pragma Singleton

import Quickshell

Singleton {
    id: root

    property bool active: false

    function toggle() {
        active = !active
    }
}
