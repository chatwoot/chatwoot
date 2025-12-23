# Browser

[![Tests](https://github.com/fnando/browser/workflows/Tests/badge.svg)](https://github.com/fnando/browser)
[![Code Climate](https://codeclimate.com/github/fnando/browser/badges/gpa.svg)](https://codeclimate.com/github/fnando/browser)
[![Gem](https://img.shields.io/gem/v/browser.svg)](https://rubygems.org/gems/browser)
[![Gem](https://img.shields.io/gem/dt/browser.svg)](https://rubygems.org/gems/browser)

Do some browser detection with Ruby. Includes ActionController integration.

## Installation

```bash
gem install browser
```

## Usage

```ruby
require "browser"

browser = Browser.new("Some User Agent", accept_language: "en-us")

# General info
browser.bot?
browser.chrome?
browser.core_media?
browser.duck_duck_go?
browser.edge?                # Newest MS browser
browser.electron?            # Electron Framework
browser.firefox?
browser.full_version
browser.ie?
browser.ie?(6)               # detect specific IE version
browser.ie?([">8", "<10"])   # detect specific IE (IE9).
browser.known?               # has the browser been successfully detected?
browser.unknown?             # the browser wasn't detected.
browser.meta                 # an array with several attributes
browser.name                 # readable browser name
browser.nokia?
browser.opera?
browser.opera_mini?
browser.phantom_js?
browser.quicktime?
browser.safari?
browser.safari_webapp_mode?
browser.samsung_browser?
browser.to_s            # the meta info joined by space
browser.uc_browser?
browser.version         # major version number
browser.webkit?
browser.webkit_full_version
browser.yandex?
browser.wechat?
browser.qq?
browser.weibo?
browser.yandex?
browser.sputnik?
browser.sougou_browser?

# Get bot info
browser.bot.name
browser.bot.search_engine?
browser.bot?
browser.bot.why? # shows which matcher detected this user agent as a bot.
Browser::Bot.why?(ua)

# Get device info
browser.device
browser.device.id
browser.device.name
browser.device.unknown?
browser.device.blackberry_playbook?
browser.device.console?
browser.device.ipad?
browser.device.iphone?
browser.device.ipod_touch?
browser.device.kindle?
browser.device.kindle_fire?
browser.device.mobile?
browser.device.nintendo?
browser.device.playstation?
browser.device.ps3?
browser.device.ps4?
browser.device.psp?
browser.device.silk?
browser.device.surface?
browser.device.tablet?
browser.device.tv?
browser.device.vita?
browser.device.wii?
browser.device.wiiu?
browser.device.samsung?
browser.device.switch?
browser.device.xbox?
browser.device.xbox_360?
browser.device.xbox_one?

# Get platform info
browser.platform
browser.platform.id
browser.platform.name
browser.platform.version  # e.g. 9 (for iOS9)
browser.platform.adobe_air?
browser.platform.android?
browser.platform.android?(4.2)   # detect Android Jelly Bean 4.2
browser.platform.android_app?     # detect webview in an Android app
browser.platform.android_webview? # alias for android_app?
browser.platform.blackberry?
browser.platform.blackberry?(10) # detect specific BlackBerry version
browser.platform.chrome_os?
browser.platform.firefox_os?
browser.platform.ios?     # detect iOS
browser.platform.ios?(9)  # detect specific iOS version
browser.platform.ios_app?     # detect webview in an iOS app
browser.platform.ios_webview? # alias for ios_app?
browser.platform.linux?
browser.platform.mac?
browser.platform.unknown?
browser.platform.windows10?
browser.platform.windows7?
browser.platform.windows8?
browser.platform.windows8_1?
browser.platform.windows?
browser.platform.windows_mobile?
browser.platform.windows_phone?
browser.platform.windows_rt?
browser.platform.windows_touchscreen_desktop?
browser.platform.windows_vista?
browser.platform.windows_wow64?
browser.platform.windows_x64?
browser.platform.windows_x64_inclusive?
browser.platform.windows_xp?
browser.platform.kai_os?
```

### Aliases

To add aliases like `mobile?` and `tablet?` to the base object (e.g
`browser.mobile?`), require the `browser/aliases` file and extend the
Browser::Base object like the following:

```ruby
require "browser/aliases"
Browser::Base.include(Browser::Aliases)

browser = Browser.new("Some user agent")
browser.mobile? #=> false
```

### What's being detected?

- For a list of platform detections, check
  [lib/browser/platform.rb](https://github.com/fnando/browser/blob/master/lib/browser/platform.rb)
- For a list of device detections, check
  [lib/browser/device.rb](https://github.com/fnando/browser/blob/master/lib/browser/device.rb)
- For a list of bot detections, check
  [bots.yml](https://github.com/fnando/browser/blob/master/bots.yml)

### Detecting modern browsers

To detect whether a browser can be considered as modern or not, create a method
that abstracts your versioning constraints. The following example will consider
any of the following browsers as a modern:

```ruby
# Expects an Browser instance,
# like in `Browser.new(user_agent, accept_language: language)`.
def modern_browser?(browser)
  [
    browser.chrome?(">= 65"),
    browser.safari?(">= 10"),
    browser.firefox?(">= 52"),
    browser.ie?(">= 11") && !browser.compatibility_view?,
    browser.edge?(">= 15"),
    browser.opera?(">= 50"),
    browser.facebook?
      && browser.safari_webapp_mode?
      && browser.webkit_full_version.to_i >= 602
  ].any?
end
```

### Rails integration

Just add it to the Gemfile.

```ruby
gem "browser"
```

This adds a helper method called `browser`, that inspects your current user
agent.

```erb
<% if browser.ie?(6) %>
  <p class="disclaimer">You're running an older IE version. Please update it!</p>
<% end %>
```

If you want to use Browser on your Rails app but don't want to taint your
controller, use the following line on your Gemfile:

```ruby
gem "browser", require: "browser/browser"
```

### Accept Language

Parses the accept-language header from an HTTP request and produces an array of
language objects sorted by quality.

```ruby
browser = Browser.new("Some User Agent", accept_language: "en-us")

browser.accept_language.class
#=> Array

language = browser.accept_language.first

language.code
#=> "en"

language.region
#=> "US"

language.full
#=> "en-US"

language.quality
#=> 1.0

language.name
#=> "English/United States"
```

Result is always sorted in quality order from highest to lowest. As per the HTTP
spec:

- omitting the quality value implies 1.0.
- quality value equal to zero means that is not accepted by the client.

### Internet Explorer

Internet Explorer has a compatibility view mode that allows newer versions
(IE8+) to run as an older version. Browser will always return the navigator
version, ignoring the compatibility view version, when defined. If you need to
get the engine's version, you have to use `Browser#msie_version` and
`Browser#msie_full_version`.

So, let's say an user activates compatibility view in a IE11 browser. This is
what you'll get:

```ruby
browser.version
#=> 11

browser.full_version
#=> 11.0

browser.msie_version
#=> 7

browser.msie_full_version
#=> 7.0

browser.compatibility_view?
#=> true
```

This behavior changed in `v1.0.0`; previously there wasn't a way of getting the
real browser version.

### Safari

iOS webviews and web apps aren't detected as Safari anymore, so be aware of that
if that's your case. You can use a combination of platform and webkit detection
to do whatever you want.

```ruby
# iPad's Safari running as web app mode.
browser = Browser.new("Mozilla/5.0 (iPad; U; CPU OS 3_2_1 like Mac OS X; en-us) AppleWebKit/531.21.10 (KHTML, like Gecko) Mobile/7B405")

browser.safari?
#=> false

browser.webkit?
#=> true

browser.platform.ios?
#=> true
```

### Bots

The bot detection is quite aggressive. Anything that matches at least one of the
following requirements will be considered a bot.

- Empty user agent string
- User agent that matches `/crawl|fetch|search|monitoring|spider|bot/`
- Any known bot listed under
  [bots.yml](https://github.com/fnando/browser/blob/master/bots.yml)

To add custom matchers, you can add a callable object to
`Browser::Bot.matchers`. The following example matches everything that has a
`externalhit` substring on it. The bot name will always be `General Bot`.

```ruby
Browser::Bot.matchers << ->(ua, _browser) { ua.match?(/externalhit/i) }
```

To clear all matchers, including the ones that are bundled, use
`Browser::Bot.matchers.clear`. You can re-add built-in matchers by doing the
following:

```ruby
Browser::Bot.matchers += Browser::Bot.default_matchers
```

To restore v2's bot detection, remove the following matchers:

```ruby
Browser::Bot.matchers.delete(Browser::Bot::KeywordMatcher)
Browser::Bot.matchers.delete(Browser::Bot::EmptyUserAgentMatcher)
```

### Middleware

You can use the `Browser::Middleware` to redirect user agents.

```ruby
use Browser::Middleware do
  redirect_to "/upgrade" if browser.ie?
end
```

If you're using Rails, you can use the route helper methods. Just add something
like the following to a initializer file (`config/initializers/browser.rb`).

```ruby
Rails.configuration.middleware.use Browser::Middleware do
  redirect_to upgrade_path if browser.ie?
end
```

If you need access to the `Rack::Request` object (e.g. to exclude a path), you
can do so with `request`.

```ruby
Rails.configuration.middleware.use Browser::Middleware do
  redirect_to upgrade_path if browser.ie? && request.env["PATH_INFO"] != "/exclude_me"
end
```

### Restrictions

- User agent has a size limit of 2048 bytes. This can be customized through
  `Browser.user_agent_size_limit=(size)`.
- Accept-Language has a size limit of 2048 bytes. This can be customized through
  `Browser.accept_language_size_limit=(size)`.

If size is not respected, then `Browser::Error` is raised.

```ruby
Browser.user_agent_size_limit = 4096
Browser.accept_language_size_limit = 4096
```

## Development

### Versioning

This library follows http://semver.org.

### Writing code

Once you've made your great commits (include tests, please):

1. [Fork](http://help.github.com/forking/) browser
2. Create a topic branch - `git checkout -b my_branch`
3. Push to your branch - `git push origin my_branch`
4. Create a pull request
5. That's it!

Please respect the indentation rules and code style. And use 2 spaces, not tabs.
And don't touch the version thing.

## Configuring environment

To configure your environment, you must have Ruby and bundler installed. Then
run `bundle install` to install all dependencies.

To run tests, execute `./bin/rake`.

### Adding new features

Before using your time to code a new feature, open a ticket asking if it makes
sense and if it's on this project's scope.

Don't forget to add a new entry to `CHANGELOG.md`.

#### Adding a new bot

1. Add the user agent to `test/ua_bots.yml`.
2. Add the readable name to `bots.yml`. The key must be something that matches
   the user agent, in lowercased text.
3. Run tests.

Don't forget to add a new entry to `CHANGELOG.md`.

#### Adding a new search engine

1. Add the user agent to `test/ua_search_engines.yml`.
2. Add the same user agent to `test/ua_bots.yml`.
3. Add the readable name to `search_engines.yml`. The key must be something that
   matches the user agent, in lowercased text.
4. Run tests.

Don't forget to add a new entry to `CHANGELOG.md`.

#### Wrong browser/platform/device detection

If you know how to fix it, follow the "Writing code" above. Open an issue
otherwise; make sure you fill in the issue template with all the required
information.

## Maintainer

- Nando Vieira - http://nandovieira.com

## Contributors

- https://github.com/fnando/browser/contributors

## License

(The MIT License)

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the 'Software'), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
the Software, and to permit persons to whom the Software is furnished to do so,
subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
