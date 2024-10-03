#!/bin/bash
apt-get update && apt-get install -y software-properties-common
apt-get update
add-apt-repository -y ppa:ondrej/php
apt-get update

echo "Setting Up Php8.2"
apt-get install -y \
php8.2-cli \
php8.2-fpm \
php8.2-curl \
php8.2-gd \
php8.2-imagick \
php8.2-redis \
php8.2-mysql \
php8.2-mbstring \
php8.2-xml \
php8.2-zip \
php8.2-intl

echo "Copy Config Php"
cp -rf ./config/php/cli /etc/php/8.2/
cp -rf ./config/php/fpm /etc/php/8.2/


echo "Setting Up Composer"
php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
php composer-setup.php
php -r "unlink('composer-setup.php');"
mv composer.phar /usr/bin/composer
chmod +x /usr/bin/composer

systemctl enable php8.2-fpm
systemctl start php8.2-fpm