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

    property var history: []
    property var latestNotification: null

    onNotification: function(n) {
        if (!n) return;
        n.tracked = true;

        const notifItem = {
            id: n.id || Date.now() + Math.random(),
            appName: n.appName || "Notification",
            summary: n.summary || "",
            body: n.body || "",
            appIcon: n.appIcon || "",
            time: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }),
            source: n
        };

        root.pushItem(notifItem);

        // Clear the active toast if the underlying DBus notification is closed.
        n.onClosed.connect(function() {
            if (root.latestNotification === notifItem)
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
            const source = root.latestNotification.source;
            if (source && source.dismiss) source.dismiss();
            root.latestNotification = null;
        }
    }
}
