SimpleCov [![Gem Version](https://badge.fury.io/rb/simplecov.svg)](https://badge.fury.io/rb/simplecov) [![Build Status](https://github.com/simplecov-ruby/simplecov/workflows/stable/badge.svg?branch=main)][Continuous Integration] [![Maintainability](https://api.codeclimate.com/v1/badges/c071d197d61953a7e482/maintainability)](https://codeclimate.com/github/simplecov-ruby/simplecov/maintainability) [![Inline docs](http://inch-ci.org/github/simplecov-ruby/simplecov.svg?branch=main)](http://inch-ci.org/github/simplecov-ruby/simplecov)
=========

**Code coverage for Ruby**

  * [Source Code]
  * [API documentation]
  * [Changelog]
  * [Rubygem]
  * [Continuous Integration]

[Coverage]: https://ruby-doc.org/stdlib/libdoc/coverage/rdoc/Coverage.html "API doc for Ruby's Coverage library"
[Source Code]: https://github.com/simplecov-ruby/simplecov "Source Code @ GitHub"
[API documentation]: http://rubydoc.info/gems/simplecov/frames "RDoc API Documentation at Rubydoc.info"
[Configuration]: http://rubydoc.info/gems/simplecov/SimpleCov/Configuration "Configuration options API documentation"
[Changelog]: https://github.com/simplecov-ruby/simplecov/blob/main/CHANGELOG.md "Project Changelog"
[Rubygem]: http://rubygems.org/gems/simplecov "SimpleCov @ rubygems.org"
[Continuous Integration]: https://github.com/simplecov-ruby/simplecov/actions?query=workflow%3Astable "SimpleCov is built around the clock by github.com"
[Dependencies]: https://gemnasium.com/simplecov-ruby/simplecov "SimpleCov dependencies on Gemnasium"
[simplecov-html]: https://github.com/simplecov-ruby/simplecov-html "SimpleCov HTML Formatter Source Code @ GitHub"

SimpleCov is a code coverage analysis tool for Ruby. It uses [Ruby's built-in Coverage][Coverage] library to gather code
coverage data, but makes processing its results much easier by providing a clean API to filter, group, merge, format,
and display those results, giving you a complete code coverage suite that can be set up with just a couple lines of
code.
SimpleCov/Coverage track covered ruby code, gathering coverage for common templating solutions like erb, slim and haml is not supported.

In most cases, you'll want overall coverage results for your projects, including all types of tests, Cucumber features,
etc. SimpleCov automatically takes care of this by caching and merging results when generating reports, so your
report actually includes coverage across your test suites and thereby gives you a better picture of blank spots.

The official formatter of SimpleCov is packaged as a separate gem called [simplecov-html], but will be installed and
configured automatically when you launch SimpleCov. If you're curious, you can find it [on GitHub, too][simplecov-html].


## Contact

*Code and Bug Reports*

* [Issue Tracker](https://github.com/simplecov-ruby/simplecov/issues)
* See [CONTRIBUTING](https://github.com/simplecov-ruby/simplecov/blob/main/CONTRIBUTING.md) for how to contribute along
with some common problems to check out before creating an issue.

*Questions, Problems, Suggestions, etc.*

* [Mailing List](https://groups.google.com/forum/#!forum/simplecov) "Open mailing list for discussion and announcements
on Google Groups"

Getting started
---------------
1. Add SimpleCov to your `Gemfile` and `bundle install`:

    ```ruby
    gem 'simplecov', require: false, group: :test
    ```
2. Load and launch SimpleCov **at the very top** of your `test/test_helper.rb`
   (*or `spec_helper.rb`, `rails_helper`, cucumber `env.rb`, or whatever your preferred test
   framework uses*):

    ```ruby
    require 'simplecov'
    SimpleCov.start

    # Previous content of test helper now starts here
    ```

    **Note:** If SimpleCov starts after your application code is already loaded
    (via `require`), it won't be able to track your files and their coverage!
    The `SimpleCov.start` **must** be issued **before any of your application
    code is required!**

    This is especially true if you use anything that keeps your tests application loaded like spring, check out the **[spring section](#want-to-use-spring-with-simplecov)**.

    SimpleCov must be running in the process that you want the code coverage
    analysis to happen on. When testing a server process (e.g. a JSON API
    endpoint) via a separate test process (e.g. when using Selenium) where you
    want to see all code executed by the `rails server`, and not just code
    executed in your actual test files, you need to require SimpleCov in the
    server process. For rails for instance, you'll want to add something like this
    to the top of `bin/rails`, but below the "shebang" line (`#! /usr/bin/env
    ruby`) and after config/boot is required:

    ```ruby
    if ENV['RAILS_ENV'] == 'test'
      require 'simplecov'
      SimpleCov.start 'rails'
      puts "required simplecov"
    end
    ```

3. Run your full test suite to see the percent coverage that your application has.
4. After running your tests, open `coverage/index.html` in the browser of your choice. For example, in a Mac Terminal,
   run the following command from your application's root directory:

   ```
   open coverage/index.html
   ```
   in a debian/ubuntu Terminal,

   ```
   xdg-open coverage/index.html
   ```

   **Note:** [This guide](https://dwheeler.com/essays/open-files-urls.html) can help if you're unsure which command your particular
   operating system requires.

5. Add the following to your `.gitignore` file to ensure that coverage results
   are not tracked by Git (optional):

   ```
   echo coverage >> .gitignore
   ```

   If you're making a Rails application, SimpleCov comes with built-in configurations (see below for information on
   profiles) that will get you started with groups for your Controllers, Models and Helpers. To use it, the
   first two lines of your test_helper should be like this:

   ```ruby
   require 'simplecov'
   SimpleCov.start 'rails'
   ```

## Example output

**Coverage results report, fully browsable locally with sorting and much more:**

![SimpleCov coverage report](https://cloud.githubusercontent.com/assets/137793/17071162/db6f253e-502d-11e6-9d84-e40c3d75f333.png)


**Source file coverage details view:**

![SimpleCov source file detail view](https://cloud.githubusercontent.com/assets/137793/17071163/db6f9f0a-502d-11e6-816c-edb2c66fad8d.png)

## Use it with any framework!

Similarly to the usage with Test::Unit described above, the only thing you have to do is to add the SimpleCov
config to the very top of your Cucumber/RSpec/whatever setup file.

Add the setup code to the **top** of `features/support/env.rb` (for Cucumber) or `spec/spec_helper.rb` (for RSpec).
Other test frameworks should work accordingly, whatever their setup file may be:

```ruby
require 'simplecov'
SimpleCov.start 'rails'
```

You could even track what kind of code your UI testers are touching if you want to go overboard with things. SimpleCov
does not care what kind of framework it is running in; it just looks at what code is being executed and generates a
report about it.

### Notes on specific frameworks and test utilities

For some frameworks and testing tools there are quirks and problems you might want to know about if you want
to use SimpleCov with them. Here's an overview of the known ones:

<table>
  <tr><th>Framework</th><th>Notes</th><th>Issue</th></tr>
  <tr>
    <th>
      parallel_tests
    </th>
    <td>
      As of 0.8.0, SimpleCov should correctly recognize parallel_tests and
      supplement your test suite names with their corresponding test env
      numbers. SimpleCov locks the resultset cache while merging, ensuring no
      race conditions occur when results are merged.
    </td>
    <td>
      <a href="https://github.com/simplecov-ruby/simplecov/issues/64">#64</a> &amp;
      <a href="https://github.com/simplecov-ruby/simplecov/pull/185">#185</a>
    </td>
  </tr>
  <tr>
    <th>
      knapsack_pro
    </th>
    <td>
      To make SimpleCov work with Knapsack Pro Queue Mode to split tests in parallel on CI jobs you need to provide CI node index number to the <code>SimpleCov.command_name</code> in <code>KnapsackPro::Hooks::Queue.before_queue</code> hook.
    </td>
    <td>
      <a href="https://knapsackpro.com/faq/question/how-to-use-simplecov-in-queue-mode">Tip</a>
    </td>
  </tr>
  <tr>
    <th>
      RubyMine
    </th>
    <td>
      The <a href="https://www.jetbrains.com/ruby/">RubyMine IDE</a> has
      built-in support for SimpleCov's coverage reports, though you might need
      to explicitly set the output root using `SimpleCov.root('foo/bar/baz')`
    </td>
    <td>
      <a href="https://github.com/simplecov-ruby/simplecov/issues/95">#95</a>
    </td>
  </tr>
  <tr>
    <th>
      Spork
    </th>
    <td>
      Because of how Spork works internally (using preforking), there used to
      be trouble when using SimpleCov with it, but that has apparently been
      resolved with a specific configuration strategy. See <a
      href="https://github.com/simplecov-ruby/simplecov/issues/42#issuecomment-4440284">this</a>
      comment.
    </td>
    <td>
      <a href="https://github.com/simplecov-ruby/simplecov/issues/42#issuecomment-4440284">#42</a>
    </td>
  </tr>
  <tr>
    <th>
      Spring
    </th>
    <td>
      <a href="#want-to-use-spring-with-simplecov">See section below.</a>
    </td>
    <td>
      <a href="https://github.com/simplecov-ruby/simplecov/issues/381">#381</a>
    </td>
  </tr>
  <tr>
    <th>
      Test/Unit
    </th>
    <td>
      Test Unit 2 used to mess with ARGV, leading to a failure to detect the
      test process name in SimpleCov. <code>test-unit</code> releases 2.4.3+
      (Dec 11th, 2011) should have this problem resolved.
    </td>
    <td>
      <a href="https://github.com/simplecov-ruby/simplecov/issues/45">#45</a> &amp;
      <a href="https://github.com/test-unit/test-unit/pull/12">test-unit/test-unit#12</a>
    </td>
  </tr>
</table>

## Configuring SimpleCov

[Configuration] settings can be applied in three formats, which are completely equivalent:

* The most common way is to configure it directly in your start block:

    ```ruby
    SimpleCov.start do
      some_config_option 'foo'
    end
    ```
* You can also set all configuration options directly:

    ```ruby
    SimpleCov.some_config_option 'foo'
    ```
* If you do not want to start coverage immediately after launch or want to add additional configuration later on in a
  concise way, use:

    ```ruby
    SimpleCov.configure do
      some_config_option 'foo'
    end
    ```

Please check out the [Configuration] API documentation to find out what you can customize.

## Using .simplecov for centralized config

If you use SimpleCov to merge multiple test suite results (e.g. Test/Unit and Cucumber) into a single report, you'd
normally have to set up all your config options twice, once in `test_helper.rb` and once in `env.rb`.

To avoid this, you can place a file called `.simplecov` in your project root. You can then just leave the
`require 'simplecov'` in each test setup helper (**at the top**) and move the `SimpleCov.start` code with all your
custom config options into `.simplecov`:

```ruby
# test/test_helper.rb
require 'simplecov'

# features/support/env.rb
require 'simplecov'

# .simplecov
SimpleCov.start 'rails' do
  # any custom configs like groups and filters can be here at a central place
end
```

Using `.simplecov` rather than separately requiring SimpleCov multiple times is recommended if you are merging multiple
test frameworks like Cucumber and RSpec that rely on each other, as invoking SimpleCov multiple times can cause coverage
information to be lost.

## Branch coverage (ruby "~> 2.5")
Add branch coverage measurement statistics to your results. Supported in CRuby versions 2.5+.

```ruby
SimpleCov.start do
  enable_coverage :branch
end
```

Branch coverage is a feature introduced in Ruby 2.5 concerning itself with whether a
particular branch of a condition had been executed. Line coverage on the other hand
is only interested in whether a line of code has been executed.

This comes in handy for instance for one line conditionals:

```ruby
number.odd? ? "odd" : "even"
```

In line coverage this line would always be marked as executed but you'd never know if both
conditions were met. Guard clauses have a similar story:

```ruby
return if number.odd?

# more code
```

If all the code in that method was covered you'd never know if the guard clause was ever
triggered! With line coverage as just evaluating the condition marks it as covered.

In the HTML report the lines of code will be annotated like `branch_type: hit_count`:

* `then: 2` - the then branch (of an `if`) was executed twice
* `else: 0` - the else branch (of an `if` or `case`) was never executed

Not that even if you don't declare an `else` branch it will still show up in the coverage
reports meaning that the condition of the `if` was not hit or that no `when` of `case`
was hit during the test runs.

**Is branch coverage strictly better?** No. Branch coverage really only concerns itself with
conditionals - meaning coverage of sequential code is of no interest to it. A file without
conditional logic will have no branch coverage data and SimpleCov will report 0 of 0
branches covered as 100% (as everything that can be covered was covered).

Hence, we recommend looking at both metrics together. Branch coverage might also be a good
overall metric to look at - while you might be missing only 10% of your lines that might
account for 50% of your branches for instance.

## Primary Coverage

By default, the primary coverage type is `line`. To set the primary coverage to something else, use the following:

```ruby
# or in configure SimpleCov.primary_coverage :branch
SimpleCov.start do
  enable_coverage :branch
  primary_coverage :branch
end
```

Primary coverage determines what will come in first all output, and the type of coverage to check if you don't specify the type of coverage when customizing exit behavior (`SimpleCov.minimum_coverage 90`).

Note that coverage must first be enabled for non-default coverage types.

## Coverage for eval

You can measure coverage for code that is evaluated by `Kernel#eval`. Supported in CRuby versions 3.2+.

```ruby
SimpleCov.start do
  enable_coverage_for_eval
end
```

This is typically useful for ERB. Set `ERB#filename=` to make it possible for SimpleCov to trace the original .erb source file.

## Filters

Filters can be used to remove selected files from your coverage data. By default, a filter is applied that removes all
files OUTSIDE of your project's root directory - otherwise you'd end up with billions of coverage reports for source
files in the gems you are using.

You can define your own to remove things like configuration files, tests or whatever you don't need in your coverage
report.

### Defining custom filters

You can currently define a filter using either a String or Regexp (that will then be Regexp-matched against each source
file's path), a block or by passing in your own Filter class.

#### String filter

```ruby
SimpleCov.start do
  add_filter "/test/"
end
```

This simple string filter will remove all files that match "/test/" in their path.

#### Regex filter

```ruby
SimpleCov.start do
  add_filter %r{^/test/}
end
```

This simple regex filter will remove all files that start with /test/ in their path.

#### Block filter

```ruby
SimpleCov.start do
  add_filter do |source_file|
    source_file.lines.count < 5
  end
end
```

Block filters receive a SimpleCov::SourceFile instance and expect your block to return either true (if the file is to be
removed from the result) or false (if the result should be kept). Please check out the RDoc for SimpleCov::SourceFile to
learn about the methods available to you. In the above example, the filter will remove all files that have less than 5
lines of code.

#### Custom filter class

```ruby
class LineFilter < SimpleCov::Filter
  def matches?(source_file)
    source_file.lines.count < filter_argument
  end
end

SimpleCov.add_filter LineFilter.new(5)
```

Defining your own filters is pretty easy: Just inherit from SimpleCov::Filter and define a method
'matches?(source_file)'. When running the filter, a true return value from this method will result in the removal of the
given source_file. The filter_argument method is being set in the SimpleCov::Filter initialize method and thus is set to
5 in this example.

#### Array filter

```ruby
SimpleCov.start do
  proc = Proc.new { |source_file| false }
  add_filter ["string", /regex/, proc, LineFilter.new(5)]
end
```

You can pass in an array containing any of the other filter types.

#### Ignoring/skipping code

You can exclude code from the coverage report by wrapping it in `# :nocov:`.

```ruby
# :nocov:
def skip_this_method
  never_reached
end
# :nocov:
```

The name of the token can be changed to your liking. [Learn more about the nocov feature.]( https://github.com/simplecov-ruby/simplecov/blob/main/features/config_nocov_token.feature)

**Note:** You shouldn't have to use the nocov token to skip private methods that are being included in your coverage. If
you appropriately test the public interface of your classes and objects you should automatically get full coverage of
your private methods.

## Default root filter and coverage for things outside of it

By default, SimpleCov filters everything outside of the `SimpleCov.root` directory. However, sometimes you may want
to include coverage reports for things you include as a gem, for example a Rails Engine.

Here's an example by [@lsaffie](https://github.com/lsaffie) from [#221](https://github.com/simplecov-ruby/simplecov/issues/221)
that shows how you can achieve just that:

```ruby
SimpleCov.start :rails do
  filters.clear # This will remove the :root_filter and :bundler_filter that come via simplecov's defaults
  add_filter do |src|
    !(src.filename =~ /^#{SimpleCov.root}/) unless src.filename =~ /my_engine/
  end
end
```

## Groups

You can separate your source files into groups. For example, in a Rails app, you'll want to have separate listings for
Models, Controllers, Helpers, and Libs. Group definition works similarly to Filters (and also accepts custom
filter classes), but source files end up in a group when the filter passes (returns true), as opposed to filtering
results, which exclude files from results when the filter results in a true value.

Add your groups with:

```ruby
SimpleCov.start do
  add_group "Models", "app/models"
  add_group "Controllers", "app/controllers"
  add_group "Long files" do |src_file|
    src_file.lines.count > 100
  end
  add_group "Multiple Files", ["app/models", "app/controllers"] # You can also pass in an array
  add_group "Short files", LineFilter.new(5) # Using the LineFilter class defined in Filters section above
end
```

## Merging results

You normally want to have your coverage analyzed across ALL of your test suites, right?

Simplecov automatically caches coverage results in your
(coverage_path)/.resultset.json, and will merge or override those with
subsequent runs, depending on whether simplecov considers those subsequent runs
as different test suites or as the same test suite as the cached results. To
make this distinction, simplecov has the concept of "test suite names".

### Test suite names

SimpleCov tries to guess the name of the currently running test suite based upon the shell command the tests
are running on. This should work fine for Unit Tests, RSpec, and Cucumber. If it fails, it will use the shell
command that invoked the test suite as a command name.

If you have some non-standard setup and still want nicely labeled test suites, you have to give Simplecov a
cue as to what the name of the currently running test suite is. You can do so by specifying
`SimpleCov.command_name` in one test file that is part of your specific suite.

To customize the suite names on a Rails app (yeah, sorry for being Rails-biased, but everyone knows what
the structure of those projects is. You can apply this accordingly to the RSpecs in your
Outlook-WebDAV-Calendar-Sync gem), you could do something like this:

```ruby
# test/unit/some_test.rb
SimpleCov.command_name 'test:units'

# test/functionals/some_controller_test.rb
SimpleCov.command_name "test:functionals"

# test/integration/some_integration_test.rb
SimpleCov.command_name "test:integration"

# features/support/env.rb
SimpleCov.command_name "features"
```

Note that this only has to be invoked ONCE PER TEST SUITE, so even if you have 200 unit test files,
specifying it in `some_test.rb` is enough.

Last but not least **if multiple suites resolve to the same `command_name`** be aware that the coverage results **will
clobber each other instead of being merged**.  SimpleCov is smart enough to detect unique names for the most common
setups, but if you have more than one test suite that doesn't follow a common pattern then you will want to manually
ensure that each suite gets a unique `command_name`.

If you are running tests in parallel each process has the potential to clobber results from the other test processes.
If you are relying on the default `command_name` then SimpleCov will attempt to detect and avoid parallel test suite
`command_name` collisions based on the presence of `ENV['PARALLEL_TEST_GROUPS']` and `ENV['TEST_ENV_NUMBER']`.  If your
parallel test runner does not set one or both of these then *you must* set a `command_name` and ensure that it is unique
per process (eg. `command_name "Unit Tests PID #{$$}"`).

If you are using parallel_tests, you must incorporate `TEST_ENV_NUMBER` into the command name yourself, in
order for SimpleCov to merge the results correctly. For example:

```ruby
# spec/spec_helper.rb
SimpleCov.command_name "features" + (ENV['TEST_ENV_NUMBER'] || '')
```

[simplecov-html] prints the used test suites in the footer of the generated coverage report.


### Merging test runs under the same execution environment

Test results are automatically merged with previous runs in the same execution
environment when generating the result, so when coverage is set up properly for
Cucumber and your unit / functional / integration tests, all of those test
suites will be taken into account when building the coverage report.

#### Timeout for merge

Of course, your cached coverage data is likely to become invalid at some point. Thus, when automatically merging
subsequent test runs, result sets that are older than `SimpleCov.merge_timeout` will not be used any more. By default,
the timeout is 600 seconds (10 minutes), and you can raise (or lower) it by specifying `SimpleCov.merge_timeout 3600`
(1 hour), or, inside a configure/start block, with just `merge_timeout 3600`.

You can deactivate this automatic merging altogether with `SimpleCov.use_merging false`.

### Merging test runs under different execution environments

If your tests are done in parallel across multiple build machines, you can fetch them all and merge them into a single
result set using the `SimpleCov.collate` method. This can be added to a Rakefile or script file, having downloaded a set of
`.resultset.json` files from each parallel test run.

```ruby
# lib/tasks/coverage_report.rake
namespace :coverage do
  desc "Collates all result sets generated by the different test runners"
  task :report do
    require 'simplecov'

    SimpleCov.collate Dir["simplecov-resultset-*/.resultset.json"]
  end
end
```

`SimpleCov.collate` also takes an optional simplecov profile and an optional
block for configuration, just the same as `SimpleCov.start` or
`SimpleCov.configure`.  This means you can configure a separate formatter for
the collated output. For instance, you can make the formatter in
`SimpleCov.start` the `SimpleCov::Formatter::SimpleFormatter`, and only use more
complex formatters in the final `SimpleCov.collate` run.

```ruby
# spec/spec_helper.rb
require 'simplecov'

SimpleCov.start 'rails' do
  # Disambiguates individual test runs
  command_name "Job #{ENV["TEST_ENV_NUMBER"]}" if ENV["TEST_ENV_NUMBER"]

  if ENV['CI']
    formatter SimpleCov::Formatter::SimpleFormatter
  else
    formatter SimpleCov::Formatter::MultiFormatter.new([
      SimpleCov::Formatter::SimpleFormatter,
      SimpleCov::Formatter::HTMLFormatter
    ])
  end

  track_files "**/*.rb"
end
```

```ruby
# lib/tasks/coverage_report.rake
namespace :coverage do
  task :report do
    require 'simplecov'

    SimpleCov.collate Dir["simplecov-resultset-*/.resultset.json"], 'rails' do
      formatter SimpleCov::Formatter::MultiFormatter.new([
        SimpleCov::Formatter::SimpleFormatter,
        SimpleCov::Formatter::HTMLFormatter
      ])
    end
  end
end
```

## Running simplecov against subprocesses

`SimpleCov.enable_for_subprocesses` will allow SimpleCov to observe subprocesses starting using `Process.fork`.
This modifies ruby's core Process.fork method so that SimpleCov can see into it, appending `" (subprocess #{pid})"`
to the `SimpleCov.command_name`, with results that can be merged together using SimpleCov's merging feature.

To configure this, use `.at_fork`.

```ruby
SimpleCov.enable_for_subprocesses true
SimpleCov.at_fork do |pid|
  # This needs a unique name so it won't be ovewritten
  SimpleCov.command_name "#{SimpleCov.command_name} (subprocess: #{pid})"
  # be quiet, the parent process will be in charge of output and checking coverage totals
  SimpleCov.print_error_status = false
  SimpleCov.formatter SimpleCov::Formatter::SimpleFormatter
  SimpleCov.minimum_coverage 0
  # start
  SimpleCov.start
end
```

NOTE: SimpleCov must have already been started before `Process.fork` was called.

### Running simplecov against spawned subprocesses

Perhaps you're testing a ruby script with `PTY.spawn` or `Open3.popen`, or `Process.spawn` or etc.
SimpleCov can cover this too.

Add a .simplecov_spawn.rb file to your project root
```ruby
# .simplecov_spawn.rb
require 'simplecov' # this will also pick up whatever config is in .simplecov
                    # so ensure it just contains configuration, and doesn't call SimpleCov.start.
SimpleCov.command_name 'spawn' # As this is not for a test runner directly, script doesn't have a pre-defined base command_name
SimpleCov.at_fork.call(Process.pid) # Use the per-process setup described previously
SimpleCov.start # only now can we start.
```
Then, instead of calling your script directly, like:
```ruby
PTY.spawn('my_script.rb') do # ...
```
Use bin/ruby to require the new .simplecov_spawn file, then your script
```ruby
PTY.spawn('ruby -r./.simplecov_spawn my_script.rb') do # ...
```

## Running coverage only on demand

The Ruby STDLIB Coverage library that SimpleCov builds upon is *very* fast (on a ~10 min Rails test suite, the speed
drop was only a couple seconds for me), and therefore it's SimpleCov's policy to just generate coverage every time you
run your tests because it doesn't do your test speed any harm and you're always equipped with the latest and greatest
coverage results.

Because of this, SimpleCov has no explicit built-in mechanism to run coverage only on demand.

However, you can still accomplish this very easily by introducing an ENV variable conditional into your SimpleCov setup
block, like this:

```ruby
SimpleCov.start if ENV["COVERAGE"]
```

Then, SimpleCov will only run if you execute your tests like this:

```shell
COVERAGE=true rake test
```

## Errors and exit statuses

To aid in debugging issues, if an error is raised, SimpleCov will print a message to `STDERR`
with the exit status of the error, like:

```
SimpleCov failed with exit 1
```

This `STDERR` message can be disabled with:

```
SimpleCov.print_error_status = false
```

## Profiles

By default, SimpleCov's only config assumption is that you only want coverage reports for files inside your project
root. To save yourself from repetitive configuration, you can use predefined blocks of configuration, called 'profiles',
or define your own.

You can then pass the name of the profile to be used as the first argument to SimpleCov.start. For example, simplecov
comes bundled with a 'rails' profile. It looks somewhat like this:

```ruby
SimpleCov.profiles.define 'rails' do
  add_filter '/test/'
  add_filter '/config/'

  add_group 'Controllers', 'app/controllers'
  add_group 'Models', 'app/models'
  add_group 'Helpers', 'app/helpers'
  add_group 'Libraries', 'lib'
end
```

As you can see, it's just a SimpleCov.configure block. In your test_helper.rb, launch SimpleCov with:

```ruby
SimpleCov.start 'rails'
```

or

```ruby
SimpleCov.start 'rails' do
  # additional config here
end
```

### Custom profiles

You can load additional profiles with the SimpleCov.load_profile('xyz') method. This allows you to build upon an
existing profile and customize it so you can reuse it in unit tests and Cucumber features. For example:

```ruby
# lib/simplecov_custom_profile.rb
require 'simplecov'
SimpleCov.profiles.define 'myprofile' do
  load_profile 'rails'
  add_filter 'vendor' # Don't include vendored stuff
end

# features/support/env.rb
require 'simplecov_custom_profile'
SimpleCov.start 'myprofile'

# test/test_helper.rb
require 'simplecov_custom_profile'
SimpleCov.start 'myprofile'
```

## Customizing exit behaviour

You can define what SimpleCov should do when your test suite finishes by customizing the at_exit hook:

```ruby
SimpleCov.at_exit do
  SimpleCov.result.format!
end
```

Above is the default behaviour. Do whatever you like instead!

### Minimum coverage

You can define the minimum coverage percentage expected. SimpleCov will return non-zero if unmet.

```ruby
SimpleCov.minimum_coverage 90
# same as above (the default is to check line coverage)
SimpleCov.minimum_coverage line: 90
# check for a minimum line coverage of 90% and minimum 80% branch coverage
SimpleCov.minimum_coverage line: 90, branch: 80
```

### Minimum coverage by file

You can define the minimum coverage by file percentage expected. SimpleCov will return non-zero if unmet. This is useful
to help ensure coverage is relatively consistent, rather than being skewed by particularly good or bad areas of the code.

```ruby
SimpleCov.minimum_coverage_by_file 80
# same as above (the default is to check line coverage by file)
SimpleCov.minimum_coverage_by_file line: 80
# check for a minimum line coverage by file of 90% and minimum 80% branch coverage
SimpleCov.minimum_coverage_by_file line: 90, branch: 80
```

### Maximum coverage drop

You can define the maximum coverage drop percentage at once. SimpleCov will return non-zero if exceeded.

```ruby
SimpleCov.maximum_coverage_drop 5
# same as above (the default is to check line drop)
SimpleCov.maximum_coverage_drop line: 5
# check for a maximum line drop of 5% and maximum 10% branch drop
SimpleCov.maximum_coverage_drop line: 5, branch: 10
```

### Refuse dropping coverage

You can also entirely refuse dropping coverage between test runs:

```ruby
SimpleCov.refuse_coverage_drop
# same as above (the default is to only refuse line drop)
SimpleCov.refuse_coverage_drop :line
# refuse drop for line and branch
SimpleCov.refuse_coverage_drop :line, :branch
```

## Using your own formatter

You can use your own formatter with:

```ruby
SimpleCov.formatter = SimpleCov::Formatter::HTMLFormatter
```

Calling `SimpleCov.result.format!` will be invoked with `SimpleCov::Formatter::YourFormatter.new.format(result)`,
and `result` is an instance of `SimpleCov::Result`. Do whatever your wish with that!


## Using multiple formatters

As of SimpleCov 0.9, you can specify multiple result formats. Formatters besides the default HTML formatter require separate gems, however.

```ruby
require "simplecov-html"

SimpleCov.formatters = SimpleCov::Formatter::MultiFormatter.new([
  SimpleCov::Formatter::HTMLFormatter,
  SimpleCov::Formatter::CSVFormatter,
])
```

## JSON formatter

SimpleCov is packaged with a separate gem called [simplecov_json_formatter](https://github.com/codeclimate-community/simplecov_json_formatter) that provides you with a JSON formatter, this formatter could be useful for different use cases, such as for CI consumption or for reporting to external services.

In order to use it you will need to manually load the installed gem like so:

```ruby
require "simplecov_json_formatter"
SimpleCov.formatter = SimpleCov::Formatter::JSONFormatter
```

> _Note:_ In case you plan to report your coverage results to CodeClimate services, know that SimpleCov will automatically use the
>  JSON formatter along with the HTML formatter when the `CC_TEST_REPORTER_ID` variable is present in the environment.

## Available formatters, editor integrations and hosted services

  * [Open Source formatter and integration plugins for SimpleCov](doc/alternate-formatters.md)
  * [Editor Integration](doc/editor-integration.md)
  * [Hosted (commercial) services](doc/commercial-services.md)

## Ruby version compatibility

SimpleCov is built in [Continuous Integration] on Ruby 2.7+ as well as JRuby 9.3+.

Note for JRuby => You need to pass JRUBY_OPTS="--debug" or create .jrubyrc and add debug.fullTrace=true

## Want to find dead code in production?

Try [Coverband](https://github.com/danmayer/coverband).

## Want to use Spring with SimpleCov?

If you're using [Spring](https://github.com/rails/spring) to speed up test suite runs and want to run SimpleCov along
with them, you'll find that it often misreports coverage with the default config due to some sort of eager loading
issue. Don't despair!

One solution is to [explicitly call eager
load](https://github.com/simplecov-ruby/simplecov/issues/381#issuecomment-347651728)
in your `test_helper.rb` / `spec_helper.rb` after calling `SimpleCov.start`.

```ruby
require 'simplecov'
SimpleCov.start 'rails'
Rails.application.eager_load!
```

Alternatively, you could disable Spring while running SimpleCov:

```
DISABLE_SPRING=1 rake test
```

Or you could remove `gem 'spring'` from your `Gemfile`.

## Troubleshooting

The **most common problem is that simplecov isn't required and started before everything else**. In order to track
coverage for your whole application **simplecov needs to be the first one** so that it (and the underlying coverage
library) can subsequently track loaded files and their usage.

If you are missing coverage for some code a simple trick is to put a puts statement in there and right after
`SimpleCov.start` so you can see if the file really was loaded after simplecov was started.

```ruby
# my_code.rb
class MyCode

  puts "MyCode is being loaded!"

  def my_method
    # ...
  end
end

# spec_helper.rb/rails_helper.rb/test_helper.rb/.simplecov whatever

SimpleCov.start
puts "SimpleCov started successfully!"
```

Now when you run your test suite and you see:

```
SimpleCov started successfully!
MyCode is being loaded!
```

then it's good otherwise you likely have a problem :)

## Code of Conduct

Everyone participating in this project's development, issue trackers and other channels is expected to follow our
[Code of Conduct](./CODE_OF_CONDUCT.md)

## Contributing

See the [contributing guide](https://github.com/simplecov-ruby/simplecov/blob/main/CONTRIBUTING.md).

## Kudos

Thanks to Aaron Patterson for the original idea for this!

## Copyright

Copyright (c) 2010-2017 Christoph Olszowka. See MIT-LICENSE for details.
