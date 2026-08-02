import QtQuick

Item {
    id: root

    property var controller
    property var userActivityCallback: null
    readonly property var mpris: controller

    function notifyUserActivity() {
        if (userActivityCallback)
            userActivityCallback();
    }

    function formatTime(totalSeconds) {
        const t = Math.max(0, Math.floor(totalSeconds || 0));
        const m = Math.floor(t / 60);
        const s = t % 60;
        return m + ":" + (s < 10 ? "0" : "") + s;
    }

    // ---- Empty state: nothing playing anywhere ----
    Column {
        anchors.centerIn: parent
        spacing: 6
        visible: !mpris || !mpris.hasPlayer

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "♪"
            color: "#666666"
            font.pixelSize: 22
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "Nothing playing"
            color: "#888888"
            font.pixelSize: 13
        }
    }

    // ---- Now-playing state ----
    Column {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 10
        visible: !!mpris && mpris.hasPlayer

        Row {
            width: parent.width
            spacing: 10

            Rectangle {
                id: albumArt
                width: 40
                height: 40
                radius: 8
                color: "#3a2a4a"
                border.color: "#33ffffff"
                border.width: 1
                clip: true

                Image {
                    anchors.fill: parent
                    source: mpris.artUrl
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    visible: mpris.artUrl !== ""
                }

                Text {
                    anchors.centerIn: parent
                    visible: mpris.artUrl === ""
                    text: "♪"
                    color: "#c084fc"
                    font.pixelSize: 18
                }
            }

            Column {
                width: parent.width - albumArt.width - visualizer.width - 20
                anchors.verticalCenter: albumArt.verticalCenter
                spacing: 2

                Text {
                    width: parent.width
                    text: mpris.title !== "" ? mpris.title : mpris.sourceApp
                    color: "#c084fc"
                    font.pixelSize: 15
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                }
                Text {
                    width: parent.width
                    text: mpris.artist !== "" ? mpris.artist : mpris.sourceApp
                    color: "#9d7fce"
                    font.pixelSize: 12
                    elide: Text.ElideRight
                }
            }

            MusicVisualizer {
                id: visualizer
                anchors.verticalCenter: albumArt.verticalCenter
                playing: mpris.playing
            }
        }

        // Progress bar
        Column {
            width: parent.width
            spacing: 4

            Rectangle {
                id: track
                width: parent.width
                height: 3
                radius: 1.5
                color: "#3a3a3a"

                Rectangle {
                    width: track.width * (mpris.length > 0 ? mpris.position / mpris.length : 0)
                    height: parent.height
                    radius: parent.radius
                    color: "white"

                    Behavior on width {
                        NumberAnimation { duration: 300; easing.type: Easing.Linear }
                    }
                }

                Rectangle {
                    width: 8
                    height: 8
                    radius: 4
                    color: "white"
                    y: (track.height - height) / 2
                    x: track.width * (mpris.length > 0 ? mpris.position / mpris.length : 0) - width / 2

                    Behavior on x {
                        NumberAnimation { duration: 300; easing.type: Easing.Linear }
                    }
                }
            }

            Row {
                width: parent.width

                Text {
                    text: root.formatTime(mpris.position)
                    color: "#999999"
                    font.pixelSize: 11
                }
                Item { width: parent.width - 80; height: 1 }
                Text {
                    text: root.formatTime(mpris.length)
                    color: "#999999"
                    font.pixelSize: 11
                }
            }
        }

        // Transport controls
        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 28

            Text {
                text: "⏮"
                color: mpris && mpris.hasPlayer ? "white" : "#777777"
                font.pixelSize: 18
                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -8
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (mpris) mpris.previous();
                        root.notifyUserActivity();
                    }
                }
            }

            Rectangle {
                width: 34
                height: 34
                radius: 17
                color: "white"

                Text {
                    anchors.centerIn: parent
                    anchors.horizontalCenterOffset: (mpris && mpris.playing) ? 0 : 1
                    text: (mpris && mpris.playing) ? "⏸" : "▶"
                    color: "black"
                    font.pixelSize: 14
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (mpris) mpris.playPause();
                        root.notifyUserActivity();
                    }
                }
            }

            Text {
                text: "⏭"
                color: mpris && mpris.hasPlayer ? "white" : "#777777"
                font.pixelSize: 18
                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -8
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (mpris) mpris.next();
                        root.notifyUserActivity();
                    }
                }
            }
        }
    }
}
