import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import "qml/services"
import "qml/wallpaperpicker"
import "qml/wlogout"
import "qml/theme"

Scope {
    id: shellRoot

    // Instantiations for global singletons
    property var _notifService: NotificationService
    property var _volService: VolumeService
    property var _cpuService: CpuService
    property var _memService: MemService
    property var _batService: BatteryService
    property var _brightService: BrightnessService
    property var _netService: NetworkService
    property var _btService: BluetoothService
    property var _usbService: UsbService

    // ── Adaptive service polling hub ─────────────────────────────────
    // Each island window calls updateActivity() (via its activityReporter
    // callback) whenever its state changes. This hub aggregates state across
    // all monitors and gates the polling services so they only spawn their
    // processes while their data is actually on screen.
    property bool islandVisible: false   // any island mapped (not fullscreen-hidden/suppressed)
    property bool anythingOpen: false    // any island expanded or showing a peek
    property bool statsActive: false     // control-center page open somewhere
    property bool wifiActive: false
    property bool btActive: false

    function updateActivity() {
        let vis = false, open = false, stats = false, wifi = false, bt = false;
        const wins = panelVariants.instances ? panelVariants.instances : [];
        for (let i = 0; i < wins.length; i++) {
            const w = wins[i];
            if (!w) continue;
            if (w.visible) vis = true;
            if (w.expanded || w.peeking || w.peekingNotif || w.peekingVolume || w.peekingWorkspace) open = true;
            if (w.page === "stats") stats = true;
            if (w.page === "wifi") wifi = true;
            if (w.page === "bluetooth") bt = true;
        }
        islandVisible = vis;
        anythingOpen = open;
        statsActive = stats;
        wifiActive = wifi;
        btActive = bt;
        applyActivity();
    }

    function applyActivity() {
        // Page-only data: poll only while their page is open.
        BrightnessService.active = statsActive;
        CpuService.active = statsActive;
        MemService.active = statsActive;

        // Wi-Fi / Bluetooth: full scan on their page; while only the
        // control-center tile is visible, fall back to a slow status poll.
        NetworkService.active = wifiActive || statsActive;
        NetworkService.pollInterval = wifiActive ? 4000 : 30000;
        BluetoothService.active = btActive || statsActive;
        BluetoothService.pollInterval = btActive ? 4000 : 30000;

        // Peek/notification drivers: keep working whenever any island is
        // mapped, but slow down while everything is collapsed.
        VolumeService.active = islandVisible;
        VolumeService.pollInterval = anythingOpen ? 2000 : 3000;
        BatteryService.active = islandVisible;
        BatteryService.pollInterval = anythingOpen ? 2000 : 5000;
        UsbService.active = islandVisible;
        UsbService.pollInterval = anythingOpen ? 2000 : 5000;
    }

    function forEachWindow(callback) {
        const windows = panelVariants.instances ? panelVariants.instances : [];
        for (let index = 0; index < windows.length; index++) {
            const window = windows[index];
            if (window)
                callback(window);
        }
    }

    function forFocusedWindow(callback) {
        const windows = panelVariants.instances ? panelVariants.instances : [];
        let fallbackWindow = null;
        for (let index = 0; index < windows.length; index++) {
            const window = windows[index];
            if (window && !fallbackWindow)
                fallbackWindow = window;
            if (window && window.hyprMonitor && window.hyprMonitor.focused) {
                callback(window);
                return;
            }
        }
        if (fallbackWindow)
            callback(fallbackWindow);
    }

    // Global media keys — registered ONCE at the shell level (not per-monitor,
    // which would register duplicate global shortcuts and can crash the
    // compositor). Route to the focused island window.
    // Wire them in hyprland.conf, e.g.:
    //   bind = , XF86AudioPlay, global, nowoward-capdynamic:play-pause
    //   bind = , XF86AudioNext, global, nowoward-capdynamic:next
    //   bind = , XF86AudioPrev, global, nowoward-capdynamic:previous
    GlobalShortcut {
        appid: "nowoward-capdynamic"
        name: "play-pause"
        description: "Play/Pause media"
        onPressed: shellRoot.forFocusedWindow((window) => window.mediaPlayPause())
    }
    GlobalShortcut {
        appid: "nowoward-capdynamic"
        name: "next"
        description: "Next track"
        onPressed: shellRoot.forFocusedWindow((window) => window.mediaNext())
    }
    GlobalShortcut {
        appid: "nowoward-capdynamic"
        name: "previous"
        description: "Previous track"
        onPressed: shellRoot.forFocusedWindow((window) => window.mediaPrevious())
    }

    // quickshell ipc call island toggle / show / hide / player / clock / stats / logout
    IpcHandler {
        target: "island"

        function toggle() {
            shellRoot.forFocusedWindow((window) => window.toggleExpanded());
        }

        function show() {
            shellRoot.forFocusedWindow((window) => window.setExpanded(true));
        }

        function hide() {
            shellRoot.forEachWindow((window) => window.setExpanded(false));
        }

        function player() {
            shellRoot.forFocusedWindow((window) => window.showPlayer());
        }

        function clock() {
            shellRoot.forFocusedWindow((window) => window.showClock());
        }

        function stats() {
            shellRoot.forFocusedWindow((window) => window.showStats());
        }

        function notifs() {
            shellRoot.forFocusedWindow((window) => window.showNotifs());
        }

        function wifi() {
            shellRoot.forFocusedWindow((window) => window.showWifi());
        }

        function bluetooth() {
            shellRoot.forFocusedWindow((window) => window.showBluetooth());
        }

        function logout() {
            shellRoot.forFocusedWindow((window) => window.showLogout());
        }

        function emojis() {
            shellRoot.forFocusedWindow((window) => window.showEmojis());
        }

        function workspace() {
            shellRoot.forFocusedWindow((window) => window.showWorkspace());
        }

        function cliphist() {
            shellRoot.forFocusedWindow((window) => window.showCliphist());
        }
    }

    // quickshell ipc call picker toggle / show / hide
    IpcHandler {
        target: "picker"

        function toggle() { wallpaperPicker.toggle(); }
        function show() { wallpaperPicker.show(); }
        function hide() { wallpaperPicker.hide(); }
    }

    // quickshell ipc call wlogout toggle / show / hide
    IpcHandler {
        target: "wlogout"

        function toggle() { wlogoutPanel.toggle(); }
        function show() { wlogoutPanel.show(); }
        function hide() { wlogoutPanel.hide(); }
    }

    // quickshell ipc call theme glassMode / defaultMode / toggle
    IpcHandler {
        target: "theme"

        function glassMode() { Theme.isMyGlass = true; }
        function defaultMode() { Theme.isMyGlass = false; }
        function toggle() { Theme.isMyGlass = !Theme.isMyGlass; }
    }

    WLogoutPanel {
        id: wlogoutPanel
    }

    // quickshell ipc call cliphist toggle / show / hide
    IpcHandler {
        target: "cliphist"

        function toggle() { shellRoot.forFocusedWindow((w) => { if (w.expanded && w.page === "cliphist") w.setExpanded(false); else w.showCliphist(); }); }
        function show() { shellRoot.forFocusedWindow((w) => w.showCliphist()); }
        function hide() { shellRoot.forEachWindow((w) => w.setExpanded(false)); }
    }

    WallpaperPickerPanel {
        id: wallpaperPicker
    }

    // Coordination: while the wallpaper picker is open, collapse every
    // island instance so the two don't overlap or fight for focus/input.
    Connections {
        target: wallpaperPicker
        function onShownChanged() {
            shellRoot.forEachWindow((window) => {
                window.suppressPeek = wallpaperPicker.shown;
                if (wallpaperPicker.shown)
                    window.setExpanded(false);
            });
        }
    }

    Variants {
        id: panelVariants

        model: Quickshell.screens

        DynamicIslandWindow {
            required property var modelData

            screen: modelData
            activityReporter: shellRoot.updateActivity
        }
    }
}
