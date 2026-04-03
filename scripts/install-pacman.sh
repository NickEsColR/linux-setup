#!/bin/bash

install_with_pacman() {
    local packages="$1"

    [[ -z "$packages" || "$packages" == "null" ]] && return 1

    echo "📦 Installing: $packages"
    # shellcheck disable=SC2086
    sudo pacman -S --needed $packages
}
