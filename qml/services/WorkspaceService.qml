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
    property var windowsByWorkspace: ({})

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

    property var _clientProc: Process {
        command: ["hyprctl", "clients", "-j"]
        running: false
        stdout: StdioCollector {
            id: _colClients
            waitForEnd: true
        }
        onExited: {
            const text = _colClients.text;
            if (text)
                root._parseClients(text);
        }
    }

    property var _pollTimer: Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: {
            if (!root._wallpaperProc.running)
                root._wallpaperProc.running = true;
            if (!root._clientProc.running)
                root._clientProc.running = true;
        }
    }

    property var _dispatchProc: Process {
        id: dispatchProc
    }

    Component.onCompleted: {
        root._wallpaperProc.running = true;
        root._clientProc.running = true;
    }

    function switchToWorkspace(wsId) {
        if (!wsId || wsId < 1) return;
        dispatchProc.running = false;
        dispatchProc.command = ["hyprctl", "dispatch", "workspace", String(wsId)];
        dispatchProc.running = true;
    }

    function getWindowsForWorkspace(wsId) {
        const list = root.windowsByWorkspace[wsId];
        return Array.isArray(list) ? list : [];
    }

    function _parseClients(text) {
        if (!text) return;
        try {
            const clients = JSON.parse(text);
            if (!Array.isArray(clients)) return;

            let byWs = {};
            for (let i = 0; i < clients.length; i++) {
                const c = clients[i];
                if (!c || !c.workspace) continue;
                const wsId = c.workspace.id;
                if (!byWs[wsId]) byWs[wsId] = [];
                byWs[wsId].push({
                    address: c.address || "",
                    title: c.title || "",
                    class: c.class || c.initialClass || "",
                    at: c.at || [0, 0],
                    size: c.size || [400, 300],
                    floating: !!c.floating
                });
            }
            root.windowsByWorkspace = byWs;
        } catch (e) {
            // Ignore parse errors
        }
    }
}
