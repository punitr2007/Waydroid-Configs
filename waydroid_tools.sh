#!/usr/bin/env bash
# ==============================================================================
# Waydroid Post-Install Tools & Helper
# Includes ARM translation setup, network fixes, Google Play Certification, & session control.
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VENV_DIR="${SCRIPT_DIR}/.venv"

# Ensure dedicated Waydroid venv with system site-packages exists
if [ ! -d "${VENV_DIR}" ]; then
    echo "[*] Initializing dedicated Waydroid virtual environment (.venv)..."
    /usr/bin/python3 -m venv --system-site-packages "${VENV_DIR}"
    "${VENV_DIR}/bin/pip" install --quiet requests tqdm inquirerpy packaging pyyaml 2>/dev/null || true
fi

# Define a safe waydroid wrapper that always uses system python/dbus even if another venv was active
run_waydroid() {
    /usr/bin/python3 /usr/bin/waydroid "$@"
}

show_menu() {
    echo "=========================================================="
    echo "               Waydroid Management Tools                  "
    echo "=========================================================="
    echo "  1) Launch Waydroid Full UI (waydroid show-full-ui)"
    echo "  2) Start Waydroid Session in background"
    echo "  3) Stop Waydroid Session & Container"
    echo "  4) Fix Internet & DNS inside Waydroid (UFW / Firewall / DNS)"
    echo "  5) Get Google Play Device ID (for Google Play Certification)"
    echo "  6) Install ARM Translation (libndk / libhoudini) & Magisk"
    echo "  7) Install an APK file"
    echo "  8) Hide / Unhide Waydroid apps from Desktop Launcher"
    echo "  9) Open Android Shell (waydroid shell)"
    echo "  10) Exit"
    echo "=========================================================="
    read -rp "Enter choice [1-10]: " CHOICE
    echo ""
}

fix_network() {
    echo "[*] Setting Waydroid DNS to Google DNS (8.8.8.8 & 1.1.1.1)..."
    run_waydroid prop set persist.waydroid.dns 8.8.8.8
    run_waydroid prop set persist.waydroid.dns2 1.1.1.1
    
    echo ""
    echo "[*] Requesting sudo access to configure Firewall / NAT for waydroid0..."
    sudo -v || { echo "[!] Sudo authentication failed."; return 1; }

    DEFAULT_IFACE=$(ip route show default | awk '{print $5}' | head -n 1)
    echo "    Default internet interface detected: ${DEFAULT_IFACE:-any}"

    if command -v ufw &>/dev/null && sudo ufw status | grep -q "Status: active"; then
        echo "[*] UFW is active. Configuring UFW forwarding rules for waydroid0..."
        sudo ufw allow in on waydroid0
        sudo ufw route allow in on waydroid0
        if [ -n "$DEFAULT_IFACE" ]; then
            sudo ufw route allow in on waydroid0 out on "${DEFAULT_IFACE}"
        fi
        sudo ufw reload
    fi

    echo "[*] Applying standard iptables forwarding and NAT rules..."
    sudo iptables -C FORWARD -i waydroid0 -j ACCEPT 2>/dev/null || sudo iptables -A FORWARD -i waydroid0 -j ACCEPT
    sudo iptables -C FORWARD -o waydroid0 -j ACCEPT 2>/dev/null || sudo iptables -A FORWARD -o waydroid0 -j ACCEPT
    sudo iptables -t nat -C POSTROUTING -s 192.168.240.0/24 ! -d 192.168.240.0/24 -j MASQUERADE 2>/dev/null || \
        sudo iptables -t nat -A POSTROUTING -s 192.168.240.0/24 ! -d 192.168.240.0/24 -j MASQUERADE

    echo ""
    echo "  ✓ Network and firewall configurations applied successfully!"
}

get_play_id() {
    echo "[*] Fetching Google Services Framework (GSF) Android ID..."
    echo "    (Make sure Waydroid is running and you have opened Google Play Store at least once)"
    echo ""
    sudo -v || { echo "[!] Sudo authentication failed."; return 1; }
    
    GSF_ID=$(sudo /usr/bin/python3 /usr/bin/waydroid shell 'sqlite3 /data/data/com.google.android.gsf/databases/gservices.db "select * from main where name = '\''android_id'\'';"' 2>/dev/null | awk -F '|' '{print $2}')
    
    if [ -n "$GSF_ID" ]; then
        echo "=========================================================="
        echo "  Your Google Services Android ID is:"
        echo "  --> ${GSF_ID}"
        echo "=========================================================="
        echo "  To certify your device with Google:"
        echo "  1. Open: https://www.google.com/android/uncertified/"
        echo "  2. Sign in with your Google account"
        echo "  3. Paste the ID above into the 'Google Services Framework ID' field"
        echo "  4. Click 'Register' and restart Waydroid"
        echo "=========================================================="
    else
        echo "[!] Could not automatically retrieve GSF ID."
        echo "    Tip: Open Waydroid, launch Play Store (even if uncertified warning shows), then run this tool again."
    fi
}

setup_arm_translation() {
    echo "[*] Setting up ARM Translation (libndk / libhoudini) via casualsnek/waydroid_script..."
    EXTRAS_DIR="${SCRIPT_DIR}/waydroid_script"
    
    if [ ! -d "${EXTRAS_DIR}" ]; then
        echo "[*] Cloning waydroid_script repository..."
        git clone https://github.com/casualsnek/waydroid_script.git "${EXTRAS_DIR}"
    else
        echo "[*] Updating existing waydroid_script repository..."
        cd "${EXTRAS_DIR}" && git pull && cd "${SCRIPT_DIR}"
    fi

    cd "${EXTRAS_DIR}"
    "${VENV_DIR}/bin/pip" install -r requirements.txt --quiet 2>/dev/null || true
    
    echo ""
    echo "[*] Launching Waydroid Extras installer..."
    echo "    Select 'Install' -> 'libndk' (for AMD/Intel) or 'libhoudini' (Intel) for ARM app compatibility."
    sudo -v
    sudo "${VENV_DIR}/bin/python3" main.py
    cd "${SCRIPT_DIR}"
}

install_apk() {
    read -rp "Enter full path to .apk file: " APK_PATH
    if [ -f "${APK_PATH}" ]; then
        echo "[*] Installing APK: ${APK_PATH}"
        run_waydroid app install "${APK_PATH}"
    else
        echo "[!] File not found: ${APK_PATH}"
    fi
}

toggle_desktop_visibility() {
    echo "Select an option:"
    echo "  1) Hide all Waydroid apps from Application Menu"
    echo "  2) Unhide / Show all Waydroid apps in Application Menu"
    echo "  3) Check current visibility status"
    read -rp "Choice [1-3]: " APP_VIS_CHOICE
    case "$APP_VIS_CHOICE" in
        1) "${SCRIPT_DIR}/hide_apps.sh" hide ;;
        2) "${SCRIPT_DIR}/hide_apps.sh" unhide ;;
        3) "${SCRIPT_DIR}/hide_apps.sh" status ;;
        *) echo "Invalid choice." ;;
    esac
}

while true; do
    show_menu
    case "${CHOICE}" in
        1)
            run_waydroid show-full-ui
            ;;
        2)
            run_waydroid session start &
            echo "Session started in background."
            ;;
        3)
            echo "[*] Stopping Waydroid session..."
            run_waydroid session stop 2>/dev/null || true
            sudo systemctl stop waydroid-container 2>/dev/null || true
            echo "  ✓ Stopped."
            ;;
        4)
            fix_network
            ;;
        5)
            get_play_id
            ;;
        6)
            setup_arm_translation
            ;;
        7)
            install_apk
            ;;
        8)
            toggle_desktop_visibility
            ;;
        9)
            sudo /usr/bin/python3 /usr/bin/waydroid shell
            ;;
        10)
            echo "Exiting."
            exit 0
            ;;
        *)
            echo "Invalid option."
            ;;
    esac
    echo ""
    read -rp "Press Enter to return to menu..."
    echo ""
done
