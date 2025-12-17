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
- `ghpm:tdd-task.md`
- `ghpm:changelog.md`

## Commands

| Command | Description |
|---------|-------------|
| `/ghpm:create-prd <prompt>` | Create a Product Requirements Document |
| `/ghpm:create-epics [prd=#N]` | Break PRD into Epics |
| `/ghpm:create-tasks [epic=#N\|prd=#N]` | Break Epics into atomic Tasks |
| `/ghpm:tdd-task [task=#N]` | Implement Task using TDD |
| `/ghpm:changelog [from=ref] [to=ref]` | Generate changelog from commits |

## Setup (Optional)

### GitHub Project Association

Set an environment variable to automatically add issues to a GitHub Project:

```bash
export GHPM_PROJECT="Your Project Name"
```

### Recommended Labels

Create these labels once per repository:

```bash
gh label create PRD  --description "Product Requirements Document" --color 0E8A16
gh label create Epic --description "Epic-level work" --color 1D76DB
gh label create Task --description "Atomic unit of work" --color FBCA04
```

## Workflow

1. **Create PRD** - Define product requirements with `/ghpm:create-prd`
2. **Create Epics** - Break down PRD into epics with `/ghpm:create-epics`
3. **Create Tasks** - Decompose epics into tasks with `/ghpm:create-tasks`
4. **Implement** - Execute tasks using TDD with `/ghpm:tdd-task`
5. **Generate Changelog** - Create release notes with `/ghpm:changelog`

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

This enables automated changelog generation via `/ghpm:changelog` or tools like [standard-version](https://github.com/conventional-changelog/standard-version).
