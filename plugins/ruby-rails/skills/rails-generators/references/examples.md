# Generator Examples

Complete, ready-to-use generator examples for common patterns.

## Table of Contents

- [Service with Dependency Injection](#service-with-dependency-injection)
- [Query Object Generator](#query-object-generator)
- [Form Object Generator](#form-object-generator)
- [Presenter Generator](#presenter-generator)

## Service with Dependency Injection

```ruby
# lib/generators/advanced_service/advanced_service_generator.rb
class AdvancedServiceGenerator < Rails::Generators::NamedBase
  source_root File.expand_path('templates', __dir__)

  class_option :dependencies, type: :array, default: []
  class_option :async, type: :boolean, default: false

  def create_service
    template 'service.rb.tt', service_path
  end

  def create_test
    template 'service_test.rb.tt', test_path
  end

  private

  def service_path
    "app/services/#{file_name}_service.rb"
  end

  def test_path
    "test/services/#{file_name}_service_test.rb"
  end

  def dependency_params
    options[:dependencies].map { |dep| "#{dep}:" }.join(', ')
  end
end
```

Template (service.rb.tt):

```erb
class <%= class_name %>Service
  <%- if options[:async] -%>
  include ActiveJob::Helpers
  <%- end -%>

  <%- if options[:dependencies].any? -%>
  def initialize(<%= dependency_params %>)
    <%- options[:dependencies].each do |dep| -%>
    @<%= dep %> = <%= dep %>
    <%- end -%>
  end
  <%- else -%>
  def initialize
  end
  <%- end -%>

  def call
    # Implementation
  end
end
```

Usage:

```bash
rails generate advanced_service payment_processor --dependencies=user,account --async
```

## Query Object Generator

```ruby
# lib/generators/query/query_generator.rb
class QueryGenerator < Rails::Generators::NamedBase
  source_root File.expand_path('templates', __dir__)

  class_option :model, type: :string, required: true
  class_option :scopes, type: :array, default: []

  def create_query
    template 'query.rb.tt', "app/queries/#{file_name}_query.rb"
  end

  def create_test
    template 'query_test.rb.tt', "test/queries/#{file_name}_query_test.rb"
  end
end
```

Template (query.rb.tt):

```erb
class <%= class_name %>Query
  def initialize(relation = <%= options[:model].camelize %>.all)
    @relation = relation
  end

  def call
    @relation
    <%- options[:scopes].each do |scope| -%>
      .then { |rel| apply_<%= scope %>(rel) }
    <%- end -%>
  end

  private

  attr_reader :relation

  <%- options[:scopes].each do |scope| -%>
  def apply_<%= scope %>(rel)
    rel # TODO: implement <%= scope %> filter
  end

  <%- end -%>
end
```

Usage:

```bash
rails generate query active_users --model=User --scopes=active,verified,recent
```

## Form Object Generator

```ruby
# lib/generators/form_object/form_object_generator.rb
class FormObjectGenerator < Rails::Generators::NamedBase
  source_root File.expand_path('templates', __dir__)

  argument :attributes, type: :array, default: [], banner: "field:type"
  class_option :model, type: :string, desc: "Backing model"

  def create_form_object
    template 'form_object.rb.tt', "app/forms/#{file_name}_form.rb"
  end

  def create_test
    template 'form_object_test.rb.tt', "test/forms/#{file_name}_form_test.rb"
  end
end
```

Template (form_object.rb.tt):

```erb
class <%= class_name %>Form
  include ActiveModel::Model
  include ActiveModel::Attributes

  <%- attributes.each do |attr| -%>
  attribute :<%= attr.name %>, :<%= attr.type %>
  <%- end -%>

  <%- attributes.each do |attr| -%>
  validates :<%= attr.name %>, presence: true
  <%- end -%>

  def save
    return false unless valid?

    <%- if options[:model] -%>
    <%= options[:model].camelize %>.create!(
      <%- attributes.each_with_index do |attr, i| -%>
      <%= attr.name %>: <%= attr.name %><%= ',' unless i == attributes.length - 1 %>
      <%- end -%>
    )
    <%- else -%>
    # Persist data
    true
    <%- end -%>
  end
end
```

Usage:

```bash
rails generate form_object registration email:string name:string password:string --model=User
```

## Presenter Generator

```ruby
# lib/generators/presenter/presenter_generator.rb
class PresenterGenerator < Rails::Generators::NamedBase
  source_root File.expand_path('templates', __dir__)

  class_option :model, type: :string, desc: "Model to present"
  class_option :methods, type: :array, default: [], desc: "Delegated methods"

  def create_presenter
    template 'presenter.rb.tt', "app/presenters/#{file_name}_presenter.rb"
  end

  def create_test
    template 'presenter_test.rb.tt', "test/presenters/#{file_name}_presenter_test.rb"
  end
end
```

Template (presenter.rb.tt):

```erb
class <%= class_name %>Presenter
  <%- if options[:model] -%>
  attr_reader :<%= options[:model].underscore %>
  <%- if options[:methods].any? -%>

  delegate <%= options[:methods].map { |m| ":#{m}" }.join(', ') %>,
    to: :<%= options[:model].underscore %>
  <%- end -%>

  def initialize(<%= options[:model].underscore %>)
    @<%= options[:model].underscore %> = <%= options[:model].underscore %>
  end
  <%- else -%>
  def initialize
  end
  <%- end -%>
end
```

Usage:

```bash
rails generate presenter user --model=User --methods=name,email,created_at
```
