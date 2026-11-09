pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.greeter.config
import qs.greeter.data

Singleton {
    id: sessionManager

    property bool _isUsingUwsm: false

    property list<User> users: []
    property list<Desktop> desktops: []

    property User activeUser: sessionManager.findUser(Settings.defaultUsername) || _firstUser
    property var _firstUser: null

    property Desktop activeDesktop: sessionManager.findDesktop(Settings.defaultDesktopName) || _firstDesktop
    property var _firstDesktop: null

    Component {
        id: userFactory
        User {}
    }

    Component {
        id: desktopFactory
        Desktop {}
    }

    function findUser(value) {
        if (value === undefined || value === null) {
            return null;
        }

        const searchValue = value.toString().trim();
        if (!searchValue.length) {
            return null;
        }

        const numericValue = parseInt(searchValue);

        if (isNaN(numericValue)) {
            const usernameSearch = searchValue.toLowerCase();
            return users.find(user => user.username.toLowerCase().includes(usernameSearch)) ?? null;
        }

        const uidMatch = users.find(user => user.uid === numericValue);
        if (uidMatch) {
            return uidMatch;
        }

        return users[numericValue - 1] ?? null;
    }

    function findDesktop(value) {
        if (value === undefined || value === null) {
            return null;
        }

        const searchValue = value.toString().trim();

        if (!searchValue.length) {
            return null;
        }

        const oneBasedIdx = parseInt(searchValue);

        if (isNaN(oneBasedIdx)) {
            const desktopSearch = searchValue.toLowerCase();
            return desktops.find(desktop => desktop.name.toLowerCase().includes(desktopSearch)) ?? null;
        }

        return desktops[oneBasedIdx - 1] ?? null;
    }

    function setUser(value, saveDefault = false) {
        const found = findUser(value);

        if (!found) {
            return false;
        }

        activeUser = found;

        if (saveDefault) {
            Settings.setDefaultUsername(found.username);
        }

        return true;
    }

    function setDesktop(value, saveDefault = false) {
        const found = findDesktop(value);

        if (!found) {
            return false;
        }

        activeDesktop = found;

        if (saveDefault) {
            Settings.setDefaultDesktopName(found.name);
        }

        return true;
    }

    function getExitCommand() {
        if (Settings.exitCommand && Settings.exitCommand.length) {
            return Settings.exitCommand;
        }

        if (_isUsingUwsm) {
            return ["uwsm", "stop"];
        }

        // unset under a bare compositor like cage, env() then returns null
        const currentDesktop = (Quickshell.env("XDG_CURRENT_DESKTOP") || "").toLowerCase();

        if (currentDesktop.includes("hyprland")) {
            return ["hyprctl", "dispatch", "exit"];
        }

        if (currentDesktop.includes("niri")) {
            return ["niri", "msg", "action", "quit"];
        }

        return [];
    }

    function getLaunchCommand() {
        if (!activeDesktop || !activeDesktop.exec) {
            return [];
        }
        const command = activeDesktop.exec.trim().split(/\s+/);

        // greetd gives the session the VT as stdout/stderr, so its startup logs flash
        // on screen. Send them to the journal instead (journalctl -t ctos-session).
        // NOTE: greetd joins argv with spaces and runs it via `sh -c`, so only plain
        // words are safe here, no shell syntax or quoting.
        if (_hasSystemdCat) {
            return ["systemd-cat", "-t", "ctos-session", "--", ...command];
        }

        return command;
    }

    // environment a display manager normally provides, so logind registers a
    // wayland session and the desktop knows what it is (e.g. GNOME needs this)
    function getLaunchEnvironment() {
        const env = ["XDG_SESSION_TYPE=wayland"];
        const names = (activeDesktop?.desktopNames || "").split(";").filter(n => n.length);

        if (names.length) {
            env.push(`XDG_CURRENT_DESKTOP=${names.join(":")}`);
            env.push(`XDG_SESSION_DESKTOP=${names[0].toLowerCase()}`);
        }

        return env;
    }

    property bool _hasSystemdCat: false

    Process {
        id: systemdCatCheck
        command: ["sh", "-c", "command -v systemd-cat"]
        running: true
        onExited: exitCode => {
            sessionManager._hasSystemdCat = exitCode === 0;
        }
    }

    Process {
        id: uwsmCheck
        command: ["sh", "-c", "env | grep -q '^UWSM'"]
        running: true
        onExited: exitCode => {
            sessionManager._isUsingUwsm = exitCode === 0;
            desktopsProcess.running = true;
        }
    }

    Process {
        id: usersProcess
        command: ["sh", "-c", "cat /etc/passwd"]
        running: true
        stdout: SplitParser {
            onRead: data => {
                const parts = data.trim().split(":");

                if (parts.length < 7) {
                    return;
                }

                const [user, , uidStr, , , home, shell] = parts;

                const uid = parseInt(uidStr);

                const isStandard = uid >= 1000 && uid < 60000;
                const isRealUser = !shell.match(/nologin|false|sync/);
                const isNotNobody = user !== "nobody";

                if (!isStandard || !isRealUser || !isNotNobody) {
                    return;
                }

                const userObj = userFactory.createObject(sessionManager, {
                    "username": user,
                    "homeDir": home,
                    "shell": shell,
                    "uid": uid
                });

                sessionManager.users.push(userObj);
                sessionManager.usersChanged();

                if (!sessionManager._firstUser) {
                    sessionManager._firstUser = userObj;
                }
            }
        }
    }

    Process {
        id: desktopsProcess
        property var _currentEntry: ({})

        command: ["sh", "-c", "cat /usr/share/wayland-sessions/*.desktop 2>/dev/null"]
        running: false

        stdout: SplitParser {
            onRead: data => {
                const line = data.trim();
                if (!line) {
                    return;
                }

                if (line === "[Desktop Entry]") {
                    desktopsProcess.commit();
                    return;
                }

                const splitIdx = line.indexOf("=");
                if (splitIdx === -1) {
                    return;
                }

                // split on the first '=' only, values may contain '=' (e.g. --session=ubuntu)
                const key = line.slice(0, splitIdx);
                const value = line.slice(splitIdx + 1);

                switch (key) {
                case "Name":
                    desktopsProcess._currentEntry.name = value;
                    break;
                case "Comment":
                    desktopsProcess._currentEntry.comment = value;
                    break;
                case "Exec":
                    desktopsProcess._currentEntry.exec = value;
                    break;
                case "Type":
                    desktopsProcess._currentEntry.type = value;
                    break;
                case "DesktopNames":
                    desktopsProcess._currentEntry.desktopNames = value;
                    break;
                }

                if (value.toLowerCase().includes("uwsm")) {
                    desktopsProcess._currentEntry._uwsmManaged = true;
                }
            }
        }

        onExited: {
            desktopsProcess.commit();

            const xdg = Quickshell.env("XDG_CURRENT_DESKTOP") || "";
            const env = xdg.toLowerCase();

            const detectedDesktop = desktops.find(d => {
                const nameMatch = env && d.name.toLowerCase().includes(env);
                const uwsmMatch = (d._uwsmManaged === _isUsingUwsm);
                return nameMatch && uwsmMatch;
            });

            _firstDesktop = detectedDesktop || (desktops.length > 0 ? desktops[0] : null);
        }

        function commit() {
            const entry = desktopsProcess._currentEntry;

            if (entry.name && entry.exec) {
                const desktopObj = desktopFactory.createObject(sessionManager, entry);
                desktops.push(desktopObj);
                desktopsChanged();
            }

            desktopsProcess._currentEntry = {
                "_uwsmManaged": false
            };
        }
    }
}
