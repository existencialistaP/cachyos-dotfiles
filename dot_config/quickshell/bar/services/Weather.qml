pragma Singleton

import QtQuick
import Quickshell

Singleton {
    id: root

    property bool ready: false
    property int tempC: 0
    property int feelsLike: 0
    property int code: 0
    property string desc: ""
    property string city: ""

    readonly property string icon: iconFor(code)

    function iconFor(c) {
        if ([113].indexOf(c) >= 0) return "\uf185"
        if ([200, 386, 389].indexOf(c) >= 0) return "\uf0e7"
        if ([179, 182, 185, 227, 230, 323, 326, 329, 332, 335, 338, 368, 371].indexOf(c) >= 0) return "\uf2dc"
        if ([176, 263, 266, 293, 296, 299, 302, 305, 308, 353, 356, 359].indexOf(c) >= 0) return "\uf043"
        return "\uf0c2"
    }

    Timer {
        interval: 1800000
        running: true
        repeat: true
        onTriggered: root.fetch()
    }

    Component.onCompleted: fetch()

    function fetch() {
        const xhr = new XMLHttpRequest()
        xhr.open("GET", "https://wttr.in/?format=j1")
        xhr.timeout = 12000
        xhr.onreadystatechange = () => {
            if (xhr.readyState !== XMLHttpRequest.DONE)
                return
            if (xhr.status !== 200)
                return
            try {
                const data = JSON.parse(xhr.responseText)
                const current = data.current_condition[0]
                root.tempC = parseInt(current.temp_C)
                root.feelsLike = parseInt(current.FeelsLikeC)
                root.code = parseInt(current.weatherCode)
                root.desc = current.weatherDesc[0].value
                root.city = data.nearest_area[0].areaName[0].value
                root.ready = true
            } catch (e) {
                // mantém o último valor
            }
        }
        xhr.send()
    }
}
