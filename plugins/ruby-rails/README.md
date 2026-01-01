# jebs-dev-tools:ruby-rails

Ruby on Rails development toolkit for Claude Code.

## Features

### Skills (11)

- **rails** - Comprehensive Rails v8.1 development guide
- **ruby** - Ruby language fundamentals and design patterns
- **rspec** - RSpec testing patterns and best practices
- **rubocop** - Ruby linting and code style
- **rubycritic** - Code quality analysis
- **simplecov** - Test coverage analysis
- **brakeman** - Rails security vulnerability scanner
- **rails-generators** - Creating custom Rails generators
- **sandi-metz-reviewer** - OO design principles from POODR and 99 Bottles
- **review-ruby-code** - Code review with Sandi Metz rules
- **postgresql-rails-analyzer** - PostgreSQL optimization for Rails

### Commands (3)

- `/red-green-refactor` - Start a TDD session
- `/review-ruby-code` - Code review with Sandi Metz principles
- `/rails-generators` - Create Rails generators

### Agents (1)

- **rails-generator** - Specialized agent for creating Rails generators

## Installation

To use this plugin with Claude Code:

```bash
# Install via plugin directory
cc --plugin-dir /path/to/plugins/ruby-rails
```

Or copy to your project:

```bash
cp -r plugins/ruby-rails/.claude-plugin /your/project/
```

## Usage

Once installed, skills trigger automatically when relevant topics are discussed. Commands can be invoked with:

```
/red-green-refactor
/review-ruby-code
/rails-generators
```
