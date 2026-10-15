#!/bin/sh
# Clipboard manager: picks an entry from the cliphist history through Fuzzel
# and copies it back with wl-copy. Text and images are both handled by
# cliphist (populated by the wl-paste --watch stores in config.kdl).
selection=$(cliphist list | fuzzel --dmenu --prompt='Clipboard: ')
[ -n "$selection" ] || exit 0
printf '%s' "$selection" | cliphist decode | wl-copy