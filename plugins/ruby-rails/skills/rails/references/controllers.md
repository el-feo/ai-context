# Action Controller

## Table of Contents

- [1. Introduction](#1-introduction)
- [2. Creating a Controller](#2-creating-a-controller)
- [3. Parameters](#3-parameters)
- [4. Strong Parameters](#4-strong-parameters)
- [5. Cookies](#5-cookies)
- [6. Session](#6-session)
- [7. Controller Callbacks](#7-controller-callbacks)
- [8. The Request and Response Objects](#8-the-request-and-response-objects)
- [9. Introduction](#9-introduction)
- [10. Authenticity Token and Request Forgery Protection](#10-authenticity-token-and-request-forgery-protection)
- [11. Controlling Allowed Browser Versions](#11-controlling-allowed-browser-versions)
- [12. HTTP Authentication](#12-http-authentication)
- [13. Streaming and File Downloads](#13-streaming-and-file-downloads)
- [14. Log Filtering](#14-log-filtering)
- [15. Force HTTPS Protocol](#15-force-https-protocol)
- [16. Built-in Health Check Endpoint](#16-built-in-health-check-endpoint)
- [17. Handling Errors](#17-handling-errors)

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

In this guide, you will learn about some advanced topics related to controllers. After reading this guide, you will know how to:

- Protect against cross-site request forgery.

- Use Action Controller's built-in HTTP authentication.

- Stream data directly to the user's browser.

- Filter sensitive parameters from the application logs.

- Handle exceptions that may be raised during request processing.

- Use the built-in health check endpoint for load balancers and uptime monitors.

## 9. Introduction

This guide covers a number of advanced topics related to controllers in a Rails
application. Please see the Action Controller
Overview guide for an introduction to Action
Controllers.

## 10. Authenticity Token and Request Forgery Protection

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

### 10.1. Authenticity Token in Forms

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

## 11. Controlling Allowed Browser Versions

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

Browsers matched in the hash passed to versions: will be blocked if they're below the versions specified. This means that all other browsers not mentioned in versions: (Chrome and Opera in the above example), as well as agents that aren't reporting a user-agent header, will be allowed access.

You can also use allow_browser in a given controller and specify actions using only or except. For example:

```ruby
class MessagesController < ApplicationController
  # In addition to the browsers blocked by ApplicationController, also block Opera below 104 and Chrome below 119 for the show action.
  allow_browser versions: { opera: 104, chrome: 119 }, only: :show
end
```

A browser that's blocked will, by default, be served the file in public/406-unsupported-browser.html with an HTTP status code of "406 Not Acceptable".

## 12. HTTP Authentication

Rails comes with three built-in HTTP authentication mechanisms:

- Basic Authentication

- Digest Authentication

- Token Authentication

### 12.1. HTTP Basic Authentication

HTTP Basic Authentication is a simple authentication method where a user is
required to enter a username and password to access a website or a particular
section of a website (e.g. admin section). These credentials are entered into a
browser's HTTP basic dialog window. The user's credentials are then encoded and
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

### 12.2. HTTP Digest Authentication

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

### 12.3. HTTP Token Authentication

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

## 13. Streaming and File Downloads

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

### 13.1. Sending Files

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

### 13.2. RESTful Downloads

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

### 13.3. Live Streaming of Arbitrary Data

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

#### 13.3.1. Example Use Case

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

#### 13.3.2. Streaming Considerations

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

## 14. Log Filtering

Rails keeps a log file for each environment in the log folder at the
application's root directory. Log files are extremely useful when debugging your
application, but in a production environment you may not want every bit of
information stored in log files. Rails allows you to specify parameters that
should not be stored.

### 14.1. Parameters Filtering

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

### 14.2. Redirects Filtering

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

## 15. Force HTTPS Protocol

If you'd like to ensure that communication to your controller is only possible
via HTTPS, you can do so by enabling the ActionDispatch::SSL middleware
via config.force_ssl in your environment configuration.

## 16. Built-in Health Check Endpoint

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

## 17. Handling Errors

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

### 17.1. The Default Error Templates

By default, in the production environment the application will render an error
page. These pages are contained in static HTML files in the public folder, in
404.html, 500.html, etc. You can customize these files to add some extra
information and styles.

The error templates are static HTML files so you can't use ERB, SCSS, or
layouts for them.

### 17.2. rescue_from

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
