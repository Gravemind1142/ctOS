import QtQuick

import qs.common

// The phone's network glyph: stacked bars narrowing to a point, as on Aiden's network
// list (videoframe_39813). Without a link it dims and takes the badge's status dot on its
// lower-left edge, in error.
Item {
    id: root

    property bool linked: true
    property color color: Theme.textPrimary

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
                color: root.linked ? root.color : Theme.textSecondary
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
