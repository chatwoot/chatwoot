# Contributing to Google Cloud Storage

1. **Sign one of the contributor license agreements below.**
2. Fork the repo, develop and test your code changes.
3. Send a pull request.

## Contributor License Agreements

Before we can accept your pull requests you'll need to sign a Contributor
License Agreement (CLA):

- **If you are an individual writing original source code** and **you own the
  intellectual property**, then you'll need to sign an [individual
  CLA](https://developers.google.com/open-source/cla/individual).
- **If you work for a company that wants to allow you to contribute your work**,
  then you'll need to sign a [corporate
  CLA](https://developers.google.com/open-source/cla/corporate).

You can sign these electronically (just scroll to the bottom). After that, we'll
be able to accept your pull requests.

## Setup

In order to use the google-cloud-storage console and run the project's tests,
there is a small amount of setup:

1. Install Ruby. google-cloud-storage requires Ruby 2.5+. You may choose to
   manage your Ruby and gem installations with [RVM](https://rvm.io/),
   [rbenv](https://github.com/rbenv/rbenv), or
   [chruby](https://github.com/postmodern/chruby).

2. Install [Bundler](http://bundler.io/).

   ```sh
   $ gem install bundler
   ```

3. Install the top-level project dependencies.

   ```sh
   $ bundle install
   ```

4. Install the Storage dependencies.

   ```sh
   $ cd google-cloud-storage/
   $ bundle install
   ```

## Console

In order to run code interactively, you can automatically load
google-cloud-storage and its dependencies in IRB. This requires that your
developer environment has already been configured by following the steps
described in the {file:AUTHENTICATION.md Authentication Guide}. An IRB console
can be created with:

```sh
$ cd google-cloud-storage/
$ bundle exec rake console
```

## Storage Tests

Tests are very important part of google-cloud-storage. All contributions
should include tests that ensure the contributed code behaves as expected.

To run the unit tests, documentation tests, and code style checks together for a
package:

``` sh
$ cd google-cloud-storage/
$ bundle exec rake ci
```

To run the command above, plus all acceptance tests, use `rake ci:acceptance` or
its handy alias, `rake ci:a`.

### Storage Unit Tests


The project uses the [minitest](https://github.com/seattlerb/minitest) library,
including [specs](https://github.com/seattlerb/minitest#specs),
[mocks](https://github.com/seattlerb/minitest#mocks) and
[minitest-autotest](https://github.com/seattlerb/minitest-autotest).

To run the Storage unit tests:

``` sh
$ cd google-cloud-storage/
$ bundle exec rake test
```

### Storage Documentation Tests

The project tests the code examples in the gem's
[YARD](https://github.com/lsegal/yard)-based documentation.

The example testing functions in a way that is very similar to unit testing, and
in fact the library providing it,
[yard-doctest](https://github.com/p0deje/yard-doctest), is based on the
project's unit test library, [minitest](https://github.com/seattlerb/minitest).

To run the Storage documentation tests:

``` sh
$ cd google-cloud-storage/
$ bundle exec rake doctest
```

If you add, remove or modify documentation examples when working on a pull
request, you may need to update the setup for the tests. The stubs and mocks
required to run the tests are located in `support/doctest_helper.rb`. Please
note that much of the setup is matched by the title of the
[`@example`](http://www.rubydoc.info/gems/yard/file/docs/Tags.md#example) tag.
If you alter an example's title, you may encounter breaking tests.

### Storage Acceptance Tests

The Storage acceptance tests interact with the live service API. Follow the
instructions in the {file:AUTHENTICATION.md Authentication Guide} for enabling
the Storage API. Occasionally, some API features may not yet be generally
available, making it difficult for some contributors to successfully run the
entire acceptance test suite. However, please ensure that you do successfully
run acceptance tests for any code areas covered by your pull request.

To run the acceptance tests, first create and configure a project in the Google
Developers Console, as described in the {file:AUTHENTICATION.md Authentication Guide}. Be sure to download the JSON KEY file. Make note of the PROJECT_ID and
the KEYFILE location on your system.

Before you can run the Storage acceptance tests, you must first create indexes
used in the tests.

#### Running the Storage acceptance tests

To run the Storage acceptance tests:

``` sh
$ cd google-cloud-storage/
$ bundle exec rake acceptance[\\{my-project-id},\\{/path/to/keyfile.json}]
```

Or, if you prefer you can store the values in the `GCLOUD_TEST_PROJECT` and
`GCLOUD_TEST_KEYFILE` environment variables:

``` sh
$ cd google-cloud-storage/
$ export GCLOUD_TEST_PROJECT=\\{my-project-id}
$ export GCLOUD_TEST_KEYFILE=\\{/path/to/keyfile.json}
$ bundle exec rake acceptance
```

If you want to use a different project and credentials for acceptance tests, you
can use the more specific `STORAGE_TEST_PROJECT`  and `STORAGE_TEST_KEYFILE`
environment variables:

``` sh
$ cd google-cloud-storage/
$ export STORAGE_TEST_PROJECT=\\{my-project-id}
$ export STORAGE_TEST_KEYFILE=\\{/path/to/keyfile.json}
$ bundle exec rake acceptance
```

## Coding Style

Please follow the established coding style in the library. The style is is
largely based on [The Ruby Style
Guide](https://github.com/bbatsov/ruby-style-guide) with a few exceptions based
on seattle-style:

* Avoid parenthesis when possible, including in method definitions.
* Always use double quotes strings. ([Option
  B](https://github.com/bbatsov/ruby-style-guide#strings))

You can check your code against these rules by running Rubocop like so:

```sh
$ cd google-cloud-storage/
$ bundle exec rake rubocop
```

## Code of Conduct

Please note that this project is released with a Contributor Code of Conduct. By
participating in this project you agree to abide by its terms. See
{file:CODE_OF_CONDUCT.md Code of Conduct} for more information.
