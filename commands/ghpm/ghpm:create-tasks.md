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
- Optional: `GHPM_PROJECT` environment variable set for project association
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
- Generate 1-25 tasks per Epic (best effort) that fully cover the Epic scope.
- Each Task MUST include a **Commit Type** (`feat`, `fix`, `refactor`, etc.) and **Scope** for conventional commits.
</operating_rules>

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

```markdown
# Task: <Name>

## Context
- Epic: #<EPIC_NUMBER>
- PRD: #<PRD_NUMBER> (if known)
- Commit Type: `<type>` (feat|fix|refactor|test|docs|chore)
- Scope: `<scope>` (module/component affected)

## Objective

## Scope (In)

## Out of Scope

## Acceptance Criteria (task-level, testable)

## Implementation Notes (non-binding)

## Test Plan

## Risks / Edge Cases

## Notes / Open Questions
```

### Commit Type Guidelines

The **Commit Type** field determines the conventional commit prefix used during implementation:

| Type | Use When |
|------|----------|
| `feat` | Adding new functionality, features, or capabilities |
| `fix` | Fixing bugs, errors, or incorrect behavior |
| `refactor` | Restructuring code without changing behavior |
| `test` | Adding or improving tests only |
| `docs` | Documentation changes only |
| `chore` | Build, CI, dependencies, or tooling changes |

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

# Else if prd=#N provided, find Epics referencing the PRD
gh issue list -l Epic -S "#$PRD" -s open --json number,title -q '.[] | [.number,.title] | @tsv'

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

For each Epic, generate 5-25 atomic tasks that fully cover the Epic scope.

Create each task:

```bash
gh issue create \
  --title "Task: <Name>" \
  --label "Task" \
  --body "<Task markdown from template>"
```

If `$GHPM_PROJECT` is set, include `--project "$GHPM_PROJECT"` (best-effort; continue if fails).

## Step 4: Link Tasks to Epic

Comment on the Epic with a checklist of created tasks:

```bash
gh issue comment "$EPIC" --body "$(cat <<'EOF'
## Tasks

- [ ] #<TASK_1> Task: <Name>
- [ ] #<TASK_2> Task: <Name>
...
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

**If project association fails:**

- Continue without project association
- Log warning in output summary
- Verify `$GHPM_PROJECT` value is correct
</error_handling>

<success_criteria>
Command completes successfully when:

1. All target Epics have been processed
2. Each Epic has 5-25 Task issues created
3. Each Task issue contains complete context (Epic/PRD links, acceptance criteria)
4. Each Epic has a comment with the task checklist
5. PRD is notified (if applicable)

**Verification:**

```bash
# List created tasks
gh issue list -l Task -s open --limit 50 --json number,title

# View Epic to confirm task checklist
gh issue view "$EPIC"
```

</success_criteria>

<output>
After completion, report:

1. **Epic(s) processed:** # and URL for each
2. **Tasks created:** Issue numbers and URLs
3. **Total tasks:** Count per Epic
4. **Project association:** Success/failure status (if `$GHPM_PROJECT` set)
5. **Warnings:** Any issues encountered (e.g., project add failed, PRD not found)
</output>

Proceed now.
