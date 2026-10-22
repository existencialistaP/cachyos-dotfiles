pragma Singleton

import QtQuick
import Quickshell
import Niri

// Ponte única com o niri. Usa o plugin qml-niri para overview/layout e o
// event stream para as listas (o modelo de janelas não expõe get(index)).
Singleton {
    id: root

    property var winList: []
    property var wsList: []
    property int focusedId: -1
    property string lastTitle: ""
    property string lastAppId: ""

    readonly property bool overviewOpen: niri.overview.isOpen
    readonly property string keyboardLayout: niri.keyboardLayouts.currentName

    readonly property var focusedWin: {
        for (const w of winList)
            if (w.id === focusedId)
                return w
        return null
    }
    readonly property string title: focusedWin && focusedWin.title ? focusedWin.title : lastTitle
    readonly property string appId: focusedWin && focusedWin.appId ? focusedWin.appId : lastAppId

    Niri {
        id: niri
        Component.onCompleted: connect()
        onRawEventReceived: event => root.handle(event)
    }

    onFocusedWinChanged: {
        if (focusedWin) {
            lastTitle = focusedWin.title ?? ""
            lastAppId = focusedWin.appId ?? ""
        }
    }

    function handle(event) {
        const type = Object.keys(event)[0]
        if (!type)
            return
        const data = event[type]

        switch (type) {
        case "WindowsChanged":
            winList = data.windows ?? []
            syncFocus()
            break
        case "WindowOpenedOrChanged": {
            const w = data.window
            if (!w)
                break
            const next = []
            let found = false
            for (const x of winList) {
                if (x.id === w.id) {
                    next.push(w)
                    found = true
                } else {
                    next.push(x)
                }
            }
            if (!found)
                next.push(w)
            winList = next
            syncFocus()
            break
        }
        case "WindowClosed":
            winList = winList.filter(w => w.id !== data.id)
            syncFocus()
            break
        case "WindowFocusChanged":
            focusedId = (data.id === null || data.id === undefined) ? -1 : data.id
            if (focusedId >= 0) {
                const w = winList.find(x => x.id === focusedId)
                if (w) {
                    lastTitle = w.title ?? ""
                    lastAppId = w.appId ?? ""
                }
            }
            break
        case "WorkspacesChanged":
            wsList = data.workspaces ?? []
            break
        case "WorkspaceActivated": {
            const target = wsList.find(w => w.id === data.id)
            if (!target)
                break
            wsList = wsList.map(w => {
                if (w.output === target.output)
                    return Object.assign({}, w, { is_active: w.id === data.id })
                if (data.focused)
                    return Object.assign({}, w, { is_focused: w.id === data.id })
                return w
            })
            break
        }
        }
    }

    function syncFocus() {
        let id = -1
        let title = ""
        let appId = ""
        for (const w of winList) {
            if (w.is_focused) {
                id = w.id
                title = w.title ?? ""
                appId = w.appId ?? ""
            }
        }
        focusedId = id
        if (id >= 0) {
            lastTitle = title
            lastAppId = appId
        }
    }

    function windowCount(wsId) {
        let n = 0
        for (const w of winList)
            if (w.workspace_id === wsId)
                n++
        return n
    }

    function focusWorkspace(id) {
        niri.focusWorkspaceById(id)
    }

    function focusWindow(id) {
        niri.focusWindow(id)
    }
}
