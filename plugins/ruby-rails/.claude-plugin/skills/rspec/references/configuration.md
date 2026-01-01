# RSpec Configuration and Setup

Complete guide to configuring RSpec for optimal performance and developer experience.

## Installation

### Add to Gemfile

```ruby
group :development, :test do
  gem 'rspec-rails', '~> 8.0'
  gem 'factory_bot_rails'
  gem 'faker'
end

group :test do
  gem 'capybara'
  gem 'selenium-webdriver'
  gem 'simplecov', require: false
  gem 'shoulda-matchers'
  gem 'database_cleaner-active_record'
end
```

### Generate Configuration

```bash
# Install gems
bundle install

# Generate RSpec files
rails generate rspec:install

# Creates:
#   .rspec
#   spec/
#   spec/spec_helper.rb
#   spec/rails_helper.rb
```

## Configuration Files

### .rspec

Project-level defaults:

```
--require spec_helper
--format documentation
--color
--order random
```

Options:
```
--require spec_helper          # Require spec_helper in each spec
--format documentation         # Readable output format
--format progress             # Compact dots format
--color                       # Colorize output
--order random               # Run specs in random order
--seed 1234                  # Use specific random seed
--profile                    # Show 10 slowest examples
--profile 5                  # Show 5 slowest examples
--only-failures              # Rerun only failed examples
--next-failure               # Stop after first failure
--fail-fast                  # Stop after first failure (alias)
--warnings                   # Show Ruby warnings
--no-fail-fast              # Continue after failures
--tag focus                 # Run only specs tagged with :focus
--tag ~slow                 # Exclude specs tagged with :slow
```

### spec/spec_helper.rb

Non-Rails configuration:

```ruby
RSpec.configure do |config|
  # Expectations syntax
  config.expect_with :rspec do |expectations|
    # Enable only `expect` syntax
    expectations.syntax = :expect
    
    # Include chain clauses in custom matchers
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end
  
  # Mocking framework
  config.mock_with :rspec do |mocks|
    # Verify mocked methods exist on real objects
    mocks.verify_partial_doubles = true
    
    # Verify doubled constants exist
    mocks.verify_doubled_constant_names = true
  end
  
  # Shared context metadata
  config.shared_context_metadata_behavior = :apply_to_host_groups
  
  # Limit backtrace
  config.filter_gems_from_backtrace 'factory_bot'
  
  # Profile slowest examples
  config.profile_examples = 10
  
  # Run specs in random order
  config.order = :random
  Kernel.srand config.seed
  
  # Persist example status
  config.example_status_persistence_file_path = 'spec/examples.txt'
  
  # Disable monkey patching (recommended)
  config.disable_monkey_patching!
  
  # Warnings
  config.warnings = true if ENV['WARNINGS']
  
  # Formatter
  config.default_formatter = 'doc' if config.files_to_run.one?
end
```

### spec/rails_helper.rb

Rails-specific configuration:

```ruby
require 'spec_helper'
ENV['RAILS_ENV'] ||= 'test'
require_relative '../config/environment'

# Prevent database truncation in production
abort('Running in production!') if Rails.env.production?

require 'rspec/rails'

# Load support files
Dir[Rails.root.join('spec', 'support', '**', '*.rb')].sort.each { |f| require f }

# Database setup
begin
  ActiveRecord::Migration.maintain_test_schema!
rescue ActiveRecord::PendingMigrationError => e
  abort e.to_s.strip
end

RSpec.configure do |config|
  # Include FactoryBot methods
  config.include FactoryBot::Syntax::Methods
  
  # Use transactional fixtures
  config.use_transactional_fixtures = true
  
  # Infer spec type from file location
  config.infer_spec_type_from_file_location!
  
  # Filter Rails backtrace
  config.filter_rails_from_backtrace!
  
  # System test configuration
  config.before(:each, type: :system) do
    driven_by :selenium_chrome_headless
  end
  
  # Request spec helpers
  config.include RequestHelpers, type: :request
  
  # System spec helpers
  config.include SystemHelpers, type: :system
end
```

## Support Files

### spec/support/factory_bot.rb

```ruby
RSpec.configure do |config|
  config.include FactoryBot::Syntax::Methods
  
  # Lint factories (optional)
  config.before(:suite) do
    FactoryBot.lint
  end
end
```

### spec/support/database_cleaner.rb

```ruby
RSpec.configure do |config|
  config.before(:suite) do
    DatabaseCleaner.clean_with(:truncation)
  end
  
  config.before(:each) do
    DatabaseCleaner.strategy = :transaction
  end
  
  config.before(:each, type: :system) do
    DatabaseCleaner.strategy = :truncation
  end
  
  config.before(:each) do
    DatabaseCleaner.start
  end
  
  config.after(:each) do
    DatabaseCleaner.clean
  end
end
```

### spec/support/shoulda_matchers.rb

```ruby
Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :rspec
    with.library :rails
  end
end
```

### spec/support/capybara.rb

```ruby
require 'capybara/rails'
require 'capybara/rspec'

Capybara.configure do |config|
  config.default_driver = :rack_test
  config.javascript_driver = :selenium_chrome_headless
  config.default_max_wait_time = 5
  
  # Server configuration
  config.server = :puma
  config.server_errors = [:default]
end

# Chrome options for headless
Capybara.register_driver :selenium_chrome_headless do |app|
  options = Selenium::WebDriver::Chrome::Options.new
  options.add_argument('--headless')
  options.add_argument('--no-sandbox')
  options.add_argument('--disable-dev-shm-usage')
  options.add_argument('--window-size=1400,1400')
  
  Capybara::Selenium::Driver.new(app, browser: :chrome, options: options)
end
```

### spec/support/request_helpers.rb

```ruby
module RequestHelpers
  def json_response
    JSON.parse(response.body)
  end
  
  def auth_header(user)
    { 'Authorization' => "Bearer #{user.token}" }
  end
end
```

### spec/support/system_helpers.rb

```ruby
module SystemHelpers
  def sign_in(user)
    visit login_path
    fill_in 'Email', with: user.email
    fill_in 'Password', with: user.password
    click_button 'Sign in'
  end
  
  def wait_for_ajax
    Timeout.timeout(Capybara.default_max_wait_time) do
      loop until page.evaluate_script('jQuery.active').zero?
    end
  end
end
```

## Test Coverage

### SimpleCov Configuration

```ruby
# spec/spec_helper.rb (at the very top)
require 'simplecov'

SimpleCov.start 'rails' do
  # Add groups
  add_group 'Controllers', 'app/controllers'
  add_group 'Models', 'app/models'
  add_group 'Services', 'app/services'
  add_group 'Jobs', 'app/jobs'
  add_group 'Mailers', 'app/mailers'
  
  # Exclude paths
  add_filter '/spec/'
  add_filter '/config/'
  add_filter '/vendor/'
  
  # Minimum coverage
  minimum_coverage 80
  minimum_coverage_by_file 60
  
  # Output directory
  coverage_dir 'coverage'
  
  # Formatters
  formatter SimpleCov::Formatter::HTMLFormatter
end
```

## Performance Optimization

### Parallel Tests

```ruby
# Gemfile
gem 'parallel_tests', group: :development

# Setup
bundle exec parallel_test -o "--format progress"

# Run
bundle exec parallel_rspec spec/
```

### Spring for Faster Boot

```ruby
# Gemfile
gem 'spring-commands-rspec', group: :development

# Generate binstub
bundle exec spring binstub rspec

# Run with spring
bin/rspec
```

### Optimized Rails Helper

```ruby
# spec/rails_helper.rb
require 'spec_helper'
ENV['RAILS_ENV'] = 'test'

# Only load what you need
require 'active_record/railtie'
require 'action_controller/railtie'
# ... not full Rails

require_relative '../config/environment'
```

## CI/CD Configuration

### GitHub Actions

```yaml
# .github/workflows/test.yml
name: Test

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    
    services:
      postgres:
        image: postgres:14
        env:
          POSTGRES_PASSWORD: postgres
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
    
    steps:
      - uses: actions/checkout@v3
      
      - name: Setup Ruby
        uses: ruby/setup-ruby@v1
        with:
          ruby-version: 3.2
          bundler-cache: true
      
      - name: Setup Node
        uses: actions/setup-node@v3
        with:
          node-version: 18
      
      - name: Install dependencies
        run: |
          bundle install
          yarn install
      
      - name: Setup database
        env:
          DATABASE_URL: postgres://postgres:postgres@localhost:5432/test
        run: |
          bundle exec rails db:create db:schema:load
      
      - name: Run tests
        env:
          DATABASE_URL: postgres://postgres:postgres@localhost:5432/test
        run: |
          bundle exec rspec --format documentation
      
      - name: Upload coverage
        uses: codecov/codecov-action@v3
        with:
          files: ./coverage/coverage.xml
```

## Custom Formatters

### Progress Bar Formatter

```ruby
# .rspec
--require ./spec/support/formatters/progress_bar_formatter.rb
--format ProgressBarFormatter

# spec/support/formatters/progress_bar_formatter.rb
require 'rspec/core/formatters/progress_formatter'

class ProgressBarFormatter < RSpec::Core::Formatters::ProgressFormatter
  RSpec::Core::Formatters.register self, :example_passed, :example_failed
  
  def example_passed(notification)
    print green('.')
  end
  
  def example_failed(notification)
    print red('F')
  end
  
  private
  
  def green(text)
    "\e[32m#{text}\e[0m"
  end
  
  def red(text)
    "\e[31m#{text}\e[0m"
  end
end
```

## Tags and Metadata

### Custom Tags

```ruby
# spec/rails_helper.rb
RSpec.configure do |config|
  # Tag slow tests
  config.around(:each, :slow) do |example|
    puts "Running slow test..."
    example.run
  end
  
  # Skip certain tests in CI
  config.filter_run_excluding :skip_ci if ENV['CI']
  
  # Focus on specific tests
  config.filter_run_when_matching :focus
end

# Usage in specs
describe 'something', :slow do
  it 'takes a while' do
    # slow test
  end
end

it 'skipped in CI', :skip_ci do
  # local only
end

it 'focused test', :focus do
  # only this runs when focusing
end
```

## Debugging Configuration

### Better Errors Page

```ruby
# Gemfile
gem 'better_errors', group: :development
gem 'binding_of_caller', group: :development

# Available in test failures
```

### Pry Integration

```ruby
# Gemfile
gem 'pry-byebug', group: :development

# spec/spec_helper.rb
require 'pry-byebug'

# Usage in specs
it 'debugs here' do
  binding.pry  # Pause execution
  expect(something).to eq(value)
end
```

## Environment-Specific Configuration

### Test Environment

```ruby
# config/environments/test.rb
Rails.application.configure do
  # Faster test runs
  config.cache_classes = true
  config.eager_load = false
  
  # No emails in test
  config.action_mailer.delivery_method = :test
  
  # No asset compilation
  config.assets.compile = false
  
  # Show errors
  config.consider_all_requests_local = true
  
  # Quiet logs
  config.log_level = :warn
  
  # Background jobs inline
  config.active_job.queue_adapter = :test
end
```

## Commands Cheatsheet

```bash
# Run all specs
bundle exec rspec

# Run specific file
bundle exec rspec spec/models/user_spec.rb

# Run specific line
bundle exec rspec spec/models/user_spec.rb:42

# Run by pattern
bundle exec rspec --pattern 'spec/**/*_spec.rb'

# Run failed specs
bundle exec rspec --only-failures

# Run with seed for reproducibility
bundle exec rspec --seed 12345

# Tag filtering
bundle exec rspec --tag focus
bundle exec rspec --tag ~slow

# Format options
bundle exec rspec --format documentation
bundle exec rspec --format progress
bundle exec rspec --format json
bundle exec rspec --format html --out results.html

# Profile slow specs
bundle exec rspec --profile 10

# Parallel execution
bundle exec parallel_rspec spec/

# With coverage
COVERAGE=true bundle exec rspec
```

## Troubleshooting

### Common Issues

**Slow test suite:**
- Use `build` instead of `create`
- Use `build_stubbed` when possible
- Profile tests: `rspec --profile`
- Use parallel tests
- Optimize database setup

**Flaky tests:**
- Use deterministic data (avoid `rand`)
- Reset database between tests
- Don't depend on test order
- Use `travel_to` for time-dependent tests

**Memory issues:**
- Use database cleaner
- Clear caches between tests
- Avoid creating too many records
- Use `--order random` to find leaks

**CI failures:**
- Pin gem versions
- Set environment variables
- Use same database as production
- Check timezone settings
- Ensure deterministic test data
