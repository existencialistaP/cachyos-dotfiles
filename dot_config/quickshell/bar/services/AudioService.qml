pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire

Singleton {
    id: root

    property int volume: 0
    property bool muted: false
    property double lastSet: 0
    property bool pendingOsd: false

    readonly property var sink: Pipewire.defaultAudioSink

    readonly property var sinks: {
        const list = Pipewire.nodes.values.filter(n => n.isSink && !n.isStream)
        const out = []
        const seen = []
        for (const node of list) {
            const desc = node.description || node.nickname || node.name
            const isCurrent = root.sink && node.id === root.sink.id
            if (!isCurrent && desc.indexOf("HDMI") >= 0)
                continue
            if (seen.indexOf(desc) >= 0)
                continue
            seen.push(desc)
            out.push(node)
        }
        out.sort((a, b) => (a.description || "").localeCompare(b.description || ""))
        return out
    }

    readonly property var streams: {
        const list = Pipewire.nodes.values.filter(n => {
            const cls = String(n.properties["media.class"] ?? "")
            const app = String(n.properties["application.name"] ?? "")
            if (app === "" || app.indexOf("speech-dispatcher") >= 0)
                return false
            return n.isStream && !n.isSink && cls.indexOf("Stream/Output/Audio") >= 0
        })
        list.sort((a, b) => root.streamName(a).localeCompare(root.streamName(b)))
        return list
    }

    function streamName(node) {
        return String(node.properties["application.name"] ?? node.description ?? node.name)
    }

    Process {
        id: readProc
        command: ["wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: root.parse(text)
        }
    }

    Process {
        id: actionProc
        stdout: StdioCollector {}
        onExited: readProc.running = true
    }

    Process {
        id: streamProc
        stdout: StdioCollector {}
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        onTriggered: readProc.running = true
    }

    function parse(output) {
        root.muted = output.indexOf("[MUTED]") >= 0
        if (Date.now() - root.lastSet < 600)
            return
        const match = output.match(/Volume:\s+([0-9.]+)/)
        if (match)
            root.volume = Math.round(parseFloat(match[1]) * 100)
        if (root.pendingOsd) {
            root.pendingOsd = false
            Osd.show("volume", root.volume / 100)
        }
    }

    function setVolume(value, showOsd) {
        root.volume = Math.max(0, Math.min(100, Math.round(value)))
        root.lastSet = Date.now()
        actionProc.command = ["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", (root.volume / 100).toFixed(2)]
        actionProc.running = true
        if (showOsd !== false)
            Osd.show("volume", root.volume / 100)
    }

    function step(delta) {
        // relativo no wpctl: não depende da leitura inicial ter chegado
        root.pendingOsd = true
        root.lastSet = 0
        actionProc.command = ["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", Math.abs(delta) + "%" + (delta >= 0 ? "+" : "-")]
        actionProc.running = true
    }

    function toggleMute() {
        root.muted = !root.muted
        actionProc.command = ["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "toggle"]
        actionProc.running = true
        Osd.show("mute", root.muted ? 0 : 1, root.muted ? "mudo" : "som")
    }

    function setStreamVolume(node, value) {
        streamProc.command = ["wpctl", "set-volume", String(node.id), (Math.max(0, Math.min(1, value))).toFixed(2)]
        streamProc.running = true
    }

    function toggleStreamMute(node) {
        streamProc.command = ["wpctl", "set-mute", String(node.id), "toggle"]
        streamProc.running = true
    }

    function setDefaultSink(node) {
        actionProc.command = ["wpctl", "set-default", String(node.id)]
        actionProc.running = true
    }
}
