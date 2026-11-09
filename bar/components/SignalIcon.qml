import QtQuick

import qs.common

// The phone's network glyph: stacked bars narrowing to a point, as on Aiden's network
// list (videoframe_39813). Without a link it dims and takes the badge's status dot on its
// lower-left edge, in error. `strength` lights the bars from the narrow end up; the rest
// sit in fillMuted.
Item {
    id: root

    property bool linked: true
    // 0–1; bars light from the point up, at least one while there is any signal
    property real strength: 1
    property color color: Theme.textPrimary

    readonly property int bars: strength > 0 ? Math.max(1, Math.ceil(strength * 4)) : 0

    implicitWidth: Theme.fontSizeMd
    implicitHeight: Theme.fontSizeMd

    Column {
        anchors.centerIn: parent
        spacing: Theme.space2xs

        Repeater {
            model: 4

            Rectangle {
                required property int index

                anchors.horizontalCenter: parent.horizontalCenter
                width: root.width * (4 - index) / 4
                height: Theme.trackThickness
                color: !root.linked ? Theme.textSecondary : index >= 4 - root.bars ? root.color : Theme.fillMuted
            }
        }
    }

    Rectangle {
        visible: !root.linked
        anchors {
            left: parent.left
            bottom: parent.bottom
        }
        width: Theme.statusDot
        height: width
        radius: width / 2
        color: Theme.error
    }
}
