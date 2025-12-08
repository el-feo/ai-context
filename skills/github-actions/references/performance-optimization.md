# Performance Optimization

Strategies to reduce workflow execution time and resource usage.

## Performance Impact Hierarchy

1. **Caching** (80% time reduction potential) - Biggest impact
2. **Parallelization** (50%+ reduction for independent jobs)
3. **Selective triggers** (Avoid unnecessary runs)
4. **Concurrency control** (Cancel obsolete runs)
5. **Self-hosted runners** (For heavy workloads)
6. **Workflow optimization** (Remove unnecessary steps)

## Dependency Caching

Caching can reduce build times by up to 80% by reusing downloaded dependencies.

### Ruby/Bundler Caching

**Use ruby/setup-ruby with built-in caching** (recommended):

```yaml
- uses: ruby/setup-ruby@v1
  with:
    ruby-version: .ruby-version
    bundler-cache: true  # Automatically caches gems
```

This handles:
- Cache key generation from Gemfile.lock
- ABI compatibility checks
- Old gem cleanup
- Cross-platform caching

**Manual caching** (not recommended - complex edge cases):

```yaml
- uses: actions/cache@v4
  with:
    path: vendor/bundle
    key: ${{ runner.os }}-gems-${{ hashFiles('**/Gemfile.lock') }}
    restore-keys: |
      ${{ runner.os }}-gems-

- run: bundle config set --local path 'vendor/bundle'
- run: bundle install --jobs 4 --retry 3
```

### Node.js/npm Caching

**Use actions/setup-node with built-in caching**:

```yaml
- uses: actions/setup-node@v4
  with:
    node-version: '20'
    cache: 'npm'  # or 'yarn' or 'pnpm'
```

**For npm** (if not using setup-node):

```yaml
- uses: actions/cache@v4
  with:
    path: ~/.npm
    key: ${{ runner.os }}-node-${{ hashFiles('**/package-lock.json') }}
    restore-keys: |
      ${{ runner.os }}-node-
```

**For yarn**:

```yaml
- uses: actions/cache@v4
  with:
    path: |
      .yarn/cache
      .yarn/unplugged
    key: ${{ runner.os }}-yarn-${{ hashFiles('**/yarn.lock') }}
    restore-keys: |
      ${{ runner.os }}-yarn-
```

**For pnpm**:

```yaml
- uses: pnpm/action-setup@v2
  with:
    version: 8

- uses: actions/setup-node@v4
  with:
    node-version: '20'
    cache: 'pnpm'
```

### Python/pip Caching

```yaml
- uses: actions/setup-python@v5
  with:
    python-version: '3.12'
    cache: 'pip'  # or 'pipenv' or 'poetry'
```

Manual:

```yaml
- uses: actions/cache@v4
  with:
    path: ~/.cache/pip
    key: ${{ runner.os }}-pip-${{ hashFiles('**/requirements.txt') }}
    restore-keys: |
      ${{ runner.os }}-pip-
```

### Docker Layer Caching

```yaml
- uses: docker/setup-buildx-action@v3

- uses: docker/build-push-action@v5
  with:
    context: .
    cache-from: type=gha
    cache-to: type=gha,mode=max
```

### Custom Caching

**actions/cache@v4 (required as of March 2025)**:

```yaml
- uses: actions/cache@v4
  with:
    path: |
      ~/.cache/custom
      build/
    key: ${{ runner.os }}-custom-${{ hashFiles('**/lockfile') }}
    restore-keys: |
      ${{ runner.os }}-custom-
```

**Cache key best practices:**
- Include OS: `${{ runner.os }}`
- Hash lock files: `${{ hashFiles('**/Gemfile.lock') }}`
- Version prefix: `v1-${{ runner.os }}-...` (for cache invalidation)

**Restore keys** (fallback if exact match not found):
```yaml
restore-keys: |
  v1-${{ runner.os }}-gems-
  v1-${{ runner.os }}-
```

### Cache Limits

- Maximum cache size: **10 GB per repository**
- Caches evicted after 7 days of no access
- actions/cache@v4+ required (v1-v2 retired March 2025)

### Cache Hit Rate

Monitor cache effectiveness:

```yaml
- uses: actions/cache@v4
  id: cache
  with:
    path: vendor/bundle
    key: ${{ runner.os }}-gems-${{ hashFiles('**/Gemfile.lock') }}

- name: Cache status
  run: |
    if [ "${{ steps.cache.outputs.cache-hit }}" == "true" ]; then
      echo "✅ Cache hit"
    else
      echo "⚠️ Cache miss"
    fi
```

Target: **>80% hit rate** after first run

## Parallelization

### Matrix Builds

Run multiple variations concurrently:

```yaml
jobs:
  test:
    strategy:
      matrix:
        ruby-version: ['3.1', '3.2', '3.3']
        os: [ubuntu-latest, macos-latest]
        include:
          - ruby-version: '3.3'
            experimental: true
        exclude:
          - os: macos-latest
            ruby-version: '3.1'
      fail-fast: false  # Continue if one fails
      max-parallel: 4   # Limit concurrent jobs

    runs-on: ${{ matrix.os }}
    continue-on-error: ${{ matrix.experimental || false }}

    steps:
      - uses: actions/checkout@v4
      - uses: ruby/setup-ruby@v1
        with:
          ruby-version: ${{ matrix.ruby-version }}
          bundler-cache: true
      - run: bundle exec rspec
```

### Independent Jobs

Run jobs in parallel when no dependencies:

```yaml
jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - run: npm run lint

  test:
    runs-on: ubuntu-latest
    steps:
      - run: npm test

  build:
    runs-on: ubuntu-latest
    steps:
      - run: npm run build

  # These 3 jobs run in parallel (no 'needs')
```

### Sequential with Dependencies

Only use `needs` when actually required:

```yaml
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - run: npm run build

  test:
    needs: build  # Waits for build
    runs-on: ubuntu-latest
    steps:
      - run: npm test

  deploy:
    needs: [build, test]  # Waits for both
    runs-on: ubuntu-latest
    steps:
      - run: ./deploy.sh
```

### Test Splitting

For large test suites, split across multiple runners:

```yaml
jobs:
  test:
    strategy:
      matrix:
        shard: [1, 2, 3, 4]
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      # RSpec parallel
      - run: |
          bundle exec rspec --only-failures --next-failure \
            $(find spec -name '*_spec.rb' | awk "NR % 4 == ${{ matrix.shard }}")

      # Jest parallel (built-in)
      - run: npm test -- --shard=${{ matrix.shard }}/4
```

## Selective Triggers

### Path Filters

Only run when specific files change:

```yaml
on:
  push:
    paths:
      - 'src/**'
      - 'package.json'
      - 'package-lock.json'
    paths-ignore:
      - '**.md'
      - 'docs/**'
```

### Branch Filters

```yaml
on:
  push:
    branches:
      - main
      - 'releases/**'
  pull_request:
    branches:
      - main
```

### Conditional Jobs

```yaml
jobs:
  deploy:
    if: github.ref == 'refs/heads/main' && github.event_name == 'push'
    runs-on: ubuntu-latest
```

### Skip CI

Check commit message for skip directives:

```yaml
jobs:
  test:
    if: "!contains(github.event.head_commit.message, '[skip ci]')"
    runs-on: ubuntu-latest
```

## Concurrency Control

Cancel outdated workflow runs:

```yaml
concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true
```

**Use cases:**
- PR pushes (cancel previous commit checks)
- Branch pushes (cancel older runs)

**Don't use for:**
- Deployment workflows (let complete)
- Release workflows (should never cancel)

### Per-workflow concurrency

```yaml
# .github/workflows/ci.yml
concurrency:
  group: ci-${{ github.ref }}
  cancel-in-progress: true

# .github/workflows/deploy.yml
concurrency:
  group: deploy-${{ github.ref }}
  cancel-in-progress: false  # Let deployments complete
```

## Workflow Optimization

### Remove Unnecessary Steps

**Before:**
```yaml
- run: npm install
- run: npm run lint
- run: npm run typecheck
- run: npm test
- run: npm run build
```

**After (combine independent steps):**
```yaml
- run: npm ci  # Faster than install
- run: npm run lint & npm run typecheck & wait  # Parallel
- run: npm test
- run: npm run build
```

### Shallow Checkout

Don't fetch full history if not needed:

```yaml
- uses: actions/checkout@v4
  with:
    fetch-depth: 1  # Only fetch latest commit (default)

# Only use fetch-depth: 0 when you need full history
```

### Sparse Checkout

Only checkout specific paths:

```yaml
- uses: actions/checkout@v4
  with:
    sparse-checkout: |
      src/
      package.json
```

### Minimize Network Requests

```yaml
# ❌ SLOW: Multiple fetches
- run: curl https://example.com/file1.txt
- run: curl https://example.com/file2.txt
- run: curl https://example.com/file3.txt

# ✅ FAST: Parallel or combined
- run: |
    curl -O https://example.com/file1.txt &
    curl -O https://example.com/file2.txt &
    curl -O https://example.com/file3.txt &
    wait
```

### Timeouts

Prevent hanging workflows:

```yaml
jobs:
  test:
    runs-on: ubuntu-latest
    timeout-minutes: 10  # Job timeout

    steps:
      - name: Long task
        timeout-minutes: 5  # Step timeout
        run: npm test
```

## Self-Hosted Runners

For heavy or frequent workloads, self-hosted runners can be faster.

### Benefits

- **Persistent caching** across runs (no download overhead)
- **Faster startup** (no VM provisioning)
- **Custom hardware** (more CPU, RAM, GPU)
- **Network proximity** to private resources

### Setup

```yaml
jobs:
  build:
    runs-on: [self-hosted, linux, x64]
    steps:
      - uses: actions/checkout@v4
      - run: npm run build
```

### Caching on Self-Hosted

Persistent directories:

```yaml
# Dependencies stay on disk between runs
- run: |
    if [ ! -d "node_modules" ]; then
      npm ci
    fi
```

### Security Considerations

See [security-checklist.md](security-checklist.md) - self-hosted runners have significant security implications.

## Resource Optimization

### Smaller Docker Images

```dockerfile
# ❌ LARGE: 1.2 GB
FROM node:20

# ✅ SMALL: 200 MB
FROM node:20-slim

# ✅ SMALLEST: 150 MB
FROM node:20-alpine
```

### Multi-stage Docker Builds

```dockerfile
# Build stage
FROM node:20 AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production
COPY . .
RUN npm run build

# Production stage
FROM node:20-slim
WORKDIR /app
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/node_modules ./node_modules
CMD ["node", "dist/index.js"]
```

### Reduce Artifact Size

```yaml
- uses: actions/upload-artifact@v4
  with:
    name: build
    path: |
      dist/
      !dist/**/*.map  # Exclude source maps
    retention-days: 1  # Clean up quickly
```

## Monitoring Performance

### Workflow Timing

View in Actions UI:
- Total workflow time
- Per-job timing
- Per-step timing

### Identify Bottlenecks

```yaml
- name: Install dependencies
  run: |
    echo "::group::Install dependencies"
    time npm ci
    echo "::endgroup::"

- name: Run tests
  run: |
    echo "::group::Run tests"
    time npm test
    echo "::endgroup::"
```

### Profiling Commands

```yaml
- name: Profile build
  run: |
    time npm run build
    du -sh dist/  # Check output size
```

### Performance Regression Detection

Track execution time over time:

```yaml
- name: Save timing
  run: |
    echo "${{ github.run_number }}: $SECONDS seconds" >> timings.txt
    git add timings.txt
    git commit -m "Add timing data"
    git push
```

## Advanced Caching Strategies

### Cross-Job Caching

```yaml
jobs:
  build:
    steps:
      - run: npm run build
      - uses: actions/cache@v4
        with:
          path: dist/
          key: build-${{ github.sha }}

  test:
    needs: build
    steps:
      - uses: actions/cache@v4
        with:
          path: dist/
          key: build-${{ github.sha }}
      - run: npm test
```

### Warm Cache Strategy

Prime cache in off-hours:

```yaml
on:
  schedule:
    - cron: '0 2 * * *'  # 2 AM daily

jobs:
  warm-cache:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: ruby/setup-ruby@v1
        with:
          ruby-version: .ruby-version
          bundler-cache: true
      - run: echo "Cache warmed"
```

### Multi-level Caching

```yaml
- uses: actions/cache@v4
  with:
    path: ~/.npm
    key: ${{ runner.os }}-npm-${{ hashFiles('**/package-lock.json') }}
    restore-keys: |
      ${{ runner.os }}-npm-${{ hashFiles('**/package-lock.json') }}
      ${{ runner.os }}-npm-
      ${{ runner.os }}-
```

## Reusable Workflows

Extract common patterns to avoid duplication:

```yaml
# .github/workflows/reusable-test.yml
on:
  workflow_call:
    inputs:
      ruby-version:
        type: string
        required: true

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: ruby/setup-ruby@v1
        with:
          ruby-version: ${{ inputs.ruby-version }}
          bundler-cache: true
      - run: bundle exec rspec
```

```yaml
# .github/workflows/ci.yml
jobs:
  test-3-2:
    uses: ./.github/workflows/reusable-test.yml
    with:
      ruby-version: '3.2'

  test-3-3:
    uses: ./.github/workflows/reusable-test.yml
    with:
      ruby-version: '3.3'
```

**Benefits:**
- Reduced duplication
- Centralized updates
- Up to 50 workflow calls per run (Nov 2025)
- Up to 10 levels of nesting (Nov 2025)

## Performance Checklist

- [ ] Dependency caching enabled (ruby/setup-ruby, actions/setup-node, etc.)
- [ ] Cache hit rate >80% after first run
- [ ] Independent jobs run in parallel (no unnecessary `needs`)
- [ ] Path filters used to skip irrelevant changes
- [ ] Concurrency control cancels outdated runs
- [ ] Timeouts set on long-running jobs/steps
- [ ] Shallow checkout used (fetch-depth: 1)
- [ ] Test suites split across multiple runners (if >5 minutes)
- [ ] Docker images use slim/alpine variants
- [ ] Workflow execution time monitored and optimized
- [ ] Reusable workflows used for common patterns

## Target Metrics

| Workflow Type | Target Time |
|---------------|-------------|
| Linting | <2 minutes |
| Unit tests | <5 minutes |
| Integration tests | <10 minutes |
| Full CI | <15 minutes |
| Deployment | <10 minutes |

**If exceeding targets:**
1. Enable caching
2. Parallelize independent steps
3. Split test suites
4. Consider self-hosted runners
5. Profile and optimize slow steps

## Resources

- [Caching dependencies](https://docs.github.com/en/actions/using-workflows/caching-dependencies-to-speed-up-workflows)
- [actions/cache](https://github.com/actions/cache)
- [Monitoring and troubleshooting workflows](https://docs.github.com/en/actions/monitoring-and-troubleshooting-workflows)
