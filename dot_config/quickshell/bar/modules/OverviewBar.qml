import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Mpris
import qs.services

// Barra que só existe durante o overview do niri. exclusionMode/exclusiveZone
// zero para não empurrar layout; focusable false para não roubar setas/Enter.
PanelWindow {
    id: root

    anchors {
        top: true
        left: true
        right: true
    }

    implicitHeight: Theme.barHeight
    exclusiveZone: 0
    exclusionMode: ExclusionMode.Ignore
    focusable: false
    visible: NiriService.overviewOpen
    color: Theme.bg

    WlrLayershell.namespace: "quickshell-overview"
    WlrLayershell.layer: WlrLayer.Top

    readonly property var orderedWorkspaces: NiriService.wsList.slice().sort((a, b) => a.idx - b.idx)
    readonly property var focusedWorkspace: {
        for (const w of orderedWorkspaces)
            if (w.is_focused)
                return w
        return null
    }
    readonly property var focusedWindows: focusedWorkspace ? NiriService.winList.filter(w => w.workspace_id === focusedWorkspace.id) : []

    readonly property var player: {
        const list = Mpris.players.values
        for (const p of list)
            if (p.isPlaying)
                return p
        return list.length > 0 ? list[0] : null
    }

    Row {
        id: left
        anchors.left: parent.left
        anchors.leftMargin: Theme.pad
        anchors.verticalCenter: parent.verticalCenter
        spacing: 6

        Repeater {
            model: root.orderedWorkspaces

            Item {
                required property var modelData

                width: pill.width + 6
                height: Theme.barHeight

                Row {
                    id: pill
                    anchors.centerIn: parent
                    spacing: 4

                    Rectangle {
                        width: 8
                        height: 8
                        anchors.verticalCenter: parent.verticalCenter
                        color: modelData.is_focused ? Theme.fg : (modelData.is_active ? Theme.accent : "transparent")
                        border.width: modelData.is_focused || modelData.is_active ? 0 : 1
                        border.color: Theme.faint
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: NiriService.windowCount(modelData.id)
                        visible: NiriService.windowCount(modelData.id) > 0
                        color: Theme.dim
                        font.family: Theme.fontFamily
                        font.pixelSize: 11
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: NiriService.focusWorkspace(modelData.id)
                }
            }
        }

        Item {
            width: 1
            height: root.height

            Rectangle {
                anchors.centerIn: parent
                width: 1
                height: 14
                color: Theme.line
            }
        }

        Repeater {
            model: root.focusedWindows.slice(0, 3)

            Item {
                required property var modelData

                width: Math.min(windowTitle.implicitWidth + 18, 170)
                height: root.height

                Row {
                    anchors.centerIn: parent
                    spacing: 5

                    Rectangle {
                        width: 5
                        height: 5
                        anchors.verticalCenter: parent.verticalCenter
                        color: modelData.is_focused ? Theme.accent : Theme.faint
                    }

                    Text {
                        id: windowTitle
                        anchors.verticalCenter: parent.verticalCenter
                        width: Math.min(implicitWidth, 140)
                        text: modelData.title || modelData.app_id || "janela"
                        elide: Text.ElideRight
                        color: modelData.is_focused ? Theme.fg : Theme.dim
                        font.family: Theme.fontFamily
                        font.pixelSize: 11
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    onEntered: Tooltip.show(modelData.title || modelData.app_id || "janela", windowTitle.parent.parent)
                    onExited: Tooltip.hide()
                    onClicked: NiriService.focusWindow(modelData.id)
                }
            }
        }
    }

    Row {
        anchors.right: parent.right
        anchors.rightMargin: Theme.pad
        anchors.verticalCenter: parent.verticalCenter
        spacing: 14

        Text {
            text: "cpu " + Math.round(Sys.cpu) + "% · " + Math.round(Sys.temp) + "°"
            color: Theme.dim
            font.family: Theme.fontFamily
            font.pixelSize: 11
        }

        Text {
            visible: Power.bat !== null
            text: Math.round(Power.pct) + "%"
            color: Theme.dim
            font.family: Theme.fontFamily
            font.pixelSize: 11
        }

        Text {
            visible: Weather.ready
            text: Weather.icon + " " + Weather.tempC + "°"
            color: Theme.fg
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
        }

        Text {
            visible: root.player !== null
            width: Math.min(implicitWidth, 260)
            text: (root.player && root.player.isPlaying ? "\uf001 " : "\uf04c ") + (root.player?.trackTitle ?? "")
            elide: Text.ElideRight
            color: Theme.fg
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: NiriService.keyboardLayout
            color: Theme.fg
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
        }

        Text {
            id: clock
            anchors.verticalCenter: parent.verticalCenter
            color: Theme.fg
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
            text: Qt.formatDateTime(new Date(), "ddd dd · HH:mm")

            Timer {
                interval: 1000
                running: true
                repeat: true
                onTriggered: clock.text = Qt.formatDateTime(new Date(), "ddd dd · HH:mm")
            }
        }
    }
}
