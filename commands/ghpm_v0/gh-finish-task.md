---
description: Finish a task - creates PR, updates GitHub issue, updates local tracker
allowed-tools: [Read, Edit, Write, Bash]
---

<objective>
Complete the execution workflow by creating a PR linked to the issue and updating all tracking.
</objective>

<prerequisites>
- Implementation complete (all ACs satisfied)
- On feature branch with committed changes
- `.current-task.md` exists with issue context
</prerequisites>

<workflow>
## Step 1: Load Task Context

```bash
cat .current-task.md
```

Extract: issue number, title, ACs, branch name

## Step 2: Verify Ready State

1. **Check all tests pass:**
   ```bash
   # Run test command from .current-task.md
   {test_command}
   ```

2. **Check for uncommitted changes:**
   ```bash
   git status
   ```

3. **Confirm ACs with human** if not already done

## Step 3: Push Branch

```bash
git push -u origin $(git branch --show-current)
```

## Step 4: Create Pull Request

```bash
BRANCH=$(git branch --show-current)
REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner)

gh pr create \
  --repo $REPO \
  --title "{type}: {description} (#{issue_number})" \
  --body "## Summary
{Brief description of what was implemented}

## Closes #{issue_number}

## Changes Made
{List key changes}

## Acceptance Criteria Verification
- [x] AC1: {description}
- [x] AC2: {description}
- [x] AC3: {description}

## Testing
- [x] Unit tests added/updated
- [x] All tests pass

## Implementation Notes
{Any decisions made or notes for reviewers}"
```

## Step 5: Update GitHub Issue

```bash
PR_NUMBER=$(gh pr view --json number -q .number)

gh issue comment {issue_number} --body "## Implementation Complete

**PR:** #$PR_NUMBER

### All Acceptance Criteria Met
- [x] AC1: {description}
- [x] AC2: {description}  
- [x] AC3: {description}

### Summary
{Brief technical summary of implementation}

### Ready for Review
This PR is ready for code review."
```

## Step 6: Update Local Tracker

If `.github-workflow-tracker.md` exists:

```bash
# Update task status and PR
DATE=$(date '+%Y-%m-%d %H:%M')

# Add session log entry
cat >> .github-workflow-tracker.md << EOF

### $DATE
**Agent**: Execution
**Issue**: #{issue_number} - {title}
**Actions**:
- Implementation complete
- Created PR #{pr_number}
- All ACs verified

EOF
```

## Step 7: Cleanup

```bash
# Remove task context file
rm .current-task.md
```

## Step 8: Report Completion

"## Task Complete

**Issue:** #{issue_number} - {title}
**PR:** #{pr_number} - {pr_url}
**Status:** Ready for review

The PR will automatically close the issue when merged.

Next steps:
- Monitor PR for review comments
- Address any feedback
- Merge when approved"
</workflow>

<pr_title_conventions>
Format: `{type}: {description} (#{issue_number})`

| Type | Use |
|------|-----|
| `feat` | New feature |
| `fix` | Bug fix |
| `refactor` | Code restructuring |
| `docs` | Documentation |
| `test` | Adding tests |
| `chore` | Maintenance |

Examples:
- `feat: add user authentication (#42)`
- `fix: resolve null pointer in payment flow (#103)`
- `refactor: extract email service (#87)`
</pr_title_conventions>
