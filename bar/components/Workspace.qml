import QtQuick
import Quickshell

import qs.common

// One workspace cell. The active one is locked on: brackets settle in around it. A workspace
// with windows shows its lead app's icon (the window last focused there), recoloured to one
// tone, and a pip under it for each other window. An empty active workspace shows a crosshair.
// Clicking switches to it, with the bar's control states: brackets and a raised fill on hover,
// an inverted block for one durationFast when pressed.
Item {
    id: root

    property bool active: true
    // app ids of the workspace's windows, the lead first
    property var windows: []
    property int maxPips: 4

    readonly property bool occupied: windows.length > 0
    readonly property bool hovered: hover.hovered
    readonly property bool pressed: tap.pressed || flash.running
    readonly property color ink: pressed ? Theme.labelText : active || hovered ? Theme.textPrimary : Theme.textSecondary

    signal clicked

    // desktop entries load asynchronously: reading the list re-runs the lookup once they arrive
    readonly property var _entry: occupied && DesktopEntries.applications.values.length >= 0 ? DesktopEntries.heuristicLookup(windows[0]) : null
    readonly property string _iconSource: _entry?.icon ? Quickshell.iconPath(_entry.icon, true) : ""

    height: parent.height
    width: parent.height

    CornerFrame {
        anchors.centerIn: parent
        width: parent.height - 2 * Theme.segmentInset
        height: parent.height - 2 * Theme.segmentInset
        marked: root.active || root.hovered || root.pressed
        fillColor: root.pressed ? Theme.labelFill : root.hovered ? Theme.surfaceRaised : "transparent"
    }

    // crosshair: the lock-on mark of an empty active workspace
    Item {
        anchors.centerIn: parent
        opacity: root.active && !root.occupied ? 1 : 0

        Behavior on opacity {
            NumberAnimation {
                duration: Theme.durationFast
                easing.type: Theme.easeSnap
            }
        }

        Rectangle {
            width: Theme.crosshairSize
            height: Theme.strokeHairline
            color: root.pressed ? Theme.labelText : Theme.frame
            anchors.centerIn: parent
        }

        Rectangle {
            width: Theme.strokeHairline
            height: Theme.crosshairSize
            color: root.pressed ? Theme.labelText : Theme.frame
            anchors.centerIn: parent
        }
    }

    TintedIcon {
        id: icon
        anchors.centerIn: parent
        source: root._iconSource
        color: root.ink
        visible: root.occupied
    }

    // no icon found: the app id's initial, in the insider voice
    Text {
        anchors.centerIn: parent
        visible: root.occupied && !icon.ready
        text: (root.windows[0] ?? "?").replace(/^.*\./, "").charAt(0).toUpperCase() || "?"
        color: root.ink
        font {
            family: Theme.fontInsider
            pixelSize: Theme.fontSizeMd
            weight: Theme.fontWeightMedium
        }
    }

    // one pip per window beyond the lead
    Row {
        anchors {
            horizontalCenter: parent.horizontalCenter
            bottom: parent.bottom
            bottomMargin: Theme.segmentInset + Theme.space2xs
        }
        spacing: Theme.space2xs

        Repeater {
            model: Math.min(Math.max(root.windows.length - 1, 0), root.maxPips)

            Rectangle {
                width: Theme.pipSize
                height: Theme.pipSize
                radius: width / 2
                color: root.ink
            }
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
            root.clicked();
        }
    }

    // keeps a quick click visible as a pressed block for one step
    Timer {
        id: flash
        interval: Theme.durationFast
    }
}
