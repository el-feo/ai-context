---
name: simplecov
description: Comprehensive test coverage analysis and improvement for Ruby and Rails applications using SimpleCov and SimpleCov Console formatter. Automatically runs coverage reports, identifies gaps, suggests tests, and enforces coverage standards. Integrates with RubyCritic for holistic code quality. Use when running tests, analyzing coverage, improving test suites, or setting up coverage tracking in Ruby/Rails projects.
---

# SimpleCov Test Coverage Agent

## Overview

Maintain high test coverage in Ruby and Rails applications through automated analysis using SimpleCov as the coverage engine and SimpleCov Console for terminal output. This skill identifies coverage gaps, suggests targeted tests, and enforces quality standards alongside RubyCritic for comprehensive code quality feedback.

## Core Capabilities

### 1. Setup and Configuration

Configure SimpleCov for any Ruby/Rails project with best practices:

**Initial Setup:**

```bash
# Add to Gemfile
echo "gem 'simplecov', require: false, group: :test" >> Gemfile
echo "gem 'simplecov-console', require: false, group: :test" >> Gemfile
bundle install
```

**Create .simplecov Configuration:**

```ruby
SimpleCov.start 'rails' do
  formatter SimpleCov::Formatter::MultiFormatter.new([
    SimpleCov::Formatter::HTMLFormatter,
    SimpleCov::Formatter::Console
  ])

  # Enable branch coverage (Ruby 2.5+)
  enable_coverage :branch
  primary_coverage :branch

  # Set thresholds
  minimum_coverage line: 90, branch: 80
  minimum_coverage_by_file 80
  refuse_coverage_drop :line, :branch

  # Standard Rails filters
  add_filter '/test/'
  add_filter '/spec/'
  add_filter '/config/'
  add_filter '/vendor/'

  # Organize by application layers
  add_group 'Controllers', 'app/controllers'
  add_group 'Models', 'app/models'
  add_group 'Services', 'app/services'
  add_group 'Jobs', 'app/jobs'
  add_group 'Mailers', 'app/mailers'
  add_group 'Helpers', 'app/helpers'
  add_group 'Libraries', 'lib'
end
```

**Console Formatter Options:**

```ruby
# Customize output in .simplecov
SimpleCov::Formatter::Console.use_colors = true
SimpleCov::Formatter::Console.sort = 'coverage'  # or 'path'
SimpleCov::Formatter::Console.show_covered = false
SimpleCov::Formatter::Console.max_rows = 15
SimpleCov::Formatter::Console.output_style = 'table'  # or 'block'
```

**Test Helper Integration (CRITICAL - Must be FIRST):**

```ruby
# test/test_helper.rb or spec/spec_helper.rb
require 'simplecov'
SimpleCov.start 'rails'

# Now load application
ENV['RAILS_ENV'] ||= 'test'
require_relative '../config/environment'
# ... rest of test helper
```

### 2. Running Coverage Analysis

**Standard Test Execution:**

```bash
# Minitest
bundle exec rake test

# RSpec
bundle exec rspec

# Cucumber
bundle exec cucumber

# Specific test files
bundle exec ruby -Itest test/models/user_test.rb
```

SimpleCov automatically tracks coverage and generates reports after test completion.

**Console Output Example:**

```bash
COVERAGE: 82.34% -- 2345/2848 lines in 111 files
BRANCH COVERAGE: 78.50% -- 157/200 branches

showing bottom (worst) 15 of 69 files
+----------+----------------------------------------------+-------+--------+----------------------+
| coverage | file                                         | lines | missed | missing              |
+----------+----------------------------------------------+-------+--------+----------------------+
| 22.73%   | lib/websocket_server.rb                      | 22    | 17     | 11, 14, 17-18, 20-22 |
| 30.77%   | app/models/role.rb                           | 13    | 9      | 28-34, 36-37         |
| 42.86%   | lib/mail_handler.rb                          | 14    | 8      | 6-8, 12-15, 22       |
| 45.00%   | app/services/payment_processor.rb            | 80    | 44     | 15-22, 35-48, ...    |
+----------+----------------------------------------------+-------+--------+----------------------+

42 file(s) with 100% coverage not shown
```

**HTML Report:**

```bash
# Open detailed browser report
open coverage/index.html  # macOS
xdg-open coverage/index.html  # Linux
```

### 3. Identifying and Addressing Coverage Gaps

**Gap Analysis Workflow:**

1. **Locate worst coverage files** from console output
2. **Examine specific uncovered lines**
3. **Categorize gap types:**
   - Edge cases and error conditions
   - Branch paths (if/else, case/when)
   - Private methods not exercised through public API
   - Callback sequences
   - Complex conditionals

4. **Determine appropriate test type:**
   - Unit tests: Business logic, calculations, validations
   - Integration tests: Multi-object workflows
   - System tests: Full user interactions
   - Request/controller tests: HTTP endpoints

5. **Write targeted tests**
6. **Verify improvement**

**Example: Improving Payment Processor Coverage**

SimpleCov shows: `45.00% | app/services/payment_processor.rb | 80 | 44`

```bash
# View the file with line numbers
cat -n app/services/payment_processor.rb | grep -A2 -B2 "15\|16\|17"
```

Uncovered lines reveal:

- Lines 15-18: Retry logic for failed charges
- Lines 35-40: Refund processing
- Lines 45-48: Webhook handling

**Add Comprehensive Tests:**

```ruby
# test/services/payment_processor_test.rb
require 'test_helper'

class PaymentProcessorTest < ActiveSupport::TestCase
  test "retries failed charges up to 3 times" do
    order = orders(:pending)

    # Simulate failures then success
    Stripe::Charge.expects(:create)
      .times(2)
      .raises(Stripe::CardError.new('declined', nil))
    Stripe::Charge.expects(:create)
      .returns(stripe_charge)

    processor = PaymentProcessor.new(order)
    assert processor.charge
    assert_equal 3, processor.attempt_count
  end

  test "processes refunds correctly" do
    order = orders(:paid)

    processor = PaymentProcessor.new(order)
    refund = processor.refund_payment

    assert refund.succeeded?
    assert_equal order.total, refund.amount
    assert_equal 'refunded', order.reload.status
  end

  test "handles webhook events appropriately" do
    event = stripe_events(:charge_succeeded)

    processor = PaymentProcessor.new
    processor.handle_webhook(event)

    order = Order.find_by(stripe_charge_id: event.data.object.id)
    assert_equal 'paid', order.status
  end
end
```

### 4. Branch Coverage Analysis

Branch coverage tracks whether both paths of conditionals are tested.

**Understanding Branch Reports:**

```
| 72.22% | app/services/discount_calculator.rb | 4 | 1 | branch: 75% | 4 | 1 | 3[else] |
```

This shows:

- Line coverage: 72.22% (4 lines, 1 missed)
- Branch coverage: 75% (4 branches, 1 missed)
- Missing branch: Line 3's else path

**Example Code:**

```ruby
def calculate_discount(order)
  return 0 if order.total < 50  # Branch: true/false

  discount = order.total * 0.1
  discount > 10 ? 10 : discount  # Branch: true/false
end
```

**Complete Branch Coverage:**

```ruby
test "returns 0 for small orders" do
  order = Order.new(total: 30)
  assert_equal 0, DiscountCalculator.calculate_discount(order)  # Tests true branch line 2
end

test "returns percentage discount for medium orders" do
  order = Order.new(total: 75)
  assert_equal 7.5, DiscountCalculator.calculate_discount(order)  # Tests false branch line 2, false branch line 5
end

test "caps discount at maximum" do
  order = Order.new(total: 200)
  assert_equal 10, DiscountCalculator.calculate_discount(order)  # Tests true branch line 5
end
```

### 5. Multi-Suite Coverage Merging

SimpleCov automatically merges results from multiple test suites run within the merge_timeout (default 10 minutes).

**Configuration:**

```ruby
# .simplecov
SimpleCov.start 'rails' do
  merge_timeout 3600  # 1 hour

  # Optional: explicit command names
  command_name "Test Suite #{ENV['TEST_ENV_NUMBER'] || Process.pid}"
end
```

**Running Multiple Suites:**

```bash
# Run all test types - SimpleCov merges automatically
bundle exec rake test
bundle exec rspec
bundle exec cucumber

# View combined coverage
open coverage/index.html
```

**Parallel Test Support:**

```ruby
# test/test_helper.rb
require 'simplecov'

SimpleCov.start 'rails' do
  command_name "Test #{ENV['TEST_ENV_NUMBER']}"
end
```

```bash
bundle exec parallel_test test/ -n 4
```

### 6. CI/CD Integration

Configure SimpleCov for CI pipelines with minimum coverage enforcement and artifact uploading.

See [references/ci_cd_integration.md](references/ci_cd_integration.md) for GitHub Actions, CircleCI, and other CI platform configurations.

### 7. Integration with RubyCritic

Combine SimpleCov coverage data with RubyCritic complexity analysis to prioritize refactoring targets.

See [references/rubycritic_integration.md](references/rubycritic_integration.md) for combined analysis workflows and prioritization matrices.

## Advanced Features

### Conditional Coverage (On-Demand)

Run coverage only when explicitly requested:

```ruby
# test/test_helper.rb
SimpleCov.start if ENV['COVERAGE']
```

```bash
# Without coverage
bundle exec rake test

# With coverage
COVERAGE=true bundle exec rake test
```

### Nocov Exclusions

Exclude specific code sections:

```ruby
# :nocov:
def debugging_helper
  # Development-only code not covered
  puts "Debug: #{inspect}"
end
# :nocov:

# Custom token
SimpleCov.nocov_token 'skip_coverage'

# skip_coverage
def skip_this_method
end
# skip_coverage
```

### Custom Filters and Groups

**Advanced Filtering:**

```ruby
SimpleCov.start 'rails' do
  # Exclude short files
  add_filter do |source_file|
    source_file.lines.count < 5
  end

  # Exclude files by complexity
  add_filter do |source_file|
    # Could integrate complexity metrics
    source_file.lines.count > 500
  end

  # Array of filters
  add_filter ["/test/", "/spec/", "/config/"]
end
```

**Custom Groups:**

```ruby
SimpleCov.start 'rails' do
  add_group "Services", "app/services"
  add_group "Jobs", "app/jobs"
  add_group "API", "app/controllers/api"

  add_group "Long Files" do |src_file|
    src_file.lines.count > 100
  end

  add_group "Business Logic" do |src_file|
    src_file.filename =~ /(models|services|lib)/
  end
end
```

### Subprocess Coverage

Track coverage in forked processes:

```ruby
SimpleCov.enable_for_subprocesses true

SimpleCov.at_fork do |pid|
  SimpleCov.command_name "#{SimpleCov.command_name} (subprocess: #{pid})"
  SimpleCov.print_error_status = false
  SimpleCov.formatter SimpleCov::Formatter::SimpleFormatter
  SimpleCov.minimum_coverage 0
  SimpleCov.start
end
```

### Coverage for Spawned Processes

For processes started with PTY.spawn, Open3.popen, etc:

```ruby
# .simplecov_spawn.rb
require 'simplecov'
SimpleCov.command_name 'spawn'
SimpleCov.at_fork.call(Process.pid)
SimpleCov.start
```

```ruby
# In test
PTY.spawn('ruby -r./.simplecov_spawn my_script.rb') do
  # ...
end
```

## Troubleshooting

Common issues include 0% coverage (load order), Spring conflicts, parallel test merge failures, and missing branch coverage.

See [references/troubleshooting.md](references/troubleshooting.md) for solutions to all common SimpleCov issues.

## Best Practices

Set achievable thresholds (start 80-85%), track both line and branch coverage, prioritize business logic, and enforce standards in CI/CD.

See [references/best_practices.md](references/best_practices.md) for the full list of 10 best practices with code examples.

## Common Patterns

Pre-commit hooks, coverage summary scripts, and watch mode for TDD workflows.

See [references/common_patterns.md](references/common_patterns.md) for ready-to-use patterns and scripts.

## Resources

### Scripts

See `scripts/` for coverage analysis utilities (if provided).

### References

See `references/` for:

- Advanced configuration examples
- CI/CD integration patterns
- Coverage analysis methodologies

## External References

- [SimpleCov Documentation](https://github.com/simplecov-ruby/simplecov)
- [SimpleCov Console Formatter](https://github.com/chetan/simplecov-console)
- [Ruby Coverage Library](https://docs.ruby-lang.org/en/master/Coverage.html)
- [RubyCritic Integration](https://github.com/whitesmith/rubycritic)
