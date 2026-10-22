import QtQuick
import qs.services

Item {
    id: root

    property bool checked: false
    signal toggled()

    implicitWidth: 30
    implicitHeight: 18

    Rectangle {
        anchors.fill: parent
        color: root.checked ? Theme.accent : "transparent"
        border.width: 1
        border.color: root.checked ? Theme.accent : Theme.dim
        Behavior on color { CAnim { type: CAnim.FastEffects } }
    }

    Rectangle {
        width: 12
        height: 12
        y: 3
        x: root.checked ? 15 : 3
        color: root.checked ? Theme.bg : Theme.dim
        Behavior on x { Anim { type: Anim.StandardSmall } }
        Behavior on color { CAnim { type: CAnim.FastEffects } }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.toggled()
    }
}
