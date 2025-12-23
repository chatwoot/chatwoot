# CONTRIBUTING

Please note that this project is released with a [Contributor Code of
Conduct](code_of_conduct.md). By participating in this project you agree to
abide by its terms.

## Bug Reports

* Try to reproduce the issue against the latest revision. There might be
  unrealeased work that fixes your problem!
* Ensure that your issue has not already been reported.
* Include the steps you carried out to produce the problem. If we can't
  reproduce it, we can't fix it.
* Include the behavior you observed along with the behavior you expected,
  and why you expected it.

## Development dependencies

* `Byebug` depends on Ruby's TracePoint API provided by `ruby-core`. This is a
  young API and a lot of bugs have been recently corrected, so make sure you
  always have the lastest patch level release installed.
* The recommended tool to manage development dependencies is `bundler`. Run
  `gem install bundler` to install it.
* Running `bundle install` inside a local clone of `byebug` will get development
  dependencies installed.

## Running the test suite

* Make sure you compile the C-extension using `bin/rake compile`.
  Otherwise you won't be able to use `byebug`.
* Run the test suite using the default rake task (`bin/rake`). This task is
  composed of 3 subtasks: `bin/rake compile`, `bin/rake test` & `bin/rake lint`.
* If you want to run specific tests, use the provided test runner, like so:
  * Specific test files. For example, `bin/minitest test/commands/break_test.rb`
  * Specific test classes. For example, `bin/minitest BreakAtLinesTest`
  * Specific tests. For example,
    `bin/minitest test_catch_removes_specific_catchpoint`
  * Specific fully qualified tests. For example,
    `bin/minitest BreakAtLinesTest#test_setting_breakpoint_sets_correct_fields`
  * You can combine any of them and you will get the union of all filters. For
    example: `bin/minitest BreakAtLinesTest
    test_catch_removes_specific_catchpoint`

## Code style

* Byebug uses several style checks to check code style consistent. You can run
  those using `bin/rake lint`.

## Byebug as a C-extension

Byebug is a gem developed as a C-extension. The debugger internal's
functionality is implemented in C (the interaction with the TracePoint API).
The rest of the gem is implemented in Ruby. Normally you won't need to touch
the C-extension, but it will obviously depended on the bug you're trying to fix
or the feature you are willing to add. You can learn more about C-extensions
[here](https://tenderlovemaking.com/2009/12/18/writing-ruby-c-extensions-part-1.html)
or
[here](https://tenderlovemaking.com/2010/12/11/writing-ruby-c-extensions-part-2.html).
