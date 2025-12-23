# Faraday::NetHttpPersistent

[![Gem Version](https://badge.fury.io/rb/faraday-net_http_persistent.svg)](https://rubygems.org/gems/faraday-net_http_persistent)
[![GitHub Actions CI](https://github.com/lostisland/faraday-net_http_persistent/workflows/CI/badge.svg)](https://github.com/lostisland/faraday-net_http_persistent/actions?query=workflow%3ACI)

This gem is a [Faraday][faraday] adapter for the [Net::HTTP::Persistent gem][net-http-persistent].

## Installation

Add this to your application's Gemfile:

```ruby
gem 'faraday-net_http_persistent', '~> 2.0'
```

And then execute:

    $ bundle

## Usage

```ruby
require 'faraday/net_http_persistent'

conn = Faraday.new(...) do |f|
  f.adapter :net_http_persistent, pool_size: 5 do |http|
    # yields Net::HTTP::Persistent
    http.idle_timeout = 100
  end
end
```

## Development

After checking out the repo, run `bin/setup` to install dependencies.
Then, run `rake spec` to run the tests. You can also run `bin/console`
for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`.
To release a new version, update the version number in `version.rb`,
and then run `bundle exec rake release`, which will create a git tag for the version,
push git commits and tags, and push the `.gem` file to [rubygems.org].

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/lostisland/faraday-net_http_persistent.
This project is intended to be a safe, welcoming space for collaboration,
and contributors are expected to adhere to the [Contributor Covenant][covenant] code of conduct.

## License

The gem is available as open source under the terms of the [MIT License][mit-license].

## Code of Conduct

This project is intended to be a safe, welcoming space for collaboration.
Everyone interacting in the Faraday::Http project’s codebases, issue trackers,
chat rooms and mailing lists is expected to follow the [code of conduct][code-of-conduct].

[code-of-conduct]:     https://github.com/lostisland/faraday-http/blob/main/CODE_OF_CONDUCT.md
[covenant]:            http://contributor-covenant.org
[faraday]:             https://github.com/lostisland/faraday
[faraday-website]:     https://lostisland.github.io/faraday
[net-http-persistent]: https://github.com/drbrain/net-http-persistent
[mit-license]:         https://opensource.org/licenses/MIT
[rubygems.org]:        https://rubygems.org
