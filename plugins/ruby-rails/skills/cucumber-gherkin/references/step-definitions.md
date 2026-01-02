# Step Definitions Reference

Step definitions connect Gherkin steps to executable code. This reference covers patterns for Ruby, JavaScript, Java, Kotlin, Scala, and Python.

## How Matching Works

1. Cucumber reads a Gherkin step (e.g., `Given I have 48 cukes`)
2. Searches registered step definitions for a matching expression
3. Extracts capture groups / parameters
4. Executes the matched method with extracted values

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
I wait {int} second(s)
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

## Ruby Step Definitions

### Basic Steps

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

### With Parameters

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

### Data Tables

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

### Doc Strings

```ruby
Given('a blog post with content:') do |content|
  # content is the full doc string text
  @post = Post.create!(body: content)
end

Given('a JSON payload:') do |json|
  @payload = JSON.parse(json)
end
```

### Sharing State

```ruby
# Use instance variables
Given('I have a user') do
  @user = create(:user)
end

When('the user logs in') do
  login_as(@user)
end

# Or use a World module
module MyWorld
  def current_user
    @current_user ||= create(:user)
  end
end

World(MyWorld)

Given('I am logged in') do
  login_as(current_user)
end
```

## JavaScript Step Definitions

### Basic Steps

```javascript
const { Given, When, Then } = require('@cucumber/cucumber');
const { expect } = require('chai');

Given('I am on the home page', async function() {
  await this.page.goto('/');
});

When('I click {string}', async function(text) {
  await this.page.click(`text=${text}`);
});

Then('I should see {string}', async function(text) {
  const content = await this.page.textContent('body');
  expect(content).to.include(text);
});
```

**Important:** Avoid arrow functions - they bind `this` incorrectly.

### With Parameters

```javascript
Given('there are {int} products', async function(count) {
  for (let i = 0; i < count; i++) {
    await this.createProduct();
  }
});

When('I transfer {float} dollars', async function(amount) {
  await this.account.transfer(amount);
});
```

### Data Tables

```javascript
Given('the following users:', async function(dataTable) {
  // As array of hashes
  const users = dataTable.hashes();
  // [{ name: 'Alice', email: 'alice@test.com' }, ...]
  
  for (const user of users) {
    await User.create(user);
  }
});

Given('a user with:', async function(dataTable) {
  // Two-column table as object
  const attrs = dataTable.rowsHash();
  // { name: 'Alice', email: 'alice@test.com' }
  
  await User.create(attrs);
});

Given('the following tags:', async function(dataTable) {
  // Single column as flat array
  const tags = dataTable.raw().flat();
  // ['ruby', 'cucumber', 'testing']
});
```

### Doc Strings

```javascript
Given('a JSON payload:', async function(docString) {
  this.payload = JSON.parse(docString);
});

Given('an email with body:', async function(body) {
  this.email = { body };
});
```

### Async/Await and Promises

```javascript
// Async/await (preferred)
When('I wait for the page to load', async function() {
  await this.page.waitForLoadState('networkidle');
});

// Promise
Then('the API returns success', function() {
  return this.api.getStatus().then(status => {
    expect(status).to.equal('ok');
  });
});

// Callback (legacy)
Given('I wait {int} seconds', function(seconds, callback) {
  setTimeout(callback, seconds * 1000);
});
```

### World Context

```javascript
// features/support/world.js
const { setWorldConstructor } = require('@cucumber/cucumber');

class CustomWorld {
  constructor() {
    this.users = [];
  }
  
  async createUser(attrs) {
    const user = await User.create(attrs);
    this.users.push(user);
    return user;
  }
}

setWorldConstructor(CustomWorld);

// In step definitions
Given('a user exists', async function() {
  this.currentUser = await this.createUser({ name: 'Test' });
});
```

## Java Step Definitions

### Basic Steps

```java
package com.example.steps;

import io.cucumber.java.en.*;
import static org.junit.jupiter.api.Assertions.*;

public class StepDefinitions {
    
    @Given("I am on the home page")
    public void iAmOnTheHomePage() {
        driver.get(baseUrl);
    }
    
    @When("I click {string}")
    public void iClick(String text) {
        driver.findElement(By.linkText(text)).click();
    }
    
    @Then("I should see {string}")
    public void iShouldSee(String text) {
        assertTrue(driver.getPageSource().contains(text));
    }
}
```

### Lambda Style (Java 8+)

```java
import io.cucumber.java8.En;

public class LambdaSteps implements En {
    
    public LambdaSteps() {
        Given("I am on the home page", () -> {
            driver.get(baseUrl);
        });
        
        When("I click {string}", (String text) -> {
            driver.findElement(By.linkText(text)).click();
        });
        
        Then("I should see {string}", (String text) -> {
            assertTrue(driver.getPageSource().contains(text));
        });
    }
}
```

### Data Tables

```java
@Given("the following users:")
public void theFollowingUsers(DataTable dataTable) {
    // As list of maps
    List<Map<String, String>> users = dataTable.asMaps();
    
    // As list of lists
    List<List<String>> rows = dataTable.asLists();
    
    // With custom type conversion
    List<User> users = dataTable.asList(User.class);
}

@Given("a user with:")
public void aUserWith(DataTable dataTable) {
    Map<String, String> attrs = dataTable.asMap();
    // {name=Alice, email=alice@test.com}
}
```

### Doc Strings

```java
@Given("a JSON payload:")
public void aJsonPayload(String docString) {
    this.payload = new ObjectMapper().readValue(docString, Map.class);
}
```

### Dependency Injection

```java
// With PicoContainer
public class StepDefinitions {
    private final SharedState state;
    
    public StepDefinitions(SharedState state) {
        this.state = state;
    }
    
    @Given("I have a user")
    public void iHaveAUser() {
        state.setCurrentUser(new User("Test"));
    }
}

// With Spring
@CucumberContextConfiguration
@SpringBootTest
public class SpringStepDefinitions {
    @Autowired
    private UserService userService;
    
    @Given("I have a user")
    public void iHaveAUser() {
        userService.createUser("Test");
    }
}
```

## Kotlin Step Definitions

```kotlin
import io.cucumber.java8.En

class StepDefinitions : En {
    
    init {
        Given("I have {int} cukes") { count: Int ->
            belly.eat(count)
        }
        
        When("I wait {int} hours") { hours: Int ->
            belly.wait(hours)
        }
        
        Then("my belly should growl") {
            assertTrue(belly.isGrowling)
        }
    }
}
```

**Note:** `@BeforeAll`/`@AfterAll` in companion objects causes issues. Use package-level functions:

```kotlin
package com.example

import io.cucumber.java.BeforeAll
import io.cucumber.java.AfterAll

@BeforeAll
fun beforeAll() {
    println("Setup")
}

@AfterAll
fun afterAll() {
    println("Teardown")
}
```

## Python Step Definitions (Behave)

```python
from behave import given, when, then

@given('I am on the home page')
def step_on_home_page(context):
    context.browser.get(context.base_url)

@when('I click "{text}"')
def step_click(context, text):
    context.browser.find_element_by_link_text(text).click()

@then('I should see "{text}"')
def step_should_see(context, text):
    assert text in context.browser.page_source

# With data table
@given('the following users')
def step_users(context):
    for row in context.table:
        User.create(name=row['name'], email=row['email'])

# With doc string
@given('a JSON payload')
def step_json_payload(context):
    context.payload = json.loads(context.text)
```

## Custom Parameter Types

### Ruby

```ruby
ParameterType(
  name: 'color',
  regexp: /red|green|blue/,
  transformer: -> (s) { s.to_sym }
)

Given('I select the {color} option') do |color|
  # color is a Symbol: :red, :green, or :blue
end
```

### JavaScript

```javascript
const { defineParameterType } = require('@cucumber/cucumber');

defineParameterType({
  name: 'color',
  regexp: /red|green|blue/,
  transformer: s => s.toUpperCase()
});

Given('I select the {color} option', function(color) {
  // color is "RED", "GREEN", or "BLUE"
});
```

### Java

```java
@ParameterType("red|green|blue")
public Color color(String color) {
    return Color.valueOf(color.toUpperCase());
}

@Given("I select the {color} option")
public void selectColor(Color color) {
    // color is Color enum
}
```

## Step Definition Organization

### Ruby (features/step_definitions/)

```
features/
├── step_definitions/
│   ├── user_steps.rb
│   ├── product_steps.rb
│   └── common_steps.rb
└── support/
    ├── env.rb
    └── hooks.rb
```

### JavaScript (features/step_definitions/)

```
features/
├── step_definitions/
│   ├── user.steps.js
│   ├── product.steps.js
│   └── common.steps.js
└── support/
    ├── world.js
    └── hooks.js
```

### Java (src/test/java/)

```
src/test/java/com/example/
├── steps/
│   ├── UserSteps.java
│   └── ProductSteps.java
├── support/
│   ├── Hooks.java
│   └── SharedState.java
└── RunCucumberTest.java
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

### Avoid Coupling to UI

Bad:
```ruby
When('I click the submit button') do
  find('button[type="submit"]').click
end
```

Good:
```ruby
When('I submit the form') do
  submit_current_form  # helper that can change implementation
end
```

### Handle Pending Steps

```ruby
Given('something not implemented yet') do
  pending 'Waiting for API endpoint'
end
```

```javascript
Given('something not implemented yet', function() {
  return 'pending';
});
```
