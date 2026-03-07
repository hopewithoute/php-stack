#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

check_root
log_info "Configuring Backup..."

BACKUP_DIR="/var/backup"
BACKUP_SCRIPT="$BACKUP_DIR/backup.sh"

# Create backup directory if not exists
if [[ ! -d "$BACKUP_DIR" ]]; then
    log_info "Creating backup directory..."
    mkdir -p "$BACKUP_DIR"
fi

# Copy backup script
log_info "Copying backup script..."
cp -rf "$SCRIPT_DIR/config/backup/backup.sh" "$BACKUP_SCRIPT"
chmod +x "$BACKUP_SCRIPT"

# Check if crontab entry already exists
CRON_ENTRY="0 1 * * * /usr/bin/bash /var/backup/backup.sh"

if crontab -l 2>/dev/null | grep -qF "/var/backup/backup.sh"; then
    log_info "Backup cron job already exists"
else
    log_info "Adding backup cron job..."
    (crontab -l 2>/dev/null; echo "$CRON_ENTRY") | crontab -
fi

log_info "Current crontab:"
crontab -l 2>/dev/null || echo "No crontab configured"

log_info "Backup configuration complete"
