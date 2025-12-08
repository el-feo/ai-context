# RSpec Best Practices

Proven patterns and anti-patterns from "Everyday Rails Testing with RSpec" and community wisdom.

## Testing Philosophy

### Test the Right Things

**Test Behavior, Not Implementation:**
```ruby
# Bad - tests implementation
it 'calls save on the user' do
  expect(user).to receive(:save)
  controller.create
end

# Good - tests behavior
it 'creates a new user' do
  expect {
    post :create, params: { user: attributes }
  }.to change(User, :count).by(1)
end
```

**Test Outcomes, Not Methods:**
```ruby
# Bad - tests method calls
it 'calls calculate_total' do
  expect(order).to receive(:calculate_total)
  order.process
end

# Good - tests outcomes
it 'updates the order total' do
  order.process
  expect(order.total).to eq(expected_total)
end
```

### The Testing Pyramid

**Distribution of Tests:**
1. **70% Unit Tests** (Model specs)
   - Fast, focused, abundant
   - Test business logic, validations, calculations
   
2. **20% Integration Tests** (Request specs)
   - Test interactions between layers
   - Cover authentication, authorization, APIs
   
3. **10% System Tests** (System specs with Capybara)
   - Slow but high confidence
   - Test critical user workflows only

```ruby
# Most of your tests should be fast unit tests
describe Calculator do
  it 'adds two numbers' do
    expect(Calculator.add(2, 3)).to eq(5)
  end
end

# Some integration tests
describe 'Articles API', type: :request do
  it 'returns articles' do
    get '/articles'
    expect(response).to be_successful
  end
end

# Few system tests for critical paths
describe 'User registration', type: :system do
  scenario 'user signs up' do
    visit signup_path
    # full workflow test
  end
end
```

## Test Organization

### Describe Blocks

**Use describe for things (nouns):**
```ruby
describe User do
  describe '#full_name' do
    # tests for instance method
  end
  
  describe '.search' do
    # tests for class method
  end
end
```

**Use context for states (adjectives):**
```ruby
describe '#publish' do
  context 'when article is draft' do
    # test draft article
  end
  
  context 'when article is already published' do
    # test published article
  end
  
  context 'with invalid data' do
    # test validation errors
  end
end
```

### One Assertion Per Test (Usually)

```ruby
# Bad - testing multiple things
it 'creates user and sends email and logs event' do
  expect { create_user }.to change(User, :count).by(1)
  expect(ActionMailer::Base.deliveries.size).to eq(1)
  expect(EventLog.last.action).to eq('user_created')
end

# Good - separate concerns
it 'creates user' do
  expect { create_user }.to change(User, :count).by(1)
end

it 'sends welcome email' do
  create_user
  expect(ActionMailer::Base.deliveries.size).to eq(1)
end

it 'logs creation event' do
  create_user
  expect(EventLog.last.action).to eq('user_created')
end
```

**Exception - Related Assertions:**
```ruby
# OK - related assertions for same concern
it 'creates article with correct attributes' do
  article = create_article
  expect(article.title).to eq('Test')
  expect(article.author).to eq(user)
  expect(article.published).to be false
end
```

## Test Readability

### Clear Test Names

```ruby
# Bad - unclear what's being tested
it 'works' do
end

it 'test 1' do
end

# Good - describes behavior
it 'returns nil when user not found' do
end

it 'sends email after user registration' do
end

it 'redirects to login when not authenticated' do
end
```

### Use let for Reusable Test Data

```ruby
describe Article do
  # Good - DRY and clear
  let(:article) { create(:article) }
  let(:published_article) { create(:article, published: true) }
  
  it 'can be saved' do
    expect(article.save).to be true
  end
  
  it 'can be published' do
    expect(published_article).to be_published
  end
end
```

### Avoid Deep Nesting

```ruby
# Bad - hard to follow
describe Article do
  describe 'when published' do
    describe 'and featured' do
      describe 'with comments' do
        describe 'by admin users' do
          it 'does something' do
            # What are we even testing?
          end
        end
      end
    end
  end
end

# Good - flatter structure
describe Article do
  describe 'featured published article with admin comments' do
    it 'displays comment count' do
      # clear context
    end
  end
end
```

## Test Speed

### Optimize Database Usage

```ruby
# Slow - unnecessary database hits
describe '#full_name' do
  it 'combines first and last name' do
    user = create(:user, first_name: 'John', last_name: 'Doe')
    expect(user.full_name).to eq('John Doe')
  end
end

# Fast - no database needed
describe '#full_name' do
  it 'combines first and last name' do
    user = build(:user, first_name: 'John', last_name: 'Doe')
    expect(user.full_name).to eq('John Doe')
  end
end

# Fastest - no factory needed
describe '#full_name' do
  it 'combines first and last name' do
    user = User.new(first_name: 'John', last_name: 'Doe')
    expect(user.full_name).to eq('John Doe')
  end
end
```

### Use build_stubbed When Possible

```ruby
# For tests that don't need database
let(:user) { build_stubbed(:user) }
let(:article) { build_stubbed(:article, author: user) }

# Acts like persisted record but doesn't hit database
expect(article.author).to eq(user)
expect(article.persisted?).to be false  # Not really persisted
```

### Share Setup Code Wisely

```ruby
# Bad - creates user for every test even if not needed
describe ArticlesController do
  let!(:user) { create(:user) }  # Eager evaluation
  
  it 'returns articles' do
    get :index
    # doesn't use user
  end
end

# Good - only create when needed
describe ArticlesController do
  let(:user) { create(:user) }  # Lazy evaluation
  
  it 'requires authentication' do
    get :index
    # doesn't use user
  end
  
  it 'shows user articles' do
    user  # Creates user here
    get :index
    # uses user
  end
end
```

## Mocking and Stubbing

### Mock External Services

```ruby
# Don't hit real APIs in tests
describe WeatherService do
  it 'fetches temperature' do
    # Bad - hits real API
    temp = WeatherService.get_temperature('Portland')
    
    # Good - stub the HTTP call
    allow(HTTParty).to receive(:get).and_return(
      double(body: '{"temp": 72}')
    )
    temp = WeatherService.get_temperature('Portland')
  end
end
```

### Don't Mock What You Don't Own

```ruby
# Bad - mocking Rails internals
allow(ActiveRecord::Base).to receive(:connection).and_return(fake_db)

# Good - wrap in your own class
class DatabaseConnection
  def execute(sql)
    ActiveRecord::Base.connection.execute(sql)
  end
end

allow(db_connection).to receive(:execute)
```

### Prefer Stubs Over Mocks

```ruby
# Stub (allow) - more flexible
allow(mailer).to receive(:deliver)
service.process  # OK if deliver not called

# Mock (expect) - more brittle
expect(mailer).to receive(:deliver)
service.process  # Fails if deliver not called
```

## Test Data

### Use Factories Over Fixtures

```ruby
# Bad - fixtures
users:
  john:
    name: John Doe
    email: john@example.com

# Good - factories
factory :user do
  name { 'John Doe' }
  sequence(:email) { |n| "user#{n}@example.com" }
end
```

### Keep Factories Minimal

```ruby
# Bad - too much data
factory :user do
  first_name { 'John' }
  last_name { 'Doe' }
  email { 'john@example.com' }
  phone { '555-1234' }
  address { '123 Main St' }
  # ... 20 more attributes
end

# Good - only required fields
factory :user do
  first_name { 'John' }
  last_name { 'Doe' }
  sequence(:email) { |n| "user#{n}@example.com" }
  
  trait :with_phone do
    phone { '555-1234' }
  end
  
  trait :with_address do
    address { '123 Main St' }
  end
end
```

## Test Maintenance

### DRY, But Not Too DRY

```ruby
# Too DRY - hard to understand
shared_examples 'a processable entity' do
  it { is_expected.to respond_to(:process) }
  it { is_expected.to respond_to(:status) }
end

describe Order do
  it_behaves_like 'a processable entity'
  # What does this actually test?
end

# Better - explicit and clear
describe Order do
  it 'can be processed' do
    order = build(:order)
    expect { order.process }.to change(order, :status)
  end
end
```

### Update Tests With Code

```ruby
# When refactoring code, update tests immediately
# Don't leave broken tests for later

# Before refactoring
def full_name
  "#{first_name} #{last_name}"
end

# After refactoring
def full_name
  [first_name, last_name].compact.join(' ')
end

# Update test to match (add edge cases)
it 'handles missing last name' do
  user = User.new(first_name: 'John', last_name: nil)
  expect(user.full_name).to eq('John')
end
```

## Common Anti-Patterns

### Anti-Pattern: Testing Private Methods

```ruby
# Bad - testing private methods
describe '#calculate_score' do
  it 'adds bonus points' do
    # calculate_score is private
  end
end

# Good - test public interface
describe '#total_score' do
  it 'includes bonus points' do
    # total_score calls private calculate_score
  end
end
```

### Anti-Pattern: Brittle Selectors

```ruby
# Bad - coupled to HTML structure
expect(page).to have_css('div.container div.row div.col-md-6 h2')

# Good - semantic selectors
expect(page).to have_css('[data-testid="article-title"]')
expect(page).to have_selector('h2', text: 'Article Title')
```

### Anti-Pattern: Testing Framework Code

```ruby
# Bad - testing Rails validations (already tested by Rails)
describe 'validations' do
  it 'validates presence' do
    user = User.new
    expect(user.valid?).to be false
  end
end

# Good - trust Rails, test your logic
describe 'custom validation' do
  it 'requires email domain to be company domain' do
    user = User.new(email: 'user@gmail.com')
    expect(user).not_to be_valid
    expect(user.errors[:email]).to include('must be company email')
  end
end
```

### Anti-Pattern: Over-Stubbing

```ruby
# Bad - stub everything
allow(user).to receive(:name).and_return('John')
allow(user).to receive(:email).and_return('john@example.com')
allow(user).to receive(:admin?).and_return(false)
allow(user).to receive(:active?).and_return(true)

# Good - use real object or factory
user = build(:user, name: 'John', email: 'john@example.com')
```

## TDD Workflow

### Red-Green-Refactor

1. **Red:** Write failing test first
```ruby
describe '#archive' do
  it 'sets archived_at timestamp' do
    article = create(:article)
    article.archive
    expect(article.archived_at).to be_present
  end
end
# FAILS: undefined method `archive'
```

2. **Green:** Write minimal code to pass
```ruby
def archive
  update(archived_at: Time.current)
end
# PASSES
```

3. **Refactor:** Improve code while keeping tests green
```ruby
def archive
  return false if archived?
  update(archived_at: Time.current)
end

def archived?
  archived_at.present?
end
# STILL PASSES
```

### Write Tests From Outside In

Start with system specs (high-level), work down to unit tests (low-level):

```ruby
# 1. System spec - user story
scenario 'user archives article' do
  visit article_path(article)
  click_button 'Archive'
  expect(page).to have_content('Archived')
end

# 2. Request spec - controller behavior
it 'archives article' do
  patch "/articles/#{article.id}/archive"
  expect(response).to redirect_to(article_path)
  expect(article.reload).to be_archived
end

# 3. Model spec - business logic
describe '#archive' do
  it 'sets archived_at' do
    article.archive
    expect(article.archived_at).to be_present
  end
end
```

## Documentation

### Tests as Documentation

```ruby
# Good tests document how code should be used
describe User do
  describe '.search' do
    it 'finds users by name (case-insensitive)' do
      user = create(:user, name: 'John Doe')
      results = User.search('john')
      expect(results).to include(user)
    end
    
    it 'finds users by email' do
      user = create(:user, email: 'john@example.com')
      results = User.search('john@example.com')
      expect(results).to include(user)
    end
  end
end
```

### Use --format documentation

```bash
$ rspec --format documentation spec/models/user_spec.rb

User
  .search
    finds users by name (case-insensitive)
    finds users by email
```

## Continuous Improvement

### Run Tests Frequently

```bash
# Run tests often during development
bundle exec rspec

# Run specific file while working on it
bundle exec rspec spec/models/user_spec.rb

# Use guard for automatic test running
guard
```

### Measure Test Coverage

```ruby
# Add simplecov to Gemfile
gem 'simplecov', require: false

# spec/spec_helper.rb
require 'simplecov'
SimpleCov.start 'rails'

# Aim for 80-90% coverage
# But don't obsess over 100%
```

### Keep Tests Fast

```bash
# Profile slowest tests
rspec --profile 10

# Identify and optimize slow tests
# Target: < 0.1s per test
# Test suite: < 5 minutes
```

### Review and Refactor Tests

```ruby
# Regularly review test code quality
# - Are tests clear?
# - Are tests fast?
# - Are tests reliable?
# - Can tests be simplified?
```

## Summary

**Key Principles:**
1. Test behavior, not implementation
2. Keep tests fast (build > create)
3. One assertion per test (usually)
4. Clear, descriptive test names
5. DRY, but not too DRY
6. Mock external dependencies
7. Use the testing pyramid
8. Practice TDD when possible
9. Keep factories minimal
10. Tests are documentation

**Remember:**
- Good tests give you confidence to refactor
- Slow tests won't be run
- Brittle tests won't be maintained
- Tests should help, not hinder development
