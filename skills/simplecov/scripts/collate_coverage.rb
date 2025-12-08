#!/usr/bin/env ruby
# frozen_string_literal: true

# Coverage Collation Script
#
# Collates coverage results from multiple CI nodes/machines into a single report.
# Useful for parallel CI builds where each node runs a subset of tests.
#
# Usage:
#   ruby scripts/collate_coverage.rb coverage-results/*/.resultset.json
#   ruby scripts/collate_coverage.rb --profile rails coverage-node-*/.resultset.json

require 'simplecov'

# Parse arguments
profile = 'rails'
result_files = []

ARGV.each do |arg|
  if arg == '--profile'
    profile = ARGV[ARGV.index(arg) + 1]
  elsif arg.start_with?('--')
    # Skip flags
  elsif !ARGV[ARGV.index(arg) - 1]&.start_with?('--')
    result_files << arg
  end
end

# Use glob patterns if provided
if result_files.empty?
  result_files = Dir['coverage-results/*/.resultset.json']
  
  if result_files.empty?
    puts "❌ No coverage result files found"
    puts ""
    puts "Usage: collate_coverage.rb [--profile PROFILE] RESULT_FILES..."
    puts ""
    puts "Examples:"
    puts "  ruby scripts/collate_coverage.rb coverage-results/*/.resultset.json"
    puts "  ruby scripts/collate_coverage.rb --profile rails coverage-node-*/.resultset.json"
    exit 1
  end
end

puts "📊 Collating coverage from #{result_files.size} result files..."
result_files.each { |f| puts "  - #{f}" }
puts ""

# Collate results
SimpleCov.collate result_files, profile do
  formatter SimpleCov::Formatter::MultiFormatter.new([
    SimpleCov::Formatter::Console,
    SimpleCov::Formatter::HTMLFormatter
  ])
  
  # You can add additional configuration here
  # minimum_coverage line: 90, branch: 80
end

puts ""
puts "✅ Coverage collation complete!"
puts "📄 View report: coverage/index.html"
