# RuboCop Cop Reference

Comprehensive reference of all cop departments and their responsibilities.

## Core Cop Departments

RuboCop organizes cops into departments based on the type of issue they detect.

### Gemspec

Detects issues in `.gemspec` files.

**Examples:**
- `Gemspec/DuplicatedAssignment` - Detects duplicate gem specifications
- `Gemspec/OrderedDependencies` - Enforces alphabetical ordering of dependencies
- `Gemspec/RequiredRubyVersion` - Ensures required_ruby_version is specified

### Layout

Handles code formatting and whitespace.

**Key Cops:**
- `Layout/LineLength` - Enforces maximum line length (default: 120 chars)
- `Layout/IndentationConsistency` - Ensures consistent indentation
- `Layout/TrailingWhitespace` - Detects trailing whitespace
- `Layout/EmptyLines` - Manages empty lines between methods and blocks
- `Layout/SpaceAroundOperators` - Ensures spaces around operators
- `Layout/HashAlignment` - Aligns hash keys and values
- `Layout/FirstArrayElementIndentation` - Indents array elements consistently

**Usage:**
```bash
# Check only layout issues
rubocop --only Layout

# Auto-fix formatting
rubocop -x  # shortcut for layout autocorrection
```

### Lint

Identifies potential runtime errors and ambiguous code.

**Key Cops:**
- `Lint/Debugger` - Detects leftover debugger statements
- `Lint/UnusedBlockArgument` - Finds unused block parameters
- `Lint/UnusedMethodArgument` - Finds unused method parameters
- `Lint/ShadowingOuterLocalVariable` - Detects variable shadowing
- `Lint/UselessAssignment` - Identifies assignments never used
- `Lint/Void` - Detects void expressions in statement position
- `Lint/AmbiguousOperator` - Warns about ambiguous operators
- `Lint/DuplicateMethods` - Detects duplicate method definitions

**Example Violations:**
```ruby
# Lint/Debugger
def process
  debugger  # Remove before committing!
  result
end

# Lint/UnusedBlockArgument
users.each do |user|  # user is never used
  puts "Processing..."
end

# Lint/ShadowingOuterLocalVariable
name = "Alice"
users.each do |name|  # Shadows outer 'name'
  puts name
end
```

### Metrics

Enforces code complexity and size limits.

**Key Cops:**
- `Metrics/AbcSize` - Assignment, Branch, Condition complexity
- `Metrics/MethodLength` - Maximum method length (default: 10 lines)
- `Metrics/ClassLength` - Maximum class length (default: 100 lines)
- `Metrics/BlockLength` - Maximum block length
- `Metrics/CyclomaticComplexity` - Cyclomatic complexity score
- `Metrics/PerceivedComplexity` - Perceived code complexity
- `Metrics/ParameterLists` - Maximum number of parameters (default: 5)

**Configuration Examples:**
```yaml
Metrics/MethodLength:
  Max: 15
  Exclude:
    - 'db/migrate/*'
    - 'spec/**/*'

Metrics/BlockLength:
  Exclude:
    - 'spec/**/*'  # RSpec blocks can be long
    - 'config/routes.rb'
```

### Naming

Enforces Ruby naming conventions.

**Key Cops:**
- `Naming/MethodName` - Methods should use snake_case
- `Naming/ClassName` - Classes should use PascalCase
- `Naming/ConstantName` - Constants should use SCREAMING_SNAKE_CASE
- `Naming/VariableName` - Variables should use snake_case
- `Naming/PredicateName` - Boolean methods should end with ?
- `Naming/AccessorMethodName` - Getters/setters naming conventions
- `Naming/BinaryOperatorParameterName` - Binary operator parameter should be 'other'

**Examples:**
```ruby
# Good
class UserProfile
  MAXIMUM_AGE = 120
  
  def full_name
    "#{first_name} #{last_name}"
  end
  
  def active?
    status == :active
  end
end

# Bad
class userProfile  # Should be PascalCase
  MaxAge = 120     # Should be SCREAMING_SNAKE_CASE
  
  def fullName     # Should be snake_case
  end
  
  def isActive     # Should end with ?
  end
end
```

### Security

Detects potential security vulnerabilities.

**Key Cops:**
- `Security/Eval` - Detects use of eval
- `Security/JSONLoad` - Prefers JSON.parse over JSON.load
- `Security/MarshalLoad` - Warns about Marshal.load
- `Security/YAMLLoad` - Prefers YAML.safe_load
- `Security/Open` - Detects dangerous usage of open

**Examples:**
```ruby
# Bad - Security risks
eval(user_input)              # Code injection
JSON.load(untrusted_data)     # Potential arbitrary code execution
Marshal.load(data)            # Potential arbitrary code execution
YAML.load(file)               # Potential arbitrary code execution

# Good - Safer alternatives
# Don't use eval with user input
JSON.parse(untrusted_data)    # Safe JSON parsing
# Use Marshal carefully
YAML.safe_load(file, permitted_classes: [Date, Time])
```

### Style

Enforces community Ruby style conventions.

**Key Cops:**
- `Style/StringLiterals` - Single vs double quotes
- `Style/HashSyntax` - Hash rocket vs new syntax
- `Style/Documentation` - Requires class/module documentation
- `Style/FrozenStringLiteralComment` - Frozen string literal comments
- `Style/TrailingCommaInArrayLiteral` - Trailing commas in arrays
- `Style/GuardClause` - Prefer guard clauses over nested conditionals
- `Style/ConditionalAssignment` - Prefer conditional assignment
- `Style/SymbolArray` - Use %i for symbol arrays

**Common Style Choices:**
```yaml
# Single quotes (default)
Style/StringLiterals:
  EnforcedStyle: single_quotes

# Or double quotes
Style/StringLiterals:
  EnforcedStyle: double_quotes

# Modern hash syntax
Style/HashSyntax:
  EnforcedStyle: ruby19  # { key: value }
  # or: hash_rockets     # { :key => value }

# Trailing commas
Style/TrailingCommaInArrayLiteral:
  EnforcedStyleForMultiline: consistent_comma  # Always include
```

**Examples:**
```ruby
# Style/StringLiterals (single_quotes)
message = 'Hello'         # Good
message = "Hello"         # Bad (unless interpolation)
message = "Hello #{name}" # Good (interpolation needed)

# Style/HashSyntax (ruby19)
user = { name: 'Alice', age: 30 }        # Good
user = { :name => 'Alice', :age => 30 }  # Bad

# Style/GuardClause
# Bad
def process(user)
  if user.present?
    user.update(status: :active)
  end
end

# Good
def process(user)
  return unless user.present?
  
  user.update(status: :active)
end
```

## Extension Departments

### Rails (rubocop-rails)

Rails-specific best practices and conventions.

**Installation:**
```yaml
# .rubocop.yml
plugins:
  - rubocop-rails

AllCops:
  TargetRailsVersion: 7.0
```

**Key Cops:**

**ActiveRecord:**
- `Rails/FindBy` - Prefer `find_by` over `where.first`
- `Rails/FindEach` - Use `find_each` for large datasets
- `Rails/HasManyOrHasOneDependent` - Require dependent: option
- `Rails/ReversibleMigration` - Ensure migrations are reversible
- `Rails/BulkChangeTable` - Combine multiple schema changes

**Controllers:**
- `Rails/ActionOrder` - Enforce standard action order
- `Rails/ApplicationController` - Inherit from ApplicationController
- `Rails/HttpStatus` - Use symbolic HTTP status codes

**Models:**
- `Rails/ApplicationRecord` - Inherit from ApplicationRecord
- `Rails/InverseOf` - Specify inverse_of on associations
- `Rails/Validation` - Use new validation syntax

**Views/Helpers:**
- `Rails/OutputSafety` - Avoid raw and html_safe
- `Rails/ContentTag` - Use tag helpers instead of content_tag
- `Rails/LinkToBlank` - Add rel="noopener" to target="_blank"

**Examples:**
```ruby
# Rails/FindBy
# Bad
User.where(email: email).first
# Good
User.find_by(email: email)

# Rails/FindEach
# Bad - Loads all records into memory
User.all.each do |user|
  user.process
end
# Good - Batches queries
User.find_each do |user|
  user.process
end

# Rails/HasManyOrHasOneDependent
class User < ApplicationRecord
  has_many :posts, dependent: :destroy  # Good
  has_many :posts                       # Bad - what happens on delete?
end

# Rails/HttpStatus
# Bad
render status: 200
redirect_to root_path, status: 301
# Good
render status: :ok
redirect_to root_path, status: :moved_permanently
```

### RSpec (rubocop-rspec)

RSpec testing conventions and best practices.

**Installation:**
```yaml
# .rubocop.yml
plugins:
  - rubocop-rspec
```

**Key Cops:**

**Structure:**
- `RSpec/DescribeClass` - Describe should specify a class
- `RSpec/FilePath` - Spec file path should match class
- `RSpec/MultipleDescribes` - One top-level describe per file
- `RSpec/NestedGroups` - Limit nested context/describe depth

**Examples:**
- `RSpec/ExampleLength` - Keep examples short (default: 5 lines)
- `RSpec/MultipleExpectations` - Limit expectations per example
- `RSpec/NamedSubject` - Use named subjects
- `RSpec/LetSetup` - Avoid let! for setup

**Matchers:**
- `RSpec/PredicateMatcher` - Use predicate matchers
- `RSpec/BeEq` - Use be matcher appropriately
- `RSpec/ExpectChange` - Prefer expect { }.to change syntax

**Examples:**
```ruby
# RSpec/DescribeClass
# Bad
RSpec.describe 'User authentication' do
end
# Good
RSpec.describe User do
  describe '#authenticate' do
  end
end

# RSpec/ExampleLength
# Bad - too long
it 'processes user' do
  user = create(:user)
  authenticator = Authenticator.new
  token = authenticator.generate(user)
  result = authenticator.validate(token)
  expect(result).to be_truthy
  # ... 10 more lines
end
# Good - focused
it 'generates valid authentication token' do
  user = create(:user)
  token = Authenticator.new.generate(user)
  expect(token).to be_valid
end

# RSpec/PredicateMatcher
# Bad
expect(user.active?).to be_truthy
# Good
expect(user).to be_active

# RSpec/MultipleExpectations (Max: 2)
# Bad
it 'validates user' do
  expect(user).to be_valid
  expect(user.name).to eq('Alice')
  expect(user.email).to eq('alice@example.com')
end
# Good - split into focused examples
it { is_expected.to be_valid }
it { expect(user.name).to eq('Alice') }
it { expect(user.email).to eq('alice@example.com') }
```

### Performance (rubocop-performance)

Performance optimization recommendations.

**Installation:**
```yaml
# .rubocop.yml
plugins:
  - rubocop-performance
```

**Key Cops:**

**String Operations:**
- `Performance/StringInclude` - Use String#include? over regex
- `Performance/StringReplacement` - Use String#tr over gsub
- `Performance/FixedSize` - Use Array#take/drop for slicing
- `Performance/RegexpMatch` - Use match? for boolean checks

**Collections:**
- `Performance/Size` - Use #size over #count for collections
- `Performance/CompareWithBlock` - Use sort_by over sort with block
- `Performance/Detect` - Use detect over select.first
- `Performance/ReverseEach` - Use reverse_each over reverse.each

**Examples:**
```ruby
# Performance/StringInclude
# Bad
/foo/.match?(string)
# Good
string.include?('foo')

# Performance/StringReplacement
# Bad
string.gsub('a', 'b')
# Good
string.tr('a', 'b')

# Performance/Size
# Bad
array.count
# Good
array.size  # or array.length

# Performance/CompareWithBlock
# Bad
array.sort { |a, b| a.name <=> b.name }
# Good
array.sort_by(&:name)

# Performance/Detect
# Bad
users.select { |u| u.admin? }.first
# Good
users.detect(&:admin?)  # or .find

# Performance/ReverseEach
# Bad
array.reverse.each { |item| process(item) }
# Good
array.reverse_each { |item| process(item) }
```

## Cop Severity Levels

Cops are classified by severity:

- **Info (I)**: Informational suggestions
- **Refactor (R)**: Refactoring opportunities
- **Convention (C)**: Coding style violations (most common)
- **Warning (W)**: Potential problems
- **Error (E)**: Definite problems
- **Fatal (F)**: Syntax errors

**Override severity:**
```yaml
Style/StringLiterals:
  Severity: warning  # Escalate from convention to warning

Metrics/MethodLength:
  Severity: error    # Make violations more serious
```

## Cop Status

Cops can have different statuses:

- **Enabled**: Active by default
- **Disabled**: Not run unless explicitly enabled
- **Pending**: Not run by default in new installations

**New cops handling:**
```yaml
AllCops:
  NewCops: enable   # Auto-enable new cops
  # or
  NewCops: pending  # Keep new cops pending
  # or
  NewCops: disable  # Keep new cops disabled
```

## Autocorrection Support

Cops are categorized by autocorrect capabilities:

**Safe Autocorrect** (included in `-a`):
- Guaranteed not to change code behavior
- Examples: fixing indentation, adding spaces

**Unsafe Autocorrect** (requires `-A`):
- Might change code semantics
- Requires review before committing
- Examples: converting `select.first` to `detect`

**Manual Only**:
- No autocorrect available
- Requires manual fixing
- Examples: reducing method complexity

## Department-Level Commands

```bash
# Run only specific departments
rubocop --only Layout
rubocop --only Style,Naming
rubocop --only Lint,Security

# Exclude departments
rubocop --except Metrics
rubocop --except Style,Layout

# List all cops in a department
rubocop --show-cops Style
```

## Custom Departments

For custom cops, organize by department:

```ruby
# lib/rubocop/cop/custom_department/custom_cop.rb
module RuboCop
  module Cop
    module CustomDepartment
      class CustomCop < Base
        # Cop implementation
      end
    end
  end
end
```

**Configuration:**
```yaml
CustomDepartment/CustomCop:
  Description: 'Custom cop description'
  Enabled: true
