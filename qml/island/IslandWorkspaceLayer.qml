import QtQuick
import "../theme"

Item {
    id: root

    property string workspaceName: "1"
    property int workspaceId: 1

    anchors.fill: parent

    Row {
        anchors.centerIn: parent
        spacing: 8

        Rectangle {
            width: 18
            height: 18
            radius: 9
            color: Colors.accent
            anchors.verticalCenter: parent.verticalCenter

            Text {
                anchors.centerIn: parent
                text: "✦"
                color: "white"
                font.pixelSize: 10
            }
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: "Workspace " + (root.workspaceName || root.workspaceId)
            color: Theme.text
            font.pixelSize: 13
            font.weight: Font.Bold
        }
    }
}
