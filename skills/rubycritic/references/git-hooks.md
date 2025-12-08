# Git Hooks and CI Integration

This guide covers integrating RubyCritic into git workflows and continuous integration pipelines to maintain code quality automatically.

## Pre-Commit Hook

Automatically run RubyCritic on staged files before commits.

### Basic Pre-Commit Hook

Create `.git/hooks/pre-commit`:

```bash
#!/bin/bash

# Get staged Ruby files
RUBY_FILES=$(git diff --cached --name-only --diff-filter=ACM | grep '\.rb$')

if [ -z "$RUBY_FILES" ]; then
  # No Ruby files staged, skip check
  exit 0
fi

echo "Running RubyCritic on staged files..."
echo "$RUBY_FILES"
echo ""

# Run RubyCritic on staged files
if [ -f "scripts/check_quality.sh" ]; then
  scripts/check_quality.sh $RUBY_FILES
else
  bundle exec rubycritic --format console --no-browser $RUBY_FILES
fi

RESULT=$?

if [ $RESULT -ne 0 ]; then
  echo ""
  echo "❌ Quality check failed!"
  echo "Fix the issues above or use 'git commit --no-verify' to skip this check."
  exit 1
fi

echo "✅ Quality check passed!"
exit 0
```

Make it executable:
```bash
chmod +x .git/hooks/pre-commit
```

### Pre-Commit Hook with Threshold

Only fail on severe quality issues:

```bash
#!/bin/bash

RUBY_FILES=$(git diff --cached --name-only --diff-filter=ACM | grep '\.rb$')

if [ -z "$RUBY_FILES" ]; then
  exit 0
fi

echo "Running RubyCritic on staged files..."

# Run and capture output
OUTPUT=$(bundle exec rubycritic --format console --no-browser $RUBY_FILES 2>&1)
echo "$OUTPUT"

# Extract score from output
SCORE=$(echo "$OUTPUT" | grep -oP 'Score: \K\d+' | head -1)

if [ -z "$SCORE" ]; then
  echo "⚠️  Could not determine quality score"
  exit 0  # Don't block commit if we can't get score
fi

MINIMUM_SCORE=85

if [ "$SCORE" -lt "$MINIMUM_SCORE" ]; then
  echo ""
  echo "❌ Quality score $SCORE is below minimum $MINIMUM_SCORE"
  echo "Please improve code quality or use --no-verify to skip."
  exit 1
fi

echo "✅ Quality score: $SCORE (minimum: $MINIMUM_SCORE)"
exit 0
```

### Pre-Commit Hook with Selective Analysis

Only analyze files in critical directories:

```bash
#!/bin/bash

RUBY_FILES=$(git diff --cached --name-only --diff-filter=ACM | grep '\.rb$')

if [ -z "$RUBY_FILES" ]; then
  exit 0
fi

# Filter for critical paths only
CRITICAL_FILES=$(echo "$RUBY_FILES" | grep -E '^(app/models|app/services|lib)/')

if [ -z "$CRITICAL_FILES" ]; then
  echo "No critical files changed, skipping quality check"
  exit 0
fi

echo "Running RubyCritic on critical files:"
echo "$CRITICAL_FILES"
echo ""

bundle exec rubycritic --format console --no-browser $CRITICAL_FILES

if [ $? -ne 0 ]; then
  echo "❌ Quality check failed!"
  exit 1
fi

echo "✅ Quality check passed!"
exit 0
```

## Pre-Push Hook

Run comprehensive analysis before pushing to remote:

Create `.git/hooks/pre-push`:

```bash
#!/bin/bash

echo "Running comprehensive quality check before push..."
echo ""

# Get all commits being pushed
while read local_ref local_sha remote_ref remote_sha
do
  if [ "$local_sha" = "0000000000000000000000000000000000000000" ]; then
    # Branch is being deleted, skip
    continue
  fi

  if [ "$remote_sha" = "0000000000000000000000000000000000000000" ]; then
    # New branch, compare with main
    RANGE="main..$local_sha"
  else
    # Existing branch, compare with remote
    RANGE="$remote_sha..$local_sha"
  fi

  # Get changed Ruby files
  RUBY_FILES=$(git diff --name-only $RANGE | grep '\.rb$')

  if [ -n "$RUBY_FILES" ]; then
    echo "Analyzing changed files:"
    echo "$RUBY_FILES"
    echo ""

    bundle exec rubycritic --format console --no-browser $RUBY_FILES

    if [ $? -ne 0 ]; then
      echo ""
      echo "❌ Quality check failed!"
      echo "Fix issues or use 'git push --no-verify' to skip."
      exit 1
    fi
  fi
done

echo "✅ All quality checks passed!"
exit 0
```

Make it executable:
```bash
chmod +x .git/hooks/pre-push
```

## Commit Message Hook

Add quality score to commit message automatically:

Create `.git/hooks/prepare-commit-msg`:

```bash
#!/bin/bash

COMMIT_MSG_FILE=$1
COMMIT_SOURCE=$2

# Skip if amending or using a message from another source
if [ "$COMMIT_SOURCE" = "message" ] || [ "$COMMIT_SOURCE" = "merge" ]; then
  exit 0
fi

# Get staged Ruby files
RUBY_FILES=$(git diff --cached --name-only --diff-filter=ACM | grep '\.rb$')

if [ -z "$RUBY_FILES" ]; then
  exit 0
fi

# Run RubyCritic and capture score
OUTPUT=$(bundle exec rubycritic --format console --no-browser $RUBY_FILES 2>&1)
SCORE=$(echo "$OUTPUT" | grep -oP 'Score: \K\d+' | head -1)

if [ -n "$SCORE" ]; then
  # Append quality score to commit message
  echo "" >> "$COMMIT_MSG_FILE"
  echo "Code Quality Score: $SCORE" >> "$COMMIT_MSG_FILE"
fi

exit 0
```

Make it executable:
```bash
chmod +x .git/hooks/prepare-commit-msg
```

## GitHub Actions Integration

### Basic Workflow

Create `.github/workflows/code-quality.yml`:

```yaml
name: Code Quality

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main, develop ]

jobs:
  rubycritic:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout code
        uses: actions/checkout@v3
        with:
          fetch-depth: 0  # Full history for CI mode

      - name: Set up Ruby
        uses: ruby/setup-ruby@v1
        with:
          ruby-version: 3.2
          bundler-cache: true

      - name: Install RubyCritic
        run: gem install rubycritic

      - name: Run RubyCritic
        run: |
          rubycritic --format console --format json \
            --minimum-score 90 \
            --no-browser \
            app/ lib/

      - name: Upload Report
        if: always()
        uses: actions/upload-artifact@v3
        with:
          name: rubycritic-report
          path: tmp/rubycritic/
          retention-days: 30
```

### PR-Focused Workflow

Only analyze changed files in pull requests:

```yaml
name: PR Quality Check

on:
  pull_request:
    branches: [ main ]

jobs:
  quality-check:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout code
        uses: actions/checkout@v3
        with:
          fetch-depth: 0

      - name: Set up Ruby
        uses: ruby/setup-ruby@v1
        with:
          ruby-version: 3.2
          bundler-cache: true

      - name: Install RubyCritic
        run: gem install rubycritic

      - name: Get changed files
        id: changed-files
        uses: tj-actions/changed-files@v35
        with:
          files: |
            **/*.rb

      - name: Run RubyCritic on changed files
        if: steps.changed-files.outputs.any_changed == 'true'
        run: |
          echo "Changed Ruby files:"
          echo "${{ steps.changed-files.outputs.all_changed_files }}"

          rubycritic --format console \
            --minimum-score 90 \
            --no-browser \
            ${{ steps.changed-files.outputs.all_changed_files }}

      - name: Comment PR with Results
        if: failure()
        uses: actions/github-script@v6
        with:
          script: |
            github.rest.issues.createComment({
              issue_number: context.issue.number,
              owner: context.repo.owner,
              repo: context.repo.repo,
              body: '⚠️ Code quality check failed. Please review the RubyCritic output above.'
            })
```

### Workflow with Coverage and Quality

Combine with SimpleCov for comprehensive analysis:

```yaml
name: Tests and Quality

on: [push, pull_request]

jobs:
  test-and-quality:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout code
        uses: actions/checkout@v3

      - name: Set up Ruby
        uses: ruby/setup-ruby@v1
        with:
          ruby-version: 3.2
          bundler-cache: true

      - name: Run tests with coverage
        run: bundle exec rspec
        env:
          COVERAGE: true

      - name: Install RubyCritic
        run: gem install rubycritic

      - name: Run RubyCritic
        run: |
          rubycritic --format console --format html \
            --minimum-score 90 \
            app/ lib/

      - name: Upload Coverage Report
        uses: actions/upload-artifact@v3
        with:
          name: coverage-report
          path: coverage/

      - name: Upload Quality Report
        uses: actions/upload-artifact@v3
        with:
          name: quality-report
          path: tmp/rubycritic/
```

## GitLab CI Integration

Create `.gitlab-ci.yml`:

```yaml
stages:
  - test
  - quality

quality:
  stage: quality
  image: ruby:3.2
  before_script:
    - gem install rubycritic
  script:
    - rubycritic --format console --format json --minimum-score 90 app/ lib/
  artifacts:
    paths:
      - tmp/rubycritic/
    expire_in: 1 week
  only:
    - merge_requests
    - main
```

### GitLab CI with Changed Files Only

```yaml
quality:mr:
  stage: quality
  image: ruby:3.2
  before_script:
    - gem install rubycritic
  script:
    - |
      git fetch origin $CI_MERGE_REQUEST_TARGET_BRANCH_NAME
      CHANGED_FILES=$(git diff --name-only origin/$CI_MERGE_REQUEST_TARGET_BRANCH_NAME...HEAD | grep '\.rb$' || true)

      if [ -n "$CHANGED_FILES" ]; then
        echo "Analyzing changed files:"
        echo "$CHANGED_FILES"
        rubycritic --format console --minimum-score 90 $CHANGED_FILES
      else
        echo "No Ruby files changed"
      fi
  only:
    - merge_requests
```

## CircleCI Integration

Create `.circleci/config.yml`:

```yaml
version: 2.1

jobs:
  quality:
    docker:
      - image: cimg/ruby:3.2
    steps:
      - checkout
      - run:
          name: Install dependencies
          command: bundle install
      - run:
          name: Install RubyCritic
          command: gem install rubycritic
      - run:
          name: Run RubyCritic
          command: |
            rubycritic --format console --format json \
              --minimum-score 90 \
              --no-browser \
              app/ lib/
      - store_artifacts:
          path: tmp/rubycritic
          destination: quality-report

workflows:
  version: 2
  build-and-quality:
    jobs:
      - quality
```

## Shared Git Hooks Setup

Use a shared hooks directory for team consistency:

### Setup Script

Create `bin/setup-git-hooks`:

```bash
#!/bin/bash

HOOKS_DIR=".git-hooks"
GIT_HOOKS_DIR=".git/hooks"

# Create symlinks for all hooks
for hook in "$HOOKS_DIR"/*; do
  hook_name=$(basename "$hook")
  ln -sf "../../$HOOKS_DIR/$hook_name" "$GIT_HOOKS_DIR/$hook_name"
  chmod +x "$HOOKS_DIR/$hook_name"
  echo "Installed $hook_name hook"
done

echo "✅ Git hooks installed successfully!"
```

Make executable:
```bash
chmod +x bin/setup-git-hooks
```

### Team Workflow

1. Create `.git-hooks/` directory (tracked in git)
2. Add hooks to `.git-hooks/`
3. Run `bin/setup-git-hooks` during project setup
4. Document in README:

```markdown
## Setup

1. Clone repository
2. Run `bin/setup-git-hooks` to install quality checks
3. Install dependencies: `bundle install`
```

## Bypassing Hooks

When necessary to bypass quality checks:

```bash
# Skip pre-commit hook
git commit --no-verify -m "Message"

# Skip pre-push hook
git push --no-verify
```

**Use sparingly** - only when:
- Emergency hotfixes
- Work-in-progress commits
- Non-code changes (docs, config)

## Best Practices

1. **Fast feedback**: Use pre-commit for quick checks
2. **Comprehensive analysis**: Use pre-push for thorough checks
3. **CI as gatekeeper**: Always run in CI, even if hooks are skipped
4. **Team adoption**: Make hooks easy to install (`bin/setup-git-hooks`)
5. **Flexible thresholds**: Different scores for different branches
6. **Clear messaging**: Explain why checks fail and how to fix
7. **Escape hatch**: Document when `--no-verify` is acceptable
8. **Artifact storage**: Keep reports for historical analysis
9. **PR comments**: Auto-comment on PRs with quality issues
10. **Regular review**: Adjust thresholds as codebase improves

## Troubleshooting

### Hooks Not Running

```bash
# Check if hooks are executable
ls -la .git/hooks/pre-commit

# Make executable
chmod +x .git/hooks/pre-commit

# Verify hook content
cat .git/hooks/pre-commit
```

### Hooks Running on Non-Ruby Commits

Add file type check:
```bash
RUBY_FILES=$(git diff --cached --name-only | grep '\.rb$')
if [ -z "$RUBY_FILES" ]; then
  exit 0  # No Ruby files, skip
fi
```

### CI Failing but Local Hooks Pass

Ensure same RubyCritic version:
```yaml
# In CI, use Bundler version
- run: bundle exec rubycritic ...

# Locally, also use Bundler
bundle exec rubycritic ...
```

### Performance Issues in Hooks

Analyze only changed files:
```bash
# Instead of analyzing entire app/
RUBY_FILES=$(git diff --cached --name-only | grep '\.rb$')
rubycritic $RUBY_FILES
```

## Example Repository Setup

Complete setup for a Rails application:

```
project/
├── .git-hooks/
│   ├── pre-commit       # Quality check on staged files
│   └── pre-push         # Comprehensive analysis
├── .github/
│   └── workflows/
│       └── quality.yml  # CI quality checks
├── .rubycritic.yml      # Configuration
├── bin/
│   └── setup-git-hooks  # Installation script
└── scripts/
    └── check_quality.sh # Shared quality check script
```

This provides:
- Local pre-commit checks (fast)
- Pre-push comprehensive analysis
- CI validation
- Team-wide consistency
- Easy onboarding
