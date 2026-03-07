#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

check_root
log_info "Configuring Tuned..."

# Install tuned if not installed
if ! command_exists tuned; then
    apt_update_once
    log_info "Installing Tuned..."
    apt-get install -y tuned
else
    log_info "Tuned already installed"
fi

# Enable and start tuned service
if ! is_service_enabled tuned; then
    log_info "Enabling tuned service..."
    systemctl enable tuned
else
    log_info "Tuned service already enabled"
fi

if ! is_service_active tuned; then
    log_info "Starting tuned service..."
    systemctl start tuned
else
    log_info "Tuned service already running"
fi

log_info "Tuned configuration complete"
