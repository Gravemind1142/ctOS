import QtQuick

import Quickshell

import qs.common
import qs.bar.components
import qs.bar.config

// User segment: the operator's name (the configured label, or $USER). Click for the session
// menu (lock, log out, suspend, reboot, shut down); the brackets hold while it is open.
SimpleSegment {
    id: root

    readonly property string name: Settings.modules.user.label || Quickshell.env("USER")

    interactive: true
    marked: hovered || menu.visible
    onClicked: menu.toggle()

    text: name.toUpperCase()

    icon: Text {
        anchors.centerIn: parent
        anchors.verticalCenterOffset: -1  // optical nudge: glyph sits low in its line box

        text: "▨"
        color: root.inkColor
        font.pixelSize: Theme.fontSizeLg
        font.family: Theme.fontInsider
        font.weight: Theme.fontWeightBold
    }

    SessionMenu {
        id: menu
        segment: root
        name: root.name
    }
}
