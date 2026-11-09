import QtQuick

import qs.common
import qs.common.components
import qs.bar.components

// Bar segment at the right end: a `[?] KEYS` key hint, mirroring the logo block at the left.
// Click to open the keybind cheatsheet; the brackets hold while it is open.
Segment {
    id: root

    // the overlay it opens
    required property Cheatsheet cheatsheet

    interactive: true
    marked: hovered || cheatsheet.shown
    onClicked: cheatsheet.toggle()

    KeyHint {
        key: "?"
        action: "KEYS"
        pixelSize: Theme.fontSizeXs
        color: root.pressed ? Theme.labelText : root.hovered || root.cheatsheet.shown ? Theme.textPrimary : Theme.textPrimaryDim
    }
}
