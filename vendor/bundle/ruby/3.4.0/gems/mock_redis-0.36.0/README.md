# MockRedis

[![Gem Version](https://badge.fury.io/rb/mock_redis.svg)](http://badge.fury.io/rb/mock_redis)
![Build Status](https://github.com/sds/mock_redis/actions/workflows/tests.yml/badge.svg)
[![Coverage Status](https://coveralls.io/repos/sds/mock_redis/badge.svg)](https://coveralls.io/r/sds/mock_redis)

MockRedis provides the same interface as `redis-rb`, but it stores its
data in memory instead of talking to a Redis server. It is intended
for use in tests.

## Requirements

Ruby 2.6+

The current implementation is tested against Redis 6.2. Older versions may work, but can also return different results or not support some commands.

## Getting Started

Install the gem:

```bash
gem install mock_redis
```

It's as easy as `require 'mock_redis'; mr = MockRedis.new`. Then you can
call the same methods on it as you can call on a real `Redis` object.

For example:

    >> require 'mock_redis'
    >> mr = MockRedis.new
    >> mr.set('some key', 'some value')
    => "OK"
    >> mr.get('some key')
    => "some value"

## Supported Features

mock_redis supports most of the methods that redis-rb does. Examples
of supported methods:

* String methods: `get`, `set`, `append`, `incr`, etc.
* List methods: `lpush`, `lpop`, `lrange`, `rpoplpush`, etc.
* Set methods: `sadd`, `sinter`, `sismember`, `srandmember`, etc.
* Hash methods: `hset`, `hget`, `hgetall`, `hmget`, `hincrby`, `hincrbyfloat` etc.
* Sorted set methods: `zadd`, `zrank`, `zunionstore`, etc.
* Expirations: `expire`, `pexpire`, `ttl`, `pttl`, etc.
* Transactions: `multi`, `exec`, `discard`
* Futures

## Mostly-Supported Commands

A MockRedis object can't do everything that a real Redis client can
since it's an in-memory object confined to a single process. MockRedis
makes every attempt to be Redis-compatible, but there are some
necessary exceptions.

* Blocking list commands (`#blmove`, `#blpop`, `#brpop`, and `#brpoplpush`)
  work as expected if there is data for them to retrieve. If you use one of
  these commands with a nonzero timeout and there is no data for it to
  retrieve, then the command returns immediately. However, if you ask
  one of these commands for data with a 0 timeout (means "wait
  forever") and there is no data available, then a
  `MockRedis::WouldBlock` exception is raised. It's not what a real
  Redis client would do, but it beats hanging your test run forever.

* `#info` just returns canned values; they don't update over time.

* `#sort` supports ascending and descending sort. `ALPHA` sort is not yet
  supported.

## Unsupported Commands

Some stuff, we just can't do with a single Ruby object in a single
Ruby process.

* Debugging commands (`#debug('object', key)` and
  `#debug('segfault')`) aren't available.

* `#object` isn't available since we don't have any Redis internals to
  poke at.

* `#monitor` isn't available; there's no place for requests to come
  from, so there's nothing to receive.

* Pubsub commands (`#psubscribe`, `#publish`, `#punsubscribe`) aren't
  available.

* `#slowlog` isn't available.

* Scripting commands (`#script`, `#eval`, `#evalsha`) are just stubs&mdash;they won't execute anything

## Remaining Work

There are some things we want to have in here, but that we just
haven't gotten to doing yet. If you're interested in helping out,
please submit a pull request with your (tested!) implementation.

* `#config(:get|:set|:resetstat)` isn't done. They can just return
  canned values.

## Running tests

We recommend running Redis within a Docker container to make development as simple as possible, but as long as you have a Redis instance listening on `localhost:6379` you should be good to go.

1. Start Redis.
   ```bash
   docker run --rm -p 6379:6379 redis:6.2-alpine
   ```
2. Install dependencies.
   ```bash
   bundle install
   ```
3. Run tests.
   ```bash
   bundle exec rspec
   ```

These tests were written with Redis running on `localhost` without any
passwords required. If you're using a different version of Redis, you
may see failures due to error message text being different and other
breaking changes over time.

## Changelog

If you're interested in seeing the changes and bug fixes between each version of `mock_redis`, read the [MockRedis Changelog](CHANGELOG.md).

## License

This project is released under the [MIT license](LICENSE.md).
