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
    property var latestNotification: null

    onNotification: function(n) {
        if (!n) return;
        n.tracked = true;

        if (root.list.includes(n)) return;

        root.list = [n, ...root.list];
        root.latestNotification = n;
        root.notificationAdded(n);

        n.onClosed.connect(function() {
            root.list = root.list.filter(function(x) { return x !== n; });
            if (root.latestNotification === n)
                root.latestNotification = null;
        });
    }

    function dismissLatest() {
        if (root.latestNotification) {
            root.latestNotification.dismiss();
            root.latestNotification = null;
        }
    }
}
