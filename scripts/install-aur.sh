#!/bin/bash

install_with_aur() {
    local packages="$1"

    [[ -z "$packages" || "$packages" == "null" ]] && return 1

    if ! command -v paru &>/dev/null; then
        echo "⚠️  paru not found, skipping AUR"
        return 1
    fi

    echo "📦 Installing (AUR): $packages"
    # shellcheck disable=SC2086
    paru -S --needed $packages
}
