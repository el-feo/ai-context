# Full-Stack Scaffold Generator Patterns

Complete feature scaffold generator that creates models, controllers, views, and tests in one invocation.

## Table of Contents

- [Generator Implementation](#generator-implementation)
- [View Templates](#view-templates)
- [Invoking Sub-Generators](#invoking-sub-generators)
- [Usage Examples](#usage-examples)
- [Testing](#testing)

## Generator Implementation

```ruby
# lib/generators/feature/feature_generator.rb
class FeatureGenerator < Rails::Generators::NamedBase
  source_root File.expand_path('templates', __dir__)

  argument :attributes, type: :array, default: [], banner: "field:type field:type"

  class_option :api, type: :boolean, default: false, desc: "Generate API-only scaffold"
  class_option :skip_views, type: :boolean, default: false, desc: "Skip view generation"
  class_option :skip_controller, type: :boolean, default: false, desc: "Skip controller"
  class_option :skip_model, type: :boolean, default: false, desc: "Skip model and migration"
  class_option :namespace, type: :string, desc: "Controller namespace"
  class_option :parent, type: :string, desc: "Parent model for nested resource"

  def create_model
    return if options[:skip_model]
    invoke 'model', [name] + attributes.map(&:to_s), migration: true
  end

  def create_controller
    return if options[:skip_controller]

    if options[:api]
      invoke 'api_controller', [name]
    else
      template 'controller.rb.tt', controller_path
    end
  end

  def create_views
    return if options[:api] || options[:skip_views] || options[:skip_controller]

    %w[index show new edit _form].each do |view|
      template "views/#{view}.html.erb.tt",
        "app/views/#{controller_file_path}/#{view}.html.erb"
    end
  end

  def add_routes
    return if options[:skip_controller]

    if options[:parent]
      route "resources :#{options[:parent].underscore.pluralize} do\n    resources :#{file_name.pluralize}\n  end"
    elsif options[:namespace]
      route "namespace :#{options[:namespace]} do\n    resources :#{file_name.pluralize}\n  end"
    else
      route "resources :#{file_name.pluralize}"
    end
  end

  def create_tests
    invoke 'test_unit:model', [name] unless options[:skip_model]
    unless options[:skip_controller]
      invoke 'test_unit:controller', [name]
      invoke 'test_unit:system', [name] unless options[:api]
    end
  end

  private

  def controller_path
    if options[:namespace]
      "app/controllers/#{options[:namespace]}/#{file_name.pluralize}_controller.rb"
    else
      "app/controllers/#{file_name.pluralize}_controller.rb"
    end
  end

  def controller_file_path
    if options[:namespace]
      "#{options[:namespace]}/#{file_name.pluralize}"
    else
      file_name.pluralize
    end
  end
end
```

## View Templates

### Index View

```erb
# lib/generators/feature/templates/views/index.html.erb.tt
<h1><%= class_name.pluralize %></h1>

<%%= link_to "New <%= class_name.titleize %>", new_<%= singular_route_name %>_path %>

<table>
  <thead>
    <tr>
      <%- attributes.each do |attr| -%>
      <th><%= attr.human_name %></th>
      <%- end -%>
      <th>Actions</th>
    </tr>
  </thead>
  <tbody>
    <%% @<%= plural_name %>.each do |<%= singular_name %>| %>
      <tr>
        <%- attributes.each do |attr| -%>
        <td><%%= <%= singular_name %>.<%= attr.name %> %></td>
        <%- end -%>
        <td>
          <%%= link_to "Show", <%= singular_name %> %>
          <%%= link_to "Edit", edit_<%= singular_route_name %>_path(<%= singular_name %>) %>
          <%%= button_to "Delete", <%= singular_name %>, method: :delete, data: { confirm: "Are you sure?" } %>
        </td>
      </tr>
    <%% end %>
  </tbody>
</table>
```

### Show View

```erb
# lib/generators/feature/templates/views/show.html.erb.tt
<h1><%= class_name %></h1>

<%- attributes.each do |attr| -%>
<p>
  <strong><%= attr.human_name %>:</strong>
  <%%= @<%= singular_name %>.<%= attr.name %> %>
</p>
<%- end -%>

<%%= link_to "Edit", edit_<%= singular_route_name %>_path(@<%= singular_name %>) %>
<%%= link_to "Back", <%= plural_route_name %>_path %>
```

### Form Partial

```erb
# lib/generators/feature/templates/views/_form.html.erb.tt
<%%= form_with(model: <%= singular_name %>) do |form| %>
  <%% if <%= singular_name %>.errors.any? %>
    <div id="error_explanation">
      <h2><%%= pluralize(<%= singular_name %>.errors.count, "error") %> prohibited this from being saved:</h2>
      <ul>
        <%% <%= singular_name %>.errors.each do |error| %>
          <li><%%= error.full_message %></li>
        <%% end %>
      </ul>
    </div>
  <%% end %>

  <%- attributes.each do |attr| -%>
  <div class="field">
    <%%= form.label :<%= attr.name %> %>
    <%- case attr.type -%>
    <%- when :text -%>
    <%%= form.text_area :<%= attr.name %> %>
    <%- when :boolean -%>
    <%%= form.check_box :<%= attr.name %> %>
    <%- when :integer, :float, :decimal -%>
    <%%= form.number_field :<%= attr.name %> %>
    <%- when :date -%>
    <%%= form.date_field :<%= attr.name %> %>
    <%- when :datetime -%>
    <%%= form.datetime_field :<%= attr.name %> %>
    <%- else -%>
    <%%= form.text_field :<%= attr.name %> %>
    <%- end -%>
  </div>
  <%- end -%>

  <div class="actions">
    <%%= form.submit %>
  </div>
<%% end %>
```

## Invoking Sub-Generators

The scaffold generator composes other generators using `invoke`:

```ruby
# Invoke built-in Rails generators
invoke 'model', [name], migration: true
invoke 'controller', [name], actions: %w[index show new create edit update destroy]

# Invoke custom generators
invoke 'api_controller', [name]
invoke 'service', ["#{name}_processor"]

# Conditional invocation
invoke 'mailer', [name] if options[:mailer]
invoke 'job', ["#{name}_job"] if options[:background_job]
```

Key considerations:
- Invoked generators receive the same `destination_root`
- Options can be passed through to sub-generators
- Use `invoke` for generators that should only run once per name
- Generator hooks (`hook_for`) are preferred for test framework integration

## Usage Examples

### Basic Feature Scaffold

```bash
rails generate feature Product name:string price:decimal description:text
# Creates:
# - db/migrate/XXX_create_products.rb
# - app/models/product.rb
# - app/controllers/products_controller.rb
# - app/views/products/{index,show,new,edit,_form}.html.erb
# - test/models/product_test.rb
# - test/controllers/products_controller_test.rb
# - test/system/products_test.rb
# - Adds routes
```

### API-Only Scaffold

```bash
rails generate feature Product name:string price:decimal --api
# Creates model, migration, API controller, serializer (no views)
```

### Nested Resource

```bash
rails generate feature Comment body:text --parent=Post
# Creates nested routes: resources :posts { resources :comments }
```

### Namespaced Feature

```bash
rails generate feature Dashboard::Widget title:string --namespace=admin
# Creates files under admin/ namespace
```

## Testing

```ruby
class FeatureGeneratorTest < Rails::Generators::TestCase
  tests FeatureGenerator
  destination File.expand_path('../tmp', __dir__)
  setup :prepare_destination

  test "generates complete feature" do
    run_generator ["order", "status:string", "total:decimal"]

    assert_file "app/models/order.rb"
    assert_migration "db/migrate/create_orders.rb"
    assert_file "app/controllers/orders_controller.rb"
    assert_file "app/views/orders/index.html.erb"
    assert_file "app/views/orders/show.html.erb"
    assert_file "app/views/orders/_form.html.erb"
  end

  test "generates API-only feature" do
    run_generator ["order", "--api"]

    assert_file "app/models/order.rb"
    assert_no_file "app/views/orders/index.html.erb"
  end

  test "skips model when requested" do
    run_generator ["order", "--skip-model"]

    assert_no_migration "db/migrate/create_orders.rb"
    assert_file "app/controllers/orders_controller.rb"
  end

  test "generates nested resource routes" do
    run_generator ["comment", "--parent=Post"]

    assert_file "config/routes.rb" do |content|
      assert_match(/resources :posts/, content)
      assert_match(/resources :comments/, content)
    end
  end
end
```
