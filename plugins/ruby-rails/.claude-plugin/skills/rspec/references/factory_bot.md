# Factory Bot Test Data Strategies

Comprehensive guide to using Factory Bot for creating test data in RSpec.

## Table of Contents

1. [Setup and Configuration](#setup-and-configuration)
2. [Defining Factories](#defining-factories)
3. [Using Factories](#using-factories)
4. [Sequences](#sequences)
5. [Associations](#associations)
6. [Traits](#traits)
7. [Transient Attributes](#transient-attributes)
8. [Callbacks](#callbacks)
9. [Strategies](#strategies)
10. [Best Practices](#best-practices)

## Setup and Configuration

### Installation

```ruby
# Gemfile
group :development, :test do
  gem 'factory_bot_rails'
end

# Run
bundle install

# Generate factories for existing models
rails g factory_bot:model User
```

### Configuration

```ruby
# spec/rails_helper.rb
RSpec.configure do |config|
  # Include FactoryBot methods
  config.include FactoryBot::Syntax::Methods
  
  # Use build_stubbed by default (faster)
  # config.before(:each) do
  #   FactoryBot.use_build_stubbed
  # end
end
```

## Defining Factories

### Basic Factory

```ruby
# spec/factories/users.rb
FactoryBot.define do
  factory :user do
    first_name { 'John' }
    last_name { 'Doe' }
    email { 'john@example.com' }
    admin { false }
  end
end
```

### Dynamic Values

```ruby
factory :user do
  # Use blocks for dynamic values
  first_name { Faker::Name.first_name }
  last_name { Faker::Name.last_name }
  
  # Time-based values
  created_at { Time.current }
  
  # Random values
  age { rand(18..80) }
  
  # Conditional values
  role { admin ? 'admin' : 'user' }
end
```

### Lazy vs Immediate Evaluation

```ruby
factory :user do
  # Lazy evaluation (block) - evaluated when factory is built
  email { "user_#{rand(1000)}@example.com" }
  
  # Immediate evaluation - evaluated when factory is defined
  # Don't do this!
  # email "user_#{rand(1000)}@example.com"
end
```

## Using Factories

### Build Strategies

```ruby
# create - persisted to database
user = create(:user)
user.persisted? # => true

# build - not persisted
user = build(:user)
user.persisted? # => false

# build_stubbed - not persisted, behaves like persisted
user = build_stubbed(:user)
user.persisted? # => false (but acts like true)
user.id # => 1001 (fake ID)

# attributes_for - hash of attributes
attrs = attributes_for(:user)
# => { first_name: 'John', last_name: 'Doe', ... }
```

### Overriding Attributes

```ruby
# Override single attribute
user = create(:user, first_name: 'Jane')

# Override multiple attributes
user = create(:user,
  first_name: 'Jane',
  last_name: 'Smith',
  email: 'jane@example.com'
)

# Use with blocks
user = create(:user) do |u|
  u.articles << create(:article)
end
```

### Creating Multiple Records

```ruby
# Create list
users = create_list(:user, 3)
# Creates 3 users

# Create list with overrides
users = create_list(:user, 3, admin: true)

# Build list (not persisted)
users = build_list(:user, 3)
```

## Sequences

### Basic Sequence

```ruby
factory :user do
  sequence(:email) { |n| "user#{n}@example.com" }
  # user1@example.com, user2@example.com, ...
end
```

### Named Sequence

```ruby
# Define sequence separately
sequence :email do |n|
  "user#{n}@example.com"
end

factory :user do
  email
end

factory :admin do
  email
end
```

### Advanced Sequences

```ruby
# Sequence with pattern
sequence(:username) { |n| "user_#{n.to_s.rjust(4, '0')}" }
# user_0001, user_0002, ...

# Sequence with array rotation
sequence(:role, %w[user moderator admin].cycle)
# user, moderator, admin, user, moderator, ...

# Sequence with custom start
sequence(:id, 1000) { |n| n }
# 1000, 1001, 1002, ...
```

## Associations

### Basic Associations

```ruby
factory :article do
  title { 'Article Title' }
  
  # Belongs to association
  association :author, factory: :user
  # or shorthand:
  author factory: :user
  # or simplest (if factory name matches):
  author
end

# Using
article = create(:article)
article.author # => User instance (auto-created)
```

### Has Many Associations

```ruby
factory :user do
  first_name { 'John' }
  
  # Create associated records after creation
  after(:create) do |user|
    create_list(:article, 3, author: user)
  end
end

# Using
user = create(:user)
user.articles.count # => 3
```

### Nested Factories

```ruby
factory :user do
  first_name { 'John' }
  
  # Nested factory
  factory :user_with_articles do
    after(:create) do |user|
      create_list(:article, 3, author: user)
    end
  end
end

# Using
user = create(:user_with_articles)
```

### Avoiding N+1 in Associations

```ruby
# Bad - creates article and author separately
article = create(:article)

# Good - reuse existing author
author = create(:user)
article = create(:article, author: author)

# Or use build
author = build(:user)
article = build(:article, author: author)
```

## Traits

### Defining Traits

```ruby
factory :user do
  first_name { 'John' }
  last_name { 'Doe' }
  email { 'john@example.com' }
  
  trait :admin do
    admin { true }
    role { 'administrator' }
  end
  
  trait :with_avatar do
    after(:create) do |user|
      user.avatar.attach(
        io: File.open(Rails.root.join('spec', 'fixtures', 'avatar.jpg')),
        filename: 'avatar.jpg'
      )
    end
  end
  
  trait :with_articles do
    after(:create) do |user|
      create_list(:article, 3, author: user)
    end
  end
end
```

### Using Traits

```ruby
# Single trait
admin = create(:user, :admin)

# Multiple traits
admin_with_avatar = create(:user, :admin, :with_avatar)

# Traits with overrides
admin = create(:user, :admin, email: 'admin@example.com')
```

### Trait Inheritance

```ruby
factory :user do
  active { false }
  
  trait :active do
    active { true }
  end
  
  trait :verified do
    verified_at { Time.current }
  end
  
  trait :active_and_verified do
    active
    verified
  end
end

# Using
user = create(:user, :active_and_verified)
```

## Transient Attributes

Attributes that aren't set on the model:

```ruby
factory :user do
  transient do
    articles_count { 3 }
    admin { false }
  end
  
  role { admin ? 'admin' : 'user' }
  
  after(:create) do |user, evaluator|
    create_list(:article, evaluator.articles_count, author: user)
  end
end

# Using
user = create(:user, articles_count: 5, admin: true)
```

## Callbacks

### Available Callbacks

```ruby
factory :user do
  # Before build (before attributes set)
  before(:build) do |user|
    puts "Building user"
  end
  
  # After build (after attributes set, before save)
  after(:build) do |user|
    user.profile ||= build(:profile)
  end
  
  # After create (after save)
  after(:create) do |user|
    create(:article, author: user)
  end
end
```

### Callback with Traits

```ruby
factory :user do
  trait :with_welcome_email do
    after(:create) do |user|
      UserMailer.welcome_email(user).deliver_now
    end
  end
end
```

## Strategies

### Default Strategy

```ruby
# Configure default strategy
FactoryBot.use_build_stubbed

# Now this uses build_stubbed
user = create(:user)  # Actually build_stubbed!

# Force specific strategy
user = FactoryBot.create(:user)
```

### Strategy Selection

```ruby
# Use build for most tests (faster)
user = build(:user)

# Use create when you need:
# - Database constraints (uniqueness)
# - Associations to work
# - Queries to find the record

# Use build_stubbed when you need:
# - Speed (fastest)
# - Record to behave as persisted
# - No actual database interaction
```

## Best Practices

### Factories vs Fixtures

**Use Factories (Recommended):**
- More flexible
- Easier to understand
- Can create variations easily
- Better for complex associations

**Fixtures (Avoid):**
- Hard to maintain
- Hidden dependencies
- All or nothing loading

### Keep Factories Minimal

```ruby
# Bad - too much data
factory :user do
  first_name { 'John' }
  last_name { 'Doe' }
  email { 'john@example.com' }
  phone { '555-1234' }
  address { '123 Main St' }
  city { 'Portland' }
  state { 'OR' }
  zip { '97201' }
  bio { 'A long bio...' }
end

# Good - only required attributes
factory :user do
  first_name { 'John' }
  last_name { 'Doe' }
  sequence(:email) { |n| "user#{n}@example.com" }
  
  # Use traits for optional attributes
  trait :with_phone do
    phone { '555-1234' }
  end
  
  trait :with_address do
    address { '123 Main St' }
    city { 'Portland' }
    state { 'OR' }
    zip { '97201' }
  end
end
```

### Use Sequences for Unique Values

```ruby
# Bad - will fail on uniqueness constraint
factory :user do
  email { 'user@example.com' }  # Same every time!
end

# Good
factory :user do
  sequence(:email) { |n| "user#{n}@example.com" }
end
```

### Don't Create When You Can Build

```ruby
# Slow - hits database
describe '#full_name' do
  it 'combines first and last name' do
    user = create(:user, first_name: 'John', last_name: 'Doe')
    expect(user.full_name).to eq('John Doe')
  end
end

# Fast - no database
describe '#full_name' do
  it 'combines first and last name' do
    user = build(:user, first_name: 'John', last_name: 'Doe')
    expect(user.full_name).to eq('John Doe')
  end
end
```

### Use build_stubbed When Possible

```ruby
# Fastest - no database, fakes persistence
describe '#admin?' do
  it 'returns true for admin users' do
    user = build_stubbed(:user, :admin)
    expect(user).to be_admin
  end
end
```

### Create Once, Use Many Times

```ruby
# Bad - creates 3 users
describe 'something' do
  it 'test 1' do
    user = create(:user)
    # test
  end
  
  it 'test 2' do
    user = create(:user)
    # test
  end
  
  it 'test 3' do
    user = create(:user)
    # test
  end
end

# Good - creates 1 user
describe 'something' do
  let(:user) { create(:user) }
  
  it 'test 1' do
    # use user
  end
  
  it 'test 2' do
    # use user
  end
  
  it 'test 3' do
    # use user
  end
end
```

### Use Traits for Variations

```ruby
# Bad - separate factories
factory :active_user do
  # ...
  active { true }
end

factory :inactive_user do
  # ...
  active { false }
end

# Good - one factory with trait
factory :user do
  # ...
  active { true }
  
  trait :inactive do
    active { false }
  end
end

# Using
active = create(:user)
inactive = create(:user, :inactive)
```

### Avoid Callbacks When Possible

```ruby
# Bad - side effects hidden in factory
factory :user do
  after(:create) do |user|
    UserMailer.welcome_email(user).deliver_now
    create(:profile, user: user)
    create_list(:article, 3, author: user)
  end
end

# Good - explicit in test
it 'sends welcome email' do
  user = create(:user)
  UserMailer.welcome_email(user).deliver_now
  # test
end

# Or use trait for optional behavior
factory :user do
  trait :with_profile do
    after(:create) { |user| create(:profile, user: user) }
  end
end
```

### Organize Factories

```ruby
# spec/factories/users.rb
FactoryBot.define do
  factory :user do
    # basic attributes
    
    # traits
    trait :admin do
    end
    
    trait :with_articles do
    end
  end
end

# One file per model
# Group related factories together
# Use traits for variations
# Keep factories in spec/factories/
```

### Use Faker for Realistic Data

```ruby
# Add to Gemfile
gem 'faker'

factory :user do
  first_name { Faker::Name.first_name }
  last_name { Faker::Name.last_name }
  email { Faker::Internet.email }
  phone { Faker::PhoneNumber.phone_number }
  
  # But use sequences for uniqueness
  sequence(:username) { |n| "#{Faker::Internet.username}#{n}" }
end
```

### Testing Factories

```ruby
# spec/factories_spec.rb
RSpec.describe 'factories' do
  FactoryBot.factories.each do |factory|
    describe "#{factory.name} factory" do
      it 'is valid' do
        expect(build(factory.name)).to be_valid
      end
      
      factory.definition.defined_traits.each do |trait|
        context "with #{trait.name} trait" do
          it 'is valid' do
            expect(build(factory.name, trait.name)).to be_valid
          end
        end
      end
    end
  end
end
```

## Common Patterns

### Polymorphic Associations

```ruby
factory :comment do
  body { 'Great post!' }
  
  trait :on_article do
    association :commentable, factory: :article
  end
  
  trait :on_photo do
    association :commentable, factory: :photo
  end
end

# Using
comment = create(:comment, :on_article)
```

### Enum Attributes

```ruby
class Order < ApplicationRecord
  enum status: { pending: 0, processing: 1, completed: 2 }
end

factory :order do
  status { :pending }
  
  trait :processing do
    status { :processing }
  end
  
  trait :completed do
    status { :completed }
  end
end
```

### File Attachments

```ruby
factory :user do
  trait :with_avatar do
    after(:build) do |user|
      user.avatar.attach(
        io: File.open(Rails.root.join('spec', 'fixtures', 'avatar.jpg')),
        filename: 'avatar.jpg',
        content_type: 'image/jpeg'
      )
    end
  end
end
```
