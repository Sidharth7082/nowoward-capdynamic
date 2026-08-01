import QtQuick
import "../theme"

Item {
    id: root

    property var notification: null
    signal dismissed()

    anchors.fill: parent

    Row {
        anchors.centerIn: parent
        spacing: 10

        // Animated Bell Badge
        Rectangle {
            id: bellBadge
            width: 24
            height: 24
            radius: 12
            color: Colors.accent
            anchors.verticalCenter: parent.verticalCenter

            Text {
                id: bellIcon
                anchors.centerIn: parent
                text: "🔔"
                font.pixelSize: 13
                transformOrigin: Item.Center

                SequentialAnimation {
                    id: bellWiggle
                    running: root.visible
                    loops: 2

                    NumberAnimation { target: bellIcon; property: "rotation"; from: 0; to: -18; duration: 80 }
                    NumberAnimation { target: bellIcon; property: "rotation"; from: -18; to: 18; duration: 120 }
                    NumberAnimation { target: bellIcon; property: "rotation"; from: 18; to: -10; duration: 80 }
                    NumberAnimation { target: bellIcon; property: "rotation"; from: -10; to: 0; duration: 60 }
                }
            }
        }

        // Notification Text
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.notification
                ? ((root.notification.summary ? root.notification.summary : root.notification.appName) || "Notification")
                : "Notification"
            color: Theme.text
            font.pixelSize: 13
            font.weight: Font.DemiBold
            elide: Text.ElideRight
            maximumLineCount: 1
        }
    }
}
