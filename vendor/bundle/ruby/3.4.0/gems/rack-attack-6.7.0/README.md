:warning:  You are viewing the development's branch version of README which might contain documentation for unreleased features.
For the README consistent with the latest released version see https://github.com/rack/rack-attack/blob/6-stable/README.md.

# Rack::Attack

*Rack middleware for blocking & throttling abusive requests*

Protect your Rails and Rack apps from bad clients. Rack::Attack lets you easily decide when to *allow*, *block* and *throttle* based on properties of the request.

See the [Backing & Hacking blog post](https://www.kickstarter.com/backing-and-hacking/rack-attack-protection-from-abusive-clients) introducing Rack::Attack.

[![Gem Version](https://badge.fury.io/rb/rack-attack.svg)](https://badge.fury.io/rb/rack-attack)
[![build](https://github.com/rack/rack-attack/actions/workflows/build.yml/badge.svg)](https://github.com/rack/rack-attack/actions/workflows/build.yml)
[![Code Climate](https://codeclimate.com/github/kickstarter/rack-attack.svg)](https://codeclimate.com/github/kickstarter/rack-attack)
[![Join the chat at https://gitter.im/rack-attack/rack-attack](https://badges.gitter.im/rack-attack/rack-attack.svg)](https://gitter.im/rack-attack/rack-attack)

## Table of contents

- [Getting started](#getting-started)
  - [Installing](#installing)
  - [Plugging into the application](#plugging-into-the-application)
- [Usage](#usage)
  - [Safelisting](#safelisting)
    - [`safelist_ip(ip_address_string)`](#safelist_ipip_address_string)
    - [`safelist_ip(ip_subnet_string)`](#safelist_ipip_subnet_string)
    - [`safelist(name, &block)`](#safelistname-block)
  - [Blocking](#blocking)
    - [`blocklist_ip(ip_address_string)`](#blocklist_ipip_address_string)
    - [`blocklist_ip(ip_subnet_string)`](#blocklist_ipip_subnet_string)
    - [`blocklist(name, &block)`](#blocklistname-block)
    - [Fail2Ban](#fail2ban)
    - [Allow2Ban](#allow2ban)
  - [Throttling](#throttling)
    - [`throttle(name, options, &block)`](#throttlename-options-block)
  - [Tracks](#tracks)
  - [Cache store configuration](#cache-store-configuration)
- [Customizing responses](#customizing-responses)
  - [RateLimit headers for well-behaved clients](#ratelimit-headers-for-well-behaved-clients)
- [Logging & Instrumentation](#logging--instrumentation)
- [Testing](#testing)
- [How it works](#how-it-works)
  - [About Tracks](#about-tracks)
- [Performance](#performance)
- [Motivation](#motivation)
- [Contributing](#contributing)
- [Code of Conduct](#code-of-conduct)
- [Development setup](#development-setup)
- [License](#license)

## Getting started

### Installing

Add this line to your application's Gemfile:

```ruby
# In your Gemfile

gem 'rack-attack'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install rack-attack

### Plugging into the application

Then tell your ruby web application to use rack-attack as a middleware.

a) For __rails__ applications it is used by default.

You can disable it permanently (like for specific environment) or temporarily (can be useful for specific test cases) by writing:

```ruby
Rack::Attack.enabled = false
```

b) For __rack__ applications:

```ruby
# In config.ru

require "rack/attack"
use Rack::Attack
```

__IMPORTANT__: By default, rack-attack won't perform any blocking or throttling, until you specifically tell it what to protect against by configuring some rules.

## Usage

*Tip:* If you just want to get going asap, then you can take our [example configuration](docs/example_configuration.md)
and tailor it to your needs, or check out the [advanced configuration](docs/advanced_configuration.md) examples.

Define rules by calling `Rack::Attack` public methods, in any file that runs when your application is being initialized. For rails applications this means creating a new file named `config/initializers/rack_attack.rb` and writing your rules there.

### Safelisting

Safelists have the most precedence, so any request matching a safelist would be allowed despite matching any number of blocklists or throttles.

#### `safelist_ip(ip_address_string)`

E.g.

```ruby
# config/initializers/rack_attack.rb (for rails app)

Rack::Attack.safelist_ip("5.6.7.8")
```

#### `safelist_ip(ip_subnet_string)`

E.g.

```ruby
# config/initializers/rack_attack.rb (for rails app)

Rack::Attack.safelist_ip("5.6.7.0/24")
```

#### `safelist(name, &block)`

Name your custom safelist and make your ruby-block argument return a truthy value if you want the request to be allowed, and falsy otherwise.

The request object is a [Rack::Request](http://www.rubydoc.info/gems/rack/Rack/Request).

E.g.

```ruby
# config/initializers/rack_attack.rb (for rails apps)

# Provided that trusted users use an HTTP request header named APIKey
Rack::Attack.safelist("mark any authenticated access safe") do |request|
  # Requests are allowed if the return value is truthy
  request.env["HTTP_APIKEY"] == "secret-string"
end

# Always allow requests from localhost
# (blocklist & throttles are skipped)
Rack::Attack.safelist('allow from localhost') do |req|
  # Requests are allowed if the return value is truthy
  '127.0.0.1' == req.ip || '::1' == req.ip
end
```

### Blocking

#### `blocklist_ip(ip_address_string)`

E.g.

```ruby
# config/initializers/rack_attack.rb (for rails apps)

Rack::Attack.blocklist_ip("1.2.3.4")
```

#### `blocklist_ip(ip_subnet_string)`

E.g.

```ruby
# config/initializers/rack_attack.rb (for rails apps)

Rack::Attack.blocklist_ip("1.2.0.0/16")
```

#### `blocklist(name, &block)`

Name your custom blocklist and make your ruby-block argument return a truthy value if you want the request to be blocked, and falsy otherwise.

The request object is a [Rack::Request](http://www.rubydoc.info/gems/rack/Rack/Request).

E.g.

```ruby
# config/initializers/rack_attack.rb (for rails apps)

Rack::Attack.blocklist("block all access to admin") do |request|
  # Requests are blocked if the return value is truthy
  request.path.start_with?("/admin")
end

Rack::Attack.blocklist('block bad UA logins') do |req|
  req.path == '/login' && req.post? && req.user_agent == 'BadUA'
end
```

#### Fail2Ban

`Fail2Ban.filter` can be used within a blocklist to block all requests from misbehaving clients.
This pattern is inspired by [fail2ban](https://www.fail2ban.org/wiki/index.php/Main_Page).
See the [fail2ban documentation](https://www.fail2ban.org/wiki/index.php/MANUAL_0_8#Jail_Options) for more details on
how the parameters work.  For multiple filters, be sure to put each filter in a separate blocklist and use a unique discriminator for each fail2ban filter.

Fail2ban state is stored in a [configurable cache](#cache-store-configuration) (which defaults to `Rails.cache` if present).

```ruby
# Block suspicious requests for '/etc/password' or wordpress specific paths.
# After 3 blocked requests in 10 minutes, block all requests from that IP for 5 minutes.
Rack::Attack.blocklist('fail2ban pentesters') do |req|
  # `filter` returns truthy value if request fails, or if it's from a previously banned IP
  # so the request is blocked
  Rack::Attack::Fail2Ban.filter("pentesters-#{req.ip}", maxretry: 3, findtime: 10.minutes, bantime: 5.minutes) do
    # The count for the IP is incremented if the return value is truthy
    CGI.unescape(req.query_string) =~ %r{/etc/passwd} ||
    req.path.include?('/etc/passwd') ||
    req.path.include?('wp-admin') ||
    req.path.include?('wp-login')

  end
end
```

Note that `Fail2Ban` filters are not automatically scoped to the blocklist, so when using multiple filters in an application the scoping must be added to the discriminator e.g. `"pentest:#{req.ip}"`.

#### Allow2Ban

`Allow2Ban.filter` works the same way as the `Fail2Ban.filter` except that it *allows* requests from misbehaving
clients until such time as they reach maxretry at which they are cut off as per normal.

Allow2ban state is stored in a [configurable cache](#cache-store-configuration) (which defaults to `Rails.cache` if present).

```ruby
# Lockout IP addresses that are hammering your login page.
# After 20 requests in 1 minute, block all requests from that IP for 1 hour.
Rack::Attack.blocklist('allow2ban login scrapers') do |req|
  # `filter` returns false value if request is to your login page (but still
  # increments the count) so request below the limit are not blocked until
  # they hit the limit.  At that point, filter will return true and block.
  Rack::Attack::Allow2Ban.filter(req.ip, maxretry: 20, findtime: 1.minute, bantime: 1.hour) do
    # The count for the IP is incremented if the return value is truthy.
    req.path == '/login' and req.post?
  end
end
```

### Throttling

Throttle state is stored in a [configurable cache](#cache-store-configuration) (which defaults to `Rails.cache` if present).

#### `throttle(name, options, &block)`

Name your custom throttle, provide `limit` and `period` as options, and make your ruby-block argument return the __discriminator__. This discriminator is how you tell rack-attack whether you're limiting per IP address, per user email or any other.

The request object is a [Rack::Request](http://www.rubydoc.info/gems/rack/Rack/Request).

E.g.

```ruby
# config/initializers/rack_attack.rb (for rails apps)

Rack::Attack.throttle("requests by ip", limit: 5, period: 2) do |request|
  request.ip
end

# Throttle login attempts for a given email parameter to 6 reqs/minute
# Return the *normalized* email as a discriminator on POST /login requests
Rack::Attack.throttle('limit logins per email', limit: 6, period: 60) do |req|
  if req.path == '/login' && req.post?
    # Normalize the email, using the same logic as your authentication process, to
    # protect against rate limit bypasses.
    req.params['email'].to_s.downcase.gsub(/\s+/, "")
  end
end

# You can also set a limit and period using a proc. For instance, after
# Rack::Auth::Basic has authenticated the user:
limit_proc = proc { |req| req.env["REMOTE_USER"] == "admin" ? 100 : 1 }
period_proc = proc { |req| req.env["REMOTE_USER"] == "admin" ? 1 : 60 }

Rack::Attack.throttle('request per ip', limit: limit_proc, period: period_proc) do |request|
  request.ip
end
```

### Tracks

```ruby
# Track requests from a special user agent.
Rack::Attack.track("special_agent") do |req|
  req.user_agent == "SpecialAgent"
end

# Supports optional limit and period, triggers the notification only when the limit is reached.
Rack::Attack.track("special_agent", limit: 6, period: 60) do |req|
  req.user_agent == "SpecialAgent"
end

# Track it using ActiveSupport::Notification
ActiveSupport::Notifications.subscribe("track.rack_attack") do |name, start, finish, request_id, payload|
  req = payload[:request]
  if req.env['rack.attack.matched'] == "special_agent"
    Rails.logger.info "special_agent: #{req.path}"
    STATSD.increment("special_agent")
  end
end
```

### Cache store configuration

Throttle, allow2ban and fail2ban state is stored in a configurable cache (which defaults to `Rails.cache` if present), presumably backed by memcached or redis ([at least gem v3.0.0](https://rubygems.org/gems/redis)).

```ruby
# This is the default
Rack::Attack.cache.store = Rails.cache 
# It is recommended to use a separate database for throttling/allow2ban/fail2ban.
Rack::Attack.cache.store = ActiveSupport::Cache::RedisCacheStore.new(url: "...") 
```

Most applications should use a new, separate database used only for `rack-attack`. During an actual attack or periods of heavy load, this database will come under heavy load. Keeping it on a separate database instance will give you additional resilience and make sure that other functions (like caching for your application) don't go down.

Note that `Rack::Attack.cache` is only used for throttling, allow2ban and fail2ban filtering; not blocklisting and safelisting. Your cache store must implement `increment` and `write` like [ActiveSupport::Cache::Store](http://api.rubyonrails.org/classes/ActiveSupport/Cache/Store.html). This means that other cache stores which inherit from ActiveSupport::Cache::Store are also compatible. In-memory stores which are not backed by an external database, such as `ActiveSupport::Cache::MemoryStore.new`, will be mostly ineffective because each Ruby process in your deployment will have it's own state, effectively multiplying the number of requests each client can make by the number of Ruby processes you have deployed.

## Customizing responses

Customize the response of blocklisted and throttled requests using an object that adheres to the [Rack app interface](http://www.rubydoc.info/github/rack/rack/file/SPEC.rdoc).

```ruby
Rack::Attack.blocklisted_responder = lambda do |request|
  # Using 503 because it may make attacker think that they have successfully
  # DOSed the site. Rack::Attack returns 403 for blocklists by default
  [ 503, {}, ['Blocked']]
end

Rack::Attack.throttled_responder = lambda do |request|
  # NB: you have access to the name and other data about the matched throttle
  #  request.env['rack.attack.matched'],
  #  request.env['rack.attack.match_type'],
  #  request.env['rack.attack.match_data'],
  #  request.env['rack.attack.match_discriminator']

  # Using 503 because it may make attacker think that they have successfully
  # DOSed the site. Rack::Attack returns 429 for throttling by default
  [ 503, {}, ["Server Error\n"]]
end
```

### RateLimit headers for well-behaved clients

While Rack::Attack's primary focus is minimizing harm from abusive clients, it
can also be used to return rate limit data that's helpful for well-behaved clients.

If you want to return to user how many seconds to wait until they can start sending requests again, this can be done through enabling `Retry-After` header:
```ruby
Rack::Attack.throttled_response_retry_after_header = true
```

Here's an example response that includes conventional `RateLimit-*` headers:

```ruby
Rack::Attack.throttled_responder = lambda do |request|
  match_data = request.env['rack.attack.match_data']
  now = match_data[:epoch_time]

  headers = {
    'RateLimit-Limit' => match_data[:limit].to_s,
    'RateLimit-Remaining' => '0',
    'RateLimit-Reset' => (now + (match_data[:period] - now % match_data[:period])).to_s
  }

  [ 429, headers, ["Throttled\n"]]
end
```


For responses that did not exceed a throttle limit, Rack::Attack annotates the env with match data:

```ruby
request.env['rack.attack.throttle_data'][name] # => { discriminator: d, count: n, period: p, limit: l, epoch_time: t }
```

## Logging & Instrumentation

Rack::Attack uses the [ActiveSupport::Notifications](http://api.rubyonrails.org/classes/ActiveSupport/Notifications.html) API if available.

You can subscribe to `rack_attack` events and log it, graph it, etc.

To get notified about specific type of events, subscribe to the event name followed by the `rack_attack` namespace.
E.g. for throttles use:

```ruby
ActiveSupport::Notifications.subscribe("throttle.rack_attack") do |name, start, finish, request_id, payload|
  # request object available in payload[:request]

  # Your code here
end
```

If you want to subscribe to every `rack_attack` event, use:

```ruby
ActiveSupport::Notifications.subscribe(/rack_attack/) do |name, start, finish, request_id, payload|
  # request object available in payload[:request]

  # Your code here
end
```

## Testing

A note on developing and testing apps using Rack::Attack - if you are using throttling in particular, you will
need to enable the cache in your development environment. See [Caching with Rails](http://guides.rubyonrails.org/caching_with_rails.html)
for more on how to do this.

### Disabling

`Rack::Attack.enabled = false` can be used to either completely disable Rack::Attack in your tests, or to disable/enable for specific test cases only.

### Test case isolation

`Rack::Attack.reset!` can be used in your test suite to clear any Rack::Attack state between different test cases. If you're testing blocklist and safelist configurations, consider using `Rack::Attack.clear_configuration` to unset the values for those lists between test cases.

## How it works

The Rack::Attack middleware compares each request against *safelists*, *blocklists*, *throttles*, and *tracks* that you define. There are none by default.

 * If the request matches any **safelist**, it is allowed.
 * Otherwise, if the request matches any **blocklist**, it is blocked.
 * Otherwise, if the request matches any **throttle**, a counter is incremented in the Rack::Attack.cache. If any throttle's limit is exceeded, the request is blocked.
 * Otherwise, all **tracks** are checked, and the request is allowed.

The algorithm is actually more concise in code: See [Rack::Attack.call](lib/rack/attack.rb):

```ruby
def call(env)
  req = Rack::Attack::Request.new(env)

  if safelisted?(req)
    @app.call(env)
  elsif blocklisted?(req)
    self.class.blocklisted_responder.call(req)
  elsif throttled?(req)
    self.class.throttled_responder.call(req)
  else
    tracked?(req)
    @app.call(env)
  end
end
```

Note: `Rack::Attack::Request` is just a subclass of `Rack::Request` so that you
can cleanly monkey patch helper methods onto the
[request object](lib/rack/attack/request.rb).

### About Tracks

`Rack::Attack.track` doesn't affect request processing. Tracks are an easy way to log and measure requests matching arbitrary attributes.

## Performance

The overhead of running Rack::Attack is typically negligible (a few milliseconds per request),
but it depends on how many checks you've configured, and how long they take.
Throttles usually require a network roundtrip to your cache server(s),
so try to keep the number of throttle checks per request low.

If a request is blocklisted or throttled, the response is a very simple Rack response.
A single typical ruby web server thread can block several hundred requests per second.

Rack::Attack complements tools like `iptables` and nginx's [limit_conn_zone module](https://nginx.org/en/docs/http/ngx_http_limit_conn_module.html#limit_conn_zone).

## Motivation

Abusive clients range from malicious login crackers to naively-written scrapers.
They hinder the security, performance, & availability of web applications.

It is impractical if not impossible to block abusive clients completely.

Rack::Attack aims to let developers quickly mitigate abusive requests and rely
less on short-term, one-off hacks to block a particular attack.

## Contributing

Check out the [Contributing guide](CONTRIBUTING.md).

## Code of Conduct

This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Code of Conduct](CODE_OF_CONDUCT.md).

## Development setup

Check out the [Development guide](docs/development.md).

## License

Copyright Kickstarter, PBC.

Released under an [MIT License](https://opensource.org/licenses/MIT).
