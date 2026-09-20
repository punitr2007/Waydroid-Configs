<div align="center">

# 🚀 Waydroid-Configs

**The Ultimate High-Speed Toolkit, Fast Mirrors, Network Fixes & Media Controls for Waydroid on Linux**

[![Linux](https://img.shields.io/badge/Linux-Arch%20%7C%20Fedora%20%7C%20Debian%20%7C%20Ubuntu-blue?logo=linux&logoColor=white)](https://waydro.id)
[![Android](https://img.shields.io/badge/Android-LineageOS%2018.1%20%7C%2020.0-green?logo=android&logoColor=white)](https://lineageos.org)
[![Python](https://img.shields.io/badge/Python-3.10%2B-yellow?logo=python&logoColor=white)](https://python.org)
[![Wayland](https://img.shields.io/badge/Display-Wayland%20Native-orange?logo=wayland&logoColor=white)](https://wayland.freedesktop.org)
[![License](https://img.shields.io/badge/License-MIT-purple.svg)](./LICENSE)

*Bypass SourceForge download throttling, fix container internet issues with UFW/iptables, enable native/ARM app execution, bind global keyboard media keys, and keep your desktop app launcher clean.*

---

</div>

## 📌 Table of Contents
- [Why This Toolkit Exists](#-why-this-toolkit-exists)
- [Key Features](#-key-features)
- [Repository Structure](#-repository-structure)
- [Quick Start Installation](#-quick-start-installation)
- [Scripts & Tool Reference](#-scripts--tool-reference)
  - [1. Multi-Threaded Parallel Downloader](#1-multi-threaded-parallel-downloader)
  - [2. Preinstalled Image Registration](#2-preinstalled-image-registration)
  - [3. Complete Internet & Firewall Fix](#3-complete-internet--firewall-fix)
  - [4. Host Media Key Controller (Play/Pause, F4)](#4-host-media-key-controller-playpause-f4)
  - [5. Hide/Unhide Apps from Application Launcher](#5-hideunhide-apps-from-application-launcher)
  - [6. All-in-One Management Menu](#6-all-in-one-management-menu)
- [Desktop Keybinding Setup (KDE / GNOME / Hyprland)](#-desktop-keybinding-setup)
- [Native x86_64 vs ARM Translation](#-native-x86_64-vs-arm-translation)
- [Troubleshooting & FAQs](#-troubleshooting--faqs)
- [License](#-license)

---

## ⚡ Why This Toolkit Exists

If you have tried installing Waydroid via `waydroid init` or AUR packages (`waydroid-image-gapps`), you likely ran into:

1. **Extreme Download Throttling (`100–300 KB/s`)**: Waydroid's default installer uses single-threaded Python `urllib` to pull ~1.2 GB image archives from SourceForge.
2. **Cloudflare & 302 Redirect Pitfalls**: SourceForge redirect chains often return small HTML error pages when Range requests are sent directly to project landing pages, causing `zipfile.BadZipFile: File is not a zip file` errors.
3. **No Internet Inside Android Container**: On systems running **UFW** (Uncomplicated Firewall) or restrictive `iptables` policies, bridged packets from `waydroid0` are dropped by default.
4. **App Launcher Clutter**: Waydroid exports every Android app (Calculator, Camera, Settings, Chrome) into your host's application launcher, mixing them with your native Linux apps.
5. **No Native Host Media Key Integration**: Standard tools like `playerctl` cannot see media players running inside Waydroid containers.

**Waydroid-Configs solves all of these issues out of the box.**

---

## ✨ Key Features

* 🚀 **16-Thread HTTP Range Turbo Downloader**: Slices downloads into 12–16 parallel streams directly from verified high-speed CDN mirrors with live progress and SHA256 integrity verification.
* 📦 **Instant Preinstalled Registration**: Symlinks extracted `system.img` and `vendor.img` into `/etc/waydroid-extra/images/`, allowing `waydroid init -f` to complete in **1 second** with zero network calls.
* 🌐 **1-Click Network & Firewall Fix**: Automatically adds UFW forwarding routes, sets iptables NAT masquerading, sets Google DNS (`8.8.8.8` / `1.1.1.1`), and restarts the container service.
* 🧹 **Desktop App Launcher Cleaner**: 1-click tool to hide all Waydroid apps from your application menu, Kickoff, GNOME app grid, and KRunner search while keeping them accessible inside Waydroid.
* 🎵 **Instant Global Media Controller**: Dispatches Android `KEYCODE_MEDIA_PLAY_PAUSE` (85), Next (87), Previous (88), and Volume events via ADB in under **10ms** without sudo.
* 🎮 **ARM Translation Ready**: Integrated companion script to install `libndk` or `libhoudini` for running Android mobile games and ARM-only APKs on `x86_64`.
* 🔑 **Google Play Certification Helper**: Automatically retrieves your Google Services Framework (GSF) Android ID for registering on Google's Uncertified Device Portal.

---

## 📂 Repository Structure

```
.
├── fast_waydroid_downloader.py   # Multi-threaded parallel range downloader & image extractor
├── setup_waydroid.sh             # 1-click interactive installation and initialization wizard
├── fix_internet.sh               # Standalone UFW, iptables NAT, and Google DNS fixer
├── hide_apps.sh                  # Hides/unhides Waydroid apps from your desktop app menu
├── waydroid_media.sh             # Instant host-to-container media controller (Play/Pause, Next, Prev)
├── waydroid_tools.sh             # Interactive management menu (ARM translation, GSF ID, APK install)
├── DOWNLOAD_MIRRORS.md           # Direct mirror catalog, checksums, and aria2 commands
├── .gitignore                    # Prevents committing multi-gigabyte OS images or venvs
└── README.md                     # Comprehensive documentation
```

---

## 🚀 Quick Start Installation

### 1. Install Prerequisites
On **Arch Linux / Manjaro**:
```bash
sudo pacman -S waydroid adb curl
```

### 2. Clone the Repository
```bash
git clone https://github.com/punitr2007/Waydroid-Configs.git
cd Waydroid-Configs
```

### 3. Run the 1-Click Interactive Setup
```bash
./setup_waydroid.sh
```
This script will:
* Check kernel binder module support (`/dev/binderfs`).
* Download **GAPPS** (Google Play Store) or **VANILLA** (Pure AOSP) using 16 parallel connections.
* Verify SHA256 checksums and extract `system.img` and `vendor.img`.
* Register images with Waydroid and initialize the container.
* Enable and start `waydroid-container.service`.

### 4. Launch Waydroid
```bash
waydroid show-full-ui
```

---

## 🛠️ Scripts & Tool Reference

### 1. Multi-Threaded Parallel Downloader
Download images at your full ISP bandwidth:
```bash
# Download GAPPS (Google Play Store + LineageOS 20) with 16 connections
python3 fast_waydroid_downloader.py --type GAPPS --threads 16

# Download VANILLA (Pure LineageOS 20 without Google services)
python3 fast_waydroid_downloader.py --type VANILLA --threads 16

# Automatically register images and initialize Waydroid after downloading:
python3 fast_waydroid_downloader.py --type GAPPS --threads 16 --init
```

---

### 2. Preinstalled Image Registration
If you already have `system.img` and `vendor.img` downloaded:
```bash
# 1. Create the official preinstalled directory
sudo mkdir -p /etc/waydroid-extra/images

# 2. Symlink your downloaded images
sudo ln -sf "$(pwd)/images/system.img" /etc/waydroid-extra/images/system.img
sudo ln -sf "$(pwd)/images/vendor.img" /etc/waydroid-extra/images/vendor.img

# 3. Initialize Waydroid (instant 1-second init, 0 download)
sudo waydroid init -f
sudo systemctl enable --now waydroid-container
```

---

### 3. Complete Internet & Firewall Fix
If apps inside Android cannot access the internet:
```bash
./fix_internet.sh
```
What it does:
1. Configures **UFW** forwarding rules (`ufw route allow in on waydroid0`).
2. Configures **iptables** NAT masquerading for subnet `192.168.240.0/24`.
3. Sets persistent Google DNS (`8.8.8.8` and `1.1.1.1`) inside Android.
4. Restarts `waydroid-container.service`.

---

### 4. Host Media Key Controller (Play/Pause, F4)
Control Android music apps (BitChord, Spotify, YouTube Music, Apple Music) from your Linux host keyboard:

```bash
# Toggle Play / Pause (Android Keycode 85)
./waydroid_media.sh play-pause

# Next Track (Android Keycode 87)
./waydroid_media.sh next

# Previous Track (Android Keycode 88)
./waydroid_media.sh prev

# Volume Control
./waydroid_media.sh vol-up
./waydroid_media.sh vol-down
```

---

### 5. Hide/Unhide Apps from Application Launcher
Prevent Waydroid apps (Calculator, Camera, Settings, etc.) from cluttering your desktop application menu:

```bash
# Hide all Waydroid apps from the launcher
./hide_apps.sh hide

# Unhide / Restore them in the launcher
./hide_apps.sh unhide

# Check visibility status
./hide_apps.sh status
```

---

### 6. All-in-One Management Menu
Run the post-install management hub:
```bash
./waydroid_tools.sh
```
Options available:
* `1)` Launch Full-Screen UI
* `2)` Start Session in background
* `3)` Stop Session & Container
* `4)` Apply Network & DNS Fixes
* `5)` Get Google Play Device ID (for Google Play Certification)
* `6)` Install ARM Translation (`libndk` / `libhoudini`) & Magisk
* `7)` Install `.apk` file into Waydroid
* `8)` Hide / Unhide Waydroid apps from Desktop Launcher
* `9)` Open Root Android Shell

---

## ⌨️ Desktop Keybinding Setup

Bind global keyboard shortcuts on your Linux host to control Waydroid media playback in the background:

### **KDE Plasma**
1. Open **System Settings** ➔ **Shortcuts** (or **Keyboard** ➔ **Shortcuts**).
2. Click **Add New** ➔ **Command or Script**.
3. **Name**: `Waydroid Play/Pause`
4. **Command**: `/path/to/Waydroid-Configs/waydroid_media.sh play-pause`
5. **Shortcut**: Press `F4` (or your media key).
6. Click **Apply**.

### **GNOME**
1. Open **Settings** ➔ **Keyboard** ➔ **View and Customize Shortcuts** ➔ **Custom Shortcuts**.
2. Click **+** (Add Shortcut):
   * **Name**: `Waydroid Play/Pause`
   * **Command**: `/path/to/Waydroid-Configs/waydroid_media.sh play-pause`
   * **Shortcut**: `F4`

### **Hyprland**
Add to `~/.config/hypr/hyprland.conf`:
```ini
bind = , F4, exec, /path/to/Waydroid-Configs/waydroid_media.sh play-pause
bind = , XF86AudioNext, exec, /path/to/Waydroid-Configs/waydroid_media.sh next
bind = , XF86AudioPrev, exec, /path/to/Waydroid-Configs/waydroid_media.sh prev
```

### **i3 / Sway**
Add to `~/.config/i3/config` or `~/.config/sway/config`:
```ini
bindsym F4 exec --no-startup-id /path/to/Waydroid-Configs/waydroid_media.sh play-pause
bindsym XF86AudioPlay exec --no-startup-id /path/to/Waydroid-Configs/waydroid_media.sh play-pause
```

---

## 🏗️ Native x86_64 vs ARM Translation

| Feature | Native `x86_64` APK | ARM Translation (`libndk` / `libhoudini`) |
| :--- | :--- | :--- |
| **Performance** | ⚡ **100% Direct CPU Execution** | 🔄 Dynamic instruction translation |
| **GPU Acceleration** | Full Hardware Vulkan/OpenGL Passthrough | GPU Passthrough with translation wrapper |
| **Battery / CPU Usage** | Lowest | Moderate |
| **Compatibility** | Apps targeting x86_64 (e.g. BitChord, MPV) | ARM-exclusive APKs, games, proprietary apps |

*Tip: For apps like **BitChord**, Gradle builds a native `app-dev-x86_64-debug.apk` directly. Install it via `waydroid app install <path>` for native speed.*

---

## ❓ Troubleshooting & FAQs

#### Q: `ModuleNotFoundError: No module named 'dbus'`
> **Cause**: You have an active Python virtual environment that does not contain system bindings.  
> **Fix**: Activate the dedicated Waydroid venv:
> ```bash
> source /path/to/Waydroid-Configs/.venv/bin/activate
> ```

#### Q: `sudo: 3 incorrect password attempts` / Account Locked (`pam_faillock`)
> **Cause**: Rapid failed sudo attempts triggered Linux PAM security lockout.  
> **Fix**: Wait **10 minutes** for `pam_faillock` to expire automatically, then run commands normally.

#### Q: Play Store shows "Device is not Play Protect certified"
> **Fix**:
> 1. Run `./waydroid_tools.sh` and select option **`5`** to get your GSF Android ID.
> 2. Visit [Google Uncertified Device Registration](https://www.google.com/android/uncertified/).
> 3. Paste the ID, click **Register**, and restart Waydroid (`waydroid session stop && sudo systemctl restart waydroid-container`).

---

## 📄 License

This project is licensed under the [MIT License](./LICENSE). Feel free to use, modify, and distribute.

<div align="center">

**Star ⭐ this repo if it helped you set up Waydroid seamlessly!**

</div>
