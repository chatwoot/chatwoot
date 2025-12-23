# elastic-apm

## Elastic APM agent for Ruby

[![Jenkins](https://apm-ci.elastic.co/buildStatus/icon?job=apm-agent-ruby/apm-agent-ruby-mbp/main)](https://apm-ci.elastic.co/job/apm-agent-ruby/job/apm-agent-ruby-mbp/job/main/) [![Gem](https://img.shields.io/gem/v/elastic-apm.svg)](https://rubygems.org/gems/elastic-apm)

The official Rubygem for [Elastic][] [APM][].

💡 We'd love to get feedback and information about your setup – please answer this [☑ short survey](https://goo.gl/forms/LQktvn4rkLWBNSWy1).

---

## Documentation

[Full documentation at elastic.co](https://www.elastic.co/guide/en/apm/agent/ruby/current/index.html).

<ul>
  <li>
    <a href="https://www.elastic.co/guide/en/apm/agent/ruby/current/set-up.html">Set up the Agent</a>
    <ul>
      <li>
        <a href="https://www.elastic.co/guide/en/apm/agent/ruby/current/getting-started-rails.html">Getting started with Rails</a>
      </li>
      <li>
        <a href="https://www.elastic.co/guide/en/apm/agent/ruby/current/getting-started-rack.html">Getting started with Rack</a>
      </li>
    </ul>
  </li>
  <li>
    <a href="https://www.elastic.co/guide/en/apm/agent/ruby/current/supported-technologies.html">Supported technologies</a>
  </li>
  <li>
    <a href="https://www.elastic.co/guide/en/apm/agent/ruby/current/configuration.html">Configuration</a>
  </li>
  <li>
    <a href="https://www.elastic.co/guide/en/apm/agent/ruby/current/advanced.html">Advanced Topics</a>
    <ul>
      <li>
        <a href="https://www.elastic.co/guide/en/apm/agent/ruby/current/context.html">Adding additional context</a>
      </li>
      <li>
        <a href="https://www.elastic.co/guide/en/apm/agent/ruby/current/custom-instrumentation.html">Custom instrumentation</a>
      </li>
    </ul>
  </li>
  <li>
    <a href="https://www.elastic.co/guide/en/apm/agent/ruby/current/api.html">API reference</a>
  </li>
  <li>
    <a href="https://www.elastic.co/guide/en/apm/agent/ruby/current/metrics.html">Metrics</a>
  </li>
  <li>
    <a href="https://www.elastic.co/guide/en/apm/agent/ruby/current/opentracing.html">OpenTracing API</a>
  </li>
  <li>
    <a href="https://www.elastic.co/guide/en/apm/agent/ruby/current/graphql.html">GraphQL</a>
  </li>
  <li>
    <a href="https://www.elastic.co/guide/en/apm/agent/ruby/current/log-correlation.html">Log correlation</a>
  </li>
  <li>
    <a href="https://www.elastic.co/guide/en/apm/agent/ruby/current/tuning-and-overhead.html">Performance tuning</a>
  </li>
  <li>
    <a href="https://www.elastic.co/guide/en/apm/agent/ruby/current/debugging.html">Troubleshooting</a>
  </li>
  <li>
    <a href="https://www.elastic.co/guide/en/apm/agent/ruby/current/upgrading.html">Upgrading</a>
  </li>
  <li class="collapsible">
    <a href="https://www.elastic.co/guide/en/apm/agent/ruby/current/release-notes.html">Release notes</a>
    <ul>
      <li>
        <a href="https://www.elastic.co/guide/en/apm/agent/ruby/current/release-notes-4.x.html">Ruby Agent version 4.x</a>
      </li>
      <li>
        <a href="https://www.elastic.co/guide/en/apm/agent/ruby/current/release-notes-3.x.html">Ruby Agent version 3.x</a>
      </li>
      <li>
        <a href="https://www.elastic.co/guide/en/apm/agent/ruby/current/release-notes-2.x.html">Ruby Agent version 2.x</a>
      </li>
      <li>
        <a href="https://www.elastic.co/guide/en/apm/agent/ruby/current/release-notes-1.x.html">Ruby Agent version 1.x</a>
      </li>
      <li>
        <a href="https://www.elastic.co/guide/en/apm/agent/ruby/current/release-notes-0.x.html">Ruby Agent version 0.x</a>
      </li>
    </ul>
  </li>
</ul>

---

## Getting help

If you find a bug, please [report an issue](https://github.com/elastic/apm-agent-ruby/issues).
For any other assistance, please open or add to a topic on the [APM discuss forum](https://discuss.elastic.co/c/apm).

## Development

A Docker based setup is provided for development.

To run all specs in the official `ruby:latest` image:

```sh
$ bin/dev
```

To pick a specific Ruby version, specify it with the `-i` flag:

```sh
$ bin/dev -i jruby:9.2
```

If the first argument is a path starting with `spec/`, the passed specs will be run. Otherwise any arguments passed will be run as a command inside the container:

```sh
$ bin/dev -i jruby:9.2 spec/integration/rails_spec.rb   # ✅
$ bin/dev -i some_custom_image bash                     # ✅
```

To see all options:

```sh
$ bin/dev -h
```

## License

Apache 2.0

[Elastic]: https://elastic.co
[APM]: https://www.elastic.co/guide/en/apm/server/index.html
