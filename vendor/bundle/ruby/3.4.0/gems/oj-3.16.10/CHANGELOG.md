# CHANGELOG

## 3.16.10 - 2025-02-24

- Changed oj_parser_type to be non-static.

## 3.16.9 - 2024-12-28

- Fixed `Oj::Parser` create_id size issue #931.

- Changed parser to be more optimized (PR from @Watson1978)

## 3.16.8 - 2024-12-14

- Fixed StreamWriter to write to non-file IO thanks to @jscheid.

## 3.16.7 - 2024-11-01

- Changed string_writer_as_json to allow multiple arguments.

- Fixed Global variable registration added to mimic_json and rails code thanks to @byroot.

## 3.16.6 - 2024-09-09

- Fixed issue with Rails 7.2 that changed the order of calls to to_json and as_json.

## 3.16.5 - 2024-08-07

- Fixed Oj::Parser so that block procedures work correctly.

## 3.16.4 - 2024-06-08

- Fixed Oj::Parse EOF issue on larger stream input.

## 3.16.3 - 2023-12-11

- Fixed the gemspec to allow earlier versions of the bigdecimal gem.

## 3.16.2 - 2023-12-06

- Fixed documentation formatting.

- Added option to the "usual" parser to raise an error on an empty input string.

## 3.16.1 - 2023-09-01

- Fixed exception type on number parsing. (thank you @jasonpenny)

## 3.16.0 - 2023-08-16

- Added the `float_format` option.

- Expanded the `max_nesting` option to allow integer values as well as
  the previous boolean (true or nil).

- Skip nesting tests with Truffle Ruby in the json gem tests.

## 3.15.1 - 2023-07-30

- Add protection against some using `require 'oj/json`, an internal file.

- Fixed non-json errors when in compat mode.

## 3.15.0 - 2023-06-02

- Added `omit_null_byte` option when dumping.

## 3.14.3 - 2023-04-07

- Fixed compat parse with optimized Hash when parsing a JSON::GenericObject.
- Deprecated Ruby <= 2.6.10

## 3.14.2 - 2023-02-10

- Fixed check for \0 in strings.

## 3.14.1 - 2023-02-01

- Fixed issue with uninitialized handler for Oj::Parser::Saj.

- Fixed hang on unterminated string with a \0 byte in parse.c.

## 3.14.0 - 2023-01-30

- Tracing is now a compile time option giving a 15 to 20% performance boost.

- Some cleanup in the fast parser.

## 3.13.23 - 2022-11-06

- Fixed issue with Oj::Parser extension regarding GC timeing.

## 3.13.22 - 2022-11-01

- Reorganized Oj::Parser code to allow for parser extensions in C.

## 3.13.21 - 2022-08-19

- Bug parsing big numbers fixed in the SAJ parser.

## 3.13.20 - 2022-08-07

- SSE4 made optional with a `--with-sse42` flag to the compile.

## 3.13.19 - 2022-07-29

- TruffleRuby issues resolved.

## 3.13.18 - 2022-07-25

- Fixed SSE detection at run time.

## 3.13.17 - 2022-07-15

- Fixed Oj::Parser to detect unterminated arrays and objects.

## 3.13.16 - 2022-07-06

- Added line and column as optional arguments to the Oj::Parser.saj parser.

## 3.13.15 - 2022-07-03

- Fixed issue dumping NaN  value in object mode.

## 3.13.14 - 2022-06-03

- Double fclose() due to bad merger fixed by tonobo.

## 3.13.13 - 2022-05-20

- Fixed flooding stdout with debug output when dumping.

## 3.13.12 - 2022-05-20

- Fixed crash on no arguments to pretty_generate. Now raises an exception.
- Register all classes and globals.
- Fixed memory issue with dumping.

## 3.13.11 - 2022-01-05

- Fixed write blocking failures on writes to a slow stream with larger writes.

## 3.13.10 - 2021-12-12

- Fixed Oj::Doc re-entrant issue with each_child.
- Fixed each_child on empty Oj::Doc.

## 3.13.9 - 2021-10-06

- Fix mimic JSON load so that it honors the `:symbolize_names` option.

## 3.13.8 - 2021-09-27

- Fix `Oj::Doc` behaviour for inexisting path.
  ```ruby
  Oj::Doc.open('{"foo":1}') do |doc|
    doc.fetch('/foo/bar') # used to give `1`, now gives `nil`
    doc.exists?('/foo/bar') # used to give `true`, now gives `false`
  end
  ```

- Fix `Oj::Parser` handling of BigDecimal. `snprint()` does not handle `%Lg` correctly but `sprintf()` does.

## 3.13.7 - 2021-09-16

- The JSON gem allows invalid unicode so Oj, when mimicing JSON now
  allows it as well. Use `:allow_invalid_unicode` to change that.

## 3.13.6 - 2021-09-11

- Fixed unicode UTF 8 parsing in string values.

- Fixed hash key allocation issue.

- The `Oj::Parser.new()` function now allows optional arguments that
  set the allowed options for the mode. As an example
  `Oj::Parser.new(:usual, cache_keys: true)`.

## 3.13.5 - 2021-09-08

- Assure value strings of zero length are not always cached.

## 3.13.4 - 2021-09-04

- Fixed concurrent GC issue in the cache.

## 3.13.3 - 2021-08-30

- Caches are now self adjusting and clearing so less used entries are
  expunged to avoid memory growth.

- When mimicking the JSON gem the JSON::State now handles all Hash
  methods. While this is different than the actually JSON gem it
  avoids failing due to errors in Rails code and other gems.

## 3.13.2 - 2021-08-11

- Fixed C99 compiler errors.

## 3.13.1 - 2021-08-09

- Fixed failing build on Windows.

## 3.13.0 - 2021-08-08

- Added `Oj::Parser`, a faster parser with better option management.

- Watson1978 increasd dump performance ever more and is now a collaborator on Oj!

## 3.12.3 - 2021-08-02

- Update documents for the `:cache_keys` and `:cache_strings`.

- Watson1978 increased dump performance for rails mode.

## 3.12.2 - 2021-07-25

- Thanks to Watson1978 for the dump performance for time values.

## 3.12.1 - 2021-07-09

- Fixed `:cache_keys` not being honored in compat mode.
- Increased the cache size.

## 3.12.0 - 2021-07-05

- Added string and symbol caching options that give Oj about a 20% parse performance boost.

## 3.11.8 - 2021-07-03

- Fixed or reverted change that set the default mode when optimize_Rails was called.

## 3.11.7 - 2021-06-22

- Fixed exception type when parsing after `Oj::Rails.mimic_JSON` is called.

## 3.11.6 - 2021-06-14

- Fixed bug where `Oj::Doc#fetch` on an empty Hash or Array did not return `nil`.

- Added an `Oj::Doc#exists?` method.

- Deprecated `Oj::Doc#where?` in favor `Oj::Doc#where` or the alias, `Oj::Doc#path`.

## 3.11.5 - 2021-04-15

- Oj.generate fix introduced in previous bug fix. Oj.mimic_JSON is forced if Oj.generate is called.

## 3.11.4 - 2021-04-14

- Code re-formatted with clang-format. Thanks goes to BuonOmo for
  suggesting and encouraging the use of a formatter and getting the
  effort started.

- Added support for `GC.compact` on `Oj::Doc`

- Fixed compatibility issue with Rails and the JSON gem that requires
  a special case when using JSON.generate versus call `to_json` on an
  object.

## 3.11.3 - 2021-03-09

- Fixed `respond_to?` method on `Oj::EasyHash`.

## 3.11.2 - 2021-01-27

- Fixed JSON gem `:decimal_class` option.

## 3.11.1 - 2021-01-24

- XrXr fixed Ruby 3.0.0 object movement issue.

## 3.11.0 - 2021-01-12

- Added `:compat_bigdecimal` to support the JSON gem `:decimal_class` undocumented option.

- Reverted the use of `:bigdecimal_load` for `:compat` mode.

## 3.10.18 - 2020-12-25

- Fix modes table by marking compat mode `:bigdecimal_load` instead of `:bigdecimal_as_decimal`.

- Added `:custom` mode setting that are the same as `:compat` mode. There are some minor differences between the two setting.

## 3.10.17 - 2020-12-15

- The undocumented JSON gem option of `:decimal_class` is now
  supported and the default option of `:bigdecimal_load` is also
  honored in JSON.parse() and in compat mode.

- Invalid encoding detection bug fixed for rails.

## 3.10.16 - 2020-11-10

- Allow escaping any character in :compat mode to match the json gem behavior.

## 3.10.15 - 2020-10-16

Remove license from code.

## 3.10.14 - 2020-09-05

- Updated float test to check a range.

## 3.10.13 - 2020-08-28

- Removed explicit dependency on bigdecimal.

## 3.10.12 - 2020-08-20

- Another try at bracketing bigdecimal versions to 1.0 and 3.

## 3.10.11 - 2020-08-20

- Bracketed bigdecimal dependency to 1.0 and 3.

## 3.10.10 - 2020-08-20

- Backed off bigdecimal dependency to 1.0.

## 3.10.9 - 2020-08-17

- Add bigdecimal dependency to gemfile.

## 3.10.8 - 2020-07-24

- New fast option for float parsing.

- Fixes a float parse error.

## 3.10.7 - 2020-07-13

- Faster float parsing and an adjust to more closely match Ruby.

## 3.10.6 - 2020-04-04

- Correct object dump code to continue instead of return on an _ attribnute.

## 3.10.5 - 2020-03-03

- Fix test

## 3.10.4 - 2020-03-03

- Another adjustment to get Ruby floats to match Oj thanks to klaxit.

## 3.10.3 - 2020-03-01

- Fixed difference between some unicode character encoding in Rails mode.

## 3.10.2 - 2020-01-30

- Fixed circular array reference load.

## 3.10.1 - 2020-01-14

- Fixed bug where setting `ActiveSupport::JSON::Encoding.use_standard_json_time_format` before calling `Oj.optimize_rails` did not have an effect on the time format.

- Worked around the Active Support hack that branched in `to_json` depending on the class of the option argument.

- Updated for Ruby 2.7.0

## 3.10.0 - 2019-11-28

- Fixed custom mode load_file to use custom mode.

- Fixed rails mode output of IO objects

- Fixed issue #567. Second precision is forced if set to the correct number of decimals even if zero nanoseconds.

- Fixed issue #568. Dumping bigdecimal in `:rails' mode made more consistent.

- Fixed issue #569. `:compat` mode not restricts the escape mode as indicated in the documentation.

- Fixed issue #570. In `:strict` mode number parsing follows the JSON specification more closely as intended.

- Added `:ignore_under` which when true will ignore attributes that begin with a `_` when dumping in `:object` or `:custom` mode.

## 3.9.2 - 2019-10-01

- Fixed wrong exception type when mimicking the JSON gem.

## 3.9.1 - 2019-08-31

- Raise an exception on an invalid time represented as a decimal in `:object` mode.

## 3.9.0 - 2019-08-18

- Changed custom behavior when `:create_additions` is true and `:create_id` is
  set to nil. Now Range, Regexp, Rational, and Complex are output as strings
  instead of a JSON object with members. Setting any other value for
  `:create_id`, even an empty string will result in an object being dumped.

- Detection of pthread mutex support was changed.

## 3.8.1 - 2019-07-22

- Fix replacement of JSON::Parse thanks to paracycle.

## 3.8.0 - 2019-07-17

- Fixed a buffer allocation bug for `JSON.pretty_generate`.

- Added mimic `safe` option to not include the complete JSON in a parse error message.

- Added `use_raw_json` option for `:compat` and `:rails` mode to allow better
  performance on dump. StringWriter in particular has been optimized for this option.

## 3.7.12 - 2019-04-14

- The `:omit_nil` option did not work in `:rails` mode. That has been fixed.

## 3.7.11 - 2019-03-19

- Fix to Rails optimize that missed initializing the mimic JSON `:symbolize_names` value.

## 3.7.10 - 2019-03-14

- Corrected time dump so that the none-leap years after a 400 year period are correct.

## 3.7.9 - 2019-02-18

- Return correct value in `create_opt` C function.

- Return `Oj::ParseError` if an invalid big decimal string is encountered instead of an argument error

## 3.7.8 - 2019-01-21

- Replace `gmtime` with a custom function.

- Oj::Doc crash fix.

- Mark odd args to avoid GC.

## 3.7.7 - 2019-01-14

  - Exception with other than a single argument initializer can now be decoded.

  - StreamWriter bug fixed that forces UTF-8 when appending to a stream. Ruby likes to convert to ASCII-8BIT but forcing the append to be UTF-8 avoids that issue.

## 3.7.6 - 2018-12-30

  - Changed time encoding for 32 bit to work around a Ruby bug in `rb_time_timespec()` that fails for times before 1970.

  - Addressed issue #514 by changing reserved identifiers.

  - Addressed issue #515 by adding return value checks on `strdup()` and `pthread_mutex_init()`.

## 3.7.5 - 2018-12-27

  - Address issue #517 with a special escape table for mimicking the JSON gem.

## 3.7.4 - 2018-11-29

  - Allow `+` in front of numbers in parse as well as stream parse **EXCEPT** when mimicking the JSON gem.

## 3.7.3 - 2018-11-29

  - Allow `+` in front of numbers in parse as well as stream parse.

## 3.7.2 - 2018-11-29

  - More tolerant float parsing to allow `123.`.

  - Parse exceptions raised by user code now preserve the message content of the exception.

## 3.7.1 - 2018-11-09

  - Updated to support TruffleRuby.

## 3.7.0 - 2018-10-29

  - Thanks to Ziaw for adding a integer range where integers outside that range are written as strings.

## 3.6.13 - 2018-10-25

  - Fixed issue where exceptions were not being cleared on parsing.

  - Added addition unicode dump error information.

## 3.6.12 - 2018-10-16

  - Fixed random `:omit_nil` setting with StringWriter and StreamWriter.

## 3.6.11 - 2018-09-26

  - Added the JSON path to parse error messages.

  - BigDecimal parse errors now return Oj::ParseError instead of ArgumentError.

## 3.6.10 - 2018-09-13

  - Additional occurrences of `SYM2ID(sym)` replaced.

## 3.6.9 - 2018-09-12

  - `SYM2ID(sym)` causes a memory leak. A work around is now used.

## 3.6.8 - 2018-09-08

  - Stopped setting the default options when optimize rails is called as the documentation has indicated.

  - In custom mode `Date` and `DateTime` instances default to use the `:time_format` option is the `:create_additions` option is false.

## 3.6.7 - 2018-08-26

  - Fixed incorrect check in StreamWriter when adding raw JSON.

## 3.6.6 - 2018-08-16

  - Fixed Debian build issues on several platforms.

  - `oj_slash_string` is now frozen.

## 3.6.5 - 2018-07-26

  - Fixed GC issue with Oj::Doc.

  - Fixed issue with time encoding with Windows.

## 3.6.4 - 2018-07-10

  - JSON.generate() now sets the `to_json` option as expected.

  - Show `:create_additions` in the default options. It did not appear before.

## 3.6.3 - 2018-06-21

  - Fixed compat dump compilation error on Windows.

## 3.6.2 - 2018-05-30

  - Regex encoded correctly for rails when using `to_json`.

  - ActiveSupport::TimeWithZone optimization fixed.

## 3.6.1 - 2018-05-16

  - Fixed realloc bug in rails dump.

## 3.6.0 - 2018-05-01

  - Add optimization for Rails ActiveRecord::Result encoding.

## 3.5.1 - 2018-04-14

  - Fixed issue with \u0000 terminating keys early.

  - Add trace for calls to `to_json` and 'as_json`.

## 3.5.0 - 2018-03-04

  - A trace option is now available in all modes. The format roughly follows the Ruby trace format.

## 3.4.0 - 2018-01-24

  - Option to ignore specific classes in :object and :custom mode added.

## 3.3.10 - 2017-12-30

  - Re-activated the bigdecimal_as_decimal option in custom mode and made the selection active for Rails mode.

  - Fixed bug in optimize_rails that did not optimize all classes as expected.

  - Fixed warnings for Ruby 2.5.0.

## 3.3.9 - 2017-10-27

  - Fixed bug where empty strings were sometimes marked as invalid.

## 3.3.8 - 2017-10-04

  - Fixed Rail mimic precision bug.

## 3.3.7 - 2017-10-02

  - Handle invalid unicode characters better for single byte strings.

  - Parsers for empty strings handle errors more consistently.

## 3.3.6 - 2017-09-22

  - Numerous fixes and cleanup to support Ruby 2.4.2.

## 3.3.5 - 2017-08-11

- Fixed a memory error when using rails string encoding of certain unicode characters.

## 3.3.4 - 2017-08-03

- Oj::Rails.mimic_JSON now uses Float for JSON.parse for large decimals instead of BigDecimal.

## 3.3.3 - 2017-08-01

- Allow nil as a second argument to parse when mimicking the json gem. This is
  a special case where the gem does not raise an exception on a non-Hash
  second argument.

## 3.3.2 - 2017-07-11

- Fixed Windows compile issue regarding timegm().

## 3.3.1 - 2017-07-06

- Some exceptions such as NoMethodError have an invisible attribute where the
  key name is NULL. Not an empty string but NULL. That is now detected and
  dealt with.

## 3.3.0 - 2017-07-05

- Added the :wab mode to support the [WABuR](https://github.com/ohler55/wabur)
  project. The :wab mode only allows the indent option and is faster due to
  not having to check the multitude of options the other modes support.

## 3.2.1 - 2017-07-04

- Made json gem NaN dumping more consistent.

- Fixed :null mode to not revert to strict mode.

## 3.2.0 - 2017-06-20

- A buffer_size option was added to StringWriter and StreamWriter. That option
  also sets the suggested flush limit for StreamWriter.

## 3.1.4 - 2017-06-16

- :symbolize_names now works with Oj::Rails.mimic_JSON.

## 3.1.3 - 2017-06-13

- JSON.dump used the default mode instead of :compat mode. That has been fixed.

- Updated docs on Oj.mimic_JSON to note the :encoding is set to :unicode_xss and not :ascii.

## 3.1.2 - 2017-06-10

- StringWriter was passing incorrect arguments to to_json and as_json. Fixed.

- StringWriter now accepts the mode option. This means it also defaults to the
  default_options mode instead of the custom mode.

- JSON.pretty_generate when in rails mode now loads the JSON::State class correctly.

## 3.1.1 - 2017-06-09

- Custom mode now honors the :create_additions option for time.

## 3.1.0 - 2017-06-04

- Added Oj::Rails.mimic_JSON which mimics the json gem when used with
  ActiveSupport which monkey patches the same to_json methods does. Basically
  this changes the JSON.parse and other JSON entry points for encoding and
  decoding.

- Oj.optimize_rails now calls Oj::Rails.mimic_JSON.

## 3.0.11 - 2017-06-02

- If rails in required and Oj.mimic_JSON is called without calling
  Oj.optimize_rails nil.to_json failed. That has been fixed.

- Fixed crash on setting create_id to nil after mimic_JSON.

## 3.0.10 - 2017-05-22

- Oj.optimize_rails failed to include Hash and Array in the optimization. It does now.

## 3.0.9 - 2017-05-17

- Missed catching invalid unicodes beginning with \xE2. Fixed.

- In :compat mode a non-string and non IO value is converted to a string with a call to to_s.

## 3.0.8 - 2017-05-16

- Float significant digits now match Ruby's unless optimized and then significant digits are set to 16.

- Rails Hash post merging of identical keys after calling as_json is preserved only for un-optimized Hashes.

- Raise an exception to match json gem behavior on invalid unicode.

## 3.0.7 - 2017-05-10

- Changed JSON.pretty_generate options to a State instead of a Hash to get the
  json gen to_json method to accept formatting options.

- Added optimization for ActionController::Parameters

## 3.0.6 - 2017-05-07

- Added Oj.optimize_rails().

- Fixed argument passing bug on calls to to_json().

## 3.0.5 - 2017-05-02

- No change in the Oj::Rails.optimize() API but additional classes are now supported.

- Added ActiveSupport::TimeWithZone optimization to rails mode.

- Added ActiveRecord::Base optimization to rails mode which allows optimization of any class inheriting from ActiveRecord::Base.

## 3.0.4 - 2017-05-01

- Fixed compile problem on Windows again.

- Fixed issue with TimeWithZone not being encoded correctly when a member of an object.

## 3.0.3 - 2017-04-28

- Improved compatibility with a json gem and Rails combination when json adds are used.

- Fixed compile problem on Windows.

## 3.0.2 - 2017-04-27

- Fixed crash due to unset var with dump to Rails mode.

## 3.0.1 - 2017-04-25

- Fixed compile error with help from Dylan Johnson.

## 3.0.0 - 2017-04-24

- Major changes focused on json gem and Rails compatibility. A new :custom
  mode was added as well. Starting with this release the json gem tests are
  being used to test the :compat mode and the ActiveSupport 5 tests are being
  used to test the :rails mode.

- Please give stereobooster a thank you for getting the tests set up and
  helping out with json gem and Rails understanding. He also has some
  benchmarks of Oj versus other options
  [here](https://github.com/stereobooster/ruby-json-benchmark).

## 2.18.3 - 2017-03-14

- Changed to use long doubles for parsing to minimize round off errors. So PI will be accurate to more places for PI day.

## 2.18.2 - 2017-03-01

- Strict mode now allows symbol keys in hashes.

- Fixed omit_nil bug discovered by ysmazda.

## 2.18.1 - 2017-01-09

- Missing argument to dump now raises the correct arg exception and with mimic does not crash on missing argument.
- Oj::Doc paths can now contain escaped path separators so "a\/b" can match an lement name with a slash in it.

## 2.18.0 - 2016-11-26

- Rubinius compilation fixes.
- Added a separate option for as_json instead of piggy backing on the use_to_json. This changes the API slightly.
- Ready for Ruby 2.4.
- Thanks to faucct for fixing mimic to not redefine JSON::ParserError.

## 2.17.5 - 2016-10-19

- Added additional code to check for as_json arguments and recursive calls.

## 2.17.4 - 2016-09-04

- Added the ascii_only option to JSON.generate when in mimic_JSON mode so that it is consistent with the undocumented feature in the json gem.

## 2.17.3 - 2016-08-16

- Updated mimic_JSON to monkey patch OpenStruct, Range, Rational, Regexp, Struct, Symbol, and Time like the JSON gem does. Also added the JSON.create_id accessor.

## 2.17.2 - 2016-08-13

- Worked around a problem with DateTime and ActiveSupport that causes a hang when hour, minute, second, and some other methods are called from C.

## 2.17.1 - 2016-07-08

- Added an option provide an alternative Hash class for loading.
- Added the Oj::EasyHash class.
- Fixed test failures on 32 bit machines.
- Sped up mimic_JSON.
- Added an option to omit Hash and Object attributes with nil values.

## 2.16.1 - 2016-06-21

- Thanks to hsbt for fixing a compile issue with Ruby 2.4.0-preview1.

## 2.16.0 - 2016-06-19

- Added option to allow invalid unicode characters. This is not a suggested option in a majority of the cases.
- Fixed float parsing for 32 bit systems so that it does not roll over to BigDecimal until more than 15 significant digits.

## 2.15.1 - 2016-05-26

- Fixed bug with activerecord when to_json returns an array instead of a string.

## 2.15.0 - 2016-03-28

- Fixed bug where encoded strings could be GCed.
- :nan option added for dumping Infinity, -Infinity, and NaN. This is an edition to the API. The default value for the :non option is :auto which uses the previous NaN handling on dumping of non-object modes.

## 2.14.7 - 2016-03-20

- Fixed bug where a comment before another JSON element caused an error. Comments are not part of the spec but this keep support consistent.

## 2.14.6 - 2016-02-26

- Changed JSON::ParserError to inherit from JSON::JSONError which inherits from StandardError.

## 2.14.5 - 2016-02-19

- Parse errors in mimic mode are not a separate class than Oj.ParseError so the displayed name is JSON::ParserError instead.

## 2.14.4 - 2016-02-04

- When not in quirks mode strings are now raise an exception if they are the top level JSON value.

## 2.14.3 - 2015-12-31

- Updated to support Ruby 2.3.0.

## 2.14.2 - 2015-12-19

- Non-UTF-8 string input is now converted to UTF-8.

## 2.14.1 - 2015-12-15

- Fixed bug that reverted to BigDecimal when a decimal had preceding zeros after the decimal point.

## 2.14.0 - 2015-12-04

- More tweaking on decimal rounding.
- Made dump options available in the default options and not only in the mimic generate calls.

## 2.13.1 - 2015-11-16

- Thanks to Comboy for the fix to a large number rounding bug.

## 2.13.0 - 2015-10-19

- Oj no longer raises an exception if the to_hash method of an object does not return a Hash. ActiveRecord has decided that to_hash should return an Array instead so Oj now encodes what ever is returned.
- Added a register_odd_raw function that allows odd marshal functions to return raw JSON as a string to be included in the dumped JSON.
- The register_odd function now supports modules in additions to classes.

## 2.12.14 - 2015-09-14

- Change the failure mode for objects that can not be serialized such as a socket. Now in compat mode the to_s of the object is placed in the output instead of raising an exception.

## 2.12.13 - 2015-09-02

- Added a check for the second argument to load() is a Hash.
- Yet another attempt to make floating point numbers display better.
- Thanks to mkillianey for getting the extconf.rb and gemspec file updated.

## 2.12.12 - 2015-08-09

- Thanks to asurin for adding support for arguments to to_json() that rails uses.

## 2.12.11 - 2015-08-02

- Oj::ParseError is now thrown instead of SyntaxError when there are multiple  JSON documents in a string or file and there is no proc or block associated with the parse call.

## 2.12.10 - 2015-07-12

- An exception is now raised if there are multiple JSON documents in a string or file if there is no proc or block associated with the parse call.

## 2.12.9 - 2015-05-30

- Fixed failing test when using Rubinius.
- Changed mimic_JSON to support the global/kernel function JSON even when the json gem is loaded first.

## 2.12.8 - 2015-05-16

- mimic_JSON now supports the global/kernel JSON function that will either parse a string argument or dump an array or object argument.

## 2.12.7 - 2015-05-07

- Fixed compile error with 32 bit HAS_NANO_TIME extra paren bug.

## 2.12.6 - 2015-05-05

- Fixed a number of 32bit related bugs.

## 2.12.5 - 2015-04-27

- In :null mode Oj now dumps Infinity and NaN as null.

## 2.12.4 - 2015-04-20

- Fixed memory leak in Oj::Doc when not using a given proc.

## 2.12.3 - 2015-04-16

- Fixed bug when trying to resolve an invalid class path in object mode load.

## 2.12.2 - 2015-04-13

- Fixed Oj::Doc bug that causes a crash on local name lookups.
- Fixed Oj::Doc unicode parsing.

## 2.12.1 - 2015-03-12

- Changed the unix_zone encoded format to be the utc epoch.

## 2.12.0 - 2015-03-06

- String formats for UTC time are now explicitly UTC instead of offset of zero. This fixes a problem with pre-2.2.0 Rubies that automatically convert zero offset times to local times.
- Added :unix_zone time_format option for formatting numeric time. This option is the same as the :unix time option but the UTC offset is included as an exponent to the number time value. A value of 86400 is an indication of UTC time.

## 2.11.5 - 2015-02-25

- Fixed issue with rails as_json not being called for Structs.
- Added support for anonymous Structs with object mode encoding. Note that this will result in a new anonymous Struct for each instance.

## 2.11.4 - 2015-01-20

- DateTime second encoding is now always a Rational to preserve accuracy.
- Fixed buf in the Oj.load() callback feature that caused an endless loop when a StringIO was used with a JSON that was a number.

## 2.11.3 - 2015-01-18

- DateTime encoding now includes nanoseconds.

## 2.11.2 - 2015-01-10

- Changed the defaults for mimic_JSON to use 16 significant digits instead of the default 15.
- Fixed bug where a subclass of Array would be serialized as if in object mode instead of compat when in compat mode.

## 2.11.1 - 2014-11-09

- Changed the use_to_json option to still allow as_json even when set to false.

## 2.11.0 - 2014-11-02

- Restricted strict dump to not dump NaN nor Infinity but instead raise an exception.
- Changed compat mode so that the :bigdecimal_as_decimal option over-rides the to_json method if the option is true. The default for mimic_JSON is to leave the option off.
- Added support for Module encoding in compat mode.
- Added ActiveSupportHelper so that require 'active_support_helper' will added a helper for serializing ActiveSupport::TimeWithZone.
- Added float_precision option to control the number of digits used for floats when dumping.

## 2.10.4 - 2014-10-22

- Fixed Range encoding in compat mode to not use the object mode encoding.
- Fixed serialization problem with timestamps.
- Fixed compat parser to accept NaN and Infinity.

## 2.10.3 - 2014-10-04

- Using the xmlschema option with :object mode now saves time as a string and preserves the timezone.
- Rational recursive loop caused by active support fixed.
- Time in mimic_JSON mode are now the ruby string representation of a date.

## 2.10.2 - 2014-08-20

- Fixed string corruption bug due to an uncommented assignment used for debugging.

## 2.10.1 - 2014-08-17

- Changed parse argument error to be a Ruby ArgError instead of a general Exception.

## 2.10.0 - 2014-08-03

- Using an indent of less than zero will not place newline characters between JSON elements when using the string or stream writer.
- A new options callback method was added to the Simple Callback Parser. If defined the prepare_key() method will be called when an JSON object ket is first encountered. The return value is then used as the key in the key-value pair.
- Increased significants digits to 16 from 15. On occasion there may be unexpected round off results. Tou avoid those use the bigdecimal options.

## 2.9.9 - 2014-07-07

- Missed a character map entry. / in ascii mode is now output as / and not \/
- Fixed SC parser to not treat all IO that respond to fileno as a file. It not checks stat and asks if it is a file.
- Tightened object parsing of non-string hash keys so that just "^#x" is parsed as a hash pair and not "~#x".
- Using echo to STDIN as an IO input works around the exception raised when asking the IO for it's position (IO.pos).
- Simple Callback Parser now uses the new stream parser for handling files and IO so that larger files are handled more efficiently and streams are read as data arrives instead of on close.
- Handles file FIFO pipes correctly now.

## 2.9.8 - 2014-06-25

- Changed escaping back to previous release and added a new escape mode.
- Strict mode and compat mode no longer parse Infinity or NaN as a valid number. Both are valid in object mode still.

## 2.9.7 - 2014-06-24

- Changed dump to use raw / and raw \n in output instead of escaping.
- Changed the writer to always put a new line at the end of a top level JSON object. It makes output easier to view and edit with minimal impact on size.
- Worked around the file.gets look ahead caching as long as it is not called while parsing (of course).
- Thanks to lautis for a new parse option. quirks_mode allows Oj to behave quirky like the JSON gem. Actually the JSON gem has it backwards with quirky mode supporting the JSON spec and non-quirky limiting parsing to objects and arrays. Oj stays consistent with the JSON gem to avoid confusion.
- Fixed problem with sc_parse not terminating the string when loaded from a file.
- Thanks go to dchelimsky for expanding the code sample for the ScHandler.

## 2.9.6 - 2014-06-15

- Fixed bug using StringIO with SCParser.
- Tightened up JSON mimic to raise an exception if JSON.parse is called on a JSON documents that returns a primitive type.

## 2.9.5 - 2014-06-07

- Mimic mode now monkey patches Object like JSON.
- A big thanks to krasnoukhov for reorganizing test and helping get Oj more rails compatible.
- Another thanks goes out to lautis for a pull request that provided some optimization and fixed the return exception for an embedded null in a string.
- Fixed a bug with zip reader streams where EOF was not handled nicely.

## 2.9.4 - 2014-05-28

- In mimic mode parse errors now match the JSON::ParserError.

## 2.9.3 - 2014-05-15

- Fixed IO read error that showed up in IO objects that return nil instead of raising an EOF error when read is done.

## 2.9.2 - 2014-05-14

- Fixed link error with Windows.

## 2.9.1 - 2014-05-14

- Fixed mimic load when given a block to evalate. It conflicted with the new load option.
- Added a true stream that is used when the input argument to load is an IO object such as a stream or file. This is slightly slower for smaller files but allows reading of huge files that will not fit in memory and is more efficient on even larger files that would fit into memory. The load_file() method uses the new stream parser so multiple GB files can be processed without used execessive memory.

## 2.9.0 - 2014-05-01

- Added support for detection and handling of String, Array, and Hash subclasses.
- Oj.load() can now take a block which will be yielded to on every object parsed when used with a file or string with multiple JSON entries.

## 2.8.1 - 2014-04-21

- Added additional argument to the register_odd function.
- Fixed bug that failed to load on some uses of STDIN.

## 2.8.0 - 2014-04-20

- Added support for registering special encoding and decoding rules for specific classes. This the ActiveSupport subclass of the String class for safe strings. For an example look at the `test_object.rb` file, `test_odd_string` test.

## 2.7.3 - 2014-04-11

- Fixed bug where load and dump of Structs in modules did not work correctly.

## 2.7.2 - 2014-04-06

- Added option return nil if nil is provided as input to load.

## 2.7.1 - 2014-03-30

- Fixed bug in new push_key which caused duplicate characters.

## 2.7.0 - 2014-03-29

- Added the push_key() method to the StringWriter and StreamWriter classes.

## 2.6.1 - 2014-03-21

- Set a limit on the maximum nesting depth to 1000. An exception is raised instead of a segfault unless a reduced stack is used which could trigger the segfault due to an out of memory condition.

## 2.6.0 - 2014-03-11

- Added the :use_to_json option for Oj.dump(). If this option is set to false the to_json() method on objects will not be called when dumping. This is the default behavior. The reason behind the option and change is to better support Rails and ActiveSupport. Previous works arounds have been removed.

## 2.5.5 - 2014-02-18

- Worked around the Rubinius failure to load bigdecimal from a require within the C code.

## 2.5.4 - 2014-01-14

- Fixed bug where unterminated JSON did not raise an exception.

## 2.5.3 - 2014-01-03

- Added support for blocks with StringWriter.

## 2.5.2 - 2014-01-02

- Fixed indent problem with StringWriter so it now indents properly.

## 2.5.1 - 2013-12-18

- Added push_json() to the StringWriter and StreamWriter to allow raw JSON to be added to a JSON document being constructed.

## 2.4.3 - 2013-12-16

- Made include pthread.h conditional for Windows.

## 2.4.2 - 2013-12-14

- Thanks to Patrik Rak for a fix to a buffer short copy when dumping with 0 indent.

## 2.4.1 - 2013-12-10

- Fixed Windows version by removing class cache test.

## 2.4.0 - 2013-12-08

- Merged in a PR to again allow strings with embedded nulls.
- Implemented StreamWriter to compliment the StringWriter.
- Fixed bug in the class cache hash function that showed up with the sparc compiler.

## 2.3.0 - 2013-12-01

- JRuby is no longer supported.
- Thanks to Stefan Kaes the support for structs has been optimized.
- Better support for Rubinous.
- Added option to disable GG during parsing.
- Added StringWriter that allows building a JSON document one element at a time.

## 2.2.3 - 2013-11-19

- Fixed struct segfault on load.
- Added option to force float on load if a decimal number.

## 2.2.2 - 2013-11-17

- Added mutex support for Windows.
- Protected SCP parser for GC.

## 2.2.1 - 2013-11-15

- Made all VALUEs in parse volatile to avoid garbage collection while in use.

## 2.2.0 - 2013-11-11

- All 1.8.x versions of Ruby now have require 'rational' called.
- Removed the temporary GC disable and implemented mark strategy instead.
- Added new character encoding mode to support the Rails 4 escape characters of &,  as xss_safe mode. The :encoding option replaces the :ascii_only option.
- Change parsing of NaN to not use math.h which on older systems does not define NAN.

## 2.1.8 - 2013-10-28

- All 1.8.x versions of Ruby now have require 'rational' called.
- Removed the temporary GC disable and implemented mark strategy instead.

## 2.1.7 - 2013-10-19

- Added support for NaN and -NaN to address issue #102. This is not according to the JSON spec but seems to be expected.
- Added require for rational if the Ruby version is 1.8.7 to address issue #104.
- Added Rails re-call of Oj.dump in the to_json() method which caused loops with Rational objects to fix issue #108 and #105.

## 2.1.6 - 2013-10-07

- Added Oj.to_stream() for dumping JSON to an IO object.

## 2.1.5 - 2013-07-21

- Allow exception dumping magic with Windows.

## 2.1.4 - 2013-07-04

- Fixed Linux 32 bit rounding bug.

## 2.1.3 - 2013-06-30

- Fixed bug that did not deserialize all attributes in an Exception subclass.
- Added a sample to demonstrate how to write Exception subclasses that will automatically serialize and deserialize.

## 2.1.2 - 2013-06-19

- Fixed support for Windows.

## 2.1.1 - 2013-06-17

- Fixed off by 1 error in buffer for escaped strings.

## 2.1.0 - 2013-06-16

- This version is a major rewrite of the parser. The parser now uses a constant stack size no matter how deeply nested the JSON document is. The parser is also slightly faster for larger documents and 30% faster for object parsing.
- Oj.strict_load() was renamed to Oj.safe_load() to better represent its functionality. A new Oj.strict_load() is simply Oj.load() with :mode set to :strict.
- Oj.compat_load() and Oj.object_load() added.
- A new Simple Callback Parser was added invoked by Oj.sc_parse().
- Eliminated :max_stack option as it is no longer needed.
- Handle cleanup after exceptions better.

## 2.0.14 - 2013-05-26

- Fixed bug in Oj::Doc.each_leaf that caused an incorrect where path to be created and also added a check for where path maximum length.
- Updated the documentation to note that invalid JSON documents, which includes an empty string or file, will cause an exception to be raised.

## 2.0.13 - 2013-05-17

- Changed dump to put closing array brackets and closing object curlies on the line following the last element if :indent is set to greater than zero.

## 2.0.12 - 2013-04-28

- Another fix for mimic.
- mimic_JSON now can now be called after loading the json gem. This will replace the json gem methods after loading. This may be more compatible in many cases.

## 2.0.11 - 2013-04-23

- Fixed mimic issue with Debian
- Added option to not cache classes when loading. This should be used when classes are dynamically unloaded and the redefined.
- Float rounding improved by limiting decimal places to 15 places.
- Fixed xml time dumping test.

## 2.0.10 - 2013-03-10

- Tweaked dump calls by reducing preallocation. Speeds are now several times faster for smaller objects.
- Fixed Windows compile error with Ruby 2.0.0.

## 2.0.9 - 2013-03-04

- Fixed problem with INFINITY with CentOS and Ruby 2.0.0. There are some header file conflicts so a different INFINITY was used.

## 2.0.8 - 2013-03-01

- Added :bigdecimal_load option that forces all decimals in a JSON string to be read as BigDecimals instead of as Floats. This is useful if precision is important.
- Worked around bug in active_support 2.3.x where BigDecimal.as_json() returned self instead of a JSON primitive. Of course that creates a loop and blows the stack. Oj ignores the as_json() for any object that returns itself and instead encodes the object as it sees fit which is usually what is expected.
- All tests pass with Ruby 2.0.0-p0. Had to modify Exception encoding slightly.

## 2.0.7 - 2013-02-18

- Fixed bug where undefined classes specified in a JSON document would freeze Ruby instead of raising an exception when the auto_define option was not set. (It seems that Ruby freezes on trying to add variables to nil.)

## 2.0.6 - 2013-02-18

- Worked around an undocumented feature in linux when using make that misreports the stack limits.

## 2.0.5 - 2013-02-16

- DateTimes are now output the same in compat mode for both 1.8.7 and 1.9.3 even though they are implemented differently in each Ruby.
- Objects implemented as data structs can now change the encoding by implemented either to_json(), as_json(), or to_hash().
- Added an option to allow BigDecimals to be dumped as either a string or as a number. There was no agreement on which was the best or correct so both are possible with the correct option setting.

## 2.0.4 - 2013-02-11

- Fixed bug related to long class names.
- Change the default for the auto_define option.
- Added Oj.strict_load() method that sets the options to public safe options. This should be safe for loading JSON documents from a public unverified source. It does not eleviate to need for reasonable programming practices of course. See the section on the proper use of Oj in a public exposure.

## 2.0.3 - 2013-02-03

- Fixed round off error in time format when rounding up to the next second.

## 2.0.2 - 2013-01-23

- Fixed bug in Oj.load where loading a hash with symbold keys and also turning on symbolize keys would try to symbolize a symbol.

## 2.0.1 - 2013-01-15

- BigDecimals now dump to a string in compat mode thanks to cgriego.
- High precision time (nano time) can be turned off for better compatibility with other JSON parsers.
- Times before 1970 now encode correctly.

## 2.0.0 - 2012-12-18

- Thanks to yuki24 Floats are now output with a decimal even if they are an integer value.
- The Simple API for JSON (SAJ) API has been added. Read more about it on the Oj::Saj page.

## 1.4.7 - 2012-12-09

- In compat mode non-String keys are converted to Strings instead of raising and error. (issue #52)

## 1.4.6 - 2012-12-03

- Silently ignores BOM on files and Strings.
- Now works with JRuby 1.7.0 to the extent possible with the unsupported C extension in JRuby.

## 1.4.5 - 2012-11-19

- Adds the old deprecated methods of unparse(), fast_unparse(), and pretty_unparse() to JSON_mimic.

## 1.4.4 - 2012-11-07

- Fixed bug in mimic that missed mimicking json_pure.

## 1.4.3 - 2012-10-19

- Fixed Exception encoding in Windows version.

## 1.4.2 - 2012-10-17

- Fixed dump and load of BigDecimals in :object mode.
- BigDecimals are now dumped and loaded in all modes.

## 1.4.1 - 2012-10-17

- Windows RubyInstaller and TCS-Ruby now supported thanks to Jarmo Pertman. Thanks Jarmo.

## 1.4.0 - 2012-10-11

- Parse errors now raise an Exception that inherites form Oj::Error which inherits from StandardError. Some other Exceptions were changed as well to make it easier to rescue errors.

## 1.3.7 - 2012-10-05

- Added header file for linux builds.

## 1.3.6 - 2012-10-04

- Oj.load() now raises a SystemStackError if a JSON is too deeply nested. The loading is allowed to use on 75% of the stack.
- Oj::Doc.open() now raises a SystemStackError if a JSON is too deeply nested. The loading is allowed to use on 75% of the stack. Oj::Doc.open will allow much deeper nesting than Oj.load().

## 1.3.5 - 2012-09-25

- Fixed mimic_JSON so it convinces Ruby that the ALL versions of the json gem are already loaded.

## 1.3.4 - 2012-08-12

- Fixed mimic_JSON so it convinces Ruby that the json gem is already loaded.

## 1.3.2 - 2012-07-28

- Fixed compile problems with native Ruby on OS X 10.8 (Mountain Lion)

## 1.3.1 - 2012-07-01

- Fixed time zone issue with :xmlschema date format.

## 1.3.0 - 2012-07-09

- extconf.rb fixed to not pause on some OSs when checking CentOS special case.
- Added an option to control the time format output when in :compat mode.

## 1.2.13 - 2012-07-08

- Fixed double free bug in Oj::Doc that showed up for larger documents.

## 1.2.12 - 2012-07-06

- Fixed GC bug in Oj::Doc, the fast parser.
- Serialization of Exceptions in Ruby 1.8.7 now includes message and backtrace.

## 1.2.11 - 2012-06-21

- Added :max_stack option to limit the size of string allocated on the stack.

## 1.2.10 - 2012-06-20

- Added check for circular on loading of circular dumped JSON.
- Added support for direct serialization of BigDecimal, Rational, Date, and DateTime.
- Added json.rb to $" in mimic mode to avoid pulling in the real JSON by accident.
- Oj is now thread safe for all functions.
- The / (solidus) character is now placed in strings without being escaped.

## 1.2.9 - 2012-05-29


## 1.2.8 - 2012-05-03

- Included a contribution by nevans to fix a math.h issue with an old fedora linux machine.
- Included a fix to the documentation found by mat.

## 1.2.7 - 2012-04-22

- Fixed bug where a float with too many characters would generate an error. It is not parsed as accuractly as Ruby will support.
- Cleaned up documentation errors.
- Added support for OS X Ruby 1.8.7.

## 1.2.6 - 2012-04-22

- Cleaned up documentation errors.
- Added support for OS X Ruby 1.8.7.

## 1.2.5 - 2012-04-18

- Added support for create_id in Oj and in mimic_JSON mode

## 1.2.4 - 2012-04-13

- Removed all use of math.h to get around CentOS 5.4 compile problem.

## 1.2.3 - 2012-04-09

- Fixed compile error for the latest RBX on Travis.

## 1.2.2 - 2012-04-02

- minor bug fixes for different rubies along with test updates
- Oj::Doc will now automatically close on GC.

## 1.2.1 - 2012-03-30

- Organized compile configuration better.
- as_json() support now more flexible thanks to a contribution by sauliusg.

## 1.2.0 - 2012-03-30

- Removed the encoding option and fixed a misunderstanding of the string encoding. Unicode code points are now used instead of byte codes. This is not compatible with previous releases but is compliant with RFC4627.
- Time encoding in :object mode is faster and higher nanosecond precision.

## 1.1.1 - 2012-03-27

- The encoding option can now be an Encoding Object or a String.
- Fixed Rubinius errors.

## 1.1.0 - 2012-03-27

- Errors are not longer raised when comments are encountered in JSON documents.
- Oj can now mimic JSON. With some exceptions calling JSON.mimic_JSON will allow all JSON calls to use OJ instead of JSON. This gives a speedup of more than 2x on parsing and 5x for generating over the JSON::Ext module.
- Oj::Doc now allows a document to be left open and then closed with the Oj::Doc.close() class.
- Changed the default encoding to UTF-8 instead of the Ruby default String encoding.

## 1.0.6 - 2012-03-20

- Gave Oj::Doc a speed increase. It is now 8 times fast than JSON::Ext.

## 1.0.5 - 2012-03-17

- Added :ascii_only options for dumping JSON where all high-bit characters are encoded as escaped sequences.

## 1.0.4 - 2012-03-16

- Fixed bug that did not allow symbols as keys in :compat mode.

## 1.0.3 - 2012-03-15

- Added :symbol_keys option to convert String hash keys into Symbols.
- The load() method now supports IO Objects as input as well as Strings.

## 1.0.2 - 2012-03-15

- Added RSTRING_NOT_MODIFIED for Rubinius optimization.

## 1.0.1 - 2012-03-15

- Fixed compatibility problems with Ruby 1.8.7.

## 1.0.0 - 2012-03-13

- The screaming fast Oj::Doc parser added.

## 0.9.0 - 2012-03-05

- Added support for circular references.

## 0.8.0 - 2012-02-27

- Auto creation of data classes when unmarshalling Objects if the Class is not defined

## 0.7.0 - 2012-02-26

- changed the object JSON format
- serialized Ruby Objects can now be deserialized
- improved performance testing

## 0.6.0 - 2012-02-22

- supports arbitrary Object dumping/serialization
- to_hash() method called if the Object responds to to_hash and the result is converted to JSON
- to_json() method called if the Object responds to to_json
- almost any Object can be dumped, including Exceptions (not including Thread, Mutex and Objects that only make sense within a process)
- default options have been added

## 0.5.2 - 2012-02-19

- Release 0.5.2 fixes encoding and float encoding.
- This is the first release sith a version of 0.5 indicating it is only half done. Basic load() and dump() is supported for Hash, Array, NilClass, TrueClass, FalseClass, Fixnum, Float, Symbol, and String Objects.

## 0.5.1 - 2012-02-19


## 0.5 - 2012-02-19

- This is the first release with a version of 0.5 indicating it is only half done. Basic load() and dump() is supported for Hash, Array, NilClass, TrueClass, FalseClass, Fixnum, Float, Symbol, and String Objects.
