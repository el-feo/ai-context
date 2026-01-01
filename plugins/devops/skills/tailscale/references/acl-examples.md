# Tailscale ACL and Grants Examples

Comprehensive examples for configuring access control in Tailscale tailnets.

## ACL vs Grants

**ACLs** (legacy, still supported):
- Network-layer only
- Specify src, dst, ports
- No new features being added

**Grants** (modern, recommended):
- Network AND application-layer capabilities
- Cleaner syntax
- Future-proof

**Both work indefinitely**, but use Grants for new configurations.

## Basic Patterns

### Default Allow All

```json
{
  "acls": [
    {
      "action": "accept",
      "src": ["*"],
      "dst": ["*:*"]
    }
  ]
}
```

Or with Grants:

```json
{
  "grants": [
    {
      "src": ["*"],
      "dst": ["*"],
      "ip": ["*"]
    }
  ]
}
```

### Deny All (Emergency Lockdown)

```json
{
  "acls": []
}
```

Or:

```json
{
  "grants": []
}
```

## Groups and Tags

### Define Groups and Tags

```json
{
  "groups": {
    "group:engineering": [
      "alice@example.com",
      "bob@example.com"
    ],
    "group:ops": [
      "ops@example.com"
    ],
    "group:finance": [
      "finance@example.com"
    ]
  },
  "tagOwners": {
    "tag:dev": ["group:engineering"],
    "tag:staging": ["group:engineering", "group:ops"],
    "tag:prod": ["group:ops"],
    "tag:database": ["group:ops"],
    "tag:monitoring": ["autogroup:admin"]
  }
}
```

### Group Best Practices

✅ **Use groups for people**: `group:engineering`, `group:ops`
✅ **Use tags for machines**: `tag:server`, `tag:database`
✅ **Sync from IdP**: Use identity provider groups when possible

```json
{
  "groups": {
    "group:engineering@example.com": [],  // Synced from Google Workspace
    "group:ops@example.com": []           // Synced from Okta
  }
}
```

## Common Scenarios

### Scenario 1: Personal + Shared Devices

Everyone accesses their own devices + shared servers.

```json
{
  "tagOwners": {
    "tag:shared": ["autogroup:admin"]
  },
  "grants": [
    {
      "src": ["autogroup:member"],
      "dst": ["autogroup:self"],
      "ip": ["*"]
    },
    {
      "src": ["autogroup:member"],
      "dst": ["tag:shared"],
      "ip": ["22", "80", "443"]
    }
  ]
}
```

### Scenario 2: Team-Based Access

Different teams access different resources.

```json
{
  "groups": {
    "group:engineering": ["alice@example.com", "bob@example.com"],
    "group:design": ["designer@example.com"],
    "group:finance": ["cfo@example.com"]
  },
  "tagOwners": {
    "tag:dev-servers": ["group:engineering"],
    "tag:design-tools": ["group:design"],
    "tag:financial-systems": ["group:finance"]
  },
  "grants": [
    {
      "src": ["autogroup:member"],
      "dst": ["autogroup:self"],
      "ip": ["*"]
    },
    {
      "src": ["group:engineering"],
      "dst": ["tag:dev-servers"],
      "ip": ["*"]
    },
    {
      "src": ["group:design"],
      "dst": ["tag:design-tools"],
      "ip": ["*"]
    },
    {
      "src": ["group:finance"],
      "dst": ["tag:financial-systems"],
      "ip": ["22", "443"]
    }
  ]
}
```

### Scenario 3: Dev/Staging/Prod Isolation

```json
{
  "groups": {
    "group:developers": ["dev@example.com"],
    "group:qa": ["qa@example.com"],
    "group:ops": ["ops@example.com"]
  },
  "tagOwners": {
    "tag:dev": ["group:developers"],
    "tag:staging": ["group:developers", "group:qa"],
    "tag:prod": ["group:ops"]
  },
  "grants": [
    {
      "src": ["group:developers"],
      "dst": ["tag:dev"],
      "ip": ["*"]
    },
    {
      "src": ["group:developers", "group:qa"],
      "dst": ["tag:staging"],
      "ip": ["22", "80", "443"]
    },
    {
      "src": ["group:ops"],
      "dst": ["tag:prod"],
      "ip": ["22"]
    },
    {
      "src": ["autogroup:member"],
      "dst": ["tag:prod"],
      "ip": ["443"]
    }
  ],
  "ssh": [
    {
      "action": "check",
      "src": ["group:ops"],
      "dst": ["tag:prod"],
      "users": ["root", "ubuntu"]
    }
  ]
}
```

### Scenario 4: Customer Access (Shared Users)

Share specific machines with external users.

```json
{
  "groups": {
    "group:customers": ["customer@external.com"]
  },
  "tagOwners": {
    "tag:shared-demo": ["autogroup:admin"]
  },
  "grants": [
    {
      "src": ["group:customers"],
      "dst": ["tag:shared-demo"],
      "ip": ["80", "443"]
    }
  ]
}
```

### Scenario 5: Site-to-Site VPN

Connect office networks via subnet routers.

```json
{
  "tagOwners": {
    "tag:subnet-router-sf": ["autogroup:admin"],
    "tag:subnet-router-nyc": ["autogroup:admin"]
  },
  "grants": [
    {
      "src": ["*"],
      "dst": ["tag:subnet-router-sf"],
      "ip": ["*"]
    },
    {
      "src": ["*"],
      "dst": ["tag:subnet-router-nyc"],
      "ip": ["*"]
    }
  ],
  "autoApprovers": {
    "routes": {
      "10.1.0.0/16": ["tag:subnet-router-sf"],
      "10.2.0.0/16": ["tag:subnet-router-nyc"]
    },
    "exitNode": ["tag:subnet-router-sf"]
  }
}
```

## SSH Access Control

### Basic SSH Setup

```json
{
  "grants": [
    {
      "src": ["alice@example.com"],
      "dst": ["tag:servers"],
      "ip": ["22"]
    }
  ],
  "ssh": [
    {
      "action": "accept",
      "src": ["alice@example.com"],
      "dst": ["tag:servers"],
      "users": ["ubuntu", "alice"]
    }
  ]
}
```

### SSH with Check Mode (MFA)

Requires recent re-authentication for sensitive access.

```json
{
  "ssh": [
    {
      "action": "check",
      "src": ["group:ops"],
      "dst": ["tag:prod"],
      "users": ["root"]
    },
    {
      "action": "accept",
      "src": ["group:ops"],
      "dst": ["tag:prod"],
      "users": ["autogroup:nonroot"]
    }
  ]
}
```

### SSH User Mapping

```json
{
  "ssh": [
    {
      "action": "accept",
      "src": ["alice@example.com"],
      "dst": ["tag:servers"],
      "users": ["alice", "ubuntu"]
    },
    {
      "action": "accept",
      "src": ["bob@example.com"],
      "dst": ["tag:servers"],
      "users": ["bob"]
    },
    {
      "action": "accept",
      "src": ["group:ops"],
      "dst": ["tag:servers"],
      "users": ["root", "autogroup:nonroot"]
    }
  ]
}
```

## Advanced Patterns

### Protocol-Specific Rules

```json
{
  "acls": [
    {
      "action": "accept",
      "src": ["group:developers"],
      "dst": ["tag:database:5432"],
      "proto": "tcp"
    },
    {
      "action": "accept",
      "src": ["tag:monitoring"],
      "dst": ["*:*"],
      "proto": "icmp"
    }
  ]
}
```

### IP Sets for Complex Networks

```json
{
  "ipSets": {
    "office-networks": [
      "10.0.0.0/8",
      "172.16.0.0/12",
      "192.168.0.0/16"
    ],
    "cloud-cidrs": [
      "10.100.0.0/16",
      "10.200.0.0/16"
    ]
  },
  "grants": [
    {
      "src": ["group:employees"],
      "dst": ["ipSet:office-networks"],
      "ip": ["*"]
    }
  ]
}
```

### Auto-Approvers

Automatically approve certain operations without admin intervention.

```json
{
  "autoApprovers": {
    "routes": {
      "192.168.0.0/16": ["tag:subnet-router"],
      "10.0.0.0/8": ["tag:cloud-gateway"]
    },
    "exitNode": ["tag:exit-nodes"]
  }
}
```

### Posture-Based Access

Require device compliance before granting access.

```json
{
  "postures": {
    "posture:secure": [
      "node:os == 'linux' || node:os == 'darwin'",
      "node:tsVersion >= '1.50.0'"
    ]
  },
  "grants": [
    {
      "src": ["group:engineering"],
      "dst": ["tag:prod"],
      "ip": ["22"],
      "capabilities": {
        "posture": ["posture:secure"]
      }
    }
  ]
}
```

## Testing ACLs

### ACL Tests

Add tests to validate your policy:

```json
{
  "tests": [
    {
      "src": "alice@example.com",
      "accept": ["tag:dev:22", "tag:dev:443"],
      "deny": ["tag:prod:*"]
    },
    {
      "src": "bob@example.com",
      "accept": ["tag:prod:443"],
      "deny": ["tag:prod:22"]
    }
  ]
}
```

### Preview Mode

In admin console:
1. Go to Access Controls
2. Click "Preview rules" tab
3. Select user
4. View what they can access

### Testing Commands

```bash
# Test network connectivity (ignores ACLs)
tailscale ping --tsmp target

# Test with ACLs applied
tailscale ping --icmp target

# If TSMP works but ICMP fails → ACL is blocking
```

## Common Mistakes

### ❌ Don't: Overly Permissive Personal Devices

```json
{
  "grants": [
    {
      "src": ["user@example.com"],  // Personal account
      "dst": ["tag:prod"],           // Production servers
      "ip": ["*"]                    // All ports
    }
  ]
}
```

✅ **Do: Use groups and limit ports**

```json
{
  "groups": {
    "group:ops": ["user@example.com"]
  },
  "grants": [
    {
      "src": ["group:ops"],
      "dst": ["tag:prod"],
      "ip": ["22", "443"]
    }
  ]
}
```

### ❌ Don't: Forget Network-Level Access

```json
{
  "ssh": [
    {
      "action": "accept",
      "src": ["user@example.com"],
      "dst": ["tag:servers"],
      "users": ["ubuntu"]
    }
  ]
  // Missing network access grant!
}
```

✅ **Do: Include both network and SSH rules**

```json
{
  "grants": [
    {
      "src": ["user@example.com"],
      "dst": ["tag:servers"],
      "ip": ["22"]
    }
  ],
  "ssh": [
    {
      "action": "accept",
      "src": ["user@example.com"],
      "dst": ["tag:servers"],
      "users": ["ubuntu"]
    }
  ]
}
```

### ❌ Don't: Hardcode Email Addresses

```json
{
  "grants": [
    {
      "src": ["alice@example.com", "bob@example.com", "charlie@example.com"],
      "dst": ["tag:servers"],
      "ip": ["*"]
    }
  ]
}
```

✅ **Do: Use groups**

```json
{
  "groups": {
    "group:engineering": ["alice@example.com", "bob@example.com", "charlie@example.com"]
  },
  "grants": [
    {
      "src": ["group:engineering"],
      "dst": ["tag:servers"],
      "ip": ["*"]
    }
  ]
}
```

## Auto-Groups Reference

Built-in groups you can use:

| Auto-Group | Description |
|------------|-------------|
| `autogroup:admin` | Tailnet admins and owners |
| `autogroup:member` | All users in the tailnet |
| `autogroup:self` | Each user's own devices |
| `autogroup:nonroot` | All non-root users on a system |
| `autogroup:internet` | The public internet (for exit nodes) |
| `autogroup:shared` | Devices shared with other users |

## GitOps Integration

### GitHub Actions Example

```yaml
name: Update Tailscale ACLs
on:
  push:
    paths:
      - 'tailscale-acl.json'
    branches:
      - main

jobs:
  update-acls:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Update Tailscale ACLs
        env:
          TAILSCALE_API_KEY: ${{ secrets.TAILSCALE_API_KEY }}
          TAILSCALE_TAILNET: ${{ secrets.TAILSCALE_TAILNET }}
        run: |
          curl -X POST \
            "https://api.tailscale.com/api/v2/tailnet/${TAILSCALE_TAILNET}/acl" \
            -u "${TAILSCALE_API_KEY}:" \
            -H "Content-Type: application/json" \
            --data @tailscale-acl.json
```

### Pre-commit Testing

```bash
#!/bin/bash
# .git/hooks/pre-commit

# Test ACL syntax
if ! tailscale debug policy lint acl.json; then
  echo "ACL lint failed"
  exit 1
fi

echo "ACL validation passed"
```

## Migration from ACLs to Grants

### Before (ACLs):

```json
{
  "acls": [
    {
      "action": "accept",
      "src": ["group:engineering"],
      "dst": ["tag:dev:22", "tag:dev:443"]
    }
  ]
}
```

### After (Grants):

```json
{
  "grants": [
    {
      "src": ["group:engineering"],
      "dst": ["tag:dev"],
      "ip": ["22", "443"]
    }
  ]
}
```

## Full Example: Complete Policy

```json
{
  "groups": {
    "group:engineering": ["alice@example.com", "bob@example.com"],
    "group:ops": ["ops@example.com"],
    "group:contractors": ["contractor@external.com"]
  },
  "tagOwners": {
    "tag:dev": ["group:engineering"],
    "tag:staging": ["group:engineering"],
    "tag:prod": ["group:ops"],
    "tag:subnet-router": ["autogroup:admin"],
    "tag:exit-node": ["autogroup:admin"]
  },
  "grants": [
    {
      "src": ["autogroup:member"],
      "dst": ["autogroup:self"],
      "ip": ["*"]
    },
    {
      "src": ["group:engineering"],
      "dst": ["tag:dev"],
      "ip": ["*"]
    },
    {
      "src": ["group:engineering"],
      "dst": ["tag:staging"],
      "ip": ["22", "80", "443"]
    },
    {
      "src": ["group:ops"],
      "dst": ["tag:prod"],
      "ip": ["22", "443"]
    },
    {
      "src": ["group:contractors"],
      "dst": ["tag:dev"],
      "ip": ["80", "443"]
    }
  ],
  "ssh": [
    {
      "action": "accept",
      "src": ["group:engineering"],
      "dst": ["tag:dev"],
      "users": ["ubuntu", "autogroup:nonroot"]
    },
    {
      "action": "check",
      "src": ["group:ops"],
      "dst": ["tag:prod"],
      "users": ["root"]
    },
    {
      "action": "accept",
      "src": ["group:ops"],
      "dst": ["tag:prod"],
      "users": ["autogroup:nonroot"]
    }
  ],
  "autoApprovers": {
    "routes": {
      "192.168.0.0/16": ["tag:subnet-router"],
      "10.0.0.0/8": ["tag:subnet-router"]
    },
    "exitNode": ["tag:exit-node"]
  },
  "tests": [
    {
      "src": "alice@example.com",
      "accept": ["tag:dev:22", "tag:staging:443"],
      "deny": ["tag:prod:22"]
    },
    {
      "src": "ops@example.com",
      "accept": ["tag:prod:22", "tag:prod:443"],
      "deny": []
    }
  ]
}
```
