import QtQuick

import Quickshell.Io

import qs.common
import qs.bar.components
import qs.bar.config
import qs.bar.services

// Meter for total CPU load, from /proc/stat. The symbol turns to a warning `!!` while a
// process holds a core over the threshold; click for the process menu, brackets held while
// it is open.
Meter {
    id: root

    property real lastTotal: 0
    property real lastIdle: 0

    name: "CPU"
    symbol: "<>"
    value: "000%"
    percentage: 0
    flagged: ProcessMonitor.cpuFlagged > 0

    interactive: true
    marked: hovered || menu.visible
    onClicked: menu.toggle()

    function sample(line: string): void {
        const parts = line.trim().split(/\s+/);
        if (parts[0] !== "cpu") {
            return;
        }

        const idle = parseInt(parts[4]) + parseInt(parts[5]);
        const total = parts.slice(1, 8).reduce((a, b) => a + parseInt(b), 0);

        if (root.lastTotal > 0 && total > root.lastTotal) {
            const usage = Math.round(100 * (1 - (idle - root.lastIdle) / (total - root.lastTotal)));

            root.percentage = usage;
            root.value = usage.toString().padStart(3, "0") + "%";
        }

        root.lastTotal = total;
        root.lastIdle = idle;
    }

    FileView {
        id: stat
        path: "/proc/stat"
        onLoaded: root.sample(text().split("\n")[0])
    }

    Timer {
        interval: Settings.pollInterval(Settings.modules.cpu.interval, 2) * 1000
        running: root.visible
        repeat: true
        onTriggered: stat.reload()
    }

    ProcessMenu {
        id: menu
        segment: root
        metric: "cpu"
        title: "CPU"
        readout: root.value
        caption: ProcessMonitor.cores + " CORES"
        facts: [
            {
                label: "LOAD AVG",
                value: ProcessMonitor.loadAverage
            },
            {
                label: "RUNNING",
                value: ProcessMonitor.processCount.toString()
            }
        ]
    }
}
