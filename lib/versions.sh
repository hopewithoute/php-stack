#!/bin/bash

# Auto version fetchers for various tools
# Source this file to use the functions

# Get latest NVM version from GitHub
get_latest_nvm_version() {
    local version
    version=$(curl -s https://api.github.com/repos/nvm-sh/nvm/releases/latest | grep '"tag_name"' | sed -E 's/.*"v([^"]+)".*/\1/')
    
    if [[ -z "$version" ]]; then
        echo "0.40.1"  # Fallback version
    else
        echo "$version"
    fi
}

# Get latest Composer version
get_latest_composer_version() {
    local version
    version=$(curl -s https://getcomposer.org/download/latest-stable.version)
    
    if [[ -z "$version" ]]; then
        echo "2.8.4"  # Fallback version
    else
        echo "$version"
    fi
}

# Get latest AWS CLI version
get_latest_awscli_version() {
    local version
    version=$(curl -s https://api.github.com/repos/aws/aws-cli/releases/latest | grep '"tag_name"' | sed -E 's/.*"v([^"]+)".*/\1/')
    
    if [[ -z "$version" ]]; then
        echo "2.17.0"  # Fallback version
    else
        echo "$version"
    fi
}

# Get latest GitHub CLI version
get_latest_ghcli_version() {
    local version
    version=$(curl -s https://api.github.com/repos/cli/cli/releases/latest | grep '"tag_name"' | sed -E 's/.*"v([^"]+)".*/\1/')
    
    if [[ -z "$version" ]]; then
        echo "2.86.0"  # Fallback version
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
    version=$(curl -s https://nodejs.org/dist/index.json | grep -m1 '"lts":' | sed -E 's/.*"version":"v([^"]+)".*/\1/')
    
    if [[ -z "$version" ]]; then
        echo "22.11.0"  # Fallback version
    else
        echo "$version"
    fi
}
