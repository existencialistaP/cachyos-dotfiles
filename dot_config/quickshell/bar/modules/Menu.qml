import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Bluetooth
import Quickshell.Networking
import qs.components
import qs.services

Item {
    id: root

    property bool dnd: false
    property string pending: ""
    property string openSection: "principal"

    function toggleSection(name) {
        openSection = openSection === name ? "" : name
    }

    implicitWidth: item.implicitWidth
    implicitHeight: Theme.barHeight

    readonly property string home: Quickshell.env("HOME")
    readonly property var adapter: Bluetooth.defaultAdapter

    Process {
        id: modeProc
        command: ["makoctl", "mode"]
        stdout: StdioCollector {
            onStreamFinished: root.dnd = text.split("\n").some(line => line.trim() === "do-not-disturb")
        }
    }

    Process {
        id: actProc
        command: []
        stdout: StdioCollector {}
        onExited: {
            modeProc.running = true
            Sys.refreshFailed()
        }
    }

    Timer {
        interval: 5000
        running: true
        repeat: true
        onTriggered: modeProc.running = true
    }

    function run(cmd) {
        actProc.command = cmd
        actProc.running = true
    }

    function runDetached(cmd) {
        Quickshell.execDetached(cmd)
    }

    function dangerous(action) {
        if (pending === action) {
            pending = ""
            switch (action) {
            case "logout": runDetached(["niri", "msg", "action", "quit"]); break
            case "reboot": run(["systemctl", "reboot"]); break
            case "poweroff": run(["systemctl", "poweroff"]); break
            }
        } else {
            pending = action
        }
    }

    BarItem {
        id: item
        text: "\uf0c9"
        tooltip: "Menu"
        onClicked: {
            root.pending = ""
            Ui.toggle("menu")
        }
    }

    Popover {
        key: "menu"
        trigger: item

        content: Component {
            Card {
                implicitWidth: 420
                title: "Menu"

                Section {
                    title: "Principal"
                    controlled: true
                    expanded: root.openSection === "principal"
                    onToggled: root.toggleSection("principal")

                    Grid {
                        width: parent.width
                        columns: 2
                        spacing: 6

                        ActionButton {
                            width: (parent.width - parent.spacing) / 2
                            label: "\uf023  lock"
                            onClicked: runDetached([root.home + "/.config/niri/scripts/lock.sh"])
                        }
                        ActionButton {
                            width: (parent.width - parent.spacing) / 2
                            label: root.pending === "logout" ? "confirmar logout" : "\uf2f5  logout"
                            danger: true
                            onClicked: root.dangerous("logout")
                        }
                        ActionButton {
                            width: (parent.width - parent.spacing) / 2
                            label: "\uf186  suspend"
                            onClicked: run(["systemctl", "suspend"])
                        }
                        ActionButton {
                            width: (parent.width - parent.spacing) / 2
                            label: root.pending === "reboot" ? "confirmar reboot" : "\uf021  reboot"
                            danger: true
                            onClicked: root.dangerous("reboot")
                        }
                        ActionButton {
                            width: (parent.width - parent.spacing) / 2
                            label: root.pending === "poweroff" ? "confirmar desligar" : "\uf011  desligar"
                            danger: true
                            onClicked: root.dangerous("poweroff")
                        }
                    }

                    Rectangle {
                        width: parent.width
                        height: 1
                        color: Theme.line
                    }

                    Item {
                        width: parent.width
                        implicitHeight: 26

                        Text {
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            text: "\uf1eb  Wi-Fi"
                            color: Theme.fg
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSize
                        }

                        Toggle {
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            checked: Networking.wifiEnabled
                            onToggled: root.run(["nmcli", "radio", "wifi", Networking.wifiEnabled ? "off" : "on"])
                        }
                    }

                    Item {
                        width: parent.width
                        implicitHeight: 26

                        Text {
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            text: "\uf293  Bluetooth"
                            color: Theme.fg
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

                    Item {
                        width: parent.width
                        implicitHeight: 26

                        Text {
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            text: "\uf0f3  Não perturbe"
                            color: Theme.fg
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSize
                        }

                        Toggle {
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            checked: root.dnd
                            onToggled: root.run(["makoctl", "mode", "-t", "do-not-disturb"])
                        }
                    }

                    Item {
                        width: parent.width
                        implicitHeight: 26

                        Text {
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            text: "\uf254  inibir idle"
                            color: Theme.fg
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSize
                        }

                        Toggle {
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            checked: Idle.active
                            onToggled: Idle.toggle()
                        }
                    }

                    Item {
                        width: parent.width
                        implicitHeight: 26

                        Text {
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            text: "\uf0e7  perfil de energia"
                            color: Theme.fg
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSize
                        }

                        Text {
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            text: Power.profileName + "  ›"
                            color: Theme.dim
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSize
                            MouseArea {
                                anchors.fill: parent
                                anchors.margins: -4
                                cursorShape: Qt.PointingHandCursor
                                onClicked: Power.cycleProfile()
                            }
                        }
                    }
                }

                Section {
                    title: "Sistema"
                    controlled: true
                    expanded: root.openSection === "sistema"
                    onToggled: root.toggleSection("sistema")

                    ListItem {
                        width: parent.width
                        clickable: false
                        label: "cpu · temp"
                        detail: Math.round(Sys.cpu) + "% · " + Math.round(Sys.temp) + "°C"
                    }

                    ListItem {
                        width: parent.width
                        clickable: false
                        label: "memória"
                        detail: Sys.memUsed.toFixed(1) + " / " + Sys.memTotal.toFixed(1) + " GiB"
                    }

                    Repeater {
                        model: Sys.top.slice(0, 3)

                        ListItem {
                            required property var modelData
                            width: parent.width
                            clickable: false
                            label: modelData.name
                            detail: modelData.cpu + "%"
                        }
                    }

                    ActionButton {
                        label: "btop"
                        onClicked: {
                            Ui.close()
                            runDetached(["kitty", "-e", "btop"])
                        }
                    }

                    Rectangle {
                        width: parent.width
                        height: 1
                        color: Theme.line
                    }

                    ListItem {
                        width: parent.width
                        clickable: false
                        label: "unidades falhando"
                        detail: String(Sys.failedUnits)
                    }

                    Repeater {
                        model: Sys.failedList

                        Text {
                            required property var modelData
                            width: parent.width
                            text: "· " + modelData
                            elide: Text.ElideRight
                            color: Theme.dim
                            font.family: Theme.fontFamily
                            font.pixelSize: 11
                        }
                    }

                    ActionButton {
                        visible: Sys.failedUnits > 0
                        label: "reset falhas"
                        onClicked: root.run(["systemctl", "--user", "reset-failed"])
                    }
                }

                Section {
                    title: "Layout"
                    controlled: true
                    expanded: root.openSection === "layout"
                    onToggled: root.toggleSection("layout")

                    ListItem {
                        width: parent.width
                        clickable: false
                        label: "posição"
                        detail: Settings.barPosition
                    }

                    Flow {
                        width: parent.width
                        spacing: 6

                        ActionButton { label: "embaixo"; selected: Settings.barPosition === "bottom"; onClicked: Settings.barPosition = "bottom" }
                        ActionButton { label: "topo"; selected: Settings.barPosition === "top"; onClicked: Settings.barPosition = "top" }
                    }

                    ListItem {
                        width: parent.width
                        clickable: false
                        label: "altura"
                        detail: Settings.barHeight + " px"
                    }

                    Flow {
                        width: parent.width
                        spacing: 6

                        ActionButton { label: "26"; selected: Settings.barHeight === 26; onClicked: Settings.barHeight = 26 }
                        ActionButton { label: "30"; selected: Settings.barHeight === 30; onClicked: Settings.barHeight = 30 }
                        ActionButton { label: "34"; selected: Settings.barHeight === 34; onClicked: Settings.barHeight = 34 }
                    }
                }

                Section {
                    title: "Clipboard"
                    controlled: true
                    expanded: root.openSection === "clipboard"
                    onToggled: root.toggleSection("clipboard")

                    Item {
                        width: parent.width
                        implicitHeight: 28

                        TextInput {
                            id: clipSearch
                            anchors.fill: parent
                            verticalAlignment: TextInput.AlignVCenter
                            color: Theme.fg
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSize
                            selectByMouse: true
                            onTextChanged: Clipboard.query = text
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "buscar…"
                            visible: clipSearch.text === ""
                            color: Theme.faint
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSize
                        }
                    }

                    Repeater {
                        model: Clipboard.filtered

                        ListItem {
                            required property var modelData
                            width: parent.width
                            label: modelData.preview !== "" ? modelData.preview : "(imagem)"
                            onClicked: Clipboard.copy(modelData.id)
                        }
                    }

                    Text {
                        visible: Clipboard.filtered.length === 0
                        text: "vazio"
                        color: Theme.faint
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize
                    }

                    ActionButton {
                        label: "limpar tudo"
                        onClicked: Clipboard.wipe()
                    }
                }

                Section {
                    title: "Tema"
                    controlled: true
                    expanded: root.openSection === "tema"
                    onToggled: root.toggleSection("tema")

                    Flow {
                        width: parent.width
                        spacing: 6

                        ActionButton {
                            label: "wallpapers"
                            onClicked: {
                                Ui.close()
                                Wallpapers.toggle()
                            }
                        }
                        ActionButton {
                            label: "claro/escuro"
                            onClicked: runDetached([root.home + "/.config/niri/scripts/themeSwitch.sh"])
                        }
                    }
                }
            }
        }
    }
}
