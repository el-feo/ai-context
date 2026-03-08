# SimpleCov Common Patterns

## Table of Contents

- [Pre-commit Hook](#pre-commit-hook)
- [Coverage Summary Script](#coverage-summary-script)
- [Watch Mode for TDD](#watch-mode-for-tdd)

## Pre-commit Hook

```bash
#!/bin/bash
# .git/hooks/pre-commit

echo "Running tests with coverage..."
COVERAGE=true bundle exec rake test

if [ $? -ne 0 ]; then
  echo "Coverage check failed"
  exit 1
fi

echo "Coverage acceptable"
```

## Coverage Summary Script

```ruby
# scripts/coverage_summary.rb
require 'json'

data = JSON.parse(File.read('coverage/.resultset.json'))
coverage = data.values.first.dig('coverage', 'lines')

total = coverage.size
covered = coverage.compact.count { |x| x > 0 }
pct = (covered.to_f / total * 100).round(2)

puts "Coverage: #{pct}% (#{covered}/#{total} lines)"

exit 1 if pct < 90
```

## Watch Mode for TDD

```bash
# Use guard-minitest or guard-rspec
bundle exec guard

# Gemfile
group :development, :test do
  gem 'guard-minitest'
end

# Guardfile
guard :minitest do
  watch(%r{^test/(.*)/?(.*)_test\.rb$})
  watch(%r{^app/(.+)\.rb$}) { |m| "test/#{m[1]}_test.rb" }
end
```
