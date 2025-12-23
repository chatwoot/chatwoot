# Change log

## master (unreleased)

## 1.2.1 (2023-03-22)

- Fix regression with `before_all(setup_fixtures: true)` and `rspec-rails` v6.0+. ([@palkan][])

- Upgrade to RubyProf 1.4+. ([@palkan][])

## 1.2.0 (2023-02-07)

- Add support for multiple databases to `before_all` / `let_it_be` with Active Record. ([@rutgerw][])

## 1.1.0 (2022-12-06)

- LetItBe: freeze records during initialization with `freeze: true`. ([@palkan][])

- Add FactoryDefault profiler (factory associations profilers). ([@palkan][])

- FactoryDefault: Allow creating a default per trait (or set of traits). ([@palkan][])

Now `create_default(:user)` and `create_default(:user, :admin)` would result into two defaults corresponding to the specified traits.

- FactoryDefault: Add stats support. ([@palkan][])

Now you can see how often the default factory values have been used by specifying
the `FACTORY_DEFAULT_SUMMARY=1` or `FACTORY_DEFAULT_STATS=1` env var.

- Support using FactoryDefault with before_all/let_it_be. ([@palkan][])

Currently, RSpec only. Default factories created within `before_all` or `let_it_be` are not reset 'till the end of the corresponding context. Thus, now it's possible to use `create_default` within `let_it_be` without any additional hacks.

- FactoryDefault: Add `preserve_attributes = false | true` option. ([@palkan][])

Allow skipping defaults if association is defined with overrides, e.g.:

```ruby
factory :post do
  association :user, name: "Post Author"
end
```

- FactoryDefault: Add `skip_factory_default(&block)` to temporary disable default factories. ([@palkan][])

You can also use `TestProf::FactoryDefault.disable!(&block)`.

- Add support for global `before_all` tags ([@maxshend][])

```ruby
TestProf::BeforeAll.configure do |config|
  config.before(:begin, reset_sequences: true, foo: :bar) do
    warn <<~MESSAGE
      Do NOT create objects outside of transaction
      because all db sequences will be reset to 1
      in every single example, so that IDs of new objects
      can get into conflict with the long-living ones.
    MESSAGE
  end
end
```

## 1.0.11 (2022-10-27)

- Fix monitoring methods with keyword args in Ruby 3+. ([@palkan][])

- Disable garbage collection frames when `TEST_STACK_PROF_IGNORE_GC` env variable is set ([@cbliard][])

- Fixed restoring lock_thread value in nested contexts ([@ygelfand][])

## 1.0.10 (2022-08-12)

- Allow overriding global logger. ([@palkan][])

```ruby
require "test_prof/recipes/logging"

TestProf::Rails::LoggingHelpers.logger = CustomLogger.new
```

## 1.0.9 (2022-05-05)

- Add `AnyFixture.before_fixtures_reset` and `AnyFixture.after_fixtures_reset` callbacks. ([@ruslanshakirov][])

- Fixes ActiveRecord 6.1 issue with AnyFixture and Postgres config ([@markedmondson][])

## 1.0.8 (2022-03-11)

- Restore the lock_thread value after rollback. ([@cou929][])

- Fixes the configuration of a printer for factory_prof runs

- Ensure that defaults are stored in a threadsafe manner

## 1.0.7 (2021-08-30)

- Fix access to `let_it_be` variables in `after(:all)` hook. ([@cbarton][])

- Add support for using the before_all hook with Rails' parallelize feature (using processes). ([@peret][])

Make sure to include `TestProf::BeforeAll::Minitest` before you call `parallelize`.

## 1.0.6 (2021-06-23)

- Fix Spring detection when `DISABLE_SPRING=1` is used. ([@palkan][])

- Make `before_all` in Minitest inheritable. ([@palkan][])

## 1.0.5 (2021-05-13)

- Fix logging regression when no newline has been added. ([@palkan][])

## 1.0.4 (2021-05-12)

- Add ability to use custom logger. ([@palkan][])

```ruby
TestProf.configure do |config|
  config.logger = Logger.new($stdout, level: Logger::WARN)
end
```

- Add `nate_heckler` mode for FactoryProf. ([@palkan][])

Drop this into your `rails_helper.rb` or `test_helper.rb`:

```ruby
require "test_prof/factory_prof/nate_heckler"
```

And for every test run see the overall factories usage:

```sh
[TEST PROF INFO] Time spent in factories: 04:31.222 (54% of total time)
```

## 1.0.3 (2021-04-30)

- Minor fixes.

## 1.0.2 (2021-02-26)

- Make `before_all(setup_fixtures: true)` compatible with Rails 6.1. ([@palkan][])

## 1.0.1 (2021-02-12)

- Fixed AnyFixture deprecation warning.

## 1.0.0 (2021-01-21)

## 1.0.0.rc2 (2021-01-06)

- Make Rails fixtures accesible in `before_all`. ([@palkan][])

You can load and access fixtures when explicitly enabling them via `before_all(setup_fixtures: true, &block)`.

- Minitest's `before_all` is not longer experimental. ([@palkan][])

- Add `after_all` to Minitest in addition to `before_all`. ([@palkan][])

## 1.0.0.rc1 (2020-12-30)

- Remove deprecated `AggregateFailures` cop. ([@palkan][])

- Remove `ActiveRecordSharedConnection`. ([@palkan][])

- Add `AnyFixture#register_dump` to _cache_ fixtures using SQL dumps. ([@palkan][])

- Replaced `TestProf::AnyFixture.reporting_enabled = true` with `TestProf::AnyFixture.config.reporting_enabled = true`. ([@palkan][])

- Add support for RSpec aliases detection when linting specs using `let_it_be`/`before_all` with `rubocop-rspec` 2.0 ([@pirj][])

## 0.12.2 (2020-09-03)

- Execute Minitest `before_all` in the context of the current test object. ([@palkan][])

## 0.12.1 (2020-09-01)

- Minor improvements.

## 0.12.0 (2020-07-17)

- Add state leakage detection for `let_it_be`. ([@pirj][], [@jaimerson][], [@alexvko][])

- Add default let_it_be modifiers configuration. ([@palkan][])

You can configure global modifiers:

```ruby
TestProf::LetItBe.configure do |config|
  # Make refind activated by default
  config.default_modifiers[:refind] = true
end
```

Or for specific contexts via tags:

```ruby
context "with let_it_be reload", let_it_be_modifiers: {reload: true} do
  # examples
end
```

- **Drop Ruby 2.4 support.** ([@palkan][])

- SAMPLE and SAMPLE_GROUP work consistently with seed in RSpec and Minitest. ([@stefkin][])

- Make sure EventProf is not affected by time freezing. ([@palkan][])

  EventProf results now is not affected by `Timecop.freeze` or similar.

  See more in [#181](https://github.com/test-prof/test-prof/issues/181).

- Adds the ability to define stackprof's interval sampling by using `TEST_STACK_PROF_INTERVAL` env variable ([@LynxEyes][])

  Now you can use `$ TEST_STACK_PROF=1 TEST_STACK_PROF_INTERVAL=10000 rspec` to define a custom interval (in microseconds).

## 0.11.3 (2020-02-11)

- Disable `RSpec/AggregateFailures` by default. ([@pirj][])

## 0.11.2 (2020-02-11)

- Fix RuboCop integration regressions. ([@palkan][])

## 0.11.1 (2020-02-10)

- Add `config/` to the gem contents. ([@palkan][])

Fixes RuboCop integration regression from 0.11.0.

## 0.11.0 (2020-02-09)

- Fix `let_it_be` issue when initialized with an array/enumerable or an AR relation. ([@pirj][])

- Improve `RSpec/AggregateExamples` (formerly `RSpec/AggregateFailures`) cop. ([@pirj][])

## 0.10.2 (2020-01-07) 🎄

- Fix Ruby 2.7 deprecations. ([@lostie][])

## 0.10.1 (2019-10-17)

- Fix AnyFixture DSL when using with Rails 6.1+. ([@palkan][])

- Fix loading `let_it_be` without ActiveRecord present. ([@palkan][])

- Fix compatibility of `before_all` with [`isolator`](https://github.com/palkan/isolator) gem to handle correct usages of non-atomic interactions outside DB transactions. ([@Envek][])

- Updates FactoryProf to show the amount of time taken per factory call. ([@tyleriguchi][])

## 0.10.0 (2019-08-19)

- Use RSpec example ID instead of full description for RubyProf/Stackprof report names. ([@palkan][])

For more complex scenarios feel free to use your own report name generator:

```ruby
# for RubyProf
TestProf::RubyProf::Listener.report_name_generator = ->(example) { "..." }
# for Stackprof
TestProf::StackProf::Listener.report_name_generator = ->(example) { "..." }
```

- Support arrays in `let_it_be` with modifiers. ([@palkan][])

```ruby
# Now you can use modifiers with arrays
let_it_be(:posts, reload: true) { create_pair(:post) }
```

- Refactor `let_it_be` modifiers and allow adding custom modifiers. ([@palkan][])

```ruby
TestProf::LetItBe.config.register_modifier :reload do |record, val|
  # ignore when `reload: false`
  next record unless val
  # ignore non-ActiveRecord objects
  next record unless record.is_a?(::ActiveRecord::Base)
  record.reload
end
```

- Print warning when `ActiveRecordSharedConnection` is used in the version of Rails
  supporting `lock_threads` (5.1+). ([@palkan][])

## 0.9.0 (2019-05-14)

- Add threshold and custom event support to FactoryDoctor. ([@palkan][])

```sh
FDOC=1 FDOC_EVENT="sql.rom" FDOC_THRESHOLD=0.1 rspec
```

- Add Fabrication support to FactoryDoctor. ([@palkan][])

- Add `guard` and `top_level` options to `EventProf::Monitor`. ([@palkan][])

For example:

```ruby
TestProf::EventProf.monitor(
  Sidekiq::Client,
  "sidekiq.inline",
  :raw_push,
  top_level: true,
  guard: ->(*) { Sidekiq::Testing.inline? }
)
```

- Add global `before_all` hooks. ([@danielwaterworth][], [@palkan][])

Now you can run additional code before and after every `before_all` transaction
begins and rollbacks:

```ruby
TestProf::BeforeAll.configure do |config|
  config.before(:begin) do
    # do something before transaction opens
  end

  config.after(:rollback) do
    # do something after transaction closes
  end
end
```

- Add ability to use `let_it_be` aliases with predefined options. ([@danielwaterworth][])

```ruby
TestProf::LetItBe.configure do |config|
  config.alias_to :let_it_be_with_refind, refind: true
end
```

- Made FactoryProf measure and report on timing ([@danielwaterworth][])

See [changelog](https://github.com/test-prof/test-prof/blob/v0.8.0/CHANGELOG.md) for versions <0.9.0.

[@palkan]: https://github.com/palkan
[@danielwaterworth]: https://github.com/danielwaterworth
[@envek]: https://github.com/Envek
[@tyleriguchi]: https://github.com/tyleriguchi
[@lostie]: https://github.com/lostie
[@pirj]: https://github.com/pirj
[@lynxeyes]: https://github.com/LynxEyes
[@stefkin]: https://github.com/stefkin
[@jaimerson]: https://github.com/jaimerson
[@alexvko]: https://github.com/alexvko
[@cou929]: https://github.com/cou929
[@ruslanshakirov]: https://github.com/ruslanshakirov
[@ygelfand]: https://github.com/ygelfand
[@cbliard]: https://github.com/cbliard
[@maxshend]: https://github.com/maxshend
[@rutgerw]: https://github.com/rutgerw
[@markedmondson]: https://github.com/markedmondson
[@cbarton]: https://github.com/cbarton
[@peret]: https://github.com/peret
