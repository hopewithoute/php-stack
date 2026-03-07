#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

check_root
log_info "Configuring GitHub CLI..."

# Check if gh is already installed
if command_exists gh; then
    log_info "GitHub CLI already installed: $(gh --version | head -1)"
else
    apt_update_once
    
    log_info "Installing prerequisites..."
    apt-get install -y wget git
    
    log_info "Adding GitHub CLI repository..."
    mkdir -p -m 755 /etc/apt/keyrings
    wget -qO- https://cli.github.com/packages/githubcli-archive-keyring.gpg | tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null
    chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg
    
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null
    
    log_info "Installing GitHub CLI..."
    apt-get update
    apt-get install -y gh
    
    log_info "GitHub CLI installed: $(gh --version | head -1)"
fi

# Prompt for authentication
read -p "Do you want to authenticate with GitHub now? (y/n): " auth_gh
case $auth_gh in
    [Yy]*)
        gh auth login
        ;;
    *)
        log_info "Skipping GitHub authentication. Run 'gh auth login' manually later."
        ;;
esac

log_info "GitHub CLI configuration complete"
