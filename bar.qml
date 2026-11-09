import Quickshell
import Quickshell.Io
import Quickshell.Networking
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower
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

            Meter {
                id: cpuMeter
                name: "CPU"
                symbol: "<>"
                value: "000%"
                percentage: 0

                property real lastCpuTotal: 0
                property real lastCpuIdle: 0

                visible: Settings.modules.cpu.enabled

                function sample(line: string): void {
                    const parts = line.trim().split(/\s+/);
                    if (parts[0] !== "cpu") {
                        return;
                    }

                    const idle = parseInt(parts[4]) + parseInt(parts[5]);
                    const total = parts.slice(1, 8).reduce((a, b) => a + parseInt(b), 0);

                    if (cpuMeter.lastCpuTotal > 0 && total > cpuMeter.lastCpuTotal) {
                        const cpuUsage = Math.round(100 * (1 - (idle - cpuMeter.lastCpuIdle) / (total - cpuMeter.lastCpuTotal)));

                        cpuMeter.percentage = cpuUsage;
                        cpuMeter.value = cpuUsage.toString().padStart(3, "0") + "%";
                    }

                    cpuMeter.lastCpuTotal = total;
                    cpuMeter.lastCpuIdle = idle;
                }

                FileView {
                    id: cpuStat
                    path: "/proc/stat"
                    onLoaded: cpuMeter.sample(text().split("\n")[0])
                }

                Timer {
                    interval: Settings.pollInterval(Settings.modules.cpu.interval, 2) * 1000
                    running: cpuMeter.visible
                    repeat: true
                    onTriggered: cpuStat.reload()
                }
            }
            Divider {
                visible: cpuMeter.visible
            }
            Meter {
                id: memMeter
                name: "MEM"
                symbol: "##"
                value: "0.0G"
                percentage: 0

                visible: Settings.modules.memory.enabled

                // same as free(1): used = total - available
                function sample(meminfo: string): void {
                    const total = parseInt(meminfo.match(/^MemTotal:\s+(\d+)/m)?.[1] ?? "0");
                    const available = parseInt(meminfo.match(/^MemAvailable:\s+(\d+)/m)?.[1] ?? "0");

                    if (total <= 0) {
                        return;
                    }

                    const used = total - available;

                    memMeter.percentage = Math.round((used / total) * 100);
                    memMeter.value = (used / 1024 / 1024).toFixed(1) + "G";
                }

                FileView {
                    id: memInfo
                    path: "/proc/meminfo"
                    onLoaded: memMeter.sample(text())
                }

                Timer {
                    interval: Settings.pollInterval(Settings.modules.memory.interval, 1) * 1000
                    running: memMeter.visible
                    repeat: true
                    onTriggered: memInfo.reload()
                }
            }
            Divider {
                visible: memMeter.visible
            }
            Meter {
                id: batMeter

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

            SimpleSegment {
                id: netSegment

                readonly property bool linked: text !== "OFFLINE"

                visible: Settings.modules.network.enabled
                interactive: true
                live: linked
                onClicked: Quickshell.execDetached(["sh", "-c", Settings.modules.network.command])

                icon: SignalIcon {
                    anchors.fill: parent
                    linked: netSegment.linked
                    color: netSegment.inkColor
                }

                text: {
                    let ssid = "";
                    let hasWifi = false;
                    let hasWired = false;

                    for (let i = 0; i < Networking.devices.values.length; i++) {
                        const device = Networking.devices.values[i];

                        if (device.type === DeviceType.None && device.connected) {
                            hasWired = true;
                            break;
                        }

                        if (device.type === DeviceType.Wifi && device.connected) {
                            hasWifi = true;
                            const connectedNetwork = device.networks.values.find(n => n.connected);

                            const wifiRegex = /([-_ ]?[25](?:\.4)?g)/gi;
                            ssid = (connectedNetwork?.name || "").toUpperCase().replace(wifiRegex, "");

                            const delimiterRegex = /[-_ ]/g;
                            ssid = ssid.replace(delimiterRegex, "").padEnd(7, "_");

                            ssid = ssid.length > 7 ? ssid.slice(-7) : ssid;
                        }
                    }

                    if (hasWired)
                        return "-WIRED-";

                    if (hasWifi && ssid !== "") {
                        return ssid;
                    }

                    return "OFFLINE";
                }
            }

            Divider {
                visible: netSegment.visible && (userSegment.visible || Settings.modules.status.enabled)
            }

            SimpleSegment {
                id: userSegment
                visible: Settings.modules.user.enabled
                text: (Settings.modules.user.label || Quickshell.env("USER")).toUpperCase()

                icon: Text {
                    anchors.centerIn: parent
                    anchors.verticalCenterOffset: -1  // optical nudge: glyph sits low in its line box

                    text: "▨"
                    color: userSegment.inkColor
                    font.pixelSize: Theme.fontSizeLg
                    font.family: Theme.fontInsider
                    font.weight: Theme.fontWeightBold
                }
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
