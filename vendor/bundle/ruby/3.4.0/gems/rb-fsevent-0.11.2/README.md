[![Code Climate](https://codeclimate.com/badge.png)](https://codeclimate.com/github/thibaudgg/rb-fsevent)
[![endorse](https://api.coderwall.com/ttilley/endorsecount.png)](https://coderwall.com/ttilley)

# rb-fsevent

Very simple & usable Mac OSX FSEvents API

* Signals are working (really)
* Tested on MRI 2.4.1, RBX 3.72, JRuby 1.7.26 and 9.1.8.0
* Tested on 10.8

## HFS+ filename corruption bug

There is a _very_ long-standing (since 2011) OSX bug where sometimes the filename metadata for HFS+ filesystems will get corrupted, resulting in some APIs returning one case for a file, and other APIs returning another. The result is that sometimes, _for no visible reason to the user_, fsevents would simply not work. As of rb-fsevent 0.9.5 this issue is properly detected and an insanely hacky (but effective) workaround is used that replaces the system `realpath()` with a custom implementation that should almost always return the same value as the kernel reporting (thus fixing fsevents). The major flaw in the workaround is that it may return the wrong path for hard links.

Please note that this doesn't repair the underlying issue on disk. Other apps and libraries using fsevents will continue to break with no warning. There may be other issues unrelated to fsevents.

__This bug is resolved in MacOS 10.12 and all users are strongly encouraged to upgrade.__

## Install

    gem install rb-fsevent

### re-compilation

rb-fsevent comes with a pre-compiled fsevent\_watch binary supporting x86\_64 on 10.9 and above. The binary is codesigned with my (Travis Tilley) Developer ID as an extra precaution when distributing pre-compiled code and contains an embedded plist describing its build environment. This should be sufficient for most users, but if you need to use rb-fsevent on 10.8 or lower then recompilation is necessary. This can be done by entering the installed gem's ext directory and running:

    MACOSX_DEPLOYMENT_TARGET="10.7" rake replace_exe

The following ENV vars are recognized:

* CC
* CFLAGS
* ARCHFLAGS
* MACOSX\_DEPLOYMENT\_TARGET
* FWDEBUG (enables debug mode, printing an obscene number of informational
  messages to STDERR)

### embedded plist

You can retrieve the values in the embedded plist via the CLI:

    fsevent_watch --show-plist

The output is essentially formatted as `"#{key}:\n  #{value}\n"` to make it easier to read than plist style xml. The result looks like this:

    DTSDKName:
      macosx10.5
    FSEWBuildTriple:
      i386-apple-darwin10.8.0
    FSEWCC:
      /usr/bin/gcc-4.2
    DTSDKPath:
      /Developer/SDKs/MacOSX10.5.sdk
    FSEWCCVersion:
      i686-apple-darwin10-gcc-4.2.1 (GCC) 4.2.1 (Apple Inc. build 5666) (dot 3)
    FSEWCFLAGS:
      -fconstant-cfstrings -fno-strict-aliasing -Wall -mmacosx-version-min=10.5 -O3

If, for some perverse reason, you prefer to look at the xml... it can be retrieved via:

    otool -s __TEXT __info_plist ./bin/fsevent_watch | grep ^0 | xxd -r -

### codesign

You can verify code signing information for a specific fsevent\_watch via:

    codesign -d -vvv ./bin/fsevent_watch

If you're using the pre-compiled binary, then the output should contain something to the effect of:

    Authority=Developer ID Application: Travis Tilley
    Authority=Developer ID Certification Authority
    Authority=Apple Root CA
    Timestamp=Dec 31, 2012 12:49:13 PM

## Usage

### Singular path

```ruby
require 'rb-fsevent'

fsevent = FSEvent.new
fsevent.watch Dir.pwd do |directories|
  puts "Detected change inside: #{directories.inspect}"
end
fsevent.run
```

### Multiple paths

```ruby
require 'rb-fsevent'

paths = ['/tmp/path/one', '/tmp/path/two', Dir.pwd]

fsevent = FSEvent.new
fsevent.watch paths do |directories|
  puts "Detected change inside: #{directories.inspect}"
end
fsevent.run
```

### Multiple paths and additional options as a Hash

```ruby
require 'rb-fsevent'

paths = ['/tmp/path/one', '/tmp/path/two', Dir.pwd]
options = {:latency => 1.5, :no_defer => true }

fsevent = FSEvent.new
fsevent.watch paths, options do |directories|
  puts "Detected change inside: #{directories.inspect}"
end
fsevent.run
```

### Multiple paths and additional options as an Array

```ruby
require 'rb-fsevent'

paths = ['/tmp/path/one', '/tmp/path/two', Dir.pwd]
options = ['--latency', 1.5, '--no-defer']

fsevent = FSEvent.new
fsevent.watch paths, options do |directories|
  puts "Detected change inside: #{directories.inspect}"
end
fsevent.run
```

### Using _full_ event information

```ruby
require 'rb-fsevent'
fsevent = FSEvent.new
fsevent.watch Dir.pwd do |paths, event_meta|
  event_meta['events'].each do |event|
    puts "event ID: #{event['id']}"
    puts "path: #{event['path']}"
    puts "c flags: #{event['cflags']}"
    puts "named flags: #{event['flags'].join(', ')}"
    # named flags will include strings such as `ItemInodeMetaMod` or `OwnEvent`
  end
end
fsevent.run
```

## Options

When defining options using a hash or hash-like object, it gets checked for validity and converted to the appropriate fsevent\_watch commandline arguments array when the FSEvent class is instantiated. This is obviously the safest and preferred method of passing in options.

You may, however, choose to pass in an array of commandline arguments as your options value and it will be passed on, unmodified, to the fsevent\_watch binary when called.

So far, the following options are supported:

* :latency => 0.5 # in seconds
* :no\_defer => true
* :watch\_root => true
* :since\_when => 18446744073709551615 # an FSEventStreamEventId
* :file\_events => true

### Latency

The :latency parameter determines how long the service should wait after the first event before passing that information along to the client. If your latency is set to 4 seconds, and 300 changes occur in the first three, then the callback will be fired only once. If latency is set to 0.1 in the exact same scenario, you will see that callback fire somewhere closer to between 25 and 30 times.

Setting a higher latency value allows for more effective temporal coalescing, resulting in fewer callbacks and greater overall efficiency... at the cost of apparent responsiveness. Setting this to a reasonably high value (and NOT setting :no\_defer) is particularly well suited for background, daemon, or batch processing applications.

Implementation note: It appears that FSEvents will only coalesce events from a maximum of 32 distinct subpaths, making the above completely accurate only when events are to fewer than 32 subpaths. Creating 300 files in one directory, for example, or 30 files in 10 subdirectories, but not 300 files within 300 subdirectories. In the latter case, you may receive 31 callbacks in one go after the latency period. As this appears to be an implementation detail, the number could potentially differ across OS revisions. It is entirely possible that this number is somehow configurable, but I have not yet discovered an accepted method of doing so.

### NoDefer

The :no\_defer option changes the behavior of the latency parameter completely. Rather than waiting for $latency period of time before sending along events in an attempt to coalesce a potential deluge ahead of time, that first event is sent along to the client immediately and is followed by a $latency period of silence before sending along any additional events that occurred within that period.

This behavior is particularly useful for interactive applications where that feeling of apparent responsiveness is most important, but you still don't want to get overwhelmed by a series of events that occur in rapid succession.

### WatchRoot

The :watch\_root option allows for catching the scenario where you start watching "~/src/demo\_project" and either it is later renamed to "~/src/awesome\_sauce\_3000" or the path changes in such a manner that the original directory is now at "~/clients/foo/iteration4/demo\_project".

Unfortunately, while this behavior is somewhat supported in the fsevent\_watch binary built as part of this project, support for passing across detailed metadata is not (yet). As a result, you would not receive the appropriate RootChanged event and be able to react appropriately. Also, since the C code doesn't open watched directories and retain that file descriptor as part of path-specific callback metadata, we are unable to issue an F\_GETPATH fcntl() to determine the directory's new path.

Please do not use this option until proper support is added (or, even better, add it and submit a pull request).

### SinceWhen

The FSEventStreamEventId passed in to :since\_when is used as a base for reacting to historic events. Unfortunately, not only is the metadata for transitioning from historic to live events not currently passed along, but it is incorrectly passed as a change event on the root path, and only per-host event streams are currently supported. When using per-host event streams, the event IDs are not guaranteed to be unique or contiguous when shared volumes (firewire/USB/net/etc) are used on multiple macs.

Please do not use this option until proper support is added, unless it's acceptable for you to receive that one fake event that's handled incorrectly when events transition from historical to live. Even in that scenario, there's no metadata available for determining the FSEventStreamEventId of the last received event.

WARNING: passing in 0 as the parameter to :since\_when will return events for every directory modified since "the beginning of time".

### FileEvents ###

Prepare yourself for an obscene number of callbacks. Realistically, an "Atomic Save" could easily fire maybe 6 events for the combination of creating the new file, changing metadata/permissions, writing content, swapping out the old file for the new may itself result in multiple events being fired, and so forth. By the time you get the event for the temporary file being created as part of the atomic save, it will already be gone and swapped with the original file. This and issues of a similar nature have prevented me from adding the option to the ruby code despite the fsevent\_watch binary supporting file level events for quite some time now. Mountain Lion seems to be better at coalescing needless events, but that might just be my imagination.

## Debugging output

If the gem is re-compiled with the environment variable FWDEBUG set, then fsevent\_watch will be built with its various DEBUG sections defined, and the output to STDERR is truly verbose (and hopefully helpful in debugging your application and not just fsevent\_watch itself). If enough people find this to be directly useful when developing code that makes use of rb-fsevent, then it wouldn't be hard to clean this up and make it a feature enabled by a commandline argument instead. Until somebody files an issue, however, I will assume otherwise.

    append_path called for: /tmp/moo/cow/
      resolved path to: /private/tmp/moo/cow

    config.sinceWhen    18446744073709551615
    config.latency      0.300000
    config.flags        00000000
    config.paths
      /private/tmp/moo/cow

    FSEventStreamRef @ 0x100108540:
       allocator = 0x7fff705a4ee0
       callback = 0x10000151e
       context = {0, 0x0, 0x0, 0x0, 0x0}
       numPathsToWatch = 1
       pathsToWatch = 0x7fff705a4ee0
            pathsToWatch[0] = '/private/tmp/moo/cow'
       latestEventId = -1
       latency = 300000 (microseconds)
       flags = 0x00000000
       runLoop = 0x0
       runLoopMode = 0x0

    FSEventStreamCallback fired!
      numEvents: 32
      event path: /private/tmp/moo/cow/1/a/
      event flags: 00000000
      event ID: 1023767
      event path: /private/tmp/moo/cow/1/b/
      event flags: 00000000
      event ID: 1023782
      event path: /private/tmp/moo/cow/1/c/
      event flags: 00000000
      event ID: 1023797
      event path: /private/tmp/moo/cow/1/d/
      event flags: 00000000
      event ID: 1023812
      [etc]


## Development

* Source hosted at [GitHub](http://github.com/thibaudgg/rb-fsevent)
* Report issues/Questions/Feature requests on [GitHub Issues](http://github.com/thibaudgg/rb-fsevent/issues)

Pull requests are quite welcome! Please ensure that your commits are in a topic branch for each individual changeset that can be reasonably isolated. It is also important to ensure that your changes are well tested... whether that means new tests, modified tests, or fixing a scenario where the existing tests currently fail. If you have rbenv and ruby-build, we have a helper task for running the testsuite in all of them:

    rake spec:portability

The list of tested targets is currently:

    %w[2.4.1 rbx-3.72 jruby-1.7.26 jruby-9.1.8.0]

## Authors

* [Travis Tilley](http://github.com/ttilley)
* [Thibaud Guillaume-Gentil](http://github.com/thibaudgg)
* [Andrey Tarantsov](https://github.com/andreyvit)
