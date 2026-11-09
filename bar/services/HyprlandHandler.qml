pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland

Singleton {
    id: root

    // focusedWorkspace is null until Hyprland reports one; fall back to the first workspace
    property int selectedWorkspaceId: Hyprland.focusedWorkspace?.id ?? 1

    // workspace id -> address of the window last focused there
    property var _lastFocused: ({})

    // App ids of a workspace's windows, the one last focused there first
    function windows(workspaceId: int): var {
        const workspace = Hyprland.workspaces.values.find(w => w.id === workspaceId);
        const toplevels = workspace ? workspace.toplevels.values : [];
        const lead = root._lastFocused[workspaceId];
        return toplevels.slice().sort((a, b) => (b.address === lead) - (a.address === lead)).map(root._appId);
    }

    function focus(workspaceId: int) {
        // dispatching the current workspace jumps back to the previous one; stay put instead
        if (workspaceId === root.selectedWorkspaceId)
            return;
        Hyprland.dispatch(`workspace ${workspaceId}`);
    }

    function _appId(toplevel: HyprlandToplevel): string {
        return toplevel.wayland?.appId || toplevel.lastIpcObject?.class || "";
    }

    Connections {
        target: Hyprland

        function onActiveToplevelChanged() {
            const toplevel = Hyprland.activeToplevel;
            const workspaceId = toplevel?.workspace?.id;
            if (workspaceId === undefined || root._lastFocused[workspaceId] === toplevel.address)
                return;
            root._lastFocused = Object.assign({}, root._lastFocused, {
                [workspaceId]: toplevel.address
            });
        }
    }

    // lastIpcObject (the fallback app id) is only filled after a refresh
    Component.onCompleted: Hyprland.refreshToplevels()
}
