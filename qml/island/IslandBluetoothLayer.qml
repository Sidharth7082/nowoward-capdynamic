import QtQuick
import "../services"
import "../theme"

Item {
    id: root

    signal backClicked()

    anchors.fill: parent

    Component.onCompleted: BluetoothService.scanDevices()
    onVisibleChanged: {
        if (visible) BluetoothService.scanDevices();
    }

    Column {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 8

        // ── Header: Back button, Title, Power Toggle ──────────────
        Item {
            width: parent.width
            height: 24

            Rectangle {
                width: 24
                height: 24
                radius: 12
                color: "#282828"
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter

                Text {
                    anchors.centerIn: parent
                    text: "←"
                    color: Theme.text
                    font.pixelSize: 13
                    font.weight: Font.Bold
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.backClicked()
                }
            }

            Row {
                anchors.centerIn: parent
                spacing: 6
                Text { text: "🔵"; font.pixelSize: 14 }
                Text {
                    text: "Bluetooth Devices"
                    color: Theme.text
                    font.pixelSize: 13
                    font.weight: Font.Bold
                }
            }

            // Power Toggle Button
            Rectangle {
                width: 54
                height: 22
                radius: 11
                color: BluetoothService.enabled ? Colors.accent : "#333333"
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter

                Text {
                    anchors.centerIn: parent
                    text: BluetoothService.enabled ? "ON" : "OFF"
                    color: Theme.text
                    font.pixelSize: 10
                    font.weight: Font.Bold
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: BluetoothService.toggleBluetooth()
                }
            }
        }

        // ── Sub-header: Current Status ───────────────────────────
        Rectangle {
            width: parent.width
            height: 24
            radius: 6
            color: "#181818"
            border.color: "#282828"
            border.width: 1

            Row {
                anchors.centerIn: parent
                spacing: 6
                Text {
                    text: BluetoothService.serviceActive ? (BluetoothService.enabled ? "● Status:" : "○ Power Off") : "⚠ Daemon:"
                    color: BluetoothService.serviceActive ? (BluetoothService.enabled ? "#10b981" : Theme.subtext) : "#ef4444"
                    font.pixelSize: 11
                    font.weight: Font.DemiBold
                }
                Text {
                    text: BluetoothService.statusText
                    color: Theme.text
                    font.pixelSize: 11
                    font.weight: Font.Bold
                }
            }
        }

        // ── Bluetooth Devices List / Service Start Prompt ────────
        Rectangle {
            width: parent.width
            height: 110
            radius: 10
            color: "#141414"
            border.color: "#262626"
            border.width: 1
            clip: true

            // When service is active
            ListView {
                anchors.fill: parent
                anchors.margins: 4
                spacing: 4
                visible: BluetoothService.serviceActive
                model: BluetoothService.deviceList

                delegate: Rectangle {
                    width: ListView.view.width - 8
                    height: 28
                    radius: 6
                    color: "#1e1e1e"
                    border.color: "#282828"
                    border.width: 1

                    Row {
                        anchors.fill: parent
                        anchors.leftMargin: 8
                        anchors.rightMargin: 8
                        spacing: 8

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "🎧"
                            font.pixelSize: 12
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width - 60
                            text: modelData.name || modelData.mac
                            color: Theme.text
                            font.pixelSize: 11
                            font.weight: Font.DemiBold
                            elide: Text.ElideRight
                        }
                    }
                }

                Text {
                    anchors.centerIn: parent
                    visible: BluetoothService.deviceList.length === 0
                    text: BluetoothService.enabled ? "Scanning nearby Bluetooth devices..." : "Turn on Bluetooth to view devices"
                    color: Theme.subtext
                    font.pixelSize: 11
                }
            }

            // When service is inactive / dead
            Column {
                anchors.centerIn: parent
                spacing: 8
                visible: !BluetoothService.serviceActive

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: BluetoothService.bluezInstalled
                        ? "Bluetooth Service (BlueZ) is stopped"
                        : "BlueZ is not installed"
                    color: "#ef4444"
                    font.pixelSize: 11
                    font.weight: Font.Bold
                }

                Rectangle {
                    width: 160
                    height: 26
                    radius: 6
                    color: "#2563eb"
                    anchors.horizontalCenter: parent.horizontalCenter

                    Row {
                        anchors.centerIn: parent
                        spacing: 4
                        Text { text: "⚡"; color: "white"; font.pixelSize: 11 }
                        Text { text: "Start Bluetooth Daemon"; color: "white"; font.pixelSize: 10; font.weight: Font.Bold }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: BluetoothService.startService()
                    }
                }

                // Actionable hint when the automatic start can't get root
                // (no polkit agent / no passwordless sudo).
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 190
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                    text: BluetoothService.hintText
                    color: "#fbbf24"
                    font.pixelSize: 10
                    visible: BluetoothService.hintText !== ""
                }
            }
        }

        // ── Action Footer Bar ─────────────────────────────────────
        Row {
            width: parent.width
            spacing: 8

            Rectangle {
                width: (parent.width - 8) / 2
                height: 24
                radius: 6
                color: "#222222"
                border.color: "#333333"
                border.width: 1

                Row {
                    anchors.centerIn: parent
                    spacing: 4
                    Text { text: "⟳"; color: Theme.text; font.pixelSize: 11 }
                    Text { text: "Refresh Scan"; color: Theme.text; font.pixelSize: 10; font.weight: Font.DemiBold }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: BluetoothService.scanDevices()
                }
            }

            Rectangle {
                width: (parent.width - 8) / 2
                height: 24
                radius: 6
                color: "#222222"
                border.color: "#333333"
                border.width: 1

                Row {
                    anchors.centerIn: parent
                    spacing: 4
                    Text { text: "⚙"; color: Theme.text; font.pixelSize: 11 }
                    Text { text: "Advanced (blueman)"; color: Theme.text; font.pixelSize: 10; font.weight: Font.DemiBold }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: BluetoothService.openSettings()
                }
            }
        }
    }
}
