import QtQuick
import qs.components
import qs.services

Item {
    id: root

    implicitWidth: item.implicitWidth
    implicitHeight: Theme.barHeight

    readonly property string glyph: "\uf120"
    readonly property color statusColor: HerdrService.anyBlocked ? Theme.error : (HerdrService.anyWorking ? Theme.accent : Theme.fg)

    BarItem {
        id: item
        text: HerdrService.available && HerdrService.agentCount > 0 ? root.glyph + " " + HerdrService.agentCount : root.glyph
        tooltip: HerdrService.available
            ? "Herdr · " + HerdrService.agentCount + " agente(s) · "
                + (HerdrService.anyBlocked ? "aguardando input" : (HerdrService.anyWorking ? "trabalhando" : "idle"))
            : "Herdr indisponível"
        active: Ui.active === "herdr"
        color: HerdrService.available ? root.statusColor : Theme.faint

        onClicked: mouse => {
            if (mouse.button === Qt.RightButton)
                HerdrService.openHerdr()
            else
                Ui.toggle("herdr", "center")
        }
    }
}
