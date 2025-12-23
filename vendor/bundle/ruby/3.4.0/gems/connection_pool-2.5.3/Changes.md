# connection_pool Changelog

2.5.3
------

- Fix TruffleRuby/JRuby crash [#201]

2.5.2
------

- Rollback inadvertant change to `auto_reload_after_fork` default. [#200]

2.5.1
------

- Pass options to TimedStack in `checkout` [#195]
- Optimize connection lookup [#196]
- Fixes for use with Ractors

2.5.0
------

- Reap idle connections [#187]
```ruby
idle_timeout = 60
pool = ConnectionPool.new ...
pool.reap(idle_timeout, &:close)
```
- `ConnectionPool#idle` returns the count of connections not in use [#187]

2.4.1
------

- New `auto_reload_after_fork` config option to disable auto-drop [#177, shayonj]

2.4.0
------

- Automatically drop all connections after fork [#166]

2.3.0
------

- Minimum Ruby version is now 2.5.0
- Add pool size to TimeoutError message

2.2.5
------

- Fix argument forwarding on Ruby 2.7 [#149]

2.2.4
------

- Add `reload` to close all connections, recreating them afterwards [Andrew Marshall, #140]
- Add `then` as a way to use a pool or a bare connection with the same code path [#138]

2.2.3
------

- Pool now throws `ConnectionPool::TimeoutError` on timeout. [#130]
- Use monotonic clock present in all modern Rubies [Tero Tasanen, #109]
- Remove code hacks necessary for JRuby 1.7
- Expose wrapped pool from ConnectionPool::Wrapper [Thomas Lecavelier, #113]

2.2.2
------

- Add pool `size` and `available` accessors for metrics and monitoring
  purposes [#97, robholland]

2.2.1
------

- Allow CP::Wrapper to use an existing pool [#87, etiennebarrie]
- Use monotonic time for more accurate timeouts [#84, jdantonio]

2.2.0
------

- Rollback `Timeout` handling introduced in 2.1.1 and 2.1.2.  It seems
  impossible to safely work around the issue. Please never, ever use
  `Timeout.timeout` in your code or you will see rare but mysterious bugs. [#75]

2.1.3
------

- Don't increment created count until connection is successfully
  created. [mylesmegyesi, #73]

2.1.2
------

- The connection\_pool will now close any connections which respond to
  `close` (Dalli) or `disconnect!` (Redis).  This ensures discarded connections
  from the fix in 2.1.1 are torn down ASAP and don't linger open.


2.1.1
------

- Work around a subtle race condition with code which uses `Timeout.timeout` and
  checks out a connection within the timeout block.  This might cause
  connections to get into a bad state and raise very odd errors. [tamird, #67]


2.1.0
------

- Refactoring to better support connection pool subclasses [drbrain,
  #55]
- `with` should return value of the last expression [#59]


2.0.0
-----

- The connection pool is now lazy.  Connections are created as needed
  and retained until the pool is shut down. [drbrain, #52]

1.2.0
-----

- Add `with(options)` and `checkout(options)`. [mattcamuto]
  Allows the caller to override the pool timeout.
```ruby
@pool.with(:timeout => 2) do |conn|
end
```

1.1.0
-----

- New `#shutdown` method (simao)

    This method accepts a block and calls the block for each
    connection in the pool. After calling this method, trying to get a
    connection from the pool raises `PoolShuttingDownError`.

1.0.0
-----

- `#with_connection` is now gone in favor of `#with`.

- We no longer pollute the top level namespace with our internal
`TimedStack` class.

0.9.3
--------

- `#with_connection` is now deprecated in favor of `#with`.

    A warning will be issued in the 0.9 series and the method will be
    removed in 1.0.

- We now reuse objects when possible.

    This means that under no contention, the same object will be checked
    out from the pool after subsequent calls to `ConnectionPool#with`.

    This change should have no impact on end user performance. If
    anything, it should be an improvement, depending on what objects you
    are pooling.

0.9.2
--------

- Fix reentrant checkout leading to early checkin.

0.9.1
--------

- Fix invalid superclass in version.rb

0.9.0
--------

- Move method\_missing magic into ConnectionPool::Wrapper (djanowski)
- Remove BasicObject superclass (djanowski)

0.1.0
--------

- More precise timeouts and better error message
- ConnectionPool now subclasses BasicObject so `method_missing` is more effective.
