# URITemplate - a uri template library

[![Build Status](https://secure.travis-ci.org/hannesg/uri_template.png)](http://travis-ci.org/hannesg/uri_template)
[![Dependency Status](https://gemnasium.com/hannesg/uri_template.png)](https://gemnasium.com/hannesg/uri_template)
[![Code Climate](https://codeclimate.com/github/hannesg/uri_template.png)](https://codeclimate.com/github/hannesg/uri_template)
[![Coverage](https://coveralls.io/repos/hannesg/uri_template/badge.png?branch=master)](https://coveralls.io/r/hannesg/uri_template)

With URITemplate you can generate URIs based on simple templates and extract variables from URIs using the same templates. There are currently two syntaxes defined. Namely the one defined in [RFC 6570]( http://tools.ietf.org/html/rfc6570 ) and a colon based syntax, similiar to the one used by sinatra.

From version 0.2.0, it will use escape_utils if available. This will significantly boost uri-escape/unescape performance if more characters need to be escaped ( may be slightly slower in trivial cases. working on that ... ), but does not run everywhere. To enable this, do the following:

```ruby
# escape_utils has to be loaded when uri_templates is loaded
gem 'escape_utils'
require 'escape_utils'

gem 'uri_template'
require 'uri_template'

URITemplate::Utils.using_escape_utils? #=> true
```

## Examples

```ruby
require 'uri_template'

tpl = URITemplate.new('http://{host}{/segments*}/{file}{.extensions*}')

# This will give: http://www.host.com/path/to/a/file.x.y
tpl.expand('host'=>'www.host.com','segments'=>['path','to','a'],'file'=>'file','extensions'=>['x','y'])

# This will give: { 'host'=>'www.host.com','segments'=>['path','to','a'],'file'=>'file','extensions'=>['x','y']}
tpl.extract('http://www.host.com/path/to/a/file.x.y')

# If you like colon templates more:
tpl2 = URITemplate.new(:colon, '/:x/y')

# This will give: {'x' => 'z'}
tpl2.extract('/z/y')

# This will give a new uri template with just the host expanded:
tpl.expand_partial(host: "www.host.com")
```

## RFC 6570 Syntax

The syntax defined by [RFC 6570]( http://tools.ietf.org/html/rfc6570 ) is pretty straight forward. Basically anything surrounded by curly brackets is interpreted as variable.

```ruby
URITemplate.new('{variable}').expand('variable' => 'value') #=> "value"
```

The way variables are inserted can be modified using operators. The operator is the first character between the curly brackets. There are seven operators defined `#`, `+`, `;`, `?`, `&`, `/` and `.`. So if you want to create a form-style query do this:

```ruby
URITemplate.new('{?variable}').expand('variable' => 'value') #=> "?variable=value"
```

## Benchmarks

I have assembled one benchmark based on the uritemplate-test examples. You can find them in the "benchmarks" folder. The short result: uri_template is 2-10x faster than addressable on ruby 1.9.3.
