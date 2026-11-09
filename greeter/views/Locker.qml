import Quickshell.Wayland
import QtQuick

import qs.common
import qs.greeter.services
import qs.greeter.config
import qs.greeter.components

WlSessionLock {
    id: lock

    locked: AuthManager.state !== AuthManager.State.Finish

    WlSessionLockSurface {
        id: lockSurface

        Rectangle {
            anchors.fill: parent
            color: Theme.background
        }

        Loader {
            // race condition where lockSurface.screen isn't available yet
            active: lockSurface.screen ? lockSurface.screen.name === Settings.monitor : false
            anchors.fill: parent
            sourceComponent: MainLayout {}
        }
    }
}
