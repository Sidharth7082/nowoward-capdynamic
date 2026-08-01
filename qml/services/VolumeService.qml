pragma Singleton
import QtQuick
import Quickshell.Io

QtObject {
    id: root

    property int volume: 50
    property bool muted: false
    signal volumeUpdated(int newVolume, bool isMuted)

    property var _proc: Process {
        command: ["sh", "-c", "wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null || pactl get-sink-volume @DEFAULT_SINK@ 2>/dev/null || echo 'Volume: 0.50'"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: (text) => {
                root._parse(text);
            }
        }
    }

    property var _setProc: Process {
        command: []
        running: false
    }

    function setVolume(percent) {
        let p = Math.min(100, Math.max(0, Math.round(percent)));
        root.volume = p;
        root._setProc.command = ["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", (p / 100.0).toFixed(2)];
        root._setProc.running = false;
        root._setProc.running = true;
    }

    property var _timer: Timer {
        interval: 2000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            root._proc.running = false;
            root._proc.running = true;
        }
    }

    function _parse(text) {
        if (!text) return;
        let isMuted = text.includes("[MUTED]");
        let vol = root.volume;

        if (text.includes("Volume:")) {
            const parts = text.trim().split(/\s+/);
            for (let i = 0; i < parts.length; i++) {
                let num = parseFloat(parts[i]);
                if (!isNaN(num) && num <= 2.0) {
                    vol = Math.round(num * 100);
                    break;
                }
            }
        }

        if (vol !== root.volume || isMuted !== root.muted) {
            root.volume = vol;
            root.muted = isMuted;
            root.volumeUpdated(vol, isMuted);
        }
    }
}
