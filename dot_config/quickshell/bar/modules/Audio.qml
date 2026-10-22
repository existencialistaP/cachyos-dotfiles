import QtQuick
import qs.components
import qs.services

Item {
    id: root

    implicitWidth: item.implicitWidth
    implicitHeight: Theme.barHeight

    BarItem {
        id: item
        text: AudioService.muted ? "\uf026" : (AudioService.volume < 35 ? "\uf027" : "\uf028")
        tooltip: "Áudio · " + (AudioService.muted ? "mudo" : AudioService.volume + "%") + " · brilho"
        active: !AudioService.muted && AudioService.volume > 0

        onClicked: mouse => {
            if (mouse.button === Qt.RightButton)
                AudioService.toggleMute()
            else
                Ui.toggle("audio")
        }

        onScrolled: (delta, modifiers) => {
            if (modifiers & Qt.ShiftModifier) {
                Brightness.apply(Brightness.pct + delta * 0.05)
                Osd.show("brightness", Brightness.pct)
            } else {
                AudioService.step(delta * 5)
            }
        }
    }

    Popover {
        key: "audio"
        trigger: item

        content: Component {
            Card {
                title: "Áudio e brilho"

                Item {
                    width: parent.width
                    implicitHeight: 24

                    Text {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        text: AudioService.muted ? "mudo" : AudioService.volume + "%"
                        color: Theme.fg
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize
                    }

                    Text {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        text: AudioService.muted ? "ativar" : "silenciar"
                        color: Theme.dim
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize
                        MouseArea {
                            anchors.fill: parent
                            anchors.margins: -4
                            cursorShape: Qt.PointingHandCursor
                            onClicked: AudioService.toggleMute()
                        }
                    }
                }

                Slider {
                    width: parent.width
                    value: AudioService.volume / 100
                    onMoved: v => AudioService.setVolume(v * 100)
                }

                Rectangle {
                    width: parent.width
                    height: 1
                    color: Theme.line
                }

                Item {
                    width: parent.width
                    implicitHeight: 24

                    Text {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        text: "brilho"
                        color: Theme.dim
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize
                    }

                    Text {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        text: Math.round(Brightness.pct * 100) + "%"
                        color: Theme.fg
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize
                    }
                }

                Slider {
                    width: parent.width
                    value: Brightness.pct
                    onMoved: v => {
                        Brightness.apply(v)
                        Osd.show("brightness", v)
                    }
                }

                Rectangle {
                    width: parent.width
                    height: 1
                    color: Theme.line
                }

                Repeater {
                    model: AudioService.sinks

                    ListItem {
                        required property var modelData
                        width: parent.width
                        label: modelData.description
                        current: AudioService.sink && modelData.id === AudioService.sink.id
                        detail: AudioService.sink && modelData.id === AudioService.sink.id ? "padrão" : ""
                        onClicked: AudioService.setDefaultSink(modelData)
                    }
                }

                Rectangle {
                    visible: AudioService.streams.length > 0
                    width: parent.width
                    height: 1
                    color: Theme.line
                }

                Text {
                    visible: AudioService.streams.length > 0
                    text: "apps"
                    color: Theme.faint
                    font.family: Theme.fontFamily
                    font.pixelSize: 11
                }

                Repeater {
                    model: AudioService.streams.slice(0, 4)

                    Item {
                        required property var modelData

                        width: parent.width
                        implicitHeight: 38

                        Text {
                            anchors.left: parent.left
                            anchors.top: parent.top
                            text: AudioService.streamName(modelData)
                            elide: Text.ElideRight
                            width: parent.width
                            color: Theme.dim
                            font.family: Theme.fontFamily
                            font.pixelSize: 11

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: AudioService.toggleStreamMute(modelData)
                            }
                        }

                        Slider {
                            anchors.bottom: parent.bottom
                            width: parent.width
                            value: Math.max(0, Math.min(1, modelData.audio ? modelData.audio.volume : 0))
                            onMoved: v => AudioService.setStreamVolume(modelData, v)
                        }
                    }
                }
            }
        }
    }
}
