# Multi-Tenant Application Template (Worked Example)

A complete application template that turns a Rails starter app into a SaaS-ready multi-tenant platform: Organizations as tenants, role-based Memberships, email invitations, and automatic data isolation via [acts_as_tenant](https://github.com/ErwinM/acts_as_tenant).

**Tenancy approach**: use the `acts_as_tenant` gem, not hand-rolled `organization_id` scoping. The gem gives default-scope isolation (an unscoped query cannot leak another tenant's rows), automatic assignment on create, and uniqueness validation scoped to the tenant — guarantees a controller concern can't match.

## Table of Contents

- [Architecture](#architecture)
- [Template Skeleton](#template-skeleton)
- [Tenant Model: Organization](#tenant-model-organization)
- [Membership: Roles and Invitations](#membership-roles-and-invitations)
- [Tenant Selection from the URL](#tenant-selection-from-the-url)
- [Scoping Models](#scoping-models)
- [Registration Flow](#registration-flow)
- [Background Jobs](#background-jobs)
- [Testing](#testing)

## Architecture

```text
User ──< Membership >── Organization (the tenant)
              │
              └── role: admin | member | viewer
                  + invitation fields (token, email, expiry)

Tenant-scoped models:  acts_as_tenant(:organization)
Tenant selection:      URL (/organizations/:organization_slug/...) via set_current_tenant_through_filter
```

- **Organization** is the tenant model (not the gem's default `Account` — after running any gem installer, rename generated `Account` references to `Organization`).
- **Membership** joins Users to Organizations and carries the role; authorization (e.g. Action Policy) reads roles from it.
- Every tenant-owned model declares `acts_as_tenant(:organization)`; queries are then scoped automatically.

## Template Skeleton

```ruby
# multitenant_template.rb — apply with:
#   rails new myapp -m multitenant_template.rb
#   bin/rails app:template LOCATION=multitenant_template.rb

def source_paths
  [__dir__]
end

# Idempotency guard — see application-templates.md
if File.exist?('app/models/organization.rb')
  say '❌ Multi-tenant template already applied.', :red
  exit 1
end

say '📦 Adding gems...'
gem 'devise', comment: 'Authentication (https://github.com/heartcombo/devise)'
gem 'acts_as_tenant', comment: 'Row-level multi-tenancy (https://github.com/ErwinM/acts_as_tenant)'
gem_group :development do
  gem 'letter_opener', comment: 'Preview email in the browser'
end
run 'bundle install'

say '🔐 Installing Devise via its own generators...'
generate 'devise:install'
generate 'devise', 'User'
generate 'devise:views'
environment "config.action_mailer.default_url_options = { host: 'localhost', port: 3000 }",
            env: 'development'

say '🏢 Creating tenant models...'
generate 'model', 'Organization', 'name:string:uniq', 'slug:string:uniq', 'description:text'
generate 'model', 'Membership',
         'organization:references', 'user:references',
         'role:string', 'invited_by:references',
         'invitation_token:string:uniq', 'invited_email:string',
         'invitation_expires_at:datetime'

# ... model bodies, controller filter, routes (sections below) ...

rails_command 'db:migrate'
run 'bundle exec rspec'
say '✅ Multi-tenant setup complete!', :green
```

Note the template runs each gem's own install generator (`devise:install`, `generate 'devise', 'User'`) instead of hand-writing initializers — see [application-templates.md](application-templates.md#prefer-gem-installers-over-hand-rolled-setup).

## Tenant Model: Organization

```ruby
create_file 'app/models/organization.rb', <<~RUBY, force: true
  class Organization < ApplicationRecord
    acts_as_tenant

    validates :name, presence: true, uniqueness: true
    validates :slug, presence: true, uniqueness: true

    has_many :memberships, dependent: :destroy
    has_many :users, through: :memberships

    scope :ordered, -> { order(:name) }

    def to_param = slug
  end
RUBY
```

## Membership: Roles and Invitations

Membership carries both the role (feeding role-based authorization) and the invitation lifecycle. Membership is deliberately **not** tenant-scoped with `acts_as_tenant` — it is the join that defines who belongs to a tenant, and it must be queryable across tenants (e.g. finding an invitation by token before the user has a tenant).

```ruby
create_file 'app/models/membership.rb', force: true do
  <<~'RUBY'
    class Membership < ApplicationRecord
      ROLES = %w[admin member viewer].freeze

      belongs_to :organization
      belongs_to :user, optional: true
      belongs_to :invited_by, class_name: 'User', optional: true

      validates :role, presence: true, inclusion: { in: ROLES }
      validates :user_id, uniqueness: { scope: :organization_id }, if: :user_id?
      validates :invited_email, presence: true,
                uniqueness: { scope: :organization_id }, if: :pending_invitation?

      scope :active,  -> { where.not(user_id: nil) }
      scope :pending, -> { where(user_id: nil) }

      before_validation :generate_invitation_token, if: :pending_invitation?
      before_validation :set_invitation_expiry, if: :pending_invitation?

      def pending_invitation? = user_id.nil? && invited_email.present?
      def admin?  = role == 'admin'
      def member? = role == 'member'
      def viewer? = role == 'viewer'

      def invitation_expired?
        pending_invitation? && invitation_expires_at&.past?
      end

      def accept_invitation!(user)
        return false unless pending_invitation? && !invitation_expired?

        update!(user: user, invitation_token: nil,
                invited_email: nil, invitation_expires_at: nil)
      end

      private

      def generate_invitation_token
        self.invitation_token = SecureRandom.urlsafe_base64(32)
      end

      def set_invitation_expiry
        self.invitation_expires_at ||= 7.days.from_now
      end
    end
  RUBY
end
```

Key migration indexes (add to the generated migration):

```ruby
add_index :memberships, [:organization_id, :user_id],
          unique: true, where: 'user_id IS NOT NULL'
add_index :memberships, [:organization_id, :invited_email],
          unique: true, where: 'user_id IS NULL'
```

The partial indexes allow the same email to hold pending invitations in different organizations while preventing duplicates within one.

Convenience methods on User:

```ruby
inject_into_file 'app/models/user.rb', after: "class User < ApplicationRecord\n" do
  <<-RUBY
  has_many :memberships, dependent: :destroy
  has_many :organizations, through: :memberships
  has_many :sent_invitations, class_name: 'Membership', foreign_key: 'invited_by_id'

  def admin_of?(organization)
    memberships.find_by(organization: organization)&.admin?
  end

  def member_of?(organization)
    memberships.exists?(organization: organization)
  end
  RUBY
end
```

> **Alternative**: [devise_invitable](https://github.com/scambra/devise_invitable) manages invitations at the User level via its own generator (`generate 'devise_invitable:install'`, `generate 'devise_invitable', 'User'`). Use it when invitations should create user accounts directly; keep the Membership-token approach above when an existing user can be invited into additional organizations.

## Tenant Selection from the URL

The tenant comes from the URL, so links are shareable and a user can be active in different organizations in different tabs.

```ruby
inject_into_file 'app/controllers/application_controller.rb',
                 after: "class ApplicationController < ActionController::Base\n" do
  <<-RUBY
  set_current_tenant_through_filter
  before_action :set_current_organization

  private

  def set_current_organization
    slug = params[:organization_slug] || params[:organization_id]
    organization = slug && current_user&.organizations&.find_by(slug: slug)

    if slug && organization.nil?
      raise ActiveRecord::RecordNotFound  # member-only access; renders 404
    end

    set_current_tenant(organization)
  end

  def current_organization = ActsAsTenant.current_tenant
  helper_method :current_organization
  RUBY
end
```

Looking the organization up through `current_user.organizations` (not `Organization.find_by`) makes membership itself the access check — non-members get a 404, not a 403 that confirms the organization exists.

Routes nest tenant-owned resources under the organization:

```ruby
route <<~RUBY
  devise_for :users, controllers: { registrations: 'users/registrations' }

  get 'invitations/:token/accept', to: 'memberships#accept', as: :accept_invitation

  resources :organizations, param: :slug do
    resources :memberships, except: %i[show new edit]
    resources :projects   # tenant-scoped resources nest here
  end

  authenticated :user do
    root to: 'organizations#index', as: :authenticated_root
  end
RUBY
```

## Scoping Models

Every tenant-owned model declares the scope; controllers then use plain ActiveRecord:

```ruby
class Project < ApplicationRecord
  acts_as_tenant(:organization)

  # Tenant-scoped uniqueness — plain `uniqueness: true` would collide across tenants
  validates :name, uniqueness: { scope: :organization_id }
end
```

```ruby
class ProjectsController < ApplicationController
  def index
    @projects = Project.all      # scoped to current tenant automatically
  end

  def create
    @project = Project.new(project_params)  # organization_id assigned automatically
    ...
  end
end
```

The template can offer this as a follow-up generator for new resources, or teams add the one line by hand. Migrations for tenant-scoped tables should make the foreign key mandatory:

```ruby
add_reference :projects, :organization, null: false, foreign_key: true
```

Use `null: true` only for tables that intentionally hold public/untenanted rows — and know that `acts_as_tenant` still hides those rows whenever a tenant is set.

## Registration Flow

New sign-ups either accept a pending invitation (token stashed in the session) or get a personal organization created for them:

```ruby
create_file 'app/controllers/users/registrations_controller.rb', <<~'RUBY'
  class Users::RegistrationsController < Devise::RegistrationsController
    protected

    def after_sign_up_path_for(user)
      membership = Membership.find_by(invitation_token: session.delete(:invitation_token))

      if membership&.accept_invitation!(user)
        organization_path(membership.organization)
      else
        organization = ActsAsTenant.without_tenant do
          Organization.create!(name: "#{user.email}'s Organization",
                               slug: SecureRandom.hex(4)).tap do |org|
            org.memberships.create!(user: user, role: 'admin')
          end
        end
        organization_path(organization)
      end
    end
  end
RUBY
```

The invitation-acceptance endpoint (`memberships#accept`) finds the membership by token, accepts directly for signed-in users, and stores the token in the session before redirecting guests to sign-up. Send invitation emails from a mailer with `deliver_later`, and add `letter_opener` in development to preview them.

## Background Jobs

`ActsAsTenant.current_tenant` is per-request; jobs must set it explicitly:

```ruby
class SyncProjectsJob < ApplicationJob
  def perform(organization)
    ActsAsTenant.with_tenant(organization) do
      Project.find_each(&:sync!)   # scoped to organization
    end
  end
end
```

Pass the organization (or its id) as a job argument — never rely on ambient tenant state surviving into the job. For maintenance scripts that legitimately cross tenants, use `ActsAsTenant.without_tenant { ... }`.

## Testing

Factories:

```ruby
FactoryBot.define do
  factory :organization do
    sequence(:name) { |n| "Organization #{n}" }
    sequence(:slug) { |n| "org-#{n}" }
  end

  factory :membership do
    organization
    user
    role { 'member' }

    trait :admin   { role { 'admin' } }
    trait :pending do
      user { nil }
      sequence(:invited_email) { |n| "invited#{n}@example.com" }
    end
    trait :expired do
      pending
      invitation_expires_at { 1.hour.ago }
    end
  end
end
```

Set a test tenant globally so model specs don't fail tenant-presence validations, and override per-example when testing isolation:

```ruby
# spec/rails_helper.rb
RSpec.configure do |config|
  config.include Devise::Test::IntegrationHelpers, type: :request

  config.before(:suite) { ActsAsTenant.test_tenant = FactoryBot.create(:organization) }
  config.after(:suite)  { ActsAsTenant.test_tenant = nil }
end
```

The test that matters most — isolation actually holds:

```ruby
RSpec.describe 'tenant isolation', type: :request do
  let(:org_a) { create(:organization) }
  let(:org_b) { create(:organization) }
  let(:user)  { create(:user) }

  before { create(:membership, user: user, organization: org_a) }

  it 'hides other tenants\' records' do
    project_b = ActsAsTenant.with_tenant(org_b) { create(:project) }

    sign_in user
    get organization_projects_path(org_a)
    expect(response.body).not_to include(project_b.name)
  end

  it 'returns 404 for organizations the user does not belong to' do
    sign_in user
    get organization_projects_path(org_b)
    expect(response).to have_http_status(:not_found)
  end
end
```

Finish the template by running migrations and the full suite (`rails_command 'db:migrate'`, `run 'bundle exec rspec'`) so a broken apply fails immediately.

## Sources

- [acts_as_tenant README](https://github.com/ErwinM/acts_as_tenant)
- [Rails Application Templates — Ruby on Rails Guides](https://guides.rubyonrails.org/rails_application_templates.html)
- [Devise](https://github.com/heartcombo/devise) / [devise_invitable](https://github.com/scambra/devise_invitable)
