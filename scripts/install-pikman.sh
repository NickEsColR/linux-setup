#!/bin/bash

install_with_pikman() {
    local packages="$1"

    [[ -z "$packages" || "$packages" == "null" ]] && return 1

    echo "📦 Installing: $packages"
    sudo pikman install $packages
}
