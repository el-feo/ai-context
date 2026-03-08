---
name: rails-generators
description: Create expert-level Ruby on Rails generators for models, services, controllers, and full-stack features. Use when building custom generators, scaffolds, or code generation tools for Rails applications, or when the user mentions Rails generators, Thor DSL, or automated code generation.
---

<objective>
Build production-ready Rails generators that automate repetitive coding tasks and enforce architectural patterns. This skill covers creating custom generators for models, service objects, API scaffolds, and complete features with migrations, tests, and documentation.
</objective>

<quick_start>
<basic_generator>
Create a simple service object generator:

```ruby
# lib/generators/service/service_generator.rb
module Generators
  class ServiceGenerator < Rails::Generators::NamedBase
    source_root File.expand_path('templates', __dir__)

    def create_service_file
      template 'service.rb.tt', "app/services/#{file_name}_service.rb"
    end

    def create_service_test
      template 'service_test.rb.tt', "test/services/#{file_name}_service_test.rb"
    end
  end
end
```

Template file (templates/service.rb.tt):
```ruby
class <%= class_name %>Service
  def initialize
  end

  def call
    # Implementation goes here
  end
end
```

Invoke with: `rails generate service payment_processor`
</basic_generator>

<usage_pattern>
**Generator location**: `lib/generators/[name]/[name]_generator.rb`
**Template location**: `lib/generators/[name]/templates/`
**Test location**: `test/generators/[name]_generator_test.rb`
</usage_pattern>
</quick_start>

<context>
<when_to_create>
Create custom generators when you need to:

- **Enforce architectural patterns**: Service objects, form objects, presenters, query objects
- **Reduce boilerplate**: API controllers with standard CRUD, serializers, policy objects
- **Maintain consistency**: Team conventions for file structure, naming, and organization
- **Automate complex setup**: Multi-file features with migrations, tests, and documentation
- **Override Rails defaults**: Customize scaffold behavior for your application's needs
</when_to_create>

<rails_8_updates>
Rails 8 introduced the authentication generator (`rails generate authentication`) which demonstrates modern generator patterns including ActionCable integration, controller concerns, mailer generation, and comprehensive view scaffolding. Study Rails 8 built-in generators for current best practices.
</rails_8_updates>
</context>

<workflow>
<step_1>
**Choose base class**:

- `Rails::Generators::Base`: Simple generators without required arguments
- `Rails::Generators::NamedBase`: Generators requiring a name argument (provides `name`, `class_name`, `file_name`, `plural_name`)

```ruby
class ServiceGenerator < Rails::Generators::NamedBase
  # Automatically provides: name, class_name, file_name, plural_name
end
```
</step_1>

<step_2>
**Define source root and options**:

```ruby
source_root File.expand_path('templates', __dir__)

class_option :namespace, type: :string, default: nil, desc: "Namespace for the service"
class_option :skip_tests, type: :boolean, default: false, desc: "Skip test files"
```

Access options with: `options[:namespace]`
</step_2>

<step_3>
**Add public methods** (executed in definition order):

```ruby
def create_service_file
  template 'service.rb.tt', service_file_path
end

def create_test_file
  return if options[:skip_tests]
  template 'service_test.rb.tt', test_file_path
end

private

def service_file_path
  if options[:namespace]
    "app/services/#{options[:namespace]}/#{file_name}_service.rb"
  else
    "app/services/#{file_name}_service.rb"
  end
end
```
</step_3>

<step_4>
**Create ERB templates** (`.tt` extension):

```erb
<% if options[:namespace] -%>
module <%= options[:namespace].camelize %>
  class <%= class_name %>Service
    def call
      # Implementation
    end
  end
end
<% else -%>
class <%= class_name %>Service
  def call
    # Implementation
  end
end
<% end -%>
```

**Important**: Use `<%%` to output literal `<%` in generated files. See [references/templates.md](references/templates.md) for template patterns.
</step_4>

<step_5>
**Test the generator** (see [Testing](#testing) section):

```ruby
rails generate service payment_processor --namespace=billing
rails generate service notifier --skip-tests
```
</step_5>
</workflow>

<common_patterns>
<model_generator>
**Custom model with associations and scopes**:

```ruby
class CustomModelGenerator < Rails::Generators::NamedBase
  source_root File.expand_path('templates', __dir__)

  class_option :parent, type: :string, desc: "Parent model for belongs_to"
  class_option :scope, type: :array, desc: "Scopes to generate"

  def create_migration
    migration_template 'migration.rb.tt', "db/migrate/create_#{table_name}.rb"
  end

  def create_model_file
    template 'model.rb.tt', "app/models/#{file_name}.rb"
  end
end
```

See [references/model-generator.md](references/model-generator.md) for complete example with templates.
</model_generator>

<service_object_generator>
**Service object with result object pattern**:

```ruby
class ServiceGenerator < Rails::Generators::NamedBase
  source_root File.expand_path('templates', __dir__)

  class_option :result_object, type: :boolean, default: true
  class_option :pattern, type: :string, default: 'simple',
    desc: "Service pattern (simple, command, interactor)"

  def create_service
    template 'service.rb.tt', "app/services/#{file_name}_service.rb"
  end

  def create_result_object
    return unless options[:result_object]
    template 'result.rb.tt', "app/services/#{file_name}_result.rb"
  end
end
```

See [references/service-generator.md](references/service-generator.md) for complete example with all three patterns.
</service_object_generator>

<api_controller_generator>
**API controller with serializer**:

```ruby
class ApiControllerGenerator < Rails::Generators::NamedBase
  source_root File.expand_path('templates', __dir__)

  class_option :serializer, type: :string, default: 'active_model_serializers'
  class_option :actions, type: :array, default: %w[index show create update destroy]

  def create_controller
    template 'controller.rb.tt',
      "app/controllers/api/v1/#{file_name.pluralize}_controller.rb"
  end

  def create_serializer
    template "serializer_#{options[:serializer]}.rb.tt",
      "app/serializers/#{file_name}_serializer.rb"
  end

  def add_routes
    route "namespace :api do\n    namespace :v1 do\n      resources :#{file_name.pluralize}\n    end\n  end"
  end
end
```

See [references/api-generator.md](references/api-generator.md) for complete example with templates.
</api_controller_generator>

<full_stack_scaffold>
**Complete feature scaffold** using generator composition:

```ruby
class FeatureGenerator < Rails::Generators::NamedBase
  source_root File.expand_path('templates', __dir__)
  class_option :api, type: :boolean, default: false

  def create_model
    invoke 'model', [name], migration: true
  end

  def create_controller
    if options[:api]
      invoke 'api_controller', [name]
    else
      invoke 'controller', [name], actions: %w[index show new create edit update destroy]
    end
  end

  def create_views
    return if options[:api]
    %w[index show new edit _form].each do |view|
      template "views/#{view}.html.erb.tt",
        "app/views/#{file_name.pluralize}/#{view}.html.erb"
    end
  end
end
```

See [references/scaffold-generator.md](references/scaffold-generator.md) for complete example.
</full_stack_scaffold>
</common_patterns>

<advanced_features>
<hooks>
**Generator hooks** enable modular composition and test framework integration:

```ruby
class ServiceGenerator < Rails::Generators::NamedBase
  hook_for :test_framework, as: :service
end
```

This automatically invokes `test_unit:service` or `rspec:service` based on configuration. See [references/hooks.md](references/hooks.md) for hook patterns, responders, and fallback configuration.
</hooks>

<generator_composition>
**Invoke other generators**:

```ruby
def create_dependencies
  invoke 'model', [name], migration: true
  invoke 'service', ["#{name}_processor"]
  invoke 'mailer', [name] if options[:mailer]
end
```
</generator_composition>

<namespacing>
**Namespace generators** for organization:

```ruby
# lib/generators/admin/resource/resource_generator.rb
module Admin
  module Generators
    class ResourceGenerator < Rails::Generators::NamedBase
      source_root File.expand_path('templates', __dir__)

      def create_admin_resource
        template 'resource.rb.tt', "app/admin/#{file_name}.rb"
      end
    end
  end
end
```

Invoke with: `rails generate admin:resource User`

See [references/namespacing.md](references/namespacing.md) for search paths, engine generators, and gem packaging.
</namespacing>

<file_manipulation>
**Thor::Actions methods** available in generators:

```ruby
# Create files
create_file 'config/settings.yml', yaml_content
template 'config.rb.tt', 'config/settings.rb'

# Modify existing files
insert_into_file 'config/routes.rb', route_content, after: "Rails.application.routes.draw do\n"
gsub_file 'config/application.rb', /old_value/, 'new_value'

# Rails-specific helpers
initializer 'service_config.rb', config_content
route "namespace :api do\n  resources :users\n end"
```

See [references/file-actions.md](references/file-actions.md) for complete reference.
</file_manipulation>
</advanced_features>

<testing>
**Testing with Rails::Generators::TestCase**:

```ruby
require 'test_helper'
require 'generators/service/service_generator'

class ServiceGeneratorTest < Rails::Generators::TestCase
  tests ServiceGenerator
  destination File.expand_path('../tmp', __dir__)
  setup :prepare_destination

  test "generates service file" do
    run_generator ["payment_processor"]

    assert_file "app/services/payment_processor_service.rb" do |content|
      assert_match(/class PaymentProcessorService/, content)
      assert_match(/def call/, content)
    end
  end

  test "skips tests when flag provided" do
    run_generator ["payment", "--skip-tests"]
    assert_file "app/services/payment_service.rb"
    assert_no_file "test/services/payment_service_test.rb"
  end
end
```

**Key assertions**: `assert_file`, `assert_no_file`, `assert_migration`, `assert_class_method`, `assert_instance_method`

- See [references/testing-rails.md](references/testing-rails.md) for comprehensive Rails testing patterns
- See [references/testing-rspec.md](references/testing-rspec.md) for RSpec and generator_spec usage
</testing>

<validation>
<checklist>
Before considering a generator complete, verify:

- [ ] Generator inherits from appropriate base class
- [ ] `source_root` points to templates directory
- [ ] All options have appropriate types and defaults
- [ ] Public methods execute in correct order
- [ ] Templates use correct ERB syntax (`.tt` extension)
- [ ] File paths handle namespacing correctly
- [ ] Tests cover default behavior and all options
- [ ] Generator can be destroyed (if applicable)
</checklist>

<common_issues>
**Missing source_root**: Add `source_root File.expand_path('templates', __dir__)` to generator class.

**Incorrect template syntax**: Use `<%%` for literal ERB in generated files: `<%%= @user.name %>` generates `<%= @user.name %>`.

**Option not recognized**: Define with `class_option :namespace, type: :string` and access with `options[:namespace]`.

**Method order issues**: Public methods execute in definition order. Place dependent steps after their prerequisites.
</common_issues>
</validation>

<reference_guides>
**Detailed references**:

- [Model generator patterns](references/model-generator.md) - Custom models with migrations and associations
- [Service generator patterns](references/service-generator.md) - Service objects with result objects
- [API generator patterns](references/api-generator.md) - Controllers, serializers, and routes
- [Scaffold patterns](references/scaffold-generator.md) - Full-stack feature generation
- [Hooks and composition](references/hooks.md) - Generator hooks and fallbacks
- [Namespacing](references/namespacing.md) - Organizing generators with namespaces
- [File manipulation](references/file-actions.md) - Thor::Actions reference
- [Template system](references/templates.md) - ERB template patterns
- [Rails testing](references/testing-rails.md) - Rails::Generators::TestCase patterns
- [RSpec testing](references/testing-rspec.md) - generator_spec and RSpec patterns
- [Examples](references/examples.md) - Complete generator examples (query objects, form objects, presenters)
</reference_guides>

<success_criteria>
A well-built Rails generator has clear inheritance, properly configured `source_root`, well-defined `class_option` declarations, public methods in logical order, correct ERB templates, comprehensive tests, and consistent Rails naming conventions.
</success_criteria>

**Sources**:
- [Creating and Customizing Rails Generators & Templates — Ruby on Rails Guides](https://guides.rubyonrails.org/generators.html)
- [Rails 8 adds built in authentication generator | Saeloun Blog](https://blog.saeloun.com/2025/05/12/rails-8-adds-built-in-authentication-generator/)
- [Shaping Rails to Your Needs, Customizing Rails Generators using Thor Templates | Saeloun Blog](https://blog.saeloun.com/2023/05/31/customizing-rails-generators-using-thor-templates/)
- [Generators · rails/thor Wiki · GitHub](https://github.com/rails/thor/wiki/Generators)
- [GitHub: generator_spec](https://github.com/stevehodgkiss/generator_spec)
- [A Deep Dive Into RSpec Tests in Ruby on Rails | AppSignal Blog](https://blog.appsignal.com/2024/02/07/a-deep-dive-into-rspec-tests-in-ruby-on-rails.html)
