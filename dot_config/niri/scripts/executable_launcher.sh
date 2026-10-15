#!/usr/bin/env bash
# Command Center: thin menu that also searches installed applications.
# Type an app name directly (Super+A -> "spo" -> Enter launches Spotify):
# no need to open a submenu first. Entries that match a command center item
# run their script; everything else falls back to launching the app.

SCRIPTS="$HOME/.config/niri/scripts"

actions=(
    'Applications'
    'Clipboard'
    'Quick Actions'
    'Bluetooth'
    'Wallpaper'
    'Screenshots'
    'Niri'
    'System'
)

# --- collect installed applications (Name -> .desktop file) -------------------
app_files=()
while IFS= read -r f; do
    [ -n "$f" ] && app_files+=("$f")
done < <(
    {
        ls "$HOME/.local/share/applications/"*.desktop 2>/dev/null
        ls /usr/share/applications/*.desktop 2>/dev/null
        ls /usr/local/share/applications/*.desktop 2>/dev/null
    } | sort -u
)

declare -A file_cmd
app_names=()
for f in "${app_files[@]}"; do
    name=$(awk '
        /^\[Desktop Entry\]/ { in_main = 1; next }
        /^\[/ { in_main = 0; next }
        in_main && /^NoDisplay=true/  { nodisplay = 1 }
        in_main && /^Hidden=true/     { hidden = 1 }
        in_main && /^Name=/           { name = substr($0, 6) }
        END { if (name != "" && !nodisplay && !hidden) print name }
    ' "$f")
    [ -n "$name" ] || continue
    file_cmd["$name"]="$f"
    app_names+=("$name")
done

# --- menu: commands first, then applications ----------------------------------
selection=$(
    {
        printf '%s\n' "${actions[@]}"
        printf '%s\n' "${app_names[@]}" | sort -u
    } | fuzzel --dmenu --prompt='Command Center: '
)
[ -n "$selection" ] || exit 0

case "$selection" in
    Applications)
        fuzzel --prompt="$(date '+%H:%M')  " --lines 12
        ;;
    Clipboard)
        "$SCRIPTS/clipboard.sh"
        ;;
    'Quick Actions')
        "$SCRIPTS/actions.sh"
        ;;
    Bluetooth)
        "$SCRIPTS/bluetooth.sh"
        ;;
    Wallpaper)
        waypaper
        ;;
    Screenshots)
        "$SCRIPTS/screenshots.sh"
        ;;
    Niri)
        "$SCRIPTS/niri-actions.sh"
        ;;
    System)
        "$SCRIPTS/system.sh"
        ;;
    *)
        desktop="${file_cmd[$selection]:-}"
        if [ -n "$desktop" ]; then
            gtk-launch "$(basename "$desktop")"
        elif [ "$selection" = "${selection% *}" ] && command -v "$selection" >/dev/null 2>&1; then
            niri msg action spawn-sh "$selection"
        fi
        ;;
esac