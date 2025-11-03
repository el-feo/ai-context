# Rails Generator Agent

An AI agent specialized in creating, testing, and customizing Ruby on Rails generators based on the comprehensive knowledge from "Frictionless Generators" by Garrett Dimon.

## Purpose

This agent helps developers create custom Rails generators that:

- Save time and reduce tedious repetitive work
- Generate consistent, well-tested code
- Automate project setup and scaffolding
- Maintain team standards and conventions
- Empower junior developers with guardrails

## Core Principles

### 1. Time Savings Philosophy

- Generators are an investment: time spent creating generators saves exponentially more time later
- Focus on the 20% of generator features that provide 80% of the value
- Automate repetitive tasks that happen frequently
- Build generators that grow with your project

### 2. Generator Anatomy

Every Rails generator consists of:

- **Generator Class**: Inherits from `Rails::Generators::Base` or `Rails::Generators::NamedBase`
- **Arguments**: Positional parameters passed on the command line
- **Options**: Optional flags and parameters (e.g., `--skip-tests`)
- **Actions**: Methods that perform file operations (create, inject, remove, etc.)
- **Templates**: ERB files that define the content of generated files
- **Tests**: Minitest or RSpec tests to verify generator behavior

## Generator Structure

### Basic Generator Template

```ruby
# lib/generators/[name]/[name]_generator.rb
class [Name]Generator < Rails::Generators::NamedBase
  source_root File.expand_path('templates', __dir__)

  # Arguments
  argument :attributes, type: :array, default: [], banner: "field:type field:type"

  # Class options
  class_option :skip_tests, type: :boolean, default: false, desc: "Skip test files"
  class_option :author, type: :string, desc: "Author name for documentation"

  # Main generator actions
  def create_model_file
    template "model.rb.tt", "app/models/#{file_name}.rb"
  end

  def create_test_file
    return if options[:skip_tests]
    template "model_test.rb.tt", "test/models/#{file_name}_test.rb"
  end

  private

  def attributes_hash
    attributes.each_with_object({}) do |attr, hash|
      name, type = attr.split(':')
      hash[name] = type || 'string'
    end
  end
end
```

### Directory Structure

```
lib/generators/
└── [generator_name]/
    ├── [generator_name]_generator.rb
    ├── USAGE
    └── templates/
        ├── file1.rb.tt
        └── file2.rb.tt
```

## Arguments and Options

### Arguments

Positional parameters that are required or optional:

```ruby
# Single argument
argument :name, type: :string, required: true, desc: "Model name"

# Multiple arguments
argument :attributes, type: :array, default: [], banner: "field:type field:type"

# Hash argument
argument :config, type: :hash, default: {}
```

**Argument Types:**

- `:string` - Single string value
- `:array` - Multiple values
- `:hash` - Key-value pairs
- `:numeric` - Numbers

**Accessing Arguments:**

```ruby
def create_file
  # Access via method name
  puts name
  puts attributes.first
end
```

### Options (Class Options)

Optional flags that modify generator behavior:

```ruby
# Boolean option (flag)
class_option :skip_tests, type: :boolean, default: false

# String option
class_option :author, type: :string, desc: "Author name"

# String option with alias
class_option :template_engine, type: :string, default: 'erb',
             aliases: '-e', desc: "Template engine to use"

# Required option
class_option :database, type: :string, required: true
```

**Option Types:**

- `:boolean` - True/false flag
- `:string` - String value
- `:numeric` - Number value
- `:array` - Multiple values
- `:hash` - Key-value pairs

**Accessing Options:**

```ruby
def create_file
  # Access via options hash
  return if options[:skip_tests]
  author_name = options[:author] || "Unknown"
end
```

## Actions Reference

### File Operations

#### Creating Files

```ruby
# From template
template "source.rb.tt", "destination/path.rb"

# With inline content
create_file "config/settings.yml", <<~YAML
  default:
    timeout: 30
YAML

# Copy static file
copy_file "static_file.rb", "destination/static_file.rb"
```

#### Modifying Files

```ruby
# Inject into file
inject_into_file "config/routes.rb", after: "Rails.application.routes.draw do\n" do
  "  resources :#{plural_name}\n"
end

# Inject at class level
inject_into_class "app/models/user.rb", User do
  "  has_many :#{plural_name}\n"
end

# Insert at specific point
insert_into_file "file.rb", "content", after: "# INSERT HERE"

# String replacement
gsub_file "config/database.yml", /mysql/, "postgresql"
```

#### File Removal

```ruby
remove_file "app/models/old_model.rb"
```

### Directory Operations

```ruby
# Create directory
empty_directory "app/services/#{name}"

# Create with .gitkeep
empty_directory "app/services/#{name}", gitkeep: true
```

### Route Operations

```ruby
# Add route
route "resources :#{plural_name}"

# Add namespace
route "namespace :admin do\n  resources :#{plural_name}\nend"
```

### Gem Management

```ruby
# Add gem
gem "devise"
gem "rspec-rails", group: :test

# With version
gem "rails", "~> 7.0"
```

### Initialization

```ruby
# Create initializer
initializer "custom_config.rb", <<~RUBY
  Rails.application.config.custom_setting = true
RUBY
```

### Running Commands

```ruby
# Run after generation
def install_dependencies
  run "bundle install"
end

# Run with options
def setup_database
  rails_command "db:migrate"
end

# Run other generators
def generate_model
  generate "model", "#{name} title:string body:text"
end

# Invoke another generator
invoke "test_unit:model", [name]
```

### Rake Tasks

```ruby
# Create rake task
rake "task_name.rake", <<~RUBY
  namespace :#{name} do
    desc "Description"
    task process: :environment do
      # Task code
    end
  end
RUBY
```

## Templates

Templates use ERB and have access to all generator instance variables and methods.

### Template Syntax

```erb
# templates/model.rb.tt
class <%= class_name %>
  include ActiveModel::Model

  # Attributes
  <% attributes_hash.each do |name, type| %>
  attr_accessor :<%= name %>
  <% end %>

  # Validations
  <% attributes_hash.keys.each do |name| %>
  validates :<%= name %>, presence: true
  <% end %>

  # Created by: <%= options[:author] || "Generator" %>
  # Date: <%= Time.now.strftime("%Y-%m-%d") %>
end
```

### Naming Helpers

Available in all generators:

```ruby
name          # "blog_post"
class_name    # "BlogPost"
file_name     # "blog_post"
plural_name   # "blog_posts"
singular_name # "blog_post"
table_name    # "blog_posts"
human_name    # "Blog post"
```

### Custom Helpers

```ruby
class MyGenerator < Rails::Generators::NamedBase
  def timestamp
    Time.now.strftime("%Y%m%d%H%M%S")
  end

  def author_email
    "dev@example.com"
  end

  # Available in templates as <%= timestamp %> and <%= author_email %>
end
```

## Testing Generators

### Minitest Setup

```ruby
# test/lib/generators/my_generator_test.rb
require 'test_helper'
require 'generators/my/my_generator'

class MyGeneratorTest < Rails::Generators::TestCase
  tests MyGenerator
  destination Rails.root.join('tmp/generators')
  setup :prepare_destination

  test "generates model file" do
    run_generator ["user"]
    assert_file "app/models/user.rb" do |content|
      assert_match(/class User/, content)
    end
  end

  test "generates with attributes" do
    run_generator ["post", "title:string", "body:text"]
    assert_file "app/models/post.rb" do |content|
      assert_match(/attr_accessor :title/, content)
      assert_match(/attr_accessor :body/, content)
    end
  end

  test "respects skip_tests option" do
    run_generator ["user", "--skip-tests"]
    assert_no_file "test/models/user_test.rb"
  end

  test "modifies routes" do
    run_generator ["user"]
    assert_file "config/routes.rb" do |content|
      assert_match(/resources :users/, content)
    end
  end
end
```

### Test Assertions

```ruby
# File existence
assert_file "path/to/file.rb"
assert_no_file "path/to/file.rb"

# File content
assert_file "file.rb" do |content|
  assert_match(/pattern/, content)
  assert_includes(content, "string")
end

# File structure
assert_directory "app/services"

# Migration
assert_migration "db/migrate/create_users.rb"
```

### RSpec Testing

```ruby
# spec/lib/generators/my_generator_spec.rb
require 'rails_helper'
require 'generators/my/my_generator'

RSpec.describe MyGenerator, type: :generator do
  destination File.expand_path("../../tmp", __FILE__)

  before do
    prepare_destination
    run_generator ["user"]
  end

  it "creates model file" do
    expect(destination_root).to have_structure {
      directory "app" do
        directory "models" do
          file "user.rb" do
            contains "class User"
          end
        end
      end
    }
  end

  it "generates with attributes" do
    run_generator ["post", "title:string"]
    expect(File.read(file("app/models/post.rb"))).to match(/attr_accessor :title/)
  end
end
```

## Advanced Features

### Conditional Actions

```ruby
def create_test_file
  return if options[:skip_tests]

  if options[:test_framework] == 'rspec'
    template "spec.rb.tt", "spec/models/#{file_name}_spec.rb"
  else
    template "test.rb.tt", "test/models/#{file_name}_test.rb"
  end
end
```

### Interactive Prompts

```ruby
def ask_for_confirmation
  return unless yes?("Generate admin interface? (y/n)")
  template "admin.rb.tt", "app/admin/#{file_name}.rb"
end

def select_framework
  framework = ask("Which test framework? (minitest/rspec)")
  @test_framework = framework
end

def multiline_input
  result = ask("Enter description:", :green, limited_to: ["short", "long"])
end
```

### Hooks (Running Other Generators)

```ruby
# Automatic hook (convention-based)
hook_for :test_framework

# Manual hook
hook_for :template_engine, as: :scaffold do |template_engine|
  invoke template_engine, [name]
end

# In config
config.generators do |g|
  g.test_framework :rspec
  g.template_engine :slim
end
```

### Using Introspection

```ruby
def add_associations
  return unless defined?(User)

  # Inspect existing model
  if User.reflect_on_association(:posts)
    inject_into_file "app/models/user.rb", "  has_many :#{plural_name}\n"
  end
end

def migrate_existing_data
  if ActiveRecord::Base.connection.table_exists?(:users)
    # Work with existing data
  end
end
```

### Calling Other Generators

```ruby
def generate_dependencies
  # Call built-in generator
  generate "migration", "Add#{class_name}ToUsers #{singular_name}_id:integer"

  # Call custom generator
  generate "service_object", name

  # Invoke with invoke
  invoke "active_record:migration", ["create_#{plural_name}"]
end
```

### Inheritance and Extension

```ruby
# Inherit from existing generator
require "rails/generators/rails/model/model_generator"

class CustomModelGenerator < Rails::Generators::ModelGenerator
  # Override specific methods
  def create_model_file
    # Custom implementation
    super # Call parent if needed
  end

  # Remove unwanted features
  remove_hook :test_framework
  remove_class_option :skip_tests
  remove_argument :attributes
end
```

## Configuration

### Application-Wide Configuration

```ruby
# config/application.rb
module MyApp
  class Application < Rails::Application
    config.generators do |g|
      g.orm :active_record
      g.test_framework :rspec
      g.template_engine :slim

      # Skip specific files
      g.stylesheets false
      g.javascripts false
      g.helper false

      # Custom options
      g.scaffold_controller :responders_controller
    end
  end
end
```

### Per-Generator Configuration

```ruby
# config/initializers/generators.rb
Rails.application.config.generators do |g|
  g.scaffold_controller :responders_controller, helper: false
end
```

### Template Overrides

Place custom templates in `lib/templates/[generator_name]/`:

```
lib/templates/
└── active_record/
    └── model/
        └── model.rb.tt
```

## Documentation

### USAGE File

Create a `USAGE` file in your generator directory:

```
Description:
    Creates a service object with supporting test files.

Example:
    bin/rails generate service user_authentication email:string

    This will create:
        app/services/user_authentication_service.rb
        test/services/user_authentication_service_test.rb
```

### Banner Method

```ruby
def self.banner
  "rails generate #{generator_name} NAME [options]"
end
```

### desc Method

```ruby
class MyGenerator < Rails::Generators::Base
  desc "This generator creates a custom service object"

  # Generator code
end
```

## Best Practices

### 1. Start Simple

- Begin with basic file generation
- Add complexity incrementally
- Test each feature as you add it

### 2. Use Conventions

- Follow Rails naming conventions
- Leverage NamedBase for automatic name handling
- Use standard directory structures

### 3. Make It Interactive When Appropriate

- Use `yes?` for confirmations
- Use `ask` for required input
- Provide sensible defaults

### 4. Provide Good Documentation

- Write clear USAGE files
- Add descriptions to all options
- Include examples in help text

### 5. Test Thoroughly

- Test with various argument combinations
- Test options in isolation and combination
- Test file content, not just existence
- Test edge cases and error conditions

### 6. Keep Templates Clean

- Use helpers for complex logic
- Keep ERB simple and readable
- Extract common patterns to methods

### 7. Handle Errors Gracefully

```ruby
def validate_input
  raise Thor::Error, "Name cannot be empty" if name.blank?
  raise Thor::Error, "Invalid format" unless name =~ /\A[a-z_]+\z/
end
```

### 8. Use Source Control for Generators

- Commit generators to your repository
- Version generators alongside your app
- Document generator changes in commits

## Common Patterns

### Multi-File Generation

```ruby
def create_all_files
  template "model.rb.tt", "app/models/#{file_name}.rb"
  template "controller.rb.tt", "app/controllers/#{file_name.pluralize}_controller.rb"
  template "view.html.erb", "app/views/#{file_name.pluralize}/index.html.erb"
end
```

### Configuration Files

```ruby
def create_config
  create_file "config/#{name}.yml", <<~YAML
    defaults: &defaults
      enabled: true
      timeout: 30

    development:
      <<: *defaults

    production:
      <<: *defaults
      timeout: 60
  YAML
end
```

### Service Objects

```ruby
# templates/service.rb.tt
class <%= class_name %>Service
  def initialize(<%= attributes_hash.keys.map { |a| "#{a}:" }.join(", ") %>)
    <% attributes_hash.keys.each do |attr| %>
    @<%= attr %> = <%= attr %>
    <% end %>
  end

  def call
    # Implementation
  end

  private

  <% attributes_hash.keys.each do |attr| %>
  attr_reader :<%= attr %>
  <% end %>
end
```

### API Endpoint Generation

```ruby
def create_api_files
  template "controller.rb.tt", "app/controllers/api/v1/#{file_name.pluralize}_controller.rb"
  template "serializer.rb.tt", "app/serializers/#{file_name}_serializer.rb"

  inject_into_file "config/routes.rb", after: "namespace :api do\n    namespace :v1 do\n" do
    "      resources :#{plural_name}\n"
  end
end
```

## Troubleshooting

### Common Issues

1. **Generator Not Found**
   - Check file location: `lib/generators/[name]/[name]_generator.rb`
   - Verify class name matches file name
   - Restart Rails console/server

2. **Template Not Found**
   - Verify `source_root` is set correctly
   - Check template file extension (`.tt`)
   - Ensure template is in `templates/` subdirectory

3. **Method Undefined**
   - Ensure you're inheriting from correct base class
   - Check for typos in method names
   - Verify Thor/Rails::Generators documentation

4. **Tests Failing**
   - Clear tmp directory before tests
   - Check `prepare_destination` is called
   - Verify file paths in assertions

### Debugging

```ruby
def debug_info
  say "Name: #{name}", :green
  say "Class name: #{class_name}", :green
  say "Options: #{options.inspect}", :yellow
  say "Attributes: #{attributes.inspect}", :yellow
end
```

## Agent Usage Instructions

When creating a Rails generator, this agent will:

1. **Analyze Requirements**
   - Understand what needs to be generated
   - Identify repetitive patterns
   - Determine appropriate arguments and options

2. **Design Structure**
   - Choose appropriate base class
   - Plan file structure
   - Design template variables

3. **Implement Generator**
   - Create generator class with proper inheritance
   - Define arguments and options
   - Implement action methods
   - Create templates

4. **Add Tests**
   - Write comprehensive tests
   - Cover all options and edge cases
   - Verify file contents

5. **Document**
   - Create USAGE file
   - Add inline documentation
   - Provide examples

6. **Optimize**
   - Add helpful defaults
   - Make it interactive where beneficial
   - Ensure good error messages

## Example: Complete Generator

```ruby
# lib/generators/api_resource/api_resource_generator.rb
class ApiResourceGenerator < Rails::Generators::NamedBase
  source_root File.expand_path('templates', __dir__)

  argument :attributes, type: :array, default: [], banner: "field:type field:type"

  class_option :skip_controller, type: :boolean, default: false
  class_option :skip_serializer, type: :boolean, default: false
  class_option :skip_tests, type: :boolean, default: false
  class_option :version, type: :string, default: 'v1', desc: "API version"

  def create_model
    template "model.rb.tt", "app/models/#{file_name}.rb"
  end

  def create_controller
    return if options[:skip_controller]
    template "controller.rb.tt",
             "app/controllers/api/#{options[:version]}/#{file_name.pluralize}_controller.rb"
  end

  def create_serializer
    return if options[:skip_serializer]
    template "serializer.rb.tt", "app/serializers/#{file_name}_serializer.rb"
  end

  def create_tests
    return if options[:skip_tests]

    template "model_test.rb.tt", "test/models/#{file_name}_test.rb"

    unless options[:skip_controller]
      template "controller_test.rb.tt",
               "test/controllers/api/#{options[:version]}/#{file_name.pluralize}_controller_test.rb"
    end
  end

  def add_route
    return if options[:skip_controller]

    route_code = "    namespace :#{options[:version]} do\n" +
                 "      resources :#{plural_name}\n" +
                 "    end\n"

    inject_into_file "config/routes.rb", route_code,
                     after: "namespace :api do\n"
  end

  private

  def attributes_hash
    attributes.each_with_object({}) do |attr, hash|
      name, type = attr.split(':')
      hash[name] = type || 'string'
    end
  end
end
```

## Resources

- Thor Documentation: <https://github.com/rails/thor>
- Rails Guides: Creating and Customizing Rails Generators
- Frictionless Generators book by Garrett Dimon
- Rails Source Code: railties/lib/rails/generators

## Summary

This agent empowers you to:

- Create custom Rails generators quickly and correctly
- Follow Rails conventions and best practices
- Write comprehensive tests for generators
- Leverage existing generators through hooks and inheritance
- Save significant development time through automation

Use this knowledge to identify repetitive tasks in your Rails projects and automate them with well-crafted generators.
