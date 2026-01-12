# ghpm

GitHub Project Management workflow for Claude Code. Provides slash commands for managing product development workflows in GitHub with a structured flow from PRD -> Epics -> Tasks -> TDD implementation, with conventional commits for automated changelog generation.

## Why did I create this?

[Spec-driven development](https://martinfowler.com/articles/exploring-gen-ai/sdd-3-tools.html) is proving effective for coding agents, tools like [agent-os](https://github.com/buildermethods/agent-os) and the [BMAD Method](https://github.com/bmad-code-org/BMAD-METHOD) demonstrate this. But existing solutions have drawbacks:

- **Complexity**: Most frameworks are elaborate and tailored for solo developers
- **File-based storage**: Markdown files in the repo don't scale for teams
- **Context management**: LLMs benefit from persistent memory with fresh contexts

GitHub Issues solve all of this. They're freely available, give you a proper UI for team backlog grooming, and let developers work the way they already do, whether collaborating on a team or flying solo.

## Installation

```bash
# From GitHub
/plugin marketplace add el-feo/ai-context
/plugin install ghpm@jebs-dev-tools

# Or use directly
cc --plugin-dir /path/to/plugins/ghpm
```

## Commands (10)

| Command                                | Description                                      |
| -------------------------------------- | ------------------------------------------------ |
| `/ghpm:create-project [title]`         | Create a GitHub Project and link to repository   |
| `/ghpm:create-prd <prompt>`            | Create a Product Requirements Document           |
| `/ghpm:create-epics [prd=#N]`          | Break PRD into Epics                             |
| `/ghpm:create-tasks [epic=#N\|prd=#N]` | Break Epics into atomic Tasks                    |
| `/ghpm:execute [task=#N\|epic=#N]`     | Execute Task (routes to TDD or non-TDD workflow) |
| `/ghpm:tdd-task [task=#N]`             | Implement Task using TDD                         |
| `/ghpm:changelog [from=ref] [to=ref]`  | Generate changelog from commits                  |
| `/ghpm:qa-create [prd=#N]`             | Create QA Issue for PRD acceptance testing       |
| `/ghpm:qa-create-steps [qa=#N]`        | Create QA Steps for QA Issue                     |
| `/ghpm:qa-execute [qa=#N\|step=#N]`    | Execute QA Steps with Playwright automation      |

## Setup (Optional)

### Creating a GitHub Project

Use `/ghpm:create-project` to create a new GitHub Project and link it to your repository:

```bash
/ghpm:create-project My Roadmap
```

The command can copy from a template project if one exists. To use templates:

```bash
export GHPM_TEMPLATE_PROJECT="7"       # Template project number
export GHPM_TEMPLATE_OWNER="my-org"    # Template project owner
```

**Note:** Project templates are only available for **organizations**. Personal user accounts cannot mark projects as templates via the CLI.

### GitHub Project Association

Set an environment variable to automatically add issues to a GitHub Project:

```bash
export GHPM_PROJECT=7  # Your project number (visible in project URL)
```

### Recommended Labels

Create these labels once per repository:

```bash
gh label create PRD     --description "Product Requirements Document" --color 0E8A16
gh label create Epic    --description "Epic-level work" --color 1D76DB
gh label create Task    --description "Atomic unit of work" --color FBCA04
gh label create QA      --description "QA Issue for acceptance testing" --color 6B3FA0
gh label create QA-Step --description "QA Step for acceptance testing" --color 9B59B6
gh label create QA-Bug  --description "Bug found via QA automation" --color B60205
```

## Issue Claiming

GHPM commands automatically claim issues before work begins to prevent duplicate work and enable progress tracking. This is especially useful for teams where multiple agents or developers may work on tasks concurrently.

### How Claiming Works

When you run `/ghpm:execute`, `/ghpm:tdd-task`, or `/ghpm:qa-execute`:

1. The command checks if you're already assigned to the issue
2. If unassigned, it assigns you and posts an audit comment
3. If assigned to someone else, the command aborts with a clear message

### Claiming Behavior by Command

| Command | Claiming Behavior |
|---------|-------------------|
| `/ghpm:tdd-task task=#N` | Claims task before TDD plan is posted |
| `/ghpm:execute task=#N` | Claims task before context hydration |
| `/ghpm:execute epic=#N` | Claims each sub-task sequentially as work begins (not all at once) |
| `/ghpm:qa-execute step=#N` | Claims step before Playwright execution |
| `/ghpm:qa-execute qa=#N` | Claims each step only when its execution begins |

### UX Output

| Scenario | Output |
|----------|--------|
| New claim | `Assigned to @username` |
| Already yours | `Already assigned to you (@username)` |
| Conflict | `ERROR: Task #N is already claimed by @another-user` |

### Project Status Updates

When `GHPM_PROJECT` is set, GHPM attempts to update the issue's project status to "In Progress" when claiming. This is best-effort and may require manual verification.

### Conflict Resolution

If a task is assigned to another user and you need to take over:

1. Coordinate with the current assignee
2. Unassign them: `gh issue edit #N --remove-assignee @username`
3. Run the GHPM command again to claim it

### Orphaned State Warning

If an issue has "In Progress" status but no assignee, GHPM will warn:

```
Warning: Task #N has status 'In Progress' but no assignee
```

This indicates someone may have started work but didn't properly claim the issue.

## Workflow

GHPM supports two parallel workflows that start from a PRD:

```
                              +------------------+
                              |      PRD         |
                              +---------+--------+
                                        |
              +-------------------------+-------------------------+
              |                         |                         |
              v                         v                         v
       +------------+            +------------+            +------------+
       |   Epic 1   |            |   Epic 2   |            |     QA     |
       +-----+------+            +-----+------+            +-----+------+
             |                         |                         |
             v                         v                         v
       +------------+            +------------+            +------------+
       |   Tasks    |            |   Tasks    |            |  QA Steps  |
       +-----+------+            +-----+------+            +-----+------+
             |                         |                         |
             v                         v                         v
       +------------+            +------------+            +------------+
       |Execute/TDD |            |Execute/TDD |            | QA Execute |
       +------------+            +------------+            +-----+------+
                                                                 |
                                                          +------+------+
                                                          |    Bugs     |
                                                          +-------------+
```

### Implementation Workflow (Left Path)

1. **Create Project** - Set up GitHub Project with `/ghpm:create-project` (optional)
2. **Create PRD** - Define product requirements with `/ghpm:create-prd`
3. **Create Epics** - Break down PRD into epics with `/ghpm:create-epics`
4. **Create Tasks** - Decompose epics into tasks with `/ghpm:create-tasks`
5. **Implement** - Execute tasks using either:
   - `/ghpm:execute` - Auto-routes to TDD or non-TDD based on commit type
   - `/ghpm:tdd-task` - Direct TDD workflow for code tasks
6. **Generate Changelog** - Create release notes with `/ghpm:changelog`

### Execute Command Routing

`/ghpm:execute` intelligently routes tasks to the appropriate workflow based on commit type and target files:

| Route To                   | Commit Types                             | Target Files                                  |
| -------------------------- | ---------------------------------------- | --------------------------------------------- |
| **TDD** (`/ghpm:tdd-task`) | `feat`, `fix`, `refactor`                | Code files (`.rb`, `.js`, `.ts`, `.py`, etc.) |
| **Non-TDD**                | `test`, `docs`, `chore`, `style`, `perf` | Any                                           |
| **Non-TDD**                | Any                                      | Non-code files (`.md`, `.yml`, `.json`, etc.) |

**Usage:**

```bash
# Execute a single task (auto-routes based on commit type)
/ghpm:execute task=#42

# Execute all tasks under an epic
/ghpm:execute epic=#10

# Auto-resolve task from branch name or GitHub
/ghpm:execute
```

**Direct TDD:** Use `/ghpm:tdd-task` directly when you want TDD workflow without routing.

### QA Workflow (Right Path)

1. **Create QA Issue** - Create acceptance testing issue with `/ghpm:qa-create`
2. **Create QA Steps** - Generate Given/When/Then test steps with `/ghpm:qa-create-steps`
3. **Execute QA** - Run Playwright automation with `/ghpm:qa-execute`
4. **Bug Handoff** - Failed steps create Bug issues that can become Tasks

### When to Use Each Workflow

| Workflow           | Use When                                                      |
| ------------------ | ------------------------------------------------------------- |
| **Implementation** | Building new features, fixing bugs, refactoring code          |
| **QA**             | Acceptance testing, end-to-end validation, regression testing |

The QA workflow runs **parallel** to implementation - you can start QA testing as soon as a PRD is created. Bugs found during QA become new Tasks that feed back into the implementation workflow.

## Issue Templates

GHPM creates GitHub issues using streamlined templates designed to minimize verbosity while providing all context needed for implementation.

### Design Principles

1. **Single Parent Link**: Each issue links only to its direct parent (Task -> Epic, Epic -> PRD)
2. **No Redundancy**: Information in parent issues is not duplicated in children
3. **Conditional Sections**: Optional sections are omitted when empty
4. **Agent-Ready**: Tasks contain everything needed to begin implementation

### Epic Template

```markdown
# Epic: <Name>

**PRD:** #<number>

## Objective
<1-3 sentences: what this Epic accomplishes>

## Scope
<Bulleted list of specific deliverables>

## Acceptance Criteria
- [ ] Criterion 1
- [ ] Criterion 2

## Dependencies
<Only if external dependencies exist; omit if none>
```

### Task Template

```markdown
# Task: <Name>

**Epic:** #<number> | **Type:** `<feat|fix|refactor|test|docs|chore>` | **Scope:** `<module>`

## Objective
<1-2 sentences: what to implement>

## Acceptance Criteria
- [ ] Criterion 1
- [ ] Criterion 2

## Test Plan
<How to verify completion>
```

## Task Estimation

Tasks are assigned Fibonacci estimates (1, 2, 3, 5, 8) to enable sprint planning and velocity tracking. Estimates reflect relative complexity, not hours.

| Estimate | Complexity   | Examples                                        |
| -------- | ------------ | ----------------------------------------------- |
| **1**    | Trivial      | Update README, fix typo, change config value    |
| **2**    | Simple       | Add a single test, update documentation section |
| **3**    | Moderate     | Add simple feature, refactor small module       |
| **5**    | Complex      | Multi-file feature, significant refactor        |
| **8**    | Very Complex | Cross-cutting feature, complex integration      |

**Decomposition Rule:** Tasks that would exceed an estimate of 8 must be broken into smaller tasks.

### GitHub Project Setup

To track estimates in GitHub Projects, add a Number field named "Estimate":

1. Open your GitHub Project
2. Click **+** to add a new field
3. Select **Number** as the field type
4. Name it exactly: `Estimate`

When `GHPM_PROJECT` is set, `/ghpm:create-tasks` will automatically populate this field.

## Review Cycle Coordination

GHPM includes agents that coordinate the automated review → fix → review cycle for PRs, ensuring quality gates are met before merge.

### Agents

| Agent | Purpose |
|-------|---------|
| `pr-review` | Reviews PRs against Task specifications, checks code quality, posts actionable feedback |
| `conflict-resolver` | Detects and resolves merge conflicts, categorizes by complexity |
| `review-cycle-coordinator` | Orchestrates the full review-fix-review cycle with iteration limits |

### Review Cycle Flow

```
┌─────────────┐    ┌────────────┐    ┌───────────────┐
│ PR Created  │───►│ pr-review  │───►│   APPROVED    │───► Merge Ready
└─────────────┘    │   agent    │    └───────────────┘
                   └─────┬──────┘
                         │ CHANGES_REQUESTED
                         ▼
                   ┌───────────────┐
                   │ task-executor │
                   │ fixes issues  │
                   └───────┬───────┘
                           │ (iteration < 3)
                           ▼
                   ┌───────────────┐
                   │   Re-review   │───► (loop back to pr-review)
                   └───────────────┘
                           │ (iteration >= 3)
                           ▼
                   ┌───────────────┐
                   │   ESCALATE    │───► Human Review Required
                   └───────────────┘
```

### Iteration Limits

The review cycle enforces a maximum of 3 iterations before escalating to human review:

| Iteration | Action |
|-----------|--------|
| 1-3 | pr-review-agent posts feedback, task-executor addresses issues |
| 4+ | Cycle terminates with human escalation summary |

### Conflict Handling

When merge conflicts are detected during the review cycle:

1. `conflict-resolver-agent` is invoked automatically
2. **Simple conflicts** (whitespace, imports, lockfiles) are auto-resolved
3. **Complex conflicts** (semantic, deleted vs modified) escalate to human
4. After resolution, the review cycle continues

### Audit Trail

All state transitions are logged in PR comments for full auditability:

```markdown
## Review Cycle Coordinator - Iteration 2

**Status:** CHANGES_REQUESTED → AWAITING_FIXES

### Review Feedback Summary
- [blocking] Missing test coverage for error handling
- [should-fix] Consider extracting validation logic

### Next Steps
The task-executor-agent should address feedback and push commits.
```

### CI Integration

The `ci-check` agent monitors GitHub Actions after PR creation:

1. Waits for CI to complete (up to 10 minutes)
2. Analyzes failures: **in-scope** (related to PR) vs **out-of-scope** (pre-existing)
3. Fixes in-scope failures automatically
4. Creates follow-up issues for out-of-scope failures
5. Posts CI Check Report to the PR

## Conventional Commits

All commits and PR titles follow [Conventional Commits](https://www.conventionalcommits.org/) format:

```
<type>(<scope>): <description> (#<issue>)
```

| Type       | Description        |
| ---------- | ------------------ |
| `feat`     | New feature        |
| `fix`      | Bug fix            |
| `refactor` | Code restructuring |
| `test`     | Tests only         |
| `docs`     | Documentation      |
| `chore`    | Build/CI/tooling   |

This enables automated changelog generation via `/ghpm:changelog` or tools like [release-please](https://github.com/googleapis/release-please).
