#!/bin/bash

install_with_script() {
    local url="$1"

    [[ -z "$url" || "$url" == "null" ]] && return 1

    echo "📦 Installing via script: $url"
    local tmpscript
    tmpscript=$(mktemp)
    trap 'rm -f "$tmpscript"' EXIT

    if ! curl -fsSL "$url" -o "$tmpscript"; then
        echo "❌ Download failed: $url"
        return 1
    fi

    chmod +x "$tmpscript"
    "$tmpscript"
}

install_from_url() {
    local url="$1"
    [[ -z "$url" || "$url" == "null" ]] && return 1

    echo "📦 Downloading from: $url"
    local tmpfile
    tmpfile=$(mktemp --suffix=".tmp")

    # Localized cleanup handler — cleans up on function return, not script exit
    # shellcheck disable=SC2317
    cleanup() { rm -f "$tmpfile"; }
    trap cleanup RETURN

    if ! curl -fsSL "$url" -o "$tmpfile"; then
        echo "❌ Download failed"
        return 1
    fi

    local mime
    mime=$(file --mime-type -b "$tmpfile")
    case "$mime" in
        application/vnd.debian.binary-package*)
            sudo apt-get update # Recommended before resolving dependencies
            sudo dpkg -i "$tmpfile"
            sudo apt-get install -f -y
            ;;
        application/x-rpm*)
            # dnf can install local files while resolving dependencies
            sudo dnf install -y "$tmpfile"
            ;;
        *)
            echo "❌ Unsupported file type: $mime"
            return 1
            ;;
    esac
}
