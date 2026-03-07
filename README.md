# PHP Stack

Kumpulan script Bash untuk setup server PHP stack di Ubuntu 22.04 dan 24.04. Mendukung sistem dengan systemd maupun non-systemd (seperti WSL2).

## Fitur

- **SSH** - Konfigurasi SSH server yang aman
- **UFW** - Firewall configuration
- **Tuned** - Performance tuning untuk server
- **Certbot** - SSL certificates dengan Let's Encrypt
- **Nginx** - Web server dengan konfigurasi SSL
- **NVM** - Node Version Manager
- **Image** - Tools optimasi gambar (ffmpeg, imagemagick, dll)
- **Timezone** - Konfigurasi timezone server
- **PHP** - PHP 8.2/8.3/8.4 dengan FPM dan Composer
- **MySQL** - Database server
- **Redis** - Cache server
- **AWS CLI** - Amazon Web Services CLI
- **GitHub CLI** - GitHub command line tool
- **Backup** - Automated backup configuration

## Prasyarat

- Ubuntu 22.04 atau 24.04
- Akses root
- Koneksi internet

## Penggunaan

### Setup Interaktif

Jalankan script orkestrator untuk setup lengkap:

```bash
sudo ./00-setup.sh
```

Script akan menanyakan konfirmasi untuk setiap komponen.

### Setup Non-Interaktif

Untuk menjalankan semua script tanpa konfirmasi:

```bash
sudo ./00-setup.sh --non-interactive
```

### Komponen Individual

Jalankan script secara terpisah sesuai kebutuhan:

```bash
sudo ./09-php.sh    # Install PHP
sudo ./05-nginx.sh  # Install Nginx
sudo ./10-mysql.sh  # Install MySQL
```

## Struktur Direktori

```
php-stack/
├── 00-setup.sh        # Orkestrator utama
├── 01-ssh.sh          # SSH configuration
├── 02-ufw.sh          # Firewall setup
├── 03-tuned.sh        # Performance tuning
├── 04-certbot.sh      # SSL certificates
├── 05-nginx.sh        # Web server
├── 06-nvm.sh          # Node Version Manager
├── 07-image.sh        # Image optimization tools
├── 08-timezone.sh     # Timezone configuration
├── 09-php.sh          # PHP installation
├── 10-mysql.sh        # Database server
├── 11-redis.sh        # Cache server
├── 12-aws.sh          # AWS CLI
├── 13-gh.sh           # GitHub CLI
├── 14-backup.sh       # Backup configuration
├── test.sh            # Test runner
├── lib/
│   ├── common.sh      # Fungsi utility bersama
│   └── versions.sh    # Auto version fetchers
├── config/
│   ├── backup/        # Backup configuration
│   ├── mysql/         # MySQL configuration
│   ├── nginx/         # Nginx configuration
│   └── php/           # PHP CLI & FPM configuration
└── docker/
    ├── Dockerfile
    └── Dockerfile.test
```

## Testing

Test script menggunakan Docker untuk memverifikasi kompatibilitas:

```bash
./test.sh
```

Test akan menjalankan build Docker untuk Ubuntu 22.04 dan 24.04.

## Library Functions

### common.sh

Fungsi-fungsi utility yang tersedia:

| Function | Deskripsi |
|----------|-----------|
| `log_info` | Output info message |
| `log_warn` | Output warning message |
| `log_error` | Output error message |
| `check_root` | Verifikasi akses root |
| `command_exists` | Cek apakah command tersedia |
| `is_installed` | Cek apakah package terinstall |
| `has_systemctl` | Cek ketersediaan systemd |
| `apt_install` | Install package secara idempotent |
| `idempotent_copy` | Copy file jika berbeda |

### versions.sh

Auto-fetcher untuk versi terbaru:

- `get_latest_nvm_version()` - NVM version
- `get_latest_composer_version()` - Composer version
- `get_latest_awscli_version()` - AWS CLI version
- `get_latest_ghcli_version()` - GitHub CLI version
- `get_latest_node_lts()` - Node.js LTS version

## Konfigurasi PHP

Script mendukung instalasi PHP 8.2, 8.3, atau 8.4. Ekstensi yang terinstall:

- cli, fpm, curl, gd, imagick, redis
- mysql, mbstring, bcmath, xml, zip, intl

Konfigurasi PHP terletak di `config/php/` untuk CLI dan FPM.

## Kompatibilitas

- Ubuntu 22.04 (Tested)
- Ubuntu 24.04 (Tested)
- WSL2 (Didukung dengan deteksi otomatis non-systemd)

## License

MIT License
