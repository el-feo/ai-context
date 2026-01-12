# GHPMplus Plugin

Autonomous GitHub Project Management workflow with orchestrator-agent coordination for parallel task execution via git worktrees.

## Overview

GHPMplus extends the original GHPM plugin with autonomous execution capabilities. While GHPM requires manual step-by-step command invocation (create PRD → create epics → create tasks → execute), GHPMplus automates the entire workflow through a central orchestrator agent.

### Key Differences from GHPM

| Feature | GHPM | GHPMplus |
|---------|------|----------|
| Workflow | Manual step-by-step | Autonomous end-to-end |
| Task Execution | One at a time | Parallel via worktrees |
| Agent Coordination | None | Orchestrator + sub-agents |
| Progress Tracking | User-driven | Automatic via GitHub comments |

## Installation

```bash
# Add the ai-context marketplace (if not already added)
/plugin marketplace add el-feo/ai-context

# Install ghpmplus plugin
/plugin install ghpmplus@jebs-dev-tools

# Or use plugin directory directly
cc --plugin-dir /path/to/ai-context/plugins/ghpmplus
```

## Commands

### `/ghpmplus:create-prd`

Creates a Product Requirements Document (PRD) as a GitHub issue.

```bash
# Create PRD from detailed description
/ghpmplus:create-prd Build a user authentication system with OAuth support for enterprise customers

# Vague input triggers clarification questions
/ghpmplus:create-prd Add a dashboard
```

**Output:** PRD issue with structured sections (Summary, Requirements, Acceptance Criteria, etc.)

### `/ghpmplus:auto-execute`

Triggers the orchestrator to autonomously execute a PRD from start to finish.

```bash
/ghpmplus:auto-execute prd=#42
```

**What happens:**
1. PRD is validated and analyzed
2. Epics are created (or existing ones used)
3. Tasks are created for each Epic
4. Tasks are executed in parallel (using git worktrees)
5. PRs are created with conventional commits
6. CI status is monitored and failures handled
7. Completion summary posted to PRD issue

## Architecture

### Orchestrator-Agent Model

```
┌─────────────────────────────────────────────────────────┐
│                    Orchestrator Agent                    │
│  - Coordinates workflow phases                          │
│  - Delegates to sub-agents via Task tool                │
│  - Manages git worktrees for parallel execution         │
│  - Reports progress to GitHub issues                    │
└───────────────────────┬─────────────────────────────────┘
                        │
        ┌───────────────┼───────────────┐
        │               │               │
        ▼               ▼               ▼
┌───────────────┐ ┌───────────────┐ ┌───────────────┐
│ Epic Planner  │ │ Task Executor │ │  CI Checker   │
│ (sub-agent)   │ │ (sub-agent)   │ │ (sub-agent)   │
└───────────────┘ └───────────────┘ └───────────────┘
```

### Workflow Phases

1. **PRD Hydration** - Fetch and analyze PRD requirements
2. **Epic/Task Planning** - Break down work via planner sub-agents
3. **Dependency Analysis** - Determine parallel vs sequential execution
4. **Parallel Execution** - Create worktrees and spawn executor agents
5. **Task Execution** - Execute tasks using TDD or Non-TDD workflows
6. **Integration & QA** - Verify PRs pass CI, handle failures
7. **Cleanup & Reporting** - Remove worktrees, update PRD status

### Task Tool Delegation

The orchestrator uses Claude Code's Task tool to spawn sub-agents:

```markdown
Use the Task tool with subagent_type="ghpmplus:task-executor" to:

Execute Task #55 using the appropriate workflow.

Context:
- Task Number: 55
- Commit Type: feat
- Epic: #101

Expected Output:
- PR URL
- Commit SHA(s)
```

## Git Worktree Usage

GHPMplus uses git worktrees to enable parallel task execution. Multiple sub-agents can work on different tasks simultaneously without conflicts.

### Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `GHPMPLUS_WORKTREE_DIR` | `.worktrees` | Directory for worktree storage |
| `GHPMPLUS_MAX_PARALLEL` | `3` | Maximum concurrent worktrees |

### Naming Conventions

- **Worktree directory:** `.worktrees/task-<issue_number>`
- **Branch name:** `ghpm/task-<issue_number>-<slug>`

### Helper Functions

The plugin includes shell helper functions:

```bash
# Create worktree for a task
ghpmplus_worktree_create 42 "Implement user login"

# Remove worktree after completion
ghpmplus_worktree_remove 42

# Cleanup all worktrees
ghpmplus_worktree_cleanup

# List active worktrees
ghpmplus_worktree_list
```

See `skills/worktree-helpers.md` for full documentation.

## Sub-Agents

| Agent | Purpose | Status |
|-------|---------|--------|
| `orchestrator` | Central coordinator with state reconstruction, concurrency control, failure recovery | Active |
| `epic-creator-agent` | Creates Epic issues from PRD analysis | Active |
| `task-creator-agent` | Creates Task issues from Epic breakdown | Active |
| `task-executor-agent` | Executes tasks via TDD or Non-TDD workflow | Active |
| `stub-epic-planner` | Epic creation (stub for testing) | Testing |
| `stub-task-executor` | Task execution (stub for testing) | Testing |

The orchestrator coordinates all sub-agents via Claude Code's Task tool, managing parallel execution through git worktrees.

## Usage Examples

### Complete Autonomous Workflow

```bash
# Step 1: Create a PRD
/ghpmplus:create-prd Build a notification system with email, SMS, and push notification support for users who want to stay informed about account activity

# Output: PRD #42 created

# Step 2: Execute autonomously
/ghpmplus:auto-execute prd=#42

# Orchestrator takes over:
# - Creates Epics #43, #44, #45
# - Creates Tasks #46-#52
# - Executes tasks in parallel
# - Creates PRs #53-#59
# - Reports completion to PRD #42
```

### Manual Fallback

If autonomous execution isn't suitable, use original ghpm commands:

```bash
# Create epics manually
/ghpm:create-epics prd=#42

# Create tasks manually
/ghpm:create-tasks epic=#43

# Execute tasks one by one
/ghpm:tdd-task task=#46
```

## Human Intervention

### PAUSE/RESUME Commands

You can pause and resume the orchestrator at any time by commenting on the PRD issue:

**To pause the workflow:**
- Comment `PAUSE` on the PRD issue
- The orchestrator will finish active tasks but won't start new ones
- An acknowledgment comment confirms the pause

**To resume the workflow:**
- Comment `RESUME` on the PRD issue
- The orchestrator will continue from the last checkpoint
- Failure tracking resets for a fresh start

Comments are case-insensitive: `PAUSE`, `pause`, or `Pause workflow` all work.

### Intervention Check Interval

The orchestrator checks for PAUSE/RESUME comments every 10 seconds (configurable via `GHPMPLUS_INTERVENTION_CHECK`).

## Failure Recovery

### Circuit Breaker Pattern

The orchestrator automatically pauses after multiple consecutive failures to prevent runaway errors:

- **Threshold:** 3 failures (configurable)
- **Window:** 60 seconds (configurable)
- **Behavior:** Pause workflow, post failure summary, await manual RESUME

### Failure Summary

When paused due to failures, a summary is posted to the PRD:

```
## Workflow Paused - Multiple Failures

The orchestrator has paused after 3 consecutive failures within 60 seconds.

### Failed Tasks
| Task | Error | Time |
|------|-------|------|
| #201 | Tests failed | 10:30:15 |
| #202 | Lint errors | 10:30:25 |
| #203 | Build failed | 10:30:35 |

### Resume Instructions
1. Fix any blocking issues
2. Comment `RESUME` on this PRD issue
```

### Recovery Actions

After RESUME:
- Failure counter resets
- Workflow continues from checkpoint
- Previously failed tasks are retried

## State Reconstruction

### Resume Capability

The orchestrator can resume from any interruption point by reconstructing state from GitHub:

- **PRD state:** Open/closed, linked Epics
- **Epic state:** Progress, linked Tasks
- **Task state:** Pending/in-progress/completed, linked PRs
- **Checkpoint comments:** YAML snapshots with execution state

### Idempotent Operations

All operations are safe to retry:

| Operation | Guard Check | On Duplicate |
|-----------|-------------|--------------|
| Create Epic | Search by title + label | Return existing |
| Create Task | Search by title + label | Return existing |
| Create Branch | `git show-ref` | Checkout existing |
| Create PR | `gh pr list --head` | Return existing |
| Post Comment | Check for marker | Update existing |

### Checkpoint Format

Progress is tracked via checkpoint comments on the PRD (YAML format):

```yaml
checkpoint:
  timestamp: "2024-01-15T10:30:00Z"
  status: "in_progress"
  progress:
    total_tasks: 8
    completed: 3
    in_progress: 2
    pending: 3
    failed: 0
  active_tasks: [202, 204]
  completed_tasks: [201, 205]
  queued_tasks: [203, 206, 207]
```

## Error Handling

| Scenario | Behavior |
|----------|----------|
| Task execution fails | Track failure, create follow-up issue, continue with other tasks |
| CI check fails | Delegate to CI checker for analysis and fix attempt |
| Worktree conflict | Clean up and recreate |
| Rate limiting | Exponential backoff |
| Multiple failures (3 in 60s) | Pause workflow, notify via PRD comment |
| Manual PAUSE | Graceful stop, save checkpoint, await RESUME |

## Configuration

### Environment Variables

```bash
# GitHub Project association (optional)
export GHPM_PROJECT="Q1 Roadmap"

# Concurrency settings
export GHPMPLUS_MAX_CONCURRENCY=3       # Max parallel task executions
export GHPMPLUS_WORKTREE_DIR=".worktrees"  # Directory for git worktrees

# Auto-merge passing PRs (use with caution)
export GHPMPLUS_AUTO_MERGE=false

# Failure recovery settings
export GHPMPLUS_FAILURE_WINDOW=60       # Seconds for failure tracking window
export GHPMPLUS_FAILURE_THRESHOLD=3     # Consecutive failures before pause

# Progress tracking
export GHPMPLUS_CHECKPOINT_INTERVAL=30  # Minimum seconds between checkpoints
export GHPMPLUS_INTERVENTION_CHECK=10   # Seconds between PAUSE/RESUME checks
```

### Configuration Reference

| Variable | Default | Description |
|----------|---------|-------------|
| `GHPMPLUS_MAX_CONCURRENCY` | 3 | Maximum parallel task executions |
| `GHPMPLUS_WORKTREE_DIR` | `.worktrees` | Directory for git worktrees |
| `GHPMPLUS_AUTO_MERGE` | false | Auto-merge passing PRs |
| `GHPMPLUS_FAILURE_WINDOW` | 60 | Seconds for failure tracking window |
| `GHPMPLUS_FAILURE_THRESHOLD` | 3 | Consecutive failures before pause |
| `GHPMPLUS_CHECKPOINT_INTERVAL` | 30 | Minimum seconds between checkpoints |
| `GHPMPLUS_INTERVENTION_CHECK` | 10 | Seconds between PAUSE/RESUME checks |

## Roadmap

- [x] State reconstruction for workflow resume
- [x] File overlap detection for parallelization
- [x] Concurrency control with configurable limits
- [x] Checkpoint comments for progress tracking
- [x] Failure recovery with circuit breaker
- [x] PAUSE/RESUME human intervention
- [x] Idempotent operations for safe re-runs
- [ ] Replace stub agents with full implementations
- [ ] Add QA agent for acceptance testing
- [ ] Implement automatic PR merging (optional)
- [ ] Add progress dashboard command
- [ ] Support for multi-repo workflows

## Related

- **GHPM Plugin** - Original manual workflow: `/ghpm:create-prd`, `/ghpm:create-epics`, `/ghpm:create-tasks`, `/ghpm:tdd-task`
- **ai-context Repository** - Collection of Claude Code plugins
