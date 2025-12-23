# Faraday Mashify

[![CI](https://github.com/sue445/faraday-mashify/actions/workflows/ci.yaml/badge.svg)](https://github.com/sue445/faraday-mashify/actions/workflows/ci.yaml)
[![Gem](https://img.shields.io/gem/v/faraday-mashify.svg?style=flat-square)](https://rubygems.org/gems/faraday-mashify)
[![License](https://img.shields.io/github/license/sue445/faraday-mashify.svg?style=flat-square)](LICENSE.md)

Faraday middleware for wrapping responses into [Hashie::Mash](https://github.com/hashie/hashie#mash).

This very specific middleware has been extracted from the [faraday_middleware](https://github.com/lostisland/faraday_middleware) project.

This is fully compatible with [FaradayMiddleware::Mashify](https://github.com/lostisland/faraday_middleware/blob/main/lib/faraday_middleware/response/mashify.rb)

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'faraday-mashify'
```

And then execute:

```shell
bundle install
```

Or install it yourself as:

```shell
gem install faraday-mashify
```

## Usage
```bash
curl http://www.example.com/api/me
{"name":"sue445"}
```

```ruby
require 'faraday/mashify'

connection =
  Faraday.new(url: 'http://www.example.com') do |conn|
    conn.response :mashify
    conn.response :json
  end

response = connection.get('/api/me').body

response[:name]
#=> "sue445"

response['name']
#=> "sue445"

response.name
#=> "sue445"
```

### Customize response class
If you want to customize the response class, pass `mash_class` to `conn.response :mashify`. (default is `Hashie::Mash`)

e.g.

```ruby
class MyHash < Hashie::Mash
end

connection =
  Faraday.new(url: 'http://www.example.com') do |conn|
    conn.response :mashify, mash_class: MyHash
    conn.response :json
  end

response = connection.get('/api/me').body

response.class
#=> MyHash
```

## Migrate from faraday_middleware
Please do the following

1. `gem "faraday_middleware"` -> `gem "faraday-mashify"` in `Gemfile`
2. `require "faraday_middleware"` -> `require "faraday/mashify"`

## Development

After checking out the repo, run `bin/setup` to install dependencies.

Then, run `bin/test` to run the tests.

To install this gem onto your local machine, run `rake build`.

To release a new version, make a commit with a message such as "Bumped to 0.0.2" and then run `rake release`.
See how it works [here](https://bundler.io/guides/creating_gem.html#releasing-the-gem).

## Contributing

Bug reports and pull requests are welcome on [GitHub](https://github.com/sue445/faraday-mashify).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
