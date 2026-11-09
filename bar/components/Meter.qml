import QtQuick
import QtQuick.Layouts

import qs.common
import qs.bar.components

// Bar segment: uppercase label and symbol, a padded value, and a thin level fill.
// Profiler pattern: the label in textPrimaryDim, the value in textPrimary.
Segment {
    id: root

    property int percentage: 0
    property string name: ""
    property string symbol: ""
    property string value: ""
    // level bars may signal state (warning when low, success when full)
    property color fillColor: Theme.textPrimary
    // switched off (a muted source): value and fill read as disabled
    property bool muted: false

    component MeterText: Text {
        color: root.labelColor
        font {
            family: Theme.fontInsider
            pixelSize: Theme.fontSizeXs
            weight: Theme.fontWeightBold
            letterSpacing: Theme.trackingLabel
        }
    }

    ColumnLayout {
        y: -2  // optical nudge: the fill sits low in the frame otherwise
        width: Theme.barMeterWidth
        spacing: Theme.space2xs

        RowLayout {
            spacing: Theme.space2xs

            MeterText {
                text: root.name
            }

            MeterText {
                text: root.symbol
            }

            Item {
                Layout.fillWidth: true
            }

            MeterText {
                text: root.value
                color: root.pressed ? Theme.labelText : root.muted ? Theme.textDisabled : Theme.textPrimary
                font.letterSpacing: Theme.trackingNone
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: Theme.trackThickness
            color: Theme.fillMuted

            Rectangle {
                anchors.fill: parent
                color: root.pressed ? Theme.labelText : root.muted ? Theme.textDisabled : root.fillColor

                transform: Scale {
                    origin.x: 0
                    xScale: Utils.clamp(root.percentage, 0, 100) / 100

                    Behavior on xScale {
                        NumberAnimation {
                            duration: Theme.durationMeter
                            easing.type: Theme.easeMove
                        }
                    }
                }
            }
        }
    }
}
