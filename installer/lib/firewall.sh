#!/bin/bash
# firewall.sh - UFW configuration

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/ui.sh"

setup_ufw() {
    print_section "Configuring Firewall (UFW)"
    
    if ! command -v ufw &> /dev/null; then
        log_info "Installing UFW..."
        apt-get install -y ufw -qq > /dev/null 2>&1 || { log_error "Failed to install UFW"; return 1; }
    fi
    
    local ssh_port=$(prompt_input "SSH port" "22")
    log_info "Allowing SSH on port $ssh_port..."
    ufw allow "$ssh_port/tcp" > /dev/null 2>&1
    log_success "SSH port $ssh_port allowed"
    
    if prompt_yes_no "Enable HTTPS (ports 80/443)?" "y"; then
        log_info "Allowing HTTP/HTTPS..."
        ufw allow 80/tcp > /dev/null 2>&1
        ufw allow 443/tcp > /dev/null 2>&1
        log_success "Ports 80/443 allowed"
    fi
    
    if [ ! -f /opt/openclaw/docker-compose.proxy.yml ]; then
        if prompt_yes_no "Allow direct access to OpenClaw (port 18789)?" "n"; then
            log_info "Allowing port 18789..."
            ufw allow 18789/tcp > /dev/null 2>&1
            log_success "Port 18789 allowed"
        fi
    fi
    
    if ufw status | grep -q "Status: active"; then
        log_info "UFW already active, reloading..."
        ufw reload > /dev/null 2>&1
    else
        log_info "Enabling UFW..."
        echo "y" | ufw enable > /dev/null 2>&1
    fi
    
    log_success "Firewall configured"
    echo ""
    ufw status numbered
}

disable_ufw() {
    if command -v ufw &> /dev/null; then
        log_info "Disabling UFW..."
        ufw disable > /dev/null 2>&1
        log_success "UFW disabled"
    fi
}

show_ufw_status() {
    if command -v ufw &> /dev/null; then
        print_section "Firewall Status"
        ufw status verbose
    else
        log_info "UFW not installed"
    fi
}
