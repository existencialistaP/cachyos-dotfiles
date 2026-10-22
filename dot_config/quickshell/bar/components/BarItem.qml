import QtQuick
import qs.services

Item {
    id: root

    property string text: ""
    property string tooltip: ""
    property bool active: false
    property color color: Theme.fg
    signal clicked(var mouse)
    signal scrolled(int delta, int modifiers)

    implicitWidth: label.implicitWidth + 14
    implicitHeight: Theme.barHeight

    Rectangle {
        anchors.fill: parent
        color: hover.containsMouse ? Theme.hover : "transparent"
        Behavior on color { CAnim { type: CAnim.FastEffects } }
    }

    Text {
        id: label
        anchors.centerIn: parent
        text: root.text
        color: root.color
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSize
        font.bold: root.active
    }

    MouseArea {
        id: hover
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onEntered: if (root.tooltip !== "") Tooltip.show(root.tooltip, root)
        onExited: Tooltip.hide()
        onPressed: Tooltip.hide()
        onClicked: mouse => root.clicked(mouse)
        onWheel: wheel => {
            root.scrolled(wheel.angleDelta.y > 0 ? 1 : -1, wheel.modifiers)
            wheel.accepted = true
        }
    }
}
