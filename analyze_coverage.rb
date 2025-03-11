#!/usr/bin/env ruby
require 'json'

# Read the coverage data
coverage_data = JSON.parse(File.read('coverage/.resultset.json'))
rspec_coverage = coverage_data['RSpec']['coverage']

# Calculate coverage for each file
file_coverage = {}
rspec_coverage.each do |file_path, data|
  next unless file_path.include?('/lib/mcp_rails/')

  lines = data['lines']
  total_lines = lines.count { |line| line != nil }
  covered_lines = lines.count { |line| line.is_a?(Integer) && line > 0 }

  coverage_percent = total_lines > 0 ? (covered_lines.to_f / total_lines * 100).round(2) : 100.0

  # Find uncovered lines
  uncovered_lines = []
  lines.each_with_index do |line, index|
    if line == 0
      uncovered_lines << (index + 1)
    end
  end

  file_coverage[file_path] = {
    total_lines: total_lines,
    covered_lines: covered_lines,
    coverage_percent: coverage_percent,
    uncovered_lines: uncovered_lines
  }
end

# Sort by coverage percentage
sorted_coverage = file_coverage.sort_by { |_, data| data[:coverage_percent] }

# Print the results
puts "File Coverage Report:"
puts "-" * 80
sorted_coverage.each do |file_path, data|
  short_path = file_path.split('/lib/')[1]
  puts "#{short_path}: #{data[:coverage_percent]}% (#{data[:covered_lines]}/#{data[:total_lines]} lines)"

  if data[:uncovered_lines].any?
    puts "  Uncovered lines: #{data[:uncovered_lines].join(', ')}"

    # Show the actual code for uncovered lines
    puts "\n  Uncovered code:"
    if File.exist?(file_path)
      file_content = File.readlines(file_path)
      data[:uncovered_lines].each do |line_num|
        if line_num - 1 < file_content.length
          puts "    Line #{line_num}: #{file_content[line_num - 1].strip}"
        end
      end
    else
      puts "    (File not found)"
    end
    puts
  end
  puts
end

# Overall coverage
total_lines = file_coverage.sum { |_, data| data[:total_lines] }
covered_lines = file_coverage.sum { |_, data| data[:covered_lines] }
overall_coverage = (covered_lines.to_f / total_lines * 100).round(2)

puts "-" * 80
puts "Overall coverage: #{overall_coverage}% (#{covered_lines}/#{total_lines} lines)"

# Add a section to show files with less than 80% coverage
puts "\nFiles below 80% coverage:"
puts "-" * 80
low_coverage_files = sorted_coverage.select { |_, data| data[:coverage_percent] < 80 }
if low_coverage_files.empty?
  puts "All files have at least 80% coverage!"
else
  low_coverage_files.each do |file_path, data|
    short_path = file_path.split('/lib/')[1]
    puts "#{short_path}: #{data[:coverage_percent]}% (#{data[:covered_lines]}/#{data[:total_lines]} lines)"
  end
end
