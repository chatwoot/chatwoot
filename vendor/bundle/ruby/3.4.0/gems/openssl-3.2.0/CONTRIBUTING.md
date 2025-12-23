# Contributing to Ruby OpenSSL

Thank you for your interest in contributing to Ruby OpenSSL!

This documentation provides an overview how you can contribute.

## Bugs and feature requests

Bugs and feature requests are tracked on [GitHub].

If you think you found a bug, file a ticket on GitHub. Please DO NOT report
security issues here, there is a separate procedure which is described on
["Security at ruby-lang.org"](https://www.ruby-lang.org/en/security/).

When reporting a bug, please make sure you include:

* Ruby version (`ruby -v`)
* `openssl` gem version (`gem list openssl` and `OpenSSL::VERSION`)
* OpenSSL library version (`OpenSSL::OPENSSL_VERSION`)
* A sample file that illustrates the problem or link to the repository or
  gem that is associated with the bug.

There are a number of unresolved issues and feature requests for openssl that
need review. Before submitting a new ticket, it is recommended to check
[known issues].

## Submitting patches

Patches are also very welcome!

Please submit a [pull request] with your changes.

Make sure that your branch does:

* Have good commit messages
* Follow Ruby's coding style ([DeveloperHowTo])
* Pass the test suite successfully (see "Testing")

## Testing

We have a test suite!

Test cases are located under the
[`test/openssl`](https://github.com/ruby/openssl/tree/master/test/openssl)
directory.

You can run it with the following three commands:

```
$ bundle install # installs rake-compiler, test-unit, ...
$ bundle exec rake compile
$ bundle exec rake test
```

### With different versions of OpenSSL

Ruby OpenSSL supports various versions of OpenSSL library. The test suite needs
to pass on all supported combinations.

Similarly to when installing `openssl` gem via the `gem` command,
you can pass a `--with-openssl-dir` argument to `rake compile`
to specify the OpenSSL library to build against.

```
$ ( curl -OL https://ftp.openssl.org/source/openssl-3.0.1.tar.gz &&
    tar xf openssl-3.0.1.tar.gz &&
    cd openssl-3.0.1 &&
    ./config --prefix=$HOME/.openssl/openssl-3.0.1 --libdir=lib &&
    make -j4 &&
    make install )

$ # in Ruby/OpenSSL's source directory
$ bundle exec rake clean
$ bundle exec rake compile -- --with-openssl-dir=$HOME/.openssl/openssl-3.0.1
$ bundle exec rake test
```

The GitHub Actions workflow file
[`test.yml`](https://github.com/ruby/openssl/tree/master/.github/workflows/test.yml)
contains useful information for building OpenSSL/LibreSSL and testing against
them.


## Relation with Ruby source tree

After Ruby 2.3, `ext/openssl` was converted into a "default gem", a library
which ships with standard Ruby builds but can be upgraded via RubyGems. This
means the development of this gem has migrated to a [separate
repository][GitHub] and will be released independently.

The version included in the Ruby source tree (trunk branch) is synchronized with
the latest release.

## Release policy

Bug fixes (including security fixes) will be made only for the version series
included in a stable Ruby release.

## Security

If you discovered a security issue, please send us in private, using the
security issue handling procedure for Ruby core.

You can either use [HackerOne] or send an email to security@ruby-lang.org.

Please see [Security] page on ruby-lang.org website for details.

Reported problems will be published after a fix is released.

_Thanks for your contributions!_

  _\- The Ruby OpenSSL team_

[GitHub]: https://github.com/ruby/openssl
[known issues]: https://github.com/ruby/openssl/issues
[DeveloperHowTo]: https://bugs.ruby-lang.org/projects/ruby/wiki/DeveloperHowto
[HackerOne]: https://hackerone.com/ruby
[Security]: https://www.ruby-lang.org/en/security/
[pull request]: https://github.com/ruby/openssl/compare
[History.md]: https://github.com/ruby/openssl/tree/master/History.md
