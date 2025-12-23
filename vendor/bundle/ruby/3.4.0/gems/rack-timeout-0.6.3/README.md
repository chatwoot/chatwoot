Rack::Timeout
=============

Abort requests that are taking too long; an exception is raised.

A timeout of 15s is the default. It's recommended to set the timeout as
low as realistically viable for your application. You can modify this by
setting the `RACK_TIMEOUT_SERVICE_TIMEOUT` environment variable.

There's a handful of other settings, read on for details.

Rack::Timeout is not a solution to the problem of long-running requests,
it's a debug and remediation tool. App developers should track
rack-timeout's data and address recurring instances of particular
timeouts, for example by refactoring code so it runs faster or
offsetting lengthy work to happen asynchronously.

Upgrading
---------

For fixing issues when upgrading, please see [UPGRADING](UPGRADING.md).

Basic Usage
-----------

The following covers currently supported versions of Rails, Rack, Ruby,
and Bundler. See the Compatibility section at the end for legacy
versions.

### Rails apps

```ruby
# Gemfile
gem "rack-timeout"
```

This will load rack-timeout and set it up as a Rails middleware using
the default timeout of 15s. The middleware is not inserted for the test
environment. You can modify the timeout by setting a
`RACK_TIMEOUT_SERVICE_TIMEOUT` environment variable.

### Rails apps, manually

You'll need to do this if you removed `Rack::Runtime` from the
middleware stack, or if you want to determine yourself where in the
stack `Rack::Timeout` gets inserted.

```ruby
# Gemfile
gem "rack-timeout", require: "rack/timeout/base"
```

```ruby
# config/initializers/rack_timeout.rb

# insert middleware wherever you want in the stack, optionally pass
# initialization arguments, or use environment variables
Rails.application.config.middleware.insert_before Rack::Runtime, Rack::Timeout, service_timeout: 15
```

### Sinatra and other Rack apps

```ruby
# config.ru
require "rack-timeout"

# Call as early as possible so rack-timeout runs before all other middleware.
# Setting service_timeout or `RACK_TIMEOUT_SERVICE_TIMEOUT` environment
# variable is recommended. If omitted, defaults to 15 seconds.
use Rack::Timeout, service_timeout: 15
```

Configuring
-----------

Rack::Timeout takes the following settings, shown here with their
default values and associated environment variables.

```
service_timeout:   15     # RACK_TIMEOUT_SERVICE_TIMEOUT
wait_timeout:      30     # RACK_TIMEOUT_WAIT_TIMEOUT
wait_overtime:     60     # RACK_TIMEOUT_WAIT_OVERTIME
service_past_wait: false  # RACK_TIMEOUT_SERVICE_PAST_WAIT
term_on_timeout:   false  # RACK_TIMEOUT_TERM_ON_TIMEOUT
```

These settings can be overriden during middleware initialization or
environment variables `RACK_TIMEOUT_*` mentioned above. Middleware
parameters take precedence:

```ruby
use Rack::Timeout, service_timeout: 15, wait_timeout: 30
```

For more on these settings, please see [doc/settings](doc/settings.md).

Further Documentation
---------------------

Please see the [doc](doc) folder for further documentation on:

* [Risks and shortcomings of using Rack::Timeout](doc/risks.md)
* [Understanding the request lifecycle](doc/request-lifecycle.md)
* [Exceptions raised by Rack::Timeout](doc/exceptions.md)
* [Rollbar fingerprinting](doc/rollbar.md)
* [Observers](doc/observers.md)
* [Logging](doc/logging.md)

Compatibility
-------------

This version of Rack::Timeout is compatible with Ruby 2.1 and up, and,
for Rails apps, Rails 3.x and up.


---
Copyright © 2010-2020 Caio Chassot, released under the MIT license
<http://github.com/sharpstone/rack-timeout>
