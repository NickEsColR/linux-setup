#!/bin/bash
# =============================================================================
# Dotfile synchronization (does not install tools)
# =============================================================================
# Usage: ./sync-dotfiles.sh
#
# To add a new dotfile:
#   1. Place the file in dotfiles/ (e.g., dotfiles/nvim/init.lua)
#   2. Add a line to DOTFILES=(...) below
#   Done. The script handles the rest.
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$SCRIPT_DIR/dotfiles"
BACKUP_DIR="$HOME/.dotfiles-backups"

source "$SCRIPT_DIR/scripts/logging.sh"

ensure_not_root

# ─── Declarative dotfile list ───────────────────────────────────────────────
# Format: "source_path:destination_path"
#   - source_path: relative to dotfiles/
#   - destination_path: absolute (use $HOME)
#
# To add a new one, just append a line.
# No need to touch the script logic.
# ─────────────────────────────────────────────────────────────────────────────

DOTFILES=(
    "git/.gitconfig:$HOME/.gitconfig"
)

# ─── Functions ──────────────────────────────────────────────────────────────

backup_if_exists() {
    local dest="$1"

    if [[ ! -f "$dest" ]]; then
        return 1
    fi

    mkdir -p "$BACKUP_DIR"

    local filename
    filename="$(basename "$dest")"
    local backup_name="${filename}.bak.$(date +%Y%m%dT%H%M%S)"
    local backup_path="$BACKUP_DIR/$backup_name"

    cp "$dest" "$backup_path"
    log_warn "Backup created: $dest → $backup_path"
    return 0
}

files_are_equal() {
    cmp -s "$1" "$2"
}

sync_dotfile() {
    local entry="$1"
    local src="${entry%%:*}"
    local dest="${entry##*:}"

    local src_path="$DOTFILES_DIR/$src"

    if [[ ! -f "$src_path" ]]; then
        log_error "Source not found: $src_path"
        return 1
    fi

    # Destination exists and is identical? Skip.
    if [[ -f "$dest" ]] && files_are_equal "$src_path" "$dest"; then
        log_info "$src — unchanged, skipped"
        return 2  # 2 = skipped
    fi

    # Create destination directory if needed
    local dest_dir
    dest_dir="$(dirname "$dest")"
    mkdir -p "$dest_dir"

    # Backup if exists and differs
    backup_if_exists "$dest"

    # Copy
    cp "$src_path" "$dest"
    log_step "$src → $dest"
    return 0
}

# ─── Execution ──────────────────────────────────────────────────────────────

log_section "SYNCING DOTFILES"
log_info "User:    $USER"
log_info "Source:  $DOTFILES_DIR"
log_info "Dest:    $HOME"
echo ""

if [[ ! -d "$DOTFILES_DIR" ]]; then
    log_error "Dotfiles directory not found: $DOTFILES_DIR"
    exit 1
fi

synced=0
skipped=0
failed=0

for entry in "${DOTFILES[@]}"; do
    rc=0
    sync_dotfile "$entry" || rc=$?
    case $rc in
        0) synced=$((synced + 1)) ;;
        2) skipped=$((skipped + 1)) ;;
        *) failed=$((failed + 1)) ;;
    esac
done

# ─── Summary ────────────────────────────────────────────────────────────────

log_section "SUMMARY"
echo -e "  ${GREEN}Synced:   $synced${NC}"
if [[ $skipped -gt 0 ]]; then
    echo -e "  ${BLUE}Skipped:  $skipped${NC}"
fi
if [[ $failed -gt 0 ]]; then
    echo -e "  ${RED}Failed:   $failed${NC}"
fi
echo -e "  ${BLUE}Backups:  $BACKUP_DIR${NC}"
echo ""
