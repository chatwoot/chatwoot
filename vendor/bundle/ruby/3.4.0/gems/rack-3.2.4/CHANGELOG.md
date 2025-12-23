# Changelog

All notable changes to this project will be documented in this file. For info on how to format all future additions to this file please reference [Keep A Changelog](https://keepachangelog.com/en/1.0.0/).

## [3.2.4] - 2025-11-03

### Fixed

- Multipart parser: limit MIME header size check to the unread buffer region to avoid false `multipart mime part header too large` errors when previously read data accumulates in the scan buffer. ([#2392](https://github.com/rack/rack/pull/2392), [@alpaca-tc](https://github.com/alpaca-tc), [@willnet](https://github.com/willnet), [@krororo](https://github.com/krororo))

## [3.2.3] - 2025-10-10

### Security

- [CVE-2025-61780](https://github.com/advisories/GHSA-r657-rxjc-j557) Improper handling of headers in `Rack::Sendfile` may allow proxy bypass.
- [CVE-2025-61919](https://github.com/advisories/GHSA-6xw4-3v39-52mm) Unbounded read in `Rack::Request` form parsing can lead to memory exhaustion.

## [3.2.2] - 2025-10-07

### Security

- [CVE-2025-61772](https://github.com/advisories/GHSA-wpv5-97wm-hp9c) Multipart parser buffers unbounded per-part headers, enabling DoS (memory exhaustion)
- [CVE-2025-61771](https://github.com/advisories/GHSA-w9pc-fmgc-vxvw) Multipart parser buffers large non‑file fields entirely in memory, enabling DoS (memory exhaustion)
- [CVE-2025-61770](https://github.com/advisories/GHSA-p543-xpfm-54cp) Unbounded multipart preamble buffering enables DoS (memory exhaustion)

## [3.2.1] -- 2025-09-02

### Added

- Add support for streaming bodies when using `Rack::Events`. ([#2375](github.com/rack/rack/pull/2375), [@unflxw](https://github.com/unflxw))

### Fixed

- Fix an issue where a `NoMethodError` would be raised when using `Rack::Events` with streaming bodies. ([#2375](github.com/rack/rack/pull/2375), [@unflxw](https://github.com/unflxw))

## [3.2.0] - 2025-07-31

This release continues Rack's evolution toward a cleaner, more efficient foundation while maintaining backward compatibility for most applications. The breaking changes primarily affect deprecated functionality, so most users should experience a smooth upgrade with improved performance and standards compliance.

### SPEC Changes

- Request environment keys must now be strings. ([#2310](https://github.com/rack/rack/issues/2310), [@jeremyevans])
- Add `nil` as a valid return from a Response `body.to_path` ([#2318](https://github.com/rack/rack/pull/2318), [@MSP-Greg])
- `Rack::Lint#check_header_value` is relaxed, only disallowing CR/LF/NUL characters. ([#2354](https://github.com/rack/rack/pull/2354), [@ioquatix])

### Added

- Introduce `Rack::VERSION` constant. ([#2199](https://github.com/rack/rack/pull/2199), [@ioquatix])
- `ISO-2022-JP` encoded parts within MIME Multipart sections of an HTTP request body will now be converted to `UTF-8`. ([#2245](https://github.com/rack/rack/pull/2245), [@nappa](https://github.com/nappa))
- Add `Rack::Request#query_parser=` to allow setting the query parser to use. ([#2349](https://github.com/rack/rack/pull/2349), [@jeremyevans])
- Add `Rack::Request#form_pairs` to access form data as raw key-value pairs, preserving duplicate keys. ([#2351](https://github.com/rack/rack/pull/2351), [@matthewd])

### Changed

- Invalid cookie keys will now raise an error. ([#2193](https://github.com/rack/rack/pull/2193), [@ioquatix])
- `Rack::MediaType#params` now handles empty strings. ([#2229](https://github.com/rack/rack/pull/2229), [@jeremyevans])
- Avoid unnecessary calls to the `ip_filter` lambda to evaluate `Request#ip` ([#2287](https://github.com/rack/rack/pull/2287), [@willbryant])
- Only calculate `Request#ip` once per request ([#2292](https://github.com/rack/rack/pull/2292), [@willbryant])
- `Rack::Builder` `#use`, `#map`, and `#run` methods now return `nil`. ([#2355](https://github.com/rack/rack/pull/2355), [@ioquatix])
- Directly close the body in `Rack::ConditionalGet` when the response is `304 Not Modified`. ([#2353](https://github.com/rack/rack/pull/2353), [@ioquatix])
- Directly close the body in `Rack::Head` when the request method is `HEAD`([#2360](https://github.com/rack/rack/pull/2360), [@skipkayhil](https://github.com/skipkayhil))

### Deprecated

- `Rack::Auth::AbstractRequest#request` is deprecated without replacement. ([#2229](https://github.com/rack/rack/pull/2229), [@jeremyevans])
- `Rack::Request#parse_multipart` (private method designed to be overridden in subclasses) is deprecated without replacement. ([#2229](https://github.com/rack/rack/pull/2229), [@jeremyevans])

### Removed

- `Rack::Request#values_at` is removed. ([#2200](https://github.com/rack/rack/pull/2200), [@ioquatix])
- `Rack::Logger` is removed with no replacement. ([#2196](https://github.com/rack/rack/pull/2196), [@ioquatix])
- Automatic cache invalidation in `Rack::Request#{GET,POST}` has been removed. ([#2230](https://github.com/rack/rack/pull/2230), [@jeremyevans])
- Support for `CGI::Cookie` has been removed. ([#2332](https://github.com/rack/rack/pull/2332), [@ioquatix])

### Fixed

- `Rack::RewindableInput::Middleware` no longer wraps a nil input. ([#2259](https://github.com/rack/rack/pull/2259), [@tt](https://github.com/tt))
- Fix `NoMethodError` in `Rack::Request#wrap_ipv6` when `x-forwarded-host` is empty. ([#2270](https://github.com/rack/rack/pull/2270), [@oieioi](https://github.com/oieioi))
- Fix the specification for `SERVER_PORT` which was incorrectly documented as required to be an `Integer` if present - it must be a `String` containing digits only. ([#2296](https://github.com/rack/rack/pull/2296), [@ioquatix])
- `SERVER_NAME` and `HTTP_HOST` are now more strictly validated according to the relevant specifications. ([#2298](https://github.com/rack/rack/pull/2298), [@ioquatix])
- `Rack::Lint` now disallows `PATH_INFO="" SCRIPT_NAME=""`. ([#2298](https://github.com/rack/rack/issues/2307), [@jeremyevans])

## [3.1.19] - 2025-11-03

### Fixed

- Multipart parser: limit MIME header size check to the unread buffer region to avoid false `multipart mime part header too large` errors when previously read data accumulates in the scan buffer. ([#2392](https://github.com/rack/rack/pull/2392), [@alpaca-tc](https://github.com/alpaca-tc), [@willnet](https://github.com/willnet), [@krororo](https://github.com/krororo))

## [3.1.18] - 2025-10-10

### Security

- [CVE-2025-61780](https://github.com/advisories/GHSA-r657-rxjc-j557) Improper handling of headers in `Rack::Sendfile` may allow proxy bypass.
- [CVE-2025-61919](https://github.com/advisories/GHSA-6xw4-3v39-52mm) Unbounded read in `Rack::Request` form parsing can lead to memory exhaustion.

## [3.1.17] - 2025-10-07

### Security

- [CVE-2025-61772](https://github.com/advisories/GHSA-wpv5-97wm-hp9c) Multipart parser buffers unbounded per-part headers, enabling DoS (memory exhaustion)
- [CVE-2025-61771](https://github.com/advisories/GHSA-w9pc-fmgc-vxvw) Multipart parser buffers large non‑file fields entirely in memory, enabling DoS (memory exhaustion)
- [CVE-2025-61770](https://github.com/advisories/GHSA-p543-xpfm-54cp) Unbounded multipart preamble buffering enables DoS (memory exhaustion)

## [3.1.16] - 2025-06-04

### Security

- [CVE-2025-49007](https://github.com/advisories/GHSA-47m2-26rw-j2jw) Fix ReDoS in multipart request.

## [3.1.15] - 2025-05-18

- Optional support for `CGI::Cookie` if not available. ([#2327](https://github.com/rack/rack/pull/2327), [#2333](https://github.com/rack/rack/pull/2333), [@earlopain])

## [3.1.14] - 2025-05-06

:warning: **This release includes a security fix that may cause certain routes in previously working applications to fail if query parameters exceed 4,096 in count or 4 MB in total size. See <https://github.com/rack/rack/discussions/2356> for more details.**

### Security

- [CVE-2025-46727](https://github.com/advisories/GHSA-gjh7-p2fx-99vx) Unbounded parameter parsing in `Rack::QueryParser` can lead to memory exhaustion.

## [3.1.13] - 2025-04-13

- Ensure `Rack::ETag` correctly updates response body. ([#2324](https://github.com/rack/rack/pull/2324), [@ioquatix])

## [3.1.12] - 2025-03-11

### Security

- [CVE-2025-27610](https://github.com/advisories/GHSA-7wqh-767x-r66v) Local file inclusion in `Rack::Static`.

## [3.1.11] - 2025-03-04

### Security

- [CVE-2025-27111](https://github.com/advisories/GHSA-8cgq-6mh2-7j6v) Possible Log Injection in `Rack::Sendfile`.

## [3.1.10] - 2025-02-12

### Security

- [CVE-2025-25184](https://github.com/advisories/GHSA-7g2v-jj9q-g3rg) Possible Log Injection in `Rack::CommonLogger`.

## [3.1.9] - 2025-01-31

### Fixed

- `Rack::MediaType#params` now handles parameters without values. ([#2263](https://github.com/rack/rack/pull/2263), [@AllyMarthaJ](https://github.com/AllyMarthaJ))

## [3.1.8] - 2024-10-14

### Fixed

- Resolve deprecation warnings about uri `DEFAULT_PARSER`. ([#2249](https://github.com/rack/rack/pull/2249), [@earlopain])

## [3.1.7] - 2024-07-11

### Fixed

- Do not remove escaped opening/closing quotes for content-disposition filenames. ([#2229](https://github.com/rack/rack/pull/2229), [@jeremyevans])
- Fix encoding setting for non-binary IO-like objects in MockRequest#env_for. ([#2227](https://github.com/rack/rack/pull/2227), [@jeremyevans])
- `Rack::Response` should not generate invalid `content-length` header. ([#2219](https://github.com/rack/rack/pull/2219), [@ioquatix])
- Allow empty PATH_INFO. ([#2214](https://github.com/rack/rack/pull/2214), [@ioquatix])

## [3.1.6] - 2024-07-03

### Fixed

- Fix several edge cases in `Rack::Request#parse_http_accept_header`'s implementation. ([#2226](https://github.com/rack/rack/pull/2226), [@ioquatix])

## [3.1.5] - 2024-07-02

### Security

- Fix potential ReDoS attack in `Rack::Request#parse_http_accept_header`. ([GHSA-cj83-2ww7-mvq7](https://github.com/advisories/GHSA-cj83-2ww7-mvq7), [@dwisiswant0](https://github.com/dwisiswant0))

## [3.1.4] - 2024-06-22

### Fixed

- Fix `Rack::Lint` matching some paths incorrectly as authority form. ([#2220](https://github.com/rack/rack/pull/2220), [@ioquatix])

## [3.1.3] - 2024-06-12

### Fixed

- Fix passing non-strings to `Rack::Utils.escape_html`. ([#2202](https://github.com/rack/rack/pull/2202), [@earlopain])
- `Rack::MockResponse` gracefully handles empty cookies ([#2203](https://github.com/rack/rack/pull/2203) [@wynksaiddestroy])

## [3.1.2] - 2024-06-11

- `Rack::Response` will take in to consideration chunked encoding responses ([#2204](https://github.com/rack/rack/pull/2204), [@tenderlove])

## [3.1.1] - 2024-06-11

- Oops! I shouldn't have shipped that

## [3.1.0] - 2024-06-11

:warning: **This release includes several breaking changes.** Refer to the **Removed** section below for the list of deprecated methods that have been removed in this release.

This release is primarily a maintenance release that removes features deprecated in Rack v3.0. Alongside these removals, there are several improvements to the Rack SPEC, mainly focused on enhancing input and output handling. These changes aim to make Rack more efficient and align better with the requirements of server implementations and relevant HTTP specifications.

### SPEC Changes

- `rack.input` is now optional. ([#1997](https://github.com/rack/rack/pull/1997), [#2018](https://github.com/rack/rack/pull/2018), [@ioquatix])
- `PATH_INFO` is now validated according to the HTTP/1.1 specification. ([#2117](https://github.com/rack/rack/pull/2117), [#2181](https://github.com/rack/rack/pull/2181), [@ioquatix])
  - `OPTIONS *` is now accepted. ([#2114](https://github.com/rack/rack/pull/2114), [@doriantaylor](https://github.com/doriantaylor))
- Introduce optional `rack.protocol` request and response header for handling connection upgrades. ([#1954](https://github.com/rack/rack/pull/1954), [@ioquatix])

### Added

- Introduce `Rack::Multipart::MissingInputError` for improved handling of missing input in `#parse_multipart`. ([#2018](https://github.com/rack/rack/pull/2018), [@ioquatix])
- Introduce `module Rack::BadRequest` which is included in multipart and query parser errors. ([#2019](https://github.com/rack/rack/pull/2019), [@ioquatix])
- Add `.mjs` MIME type ([#2057](https://github.com/rack/rack/pull/2057), [@axilleas](https://github.com/axilleas))
- `set_cookie_header` utility now supports the `partitioned` cookie attribute. This is required by Chrome in some embedded contexts. ([#2131](https://github.com/rack/rack/pull/2131), [@flavio-b](https://github.com/flavio-b))
- Introduce `rack.early_hints` for sending `103 Early Hints` informational responses. ([#1831](https://github.com/rack/rack/pull/1831), [@casperisfine](https://github.com/casperisfine), [@jeremyevans])

### Changed

- MIME type for JavaScript files (`.js`) changed from `application/javascript` to `text/javascript` ([`1bd0f15`](https://github.com/rack/rack/commit/1bd0f1597d8f4a90d47115f3e156a8ce7870c9c8), [@ioquatix])
- Update MIME types associated to `.ttf`, `.woff`, `.woff2` and `.otf` extensions to use mondern `font/*` types. ([#2065](https://github.com/rack/rack/pull/2065), [@davidstosik])
- `Rack::Utils.escape_html` is now delegated to `CGI.escapeHTML`. `'` is escaped to `#39;` instead of `#x27;`. (decimal vs hexadecimal) ([#2099](https://github.com/rack/rack/pull/2099), [@JunichiIto](https://github.com/JunichiIto))
- Clarify use of `@buffered` and only update `content-length` when `Rack::Response#finish` is invoked. ([#2149](https://github.com/rack/rack/pull/2149), [@ioquatix])

### Deprecated

- Deprecate automatic cache invalidation in `Request#{GET,POST}` ([#2073](https://github.com/rack/rack/pull/2073), [@jeremyevans])
- Only cookie keys that are not valid according to the HTTP specifications are escaped. We are planning to deprecate this behaviour, so now a deprecation message will be emitted in this case. In the future, invalid cookie keys may not be accepted. ([#2191](https://github.com/rack/rack/pull/2191), [@ioquatix])
- `Rack::Logger` is deprecated. ([#2197](https://github.com/rack/rack/pull/2197), [@ioquatix])
- Add fallback lookup and deprecation warning for obsolete status symbols. ([#2137](https://github.com/rack/rack/pull/2137), [@wtn](https://github.com/wtn))
- Deprecate `Rack::Request#values_at`, use `request.params.values_at` instead ([#2183](https://github.com/rack/rack/pull/2183), [@ioquatix])

### Removed

- Remove deprecated `Rack::Auth::Digest` with no replacement. ([#1966](https://github.com/rack/rack/pull/1966), [@ioquatix])
- Remove deprecated `Rack::Cascade::NotFound` with no replacement. ([#1966](https://github.com/rack/rack/pull/1966), [@ioquatix])
- Remove deprecated `Rack::Chunked` with no replacement. ([#1966](https://github.com/rack/rack/pull/1966), [@ioquatix])
- Remove deprecated `Rack::File`, use `Rack::Files` instead. ([#1966](https://github.com/rack/rack/pull/1966), [@ioquatix])
- Remove deprecated `Rack::QueryParser` `key_space_limit` parameter with no replacement. ([#1966](https://github.com/rack/rack/pull/1966), [@ioquatix])
- Remove deprecated `Rack::Response#header`, use `Rack::Response#headers` instead. ([#1966](https://github.com/rack/rack/pull/1966), [@ioquatix])
- Remove deprecated cookie methods from `Rack::Utils`: `add_cookie_to_header`, `make_delete_cookie_header`, `add_remove_cookie_to_header`. ([#1966](https://github.com/rack/rack/pull/1966), [@ioquatix])
- Remove deprecated `Rack::Utils::HeaderHash`. ([#1966](https://github.com/rack/rack/pull/1966), [@ioquatix])
- Remove deprecated `Rack::VERSION`, `Rack::VERSION_STRING`, `Rack.version`, use `Rack.release` instead. ([#1966](https://github.com/rack/rack/pull/1966), [@ioquatix])
- Remove non-standard status codes 306, 509, & 510 and update descriptions for 413, 422, & 451. ([#2137](https://github.com/rack/rack/pull/2137), [@wtn](https://github.com/wtn))
- Remove any dependency on `transfer-encoding: chunked`. ([#2195](https://github.com/rack/rack/pull/2195), [@ioquatix])
- Remove deprecated `Rack::Request#[]`, use `request.params[key]` instead ([#2183](https://github.com/rack/rack/pull/2183), [@ioquatix])

### Fixed

- In `Rack::Files`, ignore the `Range` header if served file is 0 bytes. ([#2159](https://github.com/rack/rack/pull/2159), [@zarqman])

## [3.0.18] - 2025-05-22

- Fix incorrect backport of optional `CGI::Cookie` support. ([#2335](https://github.com/rack/rack/pull/2335), [@jeremyevans])

## [3.0.17] - 2025-05-18

- Optional support for `CGI::Cookie` if not available. ([#2327](https://github.com/rack/rack/pull/2327), [#2333](https://github.com/rack/rack/pull/2333), [@earlopain])

## [3.0.16] - 2025-05-06

:warning: **This release includes a security fix that may cause certain routes in previously working applications to fail if query parameters exceed 4,096 in count or 4 MB in total size. See <https://github.com/rack/rack/discussions/2356> for more details.**

### Security

- [CVE-2025-46727](https://github.com/advisories/GHSA-gjh7-p2fx-99vx) Unbounded parameter parsing in `Rack::QueryParser` can lead to memory exhaustion.

## [3.0.15] - 2025-04-13

- Ensure `Rack::ETag` correctly updates response body. ([#2324](https://github.com/rack/rack/pull/2324), [@ioquatix])

## [3.0.14] - 2025-03-11

### Security

- [CVE-2025-27610](https://github.com/advisories/GHSA-7wqh-767x-r66v) Local file inclusion in `Rack::Static`.

## [3.0.13] - 2025-03-04

### Security

- [CVE-2025-27111](https://github.com/advisories/GHSA-8cgq-6mh2-7j6v) Possible Log Injection in `Rack::Sendfile`.

### Fixed

- Remove autoloads for constants no longer shipped with Rack. ([#2269](https://github.com/rack/rack/pull/2269), [@ccutrer](https://github.com/ccutrer))

## [3.0.12] - 2025-02-12

### Security

- [CVE-2025-25184](https://github.com/advisories/GHSA-7g2v-jj9q-g3rg) Possible Log Injection in `Rack::CommonLogger`.

## [3.0.11] - 2024-05-10

- Backport #2062 to 3-0-stable: Do not allow `BodyProxy` to respond to `to_str`, make `to_ary` call close . ([#2062](https://github.com/rack/rack/pull/2062), [@jeremyevans](https://github.com/jeremyevans))

## [3.0.10] - 2024-03-21

- Backport #2104 to 3-0-stable: Return empty when parsing a multi-part POST with only one end delimiter. ([#2164](https://github.com/rack/rack/pull/2164), [@JoeDupuis](https://github.com/JoeDupuis))

## [3.0.9.1] - 2024-02-21

### Security

* [CVE-2024-26146] Fixed ReDoS in Accept header parsing
* [CVE-2024-25126] Fixed ReDoS in Content Type header parsing
* [CVE-2024-26141] Reject Range headers which are too large

[CVE-2024-26146]: https://github.com/advisories/GHSA-54rr-7fvw-6x8f
[CVE-2024-25126]: https://github.com/advisories/GHSA-22f2-v57c-j9cx
[CVE-2024-26141]: https://github.com/advisories/GHSA-xj5v-6v4g-jfw6

## [3.0.9] - 2024-01-31

- Fix incorrect content-length header that was emitted when `Rack::Response#write` was used in some situations. ([#2150](https://github.com/rack/rack/pull/2150), [@mattbrictson](https://github.com/mattbrictson))

## [3.0.8] - 2023-06-14

- Fix some unused variable verbose warnings. ([#2084](https://github.com/rack/rack/pull/2084), [@jeremyevans], [@skipkayhil](https://github.com/skipkayhil))

## [3.0.7] - 2023-03-16

- Make query parameters without `=` have `nil` values. ([#2059](https://github.com/rack/rack/pull/2059), [@jeremyevans])

## [3.0.6.1] - 2023-03-13

### Security

- [CVE-2023-27539] Avoid ReDoS in header parsing

## [3.0.6] - 2023-03-13

- Add `QueryParser#missing_value` for handling missing values + tests. ([#2052](https://github.com/rack/rack/pull/2052), [@ioquatix])

## [3.0.5] - 2023-03-13

- Split form/query parsing into two steps. ([#2038](https://github.com/rack/rack/pull/2038), [@matthewd](https://github.com/matthewd))

## [3.0.4.2] - 2023-03-02

### Security

- [CVE-2023-27530] Introduce multipart_total_part_limit to limit total parts

## [3.0.4.1] - 2023-01-17

### Security

- [CVE-2022-44571] Fix ReDoS vulnerability in multipart parser
- [CVE-2022-44570] Fix ReDoS in Rack::Utils.get_byte_ranges
- [CVE-2022-44572] Forbid control characters in attributes (also ReDoS)

## [3.0.4] - 2023-01-17

- `Rack::Request#POST` should consistently raise errors. Cache errors that occur when invoking `Rack::Request#POST` so they can be raised again later. ([#2010](https://github.com/rack/rack/pull/2010), [@ioquatix])
- Fix `Rack::Lint` error message for `HTTP_CONTENT_TYPE` and `HTTP_CONTENT_LENGTH`. ([#2007](https://github.com/rack/rack/pull/2007), [@byroot](https://github.com/byroot))
- Extend `Rack::MethodOverride` to handle `QueryParser::ParamsTooDeepError` error. ([#2006](https://github.com/rack/rack/pull/2006), [@byroot](https://github.com/byroot))

## [3.0.3] - 2022-12-27

### Fixed

- `Rack::URLMap` uses non-deprecated form of `Regexp.new`. ([#1998](https://github.com/rack/rack/pull/1998), [@weizheheng](https://github.com/weizheheng))

## [3.0.2] - 2022-12-05

### Fixed

- `Utils.build_nested_query` URL-encodes nested field names including the square brackets.
- Allow `Rack::Response` to pass through streaming bodies. ([#1993](https://github.com/rack/rack/pull/1993), [@ioquatix])

## [3.0.1] - 2022-11-18

### Fixed

- `MethodOverride` does not look for an override if a request does not include form/parseable data.
- `Rack::Lint::Wrapper` correctly handles `respond_to?` with `to_ary`, `each`, `call` and `to_path`, forwarding to the body. ([#1981](https://github.com/rack/rack/pull/1981), [@ioquatix])

## [3.0.0] - 2022-09-06

This release introduces major improvements to Rack, including enhanced support for streaming responses, expanded protocol handling, and stricter compliance with HTTP standards. It refines middleware interfaces, improves multipart and hijack handling, and strengthens security and error reporting. The update also brings performance optimizations, better compatibility with modern Ruby versions, and numerous bug fixes, making Rack more robust and flexible for web application development.

- No changes

## [3.0.0.rc1] - 2022-09-04

### SPEC Changes

- Stream argument must implement `<<` https://github.com/rack/rack/pull/1959
- `close` may be called on `rack.input` https://github.com/rack/rack/pull/1956
- `rack.response_finished` may be used for executing code after the response has been finished https://github.com/rack/rack/pull/1952

## [3.0.0.beta1] - 2022-08-08

### Security

- Do not use semicolon as GET parameter separator. ([#1733](https://github.com/rack/rack/pull/1733), [@jeremyevans])

### SPEC Changes

- Response array must now be non-frozen.
- Response `status` must now be an integer greater than or equal to 100.
- Response `headers` must now be an unfrozen hash.
- Response header keys can no longer include uppercase characters.
- Response header values can be an `Array` to handle multiple values (and no longer supports `\n` encoded headers).
- Response body can now respond to `#call` (streaming body) instead of `#each` (enumerable body), for the equivalent of response hijacking in previous versions.
- Middleware must no longer call `#each` on the body, but they can call `#to_ary` on the body if it responds to `#to_ary`.
- `rack.input` is no longer required to be rewindable.
- `rack.multithread`/`rack.multiprocess`/`rack.run_once`/`rack.version` are no longer required environment keys.
- `SERVER_PROTOCOL` is now a required environment key, matching the HTTP protocol used in the request.
- `rack.hijack?` (partial hijack) and `rack.hijack` (full hijack) are now independently optional.
- `rack.hijack_io` has been removed completely.
- `rack.response_finished` is an optional environment key which contains an array of callable objects that must accept `#call(env, status, headers, error)` and are invoked after the response is finished (either successfully or unsuccessfully).
- It is okay to call `#close` on `rack.input` to indicate that you no longer need or care about the input.
- The stream argument supplied to the streaming body and hijack must support `#<<` for writing output.

### Removed

- Remove `rack.multithread`/`rack.multiprocess`/`rack.run_once`. These variables generally come too late to be useful. ([#1720](https://github.com/rack/rack/pull/1720), [@ioquatix], [@jeremyevans]))
- Remove deprecated Rack::Request::SCHEME_WHITELIST. ([@jeremyevans])
- Remove internal cookie deletion using pattern matching, there are very few practical cases where it would be useful and browsers handle it correctly without us doing anything special. ([#1844](https://github.com/rack/rack/pull/1844), [@ioquatix])
- Remove `rack.version` as it comes too late to be useful. ([#1938](https://github.com/rack/rack/pull/1938), [@ioquatix])
- Extract `rackup` command, `Rack::Server`, `Rack::Handler` and related code into a separate gem. ([#1937](https://github.com/rack/rack/pull/1937), [@ioquatix])

### Added

- `Rack::Headers` added to support lower-case header keys. ([@jeremyevans])
- `Rack::Utils#set_cookie_header` now supports `escape_key: false` to avoid key escaping.  ([@jeremyevans])
- `Rack::RewindableInput` supports size. ([@ahorek](https://github.com/ahorek))
- `Rack::RewindableInput::Middleware` added for making `rack.input` rewindable. ([@jeremyevans])
- The RFC 7239 Forwarded header is now supported and considered by default when looking for information on forwarding, falling back to the X-Forwarded-* headers. `Rack::Request.forwarded_priority` accessor has been added for configuring the priority of which header to check.  ([#1423](https://github.com/rack/rack/issues/1423), [@jeremyevans])
- Allow response headers to contain array of values. ([#1598](https://github.com/rack/rack/issues/1598), [@ioquatix])
- Support callable body for explicit streaming support and clarify streaming response body behaviour. ([#1745](https://github.com/rack/rack/pull/1745), [@ioquatix], [#1748](https://github.com/rack/rack/pull/1748), [@wjordan])
- Allow `Rack::Builder#run` to take a block instead of an argument. ([#1942](https://github.com/rack/rack/pull/1942), [@ioquatix])
- Add `rack.response_finished` to `Rack::Lint`. ([#1802](https://github.com/rack/rack/pull/1802), [@BlakeWilliams], [#1952](https://github.com/rack/rack/pull/1952), [@ioquatix])
- The stream argument must implement `#<<`. ([#1959](https://github.com/rack/rack/pull/1959), [@ioquatix])

### Changed

- BREAKING CHANGE: Require `status` to be an Integer. ([#1662](https://github.com/rack/rack/pull/1662), [@olleolleolle](https://github.com/olleolleolle))
- BREAKING CHANGE: Query parsing now treats parameters without `=` as having the empty string value instead of nil value, to conform to the URL spec. ([#1696](https://github.com/rack/rack/issues/1696), [@jeremyevans])
- Relax validations around `Rack::Request#host` and `Rack::Request#hostname`. ([#1606](https://github.com/rack/rack/issues/1606), [@pvande](https://github.com/pvande))
- Removed antiquated handlers: FCGI, LSWS, SCGI, Thin. ([#1658](https://github.com/rack/rack/pull/1658), [@ioquatix])
- Removed options from `Rack::Builder.parse_file` and `Rack::Builder.load_file`. ([#1663](https://github.com/rack/rack/pull/1663), [@ioquatix])
- `Rack::HTTP_VERSION` has been removed and the `HTTP_VERSION` env setting is no longer set in the CGI and Webrick handlers. ([#970](https://github.com/rack/rack/issues/970), [@jeremyevans])
- `Rack::Request#[]` and `#[]=` now warn even in non-verbose mode. ([#1277](https://github.com/rack/rack/issues/1277), [@jeremyevans])
- Decrease default allowed parameter recursion level from 100 to 32. ([#1640](https://github.com/rack/rack/issues/1640), [@jeremyevans])
- Attempting to parse a multipart response with an empty body now raises Rack::Multipart::EmptyContentError. ([#1603](https://github.com/rack/rack/issues/1603), [@jeremyevans])
- `Rack::Utils.secure_compare` uses OpenSSL's faster implementation if available. ([#1711](https://github.com/rack/rack/pull/1711), [@bdewater](https://github.com/bdewater))
- `Rack::Request#POST` now caches an empty hash if input content type is not parseable. ([#749](https://github.com/rack/rack/pull/749), [@jeremyevans])
- BREAKING CHANGE: Updated `trusted_proxy?` to match full 127.0.0.0/8 network. ([#1781](https://github.com/rack/rack/pull/1781), [@snbloch](https://github.com/snbloch))
- Explicitly deprecate `Rack::File` which was an alias for `Rack::Files`. ([#1811](https://github.com/rack/rack/pull/1720), [@ioquatix]).
- Moved `Rack::Session` into [separate gem](https://github.com/rack/rack-session). ([#1805](https://github.com/rack/rack/pull/1805), [@ioquatix])
- `rackup -D` option to daemonizes no longer changes the working directory to the root. ([#1813](https://github.com/rack/rack/pull/1813), [@jeremyevans])
- The `x-forwarded-proto` header is now considered before the `x-forwarded-scheme` header for determining the forwarded protocol. `Rack::Request.x_forwarded_proto_priority` accessor has been added for configuring the priority of which header to check.  ([#1809](https://github.com/rack/rack/issues/1809), [@jeremyevans])
- `Rack::Request.forwarded_authority` (and methods that call it, such as `host`) now returns the last authority in the forwarded header, instead of the first, as earlier forwarded authorities can be forged by clients. This restores the Rack 2.1 behavior. ([#1829](https://github.com/rack/rack/issues/1809), [@jeremyevans])
- Use lower case cookie attributes when creating cookies, and fold cookie attributes to lower case when reading cookies (specifically impacting `secure` and `httponly` attributes). ([#1849](https://github.com/rack/rack/pull/1849), [@ioquatix])
- The response array must now be mutable (non-frozen) so middleware can modify it without allocating a new Array,therefore reducing object allocations. ([#1887](https://github.com/rack/rack/pull/1887), [#1927](https://github.com/rack/rack/pull/1927), [@amatsuda], [@ioquatix])
- `rack.hijack?` (partial hijack) and `rack.hijack` (full hijack) are now independently optional. `rack.hijack_io` is no longer required/specified. ([#1939](https://github.com/rack/rack/pull/1939), [@ioquatix])
- Allow calling close on `rack.input`. ([#1956](https://github.com/rack/rack/pull/1956), [@ioquatix])

### Fixed

- Make Rack::MockResponse handle non-hash headers. ([#1629](https://github.com/rack/rack/issues/1629), [@jeremyevans])
- TempfileReaper now deletes temp files if application raises an exception. ([#1679](https://github.com/rack/rack/issues/1679), [@jeremyevans])
- Handle cookies with values that end in '=' ([#1645](https://github.com/rack/rack/pull/1645), [@lukaso](https://github.com/lukaso))
- Make `Rack::NullLogger` respond to `#fatal!` [@jeremyevans])
- Fix multipart filename generation for filenames that contain spaces. Encode spaces as "%20" instead of "+" which will be decoded properly by the multipart parser. ([#1736](https://github.com/rack/rack/pull/1645), [@muirdm](https://github.com/muirdm))
- `Rack::Request#scheme` returns `ws` or `wss` when one of the `X-Forwarded-Scheme` / `X-Forwarded-Proto` headers is set to `ws` or `wss`, respectively. ([#1730](https://github.com/rack/rack/issues/1730), [@erwanst](https://github.com/erwanst))

## [2.2.21] - 2025-11-03

### Fixed

- Multipart parser: limit MIME header size check to the unread buffer region to avoid false `multipart mime part header too large` errors when previously read data accumulates in the scan buffer. ([#2392](https://github.com/rack/rack/pull/2392), [@alpaca-tc](https://github.com/alpaca-tc), [@willnet](https://github.com/willnet), [@krororo](https://github.com/krororo))

## [2.2.20] - 2025-10-10

### Security

- [CVE-2025-61780](https://github.com/advisories/GHSA-r657-rxjc-j557) Improper handling of headers in `Rack::Sendfile` may allow proxy bypass.
- [CVE-2025-61919](https://github.com/advisories/GHSA-6xw4-3v39-52mm) Unbounded read in `Rack::Request` form parsing can lead to memory exhaustion.

## [2.2.19] - 2025-10-07

### Security

- [CVE-2025-61772](https://github.com/advisories/GHSA-wpv5-97wm-hp9c) Multipart parser buffers unbounded per-part headers, enabling DoS (memory exhaustion)
- [CVE-2025-61771](https://github.com/advisories/GHSA-w9pc-fmgc-vxvw) Multipart parser buffers large non‑file fields entirely in memory, enabling DoS (memory exhaustion)
- [CVE-2025-61770](https://github.com/advisories/GHSA-p543-xpfm-54cp) Unbounded multipart preamble buffering enables DoS (memory exhaustion)

## [2.2.18] - 2025-09-25

### Security

- [CVE-2025-59830](https://github.com/advisories/GHSA-625h-95r8-8xpm) Unbounded parameter parsing in `Rack::QueryParser` can lead to memory exhaustion via semicolon-separated parameters.

## [2.2.17] - 2025-06-03

- Backport `Rack::MediaType#params` now handles parameters without values. ([#2263](https://github.com/rack/rack/pull/2263), [@AllyMarthaJ](https://github.com/AllyMarthaJ))

## [2.2.16] - 2025-05-22

- Fix incorrect backport of optional `CGI::Cookie` support. ([#2335](https://github.com/rack/rack/pull/2335), [@jeremyevans])

## [2.2.15] - 2025-05-18

- Optional support for `CGI::Cookie` if not available. ([#2327](https://github.com/rack/rack/pull/2327), [#2333](https://github.com/rack/rack/pull/2333), [@earlopain])

## [2.2.14] - 2025-05-06

:warning: **This release includes a security fix that may cause certain routes in previously working applications to fail if query parameters exceed 4,096 in count or 4 MB in total size. See <https://github.com/rack/rack/discussions/2356> for more details.**

### Security

- [CVE-2025-46727](https://github.com/advisories/GHSA-gjh7-p2fx-99vx) Unbounded parameter parsing in `Rack::QueryParser` can lead to memory exhaustion.

## [2.2.13] - 2025-03-11

### Security

- [CVE-2025-27610](https://github.com/advisories/GHSA-7wqh-767x-r66v) Local file inclusion in `Rack::Static`.

## [2.2.12] - 2025-03-04

### Security

- [CVE-2025-27111](https://github.com/advisories/GHSA-8cgq-6mh2-7j6v) Possible Log Injection in `Rack::Sendfile`.

## [2.2.11] - 2025-02-12

### Security

- [CVE-2025-25184](https://github.com/advisories/GHSA-7g2v-jj9q-g3rg) Possible Log Injection in `Rack::CommonLogger`.

## [2.2.10] - 2024-10-14

- Fix compatibility issues with Ruby v3.4.0. ([#2248](https://github.com/rack/rack/pull/2248), [@byroot](https://github.com/byroot))

## [2.2.9] - 2023-03-21

- Return empty when parsing a multi-part POST with only one end delimiter. ([#2104](https://github.com/rack/rack/pull/2104), [@alpaca-tc])

## [2.2.8] - 2023-07-31

- Regenerate SPEC ([#2102](https://github.com/rack/rack/pull/2102), [@skipkayhil](https://github.com/skipkayhil))
- Limit file extension length of multipart tempfiles ([#2015](https://github.com/rack/rack/pull/2015), [@dentarg](https://github.com/dentarg))
- Fix "undefined method DelegateClass for Rack::Session::Cookie:Class" ([#2092](https://github.com/rack/rack/pull/2092), [@onigra](https://github.com/onigra) [@dchandekstark](https://github.com/dchandekstark))

## [2.2.7] - 2023-03-13

- Correct the year number in the changelog ([#2015](https://github.com/rack/rack/pull/2015), [@kimulab](https://github.com/kimulab))
- Support underscore in host names for Rack 2.2 (Fixes [#2070](https://github.com/rack/rack/issues/2070)) ([#2015](https://github.com/rack/rack/pull/2071), [@jeremyevans](https://github.com/jeremyevans))

## [2.2.6.4] - 2023-03-13

- [CVE-2023-27539] Avoid ReDoS in header parsing

## [2.2.6.3] - 2023-03-02

- [CVE-2023-27530] Introduce multipart_total_part_limit to limit total parts

## [2.2.6.2] - 2023-01-17

- [CVE-2022-44570] Fix ReDoS in Rack::Utils.get_byte_ranges

## [2.2.6.1] - 2023-01-17

- [CVE-2022-44571] Fix ReDoS vulnerability in multipart parser
- [CVE-2022-44572] Forbid control characters in attributes (also ReDoS)

## [2.2.6] - 2023-01-17

- Extend `Rack::MethodOverride` to handle `QueryParser::ParamsTooDeepError` error. ([#2011](https://github.com/rack/rack/pull/2011), [@byroot](https://github.com/byroot))

## [2.2.5] - 2022-12-27

### Fixed

- `Rack::URLMap` uses non-deprecated form of `Regexp.new`. ([#1998](https://github.com/rack/rack/pull/1998), [@weizheheng](https://github.com/weizheheng))

## [2.2.4] - 2022-06-30

- Better support for lower case headers in `Rack::ETag` middleware. ([#1919](https://github.com/rack/rack/pull/1919), [@ioquatix](https://github.com/ioquatix))
- Use custom exception on params too deep error. ([#1838](https://github.com/rack/rack/pull/1838), [@simi](https://github.com/simi))

## [2.2.3.1] - 2022-05-27

### Security

- [CVE-2022-30123] Fix shell escaping issue in Common Logger
- [CVE-2022-30122] Restrict parsing of broken MIME attachments

## [2.2.3] - 2020-06-15

### Security

- [[CVE-2020-8184](https://nvd.nist.gov/vuln/detail/CVE-2020-8184)] Do not allow percent-encoded cookie name to override existing cookie names. BREAKING CHANGE: Accessing cookie names that require URL encoding with decoded name no longer works. ([@fletchto99](https://github.com/fletchto99))

## [2.2.2] - 2020-02-11

### Fixed

- Fix incorrect `Rack::Request#host` value. ([#1591](https://github.com/rack/rack/pull/1591), [@ioquatix])
- Revert `Rack::Handler::Thin` implementation. ([#1583](https://github.com/rack/rack/pull/1583), [@jeremyevans])
- Double assignment is still needed to prevent an "unused variable" warning. ([#1589](https://github.com/rack/rack/pull/1589), [@kamipo](https://github.com/kamipo))
- Fix to handle same_site option for session pool. ([#1587](https://github.com/rack/rack/pull/1587), [@kamipo](https://github.com/kamipo))

## [2.2.1] - 2020-02-09

### Fixed

- Rework `Rack::Request#ip` to handle empty `forwarded_for`. ([#1577](https://github.com/rack/rack/pull/1577), [@ioquatix])

## [2.2.0] - 2020-02-08

### SPEC Changes

- `rack.session` request environment entry must respond to `to_hash` and return unfrozen Hash. ([@jeremyevans])
- Request environment cannot be frozen. ([@jeremyevans])
- CGI values in the request environment with non-ASCII characters must use ASCII-8BIT encoding. ([@jeremyevans])
- Improve SPEC/lint relating to SERVER_NAME, SERVER_PORT and HTTP_HOST. ([#1561](https://github.com/rack/rack/pull/1561), [@ioquatix])

### Added

- `rackup` supports multiple `-r` options and will require all arguments. ([@jeremyevans])
- `Server` supports an array of paths to require for the `:require` option. ([@khotta](https://github.com/khotta))
- `Files` supports multipart range requests. ([@fatkodima](https://github.com/fatkodima))
- `Multipart::UploadedFile` supports an IO-like object instead of using the filesystem, using `:filename` and `:io` options. ([@jeremyevans])
- `Multipart::UploadedFile` supports keyword arguments `:path`, `:content_type`, and `:binary` in addition to positional arguments. ([@jeremyevans])
- `Static` supports a `:cascade` option for calling the app if there is no matching file. ([@jeremyevans])
- `Session::Abstract::SessionHash#dig`. ([@jeremyevans])
- `Response.[]` and `MockResponse.[]` for creating instances using status, headers, and body. ([@ioquatix])
- Convenient cache and content type methods for `Rack::Response`. ([#1555](https://github.com/rack/rack/pull/1555), [@ioquatix])

### Changed

- `Request#params` no longer rescues EOFError. ([@jeremyevans])
- `Directory` uses a streaming approach, significantly improving time to first byte for large directories. ([@jeremyevans])
- `Directory` no longer includes a Parent directory link in the root directory index. ([@jeremyevans])
- `QueryParser#parse_nested_query` uses original backtrace when reraising exception with new class. ([@jeremyevans])
- `ConditionalGet` follows RFC 7232 precedence if both If-None-Match and If-Modified-Since headers are provided. ([@jeremyevans])
- `.ru` files supports the `frozen-string-literal` magic comment. ([@eregon](https://github.com/eregon))
- Rely on autoload to load constants instead of requiring internal files, make sure to require 'rack' and not just 'rack/...'. ([@jeremyevans])
- BREAKING CHANGE: `Etag` will continue sending ETag even if the response should not be cached. Streaming no longer works without a workaround, see [#1619](https://github.com/rack/rack/issues/1619#issuecomment-848460528). ([@henm](https://github.com/henm))
- `Request#host_with_port` no longer includes a colon for a missing or empty port. ([@AlexWayfer](https://github.com/AlexWayfer))
- All handlers uses keywords arguments instead of an options hash argument. ([@ioquatix])
- `Files` handling of range requests no longer return a body that supports `to_path`, to ensure range requests are handled correctly. ([@jeremyevans])
- `Multipart::Generator` only includes `Content-Length` for files with paths, and `Content-Disposition` `filename` if the `UploadedFile` instance has one. ([@jeremyevans])
- `Request#ssl?` is true for the `wss` scheme (secure websockets). ([@jeremyevans])
- `Rack::HeaderHash` is memoized by default. ([#1549](https://github.com/rack/rack/pull/1549), [@ioquatix])
- `Rack::Directory` allow directory traversal inside root directory. ([#1417](https://github.com/rack/rack/pull/1417), [@ThomasSevestre](https://github.com/ThomasSevestre))
- Sort encodings by server preference. ([#1184](https://github.com/rack/rack/pull/1184), [@ioquatix], [@wjordan](https://github.com/wjordan))
- Rework host/hostname/authority implementation in `Rack::Request`. `#host` and `#host_with_port` have been changed to correctly return IPv6 addresses formatted with square brackets, as defined by [RFC3986](https://tools.ietf.org/html/rfc3986#section-3.2.2). ([#1561](https://github.com/rack/rack/pull/1561), [@ioquatix])
- `Rack::Builder` parsing options on first `#\` line is deprecated. ([#1574](https://github.com/rack/rack/pull/1574), [@ioquatix])

### Removed

- `Directory#path` as it was not used and always returned nil. ([@jeremyevans])
- `BodyProxy#each` as it was only needed to work around a bug in Ruby <1.9.3. ([@jeremyevans])
- `URLMap::INFINITY` and `URLMap::NEGATIVE_INFINITY`, in favor of `Float::INFINITY`. ([@ch1c0t](https://github.com/ch1c0t))
- Deprecation of `Rack::File`. It will be deprecated again in rack 2.2 or 3.0. ([@rafaelfranca](https://github.com/rafaelfranca))
- Support for Ruby 2.2 as it is well past EOL. ([@ioquatix])
- Remove `Rack::Files#response_body` as the implementation was broken. ([#1153](https://github.com/rack/rack/pull/1153), [@ioquatix])
- Remove `SERVER_ADDR` which was never part of the original SPEC. ([#1573](https://github.com/rack/rack/pull/1573), [@ioquatix])

### Fixed

- `Directory` correctly handles root paths containing glob metacharacters. ([@jeremyevans])
- `Cascade` uses a new response object for each call if initialized with no apps. ([@jeremyevans])
- `BodyProxy` correctly delegates keyword arguments to the body object on Ruby 2.7+. ([@jeremyevans])
- `BodyProxy#method` correctly handles methods delegated to the body object. ([@jeremyevans])
- `Request#host` and `Request#host_with_port` handle IPv6 addresses correctly. ([@AlexWayfer](https://github.com/AlexWayfer))
- `Lint` checks when response hijacking that `rack.hijack` is called with a valid object. ([@jeremyevans])
- `Response#write` correctly updates `Content-Length` if initialized with a body. ([@jeremyevans])
- `CommonLogger` includes `SCRIPT_NAME` when logging. ([@Erol](https://github.com/Erol))
- `Utils.parse_nested_query` correctly handles empty queries, using an empty instance of the params class instead of a hash. ([@jeremyevans])
- `Directory` correctly escapes paths in links. ([@yous](https://github.com/yous))
- `Request#delete_cookie` and related `Utils` methods handle `:domain` and `:path` options in same call. ([@jeremyevans])
- `Request#delete_cookie` and related `Utils` methods do an exact match on `:domain` and `:path` options. ([@jeremyevans])
- `Static` no longer adds headers when a gzipped file request has a 304 response. ([@chooh](https://github.com/chooh))
- `ContentLength` sets `Content-Length` response header even for bodies not responding to `to_ary`. ([@jeremyevans])
- Thin handler supports options passed directly to `Thin::Controllers::Controller`. ([@jeremyevans])
- WEBrick handler no longer ignores `:BindAddress` option. ([@jeremyevans])
- `ShowExceptions` handles invalid POST data. ([@jeremyevans])
- Basic authentication requires a password, even if the password is empty. ([@jeremyevans])
- `Lint` checks response is array with 3 elements, per SPEC. ([@jeremyevans])
- Support for using `:SSLEnable` option when using WEBrick handler. (Gregor Melhorn)
- Close response body after buffering it when buffering. ([@ioquatix])
- Only accept `;` as delimiter when parsing cookies. ([@mrageh](https://github.com/mrageh))
- `Utils::HeaderHash#clear` clears the name mapping as well. ([@raxoft](https://github.com/raxoft))
- Support for passing `nil` `Rack::Files.new`, which notably fixes Rails' current `ActiveStorage::FileServer` implementation. ([@ioquatix])

### Documentation

- CHANGELOG updates. ([@aupajo](https://github.com/aupajo))
- Added [CONTRIBUTING](CONTRIBUTING.md). ([@dblock](https://github.com/dblock))

## [2.0.9] - 2020-02-08

- Handle case where session id key is requested but missing ([@jeremyevans])
- Restore support for code relying on `SessionId#to_s`. ([@jeremyevans])
- Add support for `SameSite=None` cookie value. ([@hennikul](https://github.com/hennikul))

## [2.1.2] - 2020-01-27

- Fix multipart parser for some files to prevent denial of service ([@aiomaster](https://github.com/aiomaster))
- Fix `Rack::Builder#use` with keyword arguments ([@kamipo](https://github.com/kamipo))
- Skip deflating in Rack::Deflater if Content-Length is 0 ([@jeremyevans])
- Remove `SessionHash#transform_keys`, no longer needed ([@pavel](https://github.com/pavel))
- Add to_hash to wrap Hash and Session classes ([@oleh-demyanyuk](https://github.com/oleh-demyanyuk))
- Handle case where session id key is requested but missing ([@jeremyevans])

## [2.1.1] - 2020-01-12

- Remove `Rack::Chunked` from `Rack::Server` default middleware. ([#1475](https://github.com/rack/rack/pull/1475), [@ioquatix])
- Restore support for code relying on `SessionId#to_s`. ([@jeremyevans])

## [2.1.0] - 2020-01-10

### Added

- Add support for `SameSite=None` cookie value. ([@hennikul](https://github.com/hennikul))
- Add trailer headers. ([@eileencodes](https://github.com/eileencodes))
- Add MIME Types for video streaming. ([@styd](https://github.com/styd))
- Add MIME Type for WASM. ([@buildrtech](https://github.com/buildrtech))
- Add `Early Hints(103)` to status codes. ([@egtra](https://github.com/egtra))
- Add `Too Early(425)` to status codes. ([@y-yagi]((https://github.com/y-yagi)))
- Add `Bandwidth Limit Exceeded(509)` to status codes. ([@CJKinni](https://github.com/CJKinni))
- Add method for custom `ip_filter`. ([@svcastaneda](https://github.com/svcastaneda))
- Add boot-time profiling capabilities to `rackup`. ([@tenderlove](https://github.com/tenderlove))
- Add multi mapping support for `X-Accel-Mappings` header. ([@yoshuki](https://github.com/yoshuki))
- Add `sync: false` option to `Rack::Deflater`. (Eric Wong)
- Add `Builder#freeze_app` to freeze application and all middleware instances. ([@jeremyevans])
- Add API to extract cookies from `Rack::MockResponse`. ([@petercline](https://github.com/petercline))

### Changed

- Don't propagate nil values from middleware. ([@ioquatix])
- Lazily initialize the response body and only buffer it if required. ([@ioquatix])
- Fix deflater zlib buffer errors on empty body part. ([@felixbuenemann](https://github.com/felixbuenemann))
- Set `X-Accel-Redirect` to percent-encoded path. ([@diskkid](https://github.com/diskkid))
- Remove unnecessary buffer growing when parsing multipart. ([@tainoe](https://github.com/tainoe))
- Expand the root path in `Rack::Static` upon initialization. ([@rosenfeld](https://github.com/rosenfeld))
- Make `ShowExceptions` work with binary data. ([@axyjo](https://github.com/axyjo))
- Use buffer string when parsing multipart requests. ([@janko-m](https://github.com/janko-m))
- Support optional UTF-8 Byte Order Mark (BOM) in config.ru. ([@mikegee](https://github.com/mikegee))
- Handle `X-Forwarded-For` with optional port. ([@dpritchett](https://github.com/dpritchett))
- Use `Time#httpdate` format for Expires, as proposed by RFC 7231. ([@nanaya](https://github.com/nanaya))
- Make `Utils.status_code` raise an error when the status symbol is invalid instead of `500`. ([@adambutler](https://github.com/adambutler))
- Rename `Request::SCHEME_WHITELIST` to `Request::ALLOWED_SCHEMES`.
- Make `Multipart::Parser.get_filename` accept files with `+` in their name. ([@lucaskanashiro](https://github.com/lucaskanashiro))
- Add Falcon to the default handler fallbacks. ([@ioquatix])
- Update codebase to avoid string mutations in preparation for `frozen_string_literals`. ([@pat](https://github.com/pat))
- Change `MockRequest#env_for` to rely on the input optionally responding to `#size` instead of `#length`. ([@janko](https://github.com/janko))
- Rename `Rack::File` -> `Rack::Files` and add deprecation notice. ([@postmodern](https://github.com/postmodern))
- Prefer Base64 “strict encoding” for Base64 cookies. ([@ioquatix])

### Removed

- BREAKING CHANGE: Remove `to_ary` from Response ([@tenderlove](https://github.com/tenderlove))
- Deprecate `Rack::Session::Memcache` in favor of `Rack::Session::Dalli` from dalli gem ([@fatkodima](https://github.com/fatkodima))

### Fixed

- Eliminate warnings for Ruby 2.7. ([@osamtimizer](https://github.com/osamtimizer]))

### Documentation

- Update broken example in `Session::Abstract::ID` documentation. ([tonytonyjan](https://github.com/tonytonyjan))
- Add Padrino to the list of frameworks implementing Rack. ([@wikimatze](https://github.com/wikimatze))
- Remove Mongrel from the suggested server options in the help output. ([@tricknotes](https://github.com/tricknotes))
- Replace `HISTORY.md` and `NEWS.md` with `CHANGELOG.md`. ([@twitnithegirl](https://github.com/twitnithegirl))
- CHANGELOG updates. ([@drenmi](https://github.com/Drenmi), [@p8](https://github.com/p8))

## [2.0.8] - 2019-12-08

### Security

- [[CVE-2019-16782](https://nvd.nist.gov/vuln/detail/CVE-2019-16782)] Prevent timing attacks targeted at session ID lookup. BREAKING CHANGE: Session ID is now a SessionId instance instead of a String. ([@tenderlove](https://github.com/tenderlove), [@rafaelfranca](https://github.com/rafaelfranca))

## [1.6.12] - 2019-12-08

### Security

- [[CVE-2019-16782](https://nvd.nist.gov/vuln/detail/CVE-2019-16782)] Prevent timing attacks targeted at session ID lookup. BREAKING CHANGE: Session ID is now a SessionId instance instead of a String. ([@tenderlove](https://github.com/tenderlove), [@rafaelfranca](https://github.com/rafaelfranca))

## [2.0.7] - 2019-04-02

### Fixed

- Remove calls to `#eof?` on Rack input in `Multipart::Parser`, as this breaks the specification. ([@matthewd](https://github.com/matthewd))
- Preserve forwarded IP addresses for trusted proxy chains. ([@SamSaffron](https://github.com/SamSaffron))

## [2.0.6] - 2018-11-05

### Fixed

- [[CVE-2018-16470](https://nvd.nist.gov/vuln/detail/CVE-2018-16470)] Reduce buffer size of `Multipart::Parser` to avoid pathological parsing. ([@tenderlove](https://github.com/tenderlove))
- Fix a call to a non-existing method `#accepts_html` in the `ShowExceptions` middleware. ([@tomelm](https://github.com/tomelm))
- [[CVE-2018-16471](https://nvd.nist.gov/vuln/detail/CVE-2018-16471)] Whitelist HTTP and HTTPS schemes in `Request#scheme` to prevent a possible XSS attack. ([@PatrickTulskie](https://github.com/PatrickTulskie))

## [2.0.5] - 2018-04-23

### Fixed

- Record errors originating from invalid UTF8 in `MethodOverride` middleware instead of breaking. ([@mclark](https://github.com/mclark))

## [2.0.4] - 2018-01-31

### Changed

- Ensure the `Lock` middleware passes the original `env` object. ([@lugray](https://github.com/lugray))
- Improve performance of `Multipart::Parser` when uploading large files. ([@tompng](https://github.com/tompng))
- Increase buffer size in `Multipart::Parser` for better performance. ([@jkowens](https://github.com/jkowens))
- Reduce memory usage of `Multipart::Parser` when uploading large files. ([@tompng](https://github.com/tompng))
- Replace ConcurrentRuby dependency with native `Queue`. ([@devmchakan](https://github.com/devmchakan))

### Fixed

- Require the correct digest algorithm in the `ETag` middleware. ([@matthewd](https://github.com/matthewd))

### Documentation

- Update homepage links to use SSL. ([@hugoabonizio](https://github.com/hugoabonizio))

## [2.0.3] - 2017-05-15

### Changed

- Ensure `env` values are ASCII 8-bit encoded. ([@eileencodes](https://github.com/eileencodes))

### Fixed

- Prevent exceptions when a class with mixins inherits from `Session::Abstract::ID`. ([@jnraine](https://github.com/jnraine))

## [2.0.2] - 2017-05-08

### Added

- Allow `Session::Abstract::SessionHash#fetch` to accept a block with a default value. ([@yannvanhalewyn](https://github.com/yannvanhalewyn))
- Add `Builder#freeze_app` to freeze application and all middleware. ([@jeremyevans])

### Changed

- Freeze default session options to avoid accidental mutation. ([@kirs](https://github.com/kirs))
- Detect partial hijack without hash headers. ([@devmchakan](https://github.com/devmchakan))
- Update tests to use MiniTest 6 matchers. ([@tonytonyjan](https://github.com/tonytonyjan))
- Allow 205 Reset Content responses to set a Content-Length, as RFC 7231 proposes setting this to 0. ([@devmchakan](https://github.com/devmchakan))

### Fixed

- Handle `NULL` bytes in multipart filenames. ([@casperisfine](https://github.com/casperisfine))
- Remove warnings due to miscapitalized global. ([@ioquatix])
- Prevent exceptions caused by a race condition on multi-threaded servers. ([@sophiedeziel](https://github.com/sophiedeziel))
- Add RDoc as an explicit dependency for `doc` group. ([@tonytonyjan](https://github.com/tonytonyjan))
- Record errors originating from `Multipart::Parser` in the `MethodOverride` middleware instead of letting them bubble up. ([@carlzulauf](https://github.com/carlzulauf))
- Remove remaining use of removed `Utils#bytesize` method from the `File` middleware. ([@brauliomartinezlm](https://github.com/brauliomartinezlm))

### Removed

- Remove `deflate` encoding support to reduce caching overhead. ([@devmchakan](https://github.com/devmchakan))

### Documentation

- Update broken example in `Deflater` documentation. ([@mwpastore](https://github.com/mwpastore))

## [2.0.1] - 2016-06-30

### Changed

- Remove JSON as an explicit dependency. ([@mperham](https://github.com/mperham))


# History/News Archive
Items below this line are from the previously maintained HISTORY.md and NEWS.md files.

## [2.0.0.rc1] 2016-05-06
- Rack::Session::Abstract::ID is deprecated. Please change to use Rack::Session::Abstract::Persisted

## [2.0.0.alpha] 2015-12-04
- First-party "SameSite" cookies. Browsers omit SameSite cookies from third-party requests, closing the door on many CSRF attacks.
- Pass `same_site: true` (or `:strict`) to enable: response.set_cookie 'foo', value: 'bar', same_site: true or `same_site: :lax` to use Lax enforcement: response.set_cookie 'foo', value: 'bar', same_site: :lax
- Based on version 7 of the Same-site Cookies internet draft:
	https://tools.ietf.org/html/draft-west-first-party-cookies-07
- Thanks to Ben Toews (@mastahyeti) and Bob Long (@bobjflong) for updating to drafts 5 and 7.
- Add `Rack::Events` middleware for adding event based middleware: middleware that does not care about the response body, but only cares about doing work at particular points in the request / response lifecycle.
- Add `Rack::Request#authority` to calculate the authority under which the response is being made (this will be handy for h2 pushes).
- Add `Rack::Response::Helpers#cache_control` and `cache_control=`. Use this for setting cache control headers on your response objects.
- Add `Rack::Response::Helpers#etag` and `etag=`.  Use this for setting etag values on the response.
- Introduce `Rack::Response::Helpers#add_header` to add a value to a multi-valued response header. Implemented in terms of other `Response#*_header` methods, so it's available to any response-like class that includes the `Helpers` module.
- Add `Rack::Request#add_header` to match.
- `Rack::Session::Abstract::ID` IS DEPRECATED.  Please switch to `Rack::Session::Abstract::Persisted`. `Rack::Session::Abstract::Persisted` uses a request object rather than the `env` hash.
- Pull `ENV` access inside the request object in to a module.  This will help with legacy Request objects that are ENV based but don't want to inherit from Rack::Request
- Move most methods on the `Rack::Request` to a module `Rack::Request::Helpers` and use public API to get values from the request object.  This enables users to mix `Rack::Request::Helpers` in to their own objects so they can implement `(get|set|fetch|each)_header` as they see fit (for example a proxy object).
- Files and directories with + in the name are served correctly. Rather than unescaping paths like a form, we unescape with a URI parser using `Rack::Utils.unescape_path`. Fixes #265
- Tempfiles are automatically closed in the case that there were too
	many posted.
- Added methods for manipulating response headers that don't assume
	they're stored as a Hash. Response-like classes may include the
	Rack::Response::Helpers module if they define these methods:
    - Rack::Response#has_header?
	- Rack::Response#get_header
	- Rack::Response#set_header
	- Rack::Response#delete_header
- Introduce Util.get_byte_ranges that will parse the value of the HTTP_RANGE string passed to it without depending on the `env` hash. `byte_ranges` is deprecated in favor of this method.
- Change Session internals to use Request objects for looking up session information. This allows us to only allocate one request object when dealing with session objects (rather than doing it every time we need to manipulate cookies, etc).
- Add `Rack::Request#initialize_copy` so that the env is duped when the request gets duped.
- Added methods for manipulating request specific data.  This includes
	data set as CGI parameters, and just any arbitrary data the user wants
	to associate with a particular request.  New methods:
	 - Rack::Request#has_header?
	 - Rack::Request#get_header
	 - Rack::Request#fetch_header
	 - Rack::Request#each_header
	 - Rack::Request#set_header
	 - Rack::Request#delete_header
- lib/rack/utils.rb: add a method for constructing "delete" cookie
	headers.  This allows us to construct cookie headers without depending
	on the side effects of mutating a hash.
- Prevent extremely deep parameters from being parsed. CVE-2015-3225

## [1.6.1] 2015-05-06
  - Fix CVE-2014-9490, denial of service attack in OkJson
  - Use a monotonic time for Rack::Runtime, if available
  - RACK_MULTIPART_LIMIT changed to RACK_MULTIPART_PART_LIMIT (RACK_MULTIPART_LIMIT is deprecated and will be removed in 1.7.0)

## [1.5.3] 2015-05-06
  - Fix CVE-2014-9490, denial of service attack in OkJson
  - Backport bug fixes to 1.5 series

## [1.6.0] 2014-01-18
  - Response#unauthorized? helper
  - Deflater now accepts an options hash to control compression on a per-request level
  - Builder#warmup method for app preloading
  - Request#accept_language method to extract HTTP_ACCEPT_LANGUAGE
  - Add quiet mode of rack server, rackup --quiet
  - Update HTTP Status Codes to RFC 7231
  - Less strict header name validation according to RFC 2616
  - SPEC updated to specify headers conform to RFC7230 specification
  - Etag correctly marks etags as weak
  - Request#port supports multiple x-http-forwarded-proto values
  - Utils#multipart_part_limit configures the maximum number of parts a request can contain
  - Default host to localhost when in development mode
  - Various bugfixes and performance improvements

## [1.5.2] 2013-02-07
  - Fix CVE-2013-0263, timing attack against Rack::Session::Cookie
  - Fix CVE-2013-0262, symlink path traversal in Rack::File
  - Add various methods to Session for enhanced Rails compatibility
  - Request#trusted_proxy? now only matches whole strings
  - Add JSON cookie coder, to be default in Rack 1.6+ due to security concerns
  - URLMap host matching in environments that don't set the Host header fixed
  - Fix a race condition that could result in overwritten pidfiles
  - Various documentation additions

## [1.4.5] 2013-02-07
  - Fix CVE-2013-0263, timing attack against Rack::Session::Cookie
  - Fix CVE-2013-0262, symlink path traversal in Rack::File

## [1.1.6, 1.2.8, 1.3.10] 2013-02-07
  - Fix CVE-2013-0263, timing attack against Rack::Session::Cookie

## [1.5.1] 2013-01-28
  - Rack::Lint check_hijack now conforms to other parts of SPEC
  - Added hash-like methods to Abstract::ID::SessionHash for compatibility
  - Various documentation corrections

## [1.5.0] 2013-01-21
  - Introduced hijack SPEC, for before-response and after-response hijacking
  - SessionHash is no longer a Hash subclass
  - Rack::File cache_control parameter is removed, in place of headers options
  - Rack::Auth::AbstractRequest#scheme now yields strings, not symbols
  - Rack::Utils cookie functions now format expires in RFC 2822 format
  - Rack::File now has a default mime type
  - rackup -b 'run Rack::Files.new(".")', option provides command line configs
  - Rack::Deflater will no longer double encode bodies
  - Rack::Mime#match? provides convenience for Accept header matching
  - Rack::Utils#q_values provides splitting for Accept headers
  - Rack::Utils#best_q_match provides a helper for Accept headers
  - Rack::Handler.pick provides convenience for finding available servers
  - Puma added to the list of default servers (preferred over Webrick)
  - Various middleware now correctly close body when replacing it
  - Rack::Request#params is no longer persistent with only GET params
  - Rack::Request#update_param and #delete_param provide persistent operations
  - Rack::Request#trusted_proxy? now returns true for local unix sockets
  - Rack::Response no longer forces Content-Types
  - Rack::Sendfile provides local mapping configuration options
  - Rack::Utils#rfc2109 provides old netscape style time output
  - Updated HTTP status codes
  - Ruby 1.8.6 likely no longer passes tests, and is no longer fully supported

## [1.4.4, 1.3.9, 1.2.7, 1.1.5] 2013-01-13
  - [SEC] Rack::Auth::AbstractRequest no longer symbolizes arbitrary strings
  - Fixed erroneous test case in the 1.3.x series

## [1.4.3] 2013-01-07
  - Security: Prevent unbounded reads in large multipart boundaries

## [1.3.8] 2013-01-07
  - Security: Prevent unbounded reads in large multipart boundaries

## [1.4.2] 2013-01-06
  - Add warnings when users do not provide a session secret
  - Fix parsing performance for unquoted filenames
  - Updated URI backports
  - Fix URI backport version matching, and silence constant warnings
  - Correct parameter parsing with empty values
  - Correct rackup '-I' flag, to allow multiple uses
  - Correct rackup pidfile handling
  - Report rackup line numbers correctly
  - Fix request loops caused by non-stale nonces with time limits
  - Fix reloader on Windows
  - Prevent infinite recursions from Response#to_ary
  - Various middleware better conforms to the body close specification
  - Updated language for the body close specification
  - Additional notes regarding ECMA escape compatibility issues
  - Fix the parsing of multiple ranges in range headers
  - Prevent errors from empty parameter keys
  - Added PATCH verb to Rack::Request
  - Various documentation updates
  - Fix session merge semantics (fixes rack-test)
  - Rack::Static :index can now handle multiple directories
  - All tests now utilize Rack::Lint (special thanks to Lars Gierth)
  - Rack::File cache_control parameter is now deprecated, and removed by 1.5
  - Correct Rack::Directory script name escaping
  - Rack::Static supports header rules for sophisticated configurations
  - Multipart parsing now works without a Content-Length header
  - New logos courtesy of Zachary Scott!
  - Rack::BodyProxy now explicitly defines #each, useful for C extensions
  - Cookies that are not URI escaped no longer cause exceptions

## [1.3.7] 2013-01-06
  - Add warnings when users do not provide a session secret
  - Fix parsing performance for unquoted filenames
  - Updated URI backports
  - Fix URI backport version matching, and silence constant warnings
  - Correct parameter parsing with empty values
  - Correct rackup '-I' flag, to allow multiple uses
  - Correct rackup pidfile handling
  - Report rackup line numbers correctly
  - Fix request loops caused by non-stale nonces with time limits
  - Fix reloader on Windows
  - Prevent infinite recursions from Response#to_ary
  - Various middleware better conforms to the body close specification
  - Updated language for the body close specification
  - Additional notes regarding ECMA escape compatibility issues
  - Fix the parsing of multiple ranges in range headers

## [1.2.6] 2013-01-06
  - Add warnings when users do not provide a session secret
  - Fix parsing performance for unquoted filenames

## [1.1.4] 2013-01-06
  - Add warnings when users do not provide a session secret

## [1.4.1] 2012-01-22
  - Alter the keyspace limit calculations to reduce issues with nested params
  - Add a workaround for multipart parsing where files contain unescaped "%"
  - Added Rack::Response::Helpers#method_not_allowed? (code 405)
  - Rack::File now returns 404 for illegal directory traversals
  - Rack::File now returns 405 for illegal methods (non HEAD/GET)
  - Rack::Cascade now catches 405 by default, as well as 404
  - Cookies missing '--' no longer cause an exception to be raised
  - Various style changes and documentation spelling errors
  - Rack::BodyProxy always ensures to execute its block
  - Additional test coverage around cookies and secrets
  - Rack::Session::Cookie can now be supplied either secret or old_secret
  - Tests are no longer dependent on set order
  - Rack::Static no longer defaults to serving index files
  - Rack.release was fixed

## [1.4.0] 2011-12-28
  - Ruby 1.8.6 support has officially been dropped. Not all tests pass.
  - Raise sane error messages for broken config.ru
  - Allow combining run and map in a config.ru
  - Rack::ContentType will not set Content-Type for responses without a body
  - Status code 205 does not send a response body
  - Rack::Response::Helpers will not rely on instance variables
  - Rack::Utils.build_query no longer outputs '=' for nil query values
  - Various mime types added
  - Rack::MockRequest now supports HEAD
  - Rack::Directory now supports files that contain RFC3986 reserved chars
  - Rack::File now only supports GET and HEAD requests
  - Rack::Server#start now passes the block to Rack::Handler::<h>#run
  - Rack::Static now supports an index option
  - Added the Teapot status code
  - rackup now defaults to Thin instead of Mongrel (if installed)
  - Support added for HTTP_X_FORWARDED_SCHEME
  - Numerous bug fixes, including many fixes for new and alternate rubies

## [1.1.3] 2011-12-28
  - Security fix. http://www.ocert.org/advisories/ocert-2011-003.html
    Further information here: http://jruby.org/2011/12/27/jruby-1-6-5-1

## [1.3.5] 2011-10-17
  - Fix annoying warnings caused by the backport in 1.3.4

## [1.3.4] 2011-10-01
  - Backport security fix from 1.9.3, also fixes some roundtrip issues in URI
  - Small documentation update
  - Fix an issue where BodyProxy could cause an infinite recursion
  - Add some supporting files for travis-ci

## [1.2.4] 2011-09-16
  - Fix a bug with MRI regex engine to prevent XSS by malformed unicode

## [1.3.3] 2011-09-16
  - Fix bug with broken query parameters in Rack::ShowExceptions
  - Rack::Request#cookies no longer swallows exceptions on broken input
  - Prevents XSS attacks enabled by bug in Ruby 1.8's regexp engine
  - Rack::ConditionalGet handles broken If-Modified-Since helpers

## [1.3.2] 2011-07-16
  - Fix for Rails and rack-test, Rack::Utils#escape calls to_s

## [1.3.1] 2011-07-13
  - Fix 1.9.1 support
  - Fix JRuby support
  - Properly handle $KCODE in Rack::Utils.escape
  - Make method_missing/respond_to behavior consistent for Rack::Lock,
    Rack::Auth::Digest::Request and Rack::Multipart::UploadedFile
  - Reenable passing rack.session to session middleware
  - Rack::CommonLogger handles streaming responses correctly
  - Rack::MockResponse calls close on the body object
  - Fix a DOS vector from MRI stdlib backport

## [1.2.3] 2011-05-22
  - Pulled in relevant bug fixes from 1.3
  - Fixed 1.8.6 support

## [1.3.0] 2011-05-22
  - Various performance optimizations
  - Various multipart fixes
  - Various multipart refactors
  - Infinite loop fix for multipart
  - Test coverage for Rack::Server returns
  - Allow files with '..', but not path components that are '..'
  - rackup accepts handler-specific options on the command line
  - Request#params no longer merges POST into GET (but returns the same)
  - Use URI.encode_www_form_component instead. Use core methods for escaping.
  - Allow multi-line comments in the config file
  - Bug L#94 reported by Nikolai Lugovoi, query parameter unescaping.
  - Rack::Response now deletes Content-Length when appropriate
  - Rack::Deflater now supports streaming
  - Improved Rack::Handler loading and searching
  - Support for the PATCH verb
  - env['rack.session.options'] now contains session options
  - Cookies respect renew
  - Session middleware uses SecureRandom.hex

## [1.2.2, 1.1.2] 2011-03-13
  - Security fix in Rack::Auth::Digest::MD5: when authenticator
    returned nil, permission was granted on empty password.

## [1.2.1] 2010-06-15
  - Make CGI handler rewindable
  - Rename spec/ to test/ to not conflict with SPEC on lesser
    operating systems

## [1.2.0] 2010-06-13
  - Removed Camping adapter: Camping 2.0 supports Rack as-is
  - Removed parsing of quoted values
  - Add Request.trace? and Request.options?
  - Add mime-type for .webm and .htc
  - Fix HTTP_X_FORWARDED_FOR
  - Various multipart fixes
  - Switch test suite to bacon

## [1.1.0] 2010-01-03
  - Moved Auth::OpenID to rack-contrib.
  - SPEC change that relaxes Lint slightly to allow subclasses of the
    required types
  - SPEC change to document rack.input binary mode in greater detail
  - SPEC define optional rack.logger specification
  - File servers support X-Cascade header
  - Imported Config middleware
  - Imported ETag middleware
  - Imported Runtime middleware
  - Imported Sendfile middleware
  - New Logger and NullLogger middlewares
  - Added mime type for .ogv and .manifest.
  - Don't squeeze PATH_INFO slashes
  - Use Content-Type to determine POST params parsing
  - Update Rack::Utils::HTTP_STATUS_CODES hash
  - Add status code lookup utility
  - Response should call #to_i on the status
  - Add Request#user_agent
  - Request#host knows about forwarded host
  - Return an empty string for Request#host if HTTP_HOST and
    SERVER_NAME are both missing
  - Allow MockRequest to accept hash params
  - Optimizations to HeaderHash
  - Refactored rackup into Rack::Server
  - Added Utils.build_nested_query to complement Utils.parse_nested_query
  - Added Utils::Multipart.build_multipart to complement
    Utils::Multipart.parse_multipart
  - Extracted set and delete cookie helpers into Utils so they can be
    used outside Response
  - Extract parse_query and parse_multipart in Request so subclasses
    can change their behavior
  - Enforce binary encoding in RewindableInput
  - Set correct external_encoding for handlers that don't use RewindableInput

## [1.0.1] 2009-10-18
  - Bump remainder of rack.versions.
  - Support the pure Ruby FCGI implementation.
  - Fix for form names containing "=": split first then unescape components
  - Fixes the handling of the filename parameter with semicolons in names.
  - Add anchor to nested params parsing regexp to prevent stack overflows
  - Use more compatible gzip write api instead of "<<".
  - Make sure that Reloader doesn't break when executed via ruby -e
  - Make sure WEBrick respects the :Host option
  - Many Ruby 1.9 fixes.

## [1.0.0] 2009-04-25
  - SPEC change: Rack::VERSION has been pushed to [1,0].
  - SPEC change: header values must be Strings now, split on "\n".
  - SPEC change: Content-Length can be missing, in this case chunked transfer
    encoding is used.
  - SPEC change: rack.input must be rewindable and support reading into
    a buffer, wrap with Rack::RewindableInput if it isn't.
  - SPEC change: rack.session is now specified.
  - SPEC change: Bodies can now additionally respond to #to_path with
    a filename to be served.
  - NOTE: String bodies break in 1.9, use an Array consisting of a
    single String instead.
  - New middleware Rack::Lock.
  - New middleware Rack::ContentType.
  - Rack::Reloader has been rewritten.
  - Major update to Rack::Auth::OpenID.
  - Support for nested parameter parsing in Rack::Response.
  - Support for redirects in Rack::Response.
  - HttpOnly cookie support in Rack::Response.
  - The Rakefile has been rewritten.
  - Many bugfixes and small improvements.

## [0.9.1] 2009-01-09
  - Fix directory traversal exploits in Rack::File and Rack::Directory.

## [0.9] 2009-01-06
  - Rack is now managed by the Rack Core Team.
  - Rack::Lint is stricter and follows the HTTP RFCs more closely.
  - Added ConditionalGet middleware.
  - Added ContentLength middleware.
  - Added Deflater middleware.
  - Added Head middleware.
  - Added MethodOverride middleware.
  - Rack::Mime now provides popular MIME-types and their extension.
  - Mongrel Header now streams.
  - Added Thin handler.
  - Official support for swiftiplied Mongrel.
  - Secure cookies.
  - Made HeaderHash case-preserving.
  - Many bugfixes and small improvements.

## [0.4] 2008-08-21
  - New middleware, Rack::Deflater, by Christoffer Sawicki.
  - OpenID authentication now needs ruby-openid 2.
  - New Memcache sessions, by blink.
  - Explicit EventedMongrel handler, by Joshua Peek <josh@joshpeek.com>
  - Rack::Reloader is not loaded in rackup development mode.
  - rackup can daemonize with -D.
  - Many bugfixes, especially for pool sessions, URLMap, thread safety
    and tempfile handling.
  - Improved tests.
  - Rack moved to Git.

## [0.3] 2008-02-26
  - LiteSpeed handler, by Adrian Madrid.
  - SCGI handler, by Jeremy Evans.
  - Pool sessions, by blink.
  - OpenID authentication, by blink.
  - :Port and :File options for opening FastCGI sockets, by blink.
  - Last-Modified HTTP header for Rack::File, by blink.
  - Rack::Builder#use now accepts blocks, by Corey Jewett.
    (See example/protectedlobster.ru)
  - HTTP status 201 can contain a Content-Type and a body now.
  - Many bugfixes, especially related to Cookie handling.

## [0.2] 2007-05-16
  - HTTP Basic authentication.
  - Cookie Sessions.
  - Static file handler.
  - Improved Rack::Request.
  - Improved Rack::Response.
  - Added Rack::ShowStatus, for better default error messages.
  - Bug fixes in the Camping adapter.
  - Removed Rails adapter, was too alpha.

## [0.1] 2007-03-03

[@ioquatix]: https://github.com/ioquatix "Samuel Williams"
[@jeremyevans]: https://github.com/jeremyevans "Jeremy Evans"
[@amatsuda]: https://github.com/amatsuda "Akira Matsuda"
[@wjordan]: https://github.com/wjordan "Will Jordan"
[@BlakeWilliams]: https://github.com/BlakeWilliams "Blake Williams"
[@davidstosik]: https://github.com/davidstosik "David Stosik"
[@earlopain]: https://github.com/earlopain "Earlopain"
[@wynksaiddestroy]: https://github.com/wynksaiddestroy "Fabian Winkler"
[@matthewd]: https://github.com/matthewd "Matthew Draper"
