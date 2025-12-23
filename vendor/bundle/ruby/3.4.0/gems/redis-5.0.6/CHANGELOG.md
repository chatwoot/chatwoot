# Unreleased

# 5.0.6

- Wait for an extra `config.read_timeout` in blocking commands rather than an arbitrary 100ms. See #1175.
- Treat ReadOnlyError as ConnectionError. See #1168.

# 5.0.5

- Fix automatic disconnection when the process was forked. See #1157.

# 5.0.4

- Cast `ttl` argument to integer in `expire`, `setex` and a few others.

# 5.0.3

- Add `OutOfMemoryError` as a subclass of `CommandError`

# 5.0.2

- Fix `Redis#close` to properly reset the fork protection check.

# 5.0.1

- Added a fake `Redis::Connections.drivers` method to be compatible with older sidekiq versions.

# 5.0.0

- Eagerly and strictly cast Integer and Float parameters.
- Allow to call `subscribe`, `unsubscribe`, `psubscribe` and `punsubscribe` from a subscribed client. See #1131.
- Use `MD5` for hashing server nodes in `Redis::Distributed`. This should improve keys distribution among servers. See #1089.
- Changed `sadd` and `srem` to now always return an Integer.
- Added `sadd?` and `srem?` which always return a Boolean.
- Added support for `IDLE` paramter in `xpending`.
- Cluster support has been moved to a `redis-clustering` companion gem.
- `select` no longer record the current database. If the client has to reconnect after `select` was used, it will reconnect to the original database.
- Better support Float timeout in blocking commands. See #977.
- `Redis.new` will now raise an error if provided unknown options.
- Removed positional timeout in blocking commands (`BLPOP`, etc). Timeout now must be passed as an option: `r.blpop("key", timeout: 2.5)`
- Removed `logger` option.
- Removed `reconnect_delay_max` and `reconnect_delay`, you can pass precise sleep durations to `reconnect_attempts` instead.
- Require Ruby 2.5+.
- Removed the deprecated `queue` and `commit` methods. Use `pipelined` instead.
- Removed the deprecated `Redis::Future#==`.
- Removed the deprecated `pipelined` and `multi` signature. Commands now MUST be called on the block argument, not the original redis instance.
- Removed `Redis.current`. You shouldn't assume there is a single global Redis connection, use a connection pool instead,
  and libaries using Redis should accept a Redis instance (or connection pool) as a config. E.g. `MyLibrary.redis = Redis.new(...)`.
- Removed the `synchrony` driver.
- Removed `Redis.exists_returns_integer`, it's now always enabled.

# 4.8.0

* Introduce `sadd?` and `srem?` as boolean returning versions of `sadd` and `srem`.
* Deprecate `sadd` and `srem` returning a boolean when called with a single argument.
  To enable the redis 5.0 behavior you can set `Redis.sadd_returns_boolean = false`.
* Deprecate passing `timeout` as a positional argument in blocking commands (`brpop`, `blop`, etc).

# 4.7.1

* Gracefully handle OpenSSL 3.0 EOF Errors (`OpenSSL::SSL::SSLError: SSL_read: unexpected eof while reading`). See #1106
  This happens frequently on heroku-22.

# 4.7.0

* Support single endpoint architecture with SSL/TLS in cluster mode. See #1086.
* `zrem` and `zadd` act as noop when provided an empty list of keys. See #1097.
* Support IPv6 URLs.
* Add `Redis#with` for better compatibility with `connection_pool` usage.
* Fix the block form of `multi` called inside `pipelined`. Previously the `MUTLI/EXEC` wouldn't be sent. See #1073.

# 4.6.0

* Deprecate `Redis.current`.
* Deprecate calling commands on `Redis` inside `Redis#pipelined`. See #1059.
  ```ruby
  redis.pipelined do
    redis.get("key")
  end
  ```

  should be replaced by:

  ```ruby
  redis.pipelined do |pipeline|
    pipeline.get("key")
  end
  ```
* Deprecate calling commands on `Redis` inside `Redis#multi`. See #1059.
  ```ruby
  redis.multi do
    redis.get("key")
  end
  ```

  should be replaced by:

  ```ruby
  redis.multi do |transaction|
    transaction.get("key")
  end
  ```
* Deprecate `Redis#queue` and `Redis#commit`. See #1059.

* Fix `zpopmax` and `zpopmin` when called inside a pipeline. See #1055.
* `Redis#synchronize` is now private like it should always have been.

* Add `Redis.silence_deprecations=` to turn off deprecation warnings.
  If you don't wish to see warnings yet, you can set `Redis.silence_deprecations = true`.
  It is however heavily recommended to fix them instead when possible.
* Add `Redis.raise_deprecations=` to turn deprecation warnings into errors.
  This makes it easier to identitify the source of deprecated APIs usage.
  It is recommended to set `Redis.raise_deprecations = true` in development and test environments.
* Add new options to ZRANGE. See #1053.
* Add ZRANGESTORE command. See #1053.
* Add SCAN support for `Redis::Cluster`. See #1049.
* Add COPY command. See #1053. See #1048.
* Add ZDIFFSTORE command. See #1046.
* Add ZDIFF command. See #1044.
* Add ZUNION command. See #1042.
* Add HRANDFIELD command. See #1040.

# 4.5.1

* Restore the accidential auth behavior of redis-rb 4.3.0 with a warning. If provided with the `default` user's password, but a wrong username,
  redis-rb will first try to connect as the provided user, but then will fallback to connect as the `default` user with the provided password.
  This behavior is deprecated and will be removed in Redis 4.6.0. Fix #1038.

# 4.5.0

* Handle parts of the command using incompatible encodings. See #1037.
* Add GET option to SET command. See #1036.
* Add ZRANDMEMBER command. See #1035.
* Add LMOVE/BLMOVE commands. See #1034.
* Add ZMSCORE command. See #1032.
* Add LT/GT options to ZADD. See #1033.
* Add SMISMEMBER command. See #1031.
* Add EXAT/PXAT options to SET. See #1028.
* Add GETDEL/GETEX commands. See #1024.
* `Redis#exists` now returns an Integer by default, as warned since 4.2.0. The old behavior can be restored with `Redis.exists_returns_integer = false`.
* Fix Redis < 6 detection during connect. See #1025.
* Fix fetching command details in Redis cluster when the first node is unhealthy. See #1026.

# 4.4.0

* Redis cluster: fix cross-slot validation in pipelines. Fix ##1019.
* Add support for `XAUTOCLAIM`. See #1018.
* Properly issue `READONLY` when reconnecting to replicas. Fix #1017.
* Make `del` a noop if passed an empty list of keys. See #998.
* Add support for `ZINTER`. See #995.

# 4.3.1

* Fix password authentication against redis server 5 and older.

# 4.3.0

* Add the TYPE argument to scan and scan_each. See #985.
* Support AUTH command for ACL. See #967.

# 4.2.5

* Optimize the ruby connector write buffering. See #964.

# 4.2.4

* Fix bytesize calculations in the ruby connector, and work on a copy of the buffer. Fix #961, #962.

# 4.2.3

* Use io/wait instead of IO.select in the ruby connector. See #960.
* Use exception free non blocking IOs in the ruby connector. See #926.
* Prevent corruption of the client when an interrupt happen during inside a pipeline block. See #945.

# 4.2.2

* Fix `WATCH` support for `Redis::Distributed`. See #941.
* Fix handling of empty stream responses. See #905, #929.

# 4.2.1

* Fix `exists?` returning an actual boolean when called with multiple keys. See #918.
* Setting `Redis.exists_returns_integer = false` disables warning message about new behaviour. See #920.

# 4.2.0

* Convert commands to accept keyword arguments rather than option hashes. This both help catching typos, and reduce needless allocations.
* Deprecate the synchrony driver. It will be removed in 5.0 and hopefully maintained as a separate gem. See #915.
* Make `Redis#exists` variadic, will return an Integer if called with multiple keys.
* Add `Redis#exists?` to get a Boolean if any of the keys exists.
* `Redis#exists` when called with a single key will warn that future versions will return an Integer.
  Set `Redis.exists_returns_integer = true` to opt-in to the new behavior.
* Support `keepttl` ooption in `set`. See #913.
* Optimized initialization of Redis::Cluster. See #912.
* Accept sentinel options even with string key. See #599.
* Verify TLS connections by default. See #900.
* Make `Redis#hset` variadic. It now returns an integer, not a boolean. See #910.

# 4.1.4

* Alias `Redis#disconnect` as `#close`. See #901.
* Handle clusters with multiple slot ranges. See #894.
* Fix password authentication to a redis cluster. See #889.
* Handle recursive MOVED responses. See #882.
* Increase buffer size in the ruby connector. See #880.
* Fix thread safety of `Redis.queue`. See #878.
* Deprecate `Redis::Future#==` as it's likely to be a mistake. See #876.
* Support `KEEPTTL` option for SET command. See #913.

# 4.1.3

* Fix the client hanging forever when connecting with SSL to a non-SSL server. See #835.

# 4.1.2

* Fix several authentication problems with sentinel. See #850 and #856.
* Explicitly drop Ruby 2.2 support.


# 4.1.1

* Fix error handling in multi blocks. See #754.
* Fix geoadd to accept arrays like georadius and georadiusbymember. See #841.
* Fix georadius command failing when long == lat. See #841.
* Fix timeout error in xread block: 0. See #837.
* Fix incompatibility issue with redis-objects. See #834.
* Properly handle Errno::EADDRNOTAVAIL on connect.
* Fix password authentication to sentinel instances. See #813.

# 4.1.0

* Add Redis Cluster support. See #716.
* Add streams support. See #799 and #811.
* Add ZPOP* support. See #812.
* Fix issues with integer-like objects as BPOP timeout

# 4.0.3

* Fix raising command error for first command in pipeline. See #788.
* Fix the gemspec to stop exposing a `build` executable. See #785.
* Add `:reconnect_delay` and `:reconnect_delay_max` options. See #778.

# 4.0.2

* Added `Redis#unlink`. See #766.

* `Redis.new` now accept a custom connector via `:connector`. See #591.

* `Redis#multi` no longer perform empty transactions. See #747.

* `Redis#hdel` now accepts hash keys as multiple arguments like `#del`. See #755.

* Allow to skip SSL verification. See #745.

* Add Geo commands: `geoadd`, `geohash`, `georadius`, `georadiusbymember`, `geopos`, `geodist`. See #730.

# 4.0.1

* `Redis::Distributed` now supports `mget` and `mapped_mget`. See #687.

* `Redis::Distributed` now supports `sscan` and `sscan_each`. See #572.

* `Redis#connection` returns a hash with connection information.
  You shouldn't need to call `Redis#_client`, ever.

* `Redis#flushdb` and `Redis#flushall` now support the `:async` option. See #706.


# 4.0

* Removed `Redis.connect`. Use `Redis.new`.

* Removed `Redis#[]` and `Redis#[]=` aliases.

* Added support for `CLIENT` commands. The lower-level client can be
  accessed via `Redis#_client`.

* Dropped official support for Ruby < 2.2.2.

# 3.3.5

* Fixed Ruby 1.8 compatibility after backporting `Redis#connection`. See #719.

# 3.3.4 (yanked)

* `Redis#connection` returns a hash with connection information.
  You shouldn't need to call `Redis#_client`, ever.

# 3.3.3

* Improved timeout handling after dropping Timeout module.

# 3.3.2

* Added support for `SPOP` with COUNT. See #628.

* Fixed connection glitches when using SSL. See #644.

# 3.3.1

* Remove usage of Timeout::timeout, refactor into using low level non-blocking writes.
  This fixes a memory leak due to Timeout creating threads on each invocation.

# 3.3.0

* Added support for SSL/TLS. Redis doesn't support SSL natively, so you still
  need to run a terminating proxy on Redis' side. See #496.

* Added `read_timeout` and `write_timeout` options. See #437, #482.

* Added support for pub/sub with timeouts. See #329.

* Added `Redis#call`, `Redis#queue` and `Redis#commit` as a more minimal API to
  the client.

* Deprecated `Redis#disconnect!` in favor of `Redis#close`.

# 3.2.2

* Added support for `ZADD` options `NX`, `XX`, `CH`, `INCR`. See #547.

* Added support for sentinel commands. See #556.

* New `:id` option allows you to identify the client against Redis. See #510.

* `Redis::Distributed` will raise when adding two nodes with the same ID.
  See #354.

# 3.2.1

* Added support for `PUBSUB` command.

* More low-level socket errors are now raised as `CannotConnectError`.

* Added `:connect_timeout` option.

* Added support for `:limit` option for `ZREVRANGEBYLEX`.

* Fixed an issue where connections become inconsistent when using Ruby's
  Timeout module outside of the client (see #501, #502).

* Added `Redis#disconnect!` as a public-API way of disconnecting the client
  (without needing to use `QUIT`). See #506.

* Fixed Sentinel support with Hiredis.

* Fixed Sentinel support when using authentication and databases.

* Improved resilience when trying to contact sentinels.

# 3.2.0

* Redis Sentinel support.

# 3.1.0

* Added debug log sanitization (#428).

* Added support for HyperLogLog commands (Redis 2.8.9, #432).

* Added support for `BITPOS` command (Redis 2.9.11, #412).

* The client will now automatically reconnect after a fork (#414).

* If you want to disable the fork-safety check and prefer to share the
  connection across child processes, you can now pass the `inherit_socket`
  option (#409).

* If you want the client to attempt to reconnect more than once, you can now
  pass the `reconnect_attempts` option (#347)

# 3.0.7

* Added method `Redis#dup` to duplicate a Redis connection.

* IPv6 support.

# 3.0.6

* Added support for `SCAN` and variants.

# 3.0.5

* Fix calling #select from a pipeline (#309).

* Added method `Redis#connected?`.

* Added support for `MIGRATE` (Redis 2.6).

* Support extended SET command (#343, thanks to @benubois).

# 3.0.4

* Ensure #watch without a block returns "OK" (#332).

* Make futures identifiable (#330).

* Fix an issue preventing STORE in a SORT with multiple GETs (#328).

# 3.0.3

* Blocking list commands (`BLPOP`, `BRPOP`, `BRPOPLPUSH`) use a socket
  timeout equal to the sum of the command's timeout and the Redis
  client's timeout, instead of disabling socket timeout altogether.

* Ruby 2.0 compatibility.

* Added support for `DUMP` and `RESTORE` (Redis 2.6).

* Added support for `BITCOUNT` and `BITOP` (Redis 2.6).

* Call `#to_s` on value argument for `SET`, `SETEX`, `PSETEX`, `GETSET`,
  `SETNX`, and `SETRANGE`.

# 3.0.2

* Unescape CGI escaped password in URL.

* Fix test to check availability of `UNIXSocket`.

* Fix handling of score = +/- infinity for sorted set commands.

* Replace array splats with concatenation where possible.

* Raise if `EXEC` returns an error.

* Passing a nil value in options hash no longer overwrites the default.

* Allow string keys in options hash passed to `Redis.new` or
  `Redis.connect`.

* Fix uncaught error triggering unrelated error (synchrony driver).

    See f7ffd5f1a628029691084de69e5b46699bb8b96d and #248.

# 3.0.1

* Fix reconnect logic not kicking in on a write error.

    See 427dbd52928af452f35aa0a57b621bee56cdcb18 and #238.

# 3.0.0

### Upgrading from 2.x to 3.0

The following items are the most important changes to review when
upgrading from redis-rb 2.x. A full list of changes can be found below.

* The methods for the following commands have changed the arguments they
  take, their return value, or both.

    * `BLPOP`, `BRPOP`, `BRPOPLPUSH`
    * `SORT`
    * `MSETNX`
    * `ZRANGE`, `ZREVRANGE`, `ZRANGEBYSCORE`, `ZREVRANGEBYSCORE`
    * `ZINCRBY`, `ZSCORE`

* The return value from `#pipelined` and `#multi` no longer contains
  unprocessed replies, but the same replies that would be returned if
  the command had not been executed in these blocks.

* The client raises custom errors on connection errors, instead of
  `RuntimeError` and errors in the `Errno` family.

### Changes

* Added support for scripting commands (Redis 2.6).

    Scripts can be executed using `#eval` and `#evalsha`. Both can
    commands can either take two arrays to specify `KEYS` and `ARGV`, or
    take a hash containing `:keys` and `:argv` to specify `KEYS` and
    `ARGV`.

    ```ruby
    redis.eval("return ARGV[1] * ARGV[2]", :argv => [2, 3])
      # => 6
    ```

    Subcommands of the `SCRIPT` command can be executed via the
    `#script` method.

    For example:

    ```ruby
    redis.script(:load, "return ARGV[1] * ARGV[2]")
      # => "58db5d365a1922f32e7aa717722141ea9c2b0cf3"
    redis.script(:exists, "58db5d365a1922f32e7aa717722141ea9c2b0cf3")
      # => true
    redis.script(:flush)
      # => "OK"
    ```

* The repository now lives at [https://github.com/redis/redis-rb](https://github.com/redis/redis-rb).
  Thanks, Ezra!

* Added support for `PEXPIRE`, `PEXPIREAT`, `PTTL`, `PSETEX`,
  `INCRYBYFLOAT`, `HINCRYBYFLOAT` and `TIME` (Redis 2.6).

* `Redis.current` is now thread unsafe, because the client itself is thread safe.

    In the future you'll be able to do something like:

    ```ruby
    Redis.current = Redis::Pool.connect
    ```

    This makes `Redis.current` actually usable in multi-threaded environments,
    while not affecting those running a single thread.

* Change API for `BLPOP`, `BRPOP` and `BRPOPLPUSH`.

    Both `BLPOP` and `BRPOP` now take a single argument equal to a
    string key, or an array with string keys, followed by an optional
    hash with a `:timeout` key. When not specified, the timeout defaults
    to `0` to not time out.

    ```ruby
    redis.blpop(["list1", "list2"], :timeout => 1.0)
    ```

    `BRPOPLPUSH` also takes an optional hash with a `:timeout` key as
    last argument for consistency. When not specified, the timeout
    defaults to `0` to not time out.

    ```ruby
    redis.brpoplpush("some_list", "another_list", :timeout => 1.0)
    ```

* When `SORT` is passed multiple key patterns to get via the `:get`
  option, it now returns an array per result element, holding all `GET`
  substitutions.

* The `MSETNX` command now returns a boolean.

* The `ZRANGE`, `ZREVRANGE`, `ZRANGEBYSCORE` and `ZREVRANGEBYSCORE` commands
  now return an array containing `[String, Float]` pairs when
  `:with_scores => true` is passed.

    For example:

    ```ruby
    redis.zrange("zset", 0, -1, :with_scores => true)
      # => [["foo", 1.0], ["bar", 2.0]]
    ```

* The `ZINCRBY` and `ZSCORE` commands now return a `Float` score instead
  of a string holding a representation of the score.

* The client now raises custom exceptions where it makes sense.

    If by any chance you were rescuing low-level exceptions (`Errno::*`),
    you should now rescue as follows:

        Errno::ECONNRESET    -> Redis::ConnectionError
        Errno::EPIPE         -> Redis::ConnectionError
        Errno::ECONNABORTED  -> Redis::ConnectionError
        Errno::EBADF         -> Redis::ConnectionError
        Errno::EINVAL        -> Redis::ConnectionError
        Errno::EAGAIN        -> Redis::TimeoutError
        Errno::ECONNREFUSED  -> Redis::CannotConnectError

* Always raise exceptions originating from erroneous command invocation
  inside pipelines and MULTI/EXEC blocks.

    The old behavior (swallowing exceptions) could cause application bugs
    to go unnoticed.

* Implement futures for assigning values inside pipelines and MULTI/EXEC
  blocks. Futures are assigned their value after the pipeline or
  MULTI/EXEC block has executed.

    ```ruby
    $redis.pipelined do
      @future = $redis.get "key"
    end

    puts @future.value
    ```

* Ruby 1.8.6 is officially not supported.

* Support `ZCOUNT` in `Redis::Distributed` (Michael Dungan).

* Pipelined commands now return the same replies as when called outside
  a pipeline.

    In the past, pipelined replies were returned without post-processing.

* Support `SLOWLOG` command (Michael Bernstein).

* Calling `SHUTDOWN` effectively disconnects the client (Stefan Kaes).

* Basic support for mapping commands so that they can be renamed on the
  server.

* Connecting using a URL now checks that a host is given.

    It's just a small sanity check, cf. #126

* Support variadic commands introduced in Redis 2.4.

# 2.2.2

* Added method `Redis::Distributed#hsetnx`.

# 2.2.1

* Internal API: Client#call and family are now called with a single array
  argument, since splatting a large number of arguments (100K+) results in a
  stack overflow on 1.9.2.

* The `INFO` command can optionally take a subcommand. When the subcommand is
  `COMMANDSTATS`, the client will properly format the returned statistics per
  command. Subcommands for `INFO` are available since Redis v2.3.0 (unstable).

* Change `IO#syswrite` back to the buffered `IO#write` since some Rubies do
  short writes for large (1MB+) buffers and some don't (see issue #108).

# 2.2.0

* Added method `Redis#without_reconnect` that ensures the client will not try
  to reconnect when running the code inside the specified block.

* Thread-safe by default. Thread safety can be explicitly disabled by passing
  `:thread_safe => false` as argument.

* Commands called inside a MULTI/EXEC no longer raise error replies, since a
  successful EXEC means the commands inside the block were executed.

* MULTI/EXEC blocks are pipelined.

* Don't disconnect on error replies.

* Use `IO#syswrite` instead of `IO#write` because write buffering is not
  necessary.

* Connect to a unix socket by passing the `:path` option as argument.

* The timeout value is coerced into a float, allowing sub-second timeouts.

* Accept both `:with_scores` _and_ `:withscores` as argument to sorted set
  commands.

* Use [hiredis](https://github.com/pietern/hiredis-rb) (v0.3 or higher) by
  requiring "redis/connection/hiredis".

* Use [em-synchrony](https://github.com/igrigorik/em-synchrony) by requiring
  "redis/connection/synchrony".

# 2.1.1

See commit log.
