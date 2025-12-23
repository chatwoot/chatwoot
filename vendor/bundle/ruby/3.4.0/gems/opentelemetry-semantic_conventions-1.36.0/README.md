# Opentelemetry::SemanticConventions

The `opentelemetry-semantic_conventions` gem provides auto-generated constants that represent the OpenTelemetry [Semantic Conventions][semantic-conventions].

## What is OpenTelemetry?

OpenTelemetry is an open source observability framework, providing a general-purpose API, SDK, and related tools required for the instrumentation of cloud-native software, frameworks, and libraries.

OpenTelemetry provides a single set of APIs, libraries, agents, and collector services to capture distributed traces and metrics from your application. You can analyze them using Prometheus, Jaeger, and other observability tools.

## How does this gem fit in?

The `opentelemetry-semantic_conventions` gem provides auto-generated constants that represent the OpenTelemetry Semantic Conventions. They may be referenced in instrumentation or end-user code in place of hard-coding the names of the conventions. Because they are generated from the YAML models in the specification, they are kept up-to-date for you.

## How do I get started?

Install the gem using:

```sh
gem install opentelemetry-semantic_conventions
```

Or, if you use Bundler, include `opentelemetry-semantic_conventions` in your `Gemfile`.

```rb
require 'opentelemetry/semantic_conventions'

# Use the constants however you feel necessary, eg:

puts "This is the value of #{OpenTelemetry::SemanticConventions::Trace::CODE_LINENO}"
```

## How do I rebuild the conventions?

Bump the version number in the Rakefile, and then run `rake generate`.

## How can I get involved?

The `opentelemetry-semantic_conventions` gem source is on github, along with related gems.

The OpenTelemetry Ruby gems are maintained by the OpenTelemetry-Ruby special interest group (SIG). You can get involved by joining us in [GitHub Discussions][discussions-url] or attending our weekly meeting. See the meeting calendar for dates and times. For more information on this and other language SIGs, see the OpenTelemetry community page.

## License

The `opentelemetry-semantic_conventions` gem is distributed under the Apache 2.0 license. See LICENSE for more information.

[discussions-url]: https://github.com/open-telemetry/opentelemetry-ruby/discussions
[semantic-conventions]: https://github.com/open-telemetry/opentelemetry-specification/tree/v1.20.0/semantic_conventions
