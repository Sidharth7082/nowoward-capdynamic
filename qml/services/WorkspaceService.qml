pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

QtObject {
    id: root

    readonly property var monitor: Hyprland.focusedMonitor
    readonly property int activeWorkspaceId: monitor && monitor.activeWorkspace ? Math.max(1, monitor.activeWorkspace.id) : 1

    property string activeWallpaper: (Quickshell.env("HOME") || "") + "/Pictures/Wallpapers/Angel_Warrior.jpg"

    property var _wallpaperProc: Process {
        command: ["sh", "-c", "(awww query 2>/dev/null || swww query 2>/dev/null) | sed -n 's/.*image: //p' | head -n 1"]
        running: false
        stdout: StdioCollector {
            id: _colWallpaper
            waitForEnd: true
        }
        onExited: {
            const text = _colWallpaper.text;
            if (text && text.trim().length > 0) {
                const wp = text.trim();
                if (wp !== root.activeWallpaper)
                    root.activeWallpaper = wp;
            }
        }
    }

    // Wallpaper is only needed for previews (workspace overview + picker);
    // 5s keeps it fresh without the old 1s churn.
    property var _pollTimer: Timer {
        interval: 5000
        running: true
        repeat: true
        onTriggered: {
            if (!root._wallpaperProc.running)
                root._wallpaperProc.running = true;
        }
    }

    property var _dispatchProc: Process {
        id: dispatchProc
    }

    function switchToWorkspace(wsId) {
        if (!wsId || wsId < 1) return;
        dispatchProc.running = false;
        dispatchProc.command = ["hyprctl", "dispatch", "workspace", String(wsId)];
        dispatchProc.running = true;
    }
}
