# Faraday Retry

[![CI](https://github.com/lostisland/faraday-retry/actions/workflows/ci.yaml/badge.svg)](https://github.com/lostisland/faraday-retry/actions/workflows/ci.yaml)
[![Gem](https://img.shields.io/gem/v/faraday-retry.svg?style=flat-square)](https://rubygems.org/gems/faraday-retry)
[![License](https://img.shields.io/github/license/lostisland/faraday-retry.svg?style=flat-square)](LICENSE.md)

The `Retry` middleware automatically retries requests that fail due to intermittent client
or server errors (such as network hiccups).
By default, it retries 2 times and handles only timeout exceptions.
It can be configured with an arbitrary number of retries, a list of exceptions to handle,
a retry interval, a percentage of randomness to add to the retry interval, and a backoff factor.
The middleware can also handle the [`Retry-After`](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Retry-After)
header automatically when configured with the right status codes (see below for an example).

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'faraday-retry'
```

And then execute:

```shell
bundle install
```

Or install it yourself as:

```shell
gem install faraday-retry
```

## Usage

This example will result in a first interval that is random between 0.05 and 0.075
and a second interval that is random between 0.1 and 0.125.

```ruby
require 'faraday'
require 'faraday/retry'

retry_options = {
  max: 2,
  interval: 0.05,
  interval_randomness: 0.5,
  backoff_factor: 2
}

conn = Faraday.new(...) do |f|
  f.request :retry, retry_options
  #...
end

conn.get('/')
```

### Control when the middleware will retry requests

By default, the `Retry` middleware will only retry idempotent methods and the most common network-related exceptions.
You can change this behaviour by providing the right option when adding the middleware to your connection.

#### Specify which methods will be retried

You can provide a `methods` option with a list of HTTP methods.
This will replace the default list of HTTP methods: `delete`, `get`, `head`, `options`, `put`.

```ruby
retry_options = {
  methods: %i[get post]
}
```

#### Specify which exceptions should trigger a retry

You can provide an `exceptions` option with a list of exceptions that will replace
the default exceptions: `Errno::ETIMEDOUT`, `Timeout::Error`, `Faraday::TimeoutError`, `Faraday::Error::RetriableResponse`.
This can be particularly useful when combined with the [RaiseError][raise_error] middleware.

```ruby
retry_options = {
  exceptions: [Faraday::ResourceNotFound, Faraday::UnauthorizedError]
}
```

If you want to inherit default exceptions, do it this way.

```ruby
retry_options = {
  exceptions: Faraday::Retry::Middleware::DEFAULT_EXCEPTIONS + [Faraday::ResourceNotFound, Faraday::UnauthorizedError]
}
```

#### Specify on which response statuses to retry

By default the `Retry` middleware will only retry the request if one of the expected exceptions arise.
However, you can specify a list of HTTP statuses you'd like to be retried. When you do so, the middleware will
check the response `status` code and will retry the request if included in the list.

```ruby
retry_options = {
  retry_statuses: [401, 409]
}
```

#### Automatically handle the `Retry-After` and `RateLimit-Reset` headers

Some APIs, like the [Slack API](https://api.slack.com/docs/rate-limits), will inform you when you reach their API limits by replying with a response status code of `429`
and a response header of `Retry-After` containing a time in seconds. You should then only retry querying after the amount of time provided by the `Retry-After` header,
otherwise you won't get a response. Other APIs communicate their rate limits via the [RateLimit-xxx](https://www.ietf.org/archive/id/draft-ietf-httpapi-ratelimit-headers-05.html#name-providing-ratelimit-fields) headers
where `RateLimit-Reset` behaves similarly to the `Retry-After`.

You can automatically handle both headers and have Faraday pause and retry for the right amount of time by including the `429` status code in the retry statuses list:

```ruby
retry_options = {
  retry_statuses: [429]
}
```

If you are working with an API which does not comply with the Rate Limit RFC you can specify custom headers to be used for retry and reset, as well as a block to parse the headers:

```ruby
retry_options = {
  retry_statuses: [429],
  rate_limit_retry_header: 'x-rate-limit-retry-after',
  rate_limit_reset_header: 'x-rate-limit-reset',
  header_parser_block: ->(value) { Time.at(value.to_i).utc - Time.now.utc }
}
```

#### Specify a custom retry logic

You can also specify a custom retry logic with the `retry_if` option.
This option accepts a block that will receive the `env` object and the exception raised
and should decide if the code should retry still the action or not independent of the retry count.
This would be useful if the exception produced is non-recoverable or if the the HTTP method called is not idempotent.

**NOTE:** this option will only be used for methods that are not included in the `methods` option.
If you want this to apply to all HTTP methods, pass `methods: []` as an additional option.

```ruby
# Retries the request if response contains { success: false }
retry_options = {
  retry_if: -> (env, _exc) { env.body[:success] == 'false' }
}
```

### Call a block on every retry

You can specify a proc object through the `retry_block` option that will be called before every
retry, before  There are many different applications for this feature, spacing from instrumentation to monitoring.

The block is passed keyword arguments with contextual information: Request environment, middleware options, current number of retries, exception, and amount of time we will wait before retrying. (retry_block is called before the wait time happens)

For example, you might want to keep track of the response statuses:

```ruby
response_statuses = []
retry_options = {
  retry_block: -> (env:, options:, retry_count:, exception:, will_retry_in:) { response_statuses << env.status }
}
```

## Development

After checking out the repo, run `bin/setup` to install dependencies.

Then, run `bin/test` to run the tests.

To install this gem onto your local machine, run `rake build`.

### Releasing a new version

To release a new version, make a commit with a message such as "Bumped to 0.0.2", and change the _Unreleased_ heading in `CHANGELOG.md` to a heading like "0.0.2 (2022-01-01)", and then use GitHub Releases to author a release. A GitHub Actions workflow then publishes a new gem to [RubyGems.org](https://rubygems.org/gems/faraday-retry).

## Contributing

Bug reports and pull requests are welcome on [GitHub](https://github.com/lostisland/faraday-retry).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

[raise_error]:  https://lostisland.github.io/faraday/#/middleware/included/raising-errors
