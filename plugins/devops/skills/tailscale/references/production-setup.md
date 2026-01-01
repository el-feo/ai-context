# Tailscale Production Deployment Best Practices

Enterprise-grade setup and operational practices for Tailscale.

## Architecture Patterns

### Hub-and-Spoke (Subnet Routers)

```
Internet ─┐
          ├─ Exit Node (cloud)
          │
Tailnet ──┼── Subnet Router (Office A) ── Office A LAN (192.168.1.0/24)
          │
          ├── Subnet Router (Office B) ── Office B LAN (10.0.1.0/24)
          │
          └── Subnet Router (AWS VPC) ── AWS VPC (10.100.0.0/16)
```

**Use cases:**
- Multi-site connectivity
- Cloud resource access
- Legacy device integration

### Mesh Network (Direct Install)

```
Tailnet ──┬── Laptop (Developer)
          ├── Desktop (Home)
          ├── Phone (Mobile)
          └── Server (Tagged infrastructure)
```

**Use cases:**
- Developer access
- Remote work
- Personal devices

## Initial Setup

### 1. Plan Your Tailnet

**Identity Provider:**
- Use corporate SSO (Google Workspace, Okta, Azure AD)
- Enable SCIM if available for auto-provisioning

**Namespace:**
- Choose custom tailnet name
- Use your domain: `company.com`
- Results in: `hostname.company.com.ts.net`

**Network Design:**
- Document existing subnets
- Plan subnet router placement
- Avoid overlapping CGNAT ranges (100.64.0.0/10)

### 2. Access Control Strategy

**Start Simple:**
```json
{
  "groups": {
    "group:everyone": ["*"]
  },
  "tagOwners": {
    "tag:server": ["autogroup:admin"]
  },
  "grants": [
    {
      "src": ["autogroup:member"],
      "dst": ["autogroup:self"],
      "ip": ["*"]
    },
    {
      "src": ["autogroup:member"],
      "dst": ["tag:server"],
      "ip": ["22", "80", "443"]
    }
  ]
}
```

**Evolve to Complex:**
- Add team-specific groups
- Implement environment separation (dev/staging/prod)
- Add posture-based access
- Enable Tailnet Lock

### 3. Tagging Strategy

**Infrastructure Devices:**
```bash
# All infrastructure should use tags
sudo tailscale up --advertise-tags=tag:server,tag:production,tag:database

# Never login with personal account for servers
# Use auth keys instead
```

**Tag Naming Convention:**
```
tag:role-environment-location
Examples:
- tag:server-prod-us
- tag:db-staging-eu
- tag:router-office-sf
```

### 4. Authentication Keys

**Generate Keys:**

| Type | Use Case | Settings |
|------|----------|----------|
| Ephemeral | CI/CD, testing | Reusable: No, Ephemeral: Yes |
| Reusable | Infrastructure | Reusable: Yes, Preauth: Yes |
| One-time | Manual setup | Reusable: No, Preauth: Yes |

**Key Management:**
```bash
# Store in secrets manager
aws secretsmanager create-secret \
  --name tailscale/auth-key \
  --secret-string "$AUTH_KEY"

# Retrieve and use
AUTH_KEY=$(aws secretsmanager get-secret-value \
  --secret-id tailscale/auth-key \
  --query SecretString --output text)

sudo tailscale up --auth-key="$AUTH_KEY"
```

## High Availability

### Subnet Router HA

```bash
# Router 1
sudo tailscale up \
  --advertise-routes=10.0.0.0/24 \
  --advertise-tags=tag:subnet-router-primary

# Router 2 (same routes = automatic failover)
sudo tailscale up \
  --advertise-routes=10.0.0.0/24 \
  --advertise-tags=tag:subnet-router-secondary
```

**Failover behavior:**
- Oldest router is primary
- Failover after 15 seconds offline
- Graceful switchover on maintenance

### Exit Node HA

```bash
# Multiple exit nodes in same region
# Clients auto-failover
tailscale set --exit-node=auto:any
```

### Monitoring HA Setup

```bash
#!/bin/bash
# check-ha.sh

ROUTE="10.0.0.0/24"

# Get routers advertising this route
tailscale status --json | jq -r \
  ".Peer[] | select(.PrimaryRoutes[]? == \"$ROUTE\") | .HostName"

# Should show multiple routers
```

## Security Hardening

### 1. Enable Tailnet Lock

**What it does:** Cryptographically prevents unauthorized devices.

```bash
# Initialize on trusted device
sudo tailscale lock init

# Distribute key to other admins (offline)
# Add signing keys
sudo tailscale lock add <key>
```

### 2. Restrict Key Permissions

```json
{
  "tagOwners": {
    "tag:server": ["group:ops"],  // Only ops can tag servers
    "tag:prod": ["autogroup:admin"]  // Only admins for production
  }
}
```

### 3. Implement Posture Checks

```json
{
  "postures": {
    "posture:secure-device": [
      "node:os in ['linux', 'darwin']",
      "node:tsVersion >= '1.50.0'"
    ]
  },
  "grants": [
    {
      "src": ["group:engineering"],
      "dst": ["tag:prod"],
      "ip": ["22"],
      "capabilities": {
        "posture": ["posture:secure-device"]
      }
    }
  ]
}
```

### 4. Enable Audit Logging

**Enterprise feature:**
- Stream logs to SIEM
- Track device additions/removals
- Monitor ACL changes
- SSH session recordings

```bash
# Example: Forward to Splunk
curl -X POST \
  -u "$TS_CLIENT_ID:$TS_CLIENT_SECRET" \
  -H "Content-Type: application/json" \
  "https://api.tailscale.com/api/v2/tailnet/$TS_TAILNET/logging/stream/splunk" \
  -d '{
    "url": "https://splunk.example.com:8088",
    "token": "splunk-hec-token"
  }'
```

## Infrastructure as Code

### Terraform Complete Example

```hcl
# main.tf
terraform {
  required_providers {
    tailscale = {
      source  = "tailscale/tailscale"
      version = "~> 0.13"
    }
  }
}

provider "tailscale" {
  oauth_client_id     = var.oauth_client_id
  oauth_client_secret = var.oauth_client_secret
  tailnet             = var.tailnet
}

# Create auth key for servers
resource "tailscale_tailnet_key" "server_key" {
  reusable      = true
  ephemeral     = false
  preauthorized = true
  tags          = ["tag:server"]
  description   = "Production servers"
}

# ACL policy
resource "tailscale_acl" "main" {
  acl = jsonencode({
    groups = {
      "group:engineering" = var.engineering_users
      "group:ops"         = var.ops_users
    }
    tagOwners = {
      "tag:server" = ["group:ops"]
      "tag:dev"    = ["group:engineering"]
    }
    grants = [
      {
        src = ["group:engineering"]
        dst = ["tag:dev"]
        ip  = ["*"]
      },
      {
        src = ["group:ops"]
        dst = ["tag:server"]
        ip  = ["22", "443"]
      }
    ]
  })
}

# DNS settings
resource "tailscale_dns_nameservers" "main" {
  nameservers = ["1.1.1.1", "8.8.8.8"]
}

resource "tailscale_dns_search_paths" "main" {
  search_paths = [var.domain]
}

# Output keys for use in provisioning
output "server_auth_key" {
  value     = tailscale_tailnet_key.server_key.key
  sensitive = true
}
```

### Ansible Playbook

```yaml
# tailscale.yml
---
- name: Setup Tailscale Subnet Router
  hosts: routers
  become: yes
  
  vars:
    tailscale_auth_key: "{{ lookup('env', 'TS_AUTH_KEY') }}"
    advertised_routes: "{{ subnet_cidr }}"
    
  tasks:
    - name: Install Tailscale
      shell: curl -fsSL https://tailscale.com/install.sh | sh
      args:
        creates: /usr/bin/tailscale
    
    - name: Enable IP forwarding
      sysctl:
        name: "{{ item }}"
        value: "1"
        sysctl_file: /etc/sysctl.d/99-tailscale.conf
        reload: yes
      loop:
        - net.ipv4.ip_forward
        - net.ipv6.conf.all.forwarding
    
    - name: Configure Tailscale
      command: >
        tailscale up
        --auth-key={{ tailscale_auth_key }}
        --advertise-routes={{ advertised_routes }}
        --advertise-tags=tag:subnet-router
        --hostname={{ inventory_hostname }}
      register: result
      changed_when: "'Success' in result.stdout"
    
    - name: Disable key expiry
      uri:
        url: "https://api.tailscale.com/api/v2/device/{{ device_id }}"
        method: POST
        body_format: json
        body:
          keyExpiryDisabled: true
        headers:
          Authorization: "Bearer {{ tailscale_api_key }}"
```

### Kubernetes Operator

```yaml
# subnet-router-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: tailscale-router
spec:
  replicas: 2  # HA
  selector:
    matchLabels:
      app: tailscale-router
  template:
    metadata:
      labels:
        app: tailscale-router
    spec:
      serviceAccountName: tailscale
      containers:
      - name: tailscale
        image: tailscale/tailscale:latest
        env:
        - name: TS_AUTH_KEY
          valueFrom:
            secretKeyRef:
              name: tailscale
              key: auth-key
        - name: TS_ROUTES
          value: "10.0.0.0/8"
        - name: TS_USERSPACE
          value: "true"
        securityContext:
          capabilities:
            add:
            - NET_ADMIN
```

## Monitoring and Observability

### Health Checks

```bash
#!/bin/bash
# healthcheck.sh

set -e

# Check daemon running
systemctl is-active --quiet tailscaled

# Check logged in
tailscale status >/dev/null 2>&1

# Check specific connectivity
tailscale ping --c 1 --timeout 5s critical-service

echo "OK"
```

### Prometheus Metrics

```yaml
# prometheus.yml
scrape_configs:
  - job_name: 'tailscale'
    static_configs:
      - targets: ['localhost:9090']
    metric_relabel_configs:
      - source_labels: [__name__]
        regex: 'tailscale_.*'
        action: keep
```

**Export via API:**
```python
#!/usr/bin/env python3
from prometheus_client import start_http_server, Gauge
from tailscale import Tailscale
import time

# Metrics
device_count = Gauge('tailscale_devices_total', 'Total devices')
device_online = Gauge('tailscale_devices_online', 'Online devices')

ts = Tailscale(api_key="tskey-api-...")

def collect():
    devices = ts.devices()
    device_count.set(len(devices))
    device_online.set(sum(1 for d in devices if d['online']))

if __name__ == '__main__':
    start_http_server(9090)
    while True:
        collect()
        time.sleep(60)
```

### Log Aggregation

```bash
# Ship logs to centralized logging
journalctl -u tailscaled -f --output json | \
  filebeat -c filebeat.yml
```

## Disaster Recovery

### Backup Critical Data

```bash
#!/bin/bash
# backup-tailscale.sh

BACKUP_DIR="/var/backups/tailscale"
DATE=$(date +%Y%m%d)

mkdir -p "$BACKUP_DIR"

# Export ACL policy
curl -u "$TS_CLIENT_ID:$TS_CLIENT_SECRET" \
  "https://api.tailscale.com/api/v2/tailnet/$TS_TAILNET/acl" \
  > "$BACKUP_DIR/acl-$DATE.json"

# Export device list
curl -u "$TS_CLIENT_ID:$TS_CLIENT_SECRET" \
  "https://api.tailscale.com/api/v2/tailnet/$TS_TAILNET/devices" \
  > "$BACKUP_DIR/devices-$DATE.json"

# Compress old backups
find "$BACKUP_DIR" -name "*.json" -mtime +7 -exec gzip {} \;
```

### Runbook Template

```markdown
# Tailscale Incident Response

## Severity 1: Complete Outage
1. Check https://status.tailscale.com
2. Verify internet connectivity
3. Check firewall rules for controlplane.tailscale.com
4. Review recent ACL changes (revert if needed)
5. Contact Tailscale support

## Severity 2: Partial Outage
1. Identify affected devices: `tailscale status`
2. Check DERP relay status: `tailscale netcheck`
3. Verify subnet router health
4. Review recent changes
5. Test ACL with `tailscale ping --icmp`

## Severity 3: Performance Degradation
1. Check if using DERP relay unnecessarily
2. Verify MTU settings
3. Monitor CPU/bandwidth on routers
4. Review routing configuration
```

## Operational Procedures

### Onboarding New User

1. **Add to IdP group** (auto-syncs to Tailscale)
2. **Send setup guide:**
   - Install Tailscale
   - Login with SSO
   - Verify connectivity

3. **Verify access:**
   ```bash
   # Admin checks
   tailscale status | grep new-user
   ```

### Offboarding User

1. **Remove from IdP** (auto-removes from Tailscale)
2. **Manually verify:**
   ```bash
   # Check user's devices removed
   curl -u "$TS_CLIENT_ID:$TS_CLIENT_SECRET" \
     "https://api.tailscale.com/api/v2/tailnet/$TS_TAILNET/devices" \
     | jq '.devices[] | select(.user == "user@example.com")'
   ```
3. **Audit logs** for recent activity

### Rotating Auth Keys

```bash
#!/bin/bash
# rotate-keys.sh

# Generate new key
NEW_KEY=$(curl -X POST \
  -u "$TS_CLIENT_ID:$TS_CLIENT_SECRET" \
  -H "Content-Type: application/json" \
  "https://api.tailscale.com/api/v2/tailnet/$TS_TAILNET/keys" \
  -d '{"capabilities": {"devices": {"create": {"reusable": true}}}}' \
  | jq -r '.key')

# Update secrets manager
aws secretsmanager update-secret \
  --secret-id tailscale/auth-key \
  --secret-string "$NEW_KEY"

# Revoke old key (after updating all systems)
curl -X DELETE \
  -u "$TS_CLIENT_ID:$TS_CLIENT_SECRET" \
  "https://api.tailscale.com/api/v2/tailnet/$TS_TAILNET/keys/$OLD_KEY_ID"
```

## Performance Tuning

### Subnet Router Optimization

```bash
# Enable UDP GRO forwarding (Linux)
NETDEV=$(ip -o route get 8.8.8.8 | cut -f 5 -d " ")
sudo ethtool -K $NETDEV rx-udp-gro-forwarding on rx-gro-list off

# Make persistent
echo '#!/bin/sh' | sudo tee /etc/networkd-dispatcher/routable.d/50-tailscale
echo "ethtool -K $NETDEV rx-udp-gro-forwarding on rx-gro-list off" | \
  sudo tee -a /etc/networkd-dispatcher/routable.d/50-tailscale
sudo chmod 755 /etc/networkd-dispatcher/routable.d/50-tailscale
```

### Kernel Network Stack Tuning

```bash
# /etc/sysctl.d/99-tailscale-perf.conf
net.core.rmem_max = 26214400
net.core.rmem_default = 26214400
net.core.wmem_max = 26214400
net.core.wmem_default = 26214400
net.core.netdev_max_backlog = 5000
```

## Compliance and Governance

### Audit Trail

- Enable Enterprise audit logging
- Track all ACL changes via GitOps
- Record SSH sessions (Enterprise feature)
- Monitor device additions/removals

### Documentation Requirements

✅ **Network diagram** with subnet routers
✅ **ACL policy** with rationale
✅ **Tag taxonomy** and ownership
✅ **Incident response runbook**
✅ **DR procedures** and RTO/RPO
✅ **Contact list** for escalations

### Periodic Reviews

- **Monthly:** Review active devices, remove stale
- **Quarterly:** Audit ACL policy
- **Annually:** Rotate OAuth credentials
- **After incidents:** Update runbooks

## Cost Optimization

**Device counting:**
- Personal devices count per plan limits
- Devices behind subnet routers DON'T count
- Tagged infrastructure doesn't count toward free tier

**Strategy:**
- Use subnet routers for legacy systems
- Tag all infrastructure properly
- Remove inactive devices monthly
