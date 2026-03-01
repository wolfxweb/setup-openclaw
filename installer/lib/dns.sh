#!/bin/bash
# dns.sh - DNS validation

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/ui.sh"
source "$SCRIPT_DIR/system.sh"

validate_dns() {
    local domain="$1"
    
    if [ -z "$domain" ]; then
        log_error "Domain not provided"
        return 1
    fi
    
    print_section "Validating DNS"
    
    log_info "Resolving $domain..."
    local resolved_ip=$(dig +short "$domain" A | head -n1)
    
    if [ -z "$resolved_ip" ]; then
        resolved_ip=$(nslookup "$domain" 2>/dev/null | awk '/^Address: / { print $2 }' | tail -n1)
    fi
    
    if [ -z "$resolved_ip" ]; then
        log_error "Cannot resolve $domain"
        return 1
    fi
    
    log_success "Domain resolves to: $resolved_ip"
    
    log_info "Getting public IP..."
    local public_ip=$(get_public_ip)
    
    if [ -z "$public_ip" ]; then
        log_warn "Cannot determine public IP"
        return 0
    fi
    
    log_info "Server public IP: $public_ip"
    
    if [ "$resolved_ip" = "$public_ip" ]; then
        log_success "DNS correctly points to this server"
        return 0
    else
        log_warn "DNS mismatch: $resolved_ip != $public_ip"
        log_warn "SSL certificate may fail. Update DNS A record first."
        return 0
    fi
}

check_dns_propagation() {
    local domain="$1"
    local expected_ip="$2"
    
    log_info "Checking DNS propagation..."
    local current_ip=$(dig +short "$domain" A | head -n1)
    
    if [ "$current_ip" = "$expected_ip" ]; then
        log_success "DNS propagated correctly"
        return 0
    else
        log_warn "DNS not fully propagated yet"
        return 1
    fi
}
