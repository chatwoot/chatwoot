# Changelog

## [v2.10.1](https://github.com/jwt/ruby-jwt/tree/v2.10.1) (2024-12-26)

**Fixes and enhancements:**

- Make version constants public again [#646](https://github.com/jwt/ruby-jwt/pull/646) ([@anakinj]

## [v2.10.0](https://github.com/jwt/ruby-jwt/tree/v2.10.0) (2024-12-25)

[Full Changelog](https://github.com/jwt/ruby-jwt/compare/v2.9.3...v2.10.0)

**Features:**

- JWT::Token and JWT::EncodedToken for signing and verifying tokens [#621](https://github.com/jwt/ruby-jwt/pull/621) ([@anakinj](https://github.com/anakinj))
- Detached payload support for JWT::Token and JWT::EncodedToken [#630](https://github.com/jwt/ruby-jwt/pull/630) ([@anakinj](https://github.com/anakinj))
- Skip decoding payload if b64 header is present and false [#631](https://github.com/jwt/ruby-jwt/pull/631) ([@anakinj](https://github.com/anakinj))
- Remove a few custom Rubocop configs [#638](https://github.com/jwt/ruby-jwt/pull/638) ([@anakinj](https://github.com/anakinj))

**Fixes and enhancements:**

- Deprecation warnings for deprecated methods and classes [#629](https://github.com/jwt/ruby-jwt/pull/629) ([@anakinj](https://github.com/anakinj))
- Improved documentation for public apis [#629](https://github.com/jwt/ruby-jwt/pull/629) ([@anakinj](https://github.com/anakinj))
- Use correct methods when raising error during signing/verification with EdDSA [#633](https://github.com/jwt/ruby-jwt/pull/633)
- Fix JWT::EncodedToken behavior with empty string as token [#640](https://github.com/jwt/ruby-jwt/pull/640) ([@ragalie](https://github.com/ragalie))
- Deprecation warnings for rbnacl backed functionality [#641](https://github.com/jwt/ruby-jwt/pull/641) ([@anakinj](https://github.com/anakinj))

## [v2.9.3](https://github.com/jwt/ruby-jwt/tree/v2.9.3) (2024-10-03)

[Full Changelog](https://github.com/jwt/ruby-jwt/compare/v2.9.2...v2.9.3)

**Fixes and enhancements:**

- Return truthy value for `::JWT::ClaimsValidator#validate!` and `::JWT::Verify.verify_claims` [#628](https://github.com/jwt/ruby-jwt/pull/628) ([@anakinj](https://github.com/anakinj))

## [v2.9.2](https://github.com/jwt/ruby-jwt/tree/v2.9.2) (2024-10-03)

[Full Changelog](https://github.com/jwt/ruby-jwt/compare/v2.9.1...v2.9.2)

**Features:**

- Standalone claim verification interface [#626](https://github.com/jwt/ruby-jwt/pull/626) ([@anakinj](https://github.com/anakinj))

**Fixes and enhancements:**

- Updated README to correctly document `OpenSSL::HMAC` documentation [#617](https://github.com/jwt/ruby-jwt/pull/617) ([@aedryan](https://github.com/aedryan))
- Verify JWT header format [#622](https://github.com/jwt/ruby-jwt/pull/622) ([@304](https://github.com/304))
- Bring back `::JWT::ClaimsValidator`, `::JWT::Verify` and a few other removed interfaces for preserved backwards compatibility [#624](https://github.com/jwt/ruby-jwt/pull/624) ([@anakinj](https://github.com/anakinj))

## [v2.9.1](https://github.com/jwt/ruby-jwt/tree/v2.9.1) (2024-09-23)

[Full Changelog](https://github.com/jwt/ruby-jwt/compare/v2.9.0...v2.9.1)

**Fixes and enhancements:**

- Fix regression in `iss` and `aud` claim validation [#619](https://github.com/jwt/ruby-jwt/pull/619) ([@anakinj](https://github.com/anakinj))

## [v2.9.0](https://github.com/jwt/ruby-jwt/tree/v2.9.0) (2024-09-15)

[Full Changelog](https://github.com/jwt/ruby-jwt/compare/v2.8.2...v2.9.0)

**Features:**

- Build and push gem using a GH action [#612](https://github.com/jwt/ruby-jwt/pull/612) ([@anakinj](https://github.com/anakinj))

**Fixes and enhancements:**

- Refactor claim validators into their own classes [#605](https://github.com/jwt/ruby-jwt/pull/605) ([@anakinj](https://github.com/anakinj), [@MatteoPierro](https://github.com/MatteoPierro))
- Allow extending available algorithms [#607](https://github.com/jwt/ruby-jwt/pull/607) ([@anakinj](https://github.com/anakinj))
- Do not include the EdDSA algorithm if rbnacl not available [#613](https://github.com/jwt/ruby-jwt/pull/613) ([@anakinj](https://github.com/anakinj))

## [v2.8.2](https://github.com/jwt/ruby-jwt/tree/v2.8.2) (2024-06-18)

[Full Changelog](https://github.com/jwt/ruby-jwt/compare/v2.8.1...v2.8.2)

**Fixes and enhancements:**

- Print deprecation warnings only on when token decoding succeeds [#600](https://github.com/jwt/ruby-jwt/pull/600) ([@anakinj](https://github.com/anakinj))
- Unify code style [#602](https://github.com/jwt/ruby-jwt/pull/602) ([@anakinj](https://github.com/anakinj))

## [v2.8.1](https://github.com/jwt/ruby-jwt/tree/v2.8.1) (2024-02-29)

[Full Changelog](https://github.com/jwt/ruby-jwt/compare/v2.8.0...v2.8.1)

**Features:**

- Configurable base64 decode behaviour [#589](https://github.com/jwt/ruby-jwt/pull/589) ([@anakinj](https://github.com/anakinj))

**Fixes and enhancements:**

- Output deprecation warnings once [#589](https://github.com/jwt/ruby-jwt/pull/589) ([@anakinj](https://github.com/anakinj))

## [v2.8.0](https://github.com/jwt/ruby-jwt/tree/v2.8.0) (2024-02-17)

[Full Changelog](https://github.com/jwt/ruby-jwt/compare/v2.7.1...v2.8.0)

**Features:**

- Updated rubocop to 1.56 [#573](https://github.com/jwt/ruby-jwt/pull/573) ([@anakinj](https://github.com/anakinj))
- Run CI on Ruby 3.3 [#577](https://github.com/jwt/ruby-jwt/pull/577) ([@anakinj](https://github.com/anakinj))
- Deprecation warning added for the HMAC algorithm HS512256 (HMAC-SHA-512 truncated to 256-bits) [#575](https://github.com/jwt/ruby-jwt/pull/575) ([@anakinj](https://github.com/anakinj))
- Stop using RbNaCl for standard HMAC algorithms [#575](https://github.com/jwt/ruby-jwt/pull/575) ([@anakinj](https://github.com/anakinj))

**Fixes and enhancements:**

- Fix signature has expired error if payload is a string [#555](https://github.com/jwt/ruby-jwt/pull/555) ([@GobinathAL](https://github.com/GobinathAL))
- Fix key base equality and spaceship operators [#569](https://github.com/jwt/ruby-jwt/pull/569) ([@magneland](https://github.com/magneland))
- Remove explicit base64 require from x5c_key_finder [#580](https://github.com/jwt/ruby-jwt/pull/580) ([@anakinj](https://github.com/anakinj))
- Performance improvements and cleanup of tests [#581](https://github.com/jwt/ruby-jwt/pull/581) ([@anakinj](https://github.com/anakinj))
- Repair EC x/y coordinates when importing JWK [#585](https://github.com/jwt/ruby-jwt/pull/585) ([@julik](https://github.com/julik))
- Explicit dependency to the base64 gem [#582](https://github.com/jwt/ruby-jwt/pull/582) ([@anakinj](https://github.com/anakinj))
- Deprecation warning for decoding content not compliant with RFC 4648 [#582](https://github.com/jwt/ruby-jwt/pull/582) ([@anakinj](https://github.com/anakinj))
- Algorithms moved under the `::JWT::JWA` module ([@anakinj](https://github.com/anakinj))

## [v2.7.1](https://github.com/jwt/ruby-jwt/tree/v2.8.0) (2023-06-09)

[Full Changelog](https://github.com/jwt/ruby-jwt/compare/v2.7.0...v2.7.1)

**Fixes and enhancements:**

- Handle invalid algorithm when decoding JWT [#559](https://github.com/jwt/ruby-jwt/pull/559) ([@nataliastanko](https://github.com/nataliastanko))
- Do not raise error when verifying bad HMAC signature [#563](https://github.com/jwt/ruby-jwt/pull/563) ([@hieuk09](https://github.com/hieuk09))

## [v2.7.0](https://github.com/jwt/ruby-jwt/tree/v2.7.0) (2023-02-01)

[Full Changelog](https://github.com/jwt/ruby-jwt/compare/v2.6.0...v2.7.0)

**Features:**

- Support OKP (Ed25519) keys for JWKs [#540](https://github.com/jwt/ruby-jwt/pull/540) ([@anakinj](https://github.com/anakinj))
- JWK Sets can now be used for tokens with nil kid [#543](https://github.com/jwt/ruby-jwt/pull/543) ([@bellebaum](https://github.com/bellebaum))

**Fixes and enhancements:**

- Fix issue with multiple keys returned by keyfinder and multiple allowed algorithms [#545](https://github.com/jwt/ruby-jwt/pull/545) ([@mpospelov](https://github.com/mpospelov))
- Non-string `kid` header values are now rejected [#543](https://github.com/jwt/ruby-jwt/pull/543) ([@bellebaum](https://github.com/bellebaum))

## [v2.6.0](https://github.com/jwt/ruby-jwt/tree/v2.6.0) (2022-12-22)

[Full Changelog](https://github.com/jwt/ruby-jwt/compare/v2.5.0...v2.6.0)

**Features:**

- Support custom algorithms by passing algorithm objects [#512](https://github.com/jwt/ruby-jwt/pull/512) ([@anakinj](https://github.com/anakinj))
- Support descriptive (not key related) JWK parameters [#520](https://github.com/jwt/ruby-jwt/pull/520) ([@bellebaum](https://github.com/bellebaum))
- Support for JSON Web Key Sets [#525](https://github.com/jwt/ruby-jwt/pull/525) ([@bellebaum](https://github.com/bellebaum))
- Support HMAC keys over 32 chars when using RbNaCl [#521](https://github.com/jwt/ruby-jwt/pull/521) ([@anakinj](https://github.com/anakinj))

**Fixes and enhancements:**

- Raise descriptive error on empty hmac_secret and OpenSSL 3.0/openssl gem <3.0.1 [#530](https://github.com/jwt/ruby-jwt/pull/530) ([@jonmchan](https://github.com/jonmchan))

## [v2.5.0](https://github.com/jwt/ruby-jwt/tree/v2.5.0) (2022-08-25)

[Full Changelog](https://github.com/jwt/ruby-jwt/compare/v2.4.1...v2.5.0)

**Features:**

- Support JWK thumbprints as key ids [#481](https://github.com/jwt/ruby-jwt/pull/481) ([@anakinj](https://github.com/anakinj))
- Support OpenSSL >= 3.0 [#496](https://github.com/jwt/ruby-jwt/pull/496) ([@anakinj](https://github.com/anakinj))

**Fixes and enhancements:**
- Bring back the old Base64 (RFC2045) deocode mechanisms [#488](https://github.com/jwt/ruby-jwt/pull/488) ([@anakinj](https://github.com/anakinj))
- Rescue RbNaCl exception for EdDSA wrong key [#491](https://github.com/jwt/ruby-jwt/pull/491) ([@n-studio](https://github.com/n-studio))
- New parameter name for cases when kid is not found using JWK key loader proc [#501](https://github.com/jwt/ruby-jwt/pull/501) ([@anakinj](https://github.com/anakinj))
- Fix NoMethodError when a 2 segment token is missing 'alg' header [#502](https://github.com/jwt/ruby-jwt/pull/502) ([@cmrd-senya](https://github.com/cmrd-senya))

## [v2.4.1](https://github.com/jwt/ruby-jwt/tree/v2.4.1) (2022-06-07)

[Full Changelog](https://github.com/jwt/ruby-jwt/compare/v2.4.0...v2.4.1)

**Fixes and enhancements:**
- Raise JWT::DecodeError on invalid signature [\#484](https://github.com/jwt/ruby-jwt/pull/484) ([@freakyfelt!](https://github.com/freakyfelt!))

## [v2.4.0](https://github.com/jwt/ruby-jwt/tree/v2.4.0) (2022-06-06)

[Full Changelog](https://github.com/jwt/ruby-jwt/compare/v2.3.0...v2.4.0)

**Features:**

- Dropped support for Ruby 2.5 and older [#453](https://github.com/jwt/ruby-jwt/pull/453) - ([@anakinj](https://github.com/anakinj))
- Use Ruby built-in url-safe base64 methods [#454](https://github.com/jwt/ruby-jwt/pull/454) - ([@bdewater](https://github.com/bdewater))
- Updated rubocop to 1.23.0 [#457](https://github.com/jwt/ruby-jwt/pull/457) - ([@anakinj](https://github.com/anakinj))
- Add x5c header key finder [#338](https://github.com/jwt/ruby-jwt/pull/338) - ([@bdewater](https://github.com/bdewater))
- Author driven changelog process [#463](https://github.com/jwt/ruby-jwt/pull/463) - ([@anakinj](https://github.com/anakinj))
- Allow regular expressions and procs to verify issuer [\#437](https://github.com/jwt/ruby-jwt/pull/437) ([rewritten](https://github.com/rewritten))
- Add Support to be able to verify from multiple keys [\#425](https://github.com/jwt/ruby-jwt/pull/425) ([ritikesh](https://github.com/ritikesh))

**Fixes and enhancements:**
- Readme: Typo fix re MissingRequiredClaim [\#451](https://github.com/jwt/ruby-jwt/pull/451) ([antonmorant](https://github.com/antonmorant))
- Fix RuboCop TODOs [\#476](https://github.com/jwt/ruby-jwt/pull/476) ([typhoon2099](https://github.com/typhoon2099))
- Make specific algorithms in README linkable [\#472](https://github.com/jwt/ruby-jwt/pull/472) ([milieu](https://github.com/milieu))
- Update note about supported JWK types [\#475](https://github.com/jwt/ruby-jwt/pull/475) ([dpashkevich](https://github.com/dpashkevich))
- Create CODE\_OF\_CONDUCT.md [\#449](https://github.com/jwt/ruby-jwt/pull/449) ([loic5](https://github.com/loic5))

## [v2.3.0](https://github.com/jwt/ruby-jwt/tree/v2.3.0) (2021-10-03)

[Full Changelog](https://github.com/jwt/ruby-jwt/compare/v2.2.3...v2.3.0)

**Closed issues:**

- \[SECURITY\] Algorithm Confusion Through kid Header [\#440](https://github.com/jwt/ruby-jwt/issues/440)
- JWT to memory [\#436](https://github.com/jwt/ruby-jwt/issues/436)
- ArgumentError: wrong number of arguments \(given 2, expected 1\) [\#429](https://github.com/jwt/ruby-jwt/issues/429)
- HMAC section of README outdated [\#421](https://github.com/jwt/ruby-jwt/issues/421)
- NoMethodError: undefined method `zero?' for nil:NilClass if JWT has no 'alg' field [\#410](https://github.com/jwt/ruby-jwt/issues/410)
- Release new version [\#409](https://github.com/jwt/ruby-jwt/issues/409)
- NameError: uninitialized constant JWT::JWK [\#403](https://github.com/jwt/ruby-jwt/issues/403)

**Merged pull requests:**

- Release 2.3.0 [\#448](https://github.com/jwt/ruby-jwt/pull/448) ([excpt](https://github.com/excpt))
- Fix Style/MultilineIfModifier issues [\#447](https://github.com/jwt/ruby-jwt/pull/447) ([anakinj](https://github.com/anakinj))
- feat\(EdDSA\): Accept EdDSA as algorithm header [\#446](https://github.com/jwt/ruby-jwt/pull/446) ([Pierre-Michard](https://github.com/Pierre-Michard))
- Pass kid param through JWT::JWK.create\_from [\#445](https://github.com/jwt/ruby-jwt/pull/445) ([shaun-guth-allscripts](https://github.com/shaun-guth-allscripts))
- fix document about passing JWKs as a simple Hash [\#443](https://github.com/jwt/ruby-jwt/pull/443) ([takayamaki](https://github.com/takayamaki))
- Tests for mixing JWK keys with mismatching algorithms [\#441](https://github.com/jwt/ruby-jwt/pull/441) ([anakinj](https://github.com/anakinj))
- verify\_claims test shouldnt be within the verify\_sub test [\#431](https://github.com/jwt/ruby-jwt/pull/431) ([andyjdavis](https://github.com/andyjdavis))
- Allow decode options to specify required claims [\#430](https://github.com/jwt/ruby-jwt/pull/430) ([andyjdavis](https://github.com/andyjdavis))
- Fix OpenSSL::PKey::EC public\_key handing in tests [\#427](https://github.com/jwt/ruby-jwt/pull/427) ([anakinj](https://github.com/anakinj))
- Add documentation for find\_key [\#426](https://github.com/jwt/ruby-jwt/pull/426) ([ritikesh](https://github.com/ritikesh))
- Give ruby 3.0 as a string to avoid number formatting issues [\#424](https://github.com/jwt/ruby-jwt/pull/424) ([anakinj](https://github.com/anakinj))
- Tests for iat verification behaviour [\#423](https://github.com/jwt/ruby-jwt/pull/423) ([anakinj](https://github.com/anakinj))
- Remove HMAC with nil secret from documentation [\#422](https://github.com/jwt/ruby-jwt/pull/422) ([boardfish](https://github.com/boardfish))
- Update broken link in README [\#420](https://github.com/jwt/ruby-jwt/pull/420) ([severin](https://github.com/severin))
- Add metadata for RubyGems [\#418](https://github.com/jwt/ruby-jwt/pull/418) ([nickhammond](https://github.com/nickhammond))
- Fixed a typo about class name  [\#417](https://github.com/jwt/ruby-jwt/pull/417) ([mai-f](https://github.com/mai-f))
- Fix references for v2.2.3 on CHANGELOG [\#416](https://github.com/jwt/ruby-jwt/pull/416) ([vyper](https://github.com/vyper))
- Raise IncorrectAlgorithm if token has no alg header [\#411](https://github.com/jwt/ruby-jwt/pull/411) ([bouk](https://github.com/bouk))

## [v2.2.3](https://github.com/jwt/ruby-jwt/tree/v2.2.3) (2021-04-19)

[Full Changelog](https://github.com/jwt/ruby-jwt/compare/v2.2.2...v2.2.3)

**Implemented enhancements:**

- Verify algorithm before evaluating keyfinder  [\#343](https://github.com/jwt/ruby-jwt/issues/343)
- Why jwt depends on json \< 2.0 ? [\#179](https://github.com/jwt/ruby-jwt/issues/179)
- Support for JWK in-lieu of rsa\_public [\#158](https://github.com/jwt/ruby-jwt/issues/158)
- Fix rspec `raise_error` warning [\#413](https://github.com/jwt/ruby-jwt/pull/413) ([excpt](https://github.com/excpt))
- Add support for JWKs with HMAC key type. [\#372](https://github.com/jwt/ruby-jwt/pull/372) ([phlegx](https://github.com/phlegx))
- Improve 'none' algorithm handling [\#365](https://github.com/jwt/ruby-jwt/pull/365) ([danleyden](https://github.com/danleyden))
- Handle parsed JSON JWKS input with string keys [\#348](https://github.com/jwt/ruby-jwt/pull/348) ([martinemde](https://github.com/martinemde))
- Allow Numeric values during encoding [\#327](https://github.com/jwt/ruby-jwt/pull/327) ([fanfilmu](https://github.com/fanfilmu))

**Closed issues:**

- "Signature verification raised", yet jwt.io says "Signature Verified" [\#401](https://github.com/jwt/ruby-jwt/issues/401)
- truffleruby-head build is failing [\#396](https://github.com/jwt/ruby-jwt/issues/396)
- JWT::JWK::EC needs `require 'forwardable'` [\#392](https://github.com/jwt/ruby-jwt/issues/392)
- How to use a 'signing key' as used by next-auth [\#389](https://github.com/jwt/ruby-jwt/issues/389)
- undefined method `verify' for nil:NilClass when validate a JWT with JWK [\#383](https://github.com/jwt/ruby-jwt/issues/383)
- Make specifying "algorithm" optional on decode [\#380](https://github.com/jwt/ruby-jwt/issues/380)
- ADFS created access tokens can't be validated due to missing 'kid' header [\#370](https://github.com/jwt/ruby-jwt/issues/370)
- new version? [\#355](https://github.com/jwt/ruby-jwt/issues/355)
- JWT gitlab OmniAuth provider setup support [\#354](https://github.com/jwt/ruby-jwt/issues/354)
- Release with support for RSA.import for ruby \< 2.4 hasn't been released [\#347](https://github.com/jwt/ruby-jwt/issues/347)
- cannot load such file -- jwt [\#339](https://github.com/jwt/ruby-jwt/issues/339)

**Merged pull requests:**

- Prepare 2.2.3 release [\#415](https://github.com/jwt/ruby-jwt/pull/415) ([excpt](https://github.com/excpt))
- Remove codeclimate code coverage dev dependency [\#414](https://github.com/jwt/ruby-jwt/pull/414) ([excpt](https://github.com/excpt))
- Add forwardable dependency [\#408](https://github.com/jwt/ruby-jwt/pull/408) ([anakinj](https://github.com/anakinj))
- Ignore casing of algorithm [\#405](https://github.com/jwt/ruby-jwt/pull/405) ([johnnyshields](https://github.com/johnnyshields))
- Document function and add tests for verify claims method [\#404](https://github.com/jwt/ruby-jwt/pull/404) ([yasonk](https://github.com/yasonk))
- documenting calling verify\_jti callback with 2 arguments in the readme [\#402](https://github.com/jwt/ruby-jwt/pull/402) ([HoneyryderChuck](https://github.com/HoneyryderChuck))
- Target the master branch on the build status badge [\#399](https://github.com/jwt/ruby-jwt/pull/399) ([anakinj](https://github.com/anakinj))
- Improving the local development experience [\#397](https://github.com/jwt/ruby-jwt/pull/397) ([anakinj](https://github.com/anakinj))
- Fix sourcelevel broken links [\#395](https://github.com/jwt/ruby-jwt/pull/395) ([anakinj](https://github.com/anakinj))
- Don't recommend installing gem with sudo [\#391](https://github.com/jwt/ruby-jwt/pull/391) ([tjschuck](https://github.com/tjschuck))
- Enable rubocop locally and on ci [\#390](https://github.com/jwt/ruby-jwt/pull/390) ([anakinj](https://github.com/anakinj))
- Ci and test cleanup [\#387](https://github.com/jwt/ruby-jwt/pull/387) ([anakinj](https://github.com/anakinj))
- Make JWT::JWK::EC compatible with Ruby 2.3 [\#386](https://github.com/jwt/ruby-jwt/pull/386) ([anakinj](https://github.com/anakinj))
- Support JWKs for pre 2.3 rubies [\#382](https://github.com/jwt/ruby-jwt/pull/382) ([anakinj](https://github.com/anakinj))
- Replace Travis CI with GitHub Actions \(also favor openssl/rbnacl combinations over rails compatibility tests\) [\#381](https://github.com/jwt/ruby-jwt/pull/381) ([anakinj](https://github.com/anakinj))
- Add auth0 sponsor message [\#379](https://github.com/jwt/ruby-jwt/pull/379) ([excpt](https://github.com/excpt))
- Adapt HMAC to JWK RSA code style. [\#378](https://github.com/jwt/ruby-jwt/pull/378) ([phlegx](https://github.com/phlegx))
- Disable Rails cops [\#376](https://github.com/jwt/ruby-jwt/pull/376) ([anakinj](https://github.com/anakinj))
- Support exporting RSA JWK private keys [\#375](https://github.com/jwt/ruby-jwt/pull/375) ([anakinj](https://github.com/anakinj))
- Ebert is SourceLevel nowadays [\#374](https://github.com/jwt/ruby-jwt/pull/374) ([anakinj](https://github.com/anakinj))
- Add support for JWKs with EC key type [\#371](https://github.com/jwt/ruby-jwt/pull/371) ([richardlarocque](https://github.com/richardlarocque))
- Add Truffleruby head to CI [\#368](https://github.com/jwt/ruby-jwt/pull/368) ([gogainda](https://github.com/gogainda))
- Add more docs about JWK support [\#341](https://github.com/jwt/ruby-jwt/pull/341) ([take](https://github.com/take))

## [v2.2.2](https://github.com/jwt/ruby-jwt/tree/v2.2.2) (2020-08-18)

[Full Changelog](https://github.com/jwt/ruby-jwt/compare/v2.2.1...v2.2.2)

**Implemented enhancements:**

- JWK does not decode. [\#332](https://github.com/jwt/ruby-jwt/issues/332)
- Inconsistent use of symbol and string keys in args \(exp and alrogithm\). [\#331](https://github.com/jwt/ruby-jwt/issues/331)
- Pin simplecov to \< 0.18 [\#356](https://github.com/jwt/ruby-jwt/pull/356) ([anakinj](https://github.com/anakinj))
- verifies algorithm before evaluating keyfinder [\#346](https://github.com/jwt/ruby-jwt/pull/346) ([jb08](https://github.com/jb08))
- Update Rails 6 appraisal to use actual release version [\#336](https://github.com/jwt/ruby-jwt/pull/336) ([smudge](https://github.com/smudge))
- Update Travis [\#326](https://github.com/jwt/ruby-jwt/pull/326) ([berkos](https://github.com/berkos))
- Improvement/encode hmac without key [\#312](https://github.com/jwt/ruby-jwt/pull/312) ([JotaSe](https://github.com/JotaSe))

**Fixed bugs:**

- v2.2.1 warning: already initialized constant JWT Error [\#335](https://github.com/jwt/ruby-jwt/issues/335)
- 2.2.1 is no longer raising `JWT::DecodeError` on `nil` verification key [\#328](https://github.com/jwt/ruby-jwt/issues/328)
- Fix algorithm picking from decode options [\#359](https://github.com/jwt/ruby-jwt/pull/359) ([excpt](https://github.com/excpt))
- Raise error when verification key is empty [\#358](https://github.com/jwt/ruby-jwt/pull/358) ([anakinj](https://github.com/anakinj))

**Closed issues:**

- JWT RSA: is it possible to encrypt using the public key? [\#366](https://github.com/jwt/ruby-jwt/issues/366)
- Example unsigned token that bypasses verification [\#364](https://github.com/jwt/ruby-jwt/issues/364)
- Verify exp claim/field even if it's not present [\#363](https://github.com/jwt/ruby-jwt/issues/363)
- Decode any token [\#360](https://github.com/jwt/ruby-jwt/issues/360)
- \[question\] example of using a pub/priv keys for signing? [\#351](https://github.com/jwt/ruby-jwt/issues/351)
- JWT::ExpiredSignature raised for non-JSON payloads [\#350](https://github.com/jwt/ruby-jwt/issues/350)
- verify\_aud only verifies that at least one aud is expected [\#345](https://github.com/jwt/ruby-jwt/issues/345)
- Sinatra 4.90s TTFB [\#344](https://github.com/jwt/ruby-jwt/issues/344)
- How to Logout [\#342](https://github.com/jwt/ruby-jwt/issues/342)
- jwt token decoding even when wrong token is provided for some letters [\#337](https://github.com/jwt/ruby-jwt/issues/337)
- Need to use `symbolize_keys` everywhere! [\#330](https://github.com/jwt/ruby-jwt/issues/330)
- eval\(\) used in Forwardable limits usage in iOS App Store [\#324](https://github.com/jwt/ruby-jwt/issues/324)
- HS512256 OpenSSL Exception: First num too large [\#322](https://github.com/jwt/ruby-jwt/issues/322)
- Can we change the separator character? [\#321](https://github.com/jwt/ruby-jwt/issues/321)
- Verifying iat without leeway may break with poorly synced clocks [\#319](https://github.com/jwt/ruby-jwt/issues/319)
- Adding support for 'hd' hosted domain string [\#314](https://github.com/jwt/ruby-jwt/issues/314)
- There is no "typ" header in version 2.0.0 [\#233](https://github.com/jwt/ruby-jwt/issues/233)

**Merged pull requests:**

- Release v2.2.2 [\#367](https://github.com/jwt/ruby-jwt/pull/367) ([excpt](https://github.com/excpt))
- Fix 'already initialized constant JWT Error' [\#357](https://github.com/jwt/ruby-jwt/pull/357) ([excpt](https://github.com/excpt))
- Support RSA.import for all Ruby versions. [\#333](https://github.com/jwt/ruby-jwt/pull/333) ([rabajaj0509](https://github.com/rabajaj0509))
- Removed forwardable dependency [\#325](https://github.com/jwt/ruby-jwt/pull/325) ([anakinj](https://github.com/anakinj))

## [v2.2.1](https://github.com/jwt/ruby-jwt/tree/v2.2.1) (2019-05-24)

[Full Changelog](https://github.com/jwt/ruby-jwt/compare/v2.2.0...v2.2.1)

**Fixed bugs:**

- need to `require 'forwardable'` to use `Forwardable` [\#316](https://github.com/jwt/ruby-jwt/issues/316)
- Add forwardable dependency for JWK RSA KeyFinder [\#317](https://github.com/jwt/ruby-jwt/pull/317) ([excpt](https://github.com/excpt))

**Merged pull requests:**

- Release 2.2.1 [\#318](https://github.com/jwt/ruby-jwt/pull/318) ([excpt](https://github.com/excpt))

## [v2.2.0](https://github.com/jwt/ruby-jwt/tree/v2.2.0) (2019-05-23)

[Full Changelog](https://github.com/jwt/ruby-jwt/compare/v2.2.0.pre.beta.0...v2.2.0)

**Closed issues:**

- misspelled es512 curve name [\#310](https://github.com/jwt/ruby-jwt/issues/310)
- With Base64 decode i can read the hashed content [\#306](https://github.com/jwt/ruby-jwt/issues/306)
- hide post-it's for graphviz views [\#303](https://github.com/jwt/ruby-jwt/issues/303)

**Merged pull requests:**

- Release 2.2.0 [\#315](https://github.com/jwt/ruby-jwt/pull/315) ([excpt](https://github.com/excpt))

## [v2.2.0.pre.beta.0](https://github.com/jwt/ruby-jwt/tree/v2.2.0.pre.beta.0) (2019-03-20)

[Full Changelog](https://github.com/jwt/ruby-jwt/compare/v2.1.0...v2.2.0.pre.beta.0)

**Implemented enhancements:**

- Use iat\_leeway option [\#273](https://github.com/jwt/ruby-jwt/issues/273)
- Use of global state in latest version breaks thread safety of JWT.decode [\#268](https://github.com/jwt/ruby-jwt/issues/268)
- JSON support  [\#246](https://github.com/jwt/ruby-jwt/issues/246)
- Change the Github homepage URL to https [\#301](https://github.com/jwt/ruby-jwt/pull/301) ([ekohl](https://github.com/ekohl))
- Fix Salt length for conformance with PS family specification. [\#300](https://github.com/jwt/ruby-jwt/pull/300) ([tobypinder](https://github.com/tobypinder))
- Add support for Ruby 2.6 [\#299](https://github.com/jwt/ruby-jwt/pull/299) ([bustikiller](https://github.com/bustikiller))
- update homepage in gemspec to use HTTPS [\#298](https://github.com/jwt/ruby-jwt/pull/298) ([evgeni](https://github.com/evgeni))
- Make sure alg parameter value isn't added twice [\#297](https://github.com/jwt/ruby-jwt/pull/297) ([korstiaan](https://github.com/korstiaan))
- Claims Validation [\#295](https://github.com/jwt/ruby-jwt/pull/295) ([jamesstonehill](https://github.com/jamesstonehill))
- JWT::Encode refactorings, alg and exp related bugfixes [\#293](https://github.com/jwt/ruby-jwt/pull/293) ([anakinj](https://github.com/anakinj))
- Proposal of simple JWK support [\#289](https://github.com/jwt/ruby-jwt/pull/289) ([anakinj](https://github.com/anakinj))
- Add RSASSA-PSS signature signing support [\#285](https://github.com/jwt/ruby-jwt/pull/285) ([oliver-hohn](https://github.com/oliver-hohn))
- Add note about using a hard coded algorithm in README [\#280](https://github.com/jwt/ruby-jwt/pull/280) ([revodoge](https://github.com/revodoge))
- Add Appraisal support [\#278](https://github.com/jwt/ruby-jwt/pull/278) ([olbrich](https://github.com/olbrich))
- Fix decode threading issue [\#269](https://github.com/jwt/ruby-jwt/pull/269) ([ab320012](https://github.com/ab320012))
- Removed leeway from verify\_iat [\#257](https://github.com/jwt/ruby-jwt/pull/257) ([ab320012](https://github.com/ab320012))

**Fixed bugs:**

- Inconsistent handling of payload claim data types [\#282](https://github.com/jwt/ruby-jwt/issues/282)
- Issued at validation [\#247](https://github.com/jwt/ruby-jwt/issues/247)
- Fix bug and simplify segment validation [\#292](https://github.com/jwt/ruby-jwt/pull/292) ([anakinj](https://github.com/anakinj))

**Security fixes:**

- Decoding JWT with ES256 and secp256k1 curve [\#277](https://github.com/jwt/ruby-jwt/issues/277)

**Closed issues:**

- RS256, public and private keys [\#291](https://github.com/jwt/ruby-jwt/issues/291)
- Allow passing current time to `decode` [\#288](https://github.com/jwt/ruby-jwt/issues/288)
- Verify exp claim without verifying jwt [\#281](https://github.com/jwt/ruby-jwt/issues/281)
- Audience as an array - how to specify? [\#276](https://github.com/jwt/ruby-jwt/issues/276)
- signature validation using decode method for JWT [\#271](https://github.com/jwt/ruby-jwt/issues/271)
- JWT is easily breakable [\#267](https://github.com/jwt/ruby-jwt/issues/267)
- Ruby JWT Token [\#265](https://github.com/jwt/ruby-jwt/issues/265)
- ECDSA supported algorithms constant is defined as a string, not an array [\#264](https://github.com/jwt/ruby-jwt/issues/264)
- NoMethodError: undefined method `group' for \<xxxxx\> [\#261](https://github.com/jwt/ruby-jwt/issues/261)
- 'DecodeError'will replace 'ExpiredSignature' [\#260](https://github.com/jwt/ruby-jwt/issues/260)
- TypeError: no implicit conversion of OpenSSL::PKey::RSA into String [\#259](https://github.com/jwt/ruby-jwt/issues/259)
- NameError: uninitialized constant JWT::Algos::Eddsa::RbNaCl [\#258](https://github.com/jwt/ruby-jwt/issues/258)
- Get new token if curren token expired [\#256](https://github.com/jwt/ruby-jwt/issues/256)
- Infer algorithm from header [\#254](https://github.com/jwt/ruby-jwt/issues/254)
- Why is the result of decode is an array? [\#252](https://github.com/jwt/ruby-jwt/issues/252)
- Add support for headless token [\#251](https://github.com/jwt/ruby-jwt/issues/251)
- Leeway or exp\_leeway [\#215](https://github.com/jwt/ruby-jwt/issues/215)
- Could you describe purpose of cert fixtures and their cryptokey lengths. [\#185](https://github.com/jwt/ruby-jwt/issues/185)

**Merged pull requests:**

- Release v2.2.0-beta.0 [\#302](https://github.com/jwt/ruby-jwt/pull/302) ([excpt](https://github.com/excpt))
- Misc config improvements [\#296](https://github.com/jwt/ruby-jwt/pull/296) ([jamesstonehill](https://github.com/jamesstonehill))
- Fix JSON conflict between \#293 and \#292 [\#294](https://github.com/jwt/ruby-jwt/pull/294) ([anakinj](https://github.com/anakinj))
- Drop Ruby 2.2 from test matrix [\#290](https://github.com/jwt/ruby-jwt/pull/290) ([anakinj](https://github.com/anakinj))
- Remove broken reek config [\#283](https://github.com/jwt/ruby-jwt/pull/283) ([excpt](https://github.com/excpt))
- Add missing test, Update common files [\#275](https://github.com/jwt/ruby-jwt/pull/275) ([excpt](https://github.com/excpt))
- Remove iat\_leeway option [\#274](https://github.com/jwt/ruby-jwt/pull/274) ([wohlgejm](https://github.com/wohlgejm))
- improving code quality of jwt module [\#266](https://github.com/jwt/ruby-jwt/pull/266) ([ab320012](https://github.com/ab320012))
- fixed ECDSA supported versions const [\#263](https://github.com/jwt/ruby-jwt/pull/263) ([starbeast](https://github.com/starbeast))
- Added my name to contributor list [\#262](https://github.com/jwt/ruby-jwt/pull/262) ([ab320012](https://github.com/ab320012))
- Use `Class#new` Shorthand For Error Subclasses [\#255](https://github.com/jwt/ruby-jwt/pull/255) ([akabiru](https://github.com/akabiru))
- \[CI\] Test against Ruby 2.5 [\#253](https://github.com/jwt/ruby-jwt/pull/253) ([nicolasleger](https://github.com/nicolasleger))
- Fix README [\#250](https://github.com/jwt/ruby-jwt/pull/250) ([rono23](https://github.com/rono23))
- Fix link format [\#248](https://github.com/jwt/ruby-jwt/pull/248) ([y-yagi](https://github.com/y-yagi))

## [v2.1.0](https://github.com/jwt/ruby-jwt/tree/v2.1.0) (2017-10-06)

[Full Changelog](https://github.com/jwt/ruby-jwt/compare/v2.0.0...v2.1.0)

**Implemented enhancements:**

- Ed25519 support planned? [\#217](https://github.com/jwt/ruby-jwt/issues/217)
- Verify JTI Proc [\#207](https://github.com/jwt/ruby-jwt/issues/207)
- Allow a list of algorithms for decode [\#241](https://github.com/jwt/ruby-jwt/pull/241) ([lautis](https://github.com/lautis))
- verify takes 2 params, second being payload closes: \#207 [\#238](https://github.com/jwt/ruby-jwt/pull/238) ([ab320012](https://github.com/ab320012))
- simplified logic for keyfinder [\#237](https://github.com/jwt/ruby-jwt/pull/237) ([ab320012](https://github.com/ab320012))
- Show backtrace if rbnacl-libsodium not loaded [\#231](https://github.com/jwt/ruby-jwt/pull/231) ([buzztaiki](https://github.com/buzztaiki))
- Support for ED25519 [\#229](https://github.com/jwt/ruby-jwt/pull/229) ([ab320012](https://github.com/ab320012))

**Fixed bugs:**

- JWT.encode failing on encode for string [\#235](https://github.com/jwt/ruby-jwt/issues/235)
- The README says it uses an algorithm by default [\#226](https://github.com/jwt/ruby-jwt/issues/226)
- Fix string payload issue [\#236](https://github.com/jwt/ruby-jwt/pull/236) ([excpt](https://github.com/excpt))

**Security fixes:**

- Add HS256 algorithm to decode default options [\#228](https://github.com/jwt/ruby-jwt/pull/228) ([marcoadkins](https://github.com/marcoadkins))

**Closed issues:**

- Change from 1.5.6 to 2.0.0 and appears a "Completed 401 Unauthorized" [\#240](https://github.com/jwt/ruby-jwt/issues/240)
- Why doesn't the decode function use a default algorithm? [\#227](https://github.com/jwt/ruby-jwt/issues/227)

**Merged pull requests:**

- Release 2.1.0 preparations [\#243](https://github.com/jwt/ruby-jwt/pull/243) ([excpt](https://github.com/excpt))
- Update README.md [\#242](https://github.com/jwt/ruby-jwt/pull/242) ([excpt](https://github.com/excpt))
- Update ebert configuration [\#232](https://github.com/jwt/ruby-jwt/pull/232) ([excpt](https://github.com/excpt))
- added algos/strategy classes + structs for inputs [\#230](https://github.com/jwt/ruby-jwt/pull/230) ([ab320012](https://github.com/ab320012))

## [v2.0.0](https://github.com/jwt/ruby-jwt/tree/v2.0.0) (2017-09-03)

[Full Changelog](https://github.com/jwt/ruby-jwt/compare/v2.0.0.beta1...v2.0.0)

**Fixed bugs:**

- Support versions outside 2.1 [\#209](https://github.com/jwt/ruby-jwt/issues/209)
- Verifying expiration without leeway throws exception [\#206](https://github.com/jwt/ruby-jwt/issues/206)
- Ruby interpreter warning [\#200](https://github.com/jwt/ruby-jwt/issues/200)
- TypeError: no implicit conversion of String into Integer [\#188](https://github.com/jwt/ruby-jwt/issues/188)
- Fix JWT.encode\(nil\) [\#203](https://github.com/jwt/ruby-jwt/pull/203) ([tmm1](https://github.com/tmm1))

**Closed issues:**

- Possibility to disable claim verifications [\#222](https://github.com/jwt/ruby-jwt/issues/222)
- Proper way to verify Firebase id tokens [\#216](https://github.com/jwt/ruby-jwt/issues/216)

**Merged pull requests:**

- Release 2.0.0 preparations :\) [\#225](https://github.com/jwt/ruby-jwt/pull/225) ([excpt](https://github.com/excpt))
- Skip 'exp' claim validation for array payloads [\#224](https://github.com/jwt/ruby-jwt/pull/224) ([excpt](https://github.com/excpt))
- Use a default leeway of 0 [\#223](https://github.com/jwt/ruby-jwt/pull/223) ([travisofthenorth](https://github.com/travisofthenorth))
- Fix reported codesmells [\#221](https://github.com/jwt/ruby-jwt/pull/221) ([excpt](https://github.com/excpt))
- Add fancy gem version badge [\#220](https://github.com/jwt/ruby-jwt/pull/220) ([excpt](https://github.com/excpt))
- Add missing dist option to .travis.yml [\#219](https://github.com/jwt/ruby-jwt/pull/219) ([excpt](https://github.com/excpt))
- Fix ruby version requirements in gemspec file [\#218](https://github.com/jwt/ruby-jwt/pull/218) ([excpt](https://github.com/excpt))
- Fix a little typo in the readme [\#214](https://github.com/jwt/ruby-jwt/pull/214) ([RyanBrushett](https://github.com/RyanBrushett))
- Update README.md [\#212](https://github.com/jwt/ruby-jwt/pull/212) ([zuzannast](https://github.com/zuzannast))
- Fix typo in HS512256 algorithm description [\#211](https://github.com/jwt/ruby-jwt/pull/211) ([ojab](https://github.com/ojab))
- Allow configuration of multiple acceptable issuers [\#210](https://github.com/jwt/ruby-jwt/pull/210) ([ojab](https://github.com/ojab))
- Enforce `exp` to be an `Integer` [\#205](https://github.com/jwt/ruby-jwt/pull/205) ([lucasmazza](https://github.com/lucasmazza))
- ruby 1.9.3 support message upd [\#204](https://github.com/jwt/ruby-jwt/pull/204) ([maokomioko](https://github.com/maokomioko))

## [v2.0.0.beta1](https://github.com/jwt/ruby-jwt/tree/v2.0.0.beta1) (2017-02-27)

[Full Changelog](https://github.com/jwt/ruby-jwt/compare/v1.5.6...v2.0.0.beta1)

**Implemented enhancements:**

- Error with method sign for String [\#171](https://github.com/jwt/ruby-jwt/issues/171)
- Refactor the encondig code [\#121](https://github.com/jwt/ruby-jwt/issues/121)
- Refactor [\#196](https://github.com/jwt/ruby-jwt/pull/196) ([EmilioCristalli](https://github.com/EmilioCristalli))
- Move signature logic to its own module [\#195](https://github.com/jwt/ruby-jwt/pull/195) ([EmilioCristalli](https://github.com/EmilioCristalli))
- Add options for claim-specific leeway [\#187](https://github.com/jwt/ruby-jwt/pull/187) ([EmilioCristalli](https://github.com/EmilioCristalli))
- Add user friendly encode error if private key is a String, \#171 [\#176](https://github.com/jwt/ruby-jwt/pull/176) ([ogonki-vetochki](https://github.com/ogonki-vetochki))
- Return empty string if signature less than byte\_size \#155 [\#175](https://github.com/jwt/ruby-jwt/pull/175) ([ogonki-vetochki](https://github.com/ogonki-vetochki))
- Remove 'typ' optional parameter [\#174](https://github.com/jwt/ruby-jwt/pull/174) ([ogonki-vetochki](https://github.com/ogonki-vetochki))
- Pass payload to keyfinder [\#172](https://github.com/jwt/ruby-jwt/pull/172) ([CodeMonkeySteve](https://github.com/CodeMonkeySteve))
- Use RbNaCl for HMAC if available with fallback to OpenSSL [\#149](https://github.com/jwt/ruby-jwt/pull/149) ([mwpastore](https://github.com/mwpastore))

**Fixed bugs:**

- ruby-jwt::raw\_to\_asn1: Fails for signatures less than byte\_size [\#155](https://github.com/jwt/ruby-jwt/issues/155)
- The leeway parameter is applies to all time based verifications [\#129](https://github.com/jwt/ruby-jwt/issues/129)
- Make algorithm option required to verify signature [\#184](https://github.com/jwt/ruby-jwt/pull/184) ([EmilioCristalli](https://github.com/EmilioCristalli))
- Validate audience when payload is a scalar and options is an array [\#183](https://github.com/jwt/ruby-jwt/pull/183) ([steti](https://github.com/steti))

**Closed issues:**

- Different encoded value between servers with same password [\#197](https://github.com/jwt/ruby-jwt/issues/197)
- Signature is different at each run [\#190](https://github.com/jwt/ruby-jwt/issues/190)
- Include custom headers with password [\#189](https://github.com/jwt/ruby-jwt/issues/189)
- can't create token - 'NotImplementedError: Unsupported signing method' [\#186](https://github.com/jwt/ruby-jwt/issues/186)
- Cannot verify JWT at all?? [\#177](https://github.com/jwt/ruby-jwt/issues/177)
- verify\_iss: true is raising JWT::DecodeError instead of JWT::InvalidIssuerError [\#170](https://github.com/jwt/ruby-jwt/issues/170)

**Merged pull requests:**

- Version bump 2.0.0.beta1 [\#199](https://github.com/jwt/ruby-jwt/pull/199) ([excpt](https://github.com/excpt))
- Update CHANGELOG.md and minor fixes [\#198](https://github.com/jwt/ruby-jwt/pull/198) ([excpt](https://github.com/excpt))
- Add Codacy coverage reporter [\#194](https://github.com/jwt/ruby-jwt/pull/194) ([excpt](https://github.com/excpt))
- Add minimum required ruby version to gemspec [\#193](https://github.com/jwt/ruby-jwt/pull/193) ([excpt](https://github.com/excpt))
- Code smell fixes [\#192](https://github.com/jwt/ruby-jwt/pull/192) ([excpt](https://github.com/excpt))
- Version bump to 2.0.0.dev [\#191](https://github.com/jwt/ruby-jwt/pull/191) ([excpt](https://github.com/excpt))
- Basic encode module refactoring \#121 [\#182](https://github.com/jwt/ruby-jwt/pull/182) ([ogonki-vetochki](https://github.com/ogonki-vetochki))
- Fix travis ci build configuration [\#181](https://github.com/jwt/ruby-jwt/pull/181) ([excpt](https://github.com/excpt))
- Fix travis ci build configuration [\#180](https://github.com/jwt/ruby-jwt/pull/180) ([excpt](https://github.com/excpt))
- Fix typo in README [\#178](https://github.com/jwt/ruby-jwt/pull/178) ([tomeduarte](https://github.com/tomeduarte))
- Fix code style [\#173](https://github.com/jwt/ruby-jwt/pull/173) ([excpt](https://github.com/excpt))
- Fixed a typo in a spec name [\#169](https://github.com/jwt/ruby-jwt/pull/169) ([mingan](https://github.com/mingan))

## [v1.5.6](https://github.com/jwt/ruby-jwt/tree/v1.5.6) (2016-09-19)

[Full Changelog](https://github.com/jwt/ruby-jwt/compare/v1.5.5...v1.5.6)

**Fixed bugs:**

- Fix missing symbol handling in aud verify code [\#166](https://github.com/jwt/ruby-jwt/pull/166) ([excpt](https://github.com/excpt))

**Merged pull requests:**

- Update changelog [\#168](https://github.com/jwt/ruby-jwt/pull/168) ([excpt](https://github.com/excpt))
- Fix rubocop code smells [\#167](https://github.com/jwt/ruby-jwt/pull/167) ([excpt](https://github.com/excpt))

## [v1.5.5](https://github.com/jwt/ruby-jwt/tree/v1.5.5) (2016-09-16)

[Full Changelog](https://github.com/jwt/ruby-jwt/compare/v1.5.4...v1.5.5)

**Implemented enhancements:**

- JWT.decode always raises JWT::ExpiredSignature for tokens created with Time objects passed as the `exp` parameter [\#148](https://github.com/jwt/ruby-jwt/issues/148)

**Fixed bugs:**

- expiration check does not give "Signature has expired" error for the exact time of expiration [\#157](https://github.com/jwt/ruby-jwt/issues/157)
- JTI claim broken? [\#152](https://github.com/jwt/ruby-jwt/issues/152)
- Audience Claim broken? [\#151](https://github.com/jwt/ruby-jwt/issues/151)
- 1.5.3 breaks compatibility with 1.5.2 [\#133](https://github.com/jwt/ruby-jwt/issues/133)
- Version 1.5.3 breaks 1.9.3 compatibility, but not documented as such [\#132](https://github.com/jwt/ruby-jwt/issues/132)
- Fix: exp claim check [\#161](https://github.com/jwt/ruby-jwt/pull/161) ([excpt](https://github.com/excpt))

**Security fixes:**

- \[security\] Signature verified after expiration/sub/iss checks [\#153](https://github.com/jwt/ruby-jwt/issues/153)
- Signature validation before claim verification [\#160](https://github.com/jwt/ruby-jwt/pull/160) ([excpt](https://github.com/excpt))

**Closed issues:**

- Rendering Json Results in JWT::DecodeError [\#162](https://github.com/jwt/ruby-jwt/issues/162)
- PHP Libraries [\#154](https://github.com/jwt/ruby-jwt/issues/154)
- Is ruby-jwt thread-safe? [\#150](https://github.com/jwt/ruby-jwt/issues/150)
- JWT 1.5.3 [\#143](https://github.com/jwt/ruby-jwt/issues/143)
- gem install v 1.5.3 returns error [\#141](https://github.com/jwt/ruby-jwt/issues/141)
- Adding a CHANGELOG [\#140](https://github.com/jwt/ruby-jwt/issues/140)

**Merged pull requests:**

- Bump version [\#165](https://github.com/jwt/ruby-jwt/pull/165) ([excpt](https://github.com/excpt))
- Improve error message for exp claim in payload [\#164](https://github.com/jwt/ruby-jwt/pull/164) ([excpt](https://github.com/excpt))
- Fix \#151 and code refactoring [\#163](https://github.com/jwt/ruby-jwt/pull/163) ([excpt](https://github.com/excpt))
- Create specs for README.md examples [\#159](https://github.com/jwt/ruby-jwt/pull/159) ([excpt](https://github.com/excpt))
- Tiny Readme Improvement [\#156](https://github.com/jwt/ruby-jwt/pull/156) ([b264](https://github.com/b264))
- Added test execution to Rakefile [\#147](https://github.com/jwt/ruby-jwt/pull/147) ([jabbrwcky](https://github.com/jabbrwcky))
- Bump version [\#145](https://github.com/jwt/ruby-jwt/pull/145) ([excpt](https://github.com/excpt))
- Add a changelog file [\#142](https://github.com/jwt/ruby-jwt/pull/142) ([excpt](https://github.com/excpt))
- Return decoded\_segments [\#139](https://github.com/jwt/ruby-jwt/pull/139) ([akostrikov](https://github.com/akostrikov))

## [v1.5.4](https://github.com/jwt/ruby-jwt/tree/v1.5.4) (2016-03-24)

[Full Changelog](https://github.com/jwt/ruby-jwt/compare/v1.5.3...v1.5.4)

**Closed issues:**

- 404 at https://rubygems.global.ssl.fastly.net/gems/jwt-1.5.3.gem [\#137](https://github.com/jwt/ruby-jwt/issues/137)

**Merged pull requests:**

- Update README.md [\#138](https://github.com/jwt/ruby-jwt/pull/138) ([excpt](https://github.com/excpt))
- Fix base64url\_decode [\#136](https://github.com/jwt/ruby-jwt/pull/136) ([excpt](https://github.com/excpt))
- Fix ruby 1.9.3 compatibility [\#135](https://github.com/jwt/ruby-jwt/pull/135) ([excpt](https://github.com/excpt))
- iat can be a float value [\#134](https://github.com/jwt/ruby-jwt/pull/134) ([llimllib](https://github.com/llimllib))

## [v1.5.3](https://github.com/jwt/ruby-jwt/tree/v1.5.3) (2016-02-24)

[Full Changelog](https://github.com/jwt/ruby-jwt/compare/jwt-1.5.2...v1.5.3)

**Implemented enhancements:**

- Refactor obsolete code for ruby 1.8 support [\#120](https://github.com/jwt/ruby-jwt/issues/120)
- Fix "Rubocop/Metrics/CyclomaticComplexity" issue in lib/jwt.rb [\#106](https://github.com/jwt/ruby-jwt/issues/106)
- Fix "Rubocop/Metrics/CyclomaticComplexity" issue in lib/jwt.rb [\#105](https://github.com/jwt/ruby-jwt/issues/105)
- Allow a proc to be passed for JTI verification [\#126](https://github.com/jwt/ruby-jwt/pull/126) ([yahooguntu](https://github.com/yahooguntu))
- Relax restrictions on "jti" claim verification [\#113](https://github.com/jwt/ruby-jwt/pull/113) ([lwe](https://github.com/lwe))

**Closed issues:**

- Verifications not functioning in latest release [\#128](https://github.com/jwt/ruby-jwt/issues/128)
- Base64 is generating invalid length base64 strings - cross language interop [\#127](https://github.com/jwt/ruby-jwt/issues/127)
- Digest::Digest is deprecated; use Digest [\#119](https://github.com/jwt/ruby-jwt/issues/119)
- verify\_rsa no method 'verify' for class String [\#115](https://github.com/jwt/ruby-jwt/issues/115)
- Add a changelog [\#111](https://github.com/jwt/ruby-jwt/issues/111)

**Merged pull requests:**

- Drop ruby 1.9.3 support [\#131](https://github.com/jwt/ruby-jwt/pull/131) ([excpt](https://github.com/excpt))
- Allow string hash keys in validation configurations [\#130](https://github.com/jwt/ruby-jwt/pull/130) ([tpickett66](https://github.com/tpickett66))
- Add ruby 2.3.0 for travis ci testing [\#123](https://github.com/jwt/ruby-jwt/pull/123) ([excpt](https://github.com/excpt))
- Remove obsolete json code [\#122](https://github.com/jwt/ruby-jwt/pull/122) ([excpt](https://github.com/excpt))
- Add fancy badges to README.md [\#118](https://github.com/jwt/ruby-jwt/pull/118) ([excpt](https://github.com/excpt))
- Refactor decode and verify functionality [\#117](https://github.com/jwt/ruby-jwt/pull/117) ([excpt](https://github.com/excpt))
- Drop echoe dependency for gem releases [\#116](https://github.com/jwt/ruby-jwt/pull/116) ([excpt](https://github.com/excpt))
- Updated readme for iss/aud options [\#114](https://github.com/jwt/ruby-jwt/pull/114) ([ryanmcilmoyl](https://github.com/ryanmcilmoyl))
- Fix error misspelling [\#112](https://github.com/jwt/ruby-jwt/pull/112) ([kat3kasper](https://github.com/kat3kasper))

## [jwt-1.5.2](https://github.com/jwt/ruby-jwt/tree/jwt-1.5.2) (2015-10-27)

[Full Changelog](https://github.com/jwt/ruby-jwt/compare/jwt-1.5.1...jwt-1.5.2)

**Implemented enhancements:**

- Must we specify algorithm when calling decode to avoid vulnerabilities? [\#107](https://github.com/jwt/ruby-jwt/issues/107)
- Code review: Rspec test refactoring [\#85](https://github.com/jwt/ruby-jwt/pull/85) ([excpt](https://github.com/excpt))

**Fixed bugs:**

- aud verifies if aud is passed in, :sub does not [\#102](https://github.com/jwt/ruby-jwt/issues/102)
- iat check does not use leeway so nbf could pass, but iat fail [\#83](https://github.com/jwt/ruby-jwt/issues/83)

**Closed issues:**

- Test ticket from Code Climate [\#104](https://github.com/jwt/ruby-jwt/issues/104)
- Test ticket from Code Climate [\#100](https://github.com/jwt/ruby-jwt/issues/100)
- Is it possible to decode the payload without validating the signature? [\#97](https://github.com/jwt/ruby-jwt/issues/97)
- What is audience? [\#96](https://github.com/jwt/ruby-jwt/issues/96)
- Options hash uses both symbols and strings as keys. [\#95](https://github.com/jwt/ruby-jwt/issues/95)

**Merged pull requests:**

- Fix incorrect `iat` examples [\#109](https://github.com/jwt/ruby-jwt/pull/109) ([kjwierenga](https://github.com/kjwierenga))
- Update docs to include instructions for the algorithm parameter. [\#108](https://github.com/jwt/ruby-jwt/pull/108) ([aarongray](https://github.com/aarongray))
- make sure :sub check behaves like :aud check [\#103](https://github.com/jwt/ruby-jwt/pull/103) ([skippy](https://github.com/skippy))
- Change hash syntax [\#101](https://github.com/jwt/ruby-jwt/pull/101) ([excpt](https://github.com/excpt))
- Include LICENSE and README.md in gem [\#99](https://github.com/jwt/ruby-jwt/pull/99) ([bkeepers](https://github.com/bkeepers))
- Remove unused variable in the sample code. [\#98](https://github.com/jwt/ruby-jwt/pull/98) ([hypermkt](https://github.com/hypermkt))
- Fix iat claim example [\#94](https://github.com/jwt/ruby-jwt/pull/94) ([larrylv](https://github.com/larrylv))
- Fix wrong description in README.md [\#93](https://github.com/jwt/ruby-jwt/pull/93) ([larrylv](https://github.com/larrylv))
- JWT and JWA are now RFC. [\#92](https://github.com/jwt/ruby-jwt/pull/92) ([aj-michael](https://github.com/aj-michael))
- Update README.md [\#91](https://github.com/jwt/ruby-jwt/pull/91) ([nsarno](https://github.com/nsarno))
- Fix missing verify parameter in docs [\#90](https://github.com/jwt/ruby-jwt/pull/90) ([ernie](https://github.com/ernie))
- Iat check uses leeway. [\#89](https://github.com/jwt/ruby-jwt/pull/89) ([aj-michael](https://github.com/aj-michael))
- nbf check allows exact time matches. [\#88](https://github.com/jwt/ruby-jwt/pull/88) ([aj-michael](https://github.com/aj-michael))

## [jwt-1.5.1](https://github.com/jwt/ruby-jwt/tree/jwt-1.5.1) (2015-06-22)

[Full Changelog](https://github.com/jwt/ruby-jwt/compare/jwt-1.5.0...jwt-1.5.1)

**Implemented enhancements:**

- Fix either README or source code [\#78](https://github.com/jwt/ruby-jwt/issues/78)
- Validate against draft 20 [\#38](https://github.com/jwt/ruby-jwt/issues/38)

**Fixed bugs:**

- ECDSA signature verification fails for valid tokens [\#84](https://github.com/jwt/ruby-jwt/issues/84)
- Shouldn't verification of additional claims, like iss, aud etc. be enforced when in options? [\#81](https://github.com/jwt/ruby-jwt/issues/81)
- decode fails with 'none' algorithm and verify [\#75](https://github.com/jwt/ruby-jwt/issues/75)

**Closed issues:**

- Doc mismatch: uninitialized constant JWT::ExpiredSignature [\#79](https://github.com/jwt/ruby-jwt/issues/79)
- TypeError when specifying a wrong algorithm [\#77](https://github.com/jwt/ruby-jwt/issues/77)
- jti verification doesn't prevent replays [\#73](https://github.com/jwt/ruby-jwt/issues/73)

**Merged pull requests:**

- Correctly sign ECDSA JWTs [\#87](https://github.com/jwt/ruby-jwt/pull/87) ([jurriaan](https://github.com/jurriaan))
- fixed results of decoded tokens in readme [\#86](https://github.com/jwt/ruby-jwt/pull/86) ([piscolomo](https://github.com/piscolomo))
- Force verification of "iss" and "aud" claims [\#82](https://github.com/jwt/ruby-jwt/pull/82) ([lwe](https://github.com/lwe))

## [jwt-1.5.0](https://github.com/jwt/ruby-jwt/tree/jwt-1.5.0) (2015-05-09)

[Full Changelog](https://github.com/jwt/ruby-jwt/compare/jwt-1.4.1...jwt-1.5.0)

**Implemented enhancements:**

- Needs to support asymmetric key signatures over shared secrets [\#46](https://github.com/jwt/ruby-jwt/issues/46)
- Implement Elliptic Curve Crypto Signatures [\#74](https://github.com/jwt/ruby-jwt/pull/74) ([jtdowney](https://github.com/jtdowney))
- Add an option to verify the signature on decode [\#71](https://github.com/jwt/ruby-jwt/pull/71) ([javawizard](https://github.com/javawizard))

**Closed issues:**

- Check JWT vulnerability [\#76](https://github.com/jwt/ruby-jwt/issues/76)

**Merged pull requests:**

- Fixed some examples to make them copy-pastable [\#72](https://github.com/jwt/ruby-jwt/pull/72) ([jer](https://github.com/jer))

## [jwt-1.4.1](https://github.com/jwt/ruby-jwt/tree/jwt-1.4.1) (2015-03-12)

[Full Changelog](https://github.com/jwt/ruby-jwt/compare/jwt-1.4.0...jwt-1.4.1)

**Fixed bugs:**

- jti verification not working per the spec [\#68](https://github.com/jwt/ruby-jwt/issues/68)
- Verify ISS should be off by default [\#66](https://github.com/jwt/ruby-jwt/issues/66)

**Merged pull requests:**

- Fix \#66 \#68 [\#69](https://github.com/jwt/ruby-jwt/pull/69) ([excpt](https://github.com/excpt))
- When throwing errors, mention expected/received values [\#65](https://github.com/jwt/ruby-jwt/pull/65) ([rolodato](https://github.com/rolodato))

## [jwt-1.4.0](https://github.com/jwt/ruby-jwt/tree/jwt-1.4.0) (2015-03-10)

[Full Changelog](https://github.com/jwt/ruby-jwt/compare/jwt-1.3.0...jwt-1.4.0)

**Closed issues:**

- The behavior using 'json' differs from 'multi\_json' [\#41](https://github.com/jwt/ruby-jwt/issues/41)

**Merged pull requests:**

- Release 1.4.0 [\#64](https://github.com/jwt/ruby-jwt/pull/64) ([excpt](https://github.com/excpt))
- Update README.md and remove dead code [\#63](https://github.com/jwt/ruby-jwt/pull/63) ([excpt](https://github.com/excpt))
- Add  'iat/ aud/ sub/ jti'  support for ruby-jwt [\#62](https://github.com/jwt/ruby-jwt/pull/62) ([ZhangHanDong](https://github.com/ZhangHanDong))
- Add  'iss'  support for ruby-jwt [\#61](https://github.com/jwt/ruby-jwt/pull/61) ([ZhangHanDong](https://github.com/ZhangHanDong))
- Clarify .encode API in README [\#60](https://github.com/jwt/ruby-jwt/pull/60) ([jbodah](https://github.com/jbodah))

## [jwt-1.3.0](https://github.com/jwt/ruby-jwt/tree/jwt-1.3.0) (2015-02-24)

[Full Changelog](https://github.com/jwt/ruby-jwt/compare/jwt-1.2.1...jwt-1.3.0)

**Closed issues:**

- Signature Verification to Return Verification Error rather than decode error [\#57](https://github.com/jwt/ruby-jwt/issues/57)
- Incorrect readme for leeway [\#55](https://github.com/jwt/ruby-jwt/issues/55)
- What is the reason behind stripping the = in base64 encoding? [\#54](https://github.com/jwt/ruby-jwt/issues/54)
- Preperations for version 2.x [\#50](https://github.com/jwt/ruby-jwt/issues/50)
- Release a new version [\#47](https://github.com/jwt/ruby-jwt/issues/47)
- Catch up for ActiveWhatever 4.1.1 series [\#40](https://github.com/jwt/ruby-jwt/issues/40)

**Merged pull requests:**

- raise verification error for signiture verification [\#58](https://github.com/jwt/ruby-jwt/pull/58) ([punkle](https://github.com/punkle))
- Added support for not before claim verification [\#56](https://github.com/jwt/ruby-jwt/pull/56) ([punkle](https://github.com/punkle))

## [jwt-1.2.1](https://github.com/jwt/ruby-jwt/tree/jwt-1.2.1) (2015-01-22)

[Full Changelog](https://github.com/jwt/ruby-jwt/compare/jwt-1.2.0...jwt-1.2.1)

**Closed issues:**

- JWT.encode\({"exp": 10}, "secret"\) [\#52](https://github.com/jwt/ruby-jwt/issues/52)
- JWT.encode\({"exp": 10}, "secret"\) [\#51](https://github.com/jwt/ruby-jwt/issues/51)

**Merged pull requests:**

- Accept expiration claims as string [\#53](https://github.com/jwt/ruby-jwt/pull/53) ([yarmand](https://github.com/yarmand))

## [jwt-1.2.0](https://github.com/jwt/ruby-jwt/tree/jwt-1.2.0) (2014-11-24)

[Full Changelog](https://github.com/jwt/ruby-jwt/compare/jwt-0.1.13...jwt-1.2.0)

**Closed issues:**

- set token to expire [\#42](https://github.com/jwt/ruby-jwt/issues/42)

**Merged pull requests:**

- Added support for `exp` claim [\#45](https://github.com/jwt/ruby-jwt/pull/45) ([zshannon](https://github.com/zshannon))
- rspec 3 breaks passing tests [\#44](https://github.com/jwt/ruby-jwt/pull/44) ([zshannon](https://github.com/zshannon))

## [jwt-0.1.13](https://github.com/jwt/ruby-jwt/tree/jwt-0.1.13) (2014-05-08)

[Full Changelog](https://github.com/jwt/ruby-jwt/compare/jwt-1.0.0...jwt-0.1.13)

**Closed issues:**

- yanking of version 0.1.12 causes issues [\#39](https://github.com/jwt/ruby-jwt/issues/39)
- Semantic versioning [\#37](https://github.com/jwt/ruby-jwt/issues/37)
- Update gem to get latest changes [\#36](https://github.com/jwt/ruby-jwt/issues/36)

## [jwt-1.0.0](https://github.com/jwt/ruby-jwt/tree/jwt-1.0.0) (2014-05-07)

[Full Changelog](https://github.com/jwt/ruby-jwt/compare/jwt-0.1.11...jwt-1.0.0)

**Closed issues:**

- API request - JWT::decoded\_header\(\) [\#26](https://github.com/jwt/ruby-jwt/issues/26)

**Merged pull requests:**

- return header along with playload after decoding [\#35](https://github.com/jwt/ruby-jwt/pull/35) ([sawyerzhang](https://github.com/sawyerzhang))
- Raise JWT::DecodeError on nil token [\#34](https://github.com/jwt/ruby-jwt/pull/34) ([tjmw](https://github.com/tjmw))
- Make MultiJson optional for Ruby 1.9+ [\#33](https://github.com/jwt/ruby-jwt/pull/33) ([petergoldstein](https://github.com/petergoldstein))
- Allow access to header and payload without signature verification [\#32](https://github.com/jwt/ruby-jwt/pull/32) ([petergoldstein](https://github.com/petergoldstein))
- Update specs to use RSpec 3.0.x syntax [\#31](https://github.com/jwt/ruby-jwt/pull/31) ([petergoldstein](https://github.com/petergoldstein))
- Travis - Add Ruby 2.0.0, 2.1.0, Rubinius [\#30](https://github.com/jwt/ruby-jwt/pull/30) ([petergoldstein](https://github.com/petergoldstein))

## [jwt-0.1.11](https://github.com/jwt/ruby-jwt/tree/jwt-0.1.11) (2014-01-17)

[Full Changelog](https://github.com/jwt/ruby-jwt/compare/jwt-0.1.10...jwt-0.1.11)

**Closed issues:**

- url safe encode and decode [\#28](https://github.com/jwt/ruby-jwt/issues/28)
- Release [\#27](https://github.com/jwt/ruby-jwt/issues/27)

**Merged pull requests:**

- fixed urlsafe base64 encoding [\#29](https://github.com/jwt/ruby-jwt/pull/29) ([tobscher](https://github.com/tobscher))

## [jwt-0.1.10](https://github.com/jwt/ruby-jwt/tree/jwt-0.1.10) (2014-01-10)

[Full Changelog](https://github.com/jwt/ruby-jwt/compare/jwt-0.1.8...jwt-0.1.10)

**Closed issues:**

- change to signature of JWT.decode method [\#14](https://github.com/jwt/ruby-jwt/issues/14)

**Merged pull requests:**

- Fix warning: assigned but unused variable - e [\#25](https://github.com/jwt/ruby-jwt/pull/25) ([sferik](https://github.com/sferik))
- Echoe doesn't define a license= method [\#24](https://github.com/jwt/ruby-jwt/pull/24) ([sferik](https://github.com/sferik))
- Use OpenSSL::Digest instead of deprecated OpenSSL::Digest::Digest [\#23](https://github.com/jwt/ruby-jwt/pull/23) ([JuanitoFatas](https://github.com/JuanitoFatas))
- Handle some invalid JWTs [\#22](https://github.com/jwt/ruby-jwt/pull/22) ([steved](https://github.com/steved))
- Add MIT license to gemspec [\#21](https://github.com/jwt/ruby-jwt/pull/21) ([nycvotes-dev](https://github.com/nycvotes-dev))
- Tweaks and improvements [\#20](https://github.com/jwt/ruby-jwt/pull/20) ([threedaymonk](https://github.com/threedaymonk))
- Don't leave errors in OpenSSL.errors when there is a decoding error. [\#19](https://github.com/jwt/ruby-jwt/pull/19) ([lowellk](https://github.com/lowellk))

## [jwt-0.1.8](https://github.com/jwt/ruby-jwt/tree/jwt-0.1.8) (2013-03-14)

[Full Changelog](https://github.com/jwt/ruby-jwt/compare/jwt-0.1.7...jwt-0.1.8)

**Merged pull requests:**

- Contrib and update [\#18](https://github.com/jwt/ruby-jwt/pull/18) ([threedaymonk](https://github.com/threedaymonk))
- Verify if verify is truthy \(not just true\) [\#17](https://github.com/jwt/ruby-jwt/pull/17) ([threedaymonk](https://github.com/threedaymonk))

## [jwt-0.1.7](https://github.com/jwt/ruby-jwt/tree/jwt-0.1.7) (2013-03-07)

[Full Changelog](https://github.com/jwt/ruby-jwt/compare/jwt-0.1.6...jwt-0.1.7)

**Merged pull requests:**

- Catch MultiJson::LoadError and reraise as JWT::DecodeError [\#16](https://github.com/jwt/ruby-jwt/pull/16) ([rwygand](https://github.com/rwygand))

## [jwt-0.1.6](https://github.com/jwt/ruby-jwt/tree/jwt-0.1.6) (2013-03-05)

[Full Changelog](https://github.com/jwt/ruby-jwt/compare/jwt-0.1.5...jwt-0.1.6)

**Merged pull requests:**

- Fixes a theoretical timing attack [\#15](https://github.com/jwt/ruby-jwt/pull/15) ([mgates](https://github.com/mgates))
- Use StandardError as parent for DecodeError [\#13](https://github.com/jwt/ruby-jwt/pull/13) ([Oscil8](https://github.com/Oscil8))

## [jwt-0.1.5](https://github.com/jwt/ruby-jwt/tree/jwt-0.1.5) (2012-07-20)

[Full Changelog](https://github.com/jwt/ruby-jwt/compare/jwt-0.1.4...jwt-0.1.5)

**Closed issues:**

- Unable to specify signature header fields [\#7](https://github.com/jwt/ruby-jwt/issues/7)

**Merged pull requests:**

- MultiJson dependency uses ~\> but should be \>= [\#12](https://github.com/jwt/ruby-jwt/pull/12) ([sporkmonger](https://github.com/sporkmonger))
- Oops. :-\) [\#11](https://github.com/jwt/ruby-jwt/pull/11) ([sporkmonger](https://github.com/sporkmonger))
- Fix issue with signature verification in JRuby [\#10](https://github.com/jwt/ruby-jwt/pull/10) ([sporkmonger](https://github.com/sporkmonger))
- Depend on MultiJson [\#9](https://github.com/jwt/ruby-jwt/pull/9) ([lautis](https://github.com/lautis))
- Allow for custom headers on encode and decode [\#8](https://github.com/jwt/ruby-jwt/pull/8) ([dgrijalva](https://github.com/dgrijalva))
- Missing development dependency for echoe gem. [\#6](https://github.com/jwt/ruby-jwt/pull/6) ([sporkmonger](https://github.com/sporkmonger))

## [jwt-0.1.4](https://github.com/jwt/ruby-jwt/tree/jwt-0.1.4) (2011-11-11)

[Full Changelog](https://github.com/jwt/ruby-jwt/compare/jwt-0.1.3...jwt-0.1.4)

**Merged pull requests:**

- Fix for RSA verification [\#5](https://github.com/jwt/ruby-jwt/pull/5) ([jordan-brough](https://github.com/jordan-brough))

## [jwt-0.1.3](https://github.com/jwt/ruby-jwt/tree/jwt-0.1.3) (2011-06-30)

[Full Changelog](https://github.com/jwt/ruby-jwt/compare/10d7492ea325c65fce41191c73cd90d4de494772...jwt-0.1.3)

**Closed issues:**

- signatures calculated incorrectly \(hexdigest instead of digest\) [\#1](https://github.com/jwt/ruby-jwt/issues/1)

**Merged pull requests:**

- Bumped a version and added a .gemspec using rake build\_gemspec [\#3](https://github.com/jwt/ruby-jwt/pull/3) ([zhitomirskiyi](https://github.com/zhitomirskiyi))
- Added RSA support [\#2](https://github.com/jwt/ruby-jwt/pull/2) ([zhitomirskiyi](https://github.com/zhitomirskiyi))



\* *This Changelog was automatically generated by [github_changelog_generator](https://github.com/github-changelog-generator/github-changelog-generator)*
