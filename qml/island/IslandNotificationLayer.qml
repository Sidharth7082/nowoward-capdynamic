import QtQuick
import "../theme"

Item {
    id: root

    property var notification: null
    signal dismissed()

    implicitWidth: 320
    implicitHeight: 96

    Row {
        id: mainRow
        anchors.fill: parent
        anchors.margins: 14
        spacing: 12

        // Notification Icon or App badge
        Rectangle {
            width: 44
            height: 44
            radius: 22
            color: "#2a2a2a"
            border.color: Theme.border
            border.width: 1
            anchors.verticalCenter: parent.verticalCenter

            Text {
                anchors.centerIn: parent
                text: "🔔"
                font.pixelSize: 20
            }
        }

        // Title and Body
        Column {
            width: parent.width - 56
            anchors.verticalCenter: parent.verticalCenter
            spacing: 4

            Text {
                width: parent.width
                text: root.notification ? (root.notification.summary || root.notification.appName || "Notification") : ""
                color: Theme.text
                font.pixelSize: 14
                font.weight: Font.Bold
                elide: Text.ElideRight
            }

            Text {
                width: parent.width
                text: root.notification ? (root.notification.body || "") : ""
                color: Theme.subtext
                font.pixelSize: 12
                maximumLineCount: 2
                wrapMode: Text.WordWrap
                elide: Text.ElideRight
            }
        }
    }
}
