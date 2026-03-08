# Testing Rails Generators with RSpec

Guide to testing Rails generators using RSpec and the `generator_spec` gem.

## Table of Contents

- [Setup](#setup)
- [Basic Testing with generator_spec](#basic-testing-with-generator_spec)
- [Structure Assertions](#structure-assertions)
- [Testing Options](#testing-options)
- [Testing with Dummy App](#testing-with-dummy-app)
- [Mixing RSpec and Rails Assertions](#mixing-rspec-and-rails-assertions)

## Setup

Add to Gemfile:

```ruby
group :development, :test do
  gem 'generator_spec'
end
```

### Basic Test Structure

```ruby
require 'generator_spec'
require 'generators/service/service_generator'

RSpec.describe ServiceGenerator, type: :generator do
  destination File.expand_path('../../tmp', __FILE__)

  before do
    prepare_destination
  end

  # Tests go here
end
```

## Basic Testing with generator_spec

### Running Generators

```ruby
RSpec.describe ServiceGenerator, type: :generator do
  destination File.expand_path('../../tmp', __FILE__)
  before { prepare_destination }

  context "with default options" do
    before { run_generator ["payment_processor"] }

    it "creates service file" do
      expect(destination_root).to have_structure {
        directory "app/services" do
          file "payment_processor_service.rb" do
            contains "class PaymentProcessorService"
            contains "def call"
          end
        end
      }
    end

    it "creates test file" do
      expect(destination_root).to have_structure {
        directory "test/services" do
          file "payment_processor_service_test.rb"
        end
      }
    end
  end
end
```

### With Arguments and Options

```ruby
context "with namespace option" do
  before { run_generator ["payment", "--namespace=billing"] }

  it "creates namespaced service" do
    expect(destination_root).to have_structure {
      directory "app/services/billing" do
        file "payment_service.rb" do
          contains "module Billing"
          contains "class PaymentService"
        end
      end
    }
  end
end

context "with multiple options" do
  before do
    run_generator ["payment", "--namespace=billing", "--async", "--skip-tests"]
  end

  it "creates async service without tests" do
    expect(destination_root).to have_structure {
      directory "app/services/billing" do
        file "payment_service.rb" do
          contains "include AsyncService"
        end
      end
      no_file "test/services/billing/payment_service_test.rb"
    }
  end
end
```

## Structure Assertions

### `have_structure` Matcher

The `generator_spec` gem provides a `have_structure` matcher:

```ruby
expect(destination_root).to have_structure {
  # Check directory exists
  directory "app/services"

  # Check directory with nested assertions
  directory "app/services" do
    # Check file exists
    file "payment_service.rb"

    # Check file with content
    file "payment_service.rb" do
      contains "class PaymentService"
      does_not_contain "TODO"
    end
  end

  # Check file does NOT exist
  no_file "app/services/old_service.rb"
}
```

### Content Assertions

```ruby
file "payment_service.rb" do
  # String contains
  contains "class PaymentService"

  # Negative assertion
  does_not_contain "TODO"
  does_not_contain "FIXME"
end
```

## Testing Options

### Boolean Options

```ruby
context "with skip-tests option" do
  before { run_generator ["payment", "--skip-tests"] }

  it "skips test file" do
    expect(destination_root).to have_structure {
      directory "app/services" do
        file "payment_service.rb"
      end
      no_file "test/services/payment_service_test.rb"
    }
  end
end
```

### Array Options

```ruby
context "with dependencies" do
  before { run_generator ["payment", "--dependencies=user,account"] }

  it "generates initializer with dependencies" do
    expect(destination_root).to have_structure {
      directory "app/services" do
        file "payment_service.rb" do
          contains "def initialize(user:, account:)"
          contains "@user = user"
          contains "@account = account"
        end
      end
    }
  end
end
```

### String Options

```ruby
context "with command pattern" do
  before { run_generator ["payment", "--pattern=command"] }

  it "generates command-style service" do
    expect(destination_root).to have_structure {
      directory "app/services" do
        file "payment_service.rb" do
          contains "attr_reader :errors"
          contains "def validate!"
          contains "def execute"
        end
      end
    }
  end
end
```

## Testing with Dummy App

For generators that modify existing files (routes, initializers), test against a dummy app:

```ruby
RSpec.describe "ServiceGenerator" do
  let(:dummy_app_path) { File.expand_path('../../test/dummy', __FILE__) }

  it "generates correct service file" do
    Dir.chdir(dummy_app_path) do
      `rails generate service payment_processor`

      service_file = File.read('app/services/payment_processor_service.rb')
      expect(service_file).to include('class PaymentProcessorService')

      # Cleanup
      FileUtils.rm_rf('app/services/payment_processor_service.rb')
    end
  end

  it "adds routes" do
    Dir.chdir(dummy_app_path) do
      `rails generate api_controller product`

      routes = File.read('config/routes.rb')
      expect(routes).to include('resources :products')

      # Cleanup
      `rails destroy api_controller product`
    end
  end
end
```

## Mixing RSpec and Rails Assertions

You can use Rails generator assertions within RSpec tests:

```ruby
RSpec.describe ServiceGenerator, type: :generator do
  destination File.expand_path('../../tmp', __FILE__)
  before { prepare_destination }

  context "with default options" do
    before { run_generator ["payment"] }

    it "creates service with correct content" do
      # Rails assertion style (also works in RSpec)
      assert_file "app/services/payment_service.rb" do |content|
        expect(content).to match(/class PaymentService/)
        expect(content).to match(/def call/)
      end
    end

    it "creates migration" do
      assert_migration "db/migrate/create_payments.rb" do |content|
        expect(content).to match(/create_table :payments/)
      end
    end
  end
end
```

### Custom RSpec Matchers

```ruby
RSpec::Matchers.define :generate_file do |path|
  match do |generator_args|
    prepare_destination
    run_generator generator_args
    File.exist?(File.join(destination_root, path))
  end

  failure_message do |generator_args|
    "expected generator with args #{generator_args} to create #{path}"
  end
end

# Usage
it { expect(["payment"]).to generate_file("app/services/payment_service.rb") }
```
