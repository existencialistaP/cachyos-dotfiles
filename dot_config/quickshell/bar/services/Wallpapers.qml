pragma Singleton

import Quickshell

Singleton {
    id: root

    property bool open: false

    function toggle() {
        open = !open
    }

    function close() {
        open = false
    }

    function apply(pathOrUrl) {
        let path = String(pathOrUrl)
        if (path.indexOf("file://") === 0)
            path = decodeURIComponent(path.replace(/^file:\/\//, ""))
        Quickshell.execDetached(["waypaper", "--wallpaper", path])
        close()
    }
}
