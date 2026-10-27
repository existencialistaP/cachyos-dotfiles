pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    // fallback while ~/.cache/wal/colors.json is not read
    property var palette: ({
        special: { background: "#0c1227", foreground: "#c3c4c8" },
        colors: {
            color0: "#0c1227", color1: "#0043d3", color2: "#275de2",
            color3: "#795dc9", color4: "#5f72de", color5: "#808fe5",
            color6: "#fe6a90", color7: "#c3c4c8", color8: "#545c7e",
            color9: "#0043d3", color10: "#275de2", color11: "#795dc9",
            color12: "#5f72de", color13: "#808fe5", color14: "#fe6a90",
            color15: "#c3c4c8"
        }
    })

    FileView {
        id: colorsFile
        path: Quickshell.env("HOME") + "/.cache/wal/colors.json"
        watchChanges: true
        blockLoading: true
        onTextChanged: root.reload()
        onFileChanged: reload()
        Component.onCompleted: root.reload()
    }

    function reload() {
        try {
            const parsed = JSON.parse(colorsFile.text())
            if (parsed && parsed.special)
                palette = parsed
        } catch (e) {
            // keep the last good palette
        }
    }

    readonly property var special: palette.special ?? ({})
    readonly property var colors: palette.colors ?? ({})

    readonly property color bg: special.background ?? "#111111"
    readonly property color fg: special.foreground ?? "#dddddd"
    readonly property color dim: Qt.rgba(fg.r, fg.g, fg.b, 0.55)
    readonly property color faint: Qt.rgba(fg.r, fg.g, fg.b, 0.35)
    readonly property color hover: Qt.rgba(fg.r, fg.g, fg.b, 0.08)
    readonly property color line: Qt.rgba(fg.r, fg.g, fg.b, 0.14)
    readonly property color accent: colors.color4 ?? "#5f72de"
    readonly property color error: colors.color1 ?? "#d30043"
    readonly property color pink: colors.color6 ?? "#fe6a90"

    readonly property string fontFamily: "JetBrainsMono Nerd Font"
    readonly property int fontSize: 12
    readonly property int barHeight: 30
    readonly property int pad: 20
    readonly property int cardPad: 12
    readonly property int cardWidth: 320
    readonly property int gap: 8
}
