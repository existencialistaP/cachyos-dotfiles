import QtQuick
import qs.services

Column {
    id: root

    property date today: new Date()

    spacing: 4

    readonly property var days: {
        const year = today.getFullYear()
        const month = today.getMonth()
        const first = new Date(year, month, 1)
        const start = (first.getDay() + 6) % 7 // segunda = 0
        const total = new Date(year, month + 1, 0).getDate()
        const out = []
        for (let i = 0; i < start; i++)
            out.push(0)
        for (let d = 1; d <= total; d++)
            out.push(d)
        return out
    }

    Text {
        text: Qt.formatDateTime(root.today, "MMMM yyyy")
        color: Theme.fg
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSize
        font.bold: true
    }

    Grid {
        columns: 7
        columnSpacing: 2

        Repeater {
            model: ["S", "T", "Q", "Q", "S", "S", "D"]
            Text {
                required property var modelData
                width: 22
                height: 18
                text: modelData
                color: Theme.faint
                horizontalAlignment: Text.AlignHCenter
                font.family: Theme.fontFamily
                font.pixelSize: 11
            }
        }

        Repeater {
            model: root.days
            Text {
                required property var modelData
                width: 22
                height: 18
                text: modelData === 0 ? "" : modelData
                color: modelData === root.today.getDate() ? Theme.pink : Theme.dim
                horizontalAlignment: Text.AlignHCenter
                font.family: Theme.fontFamily
                font.pixelSize: 11
                font.bold: modelData === root.today.getDate()
            }
        }
    }
}
