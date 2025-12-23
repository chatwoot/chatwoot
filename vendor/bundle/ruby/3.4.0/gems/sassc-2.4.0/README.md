# SassC [![Build Status](https://travis-ci.org/sass/sassc-ruby.svg?branch=master)](https://travis-ci.org/sass/sassc-ruby) [![Gem Version](https://badge.fury.io/rb/sassc.svg)](http://badge.fury.io/rb/sassc)

Use `libsass` with Ruby!

This gem combines the speed of `libsass`, the [Sass C implementation](https://github.com/sass/libsass), with the ease of use of the original [Ruby Sass](https://github.com/sass/ruby-sass) library.

### libsass Version

[3.6.1](https://github.com/sass/libsass/releases/3.6.1)

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'sassc'
```

And then execute:

```bash
bundle
```

Or install it yourself as:

```bash
gem install sassc
```

## Usage

This library utilizes `libsass` to allow you to compile SCSS or SASS syntax
to CSS.  To compile, use a `SassC::Engine`, e.g.:

```ruby
SassC::Engine.new(sass, style: :compressed).render
```

**Note**:  If you want to use this library with Rails/Sprockets, check out
[sassc-rails](https://github.com/bolandrm/sassc-rails).

Additionally, you can use `SassC::Sass2Scss` to convert Sass syntax to Scss syntax.

## Credits

This gem is maintained by [Ryan Boland](https://ryanboland.com)
and [awesome contributors](https://github.com/bolandrm/sassc-ruby/graphs/contributors).

## Changelog

See [CHANGELOG.md](CHANGELOG.md).

## Contributing

### Project Setup

1. Clone repo
1. Install dependencies - `bundle install`
1. Run the tests - `bundle exec rake test`

### Code Changes

1. Fork it ( https://github.com/sass/sassc-ruby/fork )
1. Create your feature branch (`git checkout -b my-new-feature`)
1. Commit your changes (`git commit -am 'Add some feature'`) - try to include tests
1. Push to the branch (`git push origin my-new-feature`)
1. Create a new Pull Request
