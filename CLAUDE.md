# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Purpose

AI Context is a collection of tools, prompts, rules, skills, and commands designed to enhance developer productivity when working with LLMs. The content here is meant to be copied or installed into other projects to provide standardized AI interaction patterns.

## Repository Structure

```
ai-context/
├── skills/          # Claude Code skills (SKILL.md + references/)
├── commands/        # Slash command definitions (.md files)
├── rules/           # Editor-agnostic coding rules and guidelines
├── agents/          # Agent configurations for specialized tasks
├── prompts/         # Reusable prompt templates
├── tools/           # Helper scripts (e.g., analyze_coverage.rb)
└── config/          # Configuration files (e.g., mcp.json)
```

### Skills

Skills are organized as directories containing a `SKILL.md` file with optional `references/` subdirectory for detailed documentation. Major skills include:

- **rails**: Ruby on Rails v8.1 development guide
- **rspec**: RSpec testing patterns and best practices
- **ruby**: Ruby language fundamentals and design patterns
- **rubocop/rubycritic/simplecov**: Code quality tools
- **github-actions**: CI/CD workflow creation
- **kamal**: Deployment configuration

### Commands

Slash commands for Claude Code workflows:

- `gh-*` commands: GitHub project management (create epics, execute tasks, TDD workflow)
- `ghpm/*` commands: GitHub PM workflow (PRD → Epics → Tasks → TDD)
- `red-green-refactor`: TDD session management
- `review-ruby-code`: Code review with Sandi Metz principles

### Rules

Coding guidelines and best practices:

- `ruby_rules.md`: Rails conventions, code style, testing
- `oop_rules.md`: Object-oriented design principles from "99 Bottles of OOP" and "POODR"
- `ruby_tdd_process.md`: TDD workflow guidelines
- `rspec_rules.md`: RSpec testing patterns

## Key Patterns

### Ruby/Rails Development

Follow Sandi Metz rules and SOLID principles:

- Classes have single responsibility
- Inject dependencies to reduce coupling
- Use polymorphism over conditionals
- Name methods at one higher level of abstraction
- Manage duplication strategically (don't abstract prematurely)

### TDD Workflow

The repository emphasizes red-green-refactor TDD:

1. **Red**: Write a failing test for smallest unit of functionality
2. **Green**: Write minimal code to pass the test
3. **Refactor**: Clean up while keeping tests green

### GitHub Project Management (GHPM)

Workflow for product development:

1. `/ghpm:create-prd` - Create product requirements document
2. `/ghpm:create-epics` - Break PRD into epics
3. `/ghpm:create-tasks` - Break epics into tasks
4. `/ghpm:tdd-task` - Execute task using TDD

## Usage

To use content from this repository in another project:

1. Copy relevant skill directories to `.claude/skills/`
2. Copy command files to `.claude/commands/`
3. Reference rules in project CLAUDE.md or copy to project rules

For GHPM commands specifically, run the install script:

```bash
chmod +x commands/ghpm/scripts/install-ghpm-claude-commands.sh
./commands/ghpm/scripts/install-ghpm-claude-commands.sh
```
