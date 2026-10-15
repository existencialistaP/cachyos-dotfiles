#!/bin/sh
# Lock the screen with hyprlock.
#
# Locking itself does not touch the brightness on purpose: the idle dim/blank
# stages (see ~/.config/swayidle/config) are what darken the screen, so a lock
# triggered by Super+Alt+L keeps the screen at full brightness, like GNOME and
# Windows do.
#
# Two things this wrapper still adds:
#   * a single-instance guard, so before-sleep or a second call never stacks a
#     second hyprlock on top of a running lock;
#   * restoring the idle dim on unlock, so coming back to the lock screen never
#     leaves you on a dimmed panel even if the idle "resume" did not fire.
#
# Knobs (env): HYPRLOCK_CONF=<path>, HYPRLOCK=<cmd> (handy for testing).

set -u

CONF="${HYPRLOCK_CONF:-$HOME/.config/hyprlock/hyprlock.conf}"
HYPRLOCK_BIN="${HYPRLOCK:-hyprlock}"
IDLE_BRIGHTNESS="${IDLE_BRIGHTNESS:-$HOME/.config/niri/scripts/idle-brightness.sh}"

# A lock is already up: don't stack a second one. This also keeps before-sleep
# from blocking on an already locked session.
if command -v flock >/dev/null 2>&1; then
    exec 9>"${XDG_RUNTIME_DIR:-/tmp}/niri-lock.lock"
    flock -n 9 || exit 0
fi

# Undim right after the lock ends, whatever the reason (unlock, error, signal).
# Please don't kill the hyprlock child here: dying with the screen still locked
# is the safe side of that trade.
trap '[ -x "$IDLE_BRIGHTNESS" ] && "$IDLE_BRIGHTNESS" restore' EXIT HUP INT TERM

"$HYPRLOCK_BIN" -c "$CONF" --immediate-render
