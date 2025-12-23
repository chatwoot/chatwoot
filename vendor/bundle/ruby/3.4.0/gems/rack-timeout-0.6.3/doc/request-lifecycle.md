Request Lifetime
----------------

Throughout a request's lifetime, Rack::Timeout keeps details about the request in `env[Rack::Timeout::ENV_INFO_KEY]`, or, more explicitly, `env["rack-timeout.info"]`.

The value of that entry is an instance of `Rack::Timeout::RequestDetails`, which is a `Struct` consisting of the following fields:

*   `id`: a unique ID per request. Either the value of the `X-Request-ID` header or a random ID
    generated internally.

*   `wait`: time in seconds since `X-Request-Start` at the time the request was initially seen by Rack::Timeout. Only set if `X-Request-Start` is present.

*   `timeout`: the final timeout value that was used or to be used, in seconds. For `expired` requests, that would be the `wait_timeout`, possibly with `wait_overtime` applied. In all other cases it's the `service_timeout`, potentially reduced to make up for time lost waiting. (See discussion regarding `service_past_wait` above, under the Wait Timeout section.)

*   `service`: set after a request completes (or times out). The time in seconds it took being processed. This is also updated while a request is still active, around every second, with the time taken so far.

*   `state`: the possible states, and their log level, are:

    *   `expired` (`ERROR`): the request is considered too old and is skipped entirely. This happens when `X-Request-Start` is present and older than `wait_timeout`. When in this state, `Rack::Timeout::RequestExpiryError` is raised. See earlier discussion about the `wait_overtime` setting, too.

    *   `ready` (`INFO`): this is the state a request is in right before it's passed down the middleware chain. Once it's being processed, it'll move on to `active`, and then on to `timed_out` and/or `completed`.

    *   `active` (`DEBUG`): the request is being actively processed in the application thread. This is signaled repeatedly every ~1s until the request completes or times out.

    *   `timed_out` (`ERROR`): the request ran for longer than the determined timeout and was aborted. `Rack::Timeout::RequestTimeoutException` is raised in the application when this occurs. This state is not the final one, `completed` will be set after the framework is done with it. (If the exception does bubble up, it's caught by rack-timeout and re-raised as `Rack::Timeout::RequestTimeoutError`, which descends from RuntimeError.)

    *   `completed` (`INFO`): the request completed and Rack::Timeout is done with it. This does not mean the request completed *successfully*. Rack::Timeout does not concern itself with that. As mentioned just above, a timed out request will still end up with a `completed` state.
