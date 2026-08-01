import QtQuick
import "../services"
import "../theme"

Item {
    id: root

    anchors.fill: parent

    Column {
        anchors.centerIn: parent
        width: parent.width - 24
        spacing: 10

        // ── 1. Top Row: Wi-Fi & Bluetooth Toggle Pills ───────────
        Row {
            width: parent.width
            spacing: 10

            // Wi-Fi Pill
            Rectangle {
                width: (parent.width - 10) / 2
                height: 48
                radius: 14
                color: NetworkService.enabled ? "#253852" : "#202020"
                border.color: NetworkService.enabled ? "#4f83cc" : Theme.border
                border.width: 1

                Row {
                    anchors.fill: parent
                    anchors.margins: 8
                    spacing: 8

                    Rectangle {
                        width: 32
                        height: 32
                        radius: 10
                        color: NetworkService.enabled ? Colors.accent : "#333333"
                        anchors.verticalCenter: parent.verticalCenter

                        Text {
                            anchors.centerIn: parent
                            text: "📶"
                            font.pixelSize: 14
                        }
                    }

                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - 48
                        spacing: 1

                        Text {
                            text: "Wi-Fi"
                            color: Theme.text
                            font.pixelSize: 12
                            font.weight: Font.Bold
                        }
                        Text {
                            width: parent.width
                            text: NetworkService.ssid
                            color: Theme.subtext
                            font.pixelSize: 10
                            elide: Text.ElideRight
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: NetworkService.toggleWifi()
                }
            }

            // Bluetooth Pill
            Rectangle {
                width: (parent.width - 10) / 2
                height: 48
                radius: 14
                color: BluetoothService.enabled ? "#253852" : "#202020"
                border.color: BluetoothService.enabled ? "#4f83cc" : Theme.border
                border.width: 1

                Row {
                    anchors.fill: parent
                    anchors.margins: 8
                    spacing: 8

                    Rectangle {
                        width: 32
                        height: 32
                        radius: 10
                        color: BluetoothService.enabled ? Colors.accent : "#333333"
                        anchors.verticalCenter: parent.verticalCenter

                        Text {
                            anchors.centerIn: parent
                            text: "🔵"
                            font.pixelSize: 14
                        }
                    }

                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - 48
                        spacing: 1

                        Text {
                            text: "Bluetooth"
                            color: Theme.text
                            font.pixelSize: 12
                            font.weight: Font.Bold
                        }
                        Text {
                            width: parent.width
                            text: BluetoothService.statusText
                            color: Theme.subtext
                            font.pixelSize: 10
                            elide: Text.ElideRight
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: BluetoothService.toggleBluetooth()
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
                    height: 12
                    radius: 6
                    color: "#222222"
                    border.color: "#33ffffff"
                    border.width: 1

                    Rectangle {
                        height: parent.height
                        width: Math.max(12, parent.width * (BrightnessService.brightness / 100.0))
                        radius: 6
                        color: "#f59e0b"

                        Behavior on width { NumberAnimation { duration: 100 } }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onPressed: (mouse) => {
                            let pct = (mouse.x / width) * 100;
                            BrightnessService.setBrightness(pct);
                        }
                        onPositionChanged: (mouse) => {
                            if (pressed) {
                                let pct = (mouse.x / width) * 100;
                                BrightnessService.setBrightness(pct);
                            }
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
                    height: 12
                    radius: 6
                    color: "#222222"
                    border.color: "#33ffffff"
                    border.width: 1

                    Rectangle {
                        height: parent.height
                        width: Math.max(12, parent.width * (VolumeService.volume / 100.0))
                        radius: 6
                        color: Colors.accent

                        Behavior on width { NumberAnimation { duration: 100 } }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onPressed: (mouse) => {
                            let pct = (mouse.x / width) * 100;
                            VolumeService.setVolume(pct);
                        }
                        onPositionChanged: (mouse) => {
                            if (pressed) {
                                let pct = (mouse.x / width) * 100;
                                VolumeService.setVolume(pct);
                            }
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
                color: "#1d1d1d"
                border.color: Theme.border
                border.width: 1

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
                color: "#1d1d1d"
                border.color: Theme.border
                border.width: 1

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
                color: "#1d1d1d"
                border.color: Theme.border
                border.width: 1

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
