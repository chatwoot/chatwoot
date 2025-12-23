Logging
-------

Rack::Timeout logs a line every time there's a change in state in a request's lifetime.

Request state changes into `timed_out` and `expired` are logged at the `ERROR` level, most other things are logged as `INFO`. The `active` state is logged as `DEBUG`, every ~1s while the request is still active.

Rack::Timeout will try to use `Rails.logger` if present, otherwise it'll look for a logger in `env['rack.logger']`, and if neither are present, it'll create its own logger, either writing to `env['rack.errors']`, or to `$stderr` if the former is not set.

When creating its own logger, rack-timeout will use a log level of `INFO`. Otherwise whatever log level is already set on the logger being used continues in effect.

A custom logger can be set via `Rack::Timeout::Logger.logger`. This takes priority over the automatic logger detection:

```ruby
Rack::Timeout::Logger.logger = Logger.new
```

There are helper setters that replace the logger:

```ruby
Rack::Timeout::Logger.device = $stderr
Rack::Timeout::Logger.level  = Logger::INFO
```

Although each call replaces the logger, these can be use together and the final logger will retain both properties. (If only one is called, the defaults used above apply.)

Logging is enabled by default, but can be removed with:

```ruby
Rack::Timeout::Logger.disable
```

Each log line is a set of `key=value` pairs, containing the entries from the `env["rack-timeout.info"]` struct that are not `nil`. See the Request Lifetime section above for a description of each field. Note that while the values for `wait`, `timeout`, and `service` are stored internally as seconds, they are logged as milliseconds for readability.

A sample log excerpt might look like:

```
source=rack-timeout id=13793c wait=369ms timeout=10000ms state=ready at=info
source=rack-timeout id=13793c wait=369ms timeout=10000ms service=15ms state=completed at=info
source=rack-timeout id=ea7bd3 wait=371ms timeout=10000ms state=timed_out at=error
```
