import QtQuick
import Quickshell
import Quickshell.Io
import qs.components
import qs.services

Item {
    id: root

    readonly property int pct: Math.round(Power.pct * 100)

    implicitWidth: item.implicitWidth
    implicitHeight: Theme.barHeight

    Process {
        id: profileProc
        stdout: StdioCollector {}
    }

    function batteryIcon() {
        if (Power.charging)
            return "\uf0e7"
        const icons = ["\uf244", "\uf243", "\uf242", "\uf241", "\uf240"]
        return icons[Math.max(0, Math.min(4, Math.floor(root.pct / 20)))]
    }

    BarItem {
        id: item
        text: root.batteryIcon() + " " + root.pct
        tooltip: "Bateria · " + root.pct + "%"
        onClicked: Ui.toggle("battery")
    }

    Popover {
        key: "battery"
        trigger: item

        content: Component {
            Card {
                title: "Bateria"

                ListItem {
                    width: parent.width
                    clickable: false
                    label: "carga"
                    detail: root.pct + "% " + Power.stateLabel
                }

                ListItem {
                    width: parent.width
                    clickable: false
                    label: "tempo"
                    detail: Power.timeLabel !== "" ? Power.timeLabel : "—"
                }

                ListItem {
                    width: parent.width
                    clickable: false
                    label: "saúde"
                    detail: Power.healthLabel
                }

                ListItem {
                    width: parent.width
                    clickable: false
                    label: "consumo"
                    detail: Power.bat ? Power.bat.changeRate.toFixed(2) + " W" : "—"
                }

                Rectangle {
                    width: parent.width
                    height: 1
                    color: Theme.line
                }

                Text {
                    text: "perfil de energia"
                    color: Theme.faint
                    font.family: Theme.fontFamily
                    font.pixelSize: 11
                }

                Row {
                    spacing: 6

                    Repeater {
                        model: ["power-saver", "balanced", "performance"]

                        ActionButton {
                            required property var modelData
                            label: modelData
                            onClicked: {
                                profileProc.command = ["powerprofilesctl", "set", modelData]
                                profileProc.running = true
                            }
                        }
                    }
                }

                Text {
                    text: "atual: " + Power.profileName
                    color: Theme.dim
                    font.family: Theme.fontFamily
                    font.pixelSize: 11
                }
            }
        }
    }
}
