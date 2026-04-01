#!/bin/bash
# =============================================================================
# Lógica compartida de instalación (Arch + Debian)
# =============================================================================
# source este archivo DESPUÉS de common.sh
# =============================================================================

# ─── Flatpak ────────────────────────────────────────────────────────────────

FLATPAK_APPS=(
    com.discordapp.Discord
    app.ytmdesktop.ytmdesktop
    org.onlyoffice.desktopeditors
    com.heroicgameslauncher.hgl
)

setup_flatpak() {
    log_section "Flatpak"

    if ! flatpak remotes | grep -q flathub; then
        flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
        log_step "Repositorio Flathub agregado"
    fi

    for app in "${FLATPAK_APPS[@]}"; do
        if ! flatpak list | grep -q "$app"; then
            flatpak install -y flathub "$app"
            log_step "Flatpak instalado: $app"
        else
            log_step "Flatpak ya existe: $app"
        fi
    done
}

# ─── Docker ─────────────────────────────────────────────────────────────────

setup_docker() {
    log_section "Docker"

    if groups "$USER" | grep -q "\bdocker\b"; then
        log_step "Usuario ya está en grupo docker"
    else
        sudo usermod -aG docker "$USER"
        log_step "Usuario agregado al grupo docker (requiere logout)"
    fi

    sudo systemctl enable --now docker
    log_step "Docker habilitado"
}

# ─── SSH Key ────────────────────────────────────────────────────────────────

setup_ssh_key() {
    log_section "SSH Key"

    if [[ ! -f "$HOME/.ssh/id_ed25519" ]]; then
        log_info "Generando SSH key..."
        ssh-keygen -t ed25519 -C "$USER@$(hostname)" -f "$HOME/.ssh/id_ed25519" -N ""
        log_step "SSH key generada"
        log_warn "Tu clave pública (copia esto a GitHub → https://github.com/settings/ssh/new):"
        echo ""
        echo -e "  ${GREEN}$(cat "$HOME/.ssh/id_ed25519.pub")${NC}"
        echo ""
    else
        log_step "SSH key ya existe"
    fi
}

# ─── Gentle AI ──────────────────────────────────────────────────────────────

install_gentle_ai() {
    log_section "Gentle AI"
    log_warn "Se instala via curl | bash (única opción disponible)"
    read -rp "¿Instalar Gentle AI? (s/N): " install_gentle
    if [[ "$install_gentle" =~ ^[sS]$ ]]; then
        curl -fsSL https://raw.githubusercontent.com/Gentleman-Programming/gentle-ai/main/scripts/install.sh | bash
        log_step "Gentle AI instalado"
    else
        log_info "Gentle AI omitido"
    fi
}

# ─── Ollama ─────────────────────────────────────────────────────────────────

setup_ollama() {
    log_section "Ollama"

    if command -v ollama &> /dev/null; then
        log_step "Ollama ya está instalado"
    else
        log_info "Instalando Ollama via script oficial..."
        curl -fsSL https://ollama.com/install.sh | sh
        log_step "Ollama instalado"
    fi

    if systemctl is-enabled ollama &> /dev/null 2>&1; then
        log_step "Servicio Ollama ya está habilitado"
    else
        sudo systemctl enable --now ollama
        log_step "Servicio Ollama habilitado"
    fi
}

# ─── Herramientas manuales ──────────────────────────────────────────────────

log_manual() {
    local name="$1"
    local url="$2"
    local note="${3:-}"
    echo -e "  ${YELLOW}▸ $name${NC}"
    echo -e "    $url"
    if [[ -n "$note" ]]; then
        echo -e "    ${BLUE}→ $note${NC}"
    fi
}

show_manual_steps() {
    log_section "HERRAMIENTAS MANUALES (instalar a mano)"

    echo ""
    echo -e "  Las siguientes herramientas no se pueden instalar automáticamente"
    echo -e "  desde el gestor de paquetes. Instalalas manualmente:"
    echo ""

    log_manual "Cursor"        "https://cursor.sh"          "Descargar AppImage o .deb"
    log_manual "OpenCode"      "https://opencode.ai"        "Descargar desde releases"
    log_manual "Warp Terminal" "https://warp.dev"           "Descargar .deb o AppImage"
    log_manual "TablePlus"     "https://tableplus.com"      "Descargar .deb"

    echo ""
}

# ─── Resumen genérico ───────────────────────────────────────────────────────

show_install_summary() {
    local distro="$1"
    local apt_count="${2:-0}"
    local aur_count="${3:-0}"
    local flatpak_count="${#FLATPAK_APPS[@]}"

    log_section "INSTALACIÓN COMPLETADA"

    echo ""
    echo -e "${GREEN}  ╔═══════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}  ║  Herramientas instaladas correctamente.           ║${NC}"
    echo -e "${GREEN}  ╚═══════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "  ${CYAN}Resumen ($distro):${NC}"
    echo -e "  ─ Flatpak apps:  $flatpak_count"
    if [[ "$apt_count" -gt 0 ]]; then
        echo -e "  ─ Paquetes apt:  $apt_count"
    fi
    if [[ "$aur_count" -gt 0 ]]; then
        echo -e "  ─ Paquetes AUR:  $aur_count"
    fi
    echo ""
    echo -e "  ${YELLOW}PRÓXIMOS PASOS:${NC}"
    echo ""
    echo -e "  ${BLUE}1. Sincronizá tus dotfiles:${NC}"
    echo -e "     $ bash scripts/sync-dotfiles.sh"
    echo ""
    echo -e "  ${BLUE}2. Configurá GitHub CLI:${NC}"
    echo -e "     $ gh auth login"
    echo ""
    echo -e "  ${BLUE}3. Agregá tu SSH key a GitHub:${NC}"
    echo -e "     https://github.com/settings/ssh/new"
    echo ""
    echo -e "  ${BLUE}4. Volvé a entrar${NC} para que docker funcione sin sudo"
    echo ""
}
