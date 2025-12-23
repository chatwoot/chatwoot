# Listen

The `listen` gem listens to file modifications and notifies you about the changes.

[![Development Status](https://github.com/guard/listen/workflows/Development/badge.svg)](https://github.com/guard/listen/actions?workflow=Development)
[![Gem Version](https://badge.fury.io/rb/listen.svg)](http://badge.fury.io/rb/listen)
[![Code Climate](https://codeclimate.com/github/guard/listen.svg)](https://codeclimate.com/github/guard/listen)
[![Coverage Status](https://coveralls.io/repos/guard/listen/badge.svg?branch=master)](https://coveralls.io/r/guard/listen)

## Features

* OS-optimized adapters on MRI for Mac OS X 10.6+, Linux, \*BSD and Windows, [more info](#listen-adapters) below.
* Detects file modification, addition and removal.
* You can watch multiple directories.
* Regexp-patterns for ignoring paths for more accuracy and speed
* Increased change detection accuracy on OS X HFS and VFAT volumes.
* Continuous Integration: tested on selected Ruby environments via [Github Workflows](https:///github.com/guard/listen/master/.github/workflows).

## Issues / limitations

* Limited support for symlinked directories ([#279](https://github.com/guard/listen/issues/279)):
  * Symlinks are always followed ([#25](https://github.com/guard/listen/issues/25)).
  * Symlinked directories pointing within a watched directory are not supported ([#273](https://github.com/guard/listen/pull/273).
* No directory/adapter-specific configuration options.
* Support for plugins planned for future.
* TCP functionality was removed in `listen` [3.0.0](https://github.com/guard/listen/releases/tag/v3.0.0) ([#319](https://github.com/guard/listen/issues/319), [#218](https://github.com/guard/listen/issues/218)). There are plans to extract this feature to separate gems ([#258](https://github.com/guard/listen/issues/258)), until this is finished, you can use by locking the `listen` gem to version `'~> 2.10'`.
* Some filesystems won't work without polling (VM/Vagrant Shared folders, NFS, Samba, sshfs, etc.).
* Windows and \*BSD adapter aren't continuously and automatically tested.
* OSX adapter has some performance limitations ([#342](https://github.com/guard/listen/issues/342)).
* Listeners do not notify across forked processes, if you wish for multiple processes to receive change notifications you must [listen inside of each process](https://github.com/guard/listen/issues/398#issuecomment-223957952).

Pull requests or help is very welcome for these.

## Install

The simplest way to install `listen` is to use [Bundler](http://bundler.io).

```ruby
gem 'listen'
```

## Complete Example
Here is a complete example of using the `listen` gem:
```ruby
require 'listen'

listener = Listen.to('/srv/app') do |modified, added, removed|
  puts(modified: modified, added: added, removed: removed)
end
listener.start
sleep
```
Running the above in the background, you can see the callback block being called in response to each command:
```
$ cd /srv/app
$ touch a.txt
{:modified=>[], :added=>["/srv/app/a.txt"], :removed=>[]}

$ echo more >> a.txt
{:modified=>["/srv/app/a.txt"], :added=>[], :removed=>[]}

$ mv a.txt b.txt
{:modified=>[], :added=>["/srv/app/b.txt"], :removed=>["/srv/app/a.txt"]}

$ vi b.txt
# add a line to this new file and press ZZ to save and exit
{:modified=>["/srv/app/b.txt"], :added=>[], :removed=>[]}

$ vi c.txt
# add a line and press ZZ to save and exit
{:modified=>[], :added=>["/srv/app/c.txt"], :removed=>[]}

$ rm b.txt c.txt
{:modified=>[], :added=>[], :removed=>["/srv/app/b.txt", "/srv/app/c.txt"]}
```

## Usage

Call `Listen.to` with one or more directories and the "changes" callback passed as a block.

``` ruby
listener = Listen.to('dir/to/listen', 'dir/to/listen2') do |modified, added, removed|
  puts "modified absolute path array: #{modified}"
  puts "added absolute path array: #{added}"
  puts "removed absolute path array: #{removed}"
end
listener.start # starts a listener thread--does not block

# do whatever you want here...just don't exit the process :)

sleep
```
## Changes Callback

Changes to the listened-to directories are reported by the listener thread in a callback.
The callback receives **three** array parameters: `modified`, `added` and `removed`, in that order.
Each of these three is always an array with 0 or more entries.
Each array entry is an absolute path.

### Pause / start / stop

Listeners can also be easily paused and later un-paused with start:

``` ruby
listener = Listen.to('dir/path/to/listen') { |modified, added, removed| puts 'handle changes here...' }

listener.start
listener.paused?     # => false
listener.processing? # => true

listener.pause       # stops processing changes (but keeps on collecting them)
listener.paused?     # => true
listener.processing? # => false

listener.start       # resumes processing changes
listener.stop        # stop both listening to changes and processing them
```

  Note: While paused, `listen` keeps on collecting changes in the background - to clear them, call `stop`.

  Note: You should keep track of all started listeners and `stop` them properly on finish.

### Ignore / ignore!

`Listen` ignores some directories and extensions by default (See DEFAULT_IGNORED_FILES and DEFAULT_IGNORED_EXTENSIONS in Listen::Silencer).
You can add ignoring patterns with the `ignore` option/method or overwrite default with `ignore!` option/method.

``` ruby
listener = Listen.to('dir/path/to/listen', ignore: /\.txt/) { |modified, added, removed| # ... }
listener.start
listener.ignore! /\.pkg/ # overwrite all patterns and only ignore pkg extension.
listener.ignore /\.rb/   # ignore rb extension in addition of pkg.
sleep
```

Note: `:ignore` regexp patterns are evaluated against relative paths.

Note: Ignoring paths does not improve performance, except when Polling ([#274](https://github.com/guard/listen/issues/274)).

### Only

`Listen` watches all files (less the ignored ones) by default. If you want to only listen to a specific type of file (i.e., just `.rb` extension), you should use the `only` option/method.

``` ruby
listener = Listen.to('dir/path/to/listen', only: /\.rb$/) { |modified, added, removed| # ... }
listener.start
listener.only /_spec\.rb$/ # overwrite all existing only patterns.
sleep
```

Note: `:only` regexp patterns are evaluated only against relative **file** paths.


## Options

All the following options can be set through the `Listen.to` after the directory path(s) params.

```ruby
ignore: [%r{/foo/bar}, /\.pid$/, /\.coffee$/]   # Ignore a list of paths
                                                # default: See DEFAULT_IGNORED_FILES and DEFAULT_IGNORED_EXTENSIONS in Listen::Silencer

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

## Logging and Debugging

`Listen` logs its activity to `Listen.logger`.
This is the primary method of debugging.

### Custom Logger
You can call `Listen.logger =` to set a custom `listen` logger for the process. For example:
```
Listen.logger = Rails.logger
```

### Default Logger
If no custom logger is set, a default `listen` logger which logs to to `STDERR` will be created and assigned to `Listen.logger`.

The default logger defaults to the `error` logging level (severity).
You can override the logging level by setting the environment variable `LISTEN_GEM_DEBUGGING=<level>`.
For `<level>`, all standard `::Logger` levels are supported, with any mix of upper-/lower-case:
```
export LISTEN_GEM_DEBUGGING=debug # or 2 [deprecated]
export LISTEN_GEM_DEBUGGING=info  # or 1 or true or yes [deprecated]
export LISTEN_GEM_DEBUGGING=warn
export LISTEN_GEM_DEBUGGING=fatal
export LISTEN_GEM_DEBUGGING=error
```
The default of `error` will be used if an unsupported value is set.

Note: The alternate values `1`, `2`, `true` and `yes` shown above are deprecated and will be removed from `listen` v4.0.

### Disabling Logging
If you want to disable `listen` logging, set
```
Listen.logger = ::Logger.new('/dev/null')
```
## Listen Adapters

The `Listen` gem has a set of adapters to notify it when there are changes.

There are 4 OS-specific adapters to support Darwin, Linux, \*BSD and Windows.
These adapters are fast as they use some system-calls to implement the notifying function.

There is also a polling adapter - although it's much slower than other adapters,
it works on every platform/system and scenario (including network filesystems such as VM shared folders).

The Darwin and Linux adapters are dependencies of the `listen` gem so they work out of the box. For other adapters a specific gem will have to be added to your Gemfile, please read below.

The `listen` gem will choose the best adapter automatically, if present. If you
want to force the use of the polling adapter, use the `:force_polling` option
while initializing the listener.

### On Windows

If you are on Windows, it's recommended to use the [`wdm`](https://github.com/Maher4Ever/wdm) adapter instead of polling.

Please add the following to your Gemfile:

```ruby
gem 'wdm', '>= 0.1.0', platforms: [:mingw, :mswin, :x64_mingw, :jruby]
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

If you see:
```
Listen will be polling for changes.
```

This means the Listen gem can’t find an optimized adapter. Typically this is caused by:

- You’re on Windows and WDM gem isn’t installed.
- You’re running the app without Bundler or RubyGems.
- Using Sass which includes an ancient (the “dinosaur” type of ancient) version of the Listen gem.

Possible solutions:

1. Suppress the message by using the :force_polling option. Or, you could just ignore the message since it’s harmless.
2. Windows users: Install the WDM gem.
3. Upgrade Ruby (use RubyInstaller for Windows or RVM/rbenv for Mac) and RubyGems.
3. Run your apps using Bundler.
4. Sass users: Install the latest version of Listen and try again.

#### Simplified Bundler and Sass example
Create a Gemfile with these lines:
```
source 'https://rubygems.org'
gem 'listen'
gem 'sass'
```
Next, use Bundler to update gems:
```
$ bundle update
$ bundle exec sass --watch # ... or whatever app is using Listen.
```

### Increasing the amount of inotify watchers

If you are running Debian, RedHat, or another similar Linux distribution, run the following in a terminal:
```
$ sudo sh -c "echo fs.inotify.max_user_watches=524288 >> /etc/sysctl.conf"
$ sudo sysctl -p
```
If you are running ArchLinux, search the `/etc/sysctl.d/` directory for config files with the setting:
```
$ grep -H -s "fs.inotify.max_user_watches" /etc/sysctl.d/*
/etc/sysctl.d/40-max_user_watches.conf:fs.inotify.max_user_watches=100000
```
Then change the setting in the file you found above to a higher value (see [here](https://www.archlinux.org/news/deprecation-of-etcsysctlconf/) for why):
```
$ sudo sh -c "echo fs.inotify.max_user_watches=524288 > /etc/sysctl.d/40-max-user-watches.conf"
$ sudo sysctl --system
```

#### The technical details
Listen uses `inotify` by default on Linux to monitor directories for changes.
It's not uncommon to encounter a system limit on the number of files you can monitor.
For example, Ubuntu Lucid's (64bit) `inotify` limit is set to 8192.

You can get your current inotify file watch limit by executing:
```
$ cat /proc/sys/fs/inotify/max_user_watches
```
When this limit is not enough to monitor all files inside a directory, the limit must be increased for Listen to work properly.

You can set a new limit temporarily with:
```
$ sudo sysctl fs.inotify.max_user_watches=524288
$ sudo sysctl -p
```
If you like to make your limit permanent, use:
```
$ sudo sh -c "echo fs.inotify.max_user_watches=524288 >> /etc/sysctl.conf"
$ sudo sysctl -p
```
You may also need to pay attention to the values of `max_queued_events` and `max_user_instances` if Listen keeps on complaining.

#### More info
Man page for [inotify(7)](https://linux.die.net/man/7/inotify).
Blog post: [limit of inotify](https://blog.sorah.jp/2012/01/24/inotify-limitation).

### Issues and Troubleshooting

If the gem doesn't work as expected, start by setting `LISTEN_GEM_DEBUGGING=debug` or `LISTEN_GEM_DEBUGGING=info` as described above in [Logging and Debugging](#logging-and-debugging).

*NOTE: without providing the output after setting the `LISTEN_GEM_DEBUGGING=debug` environment variable, it is usually impossible to guess why `listen` is not working as expected.*

#### 3 steps before you start diagnosing problems
These 3 steps will:

- help quickly troubleshoot obscure problems (trust me, most of them are obscure)
- help quickly identify the area of the problem (a full list is below)
- help you get familiar with listen's diagnostic mode (it really comes in handy, trust me)
- help you create relevant output before you submit an issue (so we can respond with answers instead of tons of questions)

Step 1 - The most important option in Listen
For effective troubleshooting set the `LISTEN_GEM_DEBUGGING=info` variable before starting `listen`.

Step 2 - Verify polling works
Polling has to work ... or something is really wrong (and we need to know that before anything else).

(see force_polling option).

After starting `listen`, you should see something like:
```
INFO -- : Record.build(): 0.06773114204406738 seconds
```
Step 3 - Trigger some changes directly without using editors or apps
Make changes e.g. touch foo or echo "a" >> foo (for troubleshooting, avoid using an editor which could generate too many misleading events).

You should see something like:
```
INFO -- : listen: raw changes: [[:added, "/home/me/foo"]]
INFO -- : listen: final changes: {:modified=>[], :added=>["/home/me/foo"], :removed=>[]}
```
"raw changes" contains changes collected during the :wait_for_delay and :latency intervals, while "final changes" is what listen decided are relevant changes (for better editor support).

## Performance

If `listen` seems slow or unresponsive, make sure you're not using the Polling adapter (you should see a warning upon startup if you are).

Also, if the directories you're watching contain many files, make sure you're:

* not using Polling (ideally)
* using `:ignore` and `:only` options to avoid tracking directories you don't care about (important with Polling and on MacOS)
* running `listen` with the `:latency` and `:wait_for_delay` options not too small or too big (depends on needs)
* not watching directories with log files, database files or other frequently changing files
* not using a version of `listen` prior to 2.7.7
* not getting silent crashes within `listen` (see `LISTEN_GEM_DEBUGGING=debug`)
* not running multiple instances of `listen` in the background
* using a file system with atime modification disabled (ideally)
* not using a filesystem with inaccurate file modification times (ideally), e.g. HFS, VFAT
* not buffering to a slow terminal (e.g. transparency + fancy font + slow gfx card + lots of output)
* ideally not running a slow encryption stack, e.g. btrfs + ecryptfs

When in doubt, `LISTEN_GEM_DEBUGGING=debug` can help discover the actual events and time they happened.

## Tips and Techniques
- Watch only directories you're interested in.
- Set your editor to save quickly (e.g. without backup files, without atomic-save)
- Tweak the `:latency` and `:wait_for_delay` options until you get good results (see [options](#options)).
- Add `:ignore` rules to silence all events you don't care about (reduces a lot of noise, especially if you use it on directories)

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

## Releasing

### Prerequisites

* You must have commit rights to the GitHub repository.
* You must have push rights for rubygems.org.

### How to release

1. Run `bundle install` to make sure that you have all the gems necessary for testing and releasing.
2.  **Ensure all tests are passing by running `bundle exec rake`.**
3. Determine which would be the correct next version number according to [semver](http://semver.org/).
4. Update the version in `./lib/listen/version.rb`.
5. Update the version in the Install section of `./README.md` (`gem 'listen', '~> X.Y'`).
6. Commit the version in a single commit, the message should be "Preparing vX.Y.Z"
7. Run `bundle exec rake release:full`; this will tag, push to GitHub, and publish to rubygems.org.
8. Update and publish the release notes on the [GitHub releases page](https://github.com/guard/listen/releases) if necessary

## Acknowledgments

* [Michael Kessler (netzpirat)][] for having written the [initial specs](https://github.com/guard/listen/commit/1e457b13b1bb8a25d2240428ce5ed488bafbed1f).
* [Travis Tilley (ttilley)][] for this awesome work on [fssm][] & [rb-fsevent][].
* [Natalie Weizenbaum (nex3)][] for [rb-inotify][], a thorough inotify wrapper.
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
[Natalie Weizenbaum (nex3)]: https://github.com/nex3
[rb-inotify]: https://github.com/nex3/rb-inotify
[stereobooster]: https://github.com/stereobooster
[rb-fchange]: https://github.com/stereobooster/rb-fchange
[rb-kqueue]: https://github.com/mat813/rb-kqueue
[Yehuda Katz (wycats)]: https://github.com/wycats
[vigilo]: https://github.com/wycats/vigilo
[wdm]: https://github.com/Maher4Ever/wdm
