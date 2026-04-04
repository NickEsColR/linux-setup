# my-software-setup

Declarative, multi-distro Linux software installer. One YAML file, every distro.

## Design Philosophy

**The script asks. You confirm.**

Every package manager handles its own prompts — `apt` asks `[Y/n]`, `pacman` asks `[Y/n]`, `flatpak` asks to confirm. The installers don't suppress these prompts because **you should know exactly what's being installed on your system**.

No hidden `--noconfirm`, no silent installs. If you want automation, pipe your own input.

## Supported Distros

| Distro | Package Manager |
|--------|----------------|
| Arch, CachyOS, Manjaro, EndeavourOS | `pacman` |
| pikaOS | `pikman` (unified manager) |
| Debian, Ubuntu, Mint, Pop!_OS, Zorin | `apt` |
| Fedora, Nobara | `dnf` |

Flatpak is available as a universal fallback on all distros.

## Quick Start

```bash
# 1. Clone
git clone https://github.com/NickEsColR/my-software-setup.git
cd my-software-setup

# 2. Recommended: guided install (native + AUR auto, rest shown as commands)
./guide.sh

# 3. Or try the full automated installer (may fail on some setups)
./setup.sh

# 4. Preview what setup.sh would install
./setup.sh --dry-run

# 5. Sync dotfiles
./sync-dotfiles.sh
```

## How It Works

### Two Installers

| Script | Behavior | Best for |
|--------|----------|----------|
| `guide.sh` | Installs native + AUR packages automatically. Shows you the exact commands to run manually for Flatpak, URL downloads, and install scripts. | **Recommended** — you stay in control |
| `setup.sh` | Attempts to install everything automatically (native, AUR, Flatpak in batch). URL and script installs are currently disabled. May fail if any package in the batch has issues. | Full automation (use at your own risk) |

### Single Source of Truth

Everything lives in [`tools.yaml`](tools.yaml). Add a tool once, install it everywhere:

```yaml
tools:
  brave:
    arch: "brave-bin"           # AUR package
    debian: "brave-browser"     # apt package
    fedora: "brave-browser"     # dnf package
    flatpak: "com.brave.Browser" # universal fallback
```

### Installation Cascade

For each tool, the script tries sources in order of trust:

```
1. Official repo (pacman / pikman / apt / dnf)  ← most trusted, auto-installed
2. AUR (Arch only, via paru)                    ← auto-installed
3. Flatpak                                      ← shown as manual command
4. Direct URL (.deb / .rpm)                     ← shown as manual command
5. Official install script                      ← shown as manual command
```

### guide.sh — Prerequisites

Before installing anything, `guide.sh` checks that required tools are available:

- **yq** (YAML processor) — required to read `tools.yaml`. If missing, the script shows the download command and exits.
- **paru** (AUR helper) — required on Arch if any AUR packages are defined. If missing, shows build commands and exits.
- **flatpak** — required if any Flatpak packages are defined. If missing, shows install commands and exits.

Once all prerequisites are met, native and AUR packages are installed in batch. Flatpak, URL, and script commands are printed for you to run manually.

### pikaOS Behavior

pikaOS uses `pikman` (the unified PikaOS package manager) as its primary installer. If a `pikaos` field isn't defined in `tools.yaml`, it falls back to `debian` — since pikaOS is Debian-based and can use apt-compatible packages.

## Adding a New Tool

Edit [`tools.yaml`](tools.yaml). That's it.

```yaml
tools:
  my-new-tool:
    arch: "my-tool"              # pacman repo
    pikaos: "my-tool"            # pikman (optional — falls back to debian)
    debian: "my-tool"            # apt
    fedora: "my-tool"            # dnf
    flatpak: "com.example.Tool"  # flathub
    debian_url: "https://..."    # direct .deb download
    script: "https://..."        # official install script
```

Fields you don't need? Just omit them. No `null`, no placeholders.

## Adding a New Dotfile

1. Place the file in `dotfiles/` (e.g., `dotfiles/nvim/init.lua`)
2. Add an entry to the `DOTFILES` array in [`sync-dotfiles.sh`](sync-dotfiles.sh):

```bash
DOTFILES=(
    "git/.gitconfig:$HOME/.gitconfig"
    "nvim/init.lua:$HOME/.config/nvim/init.lua"  # ← new
)
```

3. Run `./sync-dotfiles.sh`

Existing files are backed up to `~/.dotfiles-backups/` before being overwritten. Identical files are skipped.

## Project Structure

```
├── guide.sh                  # Guided installer (recommended)
├── setup.sh                  # Full automated installer
├── sync-dotfiles.sh          # Dotfile synchronizer
├── tools.yaml                # Tool definitions (single source of truth)
├── dotfiles/                 # Dotfiles to sync
│   └── git/.gitconfig
└── scripts/
    ├── logging.sh            # ANSI colors, ensure_not_root
    ├── distro.sh             # Distro detection + system update
    ├── ensure-deps.sh        # Dependency auto-install helpers
    ├── install-pacman.sh     # Arch official repos
    ├── install-pikman.sh     # pikaOS unified manager
    ├── install-apt.sh        # Debian/Ubuntu
    ├── install-dnf.sh        # Fedora
    ├── install-aur.sh        # AUR via paru
    ├── install-flatpak.sh    # Flathub
    └── install-script.sh     # Remote scripts + direct URL downloads
```

## Dependencies

- `yq` — required to read `tools.yaml`. `guide.sh` checks for it and shows the install command if missing.
- `paru` — required on Arch for AUR packages. `guide.sh` checks for it and shows build commands if missing.
- `flatpak` — required for Flatpak packages. `guide.sh` checks for it and shows install commands if missing.
- `curl` — for downloads
- `sudo` — for package installation

## Why Not Ansible / Nix / Home Manager?

Because you shouldn't need a configuration management tool to install 20 apps. This is a shell script that reads a YAML file and runs your package manager. You can read it, understand it, and modify it in one sitting.
