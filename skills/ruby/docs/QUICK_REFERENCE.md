# Ruby Quick Reference Guide

## Essential Patterns and Idioms

### Error Handling

```ruby
# Basic rescue
begin
  risky_operation
rescue StandardError => e
  handle_error(e)
ensure
  cleanup
end

# Inline rescue
result = risky_operation rescue default_value

# Custom exceptions
class DomainError < StandardError; end
raise DomainError, "Something went wrong"

# Result object pattern
Result.new(value: data)
Result.new(error: "Error message")
```

### Class Patterns

```ruby
# Basic class with initialization
class User
  attr_reader :name, :email
  attr_accessor :age
  
  def initialize(name:, email:, age: nil)
    @name = name
    @email = email
    @age = age
  end
  
  def adult?
    age && age >= 18
  end
end

# Class methods
class User
  def self.find_by_email(email)
    # Find user
  end
  
  class << self
    def admin_users
      # Return admins
    end
  end
end
```

### Module Patterns

```ruby
# Mixin module
module Timestamps
  def created_at
    @created_at ||= Time.now
  end
end

class Post
  include Timestamps
end

# Namespace module
module Payment
  class CreditCard; end
  class PayPal; end
end
```

### Collection Manipulation

```ruby
# Array operations
[1, 2, 3].map { |n| n * 2 }           # => [2, 4, 6]
[1, 2, 3].select { |n| n > 1 }        # => [2, 3]
[1, 2, 3].reject { |n| n > 1 }        # => [1]
[1, 2, 3].reduce(:+)                  # => 6
[1, 2, 3].reduce(0) { |sum, n| sum + n }

# Hash operations
{ a: 1, b: 2 }.transform_values(&:to_s)  # => { a: "1", b: "2" }
{ a: 1, b: 2 }.slice(:a)                 # => { a: 1 }
{ a: 1, b: 2 }.fetch(:c, 0)              # => 0

# Chaining
array.select { |x| x > 0 }
     .map { |x| x * 2 }
     .sort
```

### Blocks and Procs

```ruby
# Block
[1, 2, 3].each { |n| puts n }

# Proc
double = Proc.new { |x| x * 2 }
double.call(5)  # => 10

# Lambda
double = ->(x) { x * 2 }
double.call(5)  # => 10

# Block to proc
def method_with_block(&block)
  block.call(5)
end

method_with_block { |n| n * 2 }  # => 10
```

### String Operations

```ruby
# Interpolation
name = "World"
"Hello, #{name}!"  # => "Hello, World!"

# Common methods
"hello".upcase                    # => "HELLO"
"HELLO".downcase                  # => "hello"
"  hello  ".strip                 # => "hello"
"hello world".split               # => ["hello", "world"]
"hello".chars                     # => ["h", "e", "l", "l", "o"]

# Multiline strings
text = <<~TEXT
  This is a heredoc.
  Indentation is removed.
TEXT
```

### File Operations

```ruby
# Reading
content = File.read("file.txt")
lines = File.readlines("file.txt")

# Writing
File.write("file.txt", "content")

# Block-based (auto-closes)
File.open("file.txt") do |f|
  f.each_line { |line| puts line }
end

# Check existence
File.exist?("file.txt")
File.directory?("path")
```

### Regular Expressions

```ruby
# Matching
"hello" =~ /ell/                  # => 1 (position)
"hello".match(/h(..)lo/)          # => MatchData

# Capture groups
match = "john@example.com".match(/(\w+)@(\w+)/)
match[1]  # => "john"
match[2]  # => "example"

# Named captures
match = "john@example.com".match(/(?<user>\w+)@(?<domain>\w+)/)
match[:user]    # => "john"
match[:domain]  # => "example"

# Global replace
"hello world".gsub(/\w+/, "***")  # => "*** ***"
```

### Metaprogramming

```ruby
# method_missing
class Dynamic
  def method_missing(method, *args)
    "Called: #{method}"
  end
  
  def respond_to_missing?(method, *)
    true
  end
end

# define_method
%w[name email].each do |attr|
  define_method(attr) { instance_variable_get("@#{attr}") }
end

# class_eval
String.class_eval do
  def shout
    upcase + "!"
  end
end
```

### Modern Ruby (3.x+)

```ruby
# Pattern matching
case value
in { type: "user", name: name, age: age } if age > 18
  "Adult: #{name}"
in { type: "user", name: name }
  "User: #{name}"
end

# Endless methods
def double(x) = x * 2
def admin? = role == "admin"

# Numbered parameters
[1, 2, 3].map { _1 * 2 }
hash.map { [_1, _2.upcase] }

# Rightward assignment
fetch_user => user
user.name  # Use the assigned value
```

### Common Idioms

```ruby
# Safe navigation
user&.name  # Returns nil if user is nil

# Double pipe for default values
value ||= "default"

# Hash default values
counts = Hash.new(0)
counts[:key] += 1  # Works even if key doesn't exist

# Ternary operator
result = condition ? true_value : false_value

# Unless (opposite of if)
unless user.nil?
  process(user)
end

# Guard clauses
def method
  return unless valid?
  return if empty?
  # Main logic
end

# Splat operator
def method(first, *rest)
  # first is first arg, rest is array of remaining
end

method(1, 2, 3, 4)  # first=1, rest=[2,3,4]

# Double splat for keyword args
def method(**kwargs)
  kwargs  # Hash of all keyword arguments
end
```

### Testing Patterns

```ruby
# Minitest
class UserTest < Minitest::Test
  def setup
    @user = User.new(name: "John")
  end
  
  def test_name
    assert_equal "John", @user.name
  end
end

# RSpec
RSpec.describe User do
  let(:user) { User.new(name: "John") }
  
  it "has a name" do
    expect(user.name).to eq("John")
  end
  
  context "when adult" do
    let(:user) { User.new(name: "John", age: 30) }
    
    it "returns true for adult?" do
      expect(user.adult?).to be true
    end
  end
end
```

### Performance Tips

```ruby
# Use symbols for hash keys
{ name: "John" }  # Better than { "name" => "John" }

# Freeze strings
CONSTANT = "value".freeze

# Lazy evaluation for large collections
(1..1_000_000).lazy.select { |n| n.even? }.first(10)

# Memoization
def expensive_operation
  @result ||= compute_result
end

# String building
# Bad: str = ""; 1000.times { str += "x" }
# Good: str = ""; 1000.times { str << "x" }
# Best: Array.new(1000, "x").join
```

### Concurrency

```ruby
# Threads
threads = 3.times.map do |i|
  Thread.new(i) { |n| process(n) }
end
threads.each(&:join)

# Thread-safe with Mutex
mutex = Mutex.new
mutex.synchronize { critical_section }

# Ractors (parallel execution)
r = Ractor.new { expensive_calculation }
result = r.take
```

### Common Patterns

```ruby
# Builder pattern
UserBuilder.new
  .with_name("John")
  .with_email("john@example.com")
  .build

# Strategy pattern
class Processor
  def initialize(strategy)
    @strategy = strategy
  end
  
  def process(data)
    @strategy.call(data)
  end
end

# Null object pattern
class NullUser
  def name; "Guest"; end
  def admin?; false; end
end

current_user || NullUser.new
```

### Useful Standard Library

```ruby
# Benchmark
require 'benchmark'
Benchmark.bm { |x| x.report { code } }

# JSON
require 'json'
JSON.parse(string)
JSON.generate(hash)

# CSV
require 'csv'
CSV.read("file.csv")
CSV.open("file.csv", "w") { |csv| csv << ["a", "b"] }

# Date/Time
require 'date'
Date.today
DateTime.now
Time.now + 3600  # Add 1 hour

# Logger
require 'logger'
logger = Logger.new(STDOUT)
logger.info("Message")
logger.error("Error")
```

### Ruby on Rails Specific

```ruby
# Scopes
class User < ApplicationRecord
  scope :active, -> { where(active: true) }
  scope :recent, -> { where('created_at > ?', 1.week.ago) }
end

# Callbacks
class User < ApplicationRecord
  before_save :normalize_email
  after_create :send_welcome_email
end

# Validations
class User < ApplicationRecord
  validates :email, presence: true, uniqueness: true
  validates :age, numericality: { greater_than: 0 }
end

# Associations
class User < ApplicationRecord
  has_many :posts
  has_one :profile
  belongs_to :organization
end

# Strong parameters
def user_params
  params.require(:user).permit(:name, :email)
end
```

## Quick Commands

```bash
# Version
ruby -v

# Run file
ruby script.rb

# Interactive console
irb

# Check syntax
ruby -c script.rb

# Run with warnings
ruby -w script.rb

# Execute inline
ruby -e "puts 'hello'"

# Install gem
gem install gem_name

# Bundle install
bundle install
```

## Remember

1. **Everything is an object** - Even primitives
2. **Blocks are everywhere** - Embrace them
3. **Duck typing** - Focus on behavior, not types
4. **Convention over configuration** - Follow Ruby style
5. **Test your code** - Tests give confidence
6. **Be explicit about errors** - Fail fast and clearly
7. **Optimize when needed** - Profile before optimizing
8. **Use Ruby's features** - Leverage what the language provides
