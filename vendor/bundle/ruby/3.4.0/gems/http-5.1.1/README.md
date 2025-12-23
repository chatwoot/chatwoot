# ![http.rb](https://raw.github.com/httprb/http.rb/main/logo.png)

[![Gem Version][gem-image]][gem-link]
[![MIT licensed][license-image]][license-link]
[![Build Status][build-image]][build-link]
[![Code Climate][codeclimate-image]][codeclimate-link]

[Documentation]

## About

HTTP (The Gem! a.k.a. http.rb) is an easy-to-use client library for making requests
from Ruby. It uses a simple method chaining system for building requests, similar to
Python's [Requests].

Under the hood, http.rb uses the [llhttp] parser, a fast HTTP parsing native extension.
This library isn't just yet another wrapper around `Net::HTTP`. It implements the HTTP
protocol natively and outsources the parsing to native extensions.

### Why http.rb?

- **Clean API**: http.rb offers an easy-to-use API that should be a
   breath of fresh air after using something like Net::HTTP.

- **Maturity**: http.rb is one of the most mature Ruby HTTP clients, supporting
   features like persistent connections and fine-grained timeouts.

- **Performance**: using native parsers and a clean, lightweight implementation,
   http.rb achieves high performance while implementing HTTP in Ruby instead of C.


## Installation

Add this line to your application's Gemfile:
```ruby
gem "http"
```

And then execute:
```bash
$ bundle
```

Or install it yourself as:
```bash
$ gem install http
```

Inside of your Ruby program do:
```ruby
require "http"
```

...to pull it in as a dependency.


## Documentation

[Please see the http.rb wiki][documentation]
for more detailed documentation and usage notes.

The following API documentation is also available:

- [YARD API documentation](https://www.rubydoc.info/github/httprb/http)
- [Chainable module (all chainable methods)](https://www.rubydoc.info/github/httprb/http/HTTP/Chainable)


### Basic Usage

Here's some simple examples to get you started:

```ruby
>> HTTP.get("https://github.com").to_s
=> "\n\n\n<!DOCTYPE html>\n<html lang=\"en\" class=\"\">\n  <head prefix=\"o..."
```

That's all it takes! To obtain an `HTTP::Response` object instead of the response
body, all we have to do is omit the `#to_s` on the end:

```ruby
>> HTTP.get("https://github.com")
=> #<HTTP::Response/1.1 200 OK {"Server"=>"GitHub.com", "Date"=>"Tue, 10 May...>
```

We can also obtain an `HTTP::Response::Body` object for this response:

```ruby
>> HTTP.get("https://github.com").body
=> #<HTTP::Response::Body:3ff756862b48 @streaming=false>
```

The response body can be streamed with `HTTP::Response::Body#readpartial`.
In practice, you'll want to bind the `HTTP::Response::Body` to a local variable
and call `#readpartial` on it repeatedly until it returns `nil`:

```ruby
>> body = HTTP.get("https://github.com").body
=> #<HTTP::Response::Body:3ff756862b48 @streaming=false>
>> body.readpartial
=> "\n\n\n<!DOCTYPE html>\n<html lang=\"en\" class=\"\">\n  <head prefix=\"o..."
>> body.readpartial
=> "\" href=\"/apple-touch-icon-72x72.png\">\n    <link rel=\"apple-touch-ic..."
# ...
>> body.readpartial
=> nil
```

## Supported Ruby Versions

This library aims to support and is [tested against][build-link]
the following Ruby  versions:

- Ruby 2.6
- Ruby 2.7
- Ruby 3.0
- Ruby 3.1
- JRuby 9.3

If something doesn't work on one of these versions, it's a bug.

This library may inadvertently work (or seem to work) on other Ruby versions,
however support will only be provided for the versions listed above.

If you would like this library to support another Ruby version or
implementation, you may volunteer to be a maintainer. Being a maintainer
entails making sure all tests run and pass on that implementation. When
something breaks on your implementation, you will be responsible for providing
patches in a timely fashion. If critical issues for a particular implementation
exist at the time of a major release, support for that Ruby version may be
dropped.


## Contributing to http.rb

- Fork http.rb on GitHub
- Make your changes
- Ensure all tests pass (`bundle exec rake`)
- Send a pull request
- If we like them we'll merge them
- If we've accepted a patch, feel free to ask for commit access!


## Copyright

Copyright © 2011-2022 Tony Arcieri, Alexey V. Zapparov, Erik Michaels-Ober, Zachary Anker.
See LICENSE.txt for further details.


[//]: # (badges)

[gem-image]: https://img.shields.io/gem/v/http?logo=ruby
[gem-link]: https://rubygems.org/gems/http
[license-image]: https://img.shields.io/badge/license-MIT-blue.svg
[license-link]: https://github.com/httprb/http/blob/main/LICENSE.txt
[build-image]: https://github.com/httprb/http/workflows/CI/badge.svg
[build-link]: https://github.com/httprb/http/actions/workflows/ci.yml
[codeclimate-image]: https://codeclimate.com/github/httprb/http.svg?branch=main
[codeclimate-link]: https://codeclimate.com/github/httprb/http

[//]: # (links)

[documentation]: https://github.com/httprb/http/wiki
[requests]: http://docs.python-requests.org/en/latest/
[llhttp]: https://llhttp.org/
