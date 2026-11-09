pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts

import Quickshell
import Quickshell.Services.SystemTray

import qs.common
import qs.common.components
import qs.bar.components

// Tray menu dropped from the tray segment. First the background apps as an icon grid (the
// phone's app grid), the targeted app's name under it. Click an app to activate it, middle
// click for its secondary action, right click to drill into its own menu.
//
// An app's menu is drawn in the bar's style instead of the app's toolkit: a short phone-style
// list with a BACK row on top, separators as rules, toggles as `[X]` and radio choices as
// `(•)`. A submenu (`>` on its row) replaces the list the same way.
//
// Arrows target, Enter activates, Space opens the targeted app's menu; Left (in a menu) or
// Escape goes back a level before Escape closes.
BarPopup {
    id: root

    readonly property var apps: SystemTray.items.values
    readonly property int columns: Math.max(1, Math.floor((Theme.popupWidth - 2 * Theme.strokeHairline - 2 * Theme.spaceMd) / Theme.barHeight))

    // the app whose menu is shown (null: the grid), and the submenus entered, outermost first
    property var app: null
    property var trail: []
    // grid: the targeted app; menu: the targeted entry, -2 the BACK row
    property int currentIndex: -1

    readonly property var current: trail.length > 0 ? trail[trail.length - 1] : app?.menu ?? null
    readonly property var entries: app ? opener.children?.values ?? [] : []
    readonly property var targetApp: !app && currentIndex >= 0 ? apps[currentIndex] ?? null : null
    // menu rows the keyboard can land on: BACK and the enabled entries
    readonly property var stops: [-2].concat(entries.map((e, i) => e.isSeparator || !e.enabled ? -1 : i).filter(i => i !== -1))

    title: app ? name(app) : "BACKGROUND"
    status: app ? (trail.length > 0 ? label(trail[trail.length - 1].text).toUpperCase() : "MENU") : apps.length.toString().padStart(2, "0") + " ACTIVE"

    onVisibleChanged: {
        app = null;
        trail = [];
        currentIndex = -1;
        if (visible) {
            keys.forceActiveFocus();
        }
    }

    // the app quit while its menu was open
    onAppsChanged: {
        if (app && apps.indexOf(app) < 0) {
            app = null;
            trail = [];
            currentIndex = -1;
        } else if (!app && currentIndex >= apps.length) {
            currentIndex = apps.length - 1;
        }
    }

    function name(item: var): string {
        return (item.tooltipTitle || item.title || item.id || "").toUpperCase();
    }

    // GTK and Qt mark mnemonics with "_" or "&"; drop them, keeping doubled ones literal
    function label(text: string): string {
        return (text ?? "").replace(/__/g, "\u0000").replace(/_|&(?!&)/g, "").replace(/&&/g, "&").replace(/\u0000/g, "_");
    }

    function activateApp(item: var): void {
        if (!item) {
            return;
        }
        if (item.onlyMenu) {
            openApp(item);
            return;
        }
        visible = false;
        item.activate();
    }

    function openApp(item: var): void {
        if (!item?.hasMenu) {
            return;
        }
        app = item;
        trail = [];
        currentIndex = -1;
    }

    function back(): bool {
        if (trail.length > 0) {
            trail = trail.slice(0, -1);
            currentIndex = -1;
            return true;
        }
        if (app) {
            currentIndex = apps.indexOf(app);
            app = null;
            return true;
        }
        return false;
    }

    // a separator only between two runs of entries: apps leave leading, trailing and doubled ones
    function ruleShown(index: int): bool {
        return index > 0 && !entries[index - 1].isSeparator && entries.slice(index + 1).some(e => !e.isSeparator);
    }

    function activateEntry(index: int): void {
        if (index === -2) {
            back();
            return;
        }
        const entry = entries[index];
        if (!entry || entry.isSeparator || !entry.enabled) {
            return;
        }
        if (entry.hasChildren) {
            trail = trail.concat([entry]);
            currentIndex = -1;
            return;
        }
        // toggles stay open so a run of them can be flipped; anything else is an action
        entry.triggered();
        if (entry.buttonType === QsMenuButtonType.None) {
            visible = false;
        }
    }

    // grid: move by delta cells, clamped to the grid
    function moveTile(delta: int): void {
        if (apps.length > 0) {
            currentIndex = currentIndex < 0 ? 0 : Math.max(0, Math.min(apps.length - 1, currentIndex + delta));
        }
    }

    // menu: step through the stops, wrapping
    function stepEntry(delta: int): void {
        const count = stops.length;
        const stop = stops.indexOf(currentIndex);
        currentIndex = stops[stop < 0 ? (delta > 0 ? 0 : count - 1) : (stop + delta + count) % count];
    }

    QsMenuOpener {
        id: opener
        menu: root.current
    }

    Item {
        id: keys

        focus: true

        Keys.onUpPressed: root.app ? root.stepEntry(-1) : root.moveTile(-root.columns)
        Keys.onDownPressed: root.app ? root.stepEntry(1) : root.moveTile(root.columns)
        Keys.onTabPressed: root.app ? root.stepEntry(1) : root.moveTile(1)
        Keys.onBacktabPressed: root.app ? root.stepEntry(-1) : root.moveTile(-1)
        Keys.onLeftPressed: root.app ? root.back() : root.moveTile(-1)
        Keys.onRightPressed: {
            if (!root.app) {
                root.moveTile(1);
            } else if (root.entries[root.currentIndex]?.hasChildren) {
                root.activateEntry(root.currentIndex);
            }
        }
        Keys.onSpacePressed: root.openApp(root.targetApp)
        Keys.onReturnPressed: root.app ? root.activateEntry(root.currentIndex) : root.activateApp(root.targetApp)
        Keys.onEnterPressed: root.app ? root.activateEntry(root.currentIndex) : root.activateApp(root.targetApp)
        Keys.onEscapePressed: event => {
            event.accepted = root.back();
        }
    }

    // the app grid
    ColumnLayout {
        visible: !root.app
        Layout.fillWidth: true
        Layout.margins: Theme.spaceMd
        spacing: Theme.spaceXs

        Grid {
            columns: root.columns

            Repeater {
                model: SystemTray.items

                delegate: TrayItem {
                    id: tile

                    required property int index
                    required property SystemTrayItem modelData

                    item: modelData
                    targeted: root.currentIndex === index

                    onHoveredChanged: {
                        if (hovered) {
                            root.currentIndex = index;
                        }
                    }
                    onActivated: root.activateApp(modelData)
                    onSecondaryActivated: {
                        root.visible = false;
                        modelData.secondaryActivate();
                    }
                    onMenuRequested: root.openApp(modelData)
                }
            }
        }

        PopupMicroLabel {
            visible: root.apps.length === 0
            text: "NO BACKGROUND APPS"
        }
    }

    // a menu row: the entry's text, a toggle mark before it, `>` after it for a submenu.
    // Targeted is raised; disabled rows dim and take no input
    component EntryRow: Rectangle {
        id: row

        // -2 is the BACK row
        property int index: -2
        property string text: ""
        property string mark: ""
        property bool submenu: false
        property bool enabled: true

        readonly property bool targeted: root.currentIndex === index && enabled
        readonly property color ink: enabled ? Theme.textPrimary : Theme.textDisabled

        Layout.fillWidth: true
        implicitHeight: rowContent.implicitHeight + 2 * Theme.spaceXs
        color: targeted ? Theme.surfaceRaised : "transparent"

        RowLayout {
            id: rowContent

            anchors {
                left: parent.left
                right: parent.right
                verticalCenter: parent.verticalCenter
                leftMargin: Theme.controlPadding
                rightMargin: Theme.controlPadding
            }
            spacing: Theme.spaceSm

            PopupValue {
                visible: row.mark !== ""
                text: row.mark
                color: row.ink
            }

            PopupValue {
                Layout.fillWidth: true
                elide: Text.ElideRight
                text: row.text
                color: row.ink
            }

            PopupValue {
                visible: row.submenu
                text: ">"
                color: row.enabled ? Theme.textPrimaryDim : Theme.textDisabled
            }
        }

        HoverHandler {
            enabled: row.enabled
            cursorShape: Qt.PointingHandCursor
            onHoveredChanged: {
                if (hovered) {
                    root.currentIndex = row.index;
                }
            }
        }

        TapHandler {
            enabled: row.enabled
            onTapped: {
                root.currentIndex = row.index;
                root.activateEntry(row.index);
            }
        }
    }

    // the app's menu
    ColumnLayout {
        visible: !!root.app
        Layout.fillWidth: true
        Layout.margins: Theme.spaceMd
        spacing: 0

        EntryRow {
            index: -2
            text: "BACK"
            mark: "<"
        }

        PopupRule {
            Layout.topMargin: Theme.spaceXs
            Layout.bottomMargin: Theme.spaceXs
        }

        Repeater {
            model: root.app ? opener.children : null

            delegate: Loader {
                id: slot

                required property QsMenuEntry modelData
                required property int index

                Layout.fillWidth: true
                visible: !modelData.isSeparator || root.ruleShown(index)
                sourceComponent: modelData.isSeparator ? separator : entry

                Component {
                    id: separator

                    Item {
                        implicitHeight: Theme.strokeHairline + 2 * Theme.spaceXs

                        PopupRule {
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width
                        }
                    }
                }

                Component {
                    id: entry

                    EntryRow {
                        readonly property bool checked: slot.modelData.checkState === Qt.Checked

                        index: slot.index
                        text: root.label(slot.modelData.text)
                        enabled: slot.modelData.enabled
                        submenu: slot.modelData.hasChildren
                        mark: {
                            switch (slot.modelData.buttonType) {
                            case QsMenuButtonType.CheckBox:
                                return checked ? "[X]" : "[ ]";
                            case QsMenuButtonType.RadioButton:
                                return checked ? "(•)" : "( )";
                            default:
                                return "";
                            }
                        }
                    }
                }
            }
        }

        PopupMicroLabel {
            visible: root.entries.length === 0
            text: "NO ENTRIES"
        }
    }

    PopupRule {
        visible: root.currentIndex !== -1
    }

    // the target's name (grid) and key hints
    ColumnLayout {
        visible: root.currentIndex !== -1
        Layout.fillWidth: true
        Layout.margins: Theme.spaceMd
        spacing: Theme.spaceSm

        PopupValue {
            visible: !!root.targetApp
            Layout.fillWidth: true
            elide: Text.ElideRight
            text: root.targetApp ? root.name(root.targetApp) : ""
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.spaceMd

            KeyHint {
                key: "↵"
                action: root.app ? (root.currentIndex === -2 ? "BACK" : root.entries[root.currentIndex]?.hasChildren ? "OPEN" : "SELECT") : root.targetApp?.onlyMenu ? "MENU" : "OPEN"
            }

            KeyHint {
                visible: !root.app && !!root.targetApp?.hasMenu && !root.targetApp?.onlyMenu
                key: "SPC"
                action: "MENU"
            }

            KeyHint {
                key: "ESC"
                action: root.app ? "BACK" : "CLOSE"
            }
        }
    }
}
