pragma Singleton
import QtQuick
import Quickshell.Io

Item {
    id: root

    property bool isRecording: false

    Process {
        id: recorderCheckProcess
        command: ["pgrep", "-f", "wf-recorder|obs|gpu-screen-recorder|ffmpeg"]
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
