import QtQuick
import Quickshell
import Quickshell.Services.Mpris
import qs.components
import qs.services

Item {
    id: root

    property var pinned: null
    property real seekPos: -1
    property real livePos: 0

    Timer {
        id: seekHold
        interval: 1600
        onTriggered: root.seekPos = -1
    }

    // MPRIS Position não emite notify periodicamente: ler a propriedade 2x/s
    // acompanha a letra sem atraso visível e evita valor congelado da faixa anterior.
    Timer {
        interval: 500
        running: root.player !== null
        repeat: true
        onTriggered: {
            root.livePos = root.player ? root.player.position : 0
            if (root.player)
                Lyrics.ensure(root.player.trackTitle, root.player.trackArtist, root.player.trackAlbum, root.player.length)
        }
    }

    onPlayerChanged: {
        root.livePos = root.player ? root.player.position : 0
    }

    // pequena antecedência: a linha entra junto com o vocal, não depois dele
    readonly property int lyricIndex: Lyrics.indexAt(displayPos + 0.2)

    readonly property var players: Mpris.players.values
    // playerctld espelha o player real e costuma congelar a posição; prefira o real
    readonly property var realPlayers: {
        const list = players.filter(p => String(p.dbusName ?? "").toLowerCase().indexOf("playerctld") < 0)
        return list.length > 0 ? list : players
    }
    readonly property var player: {
        if (pinned && realPlayers.indexOf(pinned) >= 0)
            return pinned
        for (const p of realPlayers)
            if (p.isPlaying)
                return p
        return realPlayers.length > 0 ? realPlayers[0] : null
    }
    readonly property bool hasPlayer: player !== null
    readonly property var identities: {
        const out = []
        for (const p of realPlayers)
            if (out.indexOf(p.identity) < 0)
                out.push(p.identity)
        return out
    }
    readonly property var playersByFirstIdentity: {
        const out = []
        for (const identity of identities) {
            const match = realPlayers.find(p => p.identity === identity)
            if (match)
                out.push(match)
        }
        return out
    }
    readonly property bool playing: player !== null && player.isPlaying
    readonly property real len: player ? player.length : 0
    // spotatui acumula Position entre repetições da mesma faixa; normaliza pelo
    // comprimento para o progresso não passar de 100% nem voltar a 0.
    readonly property real normalizedPos: {
        if (livePos < 0)
            return 0
        if (len > 0 && livePos > len)
            return livePos % len
        return livePos
    }
    readonly property real displayPos: seekPos >= 0 ? seekPos : normalizedPos


    implicitWidth: hasPlayer ? row.implicitWidth + 10 : 0
    implicitHeight: Theme.barHeight

    Behavior on implicitWidth { Anim { type: Anim.StandardSmall } }

    function fmt(seconds) {
        if (!seconds || seconds < 0)
            return "0:00"
        const m = Math.floor(seconds / 60)
        const s = Math.floor(seconds % 60)
        return m + ":" + String(s).padStart(2, "0")
    }

    function iconFor(identity) {
        const id = (identity ?? "").toLowerCase()
        if (id.indexOf("spotify") >= 0 || id.indexOf("spotatui") >= 0)
            return "\uf1bc"
        if (id.indexOf("firefox") >= 0)
            return "\uf269"
        return "\uf001"
    }

    function cycleLoop() {
        if (!player)
            return
        player.loopState = (player.loopState + 1) % 3
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton

        onEntered: Tooltip.show(root.hasPlayer && root.player ? (root.player.trackTitle || "Mídia") + (root.player.trackArtist ? " · " + root.player.trackArtist : "") : "Mídia", root)
        onExited: Tooltip.hide()
        onPressed: Tooltip.hide()

        onClicked: mouse => {
            if (!root.hasPlayer)
                return
            if (mouse.button === Qt.LeftButton)
                Ui.toggle("media")
            else
                root.player.togglePlaying()
        }

        onWheel: wheel => {
            if (!root.player)
                return
            if (wheel.angleDelta.y > 0)
                root.player.previous()
            else
                root.player.next()
            wheel.accepted = true
        }
    }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 4

        Text {
            text: root.iconFor(root.player?.identity)
            color: root.playing ? Theme.fg : Theme.dim
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
        }

        Text {
            width: 150
            text: root.player ? (root.player.trackTitle || "—") : ""
            elide: Text.ElideRight
            color: root.playing ? Theme.fg : Theme.dim
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
        }
    }

    Rectangle {
        anchors.bottom: parent.bottom
        width: root.len > 0 ? parent.width * Math.max(0, Math.min(1, root.displayPos / root.len)) : 0
        height: 2
        color: Theme.accent
        opacity: root.hasPlayer ? 0.85 : 0

        Behavior on width {
            NumberAnimation {
                duration: 500
                easing.type: Easing.Linear
            }
        }
    }

    Popover {
        key: "media"
        trigger: root

        content: Component {
            Card {
                implicitWidth: 440
                title: "Mídia"

                Item {
                    width: parent.width
                    implicitHeight: 76

                    Rectangle {
                        id: artBox
                        width: 72
                        height: 72
                        color: Theme.hover

                        Image {
                            id: cover
                            anchors.fill: parent
                            source: root.player?.trackArtUrl ?? ""
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            visible: status === Image.Ready
                            opacity: status === Image.Ready ? 1 : 0
                            Behavior on opacity { Anim { type: Anim.FastEffects } }
                        }

                        Text {
                            anchors.centerIn: parent
                            text: root.iconFor(root.player?.identity)
                            visible: cover.status !== Image.Ready
                            color: Theme.fg
                            font.family: Theme.fontFamily
                            font.pixelSize: 22
                        }
                    }

                    Column {
                        x: 84
                        width: parent.width - 84
                        spacing: 3

                        Text {
                            width: parent.width
                            text: root.player?.trackTitle || "—"
                            elide: Text.ElideRight
                            color: Theme.fg
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSize
                            font.bold: true
                        }

                        Text {
                            width: parent.width
                            text: root.player?.trackArtist ?? ""
                            elide: Text.ElideRight
                            color: Theme.dim
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSize
                        }

                        Text {
                            width: parent.width
                            text: root.player?.trackAlbum ?? ""
                            elide: Text.ElideRight
                            color: Theme.faint
                            font.family: Theme.fontFamily
                            font.pixelSize: 11
                        }
                    }
                }

                Column {
                    visible: Lyrics.lines.length > 0
                    width: parent.width
                    spacing: 2

                    Text {
                        width: parent.width
                        text: root.lyricIndex >= 0 ? Lyrics.lines[root.lyricIndex].text : ""
                        elide: Text.ElideRight
                        color: Theme.fg
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize
                        font.bold: true
                    }

                    Text {
                        width: parent.width
                        text: root.lyricIndex + 1 < Lyrics.lines.length ? Lyrics.lines[root.lyricIndex + 1].text : ""
                        elide: Text.ElideRight
                        color: Theme.dim
                        font.family: Theme.fontFamily
                        font.pixelSize: 11
                    }
                }

                Item {
                    width: parent.width
                    implicitHeight: 36

                    Slider {
                        id: seek
                        anchors.top: parent.top
                        width: parent.width
                        enabled: root.player ? root.player.canSeek : false
                        value: root.len > 0 ? Math.max(0, Math.min(1, root.displayPos / root.len)) : 0
                        onMoved: v => root.seekPos = v * root.len
                        onPressedChanged: {
                            if (!pressed && root.seekPos >= 0) {
                                if (root.player && root.player.canSeek)
                                    root.player.seek(root.seekPos - root.normalizedPos)
                                seekHold.restart()
                            }
                        }
                    }

                    Row {
                        anchors.top: seek.bottom
                        anchors.topMargin: 2
                        width: parent.width

                        Text {
                            text: root.fmt(root.displayPos)
                            color: Theme.faint
                            font.family: Theme.fontFamily
                            font.pixelSize: 11
                        }

                        Item {
                            width: parent.width - 80
                            height: 1
                        }

                        Text {
                            text: root.fmt(root.len)
                            color: Theme.faint
                            font.family: Theme.fontFamily
                            font.pixelSize: 11
                        }
                    }
                }

                Item {
                    width: parent.width
                    implicitHeight: 30

                    Row {
                        anchors.centerIn: parent
                        spacing: 22

                        Text {
                            text: "\uf074"
                            visible: root.player?.shuffleSupported ?? false
                            color: root.player?.shuffle ? Theme.fg : Theme.dim
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSize
                            MouseArea {
                                anchors.fill: parent
                                anchors.margins: -6
                                cursorShape: Qt.PointingHandCursor
                                onClicked: if (root.player) root.player.shuffle = !root.player.shuffle
                            }
                        }

                        Text {
                            text: "\uf048"
                            color: Theme.fg
                            font.family: Theme.fontFamily
                            font.pixelSize: 15
                            MouseArea {
                                anchors.fill: parent
                                anchors.margins: -6
                                cursorShape: Qt.PointingHandCursor
                                onClicked: if (root.player) root.player.previous()
                            }
                        }

                        Text {
                            text: root.playing ? "\uf04c" : "\uf04b"
                            color: Theme.fg
                            font.family: Theme.fontFamily
                            font.pixelSize: 17
                            MouseArea {
                                anchors.fill: parent
                                anchors.margins: -6
                                cursorShape: Qt.PointingHandCursor
                                onClicked: if (root.player) root.player.togglePlaying()
                            }
                        }

                        Text {
                            text: "\uf051"
                            color: Theme.fg
                            font.family: Theme.fontFamily
                            font.pixelSize: 15
                            MouseArea {
                                anchors.fill: parent
                                anchors.margins: -6
                                cursorShape: Qt.PointingHandCursor
                                onClicked: if (root.player) root.player.next()
                            }
                        }

                        Text {
                            text: "\uf01e"
                            visible: root.player?.loopSupported ?? false
                            color: root.player && root.player.loopState !== 0 ? Theme.fg : Theme.dim
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSize
                            MouseArea {
                                anchors.fill: parent
                                anchors.margins: -6
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.cycleLoop()
                            }
                        }
                    }
                }

                Row {
                    visible: root.playersByFirstIdentity.length > 1
                    spacing: 10

                    Repeater {
                        model: root.playersByFirstIdentity

                        Text {
                            required property var modelData
                            text: modelData.identity
                            color: modelData.identity === root.player?.identity ? Theme.fg : Theme.dim
                            font.family: Theme.fontFamily
                            font.pixelSize: 11
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.pinned = modelData
                            }
                        }
                    }
                }
            }
        }
    }
}
