#!/bin/sh
# System Actions: lock, suspend, reboot and shutdown.
# Reboot/Shutdown ask for confirmation through Fuzzel to avoid accidents.

LOCK_CMD="$HOME/.config/niri/scripts/lock.sh"

confirm() {
  answer=$(printf '%s\n' 'No' 'Yes' | fuzzel --dmenu --prompt="$1 ")
  [ "$answer" = "Yes" ]
}

case "$(printf '%s\n' 'Lock' 'Suspend' 'Reboot' 'Shutdown' | fuzzel --dmenu --prompt='System: ')" in
  Lock)
    sh -c "$LOCK_CMD"
    ;;
  Suspend)
    systemctl suspend
    ;;
  Reboot)
    confirm 'Reboot?' && systemctl reboot
    ;;
  Shutdown)
    confirm 'Shutdown?' && systemctl poweroff
    ;;
esac