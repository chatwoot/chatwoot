### Development
[Full Changelog](http://github.com/rspec/rspec-support/compare/v3.13.1...main)

### 3.13.1 / 2024-02-23
[Full Changelog](http://github.com/rspec/rspec-support/compare/v3.13.0...v3.13.1)

Bug Fixes:

* Exclude ruby internal require warnings from `RSpec::Support::CallerFilter#first_non_rspec_line`.
  (Jon Rowe, #593)

### 3.13.0 / 2024-02-04
[Full Changelog](http://github.com/rspec/rspec-support/compare/v3.12.2...v3.13.0)

Enchancements

* Add `RubyFeatures#supports_syntax_suggest?`. (Jon Rowe, #571)

### 3.12.2 / 2024-02-04
[Full Changelog](http://github.com/rspec/rspec-support/compare/v3.12.1...v3.12.2)

Bug Fixes:

* Properly surface errors from `in_sub_process`. (Jon Rowe, #575)
* Add magic comment for freezing string literals. (Josh Nichols, #586)
* Allow string keys for keyword arguments during verification of method
  signatures, (but only on Ruby 3+). (@malcolmohare, #591)

### 3.12.1 / 2023-06-26
[Full Changelog](http://github.com/rspec/rspec-support/compare/v3.12.0...v3.12.1)

Bug Fixes:

* Fix `RSpec::Support.thread_local_data` to be Thread local but not Fiber local.
  (Jon Rowe, #581)

### 3.12.0 / 2022-10-26
[Full Changelog](http://github.com/rspec/rspec-support/compare/v3.11.1...v3.12.0)
Enhancements:

* Add `RSpec::Support::RubyFeatures.distincts_kw_args_from_positional_hash?`
  (Jean byroot Boussier, #535)

### 3.11.1 / 2022-09-12
[Full Changelog](http://github.com/rspec/rspec-support/compare/v3.11.0...v3.11.1)

Bug Fixes:

* Fix ripper detection on TruffleRuby. (Brandon Fish, #541)

### 3.11.0 / 2022-02-09
[Full Changelog](http://github.com/rspec/rspec-support/compare/v3.10.3...v3.11.0)

No changes. Released to support other RSpec releases.

### 3.10.3 / 2021-11-03
[Full Changelog](http://github.com/rspec/rspec-support/compare/v3.10.2...v3.10.3)

Bug Fixes:

* Use `Mutex#owned?` to allow `RSpec::Support::ReentrantMutex` to work in
  nested Fibers on Ruby 3.0 and later. (Benoit Daloze, #503, #504)
* Support `end`-less methods in `RSpec::Support::Source::Token`
  so that RSpec won't hang when an `end`-less method raises an error. (Yuji Nakayama, #505)

### 3.10.2 / 2021-01-28
[Full Changelog](http://github.com/rspec/rspec-support/compare/v3.10.1...v3.10.2)

Bug Fixes:

* Fix issue with `RSpec::Support.define_optimized_require_for_rspec` on JRuby
  9.1.17.0 (Jon Rowe, #492)

### 3.10.1 / 2020-12-27
[Full Changelog](http://github.com/rspec/rspec-support/compare/v3.10.0...v3.10.1)

Bug Fixes:

* Fix deprecation expectations to fail correctly when
  asserting on messages. (Phil Pirozhkov, #453)

### 3.10.0 / 2020-10-30
[Full Changelog](http://github.com/rspec/rspec-support/compare/v3.9.4...v3.10.0)

No changes. Released to support other RSpec releases.

### 3.9.4 / 2020-10-23
[Full Changelog](http://github.com/rspec/rspec-support/compare/v3.9.3...v3.9.4)

Bug Fixes:

* Flag ripper as supported on Truffle Ruby. (Brandon Fish, #427)
* Prevent stubbing `File.read` from breaking source extraction.
  (Jon Rowe, #431)

### 3.9.3 / 2020-05-02
[Full Changelog](http://github.com/rspec/rspec-support/compare/v3.9.2...v3.9.3)

Bug Fixes:

* Mark ripper as unsupported on Truffle Ruby. (Brandon Fish, #395)
* Mark ripper as unsupported on JRuby 9.2.0.0. (Brian Hawley, #400)
* Capture `Mutex.new` for our `RSpec::Support:Mutex` in order to
  allow stubbing `Mutex.new`. (Jon Rowe, #411)

### 3.9.2 / 2019-12-30
[Full Changelog](http://github.com/rspec/rspec-support/compare/v3.9.1...v3.9.2)

Bug Fixes:

* Remove unneeded eval. (Matijs van Zuijlen, #394)

### 3.9.1 / 2019-12-28
[Full Changelog](http://github.com/rspec/rspec-support/compare/v3.9.0...v3.9.1)

Bug Fixes:

* Remove warning caused by keyword arguments on Ruby 2.7.0.
  (Jon Rowe, #392)

### 3.9.0 / 2019-10-07
[Full Changelog](http://github.com/rspec/rspec-support/compare/v3.8.3...v3.9.0)

*NO CHANGES*

Version 3.9.0 was released to allow other RSpec gems to release 3.9.0.

### 3.8.3 / 2019-10-02
[Full Changelog](http://github.com/rspec/rspec-support/compare/v3.8.2...v3.8.3)

Bug Fixes:

* Escape \r when outputting strings inside arrays.
  (Tomita Masahiro, Jon Rowe, #378)
* Ensure that optional hash arguments are recognised correctly vs keyword
  arguments. (Evgeni Dzhelyov, #366)

### 3.8.2 / 2019-06-10
[Full Changelog](http://github.com/rspec/rspec-support/compare/v3.8.1...v3.8.2)

Bug Fixes:

* Ensure that an empty hash is recognised as empty keyword arguments when
  applicable. (Thomas Walpole, #375)
* Ensure that diffing truthy values produce diffs consistently.
  (Lucas Nestor, #377)

### 3.8.1 / 2019-03-03
[Full Changelog](http://github.com/rspec/rspec-support/compare/v3.8.0...v3.8.1)

Bug Fixes:

* Ensure that inspecting a `SimpleDelegator` based object works regardless of
  visibility of the `__getobj__` method. (Jon Rowe, #369)

### 3.8.0 / 2018-08-04
[Full Changelog](http://github.com/rspec/rspec-support/compare/v3.7.1...v3.8.0)

Bug Fixes:

* Order hash keys before diffing to improve diff accuracy when using mocked calls.
  (James Crisp, #334)

### 3.7.1 / 2018-01-29
[Full Changelog](http://github.com/rspec/rspec-support/compare/v3.7.0...v3.7.1)

Bug Fixes:

* Fix source extraction logic so that it does not trigger a `SystemStackError`
  when processing deeply nested example groups. (Craig Bass, #343)

### 3.7.0 / 2017-10-17
[Full Changelog](http://github.com/rspec/rspec-support/compare/v3.6.0...v3.7.0)

Enhancements:

* Improve compatibility with `--enable-frozen-string-literal` option
  on Ruby 2.3+. (Pat Allan, #320)
* Add `Support.class_of` for extracting class of any object.
  (Yuji Nakayama, #325)

Bug Fixes:

* Fix recursive const support to not blow up when given buggy classes
  that raise odd errors from `#to_str`. (Myron Marston, #317)

### 3.6.0 / 2017-05-04
[Full Changelog](http://github.com/rspec/rspec-support/compare/v3.6.0.beta2...3.6.0)

Enhancements:

* Import `Source` classes from rspec-core. (Yuji Nakayama, #315)

### 3.6.0.beta2 / 2016-12-12
[Full Changelog](http://github.com/rspec/rspec-support/compare/v3.6.0.beta1...v3.6.0.beta2)

No user-facing changes.

### 3.6.0.beta1 / 2016-10-09
[Full Changelog](http://github.com/rspec/rspec-support/compare/v3.5.0...v3.6.0.beta1)

Bug Fixes:

* Prevent truncated formatted object output from mangling console codes. (#294, Anson Kelly)

### 3.5.0 / 2016-07-01
[Full Changelog](http://github.com/rspec/rspec-support/compare/v3.5.0.beta4...v3.5.0)

**No user facing changes since beta4**

### 3.5.0.beta4 / 2016-06-05
[Full Changelog](http://github.com/rspec/rspec-support/compare/v3.5.0.beta3...v3.5.0.beta4)

Enhancements:
* Improve `MethodSignature` to better support keyword arguments. (#250, Rob Smith).

### 3.5.0.beta3 / 2016-04-02
[Full Changelog](http://github.com/rspec/rspec-support/compare/v3.5.0.beta2...v3.5.0.beta3)

Bug Fixes:

* Fix `EncodedString` to properly handle the behavior of `String#split`
  on JRuby when the string contains invalid bytes. (Jon Rowe, #268)
* Fix `ObjectFormatter` so that formatting objects that don't respond to
  `#inspect` (such as `BasicObject`) does not cause `NoMethodError`.
  (Yuji Nakayama, #269)
* Fix `ObjectFormatter` so that formatting recursive array or hash does not
  cause `SystemStackError`. (Yuji Nakayama, #270, #272)

### 3.5.0.beta2 / 2016-03-10
[Full Changelog](http://github.com/rspec/rspec-support/compare/v3.5.0.beta1...v3.5.0.beta2)

No user-facing changes.

### 3.5.0.beta1 / 2016-02-06
[Full Changelog](http://github.com/rspec/rspec-support/compare/v3.4.1...v3.5.0.beta1)

Enhancements:

* Improve formatting of objects by allowing truncation to a pre-configured length.
  (Liam M, #256)

### 3.4.1 / 2015-11-20
[Full Changelog](http://github.com/rspec/rspec-support/compare/v3.4.0...v3.4.1)

Bug Fixes:

* Fix `RSpec::Support::RubyFeature.ripper_supported?` so it returns
  `false` on Rubinius since the Rubinius team has no plans to support
  it. This prevents rspec-core from trying to load and use ripper to
  extract failure snippets. (Aaron Stone, #251)

Changes:

* Remove `VersionChecker` in favor of `ComparableVersion`. (Yuji Nakayama, #266)

### 3.4.0 / 2015-11-11
[Full Changelog](http://github.com/rspec/rspec-support/compare/v3.3.0...v3.4.0)

Enhancements:

* Improve formatting of `Delegator` based objects (e.g. `SimpleDelegator`) in
  failure messages and diffs. (Andrew Horner, #215)
* Add `ComparableVersion`. (Yuji Nakayama, #245)
* Add `Ripper` support detection. (Yuji Nakayama, #245)

Bug Fixes:

* Work around bug in JRuby that reports that `attr_writer` methods
  have no parameters, causing RSpec's verifying doubles to wrongly
  fail when mocking or stubbing a writer method on JRuby. (Myron Marston, #225)

### 3.3.0 / 2015-06-12
[Full Changelog](http://github.com/rspec/rspec-support/compare/v3.2.2...v3.3.0)

Enhancements:

* Improve formatting of arrays and hashes in failure messages so they
  use our custom formatting of matchers, time objects, etc.
  (Myron Marston, Nicholas Chmielewski, #205)
* Use improved formatting for diffs as well. (Nicholas Chmielewski, #205)

Bug Fixes:

* Fix `FuzzyMatcher` so that it checks `expected == actual` rather than
  `actual == expected`, which avoids errors in situations where the
  `actual` object's `==` is improperly implemented to assume that only
  objects of the same type will be given. This allows rspec-mocks'
  `anything` to match against objects with buggy `==` definitions.
  (Myron Marston, #193)

### 3.2.2 / 2015-02-23
[Full Changelog](http://github.com/rspec/rspec-support/compare/v3.2.1...v3.2.2)

Bug Fixes:

* Fix an encoding issue with `EncodedString#split` when encountering an
  invalid byte string. (Benjamin Fleischer, #1760)

### 3.2.1 / 2015-02-04
[Full Changelog](http://github.com/rspec/rspec-support/compare/v3.2.0...v3.2.1)

Bug Fixes:

* Fix `RSpec::CallerFilter` to work on Rubinius 2.2.
  (Myron Marston, #169)

### 3.2.0 / 2015-02-03
[Full Changelog](http://github.com/rspec/rspec-support/compare/v3.1.2...v3.2.0)

Enhancements:

* Add extra Ruby type detection. (Jon Rowe, #133)
* Make differ instance re-usable. (Alexey Fedorov, #160)

Bug Fixes:

* Do not consider `[]` and `{}` to match when performing fuzzy matching.
  (Myron Marston, #157)

### 3.1.2 / 2014-10-08
[Full Changelog](http://github.com/rspec/rspec-support/compare/v3.1.1...v3.1.2)

Bug Fixes:

* Fix method signature to not blow up with a `NoMethodError` on 1.8.7 when
  verifying against an RSpec matcher. (Myron Marston, #116)

### 3.1.1 / 2014-09-26
[Full Changelog](http://github.com/rspec/rspec-support/compare/v3.1.0...v3.1.1)

Bug Fixes:

* Fix `RSpec::Support::DirectoryMaker` (used by `rspec --init` and
  `rails generate rspec:install`) so that it detects absolute paths
   on Windows properly. (Scott Archer, #107, #108, #109) (Jon Rowe, #110)

### 3.1.0 / 2014-09-04
[Full Changelog](http://github.com/rspec/rspec-support/compare/v3.0.4...v3.1.0)

Bug Fixes:

* Fix `FuzzyMatcher` so that it does not wrongly match a struct against
  an array. (Myron Marston, #97)
* Prevent infinitely recursing `#flatten` methods from causing the differ
  to hang. (Jon Rowe, #101)

### 3.0.4 / 2014-08-14
[Full Changelog](http://github.com/rspec/rspec-support/compare/v3.0.3...v3.0.4)

Bug Fixes:

* Fix `FuzzyMatcher` so that it does not silence `ArgumentError` raised
  from broken implementations of `==`. (Myron Marston, #94)

### 3.0.3 / 2014-07-21
[Full Changelog](http://github.com/rspec/rspec-support/compare/v3.0.2...v3.0.3)

Bug Fixes:

* Fix regression in `Support#method_handle_for` where proxy objects
  with method delegated would wrongly not return a method handle.
  (Jon Rowe, #90)
* Properly detect Module#prepend support in Ruby 2.1+ (Ben Langfeld, #91)
* Fix `rspec/support/warnings.rb` so it can be loaded and used in
  isolation. (Myron Marston, #93)

### 3.0.2 / 2014-06-20
[Full Changelog](http://github.com/rspec/rspec-support/compare/v3.0.1...v3.0.2)

* Revert `BlockSignature` change from 3.0.1 because of a ruby bug that
  caused it to change the block's behavior (https://bugs.ruby-lang.org/issues/9967).
  (Myron Marston, rspec-mocks#721)

### 3.0.1 / 2014-06-19
[Full Changelog](http://github.com/rspec/rspec-support/compare/v3.0.0...v3.0.1)

* Fix `BlockSignature` so that it correctly differentiates between
  required and optional block args. (Myron Marston, rspec-mocks#714)

### 3.0.0 / 2014-06-01
[Full Changelog](http://github.com/rspec/rspec-support/compare/v3.0.0.rc1...v3.0.0)

### 3.0.0.rc1 / 2014-05-18
[Full Changelog](http://github.com/rspec/rspec-support/compare/v3.0.0.beta2...v3.0.0.rc1)

### 3.0.0.beta2 / 2014-02-17
[Full Changelog](http://github.com/rspec/rspec-support/compare/v3.0.0.beta1...v3.0.0.beta2)

Bug Fixes:

* Issue message when :replacement is passed to `RSpec.warn_with`. (Jon Rowe)

### 3.0.0.beta1 / 2013-11-07
[Full Changelog](https://github.com/rspec/rspec-support/compare/0dc12d1bdbbacc757a9989f8c09cd08ef3a4837e...v3.0.0.beta1)

Initial release.
