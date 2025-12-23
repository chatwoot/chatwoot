# OmniAuth OAuth2

[![Gem Version](http://img.shields.io/gem/v/omniauth-oauth2.svg)][gem]
[![Code Climate](http://img.shields.io/codeclimate/maintainability/intridea/omniauth-oauth2.svg)][codeclimate]
[![Coverage Status](http://img.shields.io/coveralls/intridea/omniauth-oauth2.svg)][coveralls]
[![Security](https://hakiri.io/github/omniauth/omniauth-oauth2/master.svg)](https://hakiri.io/github/omniauth/omniauth-oauth2/master)

[gem]: https://rubygems.org/gems/omniauth-oauth2
[codeclimate]: https://codeclimate.com/github/intridea/omniauth-oauth2
[coveralls]: https://coveralls.io/r/intridea/omniauth-oauth2

This gem contains a generic OAuth2 strategy for OmniAuth. It is meant to serve
as a building block strategy for other strategies and not to be used
independently (since it has no inherent way to gather uid and user info).

## Creating an OAuth2 Strategy

To create an OmniAuth OAuth2 strategy using this gem, you can simply subclass
it and add a few extra methods like so:

```ruby
require 'omniauth-oauth2'

module OmniAuth
  module Strategies
    class SomeSite < OmniAuth::Strategies::OAuth2
      # Give your strategy a name.
      option :name, "some_site"

      # This is where you pass the options you would pass when
      # initializing your consumer from the OAuth gem.
      option :client_options, {:site => "https://api.somesite.com"}

      # You may specify that your strategy should use PKCE by setting
      # the pkce option to true: https://tools.ietf.org/html/rfc7636
      option :pkce, true

      # These are called after authentication has succeeded. If
      # possible, you should try to set the UID without making
      # additional calls (if the user id is returned with the token
      # or as a URI parameter). This may not be possible with all
      # providers.
      uid{ raw_info['id'] }

      info do
        {
          :name => raw_info['name'],
          :email => raw_info['email']
        }
      end

      extra do
        {
          'raw_info' => raw_info
        }
      end

      def raw_info
        @raw_info ||= access_token.get('/me').parsed
      end
    end
  end
end
```

That's pretty much it!

## OmniAuth-OAuth2 for Enterprise

Available as part of the Tidelift Subscription.

The maintainers of OmniAuth-OAuth2 and thousands of other packages are working with Tidelift to deliver commercial support and maintenance for the open source packages you use to build your applications. Save time, reduce risk, and improve code health, while paying the maintainers of the exact packages you use. [Learn more.](https://tidelift.com/subscription/pkg/rubygems-omniauth-oauth2?utm_source=undefined&utm_medium=referral&utm_campaign=enterprise)

## Supported Ruby Versions
OmniAuth is tested under 2.5, 2.6, 2.7, truffleruby, and JRuby.
