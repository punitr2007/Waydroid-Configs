#!/usr/bin/env bash
# ==============================================================================
# Waydroid Complete Internet & Network Fixer
# Fixes the upstream nftables failure in waydroid-net.sh by switching to iptables,
# enables kernel IP forwarding, configures UFW/iptables NAT, and sets DNS.
# ==============================================================================

set -e

echo "=========================================================="
echo "          Waydroid Internet & Network Fixer               "
echo "=========================================================="
echo ""

echo "[*] Requesting sudo permission to patch waydroid-net.sh and configure firewall..."
sudo -v

# 1. Patch waydroid-net.sh to disable broken nftables mode and use modern iptables (iptables-nft)
NET_SCRIPT="/usr/lib/waydroid/data/scripts/waydroid-net.sh"
if [ -f "${NET_SCRIPT}" ]; then
    echo "[*] Patching ${NET_SCRIPT} to use stable iptables mode..."
    sudo sed -i 's/LXC_USE_NFT="true"/LXC_USE_NFT="false"/g' "${NET_SCRIPT}"
    
    # Force use of standard iptables / iptables-nft rather than iptables-legacy
    sudo sed -i 's/IPTABLES_BIN="\$(command -v iptables-legacy)"/IPTABLES_BIN="\$(command -v iptables)"/g' "${NET_SCRIPT}"
    sudo sed -i 's/IP6TABLES_BIN="\$(command -v ip6tables-legacy)"/IP6TABLES_BIN="\$(command -v ip6tables)"/g' "${NET_SCRIPT}"
    
    # Also clean up any leading semicolon if present in start_nftables
    if grep -q 'NFT_RULESET="\${NFT_RULESET};' "${NET_SCRIPT}"; then
        sudo sed -i 's/NFT_RULESET="\${NFT_RULESET};/NFT_RULESET="\${NFT_RULESET}/g' "${NET_SCRIPT}"
    fi
    echo "    ✓ ${NET_SCRIPT} configured."
fi

# 2. Check for kernel update mismatch (running kernel vs /lib/modules)
RUNNING_KERNEL="$(uname -r)"
if [ ! -d "/lib/modules/${RUNNING_KERNEL}" ]; then
    echo ""
    echo "[!] Notice: Running kernel (${RUNNING_KERNEL}) does not match installed /lib/modules."
    echo "    A system update (pacman -Syu) recently updated your kernel."
    echo "    A reboot is recommended to boot into the latest kernel."
fi

# 2. Enable IPv4 forwarding in kernel
echo ""
echo "[*] Enabling IPv4 packet forwarding in kernel..."
sudo sysctl -w net.ipv4.ip_forward=1 >/dev/null
echo "    ✓ net.ipv4.ip_forward = 1"

# 3. Clean up any stale bridge interfaces
echo ""
echo "[*] Resetting stale waydroid0 network bridge if exists..."
sudo ip link set dev waydroid0 down 2>/dev/null || true
sudo ip link delete dev waydroid0 2>/dev/null || true
echo "    ✓ Interface reset."

# 4. Configure UFW if active
echo ""
echo "[*] Configuring UFW Firewall Rules for waydroid0..."
if command -v ufw &>/dev/null && sudo ufw status | grep -q "Status: active"; then
    echo "    Allowing waydroid0 traffic through UFW..."
    sudo ufw allow in on waydroid0
    sudo ufw route allow in on waydroid0
    DEFAULT_IFACE=$(ip route show default | awk '{print $5}' | head -n 1)
    if [ -n "$DEFAULT_IFACE" ]; then
        sudo ufw route allow in on waydroid0 out on "${DEFAULT_IFACE}" 2>/dev/null || true
    fi
    sudo ufw reload
    echo "    ✓ UFW configured."
fi

# 5. Apply standard iptables forwarding and NAT
echo ""
echo "[*] Applying iptables NAT & Forwarding rules..."
sudo iptables -C FORWARD -i waydroid0 -j ACCEPT 2>/dev/null || sudo iptables -A FORWARD -i waydroid0 -j ACCEPT
sudo iptables -C FORWARD -o waydroid0 -j ACCEPT 2>/dev/null || sudo iptables -A FORWARD -o waydroid0 -j ACCEPT
sudo iptables -t nat -C POSTROUTING -s 192.168.240.0/24 ! -d 192.168.240.0/24 -j MASQUERADE 2>/dev/null || \
    sudo iptables -t nat -A POSTROUTING -s 192.168.240.0/24 ! -d 192.168.240.0/24 -j MASQUERADE
echo "    ✓ iptables configured."

# 6. Set Google DNS properties
echo ""
echo "[*] Setting Google DNS properties in Waydroid..."
/usr/bin/python3 /usr/bin/waydroid prop set persist.waydroid.dns 8.8.8.8 2>/dev/null || true
/usr/bin/python3 /usr/bin/waydroid prop set persist.waydroid.dns2 1.1.1.1 2>/dev/null || true
echo "    ✓ Google DNS (8.8.8.8 & 1.1.1.1) set."

# 7. Restart container service
echo ""
echo "[*] Restarting waydroid-container service..."
sudo systemctl restart waydroid-container
echo "    ✓ waydroid-container restarted."

echo ""
echo "=========================================================="
echo "  ✓ WAYDROID NETWORK FIX APPLIED SUCCESSFULLY!"
echo "=========================================================="
echo "Now you can launch Waydroid without errors:"
echo "  waydroid show-full-ui"
echo "=========================================================="
