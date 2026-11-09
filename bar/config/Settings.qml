pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

import qs.common

Singleton {
    id: root

    // per-user config, created with defaults on first run and reloaded on save
    ConfigManager {
        path: Paths.localConfigPath("bar.config")
        watchChanges: true

        adapter: JsonAdapter {
            id: adapter
            property GeneralDto general: GeneralDto {}
            property ModulesDto modules: ModulesDto {}
        }
    }

    readonly property GeneralDto general: adapter.general
    readonly property ModulesDto modules: adapter.modules

    readonly property ShellScreen screen: Quickshell.screens.find(s => s.name === general.monitor) ?? Quickshell.screens[0]

    readonly property int workspaceCount: Utils.clamp(modules.workspaces.count || 4, 1, 10)

    // seconds; guard against 0/negative values polling in a tight loop
    function pollInterval(value: real, fallback: real): real {
        return value > 0 ? Math.max(value, 0.25) : fallback;
    }
}
