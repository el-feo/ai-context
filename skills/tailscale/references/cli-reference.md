# Tailscale CLI Command Reference

Complete reference for all `tailscale` CLI commands and flags.

## Core Commands

### tailscale up

Connect to your Tailscale network with configuration options.

```bash
tailscale up [flags]
```

**Common flags:**

| Flag | Description | Example |
|------|-------------|---------|
| `--advertise-exit-node` | Offer to be an exit node | `tailscale up --advertise-exit-node` |
| `--advertise-routes=<routes>` | Expose subnet routes | `tailscale up --advertise-routes=192.168.1.0/24` |
| `--advertise-tags=<tags>` | Apply tags to this device | `tailscale up --advertise-tags=tag:server` |
| `--accept-routes` | Accept subnet routes from other nodes | `tailscale up --accept-routes` |
| `--exit-node=<node>` | Use specific exit node | `tailscale up --exit-node=homeserver` |
| `--exit-node-allow-lan-access` | Allow LAN access when using exit node | `tailscale up --exit-node-allow-lan-access` |
| `--ssh` | Enable Tailscale SSH server | `tailscale up --ssh` |
| `--hostname=<name>` | Set custom hostname | `tailscale up --hostname=myserver` |
| `--auth-key=<key>` | Use auth key for unattended setup | `tailscale up --auth-key=tskey-auth-...` |
| `--reset` | Reset to default settings | `tailscale up --reset` |

**Network flags:**

| Flag | Description |
|------|-------------|
| `--accept-dns` | Accept DNS configuration from Tailscale |
| `--advertise-connector` | Advertise as an app connector |
| `--netfilter-mode=<mode>` | (Linux) Firewall management mode: `on`, `off`, `nodivert` |
| `--snat-subnet-routes` | Enable/disable source NAT for subnet routes |
| `--stateful-filtering` | Enable stateful filtering for subnet routers |
| `--shields-up` | Block all incoming connections except Tailscale |

**Examples:**

```bash
# Basic connection
sudo tailscale up

# Subnet router with tags
sudo tailscale up \
  --advertise-routes=192.168.1.0/24,10.0.0.0/24 \
  --advertise-tags=tag:subnet-router \
  --accept-routes

# Exit node with SSH
sudo tailscale up --advertise-exit-node --ssh

# Use specific exit node with LAN access
tailscale up --exit-node=homeserver --exit-node-allow-lan-access

# Automated setup with auth key
sudo tailscale up --auth-key=tskey-auth-k... --advertise-tags=tag:server
```

### tailscale down

Disconnect from Tailscale (daemon keeps running).

```bash
tailscale down
```

Stops accepting connections but daemon remains active for faster reconnection.

### tailscale set

Change settings without reconnecting (preferred over `tailscale up` for adjustments).

```bash
tailscale set [flags]
```

**Key difference from `up`**: Only updates specified settings, doesn't require all flags.

**Examples:**

```bash
# Change exit node
tailscale set --exit-node=new-exit-node

# Disable exit node
tailscale set --exit-node=

# Enable SSH without affecting other settings
sudo tailscale set --ssh

# Change advertised routes
sudo tailscale set --advertise-routes=10.0.0.0/8
```

### tailscale status

View connection status and peer list.

```bash
tailscale status [flags]
```

**Flags:**

| Flag | Description |
|------|-------------|
| `--json` | Output as JSON |
| `--peers` | Show peer information |
| `--active` | Show only active peers |
| `--self` | Show only self |

**Example output:**

```
100.101.102.103  homeserver     user@       linux   -
100.101.102.104  laptop         user@       macOS   active; direct; tx 1234 rx 5678
100.101.102.105  phone          user@       iOS     active; relay "sfo"; tx 9012 rx 3456
```

**Status indicators:**

- `direct` - Peer-to-peer connection (best)
- `relay "location"` - Using DERP relay server
- `idle` - Not actively communicating
- `offline` - Peer is disconnected

### tailscale ping

Test connectivity to peers.

```bash
tailscale ping [flags] <hostname|ip>
```

**Ping types:**

| Flag | Type | Tests |
|------|------|-------|
| `--tsmp` (default) | TSMP | Network path only (ignores ACLs) |
| `--icmp` | ICMP | End-to-end including ACLs |
| `--peerapi` | PeerAPI | Application-layer connectivity |

**Examples:**

```bash
# Test network connectivity (ignores ACLs)
tailscale ping --tsmp homeserver

# Test end-to-end with ACLs
tailscale ping --icmp homeserver

# Test until 5 packets sent
tailscale ping -c 5 homeserver
```

### tailscale ip

Get Tailscale IP address(es).

```bash
tailscale ip [flags] [hostname]
```

**Flags:**

| Flag | Description |
|------|-------------|
| `-4` | IPv4 only |
| `-6` | IPv6 only |
| `--json` | JSON output |

**Examples:**

```bash
# Get own IPs
tailscale ip
# 100.101.102.103
# fd7a:115c:a1e0::1

# Get IPv4 only
tailscale ip -4
# 100.101.102.103

# Get another device's IP
tailscale ip homeserver
# 100.101.102.104
# fd7a:115c:a1e0::2
```

## SSH and Serve Commands

### tailscale ssh

Connect via Tailscale SSH.

```bash
tailscale ssh [user@]<hostname>
```

Note: This is syntactic sugar. Regular `ssh` works once Tailscale SSH is configured.

### tailscale serve

Share services within your tailnet.

```bash
tailscale serve [flags] <target>
```

**Target formats:**

- Port: `3000`
- URL: `http://localhost:3000`
- Path: `https+insecure://localhost:8443`
- File: `/var/www/html/index.html`
- Directory: `/var/www/html`
- Text: `text:"Hello World"`

**Flags:**

| Flag | Description |
|------|-------------|
| `--https=<port>` | HTTPS port (443, 8443, 10000) |
| `--set-path=<path>` | URL path to serve on |
| `--tls-terminated-tcp=<port>` | TCP forwarding with TLS termination |
| `--bg` | Run in background (default for Tailscale Services) |

**Examples:**

```bash
# Serve web app on port 3000
tailscale serve 3000

# Serve on custom path
tailscale serve --https=443 --set-path=/api 8080

# Serve static files
tailscale serve --https=443 /var/www/html

# Serve directory with custom path
tailscale serve --https=443 --set-path=/docs /usr/share/doc

# TCP forwarding (e.g., PostgreSQL)
tailscale serve --tls-terminated-tcp=5432 localhost:5432

# Check what's serving
tailscale serve status

# Turn off specific service
tailscale serve --https=443 --set-path=/api off

# Turn off all
tailscale serve off
```

### tailscale funnel

Share services publicly on the internet.

```bash
tailscale funnel [flags] <target>
```

Same syntax as `serve`, but accessible from public internet.

**Restrictions:**

- Must use allowed ports: 443, 8443, or 10000
- Must be enabled in admin console (Funnel feature)

**Examples:**

```bash
# Share web app publicly
tailscale funnel 3000

# Access at: https://machine-name.tailnet-name.ts.net

# Turn off
tailscale funnel off
```

## File Transfer

### tailscale file

Send and receive files via Taildrop.

```bash
tailscale file cp <files...> <target>
tailscale file get <directory>
```

**Examples:**

```bash
# Send file to another device
tailscale file cp document.pdf laptop:

# Send to specific directory (if Taildrop configured)
tailscale file cp *.jpg phone:/photos

# Receive files
tailscale file get ~/Downloads
```

## Advanced/Debug Commands

### tailscale netcheck

Test network connectivity and DERP relay access.

```bash
tailscale netcheck
```

Shows:

- UDP connectivity
- DERP relay latencies
- NAT type
- Preferred DERP region

### tailscale debug

Various debugging commands.

```bash
# Stream daemon logs
tailscale debug daemon-logs

# View network map
tailscale debug netmap

# Watch connection changes
tailscale debug watch-ipn

# Generate bug report
tailscale bugreport
```

### tailscale cert

Get TLS certificates for MagicDNS names.

```bash
tailscale cert [flags] <domain>
```

**Examples:**

```bash
# Get cert for MagicDNS hostname
tailscale cert machine-name.tailnet-name.ts.net

# Output to specific location
tailscale cert --cert-file=cert.pem --key-file=key.pem machine-name.ts.net
```

### tailscale lock

Manage Tailnet Lock (cryptographic device authorization).

```bash
# Check Tailnet Lock status
tailscale lock status

# Initialize Tailnet Lock
sudo tailscale lock init

# Add trusted signing key
sudo tailscale lock add <key>

# Remove signing key
sudo tailscale lock remove <key>
```

## System Management

### tailscale logout

Remove device from tailnet.

```bash
tailscale logout
```

Requires re-authentication to rejoin.

### tailscale switch

Switch between Tailscale accounts (fast user switching).

```bash
# List accounts
tailscale switch --list

# Switch to account
tailscale switch <account>
```

### tailscale update

Update Tailscale client.

```bash
tailscale update
```

Available on Windows, macOS, and some Linux distributions.

### tailscale version

Show client and daemon versions.

```bash
tailscale version
```

## Automation & CI/CD

### Auth Keys for Unattended Setup

Generate in admin console → Settings → Keys

```bash
# One-time use
sudo tailscale up --auth-key=tskey-auth-...

# Reusable key
sudo tailscale up --auth-key=tskey-auth-...-...

# With tags (for service accounts)
sudo tailscale up --auth-key=tskey-auth-... --advertise-tags=tag:ci
```

### OAuth API Access

For API automation:

```bash
# Use OAuth client credentials
curl -u "$CLIENT_ID:$CLIENT_SECRET" \
  https://api.tailscale.com/api/v2/tailnet/$TAILNET/devices
```

## Platform-Specific Notes

### Linux

- Most commands require `sudo` for system changes
- Daemon: `sudo systemctl status tailscaled`
- Logs: `journalctl -u tailscaled`
- Config: `/etc/default/tailscaled` (for daemon flags)

### macOS

- GUI and CLI available
- Menu bar app for easy control
- Keychain integration for auth

### Windows

- GUI application
- CLI available: `tailscale.exe`
- Service management: `net start/stop Tailscale`

### Docker/Containers

```bash
# Run as container
docker run -d \
  --name=tailscale \
  --cap-add=NET_ADMIN \
  --device=/dev/net/tun \
  -e TS_AUTH_KEY=tskey-auth-... \
  -e TS_ROUTES=192.168.1.0/24 \
  tailscale/tailscale
```

## Exit Codes

| Code | Meaning |
|------|---------|
| 0 | Success |
| 1 | Generic error |
| 2 | Invalid arguments |
| 3 | Not connected to Tailscale |
