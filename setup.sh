#!/bin/bash
# =============================================================================
# setup.sh — Multi-distro installer from tools.yaml
# =============================================================================
# Single source of truth: tools.yaml
# Supported distros: Arch, CachyOS, Debian, Ubuntu, Mint, pikaOS, Fedora
#
# Usage:
#   ./setup.sh            # install everything
#   ./setup.sh --dry-run  # preview without installing
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
source "$SCRIPT_DIR/scripts/install-flatpak.sh"
source "$SCRIPT_DIR/scripts/install-script.sh"

# ═════════════════════════════════════════════════════════════════════════════
# SAFETY CHECKS
# ═════════════════════════════════════════════════════════════════════════════
ensure_not_root

# ═════════════════════════════════════════════════════════════════════════════
# CONFIGURATION
# ═════════════════════════════════════════════════════════════════════════════
DRY_RUN=false
for arg in "$@"; do
    case "$arg" in
        --dry-run) DRY_RUN=true ;;
        *) echo "Usage: ./setup.sh [--dry-run]"; exit 1 ;;
    esac
done

if [[ ! -f "$TOOLS_FILE" ]]; then
    echo "❌ File not found: '$TOOLS_FILE'"
    exit 1
fi

echo ""
echo "═══════════════════════════════════════════════════════════"
echo "  Distro: $DISTRO"
echo "  Source: $TOOLS_FILE"
[[ "$DRY_RUN" == true ]] && echo "  Mode: DRY RUN"
echo "═══════════════════════════════════════════════════════════"
echo ""

# ═════════════════════════════════════════════════════════════════════════════
# ENSURE DEPENDENCIES
# ═════════════════════════════════════════════════════════════════════════════
ensure_yq() {
    if command -v yq &>/dev/null; then return 0; fi

    echo "📦 Installing yq..."
    local arch
    arch=$(uname -m)
    case "$arch" in
        x86_64)  arch="amd64" ;;
        aarch64) arch="arm64" ;;
        *) echo "❌ Unsupported architecture: $arch"; exit 1 ;;
    esac

    local tmpyq
    tmpyq=$(mktemp)
    trap 'rm -f "$tmpyq"' EXIT

    if curl -fsSL "https://github.com/mikefarah/yq/releases/latest/download/yq_linux_${arch}" -o "$tmpyq"; then
        sudo cp "$tmpyq" /usr/local/bin/yq
        sudo chmod +x /usr/local/bin/yq
        echo "✅ yq installed"
    else
        echo "❌ Failed to install yq"
        exit 1
    fi
}

ensure_paru() {
    if [[ "$DISTRO" != "arch" ]]; then return 0; fi
    if command -v paru &>/dev/null; then return 0; fi

    echo "📦 Installing paru (AUR helper)..."
    sudo pacman -S --needed base-devel git
    local tmpdir
    tmpdir=$(mktemp -d)
    trap 'rm -rf "$tmpdir"' EXIT
    git clone https://aur.archlinux.org/paru.git "$tmpdir/paru"
    (cd "$tmpdir/paru" && makepkg -si)
    echo "✅ paru installed"
}

# ═════════════════════════════════════════════════════════════════════════════
# STEP 1: Update system
# ═════════════════════════════════════════════════════════════════════════════
if [[ "$DRY_RUN" == false ]]; then
    echo ""
    echo "═══════════════════════════════════════════════════════════"
    echo "  STEP 1: Update system"
    distro_update
    echo "✅ System updated"
fi

# ═════════════════════════════════════════════════════════════════════════════
# STEP 2: Dependencies
# ═════════════════════════════════════════════════════════════════════════════
echo ""
echo "═══════════════════════════════════════════════════════════"
echo "  STEP 2: Dependencies"
echo "═══════════════════════════════════════════════════════════"
ensure_yq
ensure_paru

# ═════════════════════════════════════════════════════════════════════════════
# STEP 3: Install tools
# ═════════════════════════════════════════════════════════════════════════════
echo ""
echo "═══════════════════════════════════════════════════════════"
echo "  STEP 3: Install tools"
echo "═══════════════════════════════════════════════════════════"

# Ensure Flathub remote before installing flatpaks
if [[ "$DRY_RUN" == false ]] && command -v flatpak &>/dev/null; then
    flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo 2>/dev/null || true
fi

# Get YAML keys
TOOL_KEYS=$(yq '.tools | keys | .[]' "$TOOLS_FILE")
TOTAL=$(echo "$TOOL_KEYS" | wc -l)
CURRENT=0
INSTALLED=0
SKIPPED=0

while IFS= read -r tool; do
    CURRENT=$((CURRENT + 1))
    echo ""
    echo "── [$CURRENT/$TOTAL] $tool ──"

    # Read from YAML
    local_pkg=$(yq ".tools.${tool}.${DISTRO} // \"\"" "$TOOLS_FILE")
    local_aur=$(yq ".tools.${tool}.arch // \"\"" "$TOOLS_FILE")
    local_flatpak=$(yq ".tools.${tool}.flatpak // \"\"" "$TOOLS_FILE")
    local_url=$(yq ".tools.${tool}.${DISTRO}_url // \"\"" "$TOOLS_FILE")
    local_script=$(yq ".tools.${tool}.script // \"\"" "$TOOLS_FILE")

    # Clean nulls
    [[ "$local_pkg" == "null" ]] && local_pkg=""
    [[ "$local_aur" == "null" ]] && local_aur=""
    [[ "$local_flatpak" == "null" ]] && local_flatpak=""
    [[ "$local_url" == "null" ]] && local_url=""
    [[ "$local_script" == "null" ]] && local_script=""

    # Fallback pikaOS → debian (if pikaos field is not defined)
    if [[ "$DISTRO" == "pikaos" ]]; then
        [[ -z "$local_pkg" ]] && local_pkg=$(yq ".tools.${tool}.debian // \"\"" "$TOOLS_FILE")
        [[ "$local_pkg" == "null" ]] && local_pkg=""
        [[ -z "$local_url" ]] && local_url=$(yq ".tools.${tool}.debian_url // \"\"" "$TOOLS_FILE")
        [[ "$local_url" == "null" ]] && local_url=""
    fi

    installed=false

    # ── 1. Official repo (pacman, pikman, apt, dnf) ──
    if [[ -n "$local_pkg" ]]; then
        if [[ "$DRY_RUN" == true ]]; then
            echo "  [dry-run] repo: $local_pkg"
            installed=true
        elif [[ "$DISTRO" == "arch" ]]; then
            install_with_pacman "$local_pkg" && installed=true || true
        elif [[ "$DISTRO" == "pikaos" ]]; then
            install_with_pikman "$local_pkg" && installed=true || true
        elif [[ "$DISTRO" == "fedora" ]]; then
            install_with_dnf "$local_pkg" && installed=true || true
        else
            install_with_apt "$local_pkg" && installed=true || true
        fi
    fi

    # ── 2. AUR (Arch only, if official repo failed) ──
    if [[ "$installed" == false && "$DISTRO" == "arch" && -n "$local_aur" ]]; then
        if [[ "$DRY_RUN" == true ]]; then
            echo "  [dry-run] AUR: $local_aur"
            installed=true
        else
            install_with_aur "$local_aur" && installed=true || true
        fi
    fi

    # ── 3. Flatpak ──
    if [[ "$installed" == false && -n "$local_flatpak" ]]; then
        if [[ "$DRY_RUN" == true ]]; then
            echo "  [dry-run] flatpak: $local_flatpak"
            installed=true
        else
            install_with_flatpak "$local_flatpak" && installed=true || true
        fi
    fi

    # ── 4. Direct URL / Official script ──
    if [[ "$installed" == false ]]; then
        if [[ -n "$local_url" ]]; then
            if [[ "$DRY_RUN" == true ]]; then
                echo "  [dry-run] url: $local_url"
                installed=true
            else
                install_from_url "$local_url" && installed=true || true
            fi
        elif [[ -n "$local_script" ]]; then
            if [[ "$DRY_RUN" == true ]]; then
                echo "  [dry-run] script: $local_script"
                installed=true
            else
                install_with_script "$local_script" && installed=true || true
            fi
        fi
    fi

    # ── Result ──
    if [[ "$installed" == true ]]; then
        echo "  ✅ $tool"
        INSTALLED=$((INSTALLED + 1))
    else
        echo "  ⚠️  $tool — not available for $DISTRO"
        SKIPPED=$((SKIPPED + 1))
    fi

done < <(echo "$TOOL_KEYS")

# ═════════════════════════════════════════════════════════════════════════════
# STEP 4: Post-installation
# ═════════════════════════════════════════════════════════════════════════════
if [[ "$DRY_RUN" == false ]]; then
    echo ""
    echo "═══════════════════════════════════════════════════════════"
    echo "  STEP 4: Post-installation"
    echo "═══════════════════════════════════════════════════════════"

    # Docker
    if command -v docker &>/dev/null; then
        sudo systemctl enable --now docker
        sudo usermod -aG docker "$USER" 2>/dev/null || true
        echo "✅ Docker enabled"
    fi
fi

# ═════════════════════════════════════════════════════════════════════════════
# SUMMARY
# ═════════════════════════════════════════════════════════════════════════════
echo ""
echo "═══════════════════════════════════════════════════════════"
echo "  SUMMARY"
echo "═══════════════════════════════════════════════════════════"
echo ""
echo "  Distro:      $DISTRO"
echo "  Processed:   $TOTAL"
echo "  Installed:   $INSTALLED"
[[ $SKIPPED -gt 0 ]] && echo "  Skipped:     $SKIPPED"
[[ "$DRY_RUN" == true ]] && echo "  (dry-run — nothing was installed)"
echo ""
