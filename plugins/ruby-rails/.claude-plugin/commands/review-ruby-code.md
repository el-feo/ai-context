---
description: Review Ruby/Rails code with Sandi Metz rules and SOLID principles
argument-hint: [optional: specific files or all changes]
allowed-tools: Skill(review-ruby-code)
---

<objective>
Delegate Ruby and Rails code review to the review-ruby-code skill for: $ARGUMENTS

This routes to specialized skill containing OOP design principles, Rails patterns, security checks, and code review best practices. The skill will analyze changed files in the current branch, run rubycritic and simplecov, and generate a comprehensive REVIEW.md with VSCode-compatible links.
</objective>

<process>
1. Use Skill tool to invoke review-ruby-code skill
2. Pass user's request: $ARGUMENTS
3. Let skill handle workflow:
   - Detect base branch from git
   - Identify changed files
   - Run rubycritic and simplecov
   - Analyze OOP design, Rails patterns, security, and test coverage
   - Generate REVIEW.md with clickable links to code
</process>

<success_criteria>
- Skill successfully invoked
- Arguments passed correctly to skill
- REVIEW.md generated with comprehensive code review
- All code references have VSCode-compatible links
</success_criteria>
