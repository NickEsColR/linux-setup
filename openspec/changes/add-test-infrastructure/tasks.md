# Tasks: Test Infrastructure for Shell Scripts

## Phase 1: Fixtures and Helpers

- [ ] 1.1 Create `tests/fixtures/os-release-arch` with `ID=arch`, `PRETTY_NAME="Arch Linux"`
- [ ] 1.2 Create `tests/fixtures/os-release-debian` with `ID=debian`, `PRETTY_NAME="Debian GNU/Linux"`
- [ ] 1.3 Create `tests/fixtures/os-release-fedora` with `ID=fedora`, `PRETTY_NAME="Fedora Linux"`
- [ ] 1.4 Create `tests/fixtures/os-release-ubuntu` with `ID=ubuntu`, `ID_LIKE=debian`
- [ ] 1.5 Create `tests/fixtures/os-release-pikaos` with `ID=pikaos`, `PRETTY_NAME="pikaOS"`
- [ ] 1.6 Create `tests/fixtures/os-release-unknown` with `ID=unknown`
- [ ] 1.7 Create `tests/helpers/setup.bash` with `PROJECT_ROOT` detection and common BATS load

## Phase 2: Test Runner

- [ ] 2.1 Create `tests/run.sh` that runs ShellCheck on all `.sh` files, then runs `bats tests/`
- [ ] 2.2 Make `tests/run.sh` exit non-zero if ShellCheck or BATS fails

## Phase 3: Unit Tests — Logging

- [ ] 3.1 Create `tests/unit/logging.bats` with test for `log_section` output contains input text
- [ ] 3.2 Add test for `log_step` output contains input text
- [ ] 3.3 Add test for `log_warn` output contains input text
- [ ] 3.4 Add test for `log_error` output contains input text
- [ ] 3.5 Add test for `log_info` output contains input text
- [ ] 3.6 Add test: `ensure_not_root` exits 1 when EUID=0
- [ ] 3.7 Add test: `ensure_not_root` exits 0 when EUID=1000

## Phase 4: Unit Tests — Distro Detection

- [ ] 4.1 Create `tests/unit/distro.bats` with `detect_distro_from_file()` helper (copies logic from `distro.sh`)
- [ ] 4.2 Add test: arch fixture returns "arch"
- [ ] 4.3 Add test: debian fixture returns "debian"
- [ ] 4.4 Add test: fedora fixture returns "fedora"
- [ ] 4.5 Add test: ubuntu fixture returns "debian" (ID_LIKE fallback)
- [ ] 4.6 Add test: pikaos fixture returns "pikaos"
- [ ] 4.7 Add test: unknown fixture returns "unknown"
- [ ] 4.8 Add test: missing file returns "unknown"

## Phase 5: Integration Tests — YAML Parsing

- [ ] 5.1 Create `tests/integration/yaml-parsing.bats` with skip if `yq` not installed
- [ ] 5.2 Add test: `yq '.tools | keys'` returns non-empty list from `tools.yaml`
- [ ] 5.3 Add test: `.tools.git.debian` returns "git"
- [ ] 5.4 Add test: `.tools.flatseal.fedora` returns null/empty
- [ ] 5.5 Add test: `.tools.docker.arch` returns "docker docker-compose"
- [ ] 5.6 Add test: pikaos fallback — `.tools.opencode.debian` returns empty (script-based tool)

## Phase 6: CI Pipeline

- [ ] 6.1 Create `.github/workflows/test.yml` with `on: [push, pull_request]`
- [ ] 6.2 Add ShellCheck job: checkout → install shellcheck → run on `setup.sh scripts/*.sh sync-dotfiles.sh`
- [ ] 6.3 Add BATS job: checkout → install bats → run `bats tests/`
- [ ] 6.4 Verify YAML syntax is valid
