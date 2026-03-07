#!/bin/bash
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

check_root

log_info "Starting PHP Stack Setup..."
log_info "System: $(lsb_release -d | cut -f2)"
check_ubuntu_version

# Update packages first
log_info "Updating system packages..."
apt-get update && apt-get upgrade -y

# Array of script names
scripts=(
    "01-ssh.sh"
    "02-ufw.sh"
    "03-tuned.sh"
    "04-certbot.sh"
    "05-nginx.sh"
    "06-nvm.sh"
    "07-image.sh"
    "08-timezone.sh"
    "09-php.sh"
    "10-mysql.sh"
    "11-redis.sh"
    "12-aws.sh"
    "13-gh.sh"
    "14-backup.sh"
)

# Check for non-interactive mode
NON_INTERACTIVE=false
if [[ "${1:-}" == "--non-interactive" ]]; then
    NON_INTERACTIVE=true
    log_info "Running in non-interactive mode"
fi

# Iterate over each script
for script in "${scripts[@]}"; do
    script_path="$SCRIPT_DIR/$script"
    
    if [[ "$NON_INTERACTIVE" == true ]]; then
        confirm="y"
    else
        read -p "Do you want to execute $script? (y/n): " confirm
    fi
    
    case $confirm in
        [Yy]*)
            if [[ -f "$script_path" ]]; then
                log_info "Executing $script..."
                if "$script_path"; then
                    log_info "$script completed successfully"
                else
                    log_error "$script failed"
                    exit 1
                fi
            else
                log_error "Script not found: $script_path"
                exit 1
            fi
            ;;
        [Nn]*)
            log_info "Skipping $script"
            ;;
        *)
            log_error "Invalid input. Please enter 'y' or 'n'."
            ;;
    esac
done

# Clean up apt cache marker
rm -f /tmp/.php-stack-apt-updated

log_info "PHP Stack Setup complete!"