#!/usr/bin/env ruby
# frozen_string_literal: true

# Coverage Summary
#
# Quick summary of coverage metrics from SimpleCov results.
#
# Usage:
#   ruby scripts/coverage_summary.rb

require 'json'

unless File.exist?('coverage/.resultset.json')
  puts "❌ Coverage results not found at coverage/.resultset.json"
  puts "Run tests with SimpleCov enabled first."
  exit 1
end

results = JSON.parse(File.read('coverage/.resultset.json'))
coverage_data = results.values.first

# Line coverage
line_coverage = coverage_data.dig('coverage', 'lines')

if line_coverage
  all_lines = line_coverage.values.flat_map(&:to_a).compact
  total_lines = all_lines.size
  covered_lines = all_lines.count { |x| x && x > 0 }
  line_percentage = (covered_lines.to_f / total_lines * 100).round(2)
  
  puts "\n📊 Coverage Summary"
  puts "="*50
  puts "Line Coverage: #{line_percentage}%"
  puts "#{covered_lines}/#{total_lines} lines covered"
  
  # Branch coverage if available
  branch_coverage = coverage_data.dig('coverage', 'branches')
  if branch_coverage
    all_branches = branch_coverage.values.flat_map(&:values).flatten.compact
    total_branches = all_branches.size
    covered_branches = all_branches.count { |x| x && x > 0 }
    branch_percentage = (covered_branches.to_f / total_branches * 100).round(2)
    
    puts "\nBranch Coverage: #{branch_percentage}%"
    puts "#{covered_branches}/#{total_branches} branches covered"
  end
  
  puts "="*50
  
  # Exit with error if below threshold
  threshold = ENV['COVERAGE_THRESHOLD']&.to_f || 90
  if line_percentage < threshold
    puts "\n❌ Coverage (#{line_percentage}%) below threshold (#{threshold}%)"
    exit 1
  else
    puts "\n✅ Coverage meets threshold (#{threshold}%)"
  end
else
  puts "❌ Could not parse coverage data"
  exit 1
end
