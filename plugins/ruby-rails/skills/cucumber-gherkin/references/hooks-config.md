# Hooks and Configuration Reference

Hooks are blocks of code that run at specific points in the Cucumber execution cycle. This reference covers hooks, configuration, and test runners.

## Hooks Overview

| Hook | Scope | Runs |
|------|-------|------|
| `BeforeAll` | Global | Once before any scenario |
| `AfterAll` | Global | Once after all scenarios |
| `Before` | Scenario | Before each scenario |
| `After` | Scenario | After each scenario |
| `BeforeStep` | Step | Before each step |
| `AfterStep` | Step | After each step |
| `Around` | Scenario | Wraps scenario (Ruby only) |

## Scenario Hooks

### Before Hook

Runs before the first step of each scenario.

**Ruby:**
```ruby
Before do |scenario|
  @browser = Browser.new
end

# With tag filter
Before('@browser') do
  start_browser
end

# With explicit order (lower runs first)
Before(order: 10) do
  setup_database
end

Before(order: 20) do
  seed_data
end
```

**JavaScript:**
```javascript
const { Before } = require('@cucumber/cucumber');

Before(async function(scenario) {
  this.browser = await launchBrowser();
});

// With tag filter
Before({ tags: '@browser' }, async function() {
  await this.startBrowser();
});

// With order
Before({ order: 10 }, async function() {
  await this.setupDatabase();
});
```

**Java:**
```java
@Before
public void beforeScenario(Scenario scenario) {
    browser = new Browser();
}

@Before("@browser")
public void beforeBrowserScenario() {
    startBrowser();
}

@Before(order = 10)
public void setupDatabase() {
    // runs first
}
```

### After Hook

Runs after the last step of each scenario, regardless of outcome.

**Ruby:**
```ruby
After do |scenario|
  if scenario.failed?
    save_screenshot("failure_#{scenario.name}.png")
  end
  @browser.quit
end

After('@database') do
  DatabaseCleaner.clean
end
```

**JavaScript:**
```javascript
const { After, Status } = require('@cucumber/cucumber');

After(async function(scenario) {
  if (scenario.result.status === Status.FAILED) {
    const screenshot = await this.page.screenshot();
    this.attach(screenshot, 'image/png');
  }
  await this.browser.close();
});

After({ tags: '@database' }, async function() {
  await this.cleanDatabase();
});
```

**Java:**
```java
@After
public void afterScenario(Scenario scenario) {
    if (scenario.isFailed()) {
        byte[] screenshot = driver.getScreenshotAs(OutputType.BYTES);
        scenario.attach(screenshot, "image/png", "failure");
    }
    driver.quit();
}
```

### Around Hook (Ruby Only)

Wraps scenario execution. Useful for timeout control.

```ruby
Around('@fast') do |scenario, block|
  Timeout.timeout(0.5) do
    block.call
  end
end

Around do |scenario, block|
  start_time = Time.now
  block.call
  puts "Scenario took #{Time.now - start_time}s"
end
```

## Step Hooks

Run before/after each step. Useful for debugging.

**Ruby:**
```ruby
# AfterStep only in Ruby
AfterStep do |scenario|
  puts "Just finished a step"
end
```

**JavaScript:**
```javascript
const { BeforeStep, AfterStep } = require('@cucumber/cucumber');

BeforeStep(async function({ pickle, pickleStep }) {
  console.log(`Starting: ${pickleStep.text}`);
});

AfterStep(async function({ pickle, pickleStep, result }) {
  console.log(`Finished: ${pickleStep.text} - ${result.status}`);
});

// With tag filter
BeforeStep({ tags: '@debug' }, async function() {
  await this.logState();
});
```

**Java:**
```java
@BeforeStep
public void beforeStep(Scenario scenario) {
    // runs before each step
}

@AfterStep
public void afterStep(Scenario scenario) {
    // runs after each step
}
```

## Global Hooks

Run once for entire test suite.

**Ruby:**
```ruby
# In features/support/env.rb
BeforeAll do
  DatabaseCleaner.strategy = :truncation
  start_server
end

AfterAll do
  stop_server
end
```

**JavaScript:**
```javascript
const { BeforeAll, AfterAll } = require('@cucumber/cucumber');

BeforeAll(async function() {
  await startDatabase();
});

AfterAll(async function() {
  await stopDatabase();
});
```

**Java:**
```java
public class Hooks {
    @BeforeAll
    public static void beforeAll() {
        // must be static
        startServer();
    }
    
    @AfterAll
    public static void afterAll() {
        stopServer();
    }
}
```

## Conditional Hooks

Use tag expressions to run hooks selectively.

```ruby
Before('@browser and not @headless') do
  @browser = Browser.new(headless: false)
end

After('@database') do
  DatabaseCleaner.clean
end

Before('@smoke or @critical') do
  setup_monitoring
end
```

```javascript
Before({ tags: '@browser and not @headless' }, async function() {
  this.browser = await launchBrowser({ headless: false });
});

Before({ tags: '@smoke or @critical' }, async function() {
  await this.setupMonitoring();
});
```

## Hook Execution Order

1. `BeforeAll` hooks (once)
2. For each scenario:
   - `Before` hooks (in order of registration, or by `order` param)
   - `Background` steps (if any)
   - Scenario steps (with `BeforeStep`/`AfterStep` around each)
   - `After` hooks (in reverse order of registration)
3. `AfterAll` hooks (once)

## Configuration

### Ruby (cucumber.yml)

```yaml
# config/cucumber.yml
default: --format progress --strict --tags "not @wip"
html_report: --format html --out reports/cucumber.html
ci: --format progress --format junit --out reports/junit.xml --tags "not @wip"
smoke: --tags @smoke
```

Usage:
```bash
cucumber                    # uses default profile
cucumber -p html_report     # uses html_report profile
cucumber -p ci              # uses ci profile
```

### JavaScript (cucumber.js)

```javascript
// cucumber.js
module.exports = {
  default: {
    require: ['features/step_definitions/**/*.js', 'features/support/**/*.js'],
    format: ['progress', 'html:reports/cucumber.html'],
    formatOptions: { snippetInterface: 'async-await' },
    publishQuiet: true
  },
  smoke: {
    require: ['features/step_definitions/**/*.js'],
    tags: '@smoke'
  }
};
```

Usage:
```bash
npx cucumber-js               # uses default
npx cucumber-js -p smoke      # uses smoke profile
```

### Java (cucumber.properties)

```properties
# src/test/resources/cucumber.properties
cucumber.ansi-colors.disabled=false
cucumber.execution.dry-run=false
cucumber.execution.order=lexical
cucumber.filter.tags=not @wip
cucumber.glue=com.example.steps
cucumber.plugin=pretty,html:target/cucumber.html
cucumber.snippet-type=underscore
```

### Java (JUnit 4 Runner)

```java
@RunWith(Cucumber.class)
@CucumberOptions(
    features = "src/test/resources/features",
    glue = {"com.example.steps", "com.example.hooks"},
    plugin = {"pretty", "html:target/cucumber.html", "json:target/cucumber.json"},
    tags = "not @wip",
    monochrome = true,
    dryRun = false
)
public class RunCucumberTest {
}
```

### Java (JUnit 5 Platform)

```java
// src/test/resources/junit-platform.properties
cucumber.glue=com.example.steps
cucumber.plugin=pretty,html:target/cucumber.html
cucumber.filter.tags=not @wip

// Or in pom.xml
<plugin>
    <groupId>org.apache.maven.plugins</groupId>
    <artifactId>maven-surefire-plugin</artifactId>
    <configuration>
        <systemPropertyVariables>
            <cucumber.filter.tags>@smoke</cucumber.filter.tags>
        </systemPropertyVariables>
    </configuration>
</plugin>
```

## Running Cucumber

### Ruby

```bash
# Run all features
bundle exec cucumber

# Run specific feature
cucumber features/login.feature

# Run specific scenario by line
cucumber features/login.feature:10

# Run with tags
cucumber --tags "@smoke and not @wip"

# Dry run (check step definitions without executing)
cucumber --dry-run

# Generate HTML report
cucumber --format html --out report.html

# Parallel execution
bundle exec parallel_cucumber features/
```

### JavaScript

```bash
# Run all features
npx cucumber-js

# Run specific feature
npx cucumber-js features/login.feature

# Run with tags
npx cucumber-js --tags "@smoke and not @wip"

# With specific format
npx cucumber-js --format progress

# Parallel execution (requires cucumber-parallel)
npx cucumber-js --parallel 4
```

### Java (Maven)

```bash
# Run all tests
mvn test

# Run with specific tags
mvn test -Dcucumber.filter.tags="@smoke"

# Run specific feature file
mvn test -Dcucumber.features="src/test/resources/features/login.feature"

# Dry run
mvn test -Dcucumber.execution.dry-run=true

# Generate reports
mvn verify  # runs cucumber and generates reports
```

### Java (Gradle)

```groovy
// build.gradle
test {
    systemProperty 'cucumber.filter.tags', '@smoke'
    systemProperty 'cucumber.plugin', 'pretty,html:build/reports/cucumber.html'
}
```

```bash
gradle test
```

## Reporter Plugins

### Built-in Formatters

| Format | Description |
|--------|-------------|
| `pretty` | Colored console output |
| `progress` | Dots for passed, F for failed |
| `html:path` | HTML report |
| `json:path` | JSON output |
| `junit:path` | JUnit XML format |
| `message:path` | Cucumber Messages (Protobuf) |

### Using Multiple Formatters

```bash
# Ruby
cucumber --format progress --format html --out report.html

# JavaScript
npx cucumber-js --format progress --format html:report.html

# Java
@CucumberOptions(
    plugin = {"progress", "html:target/cucumber.html", "json:target/cucumber.json"}
)
```

## World/Context Pattern

Share state between steps in a scenario.

### Ruby

```ruby
# features/support/world.rb
module CustomWorld
  attr_accessor :current_user
  
  def login_as(user)
    @current_user = user
    visit login_path
    fill_in 'email', with: user.email
    click_button 'Login'
  end
end

World(CustomWorld)

# In step definitions
Given('I am logged in as {string}') do |email|
  self.current_user = User.find_by(email: email)
  login_as(current_user)
end
```

### JavaScript

```javascript
// features/support/world.js
const { setWorldConstructor } = require('@cucumber/cucumber');

class CustomWorld {
  constructor({ attach, log, parameters }) {
    this.attach = attach;
    this.log = log;
    this.parameters = parameters;
    this.currentUser = null;
  }
  
  async loginAs(user) {
    this.currentUser = user;
    await this.page.goto('/login');
    await this.page.fill('#email', user.email);
    await this.page.click('button[type="submit"]');
  }
}

setWorldConstructor(CustomWorld);

// In step definitions
Given('I am logged in as {string}', async function(email) {
  const user = await User.findByEmail(email);
  await this.loginAs(user);
});
```

### Java (Dependency Injection)

```java
// SharedState.java (PicoContainer injects same instance to all step classes)
public class SharedState {
    private User currentUser;
    private WebDriver driver;
    
    public User getCurrentUser() { return currentUser; }
    public void setCurrentUser(User user) { this.currentUser = user; }
    // getters/setters...
}

// UserSteps.java
public class UserSteps {
    private final SharedState state;
    
    public UserSteps(SharedState state) {
        this.state = state;
    }
    
    @Given("I am logged in as {string}")
    public void loginAs(String email) {
        User user = userService.findByEmail(email);
        state.setCurrentUser(user);
        loginPage.loginAs(user);
    }
}
```

## Environment Variables

Access environment-specific configuration.

```ruby
# Ruby
Before do
  @base_url = ENV['BASE_URL'] || 'http://localhost:3000'
end
```

```javascript
// JavaScript
Before(function() {
  this.baseUrl = process.env.BASE_URL || 'http://localhost:3000';
});
```

```java
// Java
@Before
public void setup() {
    baseUrl = System.getenv().getOrDefault("BASE_URL", "http://localhost:3000");
}
```

## Screenshot on Failure

Common pattern for browser tests.

```ruby
# Ruby with Capybara
After do |scenario|
  if scenario.failed?
    page.save_screenshot("tmp/screenshots/#{scenario.name.gsub(/\s+/, '_')}.png")
    embed("tmp/screenshots/#{scenario.name.gsub(/\s+/, '_')}.png", 'image/png')
  end
end
```

```javascript
// JavaScript with Playwright
const { After, Status } = require('@cucumber/cucumber');

After(async function(scenario) {
  if (scenario.result.status === Status.FAILED) {
    const screenshot = await this.page.screenshot();
    await this.attach(screenshot, 'image/png');
  }
});
```

```java
// Java with Selenium
@After
public void takeScreenshotOnFailure(Scenario scenario) {
    if (scenario.isFailed()) {
        byte[] screenshot = ((TakesScreenshot) driver).getScreenshotAs(OutputType.BYTES);
        scenario.attach(screenshot, "image/png", "Screenshot on failure");
    }
}
```
