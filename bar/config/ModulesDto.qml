import QtQuick
import Quickshell.Io

JsonObject {
    component WorkspacesDto: JsonObject {
        property bool enabled: true
        property int count: 5
    }

    component PollingDto: JsonObject {
        property bool enabled: true
        // seconds between samples
        property real interval: 2
    }

    component NetworkDto: JsonObject {
        property bool enabled: true
    }

    component UserDto: JsonObject {
        property bool enabled: true
        // empty shows $USER
        property string label: ""
    }

    component StatusDto: JsonObject {
        property bool enabled: true
        // label after the clock, empty shows the system timezone (e.g. "PST")
        property string timezone: ""
    }

    property WorkspacesDto workspaces: WorkspacesDto {}
    property PollingDto cpu: PollingDto {}
    property PollingDto memory: PollingDto {
        interval: 1
    }
    property NetworkDto network: NetworkDto {}
    property UserDto user: UserDto {}
    property StatusDto status: StatusDto {}
}
