import QtQuick

import Quickshell.Services.UPower

import qs.common
import qs.bar.components

// Meter for the laptop battery (`++` charging, `--` draining). Click for the power menu;
// the brackets hold while it is open.
Meter {
    id: root

    readonly property UPowerDevice device: UPower.displayDevice
    readonly property int level: Math.round((device?.percentage ?? 0) * 100)
    readonly property bool charging: device?.state === UPowerDeviceState.Charging || device?.state === UPowerDeviceState.FullyCharged || device?.state === UPowerDeviceState.PendingCharge
    readonly property int lowLevel: 20

    name: "BAT"
    symbol: charging ? "++" : "--"
    value: level.toString().padStart(3, "0") + "%"
    percentage: level
    // level bar: warning when low and draining, success when full
    fillColor: level >= 100 ? Theme.success : (level < lowLevel && !charging ? Theme.warning : Theme.textPrimary)

    interactive: true
    marked: hovered || menu.visible

    onClicked: menu.toggle()

    PowerMenu {
        id: menu
        segment: root
        device: root.device
        lowLevel: root.lowLevel
    }
}
