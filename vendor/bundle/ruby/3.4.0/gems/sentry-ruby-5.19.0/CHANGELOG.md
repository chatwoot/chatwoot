# Changelog

Individual gem's changelog has been deprecated. Please check the [project changelog](https://github.com/getsentry/sentry-ruby/blob/master/CHANGELOG.md).

## 4.4.2

- Fix NoMethodError when SDK's dsn is nil [#1433](https://github.com/getsentry/sentry-ruby/pull/1433)
- fix: Update protocol version to 7 [#1434](https://github.com/getsentry/sentry-ruby/pull/1434)
  - Fixes [#867](https://github.com/getsentry/sentry-ruby/issues/867)

## 4.4.1

- Apply patches when initializing the SDK [#1432](https://github.com/getsentry/sentry-ruby/pull/1432)

## 4.4.0

### Features

#### Support category-based rate limiting [#1336](https://github.com/getsentry/sentry-ruby/pull/1336) 

Sentry rate limits different types of events. And when rate limiting is enabled, it sends back a `429` response to the SDK. Currently, the SDK would then raise an error like this:

```
Unable to record event with remote Sentry server (Sentry::Error - the server responded with status 429
body: {"detail":"event rejected due to rate limit"}):
```

This change improves the SDK's handling on such responses by:

- Not treating them as errors, so you don't see the noise anymore.
- Halting event sending for a while according to the duration provided in the response. And warns you with a message like:

```
Envelope [event] not sent: Excluded by random sample
```

#### Record request span from Net::HTTP library [#1381](https://github.com/getsentry/sentry-ruby/pull/1381)

Now any outgoing requests will be recorded as a tracing span. Example:

<img width="60%" alt="net:http span example" src="https://user-images.githubusercontent.com/5079556/115838944-c1279a80-a44c-11eb-8c67-dfd92bf68bbd.png">


#### Record breadcrumb for Net::HTTP requests [#1394](https://github.com/getsentry/sentry-ruby/pull/1394)

With the new `http_logger` breadcrumbs logger:

```ruby
config.breadcrumbs_logger = [:http_logger]
```

The SDK now records a new `net.http` breadcrumb whenever the user makes a request with the `Net::HTTP` library.

<img width="60%" alt="net http breadcrumb" src="https://user-images.githubusercontent.com/5079556/114298326-5f7c3d80-9ae8-11eb-9108-222384a7f1a2.png">

#### Support config.debug configuration option [#1400](https://github.com/getsentry/sentry-ruby/pull/1400)

It'll determine whether the SDK should run in the debugging mode. Default is `false`. When set to true, SDK errors will be logged with backtrace.

#### Add the third tracing state [#1402](https://github.com/getsentry/sentry-ruby/pull/1402)
  - `rate == 0` - Tracing enabled. Rejects all locally created transactions but  respects sentry-trace.
  - `1 > rate > 0` - Tracing enabled. Samples locally created transactions  with the rate and respects sentry-trace.
  - `rate < 0` or `rate > 1` - Tracing disabled.

### Refactorings

- Let Transaction constructor take an optional hub argument [#1384](https://github.com/getsentry/sentry-ruby/pull/1384)
- Introduce LoggingHelper [#1385](https://github.com/getsentry/sentry-ruby/pull/1385)
- Raise exception if a Transaction is initialized without a hub [#1391](https://github.com/getsentry/sentry-ruby/pull/1391)
- Make hub a required argument for Transaction constructor [#1401](https://github.com/getsentry/sentry-ruby/pull/1401) 

### Bug Fixes

- Check `Scope#set_context`'s value argument [#1415](https://github.com/getsentry/sentry-ruby/pull/1415)
- Disable tracing if events are not allowed to be sent [#1421](https://github.com/getsentry/sentry-ruby/pull/1421)

## 4.3.2

- Correct type attribute's usages [#1354](https://github.com/getsentry/sentry-ruby/pull/1354)
- Fix sampling decision precedence [#1335](https://github.com/getsentry/sentry-ruby/pull/1335)
- Fix set_contexts [#1375](https://github.com/getsentry/sentry-ruby/pull/1375) 
- Use thread variable instead of fiber variable to store the hub [#1380](https://github.com/getsentry/sentry-ruby/pull/1380)
  - Fixes [#1374](https://github.com/getsentry/sentry-ruby/issues/1374)
- Fix Span/Transaction's nesting issue [#1382](https://github.com/getsentry/sentry-ruby/pull/1382) 
  - Fixes [#1372](https://github.com/getsentry/sentry-ruby/issues/1372)

## 4.3.1

- Add Sentry.set_context helper [#1337](https://github.com/getsentry/sentry-ruby/pull/1337)
- Fix handle the case where the logger messages is not of String type [#1341](https://github.com/getsentry/sentry-ruby/pull/1341)
- Don't report Sentry::ExternalError to Sentry [#1353](https://github.com/getsentry/sentry-ruby/pull/1353)
- Sentry.add_breadcrumb should call Hub#add_breadcrumb [#1358](https://github.com/getsentry/sentry-ruby/pull/1358)
  - Fixes [#1357](https://github.com/getsentry/sentry-ruby/issues/1357)

## 4.3.0

### Features

- Allow configuring BreadcrumbBuffer's size limit [#1310](https://github.com/getsentry/sentry-ruby/pull/1310)

```ruby
# the SDK will only store 10 breadcrumbs (default is 100)
config.max_breadcrumbs = 10
```

- Compress event payload by default [#1314](https://github.com/getsentry/sentry-ruby/pull/1314)

### Refatorings

- Refactor interface construction [#1296](https://github.com/getsentry/sentry-ruby/pull/1296)
- Refactor tracing implementation [#1309](https://github.com/getsentry/sentry-ruby/pull/1309)

### Bug Fixes
- Improve SDK's error handling [#1298](https://github.com/getsentry/sentry-ruby/pull/1298)
  - Fixes [#1246](https://github.com/getsentry/sentry-ruby/issues/1246) and [#1289](https://github.com/getsentry/sentry-ruby/issues/1289)
  - Please read [#1290](https://github.com/getsentry/sentry-ruby/issues/1290) to see the full specification
- Treat query string as pii too [#1302](https://github.com/getsentry/sentry-ruby/pull/1302)
  - Fixes [#1301](https://github.com/getsentry/sentry-ruby/issues/1301)
- Ignore sentry-trace when tracing is not enabled [#1308](https://github.com/getsentry/sentry-ruby/pull/1308)
  - Fixes [#1307](https://github.com/getsentry/sentry-ruby/issues/1307)
- Return nil from logger methods instead of breadcrumb buffer [#1299](https://github.com/getsentry/sentry-ruby/pull/1299)
- Exceptions with nil message shouldn't cause issues [#1327](https://github.com/getsentry/sentry-ruby/pull/1327)
  - Fixes [#1323](https://github.com/getsentry/sentry-ruby/issues/1323)
- Fix sampling decision with sentry-trace and add more tests [#1326](https://github.com/getsentry/sentry-ruby/pull/1326)

## 4.2.2

- Add thread_id to Exception interface [#1291](https://github.com/getsentry/sentry-ruby/pull/1291)
- always convert trusted proxies to string [#1288](https://github.com/getsentry/sentry-ruby/pull/1288)
  - fixes [#1274](https://github.com/getsentry/sentry-ruby/issues/1274)

## 4.2.1

### Bug Fixes

- Ignore invalid values for sentry-trace header that don't match the required format [#1265](https://github.com/getsentry/sentry-ruby/pull/1265)
- Transaction created by `.from_sentry_trace` should inherit sampling decision [#1269](https://github.com/getsentry/sentry-ruby/pull/1269)
- Transaction's sample rate should accept any numeric value [#1278](https://github.com/getsentry/sentry-ruby/pull/1278)

## 4.2.0

### Features

- Add configuration option for trusted proxies [#1126](https://github.com/getsentry/sentry-ruby/pull/1126)

```ruby
config.trusted_proxies = ["2.2.2.2"] # this ip address will be skipped when computing users' ip addresses
```

- Add ThreadsInterface [#1178](https://github.com/getsentry/sentry-ruby/pull/1178)

<img width="1029" alt="an exception event that has the new threads interface" src="https://user-images.githubusercontent.com/5079556/103459223-98b64c00-4d48-11eb-9ebb-ee58f15e647e.png">

- Support `config.before_breadcrumb` [#1253](https://github.com/getsentry/sentry-ruby/pull/1253)

```ruby
# this will be called before every breadcrumb is added to the breadcrumb buffer
# you can use it to
# - remove the data you don't want to send
# - add additional info to the data
config.before_breadcrumb = lambda do |breadcrumb, hint|
  breadcrumb.message = "foo"
  breadcrumb
end
```

- Add ability to have many post initialization callbacks [#1261](https://github.com/getsentry/sentry-ruby/pull/1261)

### Bug Fixes

- Inspect exception cause by default & don't exclude ActiveJob::DeserializationError [#1180](https://github.com/getsentry/sentry-ruby/pull/1180)
  - Fixes [#1071](https://github.com/getsentry/sentry-ruby/issues/1071)

## 4.1.6

- Don't detect project root for Rails apps [#1243](https://github.com/getsentry/sentry-ruby/pull/1243)
- Separate individual breadcrumb's data serialization [#1250](https://github.com/getsentry/sentry-ruby/pull/1250)
- Capture sentry-trace with the correct http header key [#1260](https://github.com/getsentry/sentry-ruby/pull/1260)

## 4.1.5

- Serialize event hint before passing it to the async block [#1231](https://github.com/getsentry/sentry-ruby/pull/1231)
  - Fixes [#1227](https://github.com/getsentry/sentry-ruby/issues/1227)
- Require the English library [#1233](https://github.com/getsentry/sentry-ruby/pull/1233) (by @dentarg)
- Allow `Sentry.init` without block argument [#1235](https://github.com/getsentry/sentry-ruby/pull/1235) (by @sue445)

## 4.1.5-beta.1

- No change

## 4.1.5-beta.0

- Inline global method [#1213](https://github.com/getsentry/sentry-ruby/pull/1213) (by @tricknotes)
- Event message and exception message should have a size limit [#1221](https://github.com/getsentry/sentry-ruby/pull/1221)
- Add sentry-ruby-core as a more flexible option [#1226](https://github.com/getsentry/sentry-ruby/pull/1226)

## 4.1.4

- Fix headers serialization for sentry-ruby [#1197](https://github.com/getsentry/sentry-ruby/pull/1197) (by @moofkit)
- Support capturing "sentry-trace" header from the middleware [#1205](https://github.com/getsentry/sentry-ruby/pull/1205)
- Document public APIs on the Sentry module [#1208](https://github.com/getsentry/sentry-ruby/pull/1208)
- Check the argument type of capture_exception and capture_event helpers [#1209](https://github.com/getsentry/sentry-ruby/pull/1209)

## 4.1.3

- rm reference to old constant (from Rails v2.2) [#1184](https://github.com/getsentry/sentry-ruby/pull/1184)
- Use copied env in events [#1186](https://github.com/getsentry/sentry-ruby/pull/1186)
  - Fixes [#1183](https://github.com/getsentry/sentry-ruby/issues/1183)
- Refactor RequestInterface [#1187](https://github.com/getsentry/sentry-ruby/pull/1187)
- Supply event hint to async callback when possible [#1189](https://github.com/getsentry/sentry-ruby/pull/1189)
  - Fixes [#1188](https://github.com/getsentry/sentry-ruby/issues/1188)
- Refactor stacktrace parsing and increase test coverage [#1190](https://github.com/getsentry/sentry-ruby/pull/1190)
- Sentry.send_event should also take a hint [#1192](https://github.com/getsentry/sentry-ruby/pull/1192)

## 4.1.2

- before_send callback shouldn't be applied to transaction events [#1167](https://github.com/getsentry/sentry-ruby/pull/1167)
- Transaction improvements [#1170](https://github.com/getsentry/sentry-ruby/pull/1170)
- Support Ruby 3 [#1172](https://github.com/getsentry/sentry-ruby/pull/1172)
- Add Integrable module [#1177](https://github.com/getsentry/sentry-ruby/pull/1177)

## 4.1.1

- Fix NoMethodError when sending is not allowed [#1161](https://github.com/getsentry/sentry-ruby/pull/1161)
- Add notification for users who still use deprecated middlewares [#1160](https://github.com/getsentry/sentry-ruby/pull/1160)
- Improve top-level api safety [#1162](https://github.com/getsentry/sentry-ruby/pull/1162)

## 4.1.0

- Separate rack integration [#1138](https://github.com/getsentry/sentry-ruby/pull/1138)
  - Fixes [#1136](https://github.com/getsentry/sentry-ruby/pull/1136)
- Fix event sampling [#1144](https://github.com/getsentry/sentry-ruby/pull/1144)
- Merge & rename 2 Rack middlewares [#1147](https://github.com/getsentry/sentry-ruby/pull/1147)
  - Fixes [#1153](https://github.com/getsentry/sentry-ruby/pull/1153)
  - Removed `Sentry::Rack::Tracing` middleware and renamed `Sentry::Rack::CaptureException` to `Sentry::Rack::CaptureExceptions`.
- Deep-copy spans [#1148](https://github.com/getsentry/sentry-ruby/pull/1148)
- Move span recorder related code from Span to Transaction [#1149](https://github.com/getsentry/sentry-ruby/pull/1149)
- Check SDK initialization before running integrations [#1151](https://github.com/getsentry/sentry-ruby/pull/1151)
  - Fixes [#1145](https://github.com/getsentry/sentry-ruby/pull/1145)
- Refactor transport [#1154](https://github.com/getsentry/sentry-ruby/pull/1154)
- Implement non-blocking event sending [#1155](https://github.com/getsentry/sentry-ruby/pull/1155)
  - Added `background_worker_threads` configuration option.

### Noticeable Changes

#### Middleware Changes

`Sentry::Rack::Tracing` is now removed. And `Sentry::Rack::CaptureException` has been renamed to `Sentry::Rack::CaptureExceptions`.

#### Events Are Sent Asynchronously

`sentry-ruby` now sends events asynchronously by default. The functionality works like this: 

1. When the SDK is initialized, a `Sentry::BackgroundWorker` will be initialized too.
2. When an event is passed to `Client#capture_event`, instead of sending it directly with `Client#send_event`, we'll let the worker do it.
3. The worker will have a number of threads. And the one of the idle threads will pick the job and call `Client#send_event`.
    - If all the threads are busy, new jobs will be put into a queue, which has a limit of 30.
    - If the queue size is exceeded, new events will be dropped.

However, if you still prefer to use your own async approach, that's totally fine. If you have `config.async` set, the worker won't initialize a thread pool and won't be used either.

This functionality also introduces a new `background_worker_threads` config option. It allows you to decide how many threads should the worker hold. By default, the value will be the number of the processors your machine has. For example, if your machine has 4 processors, the value would be 4.

Of course, you can always override the value to fit your use cases, like

```ruby
config.background_worker_threads = 5 # the worker will have 5 threads for sending events
```

You can also disable this new non-blocking behaviour by giving a `0` value:

```ruby
config.background_worker_threads = 0 # all events will be sent synchronously
```

## 4.0.1

- Add rake integration: [1137](https://github.com/getsentry/sentry-ruby/pull/1137)
- Make Event's interfaces accessible: [1135](https://github.com/getsentry/sentry-ruby/pull/1135)
- ActiveSupportLogger should only record events that has a started time: [1132](https://github.com/getsentry/sentry-ruby/pull/1132)

## 4.0.0

- Only documents update for the official release and no API/feature changes.

## 0.3.0

- Major API changes: [1123](https://github.com/getsentry/sentry-ruby/pull/1123)
- Support event hint: [1122](https://github.com/getsentry/sentry-ruby/pull/1122)
- Add request-id tag to events: [1120](https://github.com/getsentry/sentry-ruby/pull/1120) (by @tvec)

## 0.2.0

- Multiple fixes and refactorings
- Tracing support

## 0.1.3

Fix require reference

## 0.1.2

- Fix: Fix async callback [1098](https://github.com/getsentry/sentry-ruby/pull/1098)
- Refactor: Some code cleanup [1100](https://github.com/getsentry/sentry-ruby/pull/1100)
- Refactor: Remove Event options [1101](https://github.com/getsentry/sentry-ruby/pull/1101)

## 0.1.1

- Feature: Allow passing custom scope to Hub#capture* helpers [1086](https://github.com/getsentry/sentry-ruby/pull/1086)

## 0.1.0

First version
