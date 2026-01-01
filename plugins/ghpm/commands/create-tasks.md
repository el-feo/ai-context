---
description: Break an Epic (or all Epics under a PRD) into atomic Task issues and link them back.
allowed-tools: [Read, Bash, Grep, Glob]
arguments:
  epic:
    description: "Epic issue number (format: epic=#123)"
    required: false
  prd:
    description: "PRD issue number to generate tasks for all linked Epics (format: prd=#123)"
    required: false
---

<objective>
You are GHPM (GitHub Project Manager). Convert an Epic into a set of atomic Task issues (single unit of work) using `gh`. Each task is independently executable and includes all necessary context.
</objective>

<prerequisites>
- `gh` CLI installed and authenticated (`gh auth status`)
- Working directory is a git repository with GitHub remote
- Target Epic or PRD issue exists and is accessible
- Optional: `GHPM_PROJECT` environment variable set to project number (e.g., `export GHPM_PROJECT=7`)
- Optional: GitHub Project has an "Estimate" field (Number type) for task sizing
</prerequisites>

<arguments>
**Optional arguments:**
- `epic=#123` - Specific Epic issue number (preferred)
- `prd=#123` - PRD issue number (generates tasks for all linked Epics)

**Resolution order if omitted:**

1. Most recent open Epic issue:
   `gh issue list -l Epic -s open --limit 1 --json number -q '.[0].number'`
</arguments>

<usage_examples>
**With epic number:**

```bash
/ghpm:create-tasks epic=#42
```

**With PRD number (creates tasks for all linked Epics):**

```bash
/ghpm:create-tasks prd=#10
```

**Auto-resolve most recent Epic:**

```bash
/ghpm:create-tasks
```

</usage_examples>

<operating_rules>

- Do not ask clarifying questions. Make assumptions and record them.
- Do not create local markdown files. All output goes into GitHub issues/comments.
- Tasks must be atomic and independently executable by a human or agent.
- Each Task must include all context needed for its scope (plus links to Epic/PRD).
- Each Task MUST include a **Commit Type** (`feat`, `fix`, `refactor`, etc.) and **Scope** for conventional commits.
- **Task count must be proportional to Epic scope** - see guidance below.
- **Each Task MUST have a Fibonacci estimate** (1, 2, 3, 5, or 8) - see estimation guidance below.
</operating_rules>

<estimation_guidance>

## Fibonacci Estimation Scale

Assign a Fibonacci estimate to each Task based on relative complexity. Estimates reflect effort/complexity, not hours.

| Estimate | Complexity   | Examples                                                         |
| -------- | ------------ | ---------------------------------------------------------------- |
| **1**    | Trivial      | Update README, fix typo, change config value                     |
| **2**    | Simple       | Add a single test, update documentation section, simple refactor |
| **3**    | Moderate     | Add simple feature, refactor small module, add validation        |
| **5**    | Complex      | Multi-file feature, significant refactor, new API endpoint       |
| **8**    | Very Complex | Cross-cutting feature, complex integration, architectural change |

### Decomposition Rule

**Tasks estimated >8 MUST be decomposed.** If a task would be estimated higher than 8:

1. Do NOT create the task as-is
2. Break it into smaller, independent tasks
3. Each sub-task should be estimable at 8 or below
4. Re-analyze scope to find natural boundaries

### Estimation Heuristics

- **File count**: 1 file = 1-2, 2-3 files = 3, 4+ files = 5-8
- **Test requirements**: No tests = lower, comprehensive tests = higher
- **Dependencies**: Self-contained = lower, cross-cutting = higher
- **Unknowns**: Clear requirements = lower, exploration needed = higher

</estimation_guidance>

<task_count_guidance>

## Determining Appropriate Task Count

**Match task count to Epic complexity, not a fixed range.** Over-decomposition creates overhead without value.

### Heuristics

| Epic Scope                    | Task Count | Example                                          |
| ----------------------------- | ---------- | ------------------------------------------------ |
| Single file, simple change    | 1 task     | Update README, fix typo, change config           |
| Single file, multiple changes | 1-2 tasks  | Refactor a module, update docs with verification |
| Multiple related files        | 2-4 tasks  | Add feature touching model + controller + view   |
| Cross-cutting feature         | 4-8 tasks  | New API endpoint with auth, tests, docs          |
| Large architectural change    | 8-15 tasks | Database migration, new service layer            |

### Signs of Over-Decomposition

- Tasks that would result in the same commit
- Tasks that can't be meaningfully verified independently
- "Verify X" as a separate task from "Update X"
- Multiple tasks touching the same file for related changes

### Signs of Under-Decomposition

- Task requires multiple unrelated commits
- Task touches many files across different concerns
- Task has acceptance criteria spanning multiple features

### Rule of Thumb

**If an Epic affects 1-2 files with a clear scope, 1-2 tasks is usually sufficient.**

</task_count_guidance>

<input_validation>

## Validation Checks

Before proceeding, validate:

```bash
# 1. Check gh CLI authentication
gh auth status || { echo "ERROR: Not authenticated. Run 'gh auth login'"; exit 1; }

# 2. Validate issue number format (if provided)
# Epic and PRD numbers must be positive integers

# 3. Verify issue exists and is accessible
gh issue view "$EPIC" > /dev/null 2>&1 || { echo "ERROR: Cannot access issue #$EPIC"; exit 1; }
```

</input_validation>

<task_issue_format>

## Task Issue Body Template

Use this streamlined template. Tasks link to Epic only (PRD reachable via Epic).

```markdown
# Task: <Name>

**Epic:** #<EPIC_NUMBER> | **Type:** `<type>` | **Scope:** `<scope>`

## Objective
<1-2 sentences: what to implement>

## Acceptance Criteria
- [ ] Criterion 1
- [ ] Criterion 2
- [ ] ...

## Test Plan
<How to verify completion - manual steps, test commands, or verification approach>
```

### Template Guidance

- **Context line**: Single line with Epic link, commit type, and scope (no PRD link - navigate via Epic)
- **Objective**: Concise statement merging previous "Objective" and "Scope (In)" sections
- **Acceptance Criteria**: Task-level, testable criteria
- **Test Plan**: How to verify the task is complete

**Omit these sections** (redundant or rarely populated):

- PRD link (reachable via Epic)
- Scope (In) (merge into Objective)
- Out of Scope (inherit from Epic)
- Implementation Notes (use comments if needed)
- Risks / Edge Cases (inherit from Epic/PRD)
- Notes / Open Questions (use issue comments instead)

### Commit Type Guidelines

The **Commit Type** field determines the conventional commit prefix used during implementation:

| Type       | Use When                                            |
| ---------- | --------------------------------------------------- |
| `feat`     | Adding new functionality, features, or capabilities |
| `fix`      | Fixing bugs, errors, or incorrect behavior          |
| `refactor` | Restructuring code without changing behavior        |
| `test`     | Adding or improving tests only                      |
| `docs`     | Documentation changes only                          |
| `chore`    | Build, CI, dependencies, or tooling changes         |

**How to determine:**

1. Task creates new user-facing behavior → `feat`
2. Task fixes reported issue/bug → `fix`
3. Task improves code quality without behavior change → `refactor`
4. Task adds/updates tests without implementation → `test`
5. Task updates documentation → `docs`
6. Task updates build/CI/tooling → `chore`

</task_issue_format>

<workflow>

## Step 1: Resolve Target Epic(s)

```bash
# If epic=#N provided, use N
EPIC={provided_epic_number}

# Else if prd=#N provided, find Epics as sub-issues of the PRD
# NOTE: Use heredoc to avoid shell escaping issues with '!' characters
OWNER=$(gh repo view --json owner -q '.owner.login')
REPO=$(gh repo view --json name -q '.name')

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

gh api graphql -F owner="$OWNER" -F repo="$REPO" -F number=$PRD \
  -f query="$(cat /tmp/ghpm-subissues.graphql)" \
  --jq '.data.repository.issue.subIssues.nodes[] | select(.state == "OPEN") | select(.labels.nodes[].name == "Epic") | [.number, .title] | @tsv'

# Else pick most recent open Epic
gh issue list -l Epic -s open --limit 1 --json number -q '.[0].number'
```

## Step 2: Fetch Epic Context

For each Epic:

```bash
# Fetch Epic body and metadata
gh issue view "$EPIC" --json title,body,url,labels -q '.'
```

**Extract from Epic:**

- Objective and scope
- PRD reference (look for `PRD: #123` or similar pattern)
- Acceptance criteria to decompose

## Step 3: Generate Task Issues

For each Epic, generate the appropriate number of atomic tasks based on the task count guidance above.

Create each task:

```bash
# Create the task issue
TASK_URL=$(gh issue create \
  --title "Task: <Name>" \
  --label "Task" \
  --body "<Task markdown from template>")

# Extract task number from URL
TASK_NUM=$(echo "$TASK_URL" | grep -oE '[0-9]+$')

# Set the estimate value determined during task planning (1, 2, 3, 5, or 8)
ESTIMATE=<fibonacci_number>  # Replace with actual estimate, e.g., ESTIMATE=3
```

If `$GHPM_PROJECT` is set (project number), add the task to the project and set the Estimate field:

```bash
# Add task to project and set estimate (if GHPM_PROJECT is set)
if [ -n "$GHPM_PROJECT" ]; then
  # Add to project (GHPM_PROJECT should be the project number, e.g., "7")
  ITEM_ID=$(gh project item-add "$GHPM_PROJECT" --owner "$OWNER" --url "$TASK_URL" --format json 2>/dev/null | jq -r '.id')

  if [ -n "$ITEM_ID" ] && [ "$ITEM_ID" != "null" ]; then
    # Get project ID and Estimate field ID
    PROJECT_DATA=$(gh project view "$GHPM_PROJECT" --owner "$OWNER" --format json 2>/dev/null)
    PROJECT_ID=$(echo "$PROJECT_DATA" | jq -r '.id')
    ESTIMATE_FIELD_ID=$(gh project field-list "$GHPM_PROJECT" --owner "$OWNER" --format json 2>/dev/null | jq -r '.fields[] | select(.name == "Estimate") | .id')

    if [ -n "$ESTIMATE_FIELD_ID" ] && [ "$ESTIMATE_FIELD_ID" != "null" ]; then
      # Set estimate value (ESTIMATE is the Fibonacci number assigned to this task)
      gh project item-edit --project-id "$PROJECT_ID" --id "$ITEM_ID" --field-id "$ESTIMATE_FIELD_ID" --number "$ESTIMATE" 2>/dev/null \
        && echo "✓ Set estimate $ESTIMATE for Task #$TASK_NUM" \
        || echo "WARNING: Could not set estimate for Task #$TASK_NUM"
    else
      echo "WARNING: Estimate field not found in project. Add a Number field named 'Estimate'."
    fi
  else
    echo "WARNING: Could not add Task #$TASK_NUM to project '$GHPM_PROJECT'"
  fi
fi
```

## Step 4: Link Tasks as Sub-Issues of Epic

**IMPORTANT:** Tasks MUST be linked as sub-issues of the Epic, not just listed in a comment.

For each created task, link it as a sub-issue:

```bash
# Get the Epic's internal issue ID
EPIC_ID=$(gh api repos/{owner}/{repo}/issues/$EPIC --jq .id)

# Get the Task's internal issue ID
TASK_ID=$(gh api repos/{owner}/{repo}/issues/$TASK_NUM --jq .id)

# Add task as sub-issue of Epic
gh api repos/{owner}/{repo}/issues/$EPIC/sub_issues \
  -X POST \
  -F sub_issue_id=$TASK_ID \
  --silent || echo "Warning: Could not link Task #$TASK_NUM as sub-issue"
```

After all tasks are created and linked, optionally comment on the Epic with a summary:

```bash
gh issue comment "$EPIC" --body "$(cat <<'EOF'
## Tasks Created

Created and linked as sub-issues:

- #<TASK_1> Task: <Name>
- #<TASK_2> Task: <Name>
...

View sub-issues in the Epic's "Sub-issues" section.
EOF
)"
```

## Step 5: Update PRD (if known)

If PRD is known, comment on the PRD (one comment per Epic, avoid spam):

```bash
gh issue comment "$PRD" --body "Tasks created for Epic #$EPIC - see checklist on the Epic."
```

</workflow>

<error_handling>
**If gh CLI not authenticated:**

- Check: `gh auth status`
- Fix: `gh auth login`

**If Epic/PRD not found:**

- Verify issue number is correct
- Check repository access permissions
- Confirm issue is not closed/deleted

**If issue creation fails:**

- Check rate limits: `gh api rate_limit`
- Verify label "Task" exists or omit label
- Check repository write permissions

**If sub-issue linking fails:**

- Continue with next task (don't block on linking failures)
- Log warning in output summary with specific task number
- Common causes: task already has a parent, duplicate sub-issue, API error
- Verify with: `gh api repos/{owner}/{repo}/issues/$EPIC/sub_issues`

**If project association fails:**

- Continue without project association
- Log warning in output summary
- Verify `$GHPM_PROJECT` value is correct

**If Estimate field is missing from project:**

- Log warning: "Estimate field not found in project. Add a Number field named 'Estimate'."
- Continue without setting estimate
- Tasks are still created and linked correctly
- Provide setup instructions in warning

**If task would exceed estimate of 8:**

- Do NOT create the task
- Log: "Task scope too large (would be >8). Decomposing into smaller tasks."
- Break task into smaller units (each ≤8)
- Create the smaller tasks instead
</error_handling>

<success_criteria>
Command completes successfully when:

1. All target Epics have been processed
2. Each Epic has an appropriate number of Task issues (per task count guidance)
3. Each Task issue contains required sections: Context line (Epic, Type, Scope), Objective, Acceptance Criteria, Test Plan
4. Each Task has a Fibonacci estimate (1, 2, 3, 5, or 8) - no task exceeds 8
5. Each Task is linked as a sub-issue of its Epic
6. If `GHPM_PROJECT` set, Estimate field is populated (or warning issued if field missing)
7. PRD is notified (if applicable)
8. Optional sections omitted when not populated with meaningful content

**Verification:**

```bash
# List created tasks
gh issue list -l Task -s open --limit 50 --json number,title

# Verify sub-issues are linked to Epic
gh api repos/{owner}/{repo}/issues/$EPIC/sub_issues --jq '.[] | [.number, .title] | @tsv'

# View Epic to confirm (sub-issues appear in issue view)
gh issue view "$EPIC"
```

</success_criteria>

<output>
After completion, report:

1. **Epic(s) processed:** # and URL for each
2. **Tasks created:** Issue numbers, URLs, and estimates

   | Task | Title      | Estimate |
   | ---- | ---------- | -------- |
   | #N   | Task: Name | 3        |

3. **Sub-issue linking:** Success/failure for each task linked to Epic
4. **Total tasks:** Count per Epic, total estimate points
5. **Project association:** Success/failure status (if `$GHPM_PROJECT` set)
6. **Estimate field:** Success/failure for setting estimates (if `$GHPM_PROJECT` set)
7. **Warnings:** Any issues encountered (e.g., sub-issue linking failed, project add failed, Estimate field missing)
</output>

Proceed now.
