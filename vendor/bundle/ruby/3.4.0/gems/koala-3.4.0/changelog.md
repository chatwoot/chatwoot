Unreleased
==========

**Key breaking changes:**

New features:

Updated features:

Removed features:

Internal improvements:

Testing improvements:

Others:

v3.4.0 (2023-01-05)
======

Updated features:

* Force use by default of HTTPS (instead of HTTP) when there is no access token.
  HTTP can still be used by passing :use_ssl => false in the options hash for an api call ([#678](https://github.com/arsduo/koala/pull/678/files))

v3.3.0 (2022-09-27)
======

Updated features:

  * Removed restriction on faraday < 2 ([#666](https://github.com/arsduo/koala/pull/666))

Internal improvements:

 * Remove multipart hack and use default faraday multipart middleware ([#664](https://github.com/arsduo/koala/pull/664))

Testing improvements:

 * Fix tests with ruby-head ([#674](https://github.com/arsduo/koala/pull/674))
 * Keep supported rubies (non EOL) for CI ([#675](https://github.com/arsduo/koala/pull/675))

v3.2.0 (2022-05-27)
======

New features:

  * Exposes limiting headers(`x-business-use-case-usage, x-ad-account-usage, x-app-usage`) to APIError ([#668](https://github.com/arsduo/koala/pull/668))
  * Add `rate_limit_hook` configuration to get rate limiting headers (`x-business-use-case-usage, x-ad-account-usage, x-app-usage`) ([#670](https://github.com/arsduo/koala/pull/670))

Testing improvements:

* Fix builds for ruby 3.x

v3.1.0 (2022-01-18)
======

New features:

* mask_tokens config (default: true) to mask tokens in logs

Updated features:

* Log before and after sending request

Internal improvements:

* Lock Faraday to < 2
* Compatibility with ruby 3.x

Testing improvements:

* Use Github actions for CI
* Run CI on latest rubies

v3.0.0 (2017-03-17)
======

Most users should not see any difference upgrading from 2.x to 3.0. Most of the changes are
internal to how requests go from a graph method (like `get_connections`) through the API to the
HTTP layer and back. If you're not using API#api or HTTPService.make_request directly, upgrading
should (in theory) require no code changes. (Let me know if you run into any issues.)

**Key breaking changes:**

* Koala now requires Ruby 2.1+ (or equivalent for JRuby, etc.)
* API#api now returns a Koala::HTTPService::Response object; graph_call handles further processing
* GraphBatchAPI no longer inherits from API (the interface is otherwise unchanged)
* Empty response bodies in batch API calls will raise a JSON::ParserError rather than returning nil
* HTTPService.make_request now requires an HTTPService::Request object (Koala.make_request does
  not)
* HTTPService behavior *should not* change, but in edge cases might. (If so, please let me know.)
* API#search now requires a "type"/:type argument, matching Facebook's behavior (improving their
  cryptic error message)

New features:

* Koala now supports global configuration for tokens, secrets, etc! See the readme.
* GraphCollection now exposes #headers, allowing access to etag/rate limiting/etc. info (thanks,
  pawandubey and jessieay!) (#589)

Updated features:

* Koala.config now uses a dedicated Koala::Configuration object
* TestUser#befriend will provide the appsecret_proof if a secret is set (thanks, kwasimensah!)
* API#search now requires an object type parameter to be included, matching Facebook's API (#575)
* RealtimeUpdates will now only fetch the app access token if necessary, avoiding unnecessary calls

Removed features:

* Removed support for the Rest API, since Facebook removed support for it (#568)
* Removed support for FQL, which Facebook removed on August 8, 2016 (#569)
* Removed legacy duplication of serveral constants in the Koala module (#569)
* Removed API#get_comments_for_urls, which pointed to a no-longer-extant endpoint(#570)

Internal improvements:

* Completely rewrote HTTPService.make_request and several others, extracting most logic into
  HTTPService::Request (#566)
* API#api now returns a Koala::HTTPService::Response object (#584)
* GraphBatchAPI no longer inherits from API (#580)
* GraphBatchAPI has been refactored to be simpler and more readable (thanks, acuppy!) (#551)
* Use the more secure JSON.parse instead of JSON.load (thanks, lautis!) (#567)
* Use JSON's quirks_mode option to remove hacky JSON hack (#573 -- thanks sakuro for the
  suggestion!)
* The gemspec now allows both JSON 1.8 and 2.0 (#596) (thanks, pawandubey!)
* Remove Autotest and Guard references (no longer used/needed)

Testing improvements:

* Fixed a bunch of failing mocked specs

Others:

* Added an issue and pull request template
* Updated Code of Conduct to 1.4

v2.5.0 (2017-02-17)
======

New features:

* API#get_object_metadata provides a convenient accessor to an object's graph metadata (thanks, sancopanco!)

Documentation improvements:

* Add explicit require to examples in readme.md (thanks, dwkns!)

Internal improvements:

* Remove MultiJson dependency (thanks, sakuro!)

v2.4.0 (2016-07-08)
======

**Note:** Koala is no longer officially supported on Ruby 1.9.3 (which was [end-of-lifed back in
2015](https://www.ruby-lang.org/en/news/2014/01/10/ruby-1-9-3-will-end-on-2015/)). Versions may
still work (until version 3.0, when we may start using keyword arguments), but will not be tested
on 1.9.3.

Updated features:

* Batch API requests will now properly calculate appsecret_proofs for multiple access tokens
  (thanks, mwpastore!)

Internal improvements:

* Koala now explicitly depends on MultiJson >= 1.3.0, since it uses methods introduced in that
  version

Testing improvements:

* Test Koala against Ruby 2.3.0 (thanks, thedrow!)


v2.3.0 (2016-04-10)
======

Updated features:

* API#get_user_picture_data is now API#get_picture_data. The old method and API#get_picture both
  remain with deprecation warnings. (Thanks noahsilas for earlier work on this!)
* Koala::Facebook::APIError now includes [debug and trace
  info](https://github.com/arsduo/koala/blob/master/lib/koala/errors.rb) provided by Facebook in the headers
  (thanks, @elhu!)

Internal Improvements:

* Graph API error handling is now done via the GraphErrorChecker class

Testing improvements:

* Upgraded RSpec to 3.3.0
* Removed pended specs that were no longer relevant
* Improved https regex in test suite (thanks, lucaskds!)

v2.2.0 (2015-08-11)
======

Updated features:

* Restore API#search, since Facebook still supports that for certain usecases (thanks, vhoof!)
* You can now specify format: :json in http_options to make Content-Type application/json requests (thanks, adparlor!)
* Koala now supports uploading videos by URL (thanks, filipegiusti!)
* GraphCollections now offer direct access to the collection summary data via #summary (thanks, vhoof!)

Internal Improvements:

* Use MultiJson::LoadError instead of the newer ParseError for backward compatibility (thanks, bunshin!)

Documentation improvements:

* modernize the hash syntax in the readme (thanks, st0012!)

v2.1.0
======

Documentation improvements:

* extend/clean up code quality badges (thanks, jbender!)

v2.0.0
======

Koala 2.0 is not a major refactor, but rather a set of small, mostly internal
refactors:

* BatchAPI now reads both access token and app secret from the original API
  instance (thanks, lukeasrodgers!)
* Remove legacy interfaces (deprecated since 1.2)
  * API#search (which Facebook doesn't support anymore)
  * TestUser#graph\_api and RealtimeUpdates#graph\_api (use #api instead)
  * Various HTTP options (see diff for deprecation warnings/upgrade
    instructions for each method)
  * NetHTTPService and TyphoeusHTTPService (see diff for deprecation
    warnings/upgrade instructions)
  * OAuth methods for dealing with session tokens (which Facebook stopped
    providing)
  * OAuth#get\_user\_from\_cookies (use get\_user\_info\_from\_cookies instead)
* Blocks passed to API#get_picture will work in the batch API (thanks, cwhetung!)
* Added API#get_user_picture_data to get data about a picture (thanks, morgoth!)

Other changes:

* Test against modern Ruby versions on Travis (thanks, nicolasleger!)
* Speed up Travis builds (thanks, morgoth!)

v.1.11.1
========

Bug fixes:
* Properly import Facebook error attributes (thanks, isra17!)

v.1.11.0
========

Updated features:
* OAuth now supports decoding the new JSON responses from the access token endpoints (thanks, ridiculous!)
* Batch API now accepts either symbols or strings for the access token (thanks, mattmueller!)
* Incorporate user message and title into error handling (thanks, richrines and isra17!)

Bug fixes:
* Fixed bug in GraphCollection URL versioning (thanks, deviousdodo and jankowy!)
* TestUsers#create\_network now properly handles options (thanks, crx!)

Documentation improvements:
* Updated gem version (thanks, thomasklemm!)


v.1.10.1
========

Bug fixes:

* Facebook API version now works in all cases (thanks, markprzepiora!)
* Fixed a typo in an example (thanks, mktakuya!)

v.1.10.0
========

New features:
* API versioning is now supported through global and per-options requests
  (Koala.config.api_version and the :api_version key specified as a per-request
  options)

Updated features:
* API calls won't modify argument hashes in place anymore (thanks, MSex!)
* OAuth#dialog_url now uses https rather than http

Testing improvements:
* Use the modern RSpec syntax (thanks, loganhasson!)

Documentation improvements:
* Properly document the timeout option (thanks, bachand!)
* The gemspec now includes the license (thanks, coreyhaines!)

v1.9.0
======

Updated Methods:
* API#new now takes an optional access_token, which will be used to generate
  the appsecret_proof parameters ([thanks,
  nchelluri!](https://github.com/arsduo/koala/pull/323))

Testing Improvements:
* Add 2.1.0 to travis.yml and update specs to pass w/o deprecation on RSpec 3.0
  ([thanks](https://github.com/arsduo/koala/pull/350),
  [petergoldstein](https://github.com/arsduo/koala/pull/348)!)
* With 1.9.0+ only support, removed the OrderedHash patch

Documentation Improvements:
* Make it clear that connections take a singlar form in API#put_connection
(thanks, [josephdburdick](https://github.com/arsduo/koala/pull/349)!)

v1.8.0
=========

NOTE: Due to updates to underlying gems, new versions of Koala no longer work
with Ruby 1.8.x, rbx/jruby in 1.8 mode, and Ruby 1.9.2. Earlier versions will,
of course, continue to work, since the underlying Facebook API remains the
same.

If you, tragically, find yourself stuck using these old versions, you may be
able to get Koala to work by adding proper constraints to your Gemfile. Good
luck.

New methods:
* OAuth#generate_client_code lets you get long-lived user tokens for client apps (thanks, binarygeek!)

Updated methods:
* GraphCollection#next_page and #previous_page can now take additional
  parameters ([thanks, gacha!](https://github.com/arsduo/koala/pull/330))

NOTE: the appsecret_proof update from nchelluri was originally listed in the
changelog for 1.8.0, but didn't make it in. It's now properly in the changelog
for 1.9.0.

Internal Improvements:
* FIXED: TestUser#delete_all will avoid infinite loops if the user hashes
  change ([thanks, chunkerchunker!](https://github.com/arsduo/koala/pull/331))
* CHANGED: Koala now properly uploads Tempfiles like Files, detecting mime type (thanks, ys!)
* CHANGED: Koala now only passes valid Faraday options, improving compatibility with 0.9 (thanks, lsimoneau!)
* FIXED: RealtimeUpdates#validate_update now raise a proper error if secret is missing (thanks, theosp!)

Testing improvements:
* Fixed RSpec deprecations (thanks, sanemat!)

v1.7
====

New methods:
* API#debug_token allows you to examine user tokens (thanks, Cyril-sf!)
* Koala.config allows you to set Facebook servers (to use proxies, etc.) (thanks, bnorton!)

Internal improvements:
* CHANGED: Parameters can now be Arrays of non-enumerable values, which get comma-separated (thanks, csaunders!)
* CHANGED: API#put_wall_post now automatically encodes parameters hashes as JSON
* CHANGED: GraphCollections returned by batch API calls retain individual access tokens (thanks, billvieux!)
* CHANGED: Gem version restrictions have been removed, and versions updated.
* CHANGED: How support files are loaded in spec_helper has been improved.
* FIXED: API#get_picture returns nil if FB returns no result, rather than error (thanks, mtparet!)
* FIXED: Koala now uses the right grant_type value for fetching app access tokens (thanks, miv!)
* FIXED: Koala now uses the modern OAuth endpoint for generating codes (thanks, jayeff!)
* FIXED: Misc small fixes, typos, etc. (thanks, Ortuna, Crunch09, sagarbommidi!)

Testing improvements:
* FIXED: MockHTTPService compares Ruby objects rather than strings.
* FIXED: Removed deprecated usage of should_not_receive.and_return (thanks, Cyril-sf!)
* FIXED: Test suite now supports Typhoeus 0.5 (thanks, Cyril-sf!)
* CHANGED: Koala now tests against Ruby 2.0 on Travis (thanks, sanemat!)

v1.6
====

New methods:
* RealtimeUpdates#validate_update to validate the signature of a Facebook call (thanks, gaffo!)

Updated methods:
* Graph API methods now accepts a post processing block, see readme for examples (thanks, wolframarnold!)

Internal improvements:
* Koala now returns more specific and useful error classes (thanks, archfear!)
* Switched URL parsing to addressable, which can handle unusual FB URLs (thanks, bnorton!)
* Fixed Batch API bug that seems to have broken calls requiring post-processing
* Bump Faraday requirement to 0.8 (thanks, jarthod!)
* Picture and video URLs now support unicode characters (thanks, jayeff!)

Testing improvements:
* Cleaned up some test suites (thanks, bnorton!)

Documentation:
* Changelog is now markdown
* Code highlighting in readme (thanks, sfate!)
* Added Graph API explorer link in readme (thanks, jch!)
* Added permissions example for OAuth (thanks, sebastiandeutsch!)

v1.5
====

New methods:
* Added Koala::Utils.logger to enable debugging (thanks, KentonWhite!)
* Expose fb_error_message and fb_error_code directly in APIError

Updated methods:
* GraphCollection.parse_page_url now uses the URI library and can parse any address (thanks, bnorton!)

Internal improvements:
* Update MultiJson dependency to support the Oj library (thanks, eckz and zinenko!)
* Loosened Faraday dependency (thanks, rewritten and romanbsd!)
* Fixed typos (thanks, nathanbertram!)
* Switched uses of put_object to the more semantically accurate put_connections
* Cleaned up gemspec
* Handle invalid batch API responses better

Documentation:
* Added HTTP Services description for Faraday 0.8/persistent connections (thanks, romanbsd!)
* Remove documentation of the old pre-1.2 HTTP Service options

v1.4.1
=======

* Update MultiJson to 1.3 and change syntax to silence warnings (thanks, eckz and masterkain!)

v1.4
====

New methods:
* OAuth#exchange_access_token(_info) allows you to extend access tokens you receive (thanks, etiennebarrie!)

Updated methods:
* HTTPServices#encode_params sorts parameters to aid in URL comparison (thanks, sholden!)
* get_connections is now aliased as get_connection (use whichever makes sense to you)

Internal improvements:
* Fixed typos (thanks, brycethornton and jpemberthy!)
* RealtimeUpdates will no longer execute challenge block unnecessarily (thanks, iainbeeston!)

Testing improvements:
* Added parallel_tests to development gem file
* Fixed failing live tests
* Koala now tests against JRuby and Rubinius in 1.9 mode on Travis-CI

v1.3
====

New methods:
* OAuth#url_for_dialog creates URLs for Facebook dialog pages
* API#set_app_restrictions handles JSON-encoding app restrictions
* GraphCollection.parse_page_url now exposes useful functionality for non-Rails apps
* RealtimeUpdates#subscription_path and TestUsers#test_user_accounts_path are now public

Updated methods:
* REST API methods are now deprecated (see http://developers.facebook.com/blog/post/616/)
* OAuth#url_for_access_token and #url_for_oauth_code now include any provided options as URL parameters
* APIError#raw_response allows access to the raw error response received from Facebook
* Utils.deprecate only prints each message once (no more spamming)
* API#get_page_access_token now accepts additional arguments and HTTP options (like other calls)
* TestUsers and RealtimeUpdates methods now take http_options arguments
* All methods with http_options can now take :http_component => :response for the complete response
* OAuth#get_user_info_from_cookies returns nil rather than an error if the cookies are expired (thanks, herzio)
* TestUsers#delete_all now uses the Batch API and is much faster

Internal improvements:
* FQL queries now use the Graph API behind-the-scenes
* Cleaned up file and class organization, with aliases for backward compatibility
* Added YARD documentation throughout
* Fixed bugs in RealtimeUpdates, TestUsers, elsewhere
* Reorganized file and class structure non-destructively

Testing improvements:
* Expanded/improved test coverage
* The test suite no longer users any hard-coded user IDs
* KoalaTest.test_user_api allows access to the TestUsers instance
* Configured tests to run in random order using RSpec 2.8.0rc1

v1.2.1
======

New methods:
* RestAPI.set_app_properties handles JSON-encoding application properties

Updated methods:
* OAuth.get_user_from_cookie works with the new signed cookie format (thanks, gmccreight!)
* Beta server URLs are now correct
* OAuth.parse_signed_request now raises an informative error if the signed_request is malformed

Internal improvements:
* Koala::Multipart middleware properly encoding nested parameters (hashes) in POSTs
* Updated readme, changelog, etc.

Testing improvements:
* Live tests with test users now clean up all fake users they create
* Removed duplicate test cases
* Live tests with test users no longer delete each object they create, speeding things up

v1.2
====

New methods:
* API is now the main API class, contains both Graph and REST methods
  * Old classes are aliased with deprecation warnings (non-breaking change)
* TestUsers#update lets you update the name or password of an existing test user
* API.get_page_access_token lets you easily fetch the access token for a page you manage (thanks, marcgg!)
* Added version.rb (Koala::VERSION)

Updated methods:
* OAuth now parses Facebook's new signed cookie format
* API.put_picture now accepts URLs to images (thanks, marcgg!)
* Bug fixes to put_picture, parse_signed_request, and the test suite (thanks, johnbhall and Will S.!)
* Smarter GraphCollection use
  * Any pageable result will now become a GraphCollection
  * Non-pageable results from get_connections no longer error
  * GraphCollection.raw_results allows access to original result data
* Koala no longer enforces any limits on the number of test users you create at once

Internal improvements:
* Koala now uses Faraday to make requests, replacing the HTTPServices (see wiki)
  * Koala::HTTPService.http_options allows specification of default Faraday connection options
  * Koala::HTTPService.faraday_middleware allows custom middleware configurations
  * Koala now defaults to Net::HTTP rather than Typhoeus
  * Koala::NetHTTPService and Koala::TyphoeusService modules no longer exist
  * Koala no longer automatically switches to Net::HTTP when uploading IO objects to Facebook
* RealTimeUpdates and TestUsers are no longer subclasses of API, but have their own .api objects
  * The old .graph_api accessor is aliases to .api with a deprecation warning
* Removed deprecation warnings for pre-1.1 batch interface

Testing improvements:
* Live test suites now run against test users by default
  * Test suite can be repeatedly run live without having to update facebook_data.yml
  * OAuth code and session key tests cannot be run against test users
* Faraday adapter for live tests can be specified with ADAPTER=[your adapter] in the rspec command
* Live tests can be run against the beta server by specifying BETA=true in the rspec command
* Tests now pass against all rubies on Travis CI
* Expanded and refactored test coverage
* Fixed bug with YAML parsing in Ruby 1.9

v1.1
====

New methods:
* Added Batch API support (thanks, seejohnrun and spiegela!)
  * includes file uploads, error handling, and FQL
* Added GraphAPI#put_video
* Added GraphAPI#get_comments_for_urls (thanks, amrnt!)
* Added RestAPI#fql_multiquery, which simplifies the results (thanks, amrnt!)
* HTTP services support global proxy and timeout settings (thanks, itchy!)
* Net::HTTP supports global ca_path, ca_file, and verify_mode settings (thanks, spiegela!)

Updated methods:
* RealtimeUpdates now uses a GraphAPI object instead of its own API
* RestAPI#rest_call now has an optional last argument for method, for calls requiring POST, DELETE, etc. (thanks, sshilo!)
* Filename can now be specified when uploading (e.g. for Ads API) (thanks, sshilo!)
* get_objects([]) returns [] instead of a Facebook error in non-batch mode (thanks, aselder!)

Internal improvements:
* Koala is now more compatible with other Rubies (JRuby, Rubinius, etc.)
* HTTP services are more modular and can be changed on the fly (thanks, chadk!)
  * Includes support for uploading StringIOs and other non-files via Net::HTTP even when using TyphoeusService
* Koala now uses multi_json to improve compatibility with Rubinius and other Ruby versions
* Koala now uses the modern Typhoeus API (thanks, aselder!)
* Koala now uses the current modern Net::HTTP interface (thanks, romanbsd!)
* Fixed bugs and typos (thanks, waynn, mokevnin, and tikh!)

v1.0
====

New methods:
* Photo and file upload now supported through #put_picture
  * Added UploadableIO class to manage file uploads
* Added a delete_like method (thanks to waseem)
* Added put_connection and delete_connection convenience methods

Updated methods:
* Search can now search places, checkins, etc. (thanks, rickyc!)
* You can now pass :beta => true in the http options to use Facebook's beta tier
* TestUser#befriend now requires user info hashes (id and access token) due to Facebook API changes (thanks, pulsd and kbighorse!)
* All methods now accept an http_options hash as their optional last parameter (thanks, spiegela!)
* url_for_oauth_code can now take a :display option (thanks, netbe!)
* Net::HTTP can now accept :timeout and :proxy options (thanks, gilles!)
* Test users now supports using test accounts across multiple apps

Internal improvements:
* For public requests, Koala now uses http by default (instead of https) to improve speed
  * This can be overridden through Koala.always_use_ssl= or by passing :use_ssl => true in the options hash for an api call
* Read-only REST API requests now go through the faster api-read server
* Replaced parse_signed_request with a version from Facebook that also supports the new signed params proposal
  * Note: invalid requests will now raise exceptions rather than return nil, in keeping with other SDKs
* Delete methods will now raise an error if there's no access token (like put_object and delete_like)
* Updated parse_signed_request to match Facebook's current implementation (thanks, imajes!)
* APIError is now < StandardError, not Exception
* Added KoalaError for non-API errors
* Net::HTTP's SSL verification is no longer disabled by default

Test improvements:
* Incorporated joshk's awesome rewrite of the entire Koala test suite (thanks, joshk!)
* Expanded HTTP service tests (added Typhoeus test suite and additional Net::HTTP test cases)
* Live tests now verify that the access token has the necessary permissions before starting
* Replaced the 50-person network test, which often took 15+ minutes to run live, with a 5-person test

v0.10.0
=======

* Added test user module
* Fixed bug when raising APIError after Facebook fails to exchange session keys
* Made access_token accessible via the readonly access_token property on all our API classes

v0.9.1
======

* Tests are now compatible with Ruby 1.9.2
* Added JSON to runtime dependencies
* Removed examples directory (referenced from github instead)

v0.9.0
======

* Added parse_signed_request to handle Facebook's new authentication scheme
  * note: creates dependency on OpenSSL (OpenSSL::HMAC) for decryption
* Added GraphCollection class to provide paging support for GraphAPI get_connections and search methods (thanks to jagthedrummer)
* Added get_page method to easily fetch pages of results from GraphCollections
* Exchanging sessions for tokens now works properly when provided invalid/expired session keys
* You can now include a :typhoeus_options key in TyphoeusService#make_request's options hash to control the Typhoeus call (for example, to set :disable_ssl_peer_verification => true)
* All paths provided to HTTP services start with leading / to improve compatibility with stubbing libraries
* If Facebook returns nil for search or get_connections requests, Koala now returns nil rather than throwing an exception

v0.8.0
======

* Breaking interface changes
  * Removed string overloading for the methods, per 0.7.3, which caused Marshaling issues
  * Removed ability to provide a string as the second argument to url_for_access_token, per 0.5.0

v0.7.4
======

* Fixed bug with get_user_from_cookies

v0.7.3
======

* Added support for picture sizes -- thanks thhermansen for the patch!
* Adjusted the return values for several methods (get_access_token, get_app_access_token, get_token_from_session_key, get_tokens_from_session_keys, get_user_from_cookies)
  * These methods now return strings, rather than hashes, which makes more sense
  * The strings are overloaded with an [] method for backwards compatibility (Ruby is truly amazing)
    * Using those methods triggers a deprecation warning
    * This will be removed by 1.0
  * There are new info methods (get_access_token_info, get_app_access_token_info, get_token_info_from_session_keys, and get_user_info_from_cookies) that natively return hashes, for when you want the expiration date
* Responses with HTTP status 500+ now properly throw errors under Net::HTTP
* Updated changelog
* Added license

v0.7.2
======

* Added support for exchanging session keys for OAuth access tokens (get_token_from_session_key for single keys, get_tokens_from_session_keys for multiple)
* Moved Koala files into a koala/ subdirectory to minimize risk of name collisions
* Added OAuth Playground git submodule as an example
* Updated tests, readme, and changelog

v0.7.1
======

* Updated RealtimeUpdates#list_subscriptions and GraphAPI#get_connections to now return an
array of results directly (rather than a hash with one key)
* Fixed a bug with Net::HTTP-based HTTP service in which the headers hash was improperly formatted
* Updated readme

v0.7.0
======

* Added RealtimeUpdates class, which can be used to manage subscriptions for user updates (see http://developers.facebook.com/docs/api/realtime)
* Added picture method to graph API, which fetches an object's picture from the redirect headers.
* Added _greatly_ improved testing with result mocking, which is now the default set of tests
* Renamed live testing spec to koala_spec_without_mocks.rb
* Added Koala::Response class, which encapsulates HTTP results since Facebook sometimes sends data in the status or headers
* Much internal refactoring
* Updated readme, changelog, etc.

v0.6.0
======

* Added support for the old REST API thanks to cbaclig's great work
* Updated tests to conform to RSpec standards
* Updated changelog, readme, etc.

v0.5.1
======

* Documentation is now on the wiki, updated readme accordingly.

v0.5.0
======

* Added several new OAuth methods for making and parsing access token requests
* Added test suite for the OAuth class
* Made second argument to url_for_access_token a hash (strings still work but trigger a deprecation warning)
* Added fields to facebook_data.yml
* Updated readme

v0.4.1
======

* Encapsulated GraphAPI and OAuth classes in the Koala::Facebook module for clarity (and to avoid claiming the global Facebook class)
* Moved make_request method to Koala class from GraphAPI instance (for use by future OAuth class functionality)
* Renamed request method to api for consistancy with Javascript library
* Updated tests and readme

v0.4.0
======

* Adopted the Koala name
* Updated readme and tests
* Fixed cookie verification bug for non-expiring OAuth tokens

v0.3.1
======

* Bug fixes.

v0.3
====

* Renamed Graph API class from Facebook::GraphAPI to FacebookGraph::API
* Created FacebookGraph::OAuth class for tokens and OAuth URLs
* Updated method for including HTTP service (think we've got it this time)
* Updated tests
* Added CHANGELOG and gemspec

v0.2
====

* Gemified the project
* Split out HTTP services into their own file, and adjusted inclusion method

v0.1
====

* Added modular support for Typhoeus
* Added tests

v0.0
====

* Hi from F8!  Basic read/write from the graph is working
