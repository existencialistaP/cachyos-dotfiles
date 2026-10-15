#!/usr/bin/env bash
# Instalacao de pacotes a partir dos manifests. Cada funcao de efeito respeita
# DRY_RUN (imprime o comando em vez de executar). Nenhuma funcao aqui le
# credenciais nem toca em arquivos do usuario.

# Uma entrada por linha, ignorando comentarios e linhas vazias.
manifest_entries() { # arquivo...
    for f in "$@"; do
        [ -f "$f" ] || continue
        sed -e 's/[[:space:]]*#.*$//' -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' "$f" | grep -v '^$' || true
    done
}

# Uniao preservando a ordem de aparicao (dedup estavel).
uniq_entries() { awk '!seen[$0]++'; }

# Todos os nomes de pacote dos manifests dados (sem versao/pin).
package_names() { manifest_entries "$@" | uniq_entries; }

install_official() { # manifest...
    local names list
    names=$(package_names "$@")
    [ -n "$names" ] || { info "oficiais: nada a fazer"; return 0; }
    list=$(printf '%s\n' "$names" | tr '\n' ' ')
    info "pacman -S --needed: $list"
    # shellcheck disable=SC2086 # expansao proposital: um argumento por pacote
    run sudo pacman -S --needed -- $names
}

install_aur() { # manifest...
    local names list
    names=$(package_names "$@")
    [ -n "$names" ] || { info "AUR: nada a fazer"; return 0; }
    list=$(printf '%s\n' "$names" | tr '\n' ' ')
    info "paru -S --needed: $list"
    # shellcheck disable=SC2086 # expansao proposital: um argumento por pacote
    run paru -S --needed -- $names
}

install_flatpak() { # manifest...
    local names
    names=$(package_names "$@")
    [ -n "$names" ] || { info "flatpak: nada a fazer"; return 0; }
    run flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
    # shellcheck disable=SC2086
    run flatpak install --or-update flathub $names
}

installed_pipx() { # nome
    pipx list --json 2>/dev/null | jq -r --arg n "$1" '
        [.venvs[]?.metadata.main_package | select(.package_name == $n) | .package_version] | first // empty' || true
}

installed_uv() { # nome
    uv tool list 2>/dev/null | awk -v n="$1" '$1 == n { sub(/^v/, "", $2); print $2; exit }' || true
}

installed_npm() { # nome
    npm ls -g --depth=0 --json 2>/dev/null | jq -r --arg n "$1" '.dependencies[$n].version // empty' || true
}

installed_bun() { # nome
    local pkg="${BUN_INSTALL:-$HOME/.bun}/install/global/node_modules/$1/package.json"
    [ -f "$pkg" ] || return 0
    jq -r '.version // empty' "$pkg" || true
}

install_pipx() { # manifest...
    local spec name want cur
    while IFS= read -r spec; do
        [ -n "$spec" ] || continue
        name=${spec%%==*}
        want=${spec##*==}
        cur=$(installed_pipx "$name")
        if [ "$cur" = "$want" ]; then
            info "pipx: $name $want ja instalado"
            continue
        fi
        run pipx install --force "$spec"
    done < <(manifest_entries "$@")
}

install_uv_tools() { # manifest...
    local spec name want cur
    while IFS= read -r spec; do
        [ -n "$spec" ] || continue
        name=${spec%%==*}
        want=${spec##*==}
        cur=$(installed_uv "$name")
        if [ "$cur" = "$want" ]; then
            info "uv: $name $want ja instalado"
            continue
        fi
        run uv tool install --force "$spec"
    done < <(manifest_entries "$@")
}

install_bun_global() { # manifest...
    local spec name want cur
    while IFS= read -r spec; do
        [ -n "$spec" ] || continue
        want=${spec##*@}
        name=${spec%@*}
        cur=$(installed_bun "$name")
        if [ "$cur" = "$want" ]; then
            info "bun: $name $want ja instalado"
            continue
        fi
        run bun add -g "$spec"
    done < <(manifest_entries "$@")
}

install_npm_global() { # manifest...
    local spec name want cur
    while IFS= read -r spec; do
        [ -n "$spec" ] || continue
        want=${spec##*@}
        name=${spec%@*}
        cur=$(installed_npm "$name")
        if [ "$cur" = "$want" ]; then
            info "npm: $name $want ja instalado"
            continue
        fi
        run npm install -g "$spec"
    done < <(manifest_entries "$@")
}

# Despacha pelos manifests de usuario: pipx.txt, uv-tools.txt, bun-global.txt,
# npm-global.txt.
install_user_tools() { # manifest de usuario...
    local f base
    for f in "$@"; do
        [ -f "$f" ] || continue
        base=$(basename "$f" .txt)
        case "$base" in
            pipx)       install_pipx "$f" ;;
            uv-tools)   install_uv_tools "$f" ;;
            bun-global) install_bun_global "$f" ;;
            npm-global) install_npm_global "$f" ;;
            *) warn "manifest de usuario sem instalador conhecido: $f" ;;
        esac
    done
}
