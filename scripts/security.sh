#!/bin/bash
# =============================================================================
# security.sh — Security checks for installation
# =============================================================================
# Functions:
#   verify_checksum "$file" "$expected_sha256" → verifies SHA256
#   show_script_preview "$file" → shows script content
#   confirm_install "$tool_name" "$source" → asks for manual confirmation
#   download_safely "$url" "$output" "$expected_sha256" → downloads + verifies
#   verify_gpg_signature "$file" "$keyserver" "$keyid" → verifies GPG signature
#
# Variables:
#   INTERACTIVE=false by default, true with --interactive
# =============================================================================

INTERACTIVE=false

# ─── Verify SHA256 checksum ─────────────────────────────────────────────────
# Usage: verify_checksum "/path/to/file" "abc123..."
# Returns: 0 if match, 1 if not, 2 if expected is empty
verify_checksum() {
    local file="$1"
    local expected="$2"

    if [[ -z "$expected" || "$expected" == "null" ]]; then
        return 2  # no checksum = no verification
    fi

    if [[ ! -f "$file" ]]; then
        log_error "File not found for verification: $file"
        return 1
    fi

    local actual
    actual=$(sha256sum "$file" | awk '{print $1}')

    if [[ "$actual" != "$expected" ]]; then
        log_error "CHECKSUM MISMATCH"
        log_error "  Expected: $expected"
        log_error "  Got:      $actual"
        log_error "  File:     $file"
        log_error "ABORTED — possible file tampering"
        return 1
    fi

    log_step "checksum verified ✓"
    return 0
}

# ─── Secure download with verification ──────────────────────────────────────
# Usage: download_safely "$url" "$output_path" "$expected_sha256"
# Returns: 0 if downloaded and verified, 1 if failed
download_safely() {
    local url="$1"
    local output="$2"
    local expected_sha256="${3:-}"

    log_info "Downloading: $url"

    if ! curl -fsSL "$url" -o "$output"; then
        log_error "Download failed: $url"
        return 1
    fi

    # Verify it's not HTML (redirect to error page)
    local mime
    mime=$(file --mime-type -b "$output" 2>/dev/null || echo "unknown")
    if [[ "$mime" == "text/html" ]]; then
        log_error "Download returned HTML instead of file (url: $url)"
        rm -f "$output"
        return 1
    fi

    # Verify checksum if provided
    if [[ -n "$expected_sha256" ]]; then
        verify_checksum "$output" "$expected_sha256" || return 1
    fi

    return 0
}

# ─── Show script preview before execution ───────────────────────────────────
# Usage: show_script_preview "/path/to/script"
show_script_preview() {
    local file="$1"

    if [[ ! -f "$file" ]]; then
        return 1
    fi

    local lines
    lines=$(wc -l < "$file")
    local size
    size=$(du -h "$file" | awk '{print $1}')

    echo ""
    echo -e "${YELLOW}┌─────────────────────────────────────────────────────────────┐${NC}"
    echo -e "${YELLOW}│  DOWNLOADED SCRIPT — REVIEW BEFORE EXECUTING                │${NC}"
    echo -e "${YELLOW}├─────────────────────────────────────────────────────────────┤${NC}"
    echo -e "${CYAN}  File:   $file${NC}"
    echo -e "${CYAN}  Size:   $size ($lines lines)${NC}"
    echo -e "${YELLOW}├─────────────────────────────────────────────────────────────┤${NC}"

    # Show first 50 lines
    if [[ "$lines" -le 50 ]]; then
        cat "$file"
    else
        head -n 50 "$file"
        echo ""
        echo -e "${YELLOW}  ... (showing 50 of $lines lines)${NC}"
        echo -e "${CYAN}  View full: cat '$file'${NC}"
    fi

    echo -e "${YELLOW}└─────────────────────────────────────────────────────────────┘${NC}"
    echo ""
}

# ─── Manual confirmation before install ─────────────────────────────────────
# Usage: confirm_install "tool_name" "source (pacman/apt/script/etc)"
# Returns: 0 if accepted, 1 if rejected
confirm_install() {
    local tool="$1"
    local source="$2"

    if [[ "$INTERACTIVE" == false ]]; then
        return 0  # auto mode, don't ask
    fi

    echo ""
    echo -e "${YELLOW}  Install ${CYAN}$tool${YELLOW} via ${CYAN}$source${YELLOW}?${NC}"
    echo -e "  [Enter] Yes  │  [n] No  │  [a] Abort all"
    echo -n "  → "

    local answer
    read -r answer

    case "$answer" in
        ""|[yY])
            return 0
            ;;
        [aA])
            log_error "Aborted by user"
            exit 1
            ;;
        *)
            log_warn "Skipping: $tool"
            return 1
            ;;
    esac
}

# ─── Confirmation for install scripts ───────────────────────────────────────
# More aggressive: requires double confirmation
# Usage: confirm_script_execution "tool_name" "url" "/path/to/script"
# Returns: 0 if accepted, 1 if rejected
confirm_script_execution() {
    local tool="$1"
    local url="$2"
    local script_path="$3"

    if [[ "$INTERACTIVE" == false ]]; then
        # Without --interactive: show warning but continue
        log_warn "Running remote script for '$tool' without manual review"
        log_warn "URL: $url"
        log_warn "Use --interactive to review scripts before executing"
        return 0
    fi

    # Interactive mode: show preview and ask for confirmation
    show_script_preview "$script_path"

    while true; do
        echo -e "${RED}  ⚠️  WARNING: This script will run WITH ROOT PERMISSIONS${NC}"
        echo -e "${RED}  ⚠️  Review the code above before continuing${NC}"
        echo ""
        echo -e "${YELLOW}  Execute script to install ${CYAN}$tool${YELLOW}?${NC}"
        echo -e "  [Enter] Yes  │  [v] View full  │  [n] No  │  [a] Abort"
        echo -n "  → "

        local answer
        read -r answer

        case "$answer" in
            ""|[yY])
                return 0
                ;;
            [vV])
                less < "$script_path"
                # Ask again (loop, not recursion)
                ;;
            [aA])
                log_error "Aborted by user"
                exit 1
                ;;
            *)
                log_warn "Skipping script: $tool"
                return 1
                ;;
        esac
    done
}

# ─── Verify GPG signature ───────────────────────────────────────────────────
# Usage: verify_gpg_signature "file" "sig_file" "keyid"
# Returns: 0 if valid, 1 if not
verify_gpg_signature() {
    local file="$1"
    local sig_file="$2"
    local keyid="${3:-}"

    if [[ ! -f "$sig_file" ]]; then
        log_warn "No GPG signature file: $sig_file"
        return 2  # no signature to verify
    fi

    # Import key if keyid provided
    if [[ -n "$keyid" ]]; then
        if ! gpg --list-keys "$keyid" &>/dev/null; then
            log_info "Importing GPG key: $keyid"
            gpg --keyserver hkps://keys.openpgp.org --recv-keys "$keyid" 2>/dev/null || \
            gpg --keyserver hkps://keyserver.ubuntu.com --recv-keys "$keyid" 2>/dev/null || {
                log_warn "Could not import GPG key: $keyid"
                return 2
            }
        fi
    fi

    if gpg --verify "$sig_file" "$file" 2>/dev/null; then
        log_step "GPG signature verified ✓"
        return 0
    else
        log_error "INVALID GPG SIGNATURE — possible tampering"
        return 1
    fi
}

# ─── Security logging ───────────────────────────────────────────────────────
# Records each install action for auditing
LOG_FILE="${LOG_FILE:-${HOME}/.local/state/my-software-setup/logs/$(date +%Y%m%d).log}"
mkdir -p "$(dirname "$LOG_FILE")" 2>/dev/null || true

log_security_event() {
    local action="$1"
    local tool="$2"
    local source="$3"
    local result="$4"
    local timestamp
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

    echo "[$timestamp] $action | tool=$tool | source=$source | result=$result" >> "$LOG_FILE"
}
