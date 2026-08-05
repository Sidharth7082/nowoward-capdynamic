pragma Singleton
import QtQuick
import Quickshell.Io

QtObject {
    id: root

    property bool active: true
    property real usagePercent: 0.0
    property real totalMb: 0.0
    property real usedMb: 0.0

    property var _proc: Process {
        command: ["cat", "/proc/meminfo"]
        running: false
        stdout: StdioCollector {
            id: _colMem
            waitForEnd: true
        }
        // Stream-end events are not emitted reliably in some Quickshell builds —
        // collect the full stream and parse on exit instead.
        onExited: {
            const text = _colMem.text;
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
        var lines = text.split("\n")
        var memTotal = 0
        var memAvailable = 0

        for (var i = 0; i < lines.length; i++) {
            var line = lines[i]
            if (line.indexOf("MemTotal:") === 0) {
                memTotal = parseFloat(line.replace(/[^0-9]/g, ""))
            } else if (line.indexOf("MemAvailable:") === 0) {
                memAvailable = parseFloat(line.replace(/[^0-9]/g, ""))
            }
        }

        if (memTotal > 0) {
            var used = memTotal - memAvailable
            root.totalMb = Math.round(memTotal / 1024)
            root.usedMb = Math.round(used / 1024)
            root.usagePercent = Math.min(100.0, Math.max(0.0, Math.round((used / memTotal) * 100)))
        }
    }
}
