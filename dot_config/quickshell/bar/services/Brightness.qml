pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Leitura/escrita direta do sysfs (usuário está no grupo video), sem processo
// por evento de arraste. shown >= 0 segura o valor local durante o gesto.
Singleton {
    id: root

    readonly property string device: "/sys/class/backlight/intel_backlight"

    property int raw: 0
    property int maxRaw: 1
    property real shown: -1

    readonly property real pct: shown >= 0 ? shown : (maxRaw > 0 ? raw / maxRaw : 0)

    FileView {
        id: readFile
        path: root.device + "/brightness"
        blockLoading: true
        onTextChanged: {
            if (root.shown < 0)
                root.raw = Number(text())
        }
    }

    FileView {
        id: writeFile
        path: root.device + "/brightness"
        atomicWrites: false
        blockWrites: true
    }

    FileView {
        id: maxFile
        path: root.device + "/max_brightness"
        blockLoading: true
        onTextChanged: root.maxRaw = Math.max(1, Number(text()))
    }

    Timer {
        id: writeTimer
        interval: 30
        onTriggered: writeFile.setText(String(root.raw))
    }

    Timer {
        id: idleTimer
        interval: 700
        onTriggered: root.shown = -1
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        onTriggered: {
            if (root.shown < 0) {
                readFile.reload()
                maxFile.reload()
            }
        }
    }

    function apply(value) {
        const clamped = Math.max(0.02, Math.min(1, value))
        shown = clamped
        raw = Math.round(clamped * maxRaw)
        writeTimer.restart()
        idleTimer.restart()
    }

    function up(step) {
        apply(pct + (step ?? 0.05))
    }

    function down(step) {
        apply(pct - (step ?? 0.05))
    }
}
