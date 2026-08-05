pragma Singleton
import QtQuick
import Quickshell.Io

QtObject {
    id: root

    property bool enabled: false
    property bool serviceActive: true
    property string statusText: "Checking..."
    property var deviceList: []

    property var _procStatus: Process {
        command: ["sh", "-c", "systemctl is-active --quiet bluetooth 2>/dev/null && (bluetoothctl show 2>/dev/null | grep 'Powered:' | awk '{print $2}' || echo 'no') || echo 'service_inactive'"]
        running: false
        stdout: StdioCollector {
            id: _colStatus
            waitForEnd: true
        }
        onExited: {
            const text = _colStatus.text;
            if (!text) return;
            const p = text.trim().toLowerCase();
            if (p === "service_inactive") {
                root.serviceActive = false;
                root.enabled = false;
                root.statusText = "Service Inactive";
            } else {
                root.serviceActive = true;
                root.enabled = (p === "yes");
                root.statusText = root.enabled ? "On" : "Off";
            }
        }
    }

    property var _procDevices: Process {
        command: ["sh", "-c", "bluetoothctl devices 2>/dev/null || echo ''"]
        running: false
        stdout: StdioCollector {
            id: _colDevices
            waitForEnd: true
        }
        onExited: {
            const text = _colDevices.text;
            root._parseDevices(text);
        }
    }

    property var _procToggle: Process {
        command: []
        running: false
    }

    property var _procStartService: Process {
        command: ["sh", "-c", "pkexec systemctl enable --now bluetooth 2>/dev/null || systemctl start bluetooth"]
        running: false
    }

    property var _procSettings: Process {
        command: []
        running: false
    }

    function startService() {
        if (root._procStartService.running) return; // don't kill an in-flight start
        root._procStartService.running = true;
    }

    function toggleBluetooth() {
        if (!root.serviceActive) {
            root.startService();
            return;
        }
        const nextState = root.enabled ? "power off" : "power on";
        root.enabled = !root.enabled;
        root.statusText = root.enabled ? "On" : "Off";
        root._procToggle.command = ["sh", "-c", "bluetoothctl " + nextState];
        if (!root._procToggle.running)
            root._procToggle.running = true;
    }

    function scanDevices() {
        if (!root.serviceActive) return;
        // Never kill an in-flight scan — the 4s poller would starve it.
        if (root._procDevices.running) return;
        root._procDevices.running = true;
    }

    function openSettings() {
        root._procSettings.command = ["sh", "-c", "systemctl is-active --quiet bluetooth || (pkexec systemctl enable --now bluetooth 2>/dev/null); blueman-manager 2>/dev/null || gnome-control-center bluetooth 2>/dev/null || kitty -e bluetoothctl 2>/dev/null || bluetoothctl"];
        if (!root._procSettings.running)
            root._procSettings.running = true;
    }

    function _parseDevices(raw) {
        if (!raw) return;
        const lines = raw.trim().split("\n");
        let results = [];

        for (let i = 0; i < lines.length; i++) {
            const line = lines[i].trim();
            if (!line) continue;
            const parts = line.split(/\s+/);
            if (parts.length >= 3) {
                const mac = parts[1];
                const name = parts.slice(2).join(" ");
                results.push({
                    mac: mac,
                    name: name
                });
            }
        }

        root.deviceList = [];
        root.deviceList = results;
    }

    property var _timer: Timer {
        interval: 4000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (!root._procStatus.running)
                root._procStatus.running = true;
            if (root.serviceActive)
                root.scanDevices();
        }
    }
}
