import QtQuick
import QtQuick.Controls
import "../services"
import "../theme"

Item {
    id: root

    anchors.fill: parent
    anchors.margins: 14

    Column {
        width: parent.width
        height: parent.height
        spacing: 10

        // Header
        Item {
            width: parent.width
            height: 24

            Text {
                text: "🔔 Notification History"
                color: Theme.text
                font.pixelSize: 14
                font.weight: Font.Bold
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
            }

            Rectangle {
                width: 68
                height: 22
                radius: 11
                color: clearArea.pressed ? "#44ffffff" : "#20ffffff"
                visible: NotificationService.history.length > 0
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter

                Text {
                    anchors.centerIn: parent
                    text: "Clear All"
                    color: Theme.subtext
                    font.pixelSize: 10
                    font.weight: Font.Medium
                }

                MouseArea {
                    id: clearArea
                    anchors.fill: parent
                    onClicked: NotificationService.clearHistory()
                }
            }
        }

        // Empty state
        Text {
            visible: NotificationService.history.length === 0
            width: parent.width
            text: "No recent notifications"
            color: Theme.muted
            font.pixelSize: 12
            horizontalAlignment: Text.AlignHCenter
        }

        // Notification List
        ListView {
            width: parent.width
            height: parent.height - 34
            clip: true
            spacing: 8
            model: NotificationService.history
            visible: NotificationService.history.length > 0

            delegate: Rectangle {
                id: notifItemCard
                width: ListView.view.width
                height: 52
                radius: 10
                color: itemMouse.pressed ? "#33ffffff" : (itemMouse.containsMouse ? "#22ffffff" : "#18ffffff")
                border.width: 1
                border.color: "#12ffffff"

                Row {
                    anchors.left: parent.left
                    anchors.leftMargin: 8
                    anchors.right: removeBtn.left
                    anchors.rightMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 10

                    Rectangle {
                        width: 32
                        height: 32
                        radius: 16
                        color: Colors.accent
                        anchors.verticalCenter: parent.verticalCenter

                        Text {
                            anchors.centerIn: parent
                            text: modelData.appName ? modelData.appName.charAt(0).toUpperCase() : "N"
                            color: "white"
                            font.pixelSize: 13
                            font.weight: Font.Bold
                        }
                    }

                    Column {
                        width: parent.width - 42
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 2

                        Row {
                            width: parent.width
                            spacing: 6

                            Text {
                                text: modelData.appName || "App"
                                color: Colors.accentHover
                                font.pixelSize: 11
                                font.weight: Font.Bold
                                elide: Text.ElideRight
                            }

                            Text {
                                text: "• " + (modelData.time || "")
                                color: Theme.muted
                                font.pixelSize: 10
                            }
                        }

                        Text {
                            width: parent.width
                            text: modelData.summary || modelData.body || ""
                            color: Theme.text
                            font.pixelSize: 12
                            elide: Text.ElideRight
                        }
                    }
                }

                // Individual Close Button (✕)
                Rectangle {
                    id: removeBtn
                    width: 22
                    height: 22
                    radius: 11
                    color: removeMouse.pressed ? "#44ffffff" : (removeMouse.containsMouse ? "#30ffffff" : "transparent")
                    anchors.right: parent.right
                    anchors.rightMargin: 8
                    anchors.verticalCenter: parent.verticalCenter

                    Text {
                        anchors.centerIn: parent
                        text: "✕"
                        color: removeMouse.containsMouse ? "#ef4444" : Theme.muted
                        font.pixelSize: 11
                        font.weight: Font.Bold
                    }

                    MouseArea {
                        id: removeMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: NotificationService.removeHistoryItem(modelData.id)
                    }
                }

                MouseArea {
                    id: itemMouse
                    anchors.fill: parent
                    anchors.rightMargin: 30
                    hoverEnabled: true
                    onClicked: NotificationService.removeHistoryItem(modelData.id)
                }
            }
        }
    }
}
