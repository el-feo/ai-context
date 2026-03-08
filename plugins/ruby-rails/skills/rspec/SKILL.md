---
name: rspec
description: Comprehensive RSpec testing for Ruby and Rails applications. Covers model specs, request specs, system specs, factories, mocks, and TDD workflow. Automatically triggers on RSpec-related keywords and testing scenarios.
---

# RSpec Testing Skill

Expert guidance for writing comprehensive tests in RSpec for Ruby and Rails applications. This skill provides immediate, actionable testing strategies with deep-dive references for complex scenarios.

## Quick Start

### Basic RSpec Structure

```ruby
# spec/models/user_spec.rb
RSpec.describe User, type: :model do
  describe '#full_name' do
    it 'returns the first and last name' do
      user = User.new(first_name: 'John', last_name: 'Doe')
      expect(user.full_name).to eq('John Doe')
    end
  end
end
```

**Key concepts:**

- `describe`: Groups related tests (classes, methods)
- `context`: Describes specific scenarios
- `it`: Individual test example
- `expect`: Makes assertions using matchers

### Running Tests

```bash
# Run all specs
bundle exec rspec

# Run specific file
bundle exec rspec spec/models/user_spec.rb

# Run specific line
bundle exec rspec spec/models/user_spec.rb:12

# Run with documentation format
bundle exec rspec --format documentation

# Run only failures from last run
bundle exec rspec --only-failures
```

## Core Testing Patterns

### 1. Model Specs

Test business logic, validations, associations, and methods:

```ruby
RSpec.describe Article, type: :model do
  # Test validations
  describe 'validations' do
    it { should validate_presence_of(:title) }
    it { should validate_length_of(:title).is_at_most(100) }
  end

  # Test associations
  describe 'associations' do
    it { should belong_to(:author) }
    it { should have_many(:comments) }
  end

  # Test instance methods
  describe '#published?' do
    context 'when publish_date is in the past' do
      it 'returns true' do
        article = Article.new(publish_date: 1.day.ago)
        expect(article.published?).to be true
      end
    end

    context 'when publish_date is in the future' do
      it 'returns false' do
        article = Article.new(publish_date: 1.day.from_now)
        expect(article.published?).to be false
      end
    end
  end

  # Test scopes
  describe '.recent' do
    it 'returns articles from the last 30 days' do
      old = create(:article, created_at: 31.days.ago)
      recent = create(:article, created_at: 1.day.ago)

      expect(Article.recent).to include(recent)
      expect(Article.recent).not_to include(old)
    end
  end
end
```

### 2. Request Specs

Test HTTP requests and responses across the entire stack:

```ruby
RSpec.describe 'Articles API', type: :request do
  describe 'GET /articles' do
    it 'returns all articles' do
      create_list(:article, 3)

      get '/articles'

      expect(response).to have_http_status(:success)
      expect(JSON.parse(response.body).size).to eq(3)
    end
  end

  describe 'POST /articles' do
    context 'with valid params' do
      it 'creates a new article' do
        article_params = { article: { title: 'New Article', body: 'Content' } }

        expect {
          post '/articles', params: article_params
        }.to change(Article, :count).by(1)

        expect(response).to have_http_status(:created)
      end
    end

    context 'with invalid params' do
      it 'returns errors' do
        invalid_params = { article: { title: '' } }

        post '/articles', params: invalid_params

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe 'authentication' do
    it 'requires authentication for create' do
      post '/articles', params: { article: { title: 'Test' } }

      expect(response).to have_http_status(:unauthorized)
    end

    it 'allows authenticated users to create' do
      user = create(:user)

      post '/articles',
        params: { article: { title: 'Test' } },
        headers: { 'Authorization' => "Bearer #{user.token}" }

      expect(response).to have_http_status(:created)
    end
  end
end
```

### 3. System Specs (End-to-End)

Test user workflows through the browser with Capybara:

```ruby
RSpec.describe 'Article management', type: :system do
  before { driven_by(:selenium_chrome_headless) }

  scenario 'user creates an article' do
    visit new_article_path

    fill_in 'Title', with: 'My Article'
    fill_in 'Body', with: 'Article content'
    click_button 'Create Article'

    expect(page).to have_content('Article was successfully created')
    expect(page).to have_content('My Article')
  end

  scenario 'user edits an article' do
    article = create(:article, title: 'Original Title')

    visit article_path(article)
    click_link 'Edit'

    fill_in 'Title', with: 'Updated Title'
    click_button 'Update Article'

    expect(page).to have_content('Updated Title')
    expect(page).not_to have_content('Original Title')
  end

  # Test JavaScript interactions
  scenario 'user filters articles', js: true do
    create(:article, title: 'Ruby Article', category: 'ruby')
    create(:article, title: 'Python Article', category: 'python')

    visit articles_path

    select 'Ruby', from: 'filter'

    expect(page).to have_content('Ruby Article')
    expect(page).not_to have_content('Python Article')
  end
end
```

## Factory Bot Integration

Use FactoryBot for test data. Define factories in `spec/factories/`, use traits for variations, and prefer `build` over `create` when persistence isn't needed.

See [references/factory_bot.md](references/factory_bot.md) for factory definitions, traits, sequences, associations, and build strategies.

## Essential Matchers

| Category | Examples |
|----------|----------|
| Equality | `eq`, `eql`, `be`, `equal` |
| Truthiness | `be_truthy`, `be_falsy`, `be_nil`, `be_a` |
| Collections | `include`, `contain_exactly`, `match_array` |
| Changes | `change`, `raise_error`, `have_enqueued_job` |

See [references/matchers.md](references/matchers.md) for the complete matcher reference.

## Mocks, Stubs, and Doubles

Use `double` or `instance_double` (preferred — verifies against real class) for test doubles. Stub with `allow(obj).to receive(:method)`, set expectations with `expect(obj).to receive(:method)`, and verify after the fact with spies via `have_received`.

See [references/mocking.md](references/mocking.md) for test doubles, stubbing, message expectations, and spies.

## DRY Testing Techniques

Use `let` (lazy) and `let!` (eager) for test data, `before` hooks for shared setup, `shared_examples` for reusable test groups, and `shared_context` for reusable setup blocks. Prefer `subject` for the object under test.

See [references/core_concepts.md](references/core_concepts.md) for detailed coverage of hooks, let, shared examples, shared contexts, and subject.

## TDD Workflow

### Red-Green-Refactor Cycle

1. **Red**: Write a failing test first

```ruby
describe User do
  it 'has a full name' do
    user = User.new(first_name: 'John', last_name: 'Doe')
    expect(user.full_name).to eq('John Doe')
  end
end
# Fails: undefined method `full_name'
```

2. **Green**: Write minimal code to pass

```ruby
class User
  def full_name
    "#{first_name} #{last_name}"
  end
end
# Passes!
```

3. **Refactor**: Improve code while keeping tests green

### Testing Strategy

**Start with system specs** for user-facing features:

- Tests complete workflows
- Highest confidence
- Slowest to run

**Drop to request specs** for API/controller logic:

- Test HTTP interactions
- Faster than system specs
- Cover authentication, authorization, edge cases

**Use model specs** for business logic:

- Test calculations, validations, scopes
- Fast and focused
- Most of your test suite

## Configuration Best Practices

### spec/rails_helper.rb

```ruby
require 'spec_helper'
ENV['RAILS_ENV'] ||= 'test'
require_relative '../config/environment'
abort("Run in production!") if Rails.env.production?
require 'rspec/rails'

# Auto-require support files
Dir[Rails.root.join('spec', 'support', '**', '*.rb')].sort.each { |f| require f }

RSpec.configure do |config|
  # Use transactional fixtures
  config.use_transactional_fixtures = true

  # Infer spec type from file location
  config.infer_spec_type_from_file_location!

  # Filter Rails backtrace
  config.filter_rails_from_backtrace!

  # Include FactoryBot methods
  config.include FactoryBot::Syntax::Methods

  # Include request helpers
  config.include RequestHelpers, type: :request

  # Capybara configuration for system specs
  config.before(:each, type: :system) do
    driven_by :selenium_chrome_headless
  end
end
```

### spec/spec_helper.rb

```ruby
RSpec.configure do |config|
  # Show detailed failure messages
  config.example_status_persistence_file_path = "spec/examples.txt"

  # Disable monkey patching (use expect syntax only)
  config.disable_monkey_patching!

  # Output warnings
  config.warnings = true

  # Profile slowest tests
  config.profile_examples = 10 if ENV['PROFILE']

  # Run specs in random order
  config.order = :random
  Kernel.srand config.seed
end
```

## Common Patterns

For testing background jobs, mailers, file uploads, pagination, and search, see [references/rails_testing.md](references/rails_testing.md).

## Performance Tips

1. **Use let instead of before** for lazy loading
2. **Avoid database calls** when testing logic (use mocks)
3. **Use build instead of create** when persistence isn't needed
4. **Use build_stubbed** for non-persisted objects with associations
5. **Tag slow tests** and exclude them during development:

   ```ruby
   it 'slow test', :slow do
     # test code
   end

   # Run with: rspec --tag ~slow
   ```

## When to Use Each Spec Type

- **Model specs**: Business logic, calculations, validations, scopes
- **Request specs**: API endpoints, authentication, authorization, JSON responses
- **System specs**: User workflows, JavaScript interactions, form submissions
- **Mailer specs**: Email content, recipients, attachments
- **Job specs**: Background job enqueueing and execution
- **Helper specs**: View helper methods
- **Routing specs**: Custom routes (usually not needed)

## Quick Reference

**Most Common Commands:**

```bash
rspec                          # Run all specs
rspec spec/models              # Run model specs
rspec --tag ~slow              # Exclude slow specs
rspec --only-failures          # Rerun failures
rspec --format documentation   # Readable output
rspec --profile               # Show slowest specs
```

**Most Common Matchers:**

- `eq(expected)` - value equality
- `be_truthy` / `be_falsy` - truthiness
- `include(item)` - collection membership
- `raise_error(Error)` - exceptions
- `change { }.by(n)` - state changes

**Most Common Stubs:**

- `allow(obj).to receive(:method)` - stub method
- `expect(obj).to receive(:method)` - expect call
- `double('name', method: value)` - create double

---

## Reference Documentation

For detailed information on specific topics, see the references directory:

- **[Core Concepts](./references/core_concepts.md)** - Describe blocks, contexts, hooks, subject, let
- **[Matchers Guide](./references/matchers.md)** - Complete matcher reference with examples
- **[Mocking and Stubbing](./references/mocking.md)** - Test doubles, stubs, spies, message expectations
- **[Rails Testing](./references/rails_testing.md)** - Rails-specific spec types and helpers
- **[Factory Bot](./references/factory_bot.md)** - Test data strategies and patterns
- **[Best Practices](./references/best_practices.md)** - Testing philosophy, patterns, and anti-patterns
- **[Configuration](./references/configuration.md)** - Setup, formatters, and optimization

## Common Scenarios

For debugging failing tests, testing complex queries, and testing callbacks, see [references/rails_testing.md](references/rails_testing.md).
