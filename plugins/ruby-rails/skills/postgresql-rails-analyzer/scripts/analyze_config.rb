#!/usr/bin/env ruby
# frozen_string_literal: true

# Analyze database.yml and suggest PostgreSQL configuration improvements.
# Checks connection pool settings, timeouts, and common performance parameters.

require "yaml"

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

def load_database_config(config_file)
  content = File.read(config_file)
  # Strip ERB tags for basic parsing
  content = content.gsub(/<%=.*?%>/, '""').gsub(/<%.*?%>/, "")
  YAML.safe_load(content, permitted_classes: [Symbol])
end

def analyze_connection_pool(env_config, env_name)
  issues = []
  pool_size = env_config["pool"]

  if pool_size.nil?
    issues << {
      environment: env_name, setting: "pool", severity: "warning",
      message: "Connection pool size not explicitly set (defaults to 5)",
      recommendation: "Set pool size based on your application threads/workers. For Puma with 5 threads: pool: 5"
    }
  elsif pool_size.is_a?(Integer)
    if pool_size < 5
      issues << {
        environment: env_name, setting: "pool", severity: "warning",
        message: "Connection pool size (#{pool_size}) is quite small",
        recommendation: "Consider increasing pool size to match your web server threads/workers"
      }
    elsif pool_size > 20
      issues << {
        environment: env_name, setting: "pool", severity: "info",
        message: "Connection pool size (#{pool_size}) is quite large",
        recommendation: "Verify this matches your actual concurrency needs. Too many connections can strain PostgreSQL"
      }
    end
  end

  issues
end

def analyze_timeouts(env_config, env_name)
  issues = []
  variables = env_config.fetch("variables", {}) || {}

  unless variables.key?("statement_timeout")
    issues << {
      environment: env_name, setting: "statement_timeout", severity: "warning",
      message: "statement_timeout not configured",
      recommendation: "Add to database.yml:\n  variables:\n    statement_timeout: 30000  # 30 seconds in milliseconds"
    }
  end

  unless env_config.key?("connect_timeout")
    issues << {
      environment: env_name, setting: "connect_timeout", severity: "info",
      message: "connect_timeout not configured",
      recommendation: "Add connect_timeout: 5 to prevent hanging on database connection issues"
    }
  end

  unless env_config.key?("checkout_timeout")
    issues << {
      environment: env_name, setting: "checkout_timeout", severity: "info",
      message: "checkout_timeout not configured (defaults to 5 seconds)",
      recommendation: "Explicitly set checkout_timeout: 5 for clarity"
    }
  end

  issues
end

def analyze_prepared_statements(env_config, env_name)
  issues = []
  prepared = env_config["prepared_statements"]

  if prepared == false
    issues << {
      environment: env_name, setting: "prepared_statements", severity: "info",
      message: "Prepared statements are disabled",
      recommendation: "Prepared statements improve performance. Only disable if using PgBouncer in transaction mode"
    }
  elsif prepared.nil? && env_name == "production"
    issues << {
      environment: env_name, setting: "prepared_statements", severity: "info",
      message: "Prepared statements setting not explicit",
      recommendation: "Add prepared_statements: true for better query performance (enabled by default)"
    }
  end

  issues
end

def analyze_reaping_frequency(env_config, env_name)
  return [] unless env_name == "production" && !env_config.key?("reaping_frequency")

  [{
    environment: env_name, setting: "reaping_frequency", severity: "info",
    message: "reaping_frequency not configured",
    recommendation: "Consider adding reaping_frequency: 60 to clean up stale connections (seconds)"
  }]
end

def check_ssl_configuration(env_config, env_name)
  return [] unless env_name == "production"

  sslmode = env_config["sslmode"]
  return [] if sslmode && sslmode != "disable"

  [{
    environment: env_name, setting: "sslmode", severity: "warning",
    message: "SSL/TLS not enforced for production database connections",
    recommendation: "Add sslmode: require or sslmode: verify-full for secure connections"
  }]
end

def suggest_performance_extensions(env_name)
  [{
    environment: env_name, setting: "extensions", severity: "info",
    message: "Consider enabling pg_stat_statements extension",
    recommendation: "Enable in PostgreSQL config:\n  shared_preload_libraries = 'pg_stat_statements'\nThen run: CREATE EXTENSION IF NOT EXISTS pg_stat_statements;"
  }]
end

rails_root = find_rails_root
config_file = File.join(rails_root, "config", "database.yml")

unless File.exist?(config_file)
  abort "Error: Could not find config/database.yml"
end

puts "Analyzing database configuration at: #{rails_root}"
puts "=" * 80

begin
  config = load_database_config(config_file)
rescue => e
  abort "Error parsing database.yml: #{e.message}"
end

all_issues = []

%w[development test production].each do |env_name|
  next unless config.is_a?(Hash) && config[env_name].is_a?(Hash)

  env_config = config[env_name]
  all_issues.concat(analyze_connection_pool(env_config, env_name))
  all_issues.concat(analyze_timeouts(env_config, env_name))
  all_issues.concat(analyze_prepared_statements(env_config, env_name))
  all_issues.concat(analyze_reaping_frequency(env_config, env_name))
  all_issues.concat(check_ssl_configuration(env_config, env_name))
end

all_issues.concat(suggest_performance_extensions("all"))

by_severity = all_issues.group_by { |i| i[:severity] }

puts "\nFound #{all_issues.length} configuration recommendations:\n"

%w[warning info].each do |severity|
  issues = by_severity.fetch(severity, [])
  next if issues.empty?

  puts "\n#{severity.upcase} (#{issues.length} items):"
  puts "-" * 80
  issues.each do |issue|
    env = issue[:environment] || "all"
    setting = issue[:setting] || "general"
    puts "  [#{env}] #{setting}"
    puts "  -> #{issue[:message]}"
    puts "  Recommendation: #{issue[:recommendation]}"
    puts
  end
end

if all_issues.empty?
  puts "Database configuration looks good!"
else
  puts "=" * 80
  puts "For more information, see the High Performance PostgreSQL for Rails book"
  puts "  Chapters: 2 (Administration Basics), 5 (Optimizing Active Record)"
end
