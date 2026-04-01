#!/bin/bash
# =============================================================================
# Setup — Distro Router
# =============================================================================
# Detecta la distro y ejecuta el instalador correcto.
#
# Uso:
#   bash scripts/setup.sh              → detecta e instala todo
#   bash scripts/sync-dotfiles.sh      → solo sincronizar config
#
# Scripts disponibles:
#   install-tools-arch.sh              → Arch / CachyOS (pacman + AUR)
#   install-tools-debian.sh            → Debian / Ubuntu / Mint (apt)
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/logging.sh"

log_section "DETECTANDO DISTRIBUCIÓN"

if command -v pacman &> /dev/null; then
    log_step "Detectado: Arch / CachyOS"
    bash "$SCRIPT_DIR/install-tools-arch.sh"
elif command -v apt &> /dev/null; then
    log_step "Detectado: Debian / Ubuntu / Mint"
    bash "$SCRIPT_DIR/install-tools-debian.sh"
else
    log_error "Distribución no soportada."
    echo ""
    echo -e "  Soportadas:"
    echo -e "    ${GREEN}▸ Arch / CachyOS${NC}  (pacman)"
    echo -e "    ${GREEN}▸ Debian / Ubuntu${NC} (apt)"
    echo ""
    exit 1
fi

echo ""
bash "$SCRIPT_DIR/sync-dotfiles.sh"
