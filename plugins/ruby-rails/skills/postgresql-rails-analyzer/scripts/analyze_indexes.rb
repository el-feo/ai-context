#!/usr/bin/env ruby
# frozen_string_literal: true

# Analyze Rails schema for index opportunities.
# Detects foreign keys without indexes and queries that might benefit from indexes.

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

def parse_schema(schema_file)
  content = File.read(schema_file)
  tables = {}

  # Extract table definitions
  content.scan(/create_table\s+"(\w+)".*?do\s*\|t\|(.*?)end/m) do |table_name, table_def|
    columns = table_def.scan(/t\.\w+\s+"(\w+)"/).flatten
    foreign_keys = table_def.scan(/t\.\w+\s+"(\w+_id)"/).flatten
    tables[table_name] = { columns: columns, foreign_keys: foreign_keys, indexes: [] }
  end

  # Extract index definitions
  content.scan(/add_index\s+"(\w+)",\s+\[?"(\w+)"?\]?/) do |table_name, column_name|
    tables[table_name][:indexes] << column_name if tables[table_name]
  end

  tables
end

def analyze_missing_indexes(tables)
  issues = []

  tables.each do |table_name, info|
    info[:foreign_keys].each do |fk|
      next if info[:indexes].include?(fk)

      issues << {
        table: table_name,
        column: fk,
        type: "missing_foreign_key_index",
        severity: "warning",
        message: "Foreign key #{fk} on #{table_name} should have an index",
        suggestion: "add_index :#{table_name}, :#{fk}"
      }
    end
  end

  issues
end

def analyze_where_clauses(rails_root)
  issues = []
  seen = Set.new

  %w[app/models/**/*.rb app/controllers/**/*.rb].each do |pattern|
    Dir.glob(File.join(rails_root, pattern)).each do |file_path|
      content = File.read(file_path)
      basename = File.basename(file_path, ".rb")

      # Match .where(column: value) or .where("column = ?")
      [/\.where\(\s*(\w+):\s*/, /\.where\(["'](\w+)\s*=/].each do |re|
        content.scan(re).flatten.each do |column|
          key = "#{basename}:#{column}"
          next if seen.include?(key)

          seen << key
          issues << {
            file: file_path,
            column: column,
            type: "where_clause_column",
            severity: "info",
            message: "Column \"#{column}\" used in WHERE clause - consider indexing if queries are slow"
          }
        end
      end
    rescue => e
      # skip unreadable files
    end
  end

  issues
end

def analyze_boolean_columns(tables)
  issues = []
  boolean_names = %w[active enabled published deleted]

  tables.each do |table_name, info|
    info[:columns].each do |column|
      next unless column.start_with?("is_", "has_") || boolean_names.include?(column)
      next if info[:indexes].include?(column)

      issues << {
        table: table_name,
        column: column,
        type: "boolean_index_opportunity",
        severity: "info",
        message: "Boolean column #{column} on #{table_name} might benefit from a partial index",
        suggestion: "add_index :#{table_name}, :#{column}, where: \"#{column} = true\""
      }
    end
  end

  issues
end

require "set"

rails_root = find_rails_root
schema_file = File.join(rails_root, "db", "schema.rb")

unless File.exist?(schema_file)
  abort "Error: Could not find db/schema.rb"
end

puts "Analyzing database schema at: #{rails_root}"
puts "=" * 80

tables = parse_schema(schema_file)
puts "Found #{tables.length} tables"

missing_fk = analyze_missing_indexes(tables)
where_cols = analyze_where_clauses(rails_root)
boolean_ops = analyze_boolean_columns(tables)

all_issues = missing_fk + where_cols + boolean_ops
by_type = all_issues.group_by { |i| i[:type] }

puts "\nFound #{all_issues.length} indexing opportunities:\n"

if by_type["missing_foreign_key_index"]
  issues = by_type["missing_foreign_key_index"]
  puts "\nMISSING FOREIGN KEY INDEXES (#{issues.length} issues):"
  puts "-" * 80
  issues.each do |issue|
    puts "  Table: #{issue[:table]}, Column: #{issue[:column]}"
    puts "  -> #{issue[:message]}"
    puts "  Migration: #{issue[:suggestion]}"
    puts
  end
end

if by_type["boolean_index_opportunity"]
  issues = by_type["boolean_index_opportunity"]
  puts "\nBOOLEAN COLUMN INDEXING OPPORTUNITIES (#{issues.length} suggestions):"
  puts "-" * 80
  issues.first(5).each do |issue|
    puts "  Table: #{issue[:table]}, Column: #{issue[:column]}"
    puts "  -> #{issue[:message]}"
    puts "  Migration: #{issue[:suggestion]}"
    puts
  end
  puts "  ... and #{issues.length - 5} more" if issues.length > 5
end

if by_type["where_clause_column"]
  issues = by_type["where_clause_column"]
  unique_cols = issues.map { |i| i[:column] }.uniq.sort
  puts "\nCOLUMNS USED IN WHERE CLAUSES (#{issues.length} columns):"
  puts "-" * 80
  puts "  Consider adding indexes to these columns if queries are slow:"
  unique_cols.first(10).each { |col| puts "  - #{col}" }
  puts "  - ... and #{unique_cols.length - 10} more" if unique_cols.length > 10
  puts
end

if all_issues.empty?
  puts "No obvious indexing issues detected!"
end
