#!/bin/bash

install_with_apt() {
    local packages="$1"

    [[ -z "$packages" || "$packages" == "null" ]] && return 1

    echo "📦 Installing: $packages"
    sudo apt install $packages
}
