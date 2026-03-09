#!/usr/bin/env ruby
# frozen_string_literal: true

# Sandi Metz Code Review Agent
# Based on principles from:
# - Practical Object-Oriented Design in Ruby (POODR)
# - 99 Bottles of OOP
#
# This agent reviews Ruby code using Sandi Metz's design philosophy

require 'json'
require 'ripper'

class SandiMetzCodeReviewer
  SANDI_METZ_RULES = {
    max_lines_per_class: 100,
    max_lines_per_method: 5,
    max_parameters: 4,
    max_instance_variables: 4
  }.freeze

  CODE_SMELLS = [
    :long_method,
    :large_class,
    :long_parameter_list,
    :data_clump,
    :feature_envy,
    :primitive_obsession,
    :shotgun_surgery,
    :divergent_change,
    :temporary_field,
    :message_chains,
    :middle_man,
    :inappropriate_intimacy,
    :refused_bequest,
    :comments,
    :duplicated_code,
    :conditional_complexity,
    :speculative_generality,
    :incomplete_library_class
  ].freeze

  attr_reader :feedback, :code, :file_path

  def initialize(code_or_file_path)
    if File.exist?(code_or_file_path)
      @file_path = code_or_file_path
      @code = File.read(code_or_file_path)
    else
      @code = code_or_file_path
      @file_path = nil
    end

    @feedback = []
    @parser = CodeParser.new(@code)
  end

  def review
    puts "\n" + "=" * 80
    puts "🔍 SANDI METZ CODE REVIEW"
    puts "=" * 80
    puts "\nFile: #{file_path || 'inline code'}"
    puts "\n"

    check_sandi_metz_rules
    check_single_responsibility
    check_dependencies
    check_interface_design
    check_code_smells
    check_naming
    check_test_quality if code.include?('describe') || code.include?('test')

    display_summary

    feedback
  end

  private

  def check_sandi_metz_rules
    add_section("📏 Sandi Metz Rules")

    classes = @parser.classes

    classes.each do |klass|
      # Rule 1: Classes can be no longer than 100 lines
      if klass[:lines] > SANDI_METZ_RULES[:max_lines_per_class]
        add_issue(
          :warning,
          "Class '#{klass[:name]}' has #{klass[:lines]} lines (max: #{SANDI_METZ_RULES[:max_lines_per_class]})",
          "Classes should do the smallest possible useful thing. Consider extracting responsibilities into separate classes.",
          klass[:line_number]
        )
      else
        add_pass("✓ Class '#{klass[:name]}' size is good (#{klass[:lines]} lines)")
      end

      # Rule 4: Classes can have no more than 4 instance variables
      if klass[:instance_variables] > SANDI_METZ_RULES[:max_instance_variables]
        add_issue(
          :warning,
          "Class '#{klass[:name]}' has #{klass[:instance_variables]} instance variables (max: #{SANDI_METZ_RULES[:max_instance_variables]})",
          "Too many instance variables suggests the class has too many responsibilities. Consider extracting a collaborator.",
          klass[:line_number]
        )
      end
    end

    methods = @parser.methods

    methods.each do |method|
      # Rule 2: Methods can be no longer than 5 lines
      if method[:lines] > SANDI_METZ_RULES[:max_lines_per_method]
        add_issue(
          :warning,
          "Method '#{method[:name]}' has #{method[:lines]} lines (max: #{SANDI_METZ_RULES[:max_lines_per_method]})",
          "Long methods do too much. Extract smaller methods with intention-revealing names.",
          method[:line_number]
        )
      end

      # Rule 3: Methods can have no more than 4 parameters
      if method[:parameters] > SANDI_METZ_RULES[:max_parameters]
        add_issue(
          :warning,
          "Method '#{method[:name]}' has #{method[:parameters]} parameters (max: #{SANDI_METZ_RULES[:max_parameters]})",
          "Long parameter lists are hard to understand. Consider introducing a parameter object or hash.",
          method[:line_number]
        )
      end
    end
  end

  def check_single_responsibility
    add_section("🎯 Single Responsibility Principle")

    classes = @parser.classes

    classes.each do |klass|
      # Check for classes with many public methods (Feature Envy indicator)
      public_methods = klass[:methods].select { |m| m[:visibility] == :public }

      if public_methods.length > 7
        add_issue(
          :info,
          "Class '#{klass[:name]}' has #{public_methods.length} public methods",
          "Ask: Can this class be described with a single sentence? If not, it may have multiple responsibilities.",
          klass[:line_number]
        )
      end

      # Check for methods that don't use instance variables (Feature Envy)
      klass[:methods].each do |method|
        if method[:uses_no_ivars] && method[:lines] > 3
          add_issue(
            :info,
            "Method '#{klass[:name]}##{method[:name]}' doesn't use instance variables",
            "Methods that don't use instance state might belong elsewhere (Feature Envy).",
            method[:line_number]
          )
        end
      end
    end
  end

  def check_dependencies
    add_section("🔗 Managing Dependencies")

    # Check for dependency injection opportunities
    if code =~ /\.new\s*\(/
      add_issue(
        :info,
        "Found explicit class instantiation with .new",
        "Consider dependency injection for better testability. Depend on abstractions, not concretions.",
        nil
      )
    end

    # Check for Law of Demeter violations (message chains)
    if code =~ /\w+\.\w+\.\w+\./
      add_issue(
        :warning,
        "Potential Law of Demeter violation (message chain)",
        "Message chains (a.b.c.d) create dependencies. Use delegation or 'tell, don't ask'.",
        nil
      )
    end

    # Check for accessing instance variables of other objects
    if code =~ /@\w+\s*=\s*\w+\.instance_variable_get/
      add_issue(
        :error,
        "Accessing instance variables of other objects",
        "This creates tight coupling. Objects should manage their own data. Use methods instead.",
        nil
      )
    end

    # Check for depending on distant attributes
    methods = @parser.methods
    methods.each do |method|
      if method[:body] =~ /\.\w+\.\w+/
        add_issue(
          :info,
          "Method '#{method[:name]}' may violate Law of Demeter",
          "Consider: Does this object really need to know about the structure of other objects?",
          method[:line_number]
        )
      end
    end
  end

  def check_interface_design
    add_section("💬 Interface Design")

    classes = @parser.classes

    classes.each do |klass|
      public_methods = klass[:methods].select { |m| m[:visibility] == :public }
      private_methods = klass[:methods].select { |m| m[:visibility] == :private }

      # Check for private methods doing the real work
      if private_methods.length > public_methods.length * 2
        add_issue(
          :info,
          "Class '#{klass[:name]}' has many private methods (#{private_methods.length}) vs public (#{public_methods.length})",
          "This might indicate the class is doing too much. Consider extracting collaborators.",
          klass[:line_number]
        )
      end

      # Check for query methods (no side effects)
      public_methods.each do |method|
        if method[:name].end_with?('?') && method[:body] =~ /@\w+\s*=/
          add_issue(
            :warning,
            "Query method '#{method[:name]}' appears to have side effects",
            "Query methods should not change state. Separate commands from queries.",
            method[:line_number]
          )
        end
      end
    end

    # Check for tell don't ask violations
    if code =~ /if\s+\w+\.\w+\?/
      add_issue(
        :info,
        "Conditional based on object state query",
        "Consider 'Tell, Don't Ask': Let objects make their own decisions rather than querying state.",
        nil
      )
    end
  end

  def check_code_smells
    add_section("👃 Code Smells")

    # Primitive Obsession
    if code =~ /def \w+\([^)]*String[^)]*String[^)]*String/
      add_issue(
        :warning,
        "Primitive Obsession: Multiple string parameters",
        "Consider creating a value object to wrap related data.",
        nil
      )
    end

    # Data Clump
    methods = @parser.methods
    param_groups = methods.map { |m| m[:param_names] }.select { |p| p.length >= 3 }
    if param_groups.uniq.length < param_groups.length
      add_issue(
        :warning,
        "Data Clump: Same parameters appear together repeatedly",
        "These parameters might belong together in a class. Consider extracting a parameter object.",
        nil
      )
    end

    # Conditional Complexity
    if code =~ /if.*elsif.*elsif.*elsif/
      add_issue(
        :warning,
        "Complex conditionals detected",
        "Replace conditionals with polymorphism. Each type should know its own behavior.",
        nil
      )
    end

    # Case statements (candidate for polymorphism)
    if code =~ /case\s+\w+.*when.*when.*when/m
      add_issue(
        :info,
        "Case statement found",
        "Consider replacing with polymorphism for better Open/Closed compliance (see 99 Bottles pattern).",
        nil
      )
    end

    # Duplicated Code
    check_duplication

    # Speculative Generality
    if code =~ /module\s+\w+/ && code !~ /include\s+\w+/
      add_issue(
        :info,
        "Module defined but not used",
        "YAGNI: Don't add complexity until you need it. Wait for duplication before abstracting.",
        nil
      )
    end

    # Comments explaining what code does (vs why)
    code.scan(/^\s*#\s*(.+)$/).each do |comment|
      comment_text = comment[0]
      if comment_text =~ /^(loop|iterate|set|get|return|calculate)/i
        add_issue(
          :info,
          "Comment explaining implementation: '#{comment_text[0..50]}'",
          "Comments that explain 'what' suggest code isn't clear. Refactor for self-documenting code.",
          nil
        )
      end
    end
  end

  def check_duplication
    lines = code.split("\n").map(&:strip).reject { |l| l.empty? || l.start_with?('#') }

    # Simple duplication check
    duplicates = lines.select { |line| lines.count(line) > 1 && line.length > 20 }

    if duplicates.any?
      add_issue(
        :warning,
        "Potential code duplication detected",
        "DRY: Don't Repeat Yourself. But wait for the right abstraction - wrong abstractions are worse than duplication.",
        nil
      )
    end
  end

  def check_naming
    add_section("📝 Naming & Communication")

    methods = @parser.methods

    methods.each do |method|
      name = method[:name]

      # Check for vague names
      if name =~ /^(data|info|object|thing|stuff|temp|do|process|handle|manage)$/i
        add_issue(
          :warning,
          "Vague method name: '#{name}'",
          "Names should reveal intent. What does this method really do?",
          method[:line_number]
        )
      end

      # Check for 'and' in method names (doing two things)
      if name.include?('_and_')
        add_issue(
          :warning,
          "Method '#{name}' uses 'and' - may do two things",
          "Methods should do one thing. Consider splitting into separate methods.",
          method[:line_number]
        )
      end

      # Check for boolean parameters (flag arguments)
      if method[:param_names].any? { |p| p =~ /^(is|has|should|can|do)_/ }
        add_issue(
          :warning,
          "Method '#{name}' has boolean flag parameter",
          "Flag arguments indicate the method does different things. Consider splitting into separate methods.",
          method[:line_number]
        )
      end
    end

    # Check class names
    classes = @parser.classes
    classes.each do |klass|
      name = klass[:name]

      if name =~ /(Manager|Handler|Processor|Controller|Helper|Util)/
        add_issue(
          :info,
          "Generic class name: '#{name}'",
          "Names like Manager/Handler are vague. What does this class really do?",
          klass[:line_number]
        )
      end
    end
  end

  def check_test_quality
    add_section("🧪 Test Quality")

    if code.include?('let(')
      add_pass("✓ Using let for test setup (good for DRY tests)")
    end

    if code =~ /it\s+["'].*should.*and.*["']/
      add_issue(
        :warning,
        "Test description includes 'and' - testing multiple things",
        "Each test should verify one behavior. Split into separate tests.",
        nil
      )
    end

    if code.include?('allow_any_instance_of')
      add_issue(
        :warning,
        "Using allow_any_instance_of in tests",
        "This is a sign of poor design. Consider injecting dependencies instead.",
        nil
      )
    end
  end

  def display_summary
    errors = feedback.count { |f| f[:level] == :error }
    warnings = feedback.count { |f| f[:level] == :warning }
    infos = feedback.count { |f| f[:level] == :info }
    passes = feedback.count { |f| f[:level] == :pass }

    puts "\n" + "=" * 80
    puts "📊 SUMMARY"
    puts "=" * 80
    puts "✓ Passes: #{passes}"
    puts "ℹ️  Info: #{infos}"
    puts "⚠️  Warnings: #{warnings}"
    puts "❌ Errors: #{errors}"
    puts "\n"

    if errors.zero? && warnings.zero?
      puts "🌟 Excellent! This code follows Sandi Metz's principles well."
    elsif errors.zero? && warnings < 3
      puts "👍 Good work! A few minor improvements suggested."
    else
      puts "💡 There's room for improvement. Remember:"
      puts "   - Start with Shameless Green (working, simple code)"
      puts "   - Wait for duplication before abstracting"
      puts "   - Make the change easy, then make the easy change"
      puts "   - Trust the process of small refactorings"
    end

    puts "\n📚 Key Principles:"
    puts "   • Single Responsibility: Classes and methods do one thing"
    puts "   • Depend on behavior, not data"
    puts "   • Message-centric design: Tell, don't ask"
    puts "   • Open/Closed: Open for extension, closed for modification"
    puts "   • Liskov Substitution: Subtypes should be substitutable"
    puts "   • Law of Demeter: Only talk to immediate neighbors"
    puts "\n"
  end

  def add_section(title)
    puts "\n#{title}"
    puts "-" * 80
    @current_section = title
  end

  def add_issue(level, message, suggestion, line_number = nil)
    icon = case level
           when :error then "❌"
           when :warning then "⚠️ "
           when :info then "ℹ️ "
           else "•"
           end

    location = line_number ? " (line #{line_number})" : ""
    puts "#{icon} #{message}#{location}"
    puts "   💡 #{suggestion}" if suggestion
    puts

    feedback << {
      level: level,
      message: message,
      suggestion: suggestion,
      line: line_number,
      section: @current_section
    }
  end

  def add_pass(message)
    puts "  #{message}"
    feedback << {
      level: :pass,
      message: message,
      section: @current_section
    }
  end
end

# Simple parser to extract code structure
class CodeParser
  attr_reader :code

  def initialize(code)
    @code = code
    @lines = code.split("\n")
  end

  def classes
    classes = []
    current_class = nil

    @lines.each_with_index do |line, idx|
      if line =~ /^\s*class\s+(\w+)/
        current_class = {
          name: $1,
          line_number: idx + 1,
          lines: 0,
          instance_variables: 0,
          methods: []
        }
        classes << current_class
      elsif line =~ /^\s*end\s*$/ && current_class
        current_class = nil
      elsif current_class
        current_class[:lines] += 1
        current_class[:instance_variables] += 1 if line =~ /@\w+\s*=/
      end
    end

    classes.each do |klass|
      klass[:methods] = methods.select { |m| m[:class] == klass[:name] }
    end

    classes
  end

  def methods
    methods = []
    current_method = nil
    current_class = nil
    visibility = :public
    in_method = false

    @lines.each_with_index do |line, idx|
      # Track current class
      if line =~ /^\s*class\s+(\w+)/
        current_class = $1
        visibility = :public
      end

      # Track visibility
      if line =~ /^\s*(private|protected|public)\s*$/
        visibility = $1.to_sym
      end

      # Method definition
      if line =~ /^\s*def\s+(\w+)(\(([^)]*)\))?/
        method_name = $1
        params = $3 || ""
        param_list = params.split(',').map(&:strip).reject(&:empty?)

        current_method = {
          name: method_name,
          class: current_class,
          line_number: idx + 1,
          lines: 0,
          parameters: param_list.length,
          param_names: param_list.map { |p| p.split(/[=:]/).first.strip },
          visibility: visibility,
          body: "",
          uses_no_ivars: true
        }
        in_method = true
        methods << current_method
      elsif line =~ /^\s*end\s*$/ && in_method
        in_method = false
        if current_method
          current_method[:uses_no_ivars] = !current_method[:body].include?('@')
        end
        current_method = nil
      elsif current_method && in_method
        current_method[:lines] += 1 unless line.strip.empty?
        current_method[:body] += line + "\n"
      end
    end

    methods
  end
end

# CLI Interface
if __FILE__ == $PROGRAM_NAME
  if ARGV.empty?
    puts "Usage: ruby sandi_metz_code_reviewer.rb <file_or_code>"
    puts "\nExample:"
    puts "  ruby sandi_metz_code_reviewer.rb my_class.rb"
    exit 1
  end

  reviewer = SandiMetzCodeReviewer.new(ARGV[0])
  reviewer.review
end
