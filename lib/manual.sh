#!/usr/bin/env bash
# Instalacoes manuais: repositorios git com revisao fixa e AppImages fornecidos
# pelo usuario. Nada aqui baixa binario sem checksum e nada le credenciais.

# ~/algo -> $HOME/algo (sem hardcode de usuario).
expand_home() { printf '%s\n' "${1/#\~/$HOME}"; }

# Le um `chave = "valor"` do TOML simples dos manifests manuais.
manual_get() { # arquivo chave
    awk -v key="$2" '
        $0 ~ "^[[:space:]]*" key "[[:space:]]*=" {
            line = $0
            sub(/^[^=]*=[[:space:]]*/, "", line)
            sub(/[[:space:]]*#.*$/, "", line)
            gsub(/^"|"[[:space:]]*$/, "", line)
            print line
            exit
        }' "$1"
}

git_head_matches() { # destino revisao
    git -C "$1" rev-parse HEAD 2>/dev/null | grep -q "^$2"
}

# Uma maquina que ja tem o Flutter em outro caminho (paths.flutter do chezmoi)
# nao precisa de uma segunda copia: se a revisao alvo ja esta la, nada a fazer.
flutter_present_at_configured_path() { # manifest do flutter
    local rev cfg
    rev=$(manual_get "$1" revision)
    cfg=$(chezmoi execute-template '{{ .paths.flutter }}' 2>/dev/null || true)
    [ -n "$cfg" ] && [ -d "$cfg/.git" ] || return 1
    git_head_matches "$cfg" "$rev"
}

install_git_pinned() { # nome repositorio revisao destino
    local name="$1" repo="$2" rev="$3" dest
    dest=$(expand_home "$4")

    if [ -d "$dest/.git" ] && git_head_matches "$dest" "$rev"; then
        info "$name: ja esta na revisao $rev"
        return 0
    fi

    if [ "$DRY_RUN" = "1" ]; then
        if [ -d "$dest/.git" ]; then
            printf '+ git -C %s fetch --tags --force origin\n' "$dest"
            printf '+ git -C %s checkout --detach %s\n' "$dest" "$rev"
        else
            printf '+ git clone --filter=blob:none --no-checkout %s %s\n' "$repo" "$dest"
            printf '+ git -C %s checkout --detach %s\n' "$dest" "$rev"
        fi
        return 0
    fi

    if [ -d "$dest/.git" ]; then
        run git -C "$dest" fetch --tags --force origin
    else
        mkdir -p "$(dirname "$dest")"
        run git clone --filter=blob:none --no-checkout "$repo" "$dest"
    fi
    run git -C "$dest" checkout --detach "$rev"
}

install_artifact() { # nome versao sha256 destino
    local name="$1" version="$2" want_sha="$3" dest
    dest=$(expand_home "$4")
    local src="${ARTIFACT_PATHS[$name]:-}"

    if [ -z "$src" ]; then
        die "artefato $name $version exige --artifact $name=/caminho/do/arquivo"
    fi
    [ -f "$src" ] || die "artefato $name nao encontrado em $src"

    local got_sha
    got_sha=$(sha256sum "$src" | awk '{print $1}')
    if [ "$got_sha" != "$want_sha" ]; then
        die "$name: sha256 nao confere (esperado $want_sha, obtido $got_sha)"
    fi

    if [ -f "$dest" ] && [ "$(sha256sum "$dest" | awk '{print $1}')" = "$want_sha" ]; then
        info "$name: ja instalado com o sha256 correto"
        return 0
    fi

    run install -Dm755 "$src" "$dest"
}

ensure_omf_theme() { # destino do omf
    local omf="$1" theme
    theme=$(cat "$HOME/.config/omf/theme" 2>/dev/null || true)
    [ -n "$theme" ] || { info "omf: nenhum tema registrado em ~/.config/omf/theme"; return 0; }
    if [ -d "$omf/themes/$theme" ]; then
        info "omf: tema $theme ja presente"
        return 0
    fi
    run fish -c "source \"$omf/init.fish\"; omf install $theme"
}

install_manual() { # nome (packages/manual/<nome>.toml)
    local name="$1" file="$REPO_ROOT/packages/manual/$1.toml"
    [ -f "$file" ] || die "manifest manual ausente: $file"

    local source
    source=$(manual_get "$file" source)
    case "$source" in
        git)
            install_git_pinned "$name" \
                "$(manual_get "$file" repository)" \
                "$(manual_get "$file" revision)" \
                "$(manual_get "$file" dest)"
            if [ "$name" = "omf" ]; then
                ensure_omf_theme "$(expand_home "$(manual_get "$file" dest)")"
            fi
            ;;
        manual)
            install_artifact "$name" \
                "$(manual_get "$file" version)" \
                "$(manual_get "$file" sha256)" \
                "$(manual_get "$file" dest)"
            ;;
        *)
            die "fonte manual desconhecida para $name: '$source'"
            ;;
    esac
}
