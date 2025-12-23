## Change Log

Below is a complete listing of changes for each revision of HighLine.

### 2.1.0 / 2022-12-31
* PR #255 - Change minimum Ruby version requirement to 2.3 (@abinoam)
* PR #254 - Improve Github Actions file (@abinoam)
* PR #253, PR #251 - Setup GitHub Actions and remove Travis (@petergoldstein, rev by @AlexWayfer)
* PR #250 - Fix file permissions (@bdunne)

### 2.0.3 / 2019-10-11
* PR #245 - Suppress `Psych.safe_load` arg warn (@koic)

### 2.0.2 / 2019-04-08
* PR #243 - Add new capital_letter option to menu index (@Ana06)
  * This is a really special PR. It has come from "The Biggest
    Mobprogramming Session Ever" and around 250 people
    participated in crafting it!
* PR #241 - CI: Add 2.6 (@olleolleolle)
* PR #240 - Avoid YARD warning UnknownParam (@olleolleolle)

### 2.0.1 / 2019-01-23
* PR #238 / I #237 - Rescue Errno::ENOTTY when pipeing

### 2.0.0 / 2018-06-10
* Release 2.0.0 (major version release).

### 2.0.0-develop.16 / 2018-05-12
* PR #231 - Deprecate safe_level of ERB.new in Ruby 2.6 (@koic)
* PR #230 - Fix behavior when shell and gather options are selected together

### 2.0.0-develop.15 / 2017-12-28
* PR #229 - Update .travis.yml. Add Ruby 2.5 to matrix (@abinoam)

### 2.0.0-develop.14 / 2017-11-21
* PR #222 / I #221 - Fix inconsistent behaviour when using agree with readline (@abinoam, @ailisp)

### 2.0.0-develop.13 / 2017-11-05
* PR #219 - Make possible to use a callable as response (@abinoam)

### 2.0.0-develop.12 / 2017-10-19
* PR #218 - Ease transition from 1.7.x to 2.0.x (@abinoam)
  * Copy use_color from HighLine.default_instance
  * Expose IOConsoleCompatible
* PR #216 - Update .appveyor.yml - Fix Windows CI (@abinoam)

### 2.0.0-develop.11 / 2017-09-25
* PR #215 - Apply several Rubocop stylistic suggestions (@abinoam)
  * Update gemspec/Gemfile to newer standards
  * Update travis configuration fixing 1.9 problem
  * Adjust .rubocop.yml with things we don't want to change

### 2.0.0-develop.10 / 2017-06-29
* PR #214 - Remove `$terminal` (global variable) (@abinoam)
  * Use HighLine.default_instance instead
  * Reorganize/Group code at lib/highline.rb

### 2.0.0-develop.9 / 2017-06-24

* PR #211 / PR #212 - HighLine#use_color= and use_color? as instance methods (@abinoam, @phiggins)
* PR #203 / I #191 - Default values are shown in menus by Frederico (@fredrb)
* PR #201 / I #198 - Confirm in question now accepts Proc (@mmihira)
* PR #197 - Some HighLine::Menu improvements
  * Move Menu::MenuItem to Menu::Item with its own file
  * Some small refactorings

### 2.0.0-develop.8 / 2016-06-03

* PR #195 - Add PRONTO to development group at Gemfile by Abinoam Jr. (@abinoam)

### 2.0.0-develop.7 / 2016-05-31

* PR #194 - Indices coloring on HighLine::Menu by Aregic (@aregic)
* PR #190 - Add Ruby 2.3.0 to travis matrix by Koichi (@koic/ruby-23)
* PR #189 - Improve #agree tests by @kevinoid

### 2.0.0-develop.6 / 2016-02-01

* PR #184 - Menu improvements, bug fixes, and more tests by Geoff Lee (@matrinox)
  * Add third arg to menu that overides the choice displayed to the user
  * FIX: autocomplete prompt does not include menu choices after the first
  * Add specs to cover the new features and the bug fix
* PR #183 - Fix menu example in README.md by Fabien Foerster (@fabienfoerster)

### 2.0.0-develop.5 / 2015-12-27

* Fix #180 with PR #181 - Make it possible to overwrite the menu prompt shown on errors.

### 2.0.0-develop.4 / 2015-12-14

This versions makes the code documentation 100% 'A' grade on inch.
We have used inch and http://inch-ci.org to guide the priorities
on documentation production.

The grade 'A' (on inch) number of objects on master branch was 44,22% (153/346).
After this PR we have a 100% grade 'A' (344 objects).

There's already a inch-ci.org badge on README.md. And now it's all green!

We also bring some improvement on CodeClimate scores.

#### CHANGES SUMMARY

* PR #179 - Make inch happy. Grade "A" for the whole HighLine documentation. By Abinoam Jr. (@abinoam)
* PR #178 - Improve score on Code Climate by applying some refactoring. By Abinoam Jr. (@abinoam)
* PR #172 - Initial work on documentation by Abinoam Jr. (@abinoam)
  * Use yard
  * Use inch
  * New Readme file
* Fix #166 with PR #173 by (@matugm)


### 2.0.0-develop.3 / 2015-10-28

This version brings some improvements on documentation (switch to Yardoc).
This is the first 2.0.0-develop.x version to be release as gem.

### 2.0.0-develop.2 / 2015-09-09

(by Abinoam P. Marques Jr. - @abinoam)

#### NOTES

This version brings greater compatibility with JRuby and Windows.
But we still have a lot of small issues in both platforms.
We were able to unify/converge all approaches into using io/console,
so we could delete old code that relied solely on stty, termios, java api and
windows apis (DL and Fiddle).

Another improvement is the beginning of what I called "acceptance tests".
If you type ```rake acceptance``` you'll be guided through some tests
where you have to input some thing and see if everything work as expected.
This makes easier to catch bugs that otherwise would be over-sighted.

#### CHANGES SUMMARY

* Fix Simplecov - it was reporting erroneous code coverage
* Add new tests. Improves code coverage
* Extract HighLine::BuiltinStyles
* Try to avoid nil checking
* Try to avoid class variables (mis)use
* Fix RDoc include path and some small fixes to the docs
* Move HighLine::String to its own file
* Add HighLine::Terminal::IOConsole
  - Add an IOConsoleCompatibility module with some stubbed
    methods for using at StringIO, File and Tempfile to help
    on tests.
  - Any enviroment that can require 'io/console' will
    use HighLine::Terminal::IOConsole by default. This kind
    of unifies most environments where HighLine runs. For
    example, we can use Terminal::IOConsole on JRuby!!!
* Add ruby-head and JRuby (19mode and head) to Travis CI matrix. Yes, this
  our first step to a more peaceful JRuby compatibility.
* Add AppVeyor Continuous Integration for Windows
* Add _acceptance_ tests for HighLine
  - Use ```rake acceptance``` to run them
  - Basically it interactively asks the user to confirm if
    some expected HighLine behavior is actually happening.
    After that it gather some environment debug information,
    so the use could send to the HighLine contributors in case
    of failure.
* Remove old and unused files (as a result of relying on io/console)
  - JRuby
  - Windows (DL and Fiddle)
  - Termios
* Fix some small (old and new) bugs
* Make some more tuning for Windows compatibility
* Make some more tuning for JRuby compatibility

### 2.0.0-develop.1 / 2015-06-11

This is the first development version of the 2.0.0 series. It's the begining of a refactoring phase on HighLine development cycle.

#### SOME HISTORY

In 2014 I emailed James Edward Gray II (@JEG2) about HighLine. One of his ideas was to completely refactor the library so that it could be easier to reuse and improve it. I've began my contributions to HighLine trying to fix some of the open issues at that time so that we could "freeze" a stable version of HighLine that people could rely on. Then I've began to study HighLine source code with James' help and started to refactor some parts of the code. Abinoam P. Marques Jr. (@abinoam)

#### NOTES

* This release differs from current master branch by more than 180 commits.
* The main changes will be only summarized bellow (as there are many, and a detailed description of each is not productive).
* You could try `git log -p` to see all of them.
* During the last commits, all possible efforts were taken to preserve the tests passing status.
* 100% test passing gives you no guarantee that this new version will work for you. This happens for many reasons. One of them is that we don't currently have 100% test coverage.
* So, this version is not suitable for use in production.
* [Metric_fu](https://github.com/metricfu/metric_fu) and [Code Climate](https://codeclimate.com/github/abinoam/highline) were used here not to strictly "guide" what should be changed, but to have some way to objectively measure the progresses made so far.

#### CHANGES SUMMARY
* Extracted a lot of smaller methods from bigger ones
* Extracted smaller classes/modules from bigger ones, so they could be self contained with less external dependencies as possible, for example:
  * HighLine::Statement
  * HighLine::List
  * HighLine::ListRenderer
  * HighLine::TemplateRenderer
  * HighLine::Question::AnswerConverter
  * HighLine::Terminal
  * HighLine::Terminal::UnixStty
  * HighLine::Paginator
  * HighLine::Wrapper
* After extracting each class/module some refactoring were applied to them lowering code complexity

#### METRICS SUMMARY
Some of the metrics used to track progress are summarized bellow. Some of them have got a lot better as Flay, Flog and Reek, others like Cane haven't (probably because we didn't commented out the new code yet)

__CODECLIMATE__

* GPA: 3.60 -> 3.67 (higher is better)

__CANE__ - reports code quality threshold violations (lower is better)

* Total 92 -> 105
  * Methods exceeding allowed Abc complexity: 14 -> 10
  * Lines violating style requirements: 69 -> 72
  * Class definitions requiring comments: 9 -> 23

__FLAY__ - analyzes ruby code for structural similarities (code duplication - lower is better)

* Total: 490 -> 94

__FLOG__ - measures code complexity (lower is better)

* Top 5% average: 127.9458 -> 40.99812
* Average: 17.37982 -> 7.663875
* Total: 2158.5 -> 1969.6

__REEK__ - detects common code smells in ruby code (lower is better)

* DuplicateMethodCall: 144 -> 54
* TooManyStatements: 26 -> 30

### 1.7.3 / 2015-06-29
* Add HighLine::Simulator tests (Bala Paranj (@bparanj) and Abinoam Marques Jr. (@abinoam), #142, PR #143)

### 1.7.2 / 2015-04-19

#### Bug fixes
* Fix #138 (a regression of #131). PR #139.

### 1.7.1 / 2015-02-24

#### Enhancements
* Add travis CI configuration (Eli Young (@elyscape), #130)
* Add Rubinius to Build Matrix with Allowed Failure (Brandon Fish
(bjfish), #132)
* Make some adjustments on tests (Abinoam Marques Jr., #133, #134)
* Drop support for Ruby 1.8 (Abinoam Marques Jr., #134)

#### Bug fixes
* Fix IO.console.winsize returning reversed column and line values (Fission Xuiptz (@fissionxuiptz)), #131)

### 1.7.0 / 2015-02-18

#### Bug fixes
* Fix correct encoding of statements to output encoding (Dāvis (davispuh), #110)
* Fix character echoing when echo is false and multibyte character is typed (Abinoam Marques Jr., #117 #118)
* Fix backspace support on Cyrillic (Abinoam Marques Jr., #115 #118)
* Fix returning wrong encoding when echo is false (Abinoam Marques Jr., #116 #118)
* Fix Question #limit and #realine incompatibilities (Abinoam Marques Jr. #113 #120)
* Fix/improve string coercion on #say (Abinoam Marques Jr., #98 #122)
* Fix #terminal_size returning nil in some terminals (Abinoam Marques Jr., #85 #123)

#### Enhancements
* Improve #format_statement String coercion (Michael Bishop
(michaeljbishop), #104)
* Update homepage url on gemspec (Rubyforge->GitHub) (Edward Anderson
(nilbus), #107)
* Update COPYING file (Vít Ondruch (voxik), #109)
* Improve multi-byte encoding support (Abinoam Marques Jr., #115 #116 #117 #118)
* Make :grey -> :gray and :light -> :bright aliases (Abinoam Marques Jr., #114 #119)
* Return the default object (as it is) when no answer given (Abinoam Marques Jr., #112 #121)
* Added test for Yaml serialization of HighLine::String (Abinoam Marques Jr., #69 #124)
* Make improvements on Changelog and Rakefile (Abinoam Marques Jr., #126 #127 #128)

### 1.6.21

* Improved Windows integration (by Ronie Henrich).
* Clarified menu choice error messages (by Keith Bennett).

### 1.6.20

* Fixed a bug with FFI::NCurses integration (by agentdave).
* Improved StringExtensions performance (by John Leach).
* Various JRuby fixes (by presidentbeef).

### 1.6.19

* Fixed `terminal_size()` with jline2 (by presidentbeef).

### 1.6.18

* Fixed a long supported interface that was accidentally broken with a recent change (by Rubem Nakamura Carneiro).

### 1.6.17

* Added encoding support to menus (by David Lyons).
* Some minor fixes to SystemExtensions (by whiteleaf and presidentbeef).

### 1.6.16

* Added the new indention feature (by davispuh).
* Separated auto-completion from the answer type (by davispuh).
* Improved JRuby support (by rsutphin).
* General code clean up (by stomar).
* Made HighLine#say() a little smarter with regard to color escapes (by Kenneth Murphy).

### 1.6.15

* Added support for nil arguments in lists (by Eric Saxby).
* Fixed HighLine's termios integration (by Jens Wille).

### 1.6.14

* Added JRuby 1.7 support (by Mina Nagy).
* Take into account color escape sequences when wrapping text (by Mark J.
  Titorenko).

### 1.6.13

* Removed unneeded Shebang lines (by Scott Gonyea).
* Protect the String passed to Question.new from modification (by michael).
* Added a retype-to-verify setting (by michael).

### 1.6.12

* Silenced warnings (by James McEwan).

### 1.6.11

* Fixed a bad test.  (Fix by Diego Elio Pettenò.)

### 1.6.10

* Fixed a regression that prevented asking for String arguments (by Jeffery
  Sman.)
* Fixed a testing incompatibility (by Hans de Graaff.)

### 1.6.9

* The new list modes now properly ignore escapes when sizing.
* Added a project gemspec file.
* Fixed a bug that prevented the use of termios (by tomdz).
* Switch to JLine to provide better echo support on JRuby (by tomdz).

### 1.6.8

* Fix missing <tt>ERASE_CHAR</tt> reference (by Aaron Gifford).

### 1.6.7

* Fixed bug introduced in 1.6.6 attempted fix (by Aaron Gifford).

### 1.6.6

* Fixed old style references causing <tt>HighLine::String</tt> errors (by Aaron Gifford).

### 1.6.5

* HighLine#list() now correctly handles empty lists (fix by Lachlan Dowding).
* HighLine#list() now supports <tt>:uneven_columns_across</tt> and
  <tt>:uneven_columns_down</tt> modes.

### 1.6.4

* Add introspection methods to color_scheme: definition, keys, to_hash.
* Add tests for new methods.

### 1.6.3

* Add color NONE.
* Add RGB color capability.
* Made 'color' available as a class or instance method of HighLine, for
  instance: HighLine.color("foo", :blue)) or highline_obj.color("foo", :blue)
  are now both possible and equivalent.
* Add HighLine::String class with convenience methods: #color (alias
  #foreground), #on (alias #background), colors, and styles. See
  lib/string_extensions.rb.
* Add (optional) ability to extend String with the same convenience methods from
  HighLine::String, using Highline.colorize_strings.

### 1.6.2

* Correctly handle STDIN being closed before we receive any data (fix by
  mleinart).
* Try if msvcrt, if we can't load crtdll on Windows (fix by pepijnve).
* A fix for nil_on_handled not running the action (reported by Andrew Davey).

### 1.6.1

* Fixed raw_no_echo_mode so that it uses stty -icanon rather than cbreak
  as cbreak does not appear to be the posixly correct argument. It fails
  on Solaris if cbreak is used.
* Fixed an issue that kept Menu from showing the correct choices for
  disambiguation.
* Removed a circular require that kept Ruby 1.9.2 from loading HighLine.
* Fixed a bug that caused infinite looping when wrapping text without spaces.
* Fixed it so that :auto paging accounts for the two lines it adds.
* On JRuby, improved error message about ffi-ncurses.  Before 1.5.3,
  HighLine was silently swallowing error messages when ffi-ncurses gem
  was installed without ncurses present on the system.
* Reverted Aaron Simmons's patch to allow redirecting STDIN on Windows.  This
  is the only way we could find to restore HighLine's character reading to
  working order.

### 1.5.2

* Added support for using the ffi-ncurses gem which is supported in JRuby.
* Added gem build instructions.

### 1.5.1

* Fixed the long standing echo true bug.
  (reported by Lauri Tuominen)
* Improved Windows API calls to support the redirection of STDIN.
  (patch by Aaron Simmons)
* Updated gem specification to avoid a deprecated call.
* Made a minor documentation clarification about character mode support.
* Worked around some API changes in Ruby's standard library in Ruby 1.9.
  (patch by Jake Benilov)

### 1.5.0

* Fixed a bug that would prevent Readline from showing all completions.
  (reported by Yaohan Chen)
* Added the ability to pass a block to HighLine#agree().
  (patch by Yaohan Chen)

### 1.4.0

* Made the code grabbing terminal size a little more cross-platform by
  adding support for Solaris.  (patch by Ronald Braswell and Coey Minear)

### 1.2.9

* Additional work on the backspacing issue. (patch by Jeremy Hinegardner)
* Fixed Readline prompt bug. (patch by Jeremy Hinegardner)

### 1.2.8

* Fixed backspacing past the prompt and interrupting a prompt bugs.
  (patch by Jeremy Hinegardner)

### 1.2.7

* Fixed the stty indent bug.
* Fixed the echo backspace bug.
* Added HighLine::track_eof=() setting to work are threaded eof?() calls.

### 1.2.6

Patch by Jeremy Hinegardner:

* Added ColorScheme support.
* Added HighLine::Question.overwrite mode.
* Various documentation fixes.

### 1.2.5

* Really fixed the bug I tried to fix in 1.2.4.

### 1.2.4

* Fixed a crash causing bug when using menus, reported by Patrick Hof.

### 1.2.3

* Treat Cygwin like a Posix OS, instead of a native Windows environment.

### 1.2.2

* Minor documentation corrections.
* Applied Thomas Werschleiln's patch to fix termio buffering on Solaris.
* Applied Justin Bailey's patch to allow canceling paged output.
* Fixed a documentation bug in the description of character case settings.
* Added a notice about termios in HighLine::Question#echo.
* Finally working around the infamous "fast typing" bug

### 1.2.1

* Applied Justin Bailey's fix for the page_print() infinite loop bug.
* Made a SystemExtensions module to expose OS level functionality other
  libraries may want to access.
* Publicly exposed the get_character() method, per user requests.
* Added terminal_size(), output_cols(), and output_rows() methods.
* Added :auto setting for warp_at=() and page_at=().

### 1.2.0

* Improved RubyForge and gem spec project descriptions.
* Added basic examples to README.
* Added a VERSION constant.
* Added support for hidden menu commands.
* Added Object.or_ask() when using highline/import.

### 1.0.4

* Moved the HighLine project to Subversion.
* HighLine's color escapes can now be disabled.
* Fixed EOF bug introduced in the last release.
* Updated HighLine web page.
* Moved to a forked development/stable version numbering.

### 1.0.2

* Removed old and broken help tests.
* Fixed test case typo found by David A. Black.
* Added ERb escapes processing to lists, for coloring list items.  Color escapes
  do not add to list element size.
* HighLine now throws EOFError when input is exhausted.

### 1.0.1

* Minor bug fix:  Moved help initialization to before response building, so help
  would show up in the default responses.

### 1.0.0

* Fixed documentation typo pointed out by Gavin Kistner.
* Added <tt>gather = ...</tt> option to question for fetching entire Arrays or
  Hashes filled with answers.  You can set +gather+ to a count of answers to
  collect, a String or Regexp matching the end of input, or a Hash where each
  key can be used in a new question.
* Added File support to HighLine.ask().  You can specify a _directory_ and a
  _glob_ pattern that combine into a list of file choices the user can select
  from.  You can choose to receive the user's answer as an open filehandle or as
  a Pathname object.
* Added Readline support for history and editing.
* Added tab completion for menu  and file selection selection (requires
  Readline).
* Added an optional character limit for input.
* Added a complete help system to HighLine's shell menu creation tools.

### 0.6.1

* Removed termios dependancy in gem, to fix Windows' install.

### 0.6.0

* Implemented HighLine.choose() for menu handling.
  * Provided shortcut <tt>choose(item1, item2, ...)</tt> for simple menus.
  * Allowed Ruby code to be attached to each menu item, to create a complete
    menu solution.
  * Provided for total customization of the menu layout.
  * Allowed for menu selection by index, name or both.
  * Added a _shell_ mode to allow menu selection with additional details
    following the name.
* Added a list() utility method that can be invoked just like color().  It can
  layout Arrays for you in any output in the modes <tt>:columns_across</tt>,
  <tt>:columns_down</tt>, <tt>:inline</tt> and <tt>:rows</tt>
* Added support for <tt>echo = "*"</tt> style settings.  User code can now
  choose the echo character this way.
* Modified HighLine to user the "termios" library for character input, if
  available.  Will return to old behavior (using "stty"), if "termios" cannot be
  loaded.
* Improved "stty" state restoring code.
* Fixed "stty" code to handle interrupt signals.
* Improved the default auto-complete error message and exposed this message
  through the +responses+ interface as <tt>:no_completion</tt>.

### 0.5.0

* Implemented <tt>echo = false</tt> for HighLine::Question objects, primarily to
  make fetching passwords trivial.
* Fixed an auto-complete bug that could cause a crash when the user gave an
  answer that didn't complete to any valid choice.
* Implemented +case+ for HighLine::Question objects to provide character case
  conversions on given answers.  Can be set to <tt>:up</tt>, <tt>:down</tt>, or
  <tt>:capitalize</tt>.
* Exposed <tt>@answer</tt> to the response system, to allow response that are
  aware of incorrect input.
* Implemented +confirm+ for HighLine::Question objects to allow for verification
  for sensitive user choices.  If set to +true+, user will have to answer an
  "Are you sure?  " question.  Can also be set to the question to confirm with
  the user.

### 0.4.0

* Added <tt>@wrap_at</tt> and <tt>@page_at</tt> settings and accessors to
  HighLine, to control text flow.
* Implemented line wrapping with adjustable limit.
* Implemented paged printing with adjustable limit.

### 0.3.0

* Added support for installing with setup.rb.
* All output is now treated as an ERb sequence, allowing Ruby code to be
  embedded in output strings.
* Added support for ANSI color sequences in say().  (And everything else
  by extension.)
* Added whitespace handling for answers.  Can be set to <tt>:strip</tt>,
  <tt>:chomp</tt>, <tt>:collapse</tt>, <tt>:strip_and_collapse</tt>,
  <tt>:chomp_and_collapse</tt>, <tt>:remove</tt>, or <tt>:none</tt>.
* Exposed question details to ERb completion through @question, to allow for
  intelligent responses.
* Simplified HighLine internals using @question.
* Added support for fetching single character input either with getc() or
  HighLine's own cross-platform terminal input routine.
* Improved type conversion to handle user defined classes.

### 0.2.0 / 2005-04-29

* Added Unit Tests to cover an already fixed output bug in the future.
* Added Rakefile and setup test action (default).
* Renamed HighLine::Answer to HighLine::Question to better illustrate its role.
* Renamed fetch_line() to get_response() to better define its goal.
* Simplified explain_error in terms of the Question object.
* Renamed accept?() to in_range?() to better define purpose.
* Reworked valid?() into valid_answer?() to better fit Question object.
* Reworked <tt>@member</tt> into <tt>@in</tt>, to make it easier to remember and
  switched implementation to include?().
* Added range checks for @above and @below.
* Fixed the bug causing ask() to swallow NoMethodErrors.
* Rolled ask_on_error() into responses.
* Redirected imports to Kernel from Object.
* Added support for <tt>validate = lambda { ... }</tt>.
* Added default answer support.
* Fixed bug that caused ask() to die with an empty question.
* Added complete documentation.
* Improve the implemetation of agree() to be the intended "yes" or "no" only
  question.
* Added Rake tasks for documentation and packaging.
* Moved project to RubyForge.

### 0.1.0

* Initial release as the solution to
  {Ruby Quiz #29}[http://www.rubyquiz.com/quiz29.html].
