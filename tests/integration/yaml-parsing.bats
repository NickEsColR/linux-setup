#!/usr/bin/env bats
# =============================================================================
# tests/integration/yaml-parsing.bats — Integration tests for tools.yaml + yq
# =============================================================================

load ../helpers/setup

setup() {
    skip_if_no_yq
}

skip_if_no_yq() {
    if ! command -v yq &>/dev/null; then
        skip "yq not installed"
    fi
}

TOOLS_FILE="$PROJECT_ROOT/tools.yaml"

# ── Structure ────────────────────────────────────────────────────────────────

@test "tools.yaml exists and is readable" {
    [ -f "$TOOLS_FILE" ]
}

@test "tools.yaml contains a tools key" {
    run yq '.tools' "$TOOLS_FILE"
    [ "$status" -eq 0 ]
    [ "$output" != "null" ]
}

@test "tools.yaml has at least one tool defined" {
    run yq '.tools | keys | length' "$TOOLS_FILE"
    [ "$status" -eq 0 ]
    [ "$output" -gt 0 ]
}

# ── Distrospecific package names ─────────────────────────────────────────────

@test "git is defined for debian" {
    result=$(yq '.tools.git.debian' "$TOOLS_FILE")
    [ "$result" = "git" ]
}

@test "git is defined for arch" {
    result=$(yq '.tools.git.arch' "$TOOLS_FILE")
    [ "$result" = "git" ]
}

@test "git is defined for fedora" {
    result=$(yq '.tools.git.fedora' "$TOOLS_FILE")
    [ "$result" = "git" ]
}

@test "github-cli maps to gh on debian" {
    result=$(yq '.tools.github-cli.debian' "$TOOLS_FILE")
    [ "$result" = "gh" ]
}

@test "docker has multiple arch packages" {
    result=$(yq '.tools.docker.arch' "$TOOLS_FILE")
    [ "$result" = "docker docker-compose" ]
}

# ── Missing fields return null ───────────────────────────────────────────────

@test "flatseal has no fedora field (returns null)" {
    result=$(yq '.tools.flatseal.fedora' "$TOOLS_FILE")
    [ "$result" = "null" ]
}

@test "flatseal has no debian field (returns null)" {
    result=$(yq '.tools.flatseal.debian' "$TOOLS_FILE")
    [ "$result" = "null" ]
}

# ── Flatpak entries ──────────────────────────────────────────────────────────

@test "brave has flatpak fallback" {
    result=$(yq '.tools.brave.flatpak' "$TOOLS_FILE")
    [ "$result" = "com.brave.Browser" ]
}

@test "flatseal is flatpak-only" {
    flatpak=$(yq '.tools.flatseal.flatpak' "$TOOLS_FILE")
    arch=$(yq '.tools.flatseal.arch' "$TOOLS_FILE")
    debian=$(yq '.tools.flatseal.debian' "$TOOLS_FILE")

    [ "$flatpak" != "null" ]
    [ "$arch" = "null" ]
    [ "$debian" = "null" ]
}

# ── Script-based installs ────────────────────────────────────────────────────

@test "opencode has install script defined" {
    result=$(yq '.tools.opencode.script' "$TOOLS_FILE")
    [ "$result" = "https://opencode.ai/install" ]
}

@test "ollama has install script defined" {
    result=$(yq '.tools.ollama.script' "$TOOLS_FILE")
    [ "$result" = "https://ollama.com/install.sh" ]
}

# ── URL-based installs ───────────────────────────────────────────────────────

@test "zoom has debian_url defined" {
    result=$(yq '.tools.zoom.debian_url' "$TOOLS_FILE")
    [[ "$result" == *"zoom_amd64.deb"* ]]
}

@test "zoom has fedora_url defined" {
    result=$(yq '.tools.zoom.fedora_url' "$TOOLS_FILE")
    [[ "$result" == *"zoom_x86_64.rpm"* ]]
}
