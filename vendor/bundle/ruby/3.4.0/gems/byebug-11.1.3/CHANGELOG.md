# Changelog

## [Unreleased]

## [11.1.3] - 2020-04-23

### Fixed

* [#674](https://github.com/deivid-rodriguez/byebug/pull/674): crash when using byebug on ruby 2.7.0 on Windows.

## [11.1.2] - 2020-04-17

### Fixed

* [#657](https://github.com/deivid-rodriguez/byebug/pull/657): crash when hitting \<TAB\> due to IRB completion mechanism included in the default ruby 2.7 version of the `irb` gem ([@terceiro]).

## [11.1.1] - 2020-01-24

### Fixed

* [#635](https://github.com/deivid-rodriguez/byebug/pull/635): usage on Fedora 31 or any other `byebug` installation performed by a `rubygems` copy customized by setting `Gem.install_extension_in_lib` to false.

## [11.1.0] - 2020-01-20

### Added

* Official support for MRI 2.7 ([@yui-knk]).

### Fixed

* [#562](https://github.com/deivid-rodriguez/byebug/pull/562): post mortem mode landing in the wrong line when coming from an exception inside a `Kernel.load` call.

### Removed

* Support for MRI 2.3. Byebug no longer installs on this platform.

## [11.0.1] - 2019-03-18

### Fixed

* [#546](https://github.com/deivid-rodriguez/byebug/pull/546): `continue!` to ignore further `byebug` calls.
* [#545](https://github.com/deivid-rodriguez/byebug/pull/545): `skip` autolisting code for intermediate skipped breakpoints.

## [11.0.0] - 2019-02-15

### Added

* [#377](https://github.com/deivid-rodriguez/byebug/pull/377): `skip` to continue until the next breakpoint as long as it is different from the current one. You can use this command to get out of loops, for example ([@tacnoman]).
* [#524](https://github.com/deivid-rodriguez/byebug/pull/524): `continue!` (or `continue unconditionally`) to continue until the end of the program regardless of the currently enabled breakpoints ([@tacnoman]).

### Fixed

* [#527](https://github.com/deivid-rodriguez/byebug/pull/527): `break` help text to clarify placeholders from literals.
* [#528](https://github.com/deivid-rodriguez/byebug/pull/528): `quit!` help to not show a space between "quit" and "!".

### Removed

* Support for MRI 2.2. Byebug no longer installs on this platform.

## [10.0.2] - 2018-03-30

### Fixed

* [#447](https://github.com/deivid-rodriguez/byebug/pull/447): Error when using byebug with `debase` gem ([@tzmfreedom]).

## [10.0.1] - 2018-03-21

### Fixed

* [#443](https://github.com/deivid-rodriguez/byebug/pull/443): Error when using byebug with `debase` gem ([@tzmfreedom]).

## [10.0.0] - 2018-01-26

### Changed

* Breaking on methods now stops on the first effective line of a method, not on the line containing the `def` keyword.

### Added

* [#393](https://github.com/deivid-rodriguez/byebug/pull/393): Show valid breakpoint locations when invalid location given ([@ko1]).
* [#397](https://github.com/deivid-rodriguez/byebug/pull/397): Ruby 2.5.0 support ([@yui-knk]).
* Log host & port when launching byebug's client in remote mode.
* [#82](https://github.com/deivid-rodriguez/byebug/issues/82): Some love & tests to remote debugging.
* [#141](https://github.com/deivid-rodriguez/byebug/issues/141): `remote_byebug` shortcut to start the most common case for remote debugging.

### Fixed

* [#419](https://github.com/deivid-rodriguez/byebug/pull/419): Properly ignore ruby fullpath executable when passed to byebug script.
* [#141](https://github.com/deivid-rodriguez/byebug/issues/141): Remote server crash when interrupting client.
* [#274](https://github.com/deivid-rodriguez/byebug/issues/274): Remote server crash when interrupting client.
* [#239](https://github.com/deivid-rodriguez/byebug/issues/239): Control server thread being able to `interrupt` main thread only a single time.

## [9.1.0] - 2017-08-22

### Added

* Better UI messages for breakpoint management.

### Fixed

* `where` command failing on instance_exec block stack frames.
* [#321](https://github.com/deivid-rodriguez/byebug/pull/321): `restart` command crashing in certain cases because of a missing `require "English"` ([@akaneko3]).
* [#321](https://github.com/deivid-rodriguez/byebug/pull/321): `restart` command crashing when debugged script is not executable or has no shebang ([@akaneko3]).

### Removed

* Ruby 2.0 and Ruby 2.1 official & unofficial support. Byebug no longer installs on these platforms.

## [9.0.6] - 2016-09-29

### Fixed

* [#241](https://github.com/deivid-rodriguez/byebug/issues/241): Error when using `byebug` with a ruby compiled against libedit.
* [#277](https://github.com/deivid-rodriguez/byebug/pull/277): Allow `Byebug.start_server` to yield the block passed to it when the actual port is already known ([@cben]).
* [#275](https://github.com/deivid-rodriguez/byebug/pull/275): Use a standard license name so it can be more reliably used by tools.

## [9.0.5] - 2016-05-28

### Fixed

* Error loading rc file when `ENV["HOME"]` is unset.

## [9.0.4] - 2016-05-19

### Fixed

* Errors in rc file not being displayed to the user.

## [9.0.3] - 2016-05-16

### Fixed

* [#256](https://github.com/deivid-rodriguez/byebug/issues/256): Unfriendly output in byebug's executable when no script specified.
* Unfriendly output in byebug's executable when script doesn't exist.
* Unfriendly output in byebug's executable when script has invalid code.

## [9.0.2] - 2016-05-15

### Fixed

* [#263](https://github.com/deivid-rodriguez/byebug/pull/263): Skip to get a line in eval context ([@k0kubun]).
* [#264](https://github.com/deivid-rodriguez/byebug/pull/264): Debugger getting disabled after `continue` even when linetrace is enabled ([@k0kubun]).

## [9.0.1] - 2016-05-14

### Fixed

* [#201](https://github.com/deivid-rodriguez/byebug/issues/201): `quit` never exiting when remote debugging.

## [9.0.0] - 2016-05-11

### Fixed

* `irb` command unintentionally changing $PROGRAM_NAME.
* `pry` command failing.
* Unrelated error message when using `pry` command and Pry not installed.
* [#239](https://github.com/deivid-rodriguez/byebug/issues/239): Interrupting program execution from remote control interface ([@izaera]).

### Removed

* Official Ruby 2.0.0 support. `var local` no longer works in Ruby 2.0. The rest of the commands should still work as before, but `byebug` is no longer tested against this version so they might start breaking in the future.

## [8.2.5] - 2016-04-27

### Fixed

* [#244](https://github.com/deivid-rodriguez/byebug/pull/244): Allows paths with spaces ([@HookyQR]).
* [#244](https://github.com/deivid-rodriguez/byebug/pull/244): Allows paths with colons ([@HookyQR]).

## [8.2.4] - 2016-04-08

### Fixed

* Reverts [#211](https://github.com/deivid-rodriguez/byebug/pull/211) which leads to an unusable debugger.

## [8.2.3] - 2016-04-07

### Fixed

* Better interaction with utilities like RSpec when hitting Ctrl-C.
* [#197](https://github.com/deivid-rodriguez/byebug/issues/197): `irb` command when original program modified ARGV ([@josephks]).
* [#211](https://github.com/deivid-rodriguez/byebug/pull/211): Unusable debugger when stdin redirected ([@sethk]).
* [#223](https://github.com/deivid-rodriguez/byebug/issues/223): RC file loading when no explicit flag included.
* [#175](https://github.com/deivid-rodriguez/byebug/issues/175): Installation on some Windows systems.
* [#226](https://github.com/deivid-rodriguez/byebug/issues/226): Installation on some Windows systems.

## [8.2.2] - 2016-02-01

### Fixed

* Bug in rc file loading where most initialization commands would not be run.

## [8.2.1] - 2015-11-26

### Fixed

* Bug in evaluations using "eval".

## [8.2.0] - 2015-11-12

### Fixed

* [#184](https://github.com/deivid-rodriguez/byebug/issues/184): Due to the way of running evaluations in a separate thread.
* [#188](https://github.com/deivid-rodriguez/byebug/issues/188): Due to the way of running evaluations in a separate thread.

### Added

* `debug` command to evaluate things in a separate thread, since this behavior was removed from default `eval` to fix the above issues.

## [8.1.0] - 2015-11-09

### Fixed

* Command history should be specific per project.
* Better error message in certain edge cases when printing the backtrace.
* Bug in evaluator which would show information about having stopped at a breakpoint in some cases.

### Added

* Ability to autolist source code after `frame` command.
* Ability to stop at lines where methods return.

## [8.0.1] - 2015-11-07

### Fixed

* Error stream wouldn't be properly reset when using standalone `byebug`.
* Confusing error message for invalid breakpoint locations.

## [8.0.0] - 2015-11-05

### Fixed

* [#183](https://github.com/deivid-rodriguez/byebug/issues/183). Compilation in Ruby 2.0. Regression introduced in [7.0.0].
* "Return value is: nil" would be displayed when stopping right before the end of a class definition. We want to avoid showing anything instead.

### Changed

* Plugins now need to implement an `at_end` method (separate from `at_return`) in their custom processors.

## [7.0.0] - 2015-11-04

### Fixed

* [#177](https://github.com/deivid-rodriguez/byebug/issues/177). Some issues with formatting results of evaluations.
* [#144](https://github.com/deivid-rodriguez/byebug/issues/144). Ruby process after using byebug does no longer get slow.
* [#121](https://github.com/deivid-rodriguez/byebug/issues/121). `byebug` commands inside code evaluated from debugger's prompt are now properly working.
* Another evaluation bug in autocommands.
* `finish 0` command would sometimes fail to stop right before exiting the current frame.
* Runner's `--[no-]stop` option now works ([@windwiny]).
* Change variable name `bool`, avoid conflict clang's predefined macro.

### Removed

* `ps` command.

### Changed

* [#166](https://github.com/deivid-rodriguez/byebug/issues/166). Don't load the entire library on require, but only when a `byebug` call is issued ([@bquorning]).
* The above fix to the `finish 0` command cause `byebug`'s entrypoint to require 3 steps out instead of 2. In general, plugins using `Byebug::Context.step_out` will need to be changed to consider "c return events" as well.

### Added

* `autopry` setting that calls `pry` on every stop.
* Return value information to debugger's output when `finish 0` is used.

## [6.0.2] - 2015-08-20

### Fixed

* The user should always be given back a prompt unless (s)he explicitly states the opposite. This provides a more general fix to the bug resolved in [6.0.1].

## [6.0.1] - 2015-08-19

### Fixed

* Bug in evaluation where the user would lose the command prompt when entering an expression with a syntax error.

## [6.0.0] - 2015-08-17

### Removed

* `autoeval` setting. I haven't heard of anyone setting it to false.
* `pp`, `putl`, `eval`. People just want to evaluate Ruby code, so the less magic the better. Most of the people probably were not aware that `byebug` was overriding stuff like `pp` or `eval`. Only keeping `ps` as the single "enhanced evaluation" command.
* `verbose` setting.
* `info catch` command. Use `catch` without arguments instead.
* `R` command alias for `restart`.

### Changed

* `info args` is now `var args`.
* `interrupt` is now aliased to `int`, not to `i`.
* API to define custom commands and subcommands (see the Command class).

### Fixed

* [#140](https://github.com/deivid-rodriguez/byebug/issues/140). `help` command not showing the list of available commands and their descriptions.
* [#147](https://github.com/deivid-rodriguez/byebug/issues/147). Setting breakpoints at symlinked files.

### Added

* API to define custom command processors (see the CommandProcessor class).

## [5.0.0] - 2015-05-18

### Fixed

* [#136](https://github.com/deivid-rodriguez/byebug/issues/136). `frame` command not working with negative numbers ([@ark6]).

### Added

* IDE support and a new command/subcommand API for plugins.
* Add a "savefile" setting holding the file where "save" command saves current debugger's state.

### Changed

* `disable` no longer disable all breakpoints, it just shows command's help instead. To disable all breakpoints now you need to do `disable breakpoints` (or `dis b`). Similarly, you can't no longer use `dis 1 2 3` but need to do `dis b 1 2 3` to disable specific breakpoints. The same applies to the `enable` command.

### Removed

* `help set <setting>` no longer works. `help set` includes that same output and it's not verbose enough so that this is a problem. Same with `help show <setting>`.

## [4.0.5] - 2015-04-02

### Fixed

* [#131](https://github.com/deivid-rodriguez/byebug/issues/131).
* Thread commands help format should be consistent with the rest of the help system now.

## [4.0.4] - 2015-03-27

### Fixed

* [#127](https://github.com/deivid-rodriguez/byebug/issues/127).

## [4.0.3] - 2015-03-19

### Fixed

* Unused variable warning in `context.c`.

## [4.0.2] - 2015-03-16

### Fixed

* [#118](https://github.com/deivid-rodriguez/byebug/issues/118). Remove `rb-readline` as a dependency and show a help message whenever requiring `readline` fails instead.

## [4.0.1] - 2015-03-13

### Fixed

* .yml files needed for printers support were missing from the release... :S
* [#118](https://github.com/deivid-rodriguez/byebug/issues/118). Add `readline` as a dependency.

## [4.0.0] - 2015-03-13

### Added

* `untracevar` command that stops tracing a global variable.
* Window CI build through AppVeyor.
* OSX CI build through Travis.
* Style enforcement through RuboCop.
* C style enforment using the `indent` command line utility.
* Some remote debugging tests ([@eric-hu]).
* Printer's support ([@astashov]).

### Changed

* A lot of internal refactoring.
* `tracevar` now requires the full global variable name (with "$").
* [#92](https://github.com/deivid-rodriguez/byebug/issues/92). The `catch` command is not allowed in post_mortem mode anymore. It was not working anyways.
* [#85](https://github.com/deivid-rodriguez/byebug/issues/85). `step` is now more user friendly when used in combination with `up`.
* `var const` can now be called without an argument and will show constants in the current scope.
* `break` with a class name now creates breakpoints regardless of class not being yet defined. If that's the case, it gives a warning but the class is created anyways.

### Fixed

* Code reloading issues.
* `set fullpath` was not showing fullpaths. Now it is.
* [#93](https://github.com/deivid-rodriguez/byebug/issues/93): `up`, `down` and `frame` commands now work in post_mortem mode.
* rc file (`.byebugrc`) loading: invalid commands are just ignored instead of aborting, global (home) rc file is now properly loaded before project's file.
* [#93](https://github.com/deivid-rodriguez/byebug/issues/93). Backtraces not working in `post_mortem` mode.
* 'cmd1 ; cmd2 ; ...; cmdN' syntax which allows running several commands sequentially.
* [#101](https://github.com/deivid-rodriguez/byebug/issues/101). `finish` command not stopping at the correct line.
* [#106](https://github.com/deivid-rodriguez/byebug/issues/106). `break` with namespaced class, like `break A::B#c` should now work.
* Command history is now persisted before exiting byebug.
* Setting breakpoint in a method would stop not only at the beginning of the method but also at the beginning of every block inside the method.
* [#122](https://github.com/deivid-rodriguez/byebug/issues/122). Setting breakpoints on module methods ([@x-yuri]).

### Removed

* `autoreload` setting as it's not necessary anymore. Code should always be up to date.
* `reload` command for the same reason.
* Gem dependency on `debugger-linecache`.
* `step+`, `step-`, `next+`, `next-`, `set/show linetrace_plus` and `set/show forcestep` commands. These were all mechanisms to deal with TracePoint API event dupplication, but this duplicated events have been completely removed from the API since [r48609]( bugs.ruby-lang.org/projects/ruby-trunk/repository/revisions/48609), so they are no longer necessary.
* `info file` subcommands: `info file breakpoints`, `info file mtime`, `info file sha1`, `info file all`. Now all information is listed under `info file`.
* `testing` setting. It was just a hack to be able to test `byebug`. Nobody was supposed to actually use it!
* `var class` command, just use Ruby (`self.class.class_variables`).
* `p` command, just use `eval`, or just type your expression and `byebug` will autoevaluate it.
* `exit` alias for `quit`.

## [3.5.1] - 2014-09-29

### Fixed

* [#79](https://github.com/deivid-rodriguez/byebug/issues/79). Windows installation.
* `condition` command not properly detecting invalid breakpoint ids.

## [3.5.0] - 2014-09-28

### Fixed

* [#81](https://github.com/deivid-rodriguez/byebug/issues/81). Byebug's history messing up other programs using Readline.
* Readline's history not being properly saved and inmediately available.
* User not being notified when trying to debug a non existent script.

### Changed

* Complete rewrite of byebug's history.
* Complete rewrite of list command.
* Docs about stacktrace related commands (`up`, `down`, `frame`, `backtrace`).

## [3.4.2] - 2014-09-26

### Fixed

* [#67](https://github.com/deivid-rodriguez/byebug/issues/67). Debugging commands invoked by ruby executable, as in `byebug -- ruby -Itest a_test.rb -n test_something`.

## [3.4.1] - 2014-09-25

### Fixed

* [#54](https://github.com/deivid-rodriguez/byebug/issues/54). Use of threads inside `eval` command.
* `list` command not listing backwards after reaching the end of the file.

## [3.4.0] - 2014-09-01

### Fixed

* deivid-rodriguez/pry-byebug#32 in a better way.

## [3.3.0] - 2014-08-28

### Fixed

* `set verbose` command.
* `set post_mortem false` command.
* Debugger stopping in `byebug`'s internal frames in some cases.
* `backtrace` crashing when `fullpath` setting disabled and calculated stack size being smaller than the real one.

### Changed

* The `-t` option for `bin/byebug` now turns tracing on whereas the `-x` option tells byebug to run the initialization file (.byebugrc) on startup. This is the default behaviour though.
* `bin/byebug` libified and tests added.

### Removed

* `info locals` command. Use `var local` instead.
* `info instance_variables` command. Use `var instance` instead.
* `info global_variables` command. Use `var global` instead.
* `info variables` command. Use `var all` instead.
* `irb` command stepping capabilities, see [8e226d0](https://github.com/deivid-rodriguez/byebug/commit/8e226d0).
* `script` and `restart-script` options for `bin/byebug`.

## [3.2.0] - 2014-08-02

### Fixed

* [#71](https://github.com/deivid-rodriguez/byebug/issues/71). Remote debugging ([@shuky19]).
* [#69](https://github.com/deivid-rodriguez/byebug/issues/69). `source` command ([@Olgagr]).

### Removed

* `post_mortem` activation through `Byebug.post_mortem`. Use `set post_mortem` instead.
* `info stack` command. Use `where` instead.
* `method iv` command. Use `var instance` instead.
* [#77](https://github.com/deivid-rodriguez/byebug/issues/77). Warning.

## [3.1.2] - 2014-04-23

### Fixed

* `post_mortem` mode in `bin/byebug` (really).
* Line tracing in `bin/byebug`.

## [3.1.1] - 2014-04-23

### Fixed

* `post_mortem` mode in bin/byebug.

## [3.1.0] - 2014-04-23

### Removed

* `show commands` command. Use `history` instead.
* Byebug.start accepting options. Any program settings you want applied from the start should be set in `.byebugrc`.
* `trace` command. Use `set linetrace` for line tracing and `tracevar` for global variable tracing.
* `show version` command. Use `byebug --version` to check byebug's version.
* `set arg` setting. Use the `restart` command instead.

### Changed

* `linetrace_plus` setting renamed to `tracing_plus`.

### Added

* `history` command to check byebug's history of previous commands.

## [3.0.0] - 2014-04-17

### Fixed

* Plain `byebug` not working when `pry-byebug` installed.
* `post_mortem` mode.
* Command history not being saved after regular program termination.
* [#54](https://github.com/deivid-rodriguez/byebug/issues/54). (Again) calling `Byebug.start` with `Timeout.timeout` ([@zmoazeni]).

### Added

* Allow disabling `post_mortem` mode.

### Changed

* `show commands` command for listing history of previous commands now behaves like shell's `history` command.
* `show/set history filename` is now `show/set histfile`.
* `show/set history size` is now `show/set histsize`.
* `show/set history save` is now `show/set autosave`.
* `finish` semantics, see [61f9b4d](https://github.com/deivid-rodriguez/byebug/commit/61f9b4d).
* Use per project history file by default.

### Removed

* The `init` option for `Byebug.start`. Information to make the `restart` command work is always saved now.

## [2.7.0] - 2014-02-24

### Fixed

* [#52](https://github.com/deivid-rodriguez/byebug/issues/52). `IGNORED_FILES` slowing down startup.
* [#53](https://github.com/deivid-rodriguez/byebug/issues/53). Calling `Byebug.start` with `Timeout.timeout`.
* [#54](https://github.com/deivid-rodriguez/byebug/issues/54). Calling `Byebug.start` with `Timeout.timeout`.

## [2.6.0] - 2014-02-08

### Fixed

* Circular dependency affecting `pry-byebug` ([@andreychernih]).

## [2.5.0] - 2013-12-14

### Added

* Support for `sublime-debugger`.

## [2.4.1] - 2013-12-05

### Fixed

* [#40](https://github.com/deivid-rodriguez/byebug/issues/40). Installation error in Mac OSX ([@luislavena]).

## [2.4.0] - 2013-12-02

### Fixed

* `thread list` showing too many threads.
* Fix setting post mortem mode with `set post_mortem`. Now this is the only post mortem functionality available as specifying `Byebug.post_mortem` with a block has been removed in this version.

### Added

* (Again) `debugger` as an alias to `byebug` ([@wallace]).
* `-R` option for `bin/byebug` to specify server's hostname:port for remote debugging ([@mrkn]).

### Changed

* Use `require` instead of `require_relative` for loading byebug's extension library ([@nobu]).
* `trace variable $foo` should be now `trace variable $foo`.

## [2.3.1] - 2013-10-17

### Fixed

* Breakpoint removal.
* Broken test suite.

## [2.3.0] - 2013-10-09

### Added

* Compatibility with Phusion Passenger Enterprise ([@FooBarWidget]).

### Changed

* More minimalist help system.

## [2.2.2] - 2013-09-25

### Fixed

* Compilation issue in 64 bit systems.

## [2.2.1] - 2013-09-24

### Fixed

* [#26](https://github.com/deivid-rodriguez/byebug/issues/26). Compilation issue introduced in [2.2.0].

### Changed

* `show/set stack_trace_on_error` is now `show/set stack_on_error`.

## [2.2.0] - 2013-09-22

### Fixed

* Stack size calculations.
* Setting `post_mortem` mode.

### Added

* `verbose` setting for TracePoint API event inspection.

### Changed

* Warning free byebug.
* Allow `edit <filename>` without a line number.

## [2.1.1] - 2013-09-10

### Fixed

* Debugging code inside `-e` Ruby flag.

## [2.1.0] - 2013-09-08

### Fixed

* Remote debugging display.
* `eval` crashing when inspecting raised an exception (reported by [@iblue]).

### Changed

* `enable breakpoints` now enables every breakpoint.
* `disable breakpoints` now disables every breakpoint.

## [2.0.0] - 2013-08-30

### Added

* "Official" definition of a command API.
* Thread support.

### Removed

* `jump` command. It had never worked.

### Changed

* Several internal refactorings.

## [1.8.2] - 2013-08-16

### Fixed

* `save` command now saves the list of `displays`.
* Stack size calculation.

### Changed

* More user friendly regexps for commands.
* Better help for some commands.

## [1.8.1] - 2013-08-12

### Fixed

* Major regression introduced in [1.8.0].

## [1.8.0] - 2013-08-12

### Added

* Remote debugging support.

## [1.7.0] - 2013-08-03

### Added

* List command automatically called after callstack navigation commands.
* C-frames specifically marked in the callstack.
* C-frames skipped when navigating the callstack.

## [1.6.1] - 2013-07-10

### Fixed

* Windows compatibiliy: compilation and terminal width issues.

## [1.6.0] - 2013-07-10

### Fixed

* `byebug` placed at the end of a block or method call not working as expected.
* `autolist` being applied when Ruby `-e` option used.

### Changed

* Backtrace callstyles. Use `long` for detailed frames in callstack and `short` for more concise frames.

## [1.5.0] - 2013-06-21

### Fixed

* Incomplete backtraces when the debugger was not started at program startup.

## [1.4.2] - 2013-06-20

### Fixed

* `help command subcommand` command.
* Interaction with Rails Console debugging flag.
* `post_mortem` mode when running byebug from the outset.
* `no-quit` flag when running byebug from the outset.

## [1.4.1] - 2013-06-15

### Fixed

* Crash when printing some filenames in backtraces.
* Allow byebug developers to easily use compilers different from gcc ([@GarthSnyder]).

## [1.4.0] - 2013-06-05

### Fixed

* Memory leaks causing `byebug` to randomly crash.

### Changed

* Use the Debug Inspector API for backtrace information.

## [1.3.1] - 2013-06-02

### Fixed

* Interaction with Rails debugging flag.
* Crash when trying to print lines of code containing the character '%'.
* `basename` and `linetrace` options not working together.

## [1.3.0] - 2013-05-25

### Added

* Support colon-delimited include paths in command-line front-end ([@ender672]).

## [1.2.0] - 2013-05-20

### Fixed

* Ctrl+C during command line editing (works like pry/irb).

### Added

* `pry` command.

## [1.1.1] - 2013-05-07

### Added

* `pry-byebug` compatibility.

### Changed

* Better help system.
* Code cleanup.

## [1.1.0] - 2013-04-30

### Added

* Post Mortem support.

## [1.0.3] - 2013-04-23

### Fixed

* Negative line numbers shown by list command at the beginning of file.
* `backtrace` command segfaulting when trying to show info on some frame args. Don't know the reason yet, but the exception is handled now and command does not segfault anymore.

### Changed

* `autoreload` is set by default now.
* Try some thread support (not even close to usable).

## [1.0.2] - 2013-04-09

### Fixed

* backtraces messed up when using both `next`/`step` and backtrace navigation commands.

### Changed

* `autolist` and `autoeval` are default settings now.

## [1.0.1] - 2013-04-06

### Fixed

* Byebug not loading properly.

## [1.0.0] - 2013-03-29

### Fixed

* Green test suite.

## 0.0.1 - 2013-03-18

### Added

* Initial release.

[Unreleased]: https://github.com/deivid-rodriguez/byebug/compare/v11.1.3...HEAD
[11.1.3]: https://github.com/deivid-rodriguez/byebug/compare/v11.1.2...v11.1.3
[11.1.2]: https://github.com/deivid-rodriguez/byebug/compare/v11.1.1...v11.1.2
[11.1.1]: https://github.com/deivid-rodriguez/byebug/compare/v11.1.0...v11.1.1
[11.1.0]: https://github.com/deivid-rodriguez/byebug/compare/v11.0.1...v11.1.0
[11.0.1]: https://github.com/deivid-rodriguez/byebug/compare/v11.0.0...v11.0.1
[11.0.0]: https://github.com/deivid-rodriguez/byebug/compare/v10.0.2...v11.0.0
[10.0.2]: https://github.com/deivid-rodriguez/byebug/compare/v10.0.1...v10.0.2
[10.0.1]: https://github.com/deivid-rodriguez/byebug/compare/v10.0.0...v10.0.1
[10.0.0]: https://github.com/deivid-rodriguez/byebug/compare/v9.1.0...v10.0.0
[9.1.0]: https://github.com/deivid-rodriguez/byebug/compare/v9.0.6...v9.1.0
[9.0.6]: https://github.com/deivid-rodriguez/byebug/compare/v9.0.5...v9.0.6
[9.0.5]: https://github.com/deivid-rodriguez/byebug/compare/v9.0.4...v9.0.5
[9.0.4]: https://github.com/deivid-rodriguez/byebug/compare/v9.0.3...v9.0.4
[9.0.3]: https://github.com/deivid-rodriguez/byebug/compare/v9.0.2...v9.0.3
[9.0.2]: https://github.com/deivid-rodriguez/byebug/compare/v9.0.1...v9.0.2
[9.0.1]: https://github.com/deivid-rodriguez/byebug/compare/v9.0.0...v9.0.1
[9.0.0]: https://github.com/deivid-rodriguez/byebug/compare/v8.2.5...v9.0.0
[8.2.5]: https://github.com/deivid-rodriguez/byebug/compare/v8.2.4...v8.2.5
[8.2.4]: https://github.com/deivid-rodriguez/byebug/compare/v8.2.3...v8.2.4
[8.2.3]: https://github.com/deivid-rodriguez/byebug/compare/v8.2.2...v8.2.3
[8.2.2]: https://github.com/deivid-rodriguez/byebug/compare/v8.2.1...v8.2.2
[8.2.1]: https://github.com/deivid-rodriguez/byebug/compare/v8.2.0...v8.2.1
[8.2.0]: https://github.com/deivid-rodriguez/byebug/compare/v8.1.0...v8.2.0
[8.1.0]: https://github.com/deivid-rodriguez/byebug/compare/v8.0.1...v8.1.0
[8.0.1]: https://github.com/deivid-rodriguez/byebug/compare/v8.0.0...v8.0.1
[8.0.0]: https://github.com/deivid-rodriguez/byebug/compare/v7.0.0...v8.0.0
[7.0.0]: https://github.com/deivid-rodriguez/byebug/compare/v6.0.2...v7.0.0
[6.0.2]: https://github.com/deivid-rodriguez/byebug/compare/v6.0.1...v6.0.2
[6.0.1]: https://github.com/deivid-rodriguez/byebug/compare/v6.0.0...v6.0.1
[6.0.0]: https://github.com/deivid-rodriguez/byebug/compare/v5.0.0...v6.0.0
[5.0.0]: https://github.com/deivid-rodriguez/byebug/compare/v4.0.5...v5.0.0
[4.0.5]: https://github.com/deivid-rodriguez/byebug/compare/v4.0.4...v4.0.5
[4.0.4]: https://github.com/deivid-rodriguez/byebug/compare/v4.0.3...v4.0.4
[4.0.3]: https://github.com/deivid-rodriguez/byebug/compare/v4.0.2...v4.0.3
[4.0.2]: https://github.com/deivid-rodriguez/byebug/compare/v4.0.1...v4.0.2
[4.0.1]: https://github.com/deivid-rodriguez/byebug/compare/v4.0.0...v4.0.1
[4.0.0]: https://github.com/deivid-rodriguez/byebug/compare/v3.5.1...v4.0.0
[3.5.1]: https://github.com/deivid-rodriguez/byebug/compare/v3.5.0...v3.5.1
[3.5.0]: https://github.com/deivid-rodriguez/byebug/compare/v3.4.2...v3.5.0
[3.4.2]: https://github.com/deivid-rodriguez/byebug/compare/v3.4.1...v3.4.2
[3.4.1]: https://github.com/deivid-rodriguez/byebug/compare/v3.4.0...v3.4.1
[3.4.0]: https://github.com/deivid-rodriguez/byebug/compare/v3.3.0...v3.4.0
[3.3.0]: https://github.com/deivid-rodriguez/byebug/compare/v3.2.0...v3.3.0
[3.2.0]: https://github.com/deivid-rodriguez/byebug/compare/v3.1.2...v3.2.0
[3.1.2]: https://github.com/deivid-rodriguez/byebug/compare/v3.1.1...v3.1.2
[3.1.1]: https://github.com/deivid-rodriguez/byebug/compare/v3.1.0...v3.1.1
[3.1.0]: https://github.com/deivid-rodriguez/byebug/compare/v3.0.0...v3.1.0
[3.0.0]: https://github.com/deivid-rodriguez/byebug/compare/v2.7.0...v3.0.0
[2.7.0]: https://github.com/deivid-rodriguez/byebug/compare/v2.6.0...v2.7.0
[2.6.0]: https://github.com/deivid-rodriguez/byebug/compare/v2.5.0...v2.6.0
[2.5.0]: https://github.com/deivid-rodriguez/byebug/compare/v2.4.1...v2.5.0
[2.4.1]: https://github.com/deivid-rodriguez/byebug/compare/v2.4.0...v2.4.1
[2.4.0]: https://github.com/deivid-rodriguez/byebug/compare/v2.3.1...v2.4.0
[2.3.1]: https://github.com/deivid-rodriguez/byebug/compare/v2.3.0...v2.3.1
[2.3.0]: https://github.com/deivid-rodriguez/byebug/compare/v2.2.2...v2.3.0
[2.2.2]: https://github.com/deivid-rodriguez/byebug/compare/v2.2.1...v2.2.2
[2.2.1]: https://github.com/deivid-rodriguez/byebug/compare/v2.2.0...v2.2.1
[2.2.0]: https://github.com/deivid-rodriguez/byebug/compare/v2.1.1...v2.2.0
[2.1.1]: https://github.com/deivid-rodriguez/byebug/compare/v2.1.0...v2.1.1
[2.1.0]: https://github.com/deivid-rodriguez/byebug/compare/v2.0.0...v2.1.0
[2.0.0]: https://github.com/deivid-rodriguez/byebug/compare/v1.8.2...v2.0.0
[1.8.2]: https://github.com/deivid-rodriguez/byebug/compare/v1.8.1...v1.8.2
[1.8.1]: https://github.com/deivid-rodriguez/byebug/compare/v1.8.0...v1.8.1
[1.8.0]: https://github.com/deivid-rodriguez/byebug/compare/v1.7.0...v1.8.0
[1.7.0]: https://github.com/deivid-rodriguez/byebug/compare/v1.6.1...v1.7.0
[1.6.1]: https://github.com/deivid-rodriguez/byebug/compare/v1.6.0...v1.6.1
[1.6.0]: https://github.com/deivid-rodriguez/byebug/compare/v1.5.0...v1.6.0
[1.5.0]: https://github.com/deivid-rodriguez/byebug/compare/v1.4.2...v1.5.0
[1.4.2]: https://github.com/deivid-rodriguez/byebug/compare/v1.4.1...v1.4.2
[1.4.1]: https://github.com/deivid-rodriguez/byebug/compare/v1.4.0...v1.4.1
[1.4.0]: https://github.com/deivid-rodriguez/byebug/compare/v1.3.1...v1.4.0
[1.3.1]: https://github.com/deivid-rodriguez/byebug/compare/v1.3.0...v1.3.1
[1.3.0]: https://github.com/deivid-rodriguez/byebug/compare/v1.2.0...v1.3.0
[1.2.0]: https://github.com/deivid-rodriguez/byebug/compare/v1.1.1...v1.2.0
[1.1.1]: https://github.com/deivid-rodriguez/byebug/compare/v1.1.0...v1.1.1
[1.1.0]: https://github.com/deivid-rodriguez/byebug/compare/v1.0.3...v1.1.0
[1.0.3]: https://github.com/deivid-rodriguez/byebug/compare/v1.0.2...v1.0.3
[1.0.2]: https://github.com/deivid-rodriguez/byebug/compare/v1.0.1...v1.0.2
[1.0.1]: https://github.com/deivid-rodriguez/byebug/compare/v1.0.0...v1.0.1
[1.0.0]: https://github.com/deivid-rodriguez/byebug/compare/v0.0.1...v1.0.0

[@akaneko3]: https://github.com/akaneko3
[@andreychernih]: https://github.com/andreychernih
[@ark6]: https://github.com/ark6
[@astashov]: https://github.com/astashov
[@bquorning]: https://github.com/bquorning
[@cben]: https://github.com/cben
[@ender672]: https://github.com/ender672
[@eric-hu]: https://github.com/eric-hu
[@FooBarWidget]: https://github.com/FooBarWidget
[@GarthSnyder]: https://github.com/GarthSnyder
[@HookyQR]: https://github.com/HookyQR
[@iblue]: https://github.com/iblue
[@izaera]: https://github.com/izaera
[@josephks]: https://github.com/josephks
[@k0kubun]: https://github.com/k0kubun
[@ko1]: https://github.com/ko1
[@luislavena]: https://github.com/luislavena
[@mrkn]: https://github.com/mrkn
[@nobu]: https://github.com/nobu
[@Olgagr]: https://github.com/Olgagr
[@sethk]: https://github.com/sethk
[@shuky19]: https://github.com/shuky19
[@tacnoman]: https://github.com/tacnoman
[@terceiro]: https://github.com/terceiro
[@tzmfreedom]: https://github.com/tzmfreedom
[@wallace]: https://github.com/wallace
[@windwiny]: https://github.com/windwiny
[@x-yuri]: https://github.com/x-yuri
[@yui-knk]: https://github.com/yui-knk
[@zmoazeni]: https://github.com/zmoazeni
