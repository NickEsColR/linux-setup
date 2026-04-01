#!/bin/bash
# =============================================================================
# Instalación de herramientas — Arch / CachyOS
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/logging.sh"
source "$SCRIPT_DIR/lib/install-helpers.sh"

ensure_not_root
ensure_arch_based

log_section "INICIANDO INSTALACIÓN — Arch / CachyOS"
log_info "Usuario: $USER"
echo ""

# ═════════════════════════════════════════════════════════════════════════════
# PASO 1: Actualizar el sistema
# ═════════════════════════════════════════════════════════════════════════════
log_section "PASO 1: Actualizando el sistema"
sudo pacman -Syu --noconfirm
log_step "Sistema actualizado"

# ═════════════════════════════════════════════════════════════════════════════
# PASO 2: Instalar paru (AUR helper)
# ═════════════════════════════════════════════════════════════════════════════
log_section "PASO 2: Instalando paru (AUR helper)"

if ! command -v paru &> /dev/null; then
    log_info "paru no encontrado, compilando desde AUR..."
    sudo pacman -S --needed --noconfirm base-devel git
    TEMP_DIR=$(mktemp -d)
    git clone https://aur.archlinux.org/paru.git "$TEMP_DIR/paru"
    (cd "$TEMP_DIR/paru" && makepkg -si --noconfirm)
    rm -rf "$TEMP_DIR"
    log_step "paru instalado correctamente"
else
    log_step "paru ya está instalado"
fi

# ═════════════════════════════════════════════════════════════════════════════
# PASO 3: Paquetes oficiales (pacman)
# ═════════════════════════════════════════════════════════════════════════════
log_section "PASO 3: Instalando paquetes oficiales (pacman)"

PACMAN_PACKAGES=(
    # ── Niri Compositor + ecosistema mínimo ──
    niri
    xwayland-satellite
    xdg-desktop-portal
    xdg-desktop-portal-gnome
    xdg-desktop-portal-gtk
    nautilus
    fuzzel
    mako
    swaylock
    swayidle
    polkit-gnome
    wl-clipboard
    cliphist
    grim
    slurp
    waybar
    brightnessctl
    pipewire
    pipewire-pulse
    wireplumber
    pamixer

    # ── Terminal ──
    alacritty

    # ── Control de versiones ──
    git
    github-cli

    # ── Contenedores ──
    docker
    docker-compose

    # ── Editores ──
    zed

    # ── Gestores de entornos/paquetes ──
    uv
    pnpm
    python
    python-pip
    nodejs
    npm

    # ── Aplicaciones ──
    obs-studio
    krita
    musescore
    calibre
    steam

    # ── Utilidades básicas ──
    wget
    curl
    unzip
    zip
    tree
    htop
)

sudo pacman -S --needed --noconfirm "${PACMAN_PACKAGES[@]}"
log_step "Paquetes oficiales instalados (${#PACMAN_PACKAGES[@]} paquetes)"

# ═════════════════════════════════════════════════════════════════════════════
# PASO 4: Paquetes AUR (paru)
# ═════════════════════════════════════════════════════════════════════════════
log_section "PASO 4: Instalando paquetes AUR (paru)"

AUR_PACKAGES=(
    visual-studio-code-bin
    cursor-bin
    opencode-bin
    brave-bin
    warp-terminal
    nvm
    zoom
    postman-bin
    tableplus
)

paru -S --needed --noconfirm "${AUR_PACKAGES[@]}"
log_step "Paquetes AUR instalados (${#AUR_PACKAGES[@]} paquetes)"

# ═════════════════════════════════════════════════════════════════════════════
# PASO 5: Ollama
# ═════════════════════════════════════════════════════════════════════════════
setup_ollama

# ═════════════════════════════════════════════════════════════════════════════
# PASO 6: Flatpak
# ═════════════════════════════════════════════════════════════════════════════
sudo pacman -S --needed --noconfirm flatpak
setup_flatpak

# ═════════════════════════════════════════════════════════════════════════════
# PASO 7: Gentle AI (opcional)
# ═════════════════════════════════════════════════════════════════════════════
install_gentle_ai

# ═════════════════════════════════════════════════════════════════════════════
# PASO 8: Configuración de sistema
# ═════════════════════════════════════════════════════════════════════════════
setup_docker
setup_ssh_key

# ═════════════════════════════════════════════════════════════════════════════
# RESUMEN
# ═════════════════════════════════════════════════════════════════════════════
show_install_summary "Arch / CachyOS" 0 "${#AUR_PACKAGES[@]}"
