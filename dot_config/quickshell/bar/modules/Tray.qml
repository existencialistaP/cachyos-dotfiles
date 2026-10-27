import QtQuick
import Quickshell.Services.SystemTray
import qs.components
import qs.services

Item {
    id: root

    readonly property var items: SystemTray.items.values

    implicitWidth: trigger.implicitWidth
    implicitHeight: Theme.barHeight

    Item {
        id: trigger

        implicitWidth: 26
        implicitHeight: Theme.barHeight

        Rectangle {
            anchors.fill: parent
            color: hover.containsMouse ? Theme.hover : "transparent"
            Behavior on color { CAnim { type: CAnim.FastEffects } }
        }

        Text {
            id: arrow
            anchors.centerIn: parent
            text: "\uf077"
            // fechado aponta para baixo (180°), aberto para cima
            rotation: Ui.active === "tray" ? 0 : 180
            color: Theme.fg
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
            Behavior on rotation {
                Anim { type: Anim.StandardSmall }
            }
        }

        MouseArea {
            id: hover
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onEntered: Tooltip.show("Bandeja", hover.parent)
            onExited: Tooltip.hide()
            onPressed: Tooltip.hide()
            onClicked: Ui.toggle("tray")
        }
    }

    Popover {
        key: "tray"
        trigger: trigger

        content: Component {
            Card {
                title: "Bandeja"

                Repeater {
                    model: SystemTray.items

                    Item {
                        required property var modelData

                        width: parent.width
                        implicitHeight: 26

                        Rectangle {
                            anchors.fill: parent
                            color: hoverRow.containsMouse ? Theme.hover : "transparent"
                            Behavior on color { CAnim { type: CAnim.FastEffects } }
                        }

                        Image {
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            source: modelData.icon
                            sourceSize.width: 14
                            sourceSize.height: 14
                            width: 14
                            height: 14
                        }

                        Text {
                            anchors.left: parent.left
                            anchors.leftMargin: 22
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            text: modelData.title || modelData.id
                            elide: Text.ElideRight
                            color: Theme.fg
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSize
                        }

                        MouseArea {
                            id: hoverRow
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            acceptedButtons: Qt.LeftButton | Qt.RightButton
                            onClicked: mouse => {
                                if (mouse.button === Qt.LeftButton)
                                    modelData.activate()
                                else
                                    modelData.secondaryActivate()
                                Ui.close()
                            }
                        }
                    }
                }

                Text {
                    visible: root.items.length === 0
                    text: "nenhum item"
                    color: Theme.faint
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize
                }
            }
        }
    }
}
