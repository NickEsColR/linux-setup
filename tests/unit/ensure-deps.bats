#!/usr/bin/env bats
# =============================================================================
# tests/unit/ensure-deps.bats — Unit tests for scripts/ensure-deps.sh
# =============================================================================

load ../helpers/setup

# ── ensure_yq ────────────────────────────────────────────────────────────────

@test "ensure_yq returns 0 when yq is already installed" {
    run bash -c '
        source "$SCRIPTS_DIR/ensure-deps.sh"
        command() { [[ "$1" == "-v" && "$2" == "yq" ]] && return 0; return 1; }
        ensure_yq
    '
    [ "$status" -eq 0 ]
}

@test "ensure_yq exits 1 on unsupported architecture" {
    run bash -c '
        source "$SCRIPTS_DIR/ensure-deps.sh"
        command() { return 1; }
        uname() { echo "armv7l"; }
        ensure_yq
    '
    [ "$status" -eq 1 ]
    [[ "$output" == *"Unsupported architecture"* ]]
}

# ── ensure_paru ──────────────────────────────────────────────────────────────

@test "ensure_paru returns 0 on non-arch distros (no-op)" {
    run bash -c '
        source "$SCRIPTS_DIR/ensure-deps.sh"
        DISTRO=debian
        ensure_paru
    '
    [ "$status" -eq 0 ]
}

@test "ensure_paru returns 0 on fedora (no-op)" {
    run bash -c '
        source "$SCRIPTS_DIR/ensure-deps.sh"
        DISTRO=fedora
        ensure_paru
    '
    [ "$status" -eq 0 ]
}

@test "ensure_paru returns 0 on pikaos (no-op)" {
    run bash -c '
        source "$SCRIPTS_DIR/ensure-deps.sh"
        DISTRO=pikaos
        ensure_paru
    '
    [ "$status" -eq 0 ]
}

@test "ensure_paru returns 0 when paru is already installed on arch" {
    run bash -c '
        source "$SCRIPTS_DIR/ensure-deps.sh"
        DISTRO=arch
        command() { [[ "$1" == "-v" && "$2" == "paru" ]] && return 0; return 1; }
        ensure_paru
    '
    [ "$status" -eq 0 ]
}

# ── ensure_flatpak ───────────────────────────────────────────────────────────

@test "ensure_flatpak returns 0 when flatpak is already installed" {
    run bash -c '
        source "$SCRIPTS_DIR/ensure-deps.sh"
        command() { [[ "$1" == "-v" && "$2" == "flatpak" ]] && return 0; return 1; }
        ensure_flatpak
    '
    [ "$status" -eq 0 ]
}

@test "ensure_flatpak uses pacman on arch" {
    run bash -c '
        source "$SCRIPTS_DIR/ensure-deps.sh"
        DISTRO=arch
        command() { return 1; }
        sudo() { echo "sudo called: $*"; return 1; }
        ensure_flatpak || true
    '
    [[ "$output" == *"pacman"* ]]
}

@test "ensure_flatpak uses dnf on fedora" {
    run bash -c '
        source "$SCRIPTS_DIR/ensure-deps.sh"
        DISTRO=fedora
        command() { return 1; }
        sudo() { echo "sudo called: $*"; return 1; }
        ensure_flatpak || true
    '
    [[ "$output" == *"dnf"* ]]
}

@test "ensure_flatpak uses apt on debian" {
    run bash -c '
        source "$SCRIPTS_DIR/ensure-deps.sh"
        DISTRO=debian
        command() { return 1; }
        sudo() { echo "sudo called: $*"; return 1; }
        ensure_flatpak || true
    '
    [[ "$output" == *"apt"* ]]
}

@test "ensure_flatpak uses apt on ubuntu" {
    run bash -c '
        source "$SCRIPTS_DIR/ensure-deps.sh"
        DISTRO=ubuntu
        command() { return 1; }
        sudo() { echo "sudo called: $*"; return 1; }
        ensure_flatpak || true
    '
    [[ "$output" == *"apt"* ]]
}

@test "ensure_flatpak uses pikman fallback on pikaos" {
    run bash -c '
        source "$SCRIPTS_DIR/ensure-deps.sh"
        DISTRO=pikaos
        command() { return 1; }
        sudo() { echo "sudo called: $*"; return 1; }
        ensure_flatpak || true
    '
    [[ "$output" == *"pikman"* ]]
}

# ── ensure_flathub ───────────────────────────────────────────────────────────

@test "ensure_flathub returns 0 when flathub remote already exists" {
    run bash -c '
        source "$SCRIPTS_DIR/ensure-deps.sh"
        command() { [[ "$1" == "-v" && "$2" == "flatpak" ]] && return 0; return 1; }
        flatpak() { echo "flathub"; }
        ensure_flathub
    '
    [ "$status" -eq 0 ]
}

@test "ensure_flathub returns 1 when flatpak is not available" {
    run bash -c '
        source "$SCRIPTS_DIR/ensure-deps.sh"
        command() { return 1; }
        sudo() { return 1; }
        ensure_flathub
    '
    [ "$status" -eq 1 ]
}
