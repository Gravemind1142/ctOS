import QtQuick
import Quickshell.Io

JsonObject {
    component WorkspacesDto: JsonObject {
        property bool enabled: true
        property int count: 4
    }

    component TrayDto: JsonObject {
        property bool enabled: true
    }

    component PollingDto: JsonObject {
        property bool enabled: true
        // seconds between samples
        property real interval: 2
    }

    component CpuDto: PollingDto {
        // a process over this share of one core for two samples in a row is flagged
        property real threshold: 80
    }

    component MemoryDto: PollingDto {
        // a process holding this share of physical memory is flagged
        property real threshold: 20
    }

    component NetworkDto: JsonObject {
        property bool enabled: true
        // run by the network menu's ADVANCED action, and for enterprise (EAP) networks
        property string command: "kitty --class ctos-network -e nmtui"
    }

    component BatteryDto: JsonObject {
        property bool enabled: true
    }

    // run by the session menu's rows; an empty command hides its row
    component SessionCommandsDto: JsonObject {
        property string lock: "loginctl lock-session"
        property string logout: "hyprctl dispatch exit"
        property string suspend: "systemctl suspend"
        property string reboot: "systemctl reboot"
        property string shutdown: "systemctl poweroff"
    }

    component UserDto: JsonObject {
        property bool enabled: true
        // empty shows $USER
        property string label: ""
        property SessionCommandsDto commands: SessionCommandsDto {}
    }

    component StatusDto: JsonObject {
        property bool enabled: true
        // label after the clock, empty shows the system timezone (e.g. "PST")
        property string timezone: ""
    }

    component KeybindsDto: JsonObject {
        // the [?] KEYS cell; the cheatsheet still opens from its keybind when hidden
        property bool enabled: true
    }

    property WorkspacesDto workspaces: WorkspacesDto {}
    property TrayDto tray: TrayDto {}
    property CpuDto cpu: CpuDto {}
    property MemoryDto memory: MemoryDto {
        interval: 1
    }
    property BatteryDto battery: BatteryDto {}
    property NetworkDto network: NetworkDto {}
    property UserDto user: UserDto {}
    property StatusDto status: StatusDto {}
    property KeybindsDto keybinds: KeybindsDto {}
}
