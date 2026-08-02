import QtQuick
import Quickshell.Hyprland

Item {
    id: root

    visible: false
    width: 0
    height: 0

    property var hyprMonitor: null
    property string monitorName: ""
    property bool monitorFocused: false

    readonly property int monitorWorkspaceId: hyprMonitor && hyprMonitor.activeWorkspace
        ? hyprMonitor.activeWorkspace.id
        : 1
    property int currentWorkspaceId: monitorWorkspaceId > 0 ? monitorWorkspaceId : 1
    property string lastSlideDirection: "none"

    signal workspaceSynced(int workspaceId)
    signal workspaceActivated(int workspaceId, string side)

    onMonitorWorkspaceIdChanged: syncWorkspaceState()
    Component.onCompleted: syncWorkspaceState()

    function normalizeWorkspaceId(rawValue) {
        const parsed = parseInt(String(rawValue === undefined || rawValue === null ? "" : rawValue), 10);
        return isNaN(parsed) ? -1 : parsed;
    }

    function syncWorkspaceState() {
        if (monitorWorkspaceId < 1)
            return;

        const oldWs = currentWorkspaceId;
        if (monitorWorkspaceId !== oldWs) {
            lastSlideDirection = monitorWorkspaceId > oldWs ? "right" : (monitorWorkspaceId < oldWs ? "left" : "none");
        }
        currentWorkspaceId = monitorWorkspaceId;
        workspaceSynced(monitorWorkspaceId);
    }

    function showWorkspaceForThisMonitor(workspaceId) {
        const targetWorkspaceId = normalizeWorkspaceId(workspaceId);
        if (targetWorkspaceId >= 1) {
            const side = targetWorkspaceId > currentWorkspaceId ? "right" : (targetWorkspaceId < currentWorkspaceId ? "left" : "none");
            lastSlideDirection = side;
            workspaceActivated(targetWorkspaceId, side);
        }
    }

    function handleWorkspaceEvent(event) {
        if (!event)
            return;

        if (event.name === "workspacev2" || event.name === "workspace") {
            const args = event.parse ? event.parse(event.name === "workspacev2" ? 2 : 1) : [];
            const targetWorkspaceId = normalizeWorkspaceId(args.length > 0 ? args[0] : "");
            if (targetWorkspaceId < 1)
                return;

            Qt.callLater(() => {
                const focusedWorkspace = Hyprland.focusedWorkspace;
                if (!root.monitorFocused || !focusedWorkspace)
                    return;
                if (focusedWorkspace.id !== targetWorkspaceId)
                    return;

                root.showWorkspaceForThisMonitor(targetWorkspaceId);
            });
            return;
        }

        if (event.name === "focusedmonv2" || event.name === "focusedmon") {
            const args = event.parse ? event.parse(2) : [];
            const targetMonitorName = args.length > 0 ? String(args[0]) : "";
            const targetWorkspaceId = normalizeWorkspaceId(args.length > 1 ? args[1] : "");
            if (targetWorkspaceId < 1)
                return;
            if (monitorName !== "" && targetMonitorName !== monitorName)
                return;

            showWorkspaceForThisMonitor(targetWorkspaceId);
        }
    }

    Connections {
        target: Hyprland

        function onRawEvent(event) {
            root.handleWorkspaceEvent(event);
        }
    }

    Connections {
        target: root.hyprMonitor

        function onActiveWorkspaceChanged() {
            root.syncWorkspaceState();
        }
    }
}
