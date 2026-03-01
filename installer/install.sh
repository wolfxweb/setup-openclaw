#!/bin/bash
# SetupOpenClaw - Professional OpenClaw Docker Installer
# https://github.com/openclaw/openclaw

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source all libraries
source "$SCRIPT_DIR/lib/ui.sh"
source "$SCRIPT_DIR/lib/system.sh"
source "$SCRIPT_DIR/lib/docker.sh"
source "$SCRIPT_DIR/lib/openclaw.sh"
source "$SCRIPT_DIR/lib/proxy.sh"
source "$SCRIPT_DIR/lib/firewall.sh"

# Initialize
init_ui

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    log_error "This script must be run as root"
    log_info "Usage: sudo $0"
    exit 1
fi

# Main menu
show_main_menu() {
    local choice
    choice=$(show_menu "SetupOpenClaw - Main Menu" "Select an option:" \
        "Install/Reinstall OpenClaw" \
        "Update OpenClaw" \
        "Configure Proxy + SSL" \
        "Configure Web Authentication" \
        "Configure Firewall" \
        "Status & Logs" \
        "Uninstall OpenClaw" \
        "Exit")
    echo "$choice"
}

# Action: Install
action_install() {
    print_banner
    show_system_info
    
    if ! detect_os > /dev/null 2>&1; then
        log_error "Unsupported operating system"
        return 1
    fi
    
    if ! check_requirements; then
        log_error "System requirements not met"
        return 1
    fi
    
    install_base_deps || return 1
    install_docker || return 1
    install_openclaw || return 1
    
    log_success "Installation complete!"
    echo ""
    log_info "Next steps:"
    echo "  - Configure HTTPS proxy (recommended)"
    echo "  - Configure firewall"
    echo "  - Access Control UI at http://$(get_public_ip):18789"
    echo ""
}

# Action: Update
action_update() {
    update_openclaw
}

# Action: Proxy
action_proxy() {
    setup_proxy
}

# Action: Web Auth
action_webauth() {
    setup_webauth
}

# Action: Firewall
action_ufw() {
    setup_ufw
}

# Action: Status
action_status() {
    print_section "OpenClaw Status"
    
    local status=$(get_openclaw_status)
    echo -e "${COLOR_INFO}Status:${COLOR_RESET} $status"
    
    if [ "$status" = "running" ]; then
        echo ""
        cd /opt/openclaw
        docker compose ps
        echo ""
        
        log_info "Testing gateway..."
        if curl -s --max-time 5 http://127.0.0.1:18789 > /dev/null 2>&1; then
            log_success "Gateway responding at http://127.0.0.1:18789"
        else
            log_error "Gateway not responding"
        fi
        
        if [ -f /opt/openclaw/docker-compose.proxy.yml ]; then
            local domain=$(grep "Host(" /opt/openclaw/docker-compose.proxy.yml | head -1 | sed 's/.*Host(`\(.*\)`).*/\1/')
            if [ -n "$domain" ]; then
                log_info "Proxy configured for: https://$domain"
            fi
        fi
        
        echo ""
        log_info "Recent logs (last 20 lines):"
        docker compose logs --tail=20 openclaw-gateway
    fi
}

# Action: Uninstall
action_uninstall() {
    print_section "Uninstall OpenClaw"
    log_warn "This will stop and remove OpenClaw containers"
    echo ""
    
    local confirm=$(prompt_input "Type EXCLUIR to confirm" "")
    
    if [ "$confirm" != "EXCLUIR" ]; then
        log_info "Uninstall cancelled"
        return 0
    fi
    
    uninstall_openclaw
    
    if prompt_yes_no "Remove Docker as well?" "n"; then
        log_info "Removing Docker..."
        apt-get remove -y docker-ce docker-ce-cli containerd.io docker-compose-plugin > /dev/null 2>&1
        log_success "Docker removed"
    fi
    
    log_success "Uninstall complete"
}

# Handle command-line actions (for panel integration)
if [ $# -gt 0 ] && [ "$1" = "--action" ]; then
    ACTION="$2"
    case "$ACTION" in
        install) action_install ;;
        update) action_update ;;
        proxy) action_proxy ;;
        webauth) action_webauth ;;
        ufw) action_ufw ;;
        status) action_status ;;
        uninstall) action_uninstall ;;
        *) log_error "Unknown action: $ACTION"; exit 1 ;;
    esac
    exit $?
fi

# Interactive menu mode
while true; do
    choice=$(show_main_menu)
    
    case "$choice" in
        1) action_install ;;
        2) action_update ;;
        3) action_proxy ;;
        4) action_webauth ;;
        5) action_ufw ;;
        6) action_status ;;
        7) action_uninstall ;;
        8|"") log_info "Exiting..."; exit 0 ;;
        *) log_error "Invalid option"; continue ;;
    esac
    
    echo ""
    read -p "Press Enter to continue..."
done
