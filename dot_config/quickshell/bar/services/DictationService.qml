pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Ditado offline: parec grava PCM cru, o parakeet do Orca transcreve via
// sherpa-onnx (uv resolve a dependência do script) e o wtype digita no foco.
Singleton {
    id: root

    readonly property string home: Quickshell.env("HOME")
    readonly property string rawPath: Quickshell.env("XDG_RUNTIME_DIR") + "/quickshell-dictation.raw"
    readonly property string scriptPath: root.home + "/.config/quickshell/bar/scripts/transcribe.py"
    readonly property string modelPath: root.home + "/.config/orca/speech-models/parakeet-tdt-0.6b-v3-int8"

    // idle | recording | transcribing | error
    property string state: "idle"
    property string transcript: ""
    property string error: ""
    property int elapsed: 0
    property real startedAt: 0
    property string stderrText: ""
    property bool canType: false
    property bool cancelling: false

    readonly property bool recording: state === "recording"
    readonly property bool transcribing: state === "transcribing"
    readonly property bool busy: recording || transcribing

    signal finished(string text)

    function start() {
        if (busy)
            return
        cancelling = false
        transcript = ""
        error = ""
        stderrText = ""
        elapsed = 0
        startedAt = Date.now()
        state = "recording"
        elapsedTimer.start()
        whichProc.running = true
        recorder.running = true
    }

    function stop() {
        if (state === "recording") {
            state = "transcribing"
            elapsedTimer.stop()
            recorder.signal(15)
            stopFallback.restart()
        } else if (state === "transcribing") {
            cancelling = true
            transcribeProc.running = false
            state = "idle"
        }
    }

    function toggle() {
        if (busy)
            stop()
        else
            start()
    }

    function reset() {
        if (busy)
            return
        transcript = ""
        error = ""
        state = "idle"
    }

    function copy() {
        if (transcript === "")
            return
        copyProc.command = ["sh", "-c", "printf %s \"$1\" | wl-copy", "sh", transcript]
        copyProc.running = true
    }

    function deliver() {
        if (transcript.trim() === "")
            return
        Ui.close() // um card focado roubaria o teclado do app alvo
        typeDelay.restart()
    }

    // `exec` troca o shell pelo parec: o SIGTERM chega no processo certo.
    Process {
        id: recorder
        command: ["sh", "-c", "exec parec --format=s16le --rate=16000 --channels=1 --latency-msec=20 > \"$1\"", "sh", root.rawPath]
        onExited: code => {
            stopFallback.stop()
            if (root.state === "transcribing") {
                transcribeProc.running = true
                return
            }
            if (root.state === "recording") {
                root.elapsedTimer.stop()
                root.state = "error"
                root.error = code === 0 ? "gravação encerrou" : "parec falhou (código " + code + ")"
            }
        }
    }

    Process {
        id: transcribeProc
        command: ["uv", "run", "--quiet", root.scriptPath, "--model", root.modelPath, "--raw", root.rawPath]
        stdout: StdioCollector {
            onStreamFinished: root.transcript = text.trim()
        }
        stderr: StdioCollector {
            onStreamFinished: root.stderrText = text.trim()
        }
        onExited: code => {
            stopFallback.stop()
            if (root.cancelling) {
                root.cancelling = false
                root.state = "idle"
                return
            }
            if (code !== 0) {
                root.state = "error"
                root.error = root.stderrText !== "" ? root.stderrText : "transcrição falhou (código " + code + ")"
                Ui.open("dictation")
                return
            }
            root.state = "idle"
            root.deliver()
        }
    }

    Process {
        id: typeProc
        command: []
        stderr: StdioCollector {
            onStreamFinished: if (text.trim() !== "") root.error = text.trim()
        }
        onExited: code => {
            if (code !== 0) {
                root.copy()
                root.error = "wtype falhou; texto copiado"
            }
            root.finished(root.transcript)
        }
    }

    Process {
        id: copyProc
        command: []
        stdout: StdioCollector {}
    }

    Process {
        id: whichProc
        command: ["sh", "-c", "command -v wtype"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: root.canType = text.trim() !== ""
        }
    }

    Timer {
        id: elapsedTimer
        interval: 200
        repeat: true
        onTriggered: root.elapsed = Math.floor((Date.now() - root.startedAt) / 1000)
    }

    Timer {
        id: stopFallback
        interval: 5000
        onTriggered: {
            if (root.state === "transcribing") {
                root.state = "error"
                root.error = "gravação não encerrou"
                recorder.running = false
            }
        }
    }

    Timer {
        id: typeDelay
        interval: 120
        onTriggered: {
            if (root.canType) {
                typeProc.command = ["wtype", "--", root.transcript]
                typeProc.running = true
            } else {
                root.copy()
                root.error = "wtype ausente; texto copiado"
                Ui.open("dictation")
                root.finished(root.transcript)
            }
        }
    }
}
