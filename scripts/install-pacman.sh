#!/bin/bash

install_with_pacman() {
    local packages="$1"

    [[ -z "$packages" || "$packages" == "null" ]] && return 1

    echo "📦 Installing: $packages"
    sudo pacman -S --needed $packages
}
