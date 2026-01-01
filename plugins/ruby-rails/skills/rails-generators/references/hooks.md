# Generator Hooks and Composition

Generator hooks enable modular composition, allowing generators to delegate to other generators without tight coupling. This is essential for test framework integration and extensible generator design.

## Hook Basics

### Defining Hooks

```ruby
class ServiceGenerator < Rails::Generators::NamedBase
  source_root File.expand_path('templates', __dir__)

  # Hook for test framework integration
  hook_for :test_framework, as: :service

  def create_service_file
    template 'service.rb.tt', "app/services/#{file_name}_service.rb"
  end
end
```

When invoked, this automatically calls:
- `test_unit:service` if using Test::Unit (default)
- `rspec:service` if configured for RSpec
- Any other registered test framework

### Hook Parameters

```ruby
hook_for :test_framework,
  as: :service,                    # Generator name to invoke
  in: :rails,                      # Namespace to search
  default: true,                   # Whether to invoke by default
  required: false                  # Whether to raise if not found
```

## Creating Hook Responders

### Test Framework Hook

Create a generator that responds to the hook:

```ruby
# lib/generators/rspec/service/service_generator.rb
module Rspec
  module Generators
    class ServiceGenerator < Rails::Generators::NamedBase
      source_root File.expand_path('templates', __dir__)

      def create_service_spec
        template 'service_spec.rb.tt',
          "spec/services/#{file_name}_service_spec.rb"
      end
    end
  end
end
```

Template (service_spec.rb.tt):
```erb
require 'rails_helper'

RSpec.describe <%= class_name %>Service do
  describe '#call' do
    it 'performs the operation' do
      service = described_class.new
      result = service.call

      expect(result).to be_success
    end
  end
end
```

### Test::Unit Hook (Built-in Pattern)

```ruby
# lib/generators/test_unit/service/service_generator.rb
module TestUnit
  module Generators
    class ServiceGenerator < Rails::Generators::NamedBase
      source_root File.expand_path('templates', __dir__)

      def create_service_test
        template 'service_test.rb.tt',
          "test/services/#{file_name}_service_test.rb"
      end
    end
  end
end
```

## Fallback Configuration

### Application-Level Fallbacks

Configure in `config/application.rb`:

```ruby
module MyApp
  class Application < Rails::Application
    config.generators do |g|
      # Use custom test framework
      g.test_framework :my_test_framework

      # Fallback to test_unit for generators we haven't implemented
      g.fallbacks[:my_test_framework] = :test_unit
    end
  end
end
```

This enables:
- `my_test_framework:model` (custom) ✓
- `my_test_framework:service` (custom) ✓
- `my_test_framework:controller` → falls back to `test_unit:controller` ✓

### Multiple Fallback Levels

```ruby
config.generators do |g|
  g.test_framework :my_framework

  # Try rspec first, then test_unit
  g.fallbacks[:my_framework] = { rspec: :test_unit }
end
```

Resolution order:
1. `my_framework:service`
2. `rspec:service`
3. `test_unit:service`

## Hook Invocation Options

### Conditional Hooks

```ruby
class FeatureGenerator < Rails::Generators::NamedBase
  class_option :with_mailer, type: :boolean, default: false
  class_option :with_job, type: :boolean, default: false

  hook_for :mailer, required: false if options[:with_mailer]
  hook_for :job, required: false if options[:with_job]

  def create_feature
    # Main feature code
  end
end
```

### Manual Hook Invocation

```ruby
class CustomGenerator < Rails::Generators::NamedBase
  def invoke_test_generator
    # Only invoke if tests directory exists
    if File.directory?('spec')
      invoke 'rspec:service', [name]
    elsif File.directory?('test')
      invoke 'test_unit:service', [name]
    end
  end
end
```

## Advanced Hook Patterns

### Multiple Hooks

```ruby
class ApiResourceGenerator < Rails::Generators::NamedBase
  hook_for :test_framework, as: :model
  hook_for :test_framework, as: :controller
  hook_for :serializer, required: false

  def create_model
    invoke 'model', [name]
  end

  def create_controller
    template 'controller.rb.tt',
      "app/controllers/#{file_name.pluralize}_controller.rb"
  end
end
```

### Custom Hook Behavior

```ruby
class ServiceGenerator < Rails::Generators::NamedBase
  def invoke_test_generator
    # Custom logic before hook
    prepare_test_environment

    # Invoke hook with custom arguments
    invoke "#{test_framework}:service", [name], {
      namespace: options[:namespace],
      async: options[:async]
    }

    # Custom logic after hook
    configure_test_helpers
  end

  private

  def test_framework
    Rails.application.config.generators.options[:rails][:test_framework] || :test_unit
  end

  def prepare_test_environment
    empty_directory 'test/services' unless File.directory?('test/services')
  end
end
```

## Hook Resolution Path

Rails searches for hook responders in this order:

1. **Explicit namespace**:
   - `rails/generators/rspec/service/service_generator.rb`

2. **Generator namespace**:
   - `generators/rspec/service/service_generator.rb`

3. **Fallback namespace**:
   - `rails/generators/test_unit/service/service_generator.rb`
   - `generators/test_unit/service/service_generator.rb`

4. **Error if not found** (unless `required: false`)

## Real-World Example: Complete Hook System

### Main Generator

```ruby
# lib/generators/business_logic/business_logic_generator.rb
class BusinessLogicGenerator < Rails::Generators::NamedBase
  source_root File.expand_path('templates', __dir__)

  class_option :pattern, type: :string, default: 'service',
    desc: "Pattern to use (service, command, interactor)"

  hook_for :test_framework, as: :business_logic

  def create_business_logic
    case options[:pattern]
    when 'service'
      template 'service.rb.tt', "app/services/#{file_name}_service.rb"
    when 'command'
      template 'command.rb.tt', "app/commands/#{file_name}_command.rb"
    when 'interactor'
      template 'interactor.rb.tt', "app/interactors/#{file_name}_interactor.rb"
    end
  end
end
```

### RSpec Hook Responder

```ruby
# lib/generators/rspec/business_logic/business_logic_generator.rb
module Rspec
  module Generators
    class BusinessLogicGenerator < Rails::Generators::NamedBase
      source_root File.expand_path('templates', __dir__)

      class_option :pattern, type: :string, default: 'service'

      def create_spec
        case options[:pattern]
        when 'service'
          template 'service_spec.rb.tt', "spec/services/#{file_name}_service_spec.rb"
        when 'command'
          template 'command_spec.rb.tt', "spec/commands/#{file_name}_command_spec.rb"
        when 'interactor'
          template 'interactor_spec.rb.tt', "spec/interactors/#{file_name}_interactor_spec.rb"
        end
      end
    end
  end
end
```

### Configuration

```ruby
# config/application.rb
config.generators do |g|
  g.test_framework :rspec
  g.fixture_replacement :factory_bot

  # Custom hook for business logic patterns
  g.fallbacks[:rspec] = :test_unit
end
```

Usage:
```bash
rails generate business_logic payment_processor --pattern=service
# Creates:
# - app/services/payment_processor_service.rb
# - spec/services/payment_processor_service_spec.rb

rails generate business_logic order_fulfillment --pattern=command
# Creates:
# - app/commands/order_fulfillment_command.rb
# - spec/commands/order_fulfillment_command_spec.rb
```

## Testing Hooks

```ruby
class BusinessLogicGeneratorTest < Rails::Generators::TestCase
  tests BusinessLogicGenerator
  destination File.expand_path('../tmp', __dir__)

  setup :prepare_destination

  test "invokes rspec hook when configured" do
    with_rspec_generator do
      run_generator ["payment"]

      assert_file "app/services/payment_service.rb"
      assert_file "spec/services/payment_service_spec.rb"
    end
  end

  private

  def with_rspec_generator
    Rails.application.config.generators.test_framework = :rspec
    yield
  ensure
    Rails.application.config.generators.test_framework = :test_unit
  end
end
```

## Best Practices

1. **Use `required: false`** for optional hooks to prevent errors
2. **Provide sensible fallbacks** for common frameworks
3. **Pass options through** to hook responders
4. **Test hook invocation** separately from main generator
5. **Document expected hooks** in generator documentation
6. **Use conventional naming** for hook responders (`framework:type`)
7. **Handle missing hooks gracefully** in production generators
