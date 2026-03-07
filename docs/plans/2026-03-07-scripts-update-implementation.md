# PHP Stack Scripts Update Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Update semua installation scripts dengan error handling, auto version check, idempotency, dan reduced redundancy.

**Architecture:** Modular approach dengan lib/common.sh untuk helper functions dan lib/versions.sh untuk auto version fetchers. Setiap script source library ini untuk consistency.

**Tech Stack:** Bash, Docker (testing), GitHub API (version fetching)

---

## Task 1: Create lib directory structure

**Files:**
- Create: `lib/` directory

**Step 1: Create lib directory**

Run: `mkdir -p /var/www/php-stack/lib`
Expected: Directory created successfully

**Step 2: Verify directory exists**

Run: `ls -la /var/www/php-stack/lib`
Expected: Empty directory listing

---

## Task 2: Create lib/common.sh with core helper functions

**Files:**
- Create: `lib/common.sh`

**Step 1: Write common.sh with logging functions**

```bash
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
        apt-get update -qq
        touch "$APT_UPDATED_FILE"
    fi
}

# Install package if not installed
apt_install() {
    local package="$1"
    shift
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
```

**Step 2: Write to file**

Run: Save the above content to `/var/www/php-stack/lib/common.sh`

**Step 3: Make executable and verify**

Run: `chmod +x /var/www/php-stack/lib/common.sh && head -20 /var/www/php-stack/lib/common.sh`
Expected: File content displayed

**Step 4: Commit**

```bash
git add lib/common.sh
git commit -m "feat: add lib/common.sh with helper functions"
```

---

## Task 3: Create lib/versions.sh with auto version fetchers

**Files:**
- Create: `lib/versions.sh`

**Step 1: Write versions.sh**

```bash
#!/bin/bash

# Auto version fetchers for various tools
# Source this file to use the functions

# Get latest NVM version from GitHub
get_latest_nvm_version() {
    local version
    version=$(curl -s https://api.github.com/repos/nvm-sh/nvm/releases/latest | grep '"tag_name"' | sed -E 's/.*"v([^"]+)".*/\1/')
    
    if [[ -z "$version" ]]; then
        echo "0.40.1"  # Fallback version
    else
        echo "$version"
    fi
}

# Get latest Composer version
get_latest_composer_version() {
    local version
    version=$(curl -s https://getcomposer.org/download/latest-stable.version)
    
    if [[ -z "$version" ]]; then
        echo "2.8.4"  # Fallback version
    else
        echo "$version"
    fi
}

# Get latest AWS CLI version
get_latest_awscli_version() {
    local version
    version=$(curl -s https://api.github.com/repos/aws/aws-cli/releases/latest | grep '"tag_name"' | sed -E 's/.*"v([^"]+)".*/\1/')
    
    if [[ -z "$version" ]]; then
        echo "2.17.0"  # Fallback version
    else
        echo "$version"
    fi
}

# Get latest GitHub CLI version
get_latest_ghcli_version() {
    local version
    version=$(curl -s https://api.github.com/repos/cli/cli/releases/latest | grep '"tag_name"' | sed -E 's/.*"v([^"]+)".*/\1/')
    
    if [[ -z "$version" ]]; then
        echo "2.86.0"  # Fallback version
    else
        echo "$version"
    fi
}

# Get available PHP versions from Ondrej PPA
get_available_php_versions() {
    # Return available PHP versions
    echo "8.2 8.3 8.4"
}

# Get latest stable Node.js LTS version
get_latest_node_lts() {
    local version
    version=$(curl -s https://nodejs.org/dist/index.json | grep -m1 '"lts":' | sed -E 's/.*"version":"v([^"]+)".*/\1/')
    
    if [[ -z "$version" ]]; then
        echo "22.11.0"  # Fallback version
    else
        echo "$version"
    fi
}
```

**Step 2: Write to file**

Run: Save the above content to `/var/www/php-stack/lib/versions.sh`

**Step 3: Make executable and verify**

Run: `chmod +x /var/www/php-stack/lib/versions.sh && head -20 /var/www/php-stack/lib/versions.sh`
Expected: File content displayed

**Step 4: Commit**

```bash
git add lib/versions.sh
git commit -m "feat: add lib/versions.sh with auto version fetchers"
```

---

## Task 4: Update 01-ssh.sh with error handling and idempotency

**Files:**
- Modify: `01-ssh.sh`

**Step 1: Read current content**

Run: `cat /var/www/php-stack/01-ssh.sh`
Expected: Current script content

**Step 2: Update script**

Replace entire content with:

```bash
#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

check_root
log_info "Configuring SSH..."

# Check if SSH service is already configured correctly
current_port=$(grep -E "^Port " /etc/ssh/sshd_config 2>/dev/null | awk '{print $2}' || echo "")
current_password_auth=$(grep -E "^PasswordAuthentication " /etc/ssh/sshd_config 2>/dev/null | awk '{print $2}' || echo "")

# Disable socket and enable service
if systemctl is-active --quiet ssh.socket 2>/dev/null; then
    log_info "Disabling ssh.socket..."
    systemctl disable --now ssh.socket
fi

if ! systemctl is-enabled --quiet ssh.service 2>/dev/null; then
    log_info "Enabling ssh.service..."
    systemctl enable --now ssh.service
else
    log_info "ssh.service already enabled"
fi

# Configure port
if [[ "$current_port" != "13666" ]]; then
    log_info "Setting SSH port to 13666..."
    sed -i 's/^#Port 22/Port 13666/' /etc/ssh/sshd_config
    sed -i 's/^Port 22/Port 13666/' /etc/ssh/sshd_config
    if ! grep -q "^Port 13666" /etc/ssh/sshd_config; then
        echo "Port 13666" >> /etc/ssh/sshd_config
    fi
else
    log_info "SSH port already set to 13666"
fi

# Configure password authentication
if [[ "$current_password_auth" != "no" ]]; then
    log_info "Disabling password authentication..."
    sed -i 's/^#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
    sed -i 's/^PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
    if ! grep -q "^PasswordAuthentication no" /etc/ssh/sshd_config; then
        echo "PasswordAuthentication no" >> /etc/ssh/sshd_config
    fi
else
    log_info "Password authentication already disabled"
fi

# Restart SSH if config changed
log_info "Restarting SSH service..."
systemctl restart sshd

log_info "SSH configuration complete"
```

**Step 3: Verify syntax**

Run: `bash -n /var/www/php-stack/01-ssh.sh`
Expected: No output (syntax OK)

**Step 4: Commit**

```bash
git add 01-ssh.sh
git commit -m "refactor: update 01-ssh.sh with error handling and idempotency"
```

---

## Task 5: Update 02-ufw.sh with error handling and idempotency

**Files:**
- Modify: `02-ufw.sh`

**Step 1: Update script**

Replace entire content with:

```bash
#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

check_root
log_info "Configuring UFW..."

# Install UFW if not installed
if ! command_exists ufw; then
    apt_update_once
    log_info "Installing UFW..."
    apt-get install -y ufw
else
    log_info "UFW already installed"
fi

# Set default policies
log_info "Setting default policies..."
ufw default deny incoming
ufw default allow outgoing

# Allow required ports
# HTTP
if ! ufw status | grep -q "80/tcp"; then
    log_info "Allowing port 80 (HTTP)..."
    ufw allow 80
else
    log_info "Port 80 already allowed"
fi

# HTTPS
if ! ufw status | grep -q "443/tcp"; then
    log_info "Allowing port 443 (HTTPS)..."
    ufw allow 443
else
    log_info "Port 443 already allowed"
fi

# SSH (custom port)
if ! ufw status | grep -q "13666"; then
    log_info "Allowing port 13666 (SSH)..."
    ufw allow 13666
else
    log_info "Port 13666 already allowed"
fi

# Enable UFW if not active
if ! ufw status | grep -q "Status: active"; then
    log_info "Enabling UFW..."
    echo "y" | ufw enable
else
    log_info "UFW already enabled"
fi

log_info "UFW status:"
ufw status numbered

log_info "UFW configuration complete"
```

**Step 2: Verify syntax**

Run: `bash -n /var/www/php-stack/02-ufw.sh`
Expected: No output (syntax OK)

**Step 3: Commit**

```bash
git add 02-ufw.sh
git commit -m "refactor: update 02-ufw.sh with error handling and idempotency"
```

---

## Task 6: Update 03-tuned.sh with error handling and idempotency

**Files:**
- Modify: `03-tuned.sh`

**Step 1: Update script**

Replace entire content with:

```bash
#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

check_root
log_info "Configuring Tuned..."

# Install tuned if not installed
if ! command_exists tuned; then
    apt_update_once
    log_info "Installing Tuned..."
    apt-get install -y tuned
else
    log_info "Tuned already installed"
fi

# Enable and start tuned service
if ! is_service_enabled tuned; then
    log_info "Enabling tuned service..."
    systemctl enable tuned
else
    log_info "Tuned service already enabled"
fi

if ! is_service_active tuned; then
    log_info "Starting tuned service..."
    systemctl start tuned
else
    log_info "Tuned service already running"
fi

log_info "Tuned configuration complete"
```

**Step 2: Verify syntax**

Run: `bash -n /var/www/php-stack/03-tuned.sh`
Expected: No output (syntax OK)

**Step 3: Commit**

```bash
git add 03-tuned.sh
git commit -m "refactor: update 03-tuned.sh with error handling and idempotency"
```

---

## Task 7: Update 04-certbot.sh with error handling and idempotency

**Files:**
- Modify: `04-certbot.sh`

**Step 1: Update script**

Replace entire content with:

```bash
#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

check_root
log_info "Configuring Certbot..."

# Install snapd if not installed
if ! command_exists snap; then
    apt_update_once
    log_info "Installing snapd..."
    apt-get install -y snapd
else
    log_info "snapd already installed"
fi

# Install certbot if not installed
if ! command_exists certbot; then
    log_info "Installing Certbot via snap..."
    snap install --classic certbot
    
    # Create symlink if it doesn't exist
    if [[ ! -L /usr/bin/certbot ]]; then
        log_info "Creating certbot symlink..."
        ln -sf /snap/bin/certbot /usr/bin/certbot
    fi
else
    log_info "Certbot already installed"
fi

log_info "Certbot configuration complete"
```

**Step 2: Verify syntax**

Run: `bash -n /var/www/php-stack/04-certbot.sh`
Expected: No output (syntax OK)

**Step 3: Commit**

```bash
git add 04-certbot.sh
git commit -m "refactor: update 04-certbot.sh with error handling and idempotency"
```

---

## Task 8: Update 05-nginx.sh with error handling and idempotency

**Files:**
- Modify: `05-nginx.sh`

**Step 1: Update script**

Replace entire content with:

```bash
#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

check_root
log_info "Configuring Nginx..."

# Check if nginx is installed
if ! command_exists nginx; then
    apt_update_once
    log_info "Installing prerequisites..."
    apt-get install -y curl gnupg2 ca-certificates lsb-release ubuntu-keyring
    
    # Add Nginx repository key
    log_info "Adding Nginx signing key..."
    curl https://nginx.org/keys/nginx_signing.key | gpg --dearmor \
        | tee /usr/share/keyrings/nginx-archive-keyring.gpg > /dev/null
    
    # Add Nginx repository
    log_info "Adding Nginx repository..."
    echo "deb [signed-by=/usr/share/keyrings/nginx-archive-keyring.gpg] \
http://nginx.org/packages/mainline/ubuntu $(lsb_release -cs) nginx" \
        | tee /etc/apt/sources.list.d/nginx.list > /dev/null
    
    # Set repository priority
    echo -e "Package: *\nPin: origin nginx.org\nPin: release o=nginx\nPin-Priority: 900\n" \
        | tee /etc/apt/preferences.d/99nginx > /dev/null
    
    # Update and install nginx
    apt-get update
    log_info "Installing Nginx..."
    apt-get install -y nginx
else
    log_info "Nginx already installed"
fi

# Copy configuration
log_info "Copying Nginx configuration..."
idempotent_copy "$SCRIPT_DIR/config/nginx/nginx.conf" "/etc/nginx/nginx.conf"
idempotent_copy "$SCRIPT_DIR/config/nginx/ssl.conf" "/etc/nginx/ssl.conf"

# Copy sites-enabled configs
if [[ -d "$SCRIPT_DIR/config/nginx/sites-enabled" ]]; then
    for conf in "$SCRIPT_DIR/config/nginx/sites-enabled"/*; do
        if [[ -f "$conf" ]]; then
            conf_name=$(basename "$conf")
            idempotent_copy "$conf" "/etc/nginx/sites-enabled/$conf_name"
        fi
    done
fi

# Generate DH params if not exists
if [[ ! -f /etc/nginx/dhparam.pem ]]; then
    log_info "Generating DH parameters..."
    openssl dhparam -dsaparam -out /etc/nginx/dhparam.pem 4096
else
    log_info "DH parameters already exist"
fi

# Enable nginx service
if ! is_service_enabled nginx; then
    log_info "Enabling Nginx service..."
    systemctl enable nginx
else
    log_info "Nginx service already enabled"
fi

log_info "Nginx configuration complete"
```

**Step 2: Verify syntax**

Run: `bash -n /var/www/php-stack/05-nginx.sh`
Expected: No output (syntax OK)

**Step 3: Commit**

```bash
git add 05-nginx.sh
git commit -m "refactor: update 05-nginx.sh with error handling and idempotency"
```

---

## Task 9: Update 06-nvm.sh with auto version and error handling

**Files:**
- Modify: `06-nvm.sh`

**Step 1: Update script**

Replace entire content with:

```bash
#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"
source "$SCRIPT_DIR/lib/versions.sh"

check_root
log_info "Installing NVM..."

# Check if NVM is already installed
NVM_DIR="$HOME/.nvm"

if [[ -d "$NVM_DIR" ]]; then
    log_info "NVM already installed"
else
    # Get latest NVM version
    NVM_VERSION=$(get_latest_nvm_version)
    log_info "Installing NVM version $NVM_VERSION..."
    
    # Download and install NVM
    curl -o- "https://raw.githubusercontent.com/nvm-sh/nvm/v${NVM_VERSION}/install.sh" | bash
fi

# Load NVM
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# Install Node.js LTS if not installed
if ! command_exists node; then
    log_info "Installing Node.js LTS..."
    nvm install --lts
else
    log_info "Node.js already installed: $(node --version)"
fi

log_info "NVM installation complete"
log_info "Node version: $(node --version 2>/dev/null || echo 'not loaded in current shell')"
log_info "NPM version: $(npm --version 2>/dev/null || echo 'not loaded in current shell')"
```

**Step 2: Verify syntax**

Run: `bash -n /var/www/php-stack/06-nvm.sh`
Expected: No output (syntax OK)

**Step 3: Commit**

```bash
git add 06-nvm.sh
git commit -m "refactor: update 06-nvm.sh with auto version and error handling"
```

---

## Task 10: Update 07-image.sh with error handling and idempotency

**Files:**
- Modify: `07-image.sh`

**Step 1: Update script**

Replace entire content with:

```bash
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
```

**Step 2: Verify syntax**

Run: `bash -n /var/www/php-stack/07-image.sh`
Expected: No output (syntax OK)

**Step 3: Commit**

```bash
git add 07-image.sh
git commit -m "refactor: update 07-image.sh with error handling and idempotency"
```

---

## Task 11: Update 08-timezone.sh with error handling and idempotency

**Files:**
- Modify: `08-timezone.sh`

**Step 1: Update script**

Replace entire content with:

```bash
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
```

**Step 2: Verify syntax**

Run: `bash -n /var/www/php-stack/08-timezone.sh`
Expected: No output (syntax OK)

**Step 3: Commit**

```bash
git add 08-timezone.sh
git commit -m "refactor: update 08-timezone.sh with error handling and idempotency"
```

---

## Task 12: Update 09-php.sh with error handling and idempotency

**Files:**
- Modify: `09-php.sh`

**Step 1: Update script**

Replace entire content with:

```bash
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

    # Enable and start PHP-FPM
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
```

**Step 2: Verify syntax**

Run: `bash -n /var/www/php-stack/09-php.sh`
Expected: No output (syntax OK)

**Step 3: Commit**

```bash
git add 09-php.sh
git commit -m "refactor: update 09-php.sh with error handling and idempotency"
```

---

## Task 13: Update 10-mysql.sh with error handling and idempotency

**Files:**
- Modify: `10-mysql.sh`

**Step 1: Update script**

Replace entire content with:

```bash
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
```

**Step 2: Verify syntax**

Run: `bash -n /var/www/php-stack/10-mysql.sh`
Expected: No output (syntax OK)

**Step 3: Commit**

```bash
git add 10-mysql.sh
git commit -m "refactor: update 10-mysql.sh with error handling and idempotency"
```

---

## Task 14: Update 11-redis.sh with error handling and idempotency

**Files:**
- Modify: `11-redis.sh`

**Step 1: Update script**

Replace entire content with:

```bash
#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

check_root
log_info "Installing Redis..."

# Install Redis if not installed
if ! command_exists redis-server; then
    apt_update_once
    log_info "Installing Redis Server..."
    apt-get install -y redis-server
else
    log_info "Redis already installed"
fi

# Enable Redis service
if ! is_service_enabled redis-server; then
    log_info "Enabling Redis service..."
    systemctl enable redis-server
else
    log_info "Redis service already enabled"
fi

# Start Redis service
if ! is_service_active redis-server; then
    log_info "Starting Redis service..."
    systemctl start redis-server
else
    log_info "Redis service already running"
fi

log_info "Redis version: $(redis-server --version)"
log_info "Redis installation complete"
```

**Step 2: Verify syntax**

Run: `bash -n /var/www/php-stack/11-redis.sh`
Expected: No output (syntax OK)

**Step 3: Commit**

```bash
git add 11-redis.sh
git commit -m "refactor: update 11-redis.sh with error handling and idempotency"
```

---

## Task 15: Update 12-aws.sh with auto version and error handling

**Files:**
- Modify: `12-aws.sh`

**Step 1: Update script**

Replace entire content with:

```bash
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
```

**Step 2: Verify syntax**

Run: `bash -n /var/www/php-stack/12-aws.sh`
Expected: No output (syntax OK)

**Step 3: Commit**

```bash
git add 12-aws.sh
git commit -m "refactor: update 12-aws.sh with auto version and error handling"
```

---

## Task 16: Update 13-gh.sh with auto version and error handling

**Files:**
- Modify: `13-gh.sh`

**Step 1: Update script**

Replace entire content with:

```bash
#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

check_root
log_info "Configuring GitHub CLI..."

# Check if gh is already installed
if command_exists gh; then
    log_info "GitHub CLI already installed: $(gh --version | head -1)"
else
    apt_update_once
    
    log_info "Installing prerequisites..."
    apt-get install -y wget git
    
    log_info "Adding GitHub CLI repository..."
    mkdir -p -m 755 /etc/apt/keyrings
    wget -qO- https://cli.github.com/packages/githubcli-archive-keyring.gpg | tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null
    chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg
    
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null
    
    log_info "Installing GitHub CLI..."
    apt-get update
    apt-get install -y gh
    
    log_info "GitHub CLI installed: $(gh --version | head -1)"
fi

# Prompt for authentication
read -p "Do you want to authenticate with GitHub now? (y/n): " auth_gh
case $auth_gh in
    [Yy]*)
        gh auth login
        ;;
    *)
        log_info "Skipping GitHub authentication. Run 'gh auth login' manually later."
        ;;
esac

log_info "GitHub CLI configuration complete"
```

**Step 2: Verify syntax**

Run: `bash -n /var/www/php-stack/13-gh.sh`
Expected: No output (syntax OK)

**Step 3: Commit**

```bash
git add 13-gh.sh
git commit -m "refactor: update 13-gh.sh with auto version and error handling"
```

---

## Task 17: Update 14-backup.sh with error handling and idempotency

**Files:**
- Modify: `14-backup.sh`

**Step 1: Update script**

Replace entire content with:

```bash
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
```

**Step 2: Verify syntax**

Run: `bash -n /var/www/php-stack/14-backup.sh`
Expected: No output (syntax OK)

**Step 3: Commit**

```bash
git add 14-backup.sh
git commit -m "refactor: update 14-backup.sh with error handling and idempotency"
```

---

## Task 18: Update 00-setup.sh main orchestrator

**Files:**
- Modify: `00-setup.sh`

**Step 1: Update script**

Replace entire content with:

```bash
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
```

**Step 2: Verify syntax**

Run: `bash -n /var/www/php-stack/00-setup.sh`
Expected: No output (syntax OK)

**Step 3: Commit**

```bash
git add 00-setup.sh
git commit -m "refactor: update 00-setup.sh with improved orchestrator"
```

---

## Task 19: Create Docker test file

**Files:**
- Create: `docker/Dockerfile.test`

**Step 1: Create Dockerfile.test**

```dockerfile
# PHP Stack Test Images
# Build: docker build -f docker/Dockerfile.test --target test-2204 -t php-stack-test:22.04 .
# Build: docker build -f docker/Dockerfile.test --target test-2404 -t php-stack-test:24.04 .

# Ubuntu 22.04 Test
FROM ubuntu:22.04 AS test-2204
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    git \
    lsb-release \
    && rm -rf /var/lib/apt/lists/*
COPY . /php-stack
WORKDIR /php-stack
RUN chmod +x ./00-setup.sh && ./00-setup.sh --non-interactive || true

# Ubuntu 24.04 Test
FROM ubuntu:24.04 AS test-2404
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    git \
    lsb-release \
    && rm -rf /var/lib/apt/lists/*
COPY . /php-stack
WORKDIR /php-stack
RUN chmod +x ./00-setup.sh && ./00-setup.sh --non-interactive || true
```

**Step 2: Commit**

```bash
git add docker/Dockerfile.test
git commit -m "feat: add Docker test file for Ubuntu 22.04 and 24.04"
```

---

## Task 20: Create test runner script

**Files:**
- Create: `test.sh`

**Step 1: Create test.sh**

```bash
#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

log_info "PHP Stack Test Runner"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

run_test() {
    local target=$1
    local tag=$2
    
    log_info "Building test image for Ubuntu $target..."
    if docker build -f "$SCRIPT_DIR/docker/Dockerfile.test" --target "$target" -t "php-stack-test:$tag" "$SCRIPT_DIR"; then
        echo -e "${GREEN}[PASS]${NC} Ubuntu $tag build successful"
        return 0
    else
        echo -e "${RED}[FAIL]${NC} Ubuntu $tag build failed"
        return 1
    fi
}

# Run tests
RESULTS=()

log_info "Running tests..."
run_test "test-2204" "22.04" && RESULTS+=("22.04: PASS") || RESULTS+=("22.04: FAIL")
run_test "test-2404" "24.04" && RESULTS+=("24.04: PASS") || RESULTS+=("24.04: FAIL")

# Summary
log_info "Test Results:"
for result in "${RESULTS[@]}"; do
    echo "  - $result"
done

log_info "Test run complete"
```

**Step 2: Make executable**

Run: `chmod +x /var/www/php-stack/test.sh`

**Step 3: Commit**

```bash
git add test.sh
git commit -m "feat: add test runner script"
```

---

## Task 21: Final verification and commit

**Step 1: Run shellcheck on all scripts (if available)**

Run: `which shellcheck && for f in /var/www/php-stack/*.sh /var/www/php-stack/lib/*.sh; do echo "Checking $f"; shellcheck "$f" || true; done || echo "shellcheck not installed, skipping"`

**Step 2: Verify all files exist**

Run: `ls -la /var/www/php-stack/lib/ && ls -la /var/www/php-stack/*.sh`

**Step 3: Check git status**

Run: `git status`

**Step 4: Final push (optional)**

If all tests pass and user wants to push:

```bash
git push origin main
```

---

## Summary

| Task | Description | Status |
|------|-------------|--------|
| 1 | Create lib directory | Pending |
| 2 | Create lib/common.sh | Pending |
| 3 | Create lib/versions.sh | Pending |
| 4 | Update 01-ssh.sh | Pending |
| 5 | Update 02-ufw.sh | Pending |
| 6 | Update 03-tuned.sh | Pending |
| 7 | Update 04-certbot.sh | Pending |
| 8 | Update 05-nginx.sh | Pending |
| 9 | Update 06-nvm.sh | Pending |
| 10 | Update 07-image.sh | Pending |
| 11 | Update 08-timezone.sh | Pending |
| 12 | Update 09-php.sh | Pending |
| 13 | Update 10-mysql.sh | Pending |
| 14 | Update 11-redis.sh | Pending |
| 15 | Update 12-aws.sh | Pending |
| 16 | Update 13-gh.sh | Pending |
| 17 | Update 14-backup.sh | Pending |
| 18 | Update 00-setup.sh | Pending |
| 19 | Create Dockerfile.test | Pending |
| 20 | Create test.sh | Pending |
| 21 | Final verification | Pending |
