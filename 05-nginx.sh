#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

check_root
log_info "Configuring Nginx..."

# Check if nginx is installed
if ! command_exists nginx; then
    apt_update_once
    log_info "Installing prerequisites..."
    apt-get install -y curl gnupg2 ca-certificates lsb-release ubuntu-keyring
    
    # Add Nginx repository key
    log_info "Adding Nginx signing key..."
    curl https://nginx.org/keys/nginx_signing.key | gpg --dearmor \
        | tee /usr/share/keyrings/nginx-archive-keyring.gpg > /dev/null
    
    # Add Nginx repository
    log_info "Adding Nginx repository..."
    echo "deb [signed-by=/usr/share/keyrings/nginx-archive-keyring.gpg] \
http://nginx.org/packages/mainline/ubuntu $(lsb_release -cs) nginx" \
        | tee /etc/apt/sources.list.d/nginx.list > /dev/null
    
    # Set repository priority
    echo -e "Package: *\nPin: origin nginx.org\nPin: release o=nginx\nPin-Priority: 900\n" \
        | tee /etc/apt/preferences.d/99nginx > /dev/null
    
    # Update and install nginx
    apt-get update
    log_info "Installing Nginx..."
    apt-get install -y nginx
else
    log_info "Nginx already installed"
fi

# Copy configuration
log_info "Copying Nginx configuration..."
idempotent_copy "$SCRIPT_DIR/config/nginx/nginx.conf" "/etc/nginx/nginx.conf"
idempotent_copy "$SCRIPT_DIR/config/nginx/ssl.conf" "/etc/nginx/ssl.conf"

# Copy sites-enabled configs
if [[ -d "$SCRIPT_DIR/config/nginx/sites-enabled" ]]; then
    for conf in "$SCRIPT_DIR/config/nginx/sites-enabled"/*; do
        if [[ -f "$conf" ]]; then
            conf_name=$(basename "$conf")
            idempotent_copy "$conf" "/etc/nginx/sites-enabled/$conf_name"
        fi
    done
fi

# Generate DH params if not exists
if [[ ! -f /etc/nginx/dhparam.pem ]]; then
    log_info "Generating DH parameters..."
    openssl dhparam -dsaparam -out /etc/nginx/dhparam.pem 4096
else
    log_info "DH parameters already exist"
fi

# Enable nginx service (only on systemd systems)
if has_systemctl; then
    if ! is_service_enabled nginx; then
        log_info "Enabling Nginx service..."
        systemctl enable nginx
    else
        log_info "Nginx service already enabled"
    fi
else
    log_info "systemctl not available, skipping service enable (non-systemd system)"
fi

log_info "Nginx configuration complete"