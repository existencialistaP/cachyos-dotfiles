pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower

Singleton {
    id: root

    readonly property var bat: UPower.displayDevice
    readonly property real pct: bat && bat.percentage !== undefined ? bat.percentage : 0
    readonly property int state: bat ? bat.state : 0

    readonly property bool charging: state === UPowerDeviceState.Charging
        || state === UPowerDeviceState.PendingCharge
    readonly property bool full: state === UPowerDeviceState.FullyCharged

    readonly property string stateLabel: {
        switch (state) {
        case UPowerDeviceState.Charging: return "carregando"
        case UPowerDeviceState.Discharging: return "descarregando"
        case UPowerDeviceState.Empty: return "vazia"
        case UPowerDeviceState.FullyCharged: return "cheia"
        case UPowerDeviceState.PendingCharge: return "carregando"
        case UPowerDeviceState.PendingDischarge: return "descarregando"
        default: return "—"
        }
    }

    readonly property string timeLabel: {
        if (!bat || full)
            return ""
        const seconds = state === UPowerDeviceState.Charging ? bat.timeToFull : bat.timeToEmpty
        if (!seconds || seconds <= 0 || seconds > 86400 * 2)
            return ""
        const h = Math.floor(seconds / 3600)
        const m = Math.floor((seconds % 3600) / 60)
        return (state === UPowerDeviceState.Charging ? "até cheia " : "resta ") + h + "h" + String(m).padStart(2, "0")
    }

    readonly property string healthLabel: bat && bat.healthSupported
        ? Math.round(bat.healthPercentage > 1 ? bat.healthPercentage : bat.healthPercentage * 100) + "%"
        : "—"

    readonly property int profile: PowerProfiles.profile
    readonly property string profileName: {
        switch (profile) {
        case PowerProfile.PowerSaver: return "power-saver"
        case PowerProfile.Performance: return "performance"
        default: return "balanced"
        }
    }

    Process {
        id: setProfileProc
        stdout: StdioCollector {}
    }

    function setProfile(name) {
        setProfileProc.command = ["powerprofilesctl", "set", name]
        setProfileProc.running = true
    }

    function cycleProfile() {
        setProfile(["power-saver", "balanced", "performance"][(profile + 1) % 3])
    }
}
