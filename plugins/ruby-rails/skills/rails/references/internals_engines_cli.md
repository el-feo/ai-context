# Engines, Rack & Command Line

This guide covers Rails integration with Rack and interfacing with other Rack components.

After reading this guide, you will know:

- How to use Rack Middlewares in your Rails applications.

- Action Pack's internal Middleware stack.

- How to define a custom Middleware stack.

This guide assumes a working knowledge of Rack protocol and Rack concepts such as middlewares, URL maps, and Rack::Builder.

## Table of Contents

- 1. Introduction to Rack
- 2. Rails on Rack
- 3. Action Dispatcher Middleware Stack
- 4. Resources
- 1. What are Engines?
- 2. Generating an Engine
- 3. Providing Engine Functionality
- 4. Hooking Into an Application
- 5. Testing an Engine
- 6. Improving Engine Functionality
- 1. Overview
- 2. Creating a New Rails Application
- 3. Starting a Rails Application Server
- 4. Generating Code
- 5. Interacting with a Rails Application
- 6. Inspecting an Application
- 7. Managing Assets
- 8. Managing the Database
- 9. Running Tests
- 10. Other Useful Commands
- 11. Custom Rake Tasks
- 1. First Contact
- 2. Creating Your First Generator
- 3. Creating Generators with Generators
- 4. Generator Command Line Options
- 5. Generator Resolution
- 6. Overriding Rails Generator Templates
- 7. Overriding Rails Generators
- 8. Application Templates
- 9. Rails Generators API
- 10. Testing Generators

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

