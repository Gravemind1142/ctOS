import QtQuick
import Quickshell.Services.SystemTray

import qs.common
import qs.bar.components

// Tray segment, one workspace-sized cell after the workspaces: the number of background apps
// as a two-digit readout, in `warning` while any of them asks for attention. Click for the
// `TrayMenu` (the apps as an icon grid); the brackets hold while it is open.
Item {
    id: root

    readonly property var items: SystemTray.items.values
    readonly property bool attention: items.some(i => i.status === Status.NeedsAttention)

    readonly property bool hovered: hover.hovered
    readonly property bool pressed: tap.pressed || flash.running
    readonly property color ink: pressed ? Theme.labelText : attention ? Theme.warning : hovered || menu.visible ? Theme.textPrimary : Theme.textSecondary

    height: parent.height
    width: parent.height

    CornerFrame {
        anchors.centerIn: parent
        width: parent.height - 2 * Theme.segmentInset
        height: parent.height - 2 * Theme.segmentInset
        marked: root.hovered || root.pressed || menu.visible
        accentColor: root.attention ? Theme.warning : Theme.frame
        fillColor: root.pressed ? Theme.labelFill : root.hovered ? Theme.surfaceRaised : "transparent"
    }

    Text {
        anchors.centerIn: parent
        text: root.items.length.toString().padStart(2, "0")
        color: root.ink
        font {
            family: Theme.fontInsider
            pixelSize: Theme.fontSizeMd
            weight: Theme.fontWeightMedium
        }
    }

    HoverHandler {
        id: hover
        cursorShape: Qt.PointingHandCursor
    }

    TapHandler {
        id: tap
        onTapped: {
            flash.restart();
            menu.toggle();
        }
    }

    // keeps a quick click visible as a pressed block for one step
    Timer {
        id: flash
        interval: Theme.durationFast
    }

    TrayMenu {
        id: menu
        segment: root
    }
}
