#!/bin/sh
# Quick Actions: one press, one action, no submenus.
# Volume/brightness passam pelo shell (OSD próprio), wallpaper pelo picker do qs.

menu() {
  printf '%s\n' \
    'Volume' \
    'Brightness' \
    'Wallpaper' \
    'Theme' \
    'Screenshot' \
    'Lock' \
    | fuzzel --dmenu --prompt='Quick Actions: '
}

case "$(menu)" in
  Volume)
    qs ipc -c bar call bar volumeMute
    ;;
  Brightness)
    qs ipc -c bar call bar brightnessUp
    qs ipc -c bar call bar brightnessUp
    ;;
  Wallpaper)
    qs ipc -c bar call bar wallpaperToggle
    ;;
  Theme)
    "$HOME/.config/niri/scripts/themeSwitch.sh"
    ;;
  Screenshot)
    "$HOME/.config/niri/scripts/screenshots.sh"
    ;;
  Lock)
    "$HOME/.config/niri/scripts/lock.sh"
    ;;
esac