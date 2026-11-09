import Quickshell
import Quickshell.Services.Pipewire
import Quickshell.Services.SystemTray
import QtQuick
import QtQuick.Layouts

import qs.common
import qs.common.components
import qs.bar.components
import qs.bar.config

// qmllint disable
PanelWindow {
    id: root

    screen: Settings.screen

    color: Theme.background
    focusable: true

    implicitHeight: Theme.barHeight

    anchors {
        top: true
        right: true
        left: true
    }

    Rectangle {
        anchors.fill: parent
        border {
            width: Theme.strokeHairline
            color: Theme.frame
        }
        color: "transparent"
    }

    RowLayout {
        anchors.fill: parent
        spacing: 0

        Row {
            Layout.fillHeight: true
            Layout.alignment: Qt.AlignLeft

            SystemLabel {
                anchors.top: parent.top
                anchors.bottom: parent.bottom
            }

            Divider {}

            Workspaces {
                visible: Settings.modules.workspaces.enabled
                count: Settings.workspaceCount
            }

            Tray {
                id: tray
                visible: Settings.modules.tray.enabled && SystemTray.items.values.length > 0
            }
            Divider {
                visible: tray.visible
            }

            CpuMeter {
                id: cpuMeter
                visible: Settings.modules.cpu.enabled
            }
            Divider {
                visible: cpuMeter.visible
            }
            MemoryMeter {
                id: memMeter
                visible: Settings.modules.memory.enabled
            }
            Divider {
                visible: memMeter.visible
            }
            BatteryMeter {
                id: batMeter

                // hidden on desktops, where the display device is not a laptop battery
                visible: Settings.modules.battery.enabled && !!device?.isLaptopBattery
            }
            Divider {
                visible: batMeter.visible
            }
        }

        Item {
            Layout.fillWidth: true
        }

        Row {
            Layout.fillHeight: true
            Layout.alignment: Qt.AlignRight

            // mirrors the rule after the last left-hand segment
            Divider {
                visible: netSegment.visible
            }

            NetworkSegment {
                id: netSegment
                visible: Settings.modules.network.enabled
            }

            Divider {
                visible: netSegment.visible && (userSegment.visible || Settings.modules.status.enabled)
            }

            UserSegment {
                id: userSegment
                visible: Settings.modules.user.enabled
            }

            Divider {
                visible: userSegment.visible && Settings.modules.status.enabled
            }

            Clock {
                visible: Settings.modules.status.enabled
                zone: Settings.modules.status.timezone
            }

            Divider {
                visible: Settings.modules.status.enabled
            }

            AudioMeter {
                visible: Settings.modules.status.enabled
                name: "MIC"
                liveSymbol: "()"
                node: Pipewire.defaultAudioSource
            }

            Divider {
                visible: Settings.modules.status.enabled
            }

            AudioMeter {
                visible: Settings.modules.status.enabled
                name: "VOL"
                liveSymbol: "))"
                node: Pipewire.defaultAudioSink
            }
        }
    }
}
