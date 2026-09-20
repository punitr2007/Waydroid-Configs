#!/usr/bin/env bash
# ==============================================================================
# Waydroid App Launcher Visibility Manager
# Hides or unhides Waydroid Android apps from your Linux desktop application menu.
# ==============================================================================

ACTION="${1:-hide}"
APPS_DIR="${HOME}/.local/share/applications"

refresh_desktop_cache() {
    echo "[*] Refreshing desktop application database..."
    if command -v kbuildsycoca6 &>/dev/null; then
        kbuildsycoca6 2>/dev/null || true
    elif command -v kbuildsycoca5 &>/dev/null; then
        kbuildsycoca5 2>/dev/null || true
    fi
    if command -v update-desktop-database &>/dev/null; then
        update-desktop-database "${APPS_DIR}" 2>/dev/null || true
    fi
}

hide_apps() {
    echo "[*] Hiding all Waydroid apps from the application launcher..."
    local count=0
    for f in "${APPS_DIR}"/waydroid.*.desktop; do
        if [ -f "$f" ]; then
            if grep -q "^NoDisplay=" "$f"; then
                sed -i 's/^NoDisplay=.*/NoDisplay=true/' "$f"
            else
                sed -i '/\[Desktop Entry\]/a NoDisplay=true' "$f"
            fi
            ((count++))
        fi
    done
    echo "  ✓ Successfully hid ${count} Waydroid apps."
    refresh_desktop_cache
    echo "  ✓ Done! Waydroid apps will no longer clutter your desktop launcher."
    echo "    (You can still open them inside Android via 'waydroid show-full-ui')"
}

unhide_apps() {
    echo "[*] Unhiding all Waydroid apps in the application launcher..."
    local count=0
    for f in "${APPS_DIR}"/waydroid.*.desktop; do
        if [ -f "$f" ]; then
            sed -i '/^NoDisplay=/d' "$f"
            ((count++))
        fi
    done
    echo "  ✓ Successfully unhid ${count} Waydroid apps."
    refresh_desktop_cache
    echo "  ✓ Done! Waydroid apps are now visible in your desktop launcher."
}

status_apps() {
    echo "=========================================================="
    echo "           Waydroid App Launcher Status                   "
    echo "=========================================================="
    local total=0
    local hidden=0
    local visible=0
    for f in "${APPS_DIR}"/waydroid.*.desktop; do
        if [ -f "$f" ]; then
            ((total++))
            if grep -q "^NoDisplay=true" "$f"; then
                ((hidden++))
            else
                ((visible++))
            fi
        fi
    done
    echo "  Total Waydroid apps found: ${total}"
    echo "  Hidden from launcher:      ${hidden}"
    echo "  Visible in launcher:       ${visible}"
    echo "=========================================================="
}

case "$ACTION" in
    hide)
        hide_apps
        ;;
    unhide|show)
        unhide_apps
        ;;
    status)
        status_apps
        ;;
    *)
        echo "Usage: $0 [hide|unhide|status]"
        exit 1
        ;;
esac
