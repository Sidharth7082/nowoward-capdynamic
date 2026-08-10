import QtQuick

// A row of bars that bounce to fake "levels" while playing, and settle flat
// when paused.
Row {
    id: root

    property bool playing: true
    property color barColor: "#c084fc"
    property int barCount: 4

    spacing: 3
    height: 18

    Repeater {
        model: root.barCount

        Rectangle {
            id: bar

            readonly property int seed: index
            // Random "level" driven by the bounce timer. Kept as a separate
            // property so the height binding below is never overwritten: the
            // old code did `bar.height = ...` in the timer, which destroys the
            // binding and froze the bars at random heights when paused.
            property real level: 0
            width: 4
            radius: 2
            color: root.barColor
            opacity: root.playing ? 0.95 : 0.45
            anchors.bottom: parent.bottom
            height: root.playing ? (5 + bar.level) : 4

            Behavior on height {
                NumberAnimation { duration: 220; easing.type: Easing.InOutQuad }
            }
            Behavior on opacity {
                NumberAnimation { duration: 300 }
            }

            Timer {
                interval: 260 + bar.seed * 70
                running: root.playing
                repeat: true
                onTriggered: bar.level = Math.random() * 12
            }
        }
    }
}
