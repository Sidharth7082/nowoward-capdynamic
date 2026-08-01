pragma Singleton
import QtQuick
import Quickshell.Io

QtObject {
    id: root

    property bool active: true
    property bool present: true
    property int percentage: 100
    property bool charging: false

    property var _proc: Process {
        id: proc
        command: ["sh", "-c", "cap=$(cat /sys/class/power_supply/BAT*/capacity 2>/dev/null | head -n 1); stat=$(cat /sys/class/power_supply/BAT*/status 2>/dev/null | head -n 1); echo \"$cap|$stat\""]
        running: false
        stdout: StdioCollector {
            onStreamFinished: (text) => {
                if (!text) return;
                const parts = text.trim().split("|");
                if (parts.length >= 1) {
                    const val = parseInt(parts[0]);
                    if (!isNaN(val)) {
                        root.present = true;
                        root.percentage = val;
                    }
                }
                if (parts.length >= 2) {
                    const st = parts[1].toLowerCase();
                    root.charging = (st === "charging" || st === "full");
                }
            }
        }
    }

    property var _timer: Timer {
        interval: 3000
        running: root.active
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (!proc.running) {
                proc.running = true;
            }
        }
    }
}
