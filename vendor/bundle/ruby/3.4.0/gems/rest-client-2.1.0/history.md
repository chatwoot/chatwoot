# 2.1.0

- Add a dependency on http-accept for parsing Content-Type charset headers.
  This works around a bad memory leak introduced in MRI Ruby 2.4.0 and fixed in
  Ruby 2.4.2. (#615)
- Use mime/types/columnar from mime-types 2.6.1+, which is leaner in memory
  usage than the older storage model of mime-types. (#393)
- Add `:log` option to individual requests. This allows users to set a log on a
  per-request / per-resource basis instead of the kludgy global log. (#538)
- Log request duration by tracking request start and end times. Make
  `log_response` a method on the Response object, and ensure the `size` method
  works on RawResponse objects. (#126)
  - `# => 200 OK | text/html 1270 bytes, 0.08s`
  - Also add a new `:stream_log_percent` parameter, which is applicable only
    when `:raw_response => true` is set. This causes progress logs to be
    emitted only on every N% (default 10%) of the total download size rather
    than on every chunk.
- Drop custom handling of compression and use built-in Net::HTTP support for
  supported Content-Encodings like gzip and deflate. Don't set any explicit
  `Accept-Encoding` header, rely instead on Net::HTTP defaults. (#597)
  - Note: this changes behavior for compressed responses when using
    `:raw_response => true`. Previously the raw response would not have been
    uncompressed by rest-client, but now Net::HTTP will uncompress it.
- The previous fix to avoid having Netrc username/password override an
  Authorization header was case-sensitive and incomplete. Fix this by
  respecting existing Authorization headers, regardless of letter case. (#550)
- Handle ParamsArray payloads. Previously, rest-client would silently drop a
  ParamsArray passed as the payload. Instead, automatically use
  Payload::Multipart if the ParamsArray contains a file handle, or use
  Payload::UrlEncoded if it doesn't. (#508)
- Gracefully handle Payload objects (Payload::Base or subclasses) that are
  passed as a payload argument. Previously, `Payload.generate` would wrap a
  Payload object in Payload::Streamed, creating a pointlessly nested payload.
  Also add a `closed?` method to Payload objects, and don't error in
  `short_inspect` if `size` returns nil. (#603)
- Test with an image in the public domain to avoid licensing complexity. (#607)

# 2.0.2

- Suppress the header override warning introduced in 2.0.1 if the value is the
  same. There's no conflict if the value is unchanged. (#578)

# 2.0.1

- Warn if auto-generated headers from the payload, such as Content-Type,
  override headers set by the user. This is usually not what the user wants to
  happen, and can be surprising. (#554)
- Drop the old check for weak default TLS ciphers, and use the built-in Ruby
  defaults. Ruby versions from Oct. 2014 onward use sane defaults, so this is
  no longer needed. (#573)

# 2.0.0

This release is largely API compatible, but makes several breaking changes.

- Drop support for Ruby 1.9
- Allow mime-types as new as 3.x (requires ruby 2.0)
- Respect Content-Type charset header provided by server. Previously,
  rest-client would not override the string encoding chosen by Net::HTTP. Now
  responses that specify a charset will yield a body string in that encoding.
  For example, `Content-Type: text/plain; charset=EUC-JP` will return a String
  encoded with `Encoding::EUC_JP`. (#361)
- Change exceptions raised on request timeout. Instead of
  `RestClient::RequestTimeout` (which is still used for HTTP 408), network
  timeouts will now raise either `RestClient::Exceptions::ReadTimeout` or
  `RestClient::Exceptions::OpenTimeout`, both of which inherit from
  `RestClient::Exceptions::Timeout`. For backwards compatibility, this still
  inherits from `RestClient::RequestTimeout` so existing uses will still work.
  This may change in a future major release. These new timeout classes also
  make the original wrapped exception available as `#original_exception`.
- Unify request exceptions under `RestClient::RequestFailed`, which still
  inherits from `ExceptionWithResponse`. Previously, HTTP 304, 401, and 404
  inherited directly from `ExceptionWithResponse` rather than from
  `RequestFailed`. Now _all_ HTTP status code exceptions inherit from both.
- Rename the `:timeout` request option to `:read_timeout`. When `:timeout` is
  passed, now set both `:read_timeout` and `:open_timeout`.
- Change default HTTP Accept header to `*/*`
- Use a more descriptive User-Agent header by default
- Drop RC4-MD5 from default cipher list
- Only prepend http:// to URIs without a scheme
- Fix some support for using IPv6 addresses in URLs (still affected by Ruby
  2.0+ bug https://bugs.ruby-lang.org/issues/9129, with the fix expected to be
  backported to 2.0 and 2.1)
- `Response` objects are now a subclass of `String` rather than a `String` that
  mixes in the response functionality. Most of the methods remain unchanged,
  but this makes it much easier to understand what is happening when you look
  at a RestClient response object. There are a few additional changes:
  - Response objects now implement `.inspect` to make this distinction clearer.
  - `Response#to_i` will now behave like `String#to_i` instead of returning the
    HTTP response code, which was very surprising behavior.
  - `Response#body` and `#to_s` will now return a true `String` object rather
    than self. Previously there was no easy way to get the true `String`
    response instead of the Frankenstein response string object with
    AbstractResponse mixed in.
  - Response objects no longer accept an extra request args hash, but instead
    access request args directly from the request object, which reduces
    confusion and duplication.
- Handle multiple HTTP response headers with the same name (except for
  Set-Cookie, which is special) by joining the values with a comma space,
  compliant with RFC 7230
- Rewrite cookie support to be much smarter and to use cookie jars consistently
  for requests, responses, and redirection in order to resolve long-standing
  complaints about the previously broken behavior: (#498)
  - The `:cookies` option may now be a Hash of Strings, an Array of
    HTTP::Cookie objects, or a full HTTP::CookieJar.
  - Add `RestClient::Request#cookie_jar` and reimplement `Request#cookies` to
    be a wrapper around the cookie jar.
  - Still support passing the `:cookies` option in the headers hash, but now
    raise ArgumentError if that option is also passed to `Request#initialize`.
  - Warn if both `:cookies` and a `Cookie` header are supplied.
  - Use the `Request#cookie_jar` as the basis for `Response#cookie_jar`,
    creating a copy of the jar and adding any newly received cookies.
  - When following redirection, also use this same strategy so that cookies
    from the original request are carried through in a standards-compliant way
    by the cookie jar.
- Don't set basic auth header if explicit `Authorization` header is specified
- Add `:proxy` option to requests, which can be used for thread-safe
  per-request proxy configuration, overriding `RestClient.proxy`
- Allow overriding `ENV['http_proxy']` to disable proxies by setting
  `RestClient.proxy` to a falsey value. Previously there was no way in Ruby 2.x
  to turn off a proxy specified in the environment without changing `ENV`.
- Add actual support for streaming request payloads. Previously rest-client
  would call `.to_s` even on RestClient::Payload::Streamed objects. Instead,
  treat any object that responds to `.read` as a streaming payload and pass it
  through to `.body_stream=` on the Net:HTTP object. This massively reduces the
  memory required for large file uploads.
- Changes to redirection behavior: (#381, #484)
  - Remove `RestClient::MaxRedirectsReached` in favor of the normal
    `ExceptionWithResponse` subclasses. This makes the response accessible on
    the exception object as `.response`, making it possible for callers to tell
    what has actually happened when the redirect limit is reached.
  - When following HTTP redirection, store a list of each previous response on
    the response object as `.history`. This makes it possible to access the
    original response headers and body before the redirection was followed.
  - Follow redirection consistently, regardless of whether the HTTP method was
    passed as a symbol or string. Under the hood rest-client now normalizes the
    HTTP request method to a lowercase string.
- Add `:before_execution_proc` option to `RestClient::Request`. This makes it
  possible to add procs like `RestClient.add_before_execution_proc` to a single
  request without global state.
- Run tests on Travis's beta OS X support.
- Make `Request#transmit` a private method, along with a few others.
- Refactor URI parsing to happen earlier, in Request initialization.
- Improve consistency and functionality of complex URL parameter handling:
  - When adding URL params, handle URLs that already contain params.
  - Add new convention for handling URL params containing deeply nested arrays
    and hashes, unify handling of null/empty values, and use the same code for
    GET and POST params. (#437)
  - Add the RestClient::ParamsArray class, a simple array-like container that
    can be used to pass multiple keys with same name or keys where the ordering
    is significant.
- Add a few more exception classes for obscure HTTP status codes.
- Multipart: use a much more robust multipart boundary with greater entropy.
- Make `RestClient::Payload::Base#inspect` stop pretending to be a String.
- Add `Request#redacted_uri` and `Request#redacted_url` to display the URI
  with any password redacted.

# 2.0.0.rc1

Changes in the release candidate that did not persist through the final 2.0.0
release:
- RestClient::Exceptions::Timeout was originally going to be a direct subclass
  of RestClient::Exception in the release candidate. This exception tree was
  made a subclass of RestClient::RequestTimeout prior to the final release.

# 1.8.0

- Security: implement standards compliant cookie handling by adding a
  dependency on http-cookie. This breaks compatibility, but was necessary to
  address a session fixation / cookie disclosure vulnerability.
  (#369 / CVE-2015-1820)

  Previously, any Set-Cookie headers found in an HTTP 30x response would be
  sent to the redirection target, regardless of domain. Responses now expose a
  cookie jar and respect standards compliant domain / path flags in Set-Cookie
  headers.

# 1.7.3

- Security: redact password in URI from logs (#349 / OSVDB-117461)
- Drop monkey patch on MIME::Types (added `type_for_extension` method, use
  the public interface instead.

# 1.7.2

- Ignore duplicate certificates in CA store on Windows

# 1.7.1

- Relax mime-types dependency to continue supporting mime-types 1.x series.
  There seem to be a large number of popular gems that have depended on
  mime-types '~> 1.16' until very recently.
- Improve urlencode performance
- Clean up a number of style points

# 1.7.0

- This release drops support for Ruby 1.8.7 and breaks compatibility in a few
  other relatively minor ways
- Upgrade to mime-types ~> 2.0
- Don't CGI.unescape cookie values sent to the server (issue #89)
- Add support for reading credentials from netrc
- Lots of SSL changes and enhancements: (#268)
  - Enable peer verification by default (setting `VERIFY_PEER` with OpenSSL)
  - By default, use the system default certificate store for SSL verification,
    even on Windows (this uses a separate Windows build that pulls in ffi)
  - Add support for SSL `ca_path`
  - Add support for SSL `cert_store`
  - Add support for SSL `verify_callback` (with some caveats for jruby, OS X, #277)
  - Add support for SSL ciphers, and choose secure ones by default
- Run tests under travis
- Several other bugfixes and test improvements
  - Convert Errno::ETIMEDOUT to RestClient::RequestTimeout
  - Handle more HTTP response codes from recent standards
  - Save raw responses to binary mode tempfile (#110)
  - Disable timeouts with :timeout => nil rather than :timeout => -1
  - Drop all Net::HTTP monkey patches

# 1.6.14

- This release is unchanged from 1.6.9. It was published in order to supersede
  the malicious 1.6.10-13 versions, even for users who are still pinning to the
  legacy 1.6.x series. All users are encouraged to upgrade to rest-client 2.x.

# 1.6.10, 1.6.11, 1.6.12, 1.6.13 (CVE-2019-15224)

- These versions were pushed by a malicious actor and included a backdoor permitting
  remote code execution in Rails environments. (#713)
- They were live for about five days before being yanked.

# 1.6.9

- Move rdoc to a development dependency

# 1.6.8

- The 1.6.x series will be the last to support Ruby 1.8.7
- Pin mime-types to < 2.0 to maintain Ruby 1.8.7 support
- Add Gemfile, AUTHORS, add license to gemspec
- Point homepage at https://github.com/rest-client/rest-client
- Clean up and fix various tests and ruby warnings
- Backport `ssl_verify_callback` functionality from 1.7.0

# 1.6.7

- rebuild with 1.8.7 to avoid https://github.com/rubygems/rubygems/pull/57

# 1.6.6

- 1.6.5 was yanked

# 1.6.5

- RFC6265 requires single SP after ';' for separating parameters pairs in the 'Cookie:' header (patch provided by Hiroshi Nakamura)
- enable url parameters for all actions
- detect file parameters in arrays
- allow disabling the timeouts by passing -1 (patch provided by Sven Böhm)

# 1.6.4

- fix restclient script compatibility with 1.9.2
- fix unlinking temp file (patch provided by Evan Smith)
- monkeypatching ruby for http patch method (patch provided by Syl Turner)

# 1.6.3

- 1.6.2 was yanked

# 1.6.2

- add support for HEAD in resources (patch provided by tpresa)
- fix shell for 1.9.2
- workaround when some gem monkeypatch net/http (patch provided by Ian Warshak)
- DELETE requests should process parameters just like GET and HEAD
- adding :block_response parameter for manual processing
- limit number of redirections (patch provided by Chris Dinn)
- close and unlink the temp file created by playload (patch provided by Chris Green)
- make gemspec Rubygems 1.8 compatible (patch provided by David Backeus)
- added RestClient.reset_before_execution_procs (patch provided by Cloudify)
- added PATCH method (patch provided by Jeff Remer)
- hack for HTTP servers that use raw DEFLATE compression, see http://www.ruby-forum.com/topic/136825 (path provided by James Reeves)

# 1.6.1

- add response body in Exception#inspect
- add support for RestClient.options
- fix tests for 1.9.2 (patch provided by Niko Dittmann)
- block passing in Resource#[] (patch provided by Niko Dittmann)
- cookies set in a response should be kept in a redirect
- HEAD requests should process parameters just like GET (patch provided by Rob Eanes)
- exception message should never be nil (patch provided by Michael Klett)

# 1.6.0

- forgot to include rest-client.rb in the gem
- user, password and user-defined headers should survive a redirect
- added all missing status codes
- added parameter passing for get request using the :param key in header
- the warning about the logger when using a string was a bad idea
- multipart parameters names should not be escaped
- remove the cookie escaping introduced by migrating to CGI cookie parsing in 1.5.1
- add a streamed payload type (patch provided by Caleb Land)
- Exception#http_body works even when no response

# 1.5.1

- only converts headers keys which are Symbols
- use CGI for cookie parsing instead of custom code
- unescape user and password before using them (patch provided by Lars Gierth)
- expand ~ in ~/.restclientrc (patch provided by Mike Fletcher)
- ssl verification raise an exception when the ca certificate is incorrect (patch provided by Braintree)

# 1.5.0

- the response is now a String with the Response module a.k.a. the change in 1.4.0 was a mistake (Response.body is returning self for compatability)
- added AbstractResponse.to_i to improve semantic
- multipart Payloads ignores the name attribute if it's not set (patch provided by Tekin Suleyman)
- correctly takes into account user headers whose keys are strings (path provided by Cyril Rohr)
- use binary mode for payload temp file
- concatenate cookies with ';'
- fixed deeper parameter handling
- do not quote the boundary in the Content-Type header (patch provided by W. Andrew Loe III)

# 1.4.2

- fixed RestClient.add_before_execution_proc (patch provided by Nicholas Wieland)
- fixed error when an exception is raised without a response (patch provided by Caleb Land)

# 1.4.1

- fixed parameters managment when using hash

# 1.4.0

- Response is no more a String, and the mixin is replaced by an abstract_response, existing calls are redirected to response body with a warning.
- enable repeated parameters  RestClient.post 'http://example.com/resource', :param1 => ['one', 'two', 'three'], => :param2 => 'foo' (patch provided by Rodrigo Panachi)
- fixed the redirect code concerning relative path and query string combination (patch provided by Kevin Read)
- redirection code moved to Response so redirection can be customized using the block syntax
- only get and head redirections are now followed by default, as stated in the specification
- added RestClient.add_before_execution_proc to hack the http request, like for oauth

The response change may be breaking in rare cases.

# 1.3.1

- added compatibility to enable responses in exception to act like Net::HTTPResponse

# 1.3.0

- a block can be used to process a request's result, this enable to handle custom error codes or paththrought (design by Cyril Rohr)
- cleaner log API, add a warning for some cases but should be compatible
- accept multiple "Set-Cookie" headers, see http://www.ietf.org/rfc/rfc2109.txt (patch provided by Cyril Rohr)
- remove "Content-Length" and "Content-Type" headers when following a redirection (patch provided by haarts)
- all http error codes have now a corresponding exception class and all of them contain the Reponse -> this means that the raised exception can be different
- changed "Content-Disposition: multipart/form-data" to "Content-Disposition: form-data" per RFC 2388 (patch provided by Kyle Crawford)

The only breaking change should be the exception classes, but as the new classes inherits from the existing ones, the breaking cases should be rare.

# 1.2.0

- formatting changed from tabs to spaces
- logged requests now include generated headers
- accept and content-type headers can now be specified using extentions: RestClient.post "http://example.com/resource", { 'x' => 1 }.to_json, :content_type => :json, :accept => :json
- should be 1.1.1 but renamed to 1.2.0 because 1.1.X versions has already been packaged on Debian

# 1.1.0

- new maintainer: Archiloque, the working repo is now at http://github.com/archiloque/rest-client
- a mailing list has been created at rest.client@librelist.com and an freenode irc channel #rest-client
- François Beausoleil' multipart code from http://github.com/francois/rest-client has been merged
- ability to use hash in hash as payload
- the mime-type code now rely on the mime-types gem http://mime-types.rubyforge.org/ instead of an internal partial list
- 204 response returns a Response instead of nil (patch provided by Elliott Draper)

All changes exept the last one should be fully compatible with the previous version.

NOTE: due to a dependency problem and to the last change, heroku users should update their heroku gem to >= 1.5.3 to be able to use this version.
