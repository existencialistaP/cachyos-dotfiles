#!/bin/sh
# Estado do modo NAO PERTURBE do mako, para o modulo custom/notification da waybar.
# Clique esquerdo liga/desliga (makoctl mode -t do-not-disturb).
#
# Saida em JSON porque a waybar usa "return-type": "json": o campo "class" e usado
# pelo CSS (#custom-notification.dnd) e o "tooltip" aparece no hover.

if makoctl mode 2>/dev/null | grep -qx 'do-not-disturb'; then
    printf '{"text":"\\uf1f6","class":"dnd","tooltip":"NAO PERTURBE ligado - clique para desligar"}'
else
    printf '{"text":"\\uf0f3","class":"none","tooltip":"Notificacoes normais - clique para NAO PERTURBE"}'
fi
