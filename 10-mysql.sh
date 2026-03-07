#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

check_root
log_info "Configuring MySQL..."

# Install MySQL if not installed
if ! command_exists mysql; then
    apt_update_once
    log_info "Installing MySQL Server..."
    apt-get install -y mysql-server
else
    log_info "MySQL already installed"
fi

# Copy configuration
log_info "Copying MySQL configuration..."
idempotent_copy "$SCRIPT_DIR/config/mysql" "/etc/"

# Start and enable MySQL service
if ! is_service_active mysql; then
    log_info "Starting MySQL service..."
    service mysql start
else
    log_info "MySQL service already running"
fi

if ! is_service_enabled mysql; then
    log_info "Enabling MySQL service..."
    systemctl enable mysql
else
    log_info "MySQL service already enabled"
fi

# Check if user 'db' already exists
DB_USER_EXISTS=$(mysql --user=root -e "SELECT User FROM mysql.user WHERE User='db';" 2>/dev/null | grep -c "db" || echo "0")

if [[ "$DB_USER_EXISTS" -eq "0" ]]; then
    log_info "Running MySQL secure installation..."
    mysql_secure_installation
    
    log_info "Creating database user 'db'..."
    mysql --user=root <<_EOF_
CREATE USER 'db'@'localhost' IDENTIFIED BY 'yourpassword';
GRANT ALL PRIVILEGES ON *.* TO 'db'@'localhost' WITH GRANT OPTION;
FLUSH PRIVILEGES;
SELECT User, Host, plugin FROM mysql.user;
_EOF_
else
    log_info "Database user 'db' already exists, skipping user creation"
fi

log_info "MySQL configuration complete"