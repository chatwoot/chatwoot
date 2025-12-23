<p align="center">
    <a href="http://oauth.net/2/" target="_blank" rel="noopener">
      <img src="https://github.com/oauth-xx/oauth2/raw/main/docs/images/logo/oauth2-logo-124px.png?raw=true" alt="OAuth 2.0 Logo by Chris Messina, CC BY-SA 3.0">
    </a>
    <a href="https://www.ruby-lang.org/" target="_blank" rel="noopener">
      <img width="124px" src="https://github.com/oauth-xx/oauth2/raw/main/docs/images/logo/ruby-logo-198px.svg?raw=true" alt="Yukihiro Matsumoto, Ruby Visual Identity Team, CC BY-SA 2.5">
    </a>
</p>

## What

OAuth 2.0 is the industry-standard protocol for authorization.
OAuth 2.0 focuses on client developer simplicity while providing specific authorization flows for web applications,
    desktop applications, mobile phones, and living room devices.
This is a RubyGem for implementing OAuth 2.0 clients and servers in Ruby applications.
See the sibling `oauth` gem for OAuth 1.0 implementations in Ruby.

---

* [OAuth 2.0 Spec][oauth2-spec]
* [oauth sibling gem][sibling-gem] for OAuth 1.0 implementations in Ruby.

[oauth2-spec]: https://oauth.net/2/
[sibling-gem]: https://gitlab.com/oauth-xx/oauth

## Release Documentation

### Version 2.0.x

<details>
  <summary>2.0.x Readmes</summary>

| Version | Release Date | Readme                                                   |
|---------|--------------|----------------------------------------------------------|
| 2.0.9   | 2022-09-16   | https://gitlab.com/oauth-xx/oauth2/-/blob/v2.0.9/README.md |
| 2.0.8   | 2022-09-01   | https://gitlab.com/oauth-xx/oauth2/-/blob/v2.0.8/README.md |
| 2.0.7   | 2022-08-22   | https://gitlab.com/oauth-xx/oauth2/-/blob/v2.0.7/README.md |
| 2.0.6   | 2022-07-13   | https://gitlab.com/oauth-xx/oauth2/-/blob/v2.0.6/README.md |
| 2.0.5   | 2022-07-07   | https://gitlab.com/oauth-xx/oauth2/-/blob/v2.0.5/README.md |
| 2.0.4   | 2022-07-01   | https://gitlab.com/oauth-xx/oauth2/-/blob/v2.0.4/README.md |
| 2.0.3   | 2022-06-28   | https://gitlab.com/oauth-xx/oauth2/-/blob/v2.0.3/README.md |
| 2.0.2   | 2022-06-24   | https://gitlab.com/oauth-xx/oauth2/-/blob/v2.0.2/README.md |
| 2.0.1   | 2022-06-22   | https://gitlab.com/oauth-xx/oauth2/-/blob/v2.0.1/README.md |
| 2.0.0   | 2022-06-21   | https://gitlab.com/oauth-xx/oauth2/-/blob/v2.0.0/README.md |
</details>

### Older Releases

<details>
  <summary>1.4.x Readmes</summary>

| Version | Release Date | Readme                                                      |
|---------|--------------|-------------------------------------------------------------|
| 1.4.11  | Sep 16, 2022 | https://gitlab.com/oauth-xx/oauth2/-/blob/v1.4.11/README.md |
| 1.4.10  | Jul 1, 2022  | https://gitlab.com/oauth-xx/oauth2/-/blob/v1.4.10/README.md |
| 1.4.9   | Feb 20, 2022 | https://gitlab.com/oauth-xx/oauth2/-/blob/v1.4.9/README.md  |
| 1.4.8   | Feb 18, 2022 | https://gitlab.com/oauth-xx/oauth2/-/blob/v1.4.8/README.md  |
| 1.4.7   | Mar 19, 2021 | https://gitlab.com/oauth-xx/oauth2/-/blob/v1.4.7/README.md  |
| 1.4.6   | Mar 19, 2021 | https://gitlab.com/oauth-xx/oauth2/-/blob/v1.4.6/README.md  |
| 1.4.5   | Mar 18, 2021 | https://gitlab.com/oauth-xx/oauth2/-/blob/v1.4.5/README.md  |
| 1.4.4   | Feb 12, 2020 | https://gitlab.com/oauth-xx/oauth2/-/blob/v1.4.4/README.md  |
| 1.4.3   | Jan 29, 2020 | https://gitlab.com/oauth-xx/oauth2/-/blob/v1.4.3/README.md  |
| 1.4.2   | Oct 1, 2019  | https://gitlab.com/oauth-xx/oauth2/-/blob/v1.4.2/README.md  |
| 1.4.1   | Oct 13, 2018 | https://gitlab.com/oauth-xx/oauth2/-/blob/v1.4.1/README.md  |
| 1.4.0   | Jun 9, 2017  | https://gitlab.com/oauth-xx/oauth2/-/blob/v1.4.0/README.md  |
</details>

<details>
  <summary>1.3.x Readmes</summary>

| Version  | Release Date | Readme                                                   |
|----------|--------------|----------------------------------------------------------|
| 1.3.1    | Mar 3, 2017  | https://gitlab.com/oauth-xx/oauth2/-/blob/v1.3.1/README.md |
| 1.3.0    | Dec 27, 2016 | https://gitlab.com/oauth-xx/oauth2/-/blob/v1.3.0/README.md |
</details>

<details>
  <summary>&le;= 1.2.x Readmes (2016 and before)</summary>

| Version  | Release Date | Readme                                                   |
|----------|--------------|----------------------------------------------------------|
| 1.2.0    | Jun 30, 2016 | https://gitlab.com/oauth-xx/oauth2/-/blob/v1.2.0/README.md |
| 1.1.0    | Jan 30, 2016 | https://gitlab.com/oauth-xx/oauth2/-/blob/v1.1.0/README.md |
| 1.0.0    | May 23, 2014 | https://gitlab.com/oauth-xx/oauth2/-/blob/v1.0.0/README.md |
| < 1.0.0  | Find here    | https://gitlab.com/oauth-xx/oauth2/-/tags                  |
</details>

## Status

<!--
Numbering rows and badges in each row as a visual "database" lookup,
    as the table is extremely dense, and it can be very difficult to find anything
Putting one on each row here, to document the emoji that should be used, and for ease of copy/paste.

row #s:
1️⃣
2️⃣
3️⃣
4️⃣
5️⃣
6️⃣
7️⃣

badge #s:
⛳️
🖇
🏘
🚎
🖐
🧮
📗

appended indicators:
♻️ - URL needs to be updated from SASS integration. Find / Replace is insufficient.
-->

|     | Project               | bundle add oauth2                                                                                                                                                                                                                                                          |
|:----|-----------------------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| 1️⃣ | name, license, docs   | [![RubyGems.org][⛳️name-img]][⛳️gem] [![License: MIT][🖇src-license-img]][🖇src-license] [![FOSSA][🏘fossa-img]][🏘fossa] [![RubyDoc.info][🚎yard-img]][🚎yard] [![InchCI][🖐inch-ci-img]][🚎yard]                                                                         |
| 2️⃣ | version & activity    | [![Gem Version][⛳️version-img]][⛳️gem] [![Total Downloads][🖇DL-total-img]][⛳️gem] [![Download Rank][🏘DL-rank-img]][⛳️gem] [![Source Code][🚎src-home-img]][🚎src-home]                                                                                                   |
| 3️⃣ | maintanence & linting | [![Maintainability][⛳cclim-maint-img♻️]][⛳cclim-maint] [![Helpers][🖇triage-help-img]][🖇triage-help] [![Depfu][🏘depfu-img♻️]][🏘depfu♻️] [![Contributors][🚎contributors-img]][🚎contributors] [![Style][🖐style-wf-img]][🖐style-wf] [![Kloc Roll][🧮kloc-img]][🧮kloc] |
| 4️⃣ | testing               | [![Supported][🏘sup-wf-img]][🏘sup-wf] [![Heads][🚎heads-wf-img]][🚎heads-wf] [![Unofficial Support][🖐uns-wf-img]][🖐uns-wf] [![MacOS][🧮mac-wf-img]][🧮mac-wf] [![Windows][📗win-wf-img]][📗win-wf]                                                                      |
| 5️⃣ | coverage & security   | [![CodeClimate][⛳cclim-cov-img♻️]][⛳cclim-cov] [![CodeCov][🖇codecov-img♻️]][🖇codecov] [![Coveralls][🏘coveralls-img]][🏘coveralls] [![Security Policy][🚎sec-pol-img]][🚎sec-pol] [![CodeQL][🖐codeQL-img]][🖐codeQL] [![Code Coverage][🧮cov-wf-img]][🧮cov-wf]         |
| 6️⃣ | resources             | [![Discussion][⛳gg-discussions-img]][⛳gg-discussions] [![Get help on Codementor][🖇codementor-img]][🖇codementor] [![Chat][🏘chat-img]][🏘chat] [![Blog][🚎blog-img]][🚎blog] [![Blog][🖐wiki-img]][🖐wiki]                                                                |
| 7️⃣ | spread 💖             | [![Liberapay Patrons][⛳liberapay-img]][⛳liberapay] [![Sponsor Me][🖇sponsor-img]][🖇sponsor] [![Tweet @ Peter][🏘tweet-img]][🏘tweet] [🌏][aboutme] [👼][angelme] [💻][coderme]                                                                                            |

<!--
The link tokens in the following sections should be kept ordered by the row and badge numbering scheme
-->

<!-- 1️⃣ name, license, docs -->
[⛳️gem]: https://rubygems.org/gems/oauth2
[⛳️name-img]: https://img.shields.io/badge/name-oauth2-brightgreen.svg?style=flat
[🖇src-license]: https://opensource.org/licenses/MIT
[🖇src-license-img]: https://img.shields.io/badge/License-MIT-green.svg
[🏘fossa]: https://app.fossa.io/projects/git%2Bgithub.com%2Foauth-xx%2Foauth2?ref=badge_shield
[🏘fossa-img]: https://app.fossa.io/api/projects/git%2Bgithub.com%2Foauth-xx%2Foauth2.svg?type=shield
[🚎yard]: https://www.rubydoc.info/github/oauth-xx/oauth2
[🚎yard-img]: https://img.shields.io/badge/documentation-rubydoc-brightgreen.svg?style=flat
[🖐inch-ci-img]: http://inch-ci.org/github/oauth-xx/oauth2.png

<!-- 2️⃣ version & activity -->
[⛳️version-img]: http://img.shields.io/gem/v/oauth2.svg
[🖇DL-total-img]: https://img.shields.io/gem/dt/oauth2.svg
[🏘DL-rank-img]: https://img.shields.io/gem/rt/oauth2.svg
[🚎src-home]: https://gitlab.com/oauth-xx/oauth2/
[🚎src-home-img]: https://img.shields.io/badge/source-gitlab-blue.svg?style=flat

<!-- 3️⃣ maintenance & linting -->
[⛳cclim-maint]: https://codeclimate.com/github/oauth-xx/oauth2/maintainability
[⛳cclim-maint-img♻️]: https://api.codeclimate.com/v1/badges/688c612528ff90a46955/maintainability
[🖇triage-help]: https://www.codetriage.com/oauth-xx/oauth2
[🖇triage-help-img]: https://www.codetriage.com/oauth-xx/oauth2/badges/users.svg
[🏘depfu♻️]: https://depfu.com/github/oauth-xx/oauth2?project_id=4445
[🏘depfu-img♻️]: https://badges.depfu.com/badges/6d34dc1ba682bbdf9ae2a97848241743/count.svg
[🚎contributors]: https://gitlab.com/oauth-xx/oauth2/-/graphs/main
[🚎contributors-img]: https://img.shields.io/github/contributors-anon/oauth-xx/oauth2
[🖐style-wf]: https://github.com/oauth-xx/oauth2/actions/workflows/style.yml
[🖐style-wf-img]: https://github.com/oauth-xx/oauth2/actions/workflows/style.yml/badge.svg
[🧮kloc]: https://www.youtube.com/watch?v=dQw4w9WgXcQ
[🧮kloc-img]: https://img.shields.io/tokei/lines/github.com/oauth-xx/oauth2

<!-- 4️⃣ testing -->
[🏘sup-wf]: https://github.com/oauth-xx/oauth2/actions/workflows/supported.yml
[🏘sup-wf-img]: https://github.com/oauth-xx/oauth2/actions/workflows/supported.yml/badge.svg
[🚎heads-wf]: https://github.com/oauth-xx/oauth2/actions/workflows/heads.yml
[🚎heads-wf-img]: https://github.com/oauth-xx/oauth2/actions/workflows/heads.yml/badge.svg
[🖐uns-wf]: https://github.com/oauth-xx/oauth2/actions/workflows/unsupported.yml
[🖐uns-wf-img]: https://github.com/oauth-xx/oauth2/actions/workflows/unsupported.yml/badge.svg
[🧮mac-wf]: https://github.com/oauth-xx/oauth2/actions/workflows/macos.yml
[🧮mac-wf-img]: https://github.com/oauth-xx/oauth2/actions/workflows/macos.yml/badge.svg
[📗win-wf]: https://github.com/oauth-xx/oauth2/actions/workflows/windows.yml
[📗win-wf-img]: https://github.com/oauth-xx/oauth2/actions/workflows/windows.yml/badge.svg

<!-- 5️⃣ coverage & security -->
[⛳cclim-cov]: https://codeclimate.com/github/oauth-xx/oauth2/test_coverage
[⛳cclim-cov-img♻️]: https://api.codeclimate.com/v1/badges/688c612528ff90a46955/test_coverage
[🖇codecov-img♻️]: https://codecov.io/gh/oauth-xx/oauth2/branch/main/graph/badge.svg?token=bNqSzNiuo2
[🖇codecov]: https://codecov.io/gh/oauth-xx/oauth2
[🏘coveralls]: https://coveralls.io/github/oauth-xx/oauth2?branch=main
[🏘coveralls-img]: https://coveralls.io/repos/github/oauth-xx/oauth2/badge.svg?branch=main
[🚎sec-pol]: https://gitlab.com/oauth-xx/oauth2/-/blob/main/SECURITY.md
[🚎sec-pol-img]: https://img.shields.io/badge/security-policy-brightgreen.svg?style=flat
[🖐codeQL]: https://github.com/oauth-xx/oauth2/security/code-scanning
[🖐codeQL-img]: https://github.com/oauth-xx/oauth2/actions/workflows/codeql-analysis.yml/badge.svg
[🧮cov-wf]: https://github.com/oauth-xx/oauth2/actions/workflows/coverage.yml
[🧮cov-wf-img]: https://github.com/oauth-xx/oauth2/actions/workflows/coverage.yml/badge.svg

<!-- 6️⃣ resources -->
[⛳gg-discussions]: https://groups.google.com/g/oauth-ruby
[⛳gg-discussions-img]: https://img.shields.io/badge/google-group-purple.svg?style=flat
[🖇codementor]: https://www.codementor.io/peterboling?utm_source=github&utm_medium=button&utm_term=peterboling&utm_campaign=github
[🖇codementor-img]: https://cdn.codementor.io/badges/get_help_github.svg
[🏘chat]: https://gitter.im/oauth-xx/oauth2
[🏘chat-img]: https://img.shields.io/gitter/room/oauth-xx/oauth2.svg
[🚎blog]: http://www.railsbling.com/tags/oauth2/
[🚎blog-img]: https://img.shields.io/badge/blog-railsbling-brightgreen.svg?style=flat
[🖐wiki]: https://gitlab.com/oauth-xx/oauth2/-/wikis/home
[🖐wiki-img]: https://img.shields.io/badge/wiki-examples-brightgreen.svg?style=flat

<!-- 7️⃣ spread 💖 -->
[⛳liberapay-img]: https://img.shields.io/liberapay/patrons/pboling.svg?logo=liberapay
[⛳liberapay]: https://liberapay.com/pboling/donate
[🖇sponsor-img]: https://img.shields.io/badge/sponsor-pboling.svg?style=social&logo=github
[🖇sponsor]: https://github.com/sponsors/pboling
[🏘tweet-img]: https://img.shields.io/twitter/follow/galtzo.svg?style=social&label=Follow
[🏘tweet]: http://twitter.com/galtzo

<!-- Maintainer Contact Links -->
[railsbling]: http://www.railsbling.com
[peterboling]: http://www.peterboling.com
[aboutme]: https://about.me/peter.boling
[angelme]: https://angel.co/peter-boling
[coderme]:http://coderwall.com/pboling

## Installation

Install the gem and add to the application's Gemfile by executing:

    $ bundle add oauth2

If bundler is not being used to manage dependencies, install the gem by executing:

    $ gem install oauth2

## OAuth2 for Enterprise

Available as part of the Tidelift Subscription.

The maintainers of OAuth2 and thousands of other packages are working with Tidelift to deliver commercial support and maintenance for the open source packages you use to build your applications. Save time, reduce risk, and improve code health, while paying the maintainers of the exact packages you use. [Learn more.][tidelift-ref]

[tidelift-ref]: https://tidelift.com/subscription/pkg/rubygems-oauth2?utm_source=rubygems-oauth2&utm_medium=referral&utm_campaign=enterprise

## Security contact information

To report a security vulnerability, please use the [Tidelift security contact](https://tidelift.com/security).
Tidelift will coordinate the fix and disclosure.

For more see [SECURITY.md][🚎sec-pol].

## What is new for v2.0?

- Officially support Ruby versions >= 2.7
- Unofficially support Ruby versions >= 2.5
- Incidentally support Ruby versions >= 2.2
- Drop support for the expired MAC Draft (all versions)
- Support IETF rfc7523 JWT Bearer Tokens
- Support IETF rfc7231 Relative Location in Redirect
- Support IETF rfc6749 Don't set oauth params when nil
- Support [OIDC 1.0 Private Key JWT](https://openid.net/specs/openid-connect-core-1_0.html#ClientAuthentication); based on the OAuth JWT assertion specification [(RFC 7523)](https://tools.ietf.org/html/rfc7523)
- Support new formats, including from [jsonapi.org](http://jsonapi.org/format/): `application/vdn.api+json`, `application/vnd.collection+json`, `application/hal+json`, `application/problem+json`
- Adds new option to `OAuth2::Client#get_token`:
    - `:access_token_class` (`AccessToken`); user specified class to use for all calls to `get_token`
- Adds new option to `OAuth2::AccessToken#initialize`:
    - `:expires_latency` (`nil`); number of seconds by which AccessToken validity will be reduced to offset latency
- By default, keys are transformed to camel case.
  - Original keys will still work as previously, in most scenarios, thanks to `rash_alt` gem.
  - However, this is a _breaking_ change if you rely on `response.parsed.to_h`, as the keys in the result will be camel case.
  - As of version 2.0.4 you can turn key transformation off with the `snaky: false` option.
- By default, the `:auth_scheme` is now `:basic_auth` (instead of `:request_body`)
  - Third-party strategies and gems may need to be updated if a provider was requiring client id/secret in the request body
- [... A lot more](https://gitlab.com/oauth-xx/oauth2/-/blob/main/CHANGELOG.md#2.0.0)

## Compatibility

Targeted ruby compatibility is non-EOL versions of Ruby, currently 2.7, 3.0 and
3.1. Compatibility is further distinguished by supported and unsupported versions of Ruby.
Ruby is limited to 2.2+ for 2.x releases. See `1-4-stable` branch for older rubies.

<details>
  <summary>Ruby Engine Compatibility Policy</summary>

This gem is tested against MRI, JRuby, and Truffleruby.
Each of those has varying versions that target a specific version of MRI Ruby.
This gem should work in the just-listed Ruby engines according to the targeted MRI compatibility in the table below.
If you would like to add support for additional engines,
  see `gemfiles/README.md`, then submit a PR to the correct maintenance branch as according to the table below.
</details>

<details>
  <summary>Ruby Version Compatibility Policy</summary>

If something doesn't work on one of these interpreters, it's a bug.

This library may inadvertently work (or seem to work) on other Ruby
implementations, however support will only be provided for the versions listed
above.

If you would like this library to support another Ruby version, you may
volunteer to be a maintainer. Being a maintainer entails making sure all tests
run and pass on that implementation. When something breaks on your
implementation, you will be responsible for providing patches in a timely
fashion. If critical issues for a particular implementation exist at the time
of a major release, support for that Ruby version may be dropped.
</details>

|     | Ruby OAuth2 Version | Maintenance Branch | Supported Officially    | Supported Unofficially | Supported Incidentally |
|:----|---------------------|--------------------|-------------------------|------------------------|------------------------|
| 1️⃣ | 2.0.x               | `main`             | 2.7, 3.0, 3.1           | 2.5, 2.6               | 2.2, 2.3, 2.4          |
| 2️⃣ | 1.4.x               | `1-4-stable`       | 2.5, 2.6, 2.7, 3.0, 3.1 | 2.1, 2.2, 2.3, 2.4     | 1.9, 2.0               |
| 3️⃣ | older               | N/A                | Best of luck to you!    | Please upgrade!        |                        |

NOTE: The 1.4 series will only receive critical security updates.
See [SECURITY.md][🚎sec-pol]

## Usage Examples

### Global Configuration

If you started seeing this warning, but everything it working fine, you can now silence it.
```log
OAuth2::AccessToken.from_hash: `hash` contained more than one 'token' key
```

```ruby
OAuth2.configure do |config|
  config.silence_extra_tokens_warning = true # default: false
end
```

### `authorize_url` and `token_url` are on site root (Just Works!)

```ruby
require 'oauth2'
client = OAuth2::Client.new('client_id', 'client_secret', site: 'https://example.org')
# => #<OAuth2::Client:0x00000001204c8288 @id="client_id", @secret="client_sec...
client.auth_code.authorize_url(redirect_uri: 'http://localhost:8080/oauth2/callback')
# => "https://example.org/oauth/authorize?client_id=client_id&redirect_uri=http%3A%2F%2Flocalhost%3A8080%2Foauth2%2Fcallback&response_type=code"

access = client.auth_code.get_token('authorization_code_value', redirect_uri: 'http://localhost:8080/oauth2/callback', headers: {'Authorization' => 'Basic some_password'})
response = access.get('/api/resource', params: {'query_foo' => 'bar'})
response.class.name
# => OAuth2::Response
```

### Relative `authorize_url` and `token_url` (Not on site root, Just Works!)

In above example, the default Authorization URL is `oauth/authorize` and default Access Token URL is `oauth/token`, and, as they are missing a leading `/`, both are relative.

```ruby
client = OAuth2::Client.new('client_id', 'client_secret', site: 'https://example.org/nested/directory/on/your/server')
# => #<OAuth2::Client:0x00000001204c8288 @id="client_id", @secret="client_sec...
client.auth_code.authorize_url(redirect_uri: 'http://localhost:8080/oauth2/callback')
# => "https://example.org/nested/directory/on/your/server/oauth/authorize?client_id=client_id&redirect_uri=http%3A%2F%2Flocalhost%3A8080%2Foauth2%2Fcallback&response_type=code"
```

### Customize `authorize_url` and `token_url`

You can specify custom URLs for authorization and access token, and when using a leading `/` they will _not be relative_, as shown below:

```ruby
client = OAuth2::Client.new('client_id', 'client_secret',
                            site: 'https://example.org/nested/directory/on/your/server',
                            authorize_url: '/jaunty/authorize/',
                            token_url: '/stirrups/access_token')
# => #<OAuth2::Client:0x00000001204c8288 @id="client_id", @secret="client_sec...
client.auth_code.authorize_url(redirect_uri: 'http://localhost:8080/oauth2/callback')
# => "https://example.org/jaunty/authorize/?client_id=client_id&redirect_uri=http%3A%2F%2Flocalhost%3A8080%2Foauth2%2Fcallback&response_type=code"
client.class.name
# => OAuth2::Client
```

### snake_case and indifferent access in Response#parsed

```ruby
response = access.get('/api/resource', params: {'query_foo' => 'bar'})
# Even if the actual response is CamelCase. it will be made available as snaky:
JSON.parse(response.body)         # => {"accessToken"=>"aaaaaaaa", "additionalData"=>"additional"}
response.parsed                   # => {"access_token"=>"aaaaaaaa", "additional_data"=>"additional"}
response.parsed.access_token      # => "aaaaaaaa"
response.parsed[:access_token]    # => "aaaaaaaa"
response.parsed.additional_data   # => "additional"
response.parsed[:additional_data] # => "additional"
response.parsed.class.name        # => OAuth2::SnakyHash (subclass of Hashie::Mash::Rash, from `rash_alt` gem)
```

#### What if I hate snakes and/or indifference?

```ruby
response = access.get('/api/resource', params: {'query_foo' => 'bar'}, snaky: false)
JSON.parse(response.body)         # => {"accessToken"=>"aaaaaaaa", "additionalData"=>"additional"}
response.parsed                   # => {"accessToken"=>"aaaaaaaa", "additionalData"=>"additional"}
response.parsed['accessToken']    # => "aaaaaaaa"
response.parsed['additionalData'] # => "additional"
response.parsed.class.name        # => Hash (just, regular old Hash)
```

<details>
  <summary>Debugging</summary>

Set an environment variable, however you would [normally do that](https://github.com/bkeepers/dotenv).

```ruby
# will log both request and response, including bodies
ENV['OAUTH_DEBUG'] = 'true'
```

By default, debug output will go to `$stdout`. This can be overridden when
initializing your OAuth2::Client.

```ruby
require 'oauth2'
client = OAuth2::Client.new(
  'client_id',
  'client_secret',
  site: 'https://example.org',
  logger: Logger.new('example.log', 'weekly')
)
```
</details>

## OAuth2::Response

The `AccessToken` methods `#get`, `#post`, `#put` and `#delete` and the generic `#request`
will return an instance of the #OAuth2::Response class.

This instance contains a `#parsed` method that will parse the response body and
return a Hash-like [`OAuth2::SnakyHash`](https://gitlab.com/oauth-xx/oauth2/-/blob/main/lib/oauth2/snaky_hash.rb) if the `Content-Type` is `application/x-www-form-urlencoded` or if
the body is a JSON object.  It will return an Array if the body is a JSON
array.  Otherwise, it will return the original body string.

The original response body, headers, and status can be accessed via their
respective methods.

## OAuth2::AccessToken

If you have an existing Access Token for a user, you can initialize an instance
using various class methods including the standard new, `from_hash` (if you have
a hash of the values), or `from_kvform` (if you have an
`application/x-www-form-urlencoded` encoded string of the values).

## OAuth2::Error

On 400+ status code responses, an `OAuth2::Error` will be raised.  If it is a
standard OAuth2 error response, the body will be parsed and `#code` and `#description` will contain the values provided from the error and
`error_description` parameters.  The `#response` property of `OAuth2::Error` will
always contain the `OAuth2::Response` instance.

If you do not want an error to be raised, you may use `:raise_errors => false`
option on initialization of the client.  In this case the `OAuth2::Response`
instance will be returned as usual and on 400+ status code responses, the
Response instance will contain the `OAuth2::Error` instance.

## Authorization Grants

Currently the Authorization Code, Implicit, Resource Owner Password Credentials, Client Credentials, and Assertion
authentication grant types have helper strategy classes that simplify client
use. They are available via the [`#auth_code`](https://gitlab.com/oauth-xx/oauth2/-/blob/main/lib/oauth2/strategy/auth_code.rb),
[`#implicit`](https://gitlab.com/oauth-xx/oauth2/-/blob/main/lib/oauth2/strategy/implicit.rb),
[`#password`](https://gitlab.com/oauth-xx/oauth2/-/blob/main/lib/oauth2/strategy/password.rb),
[`#client_credentials`](https://gitlab.com/oauth-xx/oauth2/-/blob/main/lib/oauth2/strategy/client_credentials.rb), and
[`#assertion`](https://gitlab.com/oauth-xx/oauth2/-/blob/main/lib/oauth2/strategy/assertion.rb) methods respectively.

These aren't full examples, but demonstrative of the differences between usage for each strategy.
```ruby
auth_url = client.auth_code.authorize_url(redirect_uri: 'http://localhost:8080/oauth/callback')
access = client.auth_code.get_token('code_value', redirect_uri: 'http://localhost:8080/oauth/callback')

auth_url = client.implicit.authorize_url(redirect_uri: 'http://localhost:8080/oauth/callback')
# get the token params in the callback and
access = OAuth2::AccessToken.from_kvform(client, query_string)

access = client.password.get_token('username', 'password')

access = client.client_credentials.get_token

# Client Assertion Strategy
# see: https://tools.ietf.org/html/rfc7523
claimset = {
  iss: 'http://localhost:3001',
  aud: 'http://localhost:8080/oauth2/token',
  sub: 'me@example.com',
  exp: Time.now.utc.to_i + 3600,
}
assertion_params = [claimset, 'HS256', 'secret_key']
access = client.assertion.get_token(assertion_params)

# The `access` (i.e. access token) is then used like so:
access.token # actual access_token string, if you need it somewhere
access.get('/api/stuff') # making api calls with access token
```

If you want to specify additional headers to be sent out with the
request, add a 'headers' hash under 'params':

```ruby
access = client.auth_code.get_token('code_value', redirect_uri: 'http://localhost:8080/oauth/callback', headers: {'Some' => 'Header'})
```

You can always use the `#request` method on the `OAuth2::Client` instance to make
requests for tokens for any Authentication grant type.

## Versioning

This library aims to adhere to [Semantic Versioning 2.0.0][semver].
Violations of this scheme should be reported as bugs. Specifically,
if a minor or patch version is released that breaks backward
compatibility, a new version should be immediately released that
restores compatibility. Breaking changes to the public API will
only be introduced with new major versions.

As a result of this policy, you can (and should) specify a
dependency on this gem using the [Pessimistic Version Constraint][pvc] with two digits of precision.

For example:

```ruby
spec.add_dependency 'oauth2', '~> 2.0'
```

[semver]: http://semver.org/
[pvc]: http://guides.rubygems.org/patterns/#pessimistic-version-constraint

## License

[![License: MIT][🖇src-license-img]][🖇src-license]

- Copyright (c) 2011-2013 Michael Bleigh and Intridea, Inc.
- Copyright (c) 2017-2022 [oauth-xx organization][oauth-xx]
- See [LICENSE][license] for details.

[![FOSSA Status](https://app.fossa.io/api/projects/git%2Bgithub.com%2Foauth-xx%2Foauth2.svg?type=large)][fossa2]

[license]: https://gitlab.com/oauth-xx/oauth2/-/blob/main/LICENSE
[oauth-xx]: https://gitlab.com/oauth-xx
[fossa2]: https://app.fossa.io/projects/git%2Bgithub.com%2Foauth-xx%2Foauth2?ref=badge_large

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

See [CONTRIBUTING.md][contributing]

[contributing]: https://gitlab.com/oauth-xx/oauth2/-/blob/main/CONTRIBUTING.md

## Contributors

[![Contributors](https://contrib.rocks/image?repo=oauth-xx/oauth2)]("https://gitlab.com/oauth-xx/oauth2/-/graphs/main")

Made with [contributors-img](https://contrib.rocks).

## Code of Conduct

Everyone interacting in the OAuth2 project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://gitlab.com/oauth-xx/oauth2/-/blob/main/CODE_OF_CONDUCT.md).
