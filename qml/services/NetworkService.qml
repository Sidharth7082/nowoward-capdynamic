pragma Singleton
import QtQuick
import Quickshell.Io

QtObject {
    id: root

    property bool enabled: true
    property string ssid: "Connected"
    property var networkList: []

    property var _procStatus: Process {
        command: ["sh", "-c", "nmcli radio wifi 2>/dev/null || echo 'enabled'"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: (text) => {
                if (!text) return;
                root.enabled = text.trim().toLowerCase() === "enabled";
            }
        }
    }

    property var _procSsid: Process {
        command: ["sh", "-c", "nmcli -t -f active,ssid dev wifi 2>/dev/null | grep '^yes:' | cut -d: -f2 || echo ''"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: (text) => {
                if (!text) return;
                const s = text.trim();
                root.ssid = s.length > 0 ? s : (root.enabled ? "Disconnected" : "Off");
            }
        }
    }

    property var _procScan: Process {
        command: ["sh", "-c", "nmcli -t -f IN-USE,SSID,SIGNAL,SECURITY dev wifi list 2>/dev/null"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: (text) => {
                root._parseNetworks(text);
            }
        }
    }

    property var _procToggle: Process {
        command: []
        running: false
    }

    property var _procSettings: Process {
        command: []
        running: false
    }

    function toggleWifi() {
        const nextState = root.enabled ? "off" : "on";
        root.enabled = !root.enabled;
        root._procToggle.command = ["nmcli", "radio", "wifi", nextState];
        root._procToggle.running = false;
        root._procToggle.running = true;
    }

    function scanNetworks() {
        root._procScan.running = false;
        root._procScan.running = true;
    }

    function openSettings() {
        root._procSettings.command = ["sh", "-c", "nm-connection-editor 2>/dev/null || gnome-control-center wifi 2>/dev/null || kitty -e nmtui 2>/dev/null || foot -e nmtui 2>/dev/null || nmtui"];
        root._procSettings.running = false;
        root._procSettings.running = true;
    }

    function _parseNetworks(raw) {
        if (!raw) return;
        const lines = raw.trim().split("\n");
        let results = [];
        let seen = {};

        for (let i = 0; i < lines.length; i++) {
            const line = lines[i].trim();
            if (!line) continue;
            const parts = line.split(":");
            if (parts.length >= 3) {
                const inUse = parts[0].trim() === "*";
                const netSsid = parts[1].trim();
                const signal = parseInt(parts[2]) || 0;
                const sec = parts.length >= 4 ? parts[3].trim() : "Open";

                if (netSsid && !seen[netSsid]) {
                    seen[netSsid] = true;
                    results.push({
                        inUse: inUse,
                        ssid: netSsid,
                        signal: signal,
                        security: sec
                    });
                }
            }
        }

        root.networkList = [];
        root.networkList = results;
    }

    property var _timer: Timer {
        interval: 4000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            root._procStatus.running = false;
            root._procStatus.running = true;
            root._procSsid.running = false;
            root._procSsid.running = true;
            root.scanNetworks();
        }
    }
}
