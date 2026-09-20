#!/usr/bin/env bash
# ==============================================================================
# Waydroid Instant Media Controller
# Binds global host keyboard shortcuts (e.g. F4, Play/Pause, Next, Prev) to Android apps.
# ==============================================================================

ACTION="${1:-play-pause}"

# Ensure ADB is connected to Waydroid
if ! adb devices | grep -q ":5555.*device"; then
    # Dynamically find Waydroid IP
    WAYDROID_IP=$(/usr/bin/python3 /usr/bin/waydroid status 2>/dev/null | grep -i "IP address:" | awk '{print $NF}')
    if [ -n "$WAYDROID_IP" ] && [ "$WAYDROID_IP" != "UNKNOWN" ]; then
        adb connect "${WAYDROID_IP}:5555" >/dev/null 2>&1 || true
    fi
fi

case "$ACTION" in
    play-pause|play_pause|toggle|f4)
        adb shell input keyevent 85
        ;;
    play)
        adb shell input keyevent 126
        ;;
    pause)
        adb shell input keyevent 127
        ;;
    next)
        adb shell input keyevent 87
        ;;
    prev|previous)
        adb shell input keyevent 88
        ;;
    stop)
        adb shell input keyevent 86
        ;;
    vol-up|volume-up)
        adb shell input keyevent 24
        ;;
    vol-down|volume-down)
        adb shell input keyevent 25
        ;;
    *)
        echo "Usage: $0 [play-pause|next|prev|play|pause|stop|vol-up|vol-down]"
        exit 1
        ;;
esac
