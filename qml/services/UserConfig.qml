pragma Singleton
import QtQuick
import Quickshell

QtObject {
    id: root

    property string textFontFamily: "Sans"
    property string heroFontFamily: "Sans"
    readonly property string wallpaperPath: WorkspaceService.activeWallpaper || ((Quickshell.env("HOME") || "") + "/Pictures/Wallpapers/Angel_Warrior.jpg")
    property var workspaceOverviewWindowDragButton: "left"
    property var dynamicIslandPrimaryButton: "left"
    property var dynamicIslandSecondaryButton: "right"
    property int bodyFontSize: 13

    function mouseButton(button) {
        if (typeof button === "number") return button;
        const str = String(button || "").toLowerCase();
        if (str === "right") return Qt.RightButton;
        if (str === "middle") return Qt.MiddleButton;
        return Qt.LeftButton;
    }

    function mouseButtonsMask(buttons) {
        if (!Array.isArray(buttons)) return mouseButton(buttons);
        let mask = 0;
        for (let i = 0; i < buttons.length; i++) {
            mask |= mouseButton(buttons[i]);
        }
        return mask > 0 ? mask : Qt.LeftButton;
    }
}
