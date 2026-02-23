---
description: Execute a PRD using Claude Code agent teams for large, multi-epic projects with parallel teammate coordination
argument-hint: prd=#<issue_number>
allowed-tools: [Read, Bash, Grep, Glob, Task, TaskCreate, TaskUpdate, TaskList, TaskGet, AskUserQuestion]
---

<objective>
You are the entry point for GHPMplus agent team execution. For large PRDs (3+ epics, 10+ tasks), this command coordinates a team of Claude Code agents working in parallel with direct inter-agent communication via shared task lists.

Unlike `/ghpmplus:auto-execute` (which uses a single orchestrator spawning subagents), team-execute creates a true agent team where teammates work independently in isolated worktrees with a dedicated reviewer processing PRs in parallel.
</objective>

<prerequisites>
- `gh` CLI installed and authenticated (`gh auth status`)
- Working directory is a git repository with GitHub remote
- User has write access to repository issues
- PRD issue must exist and be labeled "PRD"
- PRD should have Epics and Tasks already created (use `/ghpmplus:auto-execute` first for planning, or `/ghpm:create-epics` + `/ghpm:create-tasks`)
</prerequisites>

<arguments>
**Required:**
- `prd=#N` - The PRD issue number to execute

**Example:**

```
/ghpmplus:team-execute prd=#42
```

</arguments>

<when_to_use>

### auto-execute vs team-execute

| Factor            | auto-execute (subagents) | team-execute (agent teams)     |
| ----------------- | ------------------------ | ------------------------------ |
| PRD size          | 1-2 epics, <10 tasks     | 3+ epics, 10+ tasks            |
| Coordination      | Orchestrator manages all | Teammates coordinate directly  |
| Review            | Sequential after each PR | Dedicated reviewer in parallel |
| Token cost        | Lower                    | Higher                         |
| Inter-agent comms | Report to parent only    | Shared task list               |
| Worktree usage    | Orchestrator creates     | Each teammate creates own      |

**Use team-execute when:**

- PRD has 3+ epics with 10+ total tasks
- Tasks are largely independent across epics
- You want parallel review alongside implementation
- The project is large enough to justify the token overhead
</when_to_use>

<team_structure>

## Agent Team Roles

### Lead (You - the command executor)

- Creates the shared task list from PRD/Epic/Task breakdown
- Spawns Epic Owner teammates (1 per epic)
- Spawns Reviewer teammate
- Optionally spawns QA teammate
- Reviews teammate plans before approving implementation
- Monitors overall progress via TaskList
- Handles escalations and blockers

### Epic Owner Teammates (1 per epic)

- Each owns all tasks under a single epic
- Works in an isolated git worktree
- Submits implementation plan to lead for approval before coding
- Implements tasks sequentially within their epic
- Creates PRs for each task
- Signals reviewer when PRs are ready

### Reviewer Teammate

- Monitors for new PRs across all epics
- Runs the review cycle (CI check + pr-review + conflict resolution)
- Communicates feedback to epic owners via task updates
- Tracks review iterations and escalates when needed

### QA Teammate (Optional)

- Creates QA steps from PRD acceptance criteria
- Executes QA steps as implementation completes
- Creates Bug issues for failures
- Works in parallel with implementation

</team_structure>

<workflow>

## Step 1: Parse and Validate PRD

```bash
# Parse prd=#N from $ARGUMENTS
PRD_NUMBER=$(echo "$ARGUMENTS" | grep -oE 'prd=#[0-9]+' | grep -oE '[0-9]+')

if [ -z "$PRD_NUMBER" ]; then
  echo "ERROR: PRD number required"
  echo "Usage: /ghpmplus:team-execute prd=#<issue_number>"
  exit 1
fi

# Validate PRD exists
PRD_DATA=$(gh issue view "$PRD_NUMBER" --json title,body,labels,state,url 2>/dev/null)

if [ -z "$PRD_DATA" ]; then
  echo "ERROR: Issue #$PRD_NUMBER not found"
  exit 1
fi

TITLE=$(echo "$PRD_DATA" | jq -r '.title')
URL=$(echo "$PRD_DATA" | jq -r '.url')
STATE=$(echo "$PRD_DATA" | jq -r '.state')

if [ "$STATE" = "CLOSED" ]; then
  echo "ERROR: PRD #$PRD_NUMBER is already closed"
  exit 1
fi
```

## Step 2: Discover Epics and Tasks

Fetch the PRD's epic/task hierarchy:

```bash
OWNER=$(gh repo view --json owner -q '.owner.login')
REPO=$(gh repo view --json name -q '.name')

# Fetch Epics (sub-issues of PRD with Epic label)
# Then for each Epic, fetch Tasks (sub-issues with Task label)
# Build the full hierarchy
```

If no Epics/Tasks exist, prompt the user to create them first using `/ghpmplus:auto-execute` (which handles planning) or the manual ghpm commands.

## Step 3: Build Shared Task List

Map GitHub issues to Claude Code tasks:

```
For each Task issue:
  TaskCreate:
    subject: "<Task title>"
    description: |
      GitHub Issue: #<task_number>
      Epic: #<epic_number>
      Commit Type: <type>
      Scope: <scope>
      Acceptance Criteria: <from issue body>
    metadata:
      github_issue: <task_number>
      epic: <epic_number>
      epic_title: "<epic title>"
      status: "pending"
```

Set up dependencies using `addBlocks`/`addBlockedBy` based on:

- File overlap analysis (tasks sharing files must be serialized)
- Explicit dependencies noted in Task issues
- Epic ordering (if one epic depends on another)

## Step 4: Confirm Team Composition

Present the team structure to the user:

```
## Team Execution Plan

**PRD:** #$PRD_NUMBER - $TITLE

### Team Composition

| Role          | Epic                    | Tasks            |
| ------------- | ----------------------- | ---------------- |
| Epic Owner 1  | #101: Core Auth         | #201, #202, #203 |
| Epic Owner 2  | #102: API Layer         | #204, #205, #206 |
| Epic Owner 3  | #103: Testing           | #207, #208       |
| Reviewer      | All PRs                 | -                |
| QA (optional) | All acceptance criteria | -                |

### Execution Strategy

- Parallel epics: [list epics that can run simultaneously]
- Serial dependencies: [list any cross-epic dependencies]
- Estimated PRs: <count>

Proceed with team execution?
```

Use `AskUserQuestion` for confirmation.

## Step 5: Spawn Epic Owner Teammates

For each epic, spawn a teammate using the Task tool:

```markdown
Use the Task tool with subagent_type="ghpmplus:task-executor" and isolation="worktree" to:

You are an Epic Owner teammate responsible for all tasks under Epic #$EPIC_NUMBER.

## Your Epic
- Epic: #$EPIC_NUMBER - $EPIC_TITLE
- Tasks: $TASK_LIST (in execution order)

## Workflow

### Phase A: Plan
1. Read each Task issue to understand requirements
2. Explore the codebase to understand existing patterns
3. Design your implementation approach
4. Report your plan back (this will be reviewed by the lead)

### Phase B: Implement (after plan approval)
For each Task in order:
1. Claim the Task (assign self)
2. Implement using TDD or Non-TDD workflow
3. Create a PR with conventional commits: `$COMMIT_TYPE($SCOPE): $DESCRIPTION (#$TASK_NUMBER)`
4. Update the shared task (TaskUpdate) with PR number
5. Move to next Task

### Phase C: Address Review Feedback
- Monitor your tasks for review feedback
- Apply fixes and push new commits when changes are requested
- Re-signal readiness after fixes

## Rules
- Work only within your worktree
- Only modify files relevant to your epic's tasks
- Follow conventional commit format
- Create one PR per Task
- Update TaskList as you progress
```

## Step 6: Spawn Reviewer Teammate

```markdown
Use the Task tool with subagent_type="ghpmplus:review-cycle-coordinator" to:

You are the Reviewer teammate. Your job is to review PRs created by Epic Owner teammates.

## Workflow

1. Monitor the shared task list (TaskList) for tasks with PR numbers
2. For each new PR:
   a. Run CI check (invoke ghpmplus:ci-check subagent)
   b. Run code review (invoke ghpmplus:pr-review subagent)
   c. If changes requested, update the task with feedback
   d. Wait for fixes, then re-review
   e. Max 3 iterations before escalating to human
3. Track review status on each task via metadata updates
4. Report approved PRs to the lead

## Review Priority
- Process PRs in the order they arrive
- Prioritize blocking issues over suggestions
- Escalate after 3 failed iterations
```

## Step 7: Spawn QA Teammate (Optional)

If PRD has acceptance criteria suitable for automated QA:

```markdown
Use the Task tool with subagent_type="ghpmplus:qa-planner" to:

You are the QA teammate. Create and execute QA steps.

## Workflow

1. Create QA issue linked to PRD #$PRD_NUMBER
2. Generate QA steps from acceptance criteria
3. Wait for implementation to complete (monitor TaskList)
4. Execute QA steps using Playwright
5. Create Bug issues for any failures
6. Report QA results
```

## Step 8: Monitor Progress

As the lead, monitor the team:

```python
while not all_tasks_complete():
    # Check TaskList for progress
    tasks = TaskList()

    # Count by status
    pending = [t for t in tasks if t.status == "pending"]
    in_progress = [t for t in tasks if t.status == "in_progress"]
    completed = [t for t in tasks if t.status == "completed"]

    # Check for blockers
    blocked = [t for t in tasks if t.blockedBy and not all_resolved(t.blockedBy)]

    # Post progress update to PRD
    if significant_change():
        post_progress_update(prd_number, tasks)

    # Check for escalations
    escalated = [t for t in tasks if t.metadata.get("review_status") == "ESCALATED"]
    for task in escalated:
        handle_escalation(task)
```

## Step 9: Completion

When all tasks are complete:

1. Verify all PRs are approved or merged
2. Run final QA (if QA teammate active)
3. Post completion summary to PRD
4. Clean up worktrees

```bash
gh issue comment "$PRD_NUMBER" --body "$(cat <<COMPLETE_EOF
## Team Execution Complete

**PRD:** #$PRD_NUMBER - $TITLE

### Results

| Epic | Tasks | PRs | Status |
| ---- | ----- | --- | ------ |
$(for each epic...)

### Review Summary
- Total PRs: N
- Approved: N
- Escalated: N

### QA Summary (if applicable)
- Steps Passed: N/M
- Bugs Found: N

---
*Completed by GHPMplus Team Execution*
COMPLETE_EOF
)"
```

</workflow>

<plan_approval>

## Plan Approval Workflow

Before each Epic Owner starts coding, they must submit a plan:

1. **Epic Owner explores codebase** and designs approach
2. **Epic Owner reports plan** via task update or direct output
3. **Lead reviews plan** against PRD requirements:
   - Does the approach satisfy acceptance criteria?
   - Are there conflicts with other epics' work?
   - Is the scope appropriate?
4. **Lead approves or rejects** with feedback
5. **Only after approval** does the Epic Owner start implementation

This prevents wasted work from misunderstood requirements.

</plan_approval>

<error_handling>

**If no Epics/Tasks exist:**

- Prompt user to run planning first
- Suggest: `/ghpmplus:auto-execute prd=#N` (which handles planning phases)

**If a teammate fails:**

- Log the error
- Reassign tasks to another teammate or handle manually
- Do not block other teammates

**If review escalates:**

- Add `needs-human-review` label
- Continue with other tasks
- Report in completion summary

**If user requests PAUSE:**

- Stop spawning new teammates
- Let active teammates finish current task
- Save progress via TaskList
- Report pause status

</error_handling>

<success_criteria>
Command completes successfully when:

1. All Tasks have PRs created
2. All PRs have been reviewed (approved or escalated)
3. QA steps executed (if applicable)
4. Completion summary posted to PRD
5. Worktrees cleaned up
</success_criteria>

<output>
After initiation, report:

```
Team Execution Initiated

PRD: #42 - User Authentication System
Team: 3 Epic Owners + 1 Reviewer + 1 QA

Epic Owners:
- Teammate 1: Epic #101 (3 tasks)
- Teammate 2: Epic #102 (3 tasks)
- Teammate 3: Epic #103 (2 tasks)

Reviewer: Processing PRs as they arrive
QA: Creating acceptance test steps

Monitor progress on PRD issue: https://github.com/owner/repo/issues/42
```

</output>

Now proceed:

1. Parse arguments to extract PRD number
2. Validate PRD exists and has Epics/Tasks
3. Build shared task list
4. Confirm team composition with user
5. Spawn teammates
6. Monitor progress
7. Report completion
