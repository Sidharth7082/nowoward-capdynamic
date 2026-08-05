pragma Singleton
import QtQuick
import Quickshell.Io

QtObject {
    id: root

    property int brightness: 75

    property var _procGet: Process {
        command: ["sh", "-c", "brightnessctl -m 2>/dev/null || echo ',,75%'"]
        running: false
        stdout: StdioCollector {
            id: _colBriGet
            waitForEnd: true
        }
        onExited: {
            const text = _colBriGet.text;
            if (!text) return;
            const parts = text.trim().split(",");
            if (parts.length >= 4) {
                const pctStr = parts[3].replace("%", "").trim();
                const val = parseInt(pctStr);
                if (!isNaN(val)) root.brightness = val;
            }
        }
    }

    property var _procSet: Process {
        command: []
        running: false
    }

    function setBrightness(percent) {
        let p = Math.min(100, Math.max(5, Math.round(percent)));
        root.brightness = p;
        root._procSet.command = ["brightnessctl", "set", p + "%"];
        root._procSet.running = false;
        root._procSet.running = true;
    }

    property var _timer: Timer {
        interval: 3000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (!root._procGet.running) root._procGet.running = true;
        }
    }
}
