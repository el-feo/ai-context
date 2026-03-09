# Git Hooks and CI Integration

## Pre-Commit Hook

Create `.git/hooks/pre-commit` (make executable with `chmod +x`):

```bash
#!/bin/bash

RUBY_FILES=$(git diff --cached --name-only --diff-filter=ACM | grep '\.rb$')

if [ -z "$RUBY_FILES" ]; then
  exit 0
fi

echo "Running RubyCritic on staged files..."

if [ -f "scripts/check_quality.sh" ]; then
  scripts/check_quality.sh $RUBY_FILES
else
  bundle exec rubycritic --format console --no-browser $RUBY_FILES
fi

if [ $? -ne 0 ]; then
  echo "Quality check failed. Fix issues or use 'git commit --no-verify' to skip."
  exit 1
fi
```

### With Score Threshold

```bash
OUTPUT=$(bundle exec rubycritic --format console --no-browser $RUBY_FILES 2>&1)
echo "$OUTPUT"
SCORE=$(echo "$OUTPUT" | grep -oP 'Score: \K\d+' | head -1)
MINIMUM_SCORE=85

if [ -n "$SCORE" ] && [ "$SCORE" -lt "$MINIMUM_SCORE" ]; then
  echo "Quality score $SCORE is below minimum $MINIMUM_SCORE"
  exit 1
fi
```

## GitHub Actions

```yaml
name: Code Quality

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  rubycritic:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
        with:
          fetch-depth: 0

      - uses: ruby/setup-ruby@v1
        with:
          ruby-version: 3.2
          bundler-cache: true

      - name: Run RubyCritic
        run: |
          gem install rubycritic
          rubycritic --format console --format json \
            --minimum-score 90 --no-browser app/ lib/

      - name: Upload Report
        if: always()
        uses: actions/upload-artifact@v3
        with:
          name: rubycritic-report
          path: tmp/rubycritic/
          retention-days: 30
```

## GitLab CI

```yaml
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

## Team Setup

Use a shared hooks directory tracked in git:

1. Create `.git-hooks/` with hook scripts
2. Create `bin/setup-git-hooks` to symlink them:

```bash
#!/bin/bash
for hook in .git-hooks/*; do
  ln -sf "../../$hook" ".git/hooks/$(basename $hook)"
  chmod +x "$hook"
done
```

3. Run `bin/setup-git-hooks` during project setup
