pragma Singleton
import QtQuick

QtObject {
    property color bg: Colors.background
    property color border: Colors.border
    property color text: Colors.textPrimary
    property color subtext: Colors.textSecondary
    property color muted: Colors.textMuted
    property color accent: Colors.accent

    readonly property int collapsedWidth: 150
    readonly property int collapsedHeight: 34
    readonly property int clockWidth: 260
    readonly property int clockHeight: 92
    readonly property int playerWidth: 300
    readonly property int playerHeight: 150
    readonly property int statsWidth: 300
    readonly property int statsHeight: 150
    readonly property int notificationWidth: 320
    readonly property int notificationHeight: 96
}
