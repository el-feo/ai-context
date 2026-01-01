# RuboCop Configuration Guide

Comprehensive reference for configuring RuboCop to match your project's needs and coding standards.

## Configuration File Hierarchy

### File Discovery Order

RuboCop searches for configuration in this order (first found wins):

1. `.rubocop.yml` in current/parent directories up to project root
2. `.config/.rubocop.yml` at project root
3. `$XDG_CONFIG_HOME/rubocop/config.yml` (usually `~/.config/rubocop/config.yml`)
4. `~/.rubocop.yml` (global home directory config)
5. RuboCop's built-in `config/default.yml`

### Project Root Detection

RuboCop automatically detects project roots by finding:
- `.git` directory
- `.rubocop.yml` with `AllCops: RootDirectory:`

## AllCops Configuration

Global settings that apply to all cops:

```yaml
AllCops:
  # Target Ruby version - adjusts which cops and syntax are valid
  TargetRubyVersion: 3.2  # Or: 2.7, 3.0, 3.1, 3.3
  
  # How to handle new cops in updated versions
  NewCops: enable  # Options: enable, disable, pending
  
  # Files and directories to exclude from analysis
  Exclude:
    - 'db/schema.rb'
    - 'db/migrate/*.rb'
    - 'vendor/**/*'
    - 'node_modules/**/*'
    - 'tmp/**/*'
    
  # Files to include (by default all .rb files + some others)
  Include:
    - '**/*.rb'
    - '**/*.rake'
    - '**/Gemfile'
    - '**/Rakefile'
    
  # Enable result caching for faster subsequent runs
  UseCache: true
  CacheRootDirectory: tmp/rubocop_cache
  
  # Maximum files to list when using --auto-gen-config
  MaxFilesInCache: 20000
  
  # Display style guide URLs in offense messages
  DisplayStyleGuide: false
  StyleGuideBaseURL: https://rubystyle.guide
  
  # Documentation URLs for cops
  DocumentationBaseURL: https://docs.rubocop.org/rubocop
  
  # Show extra details in messages
  ExtraDetails: false
  
  # Parallel execution (enabled by default)
  UseCache: true
```

## Inheritance

### Inheriting from Files

```yaml
# Inherit from local files
inherit_from:
  - .rubocop_todo.yml
  - config/rubocop_base.yml

# Inherit from remote URLs
inherit_from:
  - https://example.com/rubocop-config.yml

# Inherit from gem configurations
inherit_gem:
  rubocop-github:
    - config/default.yml
```

### Inheritance Behavior

- Child configs **override** parent settings
- Hash parameters (like `PreferredMethods`) are **merged**
- Use `~` (nil) to cancel a parent setting:

```yaml
Style/CollectionMethods:
  PreferredMethods:
    collect: ~ # Cancels parent's preference
```

## Enabling/Disabling Cops

### By Individual Cop

```yaml
# Explicitly enable
Style/StringLiterals:
  Enabled: true

# Explicitly disable
Style/Documentation:
  Enabled: false

# Pending status (not run unless explicitly requested)
Style/NewCopName:
  Enabled: pending
```

### By Department

```yaml
# Disable all metrics cops
Metrics:
  Enabled: false

# Enable all layout cops
Layout:
  Enabled: true
```

### By Pattern

```yaml
# Run only cops matching pattern
AllCops:
  Only:
    - Style/*
    - Layout/*

# Run all except these cops
AllCops:
  Except:
    - Metrics/AbcSize
    - Metrics/MethodLength
```

## Excluding Files and Directories

### Global Exclusions

```yaml
AllCops:
  Exclude:
    - 'db/**/*'
    - 'config/**/*'
    - 'script/**/*'
```

### Per-Cop Exclusions

```yaml
Style/StringLiterals:
  Exclude:
    - 'spec/**/*'          # Exclude all spec files
    - 'lib/legacy/**/*'    # Exclude legacy code
    - 'app/models/old.rb'  # Exclude specific file
```

### Include Patterns

```yaml
# Override default exclusions for specific files
Rails/FilePath:
  Include:
    - '**/Gemfile'
    - '**/config.ru'
```

## Cop-Specific Configuration

### Common Patterns

**Enforced Styles:**
```yaml
Style/StringLiterals:
  EnforcedStyle: double_quotes  # or: single_quotes
  
Style/ClassAndModuleChildren:
  EnforcedStyle: nested  # or: compact
  
Layout/HashAlignment:
  EnforcedHashRocketStyle: key  # or: separator, table
  EnforcedColonStyle: key       # or: separator, table
```

**Thresholds:**
```yaml
Metrics/MethodLength:
  Max: 15                    # Maximum lines per method
  CountComments: false       # Exclude comments from count
  AllowedMethods: []         # Methods exempt from check
  
Metrics/ClassLength:
  Max: 100
  CountAsOne: ['array', 'hash', 'heredoc']  # Count as single line
  
Metrics/AbcSize:
  Max: 18  # Assignment, Branch, Condition complexity
```

**Lists and Preferences:**
```yaml
Style/CollectionMethods:
  PreferredMethods:
    collect: 'map'
    inject: 'reduce'
    find: 'detect'
    
Naming/PredicateName:
  ForbiddenPrefixes:
    - is_
    - have_
  AllowedMethods:
    - is_a?
```

## Rails Configuration

```yaml
# Enable rubocop-rails plugin
plugins:
  - rubocop-rails

# Specify Rails version for relevant cops
AllCops:
  TargetRailsVersion: 7.0  # or: 5.0, 6.0, 6.1, 7.1

# Rails-specific settings
Rails:
  Enabled: true

# Schema version to ignore old migrations
Rails/MigratedSchemaVersion:
  MigratedSchemaVersion: '20240101000000'

# Specific cop configuration
Rails/ApplicationRecord:
  Enabled: true
  Exclude:
    - 'db/migrate/**'

Rails/HasManyOrHasOneDependent:
  Enabled: true

Rails/SkipsModelValidations:
  AllowedMethods:
    - touch
    - update_attribute
```

## RSpec Configuration

```yaml
# Enable rubocop-rspec plugin
plugins:
  - rubocop-rspec

# Configure RSpec cops
RSpec/ExampleLength:
  Max: 10
  CountAsOne: ['array', 'hash', 'heredoc']

RSpec/MultipleExpectations:
  Max: 3

RSpec/NestedGroups:
  Max: 4

RSpec/DescribeClass:
  Exclude:
    - 'spec/requests/**/*'
    - 'spec/system/**/*'
```

## Performance Configuration

```yaml
# Enable rubocop-performance plugin
plugins:
  - rubocop-performance

# Most performance cops are enabled by default
# Disable specific ones if needed
Performance/Casecmp:
  Enabled: false  # Only works with ASCII strings
```

## Safe vs Unsafe Cops

Understanding safety annotations:

```yaml
# Cop can produce false positives
Style/SomeUnsafeCop:
  Safe: false  # Excluded from --safe runs
  
# Cop is safe, but autocorrect might change semantics
Style/SomeCop:
  Safe: true
  SafeAutoCorrect: false  # Excluded from -a, included in -A
```

**Command-line interaction:**
- `rubocop` - Runs all enabled cops
- `rubocop --safe` - Runs only cops with `Safe: true`
- `rubocop -a` - Autocorrects with `SafeAutoCorrect: true`
- `rubocop -A` - Autocorrects all, including unsafe

## Custom Severity Levels

```yaml
# Override default severity
Style/StringLiterals:
  Severity: warning  # Options: info, refactor, convention, warning, error, fatal

# Set fail level for CI
# rubocop --fail-level warning
```

## Todo Configuration

Generate and manage technical debt:

```bash
# Generate .rubocop_todo.yml with all current offenses
rubocop --auto-gen-config

# Auto-correct and regenerate todo
rubocop -a --auto-gen-config
```

**.rubocop.yml:**
```yaml
inherit_from: .rubocop_todo.yml
```

**.rubocop_todo.yml (generated):**
```yaml
# This file contains all cops that had violations
# Offenses are commented out to make fixing incremental

Style/StringLiterals:
  Exclude:
    - 'app/models/user.rb'
    - 'app/controllers/application_controller.rb'

Metrics/MethodLength:
  Max: 25  # Temporarily increased from 15
```

## Editor-Specific Settings

### VS Code

```json
{
  "ruby.rubocop.executePath": "bundle exec",
  "ruby.rubocop.configFilePath": ".rubocop.yml",
  "ruby.rubocop.onSave": true
}
```

### RubyMine

Settings → Tools → RuboCop:
- ✓ Enable RuboCop
- Configuration file: `.rubocop.yml`
- ✓ Run RuboCop on save
- ✓ Autocorrect on save

## Advanced Patterns

### Per-Directory Configuration

```
project/
├── .rubocop.yml          # Root config
├── app/
│   └── .rubocop.yml      # App-specific config
└── spec/
    └── .rubocop.yml      # Test-specific config
```

**Root config:**
```yaml
AllCops:
  TargetRubyVersion: 3.2
```

**spec/.rubocop.yml:**
```yaml
inherit_from: ../.rubocop.yml

# Relax rules for tests
Metrics/BlockLength:
  Enabled: false
```

### Conditional Configuration

```yaml
# Apply different rules based on file path
Style/StringLiterals:
  EnforcedStyle: double_quotes
  Include:
    - 'app/**/*'
  
# Different rule for tests
Style/StringLiterals:
  EnforcedStyle: single_quotes
  Include:
    - 'spec/**/*'
```

### Custom Cop Metadata

```yaml
CustomDepartment/CustomCop:
  Description: 'Custom description for internal cop'
  Enabled: true
  VersionAdded: '1.0'
  VersionChanged: '2.0'
  Safe: true
  SafeAutoCorrect: true
```

## Configuration Validation

```bash
# Validate configuration syntax
rubocop --show-cops

# Show specific cop configuration
rubocop --show-cops Style/StringLiterals

# List all cops
rubocop --show-cops | grep "^[A-Z]"

# Display documentation URLs
rubocop --show-docs-url
rubocop --show-docs-url Style/StringLiterals
```

## Common Configuration Recipes

### Strict Configuration

```yaml
AllCops:
  NewCops: enable
  TargetRubyVersion: 3.2

Style/StringLiterals:
  EnforcedStyle: single_quotes

Style/Documentation:
  Enabled: true  # Require documentation

Metrics/MethodLength:
  Max: 10  # Keep methods short

Metrics/ClassLength:
  Max: 100

Lint:
  Enabled: true  # All lint cops enabled
```

### Relaxed Configuration

```yaml
AllCops:
  NewCops: disable

Style/Documentation:
  Enabled: false

Style/StringLiterals:
  Enabled: false

Metrics/MethodLength:
  Enabled: false

Metrics/ClassLength:
  Enabled: false

Metrics/AbcSize:
  Enabled: false
```

### Rails-Optimized Configuration

```yaml
plugins:
  - rubocop-rails
  - rubocop-rspec

AllCops:
  TargetRubyVersion: 3.2
  TargetRailsVersion: 7.0
  NewCops: enable
  Exclude:
    - 'db/schema.rb'
    - 'db/migrate/*'
    - 'bin/**/*'
    - 'vendor/**/*'

Rails:
  Enabled: true

Metrics/BlockLength:
  Exclude:
    - 'spec/**/*'
    - 'config/routes.rb'
    - 'config/environments/*'

Style/Documentation:
  Enabled: false

Metrics/MethodLength:
  Max: 15
  Exclude:
    - 'db/migrate/*'
```

## Troubleshooting Configuration

**Problem: Cops not running**
```bash
# Check cop status
rubocop --show-cops CopName

# Verify it's enabled
Enabled: true (overridden in .rubocop.yml)
```

**Problem: Configuration not found**
```bash
# Show effective configuration
rubocop --show-cops

# Show configuration file being used
rubocop --debug
```

**Problem: Conflicting configurations**
- Check inheritance chain with `--debug`
- Ensure parent configs exist and are valid
- Remember: child settings override parents

**Problem: Performance issues**
```yaml
AllCops:
  UseCache: true
  MaxFilesInCache: 10000
  Exclude:
    - 'large_generated_file.rb'
```
