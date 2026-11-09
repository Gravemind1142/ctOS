pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts

import Quickshell
import Quickshell.Io

import qs.common
import qs.common.components
import qs.bar.components
import qs.bar.config

// Session menu dropped from the user segment: the operator as a readout (profiler pattern:
// name, host, session, uptime), then the session actions as a short phone-style list.
// Lock and suspend run at once. Log out, reboot and shut down arm on the first press (the
// row turns into the destructive-action block) and run on a second press within
// durationConfirm; Escape or moving to another row disarms.
//
// Hover or Up/Down targets a row, click or Enter activates it. Commands come from
// `modules.user.commands`; an empty command hides its row.
BarPopup {
    id: root

    property string name: ""

    readonly property var commands: Settings.modules.user.commands
    readonly property var actions: [
        {
            id: "lock",
            name: "Lock",
            detail: "SECURE TERMINAL",
            confirm: false
        },
        {
            id: "logout",
            name: "Log out",
            detail: "END SESSION",
            confirm: true
        },
        {
            id: "suspend",
            name: "Suspend",
            detail: "STANDBY",
            confirm: false
        },
        {
            id: "reboot",
            name: "Reboot",
            detail: "RESTART SYSTEM",
            confirm: true
        },
        {
            id: "shutdown",
            name: "Shut down",
            detail: "POWER OFF",
            confirm: true
        }
    ].filter(a => (commands[a.id] ?? "") !== "")

    // the targeted row, and the action waiting for its confirming press
    property int currentIndex: -1
    property string armed: ""

    readonly property var target: currentIndex >= 0 && currentIndex < actions.length ? actions[currentIndex] : null

    property real uptime: 0
    property string host: ""

    title: "SESSION"
    status: armed !== "" ? "CONFIRM" : "ACCESS GRANTED"
    alignRight: true

    onVisibleChanged: {
        armed = "";
        currentIndex = -1;
        if (visible) {
            uptimeFile.reload();
            keys.forceActiveFocus();
        }
    }

    onCurrentIndexChanged: {
        if (target?.id !== armed) {
            armed = "";
        }
    }

    // seconds → "hh:mm", with a day count once it passes one
    function duration(seconds: real): string {
        const minutes = Math.floor(seconds / 60);
        const days = Math.floor(minutes / 1440);
        const clock = Utils.padTime(Math.floor(minutes / 60) % 24) + ":" + Utils.padTime(minutes % 60);
        return days > 0 ? days + "D " + clock : clock;
    }

    function activate(action: var): void {
        if (!action) {
            return;
        }
        if (action.confirm && armed !== action.id) {
            armed = action.id;
            disarm.restart();
            return;
        }
        visible = false;
        Quickshell.execDetached(["sh", "-c", commands[action.id]]);
    }

    function step(delta: int): void {
        const count = actions.length;
        if (count > 0) {
            currentIndex = currentIndex < 0 ? (delta > 0 ? 0 : count - 1) : (currentIndex + delta + count) % count;
        }
    }

    Timer {
        id: disarm
        interval: Theme.durationConfirm
        onTriggered: root.armed = ""
    }

    FileView {
        id: hostFile
        path: "/proc/sys/kernel/hostname"
        onLoaded: root.host = text().trim().toUpperCase()
    }

    FileView {
        id: uptimeFile
        path: "/proc/uptime"
        onLoaded: root.uptime = parseFloat(text().split(" ")[0]) || 0
    }

    // uptime reads in minutes, so tick once a minute while open
    Timer {
        interval: 60 * 1000
        running: root.visible
        repeat: true
        onTriggered: uptimeFile.reload()
    }

    // keyboard: Up/Down target, Enter activates, Escape disarms before it closes
    Item {
        id: keys

        focus: true

        Keys.onUpPressed: root.step(-1)
        Keys.onDownPressed: root.step(1)
        Keys.onTabPressed: root.step(1)
        Keys.onBacktabPressed: root.step(-1)
        Keys.onReturnPressed: root.activate(root.target)
        Keys.onEnterPressed: root.activate(root.target)
        Keys.onEscapePressed: event => {
            if (root.armed !== "") {
                root.armed = "";
            } else {
                event.accepted = false;
            }
        }
    }

    // a list row: name and a micro label under it. Targeted is raised; armed is the
    // destructive-action block
    component ActionRow: Rectangle {
        id: row

        required property var modelData
        required property int index

        readonly property bool targeted: root.currentIndex === index
        readonly property bool armed: root.armed === modelData.id
        readonly property color ink: armed ? Theme.labelText : Theme.textPrimary

        Layout.fillWidth: true
        implicitHeight: rowContent.implicitHeight + 2 * Theme.spaceXs
        color: armed ? Theme.error : targeted ? Theme.surfaceRaised : "transparent"

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
                text: row.modelData.name
                color: row.ink
            }

            PopupMicroLabel {
                text: row.armed ? "PRESS AGAIN TO CONFIRM" : row.modelData.detail
                color: row.armed ? Theme.labelText : Theme.textPrimaryDimmer
            }
        }

        HoverHandler {
            cursorShape: Qt.PointingHandCursor
            onHoveredChanged: {
                if (hovered) {
                    root.currentIndex = row.index;
                }
            }
        }

        TapHandler {
            onTapped: {
                root.currentIndex = row.index;
                root.activate(row.modelData);
            }
        }
    }

    // operator readout
    ColumnLayout {
        Layout.fillWidth: true
        Layout.margins: Theme.spaceMd
        spacing: Theme.spaceXs

        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.spaceSm

            Text {
                Layout.fillWidth: true
                elide: Text.ElideRight
                text: root.name
                color: Theme.textPrimary
                font {
                    family: Theme.fontInsider
                    pixelSize: Theme.fontSizeXl
                    weight: Theme.fontWeightBold
                }
            }

            PopupLabel {
                Layout.alignment: Qt.AlignBottom
                Layout.bottomMargin: Theme.space2xs
                Layout.maximumWidth: Theme.popupWidth / 2
                elide: Text.ElideRight
                text: root.host || "LOCALHOST"
            }
        }

        PopupRule {}

        PopupFact {
            label: "SESSION"
            value: (Quickshell.env("XDG_CURRENT_DESKTOP") || "UNKNOWN").toUpperCase()
        }

        PopupFact {
            label: "UPTIME"
            value: root.duration(root.uptime)
        }
    }

    PopupRule {}

    // session actions
    ColumnLayout {
        Layout.fillWidth: true
        Layout.margins: Theme.spaceMd
        spacing: 0

        Repeater {
            model: root.actions
            delegate: ActionRow {}
        }
    }

    PopupRule {
        visible: !!root.target
    }

    // key hints
    RowLayout {
        visible: !!root.target
        Layout.fillWidth: true
        Layout.margins: Theme.spaceMd
        spacing: Theme.spaceMd

        KeyHint {
            key: "↵"
            action: root.target && root.armed === root.target.id ? "CONFIRM" : root.target?.name.toUpperCase() ?? ""
        }

        KeyHint {
            visible: root.armed !== ""
            key: "ESC"
            action: "CANCEL"
        }
    }
}
