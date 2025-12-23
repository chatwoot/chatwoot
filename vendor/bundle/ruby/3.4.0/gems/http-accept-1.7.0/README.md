# HTTP::Accept

Provides a robust set of parsers for dealing with HTTP `Accept`, `Accept-Language`, `Accept-Encoding`, `Accept-Charset` headers.

[![Build Status](https://secure.travis-ci.org/ioquatix/http-accept.svg)](http://travis-ci.org/ioquatix/http-accept)
[![Code Climate](https://codeclimate.com/github/ioquatix/http-accept.svg)](https://codeclimate.com/github/ioquatix/http-accept)
[![Coverage Status](https://coveralls.io/repos/ioquatix/http-accept/badge.svg)](https://coveralls.io/r/ioquatix/http-accept)

## Motivation

I've been [developing some tools for building RESTful endpoints](https://github.com/ioquatix/utopia/blob/master/lib/utopia/controller/respond.rb) and part of that involved versioning. After reviewing the options, I settled on using the `Accept: application/json;version=1` method [as outlined here](http://labs.qandidate.com/blog/2014/10/16/using-the-accept-header-to-version-your-api/).

The `version=1` part of the `media-type` is a `parameter` as defined by [RFC7231 Section 3.1.1.1](https://tools.ietf.org/html/rfc7231#section-3.1.1.1). After reviewing several existing different options for parsing the `Accept:` header, I noticed a disturbing trend: `header.split(',')`. Because parameters may contain quoted strings which contain commas, this is clearly not an appropriate way to parse the header.

I am concerned about correctness, security and performance. As such, I implemented this gem to provide a simple high level interface for both parsing and correctly interpreting these headers.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'http-accept'
```

And then execute:

	$ bundle

Or install it yourself as:

	$ gem install http-accept

## Usage

Here are some examples of how to parse various headers.

### Parsing Accept: headers

You can parse the incoming `Accept:` header:

```ruby
media_types = HTTP::Accept::MediaTypes.parse("text/html;q=0.5, application/json; version=1")

expect(media_types[0].mime_type).to be == "application/json"
expect(media_types[0].parameters).to be == {'version' => '1'}
expect(media_types[1].mime_type).to be == "text/html"
expect(media_types[1].parameters).to be == {'q' => '0.5'}
```

Normally, you'd want to match the media types against some set of available mime types:

```ruby
module ToJSON
  def content_type
    HTTP::Accept::ContentType.new("application/json", charset: 'utf-8')
  end

  # Used for inserting into map.
  def split(*args)
    content_type.split(*args)
  end

  def convert(object, options)
    object.to_json
  end
end

module ToXML
  # Are you kidding?
end

map = HTTP::Accept::MediaTypes::Map.new
map << ToJSON
map << ToXML

object, media_range = map.for(media_types)
content = object.convert(model, media_range.parameters)
response = [200, {'Content-Type' => object.content_type}, [content]]
```

### Parsing Accept-Language: headers

You can parse the incoming `Accept-Language:` header:

```ruby
languages = HTTP::Accept::Languages.parse("da, en-gb;q=0.8, en;q=0.7")

expect(languages[0].locale).to be == "da"
expect(languages[1].locale).to be == "en-gb"
expect(languages[2].locale).to be == "en"
```

Normally, you'd want to match the languages against some set of available localizations:

```ruby
available_localizations = HTTP::Accept::Languages::Locales.new(["en-nz", "en-us"])

# Given the languages that the user wants, and the localizations available, compute the set of desired localizations.
desired_localizations = available_localizations & languages
```

The `desired_localizations` in the example above is a subset of `available_localizations`.

`HTTP::Accept::Languages::Locales` provides an efficient data-structure for matching the Accept-Languages header to set of available localizations according to https://tools.ietf.org/html/rfc7231#section-5.3.5 and https://tools.ietf.org/html/rfc4647#section-2.3

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## License

Released under the MIT license.

Copyright, 2016, by [Samuel G. D. Williams](http://www.codeotaku.com/samuel-williams). 
Copyright, 2016, by [Matthew Kerwin](http://kerwin.net.au).

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
