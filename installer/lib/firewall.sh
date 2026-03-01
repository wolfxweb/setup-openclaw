#!/bin/bash
# firewall.sh - Enhanced UFW configuration with security hardening

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/ui.sh"

setup_ufw() {
    print_section "Configuring Firewall (UFW) - Enhanced Security"
    
    if ! command -v ufw &> /dev/null; then
        log_info "Installing UFW..."
        apt-get install -y ufw -qq > /dev/null 2>&1 || { log_error "Failed to install UFW"; return 1; }
    fi
    
    # SSH port
    local ssh_port=$(prompt_input "SSH port" "22")
    log_info "Allowing SSH on port $ssh_port..."
    ufw allow "$ssh_port/tcp" comment "SSH" > /dev/null 2>&1
    log_success "SSH port $ssh_port allowed"
    
    # HTTPS/HTTP for OpenClaw
    if prompt_yes_no "Enable HTTPS access (ports 80/443 for OpenClaw)?" "y"; then
        log_info "Allowing HTTP/HTTPS..."
        ufw allow 80/tcp comment "HTTP (Traefik redirect)" > /dev/null 2>&1
        ufw allow 443/tcp comment "HTTPS (OpenClaw)" > /dev/null 2>&1
        log_success "Ports 80/443 allowed"
    fi
    
    # Panel access - recommend SSH tunnel
    if [ ! -f /opt/openclaw/docker-compose.proxy.yml ]; then
        echo ""
        log_warn "SECURITY NOTICE: Panel Web port 8080"
        log_warn "It is HIGHLY RECOMMENDED to access the panel via SSH tunnel only."
        echo ""
        
        if prompt_yes_no "Block panel port 8080 from external access? (RECOMMENDED)" "y"; then
            log_info "Blocking port 8080 externally..."
            ufw deny 8080/tcp comment "Panel blocked (use SSH tunnel)" > /dev/null 2>&1
            log_success "Port 8080 blocked externally"
            echo ""
            log_info "Access panel via SSH tunnel:"
            echo "  ssh -L 8080:localhost:8080 root@YOUR_SERVER_IP"
            echo "  Then open: http://localhost:8080"
        else
            log_warn "Allowing port 8080 - ENSURE strong password is set!"
            ufw allow 8080/tcp comment "Panel Web (INSECURE)" > /dev/null 2>&1
        fi
    fi
    
    # Direct OpenClaw access
    if [ ! -f /opt/openclaw/docker-compose.proxy.yml ]; then
        if prompt_yes_no "Allow direct access to OpenClaw (port 18789)?" "n"; then
            log_info "Allowing port 18789..."
            ufw allow 18789/tcp comment "OpenClaw direct" > /dev/null 2>&1
            log_success "Port 18789 allowed"
        fi
    fi
    
    # Default policies
    log_info "Setting default policies..."
    ufw default deny incoming > /dev/null 2>&1
    ufw default allow outgoing > /dev/null 2>&1
    ufw default deny routed > /dev/null 2>&1
    
    # Rate limiting on SSH
    log_info "Enabling SSH rate limiting..."
    ufw limit "$ssh_port/tcp" comment "SSH rate limit" > /dev/null 2>&1
    
    # Enable firewall
    if ufw status | grep -q "Status: active"; then
        log_info "UFW already active, reloading..."
        ufw reload > /dev/null 2>&1
    else
        log_info "Enabling UFW..."
        echo "y" | ufw enable > /dev/null 2>&1
    fi
    
    log_success "Firewall configured with enhanced security"
    echo ""
    log_info "Current firewall rules:"
    ufw status numbered
    
    echo ""
    log_warn "SECURITY TIPS:"
    echo "  • Change SSH port from default 22"
    echo "  • Use SSH keys instead of passwords"
    echo "  • Access panel only via SSH tunnel"
    echo "  • Monitor logs: tail -f /var/log/ufw.log"
}

setup_fail2ban() {
    print_section "Installing Fail2Ban (Brute Force Protection)"
    
    if command -v fail2ban-client &> /dev/null; then
        log_info "Fail2Ban already installed"
        return 0
    fi
    
    log_info "Installing Fail2Ban..."
    apt-get install -y fail2ban -qq > /dev/null 2>&1 || { log_error "Failed to install"; return 1; }
    
    log_info "Configuring Fail2Ban..."
    
    cat > /etc/fail2ban/jail.local << 'FAIL2BAN'
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 5
destemail = root@localhost
action = %(action_mwl)s

[sshd]
enabled = true
port = ssh
logpath = /var/log/auth.log
maxretry = 3

[nginx-limit-req]
enabled = true
filter = nginx-limit-req
port = http,https
logpath = /var/log/nginx/error.log
maxretry = 10
FAIL2BAN
    
    systemctl enable fail2ban > /dev/null 2>&1
    systemctl restart fail2ban > /dev/null 2>&1
    
    log_success "Fail2Ban installed and configured"
    log_info "Check status: fail2ban-client status"
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

harden_ssh() {
    print_section "SSH Hardening (Optional)"
    
    if ! prompt_yes_no "Apply SSH hardening configuration?" "y"; then
        return 0
    fi
    
    log_info "Backing up sshd_config..."
    cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup.$(date +%Y%m%d)
    
    log_info "Applying SSH hardening..."
    
    # Disable root login with password
    sed -i 's/^#*PermitRootLogin .*/PermitRootLogin prohibit-password/' /etc/ssh/sshd_config
    
    # Disable password authentication (use keys only)
    if prompt_yes_no "Disable password authentication (SSH keys only)?" "n"; then
        sed -i 's/^#*PasswordAuthentication .*/PasswordAuthentication no/' /etc/ssh/sshd_config
        log_warn "Ensure you have SSH keys configured before applying this!"
    fi
    
    # Disable empty passwords
    sed -i 's/^#*PermitEmptyPasswords .*/PermitEmptyPasswords no/' /etc/ssh/sshd_config
    
    # Limit authentication attempts
    sed -i 's/^#*MaxAuthTries .*/MaxAuthTries 3/' /etc/ssh/sshd_config
    
    log_info "Testing SSH configuration..."
    if sshd -t 2>/dev/null; then
        log_success "SSH configuration valid"
        log_info "Restarting SSH service..."
        systemctl restart sshd
        log_success "SSH hardened successfully"
    else
        log_error "SSH configuration has errors, restoring backup"
        cp /etc/ssh/sshd_config.backup.$(date +%Y%m%d) /etc/ssh/sshd_config
        return 1
    fi
}
