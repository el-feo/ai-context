# Sandi Metz Principles - Detailed Examples

## SOLID Principles

### Single Responsibility (SRP)

**Bad Example:**
```ruby
class User
  def save_to_database
    # Database logic
  end
  
  def send_welcome_email
    # Email logic
  end
  
  def generate_report
    # Reporting logic
  end
end
```

**Good Example:**
```ruby
class User
  def save
    UserRepository.new.save(self)
  end
end

class UserMailer
  def send_welcome(user)
    # Email logic
  end
end

class UserReport
  def generate(user)
    # Reporting logic
  end
end
```

### Open/Closed (OCP)

**Bad Example (modifying for new types):**
```ruby
class Discount
  def calculate(type, amount)
    case type
    when 'percentage'
      amount * 0.9
    when 'fixed'
      amount - 10
    when 'seasonal'  # Added new type - modified existing code!
      amount * 0.8
    end
  end
end
```

**Good Example (extending without modifying):**
```ruby
class PercentageDiscount
  def calculate(amount)
    amount * 0.9
  end
end

class FixedDiscount
  def calculate(amount)
    amount - 10
  end
end

class SeasonalDiscount  # New type - no existing code modified
  def calculate(amount)
    amount * 0.8
  end
end
```

### Liskov Substitution (LSP)

**Bad Example:**
```ruby
class Rectangle
  attr_accessor :width, :height
  
  def area
    width * height
  end
end

class Square < Rectangle
  def width=(value)
    @width = @height = value  # Violates LSP!
  end
  
  def height=(value)
    @width = @height = value  # Violates LSP!
  end
end

# This breaks:
rect = Square.new
rect.width = 5
rect.height = 10
puts rect.area  # Expected 50, got 100!
```

**Good Example:**
```ruby
class Shape
  def area
    raise NotImplementedError
  end
end

class Rectangle < Shape
  attr_accessor :width, :height
  
  def area
    width * height
  end
end

class Square < Shape
  attr_accessor :side
  
  def area
    side * side
  end
end
```

## Law of Demeter

**Bad Example (message chain):**
```ruby
class Order
  def ship
    customer.address.street.mailbox.deliver(package)
  end
end
```

**Good Example (delegation):**
```ruby
class Order
  def ship
    customer.deliver_to(package)
  end
end

class Customer
  def deliver_to(package)
    address.deliver(package)
  end
end

class Address
  def deliver(package)
    mailbox.accept(package)
  end
end
```

## Tell, Don't Ask

**Bad Example (asking):**
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

**Good Example (telling):**
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

## Replace Conditional with Polymorphism

**Bad Example:**
```ruby
class Bottle
  def quantity(number)
    if number == 0
      'no more'
    elsif number == 1
      '1'
    else
      number.to_s
    end
  end
  
  def container(number)
    if number == 1
      'bottle'
    else
      'bottles'
    end
  end
  
  def pronoun(number)
    if number == 1
      'it'
    else
      'one'
    end
  end
end
```

**Good Example (from 99 Bottles):**
```ruby
class BottleNumber
  def quantity
    number.to_s
  end
  
  def container
    'bottles'
  end
  
  def pronoun
    'one'
  end
end

class BottleNumber0 < BottleNumber
  def quantity
    'no more'
  end
end

class BottleNumber1 < BottleNumber
  def container
    'bottle'
  end
  
  def pronoun
    'it'
  end
end
```

## Extract Method

**Bad Example:**
```ruby
def process_order
  total = 0
  items.each do |item|
    total += item.price * item.quantity
  end
  
  if discount_code == 'SAVE10'
    total = total * 0.9
  elsif discount_code == 'SAVE20'
    total = total * 0.8
  end
  
  if total > 100
    shipping = 0
  else
    shipping = 10
  end
  
  total + shipping
end
```

**Good Example:**
```ruby
def process_order
  items_total - discount_amount + shipping_cost
end

private

def items_total
  items.sum { |item| item.price * item.quantity }
end

def discount_amount
  Discount.for_code(discount_code).apply(items_total)
end

def shipping_cost
  items_total > 100 ? 0 : 10
end
```

## Extract Class

**Bad Example:**
```ruby
class Person
  attr_accessor :name, :street, :city, :state, :zip, :country
  
  def full_address
    "#{street}, #{city}, #{state} #{zip}, #{country}"
  end
  
  def same_country?(other_person)
    country == other_person.country
  end
end
```

**Good Example:**
```ruby
class Person
  attr_accessor :name
  attr_reader :address
  
  def initialize(name, address)
    @name = name
    @address = address
  end
end

class Address
  attr_accessor :street, :city, :state, :zip, :country
  
  def to_s
    "#{street}, #{city}, #{state} #{zip}, #{country}"
  end
  
  def same_country?(other_address)
    country == other_address.country
  end
end
```

## Introduce Parameter Object

**Bad Example:**
```ruby
def create_order(customer_name, customer_email, 
                 shipping_street, shipping_city, shipping_state, shipping_zip,
                 billing_street, billing_city, billing_state, billing_zip)
  # Too many parameters!
end
```

**Good Example:**
```ruby
def create_order(customer, shipping_address, billing_address)
  # Much cleaner!
end

class Customer
  attr_reader :name, :email
end

class Address
  attr_reader :street, :city, :state, :zip
end
```

## Shameless Green → DRY → SOLID Journey

**Step 1: Shameless Green (simple, works)**
```ruby
def verse(n)
  if n == 0
    "No more bottles of beer on the wall"
  elsif n == 1
    "1 bottle of beer on the wall"
  elsif n == 2
    "2 bottles of beer on the wall"
  else
    "#{n} bottles of beer on the wall"
  end
end
```

**Step 2: Remove Duplication**
```ruby
def verse(n)
  "#{quantity(n)} #{container(n)} of beer on the wall"
end

def quantity(n)
  n.zero? ? 'no more' : n.to_s
end

def container(n)
  n == 1 ? 'bottle' : 'bottles'
end
```

**Step 3: Extract Concept**
```ruby
class Bottle
  attr_reader :number
  
  def initialize(number)
    @number = number
  end
  
  def verse
    "#{quantity} #{container} of beer on the wall"
  end
  
  private
  
  def quantity
    number.zero? ? 'no more' : number.to_s
  end
  
  def container
    number == 1 ? 'bottle' : 'bottles'
  end
end
```

**Step 4: Polymorphism (Open/Closed)**
```ruby
class BottleNumber
  attr_reader :number
  
  def self.for(number)
    case number
    when 0 then BottleNumber0
    when 1 then BottleNumber1
    else BottleNumber
    end.new(number)
  end
  
  def verse
    "#{quantity} #{container} of beer on the wall"
  end
  
  def quantity
    number.to_s
  end
  
  def container
    'bottles'
  end
end

class BottleNumber0 < BottleNumber
  def quantity
    'no more'
  end
end

class BottleNumber1 < BottleNumber
  def container
    'bottle'
  end
end
```
