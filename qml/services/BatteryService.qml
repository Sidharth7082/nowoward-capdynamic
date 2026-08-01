pragma Singleton
import QtQuick
import Quickshell.Io

QtObject {
    id: root

    property bool active: true
    property bool present: false
    property int percentage: 100
    property bool charging: false

    property var _procCap: Process {
        command: ["sh", "-c", "cat /sys/class/power_supply/BAT*/capacity 2>/dev/null || echo ''"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: (text) => {
                if (!text) return;
                const val = parseInt(text.trim());
                if (!isNaN(val)) {
                    root.present = true;
                    root.percentage = val;
                } else {
                    root.present = false;
                }
            }
        }
    }

    property var _procStat: Process {
        command: ["sh", "-c", "cat /sys/class/power_supply/BAT*/status 2>/dev/null || echo ''"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: (text) => {
                if (!text) return;
                const status = text.trim().toLowerCase();
                root.charging = (status === "charging");
            }
        }
    }

    property var _timer: Timer {
        interval: 5000
        running: root.active
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            root._procCap.running = false;
            root._procCap.running = true;
            root._procStat.running = false;
            root._procStat.running = true;
        }
    }
}
