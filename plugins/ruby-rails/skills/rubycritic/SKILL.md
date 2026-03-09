---
name: rubycritic
description: Integrate RubyCritic to analyze Ruby code quality and maintain high standards throughout development. Use when working on Ruby projects to check code smells, complexity, and duplication. Triggers include creating/editing Ruby files, refactoring code, reviewing code quality, or when user requests code analysis or quality checks.
---

# RubyCritic Code Quality Analysis

## Quick Start

Run quality check on Ruby files:

```bash
scripts/check_quality.sh [path/to/ruby/files]
```

Analyzes the current directory if no path provided. Auto-installs RubyCritic if missing.

Check recently modified files:

```bash
scripts/check_quality.sh $(git diff --name-only | grep '\.rb$')
```

## Workflow

Run RubyCritic automatically:
- After creating new Ruby files or classes
- After implementing complex methods (>10 lines)
- After refactoring existing code
- Before marking tasks as complete

**Skip for**: simple variable renames, comment changes, minor formatting.

## Interpreting Results

- **Score 90+**: Good. Score 95+ is excellent.
- **Score 80-89**: Consider refactoring.
- **Below 80**: Prioritize improvements.
- **File ratings**: A/B acceptable, C needs attention, D/F requires refactoring.

RubyCritic combines three analyzers:
- **Reek** (code smells) - design and readability issues
- **Flog** (complexity) - overly complex methods
- **Flay** (duplication) - repeated code patterns

## Responding to Issues

Fix in priority order: high complexity > duplication > code smells > style.

Fix one issue at a time, re-run after each fix, verify score improves.

## References

- [references/code_smells.md](references/code_smells.md) - Common smells with before/after examples
- [references/configuration.md](references/configuration.md) - `.rubycritic.yml` options, CI mode, score calculation
- [references/git-hooks.md](references/git-hooks.md) - Pre-commit hooks and CI/CD integration
- [references/error-handling.md](references/error-handling.md) - Troubleshooting installation and analysis errors
