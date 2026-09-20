#!/usr/bin/env bash
# ==============================================================================
# Waydroid All-In-One Setup & Fast Initializer
# ==============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IMAGES_DIR="${SCRIPT_DIR}/images"

echo "=========================================================="
echo "         Waydroid High-Speed Setup & Manager              "
echo "=========================================================="
echo "Working Directory: ${SCRIPT_DIR}"
echo ""

# 1. Check Prerequisites
echo "[*] Checking system requirements..."

if ! command -v waydroid &> /dev/null; then
    echo "[!] Waydroid is not installed. On Arch Linux, install it via:"
    echo "    sudo pacman -S waydroid"
    exit 1
fi
echo "  ✓ Waydroid binary found: $(command -v waydroid)"

# Check Binderfs / Kernel modules
if [ -d "/dev/binderfs" ] || [ -e "/dev/binder" ]; then
    echo "  ✓ Android Binder kernel support detected."
else
    echo "  [!] Warning: Binder nodes (/dev/binder or /dev/binderfs) not found."
    echo "      On Arch Linux with standard kernel (Linux 5.10+ / 6.x+), binderfs is built-in."
fi

# Check if images already exist
if [ -f "${IMAGES_DIR}/system.img" ] && [ -f "${IMAGES_DIR}/vendor.img" ]; then
    echo ""
    echo "[+] Found existing downloaded images in ${IMAGES_DIR}!"
    echo "  - system.img ($(du -h "${IMAGES_DIR}/system.img" | cut -f1))"
    echo "  - vendor.img ($(du -h "${IMAGES_DIR}/vendor.img" | cut -f1))"
    echo ""
    echo "Options:"
    echo "  1) Use existing images to initialize Waydroid [Fastest - No download]"
    echo "  2) Re-download GAPPS images"
    echo "  3) Re-download VANILLA images"
    echo ""
    read -rp "Enter choice [1-3] (Default: 1): " ROM_CHOICE
    ROM_CHOICE="${ROM_CHOICE:-1}"
else
    echo ""
    echo "Select Waydroid ROM Type to download:"
    echo "  1) LineageOS 20 GAPPS (Google Play Store & Services) [Recommended]"
    echo "  2) LineageOS 20 VANILLA (Pure AOSP / LineageOS, Privacy-friendly, Lightweight)"
    echo ""
    read -rp "Enter choice [1-2] (Default: 1): " ROM_CHOICE
    ROM_CHOICE="${ROM_CHOICE:-1}"
    
    if [ "$ROM_CHOICE" == "1" ]; then
        ROM_CHOICE="2"
    elif [ "$ROM_CHOICE" == "2" ]; then
        ROM_CHOICE="3"
    fi
fi

case "${ROM_CHOICE}" in
    1)
        echo "[*] Using existing local images."
        ;;
    2)
        echo ""
        echo "[*] Launching high-speed multi-connection downloader for GAPPS..."
        python3 "${SCRIPT_DIR}/fast_waydroid_downloader.py" --type GAPPS --threads 12 --out-dir "${IMAGES_DIR}"
        ;;
    3)
        echo ""
        echo "[*] Launching high-speed multi-connection downloader for VANILLA..."
        python3 "${SCRIPT_DIR}/fast_waydroid_downloader.py" --type VANILLA --threads 12 --out-dir "${IMAGES_DIR}"
        ;;
    *)
        echo "[!] Invalid choice. Exiting."
        exit 1
        ;;
esac

# 2. Check if images exist
if [ ! -f "${IMAGES_DIR}/system.img" ] || [ ! -f "${IMAGES_DIR}/vendor.img" ]; then
    echo "[!] Error: system.img or vendor.img not found in ${IMAGES_DIR}."
    exit 1
fi

echo ""
echo "=========================================================="
echo "[*] Registering preinstalled local images with Waydroid..."
echo "=========================================================="
sudo mkdir -p /etc/waydroid-extra/images
sudo ln -sf "${IMAGES_DIR}/system.img" /etc/waydroid-extra/images/system.img
sudo ln -sf "${IMAGES_DIR}/vendor.img" /etc/waydroid-extra/images/vendor.img

echo ""
echo "[*] Initializing Waydroid (sudo waydroid init -f)..."
sudo waydroid init -f

echo ""
echo "[*] Enabling and starting waydroid-container service..."
sudo systemctl enable --now waydroid-container

echo ""
echo "=========================================================="
echo "  ✓ WAYDROID INITIALIZED SUCCESSFULLY!"
echo "=========================================================="
echo ""
echo "Next Steps:"
echo "  1. To start Android UI: waydroid show-full-ui"
echo "  2. To start session in background: waydroid session start"
echo "  3. To configure ARM translation (libndk/libhoudini) or Google Play ID:"
echo "     Run: ${SCRIPT_DIR}/waydroid_tools.sh"
echo ""
