---
description: Create a GitHub issue and branch in one step for quick bug fixes and small tasks, bypassing the PRD workflow.
argument-hint: <issue description>
allowed-tools: [Bash]
---

<objective>
Create a GitHub issue and working branch in a single step, enabling developers to quickly start work on bug fixes, small enhancements, and maintenance tasks without going through the full PRD workflow. The command creates the issue, labels it appropriately, creates and checks out a feature branch, and optionally adds the issue to a GitHub Project.
</objective>

<prerequisites>
- `gh` CLI installed and authenticated (`gh auth status`)
- Working directory is a git repository with GitHub remote
- User has write access to repository issues
- Git working directory is clean (no uncommitted changes)
- Optional: `GHPM_PROJECT` environment variable set for project association
</prerequisites>

<arguments>
**Required:**
- Issue description/title (captured from user input via $ARGUMENTS)

**Optional flags (in $ARGUMENTS):**
- `--label <name>` - Add an additional label beyond "Quick Issue"
- `--no-branch` - Create issue only, skip branch creation
- `--type <fix|feat|chore>` - Override default branch prefix (default: `fix`)

**Optional environment variables:**
- `GHPM_PROJECT` - GitHub Project number to add issue to (e.g., `export GHPM_PROJECT=7`)
</arguments>

<usage_examples>
**Basic usage (creates issue and branch):**

```bash
/ghpm:quick-issue Fix the login redirect loop when session expires
```

Output:
```
Creating quick issue...

✓ Issue #42 created: "Fix the login redirect loop when session expires"
  https://github.com/owner/repo/issues/42
✓ Branch created: fix/issue-42-login-redirect-loop
✓ Switched to branch fix/issue-42-login-redirect-loop

Ready to work on issue #42. What would you like me to do first?
```

**With additional label:**

```bash
/ghpm:quick-issue Add tooltip to export button --label enhancement
```

**Issue only (no branch):**

```bash
/ghpm:quick-issue Update README with new API docs --no-branch
```

**With branch type override:**

```bash
/ghpm:quick-issue Add dark mode toggle --type feat
```
→ Creates branch: `feat/issue-43-dark-mode-toggle`

**With project association:**

```bash
export GHPM_PROJECT=7
/ghpm:quick-issue Fix broken date formatting in reports
```
→ Issue added to project #7

</usage_examples>

<operating_rules>
- Do not ask clarifying questions. Create the issue immediately with the provided description.
- The issue description becomes both the issue title and the summary in the body.
- Always create the "Quick Issue" label if it doesn't exist.
- Branch names are sanitized: lowercase, special characters removed, truncated to 50 chars.
- Default branch prefix is `fix/` unless overridden with `--type`.
- If `--no-branch` is specified, skip branch creation entirely.
- On any error, provide actionable guidance for resolution.
</operating_rules>

<workflow>

## Step 1: Validate Environment

```bash
# 1. Verify gh CLI authentication
gh auth status || { echo "ERROR: Not authenticated. Run 'gh auth login'"; exit 1; }

# 2. Verify in git repository
git rev-parse --git-dir > /dev/null 2>&1 || { echo "ERROR: Not in a git repository"; exit 1; }

# 3. Verify GitHub remote exists
REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner) || { echo "ERROR: No GitHub remote found"; exit 1; }
OWNER=$(gh repo view --json owner -q '.owner.login')
```

## Step 2: Parse Arguments

Extract from $ARGUMENTS:
- Issue description (everything that's not a flag)
- `--label <name>` if present
- `--no-branch` flag
- `--type <fix|feat|chore>` if present (default: `fix`)

```bash
# Example parsing
DESCRIPTION="<extracted description>"
EXTRA_LABEL=""  # or extracted label name
NO_BRANCH=false  # or true if --no-branch present
BRANCH_TYPE="fix"  # or feat/chore if --type specified
```

Validate:
- Description must not be empty
- If `--type` provided, must be one of: fix, feat, chore

## Step 3: Ensure "Quick Issue" Label Exists

```bash
# Check if label exists, create if not
gh label list --repo "$REPO" --json name -q '.[].name' | grep -q "^Quick Issue$" || \
  gh label create "Quick Issue" \
    --description "Quick issue for bug fixes and small tasks" \
    --color "FBCA04" \
    --repo "$REPO"
```

## Step 4: Create GitHub Issue

```bash
# Build label list
LABELS="Quick Issue"
if [ -n "$EXTRA_LABEL" ]; then
  LABELS="$LABELS,$EXTRA_LABEL"
fi

# Create issue with body
ISSUE_URL=$(gh issue create \
  --repo "$REPO" \
  --title "$DESCRIPTION" \
  --label "$LABELS" \
  --body "$(cat <<EOF
## Quick Issue

$DESCRIPTION

---
*Created via \`/ghpm:quick-issue\`*
EOF
)")

# Extract issue number from URL
ISSUE_NUM=$(echo "$ISSUE_URL" | grep -oE '[0-9]+$')
```

## Step 5: Add to GitHub Project (if configured)

```bash
if [ -n "$GHPM_PROJECT" ]; then
  gh project item-add "$GHPM_PROJECT" --owner "$OWNER" --url "$ISSUE_URL" 2>/dev/null && \
    echo "✓ Added to project #$GHPM_PROJECT" || \
    echo "WARNING: Could not add to project #$GHPM_PROJECT"
fi
```

## Step 6: Create and Checkout Branch (unless --no-branch)

```bash
if [ "$NO_BRANCH" = false ]; then
  # Generate branch name slug from description
  # 1. Convert to lowercase
  # 2. Replace spaces and special chars with hyphens
  # 3. Remove consecutive hyphens
  # 4. Truncate to 50 chars
  # 5. Remove trailing hyphens
  SLUG=$(echo "$DESCRIPTION" | \
    tr '[:upper:]' '[:lower:]' | \
    sed 's/[^a-z0-9]/-/g' | \
    sed 's/-\+/-/g' | \
    cut -c1-50 | \
    sed 's/-$//')

  BRANCH_NAME="$BRANCH_TYPE/issue-$ISSUE_NUM-$SLUG"

  # Check for uncommitted changes
  if ! git diff-index --quiet HEAD -- 2>/dev/null; then
    echo "WARNING: Uncommitted changes detected. Branch created but not checked out."
    echo "Run: git stash && git checkout $BRANCH_NAME"
  else
    # Create and checkout branch
    git checkout -b "$BRANCH_NAME" || {
      echo "ERROR: Failed to create branch. You may need to create it manually:"
      echo "  git checkout -b $BRANCH_NAME"
    }
  fi

  # Update issue body with branch link
  gh issue edit "$ISSUE_NUM" --repo "$REPO" --body "$(cat <<EOF
## Quick Issue

$DESCRIPTION

**Branch:** \`$BRANCH_NAME\`

---
*Created via \`/ghpm:quick-issue\`*
EOF
)"
fi
```

## Step 7: Output Success Message

```bash
echo ""
echo "✓ Issue #$ISSUE_NUM created: \"$DESCRIPTION\""
echo "  $ISSUE_URL"

if [ "$NO_BRANCH" = false ]; then
  echo "✓ Branch created: $BRANCH_NAME"
  echo "✓ Switched to branch $BRANCH_NAME"
fi

if [ -n "$GHPM_PROJECT" ]; then
  echo "✓ Added to project #$GHPM_PROJECT"
fi

echo ""
echo "Ready to work on issue #$ISSUE_NUM. What would you like me to do first?"
```

</workflow>

<error_handling>
**If gh CLI not authenticated:**
```
ERROR: Not authenticated. Run 'gh auth login'
```

**If not in git repository:**
```
ERROR: Not in a git repository. Navigate to your project directory.
```

**If no GitHub remote:**
```
ERROR: No GitHub remote found. Add one with: git remote add origin <url>
```

**If description is empty:**
```
ERROR: Issue description required.
Usage: /ghpm:quick-issue <description> [--label <name>] [--no-branch] [--type <fix|feat|chore>]
```

**If issue creation fails:**
```
ERROR: Failed to create issue. Check:
- gh auth status (authentication)
- Repository permissions (write access to issues)
- Rate limits: gh api rate_limit
```

**If branch creation fails:**
```
WARNING: Issue #N created, but branch creation failed.
Create branch manually: git checkout -b <branch-name>
```

**If uncommitted changes exist:**
```
WARNING: Uncommitted changes detected. Branch created but not checked out.
Run: git stash && git checkout <branch-name>
```
</error_handling>

<success_criteria>
Command completes successfully when:

1. GitHub issue is created with "Quick Issue" label
2. Issue body contains description and branch link (if branch created)
3. Branch is created with correct naming convention (unless `--no-branch`)
4. Branch is checked out (unless uncommitted changes or `--no-branch`)
5. Issue is added to project (if `GHPM_PROJECT` set)
6. Success message displays issue URL and branch name

**Verification:**

```bash
# View the created issue
gh issue view <issue_number>

# Check current branch
git branch --show-current

# Verify issue label
gh issue view <issue_number> --json labels -q '.labels[].name'
```
</success_criteria>

<output>
After completion, display:

```
Creating quick issue...

✓ Issue #<number> created: "<description>"
  <issue_url>
✓ Branch created: <branch_type>/issue-<number>-<slug>
✓ Switched to branch <branch_type>/issue-<number>-<slug>
[✓ Added to project #<project_number>]  (if GHPM_PROJECT set)

Ready to work on issue #<number>. What would you like me to do first?
```

If `--no-branch` was specified:

```
Creating quick issue...

✓ Issue #<number> created: "<description>"
  <issue_url>
[✓ Added to project #<project_number>]  (if GHPM_PROJECT set)

Issue created. Run `/ghpm:tdd-task task=#<number>` to start implementation.
```
</output>

<related_commands>
**After creating a quick issue:**
- `/ghpm:tdd-task task=#N` - Implement the issue using TDD
- `/ghpm:execute task=#N` - Execute the issue (auto-routes to TDD or non-TDD)

**Full GHPM workflow (for larger features):**
1. `/ghpm:create-prd` - Create PRD from user input
2. `/ghpm:create-epics` - Break PRD into Epics
3. `/ghpm:create-tasks` - Break Epics into Tasks
4. `/ghpm:tdd-task` - Implement Tasks with TDD
</related_commands>

Proceed now: parse $ARGUMENTS, validate environment, create issue and branch.
