# Troubleshooting GitHub Actions

Common issues, debugging strategies, and solutions for GitHub Actions workflows.

## Quick Diagnosis

| Symptom | Likely Cause | Quick Fix |
|---------|-------------|-----------|
| "Resource not accessible by integration" | Missing permissions | Add required permissions to GITHUB_TOKEN |
| Cache not restoring | Key mismatch or expired | Verify cache key, check 7-day limit |
| Secret not available | Not configured or wrong scope | Check repository/environment secrets |
| Command not found | Setup step missing or wrong PATH | Add setup action before command |
| Workflow timeout (6 hours) | Hanging process | Add timeout-minutes to job/steps |
| "ref does not exist" | Branch/tag deleted | Check if ref still exists |
| Container action fails | Docker issues | Check Dockerfile, use pre-built image |

## Permission Errors

### "Resource not accessible by integration"

**Error:**
```
Error: Resource not accessible by integration
```

**Cause:** GITHUB_TOKEN lacks required permissions

**Solution:**

```yaml
permissions:
  contents: write       # For pushing commits/tags
  pull-requests: write  # For PR comments
  issues: write         # For issue comments
  packages: write       # For publishing packages
  deployments: write    # For deployments
```

**Debug:**
```yaml
- name: Check token permissions
  run: |
    curl -H "Authorization: token ${{ secrets.GITHUB_TOKEN }}" \
         https://api.github.com/repos/${{ github.repository }}
```

### "Permission denied" for actions

**Error:**
```
Error: permission denied while trying to connect to the Docker daemon socket
```

**Cause:** Self-hosted runner needs Docker group membership

**Solution:**
```bash
# On self-hosted runner
sudo usermod -aG docker $USER
sudo systemctl restart docker
```

## Caching Issues

### Cache not restoring

**Check cache key:**
```yaml
- uses: actions/cache@v4
  id: cache
  with:
    path: ~/.npm
    key: ${{ runner.os }}-npm-${{ hashFiles('**/package-lock.json') }}

- name: Debug cache
  run: |
    echo "Cache hit: ${{ steps.cache.outputs.cache-hit }}"
    echo "Cache key: ${{ runner.os }}-npm-${{ hashFiles('**/package-lock.json') }}"
```

**Common causes:**
1. **Lock file changed** - Expected behavior, cache will rebuild
2. **Cache expired** - Caches older than 7 days are deleted
3. **Cache size limit** - Repository has >10GB of caches
4. **Wrong cache key** - Typo or incorrect hash file path

**Solutions:**
```yaml
# Use restore-keys for fallback
- uses: actions/cache@v4
  with:
    path: ~/.npm
    key: v1-${{ runner.os }}-npm-${{ hashFiles('**/package-lock.json') }}
    restore-keys: |
      v1-${{ runner.os }}-npm-
      v1-${{ runner.os }}-

# Increment version prefix to invalidate all caches
```

### Cache Actions v1-v2 deprecated (March 2025)

**Error:**
```
actions/cache@v2 is deprecated
```

**Solution:**
```yaml
# ❌ OLD
- uses: actions/cache@v2

# ✅ NEW (required after March 2025)
- uses: actions/cache@v4
```

## Secret Issues

### Secret not available

**Error:**
```
Error: The secret 'API_KEY' is not defined
```

**Check secret location:**

1. **Repository secrets:** Settings → Secrets and variables → Actions
2. **Environment secrets:** Settings → Environments → [environment] → Secrets
3. **Organization secrets:** Organization settings → Secrets and variables

**Solution:**
```yaml
# For repository secrets
env:
  API_KEY: ${{ secrets.API_KEY }}

# For environment secrets (requires environment)
jobs:
  deploy:
    environment: production
    steps:
      - run: ./deploy.sh
        env:
          API_KEY: ${{ secrets.API_KEY }}
```

### Secret value is empty

**Debug:**
```yaml
- name: Check secret
  run: |
    if [ -z "$API_KEY" ]; then
      echo "API_KEY is not set or empty"
      exit 1
    fi
    echo "API_KEY is set (length: ${#API_KEY})"
  env:
    API_KEY: ${{ secrets.API_KEY }}
```

**Common causes:**
- Secret value has leading/trailing whitespace
- Secret was deleted
- Wrong secret name (case-sensitive)

## Dependency Installation Failures

### Bundler errors (Ruby)

**Error:**
```
Your bundle is locked to mimemagic (0.3.5), but that version could not be found
```

**Solutions:**
```yaml
# Delete Gemfile.lock and regenerate
- run: |
    rm Gemfile.lock
    bundle install

# Or update specific gem
- run: bundle update mimemagic
```

**Error:**
```
An error occurred while installing pg (1.5.4), and Bundler cannot continue
```

**Solution:**
```yaml
# Install PostgreSQL development headers
- run: sudo apt-get update && sudo apt-get install -y libpq-dev
```

### npm/yarn errors (Node.js)

**Error:**
```
ENOENT: no such file or directory, open '/home/runner/work/.../package.json'
```

**Solution:**
```yaml
# Verify working directory
- run: pwd && ls -la

# Or set working directory
- run: npm ci
  working-directory: ./frontend
```

**Error:**
```
npm ERR! code ELIFECYCLE
npm ERR! errno 1
```

**Debug:**
```yaml
- name: Install with verbose logging
  run: npm ci --loglevel verbose
```

## Database Connection Issues

### PostgreSQL connection refused

**Error:**
```
PG::ConnectionBad: could not connect to server: Connection refused
```

**Solution:**
```yaml
services:
  postgres:
    image: postgres:16
    env:
      POSTGRES_PASSWORD: postgres
    # Add health check - wait for PostgreSQL to be ready
    options: >-
      --health-cmd pg_isready
      --health-interval 10s
      --health-timeout 5s
      --health-retries 5
    ports:
      - 5432:5432

steps:
  - name: Wait for PostgreSQL
    run: |
      until pg_isready -h localhost -p 5432 -U postgres; do
        sleep 1
      done

  - name: Setup database
    env:
      DATABASE_URL: postgres://postgres:postgres@localhost:5432/test
    run: bin/rails db:setup
```

### Service container networking

**Issue:** Can't connect to service from job

**Solution:**
```yaml
# Use 'localhost' for Linux runners
DATABASE_URL: postgres://postgres:postgres@localhost:5432/test

# Use service name for container jobs
jobs:
  test:
    container:
      image: ruby:3.3
    services:
      postgres:
        image: postgres:16

    env:
      # Use service name when running in container
      DATABASE_URL: postgres://postgres:postgres@postgres:5432/test
```

## Timeout Issues

### Workflow takes too long

**Default timeout:** 6 hours (360 minutes)

**Set reasonable timeouts:**
```yaml
jobs:
  test:
    runs-on: ubuntu-latest
    timeout-minutes: 30  # Job timeout

    steps:
      - name: Run tests
        timeout-minutes: 20  # Step timeout
        run: npm test
```

**Investigate slow steps:**
```yaml
- name: Profile step
  run: |
    time npm ci
    time npm test
    time npm run build
```

### Job or step hangs

**Common causes:**
1. Waiting for user input
2. Infinite loop
3. Network request timeout
4. Database connection pool exhausted

**Debug:**
```yaml
- name: Add debugging
  run: |
    set -x  # Print commands
    npm test
  timeout-minutes: 5
```

## Action Execution Errors

### "Command not found"

**Error:**
```
bash: npm: command not found
```

**Solution:**
```yaml
# Add setup action first
- uses: actions/setup-node@v4
  with:
    node-version: '20'

# Then run command
- run: npm ci
```

### Docker action fails

**Error:**
```
Error: Docker pull failed with exit code 1
```

**Solutions:**

1. **Check Dockerfile syntax:**
```dockerfile
FROM node:20-slim

# Use valid base image
# Check for typos in commands
```

2. **Use pre-built image:**
```yaml
# Instead of building on every run
runs:
  using: 'docker'
  image: 'docker://ghcr.io/username/action:v1'
```

3. **Check Docker Hub rate limits:**
```yaml
# Login to Docker Hub first
- uses: docker/login-action@v3
  with:
    username: ${{ secrets.DOCKER_USERNAME }}
    password: ${{ secrets.DOCKER_PASSWORD }}
```

## Git Issues

### "ref does not exist"

**Error:**
```
Error: Ref refs/heads/feature-branch does not exist
```

**Cause:** Branch was deleted or renamed

**Solution:**
```yaml
# Check if branch exists before checkout
- name: Safe checkout
  run: |
    if git ls-remote --heads origin ${{ github.ref }}; then
      git checkout ${{ github.ref }}
    else
      echo "Branch does not exist"
      exit 1
    fi
```

### Detached HEAD state

**Issue:** Not on any branch after checkout

**Solution:**
```yaml
# Checkout specific branch
- uses: actions/checkout@v4
  with:
    ref: main

# Or for PRs, use the head SHA
- uses: actions/checkout@v4
  with:
    ref: ${{ github.event.pull_request.head.sha }}
```

### Merge conflicts in pull_request

**Error:**
```
Error: Merge conflict in file.js
```

**Solution:**
```yaml
# Only checkout PR code, don't try to merge
- uses: actions/checkout@v4
  with:
    ref: ${{ github.event.pull_request.head.sha }}
```

## Environment Variable Issues

### Variable not accessible

**Error:**
```
Variable not set: NODE_VERSION
```

**Check variable scope:**
```yaml
# Workflow-level - available to all jobs
env:
  NODE_VERSION: '20'

jobs:
  test:
    # Job-level - only this job
    env:
      RAILS_ENV: test

    steps:
      # Step-level - only this step
      - name: Build
        env:
          NODE_ENV: production
        run: npm run build
```

### GitHub context not accessible

**Wrong:**
```yaml
- run: echo "Branch: $github.ref"
```

**Correct:**
```yaml
- run: echo "Branch: ${{ github.ref }}"

# Or use GITHUB_* environment variables
- run: echo "Branch: $GITHUB_REF"
```

## Artifact Issues

### Artifact upload fails

**Error:**
```
Error: No files were found with the provided path
```

**Solution:**
```yaml
# Verify path exists
- name: Check build output
  run: ls -la dist/

- uses: actions/upload-artifact@v4
  with:
    name: build
    path: dist/
    if-no-files-found: error  # or 'warn' or 'ignore'
```

### Artifact download fails

**Error:**
```
Error: Artifact 'build' not found
```

**Cause:** Wrong artifact name or not uploaded yet

**Solution:**
```yaml
jobs:
  build:
    steps:
      - uses: actions/upload-artifact@v4
        with:
          name: dist-files  # Note the name
          path: dist/

  deploy:
    needs: build  # Wait for build to complete
    steps:
      - uses: actions/download-artifact@v4
        with:
          name: dist-files  # Must match upload name
```

## Workflow Trigger Issues

### Workflow not triggering

**Check:**

1. **Workflow file location:** Must be in `.github/workflows/`
2. **File extension:** Must be `.yml` or `.yaml`
3. **YAML syntax:** Must be valid YAML
4. **Trigger configuration:**

```yaml
# Wrong - workflow never runs
on:
  push:
    branches: []  # Empty array

# Correct
on:
  push:
    branches: [main]
```

### Workflow triggers on wrong events

```yaml
# Only on push to main
on:
  push:
    branches: [main]

# On push AND pull_request to main
on:
  push:
    branches: [main]
  pull_request:
    branches: [main]
```

### workflow_dispatch not showing

**Error:** Manual trigger button doesn't appear

**Requirements:**
1. Workflow must be on default branch (usually `main`)
2. Must include `workflow_dispatch` trigger

```yaml
on:
  workflow_dispatch:
    inputs:
      environment:
        description: 'Deployment environment'
        required: true
        type: choice
        options:
          - development
          - staging
          - production
```

## Self-Hosted Runner Issues

### Runner offline

**Check:**
1. Runner process is running
2. Network connectivity to GitHub
3. Runner registration token not expired

**Restart runner:**
```bash
cd actions-runner
./run.sh
```

### Runner out of disk space

**Check disk usage:**
```bash
df -h
du -sh /path/to/runner/_work/*
```

**Clean up:**
```bash
# Remove old builds
rm -rf _work/_temp/*
rm -rf _work/_actions/*

# Clean Docker
docker system prune -af
```

## Advanced Debugging

### Enable debug logging

**Repository Settings → Secrets:**
- Add secret: `ACTIONS_RUNNER_DEBUG` = `true`
- Add secret: `ACTIONS_STEP_DEBUG` = `true`

Re-run workflow to see verbose logs.

### SSH into runner (for debugging)

```yaml
- name: Setup tmate session
  uses: mxschmitt/action-tmate@v3
  if: failure()  # Only on failure
```

Provides SSH access to runner environment for live debugging.

### Reproduce locally with act

```bash
# Install act
brew install act

# Run workflow locally
act push

# Run specific job
act -j test

# Pass secrets
act -s GITHUB_TOKEN=your_token
```

### Inspect runner environment

```yaml
- name: Debug environment
  run: |
    echo "=== Environment Variables ==="
    printenv | sort

    echo "=== GitHub Context ==="
    echo "Actor: ${{ github.actor }}"
    echo "Event: ${{ github.event_name }}"
    echo "Ref: ${{ github.ref }}"
    echo "SHA: ${{ github.sha }}"

    echo "=== System Info ==="
    uname -a
    df -h
    free -h

    echo "=== Installed Software ==="
    node --version
    npm --version
    ruby --version
    python --version
```

## Common Error Messages

### "Expression evaluation failed"

**Error:**
```
Error: Unrecognized named-value: 'steps'. Located at position 1 within expression: steps.cache.outputs.cache-hit
```

**Cause:** Referencing step output before step runs

**Solution:**
```yaml
# Wrong - step hasn't run yet
- if: steps.cache.outputs.cache-hit == 'true'
  uses: actions/cache@v4
  id: cache

# Correct - check output after step runs
- uses: actions/cache@v4
  id: cache

- if: steps.cache.outputs.cache-hit == 'true'
  run: echo "Cache hit!"
```

### "Context access might be invalid"

**Error:**
```
Warning: Context access might be invalid: github.event.issue.title
```

**Cause:** Accessing context that doesn't exist for this event

**Solution:**
```yaml
# Check event type first
- name: Process issue
  if: github.event_name == 'issues'
  run: echo "Issue: ${{ github.event.issue.title }}"
```

## Performance Debugging

### Identify slow steps

```yaml
- name: Benchmark steps
  run: |
    echo "::group::Install"
    time npm ci
    echo "::endgroup::"

    echo "::group::Build"
    time npm run build
    echo "::endgroup::"

    echo "::group::Test"
    time npm test
    echo "::endgroup::"
```

### Check cache effectiveness

```yaml
- uses: actions/cache@v4
  id: cache
  with:
    path: ~/.npm
    key: ${{ runner.os }}-npm-${{ hashFiles('**/package-lock.json') }}

- name: Report cache status
  run: |
    echo "Cache hit: ${{ steps.cache.outputs.cache-hit }}"
    if [ "${{ steps.cache.outputs.cache-hit }}" != "true" ]; then
      echo "⚠️ Cache miss - installation will be slower"
    fi
```

## Getting Help

### Check workflow logs

1. Go to Actions tab in repository
2. Click on workflow run
3. Click on failed job
4. Expand failed step
5. Review error message and logs

### Check Actions status

- [GitHub Status](https://www.githubstatus.com/)
- Look for incidents affecting GitHub Actions

### Community resources

- [GitHub Community Discussions](https://github.com/orgs/community/discussions/categories/actions)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Awesome Actions](https://github.com/sdras/awesome-actions)

### Contact support

For persistent issues:
- GitHub Enterprise: Contact support
- Public repositories: Post in Community Discussions
- Security issues: security@github.com

## Debugging Checklist

When workflow fails:

- [ ] Check error message in logs
- [ ] Verify YAML syntax (use yamllint)
- [ ] Check file paths and working directories
- [ ] Verify environment variables are set
- [ ] Check GITHUB_TOKEN permissions
- [ ] Verify secrets are configured correctly
- [ ] Check service container health
- [ ] Review recent changes to workflow file
- [ ] Test locally with `act` if possible
- [ ] Enable debug logging (ACTIONS_STEP_DEBUG)
- [ ] Check GitHub Actions status page
- [ ] Review similar workflow runs for patterns
