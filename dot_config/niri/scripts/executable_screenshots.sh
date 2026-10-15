#!/bin/sh
# Screenshots menu.
# Reuses niri's built-in screenshot UI (already bound to Super+P, Super+Shift+P,
# Super+Ctrl+P) instead of an extra tool. "Area" opens the interactive selector.

case "$(printf '%s\n' 'Screen' 'Window' 'Area' | fuzzel --dmenu --prompt='Screenshot: ')" in
  Screen)
    niri msg action screenshot-screen
    ;;
  Window)
    niri msg action screenshot-window
    ;;
  Area)
    niri msg action screenshot
    ;;
esac