import QtQuick

import qs.common

// Motif 10, key hint: the key's name in a small hairline cap, then the action in uppercase
// (`[DEL] FORGET`). For keybind hints in popups, the OSD and the cheatsheet.
Row {
    id: root

    property string key: ""
    property string action: ""
    property color color: Theme.textSecondary

    spacing: Theme.spaceXs

    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        width: Math.max(height, keyText.implicitWidth + 2 * Theme.spaceXs)
        height: keyText.implicitHeight + Theme.space2xs
        color: "transparent"
        border {
            width: Theme.strokeHairline
            color: root.color
        }

        Text {
            id: keyText
            anchors.centerIn: parent
            text: root.key
            color: root.color
            font {
                family: Theme.fontInsider
                pixelSize: Theme.fontSize2xs
                weight: Theme.fontWeightBold
            }
        }
    }

    Text {
        anchors.verticalCenter: parent.verticalCenter
        text: root.action
        color: root.color
        font {
            family: Theme.fontInsider
            pixelSize: Theme.fontSize2xs
            weight: Theme.fontWeightBold
            letterSpacing: Theme.trackingLabel
        }
    }
}
