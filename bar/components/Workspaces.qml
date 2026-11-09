pragma ComponentBehavior: Bound
import QtQuick

import qs.bar.services

Row {
    id: root

    property int count: 5
    property int selectedIndex: WorkspaceManager.selectedWorkspaceId - 1  // workspace 1-based index

    height: parent.height

    Repeater {
        model: root.count

        Row {
            required property int index

            height: parent.height

            Workspace {
                active: parent.index === root.selectedIndex
                windows: WorkspaceManager.windows(parent.index + 1)
                onClicked: WorkspaceManager.focus(parent.index + 1)
            }

            Divider {}
        }
    }
}
