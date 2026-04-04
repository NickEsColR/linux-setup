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
source "$SCRIPT_DIR/scripts/ensure-deps.sh"
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
ensure_flatpak
ensure_flathub
ensure_paru

# ═════════════════════════════════════════════════════════════════════════════
# STEP 3: Install tools
# ═════════════════════════════════════════════════════════════════════════════
echo ""
echo "═══════════════════════════════════════════════════════════"
echo "  STEP 3: Install tools"
echo "═══════════════════════════════════════════════════════════"

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
    local_pkg=""; local_aur=""; local_flatpak=""; local_url=""; local_script=""
    # Read from YAML
    eval "$(yq -o=shell ".tools.${tool}" "$TOOLS_FILE" | sed 's/^/TOOL_/')"

    local dist_var="TOOL_${DISTRO}"
    local_pkg="${!dist_var:-}"
    local_aur="${TOOL_arch:-}"
    local_flatpak="${TOOL_flatpak:-}"
    local_url_var="TOOL_${DISTRO}_url"
    local_url="${!local_url_var:-}"
    local_script="${TOOL_script:-}"

    # Fallback pikaOS → debian (if pikaos field is not defined)
    if [[ "$DISTRO" == "pikaos" ]]; then
        [[ -z "$local_pkg" ]] && local_pkg="${TOOL_debian:-}"
        [[ -z "$local_url" ]] && local_url="${TOOL_debian_url:-}"
    fi

    installed=false

    # ── 1. Official repo (pacman, pikman, apt, dnf) ──
    if [[ -n "$local_pkg" ]]; then
        if [[ "$DRY_RUN" == true ]]; then
            echo "  [dry-run] repo: $local_pkg"
            installed=true
        elif [[ "$DISTRO" == "arch" ]]; then
            if install_with_pacman "$local_pkg"; then installed=true; fi
        elif [[ "$DISTRO" == "pikaos" ]]; then
            if install_with_pikman "$local_pkg"; then installed=true; fi
        elif [[ "$DISTRO" == "fedora" ]]; then
            if install_with_dnf "$local_pkg"; then installed=true; fi
        else
            if install_with_apt "$local_pkg"; then installed=true; fi
        fi
    fi

    # ── 2. AUR (Arch only, if official repo failed) ──
    if [[ "$installed" == false && "$DISTRO" == "arch" && -n "$local_aur" ]]; then
        if [[ "$DRY_RUN" == true ]]; then
            echo "  [dry-run] AUR: $local_aur"
            installed=true
        else
            if install_with_aur "$local_aur"; then installed=true; fi
        fi
    fi

    # ── 3. Flatpak ──
    if [[ "$installed" == false && -n "$local_flatpak" ]]; then
        if [[ "$DRY_RUN" == true ]]; then
            echo "  [dry-run] flatpak: $local_flatpak"
            installed=true
        else
            if install_with_flatpak "$local_flatpak"; then installed=true; fi
        fi
    fi

    # ── 4. Direct URL / Official script ──
    if [[ "$installed" == false ]]; then
        if [[ -n "$local_url" ]]; then
            if [[ "$DRY_RUN" == true ]]; then
                echo "  [dry-run] url: $local_url"
                installed=true
            else
                if install_from_url "$local_url"; then installed=true; fi
            fi
        elif [[ -n "$local_script" ]]; then
            if [[ "$DRY_RUN" == true ]]; then
                echo "  [dry-run] script: $local_script"
                installed=true
            else
                if install_with_script "$local_script"; then installed=true; fi
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
