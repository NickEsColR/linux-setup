#!/bin/bash
# =============================================================================
# Instalación de herramientas — Debian / Ubuntu / Mint
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/logging.sh"
source "$SCRIPT_DIR/lib/install-helpers.sh"

ensure_not_root

if ! command -v apt &> /dev/null; then
    log_error "Este script es solo para Debian / Ubuntu / Mint (apt)."
    exit 1
fi

log_section "INICIANDO INSTALACIÓN — Debian / Ubuntu"
log_info "Usuario: $USER"
echo ""

# ═════════════════════════════════════════════════════════════════════════════
# PASO 1: Actualizar el sistema
# ═════════════════════════════════════════════════════════════════════════════
log_section "PASO 1: Actualizando el sistema"
sudo apt update && sudo apt upgrade -y
log_step "Sistema actualizado"

# ═════════════════════════════════════════════════════════════════════════════
# PASO 2: Repositorios de terceros
# ═════════════════════════════════════════════════════════════════════════════
log_section "PASO 2: Agregando repositorios de terceros"

# ── GitHub CLI ──
if ! command -v gh &> /dev/null; then
    log_info "Agregando repositorio de GitHub CLI..."
    (type -p wget >/dev/null && sudo wget -qO- https://cli.github.com/packages/githubcli-archive-keyring.gpg \
        | sudo tee /usr/share/keyrings/githubcli-archive-keyring.gpg > /dev/null
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
        | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null)
    log_step "GitHub CLI repo agregado"
else
    log_step "GitHub CLI ya instalado"
fi

# ── VS Code ──
if ! command -v code &> /dev/null; then
    log_info "Agregando repositorio de VS Code..."
    (sudo apt install -y wget gpg
    wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor \
        | sudo tee /usr/share/keyrings/microsoft-archive-keyring.gpg > /dev/null
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/microsoft-archive-keyring.gpg] https://packages.microsoft.com/repos/code stable main" \
        | sudo tee /etc/apt/sources.list.d/vscode.list > /dev/null)
    log_step "VS Code repo agregado"
else
    log_step "VS Code ya instalado"
fi

# ── Brave ──
if ! command -v brave-browser &> /dev/null; then
    log_info "Agregando repositorio de Brave..."
    (sudo curl -fsSLo /usr/share/keyrings/brave-browser-archive-keyring.gpg \
        https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg
    echo "deb [signed-by=/usr/share/keyrings/brave-browser-archive-keyring.gpg] https://brave-browser-apt-release.s3.brave.com/ stable main" \
        | sudo tee /etc/apt/sources.list.d/brave-browser-release.list > /dev/null)
    log_step "Brave repo agregado"
else
    log_step "Brave ya instalado"
fi

# ── NodeSource (Node.js 22) ──
if ! command -v node &> /dev/null; then
    log_info "Agregando repositorio de NodeSource (Node.js 22)..."
    curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
    log_step "NodeSource repo agregado"
else
    log_step "Node.js ya instalado"
fi

# ── Zed ──
if ! command -v zed &> /dev/null; then
    log_info "Agregando repositorio de Zed..."
    curl -f https://zed.dev/install.sh | sh
    log_step "Zed instalado"
else
    log_step "Zed ya instalado"
fi

# Refrescar después de agregar repos
sudo apt update

# ═════════════════════════════════════════════════════════════════════════════
# PASO 3: Paquetes apt
# ═════════════════════════════════════════════════════════════════════════════
log_section "PASO 3: Instalando paquetes (apt)"

APT_PACKAGES=(
    # ── Terminal ──
    alacritty

    # ── Control de versiones ──
    git
    gh

    # ── Contenedores ──
    docker.io
    docker-compose-v2

    # ── Editores ──
    code

    # ── Navegadores ──
    brave-browser

    # ── Gestores de entornos/paquetes ──
    python3
    python3-pip
    nodejs
    npm

    # ── Aplicaciones ──
    obs-studio
    krita
    musescore3
    calibre
    steam-installer

    # ── Utilidades básicas ──
    wget
    curl
    unzip
    zip
    tree
    htop
    flatpak
    gnome-software-plugin-flatpak
)

sudo apt install -y "${APT_PACKAGES[@]}"
log_step "Paquetes apt instalados (${#APT_PACKAGES[@]} paquetes)"

# ═════════════════════════════════════════════════════════════════════════════
# PASO 4: pnpm (via npm)
# ═════════════════════════════════════════════════════════════════════════════
log_section "PASO 4: Instalando pnpm"
if ! command -v pnpm &> /dev/null; then
    npm install -g pnpm
    log_step "pnpm instalado"
else
    log_step "pnpm ya está instalado"
fi

# ═════════════════════════════════════════════════════════════════════════════
# PASO 5: uv (via script oficial)
# ═════════════════════════════════════════════════════════════════════════════
log_section "PASO 5: Instalando uv"
if ! command -v uv &> /dev/null; then
    curl -LsSf https://astral.sh/uv/install.sh | sh
    log_step "uv instalado"
else
    log_step "uv ya está instalado"
fi

# ═════════════════════════════════════════════════════════════════════════════
# PASO 6: Ollama
# ═════════════════════════════════════════════════════════════════════════════
setup_ollama

# ═════════════════════════════════════════════════════════════════════════════
# PASO 7: Flatpak
# ═════════════════════════════════════════════════════════════════════════════
setup_flatpak

# ═════════════════════════════════════════════════════════════════════════════
# PASO 8: Gentle AI (opcional)
# ═════════════════════════════════════════════════════════════════════════════
install_gentle_ai

# ═════════════════════════════════════════════════════════════════════════════
# PASO 9: Configuración de sistema
# ═════════════════════════════════════════════════════════════════════════════
setup_docker
setup_ssh_key

# ═════════════════════════════════════════════════════════════════════════════
# PASO 10: Herramientas no disponibles en repos
# ═════════════════════════════════════════════════════════════════════════════
show_manual_steps

# ═════════════════════════════════════════════════════════════════════════════
# RESUMEN
# ═════════════════════════════════════════════════════════════════════════════
show_install_summary "Debian / Ubuntu" "${#APT_PACKAGES[@]}" 0
