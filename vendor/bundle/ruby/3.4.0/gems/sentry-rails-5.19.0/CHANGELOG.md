# Changelog

Individual gem's changelog has been deprecated. Please check the [project changelog](https://github.com/getsentry/sentry-ruby/blob/master/CHANGELOG.md).

## 4.4.0

### Features

- Make tracing subscribers configurable [#1344](https://github.com/getsentry/sentry-ruby/pull/1344) 

```ruby
# current default:
# - Sentry::Rails::Tracing::ActionControllerSubscriber
# - Sentry::Rails::Tracing::ActionViewSubscriber
# - Sentry::Rails::Tracing::ActiveRecordSubscriber

# you can add a new subscriber
config.rails.tracing_subscribers << MySubscriber
# or replace the set completely
config.rails.tracing_subscribers = [MySubscriber]
```

### Bug Fixes

- Report exceptions from the interceptor middleware for exceptions app [#1379](https://github.com/getsentry/sentry-ruby/pull/1379)
  - Fixes [#1371](https://github.com/getsentry/sentry-ruby/issues/1371)
- Re-position CaptureExceptions middleware to reduce tracing noise [#1405](https://github.com/getsentry/sentry-ruby/pull/1405) 

## 4.3.4

- Don't assign Rails.logger if it's not present [#1387](https://github.com/getsentry/sentry-ruby/pull/1387)
  - Fixes [#1386](https://github.com/getsentry/sentry-ruby/issues/1386)

## 4.3.3

- Correctly set the SDK's logger in sentry-rails [#1363](https://github.com/getsentry/sentry-ruby/pull/1363)
  - Fixes [#1361](https://github.com/getsentry/sentry-ruby/issues/1361)

## 4.3.3-beta.0

- Minimize sentry-rails' dependency requirement [#1352](https://github.com/getsentry/sentry-ruby/pull/1352)

## 4.3.2

- Avoid recording SendEventJob's transaction [#1351](https://github.com/getsentry/sentry-ruby/pull/1351)
  - Fixes [#1348](https://github.com/getsentry/sentry-ruby/issues/1348)

## 4.3.1

- Only apply background worker patch if ActiveRecord is loaded [#1350](https://github.com/getsentry/sentry-ruby/pull/1350)
  - Fixes [#1342](https://github.com/getsentry/sentry-ruby/issues/1342) and [#1346](https://github.com/getsentry/sentry-ruby/issues/1346)

## 4.3.0

### Features

- Support performance monitoring on ActiveJob execution [#1304](https://github.com/getsentry/sentry-ruby/pull/1304)

### Bug Fixes

- Prevent background workers from holding ActiveRecord connections [#1320](https://github.com/getsentry/sentry-ruby/pull/1320)

## 4.2.2

- Always define Sentry::SendEventJob to avoid eager load issues [#1286](https://github.com/getsentry/sentry-ruby/pull/1286)
  - Fixes [#1283](https://github.com/getsentry/sentry-ruby/issues/1283)

## 4.2.1

- Add additional checks to SendEventJob's definition [#1275](https://github.com/getsentry/sentry-ruby/pull/1275)
  - Fixes [#1270](https://github.com/getsentry/sentry-ruby/issues/1270)
  - Fixes [#1277](https://github.com/getsentry/sentry-ruby/issues/1277)

## 4.2.0

### Features

- Make sentry-rails a Rails engine and provide default job class for async [#1181](https://github.com/getsentry/sentry-ruby/pull/1181)

`sentry-rails` now provides a default ActiveJob class for sending events asynchronously. You can use it directly without define your own one:

```ruby
config.async = lambda { |event, hint| Sentry::SendEventJob.perform_later(event, hint) }
```

- Add configuration option for trusted proxies [#1126](https://github.com/getsentry/sentry-ruby/pull/1126)

`sentry-rails` now injects `Rails.application.config.action_dispatch.trusted_proxies` into `Sentry.configuration.trusted_proxies` automatically.

- Allow users to configure ActiveJob adapters to ignore [#1256](https://github.com/getsentry/sentry-ruby/pull/1256)

```ruby
# sentry-rails will skip active_job reporting for jobs that use ActiveJob::QueueAdapters::SidekiqAdapter
# you should use this option when:
# - you don't want to see events from a certain adapter
# - you already have a better reporting setup for the adapter (like having `sentry-sidekiq` installed)
config.rails.skippable_job_adapters = ["ActiveJob::QueueAdapters::SidekiqAdapter"]
```

- Tag `job_id` and `provider_job_id` on ActiveJob events [#1259](https://github.com/getsentry/sentry-ruby/pull/1259)

<img width="1330" alt="example of tagged event" src="https://user-images.githubusercontent.com/5079556/106389781-3a03f100-6420-11eb-810c-a99869eb26dd.png">

- Use another method for post initialization callback [#1261](https://github.com/getsentry/sentry-ruby/pull/1261)

### Bug Fixes

- Inspect exception cause by default & don't exclude ActiveJob::DeserializationError [#1180](https://github.com/getsentry/sentry-ruby/pull/1180)
  - Fixes [#1071](https://github.com/getsentry/sentry-ruby/issues/1071)

## 4.1.7

- Use env to carry original transaction name [#1255](https://github.com/getsentry/sentry-ruby/pull/1255)
- Fix duration of tracing event in Rails 5 [#1254](https://github.com/getsentry/sentry-ruby/pull/1254) (by @abcang)
- Filter out static file transaction [#1247](https://github.com/getsentry/sentry-ruby/pull/1247)

## 4.1.6

- Prevent exceptions app from overriding event's transaction name [#1230](https://github.com/getsentry/sentry-ruby/pull/1230)
- Fix project root detection [#1242](https://github.com/getsentry/sentry-ruby/pull/1242)
- Use sentry-ruby-core as the main SDK dependency [#1244](https://github.com/getsentry/sentry-ruby/pull/1244)

## 4.1.5

- Add `ActionDispatch::Http::MimeNegotiation::InvalidType` to the list of default ignored Rails exceptions [#1215](https://github.com/getsentry/sentry-ruby/pull/1215) (by @agrobbin)
- Continue ActiveJob execution if Sentry is not initialized [#1217](https://github.com/getsentry/sentry-ruby/pull/1217)
  - Fixes [#1211](https://github.com/getsentry/sentry-ruby/issues/1211) and [#1216](https://github.com/getsentry/sentry-ruby/issues/1216)
- Only extend ActiveJob when it's defined [#1218](https://github.com/getsentry/sentry-ruby/pull/1218)
  - Fixes [#1210](https://github.com/getsentry/sentry-ruby/issues/1210)
- Filter out redundant event/payload from breadcrumbs logger [#1222](https://github.com/getsentry/sentry-ruby/pull/1222)
- Copy request env before Rails' ShowExceptions middleware [#1223](https://github.com/getsentry/sentry-ruby/pull/1223)
- Don't subscribe render_partial and render_collection events [#1224](https://github.com/getsentry/sentry-ruby/pull/1224)

## 4.1.4

- Don't include headers & request info in tracing span or breadcrumb [#1199](https://github.com/getsentry/sentry-ruby/pull/1199)
- Don't run RescuedExceptionInterceptor unless Sentry is initialized [#1204](https://github.com/getsentry/sentry-ruby/pull/1204)

## 4.1.3

- Remove DelayedJobAdapter from ignored list [#1179](https://github.com/getsentry/sentry-ruby/pull/1179)

## 4.1.2

- Use middleware instead of method override to handle rescued exceptions [#1168](https://github.com/getsentry/sentry-ruby/pull/1168)
  - Fixes [#738](https://github.com/getsentry/sentry-ruby/issues/738)
- Adopt Integrable module [#1177](https://github.com/getsentry/sentry-ruby/pull/1177)

## 4.1.1

- Use stricter dependency declaration [#1159](https://github.com/getsentry/sentry-ruby/pull/1159)

## 4.1.0

- Merge & rename 2 Rack middlewares [#1147](https://github.com/getsentry/sentry-ruby/pull/1147)
  - Fixes [#1153](https://github.com/getsentry/sentry-ruby/pull/1153)
  - Removed `Sentry::Rack::Tracing` middleware and renamed `Sentry::Rack::CaptureException` to `Sentry::Rack::CaptureExceptions`
- Tidy up rails integration [#1150](https://github.com/getsentry/sentry-ruby/pull/1150)
- Check SDK initialization before running integrations [#1151](https://github.com/getsentry/sentry-ruby/pull/1151)
  - Fixes [#1145](https://github.com/getsentry/sentry-ruby/pull/1145)

## 4.0.0

- Only documents update for the official release and no API/feature changes.

## 0.3.0

- Major API changes: [1123](https://github.com/getsentry/sentry-ruby/pull/1123)

## 0.2.0

- Multiple fixes and refactorings
- Tracing support

## 0.1.2

Fix require reference

## 0.1.1

Release test

## 0.1.0

First version
