#!/bin/bash
# =============================================================================
# Sincronización de dotfiles (sin instalar herramientas)
# =============================================================================
# Uso: bash scripts/sync-dotfiles.sh
#
# Para agregar un dotfile nuevo:
#   1. Agregá el archivo en dotfiles/ (ej: dotfiles/nvim/init.vim)
#   2. Agregá una línea a DOTFILES=(...) abajo
#   Listo. El script se encarga del resto.
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(dirname "$SCRIPT_DIR")/dotfiles"
BACKUP_DIR="$HOME/.dotfiles-backups"

source "$SCRIPT_DIR/lib/logging.sh"

ensure_not_root

# ─── Lista declarativa de dotfiles ──────────────────────────────────────────
# Formato: "ruta_origen:ruta_destino"
#   - ruta_origen: relativa a dotfiles/
#   - ruta_destino: absoluta (usemos $HOME)
#
# Para agregar uno nuevo, simplemente agregá una línea.
# No hace falta tocar la lógica del script.
# ─────────────────────────────────────────────────────────────────────────────

DOTFILES=(
    "git/.gitconfig:$HOME/.gitconfig"
)

# ─── Funciones ──────────────────────────────────────────────────────────────

backup_if_exists() {
    local dest="$1"

    if [[ ! -f "$dest" ]]; then
        return 1
    fi

    mkdir -p "$BACKUP_DIR"

    local filename
    filename="$(basename "$dest")"
    local backup_name="${filename}.bak.$(date +%Y%m%dT%H%M%S)"
    local backup_path="$BACKUP_DIR/$backup_name"

    cp "$dest" "$backup_path"
    log_warn "Backup creado: $dest → $backup_path"
    return 0
}

files_are_equal() {
    cmp -s "$1" "$2"
}

sync_dotfile() {
    local entry="$1"
    local src="${entry%%:*}"
    local dest="${entry##*:}"

    local src_path="$DOTFILES_DIR/$src"

    if [[ ! -f "$src_path" ]]; then
        log_error "Origen no encontrado: $src_path"
        return 1
    fi

    # ¿Destino existe y es idéntico? Saltar.
    if [[ -f "$dest" ]] && files_are_equal "$src_path" "$dest"; then
        log_info "$src — sin cambios, omitido"
        return 2  # 2 = skipped
    fi

    # Crear directorio destino si no existe
    local dest_dir
    dest_dir="$(dirname "$dest")"
    mkdir -p "$dest_dir"

    # Backup si existe y es diferente
    backup_if_exists "$dest"

    # Copiar
    cp "$src_path" "$dest"
    log_step "$src → $dest"
    return 0
}

# ─── Ejecución ──────────────────────────────────────────────────────────────

log_section "SINCRONIZANDO DOTFILES"
log_info "Usuario: $USER"
log_info "Origen:  $DOTFILES_DIR"
log_info "Destino: $HOME"
echo ""

if [[ ! -d "$DOTFILES_DIR" ]]; then
    log_error "No existe el directorio de dotfiles: $DOTFILES_DIR"
    exit 1
fi

synced=0
skipped=0
failed=0

for entry in "${DOTFILES[@]}"; do
    rc=0
    sync_dotfile "$entry" || rc=$?
    case $rc in
        0) ((synced++)) ;;
        2) ((skipped++)) ;;
        *) ((failed++)) ;;
    esac
done

# ─── Resumen ────────────────────────────────────────────────────────────────

log_section "RESUMEN"
echo -e "  ${GREEN}Sincronizados: $synced${NC}"
if [[ $skipped -gt 0 ]]; then
    echo -e "  ${BLUE}Omitidos:      $skipped${NC}"
fi
if [[ $failed -gt 0 ]]; then
    echo -e "  ${RED}Fallidos:      $failed${NC}"
fi
echo -e "  ${BLUE}Backups en:    $BACKUP_DIR${NC}"
echo ""
