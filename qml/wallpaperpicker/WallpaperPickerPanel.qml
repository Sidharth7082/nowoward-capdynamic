//
// qml/wallpaperpicker/WallpaperPickerPanel.qml
//
// Same PathView cover-flow wallpaper picker, now embedded inside the main
// nowoward-capdynamic shell instead of running as its own `quickshell -c`
// instance. Toggling/show/hide is exposed as functions + a `shown`
// property so shell.qml can wire IPC and island coordination to it.
//

import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import QtQuick
import QtCore
import "../theme"

Item {
    id: root

    property string wallpaperDir: Quickshell.env("HOME") + "/Pictures/Wallpapers"
    property string cacheDir: localPath(StandardPaths.writableLocation(StandardPaths.GenericCacheLocation)) + "/quickshell/nowoward-capdynamic/wallpaper-picker"

    property bool shown: false
    property string activeWallpaper: ""
    readonly property var imageExts: ["jpg", "jpeg", "png", "webp", "gif", "JPG", "JPEG", "PNG", "WEBP", "GIF"]
    readonly property var videoExts: ["mp4", "mkv", "webm", "MP4", "MKV", "WEBM"]

    function localPath(v) {
        return v && v.toLocalFile ? v.toLocalFile() : String(v);
    }

    function toggle() {
        shown = !shown;
        if (wallpapers.count === 0) rescan();
    }
    function show() {
        shown = true;
        if (wallpapers.count === 0) rescan();
    }
    function hide() { shown = false; }

    ListModel { id: wallpapers }

    // ── Scan the wallpaper directory ─────────────────────────────────────
    function rescan() {
        scanBuffer = "";
        scanProcess.running = false;
        scanProcess.running = true;
    }

    property string scanBuffer: ""

    Process {
        id: scanProcess
        command: ["find", root.wallpaperDir, "-maxdepth", "1", "-type", "f"]
        stdout: SplitParser {
            onRead: function (line) { root.scanBuffer += line + "\n"; }
        }
        onExited: {
            const exts = root.imageExts.concat(root.videoExts);
            const list = root.scanBuffer.split("\n").filter(l => l.length > 0)
                .filter(p => exts.indexOf(p.substring(p.lastIndexOf(".") + 1)) >= 0)
                .sort((a, b) => a.localeCompare(b))
                .map(p => {
                    const ext = p.substring(p.lastIndexOf(".") + 1);
                    const fname = p.substring(p.lastIndexOf("/") + 1);
                    const isVid = root.videoExts.indexOf(ext) >= 0;
                    const cpath = root.cacheDir + "/" + fname + ".jpg";
                    return {
                        filePath: p,
                        fileName: fname,
                        isVideo: isVid,
                        cachePath: cpath,
                        thumbPath: "file://" + cpath,
                        thumbReady: true
                    };
                });

            wallpapers.clear();
            for (const w of list)
                wallpapers.append(w);

            if (wallpapers.count > 0) {
                carousel.currentIndex = 0;
            }

            bgThumbGen.running = false;
            bgThumbGen.running = true;
        }
    }

    // ── Parallel Thumbnail Generation Engine ──────────────────────────────
    property string genScript: String(Qt.resolvedUrl("../../scripts/gen_thumbs.sh")).replace("file://", "")

    Process {
        id: bgThumbGen
        command: [root.genScript, root.wallpaperDir, root.cacheDir]
    }

    Process {
        id: mkdirCache
        command: ["mkdir", "-p", root.cacheDir]
    }

    Component.onCompleted: {
        mkdirCache.running = true;
        root.rescan();
    }

    property var thumbQueue: []
    property bool thumbBusy: false

    function ensureThumbnail(index) {
        if (index < 0 || index >= wallpapers.count)
            return;

        const item = wallpapers.get(index);
        if (!item || item.thumbReady)
            return;

        if (thumbQueue.indexOf(index) !== -1)
            return;

        thumbQueue.push(index);
        pumpThumbQueue();
    }

    function pumpThumbQueue() {
        if (thumbBusy || thumbQueue.length === 0)
            return;

        thumbBusy = true;

        const idx = thumbQueue.shift();
        const item = wallpapers.get(idx);

        thumbProcess.targetIndex = idx;
        thumbProcess.command = [
            "ffmpeg",
            "-y",
            "-loglevel", "error",
            "-i", item.filePath,
            "-frames:v", "1",
            "-vf", "scale=320:-1",
            String(item.cachePath).replace("file://", "")
        ];

        thumbProcess.running = true;
    }

    Process {
        id: thumbProcess

        property int targetIndex: -1

        onExited: function(exitCode) {
            if (exitCode === 0 && targetIndex >= 0 && targetIndex < wallpapers.count) {
                wallpapers.setProperty(targetIndex, "thumbReady", true);
            }
            thumbBusy = false;
            pumpThumbQueue();
        }
    }

    // ── Apply wallpaper ────────────────────────────────────────────────
    Process { id: killMpvpaper; command: ["pkill", "-x", "mpvpaper"] }
    Process { id: applyImage }
    Process { id: applyVideo }

    function applyWallpaper(item) {
        if (!item || !item.filePath) return;
        root.activeWallpaper = item.filePath;

        killMpvpaper.running = false;
        killMpvpaper.running = true;

        if (item.isVideo) {
            applyVideo.running = false;
            applyVideo.command = ["mpvpaper", "-o", "--loop --mute", "*", item.filePath];
            applyVideo.running = true;
        } else {
            applyImage.running = false;
            applyImage.command = ["sh", "-c", "awww img \"$1\" --transition-type outer --transition-step 255 --transition-fps 144 || swww img \"$1\" || hyprctl hyprpaper wallpaper \",$1\"", "--", item.filePath];
            applyImage.running = true;
        }
    }

    // ── Layout constants ──────────────────────────────────────────────
    readonly property real hPad: 20
    readonly property real slotW: 1060 / 5
    readonly property real cardW: Math.round(slotW * 1.15)
    readonly property real cardH: Math.round(cardW * 0.58)
    readonly property real labelGap: 6
    readonly property real labelH: 18
    readonly property real sideScale: 0.78

    PanelWindow {
        id: win
        visible: root.shown

        anchors { top: true; left: true; right: true }

        margins.top: 24
        implicitWidth: 1100
        implicitHeight: 210

        color: "transparent"
        focusable: true

        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "nowoward-capdynamic-wallpaperpicker"
        WlrLayershell.keyboardFocus:
            root.shown ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

        Rectangle {
            id: panel
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            width: 1100
            height: 210
            radius: 20
            color: Theme.isMyGlass ? "#1a121216" : "#f20d1117"
            border.color: Theme.isMyGlass ? "#33ffffff" : "#50ffffff"
            border.width: 1

            Behavior on color {
                ColorAnimation { duration: 200 }
            }

            focus: root.shown
            Keys.onEscapePressed: root.hide()
            Keys.onLeftPressed: carousel.decrementCurrentIndex()
            Keys.onRightPressed: carousel.incrementCurrentIndex()
            Keys.onReturnPressed: {
                if (wallpapers.count > 0)
                    root.applyWallpaper(wallpapers.get(carousel.currentIndex));
            }

            Column {
                anchors.centerIn: parent
                spacing: 8
                visible: wallpapers.count === 0

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "Scanning…"
                    color: Qt.rgba(1, 1, 1, 0.35)
                    font.pixelSize: 12
                }
            }

            PathView {
                id: carousel
                anchors.fill: parent
                anchors.margins: 14
                model: root.shown ? wallpapers : null
                visible: wallpapers.count > 0
                clip: false

                pathItemCount: Math.min(wallpapers.count, 5)
                cacheItemCount: 4
                snapMode: PathView.SnapToItem
                preferredHighlightBegin: 0.5
                preferredHighlightEnd: 0.5
                highlightRangeMode: PathView.StrictlyEnforceRange
                highlightMoveDuration: 200

                path: Path {
                    startX: carousel.width / 2 - root.slotW * 2
                    startY: carousel.height / 2 - 10
                    PathLine {
                        x: carousel.width / 2 + root.slotW * 2
                        y: carousel.height / 2 - 10
                    }
                }

                delegate: Item {
                    id: del

                    readonly property bool isCurrent: PathView.isCurrentItem
                    readonly property bool onPath: PathView.onPath

                    width: root.cardW
                    height: root.cardH + root.labelGap + root.labelH
                    z: isCurrent ? 3 : 1

                    property real sc: isCurrent ? 1.0 : onPath ? root.sideScale : 0.0
                    Behavior on sc {
                        NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
                    }

                    property real op: isCurrent ? 1.0 : onPath ? 0.92 : 0.0
                    Behavior on op {
                        NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
                    }

                    Item {
                        id: inner
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.top: parent.top

                        width: root.cardW
                        height: root.cardH + root.labelGap + root.labelH

                        scale: del.sc
                        opacity: del.op
                        transformOrigin: Item.Center

                        ClippingRectangle {
                            id: thumb

                            anchors.top: parent.top
                            anchors.horizontalCenter: parent.horizontalCenter

                            width: root.cardW
                            height: root.cardH
                            radius: 14
                            color: "#0a0a0a"

                            Image {
                                id: imgCard
                                anchors.fill: parent

                                source: model.thumbPath

                                onStatusChanged: {
                                    if (status === Image.Error && source !== ("file://" + model.filePath)) {
                                        source = "file://" + model.filePath;
                                    }
                                }

                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                                cache: true
                                smooth: true
                                sourceSize: Qt.size(root.cardW * 2, root.cardH * 2)

                                Rectangle {
                                    anchors.fill: parent
                                    color: "#181818"
                                    opacity: parent.status === Image.Ready ? 0 : 1

                                    Behavior on opacity {
                                        NumberAnimation { duration: 200 }
                                    }
                                }
                            }

                            // Dark overlay to keep thumbnails rich, deep, and dark
                            Rectangle {
                                anchors.fill: parent
                                color: "#000000"
                                opacity: del.isCurrent ? 0.20 : 0.50
                                radius: 14

                                Behavior on opacity {
                                    NumberAnimation { duration: 150 }
                                }
                            }
                        }

                        Rectangle {
                            anchors.fill: thumb

                            radius: 14
                            color: "transparent"

                            border.width: model.filePath === root.activeWallpaper ? 2.5 : 0
                            border.color: "#60a5fa"

                            Behavior on border.width {
                                NumberAnimation { duration: 150 }
                            }
                        }

                        MouseArea {
                            anchors.fill: thumb
                            cursorShape: Qt.PointingHandCursor

                            onClicked: {
                                if (del.isCurrent)
                                    root.applyWallpaper(wallpapers.get(index))
                                else
                                    carousel.currentIndex = index
                            }
                        }

                        Text {
                            anchors.top: thumb.bottom
                            anchors.topMargin: root.labelGap
                            anchors.horizontalCenter: thumb.horizontalCenter

                            width: root.cardW - 4

                            text: model.fileName
                            color: del.isCurrent ? "white" : Qt.rgba(1, 1, 1, 0.5)

                            font.pixelSize: del.isCurrent ? 11 : 10
                            font.weight: del.isCurrent ? Font.Medium : Font.Normal

                            horizontalAlignment: Text.AlignHCenter
                            elide: Text.ElideMiddle

                            Behavior on color {
                                ColorAnimation { duration: 150 }
                            }
                        }
                    }
                }
            }
        }
    }
}
