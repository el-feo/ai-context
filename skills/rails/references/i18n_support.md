# Chapters

The Ruby I18n (shorthand for internationalization) gem which is shipped with Ruby on Rails (starting from Rails 2.2) provides an easy-to-use and extensible framework for translating your application to a single custom language other than English or for providing multi-language support in your application.

The process of "internationalization" usually means to abstract all strings and other locale specific bits (such as date or currency formats) out of your application. The process of "localization" means to provide translations and localized formats for these bits.1

So, in the process of internationalizing your Rails application you have to:

- Ensure you have support for I18n.

- Tell Rails where to find locale dictionaries.

- Tell Rails how to set, preserve, and switch locales.

In the process of localizing your application you'll probably want to do the following three things:

- Replace or supplement Rails' default locale - e.g. date and time formats, month names, Active Record model names, etc.

- Abstract strings in your application into keyed dictionaries - e.g. flash messages, static text in your views, etc.

- Store the resulting dictionaries somewhere.

This guide will walk you through the I18n API and contains a tutorial on how to internationalize a Rails application from the start.

After reading this guide, you will know:

- How I18n works in Ruby on Rails

- How to correctly use I18n in a RESTful application in various ways

- How to use I18n to translate Active Record errors or Action Mailer E-mail subjects

- Some other tools to go further with the translation process of your application

The Ruby I18n framework provides you with all necessary means for internationalization/localization of your Rails application. You may also use various gems available to add additional functionality or features. See the rails-i18n gem for more information.


## 1. How I18n in Ruby on Rails Works

Internationalization is a complex problem. Natural languages differ in so many ways (e.g. in pluralization rules) that it is hard to provide tools for solving all problems at once. For that reason the Rails I18n API focuses on:

- providing support for English and similar languages out of the box

- making it easy to customize and extend everything for other languages

As part of this solution, every static string in the Rails framework - e.g. Active Record validation messages, time and date formats - has been internationalized. Localization of a Rails application means defining translated values for these strings in desired languages.

To localize, store, and update content in your application (e.g. translate blog posts), see the Translating model content section.


### 1.1. The Overall Architecture of the Library

Thus, the Ruby I18n gem is split into two parts:

- The public API of the I18n framework - a Ruby module with public methods that define how the library works

- A default backend (which is intentionally named Simple backend) that implements these methods

As a user you should always only access the public methods on the I18n module, but it is useful to know about the capabilities of the backend.

It is possible to swap the shipped Simple backend with a more powerful one, which would store translation data in a relational database, GetText dictionary, or similar. See section Using different backends below.


### 1.2. The Public I18n API

The most important methods of the I18n API are:

```ruby
translate # Lookup text translations
localize  # Localize Date and Time objects to local formats
```

These have the aliases #t and #l so you can use them like this:

```ruby
I18n.t "store.title"
I18n.l Time.now
```

There are also attribute readers and writers for the following attributes:

```ruby
load_path                 # Announce your custom translation files
locale                    # Get and set the current locale
default_locale            # Get and set the default locale
available_locales         # Permitted locales available for the application
enforce_available_locales # Enforce locale permission (true or false)
exception_handler         # Use a different exception_handler
backend                   # Use a different backend
```

So, let's internationalize a simple Rails application from the ground up in the next chapters!


## 2. Setup the Rails Application for Internationalization

There are a few steps to get up and running with I18n support for a Rails application.


### 2.1. Configure the I18n Module

Following the convention over configuration philosophy, Rails I18n provides reasonable default translation strings. When different translation strings are needed, they can be overridden.

Rails adds all .rb and .yml files from the config/locales directory to the translations load path, automatically.

The default en.yml locale in this directory contains a sample pair of translation strings:

```yaml
en:
  hello: "Hello world"
```

This means, that in the :en locale, the key hello will map to the Hello world string. Every string inside Rails is internationalized in this way, see for instance Active Model validation messages in the activemodel/lib/active_model/locale/en.yml file or time and date formats in the activesupport/lib/active_support/locale/en.yml file. You can use YAML or standard Ruby Hashes to store translations in the default (Simple) backend.

The I18n library will use English as a default locale, i.e. if a different locale is not set, :en will be used for looking up translations.

The i18n library takes a pragmatic approach to locale keys (after some discussion), including only the locale ("language") part, like :en, :pl, not the region part, like :"en-US" or :"en-GB", which are traditionally used for separating "languages" and "regional setting" or "dialects". Many international applications use only the "language" element of a locale such as :cs, :th, or :es (for Czech, Thai, and Spanish). However, there are also regional differences within different language groups that may be important. For instance, in the :"en-US" locale you would have $ as a currency symbol, while in :"en-GB", you would have £. Nothing stops you from separating regional and other settings in this way: you just have to provide full "English - United Kingdom" locale in a :"en-GB" dictionary.

The translations load path (I18n.load_path) is an array of paths to files that will be loaded automatically. Configuring this path allows for customization of translations directory structure and file naming scheme.

The backend lazy-loads these translations when a translation is looked up for the first time. This backend can be swapped with something else even after translations have already been announced.

You can change the default locale as well as configure the translations load paths in config/application.rb as follows:

```ruby
config.i18n.load_path += Dir[Rails.root.join("my", "locales", "*.{rb,yml}")]
config.i18n.default_locale = :de
```

The load path must be specified before any translations are looked up. To change the default locale from an initializer instead of config/application.rb:

```ruby
# config/initializers/locale.rb

# Where the I18n library should search for translation files
I18n.load_path += Dir[Rails.root.join("lib", "locale", "*.{rb,yml}")]

# Permitted locales available for the application
I18n.available_locales = [:en, :pt]

# Set default locale to something other than :en
I18n.default_locale = :pt
```

Note that appending directly to I18n.load_path instead of to the application's configured I18n will not override translations from external gems.


### 2.2. Managing the Locale across Requests

A localized application will likely need to provide support for multiple locales. To accomplish this, the locale should be set at the beginning of each request so that all strings are translated using the desired locale during the lifetime of that request.

The default locale is used for all translations unless I18n.locale= or I18n.with_locale is used.

I18n.locale can leak into subsequent requests served by the same thread/process if it is not consistently set in every controller. For example executing I18n.locale = :es in one POST requests will have effects for all later requests to controllers that don't set the locale, but only in that particular thread/process. For that reason, instead of I18n.locale = you can use I18n.with_locale which does not have this leak issue.

The locale can be set in an around_action in the ApplicationController:

```ruby
around_action :switch_locale

def switch_locale(&action)
  locale = params[:locale] || I18n.default_locale
  I18n.with_locale(locale, &action)
end
```

This example illustrates this using a URL query parameter to set the locale (e.g. http://example.com/books?locale=pt). With this approach, http://localhost:3000?locale=pt renders the Portuguese localization, while http://localhost:3000?locale=de loads a German localization.

The locale can be set using one of many different approaches.


#### 2.2.1. Setting the Locale from the Domain Name

One option you have is to set the locale from the domain name where your application runs. For example, we want www.example.com to load the English (or default) locale, and www.example.es to load the Spanish locale. Thus the top-level domain name is used for locale setting. This has several advantages:

- The locale is an obvious part of the URL.

- People intuitively grasp in which language the content will be displayed.

- It is very trivial to implement in Rails.

- Search engines seem to like that content in different languages lives at different, inter-linked domains.

You can implement it like this in your ApplicationController:

```ruby
around_action :switch_locale

def switch_locale(&action)
  locale = extract_locale_from_tld || I18n.default_locale
  I18n.with_locale(locale, &action)
end

# Get locale from top-level domain or return +nil+ if such locale is not available
# You have to put something like:
#   127.0.0.1 application.com
#   127.0.0.1 application.it
#   127.0.0.1 application.pl
# in your /etc/hosts file to try this out locally
def extract_locale_from_tld
  parsed_locale = request.host.split(".").last
  I18n.available_locales.map(&:to_s).include?(parsed_locale) ? parsed_locale : nil
end
```

We can also set the locale from the subdomain in a very similar way:

```ruby
# Get locale code from request subdomain (like http://it.application.local:3000)
# You have to put something like:
#   127.0.0.1 it.application.local
# in your /etc/hosts file to try this out locally
#
# Additionally, you need to add the following configuration to your config/environments/development.rb:
#   config.hosts << 'it.application.local:3000'
def extract_locale_from_subdomain
  parsed_locale = request.subdomains.first
  I18n.available_locales.map(&:to_s).include?(parsed_locale) ? parsed_locale : nil
end
```

If your application includes a locale switching menu, you would then have something like this in it:

```ruby
link_to("Deutsch", "#{APP_CONFIG[:deutsch_website_url]}#{request.env['PATH_INFO']}")
```

assuming you would set APP_CONFIG[:deutsch_website_url] to some value like http://www.application.de.

This solution has aforementioned advantages, however, you may not be able or may not want to provide different localizations ("language versions") on different domains. The most obvious solution would be to include locale code in the URL params (or request path).


#### 2.2.2. Setting the Locale from URL Params

The most usual way of setting (and passing) the locale would be to include it in URL params, as we did in the I18n.with_locale(params[:locale], &action) around_action in the first example. We would like to have URLs like www.example.com/books?locale=ja or www.example.com/ja/books in this case.

This approach has almost the same set of advantages as setting the locale from the domain name: namely that it's RESTful and in accord with the rest of the World Wide Web. It does require a little bit more work to implement, though.

Getting the locale from params and setting it accordingly is not hard; including it in every URL and thus passing it through the requests is. To include an explicit option in every URL, e.g. link_to(books_url(locale: I18n.locale)), would be tedious and probably impossible, of course.

Rails contains infrastructure for "centralizing dynamic decisions about the URLs" in its ApplicationController#default_url_options, which is useful precisely in this scenario: it enables us to set "defaults" for url_for and helper methods dependent on it (by implementing/overriding default_url_options).

We can include something like this in our ApplicationController then:

```ruby
# app/controllers/application_controller.rb
def default_url_options
  { locale: I18n.locale }
end
```

Every helper method dependent on url_for (e.g. helpers for named routes like root_path or root_url, resource routes like books_path or books_url, etc.) will now automatically include the locale in the query string, like this: http://localhost:3001/?locale=ja.

You may be satisfied with this. It does impact the readability of URLs, though, when the locale "hangs" at the end of every URL in your application. Moreover, from the architectural standpoint, locale is usually hierarchically above the other parts of the application domain: and URLs should reflect this.

You probably want URLs to look like this: http://www.example.com/en/books (which loads the English locale) and http://www.example.com/nl/books (which loads the Dutch locale). This is achievable with the "over-riding default_url_options" strategy from above: you just have to set up your routes with scope:

```ruby
# config/routes.rb
scope "/:locale" do
  resources :books
end
```

Now, when you call the books_path method you should get "/en/books" (for the default locale). A URL like http://localhost:3001/nl/books should load the Dutch locale, then, and following calls to books_path should return "/nl/books" (because the locale changed).

Since the return value of default_url_options is cached per request, the URLs in a locale selector cannot be generated invoking helpers in a loop that sets the corresponding I18n.locale in each iteration. Instead, leave I18n.locale untouched, and pass an explicit :locale option to the helper, or edit request.original_fullpath.

If you don't want to force the use of a locale in your routes you can use an optional path scope (denoted by the parentheses) like so:

```ruby
# config/routes.rb
scope "(:locale)", locale: /en|nl/ do
  resources :books
end
```

With this approach you will not get a Routing Error when accessing your resources such as http://localhost:3001/books without a locale. This is useful for when you want to use the default locale when one is not specified.

Of course, you need to take special care of the root URL (usually "homepage" or "dashboard") of your application. A URL like http://localhost:3001/nl will not work automatically, because the root to: "dashboard#index" declaration in your routes.rb doesn't take locale into account. (And rightly so: there's only one "root" URL.)

You would probably need to map URLs like these:

```ruby
# config/routes.rb
get "/:locale" => "dashboard#index"
```

Do take special care about the order of your routes, so this route declaration does not "eat" other ones. (You may want to add it directly before the root :to declaration.)

Have a look at a gem which simplifies working with routes: route_translator.


#### 2.2.3. Setting the Locale from User Preferences

An application with authenticated users may allow users to set a locale preference through the application's interface. With this approach, a user's selected locale preference is persisted in the database and used to set the locale for authenticated requests by that user.

```ruby
around_action :switch_locale

def switch_locale(&action)
  locale = current_user.try(:locale) || I18n.default_locale
  I18n.with_locale(locale, &action)
end
```


#### 2.2.4. Choosing an Implied Locale

When an explicit locale has not been set for a request (e.g. via one of the above methods), an application should attempt to infer the desired locale.

The Accept-Language HTTP header indicates the preferred language for request's response. Browsers set this header value based on the user's language preference settings, making it a good first choice when inferring a locale.

A trivial implementation of using an Accept-Language header would be:

```ruby
def switch_locale(&action)
  logger.debug "* Accept-Language: #{request.env['HTTP_ACCEPT_LANGUAGE']}"
  locale = extract_locale_from_accept_language_header
  logger.debug "* Locale set to '#{locale}'"
  I18n.with_locale(locale, &action)
end

private
  def extract_locale_from_accept_language_header
    request.env["HTTP_ACCEPT_LANGUAGE"].scan(/^[a-z]{2}/).first
  end
```

In practice, more robust code is necessary to do this reliably. Iain Hecker's http_accept_language library or Ryan Tomayko's locale Rack middleware provide solutions to this problem.

The IP address of the client making the request can be used to infer the client's region and thus their locale. Services such as GeoLite2 Country or gems like geocoder can be used to implement this approach.

In general, this approach is far less reliable than using the language header and is not recommended for most web applications.


#### 2.2.5. Storing the Locale from the Session or Cookies

You may be tempted to store the chosen locale in a session or a cookie. However, do not do this. The locale should be transparent and a part of the URL. This way you won't break people's basic assumptions about the web itself: if you send a URL to a friend, they should see the same page and content as you. A fancy word for this would be that you're being RESTful. Read more about the RESTful approach in Stefan Tilkov's articles. Sometimes there are exceptions to this rule and those are discussed below.


## 3. Internationalization and Localization

OK! Now you've initialized I18n support for your Ruby on Rails application and told it which locale to use and how to preserve it between requests.

Next we need to internationalize our application by abstracting every locale-specific element. Finally, we need to localize it by providing necessary translations for these abstracts.

Given the following example:

```ruby
# config/routes.rb
Rails.application.routes.draw do
  root to: "home#index"
end
```

```ruby
# app/controllers/application_controller.rb
class ApplicationController < ActionController::Base
  around_action :switch_locale

  def switch_locale(&action)
    locale = params[:locale] || I18n.default_locale
    I18n.with_locale(locale, &action)
  end
end
```

```ruby
# app/controllers/home_controller.rb
class HomeController < ApplicationController
  def index
    flash[:notice] = "Hello Flash"
  end
end
```

```ruby
<!-- app/views/home/index.html.erb -->
<h1>Hello World</h1>
<p><%= flash[:notice] %></p>
```


### 3.1. Abstracting Localized Code

In our code, there are two strings written in English that will be rendered in our response ("Hello Flash" and "Hello World"). To internationalize this code, these strings need to be replaced by calls to Rails' #t helper with an appropriate key for each string:

```ruby
# app/controllers/home_controller.rb
class HomeController < ApplicationController
  def index
    flash[:notice] = t(:hello_flash)
  end
end
```

```ruby
<!-- app/views/home/index.html.erb -->
<h1><%= t :hello_world %></h1>
<p><%= flash[:notice] %></p>
```

Now, when this view is rendered, it will show an error message which tells you that the translations for the keys :hello_world and :hello_flash are missing.

Rails adds a t (translate) helper method to your views so that you do not need to spell out I18n.t all the time. Additionally this helper will catch missing translations and wrap the resulting error message into a <span class="translation_missing">.


### 3.2. Providing Translations for Internationalized Strings

Add the missing translations into the translation dictionary files:

```yaml
# config/locales/en.yml
en:
  hello_world: Hello world!
  hello_flash: Hello flash!
```

```yaml
# config/locales/pirate.yml
pirate:
  hello_world: Ahoy World
  hello_flash: Ahoy Flash
```

Because the default_locale hasn't changed, translations use the :en locale and the response renders the english strings:

If the locale is set via the URL to the pirate locale (http://localhost:3000?locale=pirate), the response renders the pirate strings:

You need to restart the server when you add new locale files.

You may use YAML (.yml) or plain Ruby (.rb) files for storing your translations in SimpleStore. YAML is the preferred option among Rails developers. However, it has one big disadvantage. YAML is very sensitive to whitespace and special characters, so the application may not load your dictionary properly. Ruby files will crash your application on first request, so you may easily find what's wrong. (If you encounter any "weird issues" with YAML dictionaries, try putting the relevant portion of your dictionary into a Ruby file.)

If your translations are stored in YAML files, certain keys must be escaped. They are:

- true, on, yes

- false, off, no

Examples:

```yaml
# config/locales/en.yml
en:
  success:
    'true':  'True!'
    'on':    'On!'
    'false': 'False!'
  failure:
    true:    'True!'
    off:     'Off!'
    false:   'False!'
```

```ruby
I18n.t "success.true"  # => 'True!'
I18n.t "success.on"    # => 'On!'
I18n.t "success.false" # => 'False!'
I18n.t "failure.false" # => Translation Missing
I18n.t "failure.off"   # => Translation Missing
I18n.t "failure.true"  # => Translation Missing
```


### 3.3. Passing Variables to Translations

One key consideration for successfully internationalizing an application is to
avoid making incorrect assumptions about grammar rules when abstracting localized
code. Grammar rules that seem fundamental in one locale may not hold true in
another one.

Improper abstraction is shown in the following example, where assumptions are
made about the ordering of the different parts of the translation. Note that Rails
provides a number_to_currency helper to handle the following case.

```ruby
<!-- app/views/products/show.html.erb -->
<%= "#{t('currency')}#{@product.price}" %>
```

```yaml
# config/locales/en.yml
en:
  currency: "$"
```

```yaml
# config/locales/es.yml
es:
  currency: "€"
```

If the product's price is 10 then the proper translation for Spanish is "10 €"
instead of "€10" but the abstraction cannot give it.

To create proper abstraction, the I18n gem ships with a feature called variable
interpolation that allows you to use variables in translation definitions and
pass the values for these variables to the translation method.

Proper abstraction is shown in the following example:

```ruby
<!-- app/views/products/show.html.erb -->
<%= t('product_price', price: @product.price) %>
```

```yaml
# config/locales/en.yml
en:
  product_price: "$%{price}"
```

```yaml
# config/locales/es.yml
es:
  product_price: "%{price} €"
```

All grammatical and punctuation decisions are made in the definition itself, so
the abstraction can give a proper translation.

The default and scope keywords are reserved and can't be used as
variable names. If used, an I18n::ReservedInterpolationKey exception is raised.
If a translation expects an interpolation variable, but this has not been passed
to #translate, an I18n::MissingInterpolationArgument exception is raised.


### 3.4. Adding Date/Time Formats

OK! Now let's add a timestamp to the view, so we can demo the date/time localization feature as well. To localize the time format you pass the Time object to I18n.l or (preferably) use Rails' #l helper. You can pick a format by passing the :format option - by default the :default format is used.

```ruby
<!-- app/views/home/index.html.erb -->
<h1><%= t :hello_world %></h1>
<p><%= flash[:notice] %></p>
<p><%= l Time.now, format: :short %></p>
```

And in our pirate translations file let's add a time format (it's already there in Rails' defaults for English):

```yaml
# config/locales/pirate.yml
pirate:
  time:
    formats:
      short: "arrrround %H'ish"
```

So that would give you:

Right now you might need to add some more date/time formats in order to make the I18n backend work as expected (at least for the 'pirate' locale). Of course, there's a great chance that somebody already did all the work by translating Rails' defaults for your locale. See the rails-i18n repository at GitHub for an archive of various locale files. When you put such file(s) in config/locales/ directory, they will automatically be ready for use.


### 3.5. Inflection Rules for Other Locales

Rails allows you to define inflection rules (such as rules for singularization and pluralization) for locales other than English. In config/initializers/inflections.rb, you can define these rules for multiple locales. The initializer contains a default example for specifying additional rules for English; follow that format for other locales as you see fit.


### 3.6. Localized Views

Let's say you have a BooksController in your application. Your index action renders content in app/views/books/index.html.erb template. When you put a localized variant of this template: index.es.html.erb in the same directory, Rails will render content in this template, when the locale is set to :es. When the locale is set to the default locale, the generic index.html.erb view will be used. (Future Rails versions may well bring this automagic localization to assets in public, etc.)

You can make use of this feature, e.g. when working with a large amount of static content, which would be clumsy to put inside YAML or Ruby dictionaries. Bear in mind, though, that any change you would like to do later to the template must be propagated to all of them.


### 3.7. Organization of Locale Files

When you are using the default SimpleStore shipped with the i18n library,
dictionaries are stored in plain-text files on the disk. Putting translations
for all parts of your application in one file per locale could be hard to
manage. You can store these files in a hierarchy which makes sense to you.

For example, your config/locales directory could look like this:

```
|-defaults
|---es.yml
|---en.yml
|-models
|---book
|-----es.yml
|-----en.yml
|-views
|---defaults
|-----es.yml
|-----en.yml
|---books
|-----es.yml
|-----en.yml
|---users
|-----es.yml
|-----en.yml
|---navigation
|-----es.yml
|-----en.yml
```

This way, you can separate model and model attribute names from text inside views, and all of this from the "defaults" (e.g. date and time formats). Other stores for the i18n library could provide different means of such separation.


## 4. Overview of the I18n API Features

You should have a good understanding of using the i18n library now and know how
to internationalize a basic Rails application. In the following chapters, we'll
cover its features in more depth.

These chapters will show examples using both the I18n.translate method as well as the translate view helper method (noting the additional features provided by the view helper method).

Covered are features like these:

- looking up translations

- interpolating data into translations

- pluralizing translations

- using safe HTML translations (view helper method only)

- localizing dates, numbers, currency, etc.


### 4.1. Looking up Translations


#### 4.1.1. Basic Lookup, Scopes, and Nested Keys

Translations are looked up by keys which can be both Symbols or Strings, so these calls are equivalent:

```ruby
I18n.t :message
I18n.t "message"
```

The translate method also takes a :scope option which can contain one or more additional keys that will be used to specify a "namespace" or scope for a translation key:

```ruby
I18n.t :record_invalid, scope: [:activerecord, :errors, :messages]
```

This looks up the :record_invalid message in the Active Record error messages.

Additionally, both the key and scopes can be specified as dot-separated keys as in:

```ruby
I18n.translate "activerecord.errors.messages.record_invalid"
```

Thus the following calls are equivalent:

```ruby
I18n.t "activerecord.errors.messages.record_invalid"
I18n.t "errors.messages.record_invalid", scope: :activerecord
I18n.t :record_invalid, scope: "activerecord.errors.messages"
I18n.t :record_invalid, scope: [:activerecord, :errors, :messages]
```


#### 4.1.2. Defaults

When a :default option is given, its value will be returned if the translation is missing:

```ruby
I18n.t :missing, default: "Not here"
# => 'Not here'
```

If the :default value is a Symbol, it will be used as a key and translated. One can provide multiple values as default. The first one that results in a value will be returned.

E.g., the following first tries to translate the key :missing and then the key :also_missing. As both do not yield a result, the string "Not here" will be returned:

```ruby
I18n.t :missing, default: [:also_missing, "Not here"]
# => 'Not here'
```


#### 4.1.3. Bulk and Namespace Lookup

To look up multiple translations at once, an array of keys can be passed:

```ruby
I18n.t [:odd, :even], scope: "errors.messages"
# => ["must be odd", "must be even"]
```

Also, a key can translate to a (potentially nested) hash of grouped translations. E.g., one can receive all Active Record error messages as a Hash with:

```ruby
I18n.t "errors.messages"
# => {:inclusion=>"is not included in the list", :exclusion=> ... }
```

If you want to perform interpolation on a bulk hash of translations, you need to pass deep_interpolation: true as a parameter. When you have the following dictionary:

```yaml
en:
  welcome:
    title: "Welcome!"
    content: "Welcome to the %{app_name}"
```

then the nested interpolation will be ignored without the setting:

```ruby
I18n.t "welcome", app_name: "book store"
# => {:title=>"Welcome!", :content=>"Welcome to the %{app_name}"}

I18n.t "welcome", deep_interpolation: true, app_name: "book store"
# => {:title=>"Welcome!", :content=>"Welcome to the book store"}
```


#### 4.1.4. "Lazy" Lookup

Rails implements a convenient way to look up the locale inside views. When you have the following dictionary:

```yaml
es:
  books:
    index:
      title: "Título"
```

you can look up the books.index.title value inside app/views/books/index.html.erb template like this (note the dot):

```ruby
<%= t '.title' %>
```

Automatic translation scoping by partial is only available from the translate view helper method.

"Lazy" lookup can also be used in controllers:

```yaml
en:
  books:
    create:
      success: Book created!
```

This is useful for setting flash messages for instance:

```ruby
class BooksController < ApplicationController
  def create
    # ...
    redirect_to books_url, notice: t(".success")
  end
end
```


### 4.2. Pluralization

In many languages — including English — there are only two forms, a singular and a plural, for
a given string, e.g. "1 message" and "2 messages". Other languages (Arabic, Japanese, Russian and many more) have different grammars that have additional or fewer plural forms. Thus, the I18n API provides a flexible pluralization feature.

The :count interpolation variable has a special role in that it both is interpolated to the translation and used to pick a pluralization from the translations according to the pluralization rules defined in the
pluralization backend. By default, only the English pluralization rules are applied.

```ruby
I18n.backend.store_translations :en, inbox: {
  zero: "no messages", # optional
  one: "one message",
  other: "%{count} messages"
}
I18n.translate :inbox, count: 2
# => '2 messages'

I18n.translate :inbox, count: 1
# => 'one message'

I18n.translate :inbox, count: 0
# => 'no messages'
```

The algorithm for pluralizations in :en is as simple as:

```ruby
lookup_key = :zero if count == 0 && entry.has_key?(:zero)
lookup_key ||= count == 1 ? :one : :other
entry[lookup_key]
```

The translation denoted as :one is regarded as singular, and the :other is used as plural. If the count is zero, and a :zero entry is present, then it will be used instead of :other.

If the lookup for the key does not return a Hash suitable for pluralization, an I18n::InvalidPluralizationData exception is raised.


#### 4.2.1. Locale-specific Rules

The I18n gem provides a Pluralization backend that can be used to enable locale-specific rules. Include it
to the Simple backend, then add the localized pluralization algorithms to translation store, as i18n.plural.rule.

```ruby
I18n::Backend::Simple.include(I18n::Backend::Pluralization)
I18n.backend.store_translations :pt, i18n: { plural: { rule: lambda { |n| [0, 1].include?(n) ? :one : :other } } }
I18n.backend.store_translations :pt, apples: { one: "one or none", other: "more than one" }

I18n.t :apples, count: 0, locale: :pt
# => 'one or none'
```

Alternatively, the separate gem rails-i18n can be used to provide a fuller set of locale-specific pluralization rules.


### 4.3. Setting and Passing a Locale

The locale can be either set pseudo-globally to I18n.locale (which uses Thread.current in the same way as, for example, Time.zone) or can be passed as an option to #translate and #localize.

If no locale is passed, I18n.locale is used:

```ruby
I18n.locale = :de
I18n.t :foo
I18n.l Time.now
```

Explicitly passing a locale:

```ruby
I18n.t :foo, locale: :de
I18n.l Time.now, locale: :de
```

The I18n.locale defaults to I18n.default_locale which defaults to :en. The default locale can be set like this:

```ruby
I18n.default_locale = :de
```


### 4.4. Using Safe HTML Translations

Keys with a '_html' suffix and keys named 'html' are marked as HTML safe. When you use them in views the HTML will not be escaped.

```yaml
# config/locales/en.yml
en:
  welcome: <b>welcome!</b>
  hello_html: <b>hello!</b>
  title:
    html: <b>title!</b>
```

```ruby
<!-- app/views/home/index.html.erb -->
<div><%= t('welcome') %></div>
<div><%= raw t('welcome') %></div>
<div><%= t('hello_html') %></div>
<div><%= t('title.html') %></div>
```

Interpolation escapes as needed though. For example, given:

```yaml
en:
  welcome_html: "<b>Welcome %{username}!</b>"
```

you can safely pass the username as set by the user:

```ruby
<%# This is safe, it is going to be escaped if needed. %>
<%= t('welcome_html', username: @current_user.username) %>
```

Safe strings on the other hand are interpolated verbatim.

Automatic conversion to HTML safe translate text is only available from the translate (or t) helper method. This works in views and controllers.


### 4.5. Translations for Active Record Models

You can use the methods Model.model_name.human and Model.human_attribute_name(attribute) to transparently look up translations for your model and attribute names.

For example when you add the following translations:

```yaml
en:
  activerecord:
    models:
      user: Customer
    attributes:
      user:
        login: "Handle"
      # will translate User attribute "login" as "Handle"
```

Then User.model_name.human will return "Customer" and User.human_attribute_name("login") will return "Handle".

You can also set a plural form for model names, adding as following:

```yaml
en:
  activerecord:
    models:
      user:
        one: Customer
        other: Customers
```

Then User.model_name.human(count: 2) will return "Customers". With count: 1 or without params will return "Customer".

In the event you need to access nested attributes within a given model, you should nest these under model/attribute at the model level of your translation file:

```yaml
en:
  activerecord:
    attributes:
      user/role:
        admin: "Admin"
        contributor: "Contributor"
```

Then User.human_attribute_name("role.admin") will return "Admin".

If you are using a class which includes ActiveModel and does not inherit from ActiveRecord::Base, replace activerecord with activemodel in the above key paths.


#### 4.5.1. Error Message Scopes

Active Record validation error messages can also be translated easily. Active Record gives you a couple of namespaces where you can place your message translations in order to provide different messages and translation for certain models, attributes, and/or validations. It also transparently takes single table inheritance into account.

This gives you quite powerful means to flexibly adjust your messages to your application's needs.

Consider a User model with a validation for the name attribute like this:

```ruby
class User < ApplicationRecord
  validates :name, presence: true
end
```

The key for the error message in this case is :blank. Thus, in our example it will try the following keys in this order and return the first result:

```
activerecord.errors.models.user.attributes.name.blank
activerecord.errors.models.user.blank
activerecord.errors.messages.blank
errors.attributes.name.blank
errors.messages.blank
```

To explain it more abstractly, it returns the first key that matches in the order of the following list.

```
activerecord.errors.models.[model_name].attributes.[attribute_name].[key]
activerecord.errors.models.[model_name].[key]
activerecord.errors.messages.[key]
errors.attributes.[attribute_name].[key]
errors.messages.[key]
```

When your models are additionally using inheritance then the messages are looked up in the inheritance chain.

For example, you might have an Admin model inheriting from User:

```ruby
class Admin < User
  validates :name, presence: true
end
```

Then Active Record will look for messages in this order:

```ruby
activerecord.errors.models.admin.attributes.name.blank
activerecord.errors.models.admin.blank
activerecord.errors.models.user.attributes.name.blank
activerecord.errors.models.user.blank
activerecord.errors.messages.blank
errors.attributes.name.blank
errors.messages.blank
```

This way you can provide special translations for various error messages at different points in your model's inheritance chain and in the attributes, models, or default scopes.


#### 4.5.2. Error Message Interpolation

The translated model name, translated attribute name, and value are always available for interpolation as model, attribute and value respectively.

So, for example, instead of the default error message "can't be blank" you could use the attribute name like this : "Please fill in your %{attribute}".

- count, where available, can be used for pluralization if present:


### 4.6. Translations for Action Mailer E-Mail Subjects

If you don't pass a subject to the mail method, Action Mailer will try to find
it in your translations. The performed lookup will use the pattern
<mailer_scope>.<action_name>.subject to construct the key.

```ruby
# user_mailer.rb
class UserMailer < ActionMailer::Base
  def welcome(user)
    #...
  end
end
```

```yaml
en:
  user_mailer:
    welcome:
      subject: "Welcome to Rails Guides!"
```

To send parameters to interpolation use the default_i18n_subject method on the mailer.

```ruby
# user_mailer.rb
class UserMailer < ActionMailer::Base
  def welcome(user)
    mail(to: user.email, subject: default_i18n_subject(user: user.name))
  end
end
```

```yaml
en:
  user_mailer:
    welcome:
      subject: "%{user}, welcome to Rails Guides!"
```


### 4.7. Overview of Other Built-In Methods that Provide I18n Support

Rails uses fixed strings and other localizations, such as format strings and other format information in a couple of helpers. Here's a brief overview.


#### 4.7.1. Action View Helper Methods

- distance_of_time_in_words translates and pluralizes its result and interpolates the number of seconds, minutes, hours, and so on. See datetime.distance_in_words translations.

- datetime_select and select_month use translated month names for populating the resulting select tag. See date.month_names for translations. datetime_select also looks up the order option from date.order (unless you pass the option explicitly). All date selection helpers translate the prompt using the translations in the datetime.prompts scope if applicable.

- The number_to_currency, number_with_precision, number_to_percentage, number_with_delimiter, and number_to_human_size helpers use the number format settings located in the number scope.

distance_of_time_in_words translates and pluralizes its result and interpolates the number of seconds, minutes, hours, and so on. See datetime.distance_in_words translations.

datetime_select and select_month use translated month names for populating the resulting select tag. See date.month_names for translations. datetime_select also looks up the order option from date.order (unless you pass the option explicitly). All date selection helpers translate the prompt using the translations in the datetime.prompts scope if applicable.

The number_to_currency, number_with_precision, number_to_percentage, number_with_delimiter, and number_to_human_size helpers use the number format settings located in the number scope.


#### 4.7.2. Active Model Methods

- model_name.human and human_attribute_name use translations for model names and attribute names if available in the activerecord.models scope. They also support translations for inherited class names (e.g. for use with STI) as explained above in "Error message scopes".

- ActiveModel::Errors#generate_message (which is used by Active Model validations but may also be used manually) uses model_name.human and human_attribute_name (see above). It also translates the error message and supports translations for inherited class names as explained above in "Error message scopes".

- ActiveModel::Error#full_message and ActiveModel::Errors#full_messages prepend the attribute name to the error message using a format looked up from errors.format (default: "%{attribute} %{message}"). To customize the default format, override it in the app's locale files. To customize the format per model or per attribute, see config.active_model.i18n_customize_full_message.

model_name.human and human_attribute_name use translations for model names and attribute names if available in the activerecord.models scope. They also support translations for inherited class names (e.g. for use with STI) as explained above in "Error message scopes".

ActiveModel::Errors#generate_message (which is used by Active Model validations but may also be used manually) uses model_name.human and human_attribute_name (see above). It also translates the error message and supports translations for inherited class names as explained above in "Error message scopes".

ActiveModel::Error#full_message and ActiveModel::Errors#full_messages prepend the attribute name to the error message using a format looked up from errors.format (default: "%{attribute} %{message}"). To customize the default format, override it in the app's locale files. To customize the format per model or per attribute, see config.active_model.i18n_customize_full_message.


#### 4.7.3. Active Support Methods

- Array#to_sentence uses format settings as given in the support.array scope.


## 5. How to Store your Custom Translations

The Simple backend shipped with Active Support allows you to store translations in both plain Ruby and YAML format.2

For example a Ruby Hash providing translations can look like this:

```ruby
{
  pt: {
    foo: {
      bar: "baz"
    }
  }
}
```

The equivalent YAML file would look like this:

```yaml
pt:
  foo:
    bar: baz
```

As you see, in both cases the top level key is the locale. :foo is a namespace key and :bar is the key for the translation "baz".

Here is a "real" example from the Active Support en.yml translations YAML file:

```yaml
en:
  date:
    formats:
      default: "%Y-%m-%d"
      short: "%b %d"
      long: "%B %d, %Y"
```

So, all of the following equivalent lookups will return the :short date format "%b %d":

```ruby
I18n.t "date.formats.short"
I18n.t "formats.short", scope: :date
I18n.t :short, scope: "date.formats"
I18n.t :short, scope: [:date, :formats]
```

Generally we recommend using YAML as a format for storing translations. There are cases, though, where you want to store Ruby lambdas as part of your locale data, e.g. for special date formats.


## 6. Customize Your I18n Setup


### 6.1. Using Different Backends

For several reasons the Simple backend shipped with Active Support only does the "simplest thing that could possibly work" for Ruby on Rails3 ... which means that it is only guaranteed to work for English and, as a side effect, languages that are very similar to English. Also, the simple backend is only capable of reading translations but cannot dynamically store them to any format.

That does not mean you're stuck with these limitations, though. The Ruby I18n gem makes it very easy to exchange the Simple backend implementation with something else that fits better for your needs, by passing a backend instance to the I18n.backend= setter.

For example, you can replace the Simple backend with the Chain backend to chain multiple backends together. This is useful when you want to use standard translations with a Simple backend but store custom application translations in a database or other backends.

With the Chain backend, you could use the Active Record backend and fall back to the (default) Simple backend:

```ruby
I18n.backend = I18n::Backend::Chain.new(I18n::Backend::ActiveRecord.new, I18n.backend)
```


### 6.2. Using Different Exception Handlers

The I18n API defines the following exceptions that will be raised by backends when the corresponding unexpected conditions occur:


#### 6.2.1. Customizing how I18n::MissingTranslationData is handled

If config.i18n.raise_on_missing_translations is true, I18n::MissingTranslationData errors will be raised from views and controllers. If the value is :strict, models also raise the error. It's a good idea to turn this on in your test environment, so you can catch places where missing translations are requested.

If config.i18n.raise_on_missing_translations is false (the default in all environments), the exception's error message will be printed. This contains the missing key/scope so you can fix your code.

If you want to customize this behavior further, you should set config.i18n.raise_on_missing_translations = false and then implement a I18n.exception_handler. The custom exception handler can be a proc or a class with a call method:

```ruby
# config/initializers/i18n.rb
module I18n
  class RaiseExceptForSpecificKeyExceptionHandler
    def call(exception, locale, key, options)
      if key == "special.key"
        "translation missing!" # return this, don't raise it
      elsif exception.is_a?(MissingTranslation)
        raise exception.to_exception
      else
        raise exception
      end
    end
  end
end

I18n.exception_handler = I18n::RaiseExceptForSpecificKeyExceptionHandler.new
```

This would raise all exceptions the same way the default handler would, except in the case of I18n.t("special.key").


## 7. Translating Model Content

The I18n API described in this guide is primarily intended for translating interface strings. If you are looking to translate model content (e.g. blog posts), you will need a different solution to help with this.

Several gems can help with this:

- Mobility: Provides support for storing translations in many formats, including translation tables, JSON columns (PostgreSQL), etc.

- Traco: Translatable columns stored in the model table itself


## 8. Conclusion

At this point you should have a good overview about how I18n support in Ruby on Rails works and are ready to start translating your project.


## 9. Contributing to Rails I18n

I18n support in Ruby on Rails was introduced in the release 2.2 and is still evolving. The project follows the good Ruby on Rails development tradition of evolving solutions in gems and real applications first, and only then cherry-picking the best-of-breed of most widely useful features for inclusion in the core.

Thus we encourage everybody to experiment with new ideas and features in gems or other libraries and make them available to the community. (Don't forget to announce your work on our mailing list!)

If you find your own locale (language) missing from our example translations data repository for Ruby on Rails, please fork the repository, add your data, and send a pull request.


## 10. Resources

- GitHub: rails-i18n - Code repository and issue tracker for the rails-i18n project. Most importantly you can find lots of example translations for Rails that should work for your application in most cases.

- GitHub: i18n - Code repository and issue tracker for the i18n gem.


## 11. Authors

- Sven Fuchs (initial author)

- Karel Minařík


## 12. Footnotes

1 Or, to quote Wikipedia: "Internationalization is the process of designing a software application so that it can be adapted to various languages and regions without engineering changes. Localization is the process of adapting software for a specific region or language by adding locale-specific components and translating text."

2 Other backends might allow or require to use other formats, e.g. a GetText backend might allow to read GetText files.

3 One of these reasons is that we don't want to imply any unnecessary load for applications that do not need any I18n capabilities, so we need to keep the I18n library as simple as possible for English. Another reason is that it is virtually impossible to implement a one-fits-all solution for all problems related to I18n for all existing languages. So a solution that allows us to exchange the entire implementation easily is appropriate anyway. This also makes it much easier to experiment with custom features and extensions.


---

# Chapters

Active Support is the Ruby on Rails component responsible for providing Ruby
language extensions and utilities.

It offers a richer bottom-line at the language level, targeted both at the development of Rails applications, and at the development of Ruby on Rails itself.

After reading this guide, you will know:

- What Core Extensions are.

- How to load all extensions.

- How to cherry-pick just the extensions you want.

- What extensions Active Support provides.


## 1. How to Load Core Extensions


### 1.1. Stand-Alone Active Support

In order to have the smallest default footprint possible, Active Support loads the minimum dependencies by default. It is broken in small pieces so that only the desired extensions can be loaded. It also has some convenience entry points to load related extensions in one shot, even everything.

Thus, after a simple require like:

```ruby
require "active_support"
```

only the extensions required by the Active Support framework are loaded.


#### 1.1.1. Cherry-picking a Definition

This example shows how to load Hash#with_indifferent_access.  This extension enables the conversion of a Hash into an ActiveSupport::HashWithIndifferentAccess which permits access to the keys as either strings or symbols.

```ruby
{ a: 1 }.with_indifferent_access["a"] # => 1
```

For every single method defined as a core extension this guide has a note that says where such a method is defined. In the case of with_indifferent_access the note reads:

Defined in active_support/core_ext/hash/indifferent_access.rb.

That means that you can require it like this:

```ruby
require "active_support"
require "active_support/core_ext/hash/indifferent_access"
```

Active Support has been carefully revised so that cherry-picking a file loads only strictly needed dependencies, if any.


#### 1.1.2. Loading Grouped Core Extensions

The next level is to simply load all extensions to Hash. As a rule of thumb, extensions to SomeClass are available in one shot by loading active_support/core_ext/some_class.

Thus, to load all extensions to Hash (including with_indifferent_access):

```ruby
require "active_support"
require "active_support/core_ext/hash"
```


#### 1.1.3. Loading All Core Extensions

You may prefer just to load all core extensions, there is a file for that:

```ruby
require "active_support"
require "active_support/core_ext"
```


#### 1.1.4. Loading All Active Support

And finally, if you want to have all Active Support available just issue:

```ruby
require "active_support/all"
```

That does not even put the entire Active Support in memory upfront indeed, some stuff is configured via autoload, so it is only loaded if used.


### 1.2. Active Support Within a Ruby on Rails Application

A Ruby on Rails application loads all Active Support unless config.active_support.bare is true. In that case, the application will only load what the framework itself cherry-picks for its own needs, and can still cherry-pick itself at any granularity level, as explained in the previous section.


## 2. Extensions to All Objects


### 2.1. blank? and present?

The following values are considered to be blank in a Rails application:

- nil and false,

- strings composed only of whitespace (see note below),

- empty arrays and hashes, and

- any other object that responds to empty? and is empty.

nil and false,

strings composed only of whitespace (see note below),

empty arrays and hashes, and

any other object that responds to empty? and is empty.

The predicate for strings uses the Unicode-aware character class [:space:], so for example U+2029 (paragraph separator) is considered to be whitespace.

Note that numbers are not mentioned. In particular, 0 and 0.0 are not blank.

For example, this method from ActionController::HttpAuthentication::Token::ControllerMethods uses blank? for checking whether a token is present:

```ruby
def authenticate(controller, &login_procedure)
  token, options = token_and_options(controller.request)
  unless token.blank?
    login_procedure.call(token, options)
  end
end
```

The method present? is equivalent to !blank?. This example is taken from ActionDispatch::Http::Cache::Response:

```ruby
def set_conditional_cache_control!
  unless self["Cache-Control"].present?
    # ...
  end
end
```

Defined in active_support/core_ext/object/blank.rb.


### 2.2. presence

The presence method returns its receiver if present?, and nil otherwise. It is useful for idioms like this:

```ruby
host = config[:host].presence || "localhost"
```

Defined in active_support/core_ext/object/blank.rb.


### 2.3. duplicable?

As of Ruby 2.5, most objects can be duplicated via dup or clone:

```ruby
"foo".dup           # => "foo"
"".dup              # => ""
Rational(1).dup     # => (1/1)
Complex(0).dup      # => (0+0i)
1.method(:+).dup    # => TypeError (allocator undefined for Method)
```

Active Support provides duplicable? to query an object about this:

```ruby
"foo".duplicable?           # => true
"".duplicable?              # => true
Rational(1).duplicable?     # => true
Complex(1).duplicable?      # => true
1.method(:+).duplicable?    # => false
```

Any class can disallow duplication by removing dup and clone or raising exceptions from them. Thus only rescue can tell whether a given arbitrary object is duplicable. duplicable? depends on the hard-coded list above, but it is much faster than rescue. Use it only if you know the hard-coded list is enough in your use case.

Defined in active_support/core_ext/object/duplicable.rb.


### 2.4. deep_dup

The deep_dup method returns a deep copy of a given object. Normally, when you dup an object that contains other objects, Ruby does not dup them, so it creates a shallow copy of the object. If you have an array with a string, for example, it will look like this:

```ruby
array     = ["string"]
duplicate = array.dup

duplicate.push "another-string"

# the object was duplicated, so the element was added only to the duplicate
array     # => ["string"]
duplicate # => ["string", "another-string"]

duplicate.first.gsub!("string", "foo")

# first element was not duplicated, it will be changed in both arrays
array     # => ["foo"]
duplicate # => ["foo, "another-string"]
```

As you can see, after duplicating the Array instance, we got another object, therefore we can modify it and the original object will stay unchanged. This is not true for array's elements, however. Since dup does not make a deep copy, the string inside the array is still the same object.

If you need a deep copy of an object, you should use deep_dup. Here is an example:

```ruby
array     = ["string"]
duplicate = array.deep_dup

duplicate.first.gsub!("string", "foo")

array     # => ["string"]
duplicate # => ["foo"]
```

If the object is not duplicable, deep_dup will just return it:

```ruby
number = 1
duplicate = number.deep_dup
number.object_id == duplicate.object_id   # => true
```

Defined in active_support/core_ext/object/deep_dup.rb.


### 2.5. try

When you want to call a method on an object only if it is not nil, the simplest way to achieve it is with conditional statements, adding unnecessary clutter. The alternative is to use try. try is like Object#public_send except that it returns nil if sent to nil.

Here is an example:

```ruby
# without try
unless @number.nil?
  @number.next
end

# with try
@number.try(:next)
```

Another example is this code from ActiveRecord::ConnectionAdapters::AbstractAdapter where @logger could be nil. You can see that the code uses try and avoids an unnecessary check.

```ruby
def log_info(sql, name, ms)
  if @logger.try(:debug?)
    name = "%s (%.1fms)" % [name || "SQL", ms]
    @logger.debug(format_log_entry(name, sql.squeeze(" ")))
  end
end
```

try can also be called without arguments but a block, which will only be executed if the object is not nil:

```ruby
@person.try { |p| "#{p.first_name} #{p.last_name}" }
```

Note that try will swallow no-method errors, returning nil instead. If you want to protect against typos, use try! instead:

```ruby
@number.try(:nest)  # => nil
@number.try!(:nest) # NoMethodError: undefined method `nest' for 1:Integer
```

Defined in active_support/core_ext/object/try.rb.


### 2.6. class_eval(*args, &block)

You can evaluate code in the context of any object's singleton class using class_eval:

```ruby
class Proc
  def bind(object)
    block, time = self, Time.current
    object.class_eval do
      method_name = "__bind_#{time.to_i}_#{time.usec}"
      define_method(method_name, &block)
      method = instance_method(method_name)
      remove_method(method_name)
      method
    end.bind(object)
  end
end
```

Defined in active_support/core_ext/kernel/singleton_class.rb.


### 2.7. acts_like?(duck)

The method acts_like? provides a way to check whether some class acts like some other class based on a simple convention: a class that provides the same interface as String defines

```ruby
def acts_like_string?
end
```

which is only a marker, its body or return value are irrelevant. Then, client code can query for duck-type-safeness this way:

```ruby
some_klass.acts_like?(:string)
```

Rails has classes that act like Date or Time and follow this contract.

Defined in active_support/core_ext/object/acts_like.rb.


### 2.8. to_param

All objects in Rails respond to the method to_param, which is meant to return something that represents them as values in a query string, or as URL fragments.

By default to_param just calls to_s:

```ruby
7.to_param # => "7"
```

The return value of to_param should not be escaped:

```ruby
"Tom & Jerry".to_param # => "Tom & Jerry"
```

Several classes in Rails overwrite this method.

For example nil, true, and false return themselves. Array#to_param calls to_param on the elements and joins the result with "/":

```ruby
[0, true, String].to_param # => "0/true/String"
```

Notably, the Rails routing system calls to_param on models to get a value for the :id placeholder. ActiveRecord::Base#to_param returns the id of a model, but you can redefine that method in your models. For example, given

```ruby
class User
  def to_param
    "#{id}-#{name.parameterize}"
  end
end
```

we get:

```ruby
user_path(@user) # => "/users/357-john-smith"
```

Controllers need to be aware of any redefinition of to_param because when a request like that comes in "357-john-smith" is the value of params[:id].

Defined in active_support/core_ext/object/to_param.rb.


### 2.9. to_query

The to_query method constructs a query string that associates a given key with the return value of to_param. For example, with the following to_param definition:

```ruby
class User
  def to_param
    "#{id}-#{name.parameterize}"
  end
end
```

we get:

```ruby
current_user.to_query("user") # => "user=357-john-smith"
```

This method escapes whatever is needed, both for the key and the value:

```ruby
account.to_query("company[name]")
# => "company%5Bname%5D=Johnson+%26+Johnson"
```

so its output is ready to be used in a query string.

Arrays return the result of applying to_query to each element with key[] as key, and join the result with "&":

```ruby
[3.4, -45.6].to_query("sample")
# => "sample%5B%5D=3.4&sample%5B%5D=-45.6"
```

Hashes also respond to to_query but with a different signature. If no argument is passed a call generates a sorted series of key/value assignments calling to_query(key) on its values. Then it joins the result with "&":

```ruby
{ c: 3, b: 2, a: 1 }.to_query # => "a=1&b=2&c=3"
```

The method Hash#to_query accepts an optional namespace for the keys:

```ruby
{ id: 89, name: "John Smith" }.to_query("user")
# => "user%5Bid%5D=89&user%5Bname%5D=John+Smith"
```

Defined in active_support/core_ext/object/to_query.rb.


### 2.10. with_options

The method with_options provides a way to factor out common options in a series of method calls.

Given a default options hash, with_options yields a proxy object to a block. Within the block, methods called on the proxy are forwarded to the receiver with their options merged. For example, you get rid of the duplication in:

```ruby
class Account < ApplicationRecord
  has_many :customers, dependent: :destroy
  has_many :products,  dependent: :destroy
  has_many :invoices,  dependent: :destroy
  has_many :expenses,  dependent: :destroy
end
```

this way:

```ruby
class Account < ApplicationRecord
  with_options dependent: :destroy do |assoc|
    assoc.has_many :customers
    assoc.has_many :products
    assoc.has_many :invoices
    assoc.has_many :expenses
  end
end
```

That idiom may convey grouping to the reader as well. For example, say you want to send a newsletter whose language depends on the user. Somewhere in the mailer you could group locale-dependent bits like this:

```ruby
I18n.with_options locale: user.locale, scope: "newsletter" do |i18n|
  subject i18n.t :subject
  body    i18n.t :body, user_name: user.name
end
```

Since with_options forwards calls to its receiver they can be nested. Each nesting level will merge inherited defaults in addition to their own.

Defined in active_support/core_ext/object/with_options.rb.


### 2.11. JSON Support

Active Support provides a better implementation of to_json than the json gem ordinarily provides for Ruby objects. This is because some classes, like Hash and Process::Status need special handling in order to provide a proper JSON representation.

Defined in active_support/core_ext/object/json.rb.


### 2.12. Instance Variables

Active Support provides several methods to ease access to instance variables.


#### 2.12.1. instance_values

The method instance_values returns a hash that maps instance variable names without "@" to their
corresponding values. Keys are strings:

```ruby
class C
  def initialize(x, y)
    @x, @y = x, y
  end
end

C.new(0, 1).instance_values # => {"x" => 0, "y" => 1}
```

Defined in active_support/core_ext/object/instance_variables.rb.


#### 2.12.2. instance_variable_names

The method instance_variable_names returns an array. Each name includes the "@" sign.

```ruby
class C
  def initialize(x, y)
    @x, @y = x, y
  end
end

C.new(0, 1).instance_variable_names # => ["@x", "@y"]
```

Defined in active_support/core_ext/object/instance_variables.rb.


### 2.13. Silencing Warnings and Exceptions

The methods silence_warnings and enable_warnings change the value of $VERBOSE accordingly for the duration of their block, and reset it afterwards:

```ruby
silence_warnings { Object.const_set "RAILS_DEFAULT_LOGGER", logger }
```

Silencing exceptions is also possible with suppress. This method receives an arbitrary number of exception classes. If an exception is raised during the execution of the block and is kind_of? any of the arguments, suppress captures it and returns silently. Otherwise the exception is not captured:

```ruby
# If the user is locked, the increment is lost, no big deal.
suppress(ActiveRecord::StaleObjectError) do
  current_user.increment! :visits
end
```

Defined in active_support/core_ext/kernel/reporting.rb.


### 2.14. in?

The predicate in? tests if an object is included in another object. An ArgumentError exception will be raised if the argument passed does not respond to include?.

Examples of in?:

```ruby
1.in?([1, 2])        # => true
"lo".in?("hello")   # => true
25.in?(30..50)      # => false
1.in?(1)            # => ArgumentError
```

Defined in active_support/core_ext/object/inclusion.rb.


## 3. Extensions to Module


### 3.1. Attributes


#### 3.1.1. alias_attribute

Model attributes have a reader, a writer, and a predicate. You can alias a model attribute having the corresponding three methods all defined for you by using alias_attribute. As in other aliasing methods, the new name is the first argument, and the old name is the second (one mnemonic is that they go in the same order as if you did an assignment):

```ruby
class User < ApplicationRecord
  # You can refer to the email column as "login".
  # This can be meaningful for authentication code.
  alias_attribute :login, :email
end
```

Defined in active_support/core_ext/module/aliasing.rb.


#### 3.1.2. Internal Attributes

When you are defining an attribute in a class that is meant to be subclassed, name collisions are a risk. That's remarkably important for libraries.

Active Support defines the macros attr_internal_reader, attr_internal_writer, and attr_internal_accessor. They behave like their Ruby built-in attr_* counterparts, except they name the underlying instance variable in a way that makes collisions less likely.

The macro attr_internal is a synonym for attr_internal_accessor:

```ruby
# library
class ThirdPartyLibrary::Crawler
  attr_internal :log_level
end

# client code
class MyCrawler < ThirdPartyLibrary::Crawler
  attr_accessor :log_level
end
```

In the previous example it could be the case that :log_level does not belong to the public interface of the library and it is only used for development. The client code, unaware of the potential conflict, subclasses and defines its own :log_level. Thanks to attr_internal there's no collision.

By default the internal instance variable is named with a leading underscore, @_log_level in the example above. That's configurable via Module.attr_internal_naming_format though, you can pass any sprintf-like format string with a leading @ and a %s somewhere, which is where the name will be placed. The default is "@_%s".

Rails uses internal attributes in a few spots, for examples for views:

```ruby
module ActionView
  class Base
    attr_internal :captures
    attr_internal :request, :layout
    attr_internal :controller, :template
  end
end
```

Defined in active_support/core_ext/module/attr_internal.rb.


#### 3.1.3. Module Attributes

The macros mattr_reader, mattr_writer, and mattr_accessor are the same as the cattr_* macros defined for class. In fact, the cattr_* macros are just aliases for the mattr_* macros. Check Class Attributes.

For example, the API for the logger of Active Storage is generated with mattr_accessor:

```ruby
module ActiveStorage
  mattr_accessor :logger
end
```

Defined in active_support/core_ext/module/attribute_accessors.rb.


### 3.2. Parents


#### 3.2.1. module_parent

The module_parent method on a nested named module returns the module that contains its corresponding constant:

```ruby
module X
  module Y
    module Z
    end
  end
end
M = X::Y::Z

X::Y::Z.module_parent # => X::Y
M.module_parent       # => X::Y
```

If the module is anonymous or belongs to the top-level, module_parent returns Object.

Note that in that case module_parent_name returns nil.

Defined in active_support/core_ext/module/introspection.rb.


#### 3.2.2. module_parent_name

The module_parent_name method on a nested named module returns the fully qualified name of the module that contains its corresponding constant:

```ruby
module X
  module Y
    module Z
    end
  end
end
M = X::Y::Z

X::Y::Z.module_parent_name # => "X::Y"
M.module_parent_name       # => "X::Y"
```

For top-level or anonymous modules module_parent_name returns nil.

Note that in that case module_parent returns Object.

Defined in active_support/core_ext/module/introspection.rb.


#### 3.2.3. module_parents

The method module_parents calls module_parent on the receiver and upwards until Object is reached. The chain is returned in an array, from bottom to top:

```ruby
module X
  module Y
    module Z
    end
  end
end
M = X::Y::Z

X::Y::Z.module_parents # => [X::Y, X, Object]
M.module_parents       # => [X::Y, X, Object]
```

Defined in active_support/core_ext/module/introspection.rb.


### 3.3. Anonymous

A module may or may not have a name:

```ruby
module M
end
M.name # => "M"

N = Module.new
N.name # => "N"

Module.new.name # => nil
```

You can check whether a module has a name with the predicate anonymous?:

```ruby
module M
end
M.anonymous? # => false

Module.new.anonymous? # => true
```

Note that being unreachable does not imply being anonymous:

```ruby
module M
end

m = Object.send(:remove_const, :M)

m.anonymous? # => false
```

though an anonymous module is unreachable by definition.

Defined in active_support/core_ext/module/anonymous.rb.


### 3.4. Method Delegation


#### 3.4.1. delegate

The macro delegate offers an easy way to forward methods.

Let's imagine that users in some application have login information in the User model but name and other data in a separate Profile model:

```ruby
class User < ApplicationRecord
  has_one :profile
end
```

With that configuration you get a user's name via their profile, user.profile.name, but it could be handy to still be able to access such attribute directly:

```ruby
class User < ApplicationRecord
  has_one :profile

  def name
    profile.name
  end
end
```

That is what delegate does for you:

```ruby
class User < ApplicationRecord
  has_one :profile

  delegate :name, to: :profile
end
```

It is shorter, and the intention more obvious.

The method must be public in the target.

The delegate macro accepts several methods:

```ruby
delegate :name, :age, :address, :twitter, to: :profile
```

When interpolated into a string, the :to option should become an expression that evaluates to the object the method is delegated to. Typically a string or symbol. Such an expression is evaluated in the context of the receiver:

```ruby
# delegates to the Rails constant
delegate :logger, to: :Rails

# delegates to the receiver's class
delegate :table_name, to: :class
```

If the :prefix option is true this is less generic, see below.

By default, if the delegation raises NoMethodError and the target is nil the exception is propagated. You can ask that nil is returned instead with the :allow_nil option:

```ruby
delegate :name, to: :profile, allow_nil: true
```

With :allow_nil the call user.name returns nil if the user has no profile.

The option :prefix adds a prefix to the name of the generated method. This may be handy for example to get a better name:

```ruby
delegate :street, to: :address, prefix: true
```

The previous example generates address_street rather than street.

Since in this case the name of the generated method is composed of the target object and target method names, the :to option must be a method name.

A custom prefix may also be configured:

```ruby
delegate :size, to: :attachment, prefix: :avatar
```

In the previous example the macro generates avatar_size rather than size.

The option :private changes methods scope:

```ruby
delegate :date_of_birth, to: :profile, private: true
```

The delegated methods are public by default. Pass private: true to change that.

Defined in active_support/core_ext/module/delegation.rb.


#### 3.4.2. delegate_missing_to

Imagine you would like to delegate everything missing from the User object,
to the Profile one. The delegate_missing_to macro lets you implement this
in a breeze:

```ruby
class User < ApplicationRecord
  has_one :profile

  delegate_missing_to :profile
end
```

The target can be anything callable within the object, e.g. instance variables,
methods, constants, etc. Only the public methods of the target are delegated.

Defined in active_support/core_ext/module/delegation.rb.


### 3.5. Redefining Methods

There are cases where you need to define a method with define_method, but don't know whether a method with that name already exists. If it does, a warning is issued if they are enabled. No big deal, but not clean either.

The method redefine_method prevents such a potential warning, removing the existing method before if needed.

You can also use silence_redefinition_of_method if you need to define
the replacement method yourself (because you're using delegate, for
example).

Defined in active_support/core_ext/module/redefine_method.rb.


## 4. Extensions to Class


### 4.1. Class Attributes


#### 4.1.1. class_attribute

The method class_attribute declares one or more inheritable class attributes that can be overridden at any level down the hierarchy.

```ruby
class A
  class_attribute :x
end

class B < A; end

class C < B; end

A.x = :a
B.x # => :a
C.x # => :a

B.x = :b
A.x # => :a
C.x # => :b

C.x = :c
A.x # => :a
B.x # => :b
```

For example ActionMailer::Base defines:

```ruby
class_attribute :default_params
self.default_params = {
  mime_version: "1.0",
  charset: "UTF-8",
  content_type: "text/plain",
  parts_order: [ "text/plain", "text/enriched", "text/html" ]
}.freeze
```

They can also be accessed and overridden at the instance level.

```ruby
A.x = 1

a1 = A.new
a2 = A.new
a2.x = 2

a1.x # => 1, comes from A
a2.x # => 2, overridden in a2
```

The generation of the writer instance method can be prevented by setting the option :instance_writer to false.

```ruby
module ActiveRecord
  class Base
    class_attribute :table_name_prefix, instance_writer: false, default: "my"
  end
end
```

A model may find that option useful as a way to prevent mass-assignment from setting the attribute.

The generation of the reader instance method can be prevented by setting the option :instance_reader to false.

```ruby
class A
  class_attribute :x, instance_reader: false
end

A.new.x = 1
A.new.x # NoMethodError
```

For convenience class_attribute also defines an instance predicate which is the double negation of what the instance reader returns. In the examples above it would be called x?.

When :instance_reader is false, the instance predicate returns a NoMethodError just like the reader method.

If you do not want the instance predicate, pass instance_predicate: false and it will not be defined.

Defined in active_support/core_ext/class/attribute.rb.


#### 4.1.2. cattr_reader, cattr_writer, and cattr_accessor

The macros cattr_reader, cattr_writer, and cattr_accessor are analogous to their attr_* counterparts but for classes. They initialize a class variable to nil unless it already exists, and generate the corresponding class methods to access it:

```ruby
class MysqlAdapter < AbstractAdapter
  # Generates class methods to access @@emulate_booleans.
  cattr_accessor :emulate_booleans
end
```

Also, you can pass a block to cattr_* to set up the attribute with a default value:

```ruby
class MysqlAdapter < AbstractAdapter
  # Generates class methods to access @@emulate_booleans with default value of true.
  cattr_accessor :emulate_booleans, default: true
end
```

Instance methods are also created for convenience, but they are simply proxies to the internal value which is shared among the class. As a result, when an instance modifies the value, this affects the entire class hierarchy. This behavior is different than class_attribute (see above).

For example:

```ruby
class Foo
  cattr_accessor :bar
end

instance = Foo.new

Foo.bar = 1
instance.bar # => 1

instance.bar = 2
Foo.bar # => 2
```

The generation of the reader instance method can be prevented by setting :instance_reader to false and the generation of the writer instance method can be prevented by setting :instance_writer to false. Generation of both methods can be prevented by setting :instance_accessor to false. In all cases, the value must be exactly false and not any false value.

```ruby
module A
  class B
    # No first_name instance reader is generated.
    cattr_accessor :first_name, instance_reader: false
    # No last_name= instance writer is generated.
    cattr_accessor :last_name, instance_writer: false
    # No surname instance reader or surname= writer is generated.
    cattr_accessor :surname, instance_accessor: false
  end
end
```

A model may find it useful to set :instance_accessor to false as a way to prevent mass-assignment from setting the attribute.

Defined in active_support/core_ext/module/attribute_accessors.rb.


### 4.2. Descendants


#### 4.2.1. descendants

The descendants method returns all classes that are < than its receiver:

```ruby
class C; end
C.descendants # => []

class B < C; end
C.descendants # => [B]

class A < B; end
C.descendants # => [B, A]

class D < C; end
C.descendants # => [B, A, D]
```

The order in which these classes are returned is unspecified.

Defined in active_support/core_ext/class/subclasses.rb.


## 5. Extensions to String


### 5.1. Output Safety


#### 5.1.1. Motivation

Inserting data into HTML templates needs extra care. For example, you can't just interpolate @review.title verbatim into an HTML page. For one thing, if the review title is "Flanagan & Matz rules!" the output won't be well-formed because an ampersand has to be escaped as "&amp;". What's more, depending on the application, that may be a big security hole because users can inject malicious HTML setting a hand-crafted review title. Check out the section about cross-site scripting in the Security guide for further information about the risks.


#### 5.1.2. Safe Strings

Active Support has the concept of (html) safe strings. A safe string is one that is marked as being insertable into HTML as is. It is trusted, no matter whether it has been escaped or not.

Strings are considered to be unsafe by default:

```ruby
"".html_safe? # => false
```

You can obtain a safe string from a given one with the html_safe method:

```ruby
s = "".html_safe
s.html_safe? # => true
```

It is important to understand that html_safe performs no escaping whatsoever, it is just an assertion:

```ruby
s = "<script>...</script>".html_safe
s.html_safe? # => true
s            # => "<script>...</script>"
```

It is your responsibility to ensure calling html_safe on a particular string is fine.

If you append onto a safe string, either in-place with concat/<<, or with +, the result is a safe string. Unsafe arguments are escaped:

```ruby
"".html_safe + "<" # => "&lt;"
```

Safe arguments are directly appended:

```ruby
"".html_safe + "<".html_safe # => "<"
```

These methods should not be used in ordinary views. Unsafe values are automatically escaped:

```ruby
<%= @review.title %> <%# fine, escaped if needed %>
```

To insert something verbatim use the raw helper rather than calling html_safe:

```ruby
<%= raw @cms.current_template %> <%# inserts @cms.current_template as is %>
```

or, equivalently, use <%==:

```ruby
<%== @cms.current_template %> <%# inserts @cms.current_template as is %>
```

The raw helper calls html_safe for you:

```ruby
def raw(stringish)
  stringish.to_s.html_safe
end
```

Defined in active_support/core_ext/string/output_safety.rb.


#### 5.1.3. Transformation

As a rule of thumb, except perhaps for concatenation as explained above, any method that may change a string gives you an unsafe string. These are downcase, gsub, strip, chomp, underscore, etc.

In the case of in-place transformations like gsub! the receiver itself becomes unsafe.

The safety bit is lost always, no matter whether the transformation actually changed something.


#### 5.1.4. Conversion and Coercion

Calling to_s on a safe string returns a safe string, but coercion with to_str returns an unsafe string.


#### 5.1.5. Copying

Calling dup or clone on safe strings yields safe strings.


### 5.2. remove

The method remove will remove all occurrences of the pattern:

```ruby
"Hello World".remove(/Hello /) # => "World"
```

There's also the destructive version String#remove!.

Defined in active_support/core_ext/string/filters.rb.


### 5.3. squish

The method squish strips leading and trailing whitespace, and substitutes runs of whitespace with a single space each:

```ruby
" \n  foo\n\r \t bar \n".squish # => "foo bar"
```

There's also the destructive version String#squish!.

Note that it handles both ASCII and Unicode whitespace.

Defined in active_support/core_ext/string/filters.rb.


### 5.4. truncate

The method truncate returns a copy of its receiver truncated after a given length:

```ruby
"Oh dear! Oh dear! I shall be late!".truncate(20)
# => "Oh dear! Oh dear!..."
```

Ellipsis can be customized with the :omission option:

```ruby
"Oh dear! Oh dear! I shall be late!".truncate(20, omission: "&hellip;")
# => "Oh dear! Oh &hellip;"
```

Note in particular that truncation takes into account the length of the omission string.

Pass a :separator to truncate the string at a natural break:

```ruby
"Oh dear! Oh dear! I shall be late!".truncate(18)
# => "Oh dear! Oh dea..."
"Oh dear! Oh dear! I shall be late!".truncate(18, separator: " ")
# => "Oh dear! Oh..."
```

The option :separator can be a regexp:

```ruby
"Oh dear! Oh dear! I shall be late!".truncate(18, separator: /\s/)
# => "Oh dear! Oh..."
```

In above examples "dear" gets cut first, but then :separator prevents it.

Defined in active_support/core_ext/string/filters.rb.


### 5.5. truncate_bytes

The method truncate_bytes returns a copy of its receiver truncated to at most bytesize bytes:

```ruby
"👍👍👍👍".truncate_bytes(15)
# => "👍👍👍…"
```

Ellipsis can be customized with the :omission option:

```ruby
"👍👍👍👍".truncate_bytes(15, omission: "🖖")
# => "👍👍🖖"
```

Defined in active_support/core_ext/string/filters.rb.


### 5.6. truncate_words

The method truncate_words returns a copy of its receiver truncated after a given number of words:

```ruby
"Oh dear! Oh dear! I shall be late!".truncate_words(4)
# => "Oh dear! Oh dear!..."
```

Ellipsis can be customized with the :omission option:

```ruby
"Oh dear! Oh dear! I shall be late!".truncate_words(4, omission: "&hellip;")
# => "Oh dear! Oh dear!&hellip;"
```

Pass a :separator to truncate the string at a natural break:

```ruby
"Oh dear! Oh dear! I shall be late!".truncate_words(3, separator: "!")
# => "Oh dear! Oh dear! I shall be late..."
```

The option :separator can be a regexp:

```ruby
"Oh dear! Oh dear! I shall be late!".truncate_words(4, separator: /\s/)
# => "Oh dear! Oh dear!..."
```

Defined in active_support/core_ext/string/filters.rb.


### 5.7. inquiry

The inquiry method converts a string into a StringInquirer object making equality checks prettier.

```ruby
"production".inquiry.production? # => true
"active".inquiry.inactive?       # => false
```

Defined in active_support/core_ext/string/inquiry.rb.


### 5.8. starts_with? and ends_with?

Active Support defines 3rd person aliases of String#start_with? and String#end_with?:

```ruby
"foo".starts_with?("f") # => true
"foo".ends_with?("o")   # => true
```

Defined in active_support/core_ext/string/starts_ends_with.rb.


### 5.9. strip_heredoc

The method strip_heredoc strips indentation in heredocs.

For example in

```ruby
if options[:usage]
  puts <<-USAGE.strip_heredoc
    This command does such and such.

    Supported options are:
      -h         This message
      ...
  USAGE
end
```

the user would see the usage message aligned against the left margin.

Technically, it looks for the least indented line in the whole string, and removes
that amount of leading whitespace.

Defined in active_support/core_ext/string/strip.rb.


### 5.10. indent

The indent method indents the lines in the receiver:

```ruby
<<EOS.indent(2)
def some_method
  some_code
end
EOS
# =>
  def some_method
    some_code
  end
```

The second argument, indent_string, specifies which indent string to use. The default is nil, which tells the method to make an educated guess peeking at the first indented line, and fallback to a space if there is none.

```ruby
"  foo".indent(2)        # => "    foo"
"foo\n\t\tbar".indent(2) # => "\t\tfoo\n\t\t\t\tbar"
"foo".indent(2, "\t")    # => "\t\tfoo"
```

While indent_string is typically one space or tab, it may be any string.

The third argument, indent_empty_lines, is a flag that says whether empty lines should be indented. Default is false.

```ruby
"foo\n\nbar".indent(2)            # => "  foo\n\n  bar"
"foo\n\nbar".indent(2, nil, true) # => "  foo\n  \n  bar"
```

The indent! method performs indentation in-place.

Defined in active_support/core_ext/string/indent.rb.


### 5.11. Access


#### 5.11.1. at(position)

The at method returns the character of the string at position position:

```ruby
"hello".at(0)  # => "h"
"hello".at(4)  # => "o"
"hello".at(-1) # => "o"
"hello".at(10) # => nil
```

Defined in active_support/core_ext/string/access.rb.


#### 5.11.2. from(position)

The from method returns the substring of the string starting at position position:

```ruby
"hello".from(0)  # => "hello"
"hello".from(2)  # => "llo"
"hello".from(-2) # => "lo"
"hello".from(10) # => nil
```

Defined in active_support/core_ext/string/access.rb.


#### 5.11.3. to(position)

The to method returns the substring of the string up to position position:

```ruby
"hello".to(0)  # => "h"
"hello".to(2)  # => "hel"
"hello".to(-2) # => "hell"
"hello".to(10) # => "hello"
```

Defined in active_support/core_ext/string/access.rb.


#### 5.11.4. first(limit = 1)

The first method returns a substring containing the first limit characters of the string.

The call str.first(n) is equivalent to str.to(n-1) if n > 0, and returns an empty string for n == 0.

Defined in active_support/core_ext/string/access.rb.


#### 5.11.5. last(limit = 1)

The last method returns a substring containing the last limit characters of the string.

The call str.last(n) is equivalent to str.from(-n) if n > 0, and returns an empty string for n == 0.

Defined in active_support/core_ext/string/access.rb.


### 5.12. Inflections


#### 5.12.1. pluralize

The method pluralize returns the plural of its receiver:

```ruby
"table".pluralize     # => "tables"
"ruby".pluralize      # => "rubies"
"equipment".pluralize # => "equipment"
```

As the previous example shows, Active Support knows some irregular plurals and uncountable nouns. Built-in rules can be extended in config/initializers/inflections.rb. This file is generated by default, by the rails new command and has instructions in comments.

pluralize can also take an optional count parameter. If count == 1 the singular form will be returned. For any other value of count the plural form will be returned:

```ruby
"dude".pluralize(0) # => "dudes"
"dude".pluralize(1) # => "dude"
"dude".pluralize(2) # => "dudes"
```

Active Record uses this method to compute the default table name that corresponds to a model:

```ruby
# active_record/model_schema.rb
def undecorated_table_name(model_name)
  table_name = model_name.to_s.demodulize.underscore
  pluralize_table_names ? table_name.pluralize : table_name
end
```

Defined in active_support/core_ext/string/inflections.rb.


#### 5.12.2. singularize

The singularize method is the inverse of pluralize:

```ruby
"tables".singularize    # => "table"
"rubies".singularize    # => "ruby"
"equipment".singularize # => "equipment"
```

Associations compute the name of the corresponding default associated class using this method:

```ruby
# active_record/reflection.rb
def derive_class_name
  class_name = name.to_s.camelize
  class_name = class_name.singularize if collection?
  class_name
end
```

Defined in active_support/core_ext/string/inflections.rb.


#### 5.12.3. camelize

The method camelize returns its receiver in camel case:

```ruby
"product".camelize    # => "Product"
"admin_user".camelize # => "AdminUser"
```

As a rule of thumb you can think of this method as the one that transforms paths into Ruby class or module names, where slashes separate namespaces:

```ruby
"backoffice/session".camelize # => "Backoffice::Session"
```

For example, Action Pack uses this method to load the class that provides a certain session store:

```ruby
# action_controller/metal/session_management.rb
def session_store=(store)
  @@session_store = store.is_a?(Symbol) ?
    ActionDispatch::Session.const_get(store.to_s.camelize) :
    store
end
```

camelize accepts an optional argument, it can be :upper (default), or :lower. With the latter the first letter becomes lowercase:

```ruby
"visual_effect".camelize(:lower) # => "visualEffect"
```

That may be handy to compute method names in a language that follows that convention, for example JavaScript.

As a rule of thumb you can think of camelize as the inverse of underscore, though there are cases where that does not hold: "SSLError".underscore.camelize gives back "SslError". To support cases such as this, Active Support allows you to specify acronyms in config/initializers/inflections.rb:

```ruby
ActiveSupport::Inflector.inflections do |inflect|
  inflect.acronym "SSL"
end

"SSLError".underscore.camelize # => "SSLError"
```

camelize is aliased to camelcase.

Defined in active_support/core_ext/string/inflections.rb.


#### 5.12.4. underscore

The method underscore goes the other way around, from camel case to paths:

```ruby
"Product".underscore   # => "product"
"AdminUser".underscore # => "admin_user"
```

Also converts "::" back to "/":

```ruby
"Backoffice::Session".underscore # => "backoffice/session"
```

and understands strings that start with lowercase:

```ruby
"visualEffect".underscore # => "visual_effect"
```

underscore accepts no argument though.

Rails uses underscore to get a lowercased name for controller classes:

```ruby
# actionpack/lib/abstract_controller/base.rb
def controller_path
  @controller_path ||= name.delete_suffix("Controller").underscore
end
```

For example, that value is the one you get in params[:controller].

As a rule of thumb you can think of underscore as the inverse of camelize, though there are cases where that does not hold. For example, "SSLError".underscore.camelize gives back "SslError".

Defined in active_support/core_ext/string/inflections.rb.


#### 5.12.5. titleize

The method titleize capitalizes the words in the receiver:

```ruby
"alice in wonderland".titleize # => "Alice In Wonderland"
"fermat's enigma".titleize     # => "Fermat's Enigma"
```

titleize is aliased to titlecase.

Defined in active_support/core_ext/string/inflections.rb.


#### 5.12.6. dasherize

The method dasherize replaces the underscores in the receiver with dashes:

```ruby
"name".dasherize         # => "name"
"contact_data".dasherize # => "contact-data"
```

The XML serializer of models uses this method to dasherize node names:

```ruby
# active_model/serializers/xml.rb
def reformat_name(name)
  name = name.camelize if camelize?
  dasherize? ? name.dasherize : name
end
```

Defined in active_support/core_ext/string/inflections.rb.


#### 5.12.7. demodulize

Given a string with a qualified constant name, demodulize returns the very constant name, that is, the rightmost part of it:

```ruby
"Product".demodulize                        # => "Product"
"Backoffice::UsersController".demodulize    # => "UsersController"
"Admin::Hotel::ReservationUtils".demodulize # => "ReservationUtils"
"::Inflections".demodulize                  # => "Inflections"
"".demodulize                               # => ""
```

Active Record for example uses this method to compute the name of a counter cache column:

```ruby
# active_record/reflection.rb
def counter_cache_column
  if options[:counter_cache] == true
    "#{active_record.name.demodulize.underscore.pluralize}_count"
  elsif options[:counter_cache]
    options[:counter_cache]
  end
end
```

Defined in active_support/core_ext/string/inflections.rb.


#### 5.12.8. deconstantize

Given a string with a qualified constant reference expression, deconstantize removes the rightmost segment, generally leaving the name of the constant's container:

```ruby
"Product".deconstantize                        # => ""
"Backoffice::UsersController".deconstantize    # => "Backoffice"
"Admin::Hotel::ReservationUtils".deconstantize # => "Admin::Hotel"
```

Defined in active_support/core_ext/string/inflections.rb.


#### 5.12.9. parameterize

The method parameterize normalizes its receiver in a way that can be used in pretty URLs.

```ruby
"John Smith".parameterize # => "john-smith"
"Kurt Gödel".parameterize # => "kurt-godel"
```

To preserve the case of the string, set the preserve_case argument to true. By default, preserve_case is set to false.

```ruby
"John Smith".parameterize(preserve_case: true) # => "John-Smith"
"Kurt Gödel".parameterize(preserve_case: true) # => "Kurt-Godel"
```

To use a custom separator, override the separator argument.

```ruby
"John Smith".parameterize(separator: "_") # => "john_smith"
"Kurt Gödel".parameterize(separator: "_") # => "kurt_godel"
```

Defined in active_support/core_ext/string/inflections.rb.


#### 5.12.10. tableize

The method tableize is underscore followed by pluralize.

```ruby
"Person".tableize      # => "people"
"Invoice".tableize     # => "invoices"
"InvoiceLine".tableize # => "invoice_lines"
```

As a rule of thumb, tableize returns the table name that corresponds to a given model for simple cases. The actual implementation in Active Record is not straight tableize indeed, because it also demodulizes the class name and checks a few options that may affect the returned string.

Defined in active_support/core_ext/string/inflections.rb.


#### 5.12.11. classify

The method classify is the inverse of tableize. It gives you the class name corresponding to a table name:

```ruby
"people".classify        # => "Person"
"invoices".classify      # => "Invoice"
"invoice_lines".classify # => "InvoiceLine"
```

The method understands qualified table names:

```ruby
"highrise_production.companies".classify # => "Company"
```

Note that classify returns a class name as a string. You can get the actual class object by invoking constantize on it, explained next.

Defined in active_support/core_ext/string/inflections.rb.


#### 5.12.12. constantize

The method constantize resolves the constant reference expression in its receiver:

```ruby
"Integer".constantize # => Integer

module M
  X = 1
end
"M::X".constantize # => 1
```

If the string evaluates to no known constant, or its content is not even a valid constant name, constantize raises NameError.

Constant name resolution by constantize starts always at the top-level Object even if there is no leading "::".

```ruby
X = :in_Object
module M
  X = :in_M

  X                 # => :in_M
  "::X".constantize # => :in_Object
  "X".constantize   # => :in_Object (!)
end
```

So, it is in general not equivalent to what Ruby would do in the same spot, had a real constant be evaluated.

Mailer test cases obtain the mailer being tested from the name of the test class using constantize:

```ruby
# action_mailer/test_case.rb
def determine_default_mailer(name)
  name.delete_suffix("Test").constantize
rescue NameError => e
  raise NonInferrableMailerError.new(name)
end
```

Defined in active_support/core_ext/string/inflections.rb.


#### 5.12.13. humanize

The method humanize tweaks an attribute name for display to end users.

Specifically, it performs these transformations:

- Applies human inflection rules to the argument.

- Deletes leading underscores, if any.

- Removes a "_id" suffix if present.

- Replaces underscores with spaces, if any.

- Downcases all words except acronyms.

- Capitalizes the first word.

The capitalization of the first word can be turned off by setting the
:capitalize option to false (default is true).

```ruby
"name".humanize                         # => "Name"
"author_id".humanize                    # => "Author"
"author_id".humanize(capitalize: false) # => "author"
"comments_count".humanize               # => "Comments count"
"_id".humanize                          # => "Id"
```

If "SSL" was defined to be an acronym:

```ruby
"ssl_error".humanize # => "SSL error"
```

The helper method full_messages uses humanize as a fallback to include
attribute names:

```ruby
def full_messages
  map { |attribute, message| full_message(attribute, message) }
end

def full_message
  # ...
  attr_name = attribute.to_s.tr(".", "_").humanize
  attr_name = @base.class.human_attribute_name(attribute, default: attr_name)
  # ...
end
```

Defined in active_support/core_ext/string/inflections.rb.


#### 5.12.14. foreign_key

The method foreign_key gives a foreign key column name from a class name. To do so it demodulizes, underscores, and adds "_id":

```ruby
"User".foreign_key           # => "user_id"
"InvoiceLine".foreign_key    # => "invoice_line_id"
"Admin::Session".foreign_key # => "session_id"
```

Pass a false argument if you do not want the underscore in "_id":

```ruby
"User".foreign_key(false) # => "userid"
```

Associations use this method to infer foreign keys, for example has_one and has_many do this:

```ruby
# active_record/associations.rb
foreign_key = options[:foreign_key] || reflection.active_record.name.foreign_key
```

Defined in active_support/core_ext/string/inflections.rb.


#### 5.12.15. upcase_first

The method upcase_first capitalizes the first letter of the receiver:

```ruby
"employee salary".upcase_first # => "Employee salary"
"".upcase_first                # => ""
```

Defined in active_support/core_ext/string/inflections.rb.


#### 5.12.16. downcase_first

The method downcase_first converts the first letter of the receiver to lowercase:

```ruby
"If I had read Alice in Wonderland".downcase_first # => "if I had read Alice in Wonderland"
"".downcase_first                                  # => ""
```

Defined in active_support/core_ext/string/inflections.rb.


### 5.13. Conversions


#### 5.13.1. to_date, to_time, to_datetime

The methods to_date, to_time, and to_datetime are basically convenience wrappers around Date._parse:

```ruby
"2010-07-27".to_date              # => Tue, 27 Jul 2010
"2010-07-27 23:37:00".to_time     # => 2010-07-27 23:37:00 +0200
"2010-07-27 23:37:00".to_datetime # => Tue, 27 Jul 2010 23:37:00 +0000
```

to_time receives an optional argument :utc or :local, to indicate which time zone you want the time in:

```ruby
"2010-07-27 23:42:00".to_time(:utc)   # => 2010-07-27 23:42:00 UTC
"2010-07-27 23:42:00".to_time(:local) # => 2010-07-27 23:42:00 +0200
```

Default is :local.

Please refer to the documentation of Date._parse for further details.

The three of them return nil for blank receivers.

Defined in active_support/core_ext/string/conversions.rb.


## 6. Extensions to Symbol


### 6.1. starts_with? and ends_with?

Active Support defines 3rd person aliases of Symbol#start_with? and Symbol#end_with?:

```ruby
:foo.starts_with?("f") # => true
:foo.ends_with?("o")   # => true
```

Defined in active_support/core_ext/symbol/starts_ends_with.rb.


## 7. Extensions to Numeric


### 7.1. Bytes

All numbers respond to these methods:

- bytes

- kilobytes

- megabytes

- gigabytes

- terabytes

- petabytes

- exabytes

- zettabytes

They return the corresponding amount of bytes, using a conversion factor of 1024:

```ruby
2.kilobytes   # => 2048
3.megabytes   # => 3145728
3.5.gigabytes # => 3758096384.0
-4.exabytes   # => -4611686018427387904
```

Singular forms are aliased so you are able to say:

```ruby
1.megabyte # => 1048576
```

Defined in active_support/core_ext/numeric/bytes.rb.


### 7.2. Time

The following methods:

- seconds

- minutes

- hours

- days

- weeks

- fortnights

enable time declarations and calculations, like 45.minutes + 2.hours + 4.weeks. Their return values can also be added to or subtracted from Time objects.

These methods can be combined with from_now, ago, etc, for precise date calculations. For example:

```ruby
# equivalent to Time.current.advance(days: 1)
1.day.from_now

# equivalent to Time.current.advance(weeks: 2)
2.weeks.from_now

# equivalent to Time.current.advance(days: 4, weeks: 5)
(4.days + 5.weeks).from_now
```

For other durations please refer to the time extensions to Integer.

Defined in active_support/core_ext/numeric/time.rb.


### 7.3. Formatting

Enables the formatting of numbers in a variety of ways.

Produce a string representation of a number as a telephone number:

```ruby
5551234.to_fs(:phone)
# => 555-1234
1235551234.to_fs(:phone)
# => 123-555-1234
1235551234.to_fs(:phone, area_code: true)
# => (123) 555-1234
1235551234.to_fs(:phone, delimiter: " ")
# => 123 555 1234
1235551234.to_fs(:phone, area_code: true, extension: 555)
# => (123) 555-1234 x 555
1235551234.to_fs(:phone, country_code: 1)
# => +1-123-555-1234
```

Produce a string representation of a number as currency:

```ruby
1234567890.50.to_fs(:currency)                 # => $1,234,567,890.50
1234567890.506.to_fs(:currency)                # => $1,234,567,890.51
1234567890.506.to_fs(:currency, precision: 3)  # => $1,234,567,890.506
```

Produce a string representation of a number as a percentage:

```ruby
100.to_fs(:percentage)
# => 100.000%
100.to_fs(:percentage, precision: 0)
# => 100%
1000.to_fs(:percentage, delimiter: ".", separator: ",")
# => 1.000,000%
302.24398923423.to_fs(:percentage, precision: 5)
# => 302.24399%
```

Produce a string representation of a number in delimited form:

```ruby
12345678.to_fs(:delimited)                     # => 12,345,678
12345678.05.to_fs(:delimited)                  # => 12,345,678.05
12345678.to_fs(:delimited, delimiter: ".")     # => 12.345.678
12345678.to_fs(:delimited, delimiter: ",")     # => 12,345,678
12345678.05.to_fs(:delimited, separator: " ")  # => 12,345,678 05
```

Produce a string representation of a number rounded to a precision:

```ruby
111.2345.to_fs(:rounded)                     # => 111.235
111.2345.to_fs(:rounded, precision: 2)       # => 111.23
13.to_fs(:rounded, precision: 5)             # => 13.00000
389.32314.to_fs(:rounded, precision: 0)      # => 389
111.2345.to_fs(:rounded, significant: true)  # => 111
```

Produce a string representation of a number as a human-readable number of bytes:

```ruby
123.to_fs(:human_size)                  # => 123 Bytes
1234.to_fs(:human_size)                 # => 1.21 KB
12345.to_fs(:human_size)                # => 12.1 KB
1234567.to_fs(:human_size)              # => 1.18 MB
1234567890.to_fs(:human_size)           # => 1.15 GB
1234567890123.to_fs(:human_size)        # => 1.12 TB
1234567890123456.to_fs(:human_size)     # => 1.1 PB
1234567890123456789.to_fs(:human_size)  # => 1.07 EB
```

Produce a string representation of a number in human-readable words:

```ruby
123.to_fs(:human)               # => "123"
1234.to_fs(:human)              # => "1.23 Thousand"
12345.to_fs(:human)             # => "12.3 Thousand"
1234567.to_fs(:human)           # => "1.23 Million"
1234567890.to_fs(:human)        # => "1.23 Billion"
1234567890123.to_fs(:human)     # => "1.23 Trillion"
1234567890123456.to_fs(:human)  # => "1.23 Quadrillion"
```

Defined in active_support/core_ext/numeric/conversions.rb.


## 8. Extensions to Integer


### 8.1. multiple_of?

The method multiple_of? tests whether an integer is multiple of the argument:

```ruby
2.multiple_of?(1) # => true
1.multiple_of?(2) # => false
```

Defined in active_support/core_ext/integer/multiple.rb.


### 8.2. ordinal

The method ordinal returns the ordinal suffix string corresponding to the receiver integer:

```ruby
1.ordinal    # => "st"
2.ordinal    # => "nd"
53.ordinal   # => "rd"
2009.ordinal # => "th"
-21.ordinal  # => "st"
-134.ordinal # => "th"
```

Defined in active_support/core_ext/integer/inflections.rb.


### 8.3. ordinalize

The method ordinalize returns the ordinal string corresponding to the receiver integer. In comparison, note that the ordinal method returns only the suffix string.

```ruby
1.ordinalize    # => "1st"
2.ordinalize    # => "2nd"
53.ordinalize   # => "53rd"
2009.ordinalize # => "2009th"
-21.ordinalize  # => "-21st"
-134.ordinalize # => "-134th"
```

Defined in active_support/core_ext/integer/inflections.rb.


### 8.4. Time

The following methods:

- months

- years

enable time declarations and calculations, like 4.months + 5.years. Their return values can also be added to or subtracted from Time objects.

These methods can be combined with from_now, ago, etc, for precise date calculations. For example:

```ruby
# equivalent to Time.current.advance(months: 1)
1.month.from_now

# equivalent to Time.current.advance(years: 2)
2.years.from_now

# equivalent to Time.current.advance(months: 4, years: 5)
(4.months + 5.years).from_now
```

For other durations please refer to the time extensions to Numeric.

Defined in active_support/core_ext/integer/time.rb.


## 9. Extensions to BigDecimal


### 9.1. to_s

The method to_s provides a default specifier of "F". This means that a simple call to to_s will result in floating-point representation instead of scientific notation:

```ruby
BigDecimal(5.00, 6).to_s       # => "5.0"
```

Scientific notation is still supported:

```ruby
BigDecimal(5.00, 6).to_s("e")  # => "0.5E1"
```


## 10. Extensions to Enumerable


### 10.1. index_by

The method index_by generates a hash with the elements of an enumerable indexed by some key.

It iterates through the collection and passes each element to a block. The element will be keyed by the value returned by the block:

```ruby
invoices.index_by(&:number)
# => {"2009-032" => <Invoice ...>, "2009-008" => <Invoice ...>, ...}
```

Keys should normally be unique. If the block returns the same value for different elements no collection is built for that key. The last item will win.

Defined in active_support/core_ext/enumerable.rb.


### 10.2. index_with

The method index_with generates a hash with the elements of an enumerable as keys. The value
is either a passed default or returned in a block.

```ruby
post = Post.new(title: "hey there", body: "what's up?")

%i( title body ).index_with { |attr_name| post.public_send(attr_name) }
# => { title: "hey there", body: "what's up?" }

WEEKDAYS.index_with(Interval.all_day)
# => { monday: [ 0, 1440 ], … }
```

Defined in active_support/core_ext/enumerable.rb.


### 10.3. many?

The method many? is shorthand for collection.size > 1:

```ruby
<% if pages.many? %>
  <%= pagination_links %>
<% end %>
```

If an optional block is given, many? only takes into account those elements that return true:

```ruby
@see_more = videos.many? { |video| video.category == params[:category] }
```

Defined in active_support/core_ext/enumerable.rb.


### 10.4. exclude?

The predicate exclude? tests whether a given object does not belong to the collection. It is the negation of the built-in include?:

```ruby
to_visit << node if visited.exclude?(node)
```

Defined in active_support/core_ext/enumerable.rb.


### 10.5. including

The method including returns a new enumerable that includes the passed elements:

```ruby
[ 1, 2, 3 ].including(4, 5)                    # => [ 1, 2, 3, 4, 5 ]
["David", "Rafael"].including %w[ Aaron Todd ] # => ["David", "Rafael", "Aaron", "Todd"]
```

Defined in active_support/core_ext/enumerable.rb.


### 10.6. excluding

The method excluding returns a copy of an enumerable with the specified elements
removed:

```ruby
["David", "Rafael", "Aaron", "Todd"].excluding("Aaron", "Todd") # => ["David", "Rafael"]
```

excluding is aliased to without.

Defined in active_support/core_ext/enumerable.rb.


### 10.7. pluck

The method pluck extracts the given key from each element:

```ruby
[{ name: "David" }, { name: "Rafael" }, { name: "Aaron" }].pluck(:name) # => ["David", "Rafael", "Aaron"]
[{ id: 1, name: "David" }, { id: 2, name: "Rafael" }].pluck(:id, :name) # => [[1, "David"], [2, "Rafael"]]
```

Defined in active_support/core_ext/enumerable.rb.


### 10.8. pick

The method pick extracts the given key from the first element:

```ruby
[{ name: "David" }, { name: "Rafael" }, { name: "Aaron" }].pick(:name) # => "David"
[{ id: 1, name: "David" }, { id: 2, name: "Rafael" }].pick(:id, :name) # => [1, "David"]
```

Defined in active_support/core_ext/enumerable.rb.


## 11. Extensions to Array


### 11.1. Accessing

Active Support augments the API of arrays to ease certain ways of accessing them. For example, to returns the subarray of elements up to the one at the passed index:

```ruby
%w(a b c d).to(2) # => ["a", "b", "c"]
[].to(7)          # => []
```

Similarly, from returns the tail from the element at the passed index to the end. If the index is greater than the length of the array, it returns an empty array.

```ruby
%w(a b c d).from(2)  # => ["c", "d"]
%w(a b c d).from(10) # => []
[].from(0)           # => []
```

The method including returns a new array that includes the passed elements:

```ruby
[ 1, 2, 3 ].including(4, 5)          # => [ 1, 2, 3, 4, 5 ]
[ [ 0, 1 ] ].including([ [ 1, 0 ] ]) # => [ [ 0, 1 ], [ 1, 0 ] ]
```

The method excluding returns a copy of the Array excluding the specified elements.
This is an optimization of Enumerable#excluding that uses Array#-
instead of Array#reject for performance reasons.

```ruby
["David", "Rafael", "Aaron", "Todd"].excluding("Aaron", "Todd") # => ["David", "Rafael"]
[ [ 0, 1 ], [ 1, 0 ] ].excluding([ [ 1, 0 ] ])                  # => [ [ 0, 1 ] ]
```

The methods second, third, fourth, and fifth return the corresponding element, as do second_to_last and third_to_last (first and last are built-in). Thanks to social wisdom and positive constructiveness all around, forty_two is also available.

```ruby
%w(a b c d).third # => "c"
%w(a b c d).fifth # => nil
```

Defined in active_support/core_ext/array/access.rb.


### 11.2. Extracting

The method extract! removes and returns the elements for which the block returns a true value.
If no block is given, an Enumerator is returned instead.

```ruby
numbers = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]
odd_numbers = numbers.extract! { |number| number.odd? } # => [1, 3, 5, 7, 9]
numbers # => [0, 2, 4, 6, 8]
```

Defined in active_support/core_ext/array/extract.rb.


### 11.3. Options Extraction

When the last argument in a method call is a hash, except perhaps for a &block argument, Ruby allows you to omit the brackets:

```ruby
User.exists?(email: params[:email])
```

That syntactic sugar is used a lot in Rails to avoid positional arguments where there would be too many, offering instead interfaces that emulate named parameters. In particular it is very idiomatic to use a trailing hash for options.

If a method expects a variable number of arguments and uses * in its declaration, however, such an options hash ends up being an item of the array of arguments, where it loses its role.

In those cases, you may give an options hash a distinguished treatment with extract_options!. This method checks the type of the last item of an array. If it is a hash it pops it and returns it, otherwise it returns an empty hash.

Let's see for example the definition of the caches_action controller macro:

```ruby
def caches_action(*actions)
  return unless cache_configured?
  options = actions.extract_options!
  # ...
end
```

This method receives an arbitrary number of action names, and an optional hash of options as last argument. With the call to extract_options! you obtain the options hash and remove it from actions in a simple and explicit way.

Defined in active_support/core_ext/array/extract_options.rb.


### 11.4. Conversions


#### 11.4.1. to_sentence

The method to_sentence turns an array into a string containing a sentence that enumerates its items:

```ruby
%w().to_sentence                # => ""
%w(Earth).to_sentence           # => "Earth"
%w(Earth Wind).to_sentence      # => "Earth and Wind"
%w(Earth Wind Fire).to_sentence # => "Earth, Wind, and Fire"
```

This method accepts three options:

- :two_words_connector: What is used for arrays of length 2. Default is " and ".

- :words_connector: What is used to join the elements of arrays with 3 or more elements, except for the last two. Default is ", ".

- :last_word_connector: What is used to join the last items of an array with 3 or more elements. Default is ", and ".

The defaults for these options can be localized, their keys are:

Defined in active_support/core_ext/array/conversions.rb.


#### 11.4.2. to_fs

The method to_fs acts like to_s by default.

If the array contains items that respond to id, however, the symbol
:db may be passed as argument. That's typically used with
collections of Active Record objects. Returned strings are:

```ruby
[].to_fs(:db)            # => "null"
[user].to_fs(:db)        # => "8456"
invoice.lines.to_fs(:db) # => "23,567,556,12"
```

Integers in the example above are supposed to come from the respective calls to id.

Defined in active_support/core_ext/array/conversions.rb.


#### 11.4.3. to_xml

The method to_xml returns a string containing an XML representation of its receiver:

```ruby
Contributor.limit(2).order(:rank).to_xml
# =>
# <?xml version="1.0" encoding="UTF-8"?>
# <contributors type="array">
#   <contributor>
#     <id type="integer">4356</id>
#     <name>Jeremy Kemper</name>
#     <rank type="integer">1</rank>
#     <url-id>jeremy-kemper</url-id>
#   </contributor>
#   <contributor>
#     <id type="integer">4404</id>
#     <name>David Heinemeier Hansson</name>
#     <rank type="integer">2</rank>
#     <url-id>david-heinemeier-hansson</url-id>
#   </contributor>
# </contributors>
```

To do so it sends to_xml to every item in turn, and collects the results under a root node. All items must respond to to_xml, an exception is raised otherwise.

By default, the name of the root element is the underscored and dasherized plural of the name of the class of the first item, provided the rest of elements belong to that type (checked with is_a?) and they are not hashes. In the example above that's "contributors".

If there's any element that does not belong to the type of the first one the root node becomes "objects":

```ruby
[Contributor.first, Commit.first].to_xml
# =>
# <?xml version="1.0" encoding="UTF-8"?>
# <objects type="array">
#   <object>
#     <id type="integer">4583</id>
#     <name>Aaron Batalion</name>
#     <rank type="integer">53</rank>
#     <url-id>aaron-batalion</url-id>
#   </object>
#   <object>
#     <author>Joshua Peek</author>
#     <authored-timestamp type="datetime">2009-09-02T16:44:36Z</authored-timestamp>
#     <branch>origin/master</branch>
#     <committed-timestamp type="datetime">2009-09-02T16:44:36Z</committed-timestamp>
#     <committer>Joshua Peek</committer>
#     <git-show nil="true"></git-show>
#     <id type="integer">190316</id>
#     <imported-from-svn type="boolean">false</imported-from-svn>
#     <message>Kill AMo observing wrap_with_notifications since ARes was only using it</message>
#     <sha1>723a47bfb3708f968821bc969a9a3fc873a3ed58</sha1>
#   </object>
# </objects>
```

If the receiver is an array of hashes the root element is by default also "objects":

```ruby
[{ a: 1, b: 2 }, { c: 3 }].to_xml
# =>
# <?xml version="1.0" encoding="UTF-8"?>
# <objects type="array">
#   <object>
#     <b type="integer">2</b>
#     <a type="integer">1</a>
#   </object>
#   <object>
#     <c type="integer">3</c>
#   </object>
# </objects>
```

If the collection is empty the root element is by default "nil-classes". That's a gotcha, for example the root element of the list of contributors above would not be "contributors" if the collection was empty, but "nil-classes". You may use the :root option to ensure a consistent root element.

The name of children nodes is by default the name of the root node singularized. In the examples above we've seen "contributor" and "object". The option :children allows you to set these node names.

The default XML builder is a fresh instance of Builder::XmlMarkup. You can configure your own builder via the :builder option. The method also accepts options like :dasherize and friends, they are forwarded to the builder:

```ruby
Contributor.limit(2).order(:rank).to_xml(skip_types: true)
# =>
# <?xml version="1.0" encoding="UTF-8"?>
# <contributors>
#   <contributor>
#     <id>4356</id>
#     <name>Jeremy Kemper</name>
#     <rank>1</rank>
#     <url-id>jeremy-kemper</url-id>
#   </contributor>
#   <contributor>
#     <id>4404</id>
#     <name>David Heinemeier Hansson</name>
#     <rank>2</rank>
#     <url-id>david-heinemeier-hansson</url-id>
#   </contributor>
# </contributors>
```

Defined in active_support/core_ext/array/conversions.rb.


### 11.5. Wrapping

The method Array.wrap wraps its argument in an array unless it is already an array (or array-like).

Specifically:

- If the argument is nil an empty array is returned.

- Otherwise, if the argument responds to to_ary it is invoked, and if the value of to_ary is not nil, it is returned.

- Otherwise, an array with the argument as its single element is returned.

```ruby
Array.wrap(nil)       # => []
Array.wrap([1, 2, 3]) # => [1, 2, 3]
Array.wrap(0)         # => [0]
```

This method is similar in purpose to Kernel#Array, but there are some differences:

- If the argument responds to to_ary the method is invoked. Kernel#Array moves on to try to_a if the returned value is nil, but Array.wrap returns an array with the argument as its single element right away.

- If the returned value from to_ary is neither nil nor an Array object, Kernel#Array raises an exception, while Array.wrap does not, it just returns the value.

- It does not call to_a on the argument, if the argument does not respond to to_ary it returns an array with the argument as its single element.

The last point is particularly worth comparing for some enumerables:

```ruby
Array.wrap(foo: :bar) # => [{:foo=>:bar}]
Array(foo: :bar)      # => [[:foo, :bar]]
```

There's also a related idiom that uses the splat operator:

```ruby
[*object]
```

Defined in active_support/core_ext/array/wrap.rb.


### 11.6. Duplicating

The method Array#deep_dup duplicates itself and all objects inside
recursively with the Active Support method Object#deep_dup. It works like Array#map, sending deep_dup method to each object inside.

```ruby
array = [1, [2, 3]]
dup = array.deep_dup
dup[1][2] = 4
array[1][2] == nil   # => true
```

Defined in active_support/core_ext/object/deep_dup.rb.


### 11.7. Grouping


#### 11.7.1. in_groups_of(number, fill_with = nil)

The method in_groups_of splits an array into consecutive groups of a certain size. It returns an array with the groups:

```ruby
[1, 2, 3].in_groups_of(2) # => [[1, 2], [3, nil]]
```

or yields them in turn if a block is passed:

```ruby
<% sample.in_groups_of(3) do |a, b, c| %>
  <tr>
    <td><%= a %></td>
    <td><%= b %></td>
    <td><%= c %></td>
  </tr>
<% end %>
```

The first example shows how in_groups_of fills the last group with as many nil elements as needed to have the requested size. You can change this padding value using the second optional argument:

```ruby
[1, 2, 3].in_groups_of(2, 0) # => [[1, 2], [3, 0]]
```

And you can tell the method not to fill the last group by passing false:

```ruby
[1, 2, 3].in_groups_of(2, false) # => [[1, 2], [3]]
```

As a consequence false can't be used as a padding value.

Defined in active_support/core_ext/array/grouping.rb.


#### 11.7.2. in_groups(number, fill_with = nil)

The method in_groups splits an array into a certain number of groups. The method returns an array with the groups:

```ruby
%w(1 2 3 4 5 6 7).in_groups(3)
# => [["1", "2", "3"], ["4", "5", nil], ["6", "7", nil]]
```

or yields them in turn if a block is passed:

```ruby
%w(1 2 3 4 5 6 7).in_groups(3) { |group| p group }
["1", "2", "3"]
["4", "5", nil]
["6", "7", nil]
```

The examples above show that in_groups fills some groups with a trailing nil element as needed. A group can get at most one of these extra elements, the rightmost one if any. And the groups that have them are always the last ones.

You can change this padding value using the second optional argument:

```ruby
%w(1 2 3 4 5 6 7).in_groups(3, "0")
# => [["1", "2", "3"], ["4", "5", "0"], ["6", "7", "0"]]
```

And you can tell the method not to fill the smaller groups by passing false:

```ruby
%w(1 2 3 4 5 6 7).in_groups(3, false)
# => [["1", "2", "3"], ["4", "5"], ["6", "7"]]
```

As a consequence false can't be used as a padding value.

Defined in active_support/core_ext/array/grouping.rb.


#### 11.7.3. split(value = nil)

The method split divides an array by a separator and returns the resulting chunks.

If a block is passed the separators are those elements of the array for which the block returns true:

```ruby
(-5..5).to_a.split { |i| i.multiple_of?(4) }
# => [[-5], [-3, -2, -1], [1, 2, 3], [5]]
```

Otherwise, the value received as argument, which defaults to nil, is the separator:

```ruby
[0, 1, -5, 1, 1, "foo", "bar"].split(1)
# => [[0], [-5], [], ["foo", "bar"]]
```

Observe in the previous example that consecutive separators result in empty arrays.

Defined in active_support/core_ext/array/grouping.rb.


## 12. Extensions to Hash


### 12.1. Conversions


#### 12.1.1. to_xml

The method to_xml returns a string containing an XML representation of its receiver:

```ruby
{ foo: 1, bar: 2 }.to_xml
# =>
# <?xml version="1.0" encoding="UTF-8"?>
# <hash>
#   <foo type="integer">1</foo>
#   <bar type="integer">2</bar>
# </hash>
```

To do so, the method loops over the pairs and builds nodes that depend on the values. Given a pair key, value:

- If value is a hash there's a recursive call with key as :root.

- If value is an array there's a recursive call with key as :root, and key singularized as :children.

- If value is a callable object it must expect one or two arguments. Depending on the arity, the callable is invoked with the options hash as first argument with key as :root, and key singularized as second argument. Its return value becomes a new node.

- If value responds to to_xml the method is invoked with key as :root.

- Otherwise, a node with key as tag is created with a string representation of value as text node. If value is nil an attribute "nil" set to "true" is added. Unless the option :skip_types exists and is true, an attribute "type" is added as well according to the following mapping:

If value is a hash there's a recursive call with key as :root.

If value is an array there's a recursive call with key as :root, and key singularized as :children.

If value is a callable object it must expect one or two arguments. Depending on the arity, the callable is invoked with the options hash as first argument with key as :root, and key singularized as second argument. Its return value becomes a new node.

If value responds to to_xml the method is invoked with key as :root.

Otherwise, a node with key as tag is created with a string representation of value as text node. If value is nil an attribute "nil" set to "true" is added. Unless the option :skip_types exists and is true, an attribute "type" is added as well according to the following mapping:

```ruby
XML_TYPE_NAMES = {
  "Symbol"     => "symbol",
  "Integer"    => "integer",
  "BigDecimal" => "decimal",
  "Float"      => "float",
  "TrueClass"  => "boolean",
  "FalseClass" => "boolean",
  "Date"       => "date",
  "DateTime"   => "datetime",
  "Time"       => "datetime"
}
```

By default the root node is "hash", but that's configurable via the :root option.

The default XML builder is a fresh instance of Builder::XmlMarkup. You can configure your own builder with the :builder option. The method also accepts options like :dasherize and friends, they are forwarded to the builder.

Defined in active_support/core_ext/hash/conversions.rb.


### 12.2. Merging

Ruby has a built-in method Hash#merge that merges two hashes:

```ruby
{ a: 1, b: 1 }.merge(a: 0, c: 2)
# => {:a=>0, :b=>1, :c=>2}
```

Active Support defines a few more ways of merging hashes that may be convenient.


#### 12.2.1. reverse_merge and reverse_merge!

In case of collision the key in the hash of the argument wins in merge. You can support option hashes with default values in a compact way with this idiom:

```ruby
options = { length: 30, omission: "..." }.merge(options)
```

Active Support defines reverse_merge in case you prefer this alternative notation:

```ruby
options = options.reverse_merge(length: 30, omission: "...")
```

And a bang version reverse_merge! that performs the merge in place:

```ruby
options.reverse_merge!(length: 30, omission: "...")
```

Take into account that reverse_merge! may change the hash in the caller, which may or may not be a good idea.

Defined in active_support/core_ext/hash/reverse_merge.rb.


#### 12.2.2. reverse_update

The method reverse_update is an alias for reverse_merge!, explained above.

Note that reverse_update has no bang.

Defined in active_support/core_ext/hash/reverse_merge.rb.


#### 12.2.3. deep_merge and deep_merge!

As you can see in the previous example if a key is found in both hashes the value in the one in the argument wins.

Active Support defines Hash#deep_merge. In a deep merge, if a key is found in both hashes and their values are hashes in turn, then their merge becomes the value in the resulting hash:

```ruby
{ a: { b: 1 } }.deep_merge(a: { c: 2 })
# => {:a=>{:b=>1, :c=>2}}
```

The method deep_merge! performs a deep merge in place.

Defined in active_support/core_ext/hash/deep_merge.rb.


### 12.3. Deep Duplicating

The method Hash#deep_dup duplicates itself and all keys and values
inside recursively with Active Support method Object#deep_dup. It works like Enumerator#each_with_object with sending deep_dup method to each pair inside.

```ruby
hash = { a: 1, b: { c: 2, d: [3, 4] } }

dup = hash.deep_dup
dup[:b][:e] = 5
dup[:b][:d] << 5

hash[:b][:e] == nil      # => true
hash[:b][:d] == [3, 4]   # => true
```

Defined in active_support/core_ext/object/deep_dup.rb.


### 12.4. Working with Keys


#### 12.4.1. except!

The method except! is identical to the built-in except method but removes keys in place, returning self.

```ruby
{ a: 1, b: 2 }.except!(:a) # => {:b=>2}
{ a: 1, b: 2 }.except!(:c) # => {:a=>1, :b=>2}
```

If the receiver responds to convert_key, the method is called on each of the arguments. This allows except! (and except) to play nice with hashes with indifferent access for instance:

```ruby
{ a: 1 }.with_indifferent_access.except!(:a)  # => {}
{ a: 1 }.with_indifferent_access.except!("a") # => {}
```

Defined in active_support/core_ext/hash/except.rb.


#### 12.4.2. stringify_keys and stringify_keys!

The method stringify_keys returns a hash that has a stringified version of the keys in the receiver. It does so by sending to_s to them:

```ruby
{ nil => nil, 1 => 1, a: :a }.stringify_keys
# => {"" => nil, "1" => 1, "a" => :a}
```

In case of key collision, the value will be the one most recently inserted into the hash:

```ruby
{ "a" => 1, a: 2 }.stringify_keys
# The result will be
# => {"a"=>2}
```

This method may be useful for example to easily accept both symbols and strings as options. For instance ActionView::Helpers::FormHelper defines:

```ruby
def to_checkbox_tag(options = {}, checked_value = "1", unchecked_value = "0")
  options = options.stringify_keys
  options["type"] = "checkbox"
  # ...
end
```

The second line can safely access the "type" key, and let the user to pass either :type or "type".

There's also the bang variant stringify_keys! that stringifies keys in place.

Besides that, one can use deep_stringify_keys and deep_stringify_keys! to stringify all the keys in the given hash and all the hashes nested in it. An example of the result is:

```ruby
{ nil => nil, 1 => 1, nested: { a: 3, 5 => 5 } }.deep_stringify_keys
# => {""=>nil, "1"=>1, "nested"=>{"a"=>3, "5"=>5}}
```

Defined in active_support/core_ext/hash/keys.rb.


#### 12.4.3. symbolize_keys and symbolize_keys!

The method symbolize_keys returns a hash that has a symbolized version of the keys in the receiver, where possible. It does so by sending to_sym to them:

```ruby
{ nil => nil, 1 => 1, "a" => "a" }.symbolize_keys
# => {nil=>nil, 1=>1, :a=>"a"}
```

Note in the previous example only one key was symbolized.

In case of key collision, the value will be the one most recently inserted into the hash:

```ruby
{ "a" => 1, a: 2 }.symbolize_keys
# => {:a=>2}
```

This method may be useful for example to easily accept both symbols and strings as options. For instance ActionText::TagHelper defines

```ruby
def rich_textarea_tag(name, value = nil, options = {})
  options = options.symbolize_keys

  options[:input] ||= "trix_input_#{ActionText::TagHelper.id += 1}"
  # ...
end
```

The third line can safely access the :input key, and let the user to pass either :input or "input".

There's also the bang variant symbolize_keys! that symbolizes keys in place.

Besides that, one can use deep_symbolize_keys and deep_symbolize_keys! to symbolize all the keys in the given hash and all the hashes nested in it. An example of the result is:

```ruby
{ nil => nil, 1 => 1, "nested" => { "a" => 3, 5 => 5 } }.deep_symbolize_keys
# => {nil=>nil, 1=>1, nested:{a:3, 5=>5}}
```

Defined in active_support/core_ext/hash/keys.rb.


#### 12.4.4. to_options and to_options!

The methods to_options and to_options! are aliases of symbolize_keys and symbolize_keys!, respectively.

Defined in active_support/core_ext/hash/keys.rb.


#### 12.4.5. assert_valid_keys

The method assert_valid_keys receives an arbitrary number of arguments, and checks whether the receiver has any key outside that list. If it does ArgumentError is raised.

```ruby
{ a: 1 }.assert_valid_keys(:a)  # passes
{ a: 1 }.assert_valid_keys("a") # ArgumentError
```

Active Record does not accept unknown options when building associations, for example. It implements that control via assert_valid_keys.

Defined in active_support/core_ext/hash/keys.rb.


### 12.5. Working with Values


#### 12.5.1. deep_transform_values and deep_transform_values!

The method deep_transform_values returns a new hash with all values converted by the block operation. This includes the values from the root hash and from all nested hashes and arrays.

```ruby
hash = { person: { name: "Rob", age: "28" } }

hash.deep_transform_values { |value| value.to_s.upcase }
# => {person: {name: "ROB", age: "28"}}
```

There's also the bang variant deep_transform_values! that destructively converts all values by using the block operation.

Defined in active_support/core_ext/hash/deep_transform_values.rb.


### 12.6. Slicing

The method slice! replaces the hash with only the given keys and returns a hash containing the removed key/value pairs.

```ruby
hash = { a: 1, b: 2 }
rest = hash.slice!(:a) # => {:b=>2}
hash                   # => {:a=>1}
```

Defined in active_support/core_ext/hash/slice.rb.


### 12.7. Extracting

The method extract! removes and returns the key/value pairs matching the given keys.

```ruby
hash = { a: 1, b: 2 }
rest = hash.extract!(:a) # => {:a=>1}
hash                     # => {:b=>2}
```

The method extract! returns the same subclass of Hash that the receiver is.

```ruby
hash = { a: 1, b: 2 }.with_indifferent_access
rest = hash.extract!(:a).class
# => ActiveSupport::HashWithIndifferentAccess
```

Defined in active_support/core_ext/hash/slice.rb.


### 12.8. Indifferent Access

The method with_indifferent_access returns an ActiveSupport::HashWithIndifferentAccess out of its receiver:

```ruby
{ a: 1 }.with_indifferent_access["a"] # => 1
```

Defined in active_support/core_ext/hash/indifferent_access.rb.


## 13. Extensions to Regexp


### 13.1. multiline?

The method multiline? says whether a regexp has the /m flag set, that is, whether the dot matches newlines.

```ruby
%r{.}.multiline?  # => false
%r{.}m.multiline? # => true

Regexp.new(".").multiline?                    # => false
Regexp.new(".", Regexp::MULTILINE).multiline? # => true
```

Rails uses this method in a single place, also in the routing code. Multiline regexps are disallowed for route requirements and this flag eases enforcing that constraint.

```ruby
def verify_regexp_requirements(requirements)
  # ...
  if requirement.multiline?
    raise ArgumentError, "Regexp multiline option is not allowed in routing requirements: #{requirement.inspect}"
  end
  # ...
end
```

Defined in active_support/core_ext/regexp.rb.


## 14. Extensions to Range


### 14.1. to_fs

Active Support defines Range#to_fs as an alternative to to_s that understands an optional format argument. As of this writing the only supported non-default format is :db:

```ruby
(Date.today..Date.tomorrow).to_fs
# => "2009-10-25..2009-10-26"

(Date.today..Date.tomorrow).to_fs(:db)
# => "BETWEEN '2009-10-25' AND '2009-10-26'"
```

As the example depicts, the :db format generates a BETWEEN SQL clause. That is used by Active Record in its support for range values in conditions.

Defined in active_support/core_ext/range/conversions.rb.


### 14.2. === and include?

The methods Range#=== and Range#include? say whether some value falls between the ends of a given instance:

```ruby
(2..3).include?(Math::E) # => true
```

Active Support extends these methods so that the argument may be another range in turn. In that case we test whether the ends of the argument range belong to the receiver themselves:

```ruby
(1..10) === (3..7)  # => true
(1..10) === (0..7)  # => false
(1..10) === (3..11) # => false
(1...9) === (3..9)  # => false

(1..10).include?(3..7)  # => true
(1..10).include?(0..7)  # => false
(1..10).include?(3..11) # => false
(1...9).include?(3..9)  # => false
```

Defined in active_support/core_ext/range/compare_range.rb.


### 14.3. overlap?

The method Range#overlap? says whether any two given ranges have non-void intersection:

```ruby
(1..10).overlap?(7..11)  # => true
(1..10).overlap?(0..7)   # => true
(1..10).overlap?(11..27) # => false
```

Defined in active_support/core_ext/range/overlap.rb.


## 15. Extensions to Date


### 15.1. Calculations

The following calculation methods have edge cases in October 1582, since days 5..14 just do not exist. This guide does not document their behavior around those days for brevity, but it is enough to say that they do what you would expect. That is, Date.new(1582, 10, 4).tomorrow returns Date.new(1582, 10, 15) and so on. Please check test/core_ext/date_ext_test.rb in the Active Support test suite for expected behavior.


#### 15.1.1. Date.current

Active Support defines Date.current to be today in the current time zone. That's like Date.today, except that it honors the user time zone, if defined. It also defines Date.yesterday and Date.tomorrow, and the instance predicates past?, today?, tomorrow?, next_day?, yesterday?, prev_day?, future?, on_weekday? and on_weekend?, all of them relative to Date.current.

When making Date comparisons using methods which honor the user time zone, make sure to use Date.current and not Date.today. There are cases where the user time zone might be in the future compared to the system time zone, which Date.today uses by default. This means Date.today may equal Date.yesterday.

Defined in active_support/core_ext/date/calculations.rb.


#### 15.1.2. Named Dates

The methods beginning_of_week and end_of_week return the dates for the
beginning and end of the week, respectively. Weeks are assumed to start on
Monday, but that can be changed passing an argument, setting thread local
Date.beginning_of_week or config.beginning_of_week.

```ruby
d = Date.new(2010, 5, 8)     # => Sat, 08 May 2010
d.beginning_of_week          # => Mon, 03 May 2010
d.beginning_of_week(:sunday) # => Sun, 02 May 2010
d.end_of_week                # => Sun, 09 May 2010
d.end_of_week(:sunday)       # => Sat, 08 May 2010
```

beginning_of_week is aliased to at_beginning_of_week and end_of_week is aliased to at_end_of_week.

Defined in active_support/core_ext/date_and_time/calculations.rb.

The methods monday and sunday return the dates for the previous Monday and
next Sunday, respectively.

```ruby
d = Date.new(2010, 5, 8)     # => Sat, 08 May 2010
d.monday                     # => Mon, 03 May 2010
d.sunday                     # => Sun, 09 May 2010

d = Date.new(2012, 9, 10)    # => Mon, 10 Sep 2012
d.monday                     # => Mon, 10 Sep 2012

d = Date.new(2012, 9, 16)    # => Sun, 16 Sep 2012
d.sunday                     # => Sun, 16 Sep 2012
```

Defined in active_support/core_ext/date_and_time/calculations.rb.

The method next_week receives a symbol with a day name in English (default is the thread local Date.beginning_of_week, or config.beginning_of_week, or :monday) and it returns the date corresponding to that day.

```ruby
d = Date.new(2010, 5, 9) # => Sun, 09 May 2010
d.next_week              # => Mon, 10 May 2010
d.next_week(:saturday)   # => Sat, 15 May 2010
```

The method prev_week is analogous:

```ruby
d.prev_week              # => Mon, 26 Apr 2010
d.prev_week(:saturday)   # => Sat, 01 May 2010
d.prev_week(:friday)     # => Fri, 30 Apr 2010
```

prev_week is aliased to last_week.

Both next_week and prev_week work as expected when Date.beginning_of_week or config.beginning_of_week are set.

Defined in active_support/core_ext/date_and_time/calculations.rb.

The methods beginning_of_month and end_of_month return the dates for the beginning and end of the month:

```ruby
d = Date.new(2010, 5, 9) # => Sun, 09 May 2010
d.beginning_of_month     # => Sat, 01 May 2010
d.end_of_month           # => Mon, 31 May 2010
```

beginning_of_month is aliased to at_beginning_of_month, and end_of_month is aliased to at_end_of_month.

Defined in active_support/core_ext/date_and_time/calculations.rb.

The method quarter returns the quarter of the receiver's calendar year:

```ruby
d = Date.new(2010, 5, 9) # => Sun, 09 May 2010
d.quarter                # => 2
```

The methods beginning_of_quarter and end_of_quarter return the dates for the beginning and end of the quarter of the receiver's calendar year:

```ruby
d = Date.new(2010, 5, 9) # => Sun, 09 May 2010
d.beginning_of_quarter   # => Thu, 01 Apr 2010
d.end_of_quarter         # => Wed, 30 Jun 2010
```

beginning_of_quarter is aliased to at_beginning_of_quarter, and end_of_quarter is aliased to at_end_of_quarter.

Defined in active_support/core_ext/date_and_time/calculations.rb.

The methods beginning_of_year and end_of_year return the dates for the beginning and end of the year:

```ruby
d = Date.new(2010, 5, 9) # => Sun, 09 May 2010
d.beginning_of_year      # => Fri, 01 Jan 2010
d.end_of_year            # => Fri, 31 Dec 2010
```

beginning_of_year is aliased to at_beginning_of_year, and end_of_year is aliased to at_end_of_year.

Defined in active_support/core_ext/date_and_time/calculations.rb.


#### 15.1.3. Other Date Computations

The method years_ago receives a number of years and returns the same date those many years ago:

```ruby
date = Date.new(2010, 6, 7)
date.years_ago(10) # => Wed, 07 Jun 2000
```

years_since moves forward in time:

```ruby
date = Date.new(2010, 6, 7)
date.years_since(10) # => Sun, 07 Jun 2020
```

If such a day does not exist, the last day of the corresponding month is returned:

```ruby
Date.new(2012, 2, 29).years_ago(3)     # => Sat, 28 Feb 2009
Date.new(2012, 2, 29).years_since(3)   # => Sat, 28 Feb 2015
```

last_year is short-hand for #years_ago(1).

Defined in active_support/core_ext/date_and_time/calculations.rb.

The methods months_ago and months_since work analogously for months:

```ruby
Date.new(2010, 4, 30).months_ago(2)   # => Sun, 28 Feb 2010
Date.new(2010, 4, 30).months_since(2) # => Wed, 30 Jun 2010
```

If such a day does not exist, the last day of the corresponding month is returned:

```ruby
Date.new(2010, 4, 30).months_ago(2)    # => Sun, 28 Feb 2010
Date.new(2009, 12, 31).months_since(2) # => Sun, 28 Feb 2010
```

last_month is short-hand for #months_ago(1).

Defined in active_support/core_ext/date_and_time/calculations.rb.

The method weeks_ago and [weeks_since][DateAndTime::Calculations#week_since] work analogously for weeks:

```ruby
Date.new(2010, 5, 24).weeks_ago(1)   # => Mon, 17 May 2010
Date.new(2010, 5, 24).weeks_since(2) # => Mon, 07 Jun 2010
```

Defined in active_support/core_ext/date_and_time/calculations.rb.

The most generic way to jump to other days is advance. This method receives a hash with keys :years, :months, :weeks, :days, and returns a date advanced as much as the present keys indicate:

```ruby
date = Date.new(2010, 6, 6)
date.advance(years: 1, weeks: 2)  # => Mon, 20 Jun 2011
date.advance(months: 2, days: -2) # => Wed, 04 Aug 2010
```

Note in the previous example that increments may be negative.

Defined in active_support/core_ext/date/calculations.rb.


#### 15.1.4. Changing Components

The method change allows you to get a new date which is the same as the receiver except for the given year, month, or day:

```ruby
Date.new(2010, 12, 23).change(year: 2011, month: 11)
# => Wed, 23 Nov 2011
```

This method is not tolerant to non-existing dates, if the change is invalid ArgumentError is raised:

```ruby
Date.new(2010, 1, 31).change(month: 2)
# => ArgumentError: invalid date
```

Defined in active_support/core_ext/date/calculations.rb.


#### 15.1.5. Durations

Duration objects can be added to and subtracted from dates:

```ruby
d = Date.current
# => Mon, 09 Aug 2010
d + 1.year
# => Tue, 09 Aug 2011
d - 3.hours
# => Sun, 08 Aug 2010 21:00:00 UTC +00:00
```

They translate to calls to since or advance. For example here we get the correct jump in the calendar reform:

```ruby
Date.new(1582, 10, 4) + 1.day
# => Fri, 15 Oct 1582
```


#### 15.1.6. Timestamps

The following methods return a Time object if possible, otherwise a DateTime. If set, they honor the user time zone.

The method beginning_of_day returns a timestamp at the beginning of the day (00:00:00):

```ruby
date = Date.new(2010, 6, 7)
date.beginning_of_day # => Mon Jun 07 00:00:00 +0200 2010
```

The method end_of_day returns a timestamp at the end of the day (23:59:59):

```ruby
date = Date.new(2010, 6, 7)
date.end_of_day # => Mon Jun 07 23:59:59 +0200 2010
```

beginning_of_day is aliased to at_beginning_of_day, midnight, at_midnight.

Defined in active_support/core_ext/date/calculations.rb.

The method beginning_of_hour returns a timestamp at the beginning of the hour (hh:00:00):

```ruby
date = DateTime.new(2010, 6, 7, 19, 55, 25)
date.beginning_of_hour # => Mon Jun 07 19:00:00 +0200 2010
```

The method end_of_hour returns a timestamp at the end of the hour (hh:59:59):

```ruby
date = DateTime.new(2010, 6, 7, 19, 55, 25)
date.end_of_hour # => Mon Jun 07 19:59:59 +0200 2010
```

beginning_of_hour is aliased to at_beginning_of_hour.

Defined in active_support/core_ext/date_time/calculations.rb.

The method beginning_of_minute returns a timestamp at the beginning of the minute (hh:mm:00):

```ruby
date = DateTime.new(2010, 6, 7, 19, 55, 25)
date.beginning_of_minute # => Mon Jun 07 19:55:00 +0200 2010
```

The method end_of_minute returns a timestamp at the end of the minute (hh:mm:59):

```ruby
date = DateTime.new(2010, 6, 7, 19, 55, 25)
date.end_of_minute # => Mon Jun 07 19:55:59 +0200 2010
```

beginning_of_minute is aliased to at_beginning_of_minute.

beginning_of_hour, end_of_hour, beginning_of_minute, and end_of_minute are implemented for Time and DateTime but not Date as it does not make sense to request the beginning or end of an hour or minute on a Date instance.

Defined in active_support/core_ext/date_time/calculations.rb.

The method ago receives a number of seconds as argument and returns a timestamp those many seconds ago from midnight:

```ruby
date = Date.current # => Fri, 11 Jun 2010
date.ago(1)         # => Thu, 10 Jun 2010 23:59:59 EDT -04:00
```

Similarly, since moves forward:

```ruby
date = Date.current # => Fri, 11 Jun 2010
date.since(1)       # => Fri, 11 Jun 2010 00:00:01 EDT -04:00
```

Defined in active_support/core_ext/date/calculations.rb.


## 16. Extensions to DateTime

DateTime is not aware of DST rules and so some of these methods have edge cases when a DST change is going on. For example seconds_since_midnight might not return the real amount in such a day.


### 16.1. Calculations

The class DateTime is a subclass of Date so by loading active_support/core_ext/date/calculations.rb you inherit these methods and their aliases, except that they will always return datetimes.

The following methods are reimplemented so you do not need to load active_support/core_ext/date/calculations.rb for these ones:

- beginning_of_day / midnight / at_midnight / at_beginning_of_day

- end_of_day

- ago

- since / in

On the other hand, advance and change are also defined and support more options, they are documented below.

The following methods are only implemented in active_support/core_ext/date_time/calculations.rb as they only make sense when used with a DateTime instance:

- beginning_of_hour / at_beginning_of_hour

- end_of_hour


#### 16.1.1. Named Datetimes

Active Support defines DateTime.current to be like Time.now.to_datetime, except that it honors the user time zone, if defined. The instance predicates past? and future? are defined relative to DateTime.current.

Defined in active_support/core_ext/date_time/calculations.rb.


#### 16.1.2. Other Extensions

The method seconds_since_midnight returns the number of seconds since midnight:

```ruby
now = DateTime.current     # => Mon, 07 Jun 2010 20:26:36 +0000
now.seconds_since_midnight # => 73596
```

Defined in active_support/core_ext/date_time/calculations.rb.

The method utc gives you the same datetime in the receiver expressed in UTC.

```ruby
now = DateTime.current # => Mon, 07 Jun 2010 19:27:52 -0400
now.utc                # => Mon, 07 Jun 2010 23:27:52 +0000
```

This method is also aliased as getutc.

Defined in active_support/core_ext/date_time/calculations.rb.

The predicate utc? says whether the receiver has UTC as its time zone:

```ruby
now = DateTime.now # => Mon, 07 Jun 2010 19:30:47 -0400
now.utc?           # => false
now.utc.utc?       # => true
```

Defined in active_support/core_ext/date_time/calculations.rb.

The most generic way to jump to another datetime is advance. This method receives a hash with keys :years, :months, :weeks, :days, :hours, :minutes, and :seconds, and returns a datetime advanced as much as the present keys indicate.

```ruby
d = DateTime.current
# => Thu, 05 Aug 2010 11:33:31 +0000
d.advance(years: 1, months: 1, days: 1, hours: 1, minutes: 1, seconds: 1)
# => Tue, 06 Sep 2011 12:34:32 +0000
```

This method first computes the destination date passing :years, :months, :weeks, and :days to Date#advance documented above. After that, it adjusts the time calling since with the number of seconds to advance. This order is relevant, a different ordering would give different datetimes in some edge-cases. The example in Date#advance applies, and we can extend it to show order relevance related to the time bits.

If we first move the date bits (that have also a relative order of processing, as documented before), and then the time bits we get for example the following computation:

```ruby
d = DateTime.new(2010, 2, 28, 23, 59, 59)
# => Sun, 28 Feb 2010 23:59:59 +0000
d.advance(months: 1, seconds: 1)
# => Mon, 29 Mar 2010 00:00:00 +0000
```

but if we computed them the other way around, the result would be different:

```ruby
d.advance(seconds: 1).advance(months: 1)
# => Thu, 01 Apr 2010 00:00:00 +0000
```

Since DateTime is not DST-aware you can end up in a non-existing point in time with no warning or error telling you so.

Defined in active_support/core_ext/date_time/calculations.rb.


#### 16.1.3. Changing Components

The method change allows you to get a new datetime which is the same as the receiver except for the given options, which may include :year, :month, :day, :hour, :min, :sec, :offset, :start:

```ruby
now = DateTime.current
# => Tue, 08 Jun 2010 01:56:22 +0000
now.change(year: 2011, offset: Rational(-6, 24))
# => Wed, 08 Jun 2011 01:56:22 -0600
```

If hours are zeroed, then minutes and seconds are too (unless they have given values):

```ruby
now.change(hour: 0)
# => Tue, 08 Jun 2010 00:00:00 +0000
```

Similarly, if minutes are zeroed, then seconds are too (unless it has given a value):

```ruby
now.change(min: 0)
# => Tue, 08 Jun 2010 01:00:00 +0000
```

This method is not tolerant to non-existing dates, if the change is invalid ArgumentError is raised:

```ruby
DateTime.current.change(month: 2, day: 30)
# => ArgumentError: invalid date
```

Defined in active_support/core_ext/date_time/calculations.rb.


#### 16.1.4. Durations

Duration objects can be added to and subtracted from datetimes:

```ruby
now = DateTime.current
# => Mon, 09 Aug 2010 23:15:17 +0000
now + 1.year
# => Tue, 09 Aug 2011 23:15:17 +0000
now - 1.week
# => Mon, 02 Aug 2010 23:15:17 +0000
```

They translate to calls to since or advance. For example here we get the correct jump in the calendar reform:

```ruby
DateTime.new(1582, 10, 4, 23) + 1.hour
# => Fri, 15 Oct 1582 00:00:00 +0000
```


## 17. Extensions to Time


### 17.1. Calculations

They are analogous. Please refer to their documentation above and take into account the following differences:

- change accepts an additional :usec option.

- Time understands DST, so you get correct DST calculations as in

```ruby
Time.zone_default
# => #<ActiveSupport::TimeZone:0x7f73654d4f38 @utc_offset=nil, @name="Madrid", ...>

# In Barcelona, 2010/03/28 02:00 +0100 becomes 2010/03/28 03:00 +0200 due to DST.
t = Time.local(2010, 3, 28, 1, 59, 59)
# => Sun Mar 28 01:59:59 +0100 2010
t.advance(seconds: 1)
# => Sun Mar 28 03:00:00 +0200 2010
```

- If since or ago jumps to a time that can't be expressed with Time a DateTime object is returned instead.


#### 17.1.1. Time.current

Active Support defines Time.current to be today in the current time zone. That's like Time.now, except that it honors the user time zone, if defined. It also defines the instance predicates past?, today?, tomorrow?, next_day?, yesterday?, prev_day? and future?, all of them relative to Time.current.

When making Time comparisons using methods which honor the user time zone, make sure to use Time.current instead of Time.now. There are cases where the user time zone might be in the future compared to the system time zone, which Time.now uses by default. This means Time.now.to_date may equal Date.yesterday.

Defined in active_support/core_ext/time/calculations.rb.


#### 17.1.2. all_day, all_week, all_month, all_quarter, and all_year

The method all_day returns a range representing the whole day of the current time.

```ruby
now = Time.current
# => Mon, 09 Aug 2010 23:20:05 UTC +00:00
now.all_day
# => Mon, 09 Aug 2010 00:00:00 UTC +00:00..Mon, 09 Aug 2010 23:59:59 UTC +00:00
```

Analogously, all_week, all_month, all_quarter and all_year all serve the purpose of generating time ranges.

```ruby
now = Time.current
# => Mon, 09 Aug 2010 23:20:05 UTC +00:00
now.all_week
# => Mon, 09 Aug 2010 00:00:00 UTC +00:00..Sun, 15 Aug 2010 23:59:59 UTC +00:00
now.all_week(:sunday)
# => Sun, 16 Sep 2012 00:00:00 UTC +00:00..Sat, 22 Sep 2012 23:59:59 UTC +00:00
now.all_month
# => Sat, 01 Aug 2010 00:00:00 UTC +00:00..Tue, 31 Aug 2010 23:59:59 UTC +00:00
now.all_quarter
# => Thu, 01 Jul 2010 00:00:00 UTC +00:00..Thu, 30 Sep 2010 23:59:59 UTC +00:00
now.all_year
# => Fri, 01 Jan 2010 00:00:00 UTC +00:00..Fri, 31 Dec 2010 23:59:59 UTC +00:00
```

Defined in active_support/core_ext/date_and_time/calculations.rb.


#### 17.1.3. prev_day, next_day

prev_day and next_day return the time in the last or next day:

```ruby
t = Time.new(2010, 5, 8) # => 2010-05-08 00:00:00 +0900
t.prev_day               # => 2010-05-07 00:00:00 +0900
t.next_day               # => 2010-05-09 00:00:00 +0900
```

Defined in active_support/core_ext/time/calculations.rb.


#### 17.1.4. prev_month, next_month

prev_month and next_month return the time with the same day in the last or next month:

```ruby
t = Time.new(2010, 5, 8) # => 2010-05-08 00:00:00 +0900
t.prev_month             # => 2010-04-08 00:00:00 +0900
t.next_month             # => 2010-06-08 00:00:00 +0900
```

If such a day does not exist, the last day of the corresponding month is returned:

```ruby
Time.new(2000, 5, 31).prev_month # => 2000-04-30 00:00:00 +0900
Time.new(2000, 3, 31).prev_month # => 2000-02-29 00:00:00 +0900
Time.new(2000, 5, 31).next_month # => 2000-06-30 00:00:00 +0900
Time.new(2000, 1, 31).next_month # => 2000-02-29 00:00:00 +0900
```

Defined in active_support/core_ext/time/calculations.rb.


#### 17.1.5. prev_year, next_year

prev_year and next_year return a time with the same day/month in the last or next year:

```ruby
t = Time.new(2010, 5, 8) # => 2010-05-08 00:00:00 +0900
t.prev_year              # => 2009-05-08 00:00:00 +0900
t.next_year              # => 2011-05-08 00:00:00 +0900
```

If date is the 29th of February of a leap year, you obtain the 28th:

```ruby
t = Time.new(2000, 2, 29) # => 2000-02-29 00:00:00 +0900
t.prev_year               # => 1999-02-28 00:00:00 +0900
t.next_year               # => 2001-02-28 00:00:00 +0900
```

Defined in active_support/core_ext/time/calculations.rb.


#### 17.1.6. prev_quarter, next_quarter

prev_quarter and next_quarter return the date with the same day in the previous or next quarter:

```ruby
t = Time.local(2010, 5, 8) # => 2010-05-08 00:00:00 +0300
t.prev_quarter             # => 2010-02-08 00:00:00 +0200
t.next_quarter             # => 2010-08-08 00:00:00 +0300
```

If such a day does not exist, the last day of the corresponding month is returned:

```ruby
Time.local(2000, 7, 31).prev_quarter  # => 2000-04-30 00:00:00 +0300
Time.local(2000, 5, 31).prev_quarter  # => 2000-02-29 00:00:00 +0200
Time.local(2000, 10, 31).prev_quarter # => 2000-07-31 00:00:00 +0300
Time.local(2000, 11, 31).next_quarter # => 2001-03-01 00:00:00 +0200
```

prev_quarter is aliased to last_quarter.

Defined in active_support/core_ext/date_and_time/calculations.rb.


### 17.2. Time Constructors

Active Support defines Time.current to be Time.zone.now if there's a user time zone defined, with fallback to Time.now:

```ruby
Time.zone_default
# => #<ActiveSupport::TimeZone:0x7f73654d4f38 @utc_offset=nil, @name="Madrid", ...>
Time.current
# => Fri, 06 Aug 2010 17:11:58 CEST +02:00
```

Analogously to DateTime, the predicates past?, and future? are relative to Time.current.

If the time to be constructed lies beyond the range supported by Time in the runtime platform, usecs are discarded and a DateTime object is returned instead.


#### 17.2.1. Durations

Duration objects can be added to and subtracted from time objects:

```ruby
now = Time.current
# => Mon, 09 Aug 2010 23:20:05 UTC +00:00
now + 1.year
# => Tue, 09 Aug 2011 23:21:11 UTC +00:00
now - 1.week
# => Mon, 02 Aug 2010 23:21:11 UTC +00:00
```

They translate to calls to since or advance. For example here we get the correct jump in the calendar reform:

```ruby
Time.utc(1582, 10, 3) + 5.days
# => Mon Oct 18 00:00:00 UTC 1582
```


## 18. Extensions to File


### 18.1. atomic_write

With the class method File.atomic_write you can write to a file in a way that will prevent any reader from seeing half-written content.

The name of the file is passed as an argument, and the method yields a file handle opened for writing. Once the block is done atomic_write closes the file handle and completes its job.

For example, Action Pack uses this method to write asset cache files like all.css:

```ruby
File.atomic_write(joined_asset_path) do |cache|
  cache.write(join_asset_file_contents(asset_paths))
end
```

To accomplish this atomic_write creates a temporary file. That's the file the code in the block actually writes to. On completion, the temporary file is renamed, which is an atomic operation on POSIX systems. If the target file exists atomic_write overwrites it and keeps owners and permissions. However there are a few cases where atomic_write cannot change the file ownership or permissions, this error is caught and skipped over trusting in the user/filesystem to ensure the file is accessible to the processes that need it.

Due to the chmod operation atomic_write performs, if the target file has an ACL set on it this ACL will be recalculated/modified.

Note you can't append with atomic_write.

The auxiliary file is written in a standard directory for temporary files, but you can pass a directory of your choice as second argument.

Defined in active_support/core_ext/file/atomic.rb.


## 19. Extensions to NameError

Active Support adds missing_name? to NameError, which tests whether the exception was raised because of the name passed as argument.

The name may be given as a symbol or string. A symbol is tested against the bare constant name, a string is against the fully qualified constant name.

A symbol can represent a fully qualified constant name as in :"ActiveRecord::Base", so the behavior for symbols is defined for convenience, not because it has to be that way technically.

For example, when an action of ArticlesController is called Rails tries optimistically to use ArticlesHelper. It is OK that the helper module does not exist, so if an exception for that constant name is raised it should be silenced. But it could be the case that articles_helper.rb raises a NameError due to an actual unknown constant. That should be reraised. The method missing_name? provides a way to distinguish both cases:

```ruby
def default_helper_module!
  module_name = name.delete_suffix("Controller")
  module_path = module_name.underscore
  helper module_path
rescue LoadError => e
  raise e unless e.is_missing? "helpers/#{module_path}_helper"
rescue NameError => e
  raise e unless e.missing_name? "#{module_name}Helper"
end
```

Defined in active_support/core_ext/name_error.rb.


## 20. Extensions to LoadError

Active Support adds is_missing? to LoadError.

Given a path name is_missing? tests whether the exception was raised due to that particular file (except perhaps for the ".rb" extension).

For example, when an action of ArticlesController is called Rails tries to load articles_helper.rb, but that file may not exist. That's fine, the helper module is not mandatory so Rails silences a load error. But it could be the case that the helper module does exist and in turn requires another library that is missing. In that case Rails must reraise the exception. The method is_missing? provides a way to distinguish both cases:

```ruby
def default_helper_module!
  module_name = name.delete_suffix("Controller")
  module_path = module_name.underscore
  helper module_path
rescue LoadError => e
  raise e unless e.is_missing? "helpers/#{module_path}_helper"
rescue NameError => e
  raise e unless e.missing_name? "#{module_name}Helper"
end
```

Defined in active_support/core_ext/load_error.rb.


## 21. Extensions to Pathname


### 21.1. existence

The existence method returns the receiver if the named file exists otherwise returns nil. It is useful for idioms like this:

```ruby
content = Pathname.new("file").existence&.read
```

Defined in active_support/core_ext/pathname/existence.rb.


---

# Chapters

Active Support is a part of core Rails that provides Ruby language extensions, utilities, and other things. One of the things it includes is an instrumentation API that can be used inside an application to measure certain actions that occur within Ruby code, such as those inside a Rails application or the framework itself. It is not limited to Rails, however. It can be used independently in other Ruby scripts if desired.

In this guide, you will learn how to use the Active Support's instrumentation API to measure events inside of Rails and other Ruby code.

After reading this guide, you will know:

- What instrumentation can provide.

- How to add a subscriber to a hook.

- The hooks inside the Rails framework for instrumentation.

- How to build a custom instrumentation implementation.


## 1. Introduction to Instrumentation

The instrumentation API provided by Active Support allows developers to provide hooks which other developers may hook into. There are several of these within the Rails framework. With this API, developers can choose to be notified when certain events occur inside their application or another piece of Ruby code.

For example, there is a hook provided within Active Record that is called every time Active Record uses an SQL query on a database. This hook could be subscribed to, and used to track the number of queries during a certain action. There's another hook around the processing of an action of a controller. This could be used, for instance, to track how long a specific action has taken.

You are even able to create your own events inside your application which you can later subscribe to.


## 2. Subscribing to an Event

Use ActiveSupport::Notifications.subscribe with a block to listen to any notification. Depending on the amount of
arguments the block takes, you will receive different data.

The first way to subscribe to an event is to use a block with a single argument. The argument will be an instance of
ActiveSupport::Notifications::Event.

```ruby
ActiveSupport::Notifications.subscribe "process_action.action_controller" do |event|
  event.name        # => "process_action.action_controller"
  event.duration    # => 10 (in milliseconds)
  event.allocations # => 1826
  event.payload     # => {:extra=>information}

  Rails.logger.info "#{event} Received!"
end
```

If you don't need all the data recorded by an Event object, you can also specify a
block that takes the following five arguments:

- Name of the event

- Time when it started

- Time when it finished

- A unique ID for the instrumenter that fired the event

- The payload for the event

```ruby
ActiveSupport::Notifications.subscribe "process_action.action_controller" do |name, started, finished, unique_id, payload|
  # your own custom stuff
  Rails.logger.info "#{name} Received! (started: #{started}, finished: #{finished})" # process_action.action_controller Received! (started: 2019-05-05 13:43:57 -0800, finished: 2019-05-05 13:43:58 -0800)
end
```

If you are concerned about the accuracy of started and finished to compute a precise elapsed time, then use ActiveSupport::Notifications.monotonic_subscribe. The given block would receive the same arguments as above, but the started and finished will have values with an accurate monotonic time instead of wall-clock time.

```ruby
ActiveSupport::Notifications.monotonic_subscribe "process_action.action_controller" do |name, started, finished, unique_id, payload|
  # your own custom stuff
  duration = finished - started # 1560979.429234 - 1560978.425334
  Rails.logger.info "#{name} Received! (duration: #{duration})" # process_action.action_controller Received! (duration: 1.0039)
end
```

You may also subscribe to events matching a regular expression. This enables you to subscribe to
multiple events at once. Here's how to subscribe to everything from ActionController:

```ruby
ActiveSupport::Notifications.subscribe(/action_controller/) do |event|
  # inspect all ActionController events
end
```


## 3. Rails Framework Hooks

Within the Ruby on Rails framework, there are a number of hooks provided for common events. These events and their payloads are detailed below.


### 3.1. Action Cable


#### 3.1.1. perform_action.action_cable


#### 3.1.2. transmit.action_cable


#### 3.1.3. transmit_subscription_confirmation.action_cable


#### 3.1.4. transmit_subscription_rejection.action_cable


#### 3.1.5. broadcast.action_cable


### 3.2. Action Controller


#### 3.2.1. start_processing.action_controller

```ruby
{
  controller: "PostsController",
  action: "new",
  params: { "action" => "new", "controller" => "posts" },
  headers: #<ActionDispatch::Http::Headers:0x0055a67a519b88>,
  format: :html,
  method: "GET",
  path: "/posts/new"
}
```


#### 3.2.2. process_action.action_controller

```ruby
{
  controller: "PostsController",
  action: "index",
  params: {"action" => "index", "controller" => "posts"},
  headers: #<ActionDispatch::Http::Headers:0x0055a67a519b88>,
  format: :html,
  method: "GET",
  path: "/posts",
  request: #<ActionDispatch::Request:0x00007ff1cb9bd7b8>,
  response: #<ActionDispatch::Response:0x00007f8521841ec8>,
  status: 200,
  view_runtime: 46.848,
  db_runtime: 0.157
}
```


#### 3.2.3. send_file.action_controller

Additional keys may be added by the caller.


#### 3.2.4. send_data.action_controller

ActionController does not add any specific information to the payload. All options are passed through to the payload.


#### 3.2.5. redirect_to.action_controller

```ruby
{
  status: 302,
  location: "http://localhost:3000/posts/new",
  request: <ActionDispatch::Request:0x00007ff1cb9bd7b8>
}
```


#### 3.2.6. halted_callback.action_controller

```ruby
{
  filter: ":halting_filter"
}
```


#### 3.2.7. unpermitted_parameters.action_controller


#### 3.2.8. send_stream.action_controller

```ruby
{
  filename: "subscribers.csv",
  type: "text/csv",
  disposition: "attachment"
}
```


#### 3.2.9. rate_limit.action_controller


### 3.3. Action Controller: Caching


#### 3.3.1. write_fragment.action_controller

```ruby
{
  key: 'posts/1-dashboard-view'
}
```


#### 3.3.2. read_fragment.action_controller

```ruby
{
  key: 'posts/1-dashboard-view'
}
```


#### 3.3.3. expire_fragment.action_controller

```ruby
{
  key: 'posts/1-dashboard-view'
}
```


#### 3.3.4. exist_fragment?.action_controller

```ruby
{
  key: 'posts/1-dashboard-view'
}
```


### 3.4. Action Dispatch


#### 3.4.1. process_middleware.action_dispatch


#### 3.4.2. redirect.action_dispatch


#### 3.4.3. request.action_dispatch


### 3.5. Action Mailbox


#### 3.5.1. process.action_mailbox

```ruby
{
  mailbox: #<RepliesMailbox:0x00007f9f7a8388>,
  inbound_email: {
    id: 1,
    message_id: "0CB459E0-0336-41DA-BC88-E6E28C697DDB@37signals.com",
    status: "processing"
  }
}
```


### 3.6. Action Mailer


#### 3.6.1. deliver.action_mailer

```ruby
{
  mailer: "Notification",
  message_id: "4f5b5491f1774_181b23fc3d4434d38138e5@mba.local.mail",
  subject: "Rails Guides",
  to: ["users@rails.com", "dhh@rails.com"],
  from: ["me@rails.com"],
  date: Sat, 10 Mar 2012 14:18:09 +0100,
  mail: "...", # omitted for brevity
  perform_deliveries: true
}
```


#### 3.6.2. process.action_mailer

```ruby
{
  mailer: "Notification",
  action: "welcome_email",
  args: []
}
```


### 3.7. Action View


#### 3.7.1. render_template.action_view

```ruby
{
  identifier: "/Users/adam/projects/notifications/app/views/posts/index.html.erb",
  layout: "layouts/application",
  locals: { foo: "bar" }
}
```


#### 3.7.2. render_partial.action_view

```ruby
{
  identifier: "/Users/adam/projects/notifications/app/views/posts/_form.html.erb",
  locals: { foo: "bar" }
}
```


#### 3.7.3. render_collection.action_view

The :cache_hits key is only included if the collection is rendered with cached: true.

```ruby
{
  identifier: "/Users/adam/projects/notifications/app/views/posts/_post.html.erb",
  count: 3,
  cache_hits: 0
}
```


#### 3.7.4. render_layout.action_view

```ruby
{
  identifier: "/Users/adam/projects/notifications/app/views/layouts/application.html.erb"
}
```


### 3.8. Active Job


#### 3.8.1. enqueue_at.active_job


#### 3.8.2. enqueue.active_job


#### 3.8.3. enqueue_retry.active_job


#### 3.8.4. enqueue_all.active_job


#### 3.8.5. perform_start.active_job


#### 3.8.6. perform.active_job


#### 3.8.7. retry_stopped.active_job


#### 3.8.8. discard.active_job


### 3.9. Active Record


#### 3.9.1. sql.active_record

Adapters may add their own data as well.

```ruby
{
  sql: "SELECT \"posts\".* FROM \"posts\" ",
  name: "Post Load",
  binds: [<ActiveModel::Attribute::WithCastValue:0x00007fe19d15dc00>],
  type_casted_binds: [11],
  async: false,
  allow_retry: true,
  connection: <ActiveRecord::ConnectionAdapters::SQLite3Adapter:0x00007f9f7a838850>,
  transaction: <ActiveRecord::ConnectionAdapters::RealTransaction:0x0000000121b5d3e0>
  affected_rows: 0
  row_count: 5,
  statement_name: nil,
}
```

If the query is not executed in the context of a transaction, :transaction is nil.


#### 3.9.2. strict_loading_violation.active_record

This event is only emitted when config.active_record.action_on_strict_loading_violation is set to :log.


#### 3.9.3. instantiation.active_record

```ruby
{
  record_count: 1,
  class_name: "User"
}
```


#### 3.9.4. start_transaction.active_record

This event is emitted when a transaction has been started.

Please, note that Active Record does not create the actual database transaction
until needed:

```ruby
ActiveRecord::Base.transaction do
  # We are inside the block, but no event has been triggered yet.

  # The following line makes Active Record start the transaction.
  User.count # Event fired here.
end
```

Remember that ordinary nested calls do not create new transactions:

```ruby
ActiveRecord::Base.transaction do |t1|
  User.count # Fires an event for t1.
  ActiveRecord::Base.transaction do |t2|
    # The next line fires no event for t2, because the only
    # real database transaction in this example is t1.
    User.first.touch
  end
end
```

However, if requires_new: true is passed, you get an event for the nested
transaction too. This might be a savepoint under the hood:

```ruby
ActiveRecord::Base.transaction do |t1|
  User.count # Fires an event for t1.
  ActiveRecord::Base.transaction(requires_new: true) do |t2|
    User.first.touch # Fires an event for t2.
  end
end
```


#### 3.9.5. transaction.active_record

This event is emitted when a database transaction finishes. The state of the
transaction can be found in the :outcome key.

In practice, you cannot do much with the transaction object, but it may still be
helpful for tracing database activity. For example, by tracking
transaction.uuid.


#### 3.9.6. deprecated_association.active_record

This event is emitted when a deprecated association is accessed, and the
configured deprecated associations mode is :notify.

The :location is a Thread::Backtrace::Location object, and :backtrace, if
present, is an array of Thread::Backtrace::Location objects. These are
computed using the Active Record backtrace cleaner. In Rails applications, this
is the same as Rails.backtrace_cleaner.


### 3.10. Active Storage


#### 3.10.1. preview.active_storage


#### 3.10.2. transform.active_storage


#### 3.10.3. analyze.active_storage


### 3.11. Active Storage: Storage Service


#### 3.11.1. service_upload.active_storage


#### 3.11.2. service_streaming_download.active_storage


#### 3.11.3. service_download_chunk.active_storage


#### 3.11.4. service_download.active_storage


#### 3.11.5. service_delete.active_storage


#### 3.11.6. service_delete_prefixed.active_storage


#### 3.11.7. service_exist.active_storage


#### 3.11.8. service_url.active_storage


#### 3.11.9. service_update_metadata.active_storage

This event is only emitted when using the Google Cloud Storage service.


### 3.12. Active Support: Caching


#### 3.12.1. cache_read.active_support


#### 3.12.2. cache_read_multi.active_support


#### 3.12.3. cache_generate.active_support

This event is only emitted when fetch is called with a block.

Options passed to fetch will be merged with the payload when writing to the store.

```ruby
{
  key: "name-of-complicated-computation",
  store: "ActiveSupport::Cache::MemCacheStore"
}
```


#### 3.12.4. cache_fetch_hit.active_support

This event is only emitted when fetch is called with a block.

Options passed to fetch will be merged with the payload.

```ruby
{
  key: "name-of-complicated-computation",
  store: "ActiveSupport::Cache::MemCacheStore"
}
```


#### 3.12.5. cache_write.active_support

Cache stores may add their own data as well.

```ruby
{
  key: "name-of-complicated-computation",
  store: "ActiveSupport::Cache::MemCacheStore"
}
```


#### 3.12.6. cache_write_multi.active_support


#### 3.12.7. cache_increment.active_support

```ruby
{
  key: "bottles-of-beer",
  store: "ActiveSupport::Cache::RedisCacheStore",
  amount: 99
}
```


#### 3.12.8. cache_decrement.active_support

```ruby
{
  key: "bottles-of-beer",
  store: "ActiveSupport::Cache::RedisCacheStore",
  amount: 1
}
```


#### 3.12.9. cache_delete.active_support

```ruby
{
  key: "name-of-complicated-computation",
  store: "ActiveSupport::Cache::MemCacheStore"
}
```


#### 3.12.10. cache_delete_multi.active_support


#### 3.12.11. cache_delete_matched.active_support

This event is only emitted when using RedisCacheStore,
FileStore, or MemoryStore.

```ruby
{
  key: "posts/*",
  store: "ActiveSupport::Cache::RedisCacheStore"
}
```


#### 3.12.12. cache_cleanup.active_support

This event is only emitted when using MemoryStore.

```ruby
{
  store: "ActiveSupport::Cache::MemoryStore",
  size: 9001
}
```


#### 3.12.13. cache_prune.active_support

This event is only emitted when using MemoryStore.

```ruby
{
  store: "ActiveSupport::Cache::MemoryStore",
  key: 5000,
  from: 9001
}
```


#### 3.12.14. cache_exist?.active_support

```ruby
{
  key: "name-of-complicated-computation",
  store: "ActiveSupport::Cache::MemCacheStore"
}
```


### 3.13. Active Support: Messages


#### 3.13.1. message_serializer_fallback.active_support

```ruby
{
  serializer: :json_allow_marshal,
  fallback: :marshal,
  serialized: "\x04\b{\x06I\"\nHello\x06:\x06ETI\"\nWorld\x06;\x00T",
  deserialized: { "Hello" => "World" },
}
```


### 3.14. Rails


#### 3.14.1. deprecation.rails


### 3.15. Railties


#### 3.15.1. load_config_initializer.railties


## 4. Exceptions

If an exception happens during any instrumentation, the payload will include
information about it.


## 5. Creating Custom Events

Adding your own events is easy as well. Active Support will take care of
all the heavy lifting for you. Simply call ActiveSupport::Notifications.instrument with a name, payload, and a block.
The notification will be sent after the block returns. Active Support will generate the start and end times,
and add the instrumenter's unique ID. All data passed into the instrument call will make
it into the payload.

Here's an example:

```ruby
ActiveSupport::Notifications.instrument "my.custom.event", this: :data do
  # do your custom stuff here
end
```

Now you can listen to this event with:

```ruby
ActiveSupport::Notifications.subscribe "my.custom.event" do |name, started, finished, unique_id, data|
  puts data.inspect # {:this=>:data}
end
```

You may also call instrument without passing a block. This lets you leverage the
instrumentation infrastructure for other messaging uses.

```ruby
ActiveSupport::Notifications.instrument "my.custom.event", this: :data

ActiveSupport::Notifications.subscribe "my.custom.event" do |name, started, finished, unique_id, data|
  puts data.inspect # {:this=>:data}
end
```

You should follow Rails conventions when defining your own events. The format is: event.library.
If your application is sending Tweets, you should create an event named tweet.twitter.
