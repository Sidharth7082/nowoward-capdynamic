pragma Singleton
import QtQuick
import Quickshell.Io
import "EmojiData.js" as EmojiData

QtObject {
    id: root

    property var allEmojis: EmojiData.emojis || []
    property int count: (EmojiData.emojis || []).length
    property var categories: ["Recent", "Smileys & Emotion", "People & Body", "Animals & Nature", "Food & Drink", "Travel & Places", "Activities", "Objects", "Symbols", "Flags"]
    property var recentEmojis: []

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
}
