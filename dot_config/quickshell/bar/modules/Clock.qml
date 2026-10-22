import QtQuick
import qs.components
import qs.services

Item {
    id: root

    implicitWidth: row.implicitWidth + 16
    implicitHeight: Theme.barHeight

    property string time: Qt.formatDateTime(new Date(), "HH:mm")
    property string day: Qt.formatDateTime(new Date(), "ddd dd")

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: {
            root.time = Qt.formatDateTime(new Date(), "HH:mm")
            root.day = Qt.formatDateTime(new Date(), "ddd dd")
        }
    }

    Rectangle {
        anchors.fill: parent
        color: hover.containsMouse ? Theme.hover : "transparent"
        Behavior on color { CAnim { type: CAnim.FastEffects } }
    }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 6

        Text {
            text: root.time
            color: Theme.fg
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
        }

        Text {
            text: root.day
            color: Theme.dim
            font.family: Theme.fontFamily
            font.pixelSize: 11
        }
    }

    MouseArea {
        id: hover
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onEntered: Tooltip.show("Relógio", root)
        onExited: Tooltip.hide()
        onPressed: Tooltip.hide()
        onClicked: Ui.toggle("clock")
    }

    Popover {
        key: "clock"
        trigger: root

        content: Component {
            Card {
                title: Qt.formatDateTime(new Date(), "dddd, dd 'de' MMMM")

                Text {
                    text: Qt.formatDateTime(new Date(), "HH:mm")
                    color: Theme.fg
                    font.family: Theme.fontFamily
                    font.pixelSize: 26
                    font.bold: true
                }

                Calendar {
                    today: new Date()
                }
            }
        }
    }
}
