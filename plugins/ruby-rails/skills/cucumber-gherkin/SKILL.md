---
name: cucumber-gherkin
description: BDD testing with Cucumber and Gherkin for Ruby and Rails applications. Use when writing feature files (.feature), step definitions, hooks, or implementing Behaviour-Driven Development in Ruby/Rails projects. Covers Gherkin keywords (Feature, Scenario, Given/When/Then, Background, Scenario Outline, Rule), Ruby step definition patterns, Cucumber Expressions, hooks (Before/After/BeforeAll/AfterAll), tags, data tables, doc strings, World modules, and Capybara integration. Triggers on cucumber, gherkin, BDD, feature files, step definitions, acceptance testing, executable specifications.
---

# Cucumber & Gherkin

BDD testing framework with plain-text executable specifications and Ruby step definitions.

```
Feature file (.feature) ──> Step Definitions (Ruby) ──> System under test
```

## Gherkin Quick Reference

```gherkin
Feature: Short description
  Optional multi-line description.

  Background:
    Given common setup for all scenarios

  Rule: Business rule grouping (Gherkin 6+)

    Scenario: Concrete example
      Given an initial context
      When an action occurs
      Then expected outcome
      And additional assertion
      But negative assertion

    Scenario Outline: Parameterized
      Given there are <start> items
      When I remove <remove> items
      Then I should have <remaining> items

      Examples:
        | start | remove | remaining |
        |    12 |      5 |         7 |
        |    20 |      5 |        15 |
```

**Step keywords:** `Given` (setup), `When` (action), `Then` (assertion), `And`/`But` (continuation), `*` (bullet)

**Data tables:**
```gherkin
Given the following users exist:
  | name  | email             | role  |
  | Alice | alice@example.com | admin |
```

**Doc strings:**
```gherkin
Given a blog post with content:
  """markdown
  # My Post Title
  Content here.
  """
```

**Tags:** `@smoke @critical` on Feature/Rule/Scenario/Examples. Expressions: `@smoke and not @slow`, `(@smoke or @critical) and not @wip`

## Ruby Step Definitions

```ruby
# Cucumber Expressions (preferred)
Given('I have {int} cucumbers in my belly') do |count|
  @belly = Belly.new
  @belly.eat(count)
end

When('I wait {int} hour(s)') do |hours|
  @belly.wait(hours)
end

Then('my belly should growl') do
  expect(@belly.growling?).to be true
end

# Data table
Given('the following users exist:') do |table|
  table.hashes.each { |row| User.create!(row) }
end

# Doc string
Given('a JSON payload:') do |json|
  @payload = JSON.parse(json)
end
```

**Cucumber Expressions:** `{int}`, `{float}`, `{word}`, `{string}`, `{}` (anonymous). Optional: `cucumber(s)`. Alternatives: `color/colour`.

**State sharing:** Use instance variables (`@user`) or World modules:
```ruby
module MyWorld
  def current_user
    @current_user ||= create(:user)
  end
end
World(MyWorld)
```

## Hooks

```ruby
Before do |scenario|
  @browser = Browser.new
end

After do |scenario|
  save_screenshot("failure.png") if scenario.failed?
end

Before('@database') do
  DatabaseCleaner.start
end

After('@database') do
  DatabaseCleaner.clean
end

BeforeAll do
  # once before any scenario
end

AfterAll do
  # once after all scenarios
end
```

**Order:** `BeforeAll` > (`Before` > Background > Steps > `After`) per scenario > `AfterAll`

## Running

```bash
bundle exec cucumber
cucumber --tags "@smoke and not @wip"
cucumber features/login.feature:10
cucumber --dry-run
cucumber --format html --out report.html
bundle exec parallel_cucumber features/
```

## Best Practices

**Declarative over imperative:**
```gherkin
# Good                          # Avoid
When "Bob" logs in              When I visit "/login"
Then he sees his dashboard      And I enter "bob" in "username"
                                And I click "Login"
```

- Describe *what* the system does, not *how*
- One behavior per scenario, 3-5 steps
- Keep Background short (≤4 lines), essential context only
- Use domain language stakeholders understand

## References

For comprehensive details:

- `references/gherkin-syntax.md` — Complete Gherkin language reference (keywords, data tables, tags, i18n)
- `references/step-definitions.md` — Ruby step definition patterns (data tables, doc strings, custom parameter types, World context, organization)
- `references/hooks-config.md` — Hooks, cucumber.yml configuration, reporters, Capybara integration
- `references/best-practices.md` — Anti-patterns, naming conventions, collaboration patterns, refactoring
