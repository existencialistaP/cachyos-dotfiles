#!/bin/sh
# Niri Actions: useful compositor operations exposed through Fuzzel.
# All actions use the IPC of the installed niri (verify with: niri msg action help).

menu() {
  printf '%s\n' \
    'Overview' \
    'Center Column' \
    'Maximize' \
    'Fullscreen' \
    'Toggle Floating' \
    'Focus Next' \
    'Focus Previous' \
    | fuzzel --dmenu --prompt='Niri: '
}

case "$(menu)" in
  Overview)
    niri msg action toggle-overview
    ;;
  'Center Column')
    niri msg action center-column
    ;;
  Maximize)
    niri msg action maximize-column
    ;;
  Fullscreen)
    niri msg action fullscreen-window
    ;;
  'Toggle Floating')
    niri msg action toggle-window-floating
    ;;
  'Focus Next')
    niri msg action focus-column-right-or-first
    ;;
  'Focus Previous')
    niri msg action focus-column-left-or-last
    ;;
esac