#!/usr/bin/env ruby
# frozen_string_literal: true

# Analyze Rails models and controllers for potential N+1 query issues.
# Detects patterns where associations are accessed without eager loading.

def find_rails_root(start_path = ".")
  current = File.expand_path(start_path)
  loop do
    return current if File.exist?(File.join(current, "config", "application.rb"))
    parent = File.dirname(current)
    break if parent == current
    current = parent
  end
  abort "Error: Not in a Rails application directory"
end

def analyze_controller_action(file_path, content)
  issues = []
  lines = content.split("\n")

  lines.each_with_index do |line, idx|
    line_num = idx + 1
    next unless line.match?(/\.(all|where|find_by|find)\b/)

    # Check nearby lines for eager loading
    context_start = [0, idx - 3].max
    context_end = [lines.length - 1, idx + 2].min
    context = lines[context_start..context_end].join("\n")

    next if context.match?(/\.(includes|preload|eager_load)\b/)

    # Check if result is assigned to an instance variable
    var_match = line.match(/@(\w+)\s*=/)
    next unless var_match

    var_name = var_match[1]
    # Look ahead for association access on this variable
    lookahead_end = [lines.length - 1, idx + 20].min
    (idx + 1..lookahead_end).each do |j|
      if lines[j]&.match?(/@#{Regexp.escape(var_name)}\.\w+\.\w+/)
        issues << {
          file: file_path,
          line: line_num,
          type: "potential_n_plus_one",
          severity: "warning",
          message: "Potential N+1 query: Query at line #{line_num} may need eager loading"
        }
        break
      end
    end
  end

  issues
end

def analyze_view_file(file_path, content)
  issues = []
  lines = content.split("\n")

  lines.each_with_index do |line, idx|
    line_num = idx + 1
    if line.match?(/\w+\.\w+\.(each|map|size|count|\w+)/)
      issues << {
        file: file_path,
        line: line_num,
        type: "view_association_access",
        severity: "info",
        message: "Association access in view - verify eager loading in controller"
      }
    end
  end

  issues
end

def scan_directory(directory, pattern, &analyzer)
  return [] unless Dir.exist?(directory)

  Dir.glob(File.join(directory, "**", pattern)).flat_map do |file_path|
    content = File.read(file_path)
    analyzer.call(file_path, content)
  rescue => e
    warn "Error analyzing #{file_path}: #{e.message}"
    []
  end
end

rails_root = find_rails_root
puts "Analyzing Rails application at: #{rails_root}"
puts "=" * 80

controller_issues = scan_directory(
  File.join(rails_root, "app", "controllers"), "*.rb", &method(:analyze_controller_action)
)

view_issues = scan_directory(
  File.join(rails_root, "app", "views"), "*.erb", &method(:analyze_view_file)
)
view_issues += scan_directory(
  File.join(rails_root, "app", "views"), "*.haml", &method(:analyze_view_file)
)

all_issues = controller_issues + view_issues
by_severity = all_issues.group_by { |i| i[:severity] }

puts "\nFound #{all_issues.length} potential issues:\n"

%w[warning info].each do |severity|
  issues = by_severity.fetch(severity, [])
  next if issues.empty?

  puts "\n#{severity.upcase} (#{issues.length} issues):"
  puts "-" * 80
  issues.each do |issue|
    puts "  #{issue[:file]}:#{issue[:line]}"
    puts "  -> #{issue[:message]}"
    puts
  end
end

if all_issues.empty?
  puts "No obvious N+1 query issues detected!"
end

exit(by_severity.fetch("warning", []).any? ? 1 : 0)
