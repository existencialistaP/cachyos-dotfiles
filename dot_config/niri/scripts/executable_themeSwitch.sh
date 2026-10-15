#!/bin/bash
scheme=$(cat ~/.colorscheme)
echo "$scheme"

if [ "$scheme" = "light" ]; then
  wal -w -n
  gsettings set org.gnome.desktop.interface color-scheme prefer-dark
  echo "dark" >~/.colorscheme
else
  wal -w -l -n
  gsettings set org.gnome.desktop.interface color-scheme prefer-light
  echo "light" >~/.colorscheme
fi
