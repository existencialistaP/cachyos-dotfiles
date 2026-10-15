#!/usr/bin/env bash
# Leitura do registro de perfis. Fonte unica: profiles/profiles.toml.
#
# Nada aqui tem efeito colateral: apenas resolve perfis -> manifests.
# A validacao vive em `profile_exists` e no parser de argumentos do
# bootstrap.sh (que retorna 2 em perfil invalido).

PROFILES_TOML="${PROFILES_TOML:-$REPO_ROOT/profiles/profiles.toml}"

# Le um array TOML (possivelmente multi-linha) e imprime os itens separados por
# espaco. `section` vazio = chave de primeiro nivel; caso contrario, o nome da
# secao (ex.: profiles.core).
toml_array_field() { # secao chave arquivo
    awk -v section="$1" -v key="$2" '
        function flush() {
            n = split(out, a, " ")
            for (i = 1; i <= n; i++) if (a[i] != "") print a[i]
        }
        /^[[:space:]]*\[/ {
            if (inarr) { flush(); exit }
            cur = $0
            sub(/^[[:space:]]*\[/, "", cur)
            sub(/\][[:space:]]*$/, "", cur)
            next
        }
        {
            if (inarr) {
                line = $0
                if (line ~ /\]/) { sub(/\].*$/, "", line); closed = 1 }
                gsub(/[[:space:]"]/, "", line)
                gsub(/,/, " ", line)
                if (length(line) > 0) out = out line " "
                if (closed) { flush(); exit }
                next
            }
            if (cur != section) next
            if ($0 ~ "^[[:space:]]*" key "[[:space:]]*=") {
                line = $0
                sub(/^[^=]*=[[:space:]]*\[/, "", line)
                inarr = 1
                if (line ~ /\]/) { sub(/\].*$/, "", line); closed = 1 }
                gsub(/[[:space:]"]/, "", line)
                gsub(/,/, " ", line)
                if (length(line) > 0) out = out line " "
                if (closed) { flush(); exit }
            }
        }
        END { if (inarr && !closed) flush() }' "$3"
}

profiles_order() { toml_array_field "" order "$PROFILES_TOML"; }
profiles_default() { toml_array_field "" default_profiles "$PROFILES_TOML"; }
profiles_optional() { toml_array_field "" optional_profiles "$PROFILES_TOML"; }

profile_field() { # nome campo
    toml_array_field "profiles.$1" "$2" "$PROFILES_TOML"
}

profile_exists() {
    grep -q "^\[profiles\.$1\]$" "$PROFILES_TOML"
}

# Caminho do manifest de um tipo dentro de um perfil.
manifest_path() { # tipo nome
    case "$1" in
        official) printf '%s/packages/official/%s.txt\n' "$REPO_ROOT" "$2" ;;
        aur) printf '%s/packages/aur/%s.txt\n' "$REPO_ROOT" "$2" ;;
        flatpak) printf '%s/packages/flatpak/%s.txt\n' "$REPO_ROOT" "$2" ;;
        user) printf '%s/packages/%s.txt\n' "$REPO_ROOT" "$2" ;;
        manual) printf '%s/packages/manual/%s.toml\n' "$REPO_ROOT" "$2" ;;
        *) return 2 ;;
    esac
}

# resolve_profiles NOME... -> manifests em ordem estavel, sem repeticao.
# Ordem: ordem canonica dos perfis; dentro do perfil, official, aur, flatpak,
# user, manual. Um manifest compartilhado por dois perfis sai uma vez so.
resolve_profiles() {
    {
        local profile kind name want
        for profile in $(profiles_order); do
            local requested=false
            for want in "$@"; do
                [ "$want" = "$profile" ] && requested=true
            done
            $requested || continue
            for kind in official aur flatpak user manual; do
                for name in $(profile_field "$profile" "$kind"); do
                    manifest_path "$kind" "$name"
                done
            done
        done
    } | awk '!seen[$0]++'
}

# Filtra a lista de manifests (vinda de resolve_profiles) por tipo.
resolve_by_kind() { # tipo manifest...
    local kind="$1"
    shift
    local f
    for f in "$@"; do
        [ -n "$f" ] || continue
        case "$kind" in
            official) case "$f" in */official/*) printf '%s\n' "$f" ;; esac ;;
            aur) case "$f" in */aur/*) printf '%s\n' "$f" ;; esac ;;
            flatpak) case "$f" in */flatpak/*) printf '%s\n' "$f" ;; esac ;;
            manual) case "$f" in */manual/*) printf '%s\n' "$f" ;; esac ;;
            user)
                case "$f" in
                    */manual/* | */official/* | */aur/* | */flatpak/*) ;;
                    *) printf '%s\n' "$f" ;;
                esac
                ;;
            *) return 2 ;;
        esac
    done
}
