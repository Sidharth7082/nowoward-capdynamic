pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Hyprland
import Quickshell.Io

QtObject {
    id: root

    property var _proc: Process {
        id: proc
    }

    function runHyprctl(args) {
        proc.running = false;
        proc.command = ["hyprctl"].concat(args);
        proc.running = true;
    }

    function luaString(value) {
        const text = String(value === undefined || value === null ? "" : value);
        return "\"" + text
            .replace(/\\/g, "\\\\")
            .replace(/"/g, "\\\"")
            .replace(/\n/g, "\\n")
            .replace(/\r/g, "\\r")
            .replace(/\t/g, "\\t") + "\"";
    }

    function normalizedAddress(value) {
        let rawAddress = "";
        if (value && typeof value === "object" && value.address !== undefined)
            rawAddress = String(value.address || "");
        else
            rawAddress = String(value === undefined || value === null ? "" : value);

        rawAddress = rawAddress.trim().toLowerCase();
        if (rawAddress.startsWith("address:"))
            rawAddress = rawAddress.slice(8);
        if (rawAddress === "" || rawAddress === "0x")
            return "";

        return rawAddress.startsWith("0x") ? rawAddress : "0x" + rawAddress;
    }

    function windowSelector(value) {
        const address = normalizedAddress(value);
        return address === "" ? "" : "address:" + address;
    }

    function workspaceExpression(value) {
        if (typeof value === "number" && isFinite(value))
            return String(Math.trunc(value));

        const text = String(value === undefined || value === null ? "" : value).trim();
        if (/^[1-9][0-9]*$/.test(text))
            return text;

        return luaString(text);
    }

    function numberExpression(value) {
        const parsed = Number(value);
        return isFinite(parsed) ? String(Math.round(parsed)) : "0";
    }

    function dispatchExpression(expression) {
        const text = String(expression === undefined || expression === null ? "" : expression).trim();
        if (text === "")
            return false;

        try {
            Hyprland.dispatch(text);
        } catch (e) {
            // Fallback via hyprctl
            runHyprctl(["dispatch", text]);
        }
        return true;
    }

    function focusWorkspace(workspace) {
        runHyprctl(["dispatch", "workspace", String(workspace)]);
        return dispatchExpression("hl.dsp.focus({ workspace = " + workspaceExpression(workspace) + " })");
    }

    function moveWindowToWorkspace(address, workspace, follow) {
        const selector = windowSelector(address);
        if (selector === "")
            return false;

        runHyprctl(["dispatch", "movetoworkspacesilent", String(workspace) + "," + selector]);
        return dispatchExpression("hl.dsp.window.move({ workspace = "
            + workspaceExpression(workspace)
            + ", follow = " + (follow ? "true" : "false")
            + ", window = " + luaString(selector)
            + " })");
    }

    function moveWindowToPosition(address, x, y, relative) {
        const selector = windowSelector(address);
        if (selector === "")
            return false;

        runHyprctl(["dispatch", "movewindowpixel", "exact " + numberExpression(x) + " " + numberExpression(y) + "," + selector]);
        return dispatchExpression("hl.dsp.window.move({ x = "
            + numberExpression(x)
            + ", y = " + numberExpression(y)
            + ", relative = " + (relative ? "true" : "false")
            + ", window = " + luaString(selector)
            + " })");
    }

    function focusWindow(address) {
        const selector = windowSelector(address);
        if (selector === "")
            return false;

        runHyprctl(["dispatch", "focuswindow", selector]);
        return dispatchExpression("hl.dsp.focus({ window = " + luaString(selector) + " })");
    }

    function closeWindow(address) {
        const selector = windowSelector(address);
        if (selector === "")
            return false;

        runHyprctl(["dispatch", "closewindow", selector]);
        return dispatchExpression("hl.dsp.window.close({ window = " + luaString(selector) + " })");
    }
}
