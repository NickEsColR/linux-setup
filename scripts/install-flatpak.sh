#!/bin/bash

install_with_flatpak() {
    local app_ids="$1"

    [[ -z "$app_ids" || "$app_ids" == "null" ]] && return 1

    echo "📦 Installing (Flatpak): $app_ids"
    # shellcheck disable=SC2086
    flatpak install -y flathub $app_ids
}
