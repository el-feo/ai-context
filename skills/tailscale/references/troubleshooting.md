# Tailscale Troubleshooting Guide

Comprehensive troubleshooting for common Tailscale issues.

## Quick Diagnostics

```bash
# Check Tailscale status
tailscale status

# Test network connectivity
tailscale netcheck

# View detailed connection info
tailscale status --json | jq

# Check daemon logs
tailscale debug daemon-logs
```

## Connection Issues

### Devices Not Seeing Each Other

**Symptoms:** Device doesn't appear in `tailscale status` on other devices.

**Diagnosis:**

```bash
# On the missing device, check if connected
tailscale status

# Check if logged in
tailscale status | grep "logged in"
```

**Solutions:**

1. **Not logged in:**
   ```bash
   sudo tailscale up
   ```

2. **Daemon not running:**
   ```bash
   # Linux (systemd)
   sudo systemctl status tailscaled
   sudo systemctl start tailscaled
   
   # macOS
   # Restart Tailscale app
   
   # Windows
   net start Tailscale
   ```

3. **Different tailnets:**
   - Check which tailnet each device is on
   - Ensure all devices use same identity provider

### Can't Reach Other Devices

**Symptoms:** Devices visible but cannot ping/connect.

**Diagnosis:**

```bash
# Test connectivity layers
tailscale ping --tsmp target   # Tests WireGuard connection
tailscale ping --icmp target   # Tests with ACLs
ping $(tailscale ip -4 target) # Tests routing
```

**Interpretation:**

| TSMP | ICMP | Regular Ping | Issue |
|------|------|--------------|-------|
| ✅ | ❌ | ❌ | ACL blocking |
| ✅ | ✅ | ❌ | OS firewall |
| ❌ | ❌ | ❌ | Network/NAT |

**Solutions:**

1. **ACL blocking (TSMP ✅, ICMP ❌):**
   - Check ACL policy in admin console
   - Add rule allowing src → dst
   ```json
   {
     "grants": [{
       "src": ["user@example.com"],
       "dst": ["target-device"],
       "ip": ["*"]
     }]
   }
   ```

2. **OS firewall (ICMP ✅, ping ❌):**
   ```bash
   # Linux
   sudo ufw allow from 100.0.0.0/8
   sudo ufw allow from fd7a:115c:a1e0::/48
   
   # macOS
   # System Preferences → Security & Privacy → Firewall
   # Add Tailscale to allowed applications
   ```

3. **Using DERP relay (slow):**
   ```bash
   tailscale status | grep relay
   ```
   
   Check if direct connection possible:
   ```bash
   tailscale netcheck
   ```
   
   Fix firewall/NAT to allow UDP:
   - UDP port 41641
   - Or enable UPnP/NAT-PMP on router

## Subnet Router Issues

### Routes Not Working

**Symptoms:** Can't reach devices behind subnet router.

**Diagnosis:**

```bash
# On subnet router
cat /proc/sys/net/ipv4/ip_forward  # Should be 1

# Check advertised routes
tailscale status | grep "offers routes"

# Check if routes approved in admin console
# Admin Console → Machines → subnet router → Route settings
```

**Solutions:**

1. **IP forwarding not enabled:**
   ```bash
   # Enable permanently
   echo 'net.ipv4.ip_forward = 1' | sudo tee -a /etc/sysctl.d/99-tailscale.conf
   echo 'net.ipv6.conf.all.forwarding = 1' | sudo tee -a /etc/sysctl.d/99-tailscale.conf
   sudo sysctl -p /etc/sysctl.d/99-tailscale.conf
   ```

2. **Routes not approved:**
   - Go to admin console → Machines
   - Find subnet router
   - Click menu → "Edit route settings"
   - Enable the routes

3. **Client not accepting routes (Linux):**
   ```bash
   sudo tailscale set --accept-routes
   ```

4. **Firewall blocking forwarding:**
   ```bash
   # Check iptables
   sudo iptables -L FORWARD -v -n
   
   # Add rules if needed
   sudo iptables -I FORWARD -i tailscale0 -j ACCEPT
   sudo iptables -I FORWARD -o tailscale0 -j ACCEPT
   ```

5. **NAT issues:**
   ```bash
   # Check if SNAT enabled (default)
   tailscale status | grep snat
   
   # If disabled and having issues, re-enable
   sudo tailscale set --advertise-routes=192.168.1.0/24 --snat-subnet-routes=true
   ```

### Asymmetric Routing

**Symptoms:** Connections to subnet devices timeout.

**Cause:** Return traffic not going through Tailscale.

**Solution:**

```bash
# Option 1: Enable SNAT (recommended)
sudo tailscale up --advertise-routes=192.168.1.0/24 --snat-subnet-routes=true

# Option 2: Add static routes on subnet devices
# Point Tailscale CGNAT (100.64.0.0/10) to subnet router's LAN IP
ip route add 100.64.0.0/10 via 192.168.1.1
```

## Exit Node Issues

### Can't Connect to Internet via Exit Node

**Diagnosis:**

```bash
# Check exit node active
tailscale status | grep "exit node"

# Test DNS
nslookup google.com

# Test connectivity
curl -v https://ifconfig.me
```

**Solutions:**

1. **Exit node not approved:**
   - Admin console → Machines → exit node
   - "Edit route settings" → "Use as exit node"

2. **IP forwarding not enabled** (on exit node):
   ```bash
   # Same as subnet router
   echo 'net.ipv4.ip_forward = 1' | sudo tee -a /etc/sysctl.d/99-tailscale.conf
   sudo sysctl -p /etc/sysctl.d/99-tailscale.conf
   ```

3. **NAT not working** (on exit node):
   ```bash
   # Check NAT rules
   sudo iptables -t nat -L POSTROUTING -v -n
   
   # Tailscale usually handles this, but if issues:
   INTERFACE=$(ip route | grep default | awk '{print $5}')
   sudo iptables -t nat -A POSTROUTING -o $INTERFACE -j MASQUERADE
   ```

4. **DNS resolution failing:**
   ```bash
   # Enable LAN access to use local DNS
   tailscale set --exit-node=exit-node-name --exit-node-allow-lan-access
   ```

## Tailscale SSH Issues

### SSH Not Working

**Diagnosis:**

```bash
# On server, check SSH enabled
tailscale status | grep ssh

# Check ACL allows SSH
# Admin console → Access Controls → Preview rules

# Test different ways
ssh machine-name
ssh 100.x.y.z
ssh -v machine-name  # Verbose mode
```

**Solutions:**

1. **SSH not enabled on server:**
   ```bash
   sudo tailscale set --ssh
   ```

2. **ACL doesn't allow SSH:**
   Need both network access AND SSH rule:
   ```json
   {
     "grants": [{
       "src": ["user@example.com"],
       "dst": ["server"],
       "ip": ["22"]
     }],
     "ssh": [{
       "action": "accept",
       "src": ["user@example.com"],
       "dst": ["server"],
       "users": ["ubuntu"]
     }]
   }
   ```

3. **Wrong SSH user:**
   - Check allowed users in SSH ACL
   - Try: `ssh specific-user@machine-name`

4. **Port 22 occupied by regular SSH:**
   - Tailscale SSH only intercepts Tailscale IP
   - Ensure connecting to Tailscale IP/hostname
   ```bash
   # Not this (uses LAN/public IP)
   ssh user@192.168.1.10
   
   # Use this (uses Tailscale)
   ssh user@machine-name
   ssh user@100.x.y.z
   ```

### Check Mode Re-auth Not Working

**Symptoms:** Can't SSH with check mode even after re-auth.

**Solutions:**

1. **Re-authenticate explicitly:**
   ```bash
   # On client
   tailscale logout
   tailscale up
   ```

2. **Check session timeout:**
   - Default: 90 days
   - May need to re-auth if session expired

## MagicDNS Issues

### Hostnames Not Resolving

**Diagnosis:**

```bash
# Check MagicDNS enabled
tailscale status | grep MagicDNS

# Test resolution
nslookup machine-name
dig machine-name

# Check if resolving via Tailscale
scutil --dns | grep 100.100.100.100  # macOS
resolvectl status | grep 100.100.100.100  # Linux
```

**Solutions:**

1. **MagicDNS not enabled:**
   - Admin console → DNS → Enable MagicDNS

2. **DNS cache stale:**
   ```bash
   # macOS
   sudo dscacheutil -flushcache
   sudo killall -HUP mDNSResponder
   
   # Linux (systemd-resolved)
   sudo systemd-resolve --flush-caches
   
   # Windows
   ipconfig /flushdns
   ```

3. **Name conflicts:**
   - Avoid duplicate hostnames
   - Rename devices in admin console

4. **Search domain not configured:**
   - Use full hostname: `machine-name.tailnet-name.ts.net`

## Performance Issues

### High Latency / Slow Connections

**Diagnosis:**

```bash
# Check connection type
tailscale status | grep -E "direct|relay"

# Test network path
tailscale netcheck

# Measure actual latency
tailscale ping target
```

**Solutions:**

1. **Using DERP relay unnecessarily:**
   - Check firewall allows UDP 41641
   - Enable UPnP/NAT-PMP on router
   - Check with: `tailscale netcheck`

2. **Suboptimal DERP relay:**
   - Tailscale auto-selects nearest
   - Check latencies: `tailscale netcheck`
   - Consider custom DERP server for better performance

3. **MTU issues:**
   ```bash
   # Test MTU
   ping -M do -s 1400 $(tailscale ip -4 target)
   
   # If failing, reduce MTU
   ip link set dev tailscale0 mtu 1280
   ```

4. **CPU overhead (subnet router/exit node):**
   ```bash
   # Enable UDP GRO forwarding (Linux)
   NETDEV=$(ip -o route get 8.8.8.8 | cut -f 5 -d " ")
   sudo ethtool -K $NETDEV rx-udp-gro-forwarding on rx-gro-list off
   ```

## Key Expiry Issues

### Unexpected Disconnections

**Symptoms:** Device disconnects after 90/180 days.

**Cause:** Machine key expired.

**Solutions:**

1. **Disable key expiry:**
   - Admin console → Machines → device → "Disable key expiry"

2. **Automate re-auth:**
   ```bash
   # Cron job to re-authenticate
   0 0 * * * tailscale up --force-reauth
   ```

3. **Use reusable auth keys:**
   ```bash
   # Generate in admin console
   sudo tailscale up --auth-key=tskey-auth-...
   ```

## Logging and Debugging

### Enable Verbose Logging

```bash
# Stream daemon logs
tailscale debug daemon-logs

# Linux (systemd)
journalctl -u tailscaled -f

# macOS
log stream --predicate 'subsystem == "com.tailscale.ipn"' --level debug

# Windows
# Check: C:\ProgramData\Tailscale\Logs
```

### Generate Bug Report

```bash
tailscale bugreport

# Includes:
# - Network configuration
# - Peer connections
# - Error logs
# - System info (redacted)
```

### Debug Specific Issues

```bash
# View network map
tailscale debug netmap

# Watch IPN notifications
tailscale debug watch-ipn

# Check firewall rules
tailscale debug firewall

# View DERP connectivity
tailscale debug derp
```

## Common Error Messages

### "tailscaled.service is not running"

```bash
sudo systemctl start tailscaled
sudo systemctl enable tailscaled
```

### "Login expired"

```bash
tailscale up  # Will prompt for re-auth
```

### "Coordination server unreachable"

- Check internet connectivity
- Check if firewalls block controlplane.tailscale.com (443/TCP)
- Try: `tailscale netcheck`

### "No matching route"

- ACL policy blocks connection
- Check: Admin console → Access Controls → Preview rules

## Getting Help

1. **Check status page**: https://status.tailscale.com
2. **Search docs**: https://tailscale.com/kb
3. **Community forum**: https://forum.tailscale.com
4. **File bug report**: `tailscale bugreport` then contact support
5. **GitHub issues**: https://github.com/tailscale/tailscale/issues

## Preventive Measures

✅ **Monitor key expiry dates**
✅ **Test ACL changes in dev environment first**
✅ **Document custom network configurations**
✅ **Keep Tailscale updated**: `tailscale update`
✅ **Set up health checks for critical nodes**
✅ **Use tags for infrastructure devices**
✅ **Enable audit logging (Enterprise)**
