#!/usr/bin/env ruby
# frozen_string_literal: true

# Coverage Analyzer
#
# Analyzes SimpleCov coverage data to identify areas needing attention
# and generate actionable recommendations.
#
# Usage:
#   ruby scripts/coverage_analyzer.rb
#   ruby scripts/coverage_analyzer.rb --format json
#   ruby scripts/coverage_analyzer.rb --threshold 80

require 'json'
require 'optparse'

class CoverageAnalyzer
  COLORS = {
    red: "\e[31m",
    yellow: "\e[33m",
    green: "\e[32m",
    blue: "\e[34m",
    reset: "\e[0m"
  }.freeze

  attr_reader :options

  def initialize(options = {})
    @options = {
      threshold: 80,
      format: 'text',
      show_all: false,
      output_file: nil
    }.merge(options)

    @results_file = 'coverage/.resultset.json'
    @no_color = ENV['NO_COLOR'] == '1'
  end

  def analyze
    unless File.exist?(@results_file)
      error "Coverage results not found at #{@results_file}"
      error "Run tests with SimpleCov enabled first."
      exit 1
    end

    @data = load_coverage_data
    @analysis = perform_analysis

    case @options[:format]
    when 'json'
      output_json
    when 'markdown'
      output_markdown
    else
      output_text
    end
  end

  private

  def load_coverage_data
    raw_data = JSON.parse(File.read(@results_file), symbolize_names: true)
    
    # Get the first test suite's data
    suite_data = raw_data.values.first
    
    {
      timestamp: suite_data[:timestamp],
      coverage: suite_data[:coverage] || {},
      files: extract_file_data(suite_data[:coverage])
    }
  rescue JSON::ParserError => e
    error "Failed to parse coverage data: #{e.message}"
    exit 1
  end

  def extract_file_data(coverage_data)
    return [] unless coverage_data[:lines]

    coverage_data[:lines].map do |filename, line_coverage|
      analyze_file(filename, line_coverage)
    end.compact.sort_by { |f| f[:coverage_percent] }
  end

  def analyze_file(filename, line_coverage)
    # Skip if not a project file
    return nil unless filename.start_with?(SimpleCov.root) rescue nil

    total_lines = line_coverage.compact.size
    return nil if total_lines == 0

    covered_lines = line_coverage.compact.count { |x| x && x > 0 }
    missed_lines = find_missed_lines(line_coverage)

    {
      filename: filename.sub("#{Dir.pwd}/", ''),
      total_lines: total_lines,
      covered_lines: covered_lines,
      missed_lines: missed_lines.size,
      missed_line_numbers: missed_lines,
      coverage_percent: (covered_lines.to_f / total_lines * 100).round(2)
    }
  end

  def find_missed_lines(line_coverage)
    line_coverage.each_with_index
                 .select { |cov, _| cov == 0 }
                 .map { |_, idx| idx + 1 }
  end

  def perform_analysis
    files = @data[:files]
    total_lines = files.sum { |f| f[:total_lines] }
    covered_lines = files.sum { |f| f[:covered_lines] }
    overall_coverage = (covered_lines.to_f / total_lines * 100).round(2)

    threshold = @options[:threshold]
    files_below_threshold = files.select { |f| f[:coverage_percent] < threshold }
    
    {
      overall_coverage: overall_coverage,
      total_files: files.size,
      total_lines: total_lines,
      covered_lines: covered_lines,
      files_below_threshold: files_below_threshold,
      worst_files: files.first(10),
      best_files: files.last(10),
      coverage_distribution: calculate_distribution(files)
    }
  end

  def calculate_distribution(files)
    {
      excellent: files.count { |f| f[:coverage_percent] >= 90 },
      good: files.count { |f| f[:coverage_percent] >= 80 && f[:coverage_percent] < 90 },
      fair: files.count { |f| f[:coverage_percent] >= 60 && f[:coverage_percent] < 80 },
      poor: files.count { |f| f[:coverage_percent] < 60 }
    }
  end

  def output_text
    puts "\n" + "="*80
    puts colorize("COVERAGE ANALYSIS REPORT", :blue, bold: true)
    puts "="*80

    print_summary
    print_distribution
    print_worst_files
    print_recommendations
  end

  def print_summary
    puts "\n#{colorize('📊 Overall Coverage:', :blue, bold: true)}"
    
    coverage = @analysis[:overall_coverage]
    color = coverage >= 90 ? :green : coverage >= 80 ? :yellow : :red
    
    puts "  #{colorize(coverage.to_s + '%', color, bold: true)} " +
         "(#{@analysis[:covered_lines]}/#{@analysis[:total_lines]} lines)"
    puts "  Total Files: #{@analysis[:total_files]}"
    
    if @analysis[:files_below_threshold].any?
      puts "  #{colorize("⚠️  #{@analysis[:files_below_threshold].size} files below #{@options[:threshold]}% threshold", :yellow)}"
    end
  end

  def print_distribution
    puts "\n#{colorize('📈 Coverage Distribution:', :blue, bold: true)}"
    dist = @analysis[:coverage_distribution]
    
    puts "  #{colorize('Excellent (≥90%):', :green)} #{dist[:excellent]} files"
    puts "  #{colorize('Good (80-89%):', :yellow)} #{dist[:good]} files"
    puts "  Fair (60-79%): #{dist[:fair]} files"
    puts "  #{colorize('Poor (<60%):', :red)} #{dist[:poor]} files"
  end

  def print_worst_files
    puts "\n#{colorize('⚠️  Files Needing Attention:', :blue, bold: true)}"
    puts "#{colorize('(Showing worst 10 files)', :blue)}\n"

    @analysis[:worst_files].each_with_index do |file, idx|
      color = file[:coverage_percent] >= 60 ? :yellow : :red
      
      printf "  %2d. %s %s%% %s(%d/%d lines)%s\n",
             idx + 1,
             colorize(file[:filename], color),
             colorize(file[:coverage_percent].to_s.rjust(5), color, bold: true),
             colorize('', :reset),
             file[:covered_lines],
             file[:total_lines],
             colorize('', :reset)

      if @options[:show_all] && file[:missed_line_numbers].any?
        missed = format_missed_lines(file[:missed_line_numbers])
        puts "      Missed lines: #{missed}"
      end
    end
  end

  def format_missed_lines(line_numbers)
    # Group consecutive numbers into ranges
    ranges = []
    current_range = [line_numbers.first]

    line_numbers[1..-1].each do |num|
      if num == current_range.last + 1
        current_range << num
      else
        ranges << format_range(current_range)
        current_range = [num]
      end
    end
    ranges << format_range(current_range)

    ranges.join(', ')
  end

  def format_range(range)
    range.size == 1 ? range.first.to_s : "#{range.first}-#{range.last}"
  end

  def print_recommendations
    puts "\n#{colorize('💡 Recommendations:', :blue, bold: true)}"

    recs = generate_recommendations
    recs.each_with_index do |rec, idx|
      puts "  #{idx + 1}. #{rec}"
    end

    puts ""
  end

  def generate_recommendations
    recommendations = []
    
    if @analysis[:overall_coverage] < 80
      recommendations << "Overall coverage below 80% - focus on adding comprehensive test suite"
    end

    poor_files = @analysis[:coverage_distribution][:poor]
    if poor_files > 0
      recommendations << "#{poor_files} files with <60% coverage - prioritize these for testing"
      
      # Suggest specific files
      worst = @analysis[:worst_files].first
      if worst[:coverage_percent] < 60
        recommendations << "Start with: #{colorize(worst[:filename], :yellow)} (#{worst[:coverage_percent]}%)"
      end
    end

    fair_files = @analysis[:coverage_distribution][:fair]
    if fair_files > 5
      recommendations << "#{fair_files} files in 60-80% range - good candidates for improvement"
    end

    if @analysis[:files_below_threshold].any?
      threshold = @options[:threshold]
      recommendations << "Focus on bringing #{@analysis[:files_below_threshold].size} files above #{threshold}% threshold"
    end

    recommendations << "Review worst files and identify common patterns (error handling, edge cases, etc.)"
    recommendations << "Consider pairing with RubyCritic to prioritize complex, low-coverage files"

    recommendations
  end

  def output_json
    output = {
      timestamp: Time.now.iso8601,
      analysis: @analysis,
      recommendations: generate_recommendations
    }

    json = JSON.pretty_generate(output)

    if @options[:output_file]
      File.write(@options[:output_file], json)
      puts "Analysis written to #{@options[:output_file]}"
    else
      puts json
    end
  end

  def output_markdown
    md = []
    md << "# Coverage Analysis Report"
    md << ""
    md << "**Generated:** #{Time.now.strftime('%Y-%m-%d %H:%M:%S')}"
    md << ""
    md << "## Summary"
    md << ""
    md << "- **Overall Coverage:** #{@analysis[:overall_coverage]}%"
    md << "- **Total Files:** #{@analysis[:total_files]}"
    md << "- **Total Lines:** #{@analysis[:total_lines]}"
    md << "- **Covered Lines:** #{@analysis[:covered_lines]}"
    
    if @analysis[:files_below_threshold].any?
      md << "- ⚠️ **Files Below Threshold:** #{@analysis[:files_below_threshold].size}"
    end
    
    md << ""
    md << "## Distribution"
    md << ""
    dist = @analysis[:coverage_distribution]
    md << "| Category | Files |"
    md << "|----------|-------|"
    md << "| Excellent (≥90%) | #{dist[:excellent]} |"
    md << "| Good (80-89%) | #{dist[:good]} |"
    md << "| Fair (60-79%) | #{dist[:fair]} |"
    md << "| Poor (<60%) | #{dist[:poor]} |"
    
    md << ""
    md << "## Files Needing Attention"
    md << ""
    md << "| File | Coverage | Lines |"
    md << "|------|----------|-------|"
    
    @analysis[:worst_files].each do |file|
      md << "| `#{file[:filename]}` | #{file[:coverage_percent]}% | #{file[:covered_lines]}/#{file[:total_lines]} |"
    end
    
    md << ""
    md << "## Recommendations"
    md << ""
    generate_recommendations.each_with_index do |rec, idx|
      md << "#{idx + 1}. #{rec}"
    end

    markdown = md.join("\n")

    if @options[:output_file]
      File.write(@options[:output_file], markdown)
      puts "Analysis written to #{@options[:output_file]}"
    else
      puts markdown
    end
  end

  def colorize(text, color, bold: false)
    return text if @no_color
    
    color_code = COLORS[color] || ''
    bold_code = bold ? "\e[1m" : ''
    reset = COLORS[:reset]
    
    "#{bold_code}#{color_code}#{text}#{reset}"
  end

  def error(message)
    puts colorize("Error: #{message}", :red)
  end
end

# Parse command line options
options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: coverage_analyzer.rb [options]"

  opts.on("-t", "--threshold PERCENT", Integer, "Coverage threshold (default: 80)") do |t|
    options[:threshold] = t
  end

  opts.on("-f", "--format FORMAT", String, "Output format: text, json, markdown (default: text)") do |f|
    options[:format] = f
  end

  opts.on("-o", "--output FILE", String, "Write output to file") do |o|
    options[:output_file] = o
  end

  opts.on("-a", "--all", "Show all details including missed line numbers") do
    options[:show_all] = true
  end

  opts.on("-h", "--help", "Show this help") do
    puts opts
    exit
  end
end.parse!

# Run the analyzer
analyzer = CoverageAnalyzer.new(options)
analyzer.analyze
