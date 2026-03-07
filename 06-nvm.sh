#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"
source "$SCRIPT_DIR/lib/versions.sh"

check_root
log_info "Installing NVM..."

# Check if NVM is already installed
NVM_DIR="$HOME/.nvm"

if [[ -d "$NVM_DIR" ]]; then
    log_info "NVM already installed"
else
    # Get latest NVM version
    NVM_VERSION=$(get_latest_nvm_version)
    log_info "Installing NVM version $NVM_VERSION..."
    
    # Download and install NVM
    curl -o- "https://raw.githubusercontent.com/nvm-sh/nvm/v${NVM_VERSION}/install.sh" | bash
fi

# Load NVM
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# Install Node.js LTS if not installed
if ! command_exists node; then
    log_info "Installing Node.js LTS..."
    nvm install --lts
else
    log_info "Node.js already installed: $(node --version)"
fi

log_info "NVM installation complete"
log_info "Node version: $(node --version 2>/dev/null || echo 'not loaded in current shell')"
log_info "NPM version: $(npm --version 2>/dev/null || echo 'not loaded in current shell')"