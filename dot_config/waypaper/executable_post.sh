#!/bin/bash

wallpaper="$1"
scheme=$(cat ~/.colorscheme)



echo "Wallpaper: $wallpaper"
echo "Scheme: $scheme"


ln -sf "$wallpaper" ~/.cache/wal/current-wallpaper

if [ "$scheme" = "light" ]; then
  wal -l -i "$wallpaper"
else
  wal -i "$wallpaper"
fi

# niri le o ~/.cache/wal/colors-niri.kdl so na hora de carregar a config, entao
# sem este reload as cores novas (borda, etc.) so valeriam no proximo login.
niri msg action load-config-file >/dev/null 2>&1 || true
