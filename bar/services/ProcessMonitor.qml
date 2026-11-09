pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

import qs.bar.config

// Samples every process from /proc for the CPU and MEM meters: the heaviest few by CPU and
// by resident memory, and which of them cross the configured thresholds.
//
// CPU is per core, like top: 100% is one core flat out. A process is flagged for CPU only
// when it stays over the threshold for two samples in a row, so launches and short bursts
// don't trip it. Memory is resident set size as a share of physical memory.
Singleton {
    id: root

    // rows kept for each list
    property int topCount: 5

    readonly property bool active: Settings.modules.cpu.enabled || Settings.modules.memory.enabled
    readonly property real cpuThreshold: Settings.modules.cpu.threshold > 0 ? Settings.modules.cpu.threshold : 80
    readonly property real memoryThreshold: Settings.modules.memory.threshold > 0 ? Settings.modules.memory.threshold : 20

    // { pid, name, cpu (% of one core), memory (KiB), memoryShare (% of total), flagged }
    property var cpuTop: []
    property var memoryTop: []
    readonly property int cpuFlagged: cpuTop.filter(p => p.flagged).length
    readonly property int memoryFlagged: memoryTop.filter(p => p.flagged).length

    property int cores: 1
    property int processCount: 0
    property string loadAverage: ""

    // previous sample: total jiffies, and per process (keyed by pid and start time, so a
    // reused pid starts fresh) its jiffies and whether it was over the CPU threshold
    property real _lastTotal: 0
    property var _last: ({})

    function sample(text: string): void {
        const lines = text.split("\n");
        const pageKb = (parseInt(lines[0]) || 4096) / 1024;
        const cores = Math.max(parseInt(lines[1]) || 1, 1);
        // same fields as the CPU meter: user, nice, system, idle, iowait, irq, softirq
        const total = lines[2].trim().split(/\s+/).slice(1, 8).reduce((a, b) => a + parseInt(b), 0);
        const memTotal = parseInt(lines[3].match(/(\d+)/)?.[1] ?? "0");
        const load = lines[4].split(" ").slice(0, 3).join(" ");

        // jiffies of one core over the interval
        const coreSpan = root._lastTotal > 0 && total > root._lastTotal ? (total - root._lastTotal) / cores : 0;
        const seen = {};
        const processes = [];

        for (let i = 5; i < lines.length; i++) {
            const line = lines[i];
            const open = line.indexOf("(");
            const close = line.lastIndexOf(")");
            if (open < 0 || close < open) {
                continue;
            }

            // fields after the name, from field 3 (state): field n is f[n - 3]
            const f = line.slice(close + 2).split(" ");
            const pid = parseInt(line.slice(0, open));
            const key = pid + ":" + f[19];
            const ticks = parseInt(f[11]) + parseInt(f[12]);
            const memory = parseInt(f[21]) * pageKb;

            const last = root._last[key];
            const cpu = last && coreSpan > 0 ? Math.max(0, (ticks - last.ticks) / coreSpan * 100) : 0;
            const over = cpu >= root.cpuThreshold;
            seen[key] = {
                ticks: ticks,
                over: over
            };

            processes.push({
                pid: pid,
                name: line.slice(open + 1, close),
                cpu: cpu,
                cpuFlagged: over && !!last?.over,
                memory: memory,
                memoryShare: memTotal > 0 ? memory / memTotal * 100 : 0
            });
        }

        root._last = seen;
        root._lastTotal = total;
        root.cores = cores;
        root.processCount = processes.length;
        root.loadAverage = load;

        root.cpuTop = processes.filter(p => p.cpu > 0).sort((a, b) => b.cpu - a.cpu).slice(0, root.topCount).map(p => Object.assign({}, p, {
                    flagged: p.cpuFlagged
                }));
        root.memoryTop = processes.sort((a, b) => b.memory - a.memory).slice(0, root.topCount).map(p => Object.assign({}, p, {
                    flagged: p.memoryShare >= root.memoryThreshold
                }));
    }

    Process {
        id: reader

        command: ["sh", "-c", "getconf PAGESIZE; grep -c '^cpu[0-9]' /proc/stat; head -n 1 /proc/stat; grep '^MemTotal:' /proc/meminfo; cat /proc/loadavg; cat /proc/[0-9]*/stat 2>/dev/null"]

        stdout: StdioCollector {
            onStreamFinished: root.sample(text)
        }
    }

    Timer {
        interval: Settings.pollInterval(Settings.modules.cpu.interval, 2) * 1000
        running: root.active
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (!reader.running) {
                reader.running = true;
            }
        }
    }
}
