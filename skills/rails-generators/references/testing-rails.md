# Testing Rails Generators with Rails::Generators::TestCase

Comprehensive guide to testing Rails generators using the built-in Rails testing framework.

## Test Setup

### Basic Test Structure

```ruby
require 'test_helper'
require 'generators/service/service_generator'

class ServiceGeneratorTest < Rails::Generators::TestCase
  tests ServiceGenerator
  destination File.expand_path('../tmp', __dir__)

  setup :prepare_destination

  teardown :cleanup_destination

  private

  def cleanup_destination
    FileUtils.rm_rf(destination_root)
  end
end
```

### Configuration

```ruby
class ServiceGeneratorTest < Rails::Generators::TestCase
  tests ServiceGenerator

  # Set temporary destination for generated files
  destination Rails.root.join('tmp/generators')

  # Prepare clean slate before each test
  setup :prepare_destination

  # Copy fixture files if needed
  setup :copy_fixtures

  private

  def copy_fixtures
    FileUtils.cp_r(
      File.expand_path('../fixtures', __dir__),
      destination_root
    )
  end
end
```

## Running Generators in Tests

### Basic Generation

```ruby
test "generates service file" do
  run_generator ["payment_processor"]

  assert_file "app/services/payment_processor_service.rb"
end
```

### With Arguments and Options

```ruby
test "generates with namespace" do
  run_generator ["payment", "--namespace=billing"]

  assert_file "app/services/billing/payment_service.rb"
end

test "generates with multiple options" do
  run_generator ["payment", "--namespace=billing", "--async", "--skip-tests"]

  assert_file "app/services/billing/payment_service.rb"
  assert_no_file "test/services/billing/payment_service_test.rb"
end
```

### Handling Errors

```ruby
test "raises error without required argument" do
  assert_raises(Thor::RequiredArgumentMissingError) do
    run_generator []
  end
end

test "handles invalid options gracefully" do
  output = run_generator ["payment", "--invalid-option=value"]

  # Generator should warn but continue
  assert_match(/Unknown option/, output)
end
```

## Assertion Methods

### File Assertions

#### assert_file

Basic file existence:
```ruby
test "creates service file" do
  run_generator ["payment"]

  assert_file "app/services/payment_service.rb"
end
```

With content checking:
```ruby
test "creates service with correct content" do
  run_generator ["payment"]

  assert_file "app/services/payment_service.rb" do |content|
    assert_match(/class PaymentService/, content)
    assert_match(/def call/, content)
    assert_match(/# Implementation/, content)
  end
end
```

Multiple assertions:
```ruby
test "creates properly structured service" do
  run_generator ["payment_processor"]

  assert_file "app/services/payment_processor_service.rb" do |content|
    # Check class definition
    assert_match(/class PaymentProcessorService/, content)

    # Check initialization
    assert_match(/def initialize/, content)

    # Check main method
    assert_match(/def call/, content)

    # Ensure no typos
    refute_match(/Paymen tProcessor/, content)
  end
end
```

#### assert_no_file

```ruby
test "skips test file with option" do
  run_generator ["payment", "--skip-tests"]

  assert_file "app/services/payment_service.rb"
  assert_no_file "test/services/payment_service_test.rb"
end

test "does not create unnecessary files" do
  run_generator ["payment"]

  assert_no_file "app/services/payment_controller.rb"
  assert_no_file "app/models/payment_service.rb"
end
```

#### assert_migration

```ruby
test "creates migration" do
  run_generator ["create_payments"]

  assert_migration "db/migrate/create_payments.rb" do |content|
    assert_match(/class CreatePayments < ActiveRecord::Migration/, content)
    assert_match(/create_table :payments/, content)
  end
end

test "creates migration with timestamp" do
  run_generator ["add_status_to_orders"]

  # Check migration exists with any timestamp
  assert_migration "db/migrate/add_status_to_orders.rb"
end
```

### Directory Assertions

```ruby
test "creates directory structure" do
  run_generator ["payment", "--namespace=billing/processors"]

  assert_directory "app/services/billing"
  assert_directory "app/services/billing/processors"
  assert_file "app/services/billing/processors/payment_service.rb"
end

private

def assert_directory(path)
  assert File.directory?(File.join(destination_root, path)),
    "Expected directory #{path} to exist"
end
```

### Content Assertions

```ruby
test "generates correct class name" do
  run_generator ["payment_processor"]

  assert_file "app/services/payment_processor_service.rb" do |content|
    assert_instance_of String, content
    assert content.include?("PaymentProcessorService")
    refute content.include?("PaymentProcessor")
  end
end

test "includes required modules" do
  run_generator ["payment", "--async"]

  assert_file "app/services/payment_service.rb" do |content|
    assert_match(/include AsyncService/, content)
    assert_match(/def perform_async/, content)
  end
end

test "excludes optional modules by default" do
  run_generator ["payment"]

  assert_file "app/services/payment_service.rb" do |content|
    refute_match(/include AsyncService/, content)
    refute_match(/def perform_async/, content)
  end
end
```

## Testing Options and Arguments

### Boolean Options

```ruby
test "respects skip-tests option" do
  run_generator ["payment", "--skip-tests"]

  assert_file "app/services/payment_service.rb"
  assert_no_file "test/services/payment_service_test.rb"
end

test "respects no-skip-tests option" do
  run_generator ["payment", "--no-skip-tests"]

  assert_file "app/services/payment_service.rb"
  assert_file "test/services/payment_service_test.rb"
end
```

### String Options

```ruby
test "uses custom namespace" do
  run_generator ["payment", "--namespace=billing"]

  assert_file "app/services/billing/payment_service.rb" do |content|
    assert_match(/module Billing/, content)
    assert_match(/class PaymentService/, content)
  end
end

test "handles deep namespace" do
  run_generator ["payment", "--namespace=billing/api/v1"]

  assert_file "app/services/billing/api/v1/payment_service.rb" do |content|
    assert_match(/module Billing/, content)
    assert_match(/module Api/, content)
    assert_match(/module V1/, content)
  end
end
```

### Array Options

```ruby
test "generates with multiple dependencies" do
  run_generator ["payment", "--dependencies=user,account,payment_method"]

  assert_file "app/services/payment_service.rb" do |content|
    assert_match(/def initialize\(user:, account:, payment_method:\)/, content)
    assert_match(/@user = user/, content)
    assert_match(/@account = account/, content)
    assert_match(/@payment_method = payment_method/, content)
  end
end
```

### Hash Options

```ruby
test "generates with configuration" do
  run_generator ["payment", "--config={timeout:30,retries:3}"]

  assert_file "config/initializers/payment_service.rb" do |content|
    assert_match(/timeout: 30/, content)
    assert_match(/retries: 3/, content)
  end
end
```

## Testing Generator Hooks

### Hook Invocation

```ruby
test "invokes test framework hook" do
  # Configure test framework
  with_test_framework(:rspec) do
    run_generator ["payment"]

    assert_file "app/services/payment_service.rb"
    assert_file "spec/services/payment_service_spec.rb"
  end
end

test "invokes multiple hooks" do
  run_generator ["payment"]

  # Main file
  assert_file "app/services/payment_service.rb"

  # Test hook
  assert_file "test/services/payment_service_test.rb"

  # Fixture hook (if configured)
  assert_file "test/fixtures/payments.yml"
end

private

def with_test_framework(framework)
  original = Rails.application.config.generators.options[:rails][:test_framework]
  Rails.application.config.generators.options[:rails][:test_framework] = framework
  yield
ensure
  Rails.application.config.generators.options[:rails][:test_framework] = original
end
```

### Hook Options Pass-Through

```ruby
test "passes options to hooks" do
  run_generator ["payment", "--namespace=billing", "--async"]

  assert_file "test/services/billing/payment_service_test.rb" do |content|
    # Verify hook received namespace option
    assert_match(/class Billing::PaymentServiceTest/, content)

    # Verify hook received async option
    assert_match(/test "async behavior"/, content)
  end
end
```

## Testing File Modifications

### Routes

```ruby
test "adds routes" do
  run_generator ["payment"]

  assert_file "config/routes.rb" do |content|
    assert_match(/resources :payments/, content)
  end
end

test "adds namespaced routes" do
  run_generator ["payment", "--namespace=api/v1"]

  assert_file "config/routes.rb" do |content|
    assert_match(/namespace :api/, content)
    assert_match(/namespace :v1/, content)
    assert_match(/resources :payments/, content)
  end
end
```

### Initializers

```ruby
test "creates initializer" do
  run_generator ["payment"]

  assert_file "config/initializers/payment_service.rb" do |content|
    assert_match(/Rails.application.config.to_prepare/, content)
    assert_match(/PaymentService.configure/, content)
  end
end
```

### Gemfile Modifications

```ruby
test "adds gem to Gemfile" do
  # Create dummy Gemfile
  File.write(File.join(destination_root, 'Gemfile'), "source 'https://rubygems.org'\n")

  run_generator ["payment", "--add-gem"]

  assert_file "Gemfile" do |content|
    assert_match(/gem 'payment-processor'/, content)
  end
end
```

## Testing Template Rendering

### Template Variables

```ruby
test "renders template with correct variables" do
  run_generator ["payment_processor"]

  assert_file "app/services/payment_processor_service.rb" do |content|
    # Check class_name variable
    assert_match(/class PaymentProcessorService/, content)

    # Check file_name variable
    assert_match(/# File: payment_processor_service.rb/, content)

    # Check plural_name (if applicable)
    assert_match(/# Handles payment_processors/, content)
  end
end
```

### Conditional Template Blocks

```ruby
test "includes optional blocks when option enabled" do
  run_generator ["payment", "--with-logging"]

  assert_file "app/services/payment_service.rb" do |content|
    assert_match(/include Loggable/, content)
    assert_match(/def log_operation/, content)
  end
end

test "excludes optional blocks by default" do
  run_generator ["payment"]

  assert_file "app/services/payment_service.rb" do |content|
    refute_match(/include Loggable/, content)
    refute_match(/def log_operation/, content)
  end
end
```

## Testing Generator Composition

### Invoking Other Generators

```ruby
test "invokes model generator" do
  run_generator ["payment"]

  # Main generator output
  assert_file "app/services/payment_service.rb"

  # Invoked model generator output
  assert_file "app/models/payment.rb"
  assert_migration "db/migrate/create_payments.rb"
end

test "conditionally invokes generators" do
  run_generator ["payment", "--with-job"]

  assert_file "app/services/payment_service.rb"
  assert_file "app/jobs/payment_job.rb"
end

test "does not invoke optional generators by default" do
  run_generator ["payment"]

  assert_file "app/services/payment_service.rb"
  assert_no_file "app/jobs/payment_job.rb"
end
```

## Integration Testing

### Full Feature Generation

```ruby
test "generates complete feature" do
  run_generator ["order", "--full"]

  # Model
  assert_file "app/models/order.rb"
  assert_migration "db/migrate/create_orders.rb"

  # Service
  assert_file "app/services/order_service.rb"

  # Controller
  assert_file "app/controllers/orders_controller.rb"

  # Views
  assert_file "app/views/orders/index.html.erb"
  assert_file "app/views/orders/show.html.erb"

  # Tests
  assert_file "test/models/order_test.rb"
  assert_file "test/services/order_service_test.rb"
  assert_file "test/controllers/orders_controller_test.rb"

  # Routes
  assert_file "config/routes.rb" do |content|
    assert_match(/resources :orders/, content)
  end
end
```

### Real-World Scenario

```ruby
test "generates payment processing system" do
  run_generator ["payment",
    "--namespace=billing",
    "--with-job",
    "--with-mailer",
    "--async"
  ]

  # Core service
  assert_file "app/services/billing/payment_service.rb" do |content|
    assert_match(/module Billing/, content)
    assert_match(/class PaymentService/, content)
    assert_match(/include AsyncService/, content)
  end

  # Background job
  assert_file "app/jobs/billing/payment_job.rb"

  # Mailer
  assert_file "app/mailers/billing/payment_mailer.rb"

  # Tests for all components
  assert_file "test/services/billing/payment_service_test.rb"
  assert_file "test/jobs/billing/payment_job_test.rb"
  assert_file "test/mailers/billing/payment_mailer_test.rb"
end
```

## Advanced Testing Patterns

### Custom Assertions

```ruby
module GeneratorTestHelpers
  def assert_proper_service_structure(path)
    assert_file path do |content|
      assert_match(/class \w+Service/, content)
      assert_match(/def initialize/, content)
      assert_match(/def call/, content)
    end
  end

  def assert_namespaced_file(namespace, file_name)
    path = "app/services/#{namespace}/#{file_name}"
    assert_file path do |content|
      namespace_modules = namespace.split('/').map(&:camelize)
      namespace_modules.each do |mod|
        assert_match(/module #{mod}/, content)
      end
    end
  end
end

class ServiceGeneratorTest < Rails::Generators::TestCase
  include GeneratorTestHelpers

  test "generates proper service" do
    run_generator ["payment"]
    assert_proper_service_structure "app/services/payment_service.rb"
  end

  test "generates namespaced service" do
    run_generator ["payment", "--namespace=billing/processors"]
    assert_namespaced_file "billing/processors", "payment_service.rb"
  end
end
```

### Testing with Fixtures

```ruby
class ServiceGeneratorTest < Rails::Generators::TestCase
  setup do
    prepare_destination
    copy_fixtures
  end

  test "integrates with existing code" do
    # Fixture provides existing base service
    assert File.exist?(File.join(destination_root, 'app/services/base_service.rb'))

    run_generator ["payment"]

    assert_file "app/services/payment_service.rb" do |content|
      # Should inherit from existing base
      assert_match(/class PaymentService < BaseService/, content)
    end
  end

  private

  def copy_fixtures
    fixture_path = File.expand_path('../fixtures', __dir__)
    FileUtils.cp_r("#{fixture_path}/.", destination_root)
  end
end
```

### Parameterized Tests

```ruby
class ServiceGeneratorTest < Rails::Generators::TestCase
  {
    'simple_name' => 'SimpleNameService',
    'payment_processor' => 'PaymentProcessorService',
    'api_handler' => 'ApiHandlerService'
  }.each do |input, expected_class|
    test "generates #{expected_class} from #{input}" do
      run_generator [input]

      assert_file "app/services/#{input}_service.rb" do |content|
        assert_match(/class #{expected_class}/, content)
      end
    end
  end
end
```

## Test Organization

### Grouping Related Tests

```ruby
class ServiceGeneratorTest < Rails::Generators::TestCase
  tests ServiceGenerator
  destination File.expand_path('../tmp', __dir__)
  setup :prepare_destination

  # Basic generation tests
  test "generates service file" do
    run_generator ["payment"]
    assert_file "app/services/payment_service.rb"
  end

  # Option tests
  class OptionsTest < ServiceGeneratorTest
    test "respects namespace option" do
      run_generator ["payment", "--namespace=billing"]
      assert_file "app/services/billing/payment_service.rb"
    end

    test "respects skip-tests option" do
      run_generator ["payment", "--skip-tests"]
      assert_no_file "test/services/payment_service_test.rb"
    end
  end

  # Integration tests
  class IntegrationTest < ServiceGeneratorTest
    test "generates complete feature" do
      run_generator ["payment", "--full"]
      # ... comprehensive assertions
    end
  end
end
```

## Running Tests

### Command Line

```bash
# Run all generator tests
rails test test/generators

# Run specific generator test
rails test test/generators/service_generator_test.rb

# Run specific test
rails test test/generators/service_generator_test.rb:15

# With verbose output
RAILS_LOG_TO_STDOUT=true rails test test/generators/service_generator_test.rb

# With backtrace
rails test test/generators/service_generator_test.rb --backtrace
```

### Rake Tasks

```ruby
# lib/tasks/generator_tests.rake
namespace :test do
  desc "Run generator tests"
  task generators: :environment do
    Rails::TestTask.new do |t|
      t.libs << "test"
      t.pattern = 'test/generators/**/*_test.rb'
      t.verbose = true
    end
  end
end
```

## Best Practices

1. **Always use `prepare_destination`** in setup to ensure clean test environment
2. **Test both success and failure cases** for robust generators
3. **Use `assert_file` with content blocks** to verify file contents
4. **Test all options and their combinations** for comprehensive coverage
5. **Create fixtures** for testing integration with existing code
6. **Use custom assertions** for repeated patterns
7. **Clean up after tests** to avoid test pollution
8. **Test generator hooks** separately from main functionality
9. **Parameterize similar tests** to reduce duplication
10. **Test real-world scenarios** not just individual features
