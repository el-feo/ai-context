# AI Context

A collection of skills, commands, rules, and prompts for enhancing developer productivity with Claude Code and other LLM-powered development tools.

## Overview

AI Context provides reusable components that can be copied or installed into your projects to standardize AI-assisted development workflows. The repository focuses primarily on Ruby/Rails development but includes support for JavaScript/TypeScript and other technologies.

## Repository Structure

```text
ai-context/
├── skills/          # Claude Code skills (SKILL.md + references/)
├── commands/        # Slash command definitions
├── rules/           # Coding rules and guidelines
├── agents/          # Agent configurations for specialized tasks
├── prompts/         # Reusable prompt templates
├── tools/           # Helper scripts
└── config/          # Configuration files (e.g., mcp.json)
```

## Skills

Skills are structured documentation that Claude Code uses to provide expert guidance on specific topics. Each skill contains a `SKILL.md` file with optional `references/` subdirectory for detailed documentation.

### Ruby/Rails

| Skill                       | Description                                            |
| --------------------------- | ------------------------------------------------------ |
| `rails`                     | Ruby on Rails v8.1 development guide                   |
| `ruby`                      | Ruby language fundamentals and design patterns         |
| `rspec`                     | RSpec testing patterns and best practices              |
| `rubocop`                   | Ruby linting and code style                            |
| `rubycritic`                | Code quality analysis                                  |
| `simplecov`                 | Test coverage analysis                                 |
| `brakeman`                  | Rails security vulnerability scanner                   |
| `rails-generators`          | Creating custom Rails generators                       |
| `sandi-metz-reviewer`       | OO design principles from POODR and 99 Bottles         |
| `review-ruby-code`          | Code review with Sandi Metz rules and SOLID principles |
| `postgresql-rails-analyzer` | PostgreSQL optimization for Rails                      |

### JavaScript/TypeScript

| Skill                     | Description                                 |
| ------------------------- | ------------------------------------------- |
| `eslint`                  | JavaScript/TypeScript linting               |
| `vitest`                  | Vitest testing framework and Jest migration |
| `javascript-unit-testing` | Unit testing patterns with Jest             |

### DevOps & Infrastructure

| Skill            | Description                     |
| ---------------- | ------------------------------- |
| `github-actions` | CI/CD workflow creation         |
| `kamal`          | Docker deployment configuration |
| `tailscale`      | VPN setup and configuration     |

### General

| Skill              | Description                |
| ------------------ | -------------------------- |
| `mermaid-diagrams` | Creating software diagrams |

## Commands

Slash commands for Claude Code workflows. Copy to `.claude/commands/` in your project.

### GitHub Project Management (GHPM)

A complete workflow for product development:

```text
/ghpm:create-prd    → Create product requirements document
/ghpm:create-epics  → Break PRD into GitHub epics
/ghpm:create-tasks  → Break epics into actionable tasks
/ghpm:tdd-task      → Execute task using TDD workflow
```

Install all GHPM commands:

```bash
chmod +x commands/ghpm/scripts/install-ghpm-claude-commands.sh
./commands/ghpm/scripts/install-ghpm-claude-commands.sh
```

### Development Workflow Commands

| Command               | Description                            |
| --------------------- | -------------------------------------- |
| `/red-green-refactor` | Start a TDD session                    |
| `/review-ruby-code`   | Code review with Sandi Metz principles |
| `/rails-generators`   | Create Rails generators                |
| `/vitest`             | Migrate from Jest to Vitest            |

### GitHub Integration Commands

| Command            | Description                           |
| ------------------ | ------------------------------------- |
| `/gh-plan-product` | Product planning with GitHub Projects |
| `/gh-create-epic`  | Create GitHub epic issue              |
| `/gh-execute`      | Execute a GitHub issue                |
| `/gh-finish-task`  | Create PR and update issue            |
| `/gh-tdd`          | TDD workflow with GitHub integration  |

## Rules

Coding guidelines and best practices. Reference in your project's `CLAUDE.md` or copy to your project.

| Rule                    | Description                       |
| ----------------------- | --------------------------------- |
| `ruby_rules.md`         | Rails conventions and code style  |
| `oop_rules.md`          | OO design principles (Sandi Metz) |
| `rspec_rules.md`        | RSpec testing patterns            |
| `ruby_tdd_process.md`   | TDD workflow guidelines           |
| `cursor_memory_bank.md` | Context management for Cursor     |
| `experimental_rules.md` | Experimental coding rules         |

## Agents

Agent configurations for specialized tasks:

- `qa_planner.md` - QA test planning
- `rails-generator-agent.md` - Rails generator creation

## Installation

### Skills

Copy skill directories to `.claude/skills/` in your project:

```bash
cp -r skills/rails /path/to/your/project/.claude/skills/
```

### Commands

Copy command files to `.claude/commands/` in your project:

```bash
cp commands/red-green-refactor.md /path/to/your/project/.claude/commands/
```

### Rules

Reference rules in your project's `CLAUDE.md`:

```markdown
## Rules

Follow the guidelines in:
- [Ruby Rules](path/to/ruby_rules.md)
- [OOP Rules](path/to/oop_rules.md)
```

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/new-skill`)
3. Add or modify content
4. Commit your changes
5. Push to the branch
6. Open a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.
