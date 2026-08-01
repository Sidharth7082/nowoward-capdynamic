import QtQuick
import "../services"
import "../theme"

Item {
    id: root

    signal wifiRightClicked()
    signal btRightClicked()

    anchors.fill: parent

    Column {
        anchors.centerIn: parent
        width: parent.width - 24
        spacing: 10

        // ── 1. Top Row: Wi-Fi & Bluetooth Dynamic Pill Tiles ─────
        Row {
            width: parent.width
            spacing: 10

            // Wi-Fi Pill Tile
            Rectangle {
                id: wifiTile
                width: (parent.width - 10) / 2
                height: 50
                radius: 14
                color: NetworkService.enabled ? "#1e3a8a" : "#181818"
                border.color: NetworkService.enabled ? "#3b82f6" : "#282828"
                border.width: 1

                scale: wifiArea.pressed ? 0.96 : (wifiArea.containsMouse ? 1.02 : 1.0)
                Behavior on scale { NumberAnimation { duration: 120 } }
                Behavior on color { ColorAnimation { duration: 200 } }
                Behavior on border.color { ColorAnimation { duration: 200 } }

                Row {
                    anchors.fill: parent
                    anchors.margins: 8
                    spacing: 8

                    Rectangle {
                        width: 34
                        height: 34
                        radius: 10
                        color: NetworkService.enabled ? "#2563eb" : "#2a2a2a"
                        anchors.verticalCenter: parent.verticalCenter
                        Behavior on color { ColorAnimation { duration: 200 } }

                        Text {
                            anchors.centerIn: parent
                            text: "📶"
                            font.pixelSize: 15
                        }
                    }

                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - 50
                        spacing: 1

                        Row {
                            spacing: 4
                            Text {
                                text: "Wi-Fi"
                                color: Theme.text
                                font.pixelSize: 12
                                font.weight: Font.Bold
                            }
                            Text {
                                text: NetworkService.enabled ? "🟢" : "⚪"
                                font.pixelSize: 8
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }
                        Text {
                            width: parent.width
                            text: NetworkService.ssid
                            color: NetworkService.enabled ? "#93c5fd" : Theme.subtext
                            font.pixelSize: 10
                            elide: Text.ElideRight
                        }
                    }
                }

                MouseArea {
                    id: wifiArea
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    acceptedButtons: Qt.LeftButton | Qt.RightButton

                    onClicked: (mouse) => {
                        if (mouse.button === Qt.LeftButton) {
                            NetworkService.toggleWifi();
                        } else if (mouse.button === Qt.RightButton) {
                            root.wifiRightClicked();
                        }
                    }
                }
            }

            // Bluetooth Pill Tile
            Rectangle {
                id: btTile
                width: (parent.width - 10) / 2
                height: 50
                radius: 14
                color: BluetoothService.enabled ? "#311b92" : "#181818"
                border.color: BluetoothService.enabled ? "#8b5cf6" : "#282828"
                border.width: 1

                scale: btArea.pressed ? 0.96 : (btArea.containsMouse ? 1.02 : 1.0)
                Behavior on scale { NumberAnimation { duration: 120 } }
                Behavior on color { ColorAnimation { duration: 200 } }
                Behavior on border.color { ColorAnimation { duration: 200 } }

                Row {
                    anchors.fill: parent
                    anchors.margins: 8
                    spacing: 8

                    Rectangle {
                        width: 34
                        height: 34
                        radius: 10
                        color: BluetoothService.enabled ? "#7c3aed" : "#2a2a2a"
                        anchors.verticalCenter: parent.verticalCenter
                        Behavior on color { ColorAnimation { duration: 200 } }

                        Text {
                            anchors.centerIn: parent
                            text: "🔵"
                            font.pixelSize: 15
                        }
                    }

                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - 50
                        spacing: 1

                        Row {
                            spacing: 4
                            Text {
                                text: "Bluetooth"
                                color: Theme.text
                                font.pixelSize: 12
                                font.weight: Font.Bold
                            }
                            Text {
                                text: BluetoothService.enabled ? "🟢" : "⚪"
                                font.pixelSize: 8
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }
                        Text {
                            width: parent.width
                            text: BluetoothService.statusText
                            color: BluetoothService.enabled ? "#c4b5fd" : Theme.subtext
                            font.pixelSize: 10
                            elide: Text.ElideRight
                        }
                    }
                }

                MouseArea {
                    id: btArea
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    acceptedButtons: Qt.LeftButton | Qt.RightButton

                    onClicked: (mouse) => {
                        if (mouse.button === Qt.LeftButton) {
                            BluetoothService.toggleBluetooth();
                        } else if (mouse.button === Qt.RightButton) {
                            root.btRightClicked();
                        }
                    }
                }
            }
        }

        // ── 2. Middle Sliders: Brightness & Volume ────────────────
        Column {
            width: parent.width
            spacing: 8

            // Brightness Slider
            Column {
                width: parent.width
                spacing: 3

                Item {
                    width: parent.width
                    height: 14
                    Text {
                        anchors.left: parent.left
                        text: "☀  Brightness"
                        color: Theme.subtext
                        font.pixelSize: 11
                        font.weight: Font.DemiBold
                    }
                    Text {
                        anchors.right: parent.right
                        text: BrightnessService.brightness + "%"
                        color: Theme.text
                        font.pixelSize: 11
                        font.weight: Font.Bold
                    }
                }

                Rectangle {
                    id: brightTrack
                    width: parent.width
                    height: 14
                    radius: 7
                    color: "#222222"
                    border.color: "#33ffffff"
                    border.width: 1

                    Rectangle {
                        height: parent.height
                        width: Math.max(14, parent.width * (BrightnessService.brightness / 100.0))
                        radius: 7
                        color: "#f59e0b"

                        Behavior on width { NumberAnimation { duration: 80 } }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        preventStealing: true

                        function updateValue(mouseX) {
                            if (mouseX < 0 || mouseX > width) return;
                            let pct = Math.max(0, Math.min(100, Math.round((mouseX / width) * 100)));
                            BrightnessService.setBrightness(pct);
                        }

                        onPressed: (mouse) => updateValue(mouse.x)
                        onPositionChanged: (mouse) => {
                            if (pressed) updateValue(mouse.x);
                        }
                    }
                }
            }

            // Volume Slider
            Column {
                width: parent.width
                spacing: 3

                Item {
                    width: parent.width
                    height: 14
                    Text {
                        anchors.left: parent.left
                        text: "🔊  Volume"
                        color: Theme.subtext
                        font.pixelSize: 11
                        font.weight: Font.DemiBold
                    }
                    Text {
                        anchors.right: parent.right
                        text: VolumeService.volume + "%"
                        color: Theme.text
                        font.pixelSize: 11
                        font.weight: Font.Bold
                    }
                }

                Rectangle {
                    id: volTrack
                    width: parent.width
                    height: 14
                    radius: 7
                    color: "#222222"
                    border.color: "#33ffffff"
                    border.width: 1

                    Rectangle {
                        height: parent.height
                        width: Math.max(14, parent.width * (VolumeService.volume / 100.0))
                        radius: 7
                        color: Colors.accent

                        Behavior on width { NumberAnimation { duration: 80 } }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        preventStealing: true

                        function updateValue(mouseX) {
                            if (mouseX < 0 || mouseX > width) return;
                            let pct = Math.max(0, Math.min(100, Math.round((mouseX / width) * 100)));
                            VolumeService.setVolume(pct);
                        }

                        onPressed: (mouse) => updateValue(mouse.x)
                        onPositionChanged: (mouse) => {
                            if (pressed) updateValue(mouse.x);
                        }
                    }
                }
            }
        }

        // ── 3. Bottom Row: Battery, CPU, RAM Badges ──────────────
        Row {
            width: parent.width
            spacing: 6

            // Battery Badge
            Rectangle {
                width: (parent.width - 12) / 3
                height: 28
                radius: 8
                color: "#181818"
                border.color: Theme.border
                border.width: 1
                clip: true

                Rectangle {
                    anchors.bottom: parent.bottom
                    anchors.left: parent.left
                    height: 3
                    width: parent.width * ((BatteryService.present ? BatteryService.percentage : 98) / 100.0)
                    color: "#10b981"
                    radius: 1.5
                    Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
                }

                Row {
                    anchors.centerIn: parent
                    spacing: 4
                    Text { text: BatteryService.charging ? "⚡" : "🔋"; font.pixelSize: 11 }
                    Text {
                        text: BatteryService.present ? BatteryService.percentage + "%" : "98%"
                        color: Theme.text
                        font.pixelSize: 11
                        font.weight: Font.Bold
                    }
                }
            }

            // CPU Badge
            Rectangle {
                width: (parent.width - 12) / 3
                height: 28
                radius: 8
                color: "#181818"
                border.color: Theme.border
                border.width: 1
                clip: true

                Rectangle {
                    anchors.bottom: parent.bottom
                    anchors.left: parent.left
                    height: 3
                    width: parent.width * Math.min(1.0, CpuService.usagePercent / 100.0)
                    color: "#3b82f6"
                    radius: 1.5
                    Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
                }

                Row {
                    anchors.centerIn: parent
                    spacing: 4
                    Text { text: "🧠"; font.pixelSize: 11 }
                    Text {
                        text: "CPU " + CpuService.usagePercent.toFixed(0) + "%"
                        color: Theme.text
                        font.pixelSize: 11
                        font.weight: Font.Bold
                    }
                }
            }

            // RAM Badge
            Rectangle {
                width: (parent.width - 12) / 3
                height: 28
                radius: 8
                color: "#181818"
                border.color: Theme.border
                border.width: 1
                clip: true

                Rectangle {
                    anchors.bottom: parent.bottom
                    anchors.left: parent.left
                    height: 3
                    width: parent.width * Math.min(1.0, MemService.usagePercent / 100.0)
                    color: "#a855f7"
                    radius: 1.5
                    Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
                }

                Row {
                    anchors.centerIn: parent
                    spacing: 4
                    Text { text: "💾"; font.pixelSize: 11 }
                    Text {
                        text: "RAM " + MemService.usagePercent.toFixed(0) + "%"
                        color: Theme.text
                        font.pixelSize: 11
                        font.weight: Font.Bold
                    }
                }
            }
        }
    }
}
