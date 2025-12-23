# gmail_xoauth [![Gem Version](https://badge.fury.io/rb/gmail_xoauth.png)](http://badge.fury.io/rb/gmail_xoauth)

Get access to [Gmail IMAP and SMTP via OAuth2](https://developers.google.com/google-apps/gmail/xoauth2_protocol) and [OAuth 1.0a](https://developers.google.com/google-apps/gmail/oauth_protocol), using the standard Ruby Net libraries.

The gem supports 3-legged OAuth, and 2-legged OAuth for Google Apps Business or Education account owners.

## Install

    $ gem install gmail_xoauth

## Usage for OAuth 2.0

### Get your OAuth 2.0 tokens

You can generate and validate your OAuth 2.0 tokens thanks to the [oauth2.py tool](http://code.google.com/p/google-mail-oauth2-tools/wiki/OAuth2DotPyRunThrough).

Create your API project in the [Google APIs console](https://code.google.com/apis/console/), from the menu "APIs and auth > Credentials". Click on "Create new Client ID", choose "Installed Application" and "Other".

Then go to the menu "APIs and auth > Consent screen" and enter an email address and product name.

    $ python oauth2.py --generate_oauth2_token --client_id=423906513574-o9v6kqt89lefrbfv1f3394u9rebfgv6n.apps.googleusercontent.com --client_secret=5SfdvZsYagblukE5VAhERjxZ

### IMAP OAuth 2.0

```ruby
require 'gmail_xoauth'
imap = Net::IMAP.new('imap.gmail.com', 993, usessl = true, certs = nil, verify = false)
imap.authenticate('XOAUTH2', 'myemail@gmail.com', my_oauth2_token)
messages_count = imap.status('INBOX', ['MESSAGES'])['MESSAGES']
puts "Seeing #{messages_count} messages in INBOX"
```

### SMTP OAuth 2.0

```ruby
require 'gmail_xoauth'
smtp = Net::SMTP.new('smtp.gmail.com', 587)
smtp.enable_starttls_auto
smtp.start('gmail.com', 'myemail@gmail.com', my_oauth2_token, :xoauth2)
smtp.finish
```

## Usage for OAuth 1.0a

== *[OAuth 1.0 has been officially deprecated as of April 20, 2012](https://developers.google.com/google-apps/gmail/oauth_protocol)*. ==

### Get your OAuth 1.0a tokens

For testing, you can generate and validate your OAuth tokens thanks to the awesome [xoauth.py tool](http://code.google.com/p/google-mail-xoauth-tools/wiki/XoauthDotPyRunThrough).

    $ python xoauth.py --generate_oauth_token --user=myemail@gmail.com

Or if you want some webapp code, check the [gmail-oauth-sinatra](https://github.com/nfo/gmail-oauth-sinatra) project.

### IMAP 3-legged OAuth 1.0a

For your tests, Gmail allows to set 'anonymous' as the consumer key and secret.

```ruby
require 'gmail_xoauth'
imap = Net::IMAP.new('imap.gmail.com', 993, usessl = true, certs = nil, verify = false)
imap.authenticate('XOAUTH', 'myemail@gmail.com',
  :consumer_key => 'anonymous',
  :consumer_secret => 'anonymous',
  :token => '4/nM2QAaunKUINb4RrXPC55F-mix_k',
  :token_secret => '41r18IyXjIvuyabS/NDyW6+m'
)
messages_count = imap.status('INBOX', ['MESSAGES'])['MESSAGES']
puts "Seeing #{messages_count} messages in INBOX"
```

Note that the [Net::IMAP#login](http://www.ruby-doc.org/core/classes/Net/IMAP.html#M004191) method does not use support custom authenticators, so you have to use the [Net::IMAP#authenticate](http://www.ruby-doc.org/core/classes/Net/IMAP.html#M004190) method.

### IMAP 2-legged OAuth 1.0a

```ruby
require 'gmail_xoauth'
imap = Net::IMAP.new('imap.gmail.com', 993, usessl = true, certs = nil, verify = false)
imap.authenticate('XOAUTH', 'myemail@mydomain.com',
  :two_legged => true,
  :consumer_key => 'a',
  :consumer_secret => 'b'
)
```

### SMTP 3-legged OAuth 1.0a

For your tests, Gmail allows to set 'anonymous' as the consumer key and secret.

```ruby
require 'gmail_xoauth'
smtp = Net::SMTP.new('smtp.gmail.com', 587)
smtp.enable_starttls_auto
secret = {
  :consumer_key => 'anonymous',
  :consumer_secret => 'anonymous',
  :token => '4/nM2QAaunKUINb4RrXPC55F-mix_k',
  :token_secret => '41r18IyXjIvuyabS/NDyW6+m'
}
smtp.start('gmail.com', 'myemail@gmail.com', secret, :xoauth)
smtp.finish
```

Note that `Net::SMTP#enable_starttls_auto` is not defined in Ruby 1.8.6.

### SMTP 2-legged OAuth 1.0a

```ruby
require 'gmail_xoauth'
smtp = Net::SMTP.new('smtp.gmail.com', 587)
smtp.enable_starttls_auto
secret = {
	:two_legged => true,
  :consumer_key => 'a',
  :consumer_secret => 'b'
}
smtp.start('gmail.com', 'myemail@mydomain.com', secret, :xoauth)
smtp.finish
```

## Compatibility

Tested on Ruby MRI 1.8.6, 1.8.7, 1.9.x and 2.1.x. Feel free to send me a message if you tested this code with other implementations of Ruby.

The only external dependency is the [oauth gem](http://rubygems.org/gems/oauth).

## History

* 0.4.3 Maintenance: Use Net::IMAP::SASL.add_authenticator to silence deprecation warning, thanks to [mantas](https://github.com/mantas)
* 0.4.2 SMTP: on 3xx response to 'AUTH XOAUTH2' send CR-LF to get actual error, thanks to [rafalyesware](https://github.com/rafalyesware)
* 0.4.1 [XOAUTH2](https://developers.google.com/google-apps/gmail/xoauth2_protocol) support, thanks to [glongman](https://github.com/glongman)
* 0.3.2 New email for the maintainer
* 0.3.1 2-legged OAuth support confirmed by [BobDohnal](https://github.com/BobDohnal)
* 0.3.0 Experimental 2-legged OAuth support, thanks to [wojciech](https://github.com/wojciech)
* 0.2.0 SMTP support
* 0.1.0 Initial release with IMAP support and 3-legged OAuth

## Note on Patches/Pull Requests

* Fork the project.
* Make your feature addition or bug fix.
* Add tests for it. This is important so I don't break it in a
  future version unintentionally.
* Commit, do not mess with rakefile, version, or history.
  (if you want to have your own version, that is fine but bump version in a commit by itself I can ignore when I pull)
* Send me a pull request. Bonus points for topic branches.

## Contact me

https://nicolasfouche.com

## License

See LICENSE for details.
