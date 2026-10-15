#!/bin/sh
# Menu de rede para o fuzzel.
#
# A waybar tinha "on-click": "networkmanager_dmenu" (nao instalado), entao clicar
# na rede nao fazia nada. Este script reusa o fuzzel como o resto do setup.
#
# Uso: clique esquerdo no modulo network da waybar.
set -u

menu() { fuzzel --dmenu --lines 12 --prompt "$1"; }

# --- redes: dedup por SSID (maior sinal), marcando a conectada com * -------
list_networks() {
    nmcli -t -f IN-USE,SSID,SIGNAL device wifi list --rescan no 2>/dev/null |
        awk -F: '
            $2 == "" { next }
            {
                sig = $3 + 0
                if (!($2 in seen) || sig > seen[$2]) {
                    seen[$2] = sig
                    mark[$2] = ($1 == "*") ? "* " : "  "
                    line[$2] = $2 " (" sig "%)"
                }
                if ($1 == "*") mark[$2] = "* "
            }
            END { for (s in line) print mark[s] line[s] }
        ' | sort
}

if [ "$(nmcli -t -f WIFI general 2>/dev/null)" = "enabled" ]; then
    toggle='Desligar Wi-Fi'
else
    toggle='Ligar Wi-Fi'
fi

choice=$(
    {
        printf '%s\n' "$toggle" 'Status do dispositivo' 'Conexoes salvas'
        list_networks
    } | menu 'Rede: '
)
[ -n "$choice" ] || exit 0

case "$choice" in
'Ligar Wi-Fi')
    nmcli radio wifi on
    ;;
'Desligar Wi-Fi')
    nmcli radio wifi off
    ;;
'Status do dispositivo')
    nmcli -t device status | menu 'nmcli: '
    ;;
'Conexoes salvas')
    pick=$(nmcli -t -f NAME connection show | menu 'Conectar: ')
    [ -n "$pick" ] || exit 0
    nmcli connection up "$pick" >/dev/null 2>&1 &&
        notify-send 'Rede' "Conectado em $pick" ||
        notify-send -u critical 'Rede' "Falha ao conectar em $pick"
    ;;
'* '*)
    # ja conectada: nao faz nada, so avisa
    notify-send 'Rede' "${choice#\* } ja esta conectada"
    ;;
*)
    ssid=${choice% (*}
    ssid=${ssid#"  "}
    ssid=${ssid#\* }
    [ -n "$ssid" ] || exit 0
    # conexao ja salva: sobe direto, sem pedir senha
    if nmcli -t -f NAME connection show | grep -qxF "$ssid"; then
        nmcli connection up "$ssid" >/dev/null 2>&1 &&
            notify-send 'Rede' "Conectado em $ssid" ||
            notify-send -u critical 'Rede' "Falha ao conectar em $ssid"
        exit 0
    fi
    if nmcli device wifi connect "$ssid" >/dev/null 2>&1; then
        notify-send 'Rede' "Conectado em $ssid"
        exit 0
    fi
    pw=$(menu "Senha de $ssid: ")
    [ -n "$pw" ] || exit 0
    nmcli device wifi connect "$ssid" password "$pw" >/dev/null 2>&1 &&
        notify-send 'Rede' "Conectado em $ssid" ||
        notify-send -u critical 'Rede' "Falha ao conectar em $ssid"
    ;;
esac
