import QtQuick

// Ticks once a second and exposes formatted time/date strings.
Item {
    id: root

    property string timeText: Qt.formatTime(new Date(), "hh:mm")
    property string dateText: Qt.formatDate(new Date(), "ddd, MMM d")

    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            const now = new Date();
            root.timeText = Qt.formatTime(now, "hh:mm");
            root.dateText = Qt.formatDate(now, "ddd, MMM d");
        }
    }
}
