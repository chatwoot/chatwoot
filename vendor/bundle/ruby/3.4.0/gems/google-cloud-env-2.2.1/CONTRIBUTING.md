# Contributing to Google Cloud Ruby Client

1. **Sign one of the contributor license agreements below.**
2. Fork the repo, develop and test your code changes.
3. Send a pull request.

## Contributor License Agreements

Before we can accept your pull requests you'll need to sign a Contributor License Agreement (CLA):

- **If you are an individual writing original source code** and **you own the intellectual property**, then you'll need to sign an [individual CLA](https://developers.google.com/open-source/cla/individual).
- **If you work for a company that wants to allow you to contribute your work**, then you'll need to sign a [corporate CLA](https://developers.google.com/open-source/cla/corporate).

You can sign these electronically (just scroll to the bottom). After that, we'll be able to accept your pull requests.

## Setup

In order to use the google-cloud-ruby console and run the project's tests, there is a
small amount of setup:

1.  Install Ruby.
    google-cloud-env requires Ruby 2.4+. You may choose to manage your Ruby and gem installations with [RVM](https://rvm.io/), [rbenv](https://github.com/rbenv/rbenv), or [chruby](https://github.com/postmodern/chruby).

2.  Install [Bundler](http://bundler.io/).

    ```sh
    $ gem install bundler
    ```

3.  Install the project dependencies.

    ```sh
    $ bundle install
    ```

## Tests

All contributions should include tests that ensure the contributed code behaves as expected.

To run the tests and code style checks together:

``` sh
$ bundle exec rake ci
```

### Unit Tests

The project uses the [minitest](https://github.com/seattlerb/minitest) library, including [specs](https://github.com/seattlerb/minitest#specs), [mocks](https://github.com/seattlerb/minitest#mocks) and [minitest-autotest](https://github.com/seattlerb/minitest-autotest).

To run the unit tests for a package:

``` sh
$ bundle exec rake test
```

### Coding Style

Please follow the established coding style in the library. The style is is largely based on [The Ruby Style Guide](https://github.com/bbatsov/ruby-style-guide) with a few exceptions based on seattle-style:

* Avoid parenthesis when possible, including in method definitions.
* Always use double quotes strings. ([Option B](https://github.com/bbatsov/ruby-style-guide#strings))

You can check your code against these rules by running Rubocop like so:

```sh
$ bundle exec rake rubocop
```

## Code of Conduct

Please note that this project is released with a Contributor Code of Conduct. By participating in this project you agree to abide by its terms. See {file:CODE_OF_CONDUCT.md Code of Conduct} for more information.
