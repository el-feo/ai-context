# Generator Namespacing Patterns

Organizing generators with namespaces for modular, discoverable generator libraries.

## Table of Contents

- [Basic Namespacing](#basic-namespacing)
- [Generator Search Path](#generator-search-path)
- [Namespaced Templates](#namespaced-templates)
- [Engine Generators](#engine-generators)
- [Gem-Packaged Generators](#gem-packaged-generators)
- [Usage Examples](#usage-examples)

## Basic Namespacing

Namespace generators to organize related generators under a common prefix:

```ruby
# lib/generators/admin/resource/resource_generator.rb
module Admin
  module Generators
    class ResourceGenerator < Rails::Generators::NamedBase
      source_root File.expand_path('templates', __dir__)

      def create_admin_resource
        template 'resource.rb.tt', "app/admin/#{file_name}.rb"
      end

      def create_admin_controller
        template 'controller.rb.tt',
          "app/controllers/admin/#{file_name.pluralize}_controller.rb"
      end

      def create_admin_views
        directory 'views', "app/views/admin/#{file_name.pluralize}"
      end
    end
  end
end
```

Invoke with: `rails generate admin:resource User`

## Generator Search Path

Rails searches for generators in this order:

1. `rails/generators/[namespace]/[name]/[name]_generator.rb`
2. `generators/[namespace]/[name]/[name]_generator.rb`
3. `rails/generators/[namespace]_generator.rb`
4. `generators/[namespace]_generator.rb`

For `admin:resource`, Rails looks for:
1. `rails/generators/admin/resource/resource_generator.rb`
2. `generators/admin/resource/resource_generator.rb`
3. `lib/generators/admin/resource/resource_generator.rb`

### Custom Search Paths

Add custom paths in `config/application.rb`:

```ruby
config.generators do |g|
  g.templates.unshift File.expand_path('../lib/templates', __dir__)
end
```

### Fallback Resolution

When a namespaced generator is not found, Rails checks fallbacks:

```ruby
config.generators do |g|
  g.fallbacks[:admin] = :rails
end
```

This means `admin:model` falls back to `rails:model` if not found.

## Namespaced Templates

Templates for namespaced generators follow the same directory structure:

```
lib/generators/admin/resource/
├── resource_generator.rb
└── templates/
    ├── resource.rb.tt
    ├── controller.rb.tt
    └── views/
        ├── index.html.erb.tt
        └── show.html.erb.tt
```

Handle namespace in templates:

```erb
# lib/generators/admin/resource/templates/controller.rb.tt
module Admin
  class <%= class_name.pluralize %>Controller < Admin::BaseController
    def index
      @<%= plural_name %> = <%= class_name %>.all
    end

    def show
      @<%= singular_name %> = <%= class_name %>.find(params[:id])
    end
  end
end
```

## Engine Generators

Generators packaged in Rails engines:

```ruby
# my_engine/lib/generators/my_engine/install/install_generator.rb
module MyEngine
  module Generators
    class InstallGenerator < Rails::Generators::Base
      source_root File.expand_path('templates', __dir__)

      def copy_initializer
        template 'initializer.rb.tt',
          'config/initializers/my_engine.rb'
      end

      def copy_migrations
        rake 'my_engine:install:migrations'
      end

      def add_routes
        route "mount MyEngine::Engine => '/my_engine'"
      end
    end
  end
end
```

Invoke with: `rails generate my_engine:install`

## Gem-Packaged Generators

Structure generators in a gem for reuse across projects:

```
my_generators/
├── lib/
│   ├── generators/
│   │   └── my_gem/
│   │       ├── service/
│   │       │   ├── service_generator.rb
│   │       │   └── templates/
│   │       └── query/
│   │           ├── query_generator.rb
│   │           └── templates/
│   └── my_generators.rb
├── my_generators.gemspec
└── Gemfile
```

Register generators in the gem:

```ruby
# lib/my_generators.rb
module MyGenerators
  class Railtie < Rails::Railtie
    generators do
      require 'generators/my_gem/service/service_generator'
      require 'generators/my_gem/query/query_generator'
    end
  end
end
```

## Usage Examples

### Multi-Level Namespace

```ruby
# lib/generators/api/v2/resource/resource_generator.rb
module Api
  module V2
    module Generators
      class ResourceGenerator < Rails::Generators::NamedBase
        source_root File.expand_path('templates', __dir__)

        def create_controller
          template 'controller.rb.tt',
            "app/controllers/api/v2/#{file_name.pluralize}_controller.rb"
        end
      end
    end
  end
end
```

Invoke with: `rails generate api:v2:resource Product`

### Override Built-in Generators

Override Rails scaffold by placing a generator at the same namespace:

```ruby
# lib/generators/rails/scaffold_controller/scaffold_controller_generator.rb
require 'rails/generators/rails/scaffold_controller/scaffold_controller_generator'

module Rails
  module Generators
    class ScaffoldControllerGenerator
      # Override template to customize scaffold behavior
      source_root File.expand_path('templates', __dir__)
    end
  end
end
```

### Listing Available Generators

```bash
# List all generators including namespaced ones
rails generate --help

# List generators matching a pattern
rails generate --help | grep admin
```
