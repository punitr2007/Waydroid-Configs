#!/usr/bin/env bash
# ==============================================================================
# Waydroid Complete Internet & Firewall Fix
# ==============================================================================

set -e

echo "=========================================================="
echo "          Waydroid Internet & Firewall Fix                "
echo "=========================================================="
echo ""

# 1. Check PAM faillock status
echo "[*] Checking sudo lockout status..."
if faillock --user punit | grep -q "V"; then
    echo "    Note: faillock entries detected. If sudo fails, wait until 11:31 AM."
fi

echo ""
echo "[*] Requesting sudo permission to configure UFW / iptables..."
sudo -v

echo ""
echo "[*] 1. Configuring UFW Firewall Rules for waydroid0..."
if command -v ufw &>/dev/null && sudo ufw status | grep -q "Status: active"; then
    echo "    Allowing waydroid0 traffic through UFW..."
    sudo ufw allow in on waydroid0
    sudo ufw route allow in on waydroid0
    sudo ufw route allow in on waydroid0 out on $(ip route show default | awk '{print $5}' | head -n 1) 2>/dev/null || true
    sudo ufw reload
    echo "    ✓ UFW configured."
fi

echo ""
echo "[*] 2. Applying iptables NAT & Forwarding rules..."
sudo iptables -C FORWARD -i waydroid0 -j ACCEPT 2>/dev/null || sudo iptables -A FORWARD -i waydroid0 -j ACCEPT
sudo iptables -C FORWARD -o waydroid0 -j ACCEPT 2>/dev/null || sudo iptables -A FORWARD -o waydroid0 -j ACCEPT
sudo iptables -t nat -C POSTROUTING -s 192.168.240.0/24 ! -d 192.168.240.0/24 -j MASQUERADE 2>/dev/null || \
    sudo iptables -t nat -A POSTROUTING -s 192.168.240.0/24 ! -d 192.168.240.0/24 -j MASQUERADE
echo "    ✓ iptables configured."

echo ""
echo "[*] 3. Setting DNS properties in Waydroid..."
/usr/bin/python3 /usr/bin/waydroid prop set persist.waydroid.dns 8.8.8.8
/usr/bin/python3 /usr/bin/waydroid prop set persist.waydroid.dns2 1.1.1.1
echo "    ✓ Google DNS (8.8.8.8) set."

echo ""
echo "[*] 4. Restarting waydroid-container service..."
sudo systemctl restart waydroid-container
echo "    ✓ waydroid-container restarted."

echo ""
echo "=========================================================="
echo "  ✓ INTERNET CONFIGURATION COMPLETE!"
echo "=========================================================="
echo "Now you can launch Waydroid:"
echo "  waydroid show-full-ui"
echo "=========================================================="
