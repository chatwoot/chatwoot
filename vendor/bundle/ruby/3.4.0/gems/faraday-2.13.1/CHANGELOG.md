# Faraday Changelog

## The changelog has moved!

This file is not being updated anymore. Instead, please check the [Releases](https://github.com/lostisland/faraday/releases) page.

## [2.2.0](https://github.com/lostisland/faraday/compare/v2.1.0...v2.2.0) (2022-02-03)

* Reintroduce the possibility to register middleware with symbols, strings or procs in [#1391](https://github.com/lostisland/faraday/pull/1391)

## [2.1.0](https://github.com/lostisland/faraday/compare/v2.0.1...v2.1.0) (2022-01-15)

* Fix test adapter thread safety by @iMacTia in [#1380](https://github.com/lostisland/faraday/pull/1380)
* Add default adapter options by @hirasawayuki in [#1382](https://github.com/lostisland/faraday/pull/1382)
* CI: Add Ruby 3.1 to matrix by @petergoldstein in [#1374](https://github.com/lostisland/faraday/pull/1374)
* docs: fix regex pattern in logger.md examples by @hirasawayuki in [#1378](https://github.com/lostisland/faraday/pull/1378)

## [2.0.1](https://github.com/lostisland/faraday/compare/v2.0.0...v2.0.1) (2022-01-05)

* Re-add `faraday-net_http` as default adapter by @iMacTia in [#1366](https://github.com/lostisland/faraday/pull/1366)
* Updated sample format in UPGRADING.md by @vimutter in [#1361](https://github.com/lostisland/faraday/pull/1361)
* docs: Make UPGRADING examples more copyable by @olleolleolle in [#1363](https://github.com/lostisland/faraday/pull/1363)

## [2.0.0](https://github.com/lostisland/faraday/compare/v1.8.0...v2.0.0) (2022-01-04)

The next major release is here, and it comes almost 2 years after the release of v1.0!

This release changes the way you use Faraday and embraces a new paradigm of Faraday as an ecosystem, rather than a library.

What does that mean? It means that Faraday is less of a bundled tool and more of a framework for the community to build on top of.

As a result, all adapters and some middleware have moved out and are now shipped as standalone gems 🙌!

But this doesn't mean that upgrading from Faraday 1.x to Faraday 2.0 should be hard, in fact we've listed everything you need to do in the [UPGRADING.md](https://github.com/lostisland/faraday/blob/main/UPGRADING.md) doc.

Moreover, we've setup a new [awesome-faraday](https://github.com/lostisland/awesome-faraday) repository that will showcase a curated list of adapters and middleware 😎.

This release was the result of the efforts of the core team and all the contributors, new and old, that have helped achieve this milestone 👏.

## What's Changed

* Autoloading, dependency loading and middleware registry cleanup by @iMacTia in [#1301](https://github.com/lostisland/faraday/pull/1301)
* Move JSON middleware (request and response) from faraday_middleware by @iMacTia in [#1300](https://github.com/lostisland/faraday/pull/1300)
* Remove deprecated `Faraday::Request#method` by @olleolleolle in [#1303](https://github.com/lostisland/faraday/pull/1303)
* Remove deprecated `Faraday::UploadIO` by @iMacTia in [#1307](https://github.com/lostisland/faraday/pull/1307)
* [1.x] Deprecate Authorization helpers in `Faraday::Connection` by @iMacTia in [#1306](https://github.com/lostisland/faraday/pull/1306)
* Drop deprecated auth helpers from Connection and refactor auth middleware by @iMacTia in [#1308](https://github.com/lostisland/faraday/pull/1308)
* Add Faraday 1.x examples in authentication.md docs by @iMacTia in [#1320](https://github.com/lostisland/faraday/pull/1320)
* Fix passing a URL with embedded basic auth by @iMacTia in [#1324](https://github.com/lostisland/faraday/pull/1324)
* Register JSON middleware by @mollerhoj in [#1331](https://github.com/lostisland/faraday/pull/1331)
* Retry middleware should handle string exception class name consistently by @jrochkind in [#1334](https://github.com/lostisland/faraday/pull/1334)
* Improve request info in exceptions raised by RaiseError Middleware by @willianzocolau in [#1335](https://github.com/lostisland/faraday/pull/1335)
* Remove net-http adapter and update docs by @iMacTia in [#1336](https://github.com/lostisland/faraday/pull/1336)
* Explain plan for faraday_middleware in UPGRADING.md by @iMacTia in [#1339](https://github.com/lostisland/faraday/pull/1339)
* Scripts folder cleanup by @iMacTia in [#1340](https://github.com/lostisland/faraday/pull/1340)
* Replace `Hash#merge` with `Utils#deep_merge` for connection options by @xkwd in [#1343](https://github.com/lostisland/faraday/pull/1343)
* Callable authorizers by @sled in [#1345](https://github.com/lostisland/faraday/pull/1345)
* Default value for exc error by @DariuszMusielak in [#1351](https://github.com/lostisland/faraday/pull/1351)
* Don't call `retry_block` unless a retry is going to happen by @jrochkind in [#1350](https://github.com/lostisland/faraday/pull/1350)
* Improve documentation for v2 by @iMacTia in [#1353](https://github.com/lostisland/faraday/pull/1353)
* Remove default `default_adapter` (yes, you read that right) by @iMacTia in [#1354](https://github.com/lostisland/faraday/pull/1354)
* Remove retry middleware by @iMacTia in [#1356](https://github.com/lostisland/faraday/pull/1356)
* Remove multipart middleware and all its documentation and tests by @iMacTia in [#1357](https://github.com/lostisland/faraday/pull/1357)

## [1.9.3](https://github.com/lostisland/faraday/compare/v1.9.2...v1.9.3) (2022-01-06)

* Re-add support for Ruby 2.4+ by @iMacTia in [#1371](https://github.com/lostisland/faraday/pull/1371)

## [1.9.2](https://github.com/lostisland/faraday/compare/v1.9.1...v1.9.2) (2022-01-06)

* Add alias with legacy name to gemified middleware by @iMacTia in [#1372](https://github.com/lostisland/faraday/pull/1372)

## [1.9.1](https://github.com/lostisland/faraday/compare/v1.9.0...v1.9.1) (2022-01-06)

* Update adapter dependencies in Gemspec by @iMacTia in [#1370](https://github.com/lostisland/faraday/pull/1370)

## [1.9.0](https://github.com/lostisland/faraday/compare/v1.8.0...v1.9.0) (2022-01-06)

* Use external multipart and retry middleware by @iMacTia in [#1367](https://github.com/lostisland/faraday/pull/1367)

## [1.8.0](https://github.com/lostisland/faraday/releases/tag/v1.8.0) (2021-09-18)

### Features

* Backport authorization procs (#1322, @jarl-dk)

## [v1.7.0](https://github.com/lostisland/faraday/releases/tag/v1.7.0) (2021-08-09)

### Features

* Add strict_mode to Test::Stubs (#1298, @yykamei)

## [v1.6.0](https://github.com/lostisland/faraday/releases/tag/v1.6.0) (2021-08-01)

### Misc

* Use external Rack adapter (#1296, @iMacTia)

## [v1.5.1](https://github.com/lostisland/faraday/releases/tag/v1.5.1) (2021-07-11)

### Fixes

* Fix JRuby incompatibility after moving out EM adapters (#1294, @ahorek)

### Documentation

* Update YARD to follow RackBuilder (#1292, @kachick)

## [v1.5.0](https://github.com/lostisland/faraday/releases/tag/v1.5.0) (2021-07-04)

### Misc

* Use external httpclient adapter (#1289, @iMacTia)
* Use external patron adapter (#1290, @iMacTia)

## [v1.4.3](https://github.com/lostisland/faraday/releases/tag/v1.4.3) (2021-06-24)

### Fixes

* Silence warning (#1286, @gurgeous)
* Always dup url_prefix in Connection#build_exclusive_url (#1288, @alexeyds)

## [v1.4.2](https://github.com/lostisland/faraday/releases/tag/v1.4.2) (2021-05-22)

### Fixes
* Add proxy setting when url_prefix is changed (#1276, @ci)
* Default proxy scheme to http:// if necessary, fixes #1282 (#1283, @gurgeous)

### Documentation
* Improve introduction page (#1273, @gurgeous)
* Docs: add more middleware examples (#1277, @gurgeous)

### Misc
* Use external `em_http` and `em_synchrony` adapters (#1274, @iMacTia)

## [v1.4.1](https://github.com/lostisland/faraday/releases/tag/v1.4.1) (2021-04-18)

### Fixes

* Fix dependencies from external adapter gems (#1269, @iMacTia)

## [v1.4.0](https://github.com/lostisland/faraday/releases/tag/v1.4.0) (2021-04-16)

### Highlights

With this release, we continue the work of gradually moving out adapters into their own gems 🎉
Thanks to @MikeRogers0 for helping the Faraday team in progressing with this quest 👏

And thanks to @olleolleolle efforts, Faraday is becoming more inclusive than ever 🤗
Faraday's `master` branch has been renamed into `main`, we have an official policy on inclusive language and even a rubocop plugin to check for non-inclusive words ❤️!
Checkout the "Misc" section below for more details 🙌 !

### Fixes

* Fix NoMethodError undefined method 'coverage' (#1255, @Maroo-b)

### Documentation

* Some docs on EventMachine adapters. (#1232, @damau)
* CONTRIBUTING: Fix grammar and layout (#1261, @olleolleolle)

### Misc

* Replacing Net::HTTP::Persistent with faraday-net_http_persistent (#1250, @MikeRogers0)
* CI: Configure the regenerated Coveralls token (#1256, @olleolleolle)
* Replace Excon adapter with Faraday::Excon gem, and fix autoloading issue with Faraday::NetHttpPersistent (#1257, @iMacTia)
* Drop CodeClimate (#1259, @olleolleolle)
* CI: Rename default branch to main (#1263, @olleolleolle)
* Drop RDoc support file .document (#1264, @olleolleolle, @iMacTia)
* CONTRIBUTING: add a policy on inclusive language (#1262, @olleolleolle)
* Add rubocop-inclusivity (#1267, @olleolleolle, @iMacTia)

## [v1.3.1](https://github.com/lostisland/faraday/releases/tag/v1.3.1) (2021-04-16)

### Fixes

* Escape colon in path segment (#1237, @yarafan)
* Handle IPv6 address String on Faraday::Connection#proxy_from_env (#1252, @cosmo0920)

### Documentation

* Fix broken Rubydoc.info links (#1236, @nickcampbell18)
* Add httpx to list of external adapters (#1246, @HoneyryderChuck)

### Misc

* Refactor CI to remove duplicated line (#1230, @tricknotes)
* Gemspec: Pick a good ruby2_keywords release (#1241, @olleolleolle)

## [v1.3.0](https://github.com/lostisland/faraday/releases/tag/v1.3.0) (2020-12-31)

### Highlights
Faraday v1.3.0 is the first release to officially support Ruby 3.0 in the CI pipeline 🎉 🍾!

This is also the first release with a previously "included" adapter (Net::HTTP) being isolated into a [separate gem](https://github.com/lostisland/faraday-net_http) 🎊!
The new adapter is added to Faraday as a dependency for now, so that means full backwards-compatibility, but just to be safe be careful when upgrading!

This is a huge step towards are Faraday v2.0 objective of pushing adapters and middleware into separate gems.
Many thanks to the Faraday Team, @JanDintel and everyone who attended the [ROSS Conf remote event](https://www.rossconf.io/event/remote/)

### Features

* Improves consistency with Faraday::Error and Faraday::RaiseError (#1229, @qsona, @iMacTia)

### Fixes

* Don't assign to global ::Timer (#1227, @bpo)

### Documentation

* CHANGELOG: add releases after 1.0 (#1225, @olleolleolle)
* Improves retry middleware documentation. (#1228, @iMacTia)

### Misc

* Move out Net::HTTP adapter (#1222, @JanDintel, @iMacTia)
* Adds Ruby 3.0 to CI Matrix (#1226, @iMacTia)


## [v1.2.0](https://github.com/lostisland/faraday/releases/tag/v1.2.0) (2020-12-23)

### Features

* Introduces `on_request` and `on_complete` methods in `Faraday::Middleware`. (#1194, @iMacTia)

### Fixes

* Require 'date' to avoid retry exception (#1206, @rustygeldmacher)
* Fix rdebug recursion issue (#1205, @native-api)
* Update call to `em_http_ssl_patch` (#1202, @kylekeesling)
* `EmHttp` adapter: drop superfluous loaded? check (#1213, @olleolleolle)
* Avoid 1 use of keyword hackery (#1211, @grosser)
* Fix #1219 `Net::HTTP` still uses env proxy (#1221, @iMacTia)

### Documentation

* Add comment in gemspec to explain exposure of `examples` and `spec` folders. (#1192, @iMacTia)
* Adapters, how to create them (#1193, @olleolleolle)
* Update documentation on using the logger (#1196, @tijmenb)
* Adjust the retry documentation and spec to align with implementation (#1198, @nbeyer)

### Misc

* Test against ruby head (#1208, @grosser)

## [v1.1.0](https://github.com/lostisland/faraday/releases/tag/v1.1.0) (2020-10-17)

### Features

* Makes parameters sorting configurable (#1162 @wishdev)
* Introduces `flat_encode` option for multipart adapter. (#1163 @iMacTia)
* Include request info in exceptions raised by RaiseError Middleware (#1181 @SandroDamilano)

### Fixes

* Avoid `last arg as keyword param` warning when building user middleware on Ruby 2.7 (#1153 @dgholz)
* Limits net-http-persistent version to < 4.0 (#1156 @iMacTia)
* Update `typhoeus` to new stable version (`1.4`) (#1159 @AlexWayfer)
* Properly fix test failure with Rack 2.1+. (#1171 @voxik)

### Documentation

* Improves documentation on how to contribute to the site by using Docker. (#1175 @iMacTia)
* Remove retry_change_requests from documentation (#1185 @stim371)

### Misc

* Link from GitHub Actions badge to CI workflow (#1141 @olleolleolle)
* Return tests of `Test` adapter (#1147 @AlexWayfer)
* Add 1.0 release to wording in CONTRIBUTING (#1155 @olleolleolle)
* Fix linting bumping Rubocop to 0.90.0 (#1182 @iMacTia)
* Drop `git ls-files` in gemspec (#1183 @utkarsh2102)
* Upgrade CI to ruby/setup-ruby (#1187 @gogainda)

## [v1.0.1](https://github.com/lostisland/faraday/releases/tag/v1.0.1) (2020-03-29)

### Fixes

* Use Net::HTTP#start(&block) to ensure closed TCP connections (#1117)
* Fully qualify constants to be checked (#1122)
* Allows `parse` method to be private/protected in response middleware (#1123)
* Encode Spaces in Query Strings as '%20' Instead of '+' (#1125)
* Limits rack to v2.0.x (#1127)
* Adapter Registry reads also use mutex (#1136)

### Documentation

* Retry middleware documentation fix (#1109)
* Docs(retry): precise usage of retry-after (#1111)
* README: Link the logo to the website (#1112)
* Website: add search bar (#1116)
* Fix request/response mix-up in docs text (#1132)

## [v1.0](https://github.com/lostisland/faraday/releases/tag/v1.0.0) (2020-01-22)

Features:

* Add #trace support to Faraday::Connection #861 (@technoweenie)
* Add the log formatter that is easy to override and safe to inherit #889 (@prikha)
* Support standalone adapters #941 (@iMacTia)
* Introduce Faraday::ConflictError for 409 response code #979 (@lucasmoreno)
* Add support for setting `read_timeout` option separately #1003 (@springerigor)
* Refactor and cleanup timeout settings across adapters #1022 (@technoweenie)
* Create ParamPart class to allow multipart posts with JSON content and file upload at the same time #1017 (@jeremy-israel)
* Copy UploadIO const -> FilePart for consistency with ParamPart #1018, #1021 (@technoweenie)
* Implement streaming responses in the Excon adapter #1026 (@technoweenie)
* Add default implementation of `Middleware#close`. #1069 (@ioquatix)
* Add `Adapter#close` so that derived classes can call super. #1091 (@ioquatix)
* Add log_level option to logger default formatter #1079 (@amrrbakry)
* Fix empty array for FlatParamsEncoder `{key: []} -> "key="` #1084 (@mrexox)

Bugs:

* Explicitly require date for DateTime library in Retry middleware #844 (@nickpresta)
* Refactor Adapter as final endpoints #846 (@iMacTia)
* Separate Request and Response bodies in Faraday::Env #847 (@iMacTia)
* Implement Faraday::Connection#options to make HTTP requests with the OPTIONS verb. #857 (@technoweenie)
* Multipart: Drop Ruby 1.8 String behavior compat #892 (@olleolleolle)
* Fix Ruby warnings in Faraday::Options.memoized #962 (@technoweenie)
* Allow setting min/max SSL version for a Net::HTTP::Persistent connection #972, #973 (@bdewater, @olleolleolle)
* Fix instances of frozen empty string literals #1040 (@BobbyMcWho)
* remove temp_proxy and improve proxy tests #1063 (@technoweenie)
* improve error initializer consistency #1095 (@technoweenie)

Misc:

* Convert minitest suite to RSpec #832 (@iMacTia, with help from @gaynetdinov, @Insti, @technoweenie)
* Major effort to update code to RuboCop standards. #854 (@olleolleolle, @iMacTia, @technoweenie, @htwroclau, @jherdman, @Drenmi, @Insti)
* Rubocop #1044, #1047 (@BobbyMcWho, @olleolleolle)
* Documentation tweaks (@adsteel, @Hubro, @iMacTia, @olleolleolle, @technoweenie)
* Update license year #981 (@Kevin-Kawai)
* Configure Jekyll plugin jekyll-remote-theme to support Docker usage #999 (@Lewiscowles1986)
* Fix Ruby 2.7 warnings #1009 (@tenderlove)
* Cleanup adapter connections #1023 (@technoweenie)
* Describe clearing cached stubs #1045 (@viraptor)
* Add project metadata to the gemspec #1046 (@orien)

## v0.17.4

Fixes:

* NetHttp adapter: wrap Errno::EADDRNOTAVAIL (#1114, @embs)
* Fix === for subclasses of deprecated classes (#1243, @mervync)

## v0.17.3

Fixes:

* Reverts changes in error classes hierarchy. #1092 (@iMacTia)
* Fix Ruby 1.9 syntax errors and improve Error class testing #1094 (@BanzaiMan,
  @mrexox, @technoweenie)

Misc:

* Stops using `&Proc.new` for block forwarding. #1083 (@olleolleolle)
* Update CI to test against ruby 2.0-2.7 #1087, #1099 (@iMacTia, @olleolleolle,
  @technoweenie)
* require FARADAY_DEPRECATE=warn to show Faraday v1.0 deprecation warnings
  #1098 (@technoweenie)

## v0.17.1

Final release before Faraday v1.0, with important fixes for Ruby 2.7.

Fixes:

* RaiseError response middleware raises exception if HTTP client returns a nil
  status. #1042 (@jonnyom, @BobbyMcWho)

Misc:

* Fix Ruby 2.7 warnings (#1009)
* Add `Faraday::Deprecate` to warn about upcoming v1.0 changes. (#1054, #1059,
    #1076, #1077)
* Add release notes up to current in CHANGELOG.md (#1066)
* Port minimal rspec suite from main branch to run backported tests. (#1058)

## v0.17.0

This release is the same as v0.15.4. It was pushed to cover up releases
v0.16.0-v0.16.2.

## v0.15.4

* Expose `pool_size` as a option for the NetHttpPersistent adapter (#834)

## v0.15.3

* Make Faraday::Request serialisable with Marshal. (#803)
* Add DEFAULT_EXCEPTIONS constant to Request::Retry (#814)
* Add support for Ruby 2.6 Net::HTTP write_timeout (#824)

## v0.15.2

* Prevents `Net::HTTP` adapters to retry request internally by setting `max_retries` to 0 if available (Ruby 2.5+). (#799)
* Fixes `NestedParamsEncoder` handling of empty array values (#801)

## v0.15.1

* NetHttpPersistent adapter better reuse of SSL connections (#793)
* Refactor: inline cached_connection (#797)
* Logger middleware: use $stdout instead of STDOUT (#794)
* Fix: do not memoize/reuse Patron session (#796)

Also in this release:

* Allow setting min/max ssl version for Net::HTTP (#792)
* Allow setting min/max ssl version for Excon (#795)

## v0.15.0

Features:

* Added retry block option to retry middleware. (#770)
* Retry middleware improvements (honour Retry-After header, retry statuses) (#773)
* Improve response logger middleware output (#784)

Fixes:

* Remove unused class error (#767)
* Fix minor typo in README (#760)
* Reuse persistent connections when using net-http-persistent (#778)
* Fix Retry middleware documentation (#781)
* Returns the http response when giving up on retrying by status (#783)

## v0.14.0

Features:

* Allow overriding env proxy #754 (@iMacTia)
* Remove legacy Typhoeus adapter #715 (@olleolleolle)
* External Typhoeus Adapter Compatibility #748 (@iMacTia)
* Warn about missing adapter when making a request #743 (@antstorm)
* Faraday::Adapter::Test stubs now support entire urls (with host) #741 (@erik-escobedo)

Fixes:

* If proxy is manually provided, this takes priority over `find_proxy` #724 (@iMacTia)
* Fixes the behaviour for Excon's open_timeout (not setting write_timeout anymore) #731 (@apachelogger)
* Handle all connection timeout messages in Patron #687 (@stayhero)

## v0.13.1

* Fixes an incompatibility with Addressable::URI being used as uri_parser

## v0.13.0

Features:

* Dynamically reloads the proxy when performing a request on an absolute domain (#701)
* Adapter support for Net::HTTP::Persistent v3.0.0 (#619)

Fixes:

* Prefer #hostname over #host. (#714)
* Fixes an edge-case issue with response headers parsing (missing HTTP header) (#719)

## v0.12.2

* Parse headers from aggregated proxy requests/responses (#681)
* Guard against invalid middleware configuration with warning (#685)
* Do not use :insecure option by default in Patron (#691)
* Fixes an issue with HTTPClient not raising a `Faraday::ConnectionFailed` (#702)
* Fixes YAML serialization/deserialization for `Faraday::Utils::Headers` (#690)
* Fixes an issue with Options having a nil value (#694)
* Fixes an issue with Faraday.default_connection not using Faraday.default_connection_options (#698)
* Fixes an issue with Options.merge! and Faraday instrumentation middleware (#710)

## v0.12.1

* Fix an issue with Patron tests failing on jruby
* Fix an issue with new `rewind_files` feature that was causing an exception when the body was not an Hash
* Expose wrapped_exception in all client errors
* Add Authentication Section to the ReadMe

## v0.12.0.1

* Hotfix release to address an issue with TravisCI deploy on Rubygems

## v0.12.0

Features:

* Proxy feature now relies on Ruby `URI::Generic#find_proxy` and can use `no_proxy` ENV variable (not compatible with ruby < 2.0)
* Adds support for `context` request option to pass arbitrary information to middlewares

Fixes:

* Fix an issue with options that was causing new options to override defaults ones unexpectedly
* Rewind `UploadIO`s on retry to fix a compatibility issue
* Make multipart boundary unique
* Improvements in `README.md`

## v0.11.0

Features:

* Add `filter` method to Logger middleware
* Add support for Ruby2.4 and Minitest 6
* Introduce block syntax to customise the adapter

Fixes:

* Fix an issue that was allowing to override `default_connection_options` from a connection instance
* Fix a bug that was causing newline escape characters ("\n") to be used when building the Authorization header

## v0.10.1

- Fix an issue with HTTPClient adapter that was causing the SSL to be reset on every request
- Rescue `IOError` instead of specific subclass
- `Faraday::Utils::Headers` can now be successfully serialised in YAML
- Handle `default_connection_options` set with hash

## v0.10.0

Breaking changes:
- Drop support for Ruby 1.8

Features:
- Include wrapped exception/response in ClientErrors
- Add `response.reason_phrase`
- Provide option to selectively skip logging request/response headers
- Add regex support for pattern matching in `test` adapter

Fixes:
- Add `Faraday.respond_to?` to find methods managed by `method_missing`
- em-http: `request.host` instead of `connection.host` should be taken for SSL validations
- Allow `default_connection_options` to be merged when options are passed as url parameter
- Improve splitting key-value pairs in raw HTTP headers

## v0.9.2

Adapters:
- Enable gzip compression for httpclient
- Fixes default certificate store for httpclient not having default paths.
- Make excon adapter compatible with 0.44 excon version
- Add compatibility with Patron 0.4.20
- Determine default port numbers in Net::HTTP adapters (Addressable compatibility)
- em-http: wrap "connection closed by server" as ConnectionFailed type
- Wrap Errno::ETIMEDOUT in Faraday::Error::TimeoutError

Utils:
- Add Rack-compatible support for parsing `a[][b]=c` nested queries
- Encode nil values in queries different than empty strings. Before: `a=`; now: `a`.
- Have `Faraday::Utils::Headers#replace` clear internal key cache
- Dup the internal key cache when a Headers hash is copied

Env and middleware:
- Ensure `env` stored on middleware response has reference to the response
- Ensure that Response properties are initialized during `on_complete` (VCR compatibility)
- Copy request options in Faraday::Connection#dup
- Env custom members should be copied by Env.from(env)
- Honour per-request `request.options.params_encoder`
- Fix `interval_randomness` data type for Retry middleware
- Add maximum interval option for Retry middleware

## v0.9.1

* Refactor Net:HTTP adapter so that with_net_http_connection can be overridden to allow pooled connections. (@Ben-M)
* Add configurable methods that bypass `retry_if` in the Retry request middleware.  (@mike-bourgeous)

## v0.9.0

* Add HTTPClient adapter (@hakanensari)
* Improve Retry handler (@mislav)
* Remove autoloading by default (@technoweenie)
* Improve internal docs (@technoweenie, @mislav)
* Respect user/password in http proxy string (@mislav)
* Adapter options are structs.  Reinforces consistent options across adapters
  (@technoweenie)
* Stop stripping trailing / off base URLs in a Faraday::Connection. (@technoweenie)
* Add a configurable URI parser. (@technoweenie)
* Remove need to manually autoload when using the authorization header helpers on `Faraday::Connection`. (@technoweenie)
* `Faraday::Adapter::Test` respects the `Faraday::RequestOptions#params_encoder` option. (@technoweenie)
