## 5.5.2 (2025-05-20)

- Fixed `scope` option for partial reindex

## 5.5.1 (2025-04-24)

- Added support for `elasticsearch` 9 gem

## 5.5.0 (2025-04-03)

- Added `m` and `ef_construction` to `knn` index option
- Added `ef_search` to `knn` search option
- Fixed exact cosine distance for OpenSearch 2.19+
- Dropped support for Ruby < 3.2 and Active Record < 7.1
- Dropped support for Mongoid < 8

## 5.4.0 (2024-09-04)

- Added `knn` option
- Added `rrf` method
- Added experimental support for scripting to `where` option
- Added warning for `exists` with non-`true` values
- Added warning for full reindex and `:queue` mode
- Fixed `per_page` method when paginating beyond `max_result_window`
- Dropped support for Ruby < 3.1

## 5.3.1 (2023-11-28)

- Fixed error with misspellings below and failed queries

## 5.3.0 (2023-07-02)

- Fixed error with `cutoff_frequency`
- Dropped support for Ruby < 3 and Active Record < 6.1
- Dropped support for Mongoid < 7

## 5.2.4 (2023-05-11)

- Fixed error with non-string routing and `:async` mode

## 5.2.3 (2023-04-12)

- Fixed error with missing records and multiple models

## 5.2.2 (2023-04-01)

- Fixed `total_docs` method
- Fixed deprecation warning with Active Support 7.1

## 5.2.1 (2023-02-21)

- Added support for `redis-client` gem

## 5.2.0 (2023-02-08)

- Added model name to warning about missing records
- Fixed unnecessary data loading when reindexing relations with `:async` and `:queue` modes

## 5.1.2 (2023-01-29)

- Fixed error with missing point in time

## 5.1.1 (2022-12-05)

- Added support for strings for `offset` and `per_page`

## 5.1.0 (2022-10-12)

- Added support for fractional search timeout
- Fixed search timeout with `elasticsearch` 8+ and `opensearch-ruby` gems
- Fixed search timeout not applying to `multi_search`

## 5.0.5 (2022-10-09)

- Added `model` method to `Searchkick::Relation`
- Fixed deprecation warning with `redis` gem
- Fixed `respond_to?` method on relation loading relation
- Fixed `Relation loaded` error for non-mutating methods on relation

## 5.0.4 (2022-06-16)

- Added `max_result_window` option
- Improved error message for unsupported versions of Elasticsearch

## 5.0.3 (2022-03-13)

- Fixed context for index name for inherited models

## 5.0.2 (2022-03-03)

- Fixed index name for inherited models

## 5.0.1 (2022-02-27)

- Prefer `mode: :async` over `async: true` for full reindex
- Fixed instance method overriding with concerns

## 5.0.0 (2022-02-21)

- Searches now use lazy loading (similar to Active Record)
- Added `unscope` option to better support working with default scopes
- Added support for `:async` and `:queue` modes for `reindex` on relation
- Added basic protection from unfiltered parameters to `where` option
- Added `models` option to `similar` method
- Changed async full reindex to fetch ids instead of using ranges for numeric primary keys with Active Record
- Changed `searchkick_index_options` to return symbol keys (instead of mix of strings and symbols)
- Changed non-anchored regular expressions to match expected results (previously warned)
- Changed record reindex to return `true` to match model and relation reindex
- Updated async reindex job to call `search_import` for nested associations
- Fixed removing records when `should_index?` is `false` when `reindex` called on relation
- Fixed issue with `merge_mappings` for fields that use `searchkick` options
- Raise error when `search` called on relations
- Raise `ArgumentError` (instead of warning) for invalid regular expression modifiers
- Raise `ArgumentError` instead of `RuntimeError` for unknown operators
- Removed mapping of `id` to `_id` with `order` option (not supported in Elasticsearch 8)
- Removed `wordnet` option (no longer worked)
- Removed dependency on `elasticsearch` gem (can use `elasticsearch` or `opensearch-ruby`)
- Dropped support for Elasticsearch 6
- Dropped support for Ruby < 2.6 and Active Record < 5.2
- Dropped support for NoBrainer and Cequel
- Dropped support for `faraday_middleware-aws-signers-v4` (use `faraday_middleware-aws-sigv4` instead)

## 4.6.3 (2021-11-19)

- Added support for reloadable synonyms for OpenSearch
- Added experimental support for `opensearch-ruby` gem
- Removed `elasticsearch-xpack` dependency for reloadable synonyms

## 4.6.2 (2021-11-15)

- Added support for beginless ranges to `where` option
- Fixed `like` and `ilike` with `+` character
- Fixed warning about accessing system indices when no model or index specified

## 4.6.1 (2021-09-25)

- Added `ilike` operator for Elasticsearch 7.10+
- Fixed missing methods with `multi_search`

## 4.6.0 (2021-08-22)

- Added support for case-insensitive regular expressions with Elasticsearch 7.10+
- Added support for `OPENSEARCH_URL`
- Fixed error with `debug` option

## 4.5.2 (2021-08-05)

- Fixed error with reindex queue
- Fixed error with `model_name` method with multiple models
- Fixed error with `debug` option with elasticsearch-ruby 7.14

## 4.5.1 (2021-08-03)

- Improved performance of reindex queue

## 4.5.0 (2021-06-07)

- Added experimental support for OpenSearch
- Added support for synonyms in Japanese

## 4.4.4 (2021-03-12)

- Fixed `too_long_frame_exception` with `scroll` method
- Fixed multi-word emoji tokenization

## 4.4.3 (2021-02-25)

- Added support for Hunspell
- Fixed warning about accessing system indices

## 4.4.2 (2020-11-23)

- Added `missing_records` method to results
- Fixed issue with `like` and special characters

## 4.4.1 (2020-06-24)

- Added `stem_exclusion` and `stemmer_override` options
- Added `with_score` method to search results
- Improved error message for `reload_synonyms` with non-OSS version of Elasticsearch
- Improved output for reindex rake task

## 4.4.0 (2020-06-17)

- Added support for reloadable, multi-word, search time synonyms
- Fixed another deprecation warning in Ruby 2.7

## 4.3.1 (2020-05-13)

- Fixed error with `exclude` in certain cases for Elasticsearch 7.7

## 4.3.0 (2020-02-19)

- Fixed `like` queries with `"` character
- Better error when invalid parameters passed to `where`

## 4.2.1 (2020-01-27)

- Fixed deprecation warnings with Elasticsearch
- Fixed deprecation warnings in Ruby 2.7

## 4.2.0 (2019-12-18)

- Added safety check for multiple `Model.reindex`
- Added `deep_paging` option
- Added request parameters to search notifications and curl representation
- Removed curl from search notifications to prevent confusion

## 4.1.1 (2019-11-19)

- Added `chinese2` and `korean2` languages
- Improved performance of async full reindex
- Fixed `searchkick:reindex:all` rake task for Rails 6

## 4.1.0 (2019-08-01)

- Added `like` operator
- Added `exists` operator
- Added warnings for certain regular expressions
- Fixed anchored regular expressions

## 4.0.2 (2019-06-04)

- Added block form of `scroll`
- Added `clear_scroll` method
- Fixed custom mappings

## 4.0.1 (2019-05-30)

- Added support for scroll API
- Made type optional for custom mapping for Elasticsearch 6
- Fixed error when suggestions empty
- Fixed `models` option with inheritance

## 4.0.0 (2019-04-11)

- Added support for Elasticsearch 7
- Added `models` option

Breaking changes

- Removed support for Elasticsearch 5
- Removed support for multi-word synonyms (they no longer work with shingles)
- Removed support for Active Record < 5

## 3.1.3 (2019-04-11)

- Added support for endless ranges
- Added support for routing to `similar` method
- Added `prefix` to `where`
- Fixed error with elasticsearch-ruby 6.3
- Fixed error with some language stemmers and Elasticsearch 6.5
- Fixed issue with misspellings below and body block

## 3.1.2 (2018-09-27)

- Improved performance of indices boost
- Fixed deletes with routing and `async` callbacks
- Fixed deletes with routing and `queue` callbacks
- Fixed deprecation warnings
- Fixed field misspellings for older partial match format

## 3.1.1 (2018-08-09)

- Added per-field misspellings
- Added `case_sensitive` option
- Added `stem` option
- Added `total_entries` option
- Fixed `exclude` option with match all
- Fixed `with_highlights` method

## 3.1.0 (2018-05-12)

- Added `:inline` as alias for `true` for `callbacks` and `mode` options
- Friendlier error message for bad mapping with partial matches
- Warn when records in search index do not exist in database
- Easier merging for `merge_mapping`
- Fixed `with_hit` and `with_highlights` when records in search index do not exist in database
- Fixed error with highlights and match all

## 3.0.3 (2018-04-22)

- Added support for pagination with `body` option
- Added `boost_by_recency` option
- Fixed "Model Search Data" output for `debug` option
- Fixed `reindex_status` error
- Fixed error with optional operators in Ruby regexp
- Fixed deprecation warnings for Elasticsearch 6.2+

## 3.0.2 (2018-03-26)

- Added support for Korean and Vietnamese
- Fixed `Unsupported argument type: Symbol` for async partial reindex
- Fixed infinite recursion with multi search and misspellings below
- Do not raise an error when `id` is indexed

## 3.0.1 (2018-03-14)

- Added `scope` option for partial reindex
- Added support for Japanese, Polish, and Ukrainian

## 3.0.0 (2018-03-03)

- Added support for Chinese
- No longer requires fields to query for Elasticsearch 6
- Results can be marshaled by default (unless using `highlight` option)

Breaking changes

- Removed support for Elasticsearch 2
- Removed support for Active Record < 4.2 and Mongoid < 5
- Types are no longer used
- The `_all` field is disabled by default in Elasticsearch 5
- Conversions are not stemmed by default
- An `ArgumentError` is raised instead of a warning when options are incompatible with the `body` option
- Removed `log` option from `boost_by`
- Removed `Model.enable_search_callbacks`, `Model.disable_search_callbacks`, and `Model.search_callbacks?`
- Removed `reindex_async` method, as `reindex` now defaults to callbacks mode specified on the model
- Removed `async` option from `record.reindex`
- Removed `search_hit` method - use `with_hit` instead
- Removed `each_with_hit` - use `with_hit.each` instead
- Removed `with_details` - use `with_highlights` instead
- Bumped default `limit` to 10,000

## 2.5.0 (2018-02-15)

- Try requests 3 times before raising error
- Better exception when trying to access results for failed multi-search query
- More efficient aggregations with `where` clauses
- Added support for `faraday_middleware-aws-sigv4`
- Added `credentials` option to `aws_credentials`
- Added `modifier` option to `boost_by`
- Added `scope_results` option
- Added `factor` option to `boost_by_distance`

## 2.4.0 (2017-11-14)

- Fixed `similar` for Elasticsearch 6
- Added `inheritance` option
- Added `_type` option
- Fixed `Must specify fields to search` error when searching `*`

## 2.3.2 (2017-09-08)

- Added `_all` and `default_fields` options
- Added global `index_prefix` option
- Added `wait` option to async reindex
- Added `model_includes` option
- Added `missing` option for `boost_by`
- Raise error for `reindex_status` when Redis not configured
- Warn when incompatible options used with `body` option
- Fixed bug where `routing` and `type` options were silently ignored with `body` option
- Fixed `reindex(async: true)` for non-numeric primary keys in Postgres

## 2.3.1 (2017-07-06)

- Added support for `reindex(async: true)` for non-numeric primary keys
- Added `conversions_term` option
- Added support for passing fields to `suggest` option
- Fixed `page_view_entries` for Kaminari

## 2.3.0 (2017-05-06)

- Fixed analyzer on dynamically mapped fields
- Fixed error with `similar` method and `_all` field
- Throw error when fields are needed
- Added `queue_name` option
- No longer require synonyms to be lowercase

## 2.2.1 (2017-04-16)

- Added `avg`, `cardinality`, `max`, `min`, and `sum` aggregations
- Added `load: {dumpable: true}` option
- Added `index_suffix` option
- Accept string for `exclude` option

## 2.2.0 (2017-03-19)

- Fixed bug with text values longer than 256 characters and `_all` field - see [#850](https://github.com/ankane/searchkick/issues/850)
- Fixed issue with `_all` field in `searchable`
- Fixed `exclude` option with `word_start`

## 2.1.1 (2017-01-17)

- Fixed duplicate notifications
- Added support for `connection_pool`
- Added `exclude` option

## 2.1.0 (2017-01-15)

- Background reindexing and queues are officially supported
- Log updates and deletes

## 2.0.4 (2017-01-15)

- Added support for queuing updates [experimental]
- Added `refresh_interval` option to `reindex`
- Prefer `search_index` over `searchkick_index`

## 2.0.3 (2017-01-12)

- Added `async` option to `reindex` [experimental]
- Added `misspellings?` method to results

## 2.0.2 (2017-01-08)

- Added `retain` option to `reindex`
- Added support for attributes in highlight tags
- Fixed potentially silent errors in reindex job
- Improved syntax for `boost_by_distance`

## 2.0.1 (2016-12-30)

- Added `search_hit` and `search_highlights` methods to models
- Improved reindex performance

## 2.0.0 (2016-12-28)

- Added support for `reindex` on associations

Breaking changes

- Removed support for Elasticsearch 1 as it reaches [end of life](https://www.elastic.co/support/eol)
- Removed facets, legacy options, and legacy methods
- Invalid options now throw an `ArgumentError`
- The `query` and `json` options have been removed in favor of `body`
- The `include` option has been removed in favor of `includes`
- The `personalize` option has been removed in favor of `boost_where`
- The `partial` option has been removed in favor of `operator`
- Renamed `select_v2` to `select` (legacy `select` no longer available)
- The `_all` field is disabled if `searchable` option is used (for performance)
- The `partial_reindex(:method_name)` method has been replaced with `reindex(:method_name)`
- The `unsearchable` and `only_analyzed` options have been removed in favor of `searchable` and `filterable`
- `load: false` no longer returns an array in Elasticsearch 2

## 1.5.1 (2016-12-28)

- Added `client_options`
- Added `refresh` option to `reindex` method
- Improved syntax for partial reindex

## 1.5.0 (2016-12-23)

- Added support for geo shape indexing and queries
- Added `_and`, `_or`, `_not` to `where` option

## 1.4.2 (2016-12-21)

- Added support for directional synonyms
- Easier AWS setup
- Fixed `total_docs` method for ES 5+
- Fixed exception on update errors

## 1.4.1 (2016-12-11)

- Added `partial_reindex` method
- Added `debug` option to `search` method
- Added `profile` option

## 1.4.0 (2016-10-26)

- Official support for Elasticsearch 5
- Boost exact matches for partial matching
- Added `searchkick_debug` method
- Added `geo_polygon` filter

## 1.3.6 (2016-10-08)

- Fixed `Job adapter not found` error

## 1.3.5 (2016-09-27)

- Added support for Elasticsearch 5.0 beta
- Added `request_params` option
- Added `filterable` option

## 1.3.4 (2016-08-23)

- Added `resume` option to reindex
- Added search timeout to payload

## 1.3.3 (2016-08-02)

- Fix for namespaced models (broken in 1.3.2)

## 1.3.2 (2016-08-01)

- Added `body_options` option
- Added `date_histogram` aggregation
- Added `indices_boost` option
- Added support for multiple conversions

## 1.3.1 (2016-07-10)

- Fixed error with Ruby 2.0
- Fixed error with indexing large fields

## 1.3.0 (2016-05-04)

- Added support for Elasticsearch 5.0 alpha
- Added support for phrase matches
- Added support for procs for `index_prefix` option

## 1.2.1 (2016-02-15)

- Added `multi_search` method
- Added support for routing for Elasticsearch 2
- Added support for `search_document_id` and `search_document_type` in models
- Fixed error with instrumentation for searching multiple models
- Fixed instrumentation for bulk updates

## 1.2.0 (2016-02-03)

- Fixed deprecation warnings with `alias_method_chain`
- Added `analyzed_only` option for large text fields
- Added `encoder` option to highlight
- Fixed issue in `similar` method with `per_page` option
- Added basic support for multiple models

## 1.1.2 (2015-12-18)

- Added bulk updates with `callbacks` method
- Added `bulk_delete` method
- Added `search_timeout` option
- Fixed bug with new location format for `boost_by_distance`

## 1.1.1 (2015-12-14)

- Added support for `{lat: lat, lon: lon}` as preferred format for locations

## 1.1.0 (2015-12-08)

- Added `below` option to misspellings to improve performance
- Fixed synonyms for `word_*` partial matches
- Added `searchable` option
- Added `similarity` option
- Added `match` option
- Added `word` option
- Added highlighted fields to `load: false`

## 1.0.3 (2015-11-27)

- Added support for Elasticsearch 2.1

## 1.0.2 (2015-11-15)

- Throw `Searchkick::ImportError` for errors when importing records
- Errors now inherit from `Searchkick::Error`
- Added `order` option to aggregations
- Added `mapping` method

## 1.0.1 (2015-11-05)

- Added aggregations method to get raw response
- Use `execute: false` for lazy loading
- Return nil when no aggs
- Added emoji search

## 1.0.0 (2015-10-30)

- Added support for Elasticsearch 2.0
- Added support for aggregations
- Added ability to use misspellings for partial matches
- Added `fragment_size` option for highlight
- Added `took` method to results

Breaking changes

- Raise `Searchkick::DangerousOperation` error when calling reindex with scope
- Enabled misspellings by default for partial matches
- Enabled transpositions by default for misspellings

## 0.9.1 (2015-08-31)

- `and` now matches `&`
- Added `transpositions` option to misspellings
- Added `boost_mode` and `log` options to `boost_by`
- Added `prefix_length` option to `misspellings`
- Added ability to set env

## 0.9.0 (2015-06-07)

- Much better performance for where queries if no facets
- Added basic support for regex
- Added support for routing
- Made `Searchkick.disable_callbacks` thread-safe

## 0.8.7 (2015-02-14)

- Fixed Mongoid import

## 0.8.6 (2015-02-10)

- Added support for NoBrainer
- Added `stem_conversions: false` option
- Added support for multiple `boost_where` values on the same field
- Added support for array of values for `boost_where`
- Fixed suggestions with partial match boost
- Fixed redefining existing instance methods in models

## 0.8.5 (2014-11-11)

- Added support for Elasticsearch 1.4
- Added `unsearchable` option
- Added `select: true` option
- Added `body` option

## 0.8.4 (2014-11-05)

- Added `boost_by_distance`
- More flexible highlight options
- Better `env` logic

## 0.8.3 (2014-09-20)

- Added support for Active Job
- Added `timeout` setting
- Fixed import with no records

## 0.8.2 (2014-08-18)

- Added `async` to `callbacks` option
- Added `wordnet` option
- Added `edit_distance` option to eventually replace `distance` option
- Catch misspelling of `misspellings` option
- Improved logging

## 0.8.1 (2014-08-16)

- Added `search_method_name` option
- Fixed `order` for array of hashes
- Added support for Mongoid 2

## 0.8.0 (2014-07-12)

- Added support for Elasticsearch 1.2

## 0.7.9 (2014-06-30)

- Added `tokens` method
- Added `json` option
- Added exact matches
- Added `prev_page` for Kaminari pagination
- Added `import` option to reindex

## 0.7.8 (2014-06-22)

- Added `boost_by` and `boost_where` options
- Added ability to boost fields - `name^10`
- Added `select` option for `load: false`

## 0.7.7 (2014-06-10)

- Added support for automatic failover
- Fixed `operator` option (and default) for partial matches

## 0.7.6 (2014-05-20)

- Added `stats` option to facets
- Added `padding` option

## 0.7.5 (2014-05-13)

- Do not throw errors when index becomes out of sync with database
- Added custom exception types
- Fixed `offset` and `offset_value`

## 0.7.4 (2014-05-06)

- Fixed reindex with inheritance

## 0.7.3 (2014-04-30)

- Fixed multi-index searches
- Fixed suggestions for partial matches
- Added `offset` and `length` for improved pagination

## 0.7.2 (2014-04-24)

- Added smart facets
- Added more fields to `load: false` result
- Fixed logging for multi-index searches
- Added `first_page?` and `last_page?` for improved Kaminari support

## 0.7.1 (2014-04-12)

- Fixed huge issue w/ zero-downtime reindexing on 0.90

## 0.7.0 (2014-04-10)

- Added support for Elasticsearch 1.1
- Dropped support for Elasticsearch below 0.90.4 (unfortunate side effect of above)

## 0.6.3 (2014-04-08)

- Removed patron since no support for Windows
- Added error if `searchkick` is called multiple times

## 0.6.2 (2014-04-05)

- Added logging
- Fixed index_name option
- Added ability to use proc as the index name

## 0.6.1 (2014-03-24)

- Fixed huge issue w/ zero-downtime reindexing on 0.90 and elasticsearch-ruby 1.0
- Restore load: false behavior
- Restore total_entries method

## 0.6.0 (2014-03-22)

- Moved to elasticsearch-ruby
- Added support for modifying the query and viewing the response
- Added support for page_entries_info method

## 0.5.3 (2014-02-24)

- Fixed bug w/ word_* queries

## 0.5.2 (2014-02-12)

- Use after_commit hook for Active Record to prevent data inconsistencies

## 0.5.1 (2014-02-12)

- Replaced stop words with common terms query
- Added language option
- Fixed bug with empty array in where clause
- Fixed bug with MongoDB integer _id
- Fixed reindex bug when callbacks disabled

## 0.5.0 (2014-01-20)

- Better control over partial matches
- Added merge_mappings option
- Added batch_size option
- Fixed bug with nil where clauses

## 0.4.2 (2013-12-29)

- Added `should_index?` method to control which records are indexed
- Added ability to temporarily disable callbacks
- Added custom mappings

## 0.4.1 (2013-12-19)

- Fixed issue w/ inheritance mapping

## 0.4.0 (2013-12-11)

- Added support for Mongoid 4
- Added support for multiple locations

## 0.3.5 (2013-12-08)

- Added facet ranges
- Added all operator

## 0.3.4 (2013-11-22)

- Added highlighting
- Added :distance option to misspellings
- Fixed issue w/ BigDecimal serialization

## 0.3.3 (2013-11-04)

- Better error messages
- Added where: {field: nil} queries

## 0.3.2 (2013-11-02)

- Added support for single table inheritance
- Removed Tire::Model::Search

## 0.3.1 (2013-11-02)

- Added index_prefix option
- Fixed ES issue with incorrect facet counts
- Added option to turn off special characters

## 0.3.0 (2013-11-02)

- Fixed reversed coordinates
- Added bounded by a box queries
- Expanded `or` queries

## 0.2.8 (2013-09-30)

- Added option to disable callbacks
- Fixed bug with facets with Elasticsearch 0.90.5

## 0.2.7 (2013-09-23)

- Added limit to facet
- Improved similar items

## 0.2.6 (2013-09-10)

- Added option to disable misspellings

## 0.2.5 (2013-08-30)

- Added geospartial searches
- Create alias before importing document if no alias exists
- Fixed exception when :per_page option is a string
- Check `RAILS_ENV` if `RACK_ENV` is not set

## 0.2.4 (2013-08-20)

- Use `to_hash` instead of `as_json` for default `search_data` method
- Works for Mongoid 1.3
- Use one shard in test environment for consistent scores

## 0.2.3 (2013-08-16)

- Setup Travis
- Clean old indices before reindex
- Search for `*` returns all results
- Fixed pagination
- Added `similar` method

## 0.2.2 (2013-08-11)

- Clean old indices after reindex
- More expansions for fuzzy queries

## 0.2.1 (2013-08-11)

- Added Rails logger
- Only fetch ids when `load: true`

## 0.2.0 (2013-08-10)

- Added autocomplete
- Added “Did you mean” suggestions
- Added personalized searches

## 0.1.4 (2013-08-03)

- Bug fix

## 0.1.3 (2013-08-03)

- Changed edit distance to one for misspellings
- Raise errors when indexing fails
- Fixed pagination
- Fixed :include option

## 0.1.2 (2013-07-30)

- Use conversions by default

## 0.1.1 (2013-07-29)

- Renamed `_source` to `search_data`
- Renamed `searchkick_import` to `search_import`

## 0.1.0 (2013-07-28)

- Added `_source` method
- Added `index_name` option

## 0.0.2 (2013-07-17)

- Added `conversions` option

## 0.0.1 (2013-07-14)

- First release
