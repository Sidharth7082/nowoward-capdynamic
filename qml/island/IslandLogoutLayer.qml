import QtQuick
import Quickshell
import Quickshell.Io
import "../theme"

FocusScope {
    id: root

    signal actionTriggered()

    property int activeIndex: 0
    property bool activeIndexSetByMouse: false

    focus: true

    onVisibleChanged: {
        if (visible) {
            root.forceActiveFocus();
        }
    }

    Component.onCompleted: {
        root.forceActiveFocus();
    }

    Keys.onLeftPressed: {
        root.activeIndex = (root.activeIndex - 1 + 5) % 5;
        root.activeIndexSetByMouse = false;
    }

    Keys.onRightPressed: {
        root.activeIndex = (root.activeIndex + 1) % 5;
        root.activeIndexSetByMouse = false;
    }

    Keys.onUpPressed: {
        root.activeIndex = (root.activeIndex - 1 + 5) % 5;
        root.activeIndexSetByMouse = false;
    }

    Keys.onDownPressed: {
        root.activeIndex = (root.activeIndex + 1) % 5;
        root.activeIndexSetByMouse = false;
    }

    Keys.onTabPressed: {
        root.activeIndex = (root.activeIndex + 1) % 5;
        root.activeIndexSetByMouse = false;
    }

    Keys.onBacktabPressed: {
        root.activeIndex = (root.activeIndex - 1 + 5) % 5;
        root.activeIndexSetByMouse = false;
    }

    Keys.onReturnPressed: triggerAction(root.activeIndex)
    Keys.onSpacePressed: triggerAction(root.activeIndex)

    Keys.onPressed: (event) => {
        if (event.key === Qt.Key_1 || event.key === Qt.Key_L) {
            triggerAction(0);
            event.accepted = true;
        } else if (event.key === Qt.Key_2 || event.key === Qt.Key_U) {
            triggerAction(1);
            event.accepted = true;
        } else if (event.key === Qt.Key_3 || event.key === Qt.Key_E) {
            triggerAction(2);
            event.accepted = true;
        } else if (event.key === Qt.Key_4 || event.key === Qt.Key_R) {
            triggerAction(3);
            event.accepted = true;
        } else if (event.key === Qt.Key_5 || event.key === Qt.Key_P || event.key === Qt.Key_S) {
            triggerAction(4);
            event.accepted = true;
        } else if (event.key === Qt.Key_Escape || event.key === Qt.Key_Q) {
            root.actionTriggered();
            event.accepted = true;
        }
    }

    Process {
        id: procLock
        command: ["sh", "-c", "hyprlock || swaylock || loginctl lock-session"]
    }

    Process {
        id: procSuspend
        command: ["sh", "-c", "systemctl suspend"]
    }

    Process {
        id: procLogout
        command: ["sh", "-c", "hyprctl dispatch exit || swaymsg exit || loginctl terminate-session ${XDG_SESSION_ID:-self}"]
    }

    Process {
        id: procReboot
        command: ["sh", "-c", "systemctl reboot"]
    }

    Process {
        id: procPoweroff
        command: ["sh", "-c", "systemctl poweroff"]
    }

    function triggerAction(index) {
        root.actionTriggered();
        switch (index) {
        case 0:
            procLock.running = false;
            procLock.running = true;
            break;
        case 1:
            procSuspend.running = false;
            procSuspend.running = true;
            break;
        case 2:
            procLogout.running = false;
            procLogout.running = true;
            break;
        case 3:
            procReboot.running = false;
            procReboot.running = true;
            break;
        case 4:
            procPoweroff.running = false;
            procPoweroff.running = true;
            break;
        }
    }

    Row {
        anchors.centerIn: parent
        spacing: 8

        Repeater {
            model: [
                { name: "Lock", icon: "../../wlogout/icons/lock.svg", action: "lock", key: "L / 1" },
                { name: "Suspend", icon: "../../wlogout/icons/suspend.svg", action: "suspend", key: "U / 2" },
                { name: "Log Out", icon: "../../wlogout/icons/logout.svg", action: "logout", key: "E / 3" },
                { name: "Reboot", icon: "../../wlogout/icons/reboot.svg", action: "reboot", key: "R / 4" },
                { name: "Power Off", icon: "../../wlogout/icons/shutdown.svg", action: "shutdown", key: "S / 5" }
            ]

            Rectangle {
                id: btnRect

                required property var modelData
                required property int index

                readonly property bool isActive: root.activeIndex === index

                width: 94
                height: 78
                radius: 18

                color: isActive ? "#59b2c6" : "#1e252b"
                border.color: isActive ? "#64c5d9" : "transparent"
                border.width: isActive ? 1 : 0

                scale: btnArea.pressed ? 0.95 : (btnArea.containsMouse || isActive ? 1.02 : 1.0)

                Behavior on color { ColorAnimation { duration: 150 } }
                Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

                Column {
                    anchors.centerIn: parent
                    spacing: 6

                    Item {
                        width: 28
                        height: 28
                        anchors.horizontalCenter: parent.horizontalCenter

                        Image {
                            id: iconImg
                            anchors.fill: parent
                            source: Qt.resolvedUrl(btnRect.modelData.icon)
                            fillMode: Image.PreserveAspectFit
                            smooth: true
                        }
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: btnRect.modelData.name
                        color: btnRect.isActive ? "#0c1014" : "#e6edf3"
                        font.pixelSize: 13
                        font.weight: Font.DemiBold
                        font.family: "system-ui, sans-serif"

                        Behavior on color { ColorAnimation { duration: 150 } }
                    }
                }

                MouseArea {
                    id: btnArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor

                    onEntered: {
                        root.activeIndex = btnRect.index;
                        root.activeIndexSetByMouse = true;
                    }

                    onClicked: {
                        root.triggerAction(btnRect.index);
                    }
                }
            }
        }
    }
}

