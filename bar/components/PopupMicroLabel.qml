import QtQuick
import QtQuick.Layouts

import qs.common

// Micro label under a value in a popup row (`FREE`, `WPA PASSWORD`)
Text {
    Layout.fillWidth: true
    elide: Text.ElideRight
    color: Theme.textPrimaryDimmer
    font {
        family: Theme.fontInsider
        pixelSize: Theme.fontSize2xs
        letterSpacing: Theme.trackingLabel
    }
}
