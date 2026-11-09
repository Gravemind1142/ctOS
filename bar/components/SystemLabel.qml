import QtQuick

import qs.common
import qs.common.components

// The left end of the bar: the ctOS logo in its own label block, flush with the bar's
// edges, then the brandmark inset so "OS" sits clear of the bar border
Row {
    id: root

    Rectangle {
        height: root.height
        width: root.height
        color: Theme.labelFill

        CtosLogo {
            anchors.centerIn: parent
            width: parent.height - 2 * Theme.spaceXs
            height: width
            color: Theme.labelText
        }
    }

    Item {
        height: root.height
        width: brandmark.implicitWidth + 2 * Theme.spaceSm

        Brandmark {
            id: brandmark
            anchors.centerIn: parent
            height: parent.height - 2 * Theme.spaceSm
        }
    }
}
