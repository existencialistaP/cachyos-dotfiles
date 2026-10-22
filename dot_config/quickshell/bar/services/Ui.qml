pragma Singleton

import Quickshell

// Qual card está aberto e como ele ancora:
//   mode = "item"   → em cima/embaixo do ícone clicado
//   mode = "center" → centralizado na horizontal, colado na barra (keybind/IPC)
Singleton {
    id: root

    property string active: ""
    property string mode: "item"

    function toggle(key, mode) {
        if (active === key) {
            close()
            return
        }
        root.mode = mode ?? "item"
        active = key
    }

    function open(key, mode) {
        root.mode = mode ?? "item"
        active = key
    }

    function close() {
        active = ""
    }
}
