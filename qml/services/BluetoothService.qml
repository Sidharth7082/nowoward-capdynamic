pragma Singleton
import QtQuick
import Quickshell.Io

QtObject {
    id: root

    property bool enabled: false
    property bool serviceActive: true
    property bool bluezInstalled: true
    property string statusText: "Checking..."
    property string hintText: "" // actionable message shown under the start button
    property var deviceList: []

    // Reports one of: not_installed / service_inactive / yes / no
    property var _procStatus: Process {
        command: ["sh", "-c",
            "if ! command -v bluetoothd >/dev/null 2>&1 && ! systemctl cat bluetooth.service >/dev/null 2>&1; then echo 'not_installed';"
            + " elif ! systemctl is-active --quiet bluetooth 2>/dev/null; then echo 'service_inactive';"
            + " else bluetoothctl show 2>/dev/null | awk '/Powered:/{p=$2} END{print p}' || echo 'no'; fi"]
        running: false
        stdout: StdioCollector {
            id: _colStatus
            waitForEnd: true
        }
        onExited: {
            const text = _colStatus.text;
            if (!text) return;
            const p = text.trim().toLowerCase();
            if (p === "not_installed") {
                root.bluezInstalled = false;
                root.serviceActive = false;
                root.enabled = false;
                root.statusText = "Bluez not installed";
            } else if (p === "service_inactive") {
                root.bluezInstalled = true;
                root.serviceActive = false;
                root.enabled = false;
                root.statusText = "Service Inactive";
            } else {
                root.bluezInstalled = true;
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

    // Starts the Bluez daemon through every privilege path we have. Starting a
    // system service needs root, and quickshell-spawned processes have no
    // interactive terminal — so without a polkit agent or passwordless sudo
    // this fails, and the UI tells the user the exact command to run instead
    // of silently doing nothing.
    property var _procStartService: Process {
        command: ["sh", "-c",
            "if command -v bluetoothd >/dev/null 2>&1 || systemctl cat bluetooth.service >/dev/null 2>&1; then"
            + " if timeout 30 pkexec systemctl enable --now bluetooth 2>/dev/null"
            + " || timeout 10 sudo -n systemctl enable --now bluetooth 2>/dev/null"
            + " || timeout 10 systemctl enable --now bluetooth 2>/dev/null; then echo started; else echo failed; fi;"
            + " else echo not_installed; fi"]
        running: false
        stdout: StdioCollector {
            id: _colStart
            waitForEnd: true
        }
        onExited: {
            const p = _colStart.text.trim();
            if (p === "started") {
                root.statusText = "Starting daemon…";
                root.hintText = "";
                // Re-check right away instead of waiting for the 4s poller.
                if (!root._procStatus.running)
                    root._procStatus.running = true;
            } else if (p === "not_installed") {
                root.hintText = "Install: sudo pacman -S bluez bluez-utils";
            } else {
                root.hintText = root.bluezInstalled
                    ? "Run: sudo systemctl enable --now bluetooth"
                    : "Install: sudo pacman -S bluez bluez-utils";
            }
        }
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
