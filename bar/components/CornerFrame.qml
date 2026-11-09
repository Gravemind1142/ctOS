pragma ComponentBehavior: Bound
import QtQuick

import qs.common

// Motif 2: four corner brackets around a row of content
Item {
    id: root

    property color accentColor: Theme.frame
    property int thickness: Theme.strokeHairline
    property int armLength: Theme.cornerArm
    property int horizontalMargin: Theme.spaceXs

    implicitWidth: container.width + 2 * armLength + 2 * horizontalMargin
    width: implicitWidth

    implicitHeight: container.height + 2 * armLength
    height: implicitHeight

    default property alias content: container.data

    Row {
        id: container
        x: root.armLength + root.horizontalMargin
        y: root.armLength - 2  // optical nudge: centre mono text between the brackets
    }

    component Corner: Item {
        width: root.armLength
        height: root.armLength

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
