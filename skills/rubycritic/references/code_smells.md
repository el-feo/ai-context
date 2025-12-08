# Common Ruby Code Smells and Fixes

This reference provides guidance on addressing common issues detected by RubyCritic.

## Reek Smells

### Control Parameter
**Issue**: Method behavior changes based on boolean parameter
```ruby
# Bad
def process(data, use_cache)
  use_cache ? cached_process(data) : fresh_process(data)
end

# Good
def process_with_cache(data)
  cached_process(data)
end

def process_without_cache(data)
  fresh_process(data)
end
```

### Feature Envy
**Issue**: Method uses more features of another class than its own
```ruby
# Bad
def total_price
  item.price * item.quantity + item.tax
end

# Good - move method to item class
class Item
  def total_price
    price * quantity + tax
  end
end
```

### Long Parameter List
**Issue**: Method has too many parameters (>3)
```ruby
# Bad
def create_user(name, email, age, address, phone, country)
  # ...
end

# Good
def create_user(user_params)
  name = user_params[:name]
  email = user_params[:email]
  # ...
end
```

### Unused Parameter
**Issue**: Parameter is defined but never used
```ruby
# Bad
def process(data, unused_param)
  data.map(&:upcase)
end

# Good
def process(data)
  data.map(&:upcase)
end
```

### Duplicate Method Call
**Issue**: Same method called multiple times
```ruby
# Bad
def display
  puts user.full_name
  log("Displayed #{user.full_name}")
end

# Good
def display
  name = user.full_name
  puts name
  log("Displayed #{name}")
end
```

## Flog Complexity

### High Method Complexity
**Issue**: Method has too many branches or operations

**Fix strategies:**
- Extract methods for distinct operations
- Replace conditionals with polymorphism
- Use early returns to reduce nesting
- Split into smaller, focused methods

```ruby
# Bad - high complexity
def process_order(order)
  if order.valid?
    if order.paid?
      if order.items.any?
        order.items.each do |item|
          if item.in_stock?
            item.ship
          else
            item.backorder
          end
        end
      end
    end
  end
end

# Good - extracted methods
def process_order(order)
  return unless valid_paid_order?(order)
  process_items(order.items)
end

def valid_paid_order?(order)
  order.valid? && order.paid? && order.items.any?
end

def process_items(items)
  items.each { |item| process_item(item) }
end

def process_item(item)
  item.in_stock? ? item.ship : item.backorder
end
```

## Flay Duplication

### Code Duplication
**Issue**: Similar code blocks appear in multiple places

**Fix strategies:**
- Extract common code to shared methods
- Use modules for shared behavior
- Create service objects for complex operations
- Use inheritance or composition

```ruby
# Bad - duplication
class User
  def send_welcome_email
    Mailer.deliver(
      to: email,
      subject: "Welcome",
      template: "welcome"
    )
  end
end

class Admin < User
  def send_admin_welcome_email
    Mailer.deliver(
      to: email,
      subject: "Admin Welcome",
      template: "admin_welcome"
    )
  end
end

# Good - extracted method
class User
  def send_welcome_email
    send_email("Welcome", "welcome")
  end

  private

  def send_email(subject, template)
    Mailer.deliver(
      to: email,
      subject: subject,
      template: template
    )
  end
end

class Admin < User
  def send_admin_welcome_email
    send_email("Admin Welcome", "admin_welcome")
  end
end
```

## Quality Score Interpretation

- **A (90-100)**: Excellent - maintain this quality
- **B (80-89)**: Good - minor improvements possible
- **C (70-79)**: Acceptable - consider refactoring
- **D (60-69)**: Needs work - prioritize improvements
- **F (<60)**: Poor - requires significant refactoring

## Quick Wins

When time is limited, prioritize:

1. **Remove unused code** - Easy fix, immediate improvement
2. **Extract long methods** - Break into 5-10 line methods
3. **Rename unclear variables** - Use descriptive names
4. **Reduce parameter lists** - Use parameter objects
5. **Fix duplicate code** - Extract to shared methods
