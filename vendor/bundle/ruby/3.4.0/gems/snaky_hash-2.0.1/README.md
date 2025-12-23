# SnakyHash

This gem is used by the `oauth` and `oauth2` gems, and others, to normalize hash keys and lookups,
and provide a nice psuedo-object interface.

It has its roots in the `Rash` (specifically the [`rash_alt`](https://github.com/shishi/rash_alt) flavor), which is a special `Mash`, made popular by the `hashie` gem.

Classes that include `SnakyHash::Snake` should inherit from `Hashie::Mash`.

## Installation

Install the gem and add to the application's Gemfile by executing:

    $ bundle add snaky_hash

If bundler is not being used to manage dependencies, install the gem by executing:

    $ gem install snaky_hash

## Usage

```ruby
class MySnakedHash < Hashie::Mash
  include SnakyHash::Snake.new(key_type: :string) # or :symbol
end

snake = MySnakedHash.new(a: "a", "b" => "b", 2 => 2, "VeryFineHat" => "Feathers")
snake.a # => 'a'
snake.b # => 'b'
snake[2] # 2
snake.very_fine_hat # => 'Feathers'
snake[:very_fine_hat] # => 'Feathers'
snake["very_fine_hat"] # => 'Feathers'
```

Note above that you can access the values via the string, or symbol.
The `key_type` determines how the key is actually stored, but the hash acts as "indifferent".
Note also that keys which do not respond to `to_sym`, because they don't have a natural conversion to a Symbol,
are left as-is.

### Stranger Things

I don't recommend using these features... but they exist (for now).
You can still access the original un-snaked camel keys.
And through them you can even use un-snaked camel methods.

```ruby
snake.key?("VeryFineHat") # => true
snake["VeryFineHat"] # => 'Feathers'
snake.VeryFineHat # => 'Feathers', PLEASE don't do this!!!
snake["VeryFineHat"] = "pop" # Please don't do this... you'll get a warning, and it works (for now), but no guarantees.
# WARN -- : You are setting a key that conflicts with a built-in method MySnakedHash#VeryFineHat defined in MySnakedHash. This can cause unexpected behavior when accessing the key as a property. You can still access the key via the #[] method.
# => "pop"
snake.very_fine_hat = "pop" # => 'pop', do this instead!!!
snake.very_fine_hat # => 'pop'
snake[:very_fine_hat] = "moose" # => 'moose', or do this instead!!!
snake.very_fine_hat # => 'moose'
snake["very_fine_hat"] = "cheese" # => 'cheese', or do this instead!!!
snake.very_fine_hat # => 'cheese'
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://gitlab.com/oauth-xx/snaky_hash. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://gitlab.com/oauth-xx/snaky_hash/-/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the SnakyHash project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://gitlab.com/oauth-xx/snaky_hash/-/blob/main/CODE_OF_CONDUCT.md).
