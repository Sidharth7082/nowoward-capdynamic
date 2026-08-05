import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import "qml/island"
import "qml/services"
import "qml/theme"
import "qml/workspace"

// A Dynamic-Island-style widget: a small pill in the top center of
// the screen showing clock/notifications/volume. Tap expands it; once expanded,
// swipe left/right between Clock, Music Player, and System Stats pages.
PanelWindow {
    id: root

    property bool expanded: false
    property string page: "clock"   // "clock" | "player" | "stats" | "wifi" | "bluetooth" | "emojis"
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
        && !root.peekingWorkspace
        && !root.hoverRevealed

    visible: !hideForFullscreen && !suppressPeek

    onSuppressPeekChanged: {
        if (suppressPeek) {
            root.setExpanded(false);
            root.hoverRevealed = false;
            root.peeking = false;
            root.peekingNotif = false;
            root.peekingVolume = false;
            root.peekingWorkspace = false;
            root.workspaceSlideDirection = "none";
            peekTimer.stop();
            notifTimer.stop();
            volTimer.stop();
            wsTimer.stop();
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
            root.peekingWorkspace = false;
            root.workspaceSlideDirection = "none";
            peekTimer.stop();
            notifTimer.stop();
            volTimer.stop();
            wsTimer.stop();
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

    onExpandedChanged: {
        syncIdleTimer();
        if (expanded && page === "workspace")
            workspacePage.forceFocus();
    }
    onPageChanged: {
        if (expanded && page === "workspace")
            workspacePage.forceFocus();
    }
    onPeekingChanged: syncIdleTimer()

    function setExpanded(val) {
        expanded = val;
        if (expanded) {
            peeking = false;
            peekingNotif = false;
            peekingVolume = false;
            peekingWorkspace = false;
            notifyActivity();
        } else {
            leaveTimer.stop();
            idleTimer.stop();
            page = "clock";
        }
    }

    function toggleExpanded() { setExpanded(!expanded); }
    function showPlayer() { setExpanded(true); page = "player"; notifyActivity(); }
    function showClock() { setExpanded(true); page = "clock"; notifyActivity(); }
    function showStats() { setExpanded(true); page = "stats"; notifyActivity(); }
    function showNotifs() { setExpanded(true); page = "notifs"; notifyActivity(); }
    function showWifi() { setExpanded(true); page = "wifi"; notifyActivity(); }
    function showBluetooth() { setExpanded(true); page = "bluetooth"; notifyActivity(); }
    function showLogout() { setExpanded(true); page = "logout"; notifyActivity(); }
    function showEmojis() { setExpanded(true); page = "emojis"; notifyActivity(); }
    function showWorkspace() { setExpanded(true); page = "workspace"; notifyActivity(); }
    function showCliphist() {
        setExpanded(true);
        page = "cliphist";
        notifyActivity();
        Qt.callLater(() => {
            if (cliphistPage && cliphistPage.focusInput)
                cliphistPage.focusInput();
        });
    }

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

    property bool notifExpanded: false

    // Dynamic width & height calculation
    readonly property int targetWidth: peekingNotif
        ? (root.notifExpanded ? 340 : Theme.notificationWidth)
        : (peekingVolume
            ? 240
            : (!root.expanded
                ? Theme.collapsedWidth
                : (root.page === "player"
                    ? Theme.playerWidth
                    : (root.page === "stats"
                        ? Theme.statsWidth
                        : (root.page === "workspace"
                            ? 1060
                            : (root.page === "emojis"
                                ? 480
                                : (root.page === "cliphist"
                                    ? 380
                                    : (root.page === "notifs"
                                        ? 360
                                        : (root.page === "wifi"
                                            ? Theme.wifiWidth
                                            : (root.page === "bluetooth"
                                                ? Theme.btWidth
                                                : (root.page === "logout" ? Theme.logoutWidth : Theme.clockWidth)))))))))))

    readonly property int targetHeight: peekingNotif
        ? (root.notifExpanded ? 90 : Theme.notificationHeight)
        : (peekingVolume
            ? 40
            : (!root.expanded
                ? Theme.collapsedHeight
                : (root.page === "player"
                    ? Theme.playerHeight
                    : (root.page === "stats"
                        ? Theme.statsHeight
                        : (root.page === "workspace"
                            ? 270
                            : (root.page === "emojis"
                                ? 320
                                : (root.page === "cliphist"
                                    ? 250
                                    : (root.page === "notifs"
                                        ? 220
                                        : (root.page === "wifi"
                                            ? Theme.wifiHeight
                                            : (root.page === "bluetooth"
                                                ? Theme.btHeight
                                                : (root.page === "logout" ? Theme.logoutHeight : Theme.clockHeight)))))))))))

    color: "transparent"
    anchors { top: true; left: true; right: true }

    focusable: root.expanded
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "nowoward-capdynamic"
    WlrLayershell.keyboardFocus: root.expanded
        ? ((root.page === "emojis" || root.page === "workspace" || root.page === "cliphist") ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.OnDemand)
        : WlrKeyboardFocus.None
    exclusiveZone: (root.expanded && root.page === "workspace") ? Math.ceil(capsule.height + root.topMargin + 8) : 0
    implicitHeight: root.topMargin + Math.ceil(capsule.height) + 8

    Shortcut {
        sequence: "Escape"
        enabled: root.expanded
        onActivated: root.setExpanded(false)
    }

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
    property bool peekingWorkspace: false
    property string workspaceSlideDirection: "none"
    property int _lastWsId: 1
    // Suppresses auto-peek while the shell is still initializing (a player that
    // is already playing must not pop the island on startup).
    property bool _mediaReady: false

    Component.onCompleted: {
        root._lastWsId = root.hyprMonitor && root.hyprMonitor.activeWorkspace
            ? root.hyprMonitor.activeWorkspace.id
            : 1;
        root.wasPlayingBefore = mpris.playing;
        root._mediaReady = true;
    }

    CompositorWorkspaceTracker {
        id: workspaceTracker
        hyprMonitor: root.hyprMonitor
        hyprMonitorName: root.hyprMonitor ? root.hyprMonitor.name : ""
        monitorFocused: root.hyprMonitor ? root.hyprMonitor.focused : true

        onWorkspaceActivated: function(workspaceId, side) {
            if (!root.expanded && !root.peekingNotif && !root.peekingVolume && !root.suppressPeek && !root.hideForFullscreen) {
                root.workspaceSlideDirection = side || "none";
                root.peekingWorkspace = true;
                wsTimer.restart();
            }
        }
    }

    Connections {
        target: hyprMonitor && hyprMonitor.activeWorkspace ? hyprMonitor.activeWorkspace : null
        function onIdChanged() {
            const currentId = hyprMonitor && hyprMonitor.activeWorkspace ? hyprMonitor.activeWorkspace.id : 1;
            if (currentId !== root._lastWsId) {
                root.workspaceSlideDirection = currentId > root._lastWsId ? "right" : (currentId < root._lastWsId ? "left" : "none");
                root._lastWsId = currentId;
            }
            if (!root.expanded && !root.peekingNotif && !root.peekingVolume && !root.suppressPeek && !root.hideForFullscreen) {
                root.peekingWorkspace = true;
                wsTimer.restart();
            }
        }
    }

    Timer {
        id: wsTimer
        interval: 1500
        onTriggered: {
            root.peekingWorkspace = false;
            root.workspaceSlideDirection = "none";
        }
    }

    Connections {
        target: mpris
        function onPlayingChanged() {
            if (!root._mediaReady)
                return; // suppress startup peek
            if (mpris.playing && !root.wasPlayingBefore && !root.expanded
                    && !root.suppressPeek && !root.hideForFullscreen) {
                root.peeking = true;
                root.page = "player";
                root.expanded = true;
                peekTimer.restart();
            }
            root.wasPlayingBefore = mpris.playing;
        }
        function onTrackChanged() {
            // Re-peek the music page whenever a new track starts (skipped while
            // the island is already open or a peek is in progress).
            if (!root._mediaReady)
                return; // suppress startup peek
            if (mpris.playing && !root.expanded
                    && !root.suppressPeek && !root.hideForFullscreen) {
                root.peeking = true;
                root.page = "player";
                root.expanded = true;
                peekTimer.restart();
            }
        }
    }

    // Media-key entry points, driven by the single shell-level GlobalShortcut
    // (see shell.qml). Kept on the window so keys act on the focused island.
    function mediaPlayPause() { mpris.playPause(); }
    function mediaNext() { mpris.next(); }
    function mediaPrevious() { mpris.previous(); }

    Connections {
        target: NotificationService
        function onNotificationAdded(n) {
            if (!root.suppressPeek && !root.hideForFullscreen) {
                root.activeNotification = n;
                root.peekingNotif = true;
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

    Shortcut {
        sequence: "Right"
        enabled: root.expanded && root.page === "workspace"
        context: Qt.ApplicationShortcut
        onActivated: workspacePage.moveSelection(1)
    }
    Shortcut {
        sequence: "Left"
        enabled: root.expanded && root.page === "workspace"
        context: Qt.ApplicationShortcut
        onActivated: workspacePage.moveSelection(-1)
    }
    Shortcut {
        sequence: "Down"
        enabled: root.expanded && root.page === "workspace"
        context: Qt.ApplicationShortcut
        onActivated: workspacePage.moveSelection(5)
    }
    Shortcut {
        sequence: "Up"
        enabled: root.expanded && root.page === "workspace"
        context: Qt.ApplicationShortcut
        onActivated: workspacePage.moveSelection(-5)
    }
    Shortcut {
        sequence: "Return"
        enabled: root.expanded && root.page === "workspace"
        context: Qt.ApplicationShortcut
        onActivated: workspacePage.confirmSelection()
    }
    Shortcut {
        sequence: "Space"
        enabled: root.expanded && root.page === "workspace"
        context: Qt.ApplicationShortcut
        onActivated: workspacePage.confirmSelection()
    }
    Shortcut {
        sequence: "1"
        enabled: root.expanded && root.page === "workspace"
        context: Qt.ApplicationShortcut
        onActivated: workspacePage.selectIndex(0)
    }
    Shortcut {
        sequence: "2"
        enabled: root.expanded && root.page === "workspace"
        context: Qt.ApplicationShortcut
        onActivated: workspacePage.selectIndex(1)
    }
    Shortcut {
        sequence: "3"
        enabled: root.expanded && root.page === "workspace"
        context: Qt.ApplicationShortcut
        onActivated: workspacePage.selectIndex(2)
    }
    Shortcut {
        sequence: "4"
        enabled: root.expanded && root.page === "workspace"
        context: Qt.ApplicationShortcut
        onActivated: workspacePage.selectIndex(3)
    }
    Shortcut {
        sequence: "5"
        enabled: root.expanded && root.page === "workspace"
        context: Qt.ApplicationShortcut
        onActivated: workspacePage.selectIndex(4)
    }
    Shortcut {
        sequence: "6"
        enabled: root.expanded && root.page === "workspace"
        context: Qt.ApplicationShortcut
        onActivated: workspacePage.selectIndex(5)
    }
    Shortcut {
        sequence: "7"
        enabled: root.expanded && root.page === "workspace"
        context: Qt.ApplicationShortcut
        onActivated: workspacePage.selectIndex(6)
    }
    Shortcut {
        sequence: "8"
        enabled: root.expanded && root.page === "workspace"
        context: Qt.ApplicationShortcut
        onActivated: workspacePage.selectIndex(7)
    }
    Shortcut {
        sequence: "9"
        enabled: root.expanded && root.page === "workspace"
        context: Qt.ApplicationShortcut
        onActivated: workspacePage.selectIndex(8)
    }
    Shortcut {
        sequence: "0"
        enabled: root.expanded && root.page === "workspace"
        context: Qt.ApplicationShortcut
        onActivated: workspacePage.selectIndex(9)
    }

    Timer {
        id: leaveTimer
        interval: 1500
        repeat: false
        onTriggered: {
            if (!capsuleHoverHandler.hovered && !gestureArea.containsMouse && !edgeTrigger.containsMouse) {
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
            if (capsuleHoverHandler.hovered) {
                idleTimer.restart();
                return;
            }
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
        color: Theme.isMyGlass ? "#1a121216" : "#f20d1117"
        border.color: Theme.isMyGlass ? "#33ffffff" : "#50ffffff"
        border.width: 1
        clip: true
        scale: gestureArea.containsPress ? 0.975 : (gestureArea.containsMouse ? 1.012 : 1.0)
        focus: root.expanded
        Keys.onPressed: function(event) {
            if (event.key === Qt.Key_Escape) {
                root.setExpanded(false);
                event.accepted = true;
            }
        }

        HoverHandler {
            id: capsuleHoverHandler
            target: capsule
            onHoveredChanged: {
                if (hovered) {
                    leaveTimer.stop();
                    root.notifyActivity();
                } else if (root.expanded) {
                    leaveTimer.restart();
                }
            }
        }

        Behavior on color {
            ColorAnimation { duration: 200 }
        }

        Behavior on scale {
            NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
        }

        Behavior on y {
            NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
        }
        Behavior on opacity {
            NumberAnimation { duration: 160; easing.type: Easing.OutQuad }
        }
        Behavior on width {
            NumberAnimation { duration: 220; easing.type: Easing.OutBack; easing.overshoot: 1.12 }
        }
        Behavior on height {
            NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
        }
        Behavior on radius {
            NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
        }

        MouseArea {
            id: gestureArea
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            hoverEnabled: true

            property real pressX: 0
            property bool dragging: false
            // Which auto-peek was showing when the press started ("" if none):
            // a plain click converts that peek into its full page instead of
            // collapsing the island or opening the clock page.
            property string wasPeeking: ""

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
                // Remember which auto-peek was showing so a plain click keeps
                // the island open on that page instead of collapsing it.
                wasPeeking = root.peeking ? "player"
                    : root.peekingNotif ? "notifs"
                    : root.peekingWorkspace ? "workspace"
                    : root.peekingVolume ? "stats"
                    : "";
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
                if (root.peekingWorkspace) {
                    root.peekingWorkspace = false;
                    wsTimer.stop();
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
                    if (!dragging) {
                        // Opening from a peek: land on the page that was
                        // peeking (notif/volume/workspace peeks aren't
                        // "expanded"), otherwise open the clock page.
                        if (gestureArea.wasPeeking !== "")
                            root.page = gestureArea.wasPeeking;
                        root.setExpanded(true);
                    }
                    return;
                }

                if (Math.abs(deltaX) > root.swipeThreshold) {
                    if (deltaX < 0)
                        root.nextPage();
                    else
                        root.prevPage();
                    root.notifyActivity();
                } else if (!dragging) {
                    if (gestureArea.wasPeeking !== "") {
                        // Convert the auto-peek into a persistent view instead
                        // of collapsing it; keep the idle timer fresh.
                        root.notifyActivity();
                    } else {
                        root.toggleExpanded();
                    }
                } else {
                    root.notifyActivity();
                }
            }
            onWheel: (wheel) => {
                if (root.expanded) {
                    if (wheel.angleDelta.y < 0 || wheel.angleDelta.x > 0)
                        root.nextPage();
                    else if (wheel.angleDelta.y > 0 || wheel.angleDelta.x < 0)
                        root.prevPage();
                    root.notifyActivity();
                }
            }
        }

        // Collapsed content
        Text {
            anchors.centerIn: parent
            opacity: (!root.expanded && !root.peekingNotif && !root.peekingVolume && !root.peekingWorkspace) ? 1 : 0
            visible: opacity > 0.01
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

        // Workspace Change Peek Content
        IslandWorkspaceLayer {
            anchors.fill: parent
            workspaceId: hyprMonitor && hyprMonitor.activeWorkspace ? hyprMonitor.activeWorkspace.id : 1
            workspaceName: hyprMonitor && hyprMonitor.activeWorkspace ? hyprMonitor.activeWorkspace.name : "1"
            slideDirection: root.workspaceSlideDirection
            opacity: (root.peekingWorkspace && !root.expanded && !root.peekingNotif && !root.peekingVolume) ? 1 : 0
            visible: opacity > 0.01

            Behavior on opacity { NumberAnimation { duration: 180 } }
        }

        // Notification Peek Content
        IslandNotificationLayer {
            anchors.fill: parent
            notification: root.activeNotification
            expanded: root.notifExpanded
            opacity: root.peekingNotif ? 1 : 0
            visible: opacity > 0.01

            onExpansionToggleRequested: root.notifExpanded = !root.notifExpanded

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
                scale: root.page === "clock" ? 1 : 0.95
                visible: opacity > 0.01

                Behavior on opacity { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
                Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }

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
                scale: root.page === "player" ? 1 : 0.95
                visible: opacity > 0.01

                Behavior on opacity { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
                Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
            }

            // Page 3: System Stats / Control Center
            IslandSystemStats {
                id: statsPage
                anchors.fill: parent
                opacity: root.page === "stats" ? 1 : 0
                scale: root.page === "stats" ? 1 : 0.95
                visible: opacity > 0.01

                onWifiRightClicked: root.showWifi()
                onBtRightClicked: root.showBluetooth()
                Behavior on opacity { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
                Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
            }

            // Page 4: Notification History Center
            IslandNotificationCenterLayer {
                id: notifsPage
                anchors.fill: parent
                opacity: root.page === "notifs" ? 1 : 0
                scale: root.page === "notifs" ? 1 : 0.95
                visible: opacity > 0.01

                Behavior on opacity { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
                Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
            }

            // Page 6: Wi-Fi Detail Page
            IslandWifiLayer {
                id: wifiPage
                anchors.fill: parent
                opacity: root.page === "wifi" ? 1 : 0
                scale: root.page === "wifi" ? 1 : 0.95
                visible: opacity > 0.01

                onBackClicked: root.showStats()

                Behavior on opacity { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
                Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
            }

            // Page 7: Bluetooth Detail Page
            IslandBluetoothLayer {
                id: btPage
                anchors.fill: parent
                opacity: root.page === "bluetooth" ? 1 : 0
                scale: root.page === "bluetooth" ? 1 : 0.95
                visible: opacity > 0.01

                onBackClicked: root.showStats()

                Behavior on opacity { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
                Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
            }

            // Page 8: Logout / wlogout Page
            IslandLogoutLayer {
                id: logoutPage
                anchors.fill: parent
                opacity: root.page === "logout" ? 1 : 0
                scale: root.page === "logout" ? 1 : 0.95
                visible: opacity > 0.01
                focus: root.page === "logout"

                onActionTriggered: root.setExpanded(false)

                Behavior on opacity { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
                Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
            }

            // Page 9: Emoji Picker Page
            IslandEmojiPicker {
                id: emojiPage
                anchors.fill: parent
                opacity: root.page === "emojis" ? 1 : 0
                scale: root.page === "emojis" ? 1 : 0.95
                visible: opacity > 0.01

                onEmojiPicked: root.setExpanded(false)
                onUserActivity: root.notifyActivity()

                Behavior on opacity { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
                Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
            }

            // Page 10: Workspace Overview Page
            IslandWorkspaceOverview {
                id: workspacePage
                anchors.fill: parent
                screen: root.screen
                opacity: root.page === "workspace" ? 1 : 0
                scale: root.page === "workspace" ? 1 : 0.95
                visible: opacity > 0.01

                onWorkspaceSelected: root.setExpanded(false)
                onUserActivity: root.notifyActivity()

                Behavior on opacity { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
                Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
            }

            // Page 11: Cliphist Clipboard Manager Page
            IslandCliphist {
                id: cliphistPage
                anchors.fill: parent
                opacity: root.page === "cliphist" ? 1 : 0
                scale: root.page === "cliphist" ? 1 : 0.95
                visible: opacity > 0.01

                onCloseRequested: root.setExpanded(false)
                onUserActivity: root.notifyActivity()

                Behavior on opacity { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
                Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
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
                    width: root.page === modelData ? 14 : 5
                    height: 5
                    radius: 2.5
                    color: root.page === modelData ? Theme.text : "#555555"

                    Behavior on width { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                    Behavior on color { ColorAnimation { duration: 150 } }
                }
            }
        }
    }
}
