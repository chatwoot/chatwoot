# crack

[![Test](https://github.com/jnunemaker/crack/actions/workflows/test.yml/badge.svg)](https://github.com/jnunemaker/crack/actions/workflows/test.yml)
[![Gem Version](https://badge.fury.io/rb/crack.svg)](https://badge.fury.io/rb/crack)
![downloads](https://img.shields.io/gem/dt/crack?label=downloads)

Really simple JSON and XML parsing, ripped from Merb and Rails. The XML parser is ripped from Merb and the JSON parser is ripped from Rails. I take no credit, just packaged them for all to enjoy and easily use.

## compatibility

* Ruby 2.x
* Ruby 3.x

## note on patches/pull requests

* Fork the project.
* Make your feature addition or bug fix.
* Add tests for it. This is important so I don't break it in a future version unintentionally.
* Run the tests with `rake test`
* Open a Pull Request with the changes

## usage

```ruby
gem 'crack' # in Gemfile
require 'crack' # for xml and json
require 'crack/json' # for just json
require 'crack/xml' # for just xml
```

## examples

```ruby
Crack::XML.parse("<tag>This is the contents</tag>")
# => {'tag' => 'This is the contents'}

Crack::JSON.parse('{"tag":"This is the contents"}')
# => {'tag' => 'This is the contents'}
```

## Copyright

Copyright (c) 2009 John Nunemaker. See LICENSE for details.
