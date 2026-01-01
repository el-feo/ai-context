# Tailscale API Usage Guide

Complete guide for automating Tailscale management via the REST API.

## Authentication

### OAuth Clients (Recommended)

**Create OAuth client** in admin console → Settings → OAuth clients

```bash
# Store credentials
export TS_CLIENT_ID="your-client-id"
export TS_CLIENT_SECRET="your-secret"
export TS_TAILNET="example.com"

# Make API calls
curl -u "$TS_CLIENT_ID:$TS_CLIENT_SECRET" \
  "https://api.tailscale.com/api/v2/tailnet/$TS_TAILNET/devices"
```

### API Keys (Legacy)

Generate in admin console → Settings → Keys → Generate API key

```bash
export TS_API_KEY="tskey-api-..."
export TS_TAILNET="example.com"

curl -H "Authorization: Bearer $TS_API_KEY" \
  "https://api.tailscale.com/api/v2/tailnet/$TS_TAILNET/devices"
```

## Common Operations

### List Devices

```bash
curl -u "$TS_CLIENT_ID:$TS_CLIENT_SECRET" \
  "https://api.tailscale.com/api/v2/tailnet/$TS_TAILNET/devices" \
  | jq '.devices[] | {name, addresses, os}'
```

### Get Device Details

```bash
DEVICE_ID="12345"

curl -u "$TS_CLIENT_ID:$TS_CLIENT_SECRET" \
  "https://api.tailscale.com/api/v2/device/$DEVICE_ID"
```

### Delete Device

```bash
curl -X DELETE \
  -u "$TS_CLIENT_ID:$TS_CLIENT_SECRET" \
  "https://api.tailscale.com/api/v2/device/$DEVICE_ID"
```

### Set Device Tags

```bash
curl -X POST \
  -u "$TS_CLIENT_ID:$TS_CLIENT_SECRET" \
  -H "Content-Type: application/json" \
  "https://api.tailscale.com/api/v2/device/$DEVICE_ID/tags" \
  -d '{"tags": ["tag:server", "tag:production"]}'
```

### Update Device Settings

```bash
curl -X POST \
  -u "$TS_CLIENT_ID:$TS_CLIENT_SECRET" \
  -H "Content-Type: application/json" \
  "https://api.tailscale.com/api/v2/device/$DEVICE_ID" \
  -d '{
    "keyExpiryDisabled": true,
    "updateAvailable": false
  }'
```

### Generate Auth Key

```bash
curl -X POST \
  -u "$TS_CLIENT_ID:$TS_CLIENT_SECRET" \
  -H "Content-Type: application/json" \
  "https://api.tailscale.com/api/v2/tailnet/$TS_TAILNET/keys" \
  -d '{
    "capabilities": {
      "devices": {
        "create": {
          "reusable": true,
          "ephemeral": false,
          "preauthorized": true,
          "tags": ["tag:server"]
        }
      }
    },
    "expirySeconds": 86400
  }'
```

## ACL Management

### Get ACL Policy

```bash
curl -u "$TS_CLIENT_ID:$TS_CLIENT_SECRET" \
  "https://api.tailscale.com/api/v2/tailnet/$TS_TAILNET/acl"
```

### Update ACL Policy

```bash
curl -X POST \
  -u "$TS_CLIENT_ID:$TS_CLIENT_SECRET" \
  -H "Content-Type: application/json" \
  "https://api.tailscale.com/api/v2/tailnet/$TS_TAILNET/acl" \
  --data @acl-policy.json
```

### Validate ACL Without Applying

```bash
curl -X POST \
  -u "$TS_CLIENT_ID:$TS_CLIENT_SECRET" \
  -H "Content-Type: application/json" \
  "https://api.tailscale.com/api/v2/tailnet/$TS_TAILNET/acl/validate" \
  --data @acl-policy.json
```

## DNS Management

### Get DNS Configuration

```bash
curl -u "$TS_CLIENT_ID:$TS_CLIENT_SECRET" \
  "https://api.tailscale.com/api/v2/tailnet/$TS_TAILNET/dns/preferences"
```

### Update DNS Settings

```bash
curl -X POST \
  -u "$TS_CLIENT_ID:$TS_CLIENT_SECRET" \
  -H "Content-Type: application/json" \
  "https://api.tailscale.com/api/v2/tailnet/$TS_TAILNET/dns/preferences" \
  -d '{
    "magicDNS": true
  }'
```

### Manage DNS Nameservers

```bash
curl -X POST \
  -u "$TS_CLIENT_ID:$TS_CLIENT_SECRET" \
  -H "Content-Type: application/json" \
  "https://api.tailscale.com/api/v2/tailnet/$TS_TAILNET/dns/nameservers" \
  -d '{
    "dns": ["1.1.1.1", "8.8.8.8"]
  }'
```

## Terraform Provider

### Provider Setup

```hcl
terraform {
  required_providers {
    tailscale = {
      source  = "tailscale/tailscale"
      version = "~> 0.13"
    }
  }
}

provider "tailscale" {
  api_key = var.tailscale_api_key
  tailnet = var.tailnet
}
```

### Create Auth Key

```hcl
resource "tailscale_tailnet_key" "server_key" {
  reusable      = true
  ephemeral     = false
  preauthorized = true
  tags          = ["tag:server"]
  
  expiry = 3600
}

output "auth_key" {
  value     = tailscale_tailnet_key.server_key.key
  sensitive = true
}
```

### Manage ACL

```hcl
resource "tailscale_acl" "main" {
  acl = jsonencode({
    groups = {
      "group:engineering" = ["alice@example.com"]
    }
    tagOwners = {
      "tag:server" = ["group:engineering"]
    }
    grants = [
      {
        src = ["group:engineering"]
        dst = ["tag:server"]
        ip  = ["*"]
      }
    ]
  })
}
```

### Define DNS Records

```hcl
resource "tailscale_dns_nameservers" "main" {
  nameservers = ["1.1.1.1", "8.8.8.8"]
}

resource "tailscale_dns_search_paths" "main" {
  search_paths = ["example.com"]
}
```

## Python SDK

### Installation

```bash
pip install tailscale
```

### Basic Usage

```python
from tailscale import Tailscale

# Initialize client
ts = Tailscale(
    api_key="tskey-api-...",
    tailnet="example.com"
)

# List devices
devices = ts.devices()
for device in devices:
    print(f"{device['hostname']}: {device['addresses']}")

# Get device by name
device = ts.device_by_name("myserver")

# Delete device
ts.delete_device(device['id'])

# Create auth key
key = ts.create_auth_key(
    reusable=True,
    ephemeral=False,
    preauthorized=True,
    tags=["tag:server"]
)
print(f"Auth key: {key['key']}")
```

## Automation Examples

### Automated Device Provisioning

```bash
#!/bin/bash
# provision-server.sh

set -e

# Generate ephemeral auth key
AUTH_KEY=$(curl -s -X POST \
  -u "$TS_CLIENT_ID:$TS_CLIENT_SECRET" \
  -H "Content-Type: application/json" \
  "https://api.tailscale.com/api/v2/tailnet/$TS_TAILNET/keys" \
  -d '{
    "capabilities": {
      "devices": {
        "create": {
          "ephemeral": true,
          "preauthorized": true,
          "tags": ["tag:ci"]
        }
      }
    },
    "expirySeconds": 3600
  }' | jq -r '.key')

# Install and connect
curl -fsSL https://tailscale.com/install.sh | sh
sudo tailscale up --auth-key="$AUTH_KEY" --advertise-tags=tag:ci

echo "Device connected to tailnet"
```

### Inventory Management

```python
#!/usr/bin/env python3
import json
from datetime import datetime, timedelta
from tailscale import Tailscale

ts = Tailscale(api_key="tskey-api-...", tailnet="example.com")

# Find stale devices (offline >30 days)
threshold = datetime.now() - timedelta(days=30)

stale_devices = []
for device in ts.devices():
    last_seen = datetime.fromisoformat(device['lastSeen'].replace('Z', '+00:00'))
    if last_seen < threshold:
        stale_devices.append({
            'name': device['hostname'],
            'last_seen': last_seen.isoformat(),
            'id': device['id']
        })

print(f"Found {len(stale_devices)} stale devices")
print(json.dumps(stale_devices, indent=2))

# Optional: Delete them
# for device in stale_devices:
#     ts.delete_device(device['id'])
```

### GitOps ACL Workflow

```yaml
# .github/workflows/tailscale-acl.yml
name: Update Tailscale ACL

on:
  push:
    paths:
      - 'acl.json'
    branches:
      - main

jobs:
  update-acl:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Validate ACL
        env:
          TS_CLIENT_ID: ${{ secrets.TS_CLIENT_ID }}
          TS_CLIENT_SECRET: ${{ secrets.TS_CLIENT_SECRET }}
          TS_TAILNET: ${{ secrets.TS_TAILNET }}
        run: |
          curl -X POST \
            -u "$TS_CLIENT_ID:$TS_CLIENT_SECRET" \
            -H "Content-Type: application/json" \
            "https://api.tailscale.com/api/v2/tailnet/$TS_TAILNET/acl/validate" \
            --data @acl.json || exit 1
      
      - name: Apply ACL
        env:
          TS_CLIENT_ID: ${{ secrets.TS_CLIENT_ID }}
          TS_CLIENT_SECRET: ${{ secrets.TS_CLIENT_SECRET }}
          TS_TAILNET: ${{ secrets.TS_TAILNET }}
        run: |
          curl -X POST \
            -u "$TS_CLIENT_ID:$TS_CLIENT_SECRET" \
            -H "Content-Type: application/json" \
            "https://api.tailscale.com/api/v2/tailnet/$TS_TAILNET/acl" \
            --data @acl.json
      
      - name: Notify
        run: echo "ACL updated successfully"
```

## Webhooks

### Configure Webhook

```bash
curl -X POST \
  -u "$TS_CLIENT_ID:$TS_CLIENT_SECRET" \
  -H "Content-Type: application/json" \
  "https://api.tailscale.com/api/v2/webhooks" \
  -d '{
    "endpointUrl": "https://your-server.com/webhook",
    "providerType": "slack",
    "subscriptions": ["nodeCreated", "nodeDeleted"]
  }'
```

### Webhook Events

Available event types:
- `nodeCreated` - Device added to tailnet
- `nodeDeleted` - Device removed
- `nodeApprovalChanged` - Device approval status changed
- `nodeKeyExpiringInOneDay` - Key expiring soon
- `nodeKeyExpired` - Key has expired
- `userCreated` - New user added
- `userDeleted` - User removed
- `userSuspended` - User suspended
- `userRestored` - User un-suspended
- `policyUpdate` - ACL policy changed
- `exitNodeSuggestionChanged` - Recommended exit node changed

### Process Webhook

```python
from flask import Flask, request
import hmac
import hashlib

app = Flask(__name__)

WEBHOOK_SECRET = "your-webhook-secret"

@app.route('/webhook', methods=['POST'])
def handle_webhook():
    # Verify signature
    signature = request.headers.get('Tailscale-Webhook-Signature')
    body = request.get_data()
    
    expected = hmac.new(
        WEBHOOK_SECRET.encode(),
        body,
        hashlib.sha256
    ).hexdigest()
    
    if signature != expected:
        return 'Invalid signature', 401
    
    # Process event
    event = request.json
    print(f"Event: {event['type']}")
    print(f"Data: {event['data']}")
    
    return 'OK', 200
```

## Rate Limits

- 120 requests per minute per API key
- Exponential backoff recommended for failures

## Best Practices

✅ **Use OAuth clients** instead of API keys for better security
✅ **Scope OAuth clients** to minimum required permissions
✅ **Rotate credentials** regularly
✅ **Validate ACLs** before applying
✅ **Use webhooks** for event-driven automation
✅ **Implement retry logic** with exponential backoff
✅ **Log API calls** for audit trail
✅ **Version control** ACL policies
✅ **Test in dev** before applying to production

## Error Handling

```python
import requests
from requests.adapters import HTTPAdapter
from requests.packages.urllib3.util.retry import Retry

def get_tailscale_session():
    session = requests.Session()
    
    # Retry with exponential backoff
    retry = Retry(
        total=5,
        backoff_factor=1,
        status_forcelist=[429, 500, 502, 503, 504]
    )
    
    adapter = HTTPAdapter(max_retries=retry)
    session.mount('https://', adapter)
    session.mount('http://', adapter)
    
    return session

# Use it
session = get_tailscale_session()
response = session.get(
    f"https://api.tailscale.com/api/v2/tailnet/{tailnet}/devices",
    auth=(client_id, client_secret)
)
```
