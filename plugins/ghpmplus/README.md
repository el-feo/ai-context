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
| `orchestrator` | Central coordinator | Active |
| `stub-epic-planner` | Epic creation (stub) | Testing |
| `stub-task-executor` | Task execution (stub) | Testing |

Stub agents are placeholders for testing the delegation mechanism. They will be replaced with full implementations.

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

## Error Handling

| Scenario | Behavior |
|----------|----------|
| Task execution fails | Create follow-up issue, continue with other tasks |
| CI check fails | Delegate to CI checker for analysis and fix attempt |
| Worktree conflict | Clean up and recreate |
| Rate limiting | Exponential backoff |

## Configuration

### Environment Variables

```bash
# GitHub Project association (optional)
export GHPM_PROJECT="Q1 Roadmap"

# Worktree settings
export GHPMPLUS_WORKTREE_DIR=".worktrees"
export GHPMPLUS_MAX_PARALLEL=3

# Auto-merge passing PRs (use with caution)
export GHPMPLUS_AUTO_MERGE=false
```

## Roadmap

- [ ] Replace stub agents with full implementations
- [ ] Add QA agent for acceptance testing
- [ ] Implement automatic PR merging (optional)
- [ ] Add progress dashboard command
- [ ] Support for multi-repo workflows

## Related

- **GHPM Plugin** - Original manual workflow: `/ghpm:create-prd`, `/ghpm:create-epics`, `/ghpm:create-tasks`, `/ghpm:tdd-task`
- **ai-context Repository** - Collection of Claude Code plugins
