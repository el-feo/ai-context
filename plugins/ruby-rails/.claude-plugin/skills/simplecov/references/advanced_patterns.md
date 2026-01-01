# Advanced SimpleCov Patterns

This document covers advanced configuration patterns, edge cases, and sophisticated usage of SimpleCov for enterprise Ruby/Rails applications.

## Multi-Application Coverage (Engines/Gems)

### Rails Engine Coverage

When developing a Rails engine, you want coverage for engine code even though it's loaded as a gem:

```ruby
# spec/spec_helper.rb in your engine
SimpleCov.start 'rails' do
  # Clear default filters
  filters.clear
  
  # Re-add only root filter
  add_filter :root_filter
  
  # Include engine code specifically
  add_filter do |src|
    unless src.filename =~ /my_engine/
      !(src.filename =~ /^#{SimpleCov.root}/)
    end
  end
end
```

### Gem Coverage in Host Application

Include coverage for gems you maintain:

```ruby
SimpleCov.start 'rails' do
  # Clear default filters to allow gem code
  filters.clear
  add_filter :root_filter
  add_filter :bundler_filter
  
  # Explicitly include your gem
  add_filter do |src|
    !(src.filename =~ /^#{SimpleCov.root}/) unless src.filename =~ /my_custom_gem/
  end
  
  add_group "My Gem", "my_custom_gem"
end
```

## Dynamic Configuration Based on Environment

### Environment-Specific Thresholds

```ruby
# .simplecov
SimpleCov.start 'rails' do
  case ENV['RAILS_ENV']
  when 'test'
    # Strict thresholds for main test suite
    minimum_coverage line: 90, branch: 80
    refuse_coverage_drop :line, :branch
    
  when 'ci_staging'
    # Slightly relaxed for staging CI
    minimum_coverage line: 85, branch: 75
    
  when 'development'
    # Informational only
    minimum_coverage 0
    formatter SimpleCov::Formatter::HTMLFormatter
  end
  
  # CI gets console formatter
  if ENV['CI']
    formatter SimpleCov::Formatter::Console
    SimpleCov::Formatter::Console.output_style = 'block'
  end
end
```

### Feature Flag Coverage

Track coverage only for active feature flags:

```ruby
SimpleCov.start 'rails' do
  # Exclude code behind disabled features
  add_filter do |source_file|
    disabled_features = ENV['DISABLED_FEATURES']&.split(',') || []
    
    disabled_features.any? do |feature|
      source_file.filename.include?("features/#{feature}")
    end
  end
end
```

## Advanced Filtering Strategies

### Complexity-Based Filtering

Exclude low-value simple files:

```ruby
SimpleCov.start 'rails' do
  # Exclude trivial files
  add_filter do |source_file|
    # Skip files with only simple assignments/delegations
    lines = source_file.src.split("\n")
    substantive_lines = lines.reject { |l| l.strip.empty? || l.strip.start_with?('#', 'end') }
    substantive_lines.count < 5
  end
end
```

### Namespace Filtering

Focus coverage on specific modules:

```ruby
SimpleCov.start do
  add_filter do |source_file|
    # Only include files in MyApp:: namespace
    code = source_file.src
    !(code =~ /module MyApp|class MyApp::/)
  end
  
  add_group "Core", %r{lib/my_app/core}
  add_group "Extensions", %r{lib/my_app/ext}
end
```

### Maintenance Status Filtering

Track coverage differently for maintained vs legacy code:

```ruby
SimpleCov.start 'rails' do
  # Legacy code - track but don't enforce
  add_group "Legacy (Monitor Only)" do |src|
    legacy_paths = ['app/legacy', 'lib/deprecated']
    legacy_paths.any? { |path| src.filename.include?(path) }
  end
  
  # Active code - strict enforcement
  add_group "Active Development" do |src|
    active_paths = ['app/services', 'app/models']
    active_paths.any? { |path| src.filename.include?(path) }
  end
  
  # Only enforce thresholds on active code
  track_files "app/services/**/*.rb"
  track_files "app/models/**/*.rb"
end
```

## Custom Formatters

### Slack Notification Formatter

```ruby
# lib/simplecov_slack_formatter.rb
require 'net/http'
require 'json'

class SimpleCovSlackFormatter
  def format(result)
    coverage_pct = result.covered_percent.round(2)
    
    color = case coverage_pct
           when 90..100 then 'good'
           when 70..89 then 'warning'
           else 'danger'
           end
    
    message = {
      text: "Test Coverage Report",
      attachments: [{
        color: color,
        fields: [
          {
            title: "Coverage",
            value: "#{coverage_pct}%",
            short: true
          },
          {
            title: "Lines",
            value: "#{result.covered_lines}/#{result.total_lines}",
            short: true
          }
        ]
      }]
    }
    
    uri = URI(ENV['SLACK_WEBHOOK_URL'])
    Net::HTTP.post(uri, message.to_json, "Content-Type" => "application/json")
    
    puts "Posted coverage to Slack: #{coverage_pct}%"
  end
end

# .simplecov
require './lib/simplecov_slack_formatter'

SimpleCov.start 'rails' do
  if ENV['CI'] && ENV['SLACK_WEBHOOK_URL']
    formatter SimpleCov::Formatter::MultiFormatter.new([
      SimpleCov::Formatter::Console,
      SimpleCovSlackFormatter.new
    ])
  end
end
```

### CSV Export Formatter

```ruby
# lib/simplecov_csv_formatter.rb
require 'csv'

class SimpleCovCSVFormatter
  def format(result)
    CSV.open("coverage/coverage_report.csv", "w") do |csv|
      csv << ["File", "Coverage %", "Lines", "Covered", "Missed", "Missed Lines"]
      
      result.files.sort_by(&:covered_percent).each do |file|
        csv << [
          file.filename.gsub(SimpleCov.root, ''),
          file.covered_percent.round(2),
          file.lines_of_code,
          file.covered_lines.count,
          file.missed_lines.count,
          file.missed_lines.map(&:line_number).join(';')
        ]
      end
    end
    
    puts "Coverage report exported to coverage/coverage_report.csv"
  end
end
```

### Historical Tracking Formatter

```ruby
# lib/simplecov_history_formatter.rb
require 'json'
require 'time'

class SimpleCovHistoryFormatter
  HISTORY_FILE = 'coverage/history.json'
  
  def format(result)
    history = load_history
    
    entry = {
      timestamp: Time.now.iso8601,
      coverage_percent: result.covered_percent,
      covered_lines: result.covered_lines,
      total_lines: result.total_lines,
      git_sha: `git rev-parse HEAD`.strip,
      git_branch: `git rev-parse --abbrev-ref HEAD`.strip
    }
    
    history << entry
    save_history(history)
    
    analyze_trend(history)
  end
  
  private
  
  def load_history
    return [] unless File.exist?(HISTORY_FILE)
    JSON.parse(File.read(HISTORY_FILE), symbolize_names: true)
  end
  
  def save_history(history)
    # Keep last 100 entries
    history = history.last(100)
    File.write(HISTORY_FILE, JSON.pretty_generate(history))
  end
  
  def analyze_trend(history)
    return if history.size < 2
    
    recent = history.last(10)
    avg_recent = recent.sum { |e| e[:coverage_percent] } / recent.size
    
    if avg_recent > history[-11][:coverage_percent]
      puts "📈 Coverage trending up! Average last 10 runs: #{avg_recent.round(2)}%"
    elsif avg_recent < history[-11][:coverage_percent]
      puts "📉 Coverage trending down. Average last 10 runs: #{avg_recent.round(2)}%"
    end
  end
end
```

## Collating Coverage Across Machines

For distributed CI systems running tests in parallel:

### Setup

```ruby
# .simplecov
SimpleCov.start 'rails' do
  # Unique command name per machine
  command_name "CI Node #{ENV['CI_NODE_INDEX']}/#{ENV['CI_NODE_TOTAL']}"
  
  if ENV['CI']
    # Don't format immediately
    formatter SimpleCov::Formatter::SimpleFormatter
  end
end
```

### Collection Script

```ruby
# scripts/collate_coverage.rb
require 'simplecov'

# Download .resultset.json from each CI node
# e.g., from S3, artifact storage, etc.
result_files = Dir['coverage-results/*/.resultset.json']

SimpleCov.collate result_files, 'rails' do
  formatter SimpleCov::Formatter::MultiFormatter.new([
    SimpleCov::Formatter::Console,
    SimpleCov::Formatter::HTMLFormatter
  ])
  
  minimum_coverage line: 90, branch: 80
end
```

### GitHub Actions Example

```yaml
# .github/workflows/test.yml
jobs:
  test:
    strategy:
      matrix:
        ci_node_index: [0, 1, 2, 3]
        ci_node_total: [4]
    
    steps:
      - name: Run tests
        env:
          CI_NODE_INDEX: ${{ matrix.ci_node_index }}
          CI_NODE_TOTAL: ${{ matrix.ci_node_total }}
        run: bundle exec rake test
      
      - name: Upload coverage
        uses: actions/upload-artifact@v3
        with:
          name: coverage-${{ matrix.ci_node_index }}
          path: coverage/.resultset.json
  
  collate:
    needs: test
    runs-on: ubuntu-latest
    steps:
      - uses: actions/download-artifact@v3
        with:
          path: coverage-results
      
      - name: Collate coverage
        run: bundle exec ruby scripts/collate_coverage.rb
      
      - name: Upload final report
        uses: actions/upload-artifact@v3
        with:
          name: coverage-final
          path: coverage/
```

## Continuous Coverage Monitoring

### Pre-push Hook with Baseline

```bash
#!/bin/bash
# .git/hooks/pre-push

# Get baseline coverage from main branch
git fetch origin main:main 2>/dev/null
git show main:.last_coverage 2>/dev/null > /tmp/baseline_coverage || echo "0" > /tmp/baseline_coverage
baseline=$(cat /tmp/baseline_coverage)

# Run tests and get current coverage
COVERAGE=true bundle exec rake test
current=$(ruby -r json -e "data = JSON.parse(File.read('coverage/.resultset.json')); cov = data.values.first['coverage']['lines']; puts ((cov.compact.count { |x| x > 0 }.to_f / cov.size) * 100).round(2)")

# Compare
if (( $(echo "$current < $baseline" | bc -l) )); then
  echo "❌ Coverage dropped from ${baseline}% to ${current}%"
  echo "Please add tests before pushing."
  exit 1
fi

echo "✅ Coverage: ${current}% (baseline: ${baseline}%)"

# Update baseline
echo "$current" > .last_coverage
git add .last_coverage
```

### Coverage Dashboard

```ruby
# scripts/coverage_dashboard.rb
require 'json'
require 'time'

class CoverageDashboard
  def initialize
    @history = load_history
    @current = load_current
  end
  
  def report
    puts "\n" + "="*60
    puts "COVERAGE DASHBOARD"
    puts "="*60
    
    current_summary
    trend_analysis
    worst_files
    improvement_suggestions
  end
  
  private
  
  def current_summary
    puts "\n📊 Current Status:"
    puts "  Line Coverage: #{@current[:line_percent]}%"
    puts "  Branch Coverage: #{@current[:branch_percent]}%"
    puts "  Files: #{@current[:total_files]}"
    puts "  Lines: #{@current[:covered_lines]}/#{@current[:total_lines]}"
  end
  
  def trend_analysis
    return if @history.size < 2
    
    puts "\n📈 Trend (Last 30 Days):"
    recent = @history.select { |e| Time.parse(e[:timestamp]) > Time.now - 30*24*60*60 }
    
    if recent.any?
      avg = recent.sum { |e| e[:coverage_percent] } / recent.size
      change = @current[:line_percent] - avg
      
      emoji = change > 0 ? "📈" : change < 0 ? "📉" : "➡️"
      puts "  #{emoji} #{change > 0 ? '+' : ''}#{change.round(2)}% vs 30-day average"
    end
  end
  
  def worst_files
    puts "\n⚠️  Files Needing Attention:"
    
    @current[:files]
      .sort_by { |f| f[:coverage] }
      .first(5)
      .each_with_index do |file, i|
        puts "  #{i+1}. #{file[:path]} (#{file[:coverage]}%)"
      end
  end
  
  def improvement_suggestions
    puts "\n💡 Suggestions:"
    
    low_coverage_files = @current[:files].select { |f| f[:coverage] < 80 }
    
    if low_coverage_files.any?
      puts "  • #{low_coverage_files.size} files below 80% coverage"
      puts "  • Focus on: #{low_coverage_files.first[:path]}"
    end
    
    if @current[:branch_percent] < @current[:line_percent] - 10
      puts "  • Branch coverage lagging (#{@current[:branch_percent]}% vs #{@current[:line_percent]}%)"
      puts "  • Add tests for conditional paths"
    end
  end
  
  def load_history
    # Load from coverage/history.json
    []
  end
  
  def load_current
    # Parse coverage/.resultset.json
    {}
  end
end

CoverageDashboard.new.report if __FILE__ == $0
```

## Testing SimpleCov Configuration

Verify SimpleCov is working correctly:

```ruby
# test/coverage_test.rb
require 'test_helper'

class CoverageTest < ActiveSupport::TestCase
  test "SimpleCov is running" do
    assert SimpleCov.running, "SimpleCov should be running during tests"
  end
  
  test "SimpleCov tracks files in app/" do
    tracked_files = SimpleCov.result.files.map(&:filename)
    assert tracked_files.any? { |f| f.include?('app/models') }, 
           "SimpleCov should track models"
  end
  
  test "SimpleCov excludes test files" do
    tracked_files = SimpleCov.result.files.map(&:filename)
    refute tracked_files.any? { |f| f.include?('test/') },
           "SimpleCov should not track test files"
  end
  
  test "branch coverage is enabled" do
    skip unless RUBY_VERSION >= '2.5'
    assert SimpleCov.branch_coverage?, "Branch coverage should be enabled"
  end
end
```

## Debugging Coverage Issues

### Verbose Output

```ruby
SimpleCov.start 'rails' do
  # Enable debug output
  at_exit do
    puts "\nSimpleCov Results:"
    puts "  Tracked files: #{SimpleCov.result.files.count}"
    puts "  Coverage: #{SimpleCov.result.covered_percent.round(2)}%"
    SimpleCov.result.format!
  end
end
```

### File Tracking Diagnostic

```ruby
# scripts/diagnose_coverage.rb
require 'simplecov'

puts "SimpleCov Configuration:"
puts "  Root: #{SimpleCov.root}"
puts "  Filters: #{SimpleCov.filters.map(&:class)}"
puts "  Groups: #{SimpleCov.groups.keys}"

# Check if a specific file would be tracked
test_file = Rails.root.join('app/models/user.rb')
dummy_source = SimpleCov::SourceFile.new(test_file, {})

puts "\nWould track #{test_file}?"
puts "  Filtered out: #{SimpleCov.filtered?(dummy_source)}"
```
