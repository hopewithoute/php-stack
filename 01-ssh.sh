#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

check_root
log_info "Configuring SSH..."

# Check if SSH service is already configured correctly
current_port=$(grep -E "^Port " /etc/ssh/sshd_config 2>/dev/null | awk '{print $2}' || echo "")
current_password_auth=$(grep -E "^PasswordAuthentication " /etc/ssh/sshd_config 2>/dev/null | awk '{print $2}' || echo "")

# Disable socket and enable service
if systemctl is-active --quiet ssh.socket 2>/dev/null; then
    log_info "Disabling ssh.socket..."
    systemctl disable --now ssh.socket
fi

if ! systemctl is-enabled --quiet ssh.service 2>/dev/null; then
    log_info "Enabling ssh.service..."
    systemctl enable --now ssh.service
else
    log_info "ssh.service already enabled"
fi

# Configure port
if [[ "$current_port" != "13666" ]]; then
    log_info "Setting SSH port to 13666..."
    sed -i 's/^#Port 22/Port 13666/' /etc/ssh/sshd_config
    sed -i 's/^Port 22/Port 13666/' /etc/ssh/sshd_config
    if ! grep -q "^Port 13666" /etc/ssh/sshd_config; then
        echo "Port 13666" >> /etc/ssh/sshd_config
    fi
else
    log_info "SSH port already set to 13666"
fi

# Configure password authentication
if [[ "$current_password_auth" != "no" ]]; then
    log_info "Disabling password authentication..."
    sed -i 's/^#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
    sed -i 's/^PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
    if ! grep -q "^PasswordAuthentication no" /etc/ssh/sshd_config; then
        echo "PasswordAuthentication no" >> /etc/ssh/sshd_config
    fi
else
    log_info "Password authentication already disabled"
fi

# Restart SSH if config changed
log_info "Restarting SSH service..."
systemctl restart sshd

log_info "SSH configuration complete"
