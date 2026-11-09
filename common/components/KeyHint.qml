import QtQuick

import qs.common
import qs.common.components

// Motif 10, key hint: the key's name in a small hairline cap, then the action in uppercase
// (`[DEL] FORGET`). For keybind hints in popups, the OSD and the cheatsheet.
Row {
    id: root

    property string key: ""
    property string action: ""
    property color color: Theme.textSecondary
    property int pixelSize: Theme.fontSize2xs

    spacing: Theme.spaceXs

    KeyCap {
        anchors.verticalCenter: parent.verticalCenter
        key: root.key
        inkColor: root.color
        pixelSize: root.pixelSize
    }

    Text {
        anchors.verticalCenter: parent.verticalCenter
        text: root.action
        color: root.color
        font {
            family: Theme.fontInsider
            pixelSize: root.pixelSize
            weight: Theme.fontWeightBold
            letterSpacing: Theme.trackingLabel
        }
    }
}
