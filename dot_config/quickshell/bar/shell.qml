import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.components
import qs.modules
import qs.services

ShellRoot {
    // Fecha o card ao clicar fora; fica abaixo da barra, então clicar em outro
    // módulo troca de card em vez de só fechar.
    PanelWindow {
        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        focusable: false
        visible: Ui.active !== ""

        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.namespace: "quickshell-catcher"

        MouseArea {
            anchors.fill: parent
            onClicked: Ui.close()
        }
    }

    Bar {}

    OverviewBar {}

    OsdSurface {}
    TooltipSurface {}
    Launcher {}
    WallpaperPicker {}

    // Permite abrir/fechar cards por keybind: qs ipc call bar toggleCard wifi
    IpcHandler {
        target: "bar"

        function toggleCard(key: string) {
            Ui.toggle(key, "center")
        }

        function closeCard() {
            Ui.close()
        }

        function brightnessUp() {
            Brightness.up()
            Osd.show("brightness", Brightness.pct)
        }

        function brightnessDown() {
            Brightness.down()
            Osd.show("brightness", Brightness.pct)
        }

        function volumeUp() {
            AudioService.step(5)
        }

        function volumeDown() {
            AudioService.step(-5)
        }

        function volumeMute() {
            AudioService.toggleMute()
        }

        function launcherToggle() {
            LauncherService.toggle()
        }

        function wallpaperToggle() {
            Wallpapers.toggle()
        }

        function herdrToggle() {
            Ui.toggle("herdr")
        }

        function dictationToggle() {
            DictationService.toggle()
        }

        function toggleBarPosition() {
            Settings.barPosition = Settings.barPosition === "bottom" ? "top" : "bottom"
        }

        function idleToggle() {
            Idle.toggle()
            Osd.show("idle", Idle.active ? 1 : 0, Idle.active ? "idle inibido" : "idle normal")
        }
    }
}
