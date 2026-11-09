pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

// Hyprland's live binds (`hyprctl binds -j`) as cheatsheet groups: [{ title, rows: [{ keys, action }] }].
// A `bindd` description wins: `Group: Action` files the bind under that group, a bare one keeps the
// derived group. Undescribed binds get a label from their dispatcher, and series of them (SUPER+1–0
// to workspaces, arrows to movefocus) collapse into one row. Re-read on config reload and on refresh().
Singleton {
    id: root

    property var groups: []
    // binds read, before series collapse
    property int count: 0

    readonly property var _groupOrder: ["SYSTEM", "APPS", "WINDOWS", "WORKSPACES", "MEDIA"]

    readonly property var _mods: [[64, "SUPER"], [4, "CTRL"], [8, "ALT"], [1, "SHIFT"]]

    readonly property var _keyNames: ({
            "left": "←",
            "right": "→",
            "up": "↑",
            "down": "↓",
            "Print": "PRTSC",
            "Return": "↵",
            "space": "SPACE",
            "Escape": "ESC",
            "Tab": "TAB",
            "slash": "/",
            "question": "?",
            "mouse:272": "LMB",
            "mouse:273": "RMB",
            "mouse:274": "MMB",
            "mouse_down": "WHEEL↓",
            "mouse_up": "WHEEL↑"
        })

    // media keys: [cap, action]
    readonly property var _mediaKeys: ({
            "XF86AudioRaiseVolume": ["VOL+", "VOLUME UP"],
            "XF86AudioLowerVolume": ["VOL-", "VOLUME DOWN"],
            "XF86AudioMute": ["MUTE", "MUTE OUTPUT"],
            "XF86AudioMicMute": ["MIC", "MUTE MIC"],
            "XF86MonBrightnessUp": ["BRT+", "BRIGHTNESS UP"],
            "XF86MonBrightnessDown": ["BRT-", "BRIGHTNESS DOWN"],
            "XF86AudioNext": ["NEXT", "NEXT TRACK"],
            "XF86AudioPrev": ["PREV", "PREVIOUS TRACK"],
            "XF86AudioPlay": ["PLAY", "PLAY / PAUSE"],
            "XF86AudioPause": ["PAUSE", "PLAY / PAUSE"],
            "XF86AudioStop": ["STOP", "STOP"]
        })

    // dispatcher -> [group, action]; the arg is appended where it says which one
    readonly property var _dispatchers: ({
            "killactive": ["WINDOWS", "CLOSE WINDOW"],
            "forcekillactive": ["WINDOWS", "KILL WINDOW"],
            "togglefloating": ["WINDOWS", "TOGGLE FLOATING"],
            "fullscreen": ["WINDOWS", "FULLSCREEN"],
            "pseudo": ["WINDOWS", "PSEUDOTILE"],
            "togglesplit": ["WINDOWS", "TOGGLE SPLIT"],
            "pin": ["WINDOWS", "PIN WINDOW"],
            "centerwindow": ["WINDOWS", "CENTRE WINDOW"],
            "movefocus": ["WINDOWS", "MOVE FOCUS"],
            "movewindow": ["WINDOWS", "MOVE WINDOW"],
            "swapwindow": ["WINDOWS", "SWAP WINDOW"],
            "resizewindow": ["WINDOWS", "RESIZE WINDOW"],
            "resizeactive": ["WINDOWS", "RESIZE WINDOW"],
            "cyclenext": ["WINDOWS", "CYCLE WINDOWS"],
            "togglegroup": ["WINDOWS", "TOGGLE GROUP"],
            "changegroupactive": ["WINDOWS", "CYCLE GROUP"],
            "workspace": ["WORKSPACES", "WORKSPACE"],
            "movetoworkspace": ["WORKSPACES", "SEND TO WORKSPACE"],
            "movetoworkspacesilent": ["WORKSPACES", "SEND TO WORKSPACE"],
            "togglespecialworkspace": ["WORKSPACES", "TOGGLE SCRATCHPAD"],
            "exit": ["SYSTEM", "EXIT SESSION"],
            "dpms": ["SYSTEM", "DISPLAY POWER"]
        })

    // exec commands ctOS knows by name: [pattern, action], first match wins
    readonly property var _commands: [[/ipc call cheatsheet/, "KEYBINDS"], [/\bgrim\b.*\bslurp\b/, "SCREENSHOT REGION"], [/\bgrim\b/, "SCREENSHOT"], [/lock-session|\bhyprlock\b/, "LOCK"], [/hyprshutdown|dispatch exit/, "EXIT SESSION"], [/\bnmtui\b/, "NETWORK"]]

    function refresh(): void {
        reader.running = true;
    }

    function _modNames(mask: int): var {
        return root._mods.filter(m => mask & m[0]).map(m => m[1]);
    }

    function _keyName(key: string): string {
        return root._keyNames[key] ?? key.toUpperCase();
    }

    // which series a key belongs to, so its siblings can share one row
    function _family(key: string): string {
        if (/^[0-9]$/.test(key))
            return "digits";
        if (["left", "right", "up", "down"].includes(key))
            return "arrows";
        if (key === "mouse_up" || key === "mouse_down")
            return "wheel";
        return "";
    }

    // the program an exec runs, past launch wrappers and env assignments
    function _program(command: string): string {
        const words = command.trim().split(/\s+/);
        const skip = ["uwsm", "app", "--", "env", "exec", "setsid"];
        const word = words.find(w => !skip.includes(w) && !w.includes("=") && !w.startsWith("-")) ?? "";
        return word.split("/").pop().toUpperCase();
    }

    function _target(arg: string): string {
        if (arg === "e+1" || arg === "r+1")
            return "NEXT";
        if (arg === "e-1" || arg === "r-1")
            return "PREVIOUS";
        if (arg.startsWith("special"))
            return "";
        return arg.toUpperCase();
    }

    // [group, action] for one bind
    function _describe(bind: var): var {
        if (bind.has_description) {
            const match = bind.description.match(/^([^:]+):\s*(.+)$/);
            const action = (match ? match[2] : bind.description).toUpperCase();
            return [match ? match[1].trim().toUpperCase() : root._describe(Object.assign({}, bind, {
                        has_description: false
                    }))[0], action];
        }

        const media = root._mediaKeys[bind.key];
        if (media)
            return ["MEDIA", media[1]];

        if (bind.dispatcher === "exec") {
            const known = root._commands.find(c => c[0].test(bind.arg));
            return known ? ["SYSTEM", known[1]] : ["APPS", root._program(bind.arg)];
        }

        // bindm: the action is the arg (mouse, movewindow)
        if (bind.dispatcher === "mouse")
            return ["WINDOWS", bind.arg === "resizewindow" ? "DRAG TO RESIZE" : "DRAG TO MOVE"];

        if (bind.arg.startsWith("special") && bind.dispatcher.startsWith("movetoworkspace"))
            return ["WORKSPACES", "SEND TO SCRATCHPAD"];

        const known = root._dispatchers[bind.dispatcher];
        if (!known)
            return ["WINDOWS", `${bind.dispatcher} ${bind.arg}`.trim().toUpperCase()];

        const target = ["movefocus", "movewindow", "swapwindow", "togglespecialworkspace"].includes(bind.dispatcher) ? "" : root._target(bind.arg);
        return [known[0], target ? `${known[1]} ${target}` : known[1]];
    }

    // row for a series: one cap for the keys, the targets as a range
    function _series(binds: var, group: string, action: string): var {
        const family = root._family(binds[0].key);
        let cap;
        let range = "";
        if (family === "digits") {
            // keyboard order: 1 to 9, then 0
            const order = binds.map(b => b.key).sort((a, b) => ((+a || 10) - (+b || 10)));
            cap = `${order[0]}–${order[order.length - 1]}`;
            const targets = binds.map(b => +b.arg).filter(n => !isNaN(n));
            if (targets.length === binds.length)
                range = ` ${Math.min(...targets)}–${Math.max(...targets)}`;
        } else if (family === "arrows") {
            cap = ["left", "up", "down", "right"].filter(k => binds.some(b => b.key === k)).map(root._keyName).join("");
        } else {
            cap = "WHEEL";
        }

        const base = action.replace(/ (NEXT|PREVIOUS|[0-9]+)$/, "");
        return {
            group,
            keys: root._modNames(binds[0].modmask).concat(cap),
            action: family === "wheel" ? `CYCLE ${base}S` : base + range
        };
    }

    function _build(binds: var): void {
        const rows = [];
        const seriesAt = {};

        for (const bind of binds) {
            if (bind.catch_all)
                continue;

            const [group, action] = root._describe(bind);
            const title = bind.submap ? `SUBMAP ${bind.submap.toUpperCase()}` : group;
            const family = bind.has_description ? "" : root._family(bind.key);

            if (family) {
                const id = [bind.submap, bind.modmask, bind.dispatcher, family].join("|");
                if (seriesAt[id] !== undefined) {
                    rows[seriesAt[id]].binds.push(bind);
                    continue;
                }
                seriesAt[id] = rows.length;
            }

            const media = root._mediaKeys[bind.key];
            rows.push({
                group: title,
                action,
                binds: [bind],
                keys: root._modNames(bind.modmask).concat(media ? media[0] : root._keyName(bind.key))
            });
        }

        const byGroup = {};
        for (const row of rows) {
            const entry = row.binds.length > 1 ? root._series(row.binds, row.group, row.action) : row;
            if (!byGroup[entry.group])
                byGroup[entry.group] = [];

            // two keys doing the same thing with the same modifiers share a cap (PLAY/PAUSE)
            const last = byGroup[entry.group][byGroup[entry.group].length - 1];
            const mods = entry.keys.slice(0, -1).join("+");
            if (last && last.action === entry.action && last.keys.slice(0, -1).join("+") === mods) {
                last.keys = last.keys.slice(0, -1).concat(`${last.keys[last.keys.length - 1]}/${entry.keys[entry.keys.length - 1]}`);
                continue;
            }

            byGroup[entry.group].push({
                keys: entry.keys,
                action: entry.action
            });
        }

        const titles = Object.keys(byGroup).sort((a, b) => {
            const ia = root._groupOrder.indexOf(a);
            const ib = root._groupOrder.indexOf(b);
            return (ia < 0 ? root._groupOrder.length : ia) - (ib < 0 ? root._groupOrder.length : ib);
        });

        root.count = binds.length;
        root.groups = titles.map(title => ({
                    title,
                    rows: byGroup[title]
                }));
    }

    Process {
        id: reader
        command: ["hyprctl", "binds", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root._build(JSON.parse(text));
                } catch (e) {
                    console.warn(`Keybinds: could not read hyprctl binds: ${e}`);
                }
            }
        }
    }

    Connections {
        target: Hyprland

        function onRawEvent(event: HyprlandEvent): void {
            if (event.name === "configreloaded")
                root.refresh();
        }
    }

    Component.onCompleted: refresh()
}
