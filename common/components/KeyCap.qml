import QtQuick

import qs.common

// One key's name in a small hairline cap (`[DEL]`), the cap half of motif 10. KeyHint pairs
// it with an action; a combo is a row of caps (`[SUPER] [SHIFT] [1–0]`).
Rectangle {
    id: root

    property string key: ""
    property color inkColor: Theme.textSecondary
    property int pixelSize: Theme.fontSize2xs

    width: Math.max(height, keyText.implicitWidth + 2 * Theme.spaceXs)
    height: keyText.implicitHeight + Theme.space2xs
    color: "transparent"
    border {
        width: Theme.strokeHairline
        color: root.inkColor
    }

    Text {
        id: keyText
        anchors.centerIn: parent
        text: root.key
        color: root.inkColor
        font {
            family: Theme.fontInsider
            pixelSize: root.pixelSize
            weight: Theme.fontWeightBold
        }
    }
}
