# cachyos-dotfiles

Configuracao pessoal do CachyOS com Niri, gerenciada pelo [Chezmoi], mais um
bootstrap idempotente para reproduzir a estacao do zero.

Nao ha Hyprland, Quickshell, SDDM, Waydroid, Firefox, Thunderbird, MPV, VLC,
Showtime ou Decibels em nenhum perfil.

## Instalacao numa maquina nova

```sh
sudo pacman -S --needed git chezmoi
chezmoi init existencialistaP/cachyos-dotfiles
~/.local/share/chezmoi/bootstrap.sh
```

`chezmoi init` pergunta uma vez os dados da maquina (nome/e-mail do git, saida
e escala do monitor, GPU hibrida NVIDIA, caminhos de Android SDK, Flutter,
musica e wallpapers) e grava em `~/.config/chezmoi/chezmoi.toml`. Se a maquina
ja tem o Flutter em outro lugar, informe o caminho real em `paths.flutter`:
o valor gravado manda, e o bootstrap nao instala uma segunda copia quando a
revisao alvo ja existe nesse caminho.

O bootstrap usa sudo apenas para pacman/paru/flatpak, systemd e `chsh`. Ele
nunca edita `pacman.conf`, mirrors, kernel, bootloader, microcode, firmware ou
drivers de GPU: isso continua sendo do instalador do CachyOS.

## Perfis

O registro unico e `profiles/profiles.toml`. Cada perfil aponta para manifests
por gerenciador (`packages/official`, `packages/aur`, `packages/flatpak`,
`packages/<ferramenta-de-usuario>.txt`, `packages/manual`).

Obrigatorios: `core`, `desktop-niri`, `shell-editor`.

Opcionais: `dev-web`, `dev-containers-db`, `dev-android-flutter`, `dev-jvm-php`,
`dev-native`, `apps-daily`, `apps-media`, `ai-harness`.

```sh
./bootstrap.sh --all --dry-run          # todos os 11 perfis, sem mudar nada
./bootstrap.sh --profile dev-native --profile apps-daily --dry-run
./bootstrap.sh --all --artifact orca="$HOME/.local/bin/orca.AppImage"
```

Sem flags de perfil, o bootstrap instala os tres obrigatorios e mostra um menu
numerico para escolher os opcionais.

## Previa antes de aplicar

```sh
chezmoi diff                        # o que mudaria no home
chezmoi apply --dry-run --verbose   # previa detalhada
./bootstrap.sh --all --dry-run      # previa de pacotes + apply
```

O `chezmoi apply` de verdade (e o bootstrap) exigem a confirmacao literal
`APPLY` no terminal.

## Auditoria e limpeza (opt-in)

```sh
./bootstrap.sh --audit   # escreve ~/.local/state/cachyos-dotfiles/audit-unused.txt
./bootstrap.sh --prune   # mostra a lista, exige TTY e a palavra REMOVE
```

`--audit` compara os pacotes instalados explicitamente com a uniao dos
manifests e separa candidatos. Kernel, bootloader, firmware, microcode, GPU
(`nvidia*`, `vulkan*`, `intel*`, `mesa*`), `cachyos-*`, GDM, NetworkManager,
iwd, sudo e pacman nunca entram na lista. Nada e removido sem `REMOVE` digitado.

## Assuntos deliberadamente manuais

- **Orca Agent**: nao tem URL publica estavel. O bootstrap so instala com
  `--artifact orca=/caminho/orca.AppImage` e recusa SHA-256 diferente do
  registrado em `packages/manual/orca.toml`.
- **Autenticacao**: GitHub (`gh auth login`), pywalfox dentro do LibreWolf,
  login do Spotify no Spotatui, login no OpenCode/OMP, TablePlus e o provider
  local do OpenCode. O bootstrap imprime o checklist e nao executa nem le
  credencial:
  ```sh
  sleev setup --no-open
  # depois do login no navegador:
  sleev gateway bind --host 127.0.0.1 --port 17321 --restart
  ```
- **Fontes**: instaladas pelos manifests (`noto-fonts*`, `ttf-lilex`,
  `ttf-jetbrains-mono-nerd`), nunca copiadas de outro usuario.
- **`~/wallpapers/wallpapers/asuka.gif`** (204,9 MB) fica fora do Git; os
  outros 45 wallpapers entram normalmente.

## O que nao e versionado (e por que)

Ficam fora do Git, por serem estado ou segredo: credenciais e `.env*`,
`service.json`, `auth.json`, `account.json`, `contexts/`, bancos e WAL/SHM,
logs, sessoes de terminal, caches, backups, AppImages e artefatos gerados por
Orca/herdr. Perfis de navegador/Electron, cookies, keyrings, SDKs e sessoes de
aplicativos permanecem fora mesmo quando algum app escolhido os cria.

Arquivos gerados pelo pywal (`~/.cache/wal/*`, tema Kvantum, `fuzzel.ini` e as
cores de waybar/kitty/mako/niri) nao sao versionados: o `wal` os recria a
partir dos templates em `dot_config/wal/templates`. `~/.colorscheme` e estado
mutavel: o bootstrap cria com `dark` somente se nao existir.

## Nenhum segredo no Git

O hook `.githooks/pre-commit` bloqueia o commit se encontrar chaves, tokens ou
caminhos proibidos; rode `git config core.hooksPath .githooks` no clone. Se
algo sensivel aparecer no staging, tire o arquivo, amplie o `.gitignore` e
rotacione a credencial antes de publicar.

## Harness de agentes (OpenCode + OMP)

O perfil `ai-harness` clona `existencialistaP/ai-agent-config` em
`~/.local/share/ai-agent-config` e roda o `install.sh` de la, que mantem as
configuracoes de OpenCode e OMP em conjunto (`opencode/`, `omp/`) e cria os
links de `commands`/`skills`.

[Chezmoi]: https://chezmoi.io
