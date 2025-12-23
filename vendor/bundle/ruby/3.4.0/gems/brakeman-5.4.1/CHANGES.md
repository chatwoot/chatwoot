# 5.4.1 - 2023-02-21

* Fix file/line location for EOL software warnings
* Revise checking for request.env to only consider request headers
* Add `redirect_back` and `redirect_back_or_to` to open redirect check
* Support Rails 7 redirect options
* Add Rails 6.1 and 7.0 default configuration values
* Prevent redirects using `url_from` being marked as unsafe (Lachlan Sylvester)
* Warn about unscoped find for `find_by(id: ...)`
* Support `presence`, `presence_in` and `in?`
* Fix issue with `if` expressions in `when` clauses

# 5.4.0 - 2022-11-17

* Use relative paths for CodeClimate report format (Mike Poage)
* Add check for weak RSA key sizes and padding modes
* Handle multiple values and splats in case/when
* Ignore more model methods in redirects
* Add check for absolute paths issue with Pathname
* Fix `load_rails_defaults` overwriting settings in the Rails application (James Gregory-Monk)

# 5.3.1 - 2022-08-09

* Fix version range for CVE-2022-32209

# 5.3.0 - 2022-08-09

* Include explicit engine or lib paths in vendor/ (Joe Rafaniello)
* Load rexml as a Brakeman dependency
* Fix "full call" information propagating unnecessarily
* Add check for CVE-2022-32209
* Add CWE information to warnings (Stephen Aghaulor)

# 5.2.3 - 2022-05-01

* Fix error with hash shorthand syntax
* Match order of interactive options with help message (Rory O'Kane)

# 5.2.2 - 2022-04-06

* Update `ruby_parser` for Ruby 3.1 support (Merek Skubela)
* Handle `nil` when joining values (Dan Buettner)
* Update message for unsafe reflection (Pedro Baracho)
* Add additional String methods for SQL injection check
* Respect equality in `if` conditions

# 5.2.1 - 2022-01-30

* Add warning codes for EOL software warnings

# 5.2.0 - 2021-12-15

* Initial Rails 7 support
* Require Ruby 2.5.0+
* Fix issue with calls to `foo.root` in routes
* Ignore `I18n.locale` in SQL queries
* Do not treat `sanitize_sql_like` as safe
* Add new checks for unsupported Ruby and Rails versions

# 5.1.2 - 2021-10-28

* Handle cases where enums are not symbols
* Support newer Haml with ::Haml::AttributeBuilder.build
* Fix issue where the previous output is still visible (Jason Frey)
* Fix warning sorting with nil line numbers
* Update for latest RubyParser (Ryan Davis)

# 5.1.1 - 2021-07-19

* Unrefactor IgnoreConfig's use of `Brakeman::FilePath`

# 5.1.0 - 2021-07-19

* Initial support for ActiveRecord enums
* Support `Hash#include?`
* Interprocedural dataflow from very simple class methods
* Fix SARIF report when checks have no description (Eli Block)
* Add ignored warnings to SARIF report (Eli Block)
* Add `--sql-safe-methods` option (Esty Scheiner)
* Update SQL injection check for Rails 6.0/6.1
* Fix false positive in command injection with `Open3.capture` (Richard Fitzgerald)
* Fix infinite loop on mixin self-includes (Andrew Szczepanski)
* Ignore dates in SQL
* Refactor `cookie?`/`param?` methods (Keenan Brock)
* Ignore renderables in dynamic render path check (Brad Parker)
* Support `Array#push`
* Better `Array#join` support
* Adjust copy of `--interactive` menu (Elia Schito)
* Support `Array#*`
* Better method definition tracking and lookup
* Support `Hash#values` and `Hash#values_at`
* Check for user-controlled evaluation even if it's a call target
* Support `Array#fetch` and `Hash#fetch`
* Ignore `sanitize_sql_like` in SQL
* Ignore method calls on numbers in SQL
* Add GitHub Actions format (Klaus Badelt)
* Read and parse files in parallel

# 5.0.4 - 2021-06-08

(brakeman gem release only)

* Update bundled `ruby_parser` to include argument forwarding support

# 5.0.2 - 2021-06-07

* Fix Loofah version check

# 5.0.1 - 2021-04-27

* Detect `::Rails.application.configure` too
* Set more line numbers on Sexps
* Support loading `slim/smart`
* Don't fail if $HOME/$USER are not defined
* Always ignore slice/only calls for mass assignment
* Convert splat array arguments to arguments

# 5.0.0 - 2021-01-26

* Ignore `uuid` as a safe attribute
* Collapse `__send__` calls
* Ignore `Tempfile#path` in shell commands
* Ignore development environment
* Revamp CSV report to a CSV list of warnings
* Set Rails configuration defaults based on `load_defaults` version
* Add check for (more) unsafe method reflection
* Suggest using `--force` if no Rails application is detected
* Add Sonarqube report format (Adam England)
* Add check for potential HTTP verb confusion
* Add `--[no-]skip-vendor` option
* Scan (almost) all Ruby files in project

# 4.10.1 - 2020-12-24

* Declare REXML as a dependency (Ruby 3.0 compatibility)
* Use `Sexp#sexp_body` instead of `Sexp#[..]` (Ruby 3.0 compatibility)
* Prevent render loops when template names are absolute paths
* Ensure RubyParser is passed file path as a String
* Support new Haml 5.2.0 escaping method

# 5.0.0.pre1 - 2020-11-17

* Add check for (more) unsafe method reflection
* Suggest using `--force` if no Rails application is detected
* Add Sonarqube report format (Adam England)
* Add check for potential HTTP verb confusion
* Add `--[no-]skip-vendor` option
* Scan (almost) all Ruby files in project
* Add support for Haml 5.2.0

# 4.10.0 - 2020-09-28

* Add SARIF report format (Steve Winton)

# 4.9.1 - 2020-09-04

* Check `chomp`ed strings for SQL injection
* Use version from `active_record` for non-Rails apps (Ulysse Buonomo)
* Always set line number for joined arrays
* Avoid warning about missing `attr_accessible` if `protected_attributes` gem is used

# 4.9.0 - 2020-08-04

* Add check for CVE-2020-8166 (Jamie Finnigan)
* Avoid warning when `safe_yaml` is used via `YAML.load(..., safe: true)`
* Add check for user input in `ERB.new` (Matt Hickman)
* Add `--ensure-ignore-notes` (Eli Block)
* Remove whitelist/blacklist language, add clarifications
* Do not warn about mass assignment with `params.permit!.slice`
* Add "full call" information to call index results
* Ignore `params.permit!` in path helpers
* Treat `Dir.glob` as safe source of values in guards
* Always scan `environment.rb`

# 4.8.2 - 2020-05-12

* Add check for CVE-2020-8159
* Fix `authenticate_or_request_with_http_basic` check for passed blocks (Hugo Corbucci)
* Add `--text-fields` option
* Add check for escaping HTML entities in JSON configuration

# 4.8.1 - 2020-04-06

* Check SQL query strings using `String#strip` or `String.squish`
* Handle non-symbol keys in locals hash for render()
* Warn about global(!) mass assignment
* Index calls in render arguments

# 4.8.0 - 2020-02-18 

* Add JUnit-XML report format (Naoki Kimura)
* Sort ignore files by fingerprint and line (Ngan Pham)
* Freeze call index results
* Fix output test when using newer Minitest
* Properly render confidence in Markdown report
* Report old warnings as fixed if zero warnings reported
* Catch dangerous concatenation in `CheckExecute` (Jacob Evelyn)
* Show user-friendly message when ignore config file has invalid JSON (D. Hicks)
* Initialize Rails version with `nil` (Carsten Wirth)

# 4.7.2 - 2019-11-25

* Remove version guard for `named_scope` vs. `scope`
* Find SQL injection in `String#strip_heredoc` target
* Handle more `permit!` cases
* Ensure file name is set when processing model
* Add `request.params` as query parameters

# 4.7.1 - 2019-10-29 

* Check string length against limit before joining
* Fix errors from frozen `Symbol#to_s` in Ruby 2.7
* Fix flaky rails4 test (Adam Kiczula)
* Added release dates to each version in CHANGES (TheSpartan1980)
* Catch reverse tabnabbing with `:_blank` symbol (Jacob Evelyn)
* Convert `s(:lambda)` to `s(:call)` in `Sexp#block_call`
* Sort text report by file and line (Jacob Evelyn)

# 4.7.0 - 2019-10-16

* Refactor `Brakeman::Differ#second_pass` (Benoit Côté-Jodoin)
* Ignore interpolation in `%W[]`
* Fix `version_between?` (Andrey Glushkov)
* Add support for `ruby_parser` 3.14.0
* Ignore `form_for` for XSS check
* Update Haml support to Haml 5.x
* Catch shell injection from `-c` shell commands (Jacob Evelyn)
* Correctly handle non-symbols in `CheckCookieSerialization` (Phil Turnbull)

# 4.6.1 - 2019-07-24

* Fix Reverse Tabnabbing warning message (Steffen Schildknecht / Jörg Schiller)

# 4.6.0 - 2019-07-23

* Skip calls to `dup`
* Add reverse tabnabbing check (Linos Giannopoulos)
* Better handling of gems with no version declared
* Warn people that Haml 5 is not fully supported (Jared Beck)
* Avoid warning about file access with `ActiveStorage::Filename#sanitized` (Tejas Bubane)
* Update loofah version for fixing CVE-2018-8048 (Markus Nölle)
* Restore `Warning#relative_path`
* Add check for cookie serialization with Marshal
* Index calls in initializers
* Improve template output handling in conditional branches
* Avoid assigning `nil` line numbers to `Sexp`s
* Add special warning code for custom checks
* Add call matching by regular expression

# 4.5.1 - 2019-05-11

* Add `Brakeman::FilePath` to represent file paths
* Handle trailing comma in block args
* Properly handle empty partial name
* Use relative paths for `__FILE__`
* Convert `!!` calls to boolean value
* Add optional check for `config.force_ssl`
* Remove code for Ruby versions prior to 1.9
* Check `link_to` with block for href XSS
* Add SQL injection checks for `find_or_create_by` and friends
* Add deserialization warning for `Oj.load/object_load`
* Add initial Rails 6 support
* Add SQL injection checks for `destroy_by`/`delete_by`

# 4.5.0 - 2019-03-16

* Update `ruby_parser`, use `ruby_parser-legacy`
* More thoroughly handle `Shellwords` escaping
* Handle non-integer version number comparisons
* Use `FileParser` in `Scanner` to parse files
* Add original exception to `Tracker#errors` list
* Add support for CoffeeScript in Slim templates
* Improve support for embedded template "filters"
* Remove Sass dependency
* Set location information in `CheckContentTag`
* Stop swallowing exceptions in `AliasProcessor`
* Avoid joining strings with different encodings
* Handle `**` inside Hash literals
* Better handling of splat/kwsplat arguments
* Improve "user input" reported for SQL injection

# 4.4.0 - 2019-01-17

* Set default encoding to UTF-8
* Update to Slim 4.0.1 (Jake Peterson)
* Update to RubyParser 3.12.0
* Add rendered template information to render paths
* Fix trim mode for ERb templates in old Rails versions
* Fix thread-safety issue in CallIndex
* Add `--enable` option to enable optional checks
* Support reading gem versions from gemspecs
* Support gem versions which are just major.minor (e.g. 3.0)
* Treat `if not` like `unless`
* Handle empty `secrets.yml` files (Naoki Kimura)
* Correctly set `rel="noreferrer"` in HTML reports
* Avoid warning about command injection when `String#shellescape` and `Shellwords.shelljoin` are used (George Ogata)
* Add Dockerfile to run Brakeman inside Docker (Ryan Kemper)
* Trim some unnecessary files from bundled gems
* Add check for CVE-2018-3760
* Avoid nils when concatenating arrays
* Ignore Tempfiles in FileAccess warnings (Christina Koller)
* Complete overhaul of warning message construction
* Deadcode and typo fixes found via Coverity

# 4.3.1 - 2018-06-07

* Ignore `Object#freeze`, use the target instead
* Ignore `foreign_key` calls in SQL
* Handle `included` calls outside of classes/modules
* Add `:BRAKEMAN_SAFE_LITERAL` to represent known-safe literals
* Handle `Array#map` and `Array#each` over literal arrays
* Use safe literal when accessing literal hash with unknown key
* Avoid deprecated use of ERB in Ruby 2.6 (Koichi ITO)
* Allow `symbolize_keys` to be called on `params` in SQL (Jacob Evelyn)
* Improve handling of conditionals in shell commands (Jacob Evelyn)
* Fix error when setting line number in implicit renders

# 4.3.0 - 2018-05-11

* Check exec-type calls even if they are targets
* Convert `Array#join` to string interpolation
* `BaseCheck#include_interp?` should return first string interpolation
* Add `--parser-timeout` option
* Track parent calls in CallIndex
* Warn about dangerous `link_to` href with `sanitize()`
* Ignore `params#to_h` and `params#to_hash` in SQL checks
* Change "".freeze to just ""
* Ignore `Process.pid` in system calls
* Index Kernel#\` calls even if they are targets
* Code Climate: omit leading dot from `only_files` (Todd Mazierski)
* `--color` can be used to force color output
* Fix reported line numbers for CVE-2018-3741 and CVE-2018-8048

# 4.2.1 - 2018-03-24

* Add warning for CVE-2018-3741
* Add warning for CVE-2018-8048
* Scan `app/jobs/` directory
* Handle `template_exists?` in controllers

# 4.2.0 - 2018-02-22

* Avoid warning about symbol DoS on `Model#attributes`
* Avoid warning about open redirects with model methods ending with `_path`
* Avoid warning about command injection with `Shellwords.escape`
* Use ivars from `initialize` in libraries
* `Sexp#body=` can accept `:rlist` from `Sexp#body_list`
* Update RubyParser to 3.11.0
* Fix multiple assignment of globals
* Warn about SQL injection in `not`
* Exclude template folders in `lib/` (kru0096)
* Handle ERb use of `String#<<` method for Ruby 2.5 (Pocke)

# 4.1.1 - 2017-12-19

* Remove check for use of `permit` with `*_id` keys
* Avoid duplicate warnings about permitted attributes

# 4.1.0 - 2017-12-14

* Process models as root sexp instead of each sexp
* Avoid CSRF warning in Rails 5.2 default config
* Show better location for Sass errors (Andrew Bromwich)
* Warn about dynamic values in `Arel.sql`
* Fix `include_paths` for Code Climate engine (Will Fleming)
* Add check for dangerous keys in `permit`
* Try to guess options for `less` pager
* Better processing of op_asgn1 (e.g. x[:y] += 1)
* Add optional check for divide by zero
* Remove errors about divide by zero
* Avoid warning about file access for temp files
* Do not warn on params.permit with safe values
* Add Sexp#call_chain
* Use HTTPS for warning links
* Handle nested destructuring/multiple assignment
* Leave results on screen after paging
* Do not page if results fit on screen
* Support `app_path` configuration for Code Climate engine (Noah Davis)
* Refactor Code Climate engine options parsing (Noah Davis)
* Fix upgrade version for CVE-2016-6316

# 4.0.1 - 2017-09-25

* Disable pager when `CI` environment variable is set
* Fix output when pager fails

# 4.0.0 - 2017-09-25

* Add simple pager for reports output to terminal
* Rename "Cross Site Scripting" to "Cross-Site Scripting" (Paul Tetreau)
* Rearrange tests a little bit
* Treat `request.cookies` like `cookies`
* Treat `fail`/`raise` like early returns
* Remove reliance on `CONFIDENCE` constant in checks
* Remove low confidence mass assignment warnings
* Reduce warnings about XSS in `link_to`
* "Plain" report output is now the default
* --exit-on-error and --exit-on-warn are now the default
* Fix --exit-on-error and --exit-on-warn in config files

# 3.7.2 - 2017-08-16

* Fix --ensure-latest (David Guyon)

# 3.7.1 - 2017-08-16

* Handle simple guard with return at end of branch
* Modularize bin/brakeman
* Improve multi-value Sexp error message
* Add more collection methods for iteration detection
* Update ruby2ruby and ruby_parser

# 3.7.0 - 2017-06-30

* Improve support for rails4/rails5 options in config file
* Track more information about constant assignments
* Show progress indicator in interactive mode
* Handle simple conditional guards that use `return`
* Fix false positive for redirect_to in Rails 4 (Mário Areias)
* Avoid interpolating hashes/arrays on failed access

# 3.6.2 - 2017-05-19

* Handle safe call operator in checks
* Better handling of `if` expressions in HAML rendering
* Remove `--rake` option
* Properly handle template names without `.html` or `.js`
* Set template file names during rendering for better errors
* Limit Slim dependency to before 3.0.8
* Catch YAML parsing errors in session settings check
* Avoid warning about SQLi with `to_s` in `exists?`
* Update RubyParser to 3.9.0
* Do not honor additional check paths in config by default
* Handle empty `if` expressions when finding return values
* Fix finding return value from empty `if`

# 3.6.1 - 2017-03-24

* Fix error when using `--compare` (Sean Gransee)

# 3.6.0 - 2017-03-23

* Avoid recursive Concerns
* Branch inside of `case` expressions
* Print command line option errors without modification
* Fix issue with nested interpolation inside SQL strings
* Ignore GraphQL tags inside ERB templates
* Add `--exit-on-error` (Michael Grosser)
* Only report CVE-2015-3227 when exact version is known
* Check targetless SQL calls outside of known models

# 3.5.0 - 2017-02-01

* Allow `-t None`
* Fail on invalid checks specified by `-x` or `-t`
* Avoid warning about all, first, or last after Rails 4.0
* Avoid warning about models in SQLi
* Lower confidence of SQLi when maybe not on models
* Warn about SQLi even potentially on non-models
* Report check name in JSON and plain reports
* Treat templates without `.html` as HTML anyway
* Add `--ensure-latest` option (tamgrosser / Michael Grosser)
* Add `--no-summary` to hide summaries in HTML/text reports
* Handle `included` block in concerns
* Process concerns before controllers

# 3.4.1 - 2016-11-02

* Show action help at start of interactive ignore
* Check CSRF setting in direct subclasses of `ActionController::Base` (Jason Yeo)
* Configurable engines path (Jason Yeo)
* Use Ruby version to turn off SymbolDoS check
* Pull Ruby version from `.ruby-version` or Gemfile
* Avoid warning about `where_values_hash` in SQLi
* Fix ignoring link interpolation not at beginning of string

# 3.4.0 - 2016-09-08

* Add new `plain` report format
* Add option to prune ignore file with `-I`
* Improved Slim template support
* Show obsolete ignore entries in reports (Jonathan Cheatham)
* Support creating reports in non-existent paths
* Add `--no-exit-warn`

# 3.3.5 - 2016-08-12

* Fix bug in reports when using --debug option

# 3.3.4 - 2016-08-12

* Add generic warning for CVE-2016-6316
* Warn about dangerous use of `content_tag` with CVE-2016-6316
* Add warning for CVE-2016-6317
* Use Minitest

# 3.3.3 - 2016-07-21

* Show path when no Rails app found (Neil Matatall)
* Index calls in view helpers
* Process inline template renders
* Avoid warning about hashes in link_to hrefs
* Add documentation for authentication category
* Ignore boolean methods in render paths
* Reduce open redirect duplicates
* Fix SymbolDoS error with unknown Rails version
* Sexp#value returns nil when there is no value
* Improve return value estimation

# 3.3.2 - 2016-06-10

* Fix serious performance regression with global constant tracking

# 3.3.1 - 2016-06-03

* Delay loading vendored gems and modifying load path
* Avoid warning about SQL injection with `quoted_primary_key`
* Support more safe `&.` operations
* Allow multiple line regex in `validates_format_of` (Dmitrij Fedorenko)
* Only consider `if` branches in templates
* Avoid overwriting instance/class methods with same name (Tim Wade)
* Add `--force-scan` option (Neil Matatall)
* Improved line number accuracy in ERB templates (Patrick Toomey)

# 3.3.0 - 2016-05-05

* Skip processing obviously false if branches (more broadly)
* Skip if branches with `Rails.env.test?`
* Return exit code `4` if no Rails application is detected
* Avoid warning about mass assignment with `params.slice`
* Avoid warning about `u` helper (Chad Dollins)
* Add optional check for secrets in source code
* Process `Array#first`
* Allow non-Hash arguments in `protect_from_forgery` (Jason Yeo)
* Avoid warning on `popen` with array
* Bundle all dependencies in gem
* Track constants globally
* Handle HAML `find_and_preserve` with a block
* [Code Climate engine] When possible, output to /dev/stdout (Gordon Diggs)
* [Code Climate engine] Remove nil entries from include_paths (Gordon Diggs)
* [Code Climate engine] Report end lines for issues (Gordon Diggs)

# 3.2.1 - 2016-02-25

* Remove `multi_json` dependency from `bin/brakeman`

# 3.2.0 - 2016-02-25

* Skip Symbol DoS check on Rails 5
* Only update ignore config file on changes
* Sort ignore config file
* Support calls using `&.` operator
* Update ruby_parser dependency to 3.8.1
* Remove `fastercsv` dependency
* Fix finding calls with `targets: nil`
* Remove `multi_json` dependency
* Handle CoffeeScript in HAML
* Avoid render warnings about params[:action]/params[:controller]
* Index calls in class bodies but outside methods

# 3.1.5 - 2016-01-28

* Fix CodeClimate construction of --only-files (Will Fleming)
* Add check for denial of service via routes (CVE-2015-7581)
* Warn about RCE with `render params` (CVE-2016-0752)
* Add check for `strip_tags` XSS (CVE-2015-7579)
* Add check for `sanitize` XSS (CVE-2015-7578/80)
* Add check for `reject_if` proc bypass (CVE-2015-7577)
* Add check for mime-type denial of service (CVE-2016-0751)
* Add check for basic auth timing attack (CVE-2015-7576)
* Add initial Rails 5 support
* Check for implicit integer comparison in dynamic finders
* Support directories better in --only-files and --skip-files (Patrick Toomey)
* Avoid warning about `permit` in SQL
* Handle guards using `detect`
* Avoid warning on user input in comparisons
* Handle module names with self methods
* Add session manipulation documentation

# 3.1.4 - 2015-12-22

* Emit brakeman's native fingerprints for Code Climate engine (Noah Davis)
* Ignore secrets.yml if in .gitignore
* Clean up Ruby warnings (Andy Waite)
* Increase test coverage for option parsing (Zander Mackie)
* Work around safe_yaml error

# 3.1.3 - 2015-12-03

* Check for session secret in secrets.yml
* Respect `exit_on_warn` in config file
* Avoid warning on `without_protection: true` with hash literals
* Make sure before_filter call with block is still a call
* CallIndex improvements
* Restore minimum Highline version (Kevin Glowacz)
* Add Code Climate output format (Ashley Baldwin-Hunter/Devon Blandin/John Pignata/Michael Bernstein)
* Iteratively replace values
* Output nil instead of false for user_input in JSON
* Depend on safe_yaml 1.0 or later
* Test coverage improvements for Brakema module (Bethany Rentz)

# 3.1.2 - 2015-10-28

* Treat `current_user` like a model
* Set user input value for inline renders
* Avoid warning on inline renders with safe content types
* Handle empty interpolation in HAML filters
* Ignore filters that are not method names
* Avoid warning about model find/find_by* in hrefs
* Use SafeYAML to load configuration files
* Warn on SQL query keys, not values in hashes
* Allow inspection of recursive Sexps
* Add line numbers to class-level warnings
* Handle `private def ...`
* Catch divide-by-zero in alias processing
* Reduce string allocations in Warning#initialize
* Sortable tables in HTML report (David Lanner)
* Search for config file relative to application root

# 3.1.1 - 2015-09-23

* Add optional check for use of MD5 and SHA1
* Avoid warning when linking to decorated models
* Add check for user input in session keys
* Fix chained assignment
* Treat a.try(&:b) like a.b()
* Consider j/escape_javascript safe inside HAML JavaScript blocks
* Better HAML processing of find_and_preserve calls
* Add more Arel methods to be ignored in SQL
* Fix absolute paths for Windows (Cody Frederick)
* Support newer terminal-table releases
* Allow searching call index methods by regex (Alex Ianus)

# 3.1.0 - 2015-08-31

* Add support for gems.rb/gems.locked
* Update render path information in JSON reports
* Remove renaming of several Sexp nodes
* Convert YAML config keys to symbols (Karl Glaser)
* Use railties version if rails gem is missing (Lucas Mazza)
* Warn about unverified SSL mode in Net::HTTP.start
* Add Model, Controller, Template, Config classes internally
* Report file being parsed in debug output
* Update dependencies to Ruby 1.8 incompatible versions
* Treat Array.new and Hash.new as arrays/hashes
* Fix handling of string concatenation with existing string
* Treat html_safe like raw()
* Fix low confidence XSS warning code
* Avoid warning on path creation methods in link_to
* Expand safe methods to match methods with targets
* Avoid duplicate eval() warnings

# 3.0.5 - 2015-06-20

* Fix check for CVE-2015-3227

# 3.0.4 - 2015-06-18

* Add check for CVE-2015-3226 (XSS via JSON keys)
* Add check for CVE-2015-3227 (XML DoS)
* Treat `<%==` as unescaped output
* Update `ruby_parser` dependency to 3.7.0

# 3.0.3 - 2015-04-20

* Ignore more Arel methods in SQL
* Warn about protect_from_forgery without exceptions (Neil Matatall)
* Handle lambdas as filters
* Ignore quoted_table_name in SQL (Gabriel Sobrinho)
* Warn about RCE and file access with `open`
* Handle array include? guard conditionals
* Do not ignore targets of `to_s` in SQL
* Add Rake task to exit with error code on warnings (masarakki)

# 3.0.2 - 2015-03-09

* Alias process methods called in class scope on models
* Treat primary_key, table_name_prefix, table_name_suffix as safe in SQL
* Fix using --compare and --add-checks-path together
* Avoid warning about mass assignment with string literals
* Only report original regex DoS locations
* Improve render path information implementation
* Report correct file for simple_format usage CVE warning
* Remove URI.escape from HTML reports with GitHub repos
* Update ruby_parser to ~> 3.6.2
* Remove formatting newlines in HAML template output
* Ignore case value in XSS checks
* Fix CSV output when there are no warnings
* Handle processing of explicitly shadowed block arguments

# 3.0.1 - 2015-01-23

* Avoid protect_from_forgery warning unless ApplicationController inherits from ActionController::Base
* Properly format command interpolation (again)
* Remove Slim dependency (Casey West)
* Allow for controllers/models/templates in directories under `app/` (Neal Harris)
* Add `--add-libs-path` for additional libraries (Patrick Toomey)
* Properly process libraries (Patrick Toomey)

# 3.0.0 - 2015-01-03

* Add check for CVE-2014-7829
* Add check for cross-site scripting via inline renders
* Fix formatting of command interpolation
* Local variables are no longer formatted as `(local var)`
* Actually skip skipped before filters
* `--exit-on-warn --compare` only returns error code on new warnings (Jeff Yip)
* Fix parsing of `<%==` in ERB
* Sort warnings by fingerprint in JSON report (Jeff Yip)
* Handle symmetric multiple assignment
* Do not branch for self attribute assignment `x = x.y`
* Fix CVE for CVE-2011-2932
* Remove "fake filters" from warning fingerpints
* Index calls in `lib/` files
* Move Symbol DoS to optional checks
* CVEs report correct line and file name (Gemfile/Gemfile.lock) (Rob Fletcher)
* Change `--separate-models` to be the default

# 2.6.3 - 2014-10-14

* Whitelist `exists` arel method from SQL injection check
* Avoid warning about Symbol DoS on safe parameters as method targets
* Fix stack overflow in ProcessHelper#class_name
* Add optional check for unscoped find queries (Ben Toews)
* Add framework for optional checks
* Fix stack overflow for cycles in class ancestors (Jeff Rafter)

# 2.6.2 - 2014-08-18

* Add check for CVE-2014-3415
* Avoid warning about symbolizing safe parameters
* Update ruby2ruby dependency to 2.1.1
* Expand app path in one place instead of all over (Jeff Rafter)
* Add `--add-checks-path` option for external checks (Clint Gibler)
* Fix SQL injection detection in deep nested string building
* Add `-4` option to force Rails 4 mode
* Check entire call for `send`
* Check for .gitignore of secrets in subdirectories
* Fix block statement endings in Erubis
* Fix undefined variable in controller processing error (Jason Barnabe) 

# 2.6.1 - 2014-07-02

* Add check for CVE-2014-3482 and CVE-2014-3483
* Add support for keyword arguments in blocks
* Remove unused warning codes (Bill Fischer)

# 2.6.0 - 2014-06-06

* Fix detection of `:host` setting in redirects with chained calls
* Add check for CVE-2014-0130
* Add `find_by`/`find_by!` to SQLi check for Rails 4
* Parse most files upfront instead of on demand
* Do not branch values for `+=`
* Update to use RubyParser 3.5.0 (Patrick Toomey)
* Improve default route detection in Rails 3/4 (Jeff Jarmoc)
* Handle controllers and models split across files (Patrick Toomey)
* Fix handling of `protected_attributes` gem in Rails 4 (Geoffrey Hichborn)
* Ignore more model methods in redirects
* Fix CheckRender with nested render calls

# 2.5.0 - 2014-04-30

 * Add support for RailsLTS 2.3.18.7 and 2.3.18.8
 * Add support for Rails 4 `before_actions` and friends
 * Move SQLi CVE checks to `CheckSQLCVEs`
 * Check for protected_attributes gem
 * Fix SQLi detection in chain calls in scopes
 * Add GitHub-flavored Markdown output format (Greg Ose)
 * Fix false positives when sanitize() is used in SQL (Jeff Yip)
 * Add String#intern and Hash#symbolize_keys DoS check (Jan Rusnacko)
 * Check all arguments in Model.select for SQLi
 * Fix false positive when :host is specified in redirect
 * Handle more non-literals in routes
 * Add check for regex denial of service (Ben Toews) 

# 2.4.3 - 2014-03-23

 No changes. 2.4.2 gem release was unsigned, 2.4.3 is signed.

# 2.4.2 - 2014-03-21

 * Remove `rescue Exception`
 * Fix duplicate warnings about sanitize CVE
 * Reuse duplicate call location information
 * Only track original template output locations
 * Skip identically rendered templates
 * Fix HAML template processing

# 2.4.1 - 2014-02-19

 * Add check for CVE-2014-0082
 * Add check for CVE-2014-0081, replaces CVE-2013-6415
 * Add check for CVE-2014-0080

# 2.4.0 - 2014-02-05

 * Detect Rails LTS versions
 * Reduce false positives for SQL injection in string building
 * More accurate user input marking for SQL injection warnings
 * Detect SQL injection in `delete_all`/`destroy_all`
 * Detect SQL injection raw SQL queries using `connection`
 * Parse exact versions from Gemfile.lock for all gems
 * Ignore generators
 * Update to RubyParser 3.4.0
 * Fix false positives when SQL methods are not called on AR models (Aaron Bedra)
 * Add check for uses of OpenSSL::SSL::VERIFY_NONE (Aaron Bedra)
 * No longer raise exceptions if a class name cannot be determined
 * Fingerprint attribute warnings individually (Case Taintor)

# 2.3.1 - 2013-12-13

 * Fix check for CVE-2013-4491 (i18n XSS) to detect workaround
 * Fix link for CVE-2013-6415 (number_to_currency)

# 2.3.0 - 2013-12-12

 * Add check for Parameters#permit!
 * Add check for CVE-2013-4491 (i18n XSS)
 * Add check for CVE-2013-6414 (header DoS)
 * Add check for CVE-2013-6415 (number_to_currency)
 * Add check for CVE-2013-6416 (simple_format XSS)
 * Add check for CVE-2013-6417 (query generation) 
 * Fix typos in reflection and translate bug messages
 * Collapse send/try calls 
 * Fix Slim XSS false positives (Noah Davis)
 * Whitelist `Model#create` for redirects
 * Fix scoping issues with instance variables and blocks

# 2.2.0 - 2013-10-28

 * Reduce command injection false positives
 * Use Rails version from Gemfile if it is available
 * Only add routes with actual names
 * Ignore redirects to models using friendly_id (AJ Ostrow) 
 * Support scanning Rails engines (Geoffrey Hichborn)
 * Add check for detailed exceptions in production

# 2.1.2 - 2013-09-18

 * Do not attempt to load custom Haml filters
 * Do not warn about `to_json` XSS in Rails 4
 * Add --table-width option to set width of text reports (ssendev)
 * Remove fuzzy matching on dangerous attr_accessible values

# 2.1.1 - 2013-08-21

 * New warning code for dangerous attributes in attr_accessible
 * Do not warn on attr_accessible using roles
 * More accurate results for model attribute warnings
 * Use exit code zero with `-z` if all warnings ignored
 * Respect ignored warnings in rescans
 * Ignore dynamic controller names in routes
 * Fix infinite loop when run as rake task (Matthew Shanley)
 * Respect ignored warnings in tabs format reports

# 2.1.0 - 2013-07-17

 * Support non-native line endings in Gemfile.lock (Paul Deardorff)
 * Support for ignoring warnings
 * Check for dangerous model attributes defined in attr_accessible (Paul Deardorff)
 * Update to ruby_parser 3.2.2
 * Add brakeman-min gemspec
 * Load gem dependencies on-demand 
 * Output JSON diff to file if -o option is used 
 * Add check for authenticate_or_request_with_http_basic
 * Refactor of SQL injection check code (Bart ten Brinke)
 * Fix detection of duplicate XSS warnings
 * Refactor reports into separate classes 
 * Allow use of Slim 2.x (Ian Zabel) 
 * Return error exit code when application path is not found
 * Add `--branch-limit` option, limit to 5 by default
 * Add more methods to check for command injection
 * Fix output format detection to be more strict again
 * Allow empty Brakeman configuration file

# 2.0.0 - 2013-05-20
  
 * Add `--only-files` option to specify files/paths to scan (Ian Ehlert)
 * Add Marshal/CSV deserialization check
 * Combine deserialization checks into single check
 * Avoid duplicate "Dangerous Send" and "Unsafe Reflection" warnings
 * Avoid duplicate results for Symbol DoS check
 * Medium confidence for mass assignment to attr_protected models
 * Remove "timestamp" key from JSON reports
 * Remove deprecated config file locations
 * Relative paths are used by default in JSON reports
 * `--absolute-paths` replaces `--relative-paths`
 * Only treat classes with names containing `Controller` like controllers
 * Better handling of classes nested inside controllers
 * Better handling of controller classes nested in classes/modules
 * Handle `->` lambdas with no arguments
 * Handle explicit block argument destructuring
 * Skip Rails config options that are real objects
 * Detect Rails 3 JSON escape config option
 * Much better tracking of warning file names
 * Fix errors when using `--separate-models` (Noah Davis)
 * Fix fingerprint generation to actually use the file path
 * Fix text report console output in JRuby
 * Fix false positives on `Model#id`
 * Fix false positives on `params.to_json`
 * Fix model path guesses to use "models/" instead of "controllers/"
 * Clean up SQL CVE warning messages
 * Use exceptions instead of abort in brakeman lib
 * Update to Ruby2Ruby 2.0.5

# 1.9.5 - 2013-04-05

 * Add check for unsafe symbol creation
 * Do not warn on mass assignment with `slice`/`only`
 * Do not warn on session secret if in `.gitignore`
 * Fix scoping for blocks and block arguments
 * Fix error when modifying blocks in templates
 * Fix session secret check for Rails 4
 * Fix crash on `before_filter` outside controller
 * Fix `Sexp` hash cache invalidation
 * Respect `quiet` option in configuration file
 * Convert assignment to simple `if` expressions to `or`
 * More fixes for assignments inside branches
 * Pin to ruby2ruby version 2.0.3

# 1.9.4 - 2013-03-19
 
 * Add check for CVE-2013-1854
 * Add check for CVE-2013-1855
 * Add check for CVE-2013-1856
 * Add check for CVE-2013-1857
 * Fix `--compare` to work with older versions
 * Add "no-referrer' to HTML report links
 * Don't warn when invoking `send` on user input
 * Slightly faster cloning of Sexps
 * Detect another way to add `strong_parameters`

# 1.9.3 - 2013-03-01
 
 * Add render path to JSON report
 * Add warning fingerprints
 * Add check for unsafe reflection (Gabriel Quadros)
 * Add check for skipping authentication methods with blacklist
 * Add support for Slim templates
 * Remove empty tables from reports (Owen Ben Davies)
 * Handle `prepend/append_before_filter`
 * Performance improvements when handling branches
 * Fix processing of `production.rb`
 * Fix version check for Ruby 2.0
 * Expand HAML dependency to include 4.0
 * Scroll errors into view when expanding in HTML report

# 1.9.2 - 2013-02-14

 * Add check for CVE-2013-0269
 * Add check for CVE-2013-0276
 * Add check for CVE-2013-0277
 * Add check for CVE-2013-0333
 * Check for more send-like methods
 * Check for more SQL injection locations
 * Check for more dangerous YAML methods
 * Support MultiJSON 1.2 for Rails 3.0 and 3.1

# 1.9.1 - 2013-01-19

 * Update to RubyParser 3.1.1 (neersighted)
 * Remove ActiveSupport dependency (Neil Matatall)
 * Do not warn on arrays passed to `link_to` (Neil Matatall)
 * Warn on secret tokens
 * Warn on more mass assignment methods
 * Add check for CVE-2012-5664
 * Add check for CVE-2013-0155
 * Add check for CVE-2013-0156
 * Add check for unsafe `YAML.load`

# 1.9.0 - 2012-12-25

 * Update to RubyParser 3
 * Ignore route information by default
 * Support `strong_parameters`
 * Support newer `validates :format` call
 * Add scan time to reports
 * Add Brakeman version to reports
 * Fix `CheckExecute` to warn on all string interpolation
 * Fix false positive on `to_sql` calls
 * Don't mangle whitespace in JSON code formatting
 * Add AppTree as facade for filesystem (brynary)
 * Add link for translate vulnerability warning (grosser)
 * Rename LICENSE to MIT-LICENSE, remove from README (grosser)
 * Add Rakefile to run tests (grosser)
 * Better default config file locations (grosser)
 * Reduce Sexp creation
 * Handle empty model files
 * Remove "find by regex" feature from `CallIndex`

# 1.8.3 - 2012-11-13

 * Use `multi_json` gem for better harmony
 * Performance improvement for call indexing
 * Fix issue with processing HAML files
 * Handle pre-release versions when processing `Gemfile.lock`
 * Only check first argument of `redirect_to`
 * Fix false positives from `Model.arel_table` accesses
 * Fix false positives on redirects to models decorated with Draper gem
 * Fix false positive on redirect to model association
 * Fix false positive on `YAML.load`
 * Fix false positive XSS on any `to_i` output
 * Fix error on Rails 2 name routes with no args
 * Fix error in rescan of mixins with symbols in method name
 * Do not rescan non-Ruby files in config/

# 1.8.2 - 2012-10-17

 * Fixed rescanning problems caused by 1.8.0 changes
 * Fix scope calls with single argument
 * Report specific model name in rendered collections
 * Handle overwritten JSON escape settings
 * Much improved test coverage
 * Add CHANGES to gemspec

# 1.8.1 - 2012-09-24

 * Recover from errors in output formatting
 * Fix false positive in redirect_to (Neil Matatall)
 * Fix problems with removal of `Sexp#method_missing`
 * Fix array indexing in alias processing
 * Fix old mail_to vulnerability check
 * Fix rescans when only controller action changes
 * Allow comparison of versions with unequal lengths
 * Handle super calls with blocks
 * Respect `-q` flag for "Rails 3 detected" message

# 1.8.0 - 2012-09-05

 * Support relative paths in reports (fsword)
 * Allow Brakeman to be run without tty (fsword)
 * Fix exit code with `--compare` (fsword)
 * Fix `--rake` option (Deepak Kumar)
 * Add high confidence warnings for `to_json` XSS (Neil Matatall)
 * Fix `redirect_to` false negative
 * Fix duplicate warnings with `raw` calls
 * Fix shadowing of rendered partials
 * Add "render chain" to HTML reports
 * Add check for XSS in `content_tag`
 * Add full backtrace for errors in debug mode
 * Treat model attributes in `or` expressions as immediate values
 * Switch to method access for Sexp nodes

# 1.7.1 - 2012-08-13

 * Add check for CVE-2012-3463
 * Add check for CVE-2012-3464
 * Add check for CVE-2012-3465
 * Add charset to HTML report (hooopo)
 * Report XSS in select() for Rails 2

# 1.7.0 - 2012-07-31

 * Add check for CVE-2012-3424
 * Link report types to descriptions on website
 * Report errors raised while running check
 * Improve processing of Rails 3 routes
 * Fix "empty char-class" error
 * Improve file access check
 * Avoid warning on non-ActiveModel models
 * Speed improvements by stripping down SexpProcessor
 * Fix how `params[:x] ||=` is handled
 * Treat user input in `or` expressions as immediate values
 * Fix processing of negative array indexes
 * Add line breaks to truncated table rows

# 1.6.2 - 2012-06-13

 * Add checks for CVE-2012-2660, CVE-2012-2661, CVE-2012-2694, CVE-2012-2695 (Dave Worth)
 * Avoid warning when redirecting to a model instance
 * Add `request.parameters` as a parameters hash
 * Raise confidence level for model attributes in redirects
 * Return non-zero exit code when missing dependencies
 * Fix `before_filter :except` logic
 * Only accept symbol literals as before_filter names
 * Cache before_filter lookups
 * Turn off quiet mode by default for `--compare`

# 1.6.1 - 2012-05-23

 * Major rewrite of CheckSQL
 * Fix rescanning of deleted templates
 * Process actions mixed into controllers
 * Handle `render :template => ...`
 * Check for inherited attr_accessible (Neil Matatall)
 * Fix highlighting of HTML escaped values in HTML report
 * Report line number of highlighted value, if available

# 1.6.0 - 2012-04-20

 * Remove the Ruport dependency (Neil Matatall)
 * Add more informational JSON output (Neil Matatall)
 * Add comparison to previous JSON report (Neil Matatall)
 * Add highlighting of dangerous values in HTML/text reports
 * Model#update_attribute should not raise mass assignment warning (Dave Worth)
 * Don't check `find_by_*` method for SQL injection
 * Fix duplicate reporting of mass assignment and SQL injection
 * Fix rescanning of deleted files 
 * Properly check for rails_xss in Gemfile

# 1.5.3 - 2012-04-10

 * Add check for user input in Object#send (Neil Matatall)
 * Handle render :layout in views
 * Support output to multiple formats (Nick Green)
 * Prevent infinite loops in mutually recursive templates
 * Only check eval arguments for user input, not targets
 * Search subdirectories for models
 * Set values in request hashes and propagate to views
 * Add rake task file to gemspec (Anton Ageev)
 * Filter rescanning of templates (Neil Matatall)
 * Improve handling of modules and nesting
 * Test for zero errors in test reports

# 1.5.2 - 2012-03-22

 * Fix link_to checks for Rails 2.0 and 2.3
 * Fix rescanning of lib files (Neil Matatall)
 * Output stack trace on interrupt when debugging
 * Ignore user input in if statement conditions
 * Fix --skip-files option
 * Only warn on user input in render paths
 * Fix handling of views when using rails_xss
 * Revert to ruby_parser 2.3.1 for Ruby 1.8 parsing

# 1.5.1- 2012-03-06

 * Fix detection of global mass assignment setting
 * Fix partial rendering in Rails 3
 * Show backtrace when interrupt received (Ruby 1.9 only)
 * More debug output
 * Remove duplicate method in Brakeman::Rails2XSSErubis
 * Add tracking of module and class to Brakeman::BaseProcessor
 * Report module when using Brakeman::FindCall

# 1.5.0 - 2012-03-02

 * Add version check for SafeBuffer vulnerability
 * Add check for select vulnerability in Rails 3
 * select() is no longer considered safe in Rails 2
 * Add check for skipping CSRF protection with a blacklist
 * Add JSON report format
 * Model#id should not be considered XSS
 * Standardize methods to check for SQL injection
 * Fix Rails 2 route parsing issue with nested routes

# 1.4.0 - 2012-02-24

 * Add check for user input in link_to href parameter
 * Match ERB processing to rails_xss plugin when plugin used
 * Add Brakeman::Report#to_json, Brakeman::Warning#to_json
 * Warnings below minimum confidence are dropped completely
 * Brakeman.run always returns a Tracker

# 1.3.0 - 2012-02-09

 * Add file paths to HTML report
 * Add caching of filters
 * Add --skip-files option
 * Add support for attr_protected
 * Add detection of request.env as user input
 * Descriptions of checks in -k output
 * Improved processing of named scopes
 * Check for mass assignment in ActiveRecord::Associations::AssociationCollection#build
 * Better variable substitution
 * Table output option for rescan reports

# 1.2.2 - 2012-01-26

 * --no-progress works again
 * Make CheckLinkTo a separate check
 * Don't fail on unknown options to resource(s)
 * Handle empty resource(s) blocks
 * Add RescanReport#existing_warnings

## 1.2.1 - 2012-01-20

 * Remove link_to warning for Rails 3.x or when using rails_xss
 * Don't warn if first argument to link_to is escaped
 * Detect usage of attr_accessible with no arguments
 * Fix error when rendering a partial from a view but not through a controller
 * Fix some issues with rails_xss, CheckCrossSiteScripting, and CheckTranslateBug
 * Simplify Brakeman Rake task
 * Avoid modifying $VERBOSE
 * Add Brakeman::RescanReport#to_s
 * Add Brakeman::Warning#to_s

## 1.2.0 - 2012-01-14

 * Speed improvements for CheckExecute and CheckRender
 * Check named_scope() and scope() for SQL injection
 * Add --rake option to create rake task to run Brakeman
 * Add experimental support for rescanning a subset of files
 * Add --summary option to only output summary
 * Fix a problem with Rails 3 routes

## 1.1.0 - 2011-12-22

 * Relax required versions for dependencies
 * Performance improvements for source processing
 * Better progress reporting
 * Handle basic operators like << + - * /
 * Rescue more errors to prevent complete crashes
 * Compatibility with newer Haml versions
 * Fix some warnings

## 1.0.0 - 2011-12-08

 * Better handling of assignments inside ifs
 * Check more expressions for SQL injection
 * Use latest ruby_parser for better 1.9 syntax support
 * Better behavior for Brakeman as a library

## 1.0.0rc1 - 2011-12-06

 * Brakeman can now be used as a library
 * Faster call search
 * Add option to return error code if warnings are found (tw-ngreen)
 * Allow truncated messages to be expanded in HTML
 * Fix summary when using warning thresholds
 * Better support for Rails 3 routes
 * Reduce SQL injection duplicate warnings
 * Lower confidence on mass assignment with no user input
 * Ignore mass assignment using all literal arguments
 * Keep expanded context in view with HTML output

## 0.9.2 - 2011-11-22

 * Fix Rails 3 configuration parsing
 * Add t() helper to check for translate XSS bug

## 0.9.1 - 2011-11-18

 * Add warning for translator helper XSS vulnerability

## 0.9.0 - 2011-11-17

 * Process Rails 3 configuration files
 * Fix CSV output
 * Check for config.active_record.whitelist_attributes = true
 * Always produce a warning for without_protection => true

## 0.8.4 - 2011-11-04

 * Option for separate attr_accessible warnings
 * Option to set CSS file for HTML output
 * Add file names for version-specific warnings
 * Add line number for default routes in a controller
 * Fix hash_insert()
 * Remove use of Queue from threaded checks

## 0.8.3 - 2011-10-25
 
 * Respect -w flag in .tabs format (tw-ngreen)
 * Escape HTML output of error messages
 * Add --skip-libs option

## 0.8.2 - 2011-10-01

 * Run checks in parallel threads by default
 * Fix compatibility with ruby_parser 2.3.1

## 0.8.1 - 2011-09-28

 * Add option to assume all controller methods are actions
 * Recover from errors when parsing routes

## 0.8.0 - 2011-09-15

 * Add check for mass assignment using without_protection
 * Add check for password in http_basic_authenticate_with
 * Warn on user input in hash argument with mass assignment
 * auto_link is now considered safe for Rails >= 3.0.6
 * Output detected Rails version in report
 * Keep track of methods called in class definition
 * Add ruby_parser hack for Ruby 1.9 hash syntax
 * Add a few Rails 3.1 tests

## 0.7.2 - 2011-08-27

 * Fix handling of params and cookies with nested access
 * Add CVEs for checks added in 0.7.0

## 0.7.1 - 2011-08-18

 * Require BaseProcessor for GemProcessor

## 0.7.0 - 2011-08-17

 * Allow local variable as a class name
 * Add checks for vulnerabilities fixed in Rails 2.3.14 and 3.0.10
 * Check for default routes in Rails 3 apps
 * Look in Gemfile or Gemfile.lock for Rails version

## 0.6.1 - 2011-07-29

 * Fix XSS check for cookies as parameters in output
 * Don't bother calling super in CheckSessionSettings
 * Add escape_once as a safe method
 * Accept '\Z' or '\z' in model validations

## 0.6.0 - 2011-07-20

 * Tests are in place and fully functional
 * Hide errors by default in HTML output
 * Warn if routes.rb cannot be found
 * Narrow methods assumed to be file access
 * Increase confidence for methods known to not escape output
 * Fixes to output processing for Erubis
 * Fixes for Rails 3 XSS checks
 * Fixes to line numbers with Erubis
 * Fixes to escaped output scanning
 * Update CSRF CVE-2011-0447 message to be less assertive

## 0.5.2 - 2011-06-29

 * Output report file name when finished
 * Add initial tests for Rails 2.x
 * Fix ERB line numbers when using Ruby 1.9

## 0.5.1 - 2011-06-17

 * Fix issue with 'has_one' => in routes

## 0.5.0 - 2011-06-08

  * Add support for routes like get 'x/y', :to => 'ctrlr#whatever'
  * Allow empty blocks in Rails 3 routes
  * Check initializer for session settings
  * Add line numbers to session setting warnings
  * Add --checks option to list checks

## 0.4.1 - 2011-05-23
  
  * Fix reported line numbers when using new Erubis parser
    (Mostly affects Rails 3 apps)

## 0.4.0 - 2011-05-19

  * Handle Rails XSS protection properly
  * More detection options for rails_xss
  * Add --escape-html option 

## 0.3.2 - 2011-05-12  

  * Autodetect Rails 3 applications
  * Turn on auto-escaping for Rails 3 apps
  * Check Model.create() for mass assignment

## 0.3.1 - 2011-05-03

  * Always output a line number in tabbed output format
  * Restrict characters in category name in tabbed output format to
    word characters and spaces, for Hudson/Jenkins plugin

## 0.3.0 - 2011-03-21

  * Check for SQL injection in calls using constantize()
  * Check for SQL injection in calls to count_by_sql()

## 0.2.2 - 2011-02-22

  * Fix version_between? when no Rails version is specified

## 0.2.1 - 2011-02-18

  * Add code snippet to tab output messages

## 0.2.0 - 2011-02-16

  * Add check for mail_to vulnerability - CVE-2011-0446
  * Add check for CSRF weakness - CVE-2011-0447

## 0.1.1 - 2011-01-25

  * Be more permissive with ActiveSupport version

## 0.1.0 - 2011-01-18

  * Check link_to for XSS (because arguments are not escaped)
  * Process layouts better (although not perfectly yet)
  * Load custom Haml filters if they are in lib/
  * Tab separated output via .tabs output extension
  * Switch to normal versioning scheme
