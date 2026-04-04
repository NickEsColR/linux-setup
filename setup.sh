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

# ── Phase 1: Classification by exclusive bucket (declarative) ──
echo "🔍 Filtrando candidatos para $DISTRO (aplicando jerarquía)..."

# A. NATIVE: Tools with the current distro key
#    pikaOS fallback: include debian packages that don't have pikaos key
if [[ "$DISTRO" == "pikaos" ]]; then
    PIKA_PKGS=$(yq '.tools[] | select(has("pikaos")) | .pikaos' "$TOOLS_FILE" | grep -v "null" | tr '\n' ' ')
    DEBIAN_FALLBACK=$(yq '.tools[] | select((has("pikaos") | not) and has("debian")) | .debian' "$TOOLS_FILE" | grep -v "null" | tr '\n' ' ')
    NATIVE_LIST="$PIKA_PKGS $DEBIAN_FALLBACK"
else
    NATIVE_LIST=$(yq ".tools[] | select(has(\"$DISTRO\")) | .\"$DISTRO\"" "$TOOLS_FILE" | grep -v "null" | tr '\n' ' ')
fi

# B. AUR: Tools with 'aur' but NOT the current distro key (Arch only)
AUR_LIST=""
if [[ "$DISTRO" == "arch" ]]; then
    AUR_LIST=$(yq ".tools[] | select(has(\"aur\") and (has(\"arch\") | not)) | .aur" "$TOOLS_FILE" | grep -v "null" | tr '\n' ' ')
fi

# C. FLATPAK: Tools with 'flatpak' but NOT distro key, NOT aur
FLATPAK_LIST=$(yq ".tools[] | select(has(\"flatpak\") and (has(\"$DISTRO\") | not) and (has(\"aur\") | not)) | .flatpak" "$TOOLS_FILE" | grep -v "null" | tr '\n' ' ')

# D. URL: Tools with distro_url but NOT distro, aur, or flatpak
if [[ "$DISTRO" == "pikaos" ]]; then
    URL_LIST=$(yq '.tools[] | select((has("pikaos_url") | not) and (has("pikaos") | not) and (has("debian_url")) and (has("debian") | not) and (has("aur") | not) and (has("flatpak") | not)) | .debian_url' "$TOOLS_FILE" | grep -v "null" | tr '\n' ' ')
else
    URL_LIST=$(yq ".tools[] | select(has(\"${DISTRO}_url\") and (has(\"$DISTRO\") | not) and (has(\"aur\") | not) and (has(\"flatpak\") | not)) | .\"${DISTRO}_url\"" "$TOOLS_FILE" | grep -v "null" | tr '\n' ' ')
fi

# E. SCRIPT: Tools that ONLY have 'script' (no distro, aur, flatpak, or url keys)
SCRIPT_LIST=$(yq '.tools[] | select(has("script") and (has("arch") | not) and (has("aur") | not) and (has("debian") | not) and (has("fedora") | not) and (has("flatpak") | not) and (has("arch_url") | not) and (has("debian_url") | not) and (has("fedora_url") | not) and (has("pikaos") | not) and (has("pikaos_url") | not)) | .script' "$TOOLS_FILE" | grep -v "null" | tr '\n' ' ')

# ── Display classification ──
echo "-----------------------------------------------------------"
[[ -n "$NATIVE_LIST" ]]  && echo "📦 Candidatos Nativo ($DISTRO): $NATIVE_LIST"
[[ -n "$AUR_LIST" ]]     && echo "🏪 Candidatos AUR: $AUR_LIST"
[[ -n "$FLATPAK_LIST" ]] && echo "🚀 Candidatos Flatpak: $FLATPAK_LIST"
[[ -n "$URL_LIST" ]]     && echo "🔗 Candidatos URL: $URL_LIST"
[[ -n "$SCRIPT_LIST" ]]  && echo "📜 Candidatos Script: $SCRIPT_LIST"
[[ -z "$NATIVE_LIST$AUR_LIST$FLATPAK_LIST$URL_LIST$SCRIPT_LIST" ]] && echo "⚠️  No hay candidatos para $DISTRO"
echo "-----------------------------------------------------------"

# ── Phase 2: Installation ──
ALL_KEYS=$(yq '.tools | keys | .[]' "$TOOLS_FILE")
TOTAL=$(echo "$ALL_KEYS" | wc -l)
INSTALLED=0
SKIPPED=0
CURRENT=0

# Count candidates for progress
count_words() { echo $#; }
NATIVE_COUNT=$(count_words $NATIVE_LIST)
AUR_COUNT=$(count_words $AUR_LIST)
FLATPAK_COUNT=$(count_words $FLATPAK_LIST)
URL_COUNT=$(count_words $URL_LIST)
SCRIPT_COUNT=$(count_words $SCRIPT_LIST)
CANDIDATE_TOTAL=$((NATIVE_COUNT + AUR_COUNT + FLATPAK_COUNT + URL_COUNT + SCRIPT_COUNT))

# Install NATIVE (batch — all packages at once)
if [[ -n "$NATIVE_LIST" ]]; then
    echo ""
    echo "── Repos oficiales ($NATIVE_COUNT paquetes) ──"
    if [[ "$DRY_RUN" == true ]]; then
        echo "  [dry-run] $NATIVE_LIST"
        INSTALLED=$((INSTALLED + NATIVE_COUNT))
    elif [[ "$DISTRO" == "arch" ]]; then
        if install_with_pacman "$NATIVE_LIST"; then INSTALLED=$((INSTALLED + NATIVE_COUNT)); fi
    elif [[ "$DISTRO" == "pikaos" ]]; then
        if install_with_pikman "$NATIVE_LIST"; then INSTALLED=$((INSTALLED + NATIVE_COUNT)); fi
    elif [[ "$DISTRO" == "fedora" ]]; then
        if install_with_dnf "$NATIVE_LIST"; then INSTALLED=$((INSTALLED + NATIVE_COUNT)); fi
    else
        if install_with_apt "$NATIVE_LIST"; then INSTALLED=$((INSTALLED + NATIVE_COUNT)); fi
    fi
fi

# Install AUR (batch — all packages at once)
if [[ -n "$AUR_LIST" ]]; then
    echo ""
    echo "── AUR ($AUR_COUNT paquetes) ──"
    if [[ "$DRY_RUN" == true ]]; then
        echo "  [dry-run] $AUR_LIST"
        INSTALLED=$((INSTALLED + AUR_COUNT))
    else
        if install_with_aur "$AUR_LIST"; then INSTALLED=$((INSTALLED + AUR_COUNT)); fi
    fi
fi

# Install FLATPAK (batch — all packages at once)
if [[ -n "$FLATPAK_LIST" ]]; then
    echo ""
    echo "── Flatpak ($FLATPAK_COUNT paquetes) ──"
    if [[ "$DRY_RUN" == true ]]; then
        echo "  [dry-run] $FLATPAK_LIST"
        INSTALLED=$((INSTALLED + FLATPAK_COUNT))
    else
        if install_with_flatpak "$FLATPAK_LIST"; then INSTALLED=$((INSTALLED + FLATPAK_COUNT)); fi
    fi
fi

# Install URL (disabled for this iteration — each URL needs separate download/processing)
# if [[ -n "$URL_LIST" ]]; then
#     echo ""
#     echo "── URL directa ──"
#     for url in $URL_LIST; do
#         CURRENT=$((CURRENT + 1))
#         echo "  [$CURRENT/$CANDIDATE_TOTAL] $url"
#         if [[ "$DRY_RUN" == true ]]; then
#             echo "    [dry-run]"
#             INSTALLED=$((INSTALLED + 1))
#         else
#             if install_from_url "$url"; then INSTALLED=$((INSTALLED + 1)); fi
#         fi
#     done
# fi

# Install SCRIPT (disabled for this iteration — each script runs separately)
# if [[ -n "$SCRIPT_LIST" ]]; then
#     echo ""
#     echo "── Script oficial ──"
#     for script in $SCRIPT_LIST; do
#         CURRENT=$((CURRENT + 1))
#         echo "  [$CURRENT/$CANDIDATE_TOTAL] $script"
#         if [[ "$DRY_RUN" == true ]]; then
#             echo "    [dry-run]"
#             INSTALLED=$((INSTALLED + 1))
#         else
#             if install_with_script "$script"; then INSTALLED=$((INSTALLED + 1)); fi
#         fi
#     done
# fi

SKIPPED=$((TOTAL - INSTALLED))

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
