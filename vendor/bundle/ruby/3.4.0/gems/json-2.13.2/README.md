# JSON implementation for Ruby

[![CI](https://github.com/ruby/json/actions/workflows/ci.yml/badge.svg)](https://github.com/ruby/json/actions/workflows/ci.yml)

## Description

This is an implementation of the JSON specification according to RFC 7159
http://www.ietf.org/rfc/rfc7159.txt .

The JSON generator generate UTF-8 character sequences by default.
If an :ascii\_only option with a true value is given, they escape all
non-ASCII and control characters with \uXXXX escape sequences, and support
UTF-16 surrogate pairs in order to be able to generate the whole range of
unicode code points.

All strings, that are to be encoded as JSON strings, should be UTF-8 byte
sequences on the Ruby side. To encode raw binary strings, that aren't UTF-8
encoded, please use the to\_json\_raw\_object method of String (which produces
an object, that contains a byte array) and decode the result on the receiving
endpoint.

## Installation

Install the gem and add to the application's Gemfile by executing:

    $ bundle add json

If bundler is not being used to manage dependencies, install the gem by executing:

    $ gem install json

## Basic Usage

To use JSON you can

```ruby
require 'json'
```

Now you can parse a JSON document into a ruby data structure by calling

```ruby
JSON.parse(document)
```

If you want to generate a JSON document from a ruby data structure call
```ruby
JSON.generate(data)
```

You can also use the `pretty_generate` method (which formats the output more
verbosely and nicely) or `fast_generate` (which doesn't do any of the security
checks generate performs, e. g. nesting deepness checks).

## Casting non native types

JSON documents can only support Hashes, Arrays, Strings, Integers and Floats.

By default if you attempt to serialize something else, `JSON.generate` will
search for a `#to_json` method on that object:

```ruby
Position = Struct.new(:latitude, :longitude) do
  def to_json(state = nil, *)
    JSON::State.from_state(state).generate({
      latitude: latitude,
      longitude: longitude,
    })
  end
end

JSON.generate([
  Position.new(12323.234, 435345.233),
  Position.new(23434.676, 159435.324),
]) # => [{"latitude":12323.234,"longitude":435345.233},{"latitude":23434.676,"longitude":159435.324}]
```

If a `#to_json` method isn't defined on the object, `JSON.generate` will fallback to call `#to_s`:

```ruby
JSON.generate(Object.new) # => "#<Object:0x000000011e768b98>"
```

Both of these behavior can be disabled using the `strict: true` option:

```ruby
JSON.generate(Object.new, strict: true) # => Object not allowed in JSON (JSON::GeneratorError)
JSON.generate(Position.new(1, 2)) # => Position not allowed in JSON (JSON::GeneratorError)
```

## JSON::Coder

Since `#to_json` methods are global, it can sometimes be problematic if you need a given type to be
serialized in different ways in different locations.

Instead it is recommended to use the newer `JSON::Coder` API:

```ruby
module MyApp
  API_JSON_CODER = JSON::Coder.new do |object|
    case object
    when Time
      object.iso8601(3)
    else
      object
    end
  end
end

puts MyApp::API_JSON_CODER.dump(Time.now.utc) # => "2025-01-21T08:41:44.286Z"
```

The provided block is called for all objects that don't have a native JSON equivalent, and
must return a Ruby object that has a native JSON equivalent.

## Combining JSON fragments

To combine JSON fragments into a bigger JSON document, you can use `JSON::Fragment`:

```ruby
posts_json = cache.fetch_multi(post_ids) do |post_id|
  JSON.generate(Post.find(post_id))
end
posts_json.map! { |post_json| JSON::Fragment.new(post_json) }
JSON.generate({ posts: posts_json, count: posts_json.count })
```

## Round-tripping arbitrary types

> [!CAUTION]
> You should never use `JSON.unsafe_load` nor `JSON.parse(str, create_additions: true)` to parse untrusted user input,
> as it can lead to remote code execution vulnerabilities.

To create a JSON document from a ruby data structure, you can call
`JSON.generate` like that:

```ruby
json = JSON.generate [1, 2, {"a"=>3.141}, false, true, nil, 4..10]
# => "[1,2,{\"a\":3.141},false,true,null,\"4..10\"]"
```

To get back a ruby data structure from a JSON document, you have to call
JSON.parse on it:

```ruby
JSON.parse json
# => [1, 2, {"a"=>3.141}, false, true, nil, "4..10"]
```

Note, that the range from the original data structure is a simple
string now. The reason for this is, that JSON doesn't support ranges
or arbitrary classes. In this case the json library falls back to call
`Object#to_json`, which is the same as `#to_s.to_json`.

It's possible to add JSON support serialization to arbitrary classes by
simply implementing a more specialized version of the `#to_json method`, that
should return a JSON object (a hash converted to JSON with `#to_json`) like
this (don't forget the `*a` for all the arguments):

```ruby
class Range
  def to_json(*a)
    {
      'json_class'   => self.class.name, # = 'Range'
      'data'         => [ first, last, exclude_end? ]
    }.to_json(*a)
  end
end
```

The hash key `json_class` is the class, that will be asked to deserialise the
JSON representation later. In this case it's `Range`, but any namespace of
the form `A::B` or `::A::B` will do. All other keys are arbitrary and can be
used to store the necessary data to configure the object to be deserialised.

If the key `json_class` is found in a JSON object, the JSON parser checks
if the given class responds to the `json_create` class method. If so, it is
called with the JSON object converted to a Ruby hash. So a range can
be deserialised by implementing `Range.json_create` like this:

```ruby
class Range
  def self.json_create(o)
    new(*o['data'])
  end
end
```

Now it possible to serialise/deserialise ranges as well:

```ruby
json = JSON.generate [1, 2, {"a"=>3.141}, false, true, nil, 4..10]
# => "[1,2,{\"a\":3.141},false,true,null,{\"json_class\":\"Range\",\"data\":[4,10,false]}]"
JSON.parse json
# => [1, 2, {"a"=>3.141}, false, true, nil, 4..10]
json = JSON.generate [1, 2, {"a"=>3.141}, false, true, nil, 4..10]
# => "[1,2,{\"a\":3.141},false,true,null,{\"json_class\":\"Range\",\"data\":[4,10,false]}]"
JSON.unsafe_load json
# => [1, 2, {"a"=>3.141}, false, true, nil, 4..10]
```

`JSON.generate` always creates the shortest possible string representation of a
ruby data structure in one line. This is good for data storage or network
protocols, but not so good for humans to read. Fortunately there's also
`JSON.pretty_generate` (or `JSON.pretty_generate`) that creates a more readable
output:

```ruby
 puts JSON.pretty_generate([1, 2, {"a"=>3.141}, false, true, nil, 4..10])
 [
   1,
   2,
   {
     "a": 3.141
   },
   false,
   true,
   null,
   {
     "json_class": "Range",
     "data": [
       4,
       10,
       false
     ]
   }
 ]
```

There are also the methods `Kernel#j` for generate, and `Kernel#jj` for
`pretty_generate` output to the console, that work analogous to Core Ruby's `p` and
the `pp` library's `pp` methods.

## Development

### Prerequisites

1. Clone the repository
2. Install dependencies with `bundle install`

### Testing

The full test suite can be run with:

```bash
bundle exec rake test
```

### Release

Update the `lib/json/version.rb` file.

```
rbenv shell 2.6.5
rake build
gem push pkg/json-2.3.0.gem

rbenv shell jruby-9.2.9.0
rake build
gem push pkg/json-2.3.0-java.gem
```

## Author

Florian Frank <mailto:flori@ping.de>

## License

Ruby License, see https://www.ruby-lang.org/en/about/license.txt.

## Download

The latest version of this library can be downloaded at

* https://rubygems.org/gems/json

Online Documentation should be located at

* https://www.rubydoc.info/gems/json

[Ragel]: http://www.colm.net/open-source/ragel/
