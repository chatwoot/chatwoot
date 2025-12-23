# twilio-ruby

[![Tests](https://github.com/twilio/twilio-ruby/actions/workflows/test-and-deploy.yml/badge.svg)][github-actions]
[![Gem Version](https://img.shields.io/gem/v/twilio-ruby.svg)](https://rubygems.org/gems/twilio-ruby)
[![Learn with TwilioQuest](https://img.shields.io/static/v1?label=TwilioQuest&message=Learn%20to%20contribute%21&color=F22F46&labelColor=1f243c&style=flat-square&logo=data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAIAAAACACAMAAAD04JH5AAAASFBMVEUAAAAZGRkcHBwjIyMoKCgAAABgYGBoaGiAgICMjIyzs7PJycnMzMzNzc3UoBfd3d3m5ubqrhfrMEDu7u739/f4vSb/3AD///9tbdyEAAAABXRSTlMAAAAAAMJrBrEAAAKoSURBVHgB7ZrRcuI6EESdyxXGYoNFvMD//+l2bSszRgyUYpFAsXOeiJGmj4NkuWx1Qeh+Ekl9DgEXOBwOx+Px5xyQhDykfgq4wG63MxxaR4ddIkg6Ul3g84vCIcjPBA5gmUMeXESrlukuoK33+33uID8TWeLAdOWsKpJYzwVMB7bOzYSGOciyUlXSn0/ABXTosJ1M1SbypZ4O4MbZuIDMU02PMbauhhHMHXbmebmALIiEbbbbbUrpF1gwE9kFfRNAJaP+FQEXCCTGyJ4ngDrjOFo3jEL5JdqjF/pueR4cCeCGgAtwmuRS6gDwaRiGvu+DMFwSBLTE3+jF8JyuV1okPZ+AC4hDFhCHyHQjdjPHUKFDlHSJkHQXMB3KpSwXNGJPcwwTdZiXlRN0gSp0zpWxNtM0beYE0nRH6QIbO7rawwXaBYz0j78gxjokDuv12gVeUuBD0MDi0OQCLvDaAho4juP1Q/jkAncXqIcCfd+7gAu4QLMACCLxpRsSuQh0igu0C9Svhi7weAGZg50L3IE3cai4IfkNZAC8dfdhsUD3CgKBVC9JE5ABAFzg4QL/taYPAAWrHdYcgfLaIgAXWJ7OV38n1LEF8tt2TH29E+QAoDoO5Ve/LtCQDmKM9kPbvCEBApK+IXzbcSJ0cIGF6e8gpcRhUDogWZ8JnaWjPXc/fNnBBUKRngiHgTUSivSzDRDgHZQOLvBQgf8rRt+VdBUUhwkU6VpJ+xcOwQUqZr+mR0kvBUgv6cB4+37hQAkXqE8PwGisGhJtN4xAHMzrsgvI7rccXqSvKh6jltGlrOHA3Xk1At3LC4QiPdX9/0ndHpGVvTjR4bZA1ypAKgVcwE5vx74ulwIugDt8e/X7JgfkucBMIAr26ndnB4UCLnDOqvteQsHlgX9N4A+c4cW3DXSPbwAAAABJRU5ErkJggg==)](https://twil.io/learn-open-source)

## Documentation

The documentation for the Twilio API can be found [here][apidocs].

The individual releases [here][refdocs].

## Versions

`twilio-ruby` uses a modified version of [Semantic Versioning](https://semver.org) for all changes. [See this document](VERSIONS.md) for details.

### Supported Ruby Versions

This library supports the following Ruby implementations:

* Ruby 2.4
* Ruby 2.5
* Ruby 2.6
* Ruby 2.7
* Ruby 3.0
* Ruby 3.1
* Ruby 3.2

* JRuby 9.2
* JRuby 9.3
* JRuby 9.4

### Migrating from 5.x

[Upgrade Guide][upgrade]

## Installation

To install using [Bundler][bundler] grab the latest stable version:

```ruby
gem 'twilio-ruby', '~> 7.6.0'
```

To manually install `twilio-ruby` via [Rubygems][rubygems] simply gem install:

```bash
gem install twilio-ruby -v 7.6.0
```

To build and install the development branch yourself from the latest source:

```bash
git clone git@github.com:twilio/twilio-ruby.git
cd twilio-ruby
make install
```

> **Info**
> If the command line gives you an error message that says Permission Denied, try running the above commands with sudo.
>
> For example: `sudo gem install twilio-ruby`

### Test your installation

To make sure the installation was successful, try sending yourself an SMS message, like this:

```rb
require "twilio-ruby"

# Your Account SID and Auth Token from console.twilio.com
account_sid = "ACXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
auth_token = "your_auth_token"

@client = Twilio::REST::Client.new account_sid, auth_token
message = @client.messages.create(
  body: "Hello from Ruby",
  to: "+12345678901",  # Text this number
  from: "+15005550006", # From a valid Twilio number
)

puts message.sid
```

> **Warning**
> It's okay to hardcode your credentials when testing locally, but you should use environment variables to keep them secret before committing any code or deploying to production. Check out [How to Set Environment Variables](https://www.twilio.com/blog/2017/01/how-to-set-environment-variables.html) for more information.

## Usage

### Authenticate the Client

```ruby
require 'twilio-ruby'

# Your Account SID and Auth Token from console.twilio.com
account_sid = 'ACxxxxxxxxxxxxxxxxxxxxxxxxxxxxx'
auth_token = 'yyyyyyyyyyyyyyyyyyyyyyyyyyyyyyy'

# Initialize the Twilio Client with your credentials
@client = Twilio::REST::Client.new account_sid, auth_token
```

### Use An API Key

```ruby
require 'twilio-ruby'

# Your Account SID from console.twilio.com
account_sid = 'ACxxxxxxxxxxxxxxxxxxxxxxxxxxxxx'
# API Key from twilio.com/console/project/api-keys
api_key_sid = 'zzzzzzzzzzzzzzzzzzzzzz'
api_key_secret = 'yyyyyyyyyyyyyyyyyyyyyyyyyyyyyyy'

# set up a client to talk to the Twilio REST API using an API Key
@client = Twilio::REST::Client.new api_key_sid, api_key_secret, account_sid
```

### Specify a Region and/or Edge

To take advantage of Twilio's [Global Infrastructure](https://www.twilio.com/docs/global-infrastructure), specify the target Region and/or Edge for the client:

```ruby
# set up a client to talk to the Twilio REST API over a specific region and edge
@client = Twilio::REST::Client.new account_sid, auth_token, nil, 'au1'
@client.edge = 'sydney'

# you may also specify the region and/or edge after client creation
@client = Twilio::REST::Client.new account_sid, auth_token
@client.region = 'au1'
@client.edge = 'sydney'
```

This will result in the `hostname` transforming from `api.twilio.com` to `api.sydney.au1.twilio.com`.

### Make a Call

```ruby
@client.calls.create(
  from: '+14159341234',
  to: '+16105557069',
  url: 'http://example.com'
)
```

### Send an SMS

```ruby
@client.messages.create(
  from: '+14159341234',
  to: '+16105557069',
  body: 'Hey there!'
)
```

### List your SMS Messages

```ruby
@client.messages.list(limit: 20)
```

### Fetch a single SMS message by Sid

```ruby
# put the message sid you want to retrieve here:
message_sid = 'SMxxxxxxxxxxxxxxxxxxxxxxxxxxxxx'
@client.messages(message_sid).fetch
```

### Iterate through records

The library automatically handles paging for you. Collections, such as `calls` and `messages`, have `list` and stream methods that page under the hood. With both `list` and `stream`, you can specify the number of records you want to receive (`limit`) and the maximum size you want each page fetch to be (`page_size`). The library will then handle the task for you.

`list` eagerly fetches all records and returns them as a list, whereas `stream` returns an enumerator and lazily retrieves pages of records as you iterate over the collection. You can also page manually using the `page` method.

For more information about these methods, view the [auto-generated library docs](https://www.twilio.com/docs/libraries/reference/twilio-ruby).

```rb
require 'twilio-ruby'

account_sid = 'ACXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX'
auth_token = 'your_auth_token'

@client = Twilio::REST::Client.new(account_sid, auth_token)

@client.calls.list
       .each do |call|
         puts call.direction
       end
```

### Enable Debug logging

In order to enable debug logging, pass in a 'logger' instance to the client with the level set to at least 'DEBUG'

```ruby
@client = Twilio::REST::Client.new account_sid, auth_token
myLogger = Logger.new(STDOUT)
myLogger.level = Logger::DEBUG
@client.logger = myLogger

@client = Twilio::REST::Client.new account_sid, auth_token
myLogger = Logger.new('my_log.log')
myLogger.level = Logger::DEBUG
@client.logger = myLogger
```

### Handle Exceptions {#exceptions}

If the Twilio API returns a 400 or a 500 level HTTP response, the `twilio-ruby`
library will throw a `Twilio::REST::RestError`. 400-level errors are normal
during API operation (`“Invalid number”`, `“Cannot deliver SMS to that number”`,
for example) and should be handled appropriately.

```rb
require 'twilio-ruby'

account_sid = 'ACXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX'
auth_token = 'your_auth_token'

@client = Twilio::REST::Client.new account_sid, auth_token

begin
  messages = @client.messages.list(limit: 20)
rescue Twilio::REST::RestError => e
  puts e.message
end
```

### Debug API requests

To assist with debugging, the library allows you to access the underlying request and response objects. This capability is built into the default HTTP client that ships with the library.

For example, you can retrieve the status code of the last response like so:

```ruby
require 'rubygems' # Not necessary with ruby 1.9 but included for completeness
require 'twilio-ruby'

# Your Account SID and Auth Token from console.twilio.com
account_sid = 'ACXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX'
auth_token = 'your_auth_token'

@client = Twilio::REST::Client.new(account_sid, auth_token)

@message = @client.messages.create(
  to: '+14158675309',
  from: '+14258675310',
  body: 'Ahoy!'
)

# Retrieve the status code of the last response from the HTTP client
puts @client.http_client.last_response.status_code
```

### Customize your HTTP Client

`twilio-ruby` uses [Faraday][faraday] to make HTTP requests. You can tell `Twilio::REST::Client` to use any of the Faraday adapters like so:

```ruby
@client.http_client.adapter = :typhoeus
```

To use a custom HTTP client with this helper library, please see the [advanced example of how to do so](./advanced-examples/custom-http-client.md).

To apply customizations such as middleware, you can use the `configure_connection` method like so:

```ruby
@client.http_client.configure_connection do |faraday|
  faraday.use SomeMiddleware
end
```

### Get started With Client Capability Tokens

If you just need to generate a Capability Token for use with Twilio Client, you can do this:

```ruby
require 'twilio-ruby'

# put your own account credentials here:
account_sid = 'ACxxxxxxxxxxxxxxxxxxxxxxxxxxxxx'
auth_token = 'yyyyyyyyyyyyyyyyyyyyyyyyyyyyyyy'

# set up
capability = Twilio::JWT::ClientCapability.new account_sid, auth_token

# allow outgoing calls to an application
outgoing_scope = Twilio::JWT::ClientCapability::OutgoingClientScope.new 'AP11111111111111111111111111111111'
capability.add_scope(outgoing_scope)

# allow incoming calls to 'andrew'
incoming_scope = Twilio::JWT::ClientCapability::IncomingClientScope.new 'andrew'
capability.add_scope(incoming_scope)

# generate the token string
@token = capability.to_s
```

There is a slightly more detailed document in the [Capability][capability] section of the wiki.

## OAuth Feature for Twilio APIs
We are introducing Client Credentials Flow-based OAuth 2.0 authentication. This feature is currently in beta and its implementation is subject to change.

API examples [here](https://github.com/twilio/twilio-ruby/blob/main/examples/public_oauth.rb)

### Generate TwiML

To control phone calls, your application needs to output [TwiML][twiml].

You can construct a TwiML response like this:

```ruby
require 'twilio-ruby'

response = Twilio::TwiML::VoiceResponse.new do |r|
  r.say(message: 'hello there', voice: 'alice')
  r.dial(caller_id: '+14159992222') do |d|
    d.client 'jenny'
  end
end

# print the result
puts response.to_s
```

This will print the following (except for the whitespace):

```xml
<?xml version="1.0" encoding="UTF-8"?>
<Response>
  <Say voice="alice">hello there</Say>
  <Dial callerId="+14159992222">
    <Client>jenny</Client>
  </Dial>
</Response>
```

## Docker Image

The `Dockerfile` present in this repository and its respective `twilio/twilio-ruby` Docker image are currently used by Twilio for testing purposes only.

## Getting help

If you need help installing or using the library, please check the [Twilio Support Help Center](https://support.twilio.com) first, and [file a support ticket](https://twilio.com/help/contact) if you don't find an answer to your question.

If you've instead found a bug in the library or would like new features added, go ahead and open issues or pull requests against this repo!

[apidocs]: https://www.twilio.com/docs/api
[twiml]: https://www.twilio.com/docs/api/twiml
[libdocs]: https://www.twilio.com/docs/libraries/reference/twilio-ruby/
[refdocs]: https://twilio.github.io/twilio-ruby
[capability]: https://github.com/twilio/twilio-ruby/wiki/JWT-Tokens
[wiki]: https://github.com/twilio/twilio-ruby/wiki
[bundler]: https://bundler.io
[rubygems]: https://rubygems.org
[gem]: https://rubygems.org/gems/twilio
[github-actions]: https://github.com/twilio/twilio-ruby/actions/workflows/test-and-deploy.yml
[upgrade]: https://github.com/twilio/twilio-ruby/wiki/Ruby-Version-5.x-Upgrade-Guide
[issues]: https://github.com/twilio/twilio-ruby/issues
[faraday]: https://github.com/lostisland/faraday
