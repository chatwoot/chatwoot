[![Build Status](https://travis-ci.org/tzmfreedom/json_refs.svg?branch=master)](https://travis-ci.org/tzmfreedom/json_refs)

# JsonRefs

Dereference JSON reference with JSON Pointer.

'$refs' value is replaced with referenced value.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'json_refs'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install json_refs

## Usage

```ruby
json = { 'a' => 'foo', 'b' => { '$ref' => '#/a' } }
JsonRefs.(json) # {"a"=>"foo", "b"=>"foo"}
```

local path or remote url is available
```ruby
json = {
  'a' => {
    '$ref' => '/path/to/file'
  },
  'b' => {
    '$ref' => 'http://httpbin.org/user-agent'
  }
}
JsonRefs.(json)
```

YAML is also available for file format.
```ruby
json = {
  'a' => {
    '$ref' => '/path/to/yaml.yml'
  },
  'b' => {
    '$ref' => '/path/to/yaml.yaml'
  }
}
JsonRefs.(json)
```

In case you don't want to resolve local references or file references, you have the following options 
to pass down when you initialize the JSONRefs. If you don't pass the following, both references will be resolved.
```ruby
JsonRefs.(json, { resolve_local_ref: false, resolve_file_ref: true })
```

JSONRef supports recursive reference resolving. If one the files that you reference have another reference in it, JSONRef will try to automatically resolve that.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/tzmfreedom/json_refs.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
