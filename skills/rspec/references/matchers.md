# RSpec Matchers Complete Reference

Comprehensive guide to all RSpec matchers with examples and usage patterns.

## Table of Contents

1. [Equality Matchers](#equality-matchers)
2. [Comparison Matchers](#comparison-matchers)
3. [Type/Class Matchers](#typeclass-matchers)
4. [Truthiness Matchers](#truthiness-matchers)
5. [Collection Matchers](#collection-matchers)
6. [Error Matchers](#error-matchers)
7. [Change Matchers](#change-matchers)
8. [Predicate Matchers](#predicate-matchers)
9. [Rails-Specific Matchers](#rails-specific-matchers)
10. [Composed Matchers](#composed-matchers)
11. [Custom Matchers](#custom-matchers)

## Equality Matchers

### eq - Value Equality (==)

Uses `==` for comparison:

```ruby
expect(actual).to eq(expected)

# Examples
expect(5).to eq(5)
expect('hello').to eq('hello')
expect([1, 2, 3]).to eq([1, 2, 3])
expect({ a: 1 }).to eq({ a: 1 })

# Works with complex objects
user = User.new(name: 'John')
copy = User.new(name: 'John')
expect(user).to eq(copy)  # If User defines ==
```

### eql - Value and Type Equality (.eql?)

Stricter than `eq`, checks type:

```ruby
expect(actual).to eql(expected)

# Type matters
expect(5).to eql(5)       # Pass
expect(5).not_to eql(5.0) # Pass - different types
expect(5).to eq(5.0)      # Pass - eq ignores type

# Strings
expect('hello').to eql('hello')    # Pass
expect('hello').not_to eql(:hello) # Pass - different types
```

### equal / be - Object Identity (.equal?)

Checks if same object in memory:

```ruby
expect(actual).to equal(expected)
expect(actual).to be(expected)  # Alias

# Examples
a = 'hello'
b = a
c = 'hello'

expect(a).to equal(b)      # Pass - same object
expect(a).not_to equal(c)  # Pass - different objects
expect(a).to eq(c)         # Pass - same value

# Useful for singletons
expect(true).to equal(true)
expect(nil).to equal(nil)
expect(:symbol).to equal(:symbol)
```

## Comparison Matchers

```ruby
expect(actual).to be >  expected
expect(actual).to be >= expected
expect(actual).to be <  expected
expect(actual).to be <= expected

# Examples
expect(10).to be > 5
expect(10).to be >= 10
expect(5).to be < 10
expect(5).to be <= 5

# Works with any Comparable
expect(Date.today).to be > Date.yesterday
expect('b').to be > 'a'

# Floating point precision
expect(0.1 + 0.2).to be_within(0.0001).of(0.3)
expect(price).to be_within(5).percent_of(100)  # 95-105
```

## Type/Class Matchers

### be_a / be_an / be_a_kind_of

Tests class membership (uses `kind_of?`):

```ruby
expect(actual).to be_a(Class)
expect(actual).to be_an(Class)         # Alias
expect(actual).to be_a_kind_of(Class)  # Alias

# Examples
expect(5).to be_a(Integer)
expect('hello').to be_a(String)
expect([1, 2]).to be_an(Array)

# Works with inheritance
expect('hello').to be_a(Object)     # Pass
expect([]).to be_a(Enumerable)      # Pass

class Dog; end
class Poodle < Dog; end
expect(Poodle.new).to be_a(Dog)     # Pass - inheritance
expect(Poodle.new).to be_a(Poodle)  # Pass
```

### be_an_instance_of

Exact class match (uses `instance_of?`):

```ruby
expect(actual).to be_an_instance_of(Class)

# Examples
expect(5).to be_an_instance_of(Integer)
expect(5).not_to be_an_instance_of(Numeric)  # Too broad

class Dog; end
class Poodle < Dog; end
expect(Poodle.new).to be_an_instance_of(Poodle)  # Pass
expect(Poodle.new).not_to be_an_instance_of(Dog) # Pass - exact match
```

### respond_to

Tests if object responds to method:

```ruby
expect(actual).to respond_to(:method_name)
expect(actual).to respond_to(:method1, :method2)

# Examples
expect('hello').to respond_to(:upcase)
expect([]).to respond_to(:push, :pop)
expect(user).to respond_to(:email)

# With argument count
expect(user).to respond_to(:update).with(1).argument
expect(user).to respond_to(:merge).with(2).arguments
expect(user).to respond_to(:save).with(0..1).arguments  # Optional
```

## Truthiness Matchers

```ruby
# Truthy (not nil and not false)
expect(actual).to be_truthy
expect(true).to be_truthy
expect(1).to be_truthy
expect('').to be_truthy      # Empty string is truthy
expect([]).to be_truthy      # Empty array is truthy

# Falsy (nil or false)
expect(actual).to be_falsy
expect(false).to be_falsy
expect(nil).to be_falsy

# Exact boolean values
expect(actual).to be true    # Must be exactly true
expect(actual).to be false   # Must be exactly false

# Nil-specific
expect(actual).to be_nil
expect(actual).to be_present  # Rails: not blank
expect(actual).to be_blank    # Rails: nil, false, empty, or whitespace
```

## Collection Matchers

### include - Membership

```ruby
expect(collection).to include(item)
expect(collection).to include(item1, item2)

# Arrays
expect([1, 2, 3]).to include(2)
expect([1, 2, 3]).to include(1, 3)
expect([1, 2, 3]).not_to include(4)

# Hashes - key/value pairs
expect({ a: 1, b: 2 }).to include(a: 1)
expect({ a: 1, b: 2 }).to include(a: 1, b: 2)

# Strings
expect('hello world').to include('hello')
expect('hello world').to include('hello', 'world')

# Ranges
expect(1..10).to include(5)
expect(1..10).not_to include(11)
```

### match_array / contain_exactly - Unordered Equality

```ruby
expect(array).to match_array(expected)
expect(array).to contain_exactly(*expected)  # Splat form

# Order doesn't matter
expect([1, 2, 3]).to match_array([3, 2, 1])
expect([1, 2, 3]).to contain_exactly(3, 2, 1)

# Must have exact items (no more, no less)
expect([1, 2, 3]).not_to match_array([1, 2])      # Missing 3
expect([1, 2, 3]).not_to match_array([1, 2, 3, 4]) # Extra 4

# Works with duplicates
expect([1, 2, 2, 3]).to match_array([3, 2, 1, 2])
```

### start_with / end_with

```ruby
expect(array).to start_with(item)
expect(array).to start_with(item1, item2)
expect(array).to end_with(item)
expect(array).to end_with(item1, item2)

# Arrays
expect([1, 2, 3]).to start_with(1)
expect([1, 2, 3]).to start_with(1, 2)
expect([1, 2, 3]).to end_with(3)
expect([1, 2, 3]).to end_with(2, 3)

# Strings
expect('hello world').to start_with('hello')
expect('hello world').to end_with('world')
```

### all - Every Element

```ruby
expect(collection).to all(matcher)

# Examples
expect([2, 4, 6]).to all(be_even)
expect([1, 2, 3]).to all(be > 0)
expect(['hello', 'world']).to all(be_a(String))

# With custom matcher
expect(users).to all(have_attributes(active: true))
```

## Error Matchers

### raise_error

```ruby
expect { action }.to raise_error
expect { action }.to raise_error(ErrorClass)
expect { action }.to raise_error('message')
expect { action }.to raise_error(ErrorClass, 'message')
expect { action }.to raise_error(ErrorClass, /regex/)

# Examples
expect { 1 / 0 }.to raise_error(ZeroDivisionError)
expect { raise 'error' }.to raise_error('error')
expect { raise 'network error' }.to raise_error(/network/)

# Capture error for additional assertions
expect {
  raise StandardError, 'something went wrong'
}.to raise_error do |error|
  expect(error.message).to include('wrong')
end

# Testing error attributes
expect { service.call }.to raise_error(ApiError) do |error|
  expect(error.status_code).to eq(404)
  expect(error.response_body).to include('Not Found')
end
```

### throw_symbol

```ruby
expect { action }.to throw_symbol
expect { action }.to throw_symbol(:symbol)
expect { action }.to throw_symbol(:symbol, 'value')

# Examples
expect { throw :done }.to throw_symbol(:done)
expect { throw :error, 'message' }.to throw_symbol(:error, 'message')
```

## Change Matchers

### change - State Change

```ruby
expect { action }.to change { expression }
expect { action }.to change { expression }.by(delta)
expect { action }.to change { expression }.from(before).to(after)
expect { action }.to change { expression }.by_at_least(minimum)
expect { action }.to change { expression }.by_at_most(maximum)

# Examples
expect { User.create }.to change { User.count }.by(1)
expect { user.destroy }.to change(User, :count).by(-1)  # Shorthand

expect { user.update(active: false) }
  .to change { user.active }
  .from(true).to(false)

expect { cart.add_item(item) }
  .to change { cart.total }
  .by_at_least(item.price)

# Multiple changes
expect { order.process }
  .to change { order.status }.from('pending').to('completed')
  .and change { order.processed_at }.from(nil)
  .and change { Notification.count }.by(1)

# Not changing
expect { user.save }.not_to change { user.created_at }
```

### Compound Change Matchers

```ruby
# Both must change
expect { action }
  .to change { thing1 }.and change { thing2 }

# Either can change
expect { action }
  .to change { thing1 }.or change { thing2 }

# Negative compound
expect { action }
  .not_to change { thing1 }
  .and not_change { thing2 }
```

## Predicate Matchers

Any method ending in `?` can become a matcher:

```ruby
# obj.empty? becomes:
expect(obj).to be_empty

# obj.valid? becomes:
expect(obj).to be_valid

# obj.has_key?(:key) becomes:
expect(obj).to have_key(:key)

# Examples
expect([]).to be_empty
expect([1]).not_to be_empty
expect(user).to be_valid
expect(user).to be_admin
expect(hash).to have_key(:name)
expect(object).to be_present  # Rails
expect(object).to be_blank    # Rails

# Private methods work too
expect(object).to be_authenticated  # If private authenticated? exists
```

## Rails-Specific Matchers

### HTTP Status

```ruby
expect(response).to have_http_status(200)
expect(response).to have_http_status(:success)
expect(response).to have_http_status(:ok)
expect(response).to have_http_status(:created)
expect(response).to have_http_status(:redirect)
expect(response).to have_http_status(:unauthorized)
expect(response).to have_http_status(:unprocessable_entity)
expect(response).to have_http_status(:not_found)

# Symbol groups
expect(response).to be_successful  # 2xx
expect(response).to be_redirect    # 3xx
expect(response).to be_client_error # 4xx
expect(response).to be_server_error # 5xx
```

### Redirects

```ruby
expect(response).to redirect_to(path)
expect(response).to redirect_to(url)
expect(response).to redirect_to(action: 'index')

# Examples
expect(response).to redirect_to(root_path)
expect(response).to redirect_to(article_path(article))
expect(response).to redirect_to('http://example.com')
```

### Rendering

```ruby
expect(response).to render_template(template)
expect(response).to render_template(:index)
expect(response).to render_template('articles/index')
expect(response).to render_template(partial: '_form')
expect(response).to render_template(layout: 'application')
```

### Routes

```ruby
expect(get: '/articles').to route_to('articles#index')
expect(post: '/articles').to route_to(controller: 'articles', action: 'create')
expect(get: '/articles/1').to route_to(controller: 'articles', action: 'show', id: '1')

expect(get: '/invalid').not_to be_routable
```

### ActiveJob

```ruby
expect { action }.to have_enqueued_job(JobClass)
expect { action }.to have_enqueued_job(JobClass).with(arg1, arg2)
expect { action }.to have_enqueued_job(JobClass).on_queue('default')
expect { action }.to have_enqueued_job(JobClass).at(Time.now + 1.hour)

# Examples
expect { user.activate! }.to have_enqueued_job(SendWelcomeEmailJob)
expect { order.submit }.to have_enqueued_job(ProcessOrderJob).with(order)
```

### ActiveRecord

```ruby
# Validations (requires shoulda-matchers gem)
expect(user).to validate_presence_of(:email)
expect(user).to validate_uniqueness_of(:email)
expect(user).to validate_length_of(:password).is_at_least(8)
expect(user).to validate_numericality_of(:age)
expect(user).to validate_inclusion_of(:role).in_array(['user', 'admin'])

# Associations
expect(article).to belong_to(:author)
expect(author).to have_many(:articles)
expect(article).to have_one(:featured_image)
expect(article).to have_many(:comments).dependent(:destroy)

# Database columns
expect(user).to have_db_column(:email).of_type(:string)
expect(user).to have_db_index(:email)
```

## Composed Matchers

### And/Or Combinations

```ruby
# Both conditions must match
expect(alphabet).to start_with('a').and end_with('z')
expect(user).to be_valid.and be_persisted

# Either condition can match
expect(status).to eq('active').or eq('pending')
expect(value).to be_nil.or be_empty

# Nested composition
expect(response).to have_http_status(:success)
  .and include('message')
  .and match(/\d{4}/)
```

### Using Matchers as Arguments

```ruby
# Within collections
expect([1, 2, 3]).to include(a_value_within(0.1).of(2.0))
expect(['hello', 'world']).to include(a_string_starting_with('hel'))

# In hashes
expect({ name: 'John', age: 30 }).to include(
  name: a_string_matching(/Jo/),
  age: a_value > 18
)

# Change matchers
expect { action }.to change { thing }
  .from(a_value < 10)
  .to(a_value >= 10)

# Error matchers with instance checks
expect { service.call }.to raise_error(an_instance_of(ApiError))
```

### Common Composed Patterns

```ruby
# Array of hashes
expect(users).to contain_exactly(
  hash_including(name: 'John', active: true),
  hash_including(name: 'Jane', active: true)
)

# Nested structures
expect(response_json).to match(
  status: 'success',
  data: array_including(
    hash_including(
      id: a_kind_of(Integer),
      name: a_string_starting_with('Product')
    )
  )
)

# Complex validations
expect(users).to all(
  have_attributes(
    email: a_string_matching(/@/),
    age: (a_value >= 18).and(a_value <= 100)
  )
)
```

## Custom Matchers

### Simple Custom Matcher

```ruby
RSpec::Matchers.define :be_a_multiple_of do |expected|
  match do |actual|
    actual % expected == 0
  end
  
  failure_message do |actual|
    "expected #{actual} to be a multiple of #{expected}"
  end
  
  failure_message_when_negated do |actual|
    "expected #{actual} not to be a multiple of #{expected}"
  end
  
  description do
    "be a multiple of #{expected}"
  end
end

# Usage
expect(9).to be_a_multiple_of(3)
expect(10).not_to be_a_multiple_of(3)
```

### Custom Matcher with Arguments

```ruby
RSpec::Matchers.define :have_error_on do |attribute|
  match do |model|
    model.valid?
    @actual_errors = model.errors[attribute]
    @actual_errors.present? && (@expected_message.nil? || @actual_errors.include?(@expected_message))
  end
  
  chain :with_message do |message|
    @expected_message = message
  end
  
  failure_message do |model|
    msg = "expected errors on #{attribute}"
    msg += " with message '#{@expected_message}'" if @expected_message
    msg += ", got #{@actual_errors.inspect}"
    msg
  end
end

# Usage
expect(user).to have_error_on(:email)
expect(user).to have_error_on(:email).with_message("can't be blank")
```

### Composable Custom Matcher

```ruby
RSpec::Matchers.define :be_valid_json do
  match do |actual|
    @parsed = JSON.parse(actual)
    @parsed.is_a?(Hash) || @parsed.is_a?(Array)
  rescue JSON::ParserError => e
    @parse_error = e
    false
  end
  
  # Allow composition
  def supports_block_expectations?
    true
  end
  
  failure_message do |actual|
    if @parse_error
      "expected valid JSON but got parse error: #{@parse_error.message}"
    else
      "expected valid JSON (Hash or Array) but got #{@parsed.class}"
    end
  end
end

# Usage
expect(json_string).to be_valid_json
expect(api_response).to be_valid_json.and include('status' => 'ok')
```

## Matcher Aliases and Variations

```ruby
# These are equivalent:
expect(x).to be_truthy
expect(x).to be_true  # Deprecated

expect(x).to be_a(Class)
expect(x).to be_an(Class)
expect(x).to be_a_kind_of(Class)

expect(x).to equal(y)
expect(x).to be(y)

expect(x).to have_attributes(a: 1)
expect(x).to have_attributes(a: 1, b: 2)

# Method naming conventions:
# be_*    -> tests predicates (empty?, valid?)
# have_*  -> tests presence (has_key?, has_value?)
# a_*     -> composable form (a_value, a_string)
# an_*    -> composable form for vowels (an_instance_of)
```

## Best Practices

1. **Use the most specific matcher:**
   ```ruby
   # Good
   expect(array).to be_empty
   
   # Less good
   expect(array.size).to eq(0)
   ```

2. **Use composed matchers for complex expectations:**
   ```ruby
   # Good
   expect(users).to all(have_attributes(active: true, verified: true))
   
   # Less good
   users.each do |user|
     expect(user.active).to be true
     expect(user.verified).to be true
   end
   ```

3. **Prefer positive expectations:**
   ```ruby
   # Good
   expect(user).to be_valid
   
   # Less good
   expect(user).not_to be_invalid
   ```

4. **Use change matchers for state changes:**
   ```ruby
   # Good
   expect { User.create }.to change(User, :count).by(1)
   
   # Less good
   before_count = User.count
   User.create
   expect(User.count).to eq(before_count + 1)
   ```

5. **Create custom matchers for domain-specific assertions:**
   ```ruby
   # Domain-specific matcher
   RSpec::Matchers.define :be_a_valid_email do
     match { |actual| actual =~ /@/ }
   end
   
   expect(user.email).to be_a_valid_email
   ```
