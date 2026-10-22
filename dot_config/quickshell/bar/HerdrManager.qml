import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.components
import qs.services

// Gerenciador de agentes do Herdr: lista workspaces/tabs/agentes do snapshot,
// foca o pane escolhido, abre o cliente Herdr e inicia agentes novos.
PanelWindow {
    id: root

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    visible: Ui.active === "herdr"
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    focusable: true

    WlrLayershell.namespace: "quickshell-herdr"
    WlrLayershell.layer: WlrLayer.Overlay

    property string filter: ""
    property int selected: 0

    readonly property var filtered: {
        const query = filter.toLowerCase()
        return HerdrService.agents.filter(agent => {
            if (query === "")
                return true
            const haystack = (agent.agent + " " + HerdrService.agentTitle(agent) + " " + (agent.cwd ?? "") + " "
                + (agent.pane_id ?? "") + " " + HerdrService.workspaceName(agent.workspace_id)).toLowerCase()
            return haystack.indexOf(query) >= 0
        })
    }

    function stateColor(state) {
        if (state === "blocked")
            return Theme.error
        if (state === "working")
            return Theme.accent
        if (state === "idle")
            return Theme.faint
        return Theme.faint
    }

    function select(delta) {
        if (filtered.length === 0)
            return
        selected = Math.max(0, Math.min(filtered.length - 1, selected + delta))
        list.positionViewAtIndex(selected, ListView.Contain)
    }

    function openSelected() {
        const agent = filtered[selected]
        if (!agent)
            return
        Ui.close()
        HerdrService.focusAgent(agent)
    }

    onVisibleChanged: {
        if (visible) {
            filter = ""
            selected = 0
            HerdrService.refresh()
            Qt.callLater(() => filterInput.forceActiveFocus())
        }
    }

    Connections {
        target: HerdrService

        function onStarted() {
            Ui.close()
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: Ui.close()
    }

    Rectangle {
        width: 580
        height: 480
        x: (root.width - width) / 2
        y: Settings.barPosition === "bottom" ? root.height - Settings.barHeight - height : Settings.barHeight
        color: Theme.bg
        border.width: 1
        border.color: Theme.line

        MouseArea {
            anchors.fill: parent
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 6

            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 24

                Text {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Herdr"
                    color: Theme.fg
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize
                    font.bold: true
                }

                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: 48
                    anchors.verticalCenter: parent.verticalCenter
                    text: HerdrService.agentCount + " agentes · " + HerdrService.workspaces.length + " workspaces"
                    color: Theme.dim
                    font.family: Theme.fontFamily
                    font.pixelSize: 11
                }

                ActionButton {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    label: "abrir herdr"

                    onClicked: {
                        Ui.close()
                        HerdrService.openHerdr()
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                color: Theme.line
            }

            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 26

                TextInput {
                    id: filterInput
                    anchors.fill: parent
                    verticalAlignment: TextInput.AlignVCenter
                    color: Theme.fg
                    font.family: Theme.fontFamily
                    font.pixelSize: 13
                    selectByMouse: true
                    clip: true

                    onTextChanged: {
                        root.filter = text
                        root.selected = 0
                    }

                    Keys.onEscapePressed: Ui.close()
                    Keys.onDownPressed: root.select(1)
                    Keys.onUpPressed: root.select(-1)
                    Keys.onReturnPressed: root.openSelected()
                    Keys.onEnterPressed: root.openSelected()
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: filterInput.text === ""
                    text: "filtrar por agente, título, pane…"
                    color: Theme.faint
                    font.family: Theme.fontFamily
                    font.pixelSize: 13
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                color: Theme.line
            }

            ListView {
                id: list
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                spacing: 1
                model: root.filtered

                delegate: Item {
                    required property var modelData
                    required property int index

                    width: list.width
                    height: 44

                    Rectangle {
                        anchors.fill: parent
                        color: root.selected === index ? Theme.hover : "transparent"
                    }

                    Rectangle {
                        x: 2
                        anchors.verticalCenter: parent.verticalCenter
                        width: 7
                        height: 7
                        radius: 4
                        color: root.stateColor(modelData.agent_status)
                    }

                    Column {
                        x: 16
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - 190
                        spacing: 1

                        Text {
                            width: parent.width
                            text: modelData.agent + (modelData.focused ? "  · focado" : "")
                            elide: Text.ElideRight
                            color: Theme.fg
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSize
                            font.bold: modelData.focused
                        }

                        Text {
                            width: parent.width
                            text: HerdrService.agentTitle(modelData)
                            elide: Text.ElideRight
                            color: Theme.dim
                            font.family: Theme.fontFamily
                            font.pixelSize: 10
                        }
                    }

                    Text {
                        anchors.right: parent.right
                        anchors.rightMargin: 2
                        anchors.verticalCenter: parent.verticalCenter
                        text: HerdrService.workspaceName(modelData.workspace_id) + " · " + (modelData.tab_id ?? "")
                            + " · " + (modelData.pane_id ?? "")
                        color: Theme.faint
                        font.family: Theme.fontFamily
                        font.pixelSize: 10
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor

                        onClicked: {
                            root.selected = index
                            root.openSelected()
                        }
                    }
                }

                Text {
                    anchors.centerIn: parent
                    visible: root.filtered.length === 0
                    text: HerdrService.available ? "nenhum agente" : "herdr indisponível"
                    color: Theme.faint
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                color: Theme.line
            }

            Text {
                Layout.fillWidth: true
                text: HerdrService.starting ? "iniciando " + HerdrService.pendingKind + "…" : "novo agente"
                color: HerdrService.starting ? Theme.dim : Theme.faint
                font.family: Theme.fontFamily
                font.pixelSize: 11
            }

            Flow {
                Layout.fillWidth: true
                Layout.preferredHeight: implicitHeight
                spacing: 4

                Repeater {
                    model: HerdrService.kinds

                    delegate: Rectangle {
                        required property string modelData

                        width: chipText.implicitWidth + 12
                        height: 20
                        color: chipHover.containsMouse && !HerdrService.starting ? Theme.hover : "transparent"
                        border.width: 1
                        border.color: Theme.line

                        Text {
                            id: chipText
                            anchors.centerIn: parent
                            text: modelData
                            color: HerdrService.starting ? Theme.faint : Theme.fg
                            font.family: Theme.fontFamily
                            font.pixelSize: 10
                        }

                        MouseArea {
                            id: chipHover
                            anchors.fill: parent
                            hoverEnabled: true
                            enabled: !HerdrService.starting
                            cursorShape: HerdrService.starting ? Qt.ArrowCursor : Qt.PointingHandCursor
                            onClicked: HerdrService.startAgent(modelData)
                        }
                    }
                }
            }

            Text {
                Layout.fillWidth: true
                visible: HerdrService.error !== ""
                text: HerdrService.error
                elide: Text.ElideRight
                color: Theme.error
                font.family: Theme.fontFamily
                font.pixelSize: 10
            }
        }
    }
}
