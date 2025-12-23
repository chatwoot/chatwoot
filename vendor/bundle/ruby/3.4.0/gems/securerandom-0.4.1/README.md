# Securerandom

This library is an interface to secure random number generators which are
suitable for generating session keys in HTTP cookies, etc.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'securerandom'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install securerandom

## Usage

Generate random hexadecimal strings:

```ruby
require 'securerandom'

SecureRandom.hex(10) #=> "52750b30ffbc7de3b362"
SecureRandom.hex(10) #=> "92b15d6c8dc4beb5f559"
SecureRandom.hex(13) #=> "39b290146bea6ce975c37cfc23"
```

Generate random base64 strings:

```ruby
SecureRandom.base64(10) #=> "EcmTPZwWRAozdA=="
SecureRandom.base64(10) #=> "KO1nIU+p9DKxGg=="
SecureRandom.base64(12) #=> "7kJSM/MzBJI+75j8"
```

Generate random binary strings:

```ruby
SecureRandom.random_bytes(10) #=> "\016\t{\370g\310pbr\301"
SecureRandom.random_bytes(10) #=> "\323U\030TO\234\357\020\a\337"
```

Generate alphanumeric strings:

```ruby
SecureRandom.alphanumeric(10) #=> "S8baxMJnPl"
SecureRandom.alphanumeric(10) #=> "aOxAg8BAJe"
```

Generate UUIDs:

```ruby
SecureRandom.uuid #=> "2d931510-d99f-494a-8c67-87feb05e1594"
SecureRandom.uuid #=> "bad85eb9-0713-4da7-8d36-07a8e4b00eab"
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/ruby/securerandom.

