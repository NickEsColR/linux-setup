#!/usr/bin/env bash
# =============================================================================
# tests/helpers/setup.bash — Shared BATS setup
# =============================================================================

# Project root: two levels up from this file
export PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
export SCRIPTS_DIR="$PROJECT_ROOT/scripts"
export FIXTURES_DIR="$PROJECT_ROOT/tests/fixtures"
