# nowoward-capdynamic

A sleek, macOS-inspired **Dynamic Island** widget and **Cover-Flow Wallpaper Picker** built for **Hyprland (Wayland)** using **Quickshell + QML**.

---

## ⚡ One-Line Install & Launch

Run this single command in your terminal to download dependencies (Arch/AUR), clone, and launch immediately:

```bash
git clone https://github.com/Sidharth7082/nowoward-capdynamic.git ~/.config/quickshell/nowoward-capdynamic && quickshell -p ~/.config/quickshell/nowoward-capdynamic
```

---

## ✨ Features

- **🏝️ Dynamic Island**:
  - **Clock & Date Page**: Minimal clock pill that reveals on hover and expands on click.
  - **Live MPRIS Media Player**: Controls Spotify, Brave, mpv, or any MPRIS player with animated visualizer bars.
  - **Control Center & System Monitor**: Real-time CPU %, RAM %, Battery %, interactive Brightness & Volume sliders, plus Wi-Fi & Bluetooth toggles.
  - **DBus Notification Toasts**: Auto-peeks desktop alerts with app badges & text summaries.
  - **Volume Status Overlay**: Transient audio level indicator pill when volume changes.
  - **Top-Edge Hover Reveal**: Automatically stays hidden offscreen until your cursor touches the top edge of the monitor.
  - **Smart Auto-Hide**: Hides when windows are open to keep browser tabs and window titlebars 100% clear.
- **🖼️ Cover-Flow Wallpaper Picker**:
  - PathView cover-flow wallpaper browser over `~/Pictures/Wallpapers`.
  - Generates instant thumbnails via `ffmpeg` and applies wallpapers via `awww` or `mpvpaper`.

---

## 📦 Dependencies

### Required
- **Hyprland** (Wayland compositor)
- **[Quickshell](https://quickshell.org/)** (`quickshell` binary on PATH)
- **`ffmpeg`** (For thumbnail generation)
- **`awww`** (For applying static wallpapers)

### Recommended (For Control Center & Media Features)
- **`brightnessctl`** (Display brightness slider control)
- **`nmcli`** / **NetworkManager** (Wi-Fi status & toggle)
- **`bluetoothctl`** / **BlueZ** (Bluetooth status & toggle)
- **`wpctl`** / **WirePlumber** (Audio volume slider & volume indicator overlay)
- **`mpvpaper`** (Optional: for animated/video wallpapers)

#### Install Dependencies on Arch Linux:
```bash
# Core dependencies
sudo pacman -S quickshell ffmpeg networkmanager bluez bluez-utils brightnessctl wireplumber

# Wallpaper backend (AUR)
yay -S awww mpvpaper
```

---

## 🛠️ Detailed Step-by-Step Setup

### Step 1: Clone the Repository
Clone the project into your user config folder:

```bash
git clone https://github.com/Sidharth7082/nowoward-capdynamic.git ~/.config/quickshell/nowoward-capdynamic
```

### Step 2: Prepare Wallpapers Folder
Create the wallpapers directory and add your wallpaper images (`.png`, `.jpg`, `.webp`, `.mp4`):

```bash
mkdir -p ~/Pictures/Wallpapers
```

### Step 3: Run the Widget
Launch the shell:

```bash
quickshell -p ~/.config/quickshell/nowoward-capdynamic
```

### Step 4: Configure Hyprland Auto-Start & Keybindings
Add these lines to your `~/.config/hypr/hyprland.conf`:

```conf
# Auto-start Dynamic Island on login
exec-once = quickshell -p ~/.config/quickshell/nowoward-capdynamic

# Keybindings
bind = SUPER, W, exec, quickshell ipc -p ~/.config/quickshell/nowoward-capdynamic call picker toggle
bind = SUPER, I, exec, quickshell ipc -p ~/.config/quickshell/nowoward-capdynamic call tide toggle
```

---

## 🎮 IPC Controls

You can control the island or wallpaper picker from any terminal script or keybind:

```bash
# Dynamic Island Page Controls
quickshell ipc -p ~/.config/quickshell/nowoward-capdynamic call tide toggle   # Toggle expand/collapse
quickshell ipc -p ~/.config/quickshell/nowoward-capdynamic call tide clock    # Jump to Clock page
quickshell ipc -p ~/.config/quickshell/nowoward-capdynamic call tide player   # Jump to Music Player page
quickshell ipc -p ~/.config/quickshell/nowoward-capdynamic call tide stats    # Jump to Control Center page

# Wallpaper Picker Controls
quickshell ipc -p ~/.config/quickshell/nowoward-capdynamic call picker toggle # Open/close wallpaper picker
quickshell ipc -p ~/.config/quickshell/nowoward-capdynamic call picker show   # Force show picker
quickshell ipc -p ~/.config/quickshell/nowoward-capdynamic call picker hide   # Force hide picker
```

---

## 📁 Project Architecture

```
shell.qml                              Entrypoint & IPC handlers ("tide" & "picker")
DynamicIslandWindow.qml                Island capsule geometry, animations, mask, hover reveal
qml/theme/
  Colors.qml                           Color palette definitions
  Theme.qml                            Geometry metrics & dimensions
qml/services/
  CpuService.qml                       CPU usage monitor (/proc/stat)
  MemService.qml                       RAM usage monitor (/proc/meminfo)
  BatteryService.qml                   Battery capacity monitor (/sys/class/power_supply)
  NotificationService.qml              DBus Notification server listener
  VolumeService.qml                    WirePlumber / PulseAudio volume control
  BrightnessService.qml                brightnessctl display brightness control
  NetworkService.qml                   NetworkManager Wi-Fi monitor & toggle
  BluetoothService.qml                 BlueZ Bluetooth monitor & toggle
qml/island/
  IslandClock.qml                      Clock tick source
  IslandMprisController.qml            MPRIS player state & transport
  MusicPlayerLayer.qml                 Music player page UI
  MusicVisualizer.qml                  Animated audio visualizer bars
  IslandSystemStats.qml                Control Center & System Monitor card UI
  IslandNotificationLayer.qml          DBus Notification toast UI
  IslandVolumeLayer.qml                Volume level overlay UI
qml/wallpaperpicker/
  WallpaperPickerPanel.qml             PathView cover-flow wallpaper picker
```
