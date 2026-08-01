pragma Singleton
import QtQuick
import Quickshell.Io

QtObject {
    id: root

    property bool enabled: true
    property string statusText: "On"

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

    property var _procToggle: Process {
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

    property var _timer: Timer {
        interval: 4000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            root._procStatus.running = false;
            root._procStatus.running = true;
        }
    }
}
