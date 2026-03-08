# Active Record Basics

Models, CRUD, migrations, validations, and callbacks.

## Table of Contents

- [1. What is Active Record?](#1-what-is-active-record)
- [2. Convention over Configuration in Active Record](#2-convention-over-configuration-in-active-record)
- [3. Creating Active Record Models](#3-creating-active-record-models)
- [4. Overriding the Naming Conventions](#4-overriding-the-naming-conventions)
- [5. CRUD: Reading and Writing Data](#5-crud-reading-and-writing-data)
- [6. Validations](#6-validations)
- [7. Callbacks](#7-callbacks)
- [8. Migrations](#8-migrations)
- [9. Associations](#9-associations)
- [1. Migration Overview](#1-migration-overview)
- [2. Generating Migration Files](#2-generating-migration-files)
- [3. Updating Migrations](#3-updating-migrations)
- [4. Running Migrations](#4-running-migrations)
- [5. Changing Existing Migrations](#5-changing-existing-migrations)
- [6. Schema Dumping and You](#6-schema-dumping-and-you)
- [7. Active Record and Referential Integrity](#7-active-record-and-referential-integrity)
- [8. Migrations and Seed Data](#8-migrations-and-seed-data)
- [9. Old Migrations](#9-old-migrations)
- [10. Miscellaneous](#10-miscellaneous)
- [1. Validations Overview](#1-validations-overview)
- [2. Validations](#2-validations)
- [3. Validation Options](#3-validation-options)
- [4. Conditional Validations](#4-conditional-validations)
- [5. Strict Validations](#5-strict-validations)
- [6. Listing Validators](#6-listing-validators)
- [7. Performing Custom Validations](#7-performing-custom-validations)
- [8. Working with Validation Errors](#8-working-with-validation-errors)
- [9. Displaying Validation Errors in Views](#9-displaying-validation-errors-in-views)
- [1. The Object Life Cycle](#1-the-object-life-cycle)
- [2. Callback Registration](#2-callback-registration)
- [3. Available Callbacks](#3-available-callbacks)
- [4. Running Callbacks](#4-running-callbacks)
- [5. Conditional Callbacks](#5-conditional-callbacks)
- [6. Skipping Callbacks](#6-skipping-callbacks)
- [7. Suppressing Saving](#7-suppressing-saving)
- [8. Halting Execution](#8-halting-execution)
- [9. Association Callbacks](#9-association-callbacks)
- [10. Cascading Association Callbacks](#10-cascading-association-callbacks)
- [11. Transaction Callbacks](#11-transaction-callbacks)
- [12. Callback Objects](#12-callback-objects)

---

This guide is an introduction to Active Record.

After reading this guide, you will know:

- How Active Record fits into the Model-View-Controller (MVC) paradigm.

- What Object Relational Mapping and Active Record patterns are and how
they are used in Rails.

- How to use Active Record models to manipulate data stored in a relational
database.

- Active Record schema naming conventions.

- The concepts of database migrations, validations, callbacks, and associations.

## 1. What is Active Record?

Active Record is part of the M in MVC - the model - which is the layer of
the system responsible for representing data and business logic. Active Record
helps you create and use Ruby objects whose attributes require persistent
storage to a database.

What is the difference between Active Record and Active Model? It's
possible to model data with Ruby objects that do not need to be backed by a
database. Active Model is commonly used for that in
Rails, making Active Record and Active Model both part of the M in MVC, as well
as your own plain Ruby objects.

The term "Active Record" also refers to a software architecture pattern. Active
Record in Rails is an implementation of that pattern. It's also a description of
something called an Object Relational Mapping system. The below sections
explain these terms.

### 1.1. The Active Record Pattern

The Active Record pattern is described by Martin Fowler in the book
Patterns of Enterprise Application Architecture as "an object that wraps a row
in a database table, encapsulates the database access, and adds domain logic to
that data." Active Record objects carry both data and behavior. Active Record
classes match very closely to the record structure of the underlying database.
This way users can easily read from and write to the database, as you will see
in the examples below.

### 1.2. Object Relational Mapping

Object Relational Mapping, commonly referred to as ORM, is a technique that
connects the rich objects of a programming language to tables in a relational
database management system (RDBMS). In the case of a Rails application, these
are Ruby objects. Using an ORM, the attributes of Ruby objects, as well as the
relationship between objects, can be easily stored and retrieved from a database
without writing SQL statements directly. Overall, ORMs minimize the amount of
database access code you have to write.

Basic knowledge of relational database management systems (RDBMS) and
structured query language (SQL) is helpful in order to fully understand Active
Record. Please refer to this SQL tutorial (or this RDBMS
tutorial) or study them by other means if you would like to learn
more.

### 1.3. Active Record as an ORM Framework

Active Record gives us the ability to do the following using Ruby objects:

- Represent models and their data.

- Represent associations between models.

- Represent inheritance hierarchies through related models.

- Validate models before they get persisted to the database.

- Perform database operations in an object-oriented fashion.

## 2. Convention over Configuration in Active Record

When writing applications using other programming languages or frameworks, it
may be necessary to write a lot of configuration code. This is particularly true
for ORM frameworks in general. However, if you follow the conventions adopted by
Rails, you'll write very little to no configuration code when creating Active
Record models.

Rails adopts the idea that if you configure your applications in the same way
most of the time, then that way should be the default. Explicit configuration
should be needed only in those cases where you can't follow the convention.

To take advantage of convention over configuration in Active Record, there are
some naming and schema conventions to follow. And in case you need to, it is
possible to override naming conventions.

### 2.1. Naming Conventions

Active Record uses this naming convention to map between models (represented by
Ruby objects) and database tables:

Rails will pluralize your model's class names to find the respective database
table. For example, a class named Book maps to a database table named books.
The Rails pluralization mechanisms are very powerful and capable of pluralizing
(and singularizing) both regular and irregular words in the English language.
This uses the Active Support
pluralize method.

For class names composed of two or more words, the model class name will follow
the Ruby conventions of using an UpperCamelCase name. The database table name, in
that case, will be a snake_case name. For example:

- BookClub is the model class, singular with the first letter of each word
capitalized.

- book_clubs is the matching database table, plural with underscores
separating words.

Here are some more examples of model class names and corresponding table names:

### 2.2. Schema Conventions

Active Record uses conventions for column names in the database tables as well,
depending on the purpose of these columns.

- Primary keys - By default, Active Record will use an integer column named
id as the table's primary key (bigint for PostgreSQL, MySQL, and MariaDB,
integer for SQLite). When using Active Record Migrations to
create your tables, this column will be automatically created.

- Foreign keys - These fields should be named following the pattern
singularized_table_name_id (e.g., order_id, line_item_id). These are the
fields that Active Record will look for when you create associations between
your models.

There are also some optional column names that will add additional features to
Active Record instances:

- created_at - Automatically gets set to the current date and time when the
record is first created.

- updated_at - Automatically gets set to the current date and time whenever
the record is created or updated.

- lock_version - Adds optimistic
locking to a
model.

- type - Specifies that the model uses Single Table
Inheritance.

- (association_name)_type - Stores the type for polymorphic
associations.

- (table_name)_count - Used to cache the number of belonging objects on
associations. For example, if Articles have many Comments, a
comments_count column in the articles table will cache the number of
existing comments for each article.

While these column names are optional, they are reserved by Active Record.
Steer clear of reserved keywords when naming your table's columns. For example,
type is a reserved keyword used to designate a table using Single Table
Inheritance (STI). If you are not using STI, use a different word to accurately
describe the data you are modeling.

## 3. Creating Active Record Models

When generating a Rails application, an abstract ApplicationRecord class will
be created in app/models/application_record.rb. The ApplicationRecord class
inherits from
ActiveRecord::Base
and it's what turns a regular Ruby class into an Active Record model.

ApplicationRecord is the base class for all Active Record models in your app.
To create a new model, subclass the ApplicationRecord class and you're good to
go:

```ruby
class Book < ApplicationRecord
end
```

This will create a Book model, mapped to a books table in the database,
where each column in the table is mapped to attributes of the Book class. An
instance of Book can represent a row in the books table. The books table
with columns id, title, and author, can be created using an SQL statement
like this:

```sql
CREATE TABLE books (
  id int(11) NOT NULL auto_increment,
  title varchar(255),
  author varchar(255),
  PRIMARY KEY  (id)
);
```

However, that is not how you do it normally in Rails. Database tables in Rails
are typically created using Active Record Migrations and not raw
SQL. A migration for the books table above can be generated like this:

```bash
bin/rails generate migration CreateBooks title:string author:string
```

If you don't specify a type for a field (e.g., title instead of title:string), Rails will default to type string.

and results in this:

```ruby
# Note:
# The `id` column, as the primary key, is automatically created by convention.
# Columns `created_at` and `updated_at` are added by `t.timestamps`.

# db/migrate/20240220143807_create_books.rb
class CreateBooks < ActiveRecord::Migration[8.1]
  def change
    create_table :books do |t|
      t.string :title
      t.string :author

      t.timestamps
    end
  end
end
```

That migration creates columns id, title, author, created_at and
updated_at. Each row of this table can be represented by an instance of the
Book class with the same attributes: id, title, author, created_at,
and updated_at. You can access a book's attributes like this:

```
irb> book = Book.new
=> #<Book:0x00007fbdf5e9a038 id: nil, title: nil, author: nil, created_at: nil, updated_at: nil>

irb> book.title = "The Hobbit"
=> "The Hobbit"
irb> book.title
=> "The Hobbit"
```

You can generate the Active Record model class as well as a matching
migration with the command bin/rails generate model Book title:string
author:string. This creates the files app/models/book.rb,
db/migrate/20240220143807_create_books.rb, and a couple others for testing
purposes.

### 3.1. Creating Namespaced Models

Active Record models are placed under the app/models directory by default. But
you may want to organize your models by placing similar models under their own
folder and namespace. For example, order.rb and review.rb under
app/models/book with Book::Order and Book::Review class names,
respectively. You can create namespaced models with Active Record.

In the case where the Book module does not already exist, the generate
command will create everything like this:

```bash
$ bin/rails generate model Book::Order
      invoke  active_record
      create    db/migrate/20240306194227_create_book_orders.rb
      create    app/models/book/order.rb
      create    app/models/book.rb
      invoke    test_unit
      create      test/models/book/order_test.rb
      create      test/fixtures/book/orders.yml
```

If the Book module already exists, you will be asked to resolve
the conflict:

```bash
$ bin/rails generate model Book::Order
      invoke  active_record
      create    db/migrate/20240305140356_create_book_orders.rb
      create    app/models/book/order.rb
    conflict    app/models/book.rb
  Overwrite /Users/bhumi/Code/rails_guides/app/models/book.rb? (enter "h" for help) [Ynaqdhm]
```

Once the namespaced model generation is successful, the Book and Order
classes look like this:

```ruby
# app/models/book.rb
module Book
  def self.table_name_prefix
    "book_"
  end
end

# app/models/book/order.rb
class Book::Order < ApplicationRecord
end
```

Setting the
table_name_prefix
in Book will allow Order model's database table to be named
book_orders, instead of plain orders.

The other possibility is that you already have a Book model that you want
to keep in app/models. In that case, you can choose n to not overwrite
book.rb during the generate command.

This will still allow for a namespaced table name for Book::Order class,
without needing the table_name_prefix:

```ruby
# app/models/book.rb
class Book < ApplicationRecord
  # existing code
end

Book::Order.table_name
# => "book_orders"
```

## 4. Overriding the Naming Conventions

What if you need to follow a different naming convention or need to use your
Rails application with a legacy database? No problem, you can easily override
the default conventions.

Since ApplicationRecord inherits from ActiveRecord::Base, your application's
models will have a number of helpful methods available to them. For example, you
can use the ActiveRecord::Base.table_name= method to customize the table name
that should be used:

```ruby
class Book < ApplicationRecord
  self.table_name = "my_books"
end
```

If you do so, you will have to manually define the class name that is hosting
the fixtures (my_books.yml) using the
set_fixture_class method in your test definition:

```ruby
# test/models/book_test.rb
class BookTest < ActiveSupport::TestCase
  set_fixture_class my_books: Book
  fixtures :my_books
  # ...
end
```

It's also possible to override the column that should be used as the table's
primary key using the ActiveRecord::Base.primary_key= method:

```ruby
class Book < ApplicationRecord
  self.primary_key = "book_id"
end
```

Active Record does not recommend using non-primary key columns named
id. Using a column named id which is not a single-column primary key
complicates the access to the column value. The application will have to use the
id_value alias attribute to access the value of the non-PK id column.

If you try to create a column named id which is not the primary key,
Rails will throw an error during migrations such as: you can't redefine the
primary key column 'id' on 'my_books'. To define a custom primary key, pass {
id: false } to create_table.

## 5. CRUD: Reading and Writing Data

CRUD is an acronym for the four verbs we use to operate on data: Create,
Read, Update, and Delete. Active Record automatically creates methods
to allow you to read and manipulate data stored in your application's database
tables.

Active Record makes it seamless to perform CRUD operations by using these
high-level methods that abstract away database access details. Note that all of
these convenient methods result in SQL statement(s) that are executed against
the underlying database.

The examples below show a few of the CRUD methods as well as the resulting SQL
statements.

### 5.1. Create

Active Record objects can be created from a hash, a block, or have their
attributes manually set after creation. The new method will return a new,
non-persisted object, while create will save the object to the database and
return it.

For example, given a Book model with attributes of title and author, the
create method call will create an object and save a new record to the
database:

```ruby
book = Book.create(title: "The Lord of the Rings", author: "J.R.R. Tolkien")

# Note that the `id` is assigned as this record is committed to the database.
book.inspect
# => "#<Book id: 106, title: \"The Lord of the Rings\", author: \"J.R.R. Tolkien\", created_at: \"2024-03-04 19:15:58.033967000 +0000\", updated_at: \"2024-03-04 19:15:58.033967000 +0000\">"
```

While the new method will instantiate an object without saving it to the
database:

```ruby
book = Book.new
book.title = "The Hobbit"
book.author = "J.R.R. Tolkien"

# Note that the `id` is not set for this object.
book.inspect
# => "#<Book id: nil, title: \"The Hobbit\", author: \"J.R.R. Tolkien\", created_at: nil, updated_at: nil>"

# The above `book` is not yet saved to the database.

book.save
book.id # => 107

# Now the `book` record is committed to the database and has an `id`.
```

If a block is provided, both create and new will yield the new object to that block for initialization, while only create will persist the resulting object to the database:

```ruby
book = Book.new do |b|
  b.title = "Metaprogramming Ruby 2"
  b.author = "Paolo Perrotta"
end

book.save
```

The resulting SQL statement from both book.save and Book.create look
something like this:

```sql
/* Note that `created_at` and `updated_at` are automatically set. */

INSERT INTO "books" ("title", "author", "created_at", "updated_at") VALUES (?, ?, ?, ?) RETURNING "id"  [["title", "Metaprogramming Ruby 2"], ["author", "Paolo Perrotta"], ["created_at", "2024-02-22 20:01:18.469952"], ["updated_at", "2024-02-22 20:01:18.469952"]]
```

Finally, if you'd like to insert several records without callbacks or
validations, you can directly insert records into the database using insert or insert_all methods:

```ruby
Book.insert(title: "The Lord of the Rings", author: "J.R.R. Tolkien")
Book.insert_all([{ title: "The Lord of the Rings", author: "J.R.R. Tolkien" }])
```

### 5.2. Read

Active Record provides a rich API for accessing data within a database. You can
query a single record or multiple records, filter them by any attribute, order
them, group them, select specific fields, and do anything you can do with SQL.

```ruby
# Return a collection with all books.
books = Book.all

# Return a single book.
first_book = Book.first
last_book = Book.last
book = Book.take
```

The above results in the following SQL:

```sql
-- Book.all
SELECT "books".* FROM "books"

-- Book.first
SELECT "books".* FROM "books" ORDER BY "books"."id" ASC LIMIT ?  [["LIMIT", 1]]

-- Book.last
SELECT "books".* FROM "books" ORDER BY "books"."id" DESC LIMIT ?  [["LIMIT", 1]]

-- Book.take
SELECT "books".* FROM "books" LIMIT ?  [["LIMIT", 1]]
```

We can also find specific books with find_by and where. While find_by
returns a single record, where returns a list of records:

```ruby
# Returns the first book with a given title or `nil` if no book is found.
book = Book.find_by(title: "Metaprogramming Ruby 2")

# Alternative to Book.find_by(id: 42). Will throw an exception if no matching book is found.
book = Book.find(42)
```

The above resulting in this SQL:

```sql
-- Book.find_by(title: "Metaprogramming Ruby 2")
SELECT "books".* FROM "books" WHERE "books"."title" = ? LIMIT ?  [["title", "Metaprogramming Ruby 2"], ["LIMIT", 1]]

-- Book.find(42)
SELECT "books".* FROM "books" WHERE "books"."id" = ? LIMIT ?  [["id", 42], ["LIMIT", 1]]
```

```ruby
# Find all books by a given author, sort by created_at in reverse chronological order.
Book.where(author: "Douglas Adams").order(created_at: :desc)
```

resulting in this SQL:

```sql
SELECT "books".* FROM "books" WHERE "books"."author" = ? ORDER BY "books"."created_at" DESC [["author", "Douglas Adams"]]
```

There are many more Active Record methods to read and query records. You can
learn more about them in the Active Record Query guide.

### 5.3. Update

Once an Active Record object has been retrieved, its attributes can be modified
and it can be saved to the database.

```ruby
book = Book.find_by(title: "The Lord of the Rings")
book.title = "The Lord of the Rings: The Fellowship of the Ring"
book.save
```

A shorthand for this is to use a hash mapping attribute names to the desired
value, like so:

```ruby
book = Book.find_by(title: "The Lord of the Rings")
book.update(title: "The Lord of the Rings: The Fellowship of the Ring")
```

the update results in the following SQL:

```sql
/* Note that `updated_at` is automatically set. */

 UPDATE "books" SET "title" = ?, "updated_at" = ? WHERE "books"."id" = ?  [["title", "The Lord of the Rings: The Fellowship of the Ring"], ["updated_at", "2024-02-22 20:51:13.487064"], ["id", 104]]
```

This is useful when updating several attributes at once. Similar to create,
using update will commit the updated records to the database.

If you'd like to update several records in bulk without callbacks or
validations, you can update the database directly using update_all:

```ruby
Book.update_all(status: "already own")
```

### 5.4. Delete

Likewise, once retrieved, an Active Record object can be destroyed, which
removes it from the database.

```ruby
book = Book.find_by(title: "The Lord of the Rings")
book.destroy
```

The destroy results in this SQL:

```sql
DELETE FROM "books" WHERE "books"."id" = ?  [["id", 104]]
```

If you'd like to delete several records in bulk, you may use destroy_by
or destroy_all method:

```ruby
# Find and delete all books by Douglas Adams.
Book.destroy_by(author: "Douglas Adams")

# Delete all books.
Book.destroy_all
```

Additionally, if you'd like to delete several records without callbacks or
validations, you can delete records directly from the database using delete and delete_all methods:

```ruby
Book.find_by(title: "The Lord of the Rings").delete
Book.delete_all
```

## 6. Validations

Active Record allows you to validate the state of a model before it gets written
into the database. There are several methods that allow for different types of
validations. For example, validate that an attribute value is not empty, is
unique, is not already in the database, follows a specific format, and many
more.

Methods like save, create and update validate a model before persisting it
to the database. If the model is invalid, no database operations are performed. In
this case the save and update methods return false. The create method still
returns the object, which can be checked for errors. All of these
methods have a bang counterpart (that is, save!, create! and update!),
which are stricter in that they raise an ActiveRecord::RecordInvalid exception
when validation fails. A quick example to illustrate:

```ruby
class User < ApplicationRecord
  validates :name, presence: true
end
```

```
irb> user = User.new
irb> user.save
=> false
irb> user.save!
ActiveRecord::RecordInvalid: Validation failed: Name can't be blank
```

The create method always returns the model, regardless of
its validity. You can then inspect this model for any errors.

```
irb> user = User.create
=> #<User:0x000000013e8b5008 id: nil, name: nil>
irb> user.errors.full_messages
=> ["Name can't be blank"]
```

You can learn more about validations in the Active Record Validations
guide.

## 7. Callbacks

Active Record callbacks allow you to attach code to certain events in the
lifecycle of your models. This enables you to add behavior to your models by
executing code when those events occur, like when you create a new record,
update it, destroy it, and so on.

```ruby
class User < ApplicationRecord
  after_create :log_new_user

  private
    def log_new_user
      puts "A new user was registered"
    end
end
```

```
irb> @user = User.create
A new user was registered
```

You can learn more about callbacks in the Active Record Callbacks
guide.

## 8. Migrations

Rails provides a convenient way to manage changes to a database schema via
migrations. Migrations are written in a domain-specific language and stored in
files which are executed against any database that Active Record supports.

Here's a migration that creates a new table called publications:

```ruby
class CreatePublications < ActiveRecord::Migration[8.1]
  def change
    create_table :publications do |t|
      t.string :title
      t.text :description
      t.references :publication_type
      t.references :publisher, polymorphic: true
      t.boolean :single_issue

      t.timestamps
    end
  end
end
```

Note that the above code is database-agnostic: it will run in MySQL, MariaDB,
PostgreSQL, SQLite, and others.

Rails keeps track of which migrations have been committed to the database and
stores them in a neighboring table in that same database called
schema_migrations.

To run the migration and create the table, you'd run bin/rails db:migrate, and
to roll it back and delete the table, bin/rails db:rollback.

You can learn more about migrations in the Active Record Migrations
guide.

## 9. Associations

Active Record associations allow you to define relationships between models.
Associations can be used to describe one-to-one, one-to-many, and many-to-many
relationships. For example, a relationship like “Author has many Books” can be
defined as follows:

```ruby
class Author < ApplicationRecord
  has_many :books
end
```

The Author class now has methods to add and remove books to an author, and
much more.

You can learn more about associations in the Active Record Associations
guide.

---

# Chapters


---

Migrations are a feature of Active Record that allows you to evolve your
database schema over time. Rather than write schema modifications in pure SQL,
migrations allow you to use a Ruby Domain Specific Language (DSL) to describe
changes to your tables.

After reading this guide, you will know:

- Which generators you can use to create migrations.

- Which methods Active Record provides to manipulate your database.

- How to change existing migrations and update your schema.

- How migrations relate to schema.rb.

- How to maintain referential integrity.

## 1. Migration Overview

Migrations are a convenient way to evolve your database schema over
time in a reproducible way.
They use a Ruby DSL so
that you don't have to write SQL by hand,
allowing your schema and changes to be database independent. We recommend that
you read the guides for Active Record Basics and
the Active Record Associations to learn more about
some of the concepts mentioned here.

You can think of each migration as being a new 'version' of the database. A
schema starts off with nothing in it, and each migration modifies it to add or
remove tables, columns, or indexes. Active Record knows how to update your
schema along this timeline, bringing it from whatever point it is in the history
to the latest version. Read more about how Rails knows which migration in the
timeline to run.

Active Record updates your db/schema.rb file to match the up-to-date structure
of your database. Here's an example of a migration:

```ruby
# db/migrate/20240502100843_create_products.rb
class CreateProducts < ActiveRecord::Migration[8.1]
  def change
    create_table :products do |t|
      t.string :name
      t.text :description

      t.timestamps
    end
  end
end
```

This migration adds a table called products with a string column called name
and a text column called description. A primary key column called id will
also be added implicitly, as it's the default primary key for all Active Record
models. The timestamps macro adds two columns, created_at and updated_at.
These special columns are automatically managed by Active Record if they exist.

```ruby
# db/schema.rb
ActiveRecord::Schema[8.1].define(version: 2024_05_02_100843) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "products", force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end
end
```

We define the change that we want to happen moving forward in time. Before this
migration is run, there will be no table. After it is run, the table will exist.
Active Record knows how to reverse this migration as well; if we roll this
migration back, it will remove the table. Read more about rolling back
migrations in the Rolling Back section.

After defining the change that we want to occur moving forward in time, it's
essential to consider the reversibility of the migration. While Active Record
can manage the forward progression of the migration, ensuring the creation of
the table, the concept of reversibility becomes crucial. With reversible
migrations, not only does the migration create the table when applied, but it
also enables smooth rollback functionality. In case of reverting the migration
above, Active Record intelligently handles the removal of the table, maintaining
database consistency throughout the process. See the Reversing
Migrations section for more details.

## 2. Generating Migration Files

### 2.1. Creating a Standalone Migration

Migrations are stored as files in the db/migrate directory, one for each
migration class.

The name of the file is of the form YYYYMMDDHHMMSS_create_products.rb, it
contains a UTC timestamp identifying the migration followed by an underscore
followed by the name of the migration. The name of the migration class
(CamelCased version) should match the latter part of the file name.

For example, 20240502100843_create_products.rb should define class
CreateProducts and 20240502101659_add_details_to_products.rb should define
class AddDetailsToProducts. Rails uses this timestamp to determine which
migration should be run and in what order, so if you're copying a migration from
another application or generating a file yourself, be aware of its position in
the order. You can read more about how the timestamps are used in the Rails
Migration Version Control section.

You can override the directory that migrations are stored in by setting the
migrations_paths option in your config/database.yml.

When generating a migration, Active Record automatically prepends the current
timestamp to the file name of the migration. For example, running the command
below will create an empty migration file whereby the filename is made up of a
timestamp prepended to the underscored name of the migration.

```bash
bin/rails generate migration AddPartNumberToProducts
```

```ruby
# db/migrate/20240502101659_add_part_number_to_products.rb
class AddPartNumberToProducts < ActiveRecord::Migration[8.1]
  def change
  end
end
```

The generator can do much more than prepend a timestamp to the file name. Based
on naming conventions and additional (optional) arguments it can also start
fleshing out the migration.

The following sections will cover the various ways you can create migrations
based on conventions and additional arguments.

### 2.2. Creating a New Table

When you want to create a new table in your database, you can use a migration
with the format "CreateXXX" followed by a list of column names and types. This
will generate a migration file that sets up the table with the specified
columns.

```bash
bin/rails generate migration CreateProducts name:string part_number:string
```

generates

```ruby
class CreateProducts < ActiveRecord::Migration[8.1]
  def change
    create_table :products do |t|
      t.string :name
      t.string :part_number

      t.timestamps
    end
  end
end
```

If you don't specify a type for a field (e.g., name instead of name:string), Rails will default to type string.

The generated file with its contents is just a starting point, and you can add
or remove from it as you see fit by editing the
db/migrate/YYYYMMDDHHMMSS_create_products.rb file.

### 2.3. Adding Columns

When you want to add a new column to an existing table in your database, you can
use a migration with the format "AddColumnToTable" followed by a list of column
names and types. This will generate a migration file containing the appropriate
add_column statements.

```bash
bin/rails generate migration AddPartNumberToProducts part_number:string
```

This will generate the following migration:

```ruby
class AddPartNumberToProducts < ActiveRecord::Migration[8.1]
  def change
    add_column :products, :part_number, :string
  end
end
```

Rails infers the target table from the migration name when it matches the
add_<columns>_to_<table> or remove_<columns>_from_<table> patterns. Using a
name such as AddPartNumberToProducts lets the generator configure
add_column :products, ... automatically. For more on these conventions, run
bin/rails generate migration --help to see the generator usage and examples.

If you'd like to add an index on the new column, you can do that as well.

```bash
bin/rails generate migration AddPartNumberToProducts part_number:string:index
```

This will generate the appropriate add_column and add_index
statements:

```ruby
class AddPartNumberToProducts < ActiveRecord::Migration[8.1]
  def change
    add_column :products, :part_number, :string
    add_index :products, :part_number
  end
end
```

You are not limited to one magically generated column. For example:

```bash
bin/rails generate migration AddDetailsToProducts part_number:string price:decimal
```

This will generate a schema migration which adds two additional columns to the
products table.

```ruby
class AddDetailsToProducts < ActiveRecord::Migration[8.1]
  def change
    add_column :products, :part_number, :string
    add_column :products, :price, :decimal
  end
end
```

### 2.4. Removing Columns

Similarly, if the migration name is of the form "RemoveColumnFromTable" and is
followed by a list of column names and types then a migration containing the
appropriate remove_column statements will be created.

```bash
bin/rails generate migration RemovePartNumberFromProducts part_number:string
```

This will generate the appropriate remove_column statements:

```ruby
class RemovePartNumberFromProducts < ActiveRecord::Migration[8.1]
  def change
    remove_column :products, :part_number, :string
  end
end
```

### 2.5. Creating Associations

Active Record associations are used to define relationships between different
models in your application, allowing them to interact with each other through
their relationships and making it easier to work with related data. To learn
more about associations, you can refer to the Association Basics
guide.

One common use case for associations is creating foreign key references between
tables. The generator accepts column types such as references to facilitate
this process. References are a shorthand for creating columns,
indexes, foreign keys, or even polymorphic association columns.

For example,

```bash
bin/rails generate migration AddUserRefToProducts user:references
```

generates the following add_reference call:

```ruby
class AddUserRefToProducts < ActiveRecord::Migration[8.1]
  def change
    add_reference :products, :user, null: false, foreign_key: true
  end
end
```

The above migration creates a foreign key called user_id in the products
table, where user_id is a reference to the id column in the users table.
It also creates an index for the user_id column. The schema looks as follows:

```ruby
create_table "products", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_products_on_user_id"
  end
```

belongs_to is an alias of references, so the above could be alternatively
written as:

```bash
bin/rails generate migration AddUserRefToProducts user:belongs_to
```

generating a migration and schema that is the same as above.

There is also a generator which will produce join tables if JoinTable is part
of the name:

```bash
bin/rails generate migration CreateJoinTableUserProduct user product
```

will produce the following migration:

```ruby
class CreateJoinTableUserProduct < ActiveRecord::Migration[8.1]
  def change
    create_join_table :users, :products do |t|
      # t.index [:user_id, :product_id]
      # t.index [:product_id, :user_id]
    end
  end
end
```

### 2.6. Other Generators that Create Migrations

In addition to the migration generator, the model, resource, and
scaffold generators will create migrations appropriate for adding a new model.
This migration will already contain instructions for creating the relevant
table. If you tell Rails what columns you want, then statements for adding these
columns will also be created. For example, running:

```bash
bin/rails generate model Product name:string description:text
```

This will create a migration that looks like this:

```ruby
class CreateProducts < ActiveRecord::Migration[8.1]
  def change
    create_table :products do |t|
      t.string :name
      t.text :description

      t.timestamps
    end
  end
end
```

You can append as many column name/type pairs as you want.

### 2.7. Passing Modifiers

When generating migrations, you can pass commonly used type
modifiers directly on the command line. These modifiers,
enclosed by curly braces and following the field type, allow you to tailor the
characteristics of your database columns without needing to manually edit the
migration file afterward.

For instance, running:

```bash
bin/rails generate migration AddDetailsToProducts 'price:decimal{5,2}' supplier:references{polymorphic}
```

will produce a migration that looks like this

```ruby
class AddDetailsToProducts < ActiveRecord::Migration[8.1]
  def change
    add_column :products, :price, :decimal, precision: 5, scale: 2
    add_reference :products, :supplier, polymorphic: true
  end
end
```

NOT NULL constraints can be imposed from the command line using the !
shortcut:

```bash
bin/rails generate migration AddEmailToUsers email:string!
```

will produce this migration

```ruby
class AddEmailToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :email, :string, null: false
  end
end
```

For further help with generators, run bin/rails generate --help.
Alternatively, you can also run bin/rails generate model --help or bin/rails
generate migration --help for help with specific generators.

## 3. Updating Migrations

Once you have created your migration file using one of the generators from the
above section, you can update the generated
migration file in the db/migrate folder to define further changes you want to
make to your database schema.

### 3.1. Creating a Table

The create_table method is one of the most fundamental migration type, but
most of the time, will be generated for you from using a model, resource, or
scaffold generator. A typical use would be

```ruby
create_table :products do |t|
  t.string :name
end
```

This method creates a products table with a column called name.

#### 3.1.1. Associations

If you're creating a table for a model that has an association, you can use the
:references type to create the appropriate column type. For example:

```ruby
create_table :products do |t|
  t.references :category
end
```

This will create a category_id column. Alternatively, you can use belongs_to
as an alias for references:

```ruby
create_table :products do |t|
  t.belongs_to :category
end
```

You can also specify the column type and index creation using the
:polymorphic option:

```ruby
create_table :taggings do |t|
  t.references :taggable, polymorphic: true
end
```

This will create taggable_id, taggable_type columns and the appropriate
indexes.

#### 3.1.2. Primary Keys

By default, create_table will implicitly create a primary key called id for
you. You can change the name of the column with the :primary_key option, like
below:

```ruby
class CreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :users, primary_key: "user_id" do |t|
      t.string :username
      t.string :email
      t.timestamps
    end
  end
end
```

This will yield the following schema:

```ruby
create_table "users", primary_key: "user_id", force: :cascade do |t|
  t.string "username"
  t.string "email"
  t.datetime "created_at", precision: 6, null: false
  t.datetime "updated_at", precision: 6, null: false
end
```

You can also pass an array to :primary_key for a composite primary key. Read
more about composite primary keys.

```ruby
class CreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :users, primary_key: [:id, :name] do |t|
      t.string :name
      t.string :email
      t.timestamps
    end
  end
end
```

If you don't want a primary key at all, you can pass the option id: false.

```ruby
class CreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :users, id: false do |t|
      t.string :username
      t.string :email
      t.timestamps
    end
  end
end
```

#### 3.1.3. Database Options

If you need to pass database-specific options you can place an SQL fragment in
the :options option. For example:

```ruby
create_table :products, options: "ENGINE=BLACKHOLE" do |t|
  t.string :name, null: false
end
```

This will append ENGINE=BLACKHOLE to the SQL statement used to create the
table.

An index can be created on the columns created within the create_table block
by passing index: true or an options hash to the :index option:

```ruby
create_table :users do |t|
  t.string :name, index: true
  t.string :email, index: { unique: true, name: "unique_emails" }
end
```

#### 3.1.4. Comments

You can pass the :comment option with any description for the table that will
be stored in the database itself and can be viewed with database administration
tools, such as MySQL Workbench or PgAdmin III. Comments can help team members to
better understand the data model and to generate documentation in applications
with large databases. Currently only the MySQL and PostgreSQL adapters support
comments.

```ruby
class AddDetailsToProducts < ActiveRecord::Migration[8.1]
  def change
    add_column :products, :price, :decimal, precision: 8, scale: 2, comment: "The price of the product in USD"
    add_column :products, :stock_quantity, :integer, comment: "The current stock quantity of the product"
  end
end
```

### 3.2. Creating a Join Table

The migration method create_join_table creates an HABTM (has and belongs
to many) join
table. A typical use would be:

```ruby
create_join_table :products, :categories
```

This migration will create a categories_products table with two columns called
category_id and product_id.

These columns have the option :null set to false by default, meaning that
you must provide a value in order to save a record to this table. This can
be overridden by specifying the :column_options option:

```ruby
create_join_table :products, :categories, column_options: { null: true }
```

By default, the name of the join table comes from the union of the first two
arguments provided to create_join_table, in lexical order. In this case,
the table would be named categories_products.

The precedence between model names is calculated using the <=>
operator for String. This means that if the strings are of different lengths,
and the strings are equal when compared up to the shortest length, then the
longer string is considered of higher lexical precedence than the shorter one.
For example, one would expect the tables "paper_boxes" and "papers" to generate
a join table name of "papers_paper_boxes" because of the length of the name
"paper_boxes", but it in fact generates a join table name of
"paper_boxes_papers" (because the underscore '_' is lexicographically less
than 's' in common encodings).

To customize the name of the table, provide a :table_name option:

```ruby
create_join_table :products, :categories, table_name: :categorization
```

This creates a join table with the name categorization.

Also, create_join_table accepts a block, which you can use to add indices
(which are not created by default) or any additional columns you so choose.

```ruby
create_join_table :products, :categories do |t|
  t.index :product_id
  t.index :category_id
end
```

### 3.3. Changing Tables

If you want to change an existing table in place, there is change_table.

It is used in a similar fashion to create_table but the object yielded inside
the block has access to a number of special functions, for example:

```ruby
change_table :products do |t|
  t.remove :description, :name
  t.string :part_number
  t.index :part_number
  t.rename :upccode, :upc_code
end
```

This migration will remove the description and name columns, create a new
string column called part_number and add an index on it. Finally, it renames
the upccode column to upc_code.

### 3.4. Changing Columns

Similar to the remove_column and add_column methods we covered
earlier, Rails also provides the change_column
migration method.

```ruby
change_column :products, :part_number, :text
```

This changes the column part_number on products table to be a :text field.

The change_column command is irreversible. To ensure your migration
can be safely reverted, you will need to provide your own reversible
migration. See the Reversible Migrations section for more
details.

Besides change_column, the change_column_null and
change_column_default methods are used to change a null constraint and
default values of a column.

```ruby
change_column_default :products, :approved, from: true, to: false
```

This changes the default value of the :approved field from true to false. This
change will only be applied to future records, any existing records do not
change. Use change_column_null to change a null constraint.

```ruby
change_column_null :products, :name, false
```

This sets :name field on products to a NOT NULL column. This change applies
to existing records as well, so you need to make sure all existing records have
a :name that is NOT NULL.

Setting the null constraint to true implies that column will accept a null
value, otherwise the NOT NULL constraint is applied and a value must be passed
in order to persist the record to the database.

You could also write the above change_column_default migration as
change_column_default :products, :approved, false, but unlike the previous
example, this would make your migration irreversible.

### 3.5. Column Modifiers

Column modifiers can be applied when creating or changing a column:

- comment      Adds a comment for the column.

- collation    Specifies the collation for a string or text column.

- default      Allows to set a default value on the column. Note that if you
are using a dynamic value (such as a date), the default will only be
calculated the first time (i.e. on the date the migration is applied). Use
nil for NULL.

- limit        Sets the maximum number of characters for a string column and
the maximum number of bytes for text/binary/integer columns.

- null         Allows or disallows NULL values in the column.

- precision    Specifies the precision for decimal/numeric/datetime/time
columns.

- scale        Specifies the scale for the decimal and numeric columns,
representing the number of digits after the decimal point.

For add_column or change_column there is no option for adding indexes.
They need to be added separately using add_index.

Some adapters may support additional options; see the adapter specific API docs
for further information.

default cannot be specified via command line when generating migrations.

### 3.6. References

The add_reference method allows the creation of an appropriately named column
acting as the connection between one or more associations.

```ruby
add_reference :users, :role
```

This migration will create a foreign key column called role_id in the users
table. role_id is a reference to the id column in the roles table. In
addition, it creates an index for the role_id column, unless it is explicitly
told not to do so with the index: false option.

See also the Active Record Associations guide to learn more.

The method add_belongs_to is an alias of add_reference.

```ruby
add_belongs_to :taggings, :taggable, polymorphic: true
```

The polymorphic option will create two columns on the taggings table which can
be used for polymorphic associations: taggable_type and taggable_id.

See this guide to learn more about polymorphic associations.

A foreign key can be created with the foreign_key option.

```ruby
add_reference :users, :role, foreign_key: true
```

For more add_reference options, visit the API
documentation.

References can also be removed:

```ruby
remove_reference :products, :user, foreign_key: true, index: false
```

### 3.7. Foreign Keys

While it's not required, you might want to add foreign key constraints to
guarantee referential integrity.

```ruby
add_foreign_key :articles, :authors
```

The add_foreign_key call adds a new constraint to the articles table.
The constraint guarantees that a row in the authors table exists where the
id column matches the articles.author_id to ensure all reviewers listed in
the articles table are valid authors listed in the authors table.

When using references in a migration, you are creating a new column in
the table and you'll have the option to add a foreign key using foreign_key:
true to that column. However, if you want to add a foreign key to an existing
column, you can use add_foreign_key.

If the column name of the table to which we're adding the foreign key cannot be
derived from the table with the referenced primary key then you can use the
:column option to specify the column name. Additionally, you can use the
:primary_key option if the referenced primary key is not :id.

For example, to add a foreign key on articles.reviewer referencing
authors.email:

```ruby
add_foreign_key :articles, :authors, column: :reviewer, primary_key: :email
```

This will add a constraint to the articles table that guarantees a row in the
authors table exists where the email column matches the articles.reviewer
field.

Several other options such as name, on_delete, if_not_exists, validate,
and deferrable are supported by add_foreign_key.

Foreign keys can also be removed using remove_foreign_key:

```ruby
# let Active Record figure out the column name
remove_foreign_key :accounts, :branches

# remove foreign key for a specific column
remove_foreign_key :accounts, column: :owner_id
```

Active Record only supports single column foreign keys. execute and
structure.sql are required to use composite foreign keys. See Schema Dumping
and You.

### 3.8. Composite Primary Keys

Sometimes a single column's value isn't enough to uniquely identify every row of
a table, but a combination of two or more columns does uniquely identify it.
This can be the case when using a legacy database schema without a single id
column as a primary key, or when altering schemas for sharding or multitenancy.

You can create a table with a composite primary key by passing the
:primary_key option to create_table with an array value:

```ruby
class CreateProducts < ActiveRecord::Migration[8.1]
  def change
    create_table :products, primary_key: [:customer_id, :product_sku] do |t|
      t.integer :customer_id
      t.string :product_sku
      t.text :description
    end
  end
end
```

Tables with composite primary keys require passing array values rather
than integer IDs to many methods. See also the Active Record Composite Primary
Keys guide to learn more.

### 3.9. Execute SQL

If the helpers provided by Active Record aren't enough, you can use the
execute method to execute SQL commands. For example,

```ruby
class UpdateProductPrices < ActiveRecord::Migration[8.1]
  def up
    execute "UPDATE products SET price = 'free'"
  end

  def down
    execute "UPDATE products SET price = 'original_price' WHERE price = 'free';"
  end
end
```

In this example, we're updating the price column of the products table to
'free' for all records.

Modifying data directly in migrations should be approached with
caution. Consider if this is the best approach for your use case, and be aware
of potential drawbacks such as increased complexity and maintenance overhead,
risks to data integrity and database portability. See the Data Migrations
documentation for more details.

For more details and examples of individual methods, check the API
documentation.

In particular the documentation for
ActiveRecord::ConnectionAdapters::SchemaStatements, which provides the
methods available in the change, up and down methods.

For methods available regarding the object yielded by create_table, see
ActiveRecord::ConnectionAdapters::TableDefinition.

And for the object yielded by change_table, see
ActiveRecord::ConnectionAdapters::Table.

### 3.10. Using the change Method

The change method is the primary way of writing migrations. It works for the
majority of cases in which Active Record knows how to reverse a migration's
actions automatically. Below are some of the actions that change supports:

- add_check_constraint

- add_column

- add_foreign_key

- add_index

- add_reference

- add_timestamps

- change_column_comment (must supply :from and :to options)

- change_column_default (must supply :from and :to options)

- change_column_null

- change_table_comment (must supply :from and :to options)

- create_join_table

- create_table

- disable_extension

- drop_join_table

- drop_table (must supply table creation options and block)

- enable_extension

- remove_check_constraint (must supply original constraint expression)

- remove_column (must supply original type and column options)

- remove_columns (must supply original type and column options)

- remove_foreign_key (must supply other table and original options)

- remove_index (must supply columns and original options)

- remove_reference (must supply original options)

- remove_timestamps (must supply original options)

- rename_column

- rename_index

- rename_table

change_table is also reversible, as long as the block only calls
reversible operations like the ones listed above.

If you need to use any other methods, you should use reversible or write the
up and down methods instead of using the change method.

### 3.11. Using reversible

If you'd like for a migration to do something that Active Record doesn't know
how to reverse, then you can use reversible to specify what to do when running
a migration and what else to do when reverting it.

```ruby
class ChangeProductsPrice < ActiveRecord::Migration[8.1]
  def change
    reversible do |direction|
      change_table :products do |t|
        direction.up   { t.change :price, :string }
        direction.down { t.change :price, :integer }
      end
    end
  end
end
```

This migration will change the type of the price column to a string, or back
to an integer when the migration is reverted. Notice the block being passed to
direction.up and direction.down respectively.

Alternatively, you can use up and down instead of change:

```ruby
class ChangeProductsPrice < ActiveRecord::Migration[8.1]
  def up
    change_table :products do |t|
      t.change :price, :string
    end
  end

  def down
    change_table :products do |t|
      t.change :price, :integer
    end
  end
end
```

Additionally, reversible is useful when executing raw SQL queries or
performing database operations that do not have a direct equivalent in
ActiveRecord methods. You can use reversible to specify what to do when
running a migration and what else to do when reverting it. For example:

```ruby
class ExampleMigration < ActiveRecord::Migration[8.1]
  def change
    create_table :distributors do |t|
      t.string :zipcode
    end

    reversible do |direction|
      direction.up do
        # create a distributors view
        execute <<-SQL
          CREATE VIEW distributors_view AS
          SELECT id, zipcode
          FROM distributors;
        SQL
      end
      direction.down do
        execute <<-SQL
          DROP VIEW distributors_view;
        SQL
      end
    end

    add_column :users, :address, :string
  end
end
```

Using reversible will ensure that the instructions are executed in the right
order too. If the previous example migration is reverted, the down block will
be run after the users.address column is removed and before the distributors
table is dropped.

### 3.12. Using the up/down Methods

You can also use the old style of migration using up and down methods
instead of the change method.

The up method should describe the transformation you'd like to make to your
schema, and the down method of your migration should revert the
transformations done by the up method. In other words, the database schema
should be unchanged if you do an up followed by a down.

For example, if you create a table in the up method, you should drop it in the
down method. It is wise to perform the transformations in precisely the
reverse order they were made in the up method. The example in the reversible
section is equivalent to:

```ruby
class ExampleMigration < ActiveRecord::Migration[8.1]
  def up
    create_table :distributors do |t|
      t.string :zipcode
    end

    # create a distributors view
    execute <<-SQL
      CREATE VIEW distributors_view AS
      SELECT id, zipcode
      FROM distributors;
    SQL

    add_column :users, :address, :string
  end

  def down
    remove_column :users, :address

    execute <<-SQL
      DROP VIEW distributors_view;
    SQL

    drop_table :distributors
  end
end
```

### 3.13. Throwing an error to prevent reverts

Sometimes your migration will do something which is just plain irreversible; for
example, it might destroy some data.

In such cases, you can raise ActiveRecord::IrreversibleMigration in your
down block.

```ruby
class IrreversibleMigrationExample < ActiveRecord::Migration[8.1]
  def up
    drop_table :example_table
  end

  def down
    raise ActiveRecord::IrreversibleMigration, "This migration cannot be reverted because it destroys data."
  end
end
```

If someone tries to revert your migration, an error message will be displayed
saying that it can't be done.

### 3.14. Reverting Previous Migrations

You can use Active Record's ability to rollback migrations using the
revert method:

```ruby
require_relative "20121212123456_example_migration"

class FixupExampleMigration < ActiveRecord::Migration[8.1]
  def change
    revert ExampleMigration

    create_table(:apples) do |t|
      t.string :variety
    end
  end
end
```

The revert method also accepts a block of instructions to reverse. This could
be useful to revert selected parts of previous migrations.

For example, let's imagine that ExampleMigration is committed and it is later
decided that a Distributors view is no longer needed.

```ruby
class DontUseDistributorsViewMigration < ActiveRecord::Migration[8.1]
  def change
    revert do
      # copy-pasted code from ExampleMigration
      create_table :distributors do |t|
        t.string :zipcode
      end

      reversible do |direction|
        direction.up do
          # create a distributors view
          execute <<-SQL
            CREATE VIEW distributors_view AS
            SELECT id, zipcode
            FROM distributors;
          SQL
        end
        direction.down do
          execute <<-SQL
            DROP VIEW distributors_view;
          SQL
        end
      end

      # The rest of the migration was ok
    end
  end
end
```

The same migration could also have been written without using revert but this
would have involved a few more steps:

- Reverse the order of create_table and reversible.

- Replace create_table with drop_table.

- Finally, replace up with down and vice-versa.

This is all taken care of by revert.

## 4. Running Migrations

Rails provides a set of commands to run certain sets of migrations.

The very first migration related rails command you will use will probably be
bin/rails db:migrate. In its most basic form it just runs the change or up
method for all the migrations that have not yet been run. If there are no such
migrations, it exits. It will run these migrations in order based on the date of
the migration.

Note that running the db:migrate command also invokes the db:schema:dump
command, which will update your db/schema.rb file to match the structure of
your database.

If you specify a target version, Active Record will run the required migrations
(change, up, down) until it has reached the specified version. The version is
the numerical prefix on the migration's filename. For example, to migrate to
version 20240428000000 run:

```bash
bin/rails db:migrate VERSION=20240428000000
```

If version 20240428000000 is greater than the current version (i.e., it is
migrating upwards), this will run the change (or up) method on all
migrations up to and including 20240428000000, and will not execute any later
migrations. If migrating downwards, this will run the down method on all the
migrations down to, but not including, 20240428000000.

### 4.1. Rolling Back

A common task is to rollback the last migration. For example, if you made a
mistake in it and wish to correct it. Rather than tracking down the version
number associated with the previous migration you can run:

```bash
bin/rails db:rollback
```

This will rollback the latest migration, either by reverting the change method
or by running the down method. If you need to undo several migrations you can
provide a STEP parameter:

```bash
bin/rails db:rollback STEP=3
```

The last 3 migrations will be reverted.

In some cases where you modify a local migration and would like to rollback that
specific migration before migrating back up again, you can use the
db:migrate:redo command. As with the db:rollback command, you can use the
STEP parameter if you need to go more than one version back, for example:

```bash
bin/rails db:migrate:redo STEP=3
```

You could get the same result using db:migrate. However, these are there
for convenience so that you do not need to explicitly specify the version to
migrate to.

#### 4.1.1. Transactions

In databases that support DDL transactions, changing the schema in a single
transaction, each migration is wrapped in a transaction.

A transaction ensures that if a migration fails partway through, any
changes that were successfully applied are rolled back, maintaining database
consistency. This means that either all operations within the transaction are
executed successfully, or none of them are, preventing the database from being
left in an inconsistent state if an error occurs during the transaction.

If the database does not support DDL transactions with statements that change
the schema, then when a migration fails, the parts of it that have succeeded
will not be rolled back. You will have to rollback the changes manually.

There are queries that you can’t execute inside a transaction though, and for
these situations you can turn the automatic transactions off with
disable_ddl_transaction!:

```ruby
class ChangeEnum < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def up
    execute "ALTER TYPE model_size ADD VALUE 'new_value'"
  end
end
```

Remember that you can still open your own transactions, even if you are in
a Migration with self.disable_ddl_transaction!.

### 4.2. Setting Up the Database

The bin/rails db:setup command will create the database, load the schema, and
initialize it with the seed data.

### 4.3. Preparing the Database

The bin/rails db:prepare command is similar to bin/rails db:setup, but it
operates idempotently, so it can safely be called several times, but it will
only perform the necessary tasks once.

- If the database has not been created yet, the command will run as the
bin/rails db:setup does.

- If the database exists but the tables have not been created, the command will
load the schema, run any pending migrations, dump the updated schema, and
finally load the seed data. See the Seeding Data
documentation for more details.

- If the database and tables exist, the command will do nothing.

Once the database and tables exist, the db:prepare task will not try to reload
the seed data, even if the previously loaded seed data or the existing seed file
have been altered or deleted. To reload the seed data, you can manually run
bin/rails db:seed:replant.

This task will only load seeds if one of the databases or tables created
is a primary database for the environment or is configured with seeds: true.

### 4.4. Resetting the Database

The bin/rails db:reset command will drop the database and set it up again.
This is functionally equivalent to bin/rails db:drop db:setup.

This is not the same as running all the migrations. It will only use the
contents of the current db/schema.rb or db/structure.sql file. If a
migration can't be rolled back, bin/rails db:reset may not help you. To find
out more about dumping the schema see Schema Dumping and You section.

If you need an alternative to db:reset that explicitly runs all migrations,
consider using the bin/rails db:migrate:reset command. You can follow that
command with bin/rails db:seed if needed.

bin/rails db:reset rebuilds the database using the current schema. On
the other hand, bin/rails db:migrate:reset replays all migrations from the
beginning, which can lead to schema drift if, for example, migrations have been
altered, reordered, or removed.

### 4.5. Running Specific Migrations

If you need to run a specific migration up or down, the db:migrate:up and
db:migrate:down commands will do that. Just specify the appropriate version
and the corresponding migration will have its change, up or down method
invoked, for example:

```bash
bin/rails db:migrate:up VERSION=20240428000000
```

By running this command the change method (or the up method) will be
executed for the migration with the version "20240428000000".

First, this command will check whether the migration exists and if it has
already been performed and if so, it will do nothing.

If the version specified does not exist, Rails will throw an exception.

```bash
$ bin/rails db:migrate VERSION=00000000000000
rails aborted!
ActiveRecord::UnknownMigrationVersionError:

No migration with version number 00000000000000.
```

### 4.6. Running Migrations in Different Environments

By default running bin/rails db:migrate will run in the development
environment.

To run migrations against another environment you can specify it using the
RAILS_ENV environment variable while running the command. For example to run
migrations against the test environment you could run:

```bash
bin/rails db:migrate RAILS_ENV=test
```

### 4.7. Changing the Output of Running Migrations

By default migrations tell you exactly what they're doing and how long it took.
A migration creating a table and adding an index might produce output like this

```
==  CreateProducts: migrating =================================================
-- create_table(:products)
   -> 0.0028s
==  CreateProducts: migrated (0.0028s) ========================================
```

Several methods are provided in migrations that allow you to control all this:

For example, take the following migration:

```ruby
class CreateProducts < ActiveRecord::Migration[8.1]
  def change
    suppress_messages do
      create_table :products do |t|
        t.string :name
        t.text :description
        t.timestamps
      end
    end

    say "Created a table"

    suppress_messages { add_index :products, :name }
    say "and an index!", true

    say_with_time "Waiting for a while" do
      sleep 10
      250
    end
  end
end
```

This will generate the following output:

```
==  CreateProducts: migrating =================================================
-- Created a table
   -> and an index!
-- Waiting for a while
   -> 10.0013s
   -> 250 rows
==  CreateProducts: migrated (10.0054s) =======================================
```

If you want Active Record to not output anything, then running bin/rails
db:migrate VERBOSE=false will suppress all output.

### 4.8. Rails Migration Version Control

Rails keeps track of which migrations have been run through the
schema_migrations table in the database. When you run a migration, Rails
inserts a row into the schema_migrations table with the version number of the
migration, stored in the version column. This allows Rails to determine which
migrations have already been applied to the database.

For example, if you have a migration file named 20240428000000_create_users.rb,
Rails will extract the version number (20240428000000) from the filename and
insert it into the schema_migrations table after the migration has been
successfully executed.

You can view the contents of the schema_migrations table directly in your
database management tool or by using Rails console:

```
rails dbconsole
```

Then, within the database console, you can query the schema_migrations table:

```sql
SELECT * FROM schema_migrations;
```

This will show you a list of all migration version numbers that have been
applied to the database. Rails uses this information to determine which
migrations need to be run when you run rails db:migrate or rails db:migrate:up
commands.

## 5. Changing Existing Migrations

Occasionally you will make a mistake when writing a migration. If you have
already run the migration, then you cannot just edit the migration and run the
migration again: Rails thinks it has already run the migration and so will do
nothing when you run bin/rails db:migrate. You must rollback the migration
(for example with bin/rails db:rollback), edit your migration, and then run
bin/rails db:migrate to run the corrected version.

In general, editing existing migrations that have been already committed to
source control is not a good idea. You will be creating extra work for yourself
and your co-workers and cause major headaches if the existing version of the
migration has already been run on production machines. Instead, you should write
a new migration that performs the changes you require.

However, editing a freshly generated migration that has not yet been committed
to source control (or, more generally, has not been propagated beyond your
development machine) is common.

The revert method can be helpful when writing a new migration to undo previous
migrations in whole or in part (see Reverting Previous Migrations above).

## 6. Schema Dumping and You

### 6.1. What are Schema Files for?

Migrations, mighty as they may be, are not the authoritative source for your
database schema. Your database remains the source of truth.

By default, Rails generates db/schema.rb which attempts to capture the current
state of your database schema.

It tends to be faster and less error prone to create a new instance of your
application's database by loading the schema file via bin/rails db:schema:load
than it is to replay the entire migration history. Old migrations may fail
to apply correctly if those migrations use changing external dependencies or
rely on application code which evolves separately from your migrations.

Schema files are also useful if you want a quick look at what attributes an
Active Record object has. This information is not in the model's code and is
frequently spread across several migrations, but the information is nicely
summed up in the schema file.

### 6.2. Types of Schema Dumps

The format of the schema dump generated by Rails is controlled by the
config.active_record.schema_format setting defined in
config/application.rb, or the schema_format value in the database configuration.
By default, the format is :ruby, or alternatively can be set to :sql.

#### 6.2.1. Using the default :ruby schema

When :ruby is selected, then the schema is stored in db/schema.rb. If you
look at this file you'll find that it looks an awful lot like one very big
migration:

```ruby
ActiveRecord::Schema[8.1].define(version: 2008_09_06_171750) do
  create_table "authors", force: true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "products", force: true do |t|
    t.string   "name"
    t.text     "description"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "part_number"
  end
end
```

In many ways this is exactly what it is. This file is created by inspecting the
database and expressing its structure using create_table, add_index, and so
on.

#### 6.2.2. Using the :sql schema dumper

However, db/schema.rb cannot express everything your database may support such
as triggers, sequences, stored procedures, etc.

While migrations may use execute to create database constructs that are not
supported by the Ruby migration DSL, these constructs may not be able to be
reconstituted by the schema dumper.

If you are using features like these, you should set the schema format to :sql
in order to get an accurate schema file that is useful to create new database
instances.

When the schema format is set to :sql, the database structure will be dumped
using a tool specific to the database into db/structure.sql. For example, for
PostgreSQL, the pg_dump utility is used. For MySQL and MariaDB, this file will
contain the output of SHOW CREATE TABLE for the various tables.

To load the schema from db/structure.sql, run bin/rails db:schema:load.
Loading this file is done by executing the SQL statements it contains. By
definition, this will create a perfect copy of the database's structure.

### 6.3. Schema Dumps and Source Control

Because schema files are commonly used to create new databases, it is strongly
recommended that you check your schema file into source control.

Merge conflicts can occur in your schema file when two branches modify schema.
To resolve these conflicts run bin/rails db:migrate to regenerate the schema
file.

Newly generated Rails apps will already have the migrations folder
included in the git tree, so all you have to do is be sure to add any new
migrations you add and commit them.

## 7. Active Record and Referential Integrity

The Active Record pattern suggests that intelligence should primarily reside in
your models rather than in the database. Consequently, features like triggers or
constraints, which delegate some of that intelligence back into the database,
are not always favored.

Validations such as validates :foreign_key, uniqueness: true are one way in
which models can enforce data integrity. The :dependent option on associations
allows models to automatically destroy child objects when the parent is
destroyed. Like anything which operates at the application level, these cannot
guarantee referential integrity and so some people augment them with foreign
key constraints in the database.

In practice, foreign key constraints and unique indexes are generally considered
safer when enforced at the database level. Although Active Record does not
provide direct support for working with these database-level features, you can
still use the execute method to run arbitrary SQL commands.

It's worth emphasizing that while the Active Record pattern emphasizes keeping
intelligence within models, neglecting to implement foreign keys and unique
constraints at the database level can potentially lead to integrity issues.
Therefore, it's advisable to complement the AR pattern with database-level
constraints where appropriate. These constraints should have their counterparts
explicitly defined in your code using associations and validations to ensure
data integrity across both application and database layers.

## 8. Migrations and Seed Data

The main purpose of the Rails migration feature is to issue commands that modify
the schema using a consistent process. Migrations can also be used to add or
modify data. This is useful in an existing database that can't be destroyed and
recreated, such as a production database.

```ruby
class AddInitialProducts < ActiveRecord::Migration[8.1]
  def up
    5.times do |i|
      Product.create(name: "Product ##{i}", description: "A product.")
    end
  end

  def down
    Product.delete_all
  end
end
```

To add initial data after a database is created, Rails has a built-in 'seeds'
feature that speeds up the process. This is especially useful when reloading the
database frequently in development and test environments, or when setting up
initial data for production.

To get started with this feature, open up db/seeds.rb and add some Ruby code,
then run bin/rails db:seed.

The code here should be idempotent so that it can be executed at any point
in every environment.

```ruby
["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
  MovieGenre.find_or_create_by!(name: genre_name)
end
```

This is generally a much cleaner way to set up the database of a blank
application.

## 9. Old Migrations

The db/schema.rb or db/structure.sql is a snapshot of the current state of
your database and is the authoritative source for rebuilding that database. This
makes it possible to delete or prune old migration files.

When you delete migration files in the db/migrate/ directory, any environment
where bin/rails db:migrate was run when those files still existed will hold a
reference to the migration timestamp specific to them inside an internal Rails
database table named schema_migrations. You can read more about this in the
Rails Migration Version Control section.

If you run the bin/rails db:migrate:status command, which displays the status
(up or down) of each migration, you should see ********** NO FILE **********
displayed next to any deleted migration file which was once executed on a
specific environment but can no longer be found in the db/migrate/ directory.

### 9.1. Migrations from Engines

When dealing with migrations from Engines, there's a caveat to consider.
Rake tasks to install migrations from engines are idempotent, meaning they will
have the same result no matter how many times they are called. Migrations
present in the parent application due to a previous installation are skipped,
and missing ones are copied with a new leading timestamp. If you deleted old
engine migrations and ran the install task again, you'd get new files with new
timestamps, and db:migrate would attempt to run them again.

Thus, you generally want to preserve migrations coming from engines. They have a
special comment like this:

```ruby
# This migration comes from blorgh (originally 20210621082949)
```

## 10. Miscellaneous

### 10.1. Using UUIDs instead of IDs for Primary Keys

By default, Rails uses auto-incrementing integers as primary keys for database
records. However, there are scenarios where using Universally Unique Identifiers
(UUIDs) as primary keys can be advantageous, especially in distributed systems
or when integration with external services is necessary. UUIDs provide a
globally unique identifier without relying on a centralized authority for
generating IDs.

#### 10.1.1. Enabling UUIDs in Rails

Before using UUIDs in your Rails application, you'll need to ensure that your
database supports storing them. Additionally, you may need to configure your
database adapter to work with UUIDs.

If you are using a version of PostgreSQL prior to 13, you may still need
to enable the pgcrypto extension to access the gen_random_uuid() function.

- Rails ConfigurationIn your Rails application configuration file (config/application.rb), add
the following line to configure Rails to generate UUIDs as primary keys by
default:
config.generators do |g|
  g.orm :active_record, primary_key_type: :uuid
end

This setting instructs Rails to use UUIDs as the default primary key type
for ActiveRecord models.

- Adding References with UUIDs:When creating associations between models using references, ensure that you
specify the data type as :uuid to maintain consistency with the primary key
type. For example:
create_table :posts, id: :uuid do |t|
  t.references :author, type: :uuid, foreign_key: true

  # Other columns

  t.timestamps
end

In this example, the author_id column in the posts table references the
id column of the authors table. By explicitly setting the type to :uuid,
you ensure that the foreign key column matches the data type of the primary
key it references. Adjust the syntax accordingly for other associations and
databases.

- Migration ChangesWhen generating migrations for your models, you'll notice that it specifies
the id to be of type uuid:
  $ bin/rails g migration CreateAuthors

class CreateAuthors < ActiveRecord::Migration[8.1]
  def change
    create_table :authors, id: :uuid do |t|
      t.timestamps
    end
  end
end

which results in the following schema:
create_table "authors", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
  t.datetime "created_at", precision: 6, null: false
  t.datetime "updated_at", precision: 6, null: false
end

In this migration, the id column is defined as a UUID primary key with a
default value generated by the gen_random_uuid() function.

Rails Configuration

In your Rails application configuration file (config/application.rb), add
the following line to configure Rails to generate UUIDs as primary keys by
default:

```ruby
config.generators do |g|
  g.orm :active_record, primary_key_type: :uuid
end
```

This setting instructs Rails to use UUIDs as the default primary key type
for ActiveRecord models.

Adding References with UUIDs:

When creating associations between models using references, ensure that you
specify the data type as :uuid to maintain consistency with the primary key
type. For example:

```ruby
create_table :posts, id: :uuid do |t|
  t.references :author, type: :uuid, foreign_key: true
  # Other columns...
  t.timestamps
end
```

In this example, the author_id column in the posts table references the
id column of the authors table. By explicitly setting the type to :uuid,
you ensure that the foreign key column matches the data type of the primary
key it references. Adjust the syntax accordingly for other associations and
databases.

Migration Changes

When generating migrations for your models, you'll notice that it specifies
the id to be of type uuid:

```bash
bin/rails g migration CreateAuthors
```

```ruby
class CreateAuthors < ActiveRecord::Migration[8.1]
  def change
    create_table :authors, id: :uuid do |t|
      t.timestamps
    end
  end
end
```

which results in the following schema:

```ruby
create_table "authors", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
  t.datetime "created_at", precision: 6, null: false
  t.datetime "updated_at", precision: 6, null: false
end
```

In this migration, the id column is defined as a UUID primary key with a
default value generated by the gen_random_uuid() function.

UUIDs are guaranteed to be globally unique across different systems, making them
suitable for distributed architectures. They also simplify integration with
external systems or APIs by providing a unique identifier that doesn't rely on
centralized ID generation, and unlike auto-incrementing integers, UUIDs don't
expose information about the total number of records in a table, which can be
beneficial for security purposes.

However, UUIDs can also impact performance due to their size and are harder to
index. UUIDs will have worse performance for writes and reads compared with
integer primary keys and foreign keys.

Therefore, it's essential to evaluate the trade-offs and consider the
specific requirements of your application before deciding to use UUIDs as
primary keys.

### 10.2. Data Migrations

Data migrations involve transforming or moving data within your database. In
Rails, it is generally not advised to perform data migrations using migration
files. Here’s why:

- Separation of Concerns: Schema changes and data changes have different
lifecycles and purposes. Schema changes alter the structure of your database,
while data changes alter the content.

- Rollback Complexity: Data migrations can be hard to rollback safely and
predictably.

- Performance: Data migrations can take a long time to run and may lock your
tables, affecting application performance and availability.

Instead, consider using the
maintenance_tasks gem. This
gem provides a framework for creating and managing data migrations and other
maintenance tasks in a way that is safe and easy to manage without interfering
with schema migrations.

---

# Chapters


---

This guide teaches you how to validate Active Record objects before saving them
to the database using Active Record's validations feature.

After reading this guide, you will know:

- How to use the built-in Active Record validations and options.

- How to check the validity of objects.

- How to create conditional and strict validations.

- How to create your own custom validation methods.

- How to work with the validation error messages and displaying them in views.

## 1. Validations Overview

Here's an example of a very simple validation:

```ruby
class Person < ApplicationRecord
  validates :name, presence: true
end
```

```
irb> Person.new(name: "John Doe").valid?
=> true
irb> Person.new(name: nil).valid?
=> false
```

As you can see, the Person is not valid without a name attribute.

Before we dig into more details, let's talk about how validations fit into the
big picture of your application.

### 1.1. Why Use Validations?

Validations are used to ensure that only valid data is saved into your database.
For example, it may be important to your application to ensure that every user
provides a valid email address and mailing address. Model-level validations are
the best way to ensure that only valid data is saved into your database. They
can be used with any database, cannot be bypassed by end users, and are
convenient to test and maintain. Rails provides built-in helpers for common
needs, and allows you to create your own validation methods as well.

### 1.2. Alternate Ways to Validate

There are several other ways to validate data before it is saved into your
database, including native database constraints, client-side validations and
controller-level validations. Here's a summary of the pros and cons:

- Database constraints and/or stored procedures make the validation mechanisms
database-dependent and can make testing and maintenance more difficult.
However, if your database is used by other applications, it may be a good idea
to use some constraints at the database level. Additionally, database-level
validations can safely handle some things (such as uniqueness in heavily-used
tables) that can be difficult to implement otherwise.

- Client-side validations can be useful, but are generally unreliable if used
alone. If they are implemented using JavaScript, they may be bypassed if
JavaScript is turned off in the user's browser. However, if combined with
other techniques, client-side validation can be a convenient way to provide
users with immediate feedback as they use your site.

- Controller-level validations can be tempting to use, but often become unwieldy
and difficult to test and maintain. Whenever possible, it's a good idea to
keep your controllers simple, as it will make working with your application
easier in the long run.

Rails recommends using model-level validations in most circumstances, however
there may be specific cases where you want to complement them with alternate
validations.

### 1.3. Validation Triggers

There are two kinds of Active Record objects - those that correspond to a row
inside your database and those that do not. When you instantiate a new object,
using the new method, the object does not get saved in the database as yet.
Once you call save on that object, it will be saved into the appropriate
database table. Active Record uses an instance method called persisted? (and
its inverse new_record?) to determine whether an object is already in the
database or not. Consider the following Active Record class:

```ruby
class Person < ApplicationRecord
end
```

We can see how it works by looking at some bin/rails console output:

```
irb> p = Person.new(name: "Jane Doe")
=> #<Person id: nil, name: "Jane Doe", created_at: nil, updated_at: nil>

irb> p.new_record?
=> true

irb> p.persisted?
=> false

irb> p.save
=> true

irb> p.new_record?
=> false

irb> p.persisted?
=> true
```

Saving a new record will send an SQL INSERT operation to the database, whereas
updating an existing record will send an SQL UPDATE operation. Validations are
typically run before these commands are sent to the database. If any validations
fail, the object will be marked as invalid and Active Record will not perform
the INSERT or UPDATE operation. This helps to avoid storing an invalid
object in the database. You can choose to have specific validations run when an
object is created, saved, or updated.

While validations usually prevent invalid data from being saved to the
database, it's important to be aware that not all methods in Rails trigger
validations. Some methods allow changes to be made directly to the database
without performing validations. As a result, if you're not careful, it’s
possible to bypass validations and save an object in an
invalid state.

The following methods trigger validations, and will save the object to the
database only if the object is valid:

- create

- create!

- save

- save!

- update

- update!

The bang versions (methods that end with an exclamation mark, like save!)
raise an exception if the record is invalid. The non-bang versions - save and
update returns false, and create returns the object.

### 1.4. Skipping Validations

The following methods skip validations, and will save the object to the database
regardless of its validity. They should be used with caution. Refer to the
method documentation to learn more.

- decrement!

- decrement_counter

- increment!

- increment_counter

- insert

- insert!

- insert_all

- insert_all!

- toggle!

- touch

- touch_all

- update_all

- update_attribute

- update_attribute!

- update_column

- update_columns

- update_counters

- upsert

- upsert_all

- save(validate: false)

save also has the ability to skip validations if validate: false is
passed as an argument. This technique should be used with caution.

### 1.5. Checking Validity

Before saving an Active Record object, Rails runs your validations, and if these
validations produce any validation errors, then Rails will not save the object.

You can also run the validations on your own. valid? triggers your
validations and returns true if no errors are found in the object, and false
otherwise. As you saw above:

```ruby
class Person < ApplicationRecord
  validates :name, presence: true
end
```

```
irb> Person.new(name: "John Doe").valid?
=> true
irb> Person.new(name: nil).valid?
=> false
```

After Active Record has performed validations, any failures can be accessed
through the errors instance method, which returns a collection of errors.
By definition, an object is valid if the collection is empty after running
validations.

An object instantiated with new will not report errors even if it's
technically invalid, because validations are automatically run only when the
object is saved, such as with the create or save methods.

```ruby
class Person < ApplicationRecord
  validates :name, presence: true
end
```

```
irb> person = Person.new
=> #<Person id: nil, name: nil, created_at: nil, updated_at: nil>
irb> person.errors.size
=> 0

irb> person.valid?
=> false
irb> person.errors.objects.first.full_message
=> "Name can't be blank"

irb> person.save
=> false

irb> person.save!
ActiveRecord::RecordInvalid: Validation failed: Name can't be blank

irb> Person.create!
ActiveRecord::RecordInvalid: Validation failed: Name can't be blank
```

invalid? is the inverse of valid?. It triggers your validations,
returning true if any errors were found in the object, and false otherwise.

### 1.6. Inspecting and Handling Errors

To verify whether or not a particular attribute of an object is valid, you can
use errors[:attribute]. It returns an array of all
the error messages for :attribute. If there are no errors on the specified
attribute, an empty array is returned. This allows you to easily determine
whether there are any validation issues with a specific attribute.

Here’s an example illustrating how to check for errors on an attribute:

```ruby
class Person < ApplicationRecord
  validates :name, presence: true
end
```

```
irb> new_person = Person.new
irb> new_person.errors[:name]
=> [] # no errors since validations are not run until saved
irb> new_person.errors[:name].any?
=> false

irb> create_person = Person.create
irb> create_person.errors[:name]
=> ["can't be blank"] # validation error because `name` is required
irb> create_person.errors[:name].any?
=> true
```

Additionally, you can use the
errors.add
method to manually add error messages for specific attributes. This is
particularly useful when defining custom validation scenarios.

```ruby
class Person < ApplicationRecord
  validate do |person|
    errors.add :name, :too_short, message: "is not long enough"
  end
end
```

To read about validation errors in greater depth refer to the Working
with Validation Errors section.

## 2. Validations

Active Record offers many predefined validations that you can use directly
inside your class definitions. These predefined validations provide common
validation rules. Each time a validation fails, an error message is added to the
object's errors collection, and this error is associated with the specific
attribute being validated.

When a validation fails, the error message is stored in the errors collection
under the attribute name that triggered the validation. This means you can
easily access the errors related to any specific attribute. For instance, if you
validate the :name attribute and the validation fails, you will find the error
message under errors[:name].

In modern Rails applications, the more concise validate syntax is commonly used,
for example:

```ruby
validates :name, presence: true
```

However, older versions of Rails used "helper" methods, such as:

```ruby
validates_presence_of :name
```

Both notations perform the same function, but the newer form is recommended for
its readability and alignment with Rails' conventions.

Each validation accepts an arbitrary number of attribute names, allowing you to
apply the same type of validation to multiple attributes in a single line of
code.

Additionally, all validations accept the :on and :message options. The :on
option specifies when the validation should be triggered, with possible values
being :create or :update. The :message option allows you to define a
custom error message that will be added to the errors collection if the
validation fails. If you do not specify a message, Rails will use a default
error message for that validation.

To see a list of the available default helpers, take a look at
ActiveModel::Validations::HelperMethods. This API section uses the older
notation as described above.

Below we outline the most commonly used validations.

### 2.1. absence

This validator validates that the specified attributes are absent. It uses the
Object#present? method to check if the value is neither nil nor a blank
string - that is, a string that is either empty or consists of whitespace only.

# absence is commonly used for conditional validations. For example:

```ruby
class Person < ApplicationRecord
  validates :phone_number, :address, absence: true, if: :invited?
end
```

```
irb> person = Person.new(name: "Jane Doe", invitation_sent_at: Time.current)
irb> person.valid?
=> true # absence validation passes
```

If you want to be sure that an association is absent, you'll need to test
whether the associated object itself is absent, and not the foreign key used to
map the association.

```ruby
class LineItem < ApplicationRecord
  belongs_to :order, optional: true
  validates :order, absence: true
end
```

```
irb> line_item = LineItem.new
irb> line_item.valid?
=> true # absence validation passes

order = Order.create
irb> line_item_with_order = LineItem.new(order: order)
irb> line_item_with_order.valid?
=> false # absence validation fails
```

For belongs_to the association presence is validated by default. If you
don’t want to have association presence validated, use optional: true.

Rails will usually infer the inverse association automatically. In cases where
you use a custom :foreign_key or a :through association, it's important to
explicitly set the :inverse_of option to optimize the association lookup. This
helps avoid unnecessary database queries during validation.

For more details, check out the Bi-directional Associations
documentation.

If you want to ensure that the association is both present and valid, you
also need to use validates_associated. More on that in the
validates_associated section.

If you validate the absence of an object associated via a
has_one or
has_many relationship, it
will check that the object is neither present? nor marked_for_destruction?.

Since false.present? is false, if you want to validate the absence of a
boolean field you should use:

```ruby
validates :field_name, exclusion: { in: [true, false] }
```

The default error message is "must be blank".

### 2.2. acceptance

This method validates that a checkbox on the user interface was checked when a
form was submitted. This is typically used when the user needs to agree to your
application's terms of service, confirm that some text is read, or any similar
concept.

```ruby
class Person < ApplicationRecord
  validates :terms_of_service, acceptance: true
end
```

This check is performed only if terms_of_service is not nil. The default
error message for this validation is "must be accepted". You can also pass in
a custom message via the message option.

```ruby
class Person < ApplicationRecord
  validates :terms_of_service, acceptance: { message: "must be agreed to" }
end
```

It can also receive an :accept option, which determines the allowed values
that will be considered as acceptable. It defaults to ['1', true] and can be
easily changed.

```ruby
class Person < ApplicationRecord
  validates :terms_of_service, acceptance: { accept: "yes" }
  validates :eula, acceptance: { accept: ["TRUE", "accepted"] }
end
```

This validation is very specific to web applications and this 'acceptance' does
not need to be recorded anywhere in your database. If you don't have a field for
it, the validator will create a virtual attribute. If the field does exist in
your database, the accept option must be set to or include true or else the
validation will not run.

### 2.3. confirmation

You should use this validator when you have two text fields that should receive
exactly the same content. For example, you may want to confirm an email address
or a password. This validation creates a virtual attribute whose name is the
name of the field that has to be confirmed with "_confirmation" appended.

```ruby
class Person < ApplicationRecord
  validates :email, confirmation: true
end
```

In your view template you could use something like

```ruby
<%= text_field :person, :email %>
<%= text_field :person, :email_confirmation %>
```

This check is performed only if email_confirmation is not nil. To
require confirmation, make sure to add a presence check for the confirmation
attribute (we'll take a look at the presence check later on in
this guide):

```ruby
class Person < ApplicationRecord
  validates :email, confirmation: true
  validates :email_confirmation, presence: true
end
```

There is also a :case_sensitive option that you can use to define whether the
confirmation constraint will be case sensitive or not. This option defaults to
true.

```ruby
class Person < ApplicationRecord
  validates :email, confirmation: { case_sensitive: false }
end
```

The default error message for this validator is "doesn't match confirmation".
You can also pass in a custom message via the message option.

Generally when using this validator, you will want to combine it with the :if
option to only validate the "_confirmation" field when the initial field has
changed and not every time you save the record. More on conditional
validations later.

```ruby
class Person < ApplicationRecord
  validates :email, confirmation: true
  validates :email_confirmation, presence: true, if: :email_changed?
end
```

### 2.4. comparison

This validator will validate a comparison between any two comparable values.

```ruby
class Promotion < ApplicationRecord
  validates :end_date, comparison: { greater_than: :start_date }
end
```

The default error message for this validator is "failed comparison". You can
also pass in a custom message via the message option.

These options are all supported:

The validator requires a compare option be supplied. Each option accepts a
value, proc, or symbol. Any class that includes
Comparable can be compared.

### 2.5. format

This validator validates the attributes' values by testing whether they match a
given regular expression, which is specified using the :with option.

```ruby
class Product < ApplicationRecord
  validates :legacy_code, format: { with: /\A[a-zA-Z]+\z/,
    message: "only allows letters" }
end
```

Inversely, by using the :without option instead you can require that the
specified attribute does not match the regular expression.

In either case, the provided :with or :without option must be a regular
expression or a proc or lambda that returns one.

The default error message is "is invalid".

Use \A and \z to match the start and end of the string, ^ and $
match the start/end of a line. Due to frequent misuse of ^ and $, you need
to pass the multiline: true option in case you use any of these two anchors in
the provided regular expression. In most cases, you should be using \A and
\z.

### 2.6. inclusion and exclusion

Both of these validators validate whether an attribute’s value is included or
excluded from a given set. The set can be any enumerable object such as an
array, range, or a dynamically generated collection using a proc, lambda, or
symbol.

- inclusion ensures that the value is present in the set.

- exclusion ensures that the value is not present in the set.

In both cases, the option :in receives the set of values, and :within can be
used as an alias. For full options on customizing error messages, see the
message documentation.

If the enumerable is a numerical, time, or datetime range, the test is performed
using Range#cover?, otherwise, it uses include?. When using a proc or
lambda, the instance under validation is passed as an argument, allowing for
dynamic validation.

#### 2.6.1. Examples

For inclusion:

```ruby
class Coffee < ApplicationRecord
  validates :size, inclusion: { in: %w(small medium large),
    message: "%{value} is not a valid size" }
end
```

For exclusion:

```ruby
class Account < ApplicationRecord
  validates :subdomain, exclusion: { in: %w(www us ca jp),
    message: "%{value} is reserved." }
end
```

Both validators allow the use of dynamic validation through methods that return
an enumerable. Here’s an example using a proc for inclusion:

```ruby
class Coffee < ApplicationRecord
  validates :size, inclusion: { in: ->(coffee) { coffee.available_sizes } }

  def available_sizes
    %w(small medium large extra_large)
  end
end
```

Similarly, for exclusion:

```ruby
class Account < ApplicationRecord
  validates :subdomain, exclusion: { in: ->(account) { account.reserved_subdomains } }

  def reserved_subdomains
    %w(www us ca jp admin)
  end
end
```

### 2.7. length

This validator validates the length of the attributes' values. It provides a
variety of options, so you can specify length constraints in different ways:

```ruby
class Person < ApplicationRecord
  validates :name, length: { minimum: 2 }
  validates :bio, length: { maximum: 500 }
  validates :password, length: { in: 6..20 }
  validates :registration_number, length: { is: 6 }
end
```

The possible length constraint options are:

The default error messages depend on the type of length validation being
performed. You can customize these messages using the :wrong_length,
:too_long, and :too_short options and %{count} as a placeholder for the
number corresponding to the length constraint being used. You can still use the
:message option to specify an error message.

```ruby
class Person < ApplicationRecord
  validates :bio, length: { maximum: 1000,
    too_long: "%{count} characters is the maximum allowed" }
end
```

The default error messages are plural (e.g. "is too short (minimum is
%{count} characters)"). For this reason, when :minimum is 1 you should provide
a custom message or use presence: true instead. Similarly, when :in or
:within have a lower limit of 1, you should either provide a custom message or
call presence prior to length. Only one constraint option can be used at a
time apart from the :minimum and :maximum options which can be combined
together.

### 2.8. numericality

This validator validates that your attributes have only numeric values. By
default, it will match an optional sign followed by an integer or floating point
number.

To specify that only integer numbers are allowed, set :only_integer to true.
Then it will use the following regular expression to validate the attribute's
value.

```ruby
/\A[+-]?\d+\z/
```

Otherwise, it will try to convert the value to a number using Float. Floats
are converted to BigDecimal using the column's precision value or a maximum of
15 digits.

```ruby
class Player < ApplicationRecord
  validates :points, numericality: true
  validates :games_played, numericality: { only_integer: true }
end
```

The default error message for :only_integer is "must be an integer".

Besides :only_integer, this validator also accepts the :only_numeric option
which specifies the value must be an instance of Numeric and attempts to parse
the value if it is a String.

By default, numericality doesn't allow nil values. You can use
allow_nil: true option to permit it. For Integer and Float columns empty
strings are converted to nil.

The default error message when no options are specified is "is not a number".

There are also many options that can be used to add constraints to acceptable
values:

### 2.9. presence

This validator validates that the specified attributes are not empty. It uses
the Object#blank? method to check if the value is either nil or a blank
string - that is, a string that is either empty or consists of whitespace.

```ruby
class Person < ApplicationRecord
  validates :name, :login, :email, presence: true
end
```

```
person = Person.new(name: "Alice", login: "alice123", email: "alice@example.com")
person.valid?
=> true # presence validation passes

invalid_person = Person.new(name: "", login: nil, email: "bob@example.com")
invalid_person.valid?
=> false # presence validation fails
```

To check that an association is present, you'll need to test that the associated
object is present, and not the foreign key used to map the association. Testing
the association will help you to determine that the foreign key is not empty and
also that the referenced object exists.

```ruby
class Supplier < ApplicationRecord
  has_one :account
  validates :account, presence: true
end
```

```
irb> account = Account.create(name: "Account A")

irb> supplier = Supplier.new(account: account)
irb> supplier.valid?
=> true # presence validation passes

irb> invalid_supplier = Supplier.new
irb> invalid_supplier.valid?
=> false # presence validation fails
```

In cases where you use a custom :foreign_key or a :through association, it's
important to explicitly set the :inverse_of option to optimize the association
lookup. This helps avoid unnecessary database queries during validation.

For more details, check out the Bi-directional Associations
documentation.

If you want to ensure that the association is both present and valid, you
also need to use validates_associated. More on that
below.

If you validate the presence of an object associated via a
has_one or
has_many relationship, it
will check that the object is neither blank? nor marked_for_destruction?.

Since false.blank? is true, if you want to validate the presence of a boolean
field you should use one of the following validations:

```ruby
# Value _must_ be true or false
validates :boolean_field_name, inclusion: [true, false]
# Value _must not_ be nil, aka true or false
validates :boolean_field_name, exclusion: [nil]
```

By using one of these validations, you will ensure the value will NOT be nil
which would result in a NULL value in most cases.

The default error message is "can't be blank".

### 2.10. uniqueness

This validator validates that the attribute's value is unique right before the
object gets saved.

```ruby
class Account < ApplicationRecord
  validates :email, uniqueness: true
end
```

The validation happens by performing an SQL query into the model's table,
searching for an existing record with the same value in that attribute.

There is a :scope option that you can use to specify one or more attributes
that are used to limit the uniqueness check:

```ruby
class Holiday < ApplicationRecord
  validates :name, uniqueness: { scope: :year,
    message: "should happen once per year" }
end
```

This validation does not create a uniqueness constraint in the
database, so a scenario can occur whereby two different database connections
create two records with the same value for a column that you intended to be
unique. To avoid this, you must create a unique index on that column in your
database.

In order to add a uniqueness database constraint on your database, use the
add_index statement in a migration and include the unique: true option.

If you are using the :scope option in your uniqueness validation, and you wish
to create a database constraint to prevent possible violations of the uniqueness
validation, you must create a unique index on both columns in your database. See
the MySQL manual and the MariaDB manual for more details about multiple
column indexes, or the PostgreSQL manual for examples of unique constraints
that refer to a group of columns.

There is also a :case_sensitive option that you can use to define whether the
uniqueness constraint will be case sensitive, case insensitive, or if it should
respect the default database collation. This option defaults to respecting the
default database collation.

```ruby
class Person < ApplicationRecord
  validates :name, uniqueness: { case_sensitive: false }
end
```

Some databases are configured to perform case-insensitive searches
anyway.

A :conditions option can be used to specify additional conditions as a WHERE
SQL fragment to limit the uniqueness constraint lookup:

```ruby
validates :name, uniqueness: { conditions: -> { where(status: "active") } }
```

The default error message is "has already been taken".

See validates_uniqueness_of for more information.

### 2.11. validates_associated

You should use this validator when your model has associations that always need
to be validated. Every time you try to save your object, valid? will be called
on each one of the associated objects.

```ruby
class Library < ApplicationRecord
  has_many :books
  validates_associated :books
end
```

This validation will work with all of the association types.

Don't use validates_associated on both ends of your associations.
They would call each other in an infinite loop.

The default error message for validates_associated is "is invalid". Note
that each associated object will contain its own errors collection; errors do
not bubble up to the calling model.

validates_associated can only be used with ActiveRecord objects,
everything up until now can also be used on any object which includes
ActiveModel::Validations.

### 2.12. validates_each

This validator validates attributes against a block. It doesn't have a
predefined validation function. You should create one using a block, and every
attribute passed to validates_each will be tested against it.

In the following example, we will reject names and surnames that begin with
lowercase.

```ruby
class Person < ApplicationRecord
  validates_each :name, :surname do |record, attr, value|
    record.errors.add(attr, "must start with upper case") if /\A[[:lower:]]/.match?(value)
  end
end
```

The block receives the record, the attribute's name, and the attribute's value.

You can do anything you like to check for valid data within the block. If your
validation fails, you should add an error to the model, therefore making it
invalid.

### 2.13. validates_with

This validator passes the record to a separate class for validation.

```ruby
class AddressValidator < ActiveModel::Validator
  def validate(record)
    if record.house_number.blank?
      record.errors.add :house_number, "is required"
    end

    if record.street.blank?
      record.errors.add :street, "is required"
    end

    if record.postcode.blank?
      record.errors.add :postcode, "is required"
    end
  end
end

class Invoice < ApplicationRecord
  validates_with AddressValidator
end
```

There is no default error message for validates_with. You must manually add
errors to the record's errors collection in the validator class.

Errors added to record.errors[:base] relate to the state of the record
as a whole.

To implement the validate method, you must accept a record parameter in the
method definition, which is the record to be validated.

If you want to add an error on a specific attribute, you can pass it as the
first argument to the add method.

```ruby
def validate(record)
  if record.some_field != "acceptable"
    record.errors.add :some_field, "this field is unacceptable"
  end
end
```

We will cover validation errors in greater
detail later.

The validates_with validator takes a class, or a list of classes to use
for validation.

```ruby
class Person < ApplicationRecord
  validates_with MyValidator, MyOtherValidator, on: :create
end
```

Like all other validations, validates_with takes the :if, :unless and
:on options. If you pass any other options, it will send those options to the
validator class as options:

```ruby
class AddressValidator < ActiveModel::Validator
  def validate(record)
    options[:fields].each do |field|
      if record.send(field).blank?
        record.errors.add field, "is required"
      end
    end
  end
end

class Invoice < ApplicationRecord
  validates_with AddressValidator, fields: [:house_number, :street, :postcode, :country]
end
```

The validator will be initialized only once for the whole application
life cycle, and not on each validation run, so be careful about using instance
variables inside it.

If your validator is complex enough that you want instance variables, you can
easily use a plain old Ruby object instead:

```ruby
class Invoice < ApplicationRecord
  validate do |invoice|
    AddressValidator.new(invoice).validate
  end
end

class AddressValidator
  def initialize(invoice)
    @invoice = invoice
  end

  def validate
    validate_field(:house_number)
    validate_field(:street)
    validate_field(:postcode)
  end

  private
    def validate_field(field)
      if @invoice.send(field).blank?
        @invoice.errors.add field, "#{field.to_s.humanize} is required"
      end
    end
end
```

We will cover custom validations more later.

## 3. Validation Options

There are several common options supported by the validators. These options are:

- :allow_nil: Skip validation if the attribute is nil.

- :allow_blank: Skip validation if the attribute is blank.

- :message: Specify a custom error message.

- :on: Specify the contexts where this validation is active.

- :strict: Raise an exception when the validation
fails.

- :if and :unless: Specify when the validation
should or should not occur.

Not all of these options are supported by every validator, please refer to
the API documentation for ActiveModel::Validations.

### 3.1. :allow_nil

The :allow_nil option skips the validation when the value being validated is
nil.

```ruby
class Coffee < ApplicationRecord
  validates :size, inclusion: { in: %w(small medium large),
    message: "%{value} is not a valid size" }, allow_nil: true
end
```

```
irb> Coffee.create(size: nil).valid?
=> true
irb> Coffee.create(size: "mega").valid?
=> false
```

For full options to the message argument please see the message
documentation.

### 3.2. :allow_blank

The :allow_blank option is similar to the :allow_nil option. This option
will let validation pass if the attribute's value is blank?, like nil or an
empty string for example.

```ruby
class Topic < ApplicationRecord
  validates :title, length: { is: 6 }, allow_blank: true
end
```

```
irb> Topic.create(title: "").valid?
=> true
irb> Topic.create(title: nil).valid?
=> true
irb> Topic.create(title: "short").valid?
=> false # 'short' is not of length 6, so validation fails even though it's not blank
```

### 3.3. :message

As you've already seen, the :message option lets you specify the message that
will be added to the errors collection when validation fails. When this option
is not used, Active Record will use the respective default error message for
each validation.

The :message option accepts either a String or Proc as its value.

A String :message value can optionally contain any/all of %{value},
%{attribute}, and %{model} which will be dynamically replaced when
validation fails. This replacement is done using the i18n
gem, and the placeholders must match
exactly, no spaces are allowed.

```ruby
class Person < ApplicationRecord
  # Hard-coded message
  validates :name, presence: { message: "must be given please" }

  # Message with dynamic attribute value. %{value} will be replaced
  # with the actual value of the attribute. %{attribute} and %{model}
  # are also available.
  validates :age, numericality: { message: "%{value} seems wrong" }
end
```

A Proc :message value is given two arguments: the object being validated,
and a hash with :model, :attribute, and :value key-value pairs.

```ruby
class Person < ApplicationRecord
  validates :username,
    uniqueness: {
      # object = person object being validated
      # data = { model: "Person", attribute: "Username", value: <username> }
      message: ->(object, data) do
        "Hey #{object.name}, #{data[:value]} is already taken."
      end
    }
end
```

To translate error messages, see the I18n
guide.

### 3.4. :on

The :on option lets you specify when the validation should happen. The default
behavior for all the built-in validations is to be run on save (both when you're
creating a new record and when you're updating it). If you want to change it,
you can use on: :create to run the validation only when a new record is
created or on: :update to run the validation only when a record is updated.

```ruby
class Person < ApplicationRecord
  # it will be possible to update email with a duplicated value
  validates :email, uniqueness: true, on: :create

  # it will be possible to create the record with a non-numerical age
  validates :age, numericality: true, on: :update

  # the default (validates on both create and update)
  validates :name, presence: true
end
```

You can also use :on to define custom contexts. Custom contexts need to be
triggered explicitly by passing the name of the context to valid?, invalid?,
or save.

```ruby
class Person < ApplicationRecord
  validates :email, uniqueness: true, on: :account_setup
  validates :age, numericality: true, on: :account_setup
end
```

```
irb> person = Person.new(age: 'thirty-three')
irb> person.valid?
=> true
irb> person.valid?(:account_setup)
=> false
irb> person.errors.messages
=> {:email=>["has already been taken"], :age=>["is not a number"]}
```

person.valid?(:account_setup) executes both the validations without saving the
model. person.save(context: :account_setup) validates person in the
account_setup context before saving.

Passing an array of symbols is also acceptable.

```ruby
class Book
  include ActiveModel::Validations

  validates :title, presence: true, on: [:update, :ensure_title]
end
```

```
irb> book = Book.new(title: nil)
irb> book.valid?
=> true
irb> book.valid?(:ensure_title)
=> false
irb> book.errors.messages
=> {:title=>["can't be blank"]}
```

When triggered by an explicit context, validations are run for that context, as
well as any validations without a context.

```ruby
class Person < ApplicationRecord
  validates :email, uniqueness: true, on: :account_setup
  validates :age, numericality: true, on: :account_setup
  validates :name, presence: true
end
```

```
irb> person = Person.new
irb> person.valid?(:account_setup)
=> false
irb> person.errors.messages
=> {:email=>["has already been taken"], :age=>["is not a number"], :name=>["can't be blank"]}
```

You can read more about use-cases for :on in the Custom Contexts
section.

## 4. Conditional Validations

Sometimes it will make sense to validate an object only when a given condition
is met. You can do that by using the :if and :unless options, which can take
a symbol, a Proc or an Array. You may use the :if option when you want to
specify when the validation should happen. Alternatively, if you want to
specify when the validation should not happen, then you may use the
:unless option.

### 4.1. Using a Symbol with :if and :unless

You can associate the :if and :unless options with a symbol corresponding to
the name of a method that will get called right before validation happens. This
is the most commonly used option.

```ruby
class Order < ApplicationRecord
  validates :card_number, presence: true, if: :paid_with_card?

  def paid_with_card?
    payment_type == "card"
  end
end
```

### 4.2. Using a Proc with :if and :unless

It is possible to associate :if and :unless with a Proc object which will
be called. Using a Proc object gives you the ability to write an inline
condition instead of a separate method. This option is best suited for
one-liners.

```ruby
class Account < ApplicationRecord
  validates :password, confirmation: true,
    unless: Proc.new { |a| a.password.blank? }
end
```

As lambda is a type of Proc, it can also be used to write inline conditions
taking advantage of the shortened syntax.

```ruby
validates :password, confirmation: true, unless: -> { password.blank? }
```

### 4.3. Grouping Conditional Validations

Sometimes it is useful to have multiple validations use one condition. It can be
easily achieved using with_options.

```ruby
class User < ApplicationRecord
  with_options if: :is_admin? do |admin|
    admin.validates :password, length: { minimum: 10 }
    admin.validates :email, presence: true
  end
end
```

All validations inside of the with_options block will automatically have if:
:is_admin? merged into its options.

### 4.4. Combining Validation Conditions

On the other hand, when multiple conditions define whether or not a validation
should happen, an Array can be used. Moreover, you can apply both :if and
:unless to the same validation.

```ruby
class Computer < ApplicationRecord
  validates :mouse, presence: true,
                    if: [Proc.new { |c| c.market.retail? }, :desktop?],
                    unless: Proc.new { |c| c.trackpad.present? }
end
```

The validation only runs when all the :if conditions and none of the :unless
conditions are evaluated to true.

## 5. Strict Validations

You can also specify validations to be strict and raise
ActiveModel::StrictValidationFailed when the object is invalid.

```ruby
class Person < ApplicationRecord
  validates :name, presence: { strict: true }
end
```

```
irb> Person.new.valid?
=> ActiveModel::StrictValidationFailed: Name can't be blank
```

Strict validations ensure that an exception is raised immediately when
validation fails, which can be useful in situations where you want to enforce
immediate feedback or halt processing when invalid data is encountered. For
example, you might use strict validations in a scenario where invalid input
should prevent further operations, such as when processing critical transactions
or performing data integrity checks.

There is also the ability to pass a custom exception to the :strict option.

```ruby
class Person < ApplicationRecord
  validates :token, presence: true, uniqueness: true, strict: TokenGenerationException
end
```

```
irb> Person.new.valid?
=> TokenGenerationException: Token can't be blank
```

## 6. Listing Validators

If you want to find out all of the validators for a given object, you can use
validators.

For example, if we have the following model using a custom validator and a
built-in validator:

```ruby
class Person < ApplicationRecord
  validates :name, presence: true, on: :create
  validates :email, format: URI::MailTo::EMAIL_REGEXP
  validates_with MyOtherValidator, strict: true
end
```

We can now use validators on the "Person" model to list all validators, or
even check a specific field using validators_on.

```
irb> Person.validators
#=> [#<ActiveRecord::Validations::PresenceValidator:0x10b2f2158
      @attributes=[:name], @options={:on=>:create}>,
     #<MyOtherValidatorValidator:0x10b2f17d0
      @attributes=[:name], @options={:strict=>true}>,
     #<ActiveModel::Validations::FormatValidator:0x10b2f0f10
      @attributes=[:email],
      @options={:with=>URI::MailTo::EMAIL_REGEXP}>]
     #<MyOtherValidator:0x10b2f0948 @options={:strict=>true}>]

irb> Person.validators_on(:name)
#=> [#<ActiveModel::Validations::PresenceValidator:0x10b2f2158
      @attributes=[:name], @options={on: :create}>]
```

## 7. Performing Custom Validations

When the built-in validations are not enough for your needs, you can write your
own validators or validation methods as you prefer.

### 7.1. Custom Validators

Custom validators are classes that inherit from ActiveModel::Validator.
These classes must implement the validate method which takes a record as an
argument and performs the validation on it. The custom validator is called using
the validates_with method.

```ruby
class MyValidator < ActiveModel::Validator
  def validate(record)
    unless record.name.start_with? "X"
      record.errors.add :name, "Provide a name starting with X, please!"
    end
  end
end

class Person < ApplicationRecord
  validates_with MyValidator
end
```

The easiest way to add custom validators for validating individual attributes is
with the convenient ActiveModel::EachValidator. In this case, the custom
validator class must implement a validate_each method which takes three
arguments: record, attribute, and value. These correspond to the instance, the
attribute to be validated, and the value of the attribute in the passed
instance.

```ruby
class EmailValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    unless URI::MailTo::EMAIL_REGEXP.match?(value)
      record.errors.add attribute, (options[:message] || "is not an email")
    end
  end
end

class Person < ApplicationRecord
  validates :email, presence: true, email: true
end
```

As shown in the example, you can also combine standard validations with your own
custom validators.

### 7.2. Custom Methods

You can also create methods that verify the state of your models and add errors
to the errors collection when they are invalid. You must then register these
methods by using the validate class method, passing in the symbols for the
validation methods' names.

You can pass more than one symbol for each class method and the respective
validations will be run in the same order as they were registered.

The valid? method will verify that the errors collection is empty, so your
custom validation methods should add errors to it when you wish validation to
fail:

```ruby
class Invoice < ApplicationRecord
  validate :expiration_date_cannot_be_in_the_past,
    :discount_cannot_be_greater_than_total_value

  def expiration_date_cannot_be_in_the_past
    if expiration_date.present? && expiration_date < Date.today
      errors.add(:expiration_date, "can't be in the past")
    end
  end

  def discount_cannot_be_greater_than_total_value
    if discount > total_value
      errors.add(:discount, "can't be greater than total value")
    end
  end
end
```

By default, such validations will run every time you call valid? or save the
object. But it is also possible to control when to run these custom validations
by giving an :on option to the validate method, with either: :create or
:update.

```ruby
class Invoice < ApplicationRecord
  validate :active_customer, on: :create

  def active_customer
    errors.add(:customer_id, "is not active") unless customer.active?
  end
end
```

See the section above for more details about :on.

### 7.3. Custom Contexts

You can define your own custom validation contexts for callbacks, which is
useful when you want to perform validations based on specific scenarios or group
certain callbacks together and run them in a specific context. A common scenario
for custom contexts is when you have a multi-step form and want to perform
validations per step.

For instance, you might define custom contexts for each step of the form:

```ruby
class User < ApplicationRecord
  validate :personal_information, on: :personal_info
  validate :contact_information, on: :contact_info
  validate :location_information, on: :location_info

  private
    def personal_information
      errors.add(:base, "Name must be present") if first_name.blank?
      errors.add(:base, "Age must be at least 18") if age && age < 18
    end

    def contact_information
      errors.add(:base, "Email must be present") if email.blank?
      errors.add(:base, "Phone number must be present") if phone.blank?
    end

    def location_information
      errors.add(:base, "Address must be present") if address.blank?
      errors.add(:base, "City must be present") if city.blank?
    end
end
```

In these cases, you may be tempted to skip
callbacks altogether, but
defining a custom context can be a more structured approach. You will need to
combine a context with the :on option to define a custom context for a
callback.

Once you've defined the custom context, you can use it to trigger the
validations:

```
irb> user = User.new(name: "John Doe", age: 17, email: "jane@example.com", phone: "1234567890", address: "123 Main St")
irb> user.valid?(:personal_info) # => false
irb> user.valid?(:contact_info) # => true
irb> user.valid?(:location_info) # => false
```

You can also use the custom contexts to trigger the validations on any method
that supports callbacks. For example, you could use the custom context to
trigger the validations on save:

```
irb> user = User.new(name: "John Doe", age: 17, email: "jane@example.com", phone: "1234567890", address: "123 Main St")
irb> user.save(context: :personal_info) # => false
irb> user.save(context: :contact_info) # => true
irb> user.save(context: :location_info) # => false
```

## 8. Working with Validation Errors

The valid? and invalid? methods only provide a summary status on
validity. However you can dig deeper into each individual error by using various
methods from the errors collection.

The following is a list of the most commonly used methods. Please refer to the
ActiveModel::Errors documentation for a list of all the available methods.

### 8.1. errors

The errors method is the starting point through which you can drill down
into various details of each error.

This returns an instance of the class ActiveModel::Errors containing all
errors, each error is represented by an ActiveModel::Error object.

```ruby
class Person < ApplicationRecord
  validates :name, presence: true, length: { minimum: 3 }
end
```

```
irb> person = Person.new
irb> person.valid?
=> false
irb> person.errors.full_messages
=> ["Name can't be blank", "Name is too short (minimum is 3 characters)"]

irb> person = Person.new(name: "John Doe")
irb> person.valid?
=> true
irb> person.errors.full_messages
=> []

irb> person = Person.new
irb> person.valid?
=> false
irb> person.errors.first.details
=> {:error=>:too_short, :count=>3}
```

### 8.2. errors[]

errors[] is used when you want to check the error
messages for a specific attribute. It returns an array of strings with all error
messages for the given attribute, each string with one error message. If there
are no errors related to the attribute, it returns an empty array.

This method is only useful after validations have been run, because it only
inspects the errors collection and does not trigger validations itself. It's
different from the ActiveRecord::Base#invalid? method explained above because
it doesn't verify the validity of the object as a whole. errors[] only checks
to see whether there are errors found on an individual attribute of the object.

```ruby
class Person < ApplicationRecord
  validates :name, presence: true, length: { minimum: 3 }
end
```

```
irb> person = Person.new(name: "John Doe")
irb> person.valid?
=> true
irb> person.errors[:name]
=> []

irb> person = Person.new(name: "JD")
irb> person.valid?
=> false
irb> person.errors[:name]
=> ["is too short (minimum is 3 characters)"]

irb> person = Person.new
irb> person.valid?
=> false
irb> person.errors[:name]
=> ["can't be blank", "is too short (minimum is 3 characters)"]
```

### 8.3. errors.where and Error Object

Sometimes we may need more information about each error besides its message.
Each error is encapsulated as an ActiveModel::Error object, and the
where method is the most common way of access.

where returns an array of error objects filtered by various degrees of
conditions.

Given the following validation:

```ruby
class Person < ApplicationRecord
  validates :name, presence: true, length: { minimum: 3 }
end
```

We can filter for just the attribute by passing it as the first parameter to
errors.where(:attr). The second parameter is used for filtering the type of
error we want by calling errors.where(:attr, :type).

```
irb> person = Person.new
irb> person.valid?
=> false

irb> person.errors.where(:name)
=> [ ... ] # all errors for :name attribute

irb> person.errors.where(:name, :too_short)
=> [ ... ] # :too_short errors for :name attribute
```

Lastly, we can filter by any options that may exist on the given type of error
object.

```
irb> person = Person.new
irb> person.valid?
=> false

irb> person.errors.where(:name, :too_short, minimum: 3)
=> [ ... ] # all name errors being too short and minimum is 3
```

You can read various information from these error objects:

```
irb> error = person.errors.where(:name).last

irb> error.attribute
=> :name
irb> error.type
=> :too_short
irb> error.options[:count]
=> 3
```

You can also generate the error message:

```
irb> error.message
=> "is too short (minimum is 3 characters)"
irb> error.full_message
=> "Name is too short (minimum is 3 characters)"
```

The full_message method generates a more user-friendly message, with the
capitalized attribute name prepended. (To customize the format that
full_message uses, see the I18n guide.)

### 8.4. errors.add

The add method creates the error object by taking the attribute, the
error type and additional options hash. This is useful when writing your own
validator, as it lets you define very specific error situations.

```ruby
class Person < ApplicationRecord
  validate do |person|
    errors.add :name, :too_plain, message: "is not cool enough"
  end
end
```

```
irb> person = Person.new
irb> person.errors.where(:name).first.type
=> :too_plain
irb> person.errors.where(:name).first.full_message
=> "Name is not cool enough"
```

### 8.5. errors[:base]

You can add errors that are related to the object's state as a whole, instead of
being related to a specific attribute. To do this you must use :base as the
attribute when adding a new error.

```ruby
class Person < ApplicationRecord
  validate do |person|
    errors.add :base, :invalid, message: "This person is invalid because ..."
  end
end
```

```
irb> person = Person.new
irb> person.errors.where(:base).first.full_message
=> "This person is invalid because ..."
```

### 8.6. errors.size

The size method returns the total number of errors for the object.

```ruby
class Person < ApplicationRecord
  validates :name, presence: true, length: { minimum: 3 }
end
```

```
irb> person = Person.new
irb> person.valid?
=> false
irb> person.errors.size
=> 2

irb> person = Person.new(name: "Andrea", email: "andrea@example.com")
irb> person.valid?
=> true
irb> person.errors.size
=> 0
```

### 8.7. errors.clear

The clear method is used when you intentionally want to clear the errors
collection. Of course, calling errors.clear upon an invalid object won't
actually make it valid: the errors collection will now be empty, but the next
time you call valid? or any method that tries to save this object to the
database, the validations will run again. If any of the validations fail, the
errors collection will be filled again.

```ruby
class Person < ApplicationRecord
  validates :name, presence: true, length: { minimum: 3 }
end
```

```
irb> person = Person.new
irb> person.valid?
=> false
irb> person.errors.empty?
=> false

irb> person.errors.clear
irb> person.errors.empty?
=> true

irb> person.save
=> false

irb> person.errors.empty?
=> false
```

## 9. Displaying Validation Errors in Views

Once you've defined a model and added validations, you'll want to display an
error message when a validation fails during the creation of that model via a
web form.

Since every application handles displaying validation errors differently, Rails
does not include any view helpers for generating these messages. However, Rails
gives you a rich number of methods to interact with validations that you can use
to build your own. In addition, when generating a scaffold, Rails will put some
generated ERB into the _form.html.erb that displays the full list of errors on
that model.

Assuming we have a model that's been saved in an instance variable named
@article, it looks like this:

```ruby
<% if @article.errors.any? %>
  <div id="error_explanation">
    <h2><%= pluralize(@article.errors.count, "error") %> prohibited this article from being saved:</h2>

    <ul>
      <% @article.errors.each do |error| %>
        <li><%= error.full_message %></li>
      <% end %>
    </ul>
  </div>
<% end %>
```

Furthermore, if you use the Rails form helpers to generate your forms, when a
validation error occurs on a field, it will generate an extra <div> around the
entry.

```html
<div class="field_with_errors">
  <input id="article_title" name="article[title]" size="30" type="text" value="">
</div>
```

You can then style this div however you'd like. The default scaffold that Rails
generates, for example, adds this CSS rule:

```
.field_with_errors {
  padding: 2px;
  background-color: red;
  display: table;
}
```

This means that any field with an error ends up with a 2 pixel red border.

### 9.1. Customizing Error Field Wrapper

Rails uses the field_error_proc configuration option to wrap fields with
errors in HTML. By default, this option wraps the erroneous form fields in a
<div> with a field_with_errors class, as seen in the example above:

```ruby
config.action_view.field_error_proc = Proc.new { |html_tag, instance| content_tag :div, html_tag, class: "field_with_errors" }
```

You can customize this behavior by modifying the field_error_proc setting in
your application configuration, allowing you to change how errors are presented
in your forms. For more details,refer to the Configuration Guide on
field_error_proc.

---

# Chapters


---

This guide teaches you how to hook into the life cycle of your Active Record
objects.

After reading this guide, you will know:

- When certain events occur during the life of an Active Record object.

- How to register, run, and skip callbacks that respond to these events.

- How to create relational, association, conditional, and transactional
callbacks.

- How to create objects that encapsulate common behavior for your callbacks to
be reused.

## 1. The Object Life Cycle

During the normal operation of a Rails application, objects may be created,
updated, and
destroyed. Active
Record provides hooks into this object life cycle so that you can control your
application and its data.

Callbacks allow you to trigger logic before or after a change to an object's
state. They are methods that get called at certain moments of an object's life
cycle. With callbacks it is possible to write code that will run whenever an
Active Record object is initialized, created, saved, updated, deleted,
validated, or loaded from the database.

```ruby
class BirthdayCake < ApplicationRecord
  after_create -> { Rails.logger.info("Congratulations, the callback has run!") }
end
```

```
irb> BirthdayCake.create
Congratulations, the callback has run!
```

As you will see, there are many life cycle events and multiple options to hook
into these — either before, after, or even around them.

## 2. Callback Registration

To use the available callbacks, you need to implement and register them.
Implementation can be done in a multitude of ways like using ordinary methods,
blocks and procs, or defining custom callback objects using classes or modules.
Let's go through each of these implementation techniques.

You can register the callbacks with a macro-style class method that calls an
ordinary method for implementation.

```ruby
class User < ApplicationRecord
  validates :username, :email, presence: true

  before_validation :ensure_username_has_value

  private
    def ensure_username_has_value
      if username.blank?
        self.username = email
      end
    end
end
```

The macro-style class methods can also receive a block. Consider using this
style if the code inside your block is so short that it fits in a single line:

```ruby
class User < ApplicationRecord
  validates :username, :email, presence: true

  before_validation do
    self.username = email if username.blank?
  end
end
```

Alternatively, you can pass a proc to the callback to be triggered.

```ruby
class User < ApplicationRecord
  validates :username, :email, presence: true

  before_validation ->(user) { user.username = user.email if user.username.blank? }
end
```

Lastly, you can define a custom callback object, as
shown below. We will cover these later in more detail.

```ruby
class User < ApplicationRecord
  validates :username, :email, presence: true

  before_validation AddUsername
end

class AddUsername
  def self.before_validation(record)
    if record.username.blank?
      record.username = record.email
    end
  end
end
```

### 2.1. Registering Callbacks to Fire on Life Cycle Events

Callbacks can also be registered to only fire on certain life cycle events, this
can be done using the :on option and allows complete control over when and in
what context your callbacks are triggered.

A context is like a category or a scenario in which you want certain
validations to apply. When you validate an ActiveRecord model, you can specify a
context to group validations. This allows you to have different sets of
validations that apply in different situations. In Rails, there are certain
default contexts for validations like :create, :update, and :save.

```ruby
class User < ApplicationRecord
  validates :username, :email, presence: true

  before_validation :ensure_username_has_value, on: :create

  # :on takes an array as well
  after_validation :set_location, on: [ :create, :update ]

  private
    def ensure_username_has_value
      if username.blank?
        self.username = email
      end
    end

    def set_location
      self.location = LocationService.query(self)
    end
end
```

It is considered good practice to declare callback methods as private. If
left public, they can be called from outside of the model and violate the
principle of object encapsulation.

Refrain from using methods like update, save, or any other methods
that cause side effects on the object within your callback methods.
For instance, avoid calling update(attribute: "value") inside a callback. This
practice can modify the model's state and potentially lead to unforeseen side
effects during commit.  Instead, you can assign values directly (e.g.,
self.attribute = "value") in before_create, before_update, or earlier
callbacks for a safer approach.

## 3. Available Callbacks

Here is a list with all the available Active Record callbacks, listed in the
order in which they will get called during the respective operations:

### 3.1. Creating an Object

- before_validation

- after_validation

- before_save

- around_save

- before_create

- around_create

- after_create

- after_save

- after_commit / after_rollback

See the after_commit / after_rollback
section for
examples using these two callbacks.

There are examples below that show how to use these callbacks. We've grouped
them by the operation they are associated with, and lastly show how they can be
used in combination.

#### 3.1.1. Validation Callbacks

Validation callbacks are triggered whenever the record is validated directly via
the
valid?
( or its alias
validate)
or
invalid?
method, or indirectly via create, update, or save. They are called before
and after the validation phase.

```ruby
class User < ApplicationRecord
  validates :name, presence: true
  before_validation :titleize_name
  after_validation :log_errors

  private
    def titleize_name
      self.name = name.downcase.titleize if name.present?
      Rails.logger.info("Name titleized to #{name}")
    end

    def log_errors
      if errors.any?
        Rails.logger.error("Validation failed: #{errors.full_messages.join(', ')}")
      end
    end
end
```

```
irb> user = User.new(name: "", email: "john.doe@example.com", password: "abc123456")
=> #<User id: nil, email: "john.doe@example.com", created_at: nil, updated_at: nil, name: "">

irb> user.valid?
Name titleized to
Validation failed: Name can't be blank
=> false
```

#### 3.1.2. Save Callbacks

Save callbacks are triggered whenever the record is persisted (i.e. "saved") to
the underlying database, via the create, update, or save methods. They are
called before, after, and around the object is saved.

```ruby
class User < ApplicationRecord
  before_save :hash_password
  around_save :log_saving
  after_save :update_cache

  private
    def hash_password
      self.password_digest = BCrypt::Password.create(password)
      Rails.logger.info("Password hashed for user with email: #{email}")
    end

    def log_saving
      Rails.logger.info("Saving user with email: #{email}")
      yield
      Rails.logger.info("User saved with email: #{email}")
    end

    def update_cache
      Rails.cache.write(["user_data", self], attributes)
      Rails.logger.info("Update Cache")
    end
end
```

```
irb> user = User.create(name: "Jane Doe", password: "password", email: "jane.doe@example.com")

Password hashed for user with email: jane.doe@example.com
Saving user with email: jane.doe@example.com
User saved with email: jane.doe@example.com
Update Cache
=> #<User id: 1, email: "jane.doe@example.com", created_at: "2024-03-20 16:02:43.685500000 +0000", updated_at: "2024-03-20 16:02:43.685500000 +0000", name: "Jane Doe">
```

#### 3.1.3. Create Callbacks

Create callbacks are triggered whenever the record is persisted (i.e. "saved")
to the underlying database for the first time — in other words, when we're
saving a new record, via the create or save methods. They are called before,
after and around the object is created.

```ruby
class User < ApplicationRecord
  before_create :set_default_role
  around_create :log_creation
  after_create :send_welcome_email

  private
    def set_default_role
      self.role = "user"
      Rails.logger.info("User role set to default: user")
    end

    def log_creation
      Rails.logger.info("Creating user with email: #{email}")
      yield
      Rails.logger.info("User created with email: #{email}")
    end

    def send_welcome_email
      UserMailer.welcome_email(self).deliver_later
      Rails.logger.info("User welcome email sent to: #{email}")
    end
end
```

```
irb> user = User.create(name: "John Doe", email: "john.doe@example.com")

User role set to default: user
Creating user with email: john.doe@example.com
User created with email: john.doe@example.com
User welcome email sent to: john.doe@example.com
=> #<User id: 10, email: "john.doe@example.com", created_at: "2024-03-20 16:19:52.405195000 +0000", updated_at: "2024-03-20 16:19:52.405195000 +0000", name: "John Doe">
```

### 3.2. Updating an Object

Update callbacks are triggered whenever an existing record is persisted
(i.e. "saved") to the underlying database. They are called before, after and
around the object is updated.

- before_validation

- after_validation

- before_save

- around_save

- before_update

- around_update

- after_update

- after_save

- after_commit / after_rollback

The after_save callback is triggered on both create and update
operations. However, it consistently executes after the more specific callbacks
after_create and after_update, regardless of the sequence in which the macro
calls were made. Similarly, before and around save callbacks follow the same
rule: before_save runs before create/update, and around_save runs around
create/update operations. It's important to note that save callbacks will always
run before/around/after the more specific create/update callbacks.

We've already covered validation and
save callbacks. See the after_commit /
after_rollback section for examples using
these two callbacks.

#### 3.2.1. Update Callbacks

```ruby
class User < ApplicationRecord
  before_update :check_role_change
  around_update :log_updating
  after_update :send_update_email

  private
    def check_role_change
      if role_changed?
        Rails.logger.info("User role changed to #{role}")
      end
    end

    def log_updating
      Rails.logger.info("Updating user with email: #{email}")
      yield
      Rails.logger.info("User updated with email: #{email}")
    end

    def send_update_email
      UserMailer.update_email(self).deliver_later
      Rails.logger.info("Update email sent to: #{email}")
    end
end
```

```
irb> user = User.find(1)
=> #<User id: 1, email: "john.doe@example.com", created_at: "2024-03-20 16:19:52.405195000 +0000", updated_at: "2024-03-20 16:19:52.405195000 +0000", name: "John Doe", role: "user" >

irb> user.update(role: "admin")
User role changed to admin
Updating user with email: john.doe@example.com
User updated with email: john.doe@example.com
Update email sent to: john.doe@example.com
```

#### 3.2.2. Using a Combination of Callbacks

Often, you will need to use a combination of callbacks to achieve the desired
behavior. For example, you may want to send a confirmation email after a user is
created, but only if the user is new and not being updated. When a user is
updated, you may want to notify an admin if critical information is changed. In
this case, you can use after_create and after_update callbacks together.

```ruby
class User < ApplicationRecord
  after_create :send_confirmation_email
  after_update :notify_admin_if_critical_info_updated

  private
    def send_confirmation_email
      UserMailer.confirmation_email(self).deliver_later
      Rails.logger.info("Confirmation email sent to: #{email}")
    end

    def notify_admin_if_critical_info_updated
      if saved_change_to_email? || saved_change_to_phone_number?
        AdminMailer.user_critical_info_updated(self).deliver_later
        Rails.logger.info("Notification sent to admin about critical info update for: #{email}")
      end
    end
end
```

```
irb> user = User.create(name: "John Doe", email: "john.doe@example.com")
Confirmation email sent to: john.doe@example.com
=> #<User id: 1, email: "john.doe@example.com", ...>

irb> user.update(email: "john.doe.new@example.com")
Notification sent to admin about critical info update for: john.doe.new@example.com
=> true
```

### 3.3. Destroying an Object

Destroy callbacks are triggered whenever a record is destroyed, but ignored when
a record is deleted. They are called before, after and around the object is
destroyed.

- before_destroy

- around_destroy

- after_destroy

- after_commit / after_rollback

Find examples for using after_commit /
after_rollback.

#### 3.3.1. Destroy Callbacks

```ruby
class User < ApplicationRecord
  before_destroy :check_admin_count
  around_destroy :log_destroy_operation
  after_destroy :notify_users

  private
    def check_admin_count
      if admin? && User.where(role: "admin").count == 1
        throw :abort
      end
      Rails.logger.info("Checked the admin count")
    end

    def log_destroy_operation
      Rails.logger.info("About to destroy user with ID #{id}")
      yield
      Rails.logger.info("User with ID #{id} destroyed successfully")
    end

    def notify_users
      UserMailer.deletion_email(self).deliver_later
      Rails.logger.info("Notification sent to other users about user deletion")
    end
end
```

```
irb> user = User.find(1)
=> #<User id: 1, email: "john.doe@example.com", created_at: "2024-03-20 16:19:52.405195000 +0000", updated_at: "2024-03-20 16:19:52.405195000 +0000", name: "John Doe", role: "admin">

irb> user.destroy
Checked the admin count
About to destroy user with ID 1
User with ID 1 destroyed successfully
Notification sent to other users about user deletion
```

### 3.4. after_initialize and after_find

Whenever an Active Record object is instantiated, either by directly using new
or when a record is loaded from the database, the after_initialize
callback will be called. It can be useful to avoid the need to directly override
your Active Record initialize method.

When loading a record from the database the after_find callback will be
called. after_find is called before after_initialize if both are defined.

The after_initialize and after_find callbacks have no before_*
counterparts.

They can be registered just like the other Active Record callbacks.

```ruby
class User < ApplicationRecord
  after_initialize do |user|
    Rails.logger.info("You have initialized an object!")
  end

  after_find do |user|
    Rails.logger.info("You have found an object!")
  end
end
```

```
irb> User.new
You have initialized an object!
=> #<User id: nil>

irb> User.first
You have found an object!
You have initialized an object!
=> #<User id: 1>
```

### 3.5. after_touch

The after_touch callback will be called whenever an Active Record object
is touched. You can read more about touch in the API
docs.

```ruby
class User < ApplicationRecord
  after_touch do |user|
    Rails.logger.info("You have touched an object")
  end
end
```

```
irb> user = User.create(name: "Kuldeep")
=> #<User id: 1, name: "Kuldeep", created_at: "2013-11-25 12:17:49", updated_at: "2013-11-25 12:17:49">

irb> user.touch
You have touched an object
=> true
```

It can be used along with belongs_to:

```ruby
class Book < ApplicationRecord
  belongs_to :library, touch: true
  after_touch do
    Rails.logger.info("A Book was touched")
  end
end

class Library < ApplicationRecord
  has_many :books
  after_touch :log_when_books_or_library_touched

  private
    def log_when_books_or_library_touched
      Rails.logger.info("Book/Library was touched")
    end
end
```

```
irb> book = Book.last
=> #<Book id: 1, library_id: 1, created_at: "2013-11-25 17:04:22", updated_at: "2013-11-25 17:05:05">

irb> book.touch # triggers book.library.touch
A Book was touched
Book/Library was touched
=> true
```

## 4. Running Callbacks

The following methods trigger callbacks:

- create

- create!

- destroy

- destroy!

- destroy_all

- destroy_by

- save

- save!

- save(validate: false)

- save!(validate: false)

- toggle!

- touch

- update_attribute

- update_attribute!

- update

- update!

- valid?

- validate

Additionally, the after_find callback is triggered by the following finder
methods:

- all

- first

- find

- find_by

- find_by!

- find_by_*

- find_by_*!

- find_by_sql

- last

- sole

- take

The after_initialize callback is triggered every time a new object of the
class is initialized.

The find_by_*and find_by_*! methods are dynamic finders generated
automatically for every attribute. Learn more about them in the Dynamic finders
section.

## 5. Conditional Callbacks

As with validations, we can also make the
calling of a callback method conditional on the satisfaction of a given
predicate. We can do this using the :if and :unless options, which can take
a symbol, a Proc or an Array.

You may use the :if option when you want to specify under which conditions the
callback should be called. If you want to specify the conditions under which
the callback should not be called, then you may use the :unless option.

### 5.1. Using :if and :unless with a Symbol

You can associate the :if and :unless options with a symbol corresponding to
the name of a predicate method that will get called right before the callback.

When using the :if option, the callback won't be executed if the predicate
method returns false; when using the :unless option, the callback
won't be executed if the predicate method returns true. This is the most
common option.

```ruby
class Order < ApplicationRecord
  before_save :normalize_card_number, if: :paid_with_card?
end
```

Using this form of registration it is also possible to register several
different predicates that should be called to check if the callback should be
executed. We will cover this in the Multiple Callback Conditions
section.

### 5.2. Using :if and :unless with a Proc

It is possible to associate :if and :unless with a Proc object. This
option is best suited when writing short validation methods, usually one-liners:

```ruby
class Order < ApplicationRecord
  before_save :normalize_card_number,
    if: ->(order) { order.paid_with_card? }
end
```

Since the proc is evaluated in the context of the object, it is also possible to
write this as:

```ruby
class Order < ApplicationRecord
  before_save :normalize_card_number, if: -> { paid_with_card? }
end
```

### 5.3. Multiple Callback Conditions

The :if and :unless options also accept an array of procs or method names as
symbols:

```ruby
class Comment < ApplicationRecord
  before_save :filter_content,
    if: [:subject_to_parental_control?, :untrusted_author?]
end
```

You can easily include a proc in the list of conditions:

```ruby
class Comment < ApplicationRecord
  before_save :filter_content,
    if: [:subject_to_parental_control?, -> { untrusted_author? }]
end
```

### 5.4. Using Both :if and :unless

Callbacks can mix both :if and :unless in the same declaration:

```ruby
class Comment < ApplicationRecord
  before_save :filter_content,
    if: -> { forum.parental_control? },
    unless: -> { author.trusted? }
end
```

The callback only runs when all the :if conditions and none of the :unless
conditions are evaluated to true.

## 6. Skipping Callbacks

Just as with validations, it is also possible
to skip callbacks by using the following methods:

- decrement!

- decrement_counter

- delete

- delete_all

- delete_by

- increment!

- increment_counter

- insert

- insert!

- insert_all

- insert_all!

- touch_all

- update_column

- update_columns

- update_all

- update_counters

- upsert

- upsert_all

Let's consider a User model where the before_save callback logs any changes
to the user's email address:

```ruby
class User < ApplicationRecord
  before_save :log_email_change

  private
    def log_email_change
      if email_changed?
        Rails.logger.info("Email changed from #{email_was} to #{email}")
      end
    end
end
```

Now, suppose there's a scenario where you want to update the user's email
address without triggering the before_save callback to log the email change.
You can use the update_columns method for this purpose:

```
irb> user = User.find(1)
irb> user.update_columns(email: 'new_email@example.com')
```

The above will update the user's email address without triggering the
before_save callback.

These methods should be used with caution because there may be
important business rules and application logic in callbacks that you do not want
to bypass. Bypassing them without understanding the potential implications may
lead to invalid data.

## 7. Suppressing Saving

In certain scenarios, you may need to temporarily prevent records from being
saved within your callbacks.
This can be useful if you have a record with complex nested associations and want
to skip saving specific records during certain operations without permanently disabling
the callbacks or introducing complex conditional logic.

Rails provides a mechanism to prevent saving records using the
ActiveRecord::Suppressor module.
By using this module, you can wrap a block of code where you want to avoid
saving records of a specific type that otherwise would be saved by the code block.

Let's consider a scenario where a user has many notifications.
Creating a User will automatically create a Notification record as well.

```ruby
class User < ApplicationRecord
  has_many :notifications

  after_create :create_welcome_notification

  def create_welcome_notification
    notifications.create(event: "sign_up")
  end
end

class Notification < ApplicationRecord
  belongs_to :user
end
```

To create a user without creating a notification, we can use the
ActiveRecord::Suppressor module as follows:

```ruby
Notification.suppress do
  User.create(name: "Jane", email: "jane@example.com")
end
```

In the above code, the Notification.suppress block ensures that the
Notification is not saved during the creation of the "Jane" user.

Using the Active Record Suppressor can introduce complexity and
unexpected behavior. Suppressing saving can obscure the intended flow of your
application, leading to difficulties in understanding and maintaining the
codebase over time. Carefully consider the implications of using the suppressor,
ensuring thorough documentation and thoughtful testing to mitigate
risks of unintended side effects and test failures.

## 8. Halting Execution

As you start registering new callbacks for your models, they will be queued for
execution. This queue will include all of your model's validations, the
registered callbacks, and the database operation to be executed.

The whole callback chain is wrapped in a transaction. If any callback raises an
exception, the execution chain gets halted and a rollback is issued, and the
error will be re-raised.

```ruby
class Product < ActiveRecord::Base
  before_validation do
    raise "Price can't be negative" if total_price < 0
  end
end

Product.create # raises "Price can't be negative"
```

This unexpectedly breaks code that does not expect methods like create and
save to raise exceptions.

If an exception occurs during the callback chain, Rails will re-raise it
unless it is an ActiveRecord::Rollback or ActiveRecord::RecordInvalid
exception. Instead, you should use throw :abort to intentionally halt the
chain. If any callback throws :abort, the process will be aborted and create
will return false.

```ruby
class Product < ActiveRecord::Base
  before_validation do
    throw :abort if total_price < 0
  end
end

Product.create # => false
```

However, it will raise an ActiveRecord::RecordNotSaved when calling create!.
This exception indicates that the record was not saved due to the callback's
interruption.

```ruby
User.create! # => raises an ActiveRecord::RecordNotSaved
```

When throw :abort is called in any destroy callback, destroy will return
false:

```ruby
class User < ActiveRecord::Base
  before_destroy do
    throw :abort if still_active?
  end
end

User.first.destroy # => false
```

However, it will raise an ActiveRecord::RecordNotDestroyed when calling
destroy!.

```ruby
User.first.destroy! # => raises an ActiveRecord::RecordNotDestroyed
```

## 9. Association Callbacks

Association callbacks are similar to normal callbacks, but they are triggered by
events in the life cycle of the associated collection. There are four available
association callbacks:

- before_add

- after_add

- before_remove

- after_remove

You can define association callbacks by adding options to the association.

Suppose you have an example where an author can have many books. However, before
adding a book to the authors collection, you want to ensure that the author has
not reached their book limit. You can do this by adding a before_add callback
to check the limit.

```ruby
class Author < ApplicationRecord
  has_many :books, before_add: :check_limit

  private
    def check_limit(_book)
      if books.count >= 5
        errors.add(:base, "Cannot add more than 5 books for this author")
        throw(:abort)
      end
    end
end
```

If a before_add callback throws :abort, the object does not get added to the
collection.

At times you may want to perform multiple actions on the associated object. In
this case, you can stack callbacks on a single event by passing them as an
array. Additionally, Rails passes the object being added or removed to the
callback for you to use.

```ruby
class Author < ApplicationRecord
  has_many :books, before_add: [:check_limit, :calculate_shipping_charges]

  def check_limit(_book)
    if books.count >= 5
      errors.add(:base, "Cannot add more than 5 books for this author")
      throw(:abort)
    end
  end

  def calculate_shipping_charges(book)
    weight_in_pounds = book.weight_in_pounds || 1
    shipping_charges = weight_in_pounds * 2

    shipping_charges
  end
end
```

Similarly, if a before_remove callback throws :abort, the object does not
get removed from the collection.

These callbacks are called only when the associated objects are added or
removed through the association collection.

```ruby
# Triggers `before_add` callback
author.books << book
author.books = [book, book2]

# Does not trigger the `before_add` callback
book.update(author_id: 1)
```

## 10. Cascading Association Callbacks

Callbacks can be performed when associated objects are changed. They work
through the model associations whereby life cycle events can cascade on
associations and fire callbacks.

Suppose an example where a user has many articles. A user's articles should be
destroyed if the user is destroyed. Let's add an after_destroy callback to the
User model by way of its association to the Article model:

```ruby
class User < ApplicationRecord
  has_many :articles, dependent: :destroy
end

class Article < ApplicationRecord
  after_destroy :log_destroy_action

  def log_destroy_action
    Rails.logger.info("Article destroyed")
  end
end
```

```
irb> user = User.first
=> #<User id: 1>
irb> user.articles.create!
=> #<Article id: 1, user_id: 1>
irb> user.destroy
Article destroyed
=> #<User id: 1>
```

When using a before_destroy callback, it should be placed before
dependent: :destroy associations (or use the prepend: true option), to
ensure they execute before the records are deleted by dependent: :destroy.

## 11. Transaction Callbacks

### 11.1. after_commit and after_rollback

Two additional callbacks are triggered by the completion of a database
transaction: after_commit and after_rollback. These callbacks are
very similar to the after_save callback except that they don't execute until
after database changes have either been committed or rolled back. They are most
useful when your Active Record models need to interact with external systems
that are not part of the database transaction.

Consider a PictureFile model that needs to delete a file after the
corresponding record is destroyed.

```ruby
class PictureFile < ApplicationRecord
  after_destroy :delete_picture_file_from_disk

  def delete_picture_file_from_disk
    if File.exist?(filepath)
      File.delete(filepath)
    end
  end
end
```

If anything raises an exception after the after_destroy callback is called and
the transaction rolls back, then the file will have been deleted and the model
will be left in an inconsistent state. For example, suppose that
picture_file_2 in the code below is not valid and the save! method raises an
error.

```ruby
PictureFile.transaction do
  picture_file_1.destroy
  picture_file_2.save!
end
```

By using the after_commit callback we can account for this case.

```ruby
class PictureFile < ApplicationRecord
  after_commit :delete_picture_file_from_disk, on: :destroy

  def delete_picture_file_from_disk
    if File.exist?(filepath)
      File.delete(filepath)
    end
  end
end
```

The :on option specifies when a callback will be fired. If you don't
supply the :on option the callback will fire for every life cycle event. Read
more about :on.

When a transaction completes, the after_commit or after_rollback callbacks
are called for all models created, updated, or destroyed within that
transaction. However, if an exception is raised within one of these callbacks,
the exception will bubble up and any remaining after_commit or
after_rollback methods will not be executed.

```ruby
class User < ActiveRecord::Base
  after_commit { raise "Intentional Error" }
  after_commit {
    # This won't get called because the previous after_commit raises an exception
    Rails.logger.info("This will not be logged")
  }
end
```

If your callback code raises an exception, you'll need to rescue it and
handle it within the callback in order to allow other callbacks to run.

after_commit makes very different guarantees than after_save,
after_update, and after_destroy. For example, if an exception occurs in an
after_save the transaction will be rolled back and the data will not be
persisted.

```ruby
class User < ActiveRecord::Base
  after_save do
    # If this fails the user won't be saved.
    EventLog.create!(event: "user_saved")
  end
end
```

However, during after_commit the data was already persisted to the database,
and thus any exception won't roll anything back anymore.

```ruby
class User < ActiveRecord::Base
  after_commit do
    # If this fails the user was already saved.
    EventLog.create!(event: "user_saved")
  end
end
```

The code executed within after_commit or after_rollback callbacks is itself
not enclosed within a transaction.

In the context of a single transaction, if you represent the same record in the
database, there's a crucial behavior in the after_commit and after_rollback
callbacks to note. These callbacks are triggered only for the first object of
the specific record that changes within the transaction. Other loaded objects,
despite representing the same database record, will not have their respective
after_commit or after_rollback callbacks triggered.

```ruby
class User < ApplicationRecord
  after_commit :log_user_saved_to_db, on: :update

  private
    def log_user_saved_to_db
      Rails.logger.info("User was saved to database")
    end
end
```

```
irb> user = User.create
irb> User.transaction { user.save; user.save }
# User was saved to database
```

This nuanced behavior is particularly impactful in scenarios where you
expect independent callback execution for each object associated with the same
database record. It can influence the flow and predictability of callback
sequences, leading to potential inconsistencies in application logic following
the transaction.

### 11.2. Aliases for after_commit

Using the after_commit callback only on create, update, or delete is common.
Sometimes you may also want to use a single callback for both create and
update. Here are some common aliases for these operations:

- after_destroy_commit

- after_create_commit

- after_update_commit

- after_save_commit

Let's go through some examples:

Instead of using after_commit with the on option for a destroy like below:

```ruby
class PictureFile < ApplicationRecord
  after_commit :delete_picture_file_from_disk, on: :destroy

  def delete_picture_file_from_disk
    if File.exist?(filepath)
      File.delete(filepath)
    end
  end
end
```

You can instead use the after_destroy_commit.

```ruby
class PictureFile < ApplicationRecord
  after_destroy_commit :delete_picture_file_from_disk

  def delete_picture_file_from_disk
    if File.exist?(filepath)
      File.delete(filepath)
    end
  end
end
```

The same applies for after_create_commit and after_update_commit.

However, if you use the after_create_commit and the after_update_commit
callback with the same method name, it will only allow the last callback defined
to take effect, as they both internally alias to after_commit which overrides
previously defined callbacks with the same method name.

```ruby
class User < ApplicationRecord
  after_create_commit :log_user_saved_to_db
  after_update_commit :log_user_saved_to_db

  private
    def log_user_saved_to_db
      # This only gets called once
      Rails.logger.info("User was saved to database")
    end
end
```

```
irb> user = User.create # prints nothing

irb> user.save # updating @user
User was saved to database
```

In this case, it's better to use after_save_commit instead which is an alias
for using the after_commit callback for both create and update:

```ruby
class User < ApplicationRecord
  after_save_commit :log_user_saved_to_db

  private
    def log_user_saved_to_db
      Rails.logger.info("User was saved to database")
    end
end
```

```
irb> user = User.create # creating a User
User was saved to database

irb> user.save # updating user
User was saved to database
```

### 11.3. Transactional Callback Ordering

By default (from Rails 7.1), transaction callbacks will run in the order they
are defined.

```ruby
class User < ActiveRecord::Base
  after_commit { Rails.logger.info("this gets called first") }
  after_commit { Rails.logger.info("this gets called second") }
end
```

However, in prior versions of Rails, when defining multiple transactional
after_callbacks (after_commit, after_rollback, etc), the order in which
the callbacks were run was reversed.

If for some reason you'd still like them to run in reverse, you can set the
following configuration to false. The callbacks will then run in the reverse
order. See the Active Record configuration
options
for more details.

```ruby
config.active_record.run_after_transaction_callbacks_in_order_defined = false
```

This applies to all after_*_commit variations too, such as
after_destroy_commit.

### 11.4. Per transaction callback

You can also register transactional callbacks such as before_commit, after_commit and after_rollback on a specific transaction.
This is handy in situations where you need to perform an action that isn't specific to a model but rather a unit of work.

ActiveRecord::Base.transaction yields an ActiveRecord::Transaction object, which allows registering the said callbacks on it.

```ruby
Article.transaction do |transaction|
  article.update(published: true)

  transaction.after_commit do
    PublishNotificationMailer.with(article: article).deliver_later
  end
end
```

### 11.5. ActiveRecord.after_all_transactions_commit

ActiveRecord.after_all_transactions_commit is a callback that allows you to run code after all the current transactions have been successfully committed to the database.

```ruby
def publish_article(article)
  Article.transaction do
    Post.transaction do
      ActiveRecord.after_all_transactions_commit do
        PublishNotificationMailer.with(article: article).deliver_later
        # An email will be sent after the outermost transaction is committed.
      end
    end
  end
end
```

A callback registered to after_all_transactions_commit will be triggered after the outermost transaction is committed. If any of the currently open transactions is rolled back, the block is never called.
In the event that there are no open transactions at the time a callback is registered, the block will be yielded immediately.

## 12. Callback Objects

Sometimes the callback methods that you'll write will be useful enough to be
reused by other models. Active Record makes it possible to create classes that
encapsulate the callback methods, so they can be reused.

Here's an example of an after_commit callback  class to deal with the cleanup
of discarded files on the filesystem. This behavior may not be unique to our
PictureFile model and we may want to share it, so it's a good idea to
encapsulate this into a separate class. This will make testing that behavior and
changing it much easier.

```ruby
class FileDestroyerCallback
  def after_commit(file)
    if File.exist?(file.filepath)
      File.delete(file.filepath)
    end
  end
end
```

When declared inside a class, as above, the callback methods will receive the
model object as a parameter. This will work on any model that uses the class
like so:

```ruby
class PictureFile < ApplicationRecord
  after_commit FileDestroyerCallback.new
end
```

Note that we needed to instantiate a new FileDestroyerCallback object, since
we declared our callback as an instance method. This is particularly useful if
the callbacks make use of the state of the instantiated object. Often, however,
it will make more sense to declare the callbacks as class methods:

```ruby
class FileDestroyerCallback
  def self.after_commit(file)
    if File.exist?(file.filepath)
      File.delete(file.filepath)
    end
  end
end
```

When the callback method is declared this way, it won't be necessary to
instantiate a new FileDestroyerCallback object in our model.

```ruby
class PictureFile < ApplicationRecord
  after_commit FileDestroyerCallback
end
```

You can declare as many callbacks as you want inside your callback objects.

---

# Chapters
