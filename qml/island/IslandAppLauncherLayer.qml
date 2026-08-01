import QtQuick
import Quickshell.Io
import "../theme"

Item {
    id: root

    anchors.fill: parent
    anchors.margins: 14

    property var apps: [
        { name: "Terminal", icon: "💻", cmd: ["kitty"] },
        { name: "Browser", icon: "🌐", cmd: ["brave"] },
        { name: "Files", icon: "📁", cmd: ["thunar"] },
        { name: "Discord", icon: "💬", cmd: ["discord"] },
        { name: "Spotify", icon: "🎵", cmd: ["spotify"] }
    ]

    Process {
        id: appLauncherProc
    }

    function launchApp(cmdArray) {
        appLauncherProc.command = cmdArray;
        appLauncherProc.running = true;
    }

    Column {
        width: parent.width
        height: parent.height
        spacing: 12

        Text {
            text: "🚀 Quick App Launcher"
            color: Theme.text
            font.pixelSize: 14
            font.weight: Font.Bold
        }

        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 14

            Repeater {
                model: root.apps

                delegate: Rectangle {
                    width: 52
                    height: 52
                    radius: 16
                    color: appMouse.pressed ? "#44ffffff" : (appMouse.containsMouse ? "#30ffffff" : "#1bffffff")
                    border.width: 1
                    border.color: appMouse.containsMouse ? Colors.accent : "#18ffffff"

                    scale: appMouse.pressed ? 0.92 : (appMouse.containsMouse ? 1.08 : 1.0)
                    Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutBack } }

                    Column {
                        anchors.centerIn: parent
                        spacing: 2

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: modelData.icon
                            font.pixelSize: 20
                        }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: modelData.name
                            color: Theme.subtext
                            font.pixelSize: 9
                            font.weight: Font.Medium
                        }
                    }

                    MouseArea {
                        id: appMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: root.launchApp(modelData.cmd)
                    }
                }
            }
        }
    }
}
