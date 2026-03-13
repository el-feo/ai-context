# Step Definitions Reference

Step definitions connect Gherkin steps to executable Ruby code.

## Table of Contents

- [How Matching Works](#how-matching-works)
- [Cucumber Expressions vs Regular Expressions](#cucumber-expressions-vs-regular-expressions)
- [Basic Steps](#basic-steps)
- [Parameters](#parameters)
- [Data Tables](#data-tables)
- [Doc Strings](#doc-strings)
- [Sharing State](#sharing-state)
- [Custom Parameter Types](#custom-parameter-types)
- [File Organization](#file-organization)
- [Tips and Patterns](#tips-and-patterns)

## How Matching Works

1. Cucumber reads a Gherkin step (e.g., `Given I have 48 cukes`)
2. Searches registered step definitions for a matching expression
3. Extracts capture groups / parameters
4. Executes the matched block with extracted values

**Important:** Keywords (`Given`, `When`, `Then`) are ignored during matching. These steps would conflict:
```gherkin
Given there is money in my account
Then there is money in my account  # Same text = duplicate!
```

## Cucumber Expressions vs Regular Expressions

### Cucumber Expressions (Preferred)

Human-readable, type-safe parameter matching:

```
I have {int} cukes in my belly
I have {float} dollars
I am logged in as {string}
the user {word} is active
```

**Built-in parameter types:**

| Type | Matches | Example |
|------|---------|---------|
| `{int}` | Integers | `42`, `-17` |
| `{float}` | Decimals | `3.14`, `-0.5` |
| `{word}` | Single word (no whitespace) | `admin` |
| `{string}` | Quoted string | `"hello"` or `'hello'` |
| `{}` | Anonymous (any text) | Anything |
| `{bigdecimal}` | Arbitrary precision | `123.456789` |
| `{biginteger}` | Large integers | `999999999999` |

**Optional text:** Parentheses make text optional
```
I have {int} cucumber(s)  # matches "cucumber" or "cucumbers"
```

**Alternative text:** Slash for alternatives
```
I am on the home/login/dashboard page
his/her/their account
```

### Regular Expressions

Use when Cucumber Expressions are insufficient:

```ruby
Given(/^I have (\d+) cukes? in my belly$/) do |count|
  # ...
end
```

## Basic Steps

```ruby
Given('I am on the home page') do
  visit root_path
end

When('I click {string}') do |text|
  click_on text
end

Then('I should see {string}') do |text|
  expect(page).to have_content(text)
end
```

## Parameters

```ruby
Given('there are {int} products') do |count|
  count.times { create(:product) }
end

When('I transfer {float} dollars') do |amount|
  @account.transfer(amount)
end

Then('the user {string} should be {word}') do |name, status|
  expect(User.find_by(name: name).status).to eq(status)
end
```

## Data Tables

```ruby
# Simple list (single column)
Given('the following tags:') do |table|
  tags = table.raw.flatten  # ["ruby", "cucumber", "testing"]
  tags.each { |tag| Tag.create!(name: tag) }
end

# Key-value pairs (two columns)
Given('a user with:') do |table|
  attributes = table.rows_hash  # {"name"=>"Alice", "email"=>"a@test.com"}
  User.create!(attributes)
end

# Table with headers
Given('the following products:') do |table|
  table.hashes.each do |row|
    # row = {"name"=>"Widget", "price"=>"9.99", "stock"=>"50"}
    Product.create!(row)
  end
end

# Symbolic keys
Given('products exist:') do |table|
  table.symbolic_hashes.each do |row|
    # row = {name: "Widget", price: "9.99"}
    Product.create!(row)
  end
end
```

## Doc Strings

```ruby
Given('a blog post with content:') do |content|
  @post = Post.create!(body: content)
end

Given('a JSON payload:') do |json|
  @payload = JSON.parse(json)
end
```

## Sharing State

```ruby
# Instance variables
Given('I have a user') do
  @user = create(:user)
end

When('the user logs in') do
  login_as(@user)
end

# World module (preferred for reusable helpers)
module MyWorld
  attr_accessor :current_user

  def login_as(user)
    @current_user = user
    visit login_path
    fill_in 'email', with: user.email
    click_button 'Login'
  end
end

World(MyWorld)

Given('I am logged in as {string}') do |email|
  self.current_user = User.find_by(email: email)
  login_as(current_user)
end
```

## Custom Parameter Types

```ruby
ParameterType(
  name: 'color',
  regexp: /red|green|blue/,
  transformer: -> (s) { s.to_sym }
)

Given('I select the {color} option') do |color|
  # color is a Symbol: :red, :green, or :blue
end

ParameterType(
  name: 'user_role',
  regexp: /admin|editor|viewer/,
  transformer: -> (s) { s }
)

Given('I am logged in as a {user_role}') do |role|
  @user = create(:user, role: role)
  login_as(@user)
end
```

## File Organization

```
features/
├── support/
│   ├── env.rb           # Environment setup, requires
│   ├── hooks.rb         # Before/After hooks
│   └── world.rb         # World modules
├── step_definitions/
│   ├── user_steps.rb
│   ├── product_steps.rb
│   └── common_steps.rb
├── authentication.feature
├── shopping_cart.feature
└── checkout.feature
```

## Tips and Patterns

### Reusable Steps

Write steps that compose well:
```gherkin
Given I am logged in as "admin"      # reusable
And I am on the products page        # reusable
When I create a product named "Test" # specific
Then I should see "Product created"  # reusable
```

### Avoid UI Coupling

```ruby
# Bad: Tightly coupled to HTML
When('I submit the login form') do
  find('form#login button[type="submit"]').click
end

# Good: Uses helper
When('I submit the login form') do
  login_page.submit
end

# Best: Domain-focused
When('I log in') do
  log_in_as(@current_user)
end
```

### Pending Steps

```ruby
Given('something not implemented yet') do
  pending 'Waiting for API endpoint'
end
```
