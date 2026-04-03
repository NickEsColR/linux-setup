#!/bin/bash

install_with_apt() {
    local packages="$1"

    [[ -z "$packages" || "$packages" == "null" ]] && return 1

    echo "📦 Installing: $packages"
    # shellcheck disable=SC2086
    sudo apt install $packages
}
