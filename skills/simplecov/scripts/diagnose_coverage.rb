#!/usr/bin/env ruby
# frozen_string_literal: true

# Coverage Diagnostic Tool
#
# Helps debug SimpleCov configuration and identify why files aren't being tracked.
#
# Usage:
#   ruby scripts/diagnose_coverage.rb
#   ruby scripts/diagnose_coverage.rb app/models/user.rb

require 'simplecov'

# Load SimpleCov configuration
if File.exist?('.simplecov')
  load '.simplecov'
elsif File.exist?('test/test_helper.rb') && File.read('test/test_helper.rb').include?('SimpleCov')
  puts "⚠️  SimpleCov configured in test/test_helper.rb, not .simplecov"
elsif File.exist?('spec/spec_helper.rb') && File.read('spec/spec_helper.rb').include?('SimpleCov')
  puts "⚠️  SimpleCov configured in spec/spec_helper.rb, not .simplecov"
else
  puts "⚠️  No SimpleCov configuration found"
end

puts "\n🔍 SimpleCov Configuration Diagnostic"
puts "="*60

puts "\nBasic Configuration:"
puts "  Root: #{SimpleCov.root}"
puts "  Coverage Enabled: #{SimpleCov.running}"
puts "  Command Name: #{SimpleCov.command_name || 'default'}"

if SimpleCov.instance_variable_get(:@formatters)
  puts "  Formatters: #{SimpleCov.formatters.map(&:class).join(', ')}"
end

puts "\nFilters (#{SimpleCov.filters.size}):"
SimpleCov.filters.each_with_index do |filter, i|
  puts "  #{i + 1}. #{filter.class}"
end

puts "\nGroups (#{SimpleCov.groups.size}):"
SimpleCov.groups.each do |name, _filter|
  puts "  - #{name}"
end

# Check if specific file would be tracked
if ARGV[0]
  test_file = File.expand_path(ARGV[0])
  puts "\nFile Tracking Test:"
  puts "  Testing: #{test_file}"
  
  if File.exist?(test_file)
    puts "  ✅ File exists"
    
    # Create a dummy source file to test filtering
    begin
      dummy_coverage = [1] * File.readlines(test_file).size
      dummy_source = SimpleCov::SourceFile.new(test_file, dummy_coverage)
      
      filtered = SimpleCov.filtered?(dummy_source)
      puts "  #{filtered ? '❌' : '✅'} Would #{filtered ? 'NOT ' : ''}be tracked"
      
      if filtered
        puts "\n  Reasons for exclusion:"
        SimpleCov.filters.each_with_index do |filter, i|
          if filter.matches?(dummy_source)
            puts "    - Filter #{i + 1} (#{filter.class}) matched"
          end
        end
      end
    rescue => e
      puts "  ⚠️  Error testing file: #{e.message}"
    end
  else
    puts "  ❌ File does not exist"
  end
end

# Check for common issues
puts "\nCommon Issues Check:"

if SimpleCov.root != Dir.pwd
  puts "  ⚠️  SimpleCov root (#{SimpleCov.root}) differs from current directory (#{Dir.pwd})"
end

has_test_filter = SimpleCov.filters.any? { |f| 
  f.is_a?(SimpleCov::StringFilter) && (f.filter_argument.include?('test') || f.filter_argument.include?('spec'))
}
if has_test_filter
  puts "  ✅ Test files are filtered"
else
  puts "  ⚠️  No test file filter detected"
end

if File.exist?('coverage/.resultset.json')
  puts "  ✅ Coverage results exist"
  
  results = JSON.parse(File.read('coverage/.resultset.json'))
  tracked_files = results.values.first.dig('coverage', 'lines')&.size || 0
  puts "     Currently tracking: #{tracked_files} files"
else
  puts "  ⚠️  No coverage results found"
end

puts "\n💡 Tips:"
puts "  - Ensure SimpleCov.start is FIRST in test helper"
puts "  - Check filters aren't excluding too much"
puts "  - Verify SimpleCov.root matches project root"
puts "  - Run tests to generate coverage data"
puts ""
