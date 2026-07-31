import QtQuick

// A row of bars that bounce to fake "levels" while playing, and settle flat
// when paused.
Row {
    id: root

    property bool playing: true
    property color barColor: "#c084fc"
    property int barCount: 4

    spacing: 3
    height: 16

    Repeater {
        model: root.barCount

        Rectangle {
            id: bar

            readonly property int seed: index
            width: 3
            radius: 1.5
            color: root.barColor
            anchors.bottom: parent.bottom
            height: root.playing ? 6 : 4

            Behavior on height {
                NumberAnimation { duration: 220; easing.type: Easing.InOutQuad }
            }

            Timer {
                interval: 260 + bar.seed * 70
                running: root.playing
                repeat: true
                onTriggered: bar.height = 4 + Math.random() * 12
            }
        }
    }
}
