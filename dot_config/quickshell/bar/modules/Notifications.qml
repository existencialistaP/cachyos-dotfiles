import QtQuick
import Quickshell
import Quickshell.Io
import qs.components
import qs.services

Item {
    id: root

    property bool dnd: false
    property var active: []
    property var history: []

    readonly property var entries: {
        const out = []
        const seenIds = []
        const seenContent = []
        const keyOf = n => (n.app_name || "") + "|" + (n.summary || "") + "|" + (n.body || "")
        for (const n of active) {
            out.push(n)
            seenIds.push(n.id)
            seenContent.push(keyOf(n))
        }
        for (const n of history) {
            if (seenIds.indexOf(n.id) >= 0)
                continue
            const key = keyOf(n)
            if (seenContent.indexOf(key) >= 0)
                continue
            seenContent.push(key)
            out.push(n)
        }
        out.sort((a, b) => b.id - a.id)
        return out.slice(0, 8)
    }

    implicitWidth: item.implicitWidth
    implicitHeight: Theme.barHeight

    function parse(text) {
        try {
            const value = JSON.parse(text)
            return Array.isArray(value) ? value : []
        } catch (e) {
            return []
        }
    }

    function refresh() {
        listProc.running = true
        historyProc.running = true
        modeProc.running = true
    }

    function dismiss(id) {
        actionProc.command = ["makoctl", "dismiss", "-n", String(id)]
        actionProc.running = true
    }

    Process {
        id: listProc
        command: ["makoctl", "list", "-j"]
        stdout: StdioCollector {
            onStreamFinished: root.active = root.parse(text)
        }
    }

    Process {
        id: historyProc
        command: ["makoctl", "history", "-j"]
        stdout: StdioCollector {
            onStreamFinished: root.history = root.parse(text)
        }
    }

    Process {
        id: modeProc
        command: ["makoctl", "mode"]
        stdout: StdioCollector {
            onStreamFinished: root.dnd = text.split("\n").some(line => line.trim() === "do-not-disturb")
        }
    }

    Process {
        id: actionProc
        command: []
        stdout: StdioCollector {}
        onExited: root.refresh()
    }

    Timer {
        interval: 4000
        running: true
        repeat: true
        onTriggered: root.refresh()
    }

    BarItem {
        id: item
        text: root.dnd ? "\uf1f6" : "\uf0f3"
        tooltip: root.dnd ? "Notificações · não perturbe" : "Notificações"
        active: root.dnd
        onClicked: Ui.toggle("notifications")
    }

    Popover {
        key: "notifications"
        trigger: item

        content: Component {
            Card {
                title: "Notificações"

                Item {
                    width: parent.width
                    implicitHeight: 26

                    Text {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Não perturbe"
                        color: Theme.fg
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize
                    }

                    Toggle {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        checked: root.dnd
                        onToggled: {
                            actionProc.command = ["makoctl", "mode", "-t", "do-not-disturb"]
                            actionProc.running = true
                        }
                    }
                }

                Rectangle {
                    width: parent.width
                    height: 1
                    color: Theme.line
                }

                Repeater {
                    model: root.entries

                    Item {
                        required property var modelData

                        width: parent.width
                        implicitHeight: Math.max(42, body.implicitHeight + 14)

                        Column {
                            id: body
                            width: parent.width - 20
                            spacing: 2

                            Text {
                                width: parent.width
                                text: (modelData.app_name || "app") + (modelData.summary ? " · " + modelData.summary : "")
                                elide: Text.ElideRight
                                color: Theme.fg
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSize
                                font.bold: true
                            }

                            Text {
                                visible: (modelData.body ?? "") !== ""
                                width: parent.width
                                text: modelData.body ?? ""
                                wrapMode: Text.Wrap
                                maximumLineCount: 2
                                elide: Text.ElideRight
                                color: Theme.dim
                                font.family: Theme.fontFamily
                                font.pixelSize: 11
                            }
                        }

                        Text {
                            visible: root.active.some(n => n.id === modelData.id)
                            anchors.right: parent.right
                            anchors.top: parent.top
                            text: "×"
                            color: Theme.dim
                            font.family: Theme.fontFamily
                            font.pixelSize: 16
                            MouseArea {
                                anchors.fill: parent
                                anchors.margins: -6
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.dismiss(modelData.id)
                            }
                        }
                    }
                }

                Text {
                    visible: root.entries.length === 0
                    text: "sem notificações"
                    color: Theme.faint
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize
                }

                Row {
                    spacing: 6

                    ActionButton {
                        label: "limpar todas"
                        visible: root.active.length > 0
                        onClicked: {
                            actionProc.command = ["makoctl", "dismiss", "-a"]
                            actionProc.running = true
                        }
                    }

                    ActionButton {
                        label: "restaurar última"
                        visible: root.history.length > 0
                        onClicked: {
                            actionProc.command = ["makoctl", "restore"]
                            actionProc.running = true
                        }
                    }
                }
            }
        }
    }
}
