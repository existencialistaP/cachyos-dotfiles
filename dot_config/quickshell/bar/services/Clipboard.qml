pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property var entries: []
    property string query: ""

    readonly property var filtered: entries.filter(entry => {
        if (root.query === "")
            return true
        return entry.preview.toLowerCase().indexOf(root.query.toLowerCase()) >= 0
    }).slice(0, 8)

    Process {
        id: listProc
        command: ["cliphist", "list"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim() === "" ? [] : text.trim().split("\n")
                root.entries = lines.map(line => {
                    const idx = line.indexOf("\t")
                    const id = idx >= 0 ? line.substring(0, idx) : line
                    const preview = idx >= 0 ? line.substring(idx + 1) : ""
                    return {
                        id: id,
                        preview: preview.length > 140 ? preview.substring(0, 140) + "…" : preview
                    }
                })
            }
        }
    }

    Process {
        id: copyProc
        command: []
        stdout: StdioCollector {}
    }

    Process {
        id: wipeProc
        command: ["cliphist", "wipe"]
        stdout: StdioCollector {}
        onExited: root.refresh()
    }

    Timer {
        interval: 10000
        running: true
        repeat: true
        onTriggered: root.refresh()
    }

    function refresh() {
        listProc.running = true
    }

    function copy(id) {
        copyProc.command = ["sh", "-c", "cliphist decode " + id + " | wl-copy"]
        copyProc.running = true
        Ui.close()
    }

    function wipe() {
        wipeProc.running = true
    }
}
