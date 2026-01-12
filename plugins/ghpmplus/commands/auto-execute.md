---
description: Trigger the orchestrator-agent to autonomously execute a PRD from start to finish
argument-hint: prd=#<issue_number>
allowed-tools: [Read, Bash, Grep, Task]
---

<objective>
You are the entry point for GHPMplus autonomous execution. Your job is to validate the PRD exists, confirm execution with the user, and then delegate to the orchestrator-agent via the Task tool to handle the complete workflow.
</objective>

<prerequisites>
- `gh` CLI installed and authenticated (`gh auth status`)
- Working directory is a git repository with GitHub remote
- User has write access to repository issues
- PRD issue must exist and be labeled "PRD"
</prerequisites>

<arguments>
**Required:**
- `prd=#N` - The PRD issue number to execute

**Example:**
```
/ghpmplus:auto-execute prd=#42
```
</arguments>

<usage_examples>

**Standard usage:**

```
/ghpmplus:auto-execute prd=#42
```

→ Validates PRD #42 exists, shows summary, confirms with user, then triggers orchestrator

**With existing Epics:**

```
/ghpmplus:auto-execute prd=#42
```

→ If PRD already has Epics, orchestrator will use existing breakdown instead of creating new

</usage_examples>

<operating_rules>

- **Always validate** that the PRD issue exists and has the "PRD" label before proceeding
- **Show PRD summary** to user before triggering execution
- **Confirm execution** with user before delegating to orchestrator (this is a significant autonomous action)
- **Do not create local artifacts** - all work happens via GitHub issues and the orchestrator
- **Delegate fully** to the orchestrator-agent once confirmed - do not duplicate its workflow
</operating_rules>

<workflow>

## Step 1: Parse Arguments

Extract PRD number from arguments:

```bash
# Parse prd=#N from $ARGUMENTS
PRD_NUMBER=$(echo "$ARGUMENTS" | grep -oE 'prd=#[0-9]+' | grep -oE '[0-9]+')

if [ -z "$PRD_NUMBER" ]; then
  echo "ERROR: PRD number required"
  echo "Usage: /ghpmplus:auto-execute prd=#<issue_number>"
  exit 1
fi
```

## Step 2: Validate PRD Exists

```bash
# Verify PRD issue exists and has PRD label
PRD_DATA=$(gh issue view "$PRD_NUMBER" --json title,body,labels,state,url 2>/dev/null)

if [ -z "$PRD_DATA" ]; then
  echo "ERROR: Issue #$PRD_NUMBER not found"
  exit 1
fi

# Check for PRD label
HAS_PRD_LABEL=$(echo "$PRD_DATA" | jq -r '.labels[].name' | grep -c "^PRD$" || echo "0")

if [ "$HAS_PRD_LABEL" -eq 0 ]; then
  echo "WARNING: Issue #$PRD_NUMBER does not have 'PRD' label"
  echo "This may not be a valid PRD. Proceeding anyway..."
fi

# Check if PRD is open
STATE=$(echo "$PRD_DATA" | jq -r '.state')
if [ "$STATE" = "CLOSED" ]; then
  echo "ERROR: PRD #$PRD_NUMBER is already closed"
  exit 1
fi
```

## Step 3: Display PRD Summary

Extract and display key information:

```bash
TITLE=$(echo "$PRD_DATA" | jq -r '.title')
URL=$(echo "$PRD_DATA" | jq -r '.url')

echo "## PRD Summary"
echo ""
echo "**Title:** $TITLE"
echo "**Issue:** #$PRD_NUMBER"
echo "**URL:** $URL"
echo ""
```

Also extract from body:
- Summary section
- Acceptance Criteria (high level)
- Any existing Epics linked

## Step 4: Check for Existing Work

```bash
# Get repository info
OWNER=$(gh repo view --json owner -q '.owner.login')
REPO=$(gh repo view --json name -q '.name')

# Check for existing Epics linked to this PRD using GraphQL sub-issues API
cat > /tmp/ghpmplus-subissues.graphql << 'GRAPHQL'
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

EPICS=$(gh api graphql -F owner="$OWNER" -F repo="$REPO" -F number=$PRD_NUMBER \
  -f query="$(cat /tmp/ghpmplus-subissues.graphql)" \
  --jq '.data.repository.issue.subIssues.nodes[] | select(.labels.nodes[].name == "Epic") | [.number, .title, .state] | @tsv' 2>/dev/null || echo "")

if [ -n "$EPICS" ]; then
  echo "### Existing Epics Found"
  echo ""
  echo "$EPICS" | while read line; do
    NUM=$(echo "$line" | cut -f1)
    TITLE=$(echo "$line" | cut -f2)
    STATE=$(echo "$line" | cut -f3)
    echo "- #$NUM: $TITLE ($STATE)"
  done
  echo ""
  echo "The orchestrator will use existing Epics instead of creating new ones."
fi
```

## Step 5: Confirm Execution

Before delegating to orchestrator, confirm with user:

```
This will trigger autonomous execution of PRD #$PRD_NUMBER.

The orchestrator will:
1. Break down the PRD into Epics (if not already done)
2. Break Epics into atomic Tasks
3. Execute Tasks using TDD or Non-TDD workflows
4. Create PRs for each Task
5. Monitor CI and handle failures

This process may take significant time and will create multiple GitHub issues and PRs.

Proceed with autonomous execution?
```

Use `AskUserQuestion` tool if needed for confirmation.

## Step 6: Delegate to Orchestrator

Once confirmed, delegate to the orchestrator-agent:

```markdown
Use the Task tool with subagent_type="ghpmplus:orchestrator" to:

Execute PRD #$PRD_NUMBER autonomously.

Context:
- PRD Title: $TITLE
- PRD URL: $URL
- Existing Epics: [list if any]

The orchestrator should:
1. Fetch full PRD details
2. Create or use existing Epics
3. Create Tasks for each Epic
4. Execute Tasks in appropriate order (respecting dependencies)
5. Create PRs with conventional commits
6. Monitor CI status
7. Report completion status back to PRD issue
```

## Step 7: Report Initiation

After delegation, report:

```
Autonomous Execution Initiated

PRD: #$PRD_NUMBER - $TITLE
Orchestrator: Delegated via Task tool

The orchestrator is now running. Progress will be posted to:
- PRD issue: $URL
- Individual Epic and Task issues as they are created

You can monitor progress by watching the PRD issue for updates.
```

</workflow>

<error_handling>

**If PRD not found:**
- Report error with issue number
- Suggest checking issue number or creating PRD first

**If PRD is closed:**
- Report that PRD is already closed
- Suggest reopening if execution is still needed

**If no PRD label:**
- Warn but allow proceeding (user may have custom workflow)

**If orchestrator delegation fails:**
- Report the error
- Suggest manual fallback using ghpm commands

**If user declines confirmation:**
- Exit gracefully
- Suggest using manual ghpm commands for step-by-step control

</error_handling>

<success_criteria>
Command completes successfully when:

1. PRD is validated and exists
2. User confirms execution
3. Orchestrator-agent is successfully delegated via Task tool
4. Initiation message is displayed to user

The actual execution success is determined by the orchestrator-agent.
</success_criteria>

<output>
After delegation, report:

1. **PRD:** #<number> - <title>
2. **Status:** Orchestrator delegated
3. **Monitor:** Link to PRD issue for progress updates

**Example Output:**

```
Autonomous Execution Initiated

PRD: #42 - User Authentication System
Orchestrator: Delegated via Task tool
Monitor: https://github.com/owner/repo/issues/42

Progress updates will be posted to the PRD issue.
```

</output>

<related_commands>

**GHPMplus Commands:**
- `/ghpmplus:create-prd` - Create a new PRD (prerequisite for auto-execute)

**Manual Workflow (if needed):**
- `/ghpm:create-epics prd=#N` - Manually create Epics
- `/ghpm:create-tasks epic=#N` - Manually create Tasks
- `/ghpm:tdd-task task=#N` - Manually execute Tasks

</related_commands>

Now proceed:

1. Parse arguments to extract PRD number
2. Validate PRD exists and has appropriate label
3. Display PRD summary to user
4. Check for existing Epics
5. Confirm execution with user
6. Delegate to orchestrator-agent via Task tool
7. Report initiation status
