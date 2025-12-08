# RubyCritic Error Handling and Troubleshooting

This guide covers common errors, edge cases, and troubleshooting strategies when using RubyCritic.

## Installation Errors

### "RubyCritic not found"

**Symptom**: Command `rubycritic` not recognized

**Causes**:
- RubyCritic not installed
- Not in PATH (when using Bundler)
- Wrong Ruby version active

**Solutions**:

```bash
# Check if installed
which rubycritic

# Install system-wide
gem install rubycritic

# Or add to Gemfile
# Gemfile
group :development do
  gem 'rubycritic', require: false
end

# Then install
bundle install

# Use with Bundler
bundle exec rubycritic app/
```

### "Gem::InstallError: You don't have write permissions"

**Symptom**: Permission denied when installing gem

**Solutions**:

```bash
# Option 1: Use bundler (recommended)
bundle install

# Option 2: Install to user directory
gem install --user-install rubycritic

# Option 3: Use rbenv/rvm (recommended for development)
rbenv install 3.2.0
rbenv global 3.2.0
gem install rubycritic
```

### "Bundler::GemNotFound: Could not find gem 'rubycritic'"

**Symptom**: Gem not in Gemfile.lock

**Solutions**:

```bash
# Add to Gemfile
echo "gem 'rubycritic', require: false, group: :development" >> Gemfile

# Update bundle
bundle install

# Verify installation
bundle exec rubycritic --version
```

### "LoadError: cannot load such file"

**Symptom**: Missing dependencies for RubyCritic

**Solutions**:

```bash
# Update bundler
bundle update

# Re-install RubyCritic
gem uninstall rubycritic
gem install rubycritic

# Check Ruby version compatibility
ruby --version  # Should be 2.7+
```

## Analysis Errors

### "No files to critique"

**Symptom**: RubyCritic finds no Ruby files to analyze

**Causes**:
- Wrong path specified
- No `.rb` files in path
- Path excluded in configuration

**Solutions**:

```bash
# Verify path contains Ruby files
ls -la app/*.rb

# Check explicit file extension
rubycritic app/**/*.rb

# Verify configuration exclusions
cat .rubycritic.yml | grep -A 5 exclude_paths

# Use absolute paths
rubycritic $(pwd)/app/
```

### "Analysis timed out"

**Symptom**: RubyCritic hangs or takes extremely long

**Causes**:
- Very large codebase
- Infinite loops in analyzed code
- Resource constraints

**Solutions**:

```bash
# Analyze smaller directories
rubycritic app/models/

# Use CI mode for faster analysis
rubycritic --mode-ci --branch main app/

# Increase timeout (if available in your version)
# Or split into multiple runs
rubycritic app/models/
rubycritic app/services/
rubycritic app/controllers/

# Check for problematic files
# Analyze one directory at a time to identify issues
```

### "Invalid multibyte char (UTF-8)"

**Symptom**: Encoding errors when analyzing files

**Causes**:
- Files with invalid UTF-8 encoding
- Mixed encodings in codebase

**Solutions**:

```bash
# Find files with encoding issues
find . -name "*.rb" -exec file {} \; | grep -v "UTF-8"

# Fix encoding in problematic files
# Add magic comment at top of file:
# frozen_string_literal: true
# encoding: UTF-8

# Or convert file encoding
iconv -f ISO-8859-1 -t UTF-8 problematic_file.rb -o fixed_file.rb
```

### "SyntaxError: unexpected token"

**Symptom**: RubyCritic fails on valid Ruby syntax

**Causes**:
- Unsupported Ruby version features
- RubyCritic version too old
- Actually invalid syntax in code

**Solutions**:

```bash
# Check RubyCritic version
rubycritic --version

# Update RubyCritic
gem update rubycritic

# Verify syntax is actually valid
ruby -c app/models/user.rb

# Check Ruby version compatibility
ruby --version
```

## Configuration Errors

### "Invalid YAML in .rubycritic.yml"

**Symptom**: Configuration file not parsed correctly

**Solutions**:

```bash
# Validate YAML syntax
ruby -e "require 'yaml'; YAML.load_file('.rubycritic.yml')"

# Common YAML issues:
# - Wrong indentation (use spaces, not tabs)
# - Missing quotes around special characters
# - Incorrect list syntax

# Example of common error:
# ❌ Wrong
paths:
- app/   # Missing space after hyphen

# ✅ Correct
paths:
  - 'app/'
```

### "Unrecognized option"

**Symptom**: Command-line option not recognized

**Causes**:
- Typo in option name
- Option not available in RubyCritic version
- Incorrect option format

**Solutions**:

```bash
# Check available options
rubycritic --help

# Verify correct format
rubycritic --minimum-score 90  # Correct
rubycritic --minimum_score 90  # Wrong (underscore)

# Check version supports option
rubycritic --version
```

### "Configuration file not found"

**Symptom**: RubyCritic doesn't load `.rubycritic.yml`

**Solutions**:

```bash
# Verify file exists in project root
ls -la .rubycritic.yml

# Check file permissions
chmod 644 .rubycritic.yml

# Use absolute path in config
pwd  # Get current directory
# Ensure running RubyCritic from project root

# Debug: Run with explicit paths
rubycritic --format console app/
```

## Output Errors

### "Permission denied writing to tmp/"

**Symptom**: Cannot write HTML report

**Solutions**:

```bash
# Check tmp directory permissions
ls -la tmp/

# Create directory if missing
mkdir -p tmp/rubycritic

# Fix permissions
chmod 755 tmp/

# Or use different output directory
rubycritic --path ./reports app/
```

### "Browser failed to open"

**Symptom**: HTML report generated but browser doesn't open

**Solutions**:

```bash
# Use --no-browser flag
rubycritic --no-browser app/

# Manually open report
open tmp/rubycritic/index.html  # macOS
xdg-open tmp/rubycritic/index.html  # Linux

# Add to configuration
# .rubycritic.yml
no_browser: true
```

### "JSON output malformed"

**Symptom**: JSON format produces invalid JSON

**Solutions**:

```bash
# Validate JSON output
rubycritic --format json app/ | jq .

# If jq not installed
rubycritic --format json app/ > output.json
ruby -e "require 'json'; JSON.parse(File.read('output.json'))"

# Use console format for debugging
rubycritic --format console app/
```

## Score Calculation Issues

### "Score unexpectedly low"

**Symptom**: Quality score lower than expected

**Investigation**:

```bash
# Get detailed breakdown
rubycritic --format html app/
# Open HTML report to see which files/metrics are low

# Check individual analyzers
# Look for:
# - High Flog scores (complexity)
# - Many Reek smells
# - Flay duplications

# Focus on worst files first
rubycritic --format console app/ | grep "F:"
```

**Common causes**:
- Long methods (>10 lines)
- High cyclomatic complexity
- Many parameters (>3)
- Duplicate code
- Feature envy (using other classes' methods)

### "Score changes between runs"

**Symptom**: Inconsistent scores for same code

**Causes**:
- Different file sets analyzed
- Configuration changes
- RubyCritic version differences

**Solutions**:

```bash
# Use consistent paths
rubycritic app/ lib/  # Always specify same paths

# Lock configuration
# Commit .rubycritic.yml to version control

# Use same version
# Add to Gemfile with version constraint
gem 'rubycritic', '~> 4.7', require: false
```

### "Cannot determine score from output"

**Symptom**: Parsing tools can't extract score

**Solutions**:

```bash
# Use JSON format for machine parsing
rubycritic --format json app/ > quality.json

# Parse JSON for score
ruby -e "
  require 'json'
  data = JSON.parse(File.read('quality.json'))
  puts data['score']
"

# Or use grep with console format
rubycritic --format console app/ | grep -oP 'Score: \K\d+'
```

## Integration Errors

### "Git hook not executing"

**Symptom**: Pre-commit/pre-push hook not running

**Solutions**:

```bash
# Check if hook exists
ls -la .git/hooks/pre-commit

# Verify executable permissions
chmod +x .git/hooks/pre-commit

# Test hook manually
.git/hooks/pre-commit

# Check shebang line
head -1 .git/hooks/pre-commit
# Should be: #!/bin/bash

# Verify git config allows hooks
git config --get core.hooksPath
```

### "CI build failing but local passes"

**Symptom**: Quality check passes locally but fails in CI

**Causes**:
- Different RubyCritic versions
- Different file sets analyzed
- Configuration not in version control

**Solutions**:

```bash
# Pin RubyCritic version in Gemfile
gem 'rubycritic', '~> 4.7.0', require: false

# Ensure configuration is committed
git add .rubycritic.yml
git commit -m "Add RubyCritic config"

# Use same command locally and in CI
bundle exec rubycritic app/ lib/

# Debug: Compare versions
rubycritic --version  # Local
# vs CI output

# Check for ignored files in .gitignore
# That might exist locally but not in CI
```

### "Bundler can't find rubycritic in CI"

**Symptom**: CI can't install or run RubyCritic

**Solutions**:

```yaml
# Ensure proper setup in CI
steps:
  - name: Install dependencies
    run: bundle install

  - name: Run RubyCritic
    run: bundle exec rubycritic app/

# Or install separately
steps:
  - name: Install RubyCritic
    run: gem install rubycritic

  - name: Run analysis
    run: rubycritic app/
```

## Performance Issues

### "Analysis takes too long"

**Symptom**: RubyCritic runs for minutes/hours

**Solutions**:

```bash
# Profile which directories are slow
time rubycritic app/models/
time rubycritic app/services/
time rubycritic app/controllers/

# Exclude large/generated files
# .rubycritic.yml
exclude_paths:
  - 'app/assets/**/*'
  - 'db/**/*'
  - 'spec/**/*'

# Use CI mode on branches
rubycritic --mode-ci --branch main app/

# Analyze only changed files in git hook
git diff --cached --name-only | grep '\.rb$' | xargs rubycritic
```

### "Running out of memory"

**Symptom**: RubyCritic crashes with memory errors

**Solutions**:

```bash
# Increase Ruby memory limit
RUBY_GC_HEAP_GROWTH_FACTOR=1.1 rubycritic app/

# Analyze in smaller batches
for dir in app/*/; do
  rubycritic "$dir"
done

# Reduce scope
# Only analyze app/ not spec/
rubycritic app/

# Use CI mode (more efficient)
rubycritic --mode-ci --branch main app/
```

## Debugging Strategies

### Enable Verbose Output

```bash
# Run with verbose mode (if available)
rubycritic --verbose app/

# Check RubyCritic logs
# Location varies by OS
cat tmp/rubycritic.log
```

### Isolate Problematic Files

```bash
# Binary search approach
# Split files in half, find which half has issues

# Test individual files
for file in app/models/*.rb; do
  echo "Analyzing $file"
  rubycritic "$file" || echo "Failed on $file"
done
```

### Check Dependencies

```bash
# Verify all RubyCritic dependencies
bundle exec gem dependency rubycritic

# Update dependencies
bundle update rubycritic

# Clean and reinstall
gem uninstall rubycritic
bundle install
```

### Compare with Fresh Environment

```bash
# Create new gemset/environment
# Test if issue persists

# Docker test
docker run -it ruby:3.2 bash
gem install rubycritic
# Test analysis
```

## Getting Help

### Gather Debug Information

When reporting issues:

```bash
# Collect version info
ruby --version
rubycritic --version
bundle --version

# Configuration
cat .rubycritic.yml

# Command used
echo "rubycritic app/"

# Error output
rubycritic app/ 2>&1 | tee error.log

# System info
uname -a
```

### Resources

- **GitHub Issues**: https://github.com/whitesmith/rubycritic/issues
- **Documentation**: https://github.com/whitesmith/rubycritic
- **Stack Overflow**: Tag `rubycritic`

## Prevention Best Practices

1. **Pin versions**: Lock RubyCritic version in Gemfile
2. **Test configuration**: Validate `.rubycritic.yml` syntax
3. **Incremental adoption**: Start with small directories
4. **Monitor performance**: Track analysis time
5. **Document exceptions**: Comment why files are excluded
6. **Version control config**: Commit configuration files
7. **CI validation**: Test hooks in CI environment
8. **Regular updates**: Keep RubyCritic updated
9. **Team training**: Document common issues
10. **Fallback plans**: Have manual quality review process

## Quick Reference

### Emergency Fixes

```bash
# Skip quality check temporarily
git commit --no-verify

# Force run with basic settings
rubycritic --format console --no-browser app/

# Minimal analysis
rubycritic app/models/user.rb

# Reset configuration
rm .rubycritic.yml
rubycritic app/
```

### Health Check

```bash
# Verify setup is working
rubycritic --version && echo "✓ Installed"
[ -f .rubycritic.yml ] && echo "✓ Configured"
ruby -c .git/hooks/pre-commit && echo "✓ Hook valid"
bundle exec rubycritic --help && echo "✓ Bundler OK"
```
