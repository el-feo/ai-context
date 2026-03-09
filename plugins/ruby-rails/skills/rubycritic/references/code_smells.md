# Common Code Smells and Fixes

## Reek Smells

### Control Parameter

```ruby
# Bad
def process(data, use_cache)
  use_cache ? cached_process(data) : fresh_process(data)
end

# Good - separate methods
def process_with_cache(data)
  cached_process(data)
end

def process_without_cache(data)
  fresh_process(data)
end
```

### Feature Envy

```ruby
# Bad - uses another class's data
def total_price
  item.price * item.quantity + item.tax
end

# Good - move to Item class
class Item
  def total_price
    price * quantity + tax
  end
end
```

### Long Parameter List (>3 params)

```ruby
# Bad
def create_user(name, email, age, address, phone, country)
end

# Good - parameter object
def create_user(user_params)
  name = user_params[:name]
  email = user_params[:email]
end
```

### Duplicate Method Call

```ruby
# Bad
def display
  puts user.full_name
  log("Displayed #{user.full_name}")
end

# Good - cache result
def display
  name = user.full_name
  puts name
  log("Displayed #{name}")
end
```

## Flog: High Complexity

Fix strategies:
- Extract methods for distinct operations
- Replace conditionals with polymorphism
- Use early returns to reduce nesting

```ruby
# Bad - deeply nested
def process_order(order)
  if order.valid?
    if order.paid?
      if order.items.any?
        order.items.each do |item|
          item.in_stock? ? item.ship : item.backorder
        end
      end
    end
  end
end

# Good - extracted methods with early returns
def process_order(order)
  return unless order.valid? && order.paid? && order.items.any?
  order.items.each { |item| process_item(item) }
end

def process_item(item)
  item.in_stock? ? item.ship : item.backorder
end
```

## Flay: Duplication

Fix strategies:
- Extract common code to shared methods
- Use modules for shared behavior
- Create service objects for complex operations

```ruby
# Bad - duplicated delivery logic
class User
  def send_welcome_email
    Mailer.deliver(to: email, subject: "Welcome", template: "welcome")
  end
end

class Admin < User
  def send_admin_welcome_email
    Mailer.deliver(to: email, subject: "Admin Welcome", template: "admin_welcome")
  end
end

# Good - extracted method
class User
  def send_welcome_email
    send_email("Welcome", "welcome")
  end

  private

  def send_email(subject, template)
    Mailer.deliver(to: email, subject: subject, template: template)
  end
end
```

## Quick Wins (priority order)

1. Remove unused code
2. Extract long methods (target 5-10 lines)
3. Reduce parameter lists (use parameter objects)
4. Fix duplicate code (extract to shared methods)
5. Rename unclear variables
