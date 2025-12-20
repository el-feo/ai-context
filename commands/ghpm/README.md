# GHPM - GitHub Project Manager for Claude Code

GHPM provides slash commands for managing product development workflows in GitHub. It enables a structured flow from PRD → Epics → Tasks → TDD implementation, with conventional commits for automated changelog generation.

## Installation

Copy the command files to your repository:

```bash
# From the ghpm directory
chmod +x scripts/install-ghpm-claude-commands.sh
./scripts/install-ghpm-claude-commands.sh /path/to/your/repo
```

This installs the following commands to `.claude/commands/`:

- `ghpm:create-prd.md`
- `ghpm:create-epics.md`
- `ghpm:create-tasks.md`
- `ghpm:execute.md`
- `ghpm:tdd-task.md`
- `ghpm:changelog.md`
- `ghpm:qa-create.md`
- `ghpm:qa-create-steps.md`
- `ghpm:qa-execute.md`

## Commands

| Command | Description |
|---------|-------------|
| `/ghpm:create-prd <prompt>` | Create a Product Requirements Document |
| `/ghpm:create-epics [prd=#N]` | Break PRD into Epics |
| `/ghpm:create-tasks [epic=#N\|prd=#N]` | Break Epics into atomic Tasks |
| `/ghpm:execute [task=#N\|epic=#N]` | Execute Task (routes to TDD or non-TDD workflow) |
| `/ghpm:tdd-task [task=#N]` | Implement Task using TDD |
| `/ghpm:changelog [from=ref] [to=ref]` | Generate changelog from commits |
| `/ghpm:qa-create [prd=#N]` | Create QA Issue for PRD acceptance testing |
| `/ghpm:qa-create-steps [qa=#N]` | Create QA Steps for QA Issue |
| `/ghpm:qa-execute [qa=#N\|step=#N]` | Execute QA Steps with Playwright automation |

## Setup (Optional)

### GitHub Project Association

Set an environment variable to automatically add issues to a GitHub Project (use project number):

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

## Workflow

GHPM supports two parallel workflows that start from a PRD:

```
                              ┌─────────────────┐
                              │      PRD        │
                              └────────┬────────┘
                                       │
              ┌────────────────────────┼────────────────────────┐
              │                        │                        │
              ▼                        ▼                        ▼
       ┌────────────┐           ┌────────────┐           ┌────────────┐
       │   Epic 1   │           │   Epic 2   │           │     QA     │
       └─────┬──────┘           └─────┬──────┘           └─────┬──────┘
             │                        │                        │
             ▼                        ▼                        ▼
       ┌────────────┐           ┌────────────┐           ┌────────────┐
       │   Tasks    │           │   Tasks    │           │  QA Steps  │
       └─────┬──────┘           └─────┬──────┘           └─────┬──────┘
             │                        │                        │
             ▼                        ▼                        ▼
       ┌────────────┐           ┌────────────┐           ┌────────────┐
       │    TDD     │           │    TDD     │           │  Execute   │
       └────────────┘           └────────────┘           └─────┬──────┘
                                                               │
                                                        ┌──────┴──────┐
                                                        │    Bugs     │
                                                        └─────────────┘
```

### Implementation Workflow (Left Path)

1. **Create PRD** - Define product requirements with `/ghpm:create-prd`
2. **Create Epics** - Break down PRD into epics with `/ghpm:create-epics`
3. **Create Tasks** - Decompose epics into tasks with `/ghpm:create-tasks`
4. **Implement** - Execute tasks using TDD with `/ghpm:tdd-task`
5. **Generate Changelog** - Create release notes with `/ghpm:changelog`

### QA Workflow (Right Path)

1. **Create QA Issue** - Create acceptance testing issue with `/ghpm:qa-create`
2. **Create QA Steps** - Generate Given/When/Then test steps with `/ghpm:qa-create-steps`
3. **Execute QA** - Run Playwright automation with `/ghpm:qa-execute`
4. **Bug Handoff** - Failed steps create Bug issues that can become Tasks

### When to Use Each Workflow

| Workflow | Use When |
|----------|----------|
| **Implementation** | Building new features, fixing bugs, refactoring code |
| **QA** | Acceptance testing, end-to-end validation, regression testing |

The QA workflow runs **parallel** to implementation - you can start QA testing as soon as a PRD is created, without waiting for implementation to complete. Bugs found during QA become new Tasks that feed back into the implementation workflow

## Issue Templates

GHPM creates GitHub issues using streamlined templates designed to minimize verbosity while providing all context needed for implementation.

### Design Principles

1. **Single Parent Link**: Each issue links only to its direct parent (Task → Epic, Epic → PRD). Ancestor context is reachable via navigation.
2. **No Redundancy**: Information in parent issues is not duplicated in children.
3. **Conditional Sections**: Optional sections are omitted when empty.
4. **Agent-Ready**: Tasks contain everything needed to begin implementation without reading parent issues.

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

### Sections Intentionally Omitted

These sections are excluded to reduce noise:

| Section | Reason |
|---------|--------|
| Out of Scope | Inherited from parent issue |
| Risks / Edge Cases | Inherited from PRD |
| Notes / Open Questions | Use issue comments instead |
| Key Requirements | Merged into Scope |
| Implementation Notes | Use issue comments if needed |

## Task Estimation

Tasks are assigned Fibonacci estimates (1, 2, 3, 5, 8) to enable sprint planning and velocity tracking. Estimates reflect relative complexity, not hours.

### Estimation Scale

| Estimate | Complexity | Examples |
|----------|------------|----------|
| **1** | Trivial | Update README, fix typo, change config value |
| **2** | Simple | Add a single test, update documentation section |
| **3** | Moderate | Add simple feature, refactor small module |
| **5** | Complex | Multi-file feature, significant refactor |
| **8** | Very Complex | Cross-cutting feature, complex integration |

### Decomposition Rule

**Tasks that would exceed an estimate of 8 must be broken into smaller tasks.** This ensures all work is tractable and can be completed in a reasonable timeframe.

### GitHub Project Setup

To track estimates in GitHub Projects, add a Number field named "Estimate":

1. Open your GitHub Project
2. Click **+** to add a new field
3. Select **Number** as the field type
4. Name it exactly: `Estimate`

When `GHPM_PROJECT` is set, `/ghpm:create-tasks` will automatically populate this field for each task.

## Conventional Commits

All commits and PR titles follow [Conventional Commits](https://www.conventionalcommits.org/) format:

```
<type>(<scope>): <description> (#<issue>)
```

| Type | Description |
|------|-------------|
| `feat` | New feature |
| `fix` | Bug fix |
| `refactor` | Code restructuring |
| `test` | Tests only |
| `docs` | Documentation |
| `chore` | Build/CI/tooling |

This enables automated changelog generation via `/ghpm:changelog` or tools like [release-please](https://github.com/googleapis/release-please).
