import QtQuick
import "../theme"

Item {
    id: root

    property var notification: null
    signal expansionToggleRequested()

    property bool expanded: false

    readonly property string summaryText: notification ? (notification.summary || notification.appName || "") : ""
    readonly property string bodyText: notification ? (notification.body || "") : ""

    readonly property string contentText: {
        if (summaryText !== "" && bodyText !== "" && bodyText !== summaryText)
            return summaryText + ": " + bodyText;
        if (summaryText !== "") return summaryText;
        if (bodyText !== "") return bodyText;
        return "New Notification";
    }

    anchors.fill: parent

    Row {
        id: mainRow
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        anchors.topMargin: 8
        anchors.bottomMargin: 8
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
                font.pixelSize: 12
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

        // Notification Text Area
        Item {
            width: parent.width - 34
            height: parent.height

            // Compact View
            Text {
                visible: !root.expanded
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width
                text: root.contentText
                color: Theme.text
                font.pixelSize: 13
                font.weight: Font.DemiBold
                elide: Text.ElideRight
                maximumLineCount: 1
            }

            // Expanded View (Flickable Scrollable Overflow)
            Flickable {
                visible: root.expanded
                anchors.fill: parent
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                contentWidth: width
                contentHeight: expandedText.implicitHeight

                Text {
                    id: expandedText
                    width: parent.width
                    text: root.contentText
                    color: Theme.text
                    font.pixelSize: 12
                    font.weight: Font.Medium
                    wrapMode: Text.WordWrap
                }
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: {
            if (root.bodyText.length > 30 || root.summaryText.length > 30) {
                root.expanded = !root.expanded;
                root.expansionToggleRequested();
            }
        }
    }
}
