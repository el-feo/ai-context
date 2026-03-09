# RubyCritic Error Handling

## Installation Errors

### "RubyCritic not found"

```bash
# Check if installed
which rubycritic

# Install system-wide
gem install rubycritic

# Or add to Gemfile
# group :development do
#   gem 'rubycritic', require: false
# end
bundle install

# Use with Bundler
bundle exec rubycritic app/
```

### Permission errors

```bash
# Use bundler (recommended)
bundle install

# Or install to user directory
gem install --user-install rubycritic
```

### "LoadError: cannot load such file"

```bash
bundle update
gem uninstall rubycritic && gem install rubycritic
ruby --version  # Should be 2.7+
```

## Analysis Errors

### "No files to critique"

- Verify path contains `.rb` files
- Check `.rubycritic.yml` exclusions aren't filtering everything
- Use explicit path: `rubycritic app/models/`

### Analysis hangs or times out

- Analyze smaller directories instead of entire project
- Use CI mode: `rubycritic --mode-ci --branch main app/`
- Split into multiple runs per directory

### "Invalid multibyte char (UTF-8)"

Add to file top: `# encoding: UTF-8`

Or convert: `iconv -f ISO-8859-1 -t UTF-8 file.rb -o file.rb`

### "SyntaxError: unexpected token"

```bash
rubycritic --version    # Check version
gem update rubycritic   # Update
ruby -c app/models/user.rb  # Verify syntax is valid
```

## Configuration Errors

### "Invalid YAML in .rubycritic.yml"

```bash
ruby -e "require 'yaml'; YAML.load_file('.rubycritic.yml')"
```

Common issues: tabs instead of spaces, missing space after `-` in lists.

### Config not loading

Ensure `.rubycritic.yml` is in project root and run RubyCritic from project root.

## Score Issues

### Score unexpectedly low

Generate HTML report for detailed breakdown:

```bash
rubycritic --format html app/
open tmp/rubycritic/index.html
```

### Score changes between runs

- Use consistent paths each run
- Pin version: `gem 'rubycritic', '~> 4.7', require: false`
- Commit `.rubycritic.yml` to version control

## CI vs Local Differences

- Pin RubyCritic version in Gemfile
- Commit `.rubycritic.yml`
- Use `bundle exec rubycritic` in both environments
- Compare `rubycritic --version` output

## Performance

```bash
# Analyze only changed files
git diff --cached --name-only | grep '\.rb$' | xargs rubycritic

# Exclude large directories in .rubycritic.yml
# exclude_paths: ['db/**/*', 'spec/**/*', 'vendor/**/*']

# Use CI mode
rubycritic --mode-ci --branch main app/
```
