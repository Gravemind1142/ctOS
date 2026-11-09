import QtQuick

import qs.common

// Bar segment shell: content inset from the bar's edges. The bar's border and Dividers
// carry the structure; corner brackets appear only when the segment is targeted.
// Interactive segments take the control states: brackets and a raised fill on hover, an
// inverted block for one durationFast when pressed. Content colours itself from the ink properties.
Item {
    id: root

    default property alias content: row.data

    property bool interactive: false
    property color bracketColor: Theme.frame
    // brackets settle in while targeted; hover by default
    property bool marked: hovered

    readonly property bool hovered: interactive && hover.hovered
    readonly property bool pressed: interactive && (tap.pressed || flash.running)

    // text on the segment: black while it is an inverted block
    readonly property color inkColor: pressed ? Theme.labelText : Theme.textPrimary
    readonly property color labelColor: pressed ? Theme.labelText : Theme.textPrimaryDim

    signal clicked
    // +1/-1 per wheel notch, ×10 with Shift
    signal scrolled(int delta)

    height: parent.height
    width: frame.width + 2 * Theme.segmentInset

    CornerFrame {
        id: frame

        anchors.centerIn: parent
        height: parent.height - 2 * Theme.segmentInset
        accentColor: root.bracketColor
        marked: root.marked || root.pressed
        fillColor: root.pressed ? Theme.labelFill : root.hovered ? Theme.surfaceRaised : "transparent"

        Row {
            id: row
        }
    }

    HoverHandler {
        id: hover
        enabled: root.interactive
        cursorShape: Qt.PointingHandCursor
    }

    TapHandler {
        id: tap
        enabled: root.interactive
        onTapped: {
            flash.restart();
            root.clicked();
        }
    }

    WheelHandler {
        enabled: root.interactive
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        onWheel: event => {
            const step = event.modifiers & Qt.ShiftModifier ? 10 : 1;
            root.scrolled(event.angleDelta.y > 0 ? step : -step);
        }
    }

    // keeps a quick click visible as a pressed block for one step
    Timer {
        id: flash
        interval: Theme.durationFast
    }
}
