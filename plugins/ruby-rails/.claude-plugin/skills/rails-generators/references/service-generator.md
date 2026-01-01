# Complete Service Object Generator Example

Production-ready service object generator with result objects, dependency injection, and comprehensive testing.

## Generator Implementation

```ruby
# lib/generators/service/service_generator.rb
class ServiceGenerator < Rails::Generators::NamedBase
  source_root File.expand_path('templates', __dir__)

  class_option :namespace, type: :string, desc: "Namespace for the service"
  class_option :dependencies, type: :array, default: [], desc: "Dependencies to inject"
  class_option :async, type: :boolean, default: false, desc: "Enable async processing"
  class_option :result_object, type: :boolean, default: true, desc: "Generate result object"
  class_option :skip_tests, type: :boolean, default: false, desc: "Skip test files"
  class_option :pattern, type: :string, default: 'simple',
    desc: "Service pattern (simple, command, interactor)"

  hook_for :test_framework, as: :service

  def create_service_file
    template service_template, service_path
  end

  def create_result_object
    return unless options[:result_object]
    template 'result.rb.tt', result_path
  end

  def create_error_classes
    return unless options[:pattern] == 'interactor'
    template 'error.rb.tt', error_path
  end

  private

  def service_template
    case options[:pattern]
    when 'command'
      'command_service.rb.tt'
    when 'interactor'
      'interactor_service.rb.tt'
    else
      'service.rb.tt'
    end
  end

  def service_path
    if options[:namespace]
      "app/services/#{namespace_path}/#{file_name}_service.rb"
    else
      "app/services/#{file_name}_service.rb"
    end
  end

  def result_path
    if options[:namespace]
      "app/services/#{namespace_path}/#{file_name}_result.rb"
    else
      "app/services/#{file_name}_result.rb"
    end
  end

  def error_path
    if options[:namespace]
      "app/services/#{namespace_path}/errors/#{file_name}_error.rb"
    else
      "app/services/errors/#{file_name}_error.rb"
    end
  end

  def namespace_path
    options[:namespace].underscore
  end

  def namespace_module
    options[:namespace].camelize
  end

  def dependency_params
    return "" if options[:dependencies].empty?
    options[:dependencies].map { |dep| "#{dep}:" }.join(', ')
  end

  def dependency_assignments
    options[:dependencies].map { |dep| "@#{dep} = #{dep}" }.join("\n    ")
  end
end
```

## Service Templates

### Simple Service Pattern

```erb
# lib/generators/service/templates/service.rb.tt
<% if options[:namespace] -%>
module <%= namespace_module %>
<% end -%>
  class <%= class_name %>Service
    <% if options[:async] -%>
    include ActiveJob::Helpers
    <% end -%>

    <% if options[:dependencies].any? -%>
    def initialize(<%= dependency_params %>)
      <%= dependency_assignments %>
    end
    <% else -%>
    def initialize
    end
    <% end -%>

    def call
      <% if options[:result_object] -%>
      # Implementation goes here
      # Return <%= class_name %>Result on success or failure

      <%= class_name %>Result.success(data: nil)
      <% else -%>
      # Implementation goes here
      true
      <% end -%>
    rescue StandardError => e
      <% if options[:result_object] -%>
      <%= class_name %>Result.failure(error: e.message)
      <% else -%>
      Rails.logger.error("#{self.class.name} failed: #{e.message}")
      false
      <% end -%>
    end

    <% if options[:async] -%>
    def call_async
      <%= class_name %>Job.perform_later(<%= options[:dependencies].join(', ') %>)
    end
    <% end -%>
  end
<% if options[:namespace] -%>
end
<% end -%>
```

### Command Pattern

```erb
# lib/generators/service/templates/command_service.rb.tt
<% if options[:namespace] -%>
module <%= namespace_module %>
<% end -%>
  class <%= class_name %>Service
    attr_reader :errors

    <% if options[:dependencies].any? -%>
    def initialize(<%= dependency_params %>)
      <%= dependency_assignments %>
      @errors = []
    end
    <% else -%>
    def initialize
      @errors = []
    end
    <% end -%>

    def call
      validate!
      return failure_result if errors.any?

      execute
    rescue StandardError => e
      handle_error(e)
    end

    def success?
      errors.empty?
    end

    private

    def validate!
      # Add validation logic
      <% if options[:dependencies].any? -%>
      <% options[:dependencies].each do |dep| -%>
      errors << "<%= dep.humanize %> is required" if @<%= dep %>.blank?
      <% end -%>
      <% end -%>
    end

    def execute
      # Implementation goes here
      success_result
    end

    def success_result
      <% if options[:result_object] -%>
      <%= class_name %>Result.success(data: nil)
      <% else -%>
      true
      <% end -%>
    end

    def failure_result
      <% if options[:result_object] -%>
      <%= class_name %>Result.failure(errors: errors)
      <% else -%>
      false
      <% end -%>
    end

    def handle_error(error)
      Rails.logger.error("#{self.class.name}: #{error.message}")
      errors << error.message
      failure_result
    end
  end
<% if options[:namespace] -%>
end
<% end -%>
```

### Interactor Pattern

```erb
# lib/generators/service/templates/interactor_service.rb.tt
<% if options[:namespace] -%>
module <%= namespace_module %>
<% end -%>
  class <%= class_name %>Service
    class << self
      def call(<%= dependency_params %>)
        new(<%= options[:dependencies].join(', ') %>).call
      end
    end

    <% if options[:dependencies].any? -%>
    def initialize(<%= dependency_params %>)
      <%= dependency_assignments %>
    end
    <% end -%>

    def call
      validate_inputs!
      perform
      success_result
    rescue <%= class_name %>Error => e
      failure_result(e.message)
    rescue StandardError => e
      Rails.logger.error("Unexpected error in #{self.class.name}: #{e.message}")
      failure_result("An unexpected error occurred")
    end

    private

    def validate_inputs!
      <% if options[:dependencies].any? -%>
      <% options[:dependencies].each do |dep| -%>
      raise <%= class_name %>Error, "<%= dep.humanize %> is required" if @<%= dep %>.blank?
      <% end -%>
      <% end -%>
    end

    def perform
      # Implementation goes here
    end

    def success_result
      <%= class_name %>Result.success(data: result_data)
    end

    def failure_result(message)
      <%= class_name %>Result.failure(error: message)
    end

    def result_data
      # Return successful operation data
      {}
    end
  end
<% if options[:namespace] -%>
end
<% end -%>
```

## Result Object Template

```erb
# lib/generators/service/templates/result.rb.tt
<% if options[:namespace] -%>
module <%= namespace_module %>
<% end -%>
  class <%= class_name %>Result
    attr_reader :data, :error, :errors

    def initialize(success:, data: nil, error: nil, errors: [])
      @success = success
      @data = data
      @error = error
      @errors = errors
    end

    def self.success(data: nil)
      new(success: true, data: data)
    end

    def self.failure(error: nil, errors: [])
      new(success: false, error: error, errors: errors)
    end

    def success?
      @success
    end

    def failure?
      !@success
    end

    def error_message
      error || errors.join(', ')
    end
  end
<% if options[:namespace] -%>
end
<% end -%>
```

## Error Class Template

```erb
# lib/generators/service/templates/error.rb.tt
<% if options[:namespace] -%>
module <%= namespace_module %>
<% end -%>
  class <%= class_name %>Error < StandardError
  end

  class <%= class_name %>ValidationError < <%= class_name %>Error
  end

  class <%= class_name %>ProcessingError < <%= class_name %>Error
  end
<% if options[:namespace] -%>
end
<% end -%>
```

## Usage Examples

### Simple Service

```bash
rails generate service payment_processor
```

Creates:
```ruby
class PaymentProcessorService
  def initialize
  end

  def call
    PaymentProcessorResult.success(data: nil)
  rescue StandardError => e
    PaymentProcessorResult.failure(error: e.message)
  end
end

class PaymentProcessorResult
  # ... result object implementation
end
```

### Service with Dependencies

```bash
rails generate service payment_processor \
  --dependencies=user,payment_method,amount
```

Creates:
```ruby
class PaymentProcessorService
  def initialize(user:, payment_method:, amount:)
    @user = user
    @payment_method = payment_method
    @amount = amount
  end

  def call
    # Implementation with access to @user, @payment_method, @amount
    PaymentProcessorResult.success(data: nil)
  rescue StandardError => e
    PaymentProcessorResult.failure(error: e.message)
  end
end
```

### Namespaced Service

```bash
rails generate service payment_processor \
  --namespace=Billing::Payments \
  --dependencies=order
```

Creates:
```ruby
module Billing
  module Payments
    class PaymentProcessorService
      def initialize(order:)
        @order = order
      end

      def call
        PaymentProcessorResult.success(data: nil)
      end
    end
  end
end
```

### Command Pattern Service

```bash
rails generate service order_fulfillment \
  --pattern=command \
  --dependencies=order,warehouse
```

Creates:
```ruby
class OrderFulfillmentService
  attr_reader :errors

  def initialize(order:, warehouse:)
    @order = order
    @warehouse = warehouse
    @errors = []
  end

  def call
    validate!
    return failure_result if errors.any?

    execute
  end

  def success?
    errors.empty?
  end

  private

  def validate!
    errors << "Order is required" if @order.blank?
    errors << "Warehouse is required" if @warehouse.blank?
  end

  def execute
    # Implementation
    success_result
  end
end
```

### Async Service

```bash
rails generate service email_notification \
  --dependencies=user,template \
  --async
```

Creates:
```ruby
class EmailNotificationService
  include ActiveJob::Helpers

  def initialize(user:, template:)
    @user = user
    @template = template
  end

  def call
    # Synchronous execution
    EmailNotificationResult.success(data: nil)
  end

  def call_async
    EmailNotificationJob.perform_later(@user, @template)
  end
end
```

## Testing

```ruby
# test/services/payment_processor_service_test.rb
require 'test_helper'

class PaymentProcessorServiceTest < ActiveSupport::TestCase
  setup do
    @user = users(:john)
    @payment_method = payment_methods(:visa)
    @amount = 100.00
  end

  test "successfully processes payment" do
    service = PaymentProcessorService.new(
      user: @user,
      payment_method: @payment_method,
      amount: @amount
    )

    result = service.call

    assert result.success?
    assert_not_nil result.data
  end

  test "handles payment failure" do
    service = PaymentProcessorService.new(
      user: @user,
      payment_method: nil,
      amount: @amount
    )

    result = service.call

    assert result.failure?
    assert_not_nil result.error
  end

  test "validates required dependencies" do
    service = PaymentProcessorService.new(
      user: nil,
      payment_method: @payment_method,
      amount: @amount
    )

    result = service.call

    assert result.failure?
    assert_includes result.errors, "User is required"
  end
end
```

## RSpec Testing

```ruby
# spec/services/payment_processor_service_spec.rb
require 'rails_helper'

RSpec.describe PaymentProcessorService do
  subject(:service) do
    described_class.new(
      user: user,
      payment_method: payment_method,
      amount: amount
    )
  end

  let(:user) { create(:user) }
  let(:payment_method) { create(:payment_method) }
  let(:amount) { 100.00 }

  describe '#call' do
    context 'with valid inputs' do
      it 'returns successful result' do
        result = service.call

        expect(result).to be_success
        expect(result.data).not_to be_nil
      end

      it 'processes the payment' do
        expect { service.call }
          .to change { Payment.count }.by(1)
      end
    end

    context 'with invalid inputs' do
      let(:payment_method) { nil }

      it 'returns failure result' do
        result = service.call

        expect(result).to be_failure
        expect(result.error).to be_present
      end

      it 'does not create payment' do
        expect { service.call }
          .not_to change { Payment.count }
      end
    end

    context 'when payment provider fails' do
      before do
        allow(PaymentProvider).to receive(:charge)
          .and_raise(PaymentProvider::Error, "Card declined")
      end

      it 'returns failure result with error message' do
        result = service.call

        expect(result).to be_failure
        expect(result.error).to eq("Card declined")
      end
    end
  end
end
```

## Generator Testing

```ruby
# test/generators/service_generator_test.rb
require 'test_helper'
require 'generators/service/service_generator'

class ServiceGeneratorTest < Rails::Generators::TestCase
  tests ServiceGenerator
  destination File.expand_path('../tmp', __dir__)
  setup :prepare_destination

  test "generates service and result files" do
    run_generator ["payment_processor"]

    assert_file "app/services/payment_processor_service.rb" do |content|
      assert_match(/class PaymentProcessorService/, content)
      assert_match(/def call/, content)
    end

    assert_file "app/services/payment_processor_result.rb" do |content|
      assert_match(/class PaymentProcessorResult/, content)
    end
  end

  test "generates service with namespace" do
    run_generator ["payment_processor", "--namespace=Billing"]

    assert_file "app/services/billing/payment_processor_service.rb" do |content|
      assert_match(/module Billing/, content)
      assert_match(/class PaymentProcessorService/, content)
    end
  end

  test "generates service with dependencies" do
    run_generator ["payment_processor", "--dependencies=user,amount"]

    assert_file "app/services/payment_processor_service.rb" do |content|
      assert_match(/def initialize\(user:, amount:\)/, content)
      assert_match(/@user = user/, content)
      assert_match(/@amount = amount/, content)
    end
  end

  test "generates command pattern service" do
    run_generator ["order_processor", "--pattern=command"]

    assert_file "app/services/order_processor_service.rb" do |content|
      assert_match(/attr_reader :errors/, content)
      assert_match(/def validate!/, content)
      assert_match(/def execute/, content)
    end
  end

  test "generates async service" do
    run_generator ["notification", "--async"]

    assert_file "app/services/notification_service.rb" do |content|
      assert_match(/include ActiveJob::Helpers/, content)
      assert_match(/def call_async/, content)
    end
  end

  test "skips result object when option disabled" do
    run_generator ["payment_processor", "--no-result-object"]

    assert_file "app/services/payment_processor_service.rb"
    assert_no_file "app/services/payment_processor_result.rb"
  end
end
```

## Advanced Patterns

### Service with Callbacks

```ruby
class PaymentProcessorService
  include ActiveSupport::Callbacks

  define_callbacks :call

  set_callback :call, :before, :validate_inputs
  set_callback :call, :after, :log_result
  set_callback :call, :around, :transaction_wrapper

  def call
    run_callbacks :call do
      # Implementation
    end
  end

  private

  def validate_inputs
    # Validation logic
  end

  def log_result
    # Logging logic
  end

  def transaction_wrapper
    ActiveRecord::Base.transaction do
      yield
    end
  end
end
```

### Service with State Machine

```ruby
class OrderProcessorService
  include AASM

  aasm do
    state :pending, initial: true
    state :processing
    state :completed
    state :failed

    event :start_processing do
      transitions from: :pending, to: :processing
    end

    event :complete do
      transitions from: :processing, to: :completed
    end

    event :fail do
      transitions from: [:pending, :processing], to: :failed
    end
  end
end
```

## Best Practices

1. **Single Responsibility**: Each service should do one thing well
2. **Explicit Dependencies**: Use dependency injection, not global state
3. **Return Result Objects**: Consistent success/failure handling
4. **Error Handling**: Catch and handle expected errors gracefully
5. **Testing**: Test happy path, edge cases, and error scenarios
6. **Naming**: Use verb-noun format (ProcessPayment, SendEmail)
7. **Idempotency**: Services should be safe to retry
8. **Logging**: Log important operations for debugging
9. **Transactions**: Wrap database operations in transactions
10. **Documentation**: Document complex business logic
