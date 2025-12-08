# RubyCritic Integration Guide

How to effectively combine SimpleCov test coverage with RubyCritic code quality metrics for comprehensive code health analysis.

## Overview

SimpleCov tracks **test coverage** (how much code is tested), while RubyCritic evaluates **code quality** (complexity, duplication, maintainability). Together, they provide a complete picture of code health.

## Installation

```ruby
# Gemfile
group :development, :test do
  gem 'simplecov', require: false
  gem 'simplecov-console', require: false
  gem 'rubycritic', require: false
end
```

```bash
bundle install
```

## Basic Workflow

```bash
# 1. Run tests with coverage
bundle exec rake test

# 2. Run RubyCritic on application code
bundle exec rubycritic app lib --format console

# 3. Review both reports
open coverage/index.html
open tmp/rubycritic/overview.html
```

## Prioritization Matrix

Combine metrics to prioritize improvement efforts:

| Complexity | Coverage | Priority | Action Required |
|------------|----------|----------|-----------------|
| High | Low | **CRITICAL** | Add comprehensive tests, then refactor |
| High | High | **High** | Safe to refactor with test safety net |
| Low | Low | **Medium** | Add tests for regression protection |
| Low | High | **Low** | Well-maintained code |

### Interpreting the Matrix

**High Complexity + Low Coverage (CRITICAL)**
- Dangerous: Complex code with poor test coverage
- Risk: Changes likely to introduce bugs
- Action Plan:
  1. Write characterization tests for existing behavior
  2. Achieve ~70% coverage to understand current behavior
  3. Refactor to reduce complexity
  4. Achieve 90%+ coverage on simplified code

**High Complexity + High Coverage (HIGH)**
- Safe to refactor: Tests provide safety net
- Action: Break down into smaller, simpler components
- Benefit: Tests catch regressions during refactoring

**Low Complexity + Low Coverage (MEDIUM)**
- Low risk but still a gap
- Action: Add tests for completeness
- Focus: Edge cases and error conditions

**Low Complexity + High Coverage (LOW)**
- Well-maintained code
- Action: Maintain current quality

## Example Analysis

```bash
# Run SimpleCov
bundle exec rake test

# Output:
# | 45.00% | app/services/order_processor.rb | 80 | 44 | many lines uncovered

# Run RubyCritic  
bundle exec rubycritic app/services/order_processor.rb

# Output:
# File: app/services/order_processor.rb
# Score: D
# Complexity: 28
# Duplication: 12
# Churn: 15
```

### Interpretation

- **Coverage: 45%** - Poor test coverage
- **Complexity: 28** - Very high, hard to understand
- **Duplication: 12** - Repeated code patterns
- **Churn: 15** - Frequently modified

**Conclusion**: This file is a ticking time bomb - complex, poorly tested, duplicated, and frequently changed.

**Action Plan**:
1. **Immediate**: Add characterization tests to document current behavior
2. **Short-term**: Extract duplicated code, reduce complexity through decomposition
3. **Ongoing**: Achieve 90%+ coverage on refactored components
4. **Monitor**: Track if churn decreases after refactoring

## Automated Integration

### Rake Task for Combined Analysis

```ruby
# lib/tasks/code_quality.rake
namespace :code_quality do
  desc "Run comprehensive code quality analysis"
  task :report => :environment do
    puts "\n" + "="*80
    puts "CODE QUALITY REPORT"
    puts "="*80
    
    # Run tests with coverage
    puts "\n▶️  Running tests with coverage..."
    system("COVERAGE=true bundle exec rake test") || exit(1)
    
    # Run RubyCritic
    puts "\n▶️  Running RubyCritic analysis..."
    system("bundle exec rubycritic app lib --format console --no-browser") || exit(1)
    
    # Parse and combine results
    puts "\n▶️  Generating combined analysis..."
    ruby "scripts/combined_quality_report.rb"
    
    puts "\n✅ Reports generated:"
    puts "  - Coverage: coverage/index.html"
    puts "  - RubyCritic: tmp/rubycritic/overview.html"
    puts "  - Combined: tmp/quality_report.html"
  end
  
  desc "Check if code quality meets thresholds"
  task :check => :environment do
    # Run analysis
    Rake::Task["code_quality:report"].invoke
    
    # Load results
    coverage_data = JSON.parse(File.read('coverage/.resultset.json'))
    coverage_pct = calculate_coverage(coverage_data)
    
    critic_data = JSON.parse(File.read('tmp/rubycritic/report.json'))
    avg_score = critic_data["analysed_modules"].sum { |m| m["score"] } / critic_data["analysed_modules"].size
    
    # Check thresholds
    passed = true
    
    if coverage_pct < 90
      puts "❌ Coverage below 90%: #{coverage_pct}%"
      passed = false
    end
    
    if avg_score < 80
      puts "❌ Average RubyCritic score below 80: #{avg_score}"
      passed = false
    end
    
    exit(1) unless passed
    puts "✅ Code quality checks passed"
  end
end
```

### Combined Analysis Script

```ruby
# scripts/combined_quality_report.rb
require 'json'
require 'erb'

class CombinedQualityReport
  def initialize
    @coverage_data = load_coverage
    @critic_data = load_critic
  end
  
  def generate
    files = combine_metrics
    problem_files = identify_problems(files)
    
    html = render_html(files, problem_files)
    File.write('tmp/quality_report.html', html)
    
    console_report(problem_files)
  end
  
  private
  
  def load_coverage
    data = JSON.parse(File.read('coverage/.resultset.json'))
    coverage = data.values.first['coverage']['lines']
    
    coverage.transform_values do |line_cov|
      total = line_cov.compact.size
      covered = line_cov.compact.count { |x| x > 0 }
      ((covered.to_f / total) * 100).round(2)
    end
  end
  
  def load_critic
    JSON.parse(File.read('tmp/rubycritic/report.json'))
  end
  
  def combine_metrics
    files = []
    
    @critic_data['analysed_modules'].each do |mod|
      path = mod['path']
      coverage_pct = @coverage_data[path] || 0
      
      files << {
        path: path,
        coverage: coverage_pct,
        score: mod['score'],
        complexity: mod['complexity'],
        duplication: mod['duplication'],
        churn: mod['churn'],
        priority: calculate_priority(coverage_pct, mod['complexity'])
      }
    end
    
    files.sort_by { |f| -f[:priority] }
  end
  
  def calculate_priority(coverage, complexity)
    # Higher score = higher priority to fix
    priority = 0
    
    # Low coverage adds priority
    priority += (100 - coverage) / 10
    
    # High complexity adds priority
    priority += complexity / 5
    
    # Critical combination: high complexity + low coverage
    if complexity > 20 && coverage < 60
      priority += 50
    end
    
    priority
  end
  
  def identify_problems(files)
    {
      critical: files.select { |f| f[:complexity] > 20 && f[:coverage] < 60 },
      high: files.select { |f| f[:complexity] > 20 && f[:coverage] >= 60 },
      medium: files.select { |f| f[:complexity] <= 20 && f[:coverage] < 60 }
    }
  end
  
  def console_report(problems)
    puts "\n" + "="*80
    puts "COMBINED CODE QUALITY ANALYSIS"
    puts "="*80
    
    if problems[:critical].any?
      puts "\n🚨 CRITICAL (High Complexity + Low Coverage):"
      problems[:critical].each do |f|
        puts "  • #{f[:path]}"
        puts "    Coverage: #{f[:coverage]}% | Complexity: #{f[:complexity]} | Score: #{f[:score]}"
      end
    end
    
    if problems[:high].any?
      puts "\n⚠️  HIGH PRIORITY (High Complexity, Tested):"
      problems[:high].first(5).each do |f|
        puts "  • #{f[:path]}"
        puts "    Coverage: #{f[:coverage]}% | Complexity: #{f[:complexity]} | Score: #{f[:score]}"
      end
    end
    
    if problems[:medium].any?
      puts "\n📝 MEDIUM PRIORITY (Low Complexity, Low Coverage):"
      problems[:medium].first(5).each do |f|
        puts "  • #{f[:path]}"
        puts "    Coverage: #{f[:coverage]}% | Complexity: #{f[:complexity]}"
      end
    end
    
    puts "\n💡 Recommendations:"
    if problems[:critical].any?
      puts "  1. CRITICAL FILES: Add tests first, then refactor"
      puts "     Start with: #{problems[:critical].first[:path]}"
    end
    if problems[:high].any?
      puts "  2. HIGH PRIORITY: Safe to refactor with test coverage"
    end
    if problems[:medium].any?
      puts "  3. MEDIUM: Add regression tests"
    end
    puts ""
  end
  
  def render_html(files, problems)
    template = File.read('scripts/quality_report_template.html.erb')
    ERB.new(template).result(binding)
  end
end

CombinedQualityReport.new.generate if __FILE__ == $0
```

### HTML Report Template

```erb
<!-- scripts/quality_report_template.html.erb -->
<!DOCTYPE html>
<html>
<head>
  <title>Code Quality Report</title>
  <style>
    body { font-family: Arial, sans-serif; margin: 40px; }
    table { border-collapse: collapse; width: 100%; margin: 20px 0; }
    th, td { border: 1px solid #ddd; padding: 12px; text-align: left; }
    th { background-color: #4CAF50; color: white; }
    tr:nth-child(even) { background-color: #f2f2f2; }
    .critical { background-color: #ffcdd2; }
    .high { background-color: #fff3cd; }
    .medium { background-color: #d1ecf1; }
    .good { background-color: #d4edda; }
  </style>
</head>
<body>
  <h1>Code Quality Analysis Report</h1>
  <p>Generated: <%= Time.now.strftime('%Y-%m-%d %H:%M:%S') %></p>
  
  <% if problems[:critical].any? %>
    <h2>🚨 Critical Priority (High Complexity + Low Coverage)</h2>
    <table>
      <tr>
        <th>File</th>
        <th>Coverage</th>
        <th>Complexity</th>
        <th>Score</th>
        <th>Action</th>
      </tr>
      <% problems[:critical].each do |file| %>
        <tr class="critical">
          <td><%= file[:path] %></td>
          <td><%= file[:coverage] %>%</td>
          <td><%= file[:complexity] %></td>
          <td><%= file[:score] %></td>
          <td>Add tests, then refactor</td>
        </tr>
      <% end %>
    </table>
  <% end %>
  
  <h2>All Files</h2>
  <table>
    <tr>
      <th>File</th>
      <th>Coverage</th>
      <th>Complexity</th>
      <th>Score</th>
      <th>Priority</th>
    </tr>
    <% files.first(50).each do |file| %>
      <tr class="<%= file[:priority] > 50 ? 'critical' : file[:priority] > 30 ? 'high' : file[:priority] > 15 ? 'medium' : 'good' %>">
        <td><%= file[:path] %></td>
        <td><%= file[:coverage] %>%</td>
        <td><%= file[:complexity] %></td>
        <td><%= file[:score] %></td>
        <td><%= file[:priority].round(1) %></td>
      </tr>
    <% end %>
  </table>
</body>
</html>
```

## CI/CD Integration

### GitHub Actions

```yaml
# .github/workflows/code_quality.yml
name: Code Quality

on: [push, pull_request]

jobs:
  quality:
    runs-on: ubuntu-latest
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup Ruby
        uses: ruby/setup-ruby@v1
        with:
          ruby-version: 3.2
          bundler-cache: true
      
      - name: Run quality analysis
        run: bundle exec rake code_quality:report
      
      - name: Check thresholds
        run: bundle exec rake code_quality:check
      
      - name: Upload reports
        uses: actions/upload-artifact@v4
        if: always()
        with:
          name: quality-reports
          path: |
            coverage/
            tmp/rubycritic/
            tmp/quality_report.html
```

## Monitoring Trends

Track both metrics over time:

```ruby
# scripts/track_quality_history.rb
require 'json'

class QualityHistoryTracker
  HISTORY_FILE = 'tmp/quality_history.json'
  
  def track
    history = load_history
    
    entry = {
      timestamp: Time.now.iso8601,
      coverage: current_coverage,
      avg_score: current_avg_score,
      avg_complexity: current_avg_complexity,
      git_sha: `git rev-parse HEAD`.strip
    }
    
    history << entry
    save_history(history.last(100))
    
    analyze_trends(history)
  end
  
  private
  
  def current_coverage
    data = JSON.parse(File.read('coverage/.resultset.json'))
    cov = data.values.first['coverage']['lines']
    total = cov.size
    covered = cov.compact.count { |x| x > 0 }
    ((covered.to_f / total) * 100).round(2)
  end
  
  def current_avg_score
    data = JSON.parse(File.read('tmp/rubycritic/report.json'))
    modules = data['analysed_modules']
    return 0 if modules.empty?
    
    (modules.sum { |m| m['score'] } / modules.size.to_f).round(2)
  end
  
  def current_avg_complexity
    data = JSON.parse(File.read('tmp/rubycritic/report.json'))
    modules = data['analysed_modules']
    return 0 if modules.empty?
    
    (modules.sum { |m| m['complexity'] } / modules.size.to_f).round(2)
  end
  
  def analyze_trends(history)
    return if history.size < 2
    
    recent = history.last(10)
    
    cov_trend = calculate_trend(recent.map { |e| e[:coverage] })
    score_trend = calculate_trend(recent.map { |e| e[:avg_score] })
    
    puts "\n📊 Quality Trends (last 10 commits):"
    puts "  Coverage: #{cov_trend}"
    puts "  Code Quality: #{score_trend}"
  end
  
  def calculate_trend(values)
    return "insufficient data" if values.size < 2
    
    first_half = values.first(values.size / 2).sum / (values.size / 2.0)
    second_half = values.last(values.size / 2).sum / (values.size / 2.0)
    
    diff = second_half - first_half
    
    if diff > 1
      "📈 Improving (+#{diff.round(2)})"
    elsif diff < -1
      "📉 Declining (#{diff.round(2)})"
    else
      "➡️  Stable"
    end
  end
  
  def load_history
    return [] unless File.exist?(HISTORY_FILE)
    JSON.parse(File.read(HISTORY_FILE), symbolize_names: true)
  end
  
  def save_history(history)
    FileUtils.mkdir_p(File.dirname(HISTORY_FILE))
    File.write(HISTORY_FILE, JSON.pretty_generate(history))
  end
end

QualityHistoryTracker.new.track if __FILE__ == $0
```

## Best Practices

1. **Regular Analysis**: Run both tools in CI on every commit
2. **Set Realistic Thresholds**: Coverage 80-90%, RubyCritic score 70+
3. **Track Trends**: Monitor improvements over time
4. **Prioritize**: Focus on high-complexity, low-coverage files first
5. **Refactor Safely**: Use high test coverage as safety net for refactoring
6. **Document Exemptions**: Justify any code excluded from coverage/analysis
7. **Team Reviews**: Discuss quality metrics in code reviews
8. **Continuous Improvement**: Gradually increase thresholds
9. **Automate**: Use rake tasks and CI to make analysis automatic
10. **Visualize**: Create dashboards showing combined metrics

## Summary

SimpleCov + RubyCritic provides complete code health visibility:

- **SimpleCov**: Shows WHAT needs testing
- **RubyCritic**: Shows WHAT needs refactoring  
- **Combined**: Shows WHAT to prioritize

Focus on files that are both complex and poorly tested for maximum impact on code quality and maintainability.
