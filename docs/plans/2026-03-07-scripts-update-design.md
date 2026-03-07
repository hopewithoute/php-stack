# PHP Stack Scripts Update Design

## Overview

Update semua installation scripts dengan improvements untuk error handling, auto version check, idempotency, dan reduced redundancy.

## Scope

### Tools to Update
- NVM (currently v0.40.1)
- Composer
- AWS CLI
- GitHub CLI
- PHP versions (8.2, 8.3, 8.4)

### Target OS
- Ubuntu 22.04 LTS (Jammy)
- Ubuntu 24.04 LTS (Noble)

### Improvements
- Error handling dengan exit on error dan logging
- Auto version check dari API/source
- Idempotent scripts - safe to run multiple times
- Reduce redundancy - centralized apt-get update

## Architecture

```
php-stack/
├── lib/
│   ├── common.sh          # Core helper functions
│   └── versions.sh        # Auto version fetchers
├── docker/
│   ├── Dockerfile         # Existing
│   └── Dockerfile.test    # New: test images
├── docs/
│   └── plans/
│       └── 2026-03-07-scripts-update-design.md
├── test.sh                # New: test runner
├── 00-setup.sh            # Updated
├── 01-ssh.sh              # Updated
├── 02-ufw.sh              # Updated
├── 03-tuned.sh            # Updated
├── 04-certbot.sh          # Updated
├── 05-nginx.sh            # Updated
├── 06-nvm.sh              # Updated
├── 07-image.sh            # Updated
├── 08-timezone.sh         # Updated
├── 09-php.sh              # Updated
├── 10-mysql.sh            # Updated
├── 11-redis.sh            # Updated
├── 12-aws.sh              # Updated
├── 13-gh.sh               # Updated
└── 14-backup.sh           # Updated
```

## Components

### lib/common.sh - Core Helper Functions

| Function | Purpose |
|----------|---------|
| `log_info()` | Print info message dengan timestamp |
| `log_error()` | Print error message ke stderr |
| `run_cmd()` | Execute command dengan error handling |
| `check_root()` | Verifikasi script dijalankan sebagai root |
| `apt_update_once()` | Run apt-get update sekali per session |
| `is_installed()` | Check if package/command sudah terinstall |
| `idempotent_file()` | Copy file hanya jika berbeda |

### lib/versions.sh - Auto Version Fetchers

| Function | Source |
|----------|--------|
| `get_latest_nvm_version()` | GitHub API: `nvm-sh/nvm` releases |
| `get_latest_composer_version()` | Composer installer signature |
| `get_latest_awscli_version()` | AWS CLI download page |
| `get_latest_ghcli_version()` | GitHub API: `cli/cli` releases |
| `get_php_versions()` | Ondrej PHP PPA available versions |

## Error Handling

### Standard Script Pattern

```bash
#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

check_root

log_info "Starting XYZ installation..."

if is_installed "xyz"; then
    log_info "XYZ already installed, skipping..."
    exit 0
fi

run_cmd apt-get install -y xyz

log_info "XYZ installation complete"
```

### Error Handling Strategy

| Scenario | Handling |
|----------|----------|
| Command gagal | `run_cmd` akan exit dengan error message |
| Tidak ada internet | Fail fast dengan message jelas |
| File tidak ada | Skip atau error tergantung konteks |
| Service gagal start | Log error dan exit |
| Re-run script | Skip steps yang sudah selesai (idempotent) |

### Logging Format

```
[2026-03-07 10:30:45] [INFO] Starting Nginx installation...
[2026-03-07 10:30:46] [ERROR] Failed to install nginx
```

## Testing Strategy

### Docker-Based Testing

### Dockerfile.test

```dockerfile
# Ubuntu 22.04 test
FROM ubuntu:22.04
ENV DEBIAN_FRONTEND=noninteractive
COPY . /php-stack
WORKDIR /php-stack
RUN ./00-setup.sh --non-interactive

# Ubuntu 24.04 test (multi-stage)
FROM ubuntu:24.04 AS test-2404
...
```

### test.sh - Test Runner

```bash
#!/bin/bash
# Build & run tests untuk Ubuntu 22.04 dan 24.04
docker build -f docker/Dockerfile.test --target test-2204 -t php-stack-test:22.04 .
docker build -f docker/Dockerfile.test --target test-2404 -t php-stack-test:24.04 .
```

### Test Scenarios

| Test | Description |
|------|-------------|
| Fresh install | Run semua script di container fresh |
| Idempotency | Run script 2x di container yang sama |
| Version verify | Check versi tools setelah install |
| Service status | Check semua service running |

## Files to Create

| File | Purpose |
|------|---------|
| `lib/common.sh` | Core helper functions |
| `lib/versions.sh` | Auto version fetchers |
| `docker/Dockerfile.test` | Docker test untuk 22.04 & 24.04 |
| `test.sh` | Test runner script |

## Files to Update

- `00-setup.sh` - Add source lib, improve flow
- `01-ssh.sh` - Add error handling, idempotency
- `02-ufw.sh` - Add error handling, idempotency
- `03-tuned.sh` - Add error handling, idempotency
- `04-certbot.sh` - Add error handling, idempotency
- `05-nginx.sh` - Add error handling, idempotency
- `06-nvm.sh` - Add auto version, error handling
- `07-image.sh` - Add error handling, idempotency
- `08-timezone.sh` - Add error handling, idempotency
- `09-php.sh` - Add error handling, idempotency
- `10-mysql.sh` - Add error handling, idempotency
- `11-redis.sh` - Add error handling, idempotency
- `12-aws.sh` - Add auto version, error handling
- `13-gh.sh` - Add auto version, error handling
- `14-backup.sh` - Add error handling, idempotency

## Key Changes Summary

1. Setiap script source `lib/common.sh`
2. `set -euo pipefail` untuk fail fast
3. Idempotent checks sebelum install
4. Auto version fetch dari GitHub API/APIs
5. Centralized `apt_update_once()` function
6. Docker-based testing untuk 22.04 & 24.04
