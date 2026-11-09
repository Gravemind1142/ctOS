pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts

import Quickshell
import Quickshell.Networking

import qs.common
import qs.common.components
import qs.bar.components
import qs.bar.config

// Network menu dropped from the network segment, after Aiden's phone network list
// (videoframe_39813): the current link as a readout (profiler pattern), then the wireless
// networks in range as rows with a round signal badge, a `secured` dot on protected ones and
// a micro label (`FREE`, `WPA2 PASSWORD`). The linked network is an inverted block, the
// targeted row gets the cyan ring. A protected network asks for its key in a masked well.
//
// Click or Enter connects (or disconnects the linked network), right click or Delete forgets
// a saved one. ADVANCED runs the configured network command for anything else.
BarPopup {
    id: root

    readonly property var devices: Networking.devices.values
    readonly property WifiDevice wifi: devices.find(d => d.type === DeviceType.Wifi) ?? null
    readonly property WiredDevice wired: devices.find(d => d.type === DeviceType.Wired && d.connected) ?? null
    readonly property WifiNetwork current: wifi?.networks.values.find(n => n.connected) ?? null
    readonly property bool linked: !!wired || !!current
    readonly property bool connecting: wifi?.networks.values.some(n => n.state === ConnectionState.Connecting) ?? false

    // networks in range: linked first, then saved, then by signal bars and name. Bars rather
    // than raw strength, so rows don't reshuffle under the pointer on every scan.
    readonly property var networks: {
        const list = (wifi?.networks.values ?? []).filter(n => n.name !== "");
        const rank = n => n.connected ? 0 : n.known ? 1 : 2;
        const bars = n => Math.ceil(n.signalStrength * 4);
        return list.sort((a, b) => rank(a) - rank(b) || bars(b) - bars(a) || a.name.localeCompare(b.name));
    }

    // the network waiting for a key, and the last failure per network name
    property WifiNetwork asking: null
    property var failures: ({})

    // the targeted row's network, for the key hints
    readonly property WifiNetwork target: list.currentIndex >= 0 && list.currentIndex < networks.length ? networks[list.currentIndex] : null

    title: "NETWORKS"
    status: connecting ? "CONNECTING" : linked ? "LINK ESTABLISHED" : wifi && !Networking.wifiEnabled ? "WIFI OFF" : "OFFLINE"
    implicitWidth: Theme.popupWidthWide
    alignRight: true

    onVisibleChanged: {
        if (visible) {
            asking = null;
            failures = {};
            list.currentIndex = -1;
            list.forceActiveFocus();
        }
    }

    // scan while the menu is open
    Binding {
        target: root.wifi
        property: "scannerEnabled"
        value: true
        when: root.visible && !!root.wifi
    }

    function isPsk(network: WifiNetwork): bool {
        return [WifiSecurityType.WpaPsk, WifiSecurityType.Wpa2Psk, WifiSecurityType.Sae, WifiSecurityType.StaticWep].includes(network.security);
    }

    function isEnterprise(network: WifiNetwork): bool {
        return [WifiSecurityType.WpaEap, WifiSecurityType.Wpa2Eap, WifiSecurityType.Wpa3SuiteB192, WifiSecurityType.DynamicWep, WifiSecurityType.Leap].includes(network.security);
    }

    function securityName(security: int): string {
        switch (security) {
        case WifiSecurityType.Open:
            return "OPEN";
        case WifiSecurityType.WpaPsk:
            return "WPA";
        case WifiSecurityType.Wpa2Psk:
            return "WPA2";
        case WifiSecurityType.Sae:
            return "WPA3";
        case WifiSecurityType.StaticWep:
            return "WEP";
        case WifiSecurityType.WpaEap:
            return "WPA EAP";
        case WifiSecurityType.Wpa2Eap:
            return "WPA2 EAP";
        case WifiSecurityType.Wpa3SuiteB192:
            return "WPA3 EAP";
        case WifiSecurityType.DynamicWep:
            return "WEP EAP";
        case WifiSecurityType.Leap:
            return "LEAP";
        default:
            return "UNKNOWN";
        }
    }

    function failureName(reason: int): string {
        switch (reason) {
        case ConnectionFailReason.NoSecrets:
            return "ACCESS DENIED";
        case ConnectionFailReason.WifiAuthTimeout:
            return "AUTH TIMEOUT";
        case ConnectionFailReason.WifiNetworkLost:
            return "SIGNAL LOST";
        default:
            return "LINK FAILED";
        }
    }

    // the micro label under a network's name, and whether it reports a failure
    function detail(network: WifiNetwork): string {
        if (network.name in failures) {
            return failureName(failures[network.name]);
        }
        switch (network.state) {
        case ConnectionState.Connecting:
            return "CONNECTING";
        case ConnectionState.Disconnecting:
            return "DISCONNECTING";
        }
        if (network.connected) {
            return "LINK ESTABLISHED";
        }
        if (network.known) {
            return "SAVED";
        }
        if (network.security === WifiSecurityType.Open) {
            return "FREE";
        }
        if (isEnterprise(network)) {
            return securityName(network.security) + " LOGIN";
        }
        return isPsk(network) ? securityName(network.security) + " PASSWORD" : "SECURED";
    }

    // what Enter or a click does to a network
    function actionName(network: WifiNetwork): string {
        if (network.connected) {
            return "DISCONNECT";
        }
        if (!network.known && isEnterprise(network)) {
            return "ADVANCED";
        }
        return !network.known && isPsk(network) ? "ENTER KEY" : "CONNECT";
    }

    function forgetFailure(network: WifiNetwork): void {
        const next = Object.assign({}, failures);
        delete next[network.name];
        failures = next;
    }

    function activate(network: WifiNetwork): void {
        if (!network || network.stateChanging) {
            return;
        }
        forgetFailure(network);

        if (network.connected) {
            network.disconnect();
        } else if (!network.known && isEnterprise(network)) {
            advanced();
        } else if (!network.known && isPsk(network)) {
            asking = network;
        } else {
            network.connect();
        }
    }

    function submit(network: WifiNetwork, key: string): void {
        asking = null;
        list.forceActiveFocus();
        if (key !== "") {
            forgetFailure(network);
            network.connectWithPsk(key);
        }
    }

    function forget(network: WifiNetwork): void {
        if (network?.known) {
            forgetFailure(network);
            network.forget();
        }
    }

    function advanced(): void {
        visible = false;
        Quickshell.execDetached(["sh", "-c", Settings.modules.network.command]);
    }

    // current link
    ColumnLayout {
        Layout.fillWidth: true
        Layout.margins: Theme.spaceMd
        spacing: Theme.spaceXs

        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.spaceSm

            Text {
                Layout.fillWidth: true
                elide: Text.ElideRight
                text: root.wired ? "Wired" : root.current?.name ?? "No link"
                color: root.linked ? Theme.textPrimary : Theme.textSecondary
                font {
                    family: Theme.fontInsider
                    pixelSize: Theme.fontSizeXl
                    weight: Theme.fontWeightBold
                }
            }

            PopupLabel {
                Layout.alignment: Qt.AlignBottom
                Layout.bottomMargin: Theme.space2xs
                text: (root.wired ?? root.wifi)?.name.toUpperCase() ?? "NO DEVICE"
            }
        }

        PopupRule {}

        PopupFact {
            visible: !!root.current && !root.wired
            label: "SIGNAL"
            value: Math.round((root.current?.signalStrength ?? 0) * 100).toString().padStart(3, "0") + "%"
        }

        PopupFact {
            visible: !!root.current && !root.wired
            label: "SECURITY"
            value: root.securityName(root.current?.security ?? WifiSecurityType.Unknown)
        }

        PopupFact {
            visible: !!root.wired
            label: "LINK SPEED"
            value: (root.wired?.linkSpeed ?? 0) + " MB/S"
        }

        PopupFact {
            visible: root.linked
            label: "HW ADDR"
            value: ((root.wired ?? root.wifi)?.address ?? "").toUpperCase()
        }

        PopupFact {
            visible: Networking.connectivity !== NetworkConnectivity.Unknown
            label: "UPLINK"
            value: {
                switch (Networking.connectivity) {
                case NetworkConnectivity.Full:
                    return "FULL";
                case NetworkConnectivity.Limited:
                    return "LIMITED";
                case NetworkConnectivity.Portal:
                    return "LOGIN PORTAL";
                default:
                    return "NONE";
                }
            }
            valueColor: {
                switch (Networking.connectivity) {
                case NetworkConnectivity.Full:
                    return Theme.textPrimary;
                case NetworkConnectivity.None:
                    return Theme.error;
                default:
                    return Theme.warning;
                }
            }
        }
    }

    PopupRule {
        visible: !!root.wifi
    }

    // wireless networks in range
    ColumnLayout {
        visible: !!root.wifi
        Layout.fillWidth: true
        Layout.margins: Theme.spaceMd
        spacing: Theme.spaceXs

        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.spaceSm

            PopupLabel {
                text: "WIRELESS"
            }

            PopupLabel {
                visible: Networking.wifiEnabled
                text: root.networks.length.toString().padStart(2, "0")
                color: Theme.textSecondary
            }

            Item {
                Layout.fillWidth: true
            }

            // Wi-Fi switch: the text is the control and names its state. Off steps down to
            // textSecondary, hover steps up one level; blocked by a hardware switch or rfkill,
            // it can't be turned on from here and reads as disabled
            PopupLabel {
                text: !Networking.wifiHardwareEnabled ? "WIFI BLOCKED" : Networking.wifiEnabled ? "WIFI ON" : "WIFI OFF"
                color: !Networking.wifiHardwareEnabled ? Theme.textDisabled : wifiHover.hovered ? Theme.textPrimary : Networking.wifiEnabled ? Theme.textPrimaryDim : Theme.textSecondary

                HoverHandler {
                    id: wifiHover
                    enabled: Networking.wifiHardwareEnabled
                    cursorShape: Qt.PointingHandCursor
                }

                TapHandler {
                    enabled: Networking.wifiHardwareEnabled
                    onTapped: Networking.wifiEnabled = !Networking.wifiEnabled
                }
            }
        }

        PopupMicroLabel {
            visible: Networking.wifiEnabled && root.networks.length === 0
            text: "SCANNING"
        }

        ListView {
            id: list

            // rows before it scrolls
            readonly property int maxRows: 6

            visible: Networking.wifiEnabled && count > 0
            Layout.fillWidth: true
            readonly property bool overflowing: contentHeight > height
            Layout.preferredHeight: Math.min(contentHeight, maxRows * contentHeight / Math.max(count, 1))
            clip: true
            focus: true
            boundsBehavior: Flickable.StopAtBounds
            currentIndex: -1
            highlightMoveDuration: 0

            // diffed, so a scan updates rows in place instead of rebuilding them
            model: ScriptModel {
                values: root.networks
            }

            Keys.onReturnPressed: root.activate(root.target)
            Keys.onEnterPressed: root.activate(root.target)
            Keys.onDeletePressed: root.forget(root.target)

            delegate: Rectangle {
                id: row

                required property WifiNetwork modelData
                required property int index

                readonly property bool selected: modelData.connected
                readonly property bool targeted: ListView.isCurrentItem
                readonly property bool failed: modelData.name in root.failures
                readonly property bool asking: root.asking === modelData
                readonly property color ink: selected ? Theme.labelText : Theme.textPrimary

                // clear of the scrollbar
                width: ListView.view.width - (list.overflowing ? Theme.scrollbarWidth + Theme.spaceXs : 0)
                implicitHeight: rowContent.implicitHeight
                color: selected ? Theme.labelFill : targeted ? Theme.surfaceRaised : "transparent"

                Connections {
                    target: row.modelData

                    function onConnectionFailed(reason: int): void {
                        root.failures = Object.assign({}, root.failures, {
                            [row.modelData.name]: reason
                        });
                        if (reason === ConnectionFailReason.NoSecrets && root.isPsk(row.modelData)) {
                            root.asking = row.modelData;
                        }
                    }
                }

                ColumnLayout {
                    id: rowContent

                    anchors {
                        left: parent.left
                        right: parent.right
                    }
                    spacing: 0

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.margins: Theme.spaceSm
                        Layout.leftMargin: Theme.controlPadding
                        Layout.rightMargin: Theme.controlPadding
                        spacing: Theme.spaceMd

                        NetworkBadge {
                            strength: row.modelData.signalStrength
                            secured: row.modelData.security !== WifiSecurityType.Open
                            targeted: row.targeted
                            fill: row.selected ? Theme.labelText : row.targeted ? Theme.frameSubtle : Theme.surfaceRaised
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: Theme.space2xs

                            PopupValue {
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                                text: row.modelData.name
                                color: row.ink
                            }

                            PopupMicroLabel {
                                text: root.detail(row.modelData)
                                color: row.selected ? Theme.labelText : row.failed ? Theme.error : Theme.textPrimaryDimmer
                            }
                        }

                        PopupLabel {
                            text: Math.round(row.modelData.signalStrength * 100).toString().padStart(3, "0") + "%"
                            color: row.selected ? Theme.labelText : Theme.textSecondary
                            font.letterSpacing: Theme.trackingNone
                        }
                    }

                    // key well, masked like the phone's `*****`
                    Rectangle {
                        visible: row.asking
                        Layout.fillWidth: true
                        Layout.leftMargin: Theme.controlPadding + Theme.badgeSize + Theme.spaceMd
                        Layout.rightMargin: Theme.controlPadding
                        Layout.bottomMargin: Theme.spaceSm
                        implicitHeight: Theme.controlHeight
                        color: Theme.background
                        border {
                            width: Theme.strokeHairline
                            color: key.activeFocus ? Theme.focus : Theme.frame
                        }

                        onVisibleChanged: {
                            key.text = "";
                            if (visible) {
                                key.forceActiveFocus();
                            }
                        }

                        PopupMicroLabel {
                            visible: key.text === ""
                            anchors {
                                left: parent.left
                                right: parent.right
                                verticalCenter: parent.verticalCenter
                                leftMargin: Theme.spaceMd
                            }
                            text: root.securityName(row.modelData.security) + " KEY"
                            color: Theme.textSecondary
                        }

                        TextInput {
                            id: key

                            anchors {
                                left: parent.left
                                right: parent.right
                                verticalCenter: parent.verticalCenter
                                leftMargin: Theme.spaceMd
                                rightMargin: Theme.spaceMd
                            }
                            clip: true
                            echoMode: TextInput.Password
                            passwordCharacter: "*"
                            color: Theme.textPrimary
                            selectionColor: Theme.labelFill
                            selectedTextColor: Theme.labelText
                            font {
                                family: Theme.fontInsider
                                pixelSize: Theme.fontSizeSm
                                weight: Theme.fontWeightBold
                                letterSpacing: Theme.trackingWide
                            }

                            Keys.onReturnPressed: root.submit(row.modelData, text)
                            Keys.onEnterPressed: root.submit(row.modelData, text)
                            Keys.onEscapePressed: event => {
                                root.asking = null;
                                list.forceActiveFocus();
                                event.accepted = true;
                            }
                        }
                    }
                }

                HoverHandler {
                    cursorShape: row.modelData.stateChanging ? Qt.ArrowCursor : Qt.PointingHandCursor
                    onHoveredChanged: {
                        if (hovered) {
                            list.currentIndex = row.index;
                        }
                    }
                }

                TapHandler {
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    onTapped: (eventPoint, button) => {
                        list.currentIndex = row.index;
                        if (button === Qt.RightButton) {
                            root.forget(row.modelData);
                        } else if (!row.asking) {
                            root.activate(row.modelData);
                        }
                    }
                }
            }

            // thin scrollbar on the right edge while the list overflows
            Rectangle {
                visible: list.overflowing
                anchors.right: parent.right
                y: list.visibleArea.yPosition * list.height
                width: Theme.scrollbarWidth
                height: list.visibleArea.heightRatio * list.height
                color: Theme.frame
            }
        }
    }

    PopupRule {}

    // key hints, and the way out to the full network manager
    RowLayout {
        Layout.fillWidth: true
        Layout.margins: Theme.spaceMd
        spacing: Theme.spaceMd

        KeyHint {
            visible: !!root.target
            key: "↵"
            action: root.target ? root.actionName(root.target) : ""
        }

        KeyHint {
            visible: !!root.target?.known
            key: "DEL"
            action: "FORGET"
        }

        Item {
            Layout.fillWidth: true
        }

        PopupLabel {
            text: "ADVANCED"
            color: advancedHover.hovered ? Theme.textPrimary : Theme.textSecondary

            HoverHandler {
                id: advancedHover
                cursorShape: Qt.PointingHandCursor
            }

            TapHandler {
                onTapped: root.advanced()
            }
        }
    }
}
