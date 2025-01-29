#!/bin/bash

# Function to install PHP
install_php() {
  local php_version=$1

  echo "Installing PHP $php_version"
  
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
  php$php_version-intl \

  echo "Copy Config PHP $php_version"
  cp -rf ./config/php/cli /etc/php/$php_version/
  cp -rf ./config/php/fpm /etc/php/$php_version/

  echo "Updating FPM configuration for PHP $php_version"
  sed -i "s|listen = /run/php/php8.2-fpm.sock|listen = /run/php/php$php_version-fpm.sock|g" /etc/php/$php_version/fpm/pool.d/www.conf

  systemctl enable php$php_version-fpm
  systemctl start php$php_version-fpm
}

# Function to set up Composer
setup_composer() {
  echo "Setting Up Composer"
  php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
  php composer-setup.php
  php -r "unlink('composer-setup.php');"
  mv composer.phar /usr/bin/composer
  chmod +x /usr/bin/composer
}

# Set up repository and update once
echo "Setting up repository and updating packages"
apt-get update && apt-get install -y software-properties-common
apt-get update
add-apt-repository -y ppa:ondrej/php
apt-get update

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
    echo "Invalid choice. Exiting."
    exit 1
    ;;
esac

# Set up Composer once
setup_composer