# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]
### Added

### Changed

### Fixed

### Removed

## [1.1.0] 2022-08-29
### Changed
* `OAuth::CLI` has been extracted to a new gem, `oauth-tty`, hosted on [Gitlab](https://gitlab.com/oauth-xx/oauth-tty)
  * The public API of `oauth-tty` is backwards compatible (meaning `OAuth::CLI`)
  * The change within the `oauth` gem is backwards compatible as `oauth-tty` has been added as a dependency
  * Minor version bump is cautionary, as many lines of code have changed.
* `OAuth::Comsumer#options` hash is now handled by `snaky_hash`, which was extracted from `oauth2`
  * symbolized keys, dot-access and snake-case are now normalized

## [1.0.1] 2022-08-29
### Changed
* `OAuth::Comsumer#options` hash is now handled by `snaky_hash`, which was extracted from `oauth2`
  * symbolized keys, dot-access and snake-case are now normalized

## [1.0.0] 2022-08-23
### Changed
* Dropped support for Ruby < 2.7
* Dropped support for Rails < 6

### Added
* New EOL Policy
  * Non-commercial support for the oldest version of Ruby (which itself is going EOL) will be dropped each year in April

## [0.6.2] 2022-08-29
### Changed
* `OAuth::Comsumer#options` hash is now handled by `snaky_hash`, which was extracted from `oauth2`
  * symbolized keys, dot-access and snake-case are now normalized

## [0.6.1] 2022-08-23
### Changed
* Fixed documentation in SECURITY.md
* Change references to master => main

### Added
* Post install note about v0.6.x EOL approaching in April, 2024

## [0.6.0] 2022-08-23
### Added
* New option `body_hash_enabled` which defaults to true to maintain backward compatibility with prior releases. Setting to `false` disables generation of a `oauth_body_hash` component as part of the signature computation.
* Improved documentation of support policy via Tidelift
* Stop testing against active_support v2

### Changed
* Utilize version_gem extracted from oauth2 gem for VERSION
  * Added new `OAuth::Version` namespace
  * VERSION constant now at `OAuth::Version::VERSION`

### Removed
* Ruby 2.0, 2.1, 2.2, and 2.3 are no longer valid install targets

## [0.5.14] 2022-08-29
The "hopeful last 0.5.x" Release

### Fixed
* More typos fixed

## [0.5.13] 2022-08-23
The "I think I caught 'em all!" Release

### Fixed
* Typo oauth2 => oauth as gem name in one more place.

## [0.5.12] 2022-08-23
The "Typoes are just the worst!" Release

### Fixed
* Typo oauth2 => oauth as gem name in a couple places.

## [0.5.11] 2022-08-23
The "Is this the last release with a silly name?" Release

### Added
* Post install note about v0.5.x EOL approaching in April, 2023

### Changed
* Improved documentation
* Switched branch references from master to main
* CI builds are now all green!

## [0.5.10] 2022-05-04
The "Can it be the end of the line for 0.5.x?" Release

### Added
* Major updates to Documentation
* More CI Hardening
* Align CI builds with official Ruby Compatibility Matrix
* Project tooling in preparation for final release of 0.5.x series
  - diffend

## [0.5.9] 2022-05-03
### Added
* Documentation related to Ruby compatibility
* Updated CHANGELOG.md formatting
* Corrected CHANGELOG.md typos
* Hardened the CI build for the next few years(?!)
* Require MFA to push new version to Rubygems
* Replace Hash Rocket syntax with JSON-style symbols where possible
* Project tooling in preparation for final release of 0.5.x series
  - rubocop-ruby2_0
  - overcommit

## [0.5.8] 2021-11-10
### Added
* Added more documentation files to packaged gem, e.g. SECURITY.md, CODE_OF_CONDUCT.md

### Fixed
* Removed reference to RUBY_VERSION from gemspec, as it depends on rake release, which is problematic on some ruby engines. (by @pboling)

## [0.5.7] 2021-11-02
### Added
* Setup Rubocop (#205, #208 by @pboling)
* Added CODE_OF_CONDUCT.md (#217, #218 by @pboling)
* Added FUNDING.yml (#217, #218 by @pboling)
* Added Client Certificate Options: :ssl_client_cert and :ssl_client_key (#136, #220 by @pboling)
* Handle a nested array of hashes in OAuth::Helper.normalize (#80, #221 by @pboling)

### Changed
* Switch from TravisCI to Github Actions (#202, #207, #176 by @pboling)
* Upgrade webmock to v3.14.0 (#196 by @pboling)
* Upgrade em-http-request to v1.1.7 (#173 by @pboling)
* Upgrade mocha to v1.13.0 (#193 by @pboling)
* HISTORY renamed to CHANGELOG.md, and follows Keep a Changelog (#214, #215 by @pboling)
* CHANGELOG, LICENSE, and README now ship with packaged gem (#214, #215 by @pboling)
* README.rdoc renamed to README.md (#217, #218 by @pboling)
* Require plaintext signature method by default (#135 by @confiks & @pboling)

### Fixed
* Fixed Infinite Redirect in v0.5.5, v0.5.6 (#186, #210 by @pboling)
* Fixed NoMethodError on missing leading slash in path (#194, #211 by @pboling)
* Fixed NoMethodError on nil request object (#165, #212 by @pboling)
* Fixed Unsafe String Comparison (#156, #209 by @pboling and @drosseau)
* Fixed typos in Gemspec (#204, #203, #208 by @pboling)
* Copyright Notice in LICENSE - added correct years (#217, #218 by @pboling)
* Fixed request proxy Class constant reference scopes - was missing `::` in many places (#225, #226 by @pboling)

### Removed
* Remove direct development dependency on nokogiri (#299 by @pboling)

## [0.5.6] 2021-04-02
### Added
* Add metadata to Gemspec file
* Add support for PUT requests with Action Controller (#181)

### Changed
* Change default timeout to be the same as Net::HTTP default, 60 seconds instead of 30 seconds.

## [0.5.5] 2020-01-19
### Added
* Add :allow_empty_params option (#155)

### Changed
* Allow redirect to different host but same path
* Various cleanups

### Fixed
* Fixes ssl-noverify
* Fixed README example (#158, #159, by @pboling)

## [0.5.4] 2017-12-08
### Changed
* Various cleanups (charliesome)

### Fixed
* Fixes UnknownRequestType on Rails 5.1 for ActionDispatch::Request (xprazak2)

## [0.5.3] 2017-05-24
### Fixed
* Fix #145 - broken CLI required loading active_support (James Pinto)

### Changed
* Removing legacy scripts (James Pinto)

## [0.5.2] 2017-05-17
### Added
* Adding a development dependency that had not been mentioned (James Pinto)
* Adding CodeClimate (James Pinto)
* Adding support to Ruby 2.4 and head (James Pinto)

### Changed
* Use assert_nil so as to silence a Minitest 6 deprecation warning (James Pinto)
* Stop bundling tests files in the gem (Michal Papis)
* Minor cleanup on tests (James Pinto)
* TravisCI no longer needs libcurl-dev (James Pinto)
* Nokogiri 1.7 does not accept Ruby 2.0 (James Pinto)
* Upgrading to CodeClimate 1.0 (James Pinto)
* Locking gemspec to Rails 4 so as to allow our next version for Rails 5 (James Pinto)
* moving development dependency to gemspec (James Pinto)
* Silencing 'Net::HTTPResponse#header is obsolete' (James Pinto)
* Silencing some test warnings (James Pinto)
* Silencing 'loading in progress, circular require considered harmful' (James Pinto)
* Silence 'URI.escape obsolete' (James Pinto)
* Refactored CLI (James Pinto)
* Moving test files into test/units/ (James Pinto)
* Reimplementing #82 - Debug Output Option (James Pinto)

### Fixed
* Fix #113 adding paths when a full URL has been specified   (James Pinto)
* Bug Fix, webmock 2.0 has introduced a new bug (James Pinto)
* Making a test/support dir (James Pinto)
* Fix #177 - Adjusting to webmock latest recommended implementation for minitest (James Pinto)

## [0.5.1] 2016-02-29
### Added
* Add license info to the gemspec (Robert Reiz)

### Fixed
* Proper handling for empty query string in RequestToken#build_authorize_url (midchildan,
  Harald Sitter)
* Replace calls to String#blank? with its implementation (Sergio Gil Pérez de la Manga)

### Changed
* Loosen some development dependencies. Add libcurl-dev to travis
* Fixes to travis config. Switch to rubygems for installation and loading

### Removed
* Remove obsolete comment (Arthur Nogueira Neves)
* Remove jeweler from gemspec

## [0.5.0] 2016-02-20
### Added
* Add support for HTTP PATCH method (Richard Huang)
* Allow reading private key from a string (Khaja Minhajuddin)
* Add rest-client proxy (Khem Veasna)
* Add byebug. (Kevin Hughes)
* Allow reading certificate file path from environment variable. Add CentOS cert file path (Danil Vlasov)

### Changed
* Replace jeweler with real spec and bundler tasks
* Extract version to separate file
* Use OpenSSL for all digest and hashing. Remove signature methods not defined by OAuth spec. (Kevin Hughes)
* Change token requests to exclude `oauth_body_hash`. Update doc links in comments. (John Remmen)

### Fixed
* Fix ability to pass in an authorize url with a query string (Roger Smith)
* Fix bug in signature verification (r-stu31)
* Use standard key name (`oauth_token_secret`) in Token#to_query (Craig Walker)
* Fix error in CLI when using `query` without supplying a method (grafikchaos)
* Compatibility fix for Typhoeus >= 0.5.0 (Chad Feller)
* Rails 3+ / ActiveSupport::SafeBuffer patch (Clif Reeder)
* Handle `nil` token gracefully for RequestToken#authorize_url (Brian John)
* Fix typhoeus compatibility (Vladimir Mikhailov)
* Fix oauth cli option parser on Ruby 2.2 (Felix Bünemann)
* Update gemspec for security fixes. Convert to Minitest. Add .travis.yml. (Kevin Hughes)
* Fix some warnings (amatsuda)
* Various fixes/updates to README (Evan Arnold, Jonathan Camenisch, Brian John, Ankur Sethi)

## [0.4.7] 2012-09-03
### Added
* Set a configurable timeout for all requests (Rick Olson)

### Fixed
* Fix merging paths if the path is not empty
* Fix nested hash params in Consumer#request (Ernie Miller)

## [0.4.6] 2012-04-21
### Changed
* Make use the path component of the :site parameter (Jonathon M. Abbott)

### Fixed
* Fixed nested attributes in #normalize (Shaliko Usubov)
* Fixed post body's being dropped in 1.9 (Steven Hammond)
* Fixed PUT request handling (Anton Panasenko)

## [0.4.5] 2011-06-25
### Added
* Add explicit require for rsa/sha1 (Juris Galang)
* Add gemtest support (Adrian Feldman)

### Changed
* Use webmock to mock all http-requests in tests (Adrian Feldman)
* Mention Typhoeus require in the README (Kim Ahlström)
* Use Net::HTTPGenericRequest (Jakub Kuźma)

### Fixed
* Fix POST Requests with Typhoeus proxy (niedhui)
* Fix incorrect hardcoded port (Ian Taylor)

## [0.4.4] 2010-10-31
### Added
* Added support for Rails 3 in client/action_controller_request (Pelle)

### Fixed
* Fix LoadError rescue in tests: return can't be used in this context (Hans de Graaff)
* HTTP headers should be strings. (seancribbs)
* ensure consumer uri gets set back to original config even if an error occurs (Brian Finney)
* Yahoo uses & to split records in OAuth headers (Brian Finney)

## [0.4.3] 2010-09-01
### Fixed
* Fix for em-http proxy (ichverstehe)

## [0.4.2] 2010-08-13
### Added
* Added Bundler (rc) Gemfile for easier dev/testing

### Fixed
* Fixed compatibility with Ruby 1.9.2 (ecavazos)
* Fixed the em-http request proxy (Joshua Hull)
* Fix for oauth proxy string manipulation (Jakub Suder)

## [0.4.1] 2010-06-16
### Added
* Added support for using OAuth with proxies (Marsh Gardiner)

### Fixed
* Rails 3 Compatibility fixes (Pelle Braendgaard)
* Fixed load errors on tests for missing (non-required) libraries

## [0.4.0] 2010-04-22
### Added
* Added computation of oauth_body_hash as per OAuth Request Body Hash 1.0 Draft 4 (Michael Reinsch)
* Added the optional `oauth_session_handle` parameter for the Yahoo implementation (Will Bailey)
* Added optional block to OAuth::Consumer.get_*_token (Neill Pearman)
* Exclude `oauth_callback` with :exclude_callback (Neill Pearman)
* Support for Ruby 1.9 (Aaron Quint, Corey Donahoe, et al)
* Support for Typhoeus (Bill Kocik)
* Support for em-http (EventMachine) (Darcy Laycock)
* Support for curb (André Luis Leal Cardoso Junior)
* New website (Aaron Quint)

### Changed
* Better marshalling implementation (Yoan Blanc)
* Replaced hoe with Jeweler (Aaron Quint)

### Fixed
* Strip extraneous spaces and line breaks from access_token responses (observed in the wild with Yahoo!'s OAuth+OpenID hybrid) (Eric Hartmann)
* Stop double-escaping PLAINTEXT signatures (Jimmy Zimmerman)
* OAuth::Client::Helper won't override the specified `oauth_version` (Philip Kromer)
* Fixed an encoding / multibyte issue (成田 一生)

## [0.3.6] 2009-09-14
### Added
* Added -B CLI option to use the :body authentication scheme (Seth)
* Support POST and PUT with raw bodies (Yu-Shan Fung et al)
* Added :ca_file consumer option to allow consumer specific certificate override. (Pelle)

### Changed
* Test clean-up (Xavier Shay, Hannes Tydén)

### Fixed
* Respect `--method` in `authorize` CLI command (Seth)

## [0.3.5] 2009-06-03
### Added
* `query` CLI command to access protected resources (Seth)
* Added -H, -Q CLI options for specifying the authentication scheme (Seth)
* Added -O CLI option for specifying a file containing options (Seth)
* Support streamable body contents for large request bodies (Seth Cousins)
* Support for OAuth 1.0a (Seth)
* Added proxy support to OAuth::Consumer (Marshall Huss)
* Added --scope CLI option for Google's 'scope' parameter (Seth)

## [0.3.4] 2009-05-06
### Changed
* OAuth::Client::Helper uses OAuth::Version::VERSION (chadisfaction)

### Fixed
* Fix OAuth::RequestProxy::ActionControllerRequest's handling of params (Tristan Groléat)

## [0.3.3] 2009-05-04
### Added
* Support for arguments in OAuth::Consumer#get_access_token (Matt Sanford)
* Add gem version to user-agent header (Matt Sanford)

### Changed
* Improved error handling for invalid Authorization headers (Matt Sanford)
* Handle input from aggressive form encoding libraries (Matt Wood)

### Fixed
* Corrected OAuth XMPP namespace (Seth)
* Fixed signatures for non-ASCII under $KCODE other than 'u' (Matt Sanford)
* Fixed edge cases in ActionControllerRequestProxy where params were being incorrectly signed (Marcos Wright Kuhns)

## [0.3.2] 2009-03-23
### Added
* Support applications using the MethodOverride Rack middleware (László Bácsi)
* `authorize` command for `oauth` CLI (Seth)
* Initial support for Problem Reporting extension (Seth)
* Verify SSL certificates if CA certificates are available (Seth)
* Added help to the 'oauth' CLI (Seth)

### Fixed
* 2xx statuses should be treated as success (Anders Conbere)
* Fixed ActionController parameter escaping behavior (Thiago Arrais, László Bácsi, Brett Gibson, et al)
* Fixed signature calculation when both options and a block were provided to OAuth::Signature::Base#initialize (Seth)
* Fixed a problem when attempting to normalize MockRequest URIs (Seth)

## [0.3.1] 2009-01-26
### Fixed
* Fixed a problem with relative and absolute token request paths. (Michael Wood)

## [0.3.0] 2009-01-25
### Added
* Support ActionController::Request from Edge Rails (László Bácsi)
* Added #normalized_parameters to OAuth::RequestProxy::Base (Pelle)
* Command-line app for generating signatures. (Seth)

### Changed
* OAuth::Signature.sign and friends now yield the RequestProxy instead of the token when the passed block's arity is 1. (Seth)
* Improved test-cases and compatibility for encoding issues. (Pelle)

### Fixed
* Correctly handle multi-valued parameters (Seth)
* Token requests are made to the configured URL rather than generating a potentially incorrect one.  (Kellan Elliott-McCrea)

## 0.2.7 2008-09-10
The lets fix the last release release

### Fixed
* Fixed plain text signatures (Andrew Arrow)
* Fixed RSA requests using OAuthTokens. (Philip Lipu Tsai)

## 0.2.6 2008-09-09
The lets RSA release

### Added
* Improved support for Ruby 1.8.7 (Bill Kocik)
* Added support for 'private_key_file' option for RSA signatures (Chris Mear)

### Changed
* Improved RSA testing
* Omit token when signing with RSA

### Fixed
* Fixed RSA verification to support RSA providers now using Ruby and RSA
* Fixed several edge cases where params were being incorrectly signed (Scott Hill)
* Fixed RSA signing (choonkeat)

## 0.2.2 2008-02-22
Lets actually support SSL release

### Fixed
* Use HTTPS when required.

## 0.2 2008-1-19
All together now release

This is a big release, where we have merged the efforts of various parties into one common library.
This means there are definitely some API changes you should be aware of. They should be minimal
but please have a look at the unit tests.

## 0.1.2 2007-12-1
### Fixed
* Fixed checks for missing OAuth params to improve performance
* Includes Pat's fix for getting the realm out.

## 0.1.1 2007-11-26
### Added
* First release as a GEM
* Moved all non-Rails functionality from the Rails plugin:
  http://code.google.com/p/oauth-plugin/

[Unreleased]: https://github.com/oauth-xx/oauth-ruby/compare/v1.1.0...main
[1.1.0]: https://github.com/oauth-xx/oauth-ruby/releases/tag/v1.1.0
[1.0.1]: https://github.com/oauth-xx/oauth-ruby/releases/tag/v1.0.1
[1.0.0]: https://github.com/oauth-xx/oauth-ruby/releases/tag/v1.0.0
[0.6.2]: https://github.com/oauth-xx/oauth-ruby/releases/tag/v0.6.2
[0.6.1]: https://github.com/oauth-xx/oauth-ruby/releases/tag/v0.6.1
[0.6.0]: https://github.com/oauth-xx/oauth-ruby/releases/tag/v0.6.0
[0.5.14]: https://github.com/oauth-xx/oauth-ruby/releases/tag/v0.5.14
[0.5.13]: https://github.com/oauth-xx/oauth-ruby/releases/tag/v0.5.13
[0.5.12]: https://github.com/oauth-xx/oauth-ruby/releases/tag/v0.5.12
[0.5.11]: https://github.com/oauth-xx/oauth-ruby/releases/tag/v0.5.11
[0.5.10]: https://github.com/oauth-xx/oauth-ruby/releases/tag/v0.5.10
[0.5.9]: https://github.com/oauth-xx/oauth-ruby/releases/tag/v0.5.9
[0.5.8]: https://github.com/oauth-xx/oauth-ruby/releases/tag/v0.5.8
[0.5.7]: https://github.com/oauth-xx/oauth-ruby/releases/tag/v0.5.7
[0.5.6]: https://github.com/oauth-xx/oauth-ruby/releases/tag/v0.5.6
[0.5.5]: https://github.com/oauth-xx/oauth-ruby/releases/tag/v0.5.5
[0.5.4]: https://github.com/oauth-xx/oauth-ruby/releases/tag/v0.5.4
[0.5.3]: https://github.com/oauth-xx/oauth-ruby/releases/tag/v0.5.3
[0.5.2]: https://github.com/oauth-xx/oauth-ruby/releases/tag/v0.5.2
[0.5.1]: https://github.com/oauth-xx/oauth-ruby/releases/tag/v0.5.1
[0.5.0]: https://github.com/oauth-xx/oauth-ruby/releases/tag/v0.5.0
[0.4.7]: https://github.com/oauth-xx/oauth-ruby/releases/tag/v0.4.7
[0.4.6]: https://github.com/oauth-xx/oauth-ruby/releases/tag/v0.4.6
[0.4.5]: https://github.com/oauth-xx/oauth-ruby/releases/tag/v0.4.5
[0.4.4]: https://github.com/oauth-xx/oauth-ruby/releases/tag/v0.4.4
[0.4.3]: https://github.com/oauth-xx/oauth-ruby/releases/tag/v0.4.3
[0.4.2]: https://github.com/oauth-xx/oauth-ruby/releases/tag/v0.4.2
[0.4.1]: https://github.com/oauth-xx/oauth-ruby/releases/tag/v0.4.1
[0.4.0]: https://github.com/oauth-xx/oauth-ruby/releases/tag/v0.4.0
[0.3.6]: https://github.com/oauth-xx/oauth-ruby/releases/tag/v0.3.6
[0.3.5]: https://github.com/oauth-xx/oauth-ruby/releases/tag/v0.3.5
[0.3.4]: https://github.com/oauth-xx/oauth-ruby/releases/tag/v0.3.4
[0.3.3]: https://github.com/oauth-xx/oauth-ruby/releases/tag/v0.3.3
[0.3.2]: https://github.com/oauth-xx/oauth-ruby/releases/tag/v0.3.2
[0.3.1]: https://github.com/oauth-xx/oauth-ruby/releases/tag/v0.3.1
[0.3.0]: https://github.com/oauth-xx/oauth-ruby/releases/tag/v0.3.0
