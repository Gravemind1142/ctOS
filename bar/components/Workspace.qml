import QtQuick

import qs.common

// One workspace cell: corner brackets, with a crosshair when active
Item {
    id: root

    property bool active: true

    height: parent.height
    width: parent.height

    CornerFrame {
        anchors.centerIn: parent
        width: parent.height - 2 * Theme.segmentInset
        height: parent.height - 2 * Theme.segmentInset
    }

    Item {
        anchors.centerIn: parent
        opacity: root.active ? 1 : 0

        Behavior on opacity {
            NumberAnimation {
                duration: Theme.durationFast
                easing.type: Theme.easeSnap
            }
        }

        Rectangle {
            width: Theme.crosshairSize
            height: Theme.strokeHairline
            color: Theme.frame
            anchors.centerIn: parent
        }

        Rectangle {
            width: Theme.strokeHairline
            height: Theme.crosshairSize
            color: Theme.frame
            anchors.centerIn: parent
        }
    }
}
