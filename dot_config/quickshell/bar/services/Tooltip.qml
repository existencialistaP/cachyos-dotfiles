pragma Singleton

import QtQuick
import Quickshell

Singleton {
    id: root

    property string text: ""
    property Item item: null
    property bool shown: false

    Timer {
        id: delay
        interval: 450
        onTriggered: if (root.text !== "" && root.item !== null) root.shown = true
    }

    function show(text, item) {
        if (!text) {
            hide()
            return
        }
        root.text = text
        root.item = item
        root.shown = false
        delay.restart()
    }

    function hide() {
        delay.stop()
        root.shown = false
        root.text = ""
        root.item = null
    }
}
