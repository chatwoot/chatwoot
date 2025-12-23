# OmniAuth - Rails CSRF Protection

This gem provides a mitigation against [CVE-2015-9284] (Cross-Site Request
Forgery on the request phase when using OmniAuth gem with a Ruby on Rails
application) by implementing a CSRF token verifier that directly uses
`ActionController::RequestForgeryProtection` code from Rails.

[CVE-2015-9284]: https://nvd.nist.gov/vuln/detail/CVE-2015-9284

## Usage

Add this line to your application's Gemfile:

```ruby
gem "omniauth-rails_csrf_protection"
```

Then run `bundle install` to install this gem.

You will then need to verify that all links in your application that would
initiate OAuth request phase are being converted to a HTTP POST form that
contains `authenticity_token` value. This might simply be done by changing all
`link_to` to `button_to`, or use `link_to ..., method: :post`.

## Under the Hood

This gem does a few things to your application:

* Disable access to the OAuth request phase using HTTP GET method.
* Insert a Rails CSRF token verifier at the before request phase.

These actions mitigate you from the attack vector described in [CVE-2015-9284].

## Contributing

Bug reports and pull requests are welcome on GitHub. This project is
intended to be a safe, welcoming space for collaboration, and contributors are
expected to adhere to the
[Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the
[MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the this project’s codebases, issue trackers, chat
rooms and mailing lists is expected to follow the
[code of conduct](https://github.com/cookpad/omniauth-rails_csrf_protection/blob/main/CODE_OF_CONDUCT.md).
