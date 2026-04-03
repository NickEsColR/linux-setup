#!/bin/bash

install_with_flatpak() {
    local app_id="$1"

    [[ -z "$app_id" || "$app_id" == "null" ]] && return 1

    echo "📦 Installing: $app_id"
    flatpak install flathub "$app_id"
}
