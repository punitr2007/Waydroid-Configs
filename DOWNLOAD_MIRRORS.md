# Waydroid Image Fast Mirrors & Direct Download Links

This document provides high-speed direct download links, alternative mirrors, and community AOSP builds for Waydroid on `x86_64` Linux systems.

---

## 1. Official LineageOS 20.0 Images (Latest)

### A. GAPPS (Recommended — Includes Google Play Store & Google Services)
* **System Image (`system.img`)**:
  - **Filename**: `lineage-20.0-20260403-GAPPS-waydroid_x86_64-system.zip`
  - **Size**: ~1.14 GB
  - **SHA256**: `811ab2dd7ad1b0b4964bddf020fa450275ea1af2d5b0ac10d5ceced0ac1908a3`
  - **Direct CDN URL**: [SourceForge Direct Link](https://downloads.sourceforge.net/project/waydroid/images/system/lineage/waydroid_x86_64/lineage-20.0-20260403-GAPPS-waydroid_x86_64-system.zip)
  - **Fast Mirror URLs**:
    - [ExcellMedia Mirror (India/Asia)](https://excellmedia.dl.sourceforge.net/project/waydroid/images/system/lineage/waydroid_x86_64/lineage-20.0-20260403-GAPPS-waydroid_x86_64-system.zip)
    - [JAIST Mirror (Japan/Asia)](https://jaist.dl.sourceforge.net/project/waydroid/images/system/lineage/waydroid_x86_64/lineage-20.0-20260403-GAPPS-waydroid_x86_64-system.zip)
    - [Netix Mirror (Europe)](https://netix.dl.sourceforge.net/project/waydroid/images/system/lineage/waydroid_x86_64/lineage-20.0-20260403-GAPPS-waydroid_x86_64-system.zip)
    - [CFHCable Mirror (US)](https://cfhcable.dl.sourceforge.net/project/waydroid/images/system/lineage/waydroid_x86_64/lineage-20.0-20260403-GAPPS-waydroid_x86_64-system.zip)

### B. VANILLA (Pure AOSP / LineageOS — Lightweight, No Google Services)
* **System Image (`system.img`)**:
  - **Filename**: `lineage-20.0-20260403-VANILLA-waydroid_x86_64-system.zip`
  - **Size**: ~800 MB
  - **SHA256**: `2e343b14c649a685853e7957ac34feb1ca110425d78a47ebad764caae24116a8`
  - **Direct CDN URL**: [SourceForge Direct Link](https://downloads.sourceforge.net/project/waydroid/images/system/lineage/waydroid_x86_64/lineage-20.0-20260403-VANILLA-waydroid_x86_64-system.zip)
  - **Fast Mirror URLs**:
    - [ExcellMedia Mirror (India/Asia)](https://excellmedia.dl.sourceforge.net/project/waydroid/images/system/lineage/waydroid_x86_64/lineage-20.0-20260403-VANILLA-waydroid_x86_64-system.zip)
    - [JAIST Mirror (Japan/Asia)](https://jaist.dl.sourceforge.net/project/waydroid/images/system/lineage/waydroid_x86_64/lineage-20.0-20260403-VANILLA-waydroid_x86_64-system.zip)
    - [Netix Mirror (Europe)](https://netix.dl.sourceforge.net/project/waydroid/images/system/lineage/waydroid_x86_64/lineage-20.0-20260403-VANILLA-waydroid_x86_64-system.zip)

### C. MAINLINE Vendor Image (Required for all x86_64 setups)
* **Vendor Image (`vendor.img`)**:
  - **Filename**: `lineage-20.0-20260428-MAINLINE-waydroid_x86_64-vendor.zip`
  - **Size**: ~180 MB
  - **SHA256**: `cba35433ffca73ed349e096b1daec495b3204e01c0e541c4203671e6d648e874`
  - **Direct CDN URL**: [SourceForge Direct Link](https://downloads.sourceforge.net/project/waydroid/images/vendor/waydroid_x86_64/lineage-20.0-20260428-MAINLINE-waydroid_x86_64-vendor.zip)
  - **Fast Mirror URLs**:
    - [ExcellMedia Mirror (India/Asia)](https://excellmedia.dl.sourceforge.net/project/waydroid/images/vendor/waydroid_x86_64/lineage-20.0-20260428-MAINLINE-waydroid_x86_64-vendor.zip)
    - [JAIST Mirror (Japan/Asia)](https://jaist.dl.sourceforge.net/project/waydroid/images/vendor/waydroid_x86_64/lineage-20.0-20260428-MAINLINE-waydroid_x86_64-vendor.zip)

---

## 2. Alternative Fast Community Mirrors (GitHub Releases)

If SourceForge is completely blocked or throttled in your region:

1. **WayDroid-ATV Builds (Android 13 / 14 / 15 / 16)**
   - **Repository**: [https://github.com/WayDroid-ATV/waydroid-builds/releases](https://github.com/WayDroid-ATV/waydroid-builds/releases)
   - Hosted on GitHub Releases CDN with high download speeds.

2. **akku1139 OTA Mirror**
   - **Repository**: [https://github.com/akku1139/waydroid_ota](https://github.com/akku1139/waydroid_ota)
   - Mirror of official Waydroid images hosted on GitHub Releases.

3. **BlissOS for Waydroid (Bliss Bass / Submix)**
   - **Repository**: [https://sourceforge.net/projects/blissos-dev/files/waydroid/](https://sourceforge.net/projects/blissos-dev/files/waydroid/) / [https://blissos.org](https://blissos.org)
   - Optimized for desktop experience and PC gaming.

---

## 3. High-Speed Multi-Connection Download Methods

### Method 1: Using the Included Python Multi-Threaded Tool (Recommended)
This tool splits downloads into 12-16 parallel range streams, bypassing SourceForge speed caps:
```bash
cd /home/punit/Local_Codebase/Projects/Ideas/Waydroid
python3 fast_waydroid_downloader.py --type GAPPS --threads 16
```

### Method 2: Using `aria2c` (Multi-Connection Downloader)
If you have `aria2` installed (`sudo pacman -S aria2`):
```bash
# Download GAPPS System Zip with 16 connections
aria2c -x 16 -s 16 -k 1M -j 4 "https://downloads.sourceforge.net/project/waydroid/images/system/lineage/waydroid_x86_64/lineage-20.0-20260403-GAPPS-waydroid_x86_64-system.zip"

# Download Vendor Zip with 16 connections
aria2c -x 16 -s 16 -k 1M -j 4 "https://downloads.sourceforge.net/project/waydroid/images/vendor/waydroid_x86_64/lineage-20.0-20260428-MAINLINE-waydroid_x86_64-vendor.zip"
```

---

## 4. Manual Extraction & Initialization Steps

Once you have the `.zip` files:

1. **Extract `system.img` and `vendor.img`**:
   ```bash
   mkdir -p /home/punit/Local_Codebase/Projects/Ideas/Waydroid/images
   unzip lineage-*-system.zip -d /home/punit/Local_Codebase/Projects/Ideas/Waydroid/images/
   unzip lineage-*-vendor.zip -d /home/punit/Local_Codebase/Projects/Ideas/Waydroid/images/
   ```

2. **Initialize Waydroid pointing to your images**:
   ```bash
   sudo waydroid init -f -i /home/punit/Local_Codebase/Projects/Ideas/Waydroid/images
   ```

3. **Start the Container Service**:
   ```bash
   sudo systemctl enable --now waydroid-container
   ```

4. **Launch Waydroid**:
   ```bash
   waydroid show-full-ui
   ```
