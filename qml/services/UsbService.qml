pragma Singleton
import QtQuick
import Quickshell.Io

QtObject {
    id: root

    property bool active: true
    property var knownDevices: ({})
    property bool initialized: false

    property var _proc: Process {
        id: proc
        command: ["sh", "-c", "lsblk -o NAME,TRAN,MODEL,SIZE,LABEL -J 2>/dev/null || echo '{\"blockdevices\":[]}'"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: (text) => {
                if (!text) return;
                try {
                    const data = JSON.parse(text);
                    const devices = data.blockdevices || [];
                    const currentMap = {};

                    for (let i = 0; i < devices.length; i++) {
                        const dev = devices[i];
                        if (dev.tran === "usb") {
                            const id = dev.name;
                            const model = dev.model ? dev.model.trim() : "USB Drive";
                            const size = dev.size || "";
                            const label = dev.label ? dev.label.trim() : "";
                            const nameStr = label !== "" ? (label + " (" + model + ")") : model;
                            currentMap[id] = { name: nameStr, size: size };
                        }
                    }

                    if (!root.initialized) {
                        root.knownDevices = currentMap;
                        root.initialized = true;
                        return;
                    }

                    // Check for newly connected USB drives
                    for (let id in currentMap) {
                        if (!root.knownDevices[id]) {
                            const info = currentMap[id];
                            NotificationService.pushCustom({
                                appName: "USB Storage",
                                summary: "💾 USB Drive Plugged In",
                                body: info.name + (info.size ? (" • " + info.size) : "")
                            });
                        }
                    }

                    // Check for disconnected USB drives
                    for (let id in root.knownDevices) {
                        if (!currentMap[id]) {
                            const info = root.knownDevices[id];
                            NotificationService.pushCustom({
                                appName: "USB Storage",
                                summary: "⏏️ USB Drive Disconnected",
                                body: info.name + " removed"
                            });
                        }
                    }

                    root.knownDevices = currentMap;
                } catch (e) {
                    // Ignore json parse error
                }
            }
        }
    }

    property var _timer: Timer {
        interval: 2000
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
