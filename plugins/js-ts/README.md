# js-ts

JavaScript and TypeScript development toolkit for Claude Code.

## Installation

```bash
# From GitHub
/plugin marketplace add el-feo/ai-context
/plugin install js-ts@jebs-dev-tools

# Or use directly
cc --plugin-dir /path/to/plugins/js-ts
```

## Features

### Skills (3)
- **eslint** - JavaScript/TypeScript linting with ESLint
- **vitest** - Vitest testing framework and Jest migration
- **javascript-unit-testing** - Unit testing patterns with Jest

### Commands (1)
- `/vitest` - Migrate from Jest to Vitest

## Usage

Skills trigger automatically when working with JavaScript/TypeScript code. Use the vitest command to migrate Jest tests:

```
/vitest
```
