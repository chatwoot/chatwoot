# RedisClient

`redis-client` is a simple, low-level, client for Redis 6+.

Contrary to the `redis` gem, `redis-client` doesn't try to map all Redis commands to Ruby constructs,
it merely is a thin wrapper on top of the RESP3 protocol.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'redis-client'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install redis-client

## Usage

To use `RedisClient` you first define a connection configuration, from which you can create a connection pool:

```ruby
redis_config = RedisClient.config(host: "10.0.1.1", port: 6380, db: 15)
redis = redis_config.new_pool(timeout: 0.5, size: Integer(ENV.fetch("RAILS_MAX_THREADS", 5)))

redis.call("PING") # => "PONG"
```

If you are issuing multiple commands in a raw, but can't pipeline them, it's best to use `#with` to avoid going through the connection checkout
several times:

```ruby
redis.with do |r|
  r.call("SET", "mykey", "hello world") # => "OK"
  r.call("GET", "mykey") # => "hello world"
end
```

If you are working in a single-threaded environment, or wish to use your own connection pooling mechanism,
you can obtain a raw client with `#new_client`

```ruby
redis_config = RedisClient.config(host: "10.0.1.1", port: 6380, db: 15)
redis = redis_config.new_client
redis.call("PING") # => "PONG"
```

NOTE: Raw `RedisClient` instances must not be shared between threads. Make sure to read the section on [thread safety](#thread-safety).

For simple use cases where only a single connection is needed, you can use the `RedisClient.new` shortcut:

```ruby
redis = RedisClient.new
redis.call("GET", "mykey")
```

### Configuration

- `url`: A Redis connection URL, e.g. `redis://example.com:6379/5` - a `rediss://` scheme enables SSL, and the path is interpreted as a database number.
  To connect to UNIX domain sockets, the `url` can also just be a path, and the database specified as query parameter: `/run/redis/foo.sock?db=5`, or optionally
  have a `unix://` scheme: `unix:///run/redis/foo.sock?db=5`
  Note that all other configurations take precedence, e.g. `RedisClient.config(url: "redis://localhost:3000", port: 6380)` will connect on port `6380`.
- `host`: The server hostname or IP address. Defaults to `"localhost"`.
- `port`: The server port. Defaults to `6379`.
- `path`: The path to a UNIX socket, if set `url`, `host` and `port` are ignored.
- `ssl`: Whether to connect using SSL or not.
- `ssl_params`: A configuration Hash passed to [`OpenSSL::SSL::SSLContext#set_params`](https://www.rubydoc.info/stdlib/openssl/OpenSSL%2FSSL%2FSSLContext:set_params), notable options include:
  - `cert`: The path to the client certificate (e.g. `client.crt`).
  - `key`: The path to the client key (e.g. `client.key`).
  - `ca_file`: The certificate authority to use, useful for self-signed certificates (e.g. `ca.crt`),
- `db`: The database to select after connecting, defaults to `0`.
- `id` ID for the client connection, assigns name to current connection by sending `CLIENT SETNAME`.
- `username` Username to authenticate against server, defaults to `"default"`.
- `password` Password to authenticate against server.
- `timeout`: The general timeout in seconds, default to `1.0`.
- `connect_timeout`: The connection timeout, takes precedence over the general timeout when connecting to the server.
- `read_timeout`: The read timeout, takes precedence over the general timeout when reading responses from the server.
- `write_timeout`: The write timeout, takes precedence over the general timeout when sending commands to the server.
- `reconnect_attempts`: Specify how many times the client should retry to send queries. Defaults to `0`. Makes sure to read the [reconnection section](#reconnection) before enabling it.
- `circuit_breaker`: A Hash with circuit breaker configuration. Defaults to `nil`. See the [circuit breaker section](#circuit-breaker) for details.
- `protocol:` The version of the RESP protocol to use. Default to `3`.
- `custom`: A user-owned value ignored by `redis-client` but available as `Config#custom`. This can be used to hold middleware configurations and other user-specific metadata.

### Sentinel support

The client is able to perform automatic failover by using [Redis Sentinel](https://redis.io/docs/manual/sentinel/).

To connect using Sentinel, use:

```ruby
redis_config = RedisClient.sentinel(
  name: "mymaster",
  sentinels: [
    { host: "127.0.0.1", port: 26380 },
    { host: "127.0.0.1", port: 26381 },
  ],
  role: :master,
)
```

or:

```ruby
redis_config = RedisClient.sentinel(
  name: "mymaster",
  sentinels: [
    "redis://127.0.0.1:26380",
    "redis://127.0.0.1:26381",
  ],
  role: :master,
)
```

* The name identifies a group of Redis instances composed of a master and one or more replicas (`mymaster` in the example).

* It is possible to optionally provide a role. The allowed roles are `:master`
and `:replica`. When the role is `:replica`, the client will try to connect to a
random replica of the specified master. If a role is not specified, the client
will connect to the master.

* When using the Sentinel support you need to specify a list of sentinels to
connect to. The list does not need to enumerate all your Sentinel instances,
but a few so that if one is down the client will try the next one. The client
is able to remember the last Sentinel that was able to reply correctly and will
use it for the next requests.

To [authenticate](https://redis.io/docs/management/sentinel/#configuring-sentinel-instances-with-authentication) Sentinel itself, you can specify the `sentinel_username` and `sentinel_password` options per instance. Exclude the `sentinel_username` option if you're using password-only authentication.

```ruby
SENTINELS = [{ host: '127.0.0.1', port: 26380},
             { host: '127.0.0.1', port: 26381}]

redis_config = RedisClient.sentinel(name: 'mymaster', sentinel_username: 'appuser', sentinel_password: 'mysecret', sentinels: SENTINELS, role: :master)
```

If you specify a username and/or password at the top level for your main Redis instance, Sentinel *will not* using thouse credentials

```ruby
# Use 'mysecret' to authenticate against the mymaster instance, but skip authentication for the sentinels:
SENTINELS = [{ host: '127.0.0.1', port: 26380 },
             { host: '127.0.0.1', port: 26381 }]

redis_config = RedisClient.sentinel(name: 'mymaster', sentinels: SENTINELS, role: :master, password: 'mysecret')
```

So you have to provide Sentinel credential and Redis explicitly even they are the same

```ruby
# Use 'mysecret' to authenticate against the mymaster instance and sentinel
SENTINELS = [{ host: '127.0.0.1', port: 26380 },
             { host: '127.0.0.1', port: 26381 }]

redis_config = RedisClient.sentinel(name: 'mymaster', sentinels: SENTINELS, role: :master, password: 'mysecret', sentinel_password: 'mysecret')
```

Also the `name`, `password`, `username` and `db` for Redis instance can be passed as an url:

```ruby
redis_config = RedisClient.sentinel(url: "redis://appuser:mysecret@mymaster/10", sentinels: SENTINELS, role: :master)
```

### Type support

Only a select few Ruby types are supported as arguments beside strings.

Integer and Float are supported:

```ruby
redis.call("SET", "mykey", 42)
redis.call("SET", "mykey", 1.23)
```

is equivalent to:

```ruby
redis.call("SET", "mykey", 42.to_s)
redis.call("SET", "mykey", 1.23.to_s)
```

Arrays are flattened as arguments:

```ruby
redis.call("LPUSH", "list", [1, 2, 3], 4)
```

is equivalent to:

```ruby
redis.call("LPUSH", "list", "1", "2", "3", "4")
```

Hashes are flattened as well:

```ruby
redis.call("HMSET", "hash", { "foo" => "1", "bar" => "2" })
```

is equivalent to:

```ruby
redis.call("HMSET", "hash", "foo", "1", "bar", "2")
```

Any other type requires the caller to explicitly cast the argument as a string.

Keywords arguments are treated as Redis command flags:

```ruby
redis.call("SET", "mykey", "value", nx: true, ex: 60)
redis.call("SET", "mykey", "value", nx: false, ex: nil)
```

is equivalent to:

```ruby
redis.call("SET", "mykey", "value", "nx", "ex", "60")
redis.call("SET", "mykey", "value")
```

If flags are built dynamically, you'll have to explicitly pass them as keyword arguments with `**`:

```ruby
flags = {}
flags[:nx] = true if something?
redis.call("SET", "mykey", "value", **flags)
```

**Important Note**: because of the keyword argument semantic change between Ruby 2 and Ruby 3,
unclosed hash literals with string keys may be interpreted differently:

```ruby
redis.call("HMSET", "hash", "foo" => "bar")
```

On Ruby 2 `"foo" => "bar"` will be passed as a positional argument, but on Ruby 3 it will be interpreted as keyword
arguments. To avoid such problem, make sure to enclose hash literals:

```ruby
redis.call("HMSET", "hash", { "foo" => "bar" })
```

### Commands return values

Contrary to the `redis` gem, `redis-client` doesn't do any type casting on the return value of commands.

If you wish to cast the return value, you can pass a block to the `#call` family of methods:

```ruby
redis.call("INCR", "counter") # => 1
redis.call("GET", "counter") # => "1"
redis.call("GET", "counter", &:to_i) # => 1

redis.call("EXISTS", "counter") # => 1
redis.call("EXISTS", "counter") { |c| c > 0 } # => true
```

### `*_v` methods

In some it's more convenient to pass commands as arrays, for that `_v` versions of `call` methods are available.

```ruby
redis.call_v(["MGET"] + keys)
redis.blocking_call_v(1, ["MGET"] + keys)
redis.call_once_v(1, ["MGET"] + keys)
```

### Blocking commands

For blocking commands such as `BRPOP`, a custom timeout duration can be passed as first argument of the `#blocking_call` method:

```
redis.blocking_call(timeout, "BRPOP", "key", 0)
```

If `timeout` is reached, `#blocking_call` raises `RedisClient::ReadTimeoutError` and doesn't retry regardless of the `reconnect_attempts` configuration.

`timeout` is expressed in seconds, you can pass `false` or `0` to mean no timeout.

### Scan commands

For easier use of the [`SCAN` family of commands](https://redis.io/commands/scan), `#scan`, `#sscan`, `#hscan` and `#zscan` methods are provided

```ruby
redis.scan("MATCH", "pattern:*") do |key|
  ...
end
```

```ruby
redis.sscan("myset", "MATCH", "pattern:*") do |key|
  ...
end
```

For `HSCAN` and `ZSCAN`, pairs are yielded

```ruby
redis.hscan("myhash", "MATCH", "pattern:*") do |key, value|
  ...
end
```

```ruby
redis.zscan("myzset") do |element, score|
  ...
end
```

In all cases the `cursor` parameter must be omitted and starts at `0`.

### Pipelining

When multiple commands are executed sequentially, but are not dependent, the calls can be pipelined.
This means that the client doesn't wait for reply of the first command before sending the next command.
The advantage is that multiple commands are sent at once, resulting in faster overall execution.

The client can be instructed to pipeline commands by using the `#pipelined method`.
After the block is executed, the client sends all commands to Redis and gathers their replies.
These replies are returned by the `#pipelined` method.

```ruby
redis.pipelined do |pipeline|
  pipeline.call("SET", "foo", "bar") # => nil
  pipeline.call("INCR", "baz") # => nil
end
# => ["OK", 1]
```

#### Exception management

The `exception` flag in the `#pipelined` method of `RedisClient` is a feature that modifies the pipeline execution
behavior. When set to `false`, it doesn't raise an exception when a command error occurs. Instead, it allows the
pipeline to execute all commands, and any failed command will be available in the returned array. (Defaults to `true`)

```ruby
results = redis.pipelined(exception: false) do |pipeline|
  pipeline.call("SET", "foo", "bar") # => nil
  pipeline.call("DOESNOTEXIST", 12) # => nil
  pipeline.call("INCR", "baz") # => nil
end
# results => ["OK", #<RedisClient::CommandError: ERR unknown command 'DOESNOTEXIST', with args beginning with: '12'>, 2]

results.each do |result|
  if result.is_a?(RedisClient::CommandError)
    # Do something with the failed result
  end
end
```

### Transactions

You can use [`MULTI/EXEC` to run a number of commands in an atomic fashion](https://redis.io/topics/transactions).
This is similar to executing a pipeline, but the commands are
preceded by a call to `MULTI`, and followed by a call to `EXEC`. Like
the regular pipeline, the replies to the commands are returned by the
`#multi` method.

```ruby
redis.multi do |transaction|
  transaction.call("SET", "foo", "bar") # => nil
  transaction.call("INCR", "baz") # => nil
end
# => ["OK", 1]
```

For optimistic locking, the watched keys can be passed to the `#multi` method:

```ruby
redis.multi(watch: ["title"]) do |transaction|
  title = redis.call("GET", "title")
  transaction.call("SET", "title", title.upcase)
end
# => ["OK"] / nil
```

If the transaction wasn't successful, `#multi` will return `nil`.

Note that transactions using optimistic locking aren't automatically retried upon connection errors.

### Publish / Subscribe

Pub/Sub related commands must be called on a dedicated `PubSub` object:

```ruby
redis = RedisClient.new
pubsub = redis.pubsub
pubsub.call("SUBSCRIBE", "channel-1", "channel-2")

loop do
  if message = pubsub.next_event(timeout)
    message # => ["subscribe", "channel-1", 1]
  else
    # no new message was received in the allocated timeout
  end
end
```

*Note*: pubsub connections are stateful, as such they won't ever reconnect automatically.
The caller is responsible for reconnecting if the connection is lost and to resubscribe to
all channels.

## Production

### Instrumentation and Middlewares

`redis-client` offers a public middleware API to aid in monitoring and library extension. Middleware can be registered
either globally or on a given configuration instance.

```ruby
module MyGlobalRedisInstrumentation
  def connect(redis_config)
    MyMonitoringService.instrument("redis.connect") { super }
  end

  def call(command, redis_config)
    MyMonitoringService.instrument("redis.query") { super }
  end

  def call_pipelined(commands, redis_config)
    MyMonitoringService.instrument("redis.pipeline") { super }
  end
end
RedisClient.register(MyGlobalRedisInstrumentation)
```

Note that `RedisClient.register` is global and apply to all `RedisClient` instances.

To add middlewares to only a single client, you can provide them when creating the config:

```ruby
redis_config = RedisClient.config(middlewares: [AnotherRedisInstrumentation])
redis_config.new_client
```

If middlewares need a client-specific configuration, `Config#custom` can be used

```ruby
module MyGlobalRedisInstrumentation
  def connect(redis_config)
    MyMonitoringService.instrument("redis.connect", tags: redis_config.custom[:tags]) { super }
  end

  def call(command, redis_config)
    MyMonitoringService.instrument("redis.query", tags: redis_config.custom[:tags]) { super }
  end

  def call_pipelined(commands, redis_config)
    MyMonitoringService.instrument("redis.pipeline", tags: redis_config.custom[:tags]) { super }
  end
end
RedisClient.register(MyGlobalRedisInstrumentation)

redis_config = RedisClient.config(custom: { tags: { "environment": Rails.env }})
```
### Timeouts

The client allows you to configure connect, read, and write timeouts.
Passing a single `timeout` option will set all three values:

```ruby
RedisClient.config(timeout: 1).new
```

But you can use specific values for each of them:

```ruby
RedisClient.config(
  connect_timeout: 0.2,
  read_timeout: 1.0,
  write_timeout: 0.5,
).new
```

All timeout values are specified in seconds.

### Reconnection

`redis-client` support automatic reconnection after network errors via the `reconnect_attempts:` configuration option.

It can be set as a number of retries:

```ruby
redis_config = RedisClient.config(reconnect_attempts: 1)
```

**Important Note**: Retrying may cause commands to be issued more than once to the server, so in the case of
non-idempotent commands such as `LPUSH` or `INCR`, it may cause consistency issues.

To selectively disable automatic retries, you can use the `#call_once` method:

```ruby
redis_config = RedisClient.config(reconnect_attempts: 3)
redis = redis_config.new_client
redis.call("GET", "counter") # Will be retried up to 3 times.
redis.call_once("INCR", "counter") # Won't be retried.
```

**Note**: automatic reconnection doesn't apply to pubsub clients as their connection is stateful.

### Exponential backoff

Alternatively, `reconnect_attempts` accepts a list of sleep durations for implementing exponential backoff:

```ruby
redis_config = RedisClient.config(reconnect_attempts: [0, 0.05, 0.1])
```

This configuration is generally used when the Redis server is expected to failover or recover relatively quickly and
that it's not really possible to continue without issuing the command.

When the Redis server is used as an ephemeral cache, circuit breakers are generally preferred.

### Circuit Breaker

When Redis is used as a cache and a connection error happens, you may not want to retry as it might take
longer than to recompute the value. Instead it's likely preferable to mark the server as unavailable and let it
recover for a while.

[Circuit breakers are a pattern that does exactly that](https://en.wikipedia.org/wiki/Circuit_breaker_design_pattern).

Configuration options:

  - `error_threshold`. The amount of errors to encounter within `error_threshold_timeout` amount of time before opening the circuit, that is to start rejecting requests instantly.
  - `error_threshold_timeout`. The amount of time in seconds that `error_threshold` errors must occur to open the circuit. Defaults to `error_timeout` seconds if not set.
  - `error_timeout`. The amount of time in seconds until trying to query the resource again.
  - `success_threshold`. The amount of successes on the circuit until closing it again, that is to start accepting all requests to the circuit.

```ruby
RedisClient.config(
  circuit_breaker: {
    # Stop querying the server after 3 errors happened in a 2 seconds window
    error_threshold: 3,
    error_threshold_timeout: 2,

    # Try querying again after 1 second
    error_timeout: 1,

    # Stay in half-open state until 3 queries succeeded.
    success_threshold: 3,
  }
)
```

### Drivers

`redis-client` ships with a pure Ruby socket implementation.

For increased performance, you can enable the `hiredis` binding by adding `hiredis-client` to your Gemfile:

```ruby
gem "hiredis-client"
```

The hiredis binding is only available on Linux, macOS and other POSIX platforms. You can install the gem on other platforms, but it won't have any effect.

The default driver can be set through `RedisClient.default_driver=`:

## Notable differences with the `redis` gem

### Thread Safety

Contrary to the `redis` gem, `redis-client` doesn't protect against concurrent access.
To use `redis-client` in concurrent environments, you MUST use a connection pool, or
have one client per Thread or Fiber.

## Development

After checking out the repo, run `bin/setup` to install dependencies. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/redis-rb/redis-client.
