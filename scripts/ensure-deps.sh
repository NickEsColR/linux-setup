#!/bin/bash
# =============================================================================
# ensure-deps.sh — Ensure required dependencies are available
# =============================================================================
# Provides functions to guarantee yq, paru, flatpak and flathub are installed
# before the main setup flow begins. Each function is idempotent — safe to call
# multiple times.
# =============================================================================

# ── yq (YAML processor) ─────────────────────────────────────────────────────
# Downloads the latest binary from GitHub if not already on PATH.
ensure_yq() {
    if command -v yq &>/dev/null; then return 0; fi

    echo "📦 Installing yq..."
    local arch
    arch=$(uname -m)
    case "$arch" in
        x86_64)  arch="amd64" ;;
        aarch64) arch="arm64" ;;
        *) echo "❌ Unsupported architecture: $arch"; exit 1 ;;
    esac

    local tmpyq
    tmpyq=$(mktemp)
    trap 'rm -f "$tmpyq"' EXIT

    if curl -fsSL "https://github.com/mikefarah/yq/releases/latest/download/yq_linux_${arch}" -o "$tmpyq"; then
        sudo cp "$tmpyq" /usr/local/bin/yq
        sudo chmod +x /usr/local/bin/yq
        echo "✅ yq installed"
    else
        echo "❌ Failed to install yq"
        exit 1
    fi
}

# ── paru (AUR helper) ────────────────────────────────────────────────────────
# Builds and installs paru from the AUR. Arch-based distros only; no-op on
# other distributions.
ensure_paru() {
    if [[ "$DISTRO" != "arch" ]]; then return 0; fi
    if command -v paru &>/dev/null; then return 0; fi

    echo "📦 Installing paru (AUR helper)..."
    sudo pacman -S --needed base-devel git
    local tmpdir
    tmpdir=$(mktemp -d)
    trap 'rm -rf "$tmpdir"' EXIT
    git clone https://aur.archlinux.org/paru.git "$tmpdir/paru"
    (cd "$tmpdir/paru" && makepkg -si)
    echo "✅ paru installed"
}

# ── flatpak ──────────────────────────────────────────────────────────────────
# Installs flatpak using the distro's package manager. Fails if distro is
# unsupported.
ensure_flatpak() {
    if command -v flatpak &>/dev/null; then return 0; fi

    echo "📦 Installing flatpak..."
    if [[ "$DISTRO" == "arch" ]]; then
        sudo pacman -S --needed flatpak
    elif [[ "$DISTRO" == "fedora" ]]; then
        sudo dnf install -y flatpak
    elif [[ "$DISTRO" == "pikaos" ]]; then
        sudo pikman install flatpak || sudo apt install -y flatpak
    else
        sudo apt install -y flatpak
    fi
    echo "✅ flatpak installed"
}

# ── flathub remote ───────────────────────────────────────────────────────────
# Registers the Flathub remote if not already present. Requires flatpak.
ensure_flathub() {
    if ! ensure_flatpak; then return 1; fi

    if flatpak remotes | grep -qi "flathub"; then return 0; fi

    echo "📦 Adding Flathub remote..."
    if flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo; then
        echo "✅ Flathub remote added"
    else
        echo "❌ Failed to add Flathub remote"
        return 1
    fi
}
