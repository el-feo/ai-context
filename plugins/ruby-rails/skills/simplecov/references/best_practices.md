# SimpleCov Best Practices

## Table of Contents

- [1. Start Early](#1-start-early)
- [2. Set Achievable Thresholds](#2-set-achievable-thresholds)
- [3. Track Both Line and Branch Coverage](#3-track-both-line-and-branch-coverage)
- [4. Prioritize Business Logic](#4-prioritize-business-logic)
- [5. Make Coverage Part of Code Review](#5-make-coverage-part-of-code-review)
- [6. Don't Chase 100% Blindly](#6-dont-chase-100-blindly)
- [7. Use Appropriate Grouping](#7-use-appropriate-grouping)
- [8. Filter Wisely](#8-filter-wisely)
- [9. Merge All Test Suites](#9-merge-all-test-suites)
- [10. Enforce in CI/CD](#10-enforce-in-cicd)

## 1. Start Early

Set up SimpleCov at project inception to establish baselines and track progress from day one.

## 2. Set Achievable Thresholds

Start with realistic targets (80-85%) and increase gradually. Avoid demanding 100% immediately.

## 3. Track Both Line and Branch Coverage

Branch coverage reveals untested conditional paths that line coverage misses.

```ruby
minimum_coverage line: 90, branch: 80
```

## 4. Prioritize Business Logic

Focus coverage efforts on:

- Domain models
- Service objects
- Complex calculations
- Critical user flows

Less critical:

- View helpers
- Configuration files
- Simple CRUD controllers

## 5. Make Coverage Part of Code Review

Include coverage reports in PR reviews. Block PRs that drop coverage without justification.

```ruby
refuse_coverage_drop :line, :branch
```

## 6. Don't Chase 100% Blindly

Focus on meaningful tests over coverage percentage. Some code (error logging, debugging helpers) may not need testing.

## 7. Use Appropriate Grouping

Organize reports by architecture to identify weak layers:

```ruby
add_group "Domain Models", "app/models"
add_group "Business Logic", "app/services"
add_group "Background Jobs", "app/jobs"
add_group "API", "app/controllers/api"
```

## 8. Filter Wisely

Exclude generated code, migrations, and test infrastructure:

```ruby
add_filter '/db/migrate/'
add_filter '/test/'
add_filter '/config/initializers/'
add_filter '/vendor/'
```

## 9. Merge All Test Suites

Ensure coverage reflects complete test suite execution:

```bash
bundle exec rake test      # Unit/integration
bundle exec rspec          # Specs
bundle exec cucumber       # Features
# SimpleCov merges automatically
```

## 10. Enforce in CI/CD

Prevent coverage degradation by failing builds:

```ruby
if ENV['CI']
  minimum_coverage line: 90, branch: 80
  refuse_coverage_drop :line, :branch
end
```
