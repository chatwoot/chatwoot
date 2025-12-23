# OpenStruct [![Version](https://badge.fury.io/rb/ostruct.svg)](https://badge.fury.io/rb/ostruct) [![Default Gem](https://img.shields.io/badge/stdgem-default-9c1260.svg)](https://stdgems.org/ostruct/) [![Test](https://github.com/ruby/ostruct/workflows/test/badge.svg)](https://github.com/ruby/ostruct/actions?query=workflow%3Atest)

An OpenStruct is a data structure, similar to a Hash, that allows the definition of arbitrary attributes with their accompanying values. This is accomplished by using Ruby's metaprogramming to define methods on the class itself.

## Installation

The `ostruct` library comes pre-packaged with Ruby. No installation is necessary.

## Usage

```ruby
  require "ostruct"

  person = OpenStruct.new
  person.name = "John Smith"
  person.age  = 70

  person.name      # => "John Smith"
  person.age       # => 70
  person.address   # => nil
```

An OpenStruct employs a Hash internally to store the attributes and values and can even be initialized with one:

```ruby
  australia = OpenStruct.new(:country => "Australia", :capital => "Canberra")
    # => #<OpenStruct country="Australia", capital="Canberra">
```

Hash keys with spaces or characters that could normally not be used for method calls (e.g. <code>()[]*</code>) will not be immediately available on the OpenStruct object as a method for retrieval or assignment, but can still be reached through the Object#send method.

```ruby
  measurements = OpenStruct.new("length (in inches)" => 24)
  measurements.send("length (in inches)")   # => 24

  message = OpenStruct.new(:queued? => true)
  message.queued?                           # => true
  message.send("queued?=", false)
  message.queued?                           # => false
```

Removing the presence of an attribute requires the execution of the delete_field method as setting the property value to +nil+ will not remove the attribute.

```ruby
  first_pet  = OpenStruct.new(:name => "Rowdy", :owner => "John Smith")
  second_pet = OpenStruct.new(:name => "Rowdy")

  first_pet.owner = nil
  first_pet                 # => #<OpenStruct name="Rowdy", owner=nil>
  first_pet == second_pet   # => false

  first_pet.delete_field(:owner)
  first_pet                 # => #<OpenStruct name="Rowdy">
  first_pet == second_pet   # => true
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/ruby/ostruct.

## License

The gem is available as open source under the terms of the [2-Clause BSD License](https://opensource.org/licenses/BSD-2-Clause).
