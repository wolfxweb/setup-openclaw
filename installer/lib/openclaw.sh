#!/bin/bash
# openclaw.sh - OpenClaw installation

LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$LIB_DIR/ui.sh"
source "$LIB_DIR/docker.sh"

OPENCLAW_DIR="/opt/openclaw"
OPENCLAW_REPO="https://github.com/openclaw/openclaw.git"

install_openclaw() {
    print_section "Installing OpenClaw"
    
    if [ -d "$OPENCLAW_DIR/.git" ]; then
        log_info "OpenClaw directory exists, updating..."
        cd "$OPENCLAW_DIR"
        git fetch origin > /dev/null 2>&1
        git reset --hard origin/main > /dev/null 2>&1
        log_success "OpenClaw updated"
    else
        log_info "Cloning OpenClaw repository..."
        mkdir -p "$(dirname "$OPENCLAW_DIR")"
        if git clone "$OPENCLAW_REPO" "$OPENCLAW_DIR" > /dev/null 2>&1; then
            log_success "Repository cloned"
        else
            log_error "Failed to clone repository"
            return 1
        fi
    fi
    
    cd "$OPENCLAW_DIR"
    
    log_info "Running docker-setup.sh..."
    log_warn "The wizard will ask for configuration. Follow the prompts."
    echo ""
    
    if [ -f "./docker-setup.sh" ]; then
        bash ./docker-setup.sh
    else
        log_error "docker-setup.sh not found"
        return 1
    fi
    
    sleep 2
    validate_openclaw
}

update_openclaw() {
    print_section "Updating OpenClaw"
    
    if [ ! -d "$OPENCLAW_DIR" ]; then
        log_error "OpenClaw not installed"
        return 1
    fi
    
    cd "$OPENCLAW_DIR"
    log_info "Pulling latest changes..."
    git pull origin main > /dev/null 2>&1 || { log_error "Git pull failed"; return 1; }
    
    log_info "Rebuilding Docker image..."
    docker compose build > /dev/null 2>&1 || { log_error "Build failed"; return 1; }
    
    log_info "Restarting containers..."
    docker compose down > /dev/null 2>&1
    docker compose up -d > /dev/null 2>&1
    
    sleep 3
    validate_openclaw && log_success "OpenClaw updated"
}

validate_openclaw() {
    print_section "Validating OpenClaw"
    
    if [ ! -d "$OPENCLAW_DIR" ]; then
        log_error "OpenClaw directory not found"
        return 1
    fi
    
    cd "$OPENCLAW_DIR"
    
    log_info "Checking containers..."
    local gateway_status=$(docker compose ps openclaw-gateway 2>/dev/null | grep -c "Up")
    
    if [ "$gateway_status" -eq 0 ]; then
        log_error "Gateway container not running"
        return 1
    fi
    log_success "Gateway container running"
    
    log_info "Checking port 18789..."
    if is_port_in_use 18789; then
        log_success "Port 18789 is listening"
    else
        log_warn "Port 18789 not accessible yet"
    fi
    
    log_info "Testing health endpoint..."
    if curl -s --max-time 5 http://127.0.0.1:18789 > /dev/null 2>&1; then
        log_success "Gateway responding"
        return 0
    else
        log_warn "Gateway not responding yet (may need more time)"
        return 0
    fi
}

uninstall_openclaw() {
    print_section "Uninstalling OpenClaw"
    
    if [ ! -d "$OPENCLAW_DIR" ]; then
        log_warn "OpenClaw not found"
        return 0
    fi
    
    cd "$OPENCLAW_DIR"
    
    log_info "Stopping containers..."
    docker compose down -v > /dev/null 2>&1
    
    if prompt_yes_no "Remove OpenClaw directory ($OPENCLAW_DIR)?" "n"; then
        log_info "Removing directory..."
        cd /
        rm -rf "$OPENCLAW_DIR"
        log_success "Directory removed"
    else
        log_info "Directory preserved"
    fi
    
    if [ -f "$OPENCLAW_DIR/docker-compose.proxy.yml" ]; then
        rm -f "$OPENCLAW_DIR/docker-compose.proxy.yml"
        log_info "Proxy config removed"
    fi
    
    log_success "OpenClaw uninstalled"
}

get_openclaw_status() {
    if [ ! -d "$OPENCLAW_DIR" ]; then
        echo "not_installed"
        return
    fi
    
    cd "$OPENCLAW_DIR"
    if docker compose ps openclaw-gateway 2>/dev/null | grep -q "Up"; then
        echo "running"
    else
        echo "stopped"
    fi
}
