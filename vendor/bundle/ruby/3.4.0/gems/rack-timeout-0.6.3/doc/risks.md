Risks and shortcomings of using Rack::Timeout
---------------------------------------------

### Timing Out During IO Blocks

Sometimes a request is taking too long to complete because it's blocked waiting on synchronous IO. Such IO does not need to be file operations, it could be, say, network or database operations. If said IO is happening in a C library that's unaware of ruby's interrupt system (i.e. anything written without ruby in mind), calling `Thread#raise` (that's what rack-timeout uses) will not have effect until after the IO block is gone.

At the moment rack-timeout does not try to address this issue. As a fail-safe against these cases, a blunter solution that kills the entire process is recommended, such as unicorn's timeouts.

More detailed explanations of the issues surrounding timing out in ruby during IO blocks can be found at:

- http://redgetan.cc/understanding-timeouts-in-cruby/

### Timing Out is Inherently Unsafe

Raising mid-flight in stateful applications is inherently unsafe. A request can be aborted at any moment in the code flow, and the application can be left in an inconsistent state. There's little way rack-timeout could be aware of ongoing state changes. Applications that rely on a set of globals (like class variables) or any other state that lives beyond a single request may find those left in an unexpected/inconsistent state after an aborted request. Some cleanup code might not have run, or only half of a set of related changes may have been applied.

A lot more can go wrong. An intricate explanation of the issue by JRuby's Charles Nutter can be found [here][broken-timeout].

Ruby 2.1 provides a way to defer the result of raising exceptions through the [Thread.handle_interrupt][handle-interrupt] method. This could be used in critical areas of your application code to prevent Rack::Timeout from accidentally wreaking havoc by raising just in the wrong moment. That said, `handle_interrupt` and threads in general are hard to reason about, and detecting all cases where it would be needed in an application is a tall order, and the added code complexity is probably not worth the trouble.

Your time is better spent ensuring requests run fast and don't need to timeout.

That said, it's something to be aware of, and may explain some eerie wonkiness seen in logs.

[broken-timeout]: http://headius.blogspot.de/2008/02/rubys-threadraise-threadkill-timeoutrb.html
[handle-interrupt]: http://www.ruby-doc.org/core-2.1.3/Thread.html#method-c-handle_interrupt

### Time Out Early and Often

Because of the aforementioned issues, it's recommended you set library-specific timeouts and leave Rack::Timeout as a last resort measure. Library timeouts will generally take care of IO issues and abort the operation safely. See [The Ultimate Guide to Ruby Timeouts][ruby-timeouts].

You'll want to set all relevant timeouts to something lower than Rack::Timeout's `service_timeout`. Generally you want them to be at least 1s lower, so as to account for time spent elsewhere during the request's lifetime while still giving libraries a chance to time out before Rack::Timeout.

[ruby-timeouts]: https://github.com/ankane/the-ultimate-guide-to-ruby-timeouts
