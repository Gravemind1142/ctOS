import QtQuick

import qs.common

// The official ctOS lockup (design/references/ctOS.webp): a wide label block with a small
// "CT" in its bottom-right corner, then a bold "OS". Public voice. Set a height (the block's,
// which is also the height of "OS"); everything else scales from it.
// Departs from the reference, where "OS" stands ~6% taller than the block: here they match.
Item {
    id: root

    // Proportions measured from the reference. Fixed geometry of the mark, not layout,
    // so they live here rather than in tokens.
    readonly property real blockRatio: 2.72  // block width / block height
    readonly property real ctCapRatio: 0.47  // "CT" cap height / block height
    readonly property real ctBaselineRatio: 0.09  // "CT" baseline above the block's bottom
    readonly property real ctMarginRatio: 0.18  // "CT" to the block's right edge
    readonly property real gapRatio: 0.14  // block to "OS"
    // Nimbus Sans cap height per em, to size "CT" by cap height
    readonly property real capHeightEm: 0.718
    // ink height of bold "OS" per em, overshoot included, so the round letters match the block
    readonly property real osInkEm: 0.757
    // how far the round letters dip below the baseline, per em
    readonly property real overshootEm: 0.015

    readonly property real blockHeight: Math.round(height)

    property color blockColor: Theme.labelFill
    property color blockTextColor: Theme.labelText

    implicitWidth: os.x + os.implicitWidth

    Rectangle {
        id: block

        anchors.bottom: parent.bottom
        height: root.blockHeight
        width: Math.round(root.blockHeight * root.blockRatio)
        color: root.blockColor

        Text {
            anchors {
                right: parent.right
                rightMargin: Math.round(root.blockHeight * root.ctMarginRatio)
                baseline: parent.bottom
                baselineOffset: -Math.round(root.blockHeight * root.ctBaselineRatio)
            }
            text: "CT"
            color: root.blockTextColor
            font {
                family: Theme.fontPublic
                pixelSize: Math.round(root.blockHeight * root.ctCapRatio / root.capHeightEm)
                weight: Theme.fontWeightRegular
            }
        }
    }

    // "OS" sits on the block's baseline
    Text {
        id: os

        anchors {
            left: block.right
            leftMargin: Math.round(root.blockHeight * root.gapRatio)
            baseline: block.bottom
            // lift by the overshoot so the letters' bottoms meet the block's
            baselineOffset: -os.font.pixelSize * root.overshootEm
        }
        text: "OS"
        color: root.blockColor
        font {
            family: Theme.fontPublic
            pixelSize: Math.round(root.blockHeight / root.osInkEm)
            bold: true
        }
    }
}
