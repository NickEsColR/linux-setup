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

# 2. Install everything from tools.yaml
./setup.sh

# 3. Or preview what would happen
./setup.sh --dry-run

# 4. Sync dotfiles
./sync-dotfiles.sh
```

## How It Works

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
1. Official repo (pacman / pikman / apt / dnf)  ← most trusted
2. AUR (Arch only, via paru)                    ← if official repo failed
3. Flatpak                                      ← universal fallback
4. Direct URL (.deb / .rpm)                     ← with MIME type detection
5. Official install script                      ← highest risk, reviewed last
```

The first successful source wins. If a tool isn't available for your distro, it's skipped with a warning.

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
├── setup.sh                  # Main installer
├── sync-dotfiles.sh          # Dotfile synchronizer
├── tools.yaml                # Tool definitions (single source of truth)
├── dotfiles/                 # Dotfiles to sync
│   └── git/.gitconfig
└── scripts/
    ├── logging.sh            # ANSI colors, ensure_not_root
    ├── distro.sh             # Distro detection + system update
    ├── install-pacman.sh     # Arch official repos
    ├── install-pikman.sh     # pikaOS unified manager
    ├── install-apt.sh        # Debian/Ubuntu
    ├── install-dnf.sh        # Fedora
    ├── install-aur.sh        # AUR via paru
    ├── install-flatpak.sh    # Flathub
    └── install-script.sh     # Remote scripts + direct URL downloads
```

## Dependencies

- `yq` — auto-installed if missing (downloaded from GitHub)
- `paru` — auto-installed if on Arch and missing (built from AUR)
- `curl` — for downloads
- `sudo` — for package installation

## Why Not Ansible / Nix / Home Manager?

Because you shouldn't need a configuration management tool to install 20 apps. This is a shell script that reads a YAML file and runs your package manager. You can read it, understand it, and modify it in one sitting.
