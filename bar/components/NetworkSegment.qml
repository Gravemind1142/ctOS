import QtQuick

import Quickshell.Networking

import qs.common
import qs.bar.components

// Network segment: the signal glyph and the link's name, cut to seven characters (`-WIRED-`
// on a cable, `OFFLINE` with no link). Click for the network menu; the brackets hold while
// it is open.
SimpleSegment {
    id: root

    readonly property var devices: Networking.devices.values
    readonly property bool wired: devices.some(d => d.type === DeviceType.Wired && d.connected)
    readonly property var network: devices.find(d => d.type === DeviceType.Wifi && d.connected)?.networks.values.find(n => n.connected) ?? null
    readonly property bool linked: wired || !!network

    interactive: true
    live: linked
    marked: hovered || menu.visible
    onClicked: menu.toggle()

    icon: SignalIcon {
        anchors.fill: parent
        linked: root.linked
        strength: root.wired ? 1 : root.network?.signalStrength ?? 0
        color: root.inkColor
    }

    text: {
        if (wired) {
            return "-WIRED-";
        }
        if (!network) {
            return "OFFLINE";
        }
        // drop band suffixes (`-5G`, ` 2.4G`) and delimiters, keep the last seven characters
        const ssid = network.name.toUpperCase().replace(/([-_ ]?[25](?:\.4)?g)/gi, "").replace(/[-_ ]/g, "").padEnd(7, "_");
        return ssid.slice(-7);
    }

    NetworkMenu {
        id: menu
        segment: root
    }
}
