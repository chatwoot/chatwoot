# OpenSSL for Ruby

[![Actions Status](https://github.com/ruby/openssl/workflows/CI/badge.svg)](https://github.com/ruby/openssl/actions?workflow=CI)

**OpenSSL for Ruby** provides access to SSL/TLS and general-purpose
cryptography based on the OpenSSL library.

OpenSSL for Ruby is sometimes referred to as **openssl** in all lowercase
or **Ruby/OpenSSL** for disambiguation.

## Compatibility and maintenance policy

OpenSSL for Ruby is released as a RubyGems gem. At the same time, it is part of
the standard library of Ruby. This is called a [default gem].

Each stable branch of OpenSSL for Ruby will remain supported as long as it is
included as a default gem in [supported Ruby branches][Ruby Maintenance Branches].

|Version|Maintenance status             |Ruby compatibility|OpenSSL compatibility                       |
|-------|-------------------------------|------------------|--------------------------------------------|
|3.2.x  |normal maintenance (Ruby 3.3)  |Ruby 2.7+         |OpenSSL 1.0.2-3.1 (current) or LibreSSL 3.1+|
|3.1.x  |normal maintenance (Ruby 3.2)  |Ruby 2.6+         |OpenSSL 1.0.2-3.1 (current) or LibreSSL 3.1+|
|3.0.x  |normal maintenance (Ruby 3.1)  |Ruby 2.6+         |OpenSSL 1.0.2-3.1 (current) or LibreSSL 3.1+|
|2.2.x  |security maintenance (Ruby 3.0)|Ruby 2.3+         |OpenSSL 1.0.1-1.1.1 or LibreSSL 2.9+        |
|2.1.x  |end-of-life (Ruby 2.5-2.7)     |Ruby 2.3+         |OpenSSL 1.0.1-1.1.1 or LibreSSL 2.5+        |
|2.0.x  |end-of-life (Ruby 2.4)         |Ruby 2.3+         |OpenSSL 0.9.8-1.1.1 or LibreSSL 2.3+        |

[default gem]: https://docs.ruby-lang.org/en/master/standard_library_rdoc.html
[Ruby Maintenance Branches]: https://www.ruby-lang.org/en/downloads/branches/

## Installation

> **Note**
> The openssl gem is included with Ruby by default, but you may wish to upgrade
> it to a newer version available at
> [rubygems.org](https://rubygems.org/gems/openssl).

To upgrade it, you can use RubyGems:

```
gem install openssl
```

In some cases, it may be necessary to specify the path to the installation
directory of the OpenSSL library.

```
gem install openssl -- --with-openssl-dir=/opt/openssl
```

Alternatively, you can install the gem with Bundler:

```ruby
# Gemfile
gem 'openssl'
# or specify git master
gem 'openssl', git: 'https://github.com/ruby/openssl'
```

After running `bundle install`, you should have the gem installed in your bundle.

## Usage

Once installed, you can require "openssl" in your application.

```ruby
require "openssl"
```

## Documentation

See https://ruby.github.io/openssl/.

## Contributing

Please read our [CONTRIBUTING.md] for instructions.

[CONTRIBUTING.md]: https://github.com/ruby/openssl/tree/master/CONTRIBUTING.md

## Security

Security issues should be reported to ruby-core by following the process
described on ["Security at ruby-lang.org"](https://www.ruby-lang.org/en/security/).
