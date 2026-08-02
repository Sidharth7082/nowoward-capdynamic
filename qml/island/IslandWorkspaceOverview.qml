import QtQuick
import Quickshell
import "../workspace"
import "../services"

Item {
    id: root
    anchors.fill: parent
    focus: true

    signal workspaceSelected()
    signal userActivity()

    property var screen: null

    function moveSelection(delta) {
        overviewLayer.moveSelection(delta);
    }
    function confirmSelection() {
        overviewLayer.selectCurrentKeyboardWorkspace();
    }
    function selectIndex(idx) {
        overviewLayer.selectWorkspaceIndex(idx);
    }

    HyprlandData {
        id: hyprData
    }

    onVisibleChanged: {
        if (visible) {
            overviewLayer.forceActiveFocus();
        }
    }

    WorkspaceOverviewLayer {
        id: overviewLayer
        anchors.centerIn: parent
        focus: true
        screen: root.screen || (Quickshell.screens && Quickshell.screens.length > 0 ? Quickshell.screens[0] : null)
        hyprlandData: hyprData
        showCondition: root.visible
        previewsEnabled: root.visible
        scale: 0.10

        onCloseRequested: {
            root.userActivity();
            root.workspaceSelected();
        }
    }
}
