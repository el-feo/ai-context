---
name: rails
description: Comprehensive Ruby on Rails v8.1 development guide with detailed documentation for Active Record, controllers, views, routing, testing, jobs, mailers, and more. Use when working on Rails applications, building Rails features, debugging Rails code, writing migrations, setting up associations, configuring Rails apps, or answering questions about Rails best practices and patterns.
---

# Rails v8.1 Development Guide

Reference documentation based on the official Rails Guides v8.1.1, organized by topic. Each reference file has a table of contents. Consult the relevant file when working on specific Rails components.

## Reference Navigation

### Active Record

Split across 4 files by topic:

- **[active_record_basics.md](references/active_record_basics.md)** (5,800 lines) — Models, CRUD, naming conventions, migrations, validations, callbacks
- **[active_record_queries.md](references/active_record_queries.md)** (2,700 lines) — Query interface, conditions, ordering, joins, eager loading, scopes, calculations
- **[active_record_associations.md](references/active_record_associations.md)** (3,400 lines) — Association types, configuration, STI, delegated types, reference
- **[active_record_advanced.md](references/active_record_advanced.md)** (4,100 lines) — Active Model, PostgreSQL features, multiple databases, composite primary keys, encryption

### Controllers & Views

- **[controllers.md](references/controllers.md)** (1,900 lines) — Action Controller basics, strong params, cookies, sessions, callbacks, CSRF, HTTP auth, streaming, error handling
- **[views.md](references/views.md)** (4,800 lines) — Action View, templates, partials, layouts, view helpers, form helpers, rendering

### Configuration & Internals

- **[configuration.md](references/configuration.md)** (4,750 lines) — Rails config options, versioned defaults, environment settings, initializers, load hooks, initialization process
- **[internals_autoloading.md](references/internals_autoloading.md)** (915 lines) — Zeitwerk autoloading, reloading, eager loading, threading, concurrency
- **[internals_engines_cli.md](references/internals_engines_cli.md)** (3,920 lines) — Rack middleware, Rails engines, CLI tools, custom generators

### Other References

- **[testing_debugging.md](references/testing_debugging.md)** (3,700 lines) — Unit/integration/system tests, fixtures, debugging
- **[jobs_mailers_cable.md](references/jobs_mailers_cable.md)** (3,650 lines) — Active Job, Action Mailer, Action Mailbox, Action Cable
- **[i18n_support.md](references/i18n_support.md)** (5,700 lines) — I18n, locale files, Active Support core extensions, instrumentation
- **[storage_caching.md](references/storage_caching.md)** (2,450 lines) — Active Storage file uploads, caching strategies
- **[security_performance.md](references/security_performance.md)** (2,270 lines) — XSS, CSRF, SQL injection prevention, performance tuning
- **[assets_frontend.md](references/assets_frontend.md)** (2,080 lines) — Asset pipeline, JavaScript bundling, CSS, Action Text
- **[routing.md](references/routing.md)** (1,380 lines) — RESTful routing, nested routes, constraints, concerns
- **[api_development.md](references/api_development.md)** (585 lines) — API-only apps, serialization, authentication, versioning, CORS

## Version Notes

Rails 8.1.1 key features:
- Solid Queue, Solid Cache, Solid Cable for built-in infrastructure
- Enhanced Turbo integration
- Improved authentication generators
- Progressive Web App features
