import QtQuick
import qs.services

Rectangle {
    id: root

    property string title: ""
    default property alias body: bodyColumn.data

    implicitWidth: Theme.cardWidth + 40
    implicitHeight: column.implicitHeight + Theme.cardPad * 2
    color: Theme.bg
    radius: 0

    Column {
        id: column
        x: Theme.cardPad
        y: Theme.cardPad
        width: parent.width - Theme.cardPad * 2
        spacing: 6

        Text {
            visible: root.title !== ""
            text: root.title
            color: Theme.fg
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
            font.bold: true
        }

        Rectangle {
            visible: root.title !== ""
            width: parent.width
            height: 1
            color: Theme.line
        }

        Column {
            id: bodyColumn
            width: parent.width
            spacing: 2
        }
    }
}
