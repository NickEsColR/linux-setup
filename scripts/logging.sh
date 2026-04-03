#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

log_section() {
    echo ""
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}  $1${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
}

log_step() {
    echo -e "${GREEN}[✓]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[!]${NC} $1"
}

log_error() {
    echo -e "${RED}[✗]${NC} $1"
}

log_info() {
    echo -e "${BLUE}[i]${NC} $1"
}

ensure_not_root() {
    if [[ $EUID -eq 0 ]]; then
        log_error "This script cannot run as root."
        log_error "It will request sudo permissions when needed."
        echo ""
        log_info "If you're in a Docker container, create a user first:"
        echo "  useradd -m -G sudo tester"
        echo "  echo 'tester ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers"
        echo "  su - tester"
        exit 1
    fi
}

ensure_arch_based() {
    if ! command -v pacman &> /dev/null; then
        log_error "This script is for Arch Linux / CachyOS only."
        exit 1
    fi
}
