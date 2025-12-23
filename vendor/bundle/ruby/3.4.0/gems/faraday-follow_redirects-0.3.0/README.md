# Faraday Follow Redirects

[![GitHub Workflow Status](https://img.shields.io/github/workflow/status/tisba/faraday-follow-redirects/CI)](https://github.com/tisba/faraday-follow-redirects/actions?query=branch%3Amain)
[![Gem](https://img.shields.io/gem/v/faraday-follow_redirects.svg?style=flat-square)](https://rubygems.org/gems/faraday-follow_redirects)
[![License](https://img.shields.io/github/license/tisba/faraday-follow-redirects.svg?style=flat-square)](LICENSE.md)

Faraday 2.x compatible extraction of `FaradayMiddleware::FollowRedirects`. This gem will also work with Faraday 1.x, to support gem codebases which can work with Faraday 1.x or 2.x. For the former standard version of this middleware for Faraday 1.x, check out https://github.com/lostisland/faraday_middleware. Faraday 1.x support is considered deprecated, please update to Faraday 2.x.

This gem is based on the deprecated [`FaradayMiddleware::FollowRedirects` (v1.2.0)](https://github.com/lostisland/faraday_middleware/blob/v1.2.0/lib/faraday_middleware/response/follow_redirects.rb).

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'faraday-follow_redirects'
```

And then execute:

```shell
bundle install
```

Or install it yourself as:

```shell
gem install faraday-follow_redirects
```

## Usage

```ruby
require 'faraday/follow_redirects'

Faraday.new(url: url) do |faraday|
  faraday.use Faraday::FollowRedirects::Middleware

  faraday.adapter Faraday.default_adapter
end
```

## Development

After checking out the repo, run `bin/setup` to install dependencies.

Then, run `bin/test` to run the tests.

To install this gem onto your local machine, run `rake build`.

To release a new version, make a commit with a message such as "Bumped to 0.0.2" and then run `rake release`.
See how it works [here](https://bundler.io/guides/creating_gem.html#releasing-the-gem).

We only supports non-EOL versions of Ruby. See [Ruby Maintenance Branches](https://www.ruby-lang.org/en/downloads/branches/) for the list of non-EOL Rubies.

### Appraisal for testing multiple versions of dependencies

We use [appraisal](https://github.com/thoughtbot/appraisal) to test against both faraday 1.x and 2.x, and `./bin/test` will run tests against both. To run tests against just one you could:

    bundle exec appraisal faraday_1 rspec
    bundle exec appraisal faraday_2 rspec

## Contributing

Bug reports and pull requests are welcome on [GitHub](https://github.com/tisba/faraday-follow_redirects).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
