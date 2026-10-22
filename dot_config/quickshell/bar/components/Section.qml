import QtQuick
import qs.services

Column {
    id: root

    property string title: ""
    property bool expanded: true
    property bool controlled: false
    signal toggled(bool expanded)
    default property alias body: content.data

    width: parent ? parent.width : 0
    spacing: 4

    Item {
        width: parent.width
        implicitHeight: 22

        Text {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            text: root.title.toUpperCase()
            color: Theme.faint
            font.family: Theme.fontFamily
            font.pixelSize: 10
            font.letterSpacing: 1.1
        }

        Text {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            text: "\uf077"
            rotation: root.expanded ? 0 : 180
            color: Theme.faint
            font.family: Theme.fontFamily
            font.pixelSize: 9
            Behavior on rotation { Anim { type: Anim.StandardSmall } }
        }

        Rectangle {
            anchors.bottom: parent.bottom
            width: parent.width
            height: 1
            color: Theme.line
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                if (root.controlled)
                    root.toggled(!root.expanded)
                else
                    root.expanded = !root.expanded
            }
        }
    }

    Column {
        id: content
        width: root.width
        spacing: 4
        visible: root.expanded
    }
}
