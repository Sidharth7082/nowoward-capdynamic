<div align="center">

# ❓ Frequently Asked Questions (FAQ) & Guide

### **Comprehensive FAQ for nowoward-capdynamic**
*Find quick answers to common setup, keybindings, MyGlass liquid glass mode, wlogout theme, and troubleshooting questions.*

</div>

---

## 📌 Table of Contents
1. [🟢 Basic Setup & General Questions](#-basic-setup--general-questions)
2. [🧊 MyGlass & Liquid Glass Mode](#-myglass--liquid-glass-mode)
3. [🚪 WLogout & Power Management](#-wlogout--power-management)
4. [🖼️ Cover-Flow Wallpaper Picker](#%EF%B8%8F-cover-flow-wallpaper-picker)
5. [🎮 Terminal IPC Command Reference](#-terminal-ipc-command-reference)
6. [🛠️ Troubleshooting](#%EF%B8%8F-troubleshooting)

---

## 🟢 Basic Setup & General Questions

### Q1: What is `nowoward-capdynamic`?
**A:** `nowoward-capdynamic` is an Apple-inspired **Dynamic Island & Cover-Flow Wallpaper Picker** built specifically for **Hyprland** using **Quickshell + QML**. It features smooth `OutBack` spring physics, live MPRIS audio visualizers, interactive Control Center cards, DBus notification popups, top-edge cursor sensors, and a standalone top WLogout panel.

### Q2: Will `nowoward-capdynamic` work without MyGlass?
**A:** **YES! 100% standalone!**  
`nowoward-capdynamic` runs completely independently on Hyprland using pure Quickshell QML.
* **Without MyGlass:** Renders as a crisp, solid matte dark Apple-style capsule (`#f20d1117`) out of the box.
* **With MyGlass:** Applies Apple-style liquid frosted glass shaders (refraction, specular glints, and backdrop blur).

### Q3: How do I install and launch it in 30 seconds?
**A:** Copy and paste this single command into your terminal:
```bash
git clone https://github.com/Sidharth7082/nowoward-capdynamic.git ~/.config/quickshell/nowoward-capdynamic && quickshell -p ~/.config/quickshell/nowoward-capdynamic
```

### Q4: How do I make it autostart every time Hyprland boots?
**A:** Add 1 line to your Hyprland configuration file:

* **Lua Setup (`~/.config/hypr/module/autostart.lua`):**
  ```lua
  hl.on("hyprland.start", function ()
      hl.exec_cmd("quickshell -p ~/.config/quickshell/nowoward-capdynamic &")
  end)
  ```
* **Legacy Setup (`~/.config/hypr/hyprland.conf`):**
  ```ini
  exec-once = quickshell -p ~/.config/quickshell/nowoward-capdynamic
  ```

---

## 🧊 MyGlass & Liquid Glass Mode

### Q5: How do I switch between MyGlass (Liquid Glass) and Default Dark Mode?
**A:** Press **`SUPER + SHIFT + G`** on your keyboard at any time!
* **Press once:** Switches to **Default Dark Mode** (Solid dark matte pill `#f20d1117`).
* **Press again:** Switches to **MyGlass Mode** (Translucent liquid frosted glass).

### Q6: How do I configure Hyprland layer surface rules for MyGlass?
**A:** Add layer surface rules for all 3 project namespaces (`nowoward-capdynamic`, `nowoward-capdynamic-wallpaperpicker`, `nowoward-capdynamic-wlogout`):

* **Lua Setup (`~/.config/hypr/module/myglass.lua`):**
  ```lua
  if hl.plugin and hl.plugin.myglass then
      local hg = hl.plugin.myglass
      hg.config({
          enabled = true,
          default_theme = "dark",
          default_preset = "clear",
          tint_color = 0x00000000,
          glass_opacity = 0.09,
          blur_strength = 0.04,
      })

      hg.layer("nowoward-capdynamic", { preset = "clear" })
      hg.layer("nowoward-capdynamic-wallpaperpicker", { preset = "clear" })
      hg.layer("nowoward-capdynamic-wlogout", { preset = "clear" })
  end
  ```

* **Legacy Setup (`hyprland.conf`):**
  ```ini
  plugin:myglass {
      default_theme = dark
      default_preset = clear
      glass_opacity = 0.09
      blur_strength = 0.04

      layers {
          enabled = 1
          namespaces = nowoward-capdynamic, nowoward-capdynamic-wallpaperpicker, nowoward-capdynamic-wlogout
          preset = clear
      }
  }
  ```

---

## 🚪 WLogout & Power Management

### Q7: Why does clicking "Log Out" show SDDM?
**A:** **SDDM** (Simple Desktop Display Manager) is your Linux login screen. When you click **Log Out**, your current Hyprland desktop session exits completely, returning control to SDDM so you can either log back in, log in as a different user, or shut down.

### Q8: What does "Suspend" do, and why does the screen go dark?
**A:** **Suspend** (Sleep mode / Suspend-to-RAM) puts your PC into a low-power state:
1. Saves all your open windows, apps, and work into System RAM.
2. Turns off display power (screen goes dark), stops disk drives, and powers down CPU fans to conserve electricity.
3. Keeps a tiny trickle of power to RAM. Moving your mouse or pressing any key wakes up the PC almost instantly!

### Q9: How do I open and navigate the Logout Panel?
**A:** Press **`SUPER + L`** (or `SUPER + M`) to toggle the top logout panel.
* **Arrow Key Navigation:** Use **`←` / `→` / `↑` / `↓` / `Tab`** to move highlight, press **`Enter` / `Space`** to confirm.
* **Direct Hotkeys:**
  * **`L`** / `1` ➡️ Lock (`hyprlock`)
  * **`U`** / `2` ➡️ Suspend (`systemctl suspend`)
  * **`E`** / `3` ➡️ Log Out (`hyprctl dispatch exit`)
  * **`R`** / `4` ➡️ Reboot (`systemctl reboot`)
  * **`S`** / `5` ➡️ Power Off (`systemctl poweroff`)
  * **`Esc`** / `Q` ➡️ Close

---

## 🖼️ Cover-Flow Wallpaper Picker

### Q10: How do I open the Wallpaper Picker and apply wallpapers?
**A:** Press **`SUPER + SHIFT + W`** to open the Cover-Flow Wallpaper Picker.
1. Scroll through wallpapers using **`←` / `→` Arrow Keys** or **Mouse**.
2. Press **`Enter`** (or click the active center card) to set the wallpaper instantly.

### Q11: Where does the Wallpaper Picker scan for wallpapers?
**A:** By default, it scans `~/Pictures/Wallpapers` for image and video formats (`.jpg`, `.jpeg`, `.png`, `.webp`, `.gif`, `.mp4`, `.mkv`, `.webm`).

### Q12: Which wallpaper daemons are supported?
**A:** Automatic multi-backend support is included:
* **`awww`** (Default high-speed static wallpaper daemon)
* **`swww`** (Alternative static wallpaper daemon)
* **`hyprpaper`** (Native Hyprland wallpaper daemon)
* **`mpvpaper`** (Video wallpaper backend for `.mp4`/`.webm`)

---

## 🎮 Terminal IPC Command Reference

Control any component directly from scripts, Waybar buttons, or custom keybindings:

```bash
# Dynamic Island Controls
quickshell ipc -p ~/.config/quickshell/nowoward-capdynamic call island toggle
quickshell ipc -p ~/.config/quickshell/nowoward-capdynamic call island clock
quickshell ipc -p ~/.config/quickshell/nowoward-capdynamic call island player
quickshell ipc -p ~/.config/quickshell/nowoward-capdynamic call island stats
quickshell ipc -p ~/.config/quickshell/nowoward-capdynamic call island notifs
quickshell ipc -p ~/.config/quickshell/nowoward-capdynamic call island wifi
quickshell ipc -p ~/.config/quickshell/nowoward-capdynamic call island bluetooth
quickshell ipc -p ~/.config/quickshell/nowoward-capdynamic call island logout
quickshell ipc -p ~/.config/quickshell/nowoward-capdynamic call island emojis

# Mode Switcher (Default vs MyGlass)
quickshell ipc -p ~/.config/quickshell/nowoward-capdynamic call theme defaultMode
quickshell ipc -p ~/.config/quickshell/nowoward-capdynamic call theme glassMode
quickshell ipc -p ~/.config/quickshell/nowoward-capdynamic call theme toggle

# WLogout & Wallpaper Picker
quickshell ipc -p ~/.config/quickshell/nowoward-capdynamic call wlogout toggle
quickshell ipc -p ~/.config/quickshell/nowoward-capdynamic call picker toggle
```

---

## 🛠️ Troubleshooting

### Q13: Quickshell IPC says "No running instances"?
**A:** Check where your project folder is located. If running from Downloads, pass the exact path:
```bash
quickshell ipc -p ~/Downloads/nowoward-capdynamic call island toggle
```

### Q14: MyGlass is installed, but the island looks plain dark?
**A:** Ensure `hyprpm enable myglass` is run, and check that all 3 layer surface namespaces are added to `myglass.lua` / `hyprland.conf`. Run `hyprctl reload` to apply.
