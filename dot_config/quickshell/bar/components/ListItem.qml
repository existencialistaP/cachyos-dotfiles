import QtQuick
import qs.services

Item {
    id: root

    property string label: ""
    property string detail: ""
    property bool current: false
    property bool clickable: true
    signal clicked(var mouse)

    implicitHeight: 30

    Rectangle {
        anchors.fill: parent
        color: hover.containsMouse && root.clickable ? Theme.hover : "transparent"
        Behavior on color { CAnim { type: CAnim.FastEffects } }
    }

    Text {
        anchors.left: parent.left
        anchors.right: detailText.left
        anchors.rightMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        text: root.label
        elide: Text.ElideRight
        color: Theme.fg
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSize
        font.bold: root.current
    }

    Text {
        id: detailText
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        text: root.detail
        color: Theme.faint
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSize
    }

    MouseArea {
        id: hover
        anchors.fill: parent
        hoverEnabled: true
        enabled: root.clickable
        cursorShape: root.clickable ? Qt.PointingHandCursor : Qt.ArrowCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: mouse => root.clicked(mouse)
    }
}
