import QtQuick
import Quickshell.Services.Mpris
import "../theme"

// Clean now-playing card matching the original design language: compact album
// art, purple title/artist, thin seek bar (with drag + hover thumb), and a
// centered white transport cluster with shuffle/loop at the edges.
Item {
    id: root

    property var controller
    property var userActivityCallback: null
    readonly property var mpris: controller

    readonly property color accent: "#c084fc"
    readonly property color accentDim: "#9d7fce"

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

    // If the player loses seek support (or disappears) mid-drag, drop the
    // pending drag target so the bar doesn't stick at a stale position.
    Connections {
        target: root.mpris
        function onCanSeekChanged() {
            if (!mpris || !mpris.canSeek)
                track.dragFraction = -1;
        }
        function onHasPlayerChanged() {
            track.dragFraction = -1;
        }
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
        anchors.margins: 12
        spacing: 8
        visible: !!mpris && mpris.hasPlayer

        // ── Header: album art, title/artist, visualizer ──
        Row {
            width: parent.width
            spacing: 10

            Rectangle {
                id: albumArt
                width: 42
                height: 42
                radius: 9
                color: "#3a2a4a"
                border.color: "#33ffffff"
                border.width: 1
                clip: true

                Image {
                    id: artImg
                    anchors.fill: parent
                    source: mpris.artUrl
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    sourceSize: Qt.size(96, 96)
                    // Hide if there's no art OR the URL can't be loaded (e.g.
                    // Chromium's temp art file is already gone) — the ♪
                    // placeholder below then shows instead of a blank box.
                    visible: mpris.artUrl !== "" && status !== Image.Error
                }

                Text {
                    anchors.centerIn: parent
                    visible: mpris.artUrl === "" || artImg.status === Image.Error
                    text: "♪"
                    color: root.accent
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
                    color: root.accent
                    font.pixelSize: 15
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                }
                Text {
                    width: parent.width
                    text: mpris.artist !== "" ? mpris.artist : mpris.sourceApp
                    color: root.accentDim
                    font.pixelSize: 12
                    elide: Text.ElideRight
                }
            }

            MusicVisualizer {
                id: visualizer
                anchors.verticalCenter: albumArt.verticalCenter
                playing: mpris.playing
                barColor: root.accent
            }
        }

        // ── Seek bar ──
        Column {
            width: parent.width
            spacing: 2

            Row {
                width: parent.width

                Text {
                    text: root.formatTime(mpris.position)
                    color: Theme.subtext
                    font.pixelSize: 10
                }
                Item { width: parent.width - 72; height: 1 }
                Text {
                    text: root.formatTime(mpris.length)
                    color: Theme.subtext
                    font.pixelSize: 10
                }
            }

            Rectangle {
                id: track
                width: parent.width
                height: 12
                radius: 6
                color: "transparent"

                // While dragging we show the target position; otherwise live position.
                property real dragFraction: -1
                readonly property real fraction: mpris && mpris.length > 0
                    ? Math.min(1, Math.max(0, mpris.position / mpris.length))
                    : 0
                readonly property real displayFraction: dragFraction >= 0 ? dragFraction : fraction

                // Rail
                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    height: 3
                    radius: 1.5
                    color: Theme.isMyGlass ? "#40ffffff" : "#3a3a3a"
                    width: parent.width
                }

                // Fill
                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    height: 3
                    radius: 1.5
                    color: "white"
                    width: parent.width * track.displayFraction
                }

                // Thumb — shown while hovering or dragging
                Rectangle {
                    width: 8
                    height: 8
                    radius: 4
                    color: "white"
                    anchors.verticalCenter: parent.verticalCenter
                    x: Math.max(0, Math.min(parent.width - width,
                        parent.width * track.displayFraction - width / 2))
                    visible: seekArea.containsMouse || seekArea.pressed
                    scale: seekArea.pressed ? 1.2 : 1
                    Behavior on scale { NumberAnimation { duration: 100 } }
                }

                MouseArea {
                    id: seekArea
                    anchors.fill: parent
                    cursorShape: mpris && mpris.canSeek ? Qt.PointingHandCursor : Qt.ArrowCursor
                    hoverEnabled: mpris && mpris.canSeek
                    enabled: mpris && mpris.canSeek
                    preventStealing: true

                    function fractionAt(mouseX) {
                        return Math.min(1, Math.max(0, mouseX / track.width));
                    }

                    onPressed: (mouse) => {
                        if (!mpris || !mpris.canSeek) return;
                        track.dragFraction = fractionAt(mouse.x);
                        root.notifyUserActivity();
                    }
                    onPositionChanged: (mouse) => {
                        if (pressed && mpris && mpris.canSeek) {
                            track.dragFraction = fractionAt(mouse.x);
                            root.notifyUserActivity();
                        }
                    }
                    onReleased: (mouse) => {
                        if (!mpris || !mpris.canSeek) return;
                        if (track.dragFraction >= 0) {
                            mpris.seekToFraction(track.dragFraction);
                            track.dragFraction = -1;
                            root.notifyUserActivity();
                        }
                    }
                    onCanceled: track.dragFraction = -1
                }
            }
        }

        // ── Transport controls + shuffle/loop ──
        Item {
            width: parent.width
            height: 34

            // Shuffle (left edge)
            Item {
                id: shuffleBtn
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                width: 18
                height: 18

                Text {
                    anchors.centerIn: parent
                    text: "🔀"
                    color: mpris && mpris.shuffle ? "#ffffff" : "#5c5c5c"
                    font.pixelSize: 11
                    visible: mpris && mpris.shuffleSupported
                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -8
                        cursorShape: Qt.PointingHandCursor
                        preventStealing: true
                        onPressed: function(mouse) { mouse.accepted = true; }
                        onClicked: {
                            mpris.toggleShuffle();
                            root.notifyUserActivity();
                        }
                    }
                }
            }

            // Loop (right edge)
            Item {
                id: loopBtn
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                width: 18
                height: 18

                Text {
                    anchors.centerIn: parent
                    text: mpris && mpris.loopState === MprisLoopState.Track ? "🔂" : "🔁"
                    color: mpris && mpris.loopState !== MprisLoopState.None ? "#ffffff" : "#5c5c5c"
                    font.pixelSize: 11
                    visible: mpris && mpris.loopSupported
                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -8
                        cursorShape: Qt.PointingHandCursor
                        preventStealing: true
                        onPressed: function(mouse) { mouse.accepted = true; }
                        onClicked: {
                            mpris.cycleLoop();
                            root.notifyUserActivity();
                        }
                    }
                }
            }

            // Transport cluster — centered
            Row {
                anchors.centerIn: parent
                spacing: 24

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "⏮"
                    color: mpris && mpris.canGoPrevious ? "white" : "#555555"
                    font.pixelSize: 18
                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -12
                        cursorShape: Qt.PointingHandCursor
                        preventStealing: true
                        enabled: mpris && mpris.canGoPrevious
                        onPressed: function(mouse) { mouse.accepted = true; }
                        onClicked: {
                            mpris.previous();
                            root.notifyUserActivity();
                        }
                    }
                }

                Rectangle {
                    id: playBtn
                    width: 34
                    height: 34
                    radius: 17
                    color: "white"
                    opacity: mpris && mpris.canControl ? 1 : 0.35
                    scale: playArea.pressed ? 0.92 : (playArea.containsMouse ? 1.06 : 1.0)
                    Behavior on scale { NumberAnimation { duration: 110; easing.type: Easing.OutCubic } }

                    Text {
                        anchors.centerIn: parent
                        anchors.horizontalCenterOffset: (mpris && mpris.playing) ? 0 : 1
                        text: (mpris && mpris.playing) ? "⏸" : "▶"
                        color: "black"
                        font.pixelSize: 14
                        font.weight: Font.Bold
                    }

                    MouseArea {
                        id: playArea
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        preventStealing: true
                        enabled: mpris && mpris.canControl
                        onPressed: function(mouse) { mouse.accepted = true; }
                        onClicked: {
                            mpris.playPause();
                            root.notifyUserActivity();
                        }
                    }
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "⏭"
                    color: mpris && mpris.canGoNext ? "white" : "#555555"
                    font.pixelSize: 18
                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -12
                        cursorShape: Qt.PointingHandCursor
                        preventStealing: true
                        enabled: mpris && mpris.canGoNext
                        onPressed: function(mouse) { mouse.accepted = true; }
                        onClicked: {
                            mpris.next();
                            root.notifyUserActivity();
                        }
                    }
                }
            }
        }
    }
}
