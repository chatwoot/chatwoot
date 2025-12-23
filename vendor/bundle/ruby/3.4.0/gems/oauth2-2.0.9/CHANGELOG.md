# Changelog
All notable changes to this project will be documented in this file.

The format (since v2) is based on [Keep a Changelog v1](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning v2](https://semver.org/spec/v2.0.0.html).

## [Unreleased]
### Added
### Changed
### Fixed
### Removed

## [2.0.9] - 2022-09-16
### Added
- More specs (@pboling)
### Changed
- Complete migration to main branch as default (@pboling)
- Complete migration to Gitlab, updating all links, and references in VCS-managed files (@pboling)

## [2.0.8] - 2022-09-01
### Changed
- [!630](https://gitlab.com/oauth-xx/oauth2/-/merge_requests/630) - Extract snaky_hash to external dependency (@pboling)
### Added
- [!631](https://gitlab.com/oauth-xx/oauth2/-/merge_requests/631) - New global configuration option OAuth2.config.silence_extra_tokens_warning (default: false) fixes [#628](https://gitlab.com/oauth-xx/oauth2/-/issues/628)

## [2.0.7] - 2022-08-22
### Added
- [#629](https://gitlab.com/oauth-xx/oauth2/-/merge_requests/629) - Allow POST of JSON to get token (@pboling, @terracatta)
### Fixed
- [#626](https://gitlab.com/oauth-xx/oauth2/-/merge_requests/626) - Fixes a regression in 2.0.6. Will now prefer the key order from the lookup, not the hash keys (@rickselby)
  - Note: This fixes compatibility with `omniauth-oauth2` and AWS
- [#625](https://gitlab.com/oauth-xx/oauth2/-/merge_requests/625) - Fixes the printed version in the post install message (@hasghari)

## [2.0.6] - 2022-07-13
### Fixed
- [#624](https://gitlab.com/oauth-xx/oauth2/-/merge_requests/624) - Fixes a [regression](https://gitlab.com/oauth-xx/oauth2/-/merge_requests/623) in v2.0.5, where an error would be raised in refresh_token flows due to (legitimate) lack of access_token (@pboling)

## [2.0.5] - 2022-07-07
### Fixed
- [#620](https://gitlab.com/oauth-xx/oauth2/-/merge_requests/620) - Documentation improvements, to help with upgrading (@swanson)
- [#621](https://gitlab.com/oauth-xx/oauth2/-/merge_requests/621) - Fixed [#528](https://gitlab.com/oauth-xx/oauth2/-/issues/528) and [#619](https://gitlab.com/oauth-xx/oauth2/-/issues/619) (@pboling)
  - All data in responses is now returned, with the access token removed and set as `token`
    - `refresh_token` is no longer dropped
    - **BREAKING**: Microsoft's `id_token` is no longer left as `access_token['id_token']`, but moved to the standard `access_token.token` that all other strategies use
  - Remove `parse` and `snaky` from options so they don't get included in response
  - There is now 100% test coverage, for lines _and_ branches, and it will stay that way.

## [2.0.4] - 2022-07-01
### Fixed
- [#618](https://gitlab.com/oauth-xx/oauth2/-/merge_requests/618) - In some scenarios the `snaky` option default value was not applied (@pboling)

## [2.0.3] - 2022-06-28
### Added
- [#611](https://gitlab.com/oauth-xx/oauth2/-/merge_requests/611) - Proper deprecation warnings for `extract_access_token` argument (@pboling)
- [#612](https://gitlab.com/oauth-xx/oauth2/-/merge_requests/612) - Add `snaky: false` option to skip conversion to `OAuth2::SnakyHash` (default: true) (@pboling)
### Fixed
- [#608](https://gitlab.com/oauth-xx/oauth2/-/merge_requests/608) - Wrap `Faraday::TimeoutError` in `OAuth2::TimeoutError` (@nbibler)
- [#615](https://gitlab.com/oauth-xx/oauth2/-/merge_requests/615) - Fix support for requests with blocks, see `Faraday::Connection#run_request` (@pboling)

## [2.0.2] - 2022-06-24
### Fixed
- [#604](https://gitlab.com/oauth-xx/oauth2/-/merge_requests/604) - Wrap `Faraday::TimeoutError` in `OAuth2::TimeoutError` (@stanhu)
- [#606](https://gitlab.com/oauth-xx/oauth2/-/merge_requests/606) - Ruby 2.7 deprecation warning fix: Move `access_token_class` parameter into `Client` constructor (@stanhu)
- [#607](https://gitlab.com/oauth-xx/oauth2/-/merge_requests/607) - CHANGELOG correction, reference to `OAuth2::ConnectionError` (@zavan)

## [2.0.1] - 2022-06-22
### Added
- Documentation improvements (@pboling)
- Increased test coverage to 99% (@pboling)

## [2.0.0] - 2022-06-21
### Added
- [#158](https://gitlab.com/oauth-xx/oauth2/-/merge_requests/158), [#344](https://gitlab.com/oauth-xx/oauth2/-/merge_requests/344) - Optionally pass raw response to parsers (@niels)
- [#190](https://gitlab.com/oauth-xx/oauth2/-/merge_requests/190), [#332](https://gitlab.com/oauth-xx/oauth2/-/merge_requests/332), [#334](https://gitlab.com/oauth-xx/oauth2/-/merge_requests/334), [#335](https://gitlab.com/oauth-xx/oauth2/-/merge_requests/335), [#360](https://gitlab.com/oauth-xx/oauth2/-/merge_requests/360), [#426](https://gitlab.com/oauth-xx/oauth2/-/merge_requests/426), [#427](https://gitlab.com/oauth-xx/oauth2/-/merge_requests/427), [#461](https://gitlab.com/oauth-xx/oauth2/-/merge_requests/461) - Documentation (@josephpage, @pboling, @meganemura, @joshRpowell, @elliotcm)
- [#220](https://gitlab.com/oauth-xx/oauth2/-/merge_requests/220) - Support IETF rfc7523 JWT Bearer Tokens Draft 04+ (@jhmoore)
- [#298](https://gitlab.com/oauth-xx/oauth2/-/merge_requests/298) - Set the response object on the access token on Client#get_token for debugging (@cpetschnig)
- [#305](https://gitlab.com/oauth-xx/oauth2/-/merge_requests/305) - Option: `OAuth2::Client#get_token` - `:access_token_class` (`AccessToken`); user specified class to use for all calls to `get_token` (@styd)
- [#346](https://gitlab.com/oauth-xx/oauth2/-/merge_requests/571) - Modern gem structure (@pboling)
- [#351](https://gitlab.com/oauth-xx/oauth2/-/merge_requests/351) - Support Jruby 9k (@pboling)
- [#362](https://gitlab.com/oauth-xx/oauth2/-/merge_requests/362) - Support SemVer release version scheme (@pboling)
- [#363](https://gitlab.com/oauth-xx/oauth2/-/merge_requests/363) - New method `OAuth2::AccessToken#refresh!` same as old `refresh`, with backwards compatibility alias (@pboling)
- [#364](https://gitlab.com/oauth-xx/oauth2/-/merge_requests/364) - Support `application/hal+json` format (@pboling)
- [#365](https://gitlab.com/oauth-xx/oauth2/-/merge_requests/365) - Support `application/vnd.collection+json` format (@pboling)
- [#376](https://gitlab.com/oauth-xx/oauth2/-/merge_requests/376) - _Documentation_: Example / Test for Google 2-legged JWT (@jhmoore)
- [#381](https://gitlab.com/oauth-xx/oauth2/-/merge_requests/381) - Spec for extra header params on client credentials (@nikz)
- [#394](https://gitlab.com/oauth-xx/oauth2/-/merge_requests/394) - Option: `OAuth2::AccessToken#initialize` - `:expires_latency` (`nil`); number of seconds by which AccessToken validity will be reduced to offset latency (@klippx)
- [#412](https://gitlab.com/oauth-xx/oauth2/-/merge_requests/412) - Support `application/vdn.api+json` format (from jsonapi.org) (@david-christensen)
- [#413](https://gitlab.com/oauth-xx/oauth2/-/merge_requests/413) - _Documentation_: License scan and report (@meganemura)
- [#442](https://gitlab.com/oauth-xx/oauth2/-/merge_requests/442) - Option: `OAuth2::Client#initialize` - `:logger` (`::Logger.new($stdout)`) logger to use when OAUTH_DEBUG is enabled (for parity with `1-4-stable` branch) (@rthbound)
- [#494](https://gitlab.com/oauth-xx/oauth2/-/merge_requests/494) - Support [OIDC 1.0 Private Key JWT](https://openid.net/specs/openid-connect-core-1_0.html#ClientAuthentication); based on the OAuth JWT assertion specification [(RFC 7523)](https://tools.ietf.org/html/rfc7523) (@SteveyblamWork)
- [#549](https://gitlab.com/oauth-xx/oauth2/-/merge_requests/549) - Wrap `Faraday::ConnectionFailed` in `OAuth2::ConnectionError` (@nikkypx)
- [#550](https://gitlab.com/oauth-xx/oauth2/-/merge_requests/550) - Raise error if location header not present when redirecting (@stanhu)
- [#552](https://gitlab.com/oauth-xx/oauth2/-/merge_requests/552) - Add missing `version.rb` require (@ahorek)
- [#553](https://gitlab.com/oauth-xx/oauth2/-/merge_requests/553) - Support `application/problem+json` format (@janz93)
- [#560](https://gitlab.com/oauth-xx/oauth2/-/merge_requests/560) - Support IETF rfc6749, section 2.3.1 - don't set auth params when `nil` (@bouk)
- [#571](https://gitlab.com/oauth-xx/oauth2/-/merge_requests/571) - Support Ruby 3.1 (@pboling)
- [#575](https://gitlab.com/oauth-xx/oauth2/-/merge_requests/575) - Support IETF rfc7231, section 7.1.2 - relative location in redirect (@pboling)
- [#581](https://gitlab.com/oauth-xx/oauth2/-/merge_requests/581) - _Documentation_: of breaking changes (@pboling)
### Changed
- [#191](https://gitlab.com/oauth-xx/oauth2/-/merge_requests/191) - **BREAKING**: Token is expired if `expired_at` time is `now` (@davestevens)
- [#312](https://gitlab.com/oauth-xx/oauth2/-/merge_requests/312) - **BREAKING**: Set `:basic_auth` as default for `:auth_scheme` instead of `:request_body`. This was default behavior before 1.3.0. (@tetsuya, @wy193777)
- [#317](https://gitlab.com/oauth-xx/oauth2/-/merge_requests/317) - _Dependency_: Upgrade `jwt` to 2.x.x (@travisofthenorth)
- [#338](https://gitlab.com/oauth-xx/oauth2/-/merge_requests/338) - _Dependency_: Switch from `Rack::Utils.escape` to `CGI.escape` (@josephpage)
- [#339](https://gitlab.com/oauth-xx/oauth2/-/merge_requests/339), [#368](https://gitlab.com/oauth-xx/oauth2/-/merge_requests/368), [#424](https://gitlab.com/oauth-xx/oauth2/-/merge_requests/424), [#479](https://gitlab.com/oauth-xx/oauth2/-/merge_requests/479), [#493](https://gitlab.com/oauth-xx/oauth2/-/merge_requests/493), [#539](https://gitlab.com/oauth-xx/oauth2/-/merge_requests/539), [#542](https://gitlab.com/oauth-xx/oauth2/-/merge_requests/542), [#553](https://gitlab.com/oauth-xx/oauth2/-/merge_requests/553) - CI Updates, code coverage, linting, spelling, type fixes, New VERSION constant (@pboling, @josephpage, @ahorek)
- [#410](https://gitlab.com/oauth-xx/oauth2/-/merge_requests/410) - **BREAKING**: Removed the ability to call .error from an OAuth2::Response object (@jhmoore)
- [#414](https://gitlab.com/oauth-xx/oauth2/-/merge_requests/414) - Use Base64.strict_encode64 instead of custom internal logic (@meganemura)
- [#489](https://gitlab.com/oauth-xx/oauth2/-/merge_requests/489) - **BREAKING**: Default value for option `OAuth2::Client` - `:authorize_url` removed leading slash to work with relative paths by default (`'oauth/authorize'`) (@ghost)
- [#489](https://gitlab.com/oauth-xx/oauth2/-/merge_requests/489) - **BREAKING**: Default value for option `OAuth2::Client` - `:token_url` removed leading slash to work with relative paths by default (`'oauth/token'`) (@ghost)
- [#507](https://gitlab.com/oauth-xx/oauth2/-/merge_requests/507), [#575](https://gitlab.com/oauth-xx/oauth2/-/merge_requests/575) - **BREAKING**: Transform keys to camel case, always, by default (ultimately via `rash_alt` gem)
  - Original keys will still work as previously, in most scenarios, thanks to `rash_alt` gem.
  - However, this is a _breaking_ change if you rely on `response.parsed.to_h`, as the keys in the result will be camel case.
  - As of version 2.0.4 you can turn key transformation off with the `snaky: false` option.
- [#576](https://gitlab.com/oauth-xx/oauth2/-/merge_requests/576) - **BREAKING**: Stop rescuing parsing errors (@pboling)
- [#591](https://gitlab.com/oauth-xx/oauth2/-/merge_requests/576) - _DEPRECATION_: `OAuth2::Client` - `:extract_access_token` option is deprecated
### Fixed
- [#158](https://gitlab.com/oauth-xx/oauth2/-/merge_requests/158), [#344](https://gitlab.com/oauth-xx/oauth2/-/merge_requests/344) - Handling of errors when using `omniauth-facebook` (@niels)
- [#294](https://gitlab.com/oauth-xx/oauth2/-/merge_requests/294) - Fix: "Unexpected middleware set" issue with Faraday when `OAUTH_DEBUG=true` (@spectator, @gafrom)
- [#300](https://gitlab.com/oauth-xx/oauth2/-/merge_requests/300) - _Documentation_: `Oauth2::Error` - Error codes are strings, not symbols (@NobodysNightmare)
- [#318](https://gitlab.com/oauth-xx/oauth2/-/merge_requests/318), [#326](https://gitlab.com/oauth-xx/oauth2/-/merge_requests/326), [#343](https://gitlab.com/oauth-xx/oauth2/-/merge_requests/343), [#347](https://gitlab.com/oauth-xx/oauth2/-/merge_requests/347), [#397](https://gitlab.com/oauth-xx/oauth2/-/merge_requests/397), [#464](https://gitlab.com/oauth-xx/oauth2/-/merge_requests/464), [#561](https://gitlab.com/oauth-xx/oauth2/-/merge_requests/561), [#565](https://gitlab.com/oauth-xx/oauth2/-/merge_requests/565) - _Dependency_: Support all versions of `faraday` (see [gemfiles/README.md][gemfiles/readme] for compatibility matrix with Ruby engines & versions) (@pboling, @raimondasv, @zacharywelch, @Fudoshiki, @ryogift, @sj26, @jdelStrother)
- [#322](https://gitlab.com/oauth-xx/oauth2/-/merge_requests/322), [#331](https://gitlab.com/oauth-xx/oauth2/-/merge_requests/331), [#337](https://gitlab.com/oauth-xx/oauth2/-/merge_requests/337), [#361](https://gitlab.com/oauth-xx/oauth2/-/merge_requests/361), [#371](https://gitlab.com/oauth-xx/oauth2/-/merge_requests/371), [#377](https://gitlab.com/oauth-xx/oauth2/-/merge_requests/377), [#383](https://gitlab.com/oauth-xx/oauth2/-/merge_requests/383), [#392](https://gitlab.com/oauth-xx/oauth2/-/merge_requests/392), [#395](https://gitlab.com/oauth-xx/oauth2/-/merge_requests/395), [#400](https://gitlab.com/oauth-xx/oauth2/-/merge_requests/400), [#401](https://gitlab.com/oauth-xx/oauth2/-/merge_requests/401), [#403](https://gitlab.com/oauth-xx/oauth2/-/merge_requests/403), [#415](https://gitlab.com/oauth-xx/oauth2/-/merge_requests/415), [#567](https://gitlab.com/oauth-xx/oauth2/-/merge_requests/567) - Updated Rubocop, Rubocop plugins and improved code style (@pboling, @bquorning, @lautis, @spectator)
- [#328](https://gitlab.com/oauth-xx/oauth2/-/merge_requests/328) - _Documentation_: Homepage URL is SSL (@amatsuda)
- [#339](https://gitlab.com/oauth-xx/oauth2/-/merge_requests/339), [#479](https://gitlab.com/oauth-xx/oauth2/-/merge_requests/479) - Update testing infrastructure for all supported Rubies (@pboling and @josephpage)
- [#366](https://gitlab.com/oauth-xx/oauth2/-/merge_requests/366) - **Security**: Fix logging to `$stdout` of request and response bodies via Faraday's logger and `ENV["OAUTH_DEBUG"] == 'true'` (@pboling)
- [#380](https://gitlab.com/oauth-xx/oauth2/-/merge_requests/380) - Fix: Stop attempting to encode non-encodable objects in `Oauth2::Error` (@jhmoore)
- [#399](https://gitlab.com/oauth-xx/oauth2/-/merge_requests/399) - Fix: Stop duplicating `redirect_uri` in `get_token` (@markus)
- [#410](https://gitlab.com/oauth-xx/oauth2/-/merge_requests/410) - Fix: `SystemStackError` caused by circular reference between Error and Response classes (@jhmoore)
- [#460](https://gitlab.com/oauth-xx/oauth2/-/merge_requests/460) - Fix: Stop throwing errors when `raise_errors` is set to `false`; analog of [#524](https://gitlab.com/oauth-xx/oauth2/-/merge_requests/524) for `1-4-stable` branch (@joaolrpaulo)
- [#472](https://gitlab.com/oauth-xx/oauth2/-/merge_requests/472) - **Security**: Add checks to enforce `client_secret` is *never* passed in authorize_url query params for `implicit` and `auth_code` grant types (@dfockler)
- [#482](https://gitlab.com/oauth-xx/oauth2/-/merge_requests/482) - _Documentation_: Update last of `intridea` links to `oauth-xx` (@pboling)
- [#536](https://gitlab.com/oauth-xx/oauth2/-/merge_requests/536) - **Security**: Compatibility with more (and recent) Ruby OpenSSL versions, Github Actions, Rubocop updated, analogous to [#535](https://gitlab.com/oauth-xx/oauth2/-/merge_requests/535) on `1-4-stable` branch (@pboling)
- [#595](https://gitlab.com/oauth-xx/oauth2/-/merge_requests/595) - Graceful handling of empty responses from `Client#get_token`, respecting `:raise_errors` config (@stanhu)
- [#596](https://gitlab.com/oauth-xx/oauth2/-/merge_requests/596) - Consistency between `AccessToken#refresh` and `Client#get_token` named arguments (@stanhu)
- [#598](https://gitlab.com/oauth-xx/oauth2/-/merge_requests/598) - Fix unparseable data not raised as error in `Client#get_token`, respecting `:raise_errors` config (@stanhu)
### Removed
- [#341](https://gitlab.com/oauth-xx/oauth2/-/merge_requests/341) - Remove Rdoc & Jeweler related files (@josephpage)
- [#342](https://gitlab.com/oauth-xx/oauth2/-/merge_requests/342) - **BREAKING**: Dropped support for Ruby 1.8 (@josephpage)
- [#539](https://gitlab.com/oauth-xx/oauth2/-/merge_requests/539) - Remove reliance on globally included OAuth2 in tests, analog of [#538](https://gitlab.com/oauth-xx/oauth2/-/merge_requests/538) for 1-4-stable (@anderscarling)
- [#566](https://gitlab.com/oauth-xx/oauth2/-/merge_requests/566) - _Dependency_: Removed `wwtd` (@bquorning)
- [#589](https://gitlab.com/oauth-xx/oauth2/-/merge_requests/589), [#593](https://gitlab.com/oauth-xx/oauth2/-/merge_requests/593) - Remove support for expired MAC token draft spec (@stanhu)
- [#590](https://gitlab.com/oauth-xx/oauth2/-/merge_requests/590) - _Dependency_: Removed `multi_json` (@stanhu)

## [1.4.11] - 2022-09-16
- Complete migration to main branch as default (@pboling)
- Complete migration to Gitlab, updating all links, and references in VCS-managed files (@pboling)

## [1.4.10] - 2022-07-01
- FIPS Compatibility [#587](https://gitlab.com/oauth-xx/oauth2/-/merge_requests/587) (@akostadinov)

## [1.4.9] - 2022-02-20
- Fixes compatibility with Faraday v2 [572](https://gitlab.com/oauth-xx/oauth2/-/issues/572)
- Includes supported versions of Faraday in test matrix:
  - Faraday ~> 2.2.0 with Ruby >= 2.6
  - Faraday ~> 1.10 with Ruby >= 2.4
  - Faraday ~> 0.17.3 with Ruby >= 1.9
- Add Windows and MacOS to test matrix

## [1.4.8] - 2022-02-18
- MFA is now required to push new gem versions (@pboling)
- README overhaul w/ new Ruby Version and Engine compatibility policies (@pboling)
- [#569](https://gitlab.com/oauth-xx/oauth2/-/merge_requests/569) Backport fixes ([#561](https://gitlab.com/oauth-xx/oauth2/-/merge_requests/561) by @ryogift), and add more fixes, to allow faraday 1.x and 2.x (@jrochkind)
- Improve Code Coverage tracking (Coveralls, CodeCov, CodeClimate), and enable branch coverage (@pboling)
- Add CodeQL, Security Policy, Funding info (@pboling)
- Added Ruby 3.1, jruby, jruby-head, truffleruby, truffleruby-head to build matrix (@pboling)
- [#543](https://gitlab.com/oauth-xx/oauth2/-/merge_requests/543) - Support for more modern Open SSL libraries (@pboling)

## [1.4.7] - 2021-03-19
- [#541](https://gitlab.com/oauth-xx/oauth2/-/merge_requests/541) - Backport fix to expires_at handling [#533](https://gitlab.com/oauth-xx/oauth2/-/merge_requests/533) to 1-4-stable branch. (@dobon)

## [1.4.6] - 2021-03-19
- [#540](https://gitlab.com/oauth-xx/oauth2/-/merge_requests/540) - Add VERSION constant (@pboling)
- [#537](https://gitlab.com/oauth-xx/oauth2/-/merge_requests/537) - Fix crash in OAuth2::Client#get_token (@anderscarling)
- [#538](https://gitlab.com/oauth-xx/oauth2/-/merge_requests/538) - Remove reliance on globally included OAuth2 in tests, analogous to [#539](https://gitlab.com/oauth-xx/oauth2/-/merge_requests/539) on main branch (@anderscarling)

## [1.4.5] - 2021-03-18
- [#535](https://gitlab.com/oauth-xx/oauth2/-/merge_requests/535) - Compatibility with range of supported Ruby OpenSSL versions, Rubocop updates, Github Actions, analogous to [#536](https://gitlab.com/oauth-xx/oauth2/-/merge_requests/536) on main branch (@pboling)
- [#518](https://gitlab.com/oauth-xx/oauth2/-/merge_requests/518) - Add extract_access_token option to OAuth2::Client (@jonspalmer)
- [#507](https://gitlab.com/oauth-xx/oauth2/-/merge_requests/507) - Fix camel case content type, response keys (@anvox)
- [#500](https://gitlab.com/oauth-xx/oauth2/-/merge_requests/500) - Fix YARD documentation formatting (@olleolleolle)

## [1.4.4] - 2020-02-12
- [#408](https://gitlab.com/oauth-xx/oauth2/-/merge_requests/408) - Fixed expires_at for formatted time (@Lomey)

## [1.4.3] - 2020-01-29
- [#483](https://gitlab.com/oauth-xx/oauth2/-/merge_requests/483) - add project metadata to gemspec (@orien)
- [#495](https://gitlab.com/oauth-xx/oauth2/-/merge_requests/495) - support additional types of access token requests (@SteveyblamFreeagent, @thomcorley, @dgholz)
  - Adds support for private_key_jwt and tls_client_auth
- [#433](https://gitlab.com/oauth-xx/oauth2/-/merge_requests/433) - allow field names with square brackets and numbers in params (@asm256)

## [1.4.2] - 2019-10-01
- [#478](https://gitlab.com/oauth-xx/oauth2/-/merge_requests/478) - support latest version of faraday & fix build (@pboling)
  - Officially support Ruby 2.6 and truffleruby

## [1.4.1] - 2018-10-13
- [#417](https://gitlab.com/oauth-xx/oauth2/-/merge_requests/417) - update jwt dependency (@thewoolleyman)
- [#419](https://gitlab.com/oauth-xx/oauth2/-/merge_requests/419) - remove rubocop dependency (temporary, added back in [#423](https://gitlab.com/oauth-xx/oauth2/-/merge_requests/423)) (@pboling)
- [#418](https://gitlab.com/oauth-xx/oauth2/-/merge_requests/418) - update faraday dependency (@pboling)
- [#420](https://gitlab.com/oauth-xx/oauth2/-/merge_requests/420) - update [oauth2.gemspec](https://gitlab.com/oauth-xx/oauth2/-/blob/1-4-stable/oauth2.gemspec) (@pboling)
- [#421](https://gitlab.com/oauth-xx/oauth2/-/merge_requests/421) - fix [CHANGELOG.md](https://gitlab.com/oauth-xx/oauth2/-/blob/1-4-stable/CHANGELOG.md) for previous releases (@pboling)
- [#422](https://gitlab.com/oauth-xx/oauth2/-/merge_requests/422) - update [LICENSE](https://gitlab.com/oauth-xx/oauth2/-/blob/1-4-stable/LICENSE) and [README.md](https://gitlab.com/oauth-xx/oauth2/-/blob/1-4-stable/README.md) (@pboling)
- [#423](https://gitlab.com/oauth-xx/oauth2/-/merge_requests/423) - update [builds](https://travis-ci.org/oauth-xx/oauth2/builds), [Rakefile](https://gitlab.com/oauth-xx/oauth2/-/blob/1-4-stable/Rakefile) (@pboling)
  - officially document supported Rubies
    * Ruby 1.9.3
    * Ruby 2.0.0
    * Ruby 2.1
    * Ruby 2.2
    * [JRuby 1.7][jruby-1.7] (targets MRI v1.9)
    * [JRuby 9.0][jruby-9.0] (targets MRI v2.0)
    * Ruby 2.3
    * Ruby 2.4
    * Ruby 2.5
    * [JRuby 9.1][jruby-9.1] (targets MRI v2.3)
    * [JRuby 9.2][jruby-9.2] (targets MRI v2.5)

[jruby-1.7]: https://www.jruby.org/2017/05/11/jruby-1-7-27.html
[jruby-9.0]: https://www.jruby.org/2016/01/26/jruby-9-0-5-0.html
[jruby-9.1]: https://www.jruby.org/2017/05/16/jruby-9-1-9-0.html
[jruby-9.2]: https://www.jruby.org/2018/05/24/jruby-9-2-0-0.html

## [1.4.0] - 2017-06-09
- Drop Ruby 1.8.7 support (@sferik)
- Fix some RuboCop offenses (@sferik)
- _Dependency_: Remove Yardstick (@sferik)
- _Dependency_: Upgrade Faraday to 0.12 (@sferik)

## [1.3.1] - 2017-03-03
- Add support for Ruby 2.4.0 (@pschambacher)
- _Dependency_: Upgrade Faraday to Faraday 0.11 (@mcfiredrill, @rhymes, @pschambacher)

## [1.3.0] - 2016-12-28
- Add support for header-based authentication to the `Client` so it can be used across the library (@bjeanes)
- Default to header-based authentication when getting a token from an authorisation code (@maletor)
- **Breaking**: Allow an `auth_scheme` (`:basic_auth` or `:request_body`) to be set on the client, defaulting to `:request_body` to maintain backwards compatibility (@maletor, @bjeanes)
- Handle `redirect_uri` according to the OAuth 2 spec, so it is passed on redirect and at the point of token exchange (@bjeanes)
- Refactor handling of encoding of error responses (@urkle)
- Avoid instantiating an `Error` if there is no error to raise (@urkle)
- Add support for Faraday 0.10 (@rhymes)

## [1.2.0] - 2016-07-01
- Properly handle encoding of error responses (so we don't blow up, for example, when Google's response includes a ∞) (@Motoshi-Nishihira)
- Make a copy of the options hash in `AccessToken#from_hash` to avoid accidental mutations (@Linuus)
- Use `raise` rather than `fail` to throw exceptions (@sferik)

## [1.1.0] - 2016-01-30
- Various refactors (eliminating `Hash#merge!` usage in `AccessToken#refresh!`, use `yield` instead of `#call`, freezing mutable objects in constants, replacing constants with class variables) (@sferik)
- Add support for Rack 2, and bump various other dependencies (@sferik)

## [1.0.0] - 2014-07-09
### Added
- Add an implementation of the MAC token spec.
### Fixed
- Fix Base64.strict_encode64 incompatibility with Ruby 1.8.7.

## [0.5.0] - 2011-07-29
### Changed
- *breaking* `oauth_token` renamed to `oauth_bearer`.
- *breaking* `authorize_path` Client option renamed to `authorize_url`.
- *breaking* `access_token_path` Client option renamed to `token_url`.
- *breaking* `access_token_method` Client option renamed to `token_method`.
- *breaking* `web_server` renamed to `auth_code`.

## [0.4.1] - 2011-04-20

## [0.4.0] - 2011-04-20

## [0.3.0] - 2011-04-08

## [0.2.0] - 2011-04-01

## [0.1.1] - 2011-01-12

## [0.1.0] - 2010-10-13

## [0.0.13] + [0.0.12] + [0.0.11] - 2010-08-17

## [0.0.10] - 2010-06-19

## [0.0.9] - 2010-06-18

## [0.0.8] + [0.0.7] - 2010-04-27

## [0.0.6] - 2010-04-25

## [0.0.5] - 2010-04-23

## [0.0.4] + [0.0.3] + [0.0.2] + [0.0.1] - 2010-04-22

[0.0.1]: https://gitlab.com/oauth-xx/oauth2/-/compare/311d9f4...v0.0.1
[0.0.2]: https://gitlab.com/oauth-xx/oauth2/-/compare/v0.0.1...v0.0.2
[0.0.3]: https://gitlab.com/oauth-xx/oauth2/-/compare/v0.0.2...v0.0.3
[0.0.4]: https://gitlab.com/oauth-xx/oauth2/-/compare/v0.0.3...v0.0.4
[0.0.5]: https://gitlab.com/oauth-xx/oauth2/-/compare/v0.0.4...v0.0.5
[0.0.6]: https://gitlab.com/oauth-xx/oauth2/-/compare/v0.0.5...v0.0.6
[0.0.7]: https://gitlab.com/oauth-xx/oauth2/-/compare/v0.0.6...v0.0.7
[0.0.8]: https://gitlab.com/oauth-xx/oauth2/-/compare/v0.0.7...v0.0.8
[0.0.9]: https://gitlab.com/oauth-xx/oauth2/-/compare/v0.0.8...v0.0.9
[0.0.10]: https://gitlab.com/oauth-xx/oauth2/-/compare/v0.0.9...v0.0.10
[0.0.11]: https://gitlab.com/oauth-xx/oauth2/-/compare/v0.0.10...v0.0.11
[0.0.12]: https://gitlab.com/oauth-xx/oauth2/-/compare/v0.0.11...v0.0.12
[0.0.13]: https://gitlab.com/oauth-xx/oauth2/-/compare/v0.0.12...v0.0.13
[0.1.0]: https://gitlab.com/oauth-xx/oauth2/-/compare/v0.0.13...v0.1.0
[0.1.1]: https://gitlab.com/oauth-xx/oauth2/-/compare/v0.1.0...v0.1.1
[0.2.0]: https://gitlab.com/oauth-xx/oauth2/-/compare/v0.1.1...v0.2.0
[0.3.0]: https://gitlab.com/oauth-xx/oauth2/-/compare/v0.2.0...v0.3.0
[0.4.0]: https://gitlab.com/oauth-xx/oauth2/-/compare/v0.3.0...v0.4.0
[0.4.1]: https://gitlab.com/oauth-xx/oauth2/-/compare/v0.4.0...v0.4.1
[0.5.0]: https://gitlab.com/oauth-xx/oauth2/-/compare/v0.4.1...v0.5.0
[1.0.0]: https://gitlab.com/oauth-xx/oauth2/-/compare/v0.9.4...v1.0.0
[1.1.0]: https://gitlab.com/oauth-xx/oauth2/-/compare/v1.0.0...v1.1.0
[1.2.0]: https://gitlab.com/oauth-xx/oauth2/-/compare/v1.1.0...v1.2.0
[1.3.0]: https://gitlab.com/oauth-xx/oauth2/-/compare/v1.2.0...v1.3.0
[1.3.1]: https://gitlab.com/oauth-xx/oauth2/-/compare/v1.3.0...v1.3.1
[1.4.0]: https://gitlab.com/oauth-xx/oauth2/-/compare/v1.3.1...v1.4.0
[1.4.1]: https://gitlab.com/oauth-xx/oauth2/-/compare/v1.4.0...v1.4.1
[1.4.2]: https://gitlab.com/oauth-xx/oauth2/-/compare/v1.4.1...v1.4.2
[1.4.3]: https://gitlab.com/oauth-xx/oauth2/-/compare/v1.4.2...v1.4.3
[1.4.4]: https://gitlab.com/oauth-xx/oauth2/-/compare/v1.4.3...v1.4.4
[1.4.5]: https://gitlab.com/oauth-xx/oauth2/-/compare/v1.4.4...v1.4.5
[1.4.6]: https://gitlab.com/oauth-xx/oauth2/-/compare/v1.4.5...v1.4.6
[1.4.7]: https://gitlab.com/oauth-xx/oauth2/-/compare/v1.4.6...v1.4.7
[1.4.8]: https://gitlab.com/oauth-xx/oauth2/-/compare/v1.4.7...v1.4.8
[1.4.9]: https://gitlab.com/oauth-xx/oauth2/-/compare/v1.4.8...v1.4.9
[1.4.10]: https://gitlab.com/oauth-xx/oauth2/-/compare/v1.4.9...v1.4.10
[1.4.11]: https://gitlab.com/oauth-xx/oauth2/-/compare/v1.4.10...v1.4.11
[2.0.0]: https://gitlab.com/oauth-xx/oauth2/-/compare/v1.4.11...v2.0.0
[2.0.1]: https://gitlab.com/oauth-xx/oauth2/-/compare/v2.0.0...v2.0.1
[2.0.2]: https://gitlab.com/oauth-xx/oauth2/-/compare/v2.0.1...v2.0.2
[2.0.3]: https://gitlab.com/oauth-xx/oauth2/-/compare/v2.0.2...v2.0.3
[2.0.4]: https://gitlab.com/oauth-xx/oauth2/-/compare/v2.0.3...v2.0.4
[2.0.5]: https://gitlab.com/oauth-xx/oauth2/-/compare/v2.0.4...v2.0.5
[2.0.6]: https://gitlab.com/oauth-xx/oauth2/-/compare/v2.0.5...v2.0.6
[2.0.7]: https://gitlab.com/oauth-xx/oauth2/-/compare/v2.0.6...v2.0.7
[2.0.8]: https://gitlab.com/oauth-xx/oauth2/-/compare/v2.0.7...v2.0.8
[2.0.9]: https://gitlab.com/oauth-xx/oauth2/-/compare/v2.0.8...v2.0.9
[Unreleased]: https://gitlab.com/oauth-xx/oauth2/-/compare/v2.0.9...HEAD
[gemfiles/readme]: gemfiles/README.md
