# Diagnostic Scripts

Drop-in snippets to add to `spec/spec_helper.rb` when profilers aren't telling you enough. These are lightweight — no new gems required.

## GC time tracker

Prints GC time accumulated every 1000 examples and a total at suite end. Useful for watching whether GC pressure is constant or growing.

```ruby
RSpec.configure do |config|
  gc_tracker = 0
  last_gc_time = 0

  config.after(:each) do |_ex|
    gc_tracker += 1
    if (gc_tracker % 1000).zero?
      time = GC.total_time - last_gc_time
      last_gc_time = GC.total_time
      puts "[GC] Time after #{gc_tracker} examples: #{time / 1_000_000}ms"
    end
  end

  config.after(:suite) do
    puts "[GC] Total: #{GC.total_time / 1_000_000}ms"
  end
end
```

Interpretation:

- Steady numbers per 1000 examples → healthy
- Growing numbers over time → memory accumulating somewhere (suspect #1: `rubocop/rspec/support`)
- Huge first chunk, small rest → boot-time allocation, not a per-spec problem

## Per-file runtime summary

Logs total wall time per spec file. A poor person's TPS_PROF, useful when you can't install TestProf yet:

```ruby
RSpec.configure do |config|
  file_times = Hash.new(0.0)
  file_counts = Hash.new(0)

  config.around(:each) do |example|
    file = example.metadata[:file_path]
    started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    example.run
    file_times[file]  += Process.clock_gettime(Process::CLOCK_MONOTONIC) - started
    file_counts[file] += 1
  end

  config.after(:suite) do
    sorted = file_times.sort_by { |_, t| -t }.first(20)
    puts "\n[PER-FILE] Top 20 slowest files (time, count, TPS):"
    sorted.each do |file, total|
      count = file_counts[file]
      tps = count / total
      puts format("  %8.2fs  %5d ex  %6.2f TPS  %s", total, count, tps, file)
    end
  end
end
```

## Factory call counter

Shows how many times each factory runs. Zero-dependency version of FactoryProf:

```ruby
RSpec.configure do |config|
  counts = Hash.new(0)

  ActiveSupport::Notifications.subscribe("factory_bot.run_factory") do |_, _, _, _, payload|
    counts[payload[:name]] += 1
  end

  config.after(:suite) do
    puts "\n[FACTORIES] Top 10 most-called factories:"
    counts.sort_by { |_, c| -c }.first(10).each do |name, count|
      puts format("  %6d  %s", count, name)
    end
  end
end
```

If one factory runs tens of thousands of times, investigate whether `let_it_be` or `create_default` would help.

## Boot time isolator

Sometimes "the suite is slow" really means "requiring the app is slow." Isolate that:

```bash
time ruby -e "require './config/environment'"
```

Or, from inside spec_helper:

```ruby
boot_started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
require File.expand_path("../config/environment", __dir__)
puts "[BOOT] #{Process.clock_gettime(Process::CLOCK_MONOTONIC) - boot_started}s"
```

If boot alone is 10+ seconds, investigate initializers and eager loading before blaming the specs.
