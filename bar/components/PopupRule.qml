import QtQuick
import QtQuick.Layouts

import qs.common

// Full-width hairline between blocks of data in a bar popup
Rectangle {
    Layout.fillWidth: true
    Layout.preferredHeight: Theme.strokeHairline
    color: Theme.frameSubtle
}
