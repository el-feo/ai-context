# ruby-rails

Ruby on Rails development toolkit for Claude Code.

## Installation

```bash
# From GitHub
/plugin marketplace add el-feo/ai-context
/plugin install ruby-rails@jebs-dev-tools

# Or use directly
cc --plugin-dir /path/to/plugins/ruby-rails
```

## Features

### Skills (13)

- **rails** - Comprehensive Rails v8.1 development guide
- **ruby** - Ruby language fundamentals and design patterns
- **rspec** - RSpec testing patterns and best practices
- **testprof** - Diagnose and fix slow RSpec test suites with TestProf
- **rubocop** - Ruby linting and code style
- **rubycritic** - Code quality analysis
- **simplecov** - Test coverage analysis
- **brakeman** - Rails security vulnerability scanner
- **rails-generators** - Creating custom Rails generators
- **review-ruby-code** - Code review with Sandi Metz rules, SOLID, and OO design principles
- **postgresql-rails-analyzer** - PostgreSQL optimization for Rails
- **cucumber-gherkin** - Cucumber/Gherkin BDD authoring
- **design-patterns-ruby** - Gang of Four patterns in Ruby

### Commands (3)

- `/red-green-refactor` - Start a TDD session
- `/review-ruby-code` - Code review with Sandi Metz principles
- `/rails-generators` - Create Rails generators

### Agents (1)

- **rails-generator** - Specialized agent for creating Rails generators

## Usage

Once installed, skills trigger automatically when relevant topics are discussed. Commands can be invoked with:

```
/red-green-refactor
/review-ruby-code
/rails-generators
```
