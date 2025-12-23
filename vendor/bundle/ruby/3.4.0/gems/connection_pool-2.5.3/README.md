connection\_pool
=================
[![Build Status](https://github.com/mperham/connection_pool/actions/workflows/ci.yml/badge.svg)](https://github.com/mperham/connection_pool/actions/workflows/ci.yml)

Generic connection pooling for Ruby.

MongoDB has its own connection pool.
ActiveRecord has its own connection pool.
This is a generic connection pool that can be used with anything, e.g. Redis, Dalli and other Ruby network clients.

Usage
-----

Create a pool of objects to share amongst the fibers or threads in your Ruby application:

``` ruby
$memcached = ConnectionPool.new(size: 5, timeout: 5) { Dalli::Client.new }
```

Then use the pool in your application:

``` ruby
$memcached.with do |conn|
  conn.get('some-count')
end
```

If all the objects in the connection pool are in use, `with` will block
until one becomes available.
If no object is available within `:timeout` seconds,
`with` will raise a `ConnectionPool::TimeoutError` (a subclass of `Timeout::Error`).

You can also use `ConnectionPool#then` to support _both_ a
connection pool and a raw client.

```ruby
# Compatible with a raw Redis::Client, and ConnectionPool Redis
$redis.then { |r| r.set 'foo' 'bar' }
```

Optionally, you can specify a timeout override using the with-block semantics:

``` ruby
$memcached.with(timeout: 2.0) do |conn|
  conn.get('some-count')
end
```

This will only modify the resource-get timeout for this particular
invocation.
This is useful if you want to fail-fast on certain non-critical
sections when a resource is not available, or conversely if you are comfortable blocking longer on a particular resource.
This is not implemented in the `ConnectionPool::Wrapper` class.

## Migrating to a Connection Pool

You can use `ConnectionPool::Wrapper` to wrap a single global connection, making it easier to migrate existing connection code over time:

``` ruby
$redis = ConnectionPool::Wrapper.new(size: 5, timeout: 3) { Redis.new }
$redis.sadd('foo', 1)
$redis.smembers('foo')
```

The wrapper uses `method_missing` to checkout a connection, run the requested method and then immediately check the connection back into the pool.
It's **not** high-performance so you'll want to port your performance sensitive code to use `with` as soon as possible.

``` ruby
$redis.with do |conn|
  conn.sadd('foo', 1)
  conn.smembers('foo')
end
```

Once you've ported your entire system to use `with`, you can simply remove `Wrapper` and use the simpler and faster `ConnectionPool`.


## Shutdown

You can shut down a ConnectionPool instance once it should no longer be used.
Further checkout attempts will immediately raise an error but existing checkouts will work.

```ruby
cp = ConnectionPool.new { Redis.new }
cp.shutdown { |c| c.close }
```

Shutting down a connection pool will block until all connections are checked in and closed.
**Note that shutting down is completely optional**; Ruby's garbage collector will reclaim unreferenced pools under normal circumstances.

## Reload

You can reload a ConnectionPool instance in the case it is desired to close all connections to the pool and, unlike `shutdown`, afterwards recreate connections so the pool may continue to be used.
Reloading may be useful after forking the process.

```ruby
cp = ConnectionPool.new { Redis.new }
cp.reload { |conn| conn.quit }
cp.with { |conn| conn.get('some-count') }
```

Like `shutdown`, this will block until all connections are checked in and closed.

## Reap

You can reap idle connections in the ConnectionPool instance to close connections that were created but have not been used for a certain amount of time. This can be useful to run periodically in a separate thread especially if keeping the connection open is resource intensive.

You can specify how many seconds the connections have to be idle for them to be reaped.
Defaults to 60 seconds.

```ruby
cp = ConnectionPool.new { Redis.new }
cp.reap(300) { |conn| conn.close } # Reaps connections that have been idle for 300 seconds (5 minutes).
```

### Reaper Thread

You can start your own reaper thread to reap idle connections in the ConnectionPool instance on a regular interval.

```ruby
cp = ConnectionPool.new { Redis.new }

# Start a reaper thread to reap connections that have been idle for 300 seconds (5 minutes).
Thread.new do
  loop do
    cp.reap(300) { |conn| conn.close }
    sleep 300
  end
end
```

## Current State

There are several methods that return information about a pool.

```ruby
cp = ConnectionPool.new(size: 10) { Redis.new }
cp.size # => 10
cp.available # => 10
cp.idle # => 0

cp.with do |conn|
  cp.size # => 10
  cp.available # => 9
  cp.idle # => 0
end

cp.idle # => 1
```

Notes
-----

- Connections are lazily created as needed.
- There is no provision for repairing or checking the health of a connection;
  connections should be self-repairing. This is true of the Dalli and Redis
  clients.
- **WARNING**: Don't ever use `Timeout.timeout` in your Ruby code or you will see
  occasional silent corruption and mysterious errors. The Timeout API is unsafe
  and cannot be used correctly, ever. Use proper socket timeout options as
  exposed by Net::HTTP, Redis, Dalli, etc.


Author
------

Mike Perham, [@getajobmike](https://twitter.com/getajobmike), <https://www.mikeperham.com>
