## Webauthn and the future of 2FA

Although this library will continue to be maintained, if you're implementing a 2FA solution today, you should take a look at [Webauthn](https://webauthn.guide/). It doesn't involve shared secrets and it's supported by most modern browsers and operating systems.

### Ruby resources for Webauthn

- [Multi-Factor Authentication for Rails With WebAuthn and Devise](https://www.honeybadger.io/blog/multi-factor-2fa-authentication-rails-webauthn-devise/)
- [Webauthn Ruby Gem](https://github.com/cedarcode/webauthn-ruby)
- [Rails demo app with Webauthn](https://github.com/cedarcode/webauthn-rails-demo-app)

----

# The Ruby One Time Password Library

[![Build Status](https://github.com/mdp/rotp/actions/workflows/test.yaml/badge.svg)](https://github.com/mdp/rotp/actions/workflows/test.yaml)
[![Gem Version](https://badge.fury.io/rb/rotp.svg)](https://rubygems.org/gems/rotp)
[![Documentation](http://img.shields.io/badge/docs-rdoc.info-blue.svg)](https://www.rubydoc.info/github/mdp/rotp/master)
[![License](https://img.shields.io/badge/license-MIT-blue.svg?style=flat)](https://github.com/mdp/rotp/blob/master/LICENSE)


A ruby library for generating and validating one time passwords (HOTP & TOTP) according to [RFC 4226](https://datatracker.ietf.org/doc/html/rfc4226) and [RFC 6238](https://datatracker.ietf.org/doc/html/rfc6238).

ROTP is compatible with [Google Authenticator](https://github.com/google/google-authenticator) available for [Android](https://play.google.com/store/apps/details?id=com.google.android.apps.authenticator2) and [iPhone](https://itunes.apple.com/en/app/google-authenticator/id388497605) and any other TOTP based implementations.

Many websites use this for [multi-factor authentication](https://www.youtube.com/watch?v=17rykTIX_HY), such as GMail, Facebook, Amazon EC2, WordPress, and Salesforce. You can find a more complete [list here](https://en.wikipedia.org/wiki/Google_Authenticator#Usage).

## Dependencies

* OpenSSL
* Ruby 2.3 or higher

## Breaking changes

### Breaking changes in >= 6.0

- Dropping support for Ruby <2.3

### Breaking changes in >= 5.0

- `ROTP::Base32.random_base32` is now `ROTP::Base32.random` and the argument
  has changed from secret string length to byte length to allow for more
  precision. There is an alias to allow for `random_base32` for the time being.
- Cleaned up the Base32 implementation to match Google Authenticator's version.

### Breaking changes in >= 4.0

- Simplified API
  - `verify` now takes options for `drift` and `after`,`padding` is no longer an option
  - `verify` returns a timestamp if true, nil if false
- Dropping support for Ruby < 2.0
- Docs for 3.x can be found [here](https://github.com/mdp/rotp/tree/v3.x)

## Installation

```bash
gem install rotp
```

## Library Usage

### Time based OTP's

```ruby
totp = ROTP::TOTP.new("base32secret3232", issuer: "My Service")
totp.now # => "492039"

# OTP verified for current time - returns timestamp of the current interval
# period.
totp.verify("492039") # => 1474590700

sleep 30

# OTP fails to verify - returns nil
totp.verify("492039") # => nil
```

### Counter based OTP's

```ruby
hotp = ROTP::HOTP.new("base32secretkey3232")
hotp.at(0) # => "786922"
hotp.at(1) # => "595254"
hotp.at(1401) # => "259769"

# OTP verified with a counter
hotp.verify("259769", 1401) # => 1401
hotp.verify("259769", 1402) # => nil
```

### Preventing reuse of Time based OTP's

By keeping track of the last time a user's OTP was verified, we can prevent token reuse during
the interval window (default 30 seconds)

The following is an example of this in action:

```ruby
user = User.find(someUserID)
totp = ROTP::TOTP.new(user.otp_secret)
totp.now # => "492039"

# Let's take a look at the last time the user authenticated with an OTP
user.last_otp_at # => 1432703530

# Verify the OTP
last_otp_at = totp.verify("492039", after: user.last_otp_at) #=> 1472145760
# ROTP returns the timestamp(int) of the current period

# Store this on the user's account
user.update(last_otp_at: last_otp_at)

# Someone attempts to reuse the OTP inside the 30s window
last_otp_at = totp.verify("492039", after: user.last_otp_at) #=> nil
# It fails to verify because we are still in the same 30s interval window
```

### Verifying a Time based OTP with drift

Some users may enter a code just after it has expired. By adding 'drift' you can allow
for a recently expired token to remain valid.

```ruby
totp = ROTP::TOTP.new("base32secret3232")
now = Time.at(1474590600) #2016-09-23 00:30:00 UTC
totp.at(now) # => "250939"

# OTP verified for current time along with 15 seconds earlier
# ie. User enters a code just after it expired
totp.verify("250939", drift_behind: 15, at: now + 35) # => 1474590600
# User waits too long. Fails to validate previous OTP
totp.verify("250939", drift_behind: 15, at: now + 45) # => nil
```

### Generating a Base32 Secret key

```ruby
ROTP::Base32.random  # returns a 160 bit (32 character) base32 secret. Compatible with Google Authenticator
```

Note: The Base32 format conforms to [RFC 4648 Base32](http://en.wikipedia.org/wiki/Base32#RFC_4648_Base32_alphabet)

### Generating QR Codes for provisioning mobile apps

Provisioning URI's generated by ROTP are compatible with most One Time Password applications, including
Google Authenticator.

```ruby
totp = ROTP::TOTP.new("base32secret3232", issuer: "My Service")
totp.provisioning_uri("alice@google.com") # => 'otpauth://totp/My%20Service:alice%40google.com?secret=base32secret3232&issuer=My%20Service'

hotp = ROTP::HOTP.new("base32secret3232", issuer: "My Service")
hotp.provisioning_uri("alice@google.com", 0) # => 'otpauth://hotp/My%20Service:alice%40google.com?secret=base32secret3232&issuer=My%20Service&counter=0'
```

This can then be rendered as a QR Code which the user can scan using their mobile phone and the appropriate application.

#### Working example

Scan the following barcode with your phone, using Google Authenticator

![QR Code for OTP](https://cloud.githubusercontent.com/assets/2868/18771262/54f109dc-80f2-11e6-863f-d2be62ee587a.png)

Now run the following and compare the output

```ruby
require 'rubygems'
require 'rotp'
totp = ROTP::TOTP.new("JBSWY3DPEHPK3PXP")
p "Current OTP: #{totp.now}"
```

### Testing

```bash
bundle install
bundle exec rspec
```

### Testing with Docker

In order to make it easier to test against different ruby version, ROTP comes
with a set of Dockerfiles for each version that we test against in Travis

```bash
docker build -f Dockerfile-2.6 -t rotp_2.6 .
docker run --rm -v $(pwd):/usr/src/app rotp_2.6
```

Alternately, you may use docker-compose to run all the tests:

```
docker-compose up
```

## Executable Usage

The rotp rubygem includes CLI version to help with testing and debugging

```bash
# Try this to get an overview of the commands
rotp --help

# Examples
rotp --secret p4ssword                       # Generates a time-based one-time password
rotp --hmac --secret p4ssword --counter 42   # Generates a counter-based one-time password
```

## Contributors

Have a look at the [contributors graph](https://github.com/mdp/rotp/graphs/contributors) on Github.

## License

MIT Copyright (C) 2019 by Mark Percival, see [LICENSE](https://github.com/mdp/rotp/blob/master/LICENSE) for details.

## Other implementations

A list can be found at [Wikipedia](https://en.wikipedia.org/wiki/Google_Authenticator#Implementations).
