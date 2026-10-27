import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import qs.components
import qs.services

PanelWindow {
    id: root

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    visible: Wallpapers.open
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    focusable: true

    WlrLayershell.namespace: "quickshell-wallpapers"
    WlrLayershell.layer: WlrLayer.Overlay

    property var images: []


    Process {
        id: findProc
        command: ["sh", "-c", "find '" + Settings.wallpaperDir + "' -maxdepth 1 -type f \\( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' -o -iname '*.gif' \\) | sort"]
        stdout: StdioCollector {
            onStreamFinished: {
                const t = text.trim()
                root.images = t === "" ? [] : t.split("\n")
            }
        }
    }

    onVisibleChanged: {
        if (visible) {
            findProc.running = true
            Qt.callLater(() => keyCatcher.forceActiveFocus())
        }
    }

    Item {
        id: keyCatcher
        anchors.fill: parent
        focus: true
        Keys.onEscapePressed: Wallpapers.close()
    }

    MouseArea {
        anchors.fill: parent
        onClicked: Wallpapers.close()
    }

    Rectangle {
        width: 760
        height: 540
        x: (root.width - width) / 2
        y: Settings.barPosition === "bottom" ? root.height - Settings.barHeight - height : Settings.barHeight
        color: Theme.bg

        MouseArea {
            anchors.fill: parent
        }

        Column {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 8

            Row {
                width: parent.width

                Text {
                    text: "Wallpapers"
                    color: Theme.fg
                    font.family: Theme.fontFamily
                    font.pixelSize: 14
                    font.bold: true
                }

                Item {
                    width: parent.width - 130
                    height: 1
                }

                Text {
                    text: "Esc fecha"
                    color: Theme.faint
                    font.family: Theme.fontFamily
                    font.pixelSize: 11
                }
            }

            Rectangle {
                width: parent.width
                height: 1
                color: Theme.line
            }

            GridView {
                id: grid
                width: parent.width
                height: parent.height - 45
                cellWidth: Math.floor(width / 3)
                cellHeight: Math.floor(cellWidth * 9 / 16)
                clip: true

                model: root.images

                delegate: Item {
                    required property var modelData

                    width: grid.cellWidth
                    height: grid.cellHeight

                    Image {
                        anchors.fill: parent
                        source: modelData
                        sourceSize.width: grid.cellWidth
                        sourceSize.height: grid.cellHeight
                        asynchronous: true
                        fillMode: Image.PreserveAspectCrop
                        clip: true
                    }

                    Rectangle {
                        anchors.fill: parent
                        color: "transparent"
                        border.width: 1
                        border.color: Theme.fg
                        visible: hover.containsMouse
                    }

                    MouseArea {
                        id: hover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Wallpapers.apply(modelData)
                    }
                }
            }
        }
    }
}
