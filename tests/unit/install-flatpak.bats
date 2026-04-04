#!/usr/bin/env bats
# =============================================================================
# tests/unit/install-flatpak.bats — Unit tests for scripts/install-flatpak.sh
# =============================================================================

load ../helpers/setup

setup() {
    source "$SCRIPTS_DIR/install-flatpak.sh"
}

# ── install_with_flatpak ─────────────────────────────────────────────────────

@test "install_with_flatpak returns 1 for empty app_id" {
    run install_with_flatpak ""
    [ "$status" -eq 1 ]
}

@test "install_with_flatpak returns 1 for null app_id" {
    run install_with_flatpak "null"
    [ "$status" -eq 1 ]
}

@test "install_with_flatpak calls flatpak install with correct args" {
    # Stub flatpak to capture the call
    run bash -c '
        source "$SCRIPTS_DIR/install-flatpak.sh"
        flatpak() { echo "flatpak called with: $*"; }
        install_with_flatpak "com.github.Flathub.App"
    '
    [ "$status" -eq 0 ]
    [[ "$output" == *"flatpak install flathub com.github.Flathub.App"* ]]
}
