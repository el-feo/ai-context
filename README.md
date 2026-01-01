# AI Context (aka jebs-dev-tools)

A collection of Claude Code plugins for enhancing developer productivity with AI-assisted development workflows.

## Overview

AI Context provides modular Claude Code plugins that can be installed into your projects. The repository focuses primarily on Ruby/Rails development but includes support for JavaScript/TypeScript and other technologies.

## Claude Code Plugins

This repository contains 5 modular Claude Code plugins under `plugins/`:

| Plugin       | Description                        | Skills | Commands | Agents |
| ------------ | ---------------------------------- | ------ | -------- | ------ |
| `ruby-rails` | Ruby on Rails development toolkit  | 11     | 3        | 1      |
| `ghpm`       | GitHub Project Management workflow | 0      | 10       | 0      |
| `js-ts`      | JavaScript/TypeScript toolkit      | 3      | 1        | 0      |
| `devops`     | DevOps & infrastructure toolkit    | 3      | 1        | 0      |
| `general`    | General development utilities      | 1      | 0        | 0      |

## Installation

### From GitHub (Recommended)

```bash
# Add the marketplace
/plugin marketplace add el-feo/ai-context

# Install individual plugins
/plugin install ruby-rails@jebs-dev-tools
/plugin install ghpm@jebs-dev-tools
/plugin install js-ts@jebs-dev-tools
/plugin install devops@jebs-dev-tools
/plugin install general@jebs-dev-tools
```

### Local Installation

```bash
# Add local marketplace
/plugin marketplace add /path/to/ai-context

# Then install plugins
/plugin install ruby-rails@jebs-dev-tools
```

### Direct Plugin Directory

```bash
# Use a specific plugin directly
cc --plugin-dir /path/to/ai-context/plugins/ruby-rails
```

## Repository Structure

```text
ai-context/
├── .claude-plugin/
│   └── marketplace.json  # Marketplace index
├── plugins/
│   ├── ruby-rails/       # Ruby/Rails development
│   ├── ghpm/             # GitHub Project Management
│   ├── js-ts/            # JavaScript/TypeScript
│   ├── devops/           # DevOps & infrastructure
│   └── general/          # General utilities
└── tools/                # Helper scripts
```

## Plugin Details

### ruby-rails

Ruby on Rails development toolkit with skills for Rails, Ruby, RSpec, RuboCop, SimpleCov, Brakeman, and code review with Sandi Metz principles.

**Skills:** rails, ruby, rspec, rubocop, rubycritic, simplecov, brakeman, rails-generators, sandi-metz-reviewer, review-ruby-code, postgresql-rails-analyzer

**Commands:** `/red-green-refactor`, `/review-ruby-code`, `/rails-generators`

**Agents:** rails-generator

### ghpm

GitHub Project Management workflow for product development: PRD creation, epic/task breakdown, TDD execution, and QA planning.

**Commands:** `/ghpm:create-prd`, `/ghpm:create-epics`, `/ghpm:create-tasks`, `/ghpm:create-project`, `/ghpm:execute`, `/ghpm:tdd-task`, `/ghpm:changelog`, `/ghpm:qa-create`, `/ghpm:qa-create-steps`, `/ghpm:qa-execute`

### js-ts

JavaScript and TypeScript development toolkit with ESLint, Vitest, and unit testing best practices.

**Skills:** eslint, vitest, javascript-unit-testing

**Commands:** `/vitest`

### devops

DevOps and infrastructure toolkit with GitHub Actions, Kamal deployment, and Tailscale VPN configuration.

**Skills:** github-actions, kamal, tailscale

**Commands:** `/github-actions`

### general

General development utilities including Mermaid diagram creation.

**Skills:** mermaid-diagrams

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/new-skill`)
3. Add or modify content
4. Commit your changes
5. Push to the branch
6. Open a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.
