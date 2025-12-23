## 0.21.0

* [escape filename in the multipart/form-data Content-Disposition header](https://github.com/jnunemaker/httparty/commit/cdb45a678c43e44570b4e73f84b1abeb5ec22b8e)
* [Fix request marshaling](https://github.com/jnunemaker/httparty/pull/767)
* [Replace `mime-types` with `mini_mime`](https://github.com/jnunemaker/httparty/pull/769)

## 0.20.0

Breaking changes

* Require Ruby >= 2.3.0

Fixes

* [`Marshal.dump` fails on response objects when request option `:logger` is set or `:parser` is a proc](https://github.com/jnunemaker/httparty/pull/714)
* [Switch `:pem` option to to `OpenSSL::PKey.read` to support other algorithms](https://github.com/jnunemaker/httparty/pull/720)

## 0.19.1

* [Remove use of unary + method for creating non-frozen string to increase compatibility with older versions of ruby](https://github.com/jnunemaker/httparty/commit/4416141d37fd71bdba4f37589ec265f55aa446ce)

## 0.19.0

* [Multipart/Form-Data: rewind files after read](https://github.com/jnunemaker/httparty/pull/709)
* [add frozen_string_literal pragma to all files](https://github.com/jnunemaker/httparty/pull/711)
* [Better handling of Accept-Encoding / Content-Encoding decompression (fixes #562)](https://github.com/jnunemaker/httparty/pull/729)

## 0.18.1

* [Rename cop Lint/HandleExceptions to Lint/SuppressedException](https://github.com/jnunemaker/httparty/pull/699).
* [Encode keys in query params](https://github.com/jnunemaker/httparty/pull/698).
* [Fixed SSL doc example](https://github.com/jnunemaker/httparty/pull/692).
* [Add a build status badge](https://github.com/jnunemaker/httparty/pull/701).


## 0.18.0

* [Support gzip/deflate transfer encoding when explicit headers are set](https://github.com/jnunemaker/httparty/pull/678).
* [Support edge case cookie format with a blank attribute](https://github.com/jnunemaker/httparty/pull/685).

## 0.17.3

0.17.2 is broken https://github.com/jnunemaker/httparty/issues/681

## 0.17.2

* [Add Response#nil? deprecetion warning](https://github.com/jnunemaker/httparty/pull/680)

## 0.17.1

* [Pass options to dynamic block headers](https://github.com/jnunemaker/httparty/pull/661)
* [Normalize urls with URI adapter to allow International Domain Names support](https://github.com/jnunemaker/httparty/pull/668)
* [Add max_retries support](https://github.com/jnunemaker/httparty/pull/660)
* [Minize gem size by removing test files](https://github.com/jnunemaker/httparty/pull/658)

## 0.17.0

* [Fix encoding of streamed chunk](https://github.com/jnunemaker/httparty/pull/644)
* [Avoid modifying frozen strings](https://github.com/jnunemaker/httparty/pull/649)
* [Expose .connection on fragment block param](https://github.com/jnunemaker/httparty/pull/648)
* [Add support for `Net::HTTP#write_timeout` method (Ruby 2.6.0)](https://github.com/jnunemaker/httparty/pull/647)

## 0.16.4
* [Add support for Ruby 2.6](https://github.com/jnunemaker/httparty/pull/636)
* [Fix a few multipart issues](https://github.com/jnunemaker/httparty/pull/626)
* [Improve a memory usage for https requests](https://github.com/jnunemaker/httparty/pull/625)
* [Add response code to streamed body](https://github.com/jnunemaker/httparty/pull/588)

## 0.16.3
* [Add Logstash-compatible formatter](https://github.com/jnunemaker/httparty/pull/612)
* [Add support for headers specified with symbols](https://github.com/jnunemaker/httparty/pull/622)
* [Fix response object marshalling](https://github.com/jnunemaker/httparty/pull/618)
* [Add ability to send multipart, without passing file](https://github.com/jnunemaker/httparty/pull/615)
* [Fix detection of content_type for multipart payload](https://github.com/jnunemaker/httparty/pull/616)
* [Process dynamic headers before making actual request](https://github.com/jnunemaker/httparty/pull/606)
* [Fix multipart uploads with ActionDispatch::Http::UploadedFile TempFile by using original_filename](https://github.com/jnunemaker/httparty/pull/598)
* [Added support for lock and unlock http requests](https://github.com/jnunemaker/httparty/pull/596)

## 0.16.2

* [Support ActionDispatch::Http::UploadedFile again](https://github.com/jnunemaker/httparty/pull/585)

## 0.16.1

* [Parse content with application/hal+json content type as JSON](https://github.com/jnunemaker/httparty/pull/573)
* [Convert objects to string when concatenating in multipart stuff](https://github.com/jnunemaker/httparty/pull/575)
* [Fix multipart to set its header even when other headers are provided](https://github.com/jnunemaker/httparty/pull/576)

## 0.16.0

* [Add multipart support](https://github.com/jnunemaker/httparty/pull/569)

## 0.15.7

Fixed

* [Add Response#pretty_print | Restore documented behavior](https://github.com/jnunemaker/httparty/pull/570)
* [Add ability to parse response from JSONAPI ](https://github.com/jnunemaker/httparty/pull/553)

## 0.15.6

Fixed

* [Encoding and content type stuff](https://github.com/jnunemaker/httparty/pull/543)

## 0.15.5

Fixed

* [Use non-destructive gsub](https://github.com/jnunemaker/httparty/pull/540)

## 0.15.4

Fixed

* Prevent gsub errors with different encodings.
* Prevent passing nil to encode_body.

## 0.15.3

Fixed

* [Fix processing nil body for HEAD requests](https://github.com/jnunemaker/httparty/pull/530).
* Add missing require to headers.rb (33439a8).

## 0.15.2

Fixed

* Remove symlink from specs. It was reportedly still getting bundled with gem.

## 0.15.1

Fixed

* Stop including test files in gem. Fixes installation issues on windows due to symlink in spec dir.

## 0.15.0

Breaking Changes

* require Ruby >= 2.0.0

Fixed

* [fix numerous bugs](https://github.com/jnunemaker/httparty/pull/513)
* [handle utf-8 bom for json parsing](https://github.com/jnunemaker/httparty/pull/520)
* [do not overwrite default headers unless specified](https://github.com/jnunemaker/httparty/pull/518)

## 0.14.0

Breaking Changes

* None

Added

* [added status predicate methods to Response#respond_to?](https://github.com/jnunemaker/httparty/pull/482)
* [support for MKCOL method](https://github.com/jnunemaker/httparty/pull/465)
* one fewer dependency: [remove json gem from gemspec](https://github.com/jnunemaker/httparty/pull/464)
* [optional raising exception on certain status codes](https://github.com/jnunemaker/httparty/pull/455)

Fixed

* [allow empty array to be used as param](https://github.com/jnunemaker/httparty/pull/477)
* [stop mutating cookie hash](https://github.com/jnunemaker/httparty/pull/460)

## 0.13.7 aka "party not as hard"
* remove post install emoji as it caused installation issues for some people

## 0.13.6
* avoid calling String#strip on invalid Strings
* preserve request method on 307 and 308 redirects
* output version with --version for command line bin
* maintain head request method across redirects by default
* add support for RFC2617 MD5-sess algorithm type
* add party popper emoji to post install message

## 0.13.5
* allow setting a custom URI adapter

## 0.13.4
* correct redirect url for redirect paths without leading slash
* remove core_extensions.rb as backwards compat for ruby 1.8 not needed
* replace URI.encode with ERB::Util.url_encode
* allow the response to be tapped

## 0.13.3
* minor improvement
  * added option to allow for streaming large files without loading them into memory (672cdae)

## 0.13.2
* minor improvement
  * [Set correct path on redirect to filename](https://github.com/jnunemaker/httparty/pull/337)
  * ensure logger works with curl format

## 0.13.1 2014-04-08
* new
  * [Added ability to specify a body_stream in HttpRequest](https://github.com/jnunemaker/httparty/pull/275)
  * [Added read_timeout and open_timeout options](https://github.com/jnunemaker/httparty/pull/278)
* change
  * [Initialize HTTParty requests with an URI object and a String](https://github.com/jnunemaker/httparty/pull/274)
* minor improvement
  * [Add stackexchange API example](https://github.com/jnunemaker/httparty/pull/280)

## 0.13.0 2014-02-14
* new
  * [Add CSV support](https://github.com/jnunemaker/httparty/pull/269)
  * [Allows PKCS12 client certificates](https://github.com/jnunemaker/httparty/pull/246)
* bug fix
  * [Digest auth no longer fails when multiple headers are sent by the server](https://github.com/jnunemaker/httparty/pull/272)
  * [Use 'Basement.copy' when calling 'HTTParty.copy'](https://github.com/jnunemaker/httparty/pull/268)
  * [No longer appends ampersand when queries are embedded in paths](https://github.com/jnunemaker/httparty/pull/252)
* change
  * [Merge - instead of overwrite - default headers with request provided headers](https://github.com/jnunemaker/httparty/pull/270)
  * [Modernize respond_to implementations to support second param](https://github.com/jnunemaker/httparty/pull/264)
  * [Sort query parameters by key before processing](https://github.com/jnunemaker/httparty/pull/245)
* minor improvement
  * [Add HTTParty::Error base class](https://github.com/jnunemaker/httparty/pull/260)

## 0.12.0 2013-10-10
* new
  * [Added initial logging support](https://github.com/jnunemaker/httparty/pull/243)
  * [Add support for local host and port binding](https://github.com/jnunemaker/httparty/pull/238)
  * [content_type_charset_support](https://github.com/jnunemaker/httparty/commit/82e351f0904e8ecc856015ff2854698a2ca47fbc)
* bug fix
  * [No longer attempt to decompress the body on HEAD requests](https://github.com/jnunemaker/httparty/commit/f2b8cc3d49e0e9363d7054b14f30c340d7b8e7f1)
  * [Adding java check in aliasing of multiple choices](https://github.com/jnunemaker/httparty/pull/204/commits)
* change
  * [MIME-type files of javascript are returned as a string instead of JSON](https://github.com/jnunemaker/httparty/pull/239)
  * [Made SSL connections use the system certificate store by default](https://github.com/jnunemaker/httparty/pull/226)
  * [Do not pass proxy options to Net::HTTP connection if not specified](https://github.com/jnunemaker/httparty/pull/222)
  * [Replace multi_json with stdlib json](https://github.com/jnunemaker/httparty/pull/214)
    * [Require Ruby >= 1.9.3]
  * [Response returns array of returned cookie strings](https://github.com/jnunemaker/httparty/pull/218)
    * [Allow '=' within value of a cookie]
* minor improvements
  * [Improve documentation of ssl_ca_file, ssl_ca_path](https://github.com/jnunemaker/httparty/pull/223)
  * [Fix example URLs](https://github.com/jnunemaker/httparty/pull/232)

## 0.11.0 2013-04-10
* new
  * [Add COPY http request handling](https://github.com/jnunemaker/httparty/pull/190)
  * [Ruby 2.0 tests](https://github.com/jnunemaker/httparty/pull/194)
    * [Ruby >= 2.0.0 support both multiple_choice? and multiple_choices?]
* bug fix
  * [Maintain blocks passed to 'perform' in redirects](https://github.com/jnunemaker/httparty/pull/191)
  * [Fixed nc value being quoted, this was against spec](https://github.com/jnunemaker/httparty/pull/196)
  * [Request#uri no longer duplicates non-relative-path params](https://github.com/jnunemaker/httparty/pull/189)
* change
  * [Client-side-only cookie attributes are removed: case-insensitive](https://github.com/jnunemaker/httparty/pull/188)

## 0.10.2 2013-01-26
* bug fix
  * [hash_conversions misnamed variable](https://github.com/jnunemaker/httparty/pull/187)

## 0.10.1 2013-01-26
* new
  * [Added support for MOVE requests](https://github.com/jnunemaker/httparty/pull/183)
  * [Bump multi xml version](https://github.com/jnunemaker/httparty/pull/181)

## 0.10.0 2013-01-10
* changes
  * removed yaml support because of security risk (see rails yaml issues)

## 0.9.0 2012-09-07
* new
  * [support for connection adapters](https://github.com/jnunemaker/httparty/pull/157)
  * [allow ssl_version on ruby 1.9](https://github.com/jnunemaker/httparty/pull/159)
* bug fixes
  * [don't treat port 4430 as ssl](https://github.com/jnunemaker/httparty/commit/a296b1c97f83d7dcc6ef85720a43664c265685ac)
  * [deep clone default options](https://github.com/jnunemaker/httparty/commit/f74227d30f9389b4b23a888c9af49fb9b8248e1f)
  * a few net digest auth fixes

## 0.8.3 2012-04-21
* new
  * [lazy parsing of responses](https://github.com/jnunemaker/httparty/commit/9fd5259c8dab00e426082b66af44ede2c9068f45)
  * [add support for PATCH requests](https://github.com/jnunemaker/httparty/commit/7ab6641e37a9e31517e46f6124f38c615395d38a)
* bug fixes
  * [subclasses no longer override superclass options](https://github.com/jnunemaker/httparty/commit/682af8fbf672e7b3009e650da776c85cdfe78d39)

## 0.8.2 2012-04-12
* new
  * add -r to make CLI return failure code if status >= 400
  * allow blank username from CLI
* bug fixes
  * return nil for null body
  * automatically deflate responses with a Content-Encoding: x-gzip header
  * Do not HEAD on POST request with digest authentication
  * add support for proxy authentication
  * fix posting data with CLI
  * require rexml/document if xml format from CLI
  * support for fragmented responses

## 0.8.1 2011-10-05
* bug fixes
  * content-encoding header should be removed when automatically inflating the body

## 0.8.0 2011-09-13
* new
  * switch to multi json/xml for parsing by default
* bug fixes
  * fix redirects to relative uri's

## 0.7.8 2011-06-06
* bug fix
  * Make response honor respond to
  * net http timeout can also be a float

## 0.7.7 2011-04-16
* bug fix
  * Fix NoMethodError when using the NON_RAILS_QUERY_STRING_NORMALIZER with a hash whose key is a symbol and value is nil

## 0.7.5 2011-04-16
* bug fix
  * caused issue with latest rubygems

## 0.7.4 2011-02-13
* bug fixes
  * Set VERIFY_NONE when using https. Ruby 1.9.2 no longer sets this for us. gh-67

## 0.7.3 2011-01-20
* bug fixes
  * Fix digest auth for unspecified quality of protection (bjoernalbers, mtrudel, dwo)

## 0.7.2 2011-01-20
* bug fixes
  * Fix gem dependencies

## 0.7.1 2011-01-19
* bug fixes
  * Fix uninitialized constant HTTParty::Response::Net in 1.9.2 (cap10morgan)
  * Other fixes for 1.9.2, full suite still fails (cap10morgan)

## 0.7.0 2011-01-18
* minor enhancements
  * Added query methods for HTTP status codes, i.e. response.success?
    response.created? (thanks citizenparker)
  * Added support for ssl_ca_file and ssl_ca_path (dlitz)
  * Allow custom query string normalization. gh-8
  * Unlock private keys with password (freerange)
  * Added high level request documentation (phildarnowsky)
  * Added basic post example (pbuckley)
  * Response object has access to its corresponding request object
  * Added example of siginin into tripit.com
  * Added option to follow redirects (rkj). gh-56
* bug fixes
  * Fixed superclass mismatch exception while running tests
    (thanks dlitz http://github.com/dlitz/httparty/commit/48224f0615b32133afcff4718ad426df7a4b401b)

## 0.6.1 2010-07-07
* minor enhancements
  * updated to crack 0.1.8
* bug fixes
  * subclasses always merge into the parent's default_options and
  default_cookies (l4rk).
  * subclasses play nicely with grand parents. gh-49

## 0.6.0 2010-06-13
* major enhancements
  * Digest Auth (bartiaco, sbecker, gilles, and aaronrussell)
  * Maintain HTTP method across redirects (bartiaco and sbecker)
  * HTTParty::Response#response returns the Net::HTTPResponse object
  * HTTParty::Response#headers returns a HTTParty::Response::Headers object
    which quacks like a Hash + Net::HTTPHeader. The #headers method continues
    to be backwards-compatible with the old Hash return value but may become
    deprecated in the future.

* minor enhancements
  * Update crack requirement to version 0.1.7
    You may still get a warning because Crack's version constant is out of date
  * Timeout option can be set for all requests using HTTParty.default_timeout (taazza)
  * Closed #38 "headers hash should downcase keys so canonical header name can be used"
  * Closed #40 "Gzip response" wherein gziped and deflated responses are
    automatically inflated. (carsonmcdonald)

## 0.5.2 2010-01-31
* minor enhancements
  * Update crack requirement to version 0.1.6

## 0.5.1 2010-01-30
* bug fixes
  * Handle 304 response correctly by returning the HTTParty::Response object instead of redirecting (seth and hellvinz)
  * Only redirect 300 responses if the header contains a Location
  * Don't append empty query strings to the uri. Closes #31
  * When no_follow is enabled, only raise the RedirectionTooDeep exception when a response tries redirecting. Closes #28

* major enhancements
  * Removed rubygems dependency. I suggest adding rubygems to RUBYOPT if this causes problems for you.
    $ export RUBYOPT='rubygems'
  * HTTParty#debug_output prints debugging information for the current request (iwarshak)
  * HTTParty#no_follow now available as a class-level option. Sets whether or not to follow redirects.

* minor enhancements
  * HTTParty::VERSION now available
  * Update crack requirement to version 0.1.5

## 0.5.0 2009-12-07
* bug fixes
  * inheritable attributes no longer mutable by subclasses (yyyc514)
  * namespace BasicObject within HTTParty to avoid class name collisions (eric)

* major enhancements
  * Custom Parsers via class or proc
  * Deprecation warning on HTTParty::AllowedFormats
    moved to HTTParty::Parser::SupportedFormats

* minor enhancements
  * Curl inspired output when using the binary in verbose mode (alexvollmer)
  * raise UnsupportedURIScheme when scheme is not HTTP or HTTPS (djspinmonkey)
  * Allow SSL for ports other than 443 when scheme is HTTPS (stefankroes)
  * Accept PEM certificates via HTTParty#pem (chrislo)
  * Support HEAD and OPTION verbs (grempe)
  * Verify SSL certificates when providing a PEM file (collectiveidea/danielmorrison)

## 0.4.5 2009-09-12
* bug fixes
  * Fixed class-level headers overwritten by cookie management code. Closes #19
  * Fixed "superclass mismatch for class BlankSlate" error. Closes #20
  * Fixed reading files as post data from the command line (vesan)

* minor enhancements
  * Timeout option added; will raise a Timeout::Error after the timeout has elapsed (attack). Closes #17
    HTTParty.get "http://github.com", timeout: 1
  * Building gem with Jeweler

## 0.4.4 2009-07-19
* 2 minor update
  * :query no longer sets form data. Use body and set content type to application/x-www-form-urlencoded if you need it. :query was wrong for that.
  * Fixed a bug in the cookies class method that caused cookies to be forgotten after the first request.
  * Also, some general cleanup of tests and such.

## 0.4.3 2009-04-23
* 1 minor update
  * added message to the response object

## 0.4.2 2009-03-30
* 2 minor changes
  * response code now returns an integer instead of a string (jqr)
  * rubyforge project setup for crack so i'm now depending on that instead of jnunemaker-crack

## 0.4.1 2009-03-29
* 1 minor fix
  * gem 'jnunemaker-crack' instead of gem 'crack'

## 0.4.0 2009-03-29
* 1 minor change
  * Switched xml and json parsing to crack (same code as before just moved to gem for easier reuse in other projects)

## 0.3.1 2009-02-10
* 1 minor fix, 1 minor enhancement
  * Fixed unescaping umlauts (siebertm)
  * Added yaml response parsing (Miha Filej)

## 0.3.0 2009-01-31
* 1 major enhancement, 1 bug fix
  * JSON gem no longer a requirement. It was conflicting with rails json stuff so I just stole ActiveSupport's json decoding and bundled it with HTTParty.
  * Fixed bug where query strings were being duplicated on redirects
  * Added a bunch of specs and moved some code around.

## 0.2.10 2009-01-29
* 1 minor enhancement
  * Made encoding on query parameters treat everything except URI::PATTERN::UNRESERVED as UNSAFE to force encoding of '+' character (Julian Russell)

## 0.2.9 2009-01-29
* 3 minor enhancements
  * Added a 'headers' accessor to the response with a hash of any HTTP headers. (Don Peterson)
  * Add support for a ":cookies" option to be used at the class level, or as an option on any individual call.  It should be passed a hash, which will be converted to the proper format and added to the request headers when the call is made. (Don Peterson)
  * Refactored several specs and added a full suite of cucumber features (Don Peterson)

## 0.2.8 2009-01-28
* 1 major fix
  * fixed major bug with response where it wouldn't iterate or really work at all with parsed responses

## 0.2.7 2009-01-28
* 2 minor fixes, 2 minor enhancements, 2 major enhancements
  * fixed undefined method add_node for nil class error that occasionally happened (juliocesar)
  * Handle nil or unexpected values better when typecasting. (Brian Landau)
  * More robust handling of mime types (Alex Vollmer)
  * Fixed support for specifying headers and added support for basic auth to CLI. (Alex Vollmer)
  * Added first class response object that includes original body and status code (Alex Vollmer)
  * Now parsing all response types as some non-200 responses provide important information, this means no more exception raising (Alex Vollmer)

## 0.2.6 2009-01-05
* 1 minor bug fix
  * added explicit require of time as Time#parse failed outside of rails (willcodeforfoo)

## 0.2.5 2009-01-05
* 1 major enhancement
  * Add command line interface to HTTParty (Alex Vollmer)

## 0.2.4 2008-12-23
* 1 bug fix
  * Fixed that mimetype detection was failing if no mimetype was returned from service (skippy)
## 0.2.3 2008-12-23
* 1 bug fix
  * Fixed typecasting class variable naming issue

## 0.2.2 2008-12-08
* 1 bug fix
  * Added the missing core extension hash method to_xml_attributes

## 0.2.1 2008-12-08
* 1 bug fix
  * Fixed that HTTParty was borking ActiveSupport and as such Rails (thanks to Rob Sanheim)

## 0.2.0 2008-12-07
* 1 major enhancement
  * Removed ActiveSupport as a dependency. Now requires json gem for json deserialization and uses an included class to do the xml parsing.

## 0.1.8 2008-11-30
* 3 major enhancements
  * Moved base_uri normalization into request class and out of httparty module, fixing
    the problem where base_uri was not always being normalized.
  * Stupid simple support for HTTParty.get/post/put/delete. (jqr)
  * Switched gem management to Echoe from newgem.

## 0.1.7 2008-11-30
* 1 major enhancement
  * fixed multiple class definitions overriding each others options

## 0.1.6 2008-11-26
* 1 major enhancement
  * now passing :query to set_form_data if post request to avoid content length errors

## 0.1.5 2008-11-14
* 2 major enhancements
  * Refactored send request method out into its own object.
  * Added :html format if you just want to do that.

## 0.1.4 2008-11-08
* 3 major enhancements:
  * Removed some cruft
  * Added ability to follow redirects automatically and turn that off (Alex Vollmer)

## 0.1.3 2008-08-22

* 3 major enhancements:
  * Added http_proxy key for setting proxy server and port (francxk@gmail.com)
  * Now raises exception when http error occurs (francxk@gmail.com)
  * Changed auto format detection from file extension to response content type (Jay Pignata)

## 0.1.2 2008-08-09

* 1 major enhancement:
  * default_params were not being appended to query string if option[:query] was blank

## 0.1.1 2008-07-30

* 2 major enhancement:
  * Added :basic_auth key for options when making a request
  * :query and :body both now work with query string or hash

## 0.1.0 2008-07-27

* 1 major enhancement:
  * Initial release
