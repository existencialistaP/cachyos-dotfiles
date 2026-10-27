pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Persistência real em disco (PersistentProperties só sobrevive a reload de QML).
Singleton {
    id: root

    property bool loading: true

    property string barPosition: "bottom"
    property int barHeight: 30
    property string wallpaperDir: Quickshell.env("HOME") + "/wallpapers/wallpapers"

    readonly property string path: Quickshell.env("HOME") + "/.config/quickshell/bar/settings.json"

    FileView {
        id: file
        path: root.path
        blockLoading: true
        onLoaded: root.load()
        Component.onCompleted: root.load()
    }

    Timer {
        id: saveTimer
        interval: 200
        onTriggered: root.save()
    }

    onBarPositionChanged: if (!loading) saveTimer.restart()
    onBarHeightChanged: if (!loading) saveTimer.restart()
    onWallpaperDirChanged: if (!loading) saveTimer.restart()

    function load() {
        loading = true
        try {
            const data = JSON.parse(file.text())
            if (data.barPosition === "top" || data.barPosition === "bottom")
                barPosition = data.barPosition
            if (typeof data.barHeight === "number" && data.barHeight >= 20 && data.barHeight <= 60)
                barHeight = data.barHeight
            if (typeof data.wallpaperDir === "string" && data.wallpaperDir !== "")
                wallpaperDir = data.wallpaperDir
        } catch (e) {
            // arquivo ausente ou inválido: mantém defaults
        }
        loading = false
    }

    function save() {
        file.setText(JSON.stringify({
            barPosition: barPosition,
            barHeight: barHeight,
            wallpaperDir: wallpaperDir
        }, null, 2) + "\n")
    }
}
