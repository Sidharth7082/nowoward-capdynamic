import QtQuick
import QtQuick.Controls
import "../services"
import "../theme"

Item {
    id: root

    anchors.fill: parent

    property string currentCategory: "Smileys & Emotion"
    property string searchText: ""

    property var categoryIcons: ({
        "Recent": "🕒",
        "Smileys & Emotion": "😃",
        "People & Body": "👋",
        "Animals & Nature": "🐶",
        "Food & Drink": "🍔",
        "Travel & Places": "🚀",
        "Activities": "⚽",
        "Objects": "💡",
        "Symbols": "🔣",
        "Flags": "🚩"
    })

    property var filteredEmojis: {
        const dummy = EmojiService.count;
        const query = root.searchText.trim().toLowerCase();
        if (query.length > 0) {
            return EmojiService.allEmojis.filter(e => e.name && e.name.toLowerCase().includes(query)).slice(0, 120);
        }
        if (root.currentCategory === "Recent") {
            return EmojiService.recentEmojis;
        }
        return EmojiService.allEmojis.filter(e => e.category === root.currentCategory || (e.category && e.category.indexOf(root.currentCategory) >= 0)).slice(0, 150);
    }

    Column {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 8

        // ── 1. Top Bar: Search Box ──────────────────────────
        Rectangle {
            width: parent.width
            height: 36
            radius: 12
            color: "#181818"
            border.color: searchInput.activeFocus ? "#3b82f6" : "#33ffffff"
            border.width: 1

            Behavior on border.color { ColorAnimation { duration: 150 } }

            Row {
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 10
                spacing: 8

                Text {
                    text: "🔍"
                    font.pixelSize: 14
                    anchors.verticalCenter: parent.verticalCenter
                }

                TextInput {
                    id: searchInput
                    width: parent.width - 60
                    anchors.verticalCenter: parent.verticalCenter
                    color: Theme.text
                    font.pixelSize: 13
                    clip: true
                    onTextChanged: root.searchText = text

                    Text {
                        text: "Search 1800+ emojis..."
                        color: Theme.subtext
                        font.pixelSize: 13
                        visible: !parent.text && !parent.activeFocus
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                Text {
                    text: "✖"
                    font.pixelSize: 12
                    color: Theme.subtext
                    visible: searchInput.text.length > 0
                    anchors.verticalCenter: parent.verticalCenter
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: searchInput.text = ""
                    }
                }
            }
        }

        // ── 2. Category Tab Pill Bar ──────────────────────────────
        ListView {
            width: parent.width
            height: 32
            orientation: ListView.Horizontal
            spacing: 6
            clip: true

            model: EmojiService.categories

            delegate: Rectangle {
                required property string modelData

                width: catRow.implicitWidth + 16
                height: 30
                radius: 15
                color: root.currentCategory === modelData ? Colors.accent : "#1e1e1e"
                border.color: root.currentCategory === modelData ? "#60a5fa" : "#282828"
                border.width: 1

                scale: catArea.pressed ? 0.95 : (catArea.containsMouse ? 1.03 : 1.0)
                Behavior on scale { NumberAnimation { duration: 120 } }
                Behavior on color { ColorAnimation { duration: 150 } }

                Row {
                    id: catRow
                    anchors.centerIn: parent
                    spacing: 4

                    Text {
                        text: root.categoryIcons[modelData] || "😀"
                        font.pixelSize: 13
                    }
                    Text {
                        text: modelData.split(" ")[0]
                        color: root.currentCategory === modelData ? "#ffffff" : Theme.subtext
                        font.pixelSize: 11
                        font.weight: root.currentCategory === modelData ? Font.Bold : Font.Normal
                    }
                }

                MouseArea {
                    id: catArea
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    onClicked: {
                        root.currentCategory = modelData;
                        searchInput.text = "";
                    }
                }
            }
        }

        // ── 3. Emoji Grid View ──────────────────────────────────
        GridView {
            id: grid
            width: parent.width
            height: parent.height - 84
            cellWidth: 54
            cellHeight: 54
            clip: true

            model: root.filteredEmojis

            delegate: Item {
                width: 54
                height: 54

                Rectangle {
                    id: emojiCard
                    anchors.centerIn: parent
                    width: 44
                    height: 44
                    radius: 12
                    color: itemArea.containsMouse ? "#33ffffff" : "#141414"
                    border.color: itemArea.containsMouse ? "#60a5fa" : "#22ffffff"
                    border.width: itemArea.containsMouse ? 1 : 0

                    scale: itemArea.pressed ? 0.88 : (itemArea.containsMouse ? 1.25 : 1.0)
                    z: itemArea.containsMouse ? 10 : 1

                    Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
                    Behavior on color { ColorAnimation { duration: 150 } }

                    Text {
                        anchors.centerIn: parent
                        text: modelData.emoji
                        font.pixelSize: 24
                    }

                    MouseArea {
                        id: itemArea
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        hoverEnabled: true
                        onClicked: {
                            EmojiService.copyEmoji(modelData.emoji, modelData.name);
                        }
                    }
                }
            }
        }
    }
}
