pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts

import Quickshell
import Quickshell.Services.UPower

import qs.common

// Power menu dropped from the battery segment: a battery readout (profiler pattern) and the
// power-profiles-daemon profile as a list, the active one an inverted block. Tiles onto the
// bar's bottom edge, under the segment that opened it. Click outside or Escape to close.
PopupWindow {
    id: root

    // the segment it hangs from
    required property Item segment
    property UPowerDevice device: UPower.displayDevice
    // below this the level reads as a warning while draining
    property int lowLevel: 20

    readonly property int level: Math.round((device?.percentage ?? 0) * 100)
    readonly property int deviceState: device?.state ?? UPowerDeviceState.Unknown
    readonly property bool charging: deviceState === UPowerDeviceState.Charging || deviceState === UPowerDeviceState.PendingCharge
    readonly property bool full: deviceState === UPowerDeviceState.FullyCharged

    // when it last closed: the click outside that dismisses it can land on the segment too
    property real closedAt: 0

    function toggle(): void {
        if (!visible && Date.now() - closedAt < Theme.durationMedium) {
            return;
        }
        visible = !visible;
    }

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

    anchor {
        item: segment
        // overlap the bar's border so the two frames share one rule
        rect.y: segment.height - Theme.strokeHairline
        edges: Edges.Top | Edges.Left
        gravity: Edges.Bottom | Edges.Right
    }

    implicitWidth: Theme.popupWidth
    implicitHeight: panel.height
    color: "transparent"
    grabFocus: true

    onVisibleChanged: {
        if (visible) {
            reveal.restart();
        } else {
            closedAt = Date.now();
        }
    }

    component Label: Text {
        color: Theme.textPrimaryDim
        font {
            family: Theme.fontInsider
            pixelSize: Theme.fontSizeXs
            weight: Theme.fontWeightBold
            letterSpacing: Theme.trackingLabel
        }
    }

    component Value: Text {
        color: Theme.textPrimary
        font {
            family: Theme.fontInsider
            pixelSize: Theme.fontSizeSm
            weight: Theme.fontWeightMedium
        }
    }

    component Rule: Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: Theme.strokeHairline
        color: Theme.frameSubtle
    }

    // label on the left, value on the right
    component Fact: RowLayout {
        property alias label: label.text
        property alias value: value.text

        Layout.fillWidth: true
        spacing: Theme.spaceSm

        Label {
            id: label
        }

        Item {
            Layout.fillWidth: true
        }

        Value {
            id: value
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

            Value {
                text: row.name
                color: row.ink
            }

            Text {
                Layout.fillWidth: true
                elide: Text.ElideRight
                text: row.detail
                color: row.selected ? Theme.labelText : Theme.textPrimaryDimmer
                font {
                    family: Theme.fontInsider
                    pixelSize: Theme.fontSize2xs
                    letterSpacing: Theme.trackingLabel
                }
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

    // keeps the drop clipped to the popup while it slides in
    Item {
        anchors.fill: parent
        clip: true
        focus: true

        Keys.onEscapePressed: root.visible = false

        Rectangle {
            id: panel

            width: parent.width
            height: body.implicitHeight + 2 * Theme.strokeHairline
            color: Theme.surface
            border {
                width: Theme.strokeHairline
                color: Theme.frame
            }

            NumberAnimation {
                id: reveal
                target: panel
                property: "y"
                from: -panel.height
                to: 0
                duration: Theme.durationShort
                easing.type: Theme.easeEnter
            }

            ColumnLayout {
                id: body

                anchors {
                    left: parent.left
                    right: parent.right
                    top: parent.top
                    margins: Theme.strokeHairline
                }
                spacing: 0

                // label block on the frame's top edge
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: header.implicitHeight + 2 * Theme.spaceXs
                    color: Theme.labelFill

                    RowLayout {
                        id: header
                        anchors {
                            fill: parent
                            leftMargin: Theme.controlPadding
                            rightMargin: Theme.controlPadding
                        }

                        Label {
                            text: "POWER"
                            color: Theme.labelText
                        }

                        Item {
                            Layout.fillWidth: true
                        }

                        Label {
                            text: root.stateLabel()
                            color: Theme.labelText
                        }
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

                        Label {
                            Layout.alignment: Qt.AlignBottom
                            Layout.bottomMargin: Theme.space2xs
                            text: root.device?.model ? root.device.model.toUpperCase() : "BATTERY"
                            elide: Text.ElideLeft
                            Layout.maximumWidth: Theme.popupWidth / 2
                        }
                    }

                    Rule {}

                    Fact {
                        label: root.charging ? "TIME TO FULL" : "TIME TO EMPTY"
                        value: root.duration(root.charging ? root.device?.timeToFull ?? 0 : root.device?.timeToEmpty ?? 0)
                    }

                    Fact {
                        label: "DRAW"
                        value: Math.abs(root.device?.changeRate ?? 0).toFixed(1).padStart(4, "0") + " W"
                    }

                    Fact {
                        visible: !!root.device?.healthSupported
                        label: "HEALTH"
                        value: Math.round(root.device?.healthPercentage ?? 0).toString().padStart(3, "0") + "%"
                    }
                }

                Rule {}

                // power profile
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.margins: Theme.spaceMd
                    spacing: Theme.spaceXs

                    Label {
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
        }
    }
}
