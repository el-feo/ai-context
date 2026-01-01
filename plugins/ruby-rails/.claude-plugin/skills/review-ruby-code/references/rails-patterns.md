# Rails Patterns and Anti-Patterns Reference

This guide covers Rails-specific patterns, anti-patterns, and performance issues to check during code reviews.

## N+1 Query Detection and Prevention

**What it is**: Making one query to get a collection, then making additional queries for each item in the collection.

### Detection Strategies

**In code review, look for**:
```ruby
# RED FLAG: Accessing associations in loops
@posts.each do |post|
  post.author.name      # Queries author for EACH post
  post.comments.count   # Queries comments for EACH post
end

# RED FLAG: Iteration with nested associations
users.map { |user| user.profile.avatar_url }

# RED FLAG: In views without eager loading
<% @articles.each do |article| %>
  <%= article.user.name %>  <!-- N+1 here -->
<% end %>
```

**Runtime detection**:
```ruby
# Add to development.rb to get warnings
config.after_initialize do
  Bullet.enable = true
  Bullet.alert = true
  Bullet.bullet_logger = true
  Bullet.console = true
end
```

### Solutions

**Use `includes` for eager loading**:
```ruby
# Bad - N+1 query
@posts = Post.all
@posts.each { |post| post.author.name }  # 1 + N queries

# Good - eager load with includes
@posts = Post.includes(:author)
@posts.each { |post| post.author.name }  # 2 queries total
```

**Use `preload` for separate queries**:
```ruby
# Loads associations in separate queries (better for large datasets)
Post.preload(:author, :comments)
```

**Use `eager_load` for LEFT OUTER JOIN**:
```ruby
# Loads everything in one query with LEFT OUTER JOIN
Post.eager_load(:author).where(authors: { active: true })
```

**Use `joins` for filtering only** (doesn't load association):
```ruby
# Only for WHERE clauses, doesn't prevent N+1
Post.joins(:author).where(authors: { country: 'US' })

# Still need includes if accessing association
Post.joins(:author).includes(:author).where(authors: { country: 'US' })
```

**Nested associations**:
```ruby
# Bad - N+1 on nested associations
Post.includes(:comments)
# Accessing comment.author still causes N+1

# Good - eager load nested associations
Post.includes(comments: :author)
```

**Counter caches for counts**:
```ruby
# Bad - counts cause N+1
@posts.each { |post| post.comments.count }

# Good - use counter cache
class Comment < ApplicationRecord
  belongs_to :post, counter_cache: true
end

# Migration to add counter cache
add_column :posts, :comments_count, :integer, default: 0
Post.find_each { |post| Post.reset_counters(post.id, :comments) }

# Now this is free
@posts.each { |post| post.comments_count }  # No queries!
```

---

## Callback Anti-Patterns

**Problem**: Callbacks make code hard to understand, test, and maintain. They create hidden dependencies and side effects.

### Common Callback Issues

**1. Side effects in callbacks**:
```ruby
# Bad - email sending in callback
class User < ApplicationRecord
  after_create :send_welcome_email

  private

  def send_welcome_email
    UserMailer.welcome_email(self).deliver_now
    # What if we're creating users in a seed script?
    # What if we're importing bulk users?
    # What if mail server is down?
  end
end
```

**2. Callbacks calling external services**:
```ruby
# Bad - external API calls in callbacks
class Order < ApplicationRecord
  after_save :sync_to_crm

  private

  def sync_to_crm
    CrmApi.update_order(self)  # Slows down every save
  end
end
```

**3. Callbacks updating other models**:
```ruby
# Bad - touching other models in callbacks
class Comment < ApplicationRecord
  after_create :update_post_stats

  private

  def update_post_stats
    post.increment!(:comment_count)
    post.touch(:last_commented_at)
    # Creates complex dependencies
  end
end
```

### Better Alternatives

**Use service objects for complex operations**:
```ruby
# Good - explicit service object
class UserCreationService
  def self.call(params)
    user = User.create!(params)
    UserMailer.welcome_email(user).deliver_later
    AnalyticsService.track_signup(user)
    user
  end
end

# Clear when side effects happen
UserCreationService.call(user_params)
```

**Use background jobs for async operations**:
```ruby
# Good - background job
class User < ApplicationRecord
  # No callbacks for side effects
end

class UserCreationService
  def self.call(params)
    user = User.create!(params)
    WelcomeEmailJob.perform_later(user.id)
    CrmSyncJob.perform_later(user.id)
    user
  end
end
```

**When callbacks are acceptable**:
```ruby
# OK - setting default values
class User < ApplicationRecord
  before_validation :normalize_email

  private

  def normalize_email
    self.email = email.downcase.strip if email.present?
  end
end

# OK - maintaining data consistency within same record
class Post < ApplicationRecord
  before_save :generate_slug

  private

  def generate_slug
    self.slug = title.parameterize if slug.blank?
  end
end
```

**Use ActiveRecord callbacks sparingly**:
- `before_validation`: Normalize/sanitize data
- `before_save`: Set calculated fields
- `after_commit`: Safer for side effects (transaction-aware)

**Avoid**:
- `after_create`, `after_save` with side effects
- Callbacks that call other models
- Callbacks with external API calls
- Callbacks with email sending

---

## Fat Model Anti-Pattern

**Problem**: Models with too many responsibilities become hard to maintain, test, and understand.

### Signs of Fat Models

```ruby
# Bad - model doing everything
class User < ApplicationRecord
  # 500+ lines

  # Validations (OK)
  validates :email, presence: true

  # Associations (OK)
  has_many :posts

  # Business logic (should be extracted)
  def calculate_reputation_score
    # 50 lines of complex logic
  end

  # Presentation logic (should be in presenter)
  def display_name
    "#{first_name} #{last_name}"
  end

  # External API integration (should be in service)
  def sync_to_mailchimp
    # Mailchimp API calls
  end

  # Complex queries (should be in query object)
  def self.active_premium_users_in_region(region)
    # Complex query logic
  end

  # Email sending (should be in service)
  def send_welcome_sequence
    # Email logic
  end

  # Report generation (should be in service)
  def generate_activity_report
    # Report logic
  end
end
```

### Refactoring Strategies

**1. Extract to Service Objects**:
```ruby
# app/services/user_reputation_calculator.rb
class UserReputationCalculator
  def initialize(user)
    @user = user
  end

  def calculate
    # Complex reputation logic
  end
end

# app/services/user_mailchimp_sync.rb
class UserMailchimpSync
  def initialize(user)
    @user = user
  end

  def sync
    # Mailchimp API logic
  end
end
```

**2. Extract to Query Objects**:
```ruby
# app/queries/user_query.rb
class UserQuery
  def initialize(relation = User.all)
    @relation = relation
  end

  def active_premium_in_region(region)
    @relation
      .where(status: 'active')
      .where(premium: true)
      .where(region: region)
  end
end

# Usage
UserQuery.new.active_premium_in_region('US')
```

**3. Extract to Presenters/Decorators**:
```ruby
# app/presenters/user_presenter.rb
class UserPresenter
  def initialize(user)
    @user = user
  end

  def display_name
    "#{@user.first_name} #{@user.last_name}"
  end

  def avatar_url
    @user.avatar.present? ? @user.avatar.url : default_avatar_url
  end
end
```

**4. Extract to Concerns** (for shared behavior):
```ruby
# app/models/concerns/sluggable.rb
module Sluggable
  extend ActiveSupport::Concern

  included do
    before_save :generate_slug
  end

  private

  def generate_slug
    self.slug = send(slug_source).parameterize if slug.blank?
  end

  def slug_source
    :title  # Override in including class if needed
  end
end

class Post < ApplicationRecord
  include Sluggable
end
```

---

## Service Object Patterns

Service objects extract business logic from models and controllers.

### When to Use Service Objects

- Complex multi-step operations
- Operations involving multiple models
- External API integrations
- Business logic that doesn't fit in a model
- Operations with side effects (emails, jobs, etc.)

### Service Object Structure

```ruby
# Simple structure
class UserRegistrationService
  def self.call(params)
    new(params).call
  end

  def initialize(params)
    @params = params
  end

  def call
    create_user
    send_welcome_email
    track_analytics
    user
  end

  private

  attr_reader :params, :user

  def create_user
    @user = User.create!(user_params)
  end

  def send_welcome_email
    UserMailer.welcome_email(user).deliver_later
  end

  def track_analytics
    AnalyticsService.track('user_registered', user_id: user.id)
  end

  def user_params
    params.require(:user).permit(:email, :name)
  end
end
```

### Result Object Pattern

```ruby
# app/services/result.rb
class Result
  attr_reader :value, :error

  def initialize(success:, value: nil, error: nil)
    @success = success
    @value = value
    @error = error
  end

  def success?
    @success
  end

  def failure?
    !@success
  end

  def self.success(value = nil)
    new(success: true, value: value)
  end

  def self.failure(error)
    new(success: false, error: error)
  end
end

# Service using Result
class OrderProcessingService
  def self.call(order_params)
    new(order_params).call
  end

  def initialize(order_params)
    @order_params = order_params
  end

  def call
    order = create_order
    return Result.failure(order.errors) unless order.persisted?

    charge_result = charge_payment(order)
    return Result.failure(charge_result.error) if charge_result.failure?

    Result.success(order)
  end

  private

  def create_order
    Order.create(@order_params)
  end

  def charge_payment(order)
    PaymentService.charge(order)
  end
end

# Usage in controller
def create
  result = OrderProcessingService.call(order_params)

  if result.success?
    redirect_to result.value
  else
    @errors = result.error
    render :new
  end
end
```

---

## Concerns: Proper Usage

**When to use concerns**:
- Shared behavior across multiple models
- Extracting cohesive functionality
- Domain-specific mixins

**When NOT to use concerns**:
- Single-use code (just keep it in the model)
- Hiding complexity (doesn't solve fat model problem)
- As a dumping ground for "misc" methods

### Good Concern Example

```ruby
# app/models/concerns/publishable.rb
module Publishable
  extend ActiveSupport::Concern

  included do
    scope :published, -> { where(published: true) }
    scope :draft, -> { where(published: false) }

    validates :published_at, presence: true, if: :published?
  end

  def publish!
    update!(published: true, published_at: Time.current)
  end

  def unpublish!
    update!(published: false)
  end

  def published?
    published == true
  end
end

# Used by multiple models
class Post < ApplicationRecord
  include Publishable
end

class Article < ApplicationRecord
  include Publishable
end
```

### Bad Concern Example

```ruby
# app/models/concerns/user_stuff.rb
module UserStuff  # Vague name is red flag
  extend ActiveSupport::Concern

  # Unrelated methods dumped together
  def full_name
    "#{first_name} #{last_name}"
  end

  def calculate_reputation
    # Complex logic
  end

  def sync_to_crm
    # External API
  end

  # Used by only User model - should just be in User
end
```

---

## Query Objects

Extract complex queries into dedicated classes.

```ruby
# app/queries/post_query.rb
class PostQuery
  def initialize(relation = Post.all)
    @relation = relation
  end

  def recent
    @relation.where('created_at > ?', 1.week.ago)
  end

  def popular
    @relation.where('views_count > ?', 1000)
  end

  def by_author(author)
    @relation.where(author: author)
  end

  def published
    @relation.where(published: true)
  end

  # Chainable complex queries
  def trending
    recent.popular.published.order(views_count: :desc)
  end
end

# Usage
PostQuery.new.trending
PostQuery.new.by_author(current_user).recent
```

---

## Performance Patterns

### Database Indexes

**Check for missing indexes**:
```ruby
# Bad - queries without indexes
User.where(email: params[:email])  # Needs index on email
Post.where(published: true)        # Needs index on published
Comment.where(post_id: 123)        # Foreign keys need indexes!
```

**Add indexes in migrations**:
```ruby
class AddIndexes < ActiveRecord::Migration[7.0]
  def change
    add_index :users, :email, unique: true
    add_index :posts, :published
    add_index :comments, :post_id
    add_index :posts, [:author_id, :published]  # Composite index
  end
end
```

### Caching Strategies

**Fragment caching**:
```erb
<!-- app/views/posts/show.html.erb -->
<% cache @post do %>
  <%= render @post %>
<% end %>
```

**Russian doll caching**:
```erb
<% cache @post do %>
  <h1><%= @post.title %></h1>

  <% cache @post.comments do %>
    <% @post.comments.each do |comment| %>
      <% cache comment do %>
        <%= render comment %>
      <% end %>
    <% end %>
  <% end %>
<% end %>
```

**Low-level caching**:
```ruby
def expensive_calculation
  Rails.cache.fetch("calculation-#{id}", expires_in: 12.hours) do
    # Expensive operation
    complex_computation
  end
end
```

### Background Jobs

**Move slow operations to background**:
```ruby
# Bad - slow operation in request
def create
  @user = User.create!(user_params)
  UserMailer.welcome_email(@user).deliver_now  # Blocks request
  redirect_to @user
end

# Good - async with background job
def create
  @user = User.create!(user_params)
  WelcomeEmailJob.perform_later(@user.id)
  redirect_to @user
end
```

---

## Controller Patterns

### Skinny Controllers

**Bad - fat controller**:
```ruby
class OrdersController < ApplicationController
  def create
    @user = User.find(params[:user_id])
    @product = Product.find(params[:product_id])
    @order = Order.new(user: @user, product: @product)

    if @order.save
      charge = Stripe::Charge.create(
        amount: @order.total,
        currency: 'usd',
        customer: @user.stripe_customer_id
      )

      @order.update!(payment_id: charge.id)
      OrderMailer.confirmation(@order).deliver_later
      AnalyticsService.track('order_created', @order.id)

      redirect_to @order
    else
      render :new
    end
  end
end
```

**Good - skinny controller with service**:
```ruby
class OrdersController < ApplicationController
  def create
    result = OrderCreationService.call(order_params)

    if result.success?
      redirect_to result.order
    else
      @order = result.order
      flash.now[:error] = result.error
      render :new
    end
  end
end
```

---

## Checking Rails Patterns in Reviews

**Quick checklist**:

**N+1 Queries**:
- [ ] Check for association access in loops
- [ ] Ensure `includes`/`preload` for eager loading
- [ ] Use counter caches for count operations
- [ ] Run Bullet gem to detect N+1s

**Callbacks**:
- [ ] No external API calls in callbacks
- [ ] No email sending in callbacks
- [ ] Use `after_commit` over `after_save` for side effects
- [ ] Consider service objects instead of callbacks

**Fat Models**:
- [ ] Models under 200 lines
- [ ] Business logic in service objects
- [ ] Complex queries in query objects
- [ ] Presentation logic in presenters

**Performance**:
- [ ] Indexes on foreign keys
- [ ] Indexes on frequently queried columns
- [ ] Caching for expensive operations
- [ ] Background jobs for slow tasks

**Controllers**:
- [ ] Controllers under 100 lines
- [ ] No business logic in controllers
- [ ] Service objects for complex operations
- [ ] Strong parameters properly used
