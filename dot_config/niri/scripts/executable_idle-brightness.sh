#!/bin/sh
# Idle brightness: "dim" lowers the panel after a stretch of inactivity and
# "restore" puts it back on activity. Used by the swayidle idle stages, so the
# dim is driven by idleness only - locking the screen does not dim anything.
#
# The dim is a fraction of the *current* brightness, so it also gets darker
# when you are already at a low setting (and never brightens the panel).
#
# Usage: idle-brightness.sh dim|restore
#   DIM_FACTOR=<percent of current>  brightness while dimmed   (default 40)
#   DIM_FLOOR=<percent of maximum>   never go below this       (default 2)
#
# State: $XDG_RUNTIME_DIR/niri-idle-brightness holds "<original> <dimmed>".

set -u

STATE="${XDG_RUNTIME_DIR:-/tmp}/niri-idle-brightness"
DIM_FACTOR="${DIM_FACTOR:-40}"
DIM_FLOOR="${DIM_FLOOR:-2}"

command -v brightnessctl >/dev/null 2>&1 || exit 0

case "${1:-}" in
dim)
    # Already dimmed: keep the first original value.
    [ -e "$STATE" ] && exit 0
    cur=$(brightnessctl -m get 2>/dev/null) || exit 0
    max=$(brightnessctl -m max 2>/dev/null) || exit 0
    [ -n "$cur" ] && [ -n "$max" ] && [ "$max" -gt 0 ] || exit 0

    target=$((cur * DIM_FACTOR / 100))
    floor=$((max * DIM_FLOOR / 100))
    [ "$target" -lt "$floor" ] && target=$floor
    # Never brighten the panel.
    [ "$target" -ge "$cur" ] && exit 0

    printf '%s %s\n' "$cur" "$target" > "$STATE"
    brightnessctl -q set "$target" || rm -f "$STATE"
    ;;
restore)
    [ -s "$STATE" ] || exit 0
    read -r orig dim_value < "$STATE"
    rm -f "$STATE"
    # If the brightness keys were used while dimmed, respect the new value.
    now=$(brightnessctl -m get 2>/dev/null) || exit 0
    [ -n "$orig" ] && [ "$now" = "$dim_value" ] && brightnessctl -q set "$orig"
    ;;
*)
    echo "usage: $0 dim|restore" >&2
    exit 2
    ;;
esac
