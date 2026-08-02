import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

Item {
    id: root

    visible: false

    property var windowList: []
    property var windowByAddress: ({})
    property var workspaces: []
    property var activeWorkspace: null
    property var monitors: []
    property bool clientsReady: false
    property bool monitorsReady: false
    property bool workspacesReady: false
    property bool activeWorkspaceReady: false
    property bool clientsRefreshPending: false
    property bool monitorsRefreshPending: false
    property bool workspacesRefreshPending: false
    property bool activeWorkspaceRefreshPending: false
    property bool clientsRequestRunning: false
    property bool monitorsRequestRunning: false
    property bool workspacesRequestRunning: false
    property bool activeWorkspaceRequestRunning: false
    readonly property bool ready: clientsReady && monitorsReady && workspacesReady && activeWorkspaceReady

    property var _clientsProc: Process {
        command: ["hyprctl", "clients", "-j"]
        running: false
        stdout: StdioCollector {
            id: clientsCollector
            onStreamFinished: {
                root.clientsRequestRunning = false;
                if (clientsCollector.text && clientsCollector.text.trim().length > 0) {
                    root.windowList = root.parseJson(clientsCollector.text, []);
                    root.rebuildWindowIndex();
                    root.clientsReady = true;
                }
                root.flushRefresh();
            }
        }
    }

    property var _monitorsProc: Process {
        command: ["hyprctl", "monitors", "-j"]
        running: false
        stdout: StdioCollector {
            id: monitorsCollector
            onStreamFinished: {
                root.monitorsRequestRunning = false;
                if (monitorsCollector.text && monitorsCollector.text.trim().length > 0) {
                    root.monitors = root.parseJson(monitorsCollector.text, []);
                    root.monitorsReady = true;
                }
                root.flushRefresh();
            }
        }
    }

    property var _workspacesProc: Process {
        command: ["hyprctl", "workspaces", "-j"]
        running: false
        stdout: StdioCollector {
            id: workspacesCollector
            onStreamFinished: {
                root.workspacesRequestRunning = false;
                if (workspacesCollector.text && workspacesCollector.text.trim().length > 0) {
                    const rawWorkspaces = root.parseJson(workspacesCollector.text, []);
                    root.workspaces = rawWorkspaces.filter((workspace) => workspace.id >= 1 && workspace.id <= 100);
                    root.workspacesReady = true;
                }
                root.flushRefresh();
            }
        }
    }

    property var _activeWorkspaceProc: Process {
        command: ["hyprctl", "activeworkspace", "-j"]
        running: false
        stdout: StdioCollector {
            id: activeWorkspaceCollector
            onStreamFinished: {
                root.activeWorkspaceRequestRunning = false;
                if (activeWorkspaceCollector.text && activeWorkspaceCollector.text.trim().length > 0) {
                    root.activeWorkspace = root.parseJson(activeWorkspaceCollector.text, null);
                    root.activeWorkspaceReady = true;
                }
                root.flushRefresh();
            }
        }
    }

    function parseJson(text, fallback) {
        const source = String(text === undefined || text === null ? "" : text).trim();
        if (source === "")
            return fallback;

        try {
            return JSON.parse(source);
        } catch (error) {
            console.log("[HyprlandData] Failed to parse snapshot:", error);
            return fallback;
        }
    }

    function rebuildWindowIndex() {
        const byAddress = {};
        for (let index = 0; index < root.windowList.length; index++) {
            const win = root.windowList[index];
            if (win && win.address) {
                const addr = String(win.address || "").trim().toLowerCase();
                const normAddr = addr.startsWith("0x") ? addr : "0x" + addr;
                byAddress[normAddr] = win;
                byAddress[addr] = win;
            }
        }
        root.windowByAddress = byAddress;
    }

    function requestRefresh(refreshClients, refreshMonitors, refreshWorkspaces, refreshActiveWorkspace, immediate) {
        clientsRefreshPending = clientsRefreshPending || refreshClients;
        monitorsRefreshPending = monitorsRefreshPending || refreshMonitors;
        workspacesRefreshPending = workspacesRefreshPending || refreshWorkspaces;
        activeWorkspaceRefreshPending = activeWorkspaceRefreshPending || refreshActiveWorkspace;

        if (immediate) {
            refreshTimer.stop();
            flushRefresh();
        } else {
            refreshTimer.restart();
        }
    }

    function queueRefresh(refreshClients, refreshMonitors, refreshWorkspaces, refreshActiveWorkspace) {
        requestRefresh(refreshClients, refreshMonitors, refreshWorkspaces, refreshActiveWorkspace, false);
    }

    function updateAll() {
        requestRefresh(true, true, true, true, true);
    }

    function flushRefresh() {
        if (clientsRefreshPending && !clientsRequestRunning) {
            clientsRefreshPending = false;
            clientsRequestRunning = true;
            _clientsProc.running = false;
            _clientsProc.running = true;
        }
        if (monitorsRefreshPending && !monitorsRequestRunning) {
            monitorsRefreshPending = false;
            monitorsRequestRunning = true;
            _monitorsProc.running = false;
            _monitorsProc.running = true;
        }
        if (workspacesRefreshPending && !workspacesRequestRunning) {
            workspacesRefreshPending = false;
            workspacesRequestRunning = true;
            _workspacesProc.running = false;
            _workspacesProc.running = true;
        }
        if (activeWorkspaceRefreshPending && !activeWorkspaceRequestRunning) {
            activeWorkspaceRefreshPending = false;
            activeWorkspaceRequestRunning = true;
            _activeWorkspaceProc.running = false;
            _activeWorkspaceProc.running = true;
        }
    }

    function queueRefreshForEvent(event) {
        if (!event || !event.name)
            return;

        const name = String(event.name);
        if (["openlayer", "closelayer", "screencast"].indexOf(name) !== -1)
            return;

        if (name === "configreloaded") {
            queueRefresh(true, true, true, true);
            return;
        }

        const affectsActiveWorkspace = name === "workspace"
            || name === "workspacev2"
            || name === "focusedmon"
            || name === "focusedmonv2";
        const affectsWorkspaces = affectsActiveWorkspace
            || name.indexOf("workspace") !== -1;
        const affectsMonitors = name.indexOf("monitor") !== -1
            || name === "focusedmon"
            || name === "focusedmonv2";
        const affectsClients = name.indexOf("window") !== -1
            || name === "changefloatingmode"
            || name === "fullscreen"
            || name === "pin"
            || name === "urgent"
            || name === "minimize"
            || name === "moveintogroup"
            || name === "moveoutofgroup"
            || name === "togglegroup";

        if (!affectsClients && !affectsMonitors && !affectsWorkspaces && !affectsActiveWorkspace)
            return;

        queueRefresh(affectsClients, affectsMonitors, affectsWorkspaces, affectsActiveWorkspace);
    }

    Component.onCompleted: updateAll()
    Component.onDestruction: {
        refreshTimer.stop();
    }

    Timer {
        id: refreshTimer

        interval: 90
        repeat: false

        onTriggered: root.flushRefresh()
    }

    Connections {
        target: Hyprland

        function onRawEvent(event) {
            root.queueRefreshForEvent(event);
        }
    }
}
