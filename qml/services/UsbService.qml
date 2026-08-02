pragma Singleton
import QtQuick
import Quickshell.Io

QtObject {
    id: root

    property bool active: true
    property var knownDevices: ({})
    property bool initialized: false

    property var _proc: Process {
        command: ["sh", "-c", "lsblk -o NAME,TRAN,RM,MODEL,SIZE,LABEL -J 2>/dev/null || echo '{\"blockdevices\":[]}'"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: root._parse(text)
        }
    }

    property var _timer: Timer {
        interval: 2000
        running: root.active
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            root._proc.running = false
            root._proc.running = true
        }
    }

    function _parse(text) {
        if (!text) return
        try {
            const data = JSON.parse(text)
            const devices = data.blockdevices || []
            const currentMap = {}

            function checkDevice(dev) {
                if (!dev) return
                const isUsb = (dev.tran === "usb") || (dev.rm === true) || (dev.rm === 1) || (dev.rm === "1")
                if (isUsb) {
                    const id = dev.name
                    const model = dev.model ? dev.model.trim() : "USB Storage"
                    const size = dev.size ? dev.size.trim() : ""
                    const label = dev.label ? dev.label.trim() : ""
                    const nameStr = label !== "" ? (label + " (" + model + ")") : model
                    currentMap[id] = { name: nameStr, size: size }
                }
                if (dev.children && dev.children.length > 0) {
                    for (let c = 0; c < dev.children.length; c++) {
                        checkDevice(dev.children[c])
                    }
                }
            }

            for (let i = 0; i < devices.length; i++) {
                checkDevice(devices[i])
            }

            if (!root.initialized) {
                root.knownDevices = currentMap
                root.initialized = true
                return
            }

            // Check for newly connected USB drives
            for (let id in currentMap) {
                if (!root.knownDevices[id]) {
                    const info = currentMap[id]
                    NotificationService.pushCustom({
                        appName: "USB Storage",
                        summary: "🔌 USB Drive Plugged In",
                        body: info.name + (info.size ? (" • " + info.size) : "")
                    })
                }
            }

            // Check for disconnected USB drives
            for (let id in root.knownDevices) {
                if (!currentMap[id]) {
                    const info = root.knownDevices[id]
                    NotificationService.pushCustom({
                        appName: "USB Storage",
                        summary: "⏏️ USB Drive Ejected",
                        body: info.name + " removed"
                    })
                }
            }

            root.knownDevices = currentMap
        } catch (e) {
            // Ignore parse error
        }
    }
}
