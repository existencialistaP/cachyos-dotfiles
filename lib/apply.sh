#!/usr/bin/env bash
# Passos que dependem de rede/servicos e vem depois do `chezmoi apply`.
# Nada aqui le ou restaura credenciais: autenticacao continua manual.

# chezmoi diff -> dry-run verbose -> confirmacao literal APPLY -> apply.
apply_chezmoi() {
    info "chezmoi diff"
    chezmoi diff || true

    info "chezmoi apply --dry-run --verbose"
    chezmoi apply --dry-run --verbose

    if [ "$DRY_RUN" = "1" ]; then
        return 0
    fi
    if [ ! -t 0 ]; then
        die "confirmacao interativa necessaria: rode num TTY ou use --dry-run"
    fi
    printf 'Digite APPLY para aplicar as mudancas acima: ' >&2
    local answer=""
    read -r answer
    if [ "$answer" != "APPLY" ]; then
        die "aplicacao cancelada: esperado APPLY"
    fi
    chezmoi apply
}

# ~/.colorscheme e estado mutavel: cria `dark` somente se nao existir.
ensure_colorscheme() {
    local f="$HOME/.colorscheme"
    if [ -e "$f" ]; then
        info ".colorscheme ja existe ($(cat "$f" 2>/dev/null))"
        return 0
    fi
    if [ "$DRY_RUN" = "1" ]; then
        printf '+ printf dark > %s\n' "$f"
        return 0
    fi
    printf 'dark\n' > "$f"
    info ".colorscheme inicializado com dark"
}

# Gera a paleta do pywal a partir do wallpaper inicial.
generate_palette() {
    local img="$HOME/wallpapers/wallpapers/wallhaven-zpx8vj.png"
    if [ ! -f "$img" ]; then
        local cand
        for cand in "$HOME"/wallpapers/wallpapers/*; do
            [ -f "$cand" ] || continue
            img="$cand"
            break
        done
    fi
    if [ ! -f "$img" ]; then
        warn "nenhum wallpaper encontrado: pulando a geracao da paleta"
        return 0
    fi
    run wal -i "$img" -n
}

update_xdg_dirs() {
    run xdg-user-dirs-update
}

# Só troca o shell quando ainda não é o atual.
set_fish_shell() {
    local current
    current=$(getent passwd "$USER" 2>/dev/null | awk -F: '{print $7}')
    if [ "$current" = "/usr/bin/fish" ]; then
        info "shell ja e /usr/bin/fish"
        return 0
    fi
    run chsh -s /usr/bin/fish
}

unit_present() { # unit
    systemctl list-unit-files --no-legend -- "$1" 2>/dev/null | grep -q .
}

# GDM ligado; qualquer sddm/ly presente e desligado (nao removido).
enable_display_manager() {
    run sudo systemctl enable gdm
    local unit
    for unit in sddm.service ly@tty2.service; do
        if unit_present "$unit"; then
            run sudo systemctl disable "$unit"
        fi
    done
}

# Docker + PostgreSQL, apenas quando o perfil dev-containers-db foi escolhido.
setup_containers_db() {
    run sudo systemctl enable --now docker
    if [ ! -f /var/lib/postgres/data/PG_VERSION ]; then
        run sudo -u postgres initdb -D /var/lib/postgres/data
    fi
    run sudo systemctl enable --now postgresql
}

# Clona/atualiza o harness de agentes e roda o install dele.
install_ai_harness() {
    local dest="$HOME/.local/share/ai-agent-config"
    local repo="https://github.com/existencialistaP/ai-agent-config.git"
    if [ -d "$dest/.git" ]; then
        run git -C "$dest" pull --ff-only
    else
        run mkdir -p "$HOME/.local/share"
        run git clone "$repo" "$dest"
    fi
    run "$dest/install.sh"
}

# Checklist de autenticacao: apenas instrucoes, nada e executado nem lido.
print_auth_checklist() {
    cat <<'EOF'

Autenticacao manual (nada disso e feito automaticamente):
  - GitHub:        gh auth login
  - LibreWolf:     pywalfox install   (dentro do navegador)
  - Spotify:       spotatui           (login OAuth na primeira execucao)
  - OpenCode/OMP:  /login dentro de cada harness
  - TablePlus:     abrir o app e autenticar
  - Provider local do OpenCode (Sleev):
        sleev setup --no-open
        # depois do login no navegador:
        sleev gateway bind --host 127.0.0.1 --port 17321 --restart
EOF
}
