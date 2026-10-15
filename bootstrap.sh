#!/usr/bin/env bash
# Bootstrap do CachyOS + Niri a partir deste repositorio.
#
# Uso:
#   ./bootstrap.sh [--all | --profile NAME ...] [--artifact nome=caminho]
#                  [--dry-run] [--audit | --prune]
#
# Sem flags de perfil instala `core`, `desktop-niri`, `shell-editor` e oferece
# um menu numerico com os perfis opcionais. `--audit` e `--prune` usam todos os
# perfis quando nenhum for informado.
#
# Nada aqui edita pacman.conf, mirrors, kernel, bootloader, microcode, firmware
# ou drivers de GPU: isso e do instalador do CachyOS.

set -euo pipefail

REPO_ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd -P)
DRY_RUN="${DRY_RUN:-0}"
OS_RELEASE_FILE="${OS_RELEASE_FILE:-/etc/os-release}"

declare -A ARTIFACT_PATHS=()

info() { printf '[bootstrap] %s\n' "$*"; }
warn() { printf '[bootstrap] aviso: %s\n' "$*" >&2; }
die() { printf '[bootstrap] erro: %s\n' "$*" >&2; exit 1; }
usage_error() { printf '[bootstrap] erro: %s\n' "$*" >&2; usage >&2; exit 2; }

# Efeito unico do programa: imprime em dry-run, executa fora dele.
run() {
    if [ "$DRY_RUN" = "1" ]; then
        printf '+ %s\n' "$*"
    else
        "$@"
    fi
}

usage() {
    cat <<'EOF'
uso: ./bootstrap.sh [--all | --profile NOME ...] [--artifact nome=caminho]
                    [--dry-run] [--audit | --prune]

  --all              seleciona todos os perfis declarados
  --profile NOME...  seleciona perfis especificos (repetivel)
  --artifact n=p     registra um artefato manual (hoje: orca=/caminho/AppImage)
  --dry-run          imprime os comandos sem executar nada
  --audit            escreve ~/.local/state/cachyos-dotfiles/audit-unused.txt
  --prune            remove os candidatos do audit (exige TTY + REMOVE)
EOF
}

# shellcheck source=lib/profiles.sh
. "$REPO_ROOT/lib/profiles.sh"
# shellcheck source=lib/packages.sh
. "$REPO_ROOT/lib/packages.sh"
# shellcheck source=lib/manual.sh
. "$REPO_ROOT/lib/manual.sh"
# shellcheck source=lib/audit.sh
. "$REPO_ROOT/lib/audit.sh"
# shellcheck source=lib/apply.sh
. "$REPO_ROOT/lib/apply.sh"

ALL=0
MODE=install
declare -a REQUESTED=()

while [ "$#" -gt 0 ]; do
    case "$1" in
        --all)
            ALL=1
            shift
            ;;
        --profile)
            shift
            [ "$#" -gt 0 ] || usage_error "--profile exige ao menos um nome"
            while [ "$#" -gt 0 ] && [ "${1#--}" = "$1" ]; do
                REQUESTED+=("$1")
                shift
            done
            ;;
        --artifact)
            shift
            [ "$#" -gt 0 ] || usage_error "--artifact exige nome=caminho"
            spec="$1"
            if [ "${spec%%=*}" = "$spec" ]; then
                usage_error "--artifact exige nome=caminho (ex.: orca=/tmp/orca.AppImage)"
            fi
            ARTIFACT_PATHS["${spec%%=*}"]="${spec#*=}"
            shift
            ;;
        --dry-run)
            DRY_RUN=1
            shift
            ;;
        --audit)
            [ "$MODE" = "install" ] || usage_error "--audit e --prune sao mutuamente exclusivos"
            MODE=audit
            shift
            ;;
        --prune)
            [ "$MODE" = "install" ] || usage_error "--audit e --prune sao mutuamente exclusivos"
            MODE=prune
            shift
            ;;
        -h | --help)
            usage
            exit 0
            ;;
        *)
            usage_error "opcao desconhecida: $1"
            ;;
    esac
done

# Valida cada perfil pedido antes de qualquer efeito.
for name in "${REQUESTED[@]:-}"; do
    [ -n "$name" ] || continue
    profile_exists "$name" || usage_error "perfil desconhecido: $name"
done

# Ordena a selecao na ordem canonica do registro.
canonical_profiles() {
    local profile
    for profile in $(profiles_order); do
        local want
        for want in "$@"; do
            if [ "$want" = "$profile" ]; then
                printf '%s\n' "$profile"
                break
            fi
        done
    done | awk '!seen[$0]++'
}

menu_optional() {
    local -a opts=()
    local p
    while IFS= read -r p; do
        [ -n "$p" ] && opts+=("$p")
    done < <(profiles_optional)

    if [ "${#opts[@]}" -eq 0 ]; then
        return 0
    fi
    if [ ! -t 0 ]; then
        warn "sem TTY: apenas os perfis padrao foram selecionados"
        return 0
    fi

    printf 'Perfis opcionais:\n'
    local i=1
    for p in "${opts[@]}"; do
        printf '  %d) %s\n' "$i" "$p"
        i=$((i + 1))
    done
    printf 'Escolha numeros separados por espaco (ENTER = nenhum): '
    local answer=""
    read -r answer
    local choice
    for choice in $answer; do
        case "$choice" in
            '' | *[!0-9]*) usage_error "selecao invalida: $choice" ;;
        esac
        if [ "$choice" -lt 1 ] || [ "$choice" -gt "${#opts[@]}" ]; then
            usage_error "selecao fora do intervalo: $choice"
        fi
        REQUESTED+=("${opts[$((choice - 1))]}")
    done
}

declare -a SELECTED=()
if [ "$ALL" = "1" ]; then
    while IFS= read -r p; do [ -n "$p" ] && SELECTED+=("$p"); done < <(profiles_order)
elif [ "${#REQUESTED[@]}" -gt 0 ]; then
    while IFS= read -r p; do [ -n "$p" ] && SELECTED+=("$p"); done < <(canonical_profiles "${REQUESTED[@]}")
elif [ "$MODE" = "install" ]; then
    while IFS= read -r p; do [ -n "$p" ] && SELECTED+=("$p"); done < <(profiles_default)
    menu_optional
    if [ "${#REQUESTED[@]}" -gt 0 ]; then
        while IFS= read -r p; do [ -n "$p" ] && SELECTED+=("$p"); done < <(canonical_profiles "${REQUESTED[@]}" "${SELECTED[@]}")
    fi
else
    while IFS= read -r p; do [ -n "$p" ] && SELECTED+=("$p"); done < <(profiles_order)
fi

profile_selected() {
    local want
    for want in "${SELECTED[@]}"; do
        [ "$want" = "$1" ] && return 0
    done
    return 1
}

collect_manifests() { # tipo -> paths (uma linha cada)
    local -a all=()
    local f
    while IFS= read -r f; do [ -n "$f" ] && all+=("$f"); done < <(resolve_profiles "${SELECTED[@]}")
    [ "${#all[@]}" -gt 0 ] || return 0
    resolve_by_kind "$1" "${all[@]}"
}

collect_kind() { # tipo -> popula COLLECTED
    COLLECTED=()
    local f
    while IFS= read -r f; do [ -n "$f" ] && COLLECTED+=("$f"); done < <(collect_manifests "$1")
}
preflight_common() {
    [ "$(id -u)" -ne 0 ] || die "nao rode o bootstrap como root: sudo e usado pontualmente"
    [ -f "$OS_RELEASE_FILE" ] || die "arquivo do SO ausente: $OS_RELEASE_FILE"
    grep -q '^ID=cachyos$' "$OS_RELEASE_FILE" || die "SO diferente de CachyOS (esperado ID=cachyos)"
    [ "$(uname -m)" = "x86_64" ] || die "arquitetura nao suportada: $(uname -m)"
    command -v pacman >/dev/null 2>&1 || die "pacman nao encontrado no PATH"
}

preflight_install() {
    preflight_common
    command -v sudo >/dev/null 2>&1 || die "sudo nao encontrado"
    command -v chezmoi >/dev/null 2>&1 || die "chezmoi nao encontrado (sudo pacman -S --needed chezmoi)"
    chezmoi execute-template '{{ .paths.flutter }}{{ .display.output }}{{ .git.email }}' >/dev/null 2>&1 ||
        die "dados do chezmoi ausentes ou incompletos: rode 'chezmoi init existencialistaP/cachyos-dotfiles' antes do bootstrap"
    if [ "$DRY_RUN" = "1" ]; then
        info "dry-run: checagem de rede ignorada"
        return 0
    fi
    curl -fsSI --max-time 10 https://github.com >/dev/null 2>&1 ||
        die "sem rede: nao foi possivel alcancar github.com"
}

main_install() {
    preflight_install

    info "perfis selecionados: ${SELECTED[*]}"
    if [ "$DRY_RUN" = "1" ]; then
        info "modo dry-run: nenhum pacote ou arquivo sera alterado"
    fi

    collect_kind official
    install_official "${COLLECTED[@]:-}"

    collect_kind aur
    install_aur "${COLLECTED[@]:-}"

    collect_kind flatpak
    install_flatpak "${COLLECTED[@]:-}"

    info "aplicando os arquivos de usuario com chezmoi"
    apply_chezmoi

    collect_kind user
    install_user_tools "${COLLECTED[@]:-}"

    collect_kind manual
    local manifest name
    for manifest in "${COLLECTED[@]:-}"; do
        [ -n "$manifest" ] || continue
        name=$(basename "$manifest" .toml)
        if [ "$name" = "orca" ] && [ -z "${ARTIFACT_PATHS[orca]:-}" ]; then
            warn "orca: sem --artifact orca=PATH, pulando a instalacao do AppImage"
            continue
        fi
        if [ "$name" = "flutter" ] && flutter_present_at_configured_path "$manifest"; then
            info "flutter: revisao alvo ja presente em $(chezmoi execute-template '{{ .paths.flutter }}'); pulando"
            continue
        fi
        install_manual "$name"
    done

    ensure_colorscheme
    generate_palette
    update_xdg_dirs
    set_fish_shell
    enable_display_manager

    if profile_selected dev-containers-db; then
        setup_containers_db
    fi
    if profile_selected ai-harness; then
        install_ai_harness
    fi

    print_auth_checklist
}

main_audit() {
    preflight_common
    collect_kind official
    local -a manifests=("${COLLECTED[@]:-}")
    collect_kind aur
    manifests+=("${COLLECTED[@]:-}")
    audit_report "${manifests[@]}"
}

main_prune() {
    preflight_common
    command -v sudo >/dev/null 2>&1 || die "sudo nao encontrado"
    collect_kind official
    local -a manifests=("${COLLECTED[@]:-}")
    collect_kind aur
    manifests+=("${COLLECTED[@]:-}")
    prune_run "${manifests[@]}"
}

case "$MODE" in
    install) main_install ;;
    audit) main_audit ;;
    prune) main_prune ;;
    *) die "modo desconhecido: $MODE" ;;
esac
