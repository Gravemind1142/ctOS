pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland

Singleton {
    // focusedWorkspace is null until Hyprland reports one; fall back to the first workspace
    property int selectedWorkspaceId: Hyprland.focusedWorkspace?.id ?? 1
}
