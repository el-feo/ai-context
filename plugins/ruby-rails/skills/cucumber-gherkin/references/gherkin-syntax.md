# Gherkin Syntax Reference

Complete reference for Gherkin language syntax used in Cucumber feature files.

## Document Structure

Every `.feature` file must begin with a `Feature` keyword. The structure is:

```gherkin
# language: en (optional, defaults to English)
@feature-tag
Feature: Feature name
  Optional description that can span
  multiple lines.
  
  Background:
    Given shared setup steps
  
  Rule: Business rule description
    Background:
      Given rule-specific setup
    
    Scenario: Example name
      Given precondition
      When action
      Then outcome
```

## Keywords Reference

### Feature

The root keyword. One per file. Provides high-level description and groups scenarios.

```gherkin
Feature: User Registration
  As a visitor
  I want to create an account
  So that I can access member features
  
  Scenario: Successful registration
    ...
```

Free-form text after `Feature:` is ignored by Cucumber but included in reports.

### Rule (Gherkin 6+)

Groups scenarios under a business rule. Supports tag inheritance.

```gherkin
Feature: Highlander
  
  Rule: There can be only One
    
    Example: Only One -- More than one alive
      Given there are 3 ninjas
      When 2 ninjas meet, they will fight
      Then one ninja dies
    
    Example: Only One -- One alive
      Given there is only 1 ninja alive
      Then they will live forever
  
  Rule: There can be Two (in some cases)
    
    Example: Two -- Phoenix resurrection
      ...
```

### Scenario / Example

Concrete example illustrating expected behavior. `Example` and `Scenario` are synonyms.

```gherkin
Scenario: Add item to cart
  Given I am viewing a product
  When I click "Add to Cart"
  Then my cart should contain 1 item
```

Best practice: 3-5 steps per scenario. More indicates the scenario may be testing multiple behaviors.

### Background

Shared setup steps run before each scenario in the feature (or rule).

```gherkin
Feature: Blog management
  
  Background:
    Given I am logged in as "editor"
    And I am on the blog admin page
  
  Scenario: Create post
    When I create a new post
    Then ...
  
  Scenario: Delete post
    When I delete an existing post
    Then ...
```

Background runs after `Before` hooks but before scenario steps.

**Best practices:**
- Keep to 4 lines or fewer
- Use only for essential context visible to readers
- Don't use for technical setup (put in hooks instead)
- Make it vivid with meaningful names

### Scenario Outline / Scenario Template

Run same scenario with different data combinations. Uses `< >` placeholders.

```gherkin
Scenario Outline: Eating cucumbers
  Given there are <start> cucumbers
  When I eat <eat> cucumbers
  Then I should have <left> cucumbers
  
  Examples: Normal appetite
    | start | eat | left |
    |    12 |   5 |    7 |
    |    20 |   5 |   15 |
  
  Examples: Big appetite
    | start | eat | left |
    |    50 |  20 |   30 |
```

Parameters can appear in step text, doc strings, and data tables.

### Examples / Scenarios

Data table for Scenario Outline. Each row generates one scenario execution.

```gherkin
Scenario Outline: Login validation
  When I login with "<email>" and "<password>"
  Then I should see "<message>"
  
  @valid
  Examples: Valid credentials
    | email           | password | message         |
    | user@test.com   | secret   | Welcome back    |
  
  @invalid
  Examples: Invalid credentials
    | email           | password | message         |
    | user@test.com   | wrong    | Invalid login   |
    | bad@format      | any      | Invalid email   |
```

Tags on Examples apply only to scenarios generated from that table.

## Step Keywords

### Given

Describes initial context. Use past tense. Sets up the system state.

```gherkin
Given I am logged in as "admin"
Given the following products exist:
  | name   | price |
  | Widget | 9.99  |
Given today is "2024-01-15"
```

### When

Describes the action or event being tested. Use present tense.

```gherkin
When I click "Submit"
When I search for "cucumber"
When the system processes the batch job
When 24 hours pass
```

**Tip:** Imagine it's 1922 - describe what happens, not which buttons are clicked.

### Then

Describes expected outcome. Should use assertions.

```gherkin
Then I should see "Success"
Then the order status should be "confirmed"
Then my cart should contain 3 items
Then an email should be sent to "user@test.com"
```

Outcomes should be **observable** - something the user can see, not internal state.

### And / But

Continue the previous step type for readability.

```gherkin
Given I am logged in
  And I have items in my cart
  And my shipping address is set

When I proceed to checkout
  And I select "Express Shipping"

Then I should see the order summary
  And the total should include shipping
  But I should not see any errors
```

### * (Asterisk)

Generic step marker. Useful for bullet-point lists.

```gherkin
Scenario: Shopping list
  Given I am out shopping
  * I have eggs
  * I have milk
  * I have butter
  When I check my list
  Then I don't need anything
```

## Step Arguments

### Data Tables

Pass tabular data to step definitions.

```gherkin
# Simple list (single column)
Given the following users:
  | alice   |
  | bob     |
  | charlie |

# Key-value pairs (two columns)
Given a user with attributes:
  | name  | Alice           |
  | email | alice@test.com  |
  | role  | admin           |

# Records (header row + data rows)
Given these products exist:
  | name   | price | stock |
  | Widget | 9.99  |    50 |
  | Gadget | 19.99 |    25 |
```

**Escaping in tables:**
- `\n` - newline
- `\|` - literal pipe
- `\\` - literal backslash

### Doc Strings

Multi-line text blocks using triple quotes.

```gherkin
Given a blog post with Markdown body:
  """
  # Welcome
  
  This is my **first** post.
  """

Given a JSON request body:
  """json
  {
    "name": "Test",
    "active": true
  }
  """
```

Content type annotation (e.g., `"""json`) is optional but helpful for syntax highlighting.

Indentation: Opening `"""` sets the baseline. Content is dedented accordingly.

## Tags

Labels for organizing and filtering features/scenarios.

```gherkin
@billing @important
Feature: Invoice generation
  
  @smoke
  Scenario: Generate invoice
    ...
  
  @slow @nightly
  Scenario: Generate annual report
    ...
```

### Tag Placement

Tags can be placed above:
- `Feature`
- `Rule`
- `Scenario` / `Example`
- `Scenario Outline`
- `Examples`

**Cannot** tag: `Background`, individual steps

### Tag Inheritance

Child elements inherit parent tags:
- Scenarios inherit Feature tags
- Scenarios in Rules inherit both Rule and Feature tags
- Examples inherit Scenario Outline tags

```gherkin
@feature-tag
Feature: Example
  
  @rule-tag
  Rule: Business rule
    
    @scenario-tag
    Scenario: Test
      # Has: @feature-tag, @rule-tag, @scenario-tag
```

### Tag Expressions

Boolean expressions for filtering:

| Expression | Matches |
|------------|---------|
| `@smoke` | Tagged with @smoke |
| `@smoke and @fast` | Tagged with both |
| `@smoke or @critical` | Tagged with either |
| `not @wip` | Not tagged with @wip |
| `@smoke and not @slow` | @smoke but not @slow |
| `(@smoke or @critical) and not @wip` | Complex combination |

## Comments

Single-line comments start with `#`.

```gherkin
Feature: User login
  # This feature covers authentication flows
  
  Scenario: Valid login
    # TODO: Add two-factor auth step
    Given I am on the login page
```

Block comments are not supported.

## Spoken Languages

Gherkin supports 70+ languages. Specify with `# language:` directive.

```gherkin
# language: fr
Fonctionnalité: Connexion utilisateur
  
  Scénario: Connexion réussie
    Etant donné je suis sur la page de connexion
    Quand je saisis mes identifiants
    Alors je vois mon tableau de bord
```

```gherkin
# language: no
Funksjonalitet: Gjett et ord
  
  Eksempel: Ordmaker starter et spill
    Når Ordmaker starter et spill
    Så må Ordmaker vente på at Gjetter blir med
```

If omitted, defaults to English (`en`). Can also be set in Cucumber configuration.
