#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

check_root
log_info "Configuring PHP..."

# Function to install PHP version
install_php() {
    local php_version=$1

    log_info "Checking PHP $php_version..."
    
    # Check if PHP version is already installed
    if command_exists "php$php_version"; then
        log_info "PHP $php_version already installed"
    else
        log_info "Installing PHP $php_version..."
        apt-get install -y \
            php$php_version-cli \
            php$php_version-fpm \
            php$php_version-curl \
            php$php_version-gd \
            php$php_version-imagick \
            php$php_version-redis \
            php$php_version-mysql \
            php$php_version-mbstring \
            php$php_version-bcmath \
            php$php_version-xml \
            php$php_version-zip \
            php$php_version-intl
    fi

    # Copy configuration
    log_info "Copying PHP $php_version CLI config..."
    idempotent_copy "$SCRIPT_DIR/config/php/cli" "/etc/php/$php_version/"
    
    log_info "Copying PHP $php_version FPM config..."
    idempotent_copy "$SCRIPT_DIR/config/php/fpm" "/etc/php/$php_version/"

    # Update FPM socket path
    local www_conf="/etc/php/$php_version/fpm/pool.d/www.conf"
    if [[ -f "$www_conf" ]]; then
        log_info "Updating FPM socket for PHP $php_version..."
        sed -i "s|listen = /run/php/php.*-fpm.sock|listen = /run/php/php$php_version-fpm.sock|g" "$www_conf"
    fi

    # Enable and start PHP-FPM (only on systemd systems)
    if has_systemctl; then
        if ! is_service_enabled "php$php_version-fpm"; then
            log_info "Enabling PHP $php_version FPM..."
            systemctl enable "php$php_version-fpm"
        fi
        
        if ! is_service_active "php$php_version-fpm"; then
            log_info "Starting PHP $php_version FPM..."
            systemctl start "php$php_version-fpm"
        else
            log_info "Restarting PHP $php_version FPM..."
            systemctl restart "php$php_version-fpm"
        fi
    else
        log_info "systemctl not available, skipping FPM service management (non-systemd system)"
    fi
}

# Function to set up Composer
setup_composer() {
    if command_exists composer; then
        log_info "Composer already installed: $(composer --version)"
        return
    fi
    
    log_info "Setting up Composer..."
    php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
    php composer-setup.php
    php -r "unlink('composer-setup.php');"
    mv composer.phar /usr/bin/composer
    chmod +x /usr/bin/composer
    
    log_info "Composer installed: $(composer --version)"
}

# Set up repository
log_info "Setting up PHP repository..."
apt_update_once
if ! apt-cache policy | grep -q "ondrej/php"; then
    log_info "Adding Ondrej PHP PPA..."
    apt-get install -y software-properties-common
    add-apt-repository -y ppa:ondrej/php
    apt-get update
fi

# Prompt for PHP version
echo "Select PHP version to install:"
echo "1) PHP 8.2"
echo "2) PHP 8.3"
echo "3) PHP 8.4"
echo "4) All PHP versions (8.2, 8.3, 8.4)"
read -p "Enter choice [1-4]: " choice

case $choice in
    1)
        install_php "8.2"
        ;;
    2)
        install_php "8.3"
        ;;
    3)
        install_php "8.4"
        ;;
    4)
        install_php "8.2"
        install_php "8.3"
        install_php "8.4"
        ;;
    *)
        log_error "Invalid choice. Exiting."
        exit 1
        ;;
esac

# Set up Composer
setup_composer

log_info "PHP configuration complete"
