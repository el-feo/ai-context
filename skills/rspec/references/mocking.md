# Mocking and Stubbing in RSpec

Complete guide to test doubles, stubs, spies, and message expectations in RSpec.

## Table of Contents

1. [Test Doubles](#test-doubles)
2. [Method Stubs](#method-stubs)
3. [Message Expectations](#message-expectations)
4. [Spies](#spies)
5. [Argument Matchers](#argument-matchers)
6. [Receive Counts](#receive-counts)
7. [Setting Responses](#setting-responses)
8. [Verifying Doubles](#verifying-doubles)
9. [Stubbing Constants](#stubbing-constants)
10. [Best Practices](#best-practices)

## Test Doubles

### Basic Doubles

```ruby
# Simple double
book = double('book')

# Double with methods
book = double('book', title: 'RSpec Book', pages: 300)

# Accessing stubbed methods
book.title  # => 'RSpec Book'
book.pages  # => 300
book.author # => raises error - not stubbed
```

### Verifying Doubles

Verify against real class interface:

```ruby
# Instance double - verifies instance methods
class Book
  def title; end
  def author; end
end

# This works - title exists on Book
book = instance_double('Book', title: 'RSpec')

# This raises error - invalid_method doesn't exist on Book
book = instance_double('Book', invalid_method: 'value')  # Error!

# Class double - verifies class methods
user_class = class_double('User')
allow(user_class).to receive(:find).and_return(user)

# Object double - verifies on specific object
real_user = User.new
fake_user = object_double(real_user)
```

### Null Object Doubles

Returns self for any method call:

```ruby
# Regular double - raises on unstubbed methods
book = double('book')
book.author  # Error: received unexpected message

# Null object - returns self for everything
book = double('book').as_null_object
book.author.publisher.location  # => book (returns self)

# Useful for testing chains without caring about result
allow(user).to receive_message_chain(:articles, :published).as_null_object
```

## Method Stubs

### Basic Stubbing

```ruby
# Three equivalent forms
allow(book).to receive(:title) { 'RSpec Book' }
allow(book).to receive(:title).and_return('RSpec Book')
allow(book).to receive_messages(title: 'RSpec Book', pages: 300)

# On real objects
user = User.new
allow(user).to receive(:admin?).and_return(true)
user.admin?  # => true (bypasses real method)

# Stub multiple methods
allow(book).to receive_messages(
  title: 'RSpec Book',
  author: 'Chelimsky',
  pages: 300
)
```

### Stubbing with Blocks

```ruby
# Dynamic return value
allow(counter).to receive(:next) { @count += 1 }

# Access arguments in block
allow(calculator).to receive(:add) { |a, b| a + b }

# Multiple calls to block
call_count = 0
allow(service).to receive(:call) do
  call_count += 1
  "Called #{call_count} times"
end
```

### Consecutive Return Values

```ruby
# Returns different values on each call
allow(die).to receive(:roll).and_return(1, 2, 3, 6)

die.roll  # => 1
die.roll  # => 2
die.roll  # => 3
die.roll  # => 6
die.roll  # => 6 (repeats last)

# With blocks
values = [1, 2, 3]
allow(provider).to receive(:fetch) { values.shift || 0 }
```

### Stubbing Chains

```ruby
# Stub method chain
allow(user).to receive_message_chain(:articles, :published, :count)
  .and_return(5)

user.articles.published.count  # => 5

# Multiple chains
allow(api).to receive_message_chain('client.get.body')
  .and_return('response')

# WARNING: receive_message_chain is a code smell
# Indicates violation of Law of Demeter
# Consider refactoring instead
```

### Partial Doubles

Stub methods on real objects while keeping others:

```ruby
user = User.new(name: 'John')

# Stub one method
allow(user).to receive(:admin?).and_return(true)

user.name     # => 'John' (real method)
user.admin?   # => true (stubbed)

# Call original implementation
allow(user).to receive(:full_name).and_call_original
```

## Message Expectations

### Basic Expectations

```ruby
# Expect method to be called
expect(mailer).to receive(:deliver)

# With and_return to set response
expect(validator).to receive(:validate).and_return(true)

# Must be set up BEFORE calling the method
expect(mailer).to receive(:send_email)
service.process  # This must call mailer.send_email

# Multiple expectations
expect(logger).to receive(:info).with('Starting')
expect(logger).to receive(:info).with('Complete')
processor.run
```

### Expect vs Allow

```ruby
# allow - sets up stub, doesn't verify calls
allow(service).to receive(:call)
# OK if service.call is never called

# expect - sets up stub AND verifies call
expect(service).to receive(:call)
# Fails if service.call is not called

# Use expect when the call is important
# Use allow for setup/configuration
```

## Spies

### Basic Spy Usage

```ruby
# Create spy
invitation = spy('invitation')

# Do something that calls methods
user.accept_invitation(invitation)

# Verify after the fact
expect(invitation).to have_received(:accept)
expect(invitation).to have_received(:send_notification)

# Spy with return values
user_spy = spy('user', admin?: true)
expect(user_spy.admin?).to be true
```

### Spy Advantages

```ruby
# Traditional mock (arrange, act, assert)
expect(mailer).to receive(:deliver)  # Arrange
service.call                         # Act
# Implicitly asserts

# Spy pattern (arrange, act, assert)
mailer = spy('mailer')              # Arrange
service.call(mailer)                # Act
expect(mailer).to have_received(:deliver)  # Explicit assert

# Spies read more naturally - assert after action
```

### Creating Spies

```ruby
# Generic spy
spy('name')

# Instance spy - verifies against class
instance_spy('User')

# Class spy - verifies class methods
class_spy('User')

# Object spy - verifies against specific object
object_spy(User.new)

# Allow stubbing with spy
user_spy = spy('user')
allow(user_spy).to receive(:name).and_return('John')
```

## Argument Matchers

### Exact Arguments

```ruby
# Exact match
expect(service).to receive(:call).with(1, 'hello', true)

# Multiple expectations with different args
expect(logger).to receive(:log).with(:info, 'Starting')
expect(logger).to receive(:log).with(:info, 'Complete')
```

### Special Matchers

```ruby
# Any arguments
expect(service).to receive(:call).with(any_args)

# No arguments
expect(service).to receive(:call).with(no_args)

# Specific types
expect(service).to receive(:call).with(kind_of(String))
expect(service).to receive(:call).with(instance_of(User))

# Boolean
expect(validator).to receive(:check).with(boolean())

# Anything
expect(processor).to receive(:process).with(1, anything(), 'end')

# Duck typing
expect(output).to receive(:write).with(duck_type(:to_s, :size))

# Regular expressions
expect(validator).to receive(:validate).with(/^\d+$/)
```

### Collection Matchers

```ruby
# Hash including specific keys
expect(api).to receive(:post).with(hash_including(status: 'active'))

# Hash excluding keys
expect(api).to receive(:post).with(hash_excluding(password: anything()))

# Array including items
expect(processor).to receive(:handle).with(array_including(1, 2))

# Combining matchers
expect(service).to receive(:call).with(
  hash_including(
    name: a_string_matching(/John/),
    age: a_value > 18
  )
)
```

### Custom Argument Matchers

```ruby
# Using satisfy
expect(validator).to receive(:check).with(
  satisfy { |arg| arg.length > 5 && arg.include?('@') }
)

# Custom matcher
RSpec::Matchers.define :a_positive_number do
  match { |actual| actual.is_a?(Numeric) && actual > 0 }
end

expect(calculator).to receive(:sqrt).with(a_positive_number)
```

## Receive Counts

### Exact Counts

```ruby
expect(logger).to receive(:info).once
expect(logger).to receive(:info).twice
expect(logger).to receive(:info).exactly(3).times

# Zero times
expect(logger).not_to receive(:error)
# or
expect(logger).to receive(:error).exactly(0).times
```

### Range Counts

```ruby
# At least
expect(logger).to receive(:info).at_least(:once)
expect(logger).to receive(:info).at_least(:twice)
expect(logger).to receive(:info).at_least(3).times

# At most
expect(logger).to receive(:info).at_most(:once)
expect(logger).to receive(:info).at_most(:twice)
expect(logger).to receive(:info).at_most(3).times

# Combining with arguments
expect(api).to receive(:get).with('/users').at_least(:once)
```

### Ordered Expectations

```ruby
# Must be received in order
expect(service).to receive(:connect).ordered
expect(service).to receive(:fetch).ordered
expect(service).to receive(:disconnect).ordered

# Same method with different arguments
expect(logger).to receive(:log).with('Start').ordered
expect(logger).to receive(:log).with('Process').ordered
expect(logger).to receive(:log).with('End').ordered
```

## Setting Responses

### Return Values

```ruby
# Single return value
allow(service).to receive(:call).and_return(42)

# Multiple calls, same value
allow(service).to receive(:call).and_return(42, 42, 42)

# Multiple calls, different values
allow(service).to receive(:call).and_return(1, 2, 3)

# Return array in single call (not multiple values)
allow(team).to receive(:players).and_return([player1, player2])
```

### Raising Errors

```ruby
# Raise error
allow(service).to receive(:call).and_raise(StandardError)

# With message
allow(service).to receive(:call).and_raise(StandardError, 'Network error')

# With instantiated error
allow(service).to receive(:call).and_raise(
  ApiError.new('Connection failed', status: 500)
)

# Testing error handling
expect(api).to receive(:fetch).and_raise(Timeout::Error)
expect { service.call }.to raise_error(Timeout::Error)
```

### Throwing Symbols

```ruby
allow(service).to receive(:call).and_throw(:halt)
allow(service).to receive(:call).and_throw(:redirect, '/home')

# Testing throws
expect { service.call }.to throw_symbol(:halt)
```

### Yielding

```ruby
# Yield values
allow(file).to receive(:each_line).and_yield('line 1').and_yield('line 2')

# Multiple yields
allow(iterator).to receive(:each)
  .and_yield(1)
  .and_yield(2)
  .and_yield(3)

# Yielding and returning
allow(processor).to receive(:process)
  .and_yield('data')
  .and_return(:success)
```

### Calling Original

```ruby
# Call real implementation
user = User.new
allow(user).to receive(:name).and_call_original

# Useful for partial mocking
class Calculator
  def add(a, b)
    a + b
  end
end

calc = Calculator.new
expect(calc).to receive(:add).and_call_original
result = calc.add(2, 3)  # Calls real method
expect(result).to eq(5)

# Wrap original
allow(service).to receive(:call) do |*args|
  # do something before
  result = service.call(*args).original  # Call original
  # do something after
  result
end
```

## Verifying Doubles

### Instance Doubles

```ruby
# Verify against real class
class User
  def name; end
  def email; end
  def admin?; end
end

# Valid - these methods exist
user = instance_double('User',
  name: 'John',
  email: 'john@example.com',
  admin?: true
)

# Invalid - typo in method name
user = instance_double('User', namme: 'John')  # Error!

# Verify argument count
user = instance_double('User')
allow(user).to receive(:update).with(hash)  # Verifies User#update takes 1 arg
```

### Class Doubles

```ruby
# Verify class methods
user_class = class_double('User')
allow(user_class).to receive(:find).and_return(user)
allow(user_class).to receive(:create).and_return(user)

# Transfer to real class for verification
user_class = class_double('User').as_stubbed_const
# Now User in tests refers to user_class
```

### Transfer Stubs to Real Objects

```ruby
# Create verifying double
user = instance_double('User', name: 'John')

# Later, when real object available
real_user = User.new
allow(real_user).to receive(:name).and_return('John')

# Or verify stub would work on real object
user = instance_double('User')
allow(user).to receive(:name)
# Verifies User#name exists with no arguments
```

## Stubbing Constants

### Hide Constant

```ruby
# Temporarily remove constant
hide_const('FEATURE_FLAG')

# Now FEATURE_FLAG is undefined for this test
expect { FEATURE_FLAG }.to raise_error(NameError)
```

### Stub Constant

```ruby
# Replace constant value
stub_const('API_KEY', 'test_key')

# Restore after test automatically
```

### Stub Class

```ruby
# Replace class with double
stub_const('Mailer', class_double('Mailer'))
allow(Mailer).to receive(:deliver_later)

# Transfer nested constants
stub_const('MyApp::Config', class_double('MyApp::Config'))
```

## Best Practices

### When to Use Mocks vs Real Objects

```ruby
# Use real objects when possible
describe Calculator do
  it 'adds numbers' do
    calc = Calculator.new
    expect(calc.add(2, 3)).to eq(5)
  end
end

# Use mocks for:
# 1. External services
allow(api_client).to receive(:fetch).and_return(data)

# 2. Expensive operations
allow(image).to receive(:resize).and_return(resized_image)

# 3. Testing edge cases
allow(validator).to receive(:check).and_raise(ValidationError)

# 4. Isolating units
allow(repository).to receive(:save).and_return(true)
```

### Prefer Stubs over Mocks

```ruby
# Stub (allow) - less brittle
allow(service).to receive(:call).and_return(result)
my_code_that_may_or_may_not_call_service

# Mock (expect) - more brittle
expect(service).to receive(:call).and_return(result)
my_code_must_call_service  # Test fails if not called
```

### Don't Mock What You Don't Own

```ruby
# Bad - mocking external library
allow(HTTParty).to receive(:get).and_return(response)

# Good - wrap in your own class
class ApiClient
  def fetch_users
    HTTParty.get('/users')
  end
end

allow(api_client).to receive(:fetch_users).and_return(users)
```

### Avoid Over-Mocking

```ruby
# Bad - mocking everything
allow(user).to receive(:name).and_return('John')
allow(user).to receive(:email).and_return('john@example.com')
allow(user).to receive(:admin?).and_return(false)
allow(user).to receive(:active?).and_return(true)

# Good - use factory or real object
user = create(:user, name: 'John', email: 'john@example.com')
```

### Message Expectations vs State Testing

```ruby
# Message expectation (mock) - tests implementation
expect(mailer).to receive(:deliver)
service.process

# State testing - tests outcome
service.process
expect(User.last.email_sent).to be true

# Prefer state testing when possible
```

### Stub Roles, Not Objects

```ruby
# Bad - stub specific implementation
allow(ActiveRecord::Base).to receive(:connection)

# Good - stub role/interface
notifier = double('notifier')
allow(notifier).to receive(:notify)
Service.new(notifier).process
```

### Use Spies for Complex Interactions

```ruby
# With traditional mocks - hard to read
expect(logger).to receive(:info).with('Start').ordered
expect(processor).to receive(:process)
expect(logger).to receive(:info).with('End').ordered
service.run

# With spies - clearer flow
logger = spy('logger')
processor = spy('processor')
service.run(logger: logger, processor: processor)

expect(logger).to have_received(:info).with('Start').ordered
expect(processor).to have_received(:process)
expect(logger).to have_received(:info).with('End').ordered
```

### Testing Collaborators

```ruby
class OrderProcessor
  def initialize(mailer: Mailer, payment: Payment)
    @mailer = mailer
    @payment = payment
  end
  
  def process(order)
    @payment.charge(order.total)
    @mailer.send_receipt(order)
  end
end

# Test with mocks
describe OrderProcessor do
  it 'charges payment and sends email' do
    mailer = double('mailer')
    payment = double('payment')
    
    expect(payment).to receive(:charge).with(100)
    expect(mailer).to receive(:send_receipt)
    
    processor = OrderProcessor.new(mailer: mailer, payment: payment)
    processor.process(order)
  end
end
```

## Common Patterns

### Stubbing Time

```ruby
# Freeze time
allow(Time).to receive(:now).and_return(Time.parse('2024-01-01 12:00:00'))

# Or use Timecop gem
Timecop.freeze(Time.parse('2024-01-01 12:00:00')) do
  # tests
end
```

### Stubbing ENV

```ruby
# Stub environment variables
allow(ENV).to receive(:[]).and_call_original
allow(ENV).to receive(:[]).with('API_KEY').and_return('test_key')
```

### Stubbing File Operations

```ruby
# Stub file reading
allow(File).to receive(:read).with('config.yml').and_return('test: config')

# Stub file existence
allow(File).to receive(:exist?).with('data.json').and_return(true)
```

### Stubbing Database Calls

```ruby
# Stub ActiveRecord queries
allow(User).to receive(:find).with(1).and_return(user)
allow(User).to receive(:where).with(active: true).and_return([user1, user2])

# Stub associations
allow(user).to receive(:articles).and_return([article1, article2])
```

