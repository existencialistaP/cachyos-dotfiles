#!/bin/sh
# Quick Actions: one press, one action, no submenus.
# Volume toggles mute and Brightness raises by 10% — both shown through swayosd.

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
    swayosd-client --output-volume mute-toggle
    ;;
  Brightness)
    swayosd-client --brightness +10
    ;;
  Wallpaper)
    waypaper
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