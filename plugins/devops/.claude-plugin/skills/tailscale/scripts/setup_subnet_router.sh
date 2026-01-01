#!/bin/bash
# Tailscale Subnet Router Setup Script
# Usage: ./setup_subnet_router.sh <subnet_cidr> [auth_key]

set -e

SUBNET=${1}
AUTH_KEY=${2}

if [ -z "$SUBNET" ]; then
    echo "Usage: $0 <subnet_cidr> [auth_key]"
    echo "Example: $0 192.168.1.0/24"
    exit 1
fi

echo "=== Tailscale Subnet Router Setup ==="
echo "Subnet: $SUBNET"
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

# Enable UDP GRO forwarding for better performance (Linux only)
if command -v ethtool &> /dev/null; then
    echo "Enabling UDP GRO forwarding..."
    NETDEV=$(ip -o route get 8.8.8.8 | cut -f 5 -d " ")
    if [ -n "$NETDEV" ]; then
        ethtool -K $NETDEV rx-udp-gro-forwarding on rx-gro-list off 2>/dev/null || true
        echo "✅ UDP GRO forwarding enabled on $NETDEV"
    fi
fi

# Start Tailscale daemon if not running
if ! systemctl is-active --quiet tailscaled 2>/dev/null; then
    echo "Starting Tailscale daemon..."
    systemctl enable --now tailscaled 2>/dev/null || true
fi

# Configure Tailscale
echo "Configuring Tailscale..."
UP_CMD="tailscale up --advertise-routes=$SUBNET"

if [ -n "$AUTH_KEY" ]; then
    UP_CMD="$UP_CMD --auth-key=$AUTH_KEY --advertise-tags=tag:subnet-router"
    echo "Using provided auth key..."
fi

eval $UP_CMD

echo "✅ Tailscale configured"

# Wait a moment for connection
sleep 2

# Check status
echo
echo "=== Status ==="
tailscale status | head -n 5

echo
echo "=== Advertised Routes ==="
tailscale status | grep -i "subnet\|route" || echo "No routes shown yet"

echo
echo "📋 Next Steps:"
echo "1. Go to admin console: https://login.tailscale.com/admin/machines"
echo "2. Find this device in the machines list"
echo "3. Click the menu (⋮) → 'Edit route settings'"
echo "4. Enable the advertised routes: $SUBNET"
echo
echo "5. On client devices, ensure they accept routes:"
echo "   Linux: sudo tailscale up --accept-routes"
echo "   Other platforms accept routes automatically"
echo
echo "✅ Subnet router setup complete!"
