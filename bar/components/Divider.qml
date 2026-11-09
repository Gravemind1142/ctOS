import QtQuick

import qs.common

// 1px vertical rule between bar segments, inside the bar's border
Rectangle {
    anchors {
        top: parent.top
        topMargin: Theme.strokeHairline
        bottom: parent.bottom
        bottomMargin: Theme.strokeHairline
    }
    width: Theme.strokeHairline
    color: Theme.frameSubtle
}
