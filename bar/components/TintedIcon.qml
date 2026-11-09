import QtQuick
import QtQuick.Effects

import qs.common

// An app icon recoloured to one tone, keeping its shading, so full-colour icons sit in the
// monochrome bar. `ready` is false until the image loads; show a fallback in its place.
Item {
    id: root

    property alias source: image.source
    property color color: Theme.textPrimary
    property int size: Theme.fontSizeMd

    readonly property bool ready: image.status === Image.Ready

    width: size
    height: size

    Image {
        id: image
        anchors.fill: parent
        sourceSize: Qt.size(width, height)
        visible: false
        smooth: true
        mipmap: true
    }

    MultiEffect {
        anchors.fill: image
        source: image
        visible: root.ready
        colorization: 1
        colorizationColor: root.color
    }
}
