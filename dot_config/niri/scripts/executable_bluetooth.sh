#!/bin/sh
# Menu de bluetooth para o fuzzel.
#
# Espelha o network.sh: mesmo fuzzel --dmenu, mesmo notify-send, so que sobre o
# bluez em vez do NetworkManager. A waybar nao traz menu proprio de bluetooth,
# entao o clique no modulo bluetooth da barra abre este script — igual ao
# modulo network, que chama o network.sh.
#
# Uso: clique esquerdo no modulo bluetooth da waybar, ou Command Center > Bluetooth.
set -u

menu() { fuzzel --dmenu --lines 12 --prompt "$1"; }

bt() {
    # bluetoothctl NAO sai quando o comando falha antes do D-Bus responder: um
    # connect/pair em MAC desconhecido (device saiu do cache entre o menu e o
    # clique) fica vivo para sempre e trava o script. Medido em 2026-10-14:
    # `bluetoothctl connect 00:11:22:33:44:55` passou de 3 min sem sair. Com o
    # timeout o pior caso vira "Falha ao conectar". Erro devolvido pelo D-Bus
    # (busy / offline) sai na hora com rc=1, entao o timeout so pega o patologico.
    timeout 20 bluetoothctl "$@" 2>/dev/null
}

# "Powered: yes" e a forma estavel de saber se o radio esta ligado.
is_powered() { [ "$(bt show | awk '/Powered:/ {print $2}')" = "yes" ]; }

# --- lista de pareados: "*" marca o conectado, MAC entre parenteses ----------
# O MAC vai na propria linha (e nao num lookup por nome) porque nome de device
# bluetooth tem espaco e pode repetir; os parenteses no fim delimitam o campo
# sem ambiguidade, como o " (82%)" do network.sh. O MAC tambem serve de chave
# de dedup: durante um scan o mesmo device pode aparecer duas vezes, e ai fica
# o nome mais longo.
list_paired() {
    connected=$(bt devices Connected | awk '{print $2}' | tr '\n' '|')
    bt devices Paired | awk -v connected="$connected" '
        {
            mac = $2
            $1 = ""; $2 = ""
            name = substr($0, 3)
            gsub(/ +/, " ", name)
            if (name == "") name = mac
            order[++n] = mac
            if (!(mac in best) || length(name) > length(best[mac])) best[mac] = name
        }
        END {
            for (i = 1; i <= n; i++) {
                mac = order[i]
                if (seen[mac]++) continue
                mark = index(connected, mac "|") ? "* " : "  "
                print mark best[mac] " (" mac ")"
            }
        }' | sort
}

# --- conhecidos que ainda NAO estao pareados: candidatos ao pareamento ------
list_new() {
    paired=$(bt devices Paired | awk '{print $2}' | tr '\n' '|')
    bt devices | awk -v paired="$paired" '
        {
            mac = $2
            if (index(paired, mac "|")) next
            $1 = ""; $2 = ""
            name = substr($0, 3)
            gsub(/ +/, " ", name)
            if (name == "") name = mac
            order[++n] = mac
            if (!(mac in best) || length(name) > length(best[mac])) best[mac] = name
        }
        END {
            for (i = 1; i <= n; i++) {
                mac = order[i]
                if (seen[mac]++) continue
                print best[mac] " (" mac ")"
            }
        }'
}

# sem adaptador (bluetooth.service parado, por exemplo) o menu mentiria
if [ -z "$(bt show)" ]; then
    notify-send -u critical 'Bluetooth' 'Sem controlador: bluetooth.service parado?'
    exit 1
fi

if is_powered; then
    toggle='Desligar Bluetooth'
else
    toggle='Ligar Bluetooth'
fi

choice=$(
    {
        printf '%s\n' "$toggle" 'Status do controlador' 'Dispositivos pareados'
        # as duas listas so fazem sentido com o radio ligado
        if is_powered; then
            printf '%s\n' 'Escanear (10s)'
            list_paired
        fi
    } | menu 'Bluetooth: '
)
[ -n "$choice" ] || exit 0

case "$choice" in
'Ligar Bluetooth')
    bt power on >/dev/null
    notify-send 'Bluetooth' 'Ligado'
    ;;
'Desligar Bluetooth')
    bt power off >/dev/null
    notify-send 'Bluetooth' 'Desligado'
    ;;
'Status do controlador')
    bt show | menu 'bluetoothctl: '
    ;;
'Dispositivos pareados')
    pick=$(list_paired | menu 'Conectar: ')
    [ -n "$pick" ] || exit 0
    mac=${pick##* (}; mac=${mac%)}
    name=${pick% (*}
    bt connect "$mac" >/dev/null &&
        notify-send 'Bluetooth' "Conectado em $name" ||
        notify-send -u critical 'Bluetooth' "Falha ao conectar em $name"
    ;;
'Escanear (10s)')
    # o --timeout do bluetoothctl encerra o scan em 10s; o timeout de fora e so
    # a rede de seguranca caso ele fique preso como no caso do connect
    timeout 25 bluetoothctl --timeout 10 scan on >/dev/null 2>&1
    pick=$(list_new | menu 'Parear: ')
    [ -n "$pick" ] || exit 0
    mac=${pick##* (}; mac=${mac%)}
    name=${pick% (*}
    if bt pair "$mac" >/dev/null; then
        # parear nao conecta; e o connect que traz o audio
        bt connect "$mac" >/dev/null
        notify-send 'Bluetooth' "Pareado com $name"
    else
        notify-send -u critical 'Bluetooth' "Falha ao parear com $name"
    fi
    ;;
'* '*)
    # ja conectado: aqui o desconectar vale mais que o aviso do network.sh
    mac=${choice##* (}; mac=${mac%)}
    name=${choice% (*}; name=${name#??}
    pick=$(printf '%s\n' 'Desconectar' 'Cancelar' | menu "$name: ")
    [ "$pick" = 'Desconectar' ] || exit 0
    bt disconnect "$mac" >/dev/null &&
        notify-send 'Bluetooth' "Desconectado de $name" ||
        notify-send -u critical 'Bluetooth' "Falha ao desconectar $name"
    ;;
*)
    # linha da lista de pareados (sem "* "): sobe a conexao
    mac=${choice##* (}; mac=${mac%)}
    name=${choice% (*}; name=${name#??}
    bt connect "$mac" >/dev/null &&
        notify-send 'Bluetooth' "Conectado em $name" ||
        notify-send -u critical 'Bluetooth' "Falha ao conectar em $name"
    ;;
esac
