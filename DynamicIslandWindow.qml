import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import "qml/island"
import "qml/services"
import "qml/theme"

// A Dynamic-Island-style widget: a small pill in the top center of
// the screen showing clock/notifications/volume. Tap expands it; once expanded,
// swipe left/right between Clock, Music Player, and System Stats pages.
PanelWindow {
    id: root

    property bool expanded: false
    property string page: "clock"   // "clock" | "player" | "stats" | "wifi" | "bluetooth"
    property var pages: ["clock", "player", "stats"]

    readonly property int topMargin: 10
    readonly property int swipeThreshold: 40

    property int idleTimeoutMs: 8000

    readonly property var hyprMonitor: Hyprland.monitorFor(screen)
    readonly property bool hideForFullscreen: hyprMonitor
        && hyprMonitor.activeWorkspace
        && hyprMonitor.activeWorkspace.hasFullscreen

    property bool hoverRevealed: false

    readonly property bool shouldHidePill: !root.expanded
        && !root.peeking
        && !root.peekingNotif
        && !root.peekingVolume
        && !root.hoverRevealed

    visible: !hideForFullscreen && !suppressPeek

    onSuppressPeekChanged: {
        if (suppressPeek) {
            root.setExpanded(false);
            root.hoverRevealed = false;
            root.peeking = false;
            root.peekingNotif = false;
            root.peekingVolume = false;
            peekTimer.stop();
            notifTimer.stop();
            volTimer.stop();
            leaveTimer.stop();
            idleTimer.stop();
        }
    }

    onHideForFullscreenChanged: {
        if (hideForFullscreen) {
            root.setExpanded(false);
            root.hoverRevealed = false;
            root.peeking = false;
            root.peekingNotif = false;
            root.peekingVolume = false;
            peekTimer.stop();
            notifTimer.stop();
            volTimer.stop();
            leaveTimer.stop();
            idleTimer.stop();
        }
    }

    function notifyActivity() {
        if (root.expanded && !root.peeking && !root.peekingNotif && !root.peekingVolume && root.idleTimeoutMs > 0)
            idleTimer.restart();
    }

    function syncIdleTimer() {
        if (root.expanded && !root.peeking && !root.peekingNotif && !root.peekingVolume && root.idleTimeoutMs > 0)
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
    function showStats() { root.page = "stats"; root.expanded = true; }
    function showWifi() { root.page = "wifi"; root.expanded = true; }
    function showBluetooth() { root.page = "bluetooth"; root.expanded = true; }

    function nextPage() {
        let idx = pages.indexOf(root.page);
        if (idx === -1) idx = 0;
        root.page = pages[(idx + 1) % pages.length];
    }

    function prevPage() {
        let idx = pages.indexOf(root.page);
        if (idx === -1) idx = 0;
        root.page = pages[(idx - 1 + pages.length) % pages.length];
    }

    // Dynamic width & height calculation
    readonly property int targetWidth: peekingNotif
        ? Theme.notificationWidth
        : (peekingVolume
            ? 240
            : (!root.expanded
                ? Theme.collapsedWidth
                : (root.page === "player"
                    ? Theme.playerWidth
                    : (root.page === "stats"
                        ? Theme.statsWidth
                        : (root.page === "wifi"
                            ? Theme.wifiWidth
                            : (root.page === "bluetooth" ? Theme.btWidth : Theme.clockWidth))))))

    readonly property int targetHeight: peekingNotif
        ? Theme.notificationHeight
        : (peekingVolume
            ? 40
            : (!root.expanded
                ? Theme.collapsedHeight
                : (root.page === "player"
                    ? Theme.playerHeight
                    : (root.page === "stats"
                        ? Theme.statsHeight
                        : (root.page === "wifi"
                            ? Theme.wifiHeight
                            : (root.page === "bluetooth" ? Theme.btHeight : Theme.clockHeight))))))

    color: "transparent"
    anchors { top: true; left: true; right: true }

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "tide-mini"
    exclusiveZone: 0

    implicitHeight: root.topMargin + Math.ceil(capsule.height) + 8

    mask: Region {
        x: Math.floor(capsule.x)
        y: root.shouldHidePill ? 0 : Math.floor(capsule.y)
        width: Math.ceil(capsule.width)
        height: root.shouldHidePill ? 14 : Math.ceil(capsule.height)
    }

    // Top edge hover trigger when pill is auto-hidden
    MouseArea {
        id: edgeTrigger
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        width: Math.max(260, capsule.width)
        height: root.shouldHidePill ? 14 : 0
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        onEntered: {
            leaveTimer.stop();
            if (!root.suppressPeek && !root.hideForFullscreen) {
                root.hoverRevealed = true;
            }
        }

        onExited: {
            if (root.hoverRevealed || root.expanded) {
                leaveTimer.restart();
            }
        }
    }

    IslandClock {
        id: clock
    }

    IslandMprisController {
        id: mpris
    }

    // Auto-peek for MPRIS track changes
    property bool peeking: false
    property bool wasPlayingBefore: false
    property bool suppressPeek: false

    // Auto-peek for Notifications
    property bool peekingNotif: false
    property var activeNotification: null

    // Auto-peek for Volume
    property bool peekingVolume: false

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

    Connections {
        target: NotificationService
        function onNotificationAdded(n) {
            if (!root.suppressPeek && !root.hideForFullscreen) {
                root.activeNotification = n;
                root.peekingNotif = true;
                root.setExpanded(true);
                notifTimer.restart();
            }
        }
    }

    Connections {
        target: VolumeService
        function onVolumeUpdated(vol, isMuted) {
            if (!root.expanded && !root.peekingNotif && !root.suppressPeek && !root.hideForFullscreen) {
                root.peekingVolume = true;
                volTimer.restart();
            }
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
        id: leaveTimer
        interval: 1500
        repeat: false
        onTriggered: {
            if (!gestureArea.containsMouse && !edgeTrigger.containsMouse) {
                root.hoverRevealed = false;
                root.setExpanded(false);
            }
        }
    }

    Timer {
        id: notifTimer
        interval: 4500
        onTriggered: {
            if (root.peekingNotif) {
                root.peekingNotif = false;
                root.activeNotification = null;
                root.setExpanded(false);
            }
        }
    }

    Timer {
        id: volTimer
        interval: 2000
        onTriggered: {
            if (root.peekingVolume) {
                root.peekingVolume = false;
            }
        }
    }

    Timer {
        id: idleTimer
        interval: root.idleTimeoutMs
        repeat: false
        onTriggered: {
            if (root.expanded && !root.peeking && !root.peekingNotif && !root.peekingVolume) {
                root.hoverRevealed = false;
                root.setExpanded(false);
            }
        }
    }

    Rectangle {
        id: capsule

        x: Math.round((root.width - width) / 2)
        y: root.shouldHidePill ? -height - 5 : root.topMargin
        opacity: root.shouldHidePill ? 0 : 1
        width: root.targetWidth
        height: root.targetHeight
        radius: (root.expanded || root.peekingNotif) ? 26 : height / 2
        color: Theme.bg
        border.color: Theme.border
        border.width: 1
        clip: true

        Behavior on y {
            NumberAnimation { duration: 320; easing.type: Easing.OutExpo }
        }
        Behavior on opacity {
            NumberAnimation { duration: 250; easing.type: Easing.OutQuad }
        }
        Behavior on width {
            NumberAnimation { duration: 320; easing.type: Easing.OutExpo }
        }
        Behavior on height {
            NumberAnimation { duration: 320; easing.type: Easing.OutExpo }
        }
        Behavior on radius {
            NumberAnimation { duration: 320; easing.type: Easing.OutExpo }
        }

        MouseArea {
            id: gestureArea
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            hoverEnabled: true

            property real pressX: 0
            property bool dragging: false

            onEntered: {
                leaveTimer.stop();
                if (!root.suppressPeek && !root.hideForFullscreen) {
                    root.hoverRevealed = true;
                }
            }

            onExited: {
                if (root.hoverRevealed || root.expanded) {
                    leaveTimer.restart();
                }
            }

            onPressed: (mouse) => {
                pressX = mouse.x;
                dragging = false;
                leaveTimer.stop();
                if (root.peeking) {
                    root.peeking = false;
                    peekTimer.stop();
                }
                if (root.peekingNotif) {
                    root.peekingNotif = false;
                    notifTimer.stop();
                }
                if (root.peekingVolume) {
                    root.peekingVolume = false;
                    volTimer.stop();
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
                    if (deltaX < 0)
                        root.nextPage();
                    else
                        root.prevPage();
                    root.notifyActivity();
                } else if (!dragging) {
                    root.toggleExpanded();
                } else {
                    root.notifyActivity();
                }
            }
        }

        // Collapsed content
        Text {
            anchors.centerIn: parent
            opacity: (!root.expanded && !root.peekingNotif && !root.peekingVolume) ? 1 : 0
            text: clock.timeText
            color: Theme.text
            font.pixelSize: 15
            font.weight: Font.DemiBold

            Behavior on opacity {
                NumberAnimation { duration: 150 }
            }
        }

        // Volume Peek Content
        IslandVolumeLayer {
            opacity: root.peekingVolume ? 1 : 0
            visible: opacity > 0.01

            Behavior on opacity { NumberAnimation { duration: 150 } }
        }

        // Notification Peek Content
        IslandNotificationLayer {
            anchors.fill: parent
            notification: root.activeNotification
            opacity: root.peekingNotif ? 1 : 0
            visible: opacity > 0.01

            Behavior on opacity { NumberAnimation { duration: 180 } }
        }

        // Expanded multi-page content
        Item {
            id: pageHost
            anchors.fill: parent
            opacity: (root.expanded && !root.peekingNotif && !root.peekingVolume) ? 1 : 0
            visible: opacity > 0.01
            enabled: root.expanded && opacity > 0.5

            Behavior on opacity {
                NumberAnimation { duration: 220; easing.type: Easing.InOutQuad }
            }

            // Page 1: Clock
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
                    color: Theme.text
                    font.pixelSize: 30
                    font.weight: Font.Bold
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: clock.dateText
                    color: Theme.subtext
                    font.pixelSize: 13
                }
            }

            // Page 2: Music Player
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

            // Page 3: System Stats / Control Center
            IslandSystemStats {
                id: statsPage
                anchors.fill: parent
                opacity: root.page === "stats" ? 1 : 0
                scale: root.page === "stats" ? 1 : 0.92
                visible: opacity > 0.01

                onWifiRightClicked: root.showWifi()
                onBtRightClicked: root.showBluetooth()

                Behavior on opacity { NumberAnimation { duration: 200 } }
                Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutQuad } }
            }

            // Page 4: Wi-Fi Detail Page
            IslandWifiLayer {
                id: wifiPage
                anchors.fill: parent
                opacity: root.page === "wifi" ? 1 : 0
                scale: root.page === "wifi" ? 1 : 0.92
                visible: opacity > 0.01

                onBackClicked: root.showStats()

                Behavior on opacity { NumberAnimation { duration: 200 } }
                Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutQuad } }
            }

            // Page 5: Bluetooth Detail Page
            IslandBluetoothLayer {
                id: btPage
                anchors.fill: parent
                opacity: root.page === "bluetooth" ? 1 : 0
                scale: root.page === "bluetooth" ? 1 : 0.92
                visible: opacity > 0.01

                onBackClicked: root.showStats()

                Behavior on opacity { NumberAnimation { duration: 200 } }
                Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutQuad } }
            }
        }

        // Page indicator dots
        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 6
            spacing: 5
            opacity: (root.expanded && !root.peekingNotif && !root.peekingVolume) ? 0.8 : 0
            visible: opacity > 0.01

            Behavior on opacity { NumberAnimation { duration: 200 } }

            Repeater {
                model: root.pages

                Rectangle {
                    width: 5
                    height: 5
                    radius: 2.5
                    color: root.page === modelData ? Theme.text : "#555555"

                    Behavior on color { ColorAnimation { duration: 150 } }
                }
            }
        }
    }
}
