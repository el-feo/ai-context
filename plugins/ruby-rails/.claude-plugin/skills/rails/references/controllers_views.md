# Chapters

In this guide, you will learn how controllers work and how they fit into the request cycle in your application.

After reading this guide, you will know how to:

- Follow the flow of a request through a controller.

- Access parameters passed to your controller.

- Use Strong Parameters and permit values.

- Store data in the cookie, the session, and the flash.

- Work with action callbacks to execute code during request processing.

- Use the Request and Response Objects.

## 1. Introduction

Action Controller is the C in the Model View Controller
(MVC)
pattern. After the router has matched a controller to an
incoming request, the controller is responsible for processing the request and
generating the appropriate output.

For most conventional
RESTful
applications, the controller will receive the request, fetch or save data from a
model, and use a view to create HTML output.

You can imagine that a controller sits between models and views. The controller
makes model data available to the view, so that the view can display that data
to the user. The controller also receives user input from the view and saves or
updates model data accordingly.

## 2. Creating a Controller

A controller is a Ruby class which inherits from ApplicationController and has
methods just like any other class. Once an incoming request is matched to a
controller by the router, Rails creates an instance of that controller class and
calls the method with the same name as the action.

```ruby
class ClientsController < ApplicationController
  def new
  end
end
```

Given the above ClientsController, if a user goes to /clients/new in your
application to add a new client, Rails will create an instance of
ClientsController and call its new method. If the new method is empty, Rails
will automatically render the new.html.erb view by default.

The new method is an instance method here, called on an instance of ClientsController. This should not be confused with the new class method (i.e., ClientsController.new).

In the new method, the controller would typically create an instance of the
Client model, and make it available as an instance variable called @client
in the view:

```ruby
def new
  @client = Client.new
end
```

All controllers inherit from ApplicationController, which in turn
inherits from
ActionController::Base.
For API only applications ApplicationController inherits from
ActionController::API.

### 2.1. Controller Naming Convention

Rails favors making the resource in the controller's name plural. For example,
ClientsController is preferred over ClientController and
SiteAdminsController over SiteAdminController or SitesAdminsController.
However, the plural names are not strictly required (e.g.
ApplicationController).

Following this naming convention will allow you to use the default route
generators (e.g. resources) without
needing to qualify each with options such as
:controller. The convention
also makes named route helpers consistent throughout your application.

The controller naming convention is different from models. While plural names
are preferred for controller names, the singular form is preferred for model
names (e.g. Account vs.
Accounts).

Controller actions should be public, as only public methods are callable as
actions. It is also best practice to lower the visibility of helper methods
(with private or protected) which are not intended to be actions.

Some method names are reserved by Action Controller. Accidentally
redefining them could result in SystemStackError. If you limit your
controllers to only RESTful Resource Routing actions you should not need to
worry about this.

If you must use a reserved method as an action name, one workaround is to
use a custom route to map the reserved method name to your non-reserved action
method.

## 3. Parameters

Data sent by the incoming request is available in your controller in the
params hash. There are two types of parameter data:

- Query string parameters which are sent as part of the URL (for example, after
the ? in <http://example.com/accounts?filter=free>).

- POST parameters which are submitted from an HTML form.

Rails does not make a distinction between query string parameters and POST
parameters; both are available in the params hash in your controller. For
example:

```ruby
class ClientsController < ApplicationController
  # This action receives query string parameters from an HTTP GET request
  # at the URL "/clients?status=activated"
  def index
    if params[:status] == "activated"
      @clients = Client.activated
    else
      @clients = Client.inactivated
    end
  end

  # This action receives parameters from a POST request to "/clients" URL with  form data in the request body.
  def create
    @client = Client.new(params[:client])
    if @client.save
      redirect_to @client
    else
      render "new"
    end
  end
end
```

The params hash is not a plain old Ruby Hash; instead, it is an
ActionController::Parameters object. It does not inherit from Hash, but it behaves mostly like Hash.
It provides methods for filtering params and, unlike a Hash, keys :foo and "foo" are considered to be the same.

### 3.1. Hash and Array Parameters

The params hash is not limited to one-dimensional keys and values. It can
contain nested arrays and hashes. To send an array of values, append an empty
pair of square brackets [] to the key name:

```
GET /users?ids[]=1&ids[]=2&ids[]=3
```

The actual URL in this example will be encoded as
/users?ids%5b%5d=1&ids%5b%5d=2&ids%5b%5d=3 as the [ and ] characters are
not allowed in URLs. Most of the time you don't have to worry about this because
the browser will encode it for you, and Rails will decode it automatically, but
if you ever find yourself having to send those requests to the server manually
you should keep this in mind.

The value of params[:ids] will be the array ["1", "2", "3"]. Note that
parameter values are always strings; Rails does not attempt to guess or cast the
type.

Values such as [nil] or [nil, nil, ...] in params are replaced with
[] for security reasons by default. See Security
Guide for more information.

To send a hash, you include the key name inside the brackets:

```html
<form accept-charset="UTF-8" action="/users" method="post">
  <input type="text" name="user[name]" value="Acme" />
  <input type="text" name="user[phone]" value="12345" />
  <input type="text" name="user[address][postcode]" value="12345" />
  <input type="text" name="user[address][city]" value="Carrot City" />
</form>
```

When this form is submitted, the value of params[:user] will be { "name" =>
"Acme", "phone" => "12345", "address" => { "postcode" => "12345", "city" =>
"Carrot City" } }. Note the nested hash in params[:user][:address].

The params object acts like a Hash, but lets you use symbols and strings
interchangeably as keys.

### 3.2. Composite Key Parameters

Composite key parameters contain
multiple values in one parameter separated by a delimiter (e.g., an underscore).
Therefore, you will need to extract each value so that you can pass them to
Active Record. You can use the extract_value  method to do that.

For example, given the following controller:

```ruby
class BooksController < ApplicationController
  def show
    # Extract the composite ID value from URL parameters.
    id = params.extract_value(:id)
    @book = Book.find(id)
  end
end
```

And this route:

```ruby
get "/books/:id", to: "books#show"
```

When a user requests the URL /books/4_2, the controller will extract the
composite key value ["4", "2"] and pass it to Book.find. The extract_value
method may be used to extract arrays out of any delimited parameters.

### 3.3. JSON Parameters

If your application exposes an API, you will likely accept parameters in JSON
format. If the content-type header of your request is set to
application/json, Rails will automatically load your parameters into the
params hash, which you can access as you would normally.

So for example, if you are sending this JSON content:

```
{ "user": { "name": "acme", "address": "123 Carrot Street" } }
```

Your controller will receive:

```ruby
{ "user" => { "name" => "acme", "address" => "123 Carrot Street" } }
```

#### 3.3.1. Configuring Wrap Parameters

You can use Wrap Parameters, which automatically add the controller name to
JSON parameters. For example, you can send the below JSON without a root :user
key prefix:

```
{ "name": "acme", "address": "123 Carrot Street" }
```

Assuming that you're sending the above data to the UsersController, the JSON
will be wrapped within the :user key like this:

```ruby
{ name: "acme", address: "123 Carrot Street", user: { name: "acme", address: "123 Carrot Street" } }
```

Wrap Parameters adds a clone of the parameters to the hash within a key
that is the same as the controller name. As a result, both the original version
of the parameters and the "wrapped" version of the parameters will exist in the
params hash.

This feature clones and wraps parameters with a key chosen based on your
controller's name. It is configured to true by default. If you do not want to
wrap parameters you can
configure
it to false.

```ruby
config.action_controller.wrap_parameters_by_default = false
```

You can also customize the name of the key or specific parameters you want to
wrap, see the API
documentation
for more.

### 3.4. Routing Parameters

Parameters specified as part of a route declaration in the routes.rb file are
also made available in the params hash. For example, we can add a route that
captures the :status parameter for a client:

```ruby
get "/clients/:status", to: "clients#index", foo: "bar"
```

When a user navigates to /clients/active URL, params[:status] will be set to
"active". When this route is used, params[:foo] will also be set to "bar", as
if it were passed in the query string.

Any other parameters defined by the route declaration, such as :id, will also
be available.

In the above example, your controller will also receive params[:action]
as "index" and params[:controller] as "clients". The params hash will always
contain the :controller and :action keys, but it's recommended to use the
methods controller_name and action_name instead to access these
values.

### 3.5. The default_url_options Method

You can set global default parameters for url_for
by defining a method called default_url_options in your controller. For
example:

```ruby
class ApplicationController < ActionController::Base
  def default_url_options
    { locale: I18n.locale }
  end
end
```

The specified defaults will be used as a starting point when generating URLs.
They can be overridden by the options passed to url_for or any path helper
such as posts_path. For example, by setting locale: I18n.locale, Rails will
automatically add the locale to every URL:

```ruby
posts_path # => "/posts?locale=en"
```

You can still override this default if needed:

```ruby
posts_path(locale: :fr) # => "/posts?locale=fr"
```

Under the hood, posts_path is a shorthand for calling url_for with the
appropriate parameters.

If you define default_url_options in ApplicationController, as in the
example above, these defaults will be used for all URL generation. The method
can also be defined in a specific controller, in which case it only applies to
URLs generated for that controller.

In a given request, the method is not actually called for every single generated
URL. For performance reasons the returned hash is cached per request.

## 4. Strong Parameters

With Action Controller Strong
Parameters,
parameters cannot be used in Active Model mass assignments until they have been
explicitly permitted. This means you will need to decide which attributes to
permit for mass update and declare them in the controller. This is a security
practice to prevent users from accidentally updating sensitive model attributes.

In addition, parameters can be marked as required and the request will result in
a 400 Bad Request being returned if not all required parameters are passed in.

```ruby
class PeopleController < ActionController::Base
  # This will raise an ActiveModel::ForbiddenAttributesError
  # because it's using mass assignment without an explicit permit.
  def create
    Person.create(params[:person])
  end

  # This will work as we are using `person_params` helper method, which has the
  # call to `expect` to allow mass assignment.
  def update
    person = Person.find(params[:id])
    person.update!(person_params)
    redirect_to person
  end

  private
    # Using a private method to encapsulate the permitted parameters is a good
    # pattern. You can use the same list for both create and update.
    def person_params
      params.expect(person: [:name, :age])
    end
end
```

### 4.1. Permitting Values

#### 4.1.1. expect

The expect method provides a concise and safe way to require and permit
parameters.

```ruby
id = params.expect(:id)
```

The above expect will always return a scalar value and not an array or hash.
Another example is form params, you can use expect to ensure that the root key
is present and the attributes are permitted.

```ruby
user_params = params.expect(user: [:username, :password])
user_params.has_key?(:username) # => true
```

In the above example, if the :user key is not a nested hash with the specified
keys, expect will raise an error and return a 400 Bad Request response.

To require and permit an entire hash of parameters, expect can be used in
this way.

```ruby
params.expect(log_entry: {})
```

This marks the :log_entry parameters hash and any sub-hash of it as permitted
and does not check for permitted scalars, anything is accepted.

Extreme care should be taken when calling expect with an empty
hash, as it will allow all current and future model attributes to be
mass-assigned.

#### 4.1.2. permit

Calling permit allows the specified key in params (:id or :admin
below) for inclusion in mass assignment (e.g. via create or update):

```
params = ActionController::Parameters.new(id: 1, admin: "true")
=> #<ActionController::Parameters {"id"=>1, "admin"=>"true"} permitted: false>
params.permit(:id)
=> #<ActionController::Parameters {"id"=>1} permitted: true>
params.permit(:id, :admin)
=> #<ActionController::Parameters {"id"=>1, "admin"=>"true"} permitted: true>
```

For the permitted key :id, its value also needs to be one of these permitted
scalar values: String, Symbol, NilClass, Numeric, TrueClass,
FalseClass, Date, Time, DateTime, StringIO, IO,
ActionDispatch::Http::UploadedFile, and Rack::Test::UploadedFile.

If you have not called permit on the key, it will be filtered out. Arrays,
hashes, or any other objects are not injected by default.

To include a value in params that's an array of one of the permitted scalar
values, you can map the key to an empty array like this:

```
params = ActionController::Parameters.new(tags: ["rails", "parameters"])
=> #<ActionController::Parameters {"tags"=>["rails", "parameters"]} permitted: false>
params.permit(tags: [])
=> #<ActionController::Parameters {"tags"=>["rails", "parameters"]} permitted: true>
```

To include hash values, you can map to an empty hash:

```
params = ActionController::Parameters.new(options: { darkmode: true })
=> #<ActionController::Parameters {"options"=>{"darkmode"=>true}} permitted: false>
params.permit(options: {})
=> #<ActionController::Parameters {"options"=>#<ActionController::Parameters {"darkmode"=>true} permitted: true>} permitted: true>
```

The above permit call ensures that values in options are permitted scalars
and filters out anything else.

The permit with an empty hash is convenient since sometimes it is not
possible or convenient to declare each valid key of a hash parameter or its
internal structure. But note that the above permit with an empty hash opens
the door to arbitrary input.

#### 4.1.3. permit

There is also permit! (with an !) which permits an entire hash of
parameters without checking the values.

```
params = ActionController::Parameters.new(id: 1, admin: "true")
=> #<ActionController::Parameters {"id"=>1, "admin"=>"true"} permitted: false>
params.permit!
=> #<ActionController::Parameters {"id"=>1, "admin"=>"true"} permitted: true>
```

Extreme care should be taken when using permit!, as it will allow all
current and future model attributes to be mass-assigned.

### 4.2. Nested Parameters

You can also use expect (or permit) on nested parameters, like:

```ruby
# Given the example expected params:
params = ActionController::Parameters.new(
  name: "Martin",
  emails: ["me@example.com"],
  friends: [
    { name: "André", family: { name: "RubyGems" }, hobbies: ["keyboards", "card games"] },
    { name: "Kewe", family: { name: "Baroness" }, hobbies: ["video games"] },
  ]
)
# the following expect will ensure the params are permitted
name, emails, friends = params.expect(
  :name,                 # permitted scalar
  emails: [],            # array of permitted scalars
  friends: [[            # array of permitted Parameter hashes
    :name,               # permitted scalar
    family: [:name],     # family: { name: "permitted scalar" }
    hobbies: []          # array of permitted scalars
  ]]
)
```

This declaration permits the name, emails, and friends attributes and
returns them each. It is expected that emails will be an array of permitted
scalar values, and that friends will be an array of resources (note the new
double array syntax to explicitly require an array) with specific attributes.
These attributes should have a name attribute (any permitted scalar values allowed), a
hobbies attribute as an array of permitted scalar values, and a family
attribute which is restricted to a hash with only a name key and any permitted
scalar value.

### 4.3. Examples

Here are some examples of how to use permit for different use cases.

Example 1: You may want to use the permitted attributes in your new action.
This raises the problem that you can't use require on the root key
because, normally, it does not exist when calling new:

```ruby
# using `fetch` you can supply a default and use
# the Strong Parameters API from there.
params.fetch(:blog, {}).permit(:title, :author)
```

Example 2: The model class method accepts_nested_attributes_for allows you to
update and destroy associated records. This is based on the id and_destroy
parameters:

```ruby
# permit :id and :_destroy
params.expect(author: [ :name, books_attributes: [[ :title, :id, :_destroy ]] ])
```

Example 3: Hashes with integer keys are treated differently, and you can declare
the attributes as if they were direct children. You get these kinds of
parameters when you use accepts_nested_attributes_for in combination with a
has_many association:

```ruby
# To permit the following data:
# {"book" => {"title" => "Some Book",
#             "chapters_attributes" => { "1" => {"title" => "First Chapter"},
#                                        "2" => {"title" => "Second Chapter"}}}}

params.expect(book: [ :title, chapters_attributes: [[ :title ]] ])
```

Example 4: Imagine a scenario where you have parameters representing a product
name, and a hash of arbitrary data associated with that product, and you want to
permit the product name attribute and also the whole data hash:

```ruby
def product_params
  params.expect(product: [ :name, data: {} ])
end
```

## 5. Cookies

The concept of a cookie is not specific to Rails. A
cookie (also known as an HTTP
cookie or a web cookie) is a small piece of data from the server that is saved
in the user's browser. The browser may store cookies, create new cookies, modify
existing ones, and send them back to the server with later requests. Cookies
persist data across web requests and therefore enable web applications to
remember user preferences.

Rails provides an easy way to access cookies via the cookies method, which
works like a hash:

```ruby
class CommentsController < ApplicationController
  def new
    # Auto-fill the commenter's name if it has been stored in a cookie
    @comment = Comment.new(author: cookies[:commenter_name])
  end

  def create
    @comment = Comment.new(comment_params)
    if @comment.save
      if params[:remember_name]
        # Save the commenter's name in a cookie.
        cookies[:commenter_name] = @comment.author
      else
        # Delete cookie for the commenter's name, if any.
        cookies.delete(:commenter_name)
      end
      redirect_to @comment.article
    else
      render action: "new"
    end
  end
end
```

To delete a cookie, you need to use cookies.delete(:key). Setting the
key to a nil value does not delete the cookie.

When passed a scalar value, the cookie will be deleted when the user closes their browser.
If you want the cookie to expire at a specific time, pass a hash with the :expires option when setting the cookie.
For example, to set a cookie that expires in 1 hour:

```ruby
cookies[:login] = { value: "XJ-122", expires: 1.hour }
```

If you want to create cookies that never expire use the permanent cookie jar.
This sets the assigned cookies to have an expiration date 20 years from now.

```ruby
cookies.permanent[:locale] = "fr"
```

### 5.1. Encrypted and Signed Cookies

Since cookies are stored on the client browser, they can be susceptible to
tampering and are not considered secure for storing sensitive data. Rails
provides a signed cookie jar and an encrypted cookie jar for storing sensitive
data. The signed cookie jar appends a cryptographic signature on the cookie
values to protect their integrity. The encrypted cookie jar encrypts the values
in addition to signing them, so that they cannot be read by the user.

Refer to the API
documentation
for more details.

```ruby
class CookiesController < ApplicationController
  def set_cookie
    cookies.signed[:user_id] = current_user.id
    cookies.encrypted[:expiration_date] = Date.tomorrow # => Thu, 20 Mar 2024
    redirect_to action: "read_cookie"
  end

  def read_cookie
    cookies.encrypted[:expiration_date] # => "2024-03-20"
  end
end
```

These special cookie jars use a serializer to serialize the cookie values into
strings and deserialize them into Ruby objects when read back. You can specify
which serializer to use via config.action_dispatch.cookies_serializer. The
default serializer for new applications is :json.

Be aware that JSON has limited support serializing Ruby objects such as
Date, Time, and Symbol. These will be serialized and deserialized into
Strings.

If you need to store these or more complex objects, you may need to manually
convert their values when reading them in subsequent requests.

If you use the cookie session store, the above applies to the session and
flash hash as well.

## 6. Session

While cookies are stored client-side, session data is stored server-side (in
memory, a database, or a cache), and the duration is usually temporary and tied
to the user's session (e.g. until they close the browser). An example use case
for session is storing sensitive data like user authentication.

In a Rails application, the session is available in the controller and the view.

### 6.1. Working with the Session

You can use the session instance method to access the session in your
controllers. Session values are stored as key/value pairs like a hash:

```ruby
class ApplicationController < ActionController::Base
  private
    # Look up the key `:current_user_id` in the session and use it to
    # find the current `User`. This is a common way to handle user login in
    # a Rails application; logging in sets the session value and
    # logging out removes it.
    def current_user
      @current_user ||= User.find_by(id: session[:current_user_id]) if session[:current_user_id]
    end
end
```

To store something in the session, you can assign it to a key similar to adding
a value to a hash. After a user is authenticated, its id is saved in the
session to be used for subsequent requests:

```ruby
class SessionsController < ApplicationController
  def create
    if user = User.authenticate_by(email: params[:email], password: params[:password])
      # Save the user ID in the session so it can be used in
      # subsequent requests
      session[:current_user_id] = user.id
      redirect_to root_url
    end
  end
end
```

To remove something from the session, delete the key/value pair. Deleting the
current_user_id key from the session is a typical way to log the user out:

```ruby
class SessionsController < ApplicationController
  def destroy
    session.delete(:current_user_id)
    # Clear the current user as well.
    @current_user = nil
    redirect_to root_url, status: :see_other
  end
end
```

It is possible to reset the entire session with reset_session. It is
recommended to use reset_session after logging in to avoid session fixation
attacks. Please refer to the Security
Guide
for details.

Sessions are lazily loaded. If you don't access sessions in your action's
code, they will not be loaded. Hence, you will never need to disable sessions -
not accessing them will do the job.

### 6.2. The Flash

The flash
provides a way to pass temporary data between controller actions. Anything you
place in the flash will be available to the very next action and then cleared.
The flash is typically used for setting messages (e.g. notices and alerts) in a
controller action before redirecting to an action that displays the message to
the user.

The flash is accessed via the flash method. Similar to the session, the
flash values are stored as key/value pairs.

For example, in the controller action for logging out a user, the controller can
set a flash message which can be displayed to the user on the next request:

```ruby
class SessionsController < ApplicationController
  def destroy
    session.delete(:current_user_id)
    flash[:notice] = "You have successfully logged out."
    redirect_to root_url, status: :see_other
  end
end
```

Displaying a message after a user performs some interactive action in your
application is a good practice to give the user feedback that their action was
successful (or that there were errors).

In addition to :notice, you can also use :alert. These are typically styled
(using CSS) with different colors to indicate their meaning (e.g. green for
notices and orange/red for alerts).

You can also assign a flash message directly within the redirect_to method by
including it as a parameter to redirect_to:

```ruby
redirect_to root_url, notice: "You have successfully logged out."
redirect_to root_url, alert: "There was an issue."
```

You're not limited to notice and alert.
You can set any key in a flash (similar to sessions), by assigning it to the :flash argument.
For example, assigning :just_signed_up:

```ruby
redirect_to root_url, flash: { just_signed_up: true }
```

This will allow you to have the below in the view:

```ruby
<% if flash[:just_signed_up] %>
  <p class="welcome">Welcome to our site!</p>
<% end %>
```

In the above logout example, the destroy action redirects to the application's
root_url, where the message is available to be displayed. However, it's not
displayed automatically. It's up to the next action to decide what, if anything,
it will do with what the previous action put in the flash.

#### 6.2.1. Displaying flash messages

If a previous action has set a flash message, it's a good idea to display that
to the user. We can accomplish this consistently by adding the HTML for
displaying any flash messages in the application's default layout. Here's an
example from app/views/layouts/application.html.erb:

```ruby
<html>
  <!-- <head/> -->
  <body>
    <% flash.each do |name, msg| -%>
      <%= content_tag :div, msg, class: name %>
    <% end -%>

    <!-- more content -->
    <%= yield %>
  </body>
</html>
```

The name above indicates the type of flash message, such as notice or
alert. This information is normally used to style how the message is displayed
to the user.

You can filter by name if you want to limit to displaying only notice
and alert in layout. Otherwise, all keys set in the flash will be displayed.

Including the reading and displaying of flash messages in the layout ensures
that your application will display these automatically, without each view having
to include logic to read the flash.

#### 6.2.2. flash.keep and flash.now

flash.keep is used to carry over the flash value through to an additional
request. This is useful when there are multiple redirects.

For example, assume that the index action in the controller below corresponds
to the root_url. And you want all requests here to be redirected to
UsersController#index. If an action sets the flash and redirects to
MainController#index, those flash values will be lost when another redirect
happens, unless you use flash.keep to make the values persist for another
request.

```ruby
class MainController < ApplicationController
  def index
    # Will persist all flash values.
    flash.keep

    # You can also use a key to keep only some kind of value.
    # flash.keep(:notice)
    redirect_to users_url
  end
end
```

flash.now is used to make the flash values available in the same request.
By default, adding values to the flash will make them available to the next
request. For example, if the create action fails to save a resource, and you
render the new template directly, that's not going to result in a new request,
but you may still want to display a message using the flash. To do this, you can
use flash.now in the same way you use the normal flash:

```ruby
class ClientsController < ApplicationController
  def create
    @client = Client.new(client_params)
    if @client.save
      # ...
    else
      flash.now[:error] = "Could not save client"
      render action: "new"
    end
  end
end
```

### 6.3. Session Stores

All sessions have a unique ID that represents the session object; these session
IDs are stored in a cookie. The actual session objects use one of the following
storage mechanisms:

- ActionDispatch::Session::CookieStore - Stores everything on the client.

- ActionDispatch::Session::CacheStore - Stores the data in the Rails
cache.

- ActionDispatch::Session::ActiveRecordStore -
Stores the data in a database using Active Record (requires the
activerecord-session_store gem).

- A custom store or a store provided by a third party gem.

For most session stores, the unique session ID in the cookie is used to look up
session data on the server (e.g. a database table). Rails does not allow you to
pass the session ID in the URL as this is less secure.

#### 6.3.1. CookieStore

The CookieStore is the default and recommended session store. It stores all
session data in the cookie itself (the session ID is still available to you if
you need it). The CookieStore is lightweight and does not require any
configuration to use in a new application.

The CookieStore can store 4 kB of data - much less than the other storage
options - but this is usually enough. Storing large amounts of data in the
session is discouraged. You should especially avoid storing complex objects
(such as model instances) in the session.

#### 6.3.2. CacheStore

You can use the CacheStore if your sessions don't store critical data or don't
need to be around for long periods (for instance if you just use the flash for
messaging). This will store sessions using the cache implementation you have
configured for your application. The advantage is that you can use your existing
cache infrastructure for storing sessions without requiring any additional setup
or administration. The downside is that the session storage will be temporary
and they could disappear at any time.

Read more about session storage in the Security Guide.

### 6.4. Session Storage Options

There are a few configuration options related to session storage. You can
configure the type of storage in an initializer:

```ruby
Rails.application.config.session_store :cache_store
```

Rails sets up a session key (the name of the cookie) when signing the session
data. These can also be changed in an initializer:

```ruby
Rails.application.config.session_store :cookie_store, key: "_your_app_session"
```

Be sure to restart your server when you modify an initializer file.

You can also pass a :domain key and specify the domain name for the cookie:

```ruby
Rails.application.config.session_store :cookie_store, key: "_your_app_session", domain: ".example.com"
```

See config.session_store in the
configuration guide for more information.

Rails sets up a secret key for CookieStore used for signing the session data
in config/credentials.yml.enc. The credentials can be updated with bin/rails
credentials:edit.

```yaml
# aws:
#   access_key_id: 123
#   secret_access_key: 345

# Used as the base secret for all MessageVerifiers in Rails, including the one protecting cookies.
secret_key_base: 492f...
```

Changing the secret_key_base when using the CookieStore will
invalidate all existing sessions. You'll need to configure a cookie rotator
to rotate existing sessions.

## 7. Controller Callbacks

Controller callbacks are methods that are defined to automatically run before
and/or after a controller action. A controller callback method can be defined in
a given controller or in the ApplicationController. Since all controllers
inherit from ApplicationController, callbacks defined here will run on every
controller in your application.

### 7.1. before_action

Callback methods registered via before_action run before a controller
action. They may halt the request cycle. A common use case for before_action
is ensuring that a user is logged in:

```ruby
class ApplicationController < ActionController::Base
  before_action :require_login

  private
    def require_login
      unless logged_in?
        flash[:error] = "You must be logged in to access this section"
        redirect_to new_login_url # halts request cycle
      end
    end
end
```

The method stores an error message in the flash and redirects to the login form
if the user is not already logged in. When a before_action callback renders or
redirects (like in the example above), the original controller action is not
run. If there are additional callbacks registered to run, they are also
cancelled and not run.

In this example, the before_action is defined in ApplicationController so
all controllers in the application inherit it. That implies that all requests in
the application will require the user to be logged in. This is fine except for
the "login" page. The "login" action should succeed even when the user is not
logged in (to allow the user to log in) otherwise the user will never be able to
log in. You can use skip_before_action to allow specified controller
actions to skip a given before_action:

```ruby
class LoginsController < ApplicationController
  skip_before_action :require_login, only: [:new, :create]
end
```

Now, the LoginsController's new and create actions will work without
requiring the user to be logged in.

The :only option skips the callback only for the listed actions; there is also
an :except option which works the other way. These options can be used when
registering action callbacks too, to add callbacks which only run for selected
actions.

If you register the same action callback multiple times with different
options, the last action callback definition will overwrite the previous ones.

### 7.2. after_action and around_action

You can also define action callbacks to run after a controller action has been
executed with after_action, or to run both before and after with
around_action.

The after_action callbacks are similar to before_action callbacks, but
because the controller action has already been run they have access to the
response data that's about to be sent to the client.

after_action callbacks are executed only after a successful controller
action, and not if an exception is raised in the request cycle.

The around_action callbacks are useful when you want to execute code before
and after a controller action, allowing you to encapsulate functionality that
affects the action's execution. They are responsible for running their
associated actions by yielding.

For example, imagine you want to monitor the performance of specific actions.
You could use an around_action to measure how long each action takes to
complete and log this information:

```ruby
class ApplicationController < ActionController::Base
  around_action :measure_execution_time

  private
    def measure_execution_time
      start_time = Time.now
      yield  # This executes the action
      end_time = Time.now

      duration = end_time - start_time
      Rails.logger.info "Action #{action_name} from controller #{controller_name} took #{duration.round(2)} seconds to execute."
    end
end
```

Action callbacks receive controller_name and action_name as parameters
you can use, as shown in the example above.

The around_action callback also wraps rendering. In the example above, view
rendering will be included in the duration. The code after the yield in an
around_action is run even when there is an exception in the associated action
and there is an ensure block in the callback. (This is different from
after_action callbacks where an exception in the action cancels the
after_action code.)

### 7.3. Other Ways to Use Callbacks

In addition to before_action, after_action, or around_action, there are
two less common ways to register callbacks.

The first is to use a block directly with the *_action methods. The block
receives the controller as an argument. For example, the require_login action
callback from above could be rewritten to use a block:

```ruby
class ApplicationController < ActionController::Base
  before_action do |controller|
    unless controller.send(:logged_in?)
      flash[:error] = "You must be logged in to access this section"
      redirect_to new_login_url
    end
  end
end
```

Note that the action callback, in this case, uses send because the
logged_in? method is private, and the action callback does not run in the
scope of the controller. This is not the recommended way to implement this
particular action callback, but in simpler cases, it might be useful.

Specifically for around_action, the block also yields in the action:

```ruby
around_action { |_controller, action| time(&action) }
```

The second way is to specify a class (or any object that responds to the
expected methods) for the callback action. This can be useful in cases that are
more complex. As an example, you could rewrite the around_action callback to
measure execution time with a class:

```ruby
class ApplicationController < ActionController::Base
  around_action ActionDurationCallback
end

class ActionDurationCallback
  def self.around(controller)
    start_time = Time.now
    yield # This executes the action
    end_time = Time.now

    duration = end_time - start_time
    Rails.logger.info "Action #{controller.action_name} from controller #{controller.controller_name} took #{duration.round(2)} seconds to execute."
  end
end
```

In above example, the ActionDurationCallback's method is not run in the scope
of the controller but gets controller as an argument.

In general, the class being used for a *_action callback must implement a
method with the same name as the action callback. So for the before_action
callback, the class must implement a before method, and so on. Also,
the around method must yield to execute the action.

## 8. The Request and Response Objects

Every controller has two methods, request and response, which can be
used to access the request and response objects associated with the
current request cycle. The request method returns an instance of
ActionDispatch::Request. The response method returns an instance
of ActionDispatch::Response, an object representing what is going to be
sent back to the client browser (e.g. from render or redirect in the
controller action).

### 8.1. The request Object

The request object contains useful information about the request coming in from
the client. This section describes the purpose of some of the properties of the
request object.

To get a full list of the available methods, refer to the Rails API
documentation
and Rack
documentation.

#### 8.1.1. query_parameters, request_parameters, and path_parameters

Rails collects all of the parameters for a given request in the params hash,
including the ones set in the URL as query string parameters, and those sent as
the body of a POST request. The request object has three methods that give you
access to the various parameters.

- query_parameters - contains parameters that were sent as part of the
query string.

- request_parameters - contains parameters sent as part of the post body.

- path_parameters - contains parameters parsed by the router as being part
of the path leading to this particular controller and action.

#### 8.1.2. request.variant

Controllers might need to tailor a response based on context-specific
information in a request. For example, controllers responding to requests from a
mobile platform might need to render different content than requests from a
desktop browser. One strategy to accomplish this is by customizing a request's
variant. Variant names are arbitrary, and can communicate anything from the
request's platform (:android, :ios, :linux, :macos, :windows) to its
browser (:chrome, :edge, :firefox, :safari), to the type of user
(:admin, :guest, :user).

You can set the request.variant in a before_action:

```ruby
request.variant = :tablet if request.user_agent.include?("iPad")
```

Responding with a variant in a controller action is like responding with a format:

```ruby
# app/controllers/projects_controller.rb

def show
  # ...
  respond_to do |format|
    format.html do |html|
      html.tablet                         # renders app/views/projects/show.html+tablet.erb
      html.phone { extra_setup; render }  # renders app/views/projects/show.html+phone.erb
    end
  end
end
```

A separate template should be created for each format and variant:

- app/views/projects/show.html.erb

- app/views/projects/show.html+tablet.erb

- app/views/projects/show.html+phone.erb

You can also simplify the variants definition using the inline syntax:

```ruby
respond_to do |format|
  format.html.tablet
  format.html.phone  { extra_setup; render }
end
```

### 8.2. The response Object

The response object is built up during the execution of the action from
rendering data to be sent back to the client browser. It's not usually used
directly but sometimes, in an after_action callback for example, it can be
useful to access the response directly. One use case is for setting the content type header:

```ruby
response.content_type = "application/pdf"
```

Another use case is for setting custom response headers:

```ruby
response.headers["X-Custom-Header"] = "some value"
```

The headers attribute is a hash which maps header names to header values.
Rails sets some headers automatically but if you need to update a header or add
a custom header, you can use response.headers as in the example above.

The headers method can be accessed directly in the controller as well.

Here are some of the properties of the response object:

To get a full list of the available methods, refer to the Rails API
documentation
and Rack
Documentation.

---

# Chapters

In this guide, you will learn about some advanced topics related to controllers. After reading this guide, you will know how to:

- Protect against cross-site request forgery.

- Use Action Controller's built-in HTTP authentication.

- Stream data directly to the user's browser.

- Filter sensitive parameters from the application logs.

- Handle exceptions that may be raised during request processing.

- Use the built-in health check endpoint for load balancers and uptime monitors.

## 1. Introduction

This guide covers a number of advanced topics related to controllers in a Rails
application. Please see the Action Controller
Overview guide for an introduction to Action
Controllers.

## 2. Authenticity Token and Request Forgery Protection

Cross-site request forgery
(CSRF)
is a type of malicious attack where unauthorized requests are submitted by
impersonating a user that the web application trusts.

The first step to avoid this type of attack is to ensure that all "destructive"
actions (create, update, and destroy) in your application use non-GET requests (like POST, PUT and DELETE).

However, a malicious site can still send a non-GET request to your site, so
Rails builds in request forgery protection into controllers by default.

This is done by adding a token using the
protect_from_forgery
method. This token is added to each request and is only known to your server.
Rails verifies the received token with the token in the session. If an incoming
request does not have the proper matching token, the server will deny access.

The CSRF token is added automatically when config.action_controller.default_protect_from_forgery is set to true, which is the default for newly created Rails applications. It can also be manually like this:

```ruby
class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
end
```

All subclasses of ActionController::Base are protected by default and
will raise an ActionController::InvalidAuthenticityToken error on unverified
requests.

### 2.1. Authenticity Token in Forms

When you generate a form using form_with like this:

```ruby
<%= form_with model: @user do |form| %>
  <%= form.text_field :username %>
  <%= form.text_field :password %>
<% end %>
```

A CSRF token named authenticity_token is automatically added as a hidden field
in the generated HTML:

```html
<form accept-charset="UTF-8" action="/users/1" method="post">
<input type="hidden"
       value="67250ab105eb5ad10851c00a5621854a23af5489"
       name="authenticity_token"/>
<!-- fields -->
</form>
```

Rails adds this token to every form that's generated using the form
helpers, so most of the time you don't need to do anything.
If you're writing a form manually or need to add the token for another reason,
it's available through the
form_authenticity_token
method.

```html
<!-- app/views/layouts/application.html.erb -->
<head>
  <meta name="csrf-token" content="<%= form_authenticity_token %>">
</head>
```

The form_authenticity_token method generates a valid authentication token.
That can be useful in places where Rails does not add it automatically, like in
custom Ajax calls.

You can learn more details about the CSRF attack as well as CSRF countermeasures
in the Security Guide.

## 3. Controlling Allowed Browser Versions

Starting with version 7.2, Rails controllers use allow_browser method in ApplicationController to allow only modern browsers by default.

```ruby
class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern
end
```

Modern browsers includes Safari 17.2+, Chrome 120+, Firefox 121+, Opera 106+. You can use caniuse.com to check for browser versions supporting the features you'd like to use.

In addition to the default of :modern, you can also specify the browser versions manually:

```ruby
class ApplicationController < ActionController::Base
  # All versions of Chrome and Opera will be allowed, but no versions of "internet explorer" (ie). Safari needs to be 16.4+ and Firefox 121+.
  allow_browser versions: { safari: 16.4, firefox: 121, ie: false }
end
```

Browsers matched in the hash passed to versions: will be blocked if they’re below the versions specified. This means that all other browsers not mentioned in versions: (Chrome and Opera in the above example), as well as agents that aren’t reporting a user-agent header, will be allowed access.

You can also use allow_browser in a given controller and specify actions using only or except. For example:

```ruby
class MessagesController < ApplicationController
  # In addition to the browsers blocked by ApplicationController, also block Opera below 104 and Chrome below 119 for the show action.
  allow_browser versions: { opera: 104, chrome: 119 }, only: :show
end
```

A browser that’s blocked will, by default, be served the file in public/406-unsupported-browser.html with an HTTP status code of “406 Not Acceptable”.

## 4. HTTP Authentication

Rails comes with three built-in HTTP authentication mechanisms:

- Basic Authentication

- Digest Authentication

- Token Authentication

### 4.1. HTTP Basic Authentication

HTTP Basic Authentication is a simple authentication method where a user is
required to enter a username and password to access a website or a particular
section of a website (e.g. admin section). These credentials are entered into a
browser's HTTP basic dialog window. The user’s credentials are then encoded and
sent in the HTTP header with each request.

HTTP basic authentication is an authentication scheme that is supported by most
browsers. Using HTTP Basic authentication in a Rails controller can be done by
using the http_basic_authenticate_with method:

```ruby
class AdminsController < ApplicationController
  http_basic_authenticate_with name: "Arthur", password: "42424242"
end
```

With the above in place, you can create controllers that inherit from
AdminsController. All actions in those controllers will use HTTP basic
authentication and require user credentials.

HTTP Basic Authentication is easy to implement but not secure on its
own, as it will send unencrypted credentials over the network. Make sure to use
HTTPS when using Basic Authentication. You can also force
HTTPS.

### 4.2. HTTP Digest Authentication

HTTP digest authentication is more secure than basic authentication as it does
not require the client to send an unencrypted password over the network. The
credentials are hashed instead and a
Digest
is sent.

Using digest authentication with Rails can be done by using
the authenticate_or_request_with_http_digest method:

```ruby
class AdminsController < ApplicationController
  USERS = { "admin" => "helloworld" }

  before_action :authenticate

  private
    def authenticate
      authenticate_or_request_with_http_digest do |username|
        USERS[username]
      end
    end
end
```

The authenticate_or_request_with_http_digest block takes only one argument -
the username. The block returns the password if found. If the return value is
false or nil, it is considered an authentication failure.

### 4.3. HTTP Token Authentication

Token authentication (aka "Bearer" authentication) is an authentication method
where a client receives a unique token after successfully logging in, which it
then includes in the Authorization header of future requests. Instead of
sending credentials with each request, the client sends this
token
(a string that represents the user's session) as a "bearer" of the
authentication.

This approach improves security by separating credentials from the ongoing
session. You use an authentication token that has been issued in advance to
perform authentication.

Implementing token authentication with Rails can be done using the
authenticate_or_request_with_http_token method.

```ruby
class PostsController < ApplicationController
  TOKEN = "secret"

  before_action :authenticate

  private
    def authenticate
      authenticate_or_request_with_http_token do |token, options|
        ActiveSupport::SecurityUtils.secure_compare(token, TOKEN)
      end
    end
end
```

The authenticate_or_request_with_http_token block takes two arguments - the
token and a hash containing the options that were parsed from the HTTP
Authorization header. The block should return true if the authentication is
successful. Returning false or nil will cause an authentication failure.

## 5. Streaming and File Downloads

Rails controllers provide a way to send a file to the user instead of rendering
an HTML page. This can be done with the send_data and the send_file
methods, which stream data to the client. The send_file method is a
convenience method that lets you provide the name of a file, and it will stream
the contents of that file.

Here is an example of how to use send_data:

```ruby
require "prawn"
class ClientsController < ApplicationController
  # Generates a PDF document with information on the client and
  # returns it. The user will get the PDF as a file download.
  def download_pdf
    client = Client.find(params[:id])
    send_data generate_pdf(client),
              filename: "#{client.name}.pdf",
              type: "application/pdf"
  end

  private
    def generate_pdf(client)
      Prawn::Document.new do
        text client.name, align: :center
        text "Address: #{client.address}"
        text "Email: #{client.email}"
      end.render
    end
end
```

The download_pdf action in the above example calls a private method which
generates the PDF document and returns it as a string. This string will then be
streamed to the client as a file download.

Sometimes when streaming files to the user, you may not want them to download
the file. Take images, for example, which can be embedded into HTML pages. To
tell the browser a file is not meant to be downloaded, you can set the
:disposition option to "inline". The default value for this option is
"attachment".

### 5.1. Sending Files

If you want to send a file that already exists on disk, use the send_file
method.

```ruby
class ClientsController < ApplicationController
  # Stream a file that has already been generated and stored on disk.
  def download_pdf
    client = Client.find(params[:id])
    send_file("#{Rails.root}/files/clients/#{client.id}.pdf",
              filename: "#{client.name}.pdf",
              type: "application/pdf")
  end
end
```

The file will be read and streamed at 4 kB at a time by default, to avoid loading
the entire file into memory at once. You can turn off streaming with the
:stream option or adjust the block size with the :buffer_size option.

If :type is not specified, it will be guessed from the file extension
specified in :filename. If the content-type is not registered for the
extension, application/octet-stream will be used.

Be careful when using data coming from the client (params, cookies,
etc.) to locate the file on disk. This is a security risk as it might allow
someone to gain access to sensitive files.

It is not recommended that you stream static files through Rails if you can
instead keep them in a public folder on your web server. It is much more
efficient to let the user download the file directly using Apache or another web
server, keeping the request from unnecessarily going through the whole Rails
stack.

### 5.2. RESTful Downloads

While send_data works fine, if you are creating a RESTful application having
separate actions for file downloads is usually not necessary. In REST
terminology, the PDF file from the example above can be considered just another
representation of the client resource. Rails provides a slick way of doing
"RESTful" downloads. Here's how you can rewrite the example so that the PDF
download is a part of the show action, without any streaming:

```ruby
class ClientsController < ApplicationController
  # The user can request to receive this resource as HTML or PDF.
  def show
    @client = Client.find(params[:id])

    respond_to do |format|
      format.html
      format.pdf { render pdf: generate_pdf(@client) }
    end
  end
end
```

Now the user can request to get a PDF version of a client just by adding ".pdf"
to the URL:

```
GET /clients/1.pdf
```

You can call any method on format that is an extension registered as a MIME
type by Rails. Rails already registers common MIME types like "text/html" and
"application/pdf":

```ruby
Mime::Type.lookup_by_extension(:pdf)
# => "application/pdf"
```

If you need additional MIME types, call
Mime::Type.register
in the file config/initializers/mime_types.rb. For example, this is how you
would register the Rich Text Format (RTF):

```ruby
Mime::Type.register("application/rtf", :rtf)
```

If you modify an initializer file, you have to restart the server for
their changes to take effect.

### 5.3. Live Streaming of Arbitrary Data

Rails allows you to stream more than just files. In fact, you can stream
anything you would like in a response object. The
ActionController::Live
module allows you to create a persistent connection with a browser. By including
this module in your controller, you can send arbitrary data to the browser at
specific points in time.

```ruby
class MyController < ActionController::Base
  include ActionController::Live

  def stream
    response.headers["Content-Type"] = "text/event-stream"
    100.times {
      response.stream.write "hello world\n"
      sleep 1
    }
  ensure
    response.stream.close
  end
end
```

The above example will keep a persistent connection with the browser and send
100 messages of "hello world\n", each one second apart.

Note that you have to make sure to close the response stream, otherwise the
stream will leave the socket open indefinitely. You also have to set the content
type to text/event-stream before calling write on the response stream.
Headers cannot be written after the response has been committed (when
response.committed? returns a truthy value) with either write or commit.

#### 5.3.1. Example Use Case

Let's suppose that you were making a karaoke machine, and a user wants to get
the lyrics for a particular song. Each Song has a particular number of lines
and each line takes time num_beats to finish singing.

If we wanted to return the lyrics in karaoke fashion (only sending the line when
the singer has finished the previous line), then we could use
ActionController::Live as follows:

```ruby
class LyricsController < ActionController::Base
  include ActionController::Live

  def show
    response.headers["Content-Type"] = "text/event-stream"
    response.headers["Cache-Control"] = "no-cache"

    song = Song.find(params[:id])

    song.each do |line|
      response.stream.write line.lyrics
      sleep line.num_beats
    end
  ensure
    response.stream.close
  end
end
```

#### 5.3.2. Streaming Considerations

Streaming arbitrary data is an extremely powerful tool. As shown in the previous
examples, you can choose when and what to send across a response stream.
However, you should also note the following things:

- Each response stream creates a new thread and copies over the thread local
variables from the original thread. Having too many thread local variables can
negatively impact performance. Similarly, a large number of threads can also
hinder performance.

- Failing to close the response stream will leave the corresponding socket open
forever. Make sure to call close whenever you are using a response stream.

- WEBrick servers buffer all responses, and so streaming with
ActionController::Live will not work. You must use a web server which does
not automatically buffer responses.

## 6. Log Filtering

Rails keeps a log file for each environment in the log folder at the
application's root directory. Log files are extremely useful when debugging your
application, but in a production environment you may not want every bit of
information stored in log files. Rails allows you to specify parameters that
should not be stored.

### 6.1. Parameters Filtering

You can filter out sensitive request parameters from your log files by appending
them to config.filter_parameters in the application configuration.

```ruby
config.filter_parameters << :password
```

These parameters will be marked [FILTERED] in the log.

The parameters specified in filter_parameters will be filtered out with
partial matching regular expression. So for example, :passw will filter out
password, password_confirmation, etc.

Rails adds a list of default filters, including :passw, :secret, and
:token, in the appropriate initializer
(initializers/filter_parameter_logging.rb) to handle typical application
parameters like password, password_confirmation and my_token.

### 6.2. Redirects Filtering

Sometimes it's desirable to filter out sensitive locations that your application
is redirecting to. You can do that by using the config.filter_redirect
configuration option:

```ruby
config.filter_redirect << "s3.amazonaws.com"
```

You can set it to a String, a Regexp, or an Array of both.

```ruby
config.filter_redirect.concat ["s3.amazonaws.com", /private_path/]
```

Matching URLs will be replaced with [FILTERED]. However, if you only wish to
filter the parameters, not the whole URLs, you can use parameter filtering.

## 7. Force HTTPS Protocol

If you'd like to ensure that communication to your controller is only possible
via HTTPS, you can do so by enabling the ActionDispatch::SSL middleware
via config.force_ssl in your environment configuration.

## 8. Built-in Health Check Endpoint

Rails comes with a built-in health check endpoint that is reachable at the /up
path. This endpoint will return a 200 status code if the app has booted with no
exceptions, and a 500 status code otherwise.

In production, many applications are required to report their status, whether
it's to an uptime monitor that will page an engineer when things go wrong, or a
load balancer or Kubernetes controller used to determine the health of a given
instance. This health check is designed to be a one-size fits all that will work
in many situations.

While any newly generated Rails applications will have the health check at
/up, you can configure the path to be anything you'd like in your
"config/routes.rb":

```ruby
Rails.application.routes.draw do
  get "health" => "rails/health#show", as: :rails_health_check
end
```

The health check will now be accessible via GET or HEAD requests to the
/health path.

This endpoint does not reflect the status of all of your application's
dependencies, such as the database or redis. Replace "rails/health#show" with
your own controller action if you have application specific needs.

Reporting the health of an application requires some considerations. You'll have
to decide what you want to include in the check. For example, if a third-party
service is down and your application reports that it's down due to the
dependency, your application may be restarted unnecessarily. Ideally, your
application should handle third-party outages gracefully.

## 9. Handling Errors

Your application will likely contain bugs and throw exceptions that needs to be
handled. For example, if the user follows a link to a resource that no longer
exists in the database, Active Record will throw the
ActiveRecord::RecordNotFound exception.

Rails default exception handling displays a "500 Server Error" message for all
exceptions. If the request was made in development, a nice backtrace and
additional information is displayed, to help you figure out what went wrong. If
the request was made in production, Rails will display a simple "500 Server
Error" message, or a "404 Not Found" if there was a routing error, or a record
could not be found.

You can customize how these errors are caught and how they're displayed to the
user. There are several levels of exception handling available in a Rails
application. You can use config.action_dispatch.show_exceptions configuration
to control how Rails handles exceptions raised while responding to requests. You
can learn more about the levels of exceptions in the
configuration guide.

### 9.1. The Default Error Templates

By default, in the production environment the application will render an error
page. These pages are contained in static HTML files in the public folder, in
404.html, 500.html, etc. You can customize these files to add some extra
information and styles.

The error templates are static HTML files so you can't use ERB, SCSS, or
layouts for them.

### 9.2. rescue_from

You can catch specific errors and do something different with them by using the
rescue_from method. It can handle exceptions of a certain type (or
multiple types) in an entire controller and its subclasses.

When an exception occurs which is caught by a rescue_from directive, the
exception object is passed to the handler.

Below is an example of how you can use rescue_from to intercept all
ActiveRecord::RecordNotFound errors and do something with them:

```ruby
class ApplicationController < ActionController::Base
  rescue_from ActiveRecord::RecordNotFound, with: :record_not_found

  private
    def record_not_found
      render plain: "Record Not Found", status: 404
    end
end
```

The handler can be a method or a Proc object passed to the :with option. You
can also use a block directly instead of an explicit Proc object.

The above example doesn't improve on the default exception handling at all, but
it serves to show how once you catch specific exceptions, you're free to do
whatever you want with them. For example, you could create custom exception
classes that will be thrown when a user doesn't have access to a certain section
of your application:

```ruby
class ApplicationController < ActionController::Base
  rescue_from User::NotAuthorized, with: :user_not_authorized

  private
    def user_not_authorized
      flash[:error] = "You don't have access to this section."
      redirect_back(fallback_location: root_path)
    end
end

class ClientsController < ApplicationController
  # Check that the user has the right authorization to access clients.
  before_action :check_authorization

  def edit
    @client = Client.find(params[:id])
  end

  private
    # If the user is not authorized, throw the custom exception.
    def check_authorization
      raise User::NotAuthorized unless current_user.admin?
    end
end
```

Using rescue_from with Exception or StandardError would cause
serious side-effects as it prevents Rails from handling exceptions properly. As
such, it is not recommended to do so unless there is a strong reason.

Certain exceptions are only rescuable from the ApplicationController
class, as they are raised before the controller gets initialized, and the action
gets executed.

---

# Chapters

After reading this guide, you will know:

- What Action View is and how to use it with Rails.

- How best to use templates, partials, and layouts.

- How to use localized views.

## 1. What is Action View?

Action View is the V in
MVC.
Action Controller and Action View work
together to handle web requests. Action Controller is concerned with
communicating with the model layer (of MVC) and retrieving data. Action View is
then responsible for rendering a response body to the web request using that
data.

By default, Action View templates (also referred to simply as "views") are
written using Embedded Ruby (ERB), which allows using Ruby code within HTML
documents.

Action View provides many helper methods for dynamically generating
HTML tags for forms, dates, and strings. It's also possible to add custom
helpers to your application as needed.

Action View can make use of Active Model features like
to_param
and
to_partial_path
to simplify code. That doesn't mean Action View depends on Active Model. Action
View is an independent package that can be used with any Ruby library.

## 2. Using Action View with Rails

Action View templates (aka "views") are stored in subdirectories in the
app/views directory. There is a subdirectory matching the name of each
controller. The view files inside that subdirectory are used to render specific
views as a response to controller actions.

For example, when you use scaffolding to generate an article resource, Rails
generates the following files in app/views/articles:

```bash
$ bin/rails generate scaffold article
      [...]
      invoke  scaffold_controller
      create    app/controllers/articles_controller.rb
      invoke    erb
      create      app/views/articles
      create      app/views/articles/index.html.erb
      create      app/views/articles/edit.html.erb
      create      app/views/articles/show.html.erb
      create      app/views/articles/new.html.erb
      create      app/views/articles/_form.html.erb
      [...]
```

The file names follow a Rails naming convention. They share their name with the
associated controller action. For example the index.html.erb, edit.html.erb,
etc.

By following this naming convention, Rails will automatically find and render
the matching view at the end of a controller action, without you having to
specify it. For example, the index action in the articles_controller.rb will
automatically render the index.html.erb view inside the app/views/articles/
directory. The name and the location of the file are both important.

The final HTML returned to the client is composed of a combination of the
.html.erb ERB file, a layout template that wraps it, and all the partials that
the ERB file may reference. In the rest of this guide, you will find more
details about each of the three components: Templates, Partials, Layouts.

## 3. Templates

Action View templates can be written in different formats. If the template file
has a .erb extension, it uses embedded Ruby to build an HTML response. If the
template has a .jbuilder extension, it uses the
Jbuilder gem to build a JSON response. And
a template with a .builder extension uses the
Builder::XmlMarkup library to build an XML
response.

Rails uses the file extension to distinguish among multiple template systems.
For example, an HTML file using the ERB template system will have .html.erb as
a file extension, and a JSON file using the Jbuilder template system will have
the .json.jbuilder file extension. Other libraries may add other template
types and file extensions as well.

### 3.1. ERB

An ERB template is a way to sprinkle Ruby code within static HTML using special
ERB tags like <% %> and <%= %>.

When Rails processes the ERB view templates ending with .html.erb, it
evaluates the embedded Ruby code and replaces the ERB tags with the dynamic
output. That dynamic content is combined with the static HTML markup to form the
final HTML response.

Within an ERB template, Ruby code can be included using both <% %> and <%=
%> tags. The <% %> tag (without the =) is used when you want to execute
Ruby code but not directly output the result, such as conditions or loops. The
tag <%= %> is used for Ruby code that generates an output and you want that
output rendered within the template, such as a model attribute like
person.name in this example:

```ruby
<h1>Names</h1>
<% @people.each do |person| %>
  Name: <%= person.name %><br>
<% end %>
```

The loop is set up using regular embedding tags (<% %>) and the name is
inserted using the output embedding tags (<%= %>).

Note that functions such as print and puts won't be rendered to the view
with ERB templates. So something like this would not work:

```ruby
<%# WRONG %>
Hi, Mr. <% puts "Frodo" %>
```

The above example shows that comments can be added in ERB within <%# %> tag.

To suppress leading and trailing whitespaces, you can use <%- -%>
interchangeably with <% and %>.

### 3.2. Jbuilder

Jbuilder is a gem that's maintained by the Rails team and included in the
default Rails Gemfile. It is used to build JSON responses using templates.

If you don't have it, you can add the following to your Gemfile:

```ruby
gem "jbuilder"
```

A Jbuilder object named json is automatically made available to templates
with a .jbuilder extension.

Here is a basic example:

```ruby
json.name("Alex")
json.email("alex@example.com")
```

would produce:

```
{
  "name": "Alex",
  "email": "alex@example.com"
}
```

See the Jbuilder documentation for
more examples.

### 3.3. Builder

Builder templates are a more programmatic alternative to ERB. It's similar to
JBuilder but is used to generate XML, instead of JSON.

An XmlMarkup object named xml is automatically made available to templates
with a .builder extension.

Here is a basic examples:

```ruby
xml.em("emphasized")
xml.em { xml.b("emph & bold") }
xml.a("A Link", "href" => "https://rubyonrails.org")
xml.target("name" => "compile", "option" => "fast")
```

which would produce:

```html
<em>emphasized</em>
<em><b>emph &amp; bold</b></em>
<a href="https://rubyonrails.org">A link</a>
<target option="fast" name="compile" />
```

Any method with a block will be treated as an XML markup tag with nested markup
in the block. For example, the following:

```ruby
xml.div {
  xml.h1(@person.name)
  xml.p(@person.bio)
}
```

would produce something like:

```html
<div>
  <h1>David Heinemeier Hansson</h1>
  <p>A product of Danish Design during the Winter of '79...</p>
</div>
```

See Builder documentation for more examples.

### 3.4. Template Compilation

By default, Rails will compile each template to a method to render it. In the
development environment, when you alter a template, Rails will check the file's
modification time and recompile it.

There is also Fragment Caching for when different parts of the page need to be
cached and expired separately. Learn more about it in the caching
guide.

## 4. Partials

Partial templates - usually just called "partials" - are a way of breaking up
the view templates into smaller reusable chunks. With partials, you can extract
a piece of code from your main template to a separate smaller file, and render
that file in the main template. You can also pass data to the partial files from
the main template.

Let's see this in action with some examples:

### 4.1. Rendering Partials

To render a partial as part of a view, you use the
render
method within the view:

```ruby
<%= render "product" %>
```

This will look for a file named _product.html.erb in the same folder to render
within that view. Partial file names start with leading underscore character by
convention. The file name distinguishes partials from regular views. However, no
underscore is used when referring to partials for rendering within a view. This
is true even when you reference a partial from another directory:

```ruby
<%= render "application/product" %>
```

That code will look for and display a partial file named _product.html.erb in
app/views/application/.

### 4.2. Using Partials to Simplify Views

One way to use partials is to treat them as the equivalent of methods. A way to
move details out of a view so that you can grasp what's going on more easily.
For example, you might have a view that looks like this:

```ruby
<%= render "application/ad_banner" %>

<h1>Products</h1>

<p>Here are a few of our fine products:</p>
<% @products.each do |product| %>
  <%= render partial: "product", locals: { product: product } %>
<% end %>

<%= render "application/footer" %>
```

Here, the _ad_banner.html.erb and _footer.html.erb partials could contain
content that is shared among many pages in your application. You don't need to
see the details of these sections when you're focused on a Products' page.

The above example also uses the _product.html.erb partial. This partial
contains details for rendering an individual product and is used to render each
product in the collection @products.

### 4.3. Passing Data to Partials with locals Option

When rendering a partial, you can pass data to the partial from the rendering
view. You use the locals: options hash for this. Each key in the locals:
option is available as a partial-local variable:

```ruby
<%# app/views/products/show.html.erb %>

<%= render partial: "product", locals: { my_product: @product } %>

<%# app/views/products/_product.html.erb %>

<%= tag.div id: dom_id(my_product) do %>
  <h1><%= my_product.name %></h1>
<% end %>
```

A "partial-local variable" is a variable that is local to a given partial and
only available from within that partial. In the above example, my_product is a
partial-local variable. It was assigned the value of @product when passed to
the partial from the original view.

Note that typically we'd simply call this local variable product. We are using
my_product to distinguish it from the instance variable name and template name
in this example.

Since locals is a hash, you can pass in multiple variables as needed, like
locals: { my_product: @product, my_reviews: @reviews }.

However, if a template refers to a variable that isn't passed into the view as
part of the locals: option, the template will raise an
ActionView::Template::Error:

```ruby
<%# app/views/products/_product.html.erb %>

<%= tag.div id: dom_id(my_product) do %>
  <h1><%= my_product.name %></h1>

  <%# => raises ActionView::Template::Error for `product_reviews` %>
  <% product_reviews.each do |review| %>
    <%# ... %>
  <% end %>
<% end %>
```

### 4.4. Using local_assigns

Each partial has a method called local_assigns available. You can use this
method to access keys passed via the locals: option. If a partial was not
rendered with :some_key set, the value of local_assigns[:some_key] will be
nil within the partial.

For example, product_reviews is nil in the below example since only
product is set in locals::

```ruby
<%# app/views/products/show.html.erb %>

<%= render partial: "product", locals: { product: @product } %>

<%# app/views/products/_product.html.erb %>

<% local_assigns[:product]          # => "#<Product:0x0000000109ec5d10>" %>
<% local_assigns[:product_reviews]  # => nil %>
```

One use case for local_assigns is optionally passing in a local variable and
then conditionally performing an action in the partial based on whether the
local variable is set. For example:

```ruby
<% if local_assigns[:redirect] %>
  <%= form.hidden_field :redirect, value: true %>
<% end %>
```

Another example from Active Storage's _blob.html.erb. This one sets the size
based on whether in_gallery local variable is set when rendering the partial
that contains this line:

```ruby
<%= image_tag blob.representation(resize_to_limit: local_assigns[:in_gallery] ? [ 800, 600 ] : [ 1024, 768 ]) %>
```

### 4.5. render without partial and locals Options

In the above examples, render takes 2 options: partial and locals. But if
these are the only options you need to use, you can skip the keys, partial and
locals, and specify the values only.

For example, instead of:

```ruby
<%= render partial: "product", locals: { product: @product } %>
```

You can write:

```ruby
<%= render "product", product: @product %>
```

You can also use this shorthand based on conventions:

```ruby
<%= render @product %>
```

This will look for a partial named _product.html.erb in app/views/products/,
as well as pass a local named product set to the value @product.

### 4.6. The as and object Options

By default, objects passed to the template are in a local variable with the same
name as the template. So, given:

```ruby
<%= render @product %>
```

within the _product.html.erb partial you'll get @product instance variable
in the local variable product, as if you had written:

```ruby
<%= render partial: "product", locals: { product: @product } %>
```

The object option can be used to specify a different name. This is useful when
the template's object is elsewhere (e.g. in a different instance variable or in
a local variable).

For example, instead of:

```ruby
<%= render partial: "product", locals: { product: @item } %>
```

you can write:

```ruby
<%= render partial: "product", object: @item %>
```

This assigns the instance variable @item to a partial local variable named
product. What if you wanted to change the local variable name from the default
product to something else? You can use the :as option for that.

With the as option, you can specify a different name for the local variable
like this:

```ruby
<%= render partial: "product", object: @item, as: "item" %>
```

This is equivalent to

```ruby
<%= render partial: "product", locals: { item: @item } %>
```

### 4.7. Rendering Collections

It's common for a view to iterate over a collection, such as @products, and
render a partial template for each object in the collection. This pattern has
been implemented as a single method that accepts an array and renders a partial
for each one of the elements in the array.

So this example for rendering all the products:

```ruby
<% @products.each do |product| %>
  <%= render partial: "product", locals: { product: product } %>
<% end %>
```

can be rewritten in a single line:

```ruby
<%= render partial: "product", collection: @products %>
```

When a partial is called with a collection, the individual instances of the
partial have access to the member of the collection being rendered via a
variable named after the partial. In this case, since the partial is
_product.html.erb, you can use product to refer to the collection member
that is being rendered.

You can also use the following conventions based shorthand syntax for rendering
collections.

```ruby
<%= render @products %>
```

The above assumes that @products is a collection of Product instances. Rails
uses naming conventions to determine the name of the partial to use by looking
at the model name in the collection, Product in this case. In fact, you can
even render a collection made up of instances of different models using this
shorthand, and Rails will choose the proper partial for each member of the
collection.

### 4.8. Spacer Templates

You can also specify a second partial to be rendered between instances of the
main partial by using the :spacer_template option:

```ruby
<%= render partial: @products, spacer_template: "product_ruler" %>
```

Rails will render the _product_ruler.html.erb partial (with no data passed to
it) between each pair of _product.html.erb partials.

### 4.9. Counter Variables

Rails also makes a counter variable available within a partial called by the
collection. The variable is named after the title of the partial followed by
_counter. For example, when rendering a collection @products the partial
_product.html.erb can access the variable product_counter. The variable
indexes the number of times the partial has been rendered within the enclosing
view, starting with a value of 0 on the first render.

```ruby
<%# index.html.erb %>
<%= render partial: "product", collection: @products %>
```

```ruby
<%# _product.html.erb %>
<%= product_counter %> # 0 for the first product, 1 for the second product...
```

This also works when the local variable name is changed using the as: option.
So if you did as: :item, the counter variable would be item_counter.

When rendering collections with instances of different models, the counter variable increments for each partial, regardless of the class of the model being rendered.

Note: The following two sections, Strict Locals and Local
Assigns with Pattern Matching are more
advanced features of using partials, included here for completeness.

### 4.10. local_assigns with Pattern Matching

Since local_assigns is a Hash, it's compatible with Ruby 3.1's pattern
matching assignment
operator:

```ruby
local_assigns => { product:, **options }
product # => "#<Product:0x0000000109ec5d10>"
options # => {}
```

When keys other than :product are assigned into a partial-local Hash
variable, they can be splatted into helper method calls:

```ruby
<%# app/views/products/_product.html.erb %>

<% local_assigns => { product:, **options } %>

<%= tag.div id: dom_id(product), **options do %>
  <h1><%= product.name %></h1>
<% end %>

<%# app/views/products/show.html.erb %>

<%= render "products/product", product: @product, class: "card" %>
<%# => <div id="product_1" class="card">
  #      <h1>A widget</h1>
  #    </div>
%>
```

Pattern matching assignment also supports variable renaming:

```ruby
local_assigns => { product: record }
product             # => "#<Product:0x0000000109ec5d10>"
record              # => "#<Product:0x0000000109ec5d10>"
product == record   # => true
```

You can also conditionally read a variable, then fall back to a default value
when the key isn't part of the locals: options, using fetch:

```ruby
<%# app/views/products/_product.html.erb %>

<% local_assigns.fetch(:related_products, []).each do |related_product| %>
  <%# ... %>
<% end %>
```

Combining Ruby 3.1's pattern matching assignment with calls to
Hash#with_defaults
enables compact partial-local default variable assignments:

```ruby
<%# app/views/products/_product.html.erb %>

<% local_assigns.with_defaults(related_products: []) => { product:, related_products: } %>

<%= tag.div id: dom_id(product) do %>
  <h1><%= product.name %></h1>

  <% related_products.each do |related_product| %>
    <%# ... %>
  <% end %>
<% end %>
```

### 4.11. Strict Locals

Action View partials are compiled into regular Ruby methods under the hood.
Because it is impossible in Ruby to dynamically create local variables, every single combination of locals passed to
a partial requires compiling another version:

```ruby
<%# app/views/articles/show.html.erb %>
<%= render partial: "article", layout: "box", locals: { article: @article } %>
<%= render partial: "article", layout: "box", locals: { article: @article, theme: "dark" } %>
```

The above snippet will cause the partial to be compiled twice, taking more time and using more memory.

```ruby
def _render_template_2323231_article_show(buffer, local_assigns, article:)
  # ...
end

def _render_template_3243454_article_show(buffer, local_assigns, article:, theme:)
  # ...
end
```

When the number of combinations is small, it's not really a problem, but if it's large it can waste
a sizeable amount of memory and take a long time to compile. To counter act this you can use
strict locals to define the compiled partial signature, and ensure only a single version of the partial is compiled:

```ruby
<%# locals: (article:, theme: "light") -%>
...
```

You can enforce how many and which locals a template accepts, set default
values, and more with a locals: signature, using the same syntax as Ruby method signatures.

Here are some examples of the locals: signature:

```ruby
<%# app/views/messages/_message.html.erb %>

<%# locals: (message:) -%>
<%= message %>
```

The above makes message a required local variable. Rendering the partial
without a :message local variable argument will raise an exception:

```ruby
render "messages/message"
# => ActionView::Template::Error: missing local: :message for app/views/messages/_message.html.erb
```

If a default value is set then it can be used if message is not passed in
locals::

```ruby
<%# app/views/messages/_message.html.erb %>

<%# locals: (message: "Hello, world!") -%>
<%= message %>
```

Rendering the partial without a :message local variable uses the default value
set in the locals: signature:

```ruby
render "messages/message"
# => "Hello, world!"
```

Rendering the partial with local variables not specified in the local: signature will also raise an exception:

```ruby
render "messages/message", unknown_local: "will raise"
# => ActionView::Template::Error: unknown local: :unknown_local for app/views/messages/_message.html.erb
```

You can allow optional local variable arguments with the double splat **
operator:

```ruby
<%# app/views/messages/_message.html.erb %>

<%# locals: (message: "Hello, world!", **attributes) -%>
<%= tag.p(message, **attributes) %>
```

Or you can disable locals entirely by setting the locals: to empty ():

```ruby
<%# app/views/messages/_message.html.erb %>

<%# locals: () %>
```

Rendering the partial with any local variable arguments will raise an
exception:

```ruby
render "messages/message", unknown_local: "will raise"
# => ActionView::Template::Error: no locals accepted for app/views/messages/_message.html.erb
```

Action View will process the locals: signature in any templating engine
that supports #-prefixed comments, and will read the signature from any
line in the partial.

Only keyword arguments are supported. Defining positional or block
arguments will raise an Action View Error at render-time.

The local_assigns method does not contain default values specified in the
local: signature. To access a local variable with a default value that
is named the same as a reserved Ruby keyword, like class or if, the values
can be accessed through binding.local_variable_get:

```ruby
<%# locals: (class: "message") %>
<div class="<%= binding.local_variable_get(:class) %>">...</div>
```

## 5. Layouts

Layouts can be used to render a common view template around the results of Rails
controller actions. A Rails application can have multiple layouts that pages can
be rendered within.

For example, an application might have one layout for a logged in user and
another for the marketing part of the site. The logged in user layout might
include top-level navigation that should be present across many controller
actions. The sales layout for a SaaS app might include top-level navigation for
things like "Pricing" and "Contact Us" pages. Different layouts can have a
different header and footer content.

To find the layout for the current controller action, Rails first looks for a
file in app/views/layouts with the same base name as the controller. For
example, rendering actions from the ProductsController class will use
app/views/layouts/products.html.erb.

Rails will use app/views/layouts/application.html.erb if a controller-specific layout does not exist.

Here is an example of a simple layout in application.html.erb file:

```ruby
<!DOCTYPE html>
<html>
<head>
  <title><%= "Your Rails App" %></title>
  <%= csrf_meta_tags %>
  <%= csp_meta_tag %>
  <%= stylesheet_link_tag "application", "data-turbo-track": "reload" %>
  <%= javascript_importmap_tags %>
</head>
<body>

<nav>
  <ul>
    <li><%= link_to "Home", root_path %></li>
    <li><%= link_to "Products", products_path %></li>
    <!-- Additional navigation links here -->
  </ul>
</nav>

<%= yield %>

<footer>
  <p>&copy; <%= Date.current.year %> Your Company</p>
</footer>
```

In the above example layout, view content will be rendered in place of <%=
yield %>, and surrounded by the same <head>, <nav>, and <footer> content.

Rails provides more ways to assign specific layouts to individual controllers
and actions. You can learn more about layouts in general in the Layouts and
Rendering in Rails guide.

### 5.1. Partial Layouts

Partials can have their own layouts applied to them. These layouts are different
from those applied to a controller action, but they work in a similar fashion.

Let's say you're displaying an article on a page which should be wrapped in a
div for display purposes. First, you'll create a new Article:

```ruby
Article.create(body: "Partial Layouts are cool!")
```

In the show template, you'll render the _article partial wrapped in the
box layout:

```ruby
<%# app/views/articles/show.html.erb %>
<%= render partial: 'article', layout: 'box', locals: { article: @article } %>
```

The box layout simply wraps the _article partial in a div:

```ruby
<%# app/views/articles/_box.html.erb %>
<div class="box">
  <%= yield %>
</div>
```

Note that the partial layout has access to the local article variable that was
passed into the render call, although it is not being used within
_box.html.erb in this case.

Unlike application-wide layouts, partial layouts still have the underscore
prefix in their name.

You can also render a block of code within a partial layout instead of calling
yield. For example, if you didn't have the _article partial, you could do
this instead:

```ruby
<%# app/views/articles/show.html.erb %>
<%= render(layout: 'box', locals: { article: @article }) do %>
  <div>
    <p><%= article.body %></p>
  </div>
<% end %>
```

Assuming you use the same _box partial from above, this would produce the same
output as the previous example.

### 5.2. Collection with Partial Layouts

When rendering collections it is also possible to use the :layout option:

```ruby
<%= render partial: "article", collection: @articles, layout: "special_layout" %>
```

The layout will be rendered together with the partial for each item in the
collection. The current object and object_counter variables, article and
article_counter in the above example, will be available in the layout as well,
the same way they are within the partial.

## 6. Helpers

Rails provides many helper methods to use with Action View. These include
methods for:

- Formatting dates, strings and numbers

- Creating HTML links to images, videos, stylesheets, etc...

- Sanitizing content

- Creating forms

- Localizing content

You can learn more about helpers in the Action View Helpers
Guide and the Action View Form Helpers
Guide.

## 7. Localized Views

Action View has the ability to render different templates depending on the
current locale.

For example, suppose you have an ArticlesController with a show action. By
default, calling this action will render app/views/articles/show.html.erb. But
if you set I18n.locale = :de, then Action View will try to render the template
app/views/articles/show.de.html.erb first. If the localized template isn't
present, the undecorated version will be used. This means you're not required to
provide localized views for all cases, but they will be preferred and used if
available.

You can use the same technique to localize the rescue files in your public
directory. For example, setting I18n.locale = :de and creating
public/500.de.html and public/404.de.html would allow you to have localized
rescue pages.

See the Rails Internationalization (I18n) API documentation for
more details.

---

# Chapters

After reading this guide, you will know:

- How to format dates, strings, and numbers.

- How to work with text and tags.

- How to link to images, videos, stylesheets, etc.

- How to work with Atom feeds and JavaScript in the views.

- How to cache, capture, debug and sanitize content.

The following outlines some of the most commonly used helpers available in
Action View. It serves as a good starting point, but reviewing the full API
Documentation is
also recommended, as it covers all of the helpers in more detail.

## 1. Formatting

### 1.1. Dates

These helpers facilitate the display of date and/or time elements as contextual
human readable forms.

#### 1.1.1. distance_of_time_in_words

Reports the approximate distance in time between two Time or Date objects or
integers as seconds. Set include_seconds to true if you want more detailed
approximations.

```ruby
distance_of_time_in_words(Time.current, 15.seconds.from_now)
# => less than a minute
distance_of_time_in_words(Time.current, 15.seconds.from_now, include_seconds: true)
# => less than 20 seconds
```

We use Time.current instead of Time.now because it returns the current
time based on the timezone set in Rails, whereas Time.now returns a Time
object based on the server's timezone.

See the distance_of_time_in_words API
Documentation
for more information.

#### 1.1.2. time_ago_in_words

Reports the approximate distance in time between a Time or Date object, or
integer as seconds,  and Time.current.

```ruby
time_ago_in_words(3.minutes.from_now) # => 3 minutes
```

See the time_ago_in_words API
Documentation
for more information.

### 1.2. Numbers

A set of methods for converting numbers into formatted strings. Methods are
provided for phone numbers, currency, percentage, precision, positional
notation, and file size.

#### 1.2.1. number_to_currency

Formats a number into a currency string (e.g., $13.65).

```ruby
number_to_currency(1234567890.50) # => $1,234,567,890.50
```

See the number_to_currency API
Documentation
for more information.

#### 1.2.2. number_to_human

Pretty prints (formats and approximates) a number so it is more readable by
users; useful for numbers that can get very large.

```ruby
number_to_human(1234)    # => 1.23 Thousand
number_to_human(1234567) # => 1.23 Million
```

See the number_to_human API
Documentation
for more information.

#### 1.2.3. number_to_human_size

Formats the bytes in size into a more understandable representation; useful for
reporting file sizes to users.

```ruby
number_to_human_size(1234)    # => 1.21 KB
number_to_human_size(1234567) # => 1.18 MB
```

See the number_to_human_size API
Documentation
for more information.

#### 1.2.4. number_to_percentage

Formats a number as a percentage string.

```ruby
number_to_percentage(100, precision: 0) # => 100%
```

See the number_to_percentage API
Documentation
for more information.

#### 1.2.5. number_to_phone

Formats a number into a phone number (US by default).

```ruby
number_to_phone(1235551234) # => 123-555-1234
```

See the number_to_phone API
Documentation
for more information.

#### 1.2.6. number_with_delimiter

Formats a number with grouped thousands using a delimiter.

```ruby
number_with_delimiter(12345678) # => 12,345,678
```

See the number_with_delimiter API
Documentation
for more information.

#### 1.2.7. number_with_precision

Formats a number with the specified level of precision, which defaults to 3.

```ruby
number_with_precision(111.2345)               # => 111.235
number_with_precision(111.2345, precision: 2) # => 111.23
```

See the number_with_precision API
Documentation
for more information.

### 1.3. Text

A set of methods for filtering, formatting and transforming strings.

#### 1.3.1. excerpt

Given a text and a phrase, excerpt searches for and extracts the first
occurrence of the phrase, plus the requested surrounding text determined by a
radius. An omission marker is prepended/appended if the start/end of the
result does not coincide with the start/end of the text.

```ruby
excerpt("This is a very beautiful morning", "very", separator: " ", radius: 1)
# => ...a very beautiful...

excerpt("This is also an example", "an", radius: 8, omission: "<chop> ")
#=> <chop> is also an example
```

See the excerpt API
Documentation
for more information.

#### 1.3.2. pluralize

Returns the singular or plural form of a word based on the value of a number.

```ruby
pluralize(1, "person") # => 1 person
pluralize(2, "person") # => 2 people
pluralize(3, "person", plural: "users") # => 3 users
```

See the pluralize API
Documentation
for more information.

#### 1.3.3. truncate

Truncates a given text to a given length. If the text is truncated, an
omission marker will be appended to the result for a total length not exceeding
length.

```ruby
truncate("Once upon a time in a world far far away")
# => "Once upon a time in a world..."

truncate("Once upon a time in a world far far away", length: 17)
# => "Once upon a ti..."

truncate("one-two-three-four-five", length: 20, separator: "-")
# => "one-two-three..."

truncate("And they found that many people were sleeping better.", length: 25, omission: "... (continued)")
# => "And they f... (continued)"

truncate("<p>Once upon a time in a world far far away</p>", escape: false)
# => "<p>Once upon a time in a wo..."
```

See the truncate API
Documentation
for more information.

#### 1.3.4. word_wrap

Wraps the text into lines no longer than line_width width.

```ruby
word_wrap("Once upon a time", line_width: 8)
# => "Once\nupon a\ntime"
```

See the word_wrap API
Documentation
for more information.

## 2. Forms

Form helpers simplify working with models compared to using standard HTML
elements alone. They offer a range of methods tailored to generating forms based
on your models. Some methods correspond to a specific type of input, such as
text fields, password fields, select dropdowns, and more. When a form is
submitted, the inputs within the form are grouped into the params object and
sent back to the controller.

You can learn more about form helpers in the Action View Form Helpers
Guide.

## 3. Navigation

A set of methods to build links and URLs that depend on the routing subsystem.

### 3.1. button_to

Generates a form that submits to the passed URL. The form has a submit button
with the value of the name.

```ruby
<%= button_to "Sign in", sign_in_path %>
```

would output the following HTML:

```html
<form method="post" action="/sessions" class="button_to">
  <input type="submit" value="Sign in" />
</form>
```

See the button_to API
Documentation
for more information.

### 3.2. current_page?

Returns true if the current request URL matches the given options.

```ruby
<% if current_page?(controller: 'profiles', action: 'show') %>
  <strong>Currently on the profile page</strong>
<% end %>
```

See the current_page? API
Documentation
for more information.

### 3.3. link_to

Links to a URL derived from url_for under the hood. It's commonly used to
create links for RESTful resources, especially when passing models as arguments
to link_to.

```ruby
link_to "Profile", @profile
# => <a href="/profiles/1">Profile</a>

link_to "Book", @book # given a composite primary key [:author_id, :id]
# => <a href="/books/2_1">Book</a>

link_to "Profiles", profiles_path
# => <a href="/profiles">Profiles</a>

link_to nil, "https://example.com"
# => <a href="https://example.com">https://example.com</a>

link_to "Articles", articles_path, id: "articles", class: "article__container"
# => <a href="/articles" class="article__container" id="articles">Articles</a>
```

You can use a block if your link target can't fit in the name parameter.

```ruby
<%= link_to @profile do %>
  <strong><%= @profile.name %></strong> -- <span>Check it out!</span>
<% end %>
```

It would output the following HTML:

```html
<a href="/profiles/1">
  <strong>David</strong> -- <span>Check it out!</span>
</a>
```

See the link_to API
Documentation
for more information.

### 3.4. mail_to

Generates a mailto link tag to the specified email address. You can also
specify the link text, additional HTML options, and whether to encode the email
address.

```ruby
mail_to "john_doe@gmail.com"
# => <a href="mailto:john_doe@gmail.com">john_doe@gmail.com</a>

mail_to "me@john_doe.com", cc: "me@jane_doe.com",
        subject: "This is an example email"
# => <a href="mailto:"me@john_doe.com?cc=me@jane_doe.com&subject=This%20is%20an%20example%20email">"me@john_doe.com</a>
```

See the mail_to API
Documentation
for more information.

### 3.5. url_for

Returns the URL for the set of options provided.

```ruby
url_for @profile
# => /profiles/1

url_for [ @hotel, @booking, page: 2, line: 3 ]
# => /hotels/1/bookings/1?line=3&page=2

url_for @post # given a composite primary key [:blog_id, :id]
# => /posts/1_2
```

## 4. Sanitization

A set of methods for scrubbing text of undesired HTML elements. The helpers are
particularly useful for helping to ensure that only safe and valid HTML/CSS is
rendered. It can also be useful to prevent XSS attacks by escaping or removing
potentially malicious content from user input before rendering it in your views.

This functionality is powered internally by the
rails-html-sanitizer gem.

### 4.1. sanitize

The sanitize method will HTML encode all tags and strip all attributes that
aren't specifically allowed.

```ruby
sanitize @article.body
```

If either the :attributes or :tags options are passed, only the mentioned
attributes and tags are allowed and nothing else.

```ruby
sanitize @article.body, tags: %w(table tr td), attributes: %w(id class style)
```

To change defaults for multiple uses, for example, adding table tags to the
default:

```ruby
# config/application.rb
class Application < Rails::Application
  config.action_view.sanitized_allowed_tags = %w(table tr td)
end
```

See the sanitize API
Documentation
for more information.

### 4.2. sanitize_css

Sanitizes a block of CSS code, particularly when it comes across a style
attribute in HTML content. sanitize_css is particularly useful when dealing
with user-generated content or dynamic content that includes style attributes.

The sanitize_css method below will remove the styles that are not allowed.

```ruby
sanitize_css("background-color: red; color: white; font-size: 16px;")
```

See the sanitize_css API
Documentation
for more information.

### 4.3. strip_links

Strips all link tags from text leaving just the link text.

```ruby
strip_links("<a href='https://rubyonrails.org'>Ruby on Rails</a>")
# => Ruby on Rails

strip_links("emails to <a href='mailto:me@email.com'>me@email.com</a>.")
# => emails to me@email.com.

strip_links("Blog: <a href='http://myblog.com/'>Visit</a>.")
# => Blog: Visit.
```

See the strip_links API
Documentation
for more information.

### 4.4. strip_tags

Strips all HTML tags from the HTML, including comments and special characters.

```ruby
strip_tags("Strip <i>these</i> tags!")
# => Strip these tags!

strip_tags("<b>Bold</b> no more! <a href='more.html'>See more</a>")
# => Bold no more! See more

strip_links('<<a href="https://example.org">malformed & link</a>')
# => &lt;malformed &amp; link
```

See the strip_tags API
Documentation
for more information.

## 5. Assets

A set of methods for generating HTML that links views to assets such as images,
JavaScript files, stylesheets, and feeds.

By default, Rails links to these assets on the current host in the public
folder, but you can direct Rails to link to assets from a dedicated assets
server by setting config.asset_host in the application configuration,
typically in config/environments/production.rb.

For example, let's say your asset host is assets.example.com:

```ruby
config.asset_host = "assets.example.com"
```

then the corresponding URL for an image_tag would be:

```ruby
image_tag("rails.png")
# => <img src="//assets.example.com/images/rails.png" />
```

### 5.1. audio_tag

Generates an HTML audio tag with source(s), either as a single tag for a string
source or nested source tags within an array for multiple sources. The sources
can be full paths, files in your public audios directory, or Active Storage
attachments.

```ruby
audio_tag("sound")
# => <audio src="/audios/sound"></audio>

audio_tag("sound.wav", "sound.mid")
# => <audio><source src="/audios/sound.wav" /><source src="/audios/sound.mid" /></audio>

audio_tag("sound", controls: true)
# => <audio controls="controls" src="/audios/sound"></audio>
```

Internally, audio_tag uses audio_path from the
AssetUrlHelpers
to build the audio path.

See the audio_tag API
Documentation
for more information.

### 5.2. auto_discovery_link_tag

Returns a link tag that browsers and feed readers can use to auto-detect an RSS,
Atom, or JSON feed.

```ruby
auto_discovery_link_tag(:rss, "http://www.example.com/feed.rss", { title: "RSS Feed" })
# => <link rel="alternate" type="application/rss+xml" title="RSS Feed" href="http://www.example.com/feed.rss" />
```

See the auto_discovery_link_tag API
Documentation
for more information.

### 5.3. favicon_link_tag

Returns a link tag for a favicon managed by the asset pipeline. The source can
be a full path or a file that exists in your assets directory.

```ruby
favicon_link_tag
# => <link href="/assets/favicon.ico" rel="icon" type="image/x-icon" />
```

See the favicon_link_tag API
Documentation
for more information.

### 5.4. image_tag

Returns an HTML image tag for the source. The source can be a full path or a
file that exists in your app/assets/images directory.

```ruby
image_tag("icon.png")
# => <img src="/assets/icon.png" />

image_tag("icon.png", size: "16x10", alt: "Edit Article")
# => <img src="/assets/icon.png" width="16" height="10" alt="Edit Article" />
```

Internally, image_tag uses image_path from the
AssetUrlHelpers
to build the image path.

See the image_tag API
Documentation
for more information.

### 5.5. javascript_include_tag

Returns an HTML script tag for each of the sources provided. You can pass in the
filename (.js extension is optional) of JavaScript files that exist in your
app/assets/javascripts directory for inclusion into the current page, or you
can pass the full path relative to your document root.

```ruby
javascript_include_tag("common")
# => <script src="/assets/common.js"></script>

javascript_include_tag("common", async: true)
# => <script src="/assets/common.js" async="async"></script>
```

Some of the most common attributes are async and defer, where async will
allow the script to be loaded in parallel to be parsed and evaluated as soon as
possible, and defer will indicate that the script is meant to be executed
after the document has been parsed.

Internally, javascript_include_tag uses javascript_path from the
AssetUrlHelpers
to build the script path.

See the javascript_include_tag API
Documentation
for more information.

### 5.6. picture_tag

Returns an HTML picture tag for the source. It supports passing a String, an
Array, or a Block.

```ruby
picture_tag("icon.webp", "icon.png")
```

This generates the following HTML:

```html
<picture>
  <source srcset="/assets/icon.webp" type="image/webp" />
  <source srcset="/assets/icon.png" type="image/png" />
  <img src="/assets/icon.png" />
</picture>
```

See the picture_tag API
Documentation
for more information.

### 5.7. preload_link_tag

Returns a link tag that browsers can use to preload the source. The source can
be the path of a resource managed by the asset pipeline, a full path, or a URI.

```ruby
preload_link_tag("application.css")
# => <link rel="preload" href="/assets/application.css" as="style" type="text/css" />
```

See the preload_link_tag API
Documentation
for more information.

### 5.8. stylesheet_link_tag

Returns a stylesheet link tag for the sources specified as arguments. If you
don't specify an extension, .css will be appended automatically.

```ruby
stylesheet_link_tag("application")
# => <link href="/assets/application.css" rel="stylesheet" />

stylesheet_link_tag("application", media: "all")
# => <link href="/assets/application.css" media="all" rel="stylesheet" />
```

media is used to specify the media type for the link. The most common media
types are all, screen, print, and speech.

Internally, stylesheet_link_tag uses stylesheet_path from the
AssetUrlHelpers
to build the stylesheet path.

See the stylesheet_link_tag API
Documentation
for more information.

### 5.9. video_tag

Generate an HTML video tag with source(s), either as a single tag for a string
source or nested source tags within an array for multiple sources. The sources
can be full paths, files in your public videos directory, or Active Storage
attachments.

```ruby
video_tag("trailer")
# => <video src="/videos/trailer"></video>

video_tag(["trailer.ogg", "trailer.flv"])
# => <video><source src="/videos/trailer.ogg" /><source src="/videos/trailer.flv" /></video>

video_tag("trailer", controls: true)
# => <video controls="controls" src="/videos/trailer"></video>
```

Internally, video_tag uses video_path from the
AssetUrlHelpers
to build the video path.

See the video_tag API
Documentation
for more information.

## 6. JavaScript

A set of methods for working with JavaScript in your views.

### 6.1. escape_javascript

Escapes carriage returns and single and double quotes for JavaScript segments.
You would use this method to take a string of text and make sure that it doesn’t
contain any invalid characters when the browser tries to parse it.

For example, if you have a partial with a greeting that contains double quotes,
you can escape the greeting to use in a JavaScript alert.

```ruby
<%# app/views/users/greeting.html.erb %>
My name is <%= current_user.name %>, and I'm here to say "Welcome to our website!"
```

```ruby
<script>
  var greeting = "<%= escape_javascript render('users/greeting') %>";
  alert(`Hello, ${greeting}`);
</script>
```

This will escape the quotes correctly and display the greeting in an alert box.

See the escape_javascript API
Documentation
for more information.

### 6.2. javascript_tag

Returns a JavaScript tag wrapping the provided code. You can pass a hash of
options to control the behavior of the <script> tag.

```ruby
javascript_tag("alert('All is good')", type: "application/javascript")
```

```html
<script type="application/javascript">
//<![CDATA[
alert('All is good')
//]]>
</script>
```

Instead of passing the content as an argument, you can also use a block.

```ruby
<%= javascript_tag type: "application/javascript" do %>
  alert("Welcome to my app!")
<% end %>
```

See the javascript_tag API
Documentation
for more information.

## 7. Alternative Tags

A set of methods to generate HTML tags programmatically.

### 7.1. tag

Generates a standalone HTML tag with the given name and options.

Every tag can be built with:

```ruby
tag.some_tag_name(optional content, options)
```

where tag name can be e.g. br, div, section, article, or any tag really.

For example, here are some common uses:

```ruby
tag.h1 "All titles fit to print"
# => <h1>All titles fit to print</h1>

tag.div "Hello, world!"
# => <div>Hello, world!</div>
```

Additionally, you can pass options to add attributes to the generated tag.

```ruby
tag.section class: %w( kitties puppies )
# => <section class="kitties puppies"></section>
```

In addition, HTML data-*attributes can be passed to the tag helper using
the data option, with a hash containing key-value pairs of sub-attributes. The
sub-attributes are then converted to data-* attributes that are dasherized in
order to work well with JavaScript.

```ruby
tag.div data: { user_id: 123 }
# => <div data-user-id="123"></div>
```

See the tag API
Documentation
for more information.

### 7.2. token_list

Returns a string of tokens built from the arguments provided. This method is
also aliased as class_names.

```ruby
token_list("cats", "dogs")
# => "cats dogs"

token_list(nil, false, 123, "", "foo", { bar: true })
# => "123 foo bar"

mobile, alignment = true, "center"
token_list("flex items-#{alignment}", "flex-col": mobile)
# => "flex items-center flex-col"
class_names("flex items-#{alignment}", "flex-col": mobile) # using the alias
# => "flex items-center flex-col"
```

## 8. Capture Blocks

A set of methods to let you extract generated markup which can be used in other
parts of a template or layout file.

It provides a method to capture blocks into variables through capture, and a
way to capture a block of markup for use in a layout through content_for.

### 8.1. capture

The capture method allows you to extract part of a template into a variable.

```ruby
<% @greeting = capture do %>
  <p>Welcome! The date and time is <%= Time.current %></p>
<% end %>
```

You can then use this variable anywhere in your templates, layouts, or helpers.

```ruby
<html>
  <head>
    <title>Welcome!</title>
  </head>
  <body>
    <%= @greeting %>
  </body>
</html>
```

The return of capture is the string generated by the block.

```ruby
@greeting
# => "Welcome! The date and time is 2018-09-06 11:09:16 -0500"
```

See the capture API
Documentation
for more information.

### 8.2. content_for

Calling content_for stores a block of markup in an identifier for later use.
You can make subsequent calls to the stored content in other templates, helper
modules or the layout by passing the identifier as an argument to yield.

A common use case is to set the title of a page in a content_for block.

You define a content_for block in the special page's view, and then you
yield it within the layout. For other pages, where the content_for block
isn't utilized, it remains empty, resulting in nothing being yielded.

```ruby
<%# app/views/users/special_page.html.erb %>
<% content_for(:html_title) { "Special Page Title" } %>
```

```ruby
<%# app/views/layouts/application.html.erb %>
<html>
  <head>
    <title><%= content_for?(:html_title) ? yield(:html_title) : "Default Title" %></title>
  </head>
</html>
```

You'll notice that in the above example, we use the content_for? predicate
method to conditionally render a title. This method checks whether any content
has been captured yet using content_for, enabling you to adjust parts of your
layout based on the content within your views.

Additionally, you can employ content_for within a helper module.

```ruby
# app/helpers/title_helper.rb
module TitleHelper
  def html_title
    content_for(:html_title) || "Default Title"
  end
end
```

Now, you can call html_title in your layout to retrieve the content stored in
the content_for block. If a content_for block is set on the page being
rendered, such as in the case of the special_page, it will display the title.
Otherwise, it will display the default text "Default Title".

content_for is ignored in caches. So you shouldn’t use it for
elements that will be fragment cached.

You may be thinking what's the difference between capture and
content_for?
capture is used to capture a block of markup in a variable, while
content_for is used to store a block of markup in an identifier for later use.
Internally content_for actually calls capture. However, the key difference
lies in their behavior when invoked multiple times.
content_for can be called repeatedly, concatenating the blocks it receives for
a specific identifier in the order they are provided. Each subsequent call
simply adds to what's already stored. In contrast, capture only returns the
content of the block, without keeping track of any previous invocations.

See the content_for API
Documentation
for more information.

## 9. Performance

### 9.1. benchmark

Wrap a benchmark block around expensive operations or possible bottlenecks to
get a time reading for the operation.

```ruby
<% benchmark "Process data files" do %>
  <%= expensive_files_operation %>
<% end %>
```

This would add something like Process data files (0.34523) to the log, which
you can then use to compare timings when optimizing your code.

This helper is a part of Active Support, and it is also available on
controllers, helpers, models, etc.

See the benchmark API
Documentation
for more information.

### 9.2. cache

You can cache fragments of a view rather than an entire action or page. This
technique is useful for caching pieces like menus, lists of news topics, static
HTML fragments, and so on. It allows a fragment of view logic to be wrapped in a
cache block and served out of the cache store when the next request comes in.

The cache method takes a block that contains the content you wish to cache.

For example, you could cache the footer of your application layout by wrapping
it in a cache block.

```ruby
<% cache do %>
  <%= render "application/footer" %>
<% end %>
```

You could also cache based on model instances, for example, you can cache each
article on a page by passing the article object to the cache method. This
would cache each article separately.

```ruby
<% @articles.each do |article| %>
  <% cache article do %>
    <%= render article %>
  <% end %>
<% end %>
```

When your application receives its first request to this page, Rails will write
a new cache entry with a unique key. A key looks something like this:

```
views/articles/index:bea67108094918eeba32cd4a6f786301/articles/1
```

See Fragment Caching and the
cache API
Documentation
for more information.

## 10. Miscellaneous

### 10.1. atom_feed

Atom Feeds are XML-based file formats used to syndicate content and can be used
by users in feed readers to browse content or by search engines to help discover
additional information about your site.

This helper makes building an Atom feed easy, and is mostly used in Builder
templates for creating XML. Here's a full usage example:

```ruby
# config/routes.rb
resources :articles
```

```ruby
# app/controllers/articles_controller.rb
def index
  @articles = Article.all

  respond_to do |format|
    format.html
    format.atom
  end
end
```

```ruby
# app/views/articles/index.atom.builder
atom_feed do |feed|
  feed.title("Articles Index")
  feed.updated(@articles.first.created_at)

  @articles.each do |article|
    feed.entry(article) do |entry|
      entry.title(article.title)
      entry.content(article.body, type: "html")

      entry.author do |author|
        author.name(article.author_name)
      end
    end
  end
end
```

See the atom_feed API
Documentation
for more information.

### 10.2. debug

Returns a YAML representation of an object wrapped with a pre tag. This
creates a very readable way to inspect an object.

```ruby
my_hash = { "first" => 1, "second" => "two", "third" => [1, 2, 3] }
debug(my_hash)
```

```html
<pre class="debug_dump">---
first: 1
second: two
third:
- 1
- 2
- 3
</pre>
```

See the debug API
Documentation
for more information.

---

# Chapters

Forms are a common interface for user input in web applications. However, form markup can be tedious to write and maintain because of the need to handle form controls, naming, and attributes. Rails simplifies this by providing view helpers, which are methods that output HTML form markup. This guide will help you understand the different helper methods and when to use each.

After reading this guide, you will know:

- How to create basic forms, such as a search form.

- How to work with model-based forms for creating and editing specific database records.

- How to generate select boxes from multiple types of data.

- What date and time helpers Rails provides.

- What makes a file upload form different.

- How to post forms to external resources and specify setting an authenticity_token.

- How to build complex forms.

This guide is not intended to be a complete list of all available form helpers. Please refer to the Rails API documentation for an exhaustive list of form helpers and their arguments.

## 1. Working with Basic Forms

The main form helper is form_with.

```ruby
<%= form_with do |form| %>
  Form contents
<% end %>
```

When called without arguments, it creates an HTML <form> tag with the value of the method attribute set to post and the value of the action attribute set to the current page. For example, assuming the current page is a home page at /home, the generated HTML will look like this:

```html
<form action="/home" accept-charset="UTF-8" method="post">
  <input type="hidden" name="authenticity_token" value="Lz6ILqUEs2CGdDa-oz38TqcqQORavGnbGkG0CQA8zc8peOps-K7sHgFSTPSkBx89pQxh3p5zPIkjoOTiA_UWbQ" autocomplete="off">
  Form contents
</form>
```

Notice that the form contains an input element with type hidden. This authenticity_token hidden input is required for non-GET form submissions.
This token is a security feature in Rails used to prevent cross-site request forgery (CSRF) attacks, and form helpers automatically generate it for every non-GET form (assuming the security feature is enabled). You can read more about it in the Securing Rails Applications guide.

### 1.1. A Generic Search Form

One of the most basic forms on the web is a search form. This form contains:

- a form element with "GET" method,

- a label for the input,

- a text input element, and

- a submit element.

Here is how to create a search form with form_with:

```ruby
<%= form_with url: "/search", method: :get do |form| %>
  <%= form.label :query, "Search for:" %>
  <%= form.search_field :query %>
  <%= form.submit "Search" %>
<% end %>
```

This will generate the following HTML:

```html
<form action="/search" accept-charset="UTF-8" method="get">
  <label for="query">Search for:</label>
  <input type="search" name="query" id="query">
  <input type="submit" name="commit" value="Search" data-disable-with="Search">
</form>
```

Notice that for the search form we are using the url option of form_with. Setting url: "/search" changes the form action value from the default current page path to action="/search".

In general, passing url: my_path to form_with tells the form where to make the request. The other option is to pass Active Model objects to the form, as you will learn below. You can also use URL helpers.

The search form example above also shows the form builder object. You will learn about the many helpers provided by the form builder object (likeform.label and form.text_field) in the next section.

For every form input element, an id attribute is generated from its name ("query" in above example). These IDs can be very useful for CSS styling or manipulation of form controls with JavaScript.

Use "GET" as the method for search forms. In general, Rails
conventions encourage using the right HTTP verb for controller actions. Using "GET" for
search allows users to bookmark a specific search.

### 1.2. Helpers for Generating Form Elements

The form builder object yielded by form_with provides many helper methods for generating common form elements such as text fields, checkboxes, and radio buttons.

The first argument to these methods is always the name of the input. This is
useful to remember because when the form is submitted, that name will be passed
to the controller along with the form data in the params hash. The name will be the key in the params for the value entered by the user for that field.

For example, if the form contains <%= form.text_field :query %>, then you
would be able to get the value of this field in the controller with
params[:query].

When naming inputs, Rails uses certain conventions that make it possible to submit parameters with non-scalar values such as arrays or hashes, which will also be accessible in params. You can read more about them in the Form Input Naming Conventions and Params Hash section of this guide. For details on the precise usage of these helpers, please refer to the API documentation.

#### 1.2.1. Checkboxes

A Checkbox is a form control that allows for a single value to be selected or deselected. A group of Checkboxes is generally used to allow a user to choose one or more options from the group.

Here's an example with three checkboxes in a form:

```ruby
<%= form.checkbox :biography %>
<%= form.label :biography, "Biography" %>
<%= form.checkbox :romance %>
<%= form.label :romance, "Romance" %>
<%= form.checkbox :mystery %>
<%= form.label :mystery, "Mystery" %>
```

The above will generate the following:

```html
<input name="biography" type="hidden" value="0" autocomplete="off"><input type="checkbox" value="1" name="biography" id="biography">
<label for="biography">Biography</label>
<input name="romance" type="hidden" value="0" autocomplete="off"><input type="checkbox" value="1" name="romance" id="romance">
<label for="romance">Romance</label>
<input name="mystery" type="hidden" value="0" autocomplete="off"><input type="checkbox" value="1" name="mystery" id="mystery">
<label for="mystery">Mystery</label>
```

The first parameter to checkbox is the name of the input which can be found in the params hash. If the user has checked the "Biography" checkbox only, the params hash would contain:

```ruby
{
  "biography" => "1",
  "romance" => "0",
  "mystery" => "0"
}
```

You can use params[:biography] to check if that checkbox is selected by the user.

The checkbox's values (the values that will appear in params) can optionally be specified using the checked_value and unchecked_value parameters. See the API documentation for more details.

There is also a collection_checkboxes, which you can learn about in the Collection Related Helpers section.

#### 1.2.2. Radio Buttons

Radio buttons are form controls that only allow the user to select one option at a time from the list of choices.

For example, radio buttons for choosing your favorite ice cream flavor:

```ruby
<%= form.radio_button :flavor, "chocolate_chip" %>
<%= form.label :flavor_chocolate_chip, "Chocolate Chip" %>
<%= form.radio_button :flavor, "vanilla" %>
<%= form.label :flavor_vanilla, "Vanilla" %>
<%= form.radio_button :flavor, "hazelnut" %>
<%= form.label :flavor_hazelnut, "Hazelnut" %>
```

The above will generate the following HTML:

```html
<input type="radio" value="chocolate_chip" name="flavor" id="flavor_chocolate_chip">
<label for="flavor_chocolate_chip">Chocolate Chip</label>
<input type="radio" value="vanilla" name="flavor" id="flavor_vanilla">
<label for="flavor_vanilla">Vanilla</label>
<input type="radio" value="hazelnut" name="flavor" id="flavor_hazelnut">
<label for="flavor_hazelnut">Hazelnut</label>
```

The second argument to radio_button is the value of the input. Because these radio buttons share the same name (flavor), the user will only be able to select one of them, and params[:flavor] will contain either "chocolate_chip", "vanilla", or hazelnut.

Always use labels for checkbox and radio buttons. They associate text with
a specific option using the for attribute and, by expanding the clickable
region, make it easier for users to click the inputs.

### 1.3. Other Helpers of Interest

There are many other form controls including text, email, password, date, and time. The below examples show some more helpers and their generated HTML.

Date and time related helpers:

```ruby
<%= form.date_field :born_on %>
<%= form.time_field :started_at %>
<%= form.datetime_local_field :graduation_day %>
<%= form.month_field :birthday_month %>
<%= form.week_field :birthday_week %>
```

Output:

```html
<input type="date" name="born_on" id="born_on">
<input type="time" name="started_at" id="started_at">
<input type="datetime-local" name="graduation_day" id="graduation_day">
<input type="month" name="birthday_month" id="birthday_month">
<input type="week" name="birthday_week" id="birthday_week">
```

Helpers with special formatting:

```ruby
<%= form.password_field :password %>
<%= form.email_field :address %>
<%= form.telephone_field :phone %>
<%= form.url_field :homepage %>
```

Output:

```html
<input type="password" name="password" id="password">
<input type="email" name="address" id="address">
<input type="tel" name="phone" id="phone">
<input type="url" name="homepage" id="homepage">
```

Other common helpers:

```ruby
<%= form.textarea :message, size: "70x5" %>
<%= form.hidden_field :parent_id, value: "foo" %>
<%= form.number_field :price, in: 1.0..20.0, step: 0.5 %>
<%= form.range_field :discount, in: 1..100 %>
<%= form.search_field :name %>
<%= form.color_field :favorite_color %>
```

Output:

```html
<textarea name="message" id="message" cols="70" rows="5"></textarea>
<input value="foo" autocomplete="off" type="hidden" name="parent_id" id="parent_id">
<input step="0.5" min="1.0" max="20.0" type="number" name="price" id="price">
<input min="1" max="100" type="range" name="discount" id="discount">
<input type="search" name="name" id="name">
<input value="#000000" type="color" name="favorite_color" id="favorite_color">
```

Hidden inputs are not shown to the user but instead hold data like any textual input. Values inside them can be changed with JavaScript.

If you're using password input fields, you might want to configure your application to prevent those parameters from being logged. You can learn about how in the Securing Rails Applications guide.

## 2. Creating Forms with Model Objects

### 2.1. Binding a Form to an Object

The form_with helper has a :model option that allows you to bind the form builder object to a model object. This means that the form will be scoped to that model object, and the form's fields will be populated with values from that model object.

For example, if we have a @book model object:

```ruby
@book = Book.new
# => #<Book id: nil, title: nil, author: nil>
```

And the following form to create a new book:

```ruby
<%= form_with model: @book do |form| %>
  <div>
    <%= form.label :title %>
    <%= form.text_field :title %>
  </div>
  <div>
    <%= form.label :author %>
    <%= form.text_field :author %>
  </div>
  <%= form.submit %>
<% end %>
```

It will generate this HTML:

```html
<form action="/books" accept-charset="UTF-8" method="post">
  <input type="hidden" name="authenticity_token" value="ChwHeyegcpAFDdBvXvDuvbfW7yCA3e8gvhyieai7DhG28C3akh-dyuv-IBittsjPrIjETlQQvQJ91T77QQ8xWA" autocomplete="off">
  <div>
    <label for="book_title">Title</label>
    <input type="text" name="book[title]" id="book_title">
  </div>
  <div>
    <label for="book_author">Author</label>
    <input type="text" name="book[author]" id="book_author">
  </div>
  <input type="submit" name="commit" value="Create Book" data-disable-with="Create Book">
</form>
```

Some important things to notice when using form_with with a model object:

- The form action is automatically filled with an appropriate value, action="/books". If you were updating a book, it would be action="/books/42".

- The form field names are scoped with book[...]. This means that params[:book] will be a hash containing all these field's values. You can read more about the significance of input names in chapter Form Input Naming Conventions and Params Hash of this guide.

- The submit button is automatically given an appropriate text value, "Create Book" in this case.

Typically your form inputs will mirror model attributes. However, they don't have to. If there is other information you need you can include a field in your form and access it via params[:book][:my_non_attribute_input].

#### 2.1.1. Composite Primary Key Forms

If you have a model with a composite primary key, the form building syntax is the same with slightly different output.

For example, to update a @book model object with a composite key [:author_id, :id] like this:

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

Will generate this HTML output:

```html
<form action="/books/2_25" method="post" accept-charset="UTF-8" >
  <input name="authenticity_token" type="hidden" value="ChwHeyegcpAFDdBvXvDuvbfW7yCA3e8gvhyieai7DhG28C3akh-dyuv-IBittsjPrIjETlQQvQJ91T77QQ8xWA" />
  <input type="text" name="book[title]" id="book_title" value="Some book" />
  <input type="submit" name="commit" value="Update Book" data-disable-with="Update Book">
</form>
```

Note the generated URL contains the author_id and id delimited by an
underscore. Once submitted, the controller can extract each primary key
value from the parameters and update the record as it would with a singular
primary key.

#### 2.1.2. The fields_for Helper

The fields_for helper is used to render fields for related model objects
within the same form. The associated "inner" model is usually related to the
"main" form model via an Active Record association. For example, if you had a
Person model with an associated ContactDetail model, you could create a
single form with inputs for both models like so:

```ruby
<%= form_with model: @person do |person_form| %>
  <%= person_form.text_field :name %>
  <%= fields_for :contact_detail, @person.contact_detail do |contact_detail_form| %>
    <%= contact_detail_form.text_field :phone_number %>
  <% end %>
<% end %>
```

The above will produce the following output:

```html
<form action="/people" accept-charset="UTF-8" method="post">
  <input type="hidden" name="authenticity_token" value="..." autocomplete="off" />
  <input type="text" name="person[name]" id="person_name" />
  <input type="text" name="contact_detail[phone_number]" id="contact_detail_phone_number" />
</form>
```

The object yielded by fields_for is a form builder like the one yielded by
form_with. The fields_for helper creates a similar binding but without
rendering a <form> tag. You can learn more about fields_for in the API
docs.

### 2.2. Relying on Record Identification

When dealing with RESTful resources, calls to form_with can be simplified by relying on record identification. This means you pass the model instance and have Rails figure out the model name, method, and other things. In the example below for creating a new record, both calls to form_with generate the same HTML:

```ruby
# longer way:
form_with(model: @article, url: articles_path)
# short-hand:
form_with(model: @article)
```

Similarly, for editing an existing article like below, both the calls to form_with will also generate the same HTML:

```ruby
# longer way:
form_with(model: @article, url: article_path(@article), method: "patch")
# short-hand:
form_with(model: @article)
```

Notice how the short-hand form_with invocation is conveniently the same, regardless of the record being new or existing. Record identification is smart enough to figure out if the record is new by asking record.persisted?. It also selects the correct path to submit to, and the name based on the class of the object.

This is assuming that the Article model is declared with resources :articles in the routes file.

If you have a singular resource, you will need to call resource and resolve for it to work with form_with:

```ruby
resource :article
resolve("Article") { [:article] }
```

Declaring a resource has a number of side effects. See the Rails Routing from the Outside In guide for more information on setting up and using resources.

When you're using single-table inheritance with your models, you can't rely on record identification on a subclass if only their parent class is declared a resource. You will have to specify :url, and :scope (the model name) explicitly.

### 2.3. Working with Namespaces

If you have namespaced routes, form_with has a shorthand for that. For example, if your application has an admin namespace:

```ruby
form_with model: [:admin, @article]
```

The above will create a form that submits to the Admin::ArticlesController inside the admin namespace,  therefore submitting to admin_article_path(@article) in the case of an update.

If you have several levels of namespacing then the syntax is similar:

```ruby
form_with model: [:admin, :management, @article]
```

For more information on Rails' routing system and the associated conventions, please see the Rails Routing from the Outside In guide.

### 2.4. Forms with PATCH, PUT, or DELETE Methods

The Rails framework encourages RESTful design, which means forms in your application will make requests where the method is PATCH, PUT, or DELETE in addition to GET and POST. However, HTML forms don't support methods other than GET and POST when it comes to submitting forms.

Rails works around this limitation by emulating other methods over POST with a hidden input named "_method". For example:

```ruby
form_with(url: search_path, method: "patch")
```

The above form Will generate this HTML output:

```html
<form action="/search" accept-charset="UTF-8" method="post">
  <input type="hidden" name="_method" value="patch" autocomplete="off">
  <input type="hidden" name="authenticity_token" value="R4quRuXQAq75TyWpSf8AwRyLt-R1uMtPP1dHTTWJE5zbukiaY8poSTXxq3Z7uAjXfPHiKQDsWE1i2_-h0HSktQ" autocomplete="off">
<!-- ... -->
</form>
```

When parsing POSTed data, Rails will take into account the special _method parameter and proceed as if the request's HTTP method was the one set as the value of_method (PATCH in this example).

When rendering a form, submission buttons can override the declared method attribute through the formmethod: keyword:

```ruby
<%= form_with url: "/posts/1", method: :patch do |form| %>
  <%= form.button "Delete", formmethod: :delete, data: { confirm: "Are you sure?" } %>
  <%= form.button "Update" %>
<% end %>
```

Similar to <form> elements, most browsers don't support overriding form methods declared through formmethod other than GET and POST.

Rails works around this issue by emulating other methods over POST through a combination of formmethod, value, and name attributes:

```html
<form accept-charset="UTF-8" action="/posts/1" method="post">
  <input name="_method" type="hidden" value="patch" />
  <input name="authenticity_token" type="hidden" value="f755bb0ed134b76c432144748a6d4b7a7ddf2b71" />
  <!-- ... -->

  <button type="submit" formmethod="post" name="_method" value="delete" data-confirm="Are you sure?">Delete</button>
  <button type="submit" name="button">Update</button>
</form>
```

In this case, the "Update" button will be treated as PATCH and the "Delete" button will be treated as DELETE.

## 3. Making Select Boxes with Ease

Select boxes, also known as drop-down list, allow users to select from a list of options. The HTML for select boxes requires a decent amount of markup - one <option> element for each option to choose from. Rails provides helper methods to help generate that markup.

For example, let's say we have a list of cities for the user to choose from. We can use the select helper:

```ruby
<%= form.select :city, ["Berlin", "Chicago", "Madrid"] %>
```

The above will generate this HTML output:

```html
<select name="city" id="city">
  <option value="Berlin">Berlin</option>
  <option value="Chicago">Chicago</option>
  <option value="Madrid">Madrid</option>
</select>
```

And the selection will be available in params[:city] as usual.

We can also specify <option> values that differ from their labels:

```ruby
<%= form.select :city, [["Berlin", "BE"], ["Chicago", "CHI"], ["Madrid", "MD"]] %>
```

Output:

```html
<select name="city" id="city">
  <option value="BE">Berlin</option>
  <option value="CHI">Chicago</option>
  <option value="MD">Madrid</option>
</select>
```

This way, the user will see the full city name, but params[:city] will be one of "BE", "CHI", or "MD".

Lastly, we can specify a default choice for the select box with the :selected argument:

```ruby
<%= form.select :city, [["Berlin", "BE"], ["Chicago", "CHI"], ["Madrid", "MD"]], selected: "CHI" %>
```

Output:

```html
<select name="city" id="city">
  <option value="BE">Berlin</option>
  <option value="CHI" selected="selected">Chicago</option>
  <option value="MD">Madrid</option>
</select>
```

### 3.1. Option Groups for Select Boxes

In some cases we may want to improve the user experience by grouping related options together. We can do so by passing a Hash (or comparable Array) to select:

```ruby
<%= form.select :city,
      {
        "Europe" => [ ["Berlin", "BE"], ["Madrid", "MD"] ],
        "North America" => [ ["Chicago", "CHI"] ],
      },
      selected: "CHI" %>
```

Output:

```html
<select name="city" id="city">
  <optgroup label="Europe">
    <option value="BE">Berlin</option>
    <option value="MD">Madrid</option>
  </optgroup>
  <optgroup label="North America">
    <option value="CHI" selected="selected">Chicago</option>
  </optgroup>
</select>
```

### 3.2. Binding Select Boxes to Model Objects

Like other form controls, a select box can be bound to a model attribute. For example, if we have a @person model object like:

```ruby
@person = Person.new(city: "MD")
```

The following form:

```ruby
<%= form_with model: @person do |form| %>
  <%= form.select :city, [["Berlin", "BE"], ["Chicago", "CHI"], ["Madrid", "MD"]] %>
<% end %>
```

Will output this select box:

```html
<select name="person[city]" id="person_city">
  <option value="BE">Berlin</option>
  <option value="CHI">Chicago</option>
  <option value="MD" selected="selected">Madrid</option>
</select>
```

The only difference is that the selected option will be found in params[:person][:city] instead of params[:city].

Notice that the appropriate option was automatically marked selected="selected". Since this select box was bound to an existing @person record, we didn't need to specify a :selected argument.

## 4. Using Date and Time Form Helpers

In addition to the date_field and time_field helpers mentioned earlier, Rails provides alternative date and time form helpers that render plain select boxes. The date_select helper renders a separate select box for year, month, and day.

For example, if we have a @person model object like:

```ruby
@person = Person.new(birth_date: Date.new(1995, 12, 21))
```

The following form:

```ruby
<%= form_with model: @person do |form| %>
  <%= form.date_select :birth_date %>
<% end %>
```

Will output select boxes like:

```html
<select name="person[birth_date(1i)]" id="person_birth_date_1i">
  <option value="1990">1990</option>
  <option value="1991">1991</option>
  <option value="1992">1992</option>
  <option value="1993">1993</option>
  <option value="1994">1994</option>
  <option value="1995" selected="selected">1995</option>
  <option value="1996">1996</option>
  <option value="1997">1997</option>
  <option value="1998">1998</option>
  <option value="1999">1999</option>
  <option value="2000">2000</option>
</select>
<select name="person[birth_date(2i)]" id="person_birth_date_2i">
  <option value="1">January</option>
  <option value="2">February</option>
  <option value="3">March</option>
  <option value="4">April</option>
  <option value="5">May</option>
  <option value="6">June</option>
  <option value="7">July</option>
  <option value="8">August</option>
  <option value="9">September</option>
  <option value="10">October</option>
  <option value="11">November</option>
  <option value="12" selected="selected">December</option>
</select>
<select name="person[birth_date(3i)]" id="person_birth_date_3i">
  <option value="1">1</option>
  ...
  <option value="21" selected="selected">21</option>
  ...
  <option value="31">31</option>
</select>
```

Notice that, when the form is submitted, there will be no single value in the params hash that contains the full date. Instead, there will be several values with special names like "birth_date(1i)". However, Active Model knows how to assemble these values into a full date, based on the declared type of the model attribute. So we can pass params[:person] to Person.new or Person#update just like we would if the form used a single field to represent the full date.

In addition to the date_select helper, Rails provides time_select which outputs select boxes for the hour and minute. There is datetime_select as well which combines both date and time select boxes.

### 4.1. Select Boxes for Time or Date Components

Rails also provides helpers to render select boxes for individual date and time components: select_year, select_month, select_day, select_hour, select_minute, and select_second.  These helpers are "bare" methods, meaning they are not called on a form builder instance.  For example:

```ruby
<%= select_year 2024, prefix: "party" %>
```

The above outputs a select box like:

```html
<select id="party_year" name="party[year]">
  <option value="2019">2019</option>
  <option value="2020">2020</option>
  <option value="2021">2021</option>
  <option value="2022">2022</option>
  <option value="2023">2023</option>
  <option value="2024" selected="selected">2024</option>
  <option value="2025">2025</option>
  <option value="2026">2026</option>
  <option value="2027">2027</option>
  <option value="2028">2028</option>
  <option value="2029">2029</option>
</select>
```

For each of these helpers, you may specify a Date or Time object instead of a number as the default value (for example <%= select_year Date.today, prefix: "party" %> instead of the above), and the appropriate date and time parts will be extracted and used.

### 4.2. Selecting Time Zone

When you need to ask users what time zone they are in, there is a very convenient time_zone_select helper to use.

Typically, you would have to provide a list of time zone options for users to select from. This can get tedious if not for the list of pre-defined ActiveSupport::TimeZone objects. The time_with_zone helper wraps this and can be used as follows:

```ruby
<%= form.time_zone_select :time_zone %>
```

Output:

```html
<select name="time_zone" id="time_zone">
  <option value="International Date Line West">(GMT-12:00) International Date Line West</option>
  <option value="American Samoa">(GMT-11:00) American Samoa</option>
  <option value="Midway Island">(GMT-11:00) Midway Island</option>
  <option value="Hawaii">(GMT-10:00) Hawaii</option>
  <option value="Alaska">(GMT-09:00) Alaska</option>
  ...
  <option value="Samoa">(GMT+13:00) Samoa</option>
  <option value="Tokelau Is.">(GMT+13:00) Tokelau Is.</option>
</select>
```

## 5. Collection Related Helpers

If you need to generate a set of choices from a collection of arbitrary objects, Rails has collection_select, collection_radio_button, and collection_checkboxes helpers.

To see when these helpers are useful, suppose you have a City model and corresponding belongs_to :city association with Person:

```ruby
class City < ApplicationRecord
end

class Person < ApplicationRecord
  belongs_to :city
end
```

Assuming we have the following cities stored in the database:

```ruby
City.order(:name).map { |city| [city.name, city.id] }
# => [["Berlin", 1], ["Chicago", 3], ["Madrid", 2]]
```

We can allow the user to choose from the cities with the following form:

```ruby
<%= form_with model: @person do |form| %>
  <%= form.select :city_id, City.order(:name).map { |city| [city.name, city.id] } %>
<% end %>
```

The above will generate this HTML:

```html
<select name="person[city_id]" id="person_city_id">
  <option value="1">Berlin</option>
  <option value="3">Chicago</option>
  <option value="2">Madrid</option>
</select>
```

The above example shows how you'd generate the choices manually. However, Rails has helpers that generate choices from a collection without having to explicitly iterate over it. These helpers determine the value and text label of each choice by calling specified methods on each object in the collection.

When rendering a field for a belongs_to association, you must specify the name of the foreign key (city_id in the above example), rather than the name of the association itself.

### 5.1. The collection_select Helper

To generate a select box, we can use collection_select:

```ruby
<%= form.collection_select :city_id, City.order(:name), :id, :name %>
```

The above outputs the same HTML as the manual iteration above:

```html
<select name="person[city_id]" id="person_city_id">
  <option value="1">Berlin</option>
  <option value="3">Chicago</option>
  <option value="2">Madrid</option>
</select>
```

The order of arguments for collection_select is different from the order for select. With collection_select we specify the value method first (:id in the example above), and the text label method second (:name in the example above).  This is opposite of the order used when specifying choices for the select helper, where the text label comes first and the value second (["Berlin", 1] in the previous example).

### 5.2. The collection_radio_buttons Helper

To generate a set of radio buttons, we can use collection_radio_buttons:

```ruby
<%= form.collection_radio_buttons :city_id, City.order(:name), :id, :name %>
```

Output:

```html
<input type="radio" value="1" name="person[city_id]" id="person_city_id_1">
<label for="person_city_id_1">Berlin</label>

<input type="radio" value="3" name="person[city_id]" id="person_city_id_3">
<label for="person_city_id_3">Chicago</label>

<input type="radio" value="2" name="person[city_id]" id="person_city_id_2">
<label for="person_city_id_2">Madrid</label>
```

### 5.3. The collection_checkboxes Helper

To generate a set of check boxes — for example, to support a has_and_belongs_to_many association — we can use collection_checkboxes:

```ruby
<%= form.collection_checkboxes :interest_ids, Interest.order(:name), :id, :name %>
```

Output:

```html
<input type="checkbox" name="person[interest_id][]" value="3" id="person_interest_id_3">
<label for="person_interest_id_3">Engineering</label>

<input type="checkbox" name="person[interest_id][]" value="4" id="person_interest_id_4">
<label for="person_interest_id_4">Math</label>

<input type="checkbox" name="person[interest_id][]" value="1" id="person_interest_id_1">
<label for="person_interest_id_1">Science</label>

<input type="checkbox" name="person[interest_id][]" value="2" id="person_interest_id_2">
<label for="person_interest_id_2">Technology</label>
```

## 6. Uploading Files

A common task with forms is allowing users to upload a file. It could be an avatar image or a CSV file with data to process. File upload fields can be rendered with the file_field helper.

```ruby
<%= form_with model: @person do |form| %>
  <%= form.file_field :csv_file %>
<% end %>
```

The most important thing to remember with file uploads is that the rendered form's enctype attribute must be set to multipart/form-data. This is done automatically if you use a file_field inside a form_with. You can also set the attribute manually:

```ruby
<%= form_with url: "/uploads", multipart: true do |form| %>
  <%= file_field_tag :csv_file %>
<% end %>
```

Both of which, output the following HTML form:

```html
<form enctype="multipart/form-data" action="/people" accept-charset="UTF-8" method="post">
<!-- ... -->
</form>
```

Note that, per form_with conventions, the field names in the two forms above will be different. In the first form, it will be person[csv_file] (accessible via params[:person][:csv_file]), and in the second form it will be just csv_file (accessible via params[:csv_file]).

### 6.1. CSV File Upload Example

When using file_field, the object in the params hash is an instance of ActionDispatch::Http::UploadedFile. Here is an example of how to save data in an uploaded CSV file to records in your application:

```ruby
require "csv"

  def upload
    uploaded_file = params[:csv_file]
    if uploaded_file.present?
      csv_data = CSV.parse(uploaded_file.read, headers: true)
      csv_data.each do |row|
        # Process each row of the CSV file
        # SomeInvoiceModel.create(amount: row['Amount'], status: row['Status'])
        Rails.logger.info row.inspect
        #<CSV::Row "id":"po_1KE3FRDSYPMwkcNz9SFKuaYd" "Amount":"96.22" "Created (UTC)":"2022-01-04 02:59" "Arrival Date (UTC)":"2022-01-05 00:00" "Status":"paid">
      end
    end
    # ...
  end
```

If the file is an image that needs to be stored with a model (e.g. user's profile picture), there are a number of tasks to consider, like where to store the file (on Disk, Amazon S3, etc), resizing image files, and generating thumbnails, etc. Active Storage is designed to assist with these tasks.

## 7. Customizing Form Builders

We call the objects yielded by form_with or fields_for Form Builders. Form builders allow you to generate form elements associated with a model object
and are an instance of
ActionView::Helpers::FormBuilder. This class can be extended to add custom helpers for your application.

For example, if you want to display a text_field along with a label across your application, you could add the following helper method to application_helper.rb:

```ruby
module ApplicationHelper
  def text_field_with_label(form, attribute)
    form.label(attribute) + form.text_field(attribute)
  end
end
```

And use it in a form as usual:

```ruby
<%= form_with model: @person do |form| %>
  <%= text_field_with_label form, :first_name %>
<% end %>
```

But you can also create a subclass of ActionView::Helpers::FormBuilder, and
add the helpers there. After defining this LabellingFormBuilder subclass:

```ruby
class LabellingFormBuilder < ActionView::Helpers::FormBuilder
  def text_field(attribute, options = {})
    # super will call the original text_field method
    label(attribute) + super
  end
end
```

The above form can be replaced with:

```ruby
<%= form_with model: @person, builder: LabellingFormBuilder do |form| %>
  <%= form.text_field :first_name %>
<% end %>
```

If you reuse this frequently you could define a labeled_form_with helper that automatically applies the builder: LabellingFormBuilder option:

```ruby
module ApplicationHelper
  def labeled_form_with(**options, &block)
    options[:builder] = LabellingFormBuilder
    form_with(**options, &block)
  end
end
```

The above can be used instead of form_with:

```ruby
<%= labeled_form_with model: @person do |form| %>
  <%= form.text_field :first_name %>
<% end %>
```

All three cases above (the text_field_with_label helper, the LabellingFormBuilder subclass, and the labeled_form_with helper) will generate the same HTML output:

```html
<form action="/people" accept-charset="UTF-8" method="post">
  <!-- ... -->
  <label for="person_first_name">First name</label>
  <input type="text" name="person[first_name]" id="person_first_name">
</form>
```

The form builder used also determines what happens when you do:

```ruby
<%= render partial: f %>
```

If f is an instance of ActionView::Helpers::FormBuilder, then this will render the form partial, setting the partial's object to the form builder. If the form builder is of class LabellingFormBuilder, then the labelling_form partial would be rendered instead.

Form builder customizations, such as LabellingFormBuilder, do hide the implementation details (and may seem like an overkill for the simple example above). Choose between different customizations, extending FormBuilder class or creating helpers, based on how frequently your forms use the custom elements.

## 8. Form Input Naming Conventions and params Hash

All of the form helpers described above help with generating the HTML for form elements so that the user can enter various types of input. How do you access the user input values in the Controller? The params hash is the answer. You've already seen the params hash in the above example. This section will more explicitly go over naming conventions around how form input is structured in the params hash.

The params hash can contain arrays and arrays of hashes. Values can be at the top level of the params hash or nested in another hash. For example, in a standard create action for a Person model, params[:person] will be a hash of all the attributes for the Person object.

Note that HTML forms don't have an inherent structure to the user input data, all they generate is name-value string pairs. The arrays and hashes you see in your application are the result of parameter naming conventions that Rails uses.

The fields in the params hash need to be permitted in the controller.

### 8.1. Basic Structure

The two basic structures for user input form data are arrays and hashes.

Hashes mirror the syntax used for accessing the value in params. For example, if a form contains:

```html
<input id="person_name" name="person[name]" type="text" value="Henry"/>
```

the params hash will contain

```ruby
{ "person" => { "name" => "Henry" } }
```

and params[:person][:name] will retrieve the submitted value in the controller.

Hashes can be nested as many levels as required, for example:

```html
<input id="person_address_city" name="person[address][city]" type="text" value="New York"/>
```

The above will result in the params hash being

```ruby
{ "person" => { "address" => { "city" => "New York" } } }
```

The other structure is an Array. Normally Rails ignores duplicate parameter names, but if the parameter name ends with an empty set of square brackets [] then the parameters will be accumulated in an Array.

For example, if you want users to be able to input multiple phone numbers, you could place this in the form:

```html
<input name="person[phone_number][]" type="text"/>
<input name="person[phone_number][]" type="text"/>
<input name="person[phone_number][]" type="text"/>
```

This would result in params[:person][:phone_number] being an array containing the submitted phone numbers:

```ruby
{ "person" => { "phone_number" => ["555-0123", "555-0124", "555-0125"] } }
```

### 8.2. Combining Arrays and Hashes

You can mix and match these two concepts. One element of a hash might be an array as in the previous example params[:person] hash has a key called [:phone_number] whose value is an array.

You also can have an array of hashes. For example, you can create any number of addresses by repeating the following form fragment:

```html
<input name="person[addresses][][line1]" type="text"/>
<input name="person[addresses][][line2]" type="text"/>
<input name="person[addresses][][city]" type="text"/>
<input name="person[addresses][][line1]" type="text"/>
<input name="person[addresses][][line2]" type="text"/>
<input name="person[addresses][][city]" type="text"/>
```

This would result in params[:person][:addresses] being an array of hashes. Each hash in the array will have the keys line1, line2, and city, something like this:

```ruby
{ "person" =>
  { "addresses" => [
    { "line1" => "1000 Fifth Avenue",
      "line2" => "",
      "city" => "New York"
    },
    { "line1" => "Calle de Ruiz de Alarcón",
      "line2" => "",
      "city" => "Madrid"
    }
    ]
  }
}
```

It's important to note that while hashes can be nested arbitrarily, only one level of "arrayness" is allowed. Arrays can usually be replaced by hashes. For example, instead of an array of model objects, you can have a hash of model objects keyed by their id or similar.

Array parameters do not play well with the checkbox helper. According to the HTML specification unchecked checkboxes submit no value. However it is often convenient for a checkbox to always submit a value. The checkbox helper fakes this by creating an auxiliary hidden input with the same name. If the checkbox is unchecked only the hidden input is submitted. If it is checked then both are submitted but the value submitted by the checkbox takes precedence. There is a include_hidden option that can be set to false if you want to omit this hidden field. By default, this option is true.

### 8.3. Hashes with an Index

Let's say you want to render a form with a set of fields for each of a person's
addresses. The fields_for helper with its :index option can assist:

```ruby
<%= form_with model: @person do |person_form| %>
  <%= person_form.text_field :name %>
  <% @person.addresses.each do |address| %>
    <%= person_form.fields_for address, index: address.id do |address_form| %>
      <%= address_form.text_field :city %>
    <% end %>
  <% end %>
<% end %>
```

Assuming the person has two addresses with IDs 23 and 45, the above form would
render this output:

```html
<form accept-charset="UTF-8" action="/people/1" method="post">
  <input name="_method" type="hidden" value="patch" />
  <input id="person_name" name="person[name]" type="text" />
  <input id="person_address_23_city" name="person[address][23][city]" type="text" />
  <input id="person_address_45_city" name="person[address][45][city]" type="text" />
</form>
```

Which will result in a params hash that looks like:

```ruby
{
  "person" => {
    "name" => "Bob",
    "address" => {
      "23" => {
        "city" => "Paris"
      },
      "45" => {
        "city" => "London"
      }
    }
  }
}
```

All of the form inputs map to the "person" hash because we called fields_for
on the person_form form builder. Also, by specifying index: address.id, we
rendered the name attribute of each city input as
person[address][#{address.id}][city] instead of person[address][city]. This
way you can tell which Address records should be modified when processing the
params hash.

You can find more details about fields_for index option in the API docs.

## 9. Building Complex Forms

As your application grows, you may need to create more complex forms, beyond editing a single object. For example, when creating a Person you can allow the user to create multiple Address records (home, work, etc.) within the same form. When editing a Person record later, the user should be able to add, remove, or update addresses as well.

### 9.1. Configuring the Model for Nested Attributes

For editing an associated record for a given model (Person in this case), Active Record provides model level support via the accepts_nested_attributes_for method:

```ruby
class Person < ApplicationRecord
  has_many :addresses, inverse_of: :person
  accepts_nested_attributes_for :addresses
end

class Address < ApplicationRecord
  belongs_to :person
end
```

This creates an addresses_attributes= method on Person that allows you to create, update, and destroy addresses.

### 9.2. Nested Forms in the View

The following form allows a user to create a Person and its associated addresses.

```ruby
<%= form_with model: @person do |form| %>
  Addresses:
  <ul>
    <%= form.fields_for :addresses do |addresses_form| %>
      <li>
        <%= addresses_form.label :kind %>
        <%= addresses_form.text_field :kind %>

        <%= addresses_form.label :street %>
        <%= addresses_form.text_field :street %>
        ...
      </li>
    <% end %>
  </ul>
<% end %>
```

When an association accepts nested attributes, fields_for renders its block once for every element of the association. In particular, if a person has no addresses, it renders nothing.

A common pattern is for the controller to build one or more empty children so that at least one set of fields is shown to the user. The example below would result in 2 sets of address fields being rendered on the new person form.

For example, the above form_with with this change:

```ruby
def new
  @person = Person.new
  2.times { @person.addresses.build }
end
```

Will output the following HTML:

```html
<form action="/people" accept-charset="UTF-8" method="post"><input type="hidden" name="authenticity_token" value="lWTbg-4_5i4rNe6ygRFowjDfTj7uf-6UPFQnsL7H9U9Fe2GGUho5PuOxfcohgm2Z-By3veuXwcwDIl-MLdwFRg" autocomplete="off">
  Addresses:
  <ul>
      <li>
        <label for="person_addresses_attributes_0_kind">Kind</label>
        <input type="text" name="person[addresses_attributes][0][kind]" id="person_addresses_attributes_0_kind">

        <label for="person_addresses_attributes_0_street">Street</label>
        <input type="text" name="person[addresses_attributes][0][street]" id="person_addresses_attributes_0_street">
        ...
      </li>

      <li>
        <label for="person_addresses_attributes_1_kind">Kind</label>
        <input type="text" name="person[addresses_attributes][1][kind]" id="person_addresses_attributes_1_kind">

        <label for="person_addresses_attributes_1_street">Street</label>
        <input type="text" name="person[addresses_attributes][1][street]" id="person_addresses_attributes_1_street">
        ...
      </li>
  </ul>
</form>
```

The fields_for yields a form builder. The parameter names will be what
accepts_nested_attributes_for expects. For example, when creating a person
with 2 addresses, the submitted parameters in params would look like this:

```ruby
{
  "person" => {
    "name" => "John Doe",
    "addresses_attributes" => {
      "0" => {
        "kind" => "Home",
        "street" => "221b Baker Street"
      },
      "1" => {
        "kind" => "Office",
        "street" => "31 Spooner Street"
      }
    }
  }
}
```

The actual value of the keys in the :addresses_attributes hash is not important. But they need to be strings of integers and different for each address.

If the associated object is already saved, fields_for autogenerates a hidden input with the id of the saved record. You can disable this by passing include_id: false to fields_for.

```ruby
{
  "person" => {
    "name" => "John Doe",
    "addresses_attributes" => {
      "0" => {
        "id" => 1,
        "kind" => "Home",
        "street" => "221b Baker Street"
      },
      "1" => {
        "id" => "2",
        "kind" => "Office",
        "street" => "31 Spooner Street"
      }
    }
  }
}
```

### 9.3. Permitting Parameters in the Controller

As usual you need to declare the permitted
parameters in the controller
before you pass them to the model:

```ruby
def create
  @person = Person.new(person_params)
  # ...
end

private
  def person_params
    params.expect(person: [ :name, addresses_attributes: [[ :id, :kind, :street ]] ])
  end
```

### 9.4. Removing Associated Objects

You can allow users to delete associated objects by passing allow_destroy: true to accepts_nested_attributes_for

```ruby
class Person < ApplicationRecord
  has_many :addresses
  accepts_nested_attributes_for :addresses, allow_destroy: true
end
```

If the hash of attributes for an object contains the key _destroy with a value
that evaluates to true (e.g. 1, '1', true, or 'true') then the object will be
destroyed. This form allows users to remove addresses:

```ruby
<%= form_with model: @person do |form| %>
  Addresses:
  <ul>
    <%= form.fields_for :addresses do |addresses_form| %>
      <li>
        <%= addresses_form.checkbox :_destroy %>
        <%= addresses_form.label :kind %>
        <%= addresses_form.text_field :kind %>
        ...
      </li>
    <% end %>
  </ul>
<% end %>
```

The HTML for the _destroy field:

```html
<input type="checkbox" value="1" name="person[addresses_attributes][0][_destroy]" id="person_addresses_attributes_0__destroy">
```

You also need to update the permitted params in your controller to include
the _destroy field:

```ruby
def person_params
  params.require(:person).
    permit(:name, addresses_attributes: [:id, :kind, :street, :_destroy])
end
```

### 9.5. Preventing Empty Records

It is often useful to ignore sets of fields that the user has not filled in. You can control this by passing a :reject_if proc to accepts_nested_attributes_for. This proc will be called with each hash of attributes submitted by the form. If the proc returns true then Active Record will not build an associated object for that hash. The example below only tries to build an address if the kind attribute is set.

```ruby
class Person < ApplicationRecord
  has_many :addresses
  accepts_nested_attributes_for :addresses, reject_if: lambda { |attributes| attributes["kind"].blank? }
end
```

As a convenience you can instead pass the symbol :all_blank which will create a proc that will reject records where all the attributes are blank excluding any value for _destroy.

## 10. Forms to External Resources

Rails form helpers can be used to build a form for posting data to an external resource. If the external API expects an authenticity_token for the resource, this can be passed as an authenticity_token: 'your_external_token' parameter to form_with:

```ruby
<%= form_with url: 'http://farfar.away/form', authenticity_token: 'external_token' do %>
  Form contents
<% end %>
```

At other times, the fields that can be used in the form are limited by an external API and it may be undesirable to generate an authenticity_token. To not send a token, you can pass false to the :authenticity_token option:

```ruby
<%= form_with url: 'http://farfar.away/form', authenticity_token: false do %>
  Form contents
<% end %>
```

## 11. Using Tag Helpers without a Form Builder

In case you need to render form fields outside of the context of a form builder, Rails provides tag helpers for common form elements. For example, checkbox_tag:

```ruby
<%= checkbox_tag "accept" %>
```

Output:

```html
<input type="checkbox" name="accept" id="accept" value="1" />
```

Generally, these helpers have the same name as their form builder counterparts plus a _tag suffix.  For a complete list, see the FormTagHelper API documentation.

## 12. Using form_tag and form_for

Before form_with was introduced in Rails 5.1 its functionality was split between form_tag and form_for. Both are now discouraged in favor of form_with, but you can still find them being used in some codebases.

---

# Chapters

This guide covers the basic layout features of Action Controller and Action View.

After reading this guide, you will know:

- How to use the various rendering methods built into Rails.

- How to create layouts with multiple content sections.

- How to use partials to DRY up your views.

- How to use nested layouts (sub-templates).

## 1. Overview: How the Pieces Fit Together

This guide focuses on the interaction between Controller and View in the Model-View-Controller triangle. As you know, the Controller is responsible for orchestrating the whole process of handling a request in Rails, though it normally hands off any heavy code to the Model. But then, when it's time to send a response back to the user, the Controller hands things off to the View. It's that handoff that is the subject of this guide.

In broad strokes, this involves deciding what should be sent as the response and calling an appropriate method to create that response. If the response is a full-blown view, Rails also does some extra work to wrap the view in a layout and possibly to pull in partial views. You'll see all of those paths later in this guide.

## 2. Creating Responses

From the controller's point of view, there are three ways to create an HTTP response:

- Call render to create a full response to send back to the browser

- Call redirect_to to send an HTTP redirect status code to the browser

- Call head to create a response consisting solely of HTTP headers to send back to the browser

### 2.1. Rendering by Default: Convention Over Configuration in Action

You've heard that Rails promotes "convention over configuration". Default rendering is an excellent example of this. By default, controllers in Rails automatically render views with names that correspond to valid routes. For example, if you have this code in your BooksController class:

```ruby
class BooksController < ApplicationController
end
```

And the following in your routes file:

```ruby
resources :books
```

And you have a view file app/views/books/index.html.erb:

```ruby
<h1>Books are coming soon!</h1>
```

Rails will automatically render app/views/books/index.html.erb when you navigate to /books and you will see "Books are coming soon!" on your screen.

However, a coming soon screen is only minimally useful, so you will soon create your Book model and add the index action to BooksController:

```ruby
class BooksController < ApplicationController
  def index
    @books = Book.all
  end
end
```

Note that we don't have explicit render at the end of the index action in accordance with "convention over configuration" principle. The rule is that if you do not explicitly render something at the end of a controller action, Rails will automatically look for the action_name.html.erb template in the controller's view path and render it. So in this case, Rails will render the app/views/books/index.html.erb file.

If we want to display the properties of all the books in our view, we can do so with an ERB template like this:

```ruby
<h1>Listing Books</h1>

<table>
  <thead>
    <tr>
      <th>Title</th>
      <th>Content</th>
      <th colspan="3"></th>
    </tr>
  </thead>

  <tbody>
    <% @books.each do |book| %>
      <tr>
        <td><%= book.title %></td>
        <td><%= book.content %></td>
        <td><%= link_to "Show", book %></td>
        <td><%= link_to "Edit", edit_book_path(book) %></td>
        <td><%= link_to "Destroy", book, data: { turbo_method: :delete, turbo_confirm: "Are you sure?" } %></td>
      </tr>
    <% end %>
  </tbody>
</table>

<br>

<%= link_to "New book", new_book_path %>
```

The actual rendering is done by nested classes of the module ActionView::Template::Handlers. This guide does not dig into that process, but it's important to know that the file extension on your view controls the choice of template handler.

### 2.2. Using render

In most cases, the controller's render method does the heavy lifting of rendering your application's content for use by a browser. There are a variety of ways to customize the behavior of render. You can render the default view for a Rails template, or a specific template, or a file, or inline code, or nothing at all. You can render text, JSON, or XML. You can specify the content type or HTTP status of the rendered response as well.

If you want to see the exact results of a call to render without needing to inspect it in a browser, you can call render_to_string. This method takes exactly the same options as render, but it returns a string instead of sending a response back to the browser.

#### 2.2.1. Rendering an Action's View

If you want to render the view that corresponds to a different template within the same controller, you can use render with the name of the view:

```ruby
def update
  @book = Book.find(params[:id])
  if @book.update(book_params)
    redirect_to(@book)
  else
    render "edit"
  end
end
```

If the call to update fails, calling the update action in this controller will render the edit.html.erb template belonging to the same controller.

If you prefer, you can use a symbol instead of a string to specify the action to render:

```ruby
def update
  @book = Book.find(params[:id])
  if @book.update(book_params)
    redirect_to(@book)
  else
    render :edit, status: :unprocessable_entity
  end
end
```

#### 2.2.2. Rendering an Action's Template from Another Controller

What if you want to render a template from an entirely different controller from the one that contains the action code? You can also do that with render, which accepts the full path (relative to app/views) of the template to render. For example, if you're running code in an AdminProductsController that lives in app/controllers/admin, you can render the results of an action to a template in app/views/products this way:

```ruby
render "products/show"
```

Rails knows that this view belongs to a different controller because of the embedded slash character in the string. If you want to be explicit, you can use the :template option (which was required on Rails 2.2 and earlier):

```ruby
render template: "products/show"
```

#### 2.2.3. Wrapping it up

The above two ways of rendering (rendering the template of another action in the same controller, and rendering the template of another action in a different controller) are actually variants of the same operation.

In fact, in the BooksController class, inside of the update action where we want to render the edit template if the book does not update successfully, all of the following render calls would all render the edit.html.erb template in the views/books directory:

```ruby
render :edit
render action: :edit
render "edit"
render action: "edit"
render "books/edit"
render template: "books/edit"
```

Which one you use is really a matter of style and convention, but the rule of thumb is to use the simplest one that makes sense for the code you are writing.

#### 2.2.4. Using render with :inline

The render method can do without a view completely, if you're willing to use the :inline option to supply ERB as part of the method call. This is perfectly valid:

```ruby
render inline: "<% products.each do |p| %><p><%= p.name %></p><% end %>"
```

There is seldom any good reason to use this option. Mixing ERB into your controllers defeats the MVC orientation of Rails and will make it harder for other developers to follow the logic of your project. Use a separate erb view instead.

By default, inline rendering uses ERB. You can force it to use Builder instead with the :type option:

```ruby
render inline: "xml.p {'Horrid coding practice!'}", type: :builder
```

#### 2.2.5. Rendering Text

You can send plain text - with no markup at all - back to the browser by using
the :plain option to render:

```ruby
render plain: "OK"
```

Rendering pure text is most useful when you're responding to Ajax or web
service requests that are expecting something other than proper HTML.

By default, if you use the :plain option, the text is rendered without
using the current layout. If you want Rails to put the text into the current
layout, you need to add the layout: true option and use the .text.erb
extension for the layout file.

#### 2.2.6. Rendering HTML

You can send an HTML string back to the browser by using the :html option to
render:

```ruby
render html: helpers.tag.strong("Not Found")
```

This is useful when you're rendering a small snippet of HTML code.
However, you might want to consider moving it to a template file if the markup
is complex.

When using html: option, HTML entities will be escaped if the string is not composed with html_safe-aware APIs.

#### 2.2.7. Rendering JSON

JSON is a JavaScript data format used by many Ajax libraries. Rails has built-in support for converting objects to JSON and rendering that JSON back to the browser:

```ruby
render json: @product
```

You don't need to call to_json on the object that you want to render. If you use the :json option, render will automatically call to_json for you.

#### 2.2.8. Rendering XML

Rails also has built-in support for converting objects to XML and rendering that XML back to the caller:

```ruby
render xml: @product
```

You don't need to call to_xml on the object that you want to render. If you use the :xml option, render will automatically call to_xml for you.

#### 2.2.9. Rendering Vanilla JavaScript

Rails can render vanilla JavaScript:

```ruby
render js: "alert('Hello Rails');"
```

This will send the supplied string to the browser with a MIME type of text/javascript.

#### 2.2.10. Rendering Raw Body

You can send a raw content back to the browser, without setting any content
type, by using the :body option to render:

```ruby
render body: "raw"
```

This option should be used only if you don't care about the content type of
the response. Using :plain or :html might be more appropriate most of the
time.

Unless overridden, your response returned from this render option will be
text/plain, as that is the default content type of Action Dispatch response.

#### 2.2.11. Rendering Raw File

Rails can render a raw file from an absolute path. This is useful for
conditionally rendering static files like error pages.

```ruby
render file: "#{Rails.root}/public/404.html", layout: false
```

This renders the raw file (it doesn't support ERB or other handlers). By
default it is rendered within the current layout.

Using the :file option in combination with users input can lead to security problems
since an attacker could use this action to access security sensitive files in your file system.

send_file is often a faster and better option if a layout isn't required.

#### 2.2.12. Rendering Objects

Rails can render objects responding to #render_in. The format can be controlled by defining #format on the object.

```ruby
class Greeting
  def render_in(view_context)
    view_context.render html: "Hello, World"
  end

  def format
    :html
  end
end

render Greeting.new
# => "Hello World"
```

This calls render_in on the provided object with the current view context. You can also provide the object by using the :renderable option to render:

```ruby
render renderable: Greeting.new
# => "Hello World"
```

#### 2.2.13. Options for render

Calls to the render method generally accept six options:

- :content_type

- :layout

- :location

- :status

- :formats

- :variants

By default, Rails will serve the results of a rendering operation with the MIME content-type of text/html (or application/json if you use the :json option, or application/xml for the :xml option.). There are times when you might like to change this, and you can do so by setting the :content_type option:

```ruby
render template: "feed", content_type: "application/rss"
```

With most of the options to render, the rendered content is displayed as part of the current layout. You'll learn more about layouts and how to use them later in this guide.

You can use the :layout option to tell Rails to use a specific file as the layout for the current action:

```ruby
render layout: "special_layout"
```

You can also tell Rails to render with no layout at all:

```ruby
render layout: false
```

You can use the :location option to set the HTTP Location header:

```ruby
render xml: photo, location: photo_url(photo)
```

Rails will automatically generate a response with the correct HTTP status code (in most cases, this is 200 OK). You can use the :status option to change this:

```ruby
render status: 500
render status: :forbidden
```

Rails understands both numeric status codes and the corresponding symbols shown below.

If you try to render content along with a non-content status code
(100-199, 204, 205, or 304), it will be dropped from the response.

Rails uses the format specified in the request (or :html by default). You can
change this passing the :formats option with a symbol or an array:

```ruby
render formats: :xml
render formats: [:json, :xml]
```

If a template with the specified format does not exist an ActionView::MissingTemplate error is raised.

This tells Rails to look for template variations of the same format.
You can specify a list of variants by passing the :variants option with a symbol or an array.

An example of use would be this.

```ruby
# called in HomeController#index
render variants: [:mobile, :desktop]
```

With this set of variants Rails will look for the following set of templates and use the first that exists.

- app/views/home/index.html+mobile.erb

- app/views/home/index.html+desktop.erb

- app/views/home/index.html.erb

If a template with the specified format does not exist an ActionView::MissingTemplate error is raised.

Instead of setting the variant on the render call you may also set
request.variant
in your controller action. Learn more about variants in the Action Controller
Overview guides.

```ruby
def index
  request.variant = determine_variant
end

private
  def determine_variant
    variant = nil
    # some code to determine the variant(s) to use
    variant = :mobile if session[:use_mobile]

    variant
  end
```

Adding many new variant templates with similarities to existing template
files can make maintaining your view code more difficult.

#### 2.2.14. Finding Layouts

To find the current layout, Rails first looks for a file in app/views/layouts with the same base name as the controller. For example, rendering actions from the PhotosController class will use app/views/layouts/photos.html.erb (or app/views/layouts/photos.builder). If there is no such controller-specific layout, Rails will use app/views/layouts/application.html.erb or app/views/layouts/application.builder. If there is no .erb layout, Rails will use a .builder layout if one exists. Rails also provides several ways to more precisely assign specific layouts to individual controllers and actions.

You can override the default layout conventions in your controllers by using the layout declaration. For example:

```ruby
class ProductsController < ApplicationController
  layout "inventory"
  #...
end
```

With this declaration, all of the views rendered by the ProductsController will use app/views/layouts/inventory.html.erb as their layout.

To assign a specific layout for the entire application, use a layout declaration in your ApplicationController class:

```ruby
class ApplicationController < ActionController::Base
  layout "main"
  #...
end
```

With this declaration, all of the views in the entire application will use app/views/layouts/main.html.erb for their layout.

You can use a symbol to defer the choice of layout until a request is processed:

```ruby
class ProductsController < ApplicationController
  layout :products_layout

  def show
    @product = Product.find(params[:id])
  end

  private
    def products_layout
      @current_user.special? ? "special" : "products"
    end
end
```

Now, if the current user is a special user, they'll get a special layout when viewing a product.

You can even use an inline method, such as a Proc, to determine the layout. For example, if you pass a Proc object, the block you give the Proc will be given the controller instance, so the layout can be determined based on the current request:

```ruby
class ProductsController < ApplicationController
  layout Proc.new { |controller| controller.request.xhr? ? "popup" : "application" }
end
```

Layouts specified at the controller level support the :only and :except options. These options take either a method name, or an array of method names, corresponding to method names within the controller:

```ruby
class ProductsController < ApplicationController
  layout "product", except: [:index, :rss]
end
```

With this declaration, the product layout would be used for everything but the rss and index methods.

Layout declarations cascade downward in the hierarchy, and more specific layout declarations always override more general ones. For example:

- application_controller.rb
class ApplicationController < ActionController::Base
  layout "main"
end

- articles_controller.rb
class ArticlesController < ApplicationController
end

- special_articles_controller.rb
class SpecialArticlesController < ArticlesController
  layout "special"
end

- old_articles_controller.rb
class OldArticlesController < SpecialArticlesController
  layout false

  def show
    @article = Article.find(params[:id])
  end

  def index
    @old_articles = Article.older
    render layout: "old"
  end

  #

end

application_controller.rb

```ruby
class ApplicationController < ActionController::Base
  layout "main"
end
```

articles_controller.rb

```ruby
class ArticlesController < ApplicationController
end
```

special_articles_controller.rb

```ruby
class SpecialArticlesController < ArticlesController
  layout "special"
end
```

old_articles_controller.rb

```ruby
class OldArticlesController < SpecialArticlesController
  layout false

  def show
    @article = Article.find(params[:id])
  end

  def index
    @old_articles = Article.older
    render layout: "old"
  end
  # ...
end
```

In this application:

- In general, views will be rendered in the main layout

- ArticlesController#index will use the main layout

- SpecialArticlesController#index will use the special layout

- OldArticlesController#show will use no layout at all

- OldArticlesController#index will use the old layout

Similar to the Layout Inheritance logic, if a template or partial is not found in the conventional path, the controller will look for a template or partial to render in its inheritance chain. For example:

```ruby
# app/controllers/application_controller.rb
class ApplicationController < ActionController::Base
end
```

```ruby
# app/controllers/admin_controller.rb
class AdminController < ApplicationController
end
```

```ruby
# app/controllers/admin/products_controller.rb
class Admin::ProductsController < AdminController
  def index
  end
end
```

The lookup order for an admin/products#index action will be:

- app/views/admin/products/

- app/views/admin/

- app/views/application/

This makes app/views/application/ a great place for your shared partials, which can then be rendered in your ERB as such:

```ruby
<%# app/views/admin/products/index.html.erb %>
<%= render @products || "empty_list" %>

<%# app/views/application/_empty_list.html.erb %>
There are no items in this list <em>yet</em>.
```

#### 2.2.15. Avoiding Double Render Errors

Sooner or later, most Rails developers will see the error message "Can only render or redirect once per action". While this is annoying, it's relatively easy to fix. Usually it happens because of a fundamental misunderstanding of the way that render works.

For example, here's some code that will trigger this error:

```ruby
def show
  @book = Book.find(params[:id])
  if @book.special?
    render action: "special_show"
  end
  render action: "regular_show"
end
```

If @book.special? evaluates to true, Rails will start the rendering process to dump the @book variable into the special_show view. But this will not stop the rest of the code in the show action from running, and when Rails hits the end of the action, it will start to render the regular_show view - and throw an error. The solution is simple: make sure that you have only one call to render or redirect in a single code path. One thing that can help is return. Here's a patched version of the method:

```ruby
def show
  @book = Book.find(params[:id])
  if @book.special?
    render action: "special_show"
    return
  end
  render action: "regular_show"
end
```

Note that the implicit render done by ActionController detects if render has been called, so the following will work without errors:

```ruby
def show
  @book = Book.find(params[:id])
  if @book.special?
    render action: "special_show"
  end
end
```

This will render a book with special? set with the special_show template, while other books will render with the default show template.

### 2.3. Using redirect_to

Another way to handle returning responses to an HTTP request is with redirect_to. As you've seen, render tells Rails which view (or other asset) to use in constructing a response. The redirect_to method does something completely different: it tells the browser to send a new request for a different URL. For example, you could redirect from wherever you are in your code to the index of photos in your application with this call:

```ruby
redirect_to photos_url
```

You can use redirect_back to return the user to the page they just came from.
This location is pulled from the HTTP_REFERER header which is not guaranteed
to be set by the browser, so you must provide the fallback_location
to use in this case.

```ruby
redirect_back(fallback_location: root_path)
```

redirect_to and redirect_back do not halt and return immediately from method execution, but simply set HTTP responses. Statements occurring after them in a method will be executed. You can halt by an explicit return or some other halting mechanism, if needed.

#### 2.3.1. Getting a Different Redirect Status Code

Rails uses HTTP status code 302, a temporary redirect, when you call redirect_to. If you'd like to use a different status code, perhaps 301, a permanent redirect, you can use the :status option:

```ruby
redirect_to photos_path, status: 301
```

Just like the :status option for render, :status for redirect_to accepts both numeric and symbolic header designations.

#### 2.3.2. The Difference Between render and redirect_to

Sometimes inexperienced developers think of redirect_to as a sort of goto
command, moving execution from one place to another in your Rails code. This is
not correct.

The current action will complete, returning a response to the browser. After
this your code stops running and waits for a new request, it just happens that
you've told the browser what request it should make next by sending back an
HTTP 302 status code.

Consider these actions to see the difference:

```ruby
def index
  @books = Book.all
end

def show
  @book = Book.find_by(id: params[:id])
  if @book.nil?
    render action: "index"
  end
end
```

With the code in this form, there will likely be a problem if the @book variable is nil. Remember, a render :action doesn't run any code in the target action, so nothing will set up the @books variable that the index view will probably require. One way to fix this is to redirect instead of rendering:

```ruby
def index
  @books = Book.all
end

def show
  @book = Book.find_by(id: params[:id])
  if @book.nil?
    redirect_to action: :index
  end
end
```

With this code, the browser will make a fresh request for the index page, the code in the index method will run, and all will be well.

The only downside to this code is that it requires a round trip to the browser: the browser requested the show action with /books/1 and the controller finds that there are no books, so the controller sends out a 302 redirect response to the browser telling it to go to /books/, the browser complies and sends a new request back to the controller asking now for the index action, the controller then gets all the books in the database and renders the index template, sending it back down to the browser which then shows it on your screen.

While in a small application, this added latency might not be a problem, it is something to think about if response time is a concern. We can demonstrate one way to handle this with a contrived example:

```ruby
def index
  @books = Book.all
end

def show
  @book = Book.find_by(id: params[:id])
  if @book.nil?
    @books = Book.all
    flash.now[:alert] = "Your book was not found"
    render "index"
  end
end
```

This would detect that there are no books with the specified ID, populate the @books instance variable with all the books in the model, and then directly render the index.html.erb template, returning it to the browser with a flash alert message to tell the user what happened.

### 2.4. Using head to Build Header-Only Responses

The head method can be used to send responses with only headers to the browser. The head method accepts a number or symbol (see reference table) representing an HTTP status code. The options argument is interpreted as a hash of header names and values. For example, you can return only an error header:

```ruby
head :bad_request
```

This would produce the following header:

```
HTTP/1.1 400 Bad Request
Connection: close
Date: Sun, 24 Jan 2010 12:15:53 GMT
Transfer-Encoding: chunked
Content-Type: text/html; charset=utf-8
X-Runtime: 0.013483
Set-Cookie: _blog_session=...snip...; path=/; HttpOnly
Cache-Control: no-cache
```

Or you can use other HTTP headers to convey other information:

```ruby
head :created, location: photo_path(@photo)
```

Which would produce:

```
HTTP/1.1 201 Created
Connection: close
Date: Sun, 24 Jan 2010 12:16:44 GMT
Transfer-Encoding: chunked
Location: /photos/1
Content-Type: text/html; charset=utf-8
X-Runtime: 0.083496
Set-Cookie: _blog_session=...snip...; path=/; HttpOnly
Cache-Control: no-cache
```

## 3. Structuring Layouts

When Rails renders a view as a response, it does so by combining the view with the current layout, using the rules for finding the current layout that were covered earlier in this guide. Within a layout, you have access to three tools for combining different bits of output to form the overall response:

- Asset tags

- yield and content_for

- Partials

### 3.1. Asset Tag Helpers

Asset tag helpers provide methods for generating HTML that link views to feeds, JavaScript, stylesheets, images, videos, and audios. There are six asset tag helpers available in Rails:

- auto_discovery_link_tag

- javascript_include_tag

- stylesheet_link_tag

- image_tag

- video_tag

- audio_tag

You can use these tags in layouts or other views, although the auto_discovery_link_tag, javascript_include_tag, and stylesheet_link_tag, are most commonly used in the <head> section of a layout.

The asset tag helpers do not verify the existence of the assets at the specified locations; they simply assume that you know what you're doing and generate the link.

#### 3.1.1. Linking to Feeds with the auto_discovery_link_tag

The auto_discovery_link_tag helper builds HTML that most browsers and feed readers can use to detect the presence of RSS, Atom, or JSON feeds. It takes the type of the link (:rss, :atom, or :json), a hash of options that are passed through to url_for, and a hash of options for the tag:

```ruby
<%= auto_discovery_link_tag(:rss, {action: "feed"},
  {title: "RSS Feed"}) %>
```

There are three tag options available for the auto_discovery_link_tag:

- :rel specifies the rel value in the link. The default value is "alternate".

- :type specifies an explicit MIME type. Rails will generate an appropriate MIME type automatically.

- :title specifies the title of the link. The default value is the uppercase :type value, for example, "ATOM" or "RSS".

#### 3.1.2. Linking to JavaScript Files with the javascript_include_tag

The javascript_include_tag helper returns an HTML script tag for each source provided.

If you are using Rails with the Asset Pipeline enabled, this helper will generate a link to /assets/javascripts/ rather than public/javascripts which was used in earlier versions of Rails. This link is then served by the asset pipeline.

A JavaScript file within a Rails application or Rails engine goes in one of three locations: app/assets, lib/assets or vendor/assets. These locations are explained in detail in the Asset Organization section in the Asset Pipeline Guide.

You can specify a full path relative to the document root, or a URL, if you prefer. For example, to link to a JavaScript file main.js that is inside one of app/assets/javascripts, lib/assets/javascripts or vendor/assets/javascripts, you would do this:

```ruby
<%= javascript_include_tag "main" %>
```

Rails will then output a script tag such as this:

```html
<script src='/assets/main.js'></script>
```

The request to this asset is then served by the Sprockets gem.

To include multiple files such as app/assets/javascripts/main.js and app/assets/javascripts/columns.js at the same time:

```ruby
<%= javascript_include_tag "main", "columns" %>
```

To include app/assets/javascripts/main.js and app/assets/javascripts/photos/columns.js:

```ruby
<%= javascript_include_tag "main", "/photos/columns" %>
```

To include <http://example.com/main.js>:

```ruby
<%= javascript_include_tag "http://example.com/main.js" %>
```

#### 3.1.3. Linking to CSS Files with the stylesheet_link_tag

The stylesheet_link_tag helper returns an HTML <link> tag for each source provided.

If you are using Rails with the "Asset Pipeline" enabled, this helper will generate a link to /assets/stylesheets/. This link is then processed by the Sprockets gem. A stylesheet file can be stored in one of three locations: app/assets, lib/assets, or vendor/assets.

You can specify a full path relative to the document root, or a URL. For example, to link to a stylesheet file that is inside a directory called stylesheets inside of one of app/assets, lib/assets, or vendor/assets, you would do this:

```ruby
<%= stylesheet_link_tag "main" %>
```

To include app/assets/stylesheets/main.css and app/assets/stylesheets/columns.css:

```ruby
<%= stylesheet_link_tag "main", "columns" %>
```

To include app/assets/stylesheets/main.css and app/assets/stylesheets/photos/columns.css:

```ruby
<%= stylesheet_link_tag "main", "photos/columns" %>
```

To include <http://example.com/main.css>:

```ruby
<%= stylesheet_link_tag "http://example.com/main.css" %>
```

By default, the stylesheet_link_tag creates links with rel="stylesheet". You can override this default by specifying an appropriate option (:rel):

```ruby
<%= stylesheet_link_tag "main_print", media: "print" %>
```

#### 3.1.4. Linking to Images with the image_tag

The image_tag helper builds an HTML <img /> tag to the specified file. By default, files are loaded from public/images.

Note that you must specify the extension of the image.

```ruby
<%= image_tag "header.png" %>
```

You can supply a path to the image if you like:

```ruby
<%= image_tag "icons/delete.gif" %>
```

You can supply a hash of additional HTML options:

```ruby
<%= image_tag "icons/delete.gif", {height: 45} %>
```

You can supply alternate text for the image which will be used if the user has images turned off in their browser. If you do not specify an alt text explicitly, it defaults to the file name of the file, capitalized and with no extension. For example, these two image tags would return the same code:

```ruby
<%= image_tag "home.gif" %>
<%= image_tag "home.gif", alt: "Home" %>
```

You can also specify a special size tag, in the format "{width}x{height}":

```ruby
<%= image_tag "home.gif", size: "50x20" %>
```

In addition to the above special tags, you can supply a final hash of standard HTML options, such as :class, :id, or :name:

```ruby
<%= image_tag "home.gif", alt: "Go Home",
                          id: "HomeImage",
                          class: "nav_bar" %>
```

#### 3.1.5. Linking to Videos with the video_tag

The video_tag helper builds an HTML5 <video> tag to the specified file. By default, files are loaded from public/videos.

```ruby
<%= video_tag "movie.ogg" %>
```

Produces

```ruby
<video src="/videos/movie.ogg" />
```

Like an image_tag you can supply a path, either absolute, or relative to the public/videos directory. Additionally you can specify the size: "#{width}x#{height}" option just like an image_tag. Video tags can also have any of the HTML options specified at the end (id, class et al).

The video tag also supports all of the <video> HTML options through the HTML options hash, including:

- poster: "image_name.png", provides an image to put in place of the video before it starts playing.

- autoplay: true, starts playing the video on page load.

- loop: true, loops the video once it gets to the end.

- controls: true, provides browser supplied controls for the user to interact with the video.

- autobuffer: true, the video will pre load the file for the user on page load.

You can also specify multiple videos to play by passing an array of videos to the video_tag:

```ruby
<%= video_tag ["trailer.ogg", "movie.ogg"] %>
```

This will produce:

```ruby
<video>
  <source src="/videos/trailer.ogg">
  <source src="/videos/movie.ogg">
</video>
```

#### 3.1.6. Linking to Audio Files with the audio_tag

The audio_tag helper builds an HTML5 <audio> tag to the specified file. By default, files are loaded from public/audios.

```ruby
<%= audio_tag "music.mp3" %>
```

You can supply a path to the audio file if you like:

```ruby
<%= audio_tag "music/first_song.mp3" %>
```

You can also supply a hash of additional options, such as :id, :class, etc.

Like the video_tag, the audio_tag has special options:

- autoplay: true, starts playing the audio on page load

- controls: true, provides browser supplied controls for the user to interact with the audio.

- autobuffer: true, the audio will pre load the file for the user on page load.

### 3.2. Understanding yield

Within the context of a layout, yield identifies a section where content from the view should be inserted. The simplest way to use this is to have a single yield, into which the entire contents of the view currently being rendered is inserted:

```ruby
<html>
  <head>
  </head>
  <body>
    <%= yield %>
  </body>
</html>
```

You can also create a layout with multiple yielding regions:

```ruby
<html>
  <head>
    <%= yield :head %>
  </head>
  <body>
    <%= yield %>
  </body>
</html>
```

The main body of the view will always render into the unnamed yield. To render content into a named yield, call the content_for method with the same argument as the named yield.

Newly generated applications will include <%= yield :head %> within the <head> element of its app/views/layouts/application.html.erb template.

### 3.3. Using the content_for Method

The content_for method allows you to insert content into a named yield block in your layout. For example, this view would work with the layout that you just saw:

```ruby
<% content_for :head do %>
  <title>A simple page</title>
<% end %>

<p>Hello, Rails!</p>
```

The result of rendering this page into the supplied layout would be this HTML:

```ruby
<html>
  <head>
    <title>A simple page</title>
  </head>
  <body>
    <p>Hello, Rails!</p>
  </body>
</html>
```

The content_for method is very helpful when your layout contains distinct regions such as sidebars and footers that should get their own blocks of content inserted. It's also useful for inserting page-specific JavaScript <script> elements, CSS <link> elements, context-specific <meta> elements, or any other elements into the <head> of an otherwise generic layout.

### 3.4. Using Partials

Partial templates - usually just called "partials" - are another device for breaking the rendering process into more manageable chunks. With a partial, you can move the code for rendering a particular piece of a response to its own file.

#### 3.4.1. Naming Partials

To render a partial as part of a view, you use the render method within the view:

```ruby
<%= render "menu" %>
```

This will render a file named _menu.html.erb at that point within the view being rendered. Note the leading underscore character: partials are named with a leading underscore to distinguish them from regular views, even though they are referred to without the underscore. This holds true even when you're pulling in a partial from another folder:

```ruby
<%= render "application/menu" %>
```

Since view partials rely on the same Template Inheritance
as templates and layouts, that code will pull in the partial from app/views/application/_menu.html.erb.

#### 3.4.2. Using Partials to Simplify Views

One way to use partials is to treat them as the equivalent of subroutines: as a way to move details out of a view so that you can grasp what's going on more easily. For example, you might have a view that looked like this:

```ruby
<%= render "application/ad_banner" %>

<h1>Products</h1>

<p>Here are a few of our fine products:</p>
<%# ... %>

<%= render "application/footer" %>
```

Here, the _ad_banner.html.erb and _footer.html.erb partials could contain
content that is shared by many pages in your application. You don't need to see
the details of these sections when you're concentrating on a particular page.

As seen in the previous sections of this guide, yield is a very powerful tool
for cleaning up your layouts. Keep in mind that it's pure Ruby, so you can use
it almost everywhere. For example, we can use it to DRY up form layout
definitions for several similar resources:

- users/index.html.erb
<%= render "application/search_filters", search: @q do |form| %>
  <p>
    Name contains: <%= form.text_field :name_contains %>
  </p>

<% end %>

- roles/index.html.erb
<%= render "application/search_filters", search: @q do |form| %>
  <p>
    Title contains: <%= form.text_field :title_contains %>
  </p>

<% end %>

- application/_search_filters.html.erb
<%= form_with model: search do |form| %>
  <h1>Search form:</h1>
  <fieldset>
    <%= yield form %>
  </fieldset>
  <p>
    <%= form.submit "Search" %>
  </p>

<% end %>

users/index.html.erb

```ruby
<%= render "application/search_filters", search: @q do |form| %>
  <p>
    Name contains: <%= form.text_field :name_contains %>
  </p>
<% end %>
```

roles/index.html.erb

```ruby
<%= render "application/search_filters", search: @q do |form| %>
  <p>
    Title contains: <%= form.text_field :title_contains %>
  </p>
<% end %>
```

application/_search_filters.html.erb

```ruby
<%= form_with model: search do |form| %>
  <h1>Search form:</h1>
  <fieldset>
    <%= yield form %>
  </fieldset>
  <p>
    <%= form.submit "Search" %>
  </p>
<% end %>
```

For content that is shared among all pages in your application, you can use partials directly from layouts.

#### 3.4.3. Partial Layouts

A partial can use its own layout file, just as a view can use a layout. For example, you might call a partial like this:

```ruby
<%= render partial: "link_area", layout: "graybar" %>
```

This would look for a partial named _link_area.html.erb and render it using the layout _graybar.html.erb. Note that layouts for partials follow the same leading-underscore naming as regular partials, and are placed in the same folder with the partial that they belong to (not in the master layouts folder).

Also note that explicitly specifying :partial is required when passing additional options such as :layout.

#### 3.4.4. Passing Local Variables

You can also pass local variables into partials, making them even more powerful and flexible. For example, you can use this technique to reduce duplication between new and edit pages, while still keeping a bit of distinct content:

- new.html.erb

<h1>New zone</h1>
<%= render partial: "form", locals: {zone: @zone} %>

- edit.html.erb

<h1>Editing zone</h1>
<%= render partial: "form", locals: {zone: @zone} %>

- _form.html.erb
<%= form_with model: zone do |form| %>
  <p>
    <b>Zone name</b><br>
    <%= form.text_field :name %>
  </p>
  <p>
    <%= form.submit %>
  </p>

<% end %>

new.html.erb

```ruby
<h1>New zone</h1>
<%= render partial: "form", locals: {zone: @zone} %>
```

edit.html.erb

```ruby
<h1>Editing zone</h1>
<%= render partial: "form", locals: {zone: @zone} %>
```

_form.html.erb

```ruby
<%= form_with model: zone do |form| %>
  <p>
    <b>Zone name</b><br>
    <%= form.text_field :name %>
  </p>
  <p>
    <%= form.submit %>
  </p>
<% end %>
```

Although the same partial will be rendered into both views, Action View's submit helper will return "Create Zone" for the new action and "Update Zone" for the edit action.

To pass a local variable to a partial in only specific cases use the local_assigns.

- index.html.erb
<%= render user.articles %>

- show.html.erb
<%= render article, full: true %>

- _article.html.erb

<h2><%= article.title %></h2>

<% if local_assigns[:full] %>
  <%= simple_format article.body %>
<% else %>
  <%= truncate article.body %>
<% end %>

index.html.erb

```ruby
<%= render user.articles %>
```

show.html.erb

```ruby
<%= render article, full: true %>
```

_article.html.erb

```ruby
<h2><%= article.title %></h2>

<% if local_assigns[:full] %>
  <%= simple_format article.body %>
<% else %>
  <%= truncate article.body %>
<% end %>
```

This way it is possible to use the partial without the need to declare all local variables.

Every partial also has a local variable with the same name as the partial (minus the leading underscore). You can pass an object in to this local variable via the :object option:

```ruby
<%= render partial: "customer", object: @new_customer %>
```

Within the customer partial, the customer variable will refer to @new_customer from the parent view.

If you have an instance of a model to render into a partial, you can use a shorthand syntax:

```ruby
<%= render @customer %>
```

Assuming that the @customer instance variable contains an instance of the Customer model, this will use _customer.html.erb to render it and will pass the local variable customer into the partial which will refer to the @customer instance variable in the parent view.

#### 3.4.5. Rendering Collections

Partials are very useful in rendering collections. When you pass a collection to a partial via the :collection option, the partial will be inserted once for each member in the collection:

- index.html.erb

<h1>Products</h1>
<%= render partial: "product", collection: @products %>

- _product.html.erb

<p>Product Name: <%= product.name %></p>

index.html.erb

```ruby
<h1>Products</h1>
<%= render partial: "product", collection: @products %>
```

_product.html.erb

```ruby
<p>Product Name: <%= product.name %></p>
```

When a partial is called with a pluralized collection, then the individual instances of the partial have access to the member of the collection being rendered via a variable named after the partial. In this case, the partial is _product, and within the_product partial, you can refer to product to get the instance that is being rendered.

There is also a shorthand for this. Assuming @products is a collection of Product instances, you can simply write this in the index.html.erb to produce the same result:

```ruby
<h1>Products</h1>
<%= render @products %>
```

Rails determines the name of the partial to use by looking at the model name in the collection. In fact, you can even create a heterogeneous collection and render it this way, and Rails will choose the proper partial for each member of the collection:

- index.html.erb

<h1>Contacts</h1>
<%= render [customer1, employee1, customer2, employee2] %>

- customers/_customer.html.erb

<p>Customer: <%= customer.name %></p>

- employees/_employee.html.erb

<p>Employee: <%= employee.name %></p>

index.html.erb

```ruby
<h1>Contacts</h1>
<%= render [customer1, employee1, customer2, employee2] %>
```

customers/_customer.html.erb

```ruby
<p>Customer: <%= customer.name %></p>
```

employees/_employee.html.erb

```ruby
<p>Employee: <%= employee.name %></p>
```

In this case, Rails will use the customer or employee partials as appropriate for each member of the collection.

In the event that the collection is empty, render will return nil, so it should be fairly simple to provide alternative content.

```ruby
<h1>Products</h1>
<%= render(@products) || "There are no products available." %>
```

#### 3.4.6. Local Variables

To use a custom local variable name within the partial, specify the :as option in the call to the partial:

```ruby
<%= render partial: "product", collection: @products, as: :item %>
```

With this change, you can access an instance of the @products collection as the item local variable within the partial.

You can also pass in arbitrary local variables to any partial you are rendering with the locals: {} option:

```ruby
<%= render partial: "product", collection: @products,
           as: :item, locals: {title: "Products Page"} %>
```

In this case, the partial will have access to a local variable title with the value "Products Page".

#### 3.4.7. Counter Variables

Rails also makes a counter variable available within a partial called by the collection. The variable is named after the title of the partial followed by _counter. For example, when rendering a collection @products the partial_product.html.erb can access the variable product_counter. The variable indexes the number of times the partial has been rendered within the enclosing view, starting with a value of 0 on the first render.

```ruby
# index.html.erb
<%= render partial: "product", collection: @products %>
```

```ruby
# _product.html.erb
<%= product_counter %> # 0 for the first product, 1 for the second product...
```

This also works when the local variable name is changed using the as: option. So if you did as: :item, the counter variable would be item_counter.

#### 3.4.8. Spacer Templates

You can also specify a second partial to be rendered between instances of the main partial by using the :spacer_template option:

```ruby
<%= render partial: @products, spacer_template: "product_ruler" %>
```

Rails will render the _product_ruler partial (with no data passed in to it) between each pair of _product partials.

#### 3.4.9. Collection Partial Layouts

When rendering collections it is also possible to use the :layout option:

```ruby
<%= render partial: "product", collection: @products, layout: "special_layout" %>
```

The layout will be rendered together with the partial for each item in the collection. The current object and object_counter variables will be available in the layout as well, the same way they are within the partial.

### 3.5. Using Nested Layouts

You may find that your application requires a layout that differs slightly from your regular application layout to support one particular controller. Rather than repeating the main layout and editing it, you can accomplish this by using nested layouts (sometimes called sub-templates). Here's an example:

Suppose you have the following ApplicationController layout:

- app/views/layouts/application.html.erb

<html>
<head>
  <title><%= @page_title or "Page Title" %></title>
  <%= stylesheet_link_tag "layout" %>
  <%= yield :head %>
</head>
<body>
  <div id="top_menu">Top menu items here</div>
  <div id="menu">Menu items here</div>
  <div id="content"><%= content_for?(:content) ? yield(:content) : yield %></div>
</body>
</html>

app/views/layouts/application.html.erb

```ruby
<html>
<head>
  <title><%= @page_title or "Page Title" %></title>
  <%= stylesheet_link_tag "layout" %>
  <%= yield :head %>
</head>
<body>
  <div id="top_menu">Top menu items here</div>
  <div id="menu">Menu items here</div>
  <div id="content"><%= content_for?(:content) ? yield(:content) : yield %></div>
</body>
</html>
```

On pages generated by NewsController, you want to hide the top menu and add a right menu:

- app/views/layouts/news.html.erb
<% content_for :head do %>
  <style>
    #top_menu {display: none}
    #right_menu {float: right; background-color: yellow; color: black}
  </style>

<% end %>
<% content_for :content do %>
  <div id="right_menu">Right menu items here</div>
  <%= content_for?(:news_content) ? yield(:news_content) : yield %>
<% end %>
<%= render template: "layouts/application" %>

app/views/layouts/news.html.erb

```ruby
<% content_for :head do %>
  <style>
    #top_menu {display: none}
    #right_menu {float: right; background-color: yellow; color: black}
  </style>
<% end %>
<% content_for :content do %>
  <div id="right_menu">Right menu items here</div>
  <%= content_for?(:news_content) ? yield(:news_content) : yield %>
<% end %>
<%= render template: "layouts/application" %>
```

That's it. The News views will use the new layout, hiding the top menu and adding a new right menu inside the "content" div.

There are several ways of getting similar results with different sub-templating schemes using this technique. Note that there is no limit in nesting levels. One can use the ActionView::render method via render template: 'layouts/news' to base a new layout on the News layout. If you are sure you will not subtemplate the News layout, you can replace the content_for?(:news_content) ? yield(:news_content) : yield with simply yield.
