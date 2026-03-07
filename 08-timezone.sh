#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

check_root
log_info "Configuring Timezone..."

TARGET_TIMEZONE="Asia/Jakarta"
CURRENT_TIMEZONE=$(cat /etc/timezone 2>/dev/null || timedatectl show --property=Timezone --value 2>/dev/null || echo "")

if [[ "$CURRENT_TIMEZONE" != "$TARGET_TIMEZONE" ]]; then
    log_info "Setting timezone to $TARGET_TIMEZONE..."
    timedatectl set-timezone "$TARGET_TIMEZONE"
else
    log_info "Timezone already set to $TARGET_TIMEZONE"
fi

log_info "Current timezone: $(timedatectl | grep 'Time zone')"
log_info "Timezone configuration complete"
