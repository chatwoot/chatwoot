# Changelog

All notable changes to this project will be documented in this file.

## 1.12.0

- Remove Sidekiq.server? check from schedule loader (https://github.com/sidekiq-cron/sidekiq-cron/pull/436)
- Parse arguments on `args=` method (https://github.com/sidekiq-cron/sidekiq-cron/pull/442)
- Only check out a Redis connection if necessary (https://github.com/sidekiq-cron/sidekiq-cron/pull/438)

## 1.11.0

- Differentiates b/w "schedule" vs "dynamic" jobs (https://github.com/sidekiq-cron/sidekiq-cron/pull/431)
- Clears scheduled jobs upon schedule load (https://github.com/sidekiq-cron/sidekiq-cron/pull/431)
- Reduce gem size by excluding test files (https://github.com/sidekiq-cron/sidekiq-cron/pull/414)

## 1.10.1

- Use `hset` instead of deprecated `hmset` (https://github.com/sidekiq-cron/sidekiq-cron/pull/410)

## 1.10.0

- Remove EOL Ruby 2.6 support (https://github.com/sidekiq-cron/sidekiq-cron/pull/399)
- Add a logo for the project! (https://github.com/sidekiq-cron/sidekiq-cron/pull/402)
- Added support for ActiveRecord serialize/deserialize using GlobalID (https://github.com/sidekiq-cron/sidekiq-cron/pull/395)
- Allow for keyword args (`embedded: true`) in Poller (https://github.com/sidekiq-cron/sidekiq-cron/pull/398)
- Make last_enqueue_time be always an instance of Time (https://github.com/sidekiq-cron/sidekiq-cron/pull/354)
- Fix argument error problem update from 1.6.0 to newer (https://github.com/sidekiq-cron/sidekiq-cron/pull/392)
- Clear old jobs while loading the jobs from schedule via the schedule loader (https://github.com/sidekiq-cron/sidekiq-cron/pull/405)

## 1.9.1

- Always enqueue via Active Job interface when defined in cron job config (https://github.com/sidekiq-cron/sidekiq-cron/pull/381)
- Fix schedule.yml YAML load errors on Ruby 3.1 (https://github.com/sidekiq-cron/sidekiq-cron/pull/386)
- Require Fugit v1.8 to refactor internals (https://github.com/sidekiq-cron/sidekiq-cron/pull/385)

## 1.9.0

- Sidekiq v7 support (https://github.com/sidekiq-cron/sidekiq-cron/pull/369)
- Add support for ERB templates in the auto schedule loader (https://github.com/sidekiq-cron/sidekiq-cron/pull/373)

## 1.8.0

- Fix deprecation warnings with redis-rb v4.8.0 (https://github.com/sidekiq-cron/sidekiq-cron/pull/356)
- Fix poller affecting Sidekiq scheduled set poller (https://github.com/sidekiq-cron/sidekiq-cron/pull/359)
- Fix default polling interval (https://github.com/sidekiq-cron/sidekiq-cron/pull/362)
- Add italian locale (https://github.com/sidekiq-cron/sidekiq-cron/pull/367)
- Allow disabling of cron polling (https://github.com/sidekiq-cron/sidekiq-cron/pull/368)

## 1.7.0

- Enable to use cron notation in natural language (ie `every 30 minutes`) (https://github.com/sidekiq-cron/sidekiq-cron/pull/312)
- Fix `date_as_argument` feature to add timestamp argument at every cron job execution (https://github.com/sidekiq-cron/sidekiq-cron/pull/329)
- Introduce `Sidekiq::Options` to centralize reading/writing options from different Sidekiq versions (https://github.com/sidekiq-cron/sidekiq-cron/pull/341)
- Make auto schedule loading compatible with Array format (https://github.com/sidekiq-cron/sidekiq-cron/pull/345)

## 1.6.0

- Adds support for auto-loading the `config/schedule.yml` file (https://github.com/sidekiq-cron/sidekiq-cron/pull/337)
- Fix `Sidekiq.options` deprecation warning (https://github.com/sidekiq-cron/sidekiq-cron/pull/338)

## 1.5.1

-  Fixes an issue that prevented the gem to work in previous Sidekiq versions (https://github.com/sidekiq-cron/sidekiq-cron/pull/335)

## 1.5.0

- Integrate Sidekiq v6.5 breaking changes (https://github.com/sidekiq-cron/sidekiq-cron/pull/331)
- Add portuguese translations (https://github.com/sidekiq-cron/sidekiq-cron/pull/332)

## 1.4.0

- Fix buttons order in job show view (https://github.com/sidekiq-cron/sidekiq-cron/pull/302)
- Dark Mode support in UI (https://github.com/sidekiq-cron/sidekiq-cron/pull/282)
- Remove invocation of deprecated Redis functionality (https://github.com/sidekiq-cron/sidekiq-cron/pull/318)
- Internal code cleanup (https://github.com/sidekiq-cron/sidekiq-cron/pull/317)
- Optimize gem size (https://github.com/sidekiq-cron/sidekiq-cron/pull/322)
- Fix "Show All" button on cron jobs view with Sidekiq 6.3.0+ (https://github.com/sidekiq-cron/sidekiq-cron/pull/321)
- Documentation updates

## 1.3.0

- Add confirmation dialog when enquing jobs from UI
- Start to support Sidekiq `average_scheduled_poll_interval` option (replaced `poll_interval`)
- Fix deprecation warning for Redis 4.6.x
- Fix different response from Redis#exists in different Redis versions
- All PRs:
  - https://github.com/sidekiq-cron/sidekiq-cron/pull/275
  - https://github.com/sidekiq-cron/sidekiq-cron/pull/287
  - https://github.com/sidekiq-cron/sidekiq-cron/pull/309
  - https://github.com/sidekiq-cron/sidekiq-cron/pull/299
  - https://github.com/sidekiq-cron/sidekiq-cron/pull/314
  - https://github.com/sidekiq-cron/sidekiq-cron/pull/288

## 1.2.0

- Updated readme
- Fix problem with Sidekiq::Launcher and requiring it when not needed
- Better patching of Sidekiq::Launcher
- Fixed Dockerfile

## 1.1.0

- Updated readme
- Fix unit tests - changed argument error when getting invalid cron format
- When fallbacking old job enqueued time use `Time.parse` without format (so Ruby can decide best method to parse it)
- Add option `date_as_argument` which will add to your job arguments on last place `Time.now.to_f` when it was eneuqued
- Add option `description` which will allow you to add notes to your jobs so in web view you can see it
- Fixed translations

## 1.0.4

- Fix problem with upgrading to 1.0.x - parsing last enqued time didn't count with old time format stored in Redis

## 1.0.0

- Use [fugit](https://github.com/floraison/fugit) instead of [rufus-scheduler](https://github.com/jmettraux/rufus-scheduler) - API of cron didn't change (rufus scheduler is using fugit)
- Better working with Timezones
- Translations for JA, zh-CN
- Cron without timezone are considered as UTC, to add Timezone to cron use format `* * * * * Europe/Berlin`
- Be aware that this release can change when your jobs are enqueued (for me it didn't change but it is in one project, in other it can shift by different timezone setup)

## 0.6.0

- Set poller to check jobs every 30s by default (possible to override by `Sidekiq.options[:poll_interval] = 10`)
- Add group actions (enqueue, enable, disable, delete) all in web view
- Fix poller to enqueu all jobs in poll start time
- Add performance test for enqueue of jobs (10 000 jobs in less than 19s)
- Fix problem with default queue
- Remove `redis-namespace` from dependencies
- Update Ruby versions in Travis

## 0.5.0

- Add Docker support
- All crons are now evaluated in UTC
- Fix rufus scheduler & timezones problems
- Add support for Sidekiq 4.2.1
- Fix readme
- Add Russian locale
- User Rack.env in tests
- Faster enqueue of jobs
- Permit to use `ActiveJob::Base.queue_name_delimiter`
- Fix problem with multiple times enqueue #84
- Fix problem with enqueue of unknown class

## 0.4.0

- Enable to work with Sidekiq >= 4.0.0
- Fix readme

## 0.3.1

- Add CSRF tags to forms so it will work with Sidekiq >= 3.4.2
- Remove Tilt dependency

## 0.3.0

- Suport for Active Job
- Sidekiq cron web ui needs to be loaded by: require 'sidekiq/cron/web'
- Add load_from_hash! and load_from_array! which cleanup jobs before adding new ones
