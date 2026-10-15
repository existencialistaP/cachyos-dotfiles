#!/bin/sh
# Sigla do layout de teclado ativo, para o modulo custom/language da waybar.
#
# Por que nao niri/language: no waybar 0.15.0 esse modulo ignora tanto
# "format-<lang>" quanto os placeholders {short}/{shortDescription}/{long}
# (testado: qualquer um deles faz o modulo renderizar vazio), e com o format
# padrao ele imprime o nome longo inteiro ("Portuguese (Brazil)").
#
# niri msg keyboard-layouts imprime:
#    0 Portuguese (Brazil)
#  * 1 English (US)
# A linha com "*" e a ativa; aqui extraimos o que esta entre parenteses e
# encurtamos.

layout=$(niri msg keyboard-layouts 2>/dev/null | sed -n 's/^ *\* *[0-9][0-9]* *//p')

case "$layout" in
*"("*")"*)
    code=${layout#*(}
    code=${code%%)*}
    ;;
*) code=$layout ;;
esac

case "$code" in
Brazil | BR) code=BR ;;
US | USA | "United States" | English) code=US ;;
Portugal | PT) code=PT ;;
esac

# sem layout ativo (ex.: niri reiniciando): nao imprime nada
[ -n "$code" ] || exit 0
printf '%s' "$code"
