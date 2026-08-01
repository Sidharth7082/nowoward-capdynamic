pragma Singleton
import QtQuick
import Quickshell.Services.Notifications
import Quickshell.Io

NotificationServer {
    id: root

    bodyMarkupSupported: true
    bodySupported: true
    actionsSupported: true
    keepOnReload: true

    signal notificationAdded(var notification)

    property var list: []
    property var history: []
    property var latestNotification: null

    onNotification: function(n) {
        if (!n) return;
        n.tracked = true;

        if (root.list.includes(n)) return;

        const notifItem = {
            id: n.id || Date.now() + Math.random(),
            appName: n.appName || "Notification",
            summary: n.summary || "",
            body: n.body || "",
            appIcon: n.appIcon || "",
            time: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })
        };

        root.pushItem(notifItem);

        n.onClosed.connect(function() {
            root.list = root.list.filter(function(x) { return x !== n; });
            if (root.latestNotification === n)
                root.latestNotification = null;
        });
    }

    function pushItem(notifItem) {
        // Prevent immediate duplicate entries
        if (root.history.length > 0) {
            const top = root.history[0];
            if (top.appName === notifItem.appName && top.summary === notifItem.summary && top.body === notifItem.body) {
                return;
            }
        }

        root.history = [notifItem, ...root.history.slice(0, 19)];
        root.latestNotification = notifItem;
        root.notificationAdded(notifItem);
    }

    function pushCustom(data) {
        if (!data) return;
        const notifItem = {
            id: Date.now() + Math.random(),
            appName: data.appName || "System",
            summary: data.summary || "",
            body: data.body || "",
            appIcon: data.appIcon || "",
            time: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })
        };
        root.pushItem(notifItem);
    }

    function removeHistoryItem(itemId) {
        root.history = root.history.filter(function(x) { return x.id !== itemId; });
    }

    function clearHistory() {
        root.history = [];
    }

    function dismissLatest() {
        if (root.latestNotification) {
            if (root.latestNotification.dismiss) root.latestNotification.dismiss();
            root.latestNotification = null;
        }
    }

    // Reference Project dbus-monitor sniffer for 100% notification capture guarantee
    property var _monitorProc: Process {
        id: monitorProc
        command: ["dbus-monitor", "type='method_call',interface='org.freedesktop.Notifications',member='Notify'"]
        running: true

        property string currentBlock: ""

        stdout: SplitParser {
            onRead: (line) => {
                if (line.includes("method call") && line.includes("member=Notify")) {
                    monitorProc.parseBlock(monitorProc.currentBlock);
                    monitorProc.currentBlock = line + "\n";
                } else if (monitorProc.currentBlock.length > 0) {
                    monitorProc.currentBlock += line + "\n";
                }
            }
        }

        function parseBlock(block) {
            if (!block || !block.includes("member=Notify")) return;
            const matches = [];
            const regex = /string\s+"([^"]*)"/g;
            let match;
            while ((match = regex.exec(block)) !== null) {
                matches.push(match[1]);
            }
            if (matches.length >= 2) {
                const appName = matches[0] || "Notification";
                const summary = matches[1] || "";
                const body = matches.length >= 3 ? matches[2] : "";

                // Skip internal quickshell/tide messages to avoid infinite loops
                if (appName === "Power" || appName === "USB Storage") return;

                root.pushCustom({
                    appName: appName,
                    summary: summary,
                    body: body
                });
            }
        }
    }
}
