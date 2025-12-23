# opentelemetry-api

The `opentelemetry-api` gem defines the core OpenTelemetry interfaces for Ruby applications. Using `opentelemetry-api`, a library or application can code against the OpenTelemetry interfaces to produce telemetry data such as distributed traces and metrics.

## What is OpenTelemetry?

[OpenTelemetry][opentelemetry-home] is an open source observability framework, providing a general-purpose API, SDK, and related tools required for the instrumentation of cloud-native software, frameworks, and libraries.

OpenTelemetry provides a single set of APIs, libraries, agents, and collector services to capture distributed traces and metrics from your application. You can analyze them using Prometheus, Jaeger, and other observability tools.

## How does this gem fit in?

The `opentelemetry-api` gem defines the core OpenTelemetry interfaces in the form of abstract classes and no-op implementations. That is, it defines interfaces and data types sufficient for a library or application to code against to produce telemetry data, but does not actually collect, analyze, or export the data.

To collect and analyze telemetry data, *applications* should also
install a concrete implementation of the API, such as the
`opentelemetry-sdk` gem. However, *libraries* that produce telemetry
data should depend only on `opentelemetry-api`, deferring the choice of concrete implementation to the application developer.

## How do I get started?

Install the gem using:

```sh
gem install opentelemetry-api
```

Or, if you use [bundler][bundler-home], include `opentelemetry-api` in your `Gemfile`.

Then, use the OpenTelemetry interfaces to produces traces and other telemetry data. Following is a basic example.

```ruby
require 'opentelemetry'

# Obtain the current default tracer provider
provider = OpenTelemetry.tracer_provider

# Create a trace
tracer = provider.tracer('my_app', '1.0')

# Record spans
tracer.in_span('my_task') do |task_span|
  tracer.in_span('inner') do |inner_span|
    # Do something here
  end
end
```

For additional examples, see the [examples on github][examples-github].

## How can I get involved?

The `opentelemetry-api` gem source is [on github][repo-github], along with related gems including `opentelemetry-sdk`.

The OpenTelemetry Ruby gems are maintained by the OpenTelemetry-Ruby special interest group (SIG). You can get involved by joining us in [GitHub Discussions][discussions-url] or attending our weekly meeting. See the [meeting calendar][community-meetings] for dates and times. For more information on this and other language SIGs, see the OpenTelemetry [community page][ruby-sig].

## License

The `opentelemetry-api` gem is distributed under the Apache 2.0 license. See [LICENSE][license-github] for more information.

[opentelemetry-home]: https://opentelemetry.io
[bundler-home]: https://bundler.io
[repo-github]: https://github.com/open-telemetry/opentelemetry-ruby
[license-github]: https://github.com/open-telemetry/opentelemetry-ruby/blob/main/LICENSE
[examples-github]: https://github.com/open-telemetry/opentelemetry-ruby/tree/main/examples
[ruby-sig]: https://github.com/open-telemetry/community#ruby-sig
[community-meetings]: https://github.com/open-telemetry/community#community-meetings
[discussions-url]: https://github.com/open-telemetry/opentelemetry-ruby/discussions
