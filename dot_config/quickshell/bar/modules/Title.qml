import QtQuick
import qs.components
import qs.services

Item {
    id: root

    readonly property bool expanded: hover.hovered

    implicitWidth: Math.min(label.implicitWidth + 18, expanded ? 480 : 220)
    implicitHeight: Theme.barHeight

    Behavior on implicitWidth {
        Anim { type: Anim.StandardSmall }
    }

    Text {
        id: label
        anchors.fill: parent
        anchors.leftMargin: 9
        anchors.rightMargin: 9
        verticalAlignment: Text.AlignVCenter
        text: NiriService.title
        elide: Text.ElideRight
        color: Theme.fg
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSize
    }

    HoverHandler {
        id: hover
    }
}
