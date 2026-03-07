#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

check_root
log_info "Configuring UFW..."

# Install UFW if not installed
if ! command_exists ufw; then
    apt_update_once
    log_info "Installing UFW..."
    apt-get install -y ufw
else
    log_info "UFW already installed"
fi

# Set default policies
log_info "Setting default policies..."
ufw default deny incoming
ufw default allow outgoing

# Allow required ports
# HTTP
if ! ufw status | grep -q "80/tcp"; then
    log_info "Allowing port 80 (HTTP)..."
    ufw allow 80
else
    log_info "Port 80 already allowed"
fi

# HTTPS
if ! ufw status | grep -q "443/tcp"; then
    log_info "Allowing port 443 (HTTPS)..."
    ufw allow 443
else
    log_info "Port 443 already allowed"
fi

# SSH (custom port)
if ! ufw status | grep -q "13666"; then
    log_info "Allowing port 13666 (SSH)..."
    ufw allow 13666
else
    log_info "Port 13666 already allowed"
fi

# Enable UFW if not active
if ! ufw status | grep -q "Status: active"; then
    log_info "Enabling UFW..."
    echo "y" | ufw enable
else
    log_info "UFW already enabled"
fi

log_info "UFW status:"
ufw status numbered

log_info "UFW configuration complete"
