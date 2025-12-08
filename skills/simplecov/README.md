# SimpleCov Test Coverage Skill

Comprehensive test coverage analysis and improvement for Ruby and Rails applications using SimpleCov and SimpleCov Console formatter.

## What This Skill Does

This skill enables Claude to:

- Set up and configure SimpleCov in Ruby/Rails projects
- Run tests with coverage tracking (line and branch coverage)
- Analyze coverage reports to identify gaps
- Generate targeted test suggestions for uncovered code
- Enforce coverage thresholds and standards
- Merge coverage across multiple test suites
- Integrate coverage tracking into CI/CD pipelines
- Combine with RubyCritic for holistic code quality analysis

## When to Use This Skill

Use this skill when you need to:

- Set up test coverage tracking in a new or existing project
- Understand which code lacks test coverage
- Improve test coverage systematically
- Enforce coverage standards in code reviews
- Integrate coverage checking into CI/CD
- Combine coverage with code quality metrics
- Debug coverage tracking issues
- Configure advanced coverage scenarios (parallel tests, multi-suite merging, etc.)

## Quick Start

### 1. Install SimpleCov

```ruby
# Gemfile
group :test do
  gem 'simplecov', require: false
  gem 'simplecov-console', require: false
end
```

```bash
bundle install
```

### 2. Configure SimpleCov

Create `.simplecov` in project root:

```ruby
SimpleCov.start 'rails' do
  formatter SimpleCov::Formatter::Console

  enable_coverage :branch
  minimum_coverage line: 90, branch: 80

  add_filter '/test/'
  add_filter '/spec/'
end
```

### 3. Load in Test Helper

Add to the **very top** of `test/test_helper.rb` or `spec/spec_helper.rb`:

```ruby
require 'simplecov'
SimpleCov.start 'rails'

# Rest of test helper...
```

### 4. Run Tests

```bash
bundle exec rake test
# or
bundle exec rspec
```

Coverage reports appear in `coverage/` directory.

## Key Features

### Line and Branch Coverage

Track both line execution and conditional branch paths for comprehensive coverage analysis.

### Console Formatter

Get immediate, readable coverage feedback in the terminal without opening HTML reports.

### Coverage Thresholds

Enforce minimum coverage levels and prevent coverage degradation:

```ruby
minimum_coverage line: 90, branch: 80
refuse_coverage_drop :line, :branch
```

### Multi-Suite Merging

Automatically merge coverage from multiple test types (unit, integration, system).

### RubyCritic Integration

Combine coverage metrics with code quality analysis to prioritize improvements effectively.

### CI/CD Ready

Works with GitHub Actions, GitLab CI, CircleCI, Jenkins, and more.

## File Structure

```
simplecov/
├── SKILL.md                              # Main skill documentation
├── README.md                             # This file
├── scripts/
│   └── coverage_analyzer.rb              # Analyzes coverage data, generates reports
├── references/
│   ├── advanced_patterns.md              # Advanced configurations and edge cases
│   ├── ci_cd_integration.md              # CI/CD pipeline integration patterns
│   └── rubycritic_integration.md         # Combining with RubyCritic
└── LICENSE.txt                           # MIT License
```

## Usage Examples

### Ask Claude to Set Up Coverage

```
"Set up SimpleCov in my Rails app with 90% line coverage and 80% branch coverage thresholds"
```

### Analyze Coverage Gaps

```
"Run tests with coverage and show me which files need more tests"
```

### Improve Specific File

```
"The file app/services/payment_processor.rb has 45% coverage. Help me identify what's not covered and write tests for it."
```

### CI Integration

```
"Set up GitHub Actions to run tests with coverage and fail if coverage drops below 90%"
```

### Combined Analysis

```
"Run SimpleCov and RubyCritic together and tell me which files should be prioritized for improvement"
```

## Integration with RubyCritic

This skill works excellently with RubyCritic to provide comprehensive code quality insights:

```bash
# Run tests with coverage
bundle exec rake test

# Run RubyCritic
bundle exec rubycritic app lib

# Combined analysis identifies:
# - High complexity + low coverage = CRITICAL (add tests + refactor)
# - High complexity + high coverage = HIGH (safe to refactor)
# - Low complexity + low coverage = MEDIUM (add tests)
# - Low complexity + high coverage = LOW (well-maintained)
```

See `references/rubycritic_integration.md` for detailed integration patterns.

## Troubleshooting

### Coverage shows 0% or missing files

**Cause**: SimpleCov loaded after application code
**Fix**: Ensure `SimpleCov.start` is the very first thing in test helper, before loading application

### Spring conflicts

**Cause**: Spring's preloading interferes with coverage
**Fix**: Either disable Spring (`DISABLE_SPRING=1`), eager load after SimpleCov starts, or remove Spring

### Parallel test conflicts

**Cause**: Coverage results overwrite each other
**Fix**: Use unique command names: `SimpleCov.command_name "Test #{ENV['TEST_ENV_NUMBER']}"`

See `SKILL.md` for comprehensive troubleshooting guide.

## Requirements

- Ruby 2.5+ (for branch coverage)
- SimpleCov gem
- SimpleCov Console formatter gem
- Rails (optional, but has built-in profile)

## Resources

- [SimpleCov Documentation](https://github.com/simplecov-ruby/simplecov)
- [SimpleCov Console](https://github.com/chetan/simplecov-console)
- [Ruby Coverage Library](https://docs.ruby-lang.org/en/master/Coverage.html)

## License

MIT License - see LICENSE.txt for details

## Contributing

This skill is part of the Claude Code skills ecosystem. Improvements and additions are welcome!

## Version

1.0.0 - Initial release
