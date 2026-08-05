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

    // ---- metadata passthroughs ----
    readonly property string title: activePlayer ? (activePlayer.trackTitle || "") : ""
    readonly property string artist: activePlayer ? (activePlayer.trackArtist || "") : ""
    readonly property string album: activePlayer ? (activePlayer.trackAlbum || "") : ""
    readonly property string artUrl: activePlayer ? (activePlayer.trackArtUrl || "") : ""
    readonly property string sourceApp: activePlayer ? (activePlayer.identity || "") : ""
    readonly property bool playing: activePlayer
        ? activePlayer.playbackState === MprisPlaybackState.Playing
        : false
    readonly property bool paused: activePlayer
        ? activePlayer.playbackState === MprisPlaybackState.Paused
        : false

    // ---- capability passthroughs ----
    readonly property bool canControl: activePlayer ? !!activePlayer.canControl : false
    readonly property bool canPlay: activePlayer ? !!activePlayer.canPlay : false
    readonly property bool canPause: activePlayer ? !!activePlayer.canPause : false
    readonly property bool canTogglePlaying: activePlayer ? !!activePlayer.canTogglePlaying : false
    readonly property bool canGoNext: activePlayer ? !!activePlayer.canGoNext : false
    readonly property bool canGoPrevious: activePlayer ? !!activePlayer.canGoPrevious : false
    readonly property bool canSeek: activePlayer ? (!!activePlayer.canSeek && !!activePlayer.positionSupported) : false
    readonly property bool shuffleSupported: activePlayer ? !!activePlayer.shuffleSupported : false
    readonly property bool loopSupported: activePlayer ? !!activePlayer.loopSupported : false
    readonly property bool shuffle: activePlayer ? !!activePlayer.shuffle : false
    readonly property int loopState: activePlayer ? activePlayer.loopState : MprisLoopState.None

    // Emitted whenever the currently playing track changes (title/artist/album/
    // app key differs), used by the island to auto-peek the music page.
    signal trackChanged()

    property bool _ready: false
    property string _lastTrackKey: ""
    function _trackKey() {
        return root.title + "\x1e" + root.artist + "\x1e" + root.album + "\x1e" + root.sourceApp;
    }

    onTitleChanged: root._checkTrackChange()
    onArtistChanged: root._checkTrackChange()
    onAlbumChanged: root._checkTrackChange()
    onSourceAppChanged: root._checkTrackChange()

    function _checkTrackChange() {
        // Ignore the initial population of properties at startup/player switch;
        // only real changes after the controller is primed emit trackChanged.
        if (!root._ready) return;
        const key = root._trackKey();
        if (key !== root._lastTrackKey) {
            root._lastTrackKey = key;
            if (root.playing)
                root.trackChanged();
        }
    }

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

        let pick = null;
        for (let i = 0; i < list.length; i++) {
            if (list[i].playbackState === MprisPlaybackState.Playing) {
                pick = list[i];
                break;
            }
        }

        if (!pick) {
            // Keep the current (paused) pick if it's still around.
            if (list.indexOf(root.activePlayer) !== -1)
                return;
            pick = list[0];
        }

        // Suppress the property-change handlers that fire while the active
        // player is (re)assigned, then re-prime so only real track changes
        // (not the initial population) emit trackChanged.
        root._ready = false;
        activePlayer = pick;
        root._lastTrackKey = root._trackKey();
        root._ready = true;
    }

    // ---- transport control ----

    function playPause() {
        if (!activePlayer || !root.canControl) return;
        if (root.canTogglePlaying && activePlayer.togglePlaying) {
            activePlayer.togglePlaying();
        } else if (root.playing) {
            if (root.canPause && activePlayer.pause) activePlayer.pause();
        } else {
            if (root.canPlay && activePlayer.play) activePlayer.play();
        }
    }

    function play() {
        if (!activePlayer || !root.canControl || !root.canPlay) return;
        if (activePlayer.play) activePlayer.play();
    }

    function pause() {
        if (!activePlayer || !root.canControl || !root.canPause) return;
        if (activePlayer.pause) activePlayer.pause();
    }

    function next() {
        if (activePlayer && root.canGoNext && activePlayer.next)
            activePlayer.next();
    }

    function previous() {
        if (activePlayer && root.canGoPrevious && activePlayer.previous)
            activePlayer.previous();
    }

    // ---- seeking ----

    function seekTo(seconds) {
        if (!activePlayer || !root.canSeek) return;
        let t = seconds;
        if (root.length > 0)
            t = Math.min(Math.max(0, t), root.length);
        try { activePlayer.position = t; } catch (e) { /* player rejected seek */ }
    }

    function seekToFraction(fraction) {
        if (root.length > 0)
            root.seekTo(root.length * Math.min(Math.max(0, fraction), 1));
    }

    function seekRelative(offsetSeconds) {
        // Quickshell's seek() takes seconds (like position/length).
        if (!activePlayer || !root.canSeek || !activePlayer.seek) return;
        try { activePlayer.seek(offsetSeconds); } catch (e) { /* rejected */ }
    }

    // ---- shuffle / loop ----

    function toggleShuffle() {
        if (!activePlayer || !root.shuffleSupported) return;
        activePlayer.shuffle = !root.shuffle;
    }

    function cycleLoop() {
        if (!activePlayer || !root.loopSupported) return;
        const states = [MprisLoopState.None, MprisLoopState.Track, MprisLoopState.Playlist];
        const idx = states.indexOf(root.loopState);
        activePlayer.loopState = states[(idx + 1) % states.length];
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
