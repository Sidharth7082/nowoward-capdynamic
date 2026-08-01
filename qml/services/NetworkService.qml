pragma Singleton
import QtQuick
import Quickshell.Io

QtObject {
    id: root

    property bool enabled: true
    property string ssid: "Connected"

    property var _procStatus: Process {
        command: ["sh", "-c", "nmcli radio wifi 2>/dev/null || echo 'enabled'"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: (text) => {
                if (!text) return;
                root.enabled = text.trim().toLowerCase() === "enabled";
            }
        }
    }

    property var _procSsid: Process {
        command: ["sh", "-c", "nmcli -t -f active,ssid dev wifi 2>/dev/null | grep '^yes:' | cut -d: -f2 || echo ''"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: (text) => {
                if (!text) return;
                const s = text.trim();
                root.ssid = s.length > 0 ? s : (root.enabled ? "Disconnected" : "Off");
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

    function toggleWifi() {
        const nextState = root.enabled ? "off" : "on";
        root.enabled = !root.enabled;
        root._procToggle.command = ["nmcli", "radio", "wifi", nextState];
        root._procToggle.running = false;
        root._procToggle.running = true;
    }

    function openSettings() {
        root._procSettings.command = ["sh", "-c", "nm-connection-editor 2>/dev/null || gnome-control-center wifi 2>/dev/null || kitty -e nmtui 2>/dev/null || foot -e nmtui 2>/dev/null || nmtui"];
        root._procSettings.running = false;
        root._procSettings.running = true;
    }

    property var _timer: Timer {
        interval: 4000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            root._procStatus.running = false;
            root._procStatus.running = true;
            root._procSsid.running = false;
            root._procSsid.running = true;
        }
    }
}
