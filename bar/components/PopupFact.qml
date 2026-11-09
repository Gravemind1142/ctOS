import QtQuick
import QtQuick.Layouts

import qs.common
import qs.bar.components

// One labelled fact in a bar popup: label on the left, value on the right
RowLayout {
    property alias label: label.text
    property alias value: value.text
    property alias valueColor: value.color

    Layout.fillWidth: true
    spacing: Theme.spaceSm

    PopupLabel {
        id: label
    }

    Item {
        Layout.fillWidth: true
    }

    PopupValue {
        id: value
    }
}
