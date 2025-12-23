# Listen watcher for Spring

[![Build Status](https://app.travis-ci.com/rails/spring-watcher-listen.svg?branch=master)](https://app.travis-ci.com/github/rails/spring-watcher-listen)
[![Gem Version](https://badge.fury.io/rb/spring-watcher-listen.png)](http://badge.fury.io/rb/spring-watcher-listen)

This gem makes [Spring](https://github.com/rails/spring) watch the
filesystem for changes using [Listen](https://github.com/guard/listen)
rather than by polling the filesystem.

On larger projects this means spring will be more responsive, more accurate and use less cpu on local filesystems.

(NFS, shared VM folders and user file systems will still need polling)

Listen 2.7 and higher and 3.0 are supported.
If you rely on Listen 1 you can use v1.0.0 of this gem.

## Environment variables

* `DISABLE_SPRING_WATCHER_LISTEN` - If set, this disables the loading of this gem. This can be useful for projects where
    some configurations do not support inotify (e.g. Docker on M1 Macs).

## Installation

Stop Spring if it's already running:

    $ spring stop

Add this line to your application's Gemfile:

    gem 'spring-watcher-listen', group: :development

And then execute:

    $ bundle
