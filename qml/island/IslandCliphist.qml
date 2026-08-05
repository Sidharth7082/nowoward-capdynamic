//
// qml/island/IslandCliphist.qml
// Cliphist Clipboard Manager page embedded inside Dynamic Island
//

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../theme"

Item {
    id: root

    anchors.fill: parent
    focus: true

    signal closeRequested()
    signal userActivity()

    property int selectedIndex: 0
    property var entries: [] // list of { id, label, imagePath }
    property string searchQuery: ""
    property string deletingId: ""
    property string collapsingId: ""
    property var filteredEntries: searchQuery.length === 0
        ? entries
        : entries.filter(e => e.label.toLowerCase().includes(searchQuery.toLowerCase()))

    onFilteredEntriesChanged: {
        selectedIndex = 0;
    }

    function focusInput() {
        refresh();
        searchQuery = "";
        if (searchInput) {
            searchInput.text = "";
            searchInput.forceActiveFocus();
        }
    }

    onVisibleChanged: {
        if (visible) {
            focusInput();
        }
    }

    property string scriptPath: String(Qt.resolvedUrl("../../scripts/cliphist-img.sh")).replace("file://", "")

    function refresh() {
        listProc.running = false;
        listCountProc.running = false;
        Qt.callLater(() => {
            listProc.running = true;
            listCountProc.running = true;
        });
    }

    function copySelected() {
        if (filteredEntries.length === 0) return;
        let entry = filteredEntries[selectedIndex];
        Quickshell.execDetached(["sh", "-c", "cliphist decode \"" + entry.id + "\" | wl-copy"]);
        root.closeRequested();
    }

    function deleteSelected() {
        if (filteredEntries.length === 0) return;
        let entry = filteredEntries[selectedIndex];
        root.deletingId = entry.id;
        Quickshell.execDetached(["sh", "-c", "printf '%s\\t' \"" + entry.id + "\" | cliphist delete"]);
        holdRedTimer.entryId = entry.id;
        holdRedTimer.restart();
    }

    Keys.onPressed: (event) => {
        if (event.key === Qt.Key_Escape) {
            event.accepted = true;
            root.closeRequested();
        }
    }

    Timer {
        id: holdRedTimer
        property string entryId: ""
        interval: 160
        repeat: false
        onTriggered: {
            root.collapsingId = entryId;
            removeTimer.entryId = entryId;
            removeTimer.restart();
        }
    }

    Timer {
        id: removeTimer
        property string entryId: ""
        interval: 220
        repeat: false
        onTriggered: {
            let currentIdx = root.selectedIndex;
            let savedContentY = listView.contentY;
            root.entries = root.entries.filter(e => e.id !== entryId);
            root.deletingId = "";
            root.collapsingId = "";
            let newLength = filteredEntries.length;
            if (newLength === 0) selectedIndex = -1;
            else if (currentIdx >= newLength) selectedIndex = newLength - 1;
            else selectedIndex = currentIdx;
            Qt.callLater(() => {
                let maxY = Math.max(0, listView.contentHeight - listView.height);
                listView.contentY = Math.min(savedContentY, maxY);
            });
        }
    }

    Process {
        id: listProc
        command: ["bash", "-c", root.scriptPath]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                let lines = this.text.split("\n").filter(l => l.length > 0);
                root.entries = lines.map(line => {
                    let tabIdx = line.indexOf("\t");
                    if (tabIdx === -1) return { id: "0", label: line, imagePath: "" };
                    let id = line.substring(0, tabIdx);
                    let rest = line.substring(tabIdx + 1);

                    let nullIdx = rest.indexOf("\x00");
                    if (nullIdx !== -1) {
                        let label = rest.substring(0, nullIdx);
                        let iconPart = rest.substring(nullIdx + 1);
                        let imgPath = iconPart.split("\x1f")[1] || "";
                        return { id: id, label: label, imagePath: imgPath };
                    }

                    return { id: id, label: rest, imagePath: "" };
                });
            }
        }
    }

    Process {
        id: listCountProc
        command: ["sh", "-c", "cliphist list | wc -l"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                listCountText.total = parseInt(this.text.trim()) || 0;
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 10
        clip: true

        RowLayout {
            Layout.fillWidth: true

            Text {
                text: "Clipboard History"
                color: Theme.text
                font { pixelSize: 13; weight: Font.Bold }
                Layout.alignment: Qt.AlignLeft
            }

            Item { Layout.fillWidth: true }

            Text {
                id: listCountText
                property int total: 0
                text: (root.filteredEntries.length === 0 ? 0 : root.selectedIndex + 1)
                       + " / " + root.filteredEntries.length + " (" + total + ")"
                color: Theme.subtext
                font { pixelSize: 10; weight: Font.Normal }
                Layout.alignment: Qt.AlignRight
            }
        }

        // Search Input Box
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 28
            radius: 8
            color: Theme.isMyGlass ? "#25ffffff" : "#282832"
            border.color: searchInput.activeFocus ? Colors.accent : "#3a3a42"
            border.width: 1

            TextInput {
                id: searchInput
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 10
                verticalAlignment: TextInput.AlignVCenter
                color: Theme.text
                font { pixelSize: 11 }
                clip: true
                focus: true

                onTextChanged: {
                    root.searchQuery = text;
                    root.userActivity();
                }

                Text {
                    text: "search clips..."
                    color: Theme.muted
                    font: searchInput.font
                    visible: searchInput.text.length === 0
                    anchors.verticalCenter: parent.verticalCenter
                }

                Keys.onPressed: (event) => {
                    root.userActivity();
                    if (event.key === Qt.Key_Down) {
                        if (root.filteredEntries.length > 0) {
                            root.selectedIndex = (root.selectedIndex + 1) % root.filteredEntries.length;
                        }
                        listView.positionViewAtIndex(root.selectedIndex, ListView.Contain);
                        event.accepted = true;
                    } else if (event.key === Qt.Key_Up) {
                        if (root.filteredEntries.length > 0)
                            root.selectedIndex = root.selectedIndex <= 0
                                ? root.filteredEntries.length - 1
                                : root.selectedIndex - 1;
                        listView.positionViewAtIndex(root.selectedIndex, ListView.Contain);
                        event.accepted = true;
                    } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                        root.copySelected();
                        event.accepted = true;
                    } else if (event.key === Qt.Key_Escape) {
                        event.accepted = true;
                        root.closeRequested();
                    } else if (event.key === Qt.Key_Delete) {
                        root.deleteSelected();
                        event.accepted = true;
                    }
                }
            }
        }

        ListView {
            id: listView
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            model: root.filteredEntries
            currentIndex: root.selectedIndex
            highlightFollowsCurrentItem: false
            highlightMoveDuration: 80

            removeDisplaced: Transition { NumberAnimation { properties: "y"; duration: 150; easing.type: Easing.OutCubic } }

            delegate: Rectangle {
                width: listView.width
                height: modelData.id === root.collapsingId ? 5 : (modelData.imagePath ? 60 : 34)
                radius: 8
                color: modelData.id === root.deletingId ? Colors.danger : (index === root.selectedIndex ? (Theme.isMyGlass ? "#33ffffff" : "#33333d") : "transparent")
                clip: true
                opacity: modelData.id === root.collapsingId ? 0 : 1
                scale: modelData.id === root.collapsingId ? 0.75 : 1

                Behavior on height { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
                Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

                // Image Preview Container
                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 4
                    visible: modelData.imagePath !== ""
                    color: "#18181f"
                    radius: 6
                    clip: true

                    Image {
                        anchors.fill: parent
                        anchors.margins: 2
                        source: modelData.imagePath ? ("file://" + modelData.imagePath) : ""
                        fillMode: Image.PreserveAspectFit
                        asynchronous: true
                        sourceSize: Qt.size(100, 55)
                    }
                }

                // Text Label
                Text {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.leftMargin: 12
                    anchors.rightMargin: 10
                    text: modelData.label
                    visible: !modelData.imagePath
                    color: Theme.text
                    font { pixelSize: 11 }
                    elide: Text.ElideRight
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        root.selectedIndex = index;
                        root.copySelected();
                    }
                }
            }
        }
    }
}
