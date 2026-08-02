pragma Singleton
import QtQuick
import Quickshell.Io

QtObject {
    id: root

    property string jsonPath: (os.getenv("HOME") or "/home/capture") + "/Downloads/nowoward-capdynamic/assets/emojis.json"
    property var allEmojis: []
    property int count: 0
    property var categories: ["Recent", "Smileys & Emotion", "People & Body", "Animals & Nature", "Food & Drink", "Travel & Places", "Activities", "Objects", "Symbols", "Flags"]
    property var recentEmojis: []

    property var _loaderProc: Process {
        command: ["sh", "-c", "cat " + root.jsonPath + " 2>/dev/null || cat ~/.config/quickshell/nowoward-capdynamic/assets/emojis.json 2>/dev/null"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: root._parseJson(text)
        }
    }

    property var _initTimer: Timer {
        interval: 50
        running: true
        repeat: false
        onTriggered: {
            root._loaderProc.running = false
            root._loaderProc.running = true
        }
    }

    property var _copyProc: Process {
        id: copyProc
    }

    function copyEmoji(emojiChar, emojiName) {
        if (!emojiChar) return;
        copyProc.running = false;
        copyProc.command = ["wl-copy", emojiChar];
        copyProc.running = true;

        // Push confirmation notification peek
        NotificationService.pushCustom({
            appName: "Emoji",
            summary: "📋 Copied " + emojiChar + " to Clipboard",
            body: emojiName || "Ready to paste (Ctrl+V)"
        });

        // Add to recent list
        let updated = [ { emoji: emojiChar, name: emojiName, category: "Recent" } ];
        for (let i = 0; i < root.recentEmojis.length; i++) {
            const item = root.recentEmojis[i];
            if (item.emoji !== emojiChar && updated.length < 20) {
                updated.push(item);
            }
        }
        root.recentEmojis = updated;
    }

    function _parseJson(text) {
        if (!text) return;
        try {
            const data = JSON.parse(text);
            if (data && data.emojis && Array.isArray(data.emojis)) {
                root.allEmojis = data.emojis;
                root.count = data.emojis.length;
            }
        } catch (e) {
            // Ignore parse error
        }
    }
}
