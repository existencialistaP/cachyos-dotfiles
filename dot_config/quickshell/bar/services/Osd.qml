pragma Singleton

import QtQuick
import Quickshell

Singleton {
    id: root

    property bool visible: false
    property string kind: "volume"
    property real value: 0
    property string text: ""

    function show(kind, value, text) {
        root.kind = kind
        root.value = Math.max(0, Math.min(1, value))
        root.text = text !== undefined ? text : Math.round(root.value * 100) + "%"
        root.visible = true
        hideTimer.restart()
    }

    Timer {
        id: hideTimer
        interval: 1500
        onTriggered: root.visible = false
    }
}
