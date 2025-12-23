# redis-rb [![Build Status][gh-actions-image]][gh-actions-link] [![Inline docs][inchpages-image]][inchpages-link]

A Ruby client that tries to match [Redis][redis-home]' API one-to-one, while still providing an idiomatic interface.

See [RubyDoc.info][rubydoc] for the API docs of the latest published gem.

## Getting started

Install with:

```
$ gem install redis
```

You can connect to Redis by instantiating the `Redis` class:

```ruby
require "redis"

redis = Redis.new
```

This assumes Redis was started with a default configuration, and is
listening on `localhost`, port 6379. If you need to connect to a remote
server or a different port, try:

```ruby
redis = Redis.new(host: "10.0.1.1", port: 6380, db: 15)
```

You can also specify connection options as a [`redis://` URL][redis-url]:

```ruby
redis = Redis.new(url: "redis://:p4ssw0rd@10.0.1.1:6380/15")
```

The client expects passwords with special chracters to be URL-encoded (i.e.
`CGI.escape(password)`).

To connect to Redis listening on a Unix socket, try:

```ruby
redis = Redis.new(path: "/tmp/redis.sock")
```

To connect to a password protected Redis instance, use:

```ruby
redis = Redis.new(password: "mysecret")
```

To connect a Redis instance using [ACL](https://redis.io/topics/acl), use:

```ruby
redis = Redis.new(username: 'myname', password: 'mysecret')
```

The Redis class exports methods that are named identical to the commands
they execute. The arguments these methods accept are often identical to
the arguments specified on the [Redis website][redis-commands]. For
instance, the `SET` and `GET` commands can be called like this:

```ruby
redis.set("mykey", "hello world")
# => "OK"

redis.get("mykey")
# => "hello world"
```

All commands, their arguments, and return values are documented and
available on [RubyDoc.info][rubydoc].

## Connection Pooling and Thread safety

The client does not provide connection pooling. Each `Redis` instance
has one and only one connection to the server, and use of this connection
is protected by a mutex.

As such it is heavilly recommended to use the [`connection_pool` gem](https://github.com/mperham/connection_pool), e.g.:

```ruby
module MyApp
  def self.redis
    @redis ||= ConnectionPool::Wrapper.new do
      Redis.new(url: ENV["REDIS_URL"])
    end
  end
end

MyApp.redis.incr("some-counter")
```

## Sentinel support

The client is able to perform automatic failover by using [Redis
Sentinel](http://redis.io/topics/sentinel).  Make sure to run Redis 2.8+
if you want to use this feature.

To connect using Sentinel, use:

```ruby
SENTINELS = [{ host: "127.0.0.1", port: 26380 },
             { host: "127.0.0.1", port: 26381 }]

redis = Redis.new(url: "redis://mymaster", sentinels: SENTINELS, role: :master)
```

* The master name identifies a group of Redis instances composed of a master
and one or more slaves (`mymaster` in the example).

* It is possible to optionally provide a role. The allowed roles are `master`
and `slave`. When the role is `slave`, the client will try to connect to a
random slave of the specified master. If a role is not specified, the client
will connect to the master.

* When using the Sentinel support you need to specify a list of sentinels to
connect to. The list does not need to enumerate all your Sentinel instances,
but a few so that if one is down the client will try the next one. The client
is able to remember the last Sentinel that was able to reply correctly and will
use it for the next requests.

If you want to [authenticate](https://redis.io/topics/sentinel#configuring-sentinel-instances-with-authentication) Sentinel itself, you must specify the `password` option per instance.

```ruby
SENTINELS = [{ host: '127.0.0.1', port: 26380, password: 'mysecret' },
             { host: '127.0.0.1', port: 26381, password: 'mysecret' }]

redis = Redis.new(name: 'mymaster', sentinels: SENTINELS, role: :master)
```

## Cluster support

[Clustering](https://redis.io/topics/cluster-spec). is supported via the [`redis-clustering` gem](cluster/).

## Pipelining

When multiple commands are executed sequentially, but are not dependent,
the calls can be *pipelined*. This means that the client doesn't wait
for reply of the first command before sending the next command. The
advantage is that multiple commands are sent at once, resulting in
faster overall execution.

The client can be instructed to pipeline commands by using the
`#pipelined` method. After the block is executed, the client sends all
commands to Redis and gathers their replies. These replies are returned
by the `#pipelined` method.

```ruby
redis.pipelined do |pipeline|
  pipeline.set "foo", "bar"
  pipeline.incr "baz"
end
# => ["OK", 1]
```

Commands must be called on the yielded objects. If you call methods
on the original client objects from inside a pipeline, they will be sent immediately:

```ruby
redis.pipelined do |pipeline|
  pipeline.set "foo", "bar"
  redis.incr "baz" # => 1
end
# => ["OK"]
```

### Executing commands atomically

You can use `MULTI/EXEC` to run a number of commands in an atomic
fashion. This is similar to executing a pipeline, but the commands are
preceded by a call to `MULTI`, and followed by a call to `EXEC`. Like
the regular pipeline, the replies to the commands are returned by the
`#multi` method.

```ruby
redis.multi do |transaction|
  transaction.set "foo", "bar"
  transaction.incr "baz"
end
# => ["OK", 1]
```

### Futures

Replies to commands in a pipeline can be accessed via the *futures* they
emit. All calls on the pipeline object return a
`Future` object, which responds to the `#value` method. When the
pipeline has successfully executed, all futures are assigned their
respective replies and can be used.

```ruby
set = incr = nil
redis.pipelined do |pipeline|
  set = pipeline.set "foo", "bar"
  incr = pipeline.incr "baz"
end

set.value
# => "OK"

incr.value
# => 1
```

## Error Handling

In general, if something goes wrong you'll get an exception. For example, if
it can't connect to the server a `Redis::CannotConnectError` error will be raised.

```ruby
begin
  redis.ping
rescue Redis::BaseError => e
  e.inspect
# => #<Redis::CannotConnectError: Timed out connecting to Redis on 10.0.1.1:6380>

  e.message
# => Timed out connecting to Redis on 10.0.1.1:6380
end
```

See lib/redis/errors.rb for information about what exceptions are possible.

## Timeouts

The client allows you to configure connect, read, and write timeouts.
Passing a single `timeout` option will set all three values:

```ruby
Redis.new(:timeout => 1)
```

But you can use specific values for each of them:

```ruby
Redis.new(
  :connect_timeout => 0.2,
  :read_timeout    => 1.0,
  :write_timeout   => 0.5
)
```

All timeout values are specified in seconds.

When using pub/sub, you can subscribe to a channel using a timeout as well:

```ruby
redis = Redis.new(reconnect_attempts: 0)
redis.subscribe_with_timeout(5, "news") do |on|
  on.message do |channel, message|
    # ...
  end
end
```

If no message is received after 5 seconds, the client will unsubscribe.

## Reconnections

**By default**, this gem will only **retry a connection once** and then fail, but
the client allows you to configure how many `reconnect_attempts` it should
complete before declaring a connection as failed.

```ruby
Redis.new(reconnect_attempts: 0)
Redis.new(reconnect_attempts: 3)
```

If you wish to wait between reconnection attempts, you can instead pass a list
of durations:

```ruby
Redis.new(reconnect_attempts: [
  0, # retry immediately
  0.25, # retry a second time after 250ms
  1, # retry a third and final time after another 1s
])
```

If you wish to disable reconnection only for some commands, you can use
`disable_reconnection`:

```ruby
redis.get("some-key") # this may be retried
redis.disable_reconnection do
  redis.incr("some-counter") # this won't be retried.
end
```

## SSL/TLS Support

To enable SSL support, pass the `:ssl => true` option when configuring the
Redis client, or pass in `:url => "rediss://..."` (like HTTPS for Redis).
You will also need to pass in an `:ssl_params => { ... }` hash used to
configure the `OpenSSL::SSL::SSLContext` object used for the connection:

```ruby
redis = Redis.new(
  :url        => "rediss://:p4ssw0rd@10.0.1.1:6381/15",
  :ssl_params => {
    :ca_file => "/path/to/ca.crt"
  }
)
```

The options given to `:ssl_params` are passed directly to the
`OpenSSL::SSL::SSLContext#set_params` method and can be any valid attribute
of the SSL context. Please see the [OpenSSL::SSL::SSLContext documentation]
for all of the available attributes.

Here is an example of passing in params that can be used for SSL client
certificate authentication (a.k.a. mutual TLS):

```ruby
redis = Redis.new(
  :url        => "rediss://:p4ssw0rd@10.0.1.1:6381/15",
  :ssl_params => {
    :ca_file => "/path/to/ca.crt",
    :cert    => OpenSSL::X509::Certificate.new(File.read("client.crt")),
    :key     => OpenSSL::PKey::RSA.new(File.read("client.key"))
  }
)
```

[OpenSSL::SSL::SSLContext documentation]: http://ruby-doc.org/stdlib-2.5.0/libdoc/openssl/rdoc/OpenSSL/SSL/SSLContext.html

## Expert-Mode Options

 - `inherit_socket: true`: disable safety check that prevents a forked child
   from sharing a socket with its parent; this is potentially useful in order to mitigate connection churn when:
    - many short-lived forked children of one process need to talk
      to redis, AND
    - your own code prevents the parent process from using the redis
      connection while a child is alive

   Improper use of `inherit_socket` will result in corrupted and/or incorrect
   responses.

## hiredis binding

By default, redis-rb uses Ruby's socket library to talk with Redis.

The hiredis driver uses the connection facility of hiredis-rb. In turn,
hiredis-rb is a binding to the official hiredis client library. It
optimizes for speed, at the cost of portability. Because it is a C
extension, JRuby is not supported (by default).

It is best to use hiredis when you have large replies (for example:
`LRANGE`, `SMEMBERS`, `ZRANGE`, etc.) and/or use big pipelines.

In your Gemfile, include `hiredis-client`:

```ruby
gem "redis"
gem "hiredis-client"
```

If your application doesn't call `Bundler.require`, you may have
to require it explictly:

```ruby
require "hiredis-client"
````

This makes the hiredis driver the default.

If you want to be certain hiredis is being used, when instantiating
the client object, specify hiredis:

```ruby
redis = Redis.new(driver: :hiredis)
```

## Testing

This library is tested against recent Ruby and Redis versions.
Check [Github Actions][gh-actions-link] for the exact versions supported.

## See Also

- [async-redis](https://github.com/socketry/async-redis) — An [async](https://github.com/socketry/async) compatible Redis client.

## Contributors

Several people contributed to redis-rb, but we would like to especially
mention Ezra Zygmuntowicz. Ezra introduced the Ruby community to many
new cool technologies, like Redis. He wrote the first version of this
client and evangelized Redis in Rubyland. Thank you, Ezra.

## Contributing

[Fork the project](https://github.com/redis/redis-rb) and send pull
requests.


[inchpages-image]:  https://inch-ci.org/github/redis/redis-rb.svg
[inchpages-link]:   https://inch-ci.org/github/redis/redis-rb
[redis-commands]:   https://redis.io/commands
[redis-home]:       https://redis.io
[redis-url]:        http://www.iana.org/assignments/uri-schemes/prov/redis
[gh-actions-image]: https://github.com/redis/redis-rb/workflows/Test/badge.svg
[gh-actions-link]:  https://github.com/redis/redis-rb/actions
[rubydoc]:          http://www.rubydoc.info/gems/redis
