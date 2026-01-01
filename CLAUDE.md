# CLAUDE.md

This file provides guidance to Claude Code when working with code in this repository.

## Repository Purpose

AI Context is a collection of Claude Code plugins designed to enhance developer productivity when working with LLMs. The plugins can be installed into other projects to provide standardized AI interaction patterns.

## Repository Structure

```text
ai-context/
├── plugins/
│   ├── ruby-rails/      # Ruby/Rails development (11 skills, 3 commands, 1 agent)
│   ├── ghpm/            # GitHub Project Management (10 commands, 1 agent)
│   ├── js-ts/           # JavaScript/TypeScript (3 skills, 1 command)
│   ├── devops/          # DevOps & infrastructure (3 skills, 1 command)
│   └── general/         # General utilities (1 skill)
└── tools/               # Helper scripts
```

### Plugin Structure

Each plugin follows this structure:

```text
plugins/<name>/
├── README.md
├── .claude-plugin/
│   └── plugin.json      # Plugin manifest
├── skills/              # SKILL.md files with references/
├── commands/            # Slash command definitions
└── agents/              # Agent configurations
```

## Key Plugins

### ruby-rails

Ruby on Rails development toolkit with skills for Rails, Ruby, RSpec, code quality tools, and Sandi Metz principles.

### ghpm

GitHub Project Management workflow:

1. `/ghpm:create-prd` - Create product requirements document
2. `/ghpm:create-epics` - Break PRD into epics
3. `/ghpm:create-tasks` - Break epics into tasks
4. `/ghpm:tdd-task` - Execute task using TDD

### js-ts

JavaScript/TypeScript toolkit with ESLint, Vitest, and unit testing skills.

### devops

DevOps toolkit with GitHub Actions, Kamal deployment, and Tailscale skills.

## Installation

To use plugins from this repository:

```bash
# Add the marketplace (from GitHub)
/plugin marketplace add el-feo/ai-context

# Install individual plugins
/plugin install ruby-rails@jebs-dev-tools
/plugin install ghpm@jebs-dev-tools

# Or use a plugin directory directly
cc --plugin-dir /path/to/ai-context/plugins/ruby-rails
```
