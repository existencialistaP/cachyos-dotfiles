import QtQuick
import qs.services

Item {
    id: root

    property string label: ""
    property bool danger: false
    property bool selected: false
    signal clicked()

    implicitWidth: labelText.implicitWidth + 16
    implicitHeight: 26

    Rectangle {
        anchors.fill: parent
        color: root.selected || hover.containsMouse ? Theme.hover : "transparent"
        Behavior on color { CAnim { type: CAnim.FastEffects } }
    }

    Text {
        id: labelText
        anchors.centerIn: parent
        text: root.label
        color: root.danger ? Theme.error : Theme.fg
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSize
        font.bold: root.selected
    }

    MouseArea {
        id: hover
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
