#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

check_root
log_info "Installing Redis..."

# Install Redis if not installed
if ! command_exists redis-server; then
    apt_update_once
    log_info "Installing Redis Server..."
    apt-get install -y redis-server
else
    log_info "Redis already installed"
fi

# Enable Redis service (only on systemd systems)
if has_systemctl; then
    if ! is_service_enabled redis-server; then
        log_info "Enabling Redis service..."
        systemctl enable redis-server
    else
        log_info "Redis service already enabled"
    fi

    # Start Redis service
    if ! is_service_active redis-server; then
        log_info "Starting Redis service..."
        systemctl start redis-server
    else
        log_info "Redis service already running"
    fi
else
    log_info "systemctl not available, skipping service management (non-systemd system)"
fi

log_info "Redis version: $(redis-server --version)"
log_info "Redis installation complete"
