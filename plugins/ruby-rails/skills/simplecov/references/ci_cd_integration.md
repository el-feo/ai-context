# CI/CD Integration Patterns

Comprehensive guide for integrating SimpleCov into various CI/CD pipelines and development workflows.

## GitHub Actions

### Basic Rails Test with Coverage

```yaml
# .github/workflows/test.yml
name: Tests

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

jobs:
  test:
    runs-on: ubuntu-latest
    
    services:
      postgres:
        image: postgres:14
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
        options: >-
          --health-cmd "redis-cli ping"
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
        ports:
          - 6379:6379

    steps:
      - uses: actions/checkout@v4
      
      - name: Setup Ruby
        uses: ruby/setup-ruby@v1
        with:
          ruby-version: 3.2
          bundler-cache: true
      
      - name: Setup Node
        uses: actions/setup-node@v4
        with:
          node-version: 18
          cache: 'yarn'
      
      - name: Install dependencies
        run: |
          yarn install --frozen-lockfile
      
      - name: Setup Database
        env:
          RAILS_ENV: test
          DATABASE_URL: postgres://postgres:postgres@localhost:5432/test
        run: |
          bundle exec rails db:create
          bundle exec rails db:schema:load
      
      - name: Precompile assets
        run: bundle exec rails assets:precompile
      
      - name: Run tests with coverage
        env:
          RAILS_ENV: test
          DATABASE_URL: postgres://postgres:postgres@localhost:5432/test
          REDIS_URL: redis://localhost:6379/0
        run: |
          bundle exec rake test
          bundle exec rspec
      
      - name: Check coverage thresholds
        run: |
          if grep -q "FAILED" coverage/coverage.txt 2>/dev/null; then
            echo "❌ Coverage check failed"
            exit 1
          fi
      
      - name: Upload coverage report
        uses: actions/upload-artifact@v4
        if: always()
        with:
          name: coverage-report-${{ github.sha }}
          path: coverage/
          retention-days: 30
      
      - name: Comment coverage on PR
        if: github.event_name == 'pull_request'
        uses: actions/github-script@v7
        with:
          script: |
            const fs = require('fs');
            const coverage = fs.readFileSync('coverage/coverage.txt', 'utf8');
            
            github.rest.issues.createComment({
              issue_number: context.issue.number,
              owner: context.repo.owner,
              repo: context.repo.repo,
              body: `## Coverage Report\n\n\`\`\`\n${coverage}\n\`\`\``
            });
```

### Matrix Testing with Coverage

```yaml
# .github/workflows/matrix.yml
name: Matrix Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    
    strategy:
      fail-fast: false
      matrix:
        ruby: ['3.0', '3.1', '3.2', '3.3']
        rails: ['7.0', '7.1']
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup Ruby ${{ matrix.ruby }}
        uses: ruby/setup-ruby@v1
        with:
          ruby-version: ${{ matrix.ruby }}
          bundler-cache: true
      
      - name: Run tests
        env:
          RAILS_VERSION: ${{ matrix.rails }}
        run: bundle exec rake test
      
      - name: Upload coverage
        uses: actions/upload-artifact@v4
        with:
          name: coverage-ruby-${{ matrix.ruby }}-rails-${{ matrix.rails }}
          path: coverage/
```

### Parallel Test Execution

```yaml
# .github/workflows/parallel.yml
name: Parallel Tests

on: [push]

jobs:
  test:
    runs-on: ubuntu-latest
    
    strategy:
      fail-fast: false
      matrix:
        ci_node_index: [0, 1, 2, 3]
        ci_node_total: [4]
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup Ruby
        uses: ruby/setup-ruby@v1
        with:
          ruby-version: 3.2
          bundler-cache: true
      
      - name: Setup Database
        run: |
          bundle exec rails db:create
          bundle exec rails db:schema:load
      
      - name: Run tests (Node ${{ matrix.ci_node_index }})
        env:
          CI_NODE_INDEX: ${{ matrix.ci_node_index }}
          CI_NODE_TOTAL: ${{ matrix.ci_node_total }}
          TEST_ENV_NUMBER: ${{ matrix.ci_node_index }}
        run: |
          bundle exec parallel_test test/ -n $CI_NODE_TOTAL --only-group $CI_NODE_INDEX
      
      - name: Upload coverage results
        uses: actions/upload-artifact@v4
        with:
          name: coverage-${{ matrix.ci_node_index }}
          path: coverage/.resultset.json
  
  collate:
    needs: test
    runs-on: ubuntu-latest
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup Ruby
        uses: ruby/setup-ruby@v1
        with:
          ruby-version: 3.2
          bundler-cache: true
      
      - name: Download all coverage results
        uses: actions/download-artifact@v4
        with:
          path: coverage-results
      
      - name: Collate coverage
        run: |
          cat > collate.rb << 'RUBY'
          require 'simplecov'
          
          SimpleCov.collate Dir['coverage-results/**/.resultset.json'], 'rails' do
            formatter SimpleCov::Formatter::Console
            minimum_coverage line: 90, branch: 80
          end
          RUBY
          
          bundle exec ruby collate.rb
      
      - name: Upload final coverage
        uses: actions/upload-artifact@v4
        with:
          name: coverage-final
          path: coverage/
```

## GitLab CI

### Basic Configuration

```yaml
# .gitlab-ci.yml
image: ruby:3.2

variables:
  POSTGRES_DB: test_db
  POSTGRES_USER: postgres
  POSTGRES_PASSWORD: postgres
  DATABASE_URL: "postgresql://postgres:postgres@postgres:5432/test_db"

services:
  - postgres:14
  - redis:7

stages:
  - test
  - coverage

cache:
  paths:
    - vendor/bundle

before_script:
  - bundle install --path vendor/bundle --jobs $(nproc) --retry 3
  - bundle exec rails db:create db:schema:load

test:
  stage: test
  script:
    - bundle exec rake test
    - bundle exec rspec
  coverage: '/COVERAGE:\s+(\d+\.\d+)%/'
  artifacts:
    paths:
      - coverage/
    reports:
      coverage_report:
        coverage_format: cobertura
        path: coverage/coverage.xml
    expire_in: 1 week

coverage_check:
  stage: coverage
  script:
    - bundle exec ruby scripts/coverage_analyzer.rb --threshold 90
  dependencies:
    - test
  only:
    - merge_requests
    - main
```

### With Artifacts and Pages

```yaml
# .gitlab-ci.yml
test:
  stage: test
  script:
    - bundle exec rake test
  artifacts:
    paths:
      - coverage/
    reports:
      coverage_report:
        coverage_format: cobertura
        path: coverage/coverage.xml

pages:
  stage: deploy
  dependencies:
    - test
  script:
    - mv coverage public
  artifacts:
    paths:
      - public
  only:
    - main
```

## CircleCI

```yaml
# .circleci/config.yml
version: 2.1

orbs:
  ruby: circleci/ruby@2.0

jobs:
  test:
    docker:
      - image: cimg/ruby:3.2-node
      - image: cimg/postgres:14.0
        environment:
          POSTGRES_USER: postgres
          POSTGRES_PASSWORD: postgres
          POSTGRES_DB: test_db
      - image: cimg/redis:7.0
    
    environment:
      BUNDLE_PATH: vendor/bundle
      RAILS_ENV: test
      DATABASE_URL: postgresql://postgres:postgres@localhost:5432/test_db
    
    steps:
      - checkout
      
      - ruby/install-deps
      
      - run:
          name: Setup Database
          command: bundle exec rails db:create db:schema:load
      
      - run:
          name: Run Tests with Coverage
          command: |
            bundle exec rake test
            bundle exec rspec
      
      - run:
          name: Check Coverage
          command: |
            bundle exec ruby scripts/coverage_analyzer.rb --threshold 90
      
      - store_artifacts:
          path: coverage
          destination: coverage-report
      
      - store_test_results:
          path: test/reports

workflows:
  test:
    jobs:
      - test
```

## Jenkins

```groovy
// Jenkinsfile
pipeline {
  agent {
    docker {
      image 'ruby:3.2'
      args '-v $HOME/.bundle:/usr/local/bundle'
    }
  }
  
  environment {
    RAILS_ENV = 'test'
    DATABASE_URL = 'postgresql://postgres:postgres@db:5432/test'
  }
  
  stages {
    stage('Setup') {
      steps {
        sh 'bundle install --jobs $(nproc)'
        sh 'bundle exec rails db:create db:schema:load'
      }
    }
    
    stage('Test') {
      steps {
        sh 'bundle exec rake test'
        sh 'bundle exec rspec'
      }
    }
    
    stage('Coverage Analysis') {
      steps {
        sh 'bundle exec ruby scripts/coverage_analyzer.rb --format json --output coverage/analysis.json'
        
        publishHTML([
          allowMissing: false,
          alwaysLinkToLastBuild: true,
          keepAll: true,
          reportDir: 'coverage',
          reportFiles: 'index.html',
          reportName: 'Coverage Report'
        ])
      }
    }
    
    stage('Coverage Gate') {
      steps {
        script {
          def analysis = readJSON file: 'coverage/analysis.json'
          if (analysis.analysis.overall_coverage < 90) {
            error "Coverage ${analysis.analysis.overall_coverage}% below 90% threshold"
          }
        }
      }
    }
  }
  
  post {
    always {
      archiveArtifacts artifacts: 'coverage/**/*', fingerprint: true
    }
  }
}
```

## Bitbucket Pipelines

```yaml
# bitbucket-pipelines.yml
image: ruby:3.2

definitions:
  services:
    postgres:
      image: postgres:14
      variables:
        POSTGRES_DB: test_db
        POSTGRES_USER: postgres
        POSTGRES_PASSWORD: postgres
    redis:
      image: redis:7

pipelines:
  default:
    - step:
        name: Test with Coverage
        services:
          - postgres
          - redis
        caches:
          - bundler
        script:
          - bundle install
          - bundle exec rails db:create db:schema:load
          - bundle exec rake test
          - bundle exec rspec
          - bundle exec ruby scripts/coverage_analyzer.rb --threshold 90
        artifacts:
          - coverage/**

  pull-requests:
    '**':
      - step:
          name: PR Coverage Check
          services:
            - postgres
            - redis
          caches:
            - bundler
          script:
            - bundle install
            - bundle exec rails db:create db:schema:load
            - bundle exec rake test
            - bundle exec ruby scripts/coverage_analyzer.rb --threshold 90 --format markdown --output coverage_report.md
          artifacts:
            - coverage_report.md

definitions:
  caches:
    bundler: vendor/bundle
```

## Azure Pipelines

```yaml
# azure-pipelines.yml
trigger:
  - main
  - develop

pool:
  vmImage: 'ubuntu-latest'

variables:
  RAILS_ENV: test

services:
  postgres: postgres:14
  redis: redis:7

steps:
- task: UseRubyVersion@0
  inputs:
    versionSpec: '3.2'
    addToPath: true

- script: |
    gem install bundler
    bundle install --jobs $(nproc) --retry 3
  displayName: 'Install dependencies'

- script: |
    bundle exec rails db:create db:schema:load
  displayName: 'Setup database'

- script: |
    bundle exec rake test
    bundle exec rspec
  displayName: 'Run tests with coverage'

- script: |
    bundle exec ruby scripts/coverage_analyzer.rb --threshold 90
  displayName: 'Check coverage thresholds'

- task: PublishCodeCoverageResults@1
  inputs:
    codeCoverageTool: 'Cobertura'
    summaryFileLocation: 'coverage/coverage.xml'
    reportDirectory: 'coverage'

- task: PublishBuildArtifacts@1
  inputs:
    pathToPublish: 'coverage'
    artifactName: 'coverage-report'
```

## Heroku CI

```json
{
  "environments": {
    "test": {
      "addons": [
        "heroku-postgresql:mini",
        "heroku-redis:mini"
      ],
      "scripts": {
        "test-setup": "bundle exec rails db:create db:schema:load",
        "test": "bundle exec rake test && bundle exec rspec"
      }
    }
  }
}
```

```yaml
# app.json for Heroku CI
{
  "name": "myapp",
  "environments": {
    "test": {
      "addons": ["heroku-postgresql", "heroku-redis"],
      "scripts": {
        "test-setup": "bundle exec rails db:create db:schema:load",
        "test": "bundle exec rake test"
      },
      "env": {
        "RAILS_ENV": "test",
        "COVERAGE": "true"
      }
    }
  }
}
```

## Coverage Badges

### GitHub Actions with Shields.io

```yaml
# .github/workflows/coverage-badge.yml
name: Coverage Badge

on:
  push:
    branches: [ main ]

jobs:
  badge:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup Ruby
        uses: ruby/setup-ruby@v1
        with:
          ruby-version: 3.2
          bundler-cache: true
      
      - name: Run tests
        run: bundle exec rake test
      
      - name: Extract coverage
        id: coverage
        run: |
          COVERAGE=$(ruby -r json -e "data = JSON.parse(File.read('coverage/.resultset.json')); cov = data.values.first['coverage']['lines']; puts ((cov.compact.count { |x| x > 0 }.to_f / cov.size) * 100).round(2)")
          echo "coverage=$COVERAGE" >> $GITHUB_OUTPUT
      
      - name: Create badge
        uses: schneegans/dynamic-badges-action@v1.6.0
        with:
          auth: ${{ secrets.GIST_SECRET }}
          gistID: your-gist-id
          filename: coverage-badge.json
          label: Coverage
          message: ${{ steps.coverage.outputs.coverage }}%
          color: ${{ steps.coverage.outputs.coverage >= 90 && 'green' || steps.coverage.outputs.coverage >= 80 && 'yellow' || 'red' }}
```

Then add to README:
```markdown
![Coverage](https://img.shields.io/endpoint?url=https://gist.githubusercontent.com/username/gist-id/raw/coverage-badge.json)
```

## Pre-commit/Pre-push Hooks

### Pre-commit Hook
```bash
#!/bin/bash
# .git/hooks/pre-commit

echo "Running tests with coverage..."

# Stash unstaged changes
git stash -q --keep-index

# Run tests
COVERAGE=true bundle exec rake test

RESULT=$?

# Restore stashed changes
git stash pop -q

if [ $RESULT -ne 0 ]; then
  echo "❌ Tests or coverage check failed"
  exit 1
fi

echo "✅ Tests passed with acceptable coverage"
exit 0
```

### Pre-push Hook
```bash
#!/bin/bash
# .git/hooks/pre-push

echo "Running full test suite with coverage..."

# Get current branch
branch=$(git rev-parse --abbrev-ref HEAD)

# Skip for feature branches if desired
if [[ $branch =~ ^feature/ ]]; then
  echo "Skipping coverage check for feature branch"
  exit 0
fi

# Run tests
COVERAGE=true bundle exec rake test
bundle exec ruby scripts/coverage_analyzer.rb --threshold 90

if [ $? -ne 0 ]; then
  echo "❌ Coverage below threshold - push blocked"
  echo "Override with: git push --no-verify"
  exit 1
fi

echo "✅ Coverage acceptable - proceeding with push"
exit 0
```

### Husky Configuration (for Node/Rails apps)

```json
{
  "husky": {
    "hooks": {
      "pre-push": "bundle exec rake test && bundle exec ruby scripts/coverage_analyzer.rb --threshold 90"
    }
  }
}
```

## Docker Integration

```dockerfile
# Dockerfile.test
FROM ruby:3.2

WORKDIR /app

# Install dependencies
COPY Gemfile Gemfile.lock ./
RUN bundle install

# Copy application
COPY . .

# Run tests with coverage
CMD ["bundle", "exec", "rake", "test"]
```

```yaml
# docker-compose.test.yml
version: '3.8'

services:
  test:
    build:
      context: .
      dockerfile: Dockerfile.test
    environment:
      RAILS_ENV: test
      DATABASE_URL: postgresql://postgres:postgres@db:5432/test
      REDIS_URL: redis://redis:6379/0
    depends_on:
      - db
      - redis
    volumes:
      - ./coverage:/app/coverage
  
  db:
    image: postgres:14
    environment:
      POSTGRES_PASSWORD: postgres
  
  redis:
    image: redis:7
```

Run with:
```bash
docker-compose -f docker-compose.test.yml run --rm test
docker-compose -f docker-compose.test.yml down
```

## Best Practices for CI/CD

1. **Cache Dependencies**: Bundle caching saves significant time
2. **Parallel Execution**: Split tests across multiple runners
3. **Fail Fast**: Set coverage thresholds early in pipeline
4. **Artifacts**: Always upload coverage reports
5. **Branch Protection**: Require passing coverage in PRs
6. **Notifications**: Alert team on coverage drops
7. **Historical Tracking**: Store coverage metrics over time
8. **Coverage Badges**: Display current coverage in README
9. **Incremental Checks**: Compare coverage against base branch
10. **Documentation**: Keep CI configuration well-documented
