#!/usr/bin/env ruby
# frozen_string_literal: true

# Quality History Tracker
#
# Tracks coverage and quality metrics over time to identify trends.
#
# Usage:
#   ruby scripts/track_quality_history.rb

require 'json'
require 'fileutils'

class QualityHistoryTracker
  HISTORY_FILE = 'tmp/quality_history.json'
  
  def track
    history = load_history
    
    entry = {
      timestamp: Time.now.iso8601,
      coverage: current_coverage,
      avg_score: current_avg_score,
      avg_complexity: current_avg_complexity,
      git_sha: git_sha,
      git_branch: git_branch
    }
    
    history << entry
    save_history(history.last(100))
    
    puts "✅ Quality metrics tracked"
    analyze_trends(history)
  end
  
  private
  
  def current_coverage
    return 0 unless File.exist?('coverage/.resultset.json')
    
    data = JSON.parse(File.read('coverage/.resultset.json'))
    cov = data.values.first.dig('coverage', 'lines') || {}
    return 0 if cov.empty?
    
    all_lines = cov.values.flat_map(&:to_a).compact
    return 0 if all_lines.empty?
    
    total = all_lines.size
    covered = all_lines.count { |x| x && x > 0 }
    ((covered.to_f / total) * 100).round(2)
  rescue JSON::ParserError
    0
  end
  
  def current_avg_score
    return 0 unless File.exist?('tmp/rubycritic/report.json')
    
    data = JSON.parse(File.read('tmp/rubycritic/report.json'))
    modules = data['analysed_modules'] || []
    return 0 if modules.empty?
    
    (modules.sum { |m| m['score'] } / modules.size.to_f).round(2)
  rescue JSON::ParserError
    0
  end
  
  def current_avg_complexity
    return 0 unless File.exist?('tmp/rubycritic/report.json')
    
    data = JSON.parse(File.read('tmp/rubycritic/report.json'))
    modules = data['analysed_modules'] || []
    return 0 if modules.empty?
    
    (modules.sum { |m| m['complexity'] } / modules.size.to_f).round(2)
  rescue JSON::ParserError
    0
  end
  
  def git_sha
    `git rev-parse HEAD 2>/dev/null`.strip
  rescue
    'unknown'
  end
  
  def git_branch
    `git rev-parse --abbrev-ref HEAD 2>/dev/null`.strip
  rescue
    'unknown'
  end
  
  def analyze_trends(history)
    return if history.size < 2
    
    recent = history.last(10)
    
    puts "\n📊 Quality Trends (last #{recent.size} commits):"
    
    cov_trend = calculate_trend(recent.map { |e| e[:coverage] })
    puts "  Coverage: #{cov_trend}"
    
    if recent.first[:avg_score] && recent.first[:avg_score] > 0
      score_trend = calculate_trend(recent.map { |e| e[:avg_score] })
      puts "  Quality Score: #{score_trend}"
    end
    
    if recent.first[:avg_complexity] && recent.first[:avg_complexity] > 0
      complex_trend = calculate_trend(recent.map { |e| e[:avg_complexity] })
      puts "  Complexity: #{complex_trend}"
    end
  end
  
  def calculate_trend(values)
    values = values.compact
    return "insufficient data" if values.size < 2
    
    first_half = values.first(values.size / 2)
    second_half = values.last(values.size / 2)
    
    return "insufficient data" if first_half.empty? || second_half.empty?
    
    avg_first = first_half.sum / first_half.size.to_f
    avg_second = second_half.sum / second_half.size.to_f
    
    diff = avg_second - avg_first
    
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
  rescue JSON::ParserError
    []
  end
  
  def save_history(history)
    FileUtils.mkdir_p(File.dirname(HISTORY_FILE))
    File.write(HISTORY_FILE, JSON.pretty_generate(history))
  end
end

QualityHistoryTracker.new.track if __FILE__ == $0
