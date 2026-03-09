---
name: postgresql-rails-analyzer
description: Comprehensive PostgreSQL configuration and usage analysis for Rails applications. Use when Claude Code needs to analyze a Rails codebase for database performance issues, optimization opportunities, or best practice violations. Detects N+1 queries, missing indexes, suboptimal database configurations, anti-patterns, and provides actionable recommendations. Ideal for performance audits, optimization tasks, or when users ask to "analyze the database", "check for N+1 queries", "optimize PostgreSQL", "review database performance", or "suggest database improvements".
---

# PostgreSQL Rails Analyzer

Analyze Rails applications for PostgreSQL performance issues and provide actionable optimization recommendations based on "High Performance PostgreSQL for Rails" best practices.

## Analysis Scripts

Run from the Rails application root directory:

### 1. N+1 Query Analysis

```bash
ruby scripts/analyze_n_plus_one.rb
```

Detects potential N+1 query issues by analyzing:

- Controller actions for queries without eager loading
- View files for association access patterns
- Missing `includes`, `preload`, or `eager_load` calls

### 2. Index Analysis

```bash
ruby scripts/analyze_indexes.rb
```

Identifies indexing opportunities:

- Foreign keys without indexes (critical)
- Boolean columns that could benefit from partial indexes
- Columns frequently used in WHERE clauses
- Missing composite indexes

### 3. Configuration Analysis

```bash
ruby scripts/analyze_config.rb
```

Reviews database.yml for:

- Connection pool sizing
- Timeout configurations (statement_timeout, lock_timeout)
- Prepared statements settings
- SSL/TLS configuration
- Connection reaping configuration
- Recommended PostgreSQL extensions

## Workflow

### Step 1: Understand the Request

Clarify what the user wants to analyze: full performance audit, specific issue (slow queries, N+1 problems), configuration review, or schema optimization.

### Step 2: Run Appropriate Analysis Scripts

```bash
# For comprehensive analysis, run all three
ruby scripts/analyze_n_plus_one.rb
ruby scripts/analyze_indexes.rb
ruby scripts/analyze_config.rb
```

### Step 3: Review Results

Script output categorizes issues by severity:

- **WARNING**: High-priority issues that likely impact performance
- **INFO**: Optimization opportunities and best practice recommendations

### Step 4: Provide Recommendations

Create a prioritized list of actionable recommendations:

1. **Critical Issues** (fix immediately) — FK indexes, N+1 in hot paths, missing timeouts
2. **Performance Optimizations** (high impact) — partial indexes, counter caches, eager loading
3. **Best Practices** (preventative) — configuration tuning, pool optimization, monitoring

### Step 5: Generate Migration Code

For index and schema recommendations, provide ready-to-use migration code. Use `algorithm: :concurrently` for production migrations to avoid locking tables.

```ruby
class AddPerformanceIndexes < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def change
    add_index :posts, :user_id, algorithm: :concurrently
    add_index :users, :active, where: "active = false", algorithm: :concurrently
    add_index :orders, [:status, :created_at], algorithm: :concurrently
  end
end
```

### Step 6: Reference Additional Documentation

Load these references when users need deeper understanding:

- `references/performance_guide.md` — comprehensive best practices (indexes, queries, config, schema design, monitoring)
- `references/anti_patterns.md` — 25 common mistakes organized by category (queries, indexes, schema, config, transactions)

## Advanced Analysis

For deeper analysis beyond the scripts, manually review:

- **Schema Design** — data types (bigint for high-volume PKs, jsonb vs json), constraints (NOT NULL, CHECK, FOREIGN KEY)
- **Query Patterns** — use `rails c` to run EXPLAIN ANALYZE on slow queries, check for sequential scans on large tables
- **Model Code** — missing counter caches, batch operation opportunities (`find_each` instead of `each`)

## Limitations

These analysis scripts use static analysis. They may produce false positives (flagging non-issues) or false negatives (missing runtime-only issues). Always recommend testing fixes in staging and using EXPLAIN ANALYZE to verify.

## Complementary Tools

Suggest for ongoing monitoring: **PgHero** (dashboard), **pg_stat_statements** (query stats), **Bullet gem** (runtime N+1 detection), **Rails query logging** (development visibility).
