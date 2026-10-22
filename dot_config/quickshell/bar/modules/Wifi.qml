import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Networking
import qs.components
import qs.services

Item {
    id: root

    readonly property var wifi: Networking.devices.values.find(d => d.type === DeviceType.Wifi) ?? null
    readonly property var networks: {
        if (!wifi)
            return []
        const list = wifi.networks.values.slice()
        list.sort((a, b) => (Number(b.connected) - Number(a.connected)) || (b.signalStrength - a.signalStrength))
        return list
    }

    property var pending: null

    implicitWidth: item.implicitWidth
    implicitHeight: Theme.barHeight

    Process {
        id: radioProc
        stdout: StdioCollector {}
    }

    BarItem {
        id: item
        text: root.wifi && root.wifi.connected ? "\uf1eb" : "\uf072"
        tooltip: root.wifi && root.wifi.connected ? "Wi-Fi · " + root.wifi.name : "Wi-Fi"
        active: root.wifi !== null && root.wifi.connected
        onClicked: Ui.toggle("wifi")
    }

    Popover {
        key: "wifi"
        trigger: item

        content: Component {
            Card {
                title: "Wi-Fi"

                Item {
                    width: parent.width
                    implicitHeight: 26

                    Text {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        text: Networking.wifiEnabled ? (root.wifi ? root.wifi.name : "sem interface") : "desligado"
                        color: Networking.wifiEnabled ? Theme.fg : Theme.faint
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize
                    }

                    Toggle {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        checked: Networking.wifiEnabled
                        onToggled: {
                            radioProc.command = ["nmcli", "radio", "wifi", Networking.wifiEnabled ? "off" : "on"]
                            radioProc.running = true
                        }
                    }
                }

                Repeater {
                    model: root.networks

                    ListItem {
                        required property var modelData
                        width: parent.width
                        label: modelData.name !== "" ? modelData.name : "(rede oculta)"
                        detail: (modelData.security === WifiSecurityType.Open ? "" : "\uf023 ") + Math.round(modelData.signalStrength * 100) + "%"
                        current: modelData.connected
                        onClicked: {
                            if (modelData.connected) {
                                modelData.disconnect()
                            } else if (modelData.security === WifiSecurityType.Open || modelData.known) {
                                modelData.connect()
                            } else {
                                root.pending = modelData
                                Ui.open("wifi-pass")
                            }
                        }
                    }
                }

                ActionButton {
                    label: "avançado (nmtui)"
                    onClicked: {
                        Ui.close()
                        Quickshell.execDetached(["kitty", "-e", "nmtui"])
                    }
                }
            }
        }
    }

    Popover {
        key: "wifi-pass"
        trigger: item
        wantKeyboard: true

        content: Component {
            Card {
                title: root.pending ? ("Senha · " + root.pending.name) : "Senha"

                Item {
                    width: parent.width
                    implicitHeight: 30

                    Rectangle {
                        anchors.fill: parent
                        color: "transparent"
                        border.width: 1
                        border.color: Theme.line
                    }

                    TextInput {
                        id: psk
                        anchors.fill: parent
                        anchors.leftMargin: 6
                        anchors.rightMargin: 6
                        verticalAlignment: TextInput.AlignVCenter
                        echoMode: TextInput.Password
                        color: Theme.fg
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize
                        clip: true
                        focus: true
                        onAccepted: submit()
                    }
                }

                ActionButton {
                    label: "conectar"
                    onClicked: submit()
                }

                ActionButton {
                    label: "cancelar"
                    onClicked: {
                        root.pending = null
                        Ui.open("wifi")
                    }
                }

                function submit() {
                    if (!root.pending)
                        return
                    root.pending.connectWithPsk(psk.text)
                    root.pending = null
                    Ui.close()
                }
            }
        }
    }
}
