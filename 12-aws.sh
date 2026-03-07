#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"
source "$SCRIPT_DIR/lib/versions.sh"

check_root
log_info "Configuring AWS CLI..."

# Check if AWS CLI is already installed
if command_exists aws; then
    CURRENT_VERSION=$(aws --version 2>&1 | cut -d' ' -f1 | cut -d'/' -f2)
    log_info "AWS CLI already installed: $CURRENT_VERSION"
else
    apt_update_once
    log_info "Installing prerequisites..."
    apt-get install -y curl unzip
    
    # Get latest version
    AWS_VERSION=$(get_latest_awscli_version)
    log_info "Installing AWS CLI version $AWS_VERSION..."
    
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip -q awscliv2.zip
    ./aws/install
    rm -rf ./aws awscliv2.zip
    
    log_info "AWS CLI installed: $(aws --version)"
fi

# Prompt for AWS configuration
read -p "Do you want to configure AWS CLI now? (y/n): " configure_aws
case $configure_aws in
    [Yy]*)
        aws configure
        ;;
    *)
        log_info "Skipping AWS configuration. Run 'aws configure' manually later."
        ;;
esac

log_info "AWS CLI configuration complete"
