# Best Practices and Anti-Patterns

Guidelines for writing effective, maintainable Cucumber tests following BDD principles.

## Core Principles

### 1. Describe Behavior, Not Implementation

Scenarios should describe **what** the system does, not **how** it does it.

**Good:**
```gherkin
When Bob logs in with valid credentials
Then he sees his personalized dashboard
```

**Bad:**
```gherkin
When I enter "bob@test.com" in the email field
And I enter "password123" in the password field
And I click the login button
Then I am redirected to "/dashboard"
And I see "Welcome, Bob" in the header
```

**Why it matters:**
- UI changes shouldn't break behavior specs
- Stakeholders can understand and verify scenarios
- Step definitions encapsulate implementation details

### 2. Use Declarative Style Over Imperative

**Declarative** focuses on outcomes and intent. **Imperative** focuses on mechanics.

**Declarative (preferred):**
```gherkin
Given Free Frieda has a free subscription
When she logs in with valid credentials
Then she sees only free articles
```

**Imperative (avoid):**
```gherkin
Given users with a free subscription can access "FreeArticle1" but not "PaidArticle1"
When I type "freeFrieda@example.com" in the email field
And I type "validPassword123" in the password field
And I press the "Submit" button
Then I see "FreeArticle1" on the home page
And I do not see "PaidArticle1" on the home page
```

### 3. One Behavior Per Scenario

Each scenario should test exactly one behavior or rule.

**Good:**
```gherkin
Scenario: Free user cannot access premium content
  Given I am logged in as a free user
  When I try to access a premium article
  Then I see an upgrade prompt

Scenario: Premium user can access all content
  Given I am logged in as a premium user
  When I access a premium article
  Then I see the article content
```

**Bad:**
```gherkin
Scenario: User access levels
  Given I am logged in as a free user
  When I try to access a premium article
  Then I see an upgrade prompt
  When I upgrade to premium
  Then I can access the article
  And I see the download button
  And my billing shows the charge
```

### 4. Write from the User's Perspective

Use first-person ("I") or role-based language, not system-centric language.

**Good:**
```gherkin
Given I am on the checkout page
When I apply coupon code "SAVE20"
Then my total is reduced by 20%
```

**Bad:**
```gherkin
Given the checkout controller receives GET /checkout
When a POST request with coupon=SAVE20 is sent
Then the response contains updated_total with 20% reduction
```

## Scenario Structure

### Keep Scenarios Short

**Target:** 3-5 steps per scenario

```gherkin
# Good: Focused and readable
Scenario: Add item to cart
  Given I am viewing a product
  When I add it to my cart
  Then my cart contains 1 item

# Bad: Too long and testing multiple things
Scenario: Shopping flow
  Given I am on the home page
  When I search for "laptop"
  And I click on the first result
  And I select "16GB RAM" variant
  And I click "Add to Cart"
  Then I see a confirmation
  When I go to cart
  Then I see the laptop
  When I proceed to checkout
  And I enter shipping address
  And I enter payment info
  And I click submit
  Then I see order confirmation
```

### Use Background Wisely

**Do:**
- Keep backgrounds to 4 lines or fewer
- Use for essential shared context
- Make names vivid and memorable

**Don't:**
- Hide important setup (readers should understand scenarios)
- Use for technical setup (use hooks instead)
- Duplicate steps that only some scenarios need

```gherkin
# Good: Vivid, essential context
Background:
  Given a global administrator named "Greg"
  And a blog named "Greg's Soapbox"
  And a customer named "Dr. Bill"

# Bad: Technical and too long
Background:
  Given the database has been seeded
  And the cache has been cleared
  And the test user exists with email "test@test.com"
  And the session timeout is set to 30 minutes
  And the feature flag "new_checkout" is enabled
```

### Use Scenario Outlines for Data Variations

```gherkin
# Good: Single scenario outline for variations
Scenario Outline: Password validation
  When I enter password "<password>"
  Then I should see "<message>"
  
  Examples:
    | password    | message                    |
    | short       | Password too short         |
    | nouppercase | Must contain uppercase     |
    | ValidPass1  | Password accepted          |

# Bad: Repetitive scenarios
Scenario: Short password rejected
  When I enter password "short"
  Then I should see "Password too short"

Scenario: No uppercase rejected
  When I enter password "nouppercase"
  Then I should see "Must contain uppercase"
```

## Step Definition Guidelines

### Single Responsibility

Each step should do one thing.

```ruby
# Good: Single responsibility
Given('I have {int} products in stock') do |count|
  count.times { create(:product, in_stock: true) }
end

When('I purchase a product') do
  @purchase = Purchase.create(product: Product.first)
end

Then('stock is reduced by {int}') do |count|
  expect(Product.first.stock).to eq(initial_stock - count)
end

# Bad: Step does too much
When('I purchase a product and stock is updated') do
  initial = Product.first.stock
  Purchase.create(product: Product.first)
  expect(Product.first.stock).to eq(initial - 1)
end
```

### Reusable Steps

Write steps that compose well across scenarios.

```gherkin
# Reusable building blocks
Given I am logged in as "admin"
Given I am logged in as "customer"
Given I am on the home page
Given I am on the products page
When I click "Submit"
Then I should see "Success"
Then I should not see "Error"
```

### Avoid Tight Coupling to UI

```ruby
# Bad: Tightly coupled to HTML structure
When('I submit the login form') do
  find('form#login button[type="submit"]').click
end

# Good: Uses page object or helper
When('I submit the login form') do
  login_page.submit
end

# Even better: Domain-focused
When('I log in') do
  log_in_as(@current_user)
end
```

## Anti-Patterns to Avoid

### 1. Scenario as Test Script

❌ Testing implementation, not behavior:
```gherkin
Scenario: Login
  Given I navigate to "/login"
  When I fill "#email" with "user@test.com"
  And I fill "#password" with "secret"
  And I click "#submit-btn"
  Then "#welcome-msg" should contain "Hello"
```

✅ Testing behavior:
```gherkin
Scenario: Successful login
  Given I am a registered user
  When I log in with valid credentials
  Then I see my personalized greeting
```

### 2. Incidental Details

❌ Irrelevant specifics:
```gherkin
Scenario: Place order
  Given user "John Smith" with email "john.smith@example.com"
  And user is at "123 Main Street, Anytown, ST 12345"
  And user has credit card "4111111111111111" expiring "12/25"
  When user orders product SKU "WIDGET-001" priced at $19.99
  Then order #ORD-2024-00001 is created
```

✅ Essential details only:
```gherkin
Scenario: Place order
  Given John is a registered customer
  And he has a saved payment method
  When he orders a widget
  Then his order is confirmed
```

### 3. Feature File as Test Suite

❌ One feature, many unrelated scenarios:
```gherkin
Feature: User
  Scenario: User can log in
  Scenario: User can update profile
  Scenario: User can view order history
  Scenario: User can change password
  Scenario: User can delete account
```

✅ Focused features:
```gherkin
Feature: User Authentication
  Scenario: Successful login
  Scenario: Login with invalid password
  Scenario: Password reset

Feature: User Profile Management
  Scenario: Update display name
  Scenario: Update email address
```

### 4. Cucumber as Integration Test Framework

❌ Testing internal APIs directly:
```gherkin
Scenario: API returns 200
  When I send GET request to "/api/users/1"
  Then response status is 200
  And response body contains "id": 1
```

✅ Testing user-facing behavior (API tests have their place, but consider if Cucumber is the right tool):
```gherkin
Scenario: View user profile
  Given I am viewing my profile
  Then I see my name and email
```

### 5. Logic in Feature Files

❌ Conditional logic:
```gherkin
Scenario: Login
  Given I am on the login page
  When I enter credentials
  Then if credentials are valid I see dashboard
  But if credentials are invalid I see error
```

✅ Separate scenarios:
```gherkin
Scenario: Successful login
  Given I am on the login page
  When I enter valid credentials
  Then I see my dashboard

Scenario: Failed login
  Given I am on the login page
  When I enter invalid credentials
  Then I see an error message
```

## Naming Conventions

### Feature Names

Use noun phrases describing the capability:
- `User Authentication`
- `Shopping Cart`
- `Order Management`
- `Email Notifications`

### Scenario Names

Use descriptive phrases that explain the behavior:
- `Successful login with valid credentials`
- `Add single item to empty cart`
- `Password reset email sent within 5 minutes`

Avoid:
- `Test login` (too vague)
- `TC-001: Login` (test case IDs belong in tags)
- `Should work` (meaningless)

### Tag Conventions

```gherkin
# Categories
@smoke @regression @e2e

# Priority
@critical @high @low

# Status
@wip @pending @manual

# Technical
@slow @database @browser @api

# External references
@JIRA-123 @story-456
```

## Collaboration Patterns

### Three Amigos

Before writing scenarios:
1. **Product Owner:** Explains the feature and acceptance criteria
2. **Developer:** Identifies technical considerations
3. **Tester:** Asks about edge cases and test scenarios

### Example Mapping

Use colored cards to organize discussions:
- **Yellow (Story):** The feature or user story
- **Blue (Rules):** Business rules
- **Green (Examples):** Concrete scenarios
- **Red (Questions):** Uncertainties to resolve

### Living Documentation

Treat feature files as documentation:
- Keep them up to date with the system
- Use meaningful descriptions
- Include enough context for new team members
- Review and refactor regularly

## Performance Considerations

### Fast Feedback

```ruby
# Use faster alternatives when possible
Before do
  # Fast: Create test data directly
  @user = create(:user)
  
  # Slow: Go through UI to create user
  visit new_user_path
  fill_in 'Email', with: 'test@test.com'
  click_button 'Create'
end
```

### Tag-Based Execution

```bash
# Run only smoke tests for quick feedback
cucumber --tags @smoke

# Skip slow tests during development
cucumber --tags "not @slow"

# Run database tests in isolation
cucumber --tags @database
```

### Parallel Execution

```bash
# Ruby with parallel_tests
bundle exec parallel_cucumber features/

# JavaScript
npx cucumber-js --parallel 4

# Java with Maven
mvn test -T 4  # 4 threads
```

## Refactoring Scenarios

### When to Refactor

- Scenarios are too long (>7 steps)
- Multiple scenarios have duplicated steps
- Scenarios test implementation, not behavior
- Hard to understand without reading step definitions
- Feature files don't match current system behavior

### Safe Refactoring Process

1. Ensure all scenarios pass
2. Make small, incremental changes
3. Run tests after each change
4. Update step definitions to match new wording
5. Review with team for clarity
