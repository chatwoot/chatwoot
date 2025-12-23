# Changelog

## [Unreleased]

## [2.19.0] - 2025-07-24

### Added

* AppSec: Added Business Logic Events SDK v2. ([#4802][])
* Tracing: Add `record_exception` API to capture and attach error information to spans via span events. ([#4771][])
* Tracing: Add `:cache_store` option to ActiveSupport integration to allow tracing only specified cache backends. ([#4693][])
* SSI: Rework SSI from the ground up. ([#4366][])

### Changed

* Profiling: Switch profiler stack truncation strategy and improve sampling performance ([#4819][])
* Profiling: Report GC tuning environment variables with profiles ([#4813][])
* Profiling: Tag profiles with sequence number ([#4794][])
* Profiling: Enable sample from inside signal handler by default on modern Rubies ([#4786][], [#4785][])

### Fixed

* Core: Fix emitting duplicate warnings on agent configuration mismatch ([#4814][])
* Appsec: Fix an error in AppSec route extractor for not-found routes in Rails 8 ([#4793][])
* Profiling: Add workaround for Ruby VM bug ([#4787][])
* Profiling: Fix checking for dladdr in profiling ([#4783][])
* Profiling: Fix potential profiler compilation issue. ([#4783][])
* Tracing: The mysql integration now only sets the `db.name` tag if there is a valid value ([#4776][])
* Tracing: The Rails Runner instrumentation should now create Rails Runner spans. ([#4681][])
* Tracing: Fix sampling rules and sample rate reporting in environment logger. ([#4772][])

### Removed

## [2.18.0] - 2025-07-03

### Added

* AppSec: Add API Security with new sampling algorithm to the Rack, Rails, Sinatra and Grape frameworks ([#4699][])
* Core: Add support for tracer configuration through Fleet Automation ([#4651][])
* Tracing: Add Rails view render times and database query times to the spans, when available ([#4697][])
* Core: Add Service Discovery capability, enabling the tracer to reliably determine which process are instrumented

### Changed

* AppSec: Enable API Security feature by default ([#4756][])
* AppSec: Improve overall threat detection ([#4757][])
* AppSec: Deprecate `config.appsec.ip_passlist`, `config.appsec.ip_denylist`, and `config.appsec.user_id_denylist` ([#4757][])
* Profiling: Graduate Heap Profiling from alpha to preview ([#4401][], [#4460][])
* Dynamic Instrumentation: Add instance variable capture to method and line probes ([#4668][])
* Profiling: Add capturing of native filenames in backtraces ([#4745][])
* Profiling: Clean up profiler logging ([#4728][])
Tracing: Add support for `DD_RUNTIME_METRICS_RUNTIME_ID_ENABLED` to tag runtime metrics with the current runtime ID, allowing correlation across processes ([#4718][])
* Tracing: Improve performance of `http.route` tag computation for Rails ([#4688][])

### Fixed

* AppSec: Fix authenticated users tracking in anonymization mode for Devise ([#4731][])
* Dynamic Instrumentation: Fix source code display in dynamic instrumentation/live debugger ([#4743][])
* Profiling: Fix profiler stopping due to bug in heap profiling serialization ([#4721][])

## [2.17.0] - 2025-06-02

### Added

* Tracing: Add support for Rails 8.0. ([#4455][])

### Changed

* Core: Improve tracer error reporting when agent responds with error responses to remote configuration requests ([#4669][])
* Core: Profiling: Upgrade libdatadog dependency to version 18.1 ([#4577][])
* Dynamic Instrumentation: Improve UI reporting of application and host status ([#4678][])
* Tracing: Mark AWS integration spans as errored when AWS requests fail ([#4672][])

### Fixed

* Error Tracking: remove error tracking support on Ruby 2.6 ([#4665][])
* Profiling: Fix profiling scheduler reporting corner case during shutdown ([#4679][])
* Tracing: Fix: The `on_error` warning for HTTP instrumentations ([#4673][])

## [2.16.0] - 2025-05-19

### Added

* Core: Add new configuration precedence value `environment` ([#4610][])
* Core: Add Source Code Integration (SCI) tags in Telemetry app-started event and in each Remote Config request ([#4653][])
* Core: Tracing: ErrorTracking: Add automatic reporting of handled errors ([#4604][])
* AppSec: Integrations: Add session tracking and attacker fingerprinting to `devise` and `rails` ([#4644][], [#4625][])
* Profiling: Add support for Ruby 3.5.0-preview1 ([#4600][])
* Tracing: Add warning when `on_error` handler is not a `Proc` ([#4611][])
* Tracing: Integrations: Add option to serialize MongoDB command as JSON ([#4403][])
* Tracing: Integrations: Add baggage to `karafka` list of propagation styles ([#4614][])

### Changed

* Tracing: Adjust trace sampling formula ([#4616][])
* Profiling: Replace `JSON.fast_generate` with `JSON.generate` ([#4602][])

### Fixed

* Core: Fix Ruby warnings when providing a custom time provider ([#4613][])
* Core: Fix Telemetry configuration in agentless mode to respect the timeout specified for the Agent ([#4590][])
* Profiling: Fix profiler compatibility with ruby-head (3.5) ([#4656][])

### Removed

* Core: Remove duplicated classes from Telemetry transport ([#4575][])

## [2.15.0] - 2025-04-17

### Added

* AppSec: Add auto-patching for `activerecord` with sql injection detection ([#4581][])
* Tracing: Add option for `opensearch` to set resource with relative path ([#4509][])

### Changed

* AppSec: Update In-App WAF rules, processors, and scanners ([#4568][])

### Fixed

* AppSec: Fix blocked requests not marked correctly when using custom redirect blocking action ([#4580][])
* AppSec: Fix UTF-8 unsafe payloads in InApp-WAF causing runtime exceptions ([#4573][])

## [2.14.0] - 2025-04-04

### Added

* Tracing: Add `karafka` instrumentation with 2.3.0 as the minimum supported version. ([#4147][])

### Fixed

* Core: Tracing: default logger arguments for compatibility with previous dd-trace-rb versions ([#4558][])
* AppSec: Fix `Datadog::Kit::AppSec::Events` SDK methods to correctly handle given string key `usr.login`. ([#4552][])

## [2.13.0] - 2025-04-02

### Added

* Core: Add `DD_TRACE_EXPERIMENTAL_RUNTIME_ID_ENABLED` experimental option to enable runtime ID collection for runtime metrics. ([#4473][])
* Tracing: Add support for W3C Baggage API along with automatic extraction and injection, and OpenTelemetry support. ([#4493][], [#4505][])
* Tracing: Add `DD_APM_TRACING_ENABLED` option to disable APM tracing while keeping other products traces. ([#4498][])
* Tracing: Add `DD_TRACE_NATIVE_SPAN_EVENTS` option to override span events serialization for agent-less environments. ([#4507][])
* AppSec: Add stack trace reporting for security events. ([#4526][])
* AppSec: Improve `devise` instrumentation to support latest Account Takeover (ATO) detection. ([#4433][])

### Changed

* Core: Improve `DD_TAGS` configuration handling to be more consistent across Datadog libraries and Agent. ([#4530][])
* Tracing: Enable by default 128-bit trace ID logging so that trace IDs are consistent across logs and the Datadog UI. ([#4528][])

### Fixed

* Core: Fix initialization when the library is partially loaded. ([#4498][])
* Tracing: Fix trace ID propagation by ensuring extraction of 16-character hex values from the `_dd.p.tid` tag in `x-datadog-tags` header. ([#4534][])
* Tracing: Profiling: Fix warnings printed by `ruby -w`. ([#4547][], [#4549][])

## [2.12.2] - 2025-03-17

### Fixed

* AppSec: Fix custom In-App WAF blocking response that was configured in the UI is now applied correctly ([#4497][])

## [2.12.1] - 2025-03-05

### Fixed

* AppSec: Fix `ArgumentError` from ActiveRecord for Ruby < 2.7 ([#4437][])

## [2.12.0] - 2025-02-27

### Added

* AppSec: Add detection of Server-Side Request Forgery attacks for `rest-client` ([#4424][])
* Dynamic Instrumentation: Add support for unix domain sockets ([#4426][])

## [2.11.0] - 2025-02-24

### Added

* Tracing: Support `graphql` multiple query errors report via Span Events ([#4177][])
* Profiling: Enable GVL profiling by default on Ruby 3.2+ ([#4406][])
* Profiling: Support correlating profiling with OTel API 1.5+ ([#4425][])
* AppSec: Add detection of Server-Side Request Forgery attacks for `excon` ([#4399][])
* AppSec: Add detection of Server-Side Request Forgery attacks for `faraday` ([#4391][])
* AppSec: Deprecate `appsec.track_user_events` configuration setting in favor of `appsec.auto_user_instrumentation` ([#4352][])
* Dynamic Instrumentation: Add optional trace logging ([#4283][])

### Changed

* Increase default timeout for unix domain socket to 30 seconds ([#4411][])
* Upgrade `libdatadog` to `16.0.1` ([#4353][])
* Dynamic Instrumentation: Improve path matching with prefixes of probe paths ([#4346][])
* Dynamic Instrumentation: Improve event reporting with combing status and snapshot events ([#4360][])

### Fixed

* Tracing: Fix `rack` to continue trace if only distributed trace is present ([#4398][])
* AppSec: Fix a memory leak issue for RASP ([#4422][])
* Dynamic Instrumentation: Fix event submission on forked servers ([#4363][])

### Removed

* Tracing: Remove peer services by default ([#3846][])

## [2.10.0] - 2025-02-04

### Added

* AppSec: Add configuration option(`Datadog.configuration.appsec.rasp_enabled`) to enable/disable Runtime Application Self-Protection checks ([#4311][])
* AppSec: Add stack trace when SQL Injection attack is detected ([#4321][])

### Changed

* Add `logger` gem as dependency ([#4257][])
* Bump minimum version of `datadog-ruby_core_source` to 3.4 ([#4323][])

### Fixed

* Dynamic instrumentation: Fix report probe status when dynamic instrumentation probes fail to instrument ([#4301][])
* Dynamic instrumentation: Include variables named `env` in probe snapshots ([#4292][])
* Fix a concurrency issue during application boot ([#4303][])

## [2.9.0] - 2025-01-15

### Added

* Core: add support for Ruby 3.4 ([#4249][])
* Integrations: add a new option for `ActiveSupport` to disable adding the `cache_key` as a Span Tag with the `cache_key_enabled` option ([#4022][])

### Changed

* Dynamic instrumentation: move DI preloading to `datadog/di/preload` ([#4288][])
* Dynamic instrumentation: dd-trace-rb now reports whether dynamic instrumentation is enabled in startup summary report ([#4285][])
* Dynamic instrumentation: improve loading of DI components ([#4272][], [#4239][])
* Dynamic instrumentation: logging of internal conditions is now done on debug level ([#4266][])
* Dynamic instrumentation: report instrumentation error for line probes when the target file is loaded but not in code tracker registry ([#4208][])
* Profiling: require datadog-ruby_core_source >= 3.3.7 to ensure Ruby 3.4 support ([#4228][])

### Fixed

* Core: fix a crash in crashtracker when agent hostname is an IPv6 address ([#4237][])
* Profiling: fix allocation profiling + otel tracing causing Ruby crash ([#4240][])
* Profiling: fix profiling warnings being really hard to silence ([#4232][])

## [2.8.0] - 2024-12-10

### Added

* DI: Dynamic instrumentation is now available in Ruby as a Preview
* AppSec: Add SQL injection detection for ActiveRecord for following adapters: `mysql2`, `postgresql`, and `sqlite3` ([#4167][])
* Telemetry: Add environment variable to disable logs ([#4153][])
* Integrations: Add configuration option `on_error` to Elasticsearch tracing ([#4066][])

### Changed

* Upgrade libdatadog dependency to 14.3.1 ([#4196][])
* Profiling: Require Ruby 3.1+ for heap profiling ([#4178][])
* AppSec: Update libddwaf to 1.18.0.0.0 ([#4164][])
* Single-step: Lower SSI GLIBC requirements down to 2.17 ([#4137][])

### Fixed

* Integrations: Avoid loading `ActiveSupport::Cache::RedisCacheStore`, which tries to load `redis >= 4.0.1` regardless of the version of Redis the host application has installed ([#4197][])
* Profiling: Fix unsafe initialization when using profiler with otel tracing ([#4195][])
* Single-step: Add safe NOOP injection script for very old rubies ([#4140][])

## [2.7.1] - 2024-11-28

### Fixed

* Tracing: Fix missing version tag ([#4075][])
* Profiling: Fix profiling not loading in certain situations on Ruby 2.5 and 3.3 ([#4161][])

## [2.7.0] - 2024-11-13

### Added

* Profiling: Enable "heap clean after GC" profiler optimization by default ([#4085][])

### Changed

* Enable crashtracking by default ([#4083][])
* Upgrade to `libdatadog` 14.1 ([#4082][])

### Fixed

* Fix `Process.waitall` hanging and stack overflow when crashtracking enabled ([#4082][])

## [2.6.0] - 2024-11-06

### Changed

* Core: Upgrade to libdatadog 14.0 ([#4065][])

### Fixed

* AppSec: Remove unintentional libddwaf require ([#4078][])

## [2.5.0] - 2024-11-05

### Added

* Performance: Profiling: Add setting to lower heap profiling memory use/latency by cleaning up young objects after Ruby GC ([#4020][])

### Changed

* Core: Replace the `debase-ruby_core_source` gem with the `datadog-ruby_core_source` ([#4014][])
* Core: Upgrade to `libdatadog` 13.1 ([#3997][])

### Fixed

* Fix `undefined method` error for Rails runner ([#3996][])
* Apply version tag only to spans that use the global/default service name ([#4027][])
* Ensure UDS takes precedence over HTTP when both Agent configurations defined ([#4024][])
* Remove duplicate leading slash in resource name for Grape routes ([#4033][])

## [2.4.0] - 2024-10-11

### Added

* Core: Allow changing sampling rate for customer defined tags and resources ([#3956][])
* Profiling: Add GVL profiling for Ruby 3.2+ as a preview feature ([#3929][])
* Profiling: Otel: Add preview support for correlating profiling with otel ruby gem ([#3984][])
* Tracing: AppSec: Add http.route tag to Rails, Grape, and Sinatra integrations ([#3849][])
* Tracing: Add capabilities to remote config: tracing sample rate, tracing logs injection, tracing http header tags ([#3888][])
* AppSec: Add a force disable of AppSec feature when using Ruby >= 3.3 with old FFI gem version ([#3969][])

### Changed

* AppSec: Improve PII compliance ([#3857][])
* AppSec: Integrations: Improve accuracy of login tracking for Devise ([#3867][])
* Crashtracking feature is now disabled by default ([#3970][])

### Fixed

* AppSec: Integrations: Fix GraphQL instrumentation for query fragments ([#3887][])
* Bug: Profiling: Fix (small) memory leak in profiler when forking ([#3852][])
* Tracing: Integrations: Fix GraphQL integration reconfiguration ([#3859][])

## [2.3.0] - 2024-08-22

### Added

* Core: Support agentless telemetry ([#3779][])
* Tracing: Add support for span events ([#3776][])
* Tracing: Add tags to enable inferred service dependencies for databases ([#3789][])
* Tracing: Emit log message and instructions for incompatible Lograge setup ([#3812][], [#3839][])
* Tracing: Add `append_comment` option to append SQL comment propagation for `mysql`, `pg` and `trilogy` ([#3809][])
* AppSec: Add threat detection and protection for `graphql` ([#3769][], [#3814][])

### Changed

* Core: Enable crashtracking by default ([#3826][])
* Profiling: Reduce allocation overhead ([#3805][], [#3797][])
* Profiling: Speed up stack sampling ([#3837][])
* Profiling: Upgrade to libdatadog 11 ([#3799][])
* Profiling: Disable allocation counting feature by default ([#3798][])
* Profiling: Reduce the maximum biased result for allocation samples ([#3793][])
* Tracing: Reduce noisy integration logs ([#3785][])

### Fixed

* Tracing: Fix `require` issue for `graphql` ([#3813][])
* AppSec: Fix an error when parsing http headers with integer value ([#3790][])
* AppSec: Fix an error when tracking login failure without `user_id` ([#3841][])
* Fix a syntax error for Ruby < 2.4 during single step instrumentation ([#3795][])

## [2.2.0] - 2024-07-11

### Added

* Tracing: Add `Rails` Runner instrumentation ([#2509][])
* Tracing: Introduce a new, reworked `GraphQL` tracer to comply with span attributes specification ([#3672][])
* Tracing: Enhance `ActiveSupport::Cache` instrumentation with `ActiveSupport::Notifications` subscription ([#3772][])
* Profiling: Track unscaled allocation counts in allocation profiler ([#3770][])

### Changed

* Core: Send Telemetry events in batches ([#3749][])
* Tracing: Populate spans from `ActiveSupport::Notifications` as early as possible ([#3725][])
* Profiling: Upgrade to `libdatadog` 10 ([#3753][])
* Profiling: Optimize `CodeProvenance#record_loaded_files` to avoid allocations ([#3757][])

### Fixed

* Core: Fix Telemetry events blocking main thread ([#3718][])
* Core: Fix deadlock from Telemetry threads ([#3743][])
* Tracing: Fix empty log correlation when tracing is disabled ([#3731][])
* Tracing: Fix HTTP propagation when missing parent span id ([#3730][])
* Tracing: Ensure `_dd.p.tid` tag with fixed size ([#3729][])
* OTel: Fix ids encoding/decoding for propagation ([#3709][])
* Profiling: Workaround Ruby `Dir` returning incorrect results ([#3720][])
* Profiling: Fix `Phusion Passenger` detection when missing from `Gemfile`/`gems.rb` ([#3750][])
* Profiling: Fix `rpath` for linking to libdatadog when loading extension ([#3706][])
* Profiling: Fix incorrect code provenance due to broken JSON monkey patch ([#3695][])
* Profiling: Fix aggregation of actionview template classes ([#3759][], [#3774][])

## [2.1.0] - 2024-06-10

### Added

* Tracing: Configuration by OpenTelemetry environment variables ([#3657][])

### Fixed

* Tracing: Improved compatibility with W3C Trace Context propagation ([#3631][])

## [2.0.0] - 2024-06-06

### Added

* Tracing: Remap http status code tag for otel span for trace metrics ([#3664][])

## [2.0.0.rc1] - 2024-05-24

### Added

* Core: Add libdatadog crash tracker ([#3384][])
* OpenTelemetry: Add support for Span Links ([#3572][])
* Profiling: Enable endpoint profiling for Sidekiq and other background job processors ([#3610][])
* Tracing: Add dynamically configurable sampling rules ([#3598][])
* Tracing: Add sampling rule glob pattern matching ([#3616][])

### Changed

* Appsec: Fix undefined method error when Tracing disabled ([#3645][])
* Profiling: Upgrade to libdatadog 9 ([#3627][])
* Tracing: Cache ActiveRecord configuration resolver ([#3630][])

### Fixed

* Core: Fix error during telemetry debug logging attempt ([#3617][])
* OpenTelemetry: Fix attribute merge with Datadog tags ([#3651][])
* Tracing: Fix environment logger repeated entries ([#3624][])

### Removed

* Profiling: Remove profiler support for Ruby 2.3 and 2.4 ([#3621][])
* Profiling: Remove deprecated profiler settings ([#3597][])

## [1.23.0] - 2024-05-09

### Added

* Profiling: Enable endpoint profiling for Sidekiq and similar background job processors ([#3619][])

### Fixed

* Fix no such file or directory issue when using single step instrumentation ([#3623][])
* Fix error during telemetry debug logging attempt ([#3618][])

## [2.0.0.beta2] - 2024-04-18

### Added

* Add Agent configuration option: `timeout_seconds`, `uds_path`, and `use_ssl` ([#3350][])
* Tracing: Add lightweight log correlation generation ([#3486][])
* Tracing: Add span links ([#3546][])
* Tracing: Add `span_remote` field to `TraceDigest` ([#3516][])
* Tracing: Add `_dd.parent_id` to `tracestate` ([#3488][])
* Tracing: Allow `RateSampler` with zero sampling rate ([#3295][])
* Grape: Add `on_error` settings ([#3370][])

### Changed

* Rename gem from `ddtrace` to `datadog` ([#3490][])
* Require Ruby `>= 2.5` ([#3291][])
* Frozen string literals ([#3392][])
* Startup logs emit when reconfigures ([#3441][])
* Enhance validation for configuration ([#3332][], [#3326][])
* Tracing: Propagation style configuration becomes case-insensitive ([#3299][])
* Tracing: Return string for `#trace_id` and `#span_id` from `Correlation::Identifier` ([#3322][])
* `Elasticsearch`: Replace instance configuration from `client` to `transport` instance ([#3399][])
* `Grape`: Change `error_statuses` settings to `error_status_codes` ([#3370][])
* `GraphQL`: Instrument with `GraphQL::Tracing::DataDogTrace` and more ([#3409][], [#3417][], [#3388][])
* `Rack`: Change http proxy span pattern ([#3369][])
* `Sidekiq`: Remove `tag_args` option and worker specific configuration ([#3396][], [#3402][])
* Integrations: Rename `error_handler` settings to `on_error` ([#3341][])
*
### Fixed

* Tracing: Fix `error_status_codes` options ([#3344][])

### Removed

* Profiling: Remove `bin/ddtracerb` ([#3506][])
* Ci-app: Remove `datadog-ci` gem dependency ([#3288][])
* Tracing: Remove `SpanOperation` aliases ([#3330][])
* Tracing: Remove `b3` style from default propagation ([#3293][])
* Tracing: Minimize sampling API ([#3423][])
* Tracing: Remove `client_ip` disabled env ([#3404][])
* Tracing: Remove `use` alias for `instrument` ([#3403][])
* Tracing: `OpenTracing`, `qless` removed ([#3398][], [#3443][])
* `Net/Http`: Remove `Datadog::Tracing::Contrib::HTTP::Instrumentation.after_request` ([#3367][])
* `Rails`: Drop support for Rails 3 ([#3324][])
* `Rails`: Remove `exception_controller` option ([#3243][])
* Remove constants, methods and more ([#3401][], [#3336][], [#3454][], [#3338][], [#3335][], [#3298][], [#3297][], [#3309][], [#3294][], [#3325][], [#3300][])

## [1.22.0] - 2024-04-16

### Added

* Tracing: Add sampling rules by trace resouce and tags ([#3587][], [#3585][])
* Appsec: Add WAF vendor header support ([#3528][])

### Changed

* Upgrade `Telemetry` to V2 ([#3551][])
* Upgrade to libdatadog 7 ([#3536][])
* Profiling: Enable Garbage Collection profiling by default ([#3558][])
* Profiling: Skip heap samples with age 0 ([#3573][])
* Profiling: Support falling back into extension directory when loading profiler ([#3582][])

### Fixed

* Appsec: Fix MIME-style newlines with strict base64 encoding ([#3565][])

## [2.0.0.beta1] - 2024-03-22

Release notes: https://github.com/DataDog/dd-trace-rb/releases/tag/v2.0.0.beta1

Git diff: https://github.com/DataDog/dd-trace-rb/compare/v1.21.1...v2.0.0.beta1

See https://github.com/DataDog/dd-trace-rb/blob/v2.0.0.beta1/docs/UpgradeGuide2.md.

## [1.21.1] - 2024-03-20

### Added

* Backports auto instrument shim with `datadog/auto_instrument` ([#3535][])

### Fixed

* Fix ActiveRecord resolving invalid string ([#3523][])
* Revert `http.route` tagging to fix instrumentation failure for Rails 7.1 apps ([#3539][])
* Fix wrong permissions on released gem files ([#3531][])

## [1.21.0] - 2024-03-14

### Highlights
Allocation profiling is now in beta, and timeline profiling is enabled by default.
For more details, check the [release notes](https://github.com/DataDog/dd-trace-rb/releases/tag/v1.21.0)

### Added

* APM source code integration ([#3463][])
* Core: Reduce startup logs verbosity ([#3468][])
* Tracing: Add Concurrent::Async instrumentation ([#3427][])
* Profiling: System info support ([#3357][])
* Profiling: Add bin/ddprofrb ([#3501][])

### Changed

* Bump datadog-ci dependency to 0.8.1 ([#3518][])
* Upgrade to libdatadog 6 ([#3455][])
* Core: Allow suppressing error logs for Core::Remote::Negotiation ([#3495][])
* Tracing: Add `http.route` tag to rack ([#3345][])
* Tracing: Logs deprecation warning for `use` removal ([#3438][])
* Profiling: Allocation sampling overhead improvements ([#3434][], [#3440][])
* Profiling: Enable timeline by default ([#3428][])
* Profiling: Rename Profiling files to reflect "datadog" instead of "ddtrace" ([#3502][])
* Profiling: Replace `profiling.advanced.experimental_allocation_enabled` with `profiling.allocation_enabled` and remove experimental warning ([#3520][])

### Fixed

* Core: Fix rare remote configuration worker thread leak ([#3519][])
* Tracing: Fix `Datadog::Tracing.reject!` with correct metrics ([#3491][])
* Tracing: Guard PG result with `nil` check ([#3511][])
* Profiling: Add workaround for Ruby VM bug causing crash in gc_finalize_deferred ([#3473][])
* Profiling: Fix missing profiling code hotspots when using ddtrace+otel ([#3466][])
* Profiling: Stop worker on clock failure ([#3439][])
* Profiling: Upgrade libdatadog to fix incorrect platform detection for x86_64-linux-gnu/aarch64-linux-gnu ([#3503][])

## [1.20.0] - 2024-02-05

### Added

* Tracing: Add `Trilogy` instrumentation ([#3274][])
* Rack: Add remote configuration boot tags ([#3315][])
* Faraday: Add `on_error` option ([#3431][])
* Profiling: Add dynamic allocation sampling ([#3395][])

### Changed

* Bump `datadog-ci` dependency to 0.7.0 ([#3408][])
* Improve performance of gathering ClassCount metric ([#3386][])

### Fixed

* OpenTelemetry: Fix internal loading ([#3400][])
* Core: Fix logger deadlock ([#3426][])
* Rack: Fix missing active trace ([#3420][])
* Redis: Fix instance configuration ([#3278][])

## [1.19.0] - 2024-01-10

### Highlights
Alpha support for memory profiling has been added. For more details, check the [release notes](https://github.com/DataDog/dd-trace-rb/releases/tag/v1.19.0)

### Added
* Tracing: Add `on_error` settings for `mysql2` ([#3316][])
* Core: Add install_signature to app-started telemetry event ([#3349][])
* Profiling: Heap Profiling ([#3281][]) ([#3287][]) ([#3328][]) ([#3329][]) ([#3333][]) ([#3360][])
* Profiling: Redesign GC profiling to add timeline support and reduce overhead ([#3313][])
* Core: Use Ruby 3.3 stable for CI testing ([#3354][])

### Changed
* Core: Bump `datadog-ci` dependency to 0.6.0 ([#3361][])
* Core: Bump debase-ruby_core_source dependency to 3.3.1 ([#3373][])
* Docs: Backport "List Ruby 3.3 as supported in the docs" to master branch ([#3374][])
* Profiling: Import upstream `rb_profile_frames` fix ([#3352][])
* Profiling: Allow the dynamic sampling rate overhead target to be set ([#3310][])
* Profiling: Split profiling tests into ractor and non-ractor suites. ([#3320][])

### Fixed
* Docs: Fix `pg` doc markdown format ([#3317][])
* Tracing: Fix recursive `require` in Railtie ([#3365][])
* Profiling: Fix issues stemming from rb_gc_force_recycle ([#3366][])
* Profiling: Fix Ruby 3.3 CI being broken in master due to profiler ([#3356][])
* Profiling: Fix "no signals" workaround detection when mariadb is in use ([#3362][])

## [1.18.0] - 2023-12-07

### Added

* Tracing: Support lib injection for ARM64 architecture ([#3307][])
* Tracing: Add `error_handler` for `pg` instrumentation ([#3303][])
* Appsec: Enable "Trusted IPs", a.k.a passlist with optional monitoring ([#3229][])

### Changed

* Mark ddtrace threads as fork-safe ([#3279][])
* Bump `datadog-ci` dependency to 0.5.0 ([#3308][])
* Bump `debase-ruby_core_source` dependency to 3.2.3 ([#3284][])
* Profiling: Disable profiler on Ruby 3.3 when running with RUBY_MN_THREADS=1 ([#3259][])
* Profiling: Run without "no signals" workaround on passenger 6.0.19+ ([#3280][])

### Fixed

* Tracing: Fix `pg` instrumentation `enabled` settings ([#3271][])
* Profiling: Fix potential crash by importing upstream `rb_profile_frames` fix ([#3289][])
* Appsec: Call `devise` RegistrationsController block ([#3286][])

## [1.17.0] - 2023-11-22

For W3C Trace Context, this release adds [`tracecontext`](https://www.w3.org/TR/trace-context/) to the default trace propagation extraction and injection styles. The new defaults are:
* Extraction: `Datadog,b3multi,b3,tracecontext`
* Injection: `Datadog,tracecontext`

And to increase interoperability with `tracecontext`, 128-bit Trace ID generation is now the default.

For OpenTelemetry, this release adds support for converting [OpenTelemetry Trace Semantic Conventions](https://opentelemetry.io/docs/specs/semconv/general/trace/) into equivalent Datadog trace semantics. Also, it's now possible to configure top-level Datadog span fields using OpenTelemetry span attributes (https://github.com/DataDog/dd-trace-rb/pull/3262).

For CI Visibility, you can now manually create CI traces and spans with the [newly released API](https://github.com/DataDog/datadog-ci-rb/releases/tag/v0.4.0).

### Added

* OpenTelemetry: Parse OpenTelemetry semantic conventions to Datadog's ([#3273][])
* OpenTelemetry: Support span reserved attribute overrides ([#3262][])
* Tracing: Ensure W3C `tracestate` is always propagated ([#3255][])

### Changed

* Tracing: Set 128-bit trace_id to true by default ([#3266][])
* Tracing: Default trace propagation styles to `Datadog,b3multi,b3,tracecontext` ([#3248][],[#3267][])
* Ci-App: Upgraded `datadog-ci` dependency to 0.4 ([#3270][])

## [1.16.2] - 2023-11-10

This release reverts a change to appsec response body parsing that was introduced in [1.16.0 ](https://github.com/DataDog/dd-trace-rb/releases/tag/v1.16.0) that may cause memory leaks.

### Fixed
*  Appsec: [Revert parse response body fix introduced in 1.16.0](https://github.com/DataDog/dd-trace-rb/pull/3153) ([#3252][])

## [1.16.1] - 2023-11-08

### Fixed

* Tracing: Fix `concurrent-ruby` future propagation without `active_trace` ([#3242][])
* Tracing: Fix host injection error handling  ([#3240][])

## [1.16.0] - 2023-11-03

**This release includes a security change for the Tracing Redis integration:**

Currently, the Datadog Agent removes command arguments from the resource name. However there are cases, like Redis compressed keys, where this obfuscation cannot correctly remove command arguments. To safeguard that situation, the resource name set by the tracer will only be the command (e.g. `SET`) with no arguments. To retain the previous behavior and keep arguments in the span resource, with the potential risk of some command arguments not being fully obfuscated, set ``DD_REDIS_COMMAND_ARGS=true`` or set the option `c.instrument :redis, command_args: true`.

### Added

* Tracing: Propagate trace through `Concurrent::Promises.future` ([#1522][])
* Core: Name `Datadog::Core::Remote::Worker` thread ([#3207][])

### Changed

* Tracing: Redis - Omit command arguments from span.resource by default ([#3235][])
* Ci-app: Bump `datadog-ci` dependency from 0.2.0 to 0.3.0 ([#3223][])

### Fixed

* Appsec: ASM parse response body  ([#3153][])
* Appsec: ASM make sure to append content type and length information ([#3204][])
* Appsec: Make sure function that checks content-type header value accepts nil content-type header value ([#3234][])
* Profiling: Shut down profiler if any components failed ([#3197][])
* Tracing: Fix `ActiveSupport` instrumentation of custom cache stores ([#3206][])

## [1.15.0] - 2023-10-09

### Highlights

* Timeline view for Profiler beta
* Configure AppSec blocking responses via configuration or Remote Configuration
* CI visibility to configure with agentless mode

For more details, check the [release notes](https://github.com/DataDog/dd-trace-rb/releases/tag/v1.15.0)

### Added

* Enable allocation counting feature by default for some Ruby 3 versions ([#3176][])
* Detect `WebMock` `Cucumber` and `Rails.env` to disable telemetry and remote configuration for development environment ([#3065][], [#3062][], [#3145][])
* Profiling: Import java-profiler PID controller and port it to C ([#3190][])
* Profiling: Record allocation type when sampling objects ([#3096][])
* Profiling: Include `ruby vm type` in profiler allocation samples ([#3074][])
* Tracing: Support `Rack` 3 ([#3132][])
* Tracing: Support `Opensearch` 3 ([#3189][])
* Tracing: `grpc` adds `client_error_handler` option ([#3095][])
* Tracing: Add `async` option for `test_mode` configuration ([#3158][])
* Tracing: Implements `_dd.base_service` tag ([#3018][])
* Appsec: Allow blocking response template configuration via ENV variables  ([#2975][])
* Appsec: ASM API security. Schema extraction ([#3131][], [#3166][], [#3177][])
* Appsec: Enable configuring blocking response via Remote Configuration  ([#3099][])
* Ci-app: Validate git tags ([#3100][])
* Ci-app: Add agentless mode ([#3186][])

### Changed

* Appsec: Skip passing waf addresses when the value is empty ([#3188][])
* Profiling: Restore support for Ruby 3.3 ([#3167][])
* Profiling: Add approximate thread state categorization for timeline ([#3162][])
* Profiling: Wire up allocation sampling into `CpuAndWallTimeWorker` ([#3103][])
* Tracing: `dalli` disable memcached command tag by default ([#3171][])
* Tracing: Use first valid extracted style for distributed tracing ([#2879][])
* Tracing: Rename configuration option `on_set` to `after_set` ([#3107][])
* Tracing: Rename `experimental_default_proc` to `default_proc` ([#3091][])
* Tracing: Use `peer.service` for sql comment propagation ([#3127][])
* Ci-app: Fix `Datadog::CI::Environment` to support the new CI specs ([#3080][])
* Bump `datadog-ci` dependency to 0.2 ([#3186][])
* Bump `debase-ruby_core_source` dependency to 3.2.2 ([#3163][])
* Upgrade `libdatadog` 5 ([#3169][], [#3104][])
* Upgrade `libddwaf-rb` 1.11.0 ([#3087][])
* Update AppSec rules to 1.8.0 ([#3140][], [#3139][])

### Fixed

* Profiling: Add workaround for incorrect invoke location when logging gem is in use ([#3183][])
* Profiling: Fix missing endpoint profiling when `request_queuing` is enabled in `rack` instrumentation ([#3109][])
* Appsec: Span tags reporting the number of WAF failed loaded rules ([#3106][])
* Tracing: Fix tagging with empty data ([#3102][])
* Tracing: Fix `rails.cache.backend` span tag with multiple stores ([#3060][])

### Removed

* Profiling: Remove legacy profiler codepath ([#3172][])
* Ci-app: Remove CI module and add a dependency on [`datadog-ci` gem](https://github.com/DataDog/datadog-ci-rb) ([#3128][])
* Tracing: Remove `depends_on` option from configuration DSL ([#3085][])
* Tracing: Remove `delegate_to` option from configuration DSL ([#3086][])

## [1.14.0] - 2023-08-24

### Added

* Cucumber 8.0.0 support, test CI visibility with cucumber versions 6-8 ([#3061][])
* Tracing: Add `ddsource` to #to_log_format ([#3025][])
* Core: include peer service configurations in telemetry payload ([#3056][])
* Tracing: Improve quantization ([#3041][])

### Changed

* Profiling: Disable profiler on Ruby 3.3 due to incompatibility ([#3054][])
* Core: EnvironmentLogger adjustments ([#3020][], [#3057][])

### Fixed

* Appsec: Fix ASM setting for automated user events. ([#3070][])
* Tracing: Fix ActiveRecord adapter name for Rails 7 ([#3051][])

## [1.13.1] - 2023-08-14

### Fixed

* Tracing: `net/http` instrumentation excludes query string for `http.url` tag ([#3045][])
* Tracing: Remove `log_tags` warning when given hash for log injection ([#3022][])
* Tracing: Fix OpenSearch integration loading ([#3019][])
* Core: Fix default hostname/port when mixing http and uds configuration ([#3037][])
* Core: Disable Telemetry and Remote Configuration in development environments ([#3039][])
* Profiling: Improve `Datadog::Profiling::HttpTransport` error logging ([#3038][])
* Docs: Document known issues with hanging Resque workers ([#3033][])

## [1.13.0] - 2023-07-31

### Added

* Core: Add support for `Option` precedence ([#2915][])
* Core: Add support for unsetting options ([#2972][])
* Core: Gauge primitive `RubyVM::YJIT.runtime_stats`, if `YJIT` is enabled ([#2711][], [#2959][])([@HeyNonster][])
* Core: Add Telemetry `app-client-configuration-change` event ([#2977][])
* Core: Improve our `SafeDup` module ([#2960][])
* Tracing: Add `OpenSearch` Integration ([#2940][])
* Tracing: Implement `peer.service` tag to integrations ([#2982][])
* Tracing: Add mandatory rpc and grpc tags for `grpc` integration ([#2620][], [#2962][])
* Tracing: Include `_dd.profiling.enabled` tag ([#2913][])
* Tracing: Support host injection ([#2941][], [#3007][])
* Tracing: Implement Dynamic Configuration for tracing ([#2848][], [#2973][])
* Tracing: Add for dynamic log injection configuration ([#2992][])
* Tracing: Add sampling configuration with `DD_TRACE_SAMPLING_RULES` ([#2968][])
* Tracing: Add HTTP header tagging with `DD_TRACE_HEADER_TAGS` for clients and servers ([#2946][], [#2935][])
* Profiling: Add fallback name/invoke location for unnamed threads started in native code ([#2993][])
* Profiling: Use invoke location as a fallback for nameless threads in the profiler ([#2950][])
* Profiling: Add fallback name for main thread in profiling data ([#2939][])
* Ci-app: Add `Minitest` CI integration ([#2932][]) ([@bravehager][])
* Appsec: `Devise` integration and automatic user events  ([#2877][])
* Appsec: Handle disabled tracing and appsec events ([#2572][])
* Appsec: Automate user events check for UUID in safe mode ([#2952][])
* Docs: Add Ruby 3.2 support to compatibility matrix ([#2971][])

### Changed

* Core: Set maximum supported Ruby version ([#2497][])
* Core: Prevent telemetry requests from being traced ([#2961][])
* Core: Add `env` and `type` to Core configuration option ([#2983][], [#2988][], [#2994][])
* Core: Remove `lazy` from Core configuration option ([#2931][], [#2999][])
* Profiling: Bump `libdatadog` dependency to version 3 ([#2948][])
* Profiling: Improve error message when `ddtrace_profiling_loader` fails to load ([#2957][])
* Tracing: Improve log injection runtime conditionals ([#2926][], [#2882][])

### Fixed

* Core: Fix polynomial-time regular expressions ([#2814][])
* Core: Fix environment variable for dynamic configuration polling interval ([#2967][])
* Core: Reduce remote configuration error logging noise ([#3011][])
* Tracing: Fix manual log injection for 128 bit trace_id ([#2974][])
* Tracing: Ensure the GRPC client interceptor return the response ([#2928][]) ([@KJTsanaktsidis][])
* Tracing: Remove dynamic input used in regular expression ([#2867][])
* Tracing: Fix distributed tracing header formats ([#3005][] )
* Profiling: Fix profiler `libmysqlclient` version detection with `mysql2-aurora` gem ([#2956][])
* Profiling: Automatically enable profiler "no signals" workaround for `passenger` web server ([#2978][])

## [1.12.1] - 2023-06-14

### Added
* Appsec: Add `appsec.blocked` tag to span ([#2895][])
* Profiling:  Add workaround for legacy profiler incompatibility with ruby-cloud-profiler gem ([#2891][])
* Core: Allow setting remote configuration service name ([#2853][])

### Changed
* Appsec: Change the value format for the WAF address `server.request.query` ([#2903][])
* Profiling: Log pkg-config command when building profiling native extension

### Fixed
* Appsec: Update blocked response content_type resolution ([#2900][])
* Appsec: Ensure to use service entry span. ([#2898][])
* Tracing: Fix AWS integration constant loading ([#2896][])

## [1.12.0] - 2023-06-02

### Added
* Profiling: Add support for profiling Ruby 3.3.0-preview1 ([#2860][])
* Appsec: Appsec support nested apps ([#2836][])
* Appsec: Appsec add support for custom rules ([#2856][])
* Appsec: Update appsec static rules to 1.7.0 version ([#2869][])
* Appsec: Tag AppSec on Rack top-level span ([#2858][])
* Profiling: Implement "no signals" workaround and enable CPU Profiling 2.0 for all customers ([#2873][])
* Ci: Update CI Visibility spec ([#2874][])
* Appsec: Added missing waf addresses to request operation ([#2883][])

### Changed

* Tracing: Consistent APM Span tags for AWS SDK Requests ([#2730][])
* Tracing: Change default `service_name` values Part 2 ([#2765][])
* Profiling: Bump debase-ruby_core_source dependency to 3.2.1 ([#2875][])

### Fixed
* Telemetry: Disable for non-HTTP agent connection ([#2815][])
* Tracing: Fix circular requires ([#2826][])
* Tracing: Update comment about Datadog::Tracing::Distributed::Ext to correct modules ([#2840][])
* Appsec: Check if `:appsec` setting is present before accessing it in remote component ([#2854][])
* Telemetry: Do not send Dependency `hash` when `version` is present ([#2855][])
* Core: Fix symbol configuration for `env` and `service` ([#2864][])
* Tracing: Fix sql comment propagation `full` mode when tracing is disabled ([#2866][])
* Appsec: Use relative URI for server.request.uri.raw ([#2890][])

## [1.11.1] - 2023-05-03

### Fixed

* Appsec: Remove misreported `ASM_CUSTOM_RULES` capability ([#2829][])
* Appsec: Fix block response content negotiation ([#2824][])
* Appsec: Fix incorrect remote configuration payload key handling  ([#2822][])

## [1.11.0] - 2023-04-27

### Highlights

As of ddtrace 1.11.0, these features are GA and emabled by default:

- CPU Profiling 2.0
- Remote Configuration
- Telemetry

For more details, check the release notes.

### Added

* Add remote configuration, enabled by default ([#2674][], [#2678][], [#2686][], [#2687][], [#2688][], [#2689][], [#2696][], [#2705][], [#2731][], [#2732][], [#2733][], [#2739][], [#2756][], [#2769][], [#2771][], [#2773][], [#2789][], [#2805][], [#2794][])
* AppSec: Add response headers passing to WAF ([#2701][])
* Tracing: Distributed tracing for Sidekiq ([#2513][])
* Tracing: Add Roda integration ([#2368][])
* Profiling: Support disabling endpoint names collection in new profiler ([#2698][])
* Tracing: Support Sidekiq 7 ([#2810][])
* Core: Add support for Unix Domain Socket (UDS) configuration via `DD_TRACE_AGENT_URL` ([#2806][])
* Core: Enable Telemetry by default ([#2762][])

### Changed

* Core: Allow `1` as true value in environment variables ([#2710][])
* Profiling: Enable CPU Profiling 2.0 by default ([#2702][])
* Tracing: Improve controller instrumentation and deprecate option `exception_controller` ([#2726][])
* Tracing: Implement Span Attribute Schema Environment Variable ([#2727][])
* Tracing: Change default `service_name` values (gated by feature flag) ([#2760][])

### Fixed

* Bug: Tracing: Fix w3c propagation special character handling ([#2720][])
* Performance: Tracing: Use `+@` instead of `dup` for duplicating strings ([#2704][])
* Profiling: Avoid triggering allocation sampling during sampling ([#2690][])
* Integrations: Tracing: Fix Rails < 3 conditional check in Utils#railtie_supported? ([#2695][])
* Profiling: Do not auto-enable new profiler when rugged gem is detected ([#2741][])
* Tracing: Fix using SemanticLogger#log(severity, message, progname) ([#2748][]) ([@rqz13][])
* Profiling: Improve detection of mysql2 gem incompatibilities with profiler ([#2770][])
* AppSec: Remove check for `::Rack::Request.instance_methods.include?(:each_header)` at load time ([#2778][])
* Tracing: Fix quadratic backtracking on invalid URI ([#2788][])
* Community: Correctly set mutex ([#2757][]) ([@ixti][])

Read the [full changeset](https://github.com/DataDog/dd-trace-rb/compare/v1.10.1...v1.11.0.beta1) and the release [milestone](https://github.com/DataDog/dd-trace-rb/milestone/121?closed=1).

## [1.11.0.beta1] - 2023-04-14

As of ddtrace 1.11.0.beta1, CPU Profiling 2.0 is now GA and enabled by default. For more details, check the release notes.

As of ddtrace 1.11.0.beta1, Remote Configuration is now public beta and disabled by default. For more details, check the release notes.

### Added

* Add remote configuration beta, disabled by default ([#2674][], [#2678][], [#2686][], [#2687][], [#2688][], [#2689][], [#2696][], [#2705][], [#2731][], [#2732][], [#2733][], [#2739][], [#2756][], [#2769][], [#2771][], [#2773][], [#2789][])
* AppSec: Add response headers passing to WAF ([#2701][])
* Tracing: Distributed tracing for Sidekiq ([#2513][])
* Tracing: Add Roda integration ([#2368][])
* Profiling: [PROF-6555] Support disabling endpoint names collection in new profiler ([#2698][])

### Changed

* Core: Allow `1` as true value in environment variables ([#2710][])
* Profiling: [PROF-7360] Enable CPU Profiling 2.0 by default ([#2702][])
* Tracing: Improve controller instrumentation and deprecate option `exception_controller` ([#2726][])
* Tracing: Implement Span Attribute Schema Environment Variable ([#2727][])

### Fixed

* Bug: Tracing: Fix w3c propagation special character handling ([#2720][])
* Performance: Tracing: Use `+@` instead of `dup` for duplicating strings ([#2704][])
* Profiling: [PROF-7307] Avoid triggering allocation sampling during sampling ([#2690][])
* Integrations: Tracing: Fix Rails < 3 conditional check in Utils#railtie_supported? ([#2695][])
* Profiling: [PROF-7409] Do not auto-enable new profiler when rugged gem is detected ([#2741][])
* Tracing: Fix using SemanticLogger#log(severity, message, progname) ([#2748][]) ([@rqz13][])
* Profiling: [PROF-6447] Improve detection of mysql2 gem incompatibilities with profiler ([#2770][])
* AppSec: Remove check for `::Rack::Request.instance_methods.include?(:each_header)` at load time ([#2778][])
* Tracing: Fix quadratic backtracking on invalid URI ([#2788][])

## [1.10.1] - 2023-03-10

### Fixed

* CI: Update TeamCity environment variable support ([#2668][])
* Core: Fix spurious dependency on AppSec when loading CI with `require 'datadog/ci'` ([#2679][])
* Core: Allow multiple headers and multiple IPs per header for client IP ([#2665][])
* AppSec: prevent side-effect on AppSec login event tracking method arguments ([#2663][]) ([@coneill-enhance][])

## [1.10.0] - 2023-03-06

### Added

* Support Ruby 3.2 ([#2601][])
* Publish init container image (beta) for `dd-trace-rb` injection through K8s admission controller ([#2606][])
* Tracing: Support 128 bits trace id  ([#2543][])
* Tracing: Add tags to integrations (`que` / `racecar` / `resque`/ `shoryken` / `sneakers` / `qless` / `delayed_job` / `kafka` / `sidekiq` / `dalli` / `presto` / `elasticsearch`) ([#2619][],  [#2613][] , [#2608][], [#2590][])
* Appsec: Introduce `AppSec::Instrumentation::Gateway::Argument` ([#2648][])
* Appsec: Block request when user ID matches rules  ([#2642][])
* Appsec: Block request base on response addresses matches ([#2605][])
* Appsec: Allow to set user id denylist ([#2612][])
* Profiling: Show profiler overhead in flamegraph for CPU Profiling 2.0 ([#2607][])
* Profiling: Add support for allocation samples to `ThreadContext` ([#2657][])
* Profiling: Exclude disabled profiling sample value types from output ([#2634][])
* Profiling: Extend stack collector to record the alloc-samples metric ([#2618][])
* Profiling: Add `Profiling.allocation_count` API for new profiler ([#2635][])

### Changed

* Tracing: `rack` instrumentation counts time spent in queue as part of the `http_server.queue` span ([#2591][]) ([@agrobbin][])
* Appsec: Update ruleset to 1.5.2 ([#2662][], [#2659][], [#2598][])
* Appsec: Update `libddwaf` version to 1.6.2.0.0 ([#2614][])
* Profiling: Upgrade profiler to use `libdatadog` v2.0.0 ([#2599][])
* Profiling: Remove support for profiling Ruby 2.2 ([#2592][])

### Fixed

* Fix broken Ruby VM statistics for Ruby 3.2 ([#2600][])
* Tracing: Fix 'uninitialized constant GRPC::Interceptor' error with 'gapic-common' gem ([#2649][])
* Profiling: Fix profiler not adding the "In native code" placeholder ([#2594][])
* Fix profiler detection for google-protobuf installation ([#2595][])

## [1.9.0] - 2023-01-30

As of ddtrace 1.9.0, CPU Profiling 2.0 is now in opt-in (that is, disabled by default) public beta. For more details, check the release notes.

Release notes: https://github.com/DataDog/dd-trace-rb/releases/tag/v1.9.0

### Added

* Tracing: Add `Stripe` instrumentation ([#2557][])
* Tracing: Add configurable response codes considered as errors for `Net/HTTP`, `httprb` and `httpclient` ([#2501][], [#2576][])([@caramcc][])
* Tracing: Flexible header matching for HTTP propagator ([#2504][])
* Tracing: `OpenTelemetry` Traces support ([#2496][])
* Tracing: W3C: Propagate unknown values as-is ([#2485][])
* Appsec: Add event kit API ([#2512][])
* Profiling: Allow profiler development on arm64 macOS ([#2573][])
* Core: Add `profiling_enabled` state to environment logger output ([#2541][])
* Core: Add 'type' to `OptionDefinition` ([#2493][])
* Allow `debase-ruby_core_source` 3.2.0 to be used ([#2526][])

### Changed

* Profiling: Upgrade to `libdatadog` to `1.0.1.1.0` ([#2530][])
* Appsec: Update appsec rules `1.4.3` ([#2580][])
* Ci: Update CI Visibility metadata extraction ([#2586][])

### Fixed

* Profiling: Fix wrong `libdatadog` version being picked during profiler build ([#2531][])
* Tracing: Support `PG` calls with a block ([#2522][])
* Ci: Fix error in `teamcity` env vars ([#2562][])

## [1.8.0] - 2022-12-14

Release notes: https://github.com/DataDog/dd-trace-rb/releases/tag/v1.8.0

As of ddtrace 1.8.0, CPU Profiling 2.0 is now in opt-in (that is, disabled by default) public beta. For more details,
check the release notes.

### Added

* Core: Profiling: [PROF-6559] Mark Ruby CPU Profiling 2.0 as being in beta ([#2489][])
* Tracing: Attempt to parse future version of TraceContext ([#2473][])
* Tracing: Add DD_TRACE_PROPAGATION_STYLE option ([#2466][])
* Integrations: Tracing: SQL comment propagation full mode with traceparent ([#2464][])
* Integrations: Tracing: Wire W3C propagator to HTTP & gRPC propagation ([#2458][])
* Integrations: Tracing: Auto-instrumentation with service_name from environmental variable ([#2455][])
* Core: Integrations: Tracing: Deprecation notice for B3 propagation configuration ([#2454][])
* Tracing: Add W3C Trace Context propagator ([#2451][])
* Integrations: Tracing: Redis 5 Instrumentation ([#2428][])

### Changed

* Tracing: Changes `error.msg` to `error.message` for UNC ([#2469][])
* Tracing: Semicolons not allowed in 'origin' ([#2461][])
* Core: Dev/refactor: Tracing: Dev/internal: Move Utils#next_id and constants to Tracing::Utils ([#2463][])
* Core: Dev/refactor: Tracing: Dev/internal: Move Tracing config settings from Core to Tracing ([#2459][])
* Core: Dev/refactor: Tracing: Dev/internal: Move Tracing diagnostic code from Core to Tracing ([#2453][])

### Fixed

* Integrations: Tracing: Improve redis integration patching ([#2470][])
* Tracing: Extra testing from W3C spec ([#2460][])

## [1.7.0] - 2022-11-29

### Added
* Integrations: Support que 2 ([#2382][]) ([@danhodge][])
* Tracing: Unified tagging `span.kind` as `server` and `client` ([#2365][])
* Tracing: Adds `span.kind` tag for `kafka`, `sidekiq`, `racecar`,  `que`, `shoryuken`, `sneakers`, and `resque` ([#2420][], [#2419][], [#2413][], [#2394][])
* Tracing: Adds `span.kind` with values `producer` and `consumer` for `delayed_job` ([#2393][])
* Tracing: Adds `span.kind` as `client` for `redis` ([#2392][])
* Appsec: Pass HTTP client IP to WAF ([#2316][])
* Unified tagging `process_id` ([#2276][])

### Changed
* Allow `debase-ruby_core_source` 0.10.18 to be used ([#2435][])
* Update AppSec ruleset to v1.4.2 ([#2390][])
* Refactored clearing of profile data after Ruby app forks ([#2362][], [#2367][])
* Tracing: Move distributed propagation to Contrib ([#2352][])

### Fixed
* Fix ddtrace installation issue when users have CI=true ([#2378][])

## [1.6.1] - 2022-11-16

### Changed

* Limit `redis` version support to less than 5

### Fixed

* [redis]: Fix frozen input for `Redis.new(...)`

## [1.6.0] - 2022-11-15

### Added

* Trace level tags propagation in distributed tracing  ([#2260][])
* [hanami]: Hanami 1.x instrumentation ([#2230][])
* [pg, mysql2]: option `comment_propagation` for SQL comment propagation, default is `disabled` ([#2339][])([#2324][])

### Changed

* [rack, sinatra]: Squash nested spans and improve patching mechanism.<br> No need to `register Datadog::Tracing::Contrib::Sinatra::Tracer`([#2217][])
* [rails, rack]: Fix Non-GET request method with rails exception controller ([#2317][])
* Upgrade to libdatadog 0.9.0.1.0 ([#2302][])
* Remove legacy profiling transport ([#2062][])

### Fixed

* [redis]: Fix redis instance configuration, not on `client` ([#2363][])
```
# Change your code from
Datadog.configure_onto(redis.client, service_name: '...')
# to
Datadog.configure_onto(redis, service_name: '...')
```
* Allow `DD_TAGS` values to have the colon character ([#2292][])
* Ensure that `TraceSegment` can be reported correctly when they are dropped ([#2335][])
* Docs: Fixes upgrade guide on configure_onto ([#2307][])
* Fix environment logger with IO transport ([#2313][])

## [1.5.2] - 2022-10-27

### Deprecation notice

- `DD_TRACE_CLIENT_IP_HEADER_DISABLED` was changed to `DD_TRACE_CLIENT_IP_ENABLED`. Although the former still works we encourage usage of the latter instead.

### Changed

- `http.client_ip` tag collection is made opt-in for APM. Note that `http.client_ip` is always collected when ASM is enabled as part of the security service provided ([#2321][], [#2331][])

### Fixed

- Handle REQUEST_URI with base url ([#2328][], [#2330][])

## [1.5.1] - 2022-10-19

### Changed

* Update libddwaf to 1.5.1 ([#2306][])
* Improve libddwaf extension memory management ([#2306][])

### Fixed

* Fix `URI::InvalidURIError` ([#2310][], [#2318][]) ([@yujideveloper][])
* Handle URLs with invalid characters ([#2311][], [#2319][])
* Fix missing appsec.event tag ([#2306][])
* Fix missing Rack and Rails request body parsing for AppSec analysis ([#2306][])
* Fix unneeded AppSec call in a Rack context when AppSec is disabled ([#2306][])
* Fix spurious AppSec instrumentation ([#2306][])

## [1.5.0] - 2022-09-29

### Deprecation notice

* `c.tracing.instrument :rack, { quantize: { base: ... } }` will change its default from `:exclude` to `:show` in a future version. Voluntarily moving to `:show` is recommended.
* `c.tracing.instrument :rack, { quantize: { query: { show: ... } }` will change its default to `:all` in a future version, together with `quantize.query.obfuscate` changing to `:internal`. Voluntarily moving to these future values is recommended.

### Added

* Feature: Single Span Sampling ([#2128][])
* Add query string automatic redaction ([#2283][])
* Use full URL in `http.url` tag ([#2265][])
* Add `http.useragent` tag ([#2252][])
* Add `http.client_ip` tag for Rack-based frameworks ([#2248][])
* Ci-app: CI: Fetch committer and author in Bitrise ([#2258][])

### Changed

* Bump allowed version of debase-ruby_core_source to include v0.10.17 ([#2267][])

### Fixed

* Bug: Fix `service_nam` typo to `service_name` ([#2296][])
* Bug: Check AppSec Rails for railties instead of rails meta gem ([#2293][]) ([@seuros][])
* Ci-app: Correctly extract commit message from AppVeyor ([#2257][])

## [1.4.2] - 2022-09-27

### Fixed

OpenTracing context propagation ([#2191][], [#2289][])

## [1.4.1] - 2022-09-15

### Fixed

* Missing distributed traces when trace is dropped by priority sampling ([#2101][], [#2279][])
* Profiling support when Ruby is compiled without a shared library ([#2250][])

## [1.4.0] - 2022-08-25

Release notes: https://github.com/DataDog/dd-trace-rb/releases/tag/v1.4.0

Git diff: https://github.com/DataDog/dd-trace-rb/compare/v1.3.0...v1.4.0

### Added

* gRPC: tag `grpc.client.deadline` ([#2200][])
* Implement telemetry, disable by default ([#2153][])

### Changed

* Bump `libdatadog` dependency version ([#2229][])

### Fixed

* Fix CI instrumentation configuration ([#2219][])

## [1.3.0] - 2022-08-04

Release notes: https://github.com/DataDog/dd-trace-rb/releases/tag/v1.3.0

Git diff: https://github.com/DataDog/dd-trace-rb/compare/v1.2.0...v1.3.0

### Added

* Top-level span being tagged to avoid duplicate computation ([#2138][])

### Changed

* ActiveSupport: Optionally disable tracing with Rails ([@marcotc][])
* Rack: Resource overwritten by nested application ([#2180][])
* Rake: Explicit task instrumentation to prevent memory bloat ([#2174][])
* Sidekiq and DelayedJob: Add spans to improve tracing ([#2170][])
* Drop Profiling support for Ruby 2.1 ([#2140][])
* Migrate `libddprof` dependency to `libdatadog` ([#2061][])

### Fixed

* Fix OpenTracing propagation with TraceDigest ([#2201][])
* Fix SpanFilter dropping descendant spans ([#2074][])
* Redis: Fix Empty pipelined span being dropped ([#757][]) ([@sponomarev][])
* Fix profiler not restarting on `Process.daemon` ([#2150][])
* Fix setting service from Rails configuration ([#2118][]) ([@agrobbin][])
* Some document and development improvement ([@marocchino][]) ([@yukimurasawa][])

## [1.2.0] - 2022-07-11

Release notes: https://github.com/DataDog/dd-trace-rb/releases/tag/v1.2.0

Git diff: https://github.com/DataDog/dd-trace-rb/compare/v1.1.0...v1.2.0

Special thanks go to [@miketheman][] for gifting Datadog access to the `datadog` gem a few days ago.

### Added

* Add Postgres (`pg` gem) instrumentation ([#2054][]) ([@jennchenn][])
* Add env var for debugging profiling native extension compilation issues ([#2069][])
* Teach Rest Client integration the `:split_by_domain` option ([#2079][]) ([@agrobbin][])
* Allow passing request_queuing option to Rack through Rails tracer ([#2082][]) ([@KieranP][])
* Add Utility to Collect Platform Information ([#2097][]) ([@jennchenn][])
* Add convenient interface for getting and setting tags using `[]` and `[]=` respectively ([#2076][]) ([@ioquatix][])
* Add b3 metadata in grpc ([#2110][]) ([@henrich-m][])

### Changed

* Profiler now reports profiling data using the libddprof gem ([#2059][])
* Rename `Kernel#at_fork_blocks` monkey patch to `Kernel#ddtrace_at_fork_blocks` ([#2070][])
* Improved error message for enabling profiling when `pkg-config` system tool is not installed ([#2134][])

### Fixed

* Prevent errors in `action_controller` integration when tracing is disabled ([#2027][]) ([@ahorner][])
* Fix profiler not building on ruby-head (3.2) due to VM refactoring ([#2066][])
* Span and trace IDs should not be zero ([#2113][]) ([@albertvaka][])
* Fix object_id usage as thread local key ([#2096][])
* Fix profiling not working on Heroku and AWS Elastic Beanstalk due to linking issues ([#2125][])

## [1.1.0] - 2022-05-25

Release notes: https://github.com/DataDog/dd-trace-rb/releases/tag/v1.1.0

Git diff: https://github.com/DataDog/dd-trace-rb/compare/v1.0.0...v1.1.0

### Added

* [Application Security Monitoring](https://docs.datadoghq.com/security_platform/application_security/)
* Elasticsearch: v8.0 support ([#1985][])
* Sidekiq: Quantize args ([#1972][]) ([@dudo][])
* Profiling: Add libddprof dependency to power the new Ruby profiler ([#2028][])
* Helper to easily enable core dumps ([#2010][])

### Changed

* Support spaces in environment variable DD_TAGS ([#2011][])

### Fixed

* Fix "circular require considered harmful" warnings ([#1998][])
* Logging: Change ddsource to a scalar value ([#2022][])
* Improve exception logging ([#1992][])

## [1.0.0] - 2022-04-28

Release notes: https://github.com/DataDog/dd-trace-rb/releases/tag/v1.0.0

Git diff: https://github.com/DataDog/dd-trace-rb/compare/v1.0.0.beta2...v1.0.0

Diff since last stable release: https://github.com/DataDog/dd-trace-rb/compare/v0.54.2...v1.0.0

### Added

- GraphQL 2.0 support ([#1982][])

### Changed

- AppSec: Update libddwaf to 1.3.0 ([#1981][])

### Fixed

- Rails log correlation ([#1989][]) ([@cwoodcox][])
- Resource not inherited from lazily annotated spans ([#1983][])
- AppSec: Query address for libddwaf ([#1990][])

### Refactored

- Docs: Add undocumented Rake option ([#1980][]) ([@ecdemis123][])
- Improvements to test suite & CI ([#1970][], [#1974][], [#1991][])
- Improvements to documentation ([#1984][])

## [1.0.0.beta2] - 2022-04-14

Release notes: https://github.com/DataDog/dd-trace-rb/releases/tag/v1.0.0.beta2

Git diff: https://github.com/DataDog/dd-trace-rb/compare/v1.0.0.beta1...v1.0.0.beta2

### Added

- Ruby 3.1 & 3.2 support ([#1975][], [#1955][])
- Trace tag API ([#1959][])

### Changed

- Access to configuration settings is namespaced ([#1922][])
- AWS provides metrics by default ([#1976][]) ([@dudo][])
- Update `debase-ruby_core_source` version ([#1964][])
- Profiling: Hide symbols/functions in native extension ([#1968][])
- Profiling: Renamed code_provenance.json to code-provenance.json ([#1919][])
- AppSec: Update libddwaf to v1.2.1 ([#1942][])
- AppSec: Update rulesets to v1.3.1 ([#1965][], [#1961][], [#1937][])
- AppSec: Avoid exception on missing ruleset file ([#1948][])
- AppSec: Env var consistency ([#1938][])

### Fixed

- Rake instrumenting while disabled ([#1940][], [#1945][])
- Grape instrumenting while disabled ([#1940][], [#1943][])
- CI: require 'datadog/ci' not loading dependencies ([#1911][])
- CI: RSpec shared example file names ([#1816][]) ([@Drowze][])
- General documentation improvements ([#1958][], [#1933][], [#1927][])
- Documentation fixes & improvements to 1.0 upgrade guide ([#1956][], [#1973][], [#1939][], [#1914][])

### Removed

- OpenTelemetry extensions (Use [OTLP](https://docs.datadoghq.com/tracing/setup_overview/open_standards/#otlp-ingest-in-datadog-agent) instead) ([#1917][])

### Refactored

- Agent settings resolver logic ([#1930][], [#1931][], [#1932][])

## [1.0.0.beta1] - 2022-02-15

Release notes: https://github.com/DataDog/dd-trace-rb/releases/tag/v1.0.0.beta1

Git diff: https://github.com/DataDog/dd-trace-rb/compare/v0.54.2...v1.0.0.beta1

See https://github.com/DataDog/dd-trace-rb/blob/v1.0.0.beta1/docs/UpgradeGuide.md.

## [0.54.2] - 2022-01-18

Release notes: https://github.com/DataDog/dd-trace-rb/releases/tag/v0.54.2

Git diff: https://github.com/DataDog/dd-trace-rb/compare/v0.54.1...v0.54.2

### Changed

- Bump `debase-ruby_core_source` dependency version; also allow older versions to be used ([#1798][], [#1829][])
- Profiler: Reduce impact of reporting data in multi-process applications ([#1807][])
- Profiler: Update API used to report data to backend ([#1820][])

### Fixed

- Gracefully handle installation on environments where Ruby JIT seems to be available but is actually broken ([#1801][])

## [0.54.1] - 2021-11-30

Release notes: https://github.com/DataDog/dd-trace-rb/releases/tag/v0.54.1

Git diff: https://github.com/DataDog/dd-trace-rb/compare/v0.54.0...v0.54.1

### Fixed

- Skip building profiling native extension when Ruby has been compiled without JIT ([#1774][], [#1776][])

## [0.54.0] - 2021-11-17

Release notes: https://github.com/DataDog/dd-trace-rb/releases/tag/v0.54.0

Git diff: https://github.com/DataDog/dd-trace-rb/compare/v0.53.0...v0.54.0

### Added

- MongoDB service name resolver when using multi cluster ([#1423][]) ([@skcc321][])
- Service name override for ActiveJob in Rails configuration ([#1703][], [#1770][]) ([@hatstand][])
- Profiler: Expose profile duration and start to the UI ([#1709][])
- Profiler: Gather CPU time without monkey patching Thread ([#1735][], [#1740][])
- Profiler: Link profiler samples to individual web requests ([#1688][])
- Profiler: Capture threads with empty backtrace ([#1719][])
- CI-App: Memoize environment tags to improve performance ([#1762][])
- CI-App: `test.framework_version` tag for rspec and cucumber ([#1713][])

### Changed

- Set minimum version of dogstatsd-ruby 5 series to 5.3 ([#1717][])
- Use USER_KEEP/USER_REJECT for RuleSampler decisions ([#1769][])

### Fixed

- "private method `ruby2_keywords' called" errors ([#1712][], [#1714][])
- Configuration warning when Agent port is a String ([#1720][])
- Ensure internal trace buffer respects its maximum size ([#1715][])
- Remove erroneous maximum resque version support ([#1761][])
- CI-App: Environment variables parsing precedence ([#1745][], [#1763][])
- CI-App: GitHub Metadata Extraction ([#1771][])
- Profiler: Missing thread id for natively created threads ([#1718][])
- Docs: Active Job integration example code ([#1721][]) ([@y-yagi][])

### Refactored

- Redis client patch to use prepend ([#1743][]) ([@justinhoward][])

## [0.53.0] - 2021-10-06

Release notes: https://github.com/DataDog/dd-trace-rb/releases/tag/v0.53.0

Git diff: https://github.com/DataDog/dd-trace-rb/compare/v0.52.0...v0.53.0

### Added

- ActiveJob integration ([#1639][]) ([@bensheldon][])
- Instrument Action Cable subscribe/unsubscribe hooks ([#1674][]) ([@agrobbin][])
- Instrument Sidekiq server internal events (heartbeat, job fetch, and scheduled push) ([#1685][]) ([@agrobbin][])
- Correlate Active Job logs to the active DataDog trace ([#1694][]) ([@agrobbin][])
- Runtime Metrics: Global VM cache statistics ([#1680][])
- Automatically send traces to agent Unix socket if present ([#1700][])
- CI-App: User Provided Git Metadata ([#1662][])
- ActionMailer integration ([#1280][])

### Changed

- Profiler: Set Sinatra resource setting at beginning of request and delay setting fallback resource ([#1628][])
- Profiler: Use most recent event for trace resource name ([#1695][])
- Profiler: Limit number of threads per sample ([#1699][])
- Profiler: Rename `extract_trace_resource` to `endpoint.collection.enabled` ([#1702][])

### Fixed

- Capture Rails exception before default error page is rendered ([#1684][])
- `NoMethodError` in sinatra integration when Tracer middleware is missing ([#1643][], [#1644][]) ([@mscrivo][])
- CI-App: Require `rspec-core` for RSpec integration ([#1654][]) ([@elliterate][])
- CI-App: Use the merge request branch on merge requests ([#1687][]) ([@carlallen][])
- Remove circular dependencies. ([#1668][]) ([@saturnflyer][])
- Links in the Table of Contents ([#1661][]) ([@chychkan][])
- CI-App: Fix CI Visibility Spec Tests ([#1706][])

### Refactored

- Profiler: pprof encoding benchmark and improvements ([#1511][])

## [0.52.0] - 2021-08-09

Release notes: https://github.com/DataDog/dd-trace-rb/releases/tag/v0.52.0

Git diff: https://github.com/DataDog/dd-trace-rb/compare/v0.51.1...v0.52.0

### Added

- Add Sorbet typechecker to dd-trace-rb ([#1607][])

  Note that no inline type signatures were added, to avoid a hard dependency on sorbet.

- Profiler: Add support for annotating profiler stacks with the resource of the active web trace, if any ([#1623][])

  Note that this data is not yet visible on the profiling interface.

- Add error_handler option to GRPC tracer configuration ([#1583][]) ([@fteem][])
- User-friendly handling of slow submissions on shutdown ([#1601][])
- Profiler: Add experimental toggle to disable the profiling native extension ([#1594][])
- Profiler: Bootstrap profiling native extension ([#1584][])

### Changed

- Profiler: Profiling data is no longer reported when there's less than 1 second of data to report ([#1630][])
- Move Grape span resource setting to beginning of request ([#1629][])
- Set resource in Sinatra spans at the beginning of requests, and delay setting fallback resource to end of requests ([#1628][])
- Move Rails span resource setting to beginning of request ([#1626][])
- Make registry a global constant repository ([#1572][])
- Profiler: Remove automatic agentless support ([#1590][])

### Fixed

- Profiler: Fix CPU-time accounting in Profiling when fibers are used ([#1636][])
- Don't set peer.service tag on grpc.server spans ([#1632][])
- CI-App: Fix GitHub actions environment variable extraction ([#1622][])
- Additional Faraday 1.4+ cgroup parsing formats ([#1595][])
- Avoid shipping development cruft files in gem releases ([#1585][])

## [0.51.1] - 2021-07-13

Release notes: https://github.com/DataDog/dd-trace-rb/releases/tag/v0.51.1

Git diff: https://github.com/DataDog/dd-trace-rb/compare/v0.51.0...v0.51.1

### Fixed

- AWS-SDK instrumentation without `aws-sdk-s3` ([#1592][])

## [0.51.0] - 2021-07-12

Release notes: https://github.com/DataDog/dd-trace-rb/releases/tag/v0.51.0

Git diff: https://github.com/DataDog/dd-trace-rb/compare/v0.50.0...v0.51.0

### Added

- Semantic Logger trace correlation injection ([#1566][])
- New and improved Lograge trace correlation injection ([#1555][])
- Profiler: Start profiler on `ddtrace/auto_instrument`
- CI-App: Add runtime and OS information ([#1587][])
- CI-App: Read metadata from local git repository ([#1561][])

### Changed

- Rename `Datadog::Runtime` to `Datadog::Core::Environment` ([#1570][])

  As we prepare the `Datadog` Ruby namespace to better accommodate new products, we are moving a few internal modules to a different location to avoid conflicts.

  None of the affected files are exposed publicly in our documentation, and they are only expected to be used internally and may change at any time, even between patch releases.

  * The following modules have been moved:
  ```ruby
  Datadog::Runtime::Cgroup -> Datadog::Core::Environment::Cgroup
  Datadog::Runtime::ClassCount -> Datadog::Core::Environment::ClassCount
  Datadog::Runtime::Container -> Datadog::Core::Environment::Container
  Datadog::Runtime::GC -> Datadog::Core::Environment::GC
  Datadog::Runtime::Identity -> Datadog::Core::Environment::Identity
  Datadog::Runtime::ObjectSpace -> Datadog::Core::Environment::ObjectSpace
  Datadog::Runtime::Socket -> Datadog::Core::Environment::Socket
  Datadog::Runtime::ThreadCount -> Datadog::Core::Environment::ThreadCount
  ```
  * Most constants from `Datadog::Ext::Runtime` have been moved to a new module: `Datadog::Core::Environment::Ext`.
- Skip CPU time instrumentation if logging gem is detected ([#1557][])

### Fixed

- Initialize `dogstatsd-ruby` in single threaded mode ([#1576][])

  This should alleviate any existing issues with `dogstatsd-ruby` resource leaks.

- Do not use configured `dogstatsd-ruby` instance when it's an incompatible version ([#1560][])
- Ensure tags with special Datadog processing are consistently serialized ([#1556][])
- Profiler: NameError during initialization ([#1552][])

### Refactored
- Improvements to test suite & CI ([#1586][])
- Improvements to documentation ([#1397][])

## [0.50.0] - 2021-06-07

Release notes: https://github.com/DataDog/dd-trace-rb/releases/tag/v0.50.0

Git diff: https://github.com/DataDog/dd-trace-rb/compare/v0.49.0...v0.50.0

### Added

- Add warning, update documentation, for incompatible dogstastd-ruby version ([#1544][][#1533][])
- Add CI mode and Test mode feature ([#1504][])
- Add Gem.loaded_specs fallback behavior if protobuf or dogstatsd-ruby already loaded([#1506][][#1510][])

### Changed

- Declare EOL for Ruby 2.0 support ([#1534][])
- Rename Thread#native_thread_id to #pthread_thread_id to avoid conflict with Ruby 3.1 ([#1537][])

### Fixed

- Fix tracer ignoring value for service tag (service.name) in DD_TAGS ([#1543][])
- Fix nested error reporting to correctly walk clause chain ([#1535][])
- Fix AWS integration to prevent S3 URL presigning from generating a remote request span ([#1494][])
- Fix backtrace handling of exception classes that return nil message ([#1500][]) ([@masato-hi][])

### Refactored

- Cleanup Ruby 2.0 Code (dropping Ruby 2.0 support) ([#1529][][#1523][][#1524][][#1509][][#1507][][#1503][][#1502][])

## [0.49.0] - 2021-05-12

Release notes: https://github.com/DataDog/dd-trace-rb/releases/tag/v0.49.0

Git diff: https://github.com/DataDog/dd-trace-rb/compare/v0.48.0...v0.49.0

### Added

- Add cause to error stack trace ([#1472][])

### Changed

### Fixed

- Prevent double initialization when auto instrumenting non-Rails applications ([#1497][])
- Support kwargs in Ruby 3.0 for sucker_punch ([#1495][]) ([@lloeki][])
- Fargate fixes and Container parsing for CGroups ([#1487][][#1480][][#1475][])
- Fix ActionPack instrumentation `#starts_with?` error([#1489][])
- Doc fixes ([#1473][]) ([@kexoth][])

### Refactored

## [0.48.0] - 2021-04-19

Release notes: https://github.com/DataDog/dd-trace-rb/releases/tag/v0.48.0

Git diff: https://github.com/DataDog/dd-trace-rb/compare/v0.47.0...v0.48.0

### Added

- Makara support with ActiveRecord ([#1447][])
- `tag_body` configuration for Shoryuken ([#1449][]) ([@gkampjes][])

### Changed

- Add deprecation warning for Ruby 2.0 support ([#1441][])

  Support for Ruby 2.0 will be available up to release `0.49.x`, and dropped from release `0.50.0` and greater.
  Users are welcome to continue using version `< 0.50.0` for their Ruby 2.0 deployments going forward.

- Auto instrument Resque workers by default ([#1400][])

### Fixed

- Ensure DD_TRACE_SAMPLE_RATE enables full RuleSampler ([#1416][])
- Fix Fargate 1.4 container ID not being read ([#1457][])
- Correctly close all StatsD clients ([#1429][])

### Refactored
- Improvements to test suite & CI ([#1421][], [#1435][], [#1445][], [#1453][], [#1456][], [#1461][])
- Improvements to documentation ([#1455][])

## [0.47.0] - 2021-03-29

Release notes: https://github.com/DataDog/dd-trace-rb/releases/tag/v0.47.0

Git diff: https://github.com/DataDog/dd-trace-rb/compare/v0.46.0...v0.47.0

### Added

- Document support for httpx integration ([#1396][]) ([@HoneyryderChuck][])
- Schemas to list of supported AWS services ([#1415][]) ([@tomgi][])
- Branch test coverage report ([#1343][])

### Changed

- **BREAKING** Separate Resolver configuration and resolution steps ([#1319][])

  ### ActiveRecord `describes` configuration now supports partial matching

  Partial matching of connection fields (adapter, username, host, port, database) is now allowed. Previously, only an exact match of connections fields would be considered matching. This should help greatly simplify database configuration matching, as you will only need to provide enough fields to correctly separate your distinct database connections.

  If you have a `c.use active_record, describe:` statement in your application that is currently not matching any connections, you might start seeing them match after this release.

  `c.use active_record, describe:` statements that are currently matching a connection will continue to match that same connection.

  You can refer to the [expanded ActiveSupport documentation for details on how to use the new partial matchers and configuration code examples](https://github.com/DataDog/dd-trace-rb/blob/0794be4cd455caf32e7a9c8f79d80a4b77c4087a/docs/GettingStarted.md#active-record).

  ### `Datadog::Contrib::Configuration::Resolver` interface changed

  The interface for `Datadog::Contrib::Configuration::Resolver` has changed: custom configuration resolvers that inherit from ``Datadog::Contrib::Configuration::Resolver`` will need be changed to fulfill the new interface. See [code documentation for `Datadog::Contrib::Configuration::Resolver` for specific API requirements](https://github.com/DataDog/dd-trace-rb/blob/0794be4cd455caf32e7a9c8f79d80a4b77c4087a/lib/ddtrace/contrib/configuration/resolver.rb).


- Remove type check from ThreadLocalContext#local. ([#1399][]) ([@orekyuu][])

### Fixed

- Support for JRuby 9.2.0.0 ([#1409][])
- Failed integration message ([#1394][]) ([@e1senh0rn][])
- Addressed "warning: instance variable [@components][] not initialized" ([#1419][])
- Close /proc/self/cgroup file after reading ([#1414][])
- Improve internal "only once" behavior across the tracer ([#1398][])
- Increase thread-safety during tracer initialization ([#1418][])

### Refactored

- Use MINIMUM_VERSION in resque compatible? check ([#1426][]) ([@mriddle][])
- Lint fixes for Rubocop 1.12.0 release ([#1430][])
- Internal tracer improvements ([#1403][])
- Improvements to test suite & CI ([#1334][], [#1379][], [#1393][], [#1406][], [#1408][], [#1412][], [#1417][], [#1420][], [#1422][], [#1427][], [#1428][], [#1431][], [#1432][])

## [0.46.0] - 2021-03-03

Release notes: https://github.com/DataDog/dd-trace-rb/releases/tag/v0.46.0

Git diff: https://github.com/DataDog/dd-trace-rb/compare/v0.45.0...v0.46.0

### Added

- Add EventBridge to supported AWS services ([#1368][]) ([@tomgi][])
- Add `time_now_provider` configuration option ([#1224][])
  - This new option allows the span `start_time` and `end_time` to be configured in environments that change the default time provider, like with *Timecop*. More information in the [official documentation](https://docs.datadoghq.com/tracing/setup_overview/setup/ruby/#tracer-settings).
- Add name to background threads created by ddtrace ([#1366][])

### Changed

- Rework RSpec instrumentation as separate traces for each test ([#1381][])

### Fixed

- ArgumentError: wrong number of arguments (given 2, expected 0) due to concurrent `require` ([#1306][], [#1354][]) ([@EvNomad][])
- Fix Rails' deprecation warnings ([#1352][])
- Fully populate Rake span fields on exceptions ([#1377][])
- Fix a typo in `httpclient` integration ([#1365][]) ([@y-yagi][])
- Add missing license files for vendor'd code ([#1346][])

### Refactored

- Improvements to test suite & CI ([#1277][], [#1305][], [#1336][], [#1350][], [#1353][], [#1357][], [#1367][], [#1369][], [#1370][], [#1371][], [#1374][], [#1380][])
- Improvements to documentation ([#1332][])

### Removed

- Remove deprecated Datadog::Monkey ([#1341][])
- Remove deprecated Datadog::DeprecatedPin ([#1342][])
- Remove unused Shim/MethodWrapper/MethodWrapping ([#1347][])
- Remove APP_ANALYTICS from tests instrumentation ([#1378][]) ([@AdrianLC][])

## [0.45.0] - 2021-01-26

Release notes: https://github.com/DataDog/dd-trace-rb/releases/tag/v0.45.0

Git diff: https://github.com/DataDog/dd-trace-rb/compare/v0.44.0...v0.45.0

### Added

- Option to auto enable all instrumentations ([#1260][])
- httpclient support ([#1311][]) ([@agrobbin][])

### Changed

- Promote request_queuing out of experimental ([#1320][])
- Safeguards around distributed HTTP propagator ([#1304][])
- Improvements to test integrations ([#1291][], [#1303][], [#1307][])

### Refactored

- Direct object_id lookup for ActiveRecord connections ([#1317][])
- Avoid multiple parsing of Ethon URIs ([#1302][]) ([@callumj][])
- Improvements to test suite & CI ([#1309][], [#1318][], [#1321][], [#1323][], [#1325][], [#1331][])
- Improvements to documentation ([#1326][])

## [0.44.0] - 2021-01-06

Release notes: https://github.com/DataDog/dd-trace-rb/releases/tag/v0.44.0

Git diff: https://github.com/DataDog/dd-trace-rb/compare/v0.43.0...v0.44.0

### Added

- Ruby 3.0 support ([#1281][], [#1296][], [#1298][])
- Rails 6.1 support ([#1295][])
- Qless integration ([#1237][]) ([@sco11morgan][])
- AWS Textract service to AWS integration ([#1270][]) ([@Sticksword][])
- Ability to disable Redis argument capture ([#1276][]) ([@callumj][])
- Upload coverage report to Codecov ([#1289][])

### Changed

- Reduce Runtime Metrics frequency to every 10 seconds ([#1269][])

### Fixed

- Disambiguate resource names for Grape endpoints with shared paths ([#1279][]) ([@pzaich][])
- Remove invalid Jenkins URL from CI integration ([#1283][])

### Refactored

- Reduce memory allocation when unnecessary ([#1273][], [#1275][]) ([@callumj][])
- Improvements to test suite & CI ([#847][], [#1256][], [#1257][], [#1266][], [#1272][], [#1277][], [#1278][], [#1284][], [#1286][], [#1287][], [#1293][], [#1299][])
- Improvements to documentation ([#1262][], [#1263][], [#1264][], [#1267][], [#1268][], [#1297][])

## [0.43.0] - 2020-11-18

Release notes: https://github.com/DataDog/dd-trace-rb/releases/tag/v0.43.0

Git diff: https://github.com/DataDog/dd-trace-rb/compare/v0.42.0...v0.43.0

### Added

- Background job custom error handlers ([#1212][]) ([@norbertnytko][])
- Add "multi" methods instrumentation for Rails cache ([#1217][]) ([@michaelkl][])
- Support custom error status codes for Grape ([#1238][])
- Cucumber integration ([#1216][])
- RSpec integration ([#1234][])
- Validation to `:on_error` argument on `Datadog::Tracer#trace` ([#1220][])

### Changed

- Update `TokenBucket#effective_rate` calculation ([#1236][])

### Fixed

- Avoid writer reinitialization during shutdown ([#1235][], [#1248][])
- Fix configuration multiplexing ([#1204][], [#1227][])
- Fix misnamed B3 distributed headers ([#1226][], [#1229][])
- Correct span type for AWS SDK ([#1233][])
- Correct span type for internal Pin on HTTP clients ([#1239][])
- Reset trace context after fork ([#1225][])

### Refactored

- Improvements to test suite ([#1232][], [#1244][])
- Improvements to documentation ([#1243][], [#1218][]) ([@cjford][])

### Removed

## [0.42.0] - 2020-10-21

Release notes: https://github.com/DataDog/dd-trace-rb/releases/tag/v0.42.0

Git diff: https://github.com/DataDog/dd-trace-rb/compare/v0.41.0...v0.42.0

### Added

- Increase Resque support to include 2.0  ([#1213][]) ([@erict-square][])

- Improve gRPC Propagator to support metadata array values ([#1203][]) ([@mdehoog][])

- Add CPU benchmarks, diagnostics to tests ([#1188][], [#1198][])

- Access active correlation by Thread ([#1200][])

- Improve delayed_job instrumentation ([#1187][]) ([@norbertnytko][])

### Changed

### Fixed

- Improve Rails `log_injection` option to support more Lograge formats ([#1210][]) ([@Supy][])

- Fix Changelog ([#1199][]) ([@y-yagi][])

### Refactored

- Refactor Trace buffer into multiple components ([#1195][])

## [0.41.0] - 2020-09-30

Release notes: https://github.com/DataDog/dd-trace-rb/releases/tag/v0.41.0

Git diff: https://github.com/DataDog/dd-trace-rb/compare/v0.40.0...v0.41.0

### Added

- Improve duration counting using monotonic clock ([#424][], [#1173][]) ([@soulcutter][])

### Changed

- Add peer.service tag to external services and skip tagging external services with language tag for runtime metrics ([#934][], [#935][], [#1180][])
  - This helps support the way runtime metrics are associated with spans in the UI.
- Faster TraceBuffer for CRuby ([#1172][])
- Reduce memory usage during gem startup ([#1090][])
- Reduce memory usage of the HTTP transport ([#1165][])

### Fixed

- Improved prepared statement support for Sequel  integrations ([#1186][])
- Fix Sequel instrumentation when executing literal strings ([#1185][]) ([@matchbookmac][])
- Remove explicit `Logger` class verification ([#1181][]) ([@bartekbsh][])
  - This allows users to pass in a custom logger that does not inherit from `Logger` class.
- Correct tracer buffer metric counting ([#1182][])
- Fix Span#pretty_print for empty duration ([#1183][])

### Refactored

- Improvements to test suite & CI ([#1179][], [#1184][], [#1177][], [#1178][], [#1176][])
- Reduce generated Span ID range to fit in Fixnum ([#1189][])

## [0.40.0] - 2020-09-08

Release notes: https://github.com/DataDog/dd-trace-rb/releases/tag/v0.40.0

Git diff: https://github.com/DataDog/dd-trace-rb/compare/v0.39.0...v0.40.0

### Added

- Rails `log_injection` option to auto enable log correlation ([#1157][])
- Que integration ([#1141][], [#1146][]) ([@hs-bguven][])
- `Components#startup!` hook ([#1151][])
- Code coverage report ([#1159][])
  - Every commit now has a `coverage` CI step that contains the code coverage report. This report can be found in the `Artifacts` tab of that CI step, under `coverage/index.html`.

### Changed

- Use a single top level span for Racecar consumers ([#1150][]) ([@dasch][])

### Fixed

- Sinatra nested modular applications possibly leaking spans ([#1035][], [#1145][])

  * **BREAKING** for nested modular Sinatra applications only:
    ```ruby
    class Nested < Sinatra::Base
    end

    class TopLevel < Sinatra::Base
      use Nested # Nesting happens here
    end
    ```
  * Non-breaking for classic applications nor modular non-nested applications.

  Fixes issues introduced by [#1015][] (in 0.35.0), when we first introduced Sinatra support for modular applications.

  The main issue we had to solve for modular support is how to handle nested applications, as only one application is actually responsible for handling the route. A naive implementation would cause the creation of nested `sinatra.request` spans, even for applications that did not handle the request. This is technically correct, as Sinatra is traversing that middleware, accruing overhead, but that does not aligned with our existing behavior of having a single `sinatra.request` span.

  While trying to achieve backwards-compatibility, we had to resort to a solution that turned out brittle: `sinatra.request` spans had to start in one middleware level and finished it in another. This allowed us to only capture the `sinatra.request` for the matching route, and skip the non-matching one. This caused unexpected issues on some user setups, specially around Sinatra middleware that created spans in between the initialization and closure of `sinatra.request` spans.

  This change now address these implementation issues by creating multiple `sinatra.request`, one for each traversed Sinatra application, even non-matching ones. This instrumentation is more correct, but at the cost of being a breaking change for nested modular applications.

  Please see [#1145][] for more information, and example screenshots on how traces for affected applications will look like.

- Rack/Rails span error propagation with `rescue_from` ([#1155][], [#1162][])
- Prevent logger recursion during startup ([#1158][])
- Race condition on new worker classes ([#1154][])
  - These classes represent future work, and not being used at the moment.

### Refactored

- Run CI tests in parallel ([#1156][])
- Migrate minitest tests to RSpec ([#1127][], [#1128][], [#1133][], [#1149][], [#1152][], [#1153][])
- Improvements to test suite ([#1134][], [#1148][], [#1163][])
- Improvements to documentation ([#1138][])

### Removed

- **Ruby 1.9 support ended, as it transitions from Maintenance to End-Of-Life ([#1137][])**
- GitLab status check when not applicable ([#1160][])
  - Allows for PRs pass all status checks once again. Before this change, a `dd-gitlab/copy_to_s3` check would never leave the "Pending" status. This check tracks the deployment of a commit to an internal testing platform, which currently only happens on `master` branch or when manually triggered internally.

## [0.39.0] - 2020-08-05

Release notes: https://github.com/DataDog/dd-trace-rb/releases/tag/v0.39.0

Git diff: https://github.com/DataDog/dd-trace-rb/compare/v0.38.0...v0.39.0

### Added

- JRuby 9.2 support ([#1126][])
- Sneakers integration ([#1121][]) ([@janz93][])

### Changed

- Consistent environment variables across languages ([#1115][])
- Default logger level from WARN to INFO ([#1120][]) ([@gingerlime][])
  - This change also reduces the startup environment log message to INFO level ([#1104][])

### Fixed

- HTTP::StateError on error responses for http.rb ([#1116][], [#1122][]) ([@evan-waters][])
- Startup log error when using the test adapter ([#1125][], [#1131][]) ([@benhutton][])
- Warning message for Faraday < 1.0 ([#1129][]) ([@fledman][], [@tjwp][])
- Propagate Rails error message to Rack span ([#1124][])

### Refactored

- Improved ActiveRecord documentation ([#1119][])
- Improvements to test suite ([#1105][], [#1118][])

## [0.38.0] - 2020-07-13

Release notes: https://github.com/DataDog/dd-trace-rb/releases/tag/v0.38.0

Git diff: https://github.com/DataDog/dd-trace-rb/compare/v0.37.0...v0.38.0

### Added

- http.rb integration ([#529][], [#853][])
- Kafka integration ([#1070][]) ([@tjwp][])
- Span#set_tags ([#1081][]) ([@DocX][])
- retry_count tag for Sidekiq jobs ([#1089][]) ([@elyalvarado][])
- Startup environment log ([#1104][], [#1109][])
- DD_SITE and DD_API_KEY configuration ([#1107][])

### Changed

- Auto instrument Faraday default connection ([#1057][])
- Sidekiq client middleware is now the same for client and server ([#1099][]) ([@drcapulet][])
- Single pass SpanFilter ([#1071][]) ([@tjwp][])

### Fixed

- Ensure fatal exceptions are propagated ([#1100][])
- Respect child_of: option in Tracer#trace ([#1082][]) ([@DocX][])
- Improve Writer thread safety ([#1091][]) ([@fledman][])

### Refactored

- Improvements to test suite ([#1092][], [#1103][])

## [0.37.0] - 2020-06-24

Release notes: https://github.com/DataDog/dd-trace-rb/releases/tag/v0.37.0

Git diff: https://github.com/DataDog/dd-trace-rb/compare/v0.36.0...v0.37.0

### Refactored

- Documentation improvements regarding Datadog Agent defaults ([#1074][]) ([@cswatt][])
- Improvements to test suite ([#1043][], [#1051][], [#1062][], [#1075][], [#1076][], [#1086][])

### Removed

- **DEPRECATION**: Deprecate Contrib::Configuration::Settings#tracer= ([#1072][], [#1079][])
  - The `tracer:` option is no longer supported for integration configuration. A deprecation warning will be issued when this option is used.
  - Tracer instances are dynamically created when `ddtrace` is reconfigured (through `Datadog.configure{}` calls).

    A reference to a tracer instance cannot be stored as it will be replaced by a new instance during reconfiguration.

    Retrieving the global tracer instance, by invoking `Datadog.tracer`, is the only safe mechanism to acquire the active tracer instance.

    Allowing an integration to set its tracer instance is effectively preventing that integration from dynamically retrieving the current active tracer in the future, thus causing it to record spans in a stale tracer instance. Spans recorded in a stale tracer instance will look disconnected from their parent context.

- **BREAKING**: Remove Pin#tracer= and DeprecatedPin#tracer= ([#1073][])
  - The `Pin` and `DeprecatedPin` are internal tools used to provide more granular configuration for integrations.
  - The APIs being removed are not public nor have been externally documented. The `DeprecatedPin` specifically has been considered deprecated since 0.20.0.
  - This removal is a continuation of [#1079][] above, thus carrying the same rationale.

### Migration

- Remove `tracer` argument provided to integrations (e.g. `c.use :rails, tracer: ...`).
- Remove `tracer` argument provided to `Pin` or `DeprecatedPin` initializers (e.g. `Pin.new(service, tracer: ...)`).
- If you require a custom tracer instance, use a global instance configuration:
    ```ruby
    Datadog.configure do |c|
      c.tracer.instance = custom_tracer
    end
    ```

## [0.36.0] - 2020-05-27

Release notes: https://github.com/DataDog/dd-trace-rb/releases/tag/v0.36.0

Git diff: https://github.com/DataDog/dd-trace-rb/compare/v0.35.2...v0.36.0

### Changed

- Prevent trace components from being re-initialized multiple times during setup ([#1037][])

### Fixed

- Allow Rails patching if Railties are loaded ([#993][], [#1054][]) ([@mustela][], [@bheemreddy181][], [@vramaiah][])
- Pin delegates to default tracer unless configured ([#1041][])

### Refactored

- Improvements to test suite ([#1027][], [#1031][], [#1045][], [#1046][], [#1047][])

## [0.35.2] - 2020-05-08

Release notes: https://github.com/DataDog/dd-trace-rb/releases/tag/v0.35.2

Git diff: https://github.com/DataDog/dd-trace-rb/compare/v0.35.1...v0.35.2

### Fixed

- Internal tracer HTTP requests generating traces ([#1030][], [#1033][]) ([@gingerlime][])
- `Datadog.configure` forcing all options to eager load ([#1032][], [#1034][]) ([@kelvin-acosta][])

## [0.35.1] - 2020-05-05

Release notes: https://github.com/DataDog/dd-trace-rb/releases/tag/v0.35.1

Git diff: https://github.com/DataDog/dd-trace-rb/compare/v0.35.0...v0.35.1

### Fixed

- Components#teardown! NoMethodError ([#1021][], [#1023][]) ([@bzf][])

## [0.35.0] - 2020-04-29

Release notes: https://github.com/DataDog/dd-trace-rb/releases/tag/v0.35.0

Git diff: https://github.com/DataDog/dd-trace-rb/compare/v0.34.2...v0.35.0

### Added

- Chunk large trace payloads before flushing ([#818][], [#840][])
- Support for Sinatra modular apps ([#486][], [#913][], [#1015][]) ([@jpaulgs][], [@tomasv][], [@ZimbiX][])
- active_job support for Resque ([#991][]) ([@stefanahman][], [@psycholein][])
- JRuby 9.2 to CI test matrix ([#995][])
- `TraceWriter` and `AsyncTraceWriter` workers ([#986][])
- Runtime metrics worker ([#988][])

### Changed

- Populate env, service, and version from tags ([#1008][])
- Extract components from configuration ([#996][])
- Extract logger to components ([#997][])
- Extract runtime metrics worker from `Writer` ([#1004][])
- Improvements to Faraday documentation ([#1005][])

### Fixed

- Runtime metrics not starting after #write ([#1010][])

### Refactored

- Improvements to test suite ([#842][], [#1006][], [#1009][])

## [0.34.2] - 2020-04-09

Release notes: https://github.com/DataDog/dd-trace-rb/releases/tag/v0.34.2

Git diff: https://github.com/DataDog/dd-trace-rb/compare/v0.34.1...v0.34.2

### Changed

- Revert Rails applications setting default `env` if none are configured. ([#1000][]) ([@errriclee][])

## [0.34.1] - 2020-04-02

Release notes: https://github.com/DataDog/dd-trace-rb/releases/tag/v0.34.1

Git diff: https://github.com/DataDog/dd-trace-rb/compare/v0.34.0...v0.34.1

### Changed

- Rails applications set default `service` and `env` if none are configured. ([#990][])

### Fixed

- Some configuration settings not applying ([#989][], [#990][]) ([@rahul342][])

## [0.34.0] - 2020-03-31

Release notes: https://github.com/DataDog/dd-trace-rb/releases/tag/v0.34.0

Git diff: https://github.com/DataDog/dd-trace-rb/compare/v0.33.1...v0.34.0

### Added

- `Datadog::Event` for simple pub-sub messaging ([#972][])
- `Datadog::Workers` for trace writing ([#969][], [#973][])
- `_dd.measured` tag to some integrations for more statistics ([#974][])
- `env`, `service`, `version`, `tags` configuration for auto-tagging ([#977][], [#980][], [#982][], [#983][], [#985][])
- Multiplexed configuration for Ethon, Excon, Faraday, HTTP integrations ([#882][], [#953][]) ([@stormsilver][])

### Fixed

- Runtime metrics configuration dropping with new writer ([#967][], [#968][]) ([@ericmustin][])
- Faraday "unexpected middleware" warnings on v0.x ([#965][], [#971][])
- Presto configuration ([#975][])
- Test suite issues ([#981][])

## [0.33.1] - 2020-03-09

Release notes: https://github.com/DataDog/dd-trace-rb/releases/tag/v0.33.1

Git diff: https://github.com/DataDog/dd-trace-rb/compare/v0.33.0...v0.33.1

### Fixed

- NoMethodError when activating instrumentation for non-existent library ([#964][], [#966][]) ([@roccoblues][], [@brafales][])

## [0.33.0] - 2020-03-05

Release notes: https://github.com/DataDog/dd-trace-rb/releases/tag/v0.33.0

Git diff: https://github.com/DataDog/dd-trace-rb/compare/v0.32.0...v0.33.0

### Added

- Instrumentation for [Presto](https://github.com/treasure-data/presto-client-ruby) ([#775][], [#920][], [#961][]) ([@ahammel][], [@ericmustin][])
- Sidekiq job argument tagging ([#933][]) ([@mantrala][])
- Support for multiple Redis services ([#861][], [#937][], [#940][]) ([@mberlanda][])
- Support for Sidekiq w/ Delayed extensions ([#798][], [#942][]) ([@joeyAghion][])
- Setter/reset behavior for configuration options ([#957][])
- Priority sampling rate tag ([#891][])

### Changed

- Enforced minimum version requirements for instrumentation ([#944][])
- RubyGems minimum version requirement 2.0.0 ([#954][]) ([@Joas1988][])
- Relaxed Rack minimum version to 1.1.0 ([#952][])

### Fixed

- AWS instrumentation patching when AWS is partially loaded ([#938][], [#945][]) ([@letiesperon][], [@illdelph][])
- NoMethodError for RuleSampler with priority sampling ([#949][], [#950][]) ([@BabyGroot][])
- Runtime metrics accumulating service names when disabled ([#956][])
- Sidekiq instrumentation incompatibility with Rails 6.0.2 ([#943][], [#947][]) ([@pj0tr][])
- Documentation tweaks ([#948][], [#955][]) ([@mstruve][], [@link04][])
- Various test suite issues ([#930][], [#932][], [#951][], [#960][])

## [0.32.0] - 2020-01-22

Release notes: https://github.com/DataDog/dd-trace-rb/releases/tag/v0.32.0

Git diff: https://github.com/DataDog/dd-trace-rb/compare/v0.31.1...v0.32.0

### Added

- New transport: Datadog::Transport::IO ([#910][])
- Dual License ([#893][], [#921][])

### Changed

- Improved annotation of `net/http` spans during exception ([#888][], [#907][]) ([@djmb][], [@ericmustin][])
- RuleSampler is now the default sampler; no behavior changes by default ([#917][])

### Refactored

- Improved support for multiple tracer instances ([#919][])
- Improvements to test suite ([#909][], [#928][], [#929][])

## [0.31.1] - 2020-01-15

Release notes: https://github.com/DataDog/dd-trace-rb/releases/tag/v0.31.1

Git diff: https://github.com/DataDog/dd-trace-rb/compare/v0.31.0...v0.31.1

### Fixed

- Implement SyncWriter#stop method ([#914][], [#915][]) ([@Yurokle][])
- Fix references to Datadog::Tracer.log ([#912][])
- Ensure http.status_code tag is always a string ([#927][])

### Refactored

- Improvements to test suite & CI ([#911][], [#918][])

## [0.31.0] - 2020-01-07

Release notes: https://github.com/DataDog/dd-trace-rb/releases/tag/v0.31.0

Git diff: https://github.com/DataDog/dd-trace-rb/compare/v0.30.1...v0.31.0

### Added

- Ruby 2.7 support ([#805][], [#896][])
- ActionCable integration ([#132][], [#824][]) ([@renchap][], [@ericmustin][])
- Faraday 1.0 support ([#906][])
- Set resource for Rails template spans ([#855][], [#881][]) ([@djmb][])
- at_exit hook for graceful Tracer shutdown ([#884][])
- Environment variables to configure RuleSampler defaults ([#892][])

### Changed

- Updated partial trace flushing to conform with new back-end requirements ([#845][])
- Store numeric tags as metrics ([#886][])
- Moved logging from Datadog::Tracer to Datadog::Logger ([#880][])
- Changed default RuleSampler rate limit from unlimited to 100/s ([#898][])

### Fixed

- SyncWriter incompatibility with Transport::HTTP::Client ([#903][], [#904][]) ([@Yurokle][])

### Refactored

- Improvements to test suite & CI ([#815][], [#821][], [#841][], [#846][], [#883][], [#895][])

## [0.30.1] - 2019-12-30

Release notes: https://github.com/DataDog/dd-trace-rb/releases/tag/v0.30.1

Git diff: https://github.com/DataDog/dd-trace-rb/compare/v0.30.0...v0.30.1

### Fixed

- NoMethodError when configuring tracer with SyncWriter ([#899][], [#900][]) ([@Yurokle][])
- Spans associated with runtime metrics when disabled ([#885][])

### Refactored

- Improvements to test suite & CI ([#815][], [#821][], [#846][], [#883][], [#890][], [#894][])

## [0.30.0] - 2019-12-04

Release notes: https://github.com/DataDog/dd-trace-rb/releases/tag/v0.30.0

Git diff: https://github.com/DataDog/dd-trace-rb/compare/v0.29.1...v0.30.0

### Added

- Additional tracer health metrics ([#867][])
- Integration patching instrumentation ([#871][])
- Rule-based trace sampling ([#854][])

### Fixed

- Rails template layout name error ([#872][]) ([@djmb][])

## [0.29.1] - 2019-11-26

Release notes: https://github.com/DataDog/dd-trace-rb/releases/tag/v0.29.1

Git diff: https://github.com/DataDog/dd-trace-rb/compare/v0.29.0...v0.29.1

### Fixed

- Priority sampling not activating by default ([#868][])

## [0.29.0] - 2019-11-20

Release notes: https://github.com/DataDog/dd-trace-rb/releases/tag/v0.29.0

Git diff: https://github.com/DataDog/dd-trace-rb/compare/v0.28.0...v0.29.0

### Added

- Tracer health metrics ([#838][], [#859][])

### Changed

- Default trace buffer size from 100 to 1000 ([#865][])
- Rack request start headers to accept more values ([#832][]) ([@JamesHarker][])
- Faraday to apply default instrumentation out-of-the-box ([#786][], [#843][]) ([@mdross95][])

### Fixed

- Synthetics trace context being ignored ([#856][])

### Refactored

- Tracer buffer constants ([#851][])

### Removed

- Some old Ruby 1.9 code ([#819][], [#844][])

## [0.28.0] - 2019-10-01

Release notes: https://github.com/DataDog/dd-trace-rb/releases/tag/v0.28.0

Git diff: https://github.com/DataDog/dd-trace-rb/compare/v0.27.0...v0.28.0

### Added

- Support for Rails 6.0 ([#814][])
- Multiplexing on hostname/port for Dalli ([#823][])
- Support for Redis array arguments ([#796][], [#817][]) ([@brafales][])

### Refactored

- Encapsulate span resource name in Faraday integration ([#811][]) ([@giancarlocosta][])

## [0.27.0] - 2019-09-04

Release notes: https://github.com/DataDog/dd-trace-rb/releases/tag/v0.27.0

Git diff: https://github.com/DataDog/dd-trace-rb/compare/v0.26.0...v0.27.0

Support for Ruby < 2.0 is *removed*. Plan for timeline is as follows:

 - 0.25.0: Support for Ruby < 2.0 is deprecated; retains full feature support.
 - 0.26.0: Last version to support Ruby < 2.0; any new features will not support 1.9.
 - 0.27.0: Support for Ruby < 2.0 is removed.

Version 0.26.x will receive only critical bugfixes for 1 year following the release of 0.26.0 (August 6th, 2020.)

### Added

- Support for Ruby 2.5 & 2.6 ([#800][], [#802][])
- Ethon integration ([#527][], [#778][]) ([@al-kudryavtsev][])

### Refactored

- Rails integration into smaller integrations per component ([#747][], [#762][], [#795][])

### Removed

- Support for Ruby 1.9 ([#791][])

## [0.26.0] - 2019-08-06

Release notes: https://github.com/DataDog/dd-trace-rb/releases/tag/v0.26.0

Git diff: https://github.com/DataDog/dd-trace-rb/compare/v0.25.1...v0.26.0

Support for Ruby < 2.0 is *deprecated*. Plan for timeline is as follows:

 - 0.25.0: Support for Ruby < 2.0 is deprecated; retains full feature support.
 - 0.26.0: Last version to support Ruby < 2.0; any new features will not support 1.9.
 - 0.27.0: Support for Ruby < 2.0 is removed.

Version 0.26.x will receive only critical bugfixes for 1 year following the release of 0.26.0 (August 6th, 2020.)

### Added

- Container ID tagging for containerized environments ([#784][])

### Refactored

- Datadog::Metrics constants ([#789][])

### Removed

- Datadog::HTTPTransport and related components ([#782][])

## [0.25.1] - 2019-07-16

Release notes: https://github.com/DataDog/dd-trace-rb/releases/tag/v0.25.1

Git diff: https://github.com/DataDog/dd-trace-rb/compare/v0.25.0...v0.25.1

### Fixed

- Redis integration not quantizing AUTH command ([#776][])

## [0.25.0] - 2019-06-27

Release notes: https://github.com/DataDog/dd-trace-rb/releases/tag/v0.25.0

Git diff: https://github.com/DataDog/dd-trace-rb/compare/v0.24.0...v0.25.0

Support for Ruby < 2.0 is *deprecated*. Plan for timeline is as follows:

 - 0.25.0: Support for Ruby < 2.0 is deprecated; retains full feature support.
 - 0.26.0: Last version to support Ruby < 2.0; any new features will not support 1.9.
 - 0.27.0: Support for Ruby < 2.0 is removed.

Version 0.26.x will receive only critical bugfixes for 1 year following the release of 0.26.0.

### Added

- Unix socket support for transport layer ([#770][])

### Changed

- Renamed 'ForcedTracing' to 'ManualTracing' ([#765][])

### Fixed

- HTTP headers for distributed tracing sometimes appearing in duplicate ([#768][])

### Refactored

- Transport layer ([#628][])

### Deprecated

- Ruby < 2.0 support ([#771][])
- Use of `Datadog::HTTPTransport` ([#628][])
- Use of `Datadog::Ext::ForcedTracing` ([#765][])

## [0.24.0] - 2019-05-21

Release notes: https://github.com/DataDog/dd-trace-rb/releases/tag/v0.24.0

Git diff: https://github.com/DataDog/dd-trace-rb/compare/v0.23.3...v0.24.0

### Added

- B3 header support ([#753][])
- Hostname tagging option ([#760][])
- Contribution and development guides ([#754][])

## [0.23.3] - 2019-05-16

Release notes: https://github.com/DataDog/dd-trace-rb/releases/tag/v0.23.3

Git diff: https://github.com/DataDog/dd-trace-rb/compare/v0.23.2...v0.23.3

### Fixed

- Integrations initializing tracer at load time ([#756][])

## [0.23.2] - 2019-05-10

Release notes: https://github.com/DataDog/dd-trace-rb/releases/tag/v0.23.2

Git diff: https://github.com/DataDog/dd-trace-rb/compare/v0.23.1...v0.23.2

### Fixed

- Span types for HTTP, web, and some datastore integrations ([#751][])
- AWS integration not patching service-level gems ([#707][], [#752][]) ([@alksl][], [@tonypinder][])
- Rails 6 warning for `parent_name` ([#750][]) ([@sinsoku][])

## [0.23.1] - 2019-05-02

Release notes: https://github.com/DataDog/dd-trace-rb/releases/tag/v0.23.1

Git diff: https://github.com/DataDog/dd-trace-rb/compare/v0.23.0...v0.23.1

### Fixed

- NoMethodError runtime_metrics for SyncWriter ([#748][])

## [0.23.0] - 2019-04-30

Release notes: https://github.com/DataDog/dd-trace-rb/releases/tag/v0.23.0

Git diff: https://github.com/DataDog/dd-trace-rb/compare/v0.22.0...v0.23.0

### Added

- Error status support via tags for OpenTracing ([#739][])
- Forced sampling support via tags ([#720][])

### Fixed

- Wrong return values for Rake integration ([#742][]) ([@Redapted][])

### Removed

- Obsolete service telemetry ([#738][])

## [0.22.0] - 2019-04-15

Release notes: https://github.com/DataDog/dd-trace-rb/releases/tag/v0.22.0

Git diff: https://github.com/DataDog/dd-trace-rb/compare/v0.21.2...v0.22.0

In this release we are adding initial support for the **beta** [Runtime metrics collection](https://docs.datadoghq.com/tracing/advanced/runtime_metrics/?tab=ruby) feature.

### Changed

- Add warning log if an integration is incompatible ([#722][]) ([@ericmustin][])

### Added

- Initial beta support for Runtime metrics collection ([#677][])

## [0.21.2] - 2019-04-10

Release notes: https://github.com/DataDog/dd-trace-rb/releases/tag/v0.21.2

Git diff: https://github.com/DataDog/dd-trace-rb/compare/v0.21.1...v0.21.2

### Changed

- Support Mongo gem 2.5+ ([#729][], [#731][]) ([@ricbartm][])

## [0.21.1] - 2019-03-26

Release notes: https://github.com/DataDog/dd-trace-rb/releases/tag/v0.21.1

Git diff: https://github.com/DataDog/dd-trace-rb/compare/v0.21.0...v0.21.1

### Changed

- Support `TAG_ENABLED` for custom instrumentation with analytics. ([#728][])

## [0.21.0] - 2019-03-20

Release notes: https://github.com/DataDog/dd-trace-rb/releases/tag/v0.21.0

Git diff: https://github.com/DataDog/dd-trace-rb/compare/v0.20.0...v0.21.0

### Added

- Trace analytics support ([#697][], [#715][])
- HTTP after_request span hook ([#716][], [#724][])

### Fixed

- Distributed traces with IDs in 2^64 range being dropped ([#719][])
- Custom logger level forced to warning ([#681][], [#721][]) ([@blaines][], [@ericmustin][])

### Refactored

- Global configuration for tracing into configuration API ([#714][])

## [0.20.0] - 2019-03-07

Release notes: https://github.com/DataDog/dd-trace-rb/releases/tag/v0.20.0

Git diff: https://github.com/DataDog/dd-trace-rb/compare/v0.19.1...v0.20.0

This release will log deprecation warnings for any usage of `Datadog::Pin`.
These changes are backwards compatible, but all integration configuration should be moved away from `Pin` and to the configuration API instead.

### Added

- Propagate synthetics origin header ([#699][])

### Changed

- Enable distributed tracing by default ([#701][])

### Fixed

- Fix Rack http_server.queue spans missing from distributed traces ([#709][])

### Refactored

- Refactor MongoDB to use instrumentation module ([#704][])
- Refactor HTTP to use instrumentation module ([#703][])
- Deprecate GRPC global pin in favor of configuration API ([#702][])
- Deprecate Grape pin in favor of configuration API ([#700][])
- Deprecate Faraday pin in favor of configuration API ([#696][])
- Deprecate Dalli pin in favor of configuration API ([#693][])

## [0.19.1] - 2019-02-07

Release notes: https://github.com/DataDog/dd-trace-rb/releases/tag/v0.19.1

Git diff: https://github.com/DataDog/dd-trace-rb/compare/v0.19.0...v0.19.1

### Added

- Documentation for Lograge implementation ([#683][], [#687][]) ([@nic-lan][])

### Fixed

- Priority sampling dropping spans ([#686][])

## [0.19.0] - 2019-01-22

Release notes: https://github.com/DataDog/dd-trace-rb/releases/tag/v0.19.0

Git diff: https://github.com/DataDog/dd-trace-rb/compare/v0.18.3...v0.19.0

### Added

- Tracer#active_correlation for adding correlation IDs to logs. ([#660][], [#664][], [#673][])
- Opt-in support for `event_sample_rate` tag for some integrations. ([#665][], [#666][])

### Changed

- Priority sampling enabled by default. ([#654][])

## [0.18.3] - 2019-01-17

Release notes: https://github.com/DataDog/dd-trace-rb/releases/tag/v0.18.3

Git diff: https://github.com/DataDog/dd-trace-rb/compare/v0.18.2...v0.18.3

### Fixed

- Mongo `NoMethodError` when no span available during `#failed`. ([#674][], [#675][]) ([@Azure7111][])
- Rack deprecation warnings firing with some 3rd party libraries present. ([#672][])
- Shoryuken resource name when used with ActiveJob. ([#671][]) ([@aurelian][])

## [0.18.2] - 2019-01-03

Release notes: https://github.com/DataDog/dd-trace-rb/releases/tag/v0.18.2

Git diff: https://github.com/DataDog/dd-trace-rb/compare/v0.18.1...v0.18.2

### Fixed

- Unfinished Mongo spans when SASL configured ([#658][]) ([@zachmccormick][])
- Possible performance issue with unexpanded Rails cache keys ([#630][], [#635][]) ([@gingerlime][])

## [0.18.1] - 2018-12-20

Release notes: https://github.com/DataDog/dd-trace-rb/releases/tag/v0.18.1

Git diff: https://github.com/DataDog/dd-trace-rb/compare/v0.18.0...v0.18.1

### Fixed

- ActiveRecord `SystemStackError` with some 3rd party libraries ([#661][], [#662][]) ([@EpiFouloux][], [@tjgrathwell][], [@guizmaii][])

## [0.18.0] - 2018-12-18

Release notes: https://github.com/DataDog/dd-trace-rb/releases/tag/v0.18.0

Git diff: https://github.com/DataDog/dd-trace-rb/compare/v0.17.3...v0.18.0

### Added

- Shoryuken integration ([#538][], [#626][], [#655][]) ([@steveh][], [@JustSnow][])
- Sidekiq client integration ([#602][], [#650][]) ([@dirk][])
- Datadog::Shim for adding instrumentation ([#648][])

### Changed

- Use `DD_AGENT_HOST` and `DD_TRACE_AGENT_PORT` env vars if available ([#631][])
- Inject `:connection` into `sql.active_record` event ([#640][], [#649][], [#656][]) ([@guizmaii][])
- Return default configuration instead of `nil` on miss ([#651][])

## [0.17.3] - 2018-11-29

Release notes: https://github.com/DataDog/dd-trace-rb/releases/tag/v0.17.3

Git diff: https://github.com/DataDog/dd-trace-rb/compare/v0.17.2...v0.17.3

### Fixed

- Bad resource names for Grape::API objects in Grape 1.2.0 ([#639][])
- RestClient raising NoMethodError when response is `nil` ([#636][], [#642][]) ([@frsantos][])
- Rack middleware inserted twice in some Rails applications ([#641][])

## [0.17.2] - 2018-11-23

Release notes: https://github.com/DataDog/dd-trace-rb/releases/tag/v0.17.2

Git diff: https://github.com/DataDog/dd-trace-rb/compare/v0.17.1...v0.17.2

### Fixed

- Resque integration shutting down tracer when forking is disabled ([#637][])

## [0.17.1] - 2018-11-07

Release notes: https://github.com/DataDog/dd-trace-rb/releases/tag/v0.17.1

Git diff: https://github.com/DataDog/dd-trace-rb/compare/v0.17.0...v0.17.1

### Fixed

- RestClient incorrect app type ([#583][]) ([@gaborszakacs][])
- DelayedJob incorrect job name when used with ActiveJob ([#605][]) ([@agirlnamedsophia][])

## [0.17.0] - 2018-10-30

Release notes: https://github.com/DataDog/dd-trace-rb/releases/tag/v0.17.0

Git diff: https://github.com/DataDog/dd-trace-rb/compare/v0.16.1...v0.17.0

### Added

- [BETA] Span memory `allocations` attribute ([#597][]) ([@dasch][])

### Changed

- Use Rack Env to update resource in Rails ([#580][]) ([@dasch][])
- Expand support for Sidekiq to 3.5.4+ ([#593][])
- Expand support for mysql2 to 0.3.21+ ([#578][])

### Refactored

- Upgraded integrations to new API ([#544][])
- Encoding classes into modules ([#598][])

## [0.16.1] - 2018-10-17

Release notes: https://github.com/DataDog/dd-trace-rb/releases/tag/v0.16.1

Git diff: https://github.com/DataDog/dd-trace-rb/compare/v0.16.0...v0.16.1

### Fixed

- Priority sampling response being mishandled ([#591][])
- HTTP open timeout to agent too long ([#582][])

## [0.16.0] - 2018-09-18

Release notes: https://github.com/DataDog/dd-trace-rb/releases/tag/v0.16.0

Git diff: https://github.com/DataDog/dd-trace-rb/compare/v0.15.0...v0.16.0

### Added

- OpenTracing support ([#517][])
- `middleware` option for disabling Rails trace middleware. ([#552][])

## [0.15.0] - 2018-09-12

Release notes: https://github.com/DataDog/dd-trace-rb/releases/tag/v0.15.0

Git diff: https://github.com/DataDog/dd-trace-rb/compare/v0.14.2...v0.15.0

### Added

- Rails 5.2 support ([#535][])
- Context propagation support for `Concurrent::Future` ([#415][], [#496][])

### Fixed

- Grape uninitialized constant TraceMiddleware ([#525][], [#533][]) ([@dim][])
- Signed integer trace and span IDs being discarded in distributed traces ([#530][]) ([@alloy][])

## [0.14.2] - 2018-08-23

Release notes: https://github.com/DataDog/dd-trace-rb/releases/tag/v0.14.2

Git diff: https://github.com/DataDog/dd-trace-rb/compare/v0.14.1...v0.14.2

### Fixed

- Sampling priority from request headers not being used ([#521][])

## [0.14.1] - 2018-08-21

Release notes: https://github.com/DataDog/dd-trace-rb/releases/tag/v0.14.1

Git diff: https://github.com/DataDog/dd-trace-rb/compare/v0.14.0...v0.14.1

### Changed

- Reduce verbosity of connection errors in log ([#515][])

### Fixed

- Sequel 'not a valid integration' error ([#514][], [#516][]) ([@steveh][])

## [0.14.0] - 2018-08-14

Release notes: https://github.com/DataDog/dd-trace-rb/releases/tag/v0.14.0

Git diff: https://github.com/DataDog/dd-trace-rb/compare/v0.13.2...v0.14.0

### Added

- RestClient integration ([#422][], [#460][])
- DelayedJob integration ([#393][] [#444][])
- Version information to integrations ([#483][])
- Tracer#active_root_span helper ([#503][])

### Changed

- Resque to flush traces when Job finishes instead of using SyncWriter ([#474][])
- ActiveRecord to allow configuring multiple databases ([#451][])
- Integrations configuration settings ([#450][], [#452][], [#451][])

### Fixed

- Context propagation for distributed traces when context is full ([#502][])
- Rake shutdown tracer after execution ([#487][]) ([@kissrobber][])
- Deprecation warnings fired using Unicorn ([#508][])

## [0.14.0.rc1] - 2018-08-08

Release notes: https://github.com/DataDog/dd-trace-rb/releases/tag/v0.14.0.rc1

Git diff: https://github.com/DataDog/dd-trace-rb/compare/v0.14.0.beta2...v0.14.0.rc1

### Added

- RestClient integration ([#422][], [#460][])
- Tracer#active_root_span helper ([#503][])

### Fixed

- Context propagation for distributed traces when context is full ([#502][])

## [0.14.0.beta2] - 2018-07-25

Release notes: https://github.com/DataDog/dd-trace-rb/releases/tag/v0.14.0.beta2

Git diff: https://github.com/DataDog/dd-trace-rb/compare/v0.14.0.beta1...v0.14.0.beta2

### Fixed

- Rake shutdown tracer after execution ([#487][]) [@kissrobber][]

## [0.14.0.beta1] - 2018-07-24

Release notes: https://github.com/DataDog/dd-trace-rb/releases/tag/v0.14.0.beta1

Git diff: https://github.com/DataDog/dd-trace-rb/compare/v0.13.1...v0.14.0.beta1

### Changed

- Resque to flush traces when Job finishes instead of using SyncWriter ([#474][])
- ActiveRecord to allow configuring multiple databases ([#451][])
- Integrations configuration settings ([#450][], [#452][], [#451][])

### Fixed

- Ruby warnings during tests ([#499][])
- Tests failing intermittently on Ruby 1.9.3 ([#497][])

### Added

- DelayedJob integration ([#393][] [#444][])
- Version information to integrations ([#483][])

## [0.13.2] - 2018-08-07

Release notes: https://github.com/DataDog/dd-trace-rb/releases/tag/v0.13.2

Git diff: https://github.com/DataDog/dd-trace-rb/compare/v0.13.1...v0.13.2

### Fixed

- Context propagation for distributed traces when context is full ([#502][])

## [0.13.1] - 2018-07-17

Release notes: https://github.com/DataDog/dd-trace-rb/releases/tag/v0.13.1

Git diff: https://github.com/DataDog/dd-trace-rb/compare/v0.13.0...v0.13.1

### Changed

- Configuration class variables don't lazy load ([#477][])
- Default tracer host `localhost` --> `127.0.0.1` ([#466][], [#480][]) ([@NobodysNightmare][])

### Fixed

- Workers not shutting down quickly in some short running processes ([#475][])
- Missing documentation for mysql2 and Rails ([#476][], [#488][])
- Missing variable in rescue block ([#481][]) ([@kitop][])
- Unclosed spans in ActiveSupport::Notifications with multithreading ([#431][], [#478][]) ([@senny][])

## [0.13.0] - 2018-06-20

Release notes: https://github.com/DataDog/dd-trace-rb/releases/tag/v0.13.0

Git diff: https://github.com/DataDog/dd-trace-rb/compare/v0.12.1...v0.13.0

### Added

- Sequel integration (supporting Ruby 2.0+) ([#171][], [#367][]) ([@randy-girard][], [@twe4ked][], [@palin][])
- gRPC integration (supporting Ruby 2.2+) ([#379][], [#403][]) ([@Jared-Prime][])
- ActiveModelSerializers integration ([#340][]) ([@sullimander][])
- Excon integration ([#211][], [#426][]) ([@walterking][], [@jeffjo][])
- Rake integration (supporting Ruby 2.0+, Rake 12.0+) ([#409][])
- Request queuing tracing to Rack (experimental) ([#272][])
- ActiveSupport::Notifications::Event helper for event tracing ([#400][])
- Request and response header tags to Rack ([#389][])
- Request and response header tags to Sinatra ([#427][], [#375][])
- MySQL2 integration ([#453][]) ([@jamiehodge][])
- Sidekiq job delay tag ([#443][], [#418][]) ([@gottfrois][])

### Fixed

- Elasticsearch quantization of ids ([#458][])
- MongoDB to allow quantization of collection name ([#463][])

### Refactored

- Hash quantization into core library ([#410][])
- MongoDB integration to use Hash quantization library ([#463][])

### Changed

- Hash quantization truncates arrays with nested objects ([#463][])

## [0.13.0.beta1] - 2018-05-09

Release notes: https://github.com/DataDog/dd-trace-rb/releases/tag/v0.13.0.beta1

Git diff: https://github.com/DataDog/dd-trace-rb/compare/v0.12.0...v0.13.0.beta1

### Added

- Sequel integration (supporting Ruby 2.0+) ([#171][], [#367][]) ([@randy-girard][], [@twe4ked][], [@palin][])
- gRPC integration (supporting Ruby 2.2+) ([#379][], [#403][]) ([@Jared-Prime][])
- ActiveModelSerializers integration ([#340][]) ([@sullimander][])
- Excon integration ([#211][]) ([@walterking][])
- Rake integration (supporting Ruby 2.0+, Rake 12.0+) ([#409][])
- Request queuing tracing to Rack (experimental) ([#272][])
- ActiveSupport::Notifications::Event helper for event tracing ([#400][])
- Request and response header tags to Rack ([#389][])

### Refactored

- Hash quantization into core library ([#410][])

## [0.12.1] - 2018-06-12

Release notes: https://github.com/DataDog/dd-trace-rb/releases/tag/v0.12.1

Git diff: https://github.com/DataDog/dd-trace-rb/compare/v0.12.0...v0.12.1

### Changed

- Cache configuration `Proxy` objects ([#446][])
- `freeze` more constant strings, to improve memory usage ([#446][])
 - `Utils#truncate` to use slightly less memory ([#446][])

### Fixed

- Net/HTTP integration not permitting `service_name` to be overridden. ([#407][], [#430][]) ([@undergroundwebdesigns][])
- Block not being passed through Elasticsearch client initialization. ([#421][]) ([@shayonj][])
- Devise raising `NoMethodError` when bad login attempts are made. ([#419][], [#420][]) ([@frsantos][])
- AWS spans using wrong resource name ([#374][], [#377][]) ([@jfrancoist][])
- ActionView `NoMethodError` on very long traces. ([#445][], [#447][]) ([@jvalanen][])

### Refactored

- ActionController patching strategy using modules. ([#439][])
- ActionView tracing strategy. ([#445][], [#447][])

## [0.12.0] - 2018-05-08

Release notes: https://github.com/DataDog/dd-trace-rb/releases/tag/v0.12.0

Git diff: https://github.com/DataDog/dd-trace-rb/compare/v0.11.4...v0.12.0

### Added

- GraphQL integration (supporting graphql 1.7.9+) ([#295][])
- ActiveRecord object instantiation tracing ([#311][], [#334][])
- Subscriber module for ActiveSupport::Notifications tracing ([#324][], [#380][], [#390][], [#395][]) ([@dasch][])
- HTTP quantization module ([#384][])
- Partial flushing option to tracer ([#247][], [#397][])

### Changed

- Rack applies URL quantization by default ([#371][])
- Elasticsearch applies body quantization by default ([#362][])
- Context for a single trace now has hard limit of 100,000 spans ([#247][])
- Tags with `rails.db.x` to `active_record.db.x` instead ([#396][])

### Fixed

- Loading the ddtrace library after Rails has fully initialized can result in load errors. ([#357][])
- Some scenarios where `middleware_names` could result in bad resource names ([#354][])
- ActionController instrumentation conflicting with some gems that monkey patch Rails ([#391][])

### Deprecated

- Use of `:datadog_rack_request_span` variable in favor of `'datadog.rack_request_span'` in Rack. ([#365][], [#392][])

### Refactored

- Racecar to use ActiveSupport::Notifications Subscriber module ([#381][])
- Rails to use ActiveRecord integration instead of its own implementation ([#396][])
- ActiveRecord to use ActiveSupport::Notifications Subscriber module ([#396][])

## [0.12.0.rc1] - 2018-04-11

Release notes: https://github.com/DataDog/dd-trace-rb/releases/tag/v0.12.0.rc1

Git diff: https://github.com/DataDog/dd-trace-rb/compare/v0.11.4...v0.12.0.rc1

### Added

- GraphQL integration (supporting graphql 1.7.9+) ([#295][])
- ActiveRecord object instantiation tracing ([#311][], [#334][])
- Subscriber module for ActiveSupport::Notifications tracing ([#324][], [#380][], [#390][], [#395][]) ([@dasch][])
- HTTP quantization module ([#384][])
- Partial flushing option to tracer ([#247][], [#397][])

### Changed

- Rack applies URL quantization by default ([#371][])
- Elasticsearch applies body quantization by default ([#362][])
- Context for a single trace now has hard limit of 100,000 spans ([#247][])
- Tags with `rails.db.x` to `active_record.db.x` instead ([#396][])

### Fixed

- Loading the ddtrace library after Rails has fully initialized can result in load errors. ([#357][])
- Some scenarios where `middleware_names` could result in bad resource names ([#354][])
- ActionController instrumentation conflicting with some gems that monkey patch Rails ([#391][])

### Deprecated

- Use of `:datadog_rack_request_span` variable in favor of `'datadog.rack_request_span'` in Rack. ([#365][], [#392][])

### Refactored

- Racecar to use ActiveSupport::Notifications Subscriber module ([#381][])
- Rails to use ActiveRecord integration instead of its own implementation ([#396][])
- ActiveRecord to use ActiveSupport::Notifications Subscriber module ([#396][])

## [0.12.0.beta2] - 2018-02-28

Release notes: https://github.com/DataDog/dd-trace-rb/releases/tag/v0.12.0.beta2

Git diff: https://github.com/DataDog/dd-trace-rb/compare/v0.12.0.beta1...v0.12.0.beta2

### Fixed

- Loading the ddtrace library after Rails has fully initialized can result in load errors. ([#357][])

## [0.12.0.beta1] - 2018-02-09

Release notes: https://github.com/DataDog/dd-trace-rb/releases/tag/v0.12.0.beta1

Git diff: https://github.com/DataDog/dd-trace-rb/compare/v0.11.2...v0.12.0.beta1

### Added

- GraphQL integration (supporting graphql 1.7.9+) ([#295][])
- ActiveRecord object instantiation tracing ([#311][], [#334][])
- `http.request_id` tag to Rack spans ([#335][])

## [0.11.4] - 2018-03-29

Release notes: https://github.com/DataDog/dd-trace-rb/releases/tag/v0.11.4

Git diff: https://github.com/DataDog/dd-trace-rb/compare/v0.11.3...v0.11.4

### Fixed

- Transport body parsing when downgrading ([#369][])
- Transport incorrectly attempting to apply sampling to service metadata ([#370][])
- `sql.active_record` traces showing incorrect adapter settings when non-default adapter used ([#383][])

## [0.11.3] - 2018-03-06

Release notes: https://github.com/DataDog/dd-trace-rb/releases/tag/v0.11.3

Git diff: https://github.com/DataDog/dd-trace-rb/compare/v0.11.2...v0.11.3

### Added

- CHANGELOG.md ([#350][], [#363][]) ([@awendt][])
- `http.request_id` tag to Rack spans ([#335][])
- Tracer configuration to README.md ([#332][]) ([@noma4i][])

### Fixed

- Extra indentation in README.md ([#349][]) ([@ck3g][])
- `http.url` when Rails raises exceptions ([#351][], [#353][])
- Rails from being patched twice ([#352][])
- 4XX responses from middleware being marked as errors ([#345][])
- Rails exception middleware sometimes not being inserted at correct position ([#345][])
- Processing pipeline documentation typo ([#355][]) ([@MMartyn][])
- Loading the ddtrace library after Rails has fully initialized can result in load errors. ([#357][])
- Use of block syntax with Rails `render` not working ([#359][], [#360][]) ([@dorner][])

## [0.11.2] - 2018-02-02

**Critical update**: `Datadog::Monkey` removed in version 0.11.1. Adds `Datadog::Monkey` back as no-op, deprecated module.

Release notes: https://github.com/DataDog/dd-trace-rb/releases/tag/v0.11.2

Git diff: https://github.com/DataDog/dd-trace-rb/compare/v0.11.1...v0.11.2

### Deprecated

- `Datadog::Monkey` to be no-op and print deprecation warnings.

## [0.11.1] - 2018-01-29

Release notes: https://github.com/DataDog/dd-trace-rb/releases/tag/v0.11.1

Git diff: https://github.com/DataDog/dd-trace-rb/compare/v0.11.0...v0.11.1

### Added

- `http.base_url` tag for Rack applications ([#301][], [#327][])
- `distributed_tracing` option to Sinatra ([#325][])
- `exception_controller` option to Rails ([#320][])

### Changed

- Decoupled Sinatra and ActiveRecord integrations ([#328][], [#330][]) ([@hawknewton][])
- Racecar uses preferred ActiveSupport::Notifications strategy ([#323][])

### Removed

- `Datadog::Monkey` in favor of newer configuration API ([#322][])

### Fixed

- Custom resource names from Rails controllers being overridden ([#321][])
- Custom Rails exception controllers reporting as the resource ([#320][])

## [0.11.0] - 2018-01-17

Release notes: https://github.com/DataDog/dd-trace-rb/releases/tag/v0.11.0

Git diff: https://github.com/DataDog/dd-trace-rb/compare/v0.10.0...v0.11.0

## [0.11.0.beta2] - 2017-12-27

Release notes: https://github.com/DataDog/dd-trace-rb/releases/tag/v0.11.0.beta2

Git diff: https://github.com/DataDog/dd-trace-rb/compare/v0.11.0.beta1...v0.11.0.beta2

## [0.11.0.beta1] - 2017-12-04

Release notes: https://github.com/DataDog/dd-trace-rb/releases/tag/v0.11.0.beta1

Git diff: https://github.com/DataDog/dd-trace-rb/compare/v0.10.0...v0.11.0.beta1

## [0.10.0] - 2017-11-30

Release notes: https://github.com/DataDog/dd-trace-rb/releases/tag/v0.10.0

Git diff: https://github.com/DataDog/dd-trace-rb/compare/v0.9.2...v0.10.0

## [0.9.2] - 2017-11-03

Release notes: https://github.com/DataDog/dd-trace-rb/releases/tag/v0.9.2

Git diff: https://github.com/DataDog/dd-trace-rb/compare/v0.9.1...v0.9.2

## [0.9.1] - 2017-11-02

Release notes: https://github.com/DataDog/dd-trace-rb/releases/tag/v0.9.1

Git diff: https://github.com/DataDog/dd-trace-rb/compare/v0.9.0...v0.9.1

## [0.9.0] - 2017-10-06

Release notes: https://github.com/DataDog/dd-trace-rb/releases/tag/v0.9.0

Git diff: https://github.com/DataDog/dd-trace-rb/compare/v0.8.2...v0.9.0

## [0.8.2] - 2017-09-08

Release notes: https://github.com/DataDog/dd-trace-rb/releases/tag/v0.8.2

Git diff: https://github.com/DataDog/dd-trace-rb/compare/v0.8.1...v0.8.2

## [0.8.1] - 2017-08-10

Release notes: https://github.com/DataDog/dd-trace-rb/releases/tag/v0.8.1

Git diff: https://github.com/DataDog/dd-trace-rb/compare/v0.8.0...v0.8.1

## [0.8.0] - 2017-07-24

Release notes: https://github.com/DataDog/dd-trace-rb/releases/tag/v0.8.0

Git diff: https://github.com/DataDog/dd-trace-rb/compare/v0.7.2...v0.8.0

## [0.7.2] - 2017-05-24

Release notes: https://github.com/DataDog/dd-trace-rb/releases/tag/v0.7.2

Git diff: https://github.com/DataDog/dd-trace-rb/compare/v0.7.1...v0.7.2

## [0.7.1] - 2017-05-10

Release notes: https://github.com/DataDog/dd-trace-rb/releases/tag/v0.7.1

Git diff: https://github.com/DataDog/dd-trace-rb/compare/v0.7.0...v0.7.1

## [0.7.0] - 2017-04-24

Release notes: https://github.com/DataDog/dd-trace-rb/releases/tag/v0.7.0

Git diff: https://github.com/DataDog/dd-trace-rb/compare/v0.6.2...v0.7.0

## [0.6.2] - 2017-04-07

Release notes: https://github.com/DataDog/dd-trace-rb/releases/tag/v0.6.2

Git diff: https://github.com/DataDog/dd-trace-rb/compare/v0.6.1...v0.6.2

## [0.6.1] - 2017-04-05

Release notes: https://github.com/DataDog/dd-trace-rb/releases/tag/v0.6.1

Git diff: https://github.com/DataDog/dd-trace-rb/compare/v0.6.0...v0.6.1

## [0.6.0] - 2017-03-28

Release notes: https://github.com/DataDog/dd-trace-rb/releases/tag/v0.6.0

Git diff: https://github.com/DataDog/dd-trace-rb/compare/v0.5.0...v0.6.0

## [0.5.0] - 2017-03-08

Release notes: https://github.com/DataDog/dd-trace-rb/releases/tag/v0.5.0

Git diff: https://github.com/DataDog/dd-trace-rb/compare/v0.4.3...v0.5.0

## [0.4.3] - 2017-02-17

Release notes: https://github.com/DataDog/dd-trace-rb/releases/tag/v0.4.3

Git diff: https://github.com/DataDog/dd-trace-rb/compare/v0.4.2...v0.4.3

## [0.4.2] - 2017-02-14

Release notes: https://github.com/DataDog/dd-trace-rb/releases/tag/v0.4.2

Git diff: https://github.com/DataDog/dd-trace-rb/compare/v0.4.1...v0.4.2

## [0.4.1] - 2017-02-14

Release notes: https://github.com/DataDog/dd-trace-rb/releases/tag/v0.4.1

Git diff: https://github.com/DataDog/dd-trace-rb/compare/v0.4.0...v0.4.1

## [0.4.0] - 2017-01-24

Release notes: https://github.com/DataDog/dd-trace-rb/releases/tag/v0.4.0

Git diff: https://github.com/DataDog/dd-trace-rb/compare/v0.3.1...v0.4.0

## [0.3.1] - 2017-01-23

Release notes: https://github.com/DataDog/dd-trace-rb/releases/tag/v0.3.1

Git diff: https://github.com/DataDog/dd-trace-rb/compare/v0.3.0...v0.3.1


[Unreleased]: https://github.com/DataDog/dd-trace-rb/compare/v2.19.0...master
[2.19.0]: https://github.com/DataDog/dd-trace-rb/compare/v2.18.0...v2.19.0
[2.18.0]: https://github.com/DataDog/dd-trace-rb/compare/v2.17.0...v2.18.0
[2.17.0]: https://github.com/DataDog/dd-trace-rb/compare/v2.16.0...v2.17.0
[2.16.0]: https://github.com/DataDog/dd-trace-rb/compare/v2.15.0...v2.16.0
[2.15.0]: https://github.com/DataDog/dd-trace-rb/compare/v2.14.0...v2.15.0
[2.14.0]: https://github.com/DataDog/dd-trace-rb/compare/v2.13.0...v2.14.0
[2.13.0]: https://github.com/DataDog/dd-trace-rb/compare/v2.12.2...v2.13.0
[2.12.2]: https://github.com/DataDog/dd-trace-rb/compare/v2.12.1...v2.12.2
[2.12.1]: https://github.com/DataDog/dd-trace-rb/compare/v2.12.0...v2.12.1
[2.12.0]: https://github.com/DataDog/dd-trace-rb/compare/v2.11.0...v2.12.0
[2.11.0]: https://github.com/DataDog/dd-trace-rb/compare/v2.10.0...v2.11.0
[2.10.0]: https://github.com/DataDog/dd-trace-rb/compare/v2.9.0...v2.10.0
[2.9.0]: https://github.com/DataDog/dd-trace-rb/compare/v2.8.0...v2.9.0
[2.8.0]: https://github.com/DataDog/dd-trace-rb/compare/v2.7.1...v2.8.0
[2.7.0]: https://github.com/DataDog/dd-trace-rb/compare/v2.6.0...v2.7.0
[2.6.0]: https://github.com/DataDog/dd-trace-rb/compare/v2.5.0...v2.6.0
[2.5.0]: https://github.com/DataDog/dd-trace-rb/compare/v2.4.0...v2.5.0
[2.4.0]: https://github.com/DataDog/dd-trace-rb/compare/v2.3.0...v2.4.0
[2.3.0]: https://github.com/DataDog/dd-trace-rb/compare/v2.2.0...v2.3.0
[2.2.0]: https://github.com/DataDog/dd-trace-rb/compare/v2.1.0...v2.2.0
[2.1.0]: https://github.com/DataDog/dd-trace-rb/compare/v2.0.0...v2.1.0
[2.0.0]: https://github.com/DataDog/dd-trace-rb/compare/v2.0.0.rc1...v2.0.0
[2.0.0.rc1]: https://github.com/DataDog/dd-trace-rb/compare/v2.0.0.beta2...v2.0.0.rc1
[1.23.0]: https://github.com/DataDog/dd-trace-rb/compare/v1.22.0...v1.23.0
[2.0.0.beta2]: https://github.com/DataDog/dd-trace-rb/compare/v2.0.0.beta1...v2.0.0.beta2
[1.22.0]: https://github.com/DataDog/dd-trace-rb/compare/v1.21.1...v1.22.0
[2.0.0.beta1]: https://github.com/DataDog/dd-trace-rb/compare/v1.21.1...v2.0.0.beta1
[1.21.1]: https://github.com/DataDog/dd-trace-rb/compare/v1.21.0...v1.21.1
[1.21.0]: https://github.com/DataDog/dd-trace-rb/compare/v1.20.0...v1.21.0
[1.20.0]: https://github.com/DataDog/dd-trace-rb/compare/v1.19.0...v1.20.0
[1.19.0]: https://github.com/DataDog/dd-trace-rb/compare/v1.18.0...v1.19.0
[1.18.0]: https://github.com/DataDog/dd-trace-rb/compare/v1.17.0...v1.18.0
[1.17.0]: https://github.com/DataDog/dd-trace-rb/compare/v1.16.2...v1.17.0
[1.16.2]: https://github.com/DataDog/dd-trace-rb/compare/v1.16.1...v1.16.2
[1.16.1]: https://github.com/DataDog/dd-trace-rb/compare/v1.16.0...v1.16.1
[1.16.0]: https://github.com/DataDog/dd-trace-rb/compare/v1.15.0...v1.16.0
[1.15.0]: https://github.com/DataDog/dd-trace-rb/compare/v1.14.0...v1.15.0
[1.14.0]: https://github.com/DataDog/dd-trace-rb/compare/v1.13.1...1.14.0
[1.13.1]: https://github.com/DataDog/dd-trace-rb/compare/v1.13.0...1.13.1
[1.13.0]: https://github.com/DataDog/dd-trace-rb/compare/v1.12.1...v1.13.0
[1.12.1]: https://github.com/DataDog/dd-trace-rb/compare/v1.12.0...v1.12.1
[1.12.0]: https://github.com/DataDog/dd-trace-rb/compare/v1.11.1...v1.12.0
[1.11.1]: https://github.com/DataDog/dd-trace-rb/compare/v1.10.1...v1.11.1
[1.11.0]: https://github.com/DataDog/dd-trace-rb/compare/v1.10.1...v1.11.0
[1.11.0.beta1]: https://github.com/DataDog/dd-trace-rb/compare/v1.10.1...v1.11.0.beta1
[1.10.1]: https://github.com/DataDog/dd-trace-rb/compare/v1.10.0...v1.10.1
[1.10.0]: https://github.com/DataDog/dd-trace-rb/compare/v1.9.0...v1.10.0
[1.9.0]: https://github.com/DataDog/dd-trace-rb/compare/v1.8.0...v1.9.0
[1.8.0]: https://github.com/DataDog/dd-trace-rb/compare/v1.7.0...v1.8.0
[1.7.0]: https://github.com/DataDog/dd-trace-rb/compare/v1.6.1...v1.7.0
[1.6.1]: https://github.com/DataDog/dd-trace-rb/compare/v1.6.0...v1.6.1
[1.6.0]: https://github.com/DataDog/dd-trace-rb/compare/v1.5.2...v1.6.0
[1.5.2]: https://github.com/DataDog/dd-trace-rb/compare/v1.5.1...v1.5.2
[1.5.1]: https://github.com/DataDog/dd-trace-rb/compare/v1.5.0...v1.5.1
[1.5.0]: https://github.com/DataDog/dd-trace-rb/compare/v1.4.2...v1.5.0
[1.4.1]: https://github.com/DataDog/dd-trace-rb/compare/v1.4.1...v1.4.2
[1.4.1]: https://github.com/DataDog/dd-trace-rb/compare/v1.4.0...v1.4.1
[1.4.0]: https://github.com/DataDog/dd-trace-rb/compare/v1.3.0...v1.4.0
[1.3.0]: https://github.com/DataDog/dd-trace-rb/compare/v1.2.0...v1.3.0
[1.2.0]: https://github.com/DataDog/dd-trace-rb/compare/v1.1.0...v1.2.0
[1.1.0]: https://github.com/DataDog/dd-trace-rb/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/DataDog/dd-trace-rb/compare/v1.0.0.beta2...v1.0.0
[1.0.0.beta2]: https://github.com/DataDog/dd-trace-rb/compare/v1.0.0.beta1...v1.0.0.beta2
[1.0.0.beta1]: https://github.com/DataDog/dd-trace-rb/compare/v0.54.2...v1.0.0.beta1
[0.54.2]: https://github.com/DataDog/dd-trace-rb/compare/v0.54.1...v0.54.2
[0.54.1]: https://github.com/DataDog/dd-trace-rb/compare/v0.54.0...v0.54.1
[0.54.0]: https://github.com/DataDog/dd-trace-rb/compare/v0.53.0...v0.54.0
[0.53.0]: https://github.com/DataDog/dd-trace-rb/compare/v0.52.0...v0.53.0
[0.52.0]: https://github.com/DataDog/dd-trace-rb/compare/v0.51.1...v0.52.0
[0.51.1]: https://github.com/DataDog/dd-trace-rb/compare/v0.51.0...v0.51.1
[0.51.0]: https://github.com/DataDog/dd-trace-rb/compare/v0.50.0...v0.51.0
[0.48.0]: https://github.com/DataDog/dd-trace-rb/compare/v0.47.0...v0.48.0
[0.47.0]: https://github.com/DataDog/dd-trace-rb/compare/v0.46.0...v0.47.0
[0.46.0]: https://github.com/DataDog/dd-trace-rb/compare/v0.45.0...v0.46.0
[0.45.0]: https://github.com/DataDog/dd-trace-rb/compare/v0.44.0...v0.45.0
[0.44.0]: https://github.com/DataDog/dd-trace-rb/compare/v0.43.0...v0.44.0
[0.43.0]: https://github.com/DataDog/dd-trace-rb/compare/v0.42.0...v0.43.0
[0.41.0]: https://github.com/DataDog/dd-trace-rb/compare/v0.40.0...v0.41.0
[0.40.0]: https://github.com/DataDog/dd-trace-rb/compare/v0.39.0...v0.40.0
[0.39.0]: https://github.com/DataDog/dd-trace-rb/compare/v0.38.0...v0.39.0
[0.38.0]: https://github.com/DataDog/dd-trace-rb/compare/v0.37.0...v0.38.0
[0.37.0]: https://github.com/DataDog/dd-trace-rb/compare/v0.36.0...v0.37.0
[0.36.0]: https://github.com/DataDog/dd-trace-rb/compare/v0.35.2...v0.36.0
[0.35.2]: https://github.com/DataDog/dd-trace-rb/compare/v0.35.1...v0.35.2
[0.35.1]: https://github.com/DataDog/dd-trace-rb/compare/v0.35.0...v0.35.1
[0.35.0]: https://github.com/DataDog/dd-trace-rb/compare/v0.34.2...v0.35.0
[0.34.2]: https://github.com/DataDog/dd-trace-rb/compare/v0.34.1...v0.34.2
[0.34.1]: https://github.com/DataDog/dd-trace-rb/compare/v0.34.0...v0.34.1
[0.34.0]: https://github.com/DataDog/dd-trace-rb/compare/v0.33.1...v0.34.0
[0.33.1]: https://github.com/DataDog/dd-trace-rb/compare/v0.33.0...v0.33.1
[0.33.0]: https://github.com/DataDog/dd-trace-rb/compare/v0.32.0...v0.33.0
[0.32.0]: https://github.com/DataDog/dd-trace-rb/compare/v0.31.1...v0.32.0
[0.31.1]: https://github.com/DataDog/dd-trace-rb/compare/v0.31.0...v0.31.1
[0.31.0]: https://github.com/DataDog/dd-trace-rb/compare/v0.30.1...v0.31.0
[0.30.1]: https://github.com/DataDog/dd-trace-rb/compare/v0.30.0...v0.30.1
[0.30.0]: https://github.com/DataDog/dd-trace-rb/compare/v0.29.1...v0.30.0
[0.29.1]: https://github.com/DataDog/dd-trace-rb/compare/v0.29.0...v0.29.1
[0.29.0]: https://github.com/DataDog/dd-trace-rb/compare/v0.28.0...v0.29.0
[0.28.0]: https://github.com/DataDog/dd-trace-rb/compare/v0.27.0...v0.28.0
[0.27.0]: https://github.com/DataDog/dd-trace-rb/compare/v0.26.0...v0.27.0
[0.26.0]: https://github.com/DataDog/dd-trace-rb/compare/v0.25.1...v0.26.0
[0.25.1]: https://github.com/DataDog/dd-trace-rb/compare/v0.25.0...v0.25.1
[0.25.0]: https://github.com/DataDog/dd-trace-rb/compare/v0.24.0...v0.25.0
[0.24.0]: https://github.com/DataDog/dd-trace-rb/compare/v0.23.3...v0.24.0
[0.23.3]: https://github.com/DataDog/dd-trace-rb/compare/v0.23.2...v0.23.3
[0.23.2]: https://github.com/DataDog/dd-trace-rb/compare/v0.23.1...v0.23.2
[0.23.1]: https://github.com/DataDog/dd-trace-rb/compare/v0.23.0...v0.23.1
[0.23.0]: https://github.com/DataDog/dd-trace-rb/compare/v0.22.0...v0.23.0
[0.22.0]: https://github.com/DataDog/dd-trace-rb/compare/v0.21.2...v0.22.0
[0.21.2]: https://github.com/DataDog/dd-trace-rb/compare/v0.21.1...v0.21.2
[0.21.1]: https://github.com/DataDog/dd-trace-rb/compare/v0.21.0...v0.21.1
[0.21.0]: https://github.com/DataDog/dd-trace-rb/compare/v0.20.0...v0.21.0
[0.20.0]: https://github.com/DataDog/dd-trace-rb/compare/v0.19.1...v0.20.0
[0.19.1]: https://github.com/DataDog/dd-trace-rb/compare/v0.19.0...v0.19.1
[0.19.0]: https://github.com/DataDog/dd-trace-rb/compare/v0.18.3...v0.19.0
[0.18.3]: https://github.com/DataDog/dd-trace-rb/compare/v0.18.2...v0.18.3
[0.18.2]: https://github.com/DataDog/dd-trace-rb/compare/v0.18.1...v0.18.2
[0.18.1]: https://github.com/DataDog/dd-trace-rb/compare/v0.18.0...v0.18.1
[0.18.0]: https://github.com/DataDog/dd-trace-rb/compare/v0.17.3...v0.18.0
[0.17.3]: https://github.com/DataDog/dd-trace-rb/compare/v0.17.2...v0.17.3
[0.17.2]: https://github.com/DataDog/dd-trace-rb/compare/v0.17.1...v0.17.2
[0.17.1]: https://github.com/DataDog/dd-trace-rb/compare/v0.17.0...v0.17.1
[0.17.0]: https://github.com/DataDog/dd-trace-rb/compare/v0.16.1...v0.17.0
[0.16.1]: https://github.com/DataDog/dd-trace-rb/compare/v0.16.0...v0.16.1
[0.16.0]: https://github.com/DataDog/dd-trace-rb/compare/v0.15.0...v0.16.0
[0.15.0]: https://github.com/DataDog/dd-trace-rb/compare/v0.14.2...v0.15.0
[0.14.2]: https://github.com/DataDog/dd-trace-rb/compare/v0.14.1...v0.14.2
[0.14.1]: https://github.com/DataDog/dd-trace-rb/compare/v0.14.0...v0.14.1
[0.14.0]: https://github.com/DataDog/dd-trace-rb/compare/v0.13.2...v0.14.0
[0.14.0.rc1]: https://github.com/DataDog/dd-trace-rb/compare/v0.14.0.beta2...v0.14.0.rc1
[0.14.0.beta2]: https://github.com/DataDog/dd-trace-rb/compare/v0.14.0.beta1...v0.14.0.beta2
[0.14.0.beta1]: https://github.com/DataDog/dd-trace-rb/compare/v0.13.0...v0.14.0.beta1
[0.13.2]: https://github.com/DataDog/dd-trace-rb/compare/v0.13.1...v0.13.2
[0.13.1]: https://github.com/DataDog/dd-trace-rb/compare/v0.13.0...v0.13.1
[0.13.0]: https://github.com/DataDog/dd-trace-rb/compare/v0.12.1...v0.13.0
[0.13.0.beta1]: https://github.com/DataDog/dd-trace-rb/compare/v0.12.0...v0.13.0.beta1
[0.12.1]: https://github.com/DataDog/dd-trace-rb/compare/v0.12.0...v0.12.1
[0.12.0]: https://github.com/DataDog/dd-trace-rb/compare/v0.11.4...v0.12.0
[0.12.0.rc1]: https://github.com/DataDog/dd-trace-rb/compare/v0.11.4...v0.12.0.rc1
[0.12.0.beta2]: https://github.com/DataDog/dd-trace-rb/compare/v0.12.0.beta1...v0.12.0.beta2
[0.12.0.beta1]: https://github.com/DataDog/dd-trace-rb/compare/v0.11.2...v0.12.0.beta1
[0.11.4]: https://github.com/DataDog/dd-trace-rb/compare/v0.11.3...v0.11.4
[0.11.3]: https://github.com/DataDog/dd-trace-rb/compare/v0.11.2...v0.11.3
[0.11.2]: https://github.com/DataDog/dd-trace-rb/compare/v0.11.1...v0.11.2
[0.11.1]: https://github.com/DataDog/dd-trace-rb/compare/v0.11.0...v0.11.1
[0.11.0]: https://github.com/DataDog/dd-trace-rb/compare/v0.10.0...v0.11.0
[0.11.0.beta2]: https://github.com/DataDog/dd-trace-rb/compare/v0.11.0.beta1...v0.11.0.beta2
[0.11.0.beta1]: https://github.com/DataDog/dd-trace-rb/compare/v0.10.0...v0.11.0.beta1
[0.10.0]: https://github.com/DataDog/dd-trace-rb/compare/v0.9.2...v0.10.0
[0.9.2]: https://github.com/DataDog/dd-trace-rb/compare/v0.9.1...v0.9.2
[0.9.1]: https://github.com/DataDog/dd-trace-rb/compare/v0.9.0...v0.9.1
[0.9.0]: https://github.com/DataDog/dd-trace-rb/compare/v0.8.2...v0.9.0
[0.8.2]: https://github.com/DataDog/dd-trace-rb/compare/v0.8.1...v0.8.2
[0.8.1]: https://github.com/DataDog/dd-trace-rb/compare/v0.8.0...v0.8.1
[0.8.0]: https://github.com/DataDog/dd-trace-rb/compare/v0.7.2...v0.8.0
[0.7.2]: https://github.com/DataDog/dd-trace-rb/compare/v0.7.1...v0.7.2
[0.7.1]: https://github.com/DataDog/dd-trace-rb/compare/v0.7.0...v0.7.1
[0.7.0]: https://github.com/DataDog/dd-trace-rb/compare/v0.6.2...v0.7.0
[0.6.2]: https://github.com/DataDog/dd-trace-rb/compare/v0.6.1...v0.6.2
[0.6.1]: https://github.com/DataDog/dd-trace-rb/compare/v0.6.0...v0.6.1
[0.6.0]: https://github.com/DataDog/dd-trace-rb/compare/v0.5.0...v0.6.0
[0.5.0]: https://github.com/DataDog/dd-trace-rb/compare/v0.4.3...v0.5.0
[0.4.3]: https://github.com/DataDog/dd-trace-rb/compare/v0.4.2...v0.4.3
[0.4.2]: https://github.com/DataDog/dd-trace-rb/compare/v0.4.1...v0.4.2
[0.4.1]: https://github.com/DataDog/dd-trace-rb/compare/v0.4.0...v0.4.1
[0.4.0]: https://github.com/DataDog/dd-trace-rb/compare/v0.3.1...v0.4.0
[0.3.1]: https://github.com/DataDog/dd-trace-rb/compare/v0.3.0...v0.3.1
[0.3.0]: https://github.com/DataDog/dd-trace-rb/compare/v0.2.0...v0.3.0
[0.2.0]: https://github.com/DataDog/dd-trace-rb/compare/v0.1.5...v0.2.0
[0.1.5]: https://github.com/DataDog/dd-trace-rb/compare/v0.1.4...v0.1.5
[0.1.4]: https://github.com/DataDog/dd-trace-rb/compare/v0.1.3...v0.1.4
[0.1.3]: https://github.com/DataDog/dd-trace-rb/compare/v0.1.2...v0.1.3
[0.1.2]: https://github.com/DataDog/dd-trace-rb/compare/v0.1.1...v0.1.2
[0.1.1]: https://github.com/DataDog/dd-trace-rb/compare/v0.1.0...v0.1.1

<!--- The following link definition list is generated by PimpMyChangelog --->
[#132]: https://github.com/DataDog/dd-trace-rb/issues/132
[#171]: https://github.com/DataDog/dd-trace-rb/issues/171
[#211]: https://github.com/DataDog/dd-trace-rb/issues/211
[#247]: https://github.com/DataDog/dd-trace-rb/issues/247
[#272]: https://github.com/DataDog/dd-trace-rb/issues/272
[#295]: https://github.com/DataDog/dd-trace-rb/issues/295
[#301]: https://github.com/DataDog/dd-trace-rb/issues/301
[#311]: https://github.com/DataDog/dd-trace-rb/issues/311
[#320]: https://github.com/DataDog/dd-trace-rb/issues/320
[#321]: https://github.com/DataDog/dd-trace-rb/issues/321
[#322]: https://github.com/DataDog/dd-trace-rb/issues/322
[#323]: https://github.com/DataDog/dd-trace-rb/issues/323
[#324]: https://github.com/DataDog/dd-trace-rb/issues/324
[#325]: https://github.com/DataDog/dd-trace-rb/issues/325
[#327]: https://github.com/DataDog/dd-trace-rb/issues/327
[#328]: https://github.com/DataDog/dd-trace-rb/issues/328
[#330]: https://github.com/DataDog/dd-trace-rb/issues/330
[#332]: https://github.com/DataDog/dd-trace-rb/issues/332
[#334]: https://github.com/DataDog/dd-trace-rb/issues/334
[#335]: https://github.com/DataDog/dd-trace-rb/issues/335
[#340]: https://github.com/DataDog/dd-trace-rb/issues/340
[#345]: https://github.com/DataDog/dd-trace-rb/issues/345
[#349]: https://github.com/DataDog/dd-trace-rb/issues/349
[#350]: https://github.com/DataDog/dd-trace-rb/issues/350
[#351]: https://github.com/DataDog/dd-trace-rb/issues/351
[#352]: https://github.com/DataDog/dd-trace-rb/issues/352
[#353]: https://github.com/DataDog/dd-trace-rb/issues/353
[#354]: https://github.com/DataDog/dd-trace-rb/issues/354
[#355]: https://github.com/DataDog/dd-trace-rb/issues/355
[#357]: https://github.com/DataDog/dd-trace-rb/issues/357
[#359]: https://github.com/DataDog/dd-trace-rb/issues/359
[#360]: https://github.com/DataDog/dd-trace-rb/issues/360
[#362]: https://github.com/DataDog/dd-trace-rb/issues/362
[#363]: https://github.com/DataDog/dd-trace-rb/issues/363
[#365]: https://github.com/DataDog/dd-trace-rb/issues/365
[#367]: https://github.com/DataDog/dd-trace-rb/issues/367
[#369]: https://github.com/DataDog/dd-trace-rb/issues/369
[#370]: https://github.com/DataDog/dd-trace-rb/issues/370
[#371]: https://github.com/DataDog/dd-trace-rb/issues/371
[#374]: https://github.com/DataDog/dd-trace-rb/issues/374
[#375]: https://github.com/DataDog/dd-trace-rb/issues/375
[#377]: https://github.com/DataDog/dd-trace-rb/issues/377
[#379]: https://github.com/DataDog/dd-trace-rb/issues/379
[#380]: https://github.com/DataDog/dd-trace-rb/issues/380
[#381]: https://github.com/DataDog/dd-trace-rb/issues/381
[#383]: https://github.com/DataDog/dd-trace-rb/issues/383
[#384]: https://github.com/DataDog/dd-trace-rb/issues/384
[#389]: https://github.com/DataDog/dd-trace-rb/issues/389
[#390]: https://github.com/DataDog/dd-trace-rb/issues/390
[#391]: https://github.com/DataDog/dd-trace-rb/issues/391
[#392]: https://github.com/DataDog/dd-trace-rb/issues/392
[#393]: https://github.com/DataDog/dd-trace-rb/issues/393
[#395]: https://github.com/DataDog/dd-trace-rb/issues/395
[#396]: https://github.com/DataDog/dd-trace-rb/issues/396
[#397]: https://github.com/DataDog/dd-trace-rb/issues/397
[#400]: https://github.com/DataDog/dd-trace-rb/issues/400
[#403]: https://github.com/DataDog/dd-trace-rb/issues/403
[#407]: https://github.com/DataDog/dd-trace-rb/issues/407
[#409]: https://github.com/DataDog/dd-trace-rb/issues/409
[#410]: https://github.com/DataDog/dd-trace-rb/issues/410
[#415]: https://github.com/DataDog/dd-trace-rb/issues/415
[#418]: https://github.com/DataDog/dd-trace-rb/issues/418
[#419]: https://github.com/DataDog/dd-trace-rb/issues/419
[#420]: https://github.com/DataDog/dd-trace-rb/issues/420
[#421]: https://github.com/DataDog/dd-trace-rb/issues/421
[#422]: https://github.com/DataDog/dd-trace-rb/issues/422
[#424]: https://github.com/DataDog/dd-trace-rb/issues/424
[#426]: https://github.com/DataDog/dd-trace-rb/issues/426
[#427]: https://github.com/DataDog/dd-trace-rb/issues/427
[#430]: https://github.com/DataDog/dd-trace-rb/issues/430
[#431]: https://github.com/DataDog/dd-trace-rb/issues/431
[#439]: https://github.com/DataDog/dd-trace-rb/issues/439
[#443]: https://github.com/DataDog/dd-trace-rb/issues/443
[#444]: https://github.com/DataDog/dd-trace-rb/issues/444
[#445]: https://github.com/DataDog/dd-trace-rb/issues/445
[#446]: https://github.com/DataDog/dd-trace-rb/issues/446
[#447]: https://github.com/DataDog/dd-trace-rb/issues/447
[#450]: https://github.com/DataDog/dd-trace-rb/issues/450
[#451]: https://github.com/DataDog/dd-trace-rb/issues/451
[#452]: https://github.com/DataDog/dd-trace-rb/issues/452
[#453]: https://github.com/DataDog/dd-trace-rb/issues/453
[#458]: https://github.com/DataDog/dd-trace-rb/issues/458
[#460]: https://github.com/DataDog/dd-trace-rb/issues/460
[#463]: https://github.com/DataDog/dd-trace-rb/issues/463
[#466]: https://github.com/DataDog/dd-trace-rb/issues/466
[#474]: https://github.com/DataDog/dd-trace-rb/issues/474
[#475]: https://github.com/DataDog/dd-trace-rb/issues/475
[#476]: https://github.com/DataDog/dd-trace-rb/issues/476
[#477]: https://github.com/DataDog/dd-trace-rb/issues/477
[#478]: https://github.com/DataDog/dd-trace-rb/issues/478
[#480]: https://github.com/DataDog/dd-trace-rb/issues/480
[#481]: https://github.com/DataDog/dd-trace-rb/issues/481
[#483]: https://github.com/DataDog/dd-trace-rb/issues/483
[#486]: https://github.com/DataDog/dd-trace-rb/issues/486
[#487]: https://github.com/DataDog/dd-trace-rb/issues/487
[#488]: https://github.com/DataDog/dd-trace-rb/issues/488
[#496]: https://github.com/DataDog/dd-trace-rb/issues/496
[#497]: https://github.com/DataDog/dd-trace-rb/issues/497
[#499]: https://github.com/DataDog/dd-trace-rb/issues/499
[#502]: https://github.com/DataDog/dd-trace-rb/issues/502
[#503]: https://github.com/DataDog/dd-trace-rb/issues/503
[#508]: https://github.com/DataDog/dd-trace-rb/issues/508
[#514]: https://github.com/DataDog/dd-trace-rb/issues/514
[#515]: https://github.com/DataDog/dd-trace-rb/issues/515
[#516]: https://github.com/DataDog/dd-trace-rb/issues/516
[#517]: https://github.com/DataDog/dd-trace-rb/issues/517
[#521]: https://github.com/DataDog/dd-trace-rb/issues/521
[#525]: https://github.com/DataDog/dd-trace-rb/issues/525
[#527]: https://github.com/DataDog/dd-trace-rb/issues/527
[#529]: https://github.com/DataDog/dd-trace-rb/issues/529
[#530]: https://github.com/DataDog/dd-trace-rb/issues/530
[#533]: https://github.com/DataDog/dd-trace-rb/issues/533
[#535]: https://github.com/DataDog/dd-trace-rb/issues/535
[#538]: https://github.com/DataDog/dd-trace-rb/issues/538
[#544]: https://github.com/DataDog/dd-trace-rb/issues/544
[#552]: https://github.com/DataDog/dd-trace-rb/issues/552
[#578]: https://github.com/DataDog/dd-trace-rb/issues/578
[#580]: https://github.com/DataDog/dd-trace-rb/issues/580
[#582]: https://github.com/DataDog/dd-trace-rb/issues/582
[#583]: https://github.com/DataDog/dd-trace-rb/issues/583
[#591]: https://github.com/DataDog/dd-trace-rb/issues/591
[#593]: https://github.com/DataDog/dd-trace-rb/issues/593
[#597]: https://github.com/DataDog/dd-trace-rb/issues/597
[#598]: https://github.com/DataDog/dd-trace-rb/issues/598
[#602]: https://github.com/DataDog/dd-trace-rb/issues/602
[#605]: https://github.com/DataDog/dd-trace-rb/issues/605
[#626]: https://github.com/DataDog/dd-trace-rb/issues/626
[#628]: https://github.com/DataDog/dd-trace-rb/issues/628
[#630]: https://github.com/DataDog/dd-trace-rb/issues/630
[#631]: https://github.com/DataDog/dd-trace-rb/issues/631
[#635]: https://github.com/DataDog/dd-trace-rb/issues/635
[#636]: https://github.com/DataDog/dd-trace-rb/issues/636
[#637]: https://github.com/DataDog/dd-trace-rb/issues/637
[#639]: https://github.com/DataDog/dd-trace-rb/issues/639
[#640]: https://github.com/DataDog/dd-trace-rb/issues/640
[#641]: https://github.com/DataDog/dd-trace-rb/issues/641
[#642]: https://github.com/DataDog/dd-trace-rb/issues/642
[#648]: https://github.com/DataDog/dd-trace-rb/issues/648
[#649]: https://github.com/DataDog/dd-trace-rb/issues/649
[#650]: https://github.com/DataDog/dd-trace-rb/issues/650
[#651]: https://github.com/DataDog/dd-trace-rb/issues/651
[#654]: https://github.com/DataDog/dd-trace-rb/issues/654
[#655]: https://github.com/DataDog/dd-trace-rb/issues/655
[#656]: https://github.com/DataDog/dd-trace-rb/issues/656
[#658]: https://github.com/DataDog/dd-trace-rb/issues/658
[#660]: https://github.com/DataDog/dd-trace-rb/issues/660
[#661]: https://github.com/DataDog/dd-trace-rb/issues/661
[#662]: https://github.com/DataDog/dd-trace-rb/issues/662
[#664]: https://github.com/DataDog/dd-trace-rb/issues/664
[#665]: https://github.com/DataDog/dd-trace-rb/issues/665
[#666]: https://github.com/DataDog/dd-trace-rb/issues/666
[#671]: https://github.com/DataDog/dd-trace-rb/issues/671
[#672]: https://github.com/DataDog/dd-trace-rb/issues/672
[#673]: https://github.com/DataDog/dd-trace-rb/issues/673
[#674]: https://github.com/DataDog/dd-trace-rb/issues/674
[#675]: https://github.com/DataDog/dd-trace-rb/issues/675
[#677]: https://github.com/DataDog/dd-trace-rb/issues/677
[#681]: https://github.com/DataDog/dd-trace-rb/issues/681
[#683]: https://github.com/DataDog/dd-trace-rb/issues/683
[#686]: https://github.com/DataDog/dd-trace-rb/issues/686
[#687]: https://github.com/DataDog/dd-trace-rb/issues/687
[#693]: https://github.com/DataDog/dd-trace-rb/issues/693
[#696]: https://github.com/DataDog/dd-trace-rb/issues/696
[#697]: https://github.com/DataDog/dd-trace-rb/issues/697
[#699]: https://github.com/DataDog/dd-trace-rb/issues/699
[#700]: https://github.com/DataDog/dd-trace-rb/issues/700
[#701]: https://github.com/DataDog/dd-trace-rb/issues/701
[#702]: https://github.com/DataDog/dd-trace-rb/issues/702
[#703]: https://github.com/DataDog/dd-trace-rb/issues/703
[#704]: https://github.com/DataDog/dd-trace-rb/issues/704
[#707]: https://github.com/DataDog/dd-trace-rb/issues/707
[#709]: https://github.com/DataDog/dd-trace-rb/issues/709
[#714]: https://github.com/DataDog/dd-trace-rb/issues/714
[#715]: https://github.com/DataDog/dd-trace-rb/issues/715
[#716]: https://github.com/DataDog/dd-trace-rb/issues/716
[#719]: https://github.com/DataDog/dd-trace-rb/issues/719
[#720]: https://github.com/DataDog/dd-trace-rb/issues/720
[#721]: https://github.com/DataDog/dd-trace-rb/issues/721
[#722]: https://github.com/DataDog/dd-trace-rb/issues/722
[#724]: https://github.com/DataDog/dd-trace-rb/issues/724
[#728]: https://github.com/DataDog/dd-trace-rb/issues/728
[#729]: https://github.com/DataDog/dd-trace-rb/issues/729
[#731]: https://github.com/DataDog/dd-trace-rb/issues/731
[#738]: https://github.com/DataDog/dd-trace-rb/issues/738
[#739]: https://github.com/DataDog/dd-trace-rb/issues/739
[#742]: https://github.com/DataDog/dd-trace-rb/issues/742
[#747]: https://github.com/DataDog/dd-trace-rb/issues/747
[#748]: https://github.com/DataDog/dd-trace-rb/issues/748
[#750]: https://github.com/DataDog/dd-trace-rb/issues/750
[#751]: https://github.com/DataDog/dd-trace-rb/issues/751
[#752]: https://github.com/DataDog/dd-trace-rb/issues/752
[#753]: https://github.com/DataDog/dd-trace-rb/issues/753
[#754]: https://github.com/DataDog/dd-trace-rb/issues/754
[#756]: https://github.com/DataDog/dd-trace-rb/issues/756
[#757]: https://github.com/DataDog/dd-trace-rb/issues/757
[#760]: https://github.com/DataDog/dd-trace-rb/issues/760
[#762]: https://github.com/DataDog/dd-trace-rb/issues/762
[#765]: https://github.com/DataDog/dd-trace-rb/issues/765
[#768]: https://github.com/DataDog/dd-trace-rb/issues/768
[#770]: https://github.com/DataDog/dd-trace-rb/issues/770
[#771]: https://github.com/DataDog/dd-trace-rb/issues/771
[#775]: https://github.com/DataDog/dd-trace-rb/issues/775
[#776]: https://github.com/DataDog/dd-trace-rb/issues/776
[#778]: https://github.com/DataDog/dd-trace-rb/issues/778
[#782]: https://github.com/DataDog/dd-trace-rb/issues/782
[#784]: https://github.com/DataDog/dd-trace-rb/issues/784
[#786]: https://github.com/DataDog/dd-trace-rb/issues/786
[#789]: https://github.com/DataDog/dd-trace-rb/issues/789
[#791]: https://github.com/DataDog/dd-trace-rb/issues/791
[#795]: https://github.com/DataDog/dd-trace-rb/issues/795
[#796]: https://github.com/DataDog/dd-trace-rb/issues/796
[#798]: https://github.com/DataDog/dd-trace-rb/issues/798
[#800]: https://github.com/DataDog/dd-trace-rb/issues/800
[#802]: https://github.com/DataDog/dd-trace-rb/issues/802
[#805]: https://github.com/DataDog/dd-trace-rb/issues/805
[#811]: https://github.com/DataDog/dd-trace-rb/issues/811
[#814]: https://github.com/DataDog/dd-trace-rb/issues/814
[#815]: https://github.com/DataDog/dd-trace-rb/issues/815
[#817]: https://github.com/DataDog/dd-trace-rb/issues/817
[#818]: https://github.com/DataDog/dd-trace-rb/issues/818
[#819]: https://github.com/DataDog/dd-trace-rb/issues/819
[#821]: https://github.com/DataDog/dd-trace-rb/issues/821
[#823]: https://github.com/DataDog/dd-trace-rb/issues/823
[#824]: https://github.com/DataDog/dd-trace-rb/issues/824
[#832]: https://github.com/DataDog/dd-trace-rb/issues/832
[#838]: https://github.com/DataDog/dd-trace-rb/issues/838
[#840]: https://github.com/DataDog/dd-trace-rb/issues/840
[#841]: https://github.com/DataDog/dd-trace-rb/issues/841
[#842]: https://github.com/DataDog/dd-trace-rb/issues/842
[#843]: https://github.com/DataDog/dd-trace-rb/issues/843
[#844]: https://github.com/DataDog/dd-trace-rb/issues/844
[#845]: https://github.com/DataDog/dd-trace-rb/issues/845
[#846]: https://github.com/DataDog/dd-trace-rb/issues/846
[#847]: https://github.com/DataDog/dd-trace-rb/issues/847
[#851]: https://github.com/DataDog/dd-trace-rb/issues/851
[#853]: https://github.com/DataDog/dd-trace-rb/issues/853
[#854]: https://github.com/DataDog/dd-trace-rb/issues/854
[#855]: https://github.com/DataDog/dd-trace-rb/issues/855
[#856]: https://github.com/DataDog/dd-trace-rb/issues/856
[#859]: https://github.com/DataDog/dd-trace-rb/issues/859
[#861]: https://github.com/DataDog/dd-trace-rb/issues/861
[#865]: https://github.com/DataDog/dd-trace-rb/issues/865
[#867]: https://github.com/DataDog/dd-trace-rb/issues/867
[#868]: https://github.com/DataDog/dd-trace-rb/issues/868
[#871]: https://github.com/DataDog/dd-trace-rb/issues/871
[#872]: https://github.com/DataDog/dd-trace-rb/issues/872
[#880]: https://github.com/DataDog/dd-trace-rb/issues/880
[#881]: https://github.com/DataDog/dd-trace-rb/issues/881
[#882]: https://github.com/DataDog/dd-trace-rb/issues/882
[#883]: https://github.com/DataDog/dd-trace-rb/issues/883
[#884]: https://github.com/DataDog/dd-trace-rb/issues/884
[#885]: https://github.com/DataDog/dd-trace-rb/issues/885
[#886]: https://github.com/DataDog/dd-trace-rb/issues/886
[#888]: https://github.com/DataDog/dd-trace-rb/issues/888
[#890]: https://github.com/DataDog/dd-trace-rb/issues/890
[#891]: https://github.com/DataDog/dd-trace-rb/issues/891
[#892]: https://github.com/DataDog/dd-trace-rb/issues/892
[#893]: https://github.com/DataDog/dd-trace-rb/issues/893
[#894]: https://github.com/DataDog/dd-trace-rb/issues/894
[#895]: https://github.com/DataDog/dd-trace-rb/issues/895
[#896]: https://github.com/DataDog/dd-trace-rb/issues/896
[#898]: https://github.com/DataDog/dd-trace-rb/issues/898
[#899]: https://github.com/DataDog/dd-trace-rb/issues/899
[#900]: https://github.com/DataDog/dd-trace-rb/issues/900
[#903]: https://github.com/DataDog/dd-trace-rb/issues/903
[#904]: https://github.com/DataDog/dd-trace-rb/issues/904
[#906]: https://github.com/DataDog/dd-trace-rb/issues/906
[#907]: https://github.com/DataDog/dd-trace-rb/issues/907
[#909]: https://github.com/DataDog/dd-trace-rb/issues/909
[#910]: https://github.com/DataDog/dd-trace-rb/issues/910
[#911]: https://github.com/DataDog/dd-trace-rb/issues/911
[#912]: https://github.com/DataDog/dd-trace-rb/issues/912
[#913]: https://github.com/DataDog/dd-trace-rb/issues/913
[#914]: https://github.com/DataDog/dd-trace-rb/issues/914
[#915]: https://github.com/DataDog/dd-trace-rb/issues/915
[#917]: https://github.com/DataDog/dd-trace-rb/issues/917
[#918]: https://github.com/DataDog/dd-trace-rb/issues/918
[#919]: https://github.com/DataDog/dd-trace-rb/issues/919
[#920]: https://github.com/DataDog/dd-trace-rb/issues/920
[#921]: https://github.com/DataDog/dd-trace-rb/issues/921
[#927]: https://github.com/DataDog/dd-trace-rb/issues/927
[#928]: https://github.com/DataDog/dd-trace-rb/issues/928
[#929]: https://github.com/DataDog/dd-trace-rb/issues/929
[#930]: https://github.com/DataDog/dd-trace-rb/issues/930
[#932]: https://github.com/DataDog/dd-trace-rb/issues/932
[#933]: https://github.com/DataDog/dd-trace-rb/issues/933
[#934]: https://github.com/DataDog/dd-trace-rb/issues/934
[#935]: https://github.com/DataDog/dd-trace-rb/issues/935
[#937]: https://github.com/DataDog/dd-trace-rb/issues/937
[#938]: https://github.com/DataDog/dd-trace-rb/issues/938
[#940]: https://github.com/DataDog/dd-trace-rb/issues/940
[#942]: https://github.com/DataDog/dd-trace-rb/issues/942
[#943]: https://github.com/DataDog/dd-trace-rb/issues/943
[#944]: https://github.com/DataDog/dd-trace-rb/issues/944
[#945]: https://github.com/DataDog/dd-trace-rb/issues/945
[#947]: https://github.com/DataDog/dd-trace-rb/issues/947
[#948]: https://github.com/DataDog/dd-trace-rb/issues/948
[#949]: https://github.com/DataDog/dd-trace-rb/issues/949
[#950]: https://github.com/DataDog/dd-trace-rb/issues/950
[#951]: https://github.com/DataDog/dd-trace-rb/issues/951
[#952]: https://github.com/DataDog/dd-trace-rb/issues/952
[#953]: https://github.com/DataDog/dd-trace-rb/issues/953
[#954]: https://github.com/DataDog/dd-trace-rb/issues/954
[#955]: https://github.com/DataDog/dd-trace-rb/issues/955
[#956]: https://github.com/DataDog/dd-trace-rb/issues/956
[#957]: https://github.com/DataDog/dd-trace-rb/issues/957
[#960]: https://github.com/DataDog/dd-trace-rb/issues/960
[#961]: https://github.com/DataDog/dd-trace-rb/issues/961
[#964]: https://github.com/DataDog/dd-trace-rb/issues/964
[#965]: https://github.com/DataDog/dd-trace-rb/issues/965
[#966]: https://github.com/DataDog/dd-trace-rb/issues/966
[#967]: https://github.com/DataDog/dd-trace-rb/issues/967
[#968]: https://github.com/DataDog/dd-trace-rb/issues/968
[#969]: https://github.com/DataDog/dd-trace-rb/issues/969
[#971]: https://github.com/DataDog/dd-trace-rb/issues/971
[#972]: https://github.com/DataDog/dd-trace-rb/issues/972
[#973]: https://github.com/DataDog/dd-trace-rb/issues/973
[#974]: https://github.com/DataDog/dd-trace-rb/issues/974
[#975]: https://github.com/DataDog/dd-trace-rb/issues/975
[#977]: https://github.com/DataDog/dd-trace-rb/issues/977
[#980]: https://github.com/DataDog/dd-trace-rb/issues/980
[#981]: https://github.com/DataDog/dd-trace-rb/issues/981
[#982]: https://github.com/DataDog/dd-trace-rb/issues/982
[#983]: https://github.com/DataDog/dd-trace-rb/issues/983
[#985]: https://github.com/DataDog/dd-trace-rb/issues/985
[#986]: https://github.com/DataDog/dd-trace-rb/issues/986
[#988]: https://github.com/DataDog/dd-trace-rb/issues/988
[#989]: https://github.com/DataDog/dd-trace-rb/issues/989
[#990]: https://github.com/DataDog/dd-trace-rb/issues/990
[#991]: https://github.com/DataDog/dd-trace-rb/issues/991
[#993]: https://github.com/DataDog/dd-trace-rb/issues/993
[#995]: https://github.com/DataDog/dd-trace-rb/issues/995
[#996]: https://github.com/DataDog/dd-trace-rb/issues/996
[#997]: https://github.com/DataDog/dd-trace-rb/issues/997
[#1000]: https://github.com/DataDog/dd-trace-rb/issues/1000
[#1004]: https://github.com/DataDog/dd-trace-rb/issues/1004
[#1005]: https://github.com/DataDog/dd-trace-rb/issues/1005
[#1006]: https://github.com/DataDog/dd-trace-rb/issues/1006
[#1008]: https://github.com/DataDog/dd-trace-rb/issues/1008
[#1009]: https://github.com/DataDog/dd-trace-rb/issues/1009
[#1010]: https://github.com/DataDog/dd-trace-rb/issues/1010
[#1015]: https://github.com/DataDog/dd-trace-rb/issues/1015
[#1021]: https://github.com/DataDog/dd-trace-rb/issues/1021
[#1023]: https://github.com/DataDog/dd-trace-rb/issues/1023
[#1027]: https://github.com/DataDog/dd-trace-rb/issues/1027
[#1030]: https://github.com/DataDog/dd-trace-rb/issues/1030
[#1031]: https://github.com/DataDog/dd-trace-rb/issues/1031
[#1032]: https://github.com/DataDog/dd-trace-rb/issues/1032
[#1033]: https://github.com/DataDog/dd-trace-rb/issues/1033
[#1034]: https://github.com/DataDog/dd-trace-rb/issues/1034
[#1035]: https://github.com/DataDog/dd-trace-rb/issues/1035
[#1037]: https://github.com/DataDog/dd-trace-rb/issues/1037
[#1041]: https://github.com/DataDog/dd-trace-rb/issues/1041
[#1043]: https://github.com/DataDog/dd-trace-rb/issues/1043
[#1045]: https://github.com/DataDog/dd-trace-rb/issues/1045
[#1046]: https://github.com/DataDog/dd-trace-rb/issues/1046
[#1047]: https://github.com/DataDog/dd-trace-rb/issues/1047
[#1051]: https://github.com/DataDog/dd-trace-rb/issues/1051
[#1054]: https://github.com/DataDog/dd-trace-rb/issues/1054
[#1057]: https://github.com/DataDog/dd-trace-rb/issues/1057
[#1062]: https://github.com/DataDog/dd-trace-rb/issues/1062
[#1070]: https://github.com/DataDog/dd-trace-rb/issues/1070
[#1071]: https://github.com/DataDog/dd-trace-rb/issues/1071
[#1072]: https://github.com/DataDog/dd-trace-rb/issues/1072
[#1073]: https://github.com/DataDog/dd-trace-rb/issues/1073
[#1074]: https://github.com/DataDog/dd-trace-rb/issues/1074
[#1075]: https://github.com/DataDog/dd-trace-rb/issues/1075
[#1076]: https://github.com/DataDog/dd-trace-rb/issues/1076
[#1079]: https://github.com/DataDog/dd-trace-rb/issues/1079
[#1081]: https://github.com/DataDog/dd-trace-rb/issues/1081
[#1082]: https://github.com/DataDog/dd-trace-rb/issues/1082
[#1086]: https://github.com/DataDog/dd-trace-rb/issues/1086
[#1089]: https://github.com/DataDog/dd-trace-rb/issues/1089
[#1090]: https://github.com/DataDog/dd-trace-rb/issues/1090
[#1091]: https://github.com/DataDog/dd-trace-rb/issues/1091
[#1092]: https://github.com/DataDog/dd-trace-rb/issues/1092
[#1099]: https://github.com/DataDog/dd-trace-rb/issues/1099
[#1100]: https://github.com/DataDog/dd-trace-rb/issues/1100
[#1103]: https://github.com/DataDog/dd-trace-rb/issues/1103
[#1104]: https://github.com/DataDog/dd-trace-rb/issues/1104
[#1105]: https://github.com/DataDog/dd-trace-rb/issues/1105
[#1107]: https://github.com/DataDog/dd-trace-rb/issues/1107
[#1109]: https://github.com/DataDog/dd-trace-rb/issues/1109
[#1115]: https://github.com/DataDog/dd-trace-rb/issues/1115
[#1116]: https://github.com/DataDog/dd-trace-rb/issues/1116
[#1118]: https://github.com/DataDog/dd-trace-rb/issues/1118
[#1119]: https://github.com/DataDog/dd-trace-rb/issues/1119
[#1120]: https://github.com/DataDog/dd-trace-rb/issues/1120
[#1121]: https://github.com/DataDog/dd-trace-rb/issues/1121
[#1122]: https://github.com/DataDog/dd-trace-rb/issues/1122
[#1124]: https://github.com/DataDog/dd-trace-rb/issues/1124
[#1125]: https://github.com/DataDog/dd-trace-rb/issues/1125
[#1126]: https://github.com/DataDog/dd-trace-rb/issues/1126
[#1127]: https://github.com/DataDog/dd-trace-rb/issues/1127
[#1128]: https://github.com/DataDog/dd-trace-rb/issues/1128
[#1129]: https://github.com/DataDog/dd-trace-rb/issues/1129
[#1131]: https://github.com/DataDog/dd-trace-rb/issues/1131
[#1133]: https://github.com/DataDog/dd-trace-rb/issues/1133
[#1134]: https://github.com/DataDog/dd-trace-rb/issues/1134
[#1137]: https://github.com/DataDog/dd-trace-rb/issues/1137
[#1138]: https://github.com/DataDog/dd-trace-rb/issues/1138
[#1141]: https://github.com/DataDog/dd-trace-rb/issues/1141
[#1145]: https://github.com/DataDog/dd-trace-rb/issues/1145
[#1146]: https://github.com/DataDog/dd-trace-rb/issues/1146
[#1148]: https://github.com/DataDog/dd-trace-rb/issues/1148
[#1149]: https://github.com/DataDog/dd-trace-rb/issues/1149
[#1150]: https://github.com/DataDog/dd-trace-rb/issues/1150
[#1151]: https://github.com/DataDog/dd-trace-rb/issues/1151
[#1152]: https://github.com/DataDog/dd-trace-rb/issues/1152
[#1153]: https://github.com/DataDog/dd-trace-rb/issues/1153
[#1154]: https://github.com/DataDog/dd-trace-rb/issues/1154
[#1155]: https://github.com/DataDog/dd-trace-rb/issues/1155
[#1156]: https://github.com/DataDog/dd-trace-rb/issues/1156
[#1157]: https://github.com/DataDog/dd-trace-rb/issues/1157
[#1158]: https://github.com/DataDog/dd-trace-rb/issues/1158
[#1159]: https://github.com/DataDog/dd-trace-rb/issues/1159
[#1160]: https://github.com/DataDog/dd-trace-rb/issues/1160
[#1162]: https://github.com/DataDog/dd-trace-rb/issues/1162
[#1163]: https://github.com/DataDog/dd-trace-rb/issues/1163
[#1165]: https://github.com/DataDog/dd-trace-rb/issues/1165
[#1172]: https://github.com/DataDog/dd-trace-rb/issues/1172
[#1173]: https://github.com/DataDog/dd-trace-rb/issues/1173
[#1176]: https://github.com/DataDog/dd-trace-rb/issues/1176
[#1177]: https://github.com/DataDog/dd-trace-rb/issues/1177
[#1178]: https://github.com/DataDog/dd-trace-rb/issues/1178
[#1179]: https://github.com/DataDog/dd-trace-rb/issues/1179
[#1180]: https://github.com/DataDog/dd-trace-rb/issues/1180
[#1181]: https://github.com/DataDog/dd-trace-rb/issues/1181
[#1182]: https://github.com/DataDog/dd-trace-rb/issues/1182
[#1183]: https://github.com/DataDog/dd-trace-rb/issues/1183
[#1184]: https://github.com/DataDog/dd-trace-rb/issues/1184
[#1185]: https://github.com/DataDog/dd-trace-rb/issues/1185
[#1186]: https://github.com/DataDog/dd-trace-rb/issues/1186
[#1187]: https://github.com/DataDog/dd-trace-rb/issues/1187
[#1188]: https://github.com/DataDog/dd-trace-rb/issues/1188
[#1189]: https://github.com/DataDog/dd-trace-rb/issues/1189
[#1195]: https://github.com/DataDog/dd-trace-rb/issues/1195
[#1198]: https://github.com/DataDog/dd-trace-rb/issues/1198
[#1199]: https://github.com/DataDog/dd-trace-rb/issues/1199
[#1200]: https://github.com/DataDog/dd-trace-rb/issues/1200
[#1203]: https://github.com/DataDog/dd-trace-rb/issues/1203
[#1204]: https://github.com/DataDog/dd-trace-rb/issues/1204
[#1210]: https://github.com/DataDog/dd-trace-rb/issues/1210
[#1212]: https://github.com/DataDog/dd-trace-rb/issues/1212
[#1213]: https://github.com/DataDog/dd-trace-rb/issues/1213
[#1216]: https://github.com/DataDog/dd-trace-rb/issues/1216
[#1217]: https://github.com/DataDog/dd-trace-rb/issues/1217
[#1218]: https://github.com/DataDog/dd-trace-rb/issues/1218
[#1220]: https://github.com/DataDog/dd-trace-rb/issues/1220
[#1224]: https://github.com/DataDog/dd-trace-rb/issues/1224
[#1225]: https://github.com/DataDog/dd-trace-rb/issues/1225
[#1226]: https://github.com/DataDog/dd-trace-rb/issues/1226
[#1227]: https://github.com/DataDog/dd-trace-rb/issues/1227
[#1229]: https://github.com/DataDog/dd-trace-rb/issues/1229
[#1232]: https://github.com/DataDog/dd-trace-rb/issues/1232
[#1233]: https://github.com/DataDog/dd-trace-rb/issues/1233
[#1234]: https://github.com/DataDog/dd-trace-rb/issues/1234
[#1235]: https://github.com/DataDog/dd-trace-rb/issues/1235
[#1236]: https://github.com/DataDog/dd-trace-rb/issues/1236
[#1237]: https://github.com/DataDog/dd-trace-rb/issues/1237
[#1238]: https://github.com/DataDog/dd-trace-rb/issues/1238
[#1239]: https://github.com/DataDog/dd-trace-rb/issues/1239
[#1243]: https://github.com/DataDog/dd-trace-rb/issues/1243
[#1244]: https://github.com/DataDog/dd-trace-rb/issues/1244
[#1248]: https://github.com/DataDog/dd-trace-rb/issues/1248
[#1256]: https://github.com/DataDog/dd-trace-rb/issues/1256
[#1257]: https://github.com/DataDog/dd-trace-rb/issues/1257
[#1260]: https://github.com/DataDog/dd-trace-rb/issues/1260
[#1262]: https://github.com/DataDog/dd-trace-rb/issues/1262
[#1263]: https://github.com/DataDog/dd-trace-rb/issues/1263
[#1264]: https://github.com/DataDog/dd-trace-rb/issues/1264
[#1266]: https://github.com/DataDog/dd-trace-rb/issues/1266
[#1267]: https://github.com/DataDog/dd-trace-rb/issues/1267
[#1268]: https://github.com/DataDog/dd-trace-rb/issues/1268
[#1269]: https://github.com/DataDog/dd-trace-rb/issues/1269
[#1270]: https://github.com/DataDog/dd-trace-rb/issues/1270
[#1272]: https://github.com/DataDog/dd-trace-rb/issues/1272
[#1273]: https://github.com/DataDog/dd-trace-rb/issues/1273
[#1275]: https://github.com/DataDog/dd-trace-rb/issues/1275
[#1276]: https://github.com/DataDog/dd-trace-rb/issues/1276
[#1277]: https://github.com/DataDog/dd-trace-rb/issues/1277
[#1278]: https://github.com/DataDog/dd-trace-rb/issues/1278
[#1279]: https://github.com/DataDog/dd-trace-rb/issues/1279
[#1280]: https://github.com/DataDog/dd-trace-rb/issues/1280
[#1281]: https://github.com/DataDog/dd-trace-rb/issues/1281
[#1283]: https://github.com/DataDog/dd-trace-rb/issues/1283
[#1284]: https://github.com/DataDog/dd-trace-rb/issues/1284
[#1286]: https://github.com/DataDog/dd-trace-rb/issues/1286
[#1287]: https://github.com/DataDog/dd-trace-rb/issues/1287
[#1289]: https://github.com/DataDog/dd-trace-rb/issues/1289
[#1291]: https://github.com/DataDog/dd-trace-rb/issues/1291
[#1293]: https://github.com/DataDog/dd-trace-rb/issues/1293
[#1295]: https://github.com/DataDog/dd-trace-rb/issues/1295
[#1296]: https://github.com/DataDog/dd-trace-rb/issues/1296
[#1297]: https://github.com/DataDog/dd-trace-rb/issues/1297
[#1298]: https://github.com/DataDog/dd-trace-rb/issues/1298
[#1299]: https://github.com/DataDog/dd-trace-rb/issues/1299
[#1302]: https://github.com/DataDog/dd-trace-rb/issues/1302
[#1303]: https://github.com/DataDog/dd-trace-rb/issues/1303
[#1304]: https://github.com/DataDog/dd-trace-rb/issues/1304
[#1305]: https://github.com/DataDog/dd-trace-rb/issues/1305
[#1306]: https://github.com/DataDog/dd-trace-rb/issues/1306
[#1307]: https://github.com/DataDog/dd-trace-rb/issues/1307
[#1309]: https://github.com/DataDog/dd-trace-rb/issues/1309
[#1311]: https://github.com/DataDog/dd-trace-rb/issues/1311
[#1317]: https://github.com/DataDog/dd-trace-rb/issues/1317
[#1318]: https://github.com/DataDog/dd-trace-rb/issues/1318
[#1319]: https://github.com/DataDog/dd-trace-rb/issues/1319
[#1320]: https://github.com/DataDog/dd-trace-rb/issues/1320
[#1321]: https://github.com/DataDog/dd-trace-rb/issues/1321
[#1323]: https://github.com/DataDog/dd-trace-rb/issues/1323
[#1325]: https://github.com/DataDog/dd-trace-rb/issues/1325
[#1326]: https://github.com/DataDog/dd-trace-rb/issues/1326
[#1331]: https://github.com/DataDog/dd-trace-rb/issues/1331
[#1332]: https://github.com/DataDog/dd-trace-rb/issues/1332
[#1334]: https://github.com/DataDog/dd-trace-rb/issues/1334
[#1336]: https://github.com/DataDog/dd-trace-rb/issues/1336
[#1341]: https://github.com/DataDog/dd-trace-rb/issues/1341
[#1342]: https://github.com/DataDog/dd-trace-rb/issues/1342
[#1343]: https://github.com/DataDog/dd-trace-rb/issues/1343
[#1346]: https://github.com/DataDog/dd-trace-rb/issues/1346
[#1347]: https://github.com/DataDog/dd-trace-rb/issues/1347
[#1350]: https://github.com/DataDog/dd-trace-rb/issues/1350
[#1352]: https://github.com/DataDog/dd-trace-rb/issues/1352
[#1353]: https://github.com/DataDog/dd-trace-rb/issues/1353
[#1354]: https://github.com/DataDog/dd-trace-rb/issues/1354
[#1357]: https://github.com/DataDog/dd-trace-rb/issues/1357
[#1365]: https://github.com/DataDog/dd-trace-rb/issues/1365
[#1366]: https://github.com/DataDog/dd-trace-rb/issues/1366
[#1367]: https://github.com/DataDog/dd-trace-rb/issues/1367
[#1368]: https://github.com/DataDog/dd-trace-rb/issues/1368
[#1369]: https://github.com/DataDog/dd-trace-rb/issues/1369
[#1370]: https://github.com/DataDog/dd-trace-rb/issues/1370
[#1371]: https://github.com/DataDog/dd-trace-rb/issues/1371
[#1374]: https://github.com/DataDog/dd-trace-rb/issues/1374
[#1377]: https://github.com/DataDog/dd-trace-rb/issues/1377
[#1378]: https://github.com/DataDog/dd-trace-rb/issues/1378
[#1379]: https://github.com/DataDog/dd-trace-rb/issues/1379
[#1380]: https://github.com/DataDog/dd-trace-rb/issues/1380
[#1381]: https://github.com/DataDog/dd-trace-rb/issues/1381
[#1393]: https://github.com/DataDog/dd-trace-rb/issues/1393
[#1394]: https://github.com/DataDog/dd-trace-rb/issues/1394
[#1396]: https://github.com/DataDog/dd-trace-rb/issues/1396
[#1397]: https://github.com/DataDog/dd-trace-rb/issues/1397
[#1398]: https://github.com/DataDog/dd-trace-rb/issues/1398
[#1399]: https://github.com/DataDog/dd-trace-rb/issues/1399
[#1400]: https://github.com/DataDog/dd-trace-rb/issues/1400
[#1403]: https://github.com/DataDog/dd-trace-rb/issues/1403
[#1406]: https://github.com/DataDog/dd-trace-rb/issues/1406
[#1408]: https://github.com/DataDog/dd-trace-rb/issues/1408
[#1409]: https://github.com/DataDog/dd-trace-rb/issues/1409
[#1412]: https://github.com/DataDog/dd-trace-rb/issues/1412
[#1414]: https://github.com/DataDog/dd-trace-rb/issues/1414
[#1415]: https://github.com/DataDog/dd-trace-rb/issues/1415
[#1416]: https://github.com/DataDog/dd-trace-rb/issues/1416
[#1417]: https://github.com/DataDog/dd-trace-rb/issues/1417
[#1418]: https://github.com/DataDog/dd-trace-rb/issues/1418
[#1419]: https://github.com/DataDog/dd-trace-rb/issues/1419
[#1420]: https://github.com/DataDog/dd-trace-rb/issues/1420
[#1421]: https://github.com/DataDog/dd-trace-rb/issues/1421
[#1422]: https://github.com/DataDog/dd-trace-rb/issues/1422
[#1423]: https://github.com/DataDog/dd-trace-rb/issues/1423
[#1426]: https://github.com/DataDog/dd-trace-rb/issues/1426
[#1427]: https://github.com/DataDog/dd-trace-rb/issues/1427
[#1428]: https://github.com/DataDog/dd-trace-rb/issues/1428
[#1429]: https://github.com/DataDog/dd-trace-rb/issues/1429
[#1430]: https://github.com/DataDog/dd-trace-rb/issues/1430
[#1431]: https://github.com/DataDog/dd-trace-rb/issues/1431
[#1432]: https://github.com/DataDog/dd-trace-rb/issues/1432
[#1435]: https://github.com/DataDog/dd-trace-rb/issues/1435
[#1441]: https://github.com/DataDog/dd-trace-rb/issues/1441
[#1445]: https://github.com/DataDog/dd-trace-rb/issues/1445
[#1447]: https://github.com/DataDog/dd-trace-rb/issues/1447
[#1449]: https://github.com/DataDog/dd-trace-rb/issues/1449
[#1453]: https://github.com/DataDog/dd-trace-rb/issues/1453
[#1455]: https://github.com/DataDog/dd-trace-rb/issues/1455
[#1456]: https://github.com/DataDog/dd-trace-rb/issues/1456
[#1457]: https://github.com/DataDog/dd-trace-rb/issues/1457
[#1461]: https://github.com/DataDog/dd-trace-rb/issues/1461
[#1472]: https://github.com/DataDog/dd-trace-rb/issues/1472
[#1473]: https://github.com/DataDog/dd-trace-rb/issues/1473
[#1475]: https://github.com/DataDog/dd-trace-rb/issues/1475
[#1480]: https://github.com/DataDog/dd-trace-rb/issues/1480
[#1487]: https://github.com/DataDog/dd-trace-rb/issues/1487
[#1489]: https://github.com/DataDog/dd-trace-rb/issues/1489
[#1494]: https://github.com/DataDog/dd-trace-rb/issues/1494
[#1495]: https://github.com/DataDog/dd-trace-rb/issues/1495
[#1497]: https://github.com/DataDog/dd-trace-rb/issues/1497
[#1500]: https://github.com/DataDog/dd-trace-rb/issues/1500
[#1502]: https://github.com/DataDog/dd-trace-rb/issues/1502
[#1503]: https://github.com/DataDog/dd-trace-rb/issues/1503
[#1504]: https://github.com/DataDog/dd-trace-rb/issues/1504
[#1506]: https://github.com/DataDog/dd-trace-rb/issues/1506
[#1507]: https://github.com/DataDog/dd-trace-rb/issues/1507
[#1509]: https://github.com/DataDog/dd-trace-rb/issues/1509
[#1510]: https://github.com/DataDog/dd-trace-rb/issues/1510
[#1511]: https://github.com/DataDog/dd-trace-rb/issues/1511
[#1522]: https://github.com/DataDog/dd-trace-rb/issues/1522
[#1523]: https://github.com/DataDog/dd-trace-rb/issues/1523
[#1524]: https://github.com/DataDog/dd-trace-rb/issues/1524
[#1529]: https://github.com/DataDog/dd-trace-rb/issues/1529
[#1533]: https://github.com/DataDog/dd-trace-rb/issues/1533
[#1534]: https://github.com/DataDog/dd-trace-rb/issues/1534
[#1535]: https://github.com/DataDog/dd-trace-rb/issues/1535
[#1537]: https://github.com/DataDog/dd-trace-rb/issues/1537
[#1543]: https://github.com/DataDog/dd-trace-rb/issues/1543
[#1544]: https://github.com/DataDog/dd-trace-rb/issues/1544
[#1552]: https://github.com/DataDog/dd-trace-rb/issues/1552
[#1555]: https://github.com/DataDog/dd-trace-rb/issues/1555
[#1556]: https://github.com/DataDog/dd-trace-rb/issues/1556
[#1557]: https://github.com/DataDog/dd-trace-rb/issues/1557
[#1560]: https://github.com/DataDog/dd-trace-rb/issues/1560
[#1561]: https://github.com/DataDog/dd-trace-rb/issues/1561
[#1566]: https://github.com/DataDog/dd-trace-rb/issues/1566
[#1570]: https://github.com/DataDog/dd-trace-rb/issues/1570
[#1572]: https://github.com/DataDog/dd-trace-rb/issues/1572
[#1576]: https://github.com/DataDog/dd-trace-rb/issues/1576
[#1583]: https://github.com/DataDog/dd-trace-rb/issues/1583
[#1584]: https://github.com/DataDog/dd-trace-rb/issues/1584
[#1585]: https://github.com/DataDog/dd-trace-rb/issues/1585
[#1586]: https://github.com/DataDog/dd-trace-rb/issues/1586
[#1587]: https://github.com/DataDog/dd-trace-rb/issues/1587
[#1590]: https://github.com/DataDog/dd-trace-rb/issues/1590
[#1592]: https://github.com/DataDog/dd-trace-rb/issues/1592
[#1594]: https://github.com/DataDog/dd-trace-rb/issues/1594
[#1595]: https://github.com/DataDog/dd-trace-rb/issues/1595
[#1601]: https://github.com/DataDog/dd-trace-rb/issues/1601
[#1607]: https://github.com/DataDog/dd-trace-rb/issues/1607
[#1622]: https://github.com/DataDog/dd-trace-rb/issues/1622
[#1623]: https://github.com/DataDog/dd-trace-rb/issues/1623
[#1626]: https://github.com/DataDog/dd-trace-rb/issues/1626
[#1628]: https://github.com/DataDog/dd-trace-rb/issues/1628
[#1629]: https://github.com/DataDog/dd-trace-rb/issues/1629
[#1630]: https://github.com/DataDog/dd-trace-rb/issues/1630
[#1632]: https://github.com/DataDog/dd-trace-rb/issues/1632
[#1636]: https://github.com/DataDog/dd-trace-rb/issues/1636
[#1639]: https://github.com/DataDog/dd-trace-rb/issues/1639
[#1643]: https://github.com/DataDog/dd-trace-rb/issues/1643
[#1644]: https://github.com/DataDog/dd-trace-rb/issues/1644
[#1654]: https://github.com/DataDog/dd-trace-rb/issues/1654
[#1661]: https://github.com/DataDog/dd-trace-rb/issues/1661
[#1662]: https://github.com/DataDog/dd-trace-rb/issues/1662
[#1668]: https://github.com/DataDog/dd-trace-rb/issues/1668
[#1674]: https://github.com/DataDog/dd-trace-rb/issues/1674
[#1680]: https://github.com/DataDog/dd-trace-rb/issues/1680
[#1684]: https://github.com/DataDog/dd-trace-rb/issues/1684
[#1685]: https://github.com/DataDog/dd-trace-rb/issues/1685
[#1687]: https://github.com/DataDog/dd-trace-rb/issues/1687
[#1688]: https://github.com/DataDog/dd-trace-rb/issues/1688
[#1694]: https://github.com/DataDog/dd-trace-rb/issues/1694
[#1695]: https://github.com/DataDog/dd-trace-rb/issues/1695
[#1699]: https://github.com/DataDog/dd-trace-rb/issues/1699
[#1700]: https://github.com/DataDog/dd-trace-rb/issues/1700
[#1702]: https://github.com/DataDog/dd-trace-rb/issues/1702
[#1703]: https://github.com/DataDog/dd-trace-rb/issues/1703
[#1706]: https://github.com/DataDog/dd-trace-rb/issues/1706
[#1709]: https://github.com/DataDog/dd-trace-rb/issues/1709
[#1712]: https://github.com/DataDog/dd-trace-rb/issues/1712
[#1713]: https://github.com/DataDog/dd-trace-rb/issues/1713
[#1714]: https://github.com/DataDog/dd-trace-rb/issues/1714
[#1715]: https://github.com/DataDog/dd-trace-rb/issues/1715
[#1717]: https://github.com/DataDog/dd-trace-rb/issues/1717
[#1718]: https://github.com/DataDog/dd-trace-rb/issues/1718
[#1719]: https://github.com/DataDog/dd-trace-rb/issues/1719
[#1720]: https://github.com/DataDog/dd-trace-rb/issues/1720
[#1721]: https://github.com/DataDog/dd-trace-rb/issues/1721
[#1735]: https://github.com/DataDog/dd-trace-rb/issues/1735
[#1740]: https://github.com/DataDog/dd-trace-rb/issues/1740
[#1743]: https://github.com/DataDog/dd-trace-rb/issues/1743
[#1745]: https://github.com/DataDog/dd-trace-rb/issues/1745
[#1761]: https://github.com/DataDog/dd-trace-rb/issues/1761
[#1762]: https://github.com/DataDog/dd-trace-rb/issues/1762
[#1763]: https://github.com/DataDog/dd-trace-rb/issues/1763
[#1769]: https://github.com/DataDog/dd-trace-rb/issues/1769
[#1770]: https://github.com/DataDog/dd-trace-rb/issues/1770
[#1771]: https://github.com/DataDog/dd-trace-rb/issues/1771
[#1774]: https://github.com/DataDog/dd-trace-rb/issues/1774
[#1776]: https://github.com/DataDog/dd-trace-rb/issues/1776
[#1798]: https://github.com/DataDog/dd-trace-rb/issues/1798
[#1801]: https://github.com/DataDog/dd-trace-rb/issues/1801
[#1807]: https://github.com/DataDog/dd-trace-rb/issues/1807
[#1816]: https://github.com/DataDog/dd-trace-rb/issues/1816
[#1820]: https://github.com/DataDog/dd-trace-rb/issues/1820
[#1829]: https://github.com/DataDog/dd-trace-rb/issues/1829
[#1911]: https://github.com/DataDog/dd-trace-rb/issues/1911
[#1914]: https://github.com/DataDog/dd-trace-rb/issues/1914
[#1917]: https://github.com/DataDog/dd-trace-rb/issues/1917
[#1919]: https://github.com/DataDog/dd-trace-rb/issues/1919
[#1922]: https://github.com/DataDog/dd-trace-rb/issues/1922
[#1927]: https://github.com/DataDog/dd-trace-rb/issues/1927
[#1930]: https://github.com/DataDog/dd-trace-rb/issues/1930
[#1931]: https://github.com/DataDog/dd-trace-rb/issues/1931
[#1932]: https://github.com/DataDog/dd-trace-rb/issues/1932
[#1933]: https://github.com/DataDog/dd-trace-rb/issues/1933
[#1937]: https://github.com/DataDog/dd-trace-rb/issues/1937
[#1938]: https://github.com/DataDog/dd-trace-rb/issues/1938
[#1939]: https://github.com/DataDog/dd-trace-rb/issues/1939
[#1940]: https://github.com/DataDog/dd-trace-rb/issues/1940
[#1942]: https://github.com/DataDog/dd-trace-rb/issues/1942
[#1943]: https://github.com/DataDog/dd-trace-rb/issues/1943
[#1945]: https://github.com/DataDog/dd-trace-rb/issues/1945
[#1948]: https://github.com/DataDog/dd-trace-rb/issues/1948
[#1955]: https://github.com/DataDog/dd-trace-rb/issues/1955
[#1956]: https://github.com/DataDog/dd-trace-rb/issues/1956
[#1958]: https://github.com/DataDog/dd-trace-rb/issues/1958
[#1959]: https://github.com/DataDog/dd-trace-rb/issues/1959
[#1961]: https://github.com/DataDog/dd-trace-rb/issues/1961
[#1964]: https://github.com/DataDog/dd-trace-rb/issues/1964
[#1965]: https://github.com/DataDog/dd-trace-rb/issues/1965
[#1968]: https://github.com/DataDog/dd-trace-rb/issues/1968
[#1970]: https://github.com/DataDog/dd-trace-rb/issues/1970
[#1972]: https://github.com/DataDog/dd-trace-rb/issues/1972
[#1973]: https://github.com/DataDog/dd-trace-rb/issues/1973
[#1974]: https://github.com/DataDog/dd-trace-rb/issues/1974
[#1975]: https://github.com/DataDog/dd-trace-rb/issues/1975
[#1976]: https://github.com/DataDog/dd-trace-rb/issues/1976
[#1980]: https://github.com/DataDog/dd-trace-rb/issues/1980
[#1981]: https://github.com/DataDog/dd-trace-rb/issues/1981
[#1982]: https://github.com/DataDog/dd-trace-rb/issues/1982
[#1983]: https://github.com/DataDog/dd-trace-rb/issues/1983
[#1984]: https://github.com/DataDog/dd-trace-rb/issues/1984
[#1985]: https://github.com/DataDog/dd-trace-rb/issues/1985
[#1989]: https://github.com/DataDog/dd-trace-rb/issues/1989
[#1990]: https://github.com/DataDog/dd-trace-rb/issues/1990
[#1991]: https://github.com/DataDog/dd-trace-rb/issues/1991
[#1992]: https://github.com/DataDog/dd-trace-rb/issues/1992
[#1998]: https://github.com/DataDog/dd-trace-rb/issues/1998
[#2010]: https://github.com/DataDog/dd-trace-rb/issues/2010
[#2011]: https://github.com/DataDog/dd-trace-rb/issues/2011
[#2022]: https://github.com/DataDog/dd-trace-rb/issues/2022
[#2027]: https://github.com/DataDog/dd-trace-rb/issues/2027
[#2028]: https://github.com/DataDog/dd-trace-rb/issues/2028
[#2054]: https://github.com/DataDog/dd-trace-rb/issues/2054
[#2059]: https://github.com/DataDog/dd-trace-rb/issues/2059
[#2061]: https://github.com/DataDog/dd-trace-rb/issues/2061
[#2062]: https://github.com/DataDog/dd-trace-rb/issues/2062
[#2066]: https://github.com/DataDog/dd-trace-rb/issues/2066
[#2069]: https://github.com/DataDog/dd-trace-rb/issues/2069
[#2070]: https://github.com/DataDog/dd-trace-rb/issues/2070
[#2074]: https://github.com/DataDog/dd-trace-rb/issues/2074
[#2076]: https://github.com/DataDog/dd-trace-rb/issues/2076
[#2079]: https://github.com/DataDog/dd-trace-rb/issues/2079
[#2082]: https://github.com/DataDog/dd-trace-rb/issues/2082
[#2096]: https://github.com/DataDog/dd-trace-rb/issues/2096
[#2097]: https://github.com/DataDog/dd-trace-rb/issues/2097
[#2101]: https://github.com/DataDog/dd-trace-rb/issues/2101
[#2110]: https://github.com/DataDog/dd-trace-rb/issues/2110
[#2113]: https://github.com/DataDog/dd-trace-rb/issues/2113
[#2118]: https://github.com/DataDog/dd-trace-rb/issues/2118
[#2125]: https://github.com/DataDog/dd-trace-rb/issues/2125
[#2128]: https://github.com/DataDog/dd-trace-rb/issues/2128
[#2134]: https://github.com/DataDog/dd-trace-rb/issues/2134
[#2138]: https://github.com/DataDog/dd-trace-rb/issues/2138
[#2140]: https://github.com/DataDog/dd-trace-rb/issues/2140
[#2150]: https://github.com/DataDog/dd-trace-rb/issues/2150
[#2153]: https://github.com/DataDog/dd-trace-rb/issues/2153
[#2158]: https://github.com/DataDog/dd-trace-rb/issues/2158
[#2162]: https://github.com/DataDog/dd-trace-rb/issues/2162
[#2163]: https://github.com/DataDog/dd-trace-rb/issues/2163
[#2170]: https://github.com/DataDog/dd-trace-rb/issues/2170
[#2173]: https://github.com/DataDog/dd-trace-rb/issues/2173
[#2174]: https://github.com/DataDog/dd-trace-rb/issues/2174
[#2180]: https://github.com/DataDog/dd-trace-rb/issues/2180
[#2191]: https://github.com/DataDog/dd-trace-rb/issues/2191
[#2200]: https://github.com/DataDog/dd-trace-rb/issues/2200
[#2201]: https://github.com/DataDog/dd-trace-rb/issues/2201
[#2217]: https://github.com/DataDog/dd-trace-rb/issues/2217
[#2219]: https://github.com/DataDog/dd-trace-rb/issues/2219
[#2229]: https://github.com/DataDog/dd-trace-rb/issues/2229
[#2230]: https://github.com/DataDog/dd-trace-rb/issues/2230
[#2248]: https://github.com/DataDog/dd-trace-rb/issues/2248
[#2250]: https://github.com/DataDog/dd-trace-rb/issues/2250
[#2252]: https://github.com/DataDog/dd-trace-rb/issues/2252
[#2257]: https://github.com/DataDog/dd-trace-rb/issues/2257
[#2258]: https://github.com/DataDog/dd-trace-rb/issues/2258
[#2260]: https://github.com/DataDog/dd-trace-rb/issues/2260
[#2265]: https://github.com/DataDog/dd-trace-rb/issues/2265
[#2267]: https://github.com/DataDog/dd-trace-rb/issues/2267
[#2276]: https://github.com/DataDog/dd-trace-rb/issues/2276
[#2279]: https://github.com/DataDog/dd-trace-rb/issues/2279
[#2283]: https://github.com/DataDog/dd-trace-rb/issues/2283
[#2289]: https://github.com/DataDog/dd-trace-rb/issues/2289
[#2292]: https://github.com/DataDog/dd-trace-rb/issues/2292
[#2293]: https://github.com/DataDog/dd-trace-rb/issues/2293
[#2296]: https://github.com/DataDog/dd-trace-rb/issues/2296
[#2302]: https://github.com/DataDog/dd-trace-rb/issues/2302
[#2306]: https://github.com/DataDog/dd-trace-rb/issues/2306
[#2307]: https://github.com/DataDog/dd-trace-rb/issues/2307
[#2310]: https://github.com/DataDog/dd-trace-rb/issues/2310
[#2311]: https://github.com/DataDog/dd-trace-rb/issues/2311
[#2313]: https://github.com/DataDog/dd-trace-rb/issues/2313
[#2316]: https://github.com/DataDog/dd-trace-rb/issues/2316
[#2317]: https://github.com/DataDog/dd-trace-rb/issues/2317
[#2318]: https://github.com/DataDog/dd-trace-rb/issues/2318
[#2319]: https://github.com/DataDog/dd-trace-rb/issues/2319
[#2321]: https://github.com/DataDog/dd-trace-rb/issues/2321
[#2324]: https://github.com/DataDog/dd-trace-rb/issues/2324
[#2328]: https://github.com/DataDog/dd-trace-rb/issues/2328
[#2330]: https://github.com/DataDog/dd-trace-rb/issues/2330
[#2331]: https://github.com/DataDog/dd-trace-rb/issues/2331
[#2335]: https://github.com/DataDog/dd-trace-rb/issues/2335
[#2339]: https://github.com/DataDog/dd-trace-rb/issues/2339
[#2352]: https://github.com/DataDog/dd-trace-rb/issues/2352
[#2362]: https://github.com/DataDog/dd-trace-rb/issues/2362
[#2363]: https://github.com/DataDog/dd-trace-rb/issues/2363
[#2365]: https://github.com/DataDog/dd-trace-rb/issues/2365
[#2367]: https://github.com/DataDog/dd-trace-rb/issues/2367
[#2368]: https://github.com/DataDog/dd-trace-rb/issues/2368
[#2378]: https://github.com/DataDog/dd-trace-rb/issues/2378
[#2382]: https://github.com/DataDog/dd-trace-rb/issues/2382
[#2390]: https://github.com/DataDog/dd-trace-rb/issues/2390
[#2392]: https://github.com/DataDog/dd-trace-rb/issues/2392
[#2393]: https://github.com/DataDog/dd-trace-rb/issues/2393
[#2394]: https://github.com/DataDog/dd-trace-rb/issues/2394
[#2413]: https://github.com/DataDog/dd-trace-rb/issues/2413
[#2419]: https://github.com/DataDog/dd-trace-rb/issues/2419
[#2420]: https://github.com/DataDog/dd-trace-rb/issues/2420
[#2428]: https://github.com/DataDog/dd-trace-rb/issues/2428
[#2435]: https://github.com/DataDog/dd-trace-rb/issues/2435
[#2451]: https://github.com/DataDog/dd-trace-rb/issues/2451
[#2453]: https://github.com/DataDog/dd-trace-rb/issues/2453
[#2454]: https://github.com/DataDog/dd-trace-rb/issues/2454
[#2455]: https://github.com/DataDog/dd-trace-rb/issues/2455
[#2458]: https://github.com/DataDog/dd-trace-rb/issues/2458
[#2459]: https://github.com/DataDog/dd-trace-rb/issues/2459
[#2460]: https://github.com/DataDog/dd-trace-rb/issues/2460
[#2461]: https://github.com/DataDog/dd-trace-rb/issues/2461
[#2463]: https://github.com/DataDog/dd-trace-rb/issues/2463
[#2464]: https://github.com/DataDog/dd-trace-rb/issues/2464
[#2466]: https://github.com/DataDog/dd-trace-rb/issues/2466
[#2469]: https://github.com/DataDog/dd-trace-rb/issues/2469
[#2470]: https://github.com/DataDog/dd-trace-rb/issues/2470
[#2473]: https://github.com/DataDog/dd-trace-rb/issues/2473
[#2485]: https://github.com/DataDog/dd-trace-rb/issues/2485
[#2489]: https://github.com/DataDog/dd-trace-rb/issues/2489
[#2493]: https://github.com/DataDog/dd-trace-rb/issues/2493
[#2496]: https://github.com/DataDog/dd-trace-rb/issues/2496
[#2497]: https://github.com/DataDog/dd-trace-rb/issues/2497
[#2501]: https://github.com/DataDog/dd-trace-rb/issues/2501
[#2504]: https://github.com/DataDog/dd-trace-rb/issues/2504
[#2509]: https://github.com/DataDog/dd-trace-rb/issues/2509
[#2512]: https://github.com/DataDog/dd-trace-rb/issues/2512
[#2513]: https://github.com/DataDog/dd-trace-rb/issues/2513
[#2522]: https://github.com/DataDog/dd-trace-rb/issues/2522
[#2526]: https://github.com/DataDog/dd-trace-rb/issues/2526
[#2530]: https://github.com/DataDog/dd-trace-rb/issues/2530
[#2531]: https://github.com/DataDog/dd-trace-rb/issues/2531
[#2541]: https://github.com/DataDog/dd-trace-rb/issues/2541
[#2543]: https://github.com/DataDog/dd-trace-rb/issues/2543
[#2557]: https://github.com/DataDog/dd-trace-rb/issues/2557
[#2562]: https://github.com/DataDog/dd-trace-rb/issues/2562
[#2572]: https://github.com/DataDog/dd-trace-rb/issues/2572
[#2573]: https://github.com/DataDog/dd-trace-rb/issues/2573
[#2576]: https://github.com/DataDog/dd-trace-rb/issues/2576
[#2580]: https://github.com/DataDog/dd-trace-rb/issues/2580
[#2586]: https://github.com/DataDog/dd-trace-rb/issues/2586
[#2590]: https://github.com/DataDog/dd-trace-rb/issues/2590
[#2591]: https://github.com/DataDog/dd-trace-rb/issues/2591
[#2592]: https://github.com/DataDog/dd-trace-rb/issues/2592
[#2594]: https://github.com/DataDog/dd-trace-rb/issues/2594
[#2595]: https://github.com/DataDog/dd-trace-rb/issues/2595
[#2598]: https://github.com/DataDog/dd-trace-rb/issues/2598
[#2599]: https://github.com/DataDog/dd-trace-rb/issues/2599
[#2600]: https://github.com/DataDog/dd-trace-rb/issues/2600
[#2601]: https://github.com/DataDog/dd-trace-rb/issues/2601
[#2605]: https://github.com/DataDog/dd-trace-rb/issues/2605
[#2606]: https://github.com/DataDog/dd-trace-rb/issues/2606
[#2607]: https://github.com/DataDog/dd-trace-rb/issues/2607
[#2608]: https://github.com/DataDog/dd-trace-rb/issues/2608
[#2612]: https://github.com/DataDog/dd-trace-rb/issues/2612
[#2613]: https://github.com/DataDog/dd-trace-rb/issues/2613
[#2614]: https://github.com/DataDog/dd-trace-rb/issues/2614
[#2618]: https://github.com/DataDog/dd-trace-rb/issues/2618
[#2619]: https://github.com/DataDog/dd-trace-rb/issues/2619
[#2620]: https://github.com/DataDog/dd-trace-rb/issues/2620
[#2634]: https://github.com/DataDog/dd-trace-rb/issues/2634
[#2635]: https://github.com/DataDog/dd-trace-rb/issues/2635
[#2642]: https://github.com/DataDog/dd-trace-rb/issues/2642
[#2648]: https://github.com/DataDog/dd-trace-rb/issues/2648
[#2649]: https://github.com/DataDog/dd-trace-rb/issues/2649
[#2657]: https://github.com/DataDog/dd-trace-rb/issues/2657
[#2659]: https://github.com/DataDog/dd-trace-rb/issues/2659
[#2662]: https://github.com/DataDog/dd-trace-rb/issues/2662
[#2663]: https://github.com/DataDog/dd-trace-rb/issues/2663
[#2665]: https://github.com/DataDog/dd-trace-rb/issues/2665
[#2668]: https://github.com/DataDog/dd-trace-rb/issues/2668
[#2674]: https://github.com/DataDog/dd-trace-rb/issues/2674
[#2678]: https://github.com/DataDog/dd-trace-rb/issues/2678
[#2679]: https://github.com/DataDog/dd-trace-rb/issues/2679
[#2686]: https://github.com/DataDog/dd-trace-rb/issues/2686
[#2687]: https://github.com/DataDog/dd-trace-rb/issues/2687
[#2688]: https://github.com/DataDog/dd-trace-rb/issues/2688
[#2689]: https://github.com/DataDog/dd-trace-rb/issues/2689
[#2690]: https://github.com/DataDog/dd-trace-rb/issues/2690
[#2695]: https://github.com/DataDog/dd-trace-rb/issues/2695
[#2696]: https://github.com/DataDog/dd-trace-rb/issues/2696
[#2698]: https://github.com/DataDog/dd-trace-rb/issues/2698
[#2701]: https://github.com/DataDog/dd-trace-rb/issues/2701
[#2702]: https://github.com/DataDog/dd-trace-rb/issues/2702
[#2704]: https://github.com/DataDog/dd-trace-rb/issues/2704
[#2705]: https://github.com/DataDog/dd-trace-rb/issues/2705
[#2710]: https://github.com/DataDog/dd-trace-rb/issues/2710
[#2711]: https://github.com/DataDog/dd-trace-rb/issues/2711
[#2720]: https://github.com/DataDog/dd-trace-rb/issues/2720
[#2726]: https://github.com/DataDog/dd-trace-rb/issues/2726
[#2727]: https://github.com/DataDog/dd-trace-rb/issues/2727
[#2730]: https://github.com/DataDog/dd-trace-rb/issues/2730
[#2731]: https://github.com/DataDog/dd-trace-rb/issues/2731
[#2732]: https://github.com/DataDog/dd-trace-rb/issues/2732
[#2733]: https://github.com/DataDog/dd-trace-rb/issues/2733
[#2739]: https://github.com/DataDog/dd-trace-rb/issues/2739
[#2741]: https://github.com/DataDog/dd-trace-rb/issues/2741
[#2748]: https://github.com/DataDog/dd-trace-rb/issues/2748
[#2756]: https://github.com/DataDog/dd-trace-rb/issues/2756
[#2757]: https://github.com/DataDog/dd-trace-rb/issues/2757
[#2760]: https://github.com/DataDog/dd-trace-rb/issues/2760
[#2762]: https://github.com/DataDog/dd-trace-rb/issues/2762
[#2765]: https://github.com/DataDog/dd-trace-rb/issues/2765
[#2769]: https://github.com/DataDog/dd-trace-rb/issues/2769
[#2770]: https://github.com/DataDog/dd-trace-rb/issues/2770
[#2771]: https://github.com/DataDog/dd-trace-rb/issues/2771
[#2773]: https://github.com/DataDog/dd-trace-rb/issues/2773
[#2778]: https://github.com/DataDog/dd-trace-rb/issues/2778
[#2788]: https://github.com/DataDog/dd-trace-rb/issues/2788
[#2789]: https://github.com/DataDog/dd-trace-rb/issues/2789
[#2794]: https://github.com/DataDog/dd-trace-rb/issues/2794
[#2805]: https://github.com/DataDog/dd-trace-rb/issues/2805
[#2806]: https://github.com/DataDog/dd-trace-rb/issues/2806
[#2810]: https://github.com/DataDog/dd-trace-rb/issues/2810
[#2814]: https://github.com/DataDog/dd-trace-rb/issues/2814
[#2815]: https://github.com/DataDog/dd-trace-rb/issues/2815
[#2822]: https://github.com/DataDog/dd-trace-rb/issues/2822
[#2824]: https://github.com/DataDog/dd-trace-rb/issues/2824
[#2826]: https://github.com/DataDog/dd-trace-rb/issues/2826
[#2829]: https://github.com/DataDog/dd-trace-rb/issues/2829
[#2836]: https://github.com/DataDog/dd-trace-rb/issues/2836
[#2840]: https://github.com/DataDog/dd-trace-rb/issues/2840
[#2848]: https://github.com/DataDog/dd-trace-rb/issues/2848
[#2853]: https://github.com/DataDog/dd-trace-rb/issues/2853
[#2854]: https://github.com/DataDog/dd-trace-rb/issues/2854
[#2855]: https://github.com/DataDog/dd-trace-rb/issues/2855
[#2856]: https://github.com/DataDog/dd-trace-rb/issues/2856
[#2858]: https://github.com/DataDog/dd-trace-rb/issues/2858
[#2860]: https://github.com/DataDog/dd-trace-rb/issues/2860
[#2864]: https://github.com/DataDog/dd-trace-rb/issues/2864
[#2866]: https://github.com/DataDog/dd-trace-rb/issues/2866
[#2867]: https://github.com/DataDog/dd-trace-rb/issues/2867
[#2869]: https://github.com/DataDog/dd-trace-rb/issues/2869
[#2873]: https://github.com/DataDog/dd-trace-rb/issues/2873
[#2874]: https://github.com/DataDog/dd-trace-rb/issues/2874
[#2875]: https://github.com/DataDog/dd-trace-rb/issues/2875
[#2877]: https://github.com/DataDog/dd-trace-rb/issues/2877
[#2879]: https://github.com/DataDog/dd-trace-rb/issues/2879
[#2882]: https://github.com/DataDog/dd-trace-rb/issues/2882
[#2883]: https://github.com/DataDog/dd-trace-rb/issues/2883
[#2890]: https://github.com/DataDog/dd-trace-rb/issues/2890
[#2891]: https://github.com/DataDog/dd-trace-rb/issues/2891
[#2895]: https://github.com/DataDog/dd-trace-rb/issues/2895
[#2896]: https://github.com/DataDog/dd-trace-rb/issues/2896
[#2898]: https://github.com/DataDog/dd-trace-rb/issues/2898
[#2900]: https://github.com/DataDog/dd-trace-rb/issues/2900
[#2903]: https://github.com/DataDog/dd-trace-rb/issues/2903
[#2913]: https://github.com/DataDog/dd-trace-rb/issues/2913
[#2915]: https://github.com/DataDog/dd-trace-rb/issues/2915
[#2926]: https://github.com/DataDog/dd-trace-rb/issues/2926
[#2928]: https://github.com/DataDog/dd-trace-rb/issues/2928
[#2931]: https://github.com/DataDog/dd-trace-rb/issues/2931
[#2932]: https://github.com/DataDog/dd-trace-rb/issues/2932
[#2935]: https://github.com/DataDog/dd-trace-rb/issues/2935
[#2939]: https://github.com/DataDog/dd-trace-rb/issues/2939
[#2940]: https://github.com/DataDog/dd-trace-rb/issues/2940
[#2941]: https://github.com/DataDog/dd-trace-rb/issues/2941
[#2946]: https://github.com/DataDog/dd-trace-rb/issues/2946
[#2948]: https://github.com/DataDog/dd-trace-rb/issues/2948
[#2950]: https://github.com/DataDog/dd-trace-rb/issues/2950
[#2952]: https://github.com/DataDog/dd-trace-rb/issues/2952
[#2956]: https://github.com/DataDog/dd-trace-rb/issues/2956
[#2957]: https://github.com/DataDog/dd-trace-rb/issues/2957
[#2959]: https://github.com/DataDog/dd-trace-rb/issues/2959
[#2960]: https://github.com/DataDog/dd-trace-rb/issues/2960
[#2961]: https://github.com/DataDog/dd-trace-rb/issues/2961
[#2962]: https://github.com/DataDog/dd-trace-rb/issues/2962
[#2967]: https://github.com/DataDog/dd-trace-rb/issues/2967
[#2968]: https://github.com/DataDog/dd-trace-rb/issues/2968
[#2971]: https://github.com/DataDog/dd-trace-rb/issues/2971
[#2972]: https://github.com/DataDog/dd-trace-rb/issues/2972
[#2973]: https://github.com/DataDog/dd-trace-rb/issues/2973
[#2974]: https://github.com/DataDog/dd-trace-rb/issues/2974
[#2975]: https://github.com/DataDog/dd-trace-rb/issues/2975
[#2977]: https://github.com/DataDog/dd-trace-rb/issues/2977
[#2978]: https://github.com/DataDog/dd-trace-rb/issues/2978
[#2982]: https://github.com/DataDog/dd-trace-rb/issues/2982
[#2983]: https://github.com/DataDog/dd-trace-rb/issues/2983
[#2988]: https://github.com/DataDog/dd-trace-rb/issues/2988
[#2992]: https://github.com/DataDog/dd-trace-rb/issues/2992
[#2993]: https://github.com/DataDog/dd-trace-rb/issues/2993
[#2994]: https://github.com/DataDog/dd-trace-rb/issues/2994
[#2999]: https://github.com/DataDog/dd-trace-rb/issues/2999
[#3005]: https://github.com/DataDog/dd-trace-rb/issues/3005
[#3007]: https://github.com/DataDog/dd-trace-rb/issues/3007
[#3011]: https://github.com/DataDog/dd-trace-rb/issues/3011
[#3018]: https://github.com/DataDog/dd-trace-rb/issues/3018
[#3019]: https://github.com/DataDog/dd-trace-rb/issues/3019
[#3020]: https://github.com/DataDog/dd-trace-rb/issues/3020
[#3022]: https://github.com/DataDog/dd-trace-rb/issues/3022
[#3025]: https://github.com/DataDog/dd-trace-rb/issues/3025
[#3033]: https://github.com/DataDog/dd-trace-rb/issues/3033
[#3037]: https://github.com/DataDog/dd-trace-rb/issues/3037
[#3038]: https://github.com/DataDog/dd-trace-rb/issues/3038
[#3039]: https://github.com/DataDog/dd-trace-rb/issues/3039
[#3041]: https://github.com/DataDog/dd-trace-rb/issues/3041
[#3045]: https://github.com/DataDog/dd-trace-rb/issues/3045
[#3051]: https://github.com/DataDog/dd-trace-rb/issues/3051
[#3054]: https://github.com/DataDog/dd-trace-rb/issues/3054
[#3056]: https://github.com/DataDog/dd-trace-rb/issues/3056
[#3057]: https://github.com/DataDog/dd-trace-rb/issues/3057
[#3060]: https://github.com/DataDog/dd-trace-rb/issues/3060
[#3061]: https://github.com/DataDog/dd-trace-rb/issues/3061
[#3062]: https://github.com/DataDog/dd-trace-rb/issues/3062
[#3065]: https://github.com/DataDog/dd-trace-rb/issues/3065
[#3070]: https://github.com/DataDog/dd-trace-rb/issues/3070
[#3074]: https://github.com/DataDog/dd-trace-rb/issues/3074
[#3080]: https://github.com/DataDog/dd-trace-rb/issues/3080
[#3085]: https://github.com/DataDog/dd-trace-rb/issues/3085
[#3086]: https://github.com/DataDog/dd-trace-rb/issues/3086
[#3087]: https://github.com/DataDog/dd-trace-rb/issues/3087
[#3091]: https://github.com/DataDog/dd-trace-rb/issues/3091
[#3095]: https://github.com/DataDog/dd-trace-rb/issues/3095
[#3096]: https://github.com/DataDog/dd-trace-rb/issues/3096
[#3099]: https://github.com/DataDog/dd-trace-rb/issues/3099
[#3100]: https://github.com/DataDog/dd-trace-rb/issues/3100
[#3102]: https://github.com/DataDog/dd-trace-rb/issues/3102
[#3103]: https://github.com/DataDog/dd-trace-rb/issues/3103
[#3104]: https://github.com/DataDog/dd-trace-rb/issues/3104
[#3106]: https://github.com/DataDog/dd-trace-rb/issues/3106
[#3107]: https://github.com/DataDog/dd-trace-rb/issues/3107
[#3109]: https://github.com/DataDog/dd-trace-rb/issues/3109
[#3127]: https://github.com/DataDog/dd-trace-rb/issues/3127
[#3128]: https://github.com/DataDog/dd-trace-rb/issues/3128
[#3131]: https://github.com/DataDog/dd-trace-rb/issues/3131
[#3132]: https://github.com/DataDog/dd-trace-rb/issues/3132
[#3139]: https://github.com/DataDog/dd-trace-rb/issues/3139
[#3140]: https://github.com/DataDog/dd-trace-rb/issues/3140
[#3145]: https://github.com/DataDog/dd-trace-rb/issues/3145
[#3148]: https://github.com/DataDog/dd-trace-rb/issues/3148
[#3150]: https://github.com/DataDog/dd-trace-rb/issues/3150
[#3152]: https://github.com/DataDog/dd-trace-rb/issues/3152
[#3153]: https://github.com/DataDog/dd-trace-rb/issues/3153
[#3158]: https://github.com/DataDog/dd-trace-rb/issues/3158
[#3162]: https://github.com/DataDog/dd-trace-rb/issues/3162
[#3163]: https://github.com/DataDog/dd-trace-rb/issues/3163
[#3166]: https://github.com/DataDog/dd-trace-rb/issues/3166
[#3167]: https://github.com/DataDog/dd-trace-rb/issues/3167
[#3169]: https://github.com/DataDog/dd-trace-rb/issues/3169
[#3171]: https://github.com/DataDog/dd-trace-rb/issues/3171
[#3172]: https://github.com/DataDog/dd-trace-rb/issues/3172
[#3176]: https://github.com/DataDog/dd-trace-rb/issues/3176
[#3177]: https://github.com/DataDog/dd-trace-rb/issues/3177
[#3183]: https://github.com/DataDog/dd-trace-rb/issues/3183
[#3186]: https://github.com/DataDog/dd-trace-rb/issues/3186
[#3188]: https://github.com/DataDog/dd-trace-rb/issues/3188
[#3189]: https://github.com/DataDog/dd-trace-rb/issues/3189
[#3190]: https://github.com/DataDog/dd-trace-rb/issues/3190
[#3197]: https://github.com/DataDog/dd-trace-rb/issues/3197
[#3204]: https://github.com/DataDog/dd-trace-rb/issues/3204
[#3206]: https://github.com/DataDog/dd-trace-rb/issues/3206
[#3207]: https://github.com/DataDog/dd-trace-rb/issues/3207
[#3223]: https://github.com/DataDog/dd-trace-rb/issues/3223
[#3229]: https://github.com/DataDog/dd-trace-rb/issues/3229
[#3234]: https://github.com/DataDog/dd-trace-rb/issues/3234
[#3235]: https://github.com/DataDog/dd-trace-rb/issues/3235
[#3240]: https://github.com/DataDog/dd-trace-rb/issues/3240
[#3242]: https://github.com/DataDog/dd-trace-rb/issues/3242
[#3243]: https://github.com/DataDog/dd-trace-rb/issues/3243
[#3248]: https://github.com/DataDog/dd-trace-rb/issues/3248
[#3252]: https://github.com/DataDog/dd-trace-rb/issues/3252
[#3255]: https://github.com/DataDog/dd-trace-rb/issues/3255
[#3259]: https://github.com/DataDog/dd-trace-rb/issues/3259
[#3262]: https://github.com/DataDog/dd-trace-rb/issues/3262
[#3266]: https://github.com/DataDog/dd-trace-rb/issues/3266
[#3267]: https://github.com/DataDog/dd-trace-rb/issues/3267
[#3270]: https://github.com/DataDog/dd-trace-rb/issues/3270
[#3271]: https://github.com/DataDog/dd-trace-rb/issues/3271
[#3273]: https://github.com/DataDog/dd-trace-rb/issues/3273
[#3274]: https://github.com/DataDog/dd-trace-rb/issues/3274
[#3278]: https://github.com/DataDog/dd-trace-rb/issues/3278
[#3279]: https://github.com/DataDog/dd-trace-rb/issues/3279
[#3280]: https://github.com/DataDog/dd-trace-rb/issues/3280
[#3281]: https://github.com/DataDog/dd-trace-rb/issues/3281
[#3284]: https://github.com/DataDog/dd-trace-rb/issues/3284
[#3286]: https://github.com/DataDog/dd-trace-rb/issues/3286
[#3287]: https://github.com/DataDog/dd-trace-rb/issues/3287
[#3288]: https://github.com/DataDog/dd-trace-rb/issues/3288
[#3289]: https://github.com/DataDog/dd-trace-rb/issues/3289
[#3291]: https://github.com/DataDog/dd-trace-rb/issues/3291
[#3293]: https://github.com/DataDog/dd-trace-rb/issues/3293
[#3294]: https://github.com/DataDog/dd-trace-rb/issues/3294
[#3295]: https://github.com/DataDog/dd-trace-rb/issues/3295
[#3297]: https://github.com/DataDog/dd-trace-rb/issues/3297
[#3298]: https://github.com/DataDog/dd-trace-rb/issues/3298
[#3299]: https://github.com/DataDog/dd-trace-rb/issues/3299
[#3300]: https://github.com/DataDog/dd-trace-rb/issues/3300
[#3303]: https://github.com/DataDog/dd-trace-rb/issues/3303
[#3307]: https://github.com/DataDog/dd-trace-rb/issues/3307
[#3308]: https://github.com/DataDog/dd-trace-rb/issues/3308
[#3309]: https://github.com/DataDog/dd-trace-rb/issues/3309
[#3310]: https://github.com/DataDog/dd-trace-rb/issues/3310
[#3313]: https://github.com/DataDog/dd-trace-rb/issues/3313
[#3315]: https://github.com/DataDog/dd-trace-rb/issues/3315
[#3316]: https://github.com/DataDog/dd-trace-rb/issues/3316
[#3317]: https://github.com/DataDog/dd-trace-rb/issues/3317
[#3320]: https://github.com/DataDog/dd-trace-rb/issues/3320
[#3322]: https://github.com/DataDog/dd-trace-rb/issues/3322
[#3324]: https://github.com/DataDog/dd-trace-rb/issues/3324
[#3325]: https://github.com/DataDog/dd-trace-rb/issues/3325
[#3326]: https://github.com/DataDog/dd-trace-rb/issues/3326
[#3328]: https://github.com/DataDog/dd-trace-rb/issues/3328
[#3329]: https://github.com/DataDog/dd-trace-rb/issues/3329
[#3330]: https://github.com/DataDog/dd-trace-rb/issues/3330
[#3332]: https://github.com/DataDog/dd-trace-rb/issues/3332
[#3333]: https://github.com/DataDog/dd-trace-rb/issues/3333
[#3335]: https://github.com/DataDog/dd-trace-rb/issues/3335
[#3336]: https://github.com/DataDog/dd-trace-rb/issues/3336
[#3338]: https://github.com/DataDog/dd-trace-rb/issues/3338
[#3341]: https://github.com/DataDog/dd-trace-rb/issues/3341
[#3344]: https://github.com/DataDog/dd-trace-rb/issues/3344
[#3345]: https://github.com/DataDog/dd-trace-rb/issues/3345
[#3349]: https://github.com/DataDog/dd-trace-rb/issues/3349
[#3350]: https://github.com/DataDog/dd-trace-rb/issues/3350
[#3352]: https://github.com/DataDog/dd-trace-rb/issues/3352
[#3354]: https://github.com/DataDog/dd-trace-rb/issues/3354
[#3356]: https://github.com/DataDog/dd-trace-rb/issues/3356
[#3357]: https://github.com/DataDog/dd-trace-rb/issues/3357
[#3360]: https://github.com/DataDog/dd-trace-rb/issues/3360
[#3361]: https://github.com/DataDog/dd-trace-rb/issues/3361
[#3362]: https://github.com/DataDog/dd-trace-rb/issues/3362
[#3365]: https://github.com/DataDog/dd-trace-rb/issues/3365
[#3366]: https://github.com/DataDog/dd-trace-rb/issues/3366
[#3367]: https://github.com/DataDog/dd-trace-rb/issues/3367
[#3369]: https://github.com/DataDog/dd-trace-rb/issues/3369
[#3370]: https://github.com/DataDog/dd-trace-rb/issues/3370
[#3373]: https://github.com/DataDog/dd-trace-rb/issues/3373
[#3374]: https://github.com/DataDog/dd-trace-rb/issues/3374
[#3384]: https://github.com/DataDog/dd-trace-rb/issues/3384
[#3386]: https://github.com/DataDog/dd-trace-rb/issues/3386
[#3388]: https://github.com/DataDog/dd-trace-rb/issues/3388
[#3392]: https://github.com/DataDog/dd-trace-rb/issues/3392
[#3395]: https://github.com/DataDog/dd-trace-rb/issues/3395
[#3396]: https://github.com/DataDog/dd-trace-rb/issues/3396
[#3398]: https://github.com/DataDog/dd-trace-rb/issues/3398
[#3399]: https://github.com/DataDog/dd-trace-rb/issues/3399
[#3400]: https://github.com/DataDog/dd-trace-rb/issues/3400
[#3401]: https://github.com/DataDog/dd-trace-rb/issues/3401
[#3402]: https://github.com/DataDog/dd-trace-rb/issues/3402
[#3403]: https://github.com/DataDog/dd-trace-rb/issues/3403
[#3404]: https://github.com/DataDog/dd-trace-rb/issues/3404
[#3408]: https://github.com/DataDog/dd-trace-rb/issues/3408
[#3409]: https://github.com/DataDog/dd-trace-rb/issues/3409
[#3417]: https://github.com/DataDog/dd-trace-rb/issues/3417
[#3420]: https://github.com/DataDog/dd-trace-rb/issues/3420
[#3423]: https://github.com/DataDog/dd-trace-rb/issues/3423
[#3426]: https://github.com/DataDog/dd-trace-rb/issues/3426
[#3427]: https://github.com/DataDog/dd-trace-rb/issues/3427
[#3428]: https://github.com/DataDog/dd-trace-rb/issues/3428
[#3431]: https://github.com/DataDog/dd-trace-rb/issues/3431
[#3434]: https://github.com/DataDog/dd-trace-rb/issues/3434
[#3438]: https://github.com/DataDog/dd-trace-rb/issues/3438
[#3439]: https://github.com/DataDog/dd-trace-rb/issues/3439
[#3440]: https://github.com/DataDog/dd-trace-rb/issues/3440
[#3441]: https://github.com/DataDog/dd-trace-rb/issues/3441
[#3443]: https://github.com/DataDog/dd-trace-rb/issues/3443
[#3454]: https://github.com/DataDog/dd-trace-rb/issues/3454
[#3455]: https://github.com/DataDog/dd-trace-rb/issues/3455
[#3463]: https://github.com/DataDog/dd-trace-rb/issues/3463
[#3466]: https://github.com/DataDog/dd-trace-rb/issues/3466
[#3468]: https://github.com/DataDog/dd-trace-rb/issues/3468
[#3473]: https://github.com/DataDog/dd-trace-rb/issues/3473
[#3486]: https://github.com/DataDog/dd-trace-rb/issues/3486
[#3488]: https://github.com/DataDog/dd-trace-rb/issues/3488
[#3490]: https://github.com/DataDog/dd-trace-rb/issues/3490
[#3491]: https://github.com/DataDog/dd-trace-rb/issues/3491
[#3495]: https://github.com/DataDog/dd-trace-rb/issues/3495
[#3501]: https://github.com/DataDog/dd-trace-rb/issues/3501
[#3502]: https://github.com/DataDog/dd-trace-rb/issues/3502
[#3503]: https://github.com/DataDog/dd-trace-rb/issues/3503
[#3506]: https://github.com/DataDog/dd-trace-rb/issues/3506
[#3511]: https://github.com/DataDog/dd-trace-rb/issues/3511
[#3516]: https://github.com/DataDog/dd-trace-rb/issues/3516
[#3518]: https://github.com/DataDog/dd-trace-rb/issues/3518
[#3519]: https://github.com/DataDog/dd-trace-rb/issues/3519
[#3520]: https://github.com/DataDog/dd-trace-rb/issues/3520
[#3523]: https://github.com/DataDog/dd-trace-rb/issues/3523
[#3528]: https://github.com/DataDog/dd-trace-rb/issues/3528
[#3531]: https://github.com/DataDog/dd-trace-rb/issues/3531
[#3535]: https://github.com/DataDog/dd-trace-rb/issues/3535
[#3536]: https://github.com/DataDog/dd-trace-rb/issues/3536
[#3539]: https://github.com/DataDog/dd-trace-rb/issues/3539
[#3546]: https://github.com/DataDog/dd-trace-rb/issues/3546
[#3551]: https://github.com/DataDog/dd-trace-rb/issues/3551
[#3558]: https://github.com/DataDog/dd-trace-rb/issues/3558
[#3565]: https://github.com/DataDog/dd-trace-rb/issues/3565
[#3572]: https://github.com/DataDog/dd-trace-rb/issues/3572
[#3573]: https://github.com/DataDog/dd-trace-rb/issues/3573
[#3582]: https://github.com/DataDog/dd-trace-rb/issues/3582
[#3585]: https://github.com/DataDog/dd-trace-rb/issues/3585
[#3587]: https://github.com/DataDog/dd-trace-rb/issues/3587
[#3597]: https://github.com/DataDog/dd-trace-rb/issues/3597
[#3598]: https://github.com/DataDog/dd-trace-rb/issues/3598
[#3610]: https://github.com/DataDog/dd-trace-rb/issues/3610
[#3616]: https://github.com/DataDog/dd-trace-rb/issues/3616
[#3617]: https://github.com/DataDog/dd-trace-rb/issues/3617
[#3618]: https://github.com/DataDog/dd-trace-rb/issues/3618
[#3619]: https://github.com/DataDog/dd-trace-rb/issues/3619
[#3621]: https://github.com/DataDog/dd-trace-rb/issues/3621
[#3623]: https://github.com/DataDog/dd-trace-rb/issues/3623
[#3624]: https://github.com/DataDog/dd-trace-rb/issues/3624
[#3627]: https://github.com/DataDog/dd-trace-rb/issues/3627
[#3630]: https://github.com/DataDog/dd-trace-rb/issues/3630
[#3631]: https://github.com/DataDog/dd-trace-rb/issues/3631
[#3645]: https://github.com/DataDog/dd-trace-rb/issues/3645
[#3651]: https://github.com/DataDog/dd-trace-rb/issues/3651
[#3657]: https://github.com/DataDog/dd-trace-rb/issues/3657
[#3664]: https://github.com/DataDog/dd-trace-rb/issues/3664
[#3672]: https://github.com/DataDog/dd-trace-rb/issues/3672
[#3695]: https://github.com/DataDog/dd-trace-rb/issues/3695
[#3706]: https://github.com/DataDog/dd-trace-rb/issues/3706
[#3709]: https://github.com/DataDog/dd-trace-rb/issues/3709
[#3718]: https://github.com/DataDog/dd-trace-rb/issues/3718
[#3720]: https://github.com/DataDog/dd-trace-rb/issues/3720
[#3725]: https://github.com/DataDog/dd-trace-rb/issues/3725
[#3729]: https://github.com/DataDog/dd-trace-rb/issues/3729
[#3730]: https://github.com/DataDog/dd-trace-rb/issues/3730
[#3731]: https://github.com/DataDog/dd-trace-rb/issues/3731
[#3743]: https://github.com/DataDog/dd-trace-rb/issues/3743
[#3749]: https://github.com/DataDog/dd-trace-rb/issues/3749
[#3750]: https://github.com/DataDog/dd-trace-rb/issues/3750
[#3753]: https://github.com/DataDog/dd-trace-rb/issues/3753
[#3757]: https://github.com/DataDog/dd-trace-rb/issues/3757
[#3759]: https://github.com/DataDog/dd-trace-rb/issues/3759
[#3769]: https://github.com/DataDog/dd-trace-rb/issues/3769
[#3770]: https://github.com/DataDog/dd-trace-rb/issues/3770
[#3772]: https://github.com/DataDog/dd-trace-rb/issues/3772
[#3774]: https://github.com/DataDog/dd-trace-rb/issues/3774
[#3776]: https://github.com/DataDog/dd-trace-rb/issues/3776
[#3779]: https://github.com/DataDog/dd-trace-rb/issues/3779
[#3785]: https://github.com/DataDog/dd-trace-rb/issues/3785
[#3789]: https://github.com/DataDog/dd-trace-rb/issues/3789
[#3790]: https://github.com/DataDog/dd-trace-rb/issues/3790
[#3793]: https://github.com/DataDog/dd-trace-rb/issues/3793
[#3795]: https://github.com/DataDog/dd-trace-rb/issues/3795
[#3797]: https://github.com/DataDog/dd-trace-rb/issues/3797
[#3798]: https://github.com/DataDog/dd-trace-rb/issues/3798
[#3799]: https://github.com/DataDog/dd-trace-rb/issues/3799
[#3805]: https://github.com/DataDog/dd-trace-rb/issues/3805
[#3809]: https://github.com/DataDog/dd-trace-rb/issues/3809
[#3812]: https://github.com/DataDog/dd-trace-rb/issues/3812
[#3813]: https://github.com/DataDog/dd-trace-rb/issues/3813
[#3814]: https://github.com/DataDog/dd-trace-rb/issues/3814
[#3826]: https://github.com/DataDog/dd-trace-rb/issues/3826
[#3837]: https://github.com/DataDog/dd-trace-rb/issues/3837
[#3839]: https://github.com/DataDog/dd-trace-rb/issues/3839
[#3841]: https://github.com/DataDog/dd-trace-rb/issues/3841
[#3846]: https://github.com/DataDog/dd-trace-rb/issues/3846
[#3849]: https://github.com/DataDog/dd-trace-rb/issues/3849
[#3852]: https://github.com/DataDog/dd-trace-rb/issues/3852
[#3857]: https://github.com/DataDog/dd-trace-rb/issues/3857
[#3859]: https://github.com/DataDog/dd-trace-rb/issues/3859
[#3867]: https://github.com/DataDog/dd-trace-rb/issues/3867
[#3887]: https://github.com/DataDog/dd-trace-rb/issues/3887
[#3888]: https://github.com/DataDog/dd-trace-rb/issues/3888
[#3929]: https://github.com/DataDog/dd-trace-rb/issues/3929
[#3956]: https://github.com/DataDog/dd-trace-rb/issues/3956
[#3969]: https://github.com/DataDog/dd-trace-rb/issues/3969
[#3970]: https://github.com/DataDog/dd-trace-rb/issues/3970
[#3984]: https://github.com/DataDog/dd-trace-rb/issues/3984
[#3996]: https://github.com/DataDog/dd-trace-rb/issues/3996
[#3997]: https://github.com/DataDog/dd-trace-rb/issues/3997
[#4014]: https://github.com/DataDog/dd-trace-rb/issues/4014
[#4020]: https://github.com/DataDog/dd-trace-rb/issues/4020
[#4022]: https://github.com/DataDog/dd-trace-rb/issues/4022
[#4024]: https://github.com/DataDog/dd-trace-rb/issues/4024
[#4027]: https://github.com/DataDog/dd-trace-rb/issues/4027
[#4033]: https://github.com/DataDog/dd-trace-rb/issues/4033
[#4065]: https://github.com/DataDog/dd-trace-rb/issues/4065
[#4066]: https://github.com/DataDog/dd-trace-rb/issues/4066
[#4075]: https://github.com/DataDog/dd-trace-rb/issues/4075
[#4078]: https://github.com/DataDog/dd-trace-rb/issues/4078
[#4082]: https://github.com/DataDog/dd-trace-rb/issues/4082
[#4083]: https://github.com/DataDog/dd-trace-rb/issues/4083
[#4085]: https://github.com/DataDog/dd-trace-rb/issues/4085
[#4137]: https://github.com/DataDog/dd-trace-rb/issues/4137
[#4140]: https://github.com/DataDog/dd-trace-rb/issues/4140
[#4147]: https://github.com/DataDog/dd-trace-rb/issues/4147
[#4153]: https://github.com/DataDog/dd-trace-rb/issues/4153
[#4161]: https://github.com/DataDog/dd-trace-rb/issues/4161
[#4164]: https://github.com/DataDog/dd-trace-rb/issues/4164
[#4167]: https://github.com/DataDog/dd-trace-rb/issues/4167
[#4177]: https://github.com/DataDog/dd-trace-rb/issues/4177
[#4178]: https://github.com/DataDog/dd-trace-rb/issues/4178
[#4195]: https://github.com/DataDog/dd-trace-rb/issues/4195
[#4196]: https://github.com/DataDog/dd-trace-rb/issues/4196
[#4197]: https://github.com/DataDog/dd-trace-rb/issues/4197
[#4208]: https://github.com/DataDog/dd-trace-rb/issues/4208
[#4228]: https://github.com/DataDog/dd-trace-rb/issues/4228
[#4232]: https://github.com/DataDog/dd-trace-rb/issues/4232
[#4237]: https://github.com/DataDog/dd-trace-rb/issues/4237
[#4239]: https://github.com/DataDog/dd-trace-rb/issues/4239
[#4240]: https://github.com/DataDog/dd-trace-rb/issues/4240
[#4249]: https://github.com/DataDog/dd-trace-rb/issues/4249
[#4257]: https://github.com/DataDog/dd-trace-rb/issues/4257
[#4266]: https://github.com/DataDog/dd-trace-rb/issues/4266
[#4272]: https://github.com/DataDog/dd-trace-rb/issues/4272
[#4283]: https://github.com/DataDog/dd-trace-rb/issues/4283
[#4285]: https://github.com/DataDog/dd-trace-rb/issues/4285
[#4288]: https://github.com/DataDog/dd-trace-rb/issues/4288
[#4292]: https://github.com/DataDog/dd-trace-rb/issues/4292
[#4301]: https://github.com/DataDog/dd-trace-rb/issues/4301
[#4303]: https://github.com/DataDog/dd-trace-rb/issues/4303
[#4311]: https://github.com/DataDog/dd-trace-rb/issues/4311
[#4321]: https://github.com/DataDog/dd-trace-rb/issues/4321
[#4323]: https://github.com/DataDog/dd-trace-rb/issues/4323
[#4346]: https://github.com/DataDog/dd-trace-rb/issues/4346
[#4352]: https://github.com/DataDog/dd-trace-rb/issues/4352
[#4353]: https://github.com/DataDog/dd-trace-rb/issues/4353
[#4360]: https://github.com/DataDog/dd-trace-rb/issues/4360
[#4363]: https://github.com/DataDog/dd-trace-rb/issues/4363
[#4366]: https://github.com/DataDog/dd-trace-rb/issues/4366
[#4391]: https://github.com/DataDog/dd-trace-rb/issues/4391
[#4398]: https://github.com/DataDog/dd-trace-rb/issues/4398
[#4399]: https://github.com/DataDog/dd-trace-rb/issues/4399
[#4401]: https://github.com/DataDog/dd-trace-rb/issues/4401
[#4403]: https://github.com/DataDog/dd-trace-rb/issues/4403
[#4406]: https://github.com/DataDog/dd-trace-rb/issues/4406
[#4411]: https://github.com/DataDog/dd-trace-rb/issues/4411
[#4422]: https://github.com/DataDog/dd-trace-rb/issues/4422
[#4424]: https://github.com/DataDog/dd-trace-rb/issues/4424
[#4425]: https://github.com/DataDog/dd-trace-rb/issues/4425
[#4426]: https://github.com/DataDog/dd-trace-rb/issues/4426
[#4433]: https://github.com/DataDog/dd-trace-rb/issues/4433
[#4437]: https://github.com/DataDog/dd-trace-rb/issues/4437
[#4455]: https://github.com/DataDog/dd-trace-rb/issues/4455
[#4460]: https://github.com/DataDog/dd-trace-rb/issues/4460
[#4473]: https://github.com/DataDog/dd-trace-rb/issues/4473
[#4493]: https://github.com/DataDog/dd-trace-rb/issues/4493
[#4497]: https://github.com/DataDog/dd-trace-rb/issues/4497
[#4498]: https://github.com/DataDog/dd-trace-rb/issues/4498
[#4505]: https://github.com/DataDog/dd-trace-rb/issues/4505
[#4507]: https://github.com/DataDog/dd-trace-rb/issues/4507
[#4509]: https://github.com/DataDog/dd-trace-rb/issues/4509
[#4526]: https://github.com/DataDog/dd-trace-rb/issues/4526
[#4528]: https://github.com/DataDog/dd-trace-rb/issues/4528
[#4530]: https://github.com/DataDog/dd-trace-rb/issues/4530
[#4534]: https://github.com/DataDog/dd-trace-rb/issues/4534
[#4547]: https://github.com/DataDog/dd-trace-rb/issues/4547
[#4549]: https://github.com/DataDog/dd-trace-rb/issues/4549
[#4552]: https://github.com/DataDog/dd-trace-rb/issues/4552
[#4558]: https://github.com/DataDog/dd-trace-rb/issues/4558
[#4568]: https://github.com/DataDog/dd-trace-rb/issues/4568
[#4573]: https://github.com/DataDog/dd-trace-rb/issues/4573
[#4575]: https://github.com/DataDog/dd-trace-rb/issues/4575
[#4577]: https://github.com/DataDog/dd-trace-rb/issues/4577
[#4580]: https://github.com/DataDog/dd-trace-rb/issues/4580
[#4581]: https://github.com/DataDog/dd-trace-rb/issues/4581
[#4590]: https://github.com/DataDog/dd-trace-rb/issues/4590
[#4600]: https://github.com/DataDog/dd-trace-rb/issues/4600
[#4602]: https://github.com/DataDog/dd-trace-rb/issues/4602
[#4604]: https://github.com/DataDog/dd-trace-rb/issues/4604
[#4610]: https://github.com/DataDog/dd-trace-rb/issues/4610
[#4611]: https://github.com/DataDog/dd-trace-rb/issues/4611
[#4613]: https://github.com/DataDog/dd-trace-rb/issues/4613
[#4614]: https://github.com/DataDog/dd-trace-rb/issues/4614
[#4616]: https://github.com/DataDog/dd-trace-rb/issues/4616
[#4625]: https://github.com/DataDog/dd-trace-rb/issues/4625
[#4644]: https://github.com/DataDog/dd-trace-rb/issues/4644
[#4651]: https://github.com/DataDog/dd-trace-rb/issues/4651
[#4653]: https://github.com/DataDog/dd-trace-rb/issues/4653
[#4656]: https://github.com/DataDog/dd-trace-rb/issues/4656
[#4665]: https://github.com/DataDog/dd-trace-rb/issues/4665
[#4668]: https://github.com/DataDog/dd-trace-rb/issues/4668
[#4669]: https://github.com/DataDog/dd-trace-rb/issues/4669
[#4672]: https://github.com/DataDog/dd-trace-rb/issues/4672
[#4673]: https://github.com/DataDog/dd-trace-rb/issues/4673
[#4678]: https://github.com/DataDog/dd-trace-rb/issues/4678
[#4679]: https://github.com/DataDog/dd-trace-rb/issues/4679
[#4681]: https://github.com/DataDog/dd-trace-rb/issues/4681
[#4688]: https://github.com/DataDog/dd-trace-rb/issues/4688
[#4693]: https://github.com/DataDog/dd-trace-rb/issues/4693
[#4697]: https://github.com/DataDog/dd-trace-rb/issues/4697
[#4699]: https://github.com/DataDog/dd-trace-rb/issues/4699
[#4718]: https://github.com/DataDog/dd-trace-rb/issues/4718
[#4721]: https://github.com/DataDog/dd-trace-rb/issues/4721
[#4728]: https://github.com/DataDog/dd-trace-rb/issues/4728
[#4731]: https://github.com/DataDog/dd-trace-rb/issues/4731
[#4743]: https://github.com/DataDog/dd-trace-rb/issues/4743
[#4745]: https://github.com/DataDog/dd-trace-rb/issues/4745
[#4756]: https://github.com/DataDog/dd-trace-rb/issues/4756
[#4757]: https://github.com/DataDog/dd-trace-rb/issues/4757
[#4771]: https://github.com/DataDog/dd-trace-rb/issues/4771
[#4772]: https://github.com/DataDog/dd-trace-rb/issues/4772
[#4776]: https://github.com/DataDog/dd-trace-rb/issues/4776
[#4783]: https://github.com/DataDog/dd-trace-rb/issues/4783
[#4785]: https://github.com/DataDog/dd-trace-rb/issues/4785
[#4786]: https://github.com/DataDog/dd-trace-rb/issues/4786
[#4787]: https://github.com/DataDog/dd-trace-rb/issues/4787
[#4793]: https://github.com/DataDog/dd-trace-rb/issues/4793
[#4794]: https://github.com/DataDog/dd-trace-rb/issues/4794
[#4802]: https://github.com/DataDog/dd-trace-rb/issues/4802
[#4813]: https://github.com/DataDog/dd-trace-rb/issues/4813
[#4814]: https://github.com/DataDog/dd-trace-rb/issues/4814
[#4819]: https://github.com/DataDog/dd-trace-rb/issues/4819
[@AdrianLC]: https://github.com/AdrianLC
[@Azure7111]: https://github.com/Azure7111
[@BabyGroot]: https://github.com/BabyGroot
[@DocX]: https://github.com/DocX
[@Drowze]: https://github.com/Drowze
[@EpiFouloux]: https://github.com/EpiFouloux
[@EvNomad]: https://github.com/EvNomad
[@HeyNonster]: https://github.com/HeyNonster
[@HoneyryderChuck]: https://github.com/HoneyryderChuck
[@JamesHarker]: https://github.com/JamesHarker
[@Jared-Prime]: https://github.com/Jared-Prime
[@Joas1988]: https://github.com/Joas1988
[@JustSnow]: https://github.com/JustSnow
[@KJTsanaktsidis]: https://github.com/KJTsanaktsidis
[@KieranP]: https://github.com/KieranP
[@MMartyn]: https://github.com/MMartyn
[@NobodysNightmare]: https://github.com/NobodysNightmare
[@Redapted]: https://github.com/Redapted
[@Sticksword]: https://github.com/Sticksword
[@Supy]: https://github.com/Supy
[@Yurokle]: https://github.com/Yurokle
[@ZimbiX]: https://github.com/ZimbiX
[@agirlnamedsophia]: https://github.com/agirlnamedsophia
[@agrobbin]: https://github.com/agrobbin
[@ahammel]: https://github.com/ahammel
[@ahorner]: https://github.com/ahorner
[@al-kudryavtsev]: https://github.com/al-kudryavtsev
[@albertvaka]: https://github.com/albertvaka
[@alksl]: https://github.com/alksl
[@alloy]: https://github.com/alloy
[@aurelian]: https://github.com/aurelian
[@awendt]: https://github.com/awendt
[@bartekbsh]: https://github.com/bartekbsh
[@benhutton]: https://github.com/benhutton
[@bensheldon]: https://github.com/bensheldon
[@bheemreddy181]: https://github.com/bheemreddy181
[@blaines]: https://github.com/blaines
[@brafales]: https://github.com/brafales
[@bravehager]: https://github.com/bravehager
[@bzf]: https://github.com/bzf
[@callumj]: https://github.com/callumj
[@caramcc]: https://github.com/caramcc
[@carlallen]: https://github.com/carlallen
[@chychkan]: https://github.com/chychkan
[@cjford]: https://github.com/cjford
[@ck3g]: https://github.com/ck3g
[@components]: https://github.com/components
[@coneill-enhance]: https://github.com/coneill-enhance
[@cswatt]: https://github.com/cswatt
[@cwoodcox]: https://github.com/cwoodcox
[@danhodge]: https://github.com/danhodge
[@dasch]: https://github.com/dasch
[@dim]: https://github.com/dim
[@dirk]: https://github.com/dirk
[@djmb]: https://github.com/djmb
[@dorner]: https://github.com/dorner
[@drcapulet]: https://github.com/drcapulet
[@dudo]: https://github.com/dudo
[@e1senh0rn]: https://github.com/e1senh0rn
[@ecdemis123]: https://github.com/ecdemis123
[@elliterate]: https://github.com/elliterate
[@elyalvarado]: https://github.com/elyalvarado
[@ericmustin]: https://github.com/ericmustin
[@erict-square]: https://github.com/erict-square
[@errriclee]: https://github.com/errriclee
[@evan-waters]: https://github.com/evan-waters
[@fledman]: https://github.com/fledman
[@frsantos]: https://github.com/frsantos
[@fteem]: https://github.com/fteem
[@gaborszakacs]: https://github.com/gaborszakacs
[@giancarlocosta]: https://github.com/giancarlocosta
[@gingerlime]: https://github.com/gingerlime
[@gkampjes]: https://github.com/gkampjes
[@gottfrois]: https://github.com/gottfrois
[@guizmaii]: https://github.com/guizmaii
[@hatstand]: https://github.com/hatstand
[@hawknewton]: https://github.com/hawknewton
[@henrich-m]: https://github.com/henrich-m
[@hs-bguven]: https://github.com/hs-bguven
[@illdelph]: https://github.com/illdelph
[@ioquatix]: https://github.com/ioquatix
[@ixti]: https://github.com/ixti
[@jamiehodge]: https://github.com/jamiehodge
[@janz93]: https://github.com/janz93
[@jeffjo]: https://github.com/jeffjo
[@jennchenn]: https://github.com/jennchenn
[@jfrancoist]: https://github.com/jfrancoist
[@joeyAghion]: https://github.com/joeyAghion
[@jpaulgs]: https://github.com/jpaulgs
[@justinhoward]: https://github.com/justinhoward
[@jvalanen]: https://github.com/jvalanen
[@kelvin-acosta]: https://github.com/kelvin-acosta
[@kexoth]: https://github.com/kexoth
[@kissrobber]: https://github.com/kissrobber
[@kitop]: https://github.com/kitop
[@letiesperon]: https://github.com/letiesperon
[@link04]: https://github.com/link04
[@lloeki]: https://github.com/lloeki
[@mantrala]: https://github.com/mantrala
[@marcotc]: https://github.com/marcotc
[@marocchino]: https://github.com/marocchino
[@masato-hi]: https://github.com/masato-hi
[@matchbookmac]: https://github.com/matchbookmac
[@mberlanda]: https://github.com/mberlanda
[@mdehoog]: https://github.com/mdehoog
[@mdross95]: https://github.com/mdross95
[@michaelkl]: https://github.com/michaelkl
[@miketheman]: https://github.com/miketheman
[@mriddle]: https://github.com/mriddle
[@mscrivo]: https://github.com/mscrivo
[@mstruve]: https://github.com/mstruve
[@mustela]: https://github.com/mustela
[@nic-lan]: https://github.com/nic-lan
[@noma4i]: https://github.com/noma4i
[@norbertnytko]: https://github.com/norbertnytko
[@orekyuu]: https://github.com/orekyuu
[@palin]: https://github.com/palin
[@pj0tr]: https://github.com/pj0tr
[@psycholein]: https://github.com/psycholein
[@pzaich]: https://github.com/pzaich
[@rahul342]: https://github.com/rahul342
[@randy-girard]: https://github.com/randy-girard
[@renchap]: https://github.com/renchap
[@ricbartm]: https://github.com/ricbartm
[@roccoblues]: https://github.com/roccoblues
[@rqz13]: https://github.com/rqz13
[@saturnflyer]: https://github.com/saturnflyer
[@sco11morgan]: https://github.com/sco11morgan
[@senny]: https://github.com/senny
[@seuros]: https://github.com/seuros
[@shayonj]: https://github.com/shayonj
[@sinsoku]: https://github.com/sinsoku
[@skcc321]: https://github.com/skcc321
[@soulcutter]: https://github.com/soulcutter
[@sponomarev]: https://github.com/sponomarev
[@stefanahman]: https://github.com/stefanahman
[@steveh]: https://github.com/steveh
[@stormsilver]: https://github.com/stormsilver
[@sullimander]: https://github.com/sullimander
[@tjgrathwell]: https://github.com/tjgrathwell
[@tjwp]: https://github.com/tjwp
[@tomasv]: https://github.com/tomasv
[@tomgi]: https://github.com/tomgi
[@tonypinder]: https://github.com/tonypinder
[@twe4ked]: https://github.com/twe4ked
[@undergroundwebdesigns]: https://github.com/undergroundwebdesigns
[@vramaiah]: https://github.com/vramaiah
[@walterking]: https://github.com/walterking
[@y-yagi]: https://github.com/y-yagi
[@yujideveloper]: https://github.com/yujideveloper
[@yukimurasawa]: https://github.com/yukimurasawa
[@zachmccormick]: https://github.com/zachmccormick