import QtQuick

import qs.common
import qs.bar.components

// The phone's round network badge (videoframe_39813): the signal glyph in a dark disc, a
// `secured` dot on its lower-left edge for a protected network, and the cyan selection ring
// around it while the row is targeted.
Item {
    id: root

    property real strength: 1
    property bool secured: false
    property bool targeted: false
    property color fill: Theme.surfaceRaised
    property color color: Theme.textPrimary

    implicitWidth: Theme.badgeSize
    implicitHeight: Theme.badgeSize

    Rectangle {
        anchors.fill: parent
        radius: width / 2
        color: root.fill
    }

    SignalIcon {
        anchors.centerIn: parent
        width: Theme.fontSizeSm
        height: Theme.fontSizeSm
        strength: root.strength
        color: root.color
    }

    // selection ring, clear of the disc
    Rectangle {
        visible: root.targeted
        anchors.centerIn: parent
        width: parent.width + 2 * (Theme.strokeMarker + Theme.space2xs)
        height: width
        radius: width / 2
        color: "transparent"
        border {
            width: Theme.strokeMarker
            color: Theme.focus
        }
    }

    Rectangle {
        visible: root.secured
        anchors {
            left: parent.left
            bottom: parent.bottom
        }
        width: Theme.statusDot
        height: width
        radius: width / 2
        color: Theme.secured
    }
}
