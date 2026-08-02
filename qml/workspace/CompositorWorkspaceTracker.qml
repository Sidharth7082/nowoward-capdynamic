import QtQuick

Item {
    id: root

    visible: false
    width: 0
    height: 0

    property string compositor: "hyprland"
    property var hyprMonitor: null
    property string hyprMonitorName: ""
    property string outputName: ""
    property bool monitorFocused: false
    property int currentWorkspaceId: 1

    signal workspaceSynced(int workspaceId)
    signal workspaceActivated(int workspaceId, string side)

    HyprlandWorkspaceTracker {
        id: hyprlandTracker
        hyprMonitor: root.hyprMonitor
        monitorName: root.hyprMonitorName
        monitorFocused: root.monitorFocused

        onWorkspaceSynced: function(workspaceId) {
            root.currentWorkspaceId = workspaceId;
            root.workspaceSynced(workspaceId);
        }

        onWorkspaceActivated: function(workspaceId, side) {
            root.currentWorkspaceId = workspaceId;
            root.workspaceActivated(workspaceId, side);
        }
    }
}
