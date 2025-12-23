# This is a Fork

This is a fork of the official version `3.0.x` branch. Sass need to support older
versions of ruby than Guard wants to support on an ongoing basis, so we are releasing
updates as needed for critical fixes and will support ruby 2.0 and
greater for as long as Sass users need it. Our blog has more information about
ths [Ruby version policy for Sass](http://blog.sass-lang.com/posts/560719).

# Listen

The Listen gem listens to file modifications and notifies you about the changes.

## Features

* OS-optimized adapters on MRI for Mac OS X 10.6+, Linux, \*BSD and Windows, [more info](#listen-adapters) below.
* Detects file modification, addition and removal.
* You can watch multiple directories.
* Regexp-patterns for ignoring paths for more accuracy and speed
* Increased change detection accuracy on OS X HFS and VFAT volumes.
* Tested on MRI Ruby environments (2.0+ only) via [Travis CI](https://travis-ci.org/guard/listen),

## Issues / limitations

* Limited support for symlinked directories ([#279](https://github.com/guard/listen/issues/279)):
  * Symlinks are always followed ([#25](https://github.com/guard/listen/issues/25)).
  * Symlinked directories pointing within a watched directory are not supported ([#273](https://github.com/guard/listen/pull/273)- see [Duplicate directory errors](https://github.com/guard/listen/wiki/Duplicate-directory-errors)).
* No directory/adapter-specific configuration options.
* Support for plugins planned for future.
* TCP functionality was removed in Listen [3.0.0](https://github.com/guard/listen/releases/tag/v3.0.0) ([#319](https://github.com/guard/listen/issues/319), [#218](https://github.com/guard/listen/issues/218)). There are plans to extract this feature to separate gems ([#258](https://github.com/guard/listen/issues/258)), until this is finished, you can use by locking the `listen` gem to version `'~> 2.10'`.
* Some filesystems won't work without polling (VM/Vagrant Shared folders, NFS, Samba, sshfs, etc.).
* Specs suite on JRuby and Rubinius aren't reliable on Travis CI, but should work.
* Windows and \*BSD adapter aren't continuously and automatically tested.
* OSX adapter has some performance limitations ([#342](https://github.com/guard/listen/issues/342)).
* Ruby 1.9.3 is no longer maintained (and may not work with Listen) - it's best to upgrade to Ruby 2.2.2.

Pull requests or help is very welcome for these.

## Install

The simplest way to install Listen is to use [Bundler](http://bundler.io).

```ruby
gem 'listen', '~> 3.0' # NOTE: for TCP functionality, use '~> 2.10' for now
```

## Usage

Call `Listen.to` with either a single directory or multiple directories, then define the "changes" callback in a block.

``` ruby
listener = Listen.to('dir/to/listen', 'dir/to/listen2') do |modified, added, removed|
  puts "modified absolute path: #{modified}"
  puts "added absolute path: #{added}"
  puts "removed absolute path: #{removed}"
end
listener.start # not blocking
sleep
```

### Pause / unpause / stop

Listeners can also be easily paused/unpaused:

``` ruby
listener = Listen.to('dir/path/to/listen') { |modified, added, removed| puts 'handle changes here...' }

listener.start
listener.paused? # => false
listener.processing? # => true

listener.pause   # stops processing changes (but keeps on collecting them)
listener.paused? # => true
listener.processing? # => false

listener.unpause # resumes processing changes ("start" would do the same)
listener.stop    # stop both listening to changes and processing them
```

  Note: While paused, Listen keeps on collecting changes in the background - to clear them, call "stop"

  Note: You should keep track of all started listeners and stop them properly on finish.

### Ignore / ignore!

Listen ignores some directories and extensions by default (See DEFAULT_IGNORED_DIRECTORIES and DEFAULT_IGNORED_EXTENSIONS in Listen::Silencer), you can add ignoring patterns with the `ignore` option/method or overwrite default with `ignore!` option/method.

``` ruby
listener = Listen.to('dir/path/to/listen', ignore: /\.txt/) { |modified, added, removed| # ... }
listener.start
listener.ignore! /\.pkg/ # overwrite all patterns and only ignore pkg extension.
listener.ignore /\.rb/   # ignore rb extension in addition of pkg.
sleep
```

Note: `:ignore` regexp patterns are evaluated against relative paths.

Note: Ignoring paths does not improve performance, except when Polling ([#274](https://github.com/guard/listen/issues/274))

### Only

Listen catches all files (less the ignored ones) by default. If you want to only listen to a specific type of file (i.e., just `.rb` extension), you should use the `only` option/method.

``` ruby
listener = Listen.to('dir/path/to/listen', only: /\.rb$/) { |modified, added, removed| # ... }
listener.start
listener.only /_spec\.rb$/ # overwrite all existing only patterns.
sleep
```

Note: `:only` regexp patterns are evaluated only against relative **file** paths.


## Changes callback

Changes to the listened-to directories gets reported back to the user in a callback.
The registered callback gets invoked, when there are changes, with **three** parameters:
`modified`, `added` and `removed` paths, in that particular order.
Paths are always returned in their absolute form.

Example:

```ruby
listener = Listen.to('path/to/app') do |modified, added, removed|
  # This block will be called when there are changes.
end
listener.start
sleep
```

or ...

```ruby
# Create a callback
callback = Proc.new do |modified, added, removed|
  # This proc will be called when there are changes.
end
listener = Listen.to('dir', &callback)
listener.start
sleep
```

## Options

All the following options can be set through the `Listen.to` after the directory path(s) params.

```ruby
ignore: [%r{/foo/bar}, /\.pid$/, /\.coffee$/]   # Ignore a list of paths
                                                # default: See DEFAULT_IGNORED_DIRECTORIES and DEFAULT_IGNORED_EXTENSIONS in Listen::Silencer

ignore!: %r{/foo/bar}                           # Same as ignore options, but overwrite default ignored paths.

only: %r{.rb$}                                  # Only listen to specific files
                                                # default: none

latency: 0.5                                    # Set the delay (**in seconds**) between checking for changes
                                                # default: 0.25 sec (1.0 sec for polling)

wait_for_delay: 4                               # Set the delay (**in seconds**) between calls to the callback when changes exist
                                                # default: 0.10 sec

force_polling: true                             # Force the use of the polling adapter
                                                # default: none

relative: false                                 # Whether changes should be relative to current dir or not
                                                # default: false

polling_fallback_message: 'custom message'      # Set a custom polling fallback message (or disable it with false)
                                                # default: "Listen will be polling for changes. Learn more at https://github.com/guard/listen#listen-adapters."
```

## Debugging

Setting the environment variable `LISTEN_GEM_DEBUGGING=1` sets up the INFO level logger, while `LISTEN_GEM_DEBUGGING=2` sets up the DEBUG level logger. 

You can also set `Listen.logger` to a custom logger.


## Listen adapters

The Listen gem has a set of adapters to notify it when there are changes.

There are 4 OS-specific adapters to support Darwin, Linux, \*BSD and Windows.
These adapters are fast as they use some system-calls to implement the notifying function.

There is also a polling adapter - although it's much slower than other adapters,
it works on every platform/system and scenario (including network filesystems such as VM shared folders).

The Darwin and Linux adapters are dependencies of the Listen gem so they work out of the box. For other adapters a specific gem will have to be added to your Gemfile, please read below.

The Listen gem will choose the best adapter automatically, if present. If you
want to force the use of the polling adapter, use the `:force_polling` option
while initializing the listener.

### On Windows

If you are on Windows, it's recommended to use the [`wdm`](https://github.com/Maher4Ever/wdm) adapter instead of polling.

Please add the following to your Gemfile:

```ruby
gem 'wdm', '>= 0.1.0' if Gem.win_platform?
```

### On \*BSD

If you are on \*BSD you can try to use the [`rb-kqueue`](https://github.com/mat813/rb-kqueue) adapter instead of polling.

Please add the following to your Gemfile:

```ruby
require 'rbconfig'
if RbConfig::CONFIG['target_os'] =~ /bsd|dragonfly/i
  gem 'rb-kqueue', '>= 0.2'
end

```

### Getting the [polling fallback message](#options)?

Please visit the [installation section of the Listen WIKI](https://github.com/guard/listen/wiki#installation) for more information and options for potential fixes.

### Issues and troubleshooting

*NOTE: without providing the output after setting the `LISTEN_GEM_DEBUGGING=1` environment variable, it can be almost impossible to guess why listen is not working as expected.*

See [TROUBLESHOOTING](https://github.com/guard/listen/wiki/Troubleshooting)

## Performance

If Listen seems slow or unresponsive, make sure you're not using the Polling adapter (you should see a warning upon startup if you are).

Also, if the directories you're watching contain many files, make sure you're:

* not using Polling (ideally)
* using `:ignore` and `:only` options to avoid tracking directories you don't care about (important with Polling and on MacOS)
* running Listen with the `:latency` and `:wait_for_delay` options not too small or too big (depends on needs)
* not watching directories with log files, database files or other frequently changing files
* not using a version of Listen prior to 2.7.7
* not getting silent crashes within Listen (see LISTEN_GEM_DEBUGGING=2)
* not running multiple instances of Listen in the background
* using a file system with atime modification disabled (ideally)
* not using a filesystem with inaccurate file modification times (ideally), e.g. HFS, VFAT
* not buffering to a slow terminal (e.g. transparency + fancy font + slow gfx card + lots of output)
* ideally not running a slow encryption stack, e.g. btrfs + ecryptfs

When in doubt, LISTEN_GEM_DEBUGGING=2 can help discover the actual events and time they happened.

See also [Tips and Techniques](https://github.com/guard/listen/wiki/Tips-and-Techniques).

## Development

* Documentation hosted at [RubyDoc](http://rubydoc.info/github/guard/listen/master/frames).
* Source hosted at [GitHub](https://github.com/guard/listen).

Pull requests are very welcome! Please try to follow these simple rules if applicable:

* Please create a topic branch for every separate change you make.
* Make sure your patches are well tested. All specs must pass on [Travis CI](https://travis-ci.org/guard/listen).
* Update the [Yard](http://yardoc.org/) documentation.
* Update the [README](https://github.com/guard/listen/blob/master/README.md).
* Please **do not change** the version number.

For questions please join us in our [Google group](http://groups.google.com/group/guard-dev) or on
`#guard` (irc.freenode.net).

## Acknowledgments

* [Michael Kessler (netzpirat)][] for having written the [initial specs](https://github.com/guard/listen/commit/1e457b13b1bb8a25d2240428ce5ed488bafbed1f).
* [Travis Tilley (ttilley)][] for this awesome work on [fssm][] & [rb-fsevent][].
* [Nathan Weizenbaum (nex3)][] for [rb-inotify][], a thorough inotify wrapper.
* [Mathieu Arnold (mat813)][] for [rb-kqueue][], a simple kqueue wrapper.
* [Maher Sallam][] for [wdm][], windows support wouldn't exist without him.
* [Yehuda Katz (wycats)][] for [vigilo][], that has been a great source of inspiration.

## Author

[Thibaud Guillaume-Gentil](https://github.com/thibaudgg) ([@thibaudgg](https://twitter.com/thibaudgg))

## Contributors

[https://github.com/guard/listen/graphs/contributors](https://github.com/guard/listen/graphs/contributors)

[Thibaud Guillaume-Gentil (thibaudgg)]: https://github.com/thibaudgg
[Maher Sallam]: https://github.com/Maher4Ever
[Michael Kessler (netzpirat)]: https://github.com/netzpirat
[Travis Tilley (ttilley)]: https://github.com/ttilley
[fssm]: https://github.com/ttilley/fssm
[rb-fsevent]: https://github.com/thibaudgg/rb-fsevent
[Mathieu Arnold (mat813)]: https://github.com/mat813
[Nathan Weizenbaum (nex3)]: https://github.com/nex3
[rb-inotify]: https://github.com/nex3/rb-inotify
[stereobooster]: https://github.com/stereobooster
[rb-fchange]: https://github.com/stereobooster/rb-fchange
[rb-kqueue]: https://github.com/mat813/rb-kqueue
[Yehuda Katz (wycats)]: https://github.com/wycats
[vigilo]: https://github.com/wycats/vigilo
[wdm]: https://github.com/Maher4Ever/wdm
