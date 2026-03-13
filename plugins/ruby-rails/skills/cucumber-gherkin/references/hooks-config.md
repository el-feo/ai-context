# Hooks and Configuration Reference

Hooks are blocks of code that run at specific points in the Cucumber execution cycle.

## Table of Contents

- [Hooks Overview](#hooks-overview)
- [Scenario Hooks](#scenario-hooks)
- [Step Hooks](#step-hooks)
- [Global Hooks](#global-hooks)
- [Conditional Hooks](#conditional-hooks)
- [Hook Execution Order](#hook-execution-order)
- [Configuration (cucumber.yml)](#configuration)
- [Running Cucumber](#running-cucumber)
- [Reporter Plugins](#reporter-plugins)
- [World/Context Pattern](#worldcontext-pattern)
- [Capybara Integration](#capybara-integration)
- [Database Cleaning](#database-cleaning)
- [Screenshot on Failure](#screenshot-on-failure)

## Hooks Overview

| Hook | Scope | Runs |
|------|-------|------|
| `BeforeAll` | Global | Once before any scenario |
| `AfterAll` | Global | Once after all scenarios |
| `Before` | Scenario | Before each scenario |
| `After` | Scenario | After each scenario |
| `AfterStep` | Step | After each step |
| `Around` | Scenario | Wraps scenario (Ruby only) |

## Scenario Hooks

### Before

Runs before the first step of each scenario.

```ruby
Before do |scenario|
  @browser = Browser.new
end

# With tag filter
Before('@browser') do
  start_browser
end

# With explicit order (lower runs first)
Before(order: 10) do
  setup_database
end

Before(order: 20) do
  seed_data
end
```

### After

Runs after the last step, regardless of outcome.

```ruby
After do |scenario|
  if scenario.failed?
    save_screenshot("failure_#{scenario.name.gsub(/\s+/, '_')}.png")
  end
  @browser.quit
end

After('@database') do
  DatabaseCleaner.clean
end
```

### Around (Ruby Only)

Wraps scenario execution. Useful for timeout control.

```ruby
Around('@fast') do |scenario, block|
  Timeout.timeout(0.5) do
    block.call
  end
end

Around do |scenario, block|
  start_time = Time.now
  block.call
  puts "Scenario took #{Time.now - start_time}s"
end
```

## Step Hooks

```ruby
AfterStep do |scenario|
  puts "Just finished a step"
end
```

## Global Hooks

Run once for entire test suite.

```ruby
# In features/support/env.rb
BeforeAll do
  DatabaseCleaner.strategy = :truncation
  start_server
end

AfterAll do
  stop_server
end
```

## Conditional Hooks

Use tag expressions to run hooks selectively.

```ruby
Before('@browser and not @headless') do
  @browser = Browser.new(headless: false)
end

After('@database') do
  DatabaseCleaner.clean
end

Before('@smoke or @critical') do
  setup_monitoring
end
```

## Hook Execution Order

1. `BeforeAll` hooks (once)
2. For each scenario:
   - `Before` hooks (in order of registration, or by `order` param)
   - `Background` steps (if any)
   - Scenario steps (with `AfterStep` after each)
   - `After` hooks (in reverse order of registration)
3. `AfterAll` hooks (once)

## Configuration

### cucumber.yml

```yaml
# config/cucumber.yml
default: --format progress --strict --tags "not @wip"
html_report: --format html --out reports/cucumber.html
ci: --format progress --format junit --out reports/junit.xml --tags "not @wip"
smoke: --tags @smoke
```

Usage:
```bash
cucumber                    # uses default profile
cucumber -p html_report     # uses html_report profile
cucumber -p ci              # uses ci profile
```

## Running Cucumber

```bash
# Run all features
bundle exec cucumber

# Run specific feature
cucumber features/login.feature

# Run specific scenario by line
cucumber features/login.feature:10

# Run with tags
cucumber --tags "@smoke and not @wip"

# Dry run (check step definitions without executing)
cucumber --dry-run

# Generate HTML report
cucumber --format html --out report.html

# Multiple formatters
cucumber --format progress --format html --out report.html

# Parallel execution
bundle exec parallel_cucumber features/
```

## Reporter Plugins

| Format | Description |
|--------|-------------|
| `pretty` | Colored console output |
| `progress` | Dots for passed, F for failed |
| `html:path` | HTML report |
| `json:path` | JSON output |
| `junit:path` | JUnit XML format |
| `message:path` | Cucumber Messages (Protobuf) |

## World/Context Pattern

Share state between steps in a scenario.

```ruby
# features/support/world.rb
module CustomWorld
  attr_accessor :current_user

  def login_as(user)
    @current_user = user
    visit login_path
    fill_in 'email', with: user.email
    click_button 'Login'
  end
end

World(CustomWorld)

# In step definitions
Given('I am logged in as {string}') do |email|
  self.current_user = User.find_by(email: email)
  login_as(current_user)
end
```

## Capybara Integration

Common setup for Rails feature tests:

```ruby
# features/support/env.rb
require 'cucumber/rails'
require 'capybara/cucumber'

Capybara.default_driver = :rack_test
Capybara.javascript_driver = :selenium_chrome_headless
Capybara.default_max_wait_time = 5

# Tag-based driver switching
Before('@javascript') do
  Capybara.current_driver = :selenium_chrome_headless
end

After('@javascript') do
  Capybara.use_default_driver
end
```

## Database Cleaning

```ruby
# features/support/database_cleaner.rb
require 'database_cleaner/active_record'

DatabaseCleaner.strategy = :truncation

Before do
  DatabaseCleaner.start
end

After do
  DatabaseCleaner.clean
end

# Or with cucumber-rails built-in
# In features/support/env.rb
Cucumber::Rails::Database.javascript_strategy = :truncation
```

## Screenshot on Failure

```ruby
# features/support/hooks.rb
After do |scenario|
  if scenario.failed? && Capybara.current_driver != :rack_test
    page.save_screenshot("tmp/screenshots/#{scenario.name.gsub(/\s+/, '_')}.png")
    embed("tmp/screenshots/#{scenario.name.gsub(/\s+/, '_')}.png", 'image/png')
  end
end
```

## Environment Variables

```ruby
Before do
  @base_url = ENV['BASE_URL'] || 'http://localhost:3000'
end
```
