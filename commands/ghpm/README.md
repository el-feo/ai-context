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

Set an environment variable to automatically add issues to a GitHub Project:

```bash
export GHPM_PROJECT="Your Project Name"
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
