0.22.0 (2022-12-23)
==========

## Enhancements

* On Ruby 3.2+, you can now use the new Coverage library feature for `eval` - See https://github.com/simplecov-ruby/simplecov/pull/1037. Thanks [@mame](https://github.com/mame)!

## Bugfixes
* Fix for making the test suite pass against the upcoming Ruby 3.2 - See https://github.com/simplecov-ruby/simplecov/pull/1035. Thanks [@mame](https://github.com/mame)

0.21.2 (2021-01-09)
==========

## Bugfixes
* `maximum_coverage_drop` won't fail any more if `.last_run.json` is still in the old format. Thanks [@petertellgren](https://github.com/petertellgren)
* `maximum_coverage_drop` won't fail if an expectation is specified for a previous unrecorded criterion, it will just pass (there's nothing, so nothing to drop)
* fixed bug in `maximum_coverage_drop` calculation that could falsely report it had dropped for minimal differences

0.21.1 (2021-01-04)
==========

## Bugfixes
* `minimum_coverage_by_file` works again as expected (errored out before 😱)

0.21.0 (2021-01-03)
==========

The "Collate++" release making it more viable for big CI setups by limiting memory consumption. Also includes some nice new additions for branch coverage settings.

## Enhancements
* Performance of `SimpleCov.collate` improved - it should both run faster and consume much less memory esp. when run with many files (memory consumption should not increase with number of files any more)
* Can now define the minimum_coverage_by_file, maximum_coverage_drop and refuse_coverage_drop by branch as well as line coverage. Thanks to [@jemmaissroff](https://github.com/jemmaissroff)
* Can set primary coverage to something other than line by setting `primary_coverage :branch` in SimpleCov Configuration. Thanks to [@jemmaissroff](https://github.com/jemmaissroff)

## Misc
* reduce gem size by splitting Changelog into `Changelog.md` and a pre 0.18 `Changelog.old.md`, the latter of which is not included in the gem
* The interface of `ResultMeger.merge_and_store` is changed to support the `collate` performance improvements mentioned above. It's not considered an official API, hence this is not in the breaking section. For people using it to merge results from different machines, it's recommended to migrate to [collate](https://github.com/simplecov-ruby/simplecov#merging-test-runs-under-different-execution-environments).

0.20.0 (2020-11-29)
==========

The "JSON formatter" release. Starting now a JSON formatter is included by default in the release. This is mostly done for Code Climate reasons, you can find more details [in this issue](https://github.com/codeclimate/test-reporter/issues/413).
Shipping with so much by default is sub-optimal, we know. It's the long term plan to also provide `simplecov-core` without the HTML or JSON formatters for those who don't need them/for other formatters to rely on.

## Enhancements
* `simplecov_json_formatter` included by default ([docs](https://github.com/simplecov-ruby/simplecov#json-formatter)), this should enable the Code Climate test reporter to work again once it's updated
* invalidate internal cache after switching `SimpleCov.root`, should help with some bugs

0.19.1 (2020-10-25)
==========

## Bugfixes

* No more warnings triggered by `enable_for_subprocesses`. Thanks to [@mame](https://github.com/mame)
* Avoid trying to patch `Process.fork` when it isn't available. Thanks to [@MSP-Greg](https://github.com/MSP-Greg)

0.19.0 (2020-08-16)
==========

## Breaking Changes
* Dropped support for Ruby 2.4, it reached EOL

## Enhancements
* observe forked processes (enable with SimpleCov.enable_for_subprocesses). See [#881](https://github.com/simplecov-ruby/simplecov/pull/881), thanks to [@robotdana](https://github.com/robotdana)
* SimpleCov distinguishes better that it stopped processing because of a previous error vs. SimpleCov is the originator of said error due to coverage requirements.

## Bugfixes
* Changing the `SimpleCov.root` combined with the root filtering didn't work. Now they do! Thanks to [@deivid-rodriguez](https://github.com/deivid-rodriguez) and see [#894](https://github.com/simplecov-ruby/simplecov/pull/894)
* in parallel test execution it could happen that the last coverage result was written to disk when it didn't complete yet, changed to only write it once it's the final result
* if you run parallel tests only the final process will report violations of the configured test coverage, not all previous processes
* changed the parallel_tests merging mechanisms to do the waiting always in the last process, should reduce race conditions

## Noteworthy
* The repo has moved to https://github.com/simplecov-ruby/simplecov - everything stays the same, redirects should work but you might wanna update anyhow
* The primary development branch is now `main`, not `master` anymore. If you get simplecov directly from github change your reference. For a while `master` will still be occasionally updated but that's no long term solion.

0.18.5 (2020-02-25)
===================

Can you guess? Another bugfix release!

## Bugfixes
* minitest won't crash if SimpleCov isn't loaded - aka don't execute SimpleCov code in the minitest plugin if SimpleCov isn't loaded. Thanks to [@edariedl](https://github.com/edariedl) for the report of the peculiar problem in [#877](https://github.com/simplecov-ruby/simplecov/issues/877).

0.18.4 (2020-02-24)
===================

Another small bugfix release 🙈 Fixes SimpleCov running with rspec-rails, which was broken due to our fixed minitest integration.

## Bugfixes
* SimpleCov will run again correctly when used with rspec-rails. The excellent bug report [#873](https://github.com/simplecov-ruby/simplecov/issues/873) by [@odlp](https://github.com/odlp) perfectly details what went wrong. Thanks to [@adam12](https://github.com/adam12) for the fix [#874](https://github.com/simplecov-ruby/simplecov/pull/874).


0.18.3 (2020-02-23)
===========

Small bugfix release. It's especially recommended to upgrade simplecov-html as well because of bugs in the 0.12.0 release.

## Bugfixes
* Fix a regression related to file encodings as special characters were missing. Furthermore we now respect the magic `# encoding: ...` comment and read files in the right encoding. Thanks ([@Tietew](https://github.com/Tietew)) - see [#866](https://github.com/simplecov-ruby/simplecov/pull/866)
* Use `Minitest.after_run` hook to trigger post-run hooks if `Minitest` is present. See [#756](https://github.com/simplecov-ruby/simplecov/pull/756) and [#855](https://github.com/simplecov-ruby/simplecov/pull/855) thanks ([@adam12](https://github.com/adam12))

0.18.2 (2020-02-12)
===================

Small release just to allow you to use the new simplecov-html.

## Enhancements
* Relax simplecov-html requirement so that you're able to use [0.12.0](https://github.com/simplecov-ruby/simplecov-html/blob/main/CHANGELOG.md#0120-2020-02-12)

0.18.1 (2020-01-31)
===================

Small Bugfix release.

## Bugfixes
* Just putting `# :nocov:` on top of a file or having an uneven number of them in general works again and acts as if ignoring until the end of the file. See [#846](https://github.com/simplecov-ruby/simplecov/issues/846) and thanks [@DannyBen](https://github.com/DannyBen) for the report.

0.18.0 (2020-01-28)
===================

Huge release! Highlights are support for branch coverage (Ruby 2.5+) and dropping support for EOL'ed Ruby versions (< 2.4).
Please also read the other beta patch notes.

You can run with branch coverage by putting `enable_coverage :branch` into your SimpleCov configuration (like the `SimpleCov.start do .. end` block)

## Enhancements
* You can now define the minimum expected coverage by criterion like `minimum_coverage line: 90, branch: 80`
* Memoized some internal data structures that didn't change to reduce SimpleCov overhead
* Both `FileList` and `SourceFile` now have a `coverage` method that returns a hash that points from a coverage criterion to a `CoverageStatistics` object for uniform access to overall coverage statistics for both line and branch coverage

## Bugfixes
* we were losing precision by rounding the covered strength early, that has been removed. **For Formatters** this also means that you may need to round it yourself now.
* Removed an inconsistency in how we treat skipped vs. irrelevant lines (see [#565](https://github.com/simplecov-ruby/simplecov/issues/565)) - SimpleCov's definition of 100% is now "You covered everything that you could" so if coverage is 0/0 that's counted as a 100% no matter if the lines were irrelevant or ignored/skipped

## Noteworthy
* `FileList` stopped inheriting from Array, it includes Enumerable so if you didn't use Array specific methods on it in formatters you should be fine
* We needed to change an internal file format, which we use for merging across processes, to accommodate branch coverage. Sadly CodeClimate chose to use this file to report test coverage. Until a resolution is found the code climate test reporter won't work with SimpleCov for 0.18+, see [this issue on the test reporter](https://github.com/codeclimate/test-reporter/issues/413).

0.18.0.beta3 (2020-01-20)
========================

## Enhancements
* Instead of ignoring old `.resultset.json`s that are inside the merge timeout, adapt and respect them

## Bugfixes
* Remove the constant warning printing if you still have a `.resultset.json` in pre 0.18 layout that is within your merge timeout

0.18.0.beta2 (2020-01-19)
===================

## Enhancements
* only turn on the requested coverage criteria (when activating branch coverage before SimpleCov would also instruct Ruby to take Method coverage)
* Change how branch coverage is displayed, now it's `branch_type: hit_count` which should be more self explanatory. See [#830](https://github.com/simplecov-ruby/simplecov/pull/830) for an example and feel free to give feedback!
* Allow early running exit tasks and avoid the `at_exit` hook through the `SimpleCov.run_exit_tasks!` method. (thanks [@macumber](https://github.com/macumber))
* Allow manual collation of result sets through the `SimpleCov.collate` entrypoint. See the README for more details (thanks [@ticky](https://github.com/ticky))
* Within `case`, even if there is no `else` branch declared show missing coverage for it (aka no branch of it). See [#825](https://github.com/simplecov-ruby/simplecov/pull/825)
* Stop symbolizing all keys when loading cache (should lead to be faster and consume less memory)
* Cache whether we can use/are using branch coverage (should be slightly faster)

## Bugfixes
* Fix a crash that happened when an old version of our internal cache file `.resultset.json` was still present

0.18.0.beta1 (2020-01-05)
===================

This is a huge release highlighted by changing our support for ruby versions to 2.4+ (so things that aren't EOL'ed) and finally adding branch coverage support!

This release is still beta because we'd love for you to test out branch coverage and get your feedback before doing a full release.

On a personal note from [@PragTob](https://github.com/PragTob/) thanks to [ruby together](https://rubytogether.org/) for sponsoring this work on SimpleCov making it possible to deliver this and subsequent releases.

## Breaking
* Dropped support for all EOL'ed rubies meaning we only support 2.4+. Simplecov can no longer be installed on older rubies, but older simplecov releases should still work. (thanks [@deivid-rodriguez](https://github.com/deivid-rodriguez))
* Dropped the `rake simplecov` task that "magically" integreated with rails. It was always undocumented, caused some issues and [had some issues](https://github.com/simplecov-ruby/simplecov/issues/689#issuecomment-561572327). Use the integration as described in the README please :)

## Enhancements

* Branch coverage is here! Please try it out and test it! You can activate it with `enable_coverage :branch`. See the README for more details. This is thanks to a bunch of people most notably [@som4ik](https://github.com/som4ik), [@tycooon](https://github.com/tycooon), [@stepozer](https://github.com/stepozer),  [@klyonrad](https://github.com/klyonrad) and your humble maintainers also contributed ;)
* If the minimum coverage is set to be greater than 100, a warning will be shown. See [#737](https://github.com/simplecov-ruby/simplecov/pull/737) (thanks [@belfazt](https://github.com/belfazt))
* Add a configuration option to disable the printing of non-successful exit statuses. See [#747](https://github.com/simplecov-ruby/simplecov/pull/746) (thanks [@JacobEvelyn](https://github.com/JacobEvelyn))
* Calculating 100% coverage is now stricter, so 100% means 100%. See [#680](https://github.com/simplecov-ruby/simplecov/pull/680) thanks [@gleseur](https://github.com/gleseur)

## Bugfixes

* Add new instance of `Minitest` constant. The `MiniTest` constant (with the capital T) will be removed in the next major release of Minitest. See [#757](https://github.com/simplecov-ruby/simplecov/pull/757) (thanks [@adam12](https://github.com/adam12))

Older Changelogs
================

Looking for older changelogs? Please check the [old Changelog](https://github.com/simplecov-ruby/simplecov/blob/main/CHANGELOG.old.md)
