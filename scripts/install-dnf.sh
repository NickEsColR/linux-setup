#!/bin/bash

install_with_dnf() {
    local packages="$1"

    [[ -z "$packages" || "$packages" == "null" ]] && return 1

    echo "📦 Installing: $packages"
    sudo dnf install $packages
}
