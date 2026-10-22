import QtQuick
import Quickshell.Bluetooth
import qs.components
import qs.services

Item {
    id: root

    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property var devices: {
        if (!adapter)
            return []
        const list = adapter.devices.values.slice()
        list.sort((a, b) => (Number(b.connected) - Number(a.connected)) || (Number(b.paired) - Number(a.paired)) || a.name.localeCompare(b.name))
        return list
    }

    property var menuDevice: null
    property string pendingForget: ""

    implicitWidth: item.implicitWidth
    implicitHeight: Theme.barHeight

    BarItem {
        id: item
        text: !root.adapter ? "\uf294" : (root.adapter.enabled ? "\uf293" : "\uf294")
        tooltip: "Bluetooth"
        active: root.adapter !== null && root.adapter.enabled
        onClicked: Ui.toggle("bluetooth")
    }

    Popover {
        key: "bluetooth"
        trigger: item

        content: Component {
            Card {
                title: "Bluetooth"

                Item {
                    width: parent.width
                    implicitHeight: 26

                    Text {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.adapter ? (root.adapter.enabled ? "ligado" : "desligado") : "sem controlador"
                        color: root.adapter && root.adapter.enabled ? Theme.fg : Theme.faint
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize
                    }

                    Toggle {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        checked: root.adapter ? root.adapter.enabled : false
                        onToggled: if (root.adapter) root.adapter.enabled = !root.adapter.enabled
                    }
                }

                ActionButton {
                    label: root.adapter && root.adapter.discovering ? "parar scan" : "procurar"
                    onClicked: if (root.adapter) root.adapter.discovering = !root.adapter.discovering
                }

                Repeater {
                    model: root.devices

                    ListItem {
                        required property var modelData
                        width: parent.width
                        label: modelData.name !== "" ? modelData.name : modelData.deviceName
                        detail: modelData.connected ? (modelData.batteryAvailable ? Math.round(modelData.battery * 100) + "%" : "conectado") : (modelData.paired ? "pareado" : "")
                        current: modelData.connected
                        onClicked: mouse => {
                            if (mouse.button === Qt.RightButton) {
                                root.menuDevice = modelData
                                root.pendingForget = ""
                                return
                            }
                            if (modelData.connected)
                                modelData.disconnect()
                            else if (modelData.paired)
                                modelData.connect()
                            else
                                modelData.pair()
                        }
                    }
                }

                Column {
                    visible: root.menuDevice !== null
                    width: parent.width
                    spacing: 4

                    Rectangle {
                        width: parent.width
                        height: 1
                        color: Theme.line
                    }

                    Text {
                        text: root.menuDevice ? (root.menuDevice.name || root.menuDevice.address) : ""
                        elide: Text.ElideRight
                        color: Theme.fg
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize
                        font.bold: true
                    }

                    Flow {
                        width: parent.width
                        spacing: 6

                        ActionButton {
                            visible: root.menuDevice !== null && root.menuDevice.paired
                            label: root.menuDevice && root.menuDevice.connected ? "desconectar" : "conectar"
                            onClicked: {
                                if (!root.menuDevice)
                                    return
                                if (root.menuDevice.connected)
                                    root.menuDevice.disconnect()
                                else
                                    root.menuDevice.connect()
                            }
                        }

                        ActionButton {
                            visible: root.menuDevice !== null && !root.menuDevice.paired
                            label: "parear"
                            onClicked: if (root.menuDevice) root.menuDevice.pair()
                        }

                        ActionButton {
                            visible: root.menuDevice !== null && root.menuDevice.paired
                            label: root.menuDevice && root.menuDevice.trusted ? "não confiar" : "confiar"
                            onClicked: {
                                if (root.menuDevice)
                                    root.menuDevice.trusted = !root.menuDevice.trusted
                            }
                        }

                        ActionButton {
                            visible: root.menuDevice !== null && root.menuDevice.paired
                            danger: true
                            label: root.menuDevice && root.pendingForget === root.menuDevice.address ? "confirmar esquecer" : "esquecer"
                            onClicked: {
                                if (!root.menuDevice)
                                    return
                                if (root.pendingForget === root.menuDevice.address) {
                                    root.menuDevice.forget()
                                    root.menuDevice = null
                                    root.pendingForget = ""
                                } else {
                                    root.pendingForget = root.menuDevice.address
                                }
                            }
                        }

                        ActionButton {
                            label: "fechar"
                            onClicked: {
                                root.menuDevice = null
                                root.pendingForget = ""
                            }
                        }
                    }
                }

                Text {
                    visible: root.devices.length === 0
                    text: root.adapter && root.adapter.enabled ? "nenhum dispositivo" : "ligue o adaptador"
                    color: Theme.faint
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize
                }
            }
        }
    }
}
