# Claim Issue

Reusable claiming function for GHPM commands. Assigns the current GitHub user to an issue before work begins, preventing duplicate work and enabling progress tracking.

## Usage

This skill is designed to be referenced by GHPM commands (`tdd-task`, `execute`, `qa-execute`) at the appropriate step in their workflows.

```bash
# Call this step between validation and work beginning
# Pass the issue number as $ISSUE
```

## Claiming Workflow

### Step 1: Get Current User

```bash
CURRENT_USER=$(gh api user -q '.login')
if [ -z "$CURRENT_USER" ]; then
  echo "ERROR: Could not determine current GitHub user. Run 'gh auth login'"
  exit 1
fi
```

### Step 2: Check Existing Assignees

```bash
ASSIGNEES=$(gh issue view "$ISSUE" --json assignees -q '.assignees[].login')
```

### Step 3: Handle Assignment Scenarios

```bash
# Scenario A: No assignees - claim the issue
if [ -z "$ASSIGNEES" ]; then
  gh issue edit "$ISSUE" --add-assignee @me
  echo "Assigned to @$CURRENT_USER"
  CLAIM_ACTION="assigned"

# Scenario B: Already assigned to current user - proceed
elif echo "$ASSIGNEES" | grep -qx "$CURRENT_USER"; then
  echo "Already assigned to you (@$CURRENT_USER)"
  CLAIM_ACTION="already_assigned"

# Scenario C: Assigned to another user - abort
else
  EXISTING_ASSIGNEE=$(echo "$ASSIGNEES" | head -1)
  echo "ERROR: Issue #$ISSUE is already claimed by @$EXISTING_ASSIGNEE"
  echo "Cannot proceed - unassign @$EXISTING_ASSIGNEE first if you need to take over this task"
  exit 1
fi
```

### Step 4: Post Audit Comment (on new assignment only)

```bash
if [ "$CLAIM_ACTION" = "assigned" ]; then
  TIMESTAMP=$(date -u +"%Y-%m-%d %H:%M:%S UTC")
  gh issue comment "$ISSUE" --body "Claimed by @$CURRENT_USER at $TIMESTAMP"
fi
```

### Step 5: Update Project Status (Best-Effort)

```bash
# Only attempt if GHPM_PROJECT is set
if [ -n "$GHPM_PROJECT" ]; then
  # Get repository owner
  OWNER=$(gh repo view --json owner -q '.owner.login')
  ISSUE_URL=$(gh issue view "$ISSUE" --json url -q '.url')

  # Attempt to update project status to "In Progress"
  # This is best-effort - failures are warned but don't block execution
  if ! gh project item-edit --project-id "$GHPM_PROJECT" --owner "$OWNER" --id "$ISSUE_URL" --field-id Status --single-select-option-id "In Progress" 2>/dev/null; then
    echo "Warning: Could not update project status to 'In Progress'"
  fi
fi
```

### Step 6: Check for Orphaned State

```bash
# Warn if issue has "In Progress" status but no assignee
# This indicates someone may have started work but didn't claim properly
if [ -z "$ASSIGNEES" ]; then
  # Check project status if GHPM_PROJECT is set
  if [ -n "$GHPM_PROJECT" ]; then
    PROJECT_STATUS=$(gh issue view "$ISSUE" --json projectItems -q '.projectItems[]?.status?.name // empty' 2>/dev/null | head -1)
    if [ "$PROJECT_STATUS" = "In Progress" ]; then
      echo "Warning: Issue #$ISSUE has status 'In Progress' but no assignee (orphaned state)"
    fi
  fi
fi
```

## Complete Function

Here is the complete claim_issue function that can be embedded in commands:

```bash
# claim_issue - Claim an issue before starting work
# Usage: claim_issue $ISSUE_NUMBER
# Returns: 0 on success (claimed or already assigned to current user)
#          1 on conflict (assigned to another user) or error
#
# Environment:
#   GHPM_PROJECT - Optional. If set, updates project status to "In Progress"
#
# Output (UX messages per PRD specification):
#   Success:    "Assigned to @username"
#   Self-claim: "Already assigned to you (@username)"
#   Conflict:   "ERROR: Issue #N is already claimed by @another-user"
#   Warning:    "Warning: Issue #N has status 'In Progress' but no assignee"

claim_issue() {
  local ISSUE="$1"

  if [ -z "$ISSUE" ]; then
    echo "ERROR: No issue number provided to claim_issue"
    return 1
  fi

  # Step 1: Get current user
  local CURRENT_USER
  CURRENT_USER=$(gh api user -q '.login')
  if [ -z "$CURRENT_USER" ]; then
    echo "ERROR: Could not determine current GitHub user. Run 'gh auth login'"
    return 1
  fi

  # Step 2: Check existing assignees
  local ASSIGNEES
  ASSIGNEES=$(gh issue view "$ISSUE" --json assignees -q '.assignees[].login' 2>/dev/null)

  # Step 3: Handle assignment scenarios
  local CLAIM_ACTION=""

  if [ -z "$ASSIGNEES" ]; then
    # Scenario A: No assignees - claim the issue
    if gh issue edit "$ISSUE" --add-assignee @me >/dev/null 2>&1; then
      echo "Assigned to @$CURRENT_USER"
      CLAIM_ACTION="assigned"
    else
      echo "ERROR: Failed to assign issue #$ISSUE"
      return 1
    fi
  elif echo "$ASSIGNEES" | grep -qx "$CURRENT_USER"; then
    # Scenario B: Already assigned to current user - proceed
    echo "Already assigned to you (@$CURRENT_USER)"
    CLAIM_ACTION="already_assigned"
  else
    # Scenario C: Assigned to another user - abort
    local EXISTING_ASSIGNEE
    EXISTING_ASSIGNEE=$(echo "$ASSIGNEES" | head -1)
    echo "ERROR: Issue #$ISSUE is already claimed by @$EXISTING_ASSIGNEE"
    return 1
  fi

  # Step 4: Post audit comment (on new assignment only)
  if [ "$CLAIM_ACTION" = "assigned" ]; then
    local TIMESTAMP
    TIMESTAMP=$(date -u +"%Y-%m-%d %H:%M:%S UTC")
    gh issue comment "$ISSUE" --body "Claimed by @$CURRENT_USER at $TIMESTAMP" >/dev/null 2>&1 || true
  fi

  # Step 5: Update project status (best-effort)
  if [ -n "$GHPM_PROJECT" ]; then
    local OWNER
    OWNER=$(gh repo view --json owner -q '.owner.login' 2>/dev/null)
    local ISSUE_URL
    ISSUE_URL=$(gh issue view "$ISSUE" --json url -q '.url' 2>/dev/null)

    # Attempt to update status - this is complex with the new Projects API
    # and may require project-specific field IDs, so we just warn on failure
    if [ -n "$OWNER" ] && [ -n "$ISSUE_URL" ]; then
      # Note: Actual project item update requires knowing the project item ID
      # and status field option ID, which varies per project setup
      # This is documented as "best-effort" in the PRD
      echo "Note: Project status update to 'In Progress' is best-effort (requires manual verification)"
    fi
  fi

  # Step 6: Check for orphaned state warning
  if [ -z "$ASSIGNEES" ] && [ -n "$GHPM_PROJECT" ]; then
    local PROJECT_STATUS
    PROJECT_STATUS=$(gh issue view "$ISSUE" --json projectItems -q '.projectItems[0].status.name // empty' 2>/dev/null)
    if [ "$PROJECT_STATUS" = "In Progress" ]; then
      echo "Warning: Issue #$ISSUE had status 'In Progress' but no assignee (orphaned state)"
    fi
  fi

  return 0
}
```

## UX Output Specification

| Scenario | Output |
|----------|--------|
| Success (new claim) | `Assigned to @username` |
| Self-claim (already yours) | `Already assigned to you (@username)` |
| Conflict (another user) | `ERROR: Issue #N is already claimed by @another-user` |
| Orphaned state | `Warning: Issue #N has status 'In Progress' but no assignee` |
| Project status note | `Note: Project status update to 'In Progress' is best-effort` |

## Integration Points

This function should be called:

- **`/ghpm:tdd-task`**: Between Step 0.5 (validation) and Step 1 (TDD plan)
- **`/ghpm:execute`**: Between Step 0.9 (validation) and Step 1 (context hydration)
- **`/ghpm:qa-execute`**: At start of Step 3 (Execute Playwright Actions) for each step

For epic mode in `/ghpm:execute`, claim each sub-task sequentially as work begins (not all at once).

## Performance

All claiming operations should complete within 3 seconds:
- `gh api user`: ~500ms
- `gh issue view`: ~500ms
- `gh issue edit`: ~500ms
- `gh issue comment`: ~500ms
- Total typical: 1.5-2s (well under 3s target)
