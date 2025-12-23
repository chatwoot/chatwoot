# rack-mini-profiler

Middleware that displays speed badge for every HTML page, along with (optional) flamegraphs and memory profiling. Designed to work both in production and in development.

![Screenshot 2023-04-05 at 3 13 52 PM](https://user-images.githubusercontent.com/845662/229996538-0f2d9c48-23d9-4d53-a1de-8b4c84c87fbd.png)

#### Features

* Database profiling - Currently supports Mysql2, Postgres, Oracle (oracle_enhanced ~> 1.5.0) and Mongoid3 (with fallback support to ActiveRecord)
* Call-stack profiling - Flame graphs showing time spent by gem
* Memory profiling - Per-request memory usage, GC stats, and global allocation metrics

#### Learn more

* [Visit our community](http://community.miniprofiler.com)
* [Watch the RailsCast](http://railscasts.com/episodes/368-miniprofiler)
* [Read about Flame graphs in rack-mini-profiler](http://samsaffron.com/archive/2013/03/19/flame-graphs-in-ruby-miniprofiler)
* [Read the announcement posts from 2012](http://samsaffron.com/archive/2012/07/12/miniprofiler-ruby-edition)

## rack-mini-profiler needs your help

We have decided to restructure our repository so there is a central UI repo and the various language implementations have their own.

**WE NEED HELP.**

- Help [triage issues](https://www.codetriage.com/miniprofiler/rack-mini-profiler) [![Open Source Helpers](https://www.codetriage.com/miniprofiler/rack-mini-profiler/badges/users.svg)](https://www.codetriage.com/miniprofiler/rack-mini-profiler)

If you feel like taking on any of this start an issue and update us on your progress.

## Installation

Install/add to Gemfile in Ruby 2.6+

```ruby
gem 'rack-mini-profiler'
```

NOTE: Be sure to require rack_mini_profiler below the `pg` and `mysql` gems in your Gemfile. rack_mini_profiler will identify these gems if they are loaded to insert instrumentation. If included too early no SQL will show up.

You can also include optional libraries to enable additional features.
```ruby
# For memory profiling
gem 'memory_profiler'

# For call-stack profiling flamegraphs
gem 'stackprof'
```

#### Rails

All you have to do is to include the Gem and you're good to go in development. See notes below for use in production.

#### Upgrading to version 2.0.0

Prior to version 2.0.0, Mini Profiler patched various Rails methods to get the information it needed such as template rendering time. Starting from version 2.0.0, Mini Profiler doesn't patch any Rails methods by default and relies on `ActiveSupport::Notifications` to get the information it needs from Rails. If you want Mini Profiler to keep using its patches in version 2.0.0 and later, change the gem line in your `Gemfile` to the following:

If you want to manually require Mini Profiler:
```ruby
gem 'rack-mini-profiler', require: ['enable_rails_patches']
```

If you don't want to manually require Mini Profiler:
```ruby
gem 'rack-mini-profiler', require: ['enable_rails_patches', 'rack-mini-profiler']
```

#### `Net::HTTP` stack level too deep errors

If you start seeing `SystemStackError: stack level too deep` errors from `Net::HTTP` after installing Mini Profiler, this means there is another patch for `Net::HTTP#request` that conflicts with Mini Profiler's patch in your application. To fix this, change `rack-mini-profiler` gem line in your `Gemfile` to the following:

```ruby
gem 'rack-mini-profiler', require: ['prepend_net_http_patch', 'rack-mini-profiler']
```

If you currently have `require: false`, remove the `'rack-mini-profiler'` string from the `require` array above so the gem line becomes like this:

```ruby
gem 'rack-mini-profiler', require: ['prepend_net_http_patch']
```

This conflict happens when a ruby method is patched twice, once using module prepend, and once using method aliasing. See this [ruby issue](https://bugs.ruby-lang.org/issues/11120) for details. The fix is to apply all patches the same way. Mini Profiler by default will apply its patch using method aliasing, but you can change that to module prepend by adding `require: ['prepend_net_http_patch']` to the gem line as shown above.

#### `peek-mysql2` stack level too deep errors

If you use peek-mysql2 with Rails >= 5, you'll need to use this gem spec in your Gemfile:

```ruby
gem 'rack-mini-profiler', require: ['prepend_mysql2_patch', 'rack-mini-profiler']
```

This should not be necessary with Rails < 5 because peek-mysql2 hooks into mysql2 gem in different ways depending on your Rails version.

#### Rails and manual initialization

In case you need to make sure rack_mini_profiler is initialized after all other gems, or you want to execute some code before rack_mini_profiler required:

```ruby
gem 'rack-mini-profiler', require: false
```
Note the `require: false` part - if omitted, it will cause the Railtie for the mini-profiler to
be loaded outright, and an attempt to re-initialize it manually will raise an exception.

Then run the generator which will set up rack-mini-profiler in development:

```bash
bundle exec rails g rack_mini_profiler:install
```

#### Rack Builder

```ruby
require 'rack-mini-profiler'

home = lambda { |env|
  [200, {'Content-Type' => 'text/html'}, ["<html><body>hello!</body></html>"]]
}

builder = Rack::Builder.new do
  use Rack::MiniProfiler
  map('/') { run home }
end

run builder
```

#### Sinatra

```ruby
require 'rack-mini-profiler'
class MyApp < Sinatra::Base
  use Rack::MiniProfiler
end
```

#### Hanami
For working with hanami, you need to use rack integration. Also, you need to add `Hanami::View::Rendering::Partial#render` method for profile:

```ruby
# config.ru
require 'rack-mini-profiler'
Rack::MiniProfiler.profile_method(Hanami::View::Rendering::Partial, :render) { "Render partial #{@options[:partial]}" }

use Rack::MiniProfiler
```

#### Patching ActiveRecord

A typical web application spends a lot of time querying the database. rack_mini_profiler will detect the ORM that is available
and apply patches to properly collect query statistics.

To make this work, declare the orm's gem before declaring `rack-mini-profiler` in the `Gemfile`:

```ruby
gem 'pg'
gem 'mongoid'
gem 'rack-mini-profiler'

```

If you wish to override this behavior, the environment variable `RACK_MINI_PROFILER_PATCH` is available.

```bash
export RACK_MINI_PROFILER_PATCH="pg,mongoid"
# or
export RACK_MINI_PROFILER_PATCH="false"
# initializers/rack_profiler.rb: SqlPatches.patch %w(mongo)
```

#### Patching Net::HTTP

Other than databases, `rack-mini-profiler` applies a patch to `Net::HTTP`. You may want to disable this patch:

```bash
export RACK_MINI_PROFILER_PATCH_NET_HTTP="false"
```

### Flamegraphs

To generate [flamegraphs](http://samsaffron.com/archive/2013/03/19/flame-graphs-in-ruby-miniprofiler), add the [**stackprof**](https://rubygems.org/gems/stackprof) gem to your Gemfile.

Then, to view the flamegraph as a direct HTML response from your request, just visit any page in your app with `?pp=flamegraph` appended to the URL, or add the header `X-Rack-Mini-Profiler` to the request with the value `flamegraph`.

Conversely, if you want your regular response instead (which is specially useful for JSON and/or XHR requests), just append the `?pp=async-flamegraph` parameter to your request/fetch URL; the request will then return as normal, and the flamegraph data will be stored for later *async* viewing, both for this request and for all subsequent requests made by this page (based on the `REFERER` header). For viewing these async flamegraphs, use the 'flamegraph' link that will appear inside the MiniProfiler UI for these requests.

Note: Mini Profiler will not record SQL timings for a request if it asks for a flamegraph. The rationale behind this is to keep
Mini Profiler's methods that are responsible for generating the timings data out of the flamegraph.

### Memory Profiling

Memory allocations can be measured (using the [memory_profiler](https://github.com/SamSaffron/memory_profiler) gem)
which will show allocations broken down by gem, file location, and class and will also highlight `String` allocations.

Add `?pp=profile-memory` to the URL of any request while Rack::MiniProfiler is enabled to generate the report.

Additional query parameters can be used to filter the results.

* `memory_profiler_allow_files` - filename pattern to include (default is all files)
* `memory_profiler_ignore_files` - filename pattern to exclude (default is no exclusions)
* `memory_profiler_top` - number of results per section (defaults to 50)

The allow/ignore patterns will be treated as regular expressions.

Example: `?pp=profile-memory&memory_profiler_allow_files=active_record|app`

There are two additional `pp` options that can be used to analyze memory which do not require the `memory_profiler` gem

* Use `?pp=profile-gc` to report on Garbage Collection statistics
* Use `?pp=analyze-memory` to report on ObjectSpace statistics

### Snapshots Sampling

In a complex web application, it's possible for a request to trigger rare conditions that result in poor performance. Mini Profiler ships with a feature to help detect those rare conditions and fix them. It works by enabling invisible profiling on one request every N requests, and saving the performance metrics that are collected during the request (a.k.a snapshot of the request) so that they can be viewed later. To turn this feature on, set the `snapshot_every_n_requests` config to a value larger than 0. The larger the value is, the less frequently requests are profiled.

Mini Profiler will exclude requests that are made to skipped paths (see `skip_paths` config below) from being sampled. Additionally, if profiling is enabled for a request that later finishes with a non-2xx status code, Mini Profiler will discard the snapshot and not save it (this behavior may change in the future).

After enabling snapshots sampling, you can see the snapshots that have been collected at `/mini-profiler-resources/snapshots` (or if you changed the `base_url_path` config, substitute `mini-profiler-resources` with your value of the config). You'll see on that page a table where each row represents a group of snapshots with the duration of the worst snapshot in that group. The worst snapshot in a group is defined as the snapshot whose request took longer than all of the snapshots in the same group. Snapshots grouped by HTTP method and path of the request, and if your application is a Rails app, Mini Profiler will try to convert the path to `controller#action` and group by that instead of request path. Clicking on a group will display the snapshots of that group sorted from worst to best. From there, you can click on a snapshot's ID to see the snapshot with all the performance metrics that were collected.

Access to the snapshots page is restricted to only those who can see the speed badge on their own requests, see the section below this one about access control.

Mini Profiler will keep a maximum of 50 snapshot groups and a maximum of 15 snapshots per group making the default maximum number of snapshots in the system 750. The default group and per group limits can be changed via the `max_snapshot_groups` and `max_snapshots_per_group` configuration options, see the configurations table below.

#### Snapshots Transporter

Mini Profiler can be configured so that it sends snapshots over HTTP using the snapshots transporter. The main use-case of the transporter is to allow the aggregation of snapshots from multiple applications/sources in a single place. To enable the snapshots transporter, you need to provide a destination URL to the `snapshots_transport_destination_url` config, and a secure key to the `snapshots_transport_auth_key` config (will be used for authorization). Both of these configs are required for the transporter to be enabled.

The transporter uses a buffer to temporarily hold snapshots in memory with a limit of 100 snapshots. Every 30 seconds, *if* the buffer is not empty, the transporter will make a `POST` request with the buffer content to the destination URL. Requests made by the transporter will have a `Mini-Profiler-Transport-Auth` header with the value of the `snapshots_transport_auth_key` config. The destination should only accept requests that include this header AND the header's value matches the key you set to the `snapshots_transport_auth_key` config.

If the specified destination responds with a non-200 status code, the transporter will increase the interval between requests by `2^n` seconds where `n` is the number of failed requests since the last successful request. The base interval between requests is 30 seconds. So if a request fails, the next request will be `30 + 2^1 = 32` seconds later. If the next request fails too, the next one will be `30 + 2^2 = 34` seconds later and so on until a request succeeds at which point the interval will return to 30 seconds. The interval will not go beyond 1 hour.

Requests made by the transporter can be optionally gzip-compressed by setting the `snapshots_transport_gzip_requests` config to true. The body of the requests (after decompression, if you opt for compression) is a JSON string with a single top-level key called `snapshots` and it has an array of snapshots. The structure of a snapshot is too complex to be explained here, but it has the same structure that Mini Profiler client expects. So if your use-case is to simply be able to view snapshots from multiple sources in one place, you should simply store the snapshots as-is, and then serve them to Mini Profiler client to consume. If the destination application also has Mini Profiler, you can simply use the API of the storage backends to store the incoming snapshots and Mini Profiler will treat them the same as local snapshots (e.g. they'll be grouped and displayed in the same manner described in the previous section).

Mini Profiler offers an API to add extra fields (a.k.a custom fields) to snapshots. For example, you may want to add whether the request was made by a logged-in or anonymous user, the version of your application or any other things that are specific to your application. To add custom fields to a snapshot, call the `Rack::MiniProfiler.add_snapshot_custom_field(<key>, <value>)` method anywhere during the lifetime of a request, and the snapshot of that request will include the fields you added. If you have a Rails app, you can call that method in an `after_action` callback. Custom fields are cleared between requests.

## Access control in non-development environments

rack-mini-profiler is designed with production profiling in mind. To enable that run `Rack::MiniProfiler.authorize_request` once you know a request is allowed to profile.

```ruby
  # inside your ApplicationController

  before_action do
    if current_user && current_user.is_admin?
      Rack::MiniProfiler.authorize_request
    end
  end
```

> If your production application is running on more than one server (or more than one dyno) you will need to configure rack mini profiler's storage to use Redis or Memcache. See [storage](#storage) for information on changing the storage backend.

Note:

Out-of-the-box we will initialize the `authorization_mode` to `:allow_authorized` in production. However, in some cases we may not be able to do it:

- If you are running in development or test we will not enable the explicit authorization mode
- If you use `require: false` on rack_mini_profiler we are unlikely to be able to run the railtie
- If you are running outside of rails we will not run the railtie

In those cases use:

```ruby
Rack::MiniProfiler.config.authorization_mode = :allow_authorized
```

When deciding to fully profile a page mini profiler consults with the `authorization_mode`

By default in production we attempt to set the authorization mode to `:allow_authorized` meaning that end user will only be able to see requests where somewhere `Rack::MiniProfiler.authorize_request` is invoked.

In development we run in the `:allow_all` authorization mode meaning every request is profiled and displayed to the end user.


## Configuration

Various aspects of rack-mini-profiler's behavior can be configured when your app boots.
For example in a Rails app, this should be done in an initializer:
**config/initializers/mini_profiler.rb**

### Caching behavior

To fix some nasty bugs with rack-mini-profiler showing the wrong data, the middleware
will remove headers relating to caching (Date & Etag on responses, If-Modified-Since & If-None-Match on requests).
This probably won't ever break your application, but it can cause some unexpected behavior. For
example, in a Rails app, calls to `stale?` will always return true.

To disable this behavior, use the following config setting:

```ruby
# Do not let rack-mini-profiler disable caching
Rack::MiniProfiler.config.disable_caching = false # defaults to true
```

### Storage

rack-mini-profiler stores its results so they can be shared later and aren't lost at the end of the request.

There are 4 storage options: `MemoryStore`, `RedisStore`, `MemcacheStore`, and `FileStore`.

`FileStore` is the default in Rails environments and will write files to `tmp/miniprofiler/*`.  `MemoryStore` is the default otherwise.

```ruby
# set MemoryStore
Rack::MiniProfiler.config.storage = Rack::MiniProfiler::MemoryStore

# set RedisStore
if Rails.env.production?
  Rack::MiniProfiler.config.storage_options = { url: ENV["REDIS_SERVER_URL"] }
  Rack::MiniProfiler.config.storage = Rack::MiniProfiler::RedisStore
end
```

`MemoryStore` stores results in a processes heap - something that does not work well in a multi process environment.
`FileStore` stores results in the file system - something that may not work well in a multi machine environment.
`RedisStore`/`MemcacheStore` work in multi process and multi machine environments (`RedisStore` only saves results for up to 24 hours so it won't continue to fill up Redis). You will need to add `gem redis`/`gem dalli` respectively to your `Gemfile` to use these stores.

Additionally you may implement an `AbstractStore` for your own provider.

### User result segregation

MiniProfiler will attempt to keep all user results isolated, out-of-the-box the user provider uses the ip address:

```ruby
Rack::MiniProfiler.config.user_provider = Proc.new{|env| Rack::Request.new(env).ip}
```

You can override (something that is very important in a multi-machine production setup):

```ruby
Rack::MiniProfiler.config.user_provider = Proc.new{ |env| CurrentUser.get(env) }
```

The string this function returns should be unique for each user on the system (for anonymous you may need to fall back to ip address)

### Profiling specific methods

You can increase the granularity of profiling by measuring the performance of specific methods. Add methods of interest to an initializer.

```ruby
Rails.application.config.to_prepare do
  ::Rack::MiniProfiler.profile_singleton_method(User, :non_admins) { |a| "executing all_non_admins" }
  ::Rack::MiniProfiler.profile_method(User, :favorite_post) { |a| "executing favorite_post" }
end
```

### Profiling arbitrary block of code

It is also possible to profile any arbitrary block of code by passing a block to `Rack::MiniProfiler.step(name, opts=nil)`.

```ruby
Rack::MiniProfiler.step('Adding two elements') do
  result = 1 + 2
end
```

### Using in SPA applications

Single page applications built using Ember, Angular or other frameworks need some special care, as routes often change without a full page load.

On route transition always call:

```
if (window.MiniProfiler !== undefined) {
  window.MiniProfiler.pageTransition();
}
```

This method will remove profiling information that was related to previous page and clear aggregate statistics.

#### MiniProfiler's speed badge on pages that are not generated via Rails
You need to inject the following in your SPA to load MiniProfiler's speed badge ([extra details surrounding this script](https://github.com/MiniProfiler/rack-mini-profiler/issues/139#issuecomment-192880706) and [credit for the script tag](https://github.com/MiniProfiler/rack-mini-profiler/issues/479#issue-782488320) to [@ivanyv](https://github.com/ivanyv)):

```html
 <script type="text/javascript" id="mini-profiler"
        src="/mini-profiler-resources/includes.js?v=12b4b45a3c42e6e15503d7a03810ff33"
        data-css-url="/mini-profiler-resources/includes.css?v=12b4b45a3c42e6e15503d7a03810ff33"
        data-version="12b4b45a3c42e6e15503d7a03810ff33"
        data-path="/mini-profiler-resources/"
        data-horizontal-position="left"
        data-vertical-position="top"
        data-ids=""
        data-trivial="false"
        data-children="false"
        data-max-traces="20"
        data-controls="false"
        data-total-sql-count="false"
        data-authorized="true"
        data-toggle-shortcut="alt+p"
        data-start-hidden="false"
        data-collapse-results="true"
        data-html-container="body"
        data-hidden-custom-fields></script>
```

See an [example of how to do this in a React useEffect](https://gist.github.com/katelovescode/01cfc2b962c165193b160fd10af6c4d5).

_Note:_ The GUID (`data-version` and the `?v=` parameter on the `src` and `data-css-url`) will change with each release of `rack_mini_profiler`. The MiniProfiler's speed badge will continue to work, although you will have to change the GUID to expire the script to fetch the most recent version.

#### Using MiniProfiler's built in route for apps without HTML responses
MiniProfiler also ships with a `/rack-mini-profiler/requests` route that displays the speed badge on a blank HTML page. This can be useful when profiling an application that does not render HTML.

#### Register MiniProfiler's assets in the Rails assets pipeline
MiniProfiler can be configured so it registers its assets in the assets pipeline. To do that, you'll need to provide a lambda (or proc) to the `assets_url` config (see the below section). The callback will receive 3 arguments which are: `name` represents asset name (currently it's either `rack-mini-profiling.js` or `rack-mini-profiling.css`), `assets_version` is a 32 characters long hash of MiniProfiler's assets, and `env` which is the `env` object of the request. MiniProfiler expects the `assets_url` callback to return a URL from which the asset can be loaded (the return value will be used as a `href`/`src` attribute in the DOM). If the `assets_url` callback is not set (the default) or it returns a non-truthy value, MiniProfiler will fallback to loading assets from its own middleware (`/mini-profiler-resources/*`). The following callback should work for most applications:

```ruby
Rack::MiniProfiler.config.assets_url = ->(name, version, env) {
  ActionController::Base.helpers.asset_path(name)
}
```

### Configuration Options

You can set configuration options using the configuration accessor on `Rack::MiniProfiler`.
For example:

```ruby
Rack::MiniProfiler.config.position = 'bottom-right'
Rack::MiniProfiler.config.start_hidden = true
```
The available configuration options are:

Option                              | Default                                                 | Description
------------------------------------|---------------------------------------------------------|------------------------
pre_authorize_cb                    | Rails: dev only<br>Rack: always on                      | A lambda callback that returns true to make mini_profiler visible on a given request.
position                            | `'top-left'`                                            | Display mini_profiler on `'top-right'`, `'top-left'`, `'bottom-right'` or `'bottom-left'`.
skip_paths                          | `[]`                                                    | An array of paths that skip profiling. Both `String` and `Regexp` are acceptable in the array.
skip_schema_queries                 | Rails dev: `true`<br>Othwerwise: `false`                | `true` to skip schema queries.
auto_inject                         | `true`                                                  | `true` to inject the miniprofiler script in the page.
backtrace_ignores                   | `[]`                                                    | Regexes of lines to be removed from backtraces.
backtrace_includes                  | Rails: `[/^\/?(app\|config\|lib\|test)/]`<br>Rack: `[]` | Regexes of lines to keep in backtraces.
backtrace_remove                    | rails: `Rails.root`<br>Rack: `nil`                      | A string or regex to remove part of each line in the backtrace.
toggle_shortcut                     | Alt+P                                                   | Keyboard shortcut to toggle the mini_profiler's visibility. See [jquery.hotkeys](https://github.com/jeresig/jquery.hotkeys).
start_hidden                        | `false`                                                 | `false` to make mini_profiler visible on page load.
backtrace_threshold_ms              | `0`                                                     | Minimum SQL query elapsed time before a backtrace is recorded.
flamegraph_sample_rate              | `0.5`                                                   | How often to capture stack traces for flamegraphs in milliseconds.
flamegraph_mode                     | `:wall`                                                 | The [StackProf mode](https://github.com/tmm1/stackprof#all-options) to pass to `StackProf.run`.
base_url_path                       | `'/mini-profiler-resources/'`                           | Path for assets; added as a prefix when naming assets and sought when responding to requests.
cookie_path                         | `'/'`                                                   | Set-Cookie header path for profile cookie
collapse_results                    | `true`                                                  | If multiple timing results exist in a single page, collapse them till clicked.
max_traces_to_show                  | 20                                                      | Maximum number of mini profiler timing blocks to show on one page
html_container                      | `body`                                                  | The HTML container (as a jQuery selector) to inject the mini_profiler UI into
show_total_sql_count                | `false`                                                 | Displays the total number of SQL executions.
enable_advanced_debugging_tools     | `false`                                                 | Enables sensitive debugging tools that can be used via the UI. In production we recommend keeping this disabled as memory and environment debugging tools can expose contents of memory that may contain passwords. Defaults to `true` in development.
assets_url                          | `nil`                                                   | See the "Register MiniProfiler's assets in the Rails assets pipeline" section above.
snapshot_every_n_requests           | `-1`                                                    | Determines how frequently snapshots are taken. See the "Snapshots Sampling" above for more details.
max_snapshot_groups                 | `50`                                                    | Determines how many snapshot groups Mini Profiler is allowed to keep.
max_snapshots_per_group             | `15`                                                    | Determines how many snapshots per group Mini Profiler is allowed to keep.
snapshot_hidden_custom_fields       | `[]`                                                    | Each snapshot custom field will have a dedicated column in the UI by default. Use this config to exclude certain custom fields from having their own columns.
snapshots_transport_destination_url | `nil`                                                   | Set this config to a valid URL to enable snapshots transporter which will `POST` snapshots to the given URL. The transporter requires `snapshots_transport_auth_key` config to be set as well.
snapshots_transport_auth_key        | `nil`                                                   | `POST` requests made by the snapshots transporter to the destination URL will have a `Mini-Profiler-Transport-Auth` header with the value of this config. Make sure you use a secure and random key for this config.
snapshots_redact_sql_queries        | `true`                                                  | When this is true, SQL queries will be redacted from sampling snapshots, but the backtrace and duration of each SQL query will be saved with the snapshot to keep debugging performance issues possible.
snapshots_transport_gzip_requests   | `false`                                                 | Make the snapshots transporter gzip the requests it makes to `snapshots_transport_destination_url`.
content_security_policy_nonce       | Rails: Current nonce<br>Rack: nil                       | Set the content security policy nonce to use when inserting MiniProfiler's script block.
enable_hotwire_turbo_drive_support  | `false`                                                 | Enable support for Hotwire TurboDrive page transitions.
profile_parameter                   | `'pp'`                                                  | The query parameter used to interact with this gem.

### Using MiniProfiler with `Rack::Deflate` middleware

If you are using `Rack::Deflate` with Rails and `rack-mini-profiler` in its default configuration,
`Rack::MiniProfiler` will be injected (as always) at position 0 in the middleware stack,
which means it will run after `Rack::Deflate` on response processing. To prevent attempting to inject
HTML in already compressed response body MiniProfiler will suppress compression by setting
`identity` encoding in `Accept-Encoding` request header.

### Using MiniProfiler with Heroku Redis

If you are using Heroku Redis, you may need to add the following to your `config/initializers/mini_profiler.rb`, in order to get Mini Profiler to work:

```ruby
if Rails.env.production?
  Rack::MiniProfiler.config.storage_options = { 
    url: ENV["REDIS_URL"],
    ssl_params: { verify_mode: OpenSSL::SSL::VERIFY_NONE }
  }
  Rack::MiniProfiler.config.storage = Rack::MiniProfiler::RedisStore
end
```

The above code snippet is [Heroku's officially suggested workaround](https://help.heroku.com/HC0F8CUS/redis-connection-issues).

## Special query strings

If you include the query string `pp=help` at the end of your request you will see the various options available. You can use these options to extend or contract the amount of diagnostics rack-mini-profiler gathers.

## Development

If you want to contribute to this project, that's great, thank you! You can run the following rake task:

```
$ BUNDLE_GEMFILE=website/Gemfile bundle install
$ bundle exec rake client_dev
```

This will start a local Sinatra server at `http://localhost:9292` where you'll be able to preview your changes. Refreshing the page should be enough to see any changes you make to files in the `lib/html` directory.

Make sure to prepend `bundle exec` before any Rake tasks you run.

## Running the Specs

You need Memcached and Redis services running for the specs.

```
$ bundle exec rake build
$ bundle exec rake spec
```

## Licence

The MIT License (MIT)

Copyright (c) 2013 Sam Saffron

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
