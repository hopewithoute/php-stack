#!/bin/bash

# Auto version fetchers for various tools
# Source this file to use the functions

# Source common.sh for logging functions if available
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -f "$SCRIPT_DIR/common.sh" ]]; then
    source "$SCRIPT_DIR/common.sh"
fi

# Get latest NVM version from GitHub
get_latest_nvm_version() {
    local version
    version=$(curl -sf --max-time 15 https://api.github.com/repos/nvm-sh/nvm/releases/latest 2>/dev/null | grep '"tag_name"' | sed -E 's/.*"v([^"]+)".*/\1/')
    
    if [[ -z "$version" ]]; then
        log_warn "Could not fetch latest NVM version, using fallback"
        echo "0.40.1"
    else
        echo "$version"
    fi
}

# Get latest Composer version
get_latest_composer_version() {
    local version
    version=$(curl -sf --max-time 15 https://getcomposer.org/download/latest-stable.version 2>/dev/null)
    
    if [[ -z "$version" ]]; then
        log_warn "Could not fetch latest Composer version, using fallback"
        echo "2.8.4"
    else
        echo "$version"
    fi
}

# Get latest AWS CLI version
get_latest_awscli_version() {
    local version
    version=$(curl -sf --max-time 15 https://api.github.com/repos/aws/aws-cli/releases/latest 2>/dev/null | grep '"tag_name"' | sed -E 's/.*"v([^"]+)".*/\1/')
    
    if [[ -z "$version" ]]; then
        log_warn "Could not fetch latest AWS CLI version, using fallback"
        echo "2.17.0"
    else
        echo "$version"
    fi
}

# Get latest GitHub CLI version
get_latest_ghcli_version() {
    local version
    version=$(curl -sf --max-time 15 https://api.github.com/repos/cli/cli/releases/latest 2>/dev/null | grep '"tag_name"' | sed -E 's/.*"v([^"]+)".*/\1/')
    
    if [[ -z "$version" ]]; then
        log_warn "Could not fetch latest GitHub CLI version, using fallback"
        echo "2.86.0"
    else
        echo "$version"
    fi
}

# Get available PHP versions from Ondrej PPA
get_available_php_versions() {
    # Return available PHP versions
    echo "8.2 8.3 8.4"
}

# Get latest stable Node.js LTS version
get_latest_node_lts() {
    local version
    version=$(curl -sf --max-time 15 https://nodejs.org/dist/index.json 2>/dev/null | grep -m1 '"lts":' | sed -E 's/.*"version":"v([^"]+)".*/\1/')
    
    if [[ -z "$version" ]]; then
        log_warn "Could not fetch latest Node.js LTS version, using fallback"
        echo "22.11.0"
    else
        echo "$version"
    fi
}
