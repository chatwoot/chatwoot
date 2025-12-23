# ScoutApm Ruby Agent

[![Build Status](https://travis-ci.org/scoutapp/scout_apm_ruby.svg?branch=master)](https://travis-ci.org/scoutapp/scout_apm_ruby)

A Ruby gem for detailed Rails application performance monitoring 📈. Metrics and transaction traces are
reported to [Scout](https://scoutapp.com), a hosted application monitoring
service.

## What's the special sauce? 🤔

The Scout agent is engineered to do some wonderful things:

* A unique focus on identifying those hard-to-investigate outliers like memory bloat, N+1s, and user-specific problems. [See an example workflow](http://scoutapp.com/newrelic-alternative).
* [Low-overhead](http://blog.scoutapp.com/articles/2016/02/07/overhead-benchmarks-new-relic-vs-scout)
* View your performance metrics during development with [DevTrace](https://docs.scoutapm.com/#devtrace) and in production via [server_timing](https://github.com/scoutapp/ruby_server_timing).
* Production-Safe profiling of custom code via [ScoutProf](https://docs.scoutapm.com/#scoutprof) (BETA).

## Getting Started

Add the gem to your Gemfile

    gem 'scout_apm'

Update your Gemfile

    bundle install

Signup for a [Scout](https://scoutapm.com) account and put the provided
config file at `RAILS_ROOT/config/scout_apm.yml`.

Your config file should look like:

    common: &defaults
      name: YOUR_APPLICATION_NAME
      key: YOUR_APPLICATION_KEY
      monitor: true

    test:
      monitor: false

    production:
      <<: *defaults

## DevTrace Quickstart

To use DevTrace, our free, no-signup, in-browser development profiler:

1. Add the gem to your Gemfile:

```ruby
# Gemfile
gem 'scout_apm'
```

2. Start your Rails app with the SCOUT_DEV_TRACE environment variable:

```
SCOUT_DEV_TRACE=true rails server
```

## How to test gem locally

* Point your gemfile at your local checkout: `gem 'scout_apm', path: '/path/to/scout_apm_ruby`
* Compile native code: `cd /path/to/scout_apm_ruby && bundle exec rake compile`


## Docs

For the complete list of supported frameworks, Rubies, configuration options
and more, see our [help site](https://docs.scoutapm.com/).

## Help

Email support@scoutapp.com if you need a hand.
