# Thor::Actions Complete Reference

Thor::Actions provides file manipulation methods available in all Rails generators. This reference covers all methods with practical examples.

## File Creation

### create_file

Creates a new file with specified content.

```ruby
def create_config_file
  create_file 'config/service_config.yml', <<~YAML
    development:
      timeout: 30
      retries: 3
    production:
      timeout: 60
      retries: 5
  YAML
end
```

**With block**:
```ruby
def create_json_config
  create_file 'config/settings.json' do
    JSON.pretty_generate({
      name: class_name,
      timestamp: Time.now.iso8601
    })
  end
end
```

**Options**:
- `verbose: false` - Suppress output
- `force: true` - Overwrite existing files

### copy_file

Copies a file from source_root to destination.

```ruby
def copy_template_files
  copy_file 'readme.md', 'README.md'
  copy_file 'gitignore', '.gitignore'
end
```

**With transformation**:
```ruby
def copy_with_namespace
  copy_file 'service.rb',
    "app/services/#{options[:namespace]}/#{file_name}_service.rb"
end
```

### template

Processes ERB template and writes result.

```ruby
def create_from_template
  template 'service.rb.tt', "app/services/#{file_name}_service.rb"
end
```

**With custom context**:
```ruby
def create_with_context
  @custom_var = "value"
  @another_var = options[:setting]

  template 'config.rb.tt', 'config/settings.rb'
end
```

**Inline template**:
```ruby
def create_inline
  create_file 'app/models/concern.rb' do
    <<~RUBY
      module #{class_name}Concern
        extend ActiveSupport::Concern

        included do
          # Included logic
        end
      end
    RUBY
  end
end
```

## File Modification

### insert_into_file

Inserts content into an existing file.

```ruby
def add_to_routes
  route "resources :#{plural_name}"

  # More control with insert_into_file
  insert_into_file 'config/routes.rb',
    "  namespace :api do\n    resources :#{plural_name}\n  end\n",
    after: "Rails.application.routes.draw do\n"
end
```

**Before/After positioning**:
```ruby
def insert_middleware
  insert_into_file 'config/application.rb',
    "    config.middleware.use MyMiddleware\n",
    before: "  end\nend"
end

def insert_at_end
  insert_into_file 'app/models/user.rb',
    "\n  include #{class_name}Concern\n",
    after: "class User < ApplicationRecord\n"
end
```

**With block**:
```ruby
def add_initializer_code
  insert_into_file 'config/initializers/app.rb', after: "Rails.application.configure do\n" do
    <<~RUBY
      config.custom_setting = true
      config.another_setting = "value"
    RUBY
  end
end
```

### gsub_file

Replaces text using regular expressions.

```ruby
def update_config
  gsub_file 'config/application.rb',
    /config.load_defaults \d+\.\d+/,
    'config.load_defaults 8.0'
end
```

**With block**:
```ruby
def replace_with_logic
  gsub_file 'app/models/user.rb', /old_method_name/ do |match|
    "new_method_name_#{class_name.underscore}"
  end
end
```

### comment_lines

Comments out matching lines.

```ruby
def disable_config
  comment_lines 'config/environments/production.rb',
    /config.assets.compile = false/
end
```

### uncomment_lines

Uncomments matching lines.

```ruby
def enable_config
  uncomment_lines 'config/environments/production.rb',
    /config.cache_classes = true/
end
```

## Directory Operations

### empty_directory

Creates an empty directory.

```ruby
def create_structure
  empty_directory 'app/services'
  empty_directory "app/services/#{options[:namespace]}" if options[:namespace]
end
```

### directory

Recursively copies a directory.

```ruby
def copy_templates
  directory 'views', "app/views/#{plural_name}"
  directory 'api_templates', "app/views/api/v1/#{plural_name}"
end
```

**With exclusions**:
```ruby
def copy_selective
  directory 'templates', 'app/templates', exclude_pattern: /\.keep$/
end
```

## Rails-Specific Helpers

### route

Adds routes to `config/routes.rb`.

```ruby
def add_routes
  route "resources :#{plural_name}"

  # Nested routes
  route <<~RUBY
    namespace :api do
      namespace :v1 do
        resources :#{plural_name}
      end
    end
  RUBY

  # Custom routes
  route "get '/#{plural_name}/search', to: '#{plural_name}#search'"
end
```

### initializer

Creates an initializer file.

```ruby
def create_initializer
  initializer "#{file_name}.rb", <<~RUBY
    Rails.application.config.to_prepare do
      #{class_name}Service.configure do |config|
        config.timeout = 30
      end
    end
  RUBY
end
```

**With template**:
```ruby
def create_initializer_from_template
  initializer "#{file_name}.rb" do
    <<~RUBY
      # #{class_name} Configuration
      Rails.application.config.#{file_name} = {
        enabled: true,
        options: {}
      }
    RUBY
  end
end
```

### lib

Creates a file in `lib/`.

```ruby
def create_lib_file
  lib "#{file_name}.rb", <<~RUBY
    module #{class_name}
      def self.call
        # Implementation
      end
    end
  RUBY
end
```

### rakefile

Creates a Rake task.

```ruby
def create_rake_task
  rakefile "#{file_name}.rake", <<~RUBY
    namespace :#{file_name} do
      desc "Run #{class_name} task"
      task run: :environment do
        #{class_name}Service.new.call
      end
    end
  RUBY
end
```

### vendor

Creates a file in `vendor/`.

```ruby
def add_vendor_lib
  vendor "plugins/#{file_name}.rb", <<~RUBY
    # Vendor plugin: #{class_name}
    module Plugins
      module #{class_name}
      end
    end
  RUBY
end
```

## File System Queries

### File and Directory Checks

```ruby
def conditional_creation
  if File.exist?('spec')
    create_file 'spec/support/service_helpers.rb', helper_content
  elsif File.exist?('test')
    create_file 'test/support/service_helpers.rb', helper_content
  end
end

def check_structure
  if File.directory?('app/services')
    say "Services directory exists", :green
  else
    empty_directory 'app/services'
    say "Created services directory", :blue
  end
end
```

### find_in_source_paths

Finds files in template source paths.

```ruby
def use_template
  if find_in_source_paths('custom_template.rb.tt')
    template 'custom_template.rb.tt', destination
  else
    template 'default_template.rb.tt', destination
  end
end
```

## User Interaction

### ask

Prompts user for input.

```ruby
def interactive_setup
  namespace = ask("Enter namespace (or leave empty):")
  @namespace = namespace unless namespace.empty?

  async = ask("Enable async processing? (yes/no)", limited_to: ['yes', 'no'])
  @async = async == 'yes'
end
```

### yes?

Boolean prompt.

```ruby
def optional_features
  if yes?("Include background job?")
    invoke 'job', ["#{name}_job"]
  end

  if yes?("Add API endpoints?")
    create_api_controller
  end
end
```

### no?

Inverse boolean prompt.

```ruby
def skip_optional
  return if no?("Create test files?")
  invoke 'test_unit:service', [name]
end
```

## Output and Logging

### say

Prints a message.

```ruby
def announce
  say "Creating #{class_name} service..."
  create_service_file
  say "Service created successfully!", :green
end
```

**Colors**: `:black`, `:red`, `:green`, `:yellow`, `:blue`, `:magenta`, `:cyan`, `:white`

### say_status

Prints status with formatting.

```ruby
def status_updates
  say_status :create, "app/services/#{file_name}_service.rb", :green
  say_status :invoke, "test_unit:service", :blue
  say_status :skip, "API controller (--skip-api)", :yellow
end
```

## Advanced File Operations

### append_to_file

Appends content to end of file.

```ruby
def add_to_gemfile
  append_to_file 'Gemfile', "\ngem '#{file_name}', '~> 1.0'\n"
end
```

**With specific position**:
```ruby
def insert_in_group
  inject_into_file 'Gemfile', after: "group :development, :test do\n" do
    "  gem 'generator-test-helper'\n"
  end
end
```

### prepend_to_file

Prepends content to beginning of file.

```ruby
def add_header
  prepend_to_file 'app/services/base_service.rb', <<~RUBY
    # frozen_string_literal: true
    # Generated by #{self.class.name}

  RUBY
end
```

### remove_file

Deletes a file.

```ruby
def cleanup
  remove_file 'config/old_config.yml'
  remove_file "app/services/#{file_name}_service.rb" if options[:force]
end
```

## Behavior Modifiers

### inside

Changes directory context temporarily.

```ruby
def work_in_subdirectory
  inside 'app/services' do
    create_file "#{file_name}_service.rb", service_content
    create_file 'concerns/serviceable.rb', concern_content
  end
end
```

### run

Executes shell commands.

```ruby
def install_dependencies
  run 'bundle install'
  run 'yarn add service-helper'
end

def with_conditional
  run 'rails db:migrate' if yes?("Run migrations now?")
end
```

### git

Executes git commands.

```ruby
def commit_changes
  git :init if options[:git]
  git add: '.'
  git commit: "-m 'Generated #{class_name} service'"
end
```

## Practical Patterns

### Complex File Structure Creation

```ruby
def create_service_structure
  # Base service
  template 'service.rb.tt', "app/services/#{namespace_path}/#{file_name}_service.rb"

  # Result object
  template 'result.rb.tt', "app/services/#{namespace_path}/#{file_name}_result.rb"

  # Error classes
  empty_directory "app/services/#{namespace_path}/errors"
  template 'error.rb.tt', "app/services/#{namespace_path}/errors/#{file_name}_error.rb"

  # Tests
  template 'service_test.rb.tt', test_path

  # Documentation
  create_file "app/services/#{namespace_path}/README.md", documentation
end

private

def namespace_path
  options[:namespace] ? options[:namespace].underscore : ''
end

def test_path
  if rspec?
    "spec/services/#{namespace_path}/#{file_name}_service_spec.rb"
  else
    "test/services/#{namespace_path}/#{file_name}_service_test.rb"
  end
end
```

### Conditional File Creation

```ruby
def create_conditional_files
  # Always create
  template 'service.rb.tt', service_path

  # Conditional on options
  template 'job.rb.tt', job_path if options[:async]
  template 'mailer.rb.tt', mailer_path if options[:notifications]

  # Conditional on environment
  if Rails.env.development?
    template 'service_console.rb.tt', 'lib/console/service_helper.rb'
  end

  # Conditional on existing files
  if File.exist?('app/serializers/application_serializer.rb')
    template 'serializer.rb.tt', serializer_path
  end
end
```

### Safe File Modification

```ruby
def modify_application_config
  return unless File.exist?('config/application.rb')

  # Check if modification already exists
  return if File.read('config/application.rb').include?("config.#{file_name}")

  insert_into_file 'config/application.rb',
    "    config.#{file_name}.enabled = true\n",
    after: "class Application < Rails::Application\n"
end
```

### Interactive Template Selection

```ruby
def choose_template_style
  style = ask("Choose template style:", limited_to: ['simple', 'advanced', 'dry'])

  case style
  when 'simple'
    template 'simple_service.rb.tt', destination
  when 'advanced'
    template 'advanced_service.rb.tt', destination
    template 'service_concerns.rb.tt', concerns_destination
  when 'dry'
    template 'dry_service.rb.tt', destination
    template 'dry_schema.rb.tt', schema_destination
  end
end
```

## Error Handling

### Graceful Failure

```ruby
def safe_route_addition
  begin
    route "resources :#{plural_name}"
  rescue => e
    say_status :error, "Failed to add routes: #{e.message}", :red
    say "Please add the following to config/routes.rb manually:", :yellow
    say "  resources :#{plural_name}", :cyan
  end
end
```

### Validation Before Creation

```ruby
def validate_and_create
  unless valid_service_name?
    say_status :error, "Invalid service name: #{name}", :red
    exit 1
  end

  if service_exists?
    return unless yes?("Service already exists. Overwrite?")
  end

  create_service_file
end

private

def valid_service_name?
  name.match?(/\A[A-Z][a-zA-Z0-9]*\z/)
end

def service_exists?
  File.exist?("app/services/#{file_name}_service.rb")
end
```

## Best Practices

1. **Use `empty_directory` before creating files** in new directories
2. **Check for existing files** before inserting to avoid duplicates
3. **Provide user feedback** with `say` and `say_status`
4. **Handle errors gracefully** with begin/rescue blocks
5. **Use relative paths** from `source_root` for templates
6. **Validate user input** when using `ask` and `yes?`
7. **Test file operations** in generator tests
8. **Use `inside` blocks** for cleaner directory operations
9. **Comment complex file manipulations** for maintainability
10. **Provide undo operations** when implementing `revoke` behavior
