# Rack::Test
[![Gem Version](https://badge.fury.io/rb/rack-test.svg)](https://badge.fury.io/rb/rack-test)

Code: https://github.com/rack/rack-test

## Description

Rack::Test is a small, simple testing API for Rack apps. It can be used on its
own or as a reusable starting point for Web frameworks and testing libraries
to build on.

## Features

* Allows for submitting requests and testing responses
* Maintains a cookie jar across requests
* Supports request headers used for subsequent requests
* Follow redirects when requested

## Examples

These examples use `test/unit` but it's equally possible to use `rack-test` with
other testing frameworks such as `minitest` or `rspec`.

```ruby
require "test/unit"
require "rack/test"
require "json"

class HomepageTest < Test::Unit::TestCase
  include Rack::Test::Methods

  def app
    lambda { |env| [200, {'content-type' => 'text/plain'}, ['All responses are OK']] }
  end

  def test_response_is_ok
    # Optionally set headers used for all requests in this spec:
    #header 'accept-charset', 'utf-8'

    # First argument is treated as the path
    get '/'

    assert last_response.ok?
    assert_equal 'All responses are OK', last_response.body
  end

  def delete_with_url_params_and_body
    # First argument can have a query string
    #
    # Second argument is used as the parameters for the request, which will be
    # included in the request body for non-GET requests.
    delete '/?foo=bar', JSON.generate('baz' => 'zot')
  end

  def post_with_json
    # Third argument is the rack environment to use for the request.  The following
    # entries in the submitted rack environment are treated specially (in addition
    # to options supported by `Rack::MockRequest#env_for`:
    #
    # :cookie : Set a cookie for the current session before submitting the request.
    #
    # :query_params : Set parameters for the query string (as opposed to the body).
    #                 Value should be a hash of parameters.
    #
    # :xhr : Set HTTP_X_REQUESTED_WITH env key to XMLHttpRequest.
    post(uri, JSON.generate('baz' => 'zot'), 'CONTENT_TYPE' => 'application/json')
  end
end
```

`rack-test` will test the app returned by the `app` method.  If you are loading middleware
in a `config.ru` file, and want to test that, you should load the Rack app created from
the `config.ru` file:

```ruby
OUTER_APP = Rack::Builder.parse_file("config.ru").first

class TestApp < Test::Unit::TestCase
  include Rack::Test::Methods

  def app
    OUTER_APP
  end

  def test_root
    get "/"
    assert last_response.ok?
  end
end
```

## Install

To install the latest release as a gem:

```
gem install rack-test
```

Or add to your `Gemfile`:

```
gem 'rack-test'
```

## Contribution

Contributions are welcome. Please make sure to:

* Use a regular forking workflow
* Write tests for the new or changed behaviour
* Provide an explanation/motivation in your commit message / PR message
* Ensure `History.md` is updated

## Authors

- Contributions from Bryan Helmkamp, Jeremy Evans, Simon Rozet, and others
- Much of the original code was extracted from Merb 1.0's request helper

## License

`rack-test` is released under the [MIT License](MIT-LICENSE.txt).

## Supported platforms

* Ruby 2.0+
* JRuby 9.1+

## Releasing

* Bump VERSION in lib/rack/test/version.rb
* Ensure `History.md` is up-to-date, including correct version and date
* `git commit . -m 'Release $VERSION'`
* `git push`
* `git tag -a -m 'Tag the $VERSION release' $VERSION`
* `git push --tags`
* `gem build rack-test.gemspec`
* `gem push rack-test-$VERSION.gem`
* Add a discussion post for the release
