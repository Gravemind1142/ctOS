pragma ComponentBehavior: Bound
import QtQuick

import Quickshell

import qs.common
import qs.bar.components

// Bar segment: date, time and zone as one terse readout (091126-0330-PST).
// The time is the live value; date and zone are dim, the dashes rule them apart.
Segment {
    id: root

    // label after the time; empty shows the system timezone
    property string zone: ""

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    component Part: Text {
        color: Theme.textPrimaryDim
        font {
            family: Theme.fontInsider
            pixelSize: Theme.fontSizeMd
            weight: Theme.fontWeightMedium
        }
    }

    component Rule: Part {
        text: "-"
        color: Theme.textSecondary
    }

    Part {
        text: Qt.formatDateTime(clock.date, "ddMMyy")
    }
    Rule {}
    Part {
        text: Qt.formatDateTime(clock.date, "hhmm")
        color: Theme.textPrimary
    }
    Rule {}
    Part {
        text: root.zone || Qt.formatDateTime(clock.date, "t")
    }
}
