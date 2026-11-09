import QtQuick

import qs.common

// Uppercase field label in a bar popup (profiler pattern: dim, bold, tracked)
Text {
    color: Theme.textPrimaryDim
    font {
        family: Theme.fontInsider
        pixelSize: Theme.fontSizeXs
        weight: Theme.fontWeightBold
        letterSpacing: Theme.trackingLabel
    }
}
