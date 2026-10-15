#!/usr/bin/env bash
# Auditoria e limpeza opcional. Nada aqui roda por conta propria: `--audit`
# apenas escreve um relatorio; `--prune` exige TTY e a palavra REMOVE.
#
# O conjunto protegido cobre kernel, boot, firmware, GPU, rede, sudo e pacman:
# itens que o instalador do CachyOS escolheu e que este repo nunca gerencia.

AUDIT_STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/cachyos-dotfiles"
AUDIT_FILE="$AUDIT_STATE_DIR/audit-unused.txt"

# Nunca aparecem como candidatos, mesmo fora dos manifests.
AUDIT_PROTECTED='^(base|base-devel|cachyos-.*|linux.*|.*-firmware.*|.*-ucode|nvidia.*|vulkan.*|intel.*|mesa.*|limine.*|mkinitcpio.*|gdm|networkmanager|iwd|sudo|pacman)$'

# Escreve a lista de candidatos (instalados explicitamente e ausentes dos
# manifests selecionados, menos o conjunto protegido).
audit_write() { # manifest...
    local -a files=() f
    while IFS= read -r f; do files+=("$f"); done < <(resolve_by_kind official "$@")
    while IFS= read -r f; do files+=("$f"); done < <(resolve_by_kind aur "$@")

    mkdir -p "$AUDIT_STATE_DIR"
    local kept_tmp installed_tmp
    kept_tmp=$(mktemp)
    installed_tmp=$(mktemp)

    if [ "${#files[@]}" -gt 0 ]; then
        package_names "${files[@]}" | sort -u > "$kept_tmp"
    else
        : > "$kept_tmp"
    fi

    { pacman -Qqen 2>/dev/null || true; pacman -Qqem 2>/dev/null || true; } | sort -u > "$installed_tmp"

    comm -23 "$installed_tmp" "$kept_tmp" | grep -Ev "$AUDIT_PROTECTED" > "$AUDIT_FILE" || true
    rm -f "$kept_tmp" "$installed_tmp"
    info "candidatos em $AUDIT_FILE ($(wc -l < "$AUDIT_FILE") pacotes)"
}

audit_report() { # manifest...
    audit_write "$@"
    if [ -s "$AUDIT_FILE" ]; then
        cat "$AUDIT_FILE"
    else
        info "nada fora dos perfis selecionados"
    fi
}

prune_run() { # manifest...
    # Recusa antes de qualquer leitura/escrita: prune nunca roda sem terminal.
    if [ ! -t 0 ] && [ ! -t 2 ]; then
        die "prune recusado: sem terminal interativo (rode num TTY)"
    fi

    audit_write "$@"
    if [ ! -s "$AUDIT_FILE" ]; then
        info "lista vazia: nada a remover, pacman nao sera chamado"
        return 0
    fi

    printf 'Candidatos a remocao (%s):\n' "$AUDIT_FILE" >&2
    cat "$AUDIT_FILE" >&2
    printf 'Digite REMOVE para confirmar a remocao: ' >&2

    local answer=""
    if [ -t 0 ]; then
        read -r answer
    else
        read -r answer < /dev/tty || answer=""
    fi

    if [ "$answer" != "REMOVE" ]; then
        warn "prune cancelado: palavra de confirmacao ausente"
        return 1
    fi

    local -a pkgs=()
    while IFS= read -r pkg; do [ -n "$pkg" ] && pkgs+=("$pkg"); done < "$AUDIT_FILE"
    [ "${#pkgs[@]}" -gt 0 ] || { info "lista vazia: nada a remover"; return 0; }
    run sudo pacman -Rns -- "${pkgs[@]}"
}
