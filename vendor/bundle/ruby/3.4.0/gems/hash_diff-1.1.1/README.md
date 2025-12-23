# HashDiff

[![Ruby](https://github.com/CodingZeal/hash_diff/actions/workflows/ruby.yml/badge.svg)](https://github.com/CodingZeal/hash_diff/actions/workflows/ruby.yml) [![Code Climate](https://codeclimate.com/github/CodingZeal/hash_diff.png)](https://codeclimate.com/github/CodingZeal/hash_diff) [![Gem Version](https://badge.fury.io/rb/hash_diff.png)](http://badge.fury.io/rb/hash_diff)

Deep comparison of Ruby Hash objects

## Installation

Add this line to your application's Gemfile:

    gem 'hash_diff'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install hash_diff

## Usage

Easily find the differences between two Ruby hashes.

```ruby
  left = {
    foo: 'bar',
    bar: 'foo',
    nested: {
      foo: 'bar',
      bar: {
        one: 'foo1'
      }
    },
    num: 1,
    favorite_restaurant: "Shoney's"
  }

  right = {
    foo: 'bar2',
    bar: 'foo2',
    nested: {
      foo: 'bar2',
      bar: {
        two: 'foo2'
      }
    },
    word: 'monkey',
    favorite_restaurant: nil
  }

  hash_diff = HashDiff::Comparison.new( left, right )
```

Comparison#diff returns the left and right side differences

```ruby
  hash_diff.diff # => { foo: ["bar", "bar2"], bar: ["foo", "foo2"], nested: { foo: ["bar", "bar2"], bar: { one: ["foo1", HashDiff::NO_VALUE], two: [HashDiff::NO_VALUE, "foo2"] } }, num:  [1, HashDiff::NO_VALUE], word: [HashDiff::NO_VALUE, "monkey"], favorite_restaurant: ["Shoney's", nil] }
```

You can also compare two arrays. The comparison is sensitive to the order of the elements in the array.

#### Missing keys

When there is a key that exists on one side it will return `HashDiff::NO_VALUE` to represent a missing key.

Comparison#left_diff returns only the left side differences

```ruby
  hash_diff.left_diff # => {:foo=>"bar2", :bar=>"foo2", :nested=>{:foo=>"bar2", :bar=>{:one=>HashDiff::NO_VALUE, :two=>"foo2"}}, :num=>HashDiff::NO_VALUE, :favorite_restaurant=>nil, :word=>"monkey"}
```

Comparison#right_diff returns only the right side differences

```ruby
  hash_diff.right_diff # => {:foo=>"bar", :bar=>"foo", :nested=>{:foo=>"bar", :bar=>{:one=>"foo1", :two=>HashDiff::NO_VALUE}}, :num=>1, :favorite_restaurant=>"Shoney's", :word=>HashDiff::NO_VALUE}
```

You can also use these shorthand methods

```ruby
  HashDiff.diff(left, right)
  HashDiff.left_diff(left, right)
  HashDiff.right_diff(left, right)
```

Hash#diff is not provided by default, and monkey patching is frowned upon by some, but to provide a one way shorthand call `HashDiff.patch!`

```ruby
  # run prior to implementation
  HashDiff.patch!

  left  = { foo: 'bar', num: 1 }
  right = { foo: 'baz', num: 1 }

  left.diff(right) # => { foo: 'baz' }
```

## License

Authored by the Engineering Team of [Coding ZEAL](https://codingzeal.com?utm_source=github)

Copyright (c) 2017 Zeal, LLC. Licensed under the [MIT license](https://opensource.org/licenses/MIT).

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
