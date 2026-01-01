# SOLID Principles Reference

The SOLID principles are five design principles that make software designs more understandable, flexible, and maintainable.

## S - Single Responsibility Principle (SRP)

**Definition**: A class should have one, and only one, reason to change.

**Core idea**: Each class should have a single, well-defined responsibility. If a class has multiple responsibilities, changes to one responsibility can affect the others.

**How to identify violations**:
- Class name contains "And" or "Manager" or "Handler"
- Difficult to give the class a concise name
- Class has methods that operate on different data
- Changes in different parts of the application require modifying this class

**Example violation**:
```ruby
class User < ApplicationRecord
  # Responsibility 1: User data
  validates :email, presence: true

  # Responsibility 2: Authentication
  def authenticate(password)
    BCrypt::Password.new(password_digest) == password
  end

  # Responsibility 3: Email notifications
  def send_welcome_email
    UserMailer.welcome_email(self).deliver_now
  end

  # Responsibility 4: Report generation
  def generate_activity_report
    activities.map { |a| "#{a.created_at}: #{a.description}" }.join("\n")
  end

  # Responsibility 5: External API integration
  def sync_to_crm
    CrmApi.create_contact(
      email: email,
      name: name
    )
  end
end
```

**Refactored**:
```ruby
# Responsibility 1: User data only
class User < ApplicationRecord
  validates :email, presence: true
end

# Responsibility 2: Authentication
class UserAuthenticator
  def initialize(user)
    @user = user
  end

  def authenticate(password)
    BCrypt::Password.new(@user.password_digest) == password
  end
end

# Responsibility 3: Email notifications
class UserNotifier
  def initialize(user)
    @user = user
  end

  def send_welcome_email
    UserMailer.welcome_email(@user).deliver_now
  end
end

# Responsibility 4: Report generation
class UserActivityReportGenerator
  def initialize(user)
    @user = user
  end

  def generate
    @user.activities.map { |a| format_activity(a) }.join("\n")
  end

  private

  def format_activity(activity)
    "#{activity.created_at}: #{activity.description}"
  end
end

# Responsibility 5: External API integration
class UserCrmSync
  def initialize(user)
    @user = user
  end

  def sync
    CrmApi.create_contact(
      email: @user.email,
      name: @user.name
    )
  end
end
```

**Benefits of SRP**:
- Easier to test (each class has focused tests)
- Easier to understand (clear purpose)
- Less likely to break when changing
- Better reusability

---

## O - Open/Closed Principle (OCP)

**Definition**: Software entities should be open for extension but closed for modification.

**Core idea**: You should be able to add new functionality without changing existing code. Achieve this through abstraction and polymorphism.

**How to identify violations**:
- Long if/elsif/case statements that grow with new types
- Modifying existing methods to handle new cases
- Lack of abstraction or inheritance where behavior varies

**Example violation**:
```ruby
class ReportGenerator
  def generate(report_type, data)
    case report_type
    when :pdf
      generate_pdf(data)
    when :csv
      generate_csv(data)
    when :json
      generate_json(data)
    # Adding new format requires modifying this method
    end
  end

  private

  def generate_pdf(data)
    # PDF generation logic
  end

  def generate_csv(data)
    # CSV generation logic
  end

  def generate_json(data)
    # JSON generation logic
  end
end
```

**Refactored with polymorphism**:
```ruby
# Base abstraction
class ReportGenerator
  def generate(data)
    raise NotImplementedError, "Subclasses must implement generate"
  end
end

# Concrete implementations
class PdfReportGenerator < ReportGenerator
  def generate(data)
    # PDF generation logic
  end
end

class CsvReportGenerator < ReportGenerator
  def generate(data)
    # CSV generation logic
  end
end

class JsonReportGenerator < ReportGenerator
  def generate(data)
    # JSON generation logic
  end
end

# New format can be added without modifying existing code
class XmlReportGenerator < ReportGenerator
  def generate(data)
    # XML generation logic
  end
end

# Usage with strategy pattern
class ReportService
  def initialize(generator)
    @generator = generator
  end

  def create_report(data)
    @generator.generate(data)
  end
end

# Usage
service = ReportService.new(PdfReportGenerator.new)
service.create_report(data)
```

**Rails example with concerns**:
```ruby
# Instead of modifying existing Payment class for new payment types
module Payable
  extend ActiveSupport::Concern

  def process_payment
    raise NotImplementedError
  end
end

class CreditCardPayment < Payment
  include Payable

  def process_payment
    # Credit card logic
  end
end

class PaypalPayment < Payment
  include Payable

  def process_payment
    # PayPal logic
  end
end

# Adding new payment type doesn't modify existing classes
class CryptoPayment < Payment
  include Payable

  def process_payment
    # Cryptocurrency logic
  end
end
```

---

## L - Liskov Substitution Principle (LSP)

**Definition**: Objects of a superclass should be replaceable with objects of a subclass without breaking the application.

**Core idea**: Subtypes must be substitutable for their base types. If S is a subtype of T, then objects of type T can be replaced with objects of type S without altering program correctness.

**How to identify violations**:
- Subclass removes functionality from parent
- Subclass throws exceptions parent doesn't throw
- Subclass strengthens preconditions (requires more)
- Subclass weakens postconditions (guarantees less)
- Type checking (`is_a?`, `kind_of?`) before method calls

**Example violation**:
```ruby
class Bird
  def fly
    "Flying high!"
  end
end

class Penguin < Bird
  def fly
    raise "Penguins can't fly!"  # Violates LSP
  end
end

# This breaks when we substitute Penguin for Bird
def make_bird_fly(bird)
  bird.fly  # Will raise error for Penguin
end

bird = Bird.new
make_bird_fly(bird)  # Works

penguin = Penguin.new
make_bird_fly(penguin)  # Raises error - LSP violation!
```

**Refactored**:
```ruby
# Better abstraction
class Bird
  def move
    raise NotImplementedError
  end
end

class FlyingBird < Bird
  def move
    fly
  end

  def fly
    "Flying high!"
  end
end

class Penguin < Bird
  def move
    swim
  end

  def swim
    "Swimming fast!"
  end
end

# Now substitution works correctly
def make_bird_move(bird)
  bird.move  # Works for all birds
end

eagle = FlyingBird.new
make_bird_move(eagle)  # "Flying high!"

penguin = Penguin.new
make_bird_move(penguin)  # "Swimming fast!"
```

**Rails example**:
```ruby
# Violation
class User
  def save
    # Normal save behavior
    super
  end
end

class AdminUser < User
  def save
    raise "Admins can't be saved directly"  # LSP violation
  end
end

# Refactored
class User
  def save
    return false unless can_be_saved?
    super
  end

  def can_be_saved?
    true
  end
end

class AdminUser < User
  def can_be_saved?
    false  # Doesn't violate LSP, just returns false
  end
end
```

**Key rule**: If you need to check the type before calling a method, LSP is probably violated.

---

## I - Interface Segregation Principle (ISP)

**Definition**: No client should be forced to depend on methods it does not use.

**Core idea**: Many specific interfaces are better than one general-purpose interface. Classes shouldn't be forced to implement methods they don't need.

**How to identify violations**:
- Classes implementing interfaces with empty/no-op methods
- Modules forcing unrelated behavior
- Fat interfaces with many unrelated methods
- Clients that use only a small subset of an interface

**Example violation**:
```ruby
# Fat interface forcing too many responsibilities
module Workable
  def work
    raise NotImplementedError
  end

  def eat_lunch
    raise NotImplementedError
  end

  def take_break
    raise NotImplementedError
  end

  def attend_meeting
    raise NotImplementedError
  end
end

class HumanWorker
  include Workable

  def work
    "Working on tasks"
  end

  def eat_lunch
    "Eating lunch"
  end

  def take_break
    "Taking a break"
  end

  def attend_meeting
    "Attending meeting"
  end
end

class RobotWorker
  include Workable

  def work
    "Processing tasks"
  end

  def eat_lunch
    # Robots don't eat - forced to implement anyway
    nil
  end

  def take_break
    # Robots don't need breaks - forced to implement
    nil
  end

  def attend_meeting
    # Robots don't attend meetings - forced to implement
    nil
  end
end
```

**Refactored with segregated interfaces**:
```ruby
# Split into focused interfaces
module Workable
  def work
    raise NotImplementedError
  end
end

module Feedable
  def eat_lunch
    raise NotImplementedError
  end
end

module Breakable
  def take_break
    raise NotImplementedError
  end
end

module Attendable
  def attend_meeting
    raise NotImplementedError
  end
end

class HumanWorker
  include Workable
  include Feedable
  include Breakable
  include Attendable

  def work
    "Working on tasks"
  end

  def eat_lunch
    "Eating lunch"
  end

  def take_break
    "Taking a break"
  end

  def attend_meeting
    "Attending meeting"
  end
end

class RobotWorker
  include Workable  # Only includes what it needs

  def work
    "Processing tasks"
  end
end
```

**Rails example**:
```ruby
# Violation - fat concern
module Publishable
  extend ActiveSupport::Concern

  def publish
    update(published: true, published_at: Time.current)
  end

  def unpublish
    update(published: false)
  end

  def schedule_publication(time)
    update(scheduled_for: time)
  end

  def send_publication_notification
    NotificationMailer.published(self).deliver_later
  end

  def generate_social_media_post
    # Not all publishable things need this
  end
end

# Refactored - segregated concerns
module Publishable
  extend ActiveSupport::Concern

  def publish
    update(published: true, published_at: Time.current)
  end

  def unpublish
    update(published: false)
  end
end

module Schedulable
  extend ActiveSupport::Concern

  def schedule_publication(time)
    update(scheduled_for: time)
  end
end

module Notifiable
  extend ActiveSupport::Concern

  def send_publication_notification
    NotificationMailer.published(self).deliver_later
  end
end

module SocialMediaIntegrated
  extend ActiveSupport::Concern

  def generate_social_media_post
    SocialMediaService.create_post(self)
  end
end

# Models include only what they need
class BlogPost < ApplicationRecord
  include Publishable
  include Schedulable
  include Notifiable
  include SocialMediaIntegrated
end

class Comment < ApplicationRecord
  include Publishable
  # Comments don't need scheduling or social media
end
```

---

## D - Dependency Inversion Principle (DIP)

**Definition**: High-level modules should not depend on low-level modules. Both should depend on abstractions. Abstractions should not depend on details. Details should depend on abstractions.

**Core idea**: Depend on interfaces/abstractions rather than concrete implementations. This decouples code and makes it more flexible.

**How to identify violations**:
- Classes instantiating dependencies directly
- Hard-coded dependencies
- Tight coupling to specific implementations
- Difficult to test due to concrete dependencies

**Example violation**:
```ruby
# High-level class depends on low-level concrete implementation
class OrderProcessor
  def process(order)
    # Tightly coupled to MySqlDatabase
    database = MySqlDatabase.new
    database.save(order)

    # Tightly coupled to SmtpEmailService
    email_service = SmtpEmailService.new
    email_service.send_confirmation(order.user.email)

    # Tightly coupled to StripePaymentGateway
    payment = StripePaymentGateway.new
    payment.charge(order.amount)
  end
end
```

**Refactored with dependency injection**:
```ruby
# Define abstractions (interfaces)
class DatabaseAdapter
  def save(record)
    raise NotImplementedError
  end
end

class EmailService
  def send_confirmation(email)
    raise NotImplementedError
  end
end

class PaymentGateway
  def charge(amount)
    raise NotImplementedError
  end
end

# Concrete implementations depend on abstractions
class MySqlDatabase < DatabaseAdapter
  def save(record)
    # MySQL-specific logic
  end
end

class PostgresDatabase < DatabaseAdapter
  def save(record)
    # Postgres-specific logic
  end
end

class SmtpEmailService < EmailService
  def send_confirmation(email)
    # SMTP logic
  end
end

class SendgridEmailService < EmailService
  def send_confirmation(email)
    # Sendgrid API logic
  end
end

class StripePaymentGateway < PaymentGateway
  def charge(amount)
    # Stripe API logic
  end
end

class PaypalPaymentGateway < PaymentGateway
  def charge(amount)
    # PayPal API logic
  end
end

# High-level class now depends on abstractions
class OrderProcessor
  def initialize(database:, email_service:, payment_gateway:)
    @database = database
    @email_service = email_service
    @payment_gateway = payment_gateway
  end

  def process(order)
    @database.save(order)
    @email_service.send_confirmation(order.user.email)
    @payment_gateway.charge(order.amount)
  end
end

# Easy to swap implementations
processor = OrderProcessor.new(
  database: PostgresDatabase.new,
  email_service: SendgridEmailService.new,
  payment_gateway: StripePaymentGateway.new
)

# Easy to test with mocks
test_processor = OrderProcessor.new(
  database: MockDatabase.new,
  email_service: MockEmailService.new,
  payment_gateway: MockPaymentGateway.new
)
```

**Rails example with service objects**:
```ruby
# Violation - controller tightly coupled to implementation
class OrdersController < ApplicationController
  def create
    payment = Stripe::Charge.create(
      amount: order_params[:amount],
      currency: 'usd',
      source: order_params[:token]
    )

    order = Order.create!(order_params.merge(payment_id: payment.id))

    Twilio::REST::Client.new.messages.create(
      from: ENV['TWILIO_NUMBER'],
      to: order.user.phone,
      body: "Order confirmed"
    )

    redirect_to order
  end
end

# Refactored - depend on abstractions
class OrdersController < ApplicationController
  def create
    result = OrderCreationService.call(
      params: order_params,
      payment_gateway: payment_gateway,
      notification_service: notification_service
    )

    if result.success?
      redirect_to result.order
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def payment_gateway
    # Can be configured or swapped easily
    @payment_gateway ||= PaymentGateways::Stripe.new
  end

  def notification_service
    @notification_service ||= NotificationServices::Sms.new
  end
end

class OrderCreationService
  def self.call(params:, payment_gateway:, notification_service:)
    new(params, payment_gateway, notification_service).call
  end

  def initialize(params, payment_gateway, notification_service)
    @params = params
    @payment_gateway = payment_gateway
    @notification_service = notification_service
  end

  def call
    payment = process_payment
    return failure(payment.error) unless payment.success?

    order = create_order(payment)
    send_notification(order)

    success(order)
  end

  private

  def process_payment
    @payment_gateway.charge(
      amount: @params[:amount],
      token: @params[:token]
    )
  end

  def create_order(payment)
    Order.create!(@params.merge(payment_id: payment.id))
  end

  def send_notification(order)
    @notification_service.send(
      to: order.user.phone,
      message: "Order confirmed"
    )
  end
end
```

**Benefits of DIP**:
- Easy to swap implementations (e.g., test vs. production)
- Decoupled code
- Better testability
- More flexible and maintainable

---

## Checking SOLID in Code Reviews

**Quick checklist**:

**SRP violations**:
- [ ] Class has methods operating on different data
- [ ] Class name contains "And", "Manager", "Handler"
- [ ] Class would need to change for multiple reasons

**OCP violations**:
- [ ] Long case statements based on type
- [ ] Modifying existing methods to add new behavior
- [ ] Lack of polymorphism where behavior varies

**LSP violations**:
- [ ] Type checking before method calls
- [ ] Subclass removes or restricts parent functionality
- [ ] Unexpected exceptions in subclasses

**ISP violations**:
- [ ] Empty or no-op method implementations
- [ ] Modules/concerns forcing unrelated behavior
- [ ] Classes implementing large interfaces partially

**DIP violations**:
- [ ] Direct instantiation of dependencies
- [ ] Hard-coded class names for dependencies
- [ ] Difficult to test due to concrete dependencies

**Code review comments should**:
- Identify which principle is violated
- Explain why it matters
- Suggest specific refactoring approach
- Provide code example if helpful
