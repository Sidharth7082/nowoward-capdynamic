import QtQuick
import Quickshell
import Quickshell.Io
import "../theme"

Item {
    id: root

    signal actionTriggered()

    property int activeIndex: 0
    property bool activeIndexSetByMouse: false

    FocusScope {
        id: focusScope
        anchors.fill: parent
        focus: true

        Keys.onLeftPressed: {
            root.activeIndex = (root.activeIndex - 1 + 5) % 5;
            root.activeIndexSetByMouse = false;
        }

        Keys.onRightPressed: {
            root.activeIndex = (root.activeIndex + 1) % 5;
            root.activeIndexSetByMouse = false;
        }

        Keys.onReturnPressed: triggerAction(root.activeIndex)
        Keys.onSpacePressed: triggerAction(root.activeIndex)

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
            command: ["sh", "-c", "hyprctl dispatch exit || loginctl terminate-user $USER"]
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
                    { name: "Lock", icon: "../../wlogout/icons/lock.svg", action: "lock" },
                    { name: "Suspend", icon: "../../wlogout/icons/suspend.svg", action: "suspend" },
                    { name: "Log Out", icon: "../../wlogout/icons/logout.svg", action: "logout" },
                    { name: "Reboot", icon: "../../wlogout/icons/reboot.svg", action: "reboot" },
                    { name: "Power Off", icon: "../../wlogout/icons/shutdown.svg", action: "shutdown" }
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
                            focusScope.triggerAction(btnRect.index);
                        }
                    }
                }
            }
        }
    }
}
