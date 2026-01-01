# Kamal Configuration Reference

This reference covers the complete configuration structure for Kamal's `config/deploy.yml` file.

## Basic Configuration Structure

```yaml
service: myapp              # Name of the container image
image: username/myapp       # Docker image name

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
    DB_HOST: localhost
```

## Service Configuration

The `service` name is used as the container image name and should be unique per application.

```yaml
service: myapp
image: username/myapp  # Full image path including registry
```

## Registry Configuration

### Docker Hub
```yaml
registry:
  username: myuser
  password:
    - KAMAL_REGISTRY_PASSWORD
```

### GitHub Container Registry (GHCR)
```yaml
registry:
  server: ghcr.io
  username: myuser
  password:
    - KAMAL_REGISTRY_PASSWORD
```

### Amazon ECR
```yaml
registry:
  server: 123456789.dkr.ecr.us-east-1.amazonaws.com
  username: AWS
  password:
    - KAMAL_REGISTRY_PASSWORD
```

### Google Container Registry (GCR)
```yaml
registry:
  server: gcr.io
  username: _json_key
  password:
    - KAMAL_REGISTRY_PASSWORD  # JSON key file content
```

## Server Configuration

### Simple Setup
```yaml
servers:
  web:
    - 192.168.1.10
    - 192.168.1.11
```

### Roles with Hosts
```yaml
servers:
  web:
    hosts:
      - 192.168.1.10
      - 192.168.1.11
  worker:
    hosts:
      - 192.168.1.12
    cmd: bundle exec sidekiq
```

### Role-Specific Configuration
```yaml
servers:
  web:
    hosts:
      - 192.168.1.10
    labels:
      traefik.http.routers.myapp.rule: Host(`example.com`)
    options:
      memory: 2g
      cpus: 2
```

## Environment Variables

### Secret Variables (from .kamal/secrets)
```yaml
env:
  secret:
    - RAILS_MASTER_KEY
    - DATABASE_PASSWORD
    - SECRET_KEY_BASE
```

### Clear Variables
```yaml
env:
  clear:
    LOG_LEVEL: info
    RAILS_ENV: production
```

### Role-Specific Environment
```yaml
servers:
  web:
    hosts:
      - 192.168.1.10
    env:
      clear:
        WEB_CONCURRENCY: 4
  worker:
    hosts:
      - 192.168.1.11
    env:
      clear:
        WORKER_CONCURRENCY: 10
```

## Builder Configuration

### Local Build
```yaml
builder:
  local:
    arch: amd64  # or arm64
```

### Remote Build
```yaml
builder:
  remote:
    arch: amd64
    host: ssh://builder@192.168.1.50
```

### Multi-Architecture Build
```yaml
builder:
  multiarch: true  # Builds for both amd64 and arm64
```

### Build Context and Dockerfile
```yaml
builder:
  context: .
  dockerfile: Dockerfile.production
  args:
    RUBY_VERSION: 3.2.0
```

### Build Cache
```yaml
builder:
  cache:
    type: gha  # GitHub Actions cache
```

## Kamal Proxy Configuration

### Basic Proxy Setup
```yaml
proxy:
  host: example.com  # Domain name
  ssl: true         # Enable automatic SSL/TLS
  app_port: 3000   # Application port
```

### Health Checks
```yaml
proxy:
  host: example.com
  ssl: true
  healthcheck:
    path: /health
    interval: 5      # seconds
    timeout: 3       # seconds
    max_attempts: 3
```

### Path-Based Routing
```yaml
proxy:
  host: example.com
  ssl: true
  app_port: 3000
  deploy_timeout: 30
  path: /app  # Route only /app/* to this service
```

### Response Timeout
```yaml
proxy:
  host: example.com
  response_timeout: 60  # seconds
```

### Buffering
```yaml
proxy:
  buffering:
    requests: true
    responses: true
    memory: 1m
    max_request_body: 0  # 0 = no limit
    max_response_body: 0
```

### Forward Headers
```yaml
proxy:
  forward_headers: true  # Forward X-Forwarded-* headers
```

## Accessories (Supporting Services)

### PostgreSQL Example
```yaml
accessories:
  postgres:
    image: postgres:15
    host: 192.168.1.20
    port: 5432
    env:
      secret:
        - POSTGRES_PASSWORD
      clear:
        POSTGRES_USER: myapp
        POSTGRES_DB: myapp_production
    directories:
      - data:/var/lib/postgresql/data
```

### Redis Example
```yaml
accessories:
  redis:
    image: redis:7
    host: 192.168.1.21
    port: 6379
    directories:
      - data:/data
```

### MySQL Example
```yaml
accessories:
  mysql:
    image: mysql:8
    host: 192.168.1.22
    port: 3306
    env:
      secret:
        - MYSQL_ROOT_PASSWORD
      clear:
        MYSQL_DATABASE: myapp_production
    directories:
      - data:/var/lib/mysql
```

### Litestream (SQLite Replication)
```yaml
accessories:
  litestream:
    image: litestream/litestream:latest
    host: 192.168.1.10
    cmd: replicate
    env:
      secret:
        - LITESTREAM_ACCESS_KEY_ID
        - LITESTREAM_SECRET_ACCESS_KEY
      clear:
        LITESTREAM_BUCKET: mybucket
        LITESTREAM_REGION: us-east-1
    directories:
      - storage:/rails/storage
    files:
      - config/litestream.yml:/etc/litestream.yml
```

## SSH Configuration

### Custom SSH User
```yaml
ssh:
  user: deploy
```

### Custom SSH Port
```yaml
ssh:
  port: 2222
```

### SSH Options
```yaml
ssh:
  options:
    StrictHostKeyChecking: no
    UserKnownHostsFile: /dev/null
```

### Log Level
```yaml
ssh:
  log_level: debug  # or info, warn, error
```

## Volumes

```yaml
volumes:
  - storage:/rails/storage
  - logs:/rails/log
```

## Asset Configuration

For Rails applications with asset pipeline:

```yaml
asset_path: /rails/public/assets
```

## Destinations (Multiple Environments)

### Staging
```yaml
# config/deploy.staging.yml
service: myapp-staging
servers:
  web:
    - 192.168.1.30
```

### Production
```yaml
# config/deploy.yml (default production)
service: myapp
servers:
  web:
    - 192.168.1.10
```

Deploy to staging: `kamal deploy -d staging`

## Aliases

Custom command shortcuts:

```yaml
aliases:
  console: app exec --interactive --reuse "bin/rails console"
  shell: app exec --interactive --reuse "bash"
  logs: app logs -f
  dbc: app exec --interactive --reuse "bin/rails dbconsole"
```

Use: `kamal console` instead of `kamal app exec --interactive --reuse "bin/rails console"`

## Rollout Strategy

### Serial Rollout (default)
```yaml
# Deploys to servers one at a time
```

### Parallel Rollout
```yaml
boot:
  limit: 10  # Deploy to 10 servers at once
```

### Role-Specific Rollout
```yaml
servers:
  web:
    hosts:
      - 192.168.1.10
      - 192.168.1.11
    boot:
      limit: 2
```

## Hooks

Kamal supports hooks at various lifecycle stages:

- `pre-connect`: Before SSH connection
- `pre-build`: Before building image
- `pre-deploy`: Before deploying
- `post-deploy`: After successful deploy

Hooks are shell scripts in `.kamal/hooks/` directory.

Example `.kamal/hooks/pre-deploy`:
```bash
#!/bin/bash
echo "Running database migrations..."
kamal app exec -p "bin/rails db:migrate"
```

## Secrets Management

### .kamal/secrets File
```bash
# .kamal/secrets
KAMAL_REGISTRY_PASSWORD=my-registry-token
RAILS_MASTER_KEY=abc123...
DATABASE_PASSWORD=secure-password
```

### 1Password Integration
```yaml
# In .kamal/secrets
SECRETS=$(kamal secrets fetch --adapter 1password --account my-account --from my-vault)
KAMAL_REGISTRY_PASSWORD=$(kamal secrets extract KAMAL_REGISTRY_PASSWORD $SECRETS)
```

## Logging

### Log Driver
```yaml
logging:
  driver: json-file
  options:
    max-size: "10m"
    max-file: "3"
```

## Healthchecks

### Application Healthcheck
```yaml
healthcheck:
  path: /up
  port: 3000
  max_attempts: 7
  interval: 20
```

### Role-Specific Healthchecks
```yaml
servers:
  web:
    healthcheck:
      path: /health
      interval: 10
  worker:
    healthcheck:
      cmd: bundle exec rake jobs:health
      interval: 30
```

## Complete Example Configuration

```yaml
service: myapp
image: username/myapp

servers:
  web:
    hosts:
      - 192.168.1.10
      - 192.168.1.11
    labels:
      traefik.enable: true
    options:
      memory: 2g
  worker:
    hosts:
      - 192.168.1.12
    cmd: bundle exec sidekiq

registry:
  server: ghcr.io
  username: myuser
  password:
    - KAMAL_REGISTRY_PASSWORD

env:
  secret:
    - RAILS_MASTER_KEY
    - DATABASE_PASSWORD
  clear:
    RAILS_ENV: production
    RAILS_LOG_LEVEL: info

proxy:
  ssl: true
  host: example.com
  healthcheck:
    path: /up
    interval: 5

accessories:
  postgres:
    image: postgres:15
    host: 192.168.1.20
    port: 5432
    env:
      secret:
        - POSTGRES_PASSWORD
      clear:
        POSTGRES_DB: myapp_production
    directories:
      - data:/var/lib/postgresql/data
  
  redis:
    image: redis:7
    host: 192.168.1.21
    directories:
      - data:/data

volumes:
  - storage:/rails/storage

ssh:
  user: deploy

aliases:
  console: app exec --interactive --reuse "bin/rails console"
  shell: app exec --interactive --reuse "bash"
  logs: app logs -f
```
