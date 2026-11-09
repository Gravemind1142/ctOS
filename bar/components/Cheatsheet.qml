pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts

import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland

import qs.common
import qs.common.components
import qs.bar.components
import qs.bar.services

// Keybind cheatsheet: a full-screen overlay on the focused monitor. `scrim` over the desktop, then a
// dialog panel (`surface`, `strokeFrame` outline, label block header) holding Hyprland's live binds
// from Keybinds as ruled groups in columns, each row a combo of key caps and its action. The panel
// drops in at durationMedium and leaves at durationShort; Escape or a click outside closes.
PanelWindow {
    id: root

    property bool shown: false

    readonly property int columnCount: Math.max(1, Math.min(4, Math.floor((width - 2 * Theme.space3xl + Theme.space2xl) / (Theme.cheatsheetColumnWidth + Theme.space2xl))))

    // groups dealt into columns, each to the shortest so far, so the columns end level
    readonly property var columns: {
        const columns = Array.from({
            length: columnCount
        }, () => ({
                    height: 0,
                    groups: []
                }));
        for (const group of Keybinds.groups) {
            const shortest = columns.reduce((a, b) => (b.height < a.height ? b : a));
            shortest.groups.push(group);
            // the label block counts as a row
            shortest.height += group.rows.length + 1;
        }
        return columns.filter(c => c.groups.length > 0).map(c => c.groups);
    }

    function toggle(): void {
        shown = !shown;
    }

    screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]
    // mapped on show, unmapped once the exit has played
    visible: false
    color: "transparent"

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "ctos-cheatsheet"
    WlrLayershell.keyboardFocus: shown ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    onShownChanged: {
        if (shown) {
            Keybinds.refresh();
            leave.stop();
            visible = true;
            enter.restart();
        } else {
            enter.stop();
            leave.restart();
        }
    }

    Rectangle {
        id: scrim
        anchors.fill: parent
        color: Theme.scrim
        opacity: 0

        MouseArea {
            anchors.fill: parent
            onClicked: root.shown = false
        }
    }

    FocusScope {
        anchors.fill: parent
        focus: true

        Keys.onEscapePressed: root.shown = false

        Rectangle {
            id: panel

            property real offset: 0

            anchors.horizontalCenter: parent.horizontalCenter
            y: (parent.height - height) / 2 + offset
            width: body.implicitWidth + 2 * Theme.strokeFrame
            height: Math.min(body.implicitHeight + 2 * Theme.strokeFrame, parent.height - 2 * Theme.space3xl)
            opacity: 0
            color: Theme.surface
            border {
                width: Theme.strokeFrame
                color: Theme.frame
            }

            // clicks on the panel stay on it rather than reaching the scrim
            MouseArea {
                anchors.fill: parent
            }

            ColumnLayout {
                id: body

                anchors {
                    fill: parent
                    margins: Theme.strokeFrame
                }
                spacing: 0

                // label block across the frame's top edge
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

                        PopupLabel {
                            text: "KEYBINDS"
                            color: Theme.labelText
                        }

                        Item {
                            Layout.fillWidth: true
                        }

                        PopupLabel {
                            text: `${String(Keybinds.count).padStart(3, "0")} BINDS`
                            color: Theme.labelText
                        }
                    }
                }

                Flickable {
                    id: scroller

                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    implicitWidth: grid.implicitWidth + 2 * Theme.spaceXl
                    implicitHeight: grid.implicitHeight + 2 * Theme.spaceXl
                    contentHeight: implicitHeight
                    interactive: contentHeight > height
                    boundsBehavior: Flickable.StopAtBounds
                    clip: true

                    RowLayout {
                        id: grid

                        x: Theme.spaceXl
                        y: Theme.spaceXl
                        spacing: Theme.space2xl

                        Repeater {
                            model: root.columns

                            ColumnLayout {
                                id: column

                                required property var modelData

                                Layout.alignment: Qt.AlignTop
                                Layout.preferredWidth: Theme.cheatsheetColumnWidth
                                spacing: Theme.spaceXl

                                Repeater {
                                    model: column.modelData

                                    Group {}
                                }
                            }
                        }
                    }
                }

                PopupRule {}

                RowLayout {
                    Layout.margins: Theme.spaceMd
                    spacing: Theme.spaceMd

                    KeyHint {
                        key: "ESC"
                        action: "CLOSE"
                    }

                    Item {
                        Layout.fillWidth: true
                    }

                    PopupMicroLabel {
                        Layout.fillWidth: false
                        text: "SOURCE: HYPRCTL BINDS"
                    }
                }
            }
        }
    }

    // a group: its name as a label block, then its binds as ruled rows
    component Group: ColumnLayout {
        id: group

        required property var modelData

        Layout.fillWidth: true
        spacing: 0

        Rectangle {
            Layout.alignment: Qt.AlignLeft
            implicitWidth: title.implicitWidth + 2 * Theme.spaceXs
            implicitHeight: title.implicitHeight + Theme.space2xs
            color: Theme.labelFill

            PopupLabel {
                id: title
                anchors.centerIn: parent
                text: group.modelData.title
                color: Theme.labelText
            }
        }

        Repeater {
            model: group.modelData.rows

            ColumnLayout {
                id: row

                required property var modelData
                required property int index

                Layout.fillWidth: true
                spacing: 0

                PopupRule {
                    visible: row.index > 0
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.topMargin: Theme.spaceXs
                    Layout.bottomMargin: Theme.spaceXs
                    spacing: Theme.spaceMd

                    Row {
                        Layout.preferredWidth: Theme.cheatsheetKeysWidth
                        Layout.alignment: Qt.AlignVCenter
                        spacing: Theme.space2xs

                        Repeater {
                            model: row.modelData.keys

                            KeyCap {
                                required property string modelData
                                key: modelData
                                inkColor: Theme.textPrimaryDim
                            }
                        }
                    }

                    Text {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                        elide: Text.ElideRight
                        text: row.modelData.action
                        color: Theme.textPrimary
                        font {
                            family: Theme.fontInsider
                            pixelSize: Theme.fontSizeXs
                            weight: Theme.fontWeightMedium
                            letterSpacing: Theme.trackingLabel
                        }
                    }
                }
            }
        }
    }

    ParallelAnimation {
        id: enter

        NumberAnimation {
            target: scrim
            property: "opacity"
            from: 0
            to: 1
            duration: Theme.durationShort
            easing.type: Theme.easeEnter
        }
        NumberAnimation {
            target: panel
            property: "opacity"
            from: 0
            to: 1
            duration: Theme.durationShort
            easing.type: Theme.easeEnter
        }
        NumberAnimation {
            target: panel
            property: "offset"
            from: -Theme.space2xl
            to: 0
            duration: Theme.durationMedium
            easing.type: Theme.easeEnter
        }
    }

    ParallelAnimation {
        id: leave

        onFinished: root.visible = false

        NumberAnimation {
            target: scrim
            property: "opacity"
            to: 0
            duration: Theme.durationShort
            easing.type: Theme.easeExit
        }
        NumberAnimation {
            target: panel
            property: "opacity"
            to: 0
            duration: Theme.durationShort
            easing.type: Theme.easeExit
        }
    }
}
