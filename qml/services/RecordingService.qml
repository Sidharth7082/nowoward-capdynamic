pragma Singleton
import QtQuick
import Quickshell.Io

Item {
    id: root

    property bool isRecording: false

    Process {
        id: recorderCheckProcess
        // Match actual screen-recording processes only. Anchoring avoids false
        // positives like "obsidian", and bare "ffmpeg" is excluded because
        // Quickshell's own wallpaper-thumbnail generation uses ffmpeg.
        command: ["pgrep", "-f", "(^|/)wf-recorder( |$)|(^|/)obs( |$)|gpu-screen-recorder"]
        running: false
        onExited: (exitCode) => {
            root.isRecording = (exitCode === 0);
        }
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (!recorderCheckProcess.running)
                recorderCheckProcess.running = true;
        }
    }
}
