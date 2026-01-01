# PostgreSQL Performance Best Practices for Rails

This reference contains key performance concepts and recommendations from "High Performance PostgreSQL for Rails" by Andrew Atkinson.

## Index Optimization

### Foreign Key Indexes
Always add indexes to foreign key columns. PostgreSQL doesn't automatically index foreign keys.

```ruby
# Migration example
add_index :posts, :user_id
add_index :comments, :post_id
```

### Partial Indexes for Boolean Columns
When querying boolean columns for one value much more than another, use partial indexes.

```ruby
# For columns where you mainly query for true values
add_index :users, :active, where: "active = true"
add_index :posts, :published, where: "published = true"
```

### Composite Indexes
Order matters! Place the most selective column first, or the column used most often in WHERE clauses.

```ruby
# Good: If you often filter by status and then created_at
add_index :orders, [:status, :created_at]

# Also consider standalone indexes for individual columns
add_index :orders, :status
add_index :orders, :created_at
```

### Covering Indexes
Include additional columns in the index to avoid table lookups.

```ruby
# Query frequently selects email along with user_id
add_index :posts, :user_id, include: [:email]
```

### Expression Indexes
Index computed or transformed values that are frequently queried.

```ruby
# For case-insensitive email lookups
add_index :users, "lower(email)", name: "index_users_on_lower_email"
```

### GIN Indexes for JSON/Array Columns
Use GIN indexes for PostgreSQL JSON and array columns.

```ruby
add_index :products, :metadata, using: :gin
add_index :posts, :tags, using: :gin
```

### Index Maintenance
- Remove unused indexes (they slow down writes)
- Rebuild bloated indexes with `REINDEX CONCURRENTLY`
- Use pg_stat_user_indexes to monitor index usage

## Query Optimization

### N+1 Query Prevention

#### Problem Pattern
```ruby
# Controller - loads users
@users = User.all

# View - triggers N+1 queries
@users.each do |user|
  user.posts.each do |post|  # N queries for posts
    post.comments.count        # N*M queries for comment counts
  end
end
```

#### Solution: Eager Loading
```ruby
# Load all associations upfront
@users = User.includes(posts: :comments).all

# For counting, use counter caches instead of .count
@users = User.includes(:posts).all
```

### Eager Loading Methods

**includes()** - Loads associations (uses LEFT OUTER JOIN or separate queries)
```ruby
User.includes(:posts)
User.includes(posts: :comments)
```

**preload()** - Always uses separate queries
```ruby
User.preload(:posts)
```

**eager_load()** - Always uses LEFT OUTER JOIN
```ruby
User.eager_load(:posts)
```

**strict_loading** - Prevents lazy loading (raises error)
```ruby
# In model
class User < ApplicationRecord
  has_many :posts, strict_loading: true
end

# Or per-query
User.strict_loading.all
```

### Counter Caches
Avoid counting associations at query time. Cache the count.

```ruby
# In migration
add_column :users, :posts_count, :integer, default: 0, null: false

# In model
class Post < ApplicationRecord
  belongs_to :user, counter_cache: true
end

# Use it
user.posts_count  # No query needed!
```

### Batch Processing
Use find_each/in_batches for processing large datasets.

```ruby
# Bad: Loads all records into memory
User.all.each { |user| user.process }

# Good: Processes in batches of 1000
User.find_each(batch_size: 1000) { |user| user.process }
```

### Select Only Needed Columns
Don't load columns you don't need.

```ruby
# Bad: Loads all columns
User.all

# Good: Only loads id and email
User.select(:id, :email)
```

## Database Configuration

### Connection Pool Sizing
Match your pool size to your web server threads/workers.

```yaml
# database.yml
production:
  pool: <%= ENV.fetch("RAILS_MAX_THREADS") { 5 } %>
```

Formula: `pool_size = (web_server_processes * threads_per_process)`

### Timeouts
Set appropriate timeouts to prevent hanging connections and long-running queries.

```yaml
production:
  connect_timeout: 5          # Connection timeout in seconds
  checkout_timeout: 5         # Pool checkout timeout in seconds
  variables:
    statement_timeout: 30000  # Query timeout in milliseconds (30s)
    lock_timeout: 5000        # Lock wait timeout in milliseconds (5s)
```

### Prepared Statements
Keep enabled unless using PgBouncer in transaction mode.

```yaml
production:
  prepared_statements: true  # Default, improves performance
```

### Connection Reaping
Clean up stale connections periodically.

```yaml
production:
  reaping_frequency: 60  # Check every 60 seconds
```

## Query Analysis with EXPLAIN

Use EXPLAIN ANALYZE to understand query performance.

```ruby
# In Rails console
User.where(status: 'active').explain

# Or in PostgreSQL
EXPLAIN ANALYZE SELECT * FROM users WHERE status = 'active';
```

### Key Metrics to Watch
- **Seq Scan**: Sequential scan (table scan) - usually slow for large tables
- **Index Scan**: Using an index - usually good
- **Rows**: Estimated vs actual rows - large differences indicate statistics issues
- **Cost**: Query planner's cost estimate
- **Execution Time**: Actual time taken

### Common Issues
- **Sequential Scans on Large Tables**: Add an index
- **Large Row Estimate Differences**: Run ANALYZE
- **Nested Loop with Many Rows**: Consider a different join strategy
- **High Cost**: Query might need optimization or better indexes

## Vacuum and Statistics

### Autovacuum
PostgreSQL's autovacuum reclaims dead tuples and updates statistics. Ensure it's running.

```sql
-- Check autovacuum status
SELECT schemaname, relname, last_autovacuum, last_autoanalyze
FROM pg_stat_user_tables
ORDER BY last_autovacuum;
```

### Manual ANALYZE
Update statistics after bulk data changes.

```sql
-- Analyze all tables
ANALYZE;

-- Analyze specific table
ANALYZE users;
```

## Bulk Operations

### Bulk Inserts
Use insert_all for bulk inserts (Rails 6+).

```ruby
# Bad: N INSERT queries
users.each { |user| User.create(user) }

# Good: Single INSERT with multiple VALUES
User.insert_all(users)
```

### Bulk Updates
Use update_all or update_counters for bulk updates.

```ruby
# Bad: N UPDATE queries
User.where(status: 'pending').each { |u| u.update(status: 'active') }

# Good: Single UPDATE query
User.where(status: 'pending').update_all(status: 'active')
```

### Upserts (INSERT ON CONFLICT)
Use upsert_all for insert-or-update operations.

```ruby
User.upsert_all(
  users,
  unique_by: :email,
  update_only: [:name, :updated_at]
)
```

## Schema Design Best Practices

### Use Appropriate Data Types
- Use `bigint` for primary keys if you expect high volume
- Use `text` instead of `varchar` (no performance difference in PostgreSQL)
- Use `timestamptz` for timestamps (stores timezone)
- Use `jsonb` not `json` (binary format, indexable)

### Constraints and Validation
Add database constraints for data integrity.

```ruby
# In migration
add_foreign_key :posts, :users
add_check_constraint :products, "price > 0", name: "positive_price"
add_not_null_constraint :users, :email
```

### Enum vs String Columns
For limited set of values, consider PostgreSQL enums or constrained strings.

```ruby
# String with constraint
add_column :orders, :status, :string
add_check_constraint :orders, "status IN ('pending', 'shipped', 'delivered')"

# Or PostgreSQL enum (harder to change)
execute "CREATE TYPE order_status AS ENUM ('pending', 'shipped', 'delivered')"
add_column :orders, :status, :order_status
```

## Monitoring and Observability

### Essential Extensions
Enable these extensions in PostgreSQL:

```sql
-- Query statistics
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;

-- Index bloat checking
CREATE EXTENSION IF NOT EXISTS pgstattuple;
```

### Key Metrics to Monitor
- Active connections vs connection pool size
- Slow queries (via pg_stat_statements)
- Cache hit ratio (should be > 90%)
- Index usage vs sequential scans
- Table and index bloat
- Lock waits and deadlocks

### Tools
- **PgHero**: Web dashboard for PostgreSQL monitoring
- **pg_stat_statements**: Query performance statistics
- **EXPLAIN ANALYZE**: Query execution plans
- **Rails query logs**: Enable in development for visibility

## Common Performance Patterns

### Pagination
Use keyset pagination for better performance on large datasets.

```ruby
# Bad: OFFSET pagination (slow for large offsets)
User.limit(20).offset(1000)

# Good: Keyset pagination
User.where('id > ?', last_id).limit(20)
```

### Full-Text Search
Use PostgreSQL's built-in full-text search with GIN indexes.

```ruby
# Add tsvector column
add_column :posts, :search_vector, :tsvector
add_index :posts, :search_vector, using: :gin

# Update trigger to maintain it
execute <<-SQL
  CREATE TRIGGER posts_search_vector_update
  BEFORE INSERT OR UPDATE ON posts
  FOR EACH ROW EXECUTE FUNCTION
  tsvector_update_trigger(search_vector, 'pg_catalog.english', title, body);
SQL

# Query it
Post.where("search_vector @@ plainto_tsquery(?)", "rails postgresql")
```

### Materialized Views
Cache complex query results.

```ruby
# Create materialized view
execute <<-SQL
  CREATE MATERIALIZED VIEW user_statistics AS
  SELECT user_id, COUNT(*) as post_count, MAX(created_at) as last_post
  FROM posts
  GROUP BY user_id;
SQL

# Refresh it
execute "REFRESH MATERIALIZED VIEW CONCURRENTLY user_statistics;"
```
