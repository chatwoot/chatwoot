## 6.2.1 (2023-04-18)

- Fixed extra day with `DateTime` ranges

## 6.2.0 (2023-01-29)

- Added support for async methods with Active Record 7.1

## 6.1.0 (2022-04-05)

- Added `expand_range` option

## 6.0.1 (2022-01-16)

- Fixed incorrect results (error before 6.0) with `includes` with Active Record 6.1+

## 6.0.0 (2022-01-15)

- Raise `ActiveRecord::UnknownAttributeReference` for non-attribute arguments
- Raise `ArgumentError` for ranges with string bounds
- Added `n` option for Redshift
- Changed SQL to return dates instead of times for day, week, month, quarter, and year
- Removed `dates` option
- Dropped support for Ruby < 2.6 and Rails < 5.2

## 5.2.4 (2021-12-15)

- Simplified queries for Active Record 7 and MySQL

## 5.2.3 (2021-12-06)

- Fixed error and warnings with Active Record 7

## 5.2.2 (2021-02-08)

- Added support for `nil..nil` ranges in `range` option

## 5.2.1 (2020-09-09)

- Improved error message for invalid ranges
- Fixed bug with date string ranges

## 5.2.0 (2020-09-07)

- Added warning for non-attribute argument
- Added support for beginless and endless ranges in `range` option

## 5.1.0 (2020-07-30)

- Added `n` option to minute and second for custom durations

## 5.0.0 (2020-02-18)

- Added support for `week_start` for SQLite
- Added support for full weekday names
- Made `day_start` behavior consistent between Active Record and enumerable
- Made `last` option extend to end of current period
- Raise error when `day_start` and `week_start` passed to unsupported methods
- The `day_start` option no longer applies to shorter periods
- Fixed `inconsistent time zone info` errors around DST with MySQL and PostgreSQL
- Improved performance of `format` option
- Removed deprecated positional arguments for time zone and range
- Dropped support for `mysql` gem (last release was 2013)

## 4.3.0 (2019-12-26)

- Fixed error with empty results in Ruby 2.7
- Fixed deprecation warnings in Ruby 2.7
- Deprecated positional arguments for time zone and range

## 4.2.0 (2019-10-28)

- Added `day_of_year`
- Dropped support for Rails 4.2

## 4.1.2 (2019-05-26)

- Fixed error with empty data and `current: false`
- Fixed error in time zone check for Rails < 5.2
- Prevent infinite loop with endless ranges

## 4.1.1 (2018-12-11)

- Made column resolution consistent with `group`
- Added support for `alias_attribute`

## 4.1.0 (2018-11-04)

- Many performance improvements
- Added check for consistent time zone info
- Fixed error message for invalid queries with MySQL and SQLite
- Fixed issue with enumerable methods ignoring nils

## 4.0.2 (2018-10-15)

- Make `current` option work without `last`
- Fixed default value for `maximum`, `minimum`, and `average` (periods with no results now return `nil` instead of `0`, pass `default_value: 0` for previous behavior)

## 4.0.1 (2018-05-03)

- Fixed incorrect range with `last` option near time change

## 4.0.0 (2018-02-21)

- Custom calculation methods are supported by default - `groupdate_calculation_methods` is no longer needed

Breaking changes

- Dropped support for Rails < 4.2
- Invalid options now throw an `ArgumentError`
- `group_by` methods return an `ActiveRecord::Relation` instead of a `Groupdate::Series`
- `week_start` now affects `day_of_week`
- Removed support for `reverse_order` (was never supported in Rails 5)

## 3.2.1 (2018-02-21)

- Added `minute_of_hour`
- Added support for `unscoped`

## 3.2.0 (2017-01-30)

- Added limited support for SQLite

## 3.1.1 (2016-10-25)

- Fixed `current: false`
- Fixed `last` with `group_by_quarter`
- Raise `ArgumentError` when `last` option is not supported

## 3.1.0 (2016-10-22)

- Better support for date columns with `time_zone: false`
- Better date range handling for `range` option

## 3.0.2 (2016-08-09)

- Fixed `group_by_period` with associations
- Fixed `week_start` option for enumerables

## 3.0.1 (2016-07-13)

- Added support for Redshift
- Fix for infinite loop in certain cases for Rails 5

## 3.0.0 (2016-05-30)

Breaking changes

- `Date` objects are now returned for day, week, month, quarter, and year by default. Use `dates: false` for the previous behavior, or change this globally with `Groupdate.dates = false`.
- Array and hash methods no longer return the entire series by default. Use `series: true` for the previous behavior.
- The `series: false` option now returns the correct types and order, and plays nicely with other options.

## 2.5.3 (2016-04-28)

- All tests green with `mysql` gem
- Added support for decimal day start

## 2.5.2 (2016-02-16)

- Added `dates` option to return dates for day, week, month, quarter, and year

## 2.5.1 (2016-02-03)

- Added `group_by_quarter`
- Added `default_value` option
- Accept symbol for `format` option
- Raise `ArgumentError` if no field specified
- Added support for ActiveRecord 5 beta

## 2.5.0 (2015-09-29)

- Added `group_by_period` method
- Added `current` option
- Raise `ArgumentError` if no block given to enumerable

## 2.4.0 (2014-12-28)

- Added localization
- Added `carry_forward` option
- Added `series: false` option for arrays and hashes
- Fixed issue w/ Brasilia Summer Time
- Fixed issues w/ ActiveRecord 4.2

## 2.3.0 (2014-08-31)

- Raise error when ActiveRecord::Base.default_timezone is not `:utc`
- Added `day_of_month`
- Added `month_of_year`
- Do not quote column name

## 2.2.1 (2014-06-23)

- Fixed ActiveRecord 3 associations

## 2.2.0 (2014-06-22)

- Added support for arrays and hashes

## 2.1.1 (2014-05-17)

- Fixed format option with multiple groups
- Better error message if time zone support is missing for MySQL

## 2.1.0 (2014-03-16)

- Added last option
- Added format option

## 2.0.4 (2014-03-12)

- Added multiple groups
- Added order
- Subsequent methods no longer modify relation

## 2.0.3 (2014-03-11)

- Implemented respond_to?

## 2.0.2 (2014-03-11)

- where, joins, and includes no longer need to be before the group_by method

## 2.0.1 (2014-03-07)

- Use time zone instead of UTC for results

## 2.0.0 (2014-03-07)

- Returns entire series by default
- Added day_start option
- Better interface

## 1.0.5 (2014-03-06)

- Added global time_zone option

## 1.0.4 (2013-07-20)

- Added global week_start option
- Fixed bug with NULL values and series

## 1.0.3 (2013-07-05)

- Fixed deprecation warning when used with will_paginate
- Fixed bug with DateTime series

## 1.0.2 (2013-06-10)

- Added :start option for custom week start for group_by_week

## 1.0.1 (2013-06-03)

- Fixed series for Rails < 3.2 and MySQL

## 1.0.0 (2013-05-15)

- First major release
