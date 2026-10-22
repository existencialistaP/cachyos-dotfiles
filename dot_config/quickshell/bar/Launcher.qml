import QtQuick
import Quickshell
import Quickshell.Wayland
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

    visible: LauncherService.open
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    focusable: true

    WlrLayershell.namespace: "quickshell-launcher"
    WlrLayershell.layer: WlrLayer.Overlay

    property string query: ""
    property int selected: 0

    readonly property var filtered: {
        const q = root.query.toLowerCase()
        const list = DesktopEntries.applications.values.filter(entry => {
            if (entry.noDisplay)
                return false
            const haystack = (entry.name + " " + entry.genericName + " " + entry.comment + " " + entry.keywords).toLowerCase()
            return q === "" || haystack.indexOf(q) >= 0
        })
        list.sort((a, b) => a.name.localeCompare(b.name))
        return list
    }

    function launch(entry) {
        if (!entry)
            return
        entry.execute()
        LauncherService.close()
    }

    onVisibleChanged: {
        if (visible) {
            query = ""
            selected = 0
            Qt.callLater(() => input.forceActiveFocus())
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: LauncherService.close()
    }

    Rectangle {
        width: 440
        height: 340
        x: (root.width - width) / 2
        y: Settings.barPosition === "bottom" ? root.height - Settings.barHeight - height : Settings.barHeight
        color: Theme.bg

        MouseArea {
            anchors.fill: parent
        }

        Column {
            anchors.fill: parent
            anchors.margins: 10
            spacing: 8

            Item {
                width: parent.width
                implicitHeight: 28

                TextInput {
                    id: input
                    anchors.fill: parent
                    verticalAlignment: TextInput.AlignVCenter
                    color: Theme.fg
                    font.family: Theme.fontFamily
                    font.pixelSize: 13
                    selectByMouse: true
                    focus: true
                    onTextChanged: {
                        root.query = text
                        root.selected = 0
                    }
                    Keys.onEscapePressed: LauncherService.close()
                    Keys.onDownPressed: {
                        root.selected = Math.min(root.selected + 1, Math.max(0, root.filtered.length - 1))
                        list.positionViewAtIndex(root.selected, ListView.Contain)
                    }
                    Keys.onUpPressed: {
                        root.selected = Math.max(root.selected - 1, 0)
                        list.positionViewAtIndex(root.selected, ListView.Contain)
                    }
                    Keys.onReturnPressed: root.launch(root.filtered[root.selected])
                    Keys.onEnterPressed: root.launch(root.filtered[root.selected])
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Buscar aplicativos…"
                    visible: input.text === ""
                    color: Theme.faint
                    font.family: Theme.fontFamily
                    font.pixelSize: 13
                }
            }

            Rectangle {
                width: parent.width
                height: 1
                color: Theme.line
            }

            ListView {
                id: list
                width: parent.width
                height: parent.height - 44
                model: root.filtered
                clip: true
                spacing: 1

                delegate: Item {
                    required property var modelData
                    required property int index

                    width: list.width
                    height: 38

                    Rectangle {
                        anchors.fill: parent
                        color: root.selected === index ? Theme.hover : "transparent"
                    }

                    Image {
                        x: 8
                        anchors.verticalCenter: parent.verticalCenter
                        width: 20
                        height: 20
                        source: Quickshell.iconPath(modelData.icon !== "" ? modelData.icon : "application-x-executable")
                        sourceSize.width: 20
                        sourceSize.height: 20
                    }

                    Column {
                        x: 36
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - 44
                        spacing: 1

                        Text {
                            width: parent.width
                            text: modelData.name
                            elide: Text.ElideRight
                            color: Theme.fg
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSize
                        }

                        Text {
                            width: parent.width
                            text: modelData.comment
                            elide: Text.ElideRight
                            color: Theme.faint
                            font.family: Theme.fontFamily
                            font.pixelSize: 10
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.launch(modelData)
                    }
                }
            }
        }
    }
}
