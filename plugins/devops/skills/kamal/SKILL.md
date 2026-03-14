---
name: kamal
description: Deploy containerized web applications to any Linux server using Kamal 2. Use when users need to deploy, configure, debug, or manage Kamal deployments including initial setup, configuration of deploy.yml, deployment workflows, rollbacks, managing accessories (databases, Redis, Litestream), troubleshooting deployment issues, CI/CD integration, multi-environment setups, or understanding Kamal commands and best practices. Also use when working with Kamal Proxy, Docker-based deployments, zero-downtime deploys, or 37signals deployment tooling.
---

# Kamal Deployment

Kamal is a zero-downtime deployment tool for containerized applications, built by 37signals. It combines SSH, Docker, and Kamal Proxy to deploy any containerized web app to bare Linux servers.

**Key components**: SSH/SSHKit (remote execution), Docker (containers), Kamal Proxy (zero-downtime routing), Accessories (supporting services).

## Quick Start

```bash
gem install kamal
cd your-app && kamal init          # Generate config/deploy.yml and .kamal/secrets
# Edit config/deploy.yml and .kamal/secrets
kamal setup                         # Bootstrap servers, install Docker, deploy
```

## Minimal deploy.yml

```yaml
service: myapp
image: username/myapp

servers:
  web:
    - 192.168.1.10

registry:
  server: ghcr.io
  username: myuser
  password:
    - KAMAL_REGISTRY_PASSWORD

env:
  secret:
    - RAILS_MASTER_KEY
  clear:
    RAILS_ENV: production

proxy:
  ssl: true
  host: example.com
```

For complete configuration options (registry variants, builder, proxy, accessories, SSH, volumes, aliases, healthchecks, rollout strategies), see [references/configuration.md](references/configuration.md).

## Essential Commands

```bash
kamal deploy                    # Build, push, deploy with zero downtime
kamal deploy -d staging         # Deploy to specific environment
kamal rollback VERSION          # Rollback to previous version
kamal app logs -f               # Follow application logs
kamal app exec -i --reuse "bin/rails console"  # Interactive console
kamal app maintenance           # Enable maintenance mode
kamal app live                  # Disable maintenance mode
kamal config                    # Show parsed configuration
kamal lock release              # Release stuck deployment lock
```

For complete command reference with all options, see [references/commands.md](references/commands.md).

## Common Workflows

### Deploy with Database Migration

Create `.kamal/hooks/pre-deploy`:
```bash
#!/bin/bash
kamal app exec -p -q "bin/rails db:migrate"
```
Then `chmod +x .kamal/hooks/pre-deploy && kamal deploy`.

### Rollback

```bash
kamal app containers            # List available versions
kamal rollback abc123def        # Rollback to specific version
```

### Debugging Failed Deployments

1. `kamal app logs -n 500` — check application logs
2. `kamal server exec "docker ps -a"` — check container status
3. `kamal app exec "curl localhost:3000/up"` — test health endpoint
4. `kamal config` — verify configuration
5. `kamal lock release` — clear stuck locks

### Multiple Environments

Create `config/deploy.staging.yml`, then:
```bash
kamal setup -d staging && kamal deploy -d staging
```

For detailed workflows (CI/CD, scaling, backups, security, canary deploys, monitoring), see [references/workflows.md](references/workflows.md).

## Limitations

- **No state reconciliation** — removing servers from config does not decommission containers
- **No dynamic provisioning** — cannot auto-scale or provision servers
- **Single-server load balancing** — Kamal Proxy balances containers per server; use an external LB across servers
