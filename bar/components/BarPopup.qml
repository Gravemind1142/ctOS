pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts

import Quickshell

import qs.common
import qs.bar.components

// Shell for a menu dropped from a bar segment: a `surface` panel with a hairline `frame`
// outline that tiles onto the bar's bottom edge under the segment, a label block across the
// top (`title` left, `status` right) and the menu's content stacked under it. Drops in at
// durationShort; click outside or Escape to close.
PopupWindow {
    id: root

    // the segment it hangs from
    required property Item segment
    property string title: ""
    property string status: ""
    // hang left from the segment's right edge, for segments on the right of the bar
    property bool alignRight: false
    // content stacked under the label block
    default property alias content: body.data

    // when it last closed: the click outside that dismisses it can land on the segment too
    property real closedAt: 0

    function toggle(): void {
        if (!visible && Date.now() - closedAt < Theme.durationMedium) {
            return;
        }
        visible = !visible;
    }

    anchor {
        item: segment
        // overlap the bar's border so the two frames share one rule
        rect.x: alignRight ? segment.width : 0
        rect.y: segment.height - Theme.strokeHairline
        edges: Edges.Top | Edges.Left
        gravity: Edges.Bottom | (alignRight ? Edges.Left : Edges.Right)
    }

    implicitWidth: Theme.popupWidth
    implicitHeight: panel.height
    color: "transparent"
    grabFocus: true

    onVisibleChanged: {
        if (visible) {
            reveal.restart();
        } else {
            closedAt = Date.now();
        }
    }

    // keeps the drop clipped to the popup while it slides in
    FocusScope {
        anchors.fill: parent
        clip: true
        focus: true

        Keys.onEscapePressed: root.visible = false

        Rectangle {
            id: panel

            width: parent.width
            height: body.implicitHeight + 2 * Theme.strokeHairline
            color: Theme.surface
            border {
                width: Theme.strokeHairline
                color: Theme.frame
            }

            NumberAnimation {
                id: reveal
                target: panel
                property: "y"
                from: -panel.height
                to: 0
                duration: Theme.durationShort
                easing.type: Theme.easeEnter
            }

            ColumnLayout {
                id: body

                anchors {
                    left: parent.left
                    right: parent.right
                    top: parent.top
                    margins: Theme.strokeHairline
                }
                spacing: 0

                // label block on the frame's top edge
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: header.implicitHeight + 2 * Theme.spaceXs
                    color: Theme.labelFill

                    RowLayout {
                        id: header
                        anchors {
                            fill: parent
                            leftMargin: Theme.controlPadding
                            rightMargin: Theme.controlPadding
                        }

                        PopupLabel {
                            text: root.title
                            color: Theme.labelText
                        }

                        Item {
                            Layout.fillWidth: true
                        }

                        PopupLabel {
                            text: root.status
                            color: Theme.labelText
                        }
                    }
                }
            }
        }
    }
}
