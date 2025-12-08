#!/bin/bash
# Tailscale Exit Node Setup Script
# Usage: ./setup_exit_node.sh [auth_key]

set -e

AUTH_KEY=${1}

echo "=== Tailscale Exit Node Setup ==="
echo

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "Error: This script must be run as root (use sudo)"
    exit 1
fi

# Install Tailscale if not present
if ! command -v tailscale &> /dev/null; then
    echo "Installing Tailscale..."
    curl -fsSL https://tailscale.com/install.sh | sh
    echo "✅ Tailscale installed"
else
    echo "✅ Tailscale already installed"
fi

# Enable IP forwarding
echo "Enabling IP forwarding..."
if [ -d /etc/sysctl.d ]; then
    echo 'net.ipv4.ip_forward = 1' | tee -a /etc/sysctl.d/99-tailscale.conf
    echo 'net.ipv6.conf.all.forwarding = 1' | tee -a /etc/sysctl.d/99-tailscale.conf
    sysctl -p /etc/sysctl.d/99-tailscale.conf
else
    echo 'net.ipv4.ip_forward = 1' | tee -a /etc/sysctl.conf
    echo 'net.ipv6.conf.all.forwarding = 1' | tee -a /etc/sysctl.conf
    sysctl -p /etc/sysctl.conf
fi
echo "✅ IP forwarding enabled"

# Verify IP forwarding
IPV4_FORWARD=$(cat /proc/sys/net/ipv4/ip_forward)
if [ "$IPV4_FORWARD" != "1" ]; then
    echo "❌ Error: IPv4 forwarding not enabled"
    exit 1
fi

# Start Tailscale daemon if not running
if ! systemctl is-active --quiet tailscaled 2>/dev/null; then
    echo "Starting Tailscale daemon..."
    systemctl enable --now tailscaled 2>/dev/null || true
fi

# Configure Tailscale as exit node
echo "Configuring Tailscale as exit node..."
UP_CMD="tailscale up --advertise-exit-node"

if [ -n "$AUTH_KEY" ]; then
    UP_CMD="$UP_CMD --auth-key=$AUTH_KEY --advertise-tags=tag:exit-node"
    echo "Using provided auth key..."
fi

eval $UP_CMD

echo "✅ Tailscale configured as exit node"

# Wait a moment for connection
sleep 2

# Check status
echo
echo "=== Status ==="
tailscale status | head -n 5

echo
echo "📋 Next Steps:"
echo "1. Go to admin console: https://login.tailscale.com/admin/machines"
echo "2. Find this device in the machines list"
echo "3. Click the menu (⋮) → 'Edit route settings'"
echo "4. Enable 'Use as exit node'"
echo
echo "5. On client devices, use this exit node:"
echo "   tailscale set --exit-node=$(tailscale status --json | jq -r '.Self.HostName')"
echo
echo "   Or use auto-selection:"
echo "   tailscale set --exit-node=auto:any"
echo
echo "   With LAN access:"
echo "   tailscale set --exit-node=<node> --exit-node-allow-lan-access"
echo
echo "✅ Exit node setup complete!"
