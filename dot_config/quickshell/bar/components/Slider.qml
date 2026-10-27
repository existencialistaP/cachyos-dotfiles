import QtQuick
import qs.services

Item {
    id: root

    property real value: 0
    property bool pressed: false
    property bool enabled: true
    signal moved(real value)

    implicitHeight: 20
    opacity: enabled ? 1 : 0.45

    Rectangle {
        id: track
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        height: 2
        color: Theme.line
    }

    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        width: track.width * Math.max(0, Math.min(1, root.value))
        height: 2
        color: Theme.fg
    }

    Rectangle {
        width: 6
        height: 12
        anchors.verticalCenter: parent.verticalCenter
        x: Math.max(0, Math.min(track.width - width, track.width * root.value - width / 2))
        color: Theme.fg
    }

    MouseArea {
        anchors.fill: parent
        enabled: root.enabled
        cursorShape: Qt.PointingHandCursor
        onPressed: mouse => {
            root.pressed = true
            root.moved(Math.max(0, Math.min(1, mouse.x / width)))
        }
        onReleased: root.pressed = false
        onCanceled: root.pressed = false
        onPositionChanged: mouse => {
            if (pressed)
                root.moved(Math.max(0, Math.min(1, mouse.x / width)))
        }
    }
}
