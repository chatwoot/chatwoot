# OpenTelemetry Registry Instrumentation

The instrumentation Registry contains information about available instrumentation, facilitates discovery, installation, and configuration.

The Registry allows for instrumentation to avoid depending directly on a specific SDK implementation.

The SDK depends on the Registry, the instrumentation Base class depends on the Registry, and auto instrumentation libraries extend the instrumentation Base class.

The motivation for decoupling the Registry (and by extension the instrumentation) from a specific SDK implementation means that anyone can implement their own OpenTelemetry API compatible SDK, and they could continue to use community made instrumentation.

## How do I get started?

Install the gem using:

```console
gem install opentelemetry-registry
```

Or, if you use [bundler][bundler-home], include `opentelemetry-registry` in your `Gemfile`.

```ruby
  gem 'opentelemetry-registry'
```

## How can I get involved?

The `opentelemetry-registry` gem source is [on github][repo-github], along with related gems including `opentelemetry-api` and `opentelemetry-sdk`.

The OpenTelemetry Ruby gems are maintained by the OpenTelemetry-Ruby special interest group (SIG). You can get involved by joining us in [GitHub Discussions][discussions-url] or attending our weekly meeting. See the [meeting calendar][community-meetings] for dates and times. For more information on this and other language SIGs, see the OpenTelemetry [community page][ruby-sig].

## License

The `opentelemetry-instrumentation-registry` gem is distributed under the Apache 2.0 license. See [LICENSE][license-github] for more information.

[bundler-home]: https://bundler.io
[repo-github]: https://github.com/open-telemetry/opentelemetry-ruby
[license-github]: https://github.com/open-telemetry/opentelemetry-ruby/blob/main/LICENSE
[ruby-sig]: https://github.com/open-telemetry/community#ruby-sig
[community-meetings]: https://github.com/open-telemetry/community#community-meetings
[discussions-url]: https://github.com/open-telemetry/opentelemetry-ruby/discussions
