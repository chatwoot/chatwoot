# pg_search changelog

## 2.3.6

* Drop support for Ruby 2.5
* Support Ruby 3.1
* Support Active Record 7.0
* Don't require `:against` if `:tsvector_column` is specified (Travis Hunter)
* Optionally disable transaction when rebuilding documents (Travis Hunter)
* Preserve columns when chaining ::with_pg_search_highlight (jcsanti)

## 2.3.5

* Add table of contents to README (Barry Woolgar)
* Add support for Active Record 6.1

## 2.3.4

* Fix issue when setting various options directly on the `PgSearch` module while
  running with a threaded web server, such as Puma. (Anton Rieder)

## 2.3.3

* Drop support for Ruby < 2.5.
* Use keyword argument for `clean_up` setting in `PgSearch::Multisearch.rebuild`.

## 2.3.2

* Autoload `PgSearch::Document` to prevent it from being loaded in projects that are not using multi-search.
* Rebuilder should use `update_pg_search_document` if `additional_attributes` is set. (David Ramalho)

## 2.3.1

* Drop support for Active Record < 5.2.
* Do not load railtie unless Rails::Railtie is defined, to avoid problem when loading alongside Action Mailer. (Adam Schwartz)

## 2.3.0

* Extract `PgSearch::Model` module.
* Deprecate `include PgSearch`. Use `include PgSearch::Model` instead.

## 2.2.0

* Add `word_similarity` option to trigram search. (Severin Räz)

## 2.1.7

* Restore link to GitHub repository to original location.

## 2.1.6

* Update link to GitHub repository to new location.

## 2.1.5

* Drop support for Ruby < 2.4.

## 2.1.4

* Drop support for Ruby < 2.3.
* Use `update` instead of deprecated `update_attributes`.
* Remove explicit Arel dependency to better support Active Record 6 beta.

## 2.1.3

* Drop support for Ruby < 2.2
* Disallow left/right single quotation marks in tsquery. (Fabian Schwahn) (#382)
* Do not attempt to save an already-destroyed `PgSearch::Document`. (Oleg Dashevskii, Vokhmin Aleksei V) (#353)
* Quote column name when rebuilding. (Jed Levin) (#379)

## 2.1.2

* Silence warnings in Rails 5.2.0.beta2. (Kevin Deisz)

## 2.1.1

* Support snake_case `ts_headline` options again. (with deprecation warning)

## 2.1.0

* Allow `ts_headline` options to be passed to `:highlight`. (Ian Heisters)
* Wait to load `PgSearch::Document` until after Active Record has loaded. (Logan Leger)
* Add Rails version to generated migrations. (Erik Eide)

## 2.0.1

* Remove require for generator that no longer exists. (Joshua Bartlett)

## 2.0.0

* Drop support for PostgreSQL < 9.2.
* Drop support for Active Record < 4.2.
* Drop support for Ruby < 2.1.
* Improve performance of has_one and belongs_to associations. (Peter Postma)

## 1.0.6

* Add support for highlighting the matching portion of a search result. (Jose Galisteo)
* Add `:update_if` option to control when PgSearch::Document gets updated. (Adam Becker)
* Add `:additional_attributes` option for adding additional attributes to PgSearch::Document

## 1.0.5

* Clean up rank table aliasing. (Adam Milligan)
* Fix issue when using `#with_pg_search_rank` across a join. (Reid Lynch)

## 1.0.4

* Assert valid options for features. (Janko Marohnić)
* Enable chaining of pg_search scopes. (Nicolas Buduroi)

## 1.0.3

* Support STI models using a custom inheritance column. (Nick Doiron)

## 1.0.2

* Don’t use SQL to rebuild search documents when models are multisearchable against dynamic methods and not just columns. Iterate over each record with `find_each` instead.

## 1.0.1

* Call `.unscoped` on relation used to build subquery, to eliminate unnecessary JOINs. (Markus Doits)

## 1.0.0

* Support more `ActiveRecord::Relation` methods, such as `#pluck` and `#select` by moving search-related operations to subquery.
* Generate index by default in migration for `pg_search_documents` table.
* Start officially using [Semantic Versioning 2.0.0](http://semver.org/spec/v2.0.0.html).

## 0.7.9

* Improve support for single table inheritance (STI) models. (Ewan McDougall)

## 0.7.8

* Stop inadvertently including binstubs for guard and rspec.

## 0.7.7

* Fix future compatibility with Active Record 4.2.

## 0.7.6

* Fix migration generator in Rails 3. (Andrew Marshall and Nora Lin)
* Add `:only` option for limiting search fields per feature. (Jonathan Greenberg)

## 0.7.5

* Add option to make feature available only for sorting. (Brent Wheeldon)

## 0.7.4

* Fix which STI class name is used for searchable_type for PgSearch::Document. (Ewan McDougall)
* Add support for non-standard primary keys. (Matt Beedle)

## 0.7.3

* Allow simultaneously searching using `:associated_against` and `:tsvector_column` (Adam Becker)

## 0.7.2

* Add :threshold option for configuring how permissive trigram searches are.

## 0.7.1

* Fix issue with {:using => :trigram, :ignoring => :accents} that generated
  bad SQL. (Steven Harman)

## 0.7.0

* Start requiring Ruby 1.9.2 or later.

## 0.6.4

* Fix issue with using more than two features in the same scope.

## 0.6.3

* Fix issues and deprecations for Active Record 4.0.0.rc1.

## 0.6.2

* Add workaround for issue with how ActiveRecord relations handle Arel OR
  nodes.

## 0.6.1

* Fix issue with Arel::InfixOperation that prevented #count from working,
  breaking pagination.

## 0.6.0

* Drop support for Active Record 3.0.
* Address warnings in Ruby 2.0.
* Remove all usages of sanitize_sql_array for future Rails 4 compatibility.
* Start using Arel internally to build SQL strings (not yet complete).
* Disable eager loading, fixes issue #14.
* Support named schemas in pg_search:multisearch:rebuild. (Victor Olteanu)


## 0.5.7

* Fix issue with eager loading now that the Scope class has been removed.
  (Piotr Murach)


## 0.5.6

* PgSearch#multisearchable accepts :if and :unless for conditional inclusion
  in search documents table. (Francois Harbec)
* Stop using array_to_string() in SQL since it is not indexable.


## 0.5.5

* Fix bug with single table inheritance.
* Allow option for specifying an alternate function for unaccent().


## 0.5.4

* Fix bug in associated_against join clause when search scope is chained
  after other scopes.
* Fix autoloading of PgSearch::VERSION constant.


## 0.5.3

* Prevent multiple attempts to create pg_search_document within a single
  transaction. (JT Archie & Trace Wax)


## 0.5.2

* Don't save twice if pg_search_document is missing on update.


## 0.5.1

* Add ability to override multisearch rebuild SQL.


## 0.5

* Convert migration rake tasks into generators.
* Use rake task arguments for multisearch rebuild instead of environment
  variable.
* Always cast columns to text.


## 0.4.2

* Fill in timestamps correctly when rebuilding multisearch documents.
  (Barton McGuire)
* Fix various issues with rebuilding multisearch documents. (Eugen Neagoe)
* Fix syntax error in pg_search_dmetaphone() migration. (Casey Foster)
* Rename PgSearch#rank to PgSearch#pg_search_rank and always return a Float.
* Fix issue with :associated_against and non-text columns.


## 0.4.1

* Fix Active Record 3.2 deprecation warnings. (Steven Harman)

* Fix issue with undefined logger when PgSearch::Document.search is already
  defined.


## 0.4

* Add ability to search again tsvector columns. (Kris Hicks)


## 0.3.4

* Fix issue with {:using => {:tsearch => {:prefix => true}}} and hyphens.
* Get tests running against PostgreSQL 9.1 by using CREATE EXTENSION


## 0.3.3

* Backport array_agg() aggregate function to PostgreSQL 8.3 and earlier.
  This fixes :associated_against searches.
* Backport unnest() function to PostgreSQL 8.3 and earlier. This fixes
  {:using => :dmetaphone} searches.
* Disable {:using => {:tsearch => {:prefix => true}}} in PostgreSQL 8.3 and
  earlier.


## 0.3.2

* Fix :prefix search in PostgreSQL 8.x
* Disable {:ignoring => :accents} in PostgreSQL 8.x


## 0.3.1

* Fix syntax error in generated dmetaphone migration. (Max De Marzi)


## 0.3

* Drop Active Record 2.0 support.
* Add PgSearch.multisearch for cross-model searching.
* Fix PostgreSQL warnings about truncated identifiers
* Support specifying a method of rank normalisation when using tsearch.
  (Arthur Gunn)
* Add :any_word option to :tsearch which uses OR between query terms instead
  of AND. (Fernando Espinosa)

## 0.2.2

* Fix a compatibility issue between Ruby 1.8.7 and 1.9.3 when using Rails 2
  (James Badger)

## 0.2.1

* Backport support for searching against tsvector columns (Kris Hicks)

## 0.2

* Set dictionary to :simple by default for :tsearch. Before it was unset,
  which would fall back to PostgreSQL's default dictionary, usually
  "english".
* Fix a bug with search strings containing a colon ":"
* Improve performance of :associated_against by only doing one INNER JOIN
  per association

## 0.1.1

* Fix a bug with dmetaphone searches containing " w " (which dmetaphone maps
  to an empty string)

## 0.1

* Change API to {:ignoring => :accents} from {:normalizing => :diacritics}
* Improve documentation
* Fix bug where :associated_against would not work without an :against
  present

## 0.0.2

* Fix gem ownership.

## 0.0.1

* Initial release.
