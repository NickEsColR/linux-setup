# Testing Infrastructure Specification

## Purpose

Automated test infrastructure for the multi-distro setup shell scripts. Ensures correctness of logging, distro detection, YAML parsing, and installer helpers before execution on real systems.

## Requirements

### Requirement: Test Runner

The project SHALL provide a command to execute all tests locally and in CI.

#### Scenario: Run all tests locally

- GIVEN BATS and ShellCheck are installed
- WHEN `tests/run.sh` is executed
- THEN ShellCheck analyzes all `.sh` files in `scripts/` and root
- AND BATS executes all `.bats` files under `tests/`
- AND the exit code is 0 only if all checks pass

#### Scenario: Run tests in CI

- GIVEN a GitHub Actions workflow triggers on push/PR
- WHEN the workflow runs on `ubuntu-latest`
- THEN ShellCheck runs first as a quality gate
- AND BATS runs after ShellCheck passes
- AND the workflow fails if any step fails

### Requirement: Logging Functions

All public functions in `logging.sh` SHALL produce correct output and behavior.

#### Scenario: log_section prints formatted header

- GIVEN the `log_section` function is called with "Test"
- WHEN the function executes
- THEN output contains "Test" surrounded by cyan separator lines

#### Scenario: log_step prints success indicator

- GIVEN the `log_step` function is called with "done"
- WHEN the function executes
- THEN output contains "done" with a green checkmark

#### Scenario: log_warn prints warning indicator

- GIVEN the `log_warn` function is called with "caution"
- WHEN the function executes
- THEN output contains "caution" with a yellow warning indicator

#### Scenario: log_error prints error indicator

- GIVEN the `log_error` function is called with "fail"
- WHEN the function executes
- THEN output contains "fail" with a red error indicator

#### Scenario: ensure_not_root exits when EUID is 0

- GIVEN EUID is set to 0
- WHEN `ensure_not_root` is called
- THEN the script exits with code 1

#### Scenario: ensure_not_root succeeds for non-root

- GIVEN EUID is set to 1000
- WHEN `ensure_not_root` is called
- THEN the script exits with code 0

### Requirement: Distro Detection

The system SHALL correctly identify the Linux distribution from `/etc/os-release`.

#### Scenario: Detect Arch Linux

- GIVEN `/etc/os-release` contains `ID=arch`
- WHEN distro detection runs
- THEN DISTRO is set to "arch"

#### Scenario: Detect Debian

- GIVEN `/etc/os-release` contains `ID=debian`
- WHEN distro detection runs
- THEN DISTRO is set to "debian"

#### Scenario: Detect Fedora

- GIVEN `/etc/os-release` contains `ID=fedora`
- WHEN distro detection runs
- THEN DISTRO is set to "fedora"

#### Scenario: Detect Ubuntu (ID_LIKE fallback)

- GIVEN `/etc/os-release` contains `ID=ubuntu` and `ID_LIKE=debian`
- WHEN distro detection runs
- THEN DISTRO is set to "debian"

#### Scenario: Detect pikaOS

- GIVEN `/etc/os-release` contains `ID=pikaos`
- WHEN distro detection runs
- THEN DISTRO is set to "pikaos"

#### Scenario: Unknown distro exits with error

- GIVEN `/etc/os-release` contains `ID=unknown` with no matching ID_LIKE
- WHEN distro detection runs
- THEN the script exits with code 1

### Requirement: YAML Parsing

The system SHALL correctly parse tool definitions from `tools.yaml` using `yq`.

#### Scenario: Extract tool keys

- GIVEN `tools.yaml` contains multiple tool entries
- WHEN querying `.tools | keys`
- THEN all tool names are returned as a list

#### Scenario: Get distro-specific package name

- GIVEN a tool defines `debian: "git"`
- WHEN querying `.tools.git.debian`
- THEN the value "git" is returned

#### Scenario: Missing distro field returns null

- GIVEN a tool does not define a `fedora` field
- WHEN querying `.tools.flatseal.fedora`
- THEN the value is null or empty

#### Scenario: pikaos fallback to debian

- GIVEN a tool defines `debian: "pkg"` but no `pikaos`
- WHEN resolving for pikaos distro
- THEN the debian value is used as fallback

### Requirement: Test Fixtures

The project SHALL provide mock `/etc/os-release` files for each supported distro family.

#### Scenario: Arch fixture exists

- GIVEN `tests/fixtures/os-release-arch`
- WHEN the file is read
- THEN it contains `ID=arch` and `PRETTY_NAME` for Arch Linux

#### Scenario: Debian fixture exists

- GIVEN `tests/fixtures/os-release-debian`
- WHEN the file is read
- THEN it contains `ID=debian` and `PRETTY_NAME` for Debian

#### Scenario: Fedora fixture exists

- GIVEN `tests/fixtures/os-release-fedora`
- WHEN the file is read
- THEN it contains `ID=fedora` and `PRETTY_NAME` for Fedora
