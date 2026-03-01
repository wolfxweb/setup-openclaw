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
    
    # Interactive configuration wizard
    echo ""
    print_section "🔧 Configuration Wizard"
    echo ""
    
    # Detect public IP
    log_info "Detecting public IP..."
    PUBLIC_IP=$(curl -4 -s --max-time 5 ifconfig.me 2>/dev/null || curl -4 -s --max-time 5 icanhazip.com 2>/dev/null)
    
    if [ -z "$PUBLIC_IP" ]; then
        PUBLIC_IP=$(curl -6 -s --max-time 5 ifconfig.me 2>/dev/null || curl -6 -s --max-time 5 icanhazip.com 2>/dev/null)
    fi
    
    if [ -n "$PUBLIC_IP" ]; then
        echo -e "${COLOR_SUCCESS}✓ Detected Public IP:${COLOR_RESET} $PUBLIC_IP"
    else
        echo -e "${COLOR_WARN}⚠ Could not detect public IP${COLOR_RESET}"
        PUBLIC_IP=$(prompt_input "Enter your server's public IP")
    fi
    echo ""
    
    # Ask about domain
    INSTANCE_URL=""
    USE_DOMAIN="n"
    
    if prompt_yes_no "Do you have a domain for this installation?" "n"; then
        USE_DOMAIN="y"
        DOMAIN=$(prompt_input "Enter your domain (e.g., openclaw.example.com)")
        
        if [ -n "$DOMAIN" ]; then
            echo ""
            log_info "Domain configuration will be set up..."
            INSTANCE_URL="https://$DOMAIN"
            
            # Load DNS and proxy libs if not loaded
            if ! command -v validate_dns &> /dev/null; then
                source "$LIB_DIR/dns.sh"
            fi
            if ! command -v setup_proxy &> /dev/null; then
                source "$LIB_DIR/proxy.sh"
            fi
            
            echo ""
            log_warn "After OpenClaw installation, we'll configure:"
            echo "  1. DNS validation"
            echo "  2. Traefik proxy with SSL"
            echo "  3. HTTPS redirect"
        fi
    else
        INSTANCE_URL="http://$PUBLIC_IP:18789"
        log_info "Will use IP-based access: $INSTANCE_URL"
    fi
    
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo -e "${COLOR_SUCCESS}📋 Configuration Summary:${COLOR_RESET}"
    echo ""
    echo -e "  ${COLOR_INFO}Instance URL:${COLOR_RESET} $INSTANCE_URL"
    echo -e "  ${COLOR_INFO}Public IP:${COLOR_RESET} $PUBLIC_IP"
    if [ "$USE_DOMAIN" = "y" ]; then
        echo -e "  ${COLOR_INFO}Domain:${COLOR_RESET} $DOMAIN"
        echo -e "  ${COLOR_INFO}SSL:${COLOR_RESET} Yes (Let's Encrypt)"
    else
        echo -e "  ${COLOR_INFO}SSL:${COLOR_RESET} No (HTTP only)"
    fi
    echo ""
    echo -e "${COLOR_ERROR}⚠ IMPORTANT: When the wizard asks for URL, use:${COLOR_RESET}"
    echo -e "  ${COLOR_SUCCESS}$INSTANCE_URL${COLOR_RESET}"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    
    if ! prompt_yes_no "Continue with OpenClaw installation?" "y"; then
        log_warn "Installation cancelled"
        return 1
    fi
    
    # Run OpenClaw setup
    echo ""
    log_info "Running docker-setup.sh..."
    echo ""
    
    if [ -f "./docker-setup.sh" ]; then
        bash ./docker-setup.sh
    else
        log_error "docker-setup.sh not found"
        return 1
    fi
    
    sleep 2
    validate_openclaw
    
    # Post-installation configuration
    if [ "$USE_DOMAIN" = "y" ] && [ -n "$DOMAIN" ]; then
        echo ""
        print_section "🔒 Configuring SSL (Let's Encrypt)"
        echo ""
        
        # Load proxy functions
        source "$LIB_DIR/proxy.sh"
        source "$LIB_DIR/dns.sh"
        
        log_info "Validating DNS for $DOMAIN..."
        if validate_dns "$DOMAIN"; then
            log_success "DNS validation passed"
            echo ""
            
            # Ask for email for Let's Encrypt
            EMAIL=$(prompt_input "Enter email for Let's Encrypt notifications" "admin@$DOMAIN")
            
            log_info "Configuring Traefik proxy with SSL..."
            
            # Create proxy configuration
            if [ ! -f "$LIB_DIR/../templates/docker-compose.proxy.yml.tpl" ]; then
                log_error "Proxy template not found"
            else
                # Generate proxy config
                sed -e "s|{{DOMAIN}}|$DOMAIN|g" \
                    -e "s|{{EMAIL}}|$EMAIL|g" \
                    "$LIB_DIR/../templates/docker-compose.proxy.yml.tpl" > "$OPENCLAW_DIR/docker-compose.proxy.yml"
                
                log_info "Starting Traefik proxy..."
                cd "$OPENCLAW_DIR"
                docker compose -f docker-compose.yml -f docker-compose.proxy.yml up -d
                
                echo ""
                log_success "SSL configured successfully!"
                echo ""
                echo -e "${COLOR_SUCCESS}✓ HTTPS enabled with automatic renewal${COLOR_RESET}"
                echo -e "${COLOR_INFO}  Certificate:${COLOR_RESET} Let's Encrypt"
                echo -e "${COLOR_INFO}  Auto-renewal:${COLOR_RESET} Every 90 days"
                echo -e "${COLOR_INFO}  Access:${COLOR_RESET} https://$DOMAIN"
                echo ""
                
                # Configure firewall
                if command -v ufw &> /dev/null; then
                    if prompt_yes_no "Configure firewall (UFW) for HTTPS?" "y"; then
                        source "$LIB_DIR/firewall.sh"
                        setup_ufw
                    fi
                fi
            fi
        else
            log_error "DNS validation failed for $DOMAIN"
            log_warn "Please configure DNS first:"
            echo "  1. Add A record: $DOMAIN → $PUBLIC_IP"
            echo "  2. Wait for DNS propagation (1-5 minutes)"
            echo "  3. Run: sudo $0 --action proxy"
        fi
    fi
    
    # Ask about web panel
    echo ""
    if prompt_yes_no "Do you want to install the Web Admin Panel?" "n"; then
        install_web_panel
    fi
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

install_web_panel() {
    print_section "Installing Web Admin Panel"
    
    local PANEL_DIR="$LIB_DIR/../../panel"
    
    if [ ! -d "$PANEL_DIR" ]; then
        log_error "Panel directory not found: $PANEL_DIR"
        return 1
    fi
    
    cd "$PANEL_DIR"
    
    echo ""
    log_info "Generating secure credentials..."
    
    # Generate secure password
    PANEL_PASSWORD=$(openssl rand -base64 24)
    SECRET_KEY=$(openssl rand -base64 32)
    
    echo ""
    log_success "Credentials generated:"
    echo ""
    echo -e "${COLOR_INFO}  Username:${COLOR_RESET} admin"
    echo -e "${COLOR_INFO}  Password:${COLOR_RESET} ${COLOR_SUCCESS}$PANEL_PASSWORD${COLOR_RESET}"
    echo ""
    echo -e "${COLOR_WARN}⚠ SAVE THESE CREDENTIALS! They won't be shown again.${COLOR_RESET}"
    echo ""
    
    # Create .env file
    cat > .env << EOF
PANEL_USER=admin
PANEL_PASSWORD=$PANEL_PASSWORD
SECRET_KEY=$SECRET_KEY
EOF
    
    chmod 600 .env
    log_success ".env file created"
    
    echo ""
    log_info "Building panel Docker image..."
    docker compose build > /dev/null 2>&1
    
    log_info "Starting panel..."
    docker compose up -d
    
    echo ""
    log_success "Web Admin Panel installed!"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo -e "${COLOR_SUCCESS}📱 Access Panel:${COLOR_RESET}"
    echo ""
    echo -e "${COLOR_WARN}  🔒 RECOMMENDED (SSH Tunnel):${COLOR_RESET}"
    echo -e "     ssh -L 8080:localhost:8080 root@$PUBLIC_IP"
    echo -e "     Then open: http://localhost:8080"
    echo ""
    echo -e "${COLOR_ERROR}  ⚠ NOT RECOMMENDED (Direct):${COLOR_RESET}"
    echo -e "     http://$PUBLIC_IP:8080"
    echo -e "     (Port 8080 should be blocked by firewall)"
    echo ""
    echo -e "${COLOR_INFO}  Login:${COLOR_RESET}"
    echo -e "     Username: admin"
    echo -e "     Password: $PANEL_PASSWORD"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    
    # Offer to save credentials
    if prompt_yes_no "Save credentials to file?" "y"; then
        local CREDS_FILE="$HOME/.setup-openclaw-credentials.txt"
        cat > "$CREDS_FILE" << EOF
SetupOpenClaw - Web Panel Credentials
Generated: $(date)

Panel URL (SSH Tunnel): http://localhost:8080
Panel URL (Direct): http://$PUBLIC_IP:8080

Username: admin
Password: $PANEL_PASSWORD

SSH Tunnel Command:
ssh -L 8080:localhost:8080 root@$PUBLIC_IP

EOF
        chmod 600 "$CREDS_FILE"
        log_success "Credentials saved to: $CREDS_FILE"
    fi
}
