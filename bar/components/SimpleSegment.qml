import QtQuick
import QtQuick.Layouts

import qs.common
import qs.bar.components

// Bar segment: an icon and one value inside corner brackets
Segment {
    id: root

    property string text: ""
    // false for an inactive value (no link): steps the text down to textSecondary
    property bool live: true

    // the icon (`icon: SomeItem {}`); colour it from inkColor so it inverts when pressed
    property alias icon: icon.data

    RowLayout {
        spacing: Theme.spaceSm

        Item {
            id: icon
            Layout.preferredHeight: Theme.fontSizeMd
            Layout.preferredWidth: Theme.fontSizeMd
            Layout.alignment: Qt.AlignVCenter
        }

        Text {
            text: root.text
            color: root.live || root.pressed ? root.inkColor : root.hovered ? Theme.textPrimary : Theme.textSecondary
            font {
                family: Theme.fontInsider
                pixelSize: Theme.fontSizeMd
                weight: Theme.fontWeightMedium
            }
            Layout.alignment: Qt.AlignVCenter
        }
    }
}
