# SimpleCov Troubleshooting

## Table of Contents

- [Coverage Shows 0% or Missing Files](#coverage-shows-0-or-missing-files)
- [Spring Conflicts](#spring-conflicts)
- [Parallel Test Conflicts](#parallel-test-conflicts)
- [Branch Coverage Not Showing](#branch-coverage-not-showing)
- [Old Cached Results](#old-cached-results)

## Coverage Shows 0% or Missing Files

**Problem:** SimpleCov doesn't track files or shows 0%.

**Cause:** SimpleCov loaded after application code.

**Solution:** Ensure SimpleCov starts FIRST:

```ruby
# CORRECT
require 'simplecov'
SimpleCov.start 'rails'
require_relative '../config/environment'

# WRONG
require_relative '../config/environment'
require 'simplecov'
SimpleCov.start
```

## Spring Conflicts

**Problem:** Inaccurate coverage with Spring.

**Solutions:**

```ruby
# Option 1: Eager load
require 'simplecov'
SimpleCov.start 'rails'
Rails.application.eager_load!

# Option 2: Disable Spring for coverage
# DISABLE_SPRING=1 bundle exec rake test

# Option 3: Remove Spring
# Remove gem 'spring' from Gemfile
```

## Parallel Test Conflicts

**Problem:** Results overwrite each other.

**Solution:**

```ruby
SimpleCov.start 'rails' do
  command_name "Test #{ENV['TEST_ENV_NUMBER'] || Process.pid}"
end
```

## Branch Coverage Not Showing

**Problem:** Branch coverage is 0% or missing.

**Requirements:**

- Ruby 2.5 or later
- Must explicitly enable

**Solution:**

```ruby
SimpleCov.start do
  enable_coverage :branch
  primary_coverage :branch
end
```

## Old Cached Results

**Problem:** Coverage seems incorrect or stale.

**Solution:**

```bash
# Clear cache
rm -rf coverage/
bundle exec rake test

# Or increase merge timeout
SimpleCov.merge_timeout 7200  # 2 hours
```
