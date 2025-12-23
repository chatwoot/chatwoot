Exceptions
----------

Rack::Timeout can raise three types of exceptions. They are:

Two descend from `Rack::Timeout::Error`, which itself descends from `RuntimeError` and is generally caught by an unqualified `rescue`. The third, `RequestTimeoutException`, is more complicated and the most important.

*   `Rack::Timeout::RequestTimeoutException`: this is raised when a request has run for longer than the specified timeout. This descends from `Exception`, not from `Rack::Timeout::Error` (it has to be rescued from explicitly). It's raised by the rack-timeout timer thread in the application thread, at the point in the stack the app happens to be in when the timeout is triggered. This exception could be caught explicitly within the application, but in doing so you're working past the timeout. This is ok for quick cleanup work but shouldn't be abused as Rack::Timeout will not kick in twice for the same request.

    Rails will generally intercept `Exception`s, but in plain Rack apps, this exception will be caught by rack-timeout and re-raised as a `Rack::Timeout::RequestTimeoutError`. This is to prevent an `Exception` from bubbling up beyond rack-timeout and to the server.

*   `Rack::Timeout::RequestTimeoutError` descends from `Rack::Timeout::Error`, but it's only really seen in the case described above. It'll not be seen in a standard Rails app, and will only be seen in Sinatra if rescuing from exceptions is disabled.

*   `Rack::Timeout::RequestExpiryError`: this is raised when a request is skipped for being too old (see Wait Timeout section). This error cannot generally be rescued from inside a Rails controller action as it happens before the request has a chance to enter Rails.

    This shouldn't be different for other frameworks, unless you have something above Rack::Timeout in the middleware stack, which you generally shouldn't.

You shouldn't rescue from these errors for reporting purposes. Instead, you can subscribe for state change notifications with observers.

If you're trying to test that a `Rack::Timeout::RequestTimeoutException` is raised in an action in your Rails application, you **must do so in integration tests**. Please note that Rack::Timeout will not kick in for functional tests as they bypass the rack middleware stack.

[More details about testing middleware with Rails here][pablobm].

[pablobm]: http://stackoverflow.com/a/8681208/13989
