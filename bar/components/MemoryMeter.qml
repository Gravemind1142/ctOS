import QtQuick

import Quickshell.Io

import qs.common
import qs.bar.components
import qs.bar.config
import qs.bar.services

// Meter for memory in use, from /proc/meminfo (same as free(1): used = total - available).
// The symbol turns to a warning `!!` while a process holds more than the threshold; click
// for the process menu, brackets held while it is open.
Meter {
    id: root

    // KiB
    property real total: 0
    property real available: 0
    property real swapTotal: 0
    property real swapFree: 0

    name: "MEM"
    symbol: "##"
    value: "0.0G"
    percentage: 0
    flagged: ProcessMonitor.memoryFlagged > 0

    interactive: true
    marked: hovered || menu.visible
    onClicked: menu.toggle()

    function field(meminfo: string, name: string): real {
        return parseInt(meminfo.match(new RegExp("^" + name + ":\\s+(\\d+)", "m"))?.[1] ?? "0");
    }

    function sample(meminfo: string): void {
        const total = field(meminfo, "MemTotal");
        if (total <= 0) {
            return;
        }

        root.total = total;
        root.available = field(meminfo, "MemAvailable");
        root.swapTotal = field(meminfo, "SwapTotal");
        root.swapFree = field(meminfo, "SwapFree");

        const used = total - root.available;
        root.percentage = Math.round((used / total) * 100);
        root.value = (used / 1024 / 1024).toFixed(1) + "G";
    }

    FileView {
        id: meminfo
        path: "/proc/meminfo"
        onLoaded: root.sample(text())
    }

    Timer {
        interval: Settings.pollInterval(Settings.modules.memory.interval, 1) * 1000
        running: root.visible
        repeat: true
        onTriggered: meminfo.reload()
    }

    ProcessMenu {
        id: menu
        segment: root
        metric: "memory"
        title: "MEMORY"
        readout: root.value
        caption: "OF " + menu.size(root.total)
        facts: [
            {
                label: "AVAILABLE",
                value: menu.size(root.available)
            },
            {
                label: "SWAP",
                value: root.swapTotal > 0 ? menu.size(root.swapTotal - root.swapFree) + " / " + menu.size(root.swapTotal) : "NONE"
            }
        ]
    }
}
