import QtQuick
import Quickshell
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
            if (window && window.monitorFocused) {
                callback(window);
                return;
            }
        }
        if (fallbackWindow)
            callback(fallbackWindow);
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
        }
    }
}
