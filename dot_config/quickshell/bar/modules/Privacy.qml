import QtQuick
import Quickshell.Services.Pipewire
import qs.components
import qs.services

BarItem {
    readonly property bool micInUse: Pipewire.nodes.values.some(node => {
        const cls = String(node.properties["media.class"] ?? "")
        return node.isStream && !node.isSink && cls.indexOf("Input") >= 0
    })

    visible: micInUse
    text: "\uf130"
    tooltip: "Microfone em uso"
}
