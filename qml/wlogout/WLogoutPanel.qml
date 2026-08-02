import QtQuick
import Quickshell
import Quickshell.Wayland
import "../island"
import "../theme"

Item {
    id: root

    property bool shown: false

    function toggle() { shown = !shown; }
    function show() { shown = true; }
    function hide() { shown = false; }

    PanelWindow {
        id: win
        visible: root.shown
        color: "transparent"
        focusable: true

        anchors { top: true; left: true; right: true }
        margins.top: 16
        implicitHeight: Theme.logoutHeight + 20

        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "nowoward-capdynamic-wlogout"
        WlrLayershell.keyboardFocus:
            root.shown ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

        // Centered top wlogout capsule bar
        Rectangle {
            id: capsule
            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter

            width: Theme.logoutWidth + 24
            height: Theme.logoutHeight + 16
            radius: 26

            color: Colors.background
            border.color: Colors.border
            border.width: 1

            focus: root.shown
            Keys.onEscapePressed: root.hide()

            scale: root.shown ? 1 : 0.95
            opacity: root.shown ? 1 : 0

            Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
            Behavior on opacity { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }

            IslandLogoutLayer {
                id: logoutLayer
                anchors.centerIn: parent
                width: Theme.logoutWidth
                height: Theme.logoutHeight
                focus: root.shown

                onActionTriggered: root.hide()
            }

            Connections {
                target: root
                function onShownChanged() {
                    if (root.shown) {
                        logoutLayer.forceActiveFocus();
                    }
                }
            }
        }
    }
}
