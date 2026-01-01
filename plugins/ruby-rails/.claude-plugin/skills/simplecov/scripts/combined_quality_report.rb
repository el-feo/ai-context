#!/usr/bin/env ruby
# frozen_string_literal: true

# Combined Quality Report
#
# Combines SimpleCov coverage data with RubyCritic quality metrics
# to generate a comprehensive code health report.
#
# Usage:
#   ruby scripts/combined_quality_report.rb
#   ruby scripts/combined_quality_report.rb --output tmp/quality_report.html

require 'json'
require 'erb'
require 'fileutils'

class CombinedQualityReport
  def initialize(options = {})
    @options = options
    @coverage_file = 'coverage/.resultset.json'
    @critic_file = 'tmp/rubycritic/report.json'
  end

  def generate
    unless File.exist?(@coverage_file)
      puts "❌ Coverage results not found. Run tests with SimpleCov first."
      exit 1
    end

    unless File.exist?(@critic_file)
      puts "❌ RubyCritic results not found. Run 'bundle exec rubycritic app lib' first."
      exit 1
    end

    @coverage_data = load_coverage
    @critic_data = load_critic
    
    files = combine_metrics
    problem_files = identify_problems(files)
    
    console_report(files, problem_files)
    
    if @options[:output]
      html = render_html(files, problem_files)
      FileUtils.mkdir_p(File.dirname(@options[:output]))
      File.write(@options[:output], html)
      puts "\n📄 HTML report saved to: #{@options[:output]}"
    end
  end

  private

  def load_coverage
    data = JSON.parse(File.read(@coverage_file), symbolize_names: true)
    suite_data = data.values.first
    coverage_lines = suite_data.dig(:coverage, :lines) || {}
    
    coverage_lines.transform_values do |line_cov|
      next 0 if line_cov.nil? || line_cov.empty?
      
      total = line_cov.compact.size
      next 0 if total == 0
      
      covered = line_cov.compact.count { |x| x && x > 0 }
      ((covered.to_f / total) * 100).round(2)
    end
  end

  def load_critic
    JSON.parse(File.read(@critic_file), symbolize_names: true)
  end

  def combine_metrics
    files = []
    
    @critic_data[:analysed_modules].each do |mod|
      path = mod[:path]
      coverage_pct = @coverage_data[File.expand_path(path)] || 0
      
      files << {
        path: path,
        coverage: coverage_pct,
        score: mod[:score],
        complexity: mod[:complexity],
        duplication: mod[:duplication],
        churn: mod[:churn],
        priority: calculate_priority(coverage_pct, mod[:complexity], mod[:churn])
      }
    end
    
    files.sort_by { |f| -f[:priority] }
  end

  def calculate_priority(coverage, complexity, churn)
    priority = 0
    
    # Low coverage adds priority
    priority += (100 - coverage) / 10
    
    # High complexity adds priority
    priority += complexity / 5
    
    # High churn adds priority
    priority += churn / 10
    
    # Critical combination: high complexity + low coverage
    if complexity > 20 && coverage < 60
      priority += 50
    end
    
    # Very bad: high complexity + low coverage + high churn
    if complexity > 20 && coverage < 60 && churn > 10
      priority += 25
    end
    
    priority.round(2)
  end

  def identify_problems(files)
    {
      critical: files.select { |f| f[:complexity] > 20 && f[:coverage] < 60 },
      high: files.select { |f| f[:complexity] > 20 && f[:coverage] >= 60 },
      medium: files.select { |f| f[:complexity] <= 20 && f[:coverage] < 60 },
      good: files.select { |f| f[:complexity] <= 20 && f[:coverage] >= 60 }
    }
  end

  def console_report(files, problems)
    puts "\n" + "="*80
    puts "COMBINED CODE QUALITY ANALYSIS"
    puts "="*80
    
    overall_stats(files)
    
    if problems[:critical].any?
      puts "\n🚨 CRITICAL PRIORITY (High Complexity + Low Coverage):"
      problems[:critical].first(10).each do |f|
        puts "  • #{f[:path]}"
        puts "    Coverage: #{f[:coverage]}% | Complexity: #{f[:complexity]} | " \
             "Churn: #{f[:churn]} | Priority: #{f[:priority]}"
      end
    end
    
    if problems[:high].any?
      puts "\n⚠️  HIGH PRIORITY (High Complexity, Well Tested):"
      problems[:high].first(5).each do |f|
        puts "  • #{f[:path]}"
        puts "    Coverage: #{f[:coverage]}% | Complexity: #{f[:complexity]} | Score: #{f[:score]}"
      end
    end
    
    if problems[:medium].any?
      puts "\n📝 MEDIUM PRIORITY (Simple, Needs Tests):"
      problems[:medium].first(5).each do |f|
        puts "  • #{f[:path]}"
        puts "    Coverage: #{f[:coverage]}% | Complexity: #{f[:complexity]}"
      end
    end
    
    recommendations(problems)
  end

  def overall_stats(files)
    avg_coverage = (files.sum { |f| f[:coverage] } / files.size.to_f).round(2)
    avg_complexity = (files.sum { |f| f[:complexity] } / files.size.to_f).round(2)
    avg_score = (files.sum { |f| f[:score] } / files.size.to_f).round(2)
    
    puts "\n📊 Overall Statistics:"
    puts "  Average Coverage: #{avg_coverage}%"
    puts "  Average Complexity: #{avg_complexity}"
    puts "  Average Quality Score: #{avg_score}"
    puts "  Total Files: #{files.size}"
  end

  def recommendations(problems)
    puts "\n💡 Recommendations:"
    
    if problems[:critical].any?
      puts "  1. 🚨 IMMEDIATE ACTION: #{problems[:critical].size} critical files"
      puts "     Start with: #{problems[:critical].first[:path]}"
      puts "     Action: Add comprehensive tests, then refactor to reduce complexity"
    end
    
    if problems[:high].any?
      puts "  2. ⚠️  HIGH PRIORITY: #{problems[:high].size} complex but tested files"
      puts "     Action: Safe to refactor with test coverage as safety net"
    end
    
    if problems[:medium].any?
      puts "  3. 📝 MEDIUM: #{problems[:medium].size} simple files need tests"
      puts "     Action: Add tests for regression protection"
    end
    
    puts ""
  end

  def render_html(files, problems)
    template = <<~HTML
      <!DOCTYPE html>
      <html>
      <head>
        <title>Code Quality Report</title>
        <style>
          body { 
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
            margin: 0;
            padding: 20px;
            background: #f5f5f5;
          }
          .container { max-width: 1200px; margin: 0 auto; }
          h1 { color: #333; }
          .summary { 
            background: white;
            padding: 20px;
            border-radius: 8px;
            margin: 20px 0;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
          }
          .stats { 
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 15px;
            margin: 20px 0;
          }
          .stat {
            background: white;
            padding: 15px;
            border-radius: 8px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
          }
          .stat-label { font-size: 14px; color: #666; }
          .stat-value { font-size: 24px; font-weight: bold; color: #333; }
          table { 
            width: 100%;
            border-collapse: collapse;
            background: white;
            border-radius: 8px;
            overflow: hidden;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
          }
          th, td { 
            padding: 12px;
            text-align: left;
            border-bottom: 1px solid #eee;
          }
          th { 
            background: #4CAF50;
            color: white;
            font-weight: 600;
          }
          tr:hover { background: #f9f9f9; }
          .critical { background-color: #ffebee !important; }
          .high { background-color: #fff3e0 !important; }
          .medium { background-color: #e3f2fd !important; }
          .good { background-color: #e8f5e9 !important; }
          .priority-badge {
            display: inline-block;
            padding: 4px 8px;
            border-radius: 4px;
            font-size: 12px;
            font-weight: 600;
          }
          .priority-critical { background: #f44336; color: white; }
          .priority-high { background: #ff9800; color: white; }
          .priority-medium { background: #2196F3; color: white; }
          .priority-low { background: #4CAF50; color: white; }
          .section {
            background: white;
            margin: 20px 0;
            padding: 20px;
            border-radius: 8px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
          }
        </style>
      </head>
      <body>
        <div class="container">
          <h1>🔍 Code Quality Analysis Report</h1>
          <p style="color: #666;">Generated: <%= Time.now.strftime('%Y-%m-%d %H:%M:%S') %></p>
          
          <div class="stats">
            <div class="stat">
              <div class="stat-label">Average Coverage</div>
              <div class="stat-value"><%= (files.sum { |f| f[:coverage] } / files.size.to_f).round(2) %>%</div>
            </div>
            <div class="stat">
              <div class="stat-label">Average Complexity</div>
              <div class="stat-value"><%= (files.sum { |f| f[:complexity] } / files.size.to_f).round(2) %></div>
            </div>
            <div class="stat">
              <div class="stat-label">Average Score</div>
              <div class="stat-value"><%= (files.sum { |f| f[:score] } / files.size.to_f).round(2) %></div>
            </div>
            <div class="stat">
              <div class="stat-label">Total Files</div>
              <div class="stat-value"><%= files.size %></div>
            </div>
          </div>
          
          <% if problems[:critical].any? %>
            <div class="section">
              <h2>🚨 Critical Priority (<%= problems[:critical].size %>)</h2>
              <p>High complexity + low coverage = dangerous combination</p>
              <table>
                <tr>
                  <th>File</th>
                  <th>Coverage</th>
                  <th>Complexity</th>
                  <th>Score</th>
                  <th>Churn</th>
                  <th>Priority</th>
                </tr>
                <% problems[:critical].each do |file| %>
                  <tr class="critical">
                    <td><%= file[:path] %></td>
                    <td><%= file[:coverage] %>%</td>
                    <td><%= file[:complexity] %></td>
                    <td><%= file[:score] %></td>
                    <td><%= file[:churn] %></td>
                    <td><span class="priority-badge priority-critical"><%= file[:priority] %></span></td>
                  </tr>
                <% end %>
              </table>
            </div>
          <% end %>
          
          <div class="section">
            <h2>📊 All Files</h2>
            <table>
              <tr>
                <th>File</th>
                <th>Coverage</th>
                <th>Complexity</th>
                <th>Score</th>
                <th>Priority</th>
              </tr>
              <% files.first(100).each do |file| %>
                <tr class="<%= file[:priority] > 50 ? 'critical' : file[:priority] > 30 ? 'high' : file[:priority] > 15 ? 'medium' : 'good' %>">
                  <td><%= file[:path] %></td>
                  <td><%= file[:coverage] %>%</td>
                  <td><%= file[:complexity] %></td>
                  <td><%= file[:score] %></td>
                  <td><span class="priority-badge priority-<%= file[:priority] > 50 ? 'critical' : file[:priority] > 30 ? 'high' : file[:priority] > 15 ? 'medium' : 'low' %>"><%= file[:priority] %></span></td>
                </tr>
              <% end %>
            </table>
          </div>
        </div>
      </body>
      </html>
    HTML

    ERB.new(template).result(binding)
  end
end

# Parse command line options
require 'optparse'
options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: combined_quality_report.rb [options]"
  
  opts.on("-o", "--output FILE", "Output HTML file path") do |o|
    options[:output] = o
  end
  
  opts.on("-h", "--help", "Show this help") do
    puts opts
    exit
  end
end.parse!

# Run the report
CombinedQualityReport.new(options).generate
