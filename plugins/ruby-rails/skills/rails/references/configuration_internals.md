# Chapters

This guide covers the configuration and initialization features available to Rails applications.

After reading this guide, you will know:

- How to adjust the behavior of your Rails applications.

- How to add additional code to be run at application start time.

## 1. Locations for Initialization Code

Rails offers four standard spots to place initialization code:

- config/application.rb

- Environment-specific configuration files

- Initializers

- After-initializers

## 2. Running Code Before Rails

In the rare event that your application needs to run some code before Rails itself is loaded, put it above the call to require "rails/all" in config/application.rb.

## 3. Configuring Rails Components

In general, the work of configuring Rails means configuring the components of Rails, as well as configuring Rails itself. The configuration file config/application.rb and environment-specific configuration files (such as config/environments/production.rb) allow you to specify the various settings that you want to pass down to all of the components.

For example, you could add this setting to config/application.rb file:

```ruby
config.time_zone = "Central Time (US & Canada)"
```

This is a setting for Rails itself. If you want to pass settings to individual Rails components, you can do so via the same config object in config/application.rb:

```ruby
config.active_record.schema_format = :ruby
```

Rails will use that particular setting to configure Active Record.

Use the public configuration methods over calling directly to the associated class. e.g. Rails.application.config.action_mailer.options instead of ActionMailer::Base.options.

If you need to apply configuration directly to a class, use a lazy load hook in an initializer to avoid autoloading the class before initialization has completed. This will break because autoloading during initialization cannot be safely repeated when the app reloads.

### 3.1. Versioned Default Values

config.load_defaults loads default configuration values for a target version and all versions prior. For example, config.load_defaults 6.1 will load defaults for all versions up to and including version 6.1.

Below are the default values associated with each target version. In cases of conflicting values, newer versions take precedence over older versions.

#### 3.1.1. Default Values for Target Version 8.1

- config.action_controller.action_on_path_relative_redirect: :raise

- config.action_controller.escape_json_responses: false

- config.action_view.remove_hidden_field_autocomplete: true

- config.action_view.render_tracker: :ruby

- config.active_record.raise_on_missing_required_finder_order_columns: true

- config.active_support.escape_js_separators_in_json: false

- config.yjit: !Rails.env.local?

#### 3.1.2. Default Values for Target Version 8.0

- Regexp.timeout: 1

- config.action_dispatch.strict_freshness: true

#### 3.1.3. Default Values for Target Version 7.2

- config.active_record.postgresql_adapter_decode_dates: true

- config.active_record.validate_migration_timestamps: true

- config.active_storage.web_image_content_types: %w( image/png image/jpeg image/gif image/webp )

- config.yjit: true

#### 3.1.4. Default Values for Target Version 7.1

- config.action_dispatch.debug_exception_log_level: :error

- config.action_dispatch.default_headers: { "X-Frame-Options" => "SAMEORIGIN", "X-XSS-Protection" => "0", "X-Content-Type-Options" => "nosniff", "X-Permitted-Cross-Domain-Policies" => "none", "Referrer-Policy" => "strict-origin-when-cross-origin" }

- config.action_text.sanitizer_vendor: Rails::HTML::Sanitizer.best_supported_vendor

- config.action_view.sanitizer_vendor: Rails::HTML::Sanitizer.best_supported_vendor

- config.active_record.before_committed_on_all_records: true

- config.active_record.belongs_to_required_validates_foreign_key: false

- config.active_record.default_column_serializer: nil

- config.active_record.encryption.hash_digest_class: OpenSSL::Digest::SHA256

- config.active_record.encryption.support_sha1_for_non_deterministic_encryption: false

- config.active_record.generate_secure_token_on: :initialize

- config.active_record.marshalling_format_version: 7.1

- config.active_record.query_log_tags_format: :sqlcommenter

- config.active_record.raise_on_assign_to_attr_readonly: true

- config.active_record.run_after_transaction_callbacks_in_order_defined: true

- config.active_record.run_commit_callbacks_on_first_saved_instances_in_transaction: false

- config.active_record.sqlite3_adapter_strict_strings_by_default: true

- config.active_support.cache_format_version: 7.1

- config.active_support.message_serializer: :json_allow_marshal

- config.active_support.raise_on_invalid_cache_expiration_time: true

- config.active_support.use_message_serializer_for_metadata: true

- config.add_autoload_paths_to_load_path: false

- config.dom_testing_default_html_version: defined?(Nokogiri::HTML5) ? :html5 : :html4

- config.log_file_size: 100 *1024* 1024

- config.precompile_filter_parameters: true

#### 3.1.5. Default Values for Target Version 7.0

- config.action_controller.action_on_open_redirect: :raise

- config.action_controller.wrap_parameters_by_default: true

- config.action_dispatch.cookies_serializer: :json

- config.action_dispatch.default_headers: { "X-Frame-Options" => "SAMEORIGIN", "X-XSS-Protection" => "0", "X-Content-Type-Options" => "nosniff", "X-Download-Options" => "noopen", "X-Permitted-Cross-Domain-Policies" => "none", "Referrer-Policy" => "strict-origin-when-cross-origin" }

- config.action_mailer.smtp_timeout: 5

- config.action_view.apply_stylesheet_media_default: false

- config.action_view.button_to_generates_button_tag: true

- config.active_record.automatic_scope_inversing: true

- config.active_record.partial_inserts: false

- config.active_record.verify_foreign_keys_for_fixtures: true

- config.active_storage.multiple_file_field_include_hidden: true

- config.active_storage.variant_processor: :vips

- config.active_storage.video_preview_arguments: "-vf 'select=eq(n\\,0)+eq(key\\,1)+gt(scene\\,0.015),loop=loop=-1:size=2,trim=start_frame=1' -frames:v 1 -f image2"

- config.active_support.cache_format_version: 7.0

- config.active_support.executor_around_test_case: true

- config.active_support.hash_digest_class: OpenSSL::Digest::SHA256

- config.active_support.key_generator_hash_digest_class: OpenSSL::Digest::SHA256

#### 3.1.6. Default Values for Target Version 6.1

- ActiveSupport.utc_to_local_returns_utc_offset_times: true

- config.action_dispatch.cookies_same_site_protection: :lax

- config.action_dispatch.ssl_default_redirect_status: 308

- config.action_mailbox.queues.incineration: nil

- config.action_mailbox.queues.routing: nil

- config.action_mailer.deliver_later_queue_name: nil

- config.action_view.form_with_generates_remote_forms: false

- config.action_view.preload_links_header: true

- config.active_job.retry_jitter: 0.15

- config.active_record.has_many_inversing: true

- config.active_storage.queues.analysis: nil

- config.active_storage.queues.purge: nil

- config.active_storage.track_variants: true

#### 3.1.7. Default Values for Target Version 6.0

- config.action_dispatch.use_cookies_with_metadata: true

- config.action_mailer.delivery_job: "ActionMailer::MailDeliveryJob"

- config.action_view.default_enforce_utf8: false

- config.active_record.collection_cache_versioning: true

- config.active_storage.queues.analysis: :active_storage_analysis

- config.active_storage.queues.purge: :active_storage_purge

#### 3.1.8. Default Values for Target Version 5.2

- config.action_controller.default_protect_from_forgery: true

- config.action_dispatch.use_authenticated_cookie_encryption: true

- config.action_view.form_with_generates_ids: true

- config.active_record.cache_versioning: true

- config.active_support.hash_digest_class: OpenSSL::Digest::SHA1

- config.active_support.use_authenticated_message_encryption: true

#### 3.1.9. Default Values for Target Version 5.1

- config.action_view.form_with_generates_remote_forms: true

- config.assets.unknown_asset_fallback: false

#### 3.1.10. Default Values for Target Version 5.0

- config.action_controller.forgery_protection_origin_check: true

- config.action_controller.per_form_csrf_tokens: true

- config.active_record.belongs_to_required_by_default: true

- config.ssl_options: { hsts: { subdomains: true } }

### 3.2. Rails General Configuration

The following configuration methods are to be called on a Rails::Railtie object, such as a subclass of Rails::Engine or Rails::Application.

#### 3.2.1. config.add_autoload_paths_to_load_path

Says whether autoload paths have to be added to $LOAD_PATH. It is recommended to be set to false in :zeitwerk mode early, in config/application.rb. Zeitwerk uses absolute paths internally, and applications running in :zeitwerk mode do not need require_dependency, so models, controllers, jobs, etc. do not need to be in $LOAD_PATH. Setting this to false saves Ruby from checking these directories when resolving require calls with relative paths, and saves Bootsnap work and RAM, since it does not need to build an index for them.

The default value depends on the config.load_defaults target version:

The lib directory is not affected by this flag, it is added to $LOAD_PATH always.

#### 3.2.2. config.after_initialize

Takes a block which will be run after Rails has finished initializing the application. That includes the initialization of the framework itself, engines, and all the application's initializers in config/initializers. Note that this block will be run for rake tasks. Useful for configuring values set up by other initializers:

```ruby
config.after_initialize do
  ActionView::Base.sanitized_allowed_tags.delete "div"
end
```

#### 3.2.3. config.after_routes_loaded

Takes a block which will be run after Rails has finished loading the application routes. This block will also be run whenever routes are reloaded.

```ruby
config.after_routes_loaded do
  # Code that does something with Rails.application.routes
end
```

#### 3.2.4. config.allow_concurrency

Controls whether requests should be handled concurrently. This should only
be set to false if application code is not thread safe. Defaults to true.

#### 3.2.5. config.asset_host

Sets the host for the assets. Useful when CDNs are used for hosting assets, or when you want to work around the concurrency constraints built-in in browsers using different domain aliases. Shorter version of config.action_controller.asset_host.

#### 3.2.6. config.assume_ssl

Makes application believe that all requests are arriving over SSL. This is useful when proxying through a load balancer that terminates SSL, the forwarded request will appear as though it's HTTP instead of HTTPS to the application. This makes redirects and cookie security target HTTP instead of HTTPS. This middleware makes the server assume that the proxy already terminated SSL, and that the request really is HTTPS.

#### 3.2.7. config.autoflush_log

Enables writing log file output immediately instead of buffering. Defaults to
true.

#### 3.2.8. config.autoload_lib(ignore:)

This method adds lib to config.autoload_paths and config.eager_load_paths.

Normally, the lib directory has subdirectories that should not be autoloaded or eager loaded. Please, pass their name relative to lib in the required ignore keyword argument. For example,

```ruby
config.autoload_lib(ignore: %w(assets tasks generators))
```

Please, see more details in the autoloading guide.

#### 3.2.9. config.autoload_lib_once(ignore:)

The method config.autoload_lib_once is similar to config.autoload_lib, except that it adds lib to config.autoload_once_paths instead.

By calling config.autoload_lib_once, classes and modules in lib can be autoloaded, even from application initializers, but won't be reloaded.

#### 3.2.10. config.autoload_once_paths

Accepts an array of paths from which Rails will autoload constants that won't be wiped per request. Relevant if reloading is enabled, which it is by default in the development environment. Otherwise, all autoloading happens only once. All elements of this array must also be in autoload_paths. Default is an empty array.

#### 3.2.11. config.autoload_paths

Accepts an array of paths from which Rails will autoload constants. Default is an empty array. Since Rails 6, it is not recommended to adjust this. See Autoloading and Reloading Constants.

#### 3.2.12. config.beginning_of_week

Sets the default beginning of week for the
application. Accepts a valid day of week as a symbol (e.g. :monday).

#### 3.2.13. config.cache_classes

Old setting equivalent to !config.enable_reloading. Supported for backwards compatibility.

#### 3.2.14. config.cache_store

Configures which cache store to use for Rails caching. Options include one of the symbols :memory_store, :file_store, :mem_cache_store, :null_store, :redis_cache_store, or an object that implements the cache API. Defaults to :file_store. See Cache Stores for per-store configuration options.

#### 3.2.15. config.colorize_logging

Specifies whether or not to use ANSI color codes when logging information. Defaults to true.

#### 3.2.16. config.consider_all_requests_local

Is a flag. If true then any error will cause detailed debugging information to be dumped in the HTTP response, and the Rails::Info controller will show the application runtime context in /rails/info/properties. true by default in the development and test environments, and false in production. For finer-grained control, set this to false and implement show_detailed_exceptions? in controllers to specify which requests should provide debugging information on errors.

#### 3.2.17. config.console

Allows you to set the class that will be used as console when you run bin/rails console. It's best to run it in the console block:

```ruby
console do
  # this block is called only when running console,
  # so we can safely require pry here
  require "pry"
  config.console = Pry
end
```

#### 3.2.18. config.content_security_policy_nonce_auto

See Adding a Nonce in the Security Guide

#### 3.2.19. config.content_security_policy_nonce_directives

See Adding a Nonce in the Security Guide

#### 3.2.20. config.content_security_policy_nonce_generator

See Adding a Nonce in the Security Guide

#### 3.2.21. config.content_security_policy_report_only

See Reporting Violations in the Security
Guide

#### 3.2.22. config.credentials.content_path

The path of the encrypted credentials file.

Defaults to config/credentials/#{Rails.env}.yml.enc if it exists, or
config/credentials.yml.enc otherwise.

In order for the bin/rails credentials commands to recognize this value,
it must be set in config/application.rb or config/environments/#{Rails.env}.rb.

#### 3.2.23. config.credentials.key_path

The path of the encrypted credentials key file.

Defaults to config/credentials/#{Rails.env}.key if it exists, or
config/master.key otherwise.

In order for the bin/rails credentials commands to recognize this value,
it must be set in config/application.rb or config/environments/#{Rails.env}.rb.

#### 3.2.24. config.debug_exception_response_format

Sets the format used in responses when errors occur in the development environment. Defaults to :api for API only apps and :default for normal apps.

#### 3.2.25. config.disable_sandbox

Controls whether or not someone can start a console in sandbox mode. This is helpful to avoid a long running session of sandbox console, that could lead a database server to run out of memory. Defaults to false.

#### 3.2.26. config.dom_testing_default_html_version

Controls whether an HTML4 parser or an HTML5 parser is used by default by the test helpers in Action View, Action Dispatch, and rails-dom-testing.

The default value depends on the config.load_defaults target version:

Nokogiri's HTML5 parser is not supported on JRuby, so on JRuby platforms Rails will fall back to :html4.

#### 3.2.27. config.eager_load

When true, eager loads all registered config.eager_load_namespaces. This includes your application, engines, Rails frameworks, and any other registered namespace.

#### 3.2.28. config.eager_load_namespaces

Registers namespaces that are eager loaded when config.eager_load is set to true. All namespaces in the list must respond to the eager_load! method.

#### 3.2.29. config.eager_load_paths

Accepts an array of paths from which Rails will eager load on boot if config.eager_load is true. Defaults to every folder in the app directory of the application.

#### 3.2.30. config.enable_reloading

If config.enable_reloading is true, application classes and modules are reloaded in between web requests if they change. Defaults to true in the development environment, and false in the production environment.

The predicate config.reloading_enabled? is also defined.

#### 3.2.31. config.encoding

Sets up the application-wide encoding. Defaults to UTF-8.

#### 3.2.32. config.exceptions_app

Sets the exceptions application invoked by the ShowException middleware when an exception happens.
Defaults to ActionDispatch::PublicExceptions.new(Rails.public_path).

#### 3.2.33. config.file_watcher

Is the class used to detect file updates in the file system when config.reload_classes_only_on_change is true. Rails ships with ActiveSupport::FileUpdateChecker, the default, and ActiveSupport::EventedFileUpdateChecker. Custom classes must conform to the ActiveSupport::FileUpdateChecker API.

Using ActiveSupport::EventedFileUpdateChecker depends on the listen gem:

```ruby
group :development do
  gem "listen", "~> 3.5"
end
```

On Linux and macOS no additional gems are needed, but some are required
for *BSD and
for Windows.

Note that some setups are unsupported.

#### 3.2.34. config.filter_parameters

Used for filtering out the parameters that you don't want shown in the logs,
such as passwords or credit card numbers. It also filters out sensitive values
of database columns when calling #inspect on an Active Record object. By
default, Rails filters out passwords by adding the following filters in
config/initializers/filter_parameter_logging.rb.

```ruby
Rails.application.config.filter_parameters += [
  :passw, :email, :secret, :token, :_key, :crypt, :salt, :certificate, :otp, :ssn, :cvv, :cvc
]
```

Parameters filter works by partial matching regular expression.

#### 3.2.35. config.filter_redirect

Used for filtering out redirect urls from application logs.

```ruby
Rails.application.config.filter_redirect += ["s3.amazonaws.com", /private-match/]
```

The redirect filter works by testing that urls include strings or match regular
expressions.

#### 3.2.36. config.force_ssl

Forces all requests to be served over HTTPS, and sets "https://" as the default protocol when generating URLs. Enforcement of HTTPS is handled by the ActionDispatch::SSL middleware, which can be configured via config.ssl_options.

#### 3.2.37. config.helpers_paths

Defines an array of additional paths to load view helpers.

#### 3.2.38. config.host_authorization

Accepts a hash of options to configure the HostAuthorization
middleware

#### 3.2.39. config.hosts

An array of strings, regular expressions, or IPAddr used to validate the
Host header. Used by the HostAuthorization
middleware to help prevent DNS rebinding
attacks.

#### 3.2.40. config.javascript_path

Sets the path where your app's JavaScript lives relative to the app directory and the default value is javascript.
An app's configured javascript_path will be excluded from autoload_paths.

#### 3.2.41. config.log_file_size

Defines the maximum size of the Rails log file in bytes. Defaults to 104_857_600 (100 MiB) in development and test, and unlimited in all other environments.

#### 3.2.42. config.log_formatter

Defines the formatter of the Rails logger. This option defaults to an instance of ActiveSupport::Logger::SimpleFormatter for all environments. If you are setting a value for config.logger you must manually pass the value of your formatter to your logger before it is wrapped in an ActiveSupport::TaggedLogging instance, Rails will not do it for you.

#### 3.2.43. config.log_level

Defines the verbosity of the Rails logger. This option defaults to :debug for all environments except production, where it defaults to :info. The available log levels are: :debug, :info, :warn, :error, :fatal, and :unknown.

#### 3.2.44. config.log_tags

Accepts a list of methods that the request object responds to, a Proc that accepts the request object, or something that responds to to_s. This makes it easy to tag log lines with debug information like subdomain and request id - both very helpful in debugging multi-user production applications.

#### 3.2.45. config.logger

Is the logger that will be used for Rails.logger and any related Rails logging such as ActiveRecord::Base.logger. It defaults to an instance of ActiveSupport::TaggedLogging that wraps an instance of ActiveSupport::Logger which outputs a log to the log/ directory. You can supply a custom logger, to get full compatibility you must follow these guidelines:

- To support a formatter, you must manually assign a formatter from the config.log_formatter value to the logger.

- To support tagged logs, the log instance must be wrapped with ActiveSupport::TaggedLogging.

- To support silencing, the logger must include ActiveSupport::LoggerSilence module. The ActiveSupport::Logger class already includes these modules.

```ruby
class MyLogger < ::Logger
  include ActiveSupport::LoggerSilence
end

mylogger           = MyLogger.new(STDOUT)
mylogger.formatter = config.log_formatter
config.logger      = ActiveSupport::TaggedLogging.new(mylogger)
```

#### 3.2.46. config.middleware

Allows you to configure the application's middleware. This is covered in depth in the Configuring Middleware section below.

#### 3.2.47. config.precompile_filter_parameters

When true, will precompile config.filter_parameters
using ActiveSupport::ParameterFilter.precompile_filters.

The default value depends on the config.load_defaults target version:

#### 3.2.48. config.public_file_server.enabled

Configures whether Rails should serve static files from the public directory.
Defaults to true.

If the server software (e.g. NGINX or Apache) should serve static files instead,
set this value to false.

#### 3.2.49. config.railties_order

Allows manually specifying the order that Railties/Engines are loaded. The
default value is [:all].

```ruby
config.railties_order = [Blog::Engine, :main_app, :all]
```

#### 3.2.50. config.rake_eager_load

When true, eager load the application when running Rake tasks. Defaults to false.

#### 3.2.51. config.relative_url_root

Can be used to tell Rails that you are deploying to a subdirectory. The default
is ENV['RAILS_RELATIVE_URL_ROOT'].

#### 3.2.52. config.reload_classes_only_on_change

Enables or disables reloading of classes only when tracked files change. By default tracks everything on autoload paths and is set to true. If config.enable_reloading is false, this option is ignored.

#### 3.2.53. config.require_master_key

Causes the app to not boot if a master key hasn't been made available through ENV["RAILS_MASTER_KEY"] or the config/master.key file.

#### 3.2.54. config.sandbox_by_default

When true, rails console starts in sandbox mode. To start rails console in non-sandbox mode, --no-sandbox must be specified. This is helpful to avoid accidental writing to the production database. Defaults to false.

#### 3.2.55. config.secret_key_base

The fallback for specifying the input secret for an application's key generator.
It is recommended to leave this unset, and instead to specify a secret_key_base
in config/credentials.yml.enc. See the secret_key_base API documentation
for more information and alternative configuration methods.

#### 3.2.56. config.server_timing

When true, adds the ServerTiming middleware
to the middleware stack. Defaults to false, but is set to true in the
default generated config/environments/development.rb file.

#### 3.2.57. config.session_options

Additional options passed to config.session_store. You should use
config.session_store to set this instead of modifying it yourself.

```ruby
config.session_store :cookie_store, key: "_your_app_session"
config.session_options # => {key: "_your_app_session"}
```

#### 3.2.58. config.session_store

Specifies what class to use to store the session. Possible values are :cache_store, :cookie_store, :mem_cache_store, a custom store, or :disabled. :disabled tells Rails not to deal with sessions.

This setting is configured via a regular method call, rather than a setter. This allows additional options to be passed:

```ruby
config.session_store :cookie_store, key: "_your_app_session"
```

If a custom store is specified as a symbol, it will be resolved to the ActionDispatch::Session namespace:

```ruby
# use ActionDispatch::Session::MyCustomStore as the session store
config.session_store :my_custom_store
```

The default store is a cookie store with the application name as the session key.

#### 3.2.59. config.silence_healthcheck_path

Specifies the path of the health check that should be silenced in the logs. Uses Rails::Rack::SilenceRequest to implement the silencing. All in service of keeping health checks from clogging the production logs, especially for early-stage applications.

```
config.silence_healthcheck_path = "/up"
```

#### 3.2.60. config.ssl_options

Configuration options for the ActionDispatch::SSL middleware.

The default value depends on the config.load_defaults target version:

#### 3.2.61. config.time_zone

Sets the default time zone for the application and enables time zone awareness for Active Record.

#### 3.2.62. config.x

Used to easily add nested custom configuration to the application config object

```ruby
config.x.payment_processing.schedule = :daily
  Rails.configuration.x.payment_processing.schedule # => :daily
```

See Custom Configuration

#### 3.2.63. config.yjit

Enables YJIT as of Ruby 3.3, to bring sizeable performance improvements. If you are
deploying to a memory constrained environment you may want to set this to false.
Additionally, you can pass a hash to configure YJIT options such as { stats: true }.

### 3.3. Configuring Assets

#### 3.3.1. config.assets.css_compressor

Defines the CSS compressor to use. It is set by default by sass-rails. The unique alternative value at the moment is :yui, which uses the yui-compressor gem.

#### 3.3.2. config.assets.js_compressor

Defines the JavaScript compressor to use. Possible values are :terser, :closure, :uglifier, and :yui, which require the use of the terser, closure-compiler, uglifier, or yui-compressor gems respectively.

#### 3.3.3. config.assets.gzip

A flag that enables the creation of gzipped version of compiled assets, along with non-gzipped assets. Set to true by default.

#### 3.3.4. config.assets.paths

Contains the paths which are used to look for assets. Appending paths to this configuration option will cause those paths to be used in the search for assets.

#### 3.3.5. config.assets.precompile

Allows you to specify additional assets (other than application.css and application.js) which are to be precompiled when bin/rails assets:precompile is run.

#### 3.3.6. config.assets.unknown_asset_fallback

Allows you to modify the behavior of the asset pipeline when an asset is not in the pipeline, if you use sprockets-rails 3.2.0 or newer.

The default value depends on the config.load_defaults target version:

#### 3.3.7. config.assets.prefix

Defines the prefix where assets are served from. Defaults to /assets.

#### 3.3.8. config.assets.manifest

Defines the full path to be used for the asset precompiler's manifest file. Defaults to a file named manifest-<random>.json in the config.assets.prefix directory within the public folder.

#### 3.3.9. config.assets.digest

Enables the use of SHA256 fingerprints in asset names. Set to true by default.

#### 3.3.10. config.assets.debug

Disables the concatenation and compression of assets.

#### 3.3.11. config.assets.version

Is an option string that is used in SHA256 hash generation. This can be changed to force all files to be recompiled.

#### 3.3.12. config.assets.compile

Is a boolean that can be used to turn on live Sprockets compilation in production.

#### 3.3.13. config.assets.logger

Accepts a logger conforming to the interface of Log4r or the default Ruby Logger class. Defaults to the same configured at config.logger. Setting config.assets.logger to false will turn off served assets logging.

#### 3.3.14. config.assets.quiet

Disables logging of assets requests. Set to true by default in config/environments/development.rb.

### 3.4. Configuring Generators

Rails allows you to alter what generators are used with the config.generators method. This method takes a block:

```ruby
config.generators do |g|
  g.orm :active_record
  g.test_framework :test_unit
end
```

The full set of methods that can be used in this block are as follows:

- force_plural allows pluralized model names. Defaults to false.

- helper defines whether or not to generate helpers. Defaults to true.

- integration_tool defines which integration tool to use to generate integration tests. Defaults to :test_unit.

- system_tests defines which integration tool to use to generate system tests. Defaults to :test_unit.

- orm defines which orm to use. Defaults to false and will use Active Record by default.

- resource_controller defines which generator to use for generating a controller when using bin/rails generate resource. Defaults to :controller.

- resource_route defines whether a resource route definition should be generated
or not. Defaults to true.

- scaffold_controller different from resource_controller, defines which generator to use for generating a scaffolded controller when using bin/rails generate scaffold. Defaults to :scaffold_controller.

- test_framework defines which test framework to use. Defaults to false and will use minitest by default.

- template_engine defines which template engine to use, such as ERB or Haml. Defaults to :erb.

- apply_rubocop_autocorrect_after_generate! applies RuboCop's autocorrect feature after Rails generators are run.

### 3.5. Configuring Middleware

Every Rails application comes with a standard set of middleware which it uses in this order in the development environment:

#### 3.5.1. ActionDispatch::HostAuthorization

Prevents against DNS rebinding and other Host header attacks.
It is included in the development environment by default with the following configuration:

```ruby
Rails.application.config.hosts = [
  IPAddr.new("0.0.0.0/0"),        # All IPv4 addresses.
  IPAddr.new("::/0"),             # All IPv6 addresses.
  "localhost",                    # The localhost reserved domain.
  ENV["RAILS_DEVELOPMENT_HOSTS"]  # Additional comma-separated hosts for development.
]
```

In other environments Rails.application.config.hosts is empty and no
Host header checks will be done. If you want to guard against header
attacks on production, you have to manually permit the allowed hosts
with:

```ruby
Rails.application.config.hosts << "product.com"
```

The host of a request is checked against the hosts entries with the case
operator (#===), which lets hosts support entries of type Regexp,
Proc and IPAddr to name a few. Here is an example with a regexp.

```ruby
# Allow requests from subdomains like `www.product.com` and
# `beta1.product.com`.
Rails.application.config.hosts << /.*\.product\.com/
```

The provided regexp will be wrapped with both anchors (\A and \z) so it
must match the entire hostname. /product.com/, for example, once anchored,
would fail to match <www.product.com>.

A special case is supported that allows you to permit the domain and all sub-domains:

```ruby
# Allow requests from the domain itself `product.com` and subdomains like `www.product.com` and `beta1.product.com`.
Rails.application.config.hosts << ".product.com"
```

You can exclude certain requests from Host Authorization checks by setting
config.host_authorization.exclude:

```ruby
# Exclude requests for the /healthcheck/ path from host checking
Rails.application.config.host_authorization = {
  exclude: ->(request) { request.path.include?("healthcheck") }
}
```

When a request comes to an unauthorized host, a default Rack application
will run and respond with 403 Forbidden. This can be customized by setting
config.host_authorization.response_app. For example:

```ruby
Rails.application.config.host_authorization = {
  response_app: -> env do
    [400, { "Content-Type" => "text/plain" }, ["Bad Request"]]
  end
}
```

#### 3.5.2. ActionDispatch::ServerTiming

Adds the Server-Timing header to the response, which includes performance
metrics from the server. This data can be viewed by inspecting the response in
the Network panel of the browser's Developer Tools. Most browsers provide a
Timing tab that visualizes the data.

#### 3.5.3. ActionDispatch::SSL

Forces every request to be served using HTTPS. Enabled if config.force_ssl is set to true. Options passed to this can be configured by setting config.ssl_options.

#### 3.5.4. ActionDispatch::Static

Is used to serve static assets. Disabled if config.public_file_server.enabled is false. Set config.public_file_server.index_name if you need to serve a static directory index file that is not named index. For example, to serve main.html instead of index.html for directory requests, set config.public_file_server.index_name to "main".

#### 3.5.5. ActionDispatch::Executor

Allows thread safe code reloading. Disabled if config.allow_concurrency is false, which causes Rack::Lock to be loaded. Rack::Lock wraps the app in mutex so it can only be called by a single thread at a time.

#### 3.5.6. ActiveSupport::Cache::Strategy::LocalCache

Serves as a basic memory backed cache. This cache is not thread safe and is intended only for serving as a temporary memory cache for a single thread.

#### 3.5.7. Rack::Runtime

Sets an X-Runtime header, containing the time (in seconds) taken to execute the request.

#### 3.5.8. Rails::Rack::Logger

Notifies the logs that the request has begun. After request is complete, flushes all the logs.

#### 3.5.9. ActionDispatch::ShowExceptions

Rescues any exception returned by the application and renders nice exception pages if the request is local or if config.consider_all_requests_local is set to true. If config.action_dispatch.show_exceptions is set to :none, exceptions will be raised regardless.

#### 3.5.10. ActionDispatch::RequestId

Makes a unique X-Request-Id header available to the response and enables the ActionDispatch::Request#uuid method. Configurable with config.action_dispatch.request_id_header.

#### 3.5.11. ActionDispatch::RemoteIp

Checks for IP spoofing attacks and gets valid client_ip from request headers. Configurable with the config.action_dispatch.ip_spoofing_check, and config.action_dispatch.trusted_proxies options.

#### 3.5.12. Rack::Sendfile

Intercepts responses whose body is being served from a file and replaces it with a server specific X-Sendfile header. Configurable with config.action_dispatch.x_sendfile_header.

#### 3.5.13. ActionDispatch::Callbacks

Runs the prepare callbacks before serving the request.

#### 3.5.14. ActionDispatch::Cookies

Sets cookies for the request.

#### 3.5.15. ActionDispatch::Session::CookieStore

Is responsible for storing the session in cookies. An alternate middleware can be used for this by changing config.session_store.

#### 3.5.16. ActionDispatch::Flash

Sets up the flash keys. Only available if config.session_store is set to a value.

#### 3.5.17. Rack::MethodOverride

Allows the method to be overridden if params[:_method] is set. This is the middleware which supports the PATCH, PUT, and DELETE HTTP method types.

#### 3.5.18. Rack::Head

Returns an empty body for all HEAD requests. It leaves all other requests unchanged.

#### 3.5.19. Adding Custom Middleware

Besides these usual middleware, you can add your own by using the config.middleware.use method:

```ruby
config.middleware.use Magical::Unicorns
```

This will put the Magical::Unicorns middleware on the end of the stack. You can use insert_before if you wish to add a middleware before another.

```ruby
config.middleware.insert_before Rack::Head, Magical::Unicorns
```

Or you can insert a middleware to exact position by using indexes. For example, if you want to insert Magical::Unicorns middleware on top of the stack, you can do it, like so:

```ruby
config.middleware.insert_before 0, Magical::Unicorns
```

There's also insert_after which will insert a middleware after another:

```ruby
config.middleware.insert_after Rack::Head, Magical::Unicorns
```

Middlewares can also be completely swapped out and replaced with others:

```ruby
config.middleware.swap ActionController::Failsafe, Lifo::Failsafe
```

Middlewares can be moved from one place to another:

```ruby
config.middleware.move_before ActionDispatch::Flash, Magical::Unicorns
```

This will move the Magical::Unicorns middleware before
ActionDispatch::Flash. You can also move it after:

```ruby
config.middleware.move_after ActionDispatch::Flash, Magical::Unicorns
```

They can also be removed from the stack completely:

```ruby
config.middleware.delete Rack::MethodOverride
```

### 3.6. Configuring i18n

All these configuration options are delegated to the I18n library.

#### 3.6.1. config.i18n.available_locales

Defines the permitted available locales for the app. Defaults to all locale keys found in locale files, usually only :en on a new application.

#### 3.6.2. config.i18n.default_locale

Sets the default locale of an application used for i18n. Defaults to :en.

#### 3.6.3. config.i18n.enforce_available_locales

Ensures that all locales passed through i18n must be declared in the available_locales list, raising an I18n::InvalidLocale exception when setting an unavailable locale. Defaults to true. It is recommended not to disable this option unless strongly required, since this works as a security measure against setting any invalid locale from user input.

#### 3.6.4. config.i18n.load_path

Sets the path Rails uses to look for locale files. Defaults to config/locales/**/*.{yml,rb}.

#### 3.6.5. config.i18n.raise_on_missing_translations

Determines whether an error should be raised for missing translations. If true, views and controllers raise I18n::MissingTranslationData. If :strict, models also raise the error. This defaults to false.

#### 3.6.6. config.i18n.fallbacks

Sets fallback behavior for missing translations. Here are 3 usage examples for this option:

- You can set the option to true for using default locale as fallback, like so:
config.i18n.fallbacks = true

- Or you can set an array of locales as fallback, like so:
config.i18n.fallbacks = [:tr, :en]

- Or you can set different fallbacks for locales individually. For example, if you want to use :tr for :az and :de, :en for :da as fallbacks, you can do it, like so:
config.i18n.fallbacks = { az: :tr, da: [:de, :en] }
# or
config.i18n.fallbacks.map = { az: :tr, da: [:de, :en] }

You can set the option to true for using default locale as fallback, like so:

```ruby
config.i18n.fallbacks = true
```

Or you can set an array of locales as fallback, like so:

```ruby
config.i18n.fallbacks = [:tr, :en]
```

Or you can set different fallbacks for locales individually. For example, if you want to use :tr for :az and :de, :en for :da as fallbacks, you can do it, like so:

```ruby
config.i18n.fallbacks = { az: :tr, da: [:de, :en] }
#or
config.i18n.fallbacks.map = { az: :tr, da: [:de, :en] }
```

### 3.7. Configuring Active Model

#### 3.7.1. config.active_model.i18n_customize_full_message

Controls whether the Error#full_message format can be overridden in an i18n locale file. Defaults to false.

When set to true, full_message will look for a format at the attribute and model level of the locale files. The default format is "%{attribute} %{message}", where attribute is the name of the attribute, and message is the validation-specific message. The following example overrides the format for all Person attributes, as well as the format for a specific Person attribute (age).

```ruby
class Person
  include ActiveModel::Validations

  attr_accessor :name, :age

  validates :name, :age, presence: true
end
```

```
en:
  activemodel: # or activerecord:
    errors:
      models:
        person:
          # Override the format for all Person attributes:
          format: "Invalid %{attribute} (%{message})"
          attributes:
            age:
              # Override the format for the age attribute:
              format: "%{message}"
              blank: "Please fill in your %{attribute}"
```

```
irb> person = Person.new.tap(&:valid?)

irb> person.errors.full_messages
=> [
  "Invalid Name (can't be blank)",
  "Please fill in your Age"
]

irb> person.errors.messages
=> {
  :name => ["can't be blank"],
  :age  => ["Please fill in your Age"]
}
```

### 3.8. Configuring Active Record

config.active_record includes a variety of configuration options:

#### 3.8.1. config.active_record.logger

Accepts a logger conforming to the interface of Log4r or the default Ruby Logger class, which is then passed on to any new database connections made. You can retrieve this logger by calling logger on either an Active Record model class or an Active Record model instance. Set to nil to disable logging.

#### 3.8.2. config.active_record.primary_key_prefix_type

Lets you adjust the naming for primary key columns. By default, Rails assumes that primary key columns are named id (and this configuration option doesn't need to be set). There are two other choices:

- :table_name would make the primary key for the Customer class customerid.

- :table_name_with_underscore would make the primary key for the Customer class customer_id.

#### 3.8.3. config.active_record.table_name_prefix

Lets you set a global string to be prepended to table names. If you set this to northwest_, then the Customer class will look for northwest_customers as its table. The default is an empty string.

#### 3.8.4. config.active_record.table_name_suffix

Lets you set a global string to be appended to table names. If you set this to _northwest, then the Customer class will look for customers_northwest as its table. The default is an empty string.

#### 3.8.5. config.active_record.schema_migrations_table_name

Lets you set a string to be used as the name of the schema migrations table.

#### 3.8.6. config.active_record.internal_metadata_table_name

Lets you set a string to be used as the name of the internal metadata table.

#### 3.8.7. config.active_record.protected_environments

Lets you set an array of names of environments where destructive actions should be prohibited.

#### 3.8.8. config.active_record.pluralize_table_names

Specifies whether Rails will look for singular or plural table names in the database. If set to true (the default), then the Customer class will use the customers table. If set to false, then the Customer class will use the customer table.

Some Rails generators and installers (notably active_storage:install
and action_text:install) create tables with plural names regardless of this
setting. If you set pluralize_table_names to false, you will need to
manually rename those tables after installation to maintain consistency.
This limitation exists because these installers use fixed table names
in their migrations for compatibility reasons.

#### 3.8.9. config.active_record.default_timezone

Determines whether to use Time.local (if set to :local) or Time.utc (if set to :utc) when pulling dates and times from the database. The default is :utc.

#### 3.8.10. config.active_record.schema_format

Controls the format for dumping the database schema to a file. The options are :ruby (the default) for a database-independent version that depends on migrations, or :sql for a set of (potentially database-dependent) SQL statements. This can be overridden per-database by setting schema_format in your database configuration.

#### 3.8.11. config.active_record.error_on_ignored_order

Specifies if an error should be raised if the order of a query is ignored during a batch query. The options are true (raise error) or false (warn). Default is false.

#### 3.8.12. config.active_record.timestamped_migrations

Controls whether migrations are numbered with serial integers or with timestamps. The default is true, to use timestamps, which are preferred if there are multiple developers working on the same application.

#### 3.8.13. config.active_record.automatically_invert_plural_associations

Controls whether Active Record will automatically look for inverse relations with a pluralized name.

Example:

```ruby
class Post < ApplicationRecord
  has_many :comments
end

class Comment < ApplicationRecord
  belongs_to :post
end
```

In the above case Active Record used to only look for a :comment (singular) association in Post, and won't find it.

With this option enabled, it will also look for a :comments association. In the vast majority of cases
having the inverse association discovered is beneficial as it can prevent some useless queries, but
it may cause backward compatibility issues with legacy code that doesn't expect it.

This behavior can be disabled on a per-model basis:

```ruby
class Comment < ApplicationRecord
  self.automatically_invert_plural_associations = false

  belongs_to :post
end
```

And on a per-association basis:

```ruby
class Comment < ApplicationRecord
  self.automatically_invert_plural_associations = true

  belongs_to :post, inverse_of: nil
end
```

#### 3.8.14. config.active_record.validate_migration_timestamps

Controls whether to validate migration timestamps. When set, an error will be raised if the
timestamp prefix for a migration is more than a day ahead of the timestamp associated with the
current time. This is done to prevent forward-dating of migration files, which can impact migration
generation and other migration commands. config.active_record.timestamped_migrations must be set to true.

The default value depends on the config.load_defaults target version:

#### 3.8.15. config.active_record.db_warnings_action

Controls the action to be taken when an SQL query produces a warning. The following options are available:

- :ignore - Database warnings will be ignored. This is the default.

- :log - Database warnings will be logged via ActiveRecord.logger at the :warn level.

- :raise - Database warnings will be raised as ActiveRecord::SQLWarning.

- :report - Database warnings will be reported to subscribers of Rails' error reporter.

- Custom proc - A custom proc can be provided. It should accept a SQLWarning error object.For example:
config.active_record.db_warnings_action = ->(warning) do

  # Report to custom exception reporting service

  Bugsnag.notify(warning.message) do |notification|
    notification.add_metadata(:warning_code, warning.code)
    notification.add_metadata(:warning_level, warning.level)
  end
end

:ignore - Database warnings will be ignored. This is the default.

:log - Database warnings will be logged via ActiveRecord.logger at the :warn level.

:raise - Database warnings will be raised as ActiveRecord::SQLWarning.

:report - Database warnings will be reported to subscribers of Rails' error reporter.

Custom proc - A custom proc can be provided. It should accept a SQLWarning error object.

For example:

```ruby
config.active_record.db_warnings_action = ->(warning) do
  # Report to custom exception reporting service
  Bugsnag.notify(warning.message) do |notification|
    notification.add_metadata(:warning_code, warning.code)
    notification.add_metadata(:warning_level, warning.level)
  end
end
```

#### 3.8.16. config.active_record.db_warnings_ignore

Specifies an allowlist of warning codes and messages that will be ignored, regardless of the configured db_warnings_action.
The default behavior is to report all warnings. Warnings to ignore can be specified as Strings or Regexps. For example:

```ruby
config.active_record.db_warnings_action = :raise
  # The following warnings will not be raised
  config.active_record.db_warnings_ignore = [
    /Invalid utf8mb4 character string/,
    "An exact warning message",
    "1062", # MySQL Error 1062: Duplicate entry
  ]
```

#### 3.8.17. config.active_record.migration_strategy

Controls the strategy class used to perform schema statement methods in a migration. The default class
delegates to the connection adapter. Custom strategies should inherit from ActiveRecord::Migration::ExecutionStrategy,
or may inherit from DefaultStrategy, which will preserve the default behavior for methods that aren't implemented:

```ruby
class CustomMigrationStrategy < ActiveRecord::Migration::DefaultStrategy
  def drop_table(*)
    raise "Dropping tables is not supported!"
  end
end

config.active_record.migration_strategy = CustomMigrationStrategy
```

#### 3.8.18. config.active_record.schema_versions_formatter

Controls the formatter class used by schema dumper to format versions information. Custom class can be provided
to change the default behavior:

```ruby
class CustomSchemaVersionsFormatter
  def initialize(connection)
    @connection = connection
  end

  def format(versions)
    # Special sorting of versions to reduce the likelihood of conflicts.
    sorted_versions = versions.sort { |a, b| b.to_s.reverse <=> a.to_s.reverse }

    sql = +"INSERT INTO schema_migrations (version) VALUES\n"
    sql << sorted_versions.map { |v| "(#{@connection.quote(v)})" }.join(",\n")
    sql << ";"
    sql
  end
end

config.active_record.schema_versions_formatter = CustomSchemaVersionsFormatter
```

#### 3.8.19. config.active_record.lock_optimistically

Controls whether Active Record will use optimistic locking and is true by default.

#### 3.8.20. config.active_record.cache_timestamp_format

Controls the format of the timestamp value in the cache key. Default is :usec.

#### 3.8.21. config.active_record.record_timestamps

Is a boolean value which controls whether or not timestamping of create and update operations on a model occur. The default value is true.

#### 3.8.22. config.active_record.partial_inserts

Is a boolean value and controls whether or not partial writes are used when creating new records (i.e. whether inserts only set attributes that are different from the default).

The default value depends on the config.load_defaults target version:

#### 3.8.23. config.active_record.partial_updates

Is a boolean value and controls whether or not partial writes are used when updating existing records (i.e. whether updates only set attributes that are dirty). Note that when using partial updates, you should also use optimistic locking config.active_record.lock_optimistically since concurrent updates may write attributes based on a possibly stale read state. The default value is true.

#### 3.8.24. config.active_record.maintain_test_schema

Is a boolean value which controls whether Active Record should try to keep your test database schema up-to-date with db/schema.rb (or db/structure.sql) when you run your tests. The default is true.

#### 3.8.25. config.active_record.dump_schema_after_migration

Is a flag which controls whether or not schema dump should happen
(db/schema.rb or db/structure.sql) when you run migrations. This is set to
false in config/environments/production.rb which is generated by Rails. The
default value is true if this configuration is not set.

#### 3.8.26. config.active_record.dump_schemas

Controls which database schemas will be dumped when calling db:schema:dump.
The options are :schema_search_path (the default) which dumps any schemas listed in schema_search_path,
:all which always dumps all schemas regardless of the schema_search_path,
or a string of comma separated schemas.

#### 3.8.27. config.active_record.before_committed_on_all_records

Enable before_committed! callbacks on all enrolled records in a transaction.
The previous behavior was to only run the callbacks on the first copy of a record
if there were multiple copies of the same record enrolled in the transaction.

#### 3.8.28. config.active_record.belongs_to_required_by_default

Is a boolean value and controls whether a record fails validation if
belongs_to association is not present.

The default value depends on the config.load_defaults target version:

#### 3.8.29. config.active_record.belongs_to_required_validates_foreign_key

Enable validating only parent-related columns for presence when the parent is mandatory.
The previous behavior was to validate the presence of the parent record, which performed an extra query
to get the parent every time the child record was updated, even when parent has not changed.

#### 3.8.30. config.active_record.marshalling_format_version

When set to 7.1, enables a more efficient serialization of Active Record instance with Marshal.dump.

This changes the serialization format, so models serialized this
way cannot be read by older (< 7.1) versions of Rails. However, messages that
use the old format can still be read, regardless of whether this optimization is
enabled.

#### 3.8.31. config.active_record.action_on_strict_loading_violation

Enables raising or logging an exception if strict_loading is set on an
association. The default value is :raise in all environments. It can be
changed to :log to send violations to the logger instead of raising.

#### 3.8.32. config.active_record.strict_loading_by_default

Is a boolean value that either enables or disables strict_loading mode by
default. Defaults to false.

#### 3.8.33. config.active_record.strict_loading_mode

Sets the mode in which strict loading is reported. Defaults to :all. It can be
changed to :n_plus_one_only to only report when loading associations that will
lead to an N + 1 query.

#### 3.8.34. config.active_record.index_nested_attribute_errors

Allows errors for nested has_many relationships to be displayed with an index
as well as the error. Defaults to false.

#### 3.8.35. config.active_record.use_schema_cache_dump

Enables users to get schema cache information from db/schema_cache.yml
(generated by bin/rails db:schema:cache:dump), instead of having to send a
query to the database to get this information. Defaults to true.

#### 3.8.36. config.active_record.cache_versioning

Indicates whether to use a stable #cache_key method that is accompanied by a
changing version in the #cache_version method.

The default value depends on the config.load_defaults target version:

#### 3.8.37. config.active_record.collection_cache_versioning

Enables the same cache key to be reused when the object being cached of type
ActiveRecord::Relation changes by moving the volatile information (max
updated at and count) of the relation's cache key into the cache version to
support recycling cache key.

The default value depends on the config.load_defaults target version:

#### 3.8.38. config.active_record.has_many_inversing

Enables setting the inverse record when traversing belongs_to to has_many
associations.

The default value depends on the config.load_defaults target version:

#### 3.8.39. config.active_record.automatic_scope_inversing

Enables automatically inferring the inverse_of for associations with a scope.

The default value depends on the config.load_defaults target version:

#### 3.8.40. config.active_record.destroy_association_async_job

Allows specifying the job that will be used to destroy the associated records in background. It defaults to ActiveRecord::DestroyAssociationAsyncJob.

#### 3.8.41. config.active_record.destroy_association_async_batch_size

Allows specifying the maximum number of records that will be destroyed in a background job by the dependent: :destroy_async association option. All else equal, a lower batch size will enqueue more, shorter-running background jobs, while a higher batch size will enqueue fewer, longer-running background jobs. This option defaults to nil, which will cause all dependent records for a given association to be destroyed in the same background job.

#### 3.8.42. config.active_record.queues.destroy

Allows specifying the Active Job queue to use for destroy jobs. When this option
is nil, purge jobs are sent to the default Active Job queue (see
config.active_job.default_queue_name). It defaults to nil.

#### 3.8.43. config.active_record.enumerate_columns_in_select_statements

When true, will always include column names in SELECT statements, and avoid wildcard SELECT * FROM ... queries. This avoids prepared statement cache errors when adding columns to a PostgreSQL database for example. Defaults to false.

#### 3.8.44. config.active_record.verify_foreign_keys_for_fixtures

Ensures all foreign key constraints are valid after fixtures are loaded in tests. Supported by PostgreSQL and SQLite only.

The default value depends on the config.load_defaults target version:

#### 3.8.45. config.active_record.raise_on_assign_to_attr_readonly

Enable raising on assignment to attr_readonly attributes. The previous
behavior would allow assignment but silently not persist changes to the
database.

#### 3.8.46. config.active_record.run_commit_callbacks_on_first_saved_instances_in_transaction

When multiple Active Record instances change the same record within a transaction, Rails runs after_commit or after_rollback callbacks for only one of them. This option specifies how Rails chooses which instance receives the callbacks.

When true, transactional callbacks are run on the first instance to save, even though its instance state may be stale.

When false, transactional callbacks are run on the instances with the freshest instance state. Those instances are chosen as follows:

- In general, run transactional callbacks on the last instance to save a given record within the transaction.

- There are two exceptions:

If the record is created within the transaction, then updated by another instance, after_create_commit callbacks will be run on the second instance. This is instead of the after_update_commit callbacks that would naively be run based on that instance’s state.
If the record is destroyed within the transaction, then after_destroy_commit callbacks will be fired on the last destroyed instance, even if a stale instance subsequently performed an update (which will have affected 0 rows).

- If the record is created within the transaction, then updated by another instance, after_create_commit callbacks will be run on the second instance. This is instead of the after_update_commit callbacks that would naively be run based on that instance’s state.

- If the record is destroyed within the transaction, then after_destroy_commit callbacks will be fired on the last destroyed instance, even if a stale instance subsequently performed an update (which will have affected 0 rows).

The default value depends on the config.load_defaults target version:

#### 3.8.47. config.active_record.default_column_serializer

The serializer implementation to use if none is explicitly specified for a given
column.

Historically serialize and store while allowing to use alternative serializer
implementations, would use YAML by default, but it's not a very efficient format
and can be the source of security vulnerabilities if not carefully employed.

As such it is recommended to prefer stricter, more limited formats for database
serialization.

Unfortunately there isn't really any suitable defaults available in Ruby's standard
library. JSON could work as a format, but the json gems will cast unsupported
types to strings which may lead to bugs.

The default value depends on the config.load_defaults target version:

#### 3.8.48. config.active_record.run_after_transaction_callbacks_in_order_defined

When true, after_commit callbacks are executed in the order they are defined in a model. When false, they are executed in reverse order.

All other callbacks are always executed in the order they are defined in a model (unless you use prepend: true).

The default value depends on the config.load_defaults target version:

#### 3.8.49. config.active_record.query_log_tags_enabled

Specifies whether or not to enable adapter-level query comments. Defaults to
false, but is set to true in the default generated config/environments/development.rb file.

When this is set to true database prepared statements will be automatically disabled.

#### 3.8.50. config.active_record.query_log_tags

Define an Array specifying the key/value tags to be inserted in an SQL comment. Defaults to
[ :application, :controller, :action, :job ]. The available tags are: :application, :controller,
:namespaced_controller, :action, :job, and :source_location.

Calculating the :source_location of a query can be slow, so you should consider its impact if using it in a production environment.

#### 3.8.51. config.active_record.query_log_tags_format

A Symbol specifying the formatter to use for tags. Valid values are :sqlcommenter and :legacy.

The default value depends on the config.load_defaults target version:

#### 3.8.52. config.active_record.cache_query_log_tags

Specifies whether or not to enable caching of query log tags. For applications
that have a large number of queries, caching query log tags can provide a
performance benefit when the context does not change during the lifetime of the
request or job execution. Defaults to false.

#### 3.8.53. config.active_record.query_log_tags_prepend_comment

Specifies whether or not to prepend query log tags comment to the query.

By default comments are appended at the end of the query. Certain databases, such as MySQL will
truncate the query text. This is the case for slow query logs and the results of querying
some InnoDB internal tables where the length of the query is more than 1024 bytes.
In order to not lose the log tags comments from the queries, you can prepend the comments using this option.

Defaults to false.

#### 3.8.54. config.active_record.schema_cache_ignored_tables

Define the list of table that should be ignored when generating the schema
cache. It accepts an Array of strings, representing the table names, or
regular expressions.

#### 3.8.55. config.active_record.verbose_query_logs

Specifies if source locations of methods that call database queries should be logged below relevant queries. By default, the flag is true in development and false in all other environments.

#### 3.8.56. config.active_record.sqlite3_adapter_strict_strings_by_default

Specifies whether the SQLite3Adapter should be used in a strict strings mode.
The use of a strict strings mode disables double-quoted string literals.

SQLite has some quirks around double-quoted string literals.
It first tries to consider double-quoted strings as identifier names, but if they don't exist
it then considers them as string literals. Because of this, typos can silently go unnoticed.
For example, it is possible to create an index for a non existing column.
See SQLite documentation for more details.

The default value depends on the config.load_defaults target version:

#### 3.8.57. config.active_record.postgresql_adapter_decode_dates

Specifies whether the PostgresqlAdapter should decode date columns.

```ruby
ActiveRecord::Base.connection
     .select_value("select '2024-01-01'::date").class #=> Date
```

The default value depends on the config.load_defaults target version:

#### 3.8.58. config.active_record.async_query_executor

Specifies how asynchronous queries are pooled.

It defaults to nil, which means load_async is disabled and instead directly executes queries in the foreground.
For queries to actually be performed asynchronously, it must be set to either :global_thread_pool or :multi_thread_pool.

:global_thread_pool will use a single pool for all databases the application connects to. This is the preferred configuration
for applications with only a single database, or applications which only ever query one database shard at a time.

:multi_thread_pool will use one pool per database, and each pool size can be configured individually in database.yml through the
max_threads and min_threads properties. This can be useful to applications regularly querying multiple databases at a time, and that need to more precisely define the max concurrency.

#### 3.8.59. config.active_record.global_executor_concurrency

Used in conjunction with config.active_record.async_query_executor = :global_thread_pool, defines how many asynchronous
queries can be executed concurrently.

Defaults to 4.

This number must be considered in accordance with the database connection pool size configured in database.yml. The connection pool
should be large enough to accommodate both the foreground threads (ie. web server or job worker threads) and background threads.

For each process, Rails will create one global query executor that uses this many threads to process async queries. Thus, the pool size
should be at least thread_count + global_executor_concurrency + 1. For example, if your web server has a maximum of 3 threads,
and global_executor_concurrency is set to 4, then your pool size should be at least 8.

#### 3.8.60. config.active_record.yaml_column_permitted_classes

Defaults to [Symbol]. Allows applications to include additional permitted classes to safe_load() on the ActiveRecord::Coders::YAMLColumn.

#### 3.8.61. config.active_record.use_yaml_unsafe_load

Defaults to false. Allows applications to opt into using unsafe_load on the ActiveRecord::Coders::YAMLColumn.

#### 3.8.62. config.active_record.raise_int_wider_than_64bit

Defaults to true. Determines whether to raise an exception or not when
the PostgreSQL adapter is provided an integer that is wider than signed
64bit representation.

#### 3.8.63. config.active_record.generate_secure_token_on

Controls when to generate a value for has_secure_token declarations. By
default, generate the value when the model is initialized:

```ruby
class User < ApplicationRecord
  has_secure_token
end

record = User.new
record.token # => "fwZcXX6SkJBJRogzMdciS7wf"
```

With config.active_record.generate_secure_token_on = :create, generate the
value when the model is created:

```ruby
# config/application.rb

config.active_record.generate_secure_token_on = :create

# app/models/user.rb
class User < ApplicationRecord
  has_secure_token on: :create
end

record = User.new
record.token # => nil
record.save!
record.token # => "fwZcXX6SkJBJRogzMdciS7wf"
```

#### 3.8.64. config.active_record.permanent_connection_checkout

Controls whether ActiveRecord::Base.connection raises an error, emits a deprecation warning, or neither.

ActiveRecord::Base.connection checkouts a database connection from the pool and keeps it leased until the end of
the request or job. This behavior can be undesirable in environments that use many more threads or fibers than there
is available connections.

This configuration can be used to track down and eliminate code that calls ActiveRecord::Base.connection and
migrate it to use ActiveRecord::Base.with_connection instead.

The value can be set to :disallowed, :deprecated, or true to respectively raise an error, emit a deprecation
warning, or neither.

#### 3.8.65. config.active_record.database_cli

Controls which CLI tool will be used for accessing the database when running bin/rails dbconsole. By default
the standard tool for the database will be used (e.g. psql for PostgreSQL and mysql for MySQL). The option
takes a hash which specifies the tool per-database system, and an array can be used where fallback options are
required:

```ruby
# config/application.rb

config.active_record.database_cli = { postgresql: "pgcli", mysql: %w[ mycli mysql ] }
```

#### 3.8.66. config.active_record.use_legacy_signed_id_verifier

Controls whether signed IDs are generated and verified using legacy options. Can be set to:

- :generate_and_verify (default) - Generate and verify signed IDs using the following legacy options:
{ digest: "SHA256", serializer: JSON, url_safe: true }

- :verify - Generate and verify signed IDs using options from Rails.application.message_verifiers, but fall back to verifying with the same options as :generate_and_verify.

- false - Generate and verify signed IDs using options from Rails.application.message_verifiers only.

:generate_and_verify (default) - Generate and verify signed IDs using the following legacy options:

```ruby
{ digest: "SHA256", serializer: JSON, url_safe: true }
```

:verify - Generate and verify signed IDs using options from Rails.application.message_verifiers, but fall back to verifying with the same options as :generate_and_verify.

false - Generate and verify signed IDs using options from Rails.application.message_verifiers only.

The purpose of this setting is to provide a smooth transition to a unified configuration for all message verifiers. Having a unified configuration makes it more straightforward to rotate secrets and upgrade signing algorithms.

Setting this to false may cause old signed IDs to become unreadable if Rails.application.message_verifiers is not properly configured. Use MessageVerifiers#rotate or MessageVerifiers#prepend to configure Rails.application.message_verifiers with the appropriate options, such as :digest and :url_safe.

#### 3.8.67. ActiveRecord::ConnectionAdapters::Mysql2Adapter.emulate_booleans and ActiveRecord::ConnectionAdapters::TrilogyAdapter.emulate_booleans

Controls whether the Active Record MySQL adapter will consider all tinyint(1) columns as booleans. Defaults to true.

#### 3.8.68. ActiveRecord::ConnectionAdapters::PostgreSQLAdapter.create_unlogged_tables

Controls whether database tables created by PostgreSQL should be "unlogged", which can speed
up performance but adds a risk of data loss if the database crashes. It is
highly recommended that you do not enable this in a production environment.
Defaults to false in all environments.

To enable this for tests:

```ruby
# config/environments/test.rb

ActiveSupport.on_load(:active_record_postgresqladapter) do
  self.create_unlogged_tables = true
end
```

#### 3.8.69. ActiveRecord::ConnectionAdapters::PostgreSQLAdapter.datetime_type

Controls what native type the Active Record PostgreSQL adapter should use when you call datetime in
a migration or schema. It takes a symbol which must correspond to one of the
configured NATIVE_DATABASE_TYPES. The default is :timestamp, meaning
t.datetime in a migration will create a "timestamp without time zone" column.

To use "timestamp with time zone":

```ruby
# config/application.rb

ActiveSupport.on_load(:active_record_postgresqladapter) do
  self.datetime_type = :timestamptz
end
```

You should run bin/rails db:migrate to rebuild your schema.rb if you change this.

#### 3.8.70. ActiveRecord::SchemaDumper.ignore_tables

Accepts an array of tables that should not be included in any generated schema file.

#### 3.8.71. ActiveRecord::SchemaDumper.fk_ignore_pattern

Allows setting a different regular expression that will be used to decide
whether a foreign key's name should be dumped to db/schema.rb or not. By
default, foreign key names starting with fk_rails_ are not exported to the
database schema dump. Defaults to /^fk_rails_[0-9a-f]{10}$/.

#### 3.8.72. config.active_record.encryption.add_to_filter_parameters

Enables automatic filtering of encrypted attributes on inspect.

The default value is true.

#### 3.8.73. config.active_record.encryption.hash_digest_class

Sets the digest algorithm used by Active Record Encryption.

The default value depends on the config.load_defaults target version:

#### 3.8.74. config.active_record.encryption.support_sha1_for_non_deterministic_encryption

Enables support for decrypting existing data encrypted using a SHA-1 digest class. When false,
it will only support the digest configured in config.active_record.encryption.hash_digest_class.

The default value depends on the config.load_defaults target version:

#### 3.8.75. config.active_record.encryption.compressor

Sets the compressor used by Active Record Encryption. The default value is Zlib.

You can use your own compressor by setting this to a class that responds to deflate and inflate.

#### 3.8.76. config.active_record.protocol_adapters

When using a URL to configure the database connection, this option provides a mapping from the protocol to the underlying
database adapter. For example, this means the environment can specify DATABASE_URL=mysql://localhost/database and Rails will map
mysql to the mysql2 adapter, but the application can also override these mappings:

```ruby
config.active_record.protocol_adapters.mysql = "trilogy"
```

If no mapping is found, the protocol is used as the adapter name.

#### 3.8.77. config.active_record.deprecated_associations_options

If present, this has to be a hash with keys :mode and/or :backtrace:

```ruby
config.active_record.deprecated_associations_options = { mode: :notify, backtrace: true }
```

- In :warn mode, accessing the deprecated association is reported by the
Active Record logger. This is the default mode.

- In :raise mode, usage raises an ActiveRecord::DeprecatedAssociationError
with a similar message and a clean backtrace in the exception object.

- In :notify mode, a deprecated_association.active_record Active Support
notification is published. Please, see details about its payload in the
Active Support Instrumentation guide.

In :warn mode, accessing the deprecated association is reported by the
Active Record logger. This is the default mode.

In :raise mode, usage raises an ActiveRecord::DeprecatedAssociationError
with a similar message and a clean backtrace in the exception object.

In :notify mode, a deprecated_association.active_record Active Support
notification is published. Please, see details about its payload in the
Active Support Instrumentation guide.

Backtraces are disabled by default. If :backtrace is true, warnings include a
clean backtrace in the message, and notifications have a :backtrace key in the
payload with an array of clean Thread::Backtrace::Location objects. Exceptions
always have a clean stack trace.

Clean backtraces are computed using the Active Record backtrace cleaner.

#### 3.8.78. config.active_record.raise_on_missing_required_finder_order_columns

Raises an error when order dependent finder methods (e.g. #first, #second) are called without order values
on the relation, and the model does not have any order columns (implicit_order_column, query_constraints, or
primary_key) to fall back on.

The default value depends on the config.load_defaults target version:

### 3.9. Configuring Action Controller

config.action_controller includes a number of configuration settings:

#### 3.9.1. config.action_controller.asset_host

Sets the host for the assets. Useful when CDNs are used for hosting assets rather than the application server itself. You should only use this if you have a different configuration for Action Mailer, otherwise use config.asset_host.

#### 3.9.2. config.action_controller.perform_caching

Configures whether the application should perform the caching features provided by the Action Controller component. Set to false in the development environment, true in production. If it's not specified, the default will be true.

#### 3.9.3. config.action_controller.default_static_extension

Configures the extension used for cached pages. Defaults to .html.

#### 3.9.4. config.action_controller.include_all_helpers

Configures whether all view helpers are available everywhere or are scoped to the corresponding controller. If set to false, UsersHelper methods are only available for views rendered as part of UsersController. If true, UsersHelper methods are available everywhere. The default configuration behavior (when this option is not explicitly set to true or false) is that all view helpers are available to each controller.

#### 3.9.5. config.action_controller.logger

Accepts a logger conforming to the interface of Log4r or the default Ruby Logger class, which is then used to log information from Action Controller. Set to nil to disable logging.

#### 3.9.6. config.action_controller.request_forgery_protection_token

Sets the token parameter name for RequestForgery. Calling protect_from_forgery sets it to :authenticity_token by default.

#### 3.9.7. config.action_controller.allow_forgery_protection

Enables or disables CSRF protection. By default this is false in the test environment and true in all other environments.

#### 3.9.8. config.action_controller.forgery_protection_origin_check

Configures whether the HTTP Origin header should be checked against the site's origin as an additional CSRF defense.

The default value depends on the config.load_defaults target version:

#### 3.9.9. config.action_controller.per_form_csrf_tokens

Configures whether CSRF tokens are only valid for the method/action they were generated for.

The default value depends on the config.load_defaults target version:

#### 3.9.10. config.action_controller.default_protect_from_forgery

Determines whether forgery protection is added on ActionController::Base.

The default value depends on the config.load_defaults target version:

#### 3.9.11. config.action_controller.relative_url_root

Can be used to tell Rails that you are deploying to a subdirectory. The default is
config.relative_url_root.

#### 3.9.12. config.action_controller.permit_all_parameters

Sets all the parameters for mass assignment to be permitted by default. The default value is false.

#### 3.9.13. config.action_controller.action_on_unpermitted_parameters

Controls behavior when parameters that are not explicitly permitted are found. The default value is :log in test and development environments, false otherwise. The values can be:

- false to take no action

- :log to emit an ActiveSupport::Notifications.instrument event on the unpermitted_parameters.action_controller topic and log at the DEBUG level

- :raise to raise a ActionController::UnpermittedParameters exception

#### 3.9.14. config.action_controller.always_permitted_parameters

Sets a list of permitted parameters that are permitted by default. The default values are ['controller', 'action'].

#### 3.9.15. config.action_controller.enable_fragment_cache_logging

Determines whether to log fragment cache reads and writes in verbose format as follows:

```
Read fragment views/v1/2914079/v1/2914079/recordings/70182313-20160225015037000000/d0bdf2974e1ef6d31685c3b392ad0b74 (0.6ms)
Rendered messages/_message.html.erb in 1.2 ms [cache hit]
Write fragment views/v1/2914079/v1/2914079/recordings/70182313-20160225015037000000/3b4e249ac9d168c617e32e84b99218b5 (1.1ms)
Rendered recordings/threads/_thread.html.erb in 1.5 ms [cache miss]
```

By default it is set to false which results in following output:

```
Rendered messages/_message.html.erb in 1.2 ms [cache hit]
Rendered recordings/threads/_thread.html.erb in 1.5 ms [cache miss]
```

#### 3.9.16. config.action_controller.raise_on_missing_callback_actions

Raises an AbstractController::ActionNotFound when the action specified in callback's :only or :except options is missing in the controller.

#### 3.9.17. config.action_controller.raise_on_open_redirects

Protect an application from unintentionally redirecting to an external host
(also known as an "open redirect") by making external redirects opt-in.

When this configuration is set to true, an
ActionController::Redirecting::UnsafeRedirectError will be raised when a URL
with an external host is passed to redirect_to. If an open redirect should
be allowed, then allow_other_host: true can be added to the call to
redirect_to.

#### 3.9.18. config.action_controller.action_on_open_redirect

Controls how Rails handles open redirect attempts (redirects to external hosts).

Note: This configuration replaces the deprecated config.action_controller.raise_on_open_redirects
option, which will be removed in a future Rails version. The new configuration provides more
flexible control over open redirect protection.

When set to :log, Rails will log a warning when an open redirect is detected.
When set to :notify, Rails will publish an open_redirect.action_controller
notification event. When set to :raise, Rails will raise an
ActionController::Redirecting::UnsafeRedirectError.

If raise_on_open_redirects is set to true, it will take precedence
over this configuration for backward compatibility, effectively forcing :raise
behavior.

The default value depends on the config.load_defaults target version:

#### 3.9.19. config.action_controller.action_on_path_relative_redirect

Controls how Rails handles paths relative URL redirects.

When set to :log (default), Rails will log a warning when a path relative URL redirect
is detected. When set to :notify, Rails will publish an
unsafe_redirect.action_controller notification event. When set to :raise, Rails
will raise an ActionController::Redirecting::UnsafeRedirectError.

This helps detect potentially unsafe redirects that could be exploited for open
redirect attacks.

The default value depends on the config.load_defaults target version:

#### 3.9.20. config.action_controller.log_query_tags_around_actions

Determines whether controller context for query tags will be automatically
updated via an around_filter. The default value is true.

#### 3.9.21. config.action_controller.wrap_parameters_by_default

Before Rails 7.0, new applications were generated with an initializer named
wrap_parameters.rb that enabled parameter wrapping in ActionController::Base
for JSON requests.

Setting this configuration value to true has the same behavior as the
initializer, allowing applications to remove the initializer if they do not wish
to customize parameter wrapping behavior.

Regardless of this value, applications can continue to customize the parameter
wrapping behavior as before in an initializer or per controller.

See ParamsWrapper for more information on parameter
wrapping.

The default value depends on the config.load_defaults target version:

#### 3.9.22. config.action_controller.allowed_redirect_hosts

Specifies a list of allowed hosts for redirects. redirect_to will allow redirects to them without raising an
UnsafeRedirectError error.

#### 3.9.23. ActionController::Base.wrap_parameters

Configures the ParamsWrapper. This can be called at
the top level, or on individual controllers.

#### 3.9.24. config.action_controller.escape_json_responses

Configures the JSON renderer to escape HTML entities and Unicode characters that are invalid in JavaScript.

This is useful if you relied on the JSON response having those characters escaped to embed the JSON document in
<script> tags in HTML.

This is mainly for compatibility when upgrading Rails applications, otherwise you can use the :escape option for
render json: in specific controller actions.

### 3.10. Configuring Action Dispatch

#### 3.10.1. config.action_dispatch.cookies_serializer

Specifies which serializer to use for cookies. Accepts the same values as
config.active_support.message_serializer,
plus :hybrid which is an alias for :json_allow_marshal.

The default value depends on the config.load_defaults target version:

#### 3.10.2. config.action_dispatch.debug_exception_log_level

Configures the log level used by the ActionDispatch::DebugExceptions
middleware when logging uncaught exceptions during requests.

The default value depends on the config.load_defaults target version:

#### 3.10.3. config.action_dispatch.default_headers

Is a hash with HTTP headers that are set by default in each response.

The default value depends on the config.load_defaults target version:

```
{  "X-Frame-Options" => "SAMEORIGIN",  "X-XSS-Protection" => "1; mode=block",  "X-Content-Type-Options" => "nosniff",  "X-Download-Options" => "noopen",  "X-Permitted-Cross-Domain-Policies" => "none",  "Referrer-Policy" => "strict-origin-when-cross-origin"}
```

```
{  "X-Frame-Options" => "SAMEORIGIN",  "X-XSS-Protection" => "0",  "X-Content-Type-Options" => "nosniff",  "X-Download-Options" => "noopen",  "X-Permitted-Cross-Domain-Policies" => "none",  "Referrer-Policy" => "strict-origin-when-cross-origin"}
```

```
{  "X-Frame-Options" => "SAMEORIGIN",  "X-XSS-Protection" => "0",  "X-Content-Type-Options" => "nosniff",  "X-Permitted-Cross-Domain-Policies" => "none",  "Referrer-Policy" => "strict-origin-when-cross-origin"}
```

#### 3.10.4. config.action_dispatch.default_charset

Specifies the default character set for all renders. Defaults to nil.

#### 3.10.5. config.action_dispatch.tld_length

Sets the TLD (top-level domain) length for the application. Defaults to 1.

#### 3.10.6. config.action_dispatch.domain_extractor

Configures the domain extraction strategy used by Action Dispatch for parsing host names into domain and subdomain components. This must be an object that responds to domain_from(host, tld_length) and subdomains_from(host, tld_length) methods.

Defaults to ActionDispatch::Http::URL::DomainExtractor, which provides the standard domain parsing logic. You can provide a custom extractor to implement specialized domain parsing behavior:

```ruby
class CustomDomainExtractor
  def self.domain_from(host, tld_length)
    # Custom domain extraction logic
  end

  def self.subdomains_from(host, tld_length)
    # Custom subdomain extraction logic
  end
end

config.action_dispatch.domain_extractor = CustomDomainExtractor
```

#### 3.10.7. config.action_dispatch.ignore_accept_header

Is used to determine whether to ignore accept headers from a request. Defaults to false.

#### 3.10.8. config.action_dispatch.x_sendfile_header

Specifies server specific X-Sendfile header. This is useful for accelerated file sending from server. For example it can be set to 'X-Sendfile' for Apache.

#### 3.10.9. config.action_dispatch.http_auth_salt

Sets the HTTP Auth salt value. Defaults
to 'http authentication'.

#### 3.10.10. config.action_dispatch.signed_cookie_salt

Sets the signed cookies salt value.
Defaults to 'signed cookie'.

#### 3.10.11. config.action_dispatch.encrypted_cookie_salt

Sets the encrypted cookies salt value. Defaults to 'encrypted cookie'.

#### 3.10.12. config.action_dispatch.encrypted_signed_cookie_salt

Sets the signed encrypted cookies salt value. Defaults to 'signed encrypted
cookie'.

#### 3.10.13. config.action_dispatch.authenticated_encrypted_cookie_salt

Sets the authenticated encrypted cookie salt. Defaults to 'authenticated
encrypted cookie'.

#### 3.10.14. config.action_dispatch.encrypted_cookie_cipher

Sets the cipher to be used for encrypted cookies. This defaults to
"aes-256-gcm".

#### 3.10.15. config.action_dispatch.signed_cookie_digest

Sets the digest to be used for signed cookies. This defaults to "SHA1".

#### 3.10.16. config.action_dispatch.cookies_rotations

Allows rotating secrets, ciphers, and digests for encrypted and signed cookies.

#### 3.10.17. config.action_dispatch.use_authenticated_cookie_encryption

Controls whether signed and encrypted cookies use the AES-256-GCM cipher or the
older AES-256-CBC cipher.

The default value depends on the config.load_defaults target version:

#### 3.10.18. config.action_dispatch.use_cookies_with_metadata

Enables writing cookies with the purpose metadata embedded.

The default value depends on the config.load_defaults target version:

#### 3.10.19. config.action_dispatch.perform_deep_munge

Configures whether deep_munge method should be performed on the parameters.
See Security Guide for more
information. It defaults to true.

#### 3.10.20. config.action_dispatch.rescue_responses

Configures what exceptions are assigned to an HTTP status. It accepts a hash and you can specify pairs of exception/status.

```ruby
# It's good to use #[]= or #merge! to respect the default values
config.action_dispatch.rescue_responses["MyAuthenticationError"] = :unauthorized
```

Use ActionDispatch::ExceptionWrapper.rescue_responses to observe the configuration. By default, it is defined as:

```ruby
{
  "ActionController::RoutingError" => :not_found,
  "AbstractController::ActionNotFound" => :not_found,
  "ActionController::MethodNotAllowed" => :method_not_allowed,
  "ActionController::UnknownHttpMethod" => :method_not_allowed,
  "ActionController::NotImplemented" => :not_implemented,
  "ActionController::UnknownFormat" => :not_acceptable,
  "ActionDispatch::Http::MimeNegotiation::InvalidType" => :not_acceptable,
  "ActionController::MissingExactTemplate" => :not_acceptable,
  "ActionController::InvalidAuthenticityToken" => :unprocessable_entity,
  "ActionController::InvalidCrossOriginRequest" => :unprocessable_entity,
  "ActionDispatch::Http::Parameters::ParseError" => :bad_request,
  "ActionController::BadRequest" => :bad_request,
  "ActionController::ParameterMissing" => :bad_request,
  "Rack::QueryParser::ParameterTypeError" => :bad_request,
  "Rack::QueryParser::InvalidParameterError" => :bad_request,
  "ActiveRecord::RecordNotFound" => :not_found,
  "ActiveRecord::StaleObjectError" => :conflict,
  "ActiveRecord::RecordInvalid" => :unprocessable_entity,
  "ActiveRecord::RecordNotSaved" => :unprocessable_entity
}
```

Any exceptions that are not configured will be mapped to 500 Internal Server Error.

#### 3.10.21. config.action_dispatch.cookies_same_site_protection

Configures the default value of the SameSite attribute when setting cookies.
When set to nil, the SameSite attribute is not added. To allow the value of
the SameSite attribute to be configured dynamically based on the request, a
proc may be specified. For example:

```ruby
config.action_dispatch.cookies_same_site_protection = ->(request) do
  :strict unless request.user_agent == "TestAgent"
end
```

The default value depends on the config.load_defaults target version:

#### 3.10.22. config.action_dispatch.ssl_default_redirect_status

Configures the default HTTP status code used when redirecting non-GET/HEAD
requests from HTTP to HTTPS in the ActionDispatch::SSL middleware.

The default value depends on the config.load_defaults target version:

#### 3.10.23. config.action_dispatch.log_rescued_responses

Enables logging those unhandled exceptions configured in rescue_responses. It
defaults to true.

#### 3.10.24. config.action_dispatch.show_exceptions

The config.action_dispatch.show_exceptions configuration controls how Action Pack (specifically the ActionDispatch::ShowExceptions middleware) handles exceptions raised while responding to requests.

Setting the value to :all configures Action Pack to rescue from exceptions and render corresponding error pages. For example, Action Pack would rescue from an ActiveRecord::RecordNotFound exception and render the contents of public/404.html with a 404 Not found status code.

Setting the value to :rescuable configures Action Pack to rescue from exceptions defined in config.action_dispatch.rescue_responses, and raise all others. For example, Action Pack would rescue from ActiveRecord::RecordNotFound, but would raise a NoMethodError.

Setting the value to :none configures Action Pack to raise all exceptions.

- :all - render error pages for all exceptions

- :rescuable - render error pages for exceptions declared by config.action_dispatch.rescue_responses

- :none - raise all exceptions

#### 3.10.25. config.action_dispatch.strict_freshness

Configures whether the ActionDispatch::ETag middleware should prefer the ETag header over the Last-Modified header when both are present in the response.

If set to true, when both headers are present only the ETag is considered as specified by RFC 7232 section 6.

If set to false, when both headers are present, both headers are checked and both need to match for the response to be considered fresh.

#### 3.10.26. config.action_dispatch.always_write_cookie

Cookies will be written at the end of a request if they marked as insecure, if the request is made over SSL, or if the request is made to an onion service.

If set to true, cookies will be written even if this criteria is not met.

This defaults to true in development, and false in all other environments.

#### 3.10.27. config.action_dispatch.verbose_redirect_logs

Specifies if source locations of redirects should be logged below relevant log lines. By default, the flag is true in development and false in all other environments.

#### 3.10.28. ActionDispatch::Callbacks.before

Takes a block of code to run before the request.

#### 3.10.29. ActionDispatch::Callbacks.after

Takes a block of code to run after the request.

### 3.11. Configuring Action View

config.action_view includes a small number of configuration settings:

#### 3.11.1. config.action_view.cache_template_loading

Controls whether or not templates should be reloaded on each request. Defaults to !config.enable_reloading.

#### 3.11.2. config.action_view.field_error_proc

Provides an HTML generator for displaying errors that come from Active Model. The block is evaluated within
the context of an Action View template. The default is

```ruby
Proc.new { |html_tag, instance| content_tag :div, html_tag, class: "field_with_errors" }
```

#### 3.11.3. config.action_view.default_form_builder

Tells Rails which form builder to use by default. The default is
ActionView::Helpers::FormBuilder. If you want your form builder class to be
loaded after initialization (so it's reloaded on each request in development),
you can pass it as a String.

#### 3.11.4. config.action_view.logger

Accepts a logger conforming to the interface of Log4r or the default Ruby Logger class, which is then used to log information from Action View. Set to nil to disable logging.

#### 3.11.5. config.action_view.erb_trim_mode

Controls if certain ERB syntax should trim. It defaults to '-', which turns on trimming of tail spaces and newline when using <%= -%> or <%= =%>. Setting this to anything else will turn off trimming support.

#### 3.11.6. config.action_view.frozen_string_literal

Compiles the ERB template with the # frozen_string_literal: true magic comment, making all string literals frozen and saving allocations. Set to true to enable it for all views.

#### 3.11.7. config.action_view.embed_authenticity_token_in_remote_forms

Allows you to set the default behavior for authenticity_token in forms with
remote: true. By default it's set to false, which means that remote forms
will not include authenticity_token, which is helpful when you're
fragment-caching the form. Remote forms get the authenticity from the meta
tag, so embedding is unnecessary unless you support browsers without
JavaScript. In such case you can either pass authenticity_token: true as a
form option or set this config setting to true.

#### 3.11.8. config.action_view.prefix_partial_path_with_controller_namespace

Determines whether or not partials are looked up from a subdirectory in templates rendered from namespaced controllers. For example, consider a controller named Admin::ArticlesController which renders this template:

```ruby
<%= render @article %>
```

The default setting is true, which uses the partial at /admin/articles/_article.erb. Setting the value to false would render /articles/_article.erb, which is the same behavior as rendering from a non-namespaced controller such as ArticlesController.

#### 3.11.9. config.action_view.automatically_disable_submit_tag

Determines whether submit_tag should automatically disable on click, this
defaults to true.

#### 3.11.10. config.action_view.debug_missing_translation

Determines whether to wrap the missing translations key in a <span> tag or not. This defaults to true.

#### 3.11.11. config.action_view.form_with_generates_remote_forms

Determines whether form_with generates remote forms or not.

The default value depends on the config.load_defaults target version:

#### 3.11.12. config.action_view.form_with_generates_ids

Determines whether form_with generates ids on inputs.

The default value depends on the config.load_defaults target version:

#### 3.11.13. config.action_view.default_enforce_utf8

Determines whether forms are generated with a hidden tag that forces older versions of Internet Explorer to submit forms encoded in UTF-8.

The default value depends on the config.load_defaults target version:

#### 3.11.14. config.action_view.image_loading

Specifies a default value for the loading attribute of <img> tags rendered by the image_tag helper. For example, when set to "lazy", <img> tags rendered by image_tag will include loading="lazy", which instructs the browser to wait until an image is near the viewport to load it. (This value can still be overridden per image by passing e.g. loading: "eager" to image_tag.) Defaults to nil.

#### 3.11.15. config.action_view.image_decoding

Specifies a default value for the decoding attribute of <img> tags rendered by the image_tag helper. Defaults to nil.

#### 3.11.16. config.action_view.annotate_rendered_view_with_filenames

Determines whether to annotate rendered view with template file names. This defaults to false.

#### 3.11.17. config.action_view.preload_links_header

Determines whether javascript_include_tag and stylesheet_link_tag will generate a link header that preload assets.

The default value depends on the config.load_defaults target version:

#### 3.11.18. config.action_view.button_to_generates_button_tag

When false, button_to will render a <button> or an <input> inside a
<form> depending on how content is passed (<form> omitted for brevity):

```ruby
<%= button_to "Content", "/" %>
# => <input type="submit" value="Content">

<%= button_to "/" do %>
  Content
<% end %>
# => <button type="submit">Content</button>
```

Setting this value to true makes button_to generate a <button> tag inside
the <form> in both cases.

The default value depends on the config.load_defaults target version:

#### 3.11.19. config.action_view.apply_stylesheet_media_default

Determines whether stylesheet_link_tag will render screen as the default
value for the media attribute when it's not provided.

The default value depends on the config.load_defaults target version:

#### 3.11.20. config.action_view.prepend_content_exfiltration_prevention

Determines whether or not the form_tag and button_to helpers will produce HTML tags prepended with browser-safe (but technically invalid) HTML that guarantees their contents cannot be captured by any preceding unclosed tags. The default value is false.

#### 3.11.21. config.action_view.sanitizer_vendor

Configures the set of HTML sanitizers used by Action View by setting ActionView::Helpers::SanitizeHelper.sanitizer_vendor. The default value depends on the config.load_defaults target version:

Rails::HTML5::Sanitizer is not supported on JRuby, so on JRuby platforms Rails will fall back to Rails::HTML4::Sanitizer.

#### 3.11.22. config.action_view.remove_hidden_field_autocomplete

When enabled, hidden inputs generated by form_tag, token_tag, method_tag, and the hidden parameter fields included in button_to forms will omit the autocomplete="off" attribute.

The default value depends on the config.load_defaults target version:

#### 3.11.23. config.action_view.render_tracker

Configures the strategy for tracking dependencies between Action View templates.

### 3.12. Configuring Action Mailbox

config.action_mailbox provides the following configuration options:

#### 3.12.1. config.action_mailbox.logger

Contains the logger used by Action Mailbox. It accepts a logger conforming to the interface of Log4r or the default Ruby Logger class. The default is Rails.logger.

```ruby
config.action_mailbox.logger = ActiveSupport::Logger.new(STDOUT)
```

#### 3.12.2. config.action_mailbox.incinerate_after

Accepts an ActiveSupport::Duration indicating how long after processing ActionMailbox::InboundEmail records should be destroyed. It defaults to 30.days.

```ruby
# Incinerate inbound emails 14 days after processing.
config.action_mailbox.incinerate_after = 14.days
```

#### 3.12.3. config.action_mailbox.queues.incineration

Accepts a symbol indicating the Active Job queue to use for incineration jobs.
When this option is nil, incineration jobs are sent to the default Active Job
queue (see config.active_job.default_queue_name).

The default value depends on the config.load_defaults target version:

#### 3.12.4. config.action_mailbox.queues.routing

Accepts a symbol indicating the Active Job queue to use for routing jobs. When
this option is nil, routing jobs are sent to the default Active Job queue (see
config.active_job.default_queue_name).

The default value depends on the config.load_defaults target version:

#### 3.12.5. config.action_mailbox.storage_service

Accepts a symbol indicating the Active Storage service to use for uploading emails. When this option is nil, emails are uploaded to the default Active Storage service (see config.active_storage.service).

### 3.13. Configuring Action Mailer

There are a number of settings available on config.action_mailer:

#### 3.13.1. config.action_mailer.asset_host

Sets the host for the assets. Useful when CDNs are used for hosting assets rather than the application server itself. You should only use this if you have a different configuration for Action Controller, otherwise use config.asset_host.

#### 3.13.2. config.action_mailer.logger

Accepts a logger conforming to the interface of Log4r or the default Ruby Logger class, which is then used to log information from Action Mailer. Set to nil to disable logging.

#### 3.13.3. config.action_mailer.smtp_settings

Allows detailed configuration for the :smtp delivery method. It accepts a hash of options, which can include any of these options:

- :address - Allows you to use a remote mail server. Just change it from its default "localhost" setting.

- :port - On the off chance that your mail server doesn't run on port 25, you can change it.

- :domain - If you need to specify a HELO domain, you can do it here.

- :user_name - If your mail server requires authentication, set the username in this setting.

- :password - If your mail server requires authentication, set the password in this setting.

- :authentication - If your mail server requires authentication, you need to specify the authentication type here. This is a symbol and one of :plain, :login, :cram_md5.

- :enable_starttls - Use STARTTLS when connecting to your SMTP server and fail if unsupported. It defaults to false.

- :enable_starttls_auto - Detects if STARTTLS is enabled in your SMTP server and starts to use it. It defaults to true.

- :openssl_verify_mode - When using TLS, you can set how OpenSSL checks the certificate. This is useful if you need to validate a self-signed and/or a wildcard certificate. This can be the name of one of the OpenSSL verify constants, 'none' or 'peer' - or the constant directly OpenSSL::SSL::VERIFY_NONE or OpenSSL::SSL::VERIFY_PEER, respectively.

- :ssl/:tls - Enables the SMTP connection to use SMTP/TLS (SMTPS: SMTP over direct TLS connection).

- :open_timeout - Number of seconds to wait while attempting to open a connection.

- :read_timeout - Number of seconds to wait until timing-out a read(2) call.

Additionally, it is possible to pass any configuration option Mail::SMTP respects.

#### 3.13.4. config.action_mailer.smtp_timeout

Prior to version 2.8.0, the mail gem did not configure any default timeouts
for its SMTP requests. This configuration enables applications to configure
default values for both :open_timeout and :read_timeout in the mail gem so
that requests do not end up stuck indefinitely.

The default value depends on the config.load_defaults target version:

#### 3.13.5. config.action_mailer.sendmail_settings

Allows detailed configuration for the :sendmail delivery method. It accepts a hash of options, which can include any of these options:

- :location - The location of the sendmail executable. Defaults to /usr/sbin/sendmail.

- :arguments - The command line arguments. Defaults to %w[ -i ].

#### 3.13.6. config.action_mailer.file_settings

Configures the :file delivery method. It accepts a hash of options, which can include:

- :location - The location where files are saved. Defaults to "#{Rails.root}/tmp/mails".

- :extension - The file extension. Defaults to the empty string.

#### 3.13.7. config.action_mailer.raise_delivery_errors

Specifies whether to raise an error if email delivery cannot be completed. It defaults to true.

#### 3.13.8. config.action_mailer.delivery_method

Defines the delivery method and defaults to :smtp. See the configuration section in the Action Mailer guide for more info.

#### 3.13.9. config.action_mailer.perform_deliveries

Specifies whether mail will actually be delivered and is true by default. It can be convenient to set it to false for testing.

#### 3.13.10. config.action_mailer.default_options

Configures Action Mailer defaults. Use to set options like from or reply_to for every mailer. These default to:

```ruby
{
  mime_version:  "1.0",
  charset:       "UTF-8",
  content_type: "text/plain",
  parts_order:  ["text/plain", "text/enriched", "text/html"]
}
```

Assign a hash to set additional options:

```ruby
config.action_mailer.default_options = {
  from: "noreply@example.com"
}
```

#### 3.13.11. config.action_mailer.observers

Registers observers which will be notified when mail is delivered.

```ruby
config.action_mailer.observers = ["MailObserver"]
```

#### 3.13.12. config.action_mailer.interceptors

Registers interceptors which will be called before mail is sent.

```ruby
config.action_mailer.interceptors = ["MailInterceptor"]
```

#### 3.13.13. config.action_mailer.preview_interceptors

Registers interceptors which will be called before mail is previewed.

```ruby
config.action_mailer.preview_interceptors = ["MyPreviewMailInterceptor"]
```

#### 3.13.14. config.action_mailer.preview_paths

Specifies the locations of mailer previews. Appending paths to this configuration option will cause those paths to be used in the search for mailer previews.

```ruby
config.action_mailer.preview_paths << "#{Rails.root}/lib/mailer_previews"
```

#### 3.13.15. config.action_mailer.show_previews

Enable or disable mailer previews. By default this is true in development.

```ruby
config.action_mailer.show_previews = false
```

#### 3.13.16. config.action_mailer.perform_caching

Specifies whether the mailer templates should perform fragment caching or not. If it's not specified, the default will be true.

#### 3.13.17. config.action_mailer.deliver_later_queue_name

Specifies the Active Job queue to use for the default delivery job (see
config.action_mailer.delivery_job). When this option is set to nil, delivery
jobs are sent to the default Active Job queue (see
config.active_job.default_queue_name).

Mailer classes can override this to use a different queue. Note that this only applies when using the default delivery job. If your mailer is using a custom job, its queue will be used.

Ensure that your Active Job adapter is also configured to process the specified queue, otherwise delivery jobs may be silently ignored.

The default value depends on the config.load_defaults target version:

#### 3.13.18. config.action_mailer.delivery_job

Specifies delivery job for mail.

The default value depends on the config.load_defaults target version:

### 3.14. Configuring Active Support

There are a few configuration options available in Active Support:

#### 3.14.1. config.active_support.bare

Enables or disables the loading of active_support/all when booting Rails. Defaults to nil, which means active_support/all is loaded.

#### 3.14.2. config.active_support.test_order

Sets the order in which the test cases are executed. Possible values are :random and :sorted. Defaults to :random.

#### 3.14.3. config.active_support.escape_html_entities_in_json

Enables or disables the escaping of HTML entities in JSON serialization. Defaults to true.

#### 3.14.4. config.active_support.use_standard_json_time_format

Enables or disables serializing dates to ISO 8601 format. Defaults to true.

#### 3.14.5. config.active_support.time_precision

Sets the precision of JSON encoded time values. Defaults to 3.

#### 3.14.6. config.active_support.hash_digest_class

Allows configuring the digest class to use to generate non-sensitive digests, such as the ETag header.

The default value depends on the config.load_defaults target version:

#### 3.14.7. config.active_support.key_generator_hash_digest_class

Allows configuring the digest class to use to derive secrets from the configured secret base, such as for encrypted cookies.

The default value depends on the config.load_defaults target version:

#### 3.14.8. config.active_support.use_authenticated_message_encryption

Specifies whether to use AES-256-GCM authenticated encryption as the default cipher for encrypting messages instead of AES-256-CBC.

The default value depends on the config.load_defaults target version:

#### 3.14.9. config.active_support.message_serializer

Specifies the default serializer used by ActiveSupport::MessageEncryptor
and ActiveSupport::MessageVerifier instances. To make migrating between
serializers easier, the provided serializers include a fallback mechanism to
support multiple deserialization formats:

Marshal is a potential vector for deserialization attacks in cases
where a message signing secret has been leaked. If possible, choose a
serializer that does not support Marshal.

The :message_pack and :message_pack_allow_marshal serializers support
roundtripping some Ruby types that are not supported by JSON, such as Symbol.
They can also provide improved performance and smaller payload sizes. However,
they require the msgpack gem.

Each of the above serializers will emit a message_serializer_fallback.active_support
event notification when they fall back to an alternate deserialization format,
allowing you to track how often such fallbacks occur.

Alternatively, you can specify any serializer object that responds to dump and
load methods. For example:

```ruby
config.active_support.message_serializer = YAML
```

The default value depends on the config.load_defaults target version:

#### 3.14.10. config.active_support.use_message_serializer_for_metadata

When true, enables a performance optimization that serializes message data and
metadata together. This changes the message format, so messages serialized this
way cannot be read by older (< 7.1) versions of Rails. However, messages that
use the old format can still be read, regardless of whether this optimization is
enabled.

The default value depends on the config.load_defaults target version:

#### 3.14.11. config.active_support.cache_format_version

Specifies which serialization format to use for the cache. Possible values are
7.0, and 7.1.

7.0 serializes cache entries more efficiently.

7.1 further improves efficiency, and allows expired and version-mismatched
cache entries to be detected without deserializing their values. It also
includes an optimization for bare string values such as view fragments.

All formats are backward and forward compatible, meaning cache entries written
in one format can be read when using another format. This behavior makes it
easy to migrate between formats without invalidating the entire cache.

The default value depends on the config.load_defaults target version:

#### 3.14.12. config.active_support.deprecation

Configures the behavior of deprecation warnings. See
Deprecation::Behavior for a description of the
available options.

In the default generated config/environments files, this is set to :log for
development and :stderr for test, and it is omitted for production in favor of
config.active_support.report_deprecations.

#### 3.14.13. config.active_support.disallowed_deprecation

Configures the behavior of disallowed deprecation warnings. See
Deprecation::Behavior for a description of the
available options.

This option is intended for development and test. For production, favor
config.active_support.report_deprecations.

#### 3.14.14. config.active_support.disallowed_deprecation_warnings

Configures deprecation warnings that the Application considers disallowed. This allows, for example, specific deprecations to be treated as hard failures.

#### 3.14.15. config.active_support.report_deprecations

When false, disables all deprecation warnings, including disallowed deprecations, from the application’s deprecators. This includes all the deprecations from Rails and other gems that may add their deprecator to the collection of deprecators, but may not prevent all deprecation warnings emitted from ActiveSupport::Deprecation.

In the default generated config/environments files, this is set to false for production.

#### 3.14.16. config.active_support.isolation_level

Configures the locality of most of Rails internal state. If you use a fiber based server or job processor (e.g. falcon), you should set it to :fiber. Otherwise it is best to use :thread locality. Defaults to :thread.

#### 3.14.17. config.active_support.executor_around_test_case

Configure the test suite to call Rails.application.executor.wrap around test cases.
This makes test cases behave closer to an actual request or job.
Several features that are normally disabled in test, such as Active Record query cache
and asynchronous queries will then be enabled.

The default value depends on the config.load_defaults target version:

#### 3.14.18. ActiveSupport::Logger.silencer

Is set to false to disable the ability to silence logging in a block. The default is true.

#### 3.14.19. ActiveSupport::Cache::Store.logger

Specifies the logger to use within cache store operations.

#### 3.14.20. ActiveSupport.utc_to_local_returns_utc_offset_times

Configures ActiveSupport::TimeZone.utc_to_local to return a time with a UTC
offset instead of a UTC time incorporating that offset.

The default value depends on the config.load_defaults target version:

#### 3.14.21. config.active_support.raise_on_invalid_cache_expiration_time

Specifies whether an ArgumentError should be raised if Rails.cache
fetch or write
are given an invalid expires_at or expires_in time.

Options are true and false. If false, the exception will be reported
as handled and logged instead.

The default value depends on the config.load_defaults target version:

#### 3.14.22. config.active_support.event_reporter_context_store

Configures a custom context store for the Event Reporter. The context store is used to manage metadata that should be attached to every event emitted by the reporter.

By default, the Event Reporter uses ActiveSupport::EventContext which stores context in fiber-local storage.

To use a custom context store, set this config to a class that implements the context store interface:

```ruby
# config/application.rb
config.active_support.event_reporter_context_store = CustomContextStore

class CustomContextStore
  class << self
    def context
      # Return the context hash
    end

    def set_context(context_hash)
      # Append context_hash to the existing context store
    end

    def clear
      # Clear the stored context
    end
  end
end
```

Defaults to nil, which means the default ActiveSupport::EventContext store is used.

#### 3.14.23. config.active_support.escape_js_separators_in_json

Specifies whether LINE SEPARATOR (U+2028) and PARAGRAPH SEPARATOR (U+2029) are escaped when generating JSON.

Historically these characters were not valid inside JavaScript literal strings but that changed in ECMAScript 2019.
As such it's no longer a concern in modern browsers: https://caniuse.com/mdn-javascript_builtins_json_json_superset.

The default value depends on the config.load_defaults target version:

### 3.15. Configuring Active Job

config.active_job provides the following configuration options:

#### 3.15.1. config.active_job.queue_adapter

Sets the adapter for the queuing backend. The default adapter is :async. For an up-to-date list of built-in adapters see the ActiveJob::QueueAdapters API documentation.

```ruby
# Be sure to have the adapter's gem in your Gemfile
# and follow the adapter's specific installation
# and deployment instructions.
config.active_job.queue_adapter = :sidekiq
```

#### 3.15.2. config.active_job.default_queue_name

Can be used to change the default queue name. By default this is "default".

```ruby
config.active_job.default_queue_name = :medium_priority
```

#### 3.15.3. config.active_job.queue_name_prefix

Allows you to set an optional, non-blank, queue name prefix for all jobs. By default it is blank and not used.

The following configuration would queue the given job on the production_high_priority queue when run in production:

```ruby
config.active_job.queue_name_prefix = Rails.env
```

```ruby
class GuestsCleanupJob < ActiveJob::Base
  queue_as :high_priority
  #....
end
```

#### 3.15.4. config.active_job.queue_name_delimiter

Has a default value of '_'. If queue_name_prefix is set, then queue_name_delimiter joins the prefix and the non-prefixed queue name.

The following configuration would queue the provided job on the video_server.low_priority queue:

```ruby
# prefix must be set for delimiter to be used
config.active_job.queue_name_prefix = "video_server"
config.active_job.queue_name_delimiter = "."
```

```ruby
class EncoderJob < ActiveJob::Base
  queue_as :low_priority
  #....
end
```

#### 3.15.5. config.active_job.logger

Accepts a logger conforming to the interface of Log4r or the default Ruby Logger class, which is then used to log information from Active Job. You can retrieve this logger by calling logger on either an Active Job class or an Active Job instance. Set to nil to disable logging.

#### 3.15.6. config.active_job.custom_serializers

Allows to set custom argument serializers. Defaults to [].

#### 3.15.7. config.active_job.log_arguments

Controls if the arguments of a job are logged. Defaults to true.

#### 3.15.8. config.active_job.verbose_enqueue_logs

Specifies if source locations of methods that enqueue background jobs should be logged below relevant enqueue log lines. By default, the flag is true in development and false in all other environments.

#### 3.15.9. config.active_job.retry_jitter

Controls the amount of "jitter" (random variation) applied to the delay time calculated when retrying failed jobs.

The default value depends on the config.load_defaults target version:

#### 3.15.10. config.active_job.log_query_tags_around_perform

Determines whether job context for query tags will be automatically updated via
an around_perform. The default value is true.

### 3.16. Configuring Action Cable

#### 3.16.1. config.action_cable.url

Accepts a string for the URL for where you are hosting your Action Cable
server. You would use this option if you are running Action Cable servers that
are separated from your main application.

#### 3.16.2. config.action_cable.mount_path

Accepts a string for where to mount Action Cable, as part of the main server
process. Defaults to /cable. You can set this as nil to not mount Action
Cable as part of your normal Rails server.

You can find more detailed configuration options in the
Action Cable Overview.

#### 3.16.3. config.action_cable.precompile_assets

Determines whether the Action Cable assets should be added to the asset pipeline precompilation. It
has no effect if Sprockets is not used. The default value is true.

#### 3.16.4. config.action_cable.allow_same_origin_as_host

Determines whether an origin matching the cable server itself will be permitted.
The default value is true.

Set to false to disable automatic access for same-origin requests, and strictly allow
only the configured origins.

#### 3.16.5. config.action_cable.allowed_request_origins

Determines the request origins which will be accepted by the cable server.
The default value is /https?:\/\/localhost:\d+/ in the development environment.

### 3.17. Configuring Active Storage

config.active_storage provides the following configuration options:

#### 3.17.1. config.active_storage.variant_processor

Accepts a symbol :mini_magick, :vips, or :disabled specifying whether or not variant transformations and blob analysis will be performed with MiniMagick or ruby-vips.

The default value depends on the config.load_defaults target version:

#### 3.17.2. config.active_storage.analyzers

Accepts an array of classes indicating the analyzers available for Active Storage blobs.
By default, this is defined as:

```ruby
config.active_storage.analyzers = [
  ActiveStorage::Analyzer::ImageAnalyzer::Vips,
  ActiveStorage::Analyzer::ImageAnalyzer::ImageMagick,
  ActiveStorage::Analyzer::VideoAnalyzer,
  ActiveStorage::Analyzer::AudioAnalyzer
]
```

The image analyzers can extract width and height of an image blob; the video analyzer can extract width, height, duration, angle, aspect ratio, and presence/absence of video/audio channels of a video blob; the audio analyzer can extract duration and bit rate of an audio blob.

If you want to disable analyzers, you can set this to an empty array:

```ruby
config.active_storage.analyzers = []
```

#### 3.17.3. config.active_storage.previewers

Accepts an array of classes indicating the image previewers available in Active Storage blobs.
By default, this is defined as:

```ruby
config.active_storage.previewers = [ActiveStorage::Previewer::PopplerPDFPreviewer, ActiveStorage::Previewer::MuPDFPreviewer, ActiveStorage::Previewer::VideoPreviewer]
```

PopplerPDFPreviewer and MuPDFPreviewer can generate a thumbnail from the first page of a PDF blob; VideoPreviewer from the relevant frame of a video blob.

#### 3.17.4. config.active_storage.paths

Accepts a hash of options indicating the locations of previewer/analyzer commands. The default is {}, meaning the commands will be looked for in the default path. Can include any of these options:

- :ffprobe - The location of the ffprobe executable.

- :mutool - The location of the mutool executable.

- :ffmpeg - The location of the ffmpeg executable.

```ruby
config.active_storage.paths[:ffprobe] = "/usr/local/bin/ffprobe"
```

#### 3.17.5. config.active_storage.variable_content_types

Accepts an array of strings indicating the content types that Active Storage
can transform through the variant processor.
By default, this is defined as:

```ruby
config.active_storage.variable_content_types = %w(image/png image/gif image/jpeg image/tiff image/bmp image/vnd.adobe.photoshop image/vnd.microsoft.icon image/webp image/avif image/heic image/heif)
```

#### 3.17.6. config.active_storage.web_image_content_types

Accepts an array of strings regarded as web image content types in which
variants can be processed without being converted to the fallback PNG format.
For example, if you want to use AVIF variants in your application you can add
image/avif to this array.

The default value depends on the config.load_defaults target version:

#### 3.17.7. config.active_storage.content_types_to_serve_as_binary

Accepts an array of strings indicating the content types that Active Storage will always serve as an attachment, rather than inline.
By default, this is defined as:

```ruby
config.active_storage.content_types_to_serve_as_binary = %w(text/html image/svg+xml application/postscript application/x-shockwave-flash text/xml application/xml application/xhtml+xml application/mathml+xml text/cache-manifest)
```

#### 3.17.8. config.active_storage.content_types_allowed_inline

Accepts an array of strings indicating the content types that Active Storage allows to serve as inline.
By default, this is defined as:

```ruby
config.active_storage.content_types_allowed_inline = %w(image/webp image/avif image/png image/gif image/jpeg image/tiff image/vnd.adobe.photoshop image/vnd.microsoft.icon application/pdf)
```

#### 3.17.9. config.active_storage.queues.analysis

Accepts a symbol indicating the Active Job queue to use for analysis jobs. When
this option is nil, analysis jobs are sent to the default Active Job queue
(see config.active_job.default_queue_name).

The default value depends on the config.load_defaults target version:

#### 3.17.10. config.active_storage.queues.mirror

Accepts a symbol indicating the Active Job queue to use for direct upload
mirroring jobs. When this option is nil, mirroring jobs are sent to the
default Active Job queue (see config.active_job.default_queue_name). The
default is nil.

#### 3.17.11. config.active_storage.queues.preview_image

Accepts a symbol indicating the Active Job queue to use for preprocessing
previews of images. When this option is nil, jobs are sent to the default
Active Job queue (see config.active_job.default_queue_name). The default
is nil.

#### 3.17.12. config.active_storage.queues.purge

Accepts a symbol indicating the Active Job queue to use for purge jobs. When
this option is nil, purge jobs are sent to the default Active Job queue (see
config.active_job.default_queue_name).

The default value depends on the config.load_defaults target version:

#### 3.17.13. config.active_storage.queues.transform

Accepts a symbol indicating the Active Job queue to use for preprocessing
variants. When this option is nil, jobs are sent to the default Active Job
queue (see config.active_job.default_queue_name). The default is nil.

#### 3.17.14. config.active_storage.logger

Can be used to set the logger used by Active Storage. Accepts a logger conforming to the interface of Log4r or the default Ruby Logger class.

```ruby
config.active_storage.logger = ActiveSupport::Logger.new(STDOUT)
```

#### 3.17.15. config.active_storage.service_urls_expire_in

Determines the default expiry of URLs generated by:

- ActiveStorage::Blob#url

- ActiveStorage::Blob#service_url_for_direct_upload

- ActiveStorage::Preview#url

- ActiveStorage::Variant#url

The default is 5 minutes.

#### 3.17.16. config.active_storage.urls_expire_in

Determines the default expiry of URLs in the Rails application generated by Active Storage. The default is nil.

#### 3.17.17. config.active_storage.touch_attachment_records

Directs ActiveStorage::Attachments to touch its corresponding record when updated. The default is true.

#### 3.17.18. config.active_storage.routes_prefix

Can be used to set the route prefix for the routes served by Active Storage. Accepts a string that will be prepended to the generated routes.

```ruby
config.active_storage.routes_prefix = "/files"
```

The default is /rails/active_storage.

#### 3.17.19. config.active_storage.track_variants

Determines whether variants are recorded in the database.

The default value depends on the config.load_defaults target version:

#### 3.17.20. config.active_storage.draw_routes

Can be used to toggle Active Storage route generation. The default is true.

#### 3.17.21. config.active_storage.resolve_model_to_route

Can be used to globally change how Active Storage files are delivered.

Allowed values are:

- :rails_storage_redirect: Redirect to signed, short-lived service URLs.

- :rails_storage_proxy: Proxy files by downloading them.

The default is :rails_storage_redirect.

#### 3.17.22. config.active_storage.video_preview_arguments

Can be used to alter the way ffmpeg generates video preview images.

The default value depends on the config.load_defaults target version:

- Select the first video frame, plus keyframes, plus frames that meet the scene change threshold.

- Use the first video frame as a fallback when no other frames meet the criteria by looping the first (one or) two selected frames, then dropping the first looped frame.

#### 3.17.23. config.active_storage.multiple_file_field_include_hidden

In Rails 7.1 and beyond, Active Storage has_many_attached relationships will
default to replacing the current collection instead of appending to it. Thus
to support submitting an empty collection, when multiple_file_field_include_hidden
is true, the file_field
helper will render an auxiliary hidden field, similar to the auxiliary field
rendered by the checkbox
helper.

The default value depends on the config.load_defaults target version:

#### 3.17.24. config.active_storage.precompile_assets

Determines whether the Active Storage assets should be added to the asset pipeline precompilation. It
has no effect if Sprockets is not used. The default value is true.

### 3.18. Configuring Action Text

#### 3.18.1. config.action_text.attachment_tag_name

Accepts a string for the HTML tag used to wrap attachments. Defaults to "action-text-attachment".

#### 3.18.2. config.action_text.sanitizer_vendor

Configures the HTML sanitizer used by Action Text by setting ActionText::ContentHelper.sanitizer to an instance of the class returned from the vendor's .safe_list_sanitizer method. The default value depends on the config.load_defaults target version:

Rails::HTML5::Sanitizer is not supported on JRuby, so on JRuby platforms Rails will fall back to Rails::HTML4::Sanitizer.

#### 3.18.3. Regexp.timeout

See Ruby's documentation for Regexp.timeout=.

### 3.19. Configuring a Database

Just about every Rails application will interact with a database. You can connect to the database by setting an environment variable ENV['DATABASE_URL'] or by using a configuration file called config/database.yml.

Using the config/database.yml file you can specify all the information needed to access your database:

```yaml
development:
  adapter: postgresql
  database: blog_development
  pool: 5
```

This will connect to the database named blog_development using the postgresql adapter. This same information can be stored in a URL and provided via an environment variable like this:

```ruby
ENV["DATABASE_URL"] # => "postgresql://localhost/blog_development?pool=5"
```

The config/database.yml file contains sections for three different environments in which Rails can run by default:

- The development environment is used on your development/local computer as you interact manually with the application.

- The test environment is used when running automated tests.

- The production environment is used when you deploy your application for the world to use.

If you wish, you can manually specify a URL inside of your config/database.yml

```yaml
development:
  url: postgresql://localhost/blog_development?pool=5
```

The config/database.yml file can contain ERB tags <%= %>. Anything in the tags will be evaluated as Ruby code. You can use this to pull out data from an environment variable or to perform calculations to generate the needed connection information.

When using a ENV['DATABASE_URL'] or a url key in your config/database.yml
file, Rails allows mapping the protocol in the URL to a database adapter that
can be configured from within the application. This allows the adapter to be
configured without modifying the URL set in the deployment environment. See:
config.active_record.protocol_adapters.

You don't have to update the database configurations manually. If you look at the options of the application generator, you will see that one of the options is named --database. This option allows you to choose an adapter from a list of the most used relational databases. You can even run the generator repeatedly: cd .. && rails new blog --database=mysql. When you confirm the overwriting of the config/database.yml file, your application will be configured for MySQL instead of SQLite. Detailed examples of the common database connections are below.

### 3.20. Connection Preference

Since there are two ways to configure your connection (using config/database.yml or using an environment variable) it is important to understand how they can interact.

If you have an empty config/database.yml file but your ENV['DATABASE_URL'] is present, then Rails will connect to the database via your environment variable:

```bash
$ cat config/database.yml

$ echo $DATABASE_URL
postgresql://localhost/my_database
```

If you have a config/database.yml but no ENV['DATABASE_URL'] then this file will be used to connect to your database:

```bash
$ cat config/database.yml
development:
  adapter: postgresql
  database: my_database
  host: localhost

$ echo $DATABASE_URL
```

If you have both config/database.yml and ENV['DATABASE_URL'] set then Rails will merge the configuration together. To better understand this we must see some examples.

When duplicate connection information is provided the environment variable will take precedence:

```bash
$ cat config/database.yml
development:
  adapter: sqlite3
  database: NOT_my_database
  host: localhost

$ echo $DATABASE_URL
postgresql://localhost/my_database

$ bin/rails runner 'puts ActiveRecord::Base.configurations.inspect'
#<ActiveRecord::DatabaseConfigurations:0x00007fc8eab02880 @configurations=[
  #<ActiveRecord::DatabaseConfigurations::UrlConfig:0x00007fc8eab020b0
    @env_name="development", @spec_name="primary",
    @config={"adapter"=>"postgresql", "database"=>"my_database", "host"=>"localhost"}
    @url="postgresql://localhost/my_database">
  ]
```

Here the adapter, host, and database match the information in ENV['DATABASE_URL'].

If non-duplicate information is provided you will get all unique values, environment variable still takes precedence in cases of any conflicts.

```bash
$ cat config/database.yml
development:
  adapter: sqlite3
  pool: 5

$ echo $DATABASE_URL
postgresql://localhost/my_database

$ bin/rails runner 'puts ActiveRecord::Base.configurations.inspect'
#<ActiveRecord::DatabaseConfigurations:0x00007fc8eab02880 @configurations=[
  #<ActiveRecord::DatabaseConfigurations::UrlConfig:0x00007fc8eab020b0
    @env_name="development", @spec_name="primary",
    @config={"adapter"=>"postgresql", "database"=>"my_database", "host"=>"localhost", "pool"=>5}
    @url="postgresql://localhost/my_database">
  ]
```

Since pool is not in the ENV['DATABASE_URL'] provided connection information its information is merged in. Since adapter is duplicate, the ENV['DATABASE_URL'] connection information wins.

The only way to explicitly not use the connection information in ENV['DATABASE_URL'] is to specify an explicit URL connection using the "url" sub key:

```bash
$ cat config/database.yml
development:
  url: sqlite3:NOT_my_database

$ echo $DATABASE_URL
postgresql://localhost/my_database

$ bin/rails runner 'puts ActiveRecord::Base.configurations.inspect'
#<ActiveRecord::DatabaseConfigurations:0x00007fc8eab02880 @configurations=[
  #<ActiveRecord::DatabaseConfigurations::UrlConfig:0x00007fc8eab020b0
    @env_name="development", @spec_name="primary",
    @config={"adapter"=>"sqlite3", "database"=>"NOT_my_database"}
    @url="sqlite3:NOT_my_database">
  ]
```

Here the connection information in ENV['DATABASE_URL'] is ignored, note the different adapter and database name.

Since it is possible to embed ERB in your config/database.yml it is best practice to explicitly show you are using the ENV['DATABASE_URL'] to connect to your database. This is especially useful in production since you should not commit secrets like your database password into your source control (such as Git).

```bash
$ cat config/database.yml
production:
  url: <%= ENV['DATABASE_URL'] %>
```

Now the behavior is clear, that we are only using the connection information in ENV['DATABASE_URL'].

#### 3.20.1. Configuring an SQLite3 Database

Rails comes with built-in support for SQLite3, which is a lightweight serverless database application. While Rails better configures SQLite for production workloads, a busy production environment may overload SQLite. Rails defaults to using an SQLite database when creating a new project because it is a zero configuration database that just works, but you can always change it later.

Here's the section of the default configuration file (config/database.yml) with connection information for the development environment:

```yaml
development:
  adapter: sqlite3
  database: storage/development.sqlite3
  pool: 5
  timeout: 5000
```

SQLite extensions are supported when using sqlite3 gem v2.4.0 or later by configuring extensions:

```yaml
development:
  adapter: sqlite3
  extensions:
    - SQLean::UUID                     # module name responding to `.to_path`
    - .sqlpkg/nalgeon/crypto/crypto.so # or a filesystem path
    - <%= AppExtensions.location %>    # or ruby code returning a path
```

Many useful features can be added to SQLite through extensions. You may wish to browse the SQLite extension hub or use gems like sqlpkg-ruby and sqlean-ruby that simplify extension management.

Other configuration options are described in the SQLite3Adapter documentation.

#### 3.20.2. Configuring a MySQL or MariaDB Database

If you choose to use MySQL or MariaDB instead of the shipped SQLite3 database, your config/database.yml will look a little different. Here's the development section:

```yaml
development:
  adapter: mysql2
  encoding: utf8mb4
  database: blog_development
  pool: 5
  username: root
  password:
  socket: /tmp/mysql.sock
```

If your development database has a root user with an empty password, this configuration should work for you. Otherwise, change the username and password in the development section as appropriate.

If your MySQL version is 5.5 or 5.6 and want to use the utf8mb4 character set by default, please configure your MySQL server to support the longer key prefix by enabling innodb_large_prefix system variable.

Advisory Locks are enabled by default on MySQL and are used to make database migrations concurrent safe. You can disable advisory locks by setting advisory_locks to false:

```yaml
production:
  adapter: mysql2
  advisory_locks: false
```

#### 3.20.3. Configuring a PostgreSQL Database

If you choose to use PostgreSQL, your config/database.yml will be customized to use PostgreSQL databases:

```yaml
development:
  adapter: postgresql
  encoding: unicode
  database: blog_development
  pool: 5
```

By default Active Record uses a database feature called advisory locks. You might need to disable this feature if you're using an external connection pooler like PgBouncer:

```yaml
production:
  adapter: postgresql
  advisory_locks: false
```

If enabled, Active Record will create up to 1000 prepared statements per database connection by default. To modify this behavior you can set statement_limit to a different value:

```yaml
production:
  adapter: postgresql
  statement_limit: 200
```

The more prepared statements in use: the more memory your database will require. If your PostgreSQL database is hitting memory limits, try lowering statement_limit or disabling prepared statements.

#### 3.20.4. Configuring an SQLite3 Database for JRuby Platform

If you choose to use SQLite3 and are using JRuby, your config/database.yml will look a little different. Here's the development section:

```yaml
development:
  adapter: jdbcsqlite3
  database: storage/development.sqlite3
```

#### 3.20.5. Configuring a MySQL or MariaDB Database for JRuby Platform

If you choose to use MySQL or MariaDB and are using JRuby, your config/database.yml will look a little different. Here's the development section:

```yaml
development:
  adapter: jdbcmysql
  database: blog_development
  username: root
  password:
```

#### 3.20.6. Configuring a PostgreSQL Database for JRuby Platform

If you choose to use PostgreSQL and are using JRuby, your config/database.yml will look a little different. Here's the development section:

```yaml
development:
  adapter: jdbcpostgresql
  encoding: unicode
  database: blog_development
  username: blog
  password:
```

Change the username and password in the development section as appropriate.

#### 3.20.7. Configuring Metadata Storage

By default Rails will store information about your Rails environment and schema
in an internal table named ar_internal_metadata.

To turn this off per connection, set use_metadata_table in your database
configuration. This is useful when working with a shared database and/or
database user that cannot create tables.

```yaml
development:
  adapter: postgresql
  use_metadata_table: false
```

#### 3.20.8. Configuring Retry Behavior

By default, Rails will automatically reconnect to the database server and retry certain queries
if something goes wrong. Only safely retryable (idempotent) queries will be retried. The number
of retries can be specified in your the database configuration via connection_retries, or disabled
by setting the value to 0. The default number of retries is 1.

```yaml
development:
  adapter: mysql2
  connection_retries: 3
```

The database config also allows a retry_deadline to be configured. If a retry_deadline is configured,
an otherwise-retryable query will not be retried if the specified time has elapsed while the query was
first tried. For example, a retry_deadline of 5 seconds means that if 5 seconds have passed since a query
was first attempted, we won't retry the query, even if it is idempotent and there are connection_retries left.

This value defaults to nil, meaning that all retryable queries are retried regardless of time elapsed.
The value for this config should be specified in seconds.

```yaml
development:
  adapter: mysql2
  retry_deadline: 5 # Stop retrying queries after 5 seconds
```

#### 3.20.9. Configuring Query Cache

By default, Rails automatically caches the result sets returned by queries. If Rails encounters the same query
again for that request or job, it will use the cached result set as opposed to running the query against
the database again.

The query cache is stored in memory, and to avoid using too much memory, it automatically evicts the least recently
used queries when reaching a threshold. By default the threshold is 100, but can be configured in the database.yml.

```yaml
development:
  adapter: mysql2
  query_cache: 200
```

To entirely disable query caching, it can be set to false

```yaml
development:
  adapter: mysql2
  query_cache: false
```

### 3.21. Creating Rails Environments

By default Rails ships with three environments: "development", "test", and "production". While these are sufficient for most use cases, there are circumstances when you want more environments.

Imagine you have a server which mirrors the production environment but is only used for testing. Such a server is commonly called a "staging server". To define an environment called "staging" for this server, just create a file called config/environments/staging.rb. Since this is a production-like environment, you could copy the contents of config/environments/production.rb as a starting point and make the necessary changes from there. It's also possible to require and extend other environment configurations like this:

```ruby
# config/environments/staging.rb
require_relative "production"

Rails.application.configure do
  # Staging overrides
end
```

That environment is no different than the default ones, start a server with bin/rails server -e staging, a console with bin/rails console -e staging, Rails.env.staging? works, etc.

### 3.22. Deploy to a Subdirectory (relative URL root)

By default Rails expects that your application is running at the root
(e.g. /). This section explains how to run your application inside a directory.

Let's assume we want to deploy our application to "/app1". Rails needs to know
this directory to generate the appropriate routes:

```ruby
config.relative_url_root = "/app1"
```

alternatively you can set the RAILS_RELATIVE_URL_ROOT environment
variable.

Rails will now prepend "/app1" when generating links.

#### 3.22.1. Using Passenger

Passenger makes it easy to run your application in a subdirectory. You can find the relevant configuration in the Passenger manual.

#### 3.22.2. Using a Reverse Proxy

Deploying your application using a reverse proxy has definite advantages over traditional deploys. They allow you to have more control over your server by layering the components required by your application.

Many modern web servers can be used as a proxy server to balance third-party elements such as caching servers or application servers.

One such application server you can use is Unicorn to run behind a reverse proxy.

In this case, you would need to configure the proxy server (NGINX, Apache, etc) to accept connections from your application server (Unicorn). By default Unicorn will listen for TCP connections on port 8080, but you can change the port or configure it to use sockets instead.

You can find more information in the Unicorn readme and understand the philosophy behind it.

Once you've configured the application server, you must proxy requests to it by configuring your web server appropriately. For example your NGINX config may include:

```
upstream application_server {
  server 0.0.0.0:8080;
}

server {
  listen 80;
  server_name localhost;

  root /root/path/to/your_app/public;

  try_files $uri/index.html $uri.html @app;

  location @app {
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header Host $http_host;
    proxy_redirect off;
    proxy_pass http://application_server;
  }

  # some other configuration
}
```

Be sure to read the NGINX documentation for the most up-to-date information.

## 4. Rails Environment Settings

Some parts of Rails can also be configured externally by supplying environment variables. The following environment variables are recognized by various parts of Rails:

- ENV["RAILS_ENV"] defines the Rails environment (production, development, test, and so on) that Rails will run under.

- ENV["RAILS_RELATIVE_URL_ROOT"] is used by the routing code to recognize URLs when you deploy your application to a subdirectory.

- ENV["RAILS_CACHE_ID"] and ENV["RAILS_APP_VERSION"] are used to generate expanded cache keys in Rails' caching code. This allows you to have multiple separate caches from the same application.

ENV["RAILS_ENV"] defines the Rails environment (production, development, test, and so on) that Rails will run under.

ENV["RAILS_RELATIVE_URL_ROOT"] is used by the routing code to recognize URLs when you deploy your application to a subdirectory.

ENV["RAILS_CACHE_ID"] and ENV["RAILS_APP_VERSION"] are used to generate expanded cache keys in Rails' caching code. This allows you to have multiple separate caches from the same application.

## 5. Using Initializer Files

After loading the framework and any gems in your application, Rails turns to
loading initializers. An initializer is any Ruby file stored under
config/initializers in your application. You can use initializers to hold
configuration settings that should be made after all of the frameworks and gems
are loaded, such as options to configure settings for these parts.

The files in config/initializers (and any subdirectories of
config/initializers) are sorted and loaded one by one as part of
the load_config_initializers initializer.

If an initializer has code that relies on code in another initializer, you can
combine them into a single initializer instead. This makes the dependencies more
explicit, and can help surface new concepts within your application. Rails also
supports numbering of initializer file names, but this can lead to file name
churn. Explicitly loading initializers with require is not recommended, since
it will cause the initializer to get loaded twice.

There is no guarantee that your initializers will run after all the gem
initializers, so any initialization code that depends on a given gem having been
initialized should go into a config.after_initialize block.

## 6. Load Hooks

Rails code can often be referenced on load of an application. Rails is responsible for the load order of these frameworks, so when you load frameworks, such as ActiveRecord::Base, prematurely you are violating an implicit contract your application has with Rails. Moreover, by loading code such as ActiveRecord::Base on boot of your application you are loading entire frameworks which may slow down your boot time and could cause conflicts with load order and boot of your application.

Load and configuration hooks are the API that allow you to hook into this initialization process without violating the load contract with Rails. This will also mitigate boot performance degradation and avoid conflicts.

### 6.1. Avoid Loading Rails Frameworks

Since Ruby is a dynamic language, some code will cause different Rails frameworks to load. Take this snippet for instance:

```ruby
ActiveRecord::Base.include(MyActiveRecordHelper)
```

This snippet means that when this file is loaded, it will encounter ActiveRecord::Base. This encounter causes Ruby to look for the definition of that constant and will require it. This causes the entire Active Record framework to be loaded on boot.

ActiveSupport.on_load is a mechanism that can be used to defer the loading of code until it is actually needed. The snippet above can be changed to:

```ruby
ActiveSupport.on_load(:active_record) do
  include MyActiveRecordHelper
end
```

This new snippet will only include MyActiveRecordHelper when ActiveRecord::Base is loaded.

### 6.2. When are Hooks called?

In the Rails framework these hooks are called when a specific library is loaded. For example, when ActionController::Base is loaded, the :action_controller_base hook is called. This means that all ActiveSupport.on_load calls with :action_controller_base hooks will be called in the context of ActionController::Base (that means self will be an ActionController::Base).

### 6.3. Modifying Code to Use Load Hooks

Modifying code is generally straightforward. If you have a line of code that refers to a Rails framework such as ActiveRecord::Base you can wrap that code in a load hook.

Modifying calls to include

```ruby
ActiveRecord::Base.include(MyActiveRecordHelper)
```

becomes

```ruby
ActiveSupport.on_load(:active_record) do
  # self refers to ActiveRecord::Base here,
  # so we can call .include
  include MyActiveRecordHelper
end
```

Modifying calls to prepend

```ruby
ActionController::Base.prepend(MyActionControllerHelper)
```

becomes

```ruby
ActiveSupport.on_load(:action_controller_base) do
  # self refers to ActionController::Base here,
  # so we can call .prepend
  prepend MyActionControllerHelper
end
```

Modifying calls to class methods

```ruby
ActiveRecord::Base.include_root_in_json = true
```

becomes

```ruby
ActiveSupport.on_load(:active_record) do
  # self refers to ActiveRecord::Base here
  self.include_root_in_json = true
end
```

### 6.4. Available Load Hooks

These are the load hooks you can use in your own code. To hook into the initialization process of one of the following classes use the available hook.

## 7. Initialization Events

Rails has 5 initialization events which can be hooked into (listed in the order that they are run):

- before_configuration: This is run when the application class inherits from Rails::Application in config/application.rb. Before the class body is executed. Engines may use this hook to run code before the application itself gets configured.

- before_initialize: This is run directly before the initialization process of the application occurs with the :bootstrap_hook initializer near the beginning of the Rails initialization process.

- to_prepare: Run after the initializers are run for all Railties (including the application itself) and after the middleware stack is built, but before eager loading. More importantly, will run upon every code reload in development, but only once (during boot-up) in production and test.

- before_eager_load: This is run directly before eager loading occurs, which is the default behavior for the production environment and not for the development environment.

- after_initialize: Run directly after the initialization of the application, after the application initializers in config/initializers are run.

before_configuration: This is run when the application class inherits from Rails::Application in config/application.rb. Before the class body is executed. Engines may use this hook to run code before the application itself gets configured.

before_initialize: This is run directly before the initialization process of the application occurs with the :bootstrap_hook initializer near the beginning of the Rails initialization process.

to_prepare: Run after the initializers are run for all Railties (including the application itself) and after the middleware stack is built, but before eager loading. More importantly, will run upon every code reload in development, but only once (during boot-up) in production and test.

before_eager_load: This is run directly before eager loading occurs, which is the default behavior for the production environment and not for the development environment.

after_initialize: Run directly after the initialization of the application, after the application initializers in config/initializers are run.

To define an event for these hooks, use the block syntax within a Rails::Application, Rails::Railtie or Rails::Engine subclass:

```ruby
module YourApp
  class Application < Rails::Application
    config.before_initialize do
      # initialization code goes here
    end
  end
end
```

Alternatively, you can also do it through the config method on the Rails.application object:

```ruby
Rails.application.config.before_initialize do
  # initialization code goes here
end
```

Some parts of your application, notably routing, are not yet set up at the point where the after_initialize block is called.

### 7.1. Rails::Railtie#initializer

Rails has several initializers that run on startup that are all defined by using the initializer method from Rails::Railtie. Here's an example of the set_helpers_path initializer from Action Controller:

```ruby
initializer "action_controller.set_helpers_path" do |app|
  ActionController::Helpers.helpers_path = app.helpers_paths
end
```

The initializer method takes three arguments with the first being the name for the initializer and the second being an options hash (not shown here) and the third being a block. The :before key in the options hash can be specified to specify which initializer this new initializer must run before, and the :after key will specify which initializer to run this initializer after.

Initializers defined using the initializer method will be run in the order they are defined in, with the exception of ones that use the :before or :after methods.

You may put your initializer before or after any other initializer in the chain, as long as it is logical. Say you have 4 initializers called "one" through "four" (defined in that order) and you define "four" to go before "two" but after "three", that just isn't logical and Rails will not be able to determine your initializer order.

The block argument of the initializer method is the instance of the application itself, and so we can access the configuration on it by using the config method as done in the example.

Because Rails::Application inherits from Rails::Railtie (indirectly), you can use the initializer method in config/application.rb to define initializers for the application.

### 7.2. Initializers

Below is a comprehensive list of all the initializers found in Rails in the order that they are defined (and therefore run in, unless otherwise stated).

- load_environment_hook: Serves as a placeholder so that :load_environment_config can be defined to run before it.

- load_active_support: Optionally requires active_support/all if config.active_support.bare is un-truthful, which is the default.

- initialize_logger: Initializes the logger (an ActiveSupport::BroadcastLogger object) for the application and makes it accessible at Rails.logger, provided that no initializer inserted before this point has defined Rails.logger.

- initialize_cache: If Rails.cache isn't set yet, initializes the cache by referencing the value in config.cache_store and stores the outcome as Rails.cache. If this object responds to the middleware method, its middleware is inserted before Rack::Runtime in the middleware stack.

- set_clear_dependencies_hook: This initializer - which runs only if config.enable_reloading is set to true - uses ActionDispatch::Callbacks.after to remove the constants which have been referenced during the request from the object space so that they will be reloaded during the following request.

- bootstrap_hook: Runs all configured before_initialize blocks.

- i18n.callbacks: In the development environment, sets up a to_prepare callback which will call I18n.reload! if any of the locales have changed since the last request. In production this callback will only run on the first request.

- active_support.deprecation_behavior: Sets up deprecation reporting behavior for Rails.application.deprecators based on config.active_support.report_deprecations, config.active_support.deprecation, config.active_support.disallowed_deprecation, and config.active_support.disallowed_deprecation_warnings.

- active_support.initialize_time_zone: Sets the default time zone for the application based on the config.time_zone setting, which defaults to "UTC".

- active_support.initialize_beginning_of_week: Sets the default beginning of week for the application based on config.beginning_of_week setting, which defaults to :monday.

- active_support.set_configs: Sets up Active Support by using the settings in config.active_support by send'ing the method names as setters to ActiveSupport and passing the values through.

- action_dispatch.configure: Configures the ActionDispatch::Http::URL.tld_length to be set to the value of config.action_dispatch.tld_length.

- action_view.set_configs: Sets up Action View by using the settings in config.action_view by send'ing the method names as setters to ActionView::Base and passing the values through.

- action_controller.assets_config: Initializes the config.action_controller.assets_dir to the app's public directory if not explicitly configured.

- action_controller.set_helpers_path: Sets Action Controller's helpers_path to the application's helpers_path.

- action_controller.parameters_config: Configures strong parameters options for ActionController::Parameters.

- action_controller.set_configs: Sets up Action Controller by using the settings in config.action_controller by send'ing the method names as setters to ActionController::Base and passing the values through.

- action_controller.compile_config_methods: Initializes methods for the config settings specified so that they are quicker to access.

- active_record.initialize_timezone: Sets ActiveRecord::Base.time_zone_aware_attributes to true, as well as setting ActiveRecord::Base.default_timezone to UTC. When attributes are read from the database, they will be converted into the time zone specified by Time.zone.

- active_record.logger: Sets ActiveRecord::Base.logger - if it's not already set - to Rails.logger.

- active_record.migration_error: Configures middleware to check for pending migrations.

- active_record.check_schema_cache_dump: Loads the schema cache dump if configured and available.

- active_record.set_configs: Sets up Active Record by using the settings in config.active_record by send'ing the method names as setters to ActiveRecord::Base and passing the values through.

- active_record.initialize_database: Loads the database configuration (by default) from config/database.yml and establishes a connection for the current environment.

- active_record.log_runtime: Includes ActiveRecord::Railties::ControllerRuntime and ActiveRecord::Railties::JobRuntime which are responsible for reporting the time taken by Active Record calls for the request back to the logger.

- active_record.set_reloader_hooks: Resets all reloadable connections to the database if config.enable_reloading is set to true.

- active_record.add_watchable_files: Adds schema.rb and structure.sql files to watchable files.

- active_job.logger: Sets ActiveJob::Base.logger - if it's not already set -
to Rails.logger.

- active_job.set_configs: Sets up Active Job by using the settings in config.active_job by send'ing the method names as setters to ActiveJob::Base and passing the values through.

- action_mailer.logger: Sets ActionMailer::Base.logger - if it's not already set - to Rails.logger.

- action_mailer.set_configs: Sets up Action Mailer by using the settings in config.action_mailer by send'ing the method names as setters to ActionMailer::Base and passing the values through.

- action_mailer.compile_config_methods: Initializes methods for the config settings specified so that they are quicker to access.

- set_load_path: This initializer runs before bootstrap_hook. Adds paths
specified by config.paths.load_paths to $LOAD_PATH. And unless you set
config.add_autoload_paths_to_load_path to false, it will also add all
autoload paths specified by config.autoload_paths,
config.eager_load_paths, config.autoload_once_paths.

- set_autoload_paths: This initializer runs before bootstrap_hook. Adds all sub-directories of app and paths specified by config.autoload_paths, config.eager_load_paths and config.autoload_once_paths to ActiveSupport::Dependencies.autoload_paths.

- add_routing_paths: Loads (by default) all config/routes.rb files (in the application and railties, including engines) and sets up the routes for the application.

- add_locales: Adds the files in config/locales (from the application, railties, and engines) to I18n.load_path, making available the translations in these files.

- add_view_paths: Adds the directory app/views from the application, railties, and engines to the lookup path for view files for the application.

- add_mailer_preview_paths: Adds the directory test/mailers/previews from the application, railties, and engines to the lookup path for mailer preview files for the application.

- load_environment_config: This initializer runs before load_environment_hook. Loads the config/environments file for the current environment.

- prepend_helpers_path: Adds the directory app/helpers from the application, railties, and engines to the lookup path for helpers for the application.

- load_config_initializers: Loads all Ruby files from config/initializers in the application, railties, and engines. The files in this directory can be used to hold configuration settings that should be made after all of the frameworks are loaded.

- engines_blank_point: Provides a point-in-initialization to hook into if you wish to do anything before engines are loaded. After this point, all railtie and engine initializers are run.

- add_generator_templates: Finds templates for generators at lib/templates for the application, railties, and engines, and adds these to the config.generators.templates setting, which will make the templates available for all generators to reference.

- ensure_autoload_once_paths_as_subset: Ensures that the config.autoload_once_paths only contains paths from config.autoload_paths. If it contains extra paths, then an exception will be raised.

- add_to_prepare_blocks: The block for every config.to_prepare call in the application, a railtie, or engine is added to the to_prepare callbacks for Action Dispatch which will be run per request in development, or before the first request in production.

- add_builtin_route: If the application is running under the development environment then this will append the route for rails/info/properties to the application routes. This route provides the detailed information such as Rails and Ruby version for public/index.html in a default Rails application.

- build_middleware_stack: Builds the middleware stack for the application, returning an object which has a call method which takes a Rack environment object for the request.

- eager_load!: If config.eager_load is true, runs the config.before_eager_load hooks and then calls eager_load! which will load all config.eager_load_namespaces.

- finisher_hook: Provides a hook for after the initialization of process of the application is complete, as well as running all the config.after_initialize blocks for the application, railties, and engines.

- set_routes_reloader_hook: Configures Action Dispatch to reload the routes file using ActiveSupport::Callbacks.to_run.

- disable_dependency_loading: Disables the automatic dependency loading if the config.eager_load is set to true.

load_environment_hook: Serves as a placeholder so that :load_environment_config can be defined to run before it.

load_active_support: Optionally requires active_support/all if config.active_support.bare is un-truthful, which is the default.

initialize_logger: Initializes the logger (an ActiveSupport::BroadcastLogger object) for the application and makes it accessible at Rails.logger, provided that no initializer inserted before this point has defined Rails.logger.

initialize_cache: If Rails.cache isn't set yet, initializes the cache by referencing the value in config.cache_store and stores the outcome as Rails.cache. If this object responds to the middleware method, its middleware is inserted before Rack::Runtime in the middleware stack.

set_clear_dependencies_hook: This initializer - which runs only if config.enable_reloading is set to true - uses ActionDispatch::Callbacks.after to remove the constants which have been referenced during the request from the object space so that they will be reloaded during the following request.

bootstrap_hook: Runs all configured before_initialize blocks.

i18n.callbacks: In the development environment, sets up a to_prepare callback which will call I18n.reload! if any of the locales have changed since the last request. In production this callback will only run on the first request.

active_support.deprecation_behavior: Sets up deprecation reporting behavior for Rails.application.deprecators based on config.active_support.report_deprecations, config.active_support.deprecation, config.active_support.disallowed_deprecation, and config.active_support.disallowed_deprecation_warnings.

active_support.initialize_time_zone: Sets the default time zone for the application based on the config.time_zone setting, which defaults to "UTC".

active_support.initialize_beginning_of_week: Sets the default beginning of week for the application based on config.beginning_of_week setting, which defaults to :monday.

active_support.set_configs: Sets up Active Support by using the settings in config.active_support by send'ing the method names as setters to ActiveSupport and passing the values through.

action_dispatch.configure: Configures the ActionDispatch::Http::URL.tld_length to be set to the value of config.action_dispatch.tld_length.

action_view.set_configs: Sets up Action View by using the settings in config.action_view by send'ing the method names as setters to ActionView::Base and passing the values through.

action_controller.assets_config: Initializes the config.action_controller.assets_dir to the app's public directory if not explicitly configured.

action_controller.set_helpers_path: Sets Action Controller's helpers_path to the application's helpers_path.

action_controller.parameters_config: Configures strong parameters options for ActionController::Parameters.

action_controller.set_configs: Sets up Action Controller by using the settings in config.action_controller by send'ing the method names as setters to ActionController::Base and passing the values through.

action_controller.compile_config_methods: Initializes methods for the config settings specified so that they are quicker to access.

active_record.initialize_timezone: Sets ActiveRecord::Base.time_zone_aware_attributes to true, as well as setting ActiveRecord::Base.default_timezone to UTC. When attributes are read from the database, they will be converted into the time zone specified by Time.zone.

active_record.logger: Sets ActiveRecord::Base.logger - if it's not already set - to Rails.logger.

active_record.migration_error: Configures middleware to check for pending migrations.

active_record.check_schema_cache_dump: Loads the schema cache dump if configured and available.

active_record.set_configs: Sets up Active Record by using the settings in config.active_record by send'ing the method names as setters to ActiveRecord::Base and passing the values through.

active_record.initialize_database: Loads the database configuration (by default) from config/database.yml and establishes a connection for the current environment.

active_record.log_runtime: Includes ActiveRecord::Railties::ControllerRuntime and ActiveRecord::Railties::JobRuntime which are responsible for reporting the time taken by Active Record calls for the request back to the logger.

active_record.set_reloader_hooks: Resets all reloadable connections to the database if config.enable_reloading is set to true.

active_record.add_watchable_files: Adds schema.rb and structure.sql files to watchable files.

active_job.logger: Sets ActiveJob::Base.logger - if it's not already set -
to Rails.logger.

active_job.set_configs: Sets up Active Job by using the settings in config.active_job by send'ing the method names as setters to ActiveJob::Base and passing the values through.

action_mailer.logger: Sets ActionMailer::Base.logger - if it's not already set - to Rails.logger.

action_mailer.set_configs: Sets up Action Mailer by using the settings in config.action_mailer by send'ing the method names as setters to ActionMailer::Base and passing the values through.

action_mailer.compile_config_methods: Initializes methods for the config settings specified so that they are quicker to access.

set_load_path: This initializer runs before bootstrap_hook. Adds paths
specified by config.paths.load_paths to $LOAD_PATH. And unless you set
config.add_autoload_paths_to_load_path to false, it will also add all
autoload paths specified by config.autoload_paths,
config.eager_load_paths, config.autoload_once_paths.

set_autoload_paths: This initializer runs before bootstrap_hook. Adds all sub-directories of app and paths specified by config.autoload_paths, config.eager_load_paths and config.autoload_once_paths to ActiveSupport::Dependencies.autoload_paths.

add_routing_paths: Loads (by default) all config/routes.rb files (in the application and railties, including engines) and sets up the routes for the application.

add_locales: Adds the files in config/locales (from the application, railties, and engines) to I18n.load_path, making available the translations in these files.

add_view_paths: Adds the directory app/views from the application, railties, and engines to the lookup path for view files for the application.

add_mailer_preview_paths: Adds the directory test/mailers/previews from the application, railties, and engines to the lookup path for mailer preview files for the application.

load_environment_config: This initializer runs before load_environment_hook. Loads the config/environments file for the current environment.

prepend_helpers_path: Adds the directory app/helpers from the application, railties, and engines to the lookup path for helpers for the application.

load_config_initializers: Loads all Ruby files from config/initializers in the application, railties, and engines. The files in this directory can be used to hold configuration settings that should be made after all of the frameworks are loaded.

engines_blank_point: Provides a point-in-initialization to hook into if you wish to do anything before engines are loaded. After this point, all railtie and engine initializers are run.

add_generator_templates: Finds templates for generators at lib/templates for the application, railties, and engines, and adds these to the config.generators.templates setting, which will make the templates available for all generators to reference.

ensure_autoload_once_paths_as_subset: Ensures that the config.autoload_once_paths only contains paths from config.autoload_paths. If it contains extra paths, then an exception will be raised.

add_to_prepare_blocks: The block for every config.to_prepare call in the application, a railtie, or engine is added to the to_prepare callbacks for Action Dispatch which will be run per request in development, or before the first request in production.

add_builtin_route: If the application is running under the development environment then this will append the route for rails/info/properties to the application routes. This route provides the detailed information such as Rails and Ruby version for public/index.html in a default Rails application.

build_middleware_stack: Builds the middleware stack for the application, returning an object which has a call method which takes a Rack environment object for the request.

eager_load!: If config.eager_load is true, runs the config.before_eager_load hooks and then calls eager_load! which will load all config.eager_load_namespaces.

finisher_hook: Provides a hook for after the initialization of process of the application is complete, as well as running all the config.after_initialize blocks for the application, railties, and engines.

set_routes_reloader_hook: Configures Action Dispatch to reload the routes file using ActiveSupport::Callbacks.to_run.

disable_dependency_loading: Disables the automatic dependency loading if the config.eager_load is set to true.

## 8. Database Pooling

Active Record database connections are managed by ActiveRecord::ConnectionAdapters::ConnectionPool which ensures that a connection pool synchronizes the amount of thread access to a limited number of database connections. This limit defaults to 5 and can be configured in database.yml.

```yaml
development:
  adapter: sqlite3
  database: storage/development.sqlite3
  pool: 5
  timeout: 5000
```

Since the connection pooling is handled inside of Active Record by default, all application servers (Thin, Puma, Unicorn, etc.) should behave the same. The database connection pool is initially empty. As demand for connections increases it will create them until it reaches the connection pool limit.

Any one request will check out a connection the first time it requires access to the database. At the end of the request it will check the connection back in. This means that the additional connection slot will be available again for the next request in the queue.

If you try to use more connections than are available, Active Record will block
you and wait for a connection from the pool. If it cannot get a connection, a
timeout error similar to that given below will be thrown.

```
ActiveRecord::ConnectionTimeoutError - could not obtain a database connection within 5.000 seconds (waited 5.000 seconds)
```

If you get the above error, you might want to increase the size of the
connection pool by incrementing the pool option in database.yml

If you are running in a multi-threaded environment, there could be a chance that several threads may be accessing multiple connections simultaneously. So depending on your current request load, you could very well have multiple threads contending for a limited number of connections.

## 9. Custom Configuration

You can configure your own code through the Rails configuration object with
custom configuration under either the config.x namespace, or config directly.
The key difference between these two is that you should be using config.x if you
are defining nested configuration (ex: config.x.nested.hi), and just
config for single level configuration (ex: config.hello).

```ruby
config.x.payment_processing.schedule = :daily
config.x.payment_processing.retries  = 3
config.super_debugger = true
```

These configuration points are then available through the configuration object:

```ruby
Rails.configuration.x.payment_processing.schedule # => :daily
Rails.configuration.x.payment_processing.retries  # => 3
Rails.configuration.x.payment_processing.not_set  # => nil
Rails.configuration.super_debugger                # => true
```

You can also use Rails::Application.config_for to load whole configuration files:

```yaml
# config/payment.yml
production:
  environment: production
  merchant_id: production_merchant_id
  public_key:  production_public_key
  private_key: production_private_key

development:
  environment: sandbox
  merchant_id: development_merchant_id
  public_key:  development_public_key
  private_key: development_private_key
```

```ruby
# config/application.rb
module MyApp
  class Application < Rails::Application
    config.payment = config_for(:payment)
  end
end
```

```ruby
Rails.configuration.payment["merchant_id"] # => production_merchant_id or development_merchant_id
```

Rails::Application.config_for supports a shared configuration to group common
configurations. The shared configuration will be merged into the environment
configuration.

```yaml
# config/example.yml
shared:
  foo:
    bar:
      baz: 1

development:
  foo:
    bar:
      qux: 2
```

```ruby
# development environment
Rails.application.config_for[:example](:foo)[:bar] #=> { baz: 1, qux: 2 }
```

## 10. Search Engines Indexing

Sometimes, you may want to prevent some pages of your application to be visible
on search sites like Google, Bing, Yahoo, or Duck Duck Go. The robots that index
these sites will first analyze the http://your-site.com/robots.txt file to
know which pages it is allowed to index.

Rails creates this file for you inside the /public folder. By default, it allows
search engines to index all pages of your application. If you want to block
indexing on all pages of your application, use this:

```
User-agent: *
Disallow: /
```

To block just specific pages, it's necessary to use a more complex syntax. Learn
it on the official documentation.

---

# Chapters

This guide explains the internals of the initialization process in Rails.
It is an extremely in-depth guide and recommended for advanced Rails developers.

After reading this guide, you will know:

- How to use bin/rails server.

- The timeline of Rails' initialization sequence.

- Where different files are required by the boot sequence.

- How the Rails::Server interface is defined and used.

This guide goes through every method call that is
required to boot up the Ruby on Rails stack for a default Rails
application, explaining each part in detail along the way. For this
guide, we will be focusing on what happens when you execute bin/rails server
to boot your app.

Paths in this guide are relative to Rails or a Rails application unless otherwise specified.

If you want to follow along while browsing the Rails source
code, we recommend that you use the t
key binding to open the file finder inside GitHub and find files
quickly.

## 1. Launch!

Let's start to boot and initialize the app. A Rails application is usually
started by running bin/rails console or bin/rails server.

### 1.1. bin/rails

This file is as follows:

```ruby
#!/usr/bin/env ruby
APP_PATH = File.expand_path("../config/application", __dir__)
require_relative "../config/boot"
require "rails/commands"
```

The APP_PATH constant will be used later in rails/commands. The config/boot file referenced here is the config/boot.rb file in our application which is responsible for loading Bundler and setting it up.

### 1.2. config/boot.rb

config/boot.rb contains:

```ruby
ENV["BUNDLE_GEMFILE"] ||= File.expand_path("../Gemfile", __dir__)

require "bundler/setup" # Set up gems listed in the Gemfile.
require "bootsnap/setup" # Speed up boot time by caching expensive operations.
```

In a standard Rails application, there's a Gemfile which declares all
dependencies of the application. config/boot.rb sets
ENV['BUNDLE_GEMFILE'] to the location of this file. If the Gemfile
exists, then bundler/setup is required. The require is used by Bundler to
configure the load path for your Gemfile's dependencies.

### 1.3. rails/commands.rb

Once config/boot.rb has finished, the next file that is required is
rails/commands, which helps in expanding aliases. In the current case, the
ARGV array simply contains server which will be passed over:

```ruby
require "rails/command"

aliases = {
  "g"  => "generate",
  "d"  => "destroy",
  "c"  => "console",
  "s"  => "server",
  "db" => "dbconsole",
  "r"  => "runner",
  "t"  => "test"
}

command = ARGV.shift
command = aliases[command] || command

Rails::Command.invoke command, ARGV
```

If we had used s rather than server, Rails would have used the aliases
defined here to find the matching command.

### 1.4. rails/command.rb

When one types a Rails command, invoke tries to lookup a command for the given
namespace and executes the command if found.

If Rails doesn't recognize the command, it hands the reins over to Rake
to run a task of the same name.

As shown, Rails::Command displays the help output automatically if the namespace
is empty.

```ruby
module Rails
  module Command
    class << self
      def invoke(full_namespace, args = [], **config)
        args = ["--help"] if rails_new_with_no_path?(args)

        full_namespace = full_namespace.to_s
        namespace, command_name = split_namespace(full_namespace)
        command = find_by_namespace(namespace, command_name)

        with_argv(args) do
          if command && command.all_commands[command_name]
            command.perform(command_name, args, config)
          else
            invoke_rake(full_namespace, args, config)
          end
        end
      rescue UnrecognizedCommandError => error
        if error.name == full_namespace && command && command_name == full_namespace
          command.perform("help", [], config)
        else
          puts error.detailed_message
        end
        exit(1)
      end
    end
  end
end
```

With the server command, Rails will further run the following code:

```ruby
module Rails
  module Command
    class ServerCommand < Base # :nodoc:
      def perform
        set_application_directory!
        prepare_restart

        Rails::Server.new(server_options).tap do |server|
          # Require application after server sets environment to propagate
          # the --environment option.
          require APP_PATH
          Dir.chdir(Rails.application.root)

          if server.serveable?
            print_boot_information(server.server, server.served_url)
            after_stop_callback = -> { say "Exiting" unless options[:daemon] }
            server.start(after_stop_callback)
          else
            say rack_server_suggestion(options[:using])
          end
        end
      end
    end
  end
end
```

This file will change into the Rails root directory (a path two directories up
from APP_PATH which points at config/application.rb), but only if the
config.ru file isn't found. This then starts up the Rails::Server class.

### 1.5. actionpack/lib/action_dispatch.rb

Action Dispatch is the routing component of the Rails framework.
It adds functionality like routing, session, and common middlewares.

### 1.6. rails/commands/server/server_command.rb

The Rails::Server class is defined in this file by inheriting from
Rackup::Server. When Rails::Server.new is called, this calls the initialize
method in rails/commands/server/server_command.rb:

```ruby
module Rails
  class Server < Rackup::Server
    def initialize(options = nil)
      @default_options = options || {}
      super(@default_options)
      set_environment
    end
  end
end
```

Firstly, super is called which calls the initialize method on Rackup::Server.

### 1.7. Rackup: lib/rackup/server.rb

Rackup::Server is responsible for providing a common server interface for all Rack-based applications, which Rails is now a part of.

The initialize method in Rackup::Server simply sets several variables:

```ruby
module Rackup
  class Server
    def initialize(options = nil)
      @ignore_options = []

      if options
        @use_default_options = false
        @options = options
        @app = options[:app] if options[:app]
      else
        @use_default_options = true
        @options = parse_options(ARGV)
      end
    end
  end
end
```

In this case, return value of Rails::Command::ServerCommand#server_options will be assigned to options.
When lines inside if statement is evaluated, a couple of instance variables will be set.

server_options method in Rails::Command::ServerCommand is defined as follows:

```ruby
module Rails
  module Command
    class ServerCommand < Base # :nodoc:
      no_commands do
        def server_options
          {
            user_supplied_options: user_supplied_options,
            server:                options[:using],
            log_stdout:            log_to_stdout?,
            Port:                  port,
            Host:                  host,
            DoNotReverseLookup:    true,
            config:                options[:config],
            environment:           environment,
            daemonize:             options[:daemon],
            pid:                   pid,
            caching:               options[:dev_caching],
            restart_cmd:           restart_command,
            early_hints:           early_hints
          }
        end
      end
    end
  end
end
```

The value will be assigned to instance variable @options.

After super has finished in Rackup::Server, we jump back to
rails/commands/server/server_command.rb. At this point, set_environment
is called within the context of the Rails::Server object.

```ruby
module Rails
  module Server
    def set_environment
      ENV["RAILS_ENV"] ||= options[:environment]
    end
  end
end
```

After initialize has finished, we jump back into the server command
where APP_PATH (which was set earlier) is required.

### 1.8. config/application

When require APP_PATH is executed, config/application.rb is loaded (recall
that APP_PATH is defined in bin/rails). This file exists in your application
and it's free for you to change based on your needs.

### 1.9. Rails::Server#start

After config/application is loaded, server.start is called. This method is
defined like this:

```ruby
module Rails
  class Server < ::Rackup::Server
    def start(after_stop_callback = nil)
      trap(:INT) { exit }
      create_tmp_directories
      setup_dev_caching
      log_to_stdout if options[:log_stdout]

      super()
      # ...
    end

    private
      def setup_dev_caching
        if options[:environment] == "development"
          Rails::DevCaching.enable_by_argument(options[:caching])
        end
      end

      def create_tmp_directories
        %w(cache pids sockets).each do |dir_to_make|
          FileUtils.mkdir_p(File.join(Rails.root, "tmp", dir_to_make))
        end
      end

      def log_to_stdout
        wrapped_app # touch the app so the logger is set up

        console = ActiveSupport::Logger.new(STDOUT)
        console.formatter = Rails.logger.formatter
        console.level = Rails.logger.level

        unless ActiveSupport::Logger.logger_outputs_to?(Rails.logger, STDERR, STDOUT)
          Rails.logger.broadcast_to(console)
        end
      end
  end
end
```

This method creates a trap for INT signals, so if you CTRL-C the server, it will exit the process.
As we can see from the code here, it will create the tmp/cache,
tmp/pids, and tmp/sockets directories. It then enables caching in development
if bin/rails server is called with --dev-caching. Finally, it calls wrapped_app which is
responsible for creating the Rack app, before creating and assigning an instance
of ActiveSupport::Logger.

The super method will call Rackup::Server.start which begins its definition as follows:

```ruby
module Rackup
  class Server
    def start(&block)
      if options[:warn]
        $-w = true
      end

      if includes = options[:include]
        $LOAD_PATH.unshift(*includes)
      end

      Array(options[:require]).each do |library|
        require library
      end

      if options[:debug]
        $DEBUG = true
        require "pp"
        p options[:server]
        pp wrapped_app
        pp app
      end

      check_pid! if options[:pid]

      # Touch the wrapped app, so that the config.ru is loaded before
      # daemonization (i.e. before chdir, etc).
      handle_profiling(options[:heapfile], options[:profile_mode], options[:profile_file]) do
        wrapped_app
      end

      daemonize_app if options[:daemonize]

      write_pid if options[:pid]

      trap(:INT) do
        if server.respond_to?(:shutdown)
          server.shutdown
        else
          exit
        end
      end

      server.run(wrapped_app, **options, &block)
    end
  end
end
```

The interesting part for a Rails app is the last line, server.run. Here we encounter the wrapped_app method again, which this time
we're going to explore more (even though it was executed before, and
thus memoized by now).

```ruby
module Rackup
  class Server
    def wrapped_app
      @wrapped_app ||= build_app app
    end
  end
end
```

The app method here is defined like so:

```ruby
module Rackup
  class Server
    def app
      @app ||= options[:builder] ? build_app_from_string : build_app_and_options_from_config
    end

    # ...

    private
      def build_app_and_options_from_config
        if !::File.exist? options[:config]
          abort "configuration #{options[:config]} not found"
        end

        Rack::Builder.parse_file(self.options[:config])
      end

      def build_app_from_string
        Rack::Builder.new_from_string(self.options[:builder])
      end
  end
end
```

The options[:config] value defaults to config.ru which contains this:

```ruby
# This file is used by Rack-based servers to start the application.

require_relative "config/environment"

run Rails.application
Rails.application.load_server
```

The Rack::Builder.parse_file method here takes the content from this config.ru file and parses it using this code:

```ruby
module Rack
  class Builder
    def self.load_file(path, **options)
      # ...
      new_from_string(config, path, **options)
    end

    # ...

    def self.new_from_string(builder_script, path = "(rackup)", **options)
      builder = self.new(**options)

      # We want to build a variant of TOPLEVEL_BINDING with self as a Rack::Builder instance.
      # We cannot use instance_eval(String) as that would resolve constants differently.
      binding = BUILDER_TOPLEVEL_BINDING.call(builder)
      eval(builder_script, binding, path)

      builder.to_app
    end
  end
end
```

The initialize method of Rack::Builder will take the block here and execute it within an instance of Rack::Builder.
This is where the majority of the initialization process of Rails happens.
The require line for config/environment.rb in config.ru is the first to run:

```ruby
require_relative "config/environment"
```

### 1.10. config/environment.rb

This file is the common file required by config.ru (bin/rails server) and Passenger. This is where these two ways to run the server meet; everything before this point has been Rack and Rails setup.

This file begins with requiring config/application.rb:

```ruby
require_relative "application"
```

### 1.11. config/application.rb

This file requires config/boot.rb:

```ruby
require_relative "boot"
```

But only if it hasn't been required before, which would be the case in bin/rails server
but wouldn't be the case with Passenger.

Then the fun begins!

## 2. Loading Rails

The next line in config/application.rb is:

```ruby
require "rails/all"
```

### 2.1. railties/lib/rails/all.rb

This file is responsible for requiring all the individual frameworks of Rails:

```ruby
require "rails"

%w(
  active_record/railtie
  active_storage/engine
  action_controller/railtie
  action_view/railtie
  action_mailer/railtie
  active_job/railtie
  action_cable/engine
  action_mailbox/engine
  action_text/engine
  rails/test_unit/railtie
).each do |railtie|
  begin
    require railtie
  rescue LoadError
  end
end
```

This is where all the Rails frameworks are loaded and thus made
available to the application. We won't go into detail of what happens
inside each of those frameworks, but you're encouraged to try and
explore them on your own.

For now, just keep in mind that common functionality like Rails engines,
I18n and Rails configuration are all being defined here.

### 2.2. Back to config/environment.rb

The rest of config/application.rb defines the configuration for the
Rails::Application which will be used once the application is fully
initialized. When config/application.rb has finished loading Rails and defined
the application namespace, we go back to config/environment.rb. Here, the
application is initialized with Rails.application.initialize!, which is
defined in rails/application.rb.

### 2.3. railties/lib/rails/application.rb

The initialize! method looks like this:

```ruby
def initialize!(group = :default) # :nodoc:
  raise "Application has been already initialized." if @initialized
  run_initializers(group, self)
  @initialized = true
  self
end
```

You can only initialize an app once. The Railtie initializers
are run through the run_initializers method which is defined in
railties/lib/rails/initializable.rb:

```ruby
def run_initializers(group = :default, *args)
  return if instance_variable_defined?(:@ran)
  initializers.tsort_each do |initializer|
    initializer.run(*args) if initializer.belongs_to?(group)
  end
  @ran = true
end
```

The run_initializers code itself is tricky. What Rails is doing here is
traversing all the class ancestors looking for those that respond to an
initializers method. It then sorts the ancestors by name, and runs them.
For example, the Engine class will make all the engines available by
providing an initializers method on them.

The Rails::Application class, as defined in railties/lib/rails/application.rb
defines bootstrap, railtie, and finisher initializers. The bootstrap initializers
prepare the application (like initializing the logger) while the finisher
initializers (like building the middleware stack) are run last. The railtie
initializers are the initializers which have been defined on the Rails::Application
itself and are run between the bootstrap and finisher.

Do not confuse Railtie initializers overall with the load_config_initializers
initializer instance or its associated config initializers in config/initializers.

After this is done we go back to Rackup::Server.

### 2.4. Rack: lib/rack/server.rb

Last time we left when the app method was being defined:

```ruby
module Rackup
  class Server
    def app
      @app ||= options[:builder] ? build_app_from_string : build_app_and_options_from_config
    end

    # ...

    private
      def build_app_and_options_from_config
        if !::File.exist? options[:config]
          abort "configuration #{options[:config]} not found"
        end

        Rack::Builder.parse_file(self.options[:config])
      end

      def build_app_from_string
        Rack::Builder.new_from_string(self.options[:builder])
      end
  end
end
```

At this point app is the Rails app itself (a middleware), and what
happens next is Rack will call all the provided middlewares:

```ruby
module Rackup
  class Server
    private
      def build_app(app)
        middleware[options[:environment]].reverse_each do |middleware|
          middleware = middleware.call(self) if middleware.respond_to?(:call)
          next unless middleware
          klass, *args = middleware
          app = klass.new(app, *args)
        end
        app
      end
  end
end
```

Remember, build_app was called (by wrapped_app) in the last line of Rackup::Server#start.
Here's how it looked like when we left:

```ruby
server.run(wrapped_app, **options, &block)
```

At this point, the implementation of server.run will depend on the
server you're using. For example, if you were using Puma, here's what
the run method would look like:

```ruby
module Rack
  module Handler
    module Puma
      # ...
      def self.run(app, options = {})
        conf = self.config(app, options)

        log_writer = options.delete(:Silent) ? ::Puma::LogWriter.strings : ::Puma::LogWriter.stdio

        launcher = ::Puma::Launcher.new(conf, log_writer: log_writer, events: @events)

        yield launcher if block_given?
        begin
          launcher.run
        rescue Interrupt
          puts "* Gracefully stopping, waiting for requests to finish"
          launcher.stop
          puts "* Goodbye!"
        end
      end
      # ...
    end
  end
end
```

We won't dig into the server configuration itself, but this is
the last piece of our journey in the Rails initialization process.

This high level overview will help you understand when your code is
executed and how, and overall become a better Rails developer. If you
still want to know more, the Rails source code itself is probably the
best place to go next.

---

# Chapters

This guide documents how autoloading and reloading works in zeitwerk mode.

After reading this guide, you will know:

- Related Rails configuration

- Project structure

- Autoloading, reloading, and eager loading

- Single Table Inheritance

- And more

## 1. Introduction

This guide documents autoloading, reloading, and eager loading in Rails applications.

In an ordinary Ruby program, you explicitly load the files that define classes and modules you want to use. For example, the following controller refers to ApplicationController and Post, and you'd normally issue require calls for them:

```ruby
# DO NOT DO THIS.
require "application_controller"
require "post"
# DO NOT DO THIS.

class PostsController < ApplicationController
  def index
    @posts = Post.all
  end
end
```

This is not the case in Rails applications, where application classes and modules are just available everywhere without require calls:

```ruby
class PostsController < ApplicationController
  def index
    @posts = Post.all
  end
end
```

Rails autoloads them on your behalf if needed. This is possible thanks to a couple of Zeitwerk loaders Rails sets up on your behalf, which provide autoloading, reloading, and eager loading.

On the other hand, those loaders do not manage anything else. In particular, they do not manage the Ruby standard library, gem dependencies, Rails components themselves, or even (by default) the application lib directory. That code has to be loaded as usual.

## 2. Project Structure

In a Rails application file names have to match the constants they define, with directories acting as namespaces.

For example, the file app/helpers/users_helper.rb should define UsersHelper and the file app/controllers/admin/payments_controller.rb should define Admin::PaymentsController.

By default, Rails configures Zeitwerk to inflect file names with String#camelize. For example, it expects that app/controllers/users_controller.rb defines the constant UsersController because that is what "users_controller".camelize returns.

The section Customizing Inflections below documents ways to override this default.

Please, check the Zeitwerk documentation for further details.

## 3. config.autoload_paths

We refer to the list of application directories whose contents are to be autoloaded and (optionally) reloaded as autoload paths. For example, app/models. Such directories represent the root namespace: Object.

Autoload paths are called root directories in Zeitwerk documentation, but we'll stay with "autoload path" in this guide.

Within an autoload path, file names must match the constants they define as documented here.

By default, the autoload paths of an application consist of all the subdirectories of app that exist when the application boots ---except for assets, javascript, and views--- plus the autoload paths of engines it might depend on.

For example, if UsersHelper is implemented in app/helpers/users_helper.rb, the module is autoloadable, you do not need (and should not write) a require call for it:

```bash
$ bin/rails runner 'p UsersHelper'
UsersHelper
```

Rails adds custom directories under app to the autoload paths automatically. For example, if your application has app/presenters, you don't need to configure anything in order to autoload presenters; it works out of the box.

The array of default autoload paths can be extended by pushing to config.autoload_paths, in config/application.rb or config/environments/*.rb. For example:

```ruby
module MyApplication
  class Application < Rails::Application
    config.autoload_paths << "#{root}/extras"
  end
end
```

Also, engines can push in body of the engine class and in their own config/environments/*.rb.

Please do not mutate ActiveSupport::Dependencies.autoload_paths; the public interface to change autoload paths is config.autoload_paths.

You cannot autoload code in the autoload paths while the application boots. In particular, directly in config/initializers/*.rb. Please check Autoloading when the application boots down below for valid ways to do that.

The autoload paths are managed by the Rails.autoloaders.main autoloader.

## 4. config.autoload_lib(ignore:)

By default, the lib directory does not belong to the autoload paths of applications or engines.

The configuration method config.autoload_lib adds the lib directory to config.autoload_paths and config.eager_load_paths. It has to be invoked from config/application.rb or config/environments/*.rb, and it is not available for engines.

Normally, lib has subdirectories that should not be managed by the autoloaders. Please, pass their name relative to lib in the required ignore keyword argument. For example:

```ruby
config.autoload_lib(ignore: %w(assets tasks))
```

Why? While assets and tasks share the lib directory with regular Ruby code, their contents are not meant to be reloaded or eager loaded.

The ignore list should have all lib subdirectories that do not contain files with .rb extension, or that should not be reloaded or eager loaded. For example,

```ruby
config.autoload_lib(ignore: %w(assets tasks templates generators middleware))
```

config.autoload_lib is not available before 7.1, but you can still emulate it as long as the application uses Zeitwerk:

```ruby
# config/application.rb
module MyApp
  class Application < Rails::Application
    lib = root.join("lib")

    config.autoload_paths << lib
    config.eager_load_paths << lib

    Rails.autoloaders.main.ignore(
      lib.join("assets"),
      lib.join("tasks"),
      lib.join("generators")
    )

    # ...
  end
end
```

## 5. config.autoload_once_paths

You may want to be able to autoload classes and modules without reloading them. The autoload_once_paths configuration stores code that can be autoloaded, but won't be reloaded.

By default, this collection is empty, but you can extend it pushing to config.autoload_once_paths. You can do so in config/application.rb or config/environments/*.rb. For example:

```ruby
module MyApplication
  class Application < Rails::Application
    config.autoload_once_paths << "#{root}/app/serializers"
  end
end
```

Also, engines can push in body of the engine class and in their own config/environments/*.rb.

If app/serializers is pushed to config.autoload_once_paths, Rails no longer considers this an autoload path, despite being a custom directory under app. This setting overrides that rule.

This is key for classes and modules that are cached in places that survive reloads, like the Rails framework itself.

For example, Active Job serializers are stored inside Active Job:

```ruby
# config/initializers/custom_serializers.rb
Rails.application.config.active_job.custom_serializers << MoneySerializer
```

and Active Job itself is not reloaded when there's a reload, only application and engines code in the autoload paths is.

Making MoneySerializer reloadable would be confusing, because reloading an edited version would have no effect on that class object stored in Active Job. Indeed, if MoneySerializer was reloadable, starting with Rails 7 such initializer would raise a NameError.

Another use case is when engines decorate framework classes:

```ruby
initializer "decorate ActionController::Base" do
  ActiveSupport.on_load(:action_controller_base) do
    include MyDecoration
  end
end
```

There, the module object stored in MyDecoration by the time the initializer runs becomes an ancestor of ActionController::Base, and reloading MyDecoration is pointless, it won't affect that ancestor chain.

Classes and modules from the autoload once paths can be autoloaded in config/initializers. So, with that configuration this works:

```ruby
# config/initializers/custom_serializers.rb
Rails.application.config.active_job.custom_serializers << MoneySerializer
```

Technically, you can autoload classes and modules managed by the once autoloader in any initializer that runs after :bootstrap_hook.

The autoload once paths are managed by Rails.autoloaders.once.

## 6. config.autoload_lib_once(ignore:)

The method config.autoload_lib_once is similar to config.autoload_lib, except that it adds lib to config.autoload_once_paths instead. It has to be invoked from config/application.rb or config/environments/*.rb, and it is not available for engines.

By calling config.autoload_lib_once, classes and modules in lib can be autoloaded, even from application initializers, but won't be reloaded.

config.autoload_lib_once is not available before 7.1, but you can still emulate it as long as the application uses Zeitwerk:

```ruby
# config/application.rb
module MyApp
  class Application < Rails::Application
    lib = root.join("lib")

    config.autoload_once_paths << lib
    config.eager_load_paths << lib

    Rails.autoloaders.once.ignore(
      lib.join("assets"),
      lib.join("tasks"),
      lib.join("generators")
    )

    # ...
  end
end
```

## 7. Reloading

Rails automatically reloads classes and modules if application files in the autoload paths change.

More precisely, if the web server is running and application files have been modified, Rails unloads all autoloaded constants managed by the main autoloader just before the next request is processed. That way, application classes or modules used during that request will be autoloaded again, thus picking up their current implementation in the file system.

Reloading can be enabled or disabled. The setting that controls this behavior is config.enable_reloading, which is true by default in development mode, and false by default in production mode. For backwards compatibility, Rails also supports config.cache_classes, which is equivalent to !config.enable_reloading.

Rails uses an evented file monitor to detect files changes by default.  It can be configured instead to detect file changes by walking the autoload paths. This is controlled by the config.file_watcher setting.

In a Rails console there is no file watcher active regardless of the value of config.enable_reloading. This is because, normally, it would be confusing to have code reloaded in the middle of a console session. Similar to an individual request, you generally want a console session to be served by a consistent, non-changing set of application classes and modules.

However, you can force a reload in the console by executing reload!:

```
irb(main):001:0> User.object_id
=> 70136277390120
irb(main):002:0> reload!
Reloading...
=> true
irb(main):003:0> User.object_id
=> 70136284426020
```

As you can see, the class object stored in the User constant is different after reloading.

### 7.1. Reloading and Stale Objects

It is very important to understand that Ruby does not have a way to truly reload classes and modules in memory, and have that reflected everywhere they are already used. Technically, "unloading" the User class means removing the User constant via Object.send(:remove_const, "User").

For example, check out this Rails console session:

```
irb> joe = User.new
irb> reload!
irb> alice = User.new
irb> joe.class == alice.class
=> false
```

joe is an instance of the original User class. When there is a reload, the User constant then evaluates to a different, reloaded class. alice is an instance of the newly loaded User, but joe is not — his class is stale. You may define joe again, start an IRB subsession, or just launch a new console instead of calling reload!.

Another situation in which you may find this gotcha is subclassing reloadable classes in a place that is not reloaded:

```ruby
# lib/vip_user.rb
class VipUser < User
end
```

if User is reloaded, since VipUser is not, the superclass of VipUser is the original stale class object.

Bottom line: do not cache reloadable classes or modules.

## 8. Autoloading When the Application Boots

While booting, applications can autoload from the autoload once paths, which are managed by the once autoloader. Please check the section config.autoload_once_paths above.

However, you cannot autoload from the autoload paths, which are managed by the main autoloader. This applies to code in config/initializers as well as application or engines initializers.

Why? Initializers only run once, when the application boots. They do not run again on reloads. If an initializer used a reloadable class or module, edits to them would not be reflected in that initial code, thus becoming stale. Therefore, referring to reloadable constants during initialization is disallowed.

Let's see what to do instead.

### 8.1. Use Case 1: During Boot, Load Reloadable Code

#### 8.1.1. Autoload on Boot and on Each Reload

Let's imagine ApiGateway is a reloadable class and you need to configure its endpoint while the application boots:

```ruby
# config/initializers/api_gateway_setup.rb
ApiGateway.endpoint = "https://example.com" # NameError
```

Initializers cannot refer to reloadable constants, you need to wrap that in a to_prepare block, which runs on boot, and after each reload:

```ruby
# config/initializers/api_gateway_setup.rb
Rails.application.config.to_prepare do
  ApiGateway.endpoint = "https://example.com" # CORRECT
end
```

For historical reasons, this callback may run twice. The code it executes must be idempotent.

#### 8.1.2. Autoload on Boot Only

Reloadable classes and modules can be autoloaded in after_initialize blocks too. These run on boot, but do not run again on reload. In some exceptional cases this may be what you want.

Preflight checks are a use case for this:

```ruby
# config/initializers/check_admin_presence.rb
Rails.application.config.after_initialize do
  unless Role.where(name: "admin").exists?
    abort "The admin role is not present, please seed the database."
  end
end
```

### 8.2. Use Case 2: During Boot, Load Code that Remains Cached

Some configurations take a class or module object, and they store it in a place that is not reloaded. It is important that these are not reloadable, because edits would not be reflected in those cached stale objects.

One example is middleware:

```ruby
config.middleware.use MyApp::Middleware::Foo
```

When you reload, the middleware stack is not affected, so it would be confusing that MyApp::Middleware::Foo is reloadable. Changes in its implementation would have no effect.

Another example is Active Job serializers:

```ruby
# config/initializers/custom_serializers.rb
Rails.application.config.active_job.custom_serializers << MoneySerializer
```

Whatever MoneySerializer evaluates to during initialization gets pushed to the custom serializers, and that object stays there on reloads.

Yet another example are railties or engines decorating framework classes by including modules. For instance, turbo-rails decorates ActiveRecord::Base this way:

```ruby
initializer "turbo.broadcastable" do
  ActiveSupport.on_load(:active_record) do
    include Turbo::Broadcastable
  end
end
```

That adds a module object to the ancestor chain of ActiveRecord::Base. Changes in Turbo::Broadcastable would have no effect if reloaded, the ancestor chain would still have the original one.

Corollary: Those classes or modules cannot be reloadable.

An idiomatic way to organize these files is to put them in the lib directory and load them with require where needed. For example, if the application has custom middleware in lib/middleware, issue a regular require call before configuring it:

```ruby
require "middleware/my_middleware"
config.middleware.use MyMiddleware
```

Additionally, if lib is in the autoload paths, configure the autoloader to ignore that subdirectory:

```ruby
# config/application.rb
config.autoload_lib(ignore: %w(assets tasks ... middleware))
```

since you are loading those files yourself.

As noted above, another option is to have the directory that defines them in the autoload once paths and autoload. Please check the section about config.autoload_once_paths for details.

### 8.3. Use Case 3: Configure Application Classes for Engines

Let's suppose an engine works with the reloadable application class that models users, and has a configuration point for it:

```ruby
# config/initializers/my_engine.rb
MyEngine.configure do |config|
  config.user_model = User # NameError
end
```

In order to play well with reloadable application code, the engine instead needs applications to configure the name of that class:

```ruby
# config/initializers/my_engine.rb
MyEngine.configure do |config|
  config.user_model = "User" # OK
end
```

Then, at run time, config.user_model.constantize gives you the current class object.

## 9. Eager Loading

In production-like environments it is generally better to load all the application code when the application boots. Eager loading puts everything in memory ready to serve requests right away, and it is also CoW-friendly.

Eager loading is controlled by the flag config.eager_load, which is disabled by default in all environments except production. When a Rake task gets executed, config.eager_load is overridden by config.rake_eager_load, which is false by default. So, by default, in production environments Rake tasks do not eager load the application.

The order in which files are eager-loaded is undefined.

During eager loading, Rails invokes Zeitwerk::Loader.eager_load_all. That ensures all gem dependencies managed by Zeitwerk are eager-loaded too.

## 10. Single Table Inheritance

Single Table Inheritance doesn't play well with lazy loading: Active Record has to be aware of STI hierarchies to work correctly, but when lazy loading, classes are precisely loaded only on demand!

To address this fundamental mismatch we need to preload STIs. There are a few options to accomplish this, with different trade-offs. Let's see them.

### 10.1. Option 1: Enable Eager Loading

The easiest way to preload STIs is to enable eager loading by setting:

```ruby
config.eager_load = true
```

in config/environments/development.rb and config/environments/test.rb.

This is simple, but may be costly because it eager loads the entire application on boot and on every reload. The trade-off may be worthwhile for small applications, though.

### 10.2. Option 2: Preload a Collapsed Directory

Store the files that define the hierarchy in a dedicated directory, which makes sense also conceptually. The directory is not meant to represent a namespace, its sole purpose is to group the STI:

```
app/models/shapes/shape.rb
app/models/shapes/circle.rb
app/models/shapes/square.rb
app/models/shapes/triangle.rb
```

In this example, we still want app/models/shapes/circle.rb to define Circle, not Shapes::Circle. This may be your personal preference to keep things simple, and also avoids refactors in existing code bases. The collapsing feature of Zeitwerk allows us to do that:

```ruby
# config/initializers/preload_stis.rb

shapes = "#{Rails.root}/app/models/shapes"
Rails.autoloaders.main.collapse(shapes) # Not a namespace.

unless Rails.application.config.eager_load
  Rails.application.config.to_prepare do
    Rails.autoloaders.main.eager_load_dir(shapes)
  end
end
```

In this option, we eager load these few files on boot and reload even if the STI is not used. However, unless your application has a lot of STIs, this won't have any measurable impact.

The method Zeitwerk::Loader#eager_load_dir was added in Zeitwerk 2.6.2. For older versions, you can still list the app/models/shapes directory and invoke require_dependency on its contents.

If models are added, modified, or deleted from the STI, reloading works as expected. However, if a new separate STI hierarchy is added to the application, you'll need to edit the initializer and restart the server.

### 10.3. Option 3: Preload a Regular Directory

Similar to the previous one, but the directory is meant to be a namespace. That is, app/models/shapes/circle.rb is expected to define Shapes::Circle.

For this one, the initializer is the same except no collapsing is configured:

```ruby
# config/initializers/preload_stis.rb

unless Rails.application.config.eager_load
  Rails.application.config.to_prepare do
    Rails.autoloaders.main.eager_load_dir("#{Rails.root}/app/models/shapes")
  end
end
```

Same trade-offs.

### 10.4. Option 4: Preload Types from the Database

In this option we do not need to organize the files in any way, but we hit the database:

```ruby
# config/initializers/preload_stis.rb

unless Rails.application.config.eager_load
  Rails.application.config.to_prepare do
    types = Shape.unscoped.select(:type).distinct.pluck(:type)
    types.compact.each(&:constantize)
  end
end
```

The STI will work correctly even if the table does not have all the types, but methods like subclasses or descendants won't return the missing types.

If models are added, modified, or deleted from the STI, reloading works as expected. However, if a new separate STI hierarchy is added to the application, you'll need to edit the initializer and restart the server.

## 11. Customizing Inflections

By default, Rails uses String#camelize to know which constant a given file or directory name should define. For example, posts_controller.rb should define PostsController because that is what "posts_controller".camelize returns.

It could be the case that some particular file or directory name does not get inflected as you want. For instance, html_parser.rb is expected to define HtmlParser by default. What if you prefer the class to be HTMLParser? There are a few ways to customize this.

The easiest way is to define acronyms:

```ruby
ActiveSupport::Inflector.inflections(:en) do |inflect|
  inflect.acronym "HTML"
  inflect.acronym "SSL"
end
```

Doing so affects how Active Support inflects globally. That may be fine in some applications, but you can also customize how to camelize individual basenames independently from Active Support by passing a collection of overrides to the default inflectors:

```ruby
Rails.autoloaders.each do |autoloader|
  autoloader.inflector.inflect(
    "html_parser" => "HTMLParser",
    "ssl_error"   => "SSLError"
  )
end
```

That technique still depends on String#camelize, though, because that is what the default inflectors use as fallback. If you instead prefer not to depend on Active Support inflections at all and have absolute control over inflections, configure the inflectors to be instances of Zeitwerk::Inflector:

```ruby
Rails.autoloaders.each do |autoloader|
  autoloader.inflector = Zeitwerk::Inflector.new
  autoloader.inflector.inflect(
    "html_parser" => "HTMLParser",
    "ssl_error"   => "SSLError"
  )
end
```

There is no global configuration that can affect said instances; they are deterministic.

You can even define a custom inflector for full flexibility. Please check the Zeitwerk documentation for further details.

### 11.1. Where Should Inflection Customization Go?

If an application does not use the once autoloader, the snippets above can go in config/initializers. For example, config/initializers/inflections.rb for the Active Support use case, or config/initializers/zeitwerk.rb for the other ones.

Applications using the once autoloader have to move or load this configuration from the body of the application class in config/application.rb, because the once autoloader uses the inflector early in the boot process.

## 12. Custom Namespaces

As we saw above, autoload paths represent the top-level namespace: Object.

Let's consider app/services, for example. This directory is not generated by default, but if it exists, Rails automatically adds it to the autoload paths.

By default, the file app/services/users/signup.rb is expected to define Users::Signup, but what if you prefer that entire subtree to be under a Services namespace? Well, with default settings, that can be accomplished by creating a subdirectory: app/services/services.

However, depending on your taste, that just might not feel right to you. You might prefer that app/services/users/signup.rb simply defines Services::Users::Signup.

Zeitwerk supports custom root namespaces to address this use case, and you can customize the main autoloader to accomplish that:

```ruby
# config/initializers/autoloading.rb

# The namespace has to exist.
#
# In this example we define the module on the spot. Could also be created
# elsewhere and its definition loaded here with an ordinary `require`. In
# any case, `push_dir` expects a class or module object.
module Services; end

Rails.autoloaders.main.push_dir("#{Rails.root}/app/services", namespace: Services)
```

Rails < 7.1 did not support this feature, but you can still add this additional code in the same file and get it working:

```ruby
# Additional code for applications running on Rails < 7.1.
app_services_dir = "#{Rails.root}/app/services" # has to be a string
ActiveSupport::Dependencies.autoload_paths.delete(app_services_dir)
Rails.application.config.watchable_dirs[app_services_dir] = [:rb]
```

Custom namespaces are also supported for the once autoloader. However, since that one is set up earlier in the boot process, the configuration cannot be done in an application initializer. Instead, please put it in config/application.rb, for example.

## 13. Autoloading and Engines

Engines run in the context of a parent application, and their code is autoloaded, reloaded, and eager loaded by the parent application. If the application runs in zeitwerk mode, the engine code is loaded by zeitwerk mode. If the application runs in classic mode, the engine code is loaded by classic mode.

When Rails boots, engine directories are added to the autoload paths, and from the point of view of the autoloader, there's no difference. Autoloaders' main inputs are the autoload paths, and whether they belong to the application source tree or to some engine source tree is irrelevant.

For example, this application uses Devise:

```bash
$ bin/rails runner 'pp ActiveSupport::Dependencies.autoload_paths'
[".../app/controllers",
 ".../app/controllers/concerns",
 ".../app/helpers",
 ".../app/models",
 ".../app/models/concerns",
 ".../gems/devise-4.8.0/app/controllers",
 ".../gems/devise-4.8.0/app/helpers",
 ".../gems/devise-4.8.0/app/mailers"]
```

If the engine controls the autoloading mode of its parent application, the engine can be written as usual.

However, if an engine supports Rails 6 or Rails 6.1 and does not control its parent applications, it has to be ready to run under either classic or zeitwerk mode. Things to take into account:

- If classic mode would need a require_dependency call to ensure some constant is loaded at some point, write it. While zeitwerk would not need it, it won't hurt, it will work in zeitwerk mode too.

- classic mode underscores constant names ("User" -> "user.rb"), and zeitwerk mode camelizes file names ("user.rb" -> "User"). They coincide in most cases, but they don't if there are series of consecutive uppercase letters as in "HTMLParser". The easiest way to be compatible is to avoid such names. In this case, pick "HtmlParser".

- In classic mode, the file app/model/concerns/foo.rb is allowed to define both Foo and Concerns::Foo. In zeitwerk mode, there's only one option: it has to define Foo. In order to be compatible, define Foo.

If classic mode would need a require_dependency call to ensure some constant is loaded at some point, write it. While zeitwerk would not need it, it won't hurt, it will work in zeitwerk mode too.

classic mode underscores constant names ("User" -> "user.rb"), and zeitwerk mode camelizes file names ("user.rb" -> "User"). They coincide in most cases, but they don't if there are series of consecutive uppercase letters as in "HTMLParser". The easiest way to be compatible is to avoid such names. In this case, pick "HtmlParser".

In classic mode, the file app/model/concerns/foo.rb is allowed to define both Foo and Concerns::Foo. In zeitwerk mode, there's only one option: it has to define Foo. In order to be compatible, define Foo.

## 14. Testing

### 14.1. Manual Testing

The task zeitwerk:check checks if the project tree follows the expected naming conventions and it is handy for manual checks. For example, if you're migrating from classic to zeitwerk mode, or if you're fixing something:

```bash
$ bin/rails zeitwerk:check
Hold on, I am eager loading the application.
All is good!
```

There can be additional output depending on the application configuration, but the last "All is good!" is what you are looking for.

### 14.2. Automated Testing

It is a good practice to verify in the test suite that the project eager loads correctly.

That covers Zeitwerk naming compliance and other possible error conditions. Please check the section about testing eager loading in the Testing Rails Applications guide.

## 15. Troubleshooting

The best way to follow what the loaders are doing is to inspect their activity.

The easiest way to do that is to include

```ruby
Rails.autoloaders.log!
```

in config/application.rb after loading the framework defaults. That will print traces to standard output.

If you prefer logging to a file, configure this instead:

```ruby
Rails.autoloaders.logger = Logger.new("#{Rails.root}/log/autoloading.log")
```

The Rails logger is not yet available when config/application.rb executes. If you prefer to use the Rails logger, configure this setting in an initializer instead:

```ruby
# config/initializers/log_autoloaders.rb
Rails.autoloaders.logger = Rails.logger
```

## 16. Rails.autoloaders

The Zeitwerk instances managing your application are available at

```ruby
Rails.autoloaders.main
Rails.autoloaders.once
```

The predicate

```ruby
Rails.autoloaders.zeitwerk_enabled?
```

is still available in Rails 7 applications, and returns true.

---

# Chapters

After reading this guide, you will know:

- What code Rails will automatically execute concurrently

- How to integrate manual concurrency with Rails internals

- How to wrap all application code

- How to affect application reloading

## 1. Automatic Concurrency

Rails automatically allows various operations to be performed at the same time.

When using a threaded web server, such as the default Puma, multiple HTTP
requests will be served simultaneously, with each request provided its own
controller instance.

Threaded Active Job adapters, including the built-in Async, will likewise
execute several jobs at the same time. Action Cable channels are managed this
way too.

These mechanisms all involve multiple threads, each managing work for a unique
instance of some object (controller, job, channel), while sharing the global
process space (such as classes and their configurations, and global variables).
As long as your code doesn't modify any of those shared things, it can mostly
ignore that other threads exist.

The rest of this guide describes the mechanisms Rails uses to make it "mostly
ignorable", and how extensions and applications with special needs can use them.

## 2. Executor

The Rails Executor separates application code from framework code: any time the
framework invokes code you've written in your application, it will be wrapped by
the Executor.

The Executor consists of two callbacks: to_run and to_complete. The Run
callback is called before the application code, and the Complete callback is
called after.

### 2.1. Default Callbacks

In a default Rails application, the Executor callbacks are used to:

- track which threads are in safe positions for autoloading and reloading

- enable and disable the Active Record query cache

- return acquired Active Record connections to the pool

- constrain internal cache lifetimes

Prior to Rails 5.0, some of these were handled by separate Rack middleware
classes (such as ActiveRecord::ConnectionAdapters::ConnectionManagement), or
directly wrapping code with methods like
ActiveRecord::Base.connection_pool.with_connection. The Executor replaces
these with a single more abstract interface.

### 2.2. Wrapping Application Code

If you're writing a library or component that will invoke application code, you
should wrap it with a call to the executor:

```ruby
Rails.application.executor.wrap do
  # call application code here
end
```

If you repeatedly invoke application code from a long-running process, you
may want to wrap using the Reloader instead.

Each thread should be wrapped before it runs application code, so if your
application manually delegates work to other threads, such as via Thread.new
or Concurrent Ruby features that use thread pools, you should immediately wrap
the block:

```ruby
Thread.new do
  Rails.application.executor.wrap do
    # your code here
  end
end
```

Concurrent Ruby uses a ThreadPoolExecutor, which it sometimes configures
with an executor option. Despite the name, it is unrelated.

The Executor is safely re-entrant; if it is already active on the current
thread, wrap is a no-op.

If it's impractical to wrap the application code in a block (for
example, the Rack API makes this problematic), you can also use the run! /
complete! pair:

```ruby
Thread.new do
  execution_context = Rails.application.executor.run!
  # your code here
ensure
  execution_context.complete! if execution_context
end
```

### 2.3. Concurrency

The Executor will put the current thread into running mode in the Reloading
Interlock. This operation will block temporarily if another
thread is currently unloading/reloading the application.

## 3. Reloader

Like the Executor, the Reloader also wraps application code. If the Executor is
not already active on the current thread, the Reloader will invoke it for you,
so you only need to call one. This also guarantees that everything the Reloader
does, including all its callback invocations, occurs wrapped inside the
Executor.

```ruby
Rails.application.reloader.wrap do
  # call application code here
end
```

The Reloader is only suitable where a long-running framework-level process
repeatedly calls into application code, such as for a web server or job queue.
Rails automatically wraps web requests and Active Job workers, so you'll rarely
need to invoke the Reloader for yourself. Always consider whether the Executor
is a better fit for your use case.

### 3.1. Callbacks

Before entering the wrapped block, the Reloader will check whether the running
application needs to be reloaded -- for example, because a model's source file has
been modified. If it determines a reload is required, it will wait until it's
safe, and then do so, before continuing. When the application is configured to
always reload regardless of whether any changes are detected, the reload is
instead performed at the end of the block.

The Reloader also provides to_run and to_complete callbacks; they are
invoked at the same points as those of the Executor, but only when the current
execution has initiated an application reload. When no reload is deemed
necessary, the Reloader will invoke the wrapped block with no other callbacks.

### 3.2. Class Unload

The most significant part of the reloading process is the Class Unload, where
all autoloaded classes are removed, ready to be loaded again. This will occur
immediately before either the Run or Complete callback, depending on the
reload_classes_only_on_change setting.

Often, additional reloading actions need to be performed either just before or
just after the Class Unload, so the Reloader also provides before_class_unload
and after_class_unload callbacks.

### 3.3. Concurrency

Only long-running "top level" processes should invoke the Reloader, because if
it determines a reload is needed, it will block until all other threads have
completed any Executor invocations.

If this were to occur in a "child" thread, with a waiting parent inside the
Executor, it would cause an unavoidable deadlock: the reload must occur before
the child thread is executed, but it cannot be safely performed while the parent
thread is mid-execution. Child threads should use the Executor instead.

## 4. Framework Behavior

The Rails framework components use these tools to manage their own concurrency
needs too.

ActionDispatch::Executor and ActionDispatch::Reloader are Rack middlewares
that wrap requests with a supplied Executor or Reloader, respectively. They
are automatically included in the default application stack. The Reloader will
ensure any arriving HTTP request is served with a freshly-loaded copy of the
application if any code changes have occurred.

Active Job also wraps its job executions with the Reloader, loading the latest
code to execute each job as it comes off the queue.

Action Cable uses the Executor instead: because a Cable connection is linked to
a specific instance of a class, it's not possible to reload for every arriving
WebSocket message. Only the message handler is wrapped, though; a long-running
Cable connection does not prevent a reload that's triggered by a new incoming
request or job. Instead, Action Cable uses the Reloader's before_class_unload
callback to disconnect all its connections. When the client automatically
reconnects, it will be speaking to the new version of the code.

The above are the entry points to the framework, so they are responsible for
ensuring their respective threads are protected, and deciding whether a reload
is necessary. Other components only need to use the Executor when they spawn
additional threads.

### 4.1. Configuration

The Reloader only checks for file changes when config.enable_reloading is
true and so is config.reload_classes_only_on_change. These are the defaults in the
development environment.

When config.enable_reloading is false (in production, by default), the
Reloader is only a pass-through to the Executor.

The Executor always has important work to do, like database connection
management. When config.enable_reloading is false and config.eager_load is
true (production defaults), no reloading will occur, so it does not need the
Reloading Interlock. With the default settings in the development environment, the
Executor will use the Reloading Interlock to ensure code reloading is performed safely.

## 5. Reloading Interlock

The Reloading Interlock ensures that code reloading can be performed safely in a
multi-threaded runtime environment.

It is only safe to perform an unload/reload when no application code is in
mid-execution: after the reload, the User constant, for example, may point to
a different class. Without this rule, a poorly-timed reload would mean
User.new.class == User, or even User == User, could be false.

The Reloading Interlock addresses this constraint by keeping track of which
threads are currently running application code, and ensuring that reloading
waits until no other threads are executing application code.

---

# Chapters

This guide covers Rails integration with Rack and interfacing with other Rack components.

After reading this guide, you will know:

- How to use Rack Middlewares in your Rails applications.

- Action Pack's internal Middleware stack.

- How to define a custom Middleware stack.

This guide assumes a working knowledge of Rack protocol and Rack concepts such as middlewares, URL maps, and Rack::Builder.

## 1. Introduction to Rack

Rack provides a minimal, modular, and adaptable interface for developing web applications in Ruby. By wrapping HTTP requests and responses in the simplest way possible, it unifies and distills the API for web servers, web frameworks, and software in between (the so-called middleware) into a single method call.

Explaining how Rack works is not really in the scope of this guide. In case you
are not familiar with Rack's basics, you should check out the Resources
section below.

## 2. Rails on Rack

### 2.1. Rails Application's Rack Object

Rails.application is the primary Rack application object of a Rails
application. Any Rack compliant web server should be using
Rails.application object to serve a Rails application.

### 2.2. bin/rails server

bin/rails server does the basic job of creating a Rack::Server object and starting the web server.

Here's how bin/rails server creates an instance of Rack::Server

```ruby
Rails::Server.new.tap do |server|
  require APP_PATH
  Dir.chdir(Rails.application.root)
  server.start
end
```

The Rails::Server inherits from Rack::Server and calls the Rack::Server#start method this way:

```ruby
class Server < ::Rack::Server
  def start
    # ...
    super
  end
end
```

### 2.3. Development and Auto-reloading

Middlewares are loaded once and are not monitored for changes. You will have to restart the server for changes to be reflected in the running application.

## 3. Action Dispatcher Middleware Stack

Many of Action Dispatcher's internal components are implemented as Rack middlewares. Rails::Application uses ActionDispatch::MiddlewareStack to combine various internal and external middlewares to form a complete Rails Rack application.

ActionDispatch::MiddlewareStack is Rails' equivalent of Rack::Builder,
but is built for better flexibility and more features to meet Rails' requirements.

### 3.1. Inspecting Middleware Stack

Rails has a handy command for inspecting the middleware stack in use:

```bash
$ bin/rails middleware
```

For a freshly generated Rails application, this might produce something like:

```ruby
use ActionDispatch::HostAuthorization
use Rack::Sendfile
use ActionDispatch::Static
use ActionDispatch::Executor
use ActionDispatch::ServerTiming
use ActiveSupport::Cache::Strategy::LocalCache::Middleware
use Rack::Runtime
use Rack::MethodOverride
use ActionDispatch::RequestId
use ActionDispatch::RemoteIp
use Sprockets::Rails::QuietAssets
use Rails::Rack::Logger
use ActionDispatch::ShowExceptions
use WebConsole::Middleware
use ActionDispatch::DebugExceptions
use ActionDispatch::ActionableExceptions
use ActionDispatch::Reloader
use ActionDispatch::Callbacks
use ActiveRecord::Migration::CheckPending
use ActionDispatch::Cookies
use ActionDispatch::Session::CookieStore
use ActionDispatch::Flash
use ActionDispatch::ContentSecurityPolicy::Middleware
use Rack::Head
use Rack::ConditionalGet
use Rack::ETag
use Rack::TempfileReaper
run MyApp::Application.routes
```

The default middlewares shown here (and some others) are each summarized in the Internal Middlewares section, below.

### 3.2. Configuring Middleware Stack

Rails provides a simple configuration interface config.middleware for adding, removing, and modifying the middlewares in the middleware stack via application.rb or the environment specific configuration file environments/<environment>.rb.

#### 3.2.1. Adding a Middleware

You can add a new middleware to the middleware stack using any of the following methods:

- config.middleware.use(new_middleware, args) - Adds the new middleware at the bottom of the middleware stack.

- config.middleware.insert_before(existing_middleware, new_middleware, args) - Adds the new middleware before the specified existing middleware in the middleware stack.

- config.middleware.insert_after(existing_middleware, new_middleware, args) - Adds the new middleware after the specified existing middleware in the middleware stack.

config.middleware.use(new_middleware, args) - Adds the new middleware at the bottom of the middleware stack.

config.middleware.insert_before(existing_middleware, new_middleware, args) - Adds the new middleware before the specified existing middleware in the middleware stack.

config.middleware.insert_after(existing_middleware, new_middleware, args) - Adds the new middleware after the specified existing middleware in the middleware stack.

```ruby
# config/application.rb

# Push Rack::BounceFavicon at the bottom
config.middleware.use Rack::BounceFavicon

# Add Lifo::Cache after ActionDispatch::Executor.
# Pass { page_cache: false } argument to Lifo::Cache.
config.middleware.insert_after ActionDispatch::Executor, Lifo::Cache, page_cache: false
```

#### 3.2.2. Swapping a Middleware

You can swap an existing middleware in the middleware stack using config.middleware.swap.

```ruby
# config/application.rb

# Replace ActionDispatch::ShowExceptions with Lifo::ShowExceptions
config.middleware.swap ActionDispatch::ShowExceptions, Lifo::ShowExceptions
```

#### 3.2.3. Moving a Middleware

You can move an existing middleware in the middleware stack using config.middleware.move_before and config.middleware.move_after.

```ruby
# config/application.rb

# Move ActionDispatch::ShowExceptions to before Lifo::ShowExceptions
config.middleware.move_before Lifo::ShowExceptions, ActionDispatch::ShowExceptions
```

```ruby
# config/application.rb

# Move ActionDispatch::ShowExceptions to after Lifo::ShowExceptions
config.middleware.move_after Lifo::ShowExceptions, ActionDispatch::ShowExceptions
```

#### 3.2.4. Deleting a Middleware

Add the following lines to your application configuration:

```ruby
# config/application.rb
config.middleware.delete Rack::Runtime
```

And now if you inspect the middleware stack, you'll find that Rack::Runtime is
not a part of it.

```bash
$ bin/rails middleware
(in /Users/lifo/Rails/blog)
use ActionDispatch::Static
use #<ActiveSupport::Cache::Strategy::LocalCache::Middleware:0x00000001c304c8>
...
run Rails.application.routes
```

If you want to remove session related middleware, do the following:

```ruby
# config/application.rb
config.middleware.delete ActionDispatch::Cookies
config.middleware.delete ActionDispatch::Session::CookieStore
config.middleware.delete ActionDispatch::Flash
```

And to remove browser related middleware,

```ruby
# config/application.rb
config.middleware.delete Rack::MethodOverride
```

If you want an error to be raised when you try to delete a non-existent item, use delete! instead.

```ruby
# config/application.rb
config.middleware.delete! ActionDispatch::Executor
```

### 3.3. Internal Middleware Stack

Much of Action Controller's functionality is implemented as Middlewares. The following list explains the purpose of each of them:

ActionDispatch::HostAuthorization

- Guards from DNS rebinding attacks by explicitly permitting the hosts a request can be sent to. See the configuration guide for configuration instructions.

Rack::Sendfile

- Sets server specific X-Sendfile header. Configure this via config.action_dispatch.x_sendfile_header option.

ActionDispatch::Static

- Used to serve static files from the public directory. Disabled if config.public_file_server.enabled is false.

Rack::Lock

- Sets env["rack.multithread"] flag to false and wraps the application within a Mutex.

ActionDispatch::Executor

- Used for thread safe code reloading during development.

ActionDispatch::ServerTiming

- Sets a Server-Timing header containing performance metrics for the request.

ActiveSupport::Cache::Strategy::LocalCache::Middleware

- Used for memory caching. This cache is not thread safe.

Rack::Runtime

- Sets an X-Runtime header, containing the time (in seconds) taken to execute the request.

Rack::MethodOverride

- Allows the method to be overridden if params[:_method] is set. This is the middleware which supports the PUT and DELETE HTTP method types.

ActionDispatch::RequestId

- Makes a unique X-Request-Id header available to the response and enables the ActionDispatch::Request#request_id method.

ActionDispatch::RemoteIp

- Checks for IP spoofing attacks.

Sprockets::Rails::QuietAssets

- Suppresses logger output for asset requests.

Rails::Rack::Logger

- Notifies the logs that the request has begun. After the request is complete, flushes all the logs.

ActionDispatch::ShowExceptions

- Rescues any exception returned by the application and calls an exceptions app that will wrap it in a format for the end user.

ActionDispatch::DebugExceptions

- Responsible for logging exceptions and showing a debugging page in case the request is local.

ActionDispatch::ActionableExceptions

- Provides a way to dispatch actions from Rails' error pages.

ActionDispatch::Reloader

- Provides prepare and cleanup callbacks, intended to assist with code reloading during development.

ActionDispatch::Callbacks

- Provides callbacks to be executed before and after dispatching the request.

ActiveRecord::Migration::CheckPending

- Checks pending migrations and raises ActiveRecord::PendingMigrationError if any migrations are pending.

ActionDispatch::Cookies

- Sets cookies for the request.

ActionDispatch::Session::CookieStore

- Responsible for storing the session in cookies.

ActionDispatch::Flash

- Sets up the flash keys. Only available if config.session_store is set to a value.

ActionDispatch::ContentSecurityPolicy::Middleware

- Provides a DSL to configure a Content-Security-Policy header.

Rack::Head

- Returns an empty body for all HEAD requests. It leaves all other requests unchanged.

Rack::ConditionalGet

- Adds support for "Conditional GET" so that server responds with nothing if the page wasn't changed.

Rack::ETag

- Adds ETag header on all String bodies. ETags are used to validate cache.

Rack::TempfileReaper

- Cleans up tempfiles used to buffer multipart requests.

It's possible to use any of the above middlewares in your custom Rack stack.

## 4. Resources

### 4.1. Learning Rack

- Official Rack Website

- Introducing Rack

### 4.2. Understanding Middlewares

- Railscast on Rack Middlewares

---

# Chapters

In this guide you will learn about engines and how they can be used to provide
additional functionality to their host applications through a clean and very
easy-to-use interface.

After reading this guide, you will know:

- What makes an engine.

- How to generate an engine.

- How to build features for the engine.

- How to hook the engine into an application.

- How to override engine functionality in the application.

- How to avoid loading Rails frameworks with Load and Configuration Hooks.

## 1. What are Engines?

Engines can be considered miniature applications that provide functionality to
their host applications. A Rails application is actually just a "supercharged"
engine, with the Rails::Application class inheriting a lot of its behavior
from Rails::Engine.

Therefore, engines and applications can be thought of as almost the same thing,
just with subtle differences, as you'll see throughout this guide. Engines and
applications also share a common structure.

Engines are also closely related to plugins. The two share a common lib
directory structure, and are both generated using the rails plugin new
generator. The difference is that an engine is considered a "full plugin" by
Rails (as indicated by the --full option that's passed to the generator
command). We'll actually be using the --mountable option here, which includes
all the features of --full, and then some. This guide will refer to these
"full plugins" simply as "engines" throughout. An engine can be a plugin,
and a plugin can be an engine.

The engine that will be created in this guide will be called "blorgh". This
engine will provide blogging functionality to its host applications, allowing
for new articles and comments to be created. At the beginning of this guide, you
will be working solely within the engine itself, but in later sections you'll
see how to hook it into an application.

Engines can also be isolated from their host applications. This means that an
application is able to have a path provided by a routing helper such as
articles_path and use an engine that also provides a path also called
articles_path, and the two would not clash. Along with this, controllers, models
and table names are also namespaced. You'll see how to do this later in this
guide.

It's important to keep in mind at all times that the application should
always take precedence over its engines. An application is the object that
has final say in what goes on in its environment. The engine should
only be enhancing it, rather than changing it drastically.

To see demonstrations of other engines, check out
Devise, an engine that provides
authentication for its parent applications, or
Thredded, an engine that provides forum
functionality. There's also Spree which
provides an e-commerce platform, and
Refinery CMS, a CMS engine.

Finally, engines would not have been possible without the work of James Adam,
Piotr Sarnacki, the Rails Core Team, and a number of other people. If you ever
meet them, don't forget to say thanks!

## 2. Generating an Engine

To generate an engine, you will need to run the plugin generator and pass it
options as appropriate to the need. For the "blorgh" example, you will need to
create a "mountable" engine, running this command in a terminal:

```bash
$ rails plugin new blorgh --mountable
```

The full list of options for the plugin generator may be seen by typing:

```bash
$ rails plugin --help
```

The --mountable option tells the generator that you want to create a
"mountable" and namespace-isolated engine. This generator will provide the same
skeleton structure as would the --full option. The --full option tells the
generator that you want to create an engine, including a skeleton structure
that provides the following:

- An app directory tree

- A config/routes.rb file:
Rails.application.routes.draw do
end

- A file at lib/blorgh/engine.rb, which is identical in function to a
standard Rails application's config/application.rb file:
module Blorgh
  class Engine < ::Rails::Engine
  end
end

A config/routes.rb file:

```ruby
Rails.application.routes.draw do
end
```

A file at lib/blorgh/engine.rb, which is identical in function to a
standard Rails application's config/application.rb file:

```ruby
module Blorgh
  class Engine < ::Rails::Engine
  end
end
```

The --mountable option will add to the --full option:

- Asset manifest files (blorgh_manifest.js and application.css)

- A namespaced ApplicationController stub

- A namespaced ApplicationHelper stub

- A layout view template for the engine

- Namespace isolation to config/routes.rb:
Blorgh::Engine.routes.draw do
end

- Namespace isolation to lib/blorgh/engine.rb:
module Blorgh
  class Engine < ::Rails::Engine
    isolate_namespace Blorgh
  end
end

Namespace isolation to config/routes.rb:

```ruby
Blorgh::Engine.routes.draw do
end
```

Namespace isolation to lib/blorgh/engine.rb:

```ruby
module Blorgh
  class Engine < ::Rails::Engine
    isolate_namespace Blorgh
  end
end
```

Additionally, the --mountable option tells the generator to mount the engine
inside the dummy testing application located at test/dummy by adding the
following to the dummy application's routes file at
test/dummy/config/routes.rb:

```ruby
mount Blorgh::Engine => "/blorgh"
```

### 2.1. Inside an Engine

#### 2.1.1. Critical Files

At the root of this brand new engine's directory lives a blorgh.gemspec file.
When you include the engine into an application later on, you will do so with
this line in the Rails application's Gemfile:

```ruby
gem "blorgh", path: "engines/blorgh"
```

Don't forget to run bundle install as usual. By specifying it as a gem within
the Gemfile, Bundler will load it as such, parsing this blorgh.gemspec file
and requiring a file within the lib directory called lib/blorgh.rb. This
file requires the blorgh/engine.rb file (located at lib/blorgh/engine.rb)
and defines a base module called Blorgh.

```ruby
require "blorgh/engine"

module Blorgh
end
```

Some engines choose to use this file to put global configuration options
for their engine. It's a relatively good idea, so if you want to offer
configuration options, the file where your engine's module is defined is
perfect for that. Place the methods inside the module and you'll be good to go.

Within lib/blorgh/engine.rb is the base class for the engine:

```ruby
module Blorgh
  class Engine < ::Rails::Engine
    isolate_namespace Blorgh
  end
end
```

By inheriting from the Rails::Engine class, this gem notifies Rails that
there's an engine at the specified path, and will correctly mount the engine
inside the application, performing tasks such as adding the app directory of
the engine to the load path for models, mailers, controllers, and views.

The isolate_namespace method here deserves special notice. This call is
responsible for isolating the controllers, models, routes, and other things into
their own namespace, away from similar components inside the application.
Without this, there is a possibility that the engine's components could "leak"
into the application, causing unwanted disruption, or that important engine
components could be overridden by similarly named things within the application.
One of the examples of such conflicts is helpers. Without calling
isolate_namespace, the engine's helpers would be included in an application's
controllers.

It is highly recommended that the isolate_namespace line be left
within the Engine class definition. Without it, classes generated in an engine
may conflict with an application.

What this isolation of the namespace means is that a model generated by a call
to bin/rails generate model, such as bin/rails generate model article, won't be called Article, but
instead be namespaced and called Blorgh::Article. In addition, the table for the
model is namespaced, becoming blorgh_articles, rather than simply articles.
Similar to the model namespacing, a controller called ArticlesController becomes
Blorgh::ArticlesController and the views for that controller will not be at
app/views/articles, but app/views/blorgh/articles instead. Mailers, jobs
and helpers are namespaced as well.

Finally, routes will also be isolated within the engine. This is one of the most
important parts about namespacing, and is discussed later in the
Routes section of this guide.

#### 2.1.2. app Directory

Inside the app directory are the standard assets, controllers, helpers,
jobs, mailers, models, and views directories that you should be familiar with
from an application. We'll look more into models in a future section, when we're writing the engine.

Within the app/assets directory, there are the images and
stylesheets directories which, again, you should be familiar with due to their
similarity to an application. One difference here, however, is that each
directory contains a sub-directory with the engine name. Because this engine is
going to be namespaced, its assets should be too.

Within the app/controllers directory there is a blorgh directory that
contains a file called application_controller.rb. This file will provide any
common functionality for the controllers of the engine. The blorgh directory
is where the other controllers for the engine will go. By placing them within
this namespaced directory, you prevent them from possibly clashing with
identically-named controllers within other engines or even within the
application.

The ApplicationController class inside an engine is named just like a
Rails application in order to make it easier for you to convert your
applications into engines.

Just like for app/controllers, you will find a blorgh subdirectory under
the app/helpers, app/jobs, app/mailers and app/models directories
containing the associated application_*.rb file for gathering common
functionalities. By placing your files under this subdirectory and namespacing
your objects, you prevent them from possibly clashing with identically-named
elements within other engines or even within the application.

Lastly, the app/views directory contains a layouts folder, which contains a
file at blorgh/application.html.erb. This file allows you to specify a layout
for the engine. If this engine is to be used as a stand-alone engine, then you
would add any customization to its layout in this file, rather than the
application's app/views/layouts/application.html.erb file.

If you don't want to force a layout on to users of the engine, then you can
delete this file and reference a different layout in the controllers of your
engine.

#### 2.1.3. bin Directory

This directory contains one file, bin/rails, which enables you to use the
rails sub-commands and generators just like you would within an application.
This means that you will be able to generate new controllers and models for this
engine very easily by running commands like this:

```bash
$ bin/rails generate model
```

Keep in mind, of course, that anything generated with these commands inside of
an engine that has isolate_namespace in the Engine class will be namespaced.

#### 2.1.4. test Directory

The test directory is where tests for the engine will go. To test the engine,
there is a cut-down version of a Rails application embedded within it at
test/dummy. This application will mount the engine in the
test/dummy/config/routes.rb file:

```ruby
Rails.application.routes.draw do
  mount Blorgh::Engine => "/blorgh"
end
```

This line mounts the engine at the path /blorgh, which will make it accessible
through the application only at that path.

Inside the test directory there is the test/integration directory, where
integration tests for the engine should be placed. Other directories can be
created in the test directory as well. For example, you may wish to create a
test/models directory for your model tests.

## 3. Providing Engine Functionality

The engine that this guide covers provides submitting articles and commenting
functionality and follows a similar thread to the Getting Started
Guide, with some new twists.

For this section, make sure to run the commands in the root of the
blorgh engine's directory.

### 3.1. Generating an Article Resource

The first thing to generate for a blog engine is the Article model and related
controller. To quickly generate this, you can use the Rails scaffold generator.

```bash
$ bin/rails generate scaffold article title:string text:text
```

This command will output this information:

```
invoke  active_record
create    db/migrate/[timestamp]_create_blorgh_articles.rb
create    app/models/blorgh/article.rb
invoke    test_unit
create      test/models/blorgh/article_test.rb
create      test/fixtures/blorgh/articles.yml
invoke  resource_route
 route    resources :articles
invoke  scaffold_controller
create    app/controllers/blorgh/articles_controller.rb
invoke    erb
create      app/views/blorgh/articles
create      app/views/blorgh/articles/index.html.erb
create      app/views/blorgh/articles/edit.html.erb
create      app/views/blorgh/articles/show.html.erb
create      app/views/blorgh/articles/new.html.erb
create      app/views/blorgh/articles/_form.html.erb
create      app/views/blorgh/articles/_article.html.erb
invoke    resource_route
invoke    test_unit
create      test/controllers/blorgh/articles_controller_test.rb
create      test/system/blorgh/articles_test.rb
invoke    helper
create      app/helpers/blorgh/articles_helper.rb
invoke      test_unit
```

The first thing that the scaffold generator does is invoke the active_record
generator, which generates a migration and a model for the resource. Note here,
however, that the migration is called create_blorgh_articles rather than the
usual create_articles. This is due to the isolate_namespace method called in
the Blorgh::Engine class's definition. The model here is also namespaced,
being placed at app/models/blorgh/article.rb rather than app/models/article.rb due
to the isolate_namespace call within the Engine class.

Next, the test_unit generator is invoked for this model, generating a model
test at test/models/blorgh/article_test.rb (rather than
test/models/article_test.rb) and a fixture at test/fixtures/blorgh/articles.yml
(rather than test/fixtures/articles.yml).

After that, a line for the resource is inserted into the config/routes.rb file
for the engine. This line is simply resources :articles, turning the
config/routes.rb file for the engine into this:

```ruby
Blorgh::Engine.routes.draw do
  resources :articles
end
```

Note here that the routes are drawn upon the Blorgh::Engine object rather than
the YourApp::Application class. This is so that the engine routes are confined
to the engine itself and can be mounted at a specific point as shown in the
test directory section. It also causes the engine's routes to
be isolated from those routes that are within the application. The
Routes section of this guide describes it in detail.

Next, the scaffold_controller generator is invoked, generating a controller
called Blorgh::ArticlesController (at
app/controllers/blorgh/articles_controller.rb) and its related views at
app/views/blorgh/articles. This generator also generates tests for the
controller (test/controllers/blorgh/articles_controller_test.rb and test/system/blorgh/articles_test.rb) and a helper (app/helpers/blorgh/articles_helper.rb).

Everything this generator has created is neatly namespaced. The controller's
class is defined within the Blorgh module:

```ruby
module Blorgh
  class ArticlesController < ApplicationController
    # ...
  end
end
```

The ArticlesController class inherits from
Blorgh::ApplicationController, not the application's ApplicationController.

The helper inside app/helpers/blorgh/articles_helper.rb is also namespaced:

```ruby
module Blorgh
  module ArticlesHelper
    # ...
  end
end
```

This helps prevent conflicts with any other engine or application that may have
an article resource as well.

You can see what the engine has so far by running bin/rails db:migrate at the root
of our engine to run the migration generated by the scaffold generator, and then
running bin/rails server in test/dummy. When you open
http://localhost:3000/blorgh/articles you will see the default scaffold that has
been generated. Click around! You've just generated your first engine's first
functions.

If you'd rather play around in the console, bin/rails console will also work just
like a Rails application. Remember: the Article model is namespaced, so to
reference it you must call it as Blorgh::Article.

```
irb> Blorgh::Article.find(1)
=> #<Blorgh::Article id: 1 ...>
```

One final thing is that the articles resource for this engine should be the root
of the engine. Whenever someone goes to the root path where the engine is
mounted, they should be shown a list of articles. This can be made to happen if
this line is inserted into the config/routes.rb file inside the engine:

```ruby
root to: "articles#index"
```

Now people will only need to go to the root of the engine to see all the articles,
rather than visiting /articles. This means that instead of
http://localhost:3000/blorgh/articles, you only need to go to
http://localhost:3000/blorgh now.

### 3.2. Generating a Comments Resource

Now that the engine can create new articles, it only makes sense to add
commenting functionality as well. To do this, you'll need to generate a comment
model, a comment controller, and then modify the articles scaffold to display
comments and allow people to create new ones.

From the engine root, run the model generator. Tell it to generate a
Comment model, with the related table having two columns: an article references
column and text text column.

```bash
$ bin/rails generate model Comment article:references text:text
```

This will output the following:

```
invoke  active_record
create    db/migrate/[timestamp]_create_blorgh_comments.rb
create    app/models/blorgh/comment.rb
invoke    test_unit
create      test/models/blorgh/comment_test.rb
create      test/fixtures/blorgh/comments.yml
```

This generator call will generate just the necessary model files it needs,
namespacing the files under a blorgh directory and creating a model class
called Blorgh::Comment. Now run the migration to create our blorgh_comments
table:

```bash
$ bin/rails db:migrate
```

To show the comments on an article, edit app/views/blorgh/articles/show.html.erb and
add this line before the "Edit" link:

```ruby
<h3>Comments</h3>
<%= render @article.comments %>
```

This line will require there to be a has_many association for comments defined
on the Blorgh::Article model, which there isn't right now. To define one, open
app/models/blorgh/article.rb and add this line into the model:

```ruby
has_many :comments
```

Turning the model into this:

```ruby
module Blorgh
  class Article < ApplicationRecord
    has_many :comments
  end
end
```

Because the has_many is defined inside a class that is inside the
Blorgh module, Rails will know that you want to use the Blorgh::Comment
model for these objects, so there's no need to specify that using the
:class_name option here.

Next, there needs to be a form so that comments can be created on an article. To
add this, put this line underneath the call to render @article.comments in
app/views/blorgh/articles/show.html.erb:

```ruby
<%= render "blorgh/comments/form" %>
```

Next, the partial that this line will render needs to exist. Create a new
directory at app/views/blorgh/comments and in it a new file called
_form.html.erb which has this content to create the required partial:

```ruby
<h3>New comment</h3>
<%= form_with model: [@article, @article.comments.build] do |form| %>
  <p>
    <%= form.label :text %><br>
    <%= form.textarea :text %>
  </p>
  <%= form.submit %>
<% end %>
```

When this form is submitted, it is going to attempt to perform a POST request
to a route of /articles/:article_id/comments within the engine. This route doesn't
exist at the moment, but can be created by changing the resources :articles line
inside config/routes.rb into these lines:

```ruby
resources :articles do
  resources :comments
end
```

This creates a nested route for the comments, which is what the form requires.

The route now exists, but the controller that this route goes to does not. To
create it, run this command from the engine root:

```bash
$ bin/rails generate controller comments
```

This will generate the following things:

```
create  app/controllers/blorgh/comments_controller.rb
invoke  erb
 exist    app/views/blorgh/comments
invoke  test_unit
create    test/controllers/blorgh/comments_controller_test.rb
invoke  helper
create    app/helpers/blorgh/comments_helper.rb
invoke    test_unit
```

The form will be making a POST request to /articles/:article_id/comments, which
will correspond with the create action in Blorgh::CommentsController. This
action needs to be created, which can be done by putting the following lines
inside the class definition in app/controllers/blorgh/comments_controller.rb:

```ruby
def create
  @article = Article.find(params[:article_id])
  @comment = @article.comments.create(comment_params)
  flash[:notice] = "Comment has been created!"
  redirect_to articles_path
end

private
  def comment_params
    params.expect(comment: [:text])
  end
```

This is the final step required to get the new comment form working. Displaying
the comments, however, is not quite right yet. If you were to create a comment
right now, you would see this error:

```
Missing partial blorgh/comments/_comment with {:handlers=>[:erb, :builder],
:formats=>[:html], :locale=>[:en, :en]}. Searched in:   *
"/Users/ryan/Sites/side_projects/blorgh/test/dummy/app/views"   *
"/Users/ryan/Sites/side_projects/blorgh/app/views"
```

The engine is unable to find the partial required for rendering the comments.
Rails looks first in the application's (test/dummy) app/views directory and
then in the engine's app/views directory. When it can't find it, it will throw
this error. The engine knows to look for blorgh/comments/_comment because the
model object it is receiving is from the Blorgh::Comment class.

This partial will be responsible for rendering just the comment text, for now.
Create a new file at app/views/blorgh/comments/_comment.html.erb and put this
line inside it:

```ruby
<%= comment_counter + 1 %>. <%= comment.text %>
```

The comment_counter local variable is given to us by the <%= render
@article.comments %> call, which will define it automatically and increment the
counter as it iterates through each comment. It's used in this example to
display a small number next to each comment when it's created.

That completes the comment function of the blogging engine. Now it's time to use
it within an application.

## 4. Hooking Into an Application

Using an engine within an application is very easy. This section covers how to
mount the engine into an application and the initial setup required, as well as
linking the engine to a User class provided by the application to provide
ownership for articles and comments within the engine.

### 4.1. Mounting the Engine

First, the engine needs to be specified inside the application's Gemfile. If
there isn't an application handy to test this out in, generate one using the
rails new command outside of the engine directory like this:

```bash
$ rails new unicorn
```

Usually, specifying the engine inside the Gemfile would be done by specifying it
as a normal, everyday gem.

```ruby
gem "devise"
```

However, because you are developing the blorgh engine on your local machine,
you will need to specify the :path option in your Gemfile:

```ruby
gem "blorgh", path: "engines/blorgh"
```

Then run bundle to install the gem.

As described earlier, by placing the gem in the Gemfile it will be loaded when
Rails is loaded. It will first require lib/blorgh.rb from the engine, then
lib/blorgh/engine.rb, which is the file that defines the major pieces of
functionality for the engine.

To make the engine's functionality accessible from within an application, it
needs to be mounted in that application's config/routes.rb file:

```ruby
mount Blorgh::Engine, at: "/blog"
```

This line will mount the engine at /blog in the application. Making it
accessible at http://localhost:3000/blog when the application runs with bin/rails
server.

Other engines, such as Devise, handle this a little differently by making
you specify custom helpers (such as devise_for) in the routes. These helpers
do exactly the same thing, mounting pieces of the engines's functionality at a
pre-defined path which may be customizable.

### 4.2. Engine Setup

The engine contains migrations for the blorgh_articles and blorgh_comments
table which need to be created in the application's database so that the
engine's models can query them correctly. To copy these migrations into the
application run the following command from the application's root:

```bash
$ bin/rails blorgh:install:migrations
```

If you have multiple engines that need migrations copied over, use
railties:install:migrations instead:

```bash
$ bin/rails railties:install:migrations
```

You can specify a custom path in the source engine for the migrations by specifying MIGRATIONS_PATH.

```bash
$ bin/rails railties:install:migrations MIGRATIONS_PATH=db_blourgh
```

If you have multiple databases you can also specify the target database by specifying DATABASE.

```bash
$ bin/rails railties:install:migrations DATABASE=animals
```

This command, when run for the first time, will copy over all the migrations
from the engine. When run the next time, it will only copy over migrations that
haven't been copied over already. The first run for this command will output
something such as this:

```
Copied migration [timestamp_1]_create_blorgh_articles.blorgh.rb from blorgh
Copied migration [timestamp_2]_create_blorgh_comments.blorgh.rb from blorgh
```

The first timestamp ([timestamp_1]) will be the current time, and the second
timestamp ([timestamp_2]) will be the current time plus a second. The reason
for this is so that the migrations for the engine are run after any existing
migrations in the application.

To run these migrations within the context of the application, simply run bin/rails
db:migrate. When accessing the engine through http://localhost:3000/blog, the
articles will be empty. This is because the table created inside the application is
different from the one created within the engine. Go ahead, play around with the
newly mounted engine. You'll find that it's the same as when it was only an
engine.

If you would like to run migrations only from one engine, you can do it by
specifying SCOPE:

```bash
$ bin/rails db:migrate SCOPE=blorgh
```

This may be useful if you want to revert engine's migrations before removing it.
To revert all migrations from blorgh engine you can run code such as:

```bash
$ bin/rails db:migrate SCOPE=blorgh VERSION=0
```

### 4.3. Using a Class Provided by the Application

#### 4.3.1. Using a Model Provided by the Application

When an engine is created, it may want to use specific classes from an
application to provide links between the pieces of the engine and the pieces of
the application. In the case of the blorgh engine, making articles and comments
have authors would make a lot of sense.

A typical application might have a User class that would be used to represent
authors for an article or a comment. But there could be a case where the
application calls this class something different, such as Person. For this
reason, the engine should not hardcode associations specifically for a User
class.

To keep it simple in this case, the application will have a class called User
that represents the users of the application (we'll get into making this
configurable further on). It can be generated using this command inside the
application:

```bash
$ bin/rails generate model user name:string
```

The bin/rails db:migrate command needs to be run here to ensure that our
application has the users table for future use.

Also, to keep it simple, the articles form will have a new text field called
author_name, where users can elect to put their name. The engine will then
take this name and either create a new User object from it, or find one that
already has that name. The engine will then associate the article with the found or
created User object.

First, the author_name text field needs to be added to the
app/views/blorgh/articles/_form.html.erb partial inside the engine. This can be
added above the title field with this code:

```ruby
<div class="field">
  <%= form.label :author_name %><br>
  <%= form.text_field :author_name %>
</div>
```

Next, we need to update our Blorgh::ArticlesController#article_params method to
permit the new form parameter:

```ruby
def article_params
  params.expect(article: [:title, :text, :author_name])
end
```

The Blorgh::Article model should then have some code to convert the author_name
field into an actual User object and associate it as that article's author
before the article is saved. It will also need to have an attr_accessor set up
for this field, so that the setter and getter methods are defined for it.

To do all this, you'll need to add the attr_accessor for author_name, the
association for the author and the before_validation call into
app/models/blorgh/article.rb. The author association will be hard-coded to the
User class for the time being.

```ruby
attr_accessor :author_name
belongs_to :author, class_name: "User"

before_validation :set_author

private
  def set_author
    self.author = User.find_or_create_by(name: author_name)
  end
```

By representing the author association's object with the User class, a link
is established between the engine and the application. There needs to be a way
of associating the records in the blorgh_articles table with the records in the
users table. Because the association is called author, there should be an
author_id column added to the blorgh_articles table.

To generate this new column, run this command within the engine:

```bash
$ bin/rails generate migration add_author_id_to_blorgh_articles author_id:integer
```

Due to the migration's name and the column specification after it, Rails
will automatically know that you want to add a column to a specific table and
write that into the migration for you. You don't need to tell it any more than
this.

This migration will need to be run on the application. To do that, it must first
be copied using this command:

```bash
$ bin/rails blorgh:install:migrations
```

Notice that only one migration was copied over here. This is because the first
two migrations were copied over the first time this command was run.

```
NOTE Migration [timestamp]_create_blorgh_articles.blorgh.rb from blorgh has been skipped. Migration with the same name already exists.
NOTE Migration [timestamp]_create_blorgh_comments.blorgh.rb from blorgh has been skipped. Migration with the same name already exists.
Copied migration [timestamp]_add_author_id_to_blorgh_articles.blorgh.rb from blorgh
```

Run the migration using:

```bash
$ bin/rails db:migrate
```

Now with all the pieces in place, an action will take place that will associate
an author - represented by a record in the users table - with an article,
represented by the blorgh_articles table from the engine.

Finally, the author's name should be displayed on the article's page. Add this code
above the "Title" output inside app/views/blorgh/articles/_article.html.erb:

```ruby
<p>
  <strong>Author:</strong>
  <%= article.author.name %>
</p>
```

#### 4.3.2. Using a Controller Provided by the Application

Because Rails controllers generally share code for things like authentication
and accessing session variables, they inherit from ApplicationController by
default. Rails engines, however are scoped to run independently from the main
application, so each engine gets a scoped ApplicationController. This
namespace prevents code collisions, but often engine controllers need to access
methods in the main application's ApplicationController. An easy way to
provide this access is to change the engine's scoped ApplicationController to
inherit from the main application's ApplicationController. For our Blorgh
engine this would be done by changing
app/controllers/blorgh/application_controller.rb to look like:

```ruby
module Blorgh
  class ApplicationController < ::ApplicationController
  end
end
```

By default, the engine's controllers inherit from
Blorgh::ApplicationController. So, after making this change they will have
access to the main application's ApplicationController, as though they were
part of the main application.

This change does require that the engine is run from a Rails application that
has an ApplicationController.

### 4.4. Configuring an Engine

This section covers how to make the User class configurable, followed by
general configuration tips for the engine.

#### 4.4.1. Setting Configuration Settings in the Application

The next step is to make the class that represents a User in the application
customizable for the engine. This is because that class may not always be
User, as previously explained. To make this setting customizable, the engine
will have a configuration setting called author_class that will be used to
specify which class represents users inside the application.

To define this configuration setting, you should use a mattr_accessor inside
the Blorgh module for the engine. Add this line to lib/blorgh.rb inside the
engine:

```ruby
mattr_accessor :author_class
```

This method works like its siblings, attr_accessor and cattr_accessor, but
provides a setter and getter method on the module with the specified name. To
use it, it must be referenced using Blorgh.author_class.

The next step is to switch the Blorgh::Article model over to this new setting.
Change the belongs_to association inside this model
(app/models/blorgh/article.rb) to this:

```ruby
belongs_to :author, class_name: Blorgh.author_class
```

The set_author method in the Blorgh::Article model should also use this class:

```ruby
self.author = Blorgh.author_class.constantize.find_or_create_by(name: author_name)
```

To save having to call constantize on the author_class result all the time,
you could instead just override the author_class getter method inside the
Blorgh module in the lib/blorgh.rb file to always call constantize on the
saved value before returning the result:

```ruby
def self.author_class
  @@author_class.constantize
end
```

This would then turn the above code for set_author into this:

```ruby
self.author = Blorgh.author_class.find_or_create_by(name: author_name)
```

Resulting in something a little shorter, and more implicit in its behavior. The
author_class method should always return a Class object.

Since we changed the author_class method to return a Class instead of a
String, we must also modify our belongs_to definition in the Blorgh::Article
model:

```ruby
belongs_to :author, class_name: Blorgh.author_class.to_s
```

To set this configuration setting within the application, an initializer should
be used. By using an initializer, the configuration will be set up before the
application starts and calls the engine's models, which may depend on this
configuration setting existing.

Create a new initializer at config/initializers/blorgh.rb inside the
application where the blorgh engine is installed and put this content in it:

```ruby
Blorgh.author_class = "User"
```

It's very important here to use the String version of the class,
rather than the class itself. If you were to use the class, Rails would attempt
to load that class and then reference the related table. This could lead to
problems if the table didn't already exist. Therefore, a String should be
used and then converted to a class using constantize in the engine later on.

Go ahead and try to create a new article. You will see that it works exactly in the
same way as before, except this time the engine is using the configuration
setting in config/initializers/blorgh.rb to learn what the class is.

There are now no strict dependencies on what the class is, only what the API for
the class must be. The engine simply requires this class to define a
find_or_create_by method which returns an object of that class, to be
associated with an article when it's created. This object, of course, should have
some sort of identifier by which it can be referenced.

#### 4.4.2. General Engine Configuration

Within an engine, there may come a time where you wish to use things such as
initializers, internationalization, or other configuration options. The great
news is that these things are entirely possible, because a Rails engine shares
much the same functionality as a Rails application. In fact, a Rails
application's functionality is actually a superset of what is provided by
engines!

If you wish to use an initializer - code that should run before the engine is
loaded - the place for it is the config/initializers folder. This directory's
functionality is explained in the Initializers
section of the Configuring guide, and works
precisely the same way as the config/initializers directory inside an
application. The same thing goes if you want to use a standard initializer.

For locales, simply place the locale files in the config/locales directory,
just like you would in an application.

## 5. Testing an Engine

When an engine is generated, there is a smaller dummy application created inside
it at test/dummy. This application is used as a mounting point for the engine,
to make testing the engine extremely simple. You may extend this application by
generating controllers, models, or views from within the directory, and then use
those to test your engine.

The test directory should be treated like a typical Rails testing environment,
allowing for unit, functional, and integration tests.

### 5.1. Functional Tests

A matter worth taking into consideration when writing functional tests is that
the tests are going to be running on an application - the test/dummy
application - rather than your engine. This is due to the setup of the testing
environment; an engine needs an application as a host for testing its main
functionality, especially controllers. This means that if you were to make a
typical GET to a controller in a controller's functional test like this:

```ruby
module Blorgh
  class FooControllerTest < ActionDispatch::IntegrationTest
    include Engine.routes.url_helpers

    def test_index
      get foos_url
      # ...
    end
  end
end
```

It may not function correctly. This is because the application doesn't know how
to route these requests to the engine unless you explicitly tell it how. To
do this, you must set the @routes instance variable to the engine's route set
in your setup code:

```ruby
module Blorgh
  class FooControllerTest < ActionDispatch::IntegrationTest
    include Engine.routes.url_helpers

    setup do
      @routes = Engine.routes
    end

    def test_index
      get foos_url
      # ...
    end
  end
end
```

This tells the application that you still want to perform a GET request to the
index action of this controller, but you want to use the engine's route to get
there, rather than the application's one.

This also ensures that the engine's URL helpers will work as expected in your
tests.

## 6. Improving Engine Functionality

This section explains how to add and/or override engine MVC functionality in the
main Rails application.

### 6.1. Overriding Models and Controllers

Engine models and controllers can be reopened by the parent application to extend or decorate them.

Overrides may be organized in a dedicated directory app/overrides, ignored by the autoloader, and preloaded in a to_prepare callback:

```ruby
# config/application.rb
module MyApp
  class Application < Rails::Application
    # ...

    overrides = "#{Rails.root}/app/overrides"
    Rails.autoloaders.main.ignore(overrides)

    config.to_prepare do
      Dir.glob("#{overrides}/**/*_override.rb").sort.each do |override|
        load override
      end
    end
  end
end
```

#### 6.1.1. Reopening Existing Classes Using class_eval

For example, in order to override the engine model

```ruby
# Blorgh/app/models/blorgh/article.rb
module Blorgh
  class Article < ApplicationRecord
    # ...
  end
end
```

you just create a file that reopens that class:

```ruby
# MyApp/app/overrides/models/blorgh/article_override.rb
Blorgh::Article.class_eval do
  # ...
end
```

It is very important that the override reopens the class or module. Using the class or module keywords would define them if they were not already in memory, which would be incorrect because the definition lives in the engine. Using class_eval as shown above ensures you are reopening.

#### 6.1.2. Reopening Existing Classes Using ActiveSupport::Concern

Using Class#class_eval is great for simple adjustments, but for more complex
class modifications, you might want to consider using ActiveSupport::Concern.
ActiveSupport::Concern manages load order of interlinked dependent modules and
classes at run time allowing you to significantly modularize your code.

Adding Article#time_since_created and Overriding Article#summary:

```ruby
# MyApp/app/models/blorgh/article.rb

class Blorgh::Article < ApplicationRecord
  include Blorgh::Concerns::Models::Article

  def time_since_created
    Time.current - created_at
  end

  def summary
    "#{title} - #{truncate(text)}"
  end
end
```

```ruby
# Blorgh/app/models/blorgh/article.rb
module Blorgh
  class Article < ApplicationRecord
    include Blorgh::Concerns::Models::Article
  end
end
```

```ruby
# Blorgh/lib/concerns/models/article.rb

module Blorgh::Concerns::Models::Article
  extend ActiveSupport::Concern

  # `included do` causes the block to be evaluated in the context
  # in which the module is included (i.e. Blorgh::Article),
  # rather than in the module itself.
  included do
    attr_accessor :author_name
    belongs_to :author, class_name: "User"

    before_validation :set_author

    private
      def set_author
        self.author = User.find_or_create_by(name: author_name)
      end
  end

  def summary
    "#{title}"
  end

  module ClassMethods
    def some_class_method
      "some class method string"
    end
  end
end
```

### 6.2. Autoloading and Engines

Please check the Autoloading and Reloading Constants
guide for more information about autoloading and engines.

### 6.3. Overriding Views

When Rails looks for a view to render, it will first look in the app/views
directory of the application. If it cannot find the view there, it will check in
the app/views directories of all engines that have this directory.

When the application is asked to render the view for Blorgh::ArticlesController's
index action, it will first look for the path
app/views/blorgh/articles/index.html.erb within the application. If it cannot
find it, it will look inside the engine.

You can override this view in the application by simply creating a new file at
app/views/blorgh/articles/index.html.erb. Then you can completely change what
this view would normally output.

Try this now by creating a new file at app/views/blorgh/articles/index.html.erb
and put this content in it:

```ruby
<h1>Articles</h1>
<%= link_to "New Article", new_article_path %>
<% @articles.each do |article| %>
  <h2><%= article.title %></h2>
  <small>By <%= article.author %></small>
  <%= simple_format(article.text) %>
  <hr>
<% end %>
```

### 6.4. Routes

Routes inside an engine are isolated from the application by default. This is
done by the isolate_namespace call inside the Engine class. This essentially
means that the application and its engines can have identically named routes and
they will not clash.

Routes inside an engine are drawn on the Engine class within
config/routes.rb, like this:

```ruby
Blorgh::Engine.routes.draw do
  resources :articles
end
```

By having isolated routes such as this, if you wish to link to an area of an
engine from within an application, you will need to use the engine's routing
proxy method. Calls to normal routing methods such as articles_path may end up
going to undesired locations if both the application and the engine have such a
helper defined.

For instance, the following example would go to the application's articles_path
if that template was rendered from the application, or the engine's articles_path
if it was rendered from the engine:

```ruby
<%= link_to "Blog articles", articles_path %>
```

To make this route always use the engine's articles_path routing helper method,
we must call the method on the routing proxy method that shares the same name as
the engine.

```ruby
<%= link_to "Blog articles", blorgh.articles_path %>
```

If you wish to reference the application inside the engine in a similar way, use
the main_app helper:

```ruby
<%= link_to "Home", main_app.root_path %>
```

If you were to use this inside an engine, it would always go to the
application's root. If you were to leave off the main_app "routing proxy"
method call, it could potentially go to the engine's or application's root,
depending on where it was called from.

If a template rendered from within an engine attempts to use one of the
application's routing helper methods, it may result in an undefined method call.
If you encounter such an issue, ensure that you're not attempting to call the
application's routing methods without the main_app prefix from within the
engine.

### 6.5. Assets

Assets within an engine work in an identical way to a full application. Because
the engine class inherits from Rails::Engine, the application will know to
look up assets in the engine's app/assets and lib/assets directories.

Like all of the other components of an engine, the assets should be namespaced.
This means that if you have an asset called style.css, it should be placed at
app/assets/stylesheets/[engine name]/style.css, rather than
app/assets/stylesheets/style.css. If this asset isn't namespaced, there is a
possibility that the host application could have an asset named identically, in
which case the application's asset would take precedence and the engine's one
would be ignored.

Imagine that you did have an asset located at
app/assets/stylesheets/blorgh/style.css. To include this asset inside an
application, just use stylesheet_link_tag and reference the asset as if it
were inside the engine:

```ruby
<%= stylesheet_link_tag "blorgh/style.css" %>
```

You can also specify these assets as dependencies of other assets using Asset
Pipeline require statements in processed files:

```
/*
 *= require blorgh/style
 */
```

Remember that in order to use languages like Sass or CoffeeScript, you
should add the relevant library to your engine's .gemspec.

### 6.6. Separate Assets and Precompiling

There are some situations where your engine's assets are not required by the
host application. For example, say that you've created an admin functionality
that only exists for your engine. In this case, the host application doesn't
need to require admin.css or admin.js. Only the gem's admin layout needs
these assets. It doesn't make sense for the host app to include
"blorgh/admin.css" in its stylesheets. In this situation, you should
explicitly define these assets for precompilation.  This tells Sprockets to add
your engine assets when bin/rails assets:precompile is triggered.

You can define assets for precompilation in engine.rb:

```ruby
initializer "blorgh.assets.precompile" do |app|
  app.config.assets.precompile += %w( admin.js admin.css )
end
```

For more information, read the Asset Pipeline guide.

### 6.7. Other Gem Dependencies

Gem dependencies inside an engine should be specified inside the .gemspec file
at the root of the engine. The reason is that the engine may be installed as a
gem. If dependencies were to be specified inside the Gemfile, these would not
be recognized by a traditional gem install and so they would not be installed,
causing the engine to malfunction.

To specify a dependency that should be installed with the engine during a
traditional gem install, specify it inside the Gem::Specification block
inside the .gemspec file in the engine:

```ruby
s.add_dependency "moo"
```

To specify a dependency that should only be installed as a development
dependency of the application, specify it like this:

```ruby
s.add_development_dependency "moo"
```

Both kinds of dependencies will be installed when bundle install is run inside
of the application. The development dependencies for the gem will only be used
when the development and tests for the engine are running.

Note that if you want to immediately require dependencies when the engine is
required, you should require them before the engine's initialization. For
example:

```ruby
require "other_engine/engine"
require "yet_another_engine/engine"

module MyEngine
  class Engine < ::Rails::Engine
  end
end
```

---

# Chapters

After reading this guide, you will know how to use the Rails command line:

- To create a Rails application.

- To generate models, controllers, tests, and database migrations.

- To start a development server.

- To inspect a Rails application through an interactive shell.

- To add and edit credentials.

## 1. Overview

The Rails command line is a powerful part of the Ruby on Rails framework. It
allows you to quickly start a new application by generating boilerplate code
(that follows Rails conventions). This guide includes an overview of Rails
commands that allow you to manage all aspects of your web application, including
the database.

You can get a list of commands available to you, which will often depend on your
current directory, by typing bin/rails --help. Each command has a description
to help clarify what it does.

```bash
$ bin/rails --help
Usage:
  bin/rails COMMAND [options]

You must specify a command. The most common commands are:

  generate     Generate new code (short-cut alias: "g")
  console      Start the Rails console (short-cut alias: "c")
  server       Start the Rails server (short-cut alias: "s")
  test         Run tests except system tests (short-cut alias: "t")
  test:system  Run system tests
  dbconsole    Start a console for the database specified in config/database.yml
               (short-cut alias: "db")
  plugin new   Create a new Rails railtie or engine

All commands can be run with -h (or --help) for more information.
```

The output of bin/rails --help then proceeds to list all commands in
alphabetical order, with a short description of each:

```bash
In addition to those commands, there are:
about                              List versions of all Rails frameworks ...
action_mailbox:ingress:exim        Relay an inbound email from Exim to ...
action_mailbox:ingress:postfix     Relay an inbound email from Postfix ...
action_mailbox:ingress:qmail       Relay an inbound email from Qmail to ...
action_mailbox:install             Install Action Mailbox and its ...
...
db:fixtures:load                   Load fixtures into the ...
db:migrate                         Migrate the database ...
db:migrate:status                  Display status of migrations
db:rollback                        Roll the schema back to ...
...
turbo:install                      Install Turbo into the app
turbo:install:bun                  Install Turbo into the app with bun
turbo:install:importmap            Install Turbo into the app with asset ...
turbo:install:node                 Install Turbo into the app with webpacker
turbo:install:redis                Switch on Redis and use it in development
version                            Show the Rails version
yarn:install                       Install all JavaScript dependencies as ...
zeitwerk:check                     Check project structure for Zeitwerk ...
```

In addition to bin/rails --help, running any command from the list above with
the --help flag can also be useful. For example, you can learn about the
options that can be used with bin/rails routes:

```bash
$ bin/rails routes --help
Usage:
  bin/rails routes

Options:
  -c, [--controller=CONTROLLER]      # Filter by a specific controller, e.g. PostsController or Admin::PostsController.
  -g, [--grep=GREP]                  # Grep routes by a specific pattern.
  -E, [--expanded], [--no-expanded]  # Print routes expanded vertically with parts explained.
  -u, [--unused], [--no-unused]      # Print unused routes.

List all the defined routes
```

Most Rails command line subcommands can be run with --help (or -h) and the
output can be very informative. For example bin/rails generate model --help
prints two pages of description, in addition to usage and options:

```bash
$ bin/rails generate model --help
Usage:
  bin/rails generate model NAME [field[:type][:index] field[:type][:index]] [options]
Options:
...
Description:
    Generates a new model. Pass the model name, either CamelCased or
    under_scored, and an optional list of attribute pairs as arguments.

    Attribute pairs are field:type arguments specifying the
    model's attributes. Timestamps are added by default, so you don't have to
    specify them by hand as 'created_at:datetime updated_at:datetime'.

    As a special case, specifying 'password:digest' will generate a
    password_digest field of string type, and configure your generated model and
    tests for use with Active Model has_secure_password (assuming the default ORM and test framework are being used).
    ...
```

Some of the most commonly used commands are:

- bin/rails console

- bin/rails server

- bin/rails test

- bin/rails generate

- bin/rails db:migrate

- bin/rails db:create

- bin/rails routes

- bin/rails dbconsole

- rails new app_name

We'll cover the above commands (and more) in the following sections, starting
with the command for creating a new application.

## 2. Creating a New Rails Application

We can create a brand new Rails application using the rails new command.

You will need the rails gem installed in order to run the rails new
command. You can do this by typing gem install rails - for more step-by-step
instructions, see the Installing Ruby on Rails
guide.

With the new command, Rails will set up the entire default directory structure
along with all the code needed to run a sample application right out of the box.
The first argument to rails new is the application name:

```bash
$ rails new my_app
     create
     create  README.md
     create  Rakefile
     create  config.ru
     create  .gitignore
     create  Gemfile
     create  app
     ...
     create  tmp/cache
     ...
        run  bundle install
```

You can pass options to the new command to modify its default behavior. You
can also create application templates
and use them with the new command.

### 2.1. Configure a Different Database

When creating a new Rails application, you can specify a preferred database for
your application by using the --database option. The default database for
rails new is SQLite. For example, you can set up a PostgreSQL database like
this:

```bash
$ rails new booknotes --database=postgresql
      create
      create  app/controllers
      create  app/helpers
...
```

The main difference is the content of the config/database.yml file. With the
PostgreSQL option, it looks like this:

```yaml
# PostgreSQL. Versions 9.3 and up are supported.
#
# Install the pg driver:
#   gem install pg
# On macOS with Homebrew:
#   gem install pg -- --with-pg-config=/usr/local/bin/pg_config
# On Windows:
#   gem install pg
#       Choose the win32 build.
#       Install PostgreSQL and put its /bin directory on your path.
#
# Configure Using Gemfile
# gem "pg"
#
default: &default
  adapter: postgresql
  encoding: unicode
  # For details on connection pooling, see Rails configuration guide
  # https://guides.rubyonrails.org/configuring.html#database-pooling
  pool: <%= ENV.fetch("RAILS_MAX_THREADS") { 3 } %>

development:
  <<: *default
  database: booknotes_development
  ...
```

The --database=postgresql option will also modify other files generated for a
new Rails app appropriately, such as adding the pg gem to the Gemfile, etc.

### 2.2. Skipping Defaults

The rails new command by default creates dozens of files. By using the
--skip option, you can skip some files from being generated if you don't need
them. For example,

```bash
$ rails new no_storage --skip-active-storage
Based on the specified options, the following options will also be activated:

  --skip-action-mailbox [due to --skip-active-storage]
  --skip-action-text [due to --skip-active-storage]

      create
      create  README.md
      ...
```

In the above example, Action Mailbox and Action Text are skipped in addition to
Active Storage because they depend on Active Storage functionality.

You can get a full list of what can be skipped in the options section of
rails new --help command.

## 3. Starting a Rails Application Server

We can start a Rails application using the bin/rails server command, which
launches the Puma web server that comes bundled
with Rails. You'll use this any time you want to access your application through
a web browser.

```bash
$ cd my_app
$ bin/rails server
=> Booting Puma
=> Rails 8.1.0 application starting in development
=> Run `bin/rails server --help` for more startup options
Puma starting in single mode...
* Puma version: 6.4.0 (ruby 3.1.3-p185) ("The Eagle of Durango")
*  Min threads: 3
*  Max threads: 3
*  Environment: development
*          PID: 5295
* Listening on http://127.0.0.1:3000
* Listening on http://[::1]:3000
Use Ctrl-C to stop
```

With just two commands we have a Rails application up and running. The server
command starts the application listening on port 3000 by default. You can open
your browser to http://localhost:3000 to see a basic
Rails application running.

Most common commands have a shortcut aliases. To start the server you can
use the alias "s": bin/rails s.

You can run the application on a different port using the -p option. You can
also change the environment using -e (default is development).

```bash
$ bin/rails server -e production -p 4000
```

The -b option binds Rails to the specified IP address, by default it is
localhost. You can run a server as a daemon by passing a -d option.

## 4. Generating Code

You can use the bin/rails generate command to generate a number of different
files and add functionality to your application, such as models, controllers,
and full scaffolds.

To see a list of built-in generators, you can run bin/rails generate (or
bin/rails g for short) without any arguments. It lists all available
generators after the usage. You can also learn more about what a specific
generator will do by using the --pretend option.

```bash
$ bin/rails generate
Usage:
  bin/rails generate GENERATOR [args] [options]

General options:
  -h, [--help]     # Print generator's options and usage
  -p, [--pretend]  # Run but do not make any changes
  -f, [--force]    # Overwrite files that already exist
  -s, [--skip]     # Skip files that already exist
  -q, [--quiet]    # Suppress status output

Please choose a generator below.
Rails:
  application_record
  benchmark
  channel
  controller
  generator
  helper
...
```

When you add certain gems to your application, they may install more
generators. You can also create your own generators, see the Generators
guide for more information.

The purpose of Rails' built-in generators is to save you time by freeing you
from having to write repetitive boilerplate code.

Let's add a controller with the controller generator.

### 4.1. Generating Controllers

We can find out exactly how to use the controller generator with the
bin/rails generate controller command (which is the same as using it with
--help). There is a "Usage" section and even an example:

```bash
$ bin/rails generate controller
Usage:
  bin/rails generate controller NAME [action action] [options]
...
Examples:
    `bin/rails generate controller credit_cards open debit credit close`

    This generates a `CreditCardsController` with routes like /credit_cards/debit.
        Controller: app/controllers/credit_cards_controller.rb
        Test:       test/controllers/credit_cards_controller_test.rb
        Views:      app/views/credit_cards/debit.html.erb [...]
        Helper:     app/helpers/credit_cards_helper.rb

    `bin/rails generate controller users index --skip-routes`

    This generates a `UsersController` with an index action and no routes.

    `bin/rails generate controller admin/dashboard --parent=admin_controller`

    This generates a `Admin::DashboardController` with an `AdminController` parent class.
```

The controller generator is expecting parameters in the form of generate
controller ControllerName action1 action2. Let's make a Greetings controller
with an action of hello, which will say something nice to us.

```bash
$ bin/rails generate controller Greetings hello
     create  app/controllers/greetings_controller.rb
      route  get 'greetings/hello'
     invoke  erb
     create    app/views/greetings
     create    app/views/greetings/hello.html.erb
     invoke  test_unit
     create    test/controllers/greetings_controller_test.rb
     invoke  helper
     create    app/helpers/greetings_helper.rb
     invoke    test_unit
```

The above command created various files at specific directories. It created a
controller file, a view file, a functional test file, a helper for the view, and
added a route.

To test out the new controller, we can modify the hello action and the view to
display a message:

```ruby
class GreetingsController < ApplicationController
  def hello
    @message = "Hello, how are you today?"
  end
end
```

```ruby
<h1>A Greeting for You!</h1>
<p><%= @message %></p>
```

Then, we can start the Rails server, with bin/rails server, and go to the
added route
http://localhost:3000/greetings/hello
to see the message.

Now let's use the generator to add models to our application.

### 4.2. Generating Models

The Rails model generator command has a very detailed "Description" section that
is worth reading. Here is the basic usage:

```bash
$ bin/rails generate model
Usage:
  bin/rails generate model NAME [field[:type][:index] field[:type][:index]] [options]
...
```

As an example, we can generate a post model like this:

```bash
$ bin/rails generate model post title:string body:text
    invoke  active_record
    create    db/migrate/20250807202154_create_posts.rb
    create    app/models/post.rb
    invoke    test_unit
    create      test/models/post_test.rb
    create      test/fixtures/posts.yml
```

The model generator adds test files as well as a migration, which you'll need to
run with bin/rails db:migrate.

For a list of available field types for the type parameter, refer to the
API
documentation.
The index parameter generates a corresponding index for the column. If you
don't specify a type for a field, Rails will default to type string.

In addition to generating controllers and models separately, Rails also provides
generators that add code for both at once as well as other files needed for a
standard CRUD resource. There are two generator commands that do this:
resource and scaffold. The resource command is more lightweight than
scaffold and generates less code.

### 4.3. Generating Resources

The bin/rails generate resource command generates model, migration, empty
controller, routes, and tests. It does not generate views and it does not fill
in the controller with CRUD methods.

Here are all the files generated with the resource command for post:

```bash
$ bin/rails generate resource post title:string body:text
      invoke  active_record
      create    db/migrate/20250919150856_create_posts.rb
      create    app/models/post.rb
      invoke    test_unit
      create      test/models/post_test.rb
      create      test/fixtures/posts.yml
      invoke  controller
      create    app/controllers/posts_controller.rb
      invoke    erb
      create      app/views/posts
      invoke    test_unit
      create      test/controllers/posts_controller_test.rb
      invoke    helper
      create      app/helpers/posts_helper.rb
      invoke      test_unit
      invoke  resource_route
       route    resources :posts
```

Use the resource command when you don't need views (e.g. writing an API) or
prefer to add controller actions manually.

### 4.4. Generating Scaffolds

A Rails scaffold generates a full set of files for a resource, including a
model, controller, views (HTML and JSON), routes, migration, tests, and helper
files. It can be used for quickly prototyping CRUD interfaces or when you want
to generate the basic structure of a resource as a starting point that you can
customize.

If you scaffold the post resource you can see all of the files mentioned above
being generated:

```bash
$ bin/rails generate scaffold post title:string body:text
      invoke  active_record
      create    db/migrate/20250919150748_create_posts.rb
      create    app/models/post.rb
      invoke    test_unit
      create      test/models/post_test.rb
      create      test/fixtures/posts.yml
      invoke  resource_route
       route    resources :posts
      invoke  scaffold_controller
      create    app/controllers/posts_controller.rb
      invoke    erb
      create      app/views/posts
      create      app/views/posts/index.html.erb
      create      app/views/posts/edit.html.erb
      create      app/views/posts/show.html.erb
      create      app/views/posts/new.html.erb
      create      app/views/posts/_form.html.erb
      create      app/views/posts/_post.html.erb
      invoke    resource_route
      invoke    test_unit
      create      test/controllers/posts_controller_test.rb
      create      test/system/posts_test.rb
      invoke    helper
      create      app/helpers/posts_helper.rb
      invoke      test_unit
      invoke    jbuilder
      create      app/views/posts/index.json.jbuilder
      create      app/views/posts/show.json.jbuilder
      create      app/views/posts/_post.json.jbuilder
```

At this point, you can run bin/rails db:migrate to create the post table
(see Managing the Database for more on that command).
Then, if you start the Rails server with bin/rails server and navigate to
http://localhost:3000/posts, you will be able to
interact with the post resource - see a list of posts, create new posts, as
well as edit and delete them.

The scaffold generates test files, though you will need to modify them and
actually add test cases for your code. See the Testing guide for
an in-depth look at creating and running tests.

### 4.5. Undoing Code Generation with bin/rails destroy

Imagine you made a typing error when using the generate command for a model
(or controller or scaffold or anything), it would be tedious to manually delete
each file that was created by the generator. Rails provides a destroy command
for that reason. You can think of destroy as the opposite of generate. It'll
figure out what generate did, and undo it.

You can also use the alias "d" to invoke the destroy command: bin/rails d.

For example, if you meant to generate an article model but instead typed
artcle:

```bash
$ bin/rails generate model Artcle title:string body:text
      invoke  active_record
      create    db/migrate/20250808142940_create_artcles.rb
      create    app/models/artcle.rb
      invoke    test_unit
      create      test/models/artcle_test.rb
      create      test/fixtures/artcles.yml
```

You can undo the generate command with destroy like this:

```bash
$ bin/rails destroy model Artcle title:string body:text
      invoke  active_record
      remove    db/migrate/20250808142940_create_artcles.rb
      remove    app/models/artcle.rb
      invoke    test_unit
      remove      test/models/artcle_test.rb
      remove      test/fixtures/artcles.yml
```

## 5. Interacting with a Rails Application

### 5.1. bin/rails console

The bin/rails console command loads a full Rails environment (including
models, database, etc.) into an interactive IRB style shell. It is a powerful
feature of the Ruby on Rails framework as it allows you to interact with, debug
and explore your entire application at the command line.

The Rails Console can be useful for testing out ideas by prototyping with code
and for creating and updating records in the database without needing to use a
browser.

```bash
$ bin/rails console
my-app(dev):001:0> Post.create(title: 'First!')
```

The Rails Console has several useful features. For example, if you wish to test
out some code without changing any data, you can use sandbox mode with
bin/rails console --sandbox. The sandbox mode wraps all database operations
in a transaction that rolls back when you exit:

```bash
$ bin/rails console --sandbox
Loading development environment in sandbox (Rails 8.1.0)
Any modifications you make will be rolled back on exit
my-app(dev):001:0>
```

The sandbox option is great for safely testing destructive changes without
affecting your database.

You can also specify the Rails environment for the console command with the
-e option:

```bash
$ bin/rails console -e test
Loading test environment (Rails 8.1.0)
```

#### 5.1.1. The app Object

Inside the Rails Console you have access to the app and helper instances.

With the app method you can access named route helpers:

```
my-app(dev)> app.root_path
=> "/"
my-app(dev)> app.edit_user_path
=> "profile/edit"
```

You can also use the app object to make requests of your application without
starting a real server:

```
my-app(dev)> app.get "/", headers: { "Host" => "localhost" }
Started GET "/" for 127.0.0.1 at 2025-08-11 11:11:34 -0500
...

my-app(dev)> app.response.status
=> 200
```

You have to pass the "Host" header with the app.get request above,
because the Rack client used under-the-hood defaults to "www.example.com" if not
"Host" is specified. You can modify your application to always use localhost
using a configuration or an initializer.

The reason you can "make requests" like above is because the app object is the
same one that Rails uses for integration tests:

```
my-app(dev)> app.class
=> ActionDispatch::Integration::Session
```

The app object exposes methods like app.cookies, app.session, app.post,
and app.response. This way you can simulate and debug integration tests in the
Rails Console.

#### 5.1.2. The helper Object

The helper object in the Rails console is your direct portal into Rails’ view
layer. It allows you to test out view-related formatting and utility methods in
the console, as well as custom helpers defined in your application (i.e. in
app/helpers).

```
my-app(dev)> helper.time_ago_in_words 3.days.ago
=> "3 days"

my-app(dev)> helper.l(Date.today)
=> "2025-08-11"

my-app(dev)> helper.pluralize(3, "child")
=> "3 children"

my-app(dev)> helper.truncate("This is a very long sentence", length: 22)
=> "This is a very long..."

my-app(dev)> helper.link_to("Home", "/")
=> "<a href=\"/\">Home</a>"
```

Assuming a custom_helper method is defined in a app/helpers/*_helper.rb
file:

```
my-app(dev)> helper.custom_helper
"testing custom_helper"
```

### 5.2. bin/rails dbconsole

The bin/rails dbconsole command figures out which database you're using and
drops you into the command line interface appropriate for that database. It also
figures out the command line parameters to start a session based on your
config/database.yml file and current Rails environment.

Once you're in a dbconsole session, you can interact with your database
directly as you normally would. For example, if you're using PostgreSQL, running
bin/rails dbconsole may look like this:

```bash
$ bin/rails dbconsole
psql (17.5 (Homebrew))
Type "help" for help.

booknotes_development=# help
You are using psql, the command-line interface to PostgreSQL.
Type:  \copyright for distribution terms
       \h for help with SQL commands
       \? for help with psql commands
       \g or terminate with semicolon to execute query
       \q to quit
booknotes_development=# \dt
                    List of relations
 Schema |              Name              | Type  | Owner
--------+--------------------------------+-------+-------
 public | action_text_rich_texts         | table | bhumi
 ...
```

The dbconsole command is a very convenient shorthand, it's equivalent to
running the psql command (or mysql or sqlite) with the appropriate
arguments from your database.yml:

```bash
psql -h <host> -p <port> -U <username> <database_name>
```

So if your database.yml file looks like this:

```
development:
  adapter: postgresql
  database: myapp_development
  username: myuser
  password:
  host: localhost
```

Running the bin/rails dbconsole command is the same as:

```bash
psql -h localhost -U myuser myapp_development
```

The dbconsole command supports MySQL (including MariaDB), PostgreSQL,
and SQLite3. You can also use the alias "db" to invoke the dbconsole: bin/rails db.

If you are using multiple databases, bin/rails dbconsole will connect to the
primary database by default. You can specify which database to connect to using
--database or --db:

```bash
$ bin/rails dbconsole --database=animals
```

### 5.3. bin/rails runner

The runner command executes Ruby code in the context of the Rails application
without having to open a Rails Console. This can be useful for one-off tasks
that do not need the interactivity of the Rails Console. For instance:

```bash
$ bin/rails runner "puts User.count"
42

$ bin/rails runner 'MyJob.perform_now'
```

You can specify the environment in which the runner command should operate
using the -e switch.

```bash
$ bin/rails runner -e production "puts User.count"
```

You can also execute code in a Ruby file with the runner command, in the
context of your Rails application:

```bash
$ bin/rails runner lib/path_to_ruby_script.rb
```

By default, bin/rails runner scripts are automatically wrapped with the Rails
Executor (which is an instance of ActiveSupport::Executor) associated with
your Rails application. The Executor creates a “safe zone” to run arbitrary
Ruby inside a Rails app so that the autoloader, middleware stack, and Active
Support hooks all behave consistently.

Therefore, executing bin/rails runner lib/path_to_ruby_script.rb is
functionally equivalent to the following:

```ruby
Rails.application.executor.wrap do
  # executes code inside lib/path_to_ruby_script.rb
end
```

If you have a reason to opt of this behavior, there is a --skip-executor
option.

```bash
$ bin/rails runner --skip-executor lib/long_running_script.rb
```

### 5.4. bin/rails boot

The bin/rails boot command is a low-level Rails command whose entire job is to
boot your Rails application. Specifically it loads config/boot.rb and
config/application.rb files so that the application environment is ready to
run.

The boot command boots the application and exits — it does nothing else. It
can be useful for debugging boot problems. If your app fails to start and you
want to isolate the boot phase (without running migrations, starting the server,
etc.), bin/rails boot can be a simple test.

It can also be useful for timing application initialization. You can profile how
long your application takes to boot by wrapping bin/rails boot in a profiler.

## 6. Inspecting an Application

### 6.1. bin/rails routes

The bin/rails routes command lists all defined routes in your application,
including the URI Pattern and HTTP verb, as well as the Controller Action it
maps to.

```bash
$ bin/rails routes
  Prefix  Verb  URI Pattern     Controller#Action
  books   GET   /books(:format) books#index
  books   POST  /books(:format) books#create
  ...
  ...
```

This can be useful for tracking down a routing issue, or simply getting an
overview of the resources and routes that are part of a Rails application. You
can also narrow down the output of the routes command with options like
--controller(-c) or --grep(-g):

```bash
# Only show routes where the controller name contains "users"
$ bin/rails routes --controller users

# Show routes handled by namespace Admin::UsersController
$ bin/rails routes -c admin/users

# Search by name, path, or controller/action with -g (or --grep)
$ bin/rails routes -g users
```

There is also an option, bin/rails routes --expanded, that displays even more
information about each route, including the line number in your
config/routes.rb where that route is defined:

```bash
$ bin/rails routes --expanded
--[ Route 1 ]--------------------------------------------------------------------------------
Prefix            |
Verb              |
URI               | /assets
Controller#Action | Propshaft::Server
Source Location   | propshaft (1.2.1) lib/propshaft/railtie.rb:49
--[ Route 2 ]--------------------------------------------------------------------------------
Prefix            | about
Verb              | GET
URI               | /about(.:format)
Controller#Action | posts#about
Source Location   | /Users/bhumi/Code/try_markdown/config/routes.rb:2
--[ Route 3 ]--------------------------------------------------------------------------------
Prefix            | posts
Verb              | GET
URI               | /posts(.:format)
Controller#Action | posts#index
Source Location   | /Users/bhumi/Code/try_markdown/config/routes.rb:4
```

In development mode, you can also access the same routes info by going to
http://localhost:3000/rails/info/routes

### 6.2. bin/rails about

The bin/rails about command displays information about your Rails application,
such as Ruby, RubyGems, and Rails versions, database adapter, schema version,
etc. It is useful when you need to ask for help or check if a security patch
might affect you.

```bash
$ bin/rails about
About your application's environment
Rails version             8.1.0
Ruby version              3.2.0 (x86_64-linux)
RubyGems version          3.3.7
Rack version              3.0.8
JavaScript Runtime        Node.js (V8)
Middleware:               ActionDispatch::HostAuthorization, Rack::Sendfile, ...
Application root          /home/code/my_app
Environment               development
Database adapter          sqlite3
Database schema version   20250205173523
```

### 6.3. bin/rails initializers

The bin/rails initializers command prints out all defined initializers in the
order they are invoked by Rails:

```bash
$ bin/rails initializers
ActiveSupport::Railtie.active_support.deprecator
ActionDispatch::Railtie.action_dispatch.deprecator
ActiveModel::Railtie.active_model.deprecator
...
Booknotes::Application.set_routes_reloader_hook
Booknotes::Application.set_clear_dependencies_hook
Booknotes::Application.enable_yjit
```

This command can be useful when initializers depend on each other and the order
in which they are run matters. Using this command, you can see what's run
before/after and discover the relationship between initializers. Rails runs
framework initializers first and then application ones, defined in
config/initializers.

### 6.4. bin/rails middleware

The bin/rails middleware shows you the entire Rack middleware stack for your
Rails application, in the exact order the middlewares are run for each request.

```bash
$ bin/rails middleware
use ActionDispatch::HostAuthorization
use Rack::Sendfile
use ActionDispatch::Static
use ActionDispatch::Executor
use ActionDispatch::ServerTiming
...
```

This can be useful to see which middleware Rails includes and which ones are
added by gems (Warden::Manager from Devise) as well as for debugging and
profiling.

### 6.5. bin/rails stats

The bin/rails stats command shows you things like lines of code (LOC) and the
number of classes and methods for various components in your application.

```bash
$ bin/rails stats
+----------------------+--------+--------+---------+---------+-----+-------+
| Name                 |  Lines |    LOC | Classes | Methods | M/C | LOC/M |
+----------------------+--------+--------+---------+---------+-----+-------+
| Controllers          |    309 |    247 |       7 |      37 |   5 |     4 |
| Helpers              |     10 |     10 |       0 |       0 |   0 |     0 |
| Jobs                 |      7 |      2 |       1 |       0 |   0 |     0 |
| Models               |     89 |     70 |       6 |       3 |   0 |    21 |
| Mailers              |     10 |     10 |       2 |       1 |   0 |     8 |
| Channels             |     16 |     14 |       1 |       2 |   2 |     5 |
| Views                |    622 |    501 |       0 |       1 |   0 |   499 |
| Stylesheets          |    584 |    495 |       0 |       0 |   0 |     0 |
| JavaScript           |     81 |     62 |       0 |       0 |   0 |     0 |
| Libraries            |      0 |      0 |       0 |       0 |   0 |     0 |
| Controller tests     |    117 |     75 |       4 |       9 |   2 |     6 |
| Helper tests         |      0 |      0 |       0 |       0 |   0 |     0 |
| Model tests          |     21 |      9 |       3 |       0 |   0 |     0 |
| Mailer tests         |      7 |      5 |       1 |       1 |   1 |     3 |
| Integration tests    |      0 |      0 |       0 |       0 |   0 |     0 |
| System tests         |     51 |     41 |       1 |       4 |   4 |     8 |
+----------------------+--------+--------+---------+---------+-----+-------+
| Total                |   1924 |   1541 |      26 |      58 |   2 |    24 |
+----------------------+--------+--------+---------+---------+-----+-------+
  Code LOC: 1411     Test LOC: 130     Code to Test Ratio: 1:0.1
```

### 6.6. bin/rails time:zones:all

Thebin/rails time:zones:all command prints the complete list of time zones
that Active Support knows about, along with their UTC offsets followed by the
Rails timezone identifiers.

As an example, you can use bin/rails time:zones:local to see your system's
timezone:

```bash
$ bin/rails time:zones:local

* UTC -06:00 *
Central America
Central Time (US & Canada)
Chihuahua
Guadalajara
Mexico City
Monterrey
Saskatchewan
```

This can be useful when setting config.time_zone in config/application.rb,
when you need an exact Rails time zone name and spelling (e.g., "Pacific Time
(US & Canada)"), to validate user input or when debugging.

## 7. Managing Assets

The bin/rails assets:* commands allow you to manage assets in the app/assets
directory.

You can get a list of all commands in the assets: namespace like this:

```bash
$ bin/rails -T assets
bin/rails assets:clean[count]  # Removes old files in config.assets.output_path
bin/rails assets:clobber       # Remove config.assets.output_path
bin/rails assets:precompile    # Compile all the assets from config.assets.paths
bin/rails assets:reveal        # Print all the assets available in config.assets.paths
bin/rails assets:reveal:full   # Print the full path of assets available in config.assets.paths
```

You can precompile the assets in app/assets using bin/rails
assets:precompile. See the Asset Pipeline
guide for more on precompiling.

You can remove older compiled assets using bin/rails assets:clean. The
assets:clean command allows for rolling deploys that may still be linking to
an old asset while the new assets are being built.

If you want to clear public/assets completely, you can use bin/rails assets:clobber.
assets:clobber`.

## 8. Managing the Database

The commands in this section, bin/rails db:*, are all about setting up
databases, managing migrations, etc.

You can get a list of all commands in the db: namespace like this:

```bash
$ bin/rails -T db
bin/rails db:create              # Create the database from DATABASE_URL or
bin/rails db:drop                # Drop the database from DATABASE_URL or
bin/rails db:encryption:init     # Generate a set of keys for configuring
bin/rails db:environment:set     # Set the environment value for the database
bin/rails db:fixtures:load       # Load fixtures into the current environments
bin/rails db:migrate             # Migrate the database (options: VERSION=x,
bin/rails db:migrate:down        # Run the "down" for a given migration VERSION
bin/rails db:migrate:redo        # Roll back the database one migration and
bin/rails db:migrate:status      # Display status of migrations
bin/rails db:migrate:up          # Run the "up" for a given migration VERSION
bin/rails db:prepare             # Run setup if database does not exist, or run
bin/rails db:reset               # Drop and recreate all databases from their
bin/rails db:rollback            # Roll the schema back to the previous version
bin/rails db:schema:cache:clear  # Clear a db/schema_cache.yml file
bin/rails db:schema:cache:dump   # Create a db/schema_cache.yml file
bin/rails db:schema:dump         # Create a database schema file (either db/
bin/rails db:schema:load         # Load a database schema file (either db/
bin/rails db:seed                # Load the seed data from db/seeds.rb
bin/rails db:seed:replant        # Truncate tables of each database for current
bin/rails db:setup               # Create all databases, load all schemas, and
bin/rails db:version             # Retrieve the current schema version number
bin/rails test:db                # Reset the database and run `bin/rails test`
```

### 8.1. Database Setup

The db:create and db:drop commands create or delete the database for the
current environment (or all environments with the db:create:all,
db:drop:all)

The db:seed command loads sample data from db/seeds.rb and the
db:seed:replant command truncates tables of each database for the current
environment and then loads the seed data.

The db:setup command creates all databases, loads all schemas, and initializes
with the seed data (it does not drop databases first, like the db:reset
command below).

The db:reset command drops and recreates all databases from their schema for
the current environment and loads the seed data (so it's a combination of the
above commands).

For more on seed data, see this
section of the Active
Record Migrations guide.

### 8.2. Migrations

The db:migrate command is one of the most frequently run commands in a Rails
application; it migrates the database by running all new (not yet run)
migrations.

The db:migrate:up command runs the "up" method and the db:migrate:down
command runs the "down" method for the migration specified by the VERSION
argument.

```bash
$ bin/rails db:migrate:down VERSION=20250812120000
```

The db:rollback command rolls the schema back to the previous version (or you
can specify steps with the STEP=n argument).

The db:migrate:redo command rolls back the database one migration and
re-migrates up. It is a combination of the above two commands.

There is also a db:migrate:status command, which shows which migrations have
been run and which are still pending:

```bash
$ bin/rails db:migrate:status
database: db/development.sqlite3

 Status   Migration ID    Migration Name
--------------------------------------------------
   up     20250101010101  Create users
   up     20250102020202  Add email to users
  down    20250812120000  Add age to users
```

Please see the Migration Guide for an
explanation of concepts related to database migrations and other migration commands.

### 8.3. Schema Management

There are two main commands that help with managing the database schema in your
Rails application: db:schema:dump and db:schema:load.

The db:schema:dump command reads your database’s current schema and writes
it out to the db/schema.rb file (or db/structure.sql if you’ve configured
the schema format to sql). After running migrations, Rails automatically calls
schema:dump so your schema file is always up to date (and doesn't need to be
modified manually).

The schema file is a blueprint of your database and it is useful for setting up
new environments for tests or development. It’s version-controlled, so you can
see changes to the schema over time.

The db:schema:load command drops and recreates the database schema from
db/schema.rb (or db/structure.sql). It does this directly, without
replaying each migration one at a time.

This command is useful for quickly resetting a database to the current schema
without running years of migrations one by one. For example, running db:setup
also calls db:schema:load after creating the database and before seeding it.

You can think of db:schema:dump as the one that writes the schema.rb file
and db:schema:load as the one that reads that file.

### 8.4. Other Utility Commands

#### 8.4.1. bin/rails db:version

The bin/rails db:version command will show you the current version of the
database, which can be useful for troubleshooting.

```bash
$ bin/rails db:version

database: storage/development.sqlite3
Current version: 20250806173936
```

#### 8.4.2. db:fixtures:load

The db:fixtures:load command loads fixtures into the current environment's
database. To load specific fixtures, you can use FIXTURES=x,y. To load from a
subdirectory in test/fixtures, use FIXTURES_DIR=z.

```bash
$ bin/rails db:fixtures:load
   -> Loading fixtures from test/fixtures/users.yml
   -> Loading fixtures from test/fixtures/books.yml
```

#### 8.4.3. db:system:change

In an existing Rails application, it's possible to switch to a different
database. The db:system:change command helps with that by changing the
config/database.yml file and your database gem to the target database.

```bash
$ bin/rails db:system:change --to=postgresql
    conflict  config/database.yml
Overwrite config/database.yml? (enter "h" for help) [Ynaqdhm] Y
       force  config/database.yml
        gsub  Gemfile
        gsub  Gemfile
...
```

#### 8.4.4. db:encryption:init

The db:encryption:init command generates a set of keys for configuring Active
Record encryption in a given environment.

## 9. Running Tests

The bin/rails test command helps you run the different types of tests in your
application. The bin/rails test --help output has good examples of the
different options for this command:

You can run a single test by appending a line number to a filename:

```bash
bin/rails test test/models/user_test.rb:27
```

You can run multiple tests within a line range by appending the line range to a filename:

```bash
bin/rails test test/models/user_test.rb:10-20
```

You can run multiple files and directories at the same time:

```bash
bin/rails test test/controllers test/integration/login_test.rb
```

Rails comes with a testing framework called Minitest and there are also Minitest
options you can use with the test command:

```bash
# Only run tests whose names match the regex /validation/
$ bin/rails test -n /validation/
```

Please see the  Testing Guide for explanations and
examples of different types of tests.

## 10. Other Useful Commands

### 10.1. bin/rails notes

The bin/rails notes command searches through your code for comments beginning
with a specific keyword. You can refer to bin/rails notes --help for
information about usage.

By default, it will search in app, config, db, lib, and test
directories for FIXME, OPTIMIZE, and TODO annotations in files with extension
.builder, .rb, .rake, .yml, .yaml, .ruby, .css, .js, and .erb.

```bash
$ bin/rails notes
app/controllers/admin/users_controller.rb:
  * [ 20] [TODO] any other way to do this?
  * [132] [FIXME] high priority for next deploy

lib/school.rb:
  * [ 13] [OPTIMIZE] refactor this code to make it faster
```

#### 10.1.1. Annotations

You can pass specific annotations by using the -a (or --annotations) option.
Note that annotations are case sensitive.

```bash
$ bin/rails notes --annotations FIXME RELEASE
app/controllers/admin/users_controller.rb:
  * [101] [RELEASE] We need to look at this before next release
  * [132] [FIXME] high priority for next deploy

lib/school.rb:
  * [ 17] [FIXME]
```

#### 10.1.2. Add Tags

You can add more default tags to search for by using
config.annotations.register_tags:

```ruby
config.annotations.register_tags("DEPRECATEME", "TESTME")
```

```bash
$ bin/rails notes
app/controllers/admin/users_controller.rb:
  * [ 20] [TODO] do A/B testing on this
  * [ 42] [TESTME] this needs more functional tests
  * [132] [DEPRECATEME] ensure this method is deprecated in next release
```

#### 10.1.3. Add Directories

You can add more default directories to search from by using
config.annotations.register_directories:

```ruby
config.annotations.register_directories("spec", "vendor")
```

#### 10.1.4. Add File Extensions

You can add more default file extensions by using
config.annotations.register_extensions:

```ruby
config.annotations.register_extensions("scss", "sass") { |annotation| /\/\/\s*(#{annotation}):?\s*(.*)$/ }
```

### 10.2. bin/rails tmp:

The Rails.root/tmp directory is, like the *nix /tmp directory, the holding
place for temporary files like process id files and cached actions.

The tmp: namespaced commands will help you clear and create the
Rails.root/tmp directory:

```bash
$ bin/rails tmp:cache:clear # clears `tmp/cache`.
$ bin/rails tmp:sockets:clear # clears `tmp/sockets`.
$ bin/rails tmp:screenshots:clear` # clears `tmp/screenshots`.
$ bin/rails tmp:clear # clears all cache, sockets, and screenshot files.
$ bin/rails tmp:create # creates tmp directories for cache, sockets, and pids.
```

### 10.3. bin/rails secret

The bin/rails secret command generates a cryptographically secure random
string for use as a secret key in your Rails application.

```bash
$ bin/rails secret
4d39f92a661b5afea8c201b0b5d797cdd3dcf8ae41a875add6ca51489b1fbbf2852a666660d32c0a09f8df863b71073ccbf7f6534162b0a690c45fd278620a63
```

It can be useful for setting the secret key in your application's
config/credentials.yml.enc file.

### 10.4. bin/rails credentials

The credentials commands provide access to encrypted credentials, so you can
safely store access tokens, database passwords, and the like inside the app
without relying on a bunch of environment variables.

To add values to the encrypted YML file config/credentials.yml.enc, you can
use the credentials:edit command:

```bash
$ bin/rails credentials:edit
```

This opens the decrypted credentials in an editor (set by $VISUAL or
$EDITOR) for editing. When saved, the content is encrypted automatically.

You can also use the :show command to view the decrypted credential file,
which may look something like this (This is from a sample application and not
sensitive data):

```bash
$ bin/rails credentials:show
# aws:
#   access_key_id: 123
#   secret_access_key: 345
active_record_encryption:
  primary_key: 99eYu7ZO0JEwXUcpxmja5PnoRJMaazVZ
  deterministic_key: lGRKzINTrMTDSuuOIr6r5kdq2sH6S6Ii
  key_derivation_salt: aoOUutSgvw788fvO3z0hSgv0Bwrm76P0

# Used as the base secret for all MessageVerifiers in Rails, including the one protecting cookies.
secret_key_base: 6013280bda2fcbdbeda1732859df557a067ac81c423855aedba057f7a9b14161442d9cadfc7e48109c79143c5948de848ab5909ee54d04c34f572153466fc589
```

You can learn about credentials in the Rails Security
Guide.

Check out the detailed description for this command in the output of
bin/rails credentials --help.

## 11. Custom Rake Tasks

You may want to create custom rake tasks in your application, to delete old
records from the database for example. You can do this with the the bin/rails
generate task command. Custom rake tasks have a .rake extension and are
placed in the lib/tasks folder in your Rails application. For example:

```bash
$ bin/rails generate task cool
create  lib/tasks/cool.rake
```

The cool.rake file can contain this:

```ruby
desc "I am short description for a cool task"
task task_name: [:prerequisite_task, :another_task_we_depend_on] do
  # Any valid Ruby code is allowed.
end
```

To pass arguments to your custom rake task:

```ruby
task :task_name, [:arg_1] => [:prerequisite_1, :prerequisite_2] do |task, args|
  argument_1 = args.arg_1
end
```

You can group tasks by placing them in namespaces:

```ruby
namespace :db do
  desc "This task has something to do with the database"
  task :my_db_task do
    # ...
  end
end
```

Invoking rake tasks looks like this:

```bash
$ bin/rails task_name
$ bin/rails "task_name[value1]" # entire argument string should be quoted
$ bin/rails "task_name[value1, value2]" # separate multiple args with a comma
$ bin/rails db:my_db_task
```

If you need to interact with your application models, perform database queries,
and so on, your task can depend on the environment task, which will load your
Rails application.

```ruby
task task_that_requires_app_code: [:environment] do
  puts User.count
end
```

---

# Chapters

Rails generators and application templates are useful tools that can help improve your workflow by automatically creating boilerplate code. In this guide you will learn:

- How to see which generators are available in your application.

- How to create a generator using templates.

- How Rails searches for generators before invoking them.

- How to customize Rails scaffolding by overriding generators and templates.

- How to use fallbacks to avoid overwriting a huge set of generators.

- How to use templates to create/customize Rails applications.

- How to use the Rails Template API to write your own reusable application templates.

## 1. First Contact

When you create an application using the rails command, you are in fact using
a Rails generator. After that, you can get a list of all available generators by
invoking bin/rails generate:

```bash
$ rails new myapp
$ cd myapp
$ bin/rails generate
```

To create a Rails application we use the rails global command which uses
the version of Rails installed via gem install rails. When inside the
directory of your application, we use the bin/rails command which uses the
version of Rails bundled with the application.

You will get a list of all generators that come with Rails. To see a detailed
description of a particular generator, invoke the generator with the --help
option. For example:

```bash
$ bin/rails generate scaffold --help
```

## 2. Creating Your First Generator

Generators are built on top of Thor, which
provides powerful options for parsing and a great API for manipulating files.

Let's build a generator that creates an initializer file named initializer.rb
inside config/initializers. The first step is to create a file at
lib/generators/initializer_generator.rb with the following content:

```ruby
class InitializerGenerator < Rails::Generators::Base
  def create_initializer_file
    create_file "config/initializers/initializer.rb", <<~RUBY
      # Add initialization content here
    RUBY
  end
end
```

Our new generator is quite simple: it inherits from Rails::Generators::Base
and has one method definition. When a generator is invoked, each public method
in the generator is executed sequentially in the order that it is defined. Our
method invokes create_file, which will create a file at the given
destination with the given content.

To invoke our new generator, we run:

```bash
$ bin/rails generate initializer
```

Before we go on, let's see the description of our new generator:

```bash
$ bin/rails generate initializer --help
```

Rails is usually able to derive a good description if a generator is namespaced,
such as ActiveRecord::Generators::ModelGenerator, but not in this case. We can
solve this problem in two ways. The first way to add a description is by calling
desc inside our generator:

```ruby
class InitializerGenerator < Rails::Generators::Base
  desc "This generator creates an initializer file at config/initializers"
  def create_initializer_file
    create_file "config/initializers/initializer.rb", <<~RUBY
      # Add initialization content here
    RUBY
  end
end
```

Now we can see the new description by invoking --help on the new generator.

The second way to add a description is by creating a file named USAGE in the
same directory as our generator. We are going to do that in the next step.

## 3. Creating Generators with Generators

Generators themselves have a generator. Let's remove our InitializerGenerator
and use bin/rails generate generator to generate a new one:

```bash
$ rm lib/generators/initializer_generator.rb

$ bin/rails generate generator initializer
      create  lib/generators/initializer
      create  lib/generators/initializer/initializer_generator.rb
      create  lib/generators/initializer/USAGE
      create  lib/generators/initializer/templates
      invoke  test_unit
      create    test/lib/generators/initializer_generator_test.rb
```

This is the generator just created:

```ruby
class InitializerGenerator < Rails::Generators::NamedBase
  source_root File.expand_path("templates", __dir__)
end
```

First, notice that the generator inherits from Rails::Generators::NamedBase
instead of Rails::Generators::Base. This means that our generator expects at
least one argument, which will be the name of the initializer and will be
available to our code via name.

We can see that by checking the description of the new generator:

```bash
$ bin/rails generate initializer --help
Usage:
  bin/rails generate initializer NAME [options]
```

Also, notice that the generator has a class method called source_root.
This method points to the location of our templates, if any. By default it
points to the lib/generators/initializer/templates directory that was just
created.

In order to understand how generator templates work, let's create the file
lib/generators/initializer/templates/initializer.rb with the following
content:

```ruby
# Add initialization content here
```

And let's change the generator to copy this template when invoked:

```ruby
class InitializerGenerator < Rails::Generators::NamedBase
  source_root File.expand_path("templates", __dir__)

  def copy_initializer_file
    copy_file "initializer.rb", "config/initializers/#{file_name}.rb"
  end
end
```

Now let's run our generator:

```bash
$ bin/rails generate initializer core_extensions
      create  config/initializers/core_extensions.rb

$ cat config/initializers/core_extensions.rb
# Add initialization content here
```

We see that copy_file created config/initializers/core_extensions.rb
with the contents of our template. (The file_name method used in the
destination path is inherited from Rails::Generators::NamedBase.)

## 4. Generator Command Line Options

Generators can support command line options using class_option. For
example:

```ruby
class InitializerGenerator < Rails::Generators::NamedBase
  class_option :scope, type: :string, default: "app"
end
```

Now our generator can be invoked with a --scope option:

```bash
$ bin/rails generate initializer theme --scope dashboard
```

Option values are accessible in generator methods via options:

```ruby
def copy_initializer_file
  @scope = options["scope"]
end
```

## 5. Generator Resolution

When resolving a generator's name, Rails looks for the generator using multiple
file names. For example, when you run bin/rails generate initializer core_extensions,
Rails tries to load each of the following files, in order, until one is found:

- rails/generators/initializer/initializer_generator.rb

- generators/initializer/initializer_generator.rb

- rails/generators/initializer_generator.rb

- generators/initializer_generator.rb

If none of these are found, an error will be raised.

We put our generator in the application's lib/ directory because that
directory is in $LOAD_PATH, thus allowing Rails to find and load the file.

## 6. Overriding Rails Generator Templates

Rails will also look in multiple places when resolving generator template files.
One of those places is the application's lib/templates/ directory. This
behavior allows us to override the templates used by Rails' built-in generators.
For example, we could override the scaffold controller template or the
scaffold view templates.

To see this in action, let's create a lib/templates/erb/scaffold/index.html.erb.tt
file with the following contents:

```ruby
<%%= @<%= plural_table_name %>.count %> <%= human_name.pluralize %>
```

Note that the template is an ERB template that renders another ERB template.
So any <% that should appear in the resulting template must be escaped as
<%% in the generator template.

Now let's run Rails' built-in scaffold generator:

```bash
$ bin/rails generate scaffold Post title:string
      ...
      create      app/views/posts/index.html.erb
      ...
```

The contents of app/views/posts/index.html.erb is:

```ruby
<%= @posts.count %> Posts
```

## 7. Overriding Rails Generators

Rails' built-in generators can be configured via config.generators,
including overriding some generators entirely.

First, let's take a closer look at how the scaffold generator works.

```bash
$ bin/rails generate scaffold User name:string
      invoke  active_record
      create    db/migrate/20230518000000_create_users.rb
      create    app/models/user.rb
      invoke    test_unit
      create      test/models/user_test.rb
      create      test/fixtures/users.yml
      invoke  resource_route
       route    resources :users
      invoke  scaffold_controller
      create    app/controllers/users_controller.rb
      invoke    erb
      create      app/views/users
      create      app/views/users/index.html.erb
      create      app/views/users/edit.html.erb
      create      app/views/users/show.html.erb
      create      app/views/users/new.html.erb
      create      app/views/users/_form.html.erb
      create      app/views/users/_user.html.erb
      invoke    resource_route
      invoke    test_unit
      create      test/controllers/users_controller_test.rb
      create      test/system/users_test.rb
      invoke    helper
      create      app/helpers/users_helper.rb
      invoke      test_unit
      invoke    jbuilder
      create      app/views/users/index.json.jbuilder
      create      app/views/users/show.json.jbuilder
```

From the output, we can see that the scaffold generator invokes other
generators, such as the scaffold_controller generator. And some of those
generators invoke other generators too. In particular, the scaffold_controller
generator invokes several other generators, including the helper generator.

Let's override the built-in helper generator with a new generator. We'll name
the generator my_helper:

```bash
$ bin/rails generate generator rails/my_helper
      create  lib/generators/rails/my_helper
      create  lib/generators/rails/my_helper/my_helper_generator.rb
      create  lib/generators/rails/my_helper/USAGE
      create  lib/generators/rails/my_helper/templates
      invoke  test_unit
      create    test/lib/generators/rails/my_helper_generator_test.rb
```

And in lib/generators/rails/my_helper/my_helper_generator.rb we'll define
the generator as:

```ruby
class Rails::MyHelperGenerator < Rails::Generators::NamedBase
  def create_helper_file
    create_file "app/helpers/#{file_name}_helper.rb", <<~RUBY
      module #{class_name}Helper
        # I'm helping!
      end
    RUBY
  end
end
```

Finally, we need to tell Rails to use the my_helper generator instead of the
built-in helper generator. For that we use config.generators. In
config/application.rb, let's add:

```ruby
config.generators do |g|
  g.helper :my_helper
end
```

Now if we run the scaffold generator again, we see the my_helper generator in
action:

```bash
$ bin/rails generate scaffold Article body:text
      ...
      invoke  scaffold_controller
      ...
      invoke    my_helper
      create      app/helpers/articles_helper.rb
      ...
```

You may notice that the output for the built-in helper generator
includes "invoke test_unit", whereas the output for my_helper does not.
Although the helper generator does not generate tests by default, it does
provide a hook to do so using hook_for. We can do the same by including
hook_for :test_framework, as: :helper in the MyHelperGenerator class. See
the hook_for documentation for more information.

### 7.1. Generators Fallbacks

Another way to override specific generators is by using fallbacks. A fallback
allows a generator namespace to delegate to another generator namespace.

For example, let's say we want to override the test_unit:model generator with
our own my_test_unit:model generator, but we don't want to replace all of the
other test_unit:* generators such as test_unit:controller.

First, we create the my_test_unit:model generator in
lib/generators/my_test_unit/model/model_generator.rb:

```ruby
module MyTestUnit
  class ModelGenerator < Rails::Generators::NamedBase
    source_root File.expand_path("templates", __dir__)

    def do_different_stuff
      say "Doing different stuff..."
    end
  end
end
```

Next, we use config.generators to configure the test_framework generator as
my_test_unit, but we also configure a fallback such that any missing
my_test_unit:* generators resolve to test_unit:*:

```ruby
config.generators do |g|
  g.test_framework :my_test_unit, fixture: false
  g.fallbacks[:my_test_unit] = :test_unit
end
```

Now when we run the scaffold generator, we see that my_test_unit has replaced
test_unit, but only the model tests have been affected:

```bash
$ bin/rails generate scaffold Comment body:text
      invoke  active_record
      create    db/migrate/20230518000000_create_comments.rb
      create    app/models/comment.rb
      invoke    my_test_unit
    Doing different stuff...
      invoke  resource_route
       route    resources :comments
      invoke  scaffold_controller
      create    app/controllers/comments_controller.rb
      invoke    erb
      create      app/views/comments
      create      app/views/comments/index.html.erb
      create      app/views/comments/edit.html.erb
      create      app/views/comments/show.html.erb
      create      app/views/comments/new.html.erb
      create      app/views/comments/_form.html.erb
      create      app/views/comments/_comment.html.erb
      invoke    resource_route
      invoke    my_test_unit
      create      test/controllers/comments_controller_test.rb
      create      test/system/comments_test.rb
      invoke    helper
      create      app/helpers/comments_helper.rb
      invoke      my_test_unit
      invoke    jbuilder
      create      app/views/comments/index.json.jbuilder
      create      app/views/comments/show.json.jbuilder
```

## 8. Application Templates

Application templates are a little different from generators. While generators
add files to an existing Rails application (models, views, etc.), templates are
used to automate the setup of a new Rails application. Templates are Ruby
scripts (typically named template.rb) that customize new Rails applications
right after they are generated.

Let's see how to use a template while creating a new Rails application.

### 8.1. Creating and Using Templates

Let's start with a sample template Ruby script. The below template adds Devise
to the Gemfile after asking the user and also allows the user to name the
Devise user model. After bundle install has been run, the template runs the
Devise generators and also runs migrations. Finally, the template does git add and git commit.

```ruby
# template.rb
if yes?("Would you like to install Devise?")
  gem "devise"
  devise_model = ask("What would you like the user model to be called?", default: "User")
end

after_bundle do
  if devise_model
    generate "devise:install"
    generate "devise", devise_model
    rails_command "db:migrate"
  end

  git add: ".", commit: %(-m 'Initial commit')
end
```

To apply this template while creating a new Rails application, you need to
provide the location of the template using the -m option:

```bash
$ rails new blog -m ~/template.rb
```

The above will create a new Rails application called blog that has Devise gem configured.

You can also apply templates to an existing Rails application by using
app:template command. The location of the template needs to be passed in via
the LOCATION environment variable:

```bash
$ bin/rails app:template LOCATION=~/template.rb
```

Templates don't have to be stored locally, you can also specify a URL instead
of a path:

```bash
$ rails new blog -m https://example.com/template.rb
$ bin/rails app:template LOCATION=https://example.com/template.rb
```

Caution should be taken when executing remote scripts from third parties. Since the template is a plain Ruby script, it can easily contain code that compromises your local machine (such as download a virus, delete files or upload your private files to a server).

The above template.rb file uses helper methods such as after_bundle and
rails_command and also adds user interactivity with methods like yes?. All
of these methods are part of the Rails Template
API. The
following sections shows how to use more of these methods with examples.

## 9. Rails Generators API

Generators and the template Ruby scripts have access to several helper methods
using a DSL (Domain
Specific Language). These methods are part of the Rails Generators API and you
can find more details at Thor::Actions and
Rails::Generators::Actions API documentation.

Here's another example of a typical Rails template that scaffolds a model, runs
migrations, and commits the changes with git:

```ruby
# template.rb
generate(:scaffold, "person name:string")
route "root to: 'people#index'"
rails_command("db:migrate")

after_bundle do
  git :init
  git add: "."
  git commit: %Q{ -m 'Initial commit' }
end
```

All code snippets in the examples below can be used in a template
file, such as the template.rb file above.

### 9.1. add_source

The add_source method adds the given source to the generated application's Gemfile.

```ruby
add_source "https://rubygems.org"
```

If a block is given, gem entries in the block are wrapped into the source group.
For example, if you need to source a gem from "http://gems.github.com":

```ruby
add_source "http://gems.github.com/" do
  gem "rspec-rails"
end
```

### 9.2. after_bundle

The after_bundle method registers a callback to be executed after the gems
are bundled. For example, it would make sense to run the "install" command for
tailwindcss-rails and devise only after those gems are bundled:

```ruby
# Install gems
after_bundle do
  # Install TailwindCSS
  rails_command "tailwindcss:install"

  # Install Devise
  generate "devise:install"
end
```

The callbacks get executed even if --skip-bundle has been passed.

### 9.3. environment

The environment method adds a line inside the Application class for
config/application.rb. If options[:env] is specified, the line is appended
to the corresponding file in config/environments.

```ruby
environment 'config.action_mailer.default_url_options = {host: "http://yourwebsite.example.com"}', env: "production"
```

The above will add the config line to config/environments/production.rb.

### 9.4. gem

The gem helper adds an entry for the given gem to the generated application's
Gemfile.

For example, if your application depends on the gems devise and
tailwindcss-rails:

```ruby
gem "devise"
gem "tailwindcss-rails"
```

Note that this method only adds the gem to the Gemfile, it does not install
the gem.

You can also specify an exact version:

```ruby
gem "devise", "~> 4.9.4"
```

And you can also add comments that will be added to the Gemfile:

```ruby
gem "devise", comment: "Add devise for authentication."
```

### 9.5. gem_group

The gem_group helper wraps gem entries inside a group. For example, to load rspec-rails
only in the development and test groups:

```ruby
gem_group :development, :test do
  gem "rspec-rails"
end
```

### 9.6. generate

You can even call a generator from inside a template.rb with the
generate method. The following runs the scaffold rails generator with
the given arguments:

```ruby
generate(:scaffold, "person", "name:string", "address:text", "age:number")
```

### 9.7. git

Rails templates let you run any git command with the git helper:

```ruby
git :init
git add: "."
git commit: "-a -m 'Initial commit'"
```

### 9.8. initializer, vendor, lib, file

The initializer helper method adds an initializer to the generated
application's config/initializers directory.

After adding the below to the template.rb file, you can use Object#not_nil?
and Object#not_blank? in your application:

```ruby
initializer "not_methods.rb", <<-CODE
  class Object
    def not_nil?
      !nil?
    end

    def not_blank?
      !blank?
    end
  end
CODE
```

Similarly, the lib method creates a file in the lib/ directory and
vendor method creates a file in the vendor/ directory.

There is also a file method (which is an alias for create_file), which
accepts a relative path from Rails.root and creates all the directories and
files needed:

```ruby
file "app/components/foo.rb", <<-CODE
  class Foo
  end
CODE
```

The above will create the app/components directory and put foo.rb in there.

### 9.9. rakefile

The rakefile method creates a new Rake file under lib/tasks with the
given tasks:

```ruby
rakefile("bootstrap.rake") do
  <<-TASK
    namespace :boot do
      task :strap do
        puts "I like boots!"
      end
    end
  TASK
end
```

The above creates lib/tasks/bootstrap.rake with a boot:strap rake task.

### 9.10. run

The run method executes an arbitrary command. Let's say you want to remove
the README.rdoc file:

```ruby
run "rm README.rdoc"
```

### 9.11. rails_command

You can run the Rails commands in the generated application with the
rails_command helper. Let's say you want to migrate the database at some
point in the template ruby script:

```ruby
rails_command "db:migrate"
```

Commands can be run with a different Rails environment:

```ruby
rails_command "db:migrate", env: "production"
```

You can also run commands that should abort application generation if they fail:

```ruby
rails_command "db:migrate", abort_on_failure: true
```

### 9.12. route

The route method adds an entry to the config/routes.rb file. To make
PeopleController#index the default page for the application, we can add:

```ruby
route "root to: 'person#index'"
```

There are also many helper methods that can manipulate the local file system,
such as copy_file, create_file, insert_into_file, and
inside. You can see the Thor API
documentation for details.
Here is an example of one such method:

### 9.13. inside

This inside method enables you to run a command from a given directory.
For example, if you have a copy of edge rails that you wish to symlink from your
new apps, you can do this:

```ruby
inside("vendor") do
  run "ln -s ~/my-forks/rails rails"
end
```

There are also methods that allow you to interact with the user from the Ruby template, such as ask, yes, and no. You can learn about all user interactivity methods in the Thor Shell documentation. Let's see examples of using ask, yes? and no?:

### 9.14. ask

The ask methods allows you to get feedback from the user and use it in your
templates. Let's say you want your user to name the new shiny library you're
adding:

```ruby
lib_name = ask("What do you want to call the shiny library?")
lib_name << ".rb" unless lib_name.index(".rb")

lib lib_name, <<-CODE
  class Shiny
  end
CODE
```

### 9.15. yes? or no?

These methods let you ask questions from templates and decide the flow based on
the user's answer. Let's say you want to prompt the user to run migrations:

```ruby
rails_command("db:migrate") if yes?("Run database migrations?")
# no? questions acts the opposite of yes?
```

## 10. Testing Generators

Rails provides testing helper methods via
Rails::Generators::Testing::Behavior, such as:

- run_generator

If running tests against generators you will need to set
RAILS_LOG_TO_STDOUT=true in order for debugging tools to work.

```
RAILS_LOG_TO_STDOUT=true ./bin/test test/generators/actions_test.rb
```

In addition to those, Rails also provides additional assertions via
Rails::Generators::Testing::Assertions.
