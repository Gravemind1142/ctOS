import QtQuick
import QtQuick.Layouts

import qs.common

// Bar segment: an icon and one value inside a corner frame
Item {
    id: root

    property string text: ""

    height: parent.height
    width: frame.width + 2 * Theme.segmentInset

    default property alias icon: icon.data

    CornerFrame {
        id: frame

        anchors.centerIn: parent
        height: parent.height - 2 * Theme.segmentInset

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
                color: Theme.textPrimary
                font {
                    family: Theme.fontInsider
                    pixelSize: Theme.fontSizeMd
                    weight: Theme.fontWeightMedium
                }
                Layout.alignment: Qt.AlignVCenter
            }
        }
    }
}
