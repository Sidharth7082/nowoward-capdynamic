pragma Singleton
import QtQuick
import Quickshell.Io

QtObject {
    id: root

    property bool enabled: true
    property string ssid: ""
    property var networkList: []

    property var _procStatus: Process {
        command: ["sh", "-c", "nmcli radio wifi 2>/dev/null || echo 'enabled'"]
        running: false
        stdout: StdioCollector {
            id: _colStatus
            waitForEnd: true
        }
        // onStreamFinished is never emitted in some Quickshell builds — collect
        // the full stream and parse on exit instead.
        onExited: {
            const text = _colStatus.text;
            if (!text) return;
            root.enabled = text.trim().toLowerCase() === "enabled";
        }
    }

    property var _procSsid: Process {
        // Output the full active-ssid line; the SSID is extracted in JS so
        // terse-mode '\:' escapes inside the name don't break the parse.
        command: ["sh", "-c", "nmcli -t -f active,ssid dev wifi 2>/dev/null"]
        running: false
        stdout: StdioCollector {
            id: _colSsid
            waitForEnd: true
        }
        onExited: {
            const text = _colSsid.text;
            if (!text) return;
            const lines = text.trim().split("\n");
            let active = "";
            for (let i = 0; i < lines.length; i++) {
                const parts = root._splitTerse(lines[i]);
                if (parts.length >= 2 && parts[0] === "yes") {
                    active = parts[1];
                    break;
                }
            }
            root.ssid = active.length > 0
                ? active
                : (root.enabled ? "Disconnected" : "Off");
        }
    }

    property var _procScan: Process {
        command: []
        running: false
        stdout: StdioCollector {
            id: _colScan
            waitForEnd: true
        }
        onExited: {
            root._parseNetworks(_colScan.text);
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

    // nmcli terse mode escapes ':' as '\:' and '\' as '\\' — split on
    // unescaped colons so SSIDs like "My:Network" survive intact.
    function _splitTerse(line) {
        const parts = [];
        let cur = "";
        let escaped = false;
        for (let i = 0; i < line.length; i++) {
            const ch = line[i];
            if (escaped) {
                cur += ch;
                escaped = false;
            } else if (ch === "\\") {
                escaped = true;
            } else if (ch === ":") {
                parts.push(cur);
                cur = "";
            } else {
                cur += ch;
            }
        }
        if (escaped) cur += "\\";
        parts.push(cur);
        return parts;
    }

    function toggleWifi() {
        const nextState = root.enabled ? "off" : "on";
        root.enabled = !root.enabled;
        root._procToggle.command = ["nmcli", "radio", "wifi", nextState];
        if (!root._procToggle.running) {
            root._procToggle.running = true;
        }
    }

    // rescan=true forces a fresh NetworkManager scan (slower, use on page
    // open / explicit refresh); rescan=false reads the cached list (fast,
    // used by the periodic poller).
    function scanNetworks(rescan) {
        // Never kill an in-flight scan — restarting a still-running process
        // every poll cycle can starve it so onStreamFinished never fires.
        if (root._procScan.running) return;
        root._procScan.command = [
            "sh", "-c",
            "nmcli -t -f IN-USE,SSID,SIGNAL,SECURITY dev wifi list"
                + (rescan ? " --rescan yes" : "") + " 2>/dev/null"
        ];
        root._procScan.running = true;
    }

    function openSettings() {
        root._procSettings.command = ["sh", "-c", "nm-connection-editor 2>/dev/null || gnome-control-center wifi 2>/dev/null || kitty -e nmtui 2>/dev/null || foot -e nmtui 2>/dev/null || nmtui"];
        if (!root._procSettings.running) {
            root._procSettings.running = true;
        }
    }

    function _parseNetworks(raw) {
        if (!raw) return;
        const lines = raw.trim().split("\n");
        let results = [];
        let seen = {};

        for (let i = 0; i < lines.length; i++) {
            const line = lines[i].trim();
            if (!line) continue;
            const parts = root._splitTerse(line);
            if (parts.length >= 3) {
                const inUse = parts[0].trim() === "*";
                const netSsid = parts[1].trim();
                const signal = parseInt(parts[2]) || 0;
                const sec = parts.length >= 4 ? parts[3].trim() : "Open";

                // Skip hidden-network placeholders; dedupe by SSID.
                if (netSsid && netSsid !== "--" && !seen[netSsid]) {
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

        root.networkList = results;
    }

    property var _timer: Timer {
        interval: 4000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            // Only start idle processes — never kill a running one.
            if (!root._procStatus.running)
                root._procStatus.running = true;
            if (!root._procSsid.running)
                root._procSsid.running = true;
            root.scanNetworks(false);
        }
    }
}
