## HEAD (unreleased)

## 0.6.3

- Fix `NoMethodError: undefined method 'logger' for Rails:Module` when Rails is defined as a Module, but is not a full Rails app (https://github.com/zombocom/rack-timeout/pull/180)

## 0.6.2

- Migrate CI from Travis CI to GitHub Actions (https://github.com/zombocom/rack-timeout/pull/182)
- Rails 7+ support (https://github.com/zombocom/rack-timeout/pull/184)

## 0.6.1

- RACK_TIMEOUT_TERM_ON_TIMEOUT can be set to zero to disable (https://github.com/sharpstone/rack-timeout/pull/161)
- Update the gemspec's homepage to the current repo URL(https://github.com/zombocom/rack-timeout/pull/183)

## 0.6.0

- Allow sending SIGTERM to workers on timeout (https://github.com/sharpstone/rack-timeout/pull/157)

0.5.2
=====
- Rails 6 support (#147)

0.5.1
=====
- Fixes setting ENV vars to false or 0 would not disable a timeout
  (#133)

0.5.0.1
=======
- Fix 0600 permissions in gem pushed to rubygems

0.5.0
=====

Breaking Changes

- Remove Rollbar module (#124)
- Remove legacy class setters (#125)

Other

- Add support to configure via environment variables (#105)
- Adds support for ActionDispatch::RequestId generated request ids (#115)
- Changes uuid format to proper uuid (#115)

0.4.2
=====
- Ruby 2.0 compatible

0.4.1
=====
- Rails 5 support
- Remove deprecation warning on timeout setter for Rails apps

0.4.0
=====
- Using monotonic time instead of Time.now where available (/ht concurrent-ruby)
- Settings are now passable to the middleware initializer instead of class-level
- Rollbar module may take a custom fingerprint block
- Rollbar module considered final
- Fixed an issue where some heartbeats would live on forever (#103, /ht @0x0badc0de)

0.3.2
=====
- Fixes calling timeout with a value of 0 (issue #90)

0.3.1
=====
- Rollbar module improvements

0.3.0
=====
- use a single scheduler thread to manage timeouts, instead of one timeout thread per request
- instead of inserting middleware at position 0 for rails, insert before Rack::Runtime (which is right after Rack::Lock and the static file stuff)
- reshuffle error types: RequestExpiryError is again a RuntimeError, and timeouts raise a RequestTimeoutException, an Exception, and not descending from Rack::Timeout::Error (see README for more)
- don't insert middleware for rails in test environment
- add convenience module Rack::Timeout::Logger (see README for more)
- StageChangeLoggingObserver renamed to StateChangeLoggingObserver, works slightly differently too
- file layout reorganization (see 6e82c276 for details)
- CHANGELOG file is now in the gem (@dbackeus)
- add optional and experimental support for grouping errors by url under rollbar. see "rack/timeout/rollbar" for usage

0.2.4
=====
- Previous fix was borked.

0.2.3
=====
- Ignore Rack::NullLogger when picking a logger

0.2.1
=====
- Fix raised error messages

0.2.0
=====
- Added CHANGELOG
- Rack::Timeout::Error now inherits from Exception instead of StandardError, with the hope users won't rescue from it accidentally

0.1.2
=====
- improve RequestTimeoutError error string so @watsonian is happy

0.1.1
=====
- README updates
- fix that setting properties to false resulted in an error

0.1.0
=====
- Rewrote README

0.1.0beta4
==========
- Renamed `timeout` setting to `service_timeout`; `timeout=` still works for backwards compatibility
– `MAX_REQUEST_AGE` is gone, the `wait_timeout` setting more or less replaces it
- Renamed `overtime` setting to `wait_overtime`
- overtime setting should actually work (It had never made it to beta3)
- In the request info struct, renamed `age` to `wait`, `duration` to `service`
- Rack::Timeout::StageChangeLogger is gone, replaced by Rack::Timeout::StageChangeLoggingObserver, which is an observer class that composites with a logger, instead of inheriting from Logger. Anything logging related will likely be incompatible with previous beta release.
- Log level can no longer be set with env vars, has to be set in the logger being used. (Which can now be custom / user-provided.)

0.1.0beta1,2,3
==============
- Dropped ruby 1.8.x support
- Dropped rails 2 support
- Added rails 4 support
- Added much logging
– Added support for dropping requests that waited too long in the queue without ever handling them
- Other things I can't remember, see git logs :P
