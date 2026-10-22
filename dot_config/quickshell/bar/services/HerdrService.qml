pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Estado vivo do Herdr via `herdr api snapshot` + ações via CLI.
// O socket padrão (~/.config/herdr) é usado; não precisa de HERDR_ENV.
Singleton {
    id: root

    // kinds aceitos por `herdr agent start --kind`
    readonly property var kinds: [
        "omp", "claude", "codex", "opencode", "gemini", "cursor", "copilot",
        "amp", "droid", "qwen", "pi", "devin", "cline", "grok", "hermes",
        "kimi", "kiro", "kilo", "letta", "maki", "muse", "qodercli",
        "agy", "mastracode"
    ]

    property var agents: []
    property var workspaces: []
    property string focusedWorkspace: ""
    property bool available: false
    property string error: ""
    property bool starting: false
    property string pendingKind: ""

    readonly property int agentCount: agents.length
    readonly property bool anyBlocked: agents.some(a => a.agent_status === "blocked")
    readonly property bool anyWorking: agents.some(a => a.agent_status === "working")

    signal started()

    function refresh() {
        if (!snapshotProc.running)
            snapshotProc.running = true
    }

    function applySnapshot(text) {
        try {
            const payload = JSON.parse(text)
            const snap = payload && payload.result && payload.result.snapshot
            if (!snap)
                throw new Error("snapshot ausente")
            const list = (snap.agents ?? []).slice()
            list.sort((a, b) => {
                if (a.focused !== b.focused)
                    return a.focused ? -1 : 1
                if (a.workspace_id !== b.workspace_id)
                    return String(a.workspace_id).localeCompare(String(b.workspace_id))
                return String(a.pane_id).localeCompare(String(b.pane_id))
            })
            agents = list
            workspaces = snap.workspaces ?? []
            focusedWorkspace = snap.focused_workspace_id ?? ""
            available = true
            error = ""
        } catch (e) {
            available = false
            error = "herdr: " + e.message
        }
    }

    function workspaceName(id) {
        const ws = workspaces.find(w => w.workspace_id === id)
        if (ws && ws.name)
            return ws.name
        return id
    }

    function agentTitle(agent) {
        const title = agent.terminal_title_stripped || agent.terminal_title || ""
        if (title !== "")
            return title
        const cwd = agent.foreground_cwd || agent.cwd || ""
        const parts = cwd.split("/").filter(part => part !== "")
        return parts.length > 0 ? parts[parts.length - 1] : agent.agent
    }

    function focusAgent(agent) {
        if (!agent)
            return
        run(["herdr", "agent", "focus", agent.pane_id])
        reveal()
    }

    function openHerdr() {
        reveal()
    }

    function startAgent(kind) {
        if (starting)
            return
        starting = true
        pendingKind = kind
        error = ""
        if (focusedWorkspace !== "")
            createProc.command = ["herdr", "tab", "create", "--workspace", focusedWorkspace, "--focus"]
        else
            createProc.command = ["herdr", "tab", "create", "--focus"]
        createProc.running = true
    }

    function continueStart(text) {
        try {
            const result = JSON.parse(text).result
            const pane = result.root_pane.pane_id
            startProc.command = ["herdr", "agent", "start", nextName(pendingKind), "--kind", pendingKind, "--pane", pane]
            startProc.running = true
        } catch (e) {
            starting = false
            error = "novo agente: " + e.message
            refreshTimer.restart()
        }
    }

    function nextName(kind) {
        const names = agents.map(agent => agent.agent)
        if (names.indexOf(kind) < 0)
            return kind
        let index = 2
        while (names.indexOf(kind + "-" + index) >= 0)
            index++
        return kind + "-" + index
    }

    // Foca a janela do cliente Herdr (kitty titulada "herdr"); se não existir,
    // abre um cliente novo. A ordem focus no pane → levantar janela importa:
    // o pane focado é o que aparece quando o cliente ganha foco.
    function reveal() {
        if (!niriProc.running)
            niriProc.running = true
    }

    function pickWindow(text) {
        try {
            const windows = JSON.parse(text)
            const win = windows.find(w => String(w.title ?? "").toLowerCase().indexOf("herdr") >= 0)
            if (win) {
                run(["niri", "msg", "action", "focus-window", "--id", String(win.id)])
                return
            }
        } catch (e) {
            // sem niri (ou saída vazia): cai no spawn
        }
        spawnHerdr()
    }

    property bool spawnPending: false

    function spawnHerdr() {
        if (spawnPending)
            return
        spawnPending = true
        // O quickshell pode herdar HERDR_* quando iniciado de dentro de um pane;
        // um cliente aninhado herdaria esse estado. Limpa antes de abrir.
        Quickshell.execDetached(["sh", "-c",
            "unset HERDR_ENV HERDR_SOCKET_PATH HERDR_PANE_ID HERDR_WORKSPACE_ID HERDR_TAB_ID; exec kitty --title herdr -e herdr"])
        spawnTimer.restart()
    }

    property var queue: []

    function run(args) {
        queue.push(args)
        pump()
    }

    function pump() {
        if (actionProc.running || queue.length === 0)
            return
        actionProc.command = queue.shift()
        actionProc.running = true
    }

    Process {
        id: snapshotProc
        command: ["herdr", "api", "snapshot"]
        stdout: StdioCollector {
            onStreamFinished: root.applySnapshot(text)
        }
        stderr: StdioCollector {
            onStreamFinished: if (text.trim() !== "") root.error = text.trim()
        }
        onExited: code => {
            if (code !== 0)
                root.available = false
        }
    }

    Process {
        id: actionProc
        stdout: StdioCollector {}
        stderr: StdioCollector {
            onStreamFinished: if (text.trim() !== "") root.error = text.trim()
        }
        onExited: {
            root.pump()
            refreshTimer.restart()
        }
    }

    Process {
        id: createProc
        stdout: StdioCollector {
            onStreamFinished: root.continueStart(text)
        }
        stderr: StdioCollector {
            onStreamFinished: if (text.trim() !== "") {
                root.error = text.trim()
                root.starting = false
            }
        }
        onExited: code => {
            if (code !== 0) {
                root.starting = false
                refreshTimer.restart()
            }
        }
    }

    Process {
        id: startProc
        stdout: StdioCollector {}
        stderr: StdioCollector {
            onStreamFinished: if (text.trim() !== "") root.error = text.trim()
        }
        onExited: code => {
            root.starting = false
            if (code === 0) {
                root.started()
                root.reveal()
            }
            refreshTimer.restart()
        }
    }

    Process {
        id: niriProc
        command: ["niri", "msg", "--json", "windows"]
        stdout: StdioCollector {
            onStreamFinished: root.pickWindow(text)
        }
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        onTriggered: root.refresh()
    }

    Timer {
        id: refreshTimer
        interval: 300
        onTriggered: root.refresh()
    }

    Timer {
        id: spawnTimer
        interval: 1500
        onTriggered: root.spawnPending = false
    }

    Component.onCompleted: refresh()
}
