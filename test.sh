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
