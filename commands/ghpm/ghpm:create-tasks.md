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

For each Epic, generate 5-25 atomic tasks that fully cover the Epic scope.

Create each task:

```bash
# Create the task issue
TASK_URL=$(gh issue create \
  --title "Task: <Name>" \
  --label "Task" \
  --body "<Task markdown from template>")

# Extract task number from URL
TASK_NUM=$(echo "$TASK_URL" | grep -oE '[0-9]+$')
```

If `$GHPM_PROJECT` is set, include `--project "$GHPM_PROJECT"` (best-effort; continue if fails).

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
</error_handling>

<success_criteria>
Command completes successfully when:

1. All target Epics have been processed
2. Each Epic has 5-25 Task issues created
3. Each Task issue contains complete context (Epic/PRD links, acceptance criteria)
4. Each Task is linked as a sub-issue of its Epic
5. PRD is notified (if applicable)

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
2. **Tasks created:** Issue numbers and URLs
3. **Sub-issue linking:** Success/failure for each task linked to Epic
4. **Total tasks:** Count per Epic
5. **Project association:** Success/failure status (if `$GHPM_PROJECT` set)
6. **Warnings:** Any issues encountered (e.g., sub-issue linking failed, project add failed, PRD not found)
</output>

Proceed now.
