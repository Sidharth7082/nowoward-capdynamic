pragma Singleton
import QtQuick
import Quickshell.Io

QtObject {
    id: root

    property bool active: true
    property bool present: true
    property int percentage: 100
    property bool charging: false
    property bool plugged: false

    property bool _initialized: false
    property bool _prevPlugged: false

    onPluggedChanged: {
        if (!_initialized) {
            _initialized = true;
            _prevPlugged = plugged;
            return;
        }
        if (plugged !== _prevPlugged) {
            _prevPlugged = plugged;
            if (plugged) {
                NotificationService.pushCustom({
                    appName: "Power",
                    summary: "⚡ Charger Connected",
                    body: "Charging: " + percentage + "%"
                });
            } else {
                NotificationService.pushCustom({
                    appName: "Power",
                    summary: "🔋 Charger Disconnected",
                    body: "Battery level: " + percentage + "%"
                });
            }
        }
    }

    property var _proc: Process {
        command: ["sh", "-c", "cap=$(cat /sys/class/power_supply/BAT0/capacity /sys/class/power_supply/BAT*/capacity 2>/dev/null | head -n 1); stat=$(cat /sys/class/power_supply/BAT0/status /sys/class/power_supply/BAT*/status 2>/dev/null | head -n 1); echo \"$cap|$stat\""]
        running: false
        stdout: StdioCollector {
            id: _colBatGet
            waitForEnd: true
        }
        onExited: {
            const text = _colBatGet.text;
            root._parse(text)
        }
    }

    property var _timer: Timer {
        interval: 2000
        running: root.active
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (!root._proc.running)
                root._proc.running = true
        }
    }

    function _parse(text) {
        if (!text) return
        var parts = text.trim().split("|")
        var val = parts.length >= 1 ? parseInt(parts[0]) : NaN
        if (!isNaN(val)) {
            root.present = true
            if (val > 0)
                root.percentage = val
        } else {
            root.present = false
        }
        if (parts.length >= 2) {
            var st = parts[1].toLowerCase()
            root.charging = (st === "charging")
            root.plugged = (st === "charging" || st === "full")
        } else {
            root.charging = false
            root.plugged = false
        }
    }
}
