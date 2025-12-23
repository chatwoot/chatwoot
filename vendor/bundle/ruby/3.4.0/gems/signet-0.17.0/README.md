# Signet

<dl>
  <dt>Homepage</dt><dd><a href="https://github.com/googleapis/signet/">https://github.com/googleapis/signet/</a></dd>
  <dt>Author</dt><dd><a href="mailto:bobaman@google.com">Bob Aman</a></dd>
  <dt>Copyright</dt><dd>Copyright © 2010 Google, Inc.</dd>
  <dt>License</dt><dd>Apache 2.0</dd>
</dl>

[![Gem Version](https://badge.fury.io/rb/signet.svg)](https://badge.fury.io/rb/signet)

## Description

Signet is an OAuth 1.0 / OAuth 2.0 implementation.

## Reference

- {Signet::OAuth1}
- {Signet::OAuth1::Client}
- {Signet::OAuth1::Credential}
- {Signet::OAuth1::Server}
- {Signet::OAuth2}
- {Signet::OAuth2::Client}

## Example Usage for Google

# Initialize the client

``` ruby
require 'signet/oauth_2/client'
client = Signet::OAuth2::Client.new(
  :authorization_uri => 'https://accounts.google.com/o/oauth2/auth',
  :token_credential_uri =>  'https://oauth2.googleapis.com/token',
  :client_id => "#{YOUR_CLIENT_ID}.apps.googleusercontent.com",
  :client_secret => YOUR_CLIENT_SECRET,
  :scope => 'email profile',
  :redirect_uri => 'https://example.client.com/oauth'
)
```

# Request an authorization code

```
redirect_to(client.authorization_uri)
```

# Obtain an access token

```
client.code = request.query['code']
client.fetch_access_token!
```

## Install

`gem install signet`

Be sure `https://rubygems.org` is in your gem sources.

## Supported Ruby Versions

This library is supported on Ruby 2.5+.

Google provides official support for Ruby versions that are actively supported
by Ruby Core—that is, Ruby versions that are either in normal maintenance or in
security maintenance, and not end of life. Currently, this means Ruby 2.5 and
later. Older versions of Ruby _may_ still work, but are unsupported and not
recommended. See https://www.ruby-lang.org/en/downloads/branches/ for details
about the Ruby support schedule.
