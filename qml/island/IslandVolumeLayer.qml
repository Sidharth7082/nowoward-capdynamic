import QtQuick
import "../services"
import "../theme"

Item {
    id: root

    property int volume: VolumeService.volume
    property bool muted: VolumeService.muted

    anchors.fill: parent

    Row {
        anchors.centerIn: parent
        spacing: 10
        width: parent.width - 24

        Text {
            text: root.muted ? "🔇" : (root.volume > 50 ? "🔊" : "🔉")
            font.pixelSize: 16
        }

        Rectangle {
            width: parent.width - 60
            height: 6
            radius: 3
            color: "#262626"
            border.color: "#33ffffff"
            border.width: 1
            anchors.verticalCenter: parent.verticalCenter

            Rectangle {
                height: parent.height
                width: parent.width * Math.min(1.0, Math.max(0.0, root.volume / 100.0))
                radius: 3
                color: root.muted ? Colors.danger : Colors.accent

                Behavior on width { NumberAnimation { duration: 150 } }
            }
        }

        Text {
            text: root.volume + "%"
            color: Theme.text
            font.pixelSize: 12
            font.weight: Font.DemiBold
            anchors.verticalCenter: parent.verticalCenter
        }
    }
}
