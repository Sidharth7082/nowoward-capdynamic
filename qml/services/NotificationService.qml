pragma Singleton
import QtQuick
import Quickshell.Services.Notifications

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

        root.history = [notifItem, ...root.history.slice(0, 19)];
        root.list = [n, ...root.list];
        root.latestNotification = n;
        root.notificationAdded(n);

        n.onClosed.connect(function() {
            root.list = root.list.filter(function(x) { return x !== n; });
            if (root.latestNotification === n)
                root.latestNotification = null;
        });
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
        root.history = [notifItem, ...root.history.slice(0, 19)];
        root.latestNotification = notifItem;
        root.notificationAdded(notifItem);
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
}
