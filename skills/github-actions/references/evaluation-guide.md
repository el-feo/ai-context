# Workflow Evaluation Guide

Framework for evaluating GitHub Actions workflows for security, performance, and best practices.

## Evaluation Framework

Use this systematic approach to evaluate workflows:

1. **Security Analysis** (Critical) - Identify security vulnerabilities
2. **Performance Review** (Important) - Find optimization opportunities
3. **Best Practices Audit** (Recommended) - Check against standards
4. **Maintainability Assessment** (Nice to have) - Evaluate code quality

## Security Analysis

### Critical Security Issues (Must Fix)

**1. GITHUB_TOKEN Permissions**

❌ **FAIL:**
```yaml
# No permissions specified - defaults to permissive
on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
```

✅ **PASS:**
```yaml
permissions:
  contents: read  # Minimum required

jobs:
  test:
    runs-on: ubuntu-latest
```

**2. Hardcoded Secrets**

❌ **FAIL:**
```yaml
env:
  API_KEY: sk_live_abc123
  DATABASE_URL: postgres://user:password@host/db
```

✅ **PASS:**
```yaml
env:
  API_KEY: ${{ secrets.API_KEY }}
  DATABASE_URL: ${{ secrets.DATABASE_URL }}
```

**3. Unpinned Actions**

❌ **FAIL:**
```yaml
- uses: actions/checkout@main
- uses: some-org/action@latest
```

✅ **PASS:**
```yaml
- uses: actions/checkout@b4ffde65f46336ab88eb53be808477a3936bae11  # v4.1.1
- uses: actions/setup-node@v4  # Acceptable for verified creators
```

**4. Dangerous pull_request_target Usage**

❌ **FAIL:**
```yaml
on: pull_request_target

jobs:
  build:
    steps:
      - uses: actions/checkout@v4
        with:
          ref: ${{ github.event.pull_request.head.sha }}
      - run: npm install && npm build  # Runs untrusted code with secrets!
```

✅ **PASS:**
```yaml
# Use pull_request instead for untrusted code
on: pull_request

# OR only use pull_request_target for trusted actions (no code execution)
on: pull_request_target
jobs:
  label:
    steps:
      - uses: actions/labeler@v5  # Trusted action only
```

**5. Script Injection**

❌ **FAIL:**
```yaml
- run: echo "Title: ${{ github.event.issue.title }}"
# Vulnerable to command injection
```

✅ **PASS:**
```yaml
- env:
    TITLE: ${{ github.event.issue.title }}
  run: echo "Title: $TITLE"
```

### Important Security Issues (Should Fix)

**1. Long-lived Credentials vs OIDC**

⚠️ **NEEDS IMPROVEMENT:**
```yaml
- uses: aws-actions/configure-aws-credentials@v4
  with:
    aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
    aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
```

✅ **BETTER:**
```yaml
permissions:
  id-token: write

- uses: aws-actions/configure-aws-credentials@v4
  with:
    role-to-assume: arn:aws:iam::123456789012:role/GitHubActions
    aws-region: us-east-1
```

**2. Environment Protection**

⚠️ **NEEDS IMPROVEMENT:**
```yaml
jobs:
  deploy:
    steps:
      - run: ./deploy-to-production.sh
        env:
          PROD_API_KEY: ${{ secrets.PROD_API_KEY }}
```

✅ **BETTER:**
```yaml
jobs:
  deploy:
    environment: production  # Requires manual approval
    steps:
      - run: ./deploy-to-production.sh
        env:
          PROD_API_KEY: ${{ secrets.PROD_API_KEY }}
```

**3. Third-Party Actions**

⚠️ **REVIEW REQUIRED:**
```yaml
- uses: random-user/unknown-action@v1
```

**Evaluation checklist:**
- [ ] Verified creator badge?
- [ ] Recent maintenance activity?
- [ ] Source code reviewed?
- [ ] Many stars/users?
- [ ] Known security issues?

### Security Score Calculation

| Category | Weight | Score |
|----------|--------|-------|
| No hardcoded secrets | 25% | ___/25 |
| GITHUB_TOKEN read-only default | 25% | ___/25 |
| Actions pinned to SHA/tags | 20% | ___/20 |
| No dangerous triggers | 15% | ___/15 |
| Input validation | 10% | ___/10 |
| OIDC usage | 5% | ___/5 |

**Total Security Score: ___/100**

- **90-100:** Excellent security posture
- **75-89:** Good, minor improvements needed
- **60-74:** Moderate, address important issues
- **<60:** Poor, critical issues must be fixed

## Performance Review

### Performance Metrics

Target execution times:
- **Lint/format:** <2 minutes
- **Unit tests:** <5 minutes
- **Integration tests:** <10 minutes
- **Full CI pipeline:** <15 minutes
- **Deployment:** <10 minutes

### Performance Checklist

**1. Dependency Caching**

❌ **SLOW:**
```yaml
- run: npm install  # Downloads every time
```

✅ **FAST:**
```yaml
- uses: actions/setup-node@v4
  with:
    node-version: '20'
    cache: 'npm'  # Built-in caching

- run: npm ci
```

**Impact:** Can reduce build time by 80%

**2. Parallelization**

❌ **SLOW:**
```yaml
jobs:
  test:
    steps:
      - run: npm run lint
      - run: npm run typecheck
      - run: npm test
      - run: npm run build
```

✅ **FAST:**
```yaml
jobs:
  lint:
    steps:
      - run: npm run lint

  typecheck:
    steps:
      - run: npm run typecheck

  test:
    steps:
      - run: npm test

  build:
    steps:
      - run: npm run build

# All jobs run in parallel
```

**3. Selective Triggers**

❌ **WASTEFUL:**
```yaml
on: [push]  # Runs on every commit, even doc changes
```

✅ **EFFICIENT:**
```yaml
on:
  push:
    paths:
      - 'src/**'
      - 'package.json'
    paths-ignore:
      - '**.md'
      - 'docs/**'
```

**4. Concurrency Control**

❌ **WASTEFUL:**
```yaml
on: pull_request
# Multiple commits = multiple full runs
```

✅ **EFFICIENT:**
```yaml
on: pull_request

concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true  # Cancel older runs
```

**5. Shallow Checkout**

❌ **SLOW:**
```yaml
- uses: actions/checkout@v4
  with:
    fetch-depth: 0  # Full history - only needed for specific cases
```

✅ **FAST:**
```yaml
- uses: actions/checkout@v4
  # fetch-depth: 1 is default - only latest commit
```

### Performance Score Calculation

| Optimization | Implemented? | Impact | Points |
|-------------|-------------|--------|--------|
| Dependency caching | Yes/No | High | ___/30 |
| Job parallelization | Yes/No | High | ___/25 |
| Selective triggers | Yes/No | Medium | ___/15 |
| Concurrency control | Yes/No | Medium | ___/15 |
| Matrix builds (when appropriate) | Yes/No | Medium | ___/10 |
| Timeouts set | Yes/No | Low | ___/5 |

**Total Performance Score: ___/100**

**Cache Hit Rate:** ___% (Target: >80%)

## Best Practices Audit

### Workflow Structure

**1. Naming**

❌ **POOR:**
```yaml
name: CI
```

✅ **GOOD:**
```yaml
name: Ruby on Rails CI
```

**2. Documentation**

❌ **POOR:**
```yaml
- run: |
    npm ci
    npm run build
    npm test
```

✅ **GOOD:**
```yaml
- name: Install dependencies
  run: npm ci

- name: Build application
  run: npm run build

- name: Run test suite
  run: npm test
```

**3. Error Handling**

❌ **POOR:**
```yaml
- run: ./deploy.sh  # Fails silently if script has issues
```

✅ **GOOD:**
```yaml
- name: Deploy application
  run: |
    set -euo pipefail  # Fail on errors
    ./deploy.sh
  timeout-minutes: 10
```

### Code Quality Patterns

**1. DRY Principle - Use Reusable Workflows**

❌ **REPETITIVE:**
```yaml
# .github/workflows/test-ruby-3-1.yml
jobs:
  test:
    steps:
      - uses: ruby/setup-ruby@v1
        with:
          ruby-version: '3.1'
      - run: bundle exec rspec

# .github/workflows/test-ruby-3-2.yml
jobs:
  test:
    steps:
      - uses: ruby/setup-ruby@v1
        with:
          ruby-version: '3.2'
      - run: bundle exec rspec
```

✅ **DRY:**
```yaml
# .github/workflows/reusable-test.yml
on:
  workflow_call:
    inputs:
      ruby-version:
        required: true
        type: string

jobs:
  test:
    steps:
      - uses: ruby/setup-ruby@v1
        with:
          ruby-version: ${{ inputs.ruby-version }}
      - run: bundle exec rspec

# .github/workflows/ci.yml
jobs:
  test-3-1:
    uses: ./.github/workflows/reusable-test.yml
    with:
      ruby-version: '3.1'

  test-3-2:
    uses: ./.github/workflows/reusable-test.yml
    with:
      ruby-version: '3.2'
```

**2. Conditional Logic**

❌ **COMPLEX:**
```yaml
- if: github.ref == 'refs/heads/main' && github.event_name == 'push' && !contains(github.event.head_commit.message, '[skip ci]')
  run: ./deploy.sh
```

✅ **READABLE:**
```yaml
- name: Check deployment conditions
  id: should-deploy
  run: |
    if [[ "${{ github.ref }}" == "refs/heads/main" ]] && \
       [[ "${{ github.event_name }}" == "push" ]] && \
       ! echo "${{ github.event.head_commit.message }}" | grep -q "\[skip ci\]"; then
      echo "deploy=true" >> $GITHUB_OUTPUT
    fi

- name: Deploy to production
  if: steps.should-deploy.outputs.deploy == 'true'
  run: ./deploy.sh
```

### Best Practices Score

| Practice | Status | Points |
|----------|--------|--------|
| Descriptive workflow names | _____ | ___/10 |
| Step names provided | _____ | ___/10 |
| Timeouts configured | _____ | ___/10 |
| Error handling (set -e) | _____ | ___/10 |
| DRY - reusable workflows | _____ | ___/15 |
| Appropriate conditionals | _____ | ___/10 |
| Artifacts uploaded/used properly | _____ | ___/10 |
| Environment variables organized | _____ | ___/10 |
| Services health checks | _____ | ___/10 |
| Comments for complex logic | _____ | ___/5 |

**Total Best Practices Score: ___/100**

## Maintainability Assessment

### Code Smells

**1. Magic Numbers/Strings**

❌ **POOR:**
```yaml
- run: sleep 30  # Why 30?
- run: curl https://api.example.com/v1/deploy
```

✅ **GOOD:**
```yaml
env:
  STARTUP_DELAY: 30  # Wait for services to be ready
  API_ENDPOINT: https://api.example.com/v1

- run: sleep $STARTUP_DELAY
- run: curl $API_ENDPOINT/deploy
```

**2. Complex Shell Scripts**

❌ **POOR:**
```yaml
- run: |
    # 50 lines of bash script
    for file in $(find . -name "*.rb"); do
      # complex logic
    done
    # more complex logic
```

✅ **GOOD:**
```yaml
# Move to script file: scripts/process-files.sh
- run: ./scripts/process-files.sh
```

**3. Duplicate Configuration**

❌ **POOR:**
```yaml
jobs:
  test-1:
    env:
      RUBY_VERSION: '3.2'
      RAILS_ENV: test
      DATABASE_URL: postgres://localhost/test

  test-2:
    env:
      RUBY_VERSION: '3.2'
      RAILS_ENV: test
      DATABASE_URL: postgres://localhost/test
```

✅ **GOOD:**
```yaml
env:
  RUBY_VERSION: '3.2'
  RAILS_ENV: test
  DATABASE_URL: postgres://localhost/test

jobs:
  test-1:
    # Inherits workflow-level env
  test-2:
    # Inherits workflow-level env
```

## Evaluation Report Template

```markdown
# Workflow Evaluation Report

**Workflow:** `.github/workflows/[name].yml`
**Evaluated by:** [Name]
**Date:** [Date]

## Executive Summary

Overall Status: ✅ PASS / ⚠️ NEEDS IMPROVEMENT / ❌ FAIL

- Security Score: ___/100
- Performance Score: ___/100
- Best Practices Score: ___/100
- Maintainability: ___/100

**Overall Score: ___/100**

## Critical Issues (Must Fix)

1. [Issue 1]
   - **Severity:** Critical
   - **Location:** Line X
   - **Current:** [Code snippet]
   - **Fix:** [Solution]
   - **Impact:** [Security/Performance/Reliability]

## Important Issues (Should Fix)

1. [Issue 1]
   - **Severity:** Important
   - **Location:** Line X
   - **Recommendation:** [Solution]
   - **Benefit:** [Expected improvement]

## Recommended Improvements

1. [Improvement 1]
   - **Current:** [Description]
   - **Proposed:** [Solution]
   - **Expected benefit:** [Time savings, better security, etc.]

## Positive Findings

- ✅ [Good practice 1]
- ✅ [Good practice 2]

## Action Items

Priority order:

1. [ ] Fix critical security issues
2. [ ] Implement important improvements
3. [ ] Apply recommended optimizations
4. [ ] Update documentation

## Metrics

| Metric | Current | Target | Status |
|--------|---------|--------|--------|
| Workflow execution time | X min | <15 min | ✅/❌ |
| Cache hit rate | X% | >80% | ✅/❌ |
| Security score | X/100 | >90/100 | ✅/❌ |

## Recommendations Summary

**Immediate Actions:**
- [Action 1]
- [Action 2]

**Medium-term Improvements:**
- [Improvement 1]
- [Improvement 2]

**Long-term Considerations:**
- [Consideration 1]
- [Consideration 2]
```

## Automated Evaluation Tools

### GitHub Action for Workflow Validation

```yaml
name: Validate Workflows

on:
  pull_request:
    paths:
      - '.github/workflows/**'

jobs:
  validate:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v4

      - name: Validate YAML syntax
        run: |
          for file in .github/workflows/*.yml; do
            echo "Validating $file"
            yamllint "$file"
          done

      - name: Check for security issues
        run: |
          # Check for hardcoded secrets
          if grep -r "password\|secret\|key" .github/workflows/ | grep -v "secrets\."; then
            echo "❌ Potential hardcoded secrets found"
            exit 1
          fi

      - name: Check action pinning
        run: |
          # Warn about unpinned actions
          if grep -r "uses:.*@main\|uses:.*@master" .github/workflows/; then
            echo "⚠️ Actions using branch refs found (should use tags or SHAs)"
          fi
```

### actionlint

Use [actionlint](https://github.com/rhysd/actionlint) for automated validation:

```bash
# Install
brew install actionlint

# Run
actionlint .github/workflows/*.yml
```

```yaml
# In workflow
- uses: reviewdog/action-actionlint@v1
  with:
    reporter: github-pr-review
```

## Evaluation Workflow

1. **Initial Review**
   - Run YAML validation
   - Check for obvious issues
   - Review workflow trigger configuration

2. **Security Analysis**
   - Complete security checklist
   - Calculate security score
   - Identify critical issues

3. **Performance Review**
   - Measure current execution time
   - Identify optimization opportunities
   - Calculate performance score

4. **Best Practices Audit**
   - Check naming and documentation
   - Review code organization
   - Calculate best practices score

5. **Generate Report**
   - Document findings
   - Prioritize action items
   - Set follow-up timeline

6. **Follow-up**
   - Verify fixes implemented
   - Measure improvement
   - Update documentation

## Pass/Fail Criteria

### PASS Criteria

Workflow passes evaluation if:
- Security score ≥ 90/100
- No critical security issues
- Performance score ≥ 70/100
- Execution time meets targets
- Best practices score ≥ 75/100

### NEEDS IMPROVEMENT Criteria

Workflow needs improvement if:
- Security score 75-89/100
- Important security issues present
- Performance score 60-69/100
- Execution time 1.5x target
- Best practices score 60-74/100

### FAIL Criteria

Workflow fails evaluation if:
- Security score < 75/100
- Critical security issues present
- Performance score < 60/100
- Execution time >2x target
- Best practices score < 60/100

## Resources

- [GitHub Actions Security Hardening](https://docs.github.com/en/actions/security-guides/security-hardening-for-github-actions)
- [actionlint](https://github.com/rhysd/actionlint)
- [Awesome Actions Security](https://github.com/step-security/supply-chain-goat)
