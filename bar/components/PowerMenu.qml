pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts

import Quickshell.Services.UPower

import qs.common
import qs.bar.components

// Power menu dropped from the battery segment: a battery readout (profiler pattern) and the
// power-profiles-daemon profile as a list, the active one an inverted block.
BarPopup {
    id: root

    property UPowerDevice device: UPower.displayDevice
    // below this the level reads as a warning while draining
    property int lowLevel: 20

    readonly property int level: Math.round((device?.percentage ?? 0) * 100)
    readonly property int deviceState: device?.state ?? UPowerDeviceState.Unknown
    readonly property bool charging: deviceState === UPowerDeviceState.Charging || deviceState === UPowerDeviceState.PendingCharge
    readonly property bool full: deviceState === UPowerDeviceState.FullyCharged

    title: "POWER"
    status: stateLabel()

    // seconds → "hh:mm", padded so the readout doesn't jitter
    function duration(seconds: real): string {
        if (!(seconds > 0)) {
            return "--:--";
        }
        const minutes = Math.round(seconds / 60);
        return Math.floor(minutes / 60).toString().padStart(2, "0") + ":" + (minutes % 60).toString().padStart(2, "0");
    }

    function stateLabel(): string {
        switch (deviceState) {
        case UPowerDeviceState.Charging:
            return "CHARGING";
        case UPowerDeviceState.Discharging:
            return "DISCHARGING";
        case UPowerDeviceState.FullyCharged:
            return "FULL";
        case UPowerDeviceState.PendingCharge:
            return "CHARGE PENDING";
        case UPowerDeviceState.PendingDischarge:
        case UPowerDeviceState.Empty:
            return "ON AC";
        default:
            return "UNKNOWN";
        }
    }

    function degradation(): string {
        switch (PowerProfiles.degradationReason) {
        case PerformanceDegradationReason.LapDetected:
            return "DEGRADED. LAP DETECTED";
        case PerformanceDegradationReason.HighTemperature:
            return "DEGRADED. HIGH TEMP";
        default:
            return "";
        }
    }

    // a list row: name and a micro label under it; selected is an inverted block
    component ProfileRow: Rectangle {
        id: row

        required property int profile
        required property string name
        required property string detail

        readonly property bool selected: PowerProfiles.profile === profile
        readonly property color ink: selected ? Theme.labelText : Theme.textPrimary

        Layout.fillWidth: true
        implicitHeight: rowContent.implicitHeight + 2 * Theme.spaceXs
        color: selected ? Theme.labelFill : rowHover.hovered ? Theme.surfaceRaised : "transparent"

        ColumnLayout {
            id: rowContent

            anchors {
                left: parent.left
                right: parent.right
                verticalCenter: parent.verticalCenter
                leftMargin: Theme.controlPadding
                rightMargin: Theme.controlPadding
            }
            spacing: Theme.space2xs

            PopupValue {
                text: row.name
                color: row.ink
            }

            PopupMicroLabel {
                text: row.detail
                color: row.selected ? Theme.labelText : Theme.textPrimaryDimmer
            }
        }

        HoverHandler {
            id: rowHover
            cursorShape: row.selected ? Qt.ArrowCursor : Qt.PointingHandCursor
        }

        TapHandler {
            onTapped: PowerProfiles.profile = row.profile
        }
    }

    // battery readout
    ColumnLayout {
        Layout.fillWidth: true
        Layout.margins: Theme.spaceMd
        spacing: Theme.spaceXs

        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.spaceSm

            Text {
                text: root.level.toString().padStart(3, "0") + "%"
                color: root.level < root.lowLevel && !root.charging && !root.full ? Theme.warning : Theme.textPrimary
                font {
                    family: Theme.fontInsider
                    pixelSize: Theme.fontSizeXl
                    weight: Theme.fontWeightBold
                }
            }

            Item {
                Layout.fillWidth: true
            }

            PopupLabel {
                Layout.alignment: Qt.AlignBottom
                Layout.bottomMargin: Theme.space2xs
                text: root.device?.model ? root.device.model.toUpperCase() : "BATTERY"
                elide: Text.ElideLeft
                Layout.maximumWidth: Theme.popupWidth / 2
            }
        }

        PopupRule {}

        PopupFact {
            label: root.charging ? "TIME TO FULL" : "TIME TO EMPTY"
            value: root.duration(root.charging ? root.device?.timeToFull ?? 0 : root.device?.timeToEmpty ?? 0)
        }

        PopupFact {
            label: "DRAW"
            value: Math.abs(root.device?.changeRate ?? 0).toFixed(1).padStart(4, "0") + " W"
        }

        PopupFact {
            visible: !!root.device?.healthSupported
            label: "HEALTH"
            value: Math.round(root.device?.healthPercentage ?? 0).toString().padStart(3, "0") + "%"
        }
    }

    PopupRule {}

    // power profile
    ColumnLayout {
        Layout.fillWidth: true
        Layout.margins: Theme.spaceMd
        spacing: Theme.spaceXs

        PopupLabel {
            text: "PROFILE"
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            ProfileRow {
                profile: PowerProfile.PowerSaver
                name: "Saver"
                detail: "EXTENDED RUNTIME"
            }

            ProfileRow {
                profile: PowerProfile.Balanced
                name: "Balanced"
                detail: "DEFAULT"
            }

            ProfileRow {
                visible: PowerProfiles.hasPerformanceProfile
                profile: PowerProfile.Performance
                name: "Performance"
                detail: root.degradation() || "MAXIMUM OUTPUT"
            }
        }
    }
}
