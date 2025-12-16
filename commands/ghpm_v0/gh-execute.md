---
description: Execute a GitHub issue - loads context, creates branch, delegates to implementation workflow (TDD, etc), creates PR
allowed-tools: [Read, Edit, Write, Bash, WebFetch]
---

<objective>
Coordinate implementation of a GitHub issue by setting up the environment and delegating to an implementation workflow like TDD.
</objective>

<prerequisites>
- `gh` CLI installed and authenticated
- Working directory is the cloned repository
- Issue has been groomed (has ACs, implementation notes)
</prerequisites>

<workflow>
## Phase 1: Load Issue Context

1. **Get issue number** from user (e.g., "execute issue 42" or just "42")

2. **Fetch issue details:**

   ```bash
   gh issue view {issue_number} --repo {owner}/{repo} --json number,title,body,labels,state
   ```

3. **Parse issue body** to extract:
   - Acceptance Criteria
   - Implementation Notes
   - Affected Files/Components
   - Dependencies
   - Estimate

4. **Verify dependencies** are closed:

   ```bash
   gh issue view {dep_number} --repo {repo} --json state --jq '.state'
   ```

## Phase 2: Setup Git Environment

1. **Sync with remote:**

   ```bash
   git checkout main && git pull origin main
   ```

2. **Create feature branch:**

   ```bash
   # Format: {type}/{issue-number}-{short-description}
   git checkout -b feature/{issue_number}-{kebab-case-description}
   ```

## Phase 3: Create Task Context File

Save `.current-task.md` for implementation workflows:

```markdown
# Current Task: #{number} - {title}

## Branch
`feature/{issue_number}-{description}`

## Acceptance Criteria
- [ ] AC1: {criterion from issue}
- [ ] AC2: {criterion from issue}
- [ ] AC3: {criterion from issue}

## Implementation Notes
{parsed from issue body}

## Affected Files
- `{path/to/file}` - {what to change}

## Test Commands
- Run all: `{test_command}`
- Run specific: `{specific_test_command}`

## Issue Link
{issue_url}
```

## Phase 4: Delegate to Implementation Workflow

**Select workflow based on task type:**

| Workflow     | Use When                         | Command         |
| ------------ | -------------------------------- | --------------- |
| **TDD**      | Features, bugs with testable ACs | `/gh-tdd`       |
| **Spike**    | Exploration, proving concepts    | `/spike`        |
| **Hotfix**   | Critical production fixes        | `/hotfix`       |
| **Standard** | Simple changes                   | Continue inline |

**Handoff message:**
"Task #{number} set up on branch `feature/{number}-{desc}`.
Context saved to `.current-task.md`.

Acceptance Criteria:

1. {AC1}
2. {AC2}
3. {AC3}

Use `/gh-tdd` to begin TDD implementation, or tell me which approach you'd like."

**Wait for implementation workflow to complete.**

## Phase 5: Create Pull Request (After Implementation)

When implementation is complete (all ACs satisfied):

1. **Push branch:**

   ```bash
   git push -u origin {branch_name}
   ```

2. **Create PR:**

   ```bash
   gh pr create \
     --repo {owner}/{repo} \
     --title "{type}: {description} (#{issue_number})" \
     --body "{pr_body}" \
     --base main
   ```

**PR body template:**

```markdown
## Summary
{Brief description of changes}

## Closes #{issue_number}

## Changes Made
- {change_1}
- {change_2}

## Acceptance Criteria Verification
- [x] AC1: {description} - Verified by {test/manual}
- [x] AC2: {description} - Verified by {test/manual}

## Testing
- [x] Unit tests added/updated
- [x] All tests pass
```

## Phase 6: Update Issue

```bash
gh issue comment {issue_number} --repo {repo} --body "
## Implementation Complete

PR: #{pr_number}

### Acceptance Criteria
- [x] AC1: {description}
- [x] AC2: {description}

### Ready for Review
"
```

## Phase 7: Update Local Tracker

If `.github-workflow-tracker.md` exists:

- Update task status to "In Review"
- Add PR link
- Add session log entry
</workflow>

<rules>
- Always verify dependencies are closed before starting
- Create .current-task.md before delegating to implementation workflow
- Do not create PR until human confirms all ACs are satisfied
- Use conventional commit format in PR titles (feat:, fix:, refactor:, etc.)
</rules>

<implementation_workflow_contract>
The execution agent provides:

- `.current-task.md` with ACs and context
- Feature branch already checked out
- Human guidance on which AC to tackle

Implementation workflow (TDD, etc.) provides:

- Commits following its methodology
- Passing tests for each AC
- Clean, refactored code
- Completion signal when all ACs satisfied
</implementation_workflow_contract>
