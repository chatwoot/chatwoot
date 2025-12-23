# JSONSchemer

JSON Schema validator. Supports drafts 4, 6, and 7.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'json_schemer'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install json_schemer

## Usage

```ruby
require 'json_schemer'

schema = {
  'type' => 'object',
  'properties' => {
    'abc' => {
      'type' => 'integer',
      'minimum' => 11
    }
  }
}
schemer = JSONSchemer.schema(schema)

# true/false validation

schemer.valid?({ 'abc' => 11 })
# => true

schemer.valid?({ 'abc' => 10 })
# => false

# error validation (`validate` returns an enumerator)

schemer.validate({ 'abc' => 10 }).to_a
# => [{"data"=>10, "schema"=>{"type"=>"integer", "minimum"=>11}, "pointer"=>"#/abc", "type"=>"minimum"}]

# default property values

data = {}
JSONSchemer.schema(
  {
    'properties' => {
      'foo' => {
        'default' => 'bar'
      }
    }
  },
  insert_property_defaults: true
).valid?(data)
data
# => {"foo"=>"bar"}

# schema files

require 'pathname'

schema = Pathname.new('/path/to/schema.json')
schemer = JSONSchemer.schema(schema)

# schema json string

schema = '{ "type": "integer" }'
schemer = JSONSchemer.schema(schema)
```

## Options

```ruby
JSONSchemer.schema(
  schema,

  # validate `format` (https://tools.ietf.org/html/draft-handrews-json-schema-validation-00#section-7)
  # true/false
  # default: true
  format: true,

  # insert default property values during validation
  # true/false
  # default: false
  insert_property_defaults: true,

  # modify properties during validation. You can pass one Proc or a list of Procs to modify data.
  # Proc/[Proc]
  # default: nil
  before_property_validation: proc do |data, property, property_schema, _parent|
    data[property] ||= 42
  end,

  # modify properties after validation. You can pass one Proc or a list of Procs to modify data.
  # Proc/[Proc]
  # default: nil
  after_property_validation: proc do |data, property, property_schema, _parent|
    data[property] = Date.iso8601(data[property]) if property_schema.is_a?(Hash) && property_schema['format'] == 'date'
  end,

  # resolve external references
  # 'net/http'/proc/lambda/respond_to?(:call)
  # 'net/http': proc { |uri| JSON.parse(Net::HTTP.get(uri)) }
  # default: proc { |uri| raise UnknownRef, uri.to_s }
  ref_resolver: 'net/http',
  
  # use different method to match regexes
  # 'ecma'/'ruby'/proc/lambda/respond_to?(:call)
  # default: 'ecma'
  regexp_resolver: proc do |pattern|
    RE2::Regexp.new(pattern)
  end
)
```

## CLI

The `json_schemer` executable takes a JSON schema file as the first argument followed by one or more JSON data files to validate. If there are any validation errors, it outputs them and returns an error code.

Validation errors are output as single-line JSON objects. The `--errors` option can be used to limit the number of errors returned or prevent output entirely (and fail fast).

The schema or data can also be read from stdin using `-`.

```
% json_schemer --help
Usage:
  json_schemer [options] <schema> <data>...
  json_schemer [options] <schema> -
  json_schemer [options] - <data>...
  json_schemer -h | --help
  json_schemer --version

Options:
  -e, --errors MAX                 Maximum number of errors to output
                                   Use "0" to validate with no output
  -h, --help                       Show help
  -v, --version                    Show version
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

## Build Status

![Build Status](https://github.com/davishmcclurg/json_schemer/workflows/ci/badge.svg)

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/davishmcclurg/json_schemer.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
