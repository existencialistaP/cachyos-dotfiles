#!/usr/bin/env bats
#
# Testes do bootstrap.sh. Nenhum teste toca rede, sudo, pacman real ou o home
# real: o PATH e prefixado por comandos falsos (tests/fakes/) que so registram
# as chamadas em $CALLS e saem com 0.

setup() {
    REPO="$BATS_TEST_DIRNAME/.."
    export HOME="$BATS_TEST_TMPDIR/home"
    mkdir -p "$HOME"
    export XDG_STATE_HOME="$BATS_TEST_TMPDIR/state"
    export OS_RELEASE_FILE="$REPO/tests/fixtures/os-release"
    export CALLS="$BATS_TEST_TMPDIR/calls.log"
    : >"$CALLS"
    export PACMAN_EXPLICIT="$BATS_TEST_TMPDIR/explicit.txt"
    export PACMAN_FOREIGN="$BATS_TEST_TMPDIR/foreign.txt"
    : >"$PACMAN_EXPLICIT"
    : >"$PACMAN_FOREIGN"
    export SHELL=/bin/sh

    FAKEBIN="$BATS_TEST_TMPDIR/fakebin"
    mkdir -p "$FAKEBIN"
    local f
    for f in "$REPO"/tests/fakes/*; do
        ln -s "$f" "$FAKEBIN/$(basename "$f")"
    done
    export PATH="$FAKEBIN:$PATH"

    AUDIT_FILE="$XDG_STATE_HOME/cachyos-dotfiles/audit-unused.txt"
}

# Roda o comando dentro de um pseudo-terminal, entregando $1 como resposta.
run_pty() {
    local input="$1"
    shift
    printf '%s\n' "$input" | script -qec "$*" /dev/null
}

# Imprime a linha informativa do pacman (onde os nomes deduplicados aparecem).
pacman_line() {
    printf '%s\n' "$1" | grep '^\[bootstrap\] pacman -S --needed:'
}

@test "--all --dry-run cobre os 11 perfis, mostra os comandos e nao usa sudo" {
    run "$REPO/bootstrap.sh" --all --dry-run
    [ "$status" -eq 0 ]

    local p
    for p in core desktop-niri shell-editor dev-web dev-containers-db \
        dev-android-flutter dev-jvm-php dev-native apps-daily apps-media ai-harness; do
        [[ "$output" == *"$p"* ]]
    done

    [[ "$output" == *"sudo pacman -S --needed --"* ]]
    [[ "$output" == *"paru -S --needed --"* ]]
    [[ "$output" == *"flatpak install --or-update flathub com.google.AndroidStudio"* ]]
    [[ "$output" == *"pipx install --force pywal16==3.8.15"* ]]
    [[ "$output" == *"uv tool install --force serena-agent==1.7.0"* ]]
    [[ "$output" == *"npm install -g openwiki@0.5.1"* ]]
    [[ "$output" == *"bun add -g @oh-my-pi/pi-coding-agent@18.11.0"* ]]
    [[ "$output" == *"chezmoi apply --dry-run --verbose"* ]]

    # Dry-run nao executa nada e nao cria estado no home.
    ! grep -q '^sudo ' "$CALLS"
    ! grep -q '^paru ' "$CALLS"
    ! grep -q '^chezmoi apply$' "$CALLS"
    [ ! -e "$HOME/.colorscheme" ]
}

@test "pacotes repetidos entre perfis aparecem uma vez so" {
    run "$REPO/bootstrap.sh" --all --dry-run
    [ "$status" -eq 0 ]

    local line count
    line=$(pacman_line "$output")
    [ -n "$line" ]

    for pkg in jdk17-openjdk grim slurp satty wf-recorder python-pipx flatpak uv; do
        count=$(printf '%s\n' "$line" | grep -o " $pkg " | wc -l)
        [ "$count" -eq 1 ]
    done
}

@test "perfil invalido encerra com 2 sem nenhum efeito" {
    run "$REPO/bootstrap.sh" --profile nao-existe
    [ "$status" -eq 2 ]
    [ ! -s "$CALLS" ]
}

@test "--profile sem nome encerra com 2" {
    run "$REPO/bootstrap.sh" --profile
    [ "$status" -eq 2 ]
}

@test "--audit e --prune juntos encerram com 2 sem efeito" {
    run "$REPO/bootstrap.sh" --audit --prune
    [ "$status" -eq 2 ]
    [ ! -s "$CALLS" ]
}

@test "audit separa pacote curado de candidato e protege kernel, GPU e rede" {
    cat >"$PACMAN_EXPLICIT" <<'EOF'
neovim
hyprland
quickshell
linux-cachyos
linux-cachyos-nvidia
nvidia-utils
vulkan-radeon
intel-media-driver
mesa
limine
mkinitcpio
networkmanager
iwd
sudo
pacman
base
EOF
    printf '%s\n' yay spotatui-bin >"$PACMAN_FOREIGN"

    run "$REPO/bootstrap.sh" --all --audit
    [ "$status" -eq 0 ]
    [ -f "$AUDIT_FILE" ]

    grep -qx hyprland "$AUDIT_FILE"
    grep -qx quickshell "$AUDIT_FILE"
    grep -qx yay "$AUDIT_FILE"

    local pkg
    for pkg in neovim linux-cachyos linux-cachyos-nvidia nvidia-utils vulkan-radeon \
        intel-media-driver mesa limine mkinitcpio networkmanager iwd sudo pacman base spotatui-bin; do
        ! grep -qx "$pkg" "$AUDIT_FILE"
    done
}

@test "prune sem TTY recusa e nao chama pacman -Rns" {
    printf '%s\n' hyprland >"$PACMAN_EXPLICIT"
    run "$REPO/bootstrap.sh" --all --prune </dev/null
    [ "$status" -ne 0 ]
    ! grep -q 'pacman -Rns' "$CALLS"
}

@test "com TTY, prune sem REMOVE cancela e nao chama pacman -Rns" {
    command -v script >/dev/null || skip "script indisponivel"
    printf '%s\n' hyprland >"$PACMAN_EXPLICIT"
    run run_pty NAO "$REPO/bootstrap.sh" --all --prune
    [ "$status" -ne 0 ]
    ! grep -q 'pacman -Rns' "$CALLS"
}

@test "com TTY, prune com REMOVE chama sudo pacman -Rns com os candidatos" {
    command -v script >/dev/null || skip "script indisponivel"
    printf '%s\n' hyprland quickshell >"$PACMAN_EXPLICIT"
    run run_pty REMOVE "$REPO/bootstrap.sh" --all --prune
    grep -q 'sudo pacman -Rns -- hyprland quickshell' "$CALLS"
}

@test "orca com checksum errado falha antes de copiar" {
    local bad="$BATS_TEST_TMPDIR/orca.AppImage"
    printf 'nao e o appimage\n' >"$bad"

    run "$REPO/bootstrap.sh" --profile ai-harness --dry-run --artifact "orca=$bad"
    [ "$status" -ne 0 ]
    [[ "$output" == *sha256* ]]
    [ ! -e "$HOME/.local/bin/orca.AppImage" ]
}

@test "install_artifact copia o artefato com o sha correto e modo 755" {
    local art="$BATS_TEST_TMPDIR/orca-real"
    printf '#!/bin/sh\necho orca\n' >"$art"
    chmod 644 "$art"
    local sha
    sha=$(sha256sum "$art" | cut -d' ' -f1)

    run bash -c "
        run() { \"\$@\"; }
        info() { :; }
        warn() { :; }
        die() { echo \"erro: \$*\" >&2; exit 1; }
        . '$REPO/lib/manual.sh'
        declare -A ARTIFACT_PATHS=([orca]='$art')
        DRY_RUN=0
        install_artifact orca 1.0 '$sha' '~/.local/bin/orca.AppImage'
    "
    [ "$status" -eq 0 ]
    [ -x "$HOME/.local/bin/orca.AppImage" ]
    [ "$(sha256sum "$HOME/.local/bin/orca.AppImage" | cut -d' ' -f1)" = "$sha" ]
}
