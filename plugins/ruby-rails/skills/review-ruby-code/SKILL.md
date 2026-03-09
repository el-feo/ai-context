---
name: review-ruby-code
description: Comprehensive Ruby and Rails code review using Sandi Metz rules and SOLID principles. Analyzes changed files in current branch vs base branch, runs rubycritic and simplecov, identifies OOP violations, Rails anti-patterns, security issues, code smells, and test coverage gaps. Outputs REVIEW.md with VSCode-compatible file links. Use when reviewing Ruby/Rails code, conducting code reviews, checking for design issues, pull request review, code quality analysis, or when user mentions Sandi Metz, POODR, 99 Bottles, SOLID, Law of Demeter, or "Tell Don't Ask".
---

# Ruby Code Review

Review Ruby/Rails code changes against Sandi Metz rules, SOLID principles, Rails best practices, and security standards. Generate a structured REVIEW.md with clickable VSCode links.

## Workflow

### 1. Detect scope

```bash
# Auto-detect base branch
git remote show origin | grep 'HEAD branch' | cut -d' ' -f5

# Get changed Ruby files (added/changed/modified/renamed only)
git diff --name-only --diff-filter=ACMR base-branch...HEAD | grep '\.rb$'
```

If not on a feature branch, review files specified by the user.

### 2. Run analysis tools

```bash
# RubyCritic on changed files
rubycritic --format json --no-browser $(git diff --name-only base...HEAD | grep '\.rb$')

# SimpleCov coverage run
COVERAGE=true bundle exec rspec
```

Parse rubycritic JSON for complexity/smells/duplication. Read `coverage/.resultset.json` for per-file coverage and uncovered lines. If tools aren't configured, invoke their respective skills for setup guidance.

Optionally run the bundled static analyzer:
```bash
ruby scripts/code_reviewer.rb <file.rb>
```

### 3. Analyze each changed file

Review in this order for each file:

**OOP Design** — Apply Sandi Metz rules and SOLID principles:
- Classes ≤ 100 lines, methods ≤ 5 lines, parameters ≤ 4, instance variables ≤ 4
- Controllers instantiate ≤ 1 object, views reference ≤ 1 instance variable
- SRP, Open/Closed, Liskov, Interface Segregation, Dependency Inversion
- Law of Demeter ("only talk to immediate friends")
- Tell, Don't Ask (objects make their own decisions)
- See [references/sandi-metz-rules.md](references/sandi-metz-rules.md) and [references/solid-principles.md](references/solid-principles.md)

**Code Smells** — Check for the 18 canonical smells:
- Structural: Long Method, Large Class, Long Parameter List, Data Clump
- Coupling: Feature Envy, Message Chains, Inappropriate Intimacy
- Conditional: Complex conditionals, case statements (polymorphism candidates), speculative generality
- Naming: Vague names (Manager, Handler, Processor), methods with "and", flag parameters
- See [references/sandi-metz-rules.md](references/sandi-metz-rules.md) (Code Smells section)

**Rails Patterns** — Detect anti-patterns:
- N+1 queries (missing `includes`/`preload`/`eager_load`)
- Callback overuse (prefer service objects for side effects)
- Fat models (extract to services, queries, presenters, concerns)
- Business logic in controllers
- Missing database indexes
- See [references/rails-patterns.md](references/rails-patterns.md)

**Security** — Flag vulnerabilities:
- SQL injection (string interpolation in queries)
- XSS (`html_safe`/`raw` on user input)
- Mass assignment (missing strong parameters, `permit!`)
- Authorization gaps (missing checks, inconsistent patterns)
- See [references/security-checklist.md](references/security-checklist.md)

**Test Coverage** — Cross-reference with simplecov:
- Untested methods and uncovered lines
- Missing edge case and error path coverage
- Test quality (implementation vs behavior testing, excessive mocking)

### 4. Check codebase patterns

Before making suggestions, understand existing patterns:

```bash
ls app/services/ app/queries/ app/decorators/ app/presenters/ app/policies/ 2>/dev/null
```

Ensure recommendations align with established patterns (naming conventions, abstraction layers, test framework usage). Don't suggest decorators if the codebase uses presenters.

### 5. Generate REVIEW.md

Every code reference MUST use VSCode-compatible links:
```markdown
[description](file:///absolute/path/to/file.rb#L42)
```
See [references/vscode-links.md](references/vscode-links.md) for format details.

Use severity levels for findings:
- **Error**: Serious violations (security, accessing internals, tight coupling)
- **Warning**: Rule violations that should be fixed
- **Info**: Suggestions and best practices
- **Pass**: Correctly following principles

```markdown
# Code Review - [Branch Name]

**Base Branch**: [detected-branch]
**Changed Files**: [count]
**Review Date**: [date]

---

## Summary

[High-level overview of changes and main findings]

## Critical Issues

[Security vulnerabilities, major bugs requiring immediate attention]

## Design & Architecture

### OOP Violations
[Sandi Metz rule and SOLID violations with VSCode links and severity]

### Code Smells
[Detected smells with specific refactoring suggestions]

### Rails Patterns
[N+1 queries, callback issues, anti-patterns with VSCode links]

## Security Concerns

[Vulnerabilities with VSCode links]

## Test Coverage

[Coverage gaps, missing tests, quality issues with VSCode links]

## Tool Reports

### RubyCritic Summary
- **Complexity**: [score]
- **Duplication**: [score]
- **Code Smells**: [count]

### SimpleCov Summary
- **Total Coverage**: [percentage]
- **Files with < 90% coverage**: [list]

---

## Recommendations

[Prioritized improvements aligned with codebase patterns]

## Positive Observations

[Well-designed code, good patterns, improvements from previous reviews]
```

### 6. Validate

Before finalizing:
- [ ] Every code reference has a clickable VSCode link with absolute path
- [ ] All changed files reviewed
- [ ] RubyCritic and SimpleCov findings incorporated
- [ ] Suggestions match existing codebase patterns
- [ ] Positive observations included

## Reference Guides

- [references/sandi-metz-rules.md](references/sandi-metz-rules.md) — Five rules, Law of Demeter, Tell Don't Ask, code smells, Shameless Green philosophy
- [references/solid-principles.md](references/solid-principles.md) — SOLID principles with Ruby examples
- [references/rails-patterns.md](references/rails-patterns.md) — Rails anti-patterns, N+1 queries, callbacks, service objects
- [references/security-checklist.md](references/security-checklist.md) — SQL injection, XSS, mass assignment, auth vulnerabilities
- [references/vscode-links.md](references/vscode-links.md) — VSCode link format and examples
