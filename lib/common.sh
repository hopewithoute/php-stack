#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Get script directory
get_script_dir() {
    echo "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
}

# Logging functions
log_info() {
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "${GREEN}[${timestamp}] [INFO]${NC} $*"
}

log_warn() {
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "${YELLOW}[${timestamp}] [WARN]${NC} $*"
}

log_error() {
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "${RED}[${timestamp}] [ERROR]${NC} $*" >&2
}

# Check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "This script must be run as root"
        exit 1
    fi
}

# Check if command exists
command_exists() {
    command -v "$1" &> /dev/null
}

# Check if package is installed
is_installed() {
    dpkg -l "$1" 2> /dev/null | grep -q "^ii"
}

# Check if service is active
is_service_active() {
    systemctl is-active --quiet "$1" 2> /dev/null
}

# Check if service is enabled
is_service_enabled() {
    systemctl is-enabled --quiet "$1" 2> /dev/null
}

# Run command with error handling
run_cmd() {
    local description="$1"
    shift
    local cmd=("$@")
    
    log_info "$description"
    if ! "${cmd[@]}"; then
        log_error "Failed: ${cmd[*]}"
        return 1
    fi
    return 0
}

# Apt update once per session (uses lock file)
APT_UPDATED_FILE="/tmp/.php-stack-apt-updated"

apt_update_once() {
    if [[ ! -f "$APT_UPDATED_FILE" ]]; then
        log_info "Running apt-get update..."
        if apt-get update -qq; then
            touch "$APT_UPDATED_FILE"
        else
            log_error "apt-get update failed"
            return 1
        fi
    fi
}

# Install package if not installed
apt_install() {
    local packages=("$@")
    
    apt_update_once
    
    for pkg in "${packages[@]}"; do
        if ! is_installed "$pkg"; then
            log_info "Installing $pkg..."
            apt-get install -y "$pkg"
        else
            log_info "$pkg already installed, skipping..."
        fi
    done
}

# Copy file only if different (idempotent)
idempotent_copy() {
    local src="$1"
    local dest="$2"
    
    if [[ ! -f "$dest" ]] || ! diff -q "$src" "$dest" > /dev/null 2>&1; then
        log_info "Copying $src to $dest..."
        cp -rf "$src" "$dest"
        return 0
    else
        log_info "$dest already up to date, skipping..."
        return 1
    fi
}

# Check internet connectivity
check_internet() {
    if ! ping -c 1 -W 2 8.8.8.8 > /dev/null 2>&1; then
        log_error "No internet connection"
        return 1
    fi
    return 0
}

# Check Ubuntu version compatibility
check_ubuntu_version() {
    local version
    version=$(lsb_release -rs 2>/dev/null || cat /etc/os-release | grep VERSION_ID | cut -d'"' -f2)
    
    case "$version" in
        22.04|24.04)
            log_info "Ubuntu $version detected - compatible"
            return 0
            ;;
        *)
            log_warn "Ubuntu $version - not officially tested. Proceeding anyway..."
            return 0
            ;;
    esac
}
