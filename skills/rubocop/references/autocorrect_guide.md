# RuboCop Autocorrect Guide

Understanding safe and unsafe autocorrection in RuboCop.

## Autocorrect Modes

### Safe Autocorrect (`-a` or `--autocorrect`)

Applies only corrections that are guaranteed not to change code behavior.

```bash
rubocop -a
# or
rubocop --autocorrect
```

**What gets corrected:**
- Indentation and formatting
- Adding/removing whitespace
- Quote style changes (when semantically identical)
- Adding missing frozen string literals
- Most Layout cops

**What doesn't get corrected:**
- Cops with `SafeAutoCorrect: false`
- Cops with `Safe: false`
- Changes that might alter program behavior

### Unsafe Autocorrect (`-A` or `--autocorrect-all`)

Applies all available corrections, including those that might change semantics.

```bash
rubocop -A
# or
rubocop --autocorrect-all
```

**Additional corrections:**
- Converting `select.first` to `detect`
- Changing `where.first` to `find_by`
- Converting collection methods
- Performance optimizations
- Some style transformations

**Always review changes after using `-A`!**

### Layout-Only Autocorrect (`-x` or `--fix-layout`)

Shortcut for correcting only formatting/layout issues.

```bash
rubocop -x
# Equivalent to:
rubocop -a --only Layout
```

## Safety Annotations

### Safe vs Unsafe Cops

**Safe Cop:**
```yaml
Style/StringLiterals:
  Safe: true  # Won't produce false positives
```

**Unsafe Cop:**
```yaml
Lint/UnusedMethodArgument:
  Safe: false  # Might flag valid metaprogramming
```

### Safe vs Unsafe Autocorrect

**Safe autocorrect only:**
```yaml
Layout/SpaceAroundOperators:
  Safe: true
  SafeAutoCorrect: true  # Always safe to apply
```

**Unsafe autocorrect:**
```yaml
Performance/Detect:
  Safe: true              # Detection is safe
  SafeAutoCorrect: false  # Correction might change behavior
```

## Common Safe Corrections

### Layout and Formatting

```ruby
# Before
def method( x,y )
result=x+y
end

# After (rubocop -a)
def method(x, y)
  result = x + y
end
```

### String Literals

```ruby
# Before (with EnforcedStyle: single_quotes)
message = "Hello"

# After (rubocop -a)
message = 'Hello'
```

### Trailing Comma

```ruby
# Before (with EnforcedStyleForMultiline: comma)
array = [
  1,
  2,
  3
]

# After (rubocop -a)
array = [
  1,
  2,
  3,
]
```

## Common Unsafe Corrections

### Detect vs Select.first

```ruby
# Before
users.select { |u| u.admin? }.first

# After (rubocop -A)
users.detect(&:admin?)

# Why unsafe: behavior differs if block has side effects
results = []
users.select { |u| results << u; u.admin? }.first
# select processes all elements
# detect stops at first match
```

### Where.first vs Find_by

```ruby
# Before
User.where(email: email).first

# After (rubocop -A)
User.find_by(email: email)

# Why unsafe: ordering might matter
User.where(status: :active).order(:created_at).first
# find_by doesn't preserve ordering in all cases
```

### Map.flatten vs Flat_map

```ruby
# Before
array.map { |x| [x, x * 2] }.flatten

# After (rubocop -A)
array.flat_map { |x| [x, x * 2] }

# Why unsafe: flatten(1) vs flatten
[[1, [2]]].map { |x| x }.flatten
# => [1, 2]
[[1, [2]]].flat_map { |x| x }
# => [1, [2]]
```

## Selective Autocorrection

### Autocorrect Specific Cops

```bash
# Fix only string literals
rubocop -a --only Style/StringLiterals

# Fix multiple cops
rubocop -a --only Style/StringLiterals,Layout/TrailingWhitespace

# Fix entire department
rubocop -a --only Layout
```

### Exclude from Autocorrection

```yaml
Style/StringLiterals:
  AutoCorrect: false  # Never autocorrect
  
Metrics/MethodLength:
  # This cop has no autocorrect ability
```

## Reviewing Changes

### Recommended Workflow

```bash
# 1. Run safe autocorrection
rubocop -a

# 2. Review changes
git diff

# 3. Run tests
rspec

# 4. Commit safe changes
git add -A
git commit -m "Apply safe RuboCop corrections"

# 5. Run unsafe autocorrection selectively
rubocop -A --only Performance/Detect

# 6. Review and test each unsafe change
git diff
rspec

# 7. Commit when verified
git commit -m "Apply Performance/Detect optimization"
```

### Using TODO File Approach

```bash
# Generate todo file
rubocop --auto-gen-config

# Fix one cop at a time
rubocop -a --only Style/StringLiterals
# Review, test, commit

# Remove from todo file and continue
rubocop -a --only Layout/SpaceAroundOperators
# Review, test, commit
```

## Autocorrect Configuration

### Disable Autocorrect Globally

```yaml
AllCops:
  AutoCorrect: false  # Never autocorrect anything
```

### Disable Per-Cop

```yaml
Style/StringLiterals:
  Enabled: true      # Still check
  AutoCorrect: false # But don't fix
```

### Conditional Autocorrect

```yaml
# Different settings per directory
Style/StringLiterals:
  AutoCorrect: true
  Include:
    - 'app/**/*'

Style/StringLiterals:
  AutoCorrect: false
  Include:
    - 'legacy/**/*'
```

## Stdin/Stdout Autocorrection

For editor integration:

```bash
# Read from stdin, output corrected code to stdout
echo 'def bad( x,y )' | rubocop -a --stdin - --stderr

# For editor integration
rubocop -a --stdin filename.rb --format quiet
```

## Troubleshooting

**Autocorrection not working:**

```bash
# Check if cop supports autocorrection
rubocop --show-cops Style/StringLiterals | grep -i autocorrect

# Verify cop is enabled
rubocop --show-cops Style/StringLiterals | grep -i enabled

# Check if using -A is needed
rubocop --show-cops Style/StringLiterals | grep -i safe
```

**Conflicting corrections:**

Some cops may conflict. RuboCop runs multiple passes but might not resolve all conflicts.

```bash
# Run multiple times until stable
rubocop -a
rubocop -a  # Run again to catch missed issues
```

**Performance issues:**

```yaml
AllCops:
  UseCache: true  # Enable caching for faster reruns
```

## Best Practices

1. **Start with safe corrections** (`-a`)
2. **Review all changes** before committing
3. **Run tests** after autocorrection
4. **Use unsafe corrections selectively** (one cop at a time with `-A`)
5. **Commit incrementally** (one cop category per commit)
6. **Keep todo file** for gradual cleanup
7. **Use in CI** to prevent new violations
