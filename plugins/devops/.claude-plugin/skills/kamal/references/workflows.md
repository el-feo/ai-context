# Kamal Workflows and Best Practices

Common deployment workflows, troubleshooting patterns, and production best practices.

## Initial Setup Workflow

### For New Projects

1. **Install Kamal**
   ```bash
   gem install kamal
   ```

2. **Initialize Configuration**
   ```bash
   cd your-app
   kamal init
   ```

3. **Configure deploy.yml**
   - Set service name and image
   - Add server IPs
   - Configure registry credentials
   - Set up environment variables
   - Configure proxy settings

4. **Configure Secrets**
   Edit `.kamal/secrets` and add:
   ```bash
   KAMAL_REGISTRY_PASSWORD=your-registry-token
   RAILS_MASTER_KEY=your-master-key
   # Other secrets...
   ```

5. **Bootstrap Servers**
   ```bash
   kamal server bootstrap
   ```
   Or let `kamal setup` handle it.

6. **Run Initial Setup**
   ```bash
   kamal setup
   ```

### For Existing Projects

1. **Check Configuration**
   ```bash
   kamal config
   ```

2. **Verify Servers Are Accessible**
   ```bash
   ssh user@server-ip
   ```

3. **Deploy**
   ```bash
   kamal deploy
   ```

## Standard Deployment Workflow

### Daily Development Deploy

```bash
# 1. Make changes to code
git add .
git commit -m "Feature: Add new functionality"

# 2. Build and deploy
kamal deploy

# 3. Verify deployment
kamal app logs -f
```

### Deploy with Migrations

**Option 1: Using pre-deploy hook**

Create `.kamal/hooks/pre-deploy`:
```bash
#!/bin/bash
kamal app exec -p -q "bin/rails db:migrate"
```

```bash
chmod +x .kamal/hooks/pre-deploy
kamal deploy
```

**Option 2: Manual migration**
```bash
# Deploy first
kamal deploy

# Then run migration
kamal app exec -p "bin/rails db:migrate"
```

### Deploy to Staging First

```bash
# Deploy to staging
kamal deploy -d staging

# Test staging
curl https://staging.example.com

# If good, deploy to production
kamal deploy
```

## Multi-Environment Workflow

### Setup

Create environment-specific configs:
- `config/deploy.yml` (production)
- `config/deploy.staging.yml` (staging)
- `config/deploy.development.yml` (development)

### Deploy Pattern

```bash
# Staging deploy
kamal setup -d staging
kamal deploy -d staging

# Production deploy
kamal setup  # or kamal setup -d production
kamal deploy  # or kamal deploy -d production
```

## Zero-Downtime Deploy Process

What happens during `kamal deploy`:

1. **Build Phase**
   - Builds Docker image
   - Tags with Git SHA
   - Pushes to registry

2. **Pre-Deploy Phase**
   - Runs pre-deploy hooks
   - Verifies connectivity

3. **Deploy Phase**
   - Pulls new image on servers
   - Starts new containers
   - Runs health checks
   - Routes traffic to new containers (via proxy)
   - Stops old containers after traffic shift

4. **Post-Deploy Phase**
   - Runs post-deploy hooks
   - Cleans up old containers (keeps recent ones for rollback)

## Rollback Workflow

### When Deploy Fails

```bash
# Check what went wrong
kamal app logs

# List available versions
kamal app containers

# Rollback to previous version
kamal rollback <version-sha>

# Verify rollback
kamal app version
kamal app logs -f
```

### Planned Rollback

```bash
# Get current version first
kamal app version
# Save it: v1.2.3 (abc123def)

# After problematic deploy, rollback
kamal rollback abc123def
```

## Maintenance Mode Workflow

### Enable Maintenance Mode

```bash
# Enable maintenance
kamal app maintenance

# Do maintenance work
kamal app exec -p "bin/rails db:migrate"
kamal app exec -p "bin/rails data:cleanup"

# Bring back live
kamal app live
```

### Custom Maintenance Page

Set up in proxy configuration:
```yaml
proxy:
  ssl: true
  host: example.com
```

## Troubleshooting Workflows

### Deployment Fails - Health Check Issues

```bash
# Check application logs
kamal app logs

# Check container status
kamal server exec "docker ps -a"

# Test health endpoint directly
kamal app exec "curl localhost:3000/up"

# Check if app is actually running
kamal app exec "ps aux | grep ruby"
```

### Deployment Fails - Image Build Issues

```bash
# Build with verbose logging
kamal deploy -v

# Test Docker build locally
docker build -t myapp:test .

# Check Dockerfile syntax
docker build --no-cache -t myapp:test .
```

### Deployment Fails - Registry Issues

```bash
# Check registry login
kamal registry login

# Manually test push
docker push your-image:tag

# Check registry credentials in .kamal/secrets
cat .kamal/secrets
```

### Container Won't Start

```bash
# Check container logs
kamal app logs -n 500

# Check Docker logs directly
kamal server exec "docker logs <container-id>"

# Try running container manually to debug
kamal server exec "docker run -it your-image:tag bash"
```

### Lock Issues

```bash
# Check lock status
kamal lock status

# If stale lock, release it
kamal lock release

# Then retry deploy
kamal deploy
```

### SSH Connection Issues

```bash
# Test SSH connection
ssh -v user@server-ip

# Check SSH config in deploy.yml
kamal config

# Try with different SSH user
kamal deploy --ssh-user=root
```

## Database Management Workflows

### Running Migrations

**Safe Pattern:**
```bash
# 1. Put app in maintenance mode
kamal app maintenance

# 2. Run migrations
kamal app exec -p "bin/rails db:migrate"

# 3. Bring app back
kamal app live

# 4. Verify
kamal app logs -f
```

**Automated Pattern (using hooks):**

`.kamal/hooks/pre-deploy`:
```bash
#!/bin/bash
kamal app exec -p -q "bin/rails db:migrate"
```

### Database Backups

**PostgreSQL:**
```bash
# Backup
kamal accessory exec postgres "pg_dump -U myapp myapp_production" > backup.sql

# Restore
cat backup.sql | kamal accessory exec -i postgres "psql -U myapp myapp_production"
```

**MySQL:**
```bash
# Backup
kamal accessory exec mysql "mysqldump -u root -p myapp_production" > backup.sql

# Restore
cat backup.sql | kamal accessory exec -i mysql "mysql -u root -p myapp_production"
```

**SQLite with Litestream:**
```bash
# Check backups
kamal accessory exec litestream "litestream generations /data/production.sqlite3"

# Restore from backup
kamal app exec "rm /data/production.sqlite3"
kamal accessory exec litestream "litestream restore /data/production.sqlite3"
```

## Scaling Workflows

### Adding Web Servers

1. **Update deploy.yml**
   ```yaml
   servers:
     web:
       - 192.168.1.10  # existing
       - 192.168.1.11  # existing
       - 192.168.1.12  # new
   ```

2. **Bootstrap New Server**
   ```bash
   kamal server bootstrap -h 192.168.1.12
   ```

3. **Deploy to All Servers**
   ```bash
   kamal deploy
   ```

### Adding Worker Servers

1. **Add Worker Role**
   ```yaml
   servers:
     web:
       - 192.168.1.10
     worker:
       hosts:
         - 192.168.1.13
       cmd: bundle exec sidekiq
   ```

2. **Deploy**
   ```bash
   kamal deploy
   ```

### Horizontal Scaling Pattern

For true load balancing across servers:

1. Deploy Kamal normally to multiple servers
2. Each server has Kamal Proxy routing locally
3. Add load balancer in front (e.g., DigitalOcean LB, AWS ELB)
4. Point DNS to load balancer

## CI/CD Integration Workflows

### GitHub Actions Example

`.github/workflows/deploy.yml`:
```yaml
name: Deploy

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Set up Ruby
        uses: ruby/setup-ruby@v1
        with:
          ruby-version: 3.2
      
      - name: Install Kamal
        run: gem install kamal
      
      - name: Set up SSH
        run: |
          mkdir -p ~/.ssh
          echo "${{ secrets.SSH_PRIVATE_KEY }}" > ~/.ssh/id_rsa
          chmod 600 ~/.ssh/id_rsa
          ssh-keyscan -H ${{ secrets.SERVER_IP }} >> ~/.ssh/known_hosts
      
      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v2
      
      - name: Deploy
        env:
          KAMAL_REGISTRY_PASSWORD: ${{ secrets.KAMAL_REGISTRY_PASSWORD }}
          RAILS_MASTER_KEY: ${{ secrets.RAILS_MASTER_KEY }}
        run: |
          echo "$KAMAL_REGISTRY_PASSWORD" | docker login ghcr.io -u ${{ github.actor }} --password-stdin
          kamal deploy
```

### GitLab CI Example

`.gitlab-ci.yml`:
```yaml
deploy:
  stage: deploy
  image: ruby:3.2
  before_script:
    - gem install kamal
    - mkdir -p ~/.ssh
    - echo "$SSH_PRIVATE_KEY" > ~/.ssh/id_rsa
    - chmod 600 ~/.ssh/id_rsa
    - ssh-keyscan -H $SERVER_IP >> ~/.ssh/known_hosts
  script:
    - kamal deploy
  only:
    - main
  environment:
    name: production
```

## Security Best Practices

### Secrets Management

1. **Never commit secrets to git**
   ```bash
   # Add to .gitignore
   echo ".kamal/secrets" >> .gitignore
   echo ".env" >> .gitignore
   ```

2. **Use environment-specific secrets**
   ```bash
   # .kamal/secrets.staging
   # .kamal/secrets.production
   ```

3. **Use secrets manager integration**
   ```bash
   # Use 1Password, LastPass, etc.
   kamal secrets fetch --adapter 1password
   ```

### SSH Security

1. **Use SSH keys, never passwords**
   ```bash
   ssh-keygen -t ed25519 -C "deploy@example.com"
   ssh-copy-id -i ~/.ssh/id_ed25519.pub user@server
   ```

2. **Use dedicated deploy user**
   ```yaml
   ssh:
     user: deploy
   ```

3. **Restrict deploy user permissions**
   ```bash
   # On server
   usermod -aG docker deploy
   # Don't give sudo access unless necessary
   ```

### Container Security

1. **Use specific image versions**
   ```yaml
   accessories:
     postgres:
       image: postgres:15.3  # Not 'latest'
   ```

2. **Scan images for vulnerabilities**
   ```bash
   docker scan your-image:tag
   ```

3. **Run containers as non-root**
   ```dockerfile
   USER nobody
   ```

## Performance Optimization

### Build Cache Optimization

```yaml
builder:
  cache:
    type: gha  # Use GitHub Actions cache
    # or
    type: registry  # Use registry cache
```

### Parallel Deployments

```yaml
boot:
  limit: 10  # Deploy to 10 servers at once
```

### Health Check Tuning

```yaml
healthcheck:
  interval: 10     # Balance between speed and reliability
  max_attempts: 7  # Give app time to start
  timeout: 5
```

## Monitoring and Logging

### Log Aggregation Pattern

```bash
# Stream logs to external service
kamal app logs -f | your-log-collector

# Or configure Docker logging driver
```

```yaml
logging:
  driver: syslog
  options:
    syslog-address: "tcp://logs.example.com:514"
```

### Health Monitoring

```bash
# Regular health checks
while true; do
  curl -f https://example.com/up || echo "Health check failed"
  sleep 60
done
```

### Uptime Monitoring Services

- UptimeRobot
- Pingdom
- StatusCake
- Custom: Hit `/up` endpoint every minute

## Common Patterns

### Blue-Green Deployments

Kamal automatically does this:
- Green (new) containers start
- Health checks pass
- Traffic routes to green
- Blue (old) containers stop

### Canary Deployments

Deploy to subset of servers first:

```bash
# Deploy to single server
kamal deploy -h 192.168.1.10

# Monitor
kamal app logs -h 192.168.1.10 -f

# If good, deploy to rest
kamal deploy
```

### Feature Flags

Use environment variables:

```yaml
env:
  clear:
    FEATURE_NEW_UI: false
```

Update and redeploy to enable:
```yaml
env:
  clear:
    FEATURE_NEW_UI: true
```

## Quick Reference Cheat Sheet

```bash
# Initial setup
kamal init
kamal setup

# Daily deploys
kamal deploy
kamal deploy -d staging

# Rollbacks
kamal app containers
kamal rollback <version>

# Logs
kamal app logs -f
kamal app logs -g "error"

# Maintenance
kamal app maintenance
kamal app live

# Console access
kamal app exec -i --reuse "bin/rails console"
kamal app exec -i --reuse "bash"

# Lock management
kamal lock status
kamal lock release

# Accessories
kamal accessory boot postgres
kamal accessory logs redis -f
kamal accessory exec postgres "psql"

# Configuration
kamal config
kamal config env

# Quick fixes
kamal app reboot       # Restart app
kamal proxy reboot     # Restart proxy
kamal lock release     # Clear stuck lock
```
