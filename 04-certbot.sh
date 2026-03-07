#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

check_root
log_info "Configuring Certbot..."

# Install snapd if not installed
if ! command_exists snap; then
    apt_update_once
    log_info "Installing snapd..."
    apt-get install -y snapd
else
    log_info "snapd already installed"
fi

# Install certbot if not installed
if ! command_exists certbot; then
    log_info "Installing Certbot via snap..."
    snap install --classic certbot
    
    # Create symlink if it doesn't exist
    if [[ ! -L /usr/bin/certbot ]]; then
        log_info "Creating certbot symlink..."
        ln -sf /snap/bin/certbot /usr/bin/certbot
    fi
else
    log_info "Certbot already installed"
fi

log_info "Certbot configuration complete"
