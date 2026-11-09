import QtQuick
import Quickshell.Services.SystemTray

import qs.common

// One app in the tray menu's icon grid, the size of a workspace cell: the app's icon
// recoloured to one tone (hack-prompt pattern), in `warning` while the app asks for
// attention. Control states as the workspace cells; `targeted` (hover or keyboard) gets the
// brackets and raised fill. Scroll is passed to the app.
Item {
    id: root

    required property SystemTrayItem item
    property bool targeted: false

    readonly property bool hovered: hover.hovered
    readonly property bool pressed: tap.pressed || flash.running
    readonly property bool attention: item.status === Status.NeedsAttention
    readonly property color ink: pressed ? Theme.labelText : attention ? Theme.warning : targeted ? Theme.textPrimary : Theme.textSecondary

    signal activated
    signal secondaryActivated
    signal menuRequested

    width: Theme.barHeight
    height: Theme.barHeight

    CornerFrame {
        anchors.centerIn: parent
        width: parent.height - 2 * Theme.segmentInset
        height: parent.height - 2 * Theme.segmentInset
        marked: root.targeted || root.pressed
        accentColor: root.attention ? Theme.warning : Theme.frame
        fillColor: root.pressed ? Theme.labelFill : root.targeted ? Theme.surfaceRaised : "transparent"
    }

    TintedIcon {
        id: icon
        anchors.centerIn: parent
        source: root.item.icon
        color: root.ink
    }

    // no icon: the app's initial, in the insider voice
    Text {
        anchors.centerIn: parent
        visible: !icon.ready
        text: (root.item.title || root.item.id || "?").charAt(0).toUpperCase()
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
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        onTapped: (point, button) => {
            flash.restart();
            if (button === Qt.RightButton || (button === Qt.LeftButton && root.item.onlyMenu)) {
                root.menuRequested();
            } else if (button === Qt.MiddleButton) {
                root.secondaryActivated();
            } else {
                root.activated();
            }
        }
    }

    WheelHandler {
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        onWheel: event => {
            const horizontal = Math.abs(event.angleDelta.x) > Math.abs(event.angleDelta.y);
            root.item.scroll(horizontal ? event.angleDelta.x : event.angleDelta.y, horizontal);
        }
    }

    // keeps a quick click visible as a pressed block for one step
    Timer {
        id: flash
        interval: Theme.durationFast
    }
}
