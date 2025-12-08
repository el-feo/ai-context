---
description: Plan and create GitHub issues from requirements - analyzes codebase, creates Epic with subtasks, adds to project
allowed-tools: [Read, Edit, Write, Bash, WebFetch, Glob, Grep, TodoWrite]
arguments:
  requirements:
    description: "Requirements or features to build for the Epic"
    required: false
  project_url:
    description: "GitHub Project URL (https://github.com/users/{user}/projects/{n} or orgs/{org}/projects/{n})"
    required: false
  repository:
    description: "Repository name in owner/repo format"
    required: false
---

<objective>
Analyze user requirements and the current codebase to create a well-structured Epic with subtasks in GitHub, tracked in a local file.

**Execution Notes:**

- Keep output minimal - redirect verbose commands to `/dev/null` or omit echo statements
- Execute commands efficiently without unnecessary status checks
- Use TodoWrite to track progress through multi-phase workflow

**Safety Notes:**

- Validate all user inputs before executing commands
- Check gh CLI authentication before starting (`gh auth status`)
- Monitor API rate limits during batch operations
- Use proper quoting for variables containing user input
</objective>

<prerequisites>
- `gh` CLI installed and authenticated (`gh auth status`)
- GitHub Project URL provided by user
- Working directory contains target codebase (or empty for greenfield)
</prerequisites>

<input_validation>

## Argument Handling

**If arguments provided via command:**

- `$requirements`: Features/requirements for the Epic
- `$project_url`: GitHub Project URL
- `$repository`: Repository in owner/repo format

If arguments are missing, gather interactively in Phase 1.

## Validation Checks

Before proceeding, validate:

```bash
# 1. Check gh CLI authentication
gh auth status || { echo "ERROR: Not authenticated. Run 'gh auth login'"; exit 1; }

# 2. Validate GitHub Project URL format
if [[ ! "$PROJECT_URL" =~ ^https://github\.com/(users|orgs)/[a-zA-Z0-9_-]+/projects/[0-9]+$ ]]; then
  echo "ERROR: Invalid project URL format"
  echo "Expected: https://github.com/users/{user}/projects/{n} or https://github.com/orgs/{org}/projects/{n}"
  exit 1
fi

# 3. Validate repository format
if [[ ! "$REPO" =~ ^[a-zA-Z0-9_.-]+/[a-zA-Z0-9_.-]+$ ]]; then
  echo "ERROR: Invalid repository format (expected: owner/repo)"
  exit 1
fi

# 4. Verify repository exists and is accessible
gh repo view "$REPO" > /dev/null 2>&1 || { echo "ERROR: Cannot access repository $REPO"; exit 1; }

# 5. Verify project exists and is accessible
gh project view "$PROJECT_NUMBER" --owner "$OWNER" > /dev/null 2>&1 || { echo "ERROR: Cannot access project"; exit 1; }
```

</input_validation>

<workflow>

## Phase 1: Gather Context

1. **Get from user:**
   - Requirements/features to build
   - GitHub Project URL (format: `https://github.com/users/{user}/projects/{n}` or `https://github.com/orgs/{org}/projects/{n}`)
   - Repository name (if not obvious from context)

2. **Parse project URL:**

   ```bash
   # Extract owner and project number from URL
   # Get project ID for API calls
   gh project view {project_number} --owner {owner} --format json
   ```

## Phase 2: Analyze Codebase

1. **Examine structure:**
   - Use Glob tool with patterns like `**/*.{ts,js,rb,py}` to find source files
   - Use Grep to search for patterns, tests, and configurations
   - Alternative bash approach:

   ```bash
   tree -L 3 -I 'node_modules|vendor|.git|dist|build|coverage' || find . -maxdepth 3 -type d
   ```

2. **Identify stack:** Check for package.json, Gemfile, requirements.txt, go.mod, etc.

3. **Note patterns:** Testing approach, code organization, CI/CD setup

4. **Document findings** for Epic description

## Phase 3: Discover Project Fields

```bash
gh project field-list {project_number} --owner {owner} --format json
```

Note field IDs for: Status, Priority, Estimate (Fibonacci), etc.

**Save these for later use:**

- Project ID (needed for `item-edit`)
- Estimate field ID (number type for Fibonacci points)
- Status field ID (if setting initial status)

```bash
# Get Project ID
PROJECT_ID=$(gh project view {project_number} --owner {owner} --format json | jq -r '.id')

# Get Estimate field ID
ESTIMATE_FIELD=$(gh project field-list {project_number} --owner {owner} --format json | jq -r '.fields[] | select(.name=="Estimate") | .id')
```

## Phase 4: Decompose into Tasks

**Task principles:**

- Each task = one reviewable PR (<400 lines ideal)
- Single responsibility
- Clear acceptance criteria
- Fibonacci estimate (1, 2, 3, 5, 8, 13)

**Estimation guide:**

| Points | Complexity     | Example                |
| ------ | -------------- | ---------------------- |
| 1-2    | Trivial/Simple | Config, single file    |
| 3      | Standard       | New endpoint/component |
| 5      | Moderate       | Feature with tests     |
| 8      | Complex        | Multi-file feature     |
| 13     | Large          | New subsystem          |

## Phase 5: Create Epic

```bash
gh issue create --repo {owner}/{repo} --title "[Epic] {name}" --body "{epic_body}"
```

**Epic body includes:**

- Overview and goals
- Codebase analysis summary
- Task breakdown table
- Technical considerations
- Size (S/M/L/XL based on total points)

## Phase 6: Create Subtasks

For each task:

```bash
gh issue create --repo {owner}/{repo} --title "{task_title}" --body "{task_body}"
```

**Task body includes:**

- Acceptance criteria (testable!)
- Implementation notes
- Affected files/components
- Dependencies (blocks/blocked by)
- Fibonacci estimate

## Phase 7: Link as Sub-issues

Use the REST API to link task issues as sub-issues to their parent Epic.

**Important:** The `sub_issue_id` must be the **database ID** (integer), not the issue number or GraphQL node ID.

```bash
REPO="{owner}/{repo}"
EPIC_NUM={epic_num}

# Get the database ID for the task issue (NOT the node ID)
TASK_DB_ID=$(gh api /repos/$REPO/issues/{task_num} --jq '.id')

# Add as sub-issue using parent issue NUMBER and child DATABASE ID
gh api /repos/$REPO/issues/$EPIC_NUM/sub_issues -X POST -F sub_issue_id=$TASK_DB_ID
```

**Batch linking example:**

```bash
REPO="owner/repo"
EPIC_NUM=42

# Link multiple tasks to an Epic (with rate limit protection)
for task_num in 43 44 45 46; do
  TASK_DB_ID=$(gh api /repos/$REPO/issues/$task_num --jq '.id')
  gh api /repos/$REPO/issues/$EPIC_NUM/sub_issues -X POST -F sub_issue_id=$TASK_DB_ID
  sleep 0.5  # Prevent rate limiting
done
```

**Key notes:**

- Use `-F` (not `-f`) to pass the ID as an integer type
- The URL uses the **issue number** for the parent Epic
- The body uses the **database ID** for the child task

## Phase 8: Add to Project

### Step 8.1: Get Project IDs and Fields

```bash
PROJECT_NUMBER={project_number}
OWNER={owner}

# Get Project ID and field IDs (from Phase 3 or retrieve now)
PROJECT_ID=$(gh project view $PROJECT_NUMBER --owner $OWNER --format json | jq -r '.id')
ESTIMATE_FIELD=$(gh project field-list $PROJECT_NUMBER --owner $OWNER --format json | jq -r '.fields[] | select(.name=="Estimate") | .id')
STATUS_FIELD=$(gh project field-list $PROJECT_NUMBER --owner $OWNER --format json | jq -r '.fields[] | select(.name=="Status") | .id')
```

### Step 8.2: Add Issues to Project and Set Estimate

**IMPORTANT:** After adding each issue to the project, immediately set its Estimate field with the Fibonacci point value. The Estimate field is a number field that accepts Fibonacci values (1, 2, 3, 5, 8, 13, 21).

```bash
# Add Epic to project (no estimate needed for epics)
EPIC_URL="https://github.com/$REPO/issues/$EPIC_NUM"
gh project item-add $PROJECT_NUMBER --owner $OWNER --url $EPIC_URL > /dev/null

# Add each task with its Fibonacci estimate
# Example for a single task:
TASK_NUM=43
TASK_POINTS=5  # Fibonacci estimate from task breakdown

ISSUE_URL="https://github.com/$REPO/issues/$TASK_NUM"
ITEM_ID=$(gh project item-add $PROJECT_NUMBER --owner $OWNER --url $ISSUE_URL --format json | jq -r '.id')
gh project item-edit --project-id $PROJECT_ID --id $ITEM_ID --field-id $ESTIMATE_FIELD --number $TASK_POINTS
```

### Step 8.3: Batch Add with Estimates

For multiple tasks, use a data structure to map issue numbers to estimates:

```bash
PROJECT_NUMBER={project_number}
OWNER={owner}
REPO="{owner}/{repo}"
PROJECT_ID="{project_id}"
ESTIMATE_FIELD="{estimate_field_id}"

# Check rate limit before bulk operations
RATE_REMAINING=$(gh api rate_limit --jq '.resources.core.remaining')
if [ "$RATE_REMAINING" -lt 50 ]; then
  echo "WARNING: Low API rate limit ($RATE_REMAINING remaining). Consider waiting."
fi

# Add Epic to project (no estimate)
gh project item-add $PROJECT_NUMBER --owner $OWNER --url "https://github.com/$REPO/issues/$EPIC_NUM" > /dev/null

# Add each task individually with its estimate
# Include sleep to prevent rate limiting on larger batches

# Task 1: 2 points
ITEM_ID=$(gh project item-add $PROJECT_NUMBER --owner $OWNER --url "https://github.com/$REPO/issues/43" --format json | jq -r '.id')
gh project item-edit --project-id $PROJECT_ID --id $ITEM_ID --field-id $ESTIMATE_FIELD --number 2
sleep 0.3

# Task 2: 3 points
ITEM_ID=$(gh project item-add $PROJECT_NUMBER --owner $OWNER --url "https://github.com/$REPO/issues/44" --format json | jq -r '.id')
gh project item-edit --project-id $PROJECT_ID --id $ITEM_ID --field-id $ESTIMATE_FIELD --number 3
sleep 0.3

# Continue for remaining tasks...
```

### Step 8.4: Verify Estimates Were Set (Optional)

```bash
gh project item-list $PROJECT_NUMBER --owner $OWNER --limit 50 --format json | \
  jq -r '.items[] | select(.content.number >= $EPIC_NUM) | [.content.number, .id, .title, (.estimate // "N/A")] | @csv' | sort -n
```

## Phase 9: Create Local Tracker

Create tracker file in `.gh-epics/` directory:

```bash
# Create directory if it doesn't exist
mkdir -p .gh-epics

# Get Item IDs from project
gh project item-list $PROJECT_NUMBER --owner $OWNER --limit 50 --format json | \
  jq -r '.items[] | select(.content.number >= $EPIC_NUM and .content.number <= $LAST_TASK_NUM) | [.content.number, .id, .title, (.estimate // "N/A")] | @csv' | sort -n
```

Create `.gh-epics/github-workflow-tracker-epic-{EPIC_NUM}.md`:

```markdown
# GitHub Workflow Tracker - Epic #{EPIC_NUM}

## Project Info
| Field           | Value       |
| --------------- | ----------- |
| **Project URL** | {url}       |
| **Repository**  | {repo}      |
| **Created**     | {timestamp} |

## GitHub Project IDs
These IDs are needed for `gh project item-edit` commands:

| Resource           | ID                  |
| ------------------ | ------------------- |
| **Project ID**     | {PROJECT_ID}        |
| **Estimate Field** | {ESTIMATE_FIELD_ID} |
| **Status Field**   | {STATUS_FIELD_ID}   |

## Epic
[{title}]({url}) - #{number} - Size: {size}

## Tasks
| #             | Title   | Est   | Item ID   | Status  | PR  | Blocked By |
| ------------- | ------- | ----- | --------- | ------- | --- | ---------- |
| [#{n}]({url}) | {title} | {pts} | {ITEM_ID} | Backlog | -   | {deps}     |

## Session Log
### {date}
- Created Epic #{n}
- Created {x} subtasks
- Added to project with Item IDs recorded above
```

**Tip:** To get Item IDs for existing issues:

```bash
gh project item-list {project_number} --owner {owner} --format json | \
  jq -r '.items[] | "\(.content.number): \(.id)"'
```

</workflow>

<error_handling>

## Common Failure Scenarios

1. **gh CLI not authenticated:**
   - Check: `gh auth status`
   - Fix: `gh auth login`

2. **Project not found:**
   - Verify project URL format matches expected pattern
   - Check user/org permissions
   - Validate project number exists

3. **Issue creation fails:**
   - Check repository write permissions
   - Verify repository exists and is accessible
   - Validate issue body markdown syntax

4. **Sub-issue linking fails:**
   - Ensure parent Epic issue exists
   - Verify using database ID (integer), not node ID or issue number
   - Check API rate limits

5. **Project item-add fails:**
   - Verify project accepts items from this repository
   - Check field IDs are valid for this project
   - Ensure issue URLs are correctly formatted

6. **Rate limit exceeded:**

   ```bash
   # Check current rate limit
   gh api rate_limit --jq '.resources.core.remaining'
   ```

   - Add `sleep 0.5` between batch API calls
   - Wait for rate limit reset if exhausted

## Rollback Procedure

If workflow fails after creating issues:

```bash
# 1. List recently created issues
gh issue list --repo {owner}/{repo} --limit 20 --json number,title

# 2. Close unwanted issues (if needed)
gh issue close {number} --repo {owner}/{repo}

# 3. Remove items from project (get item ID first)
gh project item-list {project_number} --owner {owner} --format json | jq '.items[] | select(.content.number == {issue_num})'
gh project item-delete {project_number} --owner {owner} --id {item_id}

# 4. Delete sub-issue relationship
gh api /repos/{owner}/{repo}/issues/{epic_num}/sub_issues/{sub_issue_id} -X DELETE
```

</error_handling>

<success_criteria>

## Verification Checklist

After completion, verify:

1. **Epic created correctly:**

   ```bash
   gh issue view {epic_number} --repo {owner}/{repo}
   ```

   - Has `[Epic]` prefix in title
   - Body contains all subtask links
   - Labels applied (if any)

2. **All subtasks created:**

   ```bash
   gh issue list --repo {owner}/{repo} --limit 20 --json number,title
   ```

   - Each task has issue number
   - Acceptance criteria present in body
   - Fibonacci estimate documented

3. **Sub-issue relationships established:**

   ```bash
   gh api /repos/{owner}/{repo}/issues/{epic_num}/sub_issues --jq '.[].number'
   ```

   - All tasks linked to Epic

4. **Project items with estimates:**

   ```bash
   gh project item-list {project_number} --owner {owner} --limit 50 --format json | \
     jq -r '.items[] | [.content.number, .estimate // "N/A"] | @csv'
   ```

   - All issues present in project
   - Estimate field set for each task

5. **Tracker file created:**
   - File exists at `.gh-epics/github-workflow-tracker-epic-{EPIC_NUM}.md`
   - Contains all Item IDs
   - Has correct project metadata
</success_criteria>

<output>
After completion, report:
1. Epic created: #{number} with link
2. Subtasks created: list with numbers and estimates
3. All added to project with Item IDs
4. Tracker file location: `.gh-epics/github-workflow-tracker-epic-{EPIC_NUM}.md`
5. Verification status: all checks passed / any issues found

Hand off to human for backlog grooming.
</output>
