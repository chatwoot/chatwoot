# Sidekiq Changes

[Sidekiq Changes](https://github.com/sidekiq/sidekiq/blob/main/Changes.md) | [Sidekiq Pro Changes](https://github.com/sidekiq/sidekiq/blob/main/Pro-Changes.md) | [Sidekiq Enterprise Changes](https://github.com/sidekiq/sidekiq/blob/main/Ent-Changes.md)

7.3.1
----------

- Don't count job interruptions as failures in metrics [#6386]
- Add frozen string literal to a number of .rb files.
- Fix frozen string error with style_tag and script_tag [#6371]
- Fix an error on Ruby 2.7 because of usage of `Hash#except` [#6376]

7.3.0
----------

- **NEW FEATURE** Add `Sidekiq::IterableJob`, iteration support for long-running jobs. [#6286, fatkodima]
  Iterable jobs are interruptible and can restart quickly if
  running during a deploy. You must ensure that `each_iteration`
  doesn't take more than Sidekiq's `-t` timeout (default: 25 seconds). Iterable jobs must not implement `perform`.
```ruby
class ProcessArrayJob
  include Sidekiq::IterableJob
  def build_enumerator(*args, **kwargs)
    array_enumerator(args, **kwargs)
  end
  def each_iteration(arg)
    puts arg
  end
end
ProcessArrayJob.perform_async(1, 2, 3)
```
See the [Iteration](//github.com/sidekiq/sidekiq/wiki/Iteration) wiki page and the RDoc in `Sidekiq::IterableJob`.
This feature should be considered BETA until the next minor release.
- **SECURITY** The Web UI no longer allows extensions to use `<script>`.
  Adjust CSP to disallow inline scripts within the Web UI. Please see
  `examples/webui-ext` for how to register Web UI extensions and use
  dynamic CSS and JS. This will make Sidekiq immune to XSS attacks. [#6270]
- Add config option, `:skip_default_job_logging` to disable Sidekiq's default
  start/finish job logging. [#6200]
- Allow `Sidekiq::Limiter.redis` to use Redis Cluster [#6288]
- Retain CurrentAttributeѕ after inline execution [#6307]
- Ignore non-existent CurrentAttributes attributes when restoring [#6341]
- Raise default Redis {read,write,connect} timeouts from 1 to 3 seconds
  to minimize ReadTimeoutErrors [#6162]
- Add `logger` as a dependency since it will become bundled in Ruby 3.5 [#6320]
- Ignore unsupported locales in the Web UI [#6313]

7.2.4
----------

- Fix XSS in metrics filtering introduced in 7.2.0, CVE-2024-32887
  Thanks to @UmerAdeemCheema for the security report.

7.2.3
----------

- [Support Dragonfly.io](https://www.mikeperham.com/2024/02/01/supporting-dragonfly/) as an alternative Redis implementation
- Fix error unpacking some compressed error backtraces [#6241]
- Fix potential heartbeat data leak [#6227]
- Add ability to find a currently running work by jid [#6212, fatkodima]

7.2.2
----------

- Add `Process.warmup` call in Ruby 3.3+
- Batch jobs now skip transactional push [#6160]

7.2.1
----------

- Add `Sidekiq::Work` type which replaces the raw Hash as the third parameter in
  `Sidekiq::WorkSet#each { |pid, tid, hash| ... }` [#6145]
- **DEPRECATED**: direct access to the attributes within the `hash` block parameter above.
  The `Sidekiq::Work` instance contains accessor methods to get at the same data, e.g.
```ruby
work["queue"] # Old
work.queue # New
```
- Fix Ruby 3.3 warnings around `base64` gem [#6151, earlopain]

7.2.0
----------

- `sidekiq_retries_exhausted` can return `:discard` to avoid the deadset
  and all death handlers [#6091]
- Metrics filtering by job class in Web UI [#5974]
- Better readability and formatting for numbers within the Web UI [#6080]
- Add explicit error if user code tries to nest test modes [#6078]
```ruby
Sidekiq::Testing.inline! # global setting
Sidekiq::Testing.fake! do # override within block
  # ok
  Sidekiq::Testing.inline! do # can't override the override
    # not ok, nested
  end
end
```
- **SECURITY** Forbid inline JavaScript execution in Web UI [#6074]
- Adjust redis-client adapter to avoid `method_missing` [#6083]
  This can result in app code breaking if your app's Redis API usage was
  depending on Sidekiq's adapter to correct invalid redis-client API usage.
  One example:
```ruby
# bad, not redis-client native
# Unsupported command argument type: TrueClass (TypeError)
Sidekiq.redis { |c| c.set("key", "value", nx: true, ex: 15) }
# good
Sidekiq.redis { |c| c.set("key", "value", "nx", "ex", 15) }
```

7.1.6
----------

- The block forms of testing modes (inline, fake) are now thread-safe so you can have
  a multithreaded test suite which uses different modes for different tests. [#6069]
- Fix breakage with non-Proc error handlers [#6065]

7.1.5
----------

- **FEATURE**: Job filtering within the Web UI. This feature has been open
  sourced from Sidekiq Pro. [#6052]
- **API CHANGE** Error handlers now take three arguments `->(ex, context, config)`.
  The previous calling convention will work until Sidekiq 8.0 but will print
  out a deprecation warning. [#6051]
- Fix issue with the `batch_size` and `at` options in `S::Client.push_bulk` [#6040]
- Fix inline testing firing batch callbacks early [#6057]
- Use new log broadcast API in Rails 7.1 [#6054]
- Crash if user tries to use RESP2 `protocol: 2` [#6061]

7.1.4
----------

- Fix empty `retry_for` logic [#6035]

7.1.3
----------

- Add `sidekiq_options retry_for: 48.hours` to allow time-based retry windows [#6029]
- Support sidekiq_retry_in and sidekiq_retries_exhausted_block in ActiveJobs (#5994)
- Lowercase all Rack headers for Rack 3.0 [#5951]
- Validate Sidekiq::Web page refresh delay to avoid potential DoS,
  CVE-2023-26141, thanks for reporting Keegan!

7.1.2
----------

- Mark Web UI assets as private so CDNs won't cache them [#5936]
- Fix stackoverflow when using Oj and the JSON log formatter [#5920]
- Remove spurious `enqueued_at` from scheduled ActiveJobs [#5937]

7.1.1
----------

- Support multiple CurrentAttributes [#5904]
- Speed up latency fetch with large queues on Redis <7 [#5910]
- Allow a larger default client pool [#5886]
- Ensure Sidekiq.options[:environment] == RAILS_ENV [#5932]

7.1.0
----------

- Improve display of ActiveJob arguments in Web UI [#5825, cover]
- Update `push_bulk` to push `batch_size` jobs at a time and allow laziness [#5827, fatkodima]
  This allows Sidekiq::Client to push unlimited jobs as long as it has enough memory for the batch_size.
- Update `perform_bulk` to use `push_bulk` internally.
- Change return value of `push_bulk` to map 1-to-1 with arguments.
  If you call `push_bulk(args: [[1], [2], [3]])`, you will now always get
  an array of 3 values as the result: `["jid1", nil, "jid3"]` where nil means
  that particular job did not push successfully (possibly due to middleware
  stopping it). Previously nil values were removed so it was impossible to tell
  which jobs pushed successfully and which did not.
- Migrate away from all deprecated Redis commands [#5788]
  Sidekiq will now print a warning if you use one of those deprecated commands.
- Prefix all Sidekiq thread names [#5872]

7.0.9
----------

- Restore confirmation dialogs in Web UI [#5881, shevaun]
- Increase fetch timeout to minimize ReadTimeoutError [#5874]
- Reverse histogram tooltip ordering [#5868]
- Add Scottish Gaelic (gd) locale [#5867, GunChleoc]

7.0.8
----------

- **SECURITY** Sanitize `period` input parameter on Metrics pages.
  Specially crafted values can lead to XSS. This functionality
  was introduced in 7.0.4. Thank you to spercex @ huntr.dev [#5694]
- Add job hash as 3rd parameter to the `sidekiq_retry_in` block.

7.0.7
----------

- Fix redis-client API usage which could result in stuck Redis
connections [#5823]
- Fix AS::Duration with `sidekiq_retry_in` [#5806]
- Restore dumping config options on startup with `-v` [#5822]

7.0.5,7.0.6
----------

- More context for debugging json unsafe errors [#5787]

7.0.4
----------

- Performance and memory optimizations [#5768, fatkodima]
- Add 1-8 hour period selector to Metrics pages [#5694]
- Fix process display with `sidekiqmon` [#5733]

7.0.3
----------

- Don't warn about memory policy on Redis Enterprise [#5712]
- Don't allow Quiet/Stop on embedded Sidekiq instances [#5716]
- Fix `size: X` for configuring the default Redis pool size [#5702]
- Improve the display of queue weights on Busy page [#5642]
- Freeze CurrentAttributes on a job once initially set [#5692]

7.0.2
----------

- Improve compatibility with custom loggers [#5673]
- Add queue weights on Busy page [#5640]
- Add BID link on job_info page if job is part of a Batch [#5623]
- Allow custom extensions to add rows/links within Job detail pages [#5624]
```ruby
Sidekiq::Web.custom_job_info_rows << AddAccountLink.new

class AddAccountLink
  include CGI::Util
  def add_pair(job)
    # yield a (name, value) pair
    # You can include HTML tags and CSS, Sidekiq does not do any
    # escaping so beware user data injection! Note how we use CGI's
    # `h` escape helper.
    aid = job["account_id"]
    yield "Account", "<a href='/accounts/#{h aid}'>#{h aid}</a>" if aid
  end
end
```

7.0.1
----------

- Allow an embedding process to reuse its own heartbeat thread
- Update zh-cn localization

7.0.0
----------

- Embedded mode!
- Capsules!!
- Job Execution metrics!!!
- See `docs/7.0-Upgrade.md` for release notes

6.5.{10,11,12}
----------

- Fixes for Rails 7.1 [#6067, #6070]

6.5.9
----------

- Ensure Sidekiq.options[:environment] == RAILS_ENV [#5932]

6.5.8
----------

- Fail if using a bad version of scout_apm [#5616]
- Add pagination to Busy page [#5556]
- Speed up WorkSet#each [#5559]
- Adjust CurrentAttributes to work with the String class name so we aren't referencing the Class within a Rails initializer [#5536]

6.5.7
----------

- Updates for JA and ZH locales
- Further optimizations for scheduled polling [#5513]

6.5.6
----------

- Fix deprecation warnings with redis-rb 4.8.0 [#5484]
- Lock redis-rb to < 5.0 as we are moving to redis-client in Sidekiq 7.0

6.5.5
----------

- Fix require issue with job_retry.rb [#5462]
- Improve Sidekiq::Web compatibility with Rack 3.x

6.5.4
----------

- Fix invalid code on Ruby 2.5 [#5460]
- Fix further metrics dependency issues [#5457]

6.5.3
----------

- Don't require metrics code without explicit opt-in [#5456]

6.5.2
----------

- [Job Metrics are under active development, help wanted!](https://github.com/sidekiq/sidekiq/wiki/Metrics#contributing) **BETA**
- Add `Context` column on queue page which shows any CurrentAttributes [#5450]
- `sidekiq_retry_in` may now return `:discard` or `:kill` to dynamically stop job retries [#5406]
- Smarter sorting of processes in /busy Web UI [#5398]
- Fix broken hamburger menu in mobile UI [#5428]
- Require redis-rb 4.5.0. Note that Sidekiq will break if you use the
  [`Redis.exists_returns_integer = false`](https://github.com/redis/redis-rb/blob/master/CHANGELOG.md#450) flag. [#5394]

6.5.1
----------

- Fix `push_bulk` breakage [#5387]

6.5.0
---------

- Substantial refactoring of Sidekiq server internals, part of a larger effort
  to reduce Sidekiq's internal usage of global methods and data, see [docs/global_to_local.md](docs/global_to_local.md) and [docs/middleware.md](docs/middleware.md).
- **Add beta support for the `redis-client` gem**. This will become the default Redis driver in Sidekiq 7.0. [#5298]
  Read more: https://github.com/sidekiq/sidekiq/wiki/Using-redis-client
- **Add beta support for DB transaction-aware client** [#5291]
  Add this line to your initializer and any jobs created during a transaction
  will only be pushed to Redis **after the transaction commits**. You will need to add the
  `after_commit_everywhere` gem to your Gemfile.
```ruby
Sidekiq.transactional_push!
```
  This feature does not have a lot of production usage yet; please try it out and let us
  know if you have any issues. It will be fully supported in Sidekiq 7.0 or removed if it
  proves problematic.
- Fix regression with middleware arguments [#5312]

6.4.2
---------

- Strict argument checking now runs after client-side middleware [#5246]
- Fix page events with live polling [#5184]
- Many under-the-hood changes to remove all usage of the term "worker"
  from the Sidekiq codebase and APIs. This mostly involved RDoc and local
  variable names but a few constants and public APIs were changed. The old
  APIs will be removed in Sidekiq 7.0.
```
Sidekiq::DEFAULT_WORKER_OPTIONS -> Sidekiq.default_job_options
Sidekiq.default_worker_options -> Sidekiq.default_job_options
Sidekiq::Queues["default"].jobs_by_worker(HardJob) -> Sidekiq::Queues["default"].jobs_by_class(HardJob)
```

6.4.1
---------

- Fix pipeline/multi deprecations in redis-rb 4.6
- Fix sidekiq.yml YAML load errors on Ruby 3.1 [#5141]
- Sharding support for `perform_bulk` [#5129]
- Refactor job logger for SPEEEEEEED

6.4.0
---------

- **SECURITY**: Validate input to avoid possible DoS in Web UI.
- Add **strict argument checking** [#5071]
  Sidekiq will now log a warning if JSON-unsafe arguments are passed to `perform_async`.
  Add `Sidekiq.strict_args!(false)` to your initializer to disable this warning.
  This warning will switch to an exception in Sidekiq 7.0.
- Note that Delayed Extensions will be removed in Sidekiq 7.0 [#5076]
- Add `perform_{inline,sync}` in Sidekiq::Job to run a job synchronously [#5061, hasan-ally]
```ruby
SomeJob.perform_async(args...)
SomeJob.perform_sync(args...)
SomeJob.perform_inline(args...)
```
  You can also dynamically redirect a job to run synchronously:
```ruby
SomeJob.set("sync": true).perform_async(args...) # will run via perform_inline
```
- Replace Sidekiq::Worker `app/workers` generator with Sidekiq::Job `app/sidekiq` generator [#5055]
```
bin/rails generate sidekiq:job ProcessOrderJob
```
- Fix job retries losing CurrentAttributes [#5090]
- Tweak shutdown to give long-running threads time to cleanup [#5095]

6.3.1
---------

- Fix keyword arguments error with CurrentAttributes on Ruby 3.0 [#5048]

6.3.0
---------

- **BREAK**: The Web UI has been refactored to remove jQuery. Any UI extensions
  which use jQuery will break.
- **FEATURE**: Sidekiq.logger has been enhanced so any `Rails.logger`
  output in jobs now shows up in the Sidekiq console. Remove any logger
  hacks in your initializer and see if it Just Works™ now. [#5021]
- **FEATURE**: Add `Sidekiq::Job` alias for `Sidekiq::Worker`, to better
  reflect industry standard terminology. You can now do this:
```ruby
class MyJob
  include Sidekiq::Job
  sidekiq_options ...
  def perform(args)
  end
end
```
- **FEATURE**: Support for serializing ActiveSupport::CurrentAttributes into each job. [#4982]
```ruby
# config/initializers/sidekiq.rb
require "sidekiq/middleware/current_attributes"
Sidekiq::CurrentAttributes.persist(Myapp::Current) # Your AS::CurrentAttributes singleton
```
- **FEATURE**: Add `Sidekiq::Worker.perform_bulk` for enqueuing jobs in bulk,
  similar to `Sidekiq::Client.push_bulk` [#5042]
```ruby
MyJob.perform_bulk([[1], [2], [3]])
```
- Implement `queue_as`, `wait` and `wait_until` for ActiveJob compatibility [#5003]
- Scheduler now uses Lua to reduce Redis load and network roundtrips [#5044]
- Retry Redis operation if we get an `UNBLOCKED` Redis error [#4985]
- Run existing signal traps, if any, before running Sidekiq's trap [#4991]
- Fix fetch bug when using weighted queues which caused Sidekiq to stop
  processing queues randomly [#5031]

6.2.2
---------

- Reduce retry jitter, add jitter to `sidekiq_retry_in` values [#4957]
- Minimize scheduler load on Redis at scale [#4882]
- Improve logging of delay jobs [#4904, BuonOno]
- Minor CSS improvements for buttons and tables, design PRs always welcome!
- Tweak Web UI `Cache-Control` header [#4966]
- Rename internal API class `Sidekiq::Job` to `Sidekiq::JobRecord` [#4955]

6.2.1
---------

- Update RTT warning logic to handle transient RTT spikes [#4851]
- Fix very low priority CVE on unescaped queue name [#4852]
- Add note about sessions and Rails apps in API mode

6.2.0
---------

- Store Redis RTT and log if poor [#4824]
- Add process/thread stats to Busy page [#4806]
- Improve Web UI on mobile devices [#4840]
- **Refactor Web UI session usage** [#4804]
  Numerous people have hit "Forbidden" errors and struggled with Sidekiq's
  Web UI session requirement. If you have code in your initializer for
  Web sessions, it's quite possible it will need to be removed. Here's
  an overview:
```
Sidekiq::Web needs a valid Rack session for CSRF protection. If this is a Rails app,
make sure you mount Sidekiq::Web *inside* your routes in `config/routes.rb` so
Sidekiq can reuse the Rails session:

  Rails.application.routes.draw do
    mount Sidekiq::Web => "/sidekiq"
    ....
  end

If this is a bare Rack app, use a session middleware before Sidekiq::Web:

  # first, use IRB to create a shared secret key for sessions and commit it
  require 'securerandom'; File.open(".session.key", "w") {|f| f.write(SecureRandom.hex(32)) }

  # now, update your Rack app to include the secret with a session cookie middleware
  use Rack::Session::Cookie, secret: File.read(".session.key"), same_site: true, max_age: 86400
  run Sidekiq::Web

If this is a Rails app in API mode, you need to enable sessions.

  https://guides.rubyonrails.org/api_app.html#using-session-middlewares
```

6.1.3
---------

- Warn if Redis is configured to evict data under memory pressure [#4752]
- Add process RSS on the Busy page [#4717]

6.1.2
---------

- Improve readability in dark mode Web UI [#4674]
- Fix Web UI crash with corrupt session [#4672]
- Allow middleware to yield arguments [#4673, @eugeneius]
- Migrate CI from CircleCI to GitHub Actions [#4677]

6.1.1
---------

- Jobs are now sorted by age in the Busy Workers table. [#4641]
- Fix "check all" JS logic in Web UI [#4619]

6.1.0
---------

- Web UI - Dark Mode fixes [#4543, natematykiewicz]
- Ensure `Rack::ContentLength` is loaded as middleware for correct Web UI responses [#4541]
- Avoid exception dumping SSL store in Redis connection logging [#4532]
- Better error messages in Sidekiq::Client [#4549]
- Remove rack-protection, reimplement CSRF protection [#4588]
- Require redis-rb 4.2 [#4591]
- Update to jquery 1.12.4 [#4593]
- Refactor internal fetch logic and API [#4602]

6.0.7
---------

- Refactor systemd integration to work better with custom binaries [#4511]
- Don't connect to Redis at process exit if not needed [#4502]
- Remove Redis connection naming [#4479]
- Fix Redis Sentinel password redaction [#4499]
- Add Vietnamese locale (vi) [#4528]

6.0.6
---------

- **Integrate with systemd's watchdog and notification features** [#4488]
  Set `Type=notify` in [sidekiq.service](https://github.com/sidekiq/sidekiq/blob/4b8a8bd3ae42f6e48ae1fdaf95ed7d7af18ed8bb/examples/systemd/sidekiq.service#L30-L39). The integration works automatically.
- Use `setTimeout` rather than `setInterval` to avoid thundering herd [#4480]
- Fix edge case where a job can be pushed without a queue.
- Flush job stats at exit [#4498]
- Check RAILS_ENV before RACK_ENV [#4493]
- Add Lithuanian locale [#4476]

6.0.5
---------

- Fix broken Web UI response when using NewRelic and Rack 2.1.2+. [#4440]
- Update APIs to use `UNLINK`, not `DEL`. [#4449]
- Fix Ruby 2.7 warnings [#4412]
- Add support for `APP_ENV` [[95fa5d9]](https://github.com/sidekiq/sidekiq/commit/95fa5d90192148026e52ca2902f1b83c70858ce8)

6.0.4
---------

- Fix ActiveJob's `sidekiq_options` integration [#4404]
- Sidekiq Pro users will now see a Pause button next to each queue in
  the Web UI, allowing them to pause queues manually [#4374, shayonj]
- Fix Sidekiq::Workers API unintentional change in 6.0.2 [#4387]


6.0.3
---------

- Fix `Sidekiq::Client.push_bulk` API which was erroneously putting
  invalid `at` values in the job payloads [#4321]

6.0.2
---------

- Fix Sidekiq Enterprise's rolling restart functionality, broken by refactoring in 6.0.0. [#4334]
- More internal refactoring and performance tuning [fatkodima]

6.0.1
---------

- **Performance tuning**, Sidekiq should be 10-15% faster now [#4303, 4299,
  4269, fatkodima]
- **Dark Mode support in Web UI** (further design polish welcome!) [#4227, mperham,
  fatkodima, silent-e]
- **Job-specific log levels**, allowing you to turn on debugging for
  problematic workers. [fatkodima, #4287]
```ruby
MyWorker.set(log_level: :debug).perform_async(...)
```
- **Ad-hoc job tags**. You can tag your jobs with, e.g, subdomain, tenant, country,
  locale, application, version, user/client, "alpha/beta/pro/ent", types of jobs,
  teams/people responsible for jobs, additional metadata, etc.
  Tags are shown on different pages with job listings. Sidekiq Pro users
  can filter based on them [fatkodima, #4280]
```ruby
class MyWorker
  include Sidekiq::Worker
  sidekiq_options tags: ['bank-ops', 'alpha']
  ...
end
```
- Fetch scheduled jobs in batches before pushing into specific queues.
  This will decrease enqueueing time of scheduled jobs by a third. [fatkodima, #4273]
```
ScheduledSet with 10,000 jobs
Before: 56.6 seconds
After:  39.2 seconds
```
- Compress error backtraces before pushing into Redis, if you are
  storing error backtraces, this will halve the size of your RetrySet
  in Redis [fatkodima, #4272]
```
RetrySet with 100,000 jobs
Before: 261 MB
After:  129 MB
```
- Support display of ActiveJob 6.0 payloads in the Web UI [#4263]
- Add `SortedSet#scan` for pattern based scanning. For large sets this API will be **MUCH** faster
  than standard iteration using each. [fatkodima, #4262]
```ruby
  Sidekiq::DeadSet.new.scan("UnreliableApi") do |job|
    job.retry
  end
```
- Dramatically speed up SortedSet#find\_job(jid) by using Redis's ZSCAN
  support, approx 10x faster. [fatkodima, #4259]
```
zscan   0.179366   0.047727   0.227093 (  1.161376)
enum    8.522311   0.419826   8.942137 (  9.785079)
```
- Respect rails' generators `test_framework` option and gracefully handle extra `worker` suffix on generator [fatkodima, #4256]
- Add ability to sort 'Enqueued' page on Web UI by position in the queue [fatkodima, #4248]
- Support `Client.push_bulk` with different delays [fatkodima, #4243]
```ruby
Sidekiq::Client.push_bulk("class" => FooJob, "args" => [[1], [2]], "at" => [1.minute.from_now.to_f, 5.minutes.from_now.to_f])
```
- Easier way to test enqueuing specific ActionMailer and ActiveRecord delayed jobs. Instead of manually
  parsing embedded class, you can now test by fetching jobs for specific classes. [fatkodima, #4292]
```ruby
assert_equal 1, Sidekiq::Extensions::DelayedMailer.jobs_for(FooMailer).size
```
- Add `sidekiqmon` to gemspec executables [#4242]
- Gracefully handle `Sidekiq.logger = nil` [#4240]
- Inject Sidekiq::LogContext module if user-supplied logger does not include it [#4239]

6.0
---------

This release has major breaking changes.  Read and test carefully in production.

- With Rails 6.0.2+, ActiveJobs can now use `sidekiq_options` directly to configure Sidekiq
  features/internals like the retry subsystem. [#4213, pirj]
```ruby
class MyJob < ActiveJob::Base
  queue_as :myqueue
  sidekiq_options retry: 10, backtrace: 20
  def perform(...)
  end
end
```
- Logging has been redesigned to allow for pluggable log formatters:
```ruby
Sidekiq.configure_server do |config|
  config.log_formatter = Sidekiq::Logger::Formatters::JSON.new
end
```
See the [Logging wiki page](https://github.com/sidekiq/sidekiq/wiki/Logging) for more details.
- **BREAKING CHANGE** Validate proper usage of the `REDIS_PROVIDER`
  variable.  This variable is meant to hold the name of the environment
  variable which contains your Redis URL, so that you can switch Redis
  providers quickly and easily with a single variable change.  It is not
  meant to hold the actual Redis URL itself.  If you want to manually set
  the Redis URL (not recommended as it implies you have no failover),
  then you may set `REDIS_URL` directly. [#3969]
- **BREAKING CHANGE** Increase default shutdown timeout from 8 seconds
  to 25 seconds.  Both Heroku and ECS now use 30 second shutdown timeout
  by default and we want Sidekiq to take advantage of this time.  If you
  have deployment scripts which depend on the old default timeout, use `-t 8` to
  get the old behavior. [#3968]
- **BREAKING CHANGE** Remove the daemonization, logfile and pidfile
  arguments to Sidekiq. Use a proper process supervisor (e.g. systemd or
  foreman) to manage Sidekiq.  See the Deployment wiki page for links to
  more resources.
- Integrate the StandardRB code formatter to ensure consistent code
  styling. [#4114, gearnode]

5.2.10
---------

- Backport fix for CVE-2022-23837.
- Migrate to `exists?` for redis-rb.
- Lock redis-rb to <4.6 to avoid deprecations.

5.2.9
---------

- Release Rack lock due to a cascade of CVEs. [#4566]
  Pro-tip: don't lock Rack.

5.2.8
---------

- Lock to Rack 2.0.x to prevent future incompatibilities
- Fix invalid reference in `sidekiqctl`

5.2.7
---------

- Fix stale `enqueued_at` when retrying [#4149]
- Move build to [Circle CI](https://circleci.com/gh/mperham/sidekiq) [#4120]

5.2.6
---------

- Fix edge case where a job failure during Redis outage could result in a lost job [#4141]
- Better handling of malformed job arguments in payload [#4095]
- Restore bootstap's dropdown css component [#4099, urkle]
- Display human-friendly time diff for longer queue latencies [#4111, interlinked]
- Allow `Sidekiq::Worker#set` to be chained

5.2.5
---------

- Fix default usage of `config/sidekiq.yml` [#4077, Tensho]

5.2.4
---------

- Add warnings for various deprecations and changes coming in Sidekiq 6.0.
  See the 6-0 branch. [#4056]
- Various improvements to the Sidekiq test suite and coverage [#4026, #4039, Tensho]

5.2.3
---------

- Warning message on invalid REDIS\_PROVIDER [#3970]
- Add `sidekiqctl status` command [#4003, dzunk]
- Update elapsed time calculatons to use monotonic clock [#3999]
- Fix a few issues with mobile Web UI styling [#3973, navied]
- Jobs with `retry: false` now go through the global `death_handlers`,
  meaning you can take action on failed ephemeral jobs. [#3980, Benjamin-Dobell]
- Fix race condition in defining Workers. [#3997, mattbooks]

5.2.2
---------

- Raise error for duplicate queue names in config to avoid unexpected fetch algorithm change [#3911]
- Fix concurrency bug on JRuby [#3958, mattbooks]
- Add "Kill All" button to the retries page [#3938]

5.2.1
-----------

- Fix concurrent modification error during heartbeat [#3921]

5.2.0
-----------

- **Decrease default concurrency from 25 to 10** [#3892]
- Verify connection pool sizing upon startup [#3917]
- Smoother scheduling for large Sidekiq clusters [#3889]
- Switch Sidekiq::Testing impl from alias\_method to Module#prepend, for resiliency [#3852]
- Update Sidekiq APIs to use SCAN for scalability [#3848, ffiller]
- Remove concurrent-ruby gem dependency [#3830]
- Optimize Web UI's bootstrap.css [#3914]

5.1.3
-----------

- Fix version comparison so Ruby 2.2.10 works. [#3808, nateberkopec]

5.1.2
-----------

- Add link to docs in Web UI footer
- Fix crash on Ctrl-C in Windows [#3775, Bernica]
- Remove `freeze` calls on String constants. This is superfluous with Ruby
  2.3+ and `frozen_string_literal: true`. [#3759]
- Fix use of AR middleware outside of Rails [#3787]
- Sidekiq::Worker `sidekiq_retry_in` block can now return nil or 0 to use
  the default backoff delay [#3796, dsalahutdinov]

5.1.1
-----------

- Fix Web UI incompatibility with Redis 3.x gem [#3749]

5.1.0
-----------

- **NEW** Global death handlers - called when your job exhausts all
  retries and dies.  Now you can take action when a job fails permanently. [#3721]
- **NEW** Enable ActiveRecord query cache within jobs by default [#3718, sobrinho]
  This will prevent duplicate SELECTS; cache is cleared upon any UPDATE/INSERT/DELETE.
  See the issue for how to bypass the cache or disable it completely.
- Scheduler timing is now more accurate, 15 -> 5 seconds [#3734]
- Exceptions during the :startup event will now kill the process [#3717]
- Make `Sidekiq::Client.via` reentrant [#3715]
- Fix use of Sidekiq logger outside of the server process [#3714]
- Tweak `constantize` to better match Rails class lookup. [#3701, caffeinated-tech]

5.0.5
-----------

- Update gemspec to allow newer versions of the Redis gem [#3617]
- Refactor Worker.set so it can be memoized [#3602]
- Fix display of Redis URL in web footer, broken in 5.0.3 [#3560]
- Update `Sidekiq::Job#display_args` to avoid mutation [#3621]

5.0.4
-----------

- Fix "slow startup" performance regression from 5.0.2. [#3525]
- Allow users to disable ID generation since some redis providers disable the CLIENT command. [#3521]

5.0.3
-----------

- Fix overriding `class_attribute` core extension from ActiveSupport with Sidekiq one [PikachuEXE, #3499]
- Allow job logger to be overridden [AlfonsoUceda, #3502]
- Set a default Redis client identifier for debugging [#3516]
- Fix "Uninitialized constant" errors on startup with the delayed extensions [#3509]

5.0.2
-----------

- fix broken release, thanks @nateberkopec

5.0.1
-----------

- Fix incorrect server identity when daemonizing [jwilm, #3496]
- Work around error running Web UI against Redis Cluster [#3492]
- Remove core extensions, Sidekiq is now monkeypatch-free! [#3474]
- Reimplement Web UI's HTTP\_ACCEPT\_LANGUAGE parsing because the spec is utterly
  incomprehensible for various edge cases. [johanlunds, natematykiewicz, #3449]
- Update `class_attribute` core extension to avoid warnings
- Expose `job_hash_context` from `Sidekiq::Logging` to support log customization

5.0.0
-----------

- **BREAKING CHANGE** Job dispatch was refactored for safer integration with
  Rails 5.  The **Logging** and **RetryJobs** server middleware were removed and
  functionality integrated directly into Sidekiq::Processor.  These aren't
  commonly used public APIs so this shouldn't impact most users.
```
Sidekiq::Middleware::Server::RetryJobs -> Sidekiq::JobRetry
Sidekiq::Middleware::Server::Logging -> Sidekiq::JobLogger
```
- Quieting Sidekiq is now done via the TSTP signal, the USR1 signal is deprecated.
- The `delay` extension APIs are no longer available by default, you
  must opt into them.
- The Web UI is now BiDi and can render RTL languages like Arabic, Farsi and Hebrew.
- Rails 3.2 and Ruby 2.0 and 2.1 are no longer supported.
- The `SomeWorker.set(options)` API was re-written to avoid thread-local state. [#2152]
- Sidekiq Enterprise's encrypted jobs now display "[encrypted data]" in the Web UI instead
  of random hex bytes.
- Please see the [5.0 Upgrade notes](docs/5.0-Upgrade.md) for more detail.

4.2.10
-----------

- Scheduled jobs can now be moved directly to the Dead queue via API [#3390]
- Fix edge case leading to job duplication when using Sidekiq Pro's
  reliability feature [#3388]
- Fix error class name display on retry page [#3348]
- More robust latency calculation [#3340]

4.2.9
-----------

- Rollback [#3303] which broke Heroku Redis users [#3311]
- Add support for TSTP signal, for Sidekiq 5.0 forward compatibility. [#3302]

4.2.8
-----------

- Fix rare edge case with Redis driver that can create duplicate jobs [#3303]
- Fix Rails 5 loading issue [#3275]
- Restore missing tooltips to timestamps in Web UI [#3310]
- Work on **Sidekiq 5.0** is now active! [#3301]

4.2.7
-----------

- Add new integration testing to verify code loading and job execution
  in development and production modes with Rails 4 and 5 [#3241]
- Fix delayed extensions in development mode [#3227, DarthSim]
- Use Worker's `retry` default if job payload does not have a retry
  attribute [#3234, mlarraz]

4.2.6
-----------

- Run Rails Executor when in production [#3221, eugeneius]

4.2.5
-----------

- Re-enable eager loading of all code when running non-development Rails 5. [#3203]
- Better root URL handling for zany web servers [#3207]

4.2.4
-----------

- Log errors coming from the Rails 5 reloader. [#3212, eugeneius]
- Clone job data so middleware changes don't appear in Busy tab

4.2.3
-----------

- Disable use of Rails 5's Reloader API in non-development modes, it has proven
  to be unstable under load [#3154]
- Allow disabling of Sidekiq::Web's cookie session to handle the
  case where the app provides a session already [#3180, inkstak]
```ruby
Sidekiq::Web.set :sessions, false
```
- Fix Web UI sharding support broken in 4.2.2. [#3169]
- Fix timestamps not updating during UI polling [#3193, shaneog]
- Relax rack-protection version to >= 1.5.0
- Provide consistent interface to exception handlers, changing the structure of the context hash. [#3161]

4.2.2
-----------

- Fix ever-increasing cookie size with nginx [#3146, cconstantine]
- Fix so Web UI works without trailing slash [#3158, timdorr]

4.2.1
-----------

- Ensure browser does not cache JSON/AJAX responses. [#3136]
- Support old Sinatra syntax for setting config [#3139]

4.2.0
-----------

- Enable development-mode code reloading.  **With Rails 5.0+, you don't need
  to restart Sidekiq to pick up your Sidekiq::Worker changes anymore!** [#2457]
- **Remove Sinatra dependency**.  Sidekiq's Web UI now uses Rack directly.
  Thank you to Sidekiq's newest committer, **badosu**, for writing the code
  and doing a lot of testing to ensure compatibility with many different
  3rd party plugins.  If your Web UI works with 4.1.4 but fails with
  4.2.0, please open an issue. [#3075]
- Allow tuning of concurrency with the `RAILS_MAX_THREADS` env var. [#2985]
  This is the same var used by Puma so you can tune all of your systems
  the same way:
```sh
web: RAILS_MAX_THREADS=5 bundle exec puma ...
worker: RAILS_MAX_THREADS=10 bundle exec sidekiq ...
```
Using `-c` or `config/sidekiq.yml` overrides this setting.  I recommend
adjusting your `config/database.yml` to use it too so connections are
auto-scaled:
```yaml
  pool: <%= ENV['RAILS_MAX_THREADS'] || 5 %>
```

4.1.4
-----------

- Unlock Sinatra so a Rails 5.0 compatible version may be used [#3048]
- Fix race condition on startup with JRuby [#3043]


4.1.3
-----------

- Please note the Redis 3.3.0 gem has a [memory leak](https://github.com/redis/redis-rb/issues/612),
  Redis 3.2.2 is recommended until that issue is fixed.
- Sinatra 1.4.x is now a required dependency, avoiding cryptic errors
  and old bugs due to people not upgrading Sinatra for years. [#3042]
- Fixed race condition in heartbeat which could rarely lead to lingering
  processes on the Busy tab. [#2982]
```ruby
# To clean up lingering processes, modify this as necessary to connect to your Redis.
# After 60 seconds, lingering processes should disappear from the Busy page.

require 'redis'
r = Redis.new(url: "redis://localhost:6379/0")
# uncomment if you need a namespace
#require 'redis-namespace'
#r = Redis::Namespace.new("foo", r)
r.smembers("processes").each do |pro|
  r.expire(pro, 60)
  r.expire("#{pro}:workers", 60)
end
```


4.1.2
-----------

- Fix Redis data leak with worker data when a busy Sidekiq process
  crashes.  You can find and expire leaked data in Redis with this
script:
```bash
$ redis-cli keys  "*:workers" | while read LINE ; do TTL=`redis-cli expire "$LINE" 60`; echo "$LINE"; done;
```
  Please note that `keys` can be dangerous to run on a large, busy Redis.  Caveat runner.
- Freeze all string literals with Ruby 2.3. [#2741]
- Client middleware can now stop bulk job push. [#2887]

4.1.1
-----------

- Much better behavior when Redis disappears and comes back. [#2866]
- Update FR locale [dbachet]
- Don't fill logfile in case of Redis downtime [#2860]
- Allow definition of a global retries_exhausted handler. [#2807]
```ruby
Sidekiq.configure_server do |config|
  config.default_retries_exhausted = -> (job, ex) do
    Sidekiq.logger.info "#{job['class']} job is now dead"
  end
end
```

4.1.0
-----------

- Tag quiet processes in the Web UI [#2757, jcarlson]
- Pass last exception to sidekiq\_retries\_exhausted block [#2787, Nowaker]
```ruby
class MyWorker
  include Sidekiq::Worker
  sidekiq_retries_exhausted do |job, exception|
  end
end
```
- Add native support for ActiveJob's `set(options)` method allowing
you to override worker options dynamically.  This should make it
even easier to switch between ActiveJob and Sidekiq's native APIs [#2780]
```ruby
class MyWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'default', retry: true

  def perform(*args)
    # do something
  end
end

MyWorker.set(queue: 'high', retry: false).perform_async(1)
```

4.0.2
-----------

- Better Japanese translations
- Remove `json` gem dependency from gemspec. [#2743]
- There's a new testing API based off the `Sidekiq::Queues` namespace. All
  assertions made against the Worker class still work as expected.
  [#2676, brandonhilkert]
```ruby
assert_equal 0, Sidekiq::Queues["default"].size
HardWorker.perform_async("log")
assert_equal 1, Sidekiq::Queues["default"].size
assert_equal "log", Sidekiq::Queues["default"].first['args'][0]
Sidekiq::Queues.clear_all
```

4.0.1
-----------

- Yank new queue-based testing API [#2663]
- Fix invalid constant reference in heartbeat

4.0.0
-----------

- Sidekiq's internals have been completely overhauled for performance
  and to remove dependencies.  This has resulted in major speedups, as
  [detailed on my blog](http://www.mikeperham.com/2015/10/14/optimizing-sidekiq/).
- See the [4.0 upgrade notes](docs/4.0-Upgrade.md) for more detail.

3.5.4
-----------

- Ensure exception message is a string [#2707]
- Revert racy Process.kill usage in sidekiqctl

3.5.3
-----------

- Adjust shutdown event to run in parallel with the rest of system shutdown. [#2635]

3.5.2
-----------

- **Sidekiq 3 is now in maintenance mode**, only major bugs will be fixed.
- The exception triggering a retry is now passed into `sidekiq_retry_in`,
  allowing you to retry more frequently for certain types of errors.
  [#2619, kreynolds]
```ruby
  sidekiq_retry_in do |count, ex|
    case ex
    when RuntimeError
      5 * count
    else
      10 * count
    end
  end
```

3.5.1
-----------

- **FIX MEMORY LEAK** Under rare conditions, threads may leak [#2598, gazay]
- Add Ukrainian locale [#2561, elrakita]
- Disconnect and retry Redis operations if we see a READONLY error [#2550]
- Add server middleware testing harness; see [wiki](https://github.com/sidekiq/sidekiq/wiki/Testing#testing-server-middleware) [#2534, ryansch]

3.5.0
-----------

- Polished new banner! [#2522, firedev]
- Upgrade to Celluloid 0.17. [#2420, digitalextremist]
- Activate sessions in Sinatra for CSRF protection, requires Rails
  monkeypatch due to rails/rails#15843. [#2460, jc00ke]

3.4.2
-----------

- Don't allow `Sidekiq::Worker` in ActiveJob::Base classes. [#2424]
- Safer display of job data in Web UI [#2405]
- Fix CSRF vulnerability in Web UI, thanks to Egor Homakov for
  reporting. [#2422] If you are running the Web UI as a standalone Rack app,
  ensure you have a [session middleware
configured](https://github.com/sidekiq/sidekiq/wiki/Monitoring#standalone):
```ruby
use Rack::Session::Cookie, :secret => "some unique secret string here"
```

3.4.1
-----------

- Lock to Celluloid 0.16


3.4.0
-----------

- Set a `created_at` attribute when jobs are created, set `enqueued_at` only
  when they go into a queue. Fixes invalid latency calculations with scheduled jobs.
  [#2373, mrsimo]
- Don't log timestamp on Heroku [#2343]
- Run `shutdown` event handlers in reverse order of definition [#2374]
- Rename and rework `poll_interval` to be simpler, more predictable [#2317, cainlevy]
  The new setting is `average_scheduled_poll_interval`.  To configure
  Sidekiq to look for scheduled jobs every 5 seconds, just set it to 5.
```ruby
Sidekiq.configure_server do |config|
  config.average_scheduled_poll_interval = 5
end
```

3.3.4
-----------

- **Improved ActiveJob integration** - Web UI now shows ActiveJobs in a
  nicer format and job logging shows the actual class name, requires
  Rails 4.2.2+ [#2248, #2259]
- Add Sidekiq::Process#dump\_threads API to trigger TTIN output [#2247]
- Web UI polling now uses Ajax to avoid page reload [#2266, davydovanton]
- Several Web UI styling improvements [davydovanton]
- Add Tamil, Hindi translations for Web UI [ferdinandrosario, tejasbubane]
- Fix Web UI to work with country-specific locales [#2243]
- Handle circular error causes [#2285,  eugenk]

3.3.3
-----------

- Fix crash on exit when Redis is down [#2235]
- Fix duplicate logging on startup
- Undeprecate delay extension for ActionMailer 4.2+ . [#2186]

3.3.2
-----------

- Add Sidekiq::Stats#queues back
- Allows configuration of dead job set size and timeout [#2173, jonhyman]
- Refactor scheduler enqueuing so Sidekiq Pro can override it. [#2159]

3.3.1
-----------

- Dumb down ActionMailer integration so it tries to deliver if possible [#2149]
- Stringify Sidekiq.default\_worker\_options's keys [#2126]
- Add random integer to process identity [#2113, michaeldiscala]
- Log Sidekiq Pro's Batch ID if available [#2076]
- Refactor Processor Redis usage to avoid redis/redis-rb#490 [#2094]
- Move /dashboard/stats to /stats.  Add /stats/queues. [moserke, #2099]
- Add processes count to /stats [ismaelga, #2141]
- Greatly improve speed of Sidekiq::Stats [ismaelga, #2142]
- Add better usage text for `sidekiqctl`.
- `Sidekiq::Logging.with_context` is now a stack so you can set your
  own job context for logging purposes [grosser, #2110]
- Remove usage of Google Fonts in Web UI so it loads in China [#2144]

3.3.0
-----------

- Upgrade to Celluloid 0.16 [#2056]
- Fix typo for generator test file name [dlackty, #2016]
- Add Sidekiq::Middleware::Chain#prepend [seuros, #2029]

3.2.6
-----------

- Deprecate delay extension for ActionMailer 4.2+ . [seuros, #1933]
- Poll interval tuning now accounts for dead processes [epchris, #1984]
- Add non-production environment to Web UI page titles [JacobEvelyn, #2004]

3.2.5
-----------

- Lock Celluloid to 0.15.2 due to bugs in 0.16.0.  This prevents the
  "hang on shutdown" problem with Celluloid 0.16.0.

3.2.4
-----------

- Fix issue preventing ActionMailer sends working in some cases with
  Rails 4. [pbhogan, #1923]

3.2.3
-----------

- Clean invalid bytes from error message before converting to JSON (requires Ruby 2.1+) [#1705]
- Add queues list for each process to the Busy page. [davetoxa, #1897]
- Fix for crash caused by empty config file. [jordan0day, #1901]
- Add Rails Worker generator, `rails g sidekiq:worker User` will create `app/workers/user_worker.rb`. [seuros, #1909]
- Fix Web UI rendering with huge job arguments [jhass, #1918]
- Minor refactoring of Sidekiq::Client internals, for Sidekiq Pro. [#1919]

3.2.2
-----------

- **This version of Sidekiq will no longer start on Ruby 1.9.**  Sidekiq
  3 does not support MRI 1.9 but we've allowed it to run before now.
- Fix issue which could cause Sidekiq workers to disappear from the Busy
  tab while still being active [#1884]
- Add "Back to App" button in Web UI.  You can set the button link via
  `Sidekiq::Web.app_url = 'http://www.mysite.com'` [#1875, seuros]
- Add process tag (`-g tag`) to the Busy page so you can differentiate processes at a glance. [seuros, #1878]
- Add "Kill" button to move retries directly to the DJQ so they don't retry. [seuros, #1867]

3.2.1
-----------

- Revert eager loading change for Rails 3.x apps, as it broke a few edge
  cases.

3.2.0
-----------

- **Fix issue which caused duplicate job execution in Rails 3.x**
  This issue is caused by [improper exception handling in ActiveRecord](https://github.com/rails/rails/blob/3-2-stable/activerecord/lib/active_record/connection_adapters/abstract_adapter.rb#L281) which changes Sidekiq's Shutdown exception into a database
  error, making Sidekiq think the job needs to be retried. **The fix requires Ruby 2.1**. [#1805]
- Update how Sidekiq eager loads Rails application code [#1791, jonleighton]
- Change logging timestamp to show milliseconds.
- Reverse sorting of Dead tab so newer jobs are listed first [#1802]

3.1.4
-----------

- Happy π release!
- Self-tuning Scheduler polling, we use heartbeat info to better tune poll\_interval [#1630]
- Remove all table column width rules, hopefully get better column formatting [#1747]
- Handle edge case where YAML can't be decoded in dev mode [#1761]
- Fix lingering jobs in Busy page on Heroku [#1764]

3.1.3
-----------

- Use ENV['DYNO'] on Heroku for hostname display, rather than an ugly UUID. [#1742]
- Show per-process labels on the Busy page, for feature tagging [#1673]


3.1.2
-----------

- Suitably chastised, @mperham reverts the Bundler change.


3.1.1
-----------

- Sidekiq::CLI now runs `Bundler.require(:default, environment)` to boot all gems
  before loading any app code.
- Sort queues by name in Web UI [#1734]


3.1.0
-----------

- New **remote control** feature: you can remotely trigger Sidekiq to quiet
  or terminate via API, without signals.  This is most useful on JRuby
  or Heroku which does not support the USR1 'quiet' signal.  Now you can
  run a rake task like this at the start of your deploy to quiet your
  set of Sidekiq processes. [#1703]
```ruby
namespace :sidekiq do
  task :quiet => :environment do
    Sidekiq::ProcessSet.new.each(&:quiet!)
  end
end
```
- The Web UI can use the API to quiet or stop all processes via the Busy page.
- The Web UI understands and hides the `Sidekiq::Extensions::Delay*`
  classes, instead showing `Class.method` as the Job. [#1718]
- Polish the Dashboard graphs a bit, update Rickshaw [brandonhilkert, #1725]
- The poll interval is now configurable in the Web UI [madebydna, #1713]
- Delay extensions can be removed so they don't conflict with
  DelayedJob: put `Sidekiq.remove_delay!` in your initializer. [devaroop, #1674]


3.0.2
-----------

- Revert gemfile requirement of Ruby 2.0.  JRuby 1.7 calls itself Ruby
  1.9.3 and broke with this requirement.

3.0.1
-----------

- Revert pidfile behavior from 2.17.5: Sidekiq will no longer remove its own pidfile
  as this is a race condition when restarting. [#1470, #1677]
- Show warning on the Queues page if a queue is paused [#1672]
- Only activate the ActiveRecord middleware if ActiveRecord::Base is defined on boot. [#1666]
- Add ability to disable jobs going to the DJQ with the `dead` option.
```ruby
sidekiq_options :dead => false, :retry => 5
```
- Minor fixes


3.0.0
-----------

Please see [3.0-Upgrade.md](docs/3.0-Upgrade.md) for more comprehensive upgrade notes.

- **Dead Job Queue** - jobs which run out of retries are now moved to a dead
  job queue.  These jobs must be retried manually or they will expire
  after 6 months or 10,000 jobs.  The Web UI contains a "Dead" tab
  exposing these jobs.  Use `sidekiq_options :retry => false` if you
don't wish jobs to be retried or put in the DJQ.  Use
`sidekiq_options :retry => 0` if you don't want jobs to retry but go
straight to the DJQ.
- **Process Lifecycle Events** - you can now register blocks to run at
  certain points during the Sidekiq process lifecycle: startup, quiet and
  shutdown.
```ruby
Sidekiq.configure_server do |config|
  config.on(:startup) do
    # do something
  end
end
```
- **Global Error Handlers** - blocks of code which handle errors that
  occur anywhere within Sidekiq, not just within middleware.
```ruby
Sidekiq.configure_server do |config|
  config.error_handlers << proc {|ex,ctx| ... }
end
```
- **Process Heartbeat** - each Sidekiq process will ping Redis every 5
  seconds to give a summary of the Sidekiq population at work.
- The Workers tab is now renamed to Busy and contains a list of live
  Sidekiq processes and jobs in progress based on the heartbeat.
- **Shardable Client** - Sidekiq::Client instances can use a custom
  Redis connection pool, allowing very large Sidekiq installations to scale by
  sharding: sending different jobs to different Redis instances.
```ruby
client = Sidekiq::Client.new(ConnectionPool.new { Redis.new })
client.push(...)
```
```ruby
Sidekiq::Client.via(ConnectionPool.new { Redis.new }) do
  FooWorker.perform_async
  BarWorker.perform_async
end
```
  **Sharding support does require a breaking change to client-side
middleware, see docs/3.0-Upgrade.md.**
- New Chinese, Greek, Swedish and Czech translations for the Web UI.
- Updated most languages translations for the new UI features.
- **Remove official Capistrano integration** - this integration has been
  moved into the [capistrano-sidekiq](https://github.com/seuros/capistrano-sidekiq) gem.
- **Remove official support for MRI 1.9** - Things still might work but
  I no longer actively test on it.
- **Remove built-in support for Redis-to-Go**.
  Heroku users: `heroku config:set REDIS_PROVIDER=REDISTOGO_URL`
- **Remove built-in error integration for Airbrake, Honeybadger, ExceptionNotifier and Exceptional**.
  Each error gem should provide its own Sidekiq integration.  Update your error gem to the latest
  version to pick up Sidekiq support.
- Upgrade to connection\_pool 2.0 which now creates connections lazily.
- Remove deprecated Sidekiq::Client.registered\_\* APIs
- Remove deprecated support for the old Sidekiq::Worker#retries\_exhausted method.
- Removed 'sidekiq/yaml\_patch', this was never documented or recommended.
- Removed --profile option, #1592
- Remove usage of the term 'Worker' in the UI for clarity.  Users would call both threads and
  processes 'workers'.  Instead, use "Thread", "Process" or "Job".

2.17.7
-----------

- Auto-prune jobs older than one hour from the Workers page [#1508]
- Add Sidekiq::Workers#prune which can perform the auto-pruning.
- Fix issue where a job could be lost when an exception occurs updating
  Redis stats before the job executes [#1511]

2.17.6
-----------

- Fix capistrano integration due to missing pidfile. [#1490]

2.17.5
-----------

- Automatically use the config file found at `config/sidekiq.yml`, if not passed `-C`. [#1481]
- Store 'retried\_at' and 'failed\_at' timestamps as Floats, not Strings. [#1473]
- A `USR2` signal will now reopen _all_ logs, using IO#reopen. Thus, instead of creating a new Logger object,
  Sidekiq will now just update the existing Logger's file descriptor [#1163].
- Remove pidfile when shutting down if started with `-P` [#1470]

2.17.4
-----------

- Fix JID support in inline testing, #1454
- Polish worker arguments display in UI, #1453
- Marshal arguments fully to avoid worker mutation, #1452
- Support reverse paging sorted sets, #1098


2.17.3
-----------

- Synchronously terminates the poller and fetcher to fix a race condition in bulk requeue during shutdown [#1406]

2.17.2
-----------

- Fix bug where strictly prioritized queues might be processed out of
  order [#1408]. A side effect of this change is that it breaks a queue
  declaration syntax that worked, although only because of a bug—it was
  never intended to work and never supported. If you were declaring your
  queues as a  comma-separated list, e.g. `sidekiq -q critical,default,low`,
  you must now use the `-q` flag before each queue, e.g.
  `sidekiq -q critical -q default -q low`.

2.17.1
-----------

- Expose `delay` extension as `sidekiq_delay` also.  This allows you to
  run Delayed::Job and Sidekiq in the same process, selectively porting
  `delay` calls to `sidekiq_delay`.  You just need to ensure that
  Sidekiq is required **before** Delayed::Job in your Gemfile. [#1393]
- Bump redis client required version to 3.0.6
- Minor CSS fixes for Web UI

2.17.0
-----------

- Change `Sidekiq::Client#push_bulk` to return an array of pushed `jid`s. [#1315, barelyknown]
- Web UI refactoring to use more API internally (yummy dogfood!)
- Much faster Sidekiq::Job#delete performance for larger queue sizes
- Further capistrano 3 fixes
- Many misc minor fixes

2.16.1
-----------

- Revert usage of `resolv-replace`.  MRI's native DNS lookup releases the GIL.
- Fix several Capistrano 3 issues
- Escaping dynamic data like job args and error messages in Sidekiq Web UI. [#1299, lian]

2.16.0
-----------

- Deprecate `Sidekiq::Client.registered_workers` and `Sidekiq::Client.registered_queues`
- Refactor Sidekiq::Client to be instance-based [#1279]
- Pass all Redis options to the Redis driver so Unix sockets
  can be fully configured. [#1270, salimane]
- Allow sidekiq-web extensions to add locale paths so extensions
  can be localized. [#1261, ondrejbartas]
- Capistrano 3 support [#1254, phallstrom]
- Use Ruby's `resolv-replace` to enable pure Ruby DNS lookups.
  This ensures that any DNS resolution that takes place in worker
  threads won't lock up the entire VM on MRI. [#1258]

2.15.2
-----------

- Iterating over Sidekiq::Queue and Sidekiq::SortedSet will now work as
  intended when jobs are deleted [#866, aackerman]
- A few more minor Web UI fixes [#1247]

2.15.1
-----------

- Fix several Web UI issues with the Bootstrap 3 upgrade.

2.15.0
-----------

- The Core Sidekiq actors are now monitored.  If any crash, the
  Sidekiq process logs the error and exits immediately.  This is to
  help prevent "stuck" Sidekiq processes which are running but don't
  appear to be doing any work. [#1194]
- Sidekiq's testing behavior is now dynamic.  You can choose between
  `inline` and `fake` behavior in your tests. See
[Testing](https://github.com/sidekiq/sidekiq/wiki/Testing) for detail. [#1193]
- The Retries table has a new column for the error message.
- The Web UI topbar now contains the status and live poll button.
- Orphaned worker records are now auto-vacuumed when you visit the
  Workers page in the Web UI.
- Sidekiq.default\_worker\_options allows you to configure default
  options for all Sidekiq worker types.

```ruby
Sidekiq.default_worker_options = { 'queue' => 'default', 'backtrace' => true }
```
- Added two Sidekiq::Client class methods for compatibility with resque-scheduler:
  `enqueue_to_in` and `enqueue_in` [#1212]
- Upgrade Web UI to Bootstrap 3.0. [#1211, jeffboek]

2.14.1
-----------

- Fix misc Web UI issues due to ERB conversion.
- Bump redis-namespace version due to security issue.

2.14.0
-----------

- Removed slim gem dependency, Web UI now uses ERB [Locke23rus, #1120]
- Fix more race conditions in Web UI actions
- Don't reset Job enqueued\_at when retrying
- Timestamp tooltips in the Web UI should use UTC
- Fix invalid usage of handle\_exception causing issues in Airbrake
  [#1134]


2.13.1
-----------

- Make Sidekiq::Middleware::Chain Enumerable
- Make summary bar and graphs responsive [manishval, #1025]
- Adds a job status page for scheduled jobs [jonhyman]
- Handle race condition in retrying and deleting jobs in the Web UI
- The Web UI relative times are now i18n. [MadRabbit, #1088]
- Allow for default number of retry attempts to be set for
  `Sidekiq::Middleware::Server::RetryJobs` middleware. [czarneckid] [#1091]

```ruby
Sidekiq.configure_server do |config|
  config.server_middleware do |chain|
    chain.add Sidekiq::Middleware::Server::RetryJobs, :max_retries => 10
  end
end
```


2.13.0
-----------

- Adding button to move scheduled job to main queue [guiceolin, #1020]
- fix i18n support resetting saved locale when job is retried [#1011]
- log rotation via USR2 now closes the old logger [#1008]
- Add ability to customize retry schedule, like so [jmazzi, #1027]

```ruby
class MyWorker
  include Sidekiq::Worker
  sidekiq_retry_in { |count| count * 2 }
end
```
- Redesign Worker#retries\_exhausted callback to use same form as above [jmazzi, #1030]

```ruby
class MyWorker
  include Sidekiq::Worker
  sidekiq_retries_exhausted do |msg|
    Rails.logger.error "Failed to process #{msg['class']} with args: #{msg['args']}"
  end
end
```

2.12.4
-----------

- Fix error in previous release which crashed the Manager when a
  Processor died.

2.12.3
-----------

- Revert back to Celluloid's TaskFiber for job processing which has proven to be more
  stable than TaskThread. [#985]
- Avoid possible lockup during hard shutdown [#997]

At this point, if you are experiencing stability issues with Sidekiq in
Ruby 1.9, please try Ruby 2.0.  It seems to be more stable.

2.12.2
-----------

- Relax slim version requirement to >= 1.1.0
- Refactor historical stats to use TTL, not explicit cleanup. [grosser, #971]

2.12.1
-----------

- Force Celluloid 0.14.1 as 0.14.0 has a serious bug. [#954]
- Scheduled and Retry jobs now use Sidekiq::Client to push
  jobs onto the queue, so they use client middleware. [dimko, #948]
- Record the timestamp when jobs are enqueued. Add
  Sidekiq::Job#enqueued\_at to query the time. [mariovisic, #944]
- Add Sidekiq::Queue#latency - calculates diff between now and
  enqueued\_at for the oldest job in the queue.
- Add testing method `perform_one` that dequeues and performs a single job.
  This is mainly to aid testing jobs that spawn other jobs. [fumin, #963]

2.12.0
-----------

- Upgrade to Celluloid 0.14, remove the use of Celluloid's thread
  pool.  This should halve the number of threads in each Sidekiq
  process, thus requiring less resources. [#919]
- Abstract Celluloid usage to Sidekiq::Actor for testing purposes.
- Better handling for Redis downtime when fetching jobs and shutting
  down, don't print exceptions every second and print success message
  when Redis is back.
- Fix unclean shutdown leading to duplicate jobs [#897]
- Add Korean locale [#890]
- Upgrade test suite to Minitest 5
- Remove usage of `multi_json` as `json` is now robust on all platforms.

2.11.2
-----------

- Fix Web UI when used without Rails [#886]
- Add Sidekiq::Stats#reset [#349]
- Add Norwegian locale.
- Updates for the JA locale.

2.11.1
-----------

- Fix timeout warning.
- Add Dutch web UI locale.

2.11.0
-----------

- Upgrade to Celluloid 0.13. [#834]
- Remove **timeout** support from `sidekiq_options`.  Ruby's timeout
  is inherently unsafe in a multi-threaded application and was causing
  stability problems for many.  See http://bit.ly/OtYpK
- Add Japanese locale for Web UI [#868]
- Fix a few issues with Web UI i18n.

2.10.1
-----------

- Remove need for the i18n gem. (brandonhilkert)
- Improve redis connection info logging on startup for debugging
purposes [#858]
- Revert sinatra/slim as runtime dependencies
- Add `find_job` method to sidekiq/api


2.10.0
-----------

- Refactor algorithm for putting scheduled jobs onto the queue [#843]
- Fix scheduler thread dying due to incorrect error handling [#839]
- Fix issue which left stale workers if Sidekiq wasn't shutdown while
quiet. [#840]
- I18n for web UI.  Please submit translations of `web/locales/en.yml` for
your own language. [#811]
- 'sinatra', 'slim' and 'i18n' are now gem dependencies for Sidekiq.


2.9.0
-----------

- Update 'sidekiq/testing' to work with any Sidekiq::Client call. It
  also serializes the arguments as using Redis would. [#713]
- Raise a Sidekiq::Shutdown error within workers which don't finish within the hard
  timeout.  This is to prevent unwanted database transaction commits. [#377]
- Lazy load Redis connection pool, you no longer need to specify
  anything in Passenger or Unicorn's after_fork callback [#794]
- Add optional Worker#retries_exhausted hook after max retries failed. [jkassemi, #780]
- Fix bug in pagination link to last page [pitr, #774]
- Upstart scripts for multiple Sidekiq instances [dariocravero, #763]
- Use select via pipes instead of poll to catch signals [mrnugget, #761]

2.8.0
-----------

- I18n support!  Sidekiq can optionally save and restore the Rails locale
  so it will be properly set when your jobs execute.  Just include
  `require 'sidekiq/middleware/i18n'` in your sidekiq initializer. [#750]
- Fix bug which could lose messages when using namespaces and the message
needs to be requeued in Redis. [#744]
- Refactor Redis namespace support [#747].  The redis namespace can no longer be
  passed via the config file, the only supported way is via Ruby in your
  initializer:

```ruby
sidekiq_redis = { :url => 'redis://localhost:3679', :namespace => 'foo' }
Sidekiq.configure_server { |config| config.redis = sidekiq_redis }
Sidekiq.configure_client { |config| config.redis = sidekiq_redis }
```

A warning is printed out to the log if a namespace is found in your sidekiq.yml.


2.7.5
-----------

- Capistrano no longer uses daemonization in order to work with JRuby [#719]
- Refactor signal handling to work on Ruby 2.0 [#728, #730]
- Fix dashboard refresh URL [#732]

2.7.4
-----------

- Fixed daemonization, was broken by some internal refactoring in 2.7.3 [#727]

2.7.3
-----------

- Real-time dashboard is now the default web page
- Make config file optional for capistrano
- Fix Retry All button in the Web UI

2.7.2
-----------

- Remove gem signing infrastructure.  It was causing Sidekiq to break
when used via git in Bundler.  This is why we can't have nice things. [#688]


2.7.1
-----------

- Fix issue with hard shutdown [#680]


2.7.0
-----------

- Add -d daemonize flag, capistrano recipe has been updated to use it [#662]
- Support profiling via `ruby-prof` with -p.  When Sidekiq is stopped
  via Ctrl-C, it will output `profile.html`.  You must add `gem 'ruby-prof'` to your Gemfile for it to work.
- Dynamically update Redis stats on dashboard [brandonhilkert]
- Add Sidekiq::Workers API giving programmatic access to the current
  set of active workers.

```
workers = Sidekiq::Workers.new
workers.size => 2
workers.each do |name, work|
  # name is a unique identifier per Processor instance
  # work is a Hash which looks like:
  # { 'queue' => name, 'run_at' => timestamp, 'payload' => msg }
end
```

- Allow environment-specific sections within the config file which
override the global values [dtaniwaki, #630]

```
---
:concurrency:  50
:verbose:      false
staging:
  :verbose:      true
  :concurrency:  5
```


2.6.5
-----------

- Several reliability fixes for job requeueing upon termination [apinstein, #622, #624]
- Fix typo in capistrano recipe
- Add `retry_queue` option so retries can be given lower priority [ryanlower, #620]

```ruby
sidekiq_options queue: 'high', retry_queue: 'low'
```

2.6.4
-----------

- Fix crash upon empty queue [#612]

2.6.3
-----------

- sidekiqctl exits with non-zero exit code upon error [jmazzi]
- better argument validation in Sidekiq::Client [karlfreeman]

2.6.2
-----------

- Add Dashboard beacon indicating when stats are updated. [brandonhilkert, #606]
- Revert issue with capistrano restart. [#598]

2.6.1
-----------

- Dashboard now live updates summary stats also. [brandonhilkert, #605]
- Add middleware chain APIs `insert_before` and `insert_after` for fine
  tuning the order of middleware. [jackrg, #595]

2.6.0
-----------

- Web UI much more mobile friendly now [brandonhilkert, #573]
- Enable live polling for every section in Web UI [brandonhilkert, #567]
- Add Stats API [brandonhilkert, #565]
- Add Stats::History API [brandonhilkert, #570]
- Add Dashboard to Web UI with live and historical stat graphs [brandonhilkert, #580]
- Add option to log output to a file, reopen log file on USR2 signal [mrnugget, #581]

2.5.4
-----------

- `Sidekiq::Client.push` now accepts the worker class as a string so the
  Sidekiq client does not have to load your worker classes at all.  [#524]
- `Sidekiq::Client.push_bulk` now works with inline testing.
- **Really** fix status icon in Web UI this time.
- Add "Delete All" and "Retry All" buttons to Retries in Web UI


2.5.3
-----------

- Small Web UI fixes
- Add `delay_until` so you can delay jobs until a specific timestamp:

```ruby
Auction.delay_until(@auction.ends_at).close(@auction.id)
```

This is identical to the existing Sidekiq::Worker method, `perform_at`.

2.5.2
-----------

- Remove asset pipeline from Web UI for much faster, simpler runtime.  [#499, #490, #481]
- Add -g option so the procline better identifies a Sidekiq process, defaults to File.basename(Rails.root). [#486]

    sidekiq 2.5.1 myapp [0 of 25 busy]

- Add splay to retry time so groups of failed jobs don't fire all at once. [#483]

2.5.1
-----------

- Fix issues with core\_ext

2.5.0
-----------

- REDESIGNED WEB UI! [unity, cavneb]
- Support Honeybadger for error delivery
- Inline testing runs the client middleware before executing jobs [#465]
- Web UI can now remove jobs from queue. [#466, dleung]
- Web UI can now show the full message, not just 100 chars [#464, dleung]
- Add APIs for manipulating the retry and job queues.  See sidekiq/api. [#457]


2.4.0
-----------

- ActionMailer.delay.method now only tries to deliver if method returns a valid message.
- Logging now uses "MSG-#{Job ID}", not a random msg ID
- Allow generic Redis provider as environment variable. [#443]
- Add ability to customize sidekiq\_options with delay calls [#450]

```ruby
Foo.delay(:retry => false).bar
Foo.delay(:retry => 10).bar
Foo.delay(:timeout => 10.seconds).bar
Foo.delay_for(5.minutes, :timeout => 10.seconds).bar
```

2.3.3
-----------

- Remove option to disable Rails hooks. [#401]
- Allow delay of any module class method

2.3.2
-----------

- Fix retry.  2.3.1 accidentally disabled it.

2.3.1
-----------

- Add Sidekiq::Client.push\_bulk for bulk adding of jobs to Redis.
  My own simple test case shows pushing 10,000 jobs goes from 5 sec to 1.5 sec.
- Add support for multiple processes per host to Capistrano recipe
- Re-enable Celluloid::Actor#defer to fix stack overflow issues [#398]

2.3.0
-----------

- Upgrade Celluloid to 0.12
- Upgrade Twitter Bootstrap to 2.1.0
- Rescue more Exceptions
- Change Job ID to be Hex, rather than Base64, for HTTP safety
- Use `Airbrake#notify_or_ignore`

2.2.1
-----------

- Add support for custom tabs to Sidekiq::Web [#346]
- Change capistrano recipe to run 'quiet' before deploy:update\_code so
  it is run upon both 'deploy' and 'deploy:migrations'. [#352]
- Rescue Exception rather than StandardError to catch and log any sort
  of Processor death.

2.2.0
-----------

- Roll back Celluloid optimizations in 2.1.0 which caused instability.
- Add extension to delay any arbitrary class method to Sidekiq.
  Previously this was limited to ActiveRecord classes.

```ruby
SomeClass.delay.class_method(1, 'mike', Date.today)
```

- Sidekiq::Client now generates and returns a random, 128-bit Job ID 'jid' which
  can be used to track the processing of a Job, e.g. for calling back to a webhook
  when a job is finished.

2.1.1
-----------

- Handle networking errors causing the scheduler thread to die [#309]
- Rework exception handling to log all Processor and actor death (#325, subelsky)
- Clone arguments when calling worker so modifications are discarded. (#265, hakanensari)

2.1.0
-----------

- Tune Celluloid to no longer run message processing within a Fiber.
  This gives us a full Thread stack and also lowers Sidekiq's memory
  usage.
- Add pagination within the Web UI [#253]
- Specify which Redis driver to use: *hiredis* or *ruby* (default)
- Remove FailureJobs and UniqueJobs, which were optional middleware
  that I don't want to support in core. [#302]

2.0.3
-----------
- Fix sidekiq-web's navbar on mobile devices and windows under 980px (ezkl)
- Fix Capistrano task for first deploys [#259]
- Worker subclasses now properly inherit sidekiq\_options set in
  their superclass [#221]
- Add random jitter to scheduler to spread polls across POLL\_INTERVAL
  window. [#247]
- Sidekiq has a new mailing list: sidekiq@librelist.org  See README.

2.0.2
-----------

- Fix "Retry Now" button on individual retry page. (ezkl)

2.0.1
-----------

- Add "Clear Workers" button to UI.  If you kill -9 Sidekiq, the workers
  set can fill up with stale entries.
- Update sidekiq/testing to support new scheduled jobs API:

   ```ruby
   require 'sidekiq/testing'
   DirectWorker.perform_in(10.seconds, 1, 2)
   assert_equal 1, DirectWorker.jobs.size
   assert_in_delta 10.seconds.from_now.to_f, DirectWorker.jobs.last['at'], 0.01
   ```

2.0.0
-----------

- **SCHEDULED JOBS**!

You can now use `perform_at` and `perform_in` to schedule jobs
to run at arbitrary points in the future, like so:

```ruby
  SomeWorker.perform_in(5.days, 'bob', 13)
  SomeWorker.perform_at(5.days.from_now, 'bob', 13)
```

It also works with the delay extensions:

```ruby
  UserMailer.delay_for(5.days).send_welcome_email(user.id)
```

The time is approximately when the job will be placed on the queue;
it is not guaranteed to run at precisely at that moment in time.

This functionality is meant for one-off, arbitrary jobs.  I still
recommend `whenever` or `clockwork` if you want cron-like,
recurring jobs.  See `examples/scheduling.rb`

I want to specially thank @yabawock for his work on sidekiq-scheduler.
His extension for Sidekiq 1.x filled an obvious functional gap that I now think is
useful enough to implement in Sidekiq proper.

- Fixed issues due to Redis 3.x API changes.  Sidekiq now requires
  the Redis 3.x client.
- Inline testing now round trips arguments through JSON to catch
  serialization issues (betelgeuse)

1.2.1
-----------

- Sidekiq::Worker now has access to Sidekiq's standard logger
- Fix issue with non-StandardErrors leading to Processor exhaustion
- Fix issue with Fetcher slowing Sidekiq shutdown
- Print backtraces for all threads upon TTIN signal [#183]
- Overhaul retries Web UI with new index page and bulk operations [#184]

1.2.0
-----------

- Full or partial error backtraces can optionally be stored as part of the retry
  for display in the web UI if you aren't using an error service. [#155]

```ruby
class Worker
  include Sidekiq::Worker
  sidekiq_options :backtrace => [true || 10]
end
```
- Add timeout option to kill a worker after N seconds (blackgold9)

```ruby
class HangingWorker
  include Sidekiq::Worker
  sidekiq_options :timeout => 600
  def perform
    # will be killed if it takes longer than 10 minutes
  end
end
```

- Fix delayed extensions not available in workers [#152]
- In test environments add the `#drain` class method to workers. This method
  executes all previously queued jobs. (panthomakos)
- Sidekiq workers can be run inline during tests, just `require 'sidekiq/testing/inline'` (panthomakos)
- Queues can now be deleted from the Sidekiq web UI [#154]
- Fix unnecessary shutdown delay due to Retry Poller [#174]

1.1.4
-----------

- Add 24 hr expiry for basic keys set in Redis, to avoid any possible leaking.
- Only register workers in Redis while working, to avoid lingering
  workers [#156]
- Speed up shutdown significantly.

1.1.3
-----------

- Better network error handling when fetching jobs from Redis.
  Sidekiq will retry once per second until it can re-establish
  a connection. (ryanlecompte)
- capistrano recipe now uses `bundle_cmd` if set [#147]
- handle multi\_json API changes (sferik)

1.1.2
-----------

- Fix double restart with cap deploy [#137]

1.1.1
-----------

- Set procline for easy monitoring of Sidekiq status via "ps aux"
- Fix race condition on shutdown [#134]
- Fix hang with cap sidekiq:start [#131]

1.1.0
-----------

- The Sidekiq license has switched from GPLv3 to LGPLv3!
- Sidekiq::Client.push now returns whether the actual Redis
  operation succeeded or not. [#123]
- Remove UniqueJobs from the default middleware chain.  Its
  functionality, while useful, is unexpected for new Sidekiq
  users.  You can re-enable it with the following config.
  Read #119 for more discussion.

```ruby
Sidekiq.configure_client do |config|
  require 'sidekiq/middleware/client/unique_jobs'
  config.client_middleware do |chain|
    chain.add Sidekiq::Middleware::Client::UniqueJobs
  end
end
Sidekiq.configure_server do |config|
  require 'sidekiq/middleware/server/unique_jobs'
  config.server_middleware do |chain|
    chain.add Sidekiq::Middleware::Server::UniqueJobs
  end
end
```

1.0.0
-----------

Thanks to all Sidekiq users and contributors for helping me
get to this big milestone!

- Default concurrency on client-side to 5, not 25 so we don't
  create as many unused Redis connections, same as ActiveRecord's
  default pool size.
- Ensure redis= is given a Hash or ConnectionPool.

0.11.2
-----------

- Implement "safe shutdown".  The messages for any workers that
  are still busy when we hit the TERM timeout will be requeued in
  Redis so the messages are not lost when the Sidekiq process exits.
  [#110]
- Work around Celluloid's small 4kb stack limit [#115]
- Add support for a custom Capistrano role to limit Sidekiq to
  a set of machines. [#113]

0.11.1
-----------

- Fix fetch breaking retry when used with Redis namespaces. [#109]
- Redis connection now just a plain ConnectionPool, not CP::Wrapper.
- Capistrano initial deploy fix [#106]
- Re-implemented weighted queues support (ryanlecompte)

0.11.0
-----------

- Client-side API changes, added sidekiq\_options for Sidekiq::Worker.
  As a side effect of this change, the client API works on Ruby 1.8.
  It's not officially supported but should work [#103]
- NO POLL!  Sidekiq no longer polls Redis, leading to lower network
  utilization and lower latency for message processing.
- Add --version CLI option

0.10.1
-----------

- Add details page for jobs in retry queue (jcoene)
- Display relative timestamps in web interface (jcoene)
- Capistrano fixes (hinrik, bensie)

0.10.0
-----------

- Reworked capistrano recipe to make it more fault-tolerant [#94].
- Automatic failure retry!  Sidekiq will now save failed messages
  and retry them, with an exponential backoff, over about 20 days.
  Did a message fail to process?  Just deploy a bug fix in the next
  few days and Sidekiq will retry the message eventually.

0.9.1
-----------

- Fix missed deprecations, poor method name in web UI

0.9.0
-----------

- Add -t option to configure the TERM shutdown timeout
- TERM shutdown timeout is now configurable, defaults to 5 seconds.
- USR1 signal now stops Sidekiq from accepting new work,
  capistrano sends USR1 at start of deploy and TERM at end of deploy
  giving workers the maximum amount of time to finish.
- New Sidekiq::Web rack application available
- Updated Sidekiq.redis API

0.8.0
-----------

- Remove :namespace and :server CLI options (mperham)
- Add ExceptionNotifier support (masterkain)
- Add capistrano support (mperham)
- Workers now log upon start and finish (mperham)
- Messages for terminated workers are now automatically requeued (mperham)
- Add support for Exceptional error reporting (bensie)

0.7.0
-----------

- Example chef recipe and monitrc script (jc00ke)
- Refactor global configuration into Sidekiq.configure\_server and
  Sidekiq.configure\_client blocks. (mperham)
- Add optional middleware FailureJobs which saves failed jobs to a
  'failed' queue (fbjork)
- Upon shutdown, workers are now terminated after 5 seconds.  This is to
  meet Heroku's hard limit of 10 seconds for a process to shutdown. (mperham)
- Refactor middleware API for simplicity, see sidekiq/middleware/chain. (mperham)
- Add `delay` extensions for ActionMailer and ActiveRecord. (mperham)
- Added config file support. See test/config.yml for an example file.  (jc00ke)
- Added pidfile for tools like monit (jc00ke)

0.6.0
-----------

- Resque-compatible processing stats in redis (mperham)
- Simple client testing support in sidekiq/testing (mperham)
- Plain old Ruby support via the -r cli flag (mperham)
- Refactored middleware support, introducing ability to add client-side middleware (ryanlecompte)
- Added middleware for ignoring duplicate jobs (ryanlecompte)
- Added middleware for displaying jobs in resque-web dashboard (maxjustus)
- Added redis namespacing support (maxjustus)

0.5.1
-----------

- Initial release!
