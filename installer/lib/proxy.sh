#!/bin/bash
# proxy.sh - Traefik proxy setup

LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$LIB_DIR/ui.sh"
source "$LIB_DIR/dns.sh"

OPENCLAW_DIR="/opt/openclaw"
PROXY_FILE="$OPENCLAW_DIR/docker-compose.proxy.yml"
TEMPLATE_FILE="$LIB_DIR/../templates/docker-compose.proxy.yml.tpl"
ENV_FILE="$OPENCLAW_DIR/.setupopenclaw.env"

setup_proxy() {
    print_section "Configuring HTTPS Proxy"
    
    if [ ! -d "$OPENCLAW_DIR" ]; then
        log_error "OpenClaw not installed"
        return 1
    fi
    
    local domain=$(prompt_input "Enter domain (e.g., openclaw.example.com)" "")
    if [ -z "$domain" ]; then
        log_error "Domain required"
        return 1
    fi
    
    local email=$(prompt_input "Let's Encrypt email" "admin@$domain")
    
    validate_dns "$domain"
    
    log_info "Generating proxy configuration..."
    
    if [ ! -f "$TEMPLATE_FILE" ]; then
        log_error "Template not found: $TEMPLATE_FILE"
        return 1
    fi
    
    cp "$TEMPLATE_FILE" "$PROXY_FILE"
    sed -i "s|{{DOMAIN}}|$domain|g" "$PROXY_FILE"
    sed -i "s|{{EMAIL}}|$email|g" "$PROXY_FILE"
    
    log_success "Proxy config created"
    
    log_info "Starting Traefik..."
    cd "$OPENCLAW_DIR"
    ensure_docker_network "openclaw-edge"
    
    if docker compose -f docker-compose.yml -f docker-compose.proxy.yml up -d > /dev/null 2>&1; then
        log_success "Traefik started"
        log_success "OpenClaw available at: https://$domain"
        echo ""
        echo -e "${COLOR_WARN}Note:${COLOR_RESET} SSL certificate may take 1-2 minutes to provision"
    else
        log_error "Failed to start Traefik"
        return 1
    fi
}

setup_webauth() {
    print_section "Configuring Web Authentication"
    
    if [ ! -f "$PROXY_FILE" ]; then
        log_error "Proxy not configured. Run 'Configure Proxy' first"
        return 1
    fi
    
    local username=$(prompt_input "Username" "admin")
    local password=$(prompt_password "Password")
    
    if [ -z "$password" ]; then
        log_error "Password cannot be empty"
        return 1
    fi
    
    log_info "Generating password hash..."
    local hash=$(openssl passwd -apr1 "$password")
    
    mkdir -p "$(dirname "$ENV_FILE")"
    echo "BASIC_AUTH_USERS=$username:$hash" > "$ENV_FILE"
    chmod 600 "$ENV_FILE"
    
    log_info "Updating proxy configuration..."
    sed -i "s|{{AUTH_HASH}}|$username:$hash|g" "$PROXY_FILE"
    
    cd "$OPENCLAW_DIR"
    docker compose -f docker-compose.yml -f docker-compose.proxy.yml up -d > /dev/null 2>&1
    
    log_success "Authentication enabled"
    log_info "Username: $username"
}

remove_proxy() {
    if [ -f "$PROXY_FILE" ]; then
        log_info "Removing proxy configuration..."
        cd "$OPENCLAW_DIR"
        docker compose -f docker-compose.yml -f docker-compose.proxy.yml down > /dev/null 2>&1
        rm -f "$PROXY_FILE"
        log_success "Proxy removed"
    fi
}
