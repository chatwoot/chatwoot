WebMock
=======
[![Gem Version](https://badge.fury.io/rb/webmock.svg)](http://badge.fury.io/rb/webmock)
[![Build Status](https://github.com/bblimke/webmock/actions/workflows/CI.yml/badge.svg?branch=master)](https://github.com/bblimke/webmock/actions)
[![Code Climate](https://codeclimate.com/github/bblimke/webmock/badges/gpa.svg)](https://codeclimate.com/github/bblimke/webmock)
[![Mentioned in Awesome Ruby](https://awesome.re/mentioned-badge.svg)](https://github.com/markets/awesome-ruby)

Library for stubbing and setting expectations on HTTP requests in Ruby.

Features
--------

* Stubbing HTTP requests at low http client lib level (no need to change tests when you change HTTP library)
* Setting and verifying expectations on HTTP requests
* Matching requests based on method, URI, headers and body
* Smart matching of the same URIs in different representations (also encoded and non encoded forms)
* Smart matching of the same headers in different representations.
* Support for Test::Unit
* Support for RSpec
* Support for MiniTest

Supported HTTP libraries
------------------------

* [Async::HTTP::Client](https://github.com/socketry/async-http)
* [Curb](https://github.com/taf2/curb) (currently only Curb::Easy)
* [EM-HTTP-Request](https://github.com/igrigorik/em-http-request)
* [Excon](https://github.com/excon/excon)
* [HTTPClient](https://github.com/nahi/httpclient)
* [HTTP Gem (also known as http.rb)](https://github.com/httprb/http)
* [httpx](https://honeyryderchuck.gitlab.io/httpx/wiki/Webmock-Adapter)
* [Manticore](https://github.com/cheald/manticore)
* [Net::HTTP](https://ruby-doc.org/stdlib-2.7.0/libdoc/net/http/rdoc/Net/HTTP.html) and other libraries based on Net::HTTP, e.g.:
  * [HTTParty](https://github.com/jnunemaker/httparty)
  * [REST Client](https://github.com/rest-client/rest-client)
* [Patron](https://github.com/toland/patron)
* [Typhoeus](https://github.com/typhoeus/typhoeus) (currently only Typhoeus::Hydra)

Supported Ruby Interpreters
---------------------------
* MRI 2.6
* MRI 2.7
* MRI 3.0
* MRI 3.1
* MRI 3.2
* MRI 3.3
* JRuby

## Installation

```bash
gem install webmock
```
or alternatively:

```ruby
# add to your Gemfile
group :test do
  gem "webmock"
end
```

### or to install the latest development version from github master

```bash
git clone http://github.com/bblimke/webmock.git
cd webmock
rake install
```

## Upgrading from v1.x to v2.x

WebMock 2.x has changed somewhat since version 1.x. Changes are listed in [CHANGELOG.md](CHANGELOG.md)

### Cucumber

Create a file `features/support/webmock.rb` with the following contents:

```ruby
require 'webmock/cucumber'
```

### MiniTest

Add the following code to `test/test_helper`:

```ruby
require 'webmock/minitest'
```

### RSpec

Add the following code to `spec/spec_helper`:

```ruby
require 'webmock/rspec'
```

### Test::Unit

Add the following code to `test/test_helper.rb`

```ruby
require 'webmock/test_unit'
```

### Outside a test framework

You can also use WebMock outside a test framework:

```ruby
require 'webmock'
include WebMock::API

WebMock.enable!
```

# Examples

## Stubbing

### Stubbed request based on uri only and with the default response

```ruby
stub_request(:any, "www.example.com")

Net::HTTP.get("www.example.com", "/")    # ===> Success
```

### Stubbing requests based on method, uri, body and headers

```ruby
stub_request(:post, "www.example.com").
  with(body: "abc", headers: { 'Content-Length' => 3 })

uri = URI.parse("http://www.example.com/")
req = Net::HTTP::Post.new(uri.path)
req['Content-Length'] = 3

res = Net::HTTP.start(uri.host, uri.port) do |http|
  http.request(req, "abc")
end    # ===> Success
```

### Matching request body and headers against regular expressions

```ruby
stub_request(:post, "www.example.com").
  with(body: /world$/, headers: {"Content-Type" => /image\/.+/}).
  to_return(body: "abc")

uri = URI.parse('http://www.example.com/')
req = Net::HTTP::Post.new(uri.path)
req['Content-Type'] = 'image/png'

res = Net::HTTP.start(uri.host, uri.port) do |http|
  http.request(req, 'hello world')
end    # ===> Success
```

### Matching request body against a hash. Body can be URL-Encoded, JSON or XML.

```ruby
stub_request(:post, "www.example.com").
  with(body: {data: {a: '1', b: 'five'}})

RestClient.post('www.example.com', "data[a]=1&data[b]=five",
  content_type: 'application/x-www-form-urlencoded')    # ===> Success

RestClient.post('www.example.com', '{"data":{"a":"1","b":"five"}}',
  content_type: 'application/json')    # ===> Success

RestClient.post('www.example.com', '<data a="1" b="five" />',
  content_type: 'application/xml')    # ===> Success
```

### Matching request body against partial hash.

```ruby
stub_request(:post, "www.example.com").
  with(body: hash_including({data: {a: '1', b: 'five'}}))

RestClient.post('www.example.com', "data[a]=1&data[b]=five&x=1",
:content_type => 'application/x-www-form-urlencoded')    # ===> Success
```

### Matching custom request headers

```ruby
stub_request(:any, "www.example.com").
  with(headers:{ 'Header-Name' => 'Header-Value' })

uri = URI.parse('http://www.example.com/')
req = Net::HTTP::Post.new(uri.path)
req['Header-Name'] = 'Header-Value'

res = Net::HTTP.start(uri.host, uri.port) do |http|
  http.request(req, 'abc')
end    # ===> Success
```

### Matching multiple headers with the same name

```ruby
stub_request(:get, 'www.example.com').
  with(headers: {'Accept' => ['image/jpeg', 'image/png'] })

req = Net::HTTP::Get.new("/")
req['Accept'] = ['image/png']
req.add_field('Accept', 'image/jpeg')
Net::HTTP.start("www.example.com") {|http| http.request(req) }    # ===> Success
```

### Matching requests against provided block

```ruby
stub_request(:post, "www.example.com").with { |request| request.body == "abc" }
RestClient.post('www.example.com', 'abc')    # ===> Success
```

### Request with basic authentication header

```ruby
stub_request(:get, "www.example.com").with(basic_auth: ['user', 'pass'])
# or
# stub_request(:get, "www.example.com").
#   with(headers: {'Authorization' => "Basic #{ Base64.strict_encode64('user:pass').chomp}"})

Net::HTTP.start('www.example.com') do |http|
  req = Net::HTTP::Get.new('/')
  req.basic_auth 'user', 'pass'
  http.request(req)
end    # ===> Success
```

##### Important! Since version 2.0.0, WebMock does not match credentials provided in Authorization header and credentials provided in the userinfo of a url. I.e. `stub_request(:get, "user:pass@www.example.com")` does not match a request with credentials provided in the Authorization header.

### Request with basic authentication in the url

```ruby
stub_request(:get, "user:pass@www.example.com")

RestClient.get('user:pass@www.example.com')    # ===> Success
```

### Matching uris using regular expressions

```ruby
stub_request(:any, /example/)

Net::HTTP.get('www.example.com', '/')    # ===> Success
```

### Matching uris using lambda

```ruby
stub_request(:any, ->(uri) { true })
```

### Matching uris using RFC 6570 - Basic Example

```ruby
uri_template = Addressable::Template.new "www.example.com/{id}/"
stub_request(:any, uri_template)

Net::HTTP.get('www.example.com', '/webmock/')    # ===> Success
```

### Matching uris using RFC 6570 - Advanced Example

```ruby
uri_template =
  Addressable::Template.new "www.example.com/thing/{id}.json{?x,y,z}{&other*}"
stub_request(:any, uri_template)

Net::HTTP.get('www.example.com',
  '/thing/5.json?x=1&y=2&z=3&anyParam=4')    # ===> Success
```

### Matching query params using hash

```ruby
stub_request(:get, "www.example.com").with(query: {"a" => ["b", "c"]})

RestClient.get("http://www.example.com/?a[]=b&a[]=c")    # ===> Success
```

### Matching partial query params using hash

```ruby
stub_request(:get, "www.example.com").
  with(query: hash_including({"a" => ["b", "c"]}))

RestClient.get("http://www.example.com/?a[]=b&a[]=c&x=1")    # ===> Success
```

### Matching partial query params using hash_excluding

```ruby
stub_request(:get, "www.example.com").
  with(query: hash_excluding({"a" => "b"}))

RestClient.get("http://www.example.com/?a=b")    # ===> Failure
RestClient.get("http://www.example.com/?a=c")    # ===> Success
```

### Stubbing with custom response

```ruby
stub_request(:any, "www.example.com").
  to_return(body: "abc", status: 200,
    headers: { 'Content-Length' => 3 })

Net::HTTP.get("www.example.com", '/')    # ===> "abc"
```

Set appropriate Content-Type for HTTParty's `parsed_response`.

```ruby
stub_request(:any, "www.example.com").to_return body: '{}', headers: {content_type: 'application/json'}
```

### Response with body specified as IO object

```ruby
File.open('/tmp/response_body.txt', 'w') { |f| f.puts 'abc' }

stub_request(:any, "www.example.com").
  to_return(body: File.new('/tmp/response_body.txt'), status: 200)

Net::HTTP.get('www.example.com', '/')    # ===> "abc\n"
```

### Response with JSON body

```ruby

stub_request(:any, "www.example.com").
  to_return_json(body: {foo: "bar"})

Net::HTTP.get('www.example.com', '/') # ===> "{\"foo\": \"bar\"}"
```

### Response with custom status message

```ruby
stub_request(:any, "www.example.com").
  to_return(status: [500, "Internal Server Error"])

req = Net::HTTP::Get.new("/")
Net::HTTP.start("www.example.com") { |http| http.request(req) }.
  message    # ===> "Internal Server Error"
```

### Replaying raw responses recorded with `curl -is`

```
curl -is www.example.com > /tmp/example_curl_-is_output.txt
```

```ruby
raw_response_file = File.new("/tmp/example_curl_-is_output.txt")
```

   from file

```ruby
stub_request(:get, "www.example.com").to_return(raw_response_file)
```

   or string

```ruby
stub_request(:get, "www.example.com").to_return(raw_response_file.read)
```

### Responses dynamically evaluated from block

```ruby
stub_request(:any, 'www.example.net').
  to_return { |request| {body: request.body} }

RestClient.post('www.example.net', 'abc')    # ===> "abc\n"
```

### Responses dynamically evaluated from lambda

```ruby
stub_request(:any, 'www.example.net').
  to_return(lambda { |request| {body: request.body} })

RestClient.post('www.example.net', 'abc')    # ===> "abc\n"
```

### Dynamically evaluated raw responses recorded with `curl -is`

`curl -is www.example.com > /tmp/www.example.com.txt`

```ruby
stub_request(:get, "www.example.com").
  to_return(lambda { |request| File.new("/tmp/#{request.uri.host.to_s}.txt") })
```

### Responses with dynamically evaluated parts

```ruby
stub_request(:any, 'www.example.net').
  to_return(body: lambda { |request| request.body })

RestClient.post('www.example.net', 'abc')    # ===> "abc\n"
```

### Rack responses

```ruby
class MyRackApp
  def self.call(env)
    [200, {}, ["Hello"]]
  end
end

stub_request(:get, "www.example.com").to_rack(MyRackApp)

RestClient.post('www.example.com')    # ===> "Hello"
```

### Raising errors

#### Exception declared by class

```ruby
stub_request(:any, 'www.example.net').to_raise(StandardError)

RestClient.post('www.example.net', 'abc')    # ===> StandardError
```

#### or by exception instance

```ruby
stub_request(:any, 'www.example.net').to_raise(StandardError.new("some error"))
```

#### or by string

```ruby
stub_request(:any, 'www.example.net').to_raise("some error")
```

### Raising timeout errors

```ruby
stub_request(:any, 'www.example.net').to_timeout

RestClient.post('www.example.net', 'abc')    # ===> RestClient::RequestTimeout
```

### Multiple responses for repeated requests

```ruby
stub_request(:get, "www.example.com").
  to_return({body: "abc"}, {body: "def"})
Net::HTTP.get('www.example.com', '/')    # ===> "abc\n"
Net::HTTP.get('www.example.com', '/')    # ===> "def\n"

#after all responses are used the last response will be returned infinitely

Net::HTTP.get('www.example.com', '/')    # ===> "def\n"
```

### Multiple responses using chained `to_return()`, `to_raise()` or `to_timeout` declarations

```ruby
stub_request(:get, "www.example.com").
  to_return({body: "abc"}).then.  #then() is just a syntactic sugar
  to_return({body: "def"}).then.
  to_raise(MyException)

Net::HTTP.get('www.example.com', '/')    # ===> "abc\n"
Net::HTTP.get('www.example.com', '/')    # ===> "def\n"
Net::HTTP.get('www.example.com', '/')    # ===> MyException raised
```

### Specifying number of times given response should be returned

```ruby
stub_request(:get, "www.example.com").
  to_return({body: "abc"}).times(2).then.
  to_return({body: "def"})

Net::HTTP.get('www.example.com', '/')    # ===> "abc\n"
Net::HTTP.get('www.example.com', '/')    # ===> "abc\n"
Net::HTTP.get('www.example.com', '/')    # ===> "def\n"
```

### Removing unused stubs

```ruby
stub_get = stub_request(:get, "www.example.com")
remove_request_stub(stub_get)
```

### Real requests to network can be allowed or disabled

```ruby
WebMock.allow_net_connect!

stub_request(:any, "www.example.com").to_return(body: "abc")

Net::HTTP.get('www.example.com', '/')    # ===> "abc"

Net::HTTP.get('www.something.com', '/')    # ===> /.+Something.+/

WebMock.disable_net_connect!

Net::HTTP.get('www.something.com', '/')    # ===> Failure
```

### External requests can be disabled while allowing localhost

```ruby
WebMock.disable_net_connect!(allow_localhost: true)

Net::HTTP.get('www.something.com', '/')    # ===> Failure

Net::HTTP.get('localhost:9887', '/')    # ===> Allowed. Perhaps to Selenium?
```

### External requests can be disabled while allowing specific requests

Allowed requests can be specified in a number of ways.

With a `String` specifying a host name:

```ruby
WebMock.disable_net_connect!(allow: 'www.example.org')

RestClient.get('www.something.com', '/')    # ===> Failure
RestClient.get('www.example.org', '/')      # ===> Allowed
RestClient.get('www.example.org:8080', '/') # ===> Allowed
```

With a `String` specifying a host name and a port:

```ruby
WebMock.disable_net_connect!(allow: 'www.example.org:8080')

RestClient.get('www.something.com', '/')    # ===> Failure
RestClient.get('www.example.org', '/')      # ===> Failure
RestClient.get('www.example.org:8080', '/') # ===> Allowed
```

With a `Regexp` matching the URI:

```ruby
WebMock.disable_net_connect!(allow: %r{ample\.org/foo})

RestClient.get('www.example.org', '/foo/bar') # ===> Allowed
RestClient.get('sample.org', '/foo')          # ===> Allowed
RestClient.get('sample.org', '/bar')          # ===> Failure
```

With an object that responds to `#call`, receiving a `URI` object and returning a boolean:

```ruby
denylist = ['google.com', 'facebook.com', 'apple.com']
allowed_sites = lambda{|uri|
  denylist.none?{|site| uri.host.include?(site) }
}
WebMock.disable_net_connect!(allow: allowed_sites)

RestClient.get('www.example.org', '/')  # ===> Allowed
RestClient.get('www.facebook.com', '/') # ===> Failure
RestClient.get('apple.com', '/')        # ===> Failure
```

With an `Array` of any of the above:

```ruby
WebMock.disable_net_connect!(allow: [
  lambda{|uri| uri.host.length % 2 == 0 },
  /ample.org/,
  'bbc.co.uk',
])

RestClient.get('www.example.org', '/') # ===> Allowed
RestClient.get('bbc.co.uk', '/')       # ===> Allowed
RestClient.get('bbc.com', '/')         # ===> Allowed
RestClient.get('www.bbc.com', '/')     # ===> Failure
```

## Connecting on Net::HTTP.start

HTTP protocol has 3 steps: connect, request and response (or 4 with close). Most Ruby HTTP client libraries
treat connect as a part of request step, with the exception of `Net::HTTP` which
allows opening connection to the server separately to the request, by using `Net::HTTP.start`.

WebMock API was also designed with connect being part of request step, and it only allows stubbing
requests, not connections. When `Net::HTTP.start` is called, WebMock doesn't know yet whether
a request is stubbed or not. WebMock by default delays a connection until the request is invoked,
so when there is no request, `Net::HTTP.start` doesn't do anything.
**This means that WebMock breaks the Net::HTTP behaviour by default!**

To workaround this issue, WebMock offers `:net_http_connect_on_start` option,
which can be passed to `WebMock.allow_net_connect!` and `WebMock.disable_net_connect!` methods, i.e.

```ruby
WebMock.allow_net_connect!(net_http_connect_on_start: true)
```

This forces WebMock Net::HTTP adapter to always connect on `Net::HTTP.start`. At the time of connection being made there is no information about the request or URL yet, therefore WebMock is not able to decide whether to stub a request or not and all connections are allowed. To enable connections only to a specific domain (e.g. your test server) use:

```ruby
WebMock.allow_net_connect!(net_http_connect_on_start: "www.example.com")
```

## Setting Expectations

### Setting expectations in Test::Unit

```ruby
require 'webmock/test_unit'

stub_request(:any, "www.example.com")

uri = URI.parse('http://www.example.com/')
req = Net::HTTP::Post.new(uri.path)
req['Content-Length'] = 3

res = Net::HTTP.start(uri.host, uri.port) do |http|
  http.request(req, 'abc')
end

assert_requested :post, "http://www.example.com",
  headers: {'Content-Length' => 3}, body: "abc",
  times: 1    # ===> Success

assert_not_requested :get, "http://www.something.com"    # ===> Success

assert_requested(:post, "http://www.example.com",
  times: 1) { |req| req.body == "abc" }
```

### Expecting real (not stubbed) requests

```ruby
WebMock.allow_net_connect!

Net::HTTP.get('www.example.com', '/')    # ===> Success

assert_requested :get, "http://www.example.com"    # ===> Success
```

### Setting expectations in Test::Unit on the stub

```ruby
stub_get = stub_request(:get, "www.example.com")
stub_post = stub_request(:post, "www.example.com")

Net::HTTP.get('www.example.com', '/')

assert_requested(stub_get)
assert_not_requested(stub_post)
```


### Setting expectations in RSpec on `WebMock` module
 This style is borrowed from [fakeweb-matcher](http://github.com/pat/fakeweb-matcher)

```ruby
require 'webmock/rspec'

expect(WebMock).to have_requested(:get, "www.example.com").
  with(body: "abc", headers: {'Content-Length' => 3}).twice

expect(WebMock).not_to have_requested(:get, "www.something.com")

expect(WebMock).to have_requested(:post, "www.example.com").
  with { |req| req.body == "abc" }
# Note that the block with `do ... end` instead of curly brackets won't work!
# Why? See this comment https://github.com/bblimke/webmock/issues/174#issuecomment-34908908

expect(WebMock).to have_requested(:get, "www.example.com").
  with(query: {"a" => ["b", "c"]})

expect(WebMock).to have_requested(:get, "www.example.com").
  with(query: hash_including({"a" => ["b", "c"]}))

expect(WebMock).to have_requested(:get, "www.example.com").
  with(body: {"a" => ["b", "c"]},
    headers: {'Content-Type' => 'application/json'})
```

### Setting expectations in RSpec with `a_request`

```ruby
expect(a_request(:post, "www.example.com").
  with(body: "abc", headers: {'Content-Length' => 3})).
  to have_been_made.once

expect(a_request(:post, "www.something.com")).to have_been_made.times(3)

expect(a_request(:post, "www.something.com")).to have_been_made.at_least_once

expect(a_request(:post, "www.something.com")).
  to have_been_made.at_least_times(3)

expect(a_request(:post, "www.something.com")).to have_been_made.at_most_twice

expect(a_request(:post, "www.something.com")).to have_been_made.at_most_times(3)

expect(a_request(:any, "www.example.com")).not_to have_been_made

expect(a_request(:post, "www.example.com").with { |req| req.body == "abc" }).
  to have_been_made

expect(a_request(:get, "www.example.com").with(query: {"a" => ["b", "c"]})).
  to have_been_made

expect(a_request(:get, "www.example.com").
  with(query: hash_including({"a" => ["b", "c"]}))).to have_been_made

expect(a_request(:post, "www.example.com").
  with(body: {"a" => ["b", "c"]},
    headers: {'Content-Type' => 'application/json'})).to have_been_made
```

### Setting expectations in RSpec on the stub

```ruby
stub = stub_request(:get, "www.example.com")
# ... make requests ...
expect(stub).to have_been_requested
```

## Clearing stubs and request history

If you want to reset all current stubs and history of requests use `WebMock.reset!`

```ruby
stub_request(:any, "www.example.com")

Net::HTTP.get('www.example.com', '/')    # ===> Success

WebMock.reset!

Net::HTTP.get('www.example.com', '/')    # ===> Failure

assert_not_requested :get, "www.example.com"    # ===> Success
```

## Clearing request counters

If you want to reset **only** the counters of the executed requests use `WebMock.reset_executed_requests!`

```ruby
stub  = stub_request(:get, "www.example.com")
stub2 = stub_request(:get, "www.example2.com")

Net::HTTP.get('www.example.com', '/')
Net::HTTP.get('www.example.com', '/')

Net::HTTP.get('www.example2.com', '/')

expect(stub).to have_been_requested.times(2)
expect(stub2).to have_been_requested.times(1)

WebMock.reset_executed_requests!

expect(stub).not_to have_been_requested
expect(stub2).not_to have_been_requested
```

## Disabling and enabling WebMock or only some http client adapters

```ruby
# Disable WebMock (all adapters)
WebMock.disable!

# Disable WebMock for all libs except Net::HTTP
WebMock.disable!(except: [:net_http])

# Enable WebMock (all adapters)
WebMock.enable!

# Enable WebMock for all libs except Patron
WebMock.enable!(except: [:patron])
```

## Matching requests

An executed request matches stubbed request if it passes following criteria:

- When request URI matches stubbed request URI string, Regexp pattern or RFC 6570 URI Template
- And request method is the same as stubbed request method or stubbed request method is :any
- And request body is the same as stubbed request body or stubbed request body is not specified
- And request headers match stubbed request headers, or stubbed request headers match a subset of request headers, or stubbed request headers are not specified
- And request matches provided block or block is not provided

## Precedence of stubs

Always the last declared stub matching the request will be applied i.e:

```ruby
stub_request(:get, "www.example.com").to_return(body: "abc")
stub_request(:get, "www.example.com").to_return(body: "def")

Net::HTTP.get('www.example.com', '/')    # ====> "def"
```

## Matching URIs

WebMock will match all different representations of the same URI.

I.e all the following representations of the URI are equal:

```ruby
"www.example.com"
"www.example.com/"
"www.example.com:80"
"www.example.com:80/"
"http://www.example.com"
"http://www.example.com/"
"http://www.example.com:80"
"http://www.example.com:80/"
```

The following URIs with userinfo are also equal for WebMock

```ruby
"a b:pass@www.example.com"
"a b:pass@www.example.com/"
"a b:pass@www.example.com:80"
"a b:pass@www.example.com:80/"
"http://a b:pass@www.example.com"
"http://a b:pass@www.example.com/"
"http://a b:pass@www.example.com:80"
"http://a b:pass@www.example.com:80/"
"a%20b:pass@www.example.com"
"a%20b:pass@www.example.com/"
"a%20b:pass@www.example.com:80"
"a%20b:pass@www.example.com:80/"
"http://a%20b:pass@www.example.com"
"http://a%20b:pass@www.example.com/"
"http://a%20b:pass@www.example.com:80"
"http://a%20b:pass@www.example.com:80/"
```

or these

```ruby
"www.example.com/my path/?a=my param&b=c"
"www.example.com/my%20path/?a=my%20param&b=c"
"www.example.com:80/my path/?a=my param&b=c"
"www.example.com:80/my%20path/?a=my%20param&b=c"
"http://www.example.com/my path/?a=my param&b=c"
"http://www.example.com/my%20path/?a=my%20param&b=c"
"http://www.example.com:80/my path/?a=my param&b=c"
"http://www.example.com:80/my%20path/?a=my%20param&b=c"
```

If you provide Regexp to match URI, WebMock will try to match it against every valid form of the same url.

I.e `/my path/` will match `www.example.com/my%20path` because it is equivalent of `www.example.com/my path`

## Matching with URI Templates

If you use [Addressable::Template](https://github.com/sporkmonger/addressable#uri-templates) for matching, then WebMock will defer the matching rules to Addressable, which complies with [RFC 6570](http://tools.ietf.org/html/rfc6570).

If you use any of the WebMock methods for matching query params, then Addressable will be used to match the base URI and WebMock will match the query params.  If you do not, then WebMock will let Addressable match the full URI.

## Matching headers

WebMock will match request headers against stubbed request headers in the following situations:

1. Stubbed request has headers specified and request headers are the same as stubbed headers <br/>
i.e stubbed headers: `{ 'Header1' => 'Value1', 'Header2' => 'Value2' }`, requested: `{ 'Header1' => 'Value1', 'Header2' => 'Value2' }`

2. Stubbed request has headers specified and stubbed request headers are a subset of request headers <br/>
i.e stubbed headers: `{ 'Header1' => 'Value1'  }`, requested: `{ 'Header1' => 'Value1', 'Header2' => 'Value2' }`

3. Stubbed request has no headers <br/>
i.e stubbed headers: `nil`, requested: `{ 'Header1' => 'Value1', 'Header2' => 'Value2' }`

WebMock normalises headers and treats all forms of same headers as equal:
i.e the following two sets of headers are equal:

`{ "Header1" => "value1", content_length: 123, X_CuStOm_hEAder: :value }`

`{ header1: "value1",  "Content-Length" => 123, "x-cuSTOM-HeAder" => "value" }`

## Recording real requests and responses and replaying them later

To record your application's real HTTP interactions and replay them later in tests you can use [VCR](https://github.com/vcr/vcr) with WebMock.

## Request callbacks

#### WebMock can invoke callbacks stubbed or real requests:

```ruby
WebMock.after_request do |request_signature, response|
  puts "Request #{request_signature} was made and #{response} was returned"
end
```

#### invoke callbacks for real requests only and except requests made with Patron

```ruby
WebMock.after_request(except: [:patron],
                      real_requests_only: true) do |req_signature, response|
  puts "Request #{req_signature} was made and #{response} was returned"
end
```

## Bugs and Issues

Please submit them here [http://github.com/bblimke/webmock/issues](http://github.com/bblimke/webmock/issues)

## Issue triage [![Open Source Helpers](https://www.codetriage.com/bblimke/webmock/badges/users.svg)](https://www.codetriage.com/bblimke/webmock)

You can contribute by triaging issues which may include reproducing bug reports or asking for vital information, such as version numbers or reproduction instructions. If you would like to start triaging issues, one easy way to get started is to [subscribe to webmock on CodeTriage](https://www.codetriage.com/bblimke/webmock).

## Suggestions

If you have any suggestions on how to improve WebMock please send an email to the mailing list [groups.google.com/group/webmock-users](http://groups.google.com/group/webmock-users)

I'm particularly interested in how the DSL could be improved.

## Development

In order to work on Webmock you first need to fork and clone the repo.
Please do any work on a dedicated branch and rebase against master
before sending a pull request.

## Credits

The initial lines of this project were written during New Bamboo [Hack Day](http://blog.new-bamboo.co.uk/2009/11/13/hackday-results)
Thanks to my fellow [Bambinos](http://new-bamboo.co.uk/) for all the great suggestions!

People who submitted patches and new features or suggested improvements. Many thanks to these people:

* Ben Pickles
* Mark Evans
* Ivan Vega
* Piotr Usewicz
* Nick Plante
* Nick Quaranto
* Diego E. "Flameeyes" Pettenò
* Niels Meersschaert
* Mack Earnhardt
* Arvicco
* Sergio Gil
* Jeffrey Jones
* Tekin Suleyman
* Tom Ward
* Nadim Bitar
* Myron Marston
* Sam Phillips
* Jose Angel Cortinas
* Razic
* Steve Tooke
* Nathaniel Bibler
* Martyn Loughran
* Muness Alrubaie
* Charles Li
* Ryan Bigg
* Pete Higgins
* Hans de Graaff
* Alastair Brunton
* Sam Stokes
* Eugene Bolshakov
* James Conroy-Finn
* Salvador Fuentes Jr
* Alex Rothenberg
* Aidan Feldman
* Steve Hull
* Jay Adkisson
* Zach Dennis
* Nikita Fedyashev
* Lin Jen-Shin
* David Yeu
* Andreas Garnæs
* Roman Shterenzon
* Chris McGrath
* Stephen Celis
* Eugene Pimenov
* Albert Llop
* Christopher Pickslay
* Tammer Saleh
* Nicolas Fouché
* Joe Van Dyk
* Mark Abramov
* Frank Schumacher
* Dimitrij Denissenko
* Marnen Laibow-Koser
* Evgeniy Dolzhenko
* Nick Recobra
* Jordan Elver
* Joe Karayusuf
* Paul Cortens
* jugyo
* aindustries
* Eric Oestrich
* erwanlr
* Ben Bleything
* Jon Leighton
* Ryan Schlesinger
* Julien Boyer
* Kevin Glowacz
* Hans Hasselberg
* Andrew France
* Jonathan Hyman
* Rex Feng
* Pavel Forkert
* Jordi Massaguer Pla
* Jake Benilov
* Tom Beauvais
* Mokevnin Kirill
* Alex Grant
* Lucas Dohmen
* Bastien Vaucher
* Joost Baaij
* Joel Chippindale
* Murahashi Sanemat Kenichi
* Tim Kurvers
* Ilya Vassilevsky
* gotwalt
* Leif Bladt
* Alex Tomlins
* Mitsutaka Mimura
* Tomy Kaira
* Daniel van Hoesel
* Ian Asaff
* Ian Lesperance
* Matthew Horan
* Dmitry Gutov
* Florian Dütsch
* Manuel Meurer
* Brian D. Burns
* Riley Strong
* Tamir Duberstein
* Stefano Uliari
* Alex Stupakov
* Karen Wang
* Matt Burke
* Jon Rowe
* Aleksey V. Zapparov
* Praveen Arimbrathodiyil
* Bo Jeanes
* Matthew Conway
* Rob Olson
* Max Lincoln
* Oleg Gritsenko
* Hwan-Joon Choi
* SHIBATA Hiroshi
* Caleb Thompson
* Theo Hultberg
* Pablo Jairala
* Insoo Buzz Jung
* Carlos Alonso Pérez
* trlorenz
* Alexander Simonov
* Thorbjørn Hermanse
* Mark Lorenz
* tjsousa
* Tasos Stathopoulos
* Dan Buettner
* Sven Riedel
* Mark Lorenz
* Dávid Kovács
* fishermand46
* Franky Wahl
* ChaYoung You
* Simon Russell
* Steve Mitchell
* Mattias Putman
* Zachary Anker
* Emmanuel Sambo
* Ramon Tayag
* Johannes Schlumberger
* Siôn Le Roux
* Matt Palmer
* Zhao Wen
* Krzysztof Rygielski
* Magne Land
* yurivm
* Mike Knepper
* Charles Pence
* Alexey Zapparov
* Pablo Brasero
* Cedric Pimenta
* Michiel Karnebeek
* Alex Kestner
* Manfred Stienstra
* Tim Diggins
* Gabriel Chaney
* Chris Griego
* Taiki Ono
* Jonathan Schatz
* Jose Luis Honorato
* Aaron Kromer
* Pavel Jurašek
* Jake Worth
* Gabe Martin-Dempesy
* Michael Grosser
* Aleksei Maridashvili
* Ville Lautanala
* Koichi ITO
* Jordan Harband
* Tarmo Tänav
* Joe Marty
* Chris Thomson
* Vít Ondruch
* George Ulmer
* Christof Koenig
* Chung-Yi Chi
* Olexandr Hoshylyk
* Janko Marohnić
* Pat Allan
* Rick Song
* NARUSE, Yui
* Piotr Boniecki
* Olia Kremmyda
* Michał Matyas
* Matt Brictson
* Kenny Ortmann
* redbar0n
* Lukas Pokorny
* Arkadiy Tetelman
* Kazato Sugimoto
* Olle Jonsson
* Pavel Rosický
* Geremia Taglialatela
* Koichi Sasada
* Yusuke Endoh
* Grey Baker
* SoonKhen OwYong
* Pavel Valena
* Adam Sokolnicki
* Jeff Felchner
* Eike Send
* Claudio Poli
* Csaba Apagyi
* Frederick Cheung
* Fábio D. Batista
* Andriy Yanko
* y-yagi
* Rafael França
* George Claghorn
* Alex Junger
* Orien Madgwick
* Andrei Sidorov
* Marco Costa
* Ryan Davis
* Brandur
* Samuel Williams
* Patrik Ragnarsson
* Alex Coomans
* Vesa Laakso
* John Hawthorn
* guppy0356
* Thilo Rusche
* Andrew Stuntz
* Lucas Uyezu
* Bruno Sutic
* Ryan Kerr
* Adam Harwood
* Ben Koshy
* Jesse Bowes
* Marek Kasztelnik
* ce07c3
* Jun Jiang
* Oleksiy Kovyrin
* Matt Larraz
* Tony Schneider
* Niklas Hösl
* Johanna Hartmann
* Alex Vondrak
* Will Storey
* Eduardo Hernandez
* ojab
* Giorgio Gambino
* Timmitry
* Michael Fairley
* Ray Zane
* Go Sueyoshi
* Cedric Sohrauer
* Akira Matsuda
* Mark Spangler
* Henrik Nyh
* Yoann Lecuyer
* Lucas Arnaud
* Marc Rohloff
* inkstak
* Yuki Inoue
* Brandon Weaver
* Josh Nichols
* Ricardo Trindade
* Earlopain
* James Brown
* Kazuhiro NISHIYAMA
* Étienne Barrié
* Matt Brown
* Victor Maslov
* Gio Lodi
* Ryan Brooks
* Jacob Frautschi

For a full list of contributors you can visit the
[contributors](https://github.com/bblimke/webmock/contributors) page.

## Background

Thank you Fakeweb! This library was inspired by [FakeWeb](https://github.com/chrisk/fakeweb).
I imported some solutions from that project to WebMock. I also copied some code i.e Net:HTTP adapter.
Fakeweb architecture unfortunately didn't allow me to extend it easily with the features I needed.
I also preferred some things to work differently i.e request stub precedence.

## Copyright

Copyright (c) 2009-2010 Bartosz Blimke. See LICENSE for details.
