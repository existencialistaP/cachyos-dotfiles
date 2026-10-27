pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property real cpu: 0
    property real memUsed: 0
    property real memTotal: 0
    property real temp: 0
    property string tempPath: ""
    property var top: []
    property int failedUnits: 0
    property var failedList: []

    // niri-screenshare.service falha de forma benigna neste setup; não é acionável.
    readonly property var ignoredUnits: ["niri-screenshare.service"]

    property real _lastTotal: 0
    property real _lastIdle: 0

    readonly property real memPct: memTotal > 0 ? memUsed / memTotal : 0

    FileView {
        id: statFile
        path: "/proc/stat"
        watchChanges: true
        onTextChanged: root.readCpu()
    }

    FileView {
        id: memFile
        path: "/proc/meminfo"
        watchChanges: true
        onTextChanged: root.readMem()
    }

    FileView {
        id: tempFile
        path: root.tempPath
        watchChanges: true
        onTextChanged: root.readTemp()
    }

    // coretemp/thermal_zone numbering muda entre boots: resolve o TCPU uma vez
    Process {
        id: findTemp
        command: ["sh", "-c", "for z in /sys/class/thermal/thermal_zone*; do if [ \"$(cat $z/type 2>/dev/null)\" = TCPU ]; then echo $z/temp; exit 0; fi; done; echo /sys/class/thermal/thermal_zone1/temp"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: root.tempPath = text.trim()
        }
    }

    Process {
        id: topProc
        command: ["ps", "-eo", "pcpu,pmem,comm", "--sort=-pcpu", "--no-headers"]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().split("\n").slice(0, 6)
                root.top = lines.map(line => {
                    const parts = line.trim().split(/\s+/)
                    return {
                        cpu: parts[0],
                        mem: parts[1],
                        name: parts.slice(2).join(" ")
                    }
                })
            }
        }
    }

    Process {
        id: failedProc
        command: ["systemctl", "--user", "--failed", "--no-legend", "--plain"]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim() === "" ? [] : text.trim().split("\n")
                const units = lines
                    .map(line => (line.trim().split(/\s+/)[1] ?? ""))
                    .filter(unit => unit !== "" && !root.ignoredUnits.includes(unit))
                root.failedList = units
                root.failedUnits = units.length
            }
        }
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        onTriggered: {
            statFile.reload()
            memFile.reload()
            if (root.tempPath !== "")
                tempFile.reload()
        }
    }

    Timer {
        interval: 5000
        running: true
        repeat: true
        onTriggered: topProc.running = true
    }

    Timer {
        interval: 30000
        running: true
        repeat: true
        onTriggered: failedProc.running = true
    }

    function refreshFailed() {
        failedProc.running = true
    }

    function readCpu() {
        const line = statFile.text().split("\n")[0]
        const values = line.trim().split(/\s+/).slice(1).map(Number)
        if (values.length < 4)
            return
        const idle = values[3] + (values[4] ?? 0)
        const total = values.reduce((a, b) => a + b, 0)
        if (_lastTotal > 0 && total > _lastTotal)
            cpu = (1 - (idle - _lastIdle) / (total - _lastTotal)) * 100
        _lastTotal = total
        _lastIdle = idle
    }

    function readMem() {
        const t = memFile.text()
        const total = Number((t.match(/MemTotal:\s+(\d+)/) ?? [])[1] ?? 0) / 1048576
        const avail = Number((t.match(/MemAvailable:\s+(\d+)/) ?? [])[1] ?? 0) / 1048576
        memTotal = total
        memUsed = total - avail
    }

    function readTemp() {
        const raw = tempFile.text().trim()
        temp = raw === "" ? 0 : Number(raw) / 1000
    }
}
