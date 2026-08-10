import QtQuick
import "../services"
import "../theme"

Item {
    id: root

    readonly property var userConfig: UserConfig

    property int workspaceId: 1
    property string workspaceName: String(workspaceId)
    property string displayText: "Workspace " + (workspaceName || workspaceId)
    property string textFontFamily: userConfig.textFontFamily
    property bool showCondition: true
    property int textPixelSize: 13
    property string slideDirection: "none" // "left" | "right" | "none"
    property bool animateVisibility: true
    property real transitionProgress: 0
    property real horizontalPadding: 14
    property real hiddenLeftPadding: 16
    property real hiddenRightPadding: 16

    // The slide itself: whenever the direction changes, animate
    // transitionProgress from ±1 (label fully off-screen on the incoming side)
    // down to 0 (centered). The parent island only shows this layer while the
    // peek is active, so the slide plays together with the fade-in.
    NumberAnimation {
        id: slideAnim
        target: root
        property: "transitionProgress"
        duration: 320
        easing.type: Easing.OutCubic
    }

    onSlideDirectionChanged: {
        if (root.slideDirection === "none") {
            slideAnim.stop();
            root.transitionProgress = 0;
        } else {
            root.transitionProgress = root.slideDirection === "right" ? 1 : -1;
            slideAnim.from = root.transitionProgress;
            slideAnim.to = 0;
            slideAnim.start();
        }
    }

    readonly property real clampedProgress: slideDirection === "right"
        ? Math.max(0, Math.min(1, transitionProgress))
        : (slideDirection === "left"
            ? Math.max(0, Math.min(1, -transitionProgress))
            : 0)
    readonly property real revealProgress: slideDirection === "none" ? 1 : (1 - clampedProgress)
    readonly property real textWidth: Math.max(0, width - horizontalPadding * 2)
    readonly property real centeredX: horizontalPadding
    readonly property real hiddenLeftX: -textWidth - hiddenLeftPadding
    readonly property real hiddenRightX: width + hiddenRightPadding
    readonly property real labelX: slideDirection === "right"
        ? centeredX + (hiddenRightX - centeredX) * clampedProgress
        : (slideDirection === "left"
            ? centeredX + (hiddenLeftX - centeredX) * clampedProgress
            : centeredX)

    anchors.fill: parent
    clip: true
    opacity: showCondition ? (animateVisibility ? revealProgress : 1) : 0

    Behavior on opacity {
        enabled: animateVisibility

        NumberAnimation {
            duration: showCondition ? 300 : 100
            easing.type: Easing.InOutQuad
        }
    }

    Row {
        x: labelX
        width: textWidth
        anchors.verticalCenter: parent.verticalCenter
        spacing: 8

        Rectangle {
            width: 18
            height: 18
            radius: 9
            color: Colors.accent
            anchors.verticalCenter: parent.verticalCenter

            Text {
                anchors.centerIn: parent
                text: "✦"
                color: "white"
                font.pixelSize: 10
            }
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.displayText
            color: Theme.text
            opacity: revealProgress
            font.pixelSize: textPixelSize
            font.family: textFontFamily
            font.weight: Font.DemiBold
            font.letterSpacing: -0.15
            elide: Text.ElideRight
            wrapMode: Text.NoWrap
        }
    }
}
