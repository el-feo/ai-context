# Rails Application Template Patterns

Application templates are Ruby scripts that configure a whole Rails application — adding gems, running installers, creating files, and modifying configuration. They use the same Thor action DSL as custom generators but run against the entire app rather than generating a single component.

## Table of Contents

- [Templates vs Generators](#templates-vs-generators)
- [Invocation](#invocation)
- [Template Structure](#template-structure)
- [The Application Template DSL](#the-application-template-dsl)
- [Prefer Gem Installers Over Hand-Rolled Setup](#prefer-gem-installers-over-hand-rolled-setup)
- [Idempotency Guards](#idempotency-guards)
- [Interactive Prompts](#interactive-prompts)
- [Composing Templates](#composing-templates)
- [Common Gotchas](#common-gotchas)
- [Verifying the Template](#verifying-the-template)

## Templates vs Generators

| | Custom generator | Application template |
|---|---|---|
| Invoked with | `rails generate foo` | `rails new app -m template.rb` or `bin/rails app:template` |
| Scope | One component (model, service, controller) | Whole-app setup (gems, auth, config, features) |
| Lives in | `lib/generators/` inside an app or gem | Standalone `.rb` file (local path or URL) |
| Base class | `Rails::Generators::Base` / `NamedBase` | None — top-level script evaluated in a `Rails::Generators::AppGenerator` context |
| Repeatable | Yes, designed for repeated use | Usually once per app; guard against re-runs |

Use a generator when the team will invoke it repeatedly inside one app. Use an application template when standing up new apps from a starter (or retrofitting a feature set like authentication or multi-tenancy onto an existing app).

## Invocation

```bash
# Apply while creating a new app
rails new myapp -m path/to/template.rb

# Apply to an existing app
bin/rails app:template LOCATION=path/to/template.rb

# Templates can also be loaded from a URL
rails new myapp -m https://example.com/template.rb
```

## Template Structure

A well-structured template follows this order:

```ruby
#!/usr/bin/env ruby
# frozen_string_literal: true

# 1. Make relative paths (partials, copied files) resolve next to the template
def source_paths
  [__dir__]
end

# 2. Guard against double application (see Idempotency Guards)
if File.exist?('app/models/organization.rb')
  say "Template already applied. Exiting.", :red
  exit 1
end

# 3. Add gems, then install
gem 'devise', comment: 'Authentication (https://github.com/heartcombo/devise)'
gem_group :development do
  gem 'letter_opener', comment: 'Preview email in the browser'
end
run 'bundle install'

# 4. Run the gems' own install generators
generate 'devise:install'
generate 'devise', 'User'

# 5. Create/modify application files
create_file 'app/models/organization.rb', <<~RUBY
  class Organization < ApplicationRecord
    validates :name, presence: true, uniqueness: true
  end
RUBY

# 6. Migrate and verify
rails_command 'db:migrate'
run 'bundle exec rspec'

say "✅ Setup complete!", :green
```

Progress output with `say` (optionally colored: `:green`, `:yellow`, `:red`) keeps long-running templates legible.

## The Application Template DSL

All Thor actions from generators are available (`create_file`, `template`, `inject_into_file`, `gsub_file`, `insert_into_file`, `route`, `initializer` — see [file-actions.md](file-actions.md)), plus app-template-specific methods:

```ruby
# Gemfile management
gem 'sidekiq'
gem 'rspec-rails', group: [:development, :test]
gem_group :development, :test do
  gem 'factory_bot_rails'
end
add_source 'https://gems.example.com'

# Environment configuration
environment 'config.active_job.queue_adapter = :sidekiq'
environment 'config.action_mailer.delivery_method = :letter_opener', env: 'development'

# Run generators and commands
generate 'devise:install'
generate 'model', 'Organization', 'name:string', 'description:text'
rails_command 'db:migrate'
rails_command 'db:seed', abort_on_failure: true
rake 'assets:precompile', env: 'production'
run 'bundle exec rubocop -a'

# Files under lib/ and vendor/
lib 'tenant_utils.rb', <<~RUBY
  module TenantUtils
  end
RUBY
vendor 'styles.css', '.tenant-badge { color: red; }'

# Git operations
git :init
git add: '.', commit: %(-m 'Apply multi-tenant template')

# Defer work until after bundle install completes (rails new only)
after_bundle do
  rails_command 'db:migrate'
  git add: '.', commit: %(-m 'Initial commit')
end
```

When run via `rails new -m`, gems added at the top are installed by the initial `bundle install`; use `after_bundle` for steps that need the bundle. When run via `app:template` against an existing app, call `run 'bundle install'` explicitly after adding gems and before invoking their generators.

## Prefer Gem Installers Over Hand-Rolled Setup

Always use the install generators provided by the gems rather than hand-writing their configuration:

```ruby
generate 'devise:install'        # not: create_file 'config/initializers/devise.rb', ...
generate 'devise', 'User'
generate 'devise:views'
generate 'action_policy:install'
generate 'flipper:setup'
```

Gem installers track the gem's current version; hand-written config drifts and encodes assumptions from whenever the template was written. Reserve `create_file`/`inject_into_file` for your application code and for post-install customization of what the installer produced.

## Idempotency Guards

Application templates modify files with `inject_into_file` and `gsub_file`, so a second run corrupts the app (duplicate injections, double routes). Guard at the top:

```ruby
def template_already_applied?
  return true if File.exist?('app/models/organization.rb')

  routes_content = File.read('config/routes.rb') rescue ""
  return true if routes_content.include?('devise_for :users')

  begin
    ActiveRecord::Base.connection.execute('SELECT 1 FROM organizations LIMIT 1')
    return true
  rescue ActiveRecord::StatementInvalid, ActiveRecord::NoDatabaseError
    # table doesn't exist — safe to proceed
  end

  false
end

if template_already_applied?
  say '❌ Template already applied. Restore from git to reapply.', :red
  exit 1
end
```

Check several signals (key files, route contents, database tables) — a partial prior run may have created some but not others.

## Interactive Prompts

```ruby
app_name = ask('What is the product name?')
use_api = yes?('Generate API endpoints? (y/n)')

gem 'jbuilder' if use_api
```

Prompts make a template flexible but break unattended use (CI, scripted app creation). Prefer detecting from the environment or reading an ENV variable, and fall back to a prompt:

```ruby
use_api = ENV.fetch('TEMPLATE_API', nil) == 'true' || yes?('Generate API endpoints? (y/n)')
```

## Composing Templates

Split large setups into focused templates and compose them with `apply`:

```ruby
# main_template.rb
def source_paths
  [__dir__]
end

apply 'authentication_template.rb'
apply 'multitenant_template.rb'
apply 'admin_template.rb'
```

Each sub-template stays independently applicable (with its own guard), which makes them testable in isolation and lets existing apps adopt one feature set at a time.

## Common Gotchas

**Migration timestamp collisions**: creating migrations with `create_file "db/migrate/#{Time.now.strftime('%Y%m%d%H%M%S')}_..."` in a loop produces duplicate timestamps. Prefer `generate 'migration', 'CreateOrganizations', 'name:string'` or the gem's generators, which handle sequencing. If you must hand-create several, sleep between them — but treat that as a smell.

**Escaping interpolation in heredocs**: Ruby code written inside a template's heredoc that itself contains `#{}` must be escaped (`\#{user.name}`) or the template evaluates it at apply time. Use `<<~'RUBY'` (single-quoted heredoc) when the generated code needs literal interpolation and the template needs none.

**`gsub_file` with brittle regexes**: matching multi-line method bodies with `/def index.*?end/m` breaks silently when the target app's code differs from what the template expects. Prefer `inject_into_file` anchored on stable lines (class definitions, `Rails.application.routes.draw do`), and verify with tests after applying.

**Devise and mailer hosts**: templates that add Devise must also set `config.action_mailer.default_url_options` in development or the first sign-up email raises.

## Verifying the Template

A template is code — test it by applying it:

```bash
# Fresh-app path
rails new /tmp/template_check -m path/to/template.rb

# Existing-app path (from a clean git state)
cd existing-app
git status --porcelain   # must be empty first
bin/rails app:template LOCATION=path/to/template.rb
git diff                 # review every change the template made
bundle exec rspec
git checkout . && git clean -fd   # reset for the next iteration
```

End the template itself with the app's test suite (`run 'bundle exec rspec'`) so a broken application fails loudly at apply time, not at first boot. See [multitenant-template.md](multitenant-template.md) for a complete worked example.

## Sources

- [Rails Application Templates — Ruby on Rails Guides](https://guides.rubyonrails.org/rails_application_templates.html)
- [Creating and Customizing Rails Generators & Templates — Ruby on Rails Guides](https://guides.rubyonrails.org/generators.html)
