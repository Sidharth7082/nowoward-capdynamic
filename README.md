# nowoward-capdynamic

A Dynamic-Island-style widget for Hyprland (Wayland), built with Quickshell +
QML. One shell process, two coordinated pieces:

- **The island** — clock pill that expands to show time/date, or a live
  MPRIS music player (works with Spotify, Brave, or any app exposing MPRIS).
  Swipe left/right on the expanded capsule to switch pages.
- **The wallpaper picker** — a PathView cover-flow picker over your
  `~/Pictures/Wallpapers`, toggled by keybind, that applies wallpapers via
  `awww`/`mpvpaper`.

They run in the **same process** and coordinate: opening the picker
collapses the island and suppresses its auto-peek (so a track starting
mid-picker doesn't pop the island open on top of it).

The island also **hides automatically** when a window on that monitor's
active workspace enters Hyprland fullscreen (games, fullscreen video, etc.),
and **collapses after 8 seconds of idle** when expanded (tap, swipe, or
transport controls reset the timer).

## Requirements

- Hyprland (Wayland)
- [Quickshell](https://quickshell.org/) (`quickshell` on your PATH), with
  `Quickshell.Services.Mpris` (standard in official builds)
- `ffmpeg` — wallpaper thumbnail generation
- `awww` — applying static wallpapers
- `mpvpaper` — applying video/animated wallpapers (optional, only needed if
  you use video wallpapers)

## Run it

```bash
quickshell -p /path/to/nowoward-capdynamic
```

Add to `hyprland.conf` to launch on login:

```conf
exec-once = quickshell -p /path/to/nowoward-capdynamic
```

## Control it

```bash
# Island
quickshell ipc call tide toggle   # expand/collapse
quickshell ipc call tide show     # force expand
quickshell ipc call tide hide     # force collapse
quickshell ipc call tide player   # jump to the music player page
quickshell ipc call tide clock    # jump to the clock page

# Wallpaper picker
quickshell ipc call picker toggle
quickshell ipc call picker show
quickshell ipc call picker hide
```

Bind the picker to a key in `hyprland.conf`:

```conf
bind = SUPER, W, exec, quickshell ipc call picker toggle
```

## Structure

```
shell.qml                              entry point: IPC handlers for both
                                        "tide" and "picker", island<->picker
                                        coordination
DynamicIslandWindow.qml                the island: capsule geometry,
                                        animation, mask, page switching,
                                        MPRIS auto-peek
qml/island/IslandClock.qml             ticking clock/date source
qml/island/IslandMprisController.qml   live MPRIS state + transport controls
qml/island/MusicPlayerLayer.qml        music player page UI
qml/island/MusicVisualizer.qml         animated visualizer bars
qml/wallpaperpicker/
  WallpaperPickerPanel.qml             embeddable wallpaper picker (scan,
                                        thumbnail, cover-flow, apply)
```

## Next steps

- Add `CompositorBackend` (C++) if you want workspace-aware behavior,
  auto-hide on fullscreen, etc.
- Add a notification layer.
- Package with a systemd user service once you're ready to distribute it.
