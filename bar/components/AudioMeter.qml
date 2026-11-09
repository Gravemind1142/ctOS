import QtQuick

import Quickshell.Services.Pipewire

import qs.common
import qs.bar.components

// Meter for a Pipewire node's volume: scroll to change (Shift for steps of 10),
// click to mute. Muted reads as disabled.
Meter {
    id: root

    required property PwNode node
    // symbol while sound passes; muted shows "xx"
    property string liveSymbol: ""

    readonly property int level: Math.round((node?.audio?.volume ?? 0) * 100)

    interactive: !!node?.audio
    muted: !!node?.audio?.muted

    symbol: muted ? "xx" : liveSymbol
    value: level.toString().padStart(3, "0") + "%"
    percentage: level

    PwObjectTracker {
        objects: [root.node]
    }

    onClicked: node.audio.muted = !node.audio.muted

    onScrolled: delta => {
        node.audio.muted = false;
        node.audio.volume = Utils.clamp(node.audio.volume + delta / 100, 0, 1);
    }
}
