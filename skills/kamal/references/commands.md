# Kamal Commands Reference

Complete reference for all Kamal CLI commands and their usage.

## Core Deployment Commands

### kamal init
Initialize Kamal configuration in a project.

```bash
kamal init
```

**What it does:**
- Creates `config/deploy.yml` with basic configuration template
- Creates `.kamal/secrets` template for environment variables

### kamal setup
Initial provisioning and first deploy.

```bash
kamal setup [OPTIONS]
```

**What it does:**
1. Ensures `.kamal` directory exists on hosts
2. Runs `kamal server bootstrap` (installs Docker if needed)
3. Creates Docker network
4. Starts Kamal Proxy
5. Boots accessories
6. Builds and pushes application image
7. Deploys application containers

**Options:**
- `-d, --destination=DESTINATION`: Target specific environment (e.g., staging)
- `-p, --primary`: Run only on primary host
- `-h, --hosts=HOSTS`: Run on specific hosts (comma-separated)
- `-r, --roles=ROLES`: Run on specific roles (comma-separated)
- `-c, --config-file=FILE`: Use specific config file
- `-v, --verbose`: Detailed logging
- `-q, --quiet`: Minimal logging

### kamal deploy
Deploy application (standard deployment workflow).

```bash
kamal deploy [OPTIONS]
```

**What it does:**
1. Builds and pushes new image (unless `--skip-push`)
2. Ensures proxy is running
3. Boots new containers with new version
4. Runs health checks
5. Routes traffic to new containers
6. Stops old containers

**Options:**
- `-P, --skip-push`: Skip image build and push
- `--version=VERSION`: Deploy specific version
- `-d, --destination=DESTINATION`: Deploy to specific environment
- `-H, --skip-hooks`: Don't run deployment hooks
- `-p, --primary`: Deploy only to primary host
- `-h, --hosts=HOSTS`: Deploy to specific hosts
- `-r, --roles=ROLES`: Deploy to specific roles

**Example:**
```bash
# Standard deploy
kamal deploy

# Deploy to staging
kamal deploy -d staging

# Deploy specific version
kamal deploy --version v2.0.1

# Deploy without building (use existing image)
kamal deploy --skip-push
```

### kamal redeploy
Redeploy without proxy setup (faster for development).

```bash
kamal redeploy [OPTIONS]
```

**What it does:**
- Same as `kamal deploy` but skips proxy setup
- Useful for frequent local deployments
- Assumes proxy is already configured

### kamal rollback
Roll back to previous version.

```bash
kamal rollback VERSION [OPTIONS]
```

**What it does:**
1. Stops current containers
2. Starts containers with specified version
3. Routes traffic to rolled-back version

**Example:**
```bash
# List available versions
kamal app containers

# Rollback to specific version
kamal rollback 718a80d3a412a8766374348bc826255dbd0d2e7f
```

### kamal remove
Remove all Kamal resources from servers.

```bash
kamal remove [OPTIONS]
```

**What it does:**
- Stops and removes all application containers
- Removes accessories
- Removes proxy
- Removes Docker network
- Keeps images for potential rollback

**Warning:** This is destructive. Make sure you want to remove everything.

## Server Management Commands

### kamal server bootstrap
Install Docker on servers.

```bash
kamal server bootstrap [OPTIONS]
```

**What it does:**
- Installs Docker Engine on remote hosts
- Configures Docker daemon
- Adds deploy user to docker group

**Note:** Only needed if Docker isn't already installed. `kamal setup` runs this automatically.

### kamal server exec
Execute commands on the host server.

```bash
kamal server exec "COMMAND" [OPTIONS]
```

**Example:**
```bash
# Check disk space
kamal server exec "df -h"

# Check running containers
kamal server exec "docker ps"

# View system resources
kamal server exec "free -m"
```

## Application Commands

### kamal app boot
Start application containers.

```bash
kamal app boot [OPTIONS]
```

**What it does:**
- Starts new containers with current version
- Runs health checks
- Routes traffic through proxy

### kamal app reboot
Restart application containers.

```bash
kamal app reboot [OPTIONS]
```

**What it does:**
- Stops current containers
- Starts new containers with same version
- Maintains zero downtime

### kamal app start
Start stopped containers.

```bash
kamal app start [OPTIONS]
```

### kamal app stop
Stop running containers.

```bash
kamal app stop [OPTIONS]
```

**Note:** Stops containers but doesn't remove them. Use for maintenance.

### kamal app remove
Remove application containers.

```bash
kamal app remove [OPTIONS]
```

**What it does:**
- Stops containers
- Removes containers
- Keeps images

### kamal app exec
Execute commands in application container.

```bash
kamal app exec [OPTIONS] "COMMAND"
```

**Options:**
- `-i, --interactive`: Interactive mode (for shells/consoles)
- `--reuse`: Reuse existing container (faster)
- `-p, --primary`: Run only on primary host

**Examples:**
```bash
# Run Rails console
kamal app exec -i --reuse "bin/rails console"

# Run bash shell
kamal app exec -i --reuse "bash"

# Run Rails migration
kamal app exec -p "bin/rails db:migrate"

# Check Rails about
kamal app exec -p "bin/rails about"

# Run one-off task
kamal app exec -p 'bin/rails runner "puts User.count"'
```

### kamal app logs
View application logs.

```bash
kamal app logs [OPTIONS]
```

**Options:**
- `-f, --follow`: Follow log output (like tail -f)
- `-n, --lines=N`: Number of lines to show
- `-s, --since=TIME`: Show logs since time (e.g., "5m", "2h", "2023-01-01T10:00:00Z")
- `-g, --grep=PATTERN`: Filter logs by pattern
- `--grep-options=OPTIONS`: Additional grep options
- `-r, --roles=ROLES`: Show logs from specific roles
- `-d, --destination=DEST`: Show logs from specific destination

**Examples:**
```bash
# Follow logs
kamal app logs -f

# Last 100 lines
kamal app logs -n 100

# Logs from last 5 minutes
kamal app logs -s 5m

# Search for errors
kamal app logs -g "error" --grep-options "-i"

# Search with context
kamal app logs -g "unauthorized" --grep-options "-A 5"

# Logs from specific role
kamal app logs -r worker

# Staging logs
kamal app logs -d staging
```

### kamal app containers
List all application containers (current and previous).

```bash
kamal app containers [OPTIONS]
```

**Output:** Shows container IDs and versions, useful for rollbacks.

### kamal app images
List application images in registry.

```bash
kamal app images [OPTIONS]
```

**Output:** Shows all built images and their tags/versions.

### kamal app version
Show currently deployed version.

```bash
kamal app version [OPTIONS]
```

### kamal app maintenance
Enable maintenance mode.

```bash
kamal app maintenance [OPTIONS]
```

**What it does:**
- Displays maintenance page to visitors
- Application keeps running in background

### kamal app live
Disable maintenance mode (bring app live).

```bash
kamal app live [OPTIONS]
```

## Build Commands

### kamal build deliver
Build and push application image.

```bash
kamal build deliver [OPTIONS]
```

**What it does:**
1. Builds Docker image using configured builder
2. Tags image with commit SHA or custom version
3. Pushes image to registry

**Example:**
```bash
# Build and push
kamal build deliver

# Build for specific destination
kamal build deliver -d staging
```

### kamal build pull
Pull application image from registry.

```bash
kamal build pull [OPTIONS]
```

### kamal build push
Push built image to registry.

```bash
kamal build push [OPTIONS]
```

### kamal build create
Create builder instance.

```bash
kamal build create [OPTIONS]
```

### kamal build remove
Remove builder instance.

```bash
kamal build remove [OPTIONS]
```

## Accessory Commands

Accessories are supporting services like databases, caches, etc.

### kamal accessory boot
Start accessory service.

```bash
kamal accessory boot NAME [OPTIONS]
```

**Example:**
```bash
kamal accessory boot postgres
kamal accessory boot redis
```

### kamal accessory reboot
Restart accessory service.

```bash
kamal accessory reboot NAME [OPTIONS]
```

### kamal accessory start
Start stopped accessory.

```bash
kamal accessory start NAME [OPTIONS]
```

### kamal accessory stop
Stop accessory.

```bash
kamal accessory stop NAME [OPTIONS]
```

### kamal accessory remove
Remove accessory containers.

```bash
kamal accessory remove NAME [OPTIONS]
```

**Example:**
```bash
kamal accessory remove postgres
kamal accessory remove all  # Remove all accessories
```

### kamal accessory exec
Execute commands in accessory container.

```bash
kamal accessory exec NAME "COMMAND" [OPTIONS]
```

**Examples:**
```bash
# PostgreSQL shell
kamal accessory exec postgres "psql -U myapp"

# Redis CLI
kamal accessory exec redis "redis-cli"

# Check Litestream generations
kamal accessory exec litestream "litestream generations /data/production.sqlite3"
```

### kamal accessory logs
View accessory logs.

```bash
kamal accessory logs NAME [OPTIONS]
```

**Options:** Same as `kamal app logs`

**Example:**
```bash
kamal accessory logs postgres -f
kamal accessory logs redis -n 100
```

### kamal accessory details
Show accessory configuration and status.

```bash
kamal accessory details NAME [OPTIONS]
```

**Example:**
```bash
kamal accessory details postgres
kamal accessory details all  # Show all accessories
```

## Proxy Commands

### kamal proxy boot
Start Kamal Proxy.

```bash
kamal proxy boot [OPTIONS]
```

### kamal proxy reboot
Restart Kamal Proxy.

```bash
kamal proxy reboot [OPTIONS]
```

### kamal proxy start
Start stopped proxy.

```bash
kamal proxy start [OPTIONS]
```

### kamal proxy stop
Stop proxy.

```bash
kamal proxy stop [OPTIONS]
```

### kamal proxy remove
Remove proxy container.

```bash
kamal proxy remove [OPTIONS]
```

### kamal proxy logs
View proxy logs.

```bash
kamal proxy logs [OPTIONS]
```

## Registry Commands

### kamal registry login
Log into Docker registry on remote hosts.

```bash
kamal registry login [OPTIONS]
```

**What it does:**
- Authenticates with registry using credentials from `.kamal/secrets`
- Required before pulling private images

### kamal registry logout
Log out from Docker registry.

```bash
kamal registry logout [OPTIONS]
```

## Lock Commands

Kamal uses locks to prevent concurrent deploys.

### kamal lock acquire
Acquire deployment lock.

```bash
kamal lock acquire [OPTIONS]
```

**Options:**
- `-m, --message=MESSAGE`: Reason for lock

**Example:**
```bash
kamal lock acquire -m "Investigating production issue"
```

### kamal lock release
Release deployment lock.

```bash
kamal lock release [OPTIONS]
```

### kamal lock status
Check lock status.

```bash
kamal lock status [OPTIONS]
```

**Output:** Shows if locked, who locked it, and when.

## Configuration Commands

### kamal config
Show parsed configuration.

```bash
kamal config [OPTIONS]
```

**What it does:**
- Displays resolved configuration
- Useful for debugging configuration issues
- Shows how environment variables are interpolated

**Example:**
```bash
# Show production config
kamal config

# Show staging config
kamal config -d staging
```

### kamal config env
Show environment variables that will be set.

```bash
kamal config env [OPTIONS]
```

**Output:** Shows both secret and clear environment variables.

### kamal docs
Output configuration documentation.

```bash
kamal docs [OPTIONS]
```

**What it does:**
- Generates configuration reference documentation
- Useful for understanding all available options

## Utility Commands

### kamal version
Show Kamal version.

```bash
kamal version
```

### kamal help
Show help information.

```bash
kamal help [COMMAND]
```

**Example:**
```bash
kamal help
kamal help deploy
kamal help app
```

## Secrets Commands

### kamal secrets fetch
Fetch secrets from secrets manager.

```bash
kamal secrets fetch --adapter ADAPTER [OPTIONS]
```

**Supported adapters:**
- `1password`: 1Password
- `lastpass`: LastPass
- Other adapters can be added

**Example:**
```bash
# Fetch from 1Password
kamal secrets fetch --adapter 1password --account my-account --from my-vault
```

### kamal secrets extract
Extract specific secret from fetched secrets.

```bash
kamal secrets extract SECRET_NAME SECRETS_JSON
```

**Used in .kamal/secrets:**
```bash
SECRETS=$(kamal secrets fetch --adapter 1password --account my-account --from my-vault)
RAILS_MASTER_KEY=$(kamal secrets extract RAILS_MASTER_KEY $SECRETS)
```

## Common Command Patterns

### Deploying to Multiple Environments

```bash
# Setup staging
kamal setup -d staging

# Deploy to staging
kamal deploy -d staging

# Deploy to production (default)
kamal deploy
```

### Targeting Specific Servers

```bash
# Deploy to specific hosts
kamal deploy -h 192.168.1.10,192.168.1.11

# Deploy to specific role
kamal deploy -r web

# Deploy only to primary
kamal deploy -p
```

### Debugging Deployments

```bash
# Verbose logging
kamal deploy -v

# Check configuration
kamal config

# Check app version
kamal app version

# Check containers
kamal app containers

# View logs
kamal app logs -f

# Check lock status
kamal lock status
```

### Running Tasks

```bash
# Run Rails migrations
kamal app exec -p "bin/rails db:migrate"

# Run Rails console
kamal app exec -i --reuse "bin/rails console"

# Run database seed
kamal app exec -p "bin/rails db:seed"

# Run custom rake task
kamal app exec -p "bin/rails mytask:run"
```

### Managing Accessories

```bash
# Start all accessories
kamal setup  # Boots accessories as part of setup

# Restart specific accessory
kamal accessory reboot postgres

# View accessory logs
kamal accessory logs postgres -f

# Access PostgreSQL
kamal accessory exec postgres "psql -U myapp"

# Backup database
kamal accessory exec postgres "pg_dump -U myapp myapp_production" > backup.sql
```

## Using Custom Aliases

If you define aliases in `config/deploy.yml`:

```yaml
aliases:
  console: app exec --interactive --reuse "bin/rails console"
  shell: app exec --interactive --reuse "bash"
  logs: app logs -f
```

You can use them directly:

```bash
kamal console
kamal shell
kamal logs
```

## Hook Integration

Kamal runs hooks at key lifecycle points. Create scripts in `.kamal/hooks/`:

- `pre-connect`: Before SSH connection
- `pre-build`: Before building image  
- `pre-deploy`: Before deploying
- `post-deploy`: After successful deploy
- `post-proxy-reboot`: After proxy restarts
- `docker-setup`: During Docker installation

**Example `.kamal/hooks/pre-deploy`:**
```bash
#!/bin/bash
echo "Running pre-deploy checks..."
kamal app exec -p "bin/rails db:migrate:status"
```

Make hooks executable: `chmod +x .kamal/hooks/*`

Disable hooks: `kamal deploy --skip-hooks`
