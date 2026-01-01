# Chapters

This guide covers how to attach files to your Active Record models.

After reading this guide, you will know:

- How to attach one or many files to a record.

- How to delete an attached file.

- How to link to an attached file.

- How to use variants to transform images.

- How to generate an image representation of a non-image file, such as a PDF or a video.

- How to send file uploads directly from browsers to a storage service,
bypassing your application servers.

- How to clean up files stored during testing.

- How to implement support for additional storage services.

## 1. What is Active Storage?

Active Storage facilitates uploading files to a cloud storage service like
Amazon S3, or Google Cloud Storage and attaching those
files to Active Record objects. It comes with a local disk-based service for
development and testing and supports mirroring files to subordinate services for
backups and migrations.

Using Active Storage, an application can transform image uploads or generate image
representations of non-image uploads like PDFs and videos, and extract metadata from
arbitrary files.

### 1.1. Requirements

Various features of Active Storage depend on third-party software which Rails
will not install, and must be installed separately:

- libvips v8.6+ or ImageMagick for image analysis and transformations

- ffmpeg v3.4+ for video previews and ffprobe for video/audio analysis

- poppler or muPDF for PDF previews

Compared to libvips, ImageMagick is better known and more widely available. However, libvips can be up to 10x faster and consume 1/10 the memory. For JPEG files, this can be further improved by replacing libjpeg-dev with libjpeg-turbo-dev, which is 2-7x faster.

Before you install and use third-party software, make sure you understand the licensing implications of doing so. MuPDF, in particular, is licensed under AGPL and requires a commercial license for some use.

## 2. Setup

```bash
bin/rails active_storage:install
bin/rails db:migrate
```

This sets up configuration, and creates the three tables Active Storage uses:
active_storage_blobs, active_storage_attachments, and active_storage_variant_records.

If you are using UUIDs instead of integers as the primary key on your models, you should set Rails.application.config.generators { |g| g.orm :active_record, primary_key_type: :uuid } in a config file.

Declare Active Storage services in config/storage.yml. For each service your
application uses, provide a name and the requisite configuration. The example
below declares three services named local, test, and amazon:

```yaml
local:
  service: Disk
  root: <%= Rails.root.join("storage") %>

test:
  service: Disk
  root: <%= Rails.root.join("tmp/storage") %>

# Use bin/rails credentials:edit to set the AWS secrets (as aws:access_key_id|secret_access_key)
amazon:
  service: S3
  access_key_id: <%= Rails.application.credentials.dig(:aws, :access_key_id) %>
  secret_access_key: <%= Rails.application.credentials.dig(:aws, :secret_access_key) %>
  bucket: your_own_bucket-<%= Rails.env %>
  region: "" # e.g. 'us-east-1'
```

Tell Active Storage which service to use by setting
Rails.application.config.active_storage.service. Because each environment will
likely use a different service, it is recommended to do this on a
per-environment basis. To use the disk service from the previous example in the
development environment, you would add the following to
config/environments/development.rb:

```ruby
# Store files locally.
config.active_storage.service = :local
```

To use the S3 service in production, you would add the following to
config/environments/production.rb:

```ruby
# Store files on Amazon S3.
config.active_storage.service = :amazon
```

To use the test service when testing, you would add the following to
config/environments/test.rb:

```ruby
# Store uploaded files on the local file system in a temporary directory.
config.active_storage.service = :test
```

Configuration files that are environment-specific will take precedence:
in production, for example, the config/storage/production.yml file (if existent)
will take precedence over the config/storage.yml file.

It is recommended to use Rails.env in the bucket names to further reduce the risk of accidentally destroying production data.

```yaml
amazon:
  service: S3
  # ...
  bucket: your_own_bucket-<%= Rails.env %>

google:
  service: GCS
  # ...
  bucket: your_own_bucket-<%= Rails.env %>
```

Continue reading for more information on the built-in service adapters (e.g.
Disk and S3) and the configuration they require.

### 2.1. Disk Service

Declare a Disk service in config/storage.yml:

```yaml
local:
  service: Disk
  root: <%= Rails.root.join("storage") %>
```

### 2.2. S3 Service (Amazon S3 and S3-compatible APIs)

To connect to Amazon S3, declare an S3 service in config/storage.yml:

```yaml
# Use bin/rails credentials:edit to set the AWS secrets (as aws:access_key_id|secret_access_key)
amazon:
  service: S3
  access_key_id: <%= Rails.application.credentials.dig(:aws, :access_key_id) %>
  secret_access_key: <%= Rails.application.credentials.dig(:aws, :secret_access_key) %>
  region: "" # e.g. 'us-east-1'
  bucket: your_own_bucket-<%= Rails.env %>
```

Optionally provide client and upload options:

```yaml
# Use bin/rails credentials:edit to set the AWS secrets (as aws:access_key_id|secret_access_key)
amazon:
  service: S3
  access_key_id: <%= Rails.application.credentials.dig(:aws, :access_key_id) %>
  secret_access_key: <%= Rails.application.credentials.dig(:aws, :secret_access_key) %>
  region: "" # e.g. 'us-east-1'
  bucket: your_own_bucket-<%= Rails.env %>
  http_open_timeout: 0
  http_read_timeout: 0
  retry_limit: 0
  upload:
    server_side_encryption: "" # 'aws:kms' or 'AES256'
    cache_control: "private, max-age=<%= 1.day.to_i %>"
```

Set sensible client HTTP timeouts and retry limits for your application. In certain failure scenarios, the default AWS client configuration may cause connections to be held for up to several minutes and lead to request queuing.

Add the aws-sdk-s3 gem to your Gemfile:

```ruby
gem "aws-sdk-s3", require: false
```

The core features of Active Storage require the following permissions: s3:ListBucket, s3:PutObject, s3:GetObject, and s3:DeleteObject. Public access additionally requires s3:PutObjectAcl. If you have additional upload options configured such as setting ACLs then additional permissions may be required.

If you want to use environment variables, standard SDK configuration files, profiles,
IAM instance profiles or task roles, you can omit the access_key_id, secret_access_key,
and region keys in the example above. The S3 Service supports all of the
authentication options described in the AWS SDK documentation.

To connect to an S3-compatible object storage API such as DigitalOcean Spaces, provide the endpoint:

```yaml
digitalocean:
  service: S3
  endpoint: https://nyc3.digitaloceanspaces.com
  access_key_id: <%= Rails.application.credentials.dig(:digitalocean, :access_key_id) %>
  secret_access_key: <%= Rails.application.credentials.dig(:digitalocean, :secret_access_key) %>
  # ...and other options
```

There are many other options available. You can check them in AWS S3 Client documentation.

### 2.3. Google Cloud Storage Service

Declare a Google Cloud Storage service in config/storage.yml:

```yaml
google:
  service: GCS
  credentials: <%= Rails.root.join("path/to/keyfile.json") %>
  project: ""
  bucket: your_own_bucket-<%= Rails.env %>
```

Optionally provide a Hash of credentials instead of a keyfile path:

```yaml
# Use bin/rails credentials:edit to set the GCS secrets (as gcs:private_key_id|private_key)
google:
  service: GCS
  credentials:
    type: "service_account"
    project_id: ""
    private_key_id: <%= Rails.application.credentials.dig(:gcs, :private_key_id) %>
    private_key: <%= Rails.application.credentials.dig(:gcs, :private_key).dump %>
    client_email: ""
    client_id: ""
    auth_uri: "https://accounts.google.com/o/oauth2/auth"
    token_uri: "https://accounts.google.com/o/oauth2/token"
    auth_provider_x509_cert_url: "https://www.googleapis.com/oauth2/v1/certs"
    client_x509_cert_url: ""
  project: ""
  bucket: your_own_bucket-<%= Rails.env %>
```

Optionally provide a Cache-Control metadata to set on uploaded assets:

```yaml
google:
  service: GCS
  ...
  cache_control: "public, max-age=3600"
```

Optionally use IAM instead of the credentials when signing URLs. This is useful if you are authenticating your GKE applications with Workload Identity, see this Google Cloud blog post for more information.

```yaml
google:
  service: GCS
  ...
  iam: true
```

Optionally use a specific GSA when signing URLs. When using IAM, the metadata server will be contacted to get the GSA email, but this metadata server is not always present (e.g. local tests) and you may wish to use a non-default GSA.

```yaml
google:
  service: GCS
  ...
  iam: true
  gsa_email: "foobar@baz.iam.gserviceaccount.com"
```

Add the google-cloud-storage gem to your Gemfile:

```ruby
gem "google-cloud-storage", "~> 1.11", require: false
```

### 2.4. Mirror Service

You can keep multiple services in sync by defining a mirror service. A mirror
service replicates uploads and deletes across two or more subordinate services.

A mirror service is intended to be used temporarily during a migration between
services in production. You can start mirroring to a new service, copy
pre-existing files from the old service to the new, then go all-in on the new
service.

Mirroring is not atomic. It is possible for an upload to succeed on the
primary service and fail on any of the subordinate services. Before going
all-in on a new service, verify that all files have been copied.

Define each of the services you'd like to mirror as described above. Reference
them by name when defining a mirror service:

```yaml
# Use bin/rails credentials:edit to set the AWS secrets (as aws:access_key_id|secret_access_key)
s3_west_coast:
  service: S3
  access_key_id: <%= Rails.application.credentials.dig(:aws, :access_key_id) %>
  secret_access_key: <%= Rails.application.credentials.dig(:aws, :secret_access_key) %>
  region: "" # e.g. 'us-west-1'
  bucket: your_own_bucket-<%= Rails.env %>

s3_east_coast:
  service: S3
  access_key_id: <%= Rails.application.credentials.dig(:aws, :access_key_id) %>
  secret_access_key: <%= Rails.application.credentials.dig(:aws, :secret_access_key) %>
  region: "" # e.g. 'us-east-1'
  bucket: your_own_bucket-<%= Rails.env %>

production:
  service: Mirror
  primary: s3_east_coast
  mirrors:
    - s3_west_coast
```

Although all secondary services receive uploads, downloads are always handled
by the primary service.

Mirror services are compatible with direct uploads. New files are directly
uploaded to the primary service. When a directly-uploaded file is attached to a
record, a background job is enqueued to copy it to the secondary services.

### 2.5. Public access

By default, Active Storage assumes private access to services. This means generating signed, single-use URLs for blobs. If you'd rather make blobs publicly accessible, specify public: true in your app's config/storage.yml:

```yaml
gcs: &gcs
  service: GCS
  project: ""

private_gcs:
  <<: *gcs
  credentials: <%= Rails.root.join("path/to/private_key.json") %>
  bucket: your_own_bucket-<%= Rails.env %>

public_gcs:
  <<: *gcs
  credentials: <%= Rails.root.join("path/to/public_key.json") %>
  bucket: your_own_bucket-<%= Rails.env %>
  public: true
```

Make sure your buckets are properly configured for public access. See docs on how to enable public read permissions for Amazon S3 and Google Cloud Storage storage services. Amazon S3 additionally requires that you have the s3:PutObjectAcl permission.

When converting an existing application to use public: true, make sure to update every individual file in the bucket to be publicly-readable before switching over.

## 3. Attaching Files to Records

### 3.1. has_one_attached

The has_one_attached macro sets up a one-to-one mapping between records and
files. Each record can have one file attached to it.

For example, suppose your application has a User model. If you want each user to
have an avatar, define the User model as follows:

```ruby
class User < ApplicationRecord
  has_one_attached :avatar
end
```

or if you are using Rails 6.0+, you can run a model generator command like this:

```bash
bin/rails generate model User avatar:attachment
```

You can create a user with an avatar:

```ruby
<%= form.file_field :avatar %>
```

```ruby
class SignupController < ApplicationController
  def create
    user = User.create!(user_params)
    session[:user_id] = user.id
    redirect_to root_path
  end

  private
    def user_params
      params.expect(user: [:email_address, :password, :avatar])
    end
end
```

Call avatar.attach to attach an avatar to an existing user:

```ruby
user.avatar.attach(params[:avatar])
```

Call avatar.attached? to determine whether a particular user has an avatar:

```ruby
user.avatar.attached?
```

In some cases you might want to override a default service for a specific attachment.
You can configure specific services per attachment using the service option with the name of your service:

```ruby
class User < ApplicationRecord
  has_one_attached :avatar, service: :google
end
```

You can configure specific variants per attachment by calling the variant method on yielded attachable object:

```ruby
class User < ApplicationRecord
  has_one_attached :avatar do |attachable|
    attachable.variant :thumb, resize_to_limit: [100, 100]
  end
end
```

Call avatar.variant(:thumb) to get a thumb variant of an avatar:

```ruby
<%= image_tag user.avatar.variant(:thumb) %>
```

You can use specific variants for previews as well:

```ruby
class User < ApplicationRecord
  has_one_attached :video do |attachable|
    attachable.variant :thumb, resize_to_limit: [100, 100]
  end
end
```

```ruby
<%= image_tag user.video.preview(:thumb) %>
```

If you know in advance that your variants will be accessed, you can specify that
Rails should generate them ahead of time:

```ruby
class User < ApplicationRecord
  has_one_attached :video do |attachable|
    attachable.variant :thumb, resize_to_limit: [100, 100], preprocessed: true
  end
end
```

Rails will enqueue a job to generate the variant after the attachment is attached to the record.

Since Active Storage relies on polymorphic associations, and polymorphic associations rely on storing class names in the database, that data must remain synchronized with the class name used by the Ruby code. When renaming classes that use has_one_attached, make sure to also update the class names in the active_storage_attachments.record_type polymorphic type column of the corresponding rows.

### 3.2. has_many_attached

The has_many_attached macro sets up a one-to-many relationship between records
and files. Each record can have many files attached to it.

For example, suppose your application has a Message model. If you want each
message to have many images, define the Message model as follows:

```ruby
class Message < ApplicationRecord
  has_many_attached :images
end
```

or if you are using Rails 6.0+, you can run a model generator command like this:

```bash
bin/rails generate model Message images:attachments
```

You can create a message with images:

```ruby
class MessagesController < ApplicationController
  def create
    message = Message.create!(message_params)
    redirect_to message
  end

  private
    def message_params
      params.expect(message: [ :title, :content, images: [] ])
    end
end
```

Call images.attach to add new images to an existing message:

```ruby
@message.images.attach(params[:images])
```

Call images.attached? to determine whether a particular message has any images:

```ruby
@message.images.attached?
```

Overriding the default service is done the same way as has_one_attached, by using the service option:

```ruby
class Message < ApplicationRecord
  has_many_attached :images, service: :s3
end
```

Configuring specific variants is done the same way as has_one_attached, by calling the variant method on the yielded attachable object:

```ruby
class Message < ApplicationRecord
  has_many_attached :images do |attachable|
    attachable.variant :thumb, resize_to_limit: [100, 100]
  end
end
```

Since Active Storage relies on polymorphic associations, and polymorphic associations rely on storing class names in the database, that data must remain synchronized with the class name used by the Ruby code. When renaming classes that use has_many_attached, make sure to also update the class names in the active_storage_attachments.record_type polymorphic type column of the corresponding rows.

### 3.3. Attaching File/IO Objects

Sometimes you need to attach a file that doesn’t arrive via an HTTP request.
For example, you may want to attach a file you generated on disk or downloaded
from a user-submitted URL. You may also want to attach a fixture file in a
model test. To do that, provide a Hash containing at least an open IO object
and a filename:

```ruby
@message.images.attach(io: File.open("/path/to/file"), filename: "file.pdf")
```

When possible, provide a content type as well. Active Storage attempts to
determine a file’s content type from its data. It falls back to the content
type you provide if it can’t do that.

```ruby
@message.images.attach(io: File.open("/path/to/file"), filename: "file.pdf", content_type: "application/pdf")
```

You can bypass the content type inference from the data by passing in
identify: false along with the content_type.

```ruby
@message.images.attach(
  io: File.open("/path/to/file"),
  filename: "file.pdf",
  content_type: "application/pdf",
  identify: false
)
```

If you don’t provide a content type and Active Storage can’t determine the
file’s content type automatically, it defaults to application/octet-stream.

There is an additional parameter key that can be used to specify folders/sub-folders
in your S3 Bucket. AWS S3 otherwise uses a random key to name your files. This
approach is helpful if you want to organize your S3 Bucket files better.

```ruby
@message.images.attach(
  io: File.open("/path/to/file"),
  filename: "file.pdf",
  content_type: "application/pdf",
  key: "#{Rails.env}/blog_content/intuitive_filename.pdf",
  identify: false
)
```

This way the file will get saved in the folder [S3_BUCKET]/development/blog_content/
when you test this from your development environment. Note that if you use the key
parameter, you have to ensure the key to be unique for the upload to go through. It is
recommended to append the filename with a unique random key, something like:

```ruby
def s3_file_key
  "#{Rails.env}/blog_content/intuitive_filename-#{SecureRandom.uuid}.pdf"
end
```

```ruby
@message.images.attach(
  io: File.open("/path/to/file"),
  filename: "file.pdf",
  content_type: "application/pdf",
  key: s3_file_key,
  identify: false
)
```

### 3.4. Replacing vs Adding Attachments

By default in Rails, attaching files to a has_many_attached association will replace
any existing attachments.

To keep existing attachments, you can use hidden form fields with the signed_id
of each attached file:

```ruby
<% @message.images.each do |image| %>
  <%= form.hidden_field :images, multiple: true, value: image.signed_id %>
<% end %>

<%= form.file_field :images, multiple: true %>
```

This has the advantage of making it possible to remove existing attachments
selectively, e.g. by using JavaScript to remove individual hidden fields.

### 3.5. Form Validation

Attachments aren't sent to the storage service until a successful save on the
associated record. This means that if a form submission fails validation, any new
attachment(s) will be lost and must be uploaded again. Since direct uploads
are stored before the form is submitted, they can be used to retain uploads when validation fails:

```ruby
<%= form.hidden_field :avatar, value: @user.avatar.signed_id if @user.avatar.attached? %>
<%= form.file_field :avatar, direct_upload: true %>
```

## 4. Querying

Active Storage attachments are Active Record associations behind the scenes, so you can use the usual query methods to look up records for attachments that meet specific criteria.

### 4.1. has_one_attached

has_one_attached creates a has_one association named "<name>_attachment" and a has_one :through association named "<name>_blob".
To select every user where the avatar is a PNG, run the following:

```ruby
User.joins(:avatar_blob).where(active_storage_blobs: { content_type: "image/png" })
```

### 4.2. has_many_attached

has_many_attached creates a has_many association called "<name>_attachments" and a has_many :through association called "<name>_blobs" (note the plural).
To select all messages where images are videos rather than photos you can do the following:

```ruby
Message.joins(:images_blobs).where(active_storage_blobs: { content_type: "video/mp4" })
```

The query will filter on the ActiveStorage::Blob, not the attachment record because these are plain SQL joins. You can combine the blob predicates above with any other scope conditions, just as you would with any other Active Record query.

## 5. Removing Files

To remove an attachment from a model, call purge on the
attachment. If your application is set up to use Active Job, removal can be done
in the background instead by calling purge_later.
Purging deletes the blob and the file from the storage service.

```ruby
# Synchronously destroy the avatar and actual resource files.
user.avatar.purge

# Destroy the associated models and actual resource files async, via Active Job.
user.avatar.purge_later
```

## 6. Serving Files

Active Storage supports two ways to serve files: redirecting and proxying.

All Active Storage controllers are publicly accessible by default. The
generated URLs are hard to guess, but permanent by design. If your files
require a higher level of protection consider implementing
Authenticated Controllers.

### 6.1. Redirect Mode

To generate a permanent URL for a blob, you can pass the attachment or the blob to
the url_for view helper. This generates a
URL with the blob's signed_id
that is routed to the blob's RedirectController

```ruby
url_for(user.avatar)
# => https://www.example.com/rails/active_storage/blobs/redirect/:signed_id/my-avatar.png
```

The RedirectController redirects to the actual service endpoint. This
indirection decouples the service URL from the actual one, and allows, for
example, mirroring attachments in different services for high-availability. The
redirection has an HTTP expiration of 5 minutes.

To create a download link, use the rails_blob_{path|url} helper. Using this
helper allows you to set the disposition.

```ruby
rails_blob_path(user.avatar, disposition: "attachment")
```

To prevent XSS attacks, Active Storage forces the Content-Disposition header
to "attachment" for some kind of files. To change this behavior see the
available configuration options in Configuring Rails Applications.

If you need to create a link from outside of controller/view context (Background
jobs, Cronjobs, etc.), you can access the rails_blob_path like this:

```ruby
Rails.application.routes.url_helpers.rails_blob_path(user.avatar, only_path: true)
```

### 6.2. Proxy Mode

Optionally, files can be proxied instead. This means that your application servers will download file data from the storage service in response to requests. This can be useful for serving files from a CDN.

You can configure Active Storage to use proxying by default:

```ruby
# config/initializers/active_storage.rb
Rails.application.config.active_storage.resolve_model_to_route = :rails_storage_proxy
```

Or if you want to explicitly proxy specific attachments there are URL helpers you can use in the form of rails_storage_proxy_path and rails_storage_proxy_url.

```ruby
<%= image_tag rails_storage_proxy_path(@user.avatar) %>
```

#### 6.2.1. Putting a CDN in Front of Active Storage

Additionally, in order to use a CDN for Active Storage attachments, you will need to generate URLs with proxy mode so that they are served by your app and the CDN will cache the attachment without any extra configuration. This works out of the box because the default Active Storage proxy controller sets an HTTP header indicating to the CDN to cache the response.

You should also make sure that the generated URLs use the CDN host instead of your app host. There are multiple ways to achieve this, but in general it involves tweaking your config/routes.rb file so that you can generate the proper URLs for the attachments and their variations. As an example, you could add this:

```ruby
# config/routes.rb
direct :cdn_image do |model, options|
  expires_in = options.delete(:expires_in) { ActiveStorage.urls_expire_in }

  if model.respond_to?(:signed_id)
    route_for(
      :rails_service_blob_proxy,
      model.signed_id(expires_in: expires_in),
      model.filename,
      options.merge(host: ENV["CDN_HOST"])
    )
  else
    signed_blob_id = model.blob.signed_id(expires_in: expires_in)
    variation_key  = model.variation.key
    filename       = model.blob.filename

    route_for(
      :rails_blob_representation_proxy,
      signed_blob_id,
      variation_key,
      filename,
      options.merge(host: ENV["CDN_HOST"])
    )
  end
end
```

and then generate routes like this:

```ruby
<%= cdn_image_url(user.avatar.variant(resize_to_limit: [128, 128])) %>
```

### 6.3. Authenticated Controllers

All Active Storage controllers are publicly accessible by default. The generated
URLs use a plain signed_id, making them hard to
guess but permanent. Anyone that knows the blob URL will be able to access it,
even if a before_action in your ApplicationController would otherwise
require a login. If your files require a higher level of protection, you can
implement your own authenticated controllers, based on the
ActiveStorage::Blobs::RedirectController,
ActiveStorage::Blobs::ProxyController,
ActiveStorage::Representations::RedirectController and
ActiveStorage::Representations::ProxyController

To only allow an account to access their own logo you could do the following:

```ruby
# config/routes.rb
resource :account do
  resource :logo
end
```

```ruby
# app/controllers/logos_controller.rb
class LogosController < ApplicationController
  # Through ApplicationController:
  # include Authenticate, SetCurrentAccount

  def show
    redirect_to Current.account.logo.url
  end
end
```

```ruby
<%= image_tag account_logo_path %>
```

And then you should disable the Active Storage default routes with:

```ruby
config.active_storage.draw_routes = false
```

to prevent files being accessed with the publicly accessible URLs.

## 7. Downloading Files

Sometimes you need to process a blob after it’s uploaded—for example, to convert
it to a different format. Use the attachment's download method to read a blob’s
binary data into memory:

```ruby
binary = user.avatar.download
```

You might want to download a blob to a file on disk so an external program (e.g.
a virus scanner or media transcoder) can operate on it. Use the attachment's
open method to download a blob to a tempfile on disk:

```ruby
message.video.open do |file|
  system "/path/to/virus/scanner", file.path
  # ...
end
```

It's important to know that the file is not yet available in the after_create callback but in the after_create_commit only.

## 8. Analyzing Files

Active Storage analyzes files once they've been uploaded by queuing a job in Active Job. Analyzed files will store additional information in the metadata hash, including analyzed: true. You can check whether a blob has been analyzed by calling analyzed? on it.

Image analysis provides width and height attributes. Video analysis provides these, as well as duration, angle, display_aspect_ratio, and video and audio booleans to indicate the presence of those channels. Audio analysis provides duration and bit_rate attributes.

## 9. Displaying Images, Videos, and PDFs

Active Storage supports representing a variety of files. You can call
representation on an attachment to display an image variant, or a
preview of a video or PDF. Before calling representation, check if the
attachment can be represented by calling representable?. Some file formats
can't be previewed by Active Storage out of the box (e.g. Word documents); if
representable? returns false you may want to link to
the file instead.

```ruby
<ul>
  <% @message.files.each do |file| %>
    <li>
      <% if file.representable? %>
        <%= image_tag file.representation(resize_to_limit: [100, 100]) %>
      <% else %>
        <%= link_to rails_blob_path(file, disposition: "attachment") do %>
          <%= image_tag "placeholder.png", alt: "Download file" %>
        <% end %>
      <% end %>
    </li>
  <% end %>
</ul>
```

Internally, representation calls variant for images, and preview for
previewable files. You can also call these methods directly.

### 9.1. Lazy vs Immediate Loading

By default, Active Storage will process representations lazily. This code:

```ruby
image_tag file.representation(resize_to_limit: [100, 100])
```

Will generate an <img> tag with the src pointing to the
ActiveStorage::Representations::RedirectController. The browser will
make a request to that controller, which will perform the following:

- Process file and upload the processed file if necessary.

- Return a 302 redirect to the file either to

the remote service (e.g., S3).
or ActiveStorage::Blobs::ProxyController which will return the file contents if proxy mode is enabled.

- the remote service (e.g., S3).

- or ActiveStorage::Blobs::ProxyController which will return the file contents if proxy mode is enabled.

Loading the file lazily allows features like single use URLs
to work without slowing down your initial page loads.

This works fine for most cases.

If you want to generate URLs for images immediately, you can call .processed.url:

```ruby
image_tag file.representation(resize_to_limit: [100, 100]).processed.url
```

The Active Storage variant tracker improves performance of this, by storing a
record in the database if the requested representation has been processed before.
Thus, the above code will only make an API call to the remote service (e.g. S3)
once, and once a variant is stored, will use that. The variant tracker runs
automatically, but can be disabled through config.active_storage.track_variants.

If you're rendering lots of images on a page, the above example could result
in N+1 queries loading all the variant records. To avoid these N+1 queries,
use the named scopes on ActiveStorage::Attachment.

```ruby
message.images.with_all_variant_records.each do |file|
  image_tag file.representation(resize_to_limit: [100, 100]).processed.url
end
```

### 9.2. Transforming Images

Transforming images allows you to display the image at your choice of dimensions.
To create a variation of an image, call variant on the attachment. You
can pass any transformation supported by the variant processor to the method.
When the browser hits the variant URL, Active Storage will lazily transform
the original blob into the specified format and redirect to its new service
location.

```ruby
<%= image_tag user.avatar.variant(resize_to_limit: [100, 100]) %>
```

If a variant is requested, Active Storage will automatically apply
transformations depending on the image's format:

- Content types that are variable (as dictated by config.active_storage.variable_content_types)
and not considered web images (as dictated by config.active_storage.web_image_content_types),
will be converted to PNG.

- If quality is not specified, the variant processor's default quality for the format will be used.

Content types that are variable (as dictated by config.active_storage.variable_content_types)
and not considered web images (as dictated by config.active_storage.web_image_content_types),
will be converted to PNG.

If quality is not specified, the variant processor's default quality for the format will be used.

Active Storage can use either Vips or MiniMagick as the variant processor.
The default depends on your config.load_defaults target version, and the
processor can be changed by setting config.active_storage.variant_processor.

### 9.3. Previewing Files

Some non-image files can be previewed: that is, they can be presented as images.
For example, a video file can be previewed by extracting its first frame. Out of
the box, Active Storage supports previewing videos and PDF documents. To create
a link to a lazily-generated preview, use the attachment's preview method:

```ruby
<%= image_tag message.video.preview(resize_to_limit: [100, 100]) %>
```

To add support for another format, add your own previewer. See the
ActiveStorage::Preview documentation for more information.

## 10. Direct Uploads

Active Storage, with its included JavaScript library, supports uploading
directly from the client to the cloud.

### 10.1. Usage

- Include the Active Storage JavaScript in your application's JavaScript bundle or reference it directly.Requiring directly without bundling through the asset pipeline in the application HTML with autostart:
<%= javascript_include_tag "activestorage" %>

Requiring via importmap-rails without bundling through the asset pipeline in the application HTML without autostart as ESM:

# config/importmap.rb

pin "@rails/activestorage", to: "activestorage.esm.js"

<script type="module-shim">
  import * as ActiveStorage from "@rails/activestorage"
  ActiveStorage.start()
</script>

Using the asset pipeline:
//= require activestorage

Using the npm package:
import * as ActiveStorage from "@rails/activestorage"
ActiveStorage.start()

- Annotate file inputs with the direct upload URL using Rails' file field helper.
<%= form.file_field :attachments, multiple: true, direct_upload: true %>

Or, if you aren't using a FormBuilder, add the data attribute directly:
<input type="file" data-direct-upload-url="<%= rails_direct_uploads_url %>" />

- Configure CORS on third-party storage services to allow direct upload requests.

- That's it! Uploads begin upon form submission.

Include the Active Storage JavaScript in your application's JavaScript bundle or reference it directly.

Requiring directly without bundling through the asset pipeline in the application HTML with autostart:

```ruby
<%= javascript_include_tag "activestorage" %>
```

Requiring via importmap-rails without bundling through the asset pipeline in the application HTML without autostart as ESM:

```ruby
# config/importmap.rb
pin "@rails/activestorage", to: "activestorage.esm.js"
```

```html
<script type="module-shim">
  import * as ActiveStorage from "@rails/activestorage"
  ActiveStorage.start()
</script>
```

Using the asset pipeline:

```
//= require activestorage
```

Using the npm package:

```
import * as ActiveStorage from "@rails/activestorage"
ActiveStorage.start()
```

Annotate file inputs with the direct upload URL using Rails' file field helper.

```ruby
<%= form.file_field :attachments, multiple: true, direct_upload: true %>
```

Or, if you aren't using a FormBuilder, add the data attribute directly:

```ruby
<input type="file" data-direct-upload-url="<%= rails_direct_uploads_url %>" />
```

Configure CORS on third-party storage services to allow direct upload requests.

That's it! Uploads begin upon form submission.

### 10.2. Cross-Origin Resource Sharing (CORS) Configuration

To make direct uploads to a third-party service work, you’ll need to configure the service to allow cross-origin requests from your app. Consult the CORS documentation for your service:

- S3

- Google Cloud Storage

Take care to allow:

- All origins from which your app is accessed

- The PUT request method

- The following headers:

Content-Type
Content-MD5
Content-Disposition
Cache-Control (for GCS, only if cache_control is set)

- Content-Type

- Content-MD5

- Content-Disposition

- Cache-Control (for GCS, only if cache_control is set)

No CORS configuration is required for the Disk service since it shares your app’s origin.

#### 10.2.1. Example: S3 CORS Configuration

```
[
  {
    "AllowedHeaders": [
      "Content-Type",
      "Content-MD5",
      "Content-Disposition"
    ],
    "AllowedMethods": [
      "PUT"
    ],
    "AllowedOrigins": [
      "https://www.example.com"
    ],
    "MaxAgeSeconds": 3600
  }
]
```

#### 10.2.2. Example: Google Cloud Storage CORS Configuration

```
[
  {
    "origin": ["https://www.example.com"],
    "method": ["PUT"],
    "responseHeader": ["Content-Type", "Content-MD5", "Content-Disposition"],
    "maxAgeSeconds": 3600
  }
]
```

### 10.3. Direct Upload JavaScript Events

### 10.4. Example

You can use these events to show the progress of an upload.

To show the uploaded files in a form:

```
// direct_uploads.js

addEventListener("direct-upload:initialize", event => {
  const { target, detail } = event
  const { id, file } = detail
  target.insertAdjacentHTML("beforebegin", `
    <div id="direct-upload-${id}" class="direct-upload direct-upload--pending">
      <div id="direct-upload-progress-${id}" class="direct-upload__progress" style="width: 0%"></div>
      <span class="direct-upload__filename"></span>
    </div>
  `)
  target.previousElementSibling.querySelector(`.direct-upload__filename`).textContent = file.name
})

addEventListener("direct-upload:start", event => {
  const { id } = event.detail
  const element = document.getElementById(`direct-upload-${id}`)
  element.classList.remove("direct-upload--pending")
})

addEventListener("direct-upload:progress", event => {
  const { id, progress } = event.detail
  const progressElement = document.getElementById(`direct-upload-progress-${id}`)
  progressElement.style.width = `${progress}%`
})

addEventListener("direct-upload:error", event => {
  event.preventDefault()
  const { id, error } = event.detail
  const element = document.getElementById(`direct-upload-${id}`)
  element.classList.add("direct-upload--error")
  element.setAttribute("title", error)
})

addEventListener("direct-upload:end", event => {
  const { id } = event.detail
  const element = document.getElementById(`direct-upload-${id}`)
  element.classList.add("direct-upload--complete")
})
```

Add styles:

```
/* direct_uploads.css */

.direct-upload {
  display: inline-block;
  position: relative;
  padding: 2px 4px;
  margin: 0 3px 3px 0;
  border: 1px solid rgba(0, 0, 0, 0.3);
  border-radius: 3px;
  font-size: 11px;
  line-height: 13px;
}

.direct-upload--pending {
  opacity: 0.6;
}

.direct-upload__progress {
  position: absolute;
  top: 0;
  left: 0;
  bottom: 0;
  opacity: 0.2;
  background: #0076ff;
  transition: width 120ms ease-out, opacity 60ms 60ms ease-in;
  transform: translate3d(0, 0, 0);
}

.direct-upload--complete .direct-upload__progress {
  opacity: 0.4;
}

.direct-upload--error {
  border-color: red;
}

input[type=file][data-direct-upload-url][disabled] {
  display: none;
}
```

### 10.5. Custom drag and drop solutions

You can use the DirectUpload class for this purpose. Upon receiving a file from your library
of choice, instantiate a DirectUpload and call its create method. Create takes
a callback to invoke when the upload completes.

```
import { DirectUpload } from "@rails/activestorage"

const input = document.querySelector('input[type=file]')

// Bind to file drop - use the ondrop on a parent element or use a
//  library like Dropzone
const onDrop = (event) => {
  event.preventDefault()
  const files = event.dataTransfer.files;
  Array.from(files).forEach(file => uploadFile(file))
}

// Bind to normal file selection
input.addEventListener('change', (event) => {
  Array.from(input.files).forEach(file => uploadFile(file))
  // you might clear the selected files from the input
  input.value = null
})

const uploadFile = (file) => {
  // your form needs the file_field direct_upload: true, which
  //  provides data-direct-upload-url
  const url = input.dataset.directUploadUrl
  const upload = new DirectUpload(file, url)

  upload.create((error, blob) => {
    if (error) {
      // Handle the error
    } else {
      // Add an appropriately-named hidden input to the form with a
      //  value of blob.signed_id so that the blob ids will be
      //  transmitted in the normal upload flow
      const hiddenField = document.createElement('input')
      hiddenField.setAttribute("type", "hidden");
      hiddenField.setAttribute("value", blob.signed_id);
      hiddenField.name = input.name
      document.querySelector('form').appendChild(hiddenField)
    }
  })
}
```

### 10.6. Track the progress of the file upload

When using the DirectUpload constructor, it is possible to include a third parameter.
This will allow the DirectUpload object to invoke the directUploadWillStoreFileWithXHR
method during the upload process.
You can then attach your own progress handler to the XHR to suit your needs.

```
import { DirectUpload } from "@rails/activestorage"

class Uploader {
  constructor(file, url) {
    this.upload = new DirectUpload(file, url, this)
  }

  uploadFile(file) {
    this.upload.create((error, blob) => {
      if (error) {
        // Handle the error
      } else {
        // Add an appropriately-named hidden input to the form
        // with a value of blob.signed_id
      }
    })
  }

  directUploadWillStoreFileWithXHR(request) {
    request.upload.addEventListener("progress",
      event => this.directUploadDidProgress(event))
  }

  directUploadDidProgress(event) {
    // Use event.loaded and event.total to update the progress bar
  }
}
```

### 10.7. Integrating with Libraries or Frameworks

Once you receive a file from the library you have selected, you need to create
a DirectUpload instance and use its "create" method to initiate the upload process,
adding any required additional headers as necessary. The "create" method also requires
a callback function to be provided that will be triggered once the upload has finished.

```
import { DirectUpload } from "@rails/activestorage"

class Uploader {
  constructor(file, url, token) {
    const headers = { 'Authentication': `Bearer ${token}` }
    // INFO: Sending headers is an optional parameter. If you choose not to send headers,
    //       authentication will be performed using cookies or session data.
    this.upload = new DirectUpload(file, url, this, headers)
  }

  uploadFile(file) {
    this.upload.create((error, blob) => {
      if (error) {
        // Handle the error
      } else {
        // Use the with blob.signed_id as a file reference in next request
      }
    })
  }

  directUploadWillStoreFileWithXHR(request) {
    request.upload.addEventListener("progress",
      event => this.directUploadDidProgress(event))
  }

  directUploadDidProgress(event) {
    // Use event.loaded and event.total to update the progress bar
  }
}
```

To implement customized authentication, a new controller must be created on
the Rails application, similar to the following:

```ruby
class DirectUploadsController < ActiveStorage::DirectUploadsController
  skip_forgery_protection
  before_action :authenticate!

  def authenticate!
    @token = request.headers["Authorization"]&.split&.last

    head :unauthorized unless valid_token?(@token)
  end
end
```

Using Direct Uploads can sometimes result in a file that uploads, but never attaches to a record. Consider purging unattached uploads.

## 11. Testing

Use file_fixture_upload to test uploading a file in an integration or controller test.
Rails handles files like any other parameter.

```ruby
class SignupController < ActionDispatch::IntegrationTest
  test "can sign up" do
    post signup_path, params: {
      name: "David",
      avatar: file_fixture_upload("david.png", "image/png")
    }

    user = User.order(:created_at).last
    assert user.avatar.attached?
  end
end
```

### 11.1. Discarding Files Created During Tests

#### 11.1.1. System Tests

System tests clean up test data by rolling back a transaction. Because destroy
is never called on an object, the attached files are never cleaned up. If you
want to clear the files, you can do it in an after_teardown callback. Doing it
here ensures that all connections created during the test are complete and
you won't receive an error from Active Storage saying it can't find a file.

```ruby
class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  # ...
  def after_teardown
    super
    FileUtils.rm_rf(ActiveStorage::Blob.service.root)
  end
  # ...
end
```

If you're using parallel tests and the DiskService, you should configure each process to use its own
folder for Active Storage. This way, the teardown callback will only delete files from the relevant process'
tests.

```ruby
class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  # ...
  parallelize_setup do |i|
    ActiveStorage::Blob.service.root = "#{ActiveStorage::Blob.service.root}-#{i}"
  end
  # ...
end
```

If your system tests verify the deletion of a model with attachments and you're
using Active Job, set your test environment to use the inline queue adapter so
the purge job is executed immediately rather at an unknown time in the future.

```ruby
# Use inline job processing to make things happen immediately
config.active_job.queue_adapter = :inline
```

#### 11.1.2. Integration Tests

Similarly to System Tests, files uploaded during Integration Tests will not be
automatically cleaned up. If you want to clear the files, you can do it in an
teardown callback.

```ruby
class ActionDispatch::IntegrationTest
  def after_teardown
    super
    FileUtils.rm_rf(ActiveStorage::Blob.service.root)
  end
end
```

If you're using parallel tests and the Disk service, you should configure each process to use its own
folder for Active Storage. This way, the teardown callback will only delete files from the relevant process'
tests.

```ruby
class ActionDispatch::IntegrationTest
  parallelize_setup do |i|
    ActiveStorage::Blob.service.root = "#{ActiveStorage::Blob.service.root}-#{i}"
  end
end
```

### 11.2. Adding Attachments to Fixtures

You can add attachments to your existing fixtures. First, you'll want to create a separate storage service:

```
# config/storage.yml

test_fixtures:
  service: Disk
  root: <%= Rails.root.join("tmp/storage_fixtures") %>
```

This tells Active Storage where to "upload" fixture files to, so it should be a temporary directory. By making it
a different directory to your regular test service, you can separate fixture files from files uploaded during a
test.

Next, create fixture files for the Active Storage classes:

```
# test/fixtures/active_storage/attachments.yml
david_avatar:
  name: avatar
  record: david (User)
  blob: david_avatar_blob
```

```
# test/fixtures/active_storage/blobs.yml
david_avatar_blob: <%= ActiveStorage::FixtureSet.blob filename: "david.png", service_name: "test_fixtures" %>
```

Then put a file in your fixtures directory (the default path is test/fixtures/files) with the corresponding filename.
See the ActiveStorage::FixtureSet docs for more information.

Once everything is set up, you'll be able to access attachments in your tests:

```ruby
class UserTest < ActiveSupport::TestCase
  def test_avatar
    avatar = users(:david).avatar

    assert avatar.attached?
    assert_not_nil avatar.download
    assert_equal 1000, avatar.byte_size
  end
end
```

#### 11.2.1. Cleaning up Fixtures

While files uploaded in tests are cleaned up at the end of each test,
you only need to clean up fixture files once: when all your tests complete.

If you're using parallel tests, call parallelize_teardown:

```ruby
class ActiveSupport::TestCase
  # ...
  parallelize_teardown do |i|
    FileUtils.rm_rf(ActiveStorage::Blob.services.fetch(:test_fixtures).root)
  end
  # ...
end
```

If you're not running parallel tests, use Minitest.after_run or the equivalent for your test
framework (e.g. after(:suite) for RSpec):

```ruby
# test_helper.rb

Minitest.after_run do
  FileUtils.rm_rf(ActiveStorage::Blob.services.fetch(:test_fixtures).root)
end
```

### 11.3. Configuring services

You can add config/storage/test.yml to configure services to be used in test environment.
This is useful when the service option is used.

```ruby
class User < ApplicationRecord
  has_one_attached :avatar, service: :s3
end
```

Without config/storage/test.yml, the s3 service configured in config/storage.yml is used - even when running tests.

The default configuration would be used and files would be uploaded to the service provider configured in config/storage.yml.

In this case, you can add config/storage/test.yml and use Disk service for s3 service to prevent sending requests.

```yaml
test:
  service: Disk
  root: <%= Rails.root.join("tmp/storage") %>

s3:
  service: Disk
  root: <%= Rails.root.join("tmp/storage") %>
```

## 12. Implementing Support for Other Cloud Services

If you need to support a cloud service other than these, you will need to
implement the Service. Each service extends
ActiveStorage::Service
by implementing the methods necessary to upload and download files to the cloud.

## 13. Purging Unattached Uploads

There are cases where a file is uploaded but never attached to a record. This can happen when using Direct Uploads. You can query for unattached records using the unattached scope. Below is an example using a custom rake task.

```ruby
namespace :active_storage do
  desc "Purges unattached Active Storage blobs. Run regularly."
  task purge_unattached: :environment do
    ActiveStorage::Blob.unattached.where(created_at: ..2.days.ago).find_each(&:purge_later)
  end
end
```

The query generated by ActiveStorage::Blob.unattached can be slow and potentially disruptive on applications with larger databases.

---

# Chapters

This guide is an introduction to speeding up your Rails application with caching.

After reading this guide, you will know:

- What caching is.

- The types of caching strategies.

- How to manage the caching dependencies.

- Solid Cache - a database-backed Active Support cache store.

- Other cache stores.

- Cache keys.

- Conditional GET support.

## 1. What is Caching?

Caching means storing content generated during the request-response cycle and
reusing it when responding to similar requests. It's like keeping your favorite
coffee mug right on your desk instead of in the kitchen cabinet — it’s ready
when you need it, saving you time and effort.

Caching is one of the most effective ways to boost an application's performance.
It allows websites running on modest infrastructure — a single server with a
single database — to sustain thousands of concurrent users.

Rails provides a set of caching features out of the box which allows you to not
only cache data, but also to tackle challenges like cache expiration, cache
dependencies, and cache invalidation.

This guide will explore Rails' comprehensive caching strategies, from fragment
caching to SQL caching. With these techniques, your Rails application can serve
millions of views while keeping response times low and server bills manageable.

## 2. Types of Caching

This is an introduction to some of the common types of caching.

By default, Action Controller caching is only enabled in your production environment. You can play
around with caching locally by running bin/rails dev:cache, or by setting
config.action_controller.perform_caching to true in config/environments/development.rb.

Changing the value of config.action_controller.perform_caching will
only have an effect on the caching provided by Action Controller.
For instance, it will not impact low-level caching, that we address
below.

### 2.1. Fragment Caching

Dynamic web applications usually build pages with a variety of components not
all of which have the same caching characteristics. When different parts of the
page need to be cached and expired separately you can use Fragment Caching.

Fragment Caching allows a fragment of view logic to be wrapped in a cache block and served out of the cache store when the next request comes in.

For example, if you wanted to cache each product on a page, you could use this
code:

```ruby
<% @products.each do |product| %>
  <% cache product do %>
    <%= render product %>
  <% end %>
<% end %>
```

When your application receives its first request to this page, Rails will write
a new cache entry with a unique key. A key looks something like this:

```
views/products/index:bea67108094918eeba42cd4a6e786901/products/1
```

The string of characters in the middle is a template tree digest. It is a hash
digest computed based on the contents of the view fragment you are caching. If
you change the view fragment (e.g., the HTML changes), the digest will change,
expiring the existing file.

A cache version, derived from the product record, is stored in the cache entry.
When the product is touched, the cache version changes, and any cached fragments
that contain the previous version are ignored.

Cache stores like Memcached will automatically delete old cache files.

If you want to cache a fragment under certain conditions, you can use
cache_if or cache_unless:

```ruby
<% cache_if admin?, product do %>
  <%= render product %>
<% end %>
```

#### 2.1.1. Collection Caching

The render helper can also cache individual templates rendered for a collection.
It can even one up the previous example with each by reading all cache
templates at once instead of one by one. This is done by passing cached: true when rendering the collection:

```ruby
<%= render partial: 'products/product', collection: @products, cached: true %>
```

All cached templates from previous renders will be fetched at once with much
greater speed. Additionally, the templates that haven't yet been cached will be
written to cache and multi fetched on the next render.

The cache key can be configured. In the example below, it is prefixed with the
current locale to ensure that different localizations of the product page
do not overwrite each other:

```ruby
<%= render partial: 'products/product',
           collection: @products,
           cached: ->(product) { [I18n.locale, product] } %>
```

### 2.2. Russian Doll Caching

You may want to nest cached fragments inside other cached fragments. This is
called Russian doll caching.

The advantage of Russian doll caching is that if a single product is updated,
all the other inner fragments can be reused when regenerating the outer
fragment.

As explained in the previous section, a cached file will expire if the value of
updated_at changes for a record on which the cached file directly depends.
However, this will not expire any cache the fragment is nested within.

For example, take the following view:

```ruby
<% cache product do %>
  <%= render product.games %>
<% end %>
```

Which in turn renders this view:

```ruby
<% cache game do %>
  <%= render game %>
<% end %>
```

If any attribute of game is changed, the updated_at value will be set to the
current time, thereby expiring the cache. However, because updated_at
will not be changed for the product object, that cache will not be expired and
your app will serve stale data. To fix this, we tie the models together with
the touch method:

```ruby
class Product < ApplicationRecord
  has_many :games
end

class Game < ApplicationRecord
  belongs_to :product, touch: true
end
```

With touch set to true, any action which changes updated_at for a game
record will also change it for the associated product, thereby expiring the
cache.

### 2.3. Shared Partial Caching

It is possible to share partials and associated caching between files with different MIME types. For example shared partial caching allows template writers to share a partial between HTML and JavaScript files. When templates are collected in the template resolver file paths they only include the template language extension and not the MIME type. Because of this templates can be used for multiple MIME types. Both HTML and JavaScript requests will respond to the following code:

```ruby
render(partial: "hotels/hotel", collection: @hotels, cached: true)
```

Will load a file named hotels/hotel.erb.

Another option is to include the formats attribute to the partial to render.

```ruby
render(partial: "hotels/hotel", collection: @hotels, formats: :html, cached: true)
```

Will load a file named hotels/hotel.html.erb in any file MIME type, for example you could include this partial in a JavaScript file.

### 2.4. Low-Level Caching using Rails.cache

Sometimes you need to cache a particular value or query result instead of caching view fragments. Rails' caching mechanism works great for storing any serializable information.

An efficient way to implement low-level caching is using the Rails.cache.fetch method. This method handles both reading from and writing to the cache. When called with a single argument, it fetches and returns the cached value for the given key. If a block is passed, the block is executed only on a cache miss. The block's return value is written to the cache under the given cache key and returned. In case of cache hit, the cached value is returned directly without executing the block.

Consider the following example. An application has a Product model with an instance method that looks up the product's price on a competing website. The data returned by this method would be perfect for low-level caching:

```ruby
class Product < ApplicationRecord
  def competing_price
    Rails.cache.fetch("#{cache_key_with_version}/competing_price", expires_in: 12.hours) do
      Competitor::API.find_price(id)
    end
  end
end
```

Notice that in this example we used the cache_key_with_version method, so the resulting cache key will be something like products/233-20140225082222765838000/competing_price. cache_key_with_version generates a string based on the model's class name, id, and updated_at attributes. This is a common convention and has the benefit of invalidating the cache whenever the product is updated. In general, when you use low-level caching, you need to generate a cache key.

Below are some more examples of how to use low-level caching:

```ruby
# Store a value in the cache
Rails.cache.write("greeting", "Hello, world!")

# Retrieve the value from the cache
greeting = Rails.cache.read("greeting")
puts greeting # Output: Hello, world!

# Fetch a value with a block to set a default if it doesn’t exist
welcome_message = Rails.cache.fetch("welcome_message") { "Welcome to Rails!" }
puts welcome_message # Output: Welcome to Rails!

# Delete a value from the cache
Rails.cache.delete("greeting")
```

#### 2.4.1. Avoid Caching Instances of Active Record Objects

Consider this example, which stores a list of Active Record objects representing superusers in the cache:

```ruby
# super_admins is an expensive SQL query, so don't run it too often
Rails.cache.fetch("super_admin_users", expires_in: 12.hours) do
  User.super_admins.to_a
end
```

You should avoid this pattern. Why? Because the instance could change. In production, attributes
on it could differ, or the record could be deleted. And in development, it works unreliably with
cache stores that reload code when you make changes.

Instead, cache the ID or some other primitive data type. For example:

```ruby
# super_admins is an expensive SQL query, so don't run it too often
ids = Rails.cache.fetch("super_admin_user_ids", expires_in: 12.hours) do
  User.super_admins.pluck(:id)
end
User.where(id: ids).to_a
```

### 2.5. SQL Caching

Query caching is a Rails feature that caches the result set returned by each
query. If Rails encounters the same query again for that request, it will use
the cached result set as opposed to running the query against the database
again.

For example:

```ruby
class ProductsController < ApplicationController
  def index
    # Run a find query
    @products = Product.all

    # ...

    # Run the same query again
    @products = Product.all
  end
end
```

The second time the same query is run against the database, it's not actually going to hit the database. The first time the result is returned from the query it is stored in the query cache (in memory) and the second time it's pulled from memory. However, each retrieval still instantiates new instances of the queried objects.

Query caches are created at the start of an action and destroyed at the
end of that action and thus persist only for the duration of the action. If
you'd like to store query results in a more persistent fashion, you can with
low-level caching.

## 3. Managing Dependencies

In order to correctly invalidate the cache, you need to properly define the
caching dependencies. Rails is clever enough to handle common cases so you don't
have to specify anything. However, sometimes, when you're dealing with custom
helpers for instance, you need to explicitly define them.

### 3.1. Implicit Dependencies

Most template dependencies can be derived from calls to render in the template
itself. Here are some examples of render calls that ActionView::Digestor knows
how to decode:

```ruby
render partial: "comments/comment", collection: commentable.comments
render "comments/comments"
render("comments/comments")

render "header" # translates to render("comments/header")

render(@topic)         # translates to render("topics/topic")
render(topics)         # translates to render("topics/topic")
render(message.topics) # translates to render("topics/topic")
```

On the other hand, some calls need to be changed to make caching work properly.
For instance, if you're passing a custom collection, you'll need to change:

```ruby
render @project.documents.where(published: true)
```

to:

```ruby
render partial: "documents/document", collection: @project.documents.where(published: true)
```

### 3.2. Explicit Dependencies

Sometimes you'll have template dependencies that can't be derived at all. This
is typically the case when rendering happens in helpers. Here's an example:

```ruby
<%= render_sortable_todolists @project.todolists %>
```

You'll need to use a special comment format to call those out:

```ruby
<%# Template Dependency: todolists/todolist %>
<%= render_sortable_todolists @project.todolists %>
```

In some cases, like a single table inheritance setup, you might have a bunch of
explicit dependencies. Instead of writing every template out, you can use a
wildcard to match any template in a directory:

```ruby
<%# Template Dependency: events/* %>
<%= render_categorizable_events @person.events %>
```

As for collection caching, if the partial template doesn't start with a clean
cache call, you can still benefit from collection caching by adding a special
comment format anywhere in the template, like:

```ruby
<%# Template Collection: notification %>
<% my_helper_that_calls_cache(some_arg, notification) do %>
  <%= notification.name %>
<% end %>
```

### 3.3. External Dependencies

If you use a helper method, for example, inside a cached block and you then update
that helper, you'll have to bump the cache as well. It doesn't really matter how
you do it, but the MD5 of the template file must change. One recommendation is to
simply be explicit in a comment, like:

```ruby
<%# Helper Dependency Updated: Jul 28, 2015 at 7pm %>
<%= some_helper_method(person) %>
```

## 4. Solid Cache

Solid Cache is a database-backed Active Support cache store. It leverages the
speed of modern SSDs (Solid
State Drives) to offer cost-effective caching with larger storage capacity and
simplified infrastructure. While SSDs are slightly slower than RAM, the
difference is minimal for most applications. SSDs compensate for this by not
needing to be invalidated as frequently, since they can store much more data. As
a result, there are fewer cache misses on average, leading to fast response
times.

Solid Cache uses a FIFO (First In, First Out) caching strategy, where the first
item added to the cache is the first one to be removed when the cache reaches
its limit. This approach is simpler but less efficient compared to an LRU (Least
Recently Used) cache, which removes the least recently accessed items first,
better optimizing for frequently used data. However, Solid Cache compensates for
the lower efficiency of FIFO by allowing the cache to live longer, reducing the
frequency of invalidations.

Solid Cache is enabled by default from Rails version 8.0 and onward. However, if
you'd prefer not to utilize it, you can skip Solid Cache:

```bash
rails new app_name --skip-solid
```

Using the --skip-solid flag skips all parts of the Solid
Trifecta (Solid Cache, Solid Queue, and Solid Cable).If you still
want to use some of them, you can install them separately. For
example, if you want to use Solid Queue and Solid Cable but not
Solid Cache, you can follow the installation guides for Solid
Queue and
Solid Cable.

### 4.1. Configuring the Database

To use Solid Cache, you can configure the database connection in your
config/database.yml file. Here's an example configuration for a SQLite
database:

```yaml
production:
  primary:
    <<: *default
    database: storage/production.sqlite3
  cache:
    <<: *default
    database: storage/production_cache.sqlite3
    migrations_paths: db/cache_migrate
```

In this configuration, the cache database is used to store cached data. You
can also specify a different database adapter, like MySQL or PostgreSQL, if you
prefer.

```yaml
production:
  primary: &primary_production
    <<: *default
    database: app_production
    username: app
    password: <%= ENV["APP_DATABASE_PASSWORD"] %>
  cache:
    <<: *primary_production
    database: app_production_cache
    migrations_paths: db/cache_migrate
```

If database or databases is not specified in the
cache configuration, Solid Cache will use the ActiveRecord::Base connection
pool. This means that cache reads and writes will be part of any wrapping
database transaction.

In production, the cache store is configured to use the Solid Cache store by
default:

```yaml
# config/environments/production.rb
  config.cache_store = :solid_cache_store
```

You can access the cache by calling
Rails.cache

### 4.2. Customizing the Cache Store

Solid Cache can be customized through the config/cache.yml file:

```yaml
default: &default
  store_options:
    # Cap age of oldest cache entry to fulfill retention policies
    max_age: <%= 60.days.to_i %>
    max_size: <%= 256.megabytes %>
    namespace: <%= Rails.env %>
```

For the full list of keys for store_options see Cache
configuration.

Here, you can adjust the max_age and max_size options to control the age and
size of the cache entries.

### 4.3. Handling Cache Expiration

Solid Cache tracks cache writes by incrementing a counter with each write. When
the counter reaches 50% of the expiry_batch_size from the Cache
configuration, a
background task is triggered to handle cache expiry. This approach ensures cache
records expire faster than they are written when the cache needs to shrink.

The background task only runs when there are writes, so the process stays idle
when the cache is not being updated. If you prefer to run the expiry process in
a background job instead of a thread, set expiry_method from theCache
configuration to
:job.

### 4.4. Sharding the Cache

If you need more scalability, Solid Cache supports sharding — splitting the
cache across multiple databases. This spreads the load, making your cache even
more powerful. To enable sharding, add multiple cache databases to your
database.yml:

```yaml
# config/database.yml
production:
  cache_shard1:
    database: cache1_production
    host: cache1-db
  cache_shard2:
    database: cache2_production
    host: cache2-db
  cache_shard3:
    database: cache3_production
    host: cache3-db
```

Additionally, you must specify the shards in the cache configuration:

```yaml
# config/cache.yml
production:
  databases: [cache_shard1, cache_shard2, cache_shard3]
```

### 4.5. Encryption

Solid Cache supports encryption to protect sensitive data. To enable encryption,
set the encrypt value in your cache configuration:

```yaml
# config/cache.yml
production:
  encrypt: true
```

You will need to set up your application to useActive Record
Encryption.

### 4.6. Caching in Development

By default, caching is enabled in development mode with
:memory_store. This doesn't apply to
Action Controller caching, which is disabled by default.

To enable Action Controller caching Rails provides the bin/rails dev:cache
command.

```bash
$ bin/rails dev:cache
Development mode is now being cached.
$ bin/rails dev:cache
Development mode is no longer being cached.
```

If you want to use Solid Cache in development, set the cache_store
configuration in config/environments/development.rb:

```ruby
config.cache_store = :solid_cache_store
```

and ensure the cache database is created and migrated:

```bash
development:
  <<: * default
  database: cache
```

To disable caching set cache_store to
:null_store

## 5. Other Cache Stores

Rails provides different stores for the cached data (with the exception of SQL
Caching).

### 5.1. Configuration

You can set up a different cache store by setting the
config.cache_store configuration option. Other parameters can be passed as
arguments to the cache store's constructor:

```ruby
config.cache_store = :memory_store, { size: 64.megabytes }
```

Alternatively, you can set ActionController::Base.cache_store outside of a configuration block.

You can access the cache by calling Rails.cache.

#### 5.1.1. Connection Pool Options

:mem_cache_store and
:redis_cache_store are configured to
use connection pooling. This means that if you're using Puma, or another
threaded server, you can have multiple threads performing queries to the cache
store at the same time.

If you want to disable connection pooling, set :pool option to false when configuring the cache store:

```ruby
config.cache_store = :mem_cache_store, "cache.example.com", { pool: false }
```

You can also override default pool settings by providing individual options to the :pool option:

```ruby
config.cache_store = :mem_cache_store, "cache.example.com", { pool: { size: 32, timeout: 1 } }
```

- :size - This option sets the number of connections per process (defaults to 5).

- :timeout - This option sets the number of seconds to wait for a connection (defaults to 5). If no connection is available within the timeout, a Timeout::Error will be raised.

:size - This option sets the number of connections per process (defaults to 5).

:timeout - This option sets the number of seconds to wait for a connection (defaults to 5). If no connection is available within the timeout, a Timeout::Error will be raised.

### 5.2. ActiveSupport::Cache::Store

ActiveSupport::Cache::Store provides the foundation for interacting with the cache in Rails. This is an abstract class, and you cannot use it on its own. Instead, you must use a concrete implementation of the class tied to a storage engine. Rails ships with several implementations, documented below.

The main API methods are read, write, delete, exist?, and fetch.

Options passed to the cache store's constructor will be treated as default options for the appropriate API methods.

### 5.3. ActiveSupport::Cache::MemoryStore

ActiveSupport::Cache::MemoryStore keeps entries in memory in the same Ruby process. The cache
store has a bounded size specified by sending the :size option to the
initializer (default is 32Mb). When the cache exceeds the allotted size, a
cleanup will occur and the least recently used entries will be removed.

```ruby
config.cache_store = :memory_store, { size: 64.megabytes }
```

If you're running multiple Ruby on Rails server processes (which is the case
if you're using Phusion Passenger or puma clustered mode), then your Rails server
process instances won't be able to share cache data with each other. This cache
store is not appropriate for large application deployments. However, it can
work well for small, low traffic sites with only a couple of server processes,
as well as development and test environments.

New Rails projects are configured to use this implementation in the development environment by default.

Since processes will not share cache data when using :memory_store,
it will not be possible to manually read, write, or expire the cache via the Rails console.

### 5.4. ActiveSupport::Cache::FileStore

ActiveSupport::Cache::FileStore uses the file system to store entries. The path to the directory where the store files will be stored must be specified when initializing the cache.

```ruby
config.cache_store = :file_store, "/path/to/cache/directory"
```

With this cache store, multiple server processes on the same host can share a
cache. This cache store is appropriate for low to medium traffic sites that are
served off one or two hosts. Server processes running on different hosts could
share a cache by using a shared file system, but that setup is not recommended.

As the cache will grow until the disk is full, it is recommended to
periodically clear out old entries.

### 5.5. ActiveSupport::Cache::MemCacheStore

ActiveSupport::Cache::MemCacheStore uses Danga's memcached server to provide a centralized cache for your application. Rails uses the bundled dalli gem by default. This is currently the most popular cache store for production websites. It can be used to provide a single, shared cache cluster with very high performance and redundancy.

When initializing the cache, you should specify the addresses for all memcached servers in your cluster, or ensure the MEMCACHE_SERVERS environment variable has been set appropriately.

```ruby
config.cache_store = :mem_cache_store, "cache-1.example.com", "cache-2.example.com"
```

If neither are specified, it will assume memcached is running on localhost on the default port (127.0.0.1:11211), but this is not an ideal setup for larger sites.

```ruby
config.cache_store = :mem_cache_store # Will fallback to $MEMCACHE_SERVERS, then 127.0.0.1:11211
```

See the Dalli::Client documentation for supported address types.

The write (and fetch) method on this cache accepts additional options that take advantage of features specific to memcached.

### 5.6. ActiveSupport::Cache::RedisCacheStore

ActiveSupport::Cache::RedisCacheStore takes advantage of Redis support for automatic eviction
when it reaches max memory, allowing it to behave much like a Memcached cache server.

Deployment note: Redis doesn't expire keys by default, so take care to use a
dedicated Redis cache server. Don't fill up your persistent-Redis server with
volatile cache data! Read the
Redis cache server setup guide in detail.

For a cache-only Redis server, set maxmemory-policy to one of the variants of allkeys.
Redis 4+ supports least-frequently-used eviction (allkeys-lfu), an excellent
default choice. Redis 3 and earlier should use least-recently-used eviction (allkeys-lru).

Set cache read and write timeouts relatively low. Regenerating a cached value
is often faster than waiting more than a second to retrieve it. Both read and
write timeouts default to 1 second, but may be set lower if your network is
consistently low-latency.

By default, the cache store will attempt to reconnect to Redis once if the
connection fails during a request.

Cache reads and writes never raise exceptions; they just return nil instead,
behaving as if there was nothing in the cache. To gauge whether your cache is
hitting exceptions, you may provide an error_handler to report to an
exception gathering service. It must accept three keyword arguments: method,
the cache store method that was originally called; returning, the value that
was returned to the user, typically nil; and exception, the exception that
was rescued.

To get started, add the redis gem to your Gemfile:

```ruby
gem "redis"
```

Finally, add the configuration in the relevant config/environments/*.rb file:

```ruby
config.cache_store = :redis_cache_store, { url: ENV["REDIS_URL"] }
```

A more complex, production Redis cache store may look something like this:

```ruby
cache_servers = %w(redis://cache-01:6379/0 redis://cache-02:6379/0)
config.cache_store = :redis_cache_store, { url: cache_servers,

  connect_timeout:    30,  # Defaults to 1 second
  read_timeout:       0.2, # Defaults to 1 second
  write_timeout:      0.2, # Defaults to 1 second
  reconnect_attempts: 2,   # Defaults to 1

  error_handler: -> (method:, returning:, exception:) {
    # Report errors to Sentry as warnings
    Sentry.capture_exception exception, level: "warning",
      tags: { method: method, returning: returning }
  }
}
```

### 5.7. ActiveSupport::Cache::NullStore

ActiveSupport::Cache::NullStore is scoped to each web request, and clears stored values at the end of a request. It is meant for use in development and test environments. It can be very useful when you have code that interacts directly with Rails.cache but caching interferes with seeing the results of code changes.

```ruby
config.cache_store = :null_store
```

### 5.8. Custom Cache Stores

You can create your own custom cache store by simply extending
ActiveSupport::Cache::Store and implementing the appropriate methods. This way,
you can swap in any number of caching technologies into your Rails application.

To use a custom cache store, simply set the cache store to a new instance of your
custom class.

```ruby
config.cache_store = MyCacheStore.new
```

## 6. Cache Keys

The keys used in a cache can be any object that responds to either cache_key or
to_param. You can implement the cache_key method on your classes if you need
to generate custom keys. Active Record will generate keys based on the class name
and record id.

You can use Hashes and Arrays of values as cache keys.

```ruby
# This is a valid cache key
Rails.cache.read(site: "mysite", owners: [owner_1, owner_2])
```

The keys you use on Rails.cache will not be the same as those actually used with
the storage engine. They may be modified with a namespace or altered to fit
technology backend constraints. This means, for instance, that you can't save
values with Rails.cache and then try to pull them out with the dalli gem.
However, you also don't need to worry about exceeding the memcached size limit or
violating syntax rules.

## 7. Conditional GET Support

Conditional GETs are a feature of the HTTP specification that provide a way for web servers to tell browsers that the response to a GET request hasn't changed since the last request and can be safely pulled from the browser cache.

They work by using the HTTP_IF_NONE_MATCH and HTTP_IF_MODIFIED_SINCE headers to pass back and forth both a unique content identifier and the timestamp of when the content was last changed. If the browser makes a request where the content identifier (ETag) or last modified since timestamp matches the server's version then the server only needs to send back an empty response with a not modified status.

It is the server's (i.e. our) responsibility to look for a last modified timestamp and the if-none-match header and determine whether or not to send back the full response. With conditional-get support in Rails this is a pretty easy task:

```ruby
class ProductsController < ApplicationController
  def show
    @product = Product.find(params[:id])

    # If the request is stale according to the given timestamp and etag value
    # (i.e. it needs to be processed again) then execute this block
    if stale?(last_modified: @product.updated_at.utc, etag: @product.cache_key_with_version)
      respond_to do |wants|
        # ... normal response processing
      end
    end

    # If the request is fresh (i.e. it's not modified) then you don't need to do
    # anything. The default render checks for this using the parameters
    # used in the previous call to stale? and will automatically send a
    # :not_modified. So that's it, you're done.
  end
end
```

Instead of an options hash, you can also simply pass in a model. Rails will use the updated_at and cache_key_with_version methods for setting last_modified and etag:

```ruby
class ProductsController < ApplicationController
  def show
    @product = Product.find(params[:id])

    if stale?(@product)
      respond_to do |wants|
        # ... normal response processing
      end
    end
  end
end
```

If you don't have any special response processing and are using the default rendering mechanism (i.e. you're not using respond_to or calling render yourself) then you've got an easy helper in fresh_when:

```ruby
class ProductsController < ApplicationController
  # This will automatically send back a :not_modified if the request is fresh,
  # and will render the default template (product.*) if it's stale.

  def show
    @product = Product.find(params[:id])
    fresh_when last_modified: @product.published_at.utc, etag: @product
  end
end
```

When both last_modified and etag are set, behavior varies depending on the value of config.action_dispatch.strict_freshness.
If set to true, only the etag is considered as specified by RFC 7232 section 6.
If set to false, both are considered and the cache is considered fresh if both conditions are satisfied, as was the historical Rails behavior.

Sometimes we want to cache response, for example a static page, that never gets
expired. To achieve this, we can use http_cache_forever helper and by doing
so browser and proxies will cache it indefinitely.

By default cached responses will be private, cached only on the user's web
browser. To allow proxies to cache the response, set public: true to indicate
that they can serve the cached response to all users.

Using this helper, last_modified header is set to Time.new(2011, 1, 1).utc
and expires header is set to a 100 years.

Use this method carefully as browser/proxy won't be able to invalidate
the cached response unless browser cache is forcefully cleared.

```ruby
class HomeController < ApplicationController
  def index
    http_cache_forever(public: true) do
      render
    end
  end
end
```

### 7.1. Strong v/s Weak ETags

Rails generates weak ETags by default. Weak ETags allow semantically equivalent
responses to have the same ETags, even if their bodies do not match exactly.
This is useful when we don't want the page to be regenerated for minor changes in
response body.

Weak ETags have a leading W/ to differentiate them from strong ETags.

```
W/"618bbc92e2d35ea1945008b42799b0e7" → Weak ETag
"618bbc92e2d35ea1945008b42799b0e7" → Strong ETag
```

Unlike weak ETag, strong ETag implies that response should be exactly the same
and byte by byte identical. Useful when doing Range requests within a
large video or PDF file. Some CDNs support only strong ETags, like Akamai.
If you absolutely need to generate a strong ETag, it can be done as follows.

```ruby
class ProductsController < ApplicationController
  def show
    @product = Product.find(params[:id])
    fresh_when last_modified: @product.published_at.utc, strong_etag: @product
  end
end
```

You can also set the strong ETag directly on the response.

```ruby
response.strong_etag = response.body # => "618bbc92e2d35ea1945008b42799b0e7"
```
