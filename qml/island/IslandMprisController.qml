import QtQuick
import Quickshell.Services.Mpris

// Picks whichever MPRIS player should be "active" (prefers one that's
// currently playing, otherwise sticks with the last one, otherwise the
// first player Quickshell reports) and exposes a flat, UI-friendly API.
// Works with any app that registers an MPRIS interface: Spotify, Brave
// (media playing in a tab), mpv, VLC, etc. — nothing app-specific here.
Item {
    id: root

    property var activePlayer: null
    readonly property bool hasPlayer: activePlayer !== null

    readonly property string title: activePlayer ? (activePlayer.trackTitle || "") : ""
    readonly property string artist: activePlayer ? (activePlayer.trackArtist || "") : ""
    readonly property string artUrl: activePlayer ? (activePlayer.trackArtUrl || "") : ""
    readonly property string sourceApp: activePlayer ? (activePlayer.identity || "") : ""
    readonly property bool playing: activePlayer
        ? activePlayer.playbackState === MprisPlaybackState.Playing
        : false
    readonly property bool canGoNext: activePlayer ? !!activePlayer.canGoNext : false
    readonly property bool canGoPrevious: activePlayer ? !!activePlayer.canGoPrevious : false

    // Forces position/length to re-read every tick even if the backend
    // doesn't emit change notifications for them.
    property int _tick: 0
    readonly property real position: {
        _tick;
        return (activePlayer && activePlayer.positionSupported) ? activePlayer.position : 0;
    }
    readonly property real length: {
        _tick;
        return activePlayer ? activePlayer.length : 0;
    }

    function refreshActivePlayer() {
        const list = Mpris.players.values;
        if (!list || list.length === 0) {
            activePlayer = null;
            return;
        }

        for (let i = 0; i < list.length; i++) {
            if (list[i].playbackState === MprisPlaybackState.Playing) {
                activePlayer = list[i];
                return;
            }
        }

        if (activePlayer && list.indexOf(activePlayer) !== -1)
            return; // keep the current pick (paused) if it's still around

        activePlayer = list[0];
    }

    function playPause() {
        if (!activePlayer) return;
        if (activePlayer.playbackState === MprisPlaybackState.Playing)
            activePlayer.pause();
        else
            activePlayer.play();
    }

    function next() {
        if (activePlayer && activePlayer.canGoNext) activePlayer.next();
    }

    function previous() {
        if (activePlayer && activePlayer.canGoPrevious) activePlayer.previous();
    }

    Connections {
        target: Mpris.players
        function onValuesChanged() { root.refreshActivePlayer(); }
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: {
            root.refreshActivePlayer();
            root._tick++;
        }
    }

    Component.onCompleted: refreshActivePlayer()
}
