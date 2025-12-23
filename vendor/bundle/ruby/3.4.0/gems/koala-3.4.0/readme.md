Koala [![Version](https://img.shields.io/gem/v/koala.svg)](https://rubygems.org/gems/koala) [![Build Status](https://img.shields.io/travis/arsduo/koala.svg)](http://travis-ci.org/arsduo/koala) [![Code Climate](https://img.shields.io/codeclimate/coverage-letter/arsduo/koala.svg)](https://codeclimate.com/github/arsduo/koala) [![Code Coverage](https://img.shields.io/codeclimate/coverage/arsduo/koala.svg)](https://codeclimate.com/github/arsduo/koala)
====
[Koala](http://github.com/arsduo/koala) is a Facebook library for Ruby, supporting the Graph API (including the batch requests and photo uploads), the Marketing API, the Atlas API, realtime updates, test users, and OAuth validation.  We wrote Koala with four goals:

* Lightweight: Koala should be as light and simple as Facebook’s own libraries, providing API accessors and returning simple JSON.
* Fast: Koala should, out of the box, be quick. Out of the box, we use Facebook's faster read-only servers when possible and if available, the Typhoeus gem to make snappy Facebook requests.  Of course, that brings us to our next topic:
* Flexible: Koala should be useful to everyone, regardless of their current configuration.  We support all currently-supported Ruby versions (MRI 2.1-2.4) and Koala should work on JRuby and Rubinius.
* Tested: Koala should have complete test coverage, so you can rely on it.  Our test coverage is complete and can be run against either mocked responses or the live Facebook servers; we're also on [Travis CI](http://travis-ci.org/arsduo/koala/).

**Found a bug? Interested in contributing?** Check out the Maintenance section below!

Installation
------------

**Koala 3.0 is out! There should be no significant changes** for most users. If you encounter any
problems, please file an issue and I'll take a look.

In Bundler:
```ruby
gem "koala"
```

Otherwise:
```bash
[sudo|rvm] gem install koala
```

Configuration
-------------

Most applications will only use one application configuration. Rather than having to provide that
value every time, you can configure Koala to use global settings:

```ruby
# In Rails, you could put this in config/initializers/koala.rb
Koala.configure do |config|
  config.access_token = MY_TOKEN
  config.app_access_token = MY_APP_ACCESS_TOKEN
  config.app_id = MY_APP_ID
  config.app_secret = MY_APP_SECRET
  # See Koala::Configuration for more options, including details on how to send requests through
  # your own proxy servers.
end
```

**Note**: this is not currently threadsafe. (PRs welcome as long as they support both threaded and
non-threaded configuration.)

Graph API
---------

The Graph API is the interface to Facebook's data.  Using it with Koala is quite straightforward.
First, you'll need an access token, which you can get through Facebook's [Graph API
Explorer](https://developers.facebook.com/tools/explorer) (click on 'Get Access Token').

Then, go exploring:

```ruby
require 'koala'

# access_token and other values aren't required if you set the defaults as described above
@graph = Koala::Facebook::API.new(access_token)

profile = @graph.get_object("me")
friends = @graph.get_connections("me", "friends")
@graph.put_connections("me", "feed", message: "I am writing on my wall!")

# Three-part queries are easy too!
@graph.get_connections("me", "mutualfriends/#{friend_id}")

# You can use the Timeline API:
# (see https://developers.facebook.com/docs/beta/opengraph/tutorial/)
@graph.put_connections("me", "namespace:action", object: object_url)

# For extra security (recommended), you can provide an appsecret parameter,
# tying your access tokens to your app secret.
# (See https://developers.facebook.com/docs/reference/api/securing-graph-api/

# You may need to turn on 'Require proof on all calls' in the advanced section
# of your app's settings when doing this.
@graph = Koala::Facebook::API.new(access_token, app_secret)

# Facebook is now versioning their API. # If you don't specify a version, Facebook
# will default to the oldest version your app is allowed to use.
# See https://developers.facebook.com/docs/apps/versions for more information.
#
# You can specify version either globally:
Koala.config.api_version = "v2.0"
# or on a per-request basis
@graph.get_object("me", {}, api_version: "v2.0")
```

The response of most requests is the JSON data returned from the Facebook servers as a Hash.

When retrieving data that returns an array of results (for example, when calling `API#get_connections` or `API#search`)
a GraphCollection object will be returned, which makes it easy to page through the results:

```ruby
# Returns the feed items for the currently logged-in user as a GraphCollection
feed = @graph.get_connections("me", "feed")
feed.each {|f| do_something_with_item(f) } # it's a subclass of Array
next_feed = feed.next_page

# You can also get an array describing the URL for the next page: [path, arguments]
# This is useful for storing page state across multiple browser requests
next_page_params = feed.next_page_params
page = @graph.get_page(next_page_params)
```

You can also make multiple calls at once using Facebook's batch API:
```ruby
# Returns an array of results as if they were called non-batch
@graph.batch do |batch_api|
  batch_api.get_object('me')
  batch_api.put_wall_post('Making a post in a batch.')
end
```

You can pass a "post-processing" block to each of Koala's Graph API methods. This is handy for two reasons:

1. You can modify the result returned by the Graph API method:

        education = @graph.get_object("me") { |data| data['education'] }
        # returned value only contains the "education" portion of the profile

2. You can consume the data in place which is particularly useful in the batch case, so you don't have to pull
the results apart from a long list of array entries:

        @graph.batch do |batch_api|
          # Assuming you have database fields "about_me" and "photos"
          batch_api.get_object('me')                {|me|     self.about_me = me }
          batch_api.get_connections('me', 'photos') {|photos| self.photos   = photos }
        end

Check out the wiki for more details and examples.

App Access Tokens
-----

You get your application's own access token, which can be used without a user session for subscriptions and certain other requests:
```ruby
@oauth = Koala::Facebook::OAuth.new(app_id, app_secret, callback_url)
@oauth.get_app_access_token
```
For those building apps on Facebook, parsing signed requests is simple:
```ruby
@oauth.parse_signed_request(signed_request_string)
```

The OAuth class has additional methods that may occasionally be useful.

Real-time Updates
-----------------

Sometimes, reaching out to Facebook is a pain -- let it reach out to you instead.  The Graph API allows your application to subscribe to real-time updates for certain objects in the graph; check the [official Facebook documentation](http://developers.facebook.com/docs/api/realtime) for more details on what objects you can subscribe to and what limitations may apply.

Koala makes it easy to interact with your applications using the RealtimeUpdates class:
```ruby
# This class also supports the defaults as described above
@updates = Koala::Facebook::RealtimeUpdates.new(app_id: app_id, secret: secret)
```
You can do just about anything with your real-time update subscriptions using the RealtimeUpdates class:
```ruby
# Add/modify a subscription to updates for when the first_name or last_name fields of any of your users is changed
@updates.subscribe("user", "first_name, last_name", callback_url, verify_token)

# Get an array of your current subscriptions (one hash for each object you've subscribed to)
@updates.list_subscriptions

# Unsubscribe from updates for an object
@updates.unsubscribe("user")
```
And to top it all off, RealtimeUpdates provides a static method to respond to Facebook servers' verification of your callback URLs:
```ruby
# Returns the hub.challenge parameter in params if the verify token in params matches verify_token
Koala::Facebook::RealtimeUpdates.meet_challenge(params, your_verify_token)
```
For more information about meet_challenge and the RealtimeUpdates class, check out the Real-Time Updates page on the wiki.

Rate limits
-----------

We support Facebook rate limit informations as defined here: [https://developers.facebook.com/docs/graph-api/overview/rate-limiting/](https://developers.facebook.com/docs/graph-api/overview/rate-limiting/)

The information is available either via the `Facebook::APIError`:

```ruby
error.fb_buc_usage
error.fb_ada_usage
error.fb_app_usage
```

Or with the rate_limit_hook:

```ruby
# App level configuration

Koala.configure do |config|
  config.rate_limit_hook = ->(limits) { 
    limits["x-app-usage"] # {"call_count"=>0, "total_cputime"=>0, "total_time"=>0}
    limits["x-ad-account-usage"] # {"acc_id_util_pct"=>9.67}
    limits["x-business-use-case-usage"] # {"123456789012345"=>[{"type"=>"messenger", "call_count"=>1, "total_cputime"=>1, "total_time"=>1, "estimated_time_to_regain_access"=>0}]}
  }
end

# Per API configuration

Koala::Facebook::API.new('', '', ->(limits) {})
```

Test Users
----------

We also support the test users API, allowing you to conjure up fake users and command them to do your bidding using the Graph API:
```ruby
# This class also supports the defaults as described above
@test_users = Koala::Facebook::TestUsers.new(app_id: id, secret: secret)
user = @test_users.create(is_app_installed, desired_permissions)
user_graph_api = Koala::Facebook::API.new(user["access_token"])
# or, if you want to make a whole community:
@test_users.create_network(network_size, is_app_installed, common_permissions)
```

Talking to Facebook
-------------------

Koala uses Faraday to make HTTP requests, which means you have complete control over how your app makes HTTP requests to Facebook.  You can set Faraday options globally or pass them in on a per-request (or both):
```ruby
# Set an SSL certificate to avoid Net::HTTP errors
Koala.http_service.http_options = {
  ssl: { ca_path: "/etc/ssl/certs" }
}
# or on a per-request basis
@api.get_object(id, args_hash, { request: { timeout: 10 } })
```
The <a href="https://github.com/arsduo/koala/wiki/HTTP-Services">HTTP Services wiki page</a> has more information on what options are available, as well as on how to configure your own Faraday middleware stack (for instance, to implement request logging).

See examples, ask questions
---------------------------

Some resources to help you as you play with Koala and the Graph API:

* Complete Koala documentation <a href="https://github.com/arsduo/koala/wiki">on the wiki</a>
* Facebook's <a href="http://facebook.stackoverflow.com/">Stack Overflow site</a> is a stupendous place to ask questions, filled with people who will help you figure out what's up with the Facebook API.
* Facebook's <a href="http://developers.facebook.com/tools/explorer/">Graph API Explorer</a>, where you can play with the Graph API in your browser

Testing
-------

Unit tests are provided for all of Koala's methods.  By default, these tests run against mock responses and hence are ready out of the box:
```bash
# From anywhere in the project directory:
bundle exec rake spec
```

You can also run live tests against Facebook's servers:
```bash
# Again from anywhere in the project directory:
LIVE=true bundle exec rake spec
# you can also test against Facebook's beta tier
LIVE=true BETA=true bundle exec rake spec
```

By default, the live tests are run against test users, so you can run them as frequently as you want.  If you want to run them against a real user, however, you can fill in the OAuth token, code, and access\_token values in spec/fixtures/facebook_data.yml.  See the wiki for more details.

Maintenance
-----------

_Pull requests_: Koala exists as it does thanks to the amazing support and work of community members of all
backgrounds and levels of experience. Pull requests are very welcome!

_Issues_: If you have any questions about the gem, found an issue in the Ruby code or
documentation, or have another question that isn't right for StackOverflow, just open an issue and fill out the template.

Please note that this project is released with a Contributor Code of Conduct. By participating in
this project you agree to abide by its terms. See
[code_of_conduct.md](https://github.com/arsduo/koala/blob/master/code_of_conduct.md) for more information.
