import QtQuick
import QtQuick.Shapes

import qs.common

// The ctOS logo: a diamond wired to a solid square core. Same geometry as
// common/resources/ctos-logo.svg (48px grid), drawn as a shape so it takes any colour.
Shape {
    id: root

    property color color: Theme.textPrimary

    // the SVG's grid and stroke; everything scales with the item's size
    readonly property real gridSize: 48
    readonly property real gridStroke: 1.5
    // never thinner than a hairline, so it stays legible at bar size
    readonly property real stroke: Math.max(Theme.strokeHairline, gridStroke * Math.min(width, height) / gridSize)
    readonly property size pathScale: Qt.size(width / gridSize, height / gridSize)

    implicitWidth: gridSize
    implicitHeight: gridSize
    preferredRendererType: Shape.CurveRenderer

    // outline and wires
    ShapePath {
        strokeColor: root.color
        strokeWidth: root.stroke
        fillColor: "transparent"
        joinStyle: ShapePath.MiterJoin
        capStyle: ShapePath.FlatCap
        scale: root.pathScale

        PathSvg {
            path: "M24,2 L46,24 L24,46 L2,24 Z M24,2 L24,24.66 M2,24 L16.344,32.316 M46,24 L31.656,32.316 M24,39.972 L24,46"
        }
    }

    // core
    ShapePath {
        strokeColor: root.color
        strokeWidth: root.stroke
        fillColor: root.color
        joinStyle: ShapePath.MiterJoin
        scale: root.pathScale

        PathSvg {
            path: "M24,24.66 L31.656,32.316 L24,39.972 L16.344,32.316 Z"
        }
    }
}
