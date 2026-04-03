# Design: Test Infrastructure for Shell Scripts

## Technical Approach

BATS framework for testable shell functions + ShellCheck for static analysis. Tests run in isolation by mocking filesystem dependencies (`/etc/os-release`, commands like `pacman`, `apt`, `flatpak`). No real package installation occurs — all installers are tested for correct command construction and guard clauses only.

## Architecture Decisions

### Decision: BATS as test framework

**Choice**: bats-core 1.10+
**Alternatives considered**: shUnit2, manual test scripts, Docker-only testing
**Rationale**: BATS has native `@test` syntax, `run` helper for capturing output/exit codes, `load` for shared helpers, and first-class GitHub Actions integration. shUnit2 is older and more verbose.

### Decision: Mock via PATH override, not containers

**Choice**: Override PATH with stub scripts in `tests/mocks/`
**Alternatives considered**: Docker containers per distro, function redefinition with `eval`
**Rationale**: We're testing that the scripts construct the **correct commands**, not that the package managers work. A stub `pacman` that echoes its args is sufficient and 100x faster than containers.

### Decision: Test `distro.sh` detection via fixture files

**Choice**: Copy fixture `os-release-*` to a temp dir, source `detect_distro` with overridden path
**Alternatives considered**: Mock `/etc/os-release` directly (requires root), redefine the function
**Rationale**: `detect_distro` reads `/etc/os-release` hardcoded. We'll create a testable wrapper that accepts a path parameter, keeping the original behavior intact.

### Decision: ShellCheck as pre-test gate

**Choice**: Run ShellCheck before BATS
**Alternatives considered**: ShellCheck only in CI, ShellCheck as a BATS test
**Rationale**: ShellCatch catches syntax errors that would make BATS tests fail for the wrong reasons. It's a fast fail that saves CI time.

## Data Flow

```
tests/run.sh
├── ShellCheck → scripts/*.sh, setup.sh, sync-dotfiles.sh
│   └── fail → exit 1
│   └── pass ↓
├── BATS → tests/unit/*.bats
│   ├── logging.bats   (pure functions, no mocks needed)
│   └── distro.bats    (fixtures/os-release-* → detect_distro)
├── BATS → tests/integration/*.bats
│   └── yaml-parsing.bats  (tools.yaml → yq queries)
└── exit 0 if all pass
```

## File Changes

| File | Action | Description |
|------|--------|-------------|
| `tests/run.sh` | Create | Local test runner: ShellCheck + BATS |
| `tests/helpers/setup.bash` | Create | Shared BATS setup: project root, PATH for mocks |
| `tests/unit/logging.bats` | Create | Tests for all logging functions |
| `tests/unit/distro.bats` | Create | Tests for distro detection with fixtures |
| `tests/integration/yaml-parsing.bats` | Create | Tests for tools.yaml structure and yq queries |
| `tests/fixtures/os-release-arch` | Create | Mock os-release for Arch Linux |
| `tests/fixtures/os-release-debian` | Create | Mock os-release for Debian |
| `tests/fixtures/os-release-fedora` | Create | Mock os-release for Fedora |
| `tests/fixtures/os-release-ubuntu` | Create | Mock os-release for Ubuntu (ID_LIKE=debian) |
| `tests/fixtures/os-release-pikaos` | Create | Mock os-release for pikaOS |
| `tests/fixtures/os-release-unknown` | Create | Mock os-release for unsupported distro |
| `.github/workflows/test.yml` | Create | CI workflow: ShellCheck + BATS on push/PR |

## Testing Strategy

| Layer | What to Test | Approach |
|-------|-------------|----------|
| Unit | `logging.sh` functions | Direct sourcing, assert output patterns |
| Unit | `detect_distro()` | Fixture os-release files, assert DISTRO value |
| Integration | `tools.yaml` + `yq` queries | Run actual yq commands against real tools.yaml |
| Static | All `.sh` files | ShellCheck with project-relevant rules |

## Key Implementation Detail: Testing `detect_distro`

The current `distro.sh` sources and runs detection immediately at load time (line 21: `DISTRO=$(detect_distro)`). To test `detect_distro` in isolation with fixtures, we extract just the function for testing:

```bash
# In tests/unit/distro.bats:
# Source only the function, not the auto-execution
detect_distro_from_file() {
    local os_release="$1"
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
```

This avoids modifying `distro.sh` while still testing the exact same logic.

## Migration / Rollout

No migration needed. Tests are additive — no existing files are modified.

## Open Questions

- None. The approach is self-contained and non-destructive.
