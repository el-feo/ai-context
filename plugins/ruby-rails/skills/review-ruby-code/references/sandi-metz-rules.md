# Sandi Metz Rules Reference

Sandi Metz's rules from "Practical Object-Oriented Design in Ruby" (POODR) and "99 Bottles of OOP" provide practical constraints that encourage better object-oriented design.

## The Five Rules

### Rule 1: Classes ≤ 100 Lines

**Principle**: Classes should be small and focused on a single responsibility.

**Detection**:
```bash
# Count lines in a class (excluding blank lines and comments)
grep -v '^\s*#' file.rb | grep -v '^\s*$' | wc -l
```

**Why it matters**: Large classes often violate Single Responsibility Principle and become difficult to understand, test, and maintain.

**Violations indicate**:
- Class doing too many things
- Missing extraction of collaborators
- Business logic mixed with coordination logic

**Refactoring strategies**:
- Extract related methods into new classes
- Identify cohesive groups of methods and data
- Create service objects for complex operations
- Use composition over large inheritance hierarchies

**Example violation**:
```ruby
class UserManager
  # 150 lines handling:
  # - User creation
  # - Authentication
  # - Password reset
  # - Email notifications
  # - Profile updates
  # - Permission checks
end
```

**Refactored**:
```ruby
class User < ApplicationRecord
  # 30 lines - just the model
end

class UserAuthenticator
  # 40 lines - authentication logic
end

class UserNotifier
  # 35 lines - notification logic
end

class UserProfileUpdater
  # 45 lines - profile update logic
end
```

---

### Rule 2: Methods ≤ 5 Lines

**Principle**: Methods should do one thing and do it well.

**Detection**: Count lines between `def` and `end` (excluding the definition line itself).

**Why it matters**: Short methods are easier to understand, test, and reuse. They encourage proper naming and reveal intention.

**Violations indicate**:
- Method doing multiple things
- Missing intermediate abstractions
- Low-level details mixed with high-level logic

**Refactoring strategies**:
- Extract logical groups into private methods
- Use composed method pattern
- Create intention-revealing method names
- Move complex conditions into query methods

**Example violation**:
```ruby
def process_order(order)
  if order.items.any? && order.user.active? && order.payment_valid?
    order.items.each do |item|
      item.reduce_inventory
      item.update(status: 'processed')
    end
    order.calculate_total
    order.send_confirmation_email
    order.update(status: 'completed')
    true
  else
    false
  end
end
```

**Refactored**:
```ruby
def process_order(order)
  return false unless processable?(order)

  process_items(order)
  finalize_order(order)
  true
end

private

def processable?(order)
  order.items.any? && order.user.active? && order.payment_valid?
end

def process_items(order)
  order.items.each { |item| process_item(item) }
end

def process_item(item)
  item.reduce_inventory
  item.update(status: 'processed')
end

def finalize_order(order)
  order.calculate_total
  order.send_confirmation_email
  order.update(status: 'completed')
end
```

---

### Rule 3: Methods ≤ 4 Parameters

**Principle**: Too many parameters indicate the method is doing too much or should be a class.

**Detection**: Count parameters in method definition (including keyword arguments).

**Why it matters**: Methods with many parameters are hard to understand, hard to test, and suggest missing abstractions.

**Violations indicate**:
- Method needs too much context
- Missing object to encapsulate related data
- Primitive obsession (using primitives instead of objects)

**Refactoring strategies**:
- Introduce parameter object
- Extract class to encapsulate related parameters
- Use builder pattern for complex construction
- Consider if method belongs in different class

**Example violation**:
```ruby
def send_notification(user, title, body, type, priority, scheduled_at, metadata)
  # ...
end
```

**Refactored with parameter object**:
```ruby
class Notification
  attr_reader :user, :title, :body, :type, :priority, :scheduled_at, :metadata

  def initialize(user:, title:, body:, type: :email, priority: :normal,
                 scheduled_at: Time.current, metadata: {})
    @user = user
    @title = title
    @body = body
    @type = type
    @priority = priority
    @scheduled_at = scheduled_at
    @metadata = metadata
  end
end

def send_notification(notification)
  # Now works with a single, well-defined object
end
```

---

### Rule 4: Controllers Instantiate ≤ 1 Object

**Principle**: Controllers should be thin and coordinate, not create multiple objects directly.

**Detection**: Count `new` calls or model queries in controller actions.

**Why it matters**: Controllers should orchestrate, not contain business logic. Multiple instantiations suggest missing service layer.

**Violations indicate**:
- Business logic in controller
- Missing service object or command pattern
- Poor separation of concerns

**Refactoring strategies**:
- Extract to service objects
- Use command pattern
- Create facade objects
- Move queries to model scopes or query objects

**Example violation**:
```ruby
class OrdersController < ApplicationController
  def create
    @user = User.find(params[:user_id])
    @product = Product.find(params[:product_id])
    @payment = Payment.new(payment_params)
    @shipping = ShippingAddress.new(shipping_params)
    @order = Order.new(user: @user, product: @product,
                       payment: @payment, shipping: @shipping)

    if @order.save
      @notification = Notification.new(order: @order)
      @notification.send
      redirect_to @order
    else
      render :new
    end
  end
end
```

**Refactored**:
```ruby
class OrdersController < ApplicationController
  def create
    result = OrderCreationService.call(order_params)

    if result.success?
      redirect_to result.order
    else
      @order = result.order
      render :new
    end
  end
end

class OrderCreationService
  def self.call(params)
    new(params).call
  end

  def initialize(params)
    @params = params
  end

  def call
    build_order
    save_order
    send_notification if order.persisted?
    Result.new(order: order, success: order.persisted?)
  end

  private

  attr_reader :params, :order

  def build_order
    @order = Order.new(
      user: find_user,
      product: find_product,
      payment: build_payment,
      shipping: build_shipping
    )
  end

  # ... rest of implementation
end
```

---

### Rule 5: Views Reference ≤ 1 Instance Variable

**Principle**: Views should only know about one thing, reducing coupling between controller and view.

**Detection**: Count `@` symbols in view files (excluding partials with explicit locals).

**Why it matters**: Multiple instance variables create tight coupling and make views hard to reuse and test.

**Violations indicate**:
- Missing presenter or decorator
- Business logic in views
- Controller exposing too much

**Refactoring strategies**:
- Use presenter pattern
- Use decorator pattern (Draper gem)
- Pass locals to partials explicitly
- Create view objects

**Example violation**:
```ruby
# app/controllers/users_controller.rb
def show
  @user = User.find(params[:id])
  @posts = @user.posts.recent
  @comments = @user.comments.recent
  @followers = @user.followers
end

# app/views/users/show.html.erb
<h1><%= @user.name %></h1>
<%= render @posts %>
<%= render @comments %>
<p>Followers: <%= @followers.count %></p>
```

**Refactored with presenter**:
```ruby
# app/controllers/users_controller.rb
def show
  @presenter = UserProfilePresenter.new(User.find(params[:id]))
end

# app/presenters/user_profile_presenter.rb
class UserProfilePresenter
  def initialize(user)
    @user = user
  end

  def name
    @user.name
  end

  def recent_posts
    @user.posts.recent
  end

  def recent_comments
    @user.comments.recent
  end

  def follower_count
    @user.followers.count
  end
end

# app/views/users/show.html.erb
<h1><%= @presenter.name %></h1>
<%= render @presenter.recent_posts %>
<%= render @presenter.recent_comments %>
<p>Followers: <%= @presenter.follower_count %></p>
```

---

## Law of Demeter

**"Only talk to your immediate friends"**

Also known as the principle of least knowledge, this rule states that an object should only call methods on:
1. Itself
2. Objects passed as parameters
3. Objects it creates
4. Its direct component objects (instance variables)

**Violations look like**: `user.address.city.name` (train wrecks)

**Why it matters**: Reduces coupling and makes code more maintainable.

**Detection patterns**:
```ruby
# Violation - multiple dots (train wreck)
order.user.shipping_address.city.tax_rate

# Violation - reaching through objects
@post.author.profile.avatar_url
```

**Refactoring strategy**:
```ruby
# Hide delegation behind methods
class Order
  def tax_rate
    user.tax_rate  # User knows how to get tax rate
  end
end

class User
  def tax_rate
    shipping_address.tax_rate  # Address knows its tax rate
  end
end

# Or use Rails delegate
class Order
  delegate :tax_rate, to: :user
end
```

---

## Tell, Don't Ask

**Principle**: Objects should make their own decisions, not have their state queried and acted upon externally.

**Bad** (asking):
```ruby
class Controller
  def handle_request(user)
    if user.admin?
      admin_dashboard
    elsif user.premium?
      premium_dashboard
    else
      standard_dashboard
    end
  end
end
```

**Good** (telling):
```ruby
class Controller
  def handle_request(user)
    user.show_dashboard
  end
end

class User
  def show_dashboard
    dashboard_class.new(self).render
  end

  private

  def dashboard_class
    return AdminDashboard if admin?
    return PremiumDashboard if premium?
    StandardDashboard
  end
end
```

---

## Code Smells (18 types)

**Structural**:
- Long Method (>5 lines)
- Large Class (>100 lines)
- Long Parameter List (>4 params)
- Data Clump (same params together repeatedly)

**Coupling**:
- Feature Envy (method uses data from another class more than own)
- Message Chains (Law of Demeter violations)
- Inappropriate Intimacy (classes too tightly coupled)

**Conditional Logic**:
- Conditional Complexity (nested if-elsif)
- Case Statements (candidate for polymorphism)
- Speculative Generality (code added "just in case")

**Naming**:
- Vague names (Manager, Handler, Processor, Data)
- Methods with "and" (doing multiple things)
- Flag parameters (boolean params that change behavior)

**Comments**:
- Comments explaining "what" code does → Code should be self-documenting
- Keep comments that explain "why" decisions were made

---

## Shameless Green Philosophy

From 99 Bottles of OOP - encourage this refactoring approach:

1. **Start with Shameless Green** - Write simplest code that works
2. **Wait for duplication** - Don't abstract too early
3. **Follow Flocking Rules**:
   - Find things that are most alike
   - Find smallest difference between them
   - Make simplest change to remove difference
4. **Converge on abstractions** - Let patterns emerge

**Key wisdom**: "Make the change easy, then make the easy change"

**Example journey**:

Step 1 - Shameless Green:
```ruby
def verse(n)
  if n == 0
    "No more bottles of beer on the wall"
  elsif n == 1
    "1 bottle of beer on the wall"
  else
    "#{n} bottles of beer on the wall"
  end
end
```

Step 2 - Remove Duplication:
```ruby
def verse(n)
  "#{quantity(n)} #{container(n)} of beer on the wall"
end
```

Step 3 - Polymorphism (Open/Closed):
```ruby
class BottleNumber
  def self.for(number)
    case number
    when 0 then BottleNumber0
    when 1 then BottleNumber1
    else BottleNumber
    end.new(number)
  end

  def quantity = number.to_s
  def container = 'bottles'
end

class BottleNumber0 < BottleNumber
  def quantity = 'no more'
end

class BottleNumber1 < BottleNumber
  def container = 'bottle'
end
```

---

## Breaking The Rules

**When to break these rules:**

1. **Rule 1 (100 lines)**: Complex algorithms that are easier to understand together
2. **Rule 2 (5 lines)**: Simple assignment methods, DSL configuration blocks
3. **Rule 3 (4 parameters)**: Framework requirements (e.g., Rails callbacks), public APIs
4. **Rule 4 (1 instantiation)**: Simple CRUD operations, scaffold-generated actions
5. **Rule 5 (1 instance variable)**: Form objects with multiple models, complex forms

**Guideline**: If you break a rule, document why with a comment explaining the trade-off.

Sandi Metz: "Break them only if you have a good reason and you've tried not to."
