## HEAD

## 3.1.2

* Replace `minitest` gem with `rspec`
* Fancier README
* Remove unnecessary short circuit in `randomize` method

## 3.1.1

* Fix typo in contexts exception message.
* Fix updating the version in the library.

## 3.1.0

* Added [contexts feature](https://github.com/kamui/retriable#contexts). Thanks to @apurvis.

## 3.0.2

* Add configuration and options validation.

## 3.0.1
* Add `rubocop` linter to enforce coding styles for this library. Also, fix rule violations.
* Removed `attr_reader :config` that caused a warning. @bruno-
* Clean up Rakefile testing cruft. @bruno-
* Use `.any?` in the `:on` hash processing. @apurvis

## 3.0.0
* Require ruby 2.0+.
* Breaking Change: `on` with a `Hash` value now matches subclassed exceptions. Thanks @apurvis!
* Remove `awesome_print` from development environment.

## 2.1.0

* Fix bug #17 due to confusing the initial try as a retry.
* Switch to `Minitest` 5.6 expect syntax.

## 2.0.2

* Change required_ruby_version in gemspec to >= 1.9.3.

## 2.0.1

* Add support for ruby 1.9.3.

## 2.0.0

* Require ruby 2.0+.
* Time intervals default to randomized exponential backoff instead of fixed time intervals. The delay between retries grows with every attempt and there's a randomization factor added to each attempt.
* `base_interval`, `max_interval`, `rand_factor`, and `multiplier` are new arguments that are used to generate randomized exponential back off time intervals.
* `interval` argument removed.
* Accept `intervals` array argument to provide your own custom intervals.
* Allow configurable defaults via `Retriable#configure` block.
* Add ability for `:on` argument to accept a `Hash` where the keys are exception types and the values are a single or array of `Regexp` pattern(s) to match against exception messages for retrial.
* Raise, not return, on max elapsed time.
* Check for elapsed time after next interval is calculated and it goes over the max elapsed time.
* Support early termination via `max_elapsed_time` argument.

## 2.0.0.beta5
* Change `:max_tries` back to `:tries`.

## 2.0.0.beta4
* Change #retry back to #retriable. Didn't like the idea of defining a method that is also a reserved word.
* Add ability for `:on` argument to accept a `Hash` where the keys are exception types and the values are a single or array of `Regexp` pattern(s) to match against exception messages for retrial.

## 2.0.0.beta3
* Accept `intervals` array argument to provide your own custom intervals.
* Refactor the exponential backoff code into it's own class.
* Add specs for exponential backoff, randomization, and config.

## 2.0.0.beta2
* Raise, not return, on max elapsed time.
* Check for elapsed time after next interval is calculated and it goes over the max elapsed time.
* Add specs for `max_elapsed_time` and `max_interval`.

## 2.0.0.beta1
* Require ruby 2.0+.
* Default to random exponential backoff, removes the `interval` option. Exponential backoff is configurable via arguments.
* Allow configurable defaults via `Retriable#configure` block.
* Change `Retriable.retriable` to `Retriable.retry`.
* Support early termination via `max_elapsed_time` argument.

## 1.4.1
* Fixes non kernel mode bug. Remove DSL class, move `#retriable` into Retriable module. Thanks @mkrogemann.

## 1.4.0
* By default, retriable doesn't monkey patch `Kernel`. If you want this functionality,
you can `require 'retriable/core_ext/kernel'.
* Upgrade minitest to 5.x.
* Refactor the DSL into it's own class.

## 1.3.3.1
* Allow sleep parameter to be a proc/lambda to allow for exponential backoff.

## 1.3.3
* sleep after executing the retry block, so there's no wait on the first call (molfar)

## 1.3.2
* Clean up option defaults.
* By default, rescue StandardError and Timeout::Error instead of [Exception](http://www.mikeperham.com/2012/03/03/the-perils-of-rescue-exception).

## 1.3.1
* Add `rake` dependency for travis-ci.
* Update gemspec summary and description.

## 1.3.0

* Rewrote a lot of the code with inspiration from [attempt](https://rubygems.org/gems/attempt).
* Add timeout option to the code block.
* Include in Kernel by default, but allow require 'retriable/no_kernel' to load a non kernel version.
* Renamed `:times` option to `:tries`.
* Renamed `:sleep` option to `:interval`.
* Renamed `:then` option to `:on_retry`.
* Removed other callbacks, you can wrap retriable in a begin/rescue/else/ensure block if you need that functionality. It avoids the need to define multiple Procs and makes the code more readable.
* Rewrote most of the README

## 1.2.0

* Forked the retryable-rb repo.
* Extend the Kernel module with the retriable method so you can use it anywhere without having to include it in every class.
* Update gemspec, Gemfile, and Raketask.
* Remove echoe dependency.
