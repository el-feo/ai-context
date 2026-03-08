# Active Record Advanced

Active Model, PostgreSQL features, multiple databases, composite primary keys, and encryption.

## Table of Contents

- [1. What is Active Model?](#1-what-is-active-model)
- [1. Datatypes](#1-datatypes)
- [2. UUID Primary Keys](#2-uuid-primary-keys)
- [3. Indexing](#3-indexing)
- [4. Generated Columns](#4-generated-columns)
- [5. Deferrable Foreign Keys](#5-deferrable-foreign-keys)
- [6. Unique Constraint](#6-unique-constraint)
- [7. Exclusion Constraints](#7-exclusion-constraints)
- [8. Full Text Search](#8-full-text-search)
- [9. Database Views](#9-database-views)
- [10. Structure Dumps](#10-structure-dumps)
- [11. Explain](#11-explain)
- [1. Setting up Your Application](#1-setting-up-your-application)
- [2. Connecting to Databases without Managing Schema and Migrations](#2-connecting-to-databases-without-managing-schema-and-migrations)
- [3. Generators and Migrations](#3-generators-and-migrations)
- [4. Activating Automatic Role Switching](#4-activating-automatic-role-switching)
- [5. Using Manual Connection Switching](#5-using-manual-connection-switching)
- [6. Horizontal Sharding](#6-horizontal-sharding)
- [7. Activating Automatic Shard Switching](#7-activating-automatic-shard-switching)
- [8. Granular Database Connection Switching](#8-granular-database-connection-switching)
- [9. Caveats](#9-caveats)
- [1. What are Composite Primary Keys?](#1-what-are-composite-primary-keys)
- [2. Composite Primary Key Migrations](#2-composite-primary-key-migrations)
- [3. Querying Models](#3-querying-models)
- [4. Associations between Models with Composite Primary Keys](#4-associations-between-models-with-composite-primary-keys)
- [5. Forms for Composite Primary Key Models](#5-forms-for-composite-primary-key-models)
- [6. Composite Key Parameters](#6-composite-key-parameters)
- [7. Composite Primary Key Fixtures](#7-composite-primary-key-fixtures)
- [1. Why Encrypt Data at the Application Level?](#1-why-encrypt-data-at-the-application-level)
- [2. Basic Usage](#2-basic-usage)
- [3. Features](#3-features)
- [4. Key Management](#4-key-management)
- [5. API](#5-api)
- [6. Configuration](#6-configuration)

---

This guide will provide you with what you need to get started using Active
Model. Active Model provides a way for Action Pack and Action View helpers to
interact with plain Ruby objects. It also helps to build custom ORMs for use
outside of the Rails framework.

After reading this guide, you will know:

- What Active Model is, and how it relates to Active Record.

- The different modules that are included in Active Model.

- How to use Active Model in your classes.

## 1. What is Active Model?

To understand Active Model, you need to know a little about Active
Record. Active Record is an ORM (Object Relational
Mapper) that connects objects whose data requires persistent storage to a
relational database. However, it has functionality that is useful outside of the
ORM, some of these include validations, callbacks, translations, the ability to
create custom attributes, etc.

Some of this functionality was abstracted from Active Record to form Active
Model. Active Model is a library containing various modules that can be used on
plain Ruby objects that require model-like features but are not tied to any
table in a database.

In summary, while Active Record provides an interface for defining models that
correspond to database tables, Active Model provides functionality for building
model-like Ruby classes that don't necessarily need to be backed by a database.
Active Model can be used independently of Active Record.

Some of these modules are explained below.

### 1.1. API

ActiveModel::API
adds the ability for a class to work with Action
Pack and Action
View right out of the box.

When including ActiveModel::API, other modules are included by default which
enables you to get features like:

- Attribute Assignment

- Conversion

- Naming

- Translation

- Validations

Here is an example of a class that includes ActiveModel::API and how it can be
used:

```ruby
class EmailContact
  include ActiveModel::API

  attr_accessor :name, :email, :message
  validates :name, :email, :message, presence: true

  def deliver
    if valid?
      # Deliver email
    end
  end
end
```

```
irb> email_contact = EmailContact.new(name: "David", email: "david@example.com", message: "Hello World")

irb> email_contact.name # Attribute Assignment
=> "David"

irb> email_contact.to_model == email_contact # Conversion
=> true

irb> email_contact.model_name.name # Naming
=> "EmailContact"

irb> EmailContact.human_attribute_name("name") # Translation if the locale is set
=> "Name"

irb> email_contact.valid? # Validations
=> true

irb> empty_contact = EmailContact.new
irb> empty_contact.valid?
=> false
```

Any class that includes ActiveModel::API can be used with form_with,
render and any other Action View helper
methods, just like
Active Record objects.

For example, form_with can be used to create a form for an EmailContact
object as follows:

```ruby
<%= form_with model: EmailContact.new do |form| %>
  <%= form.text_field :name %>
<% end %>
```

which results in the following HTML:

```html
<form action="/email_contacts" method="post">
  <input type="text" name="email_contact[name]" id="email_contact_name">
</form>
```

render can be used to render a partial with the object:

```ruby
<%= render @email_contact %>
```

You can learn more about how to use form_with and render with
ActiveModel::API compatible objects in the Action View Form
Helpers and Layouts and
Rendering
guides, respectively.

### 1.2. Model

ActiveModel::Model
includes ActiveModel::API to interact with Action Pack and Action View
by default, and is the recommended approach to implement model-like Ruby
classes. It will be extended in the future to add more functionality.

```ruby
class Person
  include ActiveModel::Model

  attr_accessor :name, :age
end
```

```
irb> person = Person.new(name: 'bob', age: '18')
irb> person.name # => "bob"
irb> person.age  # => "18"
```

### 1.3. Attributes

ActiveModel::Attributes
allows you to define data types, set default values, and handle casting and
serialization on plain Ruby objects. This can be useful for form data which will
produce Active Record-like conversion for things like dates and booleans on
regular objects.

To use Attributes, include the module in your model class and define your
attributes using the attribute macro. It accepts a name, a cast type, a
default value, and any other options supported by the attribute type.

```ruby
class Person
  include ActiveModel::Attributes

  attribute :name, :string
  attribute :date_of_birth, :date
  attribute :active, :boolean, default: true
end
```

```
irb> person = Person.new

irb> person.name = "Jane"
irb> person.name
=> "Jane"

# Casts the string to a date set by the attribute
irb> person.date_of_birth = "2020-01-01"
irb> person.date_of_birth
=> Wed, 01 Jan 2020
irb> person.date_of_birth.class
=> Date

# Uses the default value set by the attribute
irb> person.active
=> true

# Casts the integer to a boolean set by the attribute
irb> person.active = 0
irb> person.active
=> false
```

Some additional methods described below are available when using
ActiveModel::Attributes.

#### 1.3.1. Method: attribute_names

The attribute_names method returns an array of attribute names.

```
irb> Person.attribute_names
=> ["name", "date_of_birth", "active"]
```

#### 1.3.2. Method: attributes

The attributes method returns a hash of all the attributes with their names as
keys and the values of the attributes as values.

```
irb> person.attributes
=> {"name" => "Jane", "date_of_birth" => Wed, 01 Jan 2020, "active" => false}
```

### 1.4. Attribute Assignment

ActiveModel::AttributeAssignment
allows you to set an object's attributes by passing in a hash of attributes with
keys matching the attribute names. This is useful when you want to set multiple
attributes at once.

Consider the following class:

```ruby
class Person
  include ActiveModel::AttributeAssignment

  attr_accessor :name, :date_of_birth, :active
end
```

```
irb> person = Person.new

# Set multiple attributes at once
irb> person.assign_attributes(name: "John", date_of_birth: "1998-01-01", active: false)

irb> person.name
=> "John"
irb> person.date_of_birth
=> Thu, 01 Jan 1998
irb> person.active
=> false
```

If the passed hash responds to the permitted? method and the return value of
this method is false, an ActiveModel::ForbiddenAttributesError exception is
raised.

permitted? is used for strong
params
integration whereby you are assigning a params attribute from a request.

```
irb> person = Person.new

# Using strong parameters checks, build a hash of attributes similar to params from a request
irb> params = ActionController::Parameters.new(name: "John")
=> #<ActionController::Parameters {"name" => "John"} permitted: false>

irb> person.assign_attributes(params)
=> # Raises ActiveModel::ForbiddenAttributesError
irb> person.name
=> nil

# Permit the attributes we want to allow assignment
irb> permitted_params = params.permit(:name)
=> #<ActionController::Parameters {"name" => "John"} permitted: true>

irb> person.assign_attributes(permitted_params)
irb> person.name
=> "John"
```

#### 1.4.1. Method alias: attributes=

The assign_attributes method has an alias attributes=.

A method alias is a method that performs the same action as another
method, but is called something different. Aliases exist for the sake of
readability and convenience.

The following example demonstrates the use of the attributes= method to set
multiple attributes at once:

```
irb> person = Person.new

irb> person.attributes = { name: "John", date_of_birth: "1998-01-01", active: false }

irb> person.name
=> "John"
irb> person.date_of_birth
=> "1998-01-01"
```

assign_attributes and attributes= are both method calls, and accept
the hash of attributes to assign as an argument. In many cases, Ruby allows
parens () from method calls, and curly braces {} from hash definitions, to
be omitted.
"Setter" methods like attributes= are commonly written without (), even
though including them works the same, and they require the hash to always
include {}. person.attributes=({ name: "John" }) is fine, but
person.attributes = name: "John" results in a SyntaxError.
Other method calls like assign_attributes may or may not contain both parens
() and {} for the hash argument. For example, assign_attributes name:
"John" and assign_attributes({ name: "John" }) are both perfectly valid Ruby
code, however, assign_attributes { name: "John" } is not, because Ruby can't
differentiate that hash argument from a block, and will raise a SyntaxError.

### 1.5. Attribute Methods

ActiveModel::AttributeMethods
provides a way to define methods dynamically for attributes of a model. This
module is particularly useful to simplify attribute access and manipulation, and
it can add custom prefixes and suffixes to the methods of a class. You can
define the prefixes and suffixes and which methods on the object will use them
as follows:

- Include ActiveModel::AttributeMethods in your class.

- Call each of the methods you want to add, such as attribute_method_suffix,
attribute_method_prefix, attribute_method_affix.

- Call define_attribute_methods after the other methods to declare the
attribute(s) that should be prefixed and suffixed.

- Define the various generic _attribute methods that you have declared. The
parameter attribute in these methods will be replaced by the argument
passed in define_attribute_methods. In the example below it's name.

attribute_method_prefix and attribute_method_suffix are used to define
the prefixes and suffixes that will be used to create the methods.
attribute_method_affix is used to define both the prefix and suffix at the
same time.

```ruby
class Person
  include ActiveModel::AttributeMethods

  attribute_method_affix prefix: "reset_", suffix: "_to_default!"
  attribute_method_prefix "first_", "last_"
  attribute_method_suffix "_short?"

  define_attribute_methods "name"

  attr_accessor :name

  private
    # Attribute method call for 'first_name'
    def first_attribute(attribute)
      public_send(attribute).split.first
    end

    # Attribute method call for 'last_name'
    def last_attribute(attribute)
      public_send(attribute).split.last
    end

    # Attribute method call for 'name_short?'
    def attribute_short?(attribute)
      public_send(attribute).length < 5
    end

    # Attribute method call 'reset_name_to_default!'
    def reset_attribute_to_default!(attribute)
      public_send("#{attribute}=", "Default Name")
    end
end
```

```
irb> person = Person.new
irb> person.name = "Jane Doe"

irb> person.first_name
=> "Jane"
irb> person.last_name
=> "Doe"

irb> person.name_short?
=> false

irb> person.reset_name_to_default!
=> "Default Name"
```

If you call a method that is not defined, it will raise a NoMethodError error.

#### 1.5.1. Method: alias_attribute

ActiveModel::AttributeMethods provides aliasing of attribute methods using
alias_attribute.

The example below creates an alias attribute for name called full_name. They
return the same value, but the alias full_name better reflects that the
attribute includes a first name and last name.

```ruby
class Person
  include ActiveModel::AttributeMethods

  attribute_method_suffix "_short?"
  define_attribute_methods :name

  attr_accessor :name

  alias_attribute :full_name, :name

  private
    def attribute_short?(attribute)
      public_send(attribute).length < 5
    end
end
```

```
irb> person = Person.new
irb> person.name = "Joe Doe"
irb> person.name
=> "Joe Doe"

# `full_name` is the alias for `name`, and returns the same value
irb> person.full_name
=> "Joe Doe"
irb> person.name_short?
=> false

# `full_name_short?` is the alias for `name_short?`, and returns the same value
irb> person.full_name_short?
=> false
```

### 1.6. Callbacks

ActiveModel::Callbacks
gives plain Ruby objects Active Record style
callbacks. The
callbacks allow you to hook into model lifecycle events, such as before_update
and after_create, as well as to define custom logic to be executed at specific
points in the model's lifecycle.

You can implement ActiveModel::Callbacks by following the steps below:

- Extend ActiveModel::Callbacks within your class.

- Employ define_model_callbacks to establish a list of methods that should
have callbacks associated with them. When you designate a method such as
:update, it will automatically include all three default callbacks
(before, around, and after) for the :update event.

- Inside the defined method, utilize run_callbacks, which will execute the
callback chain when the specific event is triggered.

- In your class, you can then utilize the before_update, after_update, and
around_update methods like how you would use them in an Active Record
model.

```ruby
class Person
  extend ActiveModel::Callbacks

  define_model_callbacks :update

  before_update :reset_me
  after_update :finalize_me
  around_update :log_me

  # `define_model_callbacks` method containing `run_callbacks` which runs the callback(s) for the given event
  def update
    run_callbacks(:update) do
      puts "update method called"
    end
  end

  private
    # When update is called on an object, then this method is called by `before_update` callback
    def reset_me
      puts "reset_me method: called before the update method"
    end

    # When update is called on an object, then this method is called by `after_update` callback
    def finalize_me
      puts "finalize_me method: called after the update method"
    end

    # When update is called on an object, then this method is called by `around_update` callback
    def log_me
      puts "log_me method: called around the update method"
      yield
      puts "log_me method: block successfully called"
    end
end
```

The above class will yield the following which indicates the order in which the
callbacks are being called:

```
irb> person = Person.new
irb> person.update
reset_me method: called before the update method
log_me method: called around the update method
update method called
log_me method: block successfully called
finalize_me method: called after the update method
=> nil
```

As per the above example, when defining an 'around' callback remember to yield
to the block, otherwise, it won't be executed.

method_name passed to define_model_callbacks must not end with !,
? or =. In addition, defining the same callback multiple times will
overwrite previous callback definitions.

#### 1.6.1. Defining Specific Callbacks

You can choose to create specific callbacks by passing the only option to the
define_model_callbacks method:

```ruby
define_model_callbacks :update, :create, only: [:after, :before]
```

This will create only the before_create / after_create and before_update /
 after_update callbacks, but skip the around_* ones. The option will apply
to all callbacks defined on that method call. It's possible to call
define_model_callbacks multiple times, to specify different lifecycle events:

```ruby
define_model_callbacks :create, only: :after
define_model_callbacks :update, only: :before
define_model_callbacks :destroy, only: :around
```

This will create after_create, before_update, and around_destroy methods
only.

#### 1.6.2. Defining Callbacks with a Class

You can pass a class to before_<type>, after_<type> and around_<type> for
more control over when and in what context your callbacks are triggered. The
callback will trigger that class's <action>_<type> method, passing an instance
of the class as an argument.

```ruby
class Person
  extend ActiveModel::Callbacks

  define_model_callbacks :create
  before_create PersonCallbacks
end

class PersonCallbacks
  def self.before_create(obj)
    # `obj` is the Person instance that the callback is being called on
  end
end
```

#### 1.6.3. Aborting Callbacks

The callback chain can be aborted at any point in time by throwing :abort.
This is similar to how Active Record callbacks work.

In the example below, since we throw :abort before an update in the reset_me
method, the remaining callback chain including before_update will be aborted,
and the body of the update method won't be executed.

```ruby
class Person
  extend ActiveModel::Callbacks

  define_model_callbacks :update

  before_update :reset_me
  after_update :finalize_me
  around_update :log_me

  def update
    run_callbacks(:update) do
      puts "update method called"
    end
  end

  private
    def reset_me
      puts "reset_me method: called before the update method"
      throw :abort
      puts "reset_me method: some code after abort"
    end

    def finalize_me
      puts "finalize_me method: called after the update method"
    end

    def log_me
      puts "log_me method: called around the update method"
      yield
      puts "log_me method: block successfully called"
    end
end
```

```
irb> person = Person.new

irb> person.update
reset_me method: called before the update method
=> false
```

### 1.7. Conversion

ActiveModel::Conversion
is a collection of methods that allow you to convert your object to different
forms for different purposes. A common use case is to convert your object to a
string or an integer to build URLs, form fields, and more.

The ActiveModel::Conversion module adds the following methods: to_model,
to_key, to_param, and to_partial_path to classes.

The return values of the methods depend on whether persisted? is defined and
if an id is provided. The persisted? method should return true if the
object has been saved to the database or store, otherwise, it should return
false. The id should reference the id of the object or nil if the object is
not saved.

```ruby
class Person
  include ActiveModel::Conversion
  attr_accessor :id

  def initialize(id)
    @id = id
  end

  def persisted?
    id.present?
  end
end
```

#### 1.7.1. to_model

The to_model method returns the object itself.

```
irb> person = Person.new(1)
irb> person.to_model == person
=> true
```

If your model does not act like an Active Model object, then you should define
:to_model yourself returning a proxy object that wraps your object with Active
Model compliant methods.

```ruby
class Person
  def to_model
    # A proxy object that wraps your object with Active Model compliant methods.
    PersonModel.new(self)
  end
end
```

#### 1.7.2. to_key

The to_key method returns an array of the object's key attributes if any of
the attributes are set, whether or not the object is persisted. Returns nil if
there are no key attributes.

```
irb> person.to_key
=> [1]
```

A key attribute is an attribute that is used to identify the object. For
example, in a database-backed model, the key attribute is the primary key.

#### 1.7.3. to_param

The to_param method returns a string representation of the object's key
suitable for use in URLs, or nil in the case where persisted? is false.

```
irb> person.to_param
=> "1"
```

#### 1.7.4. to_partial_path

The to_partial_path method returns a string representing the path associated
with the object. Action Pack uses this to find a suitable partial to represent
the object.

```
irb> person.to_partial_path
=> "people/person"
```

### 1.8. Dirty

ActiveModel::Dirty
is useful for tracking changes made to model attributes before they are saved.
This functionality allows you to determine which attributes have been modified,
what their previous and current values are, and perform actions based on those
changes. It's particularly handy for auditing, validation, and conditional logic
within your application. It provides a way to track changes in your object in
the same way as Active Record.

An object becomes dirty when it has gone through one or more changes to its
attributes and has not been saved. It has attribute-based accessor methods.

To use ActiveModel::Dirty, you need to:

- Include the module in your class.

- Define the attribute methods that you want to track changes for, using
define_attribute_methods.

- Call [attr_name]_will_change! before each change to the tracked attribute.

- Call changes_applied after the changes are persisted.

- Call clear_changes_information when you want to reset the changes
information.

- Call restore_attributes when you want to restore previous data.

You can then use the methods provided by ActiveModel::Dirty to query the
object for its list of all changed attributes, the original values of the
changed attributes, and the changes made to the attributes.

Let's consider a Person class with attributes first_name and last_name and
determine how we can use ActiveModel::Dirty to track changes to these
attributes.

```ruby
class Person
  include ActiveModel::Dirty

  attr_reader :first_name, :last_name
  define_attribute_methods :first_name, :last_name

  def initialize
    @first_name = nil
    @last_name = nil
  end

  def first_name=(value)
    first_name_will_change! unless value == @first_name
    @first_name = value
  end

  def last_name=(value)
    last_name_will_change! unless value == @last_name
    @last_name = value
  end

  def save
    # Persist data - clears dirty data and moves `changes` to `previous_changes`.
    changes_applied
  end

  def reload!
    # Clears all dirty data: current changes and previous changes.
    clear_changes_information
  end

  def rollback!
    # Restores all previous data of the provided attributes.
    restore_attributes
  end
end
```

#### 1.8.1. Querying an Object Directly for its List of All Changed Attributes

```
irb> person = Person.new

# A newly instantiated `Person` object is unchanged:
irb> person.changed?
=> false

irb> person.first_name = "Jane Doe"
irb> person.first_name
=> "Jane Doe"
```

changed? returns true if any of the attributes have unsaved changes,
false otherwise.

```
irb> person.changed?
=> true
```

changed returns an array with the name of the attributes containing
unsaved changes.

```
irb> person.changed
=> ["first_name"]
```

changed_attributes returns a hash of the attributes with unsaved changes
indicating their original values like attr => original value.

```
irb> person.changed_attributes
=> {"first_name" => nil}
```

changes returns a hash of changes, with the attribute names as the keys,
and the values as an array of the original and new values like attr => [original value, new value].

```
irb> person.changes
=> {"first_name" => [nil, "Jane Doe"]}
```

previous_changes returns a hash of attributes that were changed before the
model was saved (i.e. before changes_applied is called).

```
irb> person.previous_changes
=> {}

irb> person.save
irb> person.previous_changes
=> {"first_name" => [nil, "Jane Doe"]}
```

#### 1.8.2. Attribute-based Accessor Methods

```
irb> person = Person.new

irb> person.changed?
=> false

irb> person.first_name = "John Doe"
irb> person.first_name
=> "John Doe"
```

[attr_name]_changed? checks whether the particular attribute has been
changed or not.

```
irb> person.first_name_changed?
=> true
```

[attr_name]_was tracks the previous value of the attribute.

```
irb> person.first_name_was
=> nil
```

[attr_name]_change tracks both the previous and current values of the
changed attribute. Returns an array with [original value, new value] if
changed, otherwise returns nil.

```
irb> person.first_name_change
=> [nil, "John Doe"]
irb> person.last_name_change
=> nil
```

[attr_name]_previously_changed? checks whether the particular attribute
has been changed before the model was saved (i.e. before changes_applied is
called).

```
irb> person.first_name_previously_changed?
=> false
irb> person.save
irb> person.first_name_previously_changed?
=> true
```

[attr_name]_previous_change tracks both previous and current values of the
changed attribute before the model was saved (i.e. before changes_applied is
called). Returns an array with [original value, new value] if changed,
otherwise returns nil.

```
irb> person.first_name_previous_change
=> [nil, "John Doe"]
```

### 1.9. Naming

ActiveModel::Naming
adds a class method and helper methods to make naming and routing easier to
manage. The module defines the model_name class method which will define
several accessors using some
ActiveSupport::Inflector
methods.

```ruby
class Person
  extend ActiveModel::Naming
end
```

name returns the name of the model.

```
irb> Person.model_name.name
=> "Person"
```

singular returns the singular class name of a record or class.

```
irb> Person.model_name.singular
=> "person"
```

plural returns the plural class name of a record or class.

```
irb> Person.model_name.plural
=> "people"
```

element removes the namespace and returns the singular snake_cased name.
It is generally used by Action Pack and/or Action View helpers to aid in
rendering the name of partials/forms.

```
irb> Person.model_name.element
=> "person"
```

human transforms the model name into a more human format, using I18n. By
default, it will underscore and then humanize the class name.

```
irb> Person.model_name.human
=> "Person"
```

collection removes the namespace and returns the plural snake_cased name.
It is generally used by Action Pack and/or Action View helpers to aid in
rendering the name of partials/forms.

```
irb> Person.model_name.collection
=> "people"
```

param_key returns a string to use for params names.

```
irb> Person.model_name.param_key
=> "person"
```

i18n_key returns the name of the i18n key. It underscores the model name
and then returns it as a symbol.

```
irb> Person.model_name.i18n_key
=> :person
```

route_key returns a string to use while generating route names.

```
irb> Person.model_name.route_key
=> "people"
```

singular_route_key returns a string to use while generating route names.

```
irb> Person.model_name.singular_route_key
=> "person"
```

uncountable? identifies whether the class name of a record or class is
uncountable.

```
irb> Person.model_name.uncountable?
=> false
```

Some Naming methods, like param_key, route_key and
singular_route_key, differ for namespaced models based on whether it's inside
an isolated Engine.

#### 1.9.1. Customize the Name of the Model

Sometimes you may want to customize the name of the model that is used in form
helpers and URL generation. This can be useful in situations where you want to
use a more user-friendly name for the model, while still being able to reference
it using its full namespace.

For example, let's say you have a Person namespace in your Rails application,
and you want to create a form for a new Person::Profile.

By default, Rails would generate the form with the URL /person/profiles, which
includes the namespace person. However, if you want the URL to simply point to
profiles without the namespace, you can customize the model_name method like
this:

```ruby
module Person
  class Profile
    include ActiveModel::Model

    def self.model_name
      ActiveModel::Name.new(self, nil, "Profile")
    end
  end
end
```

With this setup, when you use the form_with helper to create a form for
creating a new Person::Profile, Rails will generate the form with the URL
/profiles instead of /person/profiles, because the model_name method has
been overridden to return Profile.

In addition, the path helpers will be generated without the namespace, so you
can use profiles_path instead of person_profiles_path to generate the URL
for the profiles resource. To use the profiles_path helper, you need to
define the routes for the Person::Profile model in your config/routes.rb
file like this:

```ruby
Rails.application.routes.draw do
  resources :profiles
end
```

Consequently, you can expect the model to return the following values for
methods that were described in the previous section:

```
irb> name = ActiveModel::Name.new(Person::Profile, nil, "Profile")
=> #<ActiveModel::Name:0x000000014c5dbae0

irb> name.singular
=> "profile"
irb> name.singular_route_key
=> "profile"
irb> name.route_key
=> "profiles"
```

### 1.10. SecurePassword

ActiveModel::SecurePassword
provides a way to securely store any password in an encrypted form. When you
include this module, a has_secure_password class method is provided which
defines a password accessor with certain validations on it by default.

ActiveModel::SecurePassword depends on
bcrypt, so include this
gem in your Gemfile to use it.

```ruby
gem "bcrypt"
```

ActiveModel::SecurePassword requires you to have a password_digest
attribute.

The following validations are added automatically:

- Password must be present on creation.

- Confirmation of password (using a password_confirmation attribute).

- The maximum length of a password is 72 bytes (required as bcrypt truncates
the string to this size before encrypting it).

If password confirmation validation is not needed, simply leave out the
value for password_confirmation (i.e. don't provide a form field for it). When
this attribute has a nil value, the validation will not be triggered.

For further customization, it is possible to suppress the default validations by
passing validations: false as an argument.

```ruby
class Person
  include ActiveModel::SecurePassword

  has_secure_password
  has_secure_password :recovery_password, validations: false

  attr_accessor :password_digest, :recovery_password_digest
end
```

```
irb> person = Person.new

# When password is blank.
irb> person.valid?
=> false

# When the confirmation doesn't match the password.
irb> person.password = "aditya"
irb> person.password_confirmation = "nomatch"
irb> person.valid?
=> false

# When the length of password exceeds 72.
irb> person.password = person.password_confirmation = "a" * 100
irb> person.valid?
=> false

# When only password is supplied with no password_confirmation.
irb> person.password = "aditya"
irb> person.valid?
=> true

# When all validations are passed.
irb> person.password = person.password_confirmation = "aditya"
irb> person.valid?
=> true

irb> person.recovery_password = "42password"

# `authenticate` is an alias for `authenticate_password`
irb> person.authenticate("aditya")
=> #<Person> # == person
irb> person.authenticate("notright")
=> false
irb> person.authenticate_password("aditya")
=> #<Person> # == person
irb> person.authenticate_password("notright")
=> false

irb> person.authenticate_recovery_password("aditya")
=> false
irb> person.authenticate_recovery_password("42password")
=> #<Person> # == person
irb> person.authenticate_recovery_password("notright")
=> false

irb> person.password_digest
=> "$2a$04$gF8RfZdoXHvyTjHhiU4ZsO.kQqV9oonYZu31PRE4hLQn3xM2qkpIy"
irb> person.recovery_password_digest
=> "$2a$04$iOfhwahFymCs5weB3BNH/uXkTG65HR.qpW.bNhEjFP3ftli3o5DQC"
```

### 1.11. Serialization

ActiveModel::Serialization
provides basic serialization for your object. You need to declare an attributes
hash that contains the attributes you want to serialize. Attributes must be
strings, not symbols.

```ruby
class Person
  include ActiveModel::Serialization

  attr_accessor :name, :age

  def attributes
    # Declaration of attributes that will be serialized
    { "name" => nil, "age" => nil }
  end

  def capitalized_name
    # Declared methods can be later included in the serialized hash
    name&.capitalize
  end
end
```

Now you can access a serialized hash of your object using the
serializable_hash method. Valid options for serializable_hash include
:only, :except, :methods and :include.

```
irb> person = Person.new

irb> person.serializable_hash
=> {"name" => nil, "age" => nil}

# Set the name and age attributes and serialize the object
irb> person.name = "bob"
irb> person.age = 22
irb> person.serializable_hash
=> {"name" => "bob", "age" => 22}

# Use the methods option to include the capitalized_name method
irb>  person.serializable_hash(methods: :capitalized_name)
=> {"name" => "bob", "age" => 22, "capitalized_name" => "Bob"}

# Use the only method to include only the name attribute
irb> person.serializable_hash(only: :name)
=> {"name" => "bob"}

# Use the except method to exclude the name attribute
irb> person.serializable_hash(except: :name)
=> {"age" => 22}
```

The example to utilize the includes option requires a slightly more complex
scenario as defined below:

```ruby
class Person
    include ActiveModel::Serialization
    attr_accessor :name, :notes # Emulate has_many :notes

    def attributes
      { "name" => nil }
    end
  end

  class Note
    include ActiveModel::Serialization
    attr_accessor :title, :text

    def attributes
      { "title" => nil, "text" => nil }
    end
  end
```

```
irb> note = Note.new
irb> note.title = "Weekend Plans"
irb> note.text = "Some text here"

irb> person = Person.new
irb> person.name = "Napoleon"
irb> person.notes = [note]

irb> person.serializable_hash
=> {"name" => "Napoleon"}

irb> person.serializable_hash(include: { notes: { only: "title" }})
=> {"name" => "Napoleon", "notes" => [{"title" => "Weekend Plans"}]}
```

#### 1.11.1. ActiveModel::Serializers::JSON

Active Model also provides the
ActiveModel::Serializers::JSON
module for JSON serializing / deserializing.

To use the JSON serialization, change the module you are including from
ActiveModel::Serialization to ActiveModel::Serializers::JSON. It already
includes the former, so there is no need to explicitly include it.

```ruby
class Person
  include ActiveModel::Serializers::JSON

  attr_accessor :name

  def attributes
    { "name" => nil }
  end
end
```

The as_json method, similar to serializable_hash, provides a hash
representing the model with its keys as a string. The to_json method returns a
JSON string representing the model.

```
irb> person = Person.new

# A hash representing the model with its keys as a string
irb> person.as_json
=> {"name" => nil}

# A JSON string representing the model
irb> person.to_json
=> "{\"name\":null}"

irb> person.name = "Bob"
irb> person.as_json
=> {"name" => "Bob"}

irb> person.to_json
=> "{\"name\":\"Bob\"}"
```

You can also define the attributes for a model from a JSON string. To do that,
first define the attributes= method in your class:

```ruby
class Person
  include ActiveModel::Serializers::JSON

  attr_accessor :name

  def attributes=(hash)
    hash.each do |key, value|
      public_send("#{key}=", value)
    end
  end

  def attributes
    { "name" => nil }
  end
end
```

Now it is possible to create an instance of Person and set attributes using
from_json.

```
irb> json = { name: "Bob" }.to_json
=> "{\"name\":\"Bob\"}"

irb> person = Person.new

irb> person.from_json(json)
=> #<Person:0x00000100c773f0 @name="Bob">

irb> person.name
=> "Bob"
```

### 1.12. Translation

ActiveModel::Translation
provides integration between your object and the Rails internationalization
(i18n) framework.

```ruby
class Person
  extend ActiveModel::Translation
end
```

With the human_attribute_name method, you can transform attribute names into a
more human-readable format. The human-readable format is defined in your locale
file(s).

```yaml
# config/locales/app.pt-BR.yml
pt-BR:
  activemodel:
    attributes:
      person:
        name: "Nome"
```

```
irb> Person.human_attribute_name("name")
=> "Name"

irb> I18n.locale = :"pt-BR"
=> :"pt-BR"
irb> Person.human_attribute_name("name")
=> "Nome"
```

### 1.13. Validations

ActiveModel::Validations
adds the ability to validate objects and it is important for ensuring data
integrity and consistency within your application. By incorporating validations
into your models, you can define rules that govern the correctness of attribute
values, and prevent invalid data.

```ruby
class Person
  include ActiveModel::Validations

  attr_accessor :name, :email, :token

  validates :name, presence: true
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates! :token, presence: true
end
```

```
irb> person = Person.new
irb> person.token = "2b1f325"
irb> person.valid?
=> false

irb> person.name = "Jane Doe"
irb> person.email = "me"
irb> person.valid?
=> false

irb> person.email = "jane.doe@gmail.com"
irb> person.valid?
=> true

# `token` uses validate! and will raise an exception when not set.
irb> person.token = nil
irb> person.valid?
=> "Token can't be blank (ActiveModel::StrictValidationFailed)"
```

#### 1.13.1. Validation Methods and Options

You can add validations using some of the following methods:

- validate:
Adds validation through a method or a block to the class.

- validates:
An attribute can be passed to the validates method and it provides a
shortcut to all default validators.

- validates!
or setting strict: true: Used to define validations that cannot be corrected
by end users and are considered exceptional. Each validator defined with a
bang or :strict option set to true will always raise
ActiveModel::StrictValidationFailed instead of adding to the errors when
validation fails.

- validates_with:
Passes the record off to the class or classes specified and allows them to add
errors based on more complex conditions.

- validates_each:
Validates each attribute against a block.

validate:
Adds validation through a method or a block to the class.

validates:
An attribute can be passed to the validates method and it provides a
shortcut to all default validators.

validates!
or setting strict: true: Used to define validations that cannot be corrected
by end users and are considered exceptional. Each validator defined with a
bang or :strict option set to true will always raise
ActiveModel::StrictValidationFailed instead of adding to the errors when
validation fails.

validates_with:
Passes the record off to the class or classes specified and allows them to add
errors based on more complex conditions.

validates_each:
Validates each attribute against a block.

Some of the options below can be used with certain validators. To determine if
the option you're using can be used with a specific validator, read through the
validation
documentation.

- :on: Specifies the context in which to add the validation. You can pass a
symbol or an array of symbols. (e.g. on: :create or on:
:custom_validation_context or on: [:create, :custom_validation_context]).
Validations without an :on option will run no matter the context. Validations
with some :on option will only run in the specified context. You can pass the
context when validating via valid?(:context).

- :if: Specifies a method, proc or string to call to determine if the
validation should occur (e.g. if: :allow_validation, or if: -> {
signup_step > 2 }). The method, proc or string should return or evaluate to a
true or false value.

- :unless: Specifies a method, proc or string to call to determine if the
validation should not occur (e.g. unless: :skip_validation, or unless:
Proc.new { |user| user.signup_step <= 2 }). The method, proc or string should
return or evaluate to a true or false value.

- :allow_nil: Skip the validation if the attribute is nil.

- :allow_blank: Skip the validation if the attribute is blank.

- :strict: If the :strict option is set to true, it will raise
ActiveModel::StrictValidationFailed instead of adding the error. :strict
option can also be set to any other exception.

:on: Specifies the context in which to add the validation. You can pass a
symbol or an array of symbols. (e.g. on: :create or on:
:custom_validation_context or on: [:create, :custom_validation_context]).
Validations without an :on option will run no matter the context. Validations
with some :on option will only run in the specified context. You can pass the
context when validating via valid?(:context).

:if: Specifies a method, proc or string to call to determine if the
validation should occur (e.g. if: :allow_validation, or if: -> {
signup_step > 2 }). The method, proc or string should return or evaluate to a
true or false value.

:unless: Specifies a method, proc or string to call to determine if the
validation should not occur (e.g. unless: :skip_validation, or unless:
Proc.new { |user| user.signup_step <= 2 }). The method, proc or string should
return or evaluate to a true or false value.

:allow_nil: Skip the validation if the attribute is nil.

:allow_blank: Skip the validation if the attribute is blank.

:strict: If the :strict option is set to true, it will raise
ActiveModel::StrictValidationFailed instead of adding the error. :strict
option can also be set to any other exception.

Calling validate multiple times on the same method will overwrite
previous definitions.

#### 1.13.2. Errors

ActiveModel::Validations automatically adds an errors method to your
instances initialized with a new
ActiveModel::Errors
object, so there is no need for you to do this manually.

Run valid? on the object to check if the object is valid or not. If the object
is not valid, it will return false and the errors will be added to the
errors object.

```
irb> person = Person.new

irb> person.email = "me"
irb> person.valid?
=> # Raises Token can't be blank (ActiveModel::StrictValidationFailed)

irb> person.errors.to_hash
=> {:name => ["can't be blank"], :email => ["is invalid"]}

irb> person.errors.full_messages
=> ["Name can't be blank", "Email is invalid"]
```

### 1.14. Lint Tests

ActiveModel::Lint::Tests
allows you to test whether an object is compliant with the Active Model API. By
including ActiveModel::Lint::Tests in your TestCase, it will include tests
that tell you whether your object is fully compliant, or if not, which aspects
of the API are not implemented.

These tests do not attempt to determine the semantic correctness of the returned
values. For instance, you could implement valid? to always return true, and
the tests would pass. It is up to you to ensure that the values are semantically
meaningful.

Objects you pass in are expected to return a compliant object from a call to
to_model. It is perfectly fine for to_model to return self.

- app/models/person.rb
class Person
  include ActiveModel::API
end

- test/models/person_test.rb
require "test_helper"

class PersonTest < ActiveSupport::TestCase
  include ActiveModel::Lint::Tests

  setup do
    @model = Person.new
  end
end

app/models/person.rb

```ruby
class Person
  include ActiveModel::API
end
```

test/models/person_test.rb

```ruby
require "test_helper"

class PersonTest < ActiveSupport::TestCase
  include ActiveModel::Lint::Tests

  setup do
    @model = Person.new
  end
end
```

See the test methods
documentation
for more details.

To run the tests you can use the following command:

```bash
$ bin/rails test

Run options: --seed 14596

# Running:

......

Finished in 0.024899s, 240.9735 runs/s, 1204.8677 assertions/s.

6 runs, 30 assertions, 0 failures, 0 errors, 0 skips
```

---

# Chapters


---

This guide covers PostgreSQL specific usage of Active Record.

After reading this guide, you will know:

- How to use PostgreSQL's datatypes.

- How to use UUID primary keys.

- How to include non-key columns in indexes.

- How to use deferrable foreign keys.

- How to use unique constraints.

- How to implement exclusion constraints.

- How to implement full text search with PostgreSQL.

- How to back your Active Record models with database views.

In order to use the PostgreSQL adapter you need to have at least version 9.3
installed. Older versions are not supported.

To get started with PostgreSQL have a look at the
configuring Rails guide.
It describes how to properly set up Active Record for PostgreSQL.

## 1. Datatypes

PostgreSQL offers a number of specific datatypes. Following is a list of types,
that are supported by the PostgreSQL adapter.

### 1.1. Bytea

- type definition

- functions and operators

```ruby
# db/migrate/20140207133952_create_documents.rb
create_table :documents do |t|
  t.binary "payload"
end
```

```ruby
# app/models/document.rb
class Document < ApplicationRecord
end
```

```ruby
# Usage
data = File.read(Rails.root + "tmp/output.pdf")
Document.create payload: data
```

### 1.2. Array

- type definition

- functions and operators

```ruby
# db/migrate/20140207133952_create_books.rb
create_table :books do |t|
  t.string "title"
  t.string "tags", array: true
  t.integer "ratings", array: true
end
add_index :books, :tags, using: "gin"
add_index :books, :ratings, using: "gin"
```

```ruby
# app/models/book.rb
class Book < ApplicationRecord
end
```

```ruby
# Usage
Book.create title: "Brave New World",
            tags: ["fantasy", "fiction"],
            ratings: [4, 5]

## Books for a single tag
Book.where("'fantasy' = ANY (tags)")

## Books for multiple tags
Book.where("tags @> ARRAY[?]::varchar[]", ["fantasy", "fiction"])

## Books with 3 or more ratings
Book.where("array_length(ratings, 1) >= 3")
```

### 1.3. Hstore

- type definition

- functions and operators

You need to enable the hstore extension to use hstore.

```ruby
# db/migrate/20131009135255_create_profiles.rb
class CreateProfiles < ActiveRecord::Migration[8.1]
  enable_extension "hstore" unless extension_enabled?("hstore")
  create_table :profiles do |t|
    t.hstore "settings"
  end
end
```

```ruby
# app/models/profile.rb
class Profile < ApplicationRecord
end
```

```
irb> Profile.create(settings: { "color" => "blue", "resolution" => "800x600" })

irb> profile = Profile.first
irb> profile.settings
=> {"color"=>"blue", "resolution"=>"800x600"}

irb> profile.settings = {"color" => "yellow", "resolution" => "1280x1024"}
irb> profile.save!

irb> Profile.where("settings->'color' = ?", "yellow")
=> #<ActiveRecord::Relation [#<Profile id: 1, settings: {"color"=>"yellow", "resolution"=>"1280x1024"}>]>
```

### 1.4. JSON and JSONB

- type definition

- functions and operators

```ruby
# db/migrate/20131220144913_create_events.rb
# ... for json datatype:
create_table :events do |t|
  t.json "payload"
end
# ... or for jsonb datatype:
create_table :events do |t|
  t.jsonb "payload"
end
```

```ruby
# app/models/event.rb
class Event < ApplicationRecord
end
```

```
irb> Event.create(payload: { kind: "user_renamed", change: ["jack", "john"]})

irb> event = Event.first
irb> event.payload
=> {"kind"=>"user_renamed", "change"=>["jack", "john"]}

## Query based on JSON document
# The -> operator returns the original JSON type (which might be an object), whereas ->> returns text
irb> Event.where("payload->>'kind' = ?", "user_renamed")
```

### 1.5. Range Types

- type definition

- functions and operators

This type is mapped to Ruby Range objects.

```ruby
# db/migrate/20130923065404_create_events.rb
create_table :events do |t|
  t.daterange "duration"
end
```

```ruby
# app/models/event.rb
class Event < ApplicationRecord
end
```

```
irb> Event.create(duration: Date.new(2014, 2, 11)..Date.new(2014, 2, 12))

irb> event = Event.first
irb> event.duration
=> Tue, 11 Feb 2014...Thu, 13 Feb 2014

## All Events on a given date
irb> Event.where("duration @> ?::date", Date.new(2014, 2, 12))

## Working with range bounds
irb> event = Event.select("lower(duration) AS starts_at").select("upper(duration) AS ends_at").first

irb> event.starts_at
=> Tue, 11 Feb 2014
irb> event.ends_at
=> Thu, 13 Feb 2014
```

### 1.6. Composite Types

- type definition

Currently there is no special support for composite types. They are mapped to
normal text columns:

```sql
CREATE TYPE full_address AS
(
  city VARCHAR(90),
  street VARCHAR(90)
);
```

```ruby
# db/migrate/20140207133952_create_contacts.rb
execute <<-SQL
  CREATE TYPE full_address AS
  (
    city VARCHAR(90),
    street VARCHAR(90)
  );
SQL
create_table :contacts do |t|
  t.column :address, :full_address
end
```

```ruby
# app/models/contact.rb
class Contact < ApplicationRecord
end
```

```
irb> Contact.create address: "(Paris,Champs-Élysées)"
irb> contact = Contact.first
irb> contact.address
=> "(Paris,Champs-Élysées)"
irb> contact.address = "(Paris,Rue Basse)"
irb> contact.save!
```

### 1.7. Enumerated Types

- type definition

The type can be mapped as a normal text column, or to an ActiveRecord::Enum.

```ruby
# db/migrate/20131220144913_create_articles.rb
def change
  create_enum :article_status, ["draft", "published", "archived"]

  create_table :articles do |t|
    t.enum :status, enum_type: :article_status, default: "draft", null: false
  end
end
```

You can also create an enum type and add an enum column to an existing table:

```ruby
# db/migrate/20230113024409_add_status_to_articles.rb
def change
  create_enum :article_status, ["draft", "published", "archived"]

  add_column :articles, :status, :enum, enum_type: :article_status, default: "draft", null: false
end
```

The above migrations are both reversible, but you can define separate #up and #down methods if required. Make sure you remove any columns or tables that depend on the enum type before dropping it:

```ruby
def down
  drop_table :articles

  # OR: remove_column :articles, :status
  drop_enum :article_status
end
```

Declaring an enum attribute in the model adds helper methods and prevents invalid values from being assigned to instances of the class:

```ruby
# app/models/article.rb
class Article < ApplicationRecord
  enum :status, {
    draft: "draft", published: "published", archived: "archived"
  }, prefix: true
end
```

```
irb> article = Article.create
irb> article.status
=> "draft" # default status from PostgreSQL, as defined in migration above

irb> article.status_published!
irb> article.status
=> "published"

irb> article.status_archived?
=> false

irb> article.status = "deleted"
ArgumentError: 'deleted' is not a valid status
```

To rename the enum you can use rename_enum along with updating any model
usage:

```ruby
# db/migrate/20150718144917_rename_article_status.rb
def change
  rename_enum :article_status, :article_state
end
```

To add a new value you can use add_enum_value:

```ruby
# db/migrate/20150720144913_add_new_state_to_articles.rb
def up
  add_enum_value :article_state, "archived" # will be at the end after published
  add_enum_value :article_state, "in review", before: "published"
  add_enum_value :article_state, "approved", after: "in review"
  add_enum_value :article_state, "rejected", if_not_exists: true # won't raise an error if the value already exists
end
```

Enum values can't be dropped, which also means add_enum_value is irreversible. You can read why here.

To rename a value you can use rename_enum_value:

```ruby
# db/migrate/20150722144915_rename_article_state.rb
def change
  rename_enum_value :article_state, from: "archived", to: "deleted"
end
```

Hint: to show all the values of the all enums you have, you can call this query in bin/rails db or psql console:

```sql
SELECT n.nspname AS enum_schema,
       t.typname AS enum_name,
       e.enumlabel AS enum_value
  FROM pg_type t
      JOIN pg_enum e ON t.oid = e.enumtypid
      JOIN pg_catalog.pg_namespace n ON n.oid = t.typnamespace
```

### 1.8. UUID

- type definition

- pgcrypto generator function

- uuid-ossp generator functions

If you're using PostgreSQL earlier than version 13.0 you may need to enable special extensions to use UUIDs. Enable the pgcrypto extension (PostgreSQL >= 9.4) or uuid-ossp extension (for even earlier releases).

```ruby
# db/migrate/20131220144913_create_revisions.rb
create_table :revisions do |t|
  t.uuid :identifier
end
```

```ruby
# app/models/revision.rb
class Revision < ApplicationRecord
end
```

```
irb> Revision.create identifier: "A0EEBC99-9C0B-4EF8-BB6D-6BB9BD380A11"

irb> revision = Revision.first
irb> revision.identifier
=> "a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11"
```

You can use uuid type to define references in migrations:

```ruby
# db/migrate/20150418012400_create_blog.rb
enable_extension "pgcrypto" unless extension_enabled?("pgcrypto")
create_table :posts, id: :uuid

create_table :comments, id: :uuid do |t|
  # t.belongs_to :post, type: :uuid
  t.references :post, type: :uuid
end
```

```ruby
# app/models/post.rb
class Post < ApplicationRecord
  has_many :comments
end
```

```ruby
# app/models/comment.rb
class Comment < ApplicationRecord
  belongs_to :post
end
```

See this section for more details on using UUIDs as primary key.

### 1.9. Bit String Types

- type definition

- functions and operators

```ruby
# db/migrate/20131220144913_create_users.rb
create_table :users, force: true do |t|
  t.column :settings, "bit(8)"
end
```

```ruby
# app/models/user.rb
class User < ApplicationRecord
end
```

```
irb> User.create settings: "01010011"
irb> user = User.first
irb> user.settings
=> "01010011"
irb> user.settings = "0xAF"
irb> user.settings
=> "10101111"
irb> user.save!
```

### 1.10. Network Address Types

- type definition

The types inet and cidr are mapped to Ruby
IPAddr
objects. The macaddr type is mapped to normal text.

```ruby
# db/migrate/20140508144913_create_devices.rb
create_table(:devices, force: true) do |t|
  t.inet "ip"
  t.cidr "network"
  t.macaddr "address"
end
```

```ruby
# app/models/device.rb
class Device < ApplicationRecord
end
```

```
irb> macbook = Device.create(ip: "192.168.1.12", network: "192.168.2.0/24", address: "32:01:16:6d:05:ef")

irb> macbook.ip
=> #<IPAddr: IPv4:192.168.1.12/255.255.255.255>

irb> macbook.network
=> #<IPAddr: IPv4:192.168.2.0/255.255.255.0>

irb> macbook.address
=> "32:01:16:6d:05:ef"
```

### 1.11. Geometric Types

- type definition

All geometric types, with the exception of points are mapped to normal text.
A point is cast to an array containing x and y coordinates.

### 1.12. Interval

- type definition

- functions and operators

This type is mapped to ActiveSupport::Duration objects.

```ruby
# db/migrate/20200120000000_create_events.rb
create_table :events do |t|
  t.interval "duration"
end
```

```ruby
# app/models/event.rb
class Event < ApplicationRecord
end
```

```
irb> Event.create(duration: 2.days)

irb> event = Event.first
irb> event.duration
=> 2 days
```

### 1.13. Timestamps

- Date/Time Types

Rails migrations with timestamps store the time a model was created or updated. By default and for legacy reasons, the columns use the timestamp without time zone data type.

```ruby
# db/migrate/20241220144913_create_devices.rb
create_table :post, id: :uuid do |t|
  t.datetime :published_at
  # By default, Active Record will set the data type of this column to `timestamp without time zone`.
end
```

While this works ok, PostgreSQL best practices recommend that timestamp with time zone is used instead for timezone-aware timestamps.
This must be configured before it can be used for new migrations.

To configure timestamp with time zone as your new timestamp default data type, place the following configuration in the config/application.rb file.

```ruby
# config/application.rb
ActiveSupport.on_load(:active_record_postgresqladapter) do
  self.datetime_type = :timestamptz
end
```

With that configuration in place, generate and apply new migrations, then verify their timestamps use the timestamp with time zone data type.

## 2. UUID Primary Keys

You need to enable the pgcrypto (only PostgreSQL >= 9.4) or uuid-ossp
extension to generate random UUIDs.

```ruby
# db/migrate/20131220144913_create_devices.rb
enable_extension "pgcrypto" unless extension_enabled?("pgcrypto")
create_table :devices, id: :uuid do |t|
  t.string :kind
end
```

```ruby
# app/models/device.rb
class Device < ApplicationRecord
end
```

```
irb> device = Device.create
irb> device.id
=> "814865cd-5a1d-4771-9306-4268f188fe9e"
```

gen_random_uuid() (from pgcrypto) is assumed if no :default option
was passed to create_table.

To use the Rails model generator for a table using UUID as the primary key, pass
--primary-key-type=uuid to the model generator.

For example:

```bash
bin/rails generate model Device --primary-key-type=uuid kind:string
```

When building a model with a foreign key that will reference this UUID, treat
uuid as the native field type, for example:

```bash
bin/rails generate model Case device_id:uuid
```

## 3. Indexing

- index creation

PostgreSQL includes a variety of index options. The following options are
supported by the PostgreSQL adapter in addition to the
common index options

### 3.1. Include

When creating a new index, non-key columns can be included with the :include option.
These keys are not used in index scans for searching, but can be read during an index
only scan without having to visit the associated table.

```ruby
# db/migrate/20131220144913_add_index_users_on_email_include_id.rb

add_index :users, :email, include: :id
```

Multiple columns are supported:

```ruby
# db/migrate/20131220144913_add_index_users_on_email_include_id_and_created_at.rb

add_index :users, :email, include: [:id, :created_at]
```

## 4. Generated Columns

Generated columns are supported since version 12.0 of PostgreSQL.

```ruby
# db/migrate/20131220144913_create_users.rb
create_table :users do |t|
  t.string :name
  t.virtual :name_upcased, type: :string, as: "upper(name)", stored: true
end

# app/models/user.rb
class User < ApplicationRecord
end

# Usage
user = User.create(name: "John")
User.last.name_upcased # => "JOHN"
```

## 5. Deferrable Foreign Keys

- foreign key table constraints

By default, table constraints in PostgreSQL are checked immediately after each statement. It intentionally does not allow creating records where the referenced record is not yet in the referenced table. It is possible to run this integrity check later on when the transaction is committed by adding DEFERRABLE to the foreign key definition though. To defer all checks by default it can be set to DEFERRABLE INITIALLY DEFERRED. Rails exposes this PostgreSQL feature by adding the :deferrable key to the foreign_key options in the add_reference and add_foreign_key methods.

One example of this is creating circular dependencies in a transaction even if you have created foreign keys:

```ruby
add_reference :person, :alias, foreign_key: { deferrable: :deferred }
add_reference :alias, :person, foreign_key: { deferrable: :deferred }
```

If the reference was created with the foreign_key: true option, the following transaction would fail when executing the first INSERT statement. It does not fail when the deferrable: :deferred option is set though.

```ruby
ActiveRecord::Base.lease_connection.transaction do
  person = Person.create(id: SecureRandom.uuid, alias_id: SecureRandom.uuid, name: "John Doe")
  Alias.create(id: person.alias_id, person_id: person.id, name: "jaydee")
end
```

When the :deferrable option is set to :immediate, let the foreign keys keep the default behavior of checking the constraint immediately, but allow manually deferring the checks using set_constraints within a transaction. This will cause the foreign keys to be checked when the transaction is committed:

```ruby
ActiveRecord::Base.lease_connection.transaction do
  ActiveRecord::Base.lease_connection.set_constraints(:deferred)
  person = Person.create(alias_id: SecureRandom.uuid, name: "John Doe")
  Alias.create(id: person.alias_id, person_id: person.id, name: "jaydee")
end
```

By default :deferrable is false and the constraint is always checked immediately.

## 6. Unique Constraint

- unique constraints

```ruby
# db/migrate/20230422225213_create_items.rb
create_table :items do |t|
  t.integer :position, null: false
  t.unique_constraint [:position], deferrable: :immediate
end
```

If you want to change an existing unique index to deferrable, you can use :using_index to create deferrable unique constraints.

```ruby
add_unique_constraint :items, deferrable: :deferred, using_index: "index_items_on_position"
```

Like foreign keys, unique constraints can be deferred by setting :deferrable to either :immediate or :deferred. By default, :deferrable is false and the constraint is always checked immediately.

## 7. Exclusion Constraints

- exclusion constraints

```ruby
# db/migrate/20131220144913_create_products.rb
create_table :products do |t|
  t.integer :price, null: false
  t.daterange :availability_range, null: false

  t.exclusion_constraint "price WITH =, availability_range WITH &&", using: :gist, name: "price_check"
end
```

Like foreign keys, exclusion constraints can be deferred by setting :deferrable to either :immediate or :deferred. By default, :deferrable is false and the constraint is always checked immediately.

## 8. Full Text Search

```ruby
# db/migrate/20131220144913_create_documents.rb
create_table :documents do |t|
  t.string :title
  t.string :body
end

add_index :documents, "to_tsvector('english', title || ' ' || body)", using: :gin, name: "documents_idx"
```

```ruby
# app/models/document.rb
class Document < ApplicationRecord
end
```

```ruby
# Usage
Document.create(title: "Cats and Dogs", body: "are nice!")

## all documents matching 'cat & dog'
Document.where("to_tsvector('english', title || ' ' || body) @@ to_tsquery(?)",
                 "cat & dog")
```

Optionally, you can store the vector as automatically generated column (from PostgreSQL 12.0):

```ruby
# db/migrate/20131220144913_create_documents.rb
create_table :documents do |t|
  t.string :title
  t.string :body

  t.virtual :textsearchable_index_col,
            type: :tsvector, as: "to_tsvector('english', title || ' ' || body)", stored: true
end

add_index :documents, :textsearchable_index_col, using: :gin, name: "documents_idx"

# Usage
Document.create(title: "Cats and Dogs", body: "are nice!")

## all documents matching 'cat & dog'
Document.where("textsearchable_index_col @@ to_tsquery(?)", "cat & dog")
```

## 9. Database Views

- view creation

Imagine you need to work with a legacy database containing the following table:

```
rails_pg_guide=# \d "TBL_ART"
                                        Table "public.TBL_ART"
   Column   |            Type             |                         Modifiers
------------+-----------------------------+------------------------------------------------------------
 INT_ID     | integer                     | not null default nextval('"TBL_ART_INT_ID_seq"'::regclass)
 STR_TITLE  | character varying           |
 STR_STAT   | character varying           | default 'draft'::character varying
 DT_PUBL_AT | timestamp without time zone |
 BL_ARCH    | boolean                     | default false
Indexes:
    "TBL_ART_pkey" PRIMARY KEY, btree ("INT_ID")
```

This table does not follow the Rails conventions at all.
Because simple PostgreSQL views are updateable by default,
we can wrap it as follows:

```ruby
# db/migrate/20131220144913_create_articles_view.rb
execute <<-SQL
CREATE VIEW articles AS
  SELECT "INT_ID" AS id,
         "STR_TITLE" AS title,
         "STR_STAT" AS status,
         "DT_PUBL_AT" AS published_at,
         "BL_ARCH" AS archived
  FROM "TBL_ART"
  WHERE "BL_ARCH" = 'f'
SQL
```

```ruby
# app/models/article.rb
class Article < ApplicationRecord
  self.primary_key = "id"
  def archive!
    update_attribute :archived, true
  end
end
```

```
irb> first = Article.create! title: "Winter is coming", status: "published", published_at: 1.year.ago
irb> second = Article.create! title: "Brace yourself", status: "draft", published_at: 1.month.ago

irb> Article.count
=> 2
irb> first.archive!
irb> Article.count
=> 1
```

This application only cares about non-archived Articles. A view also
allows for conditions so we can exclude the archived Articles directly.

## 10. Structure Dumps

If your config.active_record.schema_format is :sql, Rails will call pg_dump to generate a
structure dump.

You can use ActiveRecord::Tasks::DatabaseTasks.structure_dump_flags to configure pg_dump.
For example, to exclude comments from your structure dump, add this to an initializer:

```ruby
ActiveRecord::Tasks::DatabaseTasks.structure_dump_flags = ["--no-comments"]
```

## 11. Explain

Along with the standard explain options, the PostgreSQL adapter supports buffers.

```ruby
Company.where(id: owning_companies_ids).explain(:analyze, :buffers)
#=> EXPLAIN (ANALYZE, BUFFERS) SELECT "companies".* FROM "companies"
# ...
# Seq Scan on companies  (cost=0.00..2.21 rows=3 width=64)
# ...
```

See their documentation for more details.

---

# Chapters


---

This guide covers using multiple databases with your Rails application.

After reading this guide you will know:

- How to set up your application for multiple databases.

- How automatic connection switching works.

- How to use horizontal sharding for multiple databases.

- What features are supported and what's still a work in progress.

As an application grows in popularity and usage, you'll need to scale the application
to support your new users and their data. One way in which your application may need
to scale is on the database level. Rails supports using multiple databases, so you don't
have to store your data all in one place.

At this time the following features are supported:

- Multiple writer databases and a replica for each

- Automatic connection switching for the model you're working with

- Automatic swapping between the writer and replica depending on the HTTP verb and recent writes

- Rails tasks for creating, dropping, migrating, and interacting with the multiple databases

The following features are not (yet) supported:

- Load balancing replicas

## 1. Setting up Your Application

While Rails tries to do most of the work for you, there are still some steps you'll
need to do to get your application ready for multiple databases.

Let's say we have an application with a single writer database, and we need to add a
new database for some new tables we're adding. The name of the new database will be
"animals".

config/database.yml looks like this:

```yaml
production:
  database: my_primary_database
  adapter: mysql2
  username: root
  password: <%= ENV['ROOT_PASSWORD'] %>
```

Let's add a second database called "animals" and replicas for both databases as
well. To do this, we need to change our config/database.yml from a 2-tier to a
3-tier config.

If a primary configuration key is provided, it will be used as the "default" configuration. If
there is no configuration named primary, Rails will use the first configuration as default
for each environment. The default configurations will use the default Rails filenames. For example,
primary configurations will use db/schema.rb for the schema file, whereas all the other entries
will use db/[CONFIGURATION_NAMESPACE]_schema.rb for the filename.

```yaml
production:
  primary:
    database: my_primary_database
    username: root
    password: <%= ENV['ROOT_PASSWORD'] %>
    adapter: mysql2
  primary_replica:
    database: my_primary_database
    username: root_readonly
    password: <%= ENV['ROOT_READONLY_PASSWORD'] %>
    adapter: mysql2
    replica: true
  animals:
    database: my_animals_database
    username: animals_root
    password: <%= ENV['ANIMALS_ROOT_PASSWORD'] %>
    adapter: mysql2
    migrations_paths: db/animals_migrate
  animals_replica:
    database: my_animals_database
    username: animals_readonly
    password: <%= ENV['ANIMALS_READONLY_PASSWORD'] %>
    adapter: mysql2
    replica: true
```

Connection URLs for databases can also be configured using environment variables. The variable
name is formed by concatenating the connection name with _DATABASE_URL. For example, setting
ANIMALS_DATABASE_URL="mysql2://username:password@host/database" is merged into the animals
configuration in database.yml in the production environment. See
Configuring a Database for details about how the
merging works.

When using multiple databases, there are a few important settings.

First, the database name for primary and primary_replica should be the same because they contain
the same data. This is also the case for animals and animals_replica.

Second, the username for the writers and replicas should be different, and the
replica user's database permissions should be set to only read and not write.

When using a replica database, you need to add a replica: true entry to the replica in
config/database.yml. This is because Rails otherwise has no way of knowing which one is a replica
and which one is the writer. Rails will not run certain tasks, such as migrations, against replicas.

Lastly, for new writer databases, you need to set the migrations_paths key to the directory
where you will store migrations for that database. We'll look more at migrations_paths
later on in this guide.

You can also configure the schema dump file by setting schema_dump to a custom schema file name
or completely skip the schema dumping by setting schema_dump: false.

Now that we have a new database, let's set up the connection model.

The primary database replica may be configured in ApplicationRecord this way:

```ruby
class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

  connects_to database: { writing: :primary, reading: :primary_replica }
end
```

If you use a differently named class for your application record you need to
set primary_abstract_class instead, so that Rails knows which class ActiveRecord::Base
should share a connection with.

```ruby
class PrimaryApplicationRecord < ActiveRecord::Base
  primary_abstract_class

  connects_to database: { writing: :primary, reading: :primary_replica }
end
```

In that case, classes that connect to primary/primary_replica can inherit
from your primary abstract class like standard Rails applications do with
ApplicationRecord:

```ruby
class Person < PrimaryApplicationRecord
end
```

On the other hand, we need to set up our models persisted in the "animals" database:

```ruby
class AnimalsRecord < ApplicationRecord
  self.abstract_class = true

  connects_to database: { writing: :animals, reading: :animals_replica }
end
```

Those models should inherit from that common abstract class:

```ruby
class Dog < AnimalsRecord
  # Talks automatically to the animals database.
end
```

By default, Rails expects the database roles to be writing and reading for the primary
and replica respectively. If you have a legacy system you may already have roles set up that
you don't want to change. In that case you can set a new role name in your application config.

```ruby
config.active_record.writing_role = :default
config.active_record.reading_role = :readonly
```

It's important to connect to your database in a single model and then inherit from that model
for the tables rather than connect multiple individual models to the same database. Database
clients have a limit to the number of open connections there can be, and if you do this, it will
multiply the number of connections you have since Rails uses the model class name for the
connection specification name.

Now that we have the config/database.yml and the new model set up, it's time
to create the databases. Rails ships with all the commands you need to use
multiple databases.

You can run bin/rails --help to see all the commands you're able to run. You should see the following:

```bash
$ bin/rails --help
...
db:create                          # Create the database from DATABASE_URL or config/database.yml for the ...
db:create:animals                  # Create animals database for current environment
db:create:primary                  # Create primary database for current environment
db:drop                            # Drop the database from DATABASE_URL or config/database.yml for the cu...
db:drop:animals                    # Drop animals database for current environment
db:drop:primary                    # Drop primary database for current environment
db:migrate                         # Migrate the database (options: VERSION=x, VERBOSE=false, SCOPE=blog)
db:migrate:animals                 # Migrate animals database for current environment
db:migrate:primary                 # Migrate primary database for current environment
db:migrate:status                  # Display status of migrations
db:migrate:status:animals          # Display status of migrations for animals database
db:migrate:status:primary          # Display status of migrations for primary database
db:reset                           # Drop and recreates all databases from their schema for the current environment and loads the seeds
db:reset:animals                   # Drop and recreates the animals database from its schema for the current environment and loads the seeds
db:reset:primary                   # Drop and recreates the primary database from its schema for the current environment and loads the seeds
db:rollback                        # Roll the schema back to the previous version (specify steps w/ STEP=n)
db:rollback:animals                # Rollback animals database for current environment (specify steps w/ STEP=n)
db:rollback:primary                # Rollback primary database for current environment (specify steps w/ STEP=n)
db:schema:dump                     # Create a database schema file (either db/schema.rb or db/structure.sql  ...
db:schema:dump:animals             # Create a database schema file (either db/schema.rb or db/structure.sql  ...
db:schema:dump:primary             # Create a db/schema.rb file that is portable against any DB supported  ...
db:schema:load                     # Load a database schema file (either db/schema.rb or db/structure.sql  ...
db:schema:load:animals             # Load a database schema file (either db/schema.rb or db/structure.sql  ...
db:schema:load:primary             # Load a database schema file (either db/schema.rb or db/structure.sql  ...
db:setup                           # Create all databases, loads all schemas, and initializes with the seed data (use db:reset to also drop all databases first)
db:setup:animals                   # Create the animals database, loads the schema, and initializes with the seed data (use db:reset:animals to also drop the database first)
db:setup:primary                   # Create the primary database, loads the schema, and initializes with the seed data (use db:reset:primary to also drop the database first)
...
```

Running a command like bin/rails db:create will create both the primary and animals databases.
Note that there is no command for creating the database users, and you'll need to do that manually
to support the read-only users for your replicas. If you want to create just the animals
database you can run bin/rails db:create:animals.

## 2. Connecting to Databases without Managing Schema and Migrations

If you would like to connect to an external database without any database
management tasks such as schema management, migrations, seeds, etc., you can set
the per database config option database_tasks: false. By default it is
set to true.

```yaml
production:
  primary:
    database: my_database
    adapter: mysql2
  animals:
    database: my_animals_database
    adapter: mysql2
    database_tasks: false
```

## 3. Generators and Migrations

Migrations for multiple databases should live in their own folders prefixed with the
name of the database key in the configuration.

You also need to set migrations_paths in the database configurations to tell
Rails where to find the migrations.

For example the animals database would look for migrations in the db/animals_migrate directory and
primary would look in db/migrate. Rails generators now take a --database option
so that the file is generated in the correct directory. The command can be run like so:

```bash
bin/rails generate migration CreateDogs name:string --database animals
```

If you are using Rails generators, the scaffold and model generators will create the abstract
class for you. Simply pass the database key to the command line.

```bash
bin/rails generate scaffold Dog name:string --database animals
```

A class with the camelized database name and Record will be created. In this
example the database is "animals" so we end up with AnimalsRecord:

```ruby
class AnimalsRecord < ApplicationRecord
  self.abstract_class = true

  connects_to database: { writing: :animals }
end
```

The generated model will automatically inherit from AnimalsRecord.

```ruby
class Dog < AnimalsRecord
end
```

Since Rails doesn't know which database is the replica for your writer you will need to
add this to the abstract class after you're done.

Rails will only generate AnimalsRecord once. It will not be overwritten by new
scaffolds or deleted if the scaffold is deleted.

If you already have an abstract class and its name differs from AnimalsRecord, you can pass
the --parent option to indicate you want a different abstract class:

```bash
bin/rails generate scaffold Dog name:string --database animals --parent Animals::Record
```

This will skip generating AnimalsRecord since you've indicated to Rails that you want to
use a different parent class.

## 4. Activating Automatic Role Switching

Finally, in order to use the read-only replica in your application, you'll need to activate
the middleware for automatic switching.

Automatic switching allows the application to switch from the writer to the replica or the replica
to the writer based on the HTTP verb and whether there was a recent write by the requesting user.

If the application receives a POST, PUT, DELETE, or PATCH request, the application will
automatically write to the writer database. If the request is not one of those methods,
but the application recently made a write, the writer database will also be used. All
other requests will use the replica database.

To activate the automatic connection switching middleware you can run the automatic swapping
generator:

```bash
bin/rails g active_record:multi_db
```

And then uncomment the following lines:

```ruby
Rails.application.configure do
  config.active_record.database_selector = { delay: 2.seconds }
  config.active_record.database_resolver = ActiveRecord::Middleware::DatabaseSelector::Resolver
  config.active_record.database_resolver_context = ActiveRecord::Middleware::DatabaseSelector::Resolver::Session
end
```

Rails guarantees "read your own write" and will send your GET or HEAD request to the
writer if it's within the delay window. By default the delay is set to 2 seconds. You
should change this based on your database infrastructure. Rails doesn't guarantee "read
a recent write" for other users within the delay window and will send GET and HEAD requests
to the replicas unless they wrote recently.

The automatic connection switching in Rails is relatively primitive and deliberately doesn't
do a whole lot. The goal is a system that demonstrates how to do automatic connection
switching that is flexible enough to be customizable by app developers.

The setup in Rails allows you to easily change how the switching is done and what
parameters it's based on. Let's say you want to use a cookie instead of a session to
decide when to swap connections. You can write your own class:

```ruby
class MyCookieResolver < ActiveRecord::Middleware::DatabaseSelector::Resolver
  def self.call(request)
    new(request.cookies)
  end

  def initialize(cookies)
    @cookies = cookies
  end

  attr_reader :cookies

  def last_write_timestamp
    self.class.convert_timestamp_to_time(cookies[:last_write])
  end

  def update_last_write_timestamp
    cookies[:last_write] = self.class.convert_time_to_timestamp(Time.now)
  end

  def save(response)
  end
end
```

And then pass it to the middleware:

```ruby
config.active_record.database_selector = { delay: 2.seconds }
config.active_record.database_resolver = ActiveRecord::Middleware::DatabaseSelector::Resolver
config.active_record.database_resolver_context = MyCookieResolver
```

## 5. Using Manual Connection Switching

There are some cases where you may want your application to connect to a writer or a replica
and the automatic connection switching isn't adequate. For example, you may know that for a
particular request you always want to send the request to a replica, even when you are in a
POST request path.

To do this Rails provides a connected_to method that will switch to the connection you
need.

```ruby
ActiveRecord::Base.connected_to(role: :reading) do
  # All code in this block will be connected to the reading role.
end
```

The "role" in the connected_to call looks up the connections that are connected on that
connection handler (or role). The reading connection handler will hold all the connections
that were connected via connects_to with the role name of reading.

Note that connected_to with a role will look up an existing connection and switch
using the connection specification name. This means that if you pass an unknown role
like connected_to(role: :nonexistent) you will get an error that says
ActiveRecord::ConnectionNotEstablished (No connection pool for 'ActiveRecord::Base' found for the 'nonexistent' role.)

If you want Rails to ensure any queries performed are read-only, pass prevent_writes: true.
This just prevents queries that look like writes from being sent to the database.
You should also configure your replica database to run in read-only mode.

```ruby
ActiveRecord::Base.connected_to(role: :reading, prevent_writes: true) do
  # Rails will check each query to ensure it's a read query.
end
```

## 6. Horizontal Sharding

Horizontal sharding is when you split up your database to reduce the number of rows on each
database server, but maintain the same schema across "shards". This is commonly called "multi-tenant"
sharding.

The API for supporting horizontal sharding in Rails is similar to the multiple database / vertical
sharding API that's existed since Rails 6.0.

Shards are declared in the three-tier config like this:

```yaml
production:
  primary:
    database: my_primary_database
    adapter: mysql2
  primary_replica:
    database: my_primary_database
    adapter: mysql2
    replica: true
  primary_shard_one:
    database: my_primary_shard_one
    adapter: mysql2
    migrations_paths: db/migrate_shards
  primary_shard_one_replica:
    database: my_primary_shard_one
    adapter: mysql2
    replica: true
  primary_shard_two:
    database: my_primary_shard_two
    adapter: mysql2
    migrations_paths: db/migrate_shards
  primary_shard_two_replica:
    database: my_primary_shard_two
    adapter: mysql2
    replica: true
```

Models are then connected with the connects_to API via the shards key:

```ruby
class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class

  connects_to database: { writing: :primary, reading: :primary_replica }
end

class ShardRecord < ApplicationRecord
  self.abstract_class = true

  connects_to shards: {
    shard_one: { writing: :primary_shard_one, reading: :primary_shard_one_replica },
    shard_two: { writing: :primary_shard_two, reading: :primary_shard_two_replica }
  }
end

class Person < ShardRecord
end
```

If you're using shards, make sure both migrations_paths and schema_dump remain unchanged for
all the shards. When generating a migration you can pass the --database option and
use one of the shard names. Since they all set the same path, it doesn't matter which
one you choose.

```
bin/rails g scaffold Dog name:string --database primary_shard_one
```

Then models can swap shards manually via the connected_to API. If
using sharding, both a role and a shard must be passed:

```ruby
ShardRecord.connected_to(role: :writing, shard: :shard_one) do
  @person = Person.create! # Creates a record in shard shard_one
end

ShardRecord.connected_to(role: :writing, shard: :shard_two) do
  Person.find(@person.id) # Can't find record, doesn't exist because it was created
                   # in the shard named ":shard_one".
end
```

The horizontal sharding API also supports read replicas. You can swap the
role and the shard with the connected_to API.

```ruby
ShardRecord.connected_to(role: :reading, shard: :shard_one) do
  Person.first # Lookup record from read replica of shard one.
end
```

## 7. Activating Automatic Shard Switching

Applications are able to automatically switch shards per request using the ShardSelector
middleware, which allows an application to provide custom logic for determining the appropriate
shard for each request.

The same generator used for the database selector above can be used to generate an initializer file
for automatic shard swapping:

```bash
bin/rails g active_record:multi_db
```

Then in the generated config/initializers/multi_db.rb uncomment and modify the following code:

```ruby
Rails.application.configure do
  config.active_record.shard_selector = { lock: true }
  config.active_record.shard_resolver = ->(request) { Tenant.find_by!(host: request.host).shard }
end
```

Applications must provide a resolver to provide application-specific logic. An example resolver that
uses a subdomain to determine the shard might look like this:

```ruby
config.active_record.shard_resolver = ->(request) {
  subdomain = request.subdomain
  tenant = Tenant.find_by_subdomain!(subdomain)
  tenant.shard
}
```

The behavior of ShardSelector can be altered through some configuration options.

lock is true by default and will prohibit the request from switching shards during the request. If
lock is false, then shard swapping will be allowed. For tenant-based sharding, lock should
always be true to prevent application code from mistakenly switching between tenants.

class_name is the name of the abstract connection class to switch. By default, the ShardSelector
will use ActiveRecord::Base, but if the application has multiple databases, then this option
should be set to the name of the sharded database's abstract connection class.

Options may be set in the application configuration. For example, this configuration tells
ShardSelector to switch shards using AnimalsRecord.connected_to:

```ruby
config.active_record.shard_selector = { lock: true, class_name: "AnimalsRecord" }
```

## 8. Granular Database Connection Switching

Starting from Rails 6.1, it's possible to switch connections for one database
instead of all databases globally.

With granular database connection switching, any abstract connection class
will be able to switch connections without affecting other connections. This
is useful for switching your AnimalsRecord queries to read from the replica
while ensuring your ApplicationRecord queries go to the primary.

```ruby
AnimalsRecord.connected_to(role: :reading) do
  Dog.first # Reads from animals_replica.
  Person.first  # Reads from primary.
end
```

It's also possible to swap connections granularly for shards.

```ruby
AnimalsRecord.connected_to(role: :reading, shard: :shard_one) do
  # Will read from shard_one_replica. If no connection exists for shard_one_replica,
  # a ConnectionNotEstablished error will be raised.
  Dog.first

  # Will read from primary writer.
  Person.first
end
```

To switch only the primary database cluster use ApplicationRecord:

```ruby
ApplicationRecord.connected_to(role: :reading, shard: :shard_one) do
  Person.first # Reads from primary_shard_one_replica.
  Dog.first # Reads from animals_primary.
end
```

ActiveRecord::Base.connected_to maintains the ability to switch
connections globally.

### 8.1. Handling Associations with Joins across Databases

As of Rails 7.0+, Active Record has an option for handling associations that would perform
a join across multiple databases. If you have a has many through or a has one through association
that you want to disable joining and perform 2 or more queries, pass the disable_joins: true option.

For example:

```ruby
class Dog < AnimalsRecord
  has_many :treats, through: :humans, disable_joins: true
  has_many :humans

  has_one :home
  has_one :yard, through: :home, disable_joins: true
end

class Home
  belongs_to :dog
  has_one :yard
end

class Yard
  belongs_to :home
end
```

Previously calling @dog.treats without disable_joins or @dog.yard without disable_joins
would raise an error because databases are unable to handle joins across clusters. With the
disable_joins option, Rails will generate multiple select queries
to avoid attempting joining across clusters. For the above association, @dog.treats would generate the
following SQL:

```sql
SELECT "humans"."id" FROM "humans" WHERE "humans"."dog_id" = ?  [["dog_id", 1]]
SELECT "treats".* FROM "treats" WHERE "treats"."human_id" IN (?, ?, ?)  [["human_id", 1], ["human_id", 2], ["human_id", 3]]
```

While @dog.yard would generate the following SQL:

```sql
SELECT "home"."id" FROM "homes" WHERE "homes"."dog_id" = ? [["dog_id", 1]]
SELECT "yards".* FROM "yards" WHERE "yards"."home_id" = ? [["home_id", 1]]
```

There are some important things to be aware of with this option:

- There may be performance implications since now two or more queries will be performed (depending
on the association) rather than a join. If the select for humans returned a high number of IDs
the select for treats may send too many IDs.

- Since we are no longer performing joins, a query with an order or limit is now sorted in-memory since
order from one table cannot be applied to another table.

- This setting must be added to all associations where you want joining to be disabled.
Rails can't guess this for you because association loading is lazy, to load treats in @dog.treats
Rails already needs to know what SQL should be generated.

### 8.2. Schema Caching

If you want to load a schema cache for each database you must set
schema_cache_path in each database configuration and set
config.active_record.lazily_load_schema_cache = true in your application
configuration. Note that this will lazily load the cache when the database
connections are established.

## 9. Caveats

### 9.1. Load Balancing Replicas

Rails doesn't support automatic load balancing of replicas. This is very
dependent on your infrastructure. We may implement basic, primitive load
balancing in the future, but for an application at scale this should be
something your application handles outside of Rails.

---

# Chapters


---

This guide is an introduction to composite primary keys for database tables.

After reading this guide you will be able to:

- Create a table with a composite primary key

- Query a model with a composite primary key

- Enable your model to use a composite primary key for queries and associations

- Create forms for models that use composite primary keys

- Extract composite primary keys from controller parameters

- Use database fixtures for tables with composite primary keys

## 1. What are Composite Primary Keys?

Sometimes a single column's value isn't enough to uniquely identify every row
of a table, and a combination of two or more columns is required.
This can be the case when using a legacy database schema without a single id
column as a primary key, or when altering schemas for sharding or multitenancy.

Composite primary keys increase complexity and can be slower than a single
primary key column. Ensure your use-case requires a composite primary key
before using one.

## 2. Composite Primary Key Migrations

You can create a table with a composite primary key by passing the
:primary_key option to create_table with an array value:

```ruby
class CreateProducts < ActiveRecord::Migration[8.1]
  def change
    create_table :products, primary_key: [:store_id, :sku] do |t|
      t.integer :store_id
      t.string :sku
      t.text :description
    end
  end
end
```

## 3. Querying Models

### 3.1. Using #find

If your table uses a composite primary key, you'll need to pass an array
when using #find to locate a record:

```
# Find the product with store_id 3 and sku "XYZ12345"
irb> product = Product.find([3, "XYZ12345"])
=> #<Product store_id: 3, sku: "XYZ12345", description: "Yellow socks">
```

The SQL equivalent of the above is:

```sql
SELECT * FROM products WHERE store_id = 3 AND sku = "XYZ12345"
```

To find multiple records with composite IDs, pass an array of arrays to #find:

```
# Find the products with primary keys [1, "ABC98765"] and [7, "ZZZ11111"]
irb> products = Product.find([[1, "ABC98765"], [7, "ZZZ11111"]])
=> [
  #<Product store_id: 1, sku: "ABC98765", description: "Red Hat">,
  #<Product store_id: 7, sku: "ZZZ11111", description: "Green Pants">
]
```

The SQL equivalent of the above is:

```sql
SELECT * FROM products WHERE (store_id = 1 AND sku = 'ABC98765' OR store_id = 7 AND sku = 'ZZZ11111')
```

Models with composite primary keys will also use the full composite primary key
when ordering:

```
irb> product = Product.first
=> #<Product store_id: 1, sku: "ABC98765", description: "Red Hat">
```

The SQL equivalent of the above is:

```sql
SELECT * FROM products ORDER BY products.store_id ASC, products.sku ASC LIMIT 1
```

### 3.2. Using #where

Hash conditions for #where may be specified in a tuple-like syntax.
This can be useful for querying composite primary key relations:

```ruby
Product.where(Product.primary_key => [[1, "ABC98765"], [7, "ZZZ11111"]])
```

#### 3.2.1. Conditions with :id

When specifying conditions on methods like find_by and where, the use
of id will match against an :id attribute on the model. This is different
from find, where the ID passed in should be a primary key value.

Take caution when using find_by(id:) on models where :id is not the primary
key, such as composite primary key models. See the Active Record Querying
guide to learn more.

## 4. Associations between Models with Composite Primary Keys

Rails can often infer the primary key-foreign key relationships between
associated models. However, when dealing with composite primary keys, Rails
typically defaults to using only part of the composite key, usually the id
column, unless explicitly instructed otherwise. This default behavior only works
if the model's composite primary key contains the :id column, and the column
is unique for all records.

Consider the following example:

```ruby
class Order < ApplicationRecord
  self.primary_key = [:shop_id, :id]
  has_many :books
end

class Book < ApplicationRecord
  belongs_to :order
end
```

In this setup, Order has a composite primary key consisting of [:shop_id,
:id], and Book belongs to Order. Rails will assume that the :id column
should be used as the primary key for the association between an order and its
books. It will infer that the foreign key column on the books table is
:order_id.

Below we create an Order and a Book associated with it:

```ruby
order = Order.create!(id: [1, 2], status: "pending")
book = order.books.create!(title: "A Cool Book")
```

To access the book's order, we reload the association:

```ruby
book.reload.order
```

When doing so, Rails will generate the following SQL to access the order:

```sql
SELECT * FROM orders WHERE id = 2
```

You can see that Rails uses the order's id in its query, rather than both the
shop_id and the id. In this case, the id is sufficient because the model's
composite primary key does in fact contain the :id column, and the column is
unique for all records.

However, if the above requirements are not met or you would like to use the full
composite primary key in associations, you can set the foreign_key: option on
the association. This option specifies a composite foreign key on the
association; all columns in the foreign key will be used when querying the
associated record(s). For example:

```ruby
class Author < ApplicationRecord
  self.primary_key = [:first_name, :last_name]
  has_many :books, foreign_key: [:first_name, :last_name]
end

class Book < ApplicationRecord
  belongs_to :author, foreign_key: [:author_first_name, :author_last_name]
end
```

In this setup, Author has a composite primary key consisting of [:first_name,
:last_name], and Book belongs to Author with a composite foreign key
[:author_first_name, :author_last_name].

Create an Author and a Book associated with it:

```ruby
author = Author.create!(first_name: "Jane", last_name: "Doe")
book = author.books.create!(title: "A Cool Book", author_first_name: "Jane", author_last_name: "Doe")
```

To access the book's author, we reload the association:

```ruby
book.reload.author
```

Rails will now use the :first_name and :last_name from the composite
primary key in the SQL query:

```sql
SELECT * FROM authors WHERE first_name = 'Jane' AND last_name = 'Doe'
```

## 5. Forms for Composite Primary Key Models

Forms may also be built for composite primary key models.
See the Form Helpers guide for more information on the form builder syntax.

Given a @book model object with a composite key [:author_id, :id]:

```ruby
@book = Book.find([2, 25])
# => #<Book id: 25, title: "Some book", author_id: 2>
```

The following form:

```ruby
<%= form_with model: @book do |form| %>
  <%= form.text_field :title %>
  <%= form.submit %>
<% end %>
```

Outputs:

```html
<form action="/books/2_25" method="post" accept-charset="UTF-8" >
  <input name="authenticity_token" type="hidden" value="..." />
  <input type="text" name="book[title]" id="book_title" value="My book" />
  <input type="submit" name="commit" value="Update Book" data-disable-with="Update Book">
</form>
```

Note the generated URL contains the author_id and id delimited by an
underscore. Once submitted, the controller can extract primary key values from
the parameters and update the record. See the next section for more details.

## 6. Composite Key Parameters

Composite key parameters contain multiple values in one parameter.
For this reason, we need to be able to extract each value and pass them to
Active Record. We can leverage the extract_value method for this use-case.

Given the following controller:

```ruby
class BooksController < ApplicationController
  def show
    # Extract the composite ID value from URL parameters.
    id = params.extract_value(:id)
    # Find the book using the composite ID.
    @book = Book.find(id)
    # use the default rendering behavior to render the show view.
  end
end
```

And the following route:

```ruby
get "/books/:id", to: "books#show"
```

When a user opens the URL /books/4_2, the controller will extract the
composite key value ["4", "2"] and pass it to Book.find to render the right
record in the view. The extract_value method may be used to extract arrays
out of any delimited parameters.

## 7. Composite Primary Key Fixtures

Fixtures for composite primary key tables are fairly similar to normal tables.
When using an id column, the column may be omitted as usual:

```ruby
class Book < ApplicationRecord
  self.primary_key = [:author_id, :id]
  belongs_to :author
end
```

```
# books.yml
alices_adventure_in_wonderland:
  author_id: <%= ActiveRecord::FixtureSet.identify(:lewis_carroll) %>
  title: "Alice's Adventures in Wonderland"
```

However, in order to support composite primary key relationships,
you must use the composite_identify method:

```ruby
class BookOrder < ApplicationRecord
  self.primary_key = [:shop_id, :id]
  belongs_to :order, foreign_key: [:shop_id, :order_id]
  belongs_to :book, foreign_key: [:author_id, :book_id]
end
```

```
# book_orders.yml
alices_adventure_in_wonderland_in_books:
  author: lewis_carroll
  book_id: <%= ActiveRecord::FixtureSet.composite_identify(
              :alices_adventure_in_wonderland, Book.primary_key)[:id] %>
  shop: book_store
  order_id: <%= ActiveRecord::FixtureSet.composite_identify(
              :books, Order.primary_key)[:id] %>
```

---

# Chapters


---

This guide covers encrypting your database information using Active Record.

After reading this guide, you will know:

- How to set up database encryption with Active Record.

- How to migrate unencrypted data.

- How to make different encryption schemes coexist.

- How to use the API.

- How to configure the library and how to extend it.

Active Record supports application-level encryption. It works by declaring which attributes should be encrypted and seamlessly encrypting and decrypting them when necessary. The encryption layer sits between the database and the application. The application will access unencrypted data, but the database will store it encrypted.

## 1. Why Encrypt Data at the Application Level?

Active Record Encryption exists to protect sensitive information in your application. A typical example is personally identifiable information from users. But why would you want application-level encryption if you are already encrypting your database at rest?

As an immediate practical benefit, encrypting sensitive attributes adds an additional security layer. For example, if an attacker gained access to your database, a snapshot of it, or your application logs, they wouldn't be able to make sense of the encrypted information. Additionally, encryption can prevent developers from unintentionally exposing users' sensitive data in application logs.

But more importantly, by using Active Record Encryption, you define what constitutes sensitive information in your application at the code level. Active Record Encryption enables granular control of data access in your application and services consuming data from your application. For example, consider auditable Rails consoles that protect encrypted data or check the built-in system to filter controller params automatically.

## 2. Basic Usage

### 2.1. Setup

Run bin/rails db:encryption:init to generate a random key set:

```bash
$ bin/rails db:encryption:init
Add this entry to the credentials of the target environment:

active_record_encryption:
  primary_key: EGY8WhulUOXixybod7ZWwMIL68R9o5kC
  deterministic_key: aPA5XyALhf75NNnMzaspW7akTfZp0lPY
  key_derivation_salt: xEY0dt6TZcAMg52K7O84wYzkjvbA62Hz
```

These values can be stored by copying and pasting the generated values into your existing Rails credentials. Alternatively, these values can be configured from other sources, such as environment variables:

```ruby
config.active_record.encryption.primary_key = ENV["ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY"]
config.active_record.encryption.deterministic_key = ENV["ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY"]
config.active_record.encryption.key_derivation_salt = ENV["ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT"]
```

These generated values are 32 bytes in length. If you generate these yourself, the minimum lengths you should use are 12 bytes for the primary key (this will be used to derive the AES 32 bytes key) and 20 bytes for the salt.

### 2.2. Declaration of Encrypted Attributes

Encryptable attributes are defined at the model level. These are regular Active Record attributes backed by a column with the same name.

```ruby
class Article < ApplicationRecord
  encrypts :title
end
```

The library will transparently encrypt these attributes before saving them in the database and will decrypt them upon retrieval:

```ruby
article = Article.create title: "Encrypt it all!"
article.title # => "Encrypt it all!"
```

But, under the hood, the executed SQL looks like this:

```sql
INSERT INTO `articles` (`title`) VALUES ('{\"p\":\"n7J0/ol+a7DRMeaE\",\"h\":{\"iv\":\"DXZMDWUKfp3bg/Yu\",\"at\":\"X1/YjMHbHD4talgF9dt61A==\"}}')
```

#### 2.2.1. Important: About Storage and Column Size

Encryption requires extra space because of Base64 encoding and the metadata stored along with the encrypted payloads. When using the built-in envelope encryption key provider, you can estimate the worst-case overhead at around 255 bytes. This overhead is negligible at larger sizes. Not only because it gets diluted but because the library uses compression by default, which can offer up to 30% storage savings over the unencrypted version for larger payloads.

There is an important concern about string column sizes: in modern databases the column size determines the number of characters it can allocate, not the number of bytes. For example, with UTF-8, each character can take up to four bytes, so, potentially, a column in a database using UTF-8 can store up to four times its size in terms of number of bytes. Now, encrypted payloads are binary strings serialized as Base64, so they can be stored in regular string columns. Because they are a sequence of ASCII bytes, an encrypted column can take up to four times its clear version size. So, even if the bytes stored in the database are the same, the column must be four times bigger.

In practice, this means:

- When encrypting short texts written in Western alphabets (mostly ASCII characters), you should account for that 255 additional overhead when defining the column size.

- When encrypting short texts written in non-Western alphabets, such as Cyrillic, you should multiply the column size by 4. Notice that the storage overhead is 255 bytes at most.

- When encrypting long texts, you can ignore column size concerns.

Some examples:

### 2.3. Deterministic and Non-deterministic Encryption

By default, Active Record Encryption uses a non-deterministic approach to encryption. Non-deterministic, in this context, means that encrypting the same content with the same password twice will result in different ciphertexts. This approach improves security by making crypto-analysis of ciphertexts harder, and querying the database impossible.

You can use the deterministic:  option to generate initialization vectors in a deterministic way, effectively enabling querying encrypted data.

```ruby
class Author < ApplicationRecord
  encrypts :email, deterministic: true
end

Author.find_by_email("some@email.com") # You can query the model normally
```

The non-deterministic approach is recommended unless you need to query the data.

In non-deterministic mode, Active Record uses AES-GCM with a 256-bits key and a random initialization vector. In deterministic mode, it also uses AES-GCM, but the initialization vector is generated as an HMAC-SHA-256 digest of the key and contents to encrypt.

You can disable deterministic encryption by omitting a deterministic_key.

## 3. Features

### 3.1. Action Text

You can encrypt Action Text attributes by passing encrypted: true in their declaration.

```ruby
class Message < ApplicationRecord
  has_rich_text :content, encrypted: true
end
```

Passing individual encryption options to Action Text attributes is not supported yet. It will use non-deterministic encryption with the global encryption options configured.

### 3.2. Fixtures

You can get Rails fixtures encrypted automatically by adding this option to your test.rb:

```ruby
config.active_record.encryption.encrypt_fixtures = true
```

When enabled, all the encryptable attributes will be encrypted according to the encryption settings defined in the model.

#### 3.2.1. Action Text Fixtures

To encrypt Action Text fixtures, you should place them in fixtures/action_text/encrypted_rich_texts.yml.

### 3.3. Supported Types

active_record.encryption will serialize values using the underlying type before encrypting them, but, unless using a custom message_serializer, they must be serializable as strings. Structured types like serialized are supported out of the box.

If you need to support a custom type, the recommended way is to use a serialized attribute. The declaration of the serialized attribute should go before the encryption declaration:

```ruby
# CORRECT
class Article < ApplicationRecord
  serialize :title, type: Title
  encrypts :title
end

# INCORRECT
class Article < ApplicationRecord
  encrypts :title
  serialize :title, type: Title
end
```

### 3.4. Ignoring Case

You might need to ignore casing when querying deterministically encrypted data. Two approaches make accomplishing this easier:

You can use the :downcase option when declaring the encrypted attribute to downcase the content before encryption occurs.

```ruby
class Person
  encrypts :email_address, deterministic: true, downcase: true
end
```

When using :downcase, the original case is lost. In some situations, you might want to ignore the case only when querying while also storing the original case. For those situations, you can use the option :ignore_case. This requires you to add a new column named original_<column_name> to store the content with the case unchanged:

```ruby
class Label
  encrypts :name, deterministic: true, ignore_case: true # the content with the original case will be stored in the column `original_name`
end
```

### 3.5. Support for Unencrypted Data

To ease migrations of unencrypted data, the library includes the option config.active_record.encryption.support_unencrypted_data. When set to true:

- Trying to read encrypted attributes that are not encrypted will work normally, without raising any error.

- Queries with deterministically encrypted attributes will include the "clear text" version of them to support finding both encrypted and unencrypted content. You need to set config.active_record.encryption.extend_queries = true to enable this.

This option is meant to be used during transition periods while clear data and encrypted data must coexist. Both are set to false by default, which is the recommended goal for any application: errors will be raised when working with unencrypted data.

### 3.6. Support for Previous Encryption Schemes

Changing encryption properties of attributes can break existing data. For example, imagine you want to make a deterministic attribute non-deterministic. If you just change the declaration in the model, reading existing ciphertexts will fail because the encryption method is different now.

To support these situations, you can declare previous encryption schemes that will be used in two scenarios:

- When reading encrypted data, Active Record Encryption will try previous encryption schemes if the current scheme doesn't work.

- When querying deterministic data, it will add ciphertexts using previous schemes so that queries work seamlessly with data encrypted with different schemes. You must set config.active_record.encryption.extend_queries = true to enable this.

You can configure previous encryption schemes:

- Globally

- On a per-attribute basis

#### 3.6.1. Global Previous Encryption Schemes

You can add previous encryption schemes by adding them as a list of properties using the previous config property in your application.rb:

```ruby
config.active_record.encryption.previous = [ { key_provider: MyOldKeyProvider.new } ]
```

#### 3.6.2. Per-attribute Encryption Schemes

Use :previous when declaring the attribute:

```ruby
class Article
  encrypts :title, deterministic: true, previous: { deterministic: false }
end
```

#### 3.6.3. Encryption Schemes and Deterministic Attributes

When adding previous encryption schemes:

- With non-deterministic encryption, new information will always be encrypted with the newest (current) encryption scheme.

- With deterministic encryption, new information will always be encrypted with the oldest encryption scheme by default.

Typically, with deterministic encryption, you want ciphertexts to remain constant. You can change this behavior by setting deterministic: { fixed: false }. In that case, it will use the newest encryption scheme for encrypting new data.

### 3.7. Unique Constraints

Unique constraints can only be used with deterministically encrypted data.

#### 3.7.1. Unique Validations

Unique validations are supported normally as long as extended queries are enabled (config.active_record.encryption.extend_queries = true).

```ruby
class Person
  validates :email_address, uniqueness: true
  encrypts :email_address, deterministic: true, downcase: true
end
```

They will also work when combining encrypted and unencrypted data, and when configuring previous encryption schemes.

If you want to ignore case, make sure to use downcase: or ignore_case: in the encrypts declaration. Using the case_sensitive: option in the validation won't work.

#### 3.7.2. Unique Indexes

To support unique indexes on deterministically encrypted columns, you need to ensure their ciphertext doesn't ever change.

To encourage this, deterministic attributes will always use the oldest available encryption scheme by default when multiple encryption schemes are configured. Otherwise, it's your job to ensure encryption properties don't change for these attributes, or the unique indexes won't work.

```ruby
class Person
  encrypts :email_address, deterministic: true
end
```

### 3.8. Filtering Params Named as Encrypted Columns

By default, encrypted columns are configured to be automatically filtered in Rails logs. You can disable this behavior by adding the following to your application.rb:

```ruby
config.active_record.encryption.add_to_filter_parameters = false
```

If filtering is enabled, but you want to exclude specific columns from automatic filtering, add them to config.active_record.encryption.excluded_from_filter_parameters:

```ruby
config.active_record.encryption.excluded_from_filter_parameters = [:catchphrase]
```

When generating the filter parameter, Rails will use the model name as a prefix. E.g: For Person#name, the filter parameter will be person.name.

### 3.9. Encoding

The library will preserve the encoding for string values encrypted non-deterministically.

Because encoding is stored along with the encrypted payload, values encrypted deterministically will force UTF-8 encoding by default. Therefore the same value with a different encoding will result in a different ciphertext when encrypted. You usually want to avoid this to keep queries and uniqueness constraints working, so the library will perform the conversion automatically on your behalf.

You can configure the desired default encoding for deterministic encryption with:

```ruby
config.active_record.encryption.forced_encoding_for_deterministic_encryption = Encoding::US_ASCII
```

And you can disable this behavior and preserve the encoding in all cases with:

```ruby
config.active_record.encryption.forced_encoding_for_deterministic_encryption = nil
```

### 3.10. Compression

The library compresses encrypted payloads by default. This can save up to 30% of the storage space for larger payloads. You can disable compression by setting compress: false for encrypted attributes:

```ruby
class Article < ApplicationRecord
  encrypts :content, compress: false
end
```

You can also configure the algorithm used for the compression. The default compressor is Zlib. You can implement your own compressor by creating a class or module that responds to #deflate(data) and #inflate(data).

```ruby
require "zstd-ruby"

module ZstdCompressor
  def self.deflate(data)
    Zstd.compress(data)
  end

  def self.inflate(data)
    Zstd.decompress(data)
  end
end

class User
  encrypts :name, compressor: ZstdCompressor
end
```

You can configure the compressor globally:

```ruby
config.active_record.encryption.compressor = ZstdCompressor
```

## 4. Key Management

Key providers implement key management strategies. You can configure key providers globally or on a per-attribute basis.

### 4.1. Built-in Key Providers

#### 4.1.1. DerivedSecretKeyProvider

A key provider that will serve keys derived from the provided passwords using PBKDF2.

```ruby
config.active_record.encryption.key_provider = ActiveRecord::Encryption::DerivedSecretKeyProvider.new(["some passwords", "to derive keys from. ", "These should be in", "credentials"])
```

By default, active_record.encryption configures a DerivedSecretKeyProvider with the keys defined in active_record.encryption.primary_key.

#### 4.1.2. EnvelopeEncryptionKeyProvider

Implements a simple envelope encryption strategy:

- It generates a random key for each data-encryption operation

- It stores the data-key with the data itself, encrypted with a primary key defined in the credential active_record.encryption.primary_key.

You can configure Active Record to use this key provider by adding this to your application.rb:

```ruby
config.active_record.encryption.key_provider = ActiveRecord::Encryption::EnvelopeEncryptionKeyProvider.new
```

As with other built-in key providers, you can provide a list of primary keys in active_record.encryption.primary_key to implement key-rotation schemes.

### 4.2. Custom Key Providers

For more advanced key-management schemes, you can configure a custom key provider in an initializer:

```ruby
ActiveRecord::Encryption.key_provider = MyKeyProvider.new
```

A key provider must implement this interface:

```ruby
class MyKeyProvider
  def encryption_key
  end

  def decryption_keys(encrypted_message)
  end
end
```

Both methods return ActiveRecord::Encryption::Key objects:

- encryption_key returns the key used for encrypting some content

- decryption_keys returns a list of potential keys for decrypting a given message

A key can include arbitrary tags that will be stored unencrypted with the message. You can use ActiveRecord::Encryption::Message#headers to examine those values when decrypting.

### 4.3. Attribute-specific Key Providers

You can configure a key provider on a per-attribute basis with the :key_provider option:

```ruby
class Article < ApplicationRecord
  encrypts :summary, key_provider: ArticleKeyProvider.new
end
```

### 4.4. Attribute-specific Keys

You can configure a given key on a per-attribute basis with the :key option:

```ruby
class Article < ApplicationRecord
  encrypts :summary, key: "some secret key for article summaries"
end
```

Active Record uses the key to derive the key used to encrypt and decrypt the data.

### 4.5. Rotating Keys

active_record.encryption can work with lists of keys to support implementing key-rotation schemes:

- The last key will be used for encrypting new content.

- All the keys will be tried when decrypting content until one works.

```
active_record_encryption:
  primary_key:
    - a1cc4d7b9f420e40a337b9e68c5ecec6 # Previous keys can still decrypt existing content
    - bc17e7b413fd4720716a7633027f8cc4 # Active, encrypts new content
  key_derivation_salt: a3226b97b3b2f8372d1fc6d497a0c0d3
```

This enables workflows in which you keep a short list of keys by adding new keys, re-encrypting content, and deleting old keys.

Rotating keys is not currently supported for deterministic encryption.

Active Record Encryption doesn't provide automatic management of key rotation processes yet. All the pieces are there, but this hasn't been implemented yet.

### 4.6. Storing Key References

You can configure active_record.encryption.store_key_references to make active_record.encryption store a reference to the encryption key in the encrypted message itself.

```ruby
config.active_record.encryption.store_key_references = true
```

Doing so makes for more performant decryption because the system can now locate keys directly instead of trying lists of keys. The price to pay is storage: encrypted data will be a bit bigger.

## 5. API

### 5.1. Basic API

ActiveRecord encryption is meant to be used declaratively, but it offers an API for advanced usage scenarios.

#### 5.1.1. Encrypt and Decrypt

```ruby
article.encrypt # encrypt or re-encrypt all the encryptable attributes
article.decrypt # decrypt all the encryptable attributes
```

#### 5.1.2. Read Ciphertext

```ruby
article.ciphertext_for(:title)
```

#### 5.1.3. Check if the Attribute is Encrypted or Not

```ruby
article.encrypted_attribute?(:title)
```

## 6. Configuration

### 6.1. Configuration Options

You can configure Active Record Encryption options in your application.rb (most common scenario) or in a specific environment config file config/environments/<env name>.rb if you want to set them on a per-environment basis.

It's recommended to use Rails built-in credentials support to store keys. If you prefer to set them manually via config properties, make sure you don't commit them with your code (e.g. use environment variables).

#### 6.1.1. config.active_record.encryption.support_unencrypted_data

When true, unencrypted data can be read normally. When false, it will raise errors. Default: false.

#### 6.1.2. config.active_record.encryption.extend_queries

When true, queries referencing deterministically encrypted attributes will be modified to include additional values if needed. Those additional values will be the clean version of the value (when config.active_record.encryption.support_unencrypted_data is true) and values encrypted with previous encryption schemes, if any (as provided with the previous: option). Default: false (experimental).

#### 6.1.3. config.active_record.encryption.encrypt_fixtures

When true, encryptable attributes in fixtures will be automatically encrypted when loaded. Default: false.

#### 6.1.4. config.active_record.encryption.store_key_references

When true, a reference to the encryption key is stored in the headers of the encrypted message. This makes for faster decryption when multiple keys are in use. Default: false.

#### 6.1.5. config.active_record.encryption.add_to_filter_parameters

When true, encrypted attribute names are added automatically to config.filter_parameters and won't be shown in logs. Default: true.

#### 6.1.6. config.active_record.encryption.excluded_from_filter_parameters

You can configure a list of params that won't be filtered out when config.active_record.encryption.add_to_filter_parameters is true. Default: [].

#### 6.1.7. config.active_record.encryption.validate_column_size

Adds a validation based on the column size. This is recommended to prevent storing huge values using highly compressible payloads. Default: true.

#### 6.1.8. config.active_record.encryption.primary_key

The key or lists of keys used to derive root data-encryption keys. The way they are used depends on the key provider configured. It's preferred to configure it via the active_record_encryption.primary_key credential.

#### 6.1.9. config.active_record.encryption.deterministic_key

The key or list of keys used for deterministic encryption. It's preferred to configure it via the active_record_encryption.deterministic_key credential.

#### 6.1.10. config.active_record.encryption.key_derivation_salt

The salt used when deriving keys. It's preferred to configure it via the active_record_encryption.key_derivation_salt credential.

#### 6.1.11. config.active_record.encryption.forced_encoding_for_deterministic_encryption

The default encoding for attributes encrypted deterministically. You can disable forced encoding by setting this option to nil. It's Encoding::UTF_8 by default.

#### 6.1.12. config.active_record.encryption.hash_digest_class

The digest algorithm used to derive keys. OpenSSL::Digest::SHA256 by default.

#### 6.1.13. config.active_record.encryption.support_sha1_for_non_deterministic_encryption

Supports decrypting data encrypted non-deterministically with a digest class SHA1. The default is false, which
means it will only support the digest algorithm configured in config.active_record.encryption.hash_digest_class.

#### 6.1.14. config.active_record.encryption.compressor

The compressor used to compress encrypted payloads. It should respond to deflate and inflate. The default is Zlib. You can find more information about compressors in the Compression section.

### 6.2. Encryption Contexts

An encryption context defines the encryption components that are used in a given moment. There is a default encryption context based on your global configuration, but you can configure a custom context for a given attribute or when running a specific block of code.

Encryption contexts are a flexible but advanced configuration mechanism. Most users should not have to care about them.

The main components of encryption contexts are:

- encryptor: exposes the internal API for encrypting and decrypting data.  It interacts with a key_provider to build encrypted messages and deal with their serialization. The encryption/decryption itself is done by the cipher and the serialization by message_serializer.

- cipher: the encryption algorithm itself (AES 256 GCM)

- key_provider: serves encryption and decryption keys.

- message_serializer: serializes and deserializes encrypted payloads (Message).

If you decide to build your own message_serializer, it's important to use safe mechanisms that can't deserialize arbitrary objects. A commonly supported scenario is encrypting existing unencrypted data. An attacker can leverage this to enter a tampered payload before encryption takes place and perform RCE attacks. This means custom serializers should avoid Marshal, YAML.load (use YAML.safe_load  instead), or JSON.load (use JSON.parse instead).

#### 6.2.1. Global Encryption Context

The global encryption context is the one used by default and is configured as other configuration properties in your application.rb or environment config files.

```ruby
config.active_record.encryption.key_provider = ActiveRecord::Encryption::EnvelopeEncryptionKeyProvider.new
config.active_record.encryption.encryptor = MyEncryptor.new
```

#### 6.2.2. Per-attribute Encryption Contexts

You can override encryption context params by passing them in the attribute declaration:

```ruby
class Attribute
  encrypts :title, encryptor: MyAttributeEncryptor.new
end
```

#### 6.2.3. Encryption Context When Running a Block of Code

You can use ActiveRecord::Encryption.with_encryption_context to set an encryption context for a given block of code:

```ruby
ActiveRecord::Encryption.with_encryption_context(encryptor: ActiveRecord::Encryption::NullEncryptor.new) do
  # ...
end
```

#### 6.2.4. Built-in Encryption Contexts

You can run code without encryption:

```ruby
ActiveRecord::Encryption.without_encryption do
  # ...
end
```

This means that reading encrypted text will return the ciphertext, and saved content will be stored unencrypted.

You can run code without encryption but prevent overwriting encrypted content:

```ruby
ActiveRecord::Encryption.protecting_encrypted_data do
  # ...
end
```

This can be handy if you want to protect encrypted data while still running arbitrary code against it (e.g. in a Rails console).
