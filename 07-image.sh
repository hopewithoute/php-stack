#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

check_root
log_info "Installing Image Processing Libraries..."

apt_update_once

# Install image optimization tools
declare -A packages=(
    ["jpegoptim"]="jpegoptim"
    ["optipng"]="optipng"
    ["pngquant"]="pngquant"
    ["gifsicle"]="gifsicle"
    ["cwebp"]="webp"
    ["avifenc"]="libavif-bin"
)

for cmd in "${!packages[@]}"; do
    pkg="${packages[$cmd]}"
    if ! command_exists "$cmd"; then
        log_info "Installing $pkg..."
        apt-get install -y "$pkg"
    else
        log_info "$pkg already installed"
    fi
done

# Install SVGO via NPM
if ! command_exists svgo; then
    log_info "Installing SVGO..."
    npm install -g svgo
else
    log_info "SVGO already installed"
fi

log_info "Image processing libraries installation complete"
