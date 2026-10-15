#!/bin/sh
# Imprime o RESTANTE do título da janela focada: exatamente o que o módulo
# niri/window corta quando usa "max-length": 12 (11 caracteres + "…").
#
# É o filho do drawer do group/title na waybar: em repouso você vê só o líder
# (12 chars); no hover este módulo completa a frase em vez de repetir o começo.
#
# Design: UMA leitura por execução, sem loop e sem processo filho. A waybar
# chama de novo a cada "interval" (2s) do módulo. A primeira versão ficava
# escutando `niri msg event-stream` para ser instantânea, mas o filho do
# event-stream sobrevivia ao reload da waybar: um órfão por reload, e ainda
# segurava o pipe do stdout do pai (travava qualquer um lendo a saída). Leitura
# por intervalo é mais chata e não vaza nada.
#
# ATENÇÃO: o 11 do `cut -c12-` casa com o max-length 12 do niri/window.
# Se mudar o max-length lá, mude aqui.

niri msg --json windows 2>/dev/null \
    | jq -r '[.[] | select(.is_focused)][0].title // ""' \
    | cut -c12-
