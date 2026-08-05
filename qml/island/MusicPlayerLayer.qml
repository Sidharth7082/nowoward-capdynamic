import QtQuick
import Quickshell.Services.Mpris

// Apple/Spotify-inspired now-playing card for the island.
// Layout: album art + title/artist + visualizer, seek bar with hover/drag,
// then transport controls flanked by shuffle/loop.
Item {
    id: root

    property var controller
    property var userActivityCallback: null
    readonly property var mpris: controller

    // Music accent palette (kept consistent with the island's purple identity).
    readonly property color accent: "#c084fc"
    readonly property color accentDim: "#9d7fce"
    readonly property color bgFill: "#2a1538"
    readonly property color textDim: "#9aa0a6"

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

    // ---- Full-bleed album-art background (Apple-Music style) ----
    // Dimmed artwork fills the whole card behind the content. The capsule's
    // clip + radius handle the rounded corners.
    Image {
        anchors.fill: parent
        source: (mpris && mpris.hasPlayer && mpris.artUrl !== "") ? mpris.artUrl : ""
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        sourceSize: Qt.size(480, 240)
        opacity: 0.32
        visible: source !== ""
    }
    Rectangle {
        anchors.fill: parent
        color: "#0c0812"
        opacity: 0.66
        visible: mpris && mpris.hasPlayer && mpris.artUrl !== ""
    }

    // ---- Empty state: nothing playing anywhere ----
    Column {
        anchors.centerIn: parent
        spacing: 8
        visible: !mpris || !mpris.hasPlayer

        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            width: 44
            height: 44
            radius: 22
            color: root.accent
            opacity: 0.18

            Text {
                anchors.centerIn: parent
                text: "♪"
                color: root.accent
                font.pixelSize: 20
            }
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "Nothing playing"
            color: "#999999"
            font.pixelSize: 12
        }
    }

    // ---- Now-playing state ----
    Column {
        anchors.fill: parent
        anchors.margins: 7
        spacing: 5
        visible: !!mpris && mpris.hasPlayer

        // ── Header: album art, title/artist, visualizer ──
        Row {
            width: parent.width
            spacing: 10

            Rectangle {
                id: albumArt
                width: 54
                height: 54
                radius: 13
                color: root.bgFill
                border.color: "#30ffffff"
                border.width: 1
                clip: true

                Image {
                    anchors.fill: parent
                    source: mpris.artUrl
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    sourceSize: Qt.size(128, 128)
                    visible: mpris.artUrl !== ""
                }

                // Placeholder when no art is available.
                Rectangle {
                    anchors.fill: parent
                    visible: mpris.artUrl === ""
                    color: "#2e1f40"

                    Text {
                        anchors.centerIn: parent
                        text: "♪"
                        color: root.accent
                        font.pixelSize: 22
                    }
                }

                // Live equalizer overlaid on the art's bottom-right corner.
                MusicVisualizer {
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    anchors.rightMargin: 5
                    anchors.bottomMargin: 5
                    playing: mpris.playing
                    barColor: "white"
                    opacity: 0.95
                }
            }

            Column {
                width: parent.width - albumArt.width - 20
                anchors.verticalCenter: albumArt.verticalCenter
                spacing: 3

                Text {
                    width: parent.width
                    text: mpris.title !== "" ? mpris.title : mpris.sourceApp
                    color: "#f5f5f7"
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
        }

        // ── Seek bar ──
        Column {
            width: parent.width
            spacing: 2

            Row {
                width: parent.width

                Text {
                    text: root.formatTime(mpris.position)
                    color: root.textDim
                    font.pixelSize: 10
                    font.weight: Font.Medium
                }
                Item { width: parent.width - 76; height: 1 }
                Text {
                    text: root.formatTime(mpris.length)
                    color: root.textDim
                    font.pixelSize: 10
                    font.weight: Font.Medium
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
                    height: 4
                    radius: 2
                    color: "#3a3a3a"
                    width: parent.width
                }

                // Fill
                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    height: 4
                    radius: 2
                    color: root.accent
                    width: parent.width * track.displayFraction
                }

                // Thumb — only shown while hovering or dragging
                Rectangle {
                    width: 10
                    height: 10
                    radius: 5
                    color: "white"
                    border.color: root.accent
                    border.width: 2
                    anchors.verticalCenter: parent.verticalCenter
                    x: Math.max(0, Math.min(parent.width - width,
                        parent.width * track.displayFraction - width / 2))
                    visible: seekArea.containsMouse || seekArea.pressed
                    scale: seekArea.pressed ? 1.15 : 1
                    Behavior on scale { NumberAnimation { duration: 100 } }
                }

                MouseArea {
                    id: seekArea
                    anchors.fill: parent
                    cursorShape: mpris && mpris.canSeek ? Qt.PointingHandCursor : Qt.ArrowCursor
                    hoverEnabled: mpris && mpris.canSeek
                    // Disabled (not transparent) so unsupported players don't
                    // swallow clicks, matching the transport buttons.
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
            height: 44

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
                spacing: 18

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "⏮"
                    color: mpris && mpris.canGoPrevious ? "#e8e8e8" : "#4a4a4a"
                    font.pixelSize: 17
                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -10
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

                // Play / Pause with a soft accent halo
                Item {
                    width: 44
                    height: 44

                    Rectangle {
                        anchors.centerIn: parent
                        width: 40
                        height: 40
                        radius: 20
                        color: root.accent
                        opacity: (mpris && mpris.canControl ? 0.22 : 0.08)
                    }

                    Rectangle {
                        id: playBtn
                        anchors.centerIn: parent
                        width: 36
                        height: 36
                        radius: 18
                        color: root.accent
                        opacity: mpris && mpris.canControl ? 1 : 0.3
                        scale: playArea.pressed ? 0.92 : (playArea.containsMouse ? 1.06 : 1.0)
                        Behavior on scale { NumberAnimation { duration: 110; easing.type: Easing.OutCubic } }

                        Text {
                            anchors.centerIn: parent
                            anchors.horizontalCenterOffset: (mpris && mpris.playing) ? 0 : 1
                            text: (mpris && mpris.playing) ? "⏸" : "▶"
                            color: "#1a1030"
                            font.pixelSize: 13
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
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "⏭"
                    color: mpris && mpris.canGoNext ? "#e8e8e8" : "#4a4a4a"
                    font.pixelSize: 17
                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -10
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
