# opentelemetry-sdk

The `opentelemetry-sdk` gem provides the reference implementation of the OpenTelemetry Ruby API. Using `opentelemetry-sdk`, an application can collect, analyze, and export telemetry data such as distributed traces and metrics.

## What is OpenTelemetry?

[OpenTelemetry][opentelemetry-home] is an open source observability framework, providing a general-purpose API, SDK, and related tools required for the instrumentation of cloud-native software, frameworks, and libraries.

OpenTelemetry provides a single set of APIs, libraries, agents, and collector services to capture distributed traces and metrics from your application. You can analyze them using Prometheus, Jaeger, and other observability tools.

## How does this gem fit in?

The `opentelemetry-sdk` gem provides the reference implementation of the OpenTelemetry Ruby interfaces defined in the `opentelemetry-api` gem. That is, it includes the *functionality* needed to collect, analyze, and export telemetry data produced using the API.

Generally, Ruby *applications* should install `opentelemetry-sdk` (or
other concrete implementation of the OpenTelemetry API). Using the SDK,
an application can configure how it wants telemetry data to be handled,
including which data should be persisted, how it should be formatted,
and where it should be recorded or exported. However, *libraries* that
produce telemetry data should generally depend only on
`opentelemetry-api`, deferring the choice of concrete implementation to the application developer.

## How do I get started?

Install the gem using:

```sh
gem install opentelemetry-sdk
```

Or, if you use [bundler][bundler-home], include `opentelemetry-sdk` in your `Gemfile`.

Then, configure the SDK according to your desired handling of telemetry data, and use the OpenTelemetry interfaces to produces traces and other information. Following is a basic example.

```ruby
require 'opentelemetry/sdk'

# Configure the sdk with default export and context propagation formats.
OpenTelemetry::SDK.configure

# Many configuration options may be set via the environment. To use them,
# set the appropriate variable before calling configure. For example:
#
# ENV['OTEL_TRACES_EXPORTER'] = 'console'
# ENV['OTEL_PROPAGATORS'] = 'ottrace'
# OpenTelemetry::SDK.configure
#
# You may also configure the SDK programmatically, for advanced usage or to
# enable auto-instrumentation. For example:
#
# OpenTelemetry::SDK.configure do |c|
#   c.service_name = something_calculated_dynamically
#   c.add_span_processor(
#     OpenTelemetry::SDK::Trace::Export::SimpleSpanProcessor.new(
#       OpenTelemetry::SDK::Trace::Export::ConsoleSpanExporter.new
#     )
#   )
#
#   c.use 'OpenTelemetry::Instrumentation::Net::HTTP'
# end
#
# Note that the SimpleSpanProcessor is not recommended for use in production.


# To start a trace you need to get a Tracer from the TracerProvider
tracer = OpenTelemetry.tracer_provider.tracer('my_app_or_gem', '0.1.0')

# create a span
tracer.in_span('foo') do |span|
  # set an attribute
  span.set_attribute('platform', 'osx')
  # add an event
  span.add_event('event in bar')
  # create bar as child of foo
  tracer.in_span('bar') do |child_span|
    # inspect the span
    pp child_span
  end
end
```

For additional examples, see the [examples on github][examples-github].

## How can I get involved?

The `opentelemetry-sdk` gem source is [on github][repo-github], along with related gems including `opentelemetry-api`.

The OpenTelemetry Ruby gems are maintained by the OpenTelemetry-Ruby special interest group (SIG). You can get involved by joining us in [GitHub Discussions][discussions-url] or attending our weekly meeting. See the [meeting calendar][community-meetings] for dates and times. For more information on this and other language SIGs, see the OpenTelemetry [community page][ruby-sig].

## License

The `opentelemetry-sdk` gem is distributed under the Apache 2.0 license. See [LICENSE][license-github] for more information.

[opentelemetry-home]: https://opentelemetry.io
[bundler-home]: https://bundler.io
[repo-github]: https://github.com/open-telemetry/opentelemetry-ruby
[license-github]: https://github.com/open-telemetry/opentelemetry-ruby/blob/main/LICENSE
[examples-github]: https://github.com/open-telemetry/opentelemetry-ruby/tree/main/examples
[ruby-sig]: https://github.com/open-telemetry/community#ruby-sig
[community-meetings]: https://github.com/open-telemetry/community#community-meetings
[discussions-url]: https://github.com/open-telemetry/opentelemetry-ruby/discussions
