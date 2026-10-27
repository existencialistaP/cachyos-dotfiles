import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.services

// Card em uma superfície Overlay (acima de janelas normais e da barra).
// Clique abre junto do ícone; keybind abre centralizado na horizontal, rente à barra.
// Sem escurecer a tela.
PanelWindow {
    id: root

    property string key: ""
    property Item trigger: null
    property Component content: null
    property bool wantKeyboard: false

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    focusable: true
    visible: Ui.active === key && trigger !== null
    mask: Region { item: loader.item }

    onVisibleChanged: if (visible) Tooltip.hide()

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-card"

    readonly property real cardW: loader.item ? loader.item.width : 0
    readonly property real cardH: loader.item ? loader.item.height : 0
    readonly property real triggerX: trigger ? trigger.mapToItem(null, trigger.width / 2, 0).x : 0
    readonly property real cardX: Ui.mode === "center" ? Math.max(0, (width - cardW) / 2) : Math.max(8, Math.min(width - cardW - 8, triggerX - cardW / 2))

    readonly property real cardY: Settings.barPosition === "bottom" ? Math.max(0, height - Settings.barHeight - cardH) : Settings.barHeight

    Loader {
        id: loader
        x: root.cardX
        y: root.cardY
        width: item ? item.implicitWidth : 0
        height: item ? item.implicitHeight : 0
        sourceComponent: root.content

        onLoaded: {
            item.width = Qt.binding(() => loader.width)
            item.height = Qt.binding(() => loader.height)
        }
    }
}
