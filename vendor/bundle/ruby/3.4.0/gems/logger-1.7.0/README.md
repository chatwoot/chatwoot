# Logger

Logger is a simple but powerful logging utility to output messages in your Ruby program.

Logger has the following features:

 * Print messages to different levels such as `info` and `error`
 * Auto-rolling of log files
 * Setting the format of log messages
 * Specifying a program name in conjunction with the message

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'logger'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install logger

## Usage

### Simple Example

```ruby
require 'logger'

# Create a Logger that prints to STDOUT
log = Logger.new(STDOUT)
log.debug("Created Logger")

log.info("Program finished")

# Create a Logger that prints to STDERR
error_log = Logger.new(STDERR)
error_log = error_log.error("fatal error")
```

## Development

After checking out the repo, run the following to install dependencies.

```
$ bin/setup
```

Then, run the tests as:

```
$ rake test
```

To install this gem onto your local machine, run

```
$ rake install
```

To release a new version, update the version number in `lib/logger/version.rb`, and then run

```
$ rake release
```

which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Advanced Development

### Run tests of a specific file

```
$ ruby test/logger/test_logger.rb
```

### Run tests filtering test methods by a name

`--name` option is available as:

```
$ ruby test/logger/test_logger.rb --name test_lshift
```

### Publish documents to GitHub Pages

```
$ rake gh-pages
```

Then, git commit and push the generated HTMLs onto `gh-pages` branch.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/ruby/logger.

## License

The gem is available as open source under the terms of the [BSD-2-Clause](BSDL).
