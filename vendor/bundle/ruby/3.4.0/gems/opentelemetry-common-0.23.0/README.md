# Opentelemetry::Common

The `opentelemetry-common` gem provides common helpers for OpenTelemetry.

## What is OpenTelemetry?

OpenTelemetry is an open source observability framework, providing a general-purpose API, SDK, and related tools required for the instrumentation of cloud-native software, frameworks, and libraries.

OpenTelemetry provides a single set of APIs, libraries, agents, and collector services to capture distributed traces and metrics from your application. You can analyze them using Prometheus, Jaeger, and other observability tools.

## How does this gem fit in?

The `opentelemetry-common` gem provides common helpers for semantic conventions, context propagation patterns, etc. It depends only on the OpenTelemetry Ruby API, not the SDK.

## How do I get started?

Install the gem using:

```sh
gem install opentelemetry-common
```

Or, if you use Bundler, include `opentelemetry-common` in your `Gemfile`.

```rb
require 'opentelemetry/common'

# TODO: example of semantic convention helpers

# Context propagation in Net::HTTP client
OpenTelemetry::Common::HTTP::ClientContext.with_attributes('peer.service' => 'example') do
  Net::HTTP.get('example.com', '/index.html')
end

# Context propagation in Net::HTTP instrumentation
attributes = OpenTelemetry::Common::HTTP::ClientContext.attributes
tracer.in_span(
  HTTP_METHODS_TO_SPAN_NAMES[req.method],
  attributes: attributes.merge(
    'http.method' => req.method,
    'http.scheme' => USE_SSL_TO_SCHEME[use_ssl?],
    'http.target' => req.path,
    'net.peer.name' => @address,
    'net.peer.port' => @port
  ),
  kind: :client
) do |span|
  ...
end
```

## How can I get involved?

The `opentelemetry-common` gem source is on github, along with related gems.

The OpenTelemetry Ruby gems are maintained by the OpenTelemetry-Ruby special interest group (SIG). You can get involved by joining us in [GitHub Discussions][discussions-url] or attending our weekly meeting. See the meeting calendar for dates and times. For more information on this and other language SIGs, see the OpenTelemetry community page.

## License

The `opentelemetry-common` gem is distributed under the Apache 2.0 license. See LICENSE for more information.

[discussions-url]: https://github.com/open-telemetry/opentelemetry-ruby/discussions
