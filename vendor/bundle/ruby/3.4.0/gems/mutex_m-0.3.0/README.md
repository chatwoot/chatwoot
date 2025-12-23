# Mutex_m

When 'mutex_m' is required, any object that extends or includes Mutex_m will be treated like a Mutex.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'mutex_m'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install mutex_m

## Usage

Start by requiring the standard library Mutex_m:

```ruby
require "mutex_m"
```

From here you can extend an object with Mutex instance methods:

```ruby
obj = Object.new
obj.extend Mutex_m
```

Or mixin Mutex_m into your module to your class inherit Mutex instance methods.
You should probably use `prepend` to mixin (if you use `include`, you need to
make sure that you call `super` inside `initialize`).

```ruby
class Foo
  prepend Mutex_m
  # ...
end

obj = Foo.new
# this obj can be handled like Mutex
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/ruby/mutex_m.

## License

The gem is available as open source under the terms of the [2-Clause BSD License](https://opensource.org/licenses/BSD-2-Clause).
