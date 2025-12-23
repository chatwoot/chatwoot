# Changelog

Individual gem's changelog has been deprecated. Please check the [project changelog](https://github.com/getsentry/sentry-ruby/blob/master/CHANGELOG.md).

## 4.4.0

### Features

- Make Sidekiq job context more readable [#1410](https://github.com/getsentry/sentry-ruby/pull/1410) 

**Before**

<img width="60%" alt="Sidekiq payload in extra" src="https://user-images.githubusercontent.com/5079556/115679342-0ed8d000-a385-11eb-8e1c-372cb1af572e.png">

**After**

<img width="60%" alt="Sidekiq payload in context" src="https://user-images.githubusercontent.com/5079556/115679353-126c5700-a385-11eb-867c-a9a25d1a7099.png">

## 4.3.0

### Features

- Support performance monitoring on Sidekiq workers [#1311](https://github.com/getsentry/sentry-ruby/pull/1311)

## 4.2.1

- Use ::Rails::Railtie for checking Rails definition [#1284](https://github.com/getsentry/sentry-ruby/pull/1284)
  - Fixes [#1276](https://github.com/getsentry/sentry-ruby/issues/1276)

## 4.2.0

### Features

- Tag queue name and jid on sidekiq events [#1258](https://github.com/getsentry/sentry-ruby/pull/1258)
<img width="1234" alt="sidekiq event tagged with queue name and jid" src="https://user-images.githubusercontent.com/5079556/106389900-d0381700-6420-11eb-90b9-a95b0881b696.png">

### Refactorings

- Add sidekiq adapter to sentry-rails' ignored adapters list [#1257](https://github.com/getsentry/sentry-ruby/pull/1257)

## 4.1.3

- Use sentry-ruby-core as the main SDK dependency [#1245](https://github.com/getsentry/sentry-ruby/pull/1245)

## 4.1.2

- Fix sidekiq middleware [#1175](https://github.com/getsentry/sentry-ruby/pull/1175)
  - Fixes [#1173](https://github.com/getsentry/sentry-ruby/issues/1173)
- Adopt Integrable module [#1177](https://github.com/getsentry/sentry-ruby/pull/1177)

## 4.1.1

- Use stricter dependency declaration [#1159](https://github.com/getsentry/sentry-ruby/pull/1159)

## 4.1.0

- Check SDK initialization before running integrations [#1151](https://github.com/getsentry/sentry-ruby/pull/1151)
  - Fixes [#1145](https://github.com/getsentry/sentry-ruby/pull/1145)

## 4.0.0

- Only documents update for the official release and no API/feature changes.

## 0.2.0

- Major API changes: [1123](https://github.com/getsentry/sentry-ruby/pull/1123)

## 0.1.3

- Small fixes

## 0.1.2

Fix require reference

## 0.1.1

Release test

## 0.1.0

First version

