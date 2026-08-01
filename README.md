# nowoward-capdynamic

A Dynamic-Island-style widget for Hyprland (Wayland), built with Quickshell + QML. One shell process, two coordinated pieces:

- **The Island** — Clock pill that expands to show:
  - **Clock & Date page**
  - **Live MPRIS music player** (Spotify, Brave, mpv, etc.)
  - **System Monitor page** (Real-time CPU %, RAM %, and Battery gauges)
  - **Notification Toasts** (Auto-peeks DBus desktop notifications)
  - **Volume Status Pill** (Transient PipeWire volume overlay)
  - **Swipe navigation**: Drag left/right on the expanded capsule to cycle pages.
  - **Hover Reveal**: Hover over the pill to smoothly expand; move mouse away to auto-collapse after 1.5s.
  - **Smart Auto-Hide when Working**: Automatically slides offscreen when windows are open so it never blocks browser tabs or title bars. Hovering the top-center edge smoothly reveals it.
- **The Wallpaper Picker** — A PathView cover-flow picker over your `~/Pictures/Wallpapers`, toggled by keybind, that applies wallpapers via `awww`/`mpvpaper`.

They run in the **same process** and coordinate: opening the picker hides the island and suppresses auto-peeks.

## Requirements

- Hyprland (Wayland)
- [Quickshell](https://quickshell.org/) (`quickshell` on your PATH)
- `ffmpeg` — wallpaper thumbnail generation
- `awww` — applying static wallpapers
- `mpvpaper` — applying video/animated wallpapers (optional)

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
quickshell ipc -p /path/to/nowoward-capdynamic call tide toggle   # expand/collapse
quickshell ipc -p /path/to/nowoward-capdynamic call tide show     # force expand
quickshell ipc -p /path/to/nowoward-capdynamic call tide hide     # force collapse
quickshell ipc -p /path/to/nowoward-capdynamic call tide player   # jump to player page
quickshell ipc -p /path/to/nowoward-capdynamic call tide clock    # jump to clock page
quickshell ipc -p /path/to/nowoward-capdynamic call tide stats    # jump to stats page

# Wallpaper picker
quickshell ipc -p /path/to/nowoward-capdynamic call picker toggle
quickshell ipc -p /path/to/nowoward-capdynamic call picker show
quickshell ipc -p /path/to/nowoward-capdynamic call picker hide
```

Bind keybindings in `hyprland.conf`:

```conf
bind = SUPER, W, exec, quickshell ipc -p /path/to/nowoward-capdynamic call picker toggle
bind = SUPER, I, exec, quickshell ipc -p /path/to/nowoward-capdynamic call tide toggle
```

## Structure

```
shell.qml                              Entrypoint & IPC handlers for "tide" and "picker"
DynamicIslandWindow.qml                Island capsule geometry, animations, mask, hover reveal, smart auto-hide
qml/theme/
  Colors.qml                           Color palette definition
  Theme.qml                            Centralized geometry metrics
qml/services/
  CpuService.qml                       /proc/stat CPU monitor
  MemService.qml                       /proc/meminfo RAM monitor
  BatteryService.qml                   /sys/class/power_supply Battery monitor
  NotificationService.qml              DBus Notification server
  VolumeService.qml                    PipeWire / PulseAudio volume listener
qml/island/
  IslandClock.qml                      Clock/date tick source
  IslandMprisController.qml            MPRIS music state + transport
  MusicPlayerLayer.qml                 Music player page UI
  MusicVisualizer.qml                  Animated visualizer bars
  IslandSystemStats.qml                System monitor gauge UI
  IslandNotificationLayer.qml          Notification toast alert UI
  IslandVolumeLayer.qml                Volume indicator UI
qml/wallpaperpicker/
  WallpaperPickerPanel.qml             Cover-flow wallpaper picker
```
