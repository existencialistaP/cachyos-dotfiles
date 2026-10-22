import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Wayland._IdleInhibitor
import qs.modules
import qs.services

PanelWindow {
    id: root

    anchors {
        left: true
        right: true
        top: Settings.barPosition === "top"
        bottom: Settings.barPosition === "bottom"
    }

    implicitHeight: Settings.barHeight
    exclusiveZone: Settings.barHeight
    color: Theme.bg

    Component.onCompleted: BarRef.window = root

    IdleInhibitor {
        window: root
        enabled: Idle.active
    }

    WlrLayershell.namespace: "quickshell-bar"
    WlrLayershell.layer: WlrLayer.Top

    Row {
        x: Theme.pad
        y: (root.height - height) / 2
        spacing: 2

        Title {}
        Privacy {}
    }

    Row {
        x: (root.screen.width - width) / 2
        y: (root.height - height) / 2
        spacing: 2

        Clock {}
        Media {}
    }

    Row {
        x: root.screen.width - width - Theme.pad
        y: (root.height - height) / 2
        spacing: 2

        Notifications {}
        Wifi {}
        Bluetooth {}
        Audio {}
        Dictation {}
        Herdr {}
        Battery {}
        Tray {}
        Menu {}
    }
}
