# IO.console

Add console capabilities to IO instances.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'io-console'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install io-console

## Usage

```ruby
require 'io/console'

IO.console      -> #<File:/dev/tty>
IO.console(sym, *args)
```

Returns a File instance opened console.

If `sym` is given, it will be sent to the opened console with `args` and the result will be returned instead of the console IO itself.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/ruby/io-console.

## License

The gem is available as open source under the terms of the [2-Clause BSD License](https://opensource.org/licenses/BSD-2-Clause).
