import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.components
import qs.services

// OSD próprio (substitui o swayosd): faixa fina acima da barra, sem input.
PanelWindow {
    id: root

    anchors {
        bottom: true
        left: true
        right: true
    }

    margins {
        bottom: Settings.barPosition === "bottom" ? Settings.barHeight + 10 : 10
    }

    implicitHeight: 44
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    focusable: false
    visible: Osd.visible

    WlrLayershell.namespace: "quickshell-osd"
    WlrLayershell.layer: WlrLayer.Overlay

    // sem região de input: cliques atravessam o OSD
    mask: Region {}

    Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        width: 220
        height: 40
        color: Theme.bg
        border.width: 1
        border.color: Theme.line
        opacity: Osd.visible ? 1 : 0
        scale: Osd.visible ? 1 : 0.97

        Behavior on opacity { Anim { type: Anim.FastEffects } }
        Behavior on scale { Anim { type: Anim.FastSpatial } }

        Row {
            anchors.fill: parent
            anchors.margins: 10
            spacing: 10

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: {
                    if (Osd.kind === "brightness")
                        return "\uf0eb"
                    if (Osd.kind === "mute")
                        return Osd.value > 0 ? "\uf028" : "\uf026"
                    if (Osd.kind === "idle")
                        return "\uf254"
                    return Osd.value > 0 ? "\uf028" : "\uf026"
                }
                color: Theme.fg
                font.family: Theme.fontFamily
                font.pixelSize: 14
            }

            Column {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - 34
                spacing: 4

                Text {
                    text: Osd.text
                    color: Theme.fg
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize
                }

                Rectangle {
                    width: parent.width
                    height: 2
                    color: Theme.line

                    Rectangle {
                        width: parent.width * Osd.value
                        height: 2
                        color: Theme.fg
                        Behavior on width { Anim { type: Anim.FastEffects } }
                    }
                }
            }
        }
    }
}
