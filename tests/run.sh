#!/usr/bin/env bash
# =============================================================================
# tests/run.sh — Local test runner
# =============================================================================
# Runs ShellCheck as a quality gate, then BATS for all tests.
#
# Usage:
#   ./tests/run.sh              # run all checks
#   ./tests/run.sh --bats-only  # skip ShellCheck
#   ./tests/run.sh --lint-only  # skip BATS
# =============================================================================

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPTS_DIR="$PROJECT_ROOT/scripts"

# ── Parse flags ──────────────────────────────────────────────────────────────
RUN_LINT=true
RUN_BATS=true

for arg in "$@"; do
    case "$arg" in
        --bats-only)  RUN_LINT=false ;;
        --lint-only)  RUN_BATS=false ;;
        *) echo "Usage: $0 [--bats-only | --lint-only]"; exit 1 ;;
    esac
done

# ── ShellCheck ───────────────────────────────────────────────────────────────
if [[ "$RUN_LINT" == true ]]; then
    echo "═══════════════════════════════════════════════════════════"
    echo "  ShellCheck"
    echo "═══════════════════════════════════════════════════════════"

    if ! command -v shellcheck &>/dev/null; then
        echo "⚠️  shellcheck not found — install it:"
        echo "   Debian/Ubuntu:  sudo apt install shellcheck"
        echo "   Arch:           sudo pacman -S shellcheck"
        echo "   Fedora:         sudo dnf install ShellCheck"
        echo ""
        echo "   Skipping lint step."
    else
        shellcheck \
            "$PROJECT_ROOT/setup.sh" \
            "$PROJECT_ROOT/sync-dotfiles.sh" \
            "$SCRIPTS_DIR"/*.sh

        echo "✅ ShellCheck passed"
    fi
    echo ""
fi

# ── BATS ─────────────────────────────────────────────────────────────────────
if [[ "$RUN_BATS" == true ]]; then
    echo "═══════════════════════════════════════════════════════════"
    echo "  BATS Tests"
    echo "═══════════════════════════════════════════════════════════"

    if ! command -v bats &>/dev/null; then
        echo "⚠️  bats not found — install it:"
        echo "   npm:  npm install -g bats"
        echo "   Arch: sudo pacman -S bats"
        echo "   Homebrew: brew install bats-core"
        echo ""
        echo "   Skipping test step."
    else
        bats "$PROJECT_ROOT/tests/"
        echo "✅ BATS passed"
    fi
    echo ""
fi

# ── Summary ──────────────────────────────────────────────────────────────────
echo "═══════════════════════════════════════════════════════════"
echo "  All checks passed"
echo "═══════════════════════════════════════════════════════════"
