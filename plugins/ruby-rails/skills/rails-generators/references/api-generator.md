# API Controller Generator Patterns

Complete API controller generator with versioned endpoints, serializers, and route configuration.

## Table of Contents

- [Generator Implementation](#generator-implementation)
- [Controller Template](#controller-template)
- [Serializer Templates](#serializer-templates)
- [Route Generation](#route-generation)
- [Usage Examples](#usage-examples)
- [Testing](#testing)

## Generator Implementation

```ruby
# lib/generators/api_controller/api_controller_generator.rb
class ApiControllerGenerator < Rails::Generators::NamedBase
  source_root File.expand_path('templates', __dir__)

  class_option :serializer, type: :string, default: 'active_model_serializers',
    desc: "Serializer framework (active_model_serializers, jsonapi, jbuilder)"
  class_option :actions, type: :array, default: %w[index show create update destroy],
    desc: "Controller actions to generate"
  class_option :version, type: :string, default: 'v1',
    desc: "API version"
  class_option :auth, type: :boolean, default: true,
    desc: "Include authentication before_action"
  class_option :pagination, type: :boolean, default: false,
    desc: "Include pagination support"

  hook_for :test_framework, as: :controller

  def create_controller
    template 'controller.rb.tt',
      "app/controllers/api/#{options[:version]}/#{file_name.pluralize}_controller.rb"
  end

  def create_serializer
    template "serializer_#{options[:serializer]}.rb.tt",
      serializer_path
  end

  def add_routes
    route route_content
  end

  private

  def serializer_path
    case options[:serializer]
    when 'jbuilder'
      "app/views/api/#{options[:version]}/#{file_name.pluralize}/index.json.jbuilder"
    else
      "app/serializers/#{file_name}_serializer.rb"
    end
  end

  def route_content
    <<~RUBY
      namespace :api do
        namespace :#{options[:version]} do
          resources :#{file_name.pluralize}, only: #{options[:actions].map(&:to_sym).inspect}
        end
      end
    RUBY
  end

  def permitted_params
    # Derive from model if it exists
    if File.exist?("app/models/#{file_name}.rb")
      ":#{file_name.pluralize}_params"
    else
      "params.require(:#{file_name}).permit(:name)"
    end
  end
end
```

## Controller Template

```erb
# lib/generators/api_controller/templates/controller.rb.tt
module Api
  module <%= options[:version].camelize %>
    class <%= class_name.pluralize %>Controller < ApplicationController
      <%- if options[:auth] -%>
      before_action :authenticate_user!
      <%- end -%>
      <%- if options[:actions].include?('show') || options[:actions].include?('update') || options[:actions].include?('destroy') -%>
      before_action :set_<%= singular_name %>, only: [<%= (options[:actions] & %w[show update destroy]).map { |a| ":#{a}" }.join(', ') %>]
      <%- end -%>

      <%- if options[:actions].include?('index') -%>
      # GET /api/<%= options[:version] %>/<%= plural_name %>
      def index
        @<%= plural_name %> = <%= class_name %>.all
        <%- if options[:pagination] -%>
        @<%= plural_name %> = @<%= plural_name %>.page(params[:page]).per(params[:per_page] || 25)
        <%- end -%>

        render json: @<%= plural_name %>
      end
      <%- end -%>

      <%- if options[:actions].include?('show') -%>
      # GET /api/<%= options[:version] %>/<%= plural_name %>/:id
      def show
        render json: @<%= singular_name %>
      end
      <%- end -%>

      <%- if options[:actions].include?('create') -%>
      # POST /api/<%= options[:version] %>/<%= plural_name %>
      def create
        @<%= singular_name %> = <%= class_name %>.new(<%= singular_name %>_params)

        if @<%= singular_name %>.save
          render json: @<%= singular_name %>, status: :created
        else
          render json: { errors: @<%= singular_name %>.errors }, status: :unprocessable_entity
        end
      end
      <%- end -%>

      <%- if options[:actions].include?('update') -%>
      # PATCH/PUT /api/<%= options[:version] %>/<%= plural_name %>/:id
      def update
        if @<%= singular_name %>.update(<%= singular_name %>_params)
          render json: @<%= singular_name %>
        else
          render json: { errors: @<%= singular_name %>.errors }, status: :unprocessable_entity
        end
      end
      <%- end -%>

      <%- if options[:actions].include?('destroy') -%>
      # DELETE /api/<%= options[:version] %>/<%= plural_name %>/:id
      def destroy
        @<%= singular_name %>.destroy
        head :no_content
      end
      <%- end -%>

      private

      <%- if options[:actions].include?('show') || options[:actions].include?('update') || options[:actions].include?('destroy') -%>
      def set_<%= singular_name %>
        @<%= singular_name %> = <%= class_name %>.find(params[:id])
      end
      <%- end -%>

      <%- if options[:actions].include?('create') || options[:actions].include?('update') -%>
      def <%= singular_name %>_params
        params.require(:<%= singular_name %>).permit(:name)
      end
      <%- end -%>
    end
  end
end
```

## Serializer Templates

### ActiveModelSerializers

```erb
# lib/generators/api_controller/templates/serializer_active_model_serializers.rb.tt
class <%= class_name %>Serializer < ActiveModel::Serializer
  attributes :id, :created_at, :updated_at
end
```

### JSON:API

```erb
# lib/generators/api_controller/templates/serializer_jsonapi.rb.tt
class <%= class_name %>Serializer
  include JSONAPI::Serializer

  attributes :id, :created_at, :updated_at
end
```

### Jbuilder

```erb
# lib/generators/api_controller/templates/serializer_jbuilder.rb.tt
json.array! @<%= plural_name %> do |<%= singular_name %>|
  json.extract! <%= singular_name %>, :id, :created_at, :updated_at
end
```

## Route Generation

The generator automatically adds versioned, namespaced routes:

```ruby
# For: rails generate api_controller Product --actions=index,show,create
namespace :api do
  namespace :v1 do
    resources :products, only: [:index, :show, :create]
  end
end
```

Custom version:
```bash
rails generate api_controller Product --version=v2
# Generates routes under api/v2/products
```

## Usage Examples

### Basic CRUD API

```bash
rails generate api_controller Product
# Creates:
# - app/controllers/api/v1/products_controller.rb (all CRUD actions)
# - app/serializers/product_serializer.rb
# - Adds routes to config/routes.rb
```

### Read-Only API

```bash
rails generate api_controller Report --actions=index,show --no-auth
# Creates controller with only index and show actions, no authentication
```

### Paginated API with Jbuilder

```bash
rails generate api_controller Order --serializer=jbuilder --pagination
# Creates:
# - app/controllers/api/v1/orders_controller.rb (with pagination)
# - app/views/api/v1/orders/index.json.jbuilder
```

## Testing

```ruby
class ApiControllerGeneratorTest < Rails::Generators::TestCase
  tests ApiControllerGenerator
  destination File.expand_path('../tmp', __dir__)
  setup :prepare_destination

  test "generates API controller with all actions" do
    run_generator ["product"]

    assert_file "app/controllers/api/v1/products_controller.rb" do |content|
      assert_match(/module Api/, content)
      assert_match(/module V1/, content)
      assert_match(/class ProductsController/, content)
      assert_match(/def index/, content)
      assert_match(/def show/, content)
      assert_match(/def create/, content)
      assert_match(/def update/, content)
      assert_match(/def destroy/, content)
    end
  end

  test "generates controller with limited actions" do
    run_generator ["product", "--actions=index,show"]

    assert_file "app/controllers/api/v1/products_controller.rb" do |content|
      assert_match(/def index/, content)
      assert_match(/def show/, content)
      refute_match(/def create/, content)
      refute_match(/def destroy/, content)
    end
  end

  test "generates serializer" do
    run_generator ["product"]

    assert_file "app/serializers/product_serializer.rb" do |content|
      assert_match(/class ProductSerializer/, content)
    end
  end

  test "adds routes" do
    run_generator ["product"]

    assert_file "config/routes.rb" do |content|
      assert_match(/namespace :api/, content)
      assert_match(/resources :products/, content)
    end
  end

  test "supports custom API version" do
    run_generator ["product", "--version=v2"]

    assert_file "app/controllers/api/v2/products_controller.rb"
  end
end
```
