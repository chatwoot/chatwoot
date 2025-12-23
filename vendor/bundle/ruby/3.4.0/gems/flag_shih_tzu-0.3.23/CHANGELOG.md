# HEAD - UNRELEASED

* Work merged into master branch goes here until it is released.

# Version 0.3.23 - NOV.30.2018

* Avoid establishing a database connection unless necessary by Jonathan del Strother

# Version 0.3.22 - SEP.18.2018

* When #selected_flags= passed with nil it clears flag bits, by xpol
  - This makes flag_shih_tzu behave like Rails: converts empty array to nil.

# Version 0.3.21 - SEP.09.2018

* Make required minimum Ruby version explicit: 1.9.3 and up by Peter Boling
* Support Rails 5.2 by Peter Boling
* Add Ruby 2.5 to build, and update/fix build by Peter Boling

# Version 0.3.20 - SEP.08.2018

* Fix generated instance methods. by xpol
* Support Rails 5.1 saved_change by shiro16

# Version 0.3.19 - MAY.15.2017

* Fixed a bug in Rails 5 support.
* Added Rails 5.1 to travis.

# Version 0.3.18 - APR.30.2017
* Switched from Fixnum to Integer for Ruby 2.4 happiness
* Fixed build for all supported Ruby and Rails versions in supported matrix

# Version 0.3.17 - APR.29.2017
* Improved compatibility with Rails 5.0
* Fixed warnings about Fixnums
* Fixed compatibility with SQLlite
* Added Ruby 2.3, and 2.4 to the Travis Matrix
* Removed JRuby 1.7 from the Travis Matrix

# Version 0.3.16 - JAN.16.2017

* Fix complex custom sql queries with multiple references to the column by vegetaras
* Improved documentation and compatibility matrix  by Peter Boling

# Version 0.3.15 - OCT.11.2015

* Fixed testing for all supported environments by Peter Boling
* Testing on Travis: added Ruby jruby-9.0.1.0 by Peter Boling
* Documented compatibility matrix in table in README by Peter Boling

# Version 0.3.14 - OCT.08.2015

* Allow use without ActiveRecord (experimental) by jfcaiceo
* Many net-zero code cleanups to follow Ruby Style Guide
* Improved local testing script rake test:all
* Testing on Travis: added Ruby 1.9.3, 2.1.5, 2.2.3, jruby-1.7.0
* Testing on Travis: removed Ruby 2.1.2

# Version 0.3.13 - MAR.13.2015

* methods for use with form builders like simple_form by Peter Boling

    - chained_flags_with_signature
    - chained_#{colmn}_with_signature
    - as_flag_collection
    - as_#{colmn.singularize}_collection
    - selected_flags=
    - selected_#{colmn}= (already existed)
* Testing on Travis: added Ruby 2.2.1
* Testing on Travis: removed Ruby 1.9.2

# Version 0.3.12 - OCT.01.2014

* Improve testing instructions in readme by Peter Boling
* fix check_flag_column to return false after warn by Peter Boling
* bash script for running complete test suite on Ruby 1.9.3 and Ruby 2.1.2 by Peter Boling
* Improve documentation in readme by trliner
* use aliases to make attribute reader methods more DRY by trliner
* add negative attribute reader and writer methods for improved interoperability with simple_form and formtastic by trliner
* Adds specs for ActiveRecord version 4.1 by Peter Boling
* Use Kernel#warn instead of puts by Peter Boling

# Version 0.3.11 - JUL.09.2014

* Rename some ambigously-named methods mixed into AR::Base by jdelStrother
* Add dynamic ".*_values_for" helpers by atipugin

# Version 0.3.10 - NOV.26.2013

* Can run tests without coverage by specifying NOCOVER=true by Peter Boling
* Improved test coverage by Peter Boling
* Improved documentation by Peter Boling
* Readme converted to Markdown by Peter Boling

# Version 0.3.9 - NOV.25.2013

* Removed runtime dependency on active record and active support by Peter Boling
* Fixed Coveralls Configuration by Peter Boling
* Improved Readme by Peter Boling

# Version 0.3.8 - NOV.24.2013

* Improved Readme / Documentation by Peter Boling
* Added Badges by Peter Boling
* Configured Coveralls by Peter Boling
* Added Code Climate, Coveralls, Gemnasium, and Version Badges by Peter Boling

# Version 0.3.7 - OCT.25.2013

* Change `sql_in_for_flag` to consider values from the range [0, 2 * max - 1] by Blake Thomson

# Version 0.3.6 - AUG.29.2013

* Allow use with any gem manager by Peter Boling
* No need to alter Ruby's load path by Peter Boling

# Version 0.3.5 - AUG.06.2013

* Fix Travis Build & Add Rails 4 by Peter M. Goldstein
* Implemented update_flag! by Peter Boling (see https://github.com/pboling/flag_shih_tzu/issues/27)
  - sets a flag on a record without triggering callbacks or validations
  - optionally syncs the instance with new flag value, by default it does not.
* Update gemspec by Peter Boling

# Version 0.3.4 - JUN.20.2013

* Allow non sequential flag numbers by Thomas Jachmann
* Report correct source location for class_evaled methods. by Sebastian Korfmann
* Implemented chained_flags_with, which allows optimizing the bit search by Tatsuhiko Miyagawa
* [bugfix] flag_options[colmn][:column] is symbol, it causes error undefined method `length' for nil:NilClass by Artem Pisarev
* Validator raises an error if the validated column is not a flags column. by David DIDIER
* Allow multiple include by Peter Goldstein
* fix a deprecation warning in rails4 by Mose
* Add flag_keys convenience method. by Keith Pitty
* [bugfix] Column names provided as symbols fully work now, as they are converted to strings by Peter Boling
* [bugfix issues/28] Since 0.3.0 flags no longer work in a class using an alternative database connection by Peter Boling
* [bugfix issues/7] Breaks db:create rake task by Peter Boling
* convenience methods now have default parameter so `all_flags` works with arity 0. by Peter Boling
* Many more tests, including arity tests by Peter Boling

# Version 0.3.3 - JUN.20.2013

- Does not exist.

# Version 0.3.2 - NOV.06.2012

* Adds skip column check option :check_for_column - from arturaz
* Adds a 'smart' set_flag_sql method which will auto determine the correct column for the given flag - from arturaz
* Changes the behavior of sql_set_for_flag to not use table names in the generated SQL
  - because it didn't actually work before
  - Now there is a test ensuring that the generated SQL can be executed by a real DB
  - This improved sql_set_for_flag underlies the public set_flag_sql method

# Version 0.3.1 - NOV.06.2012

* Adds new methods (for a flag column named 'bar', with many individual flags within) - from ddidier
  - all_bar, selected_bar, select_all_bar, unselect_all_bar, selected_bar=(selected_flags), has_bar?

# Version 0.3.0 - NOV.05.2012 - first version maintained by Peter Boling

* ClassWithHasFlags.set_#{flag_name}_sql # Returns the sql string for setting a flag for use in customized SQL
* ClassWithHasFlags.unset_#{flag_name}_sql # Returns the sql string for unsetting a flag for use in customized SQL
* ClassWithHasFlags.flag_columns # Returns the column_names used by FlagShihTzu as bit fields
* has_flags :strict => true # DuplicateFlagColumnException raised when a single DB column is declared as a flag column twice
* Less verbosity for expected conditions when the DB connection for the class is unavailable.
* Tests for additional features, but does not change any behavior of 0.2.3 / 0.2.4 by default.
* Easily migrate from 0.2.3 and 0.2.4. Goal is no code changes required. Minor version bump to encourage caution.

# Version 0.2.4 - NOV.05.2012 - released last few changes from XING master

* Fix deprecation warning for set_table_name
* Optional bang methods
* Complete Ruby 1.9(\.[^1]) and Rails 3.2.X compatibility

# Version 0.2.3 - last version maintained by XING AG
