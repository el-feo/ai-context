---
description: Execute a Task using a TDD loop; record decisions/progress on the issue; open a PR that closes the Task.
allowed-tools: [Read, Edit, Write, Bash, Grep, Glob, Skill(ruby), Skill(javascript), Skill(rspec), Skill(javascript-unit-testing), Skill(rubycritic), Skill(simplecov)]
---

<objective>
Implement a GitHub Task issue using disciplined TDD (Red -> Green -> Refactor), recording all decisions and progress on the GitHub issue, then opening a PR that closes the Task. All commits and PRs follow Conventional Commits format to enable automated changelog generation.
</objective>

<arguments>
**Optional arguments:**
- `task=#123` - Specific task issue number
- `focus=unit|integration|e2e` - Best-effort hint for test focus

**Resolution order if omitted:**

1. If branch name matches `ghpm/task-<N>-*` or `task-<N>-*`, use N
2. Most recent open issue labeled `Task` assigned to @me:
   `gh issue list -l Task -a @me -s open --limit 1 --json number -q '.[0].number'`
3. Most recent open Task:
   `gh issue list -l Task -s open --limit 1 --json number -q '.[0].number'`
</arguments>

<usage_examples>
**With task number:**

```bash
/ghpm:tdd-task task=#42
```

**With focus hint:**

```bash
/ghpm:tdd-task task=#42 focus=unit
```

**Auto-resolve from branch:**

```bash
# On branch: ghpm/task-42-add-auth
/ghpm:tdd-task
```

**Auto-resolve from GitHub:**

```bash
# No arguments - uses most recent assigned Task
/ghpm:tdd-task
```

</usage_examples>

<operating_rules>

- Always create a feature branch before making changes. Never commit directly to main/master.
- No local markdown artifacts. Do not write local status files; only code changes + GitHub issue/PR updates.
- Do NOT use the TodoWrite tool to track tasks during this session.
- Do not silently expand scope. If you must, create a new follow-up Task issue and link it.
- Always provide a runnable test command in the final notes.
- Minimize noise: comment at meaningful milestones.
- All commits and PR titles MUST follow Conventional Commits format for changelog generation.
</operating_rules>

<conventional_commits>

## Conventional Commits Format

All commits and PR titles must follow the [Conventional Commits](https://www.conventionalcommits.org/) specification to enable automated changelog generation.

### Format

```
<type>[optional scope]: <description> (#<issue>)

[optional body]

[optional footer(s)]
```

### Commit Types

| Type | Description | Changelog Section |
|------|-------------|-------------------|
| `feat` | New feature or capability | Features |
| `fix` | Bug fix | Bug Fixes |
| `refactor` | Code restructuring without behavior change | Code Refactoring |
| `perf` | Performance improvement | Performance |
| `test` | Adding or updating tests | Testing |
| `docs` | Documentation only changes | Documentation |
| `style` | Formatting, whitespace (no code change) | (excluded) |
| `chore` | Build, CI, dependencies, tooling | Maintenance |
| `revert` | Revert a previous commit | Reverts |

### Determining Commit Type

Infer the type from the Task context:

1. **Task labels**: `enhancement` → `feat`, `bug` → `fix`
2. **Task title keywords**: "add", "implement", "create" → `feat`; "fix", "resolve", "correct" → `fix`
3. **Epic context**: Feature epic → `feat`, Bug epic → `fix`, Tech debt epic → `refactor`
4. **Scope of change**: If primarily tests → `test`, if primarily docs → `docs`

### Breaking Changes

For breaking changes, add \`!\` after the type or include \`BREAKING CHANGE:\` in the footer:

```
feat!: remove deprecated API endpoint (#123)

BREAKING CHANGE: The /v1/users endpoint has been removed. Use /v2/users instead.
```

### Examples

**Feature commit:**
```
feat(auth): add OAuth2 login flow (#42)
```

**Bug fix commit:**
```
fix(payments): resolve null pointer in checkout (#103)
```

**Refactor commit:**
```
refactor(users): extract email service into separate module (#87)
```

**Test commit:**
```
test(api): add integration tests for user endpoints (#156)
```

### Commit Message During TDD Cycles

During Red-Green-Refactor cycles, commit at each meaningful milestone:

- **RED phase**: `test(<scope>): add failing test for <behavior> (#<task>)`
- **GREEN phase**: `feat(<scope>): implement <behavior> (#<task>)` or `fix(<scope>): ...`
- **REFACTOR phase**: `refactor(<scope>): <improvement description> (#<task>)`

</conventional_commits>

<workflow>

## Step 0: Hydrate context

Resolve the task number and fetch context:

```bash
# Resolve task number from arguments, branch, or auto-select
TASK={resolved_task_number}

# Fetch issue details
gh issue view "$TASK" --json title,body,url,labels,comments -q '.'
```

**Extract from issue:**

- Acceptance criteria
- Test plan (or infer if missing)
- Epic/PRD links

## Step 0.5: Validate Task Status

Before proceeding, check if the task is already closed or marked as done:

```bash
# Fetch issue state and labels
ISSUE_DATA=$(gh issue view "$TASK" --json state,labels,projectItems -q '.')
STATE=$(echo "$ISSUE_DATA" | jq -r '.state')

# Check if issue is closed
if [ "$STATE" = "CLOSED" ]; then
  echo "Task #$TASK is already CLOSED. Cannot proceed with TDD."
  exit 0
fi

# Check for "Done" label
DONE_LABEL=$(echo "$ISSUE_DATA" | jq -r '.labels[]?.name | select(. == "Done" or . == "done" or . == "DONE")')
if [ -n "$DONE_LABEL" ]; then
  echo "Task #$TASK has 'Done' label. Cannot proceed with TDD."
  exit 0
fi

# Check project status field (if linked to a project)
PROJECT_STATUS=$(echo "$ISSUE_DATA" | jq -r '.projectItems[]?.status?.name // empty')
if [ "$PROJECT_STATUS" = "Done" ] || [ "$PROJECT_STATUS" = "Completed" ]; then
  echo "Task #$TASK has project status '$PROJECT_STATUS'. Cannot proceed with TDD."
  exit 0
fi
```

**Behavior:**

- If task is CLOSED → exit with message "Task #N is already closed. Cannot proceed with TDD."
- If task has "Done" label → exit with message "Task #N is marked as done. Cannot proceed with TDD."
- If task's project status is "Done" or "Completed" → exit with status message

## Step 1: Post a TDD Plan comment

Comment on the Task with your implementation plan:

```markdown
## TDD Plan

- **Objective:**
- **Target behavior / acceptance criteria:**
- **Test strategy (focus level + what to cover):**
- **Proposed minimal design (non-binding):**
- **Commands (build/test/lint) you will run:**
- **Milestones (Red/Green/Refactor slices):**
```

Execute:

```bash
gh issue comment "$TASK" --body "<markdown>"
```

## Step 2: Create a working branch

```bash
git checkout -b "ghpm/task-$TASK-<short-slug>"
```

Comment branch name to the issue (same comment or a follow-up).

## Step 3: TDD execution loop

For each slice:

1. **RED:** Add failing test(s)
   - Commit: `test(<scope>): add failing test for <behavior> (#$TASK)`
2. **GREEN:** Implement minimum change to pass
   - Commit: `<type>(<scope>): <description> (#$TASK)` (typically `feat` or `fix`)
3. **REFACTOR:** Clean up while tests stay green
   - Commit: `refactor(<scope>): <description> (#$TASK)`
4. Run tests and capture command + result

**Commit after each phase** using conventional commit format. Determine the type from Task context (see `<conventional_commits>` section).

After each slice, comment on the Task with:

- What changed
- Tests added/updated
- Test command executed + result
- Commit hash(es) made
- Any decision/rationale

## Step 4: Update the Task body with a "Task Report" section

Edit the issue body to append:

```markdown
## Task Report (auto)

### Implementation summary

### Files changed

### How to validate locally

### Test command(s) and results

### Decision log

### Follow-ups (if any)
```

Execute:

```bash
gh issue edit "$TASK" --body "<updated markdown>"
```

## Step 5: Open a PR that closes the Task

Push branch and create PR using **Conventional Commits** format for the title:

```bash
git push -u origin HEAD

# Determine type from Task context (see <conventional_commits> section)
# Format: <type>(<scope>): <description> (#$TASK)

gh pr create --title "<type>(<scope>): <description> (#$TASK)" --body "$(cat <<'EOF'
Closes #$TASK

## Summary

- ...

## Test Plan

- `<test command>`

## Commits

<list of conventional commits made during TDD>
EOF
)"
```

**PR Title Examples:**

- `feat(auth): add OAuth2 login flow (#42)`
- `fix(payments): resolve checkout null pointer (#103)`
- `refactor(users): extract email service (#87)`

Comment the PR URL back onto the Task:

```bash
gh issue comment "$TASK" --body "PR created: <PR_URL>"
```

## Step 6: Final checkpoint

- Ensure all tests pass
- Ensure Task Report is updated in issue body
- Ensure PR references and closes the Task

</workflow>

<success_criteria>
Command completes when:

- All tests pass
- Task Report section is updated in the issue body
- PR is created with `Closes #$TASK` in the body
- PR URL is commented back to the Task
</success_criteria>

<error_handling>
**If tests fail during a cycle:**

- Do not proceed to refactor
- Comment on issue with failure details
- Debug and fix before continuing

**If PR creation fails:**

- Ensure branch is pushed
- Check repository permissions
- Verify issue number exists
- Comment failure details on Task issue
</error_handling>

Proceed now.
