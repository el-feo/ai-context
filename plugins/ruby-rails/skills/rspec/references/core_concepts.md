# RSpec Core Concepts

Deep dive into RSpec's fundamental building blocks and organizational structures.

## Table of Contents

1. [Describe and Context Blocks](#describe-and-context-blocks)
2. [Examples (it, specify, example)](#examples)
3. [Hooks (before, after, around)](#hooks)
4. [Let and Subject](#let-and-subject)
5. [Scope and Execution Order](#scope-and-execution-order)
6. [Metadata and Tags](#metadata-and-tags)
7. [Shared Examples](#shared-examples)
8. [Shared Contexts](#shared-contexts)

## Describe and Context Blocks

### Purpose

- **describe**: Defines an example group that represents a class or feature
- **context**: Defines a specific scenario or state within a describe block

```ruby
RSpec.describe User do  # Top-level describe
  describe '#full_name' do  # Method describe
    context 'when first and last name are present' do  # Specific scenario
      it 'combines them' do
        # test code
      end
    end
    
    context 'when only first name is present' do  # Different scenario
      it 'returns only first name' do
        # test code
      end
    end
  end
end
```

### Nesting and Organization

Nested groups create subclasses, providing inheritance:

```ruby
RSpec.describe 'Outer group' do
  let(:value) { 'outer' }
  
  it 'has access to outer value' do
    expect(value).to eq('outer')
  end
  
  context 'Inner group' do
    let(:value) { 'inner' }  # Overrides outer value
    
    it 'has access to inner value' do
      expect(value).to eq('inner')
    end
  end
end
```

### Best Practices

1. **Use describe for things** (nouns):
   - Classes: `describe User`
   - Methods: `describe '#method_name'` (instance) or `describe '.method_name'` (class)

2. **Use context for states** (adjectives/scenarios):
   - `context 'when user is admin'`
   - `context 'with invalid data'`
   - `context 'on a mobile device'`

3. **Keep nesting shallow** (max 3-4 levels):
```ruby
# Good
describe Article do
  describe '#publish' do
    context 'when article is draft' do
      it 'changes status to published'
    end
  end
end

# Too deep - hard to follow
describe Article do
  describe '#publish' do
    context 'when article is draft' do
      context 'and author is active' do
        context 'and article has content' do
          context 'and date is valid' do
            it 'changes status to published'  # Lost in nesting
          end
        end
      end
    end
  end
end
```

## Examples

### Three Ways to Define Examples

```ruby
describe 'Examples' do
  it 'uses it for natural language' do
    # Most common
  end
  
  specify 'uses specify for sentences' do
    # When 'it' doesn't read well
  end
  
  example 'uses example as an alias' do
    # Least common
  end
end
```

### Example Documentation

```ruby
describe User do
  # Good: Descriptive and specific
  it 'sends welcome email after creation' do
  end
  
  # Bad: Vague and unclear
  it 'works' do
  end
  
  # Good: Tests one thing
  it 'validates email format' do
  end
  
  # Bad: Tests multiple things
  it 'validates email and password and username' do
  end
end
```

### Pending Examples

```ruby
describe 'Pending specs' do
  # Mark as pending with xit
  xit 'will implement this later' do
    # Won't run
  end
  
  # Or call pending inside
  it 'will implement this later' do
    pending('waiting for API update')
    # Rest of test won't run
  end
  
  # Or omit block entirely
  it 'will implement this later'
end
```

## Hooks

### Before Hooks

Run code before examples:

```ruby
describe 'Before hooks' do
  before(:suite) do
    # Runs once before all specs in the suite
    DatabaseCleaner.start
  end
  
  before(:context) do  # Also before(:all)
    # Runs once before all examples in this describe block
    # Use sparingly - can cause test interdependencies
    @shared_data = 'shared'
  end
  
  before(:each) do  # Default - also before(:example)
    # Runs before each individual example
    @user = User.new
  end
end
```

### After Hooks

Run code after examples (opposite order of before):

```ruby
describe 'After hooks' do
  after(:each) do  # Default
    # Runs after each example
    # Useful for cleanup
    DatabaseCleaner.clean
  end
  
  after(:context) do  # Also after(:all)
    # Runs once after all examples in this describe block
  end
  
  after(:suite) do
    # Runs once after all specs in the suite
  end
end
```

### Around Hooks

Wrap examples with setup and teardown:

```ruby
describe 'Around hooks' do
  around(:each) do |example|
    # Setup before example
    Time.use_zone('UTC') do
      example.run  # Must call this!
    end
    # Teardown after example
  end
end
```

### Hook Execution Order

```ruby
describe 'Hook order' do
  before(:context) { puts '1. before :context' }
  before(:each)    { puts '2. before :each' }
  after(:each)     { puts '3. after :each' }
  after(:context)  { puts '4. after :context' }
  
  it 'first example' do
    puts '  example 1'
  end
  
  it 'second example' do
    puts '  example 2'
  end
end

# Output:
# 1. before :context
# 2. before :each
#   example 1
# 3. after :each
# 2. before :each
#   example 2
# 3. after :each
# 4. after :context
```

## Let and Subject

### Let - Lazy Evaluation

```ruby
describe 'Let' do
  let(:user) { User.new(name: 'John') }
  
  it 'creates user on first access' do
    # user is created here (lazy)
    expect(user.name).to eq('John')
  end
  
  it 'creates new user for each example' do
    # Fresh user instance for this example
    expect(user).to be_a(User)
  end
end
```

### Let! - Eager Evaluation

```ruby
describe 'Let!' do
  let!(:admin) { User.create(role: 'admin') }
  
  it 'creates user before example runs' do
    # admin already created before this line
    expect(User.count).to eq(1)
  end
end
```

### Subject - Implicit and Explicit

```ruby
describe User do
  # Implicit subject
  it { is_expected.to be_valid }
  # equivalent to: expect(subject).to be_valid
  # subject is User.new
  
  # Explicit subject
  subject { User.new(name: 'John') }
  
  it 'has a name' do
    expect(subject.name).to eq('John')
  end
  
  # Named subject
  subject(:john) { User.new(name: 'John') }
  
  it 'can be referenced by name' do
    expect(john.name).to eq('John')
  end
end
```

### Let vs Before

```ruby
describe 'Let vs Before' do
  # With let (preferred for most cases)
  let(:user) { User.new }
  
  it 'creates user lazily' do
    # user created here
  end
  
  it 'might not use user' do
    # user not created if not referenced
  end
  
  # With before
  before do
    @user = User.new
  end
  
  it 'creates user always' do
    # @user created even if not used
  end
end
```

**When to use let:**
- Default choice for test data
- Data only needed in some examples
- Want to override in nested contexts

**When to use let!:**
- Need data created before example runs
- Setting up database records for queries
- Side effects matter (callbacks, etc.)

**When to use before:**
- Non-data setup (signing in, stubbing, etc.)
- Imperative setup that doesn't return a value
- Complex setup that doesn't fit in one line

## Scope and Execution Order

### Example Group Scope vs Example Scope

```ruby
RSpec.describe 'Scopes' do
  # Example group scope - runs when file loads
  puts "This runs when the file loads"
  
  let(:value) { puts "Let called"; 'value' }
  
  before(:each) do
    # Example scope - runs before each example
    puts "Before hook runs"
  end
  
  it 'first example' do
    # Example scope - runs for each example
    puts "Example runs"
    puts value  # Let evaluated here
  end
end
```

### Complete Execution Order

```ruby
# 1. Example group (describe/context) blocks evaluated
# 2. before(:suite) hooks
# 3. For each example group:
#    - before(:context) hooks
#    - For each example:
#      - before(:each) hooks
#      - let blocks (when accessed)
#      - example code
#      - after(:each) hooks
#    - after(:context) hooks
# 4. after(:suite) hooks

describe 'Complete order' do
  before(:suite)   { puts '1' }
  before(:context) { puts '2' }
  before(:each)    { puts '3' }
  
  let(:data)       { puts '4'; 'data' }
  
  it 'example' do
    puts '5'
    data  # triggers let
    puts '6'
  end
  
  after(:each)     { puts '7' }
  after(:context)  { puts '8' }
  after(:suite)    { puts '9' }
end

# Output: 1, 2, 3, 5, 4, 6, 7, 8, 9
```

## Metadata and Tags

### Adding Metadata

```ruby
describe 'Metadata' do
  it 'has metadata', :fast do
    # Tagged as :fast
  end
  
  it 'has multiple tags', :slow, :js do
    # Tagged as both :slow and :js
  end
  
  it 'has hash metadata', priority: 'high', wip: true do
    # Custom metadata
  end
  
  # Access metadata in example
  it 'reads its own metadata' do |example|
    puts example.metadata[:description]  # => "reads its own metadata"
    puts example.metadata[:file_path]
    puts example.metadata[:line_number]
  end
end
```

### Running Tagged Specs

```bash
# Run only fast specs
rspec --tag fast

# Run everything except slow specs
rspec --tag ~slow

# Run specs with multiple tags
rspec --tag js --tag slow

# Run specs matching tag value
rspec --tag priority:high
```

### Conditional Execution

```ruby
describe 'Conditional' do
  it 'runs only on CI', if: ENV['CI'] do
    # Only runs when CI env var is set
  end
  
  it 'skips on CI', unless: ENV['CI'] do
    # Skips when CI env var is set
  end
end
```

## Shared Examples

### Defining and Using

```ruby
# Define shared examples
RSpec.shared_examples 'a collection' do
  it 'is empty when created' do
    expect(subject).to be_empty
  end
  
  it 'increases size when items added' do
    subject << :item
    expect(subject.size).to eq(1)
  end
end

# Use with it_behaves_like
describe Array do
  subject { Array.new }
  it_behaves_like 'a collection'
end

describe Hash do
  subject { Hash.new }
  it_behaves_like 'a collection'
end

# Alternative: include_examples
describe Set do
  subject { Set.new }
  include_examples 'a collection'
end
```

### Parameterized Shared Examples

```ruby
RSpec.shared_examples 'validates field' do |field_name|
  it "requires #{field_name}" do
    record = described_class.new
    record.send("#{field_name}=", nil)
    expect(record).not_to be_valid
    expect(record.errors[field_name]).to include("can't be blank")
  end
end

describe User do
  it_behaves_like 'validates field', :email
  it_behaves_like 'validates field', :password
end
```

### Shared Examples with Blocks

```ruby
RSpec.shared_examples 'sorts collection' do
  it 'returns items in order' do
    result = yield  # Execute the block passed in
    expect(result).to eq(result.sort)
  end
end

describe 'Array sorting' do
  include_examples 'sorts collection' do
    [3, 1, 2].sort
  end
end
```

## Shared Contexts

### Basic Usage

```ruby
RSpec.shared_context 'logged in user' do
  let(:current_user) { create(:user) }
  
  before do
    sign_in current_user
  end
end

describe ArticlesController do
  include_context 'logged in user'
  
  it 'allows access' do
    get :index
    expect(response).to be_successful
  end
end
```

### Auto-Including Contexts

```ruby
# spec/support/shared_contexts/api_context.rb
RSpec.shared_context 'API headers', type: :request do
  let(:headers) do
    {
      'Accept' => 'application/json',
      'Content-Type' => 'application/json'
    }
  end
end

# Configure auto-inclusion
RSpec.configure do |config|
  config.include_context 'API headers', type: :request
end

# Now available in all request specs without explicit inclusion
describe 'API', type: :request do
  it 'has headers available' do
    get '/api/articles', headers: headers
  end
end
```

### Difference: Shared Examples vs Shared Contexts

**Shared Examples:**
- Focus on behavior testing
- Contain actual examples (it blocks)
- Test that objects behave similarly
- Use: `it_behaves_like` or `include_examples`

**Shared Contexts:**
- Focus on setup and context
- Contain setup code (let, before, helper methods)
- Provide common test environment
- Use: `include_context`

```ruby
# Shared example - testing behavior
RSpec.shared_examples 'auditable' do
  it { is_expected.to have_many(:audits) }
  it { is_expected.to respond_to(:audit_changes) }
end

# Shared context - providing setup
RSpec.shared_context 'with auditing enabled' do
  before do
    allow(Audit).to receive(:enabled?).and_return(true)
  end
  
  let(:audit_logger) { double('AuditLogger') }
end
```

## Best Practices Summary

1. **Use describe for things (nouns), context for states (conditions)**
2. **Prefer let over instance variables for test data**
3. **Use let! when you need eager evaluation**
4. **Keep nesting shallow (max 3-4 levels)**
5. **Use subject for the primary object being tested**
6. **Avoid before(:context) unless you understand the implications**
7. **Use shared examples for common behaviors**
8. **Use shared contexts for common setup**
9. **Tag specs for different execution scenarios**
10. **Write descriptive example names that complete the sentence started by 'it'**

