# Complete Model Generator Example

Production-ready custom model generator with associations, validations, scopes, and tests.

## Generator Implementation

```ruby
# lib/generators/custom_model/custom_model_generator.rb
class CustomModelGenerator < Rails::Generators::NamedBase
  source_root File.expand_path('templates', __dir__)

  argument :attributes, type: :array, default: [], banner: "field:type field:type"

  class_option :parent, type: :string, desc: "Parent model for belongs_to association"
  class_option :has_many, type: :array, default: [], desc: "has_many associations"
  class_option :has_one, type: :array, default: [], desc: "has_one associations"
  class_option :scopes, type: :array, default: [], desc: "Scopes to generate"
  class_option :validations, type: :boolean, default: true, desc: "Generate validations"
  class_option :timestamps, type: :boolean, default: true, desc: "Add timestamps"
  class_option :paranoid, type: :boolean, default: false, desc: "Add soft deletes (deleted_at)"

  hook_for :test_framework, as: :model

  def create_migration
    migration_template 'migration.rb.tt',
      File.join('db/migrate', "#{migration_file_name}.rb")
  end

  def create_model_file
    template 'model.rb.tt', File.join('app/models', class_path, "#{file_name}.rb")
  end

  private

  def migration_file_name
    "create_#{table_name}"
  end

  def migration_class_name
    "Create#{class_name.pluralize}"
  end

  def parent_class_name
    options[:parent] || "ApplicationRecord"
  end

  def attributes_with_types
    attributes.map { |attr| "#{attr.name}:#{attr.type}" }
  end

  def required_attributes
    attributes.reject { |attr| attr.name.end_with?('?') }
  end

  def optional_attributes
    attributes.select { |attr| attr.name.end_with?('?') }
  end

  def belongs_to_associations
    associations = []
    associations << options[:parent].underscore if options[:parent]
    associations
  end
end
```

## Migration Template

```erb
# lib/generators/custom_model/templates/migration.rb.tt
class <%= migration_class_name %> < ActiveRecord::Migration[<%= ActiveRecord::Migration.current_version %>]
  def change
    create_table :<%= table_name %> do |t|
      <%- attributes.each do |attribute| -%>
      t.<%= attribute.type %> :<%= attribute.name %>
      <%- end -%>
      <%- if options[:parent] -%>
      t.references :<%= options[:parent].underscore %>, null: false, foreign_key: true
      <%- end -%>
      <%- if options[:paranoid] -%>
      t.datetime :deleted_at
      <%- end -%>
      <%- if options[:timestamps] -%>

      t.timestamps
      <%- end -%>
    end
    <%- if options[:paranoid] -%>

    add_index :<%= table_name %>, :deleted_at
    <%- end -%>
    <%- attributes.select { |attr| attr.has_index? }.each do |attribute| -%>
    add_index :<%= table_name %>, :<%= attribute.name %>
    <%- end -%>
  end
end
```

## Model Template

```erb
# lib/generators/custom_model/templates/model.rb.tt
class <%= class_name %> < <%= parent_class_name %>
  <%- if options[:paranoid] -%>
  # Soft deletes
  default_scope { where(deleted_at: nil) }
  scope :deleted, -> { unscope(where: :deleted_at).where.not(deleted_at: nil) }
  scope :with_deleted, -> { unscope(where: :deleted_at) }

  <%- end -%>
  <%- if belongs_to_associations.any? -%>
  # Associations
  <%- belongs_to_associations.each do |assoc| -%>
  belongs_to :<%= assoc %>
  <%- end -%>
  <%- end -%>
  <%- if options[:has_many].any? -%>
  <%- options[:has_many].each do |assoc| -%>
  has_many :<%= assoc.underscore.pluralize %>
  <%- end -%>
  <%- end -%>
  <%- if options[:has_one].any? -%>
  <%- options[:has_one].each do |assoc| -%>
  has_one :<%= assoc.underscore %>
  <%- end -%>
  <%- end -%>

  <%- if options[:validations] && required_attributes.any? -%>
  # Validations
  <%- required_attributes.each do |attr| -%>
  validates :<%= attr.name %>, presence: true
  <%- end -%>
  <%- end -%>

  <%- if options[:scopes].any? -%>
  # Scopes
  <%- options[:scopes].each do |scope_def| -%>
  <%- scope_name, scope_condition = scope_def.split(':') -%>
  scope :<%= scope_name %>, -> { where(<%= scope_condition %>) }
  <%- end -%>
  <%- end -%>

  <%- if options[:paranoid] -%>
  # Soft delete methods
  def soft_delete
    update(deleted_at: Time.current)
  end

  def restore
    update(deleted_at: nil)
  end

  def deleted?
    deleted_at.present?
  end
  <%- end -%>
end
```

## Usage Examples

### Basic Model

```bash
rails generate custom_model Product name:string price:decimal sku:string:index
```

Creates:
```ruby
class CreateProducts < ActiveRecord::Migration[8.0]
  def change
    create_table :products do |t|
      t.string :name
      t.decimal :price
      t.string :sku

      t.timestamps
    end
    add_index :products, :sku
  end
end

class Product < ApplicationRecord
  validates :name, presence: true
  validates :price, presence: true
  validates :sku, presence: true
end
```

### Model with Associations

```bash
rails generate custom_model OrderItem \
  --parent=Order \
  --has_one=Product \
  quantity:integer \
  price:decimal \
  --validations
```

Creates:
```ruby
class CreateOrderItems < ActiveRecord::Migration[8.0]
  def change
    create_table :order_items do |t|
      t.integer :quantity
      t.decimal :price
      t.references :order, null: false, foreign_key: true

      t.timestamps
    end
  end
end

class OrderItem < ApplicationRecord
  # Associations
  belongs_to :order
  has_one :product

  # Validations
  validates :quantity, presence: true
  validates :price, presence: true
end
```

### Model with Scopes

```bash
rails generate custom_model Article \
  title:string \
  body:text \
  published:boolean \
  published_at:datetime \
  --scopes=published:published=true,recent:published_at>1.week.ago
```

Creates:
```ruby
class Article < ApplicationRecord
  validates :title, presence: true
  validates :body, presence: true

  # Scopes
  scope :published, -> { where(published: true) }
  scope :recent, -> { where("published_at > ?", 1.week.ago) }
end
```

### Model with Soft Deletes

```bash
rails generate custom_model User \
  email:string \
  name:string \
  --paranoid \
  --validations
```

Creates:
```ruby
class CreateUsers < ActiveRecord::Migration[8.0]
  def change
    create_table :users do |t|
      t.string :email
      t.string :name
      t.datetime :deleted_at

      t.timestamps
    end

    add_index :users, :deleted_at
  end
end

class User < ApplicationRecord
  # Soft deletes
  default_scope { where(deleted_at: nil) }
  scope :deleted, -> { unscope(where: :deleted_at).where.not(deleted_at: nil) }
  scope :with_deleted, -> { unscope(where: :deleted_at) }

  # Validations
  validates :email, presence: true
  validates :name, presence: true

  # Soft delete methods
  def soft_delete
    update(deleted_at: Time.current)
  end

  def restore
    update(deleted_at: nil)
  end

  def deleted?
    deleted_at.present?
  end
end
```

## Testing

```ruby
# test/generators/custom_model_generator_test.rb
require 'test_helper'
require 'generators/custom_model/custom_model_generator'

class CustomModelGeneratorTest < Rails::Generators::TestCase
  tests CustomModelGenerator
  destination File.expand_path('../tmp', __dir__)
  setup :prepare_destination

  test "generates basic model" do
    run_generator ["product", "name:string", "price:decimal"]

    assert_migration "db/migrate/create_products.rb" do |content|
      assert_match(/create_table :products/, content)
      assert_match(/t.string :name/, content)
      assert_match(/t.decimal :price/, content)
    end

    assert_file "app/models/product.rb" do |content|
      assert_match(/class Product < ApplicationRecord/, content)
      assert_match(/validates :name, presence: true/, content)
    end
  end

  test "generates model with parent" do
    run_generator ["order_item", "--parent=Order", "quantity:integer"]

    assert_migration "db/migrate/create_order_items.rb" do |content|
      assert_match(/t.references :order, null: false, foreign_key: true/, content)
    end

    assert_file "app/models/order_item.rb" do |content|
      assert_match(/class OrderItem < ApplicationRecord/, content)
      assert_match(/belongs_to :order/, content)
    end
  end

  test "generates model with has_many associations" do
    run_generator ["user", "--has_many=Post,Comment", "name:string"]

    assert_file "app/models/user.rb" do |content|
      assert_match(/has_many :posts/, content)
      assert_match(/has_many :comments/, content)
    end
  end

  test "generates model with scopes" do
    run_generator [
      "article",
      "title:string",
      "--scopes=published:published=true,recent:created_at>1.week.ago"
    ]

    assert_file "app/models/article.rb" do |content|
      assert_match(/scope :published/, content)
      assert_match(/scope :recent/, content)
    end
  end

  test "generates model with soft deletes" do
    run_generator ["user", "email:string", "--paranoid"]

    assert_migration "db/migrate/create_users.rb" do |content|
      assert_match(/t.datetime :deleted_at/, content)
      assert_match(/add_index :users, :deleted_at/, content)
    end

    assert_file "app/models/user.rb" do |content|
      assert_match(/default_scope \{ where\(deleted_at: nil\) \}/, content)
      assert_match(/def soft_delete/, content)
      assert_match(/def restore/, content)
      assert_match(/def deleted\?/, content)
    end
  end

  test "skips validations when option disabled" do
    run_generator ["product", "name:string", "--no-validations"]

    assert_file "app/models/product.rb" do |content|
      refute_match(/validates/, content)
    end
  end

  test "skips timestamps when option disabled" do
    run_generator ["product", "name:string", "--no-timestamps"]

    assert_migration "db/migrate/create_products.rb" do |content|
      refute_match(/t.timestamps/, content)
    end
  end
end
```

## Advanced Customizations

### Adding Enum Support

Update generator to handle enum attributes:

```ruby
class_option :enums, type: :hash, default: {}, desc: "Enum definitions"

# In template
<%- if options[:enums].any? -%>
# Enums
<%- options[:enums].each do |attr, values| -%>
enum <%= attr %>: { <%= values %> }
<%- end -%>
<%- end -%>
```

Usage:
```bash
rails generate custom_model Order \
  status:integer \
  --enums=status:"pending:0,processing:1,completed:2"
```

### Adding JSON/JSONB Support

```ruby
# In migration template
<%- attributes.select { |a| a.type == :json || a.type == :jsonb }.each do |attr| -%>
t.<%= attr.type %> :<%= attr.name %>, default: {}
<%- end -%>
```

### Adding UUID Primary Keys

```ruby
class_option :uuid, type: :boolean, default: false, desc: "Use UUID primary key"

# In migration template
create_table :<%= table_name %><%= ", id: :uuid" if options[:uuid] %> do |t|
```

## Production Considerations

1. **Always generate migrations** for database changes
2. **Include indexes** for foreign keys and frequently queried fields
3. **Add proper validations** to prevent bad data
4. **Use soft deletes** instead of hard deletes when audit trail needed
5. **Generate tests** alongside models for better coverage
6. **Consider performance** when adding scopes and associations
7. **Document complex logic** in model comments
8. **Use concerns** for shared behavior across models
