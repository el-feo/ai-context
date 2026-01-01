# Rails-Specific Testing with RSpec

Guide to testing Rails applications with RSpec Rails, covering all spec types and Rails integrations.

## Table of Contents

1. [Model Specs](#model-specs)
2. [Request Specs](#request-specs)
3. [System Specs](#system-specs)
4. [Mailer Specs](#mailer-specs)
5. [Job Specs](#job-specs)
6. [Helper Specs](#helper-specs)
7. [View Specs](#view-specs)
8. [Routing Specs](#routing-specs)

## Model Specs

Test ActiveRecord models, validations, associations, and business logic.

### Basic Structure

```ruby
# spec/models/user_spec.rb
RSpec.describe User, type: :model do
  describe 'validations' do
    it { should validate_presence_of(:email) }
    it { should validate_uniqueness_of(:email).case_insensitive }
  end
  
  describe 'associations' do
    it { should have_many(:articles) }
    it { should belong_to(:account) }
  end
  
  describe '#full_name' do
    it 'returns first and last name' do
      user = User.new(first_name: 'John', last_name: 'Doe')
      expect(user.full_name).to eq('John Doe')
    end
  end
end
```

### Testing Validations

```ruby
describe 'validations' do
  # Using shoulda-matchers gem (recommended)
  it { should validate_presence_of(:email) }
  it { should validate_length_of(:password).is_at_least(8) }
  it { should validate_numericality_of(:age).is_greater_than(0) }
  it { should validate_inclusion_of(:role).in_array(['user', 'admin']) }
  
  # Custom validation testing
  context 'email format' do
    it 'accepts valid email' do
      user = User.new(email: 'test@example.com')
      expect(user).to be_valid
    end
    
    it 'rejects invalid email' do
      user = User.new(email: 'invalid')
      expect(user).not_to be_valid
      expect(user.errors[:email]).to include('is invalid')
    end
  end
end
```

### Testing Associations

```ruby
describe 'associations' do
  # Using shoulda-matchers
  it { should belong_to(:author).class_name('User') }
  it { should have_many(:comments).dependent(:destroy) }
  it { should have_one(:profile) }
  it { should have_many(:tags).through(:taggings) }
  
  # Testing association behavior
  describe 'comments association' do
    it 'deletes comments when article is deleted' do
      article = create(:article)
      comment = create(:comment, article: article)
      
      expect { article.destroy }.to change(Comment, :count).by(-1)
    end
  end
end
```

### Testing Scopes

```ruby
describe '.published' do
  it 'returns only published articles' do
    published = create(:article, published: true)
    draft = create(:article, published: false)
    
    expect(Article.published).to include(published)
    expect(Article.published).not_to include(draft)
  end
  
  it 'orders by publish date descending' do
    older = create(:article, publish_date: 2.days.ago)
    newer = create(:article, publish_date: 1.day.ago)
    
    expect(Article.published).to eq([newer, older])
  end
end
```

### Testing Callbacks

```ruby
describe 'callbacks' do
  describe 'after_create' do
    it 'sends welcome email' do
      expect {
        create(:user)
      }.to have_enqueued_job(SendWelcomeEmailJob)
    end
  end
  
  describe 'before_validation' do
    it 'normalizes email' do
      user = create(:user, email: 'USER@EXAMPLE.COM')
      expect(user.email).to eq('user@example.com')
    end
  end
end
```

## Request Specs

Test HTTP requests and responses, preferred over controller specs.

### Basic Structure

```ruby
# spec/requests/articles_spec.rb
RSpec.describe 'Articles', type: :request do
  describe 'GET /articles' do
    it 'returns success' do
      get articles_path
      expect(response).to have_http_status(:success)
    end
    
    it 'renders articles' do
      create_list(:article, 3)
      get articles_path
      
      expect(response.body).to include('Articles')
    end
  end
end
```

### Testing CRUD Operations

```ruby
describe 'POST /articles' do
  context 'with valid params' do
    let(:valid_params) do
      { article: { title: 'Test', body: 'Content' } }
    end
    
    it 'creates article' do
      expect {
        post articles_path, params: valid_params
      }.to change(Article, :count).by(1)
    end
    
    it 'returns created status' do
      post articles_path, params: valid_params
      expect(response).to have_http_status(:created)
    end
    
    it 'redirects to article' do
      post articles_path, params: valid_params
      expect(response).to redirect_to(article_path(Article.last))
    end
  end
  
  context 'with invalid params' do
    let(:invalid_params) do
      { article: { title: '' } }
    end
    
    it 'does not create article' do
      expect {
        post articles_path, params: invalid_params
      }.not_to change(Article, :count)
    end
    
    it 'returns unprocessable entity' do
      post articles_path, params: invalid_params
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end
end
```

### Testing JSON APIs

```ruby
describe 'GET /api/articles', type: :request do
  let(:headers) do
    {
      'Accept' => 'application/json',
      'Content-Type' => 'application/json'
    }
  end
  
  it 'returns JSON' do
    create_list(:article, 2)
    get '/api/articles', headers: headers
    
    expect(response.content_type).to match(/application\/json/)
    
    json = JSON.parse(response.body)
    expect(json['articles'].size).to eq(2)
    expect(json['articles'].first).to have_key('title')
  end
end
```

### Testing Authentication

```ruby
describe 'authentication' do
  context 'when not authenticated' do
    it 'returns unauthorized' do
      post articles_path, params: { article: { title: 'Test' } }
      expect(response).to have_http_status(:unauthorized)
    end
  end
  
  context 'when authenticated' do
    let(:user) { create(:user) }
    let(:headers) { { 'Authorization' => "Bearer #{user.token}" } }
    
    it 'allows access' do
      post articles_path,
        params: { article: { title: 'Test' } },
        headers: headers
        
      expect(response).to have_http_status(:created)
    end
  end
end
```

## System Specs

End-to-end browser testing with Capybara.

### Basic Structure

```ruby
# spec/system/articles_spec.rb
RSpec.describe 'Articles', type: :system do
  before do
    driven_by(:selenium_chrome_headless)
  end
  
  scenario 'user creates article' do
    visit new_article_path
    
    fill_in 'Title', with: 'My Article'
    fill_in 'Body', with: 'Content here'
    click_button 'Create Article'
    
    expect(page).to have_content('Article created')
    expect(page).to have_content('My Article')
  end
end
```

### Capybara Interactions

```ruby
# Navigation
visit root_path
visit '/articles/new'
click_link 'New Article'
click_button 'Submit'

# Form inputs
fill_in 'Email', with: 'test@example.com'
fill_in 'user_email', with: 'test@example.com'  # By ID
choose 'option_2'                              # Radio button
check 'Accept terms'                           # Checkbox
uncheck 'Subscribe'
select 'Option', from: 'Dropdown'
attach_file 'Avatar', '/path/to/file.jpg'

# Assertions
expect(page).to have_content('Text')
expect(page).to have_css('.alert')
expect(page).to have_selector('h1', text: 'Title')
expect(page).to have_link('Click here')
expect(page).to have_button('Submit')
expect(page).to have_field('Email')
expect(page).to have_checked_field('Remember me')
expect(page).to have_current_path(root_path)
```

### Testing JavaScript

```ruby
scenario 'user filters articles', js: true do
  create(:article, title: 'Ruby Article', category: 'ruby')
  create(:article, title: 'Python Article', category: 'python')
  
  visit articles_path
  
  select 'Ruby', from: 'Category'
  
  expect(page).to have_content('Ruby Article')
  expect(page).not_to have_content('Python Article')
end

# Configure JS driver in rails_helper.rb
RSpec.configure do |config|
  config.before(:each, type: :system, js: true) do
    driven_by :selenium_chrome_headless
  end
end
```

### Debugging System Specs

```ruby
scenario 'debugging example' do
  visit articles_path
  
  # Take screenshot
  save_screenshot('debug.png')
  
  # Open page in browser
  save_and_open_screenshot
  
  # Print page HTML
  puts page.html
  
  # Use pry for debugging
  binding.pry
end
```

## Mailer Specs

Test email delivery and content.

### Basic Structure

```ruby
# spec/mailers/user_mailer_spec.rb
RSpec.describe UserMailer, type: :mailer do
  describe '#welcome_email' do
    let(:user) { create(:user, name: 'John', email: 'john@example.com') }
    let(:mail) { UserMailer.welcome_email(user) }
    
    it 'renders subject' do
      expect(mail.subject).to eq('Welcome to MyApp!')
    end
    
    it 'renders receiver email' do
      expect(mail.to).to eq(['john@example.com'])
    end
    
    it 'renders sender email' do
      expect(mail.from).to eq(['noreply@myapp.com'])
    end
    
    it 'includes user name' do
      expect(mail.body.encoded).to include('John')
    end
    
    it 'includes activation link' do
      expect(mail.body.encoded).to include(activate_url(user.token))
    end
  end
end
```

### Testing Attachments

```ruby
describe 'attachments' do
  it 'includes PDF attachment' do
    expect(mail.attachments.size).to eq(1)
    expect(mail.attachments.first.filename).to eq('report.pdf')
    expect(mail.attachments.first.content_type).to match(/application\/pdf/)
  end
end
```

### Testing Email Delivery

```ruby
describe 'delivery' do
  it 'delivers email' do
    expect {
      UserMailer.welcome_email(user).deliver_now
    }.to change { ActionMailer::Base.deliveries.size }.by(1)
  end
  
  it 'enqueues email job' do
    expect {
      UserMailer.welcome_email(user).deliver_later
    }.to have_enqueued_job(ActionMailer::MailDeliveryJob)
  end
end
```

## Job Specs

Test ActiveJob background jobs.

### Basic Structure

```ruby
# spec/jobs/send_email_job_spec.rb
RSpec.describe SendEmailJob, type: :job do
  describe '#perform' do
    let(:user) { create(:user) }
    
    it 'sends email' do
      expect {
        SendEmailJob.perform_now(user)
      }.to change { ActionMailer::Base.deliveries.size }.by(1)
    end
    
    it 'enqueues job' do
      expect {
        SendEmailJob.perform_later(user)
      }.to have_enqueued_job(SendEmailJob).with(user)
    end
  end
end
```

### Testing Job Queue

```ruby
it 'enqueues to correct queue' do
  expect {
    SendEmailJob.perform_later(user)
  }.to have_enqueued_job.on_queue('mailers')
end

it 'schedules job for later' do
  expect {
    SendEmailJob.set(wait: 1.hour).perform_later(user)
  }.to have_enqueued_job.at(1.hour.from_now)
end
```

## Helper Specs

Test view helpers.

### Basic Structure

```ruby
# spec/helpers/application_helper_spec.rb
RSpec.describe ApplicationHelper, type: :helper do
  describe '#format_date' do
    it 'formats date' do
      date = Date.new(2024, 1, 15)
      expect(helper.format_date(date)).to eq('January 15, 2024')
    end
    
    it 'returns empty string for nil' do
      expect(helper.format_date(nil)).to eq('')
    end
  end
end
```

## View Specs

Test view templates (use system specs instead when possible).

### Basic Structure

```ruby
# spec/views/articles/show.html.erb_spec.rb
RSpec.describe 'articles/show', type: :view do
  it 'displays article title' do
    article = create(:article, title: 'Test Title')
    assign(:article, article)
    
    render
    
    expect(rendered).to have_content('Test Title')
  end
end
```

## Routing Specs

Test route configuration (usually not needed).

### Basic Structure

```ruby
# spec/routing/articles_routing_spec.rb
RSpec.describe 'articles routing', type: :routing do
  it 'routes to articles#index' do
    expect(get: '/articles').to route_to('articles#index')
  end
  
  it 'routes to articles#show' do
    expect(get: '/articles/1').to route_to(
      controller: 'articles',
      action: 'show',
      id: '1'
    )
  end
  
  it 'does not route invalid path' do
    expect(get: '/invalid').not_to be_routable
  end
end
```

## Common Patterns

### Testing Pagination

```ruby
describe 'pagination' do
  it 'paginates results' do
    create_list(:article, 30)
    
    get articles_path, params: { page: 2 }
    
    expect(assigns(:articles).count).to eq(25)  # Default per page
  end
end
```

### Testing File Uploads

```ruby
describe 'file upload' do
  it 'attaches file to record' do
    file = fixture_file_upload('avatar.jpg', 'image/jpeg')
    
    post '/profile/avatar', params: { avatar: file }
    
    expect(User.last.avatar).to be_attached
  end
end
```

### Testing Search

```ruby
describe 'search' do
  before do
    create(:article, title: 'Ruby Guide')
    create(:article, title: 'Python Guide')
  end
  
  it 'finds articles by title' do
    get search_articles_path, params: { q: 'Ruby' }
    
    expect(assigns(:articles).map(&:title)).to include('Ruby Guide')
    expect(assigns(:articles).map(&:title)).not_to include('Python Guide')
  end
end
```
