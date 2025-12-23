# ruby2_keywords

Provides empty `Module#ruby2_keywords` method, for the forward
source-level compatibility against ruby2.7 and ruby3.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'ruby2_keywords'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install ruby2_keywords

## Usage

For class/module instance methods:

```ruby
require 'ruby2_keywords'

module YourModule
  ruby2_keywords def delegating_method(*args)
    other_method(*args)
  end
end
```

For global methods:

```ruby
require 'ruby2_keywords'

ruby2_keywords def oldstyle_keywords(options = {})
end
```

You can do the same for a method defined by `Module#define_method`:

```ruby
define_method :delegating_method do |*args, &block|
  other_method(*args, &block)
end
ruby2_keywords :delegating_method
```

## Contributing

Bug reports and pull requests are welcome on [GitHub] or
[Ruby Issue Tracking System].

## Development

After checking out the repo, run `bundle install` to install dependencies.
Then, run `bundle exec rake test` to run the tests.

To test on older Ruby versions, you can use docker. E.g. to test on Ruby 2.0,
use `docker-compose run ruby-2.0`.

## License

The gem is available as open source under the terms of the
[Ruby License] or the [2-Clause BSD License].

[GitHub]: https://github.com/ruby/ruby2_keywords/
[Ruby Issue Tracking System]: https://bugs.ruby-lang.org
[Ruby License]: https://www.ruby-lang.org/en/about/license.txt
[2-Clause BSD License]: https://opensource.org/licenses/BSD-2-Clause
