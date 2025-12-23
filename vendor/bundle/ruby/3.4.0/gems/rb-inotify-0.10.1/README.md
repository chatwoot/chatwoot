# rb-inotify

This is a simple wrapper over the [inotify](http://en.wikipedia.org/wiki/Inotify) Linux kernel subsystem
for monitoring changes to files and directories.
It uses the [FFI](http://wiki.github.com/ffi/ffi) gem to avoid having to compile a C extension.

[API documentation is available on rdoc.info](http://rdoc.info/projects/nex3/rb-inotify).

[![Build Status](https://secure.travis-ci.org/guard/rb-inotify.svg)](http://travis-ci.org/guard/rb-inotify)
[![Code Climate](https://codeclimate.com/github/guard/rb-inotify.svg)](https://codeclimate.com/github/guard/rb-inotify)
[![Coverage Status](https://coveralls.io/repos/guard/rb-inotify/badge.svg)](https://coveralls.io/r/guard/rb-inotify)

## Usage

The API is similar to the inotify C API, but with a more Rubyish feel.
First, create a notifier:

    notifier = INotify::Notifier.new

Then, tell it to watch the paths you're interested in
for the events you care about:

    notifier.watch("path/to/foo.txt", :modify) {puts "foo.txt was modified!"}
    notifier.watch("path/to/bar", :moved_to, :create) do |event|
      puts "#{event.name} is now in path/to/bar!"
    end

Inotify can watch directories or individual files.
It can pay attention to all sorts of events;
for a full list, see [the inotify man page](http://www.tin.org/bin/man.cgi?section=7&topic=inotify).

Finally, you get at the events themselves:

    notifier.run

This will loop infinitely, calling the appropriate callbacks when the files are changed.
If you don't want infinite looping,
you can also block until there are available events,
process them all at once,
and then continue on your merry way:

    notifier.process

## Advanced Usage

Sometimes it's necessary to have finer control over the underlying IO operations
than is provided by the simple callback API.
The trick to this is that the \{INotify::Notifier#to_io Notifier#to_io} method
returns a fully-functional IO object,
with a file descriptor and everything.
This means, for example, that it can be passed to `IO#select`:

     # Wait 10 seconds for an event then give up
     if IO.select([notifier.to_io], [], [], 10)
       notifier.process
     end

It can even be used with EventMachine:

     require 'eventmachine'

     EM.run do
       EM.watch notifier.to_io do
         notifier.process
       end
     end

Unfortunately, this currently doesn't work under JRuby.
JRuby currently doesn't use native file descriptors for the IO object,
so we can't use the notifier's file descriptor as a stand-in.

### Resource Limits

If you get an error like `inotify event queue has overflowed` you might be running into system limits. You can add the following to your `/etc/sysctl.conf` to increase the number of files that can be monitored:

```
fs.inotify.max_user_watches = 100000
fs.inotify.max_queued_events = 100000
fs.inotify.max_user_instances = 100000
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## License

Released under the MIT license.

Copyright, 2009, by [Natalie Weizenbaum](https://github.com/nex3).
Copyright, 2017, by [Samuel G. D. Williams](http://www.codeotaku.com/samuel-williams).

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
