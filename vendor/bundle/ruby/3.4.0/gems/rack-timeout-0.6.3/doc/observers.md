Observers
---------

Observers are blocks that are notified about state changes during a request's lifetime. Keep in mind that the `active` state is set every ~1s, so you'll be notified every time.

You can register an observer with:

```ruby
Rack::Timeout.register_state_change_observer(:a_unique_name) { |env| do_things env }
```

There's currently no way to subscribe to changes into or out of a particular state. To check the actual state we're moving into, read `env['rack-timeout.info'].state`. Handling going out of a state would require some additional logic in the observer.

You can remove an observer with `unregister_state_change_observer`:

```ruby
Rack::Timeout.unregister_state_change_observer(:a_unique_name)
```

rack-timeout's logging is implemented using an observer; see `Rack::Timeout::StateChangeLoggingObserver` in logging-observer.rb for the implementation.

Custom observers might be used to do cleanup, store statistics on request length, timeouts, etc., and potentially do performance tuning on the fly.
