pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts

import qs.common
import qs.bar.components
import qs.bar.services

// Process menu dropped from the CPU or MEM meter: the meter's reading as a readout (profiler
// pattern), then the heaviest processes from ProcessMonitor as a ruled table, the ones over
// the threshold with their value in warning.
BarPopup {
    id: root

    // "cpu" or "memory": which list, and how its values read
    property string metric: "cpu"
    // the big reading, the label beside it, and labelled facts under it ({ label, value })
    property string readout: ""
    property string caption: ""
    property var facts: []

    readonly property bool isCpu: metric === "cpu"
    readonly property var processes: isCpu ? ProcessMonitor.cpuTop : ProcessMonitor.memoryTop
    readonly property int flaggedCount: isCpu ? ProcessMonitor.cpuFlagged : ProcessMonitor.memoryFlagged

    status: flaggedCount > 0 ? flaggedCount.toString().padStart(2, "0") + " FLAGGED" : "NOMINAL"

    // KiB → "512M" / "1.2G"
    function size(kb: real): string {
        return kb >= 1024 * 1024 ? (kb / 1024 / 1024).toFixed(1) + "G" : Math.round(kb / 1024) + "M";
    }

    function reading(process: var): string {
        return isCpu ? Math.round(process.cpu).toString().padStart(3, "0") + "%" : size(process.memory);
    }

    // a table row: name and pid on the left, the reading on the right
    component ProcessRow: RowLayout {
        id: row

        required property var modelData

        Layout.fillWidth: true
        spacing: Theme.spaceSm

        ColumnLayout {
            Layout.fillWidth: true
            spacing: Theme.space2xs

            PopupValue {
                Layout.fillWidth: true
                elide: Text.ElideRight
                text: row.modelData.name
            }

            PopupMicroLabel {
                text: "PID " + row.modelData.pid + (row.modelData.flagged ? ". FLAGGED" : "")
            }
        }

        PopupValue {
            Layout.alignment: Qt.AlignTop
            text: root.reading(row.modelData)
            color: row.modelData.flagged ? Theme.warning : Theme.textPrimary
        }
    }

    // the meter's reading
    ColumnLayout {
        Layout.fillWidth: true
        Layout.margins: Theme.spaceMd
        spacing: Theme.spaceXs

        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.spaceSm

            Text {
                text: root.readout
                color: Theme.textPrimary
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
                text: root.caption
            }
        }

        PopupRule {}

        Repeater {
            model: root.facts
            delegate: PopupFact {
                required property var modelData
                label: modelData.label
                value: modelData.value
            }
        }
    }

    PopupRule {}

    // heaviest processes
    ColumnLayout {
        Layout.fillWidth: true
        Layout.margins: Theme.spaceMd
        spacing: Theme.spaceXs

        RowLayout {
            Layout.fillWidth: true

            PopupLabel {
                text: "TOP PROCESSES"
            }

            Item {
                Layout.fillWidth: true
            }

            PopupLabel {
                text: root.isCpu ? "% CORE" : "RESIDENT"
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: Theme.spaceSm

            Repeater {
                model: root.processes
                delegate: ProcessRow {}
            }
        }

        PopupMicroLabel {
            visible: root.processes.length === 0
            text: "SAMPLING"
        }
    }
}
