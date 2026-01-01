# RubyCritic Configuration Reference

This guide covers advanced RubyCritic configuration options for customizing analysis behavior, output formats, and quality thresholds.

## Configuration File

Create `.rubycritic.yml` in your project root:

```yaml
# .rubycritic.yml

# Minimum acceptable score (0-100)
minimum_score: 95

# Output formats (can specify multiple)
formats:
  - console    # Terminal output
  - html       # HTML report in tmp/rubycritic
  - json       # JSON output for CI/tooling

# Paths to analyze
paths:
  - 'app/'
  - 'lib/'
  - 'spec/'

# Paths to exclude
exclude_paths:
  - 'db/migrate/**/*'
  - 'config/**/*'
  - 'vendor/**/*'

# Don't auto-open browser for HTML reports
no_browser: true

# Suppress output (useful for CI)
suppress_ratings: false

# CI mode options
mode: default  # or 'ci' for CI mode

# Branch to compare against (CI mode)
branch: main

# Deduplicate similar smells
deduplicate_symlinks: true
```

## Common Configuration Patterns

### Strict Quality Standards

For new projects or teams prioritizing code quality:

```yaml
minimum_score: 95
formats:
  - console
  - html
paths:
  - 'app/'
  - 'lib/'
no_browser: true
suppress_ratings: false
```

### CI/CD Integration

For continuous integration environments:

```yaml
minimum_score: 90
formats:
  - json
  - console
mode: ci
branch: main
no_browser: true
suppress_ratings: true
exclude_paths:
  - 'db/migrate/**/*'
  - 'spec/**/*'
```

### Legacy Codebase

For existing projects with technical debt:

```yaml
minimum_score: 70  # Lower threshold
formats:
  - html
  - console
paths:
  - 'app/models'
  - 'app/services'
exclude_paths:
  - 'app/controllers/**/*'  # Exclude problematic areas temporarily
  - 'lib/legacy/**/*'
no_browser: false  # Open reports for review
```

### Development Mode

For active development with fast feedback:

```yaml
minimum_score: 85
formats:
  - console
no_browser: true
suppress_ratings: false
deduplicate_symlinks: true
```

## Command-Line Options

Override configuration file with CLI options:

```bash
# Set minimum score
rubycritic --minimum-score 90 app/

# Specify format
rubycritic --format html app/

# CI mode
rubycritic --mode-ci --branch main app/

# Suppress browser opening
rubycritic --no-browser app/

# Multiple formats
rubycritic --format console --format json app/

# Custom paths
rubycritic app/models app/services

# Help
rubycritic --help
```

## Output Formats

### Console Format

Terminal-friendly output with immediate feedback:

```bash
rubycritic --format console app/
```

Output includes:
- Overall score
- File-by-file ratings
- List of code smells
- Complexity metrics

### HTML Format

Detailed browser-based report:

```bash
rubycritic --format html app/
```

Features:
- Interactive file browser
- Visual complexity graphs
- Clickable code smells
- Historical trends (if run multiple times)
- Saved to `tmp/rubycritic/index.html`

### JSON Format

Machine-readable output for tooling integration:

```bash
rubycritic --format json app/ > quality_report.json
```

Use cases:
- CI/CD pipeline parsing
- Custom reporting tools
- Quality metrics tracking
- Integration with dashboards

## CI Mode

Compare changes against a base branch:

```bash
rubycritic --mode-ci --branch main app/
```

**Benefits**:
- Only analyzes changed files
- Shows quality delta
- Faster on large codebases
- Focuses on new issues

**Configuration**:
```yaml
mode: ci
branch: main
minimum_score: 90
```

## Score Calculation

RubyCritic calculates scores based on:

1. **Reek** - Code smell detection (40% weight)
2. **Flog** - Complexity analysis (30% weight)
3. **Flay** - Duplication detection (30% weight)

### Score Ranges

- **90-100**: Excellent - exemplary code quality
- **80-89**: Good - minor improvements recommended
- **70-79**: Fair - some technical debt present
- **60-69**: Poor - significant refactoring needed
- **0-59**: Critical - major quality issues

### Custom Thresholds

Set thresholds based on project maturity:

**New projects**: 95+
**Active development**: 90+
**Established projects**: 85+
**Legacy codebases**: 70+ (with improvement plan)

## Excluding Paths

### Temporary Exclusions

Exclude paths during active development:

```yaml
exclude_paths:
  - 'app/controllers/legacy_controller.rb'
  - 'lib/deprecated/**/*'
```

### Permanent Exclusions

Exclude paths that shouldn't be analyzed:

```yaml
exclude_paths:
  - 'db/migrate/**/*'        # Migrations
  - 'db/schema.rb'           # Auto-generated
  - 'config/**/*'            # Configuration
  - 'vendor/**/*'            # Third-party code
  - 'bin/**/*'               # Scripts
  - 'spec/fixtures/**/*'     # Test fixtures
  - 'spec/support/shared/**/*'  # Test helpers
```

## Integration with Other Tools

### RuboCop Integration

RubyCritic complements RuboCop:

- **RuboCop**: Style and syntax enforcement
- **RubyCritic**: Complexity and design analysis

Run both:
```bash
rubocop app/ && rubycritic app/
```

### SimpleCov Integration

Combine with test coverage:

```bash
# Run tests with coverage
bundle exec rspec

# Then analyze code quality
rubycritic app/
```

### CI Pipeline Integration

```yaml
# .github/workflows/quality.yml
name: Code Quality

on: [push, pull_request]

jobs:
  quality:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - uses: ruby/setup-ruby@v1
        with:
          ruby-version: 3.2
          bundler-cache: true

      - name: Run RubyCritic
        run: |
          gem install rubycritic
          rubycritic --format json --minimum-score 90 app/ lib/

      - name: Upload Report
        uses: actions/upload-artifact@v2
        with:
          name: rubycritic-report
          path: tmp/rubycritic/
```

## Performance Optimization

For large codebases:

### Analyze Specific Directories

```bash
# Only analyze changed areas
rubycritic app/models app/services
```

### Use CI Mode

```bash
# Only analyze changed files
rubycritic --mode-ci --branch main
```

### Exclude Non-Critical Paths

```yaml
paths:
  - 'app/models'
  - 'app/services'
  - 'lib/core'
# Exclude specs, migrations, config
```

### Disable Browser Opening

```yaml
no_browser: true
```

## Troubleshooting Configuration

### Configuration Not Loading

Verify file location and syntax:
```bash
# Check if file exists
ls -la .rubycritic.yml

# Validate YAML syntax
ruby -e "require 'yaml'; YAML.load_file('.rubycritic.yml')"
```

### Scores Too Low

Adjust thresholds based on codebase maturity:
```yaml
minimum_score: 80  # More lenient
```

### Too Many Exclusions

Review exclusions periodically:
```bash
# List excluded paths
grep -A 10 "exclude_paths:" .rubycritic.yml
```

### Performance Issues

Reduce analysis scope:
```yaml
paths:
  - 'app/models'  # Start small
  - 'app/services'
```

## Best Practices

1. **Version control**: Commit `.rubycritic.yml` to repository
2. **Team alignment**: Agree on minimum score thresholds
3. **Gradual improvement**: Start with lower threshold, increase over time
4. **Focused analysis**: Analyze specific paths for faster feedback
5. **CI integration**: Run on every PR to prevent regressions
6. **Historical tracking**: Keep HTML reports for trend analysis
7. **Regular review**: Adjust configuration as project evolves
