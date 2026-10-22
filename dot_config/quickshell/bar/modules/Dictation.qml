import QtQuick
import qs.components
import qs.services

Item {
    id: root

    implicitWidth: item.implicitWidth
    implicitHeight: Theme.barHeight

    readonly property string glyph: "\uf130"

    readonly property string statusText: {
        if (DictationService.state === "recording")
            return "gravando · " + DictationService.elapsed + "s"
        if (DictationService.state === "transcribing")
            return "transcrevendo…"
        if (DictationService.state === "error")
            return "erro"
        return "ditado local"
    }

    BarItem {
        id: item
        text: DictationService.recording ? root.glyph + " " + DictationService.elapsed + "s"
            : DictationService.transcribing ? root.glyph + " …"
            : root.glyph
        tooltip: DictationService.state === "error" ? "Ditado · " + DictationService.error
            : DictationService.recording ? "Parar ditado (" + DictationService.elapsed + "s)"
            : "Ditado local · Super+Shift+D"
        active: DictationService.recording
        color: DictationService.state === "error" ? Theme.error : (DictationService.recording ? Theme.pink : Theme.fg)

        onClicked: mouse => {
            if (mouse.button === Qt.RightButton)
                Ui.toggle("dictation")
            else
                DictationService.toggle()
        }
    }

    Popover {
        key: "dictation"
        trigger: item

        content: Component {
            Card {
                title: "Ditado local"

                Text {
                    width: parent.width
                    visible: DictationService.state !== "idle"
                    text: root.statusText
                    color: DictationService.state === "error" ? Theme.error : Theme.dim
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize
                }

                Text {
                    width: parent.width
                    visible: DictationService.transcript !== ""
                    text: DictationService.transcript
                    wrapMode: Text.Wrap
                    color: Theme.fg
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize
                }

                Text {
                    width: parent.width
                    visible: DictationService.error !== ""
                    text: DictationService.error
                    wrapMode: Text.Wrap
                    color: DictationService.state === "error" ? Theme.error : Theme.dim
                    font.family: Theme.fontFamily
                    font.pixelSize: 11
                }

                Text {
                    width: parent.width
                    visible: !DictationService.busy && DictationService.transcript === "" && DictationService.error === ""
                    text: "clique no microfone ou use Super+Shift+D"
                    wrapMode: Text.Wrap
                    color: Theme.faint
                    font.family: Theme.fontFamily
                    font.pixelSize: 11
                }

                Row {
                    spacing: 4
                    visible: DictationService.transcript !== "" || DictationService.error !== ""

                    ActionButton {
                        label: "copiar"
                        onClicked: DictationService.copy()
                    }

                    ActionButton {
                        label: "limpar"
                        onClicked: DictationService.reset()
                    }
                }

                Text {
                    width: parent.width
                    text: "parakeet · sherpa-onnx · modelo do Orca"
                    color: Theme.faint
                    font.family: Theme.fontFamily
                    font.pixelSize: 10
                }
            }
        }
    }
}
