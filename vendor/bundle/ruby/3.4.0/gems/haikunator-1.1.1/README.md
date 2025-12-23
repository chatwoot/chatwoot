# Haikunator

[![Gem Version](https://badge.fury.io/rb/haikunator.svg)](http://badge.fury.io/rb/haikunator)
[![Build Status](https://travis-ci.org/usmanbashir/haikunator.svg?branch=master)](https://travis-ci.org/usmanbashir/haikunator)
[![Coverage Status](https://coveralls.io/repos/usmanbashir/haikunator/badge.svg)](https://coveralls.io/r/usmanbashir/haikunator)

Generate Heroku-like memorable random names to use in your apps or anywhere else.

## Installation

Add this line to your application's Gemfile:

    gem 'haikunator'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install haikunator

## Usage

Haikunator is pretty simple. There is nothing to configure and it only has a single method, `.haikunate`:

```ruby
Haikunator.haikunate # => "rough-snowflake-1142"

# Token range
Haikunator.haikunate(100) # => "nameless-star-13"

# Don't include the token
Haikunator.haikunate(0) # => "long-flower"

# Use a different delimiter
Haikunator.haikunate(9999, '.') # => "cool.leaf.6743"

# No token, no delimiter
Haikunator.haikunate(0, ' ') # => "green fire"
```

## Contributing

Everyone is encouraged to help improve this project. Here are a few ways you can help:

- [Report bugs](https://github.com/usmanbashir/haikunator/issues)
- Fix bugs and [submit pull requests](https://github.com/usmanbashir/haikunator/pulls)
- Write, clarify, or fix documentation
- Suggest or add new features

## Language Ports

Haikunator has also been ported to other languages. Though, these projects are not
affiliated with or endorsed by me, but check them out:

- Go:
  - [Go-Haikunator](https://github.com/yelinaung/go-haikunator)
  - [Haikunator](https://github.com/gjohnson/haikunator)
  - [Haikunator](https://github.com/taion809/haikunator)
- JavaScript:
  - [HaikunatorJS](https://github.com/Atrox/haikunatorjs)
- Python:
  - [PyHaikunator](https://github.com/ferhatelmas/pyhaikunator)
  - [HaikunatorPy](https://github.com/Atrox/haikunatorpy)
- PHP:
  - [HaikunatorPHP](https://github.com/Atrox/haikunatorphp)
- Elixir:
  - [Haikunator](https://github.com/knrz/Haikunator)
- .NET:
  - [Haikunator.NET](https://github.com/Atrox/haikunator.net)
- Java:
  - [HaikunatorJAVA](https://github.com/Atrox/haikunatorjava)
- Dart:
  - [HaikunatorDART](https://github.com/Atrox/haikunatordart)
- Rust
  - [rust-haikunator](https://github.com/nishanths/rust-haikunator)
- Crystal
  - [Haikunator](https://github.com/sanata-/haikunator)
- R
  - [Haikunator](http://github.com/amrrs/haikunator)
- Clojure
  - [clj-haikunator](https://github.com/staticweb-io/clj-haikunator)
