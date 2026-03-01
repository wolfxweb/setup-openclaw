#!/bin/bash
# system.sh - System detection and dependency management

LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$LIB_DIR/ui.sh"

detect_os() {
    if [ ! -f /etc/os-release ]; then
        log_error "Cannot detect OS"
        return 1
    fi
    source /etc/os-release
    case "$ID" in
        ubuntu)
            case "$VERSION_ID" in
                22.04) echo "ubuntu22"; return 0 ;;
                24.04) echo "ubuntu24"; return 0 ;;
                *) log_error "Unsupported Ubuntu: $VERSION_ID"; return 1 ;;
            esac
            ;;
        debian)
            [ "$VERSION_ID" = "12" ] && echo "debian12" && return 0
            log_error "Unsupported Debian: $VERSION_ID"; return 1
            ;;
        *) log_error "Unsupported OS: $ID"; return 1 ;;
    esac
}

check_requirements() {
    local errors=0
    print_section "Checking Requirements"
    local ram_kb=$(grep MemTotal /proc/meminfo | awk '{print $2}')
    local ram_gb=$((ram_kb / 1024 / 1024))
    [ "$ram_kb" -lt 2000000 ] && log_error "Low RAM: ${ram_gb}GB" && ((errors++)) || log_success "RAM: ${ram_gb}GB"
    
    local disk_gb=$(df -BG / | awk 'NR==2 {print $4}' | sed 's/G//')
    
    # If low disk space, offer to clean Docker
    if [ "$disk_gb" -lt 20 ]; then
        log_warn "Low disk space: ${disk_gb}GB available"
        
        if command -v docker &> /dev/null; then
            echo ""
            if prompt_yes_no "Clean unused Docker resources to free space?" "y"; then
                cleanup_docker
                # Recheck disk after cleanup
                disk_gb=$(df -BG / | awk 'NR==2 {print $4}' | sed 's/G//')
                log_info "Disk space after cleanup: ${disk_gb}GB"
            fi
        fi
        
        if [ "$disk_gb" -lt 20 ]; then
            log_error "Low disk: ${disk_gb}GB (minimum 20GB recommended)"
            ((errors++))
        else
            log_success "Disk: ${disk_gb}GB"
        fi
    else
        log_success "Disk: ${disk_gb}GB"
    fi
    
    [ "$EUID" -ne 0 ] && log_error "Must run as root" && ((errors++)) || log_success "Running as root"
    return $errors
}

install_base_deps() {
    print_section "Installing Dependencies"
    log_info "Updating packages..."
    apt-get update -qq > /dev/null 2>&1 || return 1
    local pkgs=("git" "curl" "wget" "openssl" "ca-certificates" "lsb-release" "gnupg" "apt-transport-https" "software-properties-common" "dnsutils" "net-tools")
    for pkg in "${pkgs[@]}"; do
        dpkg -l | grep -q "^ii  $pkg " || DEBIAN_FRONTEND=noninteractive apt-get install -y "$pkg" -qq > /dev/null 2>&1
    done
    log_success "Dependencies installed"
}

get_public_ip() {
    curl -s --max-time 5 ifconfig.me 2>/dev/null || curl -s --max-time 5 icanhazip.com 2>/dev/null
}

show_system_info() {
    print_section "System Info"
    source /etc/os-release
    echo -e "${COLOR_INFO}OS:${COLOR_RESET} $PRETTY_NAME"
    echo -e "${COLOR_INFO}Kernel:${COLOR_RESET} $(uname -r)"
    echo -e "${COLOR_INFO}RAM:${COLOR_RESET} $(grep MemTotal /proc/meminfo | awk '{print int($2/1024/1024)}'  )GB"
    local ip=$(get_public_ip)
    [ -n "$ip" ] && echo -e "${COLOR_INFO}IP:${COLOR_RESET} $ip"
    echo
}

is_port_in_use() {
    ss -tuln 2>/dev/null | grep -q ":$1 "
}

cleanup_docker() {
    print_section "Cleaning Docker Resources"
    
    log_info "Checking Docker usage..."
    
    # Show current disk usage
    local before_size=$(df -BG / | awk 'NR==2 {print $3}' | sed 's/G//')
    
    echo ""
    log_info "Current Docker usage:"
    docker system df 2>/dev/null || true
    echo ""
    
    log_info "Removing stopped containers..."
    local containers_removed=$(docker container prune -f 2>/dev/null | grep -o '[0-9]* container' | awk '{print $1}' || echo "0")
    log_success "Removed $containers_removed stopped containers"
    
    log_info "Removing unused images..."
    local images_removed=$(docker image prune -a -f 2>/dev/null | grep -o 'Total reclaimed space: .*' | cut -d: -f2 || echo "0B")
    log_success "Reclaimed: $images_removed"
    
    log_info "Removing unused volumes..."
    local volumes_removed=$(docker volume prune -f 2>/dev/null | grep -o '[0-9]* volume' | awk '{print $1}' || echo "0")
    log_success "Removed $volumes_removed unused volumes"
    
    log_info "Removing build cache..."
    docker builder prune -a -f > /dev/null 2>&1 || true
    log_success "Build cache cleaned"
    
    log_info "Removing unused networks..."
    docker network prune -f > /dev/null 2>&1 || true
    log_success "Unused networks removed"
    
    echo ""
    log_info "Final Docker usage:"
    docker system df 2>/dev/null || true
    echo ""
    
    local after_size=$(df -BG / | awk 'NR==2 {print $3}' | sed 's/G//')
    local freed=$((before_size - after_size))
    
    if [ "$freed" -gt 0 ]; then
        log_success "Freed approximately ${freed}GB of disk space"
    else
        log_info "No significant space freed"
    fi
    
    echo ""
}
