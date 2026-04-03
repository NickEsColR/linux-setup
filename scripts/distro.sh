#!/bin/bash

detect_distro() {
    if [[ ! -f /etc/os-release ]]; then
        echo "unknown"
        return
    fi

    local id
    # shellcheck disable=SC1091
    id=$(. /etc/os-release && echo "$ID")
    case "$id" in
        arch|cachyos|manjaro|endeavouros) echo "arch" ;;
        pikaos)                           echo "pikaos" ;;
        debian)                           echo "debian" ;;
        ubuntu|pop|zorin|linuxmint)       echo "debian" ;;
        fedora|nobara)                    echo "fedora" ;;
        *)                                echo "unknown" ;;
    esac
}

DISTRO=$(detect_distro)

if [[ "$DISTRO" == "unknown" ]]; then
    echo "ERROR: Unsupported distribution." >&2
    echo "Supported: Arch, Debian, Ubuntu, pikaOS, Fedora (and derivatives)" >&2
    exit 1
fi

distro_update() {
    case "$DISTRO" in
        arch)
            echo "📦 Updating system (pacman -Syu)"
            sudo pacman -Syu
            ;;
        pikaos)
            echo "📦 Updating system (pikman)"
            sudo pikman update && sudo pikman upgrade
            ;;
        debian)
            echo "📦 Updating system (apt)"
            sudo apt update && sudo apt upgrade
            ;;
        fedora)
            echo "📦 Updating system (dnf)"
            sudo dnf upgrade --refresh
            ;;
    esac
}
