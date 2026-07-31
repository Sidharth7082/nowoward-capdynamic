import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import "qml/island"

// A minimal Dynamic-Island-style widget: a small pill in the top center of
// the screen showing the clock. Tap expands it; once expanded, swipe
// left/right to switch between the Clock page and the Music Player page.
PanelWindow {
    id: root

    property bool expanded: false
    property string page: "clock"   // "clock" | "player"

    readonly property int collapsedWidth: 150
    readonly property int collapsedHeight: 34
    readonly property int clockWidth: 260
    readonly property int clockHeight: 92
    readonly property int playerWidth: 300
    readonly property int playerHeight: 150
    readonly property int topMargin: 10
    readonly property int swipeThreshold: 40

    // Collapse the expanded island after this many ms without interaction.
    // Set to 0 to disable. Does not apply during auto-peek (peek has its own timer).
    property int idleTimeoutMs: 8000

    readonly property var hyprMonitor: Hyprland.monitorFor(screen)
    readonly property bool hideForFullscreen: hyprMonitor
        && hyprMonitor.activeWorkspace
        && hyprMonitor.activeWorkspace.hasFullscreen

    visible: !hideForFullscreen

    onHideForFullscreenChanged: {
        if (hideForFullscreen) {
            root.setExpanded(false);
            root.peeking = false;
            peekTimer.stop();
            idleTimer.stop();
        }
    }

    function notifyActivity() {
        if (root.expanded && !root.peeking && root.idleTimeoutMs > 0)
            idleTimer.restart();
    }

    function syncIdleTimer() {
        if (root.expanded && !root.peeking && root.idleTimeoutMs > 0)
            idleTimer.restart();
        else
            idleTimer.stop();
    }

    onExpandedChanged: syncIdleTimer()
    onPeekingChanged: syncIdleTimer()

    function toggleExpanded() { root.expanded = !root.expanded; }
    function setExpanded(value) { root.expanded = value; }
    function showPlayer() { root.page = "player"; root.expanded = true; }
    function showClock() { root.page = "clock"; root.expanded = true; }

    readonly property int targetWidth: !root.expanded
        ? root.collapsedWidth
        : (root.page === "player" ? root.playerWidth : root.clockWidth)
    readonly property int targetHeight: !root.expanded
        ? root.collapsedHeight
        : (root.page === "player" ? root.playerHeight : root.clockHeight)

    // Frameless, click-through everywhere except the capsule itself.
    color: "transparent"
    anchors { top: true; left: true; right: true }

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "tide-mini"
    exclusiveZone: 0

    implicitHeight: root.topMargin + Math.ceil(capsule.height) + 8

    mask: Region {
        x: Math.floor(capsule.x)
        y: Math.floor(capsule.y)
        width: Math.ceil(capsule.width)
        height: Math.ceil(capsule.height)
    }

    IslandClock {
        id: clock
    }

    IslandMprisController {
        id: mpris
    }

    // Auto-peek: when a track starts playing (and the island is idle),
    // briefly pop open to the player page, then settle back down.
    property bool peeking: false
    property bool wasPlayingBefore: false
    property bool suppressPeek: false

    Connections {
        target: mpris
        function onPlayingChanged() {
            if (mpris.playing && !root.wasPlayingBefore && !root.expanded
                    && !root.suppressPeek && !root.hideForFullscreen) {
                root.peeking = true;
                root.page = "player";
                root.expanded = true;
                peekTimer.restart();
            }
            root.wasPlayingBefore = mpris.playing;
        }
    }

    Timer {
        id: peekTimer
        interval: 3000
        onTriggered: {
            if (root.peeking) {
                root.peeking = false;
                root.expanded = false;
            }
        }
    }

    Timer {
        id: idleTimer
        interval: root.idleTimeoutMs
        repeat: false
        onTriggered: {
            if (root.expanded && !root.peeking)
                root.setExpanded(false);
        }
    }

    Rectangle {
        id: capsule

        x: Math.round((root.width - width) / 2)
        y: root.topMargin
        width: root.targetWidth
        height: root.targetHeight
        radius: root.expanded ? 26 : height / 2
        color: "#e6141414"
        border.color: "#33ffffff"
        border.width: 1
        clip: true

        Behavior on width {
            NumberAnimation { duration: 280; easing.type: Easing.OutExpo }
        }
        Behavior on height {
            NumberAnimation { duration: 280; easing.type: Easing.OutExpo }
        }
        Behavior on radius {
            NumberAnimation { duration: 280; easing.type: Easing.OutExpo }
        }

        // Tap to expand/collapse, drag horizontally while expanded to
        // switch pages (swipe left -> player, swipe right -> clock).
        MouseArea {
            id: gestureArea
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor

            property real pressX: 0
            property bool dragging: false

            onPressed: (mouse) => {
                pressX = mouse.x;
                dragging = false;
                if (root.peeking) {
                    root.peeking = false;
                    peekTimer.stop();
                }
                if (root.expanded)
                    root.notifyActivity();
            }
            onPositionChanged: (mouse) => {
                if (Math.abs(mouse.x - pressX) > 6)
                    dragging = true;
            }
            onReleased: (mouse) => {
                const deltaX = mouse.x - pressX;

                if (!root.expanded) {
                    if (!dragging)
                        root.setExpanded(true);
                    return;
                }

                if (Math.abs(deltaX) > root.swipeThreshold) {
                    root.page = deltaX < 0 ? "player" : "clock";
                    root.notifyActivity();
                } else if (!dragging) {
                    root.toggleExpanded();
                } else {
                    root.notifyActivity();
                }
            }
        }

        // ---- Collapsed content: just the time, centered. ----
        Text {
            anchors.centerIn: parent
            opacity: root.expanded ? 0 : 1
            text: clock.timeText
            color: "white"
            font.pixelSize: 15
            font.weight: Font.DemiBold

            Behavior on opacity {
                NumberAnimation { duration: 150 }
            }
        }

        // ---- Expanded pages, cross-fading + scaling on page switch. ----
        Item {
            id: pageHost
            anchors.fill: parent
            opacity: root.expanded ? 1 : 0

            Behavior on opacity {
                NumberAnimation { duration: 220; easing.type: Easing.InOutQuad }
            }

            Column {
                id: clockPage
                anchors.centerIn: parent
                spacing: 4
                opacity: root.page === "clock" ? 1 : 0
                scale: root.page === "clock" ? 1 : 0.92

                Behavior on opacity { NumberAnimation { duration: 200 } }
                Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutQuad } }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: clock.timeText
                    color: "white"
                    font.pixelSize: 30
                    font.weight: Font.Bold
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: clock.dateText
                    color: "#aaffffff"
                    font.pixelSize: 13
                }
            }

            MusicPlayerLayer {
                id: playerPage
                anchors.fill: parent
                controller: mpris
                userActivityCallback: root.notifyActivity
                opacity: root.page === "player" ? 1 : 0
                scale: root.page === "player" ? 1 : 0.92
                visible: opacity > 0.01

                Behavior on opacity { NumberAnimation { duration: 200 } }
                Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutQuad } }
            }
        }

        // Page dots, only visible while expanded.
        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 6
            spacing: 5
            opacity: root.expanded ? 0.8 : 0
            visible: opacity > 0.01

            Behavior on opacity { NumberAnimation { duration: 200 } }

            Repeater {
                model: ["clock", "player"]

                Rectangle {
                    width: 5
                    height: 5
                    radius: 2.5
                    color: root.page === modelData ? "white" : "#555555"

                    Behavior on color { ColorAnimation { duration: 150 } }
                }
            }
        }
    }
}
