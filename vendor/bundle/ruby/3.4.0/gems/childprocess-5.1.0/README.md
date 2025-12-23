# childprocess

This gem aims at being a simple and reliable solution for controlling
external programs running in the background on any Ruby / OS combination.

The code originated in the [selenium-webdriver](https://rubygems.org/gems/selenium-webdriver) gem, but should prove useful as
a standalone library.

[![CI](https://github.com/enkessler/childprocess/actions/workflows/ci.yml/badge.svg)](https://github.com/enkessler/childprocess/actions/workflows/ci.yml)
![Gem Version](https://img.shields.io/gem/v/childprocess)
[![Code Climate](https://codeclimate.com/github/enkessler/childprocess.svg)](https://codeclimate.com/github/enkessler/childprocess)
[![Coverage Status](https://coveralls.io/repos/enkessler/childprocess/badge.svg?branch=master)](https://coveralls.io/r/enkessler/childprocess?branch=master)

# Requirements

* Ruby 2.4+, JRuby 9+

# Usage

The object returned from `ChildProcess.build` will implement `ChildProcess::AbstractProcess`.

### Basic examples

```ruby
process = ChildProcess.build("ruby", "-e", "sleep")

# inherit stdout/stderr from parent...
process.io.inherit!

# ...or pass an IO
process.io.stdout = Tempfile.new("child-output")

# modify the environment for the child
process.environment["a"] = "b"
process.environment["c"] = nil

# set the child's working directory
process.cwd = '/some/path'

# start the process
process.start

# check process status
process.alive?    #=> true
process.exited?   #=> false

# wait indefinitely for process to exit...
process.wait
process.exited?   #=> true

# get the exit code
process.exit_code #=> 0

# ...or poll for exit + force quit
begin
  process.poll_for_exit(10)
rescue ChildProcess::TimeoutError
  process.stop # tries increasingly harsher methods to kill the process.
end
```

### Advanced examples

#### Output to pipe

```ruby
r, w = IO.pipe

begin
  process = ChildProcess.build("sh" , "-c",
                               "for i in {1..3}; do echo $i; sleep 1; done")
  process.io.stdout = w
  process.start # This results in a subprocess inheriting the write end of the pipe.

  # Close parent's copy of the write end of the pipe so when the child
  # process closes its write end of the pipe the parent receives EOF when
  # attempting to read from it. If the parent leaves its write end open, it
  # will not detect EOF.
  w.close

  thread = Thread.new do
    begin
      loop do
        print r.readpartial(16384)
      end
    rescue EOFError
      # Child has closed the write end of the pipe
    end
  end

  process.wait
  thread.join
ensure
  r.close
end
```

Note that if you just want to get the output of a command, the backtick method on Kernel may be a better fit.

#### Write to stdin

```ruby
process = ChildProcess.build("cat")

out      = Tempfile.new("duplex")
out.sync = true

process.io.stdout = process.io.stderr = out
process.duplex    = true # sets up pipe so process.io.stdin will be available after .start

process.start
process.io.stdin.puts "hello world"
process.io.stdin.close

process.poll_for_exit(exit_timeout_in_seconds)

out.rewind
out.read #=> "hello world\n"
```

#### Pipe output to another ChildProcess

```ruby
search           = ChildProcess.build("grep", '-E', %w(redis memcached).join('|'))
search.duplex    = true # sets up pipe so search.io.stdin will be available after .start
search.io.stdout = $stdout
search.start

listing           = ChildProcess.build("ps", "aux")
listing.io.stdout = search.io.stdin
listing.start
listing.wait

search.io.stdin.close
search.wait
```

### Ensure entire process tree dies

By default, the child process does not create a new process group. This means there's no guarantee that the entire process tree will die when the child process is killed. To solve this:

```ruby
process = ChildProcess.build(*args)
process.leader = true
process.start
```

#### Detach from parent

```ruby
process = ChildProcess.build("sleep", "10")
process.detach = true
process.start
```

#### Invoking a shell

As opposed to `Kernel#system`, `Kernel#exec` et al., ChildProcess will not automatically execute your command in a shell (like `/bin/sh` or `cmd.exe`) depending on the arguments.
This means that if you try to execute e.g. gem executables (like `bundle` or `gem`) or Windows executables (with `.com` or `.bat` extensions) you may see a `ChildProcess::LaunchError`.
You can work around this by being explicit about what interpreter to invoke:

```ruby
ChildProcess.build("cmd.exe", "/c", "bundle")
ChildProcess.build("ruby", "-S", "bundle")
```

#### Log to file

Errors and debugging information are logged to `$stderr` by default but a custom logger can be used instead.

```ruby
logger = Logger.new('logfile.log')
logger.level = Logger::DEBUG
ChildProcess.logger = logger
```

## Caveats

* With JRuby on Unix, modifying `ENV["PATH"]` before using childprocess could lead to 'Command not found' errors, since JRuby is unable to modify the environment used for PATH searches in `java.lang.ProcessBuilder`. This can be avoided by setting `ChildProcess.posix_spawn = true`.
* With JRuby on Java >= 9, the JVM may need to be configured to allow JRuby to access neccessary implementations; this can be done by adding `--add-opens java.base/java.io=org.jruby.dist` and `--add-opens java.base/sun.nio.ch=org.jruby.dist` to the `JAVA_OPTS` environment variable that is used by JRuby when launching the JVM.

# Implementation

ChildProcess 5+ uses `Process.spawn` from the Ruby core library for maximum portability.

# Note on Patches/Pull Requests

1. Fork it
2. Create your feature branch (off of the development branch)
   `git checkout -b my-new-feature dev`
3. Commit your changes
   `git commit -am 'Add some feature'`
4. Push to the branch
   `git push origin my-new-feature`
5. Create new Pull Request

# Publishing a New Release

When publishing a new gem release:

1. Ensure [latest build is green on the `dev` branch](https://travis-ci.org/enkessler/childprocess/branches)
2. Ensure [CHANGELOG](CHANGELOG.md) is updated
3. Ensure [version is bumped](lib/childprocess/version.rb) following [Semantic Versioning](https://semver.org/)
4. Merge the `dev` branch into `master`: `git checkout master && git merge dev`
5. Ensure [latest build is green on the `master` branch](https://travis-ci.org/enkessler/childprocess/branches)
6. Build gem from the green `master` branch: `git checkout master && gem build childprocess.gemspec`
7. Push gem to RubyGems: `gem push childprocess-<VERSION>.gem`
8. Tag commit with version, annotated with release notes: `git tag -a <VERSION>`

# Copyright

Copyright (c) 2010-2015 Jari Bakken. See [LICENSE](LICENSE) for details.
