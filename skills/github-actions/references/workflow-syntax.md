# Workflow Syntax Reference

Complete YAML syntax reference for GitHub Actions workflows.

## Basic Structure

```yaml
name: Workflow Name          # Optional: Display name in Actions UI
run-name: Custom Run Name    # Optional: Custom name for workflow runs

on: [push, pull_request]     # Triggers

permissions:                 # Optional: GITHUB_TOKEN permissions
  contents: read

env:                        # Optional: Global environment variables
  NODE_VERSION: '20'

jobs:
  job-id:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: echo "Hello World"
```

## Workflow Triggers (`on`)

### Single event
```yaml
on: push
```

### Multiple events
```yaml
on: [push, pull_request, workflow_dispatch]
```

### Event with configuration
```yaml
on:
  push:
    branches:
      - main
      - 'releases/**'
    tags:
      - v1.*
    paths:
      - '**.js'
      - 'src/**'
    paths-ignore:
      - 'docs/**'

  pull_request:
    branches:
      - main
    types:
      - opened
      - synchronize
      - reopened

  workflow_dispatch:
    inputs:
      environment:
        description: 'Environment to deploy to'
        required: true
        type: choice
        options:
          - development
          - staging
          - production

  schedule:
    - cron: '0 0 * * 0'  # Weekly on Sunday at midnight

  workflow_call:
    inputs:
      config-path:
        required: true
        type: string
    secrets:
      token:
        required: true
```

### Common trigger types
- `push`: Code pushed to repository
- `pull_request`: PR opened, synchronized, reopened (runs in PR's base branch context)
- `pull_request_target`: Like pull_request but runs in base repository context with secrets (DANGEROUS with untrusted code)
- `workflow_dispatch`: Manual trigger from Actions UI
- `workflow_call`: Called by another workflow (reusable workflows)
- `schedule`: Cron-based scheduling
- `release`: Release published, created, edited, etc.
- `issues`: Issue opened, edited, closed, etc.
- `issue_comment`: Comment on issue or PR

## Permissions

### Default (read-only recommended)
```yaml
permissions: read-all  # or 'write-all' (not recommended)
```

### Granular permissions
```yaml
permissions:
  contents: read        # Repository contents
  pull-requests: write  # PR comments, labels, reviews
  issues: write         # Issue comments, labels
  packages: write       # GitHub Packages
  deployments: write    # Deployments
  id-token: write       # OIDC token for cloud auth
```

### Job-level permissions (override workflow-level)
```yaml
permissions:
  contents: read

jobs:
  deploy:
    permissions:
      contents: write
      deployments: write
```

## Environment Variables

### Workflow-level
```yaml
env:
  API_URL: https://api.example.com
  NODE_VERSION: '20'
```

### Job-level
```yaml
jobs:
  test:
    env:
      RAILS_ENV: test
      DATABASE_URL: postgres://localhost/test
```

### Step-level
```yaml
- name: Run tests
  env:
    DEBUG: true
  run: npm test
```

## Jobs

### Basic job
```yaml
jobs:
  job-id:
    name: Job Display Name
    runs-on: ubuntu-latest
    timeout-minutes: 30
    steps:
      - run: echo "Hello"
```

### Runner selection
```yaml
runs-on: ubuntu-latest       # Ubuntu 24 (as of Dec 2024)
runs-on: ubuntu-22.04        # Specific Ubuntu version
runs-on: macos-latest        # macOS (currently macOS 14)
runs-on: macos-latest-xlarge # M2 macOS runner (Nov 2025+)
runs-on: windows-latest      # Windows Server

# Self-hosted
runs-on: [self-hosted, linux, x64]
```

### Job dependencies
```yaml
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - run: npm run build

  test:
    needs: build              # Runs after build completes
    runs-on: ubuntu-latest
    steps:
      - run: npm test

  deploy:
    needs: [build, test]      # Runs after both complete
    runs-on: ubuntu-latest
    steps:
      - run: ./deploy.sh
```

### Conditional execution
```yaml
jobs:
  deploy:
    if: github.ref == 'refs/heads/main'
    runs-on: ubuntu-latest
```

### Matrix strategy
```yaml
jobs:
  test:
    strategy:
      matrix:
        os: [ubuntu-latest, macos-latest, windows-latest]
        node-version: [18, 20, 22]
        include:
          - os: ubuntu-latest
            node-version: 20
            experimental: true
        exclude:
          - os: macos-latest
            node-version: 18
      fail-fast: false  # Continue other jobs if one fails
      max-parallel: 3   # Limit concurrent jobs

    runs-on: ${{ matrix.os }}
    steps:
      - uses: actions/setup-node@v4
        with:
          node-version: ${{ matrix.node-version }}
```

### Outputs
```yaml
jobs:
  build:
    runs-on: ubuntu-latest
    outputs:
      version: ${{ steps.get-version.outputs.version }}
    steps:
      - id: get-version
        run: echo "version=1.2.3" >> $GITHUB_OUTPUT

  deploy:
    needs: build
    runs-on: ubuntu-latest
    steps:
      - run: echo "Deploying version ${{ needs.build.outputs.version }}"
```

### Services (Docker containers)
```yaml
jobs:
  test:
    runs-on: ubuntu-latest

    services:
      postgres:
        image: postgres:16
        env:
          POSTGRES_PASSWORD: postgres
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
        ports:
          - 5432:5432

      redis:
        image: redis:7
        ports:
          - 6379:6379
```

### Environment (deployment protection)
```yaml
jobs:
  deploy:
    runs-on: ubuntu-latest
    environment:
      name: production
      url: https://example.com
    steps:
      - run: ./deploy.sh
```

## Steps

### Run shell commands
```yaml
- name: Single command
  run: echo "Hello World"

- name: Multiple commands
  run: |
    echo "Line 1"
    echo "Line 2"
    npm install

- name: Specify shell
  shell: bash
  run: echo "Hello"
```

### Use actions
```yaml
- uses: actions/checkout@v4

- uses: actions/setup-node@v4
  with:
    node-version: '20'
    cache: 'npm'

- uses: ./.github/actions/my-local-action
  with:
    input-param: value
```

### Conditional steps
```yaml
- name: Deploy
  if: github.ref == 'refs/heads/main' && success()
  run: ./deploy.sh

- name: Notify on failure
  if: failure()
  run: curl -X POST $WEBHOOK_URL
```

### Continue on error
```yaml
- name: Experimental feature
  continue-on-error: true
  run: npm run experimental
```

### Set outputs
```yaml
- id: step-id
  run: echo "result=success" >> $GITHUB_OUTPUT

- name: Use output
  run: echo "Result was ${{ steps.step-id.outputs.result }}"
```

### Working directory
```yaml
- name: Run in subdirectory
  working-directory: ./frontend
  run: npm test
```

### Timeout
```yaml
- name: Long-running task
  timeout-minutes: 10
  run: npm run build
```

## Expressions and Contexts

### Common expressions
```yaml
# Equality
if: github.ref == 'refs/heads/main'

# Logical operators
if: github.event_name == 'push' && github.ref == 'refs/heads/main'
if: github.event_name == 'push' || github.event_name == 'workflow_dispatch'

# Contains
if: contains(github.event.head_commit.message, '[skip ci]')

# startsWith / endsWith
if: startsWith(github.ref, 'refs/tags/')

# Status functions
if: success()    # Previous steps succeeded
if: failure()    # Any previous step failed
if: always()     # Always run
if: cancelled()  # Workflow was cancelled
```

### GitHub context
```yaml
${{ github.actor }}              # User who triggered workflow
${{ github.event_name }}         # Event type (push, pull_request, etc.)
${{ github.ref }}                # Branch/tag ref (refs/heads/main)
${{ github.ref_name }}           # Branch/tag name (main)
${{ github.sha }}                # Commit SHA
${{ github.repository }}         # owner/repo
${{ github.repository_owner }}   # owner
${{ github.run_id }}             # Unique workflow run ID
${{ github.run_number }}         # Auto-incrementing run number
${{ github.workspace }}          # Working directory path
```

### Secrets context
```yaml
${{ secrets.GITHUB_TOKEN }}      # Automatic token
${{ secrets.API_KEY }}           # Custom secret
```

### Env context
```yaml
${{ env.NODE_VERSION }}          # Environment variable
```

### Job/step context
```yaml
${{ job.status }}                # Job status
${{ steps.step-id.outputs.value }}  # Step output
${{ needs.job-id.outputs.value }}   # Job output
```

### Matrix context
```yaml
${{ matrix.os }}                 # Matrix value
${{ matrix.node-version }}
```

## Concurrency

### Cancel in-progress runs
```yaml
concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true
```

### Named concurrency groups
```yaml
concurrency:
  group: deployment-${{ github.ref }}
  cancel-in-progress: false  # Wait for previous to complete
```

## Reusable Workflows

### Reusable workflow definition
```yaml
# .github/workflows/reusable.yml
name: Reusable Workflow

on:
  workflow_call:
    inputs:
      environment:
        required: true
        type: string
      deploy-url:
        required: false
        type: string
        default: 'https://example.com'
    secrets:
      api-key:
        required: true
    outputs:
      deployment-id:
        description: "Deployment ID"
        value: ${{ jobs.deploy.outputs.deployment-id }}

jobs:
  deploy:
    runs-on: ubuntu-latest
    outputs:
      deployment-id: ${{ steps.deploy.outputs.id }}
    steps:
      - run: echo "Deploying to ${{ inputs.environment }}"
      - id: deploy
        run: echo "id=12345" >> $GITHUB_OUTPUT
```

### Calling reusable workflow
```yaml
jobs:
  call-workflow:
    uses: ./.github/workflows/reusable.yml
    with:
      environment: production
      deploy-url: https://prod.example.com
    secrets:
      api-key: ${{ secrets.PROD_API_KEY }}

  use-output:
    needs: call-workflow
    runs-on: ubuntu-latest
    steps:
      - run: echo "Deployed with ID ${{ needs.call-workflow.outputs.deployment-id }}"
```

### Nested reusable workflows (Nov 2025)
- Up to 10 levels of nesting (was 4)
- Total of 50 workflows per run (was 20)

## Default Settings

### Workflow-level defaults
```yaml
defaults:
  run:
    shell: bash
    working-directory: ./scripts
```

### Job-level defaults
```yaml
jobs:
  test:
    defaults:
      run:
        shell: bash
        working-directory: ./frontend
```

## Artifacts

### Upload artifacts
```yaml
- uses: actions/upload-artifact@v4
  with:
    name: build-output
    path: dist/
    retention-days: 7
```

### Download artifacts
```yaml
- uses: actions/download-artifact@v4
  with:
    name: build-output
    path: dist/
```

## Path Filtering

```yaml
on:
  push:
    paths:
      - 'src/**'           # Include
      - '**.js'            # All JS files
    paths-ignore:
      - 'docs/**'          # Exclude
      - '**.md'            # Markdown files
```

## Branch Filtering

```yaml
on:
  push:
    branches:
      - main
      - 'releases/**'     # Glob patterns
      - '!releases/alpha' # Exclude pattern
```

## Action Syntax (in actions)

For creating custom actions, see [custom-actions.md](custom-actions.md).
