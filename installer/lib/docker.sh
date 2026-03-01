#!/bin/bash
# docker.sh - Docker installation

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/ui.sh"

is_docker_installed() {
    command -v docker &> /dev/null && docker compose version &> /dev/null
}

validate_docker() {
    print_section "Validating Docker"
    command -v docker &> /dev/null || { log_error "Docker not found"; return 1; }
    log_success "Docker: $(docker --version | awk '{print $3}' | tr -d ',')"
    log_success "Compose: $(docker compose version --short)"
    docker ps &> /dev/null || { log_error "Docker daemon not running"; return 1; }
    log_success "Docker daemon running"
}

install_docker() {
    print_section "Installing Docker"
    if is_docker_installed && validate_docker; then
        return 0
    fi
    log_info "Removing old versions..."
    apt-get remove -y docker docker-engine docker.io containerd runc 2>/dev/null || true
    log_info "Installing prerequisites..."
    apt-get install -y ca-certificates curl gnupg -qq > /dev/null 2>&1 || return 1
    log_info "Adding GPG key..."
    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg 2>/dev/null || return 1
    chmod a+r /etc/apt/keyrings/docker.gpg
    log_info "Adding repository..."
    local os_id=$(. /etc/os-release && echo "$ID")
    local codename=$(. /etc/os-release && echo "$VERSION_CODENAME")
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/$os_id $codename stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
    apt-get update -qq > /dev/null 2>&1
    log_info "Installing Docker..."
    DEBIAN_FRONTEND=noninteractive apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -qq > /dev/null 2>&1 || return 1
    systemctl start docker && systemctl enable docker > /dev/null 2>&1
    sleep 2
    validate_docker && log_success "Docker installed"
}

ensure_docker_network() {
    docker network inspect "$1" &> /dev/null || docker network create "$1" > /dev/null 2>&1
}

is_container_running() {
    docker ps --format '{{.Names}}' | grep -q "^$1$"
}
