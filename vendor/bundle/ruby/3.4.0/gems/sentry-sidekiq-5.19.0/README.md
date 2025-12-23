<p align="center">
  <a href="https://sentry.io" target="_blank" align="center">
    <img src="https://sentry-brand.storage.googleapis.com/sentry-logo-black.png" width="280">
  </a>
  <br>
</p>

# sentry-sidekiq, the Sidekiq integration for Sentry's Ruby client

---


[![Gem Version](https://img.shields.io/gem/v/sentry-sidekiq.svg)](https://rubygems.org/gems/sentry-sidekiq)
![Build Status](https://github.com/getsentry/sentry-ruby/actions/workflows/sentry_sidekiq_test.yml/badge.svg)
[![Coverage Status](https://img.shields.io/codecov/c/github/getsentry/sentry-ruby/master?logo=codecov)](https://codecov.io/gh/getsentry/sentry-ruby/branch/master)
[![Gem](https://img.shields.io/gem/dt/sentry-sidekiq.svg)](https://rubygems.org/gems/sentry-sidekiq/)
[![SemVer](https://api.dependabot.com/badges/compatibility_score?dependency-name=sentry-sidekiq&package-manager=bundler&version-scheme=semver)](https://dependabot.com/compatibility-score.html?dependency-name=sentry-sidekiq&package-manager=bundler&version-scheme=semver)


[Documentation](https://docs.sentry.io/platforms/ruby/guides/sidekiq/) | [Bug Tracker](https://github.com/getsentry/sentry-ruby/issues) | [Forum](https://forum.sentry.io/) | IRC: irc.freenode.net, #sentry

The official Ruby-language client and integration layer for the [Sentry](https://github.com/getsentry/sentry) error reporting API.


## Getting Started

### Install

```ruby
gem "sentry-ruby"
gem "sentry-sidekiq"
```

Then you're all set! `sentry-sidekiq` will automatically insert a custom middleware and error handler to capture exceptions from your workers!
