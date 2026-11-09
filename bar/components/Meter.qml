import QtQuick
import QtQuick.Layouts

import qs.common
import qs.bar.components

// Bar segment: uppercase label and symbol, a padded value, and a thin level fill
Item {
    id: root

    property int percentage: 0
    property string name: ""
    property string symbol: ""
    property string value: ""
    // level bars may signal state (warning when low, success when full)
    property color fillColor: Theme.textPrimary

    height: parent.height
    width: frame.width + 2 * Theme.segmentInset

    component MeterText: Text {
        color: Theme.textPrimaryDim
        font {
            family: Theme.fontInsider
            pixelSize: Theme.fontSizeXs
            weight: Theme.fontWeightBold
            letterSpacing: Theme.trackingLabel
        }
    }

    CornerFrame {
        id: frame

        anchors.centerIn: parent
        height: parent.height - 2 * Theme.segmentInset

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
                    color: Theme.textPrimary
                    font.letterSpacing: Theme.trackingNone
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: Theme.trackThickness
                color: Theme.fillMuted

                Rectangle {
                    anchors.fill: parent
                    color: root.fillColor

                    Behavior on color {
                        ColorAnimation {
                            duration: Theme.durationFast
                        }
                    }

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
}
