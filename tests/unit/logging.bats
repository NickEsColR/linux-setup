#!/usr/bin/env bats
# =============================================================================
# tests/unit/logging.bats — Unit tests for scripts/logging.sh
# =============================================================================

load ../helpers/setup

setup() {
    # Source logging without ensure_not_root auto-executing anything
    source "$SCRIPTS_DIR/logging.sh"
}

# ── log_section ──────────────────────────────────────────────────────────────

@test "log_section output contains the section text" {
    run log_section "Test Section"
    [ "$status" -eq 0 ]
    [[ "$output" == *"Test Section"* ]]
}

@test "log_section output contains separator lines" {
    run log_section "Test Section"
    [[ "$output" == *"═"* ]]
}

# ── log_step ─────────────────────────────────────────────────────────────────

@test "log_step output contains the step text" {
    run log_step "done"
    [ "$status" -eq 0 ]
    [[ "$output" == *"done"* ]]
}

@test "log_step output contains checkmark" {
    run log_step "done"
    [[ "$output" == *"✓"* ]]
}

# ── log_warn ─────────────────────────────────────────────────────────────────

@test "log_warn output contains the warning text" {
    run log_warn "caution"
    [ "$status" -eq 0 ]
    [[ "$output" == *"caution"* ]]
}

@test "log_warn output contains warning indicator" {
    run log_warn "caution"
    [[ "$output" == *"[!"* ]]
}

# ── log_error ────────────────────────────────────────────────────────────────

@test "log_error output contains the error text" {
    run log_error "fail"
    [ "$status" -eq 0 ]
    [[ "$output" == *"fail"* ]]
}

@test "log_error output contains error indicator" {
    run log_error "fail"
    [[ "$output" == *"[✗]"* ]]
}

# ── log_info ─────────────────────────────────────────────────────────────────

@test "log_info output contains the info text" {
    run log_info "info msg"
    [ "$status" -eq 0 ]
    [[ "$output" == *"info msg"* ]]
}

@test "log_info output contains info indicator" {
    run log_info "info msg"
    [[ "$output" == *"[i]"* ]]
}

# ── ensure_not_root ──────────────────────────────────────────────────────────

@test "ensure_not_root exits 1 when EUID is 0" {
    run bash -c "source '$SCRIPTS_DIR/logging.sh'; EUID=0; ensure_not_root"
    [ "$status" -eq 1 ]
}

@test "ensure_not_root exits 0 when EUID is non-zero" {
    run bash -c "source '$SCRIPTS_DIR/logging.sh'; EUID=1000; ensure_not_root"
    [ "$status" -eq 0 ]
}
