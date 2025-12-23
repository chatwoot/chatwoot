# MockRedis Changelog

### 0.36.0

* Add support for `smismember`
* Add support for `lmove` and `blmove`
* Fix `zrem` to support passing array of integers

### 0.35.0

* Add support for `getdel`

### 0.34.0

* Add support for `with`

### 0.33.0

* Add support for `GET` argument to `SET` command

### 0.32.0

* Add support for `psetex`

### 0.31.0

* Allow `ping` to take argument
* Raise `CommandError` on `hmget` with empty list of fields

### 0.30.0

* Drop support for Ruby 2.4 and Ruby 2.5 since they are EOL
* Fix `expire` to to raise error on invalid integer

### 0.29.0

* Add support for `logger` option ([#211](https://github.com/sds/mock_redis/pull/211))
* Fix `zadd` to not perform conditional type conversion ([#214](https://github.com/sds/mock_redis/pull/214))
* Fix `hdel` to raise error when called with empty array ([#215](https://github.com/sds/mock_redis/pull/215))

### 0.28.0

* Fix `hmset` exception ([#206](https://github.com/sds/mock_redis/pull/206))
* Fix `hmset` to accept hashes in addition to key/value pairs ([#208](https://github.com/sds/mock_redis/pull/208))
* Fix stream ID regex to support `(` ([#209](https://github.com/sds/mock_redis/pull/209))
* Allow `mget` to accept a block ([#210](https://github.com/sds/mock_redis/pull/210))

### 0.27.3

* Ensure `ruby2_keywords` dependency is `require`d at runtime

### 0.27.2

* Switch `ruby2_keywords` gem from development dependency to runtime dependency

### 0.27.1

* Fix missing `ruby2_keywords` gem
* Allow passing string `offset` to `getbit` ([#203](https://github.com/sds/mock_redis/pull/203))

### 0.27.0

* Fix handling of keyword arguments on Ruby 3 ([#199](https://github.com/sds/mock_redis/pull/199))
* Allow passing string `offset` to `setbit` ([#200](https://github.com/sds/mock_redis/pull/200))
* Add `connection` method ([#201](https://github.com/sds/mock_redis/pull/201))

### 0.26.0

* Add block and count support to `xread` ([#194](https://github.com/sds/mock_redis/pull/194))

### 0.25.0

* Add support for `xread` command ([#190](https://github.com/sds/mock_redis/pull/190))
* Fix `mget` to raise error when passing empty array ([#191](https://github.com/sds/mock_redis/pull/191))
* Fix `xadd` when `maxlen` is zero ([#192](https://github.com/sds/mock_redis/pull/192))

### 0.24.0

* Fix handling of blocks within `multi` blocks ([#185](https://github.com/sds/mock_redis/pull/185))
* Fix handling of multiple consecutive `?` characters in key pattern matching ([#186](https://github.com/sds/mock_redis/pull/186))
* Change `exists` to return an integer and add `exists?` ([#188](https://github.com/sds/mock_redis/pull/188))

### 0.23.0

* Raise error when `setex` called with negative timeout ([#174](https://github.com/sds/mock_redis/pull/174))
* Add support for `dump`/`restore` between MockRedis instances ([#176](https://github.com/sds/mock_redis/pull/176))
* Fix warnings for ZSET methods on Ruby 2.7 ([#177](https://github.com/sds/mock_redis/pull/177))
* Add support for returning time in pipelines ([#179](https://github.com/sds/mock_redis/pull/179))
* Fix SET methods to correct set milliseconds with `px` ([#180](https://github.com/sds/mock_redis/pull/180))
* Add support for unsorted sets within `zinterstore`/`zunionstore`([#182](https://github.com/sds/mock_redis/pull/182))

### 0.22.0

* Gracefully handle cursors larger than the collection size in scan commands ([#171](https://github.com/sds/mock_redis/pull/171))
* Add `zpopmin` and `zpopmax` commands ([#172](https://github.com/sds/mock_redis/pull/172))
* Fix `hmset` to support array arguments ([#173](https://github.com/sds/mock_redis/pull/173))
* Fix `hmset` to always treat keys as strings ([#173](https://github.com/sds/mock_redis/pull/173))
* Remove unnecessary dependency on `rake` gem

### 0.21.0

* Fix behavior of `time` to return array of two integers ([#161](https://github.com/sds/mock_redis/pull/161))
* Add support for `close` and `disconnect!` ([#163](https://github.com/sds/mock_redis/pull/163))
* Fix `set` to properly handle (and ignore) other options ([#164](https://github.com/sds/mock_redis/pull/163))
* Fix `srem` to allow array of integers as argument ([#166](https://github.com/sds/mock_redis/pull/166))
* Fix `hdel` to allow array as argument ([#168](https://github.com/sds/mock_redis/pull/168))

### 0.20.0

* Add support for `count` parameter of `spop`
* Fix `mget` and `mset` to accept array as parameters
* Fix pipelined array replies
* Fix nested pipelining
* Allow nested multi
* Require Redis gem 4.0.1 or newer
* Add support for stream commands on Redis 5
* Keep empty strings on type mismatch
* Improve performance of `set_expiration`
* Fix `watch` to allow multiple keys
* Add `unlink` alias for `del`
* Drop support for Ruby 2.3 or older

### 0.19.0

* Require Ruby 2.2+
* Add support for `bitfield` command
* Add support for `geoadd`, `geopos`, `geohash`, and `geodist` commands
* Fix multi-nested pipeline not releasing lock issue

### 0.18.0

* Fix `hset` return value to return false when the field exists in the hash
* Fix message on exception raised from hincrbyfloat to match Redis 4
* Fix `lpushx`/`rpushx` to correctly accept an array as the value
* Fix rename to allow `rename(k1, k1)`

### 0.17.3

* Fix `zrange` behavior with negative stop argument

### 0.17.2

* Allow negative out-of-bounds start and stop in `zrange`

### 0.17.1

* Flatten args list passed to `hmset`
* Fix `pipelined` calls within `multi` blocks

### 0.17.0

* Upgrade minimum `redis` gem version to 3.3.0+
* Add support for XX, NX and INCR parameters of `ZADD`
* Drop support for Ruby 1.9.3/JRuby 1.7.x
* Fix ZREM to raise error when argument is an empty array

### 0.16.1

* Relax `rake` gem dependency to allow 11.x.x versions

### 0.16.0

* Add stub implementations for `script`/`eval`/`evalsha` commands
* Add implementations for `SCAN` family (`sscan`/`hscan`/`zscan`)
  family of commands

### 0.15.4

* Fix `zrange`/`zrevrange` to return elements with equal values in
  lexicographic order

### 0.15.3

* Fix `sadd` to return integers when adding arrays

### 0.15.2

* Fix `zrangebyscore` to work with exclusive ranges on both ends of interval

### 0.15.1

* Fix `hmget` and `mapped_hmget` to allow passing of an array of keys

### 0.15.0

* Add support for the `time` method

### 0.14.1

* Upgrade `redis` gem dependency to 3.2.x series
* Map `HDEL` field to string when given as an array

### 0.14.0

* Fix bug where SETBIT command would not correctly unset a bit
* Fix bug where a key that expired would cause another key that expired later
  to prematurely expire
* Add support to set methods to take array as argument
* Evaluate futures at the end of `#multi` blocks
* Add support for the SCAN command
* Add support for `[+/-]inf` values for min/max in ordered set commands

### 0.13.2

* Fix SMEMBERS command to not return frozen elements

### 0.13.1

* Fix bug where certain characters in keys were treated as regex characters
  rather than literals
* Add back support for legacy integer timeouts on blocking list commands

### 0.13.0

* Fix bug where SETBIT command would not correctly unset a bit
* Add support for the `connect` method
* Check that `min`/`max` parameters are floats in `zrangebyscore`,
  `zremrangebyscore`, and `zrevrangebyscore`
* Update blocking list commands to take `timeout` in an options hash
  for compatibility with `redis-rb` >= 3.0.0

### 0.12.1

* RENAME command now keeps key expiration

### 0.12.0

* Fix bug where `del` would not raise error when given empty array
* Add support for the BITCOUNT command

### 0.11.0

* Raise errors for empty arrays as arguments
* Update error messages to conform to Redis 2.8. This officially means
  `mock_redis` no *longer supports Redis 2.6 or lower*. All testing in
  TravisCI is now done against 2.8
* Update return value of TTL to return -2 if key doesn't exist
* Add support for the HINCRBYFLOAT command
* Add support for `count` parameter on SRANDMEMBER
* Add support for the PTTL command
* Improve support for negative start indices in LRANGE
* Improve support for negative start indices in LTRIM
* Allow `del` to accept arrays of keys

### 0.10.0
* Add support for :nx, :xx, :ex, :px options for SET command

### 0.9.0
* Added futures support

### 0.8.2
* Added support for Ruby 2.0.0, dropped support for Ruby 1.8.7
* Changes for compatibility with JRuby

### 0.8.1
* Fix `#pipelined` to yield self

### 0.8.0
* Fixed `watch` to return OK when passed no block
* Implemented `pexpire`, `pexpireat`
* Fixed `expire` to use millisecond precision

### 0.7.0
* Implemented `mapped_mget`, `mapped_mset`, `mapped_msetnx`
* Fixed `rpoplpush` when the `rpop` is nil

### 0.6.6
* Avoid mutation of @data from external reference
* Fix sorted set (e.g. `zadd`) with multiple score/member pairs

### 0.6.5
* Fix `zrevrange` to return an empty array on invalid range
* Fix `srandmember` spec on redis-rb 3.0.3
* Stringify keys in expiration-related commands

### 0.6.4
* Update INFO command for latest Redis 2.6 compatibility

### 0.6.3
* Treat symbols as strings for keys
* Add #reconnect method (no-op)

### 0.6.2
* Support for `connected?`, `disconnect` (no-op)
* Fix `*` in `keys` to support 0 or more

### 0.6.1
* Support default argument of `*` for keys
* Allow `MockRedis` to take a TimeClass

### 0.6.0
* Support for `#sort` (ascending and descending only)

### 0.5.5
* Support exclusive ranges in `zcount`
* List methods (`lindex`, `lrange`, `lset`, and `ltrim`) can take string indexes
* Fix typo in shared example `zset` spec
* Fix `lrange` to return `[]` when start is too large
* Update readme about spec suite compatibility

### 0.5.4
* Support `incrbyfloat` (new in Redis 2.6)
* Fix specs to pass in Redis 2.6
* Deprecated spec suite on 2.4

### 0.5.3
* Support `location` as an alias to `id` for `Sidekiq`'s benefit

### 0.5.2
* Support `watch`
* `sadd` is now Redis 2.4-compliant

### 0.5.1
* Support `MockRedis.connect`

### 0.5.0
* Support `redis-rb` >= 3.0
* Support Redis::Distributed
* Support ruby 1.9.3 in spec suite
* Support subsecond timeouts
* Support `-inf`, `+inf` in #zcount
* Return array of results from pipelined calls
* Use `debugger` instead of the deprecated `ruby-debug19`
* Fix exception handling in transaction wrappers
* Fix rename error behaviour for nonexistant keys

### 0.4.1
* bugfixes: teach various methods to correctly handle non-string values

### 0.4.0
* Support `mapped_hmset`/`mapped_hmget`
* Support `pipelined`
* Correctly handle out-of-range conditions for `zremrangebyrank` and `zrange`
* Fix off-by-one error in calculation of `ttl`

### 0.3.0
* Support hash operator (`[]`/`[]=`) as synonym of `get`/`set`
* Misc bugfixes

### 0.2.0
* Support passing a block to `#multi`.

### 0.1.2
* Fixes for 1.9.2; no functionality changes.

### 0.1.1
* Fix handling of -inf, +inf, and exclusive endpoints (e.g. "(3") in
  zrangebyscore, zrevrangebyscore, and zremrangebyscore. ("Fix" here
  means "write", as it's something that was completely forgotten the
  first time around.)

### 0.1.0
* Support `move(key, db)` to move keys between databases.

### 0.0.2
* Fix gem homepage.

### 0.0.1
Initial release.
