pragma ComponentBehavior: Bound
import QtQuick

import qs.common

// Motif 2: four corner brackets around a row of content. The brackets mark the item as
// targeted: with `marked` false they are hidden but keep their space, so nothing shifts
// when they settle in.
Item {
    id: root

    property color accentColor: Theme.frame
    // fills the bracketed area: hover and pressed states
    property color fillColor: "transparent"
    property int thickness: Theme.strokeHairline
    property int armLength: Theme.cornerArm
    property int horizontalMargin: Theme.spaceXs
    property bool marked: true

    // how far out the brackets sit while unmarked; they slide in to the corners
    readonly property int _offset: marked ? 0 : Theme.space2xs

    implicitWidth: container.width + 2 * armLength + 2 * horizontalMargin
    width: implicitWidth

    implicitHeight: container.height + 2 * armLength
    height: implicitHeight

    default property alias content: container.data

    // states switch instantly so the pressed block reads as a cut, not a fade
    Rectangle {
        anchors.fill: parent
        color: root.fillColor
    }

    Row {
        id: container
        x: root.armLength + root.horizontalMargin
        y: root.armLength - 2  // optical nudge: centre mono text between the brackets
    }

    component Corner: Item {
        width: root.armLength
        height: root.armLength
        anchors.margins: -root._offset
        opacity: root.marked ? 1 : 0

        Behavior on opacity {
            NumberAnimation {
                duration: Theme.durationFast
                easing.type: Theme.easeSnap
            }
        }

        Behavior on anchors.margins {
            NumberAnimation {
                duration: Theme.durationFast
                easing.type: Theme.easeSnap
            }
        }

        Rectangle {
            width: root.armLength
            height: root.thickness
            color: root.accentColor
            anchors.top: parent.top
            anchors.left: parent.left
        }

        Rectangle {
            width: root.thickness
            height: root.armLength
            color: root.accentColor
            anchors.top: parent.top
            anchors.left: parent.left
        }
    }

    Corner {
        anchors.top: parent.top
        anchors.left: parent.left
    }

    Corner {
        anchors.top: parent.top
        anchors.right: parent.right
        rotation: 90
    }

    Corner {
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        rotation: 180
    }

    Corner {
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        rotation: 270
    }
}
