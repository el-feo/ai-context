# Common PostgreSQL Anti-Patterns in Rails

This reference documents common performance anti-patterns and their solutions.

## Query Anti-Patterns

### 1. The N+1 Query Problem

**Anti-pattern:**

```ruby
# Controller
@posts = Post.limit(10)

# View
<% @posts.each do |post| %>
  <%= post.title %>
  <%= post.user.name %>        # 1 query per post
  <%= post.comments.count %>    # 1 query per post
<% end %>
```

**Result:** 1 query for posts + 10 queries for users + 10 queries for comment counts = 21 queries

**Solution:**

```ruby
# Controller
@posts = Post.includes(:user).limit(10)

# Better: add counter_cache for comments
@posts = Post.includes(:user).limit(10)
# Then use post.comments_count instead of post.comments.count
```

### 2. Counting with .count Instead of Counter Cache

**Anti-pattern:**

```ruby
# Triggers a COUNT query every time
user.posts.count
```

**Solution:**

```ruby
# Add counter cache column
add_column :users, :posts_count, :integer, default: 0, null: false

# Enable in model
class Post < ApplicationRecord
  belongs_to :user, counter_cache: true
end

# Use it
user.posts_count  # No query!
```

### 3. Loading All Records Before Iteration

**Anti-pattern:**

```ruby
# Loads all million users into memory
User.all.each do |user|
  user.send_email
end
```

**Solution:**

```ruby
# Process in batches
User.find_each(batch_size: 1000) do |user|
  user.send_email
end
```

### 4. Using .exists? with .any?

**Anti-pattern:**

```ruby
# Loads all records into memory then checks
if user.posts.any?
  # do something
end
```

**Solution:**

```ruby
# Just checks existence with a LIMIT 1 query
if user.posts.exists?
  # do something
end
```

### 5. Pluck with Multiple Queries

**Anti-pattern:**

```ruby
# Two separate queries
user_ids = User.where(active: true).pluck(:id)
names = User.where(active: true).pluck(:name)
```

**Solution:**

```ruby
# Single query
users = User.where(active: true).pluck(:id, :name)
# Returns array of arrays: [[1, "Alice"], [2, "Bob"]]
```

### 6. Loading Full Objects for Attributes

**Anti-pattern:**

```ruby
# Loads all columns for all users
User.where(active: true).map(&:email)
```

**Solution:**

```ruby
# Only loads email column
User.where(active: true).pluck(:email)
```

### 7. Counting with size vs count vs length

**Anti-pattern:**

```ruby
# Wrong choice can cause performance issues
users = User.where(active: true)
users.length  # Always loads all records
```

**Solution:**

```ruby
# .count - executes COUNT query (use for unloaded collections)
User.where(active: true).count

# .size - smart choice (uses count if unloaded, length if loaded)
users = User.where(active: true)
users.size

# .length - array length (use only for already-loaded collections)
users.to_a.length
```

## Index Anti-Patterns

### 8. Missing Foreign Key Indexes

**Anti-pattern:**

```ruby
# Foreign key without index
create_table :posts do |t|
  t.belongs_to :user
end
```

**Problem:** Slow joins and cascading deletes

**Solution:**

```ruby
# Always index foreign keys
create_table :posts do |t|
  t.belongs_to :user, index: true
end
```

### 9. Indexing Low-Cardinality Boolean Columns

**Anti-pattern:**

```ruby
# Full index on boolean column
add_index :users, :active
```

**Problem:** Inefficient for highly skewed data (e.g., 99% true, 1% false)

**Solution:**

```ruby
# Partial index for the minority value
add_index :users, :active, where: "active = false"
```

### 10. Wrong Index Column Order

**Anti-pattern:**

```ruby
# Querying: WHERE status = 'active' AND created_at > '2024-01-01'
add_index :orders, [:created_at, :status]
```

**Problem:** Index may not be used efficiently

**Solution:**

```ruby
# Put more selective column first
add_index :orders, [:status, :created_at]
```

### 11. Duplicate or Redundant Indexes

**Anti-pattern:**

```ruby
add_index :posts, :user_id
add_index :posts, [:user_id, :created_at]
# First index is redundant!
```

**Solution:**

```ruby
# Only keep the composite index
add_index :posts, [:user_id, :created_at]
# PostgreSQL can use this for queries on just user_id too
```

## Schema Anti-Patterns

### 12. Using VARCHAR Instead of TEXT

**Anti-pattern:**

```ruby
t.string :description, limit: 255
# or
t.column :description, :varchar, limit: 255
```

**Problem:** No performance benefit in PostgreSQL, adds maintenance burden

**Solution:**

```ruby
# Use TEXT (no length limit, same performance)
t.text :description
```

### 13. Missing Database Constraints

**Anti-pattern:**

```ruby
# Only Rails validation, no DB constraint
class User < ApplicationRecord
  validates :email, presence: true, uniqueness: true
end
```

**Problem:** Race conditions can create duplicate records

**Solution:**

```ruby
# Add database constraint + Rails validation
class AddEmailConstraints < ActiveRecord::Migration
  def change
    add_index :users, :email, unique: true
    change_column_null :users, :email, false
  end
end
```

### 14. Using JSON Instead of JSONB

**Anti-pattern:**

```ruby
add_column :products, :metadata, :json
```

**Problem:** Can't index json columns efficiently

**Solution:**

```ruby
# Use jsonb (binary JSON, indexable)
add_column :products, :metadata, :jsonb
add_index :products, :metadata, using: :gin
```

### 15. Integer Primary Keys for High-Volume Tables

**Anti-pattern:**

```ruby
create_table :events do |t|
  # Uses integer (max ~2 billion)
  t.timestamps
end
```

**Problem:** Can exhaust integer range on high-volume tables

**Solution:**

```ruby
# Use bigint for primary keys
create_table :events, id: :bigint do |t|
  t.timestamps
end
```

## Configuration Anti-Patterns

### 16. Not Setting Statement Timeout

**Anti-pattern:**

```yaml
# database.yml with no timeout
production:
  adapter: postgresql
  database: myapp_production
```

**Problem:** Runaway queries can hang indefinitely

**Solution:**

```yaml
production:
  adapter: postgresql
  database: myapp_production
  variables:
    statement_timeout: 30000  # 30 seconds
    lock_timeout: 5000        # 5 seconds
```

### 17. Mismatched Connection Pool Size

**Anti-pattern:**

```yaml
# Puma with 5 threads but pool: 2
production:
  pool: 2
```

**Problem:** Connection starvation, blocked threads

**Solution:**

```yaml
# Match pool to threads/workers
production:
  pool: <%= ENV.fetch("RAILS_MAX_THREADS") { 5 } %>
```

### 18. Not Enabling pg_stat_statements

**Anti-pattern:**
Not configuring pg_stat_statements extension

**Problem:** No query performance statistics

**Solution:**

```sql
-- In postgresql.conf
shared_preload_libraries = 'pg_stat_statements'

-- Then restart PostgreSQL and run:
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;
```

## Transaction Anti-Patterns

### 19. Long-Running Transactions

**Anti-pattern:**

```ruby
ActiveRecord::Base.transaction do
  users = User.all
  users.each do |user|
    sleep(1)  # Simulate slow operation
    user.update(processed: true)
  end
end
```

**Problem:** Holds locks, blocks other queries, increases bloat

**Solution:**

```ruby
# Process in smaller transactions or outside transaction
User.find_each do |user|
  user.update(processed: true)
end

# Or use bulk update
User.update_all(processed: true)
```

### 20. Nested Transactions Without Savepoints

**Anti-pattern:**

```ruby
ActiveRecord::Base.transaction do
  user.save!

  # This doesn't create a real nested transaction
  ActiveRecord::Base.transaction do
    post.save!
  end
end
```

**Solution:**

```ruby
# Use requires_new for true nested transactions
ActiveRecord::Base.transaction do
  user.save!

  ActiveRecord::Base.transaction(requires_new: true) do
    post.save!  # Can rollback independently
  end
end
```

## Query Writing Anti-Patterns

### 21. String Interpolation in SQL

**Anti-pattern:**

```ruby
# SQL injection vulnerability!
User.where("email = '#{params[:email]}'")
```

**Solution:**

```ruby
# Use parameter binding
User.where("email = ?", params[:email])
# Or hash syntax
User.where(email: params[:email])
```

### 22. Using LIKE for Exact Matches

**Anti-pattern:**

```ruby
# Slower and can't use index efficiently
User.where("email LIKE ?", email)
```

**Solution:**

```ruby
# Use equality for exact matches
User.where(email: email)
```

### 23. Not Using lower() for Case-Insensitive Searches

**Anti-pattern:**

```ruby
# Case-sensitive search
User.where("email = ?", params[:email].downcase)
```

**Problem:** Relies on application to normalize, can't use index

**Solution:**

```ruby
# Case-insensitive search with expression index
User.where("lower(email) = ?", params[:email].downcase)

# Add expression index
add_index :users, "lower(email)", name: "index_users_on_lower_email"
```

## Maintenance Anti-Patterns

### 24. Not Monitoring Index Usage

**Anti-pattern:**
Creating indexes but never checking if they're used

**Solution:**

```sql
-- Check index usage
SELECT
  schemaname,
  tablename,
  indexname,
  idx_scan,
  idx_tup_read,
  idx_tup_fetch
FROM pg_stat_user_indexes
WHERE idx_scan = 0
ORDER BY idx_scan;
```

### 25. Not Running ANALYZE After Bulk Changes

**Anti-pattern:**

```ruby
# Bulk insert without updating statistics
User.insert_all(10000.times.map { |i| { name: "User #{i}" } })
```

**Problem:** Query planner has outdated statistics

**Solution:**

```ruby
User.insert_all(users)
# Update statistics
ActiveRecord::Base.connection.execute("ANALYZE users")
```
