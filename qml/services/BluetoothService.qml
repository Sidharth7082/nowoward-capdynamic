pragma Singleton
import QtQuick
import Quickshell.Io

QtObject {
    id: root

    property bool enabled: true
    property string statusText: "On"
    property var deviceList: []

    property var _procStatus: Process {
        command: ["sh", "-c", "bluetoothctl show 2>/dev/null | grep 'Powered:' | awk '{print $2}' || echo 'no'"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: (text) => {
                if (!text) return;
                const p = text.trim().toLowerCase();
                root.enabled = (p === "yes");
                root.statusText = root.enabled ? "On" : "Off";
            }
        }
    }

    property var _procDevices: Process {
        command: ["sh", "-c", "bluetoothctl devices 2>/dev/null || echo ''"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: (text) => {
                root._parseDevices(text);
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

    function toggleBluetooth() {
        const nextState = root.enabled ? "power off" : "power on";
        root.enabled = !root.enabled;
        root.statusText = root.enabled ? "On" : "Off";
        root._procToggle.command = ["sh", "-c", "bluetoothctl " + nextState];
        root._procToggle.running = false;
        root._procToggle.running = true;
    }

    function scanDevices() {
        root._procDevices.running = false;
        root._procDevices.running = true;
    }

    function openSettings() {
        root._procSettings.command = ["sh", "-c", "blueman-manager 2>/dev/null || gnome-control-center bluetooth 2>/dev/null || kitty -e bluetoothctl 2>/dev/null || bluetoothctl"];
        root._procSettings.running = false;
        root._procSettings.running = true;
    }

    function _parseDevices(raw) {
        if (!raw) return;
        const lines = raw.trim().split("\n");
        let results = [];

        for (let i = 0; i < lines.length; i++) {
            const line = lines[i].trim();
            if (!line) continue;
            // Format: Device MAC Name
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

        root.deviceList = results;
    }

    property var _timer: Timer {
        interval: 4000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            root._procStatus.running = false;
            root._procStatus.running = true;
            root.scanDevices();
        }
    }
}
