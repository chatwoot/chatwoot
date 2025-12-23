# Gserver

GServer implements a generic server, featuring thread pool management,
simple logging, and multi-server management.  See HttpServer in
<tt>sample/xmlrpc.rb</tt> in the Ruby standard library for an example of
GServer in action.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'gserver'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install gserver

## Usage

Using GServer is simple.  Below we implement a simple time server, run it,
query it, and shut it down.  Try this code in +irb+:

    require 'gserver'

    #
    # A server that returns the time in seconds since 1970.
    #
    class TimeServer < GServer
      def initialize(port=10001, *args)
        super(port, *args)
      end
      def serve(io)
        io.puts(Time.now.to_i)
      end
    end

    # Run the server with logging enabled (it's a separate thread).
    server = TimeServer.new
    server.audit = true                  # Turn logging on.
    server.start

    # *** Now point your browser to http://localhost:10001 to see it working ***

    # See if it's still running.
    GServer.in_service?(10001)           # -> true
    server.stopped?                      # -> false

    # Shut the server down gracefully.
    server.shutdown

    # Alternatively, stop it immediately.
    GServer.stop(10001)
    # or, of course, "server.stop".

All the business of accepting connections and exception handling is taken
care of.  All we have to do is implement the method that actually serves the
client.

## Contributing

1. Fork it ( https://github.com/[my-github-username]/gserver/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
