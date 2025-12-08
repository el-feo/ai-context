# Security Checklist Reference

This guide covers common security vulnerabilities to check in Ruby on Rails code reviews.

## SQL Injection

**Risk**: Attackers can execute arbitrary SQL queries, potentially reading, modifying, or deleting data.

### Vulnerable Patterns

**1. String interpolation in queries**:
```ruby
# DANGEROUS - SQL injection vulnerability
User.where("email = '#{params[:email]}'")
Post.where("title LIKE '%#{params[:search]}%'")

# Attacker input: ' OR '1'='1
# Results in: SELECT * FROM users WHERE email = '' OR '1'='1'
```

**2. Raw SQL without parameterization**:
```ruby
# DANGEROUS
User.find_by_sql("SELECT * FROM users WHERE id = #{params[:id]}")
ActiveRecord::Base.connection.execute("DELETE FROM posts WHERE id = #{params[:id]}")
```

**3. Unsafe sanitize usage**:
```ruby
# DANGEROUS - still vulnerable
User.where("name = #{sanitize(params[:name])}")
```

### Safe Alternatives

**1. Use parameterized queries**:
```ruby
# SAFE - uses placeholders
User.where("email = ?", params[:email])
Post.where("title LIKE ?", "%#{params[:search]}%")
User.where("created_at > ? AND status = ?", date, status)
```

**2. Use hash conditions**:
```ruby
# SAFE - ActiveRecord handles escaping
User.where(email: params[:email])
Post.where(status: 'published', category: params[:category])
```

**3. Use named placeholders**:
```ruby
# SAFE - named placeholders
User.where("email = :email AND status = :status",
           email: params[:email], status: params[:status])
```

**4. Use Arel for complex queries**:
```ruby
# SAFE - using Arel
users = User.arel_table
User.where(users[:email].eq(params[:email]))
```

**5. Safe raw SQL**:
```ruby
# SAFE - with bind parameters
User.find_by_sql(["SELECT * FROM users WHERE email = ?", params[:email]])
```

### Detection Strategy

**In code review, search for**:
- String interpolation (`#{}`) in SQL strings
- `where()` with strings containing user input
- `find_by_sql` without bind parameters
- `execute` or `exec_query` with user input
- `delete_all` or `update_all` with unsafe conditions

---

## Cross-Site Scripting (XSS)

**Risk**: Attackers can inject malicious JavaScript that executes in other users' browsers, potentially stealing data or performing actions on their behalf.

### Vulnerable Patterns

**1. Using `html_safe` on user input**:
```ruby
# DANGEROUS
<%= params[:message].html_safe %>
<%= @user.bio.html_safe %>  # If bio contains user input

# Attacker input: <script>alert('XSS')</script>
```

**2. Using `raw()` on user input**:
```ruby
# DANGEROUS
<%= raw @comment.body %>
<%= raw params[:content] %>
```

**3. Rendering unescaped HTML**:
```ruby
# DANGEROUS in Rails 2
<%== @user.description %>
```

**4. Direct JavaScript embedding**:
```ruby
# DANGEROUS
<script>
  var message = "<%= @message %>";  // Not escaped in JS context
</script>
```

**5. Unsafe content_tag usage**:
```ruby
# DANGEROUS
content_tag :div, params[:content].html_safe
```

### Safe Alternatives

**1. Let Rails auto-escape** (default behavior):
```ruby
# SAFE - Rails escapes by default
<%= @user.bio %>
<%= params[:message] %>
```

**2. Use sanitize for limited HTML**:
```ruby
# SAFE - allows safe HTML tags only
<%= sanitize @comment.body %>

# With custom allowed tags
<%= sanitize @post.content, tags: %w(strong em a), attributes: %w(href) %>
```

**3. Use JSON for JavaScript data**:
```ruby
# SAFE - properly escaped for JavaScript
<script>
  var message = <%= @message.to_json %>;
  var user = <%= @user.to_json %>;
</script>
```

**4. Use data attributes**:
```ruby
# SAFE - let Rails handle escaping
<div data-message="<%= @message %>">
</div>

<script>
  const message = document.querySelector('[data-message]').dataset.message;
</script>
```

**5. Use content_security_policy**:
```ruby
# config/initializers/content_security_policy.rb
Rails.application.config.content_security_policy do |policy|
  policy.default_src :self
  policy.script_src  :self, :https
  policy.style_src   :self, :https
end
```

### Detection Strategy

**In code review, search for**:
- `.html_safe` on user-generated content
- `raw()` helper usage
- User input in `<script>` tags
- `sanitize()` without restricted tags
- Direct rendering of params in views

---

## Mass Assignment

**Risk**: Attackers can modify fields they shouldn't have access to (e.g., admin flags, prices).

### Vulnerable Patterns

**1. No strong parameters**:
```ruby
# DANGEROUS - allows any parameter
def create
  @user = User.create(params[:user])
end
```

**2. Using permit!**:
```ruby
# DANGEROUS - permits everything
def create
  @user = User.create(user_params)
end

private

def user_params
  params.require(:user).permit!  # Allows ALL attributes
end
```

**3. Direct assignment of params**:
```ruby
# DANGEROUS
def update
  current_user.attributes = params[:user]
  current_user.save
end
```

**4. Bypassing strong parameters**:
```ruby
# DANGEROUS
def create
  @product = Product.new
  params[:product].each do |key, value|
    @product.send("#{key}=", value)  # Allows any attribute
  end
  @product.save
end
```

### Safe Alternatives

**1. Use strong parameters**:
```ruby
# SAFE - explicitly permit attributes
def create
  @user = User.create(user_params)
end

private

def user_params
  params.require(:user).permit(:name, :email, :bio)
end
```

**2. Conditional permissions**:
```ruby
# SAFE - different permissions for admins
def user_params
  if current_user.admin?
    params.require(:user).permit(:name, :email, :role, :status)
  else
    params.require(:user).permit(:name, :email)
  end
end
```

**3. Nested attributes**:
```ruby
# SAFE - permit nested attributes
def post_params
  params.require(:post).permit(
    :title,
    :body,
    comments_attributes: [:id, :body, :_destroy]
  )
end
```

**4. Use form objects for complex scenarios**:
```ruby
# SAFE - explicit attribute handling
class UserRegistrationForm
  include ActiveModel::Model

  attr_accessor :name, :email, :password

  validates :name, :email, :password, presence: true

  def save
    return false unless valid?

    User.create!(
      name: name,
      email: email,
      password: password,
      role: 'user'  # Hardcoded, not from params
    )
  end
end
```

### Detection Strategy

**In code review, search for**:
- `params[:model]` without strong parameters
- `.permit!` usage
- Direct assignment: `model.attributes = params`
- Dynamic attribute assignment with `send()`
- Missing authorization checks on sensitive fields

---

## Authentication & Authorization

### Authentication Issues

**1. Weak password requirements**:
```ruby
# WEAK
validates :password, length: { minimum: 4 }

# BETTER
validates :password,
          length: { minimum: 12 },
          format: {
            with: /(?=.*[a-z])(?=.*[A-Z])(?=.*\d)/,
            message: "must include lowercase, uppercase, and number"
          }
```

**2. Storing passwords in plain text**:
```ruby
# DANGEROUS
def password=(value)
  self[:password] = value  # Never store plain text!
end

# SAFE - use has_secure_password
class User < ApplicationRecord
  has_secure_password

  validates :password, length: { minimum: 12 }, if: :password_digest_changed?
end
```

**3. Predictable password reset tokens**:
```ruby
# DANGEROUS
def generate_reset_token
  self.reset_token = id.to_s + Time.now.to_i.to_s  # Predictable!
end

# SAFE
def generate_reset_token
  self.reset_token = SecureRandom.urlsafe_base64(32)
  self.reset_token_expires_at = 2.hours.from_now
end
```

### Authorization Issues

**1. Missing authorization checks**:
```ruby
# DANGEROUS - no authorization
def destroy
  @post = Post.find(params[:id])
  @post.destroy
  redirect_to posts_path
end

# SAFE - verify ownership
def destroy
  @post = current_user.posts.find(params[:id])  # Scoped to user
  @post.destroy
  redirect_to posts_path
end
```

**2. Inconsistent authorization**:
```ruby
# DANGEROUS - authorization only on some actions
class PostsController < ApplicationController
  before_action :authorize_user, only: [:edit, :update]
  # Missing authorization on destroy!

  def destroy
    @post = Post.find(params[:id])
    @post.destroy
  end
end
```

**3. Client-side authorization only**:
```ruby
# DANGEROUS - client can bypass this
<% if current_user.admin? %>
  <%= link_to "Delete", post_path(@post), method: :delete %>
<% end %>

# Controller MUST also check
def destroy
  return head :forbidden unless current_user.admin?
  @post = Post.find(params[:id])
  @post.destroy
end
```

**4. Use authorization gems**:
```ruby
# Use Pundit for consistent authorization
class PostPolicy
  attr_reader :user, :post

  def initialize(user, post)
    @user = user
    @post = post
  end

  def destroy?
    user.admin? || post.user == user
  end
end

class PostsController < ApplicationController
  def destroy
    @post = Post.find(params[:id])
    authorize @post  # Pundit checks PostPolicy#destroy?
    @post.destroy
    redirect_to posts_path
  end
end
```

### Detection Strategy

**In code review, check for**:
- Actions modifying data without authorization
- Password validations (length, complexity)
- Plain text password storage
- Missing scoping to current user
- Authorization logic inconsistency

---

## CSRF (Cross-Site Request Forgery)

**Risk**: Attackers can trick users into performing unwanted actions.

### Protection

**1. CSRF tokens (enabled by default)**:
```ruby
# app/controllers/application_controller.rb
class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception  # Default in Rails
end
```

**2. Don't disable CSRF protection**:
```ruby
# DANGEROUS - disables CSRF protection
class ApiController < ApplicationController
  skip_before_action :verify_authenticity_token  # Only for APIs with other auth
end
```

**3. Use proper HTTP verbs**:
```ruby
# BAD - state-changing action with GET
get '/users/:id/delete', to: 'users#destroy'

# GOOD - use DELETE
delete '/users/:id', to: 'users#destroy'
```

---

## Session Management

**1. Secure session cookies**:
```ruby
# config/initializers/session_store.rb
Rails.application.config.session_store :cookie_store,
  key: '_app_session',
  secure: Rails.env.production?,  # HTTPS only in production
  httponly: true,                  # Not accessible via JavaScript
  same_site: :lax                  # CSRF protection
```

**2. Session fixation protection**:
```ruby
# SAFE - Rails resets session on login by default
def create
  user = User.find_by(email: params[:email])
  if user&.authenticate(params[:password])
    reset_session  # Important: prevent session fixation
    session[:user_id] = user.id
    redirect_to root_path
  end
end
```

**3. Session timeout**:
```ruby
# Add session expiration
class ApplicationController < ActionController::Base
  before_action :check_session_expiry

  private

  def check_session_expiry
    if session[:expires_at] && session[:expires_at] < Time.current
      reset_session
      redirect_to login_path, alert: 'Session expired'
    else
      session[:expires_at] = 30.minutes.from_now
    end
  end
end
```

---

## File Upload Security

**1. Validate file types**:
```ruby
# DANGEROUS - trusts client-provided content type
def create
  if params[:file].content_type == 'image/jpeg'
    # Client can lie about content type!
  end
end

# BETTER - validate actual file content
class ImageUploader < CarrierWave::Uploader::Base
  def content_type_whitelist
    /image\//
  end

  def extension_whitelist
    %w(jpg jpeg gif png)
  end
end
```

**2. Scan uploaded files**:
```ruby
# Use ClamAV or similar to scan for malware
class DocumentUploader < CarrierWave::Uploader::Base
  before :cache, :scan_for_viruses

  def scan_for_viruses(file)
    result = `clamscan #{file.path}`
    raise SecurityError, 'Virus detected' if $?.exitstatus != 0
  end
end
```

**3. Store uploads outside web root**:
```ruby
# Don't store in public/ - use cloud storage
class AvatarUploader < CarrierWave::Uploader::Base
  storage :fog  # AWS S3, etc.

  def store_dir
    "uploads/#{model.class.to_s.underscore}/#{mounted_as}/#{model.id}"
  end
end
```

**4. Limit file sizes**:
```ruby
class AvatarUploader < CarrierWave::Uploader::Base
  def size_range
    1..5.megabytes
  end
end
```

---

## API Security

**1. Use API authentication**:
```ruby
# Use tokens, not session cookies for APIs
class Api::BaseController < ActionController::API
  before_action :authenticate_api_user

  private

  def authenticate_api_user
    token = request.headers['Authorization']&.split(' ')&.last
    @current_user = User.find_by(api_token: token)
    head :unauthorized unless @current_user
  end
end
```

**2. Rate limiting**:
```ruby
# Use Rack::Attack for rate limiting
class Rack::Attack
  throttle('api/ip', limit: 300, period: 5.minutes) do |req|
    req.ip if req.path.start_with?('/api/')
  end

  throttle('api/token', limit: 100, period: 1.minute) do |req|
    req.env['HTTP_AUTHORIZATION'] if req.path.start_with?('/api/')
  end
end
```

**3. Validate content types**:
```ruby
class Api::PostsController < Api::BaseController
  before_action :verify_content_type

  private

  def verify_content_type
    unless request.content_type == 'application/json'
      head :unsupported_media_type
    end
  end
end
```

---

## Input Validation

**1. Validate all inputs**:
```ruby
class User < ApplicationRecord
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :age, numericality: { only_integer: true, greater_than: 0 }
  validates :website, format: { with: /\Ahttps?:\/\// }, allow_blank: true
end
```

**2. Sanitize inputs**:
```ruby
# Remove dangerous characters
before_validation :sanitize_inputs

def sanitize_inputs
  self.name = name.strip if name.present?
  self.bio = ActionController::Base.helpers.sanitize(bio) if bio.present?
end
```

---

## Security Review Checklist

**For every code review, check**:

**SQL Injection**:
- [ ] No string interpolation in SQL
- [ ] Parameterized queries used
- [ ] Hash conditions for simple queries

**XSS**:
- [ ] No `.html_safe` on user input
- [ ] No `raw()` on user input
- [ ] Proper escaping in JavaScript contexts
- [ ] Content Security Policy configured

**Mass Assignment**:
- [ ] Strong parameters used
- [ ] No `.permit!` usage
- [ ] Sensitive fields not accessible

**Authentication**:
- [ ] Strong password requirements
- [ ] Passwords hashed (has_secure_password)
- [ ] Secure token generation
- [ ] Session reset on login

**Authorization**:
- [ ] Authorization checks on all actions
- [ ] Consistent authorization approach
- [ ] Scoped queries to current user
- [ ] Server-side authorization (not just client-side)

**CSRF**:
- [ ] CSRF protection enabled
- [ ] Proper HTTP verbs used
- [ ] State changes require POST/PUT/DELETE

**Sessions**:
- [ ] Secure cookie settings
- [ ] Session timeout implemented
- [ ] Session fixation prevention

**File Uploads**:
- [ ] File type validation
- [ ] File size limits
- [ ] Stored outside web root
- [ ] Virus scanning for user uploads

**API Security**:
- [ ] Token-based authentication
- [ ] Rate limiting implemented
- [ ] Content type validation

**General**:
- [ ] Input validation on all user data
- [ ] Proper error handling (don't leak info)
- [ ] Dependencies up to date (check `bundle audit`)
- [ ] Secrets in credentials, not code
