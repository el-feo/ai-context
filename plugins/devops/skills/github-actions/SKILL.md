---
name: github-actions
description: Create, evaluate, and optimize GitHub Actions workflows and custom actions. Use when building CI/CD pipelines, creating workflow files, developing custom actions, troubleshooting workflow failures, performing security analysis, optimizing performance, or reviewing GitHub Actions best practices. Covers Ruby/Rails, TypeScript/Node.js, Heroku and Fly.io deployments.
---

# GitHub Actions

GitHub Actions automates software workflows with event-driven CI/CD pipelines. Workflows are YAML files in `.github/workflows/` that define jobs, steps, and actions triggered by repository events.

**Action types:**
- **Workflow files**: CI/CD pipelines using existing actions (`.github/workflows/*.yml`)
- **Custom JavaScript actions**: Fast, cross-platform, use `@actions/toolkit`
- **Custom Docker actions**: Full environment control, Linux only, slower startup
- **Composite actions**: Combine multiple steps into reusable units

## Quick Start

```yaml
# .github/workflows/ci.yml
name: CI
on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

permissions:
  contents: read

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Run tests
        run: npm test
```

**Ruby/Rails with RSpec:**

```yaml
- uses: ruby/setup-ruby@v1
  with:
    ruby-version: .ruby-version
    bundler-cache: true

- name: Setup database
  env:
    RAILS_ENV: test
  run: bin/rails db:setup

- run: bundle exec rspec
```

**TypeScript/Node.js:**

```yaml
- uses: actions/setup-node@v4
  with:
    node-version: '20'
    cache: 'npm'

- run: npm ci
- run: npm run build --if-present
- run: npm test
```

**Deploy to Fly.io:**

```yaml
- uses: superfly/flyctl-actions/setup-flyctl@1.5
- run: flyctl deploy --remote-only
  env:
    FLY_API_TOKEN: ${{ secrets.FLY_API_TOKEN }}
```

## Creating Workflows

1. **Identify triggers**: push, pull_request, workflow_dispatch, schedule, etc.
2. **Define jobs**: Specify runner OS, steps, and dependencies
3. **Add security**: Set GITHUB_TOKEN permissions to read-only, pin actions to SHA
4. **Optimize performance**: Enable caching, use matrix builds for parallelization
5. **Test locally**: Use `act` or GitHub CLI to test before pushing

## Evaluating Workflows

1. **Security scan**: Check permissions, secrets exposure, action pinning, pull_request_target usage
2. **Performance analysis**: Identify slow steps, missing caches, parallelization opportunities
3. **Best practices review**: Validate naming, structure, error handling, documentation

## Critical Security Patterns

1. **Always set GITHUB_TOKEN permissions to read-only**:
   ```yaml
   permissions:
     contents: read
   ```

2. **Pin actions to commit SHA** (most secure):
   ```yaml
   - uses: actions/checkout@b4ffde65f46336ab88eb53be808477a3936bae11 # v4.1.1
   ```

3. **Use OIDC for cloud deployments** (credential-less):
   ```yaml
   permissions:
     id-token: write
     contents: read
   ```

4. **Avoid pull_request_target with untrusted code** - runs in base repository context with access to secrets

5. **Never log secrets** - use `::add-mask::` for dynamic values

6. **Validate user-controlled inputs via environment variables**:
   ```yaml
   - env:
       TITLE: ${{ github.event.issue.title }}
     run: echo "Title: $TITLE"
   ```

For complete security guidelines, see [references/security-checklist.md](references/security-checklist.md).

## Key Anti-Patterns

- Running as root in Docker actions
- Hardcoded secrets (always use GitHub Secrets)
- Overly broad permissions
- No caching (wastes time on every run)
- Sequential jobs that could be parallel
- Using branch references for actions (use tags or SHAs)
- No `timeout-minutes` (jobs default to 6 hours)
- `fetch-depth: 0` when full history isn't needed

## Concurrency Control

Cancel outdated runs to save resources:

```yaml
concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true
```

## Reference Guides

For detailed information on specific topics:

- **[Workflow Syntax](references/workflow-syntax.md)**: Complete YAML reference - triggers, jobs, steps, expressions, contexts, matrix, reusable workflows
- **[Custom Actions](references/custom-actions.md)**: Building JavaScript, Docker, and composite actions with `@actions/toolkit`
- **[Security Checklist](references/security-checklist.md)**: GITHUB_TOKEN permissions, action pinning, OIDC setup, secrets management, input validation, self-hosted runner security
- **[Performance Optimization](references/performance-optimization.md)**: Dependency caching (Ruby/Node/Python/Docker), parallelization, selective triggers, test splitting, self-hosted runners
- **[Common Workflows](references/common-workflows.md)**: Production-ready templates for Rails CI/CD, TypeScript CI, Heroku/Fly.io deployments, monorepos, release automation, full-stack examples
- **[Troubleshooting](references/troubleshooting.md)**: Permission errors, caching issues, secret problems, database connections, timeout debugging, `act` for local testing

## Validation Checklist

**Pre-deployment:**
- YAML syntax valid
- Required secrets configured
- GITHUB_TOKEN permissions set to minimum required
- Actions pinned to SHA or trusted tags
- Caching configured for dependencies
- Workflow triggers appropriate for use case

**Post-deployment:**
- First run completes successfully
- Execution time acceptable (<15 min for full CI)
- No secrets in logs
- Cache hit rate >80% after first run
