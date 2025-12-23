## Changes in 2.1.0

### New Features

* Add Support for `active_record_proxy_adapters` gem thanks to @stingrayzboy via #\867.
  Since Rails 7.1 makara no longer works and it is not currently maintained. The @nasdaq team
  have written a gem called [active_record_proxy_adapters](https://rubygems.org/gems/active_record_proxy_adapters)
  that implements some makara functionality.

## Changes in 2.0.0

### Breaking Changes

* Fix `recursive_on_duplicate_key_update` doesn't work with non-standard
  association name. Thanks to @jacob-carlborg-apoex via \#852. The documentation for the
  `:recursive_on_duplicate_key_update` option specifies that the hash key is
  the association name. But previously the name of associated table was used to
  look up the options. Now the behavior matches the documentation and the name
  of the association is used instead. This only affects associations that uses
  a name that doesn't follow the ActiveRecord naming conventions of
  associations and class names, i.e. when the `class_name:` option is used on
  an association.

## Changes in 1.8.1

### Fixes

* Further update for ActiveRecord 7.2 compatibility when running validations. Thanks to @denisahearn  via \##847.

## Changes in 1.8.0

### New Features

* Add support for ActiveRecord 7.2 via \##845.

## Changes in 1.7.0

### New Features

* Add support for ActiveRecord 7.1 composite primary keys. Thanks to @fragkakis via \##837.
* Add support for upserting associations when doing recursive imports. Thanks to @ramblex via \##778.

## Changes in 1.6.0

### New Features

* Add trilogy adapter support. Thanks to @zmariscal via \##825.

### Fixes

* Use the locking_enabled? method provided by activerecord to decide whether the lock field should be updated. Thanks to @dombesz via \##822.

## Changes in 1.5.1

### Fixes

* Stop memoizing schema_columns_hash so dynamic schema changes are picked up. Thanks to @koshigoe via \##812.

## Changes in 1.5.0

### New Features

* Add Rails 7.1 support. Thanks to @gucki via \##807.
* Add support for alias attributes. Thanks to @leonidkroka via \##799.

### Fixes

* Support for multi-byte column names when splitting queries. Thanks to @TakuyaKurimoto via \##801.
* Fix issue with track_validation_failures when import models. Thanks to @OtaYohihiro via \##798.

## Changes in 1.4.1

### Fixes

* Fix importing models that have required belongs_to associations and use composite primary keys. Thanks to @thoughtbot-summer via \##783.

## Changes in 1.4.0

### New Features

  * Enable compatibility with frozen string literals. Thanks to @desheikh via \##760.

## Changes in 1.3.0

### Fixes

* Ensure correct timestamp values are returned for models after insert. Thanks to @kos1kov via \##756.
* Restore database_version method to public scope. Thanks to @beauraF via \##753.

### New Features

* Add support for ActiveRecord 7.0. Thanks to @nickhammond, @ryanwood, @jkowens via \##749 and \##752.
* Add support for compound foreign keys. Thanks to @Uladzimiro via \##750.
* Add support for :recursive combined with on_duplicate_key_update: :all. Thanks to @deathwish via \##746.

## Changes in 1.2.0

### Fixes

* Update JDBC MySQL adapter to use mysql2 connection adapter. Thanks to @terencechow via \##744.
* Fix importing STI models with ActiveRecord 6. Thanks to @clemens1483 via \##743.
* Use polymorphic_name instead of base_class.name for imports. Thanks to @kmhajjar via \##741.
* Fix compatibility issue with composite primary keys. Thanks to @dlanileonardo via \##737.
* Prevent double validation of associations on recursive import.

## Changes in 1.1.0

### New Features

*  Add batch progress reporting. Thanks to @gee-forr via \##729.

## Changes in 1.0.8

### Fixes

* Use correct method for clearing query cache. Thanks to @EtienneDepaulis via \##719.

## Changes in 1.0.7

### New Features

* Use @@max_allowed_packet session variable instead of querying SHOW VARIABLES. Thanks to @diclophis via \#706.
* Add option :track_validation_failures. When this is set to true, failed_instances will be an array of arrays, with each inner array having the form [:index_in_dataset, :object_with_errors]. Thanks to @rorymckinley  via \#684.

### Fixes

* Prevent mass-assignment errors in Rails strict mode. Thanks to @diclophis via \##709.

## Changes in 1.0.6

### Fixes

* Handle after_initialize callbacks. Thanks to @AhMohsen46 via \#691 and
  \#692.
* Fix regression introduced in 1.0.4. Explicitly allow adapters to
  support on duplicate key update. Thanks to @dsobiera, @jkowens via \#696.

## Changes in 1.0.5

### Fixes

* Allow serialized attributes to be returned from import. Thanks to @timanovsky, @jkowens via \#660.
* Return ActiveRecord::Connection from
  ActiveRecord::Base#establish_connection. Thanks to @reverentF via
\#663.
* Support PostgreSQL array. Thanks to @ujihisa via \#669.
* Skip loading association ids when column changed. Thanks to @Aristat
  via \#673.

## Changes in 1.0.4

### Fixes

* Use prepend pattern for ActiveRecord::Base#establish_connection patching. Thanks to @dombesz via \#648.
* Fix NoMethodError when using PostgreSQL ENUM types. Thanks to @sebcoetzee via \#651.
* Fix issue updating optimistic lock in Postgres. Thanks to @timanovsky
  via \#656.

## Changes in 1.0.3

### New Features

* Add support for ActiveRecord 6.1.0.alpha. Thanks to @imtayadeway via
  \#642.

### Fixes

* Return an empty array for results instead of nil when importing empty
  array. Thanks to @gyfis via \#636.

## Changes in 1.0.2

### New Features

* Add support for CockroachDB adapter. Thanks to @willie via \#605.
* Add support for ActiveRecord 6.0.0.rc1. Thanks to @madeindjs, @bill-filler,
  @jkowens via \#619, \#623.

### Fixes

* Fixes NoMethodError when attempting to use nil logger. Thanks to @MattMecel,
  @khiav22357.
* Fix issue validating STI models. Thanks to @thejbsmith, @jkowens via
  \#626.

## Changes in 1.0.1

### Fixes

* Raise an error with a helpful message if array of values exceeds the number of
  columns for a table. Thanks to @golddranks via \#589.
* Properly check if model responds to import before creating alias.
  Thanks to @jcw- via \#591.
* No longer pass :returning option to child associations on recursive
  import. Thanks to @dmitriy-kiriyenko via \#595.
* Fix import issue for models with Postgresql json/jsonb fields. Thanks
  to @stokarenko via \#594.
* Fix issue importing models with timestamps that contain timezone
  information. Thanks to @dekaikiwi, @jkowens via \#598.
* Ignore :no_returning when using :recursive option. Thanks to @dgollahon, @jkowens
  via \#599.

## Changes in 1.0.0

### New Features

* Move ActiveRecord::Dirty changes to previous_changes after import.
  Thanks to @stokarenko via \#584.

### Breaking Changes

* Previously :on_duplicate_key_update was enabled by default for MySQL.
  The update timestamp columns (updated_at, updated_on) would be updated
  on duplicate key. This was behavior is inconsistent with the other database
  adapters and could also be considered surprising. Going forward it must
  be explicitly enabled. See \#548.

## Changes in 0.28.2

### Fixes

* Fix issue where validations where not working in certain scenarios.
  Thanks to @CASIXx1 via \#579.

## Changes in 0.28.1

### Fixes

* Fix issue where ActiveRecord presence validations were being mutated.
  Limited custom presence validation to bulk imports.

## Changes in 0.28.0

### New Features

* Allow updated timestamps to be manually set.Thanks to @Rob117, @jkowens via \#570.

### Fixes

* Fix validating presence of belongs_to associations. Existence
  of the parent record is not validated, but the foreign key field
  cannot be empty. Thanks to @Rob117, @jkowens via \#575.

## Changes in 0.27.0

### New Features

* Add "secret" option validate_uniqueness to enable uniqueness
  validators when validating import. This is not a recommended
  approach (See #228), but is being added back in for projects
  that depended on this feature. Thanks to @jkowens via \#554.

## Changes in 0.26.0

### New Features

* Add  on_duplicate_key_update for SQLite. Thanks to @jkowens via \#542.
* Add option to update all fields on_duplicate_key_update. Thanks to @aimerald, @jkowens via \#543.

### Fixes

* Handle deeply frozen options hashes. Thanks to @jturkel via \#546.
* Switch from FactoryGirl to FactoryBot. Thanks to @koic via \#547.
* Allow import to work with ProxySQL. Thanks to @GregFarrell via \#550.

## Changes in 0.25.0

### New Features

* Add support for makara_postgis adapter. Thanks to @chadwilken via \#527.
* Skip validating presence of belongs_to associations. Thanks to @Sohair63, @naiyt, @jkowens via \#528.

### Fixes

* Add missing require for ActiveSupport.on_load. Thanks to @onk via \#529.
* Support setting attribute values in before_validation callbacks.
  Thanks to @SirRawlins, @jkowens via \#531.
* Ignore virtual columns. Thanks to @dbourguignon, @jkowens via \#530.

## Changes in 0.24.0

### Fixes

* Use the association primary key when importing. Thanks to @dpogue via \#512.
* Allow association ids to be updated. Thanks to @Aristat via \#515.

## Changes in 0.23.0

### New Features

* Rename `import` method to `bulk_import` and alias to `import`. Thanks
  to @itay-grudev, @jkowens via \#498.
* Increment lock_version on duplicate key update. Thanks to @aimerald
  via \#500.

### Fixes

* Fix import_without_validations_or_callbacks exception if array is empty.
  Thanks to @doloopwhile via \#508.

## Changes in 0.22.0

### New Features

* Add support for importing hashes thru a has many association. Thanks
  to @jkowens via \#483.

### Fixes

* Fix validation logic for recursive import. For those on Rails 5.0 and 5.1,
  this change requires models with polymorphic associations to specify the `inverse_of`
  argument (See issue #495). Thanks to @eric-simonton-sama, @jkowens via
  \#489.

## Changes in 0.21.0

### New Features

* Allow SQL subqueries (objects that respond to .to_sql) to be passed as values. Thanks
  to @jalada, @jkowens via \#471
* Raise an ArgumentError when importing an array of hashes if any of the
  hash objects have different keys. Thanks to @mbell697 via \#465.

### Fixes

* Fix issue loading incorrect foreign key value when syncing belongs_to
  associations with custom foreign key columns. Thanks to @marcgreenstock, @jkowens via \#470.
* Fix issue importing models with polymorphic belongs_to associations.
  Thanks to @zorab47, @jkowens via \#476.
* Fix issue importing STI models with ActiveRecord 4.0. Thanks to
  @kazuki-st, @jkowens via \#478.

## Changes in 0.20.2

### Fixes

* Unscope model when synchronizing with database. Thanks to @indigoviolet via \#455.

## Changes in 0.20.1

### Fixes

* Prevent :on_duplicate_key_update args from being modified. Thanks to @joshuamcginnis, @jkowens via \#451.

## Changes in 0.20.0

### New Features

* Allow returning columns to be specified for PostgreSQL. Thanks to
  @tjwp via \#433.

### Fixes

* Fixes an issue when bypassing uniqueness validators. Thanks to @vmaxv via \#444.
* For AR < 4.2, prevent type casting for binary columns on Postgresql. Thanks to @mwalsher via \#446.
* Fix issue logging class name on import. Thanks to @sophylee, @jkowens via \#447.
* Copy belongs_to association id to foreign key column before importing. Thanks to @jkowens via \#448.
* Reset model instance on validate. Thanks to @vmaxv via \#449.

## Changes in 0.19.1

### Fixes

* Fix a regression where models weren't properly being marked clean. Thanks to @tjwp via \#434.
* Raise ActiveRecord::Import::ValueSetTooLargeError when a record being inserted exceeds the
  `max_allowed_packet` for MySQL. Thanks to @saizai, @jkowens via \#437.
* Fix issue concatenating column names array with primary key. Thanks to @keeguon via \#440.

## Changes in 0.19.0

### New Features

* For PostgreSQL, add option to set WHERE condition in conflict_action. Thanks to
  @Saidbek via \#423.

### Fixes

* Fix issue importing saved records with serialized fields. Thanks to
  @Andreis13, @jkowens via \#425.
* Fix issue importing records that have columns defined with default values
  that are functions or expressions. Thanks to @Andreis13, @jkowens via \#428.

## Changes in 0.18.3

### Fixes

* Set models new_record attribute to false when importing with
  :on_duplicate_key_ignore. Thanks to @nijikon, @jkowens via \#416.

## Changes in 0.18.2

### Fixes

* Enable custom validate callbacks when validating import. Thanks to @afn via \#410.
* Prevent wrong IDs being set on models when using :on_duplicate_key_ignore.
  Thanks to @afn, @jkowens via \#412.

## Changes in 0.18.1

### Fixes

* Fix to enable validation callbacks (before_validation,
  after_validation). Thanks to @sinsoku, @jkowens via \#406.

## Changes in 0.18.0

### New Features

* Uniqueness validation is bypassed when validating models since
  it cannot be guaranteed if there are duplicates in a batch.
  Thanks to @jkowens via \#301.
* Allow for custom timestamp columns. Thanks to @mojidabckuu, @jkowens
  via \#401.

### Fixes

* Fix ActiveRecord 5 issue coercing boolean values when serializing
  for the database. Thanks to @rjrobinson, @jkowens via \#403.

## Changes in 0.17.2

### Fixes

* Fix issue where PostgreSQL cannot recognize columns if names
  include mixed case characters. Thanks to @hugobgranja via \#379.
* Fix an issue for ActiveRecord 5 where serialized fields with
  default values were not being typecast. Thanks to @whistlerbrk,
  @jkowens via \#386.
* Add option :force_single_insert for MySQL to make sure a single
  insert is attempted instead of performing multiple inserts based
  on max_allowed_packet. Thanks to @mtparet via \#387.

## Changes in 0.17.1

### Fixes

* Along with setting id on models for adapters that support it,
  add created_at and updated_at timestamps. Thanks to @jacob-carlborg
  via \#364.
* Properly set returned ids when using composite_primary_keys.
  Thanks to @guigs, @jkowens via \#371.

## Changes in 0.17.0

### New Features

* Add support for composite_primary_keys gem. Thanks to @jkowens
  via \#350.
* Add support for importing an array of hashes. Thanks to @jkowens
  via \#352.
* Add JDBC SQLite3 support. Thanks to @jkowens via \#356.

### Fixes

* Remove support for SQLite recursive imports. See \#351.
* Improve import speed for Rails 5. Thanks to @ranchodeluxe, @jkowens
  via \#359.

## Changes in 0.16.2

### Fixes

* Fixes issue clearing query cache on wrong connection when using
  multiple databases. Thanks to @KentoMoriwaki via \#337
* Raises an ArgumentError on incorrect usage of nested arrays. Thanks
  to @Nitrodist via \#340
* Fixes issue that prevented uuid primary keys from being set manually.
  Thanks to @Dclusin-og, @jkowens via \#342

## Changes in 0.16.1

### Fixes

* Fixes issue with missing error messages on failed instances when
  importing using arrays of columns and values. Thanks to @Fivell via \#332
* Update so SQLite only return ids if table has a primary key field via \#333


## Changes in 0.16.0

### New Features

* Add partial index upsert support for PostgreSQL. Thanks to @luislew via \#305
* Add UUID primary key support for PostgreSQL. Thanks to @jkowens via
  \#312
* Add store accessor support for JSON, JSON, and HSTORE data types.
  Thanks to @jkowens via \#322
* Log warning if database does not support :on_duplicate_key_update.
  Thanks to @jkowens via \#324
* Add option :on_duplicate_key_ignore for MySQL and SQLite. Thanks to
  @jkowens via \#326

### Fixes

* Fixes issue with recursive import using same primary key for all models.
  Thanks to @chopraanmol1 via \#309
* Fixes issue importing from STI subclass with polymorphic associations.
  Thanks to @JNajera via \#314
* Fixes issue setting returned IDs to wrong models when some fail validation. Also fixes issue with SQLite returning wrong IDs. Thanks to @mizukami234 via \#315


## Changes in 0.15.0

### New Features

* An ArgumentError is now raised if when no `conflict_target` or `conflict_name` is provided or can be determined when using the `on_duplicate_key_update` option for PostgreSQL. Thanks to @jkowens via \#290
* Support for Rails 5.0 final release for all except the JDBC driver which is not yet updated to support Rails 5.0

### Fixes

* activerecord-import no longer modifies a value array inside of the given values array when called with `import(columns, values)`. Thanks to @jkowens via \#291

### Misc

* `raise_error` is used to raise errors for ActiveRecord 5.0. Thanks to @couragecourag via \#294 `raise_record_invalid` has been


## Changes in 0.14.1

### Fixes

* JRuby/JDBCDriver with PostgreSQL will no longer raise a JDBCDriver error when using the :no_returning boolean option. Thanks to @jkowens via \#287

## Changes in 0.14.0

### New Features

* Support for ActiveRecord 3.1 has been dropped. Thanks to @sferik via \#254
* SQLite3 has learned the :recursive option. Thanks to @jkowens via \#281
* :on_duplicate_key_ignore will be ignored when imports are being done with :recursive. Thanks to @jkowens via \#268
* :activerecord-import learned how to tell PostgreSQL to return no data back from the import via the :no_returning boolean option. Thanks to @makaroni4 via \#276

### Fixes

* Polymorphic associations will not import the :type column. Thanks to @seanlinsley via \#282 and \#283
* ~2X speed increase for importing models with validations. Thanks to @jkowens via \#266

### Misc

* Benchmark HTML report has been fixed. Thanks to @jkowens via \#264
* seamless_database_pool has been updated to work with AR 5.0. Thanks to @jkowens via \#280
* Code cleanup, removal of redundant condition checks. Thanks to @pavlik4k via \#273
* Code cleanup, removal of deprecated `alias_method_chain`. Thanks to @codeodor via \#271


## Changes in 0.13.0

### New Features

* Addition of :batch_size option to control the number of rows to insert per INSERT statement. The default is the total number of records being inserted so there is a single INSERT statement. Thanks to @jkowens via \#245

* Addition `import!` which will raise an exception if a validation occurs. It will fail fast. Thanks to @jkowens via \#246

### Fixes

* Fixing issue with recursive import when utilizing the `:on_duplicate_key_update` option. The `on_duplicate_key_update` only applies to parent models at this time. Thanks to @yuri-karpovich for reporting and  @jkowens for fixing via \#249

### Misc

* Refactoring of fetching and assigning attributes. Thanks to @jkownes via \#259
* Lots of code cleanup and addition of Rubocop linter. Thanks to @sferik via \#256 and \#250
* Resolving errors with the test suite when running against ActiveRecord 4.0 and 4.1. Thanks to @jkowens via \#262
* Cleaning up the TravisCI settings and packages. Thanks to @sferik via \#258 and \#251

## Changes in 0.12.0

### New Features

* PostgreSQL UPSERT support has been added. Thanks @jkowens via \#218

### Fixes

* has_one and has_many associations will now be recursively imported regardless of :autosave being set. Thanks @sferik, @jkowens via \#243, \#234
* Fixing an issue with enum column support for Rails > 4.1. Thanks @aquajach via \#235

### Removals

* Support for em-synchrony has been removed since it appears the project has been abandoned. Thanks @sferik, @zdennis via \#239
* Support for the mysql gem/adapter has been removed since it has officially been abandoned. Use the mysql2 gem/adapter instead. Thanks @sferik, @zdennis via \#239

### Misc

* Cleaned up TravisCI output and removing deprecation warnings. Thanks @jkowens, @zdennis \#242


## Changes before 0.12.0

> Never look back. What's gone is now history. But in the process make memory of events to help you understand what will help you to make your dream a true story. Mistakes of the past are lessons, success of the past is inspiration. – Dr. Anil Kr Sinha
