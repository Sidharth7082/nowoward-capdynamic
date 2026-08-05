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
            // brightnessctl -m field ORDER varies between versions
            // (dev,class,value,max,percent% vs dev,class,value,percent%,max):
            // locate the field that actually carries the percentage instead
            // of trusting an index. The bare ',,75%' fallback only has the
            // percent field, which this scan also handles.
            const parts = text.trim().split(",");
            for (let i = 0; i < parts.length; i++) {
                const part = parts[i];
                if (part.indexOf("%") !== -1) {
                    const val = parseInt(part.replace("%", "").trim());
                    if (!isNaN(val)) {
                        root.brightness = val;
                        break;
                    }
                }
            }
        }
    }

    property var _procSet: Process {
        command: []
        running: false
    }

    // Debounce: a slider drag calls setBrightness on every mouse move; queue
    // the target and spawn brightnessctl at most once per 60ms instead of
    // spawn-and-killing dozens of processes per drag.
    property real _setPending: -1
    property var _setTimer: Timer {
        interval: 60
        repeat: false
        onTriggered: {
            if (root._setPending >= 0) {
                const p = root._setPending;
                root._setPending = -1;
                root._procSet.command = ["brightnessctl", "set", p + "%"];
                root._procSet.running = false;
                root._procSet.running = true;
            }
        }
    }

    function setBrightness(percent) {
        let p = Math.min(100, Math.max(5, Math.round(percent)));
        root.brightness = p; // optimistic UI update
        root._setPending = p;
        root._setTimer.restart();
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
