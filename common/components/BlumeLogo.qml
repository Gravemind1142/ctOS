import QtQuick
import QtQuick.Shapes

import qs.common

// The Blume logo: a hexagon split into three isometric cubes. Same geometry as
// common/resources/blume-logo.svg (48px grid), drawn as a shape so it takes any colour.
Shape {
    id: root

    property color color: Theme.textPrimary

    // the SVG's grid and stroke; everything scales with the item's size
    readonly property real gridSize: 48
    readonly property real gridStroke: 1.5

    implicitWidth: gridSize
    implicitHeight: gridSize
    preferredRendererType: Shape.CurveRenderer

    ShapePath {
        strokeColor: root.color
        // never thinner than a hairline, so it stays legible at bar size
        strokeWidth: Math.max(Theme.strokeHairline, root.gridStroke * Math.min(root.width, root.height) / root.gridSize)
        fillColor: "transparent"
        joinStyle: ShapePath.MiterJoin
        capStyle: ShapePath.FlatCap
        scale: Qt.size(root.width / root.gridSize, root.height / root.gridSize)

        PathSvg {
            path: "M24,3.215 L42,13.608 L42,34.392 L24,44.785 L6,34.392 L6,13.608 Z M33,8.412 L33,18.804 L42,24 M33,8.412 L24,13.608 L15,8.412 M24,13.608 L24,24 M24,24 L33,29.196 L42,24 M15,8.412 L15,18.804 L6,24 M6,24 L15,29.196 L24,24 M15,29.196 L15,39.588 M15,39.588 L24,34.392 L33,39.588 M33,39.588 L33,29.196"
        }
    }
}
