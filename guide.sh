#!/bin/bash
# =============================================================================
# guide.sh — Interactive installation guide (reads tools.yaml, tells you what to do)
# =============================================================================
# Single source of truth: tools.yaml
# Supported distros: Arch, CachyOS, Debian, Ubuntu, Mint, pikaOS, Fedora
#
# This script does NOT auto-install everything. It:
#   1. Checks prerequisites and tells you what to install if missing
#   2. Installs native + AUR packages (if prerequisites are met)
#   3. Shows you the flatpak, URL, and script commands to run manually
#
# Usage:
#   ./guide.sh
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOOLS_FILE="$SCRIPT_DIR/tools.yaml"

# ═════════════════════════════════════════════════════════════════════════════
# LOAD LIBRARIES
# ═════════════════════════════════════════════════════════════════════════════
source "$SCRIPT_DIR/scripts/logging.sh"
source "$SCRIPT_DIR/scripts/distro.sh"
source "$SCRIPT_DIR/scripts/install-pacman.sh"
source "$SCRIPT_DIR/scripts/install-aur.sh"
source "$SCRIPT_DIR/scripts/install-pikman.sh"
source "$SCRIPT_DIR/scripts/install-apt.sh"
source "$SCRIPT_DIR/scripts/install-dnf.sh"

# ═════════════════════════════════════════════════════════════════════════════
# SAFETY CHECKS
# ═════════════════════════════════════════════════════════════════════════════
if [[ $EUID -eq 0 ]]; then
    echo "❌ Do not run this script as root."
    exit 1
fi

if [[ ! -f "$TOOLS_FILE" ]]; then
    echo "❌ File not found: '$TOOLS_FILE'"
    exit 1
fi

# ═════════════════════════════════════════════════════════════════════════════
# HEADER
# ═════════════════════════════════════════════════════════════════════════════
echo ""
echo "═══════════════════════════════════════════════════════════"
echo "  Installation Guide"
echo "  Distro: $DISTRO"
echo "  Source: $TOOLS_FILE"
echo "═══════════════════════════════════════════════════════════"
echo ""

# ═════════════════════════════════════════════════════════════════════════════
# STEP 1: Prerequisites check
# ═════════════════════════════════════════════════════════════════════════════
echo "───────────────────────────────────────────────────────────"
echo "  STEP 1: Prerequisites"
echo "───────────────────────────────────────────────────────────"

MISSING=0

# ── yq (required for reading tools.yaml) ──
if command -v yq &>/dev/null; then
    echo "  ✅ yq — found"
else
    echo "  ❌ yq — NOT FOUND"
    MISSING=1
fi

# ── Check if we need paru (AUR packages exist for this distro) ──
NEED_PARU=false
if [[ "$DISTRO" == "arch" ]]; then
    if yq '.tools[] | select(has("aur")) | .aur' "$TOOLS_FILE" | grep -qv "null"; then
        NEED_PARU=true
    fi
fi

if [[ "$NEED_PARU" == true ]]; then
    if command -v paru &>/dev/null; then
        echo "  ✅ paru — found"
    else
        echo "  ❌ paru — NOT FOUND (required for AUR packages)"
        MISSING=1
    fi
else
    echo "  ℹ️  paru — not needed for $DISTRO"
fi

# ── Check if we need flatpak (flatpak packages exist for this distro) ──
NEED_FLATPAK=false
if yq '.tools[] | select(has("flatpak")) | .flatpak' "$TOOLS_FILE" | grep -qv "null"; then
    NEED_FLATPAK=true
fi

if [[ "$NEED_FLATPAK" == true ]]; then
    if command -v flatpak &>/dev/null; then
        echo "  ✅ flatpak — found"
    else
        echo "  ❌ flatpak — NOT FOUND"
        MISSING=1
    fi
else
    echo "  ℹ️  flatpak — not needed"
fi

echo ""

# ── If prerequisites are missing, show commands and exit ──
if [[ $MISSING -ne 0 ]]; then
    echo "───────────────────────────────────────────────────────────"
    echo "  Install missing prerequisites and run this script again"
    echo "───────────────────────────────────────────────────────────"
    echo ""

    if ! command -v yq &>/dev/null; then
        echo "  📦 yq (YAML processor):"
        echo "     curl -fsSL https://github.com/mikefarah/yq/releases/latest/download/yq_linux_$(uname -m | sed 's/x86_64/amd64/;s/aarch64/arm64/') -o /tmp/yq && sudo cp /tmp/yq /usr/local/bin/yq && sudo chmod +x /usr/local/bin/yq"
        echo ""
    fi

    if [[ "$NEED_PARU" == true ]] && ! command -v paru &>/dev/null; then
        echo "  📦 paru (AUR helper — Arch only):"
        echo "     sudo pacman -S --needed base-devel git"
        echo "     git clone https://aur.archlinux.org/paru.git /tmp/paru && cd /tmp/paru && makepkg -si"
        echo ""
    fi

    if [[ "$NEED_FLATPAK" == true ]] && ! command -v flatpak &>/dev/null; then
        echo "  📦 flatpak:"
        case "$DISTRO" in
            arch)    echo "     sudo pacman -S flatpak" ;;
            fedora)  echo "     sudo dnf install -y flatpak" ;;
            pikaos)  echo "     sudo pikman install flatpak || sudo apt install -y flatpak" ;;
            *)       echo "     sudo apt install -y flatpak" ;;
        esac
        echo "     flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo"
        echo ""
    fi

    exit 1
fi

echo "  ✅ All prerequisites met"
echo ""

# ═════════════════════════════════════════════════════════════════════════════
# STEP 2: Classify packages
# ═════════════════════════════════════════════════════════════════════════════
echo "───────────────────────────────────────────────────────────"
echo "  STEP 2: Package classification"
echo "───────────────────────────────────────────────────────────"

# NATIVE: Tools with the current distro key
if [[ "$DISTRO" == "pikaos" ]]; then
    PIKA_PKGS=$(yq '.tools[] | select(has("pikaos")) | .pikaos' "$TOOLS_FILE" | grep -v "null" | tr '\n' ' ')
    DEBIAN_FALLBACK=$(yq '.tools[] | select((has("pikaos") | not) and has("debian")) | .debian' "$TOOLS_FILE" | grep -v "null" | tr '\n' ' ')
    NATIVE_LIST="$PIKA_PKGS $DEBIAN_FALLBACK"
else
    NATIVE_LIST=$(yq ".tools[] | select(has(\"$DISTRO\")) | .\"$DISTRO\"" "$TOOLS_FILE" | grep -v "null" | tr '\n' ' ')
fi

# AUR: Tools with 'aur' but NOT the current distro key (Arch only)
AUR_LIST=""
if [[ "$DISTRO" == "arch" ]]; then
    AUR_LIST=$(yq ".tools[] | select(has(\"aur\") and (has(\"arch\") | not)) | .aur" "$TOOLS_FILE" | grep -v "null" | tr '\n' ' ')
fi

# FLATPAK: Tools with 'flatpak'
FLATPAK_LIST=$(yq '.tools[] | select(has("flatpak")) | .flatpak' "$TOOLS_FILE" | grep -v "null" | tr '\n' ' ')

# URL: Tools with distro_url but NOT distro, aur, or flatpak
if [[ "$DISTRO" == "pikaos" ]]; then
    URL_LIST=$(yq '.tools[] | select((has("pikaos_url") | not) and (has("pikaos") | not) and (has("debian_url")) and (has("debian") | not) and (has("aur") | not) and (has("flatpak") | not)) | .debian_url' "$TOOLS_FILE" | grep -v "null" | tr '\n' ' ')
else
    URL_LIST=$(yq ".tools[] | select(has(\"${DISTRO}_url\") and (has(\"$DISTRO\") | not) and (has(\"aur\") | not) and (has(\"flatpak\") | not)) | .\"${DISTRO}_url\"" "$TOOLS_FILE" | grep -v "null" | tr '\n' ' ')
fi

# SCRIPT: Tools that ONLY have 'script' (no distro, aur, flatpak, or url keys)
SCRIPT_LIST=$(yq '.tools[] | select(has("script") and (has("arch") | not) and (has("aur") | not) and (has("debian") | not) and (has("fedora") | not) and (has("flatpak") | not) and (has("arch_url") | not) and (has("debian_url") | not) and (has("fedora_url") | not) and (has("pikaos") | not) and (has("pikaos_url") | not)) | .script' "$TOOLS_FILE" | grep -v "null" | tr '\n' ' ')

# Show classification
[[ -n "$NATIVE_LIST" ]]  && echo "  📦 Nativo ($DISTRO): $NATIVE_LIST"
[[ -n "$AUR_LIST" ]]     && echo "  🏪 AUR: $AUR_LIST"
[[ -n "$FLATPAK_LIST" ]] && echo "  🚀 Flatpak: $FLATPAK_LIST"
[[ -n "$URL_LIST" ]]     && echo "  🔗 URL: $URL_LIST"
[[ -n "$SCRIPT_LIST" ]]  && echo "  📜 Script: $SCRIPT_LIST"
[[ -z "$NATIVE_LIST$AUR_LIST$FLATPAK_LIST$URL_LIST$SCRIPT_LIST" ]] && echo "  ⚠️  No hay paquetes para $DISTRO"
echo ""

# ═════════════════════════════════════════════════════════════════════════════
# STEP 3: Install native + AUR
# ═════════════════════════════════════════════════════════════════════════════
echo "───────────────────────────────────────────────────────────"
echo "  STEP 3: Installing native + AUR packages"
echo "───────────────────────────────────────────────────────────"
echo ""

if [[ -n "$NATIVE_LIST" ]]; then
    echo "── Repos oficiales ──"
    if [[ "$DISTRO" == "arch" ]]; then
        install_with_pacman "$NATIVE_LIST"
    elif [[ "$DISTRO" == "pikaos" ]]; then
        install_with_pikman "$NATIVE_LIST"
    elif [[ "$DISTRO" == "fedora" ]]; then
        install_with_dnf "$NATIVE_LIST"
    else
        install_with_apt "$NATIVE_LIST"
    fi
    echo ""
else
    echo "  ℹ️  No hay paquetes nativos para $DISTRO"
    echo ""
fi

if [[ -n "$AUR_LIST" ]]; then
    echo "── AUR ──"
    install_with_aur "$AUR_LIST"
    echo ""
else
    echo "  ℹ️  No hay paquetes AUR"
    echo ""
fi

# ═════════════════════════════════════════════════════════════════════════════
# STEP 4: Manual installations (Flatpak, URL, Script)
# ═════════════════════════════════════════════════════════════════════════════
echo "───────────────────────────────────────────────────────────"
echo "  STEP 4: Manual installations"
echo "───────────────────────────────────────────────────────────"
echo ""

# ── Flatpak ──
if [[ -n "$FLATPAK_LIST" ]]; then
    echo "  🚀 Flatpak:"
    echo "    flatpak install -y flathub $FLATPAK_LIST"
    echo ""
else
    echo "  ℹ️  No hay paquetes Flatpak"
    echo ""
fi

# ── URL ──
if [[ -n "$URL_LIST" ]]; then
    echo "  🔗 Descargas directas (URL):"
    for url in $URL_LIST; do
        echo "    curl -fsSL '$url' -o /tmp/pkg && sudo dpkg -i /tmp/pkg || sudo dnf install -y /tmp/pkg && rm -f /tmp/pkg"
    done
    echo ""
else
    echo "  ℹ️  No hay paquetes por URL"
    echo ""
fi

# ── Script ──
if [[ -n "$SCRIPT_LIST" ]]; then
    echo "  📜 Scripts de instalación:"
    for script in $SCRIPT_LIST; do
        echo "    curl -fsSL '$script' | bash"
    done
    echo ""
else
    echo "  ℹ️  No hay scripts de instalación"
    echo ""
fi

# ═════════════════════════════════════════════════════════════════════════════
# DONE
# ═════════════════════════════════════════════════════════════════════════════
echo "═══════════════════════════════════════════════════════════"
echo "  Done"
echo "═══════════════════════════════════════════════════════════"
echo ""
