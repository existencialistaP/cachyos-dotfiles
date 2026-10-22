import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.services

// Faixa sem input, acima (ou abaixo) da barra; o balão fica centrado no item.
PanelWindow {
    id: root

    anchors {
        left: true
        right: true
        top: Settings.barPosition === "top"
        bottom: Settings.barPosition === "bottom"
    }

    margins {
        top: Settings.barPosition === "top" ? Settings.barHeight + 4 : 0
        bottom: Settings.barPosition === "bottom" ? Settings.barHeight + 4 : 0
    }

    implicitHeight: 24
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    focusable: false
    visible: Tooltip.shown && Tooltip.item !== null
    mask: Region {}

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-tooltip"

    readonly property real itemX: Tooltip.item ? Tooltip.item.mapToItem(null, Tooltip.item.width / 2, 0).x : 0

    Rectangle {
        id: bubble

        x: Math.max(4, Math.min(root.width - width - 4, root.itemX - width / 2))
        anchors.verticalCenter: parent.verticalCenter
        width: text.implicitWidth + 16
        height: 22
        color: Theme.bg
        border.width: 1
        border.color: Theme.line

        Text {
            id: text
            anchors.centerIn: parent
            text: Tooltip.text
            color: Theme.fg
            font.family: Theme.fontFamily
            font.pixelSize: 11
        }
    }
}
