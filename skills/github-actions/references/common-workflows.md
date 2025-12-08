# Common Workflows

Production-ready workflow templates for Ruby/Rails, TypeScript, and deployment to Heroku/Fly.io.

## Ruby on Rails CI/CD

### Complete Rails CI with PostgreSQL

```yaml
name: Rails CI

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

permissions:
  contents: read

env:
  RUBY_VERSION: .ruby-version

jobs:
  test:
    runs-on: ubuntu-latest

    services:
      postgres:
        image: postgres:16
        env:
          POSTGRES_USER: postgres
          POSTGRES_PASSWORD: postgres
          POSTGRES_DB: test
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
        ports:
          - 5432:5432

      redis:
        image: redis:7-alpine
        options: >-
          --health-cmd "redis-cli ping"
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
        ports:
          - 6379:6379

    env:
      RAILS_ENV: test
      DATABASE_URL: postgres://postgres:postgres@localhost:5432/test
      REDIS_URL: redis://localhost:6379/0

    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Setup Ruby
        uses: ruby/setup-ruby@v1
        with:
          ruby-version: ${{ env.RUBY_VERSION }}
          bundler-cache: true

      - name: Setup Node (for assets)
        uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'yarn'

      - name: Install Node dependencies
        run: yarn install --frozen-lockfile

      - name: Setup database
        run: |
          bin/rails db:create
          bin/rails db:schema:load

      - name: Precompile assets
        run: bin/rails assets:precompile

      - name: Run tests
        run: bundle exec rspec

      - name: Upload coverage
        if: always()
        uses: actions/upload-artifact@v4
        with:
          name: coverage
          path: coverage/
          retention-days: 7

  lint:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v4

      - uses: ruby/setup-ruby@v1
        with:
          ruby-version: ${{ env.RUBY_VERSION }}
          bundler-cache: true

      - name: Run RuboCop
        run: bundle exec rubocop --parallel

      - name: Run Brakeman
        run: bundle exec brakeman --no-pager

  deploy:
    needs: [test, lint]
    if: github.ref == 'refs/heads/main' && github.event_name == 'push'
    runs-on: ubuntu-latest
    environment: production

    steps:
      - uses: actions/checkout@v4

      - uses: superfly/flyctl-actions/setup-flyctl@master

      - name: Deploy to Fly.io
        run: flyctl deploy --remote-only
        env:
          FLY_API_TOKEN: ${{ secrets.FLY_API_TOKEN }}
```

### Rails with MySQL

```yaml
services:
  mysql:
    image: mysql:8.0
    env:
      MYSQL_ROOT_PASSWORD: password
      MYSQL_DATABASE: test
    options: >-
      --health-cmd "mysqladmin ping -h localhost"
      --health-interval 10s
      --health-timeout 5s
      --health-retries 5
    ports:
      - 3306:3306

env:
  DATABASE_URL: mysql2://root:password@127.0.0.1:3306/test
```

### Rails with SQLite (simple projects)

```yaml
steps:
  - uses: actions/checkout@v4

  - uses: ruby/setup-ruby@v1
    with:
      ruby-version: .ruby-version
      bundler-cache: true

  - name: Run tests
    env:
      RAILS_ENV: test
    run: |
      bin/rails db:setup
      bundle exec rspec
```

### Rails Matrix Testing (multiple Ruby versions)

```yaml
jobs:
  test:
    strategy:
      fail-fast: false
      matrix:
        ruby-version: ['3.1', '3.2', '3.3']
        rails-version: ['7.0', '7.1', '7.2']
        exclude:
          - ruby-version: '3.1'
            rails-version: '7.2'

    runs-on: ubuntu-latest

    env:
      RAILS_VERSION: ${{ matrix.rails-version }}

    steps:
      - uses: actions/checkout@v4

      - uses: ruby/setup-ruby@v1
        with:
          ruby-version: ${{ matrix.ruby-version }}
          bundler-cache: true

      - name: Run tests
        run: bundle exec rspec
```

## TypeScript/Node.js CI/CD

### Complete TypeScript CI

```yaml
name: TypeScript CI

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

permissions:
  contents: read

jobs:
  lint-and-type-check:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v4

      - uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'

      - name: Install dependencies
        run: npm ci

      - name: Lint
        run: npm run lint

      - name: Type check
        run: npm run typecheck

  test:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v4

      - uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'

      - run: npm ci

      - name: Run tests
        run: npm test -- --coverage

      - name: Upload coverage
        uses: actions/upload-artifact@v4
        with:
          name: coverage
          path: coverage/

  build:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v4

      - uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'

      - run: npm ci

      - name: Build
        run: npm run build

      - name: Upload build
        uses: actions/upload-artifact@v4
        with:
          name: dist
          path: dist/

  deploy:
    needs: [lint-and-type-check, test, build]
    if: github.ref == 'refs/heads/main' && github.event_name == 'push'
    runs-on: ubuntu-latest
    environment: production

    steps:
      - uses: actions/checkout@v4

      - uses: superfly/flyctl-actions/setup-flyctl@master

      - run: flyctl deploy --remote-only
        env:
          FLY_API_TOKEN: ${{ secrets.FLY_API_TOKEN }}
```

### TypeScript with Yarn

```yaml
- uses: actions/setup-node@v4
  with:
    node-version: '20'
    cache: 'yarn'

- run: yarn install --frozen-lockfile
- run: yarn lint
- run: yarn typecheck
- run: yarn test
- run: yarn build
```

### TypeScript with pnpm

```yaml
- uses: pnpm/action-setup@v2
  with:
    version: 8

- uses: actions/setup-node@v4
  with:
    node-version: '20'
    cache: 'pnpm'

- run: pnpm install --frozen-lockfile
- run: pnpm lint
- run: pnpm typecheck
- run: pnpm test
- run: pnpm build
```

### TypeScript Matrix Testing

```yaml
jobs:
  test:
    strategy:
      matrix:
        node-version: [18, 20, 22]
        os: [ubuntu-latest, macos-latest, windows-latest]

    runs-on: ${{ matrix.os }}

    steps:
      - uses: actions/checkout@v4

      - uses: actions/setup-node@v4
        with:
          node-version: ${{ matrix.node-version }}
          cache: 'npm'

      - run: npm ci
      - run: npm test
```

### Next.js Deployment

```yaml
name: Next.js CI/CD

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  build:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v4

      - uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'

      - run: npm ci

      - name: Build Next.js app
        run: npm run build
        env:
          NEXT_PUBLIC_API_URL: ${{ secrets.NEXT_PUBLIC_API_URL }}

      - name: Run tests
        run: npm test

      - uses: actions/upload-artifact@v4
        with:
          name: nextjs-build
          path: .next/
```

## Heroku Deployment

### Deploy to Heroku (using Action)

```yaml
name: Deploy to Heroku

on:
  push:
    branches: [main]

permissions:
  contents: read

jobs:
  deploy:
    runs-on: ubuntu-latest
    environment: production

    steps:
      - uses: actions/checkout@v4

      - uses: akhileshns/heroku-deploy@v3.14.15
        with:
          heroku_api_key: ${{ secrets.HEROKU_API_KEY }}
          heroku_app_name: ${{ secrets.HEROKU_APP_NAME }}
          heroku_email: ${{ secrets.HEROKU_EMAIL }}

      - name: Run database migrations
        env:
          HEROKU_API_KEY: ${{ secrets.HEROKU_API_KEY }}
        run: |
          heroku run rails db:migrate --app ${{ secrets.HEROKU_APP_NAME }}
```

### Deploy with Heroku CLI

```yaml
- name: Deploy to Heroku
  env:
    HEROKU_API_KEY: ${{ secrets.HEROKU_API_KEY }}
  run: |
    git remote add heroku https://git.heroku.com/${{ secrets.HEROKU_APP_NAME }}.git
    git push heroku main

- name: Run migrations
  env:
    HEROKU_API_KEY: ${{ secrets.HEROKU_API_KEY }}
  run: |
    heroku run rails db:migrate --app ${{ secrets.HEROKU_APP_NAME }}
```

### Heroku with Docker

```yaml
- name: Build and push to Heroku Container Registry
  env:
    HEROKU_API_KEY: ${{ secrets.HEROKU_API_KEY }}
  run: |
    heroku container:login
    heroku container:push web --app ${{ secrets.HEROKU_APP_NAME }}
    heroku container:release web --app ${{ secrets.HEROKU_APP_NAME }}
```

### Heroku with Review Apps

```yaml
name: Deploy Review App

on:
  pull_request:
    types: [opened, synchronize]

jobs:
  deploy-review:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v4

      - name: Create Review App
        env:
          HEROKU_API_KEY: ${{ secrets.HEROKU_API_KEY }}
        run: |
          APP_NAME="${{ secrets.HEROKU_APP_NAME }}-pr-${{ github.event.pull_request.number }}"
          heroku apps:create $APP_NAME --team ${{ secrets.HEROKU_TEAM }} || true
          git remote add heroku https://git.heroku.com/$APP_NAME.git
          git push heroku HEAD:main --force

      - name: Comment PR
        uses: actions/github-script@v7
        with:
          script: |
            const appName = '${{ secrets.HEROKU_APP_NAME }}-pr-${{ github.event.pull_request.number }}';
            github.rest.issues.createComment({
              owner: context.repo.owner,
              repo: context.repo.repo,
              issue_number: context.issue.number,
              body: `🚀 Review app deployed: https://${appName}.herokuapp.com`
            });
```

## Fly.io Deployment

### Basic Fly.io Deployment

```yaml
name: Deploy to Fly.io

on:
  push:
    branches: [main]

permissions:
  contents: read

jobs:
  deploy:
    runs-on: ubuntu-latest
    environment: production

    steps:
      - uses: actions/checkout@v4

      - uses: superfly/flyctl-actions/setup-flyctl@master

      - name: Deploy to Fly.io
        run: flyctl deploy --remote-only
        env:
          FLY_API_TOKEN: ${{ secrets.FLY_API_TOKEN }}
```

### Fly.io with Database Migrations (Rails)

```yaml
- uses: superfly/flyctl-actions/setup-flyctl@master

- name: Deploy to Fly.io
  run: flyctl deploy --remote-only
  env:
    FLY_API_TOKEN: ${{ secrets.FLY_API_TOKEN }}

- name: Run database migrations
  run: flyctl ssh console --command "bin/rails db:migrate"
  env:
    FLY_API_TOKEN: ${{ secrets.FLY_API_TOKEN }}
```

### Fly.io Review Apps

```yaml
name: Fly.io Preview

on:
  pull_request:
    types: [opened, synchronize, reopened, closed]

jobs:
  deploy-preview:
    runs-on: ubuntu-latest

    # Only run on opened/sync, not on close
    if: github.event.action != 'closed'

    steps:
      - uses: actions/checkout@v4

      - uses: superfly/flyctl-actions/setup-flyctl@master

      - name: Create preview app
        run: |
          APP_NAME="myapp-pr-${{ github.event.pull_request.number }}"
          flyctl apps create $APP_NAME --org personal || true
          flyctl deploy --app $APP_NAME --remote-only
        env:
          FLY_API_TOKEN: ${{ secrets.FLY_API_TOKEN }}

      - name: Comment PR
        uses: actions/github-script@v7
        with:
          script: |
            const appName = `myapp-pr-${{ github.event.pull_request.number }}`;
            github.rest.issues.createComment({
              owner: context.repo.owner,
              repo: context.repo.repo,
              issue_number: context.issue.number,
              body: `🚀 Preview deployed: https://${appName}.fly.dev`
            });

  cleanup-preview:
    runs-on: ubuntu-latest

    if: github.event.action == 'closed'

    steps:
      - uses: superfly/flyctl-actions/setup-flyctl@master

      - name: Destroy preview app
        run: |
          APP_NAME="myapp-pr-${{ github.event.pull_request.number }}"
          flyctl apps destroy $APP_NAME --yes || true
        env:
          FLY_API_TOKEN: ${{ secrets.FLY_API_TOKEN }}
```

### Fly.io Multi-Region Deployment

```yaml
- name: Deploy to multiple regions
  run: |
    flyctl deploy --remote-only --region iad  # US East
    flyctl deploy --remote-only --region lhr  # London
    flyctl deploy --remote-only --region nrt  # Tokyo
  env:
    FLY_API_TOKEN: ${{ secrets.FLY_API_TOKEN }}
```

### Fly.io with Docker Build

```yaml
- uses: docker/setup-buildx-action@v3

- uses: docker/login-action@v3
  with:
    registry: registry.fly.io
    username: x
    password: ${{ secrets.FLY_API_TOKEN }}

- name: Build and push
  uses: docker/build-push-action@v5
  with:
    context: .
    push: true
    tags: registry.fly.io/myapp:${{ github.sha }}
    cache-from: type=gha
    cache-to: type=gha,mode=max

- uses: superfly/flyctl-actions/setup-flyctl@master

- name: Deploy
  run: flyctl deploy --image registry.fly.io/myapp:${{ github.sha }}
  env:
    FLY_API_TOKEN: ${{ secrets.FLY_API_TOKEN }}
```

## Monorepo Workflows

### Nx Monorepo

```yaml
name: Nx Monorepo CI

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  main:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0  # Nx needs git history

      - uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'

      - run: npm ci

      - uses: nrwl/nx-set-shas@v4

      - name: Run affected tests
        run: npx nx affected -t test --parallel=3

      - name: Run affected builds
        run: npx nx affected -t build --parallel=3

      - name: Run affected lint
        run: npx nx affected -t lint --parallel=3
```

### Turborepo Monorepo

```yaml
name: Turborepo CI

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  build:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v4

      - uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'

      - run: npm ci

      - name: Build
        run: npx turbo run build

      - name: Test
        run: npx turbo run test

      - name: Lint
        run: npx turbo run lint
```

## Code Quality & Security

### RuboCop + Brakeman + Bundler Audit

```yaml
name: Security & Quality

on: [push, pull_request]

jobs:
  security:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v4

      - uses: ruby/setup-ruby@v1
        with:
          ruby-version: .ruby-version
          bundler-cache: true

      - name: Run RuboCop
        run: bundle exec rubocop --parallel

      - name: Run Brakeman (security scanner)
        run: bundle exec brakeman --no-pager --format json --output brakeman.json

      - name: Check for vulnerable gems
        run: bundle exec bundle-audit check --update

      - name: Upload Brakeman report
        if: always()
        uses: actions/upload-artifact@v4
        with:
          name: brakeman-report
          path: brakeman.json
```

### ESLint + TypeScript + Prettier

```yaml
name: Code Quality

on: [push, pull_request]

jobs:
  quality:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v4

      - uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'

      - run: npm ci

      - name: Run ESLint
        run: npm run lint

      - name: Run Prettier
        run: npm run format:check

      - name: Run TypeScript compiler
        run: npm run typecheck
```

### CodeQL Security Scanning

```yaml
name: CodeQL

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]
  schedule:
    - cron: '0 12 * * 1'  # Weekly on Monday

permissions:
  security-events: write
  contents: read

jobs:
  analyze:
    runs-on: ubuntu-latest

    strategy:
      matrix:
        language: [javascript, typescript, ruby]

    steps:
      - uses: actions/checkout@v4

      - uses: github/codeql-action/init@v3
        with:
          languages: ${{ matrix.language }}

      - uses: github/codeql-action/autobuild@v3

      - uses: github/codeql-action/analyze@v3
```

## Release Automation

### Semantic Release

```yaml
name: Release

on:
  push:
    branches: [main]

permissions:
  contents: write
  issues: write
  pull-requests: write

jobs:
  release:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0
          persist-credentials: false

      - uses: actions/setup-node@v4
        with:
          node-version: '20'

      - run: npm ci

      - name: Release
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
          NPM_TOKEN: ${{ secrets.NPM_TOKEN }}
        run: npx semantic-release
```

### Create GitHub Release

```yaml
name: Create Release

on:
  push:
    tags:
      - 'v*'

permissions:
  contents: write

jobs:
  release:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v4

      - name: Build artifacts
        run: npm run build

      - name: Create Release
        uses: actions/create-release@v1
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        with:
          tag_name: ${{ github.ref }}
          release_name: Release ${{ github.ref }}
          draft: false
          prerelease: false

      - name: Upload Release Asset
        uses: actions/upload-release-asset@v1
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        with:
          upload_url: ${{ steps.create_release.outputs.upload_url }}
          asset_path: ./dist/bundle.zip
          asset_name: bundle.zip
          asset_content_type: application/zip
```

## Complete Full-Stack Example

### Rails API + TypeScript Frontend

```yaml
name: Full-Stack CI/CD

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

permissions:
  contents: read

jobs:
  backend-test:
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

    steps:
      - uses: actions/checkout@v4

      - uses: ruby/setup-ruby@v1
        with:
          ruby-version: .ruby-version
          bundler-cache: true
          working-directory: backend

      - name: Run backend tests
        working-directory: backend
        env:
          RAILS_ENV: test
          DATABASE_URL: postgres://postgres:postgres@localhost:5432/test
        run: |
          bin/rails db:setup
          bundle exec rspec

  frontend-test:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v4

      - uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'
          cache-dependency-path: frontend/package-lock.json

      - name: Run frontend tests
        working-directory: frontend
        run: |
          npm ci
          npm run lint
          npm run typecheck
          npm test
          npm run build

  deploy:
    needs: [backend-test, frontend-test]
    if: github.ref == 'refs/heads/main' && github.event_name == 'push'
    runs-on: ubuntu-latest
    environment: production

    steps:
      - uses: actions/checkout@v4

      - uses: superfly/flyctl-actions/setup-flyctl@master

      - name: Deploy backend
        run: flyctl deploy --remote-only --config backend/fly.toml
        env:
          FLY_API_TOKEN: ${{ secrets.FLY_API_TOKEN }}

      - name: Deploy frontend
        run: flyctl deploy --remote-only --config frontend/fly.toml
        env:
          FLY_API_TOKEN: ${{ secrets.FLY_API_TOKEN }}
```

## Resources

- [Ruby/Rails CI Examples](https://github.com/rails/rails/tree/main/.github/workflows)
- [Node.js CI Examples](https://docs.github.com/en/actions/automating-builds-and-tests/building-and-testing-nodejs)
- [Heroku Deployment](https://devcenter.heroku.com/articles/github-integration)
- [Fly.io CI/CD](https://fly.io/docs/launch/continuous-deployment-with-github-actions/)
