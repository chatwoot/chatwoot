# [![{}j](http://www.ohler.com/dev/images/oj_comet_64.svg)](http://www.ohler.com/oj) gem

[![CI](https://github.com/ohler55/oj/actions/workflows/CI.yml/badge.svg)](https://github.com/ohler55/oj/actions/workflows/CI.yml)
![Gem](https://img.shields.io/gem/v/oj.svg)
![Gem](https://img.shields.io/gem/dt/oj.svg)
[![TideLift](https://tidelift.com/badges/github/ohler55/oj)](https://tidelift.com/subscription/pkg/rubygems-oj?utm_source=rubygems-oj&utm_medium=referral&utm_campaign=readme)

A *fast* JSON parser and Object marshaller as a Ruby gem.

Version 3.13 is out with a much faster parser (`Oj::Parser`) and option isolation.

## Using

```ruby
require 'oj'

h = { 'one' => 1, 'array' => [ true, false ] }
json = Oj.dump(h)

# json =
# {
#   "one":1,
#   "array":[
#     true,
#     false
#   ]
# }

h2 = Oj.load(json)
puts "Same? #{h == h2}"
# true
```

## Installation
```
gem install oj
```

or in Bundler:

```
gem 'oj'
```

## Rails and json quickstart

See the Quickstart sections of the [Rails](pages/Rails.md) and [json](pages/JsonGem.md) docs.

## multi_json

Code which uses [multi_json](https://github.com/intridea/multi_json)
will automatically prefer Oj if it is installed.

## Support

[Get supported Oj with a Tidelift Subscription.](https://tidelift.com/subscription/pkg/rubygems-oj?utm_source=rubygems-oj&utm_medium=referral&utm_campaign=readme) Security updates are [supported](https://tidelift.com/security).

## Further Reading

For more details on options, modes, advanced features, and more follow these
links.

 - [{file:Options.md}](pages/Options.md) for parse and dump options.
 - [{file:Modes.md}](pages/Modes.md) for details on modes for strict JSON compliance, mimicking the JSON gem, and mimicking Rails and ActiveSupport behavior.
 - [{file:JsonGem.md}](pages/JsonGem.md) includes more details on json gem compatibility and use.
 - [{file:Rails.md}](pages/Rails.md) includes more details on Rails and ActiveSupport compatibility and use.
 - [{file:Custom.md}](pages/Custom.md) includes more details on Custom mode.
 - [{file:Encoding.md}](pages/Encoding.md) describes the :object encoding format.
 - [{file:Compatibility.md}](pages/Compatibility.md) lists current compatibility with Rubys and Rails.
 - [{file:Advanced.md}](pages/Advanced.md) for fast parser and marshalling features.
 - [{file:Security.md}](pages/Security.md) for security considerations.
 - [{file:InstallOptions.md}](pages/InstallOptions.md) for install option.

## Releases

See [{file:CHANGELOG.md}](CHANGELOG.md) and [{file:RELEASE_NOTES.md}](RELEASE_NOTES.md)

## Links

- *Documentation*: http://www.ohler.com/oj/doc, http://rubydoc.info/gems/oj

- *GitHub* *repo*: https://github.com/ohler55/oj

- *RubyGems* *repo*: https://rubygems.org/gems/oj

Follow [@peterohler on Twitter](http://twitter.com/peterohler) for announcements and news about the Oj gem.

#### Performance Comparisons

 - [Oj Strict Mode Performance](http://www.ohler.com/dev/oj_misc/performance_strict.html) compares Oj strict mode parser performance to other JSON parsers.

 - [Oj Compat Mode Performance](http://www.ohler.com/dev/oj_misc/performance_compat.html) compares Oj compat mode parser performance to other JSON parsers.

 - [Oj Object Mode Performance](http://www.ohler.com/dev/oj_misc/performance_object.html) compares Oj object mode parser performance to other marshallers.

 - [Oj Callback Performance](http://www.ohler.com/dev/oj_misc/performance_callback.html) compares Oj callback parser performance to other JSON parsers.

#### Links of Interest

 - *Fast XML parser and marshaller on RubyGems*: https://rubygems.org/gems/ox

 - *Fast XML parser and marshaller on GitHub*: https://github.com/ohler55/ox

 - [Need for Speed](http://www.ohler.com/dev/need_for_speed/need_for_speed.html) for an overview of how Oj::Doc was designed.

 - *OjC, a C JSON parser*: https://www.ohler.com/ojc also at https://github.com/ohler55/ojc

 - *Agoo, a high performance Ruby web server supporting GraphQL on GitHub*: https://github.com/ohler55/agoo

 - *Agoo-C, a high performance C web server supporting GraphQL on GitHub*: https://github.com/ohler55/agoo-c

 - *oj-introspect, an example of creating an Oj parser extension in C*: https://github.com/meinac/oj-introspect

#### Contributing

+ Provide a Pull Request off the `develop` branch.
+ Report a bug
+ Suggest an idea
+ Code is now formatted with the clang-format tool with the configuration file in the root of the repo.
