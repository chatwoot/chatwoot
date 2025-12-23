# CHANGELOG

## 3.2.0 - 2023-12-06
- [BREAKING CHANGE] Ruby version 2.7.0 or later is required.
- [FEATURE] All RMP actions can be chosen by including a X-Rack-Mini-Profiler header as well as by query parameter. [#578](https://github.com/MiniProfiler/rack-mini-profiler/pull/578)
- [FEATURE] Speedscope 1.12 -> 1.16
- [FIX] If patch_rails is false, do not patch mysql2 or pg [#583](https://github.com/MiniProfiler/rack-mini-profiler/pull/583)
- [FIX] vertical position bottom now aligns the detail window correctly [#581](https://github.com/MiniProfiler/rack-mini-profiler/pull/581)
- [FIX] Webpacker hiccup in some setups [#582](https://github.com/MiniProfiler/rack-mini-profiler/pull/582)
- [INTERNAL] Capture rows instantiated by ActiveRecord, UI to be added later [#585](https://github.com/MiniProfiler/rack-mini-profiler/pull/585)
- [INTERNAL] Lots of refactoring.


## 3.1.1 - 2023-08-01

- [FIX] Include configured base path in speedscope iframe URL [#587](https://github.com/MiniProfiler/rack-mini-profiler/pull/587)
- [FIX] Race condition starting CacheCleanupThread [#586](https://github.com/MiniProfiler/rack-mini-profiler/pull/586)
- [FEATURE] Add controller name to description [#567](https://github.com/MiniProfiler/rack-mini-profiler/pull/567)
- [FIX] 'more' link w/HTTPS [#574](https://github.com/MiniProfiler/rack-mini-profiler/pull/574)

## 3.1.0 - 2023-04-11

- [FEATURE] The query parameter that RMP uses (by default, pp) is now configurable [#553](https://github.com/MiniProfiler/rack-mini-profiler/pull/553)
- [FEATURE] You can now opt-out of the Net::HTTP patch by using RACK_MINI_PROFILER_PATCH_NET_HTTP="false"
- [FIX] Error responses now include header values from the app, and stackprof not installed message now has correct content [#547](https://github.com/MiniProfiler/rack-mini-profiler/pull/547)
- [FIX] RMP pages now have more valid HTML, with title elements [#552](https://github.com/MiniProfiler/rack-mini-profiler/pull/552)
- [BREAKING CHANGE] Ruby 2.4 and Ruby 2.5 are no longer supported.
- [FIX] Now works with apps that don't otherwise require erb [#531](https://github.com/MiniProfiler/rack-mini-profiler/pull/531)
- [DOCS] Added Heroku Redis instructions
- [DEPRECATION] We are changing the name of the generators to `rack_mini_profiler`, e.g. `rack_mini_profiler:install` [#550](https://github.com/MiniProfiler/rack-mini-profiler/pull/550)

## 3.0.0 - 2022-02-24

- PERF: Improve snapshots page performance (#518) (introduces breaking changes to the API of `AbstractStore`, `MemoryStore` and `RedisStore`, and removes the `snapshots_limit` config option.)

## 2.3.4 - 2022-02-23

- [FEATURE] Add cookie path support for subfolder sites
- [FIX] Remove deprecated uses of Redis#pipelined

## 2.3.3 - 2021-08-30

- [FEATURE] Introduce `pp=flamegraph_mode`
- [FEATURE] Richer CSP configuration options
- [FEATURE] Add support for Hotwire Turbo Drive

## 2.3.2 - 2021-04-30

- [FEATURE] Introduce `pp=async-flamegraph` for asynchronous flamegraphs

## 2.3.1 - 2021-01-29

- [FIX] compatability with Ruby 3.0
- [FIX] compatability with peek-mysql2

## 2.3.0 - 2020-12-29

- [FEATURE] flamegraphs are now based off speedscope

## 2.2.1 - 2020-12-23

- [FIX] Turbolinks integration causing increasing number of GET requests
- [FEATURE] enahanced log transporter with compression and exponential backoff
- [FEATURE] sameSite=Lax added to MiniProfiler cookie

## 2.2.0 - 2020-10-19

- [UX] Enhancements to snapshots UI
- [FEATURE] Mini Profiler cookie is now sameSite=lax
- [FEATURE] Snapshots transporter
- [FEATURE] Redact SQL queries in snapshots by default

## 2.1.0 - 2020-09-17

- [FEATURE] Allow assets to be precompiled with Sprockets
- [FEATURE] Snapshots sampling (see README in repo)
- [FEATURE] Allow `skip_paths` config to contain regular expressions

## 2.0.4 - 2020-08-04

- [FIX] webpacker may exist with no config, allow for that

## 2.0.3 - 2020-07-29

- [FIX] support for deprecation free Redis 4.2
- [FEATURE] skip /packs when serving static assets
- [FEATURE] allow Net::HTTP patch to be applied with either prerpend or alias

## 2.0.2 - 2020-05-25

- [FIX] client timings were not showing up when you clicked show trivial

## 2.0.1 - 2020-03-17

- [REVERT] Prepend Net::HTTP patch instead of class_eval and aliasing (#429) (technique clashes with New Relic and Skylight agents)

## 2.0.0 - 2020-03-11

- [FEATURE] Prepend Net::HTTP patch instead of class_eval and aliasing (#429)
- [FEATURE] Stop patching Rails and use `ActiveSupport::Notifications` by default (see README.md for details)

## 1.1.6 - 2020-01-30

- [FIX] edge condition on page transition function could lead to exceptions

## 1.1.5 - 2020-01-28

- [FIX] correct custom counter regression
- [FIX] respect max_traces_to_show
- [FIX] handle storage engine failures in whitelist mode

## 1.1.4 - 2019-12-12

- [SECURITY] carefully crafted SQL could cause an XSS on sites that do not use CSPs

## 1.1.3 - 2019-10-28

- [FEATURE] precompile all templates to avoid need for unsafe-eval

## 1.1.2 - 2019-10-24

- [FIX] JS payload was not working on IE11 and leading to errors
- [FIX] Remove global singleton_class which was injected
- [FIX] Regressions post removal of jQuery

## 1.1.1 - 2019-10-22

- [FIX] correct JavaScript fetch support header iteration (Jorge Manrubia)

## 1.1.0 - 2019-10-01

- [FEATURE] remove jQuery dependency, switch template library to dot.js
- [FEATURE] disable all sensitive debugging methods by default (env, memory profiling) can be enabled with enable_advanced_debugging_tools.
- [FIX] when conditionally requiring rack mini profiler, asset precompile could fail
- [FEATURE] `/rack-mini-profiler/requests` can be used to monitor all requests for apps that do not have a UI (like API apps)
- [SECURITY] XSS injection in `?pp=help` via rogue uri

## 1.0.2 - 2019-02-05

- [FIX] correct script injection to work with Rails 6 and above

## 1.0.1 - 2018-12-10

- [FIX] add support for exec_params instrumentation in PG, this method as of PG 1.1.0 no longer
 routes calls to exec / async_exec
- [FIX] add missing started_at on requests
- [UX] amend colors so we pass lighthouse
- [FEATURE] fetch API support
- [FIX] getEntriesByName is missing in iOS, workaround
- [FEATURE] drop support for Ruby 2.2.0 we require 2.3.0 and up (EOL Ruby no longer supported)

## 1.0.0 - 2018-03-29

- [BREAKING CHANGE] Ruby version 2.2.0 or later is required
- [FEATURE] use new web performance API to avoid warning @MikeRogers0
- [FEATURE] store hidden pref regarding showing mini profiler in session @MikeRogers0
- [FIX] correct jQuery 3.0 deprecations @TiSer
- [FIX] JS in IFRAME @naiyt

## 0.10.8 - 2017-12-01

- [FEATURE] Add `# frozen_string_literal: true` to all `lib/**/*.rb` files

## 0.10.7 - 2017-11-24

- [FEATURE] Replace Time.now with Process.clock_gettime(Process::CLOCK_MONOTONIC)
- [FIX] Error with webrick and empty cache control

## 0.10.6 - 2017-10-30

- [FEATURE] Support for vertical positions (top/bottom)
- [FEATURE] Suppress profiler results in print media @Mike Dillon
- [FIX] toggle shortcut not working @lukesilva
- [FEATURE] install generator @yhirano
- [FEATURE] store initial cache control headers in X-MiniProfiler-Original-Cache-Control @mrasu

## 0.10.5 - 2017-05-22

- [FIX] revert PG bind sniffing until it is properly tested

## 0.10.4 - 2017-05-17

- [FEATURE] log binds for pg @neznauy
- [FIX] use async exec pg monkey patch instead of exec
- [FEATURE] nuke less css and use sass instead
- [FIX] use jQuery on instead of bind
- [FIX] ensure redis get_unviewed_ids returns only ids that exist
- [FIX] correctly respect SCRIPT in env if it is sniffed by middleware

## 0.10.2 - 2017-02-08

- [FIX] improve turbolinks support
- [FEATURE] make location of mini_profiler injection customizable

## 0.10.1 - 2016-05-18

- [FEATURE] push forward the security checks so no work is ever done if a valid production
    cookie is not available (@sam)

## 0.9.9.2 - 2016-03-06

- [FEATURE] on pageTransition collapse previously expanded timings

## 0.9.9.1 - 2016-03-06

- [FEATURE] expost MiniProfiler.pageTransition() for use by SPA web apps (@sam)

## 0.9.9 - 2016-03-06

- [FIX] removes alias_method_chain in favor of alias_method until Ruby 1.9.3 (@ayfredlund)
- [FIX] Dont block mongo when already patched for another db (@rrooding @kbrock)
- [FIX] get_profile_script when running under passenger configured with RailsBaseURI (@nspring)
- [FEATURE] Add support for neo4j (@ProGM)
- [FIX] ArgumentError: comparison of String with 200 failed (@paweljw)
- [FEATURE] Add support for Riak (@janx)
- [PERF] GC profiler much faster (@dgynn)
- [FIX] If local storage is disabled don't bomb out (@elia)
- [FIX] Create tmp directory when actually using it (@kbrock)
- [ADDED] Default collapse_results setting that collapses multiple timings on same page to a single one (@sam)
- [ADDED] Rack::MiniProfiler.profile_singleton_method (@kbrock)
- [CHANGE] Added Rack 2.0 support (and dropped support for Rack 1.1) (@dgynn)

## 0.9.8 - 2015-11-27 (Sam Saffron)

- [FEATURE] disable_env_dump config setting (@mathias)
- [FEATURE] set X-MiniProfiler-Ids for all 2XX reqs (@tymagu2)
- [FEATURE] add support for NoBrainer (rethinkdb) profiling (@niv)
- [FEATURE] add oracle enhanced adapter profiling (@rrooding)
- [FEATURE] pp=profile-memory can now parse query params (@dgynn)


## 0.9.7 - 2015-08-03 (Sam Saffron)

- [FEATURE] remove confusing pp=profile-gc-time (Nate Berkopec)
- [FEATURE] truncate strings in pp=analyze-memory (Nate Berkopec)
- [FEATURE] rename pp=profile-gc-ruby-head to pp=profile-memory (Nate Berkopec)

## 0.9.6 - 2015-07-08 (Sam Saffron)

- [FIX] incorrect truncation in pp=analyze-memory

## 0.9.5 - 2015-07-08 (Sam Saffron)

- [FEATURE] improve pp=analyze-memory

## 0.9.4 - 2015-07-08 (Sam Saffron)
- [UX] added a link to "more" actions in profiler
- [FEATURE] pp=help now displays links
- [FEATURE] simple memory report with pp=analyze-memory

## 0.9.2 - 2014-06-26 (Sam Saffron)
- [CHANGE] staging and other environments behave like production (Cedric Felizard)
- [DOC] CHANGELOG reorg (Olivier Lacan)
- [FIXED] Double calls to Rack::MiniProfilerRails.initialize! now raise an exception (Julik Tarkhanov)
- [FIXED] Add no-store header (George Mendoza)

## 0.9.1 - 2014-03-13 (Sam Saffron)
- [ADDED] Added back Ruby 1.8 support (thanks Malet)
- [IMPROVED] Amended Railstie so MiniProfiler can be launched with action view or action controller (Thanks Akira)
- [FIXED] Rails 3.0 support (thanks Zlatko)
- [FIXED] Possible XSS (admin only)
- [FIXED] Corrected Sql patching to avoid setting instance vars on nil which is frozen (thanks Andy, huoxito)

## 0.9.0.pre - 2013-12-05 (Sam Saffron)
- Bumped up version to reflect the stability of the project
- [IMPROVED] Reports for pp=profile-gc
- [IMPROVED] pp=flamegraph&flamegraph_sample_rate=1 , allow you to specify sampling rates

## 2013-09-17 (Ross Wilson)
- [IMPROVED] Instead of supressing all "/assets/" requests we now check the configured
  config.assets.prefix path since developers can rename the path to serve Asset Pipeline
  files from

## 0.1.31 - 2013-09-03
- [IMPROVED] Flamegraph now has much increased fidelity
- [REMOVED] Ripped out flamegraph so it can be isolated into a gem
- [REMOVED] Ripped out pp=sample it just was never really used

## 0.1.30 - 2013-08-30
- [ADDED] Rack::MiniProfiler.counter_method(klass,name) for injecting counters
- [FIXED] Counters were not shifting the table correctly

## 0.1.29 - 2013-08-20
- [ADDED] Implemented exception tracing using TracePoint see pp=trace-exceptions
- [FIXED] SOLR patching had an incorrect monkey patch

## 0.1.28 - 2013-07-30
- [FIXED] Diagnostics in abstract storage was raising not implemented killing
  ?pp=env and others
- [FIXED] SOLR xml unescaped by mistake

## 0.1.27 - 2013-06-26
- [ADDED] Rack::MiniProfiler.config.backtrace_threshold_ms
- [ADDED] jQuery 2.0 support
- [FIXED] Disabled global ajax handlers on MP requests @JP

## 0.1.26 - 2013-04-11
- [IMPROVED] Allow Rack::MiniProfilerRails.initialize!(Rails.application), for post config intialization

## 0.1.25 - 2013-04-08
- [FIXED] Missed flamegraph.html from build

## 0.1.24 - 2013-04-08
- [ADDED] Flame Graph Support see: http://samsaffron.com/archive/2013/03/19/flame-graphs-in-ruby-miniprofiler
- [ADDED] New toggle_shortcut and start_hidden options
- [ADDED] Mongoid support
- [ADDED] Rack::MiniProfiler.counter counter_name {}
- [ADDED] Net:HTTP profiling
- [ADDED] Ruby 1.8.7 support ... grrr
- [IMPROVED] More robust gc profiling
- [IMPROVED] Script tag initialized via data-attributes
- [IMPROVED] Allow usage of existing jQuery if its already loaded
- [IMPROVED] Pre-authorize to run in all non development? and production? modes
- [FIXED] AngularJS support and MooTools
- [FIXED] File retention leak in file_store
- [FIXED] HTML5 implicit <body> tags
- [FIXED] pp=enable

## 0.1.22 - 2012-09-20
- [FIXED] Permission issue in the gem

## 2012-09-17
- [IMPROVED] Allow rack-mini-profiler to be sourced from github
- [IMPROVED] Extracted the pp=profile-gc-time out, the object space profiler needs to disable gc

## 0.1.21 - 2012-09-17
- [ADDED] New MemchacedStore
- [ADDED] Rails 4 support

## 0.1.20 - 2012-09-12 (Sam Saffron)
- [ADDED] pp=profile-gc: allows you to profile the GC in Ruby 1.9.3

## 0.1.19 - 2012-09-10 (Sam Saffron)
- [FIXED] Compatibility issue with Ruby 1.8.7

## 0.1.17 - 2012-09-07 (Sam Saffron)
- [FIXED] pp=sample was bust unless stacktrace was installed

## 0.1.16 - 2012-09-05 (Sam Saffron)
- [IMPROVED] Implemented stacktrace properly
- [FIXED] Long standing problem specs (issue with memory store)
- [FIXED] Issue where profiler would be dumped when you got a 404 in production (and any time rails is bypassed)

## 0.1.15.pre - 2012-09-04 (Sam Saffron)
- [FIXED] Annoying bug where client settings were not sticking
- [FIXED] Long standing issue with Rack::ConditionalGet stopping MiniProfiler from working properly

## 0.1.13.pre - 2012-09-03 (Sam Saffron)
- [ADDED] Setting: config.backtrace_ignores = [] - an array of regexes that match on caller lines that get ignored
- [ADDED] Setting: config.backtrace_includes = [] - an array of regexes that get included in the trace by default
- [ADDED] pp=normal-backtrace to clear the "sticky" state
- [IMPROVED] Cleaned up the way client settings are stored
- [IMPROVED] Made pp=full-backtrace "sticky"
- [IMPROVED] Changed "pp=sample" to work with "caller" no need for stack trace gem
- [FIXED] pg gem prepared statements were not being logged correctly

## 0.1.12.pre - 2012-08-20 (Sam Saffron)
- [IMPROVED] Cap X-MiniProfiler-Ids at 10, otherwise the header can get killed

## 0.1.11.pre - 2012-08-10 (Sam Saffron)
- [ADDED] Basic prepared statement profiling for Postgres

## 0.1.10 - 2012-08-07 (Sam Saffron)
- [ADDED] Option to disable profiler for the current session (pp=disable / pp=enable)
- [ADDED] yajl compatability contributed by Sven Riedel

## 0.1.9 - 2012-07-30 (Sam Saffron)
- [IMPROVED] Made compliant with ancient versions of Rack (including Rack used by Rails2)
- [FIXED] Broken share link
- [FIXED] Crashes on startup (in MemoryStore and FileStore)
- [FIXED] Unicode issue

## 0.1.7 - 2012-07-18 (Sam Saffron)
- [ADDED] First Paint time for Google Chrome
- [FIXED] Ensure non Rails installs have mini profiler

## 0.1.6 - 2012-07-12 (Sam Saffron)
- [ADDED] Native PG and MySql2 interceptors, this gives way more accurate times
- [ADDED] some more client probing built in to rails
- [IMPROVED] Refactored context so its a proper class and not a hash
- [IMPROVED] More tests
- [FIXED] Incorrect profiling steps (was not indenting or measuring start time right

## 0.1.3 - 2012-07-09 (Sam Saffron)
- [ADDED] New option to display full backtraces pp=full-backtrace
- [IMPROVED] Cleaned up mechanism for profiling in production, all you need to do now
  is call Rack::MiniProfiler.authorize_request to get profiling working in
  production
- [IMPROVED] Cleaned up railties, got rid of the post authorize callback

## 0.1.1 - 2012-06-28 (Sam Saffron)
- [ADDED] Started change log
- [ADDED] added MemcacheStore
- [IMPROVED] Corrected profiler so it properly captures POST requests (was supressing non 200s)
- [IMPROVED] Amended Rack.MiniProfiler.config[:user_provider] to use ip addres for identity
- [IMPROVED] Supress all '/assets/' in the rails tie (makes debugging easier)
- [FIXED] Issue where unviewed missing ids never got cleared
- [FIXED] record_sql was mega buggy
