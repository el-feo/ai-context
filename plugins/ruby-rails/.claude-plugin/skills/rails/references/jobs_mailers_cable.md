# Chapters

This guide provides you with all you need to get started in creating, enqueuing
and executing background jobs.

After reading this guide, you will know:

- How to create and enqueue jobs.

- How to configure and use Solid Queue.

- How to run jobs in the background.

- How to send emails from your application asynchronously.

## 1. What is Active Job?

Active Job is a framework in Rails designed for declaring background jobs and
executing them on a queuing backend. It provides a standardized interface for
tasks like sending emails, processing data, or handling regular maintenance
activities, such as clean-ups and billing charges. By offloading these tasks
from the main application thread to a queuing backend like the default Solid
Queue, Active Job ensures that time-consuming operations do not block the
request-response cycle. This can improve the performance and responsiveness of
the application, allowing it to handle tasks in parallel.

## 2. Create and Enqueue Jobs

This section will provide a step-by-step guide to create a job and enqueue it.

### 2.1. Create the Job

Active Job provides a Rails generator to create jobs. The following will create
a job in app/jobs (with an attached test case under test/jobs):

```bash
$ bin/rails generate job guests_cleanup
invoke  test_unit
create    test/jobs/guests_cleanup_job_test.rb
create  app/jobs/guests_cleanup_job.rb
```

You can also create a job that will run on a specific queue:

```bash
bin/rails generate job guests_cleanup --queue urgent
```

If you don't want to use a generator, you could create your own file inside of
app/jobs, just make sure that it inherits from ApplicationJob.

Here's what a job looks like:

```ruby
class GuestsCleanupJob < ApplicationJob
  queue_as :default

  def perform(*guests)
    # Do something later
  end
end
```

Note that you can define perform with as many arguments as you want.

If you already have an abstract class and its name differs from
ApplicationJob, you can pass the --parent option to indicate you want a
different abstract class:

```bash
bin/rails generate job process_payment --parent=payment_job
```

```ruby
class ProcessPaymentJob < PaymentJob
  queue_as :default

  def perform(*args)
    # Do something later
  end
end
```

### 2.2. Enqueue the Job

Enqueue a job using perform_later and, optionally, set. Like so:

```ruby
# Enqueue a job to be performed as soon as the queuing system is
# free.
GuestsCleanupJob.perform_later guest
```

```ruby
# Enqueue a job to be performed tomorrow at noon.
GuestsCleanupJob.set(wait_until: Date.tomorrow.noon).perform_later(guest)
```

```ruby
# Enqueue a job to be performed 1 week from now.
GuestsCleanupJob.set(wait: 1.week).perform_later(guest)
```

```ruby
# `perform_now` and `perform_later` will call `perform` under the hood so
# you can pass as many arguments as defined in the latter.
GuestsCleanupJob.perform_later(guest1, guest2, filter: "some_filter")
```

That's it!

### 2.3. Enqueue Jobs in Bulk

You can enqueue multiple jobs at once using
perform_all_later.
For more details see Bulk Enqueuing.

## 3. Default Backend: Solid Queue

Solid Queue, which is enabled by default from Rails version 8.0 and onward, is a
database-backed queuing system for Active Job, allowing you to queue large
amounts of data without requiring additional dependencies such as Redis.

Besides regular job enqueuing and processing, Solid Queue supports delayed jobs,
concurrency controls, numeric priorities per job, priorities by queue order, and
more.

### 3.1. Set Up

#### 3.1.1. Development

In development, Rails provides an asynchronous in-process queuing system, which
keeps the jobs in RAM. If the process crashes or the machine is reset, then all
outstanding jobs are lost with the default async backend. This can be fine for
smaller apps or non-critical jobs in development.

However, if you use Solid Queue instead, you can configure it in the same way as
in the production environment:

```ruby
# config/environments/development.rb
config.active_job.queue_adapter = :solid_queue
config.solid_queue.connects_to = { database: { writing: :queue } }
```

which sets the :solid_queue adapter as the default for Active Job in the
development environment, and connects to the queue database for writing.

Thereafter, you'd add queue to the development database configuration:

```yaml
# config/database.yml
development:
  primary:
    <<: *default
    database: storage/development.sqlite3
  queue:
    <<: *default
    database: storage/development_queue.sqlite3
    migrations_paths: db/queue_migrate
```

The key queue from the database configuration needs to match the key
used in the configuration for config.solid_queue.connects_to.

You can then run db:prepare to ensure the queue database in development has all the required tables:

```bash
bin/rails db:prepare
```

You can find the default generated schema for the queue database in
db/queue_schema.rb. They will contain tables like
solid_queue_ready_executions, solid_queue_scheduled_executions, and more.

Finally, to start the queue and start processing jobs you can run:

```bash
bin/jobs start
```

#### 3.1.2. Production

Solid Queue is already configured for the production environment. If you open
config/environments/production.rb, you will see the following:

```ruby
# config/environments/production.rb
# Replace the default in-process and non-durable queuing backend for Active Job.
config.active_job.queue_adapter = :solid_queue
config.solid_queue.connects_to = { database: { writing: :queue } }
```

Additionally, the database connection for the queue database is configured in
config/database.yml:

```yaml
# config/database.yml
# Store production database in the storage/ directory, which by default
# is mounted as a persistent Docker volume in config/deploy.yml.
production:
  primary:
    <<: *default
    database: storage/production.sqlite3
  queue:
    <<: *default
    database: storage/production_queue.sqlite3
    migrations_paths: db/queue_migrate
```

Make sure you run db:prepare so your database is ready to use:

```bash
bin/rails db:prepare
```

### 3.2. Configuration

The configuration options for Solid Queue are defined in config/queue.yml.
Here is an example of the default configuration:

```yaml
default: &default
  dispatchers:
    - polling_interval: 1
      batch_size: 500
  workers:
    - queues: "*"
      threads: 3
      processes: <%= ENV.fetch("JOB_CONCURRENCY", 1) %>
      polling_interval: 0.1
```

In order to understand the configuration options for Solid Queue, you must
understand the different types of roles:

- Dispatchers: They select jobs scheduled to run for the future. When it's
time for these jobs to run, dispatchers move them from the
solid_queue_scheduled_executions table to the solid_queue_ready_executions
table so workers can pick them up. They also manage concurrency-related
maintenance.

- Workers: They pick up jobs that are ready to run. These jobs are taken
from the solid_queue_ready_executions table.

- Scheduler: This takes care of recurring tasks, adding jobs to the queue
when they're due.

- Supervisor: It oversees the whole system, managing workers and
dispatchers. It starts and stops them as needed, monitors their health, and
ensures everything runs smoothly.

Everything is optional in the config/queue.yml. If no configuration is
provided, Solid Queue will run with one dispatcher and one worker with default
settings. Below are some of the configuration options you can set in
config/queue.yml:

You can read more about these configuration options in the Solid Queue
documentation.
There are also additional configuration
options
that can be set in config/<environment>.rb to further configure Solid Queue in
your Rails Application.

### 3.3. Queue Order

As per the configuration options in the Configuration section,
the queues configuration option will list the queues that workers will pick
jobs from. In a list of queues, the order matters. Workers will pick jobs from
the first queue in the list - once there are no more jobs in the first queue,
only then will it move onto the second, and so on.

```yaml
# config/queue.yml
production:
  workers:
    - queues:[active_storage*, mailers]
      threads: 3
      polling_interval: 5
```

In the above example, workers will fetch jobs from queues starting with
"active_storage", like  the active_storage_analyse queue and
active_storage_transform queue. Only when no jobs remain in the
active_storage-prefixed queues will workers move on to the mailers queue.

The wildcard *(like at the end of "active_storage") is only allowed on
its own or at the end of a queue name to match all queues with the same prefix.
You can't specify queue names such as*_some_queue.

Using wildcard queue names (e.g., queues: active_storage*) can slow
down polling performance in SQLite and PostgreSQL due to the need for a DISTINCT
query to identify all matching queues, which can be slow on large tables in these RDBMS.
For better performance, it’s best to specify exact queue names instead of using
wildcards. Read more about this in Queues specification and performance in the
Solid Queue documentation

Active Job supports positive integer priorities when enqueuing jobs (see
Priority section). Within a single queue, jobs are picked based on
their priority (with lower integers being higher priority). However, when you
have multiple queues, the order of the queues themselves takes priority.

For example, if you have two queues, production and background, jobs in the
production queue will always be processed first, even if some jobs in the
background queue have a higher priority.

### 3.4. Threads, Processes, and Signals

In Solid Queue, parallelism is achieved through threads (configurable via the
threads parameter), processes (via the processes
parameter), or horizontal scaling. The supervisor manages
processes and responds to the following signals:

- TERM, INT: Starts graceful termination, sending a TERM signal and waiting
up to SolidQueue.shutdown_timeout. If not finished, a QUIT signal forces
processes to exit.

- QUIT: Forces immediate termination of processes.

If a worker is killed unexpectedly (e.g., with a KILL signal), in-flight jobs
are marked as failed, and errors like SolidQueue::Processes::ProcessExitError
or SolidQueue::Processes::ProcessPrunedError are raised. Heartbeat settings
help manage and detect expired processes. Read more about Threads, Processes
and Signals in the Solid Queue
documentation.

### 3.5. Errors When Enqueuing

Solid Queue raises a SolidQueue::Job::EnqueueError when Active Record errors
occur during job enqueuing. This is different from the ActiveJob::EnqueueError
raised by Active Job, which handles the error and makes perform_later return
false. This makes error handling trickier for jobs enqueued by Rails or
third-party gems like Turbo::Streams::BroadcastJob.

For recurring tasks, any errors encountered while enqueuing are logged, but they
won’t be raised. Read more about Errors When Enqueuing in the Solid Queue
documentation.

### 3.6. Concurrency Controls

Solid Queue extends Active Job with concurrency controls, allowing you to limit
how many jobs of a certain type or with specific arguments can run at the same
time. If a job exceeds the limit, it will be blocked until another job finishes
or the duration expires. For example:

```ruby
class MyJob < ApplicationJob
  limits_concurrency to: 2, key: ->(contact) { contact.account }, duration: 5.minutes

  def perform(contact)
    # perform job logic
  end
end
```

In this example, only two MyJob instances for the same account will run
concurrently. After that, other jobs will be blocked until one completes.

The group parameter can be used to control concurrency across different job
types. For instance, two different job classes that use the same group will have
their concurrency limited together:

```ruby
class Box::MovePostingsByContactToDesignatedBoxJob < ApplicationJob
  limits_concurrency key: ->(contact) { contact }, duration: 15.minutes, group: "ContactActions"
end

class Bundle::RebundlePostingsJob < ApplicationJob
  limits_concurrency key: ->(bundle) { bundle.contact }, duration: 15.minutes, group: "ContactActions"
end
```

This ensures that only one job for a given contact can run at a time, regardless
of the job class.

Read more about Concurrency Controls in the Solid Queue
documentation.

### 3.7. Error Reporting on Jobs

If your error tracking service doesn’t automatically report job errors, you can
manually hook into Active Job to report them. For example, you can add a
rescue_from block in ApplicationJob:

```ruby
class ApplicationJob < ActiveJob::Base
  rescue_from(Exception) do |exception|
    Rails.error.report(exception)
    raise exception
  end
end
```

If you use ActionMailer, you’ll need to handle errors for MailDeliveryJob
separately:

```ruby
class ApplicationMailer < ActionMailer::Base
  ActionMailer::MailDeliveryJob.rescue_from(Exception) do |exception|
    Rails.error.report(exception)
    raise exception
  end
end
```

### 3.8. Transactional Integrity on Jobs

⚠️ Having your jobs in the same ACID-compliant database as your application data
enables a powerful yet sharp tool: taking advantage of transactional integrity
to ensure some action in your app is not committed unless your job is also committed
and vice versa, and ensuring that your job won't be enqueued until the transaction
within which you're enqueuing it is committed. This can be very powerful and useful,
but it can also backfire if you base some of your logic on this behavior,
and in the future, you move to another active job backend, or if you simply move
Solid Queue to its own database, and suddenly the behavior changes under you.

Because this can be quite tricky and many people shouldn't need to worry about it,
by default Solid Queue is configured in a different database as the main app.

However, if you use Solid Queue in the same database as your app, you can make sure you
don't rely accidentallly on transactional integrity with Active Job’s
enqueue_after_transaction_commit option which can be enabled for individual jobs or
all jobs through ApplicationJob:

```ruby
class ApplicationJob < ActiveJob::Base
  self.enqueue_after_transaction_commit = true
end
```

You can also configure Solid Queue to use the same database as your app while
avoiding relying on transactional integrity by setting up a separate database
connection for Solid Queue jobs. Read more about Transactional Integrity in the
Solid Queue
documentation

### 3.9. Recurring Tasks

Solid Queue supports recurring tasks, similar to cron jobs. These tasks are
defined in a configuration file (by default, config/recurring.yml) and can be
scheduled at specific times. Here's an example of a task configuration:

```yaml
production:
  a_periodic_job:
    class: MyJob
    args: [42, { status: "custom_status" }]
    schedule: every second
  a_cleanup_task:
    command: "DeletedStuff.clear_all"
    schedule: every day at 9am
```

Each task specifies a class or command and a schedule (parsed using
Fugit). You can also pass arguments to
jobs, such as in the example for MyJob where args are passed. This can be
passed as a single argument, a hash, or an array of arguments that can also
include kwargs as the last element in the array. This allows jobs to run
periodically at specified times.

Read more about Recurring Tasks in the Solid Queue
documentation.

### 3.10. Job Tracking and Management

A tool like
mission_control-jobs can help
centralize the monitoring and management of failed jobs. It provides insights
into job statuses, failure reasons, and retry behaviors, enabling you to track
and resolve issues more effectively.

For instance, if a job fails to process a large file due to a timeout,
mission_control-jobs allows you to inspect the failure, review the job’s
arguments and execution history, and decide whether to retry, requeue, or
discard it.

## 4. Queues

With Active Job you can schedule the job to run on a specific queue using
queue_as:

```ruby
class GuestsCleanupJob < ApplicationJob
  queue_as :low_priority
  # ...
end
```

You can prefix the queue name for all your jobs using
config.active_job.queue_name_prefix in application.rb:

```ruby
# config/application.rb
module YourApp
  class Application < Rails::Application
    config.active_job.queue_name_prefix = Rails.env
  end
end
```

```ruby
# app/jobs/guests_cleanup_job.rb
class GuestsCleanupJob < ApplicationJob
  queue_as :low_priority
  # ...
end

# Now your job will run on queue production_low_priority on your
# production environment and on staging_low_priority
# on your staging environment
```

You can also configure the prefix on a per job basis.

```ruby
class GuestsCleanupJob < ApplicationJob
  queue_as :low_priority
  self.queue_name_prefix = nil
  # ...
end

# Now your job's queue won't be prefixed, overriding what
# was configured in `config.active_job.queue_name_prefix`.
```

The default queue name prefix delimiter is '_'.  This can be changed by setting
config.active_job.queue_name_delimiter in application.rb:

```ruby
# config/application.rb
module YourApp
  class Application < Rails::Application
    config.active_job.queue_name_prefix = Rails.env
    config.active_job.queue_name_delimiter = "."
  end
end
```

```ruby
# app/jobs/guests_cleanup_job.rb
class GuestsCleanupJob < ApplicationJob
  queue_as :low_priority
  # ...
end

# Now your job will run on queue production.low_priority on your
# production environment and on staging.low_priority
# on your staging environment
```

To control the queue from the job level you can pass a block to queue_as. The
block will be executed in the job context (so it can access self.arguments),
and it must return the queue name:

```ruby
class ProcessVideoJob < ApplicationJob
  queue_as do
    video = self.arguments.first
    if video.owner.premium?
      :premium_videojobs
    else
      :videojobs
    end
  end

  def perform(video)
    # Do process video
  end
end
```

```ruby
ProcessVideoJob.perform_later(Video.last)
```

If you want more control on what queue a job will be run you can pass a :queue
option to set:

```ruby
MyJob.set(queue: :another_queue).perform_later(record)
```

If you choose to use an alternate queuing
backend you may need to specify the queues to
listen to.

## 5. Priority

You can schedule a job to run with a specific priority using
queue_with_priority:

```ruby
class GuestsCleanupJob < ApplicationJob
  queue_with_priority 10
  # ...
end
```

Solid Queue, the default queuing backend, prioritizes jobs based on the order of
the queues.  You can read more about it in the Order of Queues
section. If you're using Solid Queue, and both the order of the
queues and the priority option are used, the queue order will take precedence,
and the priority option will only apply within each queue.

Other queuing backends may allow jobs to be prioritized relative to others
within the same queue or across multiple queues. Refer to the documentation of
your backend for more information.

Similar to queue_as, you can also pass a block to queue_with_priority to be
evaluated in the job context:

```ruby
class ProcessVideoJob < ApplicationJob
  queue_with_priority do
    video = self.arguments.first
    if video.owner.premium?
      0
    else
      10
    end
  end

  def perform(video)
    # Process video
  end
end
```

```ruby
ProcessVideoJob.perform_later(Video.last)
```

You can also pass a :priority option to set:

```ruby
MyJob.set(priority: 50).perform_later(record)
```

If a lower priority number performs before or after a higher priority
number depends on the adapter implementation. Refer to documentation of your
backend for more information. Adapter authors are encouraged to treat a lower
number as more important.

## 6. Job Continuations

Jobs can be split into resumable steps using continuations. This is useful when
a job may be interrupted - for example, during queue shutdown. When using
continuations, the job can resume from the last completed step, avoiding the
need to restart from the beginning.

To use continuations, include the ActiveJob::Continuable module. You can then
define each step using the step method inside the perform method. Each step can
be declared with a block or by referencing a method name.

```ruby
class ProcessImportJob < ApplicationJob
  include ActiveJob::Continuable

  def perform(import_id)
    # Always runs on job start, even when resuming from an interrupted step.
    @import = Import.find(import_id)

    # Step defined using a block
    step :initialize do
      @import.initialize
    end

    # Step with a cursor — progress is saved and resumed if the job is interrupted
    step :process do |step|
      @import.records.find_each(start: step.cursor) do |record|
        record.process
        step.advance! from: record.id
      end
    end

    # Step defined by referencing a method
    step :finalize
  end

  private
    def finalize
      @import.finalize
    end
end
```

Each step runs sequentially. If the job is interrupted between steps, or within a
step that uses a cursor, the job resumes from the last recorded position. This
makes it easier to build long-running or multi-phase jobs that can safely pause
and resume without losing progress.
For more details, see ActiveJob::Continuation.

## 7. Callbacks

Active Job provides hooks to trigger logic during the life cycle of a job. Like
other callbacks in Rails, you can implement the callbacks as ordinary methods
and use a macro-style class method to register them as callbacks:

```ruby
class GuestsCleanupJob < ApplicationJob
  queue_as :default

  around_perform :around_cleanup

  def perform
    # Do something later
  end

  private
    def around_cleanup
      # Do something before perform
      yield
      # Do something after perform
    end
end
```

The macro-style class methods can also receive a block. Consider using this
style if the code inside your block is so short that it fits in a single line.
For example, you could send metrics for every job enqueued:

```ruby
class ApplicationJob < ActiveJob::Base
  before_enqueue { |job| $statsd.increment "#{job.class.name.underscore}.enqueue" }
end
```

### 7.1. Available Callbacks

- before_enqueue

- around_enqueue

- after_enqueue

- before_perform

- around_perform

- after_perform

- after_discard

Please note that when enqueuing jobs in bulk using perform_all_later,
callbacks such as around_enqueue will not be triggered on the individual jobs.
See Bulk Enqueuing Callbacks.

## 8. Bulk Enqueuing

You can enqueue multiple jobs at once using
perform_all_later.
Bulk enqueuing reduces the number of round trips to the queue data store (like
Redis or a database), making it a more performant operation than enqueuing the
same jobs individually.

perform_all_later is a top-level API on Active Job. It accepts instantiated
jobs as arguments (note that this is different from perform_later).
perform_all_later does call perform under the hood. The arguments passed to
new will be passed on to perform when it's eventually called.

Here is an example calling perform_all_later with GuestsCleanupJob instances:

```ruby
# Create jobs to pass to `perform_all_later`.
# The arguments to `new` are passed on to `perform`
cleanup_jobs = Guest.all.map { |guest| GuestsCleanupJob.new(guest) }

# Will enqueue a separate job for each instance of `GuestsCleanupJob`
ActiveJob.perform_all_later(cleanup_jobs)

# Can also use `set` method to configure options before bulk enqueuing jobs.
cleanup_jobs = Guest.all.map { |guest| GuestsCleanupJob.new(guest).set(wait: 1.day) }

ActiveJob.perform_all_later(cleanup_jobs)
```

perform_all_later logs the number of jobs successfully enqueued, for example
if Guest.all.map above resulted in 3 cleanup_jobs, it would log
Enqueued 3 jobs to Async (3 GuestsCleanupJob) (assuming all were enqueued).

The return value of perform_all_later is nil. Note that this is different
from perform_later, which returns the instance of the queued job class.

### 8.1. Enqueue Multiple Active Job Classes

With perform_all_later, it's also possible to enqueue different Active Job
class instances in the same call. For example:

```ruby
class ExportDataJob < ApplicationJob
  def perform(*args)
    # Export data
  end
end

class NotifyGuestsJob < ApplicationJob
  def perform(*guests)
    # Email guests
  end
end

# Instantiate job instances
cleanup_job = GuestsCleanupJob.new(guest)
export_job = ExportDataJob.new(data)
notify_job = NotifyGuestsJob.new(guest)

# Enqueues job instances from multiple classes at once
ActiveJob.perform_all_later(cleanup_job, export_job, notify_job)
```

### 8.2. Bulk Enqueue Callbacks

When enqueuing jobs in bulk using perform_all_later, callbacks such as
around_enqueue will not be triggered on the individual jobs. This behavior is
in line with other Active Record bulk methods. Since callbacks run on individual
jobs, they can't take advantage of the bulk nature of this method.

However, the perform_all_later method does fire an
enqueue_all.active_job
event which you can subscribe to using ActiveSupport::Notifications.

The method
successfully_enqueued?
can be used to find out if a given job was successfully enqueued.

### 8.3. Queue Backend Support

For perform_all_later, bulk enqueuing needs to be backed by the queue backend.
Solid Queue, the default queue backend, supports bulk enqueuing using
enqueue_all.

Other backends like Sidekiq have a push_bulk
method, which can push a large number of jobs to Redis and prevent the round
trip network latency. GoodJob also supports bulk enqueuing with the
GoodJob::Bulk.enqueue method.

If the queue backend does not support bulk enqueuing, perform_all_later will
enqueue jobs one by one.

## 9. Action Mailer

One of the most common jobs in a modern web application is sending emails
outside of the request-response cycle, so the user doesn't have to wait on it.
Active Job is integrated with Action Mailer so you can easily send emails
asynchronously:

```ruby
# If you want to send the email now use #deliver_now
UserMailer.welcome(@user).deliver_now

# If you want to send the email through Active Job use #deliver_later
UserMailer.welcome(@user).deliver_later
```

Using the asynchronous queue from a Rake task (for example, to send an
email using .deliver_later) will generally not work because Rake will likely
end, causing the in-process thread pool to be deleted, before any/all of the
.deliver_later emails are processed. To avoid this problem, use .deliver_now
or run a persistent queue in development.

## 10. Internationalization

Each job uses the I18n.locale set when the job was created. This is useful if
you send emails asynchronously:

```ruby
I18n.locale = :eo

UserMailer.welcome(@user).deliver_later # Email will be localized to Esperanto.
```

## 11. Supported Types for Arguments

ActiveJob supports the following types of arguments by default:

- Basic types (NilClass, String, Integer, Float, BigDecimal,
TrueClass, FalseClass)

- Symbol

- Date

- Time

- DateTime

- ActiveSupport::TimeWithZone

- ActiveSupport::Duration

- Hash (Keys should be of String or Symbol type)

- ActiveSupport::HashWithIndifferentAccess

- Array

- Range

- Module

- Class

### 11.1. GlobalID

Active Job supports
GlobalID for
parameters. This makes it possible to pass live Active Record objects to your
job instead of class/id pairs, which you then have to manually deserialize.
Before, jobs would look like this:

```ruby
class TrashableCleanupJob < ApplicationJob
  def perform(trashable_class, trashable_id, depth)
    trashable = trashable_class.constantize.find(trashable_id)
    trashable.cleanup(depth)
  end
end
```

Now you can simply do:

```ruby
class TrashableCleanupJob < ApplicationJob
  def perform(trashable, depth)
    trashable.cleanup(depth)
  end
end
```

This works with any class that mixes in GlobalID::Identification, which by
default has been mixed into Active Record classes.

### 11.2. Serializers

You can extend the list of supported argument types. You just need to define
your own serializer:

```ruby
# app/serializers/money_serializer.rb
class MoneySerializer < ActiveJob::Serializers::ObjectSerializer
  # Converts an object to a simpler representative using supported object types.
  # The recommended representative is a Hash with a specific key. Keys can be of basic types only.
  # You should call `super` to add the custom serializer type to the hash.
  def serialize(money)
    super(
      "amount" => money.amount,
      "currency" => money.currency
    )
  end

  # Converts serialized value into a proper object.
  def deserialize(hash)
    Money.new(hash["amount"], hash["currency"])
  end

  private
    # Checks if an argument should be serialized by this serializer.
    def klass
      Money
    end
end
```

and add this serializer to the list:

```ruby
# config/initializers/custom_serializers.rb
Rails.application.config.active_job.custom_serializers << MoneySerializer
```

Note that autoloading reloadable code during initialization is not supported.
Thus it is recommended to set-up serializers to be loaded only once, e.g. by
amending config/application.rb like this:

```ruby
# config/application.rb
module YourApp
  class Application < Rails::Application
    config.autoload_once_paths << "#{root}/app/serializers"
  end
end
```

## 12. Exceptions

Exceptions raised during the execution of the job can be handled with
rescue_from:

```ruby
class GuestsCleanupJob < ApplicationJob
  queue_as :default

  rescue_from(ActiveRecord::RecordNotFound) do |exception|
    # Do something with the exception
  end

  def perform
    # Do something later
  end
end
```

If an exception from a job is not rescued, then the job is referred to as
"failed".

### 12.1. Retrying or Discarding Failed Jobs

A failed job will not be retried, unless configured otherwise.

It's possible to retry or discard a failed job by using retry_on or
discard_on, respectively. For example:

```ruby
class RemoteServiceJob < ApplicationJob
  retry_on CustomAppException # defaults to 3s wait, 5 attempts

  discard_on ActiveJob::DeserializationError

  def perform(*args)
    # Might raise CustomAppException or ActiveJob::DeserializationError
  end
end
```

### 12.2. Deserialization

GlobalID allows serializing full Active Record objects passed to #perform.

If a passed record is deleted after the job is enqueued but before the
# perform method is called Active Job will raise an
ActiveJob::DeserializationError exception.

## 13. Job Testing

You can find detailed instructions on how to test your jobs in the testing
guide.

## 14. Debugging

If you need help figuring out where jobs are coming from, you can enable
verbose logging.

## 15. Alternate Queuing Backends

Active Job has other built-in adapters for multiple queuing backends (Sidekiq,
Resque, Delayed Job, and others). To get an up-to-date list of the adapters see
the API Documentation for ActiveJob::QueueAdapters.

### 15.1. Configuring the Backend

You can change your queuing backend with config.active_job.queue_adapter:

```ruby
# config/application.rb
module YourApp
  class Application < Rails::Application
    # Be sure to have the adapter's gem in your Gemfile
    # and follow the adapter's specific installation
    # and deployment instructions.
    config.active_job.queue_adapter = :sidekiq
  end
end
```

You can also configure your backend on a per job basis:

```ruby
class GuestsCleanupJob < ApplicationJob
  self.queue_adapter = :resque
  # ...
end

# Now your job will use `resque` as its backend queue adapter, overriding the default Solid Queue adapter.
```

### 15.2. Starting the Backend

Since jobs run in parallel to your Rails application, most queuing libraries
require that you start a library-specific queuing service (in addition to
starting your Rails app) for the job processing to work. Refer to library
documentation for instructions on starting your queue backend.

Here is a noncomprehensive list of documentation:

- Sidekiq

- Resque

- Sneakers

- Queue Classic

- Delayed Job

- Que

- Good Job

---

# Chapters

This guide covers sending emails from your Rails application.

After reading this guide, you will know:

- How to generate and edit Action Mailer classes and mailer views.

- How to send attachments and multipart emails.

- How to use Action Mailer callbacks.

- How to configure Action Mailer for your environment.

- How to preview emails and test your Action Mailer classes.

## 1. What is Action Mailer?

Action Mailer allows you to send emails from your Rails application. It's one of
the two email related components in the Rails framework. The other is Action
Mailbox, which deals with receiving emails.

Action Mailer uses classes (called "mailers") and views to create and configure
the email to send. Mailers are classes that inherit from
ActionMailer::Base. Mailer classes are similar to controller classes. Both
have:

- Instance variables that are accessible in views.

- The ability to use layouts and partials.

- The ability to access a params hash.

- Actions and associated views in app/views.

## 2. Creating a Mailer and Views

This section will provide a step-by-step guide to sending email with Action
Mailer. Here are the details of each step.

### 2.1. Generate the Mailer

First, you use the "mailer" generator to create the Mailer related classes:

```bash
$ bin/rails generate mailer User
create  app/mailers/user_mailer.rb
invoke  erb
create    app/views/user_mailer
invoke  test_unit
create    test/mailers/user_mailer_test.rb
create    test/mailers/previews/user_mailer_preview.rb
```

Like the UserMailer below, all generated Mailer classes inherit from
ApplicationMailer:

```ruby
# app/mailers/user_mailer.rb
class UserMailer < ApplicationMailer
end
```

The ApplicationMailer class inherits from ActionMailer::Base, and can be
used to define attributes common to all Mailers:

```ruby
# app/mailers/application_mailer.rb
class ApplicationMailer < ActionMailer::Base
  default from: "from@example.com"
  layout "mailer"
end
```

If you don't want to use a generator, you can also manually add a file to the
app/mailers directory. Make sure that your class inherits from
ApplicationMailer:

```ruby
# app/mailers/custom_mailer.rb
class CustomMailer < ApplicationMailer
end
```

### 2.2. Edit the Mailer

The UserMailer in app/mailers/user_mailer.rb initially doesn't have any methods. So next, we add
methods (aka actions) to the mailer that will send specific emails.

Mailers have methods called "actions" and they use views to structure their
content, similar to controllers. While a controller generates HTML content to
send back to the client, a Mailer creates a message to be delivered via email.

Let's add a method called welcome_email to the UserMailer, that will send an
email to the user's registered email address:

```ruby
class UserMailer < ApplicationMailer
  default from: "notifications@example.com"

  def welcome_email
    @user = params[:user]
    @url  = "http://example.com/login"
    mail(to: @user.email, subject: "Welcome to My Awesome Site")
  end
end
```

The method names in mailers do not have to end in _email.

Here is a quick explanation of the Mailer related methods used above:

- The default method sets default values for all emails sent from this
mailer. In this case, we use it to set the :from header value for all
messages in this class. This can be overridden on a per-email basis.

- The mail method creates the actual email message. We use it to specify
the values of headers like :to and :subject per email.

There is also the headers method (not used above), which is used to
specify email headers with a hash or by calling headers[:field_name] = 'value'.

It is possible to specify an action directly while using the generator like
this:

```bash
bin/rails generate mailer User welcome_email
```

The above will generate the UserMailer with an empty welcome_email method.

You can also send multiple emails from a single mailer class. It can be
convenient to group related emails together. For example, the above UserMailer
can have a goodbye_email (and corresponding view) in addition to the
welcome_email.

### 2.3. Create a Mailer View

Next, for the welcome_email action, you'll need to create a matching view in a
file called welcome_email.html.erb in the app/views/user_mailer/ directory.
Here is a sample HTML template that can be used for the welcome email:

```ruby
<h1>Welcome to example.com, <%= @user.name %></h1>
<p>
  You have successfully signed up to example.com,
  your username is: <%= @user.login %>.<br>
</p>
<p>
  To log in to the site, just follow this link: <%= link_to 'login', login_url %>.
</p>
<p>Thanks for joining and have a great day!</p>
```

The above is the content of the <body> tag. It will be embedded in the
default mailer layout, which contains the <html> tag. See Mailer
layouts for more.

You can also create a text version of the above email and store it in
welcome_email.text.erb in the app/views/user_mailer/ directory (notice the
.text.erb extension vs. the html.erb). Sending both formats is considered
best practice because, in case of HTML rendering issues, the text version can
serve as a reliable fallback. Here is a sample text email:

```ruby
Welcome to example.com, <%= @user.name %>
===============================================

You have successfully signed up to example.com,
your username is: <%= @user.login %>.

To log in to the site, just follow this link: <%= @url %>.

Thanks for joining and have a great day!
```

Notice that in both HTML and text email templates you can use the instance
variables @user and @url.

Now, when you call the mail method, Action Mailer will detect the two
templates (text and HTML) and automatically generate a multipart/alternative
email.

### 2.4. Call the Mailer

Once you have a mailer class and view set up, the next step is to actually call
the mailer method that renders the email view (i.e. sends the email). Mailers
can be thought of as another way of rendering views. Controller actions render a
view to be sent over the HTTP protocol. Mailer actions render a view and send it
through email protocols instead.

Let's see an example of using the UserMailer to send a welcome email when a
user is successfully created.

First, let's create a User scaffold:

```bash
bin/rails generate scaffold user name email login
bin/rails db:migrate
```

Next, we edit the create action in the UserController to send a welcome
email when a new user is created. We do this by inserting a call to
UserMailer.with(user: @user).welcome_email right after the user is
successfully saved.

We use deliver_later to enqueue the email to be sent later. This
way, the controller action will continue without waiting for the email sending
code to run. The deliver_later method is backed by Active
Job.

```ruby
class UsersController < ApplicationController
  # ...

  def create
    @user = User.new(user_params)

    respond_to do |format|
      if @user.save
        # Tell the UserMailer to send a welcome email after save
        UserMailer.with(user: @user).welcome_email.deliver_later

        format.html { redirect_to user_url(@user), notice: "User was successfully created." }
        format.json { render :show, status: :created, location: @user }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @user.errors, status: :unprocessable_entity }
      end
    end
  end

  # ...
end
```

Any key-value pair passed to with becomes the params for the Mailer
action. For example, with(user: @user, account: @user.account) makes
params[:user] and params[:account] available in the Mailer action.

With the above mailer, view, and controller set up, if you create a new User,
you can examine the logs to see the welcome email being sent. The log file will
show the text and HTML versions being sent, like this:

```bash
[ActiveJob] [ActionMailer::MailDeliveryJob] [ec4b3786-b9fc-4b5e-8153-9153095e1cbf] Delivered mail 6661f55087e34_1380c7eb86934d@Bhumis-MacBook-Pro.local.mail (19.9ms)
[ActiveJob] [ActionMailer::MailDeliveryJob] [ec4b3786-b9fc-4b5e-8153-9153095e1cbf] Date: Thu, 06 Jun 2024 12:43:44 -0500
From: notifications@example.com
To: test@gmail.com
Message-ID: <6661f55087e34_1380c7eb86934d@Bhumis-MacBook-Pro.local.mail>
Subject: Welcome to My Awesome Site
Mime-Version: 1.0
Content-Type: multipart/alternative;
 boundary="--==_mimepart_6661f55086194_1380c7eb869259";
 charset=UTF-8
Content-Transfer-Encoding: 7bit


----==_mimepart_6661f55086194_1380c7eb869259
Content-Type: text/plain;

...

----==_mimepart_6661f55086194_1380c7eb869259
Content-Type: text/html;

...
```

You can also call the mailer from the Rails console and send emails, perhaps
useful as a test before you have a controller action set up. The below will send
the same welcome_email as above:

```
irb> user = User.first
irb> UserMailer.with(user: user).welcome_email.deliver_later
```

If you want to send emails right away (from a cronjob for example) you can call
deliver_now:

```ruby
class SendWeeklySummary
  def run
    User.find_each do |user|
      UserMailer.with(user: user).weekly_summary.deliver_now
    end
  end
end
```

A method like weekly_summary from UserMailer would return an
ActionMailer::MessageDelivery object, which has the methods deliver_now
or deliver_later to send itself now or later. The
ActionMailer::MessageDelivery object is a wrapper around a
Mail::Message. If you want to inspect, alter, or do anything else with the
Mail::Message object you can access it with the message method on the
ActionMailer::MessageDelivery object.

Here is an example of the MessageDelivery object from the Rails console
example above:

```
irb> UserMailer.with(user: user).weekly_summary
#<ActionMailer::MailDeliveryJob:0x00007f84cb0367c0
 @_halted_callback_hook_called=nil,
 @_scheduled_at_time=nil,
 @arguments=
  ["UserMailer",
   "welcome_email",
   "deliver_now",
   {:params=>
     {:user=>
       #<User:0x00007f84c9327198
        id: 1,
        name: "Bhumi",
        email: "hi@gmail.com",
        login: "Bhumi",
        created_at: Thu, 06 Jun 2024 17:43:44.424064000 UTC +00:00,
        updated_at: Thu, 06 Jun 2024 17:43:44.424064000 UTC +00:00>},
    :args=>[]}],
 @exception_executions={},
 @executions=0,
 @job_id="07747748-59cc-4e88-812a-0d677040cd5a",
 @priority=nil,
```

## 3. Multipart Emails and Attachments

The multipart MIME type represents a document that's comprised of multiple component parts, each of which may have its own individual MIME type (such as the text/html and text/plain). The multipart type encapsulates sending multiple files together in one transaction such as attaching multiple files to an email for example.

### 3.1. Adding Attachments

You can add an attachment with Action Mailer by passing the file name and
content to the attachments
method.
Action Mailer will automatically guess the mime_type, set the encoding, and
create the attachment.

```ruby
attachments["filename.jpg"] = File.read("/path/to/filename.jpg")
```

When the mail method is triggered, it will send a multipart email with an
attachment, properly nested with the top level being multipart/mixed and the
first part being a multipart/alternative containing the plain text and HTML
email messages.

The other way to send attachments is to specify the file name, MIME-type and
encoding headers, and content. Action Mailer will use the settings you pass in.

```ruby
encoded_content = SpecialEncode(File.read("/path/to/filename.jpg"))
attachments["filename.jpg"] = {
  mime_type: "application/gzip",
  encoding: "SpecialEncoding",
  content: encoded_content
}
```

Action Mailer will automatically Base64 encode an attachment. If you want
something different, you can encode your content and pass in the encoded content
as well as the encoding in a Hash to the attachments method. If you specify
an encoding, Action Mailer will not try to Base64 encode the attachment.

### 3.2. Making Inline Attachments

Sometimes, you may want to send an attachment (e.g. image) inline, so it appears
within the email body.

In order to do this, first, you turn an attachment into an inline attachment by
calling #inline:

```ruby
def welcome
  attachments.inline["image.jpg"] = File.read("/path/to/image.jpg")
end
```

Then in the view, you can reference attachments as a hash and specify the file
you want to show inline. You can call url on the hash and pass the result into
the
image_tag
method:

```ruby
<p>Hello there, this is the image you requested:</p>

<%= image_tag attachments['image.jpg'].url %>
```

Since this is a standard call to image_tag you can pass in an options hash
after the attachment URL as well:

```ruby
<p>Hello there, this is our image</p>

<%= image_tag attachments['image.jpg'].url, alt: 'My Photo', class: 'photos' %>
```

### 3.3. Multipart Emails

As demonstrated in Create a Mailer View, Action Mailer
will automatically send multipart emails if you have different templates for the
same action. For example, if you have a UserMailer with
welcome_email.text.erb and welcome_email.html.erb in
app/views/user_mailer, Action Mailer will automatically send a multipart email
with both the HTML and text versions included as separate parts.

The Mail gem has helper methods for making a
multipart/alternate email for text/plain and text/html MIME
types
and you can manually create any other type of MIME email.

The order of the parts getting inserted is determined by the
:parts_order inside of the ActionMailer::Base.default method.

Multipart is also used when you send attachments with email.

## 4. Mailer Views and Layouts

Action Mailer uses view files to specify the content to be sent in emails.
Mailer views are located in the app/views/name_of_mailer_class directory by
default. Similar to a controller view, the name of the file matches the name of
the mailer method.

Mailer views are rendered within a layout, similar to controller views. Mailer
layouts are located in app/views/layouts. The default layout is
mailer.html.erb and mailer.text.erb. This section covers various features
around mailer views and layouts.

### 4.1. Configuring Custom View Paths

It is possible to change the default mailer view for your action in various
ways, as shown below.

There are template_path and template_name options to the mail method:

```ruby
class UserMailer < ApplicationMailer
  default from: "notifications@example.com"

  def welcome_email
    @user = params[:user]
    @url  = "http://example.com/login"
    mail(to: @user.email,
         subject: "Welcome to My Awesome Site",
         template_path: "notifications",
         template_name: "hello")
  end
end
```

The above configures the mail method to look for a template with the name
hello in the app/views/notifications directory.  You can also specify an
array of paths for template_path, and they will be searched in order.

If you need more flexibility, you can also pass a block and render a specific
template. You can also render plain text inline without using a template file:

```ruby
class UserMailer < ApplicationMailer
  default from: "notifications@example.com"

  def welcome_email
    @user = params[:user]
    @url  = "http://example.com/login"
    mail(to: @user.email,
         subject: "Welcome to My Awesome Site") do |format|
      format.html { render "another_template" }
      format.text { render plain: "hello" }
    end
  end
end
```

This will render the template another_template.html.erb for the HTML part and
"hello" for the text part. The
render
method is the same one used inside of Action Controller, so you can use all the
same options, such as :plain, :inline, etc.

Lastly, if you need to render a template located outside of the default
app/views/mailer_name/ directory, you can apply the prepend_view_path,
like so:

```ruby
class UserMailer < ApplicationMailer
  prepend_view_path "custom/path/to/mailer/view"

  # This will try to load "custom/path/to/mailer/view/welcome_email" template
  def welcome_email
    # ...
  end
end
```

There is also an append_view_path method.

### 4.2. Generating URLs in Action Mailer Views

In order to add URLs to your mailer, you need to set the host value to your
application's domain first. This is because, unlike controllers, the mailer
instance doesn't have any context about the incoming request.

You can configure the default host across the application in
config/application.rb:

```ruby
config.action_mailer.default_url_options = { host: "example.com" }
```

Once the host is configured, it is recommended that email views use the
*_url with the full URL, and not the*_path helpers with relative URL. Since
email clients do not have web request context, *_path helpers have no base URL
to form complete web addresses.

For example, instead of:

```ruby
<%= link_to 'welcome', welcome_path %>
```

Use:

```ruby
<%= link_to 'welcome', welcome_url %>
```

By using the full URL, your links will work correctly in your emails.

#### 4.2.1. Generating URLs with url_for

The url_for helper generates a full URL, by default, in templates.

If you haven't configured the :host option globally, you'll need to pass it to
url_for.

```ruby
<%= url_for(host: 'example.com',
            controller: 'welcome',
            action: 'greeting') %>
```

#### 4.2.2. Generating URLs with Named Routes

Similar to other URLs, you need to use the *_url variant of named route
helpers in emails as well.

You either configure the :host option globally or make sure to pass it to the
URL helper:

```ruby
<%= user_url(@user, host: 'example.com') %>
```

### 4.3. Adding Images in Action Mailer Views

In order to use the image_tag helper in emails, you need to specify the
:asset_host parameter. This is because a mailer instance doesn't have any
context about the incoming request.

Usually the :asset_host is consistent across the application, so you can
configure it globally in config/application.rb:

```ruby
config.action_mailer.asset_host = "http://example.com"
```

Because we can't infer the protocol from the request, you'll need to
specify a protocol such as http:// or https:// in the :asset_host config.

Now you can display an image inside your email.

```ruby
<%= image_tag 'image.jpg' %>
```

### 4.4. Caching Mailer View

You can perform fragment caching in mailer views, similar to application views,
using the cache method.

```ruby
<% cache do %>
  <%= @company.name %>
<% end %>
```

And to use this feature, you need to enable it in your application's
config/environments/*.rb file:

```ruby
config.action_mailer.perform_caching = true
```

Fragment caching is also supported in multipart emails. Read more about caching
in the Rails caching guide.

### 4.5. Action Mailer Layouts

Just like controller layouts, you can also have mailer layouts. Mailer layouts
are located in app/views/layouts. Here is the default layout:

```html
# app/views/layouts/mailer.html.erb
<!DOCTYPE html>
<html>
  <head>
    <meta http-equiv="Content-Type" content="text/html; charset=utf-8">
    <style>
      /* Email styles need to be inline */
    </style>
  </head>

  <body>
    <%= yield %>
  </body>
</html>
```

The above layout is in a file mailer.html.erb. The default layout name is
specified in the ApplicationMailer, as we saw earlier with the line layout
"mailer" in the Generate Mailer section. Similar to
controller layouts, you use yield to render the mailer view inside the layout.

To use a different layout for a given mailer, call layout:

```ruby
class UserMailer < ApplicationMailer
  layout "awesome" # Use awesome.(html|text).erb as the layout
end
```

To use a specific layout for a given email, you can pass in a layout:
'layout_name' option to the render call inside the format block:

```ruby
class UserMailer < ApplicationMailer
  def welcome_email
    mail(to: params[:user].email) do |format|
      format.html { render layout: "my_layout" }
      format.text
    end
  end
end
```

The above will render the HTML part using the my_layout.html.erb file and the
text part with the usual user_mailer.text.erb file.

## 5. Sending Email

### 5.1. Sending Email to Multiple Recipients

It is possible to send an email to more than one recipient by setting the :to
field to a list of email addresses. The list of emails can be an array or a
single string with the addresses separated by commas.

For example, to inform all admins of a new registration:

```ruby
class AdminMailer < ApplicationMailer
  default to: -> { Admin.pluck(:email) },
          from: "notification@example.com"

  def new_registration(user)
    @user = user
    mail(subject: "New User Signup: #{@user.email}")
  end
end
```

The same format can be used to add multiple carbon copy (cc) and blind carbon
copy (bcc) recipients, by setting the :cc and :bcc keys respectively
(similarly to the :to field).

### 5.2. Sending Email with Name

It's possible to show the name, in addition to the email address, of the person
who receives the email or sends the email.

To show the name of the person when they receive the email, you can use
email_address_with_name method in to::

```ruby
def welcome_email
  @user = params[:user]
  mail(
    to: email_address_with_name(@user.email, @user.name),
    subject: "Welcome to My Awesome Site"
  )
end
```

The same method in from: works to display the name of the sender:

```ruby
class UserMailer < ApplicationMailer
  default from: email_address_with_name("notification@example.com", "Example Company Notifications")
end
```

If the name is blank (nil or empty string), it returns the email address.

### 5.3. Sending Email with Subject Translation

If you don't pass a subject to the mail method, Action Mailer will try to find
it in your translations. See the Internationalization
Guide for more.

### 5.4. Sending Emails without Template Rendering

There may be cases in which you want to skip the template rendering step and
instead supply the email body as a string. You can achieve this using the
:body option. Remember to set the :content_type option, such as setting it
to text/html below. Rails will default to text/plain as the content type.

```ruby
class UserMailer < ApplicationMailer
  def welcome_email
    mail(to: params[:user].email,
         body: params[:email_body],
         content_type: "text/html",
         subject: "Already rendered!")
  end
end
```

### 5.5. Sending Emails with Dynamic Delivery Options

If you wish to override the default delivery
configuration (e.g. SMTP credentials) while
delivering emails, you can do this using delivery_method_options in the mailer
action.

```ruby
class UserMailer < ApplicationMailer
  def welcome_email
    @user = params[:user]
    @url  = user_url(@user)
    delivery_options = { user_name: params[:company].smtp_user,
                         password: params[:company].smtp_password,
                         address: params[:company].smtp_host }
    mail(to: @user.email,
         subject: "Please see the Terms and Conditions attached",
         delivery_method_options: delivery_options)
  end
end
```

## 6. Action Mailer Callbacks

Action Mailer allows for you to specify *_action callbacks to configure the message, and*_deliver callbacks to control the delivery.

Here is a list with all the available Action Mailer callbacks, listed in the order in which they will get called when sending an email:

- before_action

- around_action

- after_action

- before_deliver

- around_deliver

- after_deliver

Callbacks can be specified with a block or a symbol representing a method name in the mailer class, similar to other callbacks (in controllers or models).

Here are some examples of when you may use one of these callbacks with mailers.

### 6.1. before_action

You can use a before_action to set instance variables, populate the mail
object with defaults, or insert default headers and attachments.

```ruby
class InvitationsMailer < ApplicationMailer
  before_action :set_inviter_and_invitee
  before_action { @account = params[:inviter].account }

  default to:       -> { @invitee.email_address },
          from:     -> { common_address(@inviter) },
          reply_to: -> { @inviter.email_address_with_name }

  def account_invitation
    mail subject: "#{@inviter.name} invited you to their Basecamp (#{@account.name})"
  end

  def project_invitation
    @project    = params[:project]
    @summarizer = ProjectInvitationSummarizer.new(@project.bucket)

    mail subject: "#{@inviter.name.familiar} added you to a project in Basecamp (#{@account.name})"
  end

  private
    def set_inviter_and_invitee
      @inviter = params[:inviter]
      @invitee = params[:invitee]
    end
end
```

### 6.2. after_action

You can use an after_action callback with a similar setup as a before_action
but also have access to instance variables that were set in your mailer action.

You can also use an after_action to override delivery method settings by
updating mail.delivery_method.settings.

```ruby
class UserMailer < ApplicationMailer
  before_action { @business, @user = params[:business], params[:user] }

  after_action :set_delivery_options,
               :prevent_delivery_to_guests,
               :set_business_headers

  def feedback_message
  end

  def campaign_message
  end

  private
    def set_delivery_options
      # You have access to the mail instance,
      # @business and @user instance variables here
      if @business && @business.has_smtp_settings?
        mail.delivery_method.settings.merge!(@business.smtp_settings)
      end
    end

    def prevent_delivery_to_guests
      if @user && @user.guest?
        mail.perform_deliveries = false
      end
    end

    def set_business_headers
      if @business
        headers["X-SMTPAPI-CATEGORY"] = @business.code
      end
    end
end
```

### 6.3. after_deliver

You could use an after_deliver to record the delivery of the message. It also
allows observer/interceptor-like behaviors, but with access to the full mailer
context.

```ruby
class UserMailer < ApplicationMailer
  after_deliver :mark_delivered
  before_deliver :sandbox_staging
  after_deliver :observe_delivery

  def feedback_message
    @feedback = params[:feedback]
  end

  private
    def mark_delivered
      params[:feedback].touch(:delivered_at)
    end

    # An Interceptor alternative.
    def sandbox_staging
      message.to = ["sandbox@example.com"] if Rails.env.staging?
    end

    # A callback has more context than the comparable Observer example.
    def observe_delivery
      EmailDelivery.log(message, self.class, action_name, params)
    end
end
```

Mailer callbacks abort further processing if body is set to a non-nil value.
before_deliver can abort with throw :abort.

## 7. Action Mailer View Helpers

Action Mailer views have access to most of the same helpers as regular views.

There are also some Action Mailer-specific helper methods available in
ActionMailer::MailHelper. For example, these allow accessing the mailer
instance from your view with mailer, and accessing the
message as message:

```ruby
<%= stylesheet_link_tag mailer.name.underscore %>
<h1><%= message.subject %></h1>
```

## 8. Action Mailer Configuration

This section shows some example configurations for Action Mailer.

For more details on the various configuration options, see the Configuring
Rails Applications guide. You can
specify configuration options in environment specific files such as
production.rb.

### 8.1. Example Action Mailer Configuration

Here is an example using the :sendmail delivery method, added to a
config/environments/$RAILS_ENV.rb file:

```ruby
config.action_mailer.delivery_method = :sendmail
# Defaults to:
# config.action_mailer.sendmail_settings = {
#   location: '/usr/sbin/sendmail',
#   arguments: %w[ -i ]
# }
config.action_mailer.perform_deliveries = true
config.action_mailer.raise_delivery_errors = true
config.action_mailer.default_options = { from: "no-reply@example.com" }
```

### 8.2. Action Mailer Configuration for Gmail

Add this to your config/environments/$RAILS_ENV.rb file to send via Gmail:

```ruby
config.action_mailer.delivery_method = :smtp
config.action_mailer.smtp_settings = {
  address:         "smtp.gmail.com",
  port:            587,
  domain:          "example.com",
  user_name:       Rails.application.credentials.dig(:smtp, :user_name),
  password:        Rails.application.credentials.dig(:smtp, :password),
  authentication:  "plain",
  enable_starttls: true,
  open_timeout:    5,
  read_timeout:    5 }
```

Google blocks
sign-ins from apps it deems
less secure. You can change your Gmail settings to allow the
attempts. If your Gmail account has 2-factor authentication enabled, then you
will need to set an app password
and use that instead of your regular password.

## 9. Previewing and Testing Mailers

You can find detailed instructions on how to test your mailers in the testing
guide.

### 9.1. Previewing Emails

You can preview rendered email templates visually by visiting a special Action
Mailer preview URL. To set up a preview for UserMailer, create a class named
UserMailerPreview in the test/mailers/previews/ directory. To see the
preview of welcome_email from UserMailer, implement a method that has the
same name in UserMailerPreview and call UserMailer.welcome_email:

```ruby
class UserMailerPreview < ActionMailer::Preview
  def welcome_email
    UserMailer.with(user: User.first).welcome_email
  end
end
```

Now the preview will be available at
<http://localhost:3000/rails/mailers/user_mailer/welcome_email>.

If you change something in the mailer view at
app/views/user_mailer/welcome_email.html.erb or the mailer itself, the preview
will automatically be updated. A list of previews is also available in
<http://localhost:3000/rails/mailers>.

By default, these preview classes live in test/mailers/previews. This can be
configured using the preview_paths option. For example, if you want to add
lib/mailer_previews to it, you can configure it in config/application.rb:

```ruby
config.action_mailer.preview_paths << "#{Rails.root}/lib/mailer_previews"
```

### 9.2. Rescuing Errors

Rescue blocks inside of a mailer method cannot rescue errors that occur outside
of rendering. For example, record deserialization errors in a background job, or
errors from a third-party mail delivery service.

To rescue errors that occur during any part of the mailing process, use
rescue_from:

```ruby
class NotifierMailer < ApplicationMailer
  rescue_from ActiveJob::DeserializationError do
    # ...
  end

  rescue_from "SomeThirdPartyService::ApiError" do
    # ...
  end

  def notify(recipient)
    mail(to: recipient, subject: "Notification")
  end
end
```

## 10. Intercepting and Observing Emails

Action Mailer provides hooks into the Mail observer and interceptor methods.
These allow you to register classes that are called during the mail delivery
life cycle of every email sent.

### 10.1. Intercepting Emails

Interceptors allow you to make modifications to emails before they are handed
off to the delivery agents. An interceptor class must implement the
.delivering_email(message) method which will be called before the email is
sent.

```ruby
class SandboxEmailInterceptor
  def self.delivering_email(message)
    message.to = ["sandbox@example.com"]
  end
end
```

The interceptor needs to be registered using the interceptors config option.
You can do this in an initializer file like
config/initializers/mail_interceptors.rb:

```ruby
Rails.application.configure do
  if Rails.env.staging?
    config.action_mailer.interceptors = %w[SandboxEmailInterceptor]
  end
end
```

The example above uses a custom environment called "staging" for a
production-like server but for testing purposes. You can read Creating Rails
Environments for more information
about custom Rails environments.

### 10.2. Observing Emails

Observers give you access to the email message after it has been sent. An
observer class must implement the :delivered_email(message) method, which will
be called after the email is sent.

```ruby
class EmailDeliveryObserver
  def self.delivered_email(message)
    EmailDelivery.log(message)
  end
end
```

Similar to interceptors, you must register observers using the observers
config option. You can do this in an initializer file like
config/initializers/mail_observers.rb:

```ruby
Rails.application.configure do
  config.action_mailer.observers = %w[EmailDeliveryObserver]
end
```

---

# Chapters

This guide provides you with all you need to get started in receiving emails to
your application.

After reading this guide, you will know:

- How to receive email within a Rails application.

- How to configure Action Mailbox.

- How to generate and route emails to a mailbox.

- How to test incoming emails.

## 1. What is Action Mailbox?

Action Mailbox routes incoming emails to controller-like mailboxes for
processing in your Rails application. Action Mailbox is for receiving email,
while Action Mailer is for sending them.

The inbound emails are routed asynchronously using Active
Job to one or several dedicated mailboxes. These emails
are turned into
InboundEmail
records using Active Record, which are capable of
interacting directly with the rest of your domain model.

InboundEmail records also provide lifecycle tracking, storage of the original
email via Active Storage, and responsible data
handling with on-by-default incineration.

Action Mailbox ships with ingresses which enable your application to receive
emails from external email providers such as Mailgun, Mandrill, Postmark, and
SendGrid. You can also handle inbound emails directly via the built-in Exim,
Postfix, and Qmail ingresses.

## 2. Setup

Action Mailbox has a few moving parts. First, you'll run the installer. Next,
you'll choose and configure an ingress for handling incoming email. You're then
ready to add Action Mailbox routing, create mailboxes, and start processing
incoming emails.

To start, let's install Action Mailbox:

```bash
bin/rails action_mailbox:install
```

This will create an application_mailbox.rb file and copy over migrations.

```bash
bin/rails db:migrate
```

This will run the Action Mailbox and Active Storage migrations.

The Action Mailbox table action_mailbox_inbound_emails stores incoming
messages and their processing status.

At this point, you can start your Rails server and check out
<http://localhost:3000/rails/conductor/action_mailbox/inbound_emails>. See
Local Development and Testing for more.

The next step is to configure an ingress in your Rails application to specify
how incoming emails should be received.

## 3. Ingress Configuration

Configuring ingress involves setting up credentials and endpoint information for
the chosen email service. Here are the steps for each of the supported
ingresses.

### 3.1. Exim

Tell Action Mailbox to accept emails from an SMTP relay:

```ruby
# config/environments/production.rb
config.action_mailbox.ingress = :relay
```

Generate a strong password that Action Mailbox can use to authenticate requests
to the relay ingress.

Use bin/rails credentials:edit to add the password to your application's
encrypted credentials under action_mailbox.ingress_password, where Action
Mailbox will automatically find it:

```yaml
action_mailbox:
  ingress_password: ...
```

Alternatively, provide the password in the RAILS_INBOUND_EMAIL_PASSWORD
environment variable.

Configure Exim to pipe inbound emails to bin/rails
action_mailbox:ingress:exim, providing the URL of the relay ingress and the
INGRESS_PASSWORD you previously generated. If your application lived at
<https://example.com>, the full command would look like this:

```bash
bin/rails action_mailbox:ingress:exim URL=https://example.com/rails/action_mailbox/relay/inbound_emails INGRESS_PASSWORD=...
```

### 3.2. Mailgun

Give Action Mailbox your Mailgun Signing key (which you can find under Settings
-> Security & Users -> API security in Mailgun), so it can authenticate requests
to the Mailgun ingress.

Use bin/rails credentials:edit to add your Signing key to your application's
encrypted credentials under action_mailbox.mailgun_signing_key, where Action
Mailbox will automatically find it:

```yaml
action_mailbox:
  mailgun_signing_key: ...
```

Alternatively, provide your Signing key in the MAILGUN_INGRESS_SIGNING_KEY
environment variable.

Tell Action Mailbox to accept emails from Mailgun:

```ruby
# config/environments/production.rb
config.action_mailbox.ingress = :mailgun
```

Configure
Mailgun
to forward inbound emails to
/rails/action_mailbox/mailgun/inbound_emails/mime. If your application lived
at <https://example.com>, you would specify the fully-qualified URL
<https://example.com/rails/action_mailbox/mailgun/inbound_emails/mime>.

### 3.3. Mandrill

Give Action Mailbox your Mandrill API key, so it can authenticate requests to
the Mandrill ingress.

Use bin/rails credentials:edit to add your API key to your application's
encrypted credentials under action_mailbox.mandrill_api_key, where Action
Mailbox will automatically find it:

```yaml
action_mailbox:
  mandrill_api_key: ...
```

Alternatively, provide your API key in the MANDRILL_INGRESS_API_KEY
environment variable.

Tell Action Mailbox to accept emails from Mandrill:

```ruby
# config/environments/production.rb
config.action_mailbox.ingress = :mandrill
```

Configure
Mandrill
to route inbound emails to /rails/action_mailbox/mandrill/inbound_emails. If
your application lived at <https://example.com>, you would specify the
fully-qualified URL
<https://example.com/rails/action_mailbox/mandrill/inbound_emails>.

### 3.4. Postfix

Tell Action Mailbox to accept emails from an SMTP relay:

```ruby
# config/environments/production.rb
config.action_mailbox.ingress = :relay
```

Generate a strong password that Action Mailbox can use to authenticate requests
to the relay ingress.

Use bin/rails credentials:edit to add the password to your application's
encrypted credentials under action_mailbox.ingress_password, where Action
Mailbox will automatically find it:

```yaml
action_mailbox:
  ingress_password: ...
```

Alternatively, provide the password in the RAILS_INBOUND_EMAIL_PASSWORD
environment variable.

Configure
Postfix
to pipe inbound emails to bin/rails action_mailbox:ingress:postfix, providing
the URL of the Postfix ingress and the INGRESS_PASSWORD you previously
generated. If your application lived at <https://example.com>, the full command
would look like this:

```bash
bin/rails action_mailbox:ingress:postfix URL=https://example.com/rails/action_mailbox/relay/inbound_emails INGRESS_PASSWORD=...
```

### 3.5. Postmark

Tell Action Mailbox to accept emails from Postmark:

```ruby
# config/environments/production.rb
config.action_mailbox.ingress = :postmark
```

Generate a strong password that Action Mailbox can use to authenticate requests
to the Postmark ingress.

Use bin/rails credentials:edit to add the password to your application's
encrypted credentials under action_mailbox.ingress_password, where Action
Mailbox will automatically find it:

```yaml
action_mailbox:
  ingress_password: ...
```

Alternatively, provide the password in the RAILS_INBOUND_EMAIL_PASSWORD
environment variable.

Configure Postmark inbound
webhook to
forward inbound emails to /rails/action_mailbox/postmark/inbound_emails with
the username actionmailbox and the password you previously generated. If your
application lived at <https://example.com>, you would configure Postmark with
the following fully-qualified URL:

```
https://actionmailbox:PASSWORD@example.com/rails/action_mailbox/postmark/inbound_emails
```

When configuring your Postmark inbound webhook, be sure to check the box
labeled "Include raw email content in JSON payload". Action Mailbox needs
the raw email content to work.

### 3.6. Qmail

Tell Action Mailbox to accept emails from an SMTP relay:

```ruby
# config/environments/production.rb
config.action_mailbox.ingress = :relay
```

Generate a strong password that Action Mailbox can use to authenticate requests
to the relay ingress.

Use bin/rails credentials:edit to add the password to your application's
encrypted credentials under action_mailbox.ingress_password, where Action
Mailbox will automatically find it:

```yaml
action_mailbox:
  ingress_password: ...
```

Alternatively, provide the password in the RAILS_INBOUND_EMAIL_PASSWORD
environment variable.

Configure Qmail to pipe inbound emails to bin/rails
action_mailbox:ingress:qmail, providing the URL of the relay ingress and the
INGRESS_PASSWORD you previously generated. If your application lived at
<https://example.com>, the full command would look like this:

```bash
bin/rails action_mailbox:ingress:qmail URL=https://example.com/rails/action_mailbox/relay/inbound_emails INGRESS_PASSWORD=...
```

### 3.7. SendGrid

Tell Action Mailbox to accept emails from SendGrid:

```ruby
# config/environments/production.rb
config.action_mailbox.ingress = :sendgrid
```

Generate a strong password that Action Mailbox can use to authenticate requests
to the SendGrid ingress.

Use bin/rails credentials:edit to add the password to your application's
encrypted credentials under action_mailbox.ingress_password, where Action
Mailbox will automatically find it:

```yaml
action_mailbox:
  ingress_password: ...
```

Alternatively, provide the password in the RAILS_INBOUND_EMAIL_PASSWORD
environment variable.

Configure SendGrid Inbound
Parse
to forward inbound emails to /rails/action_mailbox/sendgrid/inbound_emails
with the username actionmailbox and the password you previously generated. If
your application lived at <https://example.com>, you would configure SendGrid
with the following URL:

```
https://actionmailbox:PASSWORD@example.com/rails/action_mailbox/sendgrid/inbound_emails
```

When configuring your SendGrid Inbound Parse webhook, be sure to check the
box labeled “Post the raw, full MIME message.” Action Mailbox needs the raw
MIME message to work.

## 4. Processing Incoming Email

Processing incoming emails usually entails using the email content to create
models, update views, queue background work, etc. in your Rails application.

Before you can start processing incoming emails, you'll need to setup Action
Mailbox routing and create mailboxes.

### 4.1. Configure Routing

After an incoming email is received via the configured ingress, it needs to be
forwarded to a mailbox for actual processing by your application. Much like the
Rails router that dispatches URLs to controllers, routing in
Action Mailbox defines which emails go to which mailboxes for processing. Routes
are added to the application_mailbox.rb file using regular expressions:

```ruby
# app/mailboxes/application_mailbox.rb
class ApplicationMailbox < ActionMailbox::Base
  routing(/^save@/i     => :forwards)
  routing(/@replies\./i => :replies)
end
```

The regular expression matches the incoming email's to, cc, or bcc fields.
For example, the above will match any email sent to save@ to a "forwards"
mailbox. There are other ways to route an email, see
ActionMailbox::Base
for more.

We need to create that "forwards" mailbox next.

### 4.2. Create a Mailbox

```bash
# Generate new mailbox
$ bin/rails generate mailbox forwards
```

This creates app/mailboxes/forwards_mailbox.rb, with a ForwardsMailbox class
and a process method.

### 4.3. Process Email

When processing an InboundEmail, you can get the parsed version of the email
as a Mail object with InboundEmail#mail.
You can also get the raw source directly using the #source method. With the
Mail object, you can access the relevant fields, such as mail.to,
mail.body.decoded, etc.

```
irb> mail
=> #<Mail::Message:33780, Multipart: false, Headers: <Date: Wed, 31 Jan 2024 22:18:40 -0600>, <From: someone@hey.com>, <To: save@example.com>, <Message-ID: <65bb1ba066830_50303a70397e@Bhumis-MacBook-Pro.local.mail>>, <In-Reply-To: >, <Subject: Hello Action Mailbox>, <Mime-Version: 1.0>, <Content-Type: text/plain; charset=UTF-8>, <Content-Transfer-Encoding: 7bit>, <x-original-to: >>
irb> mail.to
=> ["save@example.com"]
irb> mail.from
=> ["someone@hey.com"]
irb> mail.date
=> Wed, 31 Jan 2024 22:18:40 -0600
irb> mail.subject
=> "Hello Action Mailbox"
irb> mail.body.decoded
=> "This is the body of the email message."
# mail.decoded, a shorthand for mail.body.decoded, also works
irb> mail.decoded
=> "This is the body of the email message."
irb> mail.body
=> <Mail::Body:0x00007fc74cbf46c0 @boundary=nil, @preamble=nil, @epilogue=nil, @charset="US-ASCII", @part_sort_order=["text/plain", "text/enriched", "text/html", "multipart/alternative"], @parts=[], @raw_source="This is the body of the email message.", @ascii_only=true, @encoding="7bit">
```

### 4.4. Inbound Email Status

While the email is being routed to a matching mailbox and processed, Action
Mailbox updates the email status stored in action_mailbox_inbound_emails table
with one of the following values:

- pending: Received by one of the ingress controllers and scheduled for
routing.

- processing: During active processing, while a specific mailbox is running
its process method.

- delivered: Successfully processed by the specific mailbox.

- failed: An exception was raised during the specific mailbox’s execution of
the process method.

- bounced: Rejected processing by the specific mailbox and bounced to sender.

If the email is marked either delivered, failed, or bounced it's
considered "processed" and marked for
incineration.

## 5. Example

Here is an example of an Action Mailbox that processes emails to create
"forwards" for the user's project.

The before_processing callback is used to ensure that certain conditions are
met before process method is called. In this case, before_processing checks
that the user has at least one project. Other supported Action Mailbox
callbacks are
after_processing and around_processing.

The email can be bounced using bounced_with if the "forwarder" has no
projects. The "forwarder" is a User with the same email as mail.from.

If the "forwarder" does have at least one project, the record_forward method
creates an Active Record model in the application using the email data
mail.subject and mail.decoded. Otherwise, it sends an email, using Action
Mailer, requesting the "forwarder" to choose a project.

```ruby
# app/mailboxes/forwards_mailbox.rb
class ForwardsMailbox < ApplicationMailbox
  # Callbacks specify prerequisites to processing
  before_processing :require_projects

  def process
    # Record the forward on the one project, or…
    if forwarder.projects.one?
      record_forward
    else
      # …involve a second Action Mailer to ask which project to forward into.
      request_forwarding_project
    end
  end

  private
    def require_projects
      if forwarder.projects.none?
        # Use Action Mailers to bounce incoming emails back to sender – this halts processing
        bounce_with Forwards::BounceMailer.no_projects(inbound_email, forwarder: forwarder)
      end
    end

    def record_forward
      forwarder.forwards.create subject: mail.subject, content: mail.decoded
    end

    def request_forwarding_project
      Forwards::RoutingMailer.choose_project(inbound_email, forwarder: forwarder).deliver_now
    end

    def forwarder
      @forwarder ||= User.find_by(email_address: mail.from)
    end
end
```

## 6. Local Development and Testing

It's helpful to be able to test incoming emails in development without actually
sending and receiving real emails. To accomplish this, there's a conductor
controller mounted at /rails/conductor/action_mailbox/inbound_emails, which
gives you an index of all the InboundEmails in the system, their state of
processing, and a form to create a new InboundEmail as well.

Here is and example of testing an inbound email with Action Mailbox TestHelpers.

```ruby
class ForwardsMailboxTest < ActionMailbox::TestCase
  test "directly recording a client forward for a forwarder and forwardee corresponding to one project" do
    assert_difference -> { people(:david).buckets.first.recordings.count } do
      receive_inbound_email_from_mail \
        to: "save@example.com",
        from: people(:david).email_address,
        subject: "Fwd: Status update?",
        body: <<~BODY
          --- Begin forwarded message ---
          From: Frank Holland <frank@microsoft.com>

          What's the status?
        BODY
    end

    recording = people(:david).buckets.first.recordings.last
    assert_equal people(:david), recording.creator
    assert_equal "Status update?", recording.forward.subject
    assert_match "What's the status?", recording.forward.content.to_s
  end
end
```

Please refer to the ActionMailbox::TestHelper
API for
further test helper methods.

## 7. Incineration of InboundEmails

By default, an InboundEmail that has been processed will be incinerated after
30 days. The InboundEmail is considered as processed when its status changes
to delivered, failed, or bounced.

The actual incineration is done via the
IncinerationJob
that's scheduled to run after
config.action_mailbox.incinerate_after
time. This value is set to 30.days by default, but you can change it in your
production.rb configuration. (Note that this far-future incineration scheduling
relies on your job queue being able to hold jobs for that long.)

Default data incineration ensures that you're not holding on to people's data
unnecessarily after they may have canceled their accounts or deleted their
content.

The intention with Action Mailbox processing is that as you process an email,
you should extract all the data you need from the email and persist it into
domain models in your application. The InboundEmail stays in the system for
the configured time to allow for debugging and forensics and then will be
deleted.

---

# Chapters

In this guide, you will learn how Action Cable works and how to use WebSockets to
incorporate real-time features into your Rails application.

After reading this guide, you will know:

- What Action Cable is and its integration backend and frontend

- How to set up Action Cable

- How to set up channels

- Deployment and Architecture setup for running Action Cable

## 1. What is Action Cable?

Action Cable seamlessly integrates
WebSockets with the rest of your
Rails application. It allows for real-time features to be written in Ruby in the
same style and form as the rest of your Rails application, while still being
performant and scalable. It's a full-stack offering that provides both a
client-side JavaScript framework and a server-side Ruby framework. You have
access to your entire domain model written with Active Record or your ORM of
choice.

## 2. Terminology

Action Cable uses WebSockets instead of the HTTP request-response protocol.
Both Action Cable and WebSockets introduce some less familiar terminology:

### 2.1. Connections

Connections form the foundation of the client-server relationship.
A single Action Cable server can handle multiple connection instances. It has one
connection instance per WebSocket connection. A single user may have multiple
WebSockets open to your application if they use multiple browser tabs or devices.

### 2.2. Consumers

The client of a WebSocket connection is called the consumer. In Action Cable,
the consumer is created by the client-side JavaScript framework.

### 2.3. Channels

Each consumer can, in turn, subscribe to multiple channels. Each channel
encapsulates a logical unit of work, similar to what a controller does in
a typical MVC setup. For example, you could have a ChatChannel and
an AppearancesChannel, and a consumer could be subscribed to either
or both of these channels. At the very least, a consumer should be subscribed
to one channel.

### 2.4. Subscribers

When the consumer is subscribed to a channel, they act as a subscriber.
The connection between the subscriber and the channel is, surprise-surprise,
called a subscription. A consumer can act as a subscriber to a given channel
any number of times. For example, a consumer could subscribe to multiple chat rooms
at the same time. (And remember that a physical user may have multiple consumers,
one per tab/device open to your connection).

### 2.5. Pub/Sub

Pub/Sub or
Publish-Subscribe refers to a message queue paradigm whereby senders of
information (publishers), send data to an abstract class of recipients
(subscribers), without specifying individual recipients. Action Cable uses this
approach to communicate between the server and many clients.

### 2.6. Broadcastings

A broadcasting is a pub/sub link where anything transmitted by the broadcaster is
sent directly to the channel subscribers who are streaming that named broadcasting.
Each channel can be streaming zero or more broadcastings.

## 3. Server-Side Components

### 3.1. Connections

For every WebSocket accepted by the server, a connection object is instantiated. This
object becomes the parent of all the channel subscriptions that are created
from thereon. The connection itself does not deal with any specific application
logic beyond authentication and authorization. The client of a WebSocket
connection is called the connection consumer. An individual user will create
one consumer-connection pair per browser tab, window, or device they have open.

Connections are instances of ApplicationCable::Connection, which extends
ActionCable::Connection::Base. In ApplicationCable::Connection, you
authorize the incoming connection and proceed to establish it if the user can
be identified.

#### 3.1.1. Connection Setup

```ruby
# app/channels/application_cable/connection.rb
module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_user

    def connect
      self.current_user = find_verified_user
    end

    private
      def find_verified_user
        if verified_user = User.find_by(id: cookies.encrypted[:user_id])
          verified_user
        else
          reject_unauthorized_connection
        end
      end
  end
end
```

Here identified_by designates a connection identifier that can be used to find the
specific connection later. Note that anything marked as an identifier will automatically
create a delegate by the same name on any channel instances created off the connection.

This example relies on the fact that you will already have handled authentication of the user
somewhere else in your application, and that a successful authentication sets an encrypted
cookie with the user ID.

The cookie is then automatically sent to the connection instance when a new connection
is attempted, and you use that to set the current_user. By identifying the connection
by this same current user, you're also ensuring that you can later retrieve all open
connections by a given user (and potentially disconnect them all if the user is deleted
or unauthorized).

If your authentication approach includes using a session, you use cookie store for the
session, your session cookie is named _session and the user ID key is user_id you
can use this approach:

```ruby
verified_user = User.find_by(id: cookies.encrypted["_session"]["user_id"])
```

#### 3.1.2. Exception Handling

By default, unhandled exceptions are caught and logged to Rails' logger. If you would like to
globally intercept these exceptions and report them to an external bug tracking service, for
example, you can do so with rescue_from:

```ruby
# app/channels/application_cable/connection.rb
module ApplicationCable
  class Connection < ActionCable::Connection::Base
    rescue_from StandardError, with: :report_error

    private
      def report_error(e)
        SomeExternalBugtrackingService.notify(e)
      end
  end
end
```

#### 3.1.3. Connection Callbacks

ActionCable::Connection::Callbacks provides callback hooks that are
invoked when sending commands to the client, such as when subscribing,
unsubscribing, or performing an action:

- before_command

- after_command

- around_command

### 3.2. Channels

A channel encapsulates a logical unit of work, similar to what a controller does in a
typical MVC setup. By default, Rails creates a parent ApplicationCable::Channel class
(which extends ActionCable::Channel::Base) for encapsulating shared logic between your channels,
when you use the channel generator for the first time.

#### 3.2.1. Parent Channel Setup

```ruby
# app/channels/application_cable/channel.rb
module ApplicationCable
  class Channel < ActionCable::Channel::Base
  end
end
```

Your own channel classes could then look like these examples:

```ruby
# app/channels/chat_channel.rb
class ChatChannel < ApplicationCable::Channel
end
```

```ruby
# app/channels/appearance_channel.rb
class AppearanceChannel < ApplicationCable::Channel
end
```

A consumer could then be subscribed to either or both of these channels.

#### 3.2.2. Subscriptions

Consumers subscribe to channels, acting as subscribers. Their connection is
called a subscription. Produced messages are then routed to these channel
subscriptions based on an identifier sent by the channel consumer.

```ruby
# app/channels/chat_channel.rb
class ChatChannel < ApplicationCable::Channel
  # Called when the consumer has successfully
  # become a subscriber to this channel.
  def subscribed
  end
end
```

#### 3.2.3. Exception Handling

As with ApplicationCable::Connection, you can also use rescue_from on a
specific channel to handle raised exceptions:

```ruby
# app/channels/chat_channel.rb
class ChatChannel < ApplicationCable::Channel
  rescue_from "MyError", with: :deliver_error_message

  private
    def deliver_error_message(e)
      # broadcast_to(...)
    end
end
```

#### 3.2.4. Channel Callbacks

ActionCable::Channel::Callbacks provides callback hooks that are invoked
during the life cycle of a channel:

- before_subscribe

- after_subscribe (aliased as on_subscribe)

- before_unsubscribe

- after_unsubscribe (aliased as on_unsubscribe)

## 4. Client-Side Components

### 4.1. Connections

Consumers require an instance of the connection on their side. This can be
established using the following JavaScript, which is generated by default by Rails:

#### 4.1.1. Connect Consumer

```
// app/javascript/channels/consumer.js
// Action Cable provides the framework to deal with WebSockets in Rails.
// You can generate new channels where WebSocket features live using the `bin/rails generate channel` command.

import { createConsumer } from "@rails/actioncable"

export default createConsumer()
```

This will ready a consumer that'll connect against /cable on your server by default.
The connection won't be established until you've also specified at least one subscription
you're interested in having.

The consumer can optionally take an argument that specifies the URL to connect to. This
can be a string or a function that returns a string that will be called when the
WebSocket is opened.

```
// Specify a different URL to connect to
createConsumer('wss://example.com/cable')
// Or when using websockets over HTTP
createConsumer('https://ws.example.com/cable')

// Use a function to dynamically generate the URL
createConsumer(getWebSocketURL)

function getWebSocketURL() {
  const token = localStorage.get('auth-token')
  return `wss://example.com/cable?token=${token}`
}
```

#### 4.1.2. Subscriber

A consumer becomes a subscriber by creating a subscription to a given channel:

```
// app/javascript/channels/chat_channel.js
import consumer from "./consumer"

consumer.subscriptions.create({ channel: "ChatChannel", room: "Best Room" })

// app/javascript/channels/appearance_channel.js
import consumer from "./consumer"

consumer.subscriptions.create({ channel: "AppearanceChannel" })
```

While this creates the subscription, the functionality needed to respond to
received data will be described later on.

A consumer can act as a subscriber to a given channel any number of times. For
example, a consumer could subscribe to multiple chat rooms at the same time:

```
// app/javascript/channels/chat_channel.js
import consumer from "./consumer"

consumer.subscriptions.create({ channel: "ChatChannel", room: "1st Room" })
consumer.subscriptions.create({ channel: "ChatChannel", room: "2nd Room" })
```

## 5. Client-Server Interactions

### 5.1. Streams

Streams provide the mechanism by which channels route published content
(broadcasts) to their subscribers. For example, the following code uses
stream_from to subscribe to the broadcasting named chat_Best Room when
the value of the :room parameter is "Best Room":

```ruby
# app/channels/chat_channel.rb
class ChatChannel < ApplicationCable::Channel
  def subscribed
    stream_from "chat_#{params[:room]}"
  end
end
```

Then, elsewhere in your Rails application, you can broadcast to such a room by
calling broadcast:

```ruby
ActionCable.server.broadcast("chat_Best Room", { body: "This Room is Best Room." })
```

If you have a stream that is related to a model, then the broadcasting name
can be generated from the channel and model. For example, the following code
uses stream_for to subscribe to a broadcasting like
posts:Z2lkOi8vVGVzdEFwcC9Qb3N0LzE, where Z2lkOi8vVGVzdEFwcC9Qb3N0LzE is
the GlobalID of the Post model.

```ruby
class PostsChannel < ApplicationCable::Channel
  def subscribed
    post = Post.find(params[:id])
    stream_for post
  end
end
```

You can then broadcast to this channel by calling broadcast_to:

```ruby
PostsChannel.broadcast_to(@post, @comment)
```

### 5.2. Broadcastings

A broadcasting is a pub/sub link where anything transmitted by a publisher
is routed directly to the channel subscribers who are streaming that named
broadcasting. Each channel can be streaming zero or more broadcastings.

Broadcastings are purely an online queue and time-dependent. If a consumer is
not streaming (subscribed to a given channel), they'll not get the broadcast
should they connect later.

### 5.3. Subscriptions

When a consumer is subscribed to a channel, they act as a subscriber. This
connection is called a subscription. Incoming messages are then routed to
these channel subscriptions based on an identifier sent by the cable consumer.

```
// app/javascript/channels/chat_channel.js
import consumer from "./consumer"

consumer.subscriptions.create({ channel: "ChatChannel", room: "Best Room" }, {
  received(data) {
    this.appendLine(data)
  },

  appendLine(data) {
    const html = this.createLine(data)
    const element = document.querySelector("[data-chat-room='Best Room']")
    element.insertAdjacentHTML("beforeend", html)
  },

  createLine(data) {
    return `
      <article class="chat-line">
        <span class="speaker">${data["sent_by"]}</span>
        <span class="body">${data["body"]}</span>
      </article>
    `
  }
})
```

### 5.4. Passing Parameters to Channels

You can pass parameters from the client-side to the server-side when creating a
subscription. For example:

```ruby
# app/channels/chat_channel.rb
class ChatChannel < ApplicationCable::Channel
  def subscribed
    stream_from "chat_#{params[:room]}"
  end
end
```

An object passed as the first argument to subscriptions.create becomes the
params hash in the cable channel. The keyword channel is required:

```
// app/javascript/channels/chat_channel.js
import consumer from "./consumer"

consumer.subscriptions.create({ channel: "ChatChannel", room: "Best Room" }, {
  received(data) {
    this.appendLine(data)
  },

  appendLine(data) {
    const html = this.createLine(data)
    const element = document.querySelector("[data-chat-room='Best Room']")
    element.insertAdjacentHTML("beforeend", html)
  },

  createLine(data) {
    return `
      <article class="chat-line">
        <span class="speaker">${data["sent_by"]}</span>
        <span class="body">${data["body"]}</span>
      </article>
    `
  }
})
```

```ruby
# Somewhere in your app this is called, perhaps
# from a NewCommentJob.
ActionCable.server.broadcast(
  "chat_#{room}",
  {
    sent_by: "Paul",
    body: "This is a cool chat app."
  }
)
```

### 5.5. Rebroadcasting a Message

A common use case is to rebroadcast a message sent by one client to any
other connected clients.

```ruby
# app/channels/chat_channel.rb
class ChatChannel < ApplicationCable::Channel
  def subscribed
    stream_from "chat_#{params[:room]}"
  end

  def receive(data)
    ActionCable.server.broadcast("chat_#{params[:room]}", data)
  end
end
```

```
// app/javascript/channels/chat_channel.js
import consumer from "./consumer"

const chatChannel = consumer.subscriptions.create({ channel: "ChatChannel", room: "Best Room" }, {
  received(data) {
    // data => { sent_by: "Paul", body: "This is a cool chat app." }
  }
})

chatChannel.send({ sent_by: "Paul", body: "This is a cool chat app." })
```

The rebroadcast will be received by all connected clients, including the
client that sent the message. Note that params are the same as they were when
you subscribed to the channel.

## 6. Full-Stack Examples

The following setup steps are common to both examples:

- Set up your connection.

- Set up your parent channel.

- Connect your consumer.

### 6.1. Example 1: User Appearances

Here's a simple example of a channel that tracks whether a user is online or not
and what page they're on. (This is useful for creating presence features like showing
a green dot next to a username if they're online).

Create the server-side appearance channel:

```ruby
# app/channels/appearance_channel.rb
class AppearanceChannel < ApplicationCable::Channel
  def subscribed
    current_user.appear
  end

  def unsubscribed
    current_user.disappear
  end

  def appear(data)
    current_user.appear(on: data["appearing_on"])
  end

  def away
    current_user.away
  end
end
```

When a subscription is initiated the subscribed callback gets fired, and we
take that opportunity to say "the current user has indeed appeared". That
appear/disappear API could be backed by Redis, a database, or whatever else.

Create the client-side appearance channel subscription:

```
// app/javascript/channels/appearance_channel.js
import consumer from "./consumer"

consumer.subscriptions.create("AppearanceChannel", {
  // Called once when the subscription is created.
  initialized() {
    this.update = this.update.bind(this)
  },

  // Called when the subscription is ready for use on the server.
  connected() {
    this.install()
    this.update()
  },

  // Called when the WebSocket connection is closed.
  disconnected() {
    this.uninstall()
  },

  // Called when the subscription is rejected by the server.
  rejected() {
    this.uninstall()
  },

  update() {
    this.documentIsActive ? this.appear() : this.away()
  },

  appear() {
    // Calls `AppearanceChannel#appear(data)` on the server.
    this.perform("appear", { appearing_on: this.appearingOn })
  },

  away() {
    // Calls `AppearanceChannel#away` on the server.
    this.perform("away")
  },

  install() {
    window.addEventListener("focus", this.update)
    window.addEventListener("blur", this.update)
    document.addEventListener("turbo:load", this.update)
    document.addEventListener("visibilitychange", this.update)
  },

  uninstall() {
    window.removeEventListener("focus", this.update)
    window.removeEventListener("blur", this.update)
    document.removeEventListener("turbo:load", this.update)
    document.removeEventListener("visibilitychange", this.update)
  },

  get documentIsActive() {
    return document.visibilityState === "visible" && document.hasFocus()
  },

  get appearingOn() {
    const element = document.querySelector("[data-appearing-on]")
    return element ? element.getAttribute("data-appearing-on") : null
  }
})
```

#### 6.1.1. Client-Server Interaction

- Client connects to the Server via createConsumer(). (consumer.js). The
Server identifies this connection by current_user.

- Client subscribes to the appearance channel via
consumer.subscriptions.create({ channel: "AppearanceChannel" }). (appearance_channel.js)

- Server recognizes a new subscription has been initiated for the
appearance channel and runs its subscribed callback, calling the appear
method on current_user. (appearance_channel.rb)

- Client recognizes that a subscription has been established and calls
connected (appearance_channel.js), which in turn calls install and appear.
appear calls AppearanceChannel#appear(data) on the server, and supplies a
data hash of { appearing_on: this.appearingOn }. This is
possible because the server-side channel instance automatically exposes all
public methods declared on the class (minus the callbacks), so that these can be
reached as remote procedure calls via a subscription's perform method.

- Server receives the request for the appear action on the appearance
channel for the connection identified by current_user
(appearance_channel.rb). Server retrieves the data with the
:appearing_on key from the data hash and sets it as the value for the :on
key being passed to current_user.appear.

Client connects to the Server via createConsumer(). (consumer.js). The
Server identifies this connection by current_user.

Client subscribes to the appearance channel via
consumer.subscriptions.create({ channel: "AppearanceChannel" }). (appearance_channel.js)

Server recognizes a new subscription has been initiated for the
appearance channel and runs its subscribed callback, calling the appear
method on current_user. (appearance_channel.rb)

Client recognizes that a subscription has been established and calls
connected (appearance_channel.js), which in turn calls install and appear.
appear calls AppearanceChannel#appear(data) on the server, and supplies a
data hash of { appearing_on: this.appearingOn }. This is
possible because the server-side channel instance automatically exposes all
public methods declared on the class (minus the callbacks), so that these can be
reached as remote procedure calls via a subscription's perform method.

Server receives the request for the appear action on the appearance
channel for the connection identified by current_user
(appearance_channel.rb). Server retrieves the data with the
:appearing_on key from the data hash and sets it as the value for the :on
key being passed to current_user.appear.

### 6.2. Example 2: Receiving New Web Notifications

The appearance example was all about exposing server functionality to
client-side invocation over the WebSocket connection. But the great thing
about WebSockets is that it's a two-way street. So, now, let's show an example
where the server invokes an action on the client.

This is a web notification channel that allows you to trigger client-side
web notifications when you broadcast to the relevant streams:

Create the server-side web notifications channel:

```ruby
# app/channels/web_notifications_channel.rb
class WebNotificationsChannel < ApplicationCable::Channel
  def subscribed
    stream_for current_user
  end
end
```

Create the client-side web notifications channel subscription:

```
// app/javascript/channels/web_notifications_channel.js
// Client-side which assumes you've already requested
// the right to send web notifications.
import consumer from "./consumer"

consumer.subscriptions.create("WebNotificationsChannel", {
  received(data) {
    new Notification(data["title"], { body: data["body"] })
  }
})
```

Broadcast content to a web notification channel instance from elsewhere in your
application:

```ruby
# Somewhere in your app this is called, perhaps from a NewCommentJob
WebNotificationsChannel.broadcast_to(
  current_user,
  title: "New things!",
  body: "All the news fit to print"
)
```

The WebNotificationsChannel.broadcast_to call places a message in the current
subscription adapter's pubsub queue under a separate broadcasting name for each
user. For a user with an ID of 1, the broadcasting name would be
web_notifications:1.

The channel has been instructed to stream everything that arrives at
web_notifications:1 directly to the client by invoking the received
callback. The data passed as an argument is the hash sent as the second parameter
to the server-side broadcast call, JSON encoded for the trip across the wire
and unpacked for the data argument arriving as received.

### 6.3. More Complete Examples

See the rails/actioncable-examples
repository for a full example of how to set up Action Cable in a Rails app and adding channels.

## 7. Configuration

Action Cable has two required configurations: a subscription adapter and allowed request origins.

### 7.1. Subscription Adapter

By default, Action Cable looks for a configuration file in config/cable.yml.
The file must specify an adapter for each Rails environment. See the
Dependencies section for additional information on adapters.

```yaml
development:
  adapter: async

test:
  adapter: test

production:
  adapter: redis
  url: redis://10.10.3.153:6381
  channel_prefix: appname_production
```

#### 7.1.1. Adapter Configuration

Below is a list of the subscription adapters available for end-users.

The async adapter is intended for development/testing and should not be used in production.

The async adapter only works within the same process, so for manually triggering cable updates from a console and seeing results in the browser, you must do so from the web console (running inside the dev process), not a terminal started via bin/rails console! Add console to any action or any ERB template view to make the web console appear.

The Solid Cable adapter is a database-backed solution that uses Active Record. It has been tested with MySQL, SQLite, and PostgreSQL. Running bin/rails solid_cable:install will automatically set up config/cable.yml and create db/cable_schema.rb. After that, you must manually update config/database.yml, adjusting it based on your database. See Solid Cable Installation.

The Redis adapter requires users to provide a URL pointing to the Redis server.
Additionally, a channel_prefix may be provided to avoid channel name collisions
when using the same Redis server for multiple applications. See the Redis Pub/Sub documentation for more details.

The Redis adapter also supports SSL/TLS connections. The required SSL/TLS parameters can be passed in ssl_params key in the configuration YAML file.

```yaml
production:
  adapter: redis
  url: rediss://10.10.3.153:tls_port
  channel_prefix: appname_production
  ssl_params:
    ca_file: "/path/to/ca.crt"
```

The options given to ssl_params are passed directly to the OpenSSL::SSL::SSLContext#set_params method and can be any valid attribute of the SSL context.
Please refer to the OpenSSL::SSL::SSLContext documentation for other available attributes.

If you are using self-signed certificates for redis adapter behind a firewall and opt to skip certificate check, then the ssl verify_mode should be set as OpenSSL::SSL::VERIFY_NONE.

It is not recommended to use VERIFY_NONE in production unless you absolutely understand the security implications. In order to set this option for the Redis adapter, the config should be ssl_params: { verify_mode: <%= OpenSSL::SSL::VERIFY_NONE %> }.

The PostgreSQL adapter uses Active Record's connection pool, and thus the
application's config/database.yml database configuration, for its connection.
This may change in the future. #27214

PostgreSQL has a 8000 bytes limit on NOTIFY (the command used under the hood for sending notifications) which might be a constraint when dealing with large payloads.

### 7.2. Allowed Request Origins

Action Cable will only accept requests from specified origins, which are
passed to the server config as an array. The origins can be instances of
strings or regular expressions, against which a check for the match will be performed.

```ruby
config.action_cable.allowed_request_origins = ["https://rubyonrails.com", %r{http://ruby.*}]
```

To disable and allow requests from any origin:

```ruby
config.action_cable.disable_request_forgery_protection = true
```

By default, Action Cable allows all requests from localhost:3000 when running
in the development environment.

### 7.3. Consumer Configuration

To configure the URL, add a call to action_cable_meta_tag in your HTML layout
HEAD. This uses a URL or path typically set via config.action_cable.url in the
environment configuration files.

### 7.4. Worker Pool Configuration

The worker pool is used to run connection callbacks and channel actions in
isolation from the server's main thread. Action Cable allows the application
to configure the number of simultaneously processed threads in the worker pool.

```ruby
config.action_cable.worker_pool_size = 4
```

Also, note that your server must provide at least the same number of database
connections as you have workers. The default worker pool size is set to 4, so
that means you have to make at least 4 database connections available.
You can change that in config/database.yml through the pool attribute.

### 7.5. Client-side Logging

Client-side logging is disabled by default. You can enable this by setting the ActionCable.logger.enabled to true.

```
import * as ActionCable from '@rails/actioncable'

ActionCable.logger.enabled = true
```

### 7.6. Other Configurations

The other common option to configure is the log tags applied to the
per-connection logger. Here's an example that uses
the user account id if available, else "no-account" while tagging:

```ruby
config.action_cable.log_tags = [
  -> request { request.env["user_account_id"] || "no-account" },
  :action_cable,
  -> request { request.uuid }
]
```

For a full list of all configuration options, see the
ActionCable::Server::Configuration class.

## 8. Running Standalone Cable Servers

Action Cable can either run as part of your Rails application, or as
a standalone server. In development, running as part of your Rails app
is generally fine, but in production you should run it as a standalone.

### 8.1. In App

Action Cable can run alongside your Rails application. For example, to
listen for WebSocket requests on /websocket, specify that path to
config.action_cable.mount_path:

```ruby
# config/application.rb
class Application < Rails::Application
  config.action_cable.mount_path = "/websocket"
end
```

You can use ActionCable.createConsumer() to connect to the cable
server if action_cable_meta_tag is invoked in the layout. Otherwise, a path is
specified as first argument to createConsumer (e.g. ActionCable.createConsumer("/websocket")).

For every instance of your server you create, and for every worker your server
spawns, you will also have a new instance of Action Cable, but the Redis or
PostgreSQL adapter keeps messages synced across connections.

### 8.2. Standalone

The cable servers can be separated from your normal application server. It's
still a Rack application, but it is its own Rack application. The recommended
basic setup is as follows:

```ruby
# cable/config.ru
require_relative "../config/environment"
Rails.application.eager_load!

run ActionCable.server
```

Then to start the server:

```bash
bundle exec puma -p 28080 cable/config.ru
```

This starts a cable server on port 28080. To tell Rails to use this
server, update your config:

```ruby
# config/environments/development.rb
Rails.application.configure do
  config.action_cable.mount_path = nil
  config.action_cable.url = "ws://localhost:28080" # use wss:// in production
end
```

Finally, ensure you have configured the consumer correctly.

### 8.3. Notes

The WebSocket server doesn't have access to the session, but it has
access to the cookies. This can be used when you need to handle
authentication. You can see one way of doing that with Devise in this article.

## 9. Dependencies

Action Cable provides a subscription adapter interface to process its
pubsub internals. By default, asynchronous, inline, PostgreSQL, and Redis
adapters are included. The default adapter
in new Rails applications is the asynchronous (async) adapter.

The Ruby side of things is built on top of websocket-driver,
nio4r, and concurrent-ruby.

## 10. Deployment

Action Cable is powered by a combination of WebSockets and threads. Both the
framework plumbing and user-specified channel work are handled internally by
utilizing Ruby's native thread support. This means you can use all your existing
Rails models with no problem, as long as you haven't committed any thread-safety sins.

The Action Cable server implements the Rack socket hijacking API,
thereby allowing the use of a multi-threaded pattern for managing connections
internally, irrespective of whether the application server is multi-threaded or not.

Accordingly, Action Cable works with popular servers like Unicorn, Puma, and
Passenger.

## 11. Testing

You can find detailed instructions on how to test your Action Cable functionality in the
testing guide.
