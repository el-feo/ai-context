---
name: tailscale
description: Comprehensive Tailscale VPN setup, configuration, and management for mesh networking, secure access, and zero-trust infrastructure. Covers installation, CLI commands, subnet routers, exit nodes, Tailscale SSH, ACL/grants configuration, MagicDNS, Tailscale Serve/Funnel, API automation, and production deployment best practices. Use when setting up Tailscale, configuring tailnet access controls, deploying subnet routers or exit nodes, enabling Tailscale SSH, exposing services with Serve/Funnel, automating via the Tailscale API, troubleshooting connectivity, or planning production Tailscale deployments.
---

# Tailscale Network Management

## Quick Start

```bash
# Install (Linux)
curl -fsSL https://tailscale.com/install.sh | sh

# Install (macOS)
brew install tailscale

# Connect and authenticate
sudo tailscale up

# Check status
tailscale status

# Get your Tailscale IP
tailscale ip -4
```

## Common Operations

### Connection Management

```bash
tailscale up                    # Connect
tailscale down                  # Disconnect (daemon stays running)
tailscale status                # View peers
tailscale status --json | jq    # Detailed network map
tailscale ping machine-name     # Test connectivity (ignores ACLs)
tailscale ping --icmp machine-name  # Test with ACLs
tailscale set --exit-node=name  # Use exit node
tailscale set --exit-node=      # Stop using exit node
```

Use `tailscale set` to change settings without reconnecting. Use `tailscale up` for initial setup.

### Subnet Router Setup

Run `scripts/setup_subnet_router.sh <subnet_cidr> [auth_key]` for automated setup.

**Manual steps:**
1. Enable IP forwarding on the router device
2. `sudo tailscale up --advertise-routes=192.168.1.0/24`
3. Approve routes in admin console (Machines > device > Edit route settings)
4. Linux clients: `sudo tailscale up --accept-routes`

### Exit Node Setup

Run `scripts/setup_exit_node.sh [auth_key]` for automated setup.

**Manual steps:**
1. Enable IP forwarding on the exit node
2. `sudo tailscale up --advertise-exit-node`
3. Approve in admin console (Machines > device > Edit route settings > Use as exit node)
4. Clients: `tailscale set --exit-node=node-name --exit-node-allow-lan-access`

### Tailscale SSH

```bash
# Enable on server
sudo tailscale set --ssh

# Connect from client (no special setup needed)
ssh machine-name
```

Requires both network access grant and SSH ACL rule. See [acl-examples.md](references/acl-examples.md) for SSH ACL patterns.

### Serve and Funnel

```bash
# Serve locally to tailnet
tailscale serve 3000

# Expose to public internet (ports 443, 8443, or 10000 only)
tailscale funnel 3000

# TCP forwarding with TLS termination
tailscale serve --tls-terminated-tcp=5432 localhost:5432

# Check status / turn off
tailscale serve status
tailscale serve off
```

## Access Control

Use **Grants** (modern, recommended) over ACLs (legacy). Both work, but Grants support application-layer capabilities.

```json
{
  "groups": {
    "group:engineering": ["alice@example.com"]
  },
  "tagOwners": {
    "tag:server": ["group:engineering"]
  },
  "grants": [
    {
      "src": ["group:engineering"],
      "dst": ["tag:server"],
      "ip": ["22", "443"]
    }
  ]
}
```

**Key patterns:** Use groups for people, tags for machines. Always include both network grants and SSH rules for SSH access.

For detailed ACL scenarios, SSH access patterns, posture checks, auto-approvers, GitOps integration, and common mistakes, see [acl-examples.md](references/acl-examples.md).

## Reference Files

- **[cli-reference.md](references/cli-reference.md)** - Complete CLI command reference with all flags, target formats, and platform-specific notes
- **[acl-examples.md](references/acl-examples.md)** - Detailed ACL/grants configuration: team-based access, dev/staging/prod isolation, SSH patterns, posture checks, auto-approvers, GitOps, migration from ACLs to Grants
- **[api-usage.md](references/api-usage.md)** - REST API, Terraform provider, Python SDK, webhooks, automation examples
- **[troubleshooting.md](references/troubleshooting.md)** - Connectivity diagnostics, subnet router issues, exit node issues, SSH problems, MagicDNS, performance tuning, common error messages
- **[production-setup.md](references/production-setup.md)** - Architecture patterns, HA setup, security hardening, IaC (Terraform/Ansible/K8s), monitoring, DR, operational procedures

## Scripts

- **`scripts/setup_subnet_router.sh <subnet_cidr> [auth_key]`** - Automated subnet router setup (installs Tailscale, enables IP forwarding, configures routes)
- **`scripts/setup_exit_node.sh [auth_key]`** - Automated exit node setup (installs Tailscale, enables IP forwarding, advertises as exit node)
