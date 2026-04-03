#!/usr/bin/env bats
# =============================================================================
# tests/unit/distro.bats — Unit tests for distro detection
# =============================================================================

load ../helpers/setup

# Replicate the detect_distro logic from distro.sh so we can test it
# with fixture files instead of the real /etc/os-release.
# This is the EXACT same case statement from distro.sh — keep in sync.
detect_distro_from_file() {
    local os_release="$1"

    if [[ ! -f "$os_release" ]]; then
        echo "unknown"
        return
    fi

    local id
    id=$(. "$os_release" && echo "$ID")
    case "$id" in
        arch|cachyos|manjaro|endeavouros) echo "arch" ;;
        pikaos)                           echo "pikaos" ;;
        debian)                           echo "debian" ;;
        ubuntu|pop|zorin|linuxmint)       echo "debian" ;;
        fedora|nobara)                    echo "fedora" ;;
        *)                                echo "unknown" ;;
    esac
}

# ── Arch Linux ───────────────────────────────────────────────────────────────

@test "detects Arch Linux from arch fixture" {
    result=$(detect_distro_from_file "$FIXTURES_DIR/os-release-arch")
    [ "$result" = "arch" ]
}

# ── Debian ───────────────────────────────────────────────────────────────────

@test "detects Debian from debian fixture" {
    result=$(detect_distro_from_file "$FIXTURES_DIR/os-release-debian")
    [ "$result" = "debian" ]
}

# ── Fedora ───────────────────────────────────────────────────────────────────

@test "detects Fedora from fedora fixture" {
    result=$(detect_distro_from_file "$FIXTURES_DIR/os-release-fedora")
    [ "$result" = "fedora" ]
}

# ── Ubuntu (ID_LIKE fallback mapped to debian) ──────────────────────────────

@test "detects Ubuntu as debian distro family" {
    result=$(detect_distro_from_file "$FIXTURES_DIR/os-release-ubuntu")
    [ "$result" = "debian" ]
}

# ── pikaOS ───────────────────────────────────────────────────────────────────

@test "detects pikaOS from pikaos fixture" {
    result=$(detect_distro_from_file "$FIXTURES_DIR/os-release-pikaos")
    [ "$result" = "pikaos" ]
}

# ── Unknown ──────────────────────────────────────────────────────────────────

@test "returns unknown for unsupported distro" {
    result=$(detect_distro_from_file "$FIXTURES_DIR/os-release-unknown")
    [ "$result" = "unknown" ]
}

@test "returns unknown for missing file" {
    result=$(detect_distro_from_file "/nonexistent/os-release")
    [ "$result" = "unknown" ]
}
