import QtQuick
import "../services"
import "../theme"

Item {
    id: root

    anchors.fill: parent

    Column {
        anchors.centerIn: parent
        width: parent.width - 32
        spacing: 12

        // Header
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "System Monitor"
            color: Theme.text
            font.pixelSize: 13
            font.weight: Font.Bold
        }

        // Stats grid / bars
        Row {
            width: parent.width
            spacing: 12

            // CPU Gauge
            Column {
                width: (parent.width - 24) / 3
                spacing: 4

                Item {
                    width: parent.width
                    height: 16
                    Text { anchors.left: parent.left; text: "CPU"; color: Theme.subtext; font.pixelSize: 11 }
                    Text { anchors.right: parent.right; text: CpuService.usagePercent.toFixed(0) + "%"; color: Theme.text; font.pixelSize: 11; font.weight: Font.DemiBold }
                }

                Rectangle {
                    width: parent.width
                    height: 6
                    radius: 3
                    color: "#262626"
                    border.color: "#33ffffff"
                    border.width: 1

                    Rectangle {
                        height: parent.height
                        width: parent.width * Math.min(1.0, Math.max(0.0, CpuService.usagePercent / 100.0))
                        radius: 3
                        color: CpuService.usagePercent > 80 ? Colors.danger : Colors.accent

                        Behavior on width { NumberAnimation { duration: 300 } }
                    }
                }
            }

            // RAM Gauge
            Column {
                width: (parent.width - 24) / 3
                spacing: 4

                Item {
                    width: parent.width
                    height: 16
                    Text { anchors.left: parent.left; text: "RAM"; color: Theme.subtext; font.pixelSize: 11 }
                    Text { anchors.right: parent.right; text: MemService.usagePercent.toFixed(0) + "%"; color: Theme.text; font.pixelSize: 11; font.weight: Font.DemiBold }
                }

                Rectangle {
                    width: parent.width
                    height: 6
                    radius: 3
                    color: "#262626"
                    border.color: "#33ffffff"
                    border.width: 1

                    Rectangle {
                        height: parent.height
                        width: parent.width * Math.min(1.0, Math.max(0.0, MemService.usagePercent / 100.0))
                        radius: 3
                        color: MemService.usagePercent > 85 ? Colors.warning : "#10b981"

                        Behavior on width { NumberAnimation { duration: 300 } }
                    }
                }
            }

            // BAT Gauge
            Column {
                width: (parent.width - 24) / 3
                spacing: 4

                Item {
                    width: parent.width
                    height: 16
                    Text { anchors.left: parent.left; text: BatteryService.charging ? "CHG" : "BAT"; color: Theme.subtext; font.pixelSize: 11 }
                    Text { anchors.right: parent.right; text: BatteryService.present ? BatteryService.percentage + "%" : "N/A"; color: Theme.text; font.pixelSize: 11; font.weight: Font.DemiBold }
                }

                Rectangle {
                    width: parent.width
                    height: 6
                    radius: 3
                    color: "#262626"
                    border.color: "#33ffffff"
                    border.width: 1

                    Rectangle {
                        height: parent.height
                        width: BatteryService.present ? parent.width * Math.min(1.0, Math.max(0.0, BatteryService.percentage / 100.0)) : parent.width
                        radius: 3
                        color: BatteryService.charging ? Colors.success : (BatteryService.percentage < 20 ? Colors.danger : Colors.accent)

                        Behavior on width { NumberAnimation { duration: 300 } }
                    }
                }
            }
        }
    }
}
