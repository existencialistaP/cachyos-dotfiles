pragma Singleton

import QtQuick
import Quickshell

Singleton {
    id: root

    property string trackKey: ""
    property var lines: []
    property bool loading: false

    function ensure(title, artist, album, duration) {
        const key = (title || "") + "|" + (artist || "") + "|" + (album || "") + "|" + Math.round(duration || 0)
        if (key === trackKey)
            return
        trackKey = key
        lines = []
        if (!title || !artist)
            return
        fetch(title, artist, album, duration)
    }

    function fetch(title, artist, album, duration) {
        loading = true
        const url = "https://lrclib.net/api/get"
            + "?artist_name=" + encodeURIComponent(artist)
            + "&track_name=" + encodeURIComponent(title)
            + (album ? "&album_name=" + encodeURIComponent(album) : "")
            + (duration > 0 ? "&duration=" + Math.round(duration) : "")

        const xhr = new XMLHttpRequest()
        xhr.open("GET", url)
        xhr.timeout = 10000
        xhr.onreadystatechange = () => {
            if (xhr.readyState !== XMLHttpRequest.DONE)
                return
            root.loading = false
            if (xhr.status !== 200)
                return
            try {
                const data = JSON.parse(xhr.responseText)
                root.lines = root.parse(data.syncedLyrics || "")
            } catch (e) {
                root.lines = []
            }
        }
        xhr.send()
    }

    function parse(lrc) {
        const out = []
        for (const raw of lrc.split("\n")) {
            // aceita [mm:ss.xx], [mm:ss:xx] e [mm:ss]; ignora metadados [ar:...]
            const match = raw.match(/^\[(\d+):(\d{1,2})(?:[.:](\d{1,3}))?\](.*)$/)
            if (!match)
                continue
            const text = match[4].trim()
            if (text === "")
                continue
            const fraction = match[3] ? parseInt(match[3].padEnd(3, "0")) / 1000 : 0
            out.push({
                t: parseInt(match[1]) * 60 + parseInt(match[2]) + fraction,
                text: text
            })
        }
        out.sort((a, b) => a.t - b.t)
        return out
    }

    function indexAt(position) {
        let index = -1
        for (let i = 0; i < lines.length; i++) {
            if (lines[i].t <= position)
                index = i
            else
                break
        }
        return index
    }
}
