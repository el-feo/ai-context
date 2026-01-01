---
description: Execute a Task or Epic, routing to TDD or non-TDD workflow based on commit type.
allowed-tools: [Read, Edit, Write, Bash, Grep, Glob, SlashCommand, Skill(ruby), Skill(javascript), Skill(rspec), Skill(javascript-unit-testing), Skill(rubycritic), Skill(simplecov)]
arguments:
  task:
    description: "Task issue number (format: task=#123)"
    required: false
  epic:
    description: "Epic issue number to execute all tasks (format: epic=#123)"
    required: false
---

<objective>
Execute a GitHub Task (or all Tasks under an Epic) by routing to the appropriate workflow:

- **TDD workflow** (`/ghpm:tdd-task`): For `feat`, `fix`, `refactor` commit types
- **Non-TDD workflow**: For `test`, `docs`, `chore`, `style`, `perf` commit types

Both workflows produce identical outputs: conventional commits, Task Report, and a PR that closes the Task.
</objective>

<arguments>
**Optional arguments:**
- `task=#123` - Specific task issue number
- `epic=#123` - Epic issue number (executes all open tasks under the epic)

**Resolution order if omitted:**

1. If branch name matches `ghpm/task-<N>-*` or `task-<N>-*`, use N
2. Most recent open issue labeled `Task` assigned to @me:
   `gh issue list -l Task -a @me -s open --limit 1 --json number -q '.[0].number'`
3. Most recent open Task:
   `gh issue list -l Task -s open --limit 1 --json number -q '.[0].number'`
</arguments>

<usage_examples>
**Execute a single task (auto-routes based on commit type):**

```bash
/ghpm:execute task=#42
```

**Execute all tasks under an epic:**

```bash
/ghpm:execute epic=#10
```

**Auto-resolve from branch or GitHub:**

```bash
/ghpm:execute
```

</usage_examples>

<operating_rules>

- Always create a feature branch before making changes. Never commit directly to main/master.
- No local markdown artifacts. Do not write local status files; only code changes + GitHub issue/PR updates.
- Do NOT use the TodoWrite tool to track tasks during this session.
- Do not silently expand scope. If needed, create a new follow-up Task issue and link it.
- All commits and PR titles MUST follow Conventional Commits format for changelog generation.
- When routing to TDD, delegate fully to `/ghpm:tdd-task` - do not duplicate its workflow.
- When handling an Epic, process tasks sequentially (one PR per task, not batched).
  - **Exception:** If multiple tasks modify the same file(s), batch them into a single PR with separate commits per task. Each commit must reference its task number.
- Minimize noise: comment at meaningful milestones.
</operating_rules>

<routing_logic>

## Determining Workflow Type

Read the Task issue body and extract the **Commit Type** field:

```
- Commit Type: `<type>`
```

### Step 1: Check for Non-TDD Patterns (Override)

Before applying commit-type routing, check if the task matches these Non-TDD patterns:

**Auto-route to Non-TDD if:**

- Target files are non-code: `*.md`, `*.yml`, `*.yaml`, `*.json`, `*.toml`, `*.txt`
- Task creates/modifies slash commands: path matches `commands/**/*.md` or `.claude/commands/**/*.md`
- Task creates/modifies skills: path matches `skills/**/*.md` or `.claude/skills/**/*.md`
- Task title contains: "Create ... command", "Add ... slash command", "Update ... documentation"
- Scope indicates non-code: `docs`, `commands`, `skills`, `config`

These patterns indicate work where TDD is not applicable (tests cannot be written for markdown/config files).

### Step 2: Apply Commit-Type Routing

If no Non-TDD pattern matched, route based on commit type:

**Route to TDD workflow (`/ghpm:tdd-task`):**

- `feat` - New features benefit from test-first development (when targeting code files)
- `fix` - Bug fixes need tests to verify the fix
- `refactor` - Refactoring requires tests to ensure behavior is preserved

**Route to Non-TDD workflow (execute directly):**

- `test` - Adding tests doesn't need TDD (you're already writing tests)
- `docs` - Documentation changes don't need tests
- `chore` - Build/CI/tooling changes typically don't need unit tests
- `style` - Formatting changes don't need tests
- `perf` - Performance changes may have benchmarks, not TDD cycles

**If Commit Type is missing or unclear:**

- Analyze the Task title and objective
- Check target file extensions to determine if code or non-code
- Default to TDD workflow for code changes (`.rb`, `.js`, `.ts`, `.py`, `.go`, etc.)
- Default to Non-TDD for non-code changes (`.md`, `.yml`, `.json`, etc.)

</routing_logic>

<conventional_commits>

## Conventional Commits Format

All commits and PR titles must follow the [Conventional Commits](https://www.conventionalcommits.org/) specification.

### Format

```
<type>[optional scope]: <description> (#<issue>)
```

### Commit Types

| Type       | Description                                | Changelog Section |
| ---------- | ------------------------------------------ | ----------------- |
| `feat`     | New feature or capability                  | Features          |
| `fix`      | Bug fix                                    | Bug Fixes         |
| `refactor` | Code restructuring without behavior change | Code Refactoring  |
| `perf`     | Performance improvement                    | Performance       |
| `test`     | Adding or updating tests                   | Testing           |
| `docs`     | Documentation only changes                 | Documentation     |
| `style`    | Formatting, whitespace (no code change)    | (excluded)        |
| `chore`    | Build, CI, dependencies, tooling           | Maintenance       |

</conventional_commits>

<workflow>

## Step 0: Resolve Target Task(s)

### If `epic=#N` provided

```bash
EPIC=$N

# Get repository owner and name
OWNER=$(gh repo view --json owner -q '.owner.login')
REPO=$(gh repo view --json name -q '.name')

# Fetch all open sub-issues (Tasks) under this Epic using GraphQL API
# GitHub sub-issues are linked via parent-child relationship, NOT by text mention
# NOTE: Use heredoc to avoid shell escaping issues with '!' characters
cat > /tmp/ghpm-subissues.graphql << 'GRAPHQL'
query($owner: String!, $repo: String!, $number: Int!) {
  repository(owner: $owner, name: $repo) {
    issue(number: $number) {
      subIssues(first: 50) {
        nodes {
          number
          title
          state
          labels(first: 10) {
            nodes { name }
          }
        }
      }
    }
  }
}
GRAPHQL

gh api graphql -F owner="$OWNER" -F repo="$REPO" -F number=$EPIC \
  -f query="$(cat /tmp/ghpm-subissues.graphql)" \
  --jq '.data.repository.issue.subIssues.nodes[] | select(.state == "OPEN") | select(.labels.nodes[].name == "Task") | [.number, .title] | @tsv'
```

## Step 0.5: Analyze Task Dependencies (Epic Mode Only)

Before processing tasks, analyze all task bodies to detect interdependencies:

1. **Fetch all task bodies** for the Epic
2. **Extract target file paths** from each task (look for file paths in Implementation Notes, Scope, or infer from task title/objective)
3. **Group tasks by target file** - if multiple tasks modify the same file, they are interdependent
4. **Determine execution strategy:**

| Scenario | Strategy |
|----------|----------|
| All tasks target different files | Process sequentially, one PR per task |
| Multiple tasks target same file | Batch into single PR with separate commits |
| Tasks have explicit dependencies | Process in dependency order |

**For batched tasks:**
- Create a single branch named after the first task: `ghpm/task-$FIRST_TASK-<epic-slug>`
- Make separate commits per task, each referencing its task number
- Create single PR that closes all batched tasks
- Comment PR URL on all batched task issues

Process tasks using Steps 1-6, applying batching strategy where applicable.

### If `task=#N` provided

```bash
TASK=$N
```

### If no argument provided

```bash
# 1. Try branch name
BRANCH=$(git rev-parse --abbrev-ref HEAD)
# Extract task number from ghpm/task-<N>-* or task-<N>-*

# 2. Most recent assigned Task
TASK=$(gh issue list -l Task -a @me -s open --limit 1 --json number -q '.[0].number')

# 3. Most recent open Task
TASK=$(gh issue list -l Task -s open --limit 1 --json number -q '.[0].number')
```

## Step 0.9: Validate Task Status

Before proceeding with any task, check if it's already closed or marked as done:

```bash
# Fetch issue state and labels
ISSUE_DATA=$(gh issue view "$TASK" --json state,labels,projectItems -q '.')
STATE=$(echo "$ISSUE_DATA" | jq -r '.state')

# Check if issue is closed
if [ "$STATE" = "CLOSED" ]; then
  echo "Task #$TASK is already CLOSED. Skipping."
  # If processing an Epic, continue to next task; otherwise exit
  exit 0  # or continue to next task in Epic mode
fi

# Check for "Done" label
DONE_LABEL=$(echo "$ISSUE_DATA" | jq -r '.labels[]?.name | select(. == "Done" or . == "done" or . == "DONE")')
if [ -n "$DONE_LABEL" ]; then
  echo "Task #$TASK has 'Done' label. Skipping."
  exit 0
fi

# Check project status field (if linked to a project)
PROJECT_STATUS=$(echo "$ISSUE_DATA" | jq -r '.projectItems[]?.status?.name // empty')
if [ "$PROJECT_STATUS" = "Done" ] || [ "$PROJECT_STATUS" = "Completed" ]; then
  echo "Task #$TASK has project status '$PROJECT_STATUS'. Skipping."
  exit 0
fi
```

**Behavior:**
- If task is CLOSED → skip and report "Task #N is already closed"
- If task has "Done" label → skip and report "Task #N is marked as done"
- If task's project status is "Done" or "Completed" → skip and report status
- For Epic mode: continue to next task after skipping
- For single task mode: exit with informational message

## Step 1: Hydrate Context and Determine Routing

```bash
# Fetch issue details
gh issue view "$TASK" --json title,body,url,labels,comments -q '.'
```

**Extract from issue:**

- Commit Type (from body: `Commit Type: \`<type>\``)
- Scope (from body: `Scope: \`<scope>\``)
- Target file paths (from Implementation Notes or infer from task)
- Acceptance criteria
- Test plan (or infer if missing)
- Epic/PRD links

**Determine workflow (see <routing_logic> for details):**

```
1. Check Non-TDD Patterns (Override):
   If target files are non-code (*.md, *.yml, *.json, etc.):
       → Route to Non-TDD workflow (Step 2B)
   If task creates slash commands or skills:
       → Route to Non-TDD workflow (Step 2B)

2. Apply Commit-Type Routing:
   If Commit Type in [feat, fix, refactor] AND targeting code files:
       → Route to TDD workflow (Step 2A)
   Else if Commit Type in [test, docs, chore, style, perf]:
       → Route to Non-TDD workflow (Step 2B)
   Else:
       → Analyze task content and make best judgment
```

## Step 2A: TDD Workflow (Delegate)

For `feat`, `fix`, `refactor` tasks, delegate to the TDD command:

```bash
/ghpm:tdd-task task=#$TASK
```

The TDD command handles all subsequent steps. Proceed to next task if processing an Epic.

## Step 2B: Non-TDD Workflow (Execute Directly)

For `test`, `docs`, `chore`, `style`, `perf` tasks, execute directly.

### Step 2B.1: Post Implementation Plan

Comment on the Task with your implementation plan:

```markdown
## Implementation Plan

- **Objective:** <from task>
- **Commit Type:** `<type>`
- **Scope:** `<scope>`
- **What will be changed:**
- **Verification approach:** (manual verification, existing tests, linting, etc.)
- **Milestones:**
```

Execute:

```bash
gh issue comment "$TASK" --body "<markdown>"
```

### Step 2B.2: Create Working Branch

```bash
git checkout -b "ghpm/task-$TASK-<short-slug>"
```

Comment branch name to the issue.

### Step 2B.3: Execute the Work

For each milestone:

1. Make the changes
2. Verify the changes work (run existing tests, manual verification, linting)
3. Commit using conventional commit format:

   ```
   <type>(<scope>): <description> (#$TASK)
   ```

**Commit patterns by type:**

- `test`: `test(<scope>): add tests for <behavior> (#$TASK)`
- `docs`: `docs(<scope>): update documentation for <topic> (#$TASK)`
- `chore`: `chore(<scope>): update <tooling/config> (#$TASK)`
- `style`: `style(<scope>): format <files/code> (#$TASK)`
- `perf`: `perf(<scope>): optimize <operation> (#$TASK)`

After meaningful progress, comment on the Task with:

- What changed
- Verification performed
- Commit hash(es) made
- Any decisions/rationale

### Step 2B.4: Update Task Report

Edit the issue body to append:

```markdown
## Task Report (auto)

### Implementation summary

### Files changed

### How to validate

### Verification performed

### Decision log

### Follow-ups (if any)
```

Execute:

```bash
gh issue edit "$TASK" --body "<updated markdown>"
```

### Step 2B.5: Open PR

Push branch and create PR:

```bash
git push -u origin HEAD

gh pr create --title "<type>(<scope>): <description> (#$TASK)" --body "$(cat <<'EOF'
Closes #$TASK

## Summary

- ...

## Verification

- <what was verified and how>

## Commits

<list of conventional commits made>
EOF
)"
```

Comment the PR URL back onto the Task:

```bash
gh issue comment "$TASK" --body "PR created: <PR_URL>"
```

## Step 3: Process Next Task (Epic Mode)

If processing an Epic, move to the next task and repeat from Step 1.

After all tasks are complete, comment on the Epic:

```bash
gh issue comment "$EPIC" --body "$(cat <<'EOF'
## Execution Complete

All tasks have been executed. PRs created:

- #<TASK_1>: <PR_URL_1>
- #<TASK_2>: <PR_URL_2>
...
EOF
)"
```

</workflow>

<success_criteria>
Command completes when:

**For single task:**

- Task is executed (via TDD or Non-TDD workflow)
- Task Report section is updated in the issue body
- PR is created with `Closes #$TASK` in the body
- PR URL is commented back to the Task

**For epic (independent tasks):**

- All open tasks under the Epic are processed
- Each task has its own PR
- Summary comment posted on Epic with all PR URLs

**For epic (interdependent tasks - same target file):**

- All interdependent tasks batched into single PR
- Each task has its own commit referencing its task number
- PR closes all batched tasks (`Closes #T1, Closes #T2, ...`)
- PR URL commented on all batched task issues
- Summary comment on Epic shows task-to-PR mapping
</success_criteria>

<error_handling>
**If Commit Type cannot be determined:**

- Check target file extensions first (Non-TDD patterns take priority)
- Analyze task title and objective
- Look for keywords: "add", "implement", "create" → TDD (if code); "update docs", "fix CI" → Non-TDD
- Default to TDD for code files, Non-TDD for non-code files

**If target files cannot be determined:**

- Check task scope field for hints (`ghpm`, `commands`, `docs` → Non-TDD)
- Look for file paths in Implementation Notes section
- Ask in task comment if truly ambiguous (rare - most tasks indicate target)

**If task is already in progress (branch exists):**

- Check out existing branch instead of creating new
- Continue from where left off

**If delegation to /ghpm:tdd-task fails:**

- Fall back to executing TDD workflow directly
- Comment error details on Task issue

**If verification fails (tests fail, lint errors):**

- Do not proceed to PR
- Comment on issue with failure details
- Debug and fix before continuing
</error_handling>

<output>
After completion, report:

1. **Tasks executed:** Issue numbers and workflow type used
2. **PRs created:** PR numbers and URLs (note batched tasks if applicable)
3. **Routing decisions:** For each task, explain:
   - Commit type detected
   - Target file type (code vs non-code)
   - Pattern matched (if Non-TDD override applied)
   - Final workflow chosen and why
4. **Batching decisions:** If tasks were batched, explain why (shared target files)
5. **Warnings:** Any issues encountered
</output>

Proceed now.
