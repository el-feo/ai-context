# RuboCop Extensions Guide

Comprehensive guide to rubocop-rails, rubocop-rspec, and rubocop-performance extensions.

## Installation

### Add to Gemfile

```ruby
group :development do
  gem 'rubocop', require: false
  gem 'rubocop-rails', require: false
  gem 'rubocop-rspec', require: false
  gem 'rubocop-performance', require: false
end
```

### Enable in .rubocop.yml

```yaml
plugins:
  - rubocop-rails
  - rubocop-rspec
  - rubocop-performance

AllCops:
  TargetRubyVersion: 3.2
  TargetRailsVersion: 7.0  # For rubocop-rails
```

## rubocop-rails

Rails-specific best practices and conventions.

### Configuration

```yaml
AllCops:
  TargetRailsVersion: 7.0

Rails:
  Enabled: true

Rails/MigratedSchemaVersion:
  MigratedSchemaVersion: '20240101000000'
```

### Key Features

**ActiveRecord Best Practices:**
- Detects N+1 queries patterns
- Enforces proper associations
- Migration safety checks
- SQL injection prevention

**Controller Conventions:**
- Action ordering
- Status code usage
- Before action patterns

**View/Helper Safety:**
- XSS prevention
- Proper escaping

### Common Cops

See cop_reference.md for detailed examples.

## rubocop-rspec

RSpec testing conventions.

### Configuration

```yaml
RSpec/ExampleLength:
  Max: 10

RSpec/MultipleExpectations:
  Max: 3

RSpec/NestedGroups:
  Max: 4

RSpec/DescribeClass:
  Exclude:
    - 'spec/system/**/*'
    - 'spec/requests/**/*'
```

### Key Features

**Test Organization:**
- File path conventions
- Describe/context structure
- Example grouping

**Matcher Preferences:**
- Predicate matchers
- Change matchers
- Expectation syntax

### Common Patterns

Focus on clarity and single responsibility in tests.

## rubocop-performance

Performance optimization recommendations.

### Key Features

**String Operations:**
- Efficient string manipulation
- Regex optimization
- Immutable string handling

**Collection Operations:**
- Optimal iteration methods
- Array/hash operations
- Lazy evaluation

### Configuration

Most cops are enabled by default. Disable specific ones if needed:

```yaml
Performance/Casecmp:
  Enabled: false  # Only works with ASCII
```

## Version Compatibility

Extensions track RuboCop versions:

- Update all gems together
- Check CHANGELOG for breaking changes
- Test after updates

## Custom Extensions

See custom_cops_guide.md for creating custom cops.
