# Chapters

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

This guide covers different ways to retrieve data from the database using Active Record.

After reading this guide, you will know:

- How to find records using a variety of methods and conditions.

- How to specify the order, retrieved attributes, grouping, and other properties of the found records.

- How to use eager loading to reduce the number of database queries needed for data retrieval.

- How to use dynamic finder methods.

- How to use method chaining to use multiple Active Record methods together.

- How to check for the existence of particular records.

- How to perform various calculations on Active Record models.

- How to run EXPLAIN on relations.

## 1. What is the Active Record Query Interface?

If you're used to using raw SQL to find database records, then you will generally find that there are better ways to carry out the same operations in Rails. Active Record insulates you from the need to use SQL in most cases.

Active Record will perform queries on the database for you and is compatible with most database systems, including MySQL, MariaDB, PostgreSQL, and SQLite. Regardless of which database system you're using, the Active Record method format will always be the same.

Code examples throughout this guide will refer to one or more of the following models:

All of the following models use id as the primary key, unless specified otherwise.

```ruby
class Author < ApplicationRecord
  has_many :books, -> { order(year_published: :desc) }
end
```

```ruby
class Book < ApplicationRecord
  belongs_to :supplier
  belongs_to :author
  has_many :reviews
  has_and_belongs_to_many :orders, join_table: "books_orders"

  scope :in_print, -> { where(out_of_print: false) }
  scope :out_of_print, -> { where(out_of_print: true) }
  scope :old, -> { where(year_published: ...50.years.ago.year) }
  scope :out_of_print_and_expensive, -> { out_of_print.where("price > 500") }
  scope :costs_more_than, ->(amount) { where("price > ?", amount) }
end
```

```ruby
class Customer < ApplicationRecord
  has_many :orders
  has_many :reviews
end
```

```ruby
class Order < ApplicationRecord
  belongs_to :customer
  has_and_belongs_to_many :books, join_table: "books_orders"

  enum :status, [:shipped, :being_packed, :complete, :cancelled]

  scope :created_before, ->(time) { where(created_at: ...time) }
end
```

```ruby
class Review < ApplicationRecord
  belongs_to :customer
  belongs_to :book

  enum :state, [:not_reviewed, :published, :hidden]
end
```

```ruby
class Supplier < ApplicationRecord
  has_many :books
  has_many :authors, through: :books
end
```

## 2. Retrieving Objects from the Database

To retrieve objects from the database, Active Record provides several finder methods. Each finder method allows you to pass arguments into it to perform certain queries on your database without writing raw SQL.

The methods are:

- annotate

- find

- create_with

- distinct

- eager_load

- extending

- extract_associated

- from

- group

- having

- includes

- joins

- left_outer_joins

- limit

- lock

- none

- offset

- optimizer_hints

- order

- preload

- readonly

- references

- reorder

- reselect

- regroup

- reverse_order

- select

- where

Finder methods that return a collection, such as where and group, return an instance of ActiveRecord::Relation.  Methods that find a single entity, such as find and first, return a single instance of the model.

The primary operation of Model.find(options) can be summarized as:

- Convert the supplied options to an equivalent SQL query.

- Fire the SQL query and retrieve the corresponding results from the database.

- Instantiate the equivalent Ruby object of the appropriate model for every resulting row.

- Run after_find and then after_initialize callbacks, if any.

### 2.1. Retrieving a Single Object

Active Record provides several different ways of retrieving a single object.

#### 2.1.1. find

Using the find method, you can retrieve the object corresponding to the specified primary key that matches any supplied options. For example:

```
# Find the customer with primary key (id) 10.
irb> customer = Customer.find(10)
=> #<Customer id: 10, first_name: "Ryan">
```

The SQL equivalent of the above is:

```sql
SELECT * FROM customers WHERE (customers.id = 10) LIMIT 1
```

The find method will raise an ActiveRecord::RecordNotFound exception if no matching record is found.

You can also use this method to query for multiple objects. Call the find method and pass in an array of primary keys. The return will be an array containing all of the matching records for the supplied primary keys. For example:

```
# Find the customers with primary keys 1 and 10.
irb> customers = Customer.find([1, 10]) # OR Customer.find(1, 10)
=> [#<Customer id: 1, first_name: "Lifo">, #<Customer id: 10, first_name: "Ryan">]
```

The SQL equivalent of the above is:

```sql
SELECT * FROM customers WHERE (customers.id IN (1,10))
```

The find method will raise an ActiveRecord::RecordNotFound exception unless a matching record is found for all of the supplied primary keys.

If your table uses a composite primary key, you'll need to pass in an array to find a single item. For instance, if customers were defined with [:store_id, :id] as a primary key:

```
# Find the customer with store_id 3 and id 17
irb> customers = Customer.find([3, 17])
=> #<Customer store_id: 3, id: 17, first_name: "Magda">
```

The SQL equivalent of the above is:

```sql
SELECT * FROM customers WHERE store_id = 3 AND id = 17
```

To find multiple customers with composite IDs, you would pass an array of arrays:

```
# Find the customers with primary keys [1, 8] and [7, 15].
irb> customers = Customer.find([[1, 8], [7, 15]]) # OR Customer.find([1, 8], [7, 15])
=> [#<Customer store_id: 1, id: 8, first_name: "Pat">, #<Customer store_id: 7, id: 15, first_name: "Chris">]
```

The SQL equivalent of the above is:

```sql
SELECT * FROM customers WHERE (store_id = 1 AND id = 8 OR store_id = 7 AND id = 15)
```

#### 2.1.2. take

The take method retrieves a record without any implicit ordering. For example:

```
irb> customer = Customer.take
=> #<Customer id: 1, first_name: "Lifo">
```

The SQL equivalent of the above is:

```sql
SELECT * FROM customers LIMIT 1
```

The take method returns nil if no record is found and no exception will be raised.

You can pass in a numerical argument to the take method to return up to that number of results. For example:

```
irb> customers = Customer.take(2)
=> [#<Customer id: 1, first_name: "Lifo">, #<Customer id: 220, first_name: "Sara">]
```

The SQL equivalent of the above is:

```sql
SELECT * FROM customers LIMIT 2
```

The take! method behaves exactly like take, except that it will raise ActiveRecord::RecordNotFound if no matching record is found.

The retrieved record may vary depending on the database engine.

#### 2.1.3. first

The first method finds the first record ordered by primary key (default). For example:

```
irb> customer = Customer.first
=> #<Customer id: 1, first_name: "Lifo">
```

The SQL equivalent of the above is:

```sql
SELECT * FROM customers ORDER BY customers.id ASC LIMIT 1
```

The first method returns nil if no matching record is found and no exception will be raised.

If your default scope contains an order method, first will return the first record according to this ordering.

You can pass in a numerical argument to the first method to return up to that number of results. For example:

```
irb> customers = Customer.first(3)
=> [#<Customer id: 1, first_name: "Lifo">, #<Customer id: 2, first_name: "Fifo">, #<Customer id: 3, first_name: "Filo">]
```

The SQL equivalent of the above is:

```sql
SELECT * FROM customers ORDER BY customers.id ASC LIMIT 3
```

Models with composite primary keys will use the full composite primary key for ordering.
For instance, if customers were defined with [:store_id, :id] as a primary key:

```
irb> customer = Customer.first
=> #<Customer id: 2, store_id: 1, first_name: "Lifo">
```

The SQL equivalent of the above is:

```sql
SELECT * FROM customers ORDER BY customers.store_id ASC, customers.id ASC LIMIT 1
```

On a collection that is ordered using order, first will return the first record ordered by the specified attribute for order.

```
irb> customer = Customer.order(:first_name).first
=> #<Customer id: 2, first_name: "Fifo">
```

The SQL equivalent of the above is:

```sql
SELECT * FROM customers ORDER BY customers.first_name ASC LIMIT 1
```

The first! method behaves exactly like first, except that it will raise ActiveRecord::RecordNotFound if no matching record is found.

#### 2.1.4. last

The last method finds the last record ordered by primary key (default). For example:

```
irb> customer = Customer.last
=> #<Customer id: 221, first_name: "Russel">
```

The SQL equivalent of the above is:

```sql
SELECT * FROM customers ORDER BY customers.id DESC LIMIT 1
```

The last method returns nil if no matching record is found and no exception will be raised.

Models with composite primary keys will use the full composite primary key for ordering.
For instance, if customers were defined with [:store_id, :id] as a primary key:

```
irb> customer = Customer.last
=> #<Customer id: 221, store_id: 1, first_name: "Lifo">
```

The SQL equivalent of the above is:

```sql
SELECT * FROM customers ORDER BY customers.store_id DESC, customers.id DESC LIMIT 1
```

If your default scope contains an order method, last will return the last record according to this ordering.

You can pass in a numerical argument to the last method to return up to that number of results. For example:

```
irb> customers = Customer.last(3)
=> [#<Customer id: 219, first_name: "James">, #<Customer id: 220, first_name: "Sara">, #<Customer id: 221, first_name: "Russel">]
```

The SQL equivalent of the above is:

```sql
SELECT * FROM customers ORDER BY customers.id DESC LIMIT 3
```

On a collection that is ordered using order, last will return the last record ordered by the specified attribute for order.

```
irb> customer = Customer.order(:first_name).last
=> #<Customer id: 220, first_name: "Sara">
```

The SQL equivalent of the above is:

```sql
SELECT * FROM customers ORDER BY customers.first_name DESC LIMIT 1
```

The last! method behaves exactly like last, except that it will raise ActiveRecord::RecordNotFound if no matching record is found.

#### 2.1.5. find_by

The find_by method finds the first record matching some conditions. For example:

```
irb> Customer.find_by first_name: 'Lifo'
=> #<Customer id: 1, first_name: "Lifo">

irb> Customer.find_by first_name: 'Jon'
=> nil
```

It is equivalent to writing:

```ruby
Customer.where(first_name: "Lifo").take
```

The SQL equivalent of the above is:

```sql
SELECT * FROM customers WHERE (customers.first_name = 'Lifo') LIMIT 1
```

Note that there is no ORDER BY in the above SQL.  If your find_by conditions can match multiple records, you should apply an order to guarantee a deterministic result.

The find_by! method behaves exactly like find_by, except that it will raise ActiveRecord::RecordNotFound if no matching record is found. For example:

```
irb> Customer.find_by! first_name: 'does not exist'
ActiveRecord::RecordNotFound
```

This is equivalent to writing:

```ruby
Customer.where(first_name: "does not exist").take!
```

When specifying conditions on methods like find_by and where, the use of id will match against
an :id attribute on the model. This is different from find, where the ID passed in should be a primary key value.

Take caution when using find_by(id:) on models where :id is not the primary key, such as composite primary key models.
For example, if customers were defined with [:store_id, :id] as a primary key:

```
irb> customer = Customer.last
=> #<Customer id: 10, store_id: 5, first_name: "Joe">
irb> Customer.find_by(id: customer.id) # Customer.find_by(id: [5, 10])
=> #<Customer id: 5, store_id: 3, first_name: "Bob">
```

Here, we might intend to search for a single record with the composite primary key [5, 10], but Active Record will
search for a record with an :id column of either 5 or 10, and may return the wrong record.

The id_value method can be used to fetch the value of the :id column for a record, for use in finder
methods such as find_by and where. See example below:

```
irb> customer = Customer.last
=> #<Customer id: 10, store_id: 5, first_name: "Joe">
irb> Customer.find_by(id: customer.id_value) # Customer.find_by(id: 10)
=> #<Customer id: 10, store_id: 5, first_name: "Joe">
```

### 2.2. Retrieving Multiple Objects in Batches

We often need to iterate over a large set of records, as when we send a newsletter to a large set of customers, or when we export data.

This may appear straightforward:

```ruby
# This may consume too much memory if the table is big.
Customer.all.each do |customer|
  NewsMailer.weekly(customer).deliver_now
end
```

But this approach becomes increasingly impractical as the table size increases, since Customer.all.each instructs Active Record to fetch the entire table in a single pass, build a model object per row, and then keep the entire array of model objects in memory. Indeed, if we have a large number of records, the entire collection may exceed the amount of memory available.

Rails provides two methods that address this problem by dividing records into memory-friendly batches for processing. The first method, find_each, retrieves a batch of records and then yields each record to the block individually as a model. The second method, find_in_batches, retrieves a batch of records and then yields the entire batch to the block as an array of models.

The find_each and find_in_batches methods are intended for use in the batch processing of a large number of records that wouldn't fit in memory all at once. If you just need to loop over a thousand records the regular find methods are the preferred option.

#### 2.2.1. find_each

The find_each method retrieves records in batches and then yields each one to the block. In the following example, find_each retrieves customers in batches of 1000 and yields them to the block one by one:

```ruby
Customer.find_each do |customer|
  NewsMailer.weekly(customer).deliver_now
end
```

This process is repeated, fetching more batches as needed, until all of the records have been processed.

find_each works on model classes, as seen above, and also on relations:

```ruby
Customer.where(weekly_subscriber: true).find_each do |customer|
  NewsMailer.weekly(customer).deliver_now
end
```

as long as they have no ordering, since the method needs to force an order
internally to iterate.

If an order is present in the receiver the behavior depends on the flag
config.active_record.error_on_ignored_order. If true, ArgumentError is
raised, otherwise the order is ignored and a warning issued, which is the
default. This can be overridden with the option :error_on_ignore, explained
below.

:batch_size

The :batch_size option allows you to specify the number of records to be retrieved in each batch, before being passed individually to the block. For example, to retrieve records in batches of 5000:

```ruby
Customer.find_each(batch_size: 5000) do |customer|
  NewsMailer.weekly(customer).deliver_now
end
```

:start

By default, records are fetched in ascending order of the primary key. The :start option allows you to configure the first ID of the sequence whenever the lowest ID is not the one you need. This would be useful, for example, if you wanted to resume an interrupted batch process, provided you saved the last processed ID as a checkpoint.

For example, to send newsletters only to customers with the primary key starting from 2000:

```ruby
Customer.find_each(start: 2000) do |customer|
  NewsMailer.weekly(customer).deliver_now
end
```

:finish

Similar to the :start option, :finish allows you to configure the last ID of the sequence whenever the highest ID is not the one you need.
This would be useful, for example, if you wanted to run a batch process using a subset of records based on :start and :finish.

For example, to send newsletters only to customers with the primary key starting from 2000 up to 10000:

```ruby
Customer.find_each(start: 2000, finish: 10000) do |customer|
  NewsMailer.weekly(customer).deliver_now
end
```

Another example would be if you wanted multiple workers handling the same
processing queue. You could have each worker handle 10000 records by setting the
appropriate :start and :finish options on each worker.

:error_on_ignore

Overrides the application config to specify if an error should be raised when an
order is present in the relation.

:order

Specifies the primary key order (can be :asc or :desc). Defaults to :asc.

```ruby
Customer.find_each(order: :desc) do |customer|
  NewsMailer.weekly(customer).deliver_now
end
```

#### 2.2.2. find_in_batches

The find_in_batches method is similar to find_each, since both retrieve batches of records. The difference is that find_in_batches yields batches to the block as an array of models, instead of individually. The following example will yield to the supplied block an array of up to 1000 customers at a time, with the final block containing any remaining customers:

```ruby
# Give add_customers an array of 1000 customers at a time.
Customer.find_in_batches do |customers|
  export.add_customers(customers)
end
```

find_in_batches works on model classes, as seen above, and also on relations:

```ruby
# Give add_customers an array of 1000 recently active customers at a time.
Customer.recently_active.find_in_batches do |customers|
  export.add_customers(customers)
end
```

as long as they have no ordering, since the method needs to force an order
internally to iterate.

The find_in_batches method accepts the same options as find_each:

:batch_size

Just like for find_each, batch_size establishes how many records will be retrieved in each group. For example, retrieving batches of 2500 records can be specified as:

```ruby
Customer.find_in_batches(batch_size: 2500) do |customers|
  export.add_customers(customers)
end
```

:start

The start option allows specifying the beginning ID from where records will be selected. As mentioned before, by default records are fetched in ascending order of the primary key. For example, to retrieve customers starting on ID: 5000 in batches of 2500 records, the following code can be used:

```ruby
Customer.find_in_batches(batch_size: 2500, start: 5000) do |customers|
  export.add_customers(customers)
end
```

:finish

The finish option allows specifying the ending ID of the records to be retrieved. The code below shows the case of retrieving customers in batches, up to the customer with ID: 7000:

```ruby
Customer.find_in_batches(finish: 7000) do |customers|
  export.add_customers(customers)
end
```

:error_on_ignore

The error_on_ignore option overrides the application config to specify if an error should be raised when a specific order is present in the relation.

## 3. Conditions

The where method allows you to specify conditions to limit the records returned, representing the WHERE-part of the SQL statement. Conditions can either be specified as a string, array, or hash.

### 3.1. Pure String Conditions

If you'd like to add conditions to your find, you could just specify them in there, just like Book.where("title = 'Introduction to Algorithms'"). This will find all books where the title field value is 'Introduction to Algorithms'.

Building your own conditions as pure strings can leave you vulnerable to SQL injection exploits. For example, Book.where("title LIKE '%#{params[:title]}%'") is not safe. See the next section for the preferred way to handle conditions using an array.

### 3.2. Array Conditions

Now what if that title could vary, say as an argument from somewhere? The find would then take the form:

```ruby
Book.where("title = ?", params[:title])
```

Active Record will take the first argument as the conditions string and any additional arguments will replace the question marks (?) in it.

If you want to specify multiple conditions:

```ruby
Book.where("title = ? AND out_of_print = ?", params[:title], false)
```

In this example, the first question mark will be replaced with the value in params[:title] and the second will be replaced with the SQL representation of false, which depends on the adapter.

This code is highly preferable:

```ruby
Book.where("title = ?", params[:title])
```

to this code:

```ruby
Book.where("title = #{params[:title]}")
```

because of argument safety. Putting the variable directly into the conditions string will pass the variable to the database as-is. This means that it will be an unescaped variable directly from a user who may have malicious intent. If you do this, you put your entire database at risk because once a user finds out they can exploit your database they can do just about anything to it. Never ever put your arguments directly inside the conditions string.

For more information on the dangers of SQL injection, see the Ruby on Rails Security Guide.

#### 3.2.1. Placeholder Conditions

Similar to the (?) replacement style of params, you can also specify keys in your conditions string along with a corresponding keys/values hash:

```ruby
Book.where("created_at >= :start_date AND created_at <= :end_date",
  { start_date: params[:start_date], end_date: params[:end_date] })
```

This makes for clearer readability if you have a large number of variable conditions.

#### 3.2.2. Conditions That Use LIKE

Although condition arguments are automatically escaped to prevent SQL injection, SQL LIKE wildcards (i.e., % and _) are not escaped. This may cause unexpected behavior if an unsanitized value is used in an argument. For example:

```ruby
Book.where("title LIKE ?", params[:title] + "%")
```

In the above code, the intent is to match titles that start with a user-specified string. However, any occurrences of % or _ in params[:title] will be treated as wildcards, leading to surprising query results. In some circumstances, this may also prevent the database from using an intended index, leading to a much slower query.

To avoid these problems, use sanitize_sql_like to escape wildcard characters in the relevant portion of the argument:

```ruby
Book.where("title LIKE ?",
  Book.sanitize_sql_like(params[:title]) + "%")
```

### 3.3. Hash Conditions

Active Record also allows you to pass in hash conditions which can increase the readability of your conditions syntax. With hash conditions, you pass in a hash with keys of the fields you want qualified and the values of how you want to qualify them:

Only equality, range, and subset checking are possible with Hash conditions.

#### 3.3.1. Equality Conditions

```ruby
Book.where(out_of_print: true)
```

This will generate SQL like this:

```sql
SELECT * FROM books WHERE (books.out_of_print = 1)
```

The field name can also be a string:

```ruby
Book.where("out_of_print" => true)
```

In the case of a belongs_to relationship, an association key can be used to specify the model if an Active Record object is used as the value. This method works with polymorphic relationships as well.

```ruby
author = Author.first
Book.where(author: author)
Author.joins(:books).where(books: { author: author })
```

Hash conditions may also be specified in a tuple-like syntax, where the key is an array of columns and the value is
an array of tuples:

```ruby
Book.where([:author_id, :id] => [[15, 1], [15, 2]])
```

This syntax can be useful for querying relations where the table uses a composite primary key:

```ruby
class Book < ApplicationRecord
  self.primary_key = [:author_id, :id]
end

Book.where(Book.primary_key => [[2, 1], [3, 1]])
```

#### 3.3.2. Range Conditions

```ruby
Book.where(created_at: (Time.now.midnight - 1.day)..Time.now.midnight)
```

This will find all books created yesterday by using a BETWEEN SQL statement:

```sql
SELECT * FROM books WHERE (books.created_at BETWEEN '2008-12-21 00:00:00' AND '2008-12-22 00:00:00')
```

This demonstrates a shorter syntax for the examples in Array Conditions

Beginless and endless ranges are supported and can be used to build less/greater than conditions.

```ruby
Book.where(created_at: (Time.now.midnight - 1.day)..)
```

This would generate SQL like:

```sql
SELECT * FROM books WHERE books.created_at >= '2008-12-21 00:00:00'
```

#### 3.3.3. Subset Conditions

If you want to find records using the IN expression you can pass an array to the conditions hash:

```ruby
Customer.where(orders_count: [1, 3, 5])
```

This code will generate SQL like this:

```sql
SELECT * FROM customers WHERE (customers.orders_count IN (1,3,5))
```

### 3.4. NOT Conditions

NOT SQL queries can be built by where.not:

```ruby
Customer.where.not(orders_count: [1, 3, 5])
```

In other words, this query can be generated by calling where with no argument, then immediately chain with not passing where conditions.  This will generate SQL like this:

```sql
SELECT * FROM customers WHERE (customers.orders_count NOT IN (1,3,5))
```

If a query has a hash condition with non-nil values on a nullable column, the records that have nil values on the nullable column won't be returned. For example:

```ruby
Customer.create!(nullable_country: nil)
Customer.where.not(nullable_country: "UK")
# => []

# But
Customer.create!(nullable_country: "UK")
Customer.where.not(nullable_country: nil)
# => [#<Customer id: 2, nullable_country: "UK">]
```

### 3.5. OR Conditions

OR conditions between two relations can be built by calling or on the first
relation, and passing the second one as an argument.

```ruby
Customer.where(last_name: "Smith").or(Customer.where(orders_count: [1, 3, 5]))
```

```sql
SELECT * FROM customers WHERE (customers.last_name = 'Smith' OR customers.orders_count IN (1,3,5))
```

### 3.6. AND Conditions

AND conditions can be built by chaining where conditions.

```ruby
Customer.where(last_name: "Smith").where(orders_count: [1, 3, 5])
```

```sql
SELECT * FROM customers WHERE customers.last_name = 'Smith' AND customers.orders_count IN (1,3,5)
```

AND conditions for the logical intersection between relations can be built by
calling and on the first relation, and passing the second one as an
argument.

```ruby
Customer.where(id: [1, 2]).and(Customer.where(id: [2, 3]))
```

```sql
SELECT * FROM customers WHERE (customers.id IN (1, 2) AND customers.id IN (2, 3))
```

## 4. Ordering

To retrieve records from the database in a specific order, you can use the order method.

For example, if you're getting a set of records and want to order them in ascending order by the created_at field in your table:

```ruby
Book.order(:created_at)
# OR
Book.order("created_at")
```

You could specify ASC or DESC as well:

```ruby
Book.order(created_at: :desc)
# OR
Book.order(created_at: :asc)
# OR
Book.order("created_at DESC")
# OR
Book.order("created_at ASC")
```

Or ordering by multiple fields:

```ruby
Book.order(title: :asc, created_at: :desc)
# OR
Book.order(:title, created_at: :desc)
# OR
Book.order("title ASC, created_at DESC")
# OR
Book.order("title ASC", "created_at DESC")
```

If you want to call order multiple times, subsequent orders will be appended to the first:

```
irb> Book.order("title ASC").order("created_at DESC")
SELECT * FROM books ORDER BY title ASC, created_at DESC
```

You can also order from a joined table

```ruby
Book.includes(:author).order(books: { print_year: :desc }, authors: { name: :asc })
# OR
Book.includes(:author).order("books.print_year desc", "authors.name asc")
```

In most database systems, on selecting fields with distinct from a result set using methods like select, pluck and ids; the order method will raise an ActiveRecord::StatementInvalid exception unless the field(s) used in order clause are included in the select list. See the next section for selecting fields from the result set.

## 5. Selecting Specific Fields

By default, Model.find selects all the fields from the result set using select *.

To select only a subset of fields from the result set, you can specify the subset via the select method.

For example, to select only isbn and out_of_print columns:

```ruby
Book.select(:isbn, :out_of_print)
# OR
Book.select("isbn, out_of_print")
```

The SQL query used by this find call will be somewhat like:

```sql
SELECT isbn, out_of_print FROM books
```

Be careful because this also means you're initializing a model object with only the fields that you've selected. If you attempt to access a field that is not in the initialized record you'll receive:

```
ActiveModel::MissingAttributeError: missing attribute '<attribute>' for Book
```

Where <attribute> is the attribute you asked for. The id method will not raise the ActiveRecord::MissingAttributeError, so just be careful when working with associations because they need the id method to function properly.

If you would like to only grab a single record per unique value in a certain field, you can use distinct:

```ruby
Customer.select(:last_name).distinct
```

This would generate SQL like:

```sql
SELECT DISTINCT last_name FROM customers
```

You can also remove the uniqueness constraint:

```ruby
# Returns unique last_names
query = Customer.select(:last_name).distinct

# Returns all last_names, even if there are duplicates
query.distinct(false)
```

## 6. Limit and Offset

To apply LIMIT to the SQL fired by the Model.find, you can specify the LIMIT using limit and offset methods on the relation.

You can use limit to specify the number of records to be retrieved, and use offset to specify the number of records to skip before starting to return the records. For example:

```ruby
Customer.limit(5)
```

will return a maximum of 5 customers and because it specifies no offset it will return the first 5 in the table. The SQL it executes looks like this:

```sql
SELECT * FROM customers LIMIT 5
```

Adding offset to that

```ruby
Customer.limit(5).offset(30)
```

will return instead a maximum of 5 customers beginning with the 31st. The SQL looks like:

```sql
SELECT * FROM customers LIMIT 5 OFFSET 30
```

## 7. Grouping

To apply a GROUP BY clause to the SQL fired by the finder, you can use the group method.

For example, if you want to find a collection of the dates on which orders were created:

```ruby
Order.select("created_at").group("created_at")
```

And this will give you a single Order object for each date where there are orders in the database.

The SQL that would be executed would be something like this:

```sql
SELECT created_at
FROM orders
GROUP BY created_at
```

### 7.1. Total of Grouped Items

To get the total of grouped items on a single query, call count after the group.

```
irb> Order.group(:status).count
=> {"being_packed"=>7, "shipped"=>12}
```

The SQL that would be executed would be something like this:

```sql
SELECT COUNT (*) AS count_all, status AS status
FROM orders
GROUP BY status
```

### 7.2. HAVING Conditions

SQL uses the HAVING clause to specify conditions on the GROUP BY fields. You can add the HAVING clause to the SQL fired by the Model.find by adding the having method to the find.

For example:

```ruby
Order.select("created_at as ordered_date, sum(total) as total_price").
  group("created_at").having("sum(total) > ?", 200)
```

The SQL that would be executed would be something like this:

```sql
SELECT created_at as ordered_date, sum(total) as total_price
FROM orders
GROUP BY created_at
HAVING sum(total) > 200
```

This returns the date and total price for each order object, grouped by the day they were ordered and where the total is more than $200.

You would access the total_price for each order object returned like this:

```ruby
big_orders = Order.select("created_at, sum(total) as total_price")
                  .group("created_at")
                  .having("sum(total) > ?", 200)

big_orders[0].total_price
# Returns the total price for the first Order object
```

## 8. Overriding Conditions

### 8.1. unscope

You can specify certain conditions to be removed using the unscope method. For example:

```ruby
Book.where("id > 100").limit(20).order("id desc").unscope(:order)
```

The SQL that would be executed:

```sql
SELECT * FROM books WHERE id > 100 LIMIT 20

-- Original query without `unscope`
SELECT * FROM books WHERE id > 100 ORDER BY id desc LIMIT 20
```

You can also unscope specific where clauses. For example, this will remove id condition from the where clause:

```ruby
Book.where(id: 10, out_of_print: false).unscope(where: :id)
# SELECT books.* FROM books WHERE out_of_print = 0
```

A relation which has used unscope will affect any relation into which it is merged:

```ruby
Book.order("id desc").merge(Book.unscope(:order))
# SELECT books.* FROM books
```

### 8.2. only

You can also override conditions using the only method. For example:

```ruby
Book.where("id > 10").limit(20).order("id desc").only(:order, :where)
```

The SQL that would be executed:

```sql
SELECT * FROM books WHERE id > 10 ORDER BY id DESC

-- Original query without `only`
SELECT * FROM books WHERE id > 10 ORDER BY id DESC LIMIT 20
```

### 8.3. reselect

The reselect method overrides an existing select statement. For example:

```ruby
Book.select(:title, :isbn).reselect(:created_at)
```

The SQL that would be executed:

```sql
SELECT books.created_at FROM books
```

Compare this to the case where the reselect clause is not used:

```ruby
Book.select(:title, :isbn).select(:created_at)
```

The SQL executed would be:

```sql
SELECT books.title, books.isbn, books.created_at FROM books
```

### 8.4. reorder

The reorder method overrides the default scope order. For example, if the class definition includes this:

```ruby
class Author < ApplicationRecord
  has_many :books, -> { order(year_published: :desc) }
end
```

And you execute this:

```ruby
Author.find(10).books
```

The SQL that would be executed:

```sql
SELECT * FROM authors WHERE id = 10 LIMIT 1
SELECT * FROM books WHERE author_id = 10 ORDER BY year_published DESC
```

You can using the reorder clause to specify a different way to order the books:

```ruby
Author.find(10).books.reorder("year_published ASC")
```

The SQL that would be executed:

```sql
SELECT * FROM authors WHERE id = 10 LIMIT 1
SELECT * FROM books WHERE author_id = 10 ORDER BY year_published ASC
```

### 8.5. reverse_order

The reverse_order method reverses the ordering clause if specified.

```ruby
Book.where("author_id > 10").order(:year_published).reverse_order
```

The SQL that would be executed:

```sql
SELECT * FROM books WHERE author_id > 10 ORDER BY year_published DESC
```

If no ordering clause is specified in the query, the reverse_order orders by the primary key in reverse order.

```ruby
Book.where("author_id > 10").reverse_order
```

The SQL that would be executed:

```sql
SELECT * FROM books WHERE author_id > 10 ORDER BY books.id DESC
```

The reverse_order method accepts no arguments.

### 8.6. rewhere

The rewhere method overrides an existing, named where condition. For example:

```ruby
Book.where(out_of_print: true).rewhere(out_of_print: false)
```

The SQL that would be executed:

```sql
SELECT * FROM books WHERE out_of_print = 0
```

If the rewhere clause is not used, the where clauses are ANDed together:

```ruby
Book.where(out_of_print: true).where(out_of_print: false)
```

The SQL executed would be:

```sql
SELECT * FROM books WHERE out_of_print = 1 AND out_of_print = 0
```

### 8.7. regroup

The regroup method overrides an existing, named group condition. For example:

```ruby
Book.group(:author).regroup(:id)
```

The SQL that would be executed:

```sql
SELECT * FROM books GROUP BY id
```

If the regroup clause is not used, the group clauses are combined together:

```ruby
Book.group(:author).group(:id)
```

The SQL executed would be:

```sql
SELECT * FROM books GROUP BY author, id
```

## 9. Null Relation

The none method returns a chainable relation with no records. Any subsequent conditions chained to the returned relation will continue generating empty relations. This is useful in scenarios where you need a chainable response to a method or a scope that could return zero results.

```ruby
Book.none # returns an empty Relation and fires no queries.
```

```ruby
# The highlighted_reviews method below is expected to always return a Relation.
Book.first.highlighted_reviews.average(:rating)
# => Returns average rating of a book

class Book
  # Returns reviews if there are at least 5,
  # else consider this as non-reviewed book
  def highlighted_reviews
    if reviews.count >= 5
      reviews
    else
      Review.none # Does not meet minimum threshold yet
    end
  end
end
```

## 10. Readonly Objects

Active Record provides the readonly method on a relation to explicitly disallow modification of any of the returned objects. Any attempt to alter a readonly record will not succeed, raising an ActiveRecord::ReadOnlyRecord exception.

```ruby
customer = Customer.readonly.first
customer.visits += 1
customer.save # Raises an ActiveRecord::ReadOnlyRecord
```

As customer is explicitly set to be a readonly object, the above code will raise an ActiveRecord::ReadOnlyRecord exception when calling customer.save with an updated value of visits.

## 11. Locking Records for Update

Locking is helpful for preventing race conditions when updating records in the database and ensuring atomic updates.

Active Record provides two locking mechanisms:

- Optimistic Locking

- Pessimistic Locking

### 11.1. Optimistic Locking

Optimistic locking allows multiple users to access the same record for edits, and assumes a minimum of conflicts with the data. It does this by checking whether another process has made changes to a record since it was opened. An ActiveRecord::StaleObjectError exception is thrown if that has occurred and the update is ignored.

Optimistic locking column

In order to use optimistic locking, the table needs to have a column called lock_version of type integer. Each time the record is updated, Active Record increments the lock_version column. If an update request is made with a lower value in the lock_version field than is currently in the lock_version column in the database, the update request will fail with an ActiveRecord::StaleObjectError.

For example:

```ruby
c1 = Customer.find(1)
c2 = Customer.find(1)

c1.first_name = "Sandra"
c1.save

c2.first_name = "Michael"
c2.save # Raises an ActiveRecord::StaleObjectError
```

You're then responsible for dealing with the conflict by rescuing the exception and either rolling back, merging, or otherwise apply the business logic needed to resolve the conflict.

This behavior can be turned off by setting ActiveRecord::Base.lock_optimistically = false.

To override the name of the lock_version column, ActiveRecord::Base provides a class attribute called locking_column:

```ruby
class Customer < ApplicationRecord
  self.locking_column = :lock_customer_column
end
```

### 11.2. Pessimistic Locking

Pessimistic locking uses a locking mechanism provided by the underlying database. Using lock when building a relation obtains an exclusive lock on the selected rows. Relations using lock are usually wrapped inside a transaction for preventing deadlock conditions.

For example:

```ruby
Book.transaction do
  book = Book.lock.first
  book.title = "Algorithms, second edition"
  book.save!
end
```

The above session produces the following SQL for a MySQL backend:

```sql
SQL (0.2ms)   BEGIN
Book Load (0.3ms)   SELECT * FROM books LIMIT 1 FOR UPDATE
Book Update (0.4ms)   UPDATE books SET updated_at = '2009-02-07 18:05:56', title = 'Algorithms, second edition' WHERE id = 1
SQL (0.8ms)   COMMIT
```

You can also pass raw SQL to the lock method for allowing different types of locks. For example, MySQL has an expression called LOCK IN SHARE MODE where you can lock a record but still allow other queries to read it. To specify this expression just pass it in as the lock option:

```ruby
Book.transaction do
  book = Book.lock("LOCK IN SHARE MODE").find(1)
  book.increment!(:views)
end
```

Note that your database must support the raw SQL, that you pass in to the lock method.

If you already have an instance of your model, you can start a transaction and acquire the lock in one go using the following code:

```ruby
book = Book.first
book.with_lock do
  # This block is called within a transaction,
  # book is already locked.
  book.increment!(:views)
end
```

## 12. Joining Tables

Active Record provides two finder methods for specifying JOIN clauses on the
resulting SQL: joins and left_outer_joins.
While joins should be used for INNER JOIN or custom queries,
left_outer_joins is used for queries using LEFT OUTER JOIN.

### 12.1. joins

There are multiple ways to use the joins method.

#### 12.1.1. Using a String SQL Fragment

You can just supply the raw SQL specifying the JOIN clause to joins:

```ruby
Author.joins("INNER JOIN books ON books.author_id = authors.id AND books.out_of_print = FALSE")
```

This will result in the following SQL:

```sql
SELECT authors.* FROM authors INNER JOIN books ON books.author_id = authors.id AND books.out_of_print = FALSE
```

#### 12.1.2. Using Array/Hash of Named Associations

Active Record lets you use the names of the associations defined on the model as a shortcut for specifying JOIN clauses for those associations when using the joins method.

All of the following will produce the expected join queries using INNER JOIN:

```ruby
Book.joins(:reviews)
```

This produces:

```sql
SELECT books.* FROM books
  INNER JOIN reviews ON reviews.book_id = books.id
```

Or, in English: "return a Book object for all books with reviews". Note that you will see duplicate books if a book has more than one review.  If you want unique books, you can use Book.joins(:reviews).distinct.

#### 12.1.3. Joining Multiple Associations

```ruby
Book.joins(:author, :reviews)
```

This produces:

```sql
SELECT books.* FROM books
  INNER JOIN authors ON authors.id = books.author_id
  INNER JOIN reviews ON reviews.book_id = books.id
```

Or, in English: "return all books that have an author and at least one review". Note again that books with multiple reviews will show up multiple times.

```ruby
Book.joins(reviews: :customer)
```

This produces:

```sql
SELECT books.* FROM books
  INNER JOIN reviews ON reviews.book_id = books.id
  INNER JOIN customers ON customers.id = reviews.customer_id
```

Or, in English: "return all books that have a review by a customer."

```ruby
Author.joins(books: [{ reviews: { customer: :orders } }, :supplier])
```

This produces:

```sql
SELECT authors.* FROM authors
  INNER JOIN books ON books.author_id = authors.id
  INNER JOIN reviews ON reviews.book_id = books.id
  INNER JOIN customers ON customers.id = reviews.customer_id
  INNER JOIN orders ON orders.customer_id = customers.id
INNER JOIN suppliers ON suppliers.id = books.supplier_id
```

Or, in English: "return all authors that have books with reviews and have been ordered by a customer, and the suppliers for those books."

#### 12.1.4. Specifying Conditions on the Joined Tables

You can specify conditions on the joined tables using the regular Array and String conditions. Hash conditions provide a special syntax for specifying conditions for the joined tables:

```ruby
time_range = (Time.now.midnight - 1.day)..Time.now.midnight
Customer.joins(:orders).where("orders.created_at" => time_range).distinct
```

This will find all customers who have orders that were created yesterday, using a BETWEEN SQL expression to compare created_at.

An alternative and cleaner syntax is to nest the hash conditions:

```ruby
time_range = (Time.now.midnight - 1.day)..Time.now.midnight
Customer.joins(:orders).where(orders: { created_at: time_range }).distinct
```

For more advanced conditions or to reuse an existing named scope, merge may be used. First, let's add a new named scope to the Order model:

```ruby
class Order < ApplicationRecord
  belongs_to :customer

  scope :created_in_time_range, ->(time_range) {
    where(created_at: time_range)
  }
end
```

Now we can use merge to merge in the created_in_time_range scope:

```ruby
time_range = (Time.now.midnight - 1.day)..Time.now.midnight
Customer.joins(:orders).merge(Order.created_in_time_range(time_range)).distinct
```

This will find all customers who have orders that were created yesterday, again using a BETWEEN SQL expression.

### 12.2. left_outer_joins

If you want to select a set of records whether or not they have associated
records you can use the left_outer_joins method.

```ruby
Customer.left_outer_joins(:reviews).distinct.select("customers.*, COUNT(reviews.*) AS reviews_count").group("customers.id")
```

Which produces:

```sql
SELECT DISTINCT customers.*, COUNT(reviews.*) AS reviews_count FROM customers
LEFT OUTER JOIN reviews ON reviews.customer_id = customers.id GROUP BY customers.id
```

Which means: "return all customers with their count of reviews, whether or not they
have any reviews at all"

### 12.3. where.associated and where.missing

The associated and missing query methods let you select a set of records
based on the presence or absence of an association.

To use where.associated:

```ruby
Customer.where.associated(:reviews)
```

Produces:

```sql
SELECT customers.* FROM customers
INNER JOIN reviews ON reviews.customer_id = customers.id
WHERE reviews.id IS NOT NULL
```

Which means "return all customers that have made at least one review".

To use where.missing:

```ruby
Customer.where.missing(:reviews)
```

Produces:

```sql
SELECT customers.* FROM customers
LEFT OUTER JOIN reviews ON reviews.customer_id = customers.id
WHERE reviews.id IS NULL
```

Which means "return all customers that have not made any reviews".

## 13. Eager Loading Associations

Eager loading is the mechanism for loading the associated records of the objects returned by Model.find using as few queries as possible.

### 13.1. N + 1 Queries Problem

Consider the following code, which finds 10 books and prints their authors' last_name:

```ruby
books = Book.limit(10)

books.each do |book|
  puts book.author.last_name
end
```

This code looks fine at the first sight. But the problem lies within the total number of queries executed. The above code executes 1 (to find 10 books) + 10 (one per each book to load the author) = 11 queries in total.

#### 13.1.1. Solution to N + 1 Queries Problem

Active Record lets you specify in advance all the associations that are going to be loaded.

The methods are:

- includes

- preload

- eager_load

### 13.2. includes

With includes, Active Record ensures that all of the specified associations are loaded using the minimum possible number of queries.

Revisiting the above case using the includes method, we could rewrite Book.limit(10) to eager load authors:

```ruby
books = Book.includes(:author).limit(10)

books.each do |book|
  puts book.author.last_name
end
```

The above code will execute just 2 queries, as opposed to the 11 queries from the original case:

```sql
SELECT books.* FROM books LIMIT 10
SELECT authors.* FROM authors
  WHERE authors.id IN (1,2,3,4,5,6,7,8,9,10)
```

#### 13.2.1. Eager Loading Multiple Associations

Active Record lets you eager load any number of associations with a single Model.find call by using an array, hash, or a nested hash of array/hash with the includes method.

```ruby
Customer.includes(:orders, :reviews)
```

This loads all the customers and the associated orders and reviews for each.

```ruby
Customer.includes(orders: { books: [:supplier, :author] }).find(1)
```

This will find the customer with id 1 and eager load all of the associated orders for it, the books for all of the orders, and the author and supplier for each of the books.

#### 13.2.2. Specifying Conditions on Eager Loaded Associations

Even though Active Record lets you specify conditions on the eager loaded associations just like joins, the recommended way is to use joins instead.

However if you must do this, you may use where as you would normally.

```ruby
Author.includes(:books).where(books: { out_of_print: true })
```

This would generate a query which contains a LEFT OUTER JOIN whereas the
joins method would generate one using the INNER JOIN function instead.

```sql
SELECT authors.id AS t0_r0, ... books.updated_at AS t1_r5 FROM authors LEFT OUTER JOIN books ON books.author_id = authors.id WHERE (books.out_of_print = 1)
```

If there was no where condition, this would generate the normal set of two queries.

Using where like this will only work when you pass it a Hash. For
SQL-fragments you need to use references to force joined tables:

```ruby
Author.includes(:books).where("books.out_of_print = true").references(:books)
```

If, in the case of this includes query, there were no books for any
authors, all the authors would still be loaded. By using joins (an INNER
JOIN), the join conditions must match, otherwise no records will be
returned.

If an association is eager loaded as part of a join, any fields from a custom select clause will not be present on the loaded models.
This is because it is ambiguous whether they should appear on the parent record, or the child.

### 13.3. preload

With preload, Active Record loads each specified association using one query per association.

Revisiting the N + 1 queries problem, we could rewrite Book.limit(10) to preload authors:

```ruby
books = Book.preload(:author).limit(10)

books.each do |book|
  puts book.author.last_name
end
```

The above code will execute just 2 queries, as opposed to the 11 queries from the original case:

```sql
SELECT books.* FROM books LIMIT 10
SELECT authors.* FROM authors
  WHERE authors.id IN (1,2,3,4,5,6,7,8,9,10)
```

The preload method uses an array, hash, or a nested hash of array/hash in the same way as the includes method to load any number of associations with a single Model.find call. However, unlike the includes method, it is not possible to specify conditions for preloaded associations.

### 13.4. eager_load

With eager_load, Active Record loads all specified associations using a LEFT OUTER JOIN.

Revisiting the case where N + 1 was occurred using the eager_load method, we could rewrite Book.limit(10) to eager load authors:

```ruby
books = Book.eager_load(:author).limit(10)

books.each do |book|
  puts book.author.last_name
end
```

The above code will execute just 1 query, as opposed to the 11 queries from the original case:

```sql
SELECT "books"."id" AS t0_r0, "books"."title" AS t0_r1, ... FROM "books"
  LEFT OUTER JOIN "authors" ON "authors"."id" = "books"."author_id"
  LIMIT 10
```

The eager_load method uses an array, hash, or a nested hash of array/hash in the same way as the includes method to load any number of associations with a single Model.find call. Also, like the includes method, you can specify conditions for eager loaded associations.

### 13.5. strict_loading

Eager loading can prevent N + 1 queries but you might still be lazy loading
some associations. To make sure no associations are lazy loaded you can enable
strict_loading.

By enabling strict loading mode on a relation, an
ActiveRecord::StrictLoadingViolationError will be raised if the record tries
to lazily load any association:

```ruby
user = User.strict_loading.first
user.address.city # raises an ActiveRecord::StrictLoadingViolationError
user.comments.to_a # raises an ActiveRecord::StrictLoadingViolationError
```

To enable for all relations, change the
config.active_record.strict_loading_by_default flag to true.

To send violations to the logger instead, change
config.active_record.action_on_strict_loading_violation to :log.

### 13.6. strict_loading

We can also enable strict loading on the record itself by calling strict_loading!:

```ruby
user = User.first
user.strict_loading!
user.address.city # raises an ActiveRecord::StrictLoadingViolationError
user.comments.to_a # raises an ActiveRecord::StrictLoadingViolationError
```

strict_loading! also takes a :mode argument. Setting it to :n_plus_one_only
will only raise an error if an association that will lead to an N + 1 query is
lazily loaded:

```ruby
user.strict_loading!(mode: :n_plus_one_only)
user.address.city # => "Tatooine"
user.comments.to_a # => [#<Comment:0x00...]
user.comments.first.likes.to_a # raises an ActiveRecord::StrictLoadingViolationError
```

### 13.7. strict_loading option on an association

We can also enable strict loading for a single association by providing the strict_loading option:

```ruby
class Author < ApplicationRecord
  has_many :books, strict_loading: true
end
```

## 14. Scopes

Scoping allows you to specify commonly-used queries which can be referenced as method calls on the association objects or models. With these scopes, you can use every method previously covered such as where, joins and includes. All scope bodies should return an ActiveRecord::Relation or nil to allow for further methods (such as other scopes) to be called on it.

To define a simple scope, we use the scope method inside the class, passing the query that we'd like to run when this scope is called:

```ruby
class Book < ApplicationRecord
  scope :out_of_print, -> { where(out_of_print: true) }
end
```

To call this out_of_print scope we can call it on either the class:

```
irb> Book.out_of_print
=> #<ActiveRecord::Relation> # all out of print books
```

Or on an association consisting of Book objects:

```
irb> author = Author.first
irb> author.books.out_of_print
=> #<ActiveRecord::Relation> # all out of print books by `author`
```

Scopes are also chainable within scopes:

```ruby
class Book < ApplicationRecord
  scope :out_of_print, -> { where(out_of_print: true) }
  scope :out_of_print_and_expensive, -> { out_of_print.where("price > 500") }
end
```

### 14.1. Passing in Arguments

Your scope can take arguments:

```ruby
class Book < ApplicationRecord
  scope :costs_more_than, ->(amount) { where("price > ?", amount) }
end
```

Call the scope as if it were a class method:

```
irb> Book.costs_more_than(100.10)
```

However, this is just duplicating the functionality that would be provided to you by a class method.

```ruby
class Book < ApplicationRecord
  def self.costs_more_than(amount)
    where("price > ?", amount)
  end
end
```

These methods will still be accessible on the association objects:

```
irb> author.books.costs_more_than(100.10)
```

### 14.2. Using Conditionals

Your scope can utilize conditionals:

```ruby
class Order < ApplicationRecord
  scope :created_before, ->(time) { where(created_at: ...time) if time.present? }
end
```

Like the other examples, this will behave similarly to a class method.

```ruby
class Order < ApplicationRecord
  def self.created_before(time)
    where(created_at: ...time) if time.present?
  end
end
```

However, there is one important caveat: A scope will always return an ActiveRecord::Relation object, even if the conditional evaluates to false, whereas a class method, will return nil. This can cause NoMethodError when chaining class methods with conditionals, if any of the conditionals return false.

### 14.3. Applying a Default Scope

If we wish for a scope to be applied across all queries to the model we can use the
default_scope method within the model itself.

```ruby
class Book < ApplicationRecord
  default_scope { where(out_of_print: false) }
end
```

When queries are executed on this model, the SQL query will now look something like
this:

```sql
SELECT * FROM books WHERE (out_of_print = false)
```

If you need to do more complex things with a default scope, you can alternatively
define it as a class method:

```ruby
class Book < ApplicationRecord
  def self.default_scope
    # Should return an ActiveRecord::Relation.
  end
end
```

The default_scope is also applied while creating/building a record
when the scope arguments are given as a Hash. It is not applied while
updating a record. E.g.:

```ruby
class Book < ApplicationRecord
  default_scope { where(out_of_print: false) }
end
```

```
irb> Book.new
=> #<Book id: nil, out_of_print: false>
irb> Book.unscoped.new
=> #<Book id: nil, out_of_print: nil>
```

Be aware that, when given in the Array format, default_scope query arguments
cannot be converted to a Hash for default attribute assignment. E.g.:

```ruby
class Book < ApplicationRecord
  default_scope { where("out_of_print = ?", false) }
end
```

```
irb> Book.new
=> #<Book id: nil, out_of_print: nil>
```

### 14.4. Merging of Scopes

Just like where clauses, scopes are merged using AND conditions.

```ruby
class Book < ApplicationRecord
  scope :in_print, -> { where(out_of_print: false) }
  scope :out_of_print, -> { where(out_of_print: true) }

  scope :recent, -> { where(year_published: 50.years.ago.year..) }
  scope :old, -> { where(year_published: ...50.years.ago.year) }
end
```

```
irb> Book.out_of_print.old
SELECT books.* FROM books WHERE books.out_of_print = 'true' AND books.year_published < 1969
```

We can mix and match scope and where conditions and the final SQL
will have all conditions joined with AND.

```
irb> Book.in_print.where(price: ...100)
SELECT books.* FROM books WHERE books.out_of_print = 'false' AND books.price < 100
```

If we do want the last where clause to win then merge can
be used.

```
irb> Book.in_print.merge(Book.out_of_print)
SELECT books.* FROM books WHERE books.out_of_print = true
```

One important caveat is that default_scope will be prepended in
scope and where conditions.

```ruby
class Book < ApplicationRecord
  default_scope { where(year_published: 50.years.ago.year..) }

  scope :in_print, -> { where(out_of_print: false) }
  scope :out_of_print, -> { where(out_of_print: true) }
end
```

```
irb> Book.all
SELECT books.* FROM books WHERE (year_published >= 1969)

irb> Book.in_print
SELECT books.* FROM books WHERE (year_published >= 1969) AND books.out_of_print = false

irb> Book.where('price > 50')
SELECT books.* FROM books WHERE (year_published >= 1969) AND (price > 50)
```

As you can see above the default_scope is being merged in both
scope and where conditions.

### 14.5. Removing All Scoping

If we wish to remove scoping for any reason we can use the unscoped method. This is
especially useful if a default_scope is specified in the model and should not be
applied for this particular query.

```ruby
Book.unscoped.load
```

This method removes all scoping and will do a normal query on the table.

```
irb> Book.unscoped.all
SELECT books.* FROM books

irb> Book.where(out_of_print: true).unscoped.all
SELECT books.* FROM books
```

unscoped can also accept a block:

```
irb> Book.unscoped { Book.out_of_print }
SELECT books.* FROM books WHERE books.out_of_print = true
```

## 15. Dynamic Finders

For every field (also known as an attribute) you define in your table,
Active Record provides a finder method. If you have a field called first_name on your Customer model for example,
you get the instance method find_by_first_name for free from Active Record.
If you also have a locked field on the Customer model, you also get find_by_locked method.

You can specify an exclamation point (!) on the end of the dynamic finders
to get them to raise an ActiveRecord::RecordNotFound error if they do not return any records, like Customer.find_by_first_name!("Ryan")

If you want to find both by first_name and orders_count, you can chain these finders together by simply typing "and" between the fields.
For example, Customer.find_by_first_name_and_orders_count("Ryan", 5).

## 16. Enums

An enum lets you define an Array of values for an attribute and refer to them by name.  The actual value stored in the database is an integer that has been mapped to one of the values.

Declaring an enum will:

- Create scopes that can be used to find all objects that have or do not have one of the enum values

- Create an instance method that can be used to determine if an object has a particular value for the enum

- Create an instance method that can be used to change the enum value of an object

for all possible values of an enum.

For example, given this enum declaration:

```ruby
class Order < ApplicationRecord
  enum :status, [:shipped, :being_packaged, :complete, :cancelled]
end
```

These scopes are created automatically and can be used to find all objects with or without a particular value for status:

```
irb> Order.shipped
=> #<ActiveRecord::Relation> # all orders with status == :shipped
irb> Order.not_shipped
=> #<ActiveRecord::Relation> # all orders with status != :shipped
```

These instance methods are created automatically and query whether the model has that value for the status enum:

```
irb> order = Order.shipped.first
irb> order.shipped?
=> true
irb> order.complete?
=> false
```

These instance methods are created automatically and will first update the value of status to the named value
and then query whether or not the status has been successfully set to the value:

```
irb> order = Order.first
irb> order.shipped!
UPDATE "orders" SET "status" = ?, "updated_at" = ? WHERE "orders"."id" = ?  [["status", 0], ["updated_at", "2019-01-24 07:13:08.524320"], ["id", 1]]
=> true
```

Full documentation about enums can be found here.

## 17. Understanding Method Chaining

The Active Record pattern implements Method Chaining,
which allows us to use multiple Active Record methods together in a simple and straightforward way.

You can chain methods in a statement when the previous method called returns an
ActiveRecord::Relation, like all, where, and joins. Methods that return
a single object (see Retrieving a Single Object Section)
have to be at the end of the statement.

There are some examples below. This guide won't cover all the possibilities, just a few as examples.
When an Active Record method is called, the query is not immediately generated and sent to the database.
The query is sent only when the data is actually needed. So each example below generates a single query.

### 17.1. Retrieving Filtered Data from Multiple Tables

```ruby
Customer
  .select("customers.id, customers.last_name, reviews.body")
  .joins(:reviews)
  .where("reviews.created_at > ?", 1.week.ago)
```

The result should be something like this:

```sql
SELECT customers.id, customers.last_name, reviews.body
FROM customers
INNER JOIN reviews
  ON reviews.customer_id = customers.id
WHERE (reviews.created_at > '2019-01-08')
```

### 17.2. Retrieving Specific Data from Multiple Tables

```ruby
Book
  .select("books.id, books.title, authors.first_name")
  .joins(:author)
  .find_by(title: "Abstraction and Specification in Program Development")
```

The above should generate:

```sql
SELECT books.id, books.title, authors.first_name
FROM books
INNER JOIN authors
  ON authors.id = books.author_id
WHERE books.title = $1 [["title", "Abstraction and Specification in Program Development"]]
LIMIT 1
```

Note that if a query matches multiple records, find_by will
fetch only the first one and ignore the others (see the LIMIT 1
statement above).

## 18. Find or Build a New Object

It's common that you need to find a record or create it if it doesn't exist. You can do that with the find_or_create_by and find_or_create_by! methods.

### 18.1. find_or_create_by

The find_or_create_by method checks whether a record with the specified attributes exists. If it doesn't, then create is called. Let's see an example.

Suppose you want to find a customer named "Andy", and if there's none, create one. You can do so by running:

```
irb> Customer.find_or_create_by(first_name: 'Andy')
=> #<Customer id: 5, first_name: "Andy", last_name: nil, title: nil, visits: 0, orders_count: nil, lock_version: 0, created_at: "2019-01-17 07:06:45", updated_at: "2019-01-17 07:06:45">
```

The SQL generated by this method looks like this:

```sql
SELECT * FROM customers WHERE (customers.first_name = 'Andy') LIMIT 1
BEGIN
INSERT INTO customers (created_at, first_name, locked, orders_count, updated_at) VALUES ('2011-08-30 05:22:57', 'Andy', 1, NULL, '2011-08-30 05:22:57')
COMMIT
```

find_or_create_by returns either the record that already exists or the new record. In our case, we didn't already have a customer named Andy so the record is created and returned.

The new record might not be saved to the database; that depends on whether validations passed or not (just like create).

Suppose we want to set the 'locked' attribute to false if we're
creating a new record, but we don't want to include it in the query. So
we want to find the customer named "Andy", or if that customer doesn't
exist, create a customer named "Andy" which is not locked.

We can achieve this in two ways. The first is to use create_with:

```ruby
Customer.create_with(locked: false).find_or_create_by(first_name: "Andy")
```

The second way is using a block:

```ruby
Customer.find_or_create_by(first_name: "Andy") do |c|
  c.locked = false
end
```

The block will only be executed if the customer is being created. The
second time we run this code, the block will be ignored.

### 18.2. find_or_create_by

You can also use find_or_create_by! to raise an exception if the new record is invalid. Validations are not covered on this guide, but let's assume for a moment that you temporarily add

```ruby
validates :orders_count, presence: true
```

to your Customer model. If you try to create a new Customer without passing an orders_count, the record will be invalid and an exception will be raised:

```
irb> Customer.find_or_create_by!(first_name: 'Andy')
ActiveRecord::RecordInvalid: Validation failed: Orders count can't be blank
```

### 18.3. find_or_initialize_by

The find_or_initialize_by method will work just like
find_or_create_by but it will call new instead of create. This
means that a new model instance will be created in memory but won't be
saved to the database. Continuing with the find_or_create_by example, we
now want the customer named 'Nina':

```
irb> nina = Customer.find_or_initialize_by(first_name: 'Nina')
=> #<Customer id: nil, first_name: "Nina", orders_count: 0, locked: true, created_at: "2011-08-30 06:09:27", updated_at: "2011-08-30 06:09:27">

irb> nina.persisted?
=> false

irb> nina.new_record?
=> true
```

Because the object is not yet stored in the database, the SQL generated looks like this:

```sql
SELECT * FROM customers WHERE (customers.first_name = 'Nina') LIMIT 1
```

When you want to save it to the database, just call save:

```
irb> nina.save
=> true
```

## 19. Finding by SQL

If you'd like to use your own SQL to find records in a table you can use find_by_sql. The find_by_sql method will return an array of objects even if the underlying query returns just a single record. For example, you could run this query:

```
irb> Customer.find_by_sql("SELECT * FROM customers INNER JOIN orders ON customers.id = orders.customer_id ORDER BY customers.created_at desc")
=> [#<Customer id: 1, first_name: "Lucas" ...>, #<Customer id: 2, first_name: "Jan" ...>, ...]
```

find_by_sql provides you with a simple way of making custom calls to the database and retrieving instantiated objects.

### 19.1. select_all

find_by_sql has a close relative called lease_connection.select_all. select_all will retrieve
objects from the database using custom SQL just like find_by_sql but will not instantiate them.
This method will return an instance of ActiveRecord::Result class and calling to_a on this
object would return you an array of hashes where each hash indicates a record.

```
irb> Customer.lease_connection.select_all("SELECT first_name, created_at FROM customers WHERE id = '1'").to_a
=> [{"first_name"=>"Rafael", "created_at"=>"2012-11-10 23:23:45.281189"}, {"first_name"=>"Eileen", "created_at"=>"2013-12-09 11:22:35.221282"}]
```

### 19.2. pluck

pluck can be used to pick the value(s) from the named column(s) in the current relation. It accepts a list of column names as an argument and returns an array of values of the specified columns with the corresponding data type.

```
irb> Book.where(out_of_print: true).pluck(:id)
SELECT id FROM books WHERE out_of_print = true
=> [1, 2, 3]

irb> Order.distinct.pluck(:status)
SELECT DISTINCT status FROM orders
=> ["shipped", "being_packed", "cancelled"]

irb> Customer.pluck(:id, :first_name)
SELECT customers.id, customers.first_name FROM customers
=> [[1, "David"], [2, "Fran"], [3, "Jose"]]
```

pluck makes it possible to replace code like:

```ruby
Customer.select(:id).map { |c| c.id }
# or
Customer.select(:id).map(&:id)
# or
Customer.select(:id, :first_name).map { |c| [c.id, c.first_name] }
```

with:

```ruby
Customer.pluck(:id)
# or
Customer.pluck(:id, :first_name)
```

Unlike select, pluck directly converts a database result into a Ruby Array,
without constructing ActiveRecord objects. This can mean better performance for
a large or frequently-run query. However, any model method overrides will
not be available. For example:

```ruby
class Customer < ApplicationRecord
  def name
    "I am #{first_name}"
  end
end
```

```
irb> Customer.select(:first_name).map &:name
=> ["I am David", "I am Jeremy", "I am Jose"]

irb> Customer.pluck(:first_name)
=> ["David", "Jeremy", "Jose"]
```

You are not limited to querying fields from a single table, you can query multiple tables as well.

```
irb> Order.joins(:customer, :books).pluck("orders.created_at, customers.email, books.title")
```

Furthermore, unlike select and other Relation scopes, pluck triggers an immediate
query, and thus cannot be chained with any further scopes, although it can work with
scopes already constructed earlier:

```
irb> Customer.pluck(:first_name).limit(1)
NoMethodError: undefined method `limit' for #<Array:0x007ff34d3ad6d8>

irb> Customer.limit(1).pluck(:first_name)
=> ["David"]
```

You should also know that using pluck will trigger eager loading if the relation object contains include values, even if the eager loading is not necessary for the query. For example:

```
irb> assoc = Customer.includes(:reviews)
irb> assoc.pluck(:id)
SELECT "customers"."id" FROM "customers" LEFT OUTER JOIN "reviews" ON "reviews"."id" = "customers"."review_id"
```

One way to avoid this is to unscope the includes:

```
irb> assoc.unscope(:includes).pluck(:id)
```

### 19.3. pick

pick can be used to pick the value(s) from the named column(s) in the current relation. It accepts a list of column names as an argument and returns the first row of the specified column values ​​with corresponding data type.
pick is a short-hand for relation.limit(1).pluck(*column_names).first, which is primarily useful when you already have a relation that is limited to one row.

pick makes it possible to replace code like:

```ruby
Customer.where(id: 1).pluck(:id).first
```

with:

```ruby
Customer.where(id: 1).pick(:id)
```

### 19.4. ids

ids can be used to pluck all the IDs for the relation using the table's primary key.

```
irb> Customer.ids
SELECT id FROM customers
```

```ruby
class Customer < ApplicationRecord
  self.primary_key = "customer_id"
end
```

```
irb> Customer.ids
SELECT customer_id FROM customers
```

## 20. Existence of Objects

If you simply want to check for the existence of the object there's a method called exists?.
This method will query the database using the same query as find, but instead of returning an
object or collection of objects it will return either true or false.

```ruby
Customer.exists?(1)
```

The exists? method also takes multiple values, but the catch is that it will return true if any
one of those records exists.

```ruby
Customer.exists?(id: [1, 2, 3])
# or
Customer.exists?(first_name: ["Jane", "Sergei"])
```

It's even possible to use exists? without any arguments on a model or a relation.

```ruby
Customer.where(first_name: "Ryan").exists?
```

The above returns true if there is at least one customer with the first_name 'Ryan' and false
otherwise.

```ruby
Customer.exists?
```

The above returns false if the customers table is empty and true otherwise.

You can also use any? and many? to check for existence on a model or relation.  many? will use SQL count to determine if the item exists.

```ruby
# via a model
Order.any?
# SELECT 1 FROM orders LIMIT 1
Order.many?
# SELECT COUNT(*) FROM (SELECT 1 FROM orders LIMIT 2)

# via a named scope
Order.shipped.any?
# SELECT 1 FROM orders WHERE orders.status = 0 LIMIT 1
Order.shipped.many?
# SELECT COUNT(*) FROM (SELECT 1 FROM orders WHERE orders.status = 0 LIMIT 2)

# via a relation
Book.where(out_of_print: true).any?
Book.where(out_of_print: true).many?

# via an association
Customer.first.orders.any?
Customer.first.orders.many?
```

## 21. Calculations

This section uses count as an example method in this preamble, but the options described apply to all sub-sections.

All calculation methods work directly on a model:

```
irb> Customer.count
SELECT COUNT(*) FROM customers
```

Or on a relation:

```
irb> Customer.where(first_name: 'Ryan').count
SELECT COUNT(*) FROM customers WHERE (first_name = 'Ryan')
```

You can also use various finder methods on a relation for performing complex calculations:

```
irb> Customer.includes("orders").where(first_name: 'Ryan', orders: { status: 'shipped' }).count
```

Which will execute:

```sql
SELECT COUNT(DISTINCT customers.id) FROM customers
  LEFT OUTER JOIN orders ON orders.customer_id = customers.id
  WHERE (customers.first_name = 'Ryan' AND orders.status = 0)
```

assuming that Order has enum status: [ :shipped, :being_packed, :cancelled ].

### 21.1. count

If you want to see how many records are in your model's table you could call Customer.count and that will return the number.
If you want to be more specific and find all the customers with a title present in the database you can use Customer.count(:title).

For options, please see the parent section, Calculations.

### 21.2. average

If you want to see the average of a certain number in one of your tables you can call the average method on the class that relates to the table. This method call will look something like this:

```ruby
Order.average("subtotal")
```

This will return a number (possibly a floating-point number such as 3.14159265) representing the average value in the field.

For options, please see the parent section, Calculations.

### 21.3. minimum

If you want to find the minimum value of a field in your table you can call the minimum method on the class that relates to the table. This method call will look something like this:

```ruby
Order.minimum("subtotal")
```

For options, please see the parent section, Calculations.

### 21.4. maximum

If you want to find the maximum value of a field in your table you can call the maximum method on the class that relates to the table. This method call will look something like this:

```ruby
Order.maximum("subtotal")
```

For options, please see the parent section, Calculations.

### 21.5. sum

If you want to find the sum of a field for all records in your table you can call the sum method on the class that relates to the table. This method call will look something like this:

```ruby
Order.sum("subtotal")
```

For options, please see the parent section, Calculations.

## 22. Running EXPLAIN

You can run explain on a relation. EXPLAIN output varies for each database.

For example, running:

```ruby
Customer.where(id: 1).joins(:orders).explain
```

may yield this for MySQL and MariaDB:

```sql
EXPLAIN SELECT `customers`.* FROM `customers` INNER JOIN `orders` ON `orders`.`customer_id` = `customers`.`id` WHERE `customers`.`id` = 1
+----+-------------+------------+-------+---------------+
| id | select_type | table      | type  | possible_keys |
+----+-------------+------------+-------+---------------+
|  1 | SIMPLE      | customers  | const | PRIMARY       |
|  1 | SIMPLE      | orders     | ALL   | NULL          |
+----+-------------+------------+-------+---------------+
+---------+---------+-------+------+-------------+
| key     | key_len | ref   | rows | Extra       |
+---------+---------+-------+------+-------------+
| PRIMARY | 4       | const |    1 |             |
| NULL    | NULL    | NULL  |    1 | Using where |
+---------+---------+-------+------+-------------+

2 rows in set (0.00 sec)
```

Active Record performs pretty printing that emulates the output of
the corresponding database shell. So, the same query run with the
PostgreSQL adapter would instead yield:

```sql
EXPLAIN SELECT "customers".* FROM "customers" INNER JOIN "orders" ON "orders"."customer_id" = "customers"."id" WHERE "customers"."id" = $1 [["id", 1]]
                                  QUERY PLAN
------------------------------------------------------------------------------
 Nested Loop  (cost=4.33..20.85 rows=4 width=164)
    ->  Index Scan using customers_pkey on customers  (cost=0.15..8.17 rows=1 width=164)
          Index Cond: (id = '1'::bigint)
    ->  Bitmap Heap Scan on orders  (cost=4.18..12.64 rows=4 width=8)
          Recheck Cond: (customer_id = '1'::bigint)
          ->  Bitmap Index Scan on index_orders_on_customer_id  (cost=0.00..4.18 rows=4 width=0)
                Index Cond: (customer_id = '1'::bigint)
(7 rows)
```

Eager loading may trigger more than one query under the hood, and some queries
may need the results of previous ones. Because of that, explain actually
executes the query, and then asks for the query plans. For example, running:

```ruby
Customer.where(id: 1).includes(:orders).explain
```

may yield this for MySQL and MariaDB:

```sql
EXPLAIN SELECT `customers`.* FROM `customers`  WHERE `customers`.`id` = 1
+----+-------------+-----------+-------+---------------+
| id | select_type | table     | type  | possible_keys |
+----+-------------+-----------+-------+---------------+
|  1 | SIMPLE      | customers | const | PRIMARY       |
+----+-------------+-----------+-------+---------------+
+---------+---------+-------+------+-------+
| key     | key_len | ref   | rows | Extra |
+---------+---------+-------+------+-------+
| PRIMARY | 4       | const |    1 |       |
+---------+---------+-------+------+-------+

1 row in set (0.00 sec)

EXPLAIN SELECT `orders`.* FROM `orders`  WHERE `orders`.`customer_id` IN (1)
+----+-------------+--------+------+---------------+
| id | select_type | table  | type | possible_keys |
+----+-------------+--------+------+---------------+
|  1 | SIMPLE      | orders | ALL  | NULL          |
+----+-------------+--------+------+---------------+
+------+---------+------+------+-------------+
| key  | key_len | ref  | rows | Extra       |
+------+---------+------+------+-------------+
| NULL | NULL    | NULL |    1 | Using where |
+------+---------+------+------+-------------+


1 row in set (0.00 sec)
```

and may yield this for PostgreSQL:

```sql
Customer Load (0.3ms)  SELECT "customers".* FROM "customers" WHERE "customers"."id" = $1  [["id", 1]]
  Order Load (0.3ms)  SELECT "orders".* FROM "orders" WHERE "orders"."customer_id" = $1  [["customer_id", 1]]
=> EXPLAIN SELECT "customers".* FROM "customers" WHERE "customers"."id" = $1 [["id", 1]]
                                    QUERY PLAN
----------------------------------------------------------------------------------
 Index Scan using customers_pkey on customers  (cost=0.15..8.17 rows=1 width=164)
   Index Cond: (id = '1'::bigint)
(2 rows)
```

### 22.1. Explain Options

For databases and adapters which support them (currently PostgreSQL, MySQL, and MariaDB), options can be passed to provide deeper analysis.

Using PostgreSQL, the following:

```ruby
Customer.where(id: 1).joins(:orders).explain(:analyze, :verbose)
```

yields:

```sql
EXPLAIN (ANALYZE, VERBOSE) SELECT "shop_accounts".* FROM "shop_accounts" INNER JOIN "customers" ON "customers"."id" = "shop_accounts"."customer_id" WHERE "shop_accounts"."id" = $1 [["id", 1]]
                                                                   QUERY PLAN
------------------------------------------------------------------------------------------------------------------------------------------------
 Nested Loop  (cost=0.30..16.37 rows=1 width=24) (actual time=0.003..0.004 rows=0 loops=1)
   Output: shop_accounts.id, shop_accounts.customer_id, shop_accounts.customer_carrier_id
   Inner Unique: true
   ->  Index Scan using shop_accounts_pkey on public.shop_accounts  (cost=0.15..8.17 rows=1 width=24) (actual time=0.003..0.003 rows=0 loops=1)
         Output: shop_accounts.id, shop_accounts.customer_id, shop_accounts.customer_carrier_id
         Index Cond: (shop_accounts.id = '1'::bigint)
   ->  Index Only Scan using customers_pkey on public.customers  (cost=0.15..8.17 rows=1 width=8) (never executed)
         Output: customers.id
         Index Cond: (customers.id = shop_accounts.customer_id)
         Heap Fetches: 0
 Planning Time: 0.063 ms
 Execution Time: 0.011 ms
(12 rows)
```

Using MySQL or MariaDB, the following:

```ruby
Customer.where(id: 1).joins(:orders).explain(:analyze)
```

yields:

```sql
ANALYZE SELECT `shop_accounts`.* FROM `shop_accounts` INNER JOIN `customers` ON `customers`.`id` = `shop_accounts`.`customer_id` WHERE `shop_accounts`.`id` = 1
+----+-------------+-------+------+---------------+------+---------+------+------+--------+----------+------------+--------------------------------+
| id | select_type | table | type | possible_keys | key  | key_len | ref  | rows | r_rows | filtered | r_filtered | Extra                          |
+----+-------------+-------+------+---------------+------+---------+------+------+--------+----------+------------+--------------------------------+
|  1 | SIMPLE      | NULL  | NULL | NULL          | NULL | NULL    | NULL | NULL | NULL   | NULL     | NULL       | no matching row in const table |
+----+-------------+-------+------+---------------+------+---------+------+------+--------+----------+------------+--------------------------------+
1 row in set (0.00 sec)
```

EXPLAIN and ANALYZE options vary across MySQL and MariaDB versions.
(MySQL 5.7, MySQL 8.0, MariaDB)

### 22.2. Interpreting EXPLAIN

Interpretation of the output of EXPLAIN is beyond the scope of this guide. The
following pointers may be helpful:

- SQLite3: EXPLAIN QUERY PLAN

- MySQL: EXPLAIN Output Format

- MariaDB: EXPLAIN

- PostgreSQL: Using EXPLAIN

SQLite3: EXPLAIN QUERY PLAN

MySQL: EXPLAIN Output Format

MariaDB: EXPLAIN

PostgreSQL: Using EXPLAIN

---

# Chapters

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

This guide covers the association features of Active Record.

After reading this guide, you will know how to:

- Understand the various types of associations.

- Declare associations between Active Record models.

- Choose the right association type for your models.

- Use Single Table Inheritance.

- Setting up and using Delegated Types.

## 1. Associations Overview

Active Record associations allow you to define relationships between models.
Associations are implemented as special macro style calls that make it easy to
tell Rails how your models relate to each other, which helps you manage your
data more effectively, and makes common operations simpler and easier to read.

A macro-style call is a method that generates or modifies other methods at
runtime, allowing for concise and expressive declarations of functionality, such
as defining model associations in Rails. For example, has_many :comments.

When you set up an association, Rails helps define and manage the Primary
Key and Foreign
Key relationships between instances
of the two models, while the database ensures that your data stays consistent
and properly linked.

This makes it easy to keep track of which records are related. It also adds
useful methods to your models so you can work with related data more easily.

Consider a simple Rails application with models for authors and books.

### 1.1. Without Associations

Without associations, creating and deleting books for that author would require
a tedious and manual process. Here's what that would look like:

```ruby
class CreateAuthors < ActiveRecord::Migration[8.1]
  def change
    create_table :authors do |t|
      t.string :name
      t.timestamps
    end

    create_table :books do |t|
      t.references :author
      t.datetime :published_at
      t.timestamps
    end
  end
end
```

```ruby
class Author < ApplicationRecord
end

class Book < ApplicationRecord
end
```

To add a new book for an existing author, you'd need to provide the author_id
value when creating the book.

```ruby
@book = Book.create(author_id: @author.id, published_at: Time.now)
```

To delete an author and ensure all their books are also deleted, you'd need to
retrieve all the author's books, loop through each book to destroy it, and
then destroy the author.

```ruby
@books = Book.where(author_id: @author.id)
@books.each do |book|
  book.destroy
end
@author.destroy
```

### 1.2. Using Associations

However, with associations, we can streamline these operations, as well as
others, by explicitly informing Rails about the relationship between the two
models. Here's the revised code for setting up authors and books using
associations:

```ruby
class Author < ApplicationRecord
  has_many :books, dependent: :destroy
end

class Book < ApplicationRecord
  belongs_to :author
end
```

With this change, creating a new book for a particular author is simpler:

```ruby
@book = @author.books.create(published_at: Time.now)
```

Deleting an author and all of its books is much easier:

```ruby
@author.destroy
```

When you set up an association in Rails, you still need to create a
migration to ensure that the database is
properly configured to handle the association. This migration will need to add
the necessary foreign key columns to your database tables.

For example, if you set up a belongs_to :author association in the Book
model, you would create a migration to add the author_id column to the books
table:

```bash
rails generate migration AddAuthorToBooks author:references
```

This migration will add the author_id column and set up the foreign key
relationship in the database, ensuring that your models and database stay in
sync.

To learn more about the different types of associations, you can read the next
section of this guide. Following that, you'll find some tips and tricks for
working with associations. Finally, there's a complete reference to the methods
and options for associations in Rails.

## 2. Types of Associations

Rails supports six types of associations, each with a particular use-case in
mind.

Here is a list of all of the supported types with a link to their API docs for
more detailed information on how to use them, their method parameters, etc.

- belongs_to

- has_one

- has_many

- has_many :through

- has_one :through

- has_and_belongs_to_many

In the remainder of this guide, you'll learn how to declare and use the various
forms of associations. First, let's take a quick look at the situations where
each association type is appropriate.

### 2.1. belongs_to

A belongs_to association sets up a relationship with another model, such
that each instance of the declaring model "belongs to" one instance of the other
model. For example, if your application includes authors and books, and each
book can be assigned to exactly one author, you'd declare the book model this
way:

```ruby
class Book < ApplicationRecord
  belongs_to :author
end
```

A belongs_to association must use the singular term. If you use the
plural form, like belongs_to :authors in the Book model, and try to create a
book with Book.create(authors: @author), Rails will give you an "uninitialized
constant Book::Authors" error. This happens because Rails automatically infers
the class name from the association name. If the association name is :authors,
Rails will look for a class named Authors instead of Author.

The corresponding migration might look like this:

```ruby
class CreateBooks < ActiveRecord::Migration[8.1]
  def change
    create_table :authors do |t|
      t.string :name
      t.timestamps
    end

    create_table :books do |t|
      t.belongs_to :author
      t.datetime :published_at
      t.timestamps
    end
  end
end
```

In database terms, the belongs_to association says that this model's table
contains a column which represents a reference to another table. This can be
used to set up one-to-one or one-to-many relations, depending on the setup. If
the table of the other class contains the reference in a one-to-one relation,
then you should use has_one instead.

When used alone, belongs_to produces a one-directional one-to-one
relationship. Therefore each book in the above example "knows" its author, but
the authors don't know about their books. To set up a bi-directional
association - use belongs_to in combination
with a has_one or has_many on the other model, in this case the Author
model.

By default belongs_to validates the presence of the associated record to
guarantee reference consistency.If optional is set to true in the
model, then belongs_to does not guarantee reference consistency. This means
that the foreign key in one table might not reliably point to a valid primary
key in the referenced table.

```ruby
class Book < ApplicationRecord
  belongs_to :author, optional: true
end
```

Hence, depending on the use case, you might also need to add a database-level
foreign key constraint on the reference column, like this:

```ruby
create_table :books do |t|
  t.belongs_to :author, foreign_key: true
  # ...
end
```

This ensures that even though optional: true allows author_id to be NULL,
when it's not NULL, it must still reference a valid record in the authors table.

#### 2.1.1. Methods Added by belongs_to

When you declare a belongs_to association, the declaring class automatically
gains numerous methods related to the association. Some of these are:

- association=(associate)

- build_association(attributes = {})

- create_association(attributes = {})

- create_association!(attributes = {})

- reload_association

- reset_association

- association_changed?

- association_previously_changed?

We'll discuss some of the common methods, but you can find an exhaustive list in
the ActiveRecord Associations
API.

In all of the above methods, association is replaced with the symbol passed as
the first argument to belongs_to. For example, given the declaration:

```ruby
# app/models/book.rb
class Book < ApplicationRecord
  belongs_to :author
end

# app/models/author.rb
class Author < ApplicationRecord
  has_many :books
  validates :name, presence: true
end
```

An instance of the Book model will have the following methods:

- author

- author=

- build_author

- create_author

- create_author!

- reload_author

- reset_author

- author_changed?

- author_previously_changed?

When initializing a new has_one or belongs_to association you must use
the build_prefix to build the association, rather than the
association.build method that would be used for has_many or
has_and_belongs_to_many associations. To create one, use the create_ prefix.

The association method returns the associated object, if any. If no associated
object is found, it returns nil.

```ruby
@author = @book.author
```

If the associated object has already been retrieved from the database for this
object, the cached version will be returned. To override this behavior (and
force a database read), call #reload_association on the parent object.

```ruby
@author = @book.reload_author
```

To unload the cached version of the associated object—causing the next access,
if any, to query it from the database—call #reset_association on the parent
object.

```ruby
@book.reset_author
```

The association= method assigns an associated object to this object. Behind
the scenes, this means extracting the primary key from the associated object and
setting this object's foreign key to the same value.

```ruby
@book.author = @author
```

The build_association method returns a new object of the associated type. This
object will be instantiated from the passed attributes, and the link through
this object's foreign key will be set, but the associated object will not yet
be saved.

```ruby
@author = @book.build_author(author_number: 123,
                             author_name: "John Doe")
```

The create_association method takes it a step further and also saves the
associated object once it passes all of the validations specified on the
associated model.

```ruby
@author = @book.create_author(author_number: 123,
                              author_name: "John Doe")
```

Finally, create_association! does the same, but raises
ActiveRecord::RecordInvalid if the record is invalid.

```ruby
# This will raise ActiveRecord::RecordInvalid because the name is blank
begin
  @book.create_author!(author_number: 123, name: "")
rescue ActiveRecord::RecordInvalid => e
  puts e.message
end
```

```
irb> raise_validation_error: Validation failed: Name can't be blank (ActiveRecord::RecordInvalid)
```

The association_changed? method returns true if a new associated object has
been assigned and the foreign key will be updated in the next save.

The association_previously_changed? method returns true if the previous save
updated the association to reference a new associate object.

```ruby
@book.author # => #<Author author_number: 123, author_name: "John Doe">
@book.author_changed? # => false
@book.author_previously_changed? # => false

@book.author = Author.second # => #<Author author_number: 456, author_name: "Jane Smith">
@book.author_changed? # => true

@book.save!
@book.author_changed? # => false
@book.author_previously_changed? # => true
```

Do not confuse model.association_changed? with
model.association.changed?. The former checks if the association has been
replaced with a new record, while the latter tracks changes to the attributes of
the association.

You can see if any associated objects exist by using the association.nil?
method:

```ruby
if @book.author.nil?
  @msg = "No author found for this book"
end
```

Assigning an object to a belongs_to association does not automatically save
either the current object or the associated object. However, when you save the
current object, the association is saved as well.

### 2.2. has_one

A has_one association indicates that one other model has a reference to
this model. That model can be fetched through this association.

For example, if each supplier in your application has only one account, you'd
declare the supplier model like this:

```ruby
class Supplier < ApplicationRecord
  has_one :account
end
```

The main difference from belongs_to is that the link column (in this case
supplier_id) is located in the other table, not the table where the has_one
is declared.

The corresponding migration might look like this:

```ruby
class CreateSuppliers < ActiveRecord::Migration[8.1]
  def change
    create_table :suppliers do |t|
      t.string :name
      t.timestamps
    end

    create_table :accounts do |t|
      t.belongs_to :supplier
      t.string :account_number
      t.timestamps
    end
  end
end
```

The has_one association creates a one-to-one match with another model. In
database terms, this association says that the other class contains the foreign
key. If this class contains the foreign key, then you should use belongs_to
instead.

Depending on the use case, you might also need to create a unique index and/or a
foreign key constraint on the supplier column for the accounts table. The unique
index ensures that each supplier is associated with only one account and allows
you to query in an efficient manner, while the foreign key constraint ensures
that the supplier_id in the accounts table refers to a valid supplier in
the suppliers table. This enforces the association at the database level.

```ruby
create_table :accounts do |t|
  t.belongs_to :supplier, index: { unique: true }, foreign_key: true
  # ...
end
```

This relation can be bi-directional when used in
combination with belongs_to on the other model.

#### 2.2.1. Methods Added by

has_one

When you declare a has_one association,  the declaring class automatically
gains numerous methods related to the association. Some of these are:

- association

- association=(associate)

- build_association(attributes = {})

- create_association(attributes = {})

- create_association!(attributes = {})

- reload_association

- reset_association

We'll discuss some of the common methods, but you can find an exhaustive list in
the ActiveRecord Associations
API.

Like with the belongs_to references, in all of
these methods, association is replaced with the symbol passed as the first
argument to has_one. For example, given the declaration:

```ruby
# app/models/supplier.rb
class Supplier < ApplicationRecord
  has_one :account
end

# app/models/account.rb
class Account < ApplicationRecord
  validates :terms, presence: true
  belongs_to :supplier
end
```

Each instance of the Supplier model will have these methods:

- account

- account=

- build_account

- create_account

- create_account!

- reload_account

- reset_account

When initializing a new has_one or belongs_to association you must use
the build_prefix to build the association, rather than the
association.build method that would be used for has_many or
has_and_belongs_to_many associations. To create one, use the create_ prefix.

The association method returns the associated object, if any. If no associated
object is found, it returns nil.

```ruby
@account = @supplier.account
```

If the associated object has already been retrieved from the database for this
object, the cached version will be returned. To override this behavior (and
force a database read), call #reload_association on the parent object.

```ruby
@account = @supplier.reload_account
```

To unload the cached version of the associated object—forcing the next access,
if any, to query it from the database—call #reset_association on the parent
object.

```ruby
@supplier.reset_account
```

The association= method assigns an associated object to this object. Behind
the scenes, this means extracting the primary key from this object and setting
the associated object's foreign key to the same value.

```ruby
@supplier.account = @account
```

The build_association method returns a new object of the associated type. This
object will be instantiated from the passed attributes, and the link through
this object's foreign key will be set, but the associated object will not yet
be saved.

```ruby
@account = @supplier.build_account(terms: "Net 30")
```

The create_association method takes it a step further and also saves the
associated object once it passes all of the validations specified on the
associated model.

```ruby
@account = @supplier.create_account(terms: "Net 30")
```

Finally, create_association! does the same as create_association above,
but raises ActiveRecord::RecordInvalid if the record is invalid.

```ruby
# This will raise ActiveRecord::RecordInvalid because the terms is blank
begin
  @supplier.create_account!(terms: "")
rescue ActiveRecord::RecordInvalid => e
  puts e.message
end
```

```
irb> raise_validation_error: Validation failed: Terms can't be blank (ActiveRecord::RecordInvalid)
```

You can see if any associated objects exist by using the association.nil?
method:

```ruby
if @supplier.account.nil?
  @msg = "No account found for this supplier"
end
```

When you assign an object to a has_one association, that object is
automatically saved to update its foreign key. Additionally, any object being
replaced is also automatically saved, as its foreign key will change too.

If either of these saves fails due to validation errors, the assignment
statement returns false, and the assignment itself is canceled.

If the parent object (the one declaring the has_one association) is unsaved
(that is, new_record? returns true) then the child objects are not saved
immediately. They will be automatically saved when the parent object is saved.

If you want to assign an object to a has_one association without saving the
object, use the build_association method. This method creates a new, unsaved
instance of the associated object, allowing you to work with it before deciding
to save it.

Use autosave: false when you want to control the saving behavior of the
associated objects for the model. This setting prevents the associated object
from being saved automatically when the parent object is saved. In contrast, use
build_association when you need to work with an unsaved associated object and
delay its persistence until you're ready.

### 2.3. has_many

A has_many association is similar to has_one, but indicates a
one-to-many relationship with another model. You'll often find this association
on the "other side" of a belongs_to association. This association indicates
that each instance of the model has zero or more instances of another model. For
example, in an application containing authors and books, the author model could
be declared like this:

```ruby
class Author < ApplicationRecord
  has_many :books
end
```

has_many establishes a one-to-many relationship between models, allowing each
instance of the declaring model (Author) to have multiple instances of the
associated model (Book).

Unlike a has_one and belongs_to association, the name of the other
model is pluralized when declaring a has_many association.

The corresponding migration might look like this:

```ruby
class CreateAuthors < ActiveRecord::Migration[8.1]
  def change
    create_table :authors do |t|
      t.string :name
      t.timestamps
    end

    create_table :books do |t|
      t.belongs_to :author
      t.datetime :published_at
      t.timestamps
    end
  end
end
```

The has_many association creates a one-to-many relationship with another
model. In database terms, this association says that the other class will have a
foreign key that refers to instances of this class.

In this migration, the authors table is created with a name column to store
the names of authors. The books table is also created, and it includes a
belongs_to :author association. This association establishes a foreign key
relationship between the books and authors tables. Specifically, the
author_id column in the books table acts as a foreign key, referencing the
id column in the authors table. By including this belongs_to :author
association in the books table, we ensure that each book is associated with a
single author, enabling a has_many association from the Author model. This
setup allows each author to have multiple associated books.

Depending on the use case, it's usually a good idea to create a non-unique index
and optionally a foreign key constraint on the author column for the books
table. Adding an index on the author_id column improves query performance when
retrieving books associated with a specific author.

If you wish to enforce referential
integrity at the database
level, add the foreign_key: true
option to the reference column declarations above. This will ensure that the
author_id in the books table must correspond to a valid id in the authors
table,

```ruby
create_table :books do |t|
  t.belongs_to :author, index: true, foreign_key: true
  # ...
end
```

This relation can be bi-directional when used in
combination with belongs_to on the other model.

#### 2.3.1. Methods Added by has_many

When you declare a has_many association, the declaring class gains numerous
methods related to the association. Some of these are:

- collection

- collection<<(object, ...)

- collection.delete(object, ...)

- collection.destroy(object, ...)

- collection=(objects)

- collection_singular_ids

- collection_singular_ids=(ids)

- collection.clear

- collection.empty?

- collection.size

- collection.find(...)

- collection.where(...)

- collection.exists?(...)

- collection.build(attributes = {})

- collection.create(attributes = {})

- collection.create!(attributes = {})

- collection.reload

We'll discuss some of the common methods, but you can find an exhaustive list in
the ActiveRecord Associations
API.

In all of these methods, collection is replaced with the symbol passed as the
first argument to has_many, and collection_singular is replaced with the
singularized version of that symbol. For example, given the declaration:

```ruby
class Author < ApplicationRecord
  has_many :books
end
```

An instance of the Author model can have the following methods:

```
books
books<<(object, ...)
books.delete(object, ...)
books.destroy(object, ...)
books=(objects)
book_ids
book_ids=(ids)
books.clear
books.empty?
books.size
books.find(...)
books.where(...)
books.exists?(...)
books.build(attributes = {}, ...)
books.create(attributes = {})
books.create!(attributes = {})
books.reload
```

The collection method returns a Relation of all of the associated objects. If
there are no associated objects, it returns an empty Relation.

```ruby
@books = @author.books
```

The collection.delete method removes one or more objects from the
collection by setting their foreign keys to NULL.

```ruby
@author.books.delete(@book1)
```

Additionally, objects will be destroyed if they're associated with
dependent: :destroy, and deleted if they're associated with dependent:
:delete_all.

The collection.destroy method removes one or more objects from the
collection by running destroy on each object.

```ruby
@author.books.destroy(@book1)
```

Objects will always be removed from the database, ignoring the
:dependent option.

The collection.clear method removes all objects from the collection
according to the strategy specified by the dependent option. If no option is
given, it follows the default strategy. The default strategy for has_many
:through associations is delete_all, and for has_many associations is to
set the foreign keys to NULL.

```ruby
@author.books.clear
```

Objects will be deleted if they're associated with dependent:
:destroy or dependent: :destroy_async, just like dependent: :delete_all.

The collection.reload method returns a Relation of all of the associated
objects, forcing a database read. If there are no associated objects, it returns
an empty Relation.

```ruby
@books = @author.books.reload
```

The collection=(objects) method makes the collection contain only the supplied
objects, by adding and deleting as appropriate. The changes are persisted to the
database.

The collection_singular_ids=(ids) method makes the collection contain only the
objects identified by the supplied primary key values, by adding and deleting as
appropriate. The changes are persisted to the database.

The collection_singular_ids method returns an array of the ids of the objects
in the collection.

```ruby
@book_ids = @author.book_ids
```

The collection.empty? method returns true if the collection does not
contain any associated objects.

```ruby
<% if @author.books.empty? %>
  No Books Found
<% end %>
```

The collection.size method returns the number of objects in the
collection.

```ruby
@book_count = @author.books.size
```

The collection.find method finds objects within the collection's table.

```ruby
@available_book = @author.books.find(1)
```

The collection.where method finds objects within the collection based on
the conditions supplied but the objects are loaded lazily meaning that the
database is queried only when the object(s) are accessed.

```ruby
@available_books = @author.books.where(available: true) # No query yet
@available_book = @available_books.first # Now the database will be queried
```

The collection.exists? method checks whether an object meeting the
supplied conditions exists in the collection's table.

The collection.build method returns a single or array of new objects of
the associated type. The object(s) will be instantiated from the passed
attributes, and the link through their foreign key will be created, but the
associated objects will not yet be saved.

```ruby
@book = @author.books.build(published_at: Time.now,
                            book_number: "A12345")

@books = @author.books.build([
  { published_at: Time.now, book_number: "A12346" },
  { published_at: Time.now, book_number: "A12347" }
])
```

The collection.create method returns a single or array of new objects of
the associated type. The object(s) will be instantiated from the passed
attributes, the link through its foreign key will be created, and, once it
passes all of the validations specified on the associated model, the associated
object will be saved.

```ruby
@book = @author.books.create(published_at: Time.now,
                             book_number: "A12345")

@books = @author.books.create([
  { published_at: Time.now, book_number: "A12346" },
  { published_at: Time.now, book_number: "A12347" }
])
```

collection.create! does the same as collection.create, but raises
ActiveRecord::RecordInvalid if the record is invalid.

When you assign an object to a has_many association, that object is
automatically saved (in order to update its foreign key). If you assign multiple
objects in one statement, then they are all saved.

If any of these saves fails due to validation errors, then the assignment
statement returns false and the assignment itself is cancelled.

If the parent object (the one declaring the has_many association) is unsaved
(that is, new_record? returns true) then the child objects are not saved
when they are added. All unsaved members of the association will automatically
be saved when the parent is saved.

If you want to assign an object to a has_many association without saving the
object, use the collection.build method.

### 2.4. has_many :through

A has_many :through association is often used to set up a
many-to-many relationship with another model. This association indicates that
the declaring model can be matched with zero or more instances of another model
by proceeding through an intermediate "join" model.

For example, consider a medical practice where patients make appointments to see
physicians. The relevant association declarations could look like this:

```ruby
class Physician < ApplicationRecord
  has_many :appointments
  has_many :patients, through: :appointments
end

class Appointment < ApplicationRecord
  belongs_to :physician
  belongs_to :patient
end

class Patient < ApplicationRecord
  has_many :appointments
  has_many :physicians, through: :appointments
end
```

has_many :through establishes a many-to-many relationship between models,
allowing instances of one model (Physician) to be associated with multiple
instances of another model (Patient) through a third "join" model (Appointment).

We call Physician.appointments and Appointment.patient the through and
source associations of Physician.patients, respectively.

The corresponding migration might look like this:

```ruby
class CreateAppointments < ActiveRecord::Migration[8.1]
  def change
    create_table :physicians do |t|
      t.string :name
      t.timestamps
    end

    create_table :patients do |t|
      t.string :name
      t.timestamps
    end

    create_table :appointments do |t|
      t.belongs_to :physician
      t.belongs_to :patient
      t.datetime :appointment_date
      t.timestamps
    end
  end
end
```

In this migration the physicians and patients tables are created with a
name column. The appointments table, which acts as the join table, is
created with physician_id and patient_id columns, establishing the
many-to-many relationship between physicians and patients.

The through association can be any type of association, including other
through associations, but it cannot be polymorphic.
Source associations can be polymorphic as long as you provide a source type.

You could also consider using a composite primary
key for the join table in the
has_many :through relationship like below:

```ruby
class CreateAppointments < ActiveRecord::Migration[8.1]
  def change
    #  ...
    create_table :appointments, primary_key: [:physician_id, :patient_id] do |t|
      t.belongs_to :physician
      t.belongs_to :patient
      t.datetime :appointment_date
      t.timestamps
    end
  end
end
```

The collection of join models in a has_many :through association can be
managed using standard has_many association
methods. For example, if you assign a list of
patients to a physician like this:

```ruby
physician.patients = patients
```

Rails will automatically create new join models for any patients in the new list
that were not previously associated with the physician. Additionally, if any
patients that were previously associated with the physician are not included in
the new list, their join records will be automatically deleted. This simplifies
managing many-to-many relationships by handling the creation and deletion of the
join models for you.

Automatic deletion of join models is direct, no destroy callbacks are
triggered. You can read more about callbacks in the Active Record Callbacks
Guide.

The has_many :through association is also useful for setting up "shortcuts"
through nested has_many associations. This is particularly beneficial when you
need to access a collection of related records through an intermediary
association.

For example, if a document has many sections, and each section has many
paragraphs, you may sometimes want to get a simple collection of all paragraphs
in the document without having to manually traverse through each section.

You can set this up with a has_many :through association as follows:

```ruby
class Document < ApplicationRecord
  has_many :sections
  has_many :paragraphs, through: :sections
end

class Section < ApplicationRecord
  belongs_to :document
  has_many :paragraphs
end

class Paragraph < ApplicationRecord
  belongs_to :section
end
```

With through: :sections specified, Rails will now understand:

```ruby
@document.paragraphs
```

Whereas, if you had not set up a has_many :through association, you would have
needed to do something like this to get paragraphs in a document:

```ruby
paragraphs = []
@document.sections.each do |section|
  paragraphs.concat(section.paragraphs)
end
```

### 2.5. has_one :through

A has_one :through association sets up a one-to-one relationship
with another model through an intermediary model. This association indicates
that the declaring model can be matched with one instance of another model by
proceeding through a third model.

For example, if each supplier has one account, and each account is associated
with one account history, then the supplier model could look like this:

```ruby
class Supplier < ApplicationRecord
  has_one :account
  has_one :account_history, through: :account
end

class Account < ApplicationRecord
  belongs_to :supplier
  has_one :account_history
end

class AccountHistory < ApplicationRecord
  belongs_to :account
end
```

This setup allows a supplier to directly access its account_history through
its account.

We call Supplier.account and Account.account_history the through and
source associations of Supplier.account_history, respectively.

The corresponding migration to set up these associations might look like this:

```ruby
class CreateAccountHistories < ActiveRecord::Migration[8.1]
  def change
    create_table :suppliers do |t|
      t.string :name
      t.timestamps
    end

    create_table :accounts do |t|
      t.belongs_to :supplier
      t.string :account_number
      t.timestamps
    end

    create_table :account_histories do |t|
      t.belongs_to :account
      t.integer :credit_rating
      t.timestamps
    end
  end
end
```

The through association must be a has_one, has_one :through, or
non-polymorphic belongs_to. That is, a non-polymorphic singular association.
On the other hand, source associations can be polymorphic as long as you provide
a source type.

### 2.6. has_and_belongs_to_many

A has_and_belongs_to_many association creates a direct many-to-many
relationship with another model, with no intervening model. This association
indicates that each instance of the declaring model refers to zero or more
instances of another model.

For example, consider an application with Assembly and Part models, where
each assembly can contain many parts, and each part can be used in many
assemblies. You can set up the models as follows:

```ruby
class Assembly < ApplicationRecord
  has_and_belongs_to_many :parts
end

class Part < ApplicationRecord
  has_and_belongs_to_many :assemblies
end
```

Even though a has_and_belongs_to_many does not require an intervening model,
it does require a separate table to establish the many-to-many relationship
between the two models involved. This intervening table serves to store the
related data, mapping the associations between instances of the two models. The
table does not necessarily need a primary key since its purpose is solely to
manage the relationship between the associated records. The corresponding
migration might look like this:

```ruby
class CreateAssembliesAndParts < ActiveRecord::Migration[8.1]
  def change
    create_table :assemblies do |t|
      t.string :name
      t.timestamps
    end

    create_table :parts do |t|
      t.string :part_number
      t.timestamps
    end

    # Create a join table to establish the many-to-many relationship between assemblies and parts.
    # `id: false` indicates that the table does not need a primary key of its own
    create_table :assemblies_parts, id: false do |t|
      # creates foreign keys linking the join table to the `assemblies` and `parts` tables
      t.belongs_to :assembly
      t.belongs_to :part
    end
  end
end
```

The has_and_belongs_to_many association creates a many-to-many relationship
with another model. In database terms, this associates two classes via an
intermediate join table that includes foreign keys referring to each of the
classes.

If the join table for a has_and_belongs_to_many association has additional
columns beyond the two foreign keys, these columns will be added as attributes
to records retrieved via that association. Records returned with additional
attributes will always be read-only, because Rails cannot save changes to those
attributes.

The use of extra attributes on the join table in a
has_and_belongs_to_many association is deprecated. If you require this sort of
complex behavior on the table that joins two models in a many-to-many
relationship, you should use a has_many :through association instead of
has_and_belongs_to_many.

#### 2.6.1. Methods Added by has_and_belongs_to_many

When you declare a has_and_belongs_to_many association, the declaring class
gains numerous methods related to the association. Some of these are:

- collection

- collection<<(object, ...)

- collection.delete(object, ...)

- collection.destroy(object, ...)

- collection=(objects)

- collection_singular_ids

- collection_singular_ids=(ids)

- collection.clear

- collection.empty?

- collection.size

- collection.find(...)

- collection.where(...)

- collection.exists?(...)

- collection.build(attributes = {})

- collection.create(attributes = {})

- collection.create!(attributes = {})

- collection.reload

We'll discuss some of the common methods, but you can find an exhaustive list in
the ActiveRecord Associations
API.

In all of these methods, collection is replaced with the symbol passed as the
first argument to has_and_belongs_to_many, and collection_singular is
replaced with the singularized version of that symbol. For example, given the
declaration:

```ruby
class Part < ApplicationRecord
  has_and_belongs_to_many :assemblies
end
```

An instance of the Part model can have the following methods:

```
assemblies
assemblies<<(object, ...)
assemblies.delete(object, ...)
assemblies.destroy(object, ...)
assemblies=(objects)
assembly_ids
assembly_ids=(ids)
assemblies.clear
assemblies.empty?
assemblies.size
assemblies.find(...)
assemblies.where(...)
assemblies.exists?(...)
assemblies.build(attributes = {}, ...)
assemblies.create(attributes = {})
assemblies.create!(attributes = {})
assemblies.reload
```

The collection method returns a Relation of all of the associated objects. If
there are no associated objects, it returns an empty Relation.

```ruby
@assemblies = @part.assemblies
```

The collection<< method adds one or more objects to the collection by
creating records in the join table.

```ruby
@part.assemblies << @assembly1
```

This method is aliased as collection.concat and collection.push.

The collection.delete method removes one or more objects from the
collection by deleting records in the join table. This does not destroy the
objects.

```ruby
@part.assemblies.delete(@assembly1)
```

The collection.destroy method removes one or more objects from the
collection by deleting records in the join table. This does not destroy the
objects.

```ruby
@part.assemblies.destroy(@assembly1)
```

The collection.clear method removes every object from the collection by
deleting the rows from the joining table. This does not destroy the associated
objects.

The collection= method makes the collection contain only the supplied objects,
by adding and deleting as appropriate. The changes are persisted to the
database.

The collection_singular_ids= method makes the collection contain only the
objects identified by the supplied primary key values, by adding and deleting as
appropriate. The changes are persisted to the database.

The collection_singular_ids method returns an array of the ids of the objects
in the collection.

```ruby
@assembly_ids = @part.assembly_ids
```

The collection.empty? method returns true if the collection does not
contain any associated objects.

```ruby
<% if @part.assemblies.empty? %>
  This part is not used in any assemblies
<% end %>
```

The collection.size method returns the number of objects in the
collection.

```ruby
@assembly_count = @part.assemblies.size
```

The collection.find method finds objects within the collection's table.

```ruby
@assembly = @part.assemblies.find(1)
```

The collection.where method finds objects within the collection based on
the conditions supplied but the objects are loaded lazily meaning that the
database is queried only when the object(s) are accessed.

```ruby
@new_assemblies = @part.assemblies.where("created_at > ?", 2.days.ago)
```

The collection.exists? method checks whether an object meeting the
supplied conditions exists in the collection's table.

The collection.build method returns a new object of the associated type.
This object will be instantiated from the passed attributes, and the link
through the join table will be created, but the associated object will not yet
be saved.

```ruby
@assembly = @part.assemblies.build({ assembly_name: "Transmission housing" })
```

The collection.create method returns a new object of the associated type.
This object will be instantiated from the passed attributes, the link through
the join table will be created, and, once it passes all of the validations
specified on the associated model, the associated object will be saved.

```ruby
@assembly = @part.assemblies.create({ assembly_name: "Transmission housing" })
```

collection.create! does the same as collection.create, but raises
ActiveRecord::RecordInvalid if the record is invalid.

The collection.reload method returns a Relation of all of the associated
objects, forcing a database read. If there are no associated objects, it returns
an empty Relation.

```ruby
@assemblies = @part.assemblies.reload
```

When you assign an object to a has_and_belongs_to_many association, that
object is automatically saved (in order to update the join table). If you assign
multiple objects in one statement, then they are all saved.

If any of these saves fails due to validation errors, then the assignment
statement returns false and the assignment itself is cancelled.

If the parent object (the one declaring the has_and_belongs_to_many
association) is unsaved (that is, new_record? returns true) then the child
objects are not saved when they are added. All unsaved members of the
association will automatically be saved when the parent is saved.

If you want to assign an object to a has_and_belongs_to_many association
without saving the object, use the collection.build method.

## 3. Choosing an Association

### 3.1. belongs_to vs has_one

If you want to set up a one-to-one relationship between two models, you can
choose between a belongs_to and a has_one association. How do you know which
one to choose?

The distinction lies in the placement of the foreign key, which goes on the
table of the class declaring the belongs_to association. However, it’s
essential to understand the semantics to determine the correct associations:

- belongs_to: This association indicates that the current model contains the
foreign key and is a child in the relationship. It references another model,
implying that each instance of this model is linked to one instance of the
other model.

- has_one: This association indicates that the current model is the parent in
the relationship, and it owns one instance of the other model.

For example, consider a scenario with suppliers and their accounts. It makes
more sense to say that a supplier has/owns an account (where the supplier is the
parent) rather than an account has/owns a supplier. Therefore, the correct
associations would be:

- A supplier has one account.

- An account belongs to one supplier.

Here is how you can define these associations in Rails:

```ruby
class Supplier < ApplicationRecord
  has_one :account
end

class Account < ApplicationRecord
  belongs_to :supplier
end
```

To implement these associations, you'll need to create the corresponding
database tables and set up the foreign key. Here's an example migration:

```ruby
class CreateSuppliers < ActiveRecord::Migration[8.1]
  def change
    create_table :suppliers do |t|
      t.string :name
      t.timestamps
    end

    create_table :accounts do |t|
      t.belongs_to :supplier_id
      t.string :account_number
      t.timestamps
    end

    add_index :accounts, :supplier_id
  end
end
```

Remember that the foreign key goes on the table of the class declaring the
belongs_to association. In this case the account table.

### 3.2. has_many :through vs has_and_belongs_to_many

Rails offers two different ways to declare a many-to-many relationship between
models: has_many :through and has_and_belongs_to_many. Understanding the
differences and use cases for each can help you choose the best approach for
your application's needs.

The has_many :through association sets up a many-to-many relationship through
an intermediary model (also known as a join model). This approach is more
flexible and allows you to add validations, callbacks, and extra attributes to
the join model. The join table needs a primary_key (or a composite primary
key).

```ruby
class Assembly < ApplicationRecord
  has_many :manifests
  has_many :parts, through: :manifests
end

class Manifest < ApplicationRecord
  belongs_to :assembly
  belongs_to :part
end

class Part < ApplicationRecord
  has_many :manifests
  has_many :assemblies, through: :manifests
end
```

You'd use has_many :through when:

- You need to add extra attributes or methods to the join table.

- You require validations or
callbacks on the join model.

- The join table should be treated as an independent entity with its own
behavior.

The has_and_belongs_to_many association allows you to create a many-to-many
relationship directly between two models without needing an intermediary model.
This method is straightforward and is suitable for simple associations where no
additional attributes or behaviors are required on the join table. For
has_and_belongs_to_many associations, you'll need to create a join table
without a primary key.

```ruby
class Assembly < ApplicationRecord
  has_and_belongs_to_many :parts
end

class Part < ApplicationRecord
  has_and_belongs_to_many :assemblies
end
```

You'd use has_and_belongs_to_many when:

- The association is simple and does not require additional attributes or
behaviors on the join table.

- You do not need validations, callbacks, or extra methods on the join table.

## 4. Advanced Associations

### 4.1. Polymorphic Associations

A slightly more advanced twist on associations is the polymorphic association.
Polymorphic associations in Rails allow a model to belong to multiple other
models through a single association. This can be particularly useful when you
have a model that needs to be linked to different types of models.

For instance, imagine you have a Picture model that can belong to either
an Employee or a Product, because each of these can have a profile picture.
Here's how this could be declared:

```ruby
class Picture < ApplicationRecord
  belongs_to :imageable, polymorphic: true
end

class Employee < ApplicationRecord
  has_many :pictures, as: :imageable
end

class Product < ApplicationRecord
  has_many :pictures, as: :imageable
end
```

In the context above, imageable is a name chosen for the association. It's a
symbolic name that represents the polymorphic association between the Picture
model and other models such as Employee and Product. The important thing is
to use the same name (imageable) consistently across all associated models to
establish the polymorphic association correctly.

When you declare belongs_to :imageable, polymorphic: true in the Picture
model, you're saying that a Picture can belong to any model (like Employee
or Product) through this association.

You can think of a polymorphic belongs_to declaration as setting up an
interface that any other model can use. This allows you to retrieve a collection
of pictures from an instance of the Employee model using @employee.pictures.
Similarly, you can retrieve a collection of pictures from an instance of the
Product model using @product.pictures.

Additionally, if you have an instance of the Picture model, you can get its
parent via @picture.imageable, which could be an Employee or a Product.

To set up a polymorphic association manually you would need to declare both a
foreign key column (imageable_id) and a type column (imageable_type) in the
model:

```ruby
class CreatePictures < ActiveRecord::Migration[8.1]
  def change
    create_table :pictures do |t|
      t.string  :name
      t.bigint  :imageable_id
      t.string  :imageable_type
      t.timestamps
    end

    add_index :pictures, [:imageable_type, :imageable_id]
  end
end
```

In our example, imageable_id could be the ID of either an Employee or a
Product, and imageable_type is the name of the associated model's class, so
either Employee or Product.

While creating the polymorphic association manually is acceptable, it is instead
recommended to use t.references or its alias t.belongs_to and specify
polymorphic: true so that Rails knows that the association is polymorphic, and
it automatically adds both the foreign key and type columns to the table.

```ruby
class CreatePictures < ActiveRecord::Migration[8.1]
  def change
    create_table :pictures do |t|
      t.string :name
      t.belongs_to :imageable, polymorphic: true
      t.timestamps
    end
  end
end
```

Since polymorphic associations rely on storing class names in the
database, that data must remain synchronized with the class name used by the
Ruby code. When renaming a class, make sure to update the data in the
polymorphic type column.

For example, if you change the class name from Product to Item then you'd
need to run a migration script to update the imageable_type column in the
pictures table (or whichever table is affected) with the new class name.
Additionally, you'll need to update any other references to the class name
throughout your application code to reflect the change.

### 4.2. Models with Composite Primary Keys

Rails can often infer primary key-foreign key relationships between associated
models, but when dealing with composite primary keys, Rails typically defaults
to using only part of the composite key, often the id column, unless explicitly
instructed otherwise.

If you're working with composite primary keys in your Rails models and need to
ensure the correct handling of associations, please refer to the Associations
section of the Composite Primary Keys
guide.
This section provides comprehensive guidance on setting up and using
associations with composite primary keys in Rails, including how to specify
composite foreign keys when necessary.

### 4.3. Self Joins

A self-join is a regular join, but the table is joined with itself. This is
useful in situations where there is a hierarchical relationship within a single
table. A common example is an employee management system where an employee can
have a manager, and that manager is also an employee.

Consider an organization where employees can be managers of other employees. We
want to track this relationship using a single employees table.

In your Rails model, you define the Employee class to reflect these
relationships:

```ruby
class Employee < ApplicationRecord
  # an employee can have many subordinates.
  has_many :subordinates, class_name: "Employee", foreign_key: "manager_id"

  # an employee can have one manager.
  belongs_to :manager, class_name: "Employee", optional: true
end
```

has_many :subordinates sets up a one-to-many relationship where an employee
can have many subordinates. Here, we specify that the related model is also
Employee (class_name: "Employee") and the foreign key used to identify the
manager is manager_id.

belongs_to :manager sets up a one-to-one relationship where an employee can
belong to one manager. Again, we specify the related model as Employee.

To support this relationship, we need to add a manager_id column to the
employees table. This column references the id of another employee (the
manager).

```ruby
class CreateEmployees < ActiveRecord::Migration[8.1]
  def change
    create_table :employees do |t|
      # Add a belongs_to reference to the manager, which is an employee.
      t.belongs_to :manager, foreign_key: { to_table: :employees }
      t.timestamps
    end
  end
end
```

- t.belongs_to :manager adds a manager_id column to the employees table.

- foreign_key: { to_table: :employees } ensures that the manager_id column
references the id column of the employees table.

The to_table option passed to foreign_key and more are explained in
SchemaStatements#add_reference.

With this setup, you can easily access an employee's subordinates and manager in
your Rails application.

To get an employee's subordinates:

```ruby
employee = Employee.find(1)
subordinates = employee.subordinates
```

To get an employee's manager:

```ruby
manager = employee.manager
```

## 5. Single Table Inheritance (STI)

Single Table Inheritance (STI) is a pattern in Rails that allows multiple models
to be stored in a single database table. This is useful when you have different
types of entities that share common attributes and behavior but also have
specific behaviors.

For example, suppose we have Car, Motorcycle, and Bicycle models. These
models will share fields like color and price, but each will have unique
behaviors. They will also each have their own controller.

### 5.1. Generating the Base Vehicle Model

First, we generate the base Vehicle model with shared fields:

```bash
bin/rails generate model vehicle type:string color:string price:decimal{10.2}
```

Here, the type field is crucial for STI as it stores the model name (Car,
Motorcycle, or Bicycle). STI requires this field to differentiate between
the different models stored in the same table.

### 5.2. Generating Child Models

Next, we generate the Car, Motorcycle, and Bicycle models that inherit
from Vehicle. These models won't have their own tables; instead, they will use
the vehicles table.

To generate the Car model:

```bash
bin/rails generate model car --parent=Vehicle
```

For this, we can use the --parent=PARENT option, which will generate a model
that inherits from the specified parent and without equivalent migration (since
the table already exists).

This generates a Car model that inherits from Vehicle:

```ruby
class Car < Vehicle
end
```

This means that all behavior added to Vehicle is available for Car too, as
associations, public methods, etc. Creating a car will save it in the vehicles
table with "Car" as the type field:

Repeat the same process for Motorcycle and Bicycle.

### 5.3. Creating Records

Creating a record for Car:

```ruby
Car.create(color: "Red", price: 10000)
```

This will generate the following SQL:

```sql
INSERT INTO "vehicles" ("type", "color", "price") VALUES ('Car', 'Red', 10000)
```

### 5.4. Querying Records

Querying car records will search only for vehicles that are cars:

```ruby
Car.all
```

will run a query like:

```sql
SELECT "vehicles".* FROM "vehicles" WHERE "vehicles"."type" IN ('Car')
```

### 5.5. Adding Specific Behavior

You can add specific behavior or methods to the child models. For example,
adding a method to the Car model:

```ruby
class Car < Vehicle
  def honk
    "Beep Beep"
  end
end
```

Now you can call the honk method on a Car instance:

```ruby
car = Car.first
car.honk
# => 'Beep Beep'
```

### 5.6. Controllers

Each model can have its own controller. For example, the CarsController:

```ruby
# app/controllers/cars_controller.rb

class CarsController < ApplicationController
  def index
    @cars = Car.all
  end
end
```

### 5.7. Overriding the inheritance column

There may be cases (like when working with a legacy database) where you need to
override the name of the inheritance column. This can be achieved with the
inheritance_column method.

```ruby
# Schema: vehicles[ id, kind, created_at, updated_at ]
class Vehicle < ApplicationRecord
  self.inheritance_column = "kind"
end

class Car < Vehicle
end

Car.create(color: "Red", price: 10000)
# => #<Car kind: "Car", color: "Red", price: 10000>
```

In this setup, Rails will use the kind column to store the model type,
allowing STI to function correctly with the custom column name.

### 5.8. Disabling the inheritance column

There may be cases (like when working with a legacy database) where you need to
disable Single Table Inheritance altogether. If you don't disable STI properly,
you might encounter an ActiveRecord::SubclassNotFound error.

To disable STI, you can set the inheritance_column to nil.

```ruby
# Schema: vehicles[ id, type, created_at, updated_at ]
class Vehicle < ApplicationRecord
  self.inheritance_column = nil
end

Vehicle.create!(type: "Car", color: "Red", price: 10000)
# => #<Vehicle type: "Car", color: "Red", price: 10000>
```

In this configuration, Rails will treat the type column as a normal attribute
and will not use it for STI purposes. This is useful if you need to work with a
legacy schema that does not follow the STI pattern.

These adjustments provide flexibility when integrating Rails with existing
databases or when specific customization is required for your models.

### 5.9. Considerations

Single Table Inheritance (STI) works best
when there is little difference between subclasses and their attributes, but it
includes all attributes of all subclasses in a single table.

A disadvantage of this approach is that it can result in table bloat, as the
table will include attributes specific to each subclass, even if they aren't
used by others. This can be solved by using Delegated Types.

Additionally, if you’re using polymorphic
associations, where a model can belong to more than
one other model via a type and an ID, it could become complex to maintain
referential integrity because the association logic must handle different types
correctly.

Finally, if you have specific data integrity checks or validations that differ
between subclasses, you need to ensure these are correctly handled by Rails or
the database, especially when setting up foreign key constraints.

## 6. Delegated Types

Delegated types solves the Single Table Inheritance
(STI) problem of table bloat via
delegated_type. This approach allows us to store shared attributes in a
superclass table and have separate tables for subclass-specific attributes.

### 6.1. Setting up Delegated Types

To use delegated types, we need to model our data as follows:

- There is a superclass that stores shared attributes among all subclasses in
its table.

- Each subclass must inherit from the superclass, and will have a separate table
for any additional attributes specific to it.

This eliminates the need to define attributes in a single table that are
unintentionally shared among all subclasses.

### 6.2. Generating Models

In order to apply this to our example above, we need to regenerate our models.

First, let's generate the base Entry model which will act as our superclass:

```bash
bin/rails generate model entry entryable_type:string entryable_id:integer
```

Then, we will generate new Message and Comment models for delegation:

```bash
bin/rails generate model message subject:string body:string
bin/rails generate model comment content:string
```

If you don't specify a type for a field (e.g., subject instead of subject:string), Rails will default to type string.

After running the generators, our models should look like this:

```ruby
# Schema: entries[ id, entryable_type, entryable_id, created_at, updated_at ]
class Entry < ApplicationRecord
end

# Schema: messages[ id, subject, body, created_at, updated_at ]
class Message < ApplicationRecord
end

# Schema: comments[ id, content, created_at, updated_at ]
class Comment < ApplicationRecord
end
```

### 6.3. Declaring delegated_type

First, declare a delegated_type in the superclass Entry.

```ruby
class Entry < ApplicationRecord
  delegated_type :entryable, types: %w[ Message Comment ], dependent: :destroy
end
```

The entryable parameter specifies the field to use for delegation, and include
the types Message and Comment as the delegate classes. The entryable_type
and entryable_id fields store the subclass name and the record ID of the
delegate subclass, respectively.

### 6.4. Defining the Entryable Module

Next, define a module to implement those delegated types by declaring the as:
:entryable parameter in the has_one association.

```ruby
module Entryable
  extend ActiveSupport::Concern

  included do
    has_one :entry, as: :entryable, touch: true
  end
end
```

Include the created module in your subclass:

```ruby
class Message < ApplicationRecord
  include Entryable
end

class Comment < ApplicationRecord
  include Entryable
end
```

With this definition complete, our Entry delegator now provides the following
methods:

### 6.5. Object creation

When creating a new Entry object, we can specify the entryable subclass at
the same time.

```ruby
Entry.create! entryable: Message.new(subject: "hello!")
```

### 6.6. Adding further delegation

We can enhance our Entry delegator by defining delegate and using
polymorphism on the subclasses. For example, to delegate the title method from
Entry to its subclasses:

```ruby
class Entry < ApplicationRecord
  delegated_type :entryable, types: %w[ Message Comment ]
  delegate :title, to: :entryable
end

class Message < ApplicationRecord
  include Entryable

  def title
    subject
  end
end

class Comment < ApplicationRecord
  include Entryable

  def title
    content.truncate(20)
  end
end
```

This setup allows Entry to delegate the title method to its subclasses,
where Message uses subject and Comment uses a truncated version of
content.

## 7. Tips, Tricks, and Warnings

Here are a few things you should know to make efficient use of Active Record
associations in your Rails applications:

- Controlling caching

- Avoiding name collisions

- Updating the schema

- Controlling association scope

- Bi-directional associations

### 7.1. Controlling Association Caching

All of the association methods are built around caching, which keeps the result
of loaded associations for further operations. The cache is even shared across
methods. For example:

```ruby
# retrieves books from the database
author.books.load

# uses the cached copy of books
author.books.size

# uses the cached copy of books
author.books.empty?
```

When we use author.books, the data is not immediately loaded from the
database. Instead, it sets up a query that will be executed when you actually
try to use the data, for example, by calling methods that require data like
each, size, empty?, etc. By calling author.books.load, before calling other
methods which use the data, you explicitly trigger the query to load the data
from the database immediately. This is useful if you know you will need the data
and want to avoid the potential performance overhead of multiple queries being
triggered as you work with the association.

But what if you want to reload the cache, because data might have been changed
by some other part of the application? Just call
reload
on the association:

```ruby
# retrieves books from the database
author.books.load

# uses the cached copy of books
author.books.size

# discards the cached copy of books and goes back to the database
author.books.reload.empty?
```

### 7.2. Avoiding Name Collisions

When creating associations in Ruby on Rails models, it's important to avoid
using names that are already used for instance methods of ActiveRecord::Base.
This is because creating an association with a name that clashes with an
existing method could lead to unintended consequences, such as overriding the
base method and causing issues with functionality. For example, using names like
attributes or connection for associations would be problematic.

### 7.3. Updating the Schema

Associations are extremely useful, they are responsible for defining the
relationships between models but they do not update your database schema. You
are responsible for maintaining your database schema to match your associations.
This usually involves two main tasks: creating foreign keys for belongs_to
associations and setting up the correct join table for has_many
:through and
has_and_belongs_to_many associations. You can read
more about when to use a has_many :through vs has_and_belongs_to_many in the
has many through vs has and belongs to many
section.

#### 7.3.1. Creating Foreign Keys for belongs_to Associations

When you declare a belongs_to association, you need to create
foreign keys as appropriate. For example, consider this model:

```ruby
class Book < ApplicationRecord
  belongs_to :author
end
```

This declaration needs to be backed up by a corresponding foreign key column in
the books table. For a brand new table, the migration might look something like
this:

```ruby
class CreateBooks < ActiveRecord::Migration[8.1]
  def change
    create_table :books do |t|
      t.datetime   :published_at
      t.string     :book_number
      t.belongs_to :author
    end
  end
end
```

Whereas for an existing table, it might look like this:

```ruby
class AddAuthorToBooks < ActiveRecord::Migration[8.1]
  def change
    add_reference :books, :author
  end
end
```

#### 7.3.2. Creating Join Tables for has_and_belongs_to_many Associations

If you create a has_and_belongs_to_many association, you need to explicitly
create the join table. Unless the name of the join table is explicitly specified
by using the :join_table option, Active Record creates the name by using the
lexical order of the class names. So a join between author and book models will
give the default join table name of "authors_books" because "a" outranks "b" in
lexical ordering.

Whatever the name, you must manually generate the join table with an appropriate
migration. For example, consider these associations:

```ruby
class Assembly < ApplicationRecord
  has_and_belongs_to_many :parts
end

class Part < ApplicationRecord
  has_and_belongs_to_many :assemblies
end
```

These need to be backed up by a migration to create the assemblies_parts
table.

```bash
bin/rails generate migration CreateAssembliesPartsJoinTable assemblies parts
```

You can then fill out the migration and ensure that the table is created without
a primary key.

```ruby
class CreateAssembliesPartsJoinTable < ActiveRecord::Migration[8.1]
  def change
    create_table :assemblies_parts, id: false do |t|
      t.bigint :assembly_id
      t.bigint :part_id
    end

    add_index :assemblies_parts, :assembly_id
    add_index :assemblies_parts, :part_id
  end
end
```

We pass id: false to create_table because the join table does not represent
a model. If you observe any strange behavior in a has_and_belongs_to_many
association like mangled model IDs, or exceptions about conflicting IDs, chances
are you forgot to set id: false when creating your migration.

For simplicity, you can also use the method create_join_table:

```ruby
class CreateAssembliesPartsJoinTable < ActiveRecord::Migration[8.1]
  def change
    create_join_table :assemblies, :parts do |t|
      t.index :assembly_id
      t.index :part_id
    end
  end
end
```

You can read more about the create_join_table method in the Active Record
Migration Guides

#### 7.3.3. Creating Join Tables for has_many :through Associations

The main difference in schema implementation between creating a join table for
has_many :through vs has_and_belongs_to_many is that the join table for a
has_many :through requires an id.

```ruby
class CreateAppointments < ActiveRecord::Migration[8.1]
  def change
    create_table :appointments do |t|
      t.belongs_to :physician
      t.belongs_to :patient
      t.datetime :appointment_date
      t.timestamps
    end
  end
end
```

### 7.4. Controlling Association Scope

By default, associations look for objects only within the current module's
scope. This feature is particularly useful when declaring Active Record models
inside a module, as it keeps the associations scoped properly. For example:

```ruby
module MyApplication
  module Business
    class Supplier < ApplicationRecord
      has_one :account
    end

    class Account < ApplicationRecord
      belongs_to :supplier
    end
  end
end
```

In this example, both the Supplier and Account classes are defined within
the same module (MyApplication::Business). This organization allows you to
structure your models into folders based on their scope without needing to
explicitly specify the scope in every association:

```ruby
# app/models/my_application/business/supplier.rb
module MyApplication
  module Business
    class Supplier < ApplicationRecord
      has_one :account
    end
  end
end
```

```ruby
# app/models/my_application/business/account.rb
module MyApplication
  module Business
    class Account < ApplicationRecord
      belongs_to :supplier
    end
  end
end
```

It is important to note that while model scoping helps organize your code, it
does not change the naming convention for your database tables. For instance, if
you have a MyApplication::Business::Supplier model, the corresponding database
table should still follow the naming convention and be named
my_application_business_suppliers.

However, if the Supplier and Account models are defined in different scopes,
the associations will not work by default:

```ruby
module MyApplication
  module Business
    class Supplier < ApplicationRecord
      has_one :account
    end
  end

  module Billing
    class Account < ApplicationRecord
      belongs_to :supplier
    end
  end
end
```

To associate a model with a model in a different namespace, you must specify the
complete class name in your association declaration:

```ruby
module MyApplication
  module Business
    class Supplier < ApplicationRecord
      has_one :account,
        class_name: "MyApplication::Billing::Account"
    end
  end

  module Billing
    class Account < ApplicationRecord
      belongs_to :supplier,
        class_name: "MyApplication::Business::Supplier"
    end
  end
end
```

By explicitly declaring the class_name option, you can create associations
across different namespaces, ensuring the correct models are linked regardless
of their module scope.

### 7.5. Bi-directional Associations

In Rails, it's common for associations between models to be bi-directional,
meaning they need to be declared in both related models. Consider the following
example:

```ruby
class Author < ApplicationRecord
  has_many :books
end

class Book < ApplicationRecord
  belongs_to :author
end
```

Active Record will attempt to automatically identify that these two models share
a bi-directional association based on the association name. This information
allows Active Record to:

- Prevent needless queries for already-loaded data:Active Record avoids additional database queries for already-loaded data.
irb> author = Author.first
irb> author.books.all? do |book|
irb>   book.author.equal?(author) # No additional queries executed here
irb> end
=> true

- Prevent inconsistent dataSince only one copy of the Author object is loaded, it helps to prevent
inconsistencies.
irb> author = Author.first
irb> book = author.books.first
irb> author.name == book.author.name
=> true
irb> author.name = "Changed Name"
irb> author.name == book.author.name
=> true

- Automatic saving of associations in more cases:
irb> author = Author.new
irb> book = author.books.new
irb> book.save!
irb> book.persisted?
=> true
irb> author.persisted?
=> true

- Validate the presence and
absence of associations in more
cases:
irb> book = Book.new
irb> book.valid?
=> false
irb> book.errors.full_messages
=> ["Author must exist"]
irb> author = Author.new
irb> book = author.books.new
irb> book.valid?
=> true

Prevent needless queries for already-loaded data:

Active Record avoids additional database queries for already-loaded data.

```
irb> author = Author.first
irb> author.books.all? do |book|
irb>   book.author.equal?(author) # No additional queries executed here
irb> end
=> true
```

Prevent inconsistent data

Since only one copy of the Author object is loaded, it helps to prevent
inconsistencies.

```
irb> author = Author.first
irb> book = author.books.first
irb> author.name == book.author.name
=> true
irb> author.name = "Changed Name"
irb> author.name == book.author.name
=> true
```

Automatic saving of associations in more cases:

```
irb> author = Author.new
irb> book = author.books.new
irb> book.save!
irb> book.persisted?
=> true
irb> author.persisted?
=> true
```

Validate the presence and
absence of associations in more
cases:

```
irb> book = Book.new
irb> book.valid?
=> false
irb> book.errors.full_messages
=> ["Author must exist"]
irb> author = Author.new
irb> book = author.books.new
irb> book.valid?
=> true
```

Sometimes, you might need to customize the association with options like
:foreign_key or :class_name. When you do this, Rails might not automatically
recognize the bi-directional association involving :through or :foreign_key
options.

Custom scopes on the opposite association also prevent automatic identification,
as do custom scopes on the association itself unless
config.active_record.automatic_scope_inversing is set to true.

For example, consider the following model declarations with a custom foreign
key:

```ruby
class Author < ApplicationRecord
  has_many :books
end

class Book < ApplicationRecord
  belongs_to :writer, class_name: "Author", foreign_key: "author_id"
end
```

Due to the :foreign_key option, Active Record will not automatically recognize
the bi-directional association, which can lead to several issues:

- Execute needless queries for the same data (in this example causing N+1
queries):
irb> author = Author.first
irb> author.books.any? do |book|
irb>   book.writer.equal?(author) # This executes an author query for every book
irb> end
=> false

- Reference multiple copies of a model with inconsistent data:
irb> author = Author.first
irb> book = author.books.first
irb> author.name == book.writer.name
=> true
irb> author.name = "Changed Name"
irb> author.name == book.writer.name
=> false

- Fail to autosave associations:
irb> author = Author.new
irb> book = author.books.new
irb> book.save!
irb> book.persisted?
=> true
irb> author.persisted?
=> false

- Fail to validate presence or absence:
irb> author = Author.new
irb> book = author.books.new
irb> book.valid?
=> false
irb> book.errors.full_messages
=> ["Author must exist"]

Execute needless queries for the same data (in this example causing N+1
queries):

```
irb> author = Author.first
irb> author.books.any? do |book|
irb>   book.writer.equal?(author) # This executes an author query for every book
irb> end
=> false
```

Reference multiple copies of a model with inconsistent data:

```
irb> author = Author.first
irb> book = author.books.first
irb> author.name == book.writer.name
=> true
irb> author.name = "Changed Name"
irb> author.name == book.writer.name
=> false
```

Fail to autosave associations:

```
irb> author = Author.new
irb> book = author.books.new
irb> book.save!
irb> book.persisted?
=> true
irb> author.persisted?
=> false
```

Fail to validate presence or absence:

```
irb> author = Author.new
irb> book = author.books.new
irb> book.valid?
=> false
irb> book.errors.full_messages
=> ["Author must exist"]
```

To resolve these issues, you can explicitly declare bi-directional associations
using the :inverse_of option:

```ruby
class Author < ApplicationRecord
  has_many :books, inverse_of: "writer"
end

class Book < ApplicationRecord
  belongs_to :writer, class_name: "Author", foreign_key: "author_id"
end
```

By including the :inverse_of option in the has_many association declaration,
Active Record will recognize the bi-directional association and behave as
described in the initial examples above.

## 8. Association References

### 8.1. Options

While Rails uses intelligent defaults that will work well in most situations,
there may be times when you want to customize the behavior of the association
references. Such customizations can be accomplished by passing options blocks
when you create the association. For example, this association uses two such
options:

```ruby
class Book < ApplicationRecord
  belongs_to :author, touch: :books_updated_at,
    counter_cache: true
end
```

Each association supports numerous options which you can read more about in
Options section of each association in the ActiveRecord Associations
API.
We'll discuss some of the common use cases below.

#### 8.1.1. :class_name

If the name of the other model cannot be derived from the association name, you
can use the :class_name option to supply the model name. For example, if a
book belongs to an author, but the actual name of the model containing authors
is Patron, you'd set things up this way:

```ruby
class Book < ApplicationRecord
  belongs_to :author, class_name: "Patron"
end
```

This option is not supported in polymorphic associations, since in that case the
class name of the associated record is stored in the type column.

#### 8.1.2. :dependent

Controls what happens to the associated object when its owner is destroyed:

- :destroy, when the object is destroyed, destroy will be called on its
associated objects. This method not only removes the associated records from
the database but also ensures that any defined callbacks (like
before_destroy and after_destroy) are executed. This is useful for
performing custom logic during the deletion process, such as logging or
cleaning up related data.

- :delete, when the object is destroyed, all its associated objects will be
deleted directly from the database without calling their destroy method.
This method performs a direct deletion and bypasses any callbacks or
validations in the associated models, making it more efficient but potentially
leading to data integrity issues if important cleanup tasks are skipped. Use
delete when you need to remove records quickly and are confident that no
additional actions are required for the associated records.

- :destroy_async: when the object is destroyed, an
ActiveRecord::DestroyAssociationAsyncJob job is enqueued which will call
destroy on its associated objects. Active Job must be set up for this to work.
Do not use this option if the association is backed by foreign key constraints
in your database. The foreign key constraint actions will occur inside the
same transaction that deletes its owner.

- :nullify causes the foreign key to be set to NULL. Polymorphic type
column is also nullified on polymorphic associations. Callbacks are not
executed.

- :restrict_with_exception causes an ActiveRecord::DeleteRestrictionError
exception to be raised if there is an associated record

- :restrict_with_error causes an error to be added to the owner if there is
an associated object

You should not specify this option on a belongs_to association that
is connected with a has_many association on the other class. Doing so can lead
to orphaned records in your database because destroying the parent object may
attempt to destroy its children, which in turn may attempt to destroy the parent
again, causing inconsistencies.

Do not leave the :nullify option for associations with NOT NULL database
constraints. Setting dependent to :destroy is essential; otherwise, the
foreign key of the associated object may be set to NULL, preventing changes to
it.

The :dependent option is ignored with the :through option. When using
:through, the join model must have a belongs_to association, and the
deletion affects only the join records, not the associated records.

When using dependent: :destroy on a scoped association, only the scoped
objects are destroyed. For example, in a Post model defined as has_many
:comments, -> { where published: true }, dependent: :destroy, calling destroy
on a post will only delete published comments, leaving unpublished comments
intact with a foreign key pointing to the deleted post.

You cannot use the :dependent option directly on a has_and_belongs_to_many
association. To manage deletions of join table records, handle them manually or
switch to a has_many :through association, which provides more flexibility and
supports the :dependent option.

#### 8.1.3. :foreign_key

By convention, Rails assumes that the column used to hold the foreign key on
this model is the name of the association with the suffix _id added. The
:foreign_key option lets you set the name of the foreign key directly:

```ruby
class Supplier < ApplicationRecord
  has_one :account, foreign_key: "supp_id"
end
```

Rails does not create foreign key columns for you. You need to explicitly
define them in your migrations.

#### 8.1.4. :primary_key

By default, Rails uses the id column as the primary key for its tables. The
:primary_key option allows you to specify a different column as the primary
key.

For example, if the users table uses guid as the primary key instead of
id, and you want the todos table to reference guid as a foreign key
(user_id), you can configure it like this:

```ruby
class User < ApplicationRecord
  self.primary_key = "guid" # Sets the primary key to guid instead of id
end

class Todo < ApplicationRecord
  belongs_to :user, primary_key: "guid" # References the guid column in users table
end
```

When you execute @user.todos.create, the @todo record will have its
user_id value set to the guid value of @user.

has_and_belongs_to_many does not support the :primary_key option. For this
type of association, you can achieve similar functionality by using a join table
with has_many :through association, which gives more flexibility and supports
the :primary_key option. You can read more about this in the
has_many :through section.

#### 8.1.5. :touch

If you set the :touch option to true, then the updated_at or updated_on
timestamp on the associated object will be set to the current time whenever this
object is saved or destroyed:

```ruby
class Book < ApplicationRecord
  belongs_to :author, touch: true
end

class Author < ApplicationRecord
  has_many :books
end
```

In this case, saving or destroying a book will update the timestamp on the
associated author. You can also specify a particular timestamp attribute to
update:

```ruby
class Book < ApplicationRecord
  belongs_to :author, touch: :books_updated_at
end
```

has_and_belongs_to_many does not support the :touch option. For this type of
association, you can achieve similar functionality by using a join table with
has_many :through association. You can read more about this in the
has_many :through section.

#### 8.1.6. :validate

If you set the :validate option to true, then new associated objects will be
validated whenever you save this object. By default, this is false: new
associated objects will not be validated when this object is saved.

has_and_belongs_to_many does not support the :validate option. For this type
of association, you can achieve similar functionality by using a join table with
has_many :through association. You can read more about this in the
has_many :through section.

#### 8.1.7. :inverse_of

The :inverse_of option specifies the name of the belongs_to association that
is the inverse of this association. See the bi-directional
association section for more details.

```ruby
class Supplier < ApplicationRecord
  has_one :account, inverse_of: :supplier
end

class Account < ApplicationRecord
  belongs_to :supplier, inverse_of: :account
end
```

#### 8.1.8. :source_type

The :source_type option specifies the source association type for a has_many
:through association that proceeds through a polymorphic
association.

```ruby
class Author < ApplicationRecord
  has_many :books
  has_many :paperbacks, through: :books, source: :format, source_type: "Paperback"
end

class Book < ApplicationRecord
  belongs_to :format, polymorphic: true
end

class Hardback < ApplicationRecord; end
class Paperback < ApplicationRecord; end
```

#### 8.1.9. :strict_loading

Enforces strict loading every time an associated record is loaded through this
association.

#### 8.1.10. :association_foreign_key

The :association_foreign_key can be found on a has_and_belongs_to_many
relationship. By convention, Rails assumes that the column in the join table
used to hold the foreign key pointing to the other model is the name of that
model with the suffix _id added. The :association_foreign_key option lets
you set the name of the foreign key directly. For example:

```ruby
class User < ApplicationRecord
  has_and_belongs_to_many :friends,
      class_name: "User",
      foreign_key: "this_user_id",
      association_foreign_key: "other_user_id"
end
```

The :foreign_key and :association_foreign_key options are useful when
setting up a many-to-many self-join.

#### 8.1.11. :join_table

The :join_table can be found on a has_and_belongs_to_many relationship. If
the default name of the join table, based on lexical ordering, is not what you
want, you can use the :join_table option to override the default.

#### 8.1.12. :deprecated

If true, Active Record warns every time the association is used.

Three reporting modes are supported (:warn, :raise, and :notify), and
backtraces can be enabled or disabled. Defaults are :warn mode and disabled
backtraces.

Please, check the documentation of ActiveRecord::Associations::ClassMethods
for further details.

### 8.2. Scopes

Scopes allow you to specify common queries that can be referenced as method
calls on the association objects. This is useful for defining custom queries
that are reused in multiple places in your application. For example:

```ruby
class Parts < ApplicationRecord
  has_and_belongs_to_many :assemblies, -> { where active: true }
end
```

#### 8.2.1. General Scopes

You can use any of the standard querying methods
inside the scope block. The following ones are discussed below:

- where

- includes

- readonly

- select

The where method lets you specify the conditions that the associated object
must meet.

```ruby
class Parts < ApplicationRecord
  has_and_belongs_to_many :assemblies,
    -> { where "factory = 'Seattle'" }
end
```

You can also set conditions via a hash:

```ruby
class Parts < ApplicationRecord
  has_and_belongs_to_many :assemblies,
    -> { where factory: "Seattle" }
end
```

If you use a hash-style where, then record creation via this association will
be automatically scoped using the hash. In this case, using
@parts.assemblies.create or @parts.assemblies.build will create assemblies
where the factory column has the value "Seattle".

You can use the includes method to specify second-order associations that
should be eager-loaded when this association is used. For example, consider
these models:

```ruby
class Supplier < ApplicationRecord
  has_one :account
end

class Account < ApplicationRecord
  belongs_to :supplier
  belongs_to :representative
end

class Representative < ApplicationRecord
  has_many :accounts
end
```

If you frequently retrieve representatives directly from suppliers
(@supplier.account.representative), then you can make your code somewhat more
efficient by including representatives in the association from suppliers to
accounts:

```ruby
class Supplier < ApplicationRecord
  has_one :account, -> { includes :representative }
end

class Account < ApplicationRecord
  belongs_to :supplier
  belongs_to :representative
end

class Representative < ApplicationRecord
  has_many :accounts
end
```

There's no need to use includes for immediate associations - that is, if
you have Book belongs_to :author, then the author is eager-loaded
automatically when it's needed.

If you use readonly, then the associated object will be read-only when
retrieved via the association.

```ruby
class Book < ApplicationRecord
  belongs_to :author, -> { readonly }
end
```

This is useful when you want to prevent the associated object from being
modified through the association. For example, if you have a Book model that
belongs_to :author, you can use readonly to prevent the author from being
modified through the book:

```ruby
@book.author = Author.first
@book.author.save! # This will raise an ActiveRecord::ReadOnlyRecord error
```

The select method lets you override the SQL SELECT clause used to retrieve
data about the associated object. By default, Rails retrieves all columns.

For example, if you have an Author model with many Books, but you only want
to retrieve the title of each book:

```ruby
class Author < ApplicationRecord
  has_many :books, -> { select(:id, :title) } # Only select id and title columns
end

class Book < ApplicationRecord
  belongs_to :author
end
```

Now, when you access an author's books, only the id and title columns will
be retrieved from the books table.

If you use the select method on a belongs_to association, you should
also set the :foreign_key option to guarantee correct results. For example:

```ruby
class Book < ApplicationRecord
  belongs_to :author, -> { select(:id, :name) }, foreign_key: "author_id" # Only select id and name columns
end

class Author < ApplicationRecord
  has_many :books
end
```

In this case, when you access a book's author, only the id and name columns
will be retrieved from the authors table.

#### 8.2.2. Collection Scopes

has_many and has_and_belongs_to_many are associations that deal with
collections of records, so you can use additional methods like group, limit,
order, select, and distinct to customize the query used by the
association.

The group method supplies an attribute name to group the result set by, using
a GROUP BY clause in the finder SQL.

```ruby
class Parts < ApplicationRecord
  has_and_belongs_to_many :assemblies, -> { group "factory" }
end
```

The limit method lets you restrict the total number of objects that will be
fetched through an association.

```ruby
class Parts < ApplicationRecord
  has_and_belongs_to_many :assemblies,
    -> { order("created_at DESC").limit(50) }
end
```

The order method dictates the order in which associated objects will be
received (in the syntax used by an SQL ORDER BY clause).

```ruby
class Author < ApplicationRecord
  has_many :books, -> { order "date_confirmed DESC" }
end
```

The select method lets you override the SQL SELECT clause that is used to
retrieve data about the associated objects. By default, Rails retrieves all
columns.

If you specify your own select, be sure to include the primary key
and foreign key columns of the associated model. If you do not, Rails will throw
an error.

Use the distinct method to keep the collection free of duplicates. This is
mostly useful together with the :through option.

```ruby
class Person < ApplicationRecord
  has_many :readings
  has_many :articles, through: :readings
end
```

```
irb> person = Person.create(name: 'John')
irb> article = Article.create(name: 'a1')
irb> person.articles << article
irb> person.articles << article
irb> person.articles.to_a
=> [#<Article id: 5, name: "a1">, #<Article id: 5, name: "a1">]
irb> Reading.all.to_a
=> [#<Reading id: 12, person_id: 5, article_id: 5>, #<Reading id: 13, person_id: 5, article_id: 5>]
```

In the above case there are two readings and person.articles brings out both
of them even though these records are pointing to the same article.

Now let's set distinct:

```ruby
class Person
  has_many :readings
  has_many :articles, -> { distinct }, through: :readings
end
```

```
irb> person = Person.create(name: 'Honda')
irb> article = Article.create(name: 'a1')
irb> person.articles << article
irb> person.articles << article
irb> person.articles.to_a
=> [#<Article id: 7, name: "a1">]
irb> Reading.all.to_a
=> [#<Reading id: 16, person_id: 7, article_id: 7>, #<Reading id: 17, person_id: 7, article_id: 7>]
```

In the above case there are still two readings. However person.articles shows
only one article because the collection loads only unique records.

If you want to make sure that, upon insertion, all of the records in the
persisted association are distinct (so that you can be sure that when you
inspect the association that you will never find duplicate records), you should
add a unique index on the table itself. For example, if you have a table named
readings and you want to make sure the articles can only be added to a person
once, you could add the following in a migration:

```ruby
add_index :readings, [:person_id, :article_id], unique: true
```

Once you have this unique index, attempting to add the article to a person twice
will raise an ActiveRecord::RecordNotUnique error:

```
irb> person = Person.create(name: 'Honda')
irb> article = Article.create(name: 'a1')
irb> person.articles << article
irb> person.articles << article
ActiveRecord::RecordNotUnique
```

Note that checking for uniqueness using something like include? is subject to
race conditions. Do not attempt to use include? to enforce distinctness in an
association. For instance, using the article example from above, the following
code would be racy because multiple users could be attempting this at the same
time:

```ruby
person.articles << article unless person.articles.include?(article)
```

#### 8.2.3. Using the Association Owner

You can pass the owner of the association as a single argument to the scope
block for even more control over the association scope. However, be aware that
doing this will make preloading the association impossible.

For example:

```ruby
class Supplier < ApplicationRecord
  has_one :account, ->(supplier) { where active: supplier.active? }
end
```

In this example, the account association of the Supplier model is scoped
based on the active status of the supplier.

By utilizing association extensions and scoping with the association owner, you
can create more dynamic and context-aware associations in your Rails
applications.

### 8.3. Counter Cache

The :counter_cache option in Rails helps improve the efficiency of finding the
number of associated objects. Consider the following models:

```ruby
class Book < ApplicationRecord
  belongs_to :author
end

class Author < ApplicationRecord
  has_many :books
end
```

By default, querying author.books.size results in a database call to perform a
COUNT(*) query. To optimize this, you can add a counter cache to the
belonging model (in this case, Book). This way, Rails can return the count
directly from the cache without querying the database.

```ruby
class Book < ApplicationRecord
  belongs_to :author, counter_cache: true
end

class Author < ApplicationRecord
  has_many :books
end
```

With this declaration, Rails will keep the cache value up to date, and then
return that value in response to the size method, avoiding the database call.

Although the :counter_cache option is specified on the model with the
belongs_to declaration, the actual column must be added to the associated
(in this case has_many) model. In this example, you need to add a
books_count column to the Author model:

```ruby
class AddBooksCountToAuthors < ActiveRecord::Migration[8.1]
  def change
    add_column :authors, :books_count, :integer, default: 0, null: false
  end
end
```

You can specify a custom column name in the counter_cache declaration instead
of using the default books_count. For example, to use count_of_books:

```ruby
class Book < ApplicationRecord
  belongs_to :author, counter_cache: :count_of_books
end

class Author < ApplicationRecord
  has_many :books
end
```

You only need to specify the :counter_cache option on the belongs_to
side of the association.

Using counter caches on existing large tables can be troublesome. To avoid
locking the table for too long, the column values must be backfilled separately
from the column addition. This backfill must also happen before using
:counter_cache; otherwise, methods like size, any?, etc., which rely on
counter caches, may return incorrect results.

To backfill values safely while keeping counter cache columns updated with child
record creation/removal and ensuring methods always get results from the
database (avoiding potentially incorrect counter cache values), use
counter_cache: { active: false }. This setting ensures that methods always
fetch results from the database, avoiding incorrect values from an uninitialized
counter cache. If you need to specify a custom column name, use counter_cache:
{ active: false, column: :my_custom_counter }.

If for some reason you change the value of an owner model's primary key, and do
not also update the foreign keys of the counted models, then the counter cache
may have stale data. In other words, any orphaned models will still count
towards the counter. To fix a stale counter cache, use
reset_counters.

### 8.4. Callbacks

Normal callbacks hook into the life cycle of
Active Record objects, allowing you to work with those objects at various
points. For example, you can use a :before_save callback to cause something to
happen just before an object is saved.

Association callbacks are similar to normal callbacks, but they are triggered by
events in the life cycle of a collection associated with an Active Record
object. There are four available association callbacks:

- before_add

- after_add

- before_remove

- after_remove

You define association callbacks by adding options to the association
declaration. For example:

```ruby
class Author < ApplicationRecord
  has_many :books, before_add: :check_credit_limit

  def check_credit_limit(book)
    throw(:abort) if limit_reached?
  end
end
```

In this example, the Author model has a has_many association with books.
The before_add callback check_credit_limit is triggered before a book is
added to the collection. If the limit_reached? method returns true, the book
is not added to the collection.

By using these association callbacks, you can customize the behavior of your
associations, ensuring that specific actions are taken at key points in the life
cycle of your collections.

Read more about association callbacks in the Active Record Callbacks
Guide

### 8.5. Extensions

Rails provides the ability to extend the functionality of association proxy
objects, which manage associations, by adding new finders, creators, or other
methods through anonymous modules. This feature allows you to customize
associations to meet the specific needs of your application.

You can extend a has_many association with custom methods directly within the
model definition. For example:

```ruby
class Author < ApplicationRecord
  has_many :books do
    def find_by_book_prefix(book_number)
      find_by(category_id: book_number[0..2])
    end
  end
end
```

In this example, the find_by_book_prefix method is added to the books
association of the Author model. This custom method allows you to find books
based on a specific prefix of the book_number.

If you have an extension that should be shared by multiple associations, you can
use a named extension module. For example:

```ruby
module FindRecentExtension
  def find_recent
    where("created_at > ?", 5.days.ago)
  end
end

class Author < ApplicationRecord
  has_many :books, -> { extending FindRecentExtension }
end

class Supplier < ApplicationRecord
  has_many :deliveries, -> { extending FindRecentExtension }
end
```

In this case, the FindRecentExtension module is used to add a find_recent
method to both the books association in the Author model and the
deliveries association in the Supplier model. This method retrieves records
created within the last five days.

Extensions can interact with the internals of the association proxy using the
proxy_association accessor. The proxy_association provides three important
attributes:

- proxy_association.owner returns the object that the association is a part
of.

- proxy_association.reflection returns the reflection object that describes
the association.

- proxy_association.target returns the associated object for belongs_to or
has_one, or the collection of associated objects for has_many or
has_and_belongs_to_many.

These attributes allow extensions to access and manipulate the association
proxy's internal state and behavior.

Here's an advanced example demonstrating how to use these attributes in an
extension:

```ruby
module AdvancedExtension
  def find_and_log(query)
    results = where(query)
    proxy_association.owner.logger.info("Querying #{proxy_association.reflection.name} with #{query}")
    results
  end
end

class Author < ApplicationRecord
  has_many :books, -> { extending AdvancedExtension }
end
```

In this example, the find_and_log method performs a query on the association
and logs the query details using the owner's logger. The method accesses the
owner's logger via proxy_association.owner and the association's name via
proxy_association.reflection.name.

---

# Chapters

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
