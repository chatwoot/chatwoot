## 6.4.3 / 2024-09-19

* Security
  * Discards any headers using underscores if the non-underscore version also exists. Without this, an attacker could overwrite values set by intermediate proxies (e.g. X-Forwarded-For). ([CVE-2024-45614](https://github.com/puma/puma/security/advisories/GHSA-9hf4-67fc-4vf4)/GHSA-9hf4-67fc-4vf4)

## 6.4.2 / 2024-01-08

* Security
  * Limit the size of chunk extensions. Without this limit, an attacker could cause unbounded resource (CPU, network bandwidth) consumption. ([GHSA-c2f4-cvqm-65w2](https://github.com/puma/puma/security/advisories/GHSA-c2f4-cvqm-65w2))

## 6.4.1 / 2024-01-03

* Bugfixes
  * DSL#warn_if_in_single_mode - fixup when workers set via CLI ([#3256])
  * Fix `idle-timeout` not working in cluster mode ([#3235], [#3228], [#3282], [#3283])
  * Fix worker 0 timing out during phased restart ([#3225], [#2786])
  * context_builder.rb - require openssl if verify_mode != 'none' ([#3179])
  * Make puma cluster process suitable as PID 1 ([#3255])
  * Improve Puma::NullIO consistency with real IO ([#3276])
  * extconf.rb - fixup to detect openssl info in Ruby build ([#3271], [#3266])
  * MiniSSL.java - set serialVersionUID, fix RaiseException deprecation ([#3270])
  * dsl.rb - fix warn_if_in_single_mode when WEB_CONCURRENCY is set ([#3265], [#3264])

* Maintenance
  * LOTS of test refactoring to make tests more stable and easier to write - thanks to @MSP-Greg!
  * Fix bug in tests re: TestPuma::HOST4 ([#3254])
  * Dockerfile for minimal repros: use Ruby 3.2, expect bundler installed ([#3245])
  * fix define_method calls, use Symbol parameter instead of String ([#3293])

* Docs
  * README.md - add the puma-acme plugin ([#3301])
  * Remove `--keep-file-descriptors` flag from systemd docs ([#3248])
  * Note symlink mechanism in restart documentation for hot restart ([#3298])

## 6.4.0 / 2023-09-21

* Features
  * on_thread_exit hook ([#2920])
  * on_thread_start_hook ([#3195])
  * Shutdown on idle ([#3209], [#2580])
  * New error message when control server port taken ([#3204])

* Refactor
  * Remove `Forwardable` dependency ([#3191], #3190)
  * Update URLMap Regexp usage for Ruby v3.3 ([#3165])

* Bugfixes
  * Bring the cert_pem: parameter into parity with the cert: parameter to ssl_bind. ([#3174])
  * Fix using control server with IPv6 host ([#3181])
  * control_cli.rb - add require_relative 'log_writer' ([#3187])
  * Fix cases where fallback Rack response wasn't sent to the client ([#3094])

## 6.3.1 / 2023-08-18

* Security
  * Address HTTP request smuggling vulnerabilities with zero-length Content Length header and trailer fields ([GHSA-68xg-gqqm-vgj8](https://github.com/puma/puma/security/advisories/GHSA-68xg-gqqm-vgj8))

## 6.3.0 / 2023-05-31

* Features
  * Add dsl method `supported_http_methods` ([#3106], [#3014])
  * Puma error responses no longer have any fingerprints to indicate Puma ([#3161], [#3037])
  * Support decryption of SSL key ([#3133], [#3132])

* Bugfixes
  * Don't send 103 early hints response when only invalid headers are used ([#3163])
  * Handle malformed request path ([#3155], [#3148])
  * Misc lib file fixes - trapping additional errors, CI helper ([#3129])
  * Fixup req form data file upload with "r\n" line endings ([#3137])
  * Restore rack 1.6 compatibility ([#3156])

* Refactor
  * const.rb - Update Puma::HTTP_STATUS_CODES ([#3162])
  * Clarify Reactor#initialize ([#3151])

## 6.2.2 / 2023-04-17

* Bugfixes
  * Fix Rack-related NameError by adding :: operator ([#3118], [#3117])

## 6.2.1 / 2023-03-31

* Bugfixes
  * Fix java 8 compatibility ([#3109], [#3108])
  * Always write io_buffer when in "enum bodies" branch. ([#3113], [#3112])
  * Fix warn_if_in_single_mode incorrect message ([#3111])

## 6.2.0 / 2023-03-29

* Features
  * Ability to supply a custom logger ([#2770], [#2511])
  * Warn when clustered-only hooks are defined in single mode ([#3089])
  * Adds the on_booted event ([#2709])

* Bugfixes
  * Loggers - internal_write - catch Errno::EINVAL ([#3091])
  * commonlogger.rb - fix HIJACK time format, use constants, not strings ([#3074])
  * Fixed some edge cases regarding request hijacking ([#3072])

## 6.1.1 / 2023-02-28

* Bugfixes
  * We no longer try to use the systemd plugin for JRuby ([#3079])
  * Allow ::Rack::Handler::Puma.run to work regardless of whether Rack/Rackup are loaded ([#3080])

## 6.1.0 / 2023-02-12

* Features
  * WebSocket support via partial hijack ([#3058], [#3007])
  * Add built-in systemd notify support ([#3011])
  * Periodically send status to systemd ([#3006], [#2604])
  * Introduce the ability to return 413: payload too large for requests ([#3040])
  * Log loaded extensions when `PUMA_DEBUG` is set ([#3036], [#3020])

* Bugfixes
  * Fix issue with rack 3 compatibility re: rackup ([#3061], [#3057])
  * Allow setting TCP low_latency with SSL listener ([#3065])

* Performance
  * Reduce memory usage for large file uploads ([#3062])

## 6.0.2 / 2023-01-01

* Refactor
  * Remove use of etc and time gems in Puma ([#3035], [#3033])
  * Refactor const.rb - freeze ([#3016])

## 6.0.1 / 2022-12-20

* Bugfixes
  * Handle waking up a closed selector in Reactor#add ([#3005])
  * Fixup response processing, enumerable bodies ([#3004], [#3000])
  * Correctly close app body for all code paths ([#3002], [#2999])
* Refactor
  * Add IOBuffer to Client, remove from ThreadPool thread instances ([#3013])

## 6.0.0 / 2022-10-14

* Breaking Changes
  * Dropping Ruby 2.2 and 2.3 support (now 2.4+) ([#2919])
  * Remote_addr functionality has changed ([#2652], [#2653])
  * No longer supporting Java 1.7 or below (JRuby 9.1 was the last release to support this) ([#2849])
  * Remove nakayoshi GC ([#2933], [#2925])
  * wait_for_less_busy_worker is now default on ([#2940])
  * Prefix all environment variables with `PUMA_` ([#2924], [#2853])
  * Removed some constants ([#2957], [#2958], [#2959], [#2960])
  * The following classes are now part of Puma's private API: `Client`, `Cluster::Worker`, `Cluster::Worker`, `HandleRequest`. ([#2988])
  * Configuration constants like `DefaultRackup` removed ([#2928])
  * Extracted `LogWriter` from `Events` ([#2798])
  * Only accept the standard 8 HTTP methods, others rejected with 501. ([#2932])

* Features
  * Increase throughput on large (100kb+) response bodies by 3-10x ([#2896], [#2892])
  * Increase throughput on file responses ([#2923])
  * Add support for streaming bodies in Rack. ([#2740])
  * Allow OpenSSL session reuse via a 'reuse' ssl_bind method or bind string query parameter ([#2845])
  * Allow `run_hooks` to pass a hash to blocks for use later ([#2917], [#2915])
  * Allow using `preload_app!` with `fork_worker` ([#2907])
  * Support request_body_wait metric with higher precision ([#2953])
  * Allow header values to be arrays (Rack 3) ([#2936], [#2931])
  * Export Puma/Ruby versions in /stats ([#2875])
  * Allow configuring request uri max length & request path max length ([#2840])
  * Add a couple of public accessors ([#2774])
  * Log entire backtrace when worker start fails ([#2891])
  * [jruby] Enable TLSv1.3 support ([#2886])
  * [jruby] support setting TLS protocols + rename ssl_cipher_list ([#2899])
  * [jruby] Support a truststore option ([#2849], [#2904], [#2884])

* Bugfixes
  * Load the configuration before passing it to the binder ([#2897])
  * Do not raise error raised on HTTP methods we don't recognize or support, like CONNECT ([#2932], [#1441])
  * Fixed a memory leak when creating a new SSL listener ([#2956])

* Refactor
  * log_writer.rb - add internal_write method ([#2888])
  * Extract prune_bundler code into it's own class. ([#2797])
  * Refactor Launcher#run to increase readability (no logic change) ([#2795])
  * Ruby 3.2 will have native IO#wait_* methods, don't require io/wait ([#2903])
  * Various internal API refactorings ([#2942], [#2921], [#2922], [#2955])

## 5.6.9 / 2024-09-19

* Security
  * Discards any headers using underscores if the non-underscore version also exists. Without this, an attacker could overwrite values set by intermediate proxies (e.g. X-Forwarded-For). ([CVE-2024-45614](https://github.com/puma/puma/security/advisories/GHSA-9hf4-67fc-4vf4)/GHSA-9hf4-67fc-4vf4)

## 5.6.8 / 2024-01-08

* Security
  * Limit the size of chunk extensions. Without this limit, an attacker could cause unbounded resource (CPU, network bandwidth) consumption. ([GHSA-c2f4-cvqm-65w2](https://github.com/puma/puma/security/advisories/GHSA-c2f4-cvqm-65w2))

## 5.6.7 / 2023-08-18

* Security
  * Address HTTP request smuggling vulnerabilities with zero-length Content Length header and trailer fields ([GHSA-68xg-gqqm-vgj8](https://github.com/puma/puma/security/advisories/GHSA-68xg-gqqm-vgj8))

## 5.6.6 / 2023-06-21

* Bugfix
  * Prevent loading with rack 3 ([#3166])

## 5.6.5 / 2022-08-23

* Feature
  * Puma::ControlCLI - allow refork command to be sent as a request ([#2868], [#2866])

* Bugfixes
  * NullIO#closed should return false ([#2883])
  * [jruby] Fix TLS verification hang ([#2890], [#2729])
  * extconf.rb - don't use pkg_config('openssl') if '--with-openssl-dir' is used ([#2885], [#2839])
  * MiniSSL - detect SSL_CTX_set_dh_auto ([#2864], [#2863])
  * Fix rack.after_reply exceptions breaking connections ([#2861], [#2856])
  * Escape SSL cert and filenames ([#2855])
  * Fail hard if SSL certs or keys are invalid ([#2848])
  * Fail hard if SSL certs or keys cannot be read by user ([#2847])
  * Fix build with Opaque DH in LibreSSL 3.5. ([#2838])
  * Pre-existing socket file removed when TERM is issued after USR2 (if puma is running in cluster mode) ([#2817])
  * Fix Puma::StateFile#load incompatibility ([#2810])

## 5.6.4 / 2022-03-30

* Security
  * Close several HTTP Request Smuggling exploits (CVE-2022-24790)

## 5.6.2 / 2022-02-11

* Bugfix/Security
  * Response body will always be `close`d. (GHSA-rmj8-8hhh-gv5h, related to [#2809])

## 5.6.1 / 2022-01-26

* Bugfixes
  * Reverted a commit which appeared to be causing occasional blank header values ([#2809])

## 5.6.0 / 2022-01-25

* Features
  * Support `localhost` integration in `ssl_bind` ([#2764], [#2708])
  * Allow backlog parameter to be set with ssl_bind DSL ([#2780])
  * Remove yaml (psych) requirement in StateFile ([#2784])
  * Allow culling of oldest workers, previously was only youngest ([#2773], [#2794])
  * Add worker_check_interval configuration option ([#2759])
  * Always send lowlevel_error response to client ([#2731], [#2341])
  * Support for cert_pem and key_pem with ssl_bind DSL ([#2728])

* Bugfixes
  * Keep thread names under 15 characters, prevents breakage on some OSes ([#2733])
  * Fix two 'old-style-definition' compile warning ([#2807], [#2806])
  * Log environment correctly using option value ([#2799])
  * Fix warning from Ruby master (will be 3.2.0) ([#2785])
  * extconf.rb - fix openssl with old Windows builds ([#2757])
  * server.rb - rescue handling (`Errno::EBADF`) for `@notify.close` ([#2745])

* Refactor
  * server.rb - refactor code using @options[:remote_address] ([#2742])
  * [jruby] a couple refactorings - avoid copy-ing bytes ([#2730])

## 5.5.2 / 2021-10-12

* Bugfixes
  * Allow UTF-8 in HTTP header values

## 5.5.1 / 2021-10-12

* Feature (added as mistake - we don't normally do this on bugfix releases, sorry!)
  * Allow setting APP_ENV in preference to RACK_ENV or RAILS_ENV ([#2702])

* Security
  * Do not allow LF as a line ending in a header (CVE-2021-41136)

## 5.5.0 / 2021-09-19

* Features
  * Automatic SSL certificate provisioning for localhost, via localhost gem ([#2610], [#2257])
  * add support for the PROXY protocol (v1 only) ([#2654], [#2651])
  * Add a semantic CLI option for no config file ([#2689])

* Bugfixes
  * More elaborate exception handling - lets some dead pumas die. ([#2700], [#2699])
  * allow multiple after_worker_fork hooks ([#2690])
  * Preserve BUNDLE_APP_CONFIG on worker fork ([#2688], [#2687])

* Performance
  * Fix performance of server-side SSL connection close. ([#2675])

## 5.4.0 / 2021-07-28

* Features
  * Better/expanded names for threadpool threads ([#2657])
  * Allow pkg_config for OpenSSL ([#2648], [#1412])
  * Add `rack_url_scheme` to Puma::DSL, allows setting of `rack.url_scheme` header ([#2586], [#2569])

* Bugfixes
  * `Binder#parse` - allow for symlinked unix path, add create_activated_fds debug ENV ([#2643], [#2638])
  * Fix deprecation warning: minissl.c - Use Random.bytes if available ([#2642])
  * Client certificates: set session id context while creating SSLContext ([#2633])
  * Fix deadlock issue in thread pool ([#2656])

* Refactor
  * Replace `IO.select` with `IO#wait_*` when checking a single IO ([#2666])

## 5.3.2 / 2021-05-21

* Bugfixes
  * Gracefully handle Rack not accepting CLI options ([#2630], [#2626])
  * Fix sigterm misbehavior ([#2629])
  * Improvements to keepalive-connection shedding ([#2628])

## 5.3.1 / 2021-05-11

* Security
  * Close keepalive connections after the maximum number of fast inlined requests (CVE-2021-29509) ([#2625])

## 5.3.0 / 2021-05-07

* Features
  * Add support for Linux's abstract sockets ([#2564], [#2526])
  * Add debug to worker timeout and startup ([#2559], [#2528])
  * Print warning when running one-worker cluster ([#2565], [#2534])
  * Don't close systemd activated socket on pumactl restart ([#2563], [#2504])

* Bugfixes
  * systemd - fix event firing ([#2591], [#2572])
  * Immediately unlink temporary files ([#2613])
  * Improve parsing of HTTP_HOST header ([#2605], [#2584])
  * Handle fatal error that has no backtrace ([#2607], [#2552])
  * Fix timing out requests too early ([#2606], [#2574])
  * Handle segfault in Ruby 2.6.6 on thread-locals ([#2567], [#2566])
  * Server#closed_socket? - parameter may be a MiniSSL::Socket ([#2596])
  * Define UNPACK_TCP_STATE_FROM_TCP_INFO in the right place ([#2588], [#2556])
  * request.rb - fix chunked assembly for ascii incompatible encodings, add test ([#2585], [#2583])

* Performance
  * Reset peerip only if remote_addr_header is set ([#2609])
  * Reduce puma_parser struct size ([#2590])

* Refactor
  * Refactor drain on shutdown ([#2600])
  * Micro optimisations in `wait_for_less_busy_worker` feature ([#2579])
  * Lots of test fixes

## 5.2.2 / 2021-02-22

* Bugfixes
  * Add `#flush` and `#sync` methods to `Puma::NullIO`  ([#2553])
  * Restore `sync=true` on `STDOUT` and `STDERR` streams ([#2557])

## 5.2.1 / 2021-02-05

* Bugfixes
  * Fix TCP cork/uncork operations to work with ssl clients ([#2550])
  * Require rack/common_logger explicitly if :verbose is true ([#2547])
  * MiniSSL::Socket#write - use data.byteslice(wrote..-1) ([#2543])
  * Set `@env[CONTENT_LENGTH]` value as string. ([#2549])

## 5.2.0 / 2021-01-27

* Features
  * 10x latency improvement for MRI on ssl connections by reducing overhead ([#2519])
  * Add option to specify the desired IO selector backend for libev ([#2522])
  * Add ability to set OpenSSL verification flags (MRI only) ([#2490])
  * Uses `flush` after writing messages to avoid mutating $stdout and $stderr using `sync=true` ([#2486])

* Bugfixes
  * MiniSSL - Update dhparam to 2048 bit for use with SSL_CTX_set_tmp_dh ([#2535])
  * Change 'Goodbye!' message to be output after listeners are closed ([#2529])
  * Fix ssl bind logging with 0.0.0.0 and localhost ([#2533])
  * Fix compiler warnings, but skipped warnings related to ragel state machine generated code ([#1953])
  * Fix phased restart errors related to nio4r gem when using the Puma control server ([#2516])
  * Add `#string` method to `Puma::NullIO` ([#2520])
  * Fix binding via Rack handler to IPv6 addresses ([#2521])

* Refactor
  * Refactor MiniSSL::Context on MRI, fix MiniSSL::Socket#write ([#2519])
  * Remove `Server#read_body` ([#2531])
  * Fail build if compiling extensions raises warnings on GH Actions, configurable via `MAKE_WARNINGS_INTO_ERRORS` ([#1953])

## 5.1.1 / 2020-12-10

* Bugfixes
  * Fix over eager matching against banned header names ([#2510])

## 5.1.0 / 2020-11-30

* Features
  * Phased restart availability is now always logged, even if it is not available.
  * Prints the loaded configuration if the environment variable `PUMA_LOG_CONFIG` is present ([#2472])
  * Integrate with systemd's watchdog and notification features ([#2438])
  * Adds max_fast_inline as a configuration option for the Server object ([#2406])
  * You can now fork workers from worker 0 using SIGURG w/o fork_worker enabled [#2449]
  * Add option to bind to systemd activated sockets ([#2362])
  * Add compile option to change the `QUERY_STRING` max length ([#2485])

* Bugfixes
  * Fix JRuby handling in Puma::DSL#ssl_bind ([#2489])
  * control_cli.rb - all normal output should be to @stdout ([#2487])
  * Catch 'Error in reactor loop escaped: mode not supported for this object: r' ([#2477])
  * Ignore Rails' reaper thread (and any thread marked forksafe) for warning ([#2475])
  * Ignore illegal (by Rack spec) response header ([#2439])
  * Close idle connections immediately on shutdown ([#2460])
  * Fix some instances of phased restart errors related to the `json` gem ([#2473])
  * Remove use of `json` gem to fix phased restart errors ([#2479])
  * Fix grouping regexp of ILLEGAL_HEADER_KEY_REGEX ([#2495])

## 5.0.4 / 2020-10-27

* Bugfixes
  * Pass preloaded application into new workers if available when using `preload_app` ([#2461], [#2454])

## 5.0.3 / 2020-10-26

* Bugfixes
  * Add Client#io_ok?, check before Reactor#register ([#2432])
  * Fix hang on shutdown in refork ([#2442])
  * Fix `Bundler::GemNotFound` errors for `nio4r` gem during phased restarts ([#2427], [#2018])
  * Server run thread safety fix ([#2435])
  * Fire `on_booted` after server starts ([#2431], [#2212])
  * Cleanup daemonization in rc.d script ([#2409])

* Refactor
  * Remove accept_nonblock.rb, add test_integration_ssl.rb ([#2448])
  * Refactor status.rb - dry it up a bit ([#2450])
  * Extract req/resp methods to new request.rb from server.rb ([#2419])
  * Refactor Reactor and Client request buffering ([#2279])
  * client.rb - remove JRuby specific 'finish' code ([#2412])
  * Consolidate fast_write calls in Server, extract early_hints assembly ([#2405])
  * Remove upstart from docs ([#2408])
  * Extract worker process into separate class ([#2374])
  * Consolidate option handling in Server, Server small refactors, doc changes ([#2389])

## 5.0.2 / 2020-09-28

* Bugfixes
  * Reverted API changes to Server.

## 5.0.1 / 2020-09-28

* Bugfixes
  * Fix LoadError in CentOS 8 ([#2381])
  * Better error handling during force shutdown ([#2271])
  * Prevent connections from entering Reactor after shutdown begins ([#2377])
  * Fix error backtrace debug logging && Do not log request dump if it is not parsed ([#2376])
  * Split TCP_CORK and TCP_INFO ([#2372])
  * Do not log EOFError when a client connection is closed without write ([#2384])

* Refactor
  * Change Events#ssl_error signature from (error, peeraddr, peercert) to (error, ssl_socket) ([#2375])
  * Consolidate option handling in Server, Server small refactors, doc chang ([#2373])

## 5.0.0 / 2020-09-17

* Features
  * Allow compiling without OpenSSL and dynamically load files needed for SSL, add 'no ssl' CI ([#2305])
  * EXPERIMENTAL: Add `fork_worker` option and `refork` command for reduced memory usage by forking from a worker process instead of the master process. ([#2099])
  * EXPERIMENTAL: Added `wait_for_less_busy_worker` config. This may reduce latency on MRI through inserting a small delay before re-listening on the socket if worker is busy ([#2079]).
  * EXPERIMENTAL: Added `nakayoshi_fork` option. Reduce memory usage in preloaded cluster-mode apps by GCing before fork and compacting, where available. ([#2093], [#2256])
  * Added pumactl `thread-backtraces` command to print thread backtraces ([#2054])
  * Added incrementing `requests_count` to `Puma.stats`. ([#2106])
  * Increased maximum URI path length from 2048 to 8192 bytes ([#2167], [#2344])
  * `lowlevel_error_handler` is now called during a forced threadpool shutdown, and if a callable with 3 arguments is set, we now also pass the status code ([#2203])
  * Faster phased restart and worker timeout ([#2220])
  * Added `state_permission` to config DSL to set state file permissions ([#2238])
  * Added `Puma.stats_hash`, which returns a stats in Hash instead of a JSON string ([#2086], [#2253])
  * `rack.multithread` and `rack.multiprocess` now dynamically resolved by `max_thread` and `workers` respectively ([#2288])

* Deprecations, Removals and Breaking API Changes
  * `--control` has been removed. Use `--control-url` ([#1487])
  * `worker_directory` has been removed. Use `directory`.
  * min_threads now set by environment variables PUMA_MIN_THREADS and MIN_THREADS. ([#2143])
  * max_threads now set by environment variables PUMA_MAX_THREADS and MAX_THREADS. ([#2143])
  * max_threads default to 5 in MRI or 16 for all other interpreters. ([#2143])
  * `preload_app!` is on by default if number of workers > 1 and set via `WEB_CONCURRENCY` ([#2143])
  * Puma::Plugin.workers_supported? has been removed. Use Puma.forkable? instead. ([#2143])
  * `tcp_mode` has been removed without replacement. ([#2169])
  * Daemonization has been removed without replacement. ([#2170])
  * Changed #connected_port to #connected_ports ([#2076])
  * Configuration: `environment` is read from `RAILS_ENV`, if `RACK_ENV` can't be found ([#2022])
  * Log binding on http:// for TCP bindings to make it clickable  ([#2300])

* Bugfixes
  * Fix JSON loading issues on phased-restarts ([#2269])
  * Improve shutdown reliability ([#2312], [#2338])
  * Close client http connections made to an ssl server with TLSv1.3 ([#2116])
  * Do not set user_config to quiet by default to allow for file config ([#2074])
  * Always close SSL connection in Puma::ControlCLI ([#2211])
  * Windows update extconf.rb for use with ssp and varied Ruby/MSYS2 combinations ([#2069])
  * Ensure control server Unix socket is closed on shutdown ([#2112])
  * Preserve `BUNDLE_GEMFILE` env var when using `prune_bundler` ([#1893])
  * Send 408 request timeout even when queue requests is disabled ([#2119])
  * Rescue IO::WaitReadable instead of EAGAIN for blocking read ([#2121])
  * Ensure `BUNDLE_GEMFILE` is unspecified in workers if unspecified in master when using `prune_bundler` ([#2154])
  * Rescue and log exceptions in hooks defined by users (on_worker_boot, after_worker_fork etc) ([#1551])
  * Read directly from the socket in #read_and_drop to avoid raising further SSL errors ([#2198])
  * Set `Connection: closed` header when queue requests is disabled ([#2216])
  * Pass queued requests to thread pool on server shutdown ([#2122])
  * Fixed a few minor concurrency bugs in ThreadPool that may have affected non-GVL Rubies ([#2220])
  * Fix `out_of_band` hook never executed if the number of worker threads is > 1 ([#2177])
  * Fix ThreadPool#shutdown timeout accuracy ([#2221])
  * Fix `UserFileDefaultOptions#fetch` to properly use `default` ([#2233])
  * Improvements to `out_of_band` hook ([#2234])
  * Prefer the rackup file specified by the CLI ([#2225])
  * Fix for spawning subprocesses with fork_worker option ([#2267])
  * Set `CONTENT_LENGTH` for chunked requests ([#2287])
  * JRuby - Add Puma::MiniSSL::Engine#init? and #teardown methods, run all SSL tests ([#2317])
  * Improve shutdown reliability ([#2312])
  * Resolve issue with threadpool waiting counter decrement when thread is killed
  * Constrain rake-compiler version to 0.9.4 to fix `ClassNotFound` exception when using MiniSSL with Java8.
  * Fix recursive `prune_bundler` ([#2319]).
  * Ensure that TCP_CORK is usable
  * Fix corner case when request body is chunked ([#2326])
  * Fix filehandle leak in MiniSSL ([#2299])

* Refactor
  * Remove unused loader argument from Plugin initializer ([#2095])
  * Simplify `Configuration.random_token` and remove insecure fallback ([#2102])
  * Simplify `Runner#start_control` URL parsing ([#2111])
  * Removed the IOBuffer extension and replaced with Ruby ([#1980])
  * Update `Rack::Handler::Puma.run` to use `**options` ([#2189])
  * ThreadPool concurrency refactoring ([#2220])
  * JSON parse cluster worker stats instead of regex ([#2124])
  * Support parallel tests in verbose progress reporting ([#2223])
  * Refactor error handling in server accept loop ([#2239])

## 4.3.12 / 2022-03-30

* Security
  * Close several HTTP Request Smuggling exploits (CVE-2022-24790)

## 4.3.11 / 2022-02-11

* Security
  * Always close the response body (GHSA-rmj8-8hhh-gv5h)

## 4.3.10 / 2021-10-12

* Bugfixes
  * Allow UTF-8 in HTTP header values

## 4.3.9 / 2021-10-12

* Security
  * Do not allow LF as a line ending in a header (CVE-2021-41136)

## 4.3.8 / 2021-05-11

* Security
  * Close keepalive connections after the maximum number of fast inlined requests (CVE-2021-29509) ([#2625])

## 4.3.7 / 2020-11-30

* Bugfixes
  * Backport set CONTENT_LENGTH for chunked requests (Originally: [#2287], backport: [#2496])

## 4.3.6 / 2020-09-05

* Bugfixes
  * Explicitly include ctype.h to fix compilation warning and build error on macOS with Xcode 12 ([#2304])
  * Don't require json at boot ([#2269])

## 4.3.4/4.3.5 and 3.12.5/3.12.6 / 2020-05-22

Each patchlevel release contains a separate security fix. We recommend simply upgrading to 4.3.5/3.12.6.

* Security
  * Fix: Fixed two separate HTTP smuggling vulnerabilities that used the Transfer-Encoding header. CVE-2020-11076 and CVE-2020-11077.

## 4.3.3 and 3.12.4 / 2020-02-28

* Bugfixes
  * Fix: Fixes a problem where we weren't splitting headers correctly on newlines ([#2132])
* Security
  * Fix: Prevent HTTP Response splitting via CR in early hints. CVE-2020-5249.

## 4.3.2 and 3.12.3 / 2020-02-27 (YANKED)

* Security
  * Fix: Prevent HTTP Response splitting via CR/LF in header values. CVE-2020-5247.

## 4.3.1 and 3.12.2 / 2019-12-05

* Security
  * Fix: a poorly-behaved client could use keepalive requests to monopolize Puma's reactor and create a denial of service attack. CVE-2019-16770.

## 4.3.0 / 2019-11-07

* Features
  * Strip whitespace at end of HTTP headers ([#2010])
  * Optimize HTTP parser for JRuby ([#2012])
  * Add SSL support for the control app and cli ([#2046], [#2052])

* Bugfixes
  * Fix Errno::EINVAL when SSL is enabled and browser rejects cert ([#1564])
  * Fix pumactl defaulting puma to development if an environment was not specified ([#2035])
  * Fix closing file stream when reading pid from pidfile ([#2048])
  * Fix a typo in configuration option `--extra_runtime_dependencies` ([#2050])

## 4.2.1 / 2019-10-07

* 3 bugfixes
  * Fix socket activation of systemd (pre-existing) unix binder files ([#1842], [#1988])
  * Deal with multiple calls to bind correctly ([#1986], [#1994], [#2006])
  * Accepts symbols for `verify_mode` ([#1222])

## 4.2.0 / 2019-09-23

* 6 features
  * Pumactl has a new -e environment option and reads `config/puma/<environment>.rb` config files ([#1885])
  * Semicolons are now allowed in URL paths (MRI only), useful for Angular or Redmine ([#1934])
  * Allow extra dependencies to be defined when using prune_bundler ([#1105])
  * Puma now reports the correct port when binding to port 0, also reports other listeners when binding to localhost ([#1786])
  * Sending SIGINFO to any Puma worker now prints currently active threads and their backtraces ([#1320])
  * Puma threads all now have their name set on Ruby 2.3+ ([#1968])
* 4 bugfixes
  * Fix some misbehavior with phased restart and externally SIGTERMed workers ([#1908], [#1952])
  * Fix socket closing on error ([#1941])
  * Removed unnecessary SIGINT trap for JRuby that caused some race conditions ([#1961])
  * Fix socket files being left around after process stopped ([#1970])
* Absolutely thousands of lines of test improvements and fixes thanks to @MSP-Greg

## 4.1.1 / 2019-09-05

* 3 bugfixes
  * Revert our attempt to not dup STDOUT/STDERR ([#1946])
  * Fix socket close on error ([#1941])
  * Fix workers not shutting down correctly ([#1908])

## 4.1.0 / 2019-08-08

* 4 features
  * Add REQUEST_PATH on parse error message ([#1831])
  * You can now easily add custom log formatters with the `log_formatter` config option ([#1816])
  * Puma.stats now provides process start times ([#1844])
  * Add support for disabling TLSv1.1 ([#1836])

* 7 bugfixes
  * Fix issue where Puma was creating zombie process entries ([#1887])
  * Fix bugs with line-endings and chunked encoding ([#1812])
  * RACK_URL_SCHEME is now set correctly in all conditions ([#1491])
  * We no longer mutate global STDOUT/STDERR, particularly the sync setting ([#1837])
  * SSL read_nonblock no longer blocks ([#1857])
  * Swallow connection errors when sending early hints ([#1822])
  * Backtrace no longer dumped when invalid pumactl commands are run ([#1863])

* 5 other
  * Avoid casting worker_timeout twice ([#1838])
  * Removed a call to private that wasn't doing anything ([#1882])
  * README, Rakefile, docs and test cleanups ([#1848], [#1847], [#1846], [#1853], #1859, [#1850], [#1866], [#1870], [#1872], [#1833], [#1888])
  * Puma.io has proper documentation now (https://puma.io/puma/)
  * Added the Contributor Covenant CoC

* 1 known issue
  * Some users are still experiencing issues surrounding socket activation and Unix sockets ([#1842])

## 4.0.1 / 2019-07-11

* 2 bugfixes
  * Fix socket removed after reload - should fix problems with systemd socket activation. ([#1829])
  * Add extconf tests for DTLS_method & TLS_server_method, use in minissl.rb. Should fix "undefined symbol: DTLS_method" when compiling against old OpenSSL versions. ([#1832])
* 1 other
  * Removed unnecessary RUBY_VERSION checks. ([#1827])

## 4.0.0 / 2019-06-25

* 9 features
  * Add support for disabling TLSv1.0 ([#1562])
  * Request body read time metric ([#1569])
  * Add out_of_band hook ([#1648])
  * Re-implement (native) IOBuffer for JRuby ([#1691])
  * Min worker timeout ([#1716])
  * Add option to suppress SignalException on SIGTERM ([#1690])
  * Allow mutual TLS CA to be set using `ssl_bind` DSL ([#1689])
  * Reactor now uses nio4r instead of `select` ([#1728])
  * Add status to pumactl with pidfile ([#1824])

* 10 bugfixes
  * Do not accept new requests on shutdown ([#1685], [#1808])
  * Fix 3 corner cases when request body is chunked ([#1508])
  * Change pid existence check's condition branches ([#1650])
  * Don't call .stop on a server that doesn't exist ([#1655])
  * Implemented NID_X9_62_prime256v1 (P-256) curve over P-521 ([#1671])
  * Fix @notify.close can't modify frozen IOError (RuntimeError) ([#1583])
  * Fix Java 8 support ([#1773])
  * Fix error `uninitialized constant Puma::Cluster` ([#1731])
  * Fix `not_token` being able to be set to true ([#1803])
  * Fix "Hang on SIGTERM with ruby 2.6 in clustered mode" (PR [#1741], [#1674], [#1720], [#1730], [#1755])

## 3.12.1 / 2019-03-19

* 1 features
  * Internal strings are frozen ([#1649])
* 3 bugfixes
  * Fix chunked ending check ([#1607])
  * Rack handler should use provided default host ([#1700])
  * Better support for detecting runtimes that support `fork` ([#1630])

## 3.12.0 / 2018-07-13

* 5 features:
  * You can now specify which SSL ciphers the server should support, default is unchanged ([#1478])
  * The setting for Puma's `max_threads` is now in `Puma.stats` ([#1604])
  * Pool capacity is now in `Puma.stats` ([#1579])
  * Installs restricted to Ruby 2.2+ ([#1506])
  * `--control` is now deprecated in favor of `--control-url` ([#1487])

* 2 bugfixes:
  * Workers will no longer accept more web requests than they have capacity to process. This prevents an issue where one worker would accept lots of requests while starving other workers ([#1563])
  * In a test env puma now emits the stack on an exception ([#1557])

## 3.11.4 / 2018-04-12

* 2 features:
  * Manage puma as a service using rc.d ([#1529])
  * Server stats are now available from a top level method ([#1532])
* 5 bugfixes:
  * Fix parsing CLI options ([#1482])
  * Order of stderr and stdout is made before redirecting to a log file ([#1511])
  * Init.d fix of `ps -p` to check if pid exists ([#1545])
  * Early hints bugfix ([#1550])
  * Purge interrupt queue when closing socket fails ([#1553])

## 3.11.3 / 2018-03-05

* 3 bugfixes:
  * Add closed? to MiniSSL::Socket for use in reactor ([#1510])
  * Handle EOFError at the toplevel of the server threads ([#1524]) ([#1507])
  * Deal with zero sized bodies when using SSL ([#1483])

## 3.11.2 / 2018-01-19

* 1 bugfix:
  * Deal with read\_nonblock returning nil early

## 3.11.1 / 2018-01-18

* 1 bugfix:
  * Handle read\_nonblock returning nil when the socket close ([#1502])

## 3.11.0 / 2017-11-20

* 2 features:
  * HTTP 103 Early Hints ([#1403])
  * 421/451 status codes now have correct status messages attached ([#1435])

* 9 bugfixes:
  * Environment config files (/config/puma/<ENV>.rb) load correctly ([#1340])
  * Specify windows dependencies correctly ([#1434], [#1436])
  * puma/events required in test helper ([#1418])
  * Correct control CLI's option help text ([#1416])
  * Remove a warning for unused variable in mini_ssl ([#1409])
  * Correct pumactl docs argument ordering ([#1427])
  * Fix an uninitialized variable warning in server.rb ([#1430])
  * Fix docs typo/error in Launcher init ([#1429])
  * Deal with leading spaces in RUBYOPT ([#1455])

* 2 other:
  * Add docs about internals ([#1425], [#1452])
  * Tons of test fixes from @MSP-Greg ([#1439], [#1442], [#1464])

## 3.10.0 / 2017-08-17

* 3 features:
  * The status server has a new /gc and /gc-status command. ([#1384])
  * The persistent and first data timeouts are now configurable ([#1111])
  * Implemented RFC 2324 ([#1392])

* 12 bugfixes:
  * Not really a Puma bug, but @NickolasVashchenko created a gem to workaround a Ruby bug that some users of Puma may be experiencing. See README for more. ([#1347])
  * Fix hangups with SSL and persistent connections. ([#1334])
  * Fix Rails double-binding to a port ([#1383])
  * Fix incorrect thread names ([#1368])
  * Fix issues with /etc/hosts and JRuby where localhost addresses were not correct. ([#1318])
  * Fix compatibility with RUBYOPT="--enable-frozen-string-literal" ([#1376])
  * Fixed some compiler warnings ([#1388])
  * We actually run the integration tests in CI now ([#1390])
  * No longer shipping unnecessary directories in the gemfile ([#1391])
  * If RUBYOPT is nil, we no longer blow up on restart. ([#1385])
  * Correct response to SIGINT ([#1377])
  * Proper exit code returned when we receive a TERM signal ([#1337])

* 3 refactors:
  * Various test improvements from @grosser
  * Rubocop ([#1325])
  * Hoe has been removed ([#1395])

* 1 known issue:
  * Socket activation doesn't work in JRuby. Their fault, not ours. ([#1367])

## 3.9.1 / 2017-06-03

* 2 bugfixes:
  * Fixed compatibility with older Bundler versions ([#1314])
  * Some internal test/development cleanup ([#1311], [#1313])

## 3.9.0 / 2017-06-01

* 2 features:
  * The ENV is now reset to its original values when Puma restarts via USR1/USR2 ([#1260]) (MRI only, no JRuby support)
  * Puma will no longer accept more clients than the maximum number of threads. ([#1278])

* 9 bugfixes:
  * Reduce information leakage by preventing HTTP parse errors from writing environment hashes to STDERR ([#1306])
  * Fix SSL/WebSocket compatibility ([#1274])
  * HTTP headers with empty values are no longer omitted from responses. ([#1261])
  * Fix a Rack env key which was set to nil. ([#1259])
  * peercert has been implemented for JRuby ([#1248])
  * Fix port settings when using rails s ([#1277], [#1290])
  * Fix compat w/LibreSSL ([#1285])
  * Fix restarting Puma w/symlinks and a new Gemfile ([#1282])
  * Replace Dir.exists? with Dir.exist? ([#1294])

* 1 known issue:
  * A bug in MRI 2.2+ can result in IOError: stream closed. See [#1206]. This issue has existed since at least Puma 3.6, and probably further back.

* 1 refactor:
  * Lots of test fixups from @grosser.

## 3.8.2 / 2017-03-14

* 1 bugfix:
  * Deal with getsockopt with TCP\_INFO failing for sockets that say they're TCP but aren't really. ([#1241])

## 3.8.1 / 2017-03-10

* 1 bugfix:
  * Remove method call to method that no longer exists ([#1239])

## 3.8.0 / 2017-03-09

* 2 bugfixes:
  * Port from rack handler does not take precedence over config file in Rails 5.1.0.beta2+ and 5.0.1.rc3+ ([#1234])
  * The `tmp/restart.txt` plugin no longer restricts the user from running more than one server from the same folder at a time ([#1226])

* 1 feature:
  * Closed clients are aborted to save capacity ([#1227])

* 1 refactor:
  * Bundler is no longer a dependency from tests ([#1213])

## 3.7.1 / 2017-02-20

* 2 bugfixes:
  * Fix typo which blew up MiniSSL ([#1182])
  * Stop overriding command-line options with the config file ([#1203])

## 3.7.0 / 2017-01-04

* 6 minor features:
  * Allow rack handler to accept ssl host. ([#1129])
  * Refactor TTOU processing. TTOU now handles multiple signals at once. ([#1165])
  * Pickup any remaining chunk data as the next request.
  * Prevent short term thread churn - increased auto trim default to 30 seconds.
  * Raise error when `stdout` or `stderr` is not writable. ([#1175])
  * Add Rack 2.0 support to gemspec. ([#1068])

* 5 refactors:
  * Compare host and server name only once per call. ([#1091])
  * Minor refactor on Thread pool ([#1088])
  * Removed a ton of unused constants, variables and files.
  * Use MRI macros when allocating heap memory
  * Use hooks for on\_booted event. ([#1160])

* 14 bugfixes:
  * Add eof? method to NullIO? ([#1169])
  * Fix Puma startup in provided init.d script ([#1061])
  * Fix default SSL mode back to none. ([#1036])
  * Fixed the issue of @listeners getting nil io ([#1120])
  * Make `get_dh1024` compatible with OpenSSL v1.1.0 ([#1178])
  * More gracefully deal with SSL sessions. Fixes [#1002]
  * Move puma.rb to just autoloads. Fixes [#1063]
  * MiniSSL: Provide write as <<. Fixes [#1089]
  * Prune bundler should inherit fds ([#1114])
  * Replace use of Process.getpgid which does not behave as intended on all platforms ([#1110])
  * Transfer encoding header should be downcased before comparison ([#1135])
  * Use same write log logic for hijacked requests. ([#1081])
  * Fix `uninitialized constant Puma::StateFile` ([#1138])
  * Fix access priorities of each level in LeveledOptions ([#1118])

* 3 others:

  * Lots of tests added/fixed/improved. Switched to Minitest from Test::Unit. Big thanks to @frodsan.
  * Lots of documentation added/improved.
  * Add license indicators to the HTTP extension. ([#1075])

## 3.6.2 / 2016-11-22

* 1 bug fix:

  * Revert [#1118]/Fix access priorities of each level in LeveledOptions. This
    had an unintentional side effect of changing the importance of command line
    options, such as -p.

## 3.6.1 / 2016-11-21

* 8 bug fixes:

  * Fix Puma start in init.d script.
  * Fix default SSL mode back to none. Fixes [#1036]
  * Fixed the issue of @listeners getting nil io, fix rails restart ([#1120])
  * More gracefully deal with SSL sessions. Fixes [#1002]
  * Prevent short term thread churn.
  * Provide write as <<. Fixes [#1089]
  * Fix access priorities of each level in LeveledOptions - fixes TTIN.
  * Stub description files updated for init.d.

* 2 new project committers:

  * Nate Berkopec (@nateberkopec)
  * Richard Schneeman (@schneems)

## 3.6.0 / 2016-07-24

* 12 bug fixes:
  * Add ability to detect a shutting down server. Fixes [#932]
  * Add support for Expect: 100-continue. Fixes [#519]
  * Check SSLContext better. Fixes [#828]
  * Clarify behavior of '-t num'. Fixes [#984]
  * Don't default to VERIFY_PEER. Fixes [#1028]
  * Don't use ENV['PWD'] on windows. Fixes [#1023]
  * Enlarge the scope of catching app exceptions. Fixes [#1027]
  * Execute background hooks after daemonizing. Fixes [#925]
  * Handle HUP as a stop unless there is IO redirection. Fixes [#911]
  * Implement chunked request handling. Fixes [#620]
  * Just rescue exception to return a 500. Fixes [#1027]
  * Redirect IO in the jruby daemon mode. Fixes [#778]

## 3.5.2 / 2016-07-20

* 1 bug fix:
  * Don't let persistent_timeout be nil

* 1 PR merged:
  * Merge pull request [#1021] from benzrf/patch-1

## 3.5.1 / 2016-07-20

* 1 bug fix:
  * Be sure to only listen on host:port combos once. Fixes [#1022]

## 3.5.0 / 2016-07-18

* 1 minor features:
  * Allow persistent_timeout to be configured via the dsl.

* 9 bug fixes:
  * Allow a bare % in a query string. Fixes [#958]
  * Explicitly listen on all localhost addresses. Fixes [#782]
  * Fix `TCPLogger` log error in tcp cluster mode.
  * Fix puma/puma[#968] Cannot bind SSL port due to missing verify_mode option
  * Fix puma/puma[#968] Default verify_mode to peer
  * Log any exceptions in ThreadPool. Fixes [#1010]
  * Silence connection errors in the reactor. Fixes [#959]
  * Tiny fixes in hook documentation for [#840]
  * It should not log requests if we want it to be quiet

* 5 doc fixes:
  * Add How to stop Puma on Heroku using plugins to the example directory
  * Provide both hot and phased restart in jungle script
  * Update reference to the instances management script
  * Update default number of threads
  * Fix typo in example config

* 14 PRs merged:
  * Merge pull request [#1007] from willnet/patch-1
  * Merge pull request [#1014] from jeznet/patch-1
  * Merge pull request [#1015] from bf4/patch-1
  * Merge pull request [#1017] from jorihardman/configurable_persistent_timeout
  * Merge pull request [#954] from jf/master
  * Merge pull request [#955] from jf/add-request-info-to-standard-error-rescue
  * Merge pull request [#956] from maxkwallace/master
  * Merge pull request [#960] from kmayer/kmayer-plugins-heroku-restart
  * Merge pull request [#969] from frankwong15/master
  * Merge pull request [#970] from willnet/delete-blank-document
  * Merge pull request [#974] from rocketjob/feature/name_threads
  * Merge pull request [#977] from snow/master
  * Merge pull request [#981] from zach-chai/patch-1
  * Merge pull request [#993] from scorix/master

## 3.4.0 / 2016-04-07

* 2 minor features:
  * Add ability to force threads to stop on shutdown. Fixes [#938]
  * Detect and commit seppuku when fork(2) fails. Fixes [#529]

* 3 unknowns:
  * Ignore errors trying to update the backport tables. Fixes [#788]
  * Invoke the lowlevel_error in more places to allow for exception tracking. Fixes [#894]
  * Update the query string when an absolute URI is used. Fixes [#937]

* 5 doc fixes:
  * Add Process Monitors section to top-level README
  * Better document the hooks. Fixes [#840]
  * docs/system.md sample config refinements and elaborations
  * Fix typos at couple of places.
  * Cleanup warnings

* 3 PRs merged:
  * Merge pull request [#945] from dekellum/systemd-docs-refined
  * Merge pull request [#946] from vipulnsward/rm-pid
  * Merge pull request [#947] from vipulnsward/housekeeping-typos

## 3.3.0 / 2016-04-05

* 2 minor features:
  * Allow overriding options of Configuration object
  * Rename to inherit_ssl_listener like inherit_tcp|unix

* 2 doc fixes:
  * Add docs/systemd.md (with socket activation sub-section)
  * Document UNIX signals with cluster on README.md

* 3 PRs merged:
  * Merge pull request [#936] from prathamesh-sonpatki/allow-overriding-config-options
  * Merge pull request [#940] from kyledrake/signalsdoc
  * Merge pull request [#942] from dekellum/socket-activate-improve

## 3.2.0 / 2016-03-20

* 1 deprecation removal:
  * Delete capistrano.rb

* 3 bug fixes:
  * Detect gems.rb as well as Gemfile
  * Simplify and fix logic for directory to use when restarting for all phases
  * Speed up phased-restart start

* 2 PRs merged:
  * Merge pull request [#927] from jlecour/gemfile_variants
  * Merge pull request [#931] from joneslee85/patch-10

## 3.1.1 / 2016-03-17

* 4 bug fixes:
  * Disable USR1 usage on JRuby
  * Fixes [#922] - Correctly define file encoding as UTF-8
  * Set a more explicit SERVER_SOFTWARE Rack variable
  * Show RUBY_ENGINE_VERSION if available. Fixes [#923]

* 3 PRs merged:
  * Merge pull request [#912] from tricknotes/fix-allow-failures-in-travis-yml
  * Merge pull request [#921] from swrobel/patch-1
  * Merge pull request [#924] from tbrisker/patch-1

## 3.1.0 / 2016-03-05

* 1 minor feature:
  * Add 'import' directive to config file. Fixes [#916]

* 5 bug fixes:
  * Add 'fetch' to options. Fixes [#913]
  * Fix jruby daemonization. Fixes [#918]
  * Recreate the proper args manually. Fixes [#910]
  * Require 'time' to get iso8601. Fixes [#914]

## 3.0.2 / 2016-02-26

* 5 bug fixes:

  * Fix 'undefined local variable or method `pid` for #<Puma::ControlCLI:0x007f185fcef968>' when execute pumactl with `--pid` option.
  * Fix 'undefined method `windows?` for Puma:Module' when execute pumactl.
  * Harden tmp_restart against errors related to the restart file
  * Make `plugin :tmp_restart` behavior correct in Windows.
  * fix uninitialized constant Puma::ControlCLI::StateFile

* 3 PRs merged:

  * Merge pull request [#901] from mitto/fix-pumactl-uninitialized-constant-statefile
  * Merge pull request [#902] from corrupt952/fix_undefined_method_and_variable_when_execute_pumactl
  * Merge pull request [#905] from Eric-Guo/master

## 3.0.1 / 2016-02-25

* 1 bug fix:

  * Removed the experimental support for async.callback as it broke
    websockets entirely. Seems no server has both hijack and async.callback
    and thus faye is totally confused what to do and doesn't work.

## 3.0.0 / 2016-02-25

* 2 major changes:

  * Ruby pre-2.0 is no longer supported. We'll do our best to not add
    features that break those rubies but will no longer be testing
    with them.
  * Don't log requests by default. Fixes [#852]

* 2 major features:

  * Plugin support! Plugins can interact with configuration as well
    as provide augment server functionality!
  * Experimental env['async.callback'] support

* 4 minor features:

  * Listen to unix socket with provided backlog if any
  * Improves the clustered stats to report worker stats
  * Pass the env to the lowlevel_error handler. Fixes [#854]
  * Treat path-like hosts as unix sockets. Fixes [#824]

* 5 bug fixes:

  * Clean thread locals when using keepalive. Fixes [#823]
  * Cleanup compiler warnings. Fixes [#815]
  * Expose closed? for use by the reactor. Fixes [#835]
  * Move signal handlers to separate method to prevent space leak. Fixes [#798]
  * Signal not full on worker exit [#876]

* 5 doc fixes:

  * Update README.md with various grammar fixes
  * Use newest version of Minitest
  * Add directory configuration docs, fix typo [ci skip]
  * Remove old COPYING notice. Fixes [#849]

* 10 merged PRs:

  * Merge pull request [#871] from deepj/travis
  * Merge pull request [#874] from wallclockbuilder/master
  * Merge pull request [#883] from dadah89/igor/trim_only_worker
  * Merge pull request [#884] from uistudio/async-callback
  * Merge pull request [#888] from mlarraz/tick_minitest
  * Merge pull request [#890] from todd/directory_docs
  * Merge pull request [#891] from ctaintor/improve_clustered_status
  * Merge pull request [#893] from spastorino/add_missing_require
  * Merge pull request [#897] from zendesk/master
  * Merge pull request [#899] from kch/kch-readme-fixes

## 2.16.0 / 2016-01-27

* 7 minor features:

  * Add 'set_remote_address' config option
  * Allow to run puma in silent mode
  * Expose cli options in DSL
  * Support passing JRuby keystore info in ssl_bind DSL
  * Allow umask for unix:/// style control urls
  * Expose `old_worker_count` in stats url
  * Support TLS client auth (verify_mode) in jruby

* 7 bug fixes:

  * Don't persist before_fork hook in state file
  * Reload bundler before pulling in rack. Fixes [#859]
  * Remove NEWRELIC_DISPATCHER env variable
  * Cleanup C code
  * Use Timeout.timeout instead of Object.timeout
  * Make phased restarts faster
  * Ignore the case of certain headers, because HTTP

* 1 doc changes:

  * Test against the latest Ruby 2.1, 2.2, 2.3, head and JRuby 9.0.4.0 on Travis

* 12 merged PRs
  * Merge pull request [#822] from kwugirl/remove_NEWRELIC_DISPATCHER
  * Merge pull request [#833] from joemiller/jruby-client-tls-auth
  * Merge pull request [#837] from YuriSolovyov/ssl-keystore-jruby
  * Merge pull request [#839] from mezuka/master
  * Merge pull request [#845] from deepj/timeout-deprecation
  * Merge pull request [#846] from sriedel/strip_before_fork
  * Merge pull request [#850] from deepj/travis
  * Merge pull request [#853] from Jeffrey6052/patch-1
  * Merge pull request [#857] from zendesk/faster_phased_restarts
  * Merge pull request [#858] from mlarraz/fix_some_warnings
  * Merge pull request [#860] from zendesk/expose_old_worker_count
  * Merge pull request [#861] from zendesk/allow_control_url_umask

## 2.15.3 / 2015-11-07

* 1 bug fix:

  * Fix JRuby parser

## 2.15.2 / 2015-11-06

* 2 bug fixes:
  * ext/puma_http11: handle duplicate headers as per RFC
  * Only set ctx.ca iff there is a params['ca'] to set with.

* 2 PRs merged:
  * Merge pull request [#818] from unleashed/support-duplicate-headers
  * Merge pull request [#819] from VictorLowther/fix-ca-and-verify_null-exception

## 2.15.1 / 2015-11-06

* 1 bug fix:

  * Allow older openssl versions

## 2.15.0 / 2015-11-06

* 6 minor features:
  * Allow setting ca without setting a verify mode
  * Make jungle for init.d support rbenv
  * Use SSL_CTX_use_certificate_chain_file for full chain
  * cluster: add worker_boot_timeout option
  * configuration: allow empty tags to mean no tag desired
  * puma/cli: support specifying STD{OUT,ERR} redirections and append mode

* 5 bug fixes:
  * Disable SSL Compression
  * Fix bug setting worker_directory when using a symlink directory
  * Fix error message in DSL that was slightly inaccurate
  * Pumactl: set correct process name. Fixes [#563]
  * thread_pool: fix race condition when shutting down workers

* 10 doc fixes:
  * Add before_fork explanation in Readme.md
  * Correct spelling in DEPLOYMENT.md
  * Correct spelling in docs/nginx.md
  * Fix spelling errors.
  * Fix typo in deployment description
  * Fix typos (it's -> its) in events.rb and server.rb
  * fixing for typo mentioned in [#803]
  * Spelling correction for README
  * thread_pool: fix typos in comment
  * More explicit docs for worker_timeout

* 18 PRs merged:
  * Merge pull request [#768] from nathansamson/patch-1
  * Merge pull request [#773] from rossta/spelling_corrections
  * Merge pull request [#774] from snow/master
  * Merge pull request [#781] from sunsations/fix-typo
  * Merge pull request [#791] from unleashed/allow_empty_tags
  * Merge pull request [#793] from robdimarco/fix-working-directory-symlink-bug
  * Merge pull request [#794] from peterkeen/patch-1
  * Merge pull request [#795] from unleashed/redirects-from-cmdline
  * Merge pull request [#796] from cschneid/fix_dsl_message
  * Merge pull request [#799] from annafw/master
  * Merge pull request [#800] from liamseanbrady/fix_typo
  * Merge pull request [#801] from scottjg/ssl-chain-file
  * Merge pull request [#802] from scottjg/ssl-crimes
  * Merge pull request [#804] from burningTyger/patch-2
  * Merge pull request [#809] from unleashed/threadpool-fix-race-in-shutdown
  * Merge pull request [#810] from vlmonk/fix-pumactl-restart-bug
  * Merge pull request [#814] from schneems/schneems/worker_timeout-docs
  * Merge pull request [#817] from unleashed/worker-boot-timeout

## 2.14.0 / 2015-09-18

* 1 minor feature:
  * Make building with SSL support optional

* 1 bug fix:
  * Use Rack::Builder if available. Fixes [#735]

## 2.13.4 / 2015-08-16

* 1 bug fix:
  * Use the environment possible set by the config early and from
    the config file later (if set).

## 2.13.3 / 2015-08-15

Seriously, I need to revamp config with tests.

* 1 bug fix:
  * Fix preserving options before cleaning for state. Fixes [#769]

## 2.13.2 / 2015-08-15

The "clearly I don't have enough tests for the config" release.

* 1 bug fix:
  * Fix another place binds wasn't initialized. Fixes [#767]

## 2.13.1 / 2015-08-15

* 2 bug fixes:
  * Fix binds being masked in config files. Fixes [#765]
  * Use options from the config file properly in pumactl. Fixes [#764]

## 2.13.0 / 2015-08-14

* 1 minor feature:
  * Add before_fork hooks option.

* 3 bug fixes:
  * Check for OPENSSL_NO_ECDH before using ECDH
  * Eliminate logging overhead from JRuby SSL
  * Prefer cli options over config file ones. Fixes [#669]

* 1 deprecation:
  * Add deprecation warning to capistrano.rb. Fixes [#673]

* 4 PRs merged:
  * Merge pull request [#668] from kcollignon/patch-1
  * Merge pull request [#754] from nathansamson/before_boot
  * Merge pull request [#759] from BenV/fix-centos6-build
  * Merge pull request [#761] from looker/no-log

## 2.12.3 / 2015-08-03

* 8 minor bugs fixed:
  * Fix Capistrano 'uninitialized constant Puma' error.
  * Fix some ancient and incorrect error handling code
  * Fix uninitialized constant error
  * Remove toplevel rack interspection, require rack on load instead
  * Skip empty parts when chunking
  * Switch from inject to each in config_ru_binds iteration
  * Wrap SSLv3 spec in version guard.
  * ruby 1.8.7 compatibility patches

* 4 PRs merged:
  * Merge pull request [#742] from deivid-rodriguez/fix_missing_require
  * Merge pull request [#743] from matthewd/skip-empty-chunks
  * Merge pull request [#749] from huacnlee/fix-cap-uninitialized-puma-error
  * Merge pull request [#751] from costi/compat_1_8_7

* 1 test fix:
  * Add 1.8.7, rbx-1 (allow failures) to Travis.

## 2.12.2 / 2015-07-17

* 2 bug fix:
  * Pull over and use Rack::URLMap. Fixes [#741]
  * Stub out peercert on JRuby for now. Fixes [#739]

## 2.12.1 / 2015-07-16

* 2 bug fixes:
  * Use a constant format. Fixes [#737]
  * Use strerror for Windows sake. Fixes [#733]

* 1 doc change:
  * typo fix: occured -> occurred

* 1 PR merged:
  * Merge pull request [#736] from paulanunda/paulanunda/typo-fix

## 2.12.0 / 2015-07-14

* 13 bug fixes:
  * Add thread reaping to thread pool
  * Do not automatically use chunked responses when hijacked
  * Do not suppress Content-Length on partial hijack
  * Don't allow any exceptions to terminate a thread
  * Handle ENOTCONN client disconnects when setting REMOTE_ADDR
  * Handle very early exit of cluster mode. Fixes [#722]
  * Install rack when running tests on travis to use rack/lint
  * Make puma -v and -h return success exit code
  * Make pumactl load config/puma.rb by default
  * Pass options from pumactl properly when pruning. Fixes [#694]
  * Remove rack dependency. Fixes [#705]
  * Remove the default Content-Type: text/plain
  * Add Client Side Certificate Auth

* 8 doc/test changes:
  * Added example sourcing of environment vars
  * Added tests for bind configuration on rackup file
  * Fix example config text
  * Update DEPLOYMENT.md
  * Update Readme with example of custom error handler
  * ci: Improve Travis settings
  * ci: Start running tests against JRuby 9k on Travis
  * ci: Convert to container infrastructure for travisci

* 2 ops changes:
  * Check for system-wide rbenv
  * capistrano: Add additional env when start rails

* 16 PRs merged:
  * Merge pull request [#686] from jjb/patch-2
  * Merge pull request [#693] from rob-murray/update-example-config
  * Merge pull request [#697] from spk/tests-bind-on-rackup-file
  * Merge pull request [#699] from deees/fix/require_rack_builder
  * Merge pull request [#701] from deepj/master
  * Merge pull request [#702] from Jimdo/thread-reaping
  * Merge pull request [#703] from deepj/travis
  * Merge pull request [#704] from grega/master
  * Merge pull request [#709] from lian/master
  * Merge pull request [#711] from julik/master
  * Merge pull request [#712] from yakara-ltd/pumactl-default-config
  * Merge pull request [#715] from RobotJiang/master
  * Merge pull request [#725] from rwz/master
  * Merge pull request [#726] from strenuus/handle-client-disconnect
  * Merge pull request [#729] from allaire/patch-1
  * Merge pull request [#730] from iamjarvo/container-infrastructure

## 2.11.3 / 2015-05-18

* 5 bug fixes:
  * Be sure to unlink tempfiles after a request. Fixes [#690]
  * Coerce the key to a string before checking. (thar be symbols). Fixes [#684]
  * Fix hang on bad SSL handshake
  * Remove `enable_SSLv3` support from JRuby

* 1 PR merged:
  * Merge pull request [#698] from looker/hang-handshake

## 2.11.2 / 2015-04-11

* 2 minor features:
  * Add `on_worker_fork` hook, which allows to mimic Unicorn's behavior
  * Add shutdown_debug config option

* 4 bug fixes:
  * Fix the Config constants not being available in the DSL. Fixes [#683]
  * Ignore multiple port declarations
  * Proper 'Connection' header handling compatible with HTTP 1.[01] protocols
  * Use "Puma" instead of "puma" to reporting to New Relic

* 1 doc fixes:
  * Add Gitter badge.

* 6 PRs merged:
  * Merge pull request [#657] from schneems/schneems/puma-once-port
  * Merge pull request [#658] from Tomohiro/newrelic-dispatcher-default-update
  * Merge pull request [#662] from basecrm/connection-compatibility
  * Merge pull request [#664] from fxposter/on-worker-fork
  * Merge pull request [#667] from JuanitoFatas/doc/gemspec
  * Merge pull request [#672] from chulkilee/refactor

## 2.11.1 / 2015-02-11

* 2 bug fixes:
  * Avoid crash in strange restart conditions
  * Inject the GEM_HOME that bundler into puma-wild's env. Fixes [#653]

* 2 PRs merged:
  * Merge pull request [#644] from bpaquet/master
  * Merge pull request [#646] from mkonecny/master

## 2.11.0 / 2015-01-20

* 9 bug fixes:
  * Add mode as an additional bind option to unix sockets. Fixes [#630]
  * Advertise HTTPS properly after a hot restart
  * Don't write lowlevel_error_handler to state
  * Fix phased restart with stuck requests
  * Handle spaces in the path properly. Fixes [#622]
  * Set a default REMOTE_ADDR to avoid using peeraddr on unix sockets. Fixes [#583]
  * Skip device number checking on jruby. Fixes [#586]
  * Update extconf.rb to compile correctly on OS X
  * redirect io right after daemonizing so startup errors are shown. Fixes [#359]

* 6 minor features:
  * Add a configuration option that prevents puma from queueing requests.
  * Add reload_worker_directory
  * Add the ability to pass environment variables to the init script (for Jungle).
  * Add the proctitle tag to the worker. Fixes [#633]
  * Infer a proctitle tag based on the directory
  * Update lowlevel error message to be more meaningful.

* 10 PRs merged:
  * Merge pull request [#478] from rubencaro/master
  * Merge pull request [#610] from kwilczynski/master
  * Merge pull request [#611] from jasonl/better-lowlevel-message
  * Merge pull request [#616] from jc00ke/master
  * Merge pull request [#623] from raldred/patch-1
  * Merge pull request [#628] from rdpoor/master
  * Merge pull request [#634] from deepj/master
  * Merge pull request [#637] from raskhadafi/patch-1
  * Merge pull request [#639] from ebeigarts/fix-phased-restarts
  * Merge pull request [#640] from codehotter/issue-612-dependent-requests-deadlock

## 2.10.2 / 2014-11-26

* 1 bug fix:
  * Conditionalize thread local cleaning, fixes perf degradation fix
    The code to clean out all Thread locals adds pretty significant
    overhead to a each request, so it has to be turned on explicitly
    if a user needs it.

## 2.10.1 / 2014-11-24

* 1 bug fix:
  * Load the app after daemonizing because the app might start threads.

  This change means errors loading the app are now reported only in the redirected
  stdout/stderr.

  If you're app has problems starting up, start it without daemon mode initially
  to test.

## 2.10.0 / 2014-11-23

* 3 minor features:
  * Added on_worker_shutdown hook mechanism
  * Allow binding to ipv6 addresses for ssl URIs
  * Warn about any threads started during app preload

* 5 bug fixes:
  * Clean out a threads local data before doing work
  * Disable SSLv3. Fixes [#591]
  * First change the directory to use the correct Gemfile.
  * Only use config.ru binds if specified. Fixes [#606]
  * Strongish cipher suite with FS support for some browsers

* 2 doc changes:
  * Change umask examples to more permissive values
  * fix typo in README.md

* 9 Merged PRs:
  * Merge pull request [#560] from raskhadafi/prune_bundler-bug
  * Merge pull request [#566] from sheltond/master
  * Merge pull request [#593] from andruby/patch-1
  * Merge pull request [#594] from hassox/thread-cleanliness
  * Merge pull request [#596] from burningTyger/patch-1
  * Merge pull request [#601] from sorentwo/friendly-umask
  * Merge pull request [#602] from 1334/patch-1
  * Merge pull request [#608] from Gu1/master
  * Merge pull request [#538] from memiux/?

## 2.9.2 / 2014-10-25

* 8 bug fixes:
  * Fix puma-wild handling a restart properly. Fixes [#550]
  * JRuby SSL POODLE update
  * Keep deprecated features warnings
  * Log the current time when Puma shuts down.
  * Fix cross-platform extension library detection
  * Use the correct Windows names for OpenSSL.
  * Better error logging during startup
  * Fixing sexist error messages

* 6 PRs merged:
  * Merge pull request [#549] from bsnape/log-shutdown-time
  * Merge pull request [#553] from lowjoel/master
  * Merge pull request [#568] from mariuz/patch-1
  * Merge pull request [#578] from danielbuechele/patch-1
  * Merge pull request [#581] from alexch/slightly-better-logging
  * Merge pull request [#590] from looker/jruby_disable_sslv3

## 2.9.1 / 2014-09-05

* 4 bug fixes:
  * Cleanup the SSL related structures properly, fixes memory leak
  * Fix thread spawning edge case.
  * Force a worker check after a worker boots, don't wait 5sec. Fixes [#574]
  * Implement SIGHUP for logs reopening

* 2 PRs merged:
  * Merge pull request [#561] from theoldreader/sighup
  * Merge pull request [#570] from havenwood/spawn-thread-edge-case

## 2.9.0 / 2014-07-12

* 1 minor feature:
  * Add SSL support for JRuby

* 3 bug fixes:
  * Typo BUNDLER_GEMFILE -> BUNDLE_GEMFILE
  * Use fast_write because we can't trust syswrite
  * pumactl - do not modify original ARGV

* 4 doc fixes:
  * BSD-3-Clause over BSD to avoid confusion
  * Deploy doc: clarification of the GIL
  * Fix typo in DEPLOYMENT.md
  * Update README.md

* 6 PRs merged:
  * Merge pull request [#520] from misfo/patch-2
  * Merge pull request [#530] from looker/jruby-ssl
  * Merge pull request [#537] from vlmonk/patch-1
  * Merge pull request [#540] from allaire/patch-1
  * Merge pull request [#544] from chulkilee/bsd-3-clause
  * Merge pull request [#551] from jcxplorer/patch-1

## 2.8.2 / 2014-04-12

* 4 bug fixes:
  * During upgrade, change directory in main process instead of workers.
  * Close the client properly on error
  * Capistrano: fallback from phased restart to start when not started
  * Allow tag option in conf file

* 4 doc fixes:
  * Fix Puma daemon service README typo
  * `preload_app!` instead of `preload_app`
  * add preload_app and prune_bundler to example config
  * allow changing of worker_timeout in config file

* 11 PRs merged:
  * Merge pull request [#487] from ckuttruff/master
  * Merge pull request [#492] from ckuttruff/master
  * Merge pull request [#493] from alepore/config_tag
  * Merge pull request [#503] from mariuz/patch-1
  * Merge pull request [#505] from sammcj/patch-1
  * Merge pull request [#506] from FlavourSys/config_worker_timeout
  * Merge pull request [#510] from momer/rescue-block-handle-servers-fix
  * Merge pull request [#511] from macool/patch-1
  * Merge pull request [#514] from edogawaconan/refactor_env
  * Merge pull request [#517] from misfo/patch-1
  * Merge pull request [#518] from LongMan/master

## 2.8.1 / 2014-03-06

* 1 bug fixes:
  * Run puma-wild with proper deps for prune_bundler

* 2 doc changes:
  * Described the configuration file finding behavior added in 2.8.0 and how to disable it.
  * Start the deployment doc

* 6 PRs merged:
  * Merge pull request [#471] from arthurnn/fix_test
  * Merge pull request [#485] from joneslee85/patch-9
  * Merge pull request [#486] from joshwlewis/patch-1
  * Merge pull request [#490] from tobinibot/patch-1
  * Merge pull request [#491] from brianknight10/clarify-no-config

## 2.8.0 / 2014-02-28

* 8 minor features:
  * Add ability to autoload a config file. Fixes [#438]
  * Add ability to detect and terminate hung workers. Fixes [#333]
  * Add booted_workers to stats response
  * Add config to customize the default error message
  * Add prune_bundler option
  * Add worker indexes, expose them via on_worker_boot. Fixes [#440]
  * Add pretty process name
  * Show the ruby version in use

* 7 bug fixes:
  * Added 408 status on timeout.
  * Be more hostile with sockets that write block. Fixes [#449]
  * Expect at_exit to exclusively remove the pidfile. Fixes [#444]
  * Expose latency and listen backlog via bind query. Fixes [#370]
  * JRuby raises IOError if the socket is there. Fixes [#377]
  * Process requests fairly. Fixes [#406]
  * Rescue SystemCallError as well. Fixes [#425]

* 4 doc changes:
  * Add 2.1.0 to the matrix
  * Add Code Climate badge to README
  * Create signals.md
  * Set the license to BSD. Fixes [#432]

* 14 PRs merged:
  * Merge pull request [#428] from alexeyfrank/capistrano_default_hooks
  * Merge pull request [#429] from namusyaka/revert-const_defined
  * Merge pull request [#431] from mrb/master
  * Merge pull request [#433] from alepore/process-name
  * Merge pull request [#437] from ibrahima/master
  * Merge pull request [#446] from sudara/master
  * Merge pull request [#451] from pwiebe/status_408
  * Merge pull request [#453] from joevandyk/patch-1
  * Merge pull request [#470] from arthurnn/fix_458
  * Merge pull request [#472] from rubencaro/master
  * Merge pull request [#480] from jjb/docs-on-running-test-suite
  * Merge pull request [#481] from schneems/master
  * Merge pull request [#482] from prathamesh-sonpatki/signals-doc-cleanup
  * Merge pull request [#483] from YotpoLtd/master

## 2.7.1 / 2013-12-05

* 1 bug fix:
  * Keep STDOUT/STDERR the right mode. Fixes [#422]

## 2.7.0 / 2013-12-03

* 1 minor feature:
  * Adding TTIN and TTOU to increment/decrement workers

* N bug fixes:
  * Always use our Process.daemon because it's not busted
  * Add capistrano restart failback to start.
  * Change position of `cd` so that rvm gemset is loaded
  * Clarify some platform specifics
  * Do not close the pipe sockets when retrying
  * Fix String#byteslice for Ruby 1.9.1, 1.9.2
  * Fix compatibility with 1.8.7.
  * Handle IOError closed stream in IO.select
  * Increase the max URI path length to 2048 chars from 1024 chars
  * Upstart jungle use config/puma.rb instead

## 2.6.0 / 2013-09-13

* 2 minor features:
  * Add support for event hooks
  ** Add a hook for state transitions
  * Add phased restart to capistrano recipe.

* 4 bug fixes:
  * Convince workers to stop by SIGKILL after timeout
  * Define RSTRING_NOT_MODIFIED for Rubinius performance
  * Handle BrokenPipe, StandardError and IOError in fat_wrote and break out
  * Return success status to the invoking environment

## 2.5.1 / 2013-08-13

* 2 bug fixes:
  * Keep jruby daemon mode from retrying on a hot restart
  * Extract version from const.rb in gemspec

## 2.5.0 / 2013-08-08

* 2 minor features:
  * Allow configuring pumactl with config.rb
  * make `pumactl restart` start puma if not running

* 6 bug fixes:
  * Autodetect ruby managers and home directory in upstart script
  * Convert header values to string before sending.
  * Correctly report phased-restart availability
  * Fix pidfile creation/deletion race on jruby daemonization
  * Use integers when comparing thread counts
  * Fix typo in using lopez express (raw tcp) mode

* 6 misc changes:
  * Fix typo in phased-restart response
  * Uncomment setuid/setgid by default in upstart
  * Use Puma::Const::PUMA_VERSION in gemspec
  * Update upstart comments to reflect new commandline
  * Remove obsolete pumactl instructions; refer to pumactl for details
  * Make Bundler used puma.gemspec version agnostic

## 2.4.1 / 2013-08-07

* 1 experimental feature:
  * Support raw tcp servers (aka Lopez Express mode)

## 2.4.0 / 2013-07-22

* 5 minor features:
  * Add PUMA_JRUBY_DAEMON_OPTS to get around agent starting twice
  * Add ability to drain accept socket on shutdown
  * Add port to DSL
  * Adds support for using puma config file in capistrano deploys.
  * Make phased_restart fallback to restart if not available

* 10 bug fixes:

  * Be sure to only delete the pid in the master. Fixes [#334]
  * Call out -C/--config flags
  * Change parser symbol names to avoid clash. Fixes [#179]
  * Convert thread pool sizes to integers
  * Detect when the jruby daemon child doesn't start properly
  * Fix typo in CLI help
  * Improve the logging output when hijack is used. Fixes [#332]
  * Remove unnecessary thread pool size conversions
  * Setup :worker_boot as an Array. Fixes [#317]
  * Use 127.0.0.1 as REMOTE_ADDR of unix client. Fixes [#309]


## 2.3.2 / 2013-07-08

* 1 bug fix:
  * Move starting control server to after daemonization.

## 2.3.1 / 2013-07-06

* 2 bug fixes:
  * Include the right files in the Manifest.
  * Disable inheriting connections on restart on windows. Fixes [#166]

* 1 doc change:
  * Better document some platform constraints

## 2.3.0 / 2013-07-05

* 1 major bug fix:
  * Stabilize control server, add support in cluster mode

* 5 minor bug fixes:
  * Add ability to cleanup stale unix sockets
  * Check status data better. Fixes [#292]
  * Convert raw IO errors to ConnectionError. Fixes [#274]
  * Fix sending Content-Type and Content-Length for no body status. Fixes [#304]
  * Pass state path through to `pumactl start`. Fixes [#287]

* 2 internal changes:
  * Refactored modes into seperate classes that CLI uses
  * Changed CLI to take an Events object instead of stdout/stderr (API change)

## 2.2.2 / 2013-07-02

* 1 bug fix:
  * Fix restart_command in the config

## 2.2.1 / 2013-07-02

* 1 minor feature:
  * Introduce preload flag

* 1 bug fix:
  * Pass custom restart command in JRuby

## 2.2.0 / 2013-07-01

* 1 major feature:
  * Add ability to preload rack app

* 2 minor bugfixes:
  * Don't leak info when not in development. Fixes [#256]
  * Load the app, then bind the ports

## 2.1.1 / 2013-06-20

* 2 minor bug fixes:

  * Fix daemonization on jruby
  * Load the application before daemonizing. Fixes [#285]

## 2.1.0 / 2013-06-18

* 3 minor features:
  * Allow listening socket to be configured via Capistrano variable
  * Output results from 'stat's command when using pumactl
  * Support systemd socket activation

* 15 bug fixes:
  * Deal with pipes closing while stopping. Fixes [#270]
  * Error out early if there is no app configured
  * Handle ConnectionError rather than the lowlevel exceptions
  * tune with `-C` config file and `on_worker_boot`
  * use `-w`
  * Fixed some typos in upstart scripts
  * Make sure to use bytesize instead of size (MiniSSL write)
  * Fix an error in puma-manager.conf
  * fix: stop leaking sockets on restart (affects ruby 1.9.3 or before)
  * Ignore errors on the cross-thread pipe. Fixes [#246]
  * Ignore errors while uncorking the socket (it might already be closed)
  * Ignore the body on a HEAD request. Fixes [#278]
  * Handle all engine data when possible. Fixes [#251].
  * Handle all read exceptions properly. Fixes [#252]
  * Handle errors from the server better

* 3 doc changes:
  * Add note about on_worker_boot hook
  * Add some documentation for Clustered mode
  * Added quotes to /etc/puma.conf

## 2.0.1 / 2013-04-30

* 1 bug fix:
  * Fix not starting on JRuby properly

## 2.0.0 / 2013-04-29

RailsConf 2013 edition!

* 2 doc changes:
  * Start with rackup -s Puma, NOT rackup -s puma.
  * Minor doc fixes in the README.md, Capistrano section

* 2 bug fixes:
  * Fix reading RACK_ENV properly. Fixes [#234]
  * Make cap recipe handle tmp/sockets; fixes [#228]

* 3 minor changes:
  * Fix capistrano recipe
  * Fix stdout/stderr logs to sync outputs
  * allow binding to IPv6 addresses

## 2.0.0.b7 / 2013-03-18

* 5 minor enhancements:
  * Add -q option for :start
  * Add -V, --version
  * Add default Rack handler helper
  * Upstart support
  * Set worker directory from configuration file

* 12 bug fixes:
  * Close the binder in the right place. Fixes [#192]
  * Handle early term in workers. Fixes [#206]
  * Make sure that the default port is 80 when the request doesn't include HTTP_X_FORWARDED_PROTO.
  * Prevent Errno::EBADF errors on restart when running ruby 2.0
  * Record the proper @master_pid
  * Respect the header HTTP_X_FORWARDED_PROTO when the host doesn't include a port number.
  * Retry EAGAIN/EWOULDBLOCK during syswrite
  * Run exec properly to restart. Fixes [#154]
  * Set Rack run_once to false
  * Syncronize all access to @timeouts. Fixes [#208]
  * Write out the state post-daemonize. Fixes [#189]
  * Prevent crash when all workers are gone

## 2.0.0.b6 / 2013-02-06

* 2 minor enhancements:
  * Add hook for running when a worker boots
  * Advertise the Configuration object for apps to use.

* 1 bug fix:
  * Change directory in working during upgrade. Fixes [#185]

## 2.0.0.b5 / 2013-02-05

* 2 major features:
  * Add phased worker upgrade
  * Add support for the rack hijack protocol

* 2 minor features:
  * Add -R to specify the restart command
  * Add config file option to specify the restart command

* 5 bug fixes:
  * Cleanup pipes properly. Fixes [#182]
  * Daemonize earlier so that we don't lose app threads. Fixes [#183]
  * Drain the notification pipe. Fixes [#176], thanks @cryo28
  * Move write_pid to after we daemonize. Fixes [#180]
  * Redirect IO properly and emit message for checkpointing

## 2.0.0.b4 / 2012-12-12

* 4 bug fixes:
  * Properly check #syswrite's value for variable sized buffers. Fixes [#170]
  * Shutdown status server properly
  * Handle char vs byte and mixing syswrite with write properly
  * made MiniSSL validate key/cert file existence

## 2.0.0.b3 / 2012-11-22

* 1 bug fix:
  * Package right files in gem

## 2.0.0.b2 / 2012-11-18
* 5 minor feature:
  * Now Puma is bundled with an capistrano recipe. Just require
     'puma/capistrano' in you deploy.rb
  * Only inject CommonLogger in development mode
  * Add -p option to pumactl
  * Add ability to use pumactl to start a server
  * Add options to daemonize puma

* 7 bug fixes:
  * Reset the IOBuffer properly. Fixes [#148]
  * Shutdown gracefully on JRuby with Ctrl-C
  * Various methods to get newrelic to start. Fixes [#128]
  * fixing syntax error at capistrano recipe
  * Force ECONNRESET when read returns nil
  * Be sure to empty the drain the todo before shutting down. Fixes [#155]
  * allow for alternate locations for status app

## 2.0.0.b1 / 2012-09-11

* 1 major feature:
  * Optional worker process mode (-w) to allow for process scaling in
    addition to thread scaling

* 1 bug fix:
  * Introduce Puma::MiniSSL to be able to properly control doing
    nonblocking SSL

NOTE: SSL support in JRuby is not supported at present. Support will
be added back in a future date when a java Puma::MiniSSL is added.

## 1.6.3 / 2012-09-04

* 1 bug fix:
  * Close sockets waiting in the reactor when a hot restart is performed
    so that browsers reconnect on the next request

## 1.6.2 / 2012-08-27

* 1 bug fix:
  * Rescue StandardError instead of IOError to handle SystemCallErrors
    as well as other application exceptions inside the reactor.

## 1.6.1 / 2012-07-23

* 1 packaging bug fixed:
  * Include missing files

## 1.6.0 / 2012-07-23

* 1 major bug fix:
  * Prevent slow clients from starving the server by introducing a
    dedicated IO reactor thread. Credit for reporting goes to @meh.

## 1.5.0 / 2012-07-19

* 7 contributors to this release:
  * Christian Mayer
  * Darío Javier Cravero
  * Dirkjan Bussink
  * Gianluca Padovani
  * Santiago Pastorino
  * Thibault Jouan
  * tomykaira

* 6 bug fixes:
  * Define RSTRING_NOT_MODIFIED for Rubinius
  * Convert status to integer. Fixes [#123]
  * Delete pidfile when stopping the server
  * Allow compilation with -Werror=format-security option
  * Fix wrong HTTP version for a HTTP/1.0 request
  * Use String#bytesize instead of String#length

* 3 minor features:
  * Added support for setting RACK_ENV via the CLI, config file, and rack app
  * Allow Server#run to run sync. Fixes [#111]
  * Puma can now run on windows

## 1.4.0 / 2012-06-04

* 1 bug fix:
  * SCRIPT_NAME should be passed from env to allow mounting apps

* 1 experimental feature:
  * Add puma.socket key for direct socket access

## 1.3.1 / 2012-05-15

* 2 bug fixes:
  * use #bytesize instead of #length for Content-Length header
  * Use StringIO properly. Fixes [#98]

## 1.3.0 / 2012-05-08

* 2 minor features:
  * Return valid Rack responses (passes Lint) from status server
  * Add -I option to specify $LOAD_PATH directories

* 4 bug fixes:
  * Don't join the server thread inside the signal handle. Fixes [#94]
  * Make NullIO#read mimic IO#read
  * Only stop the status server if it's started. Fixes [#84]
  * Set RACK_ENV early in cli also. Fixes [#78]

* 1 new contributor:
  * Jesse Cooke

## 1.2.2 / 2012-04-28

* 4 bug fixes:
  * Report a lowlevel error to stderr
  * Set a fallback SERVER_NAME and SERVER_PORT
  * Keep the encoding of the body correct. Fixes [#79]
  * show error.to_s along with backtrace for low-level error

## 1.2.1 / 2012-04-11

* 1 bug fix:
  * Fix rack.url_scheme for SSL servers. Fixes [#65]

## 1.2.0 / 2012-04-11

* 1 major feature:
 * When possible, the internal restart does a "hot restart" meaning
   the server sockets remains open, so no connections are lost.

* 1 minor feature:
  * More helpful fallback error message

* 6 bug fixes:
  * Pass the proper args to unknown_error. Fixes [#54], [#58]
  * Stop the control server before restarting. Fixes [#61]
  * Fix reporting https only on a true SSL connection
  * Set the default content type to 'text/plain'. Fixes [#63]
  * Use REUSEADDR. Fixes [#60]
  * Shutdown gracefully on SIGTERM. Fixes [#53]

* 2 new contributors:
  * Seamus Abshere
  * Steve Richert

## 1.1.1 / 2012-03-30

* 1 bugfix:
  * Include puma/compat.rb in the gem (oops!)

## 1.1.0 / 2012-03-30

* 1 bugfix:
  * Make sure that the unix socket has the perms 0777 by default

* 1 minor feature:
  * Add umask param to the unix:// bind to set the umask

## 1.0.0 / 2012-03-29

* Released!

## Ignore - this is for maintainers to copy-paste during release
## Master

* Features
  * Your feature goes here <Most recent on the top, like GitHub> (#Github Number)

* Bugfixes
  * Your bugfix goes here <Most recent on the top, like GitHub> (#Github Number)

[#3256]:https://github.com/puma/puma/pull/3256     "PR by @MSP-Greg, merged 2023-10-16"
[#3235]:https://github.com/puma/puma/pull/3235     "PR by @joshuay03, merged 2023-10-03"
[#3228]:https://github.com/puma/puma/issues/3228   "Issue by @davidalejandroaguilar, closed 2023-10-03"
[#3282]:https://github.com/puma/puma/issues/3282   "Issue by @bensheldon, closed 2024-01-02"
[#3283]:https://github.com/puma/puma/pull/3283     "PR by @joshuay03, merged 2024-01-02"
[#3225]:https://github.com/puma/puma/pull/3225     "PR by @joshuay03, merged 2023-09-27"
[#2786]:https://github.com/puma/puma/issues/2786   "Issue by @vitiokss, closed 2023-09-27"
[#3179]:https://github.com/puma/puma/pull/3179     "PR by @MSP-Greg, merged 2023-09-26"
[#3255]:https://github.com/puma/puma/pull/3255     "PR by @casperisfine, merged 2023-10-19"
[#3276]:https://github.com/puma/puma/pull/3276     "PR by @casperisfine, merged 2023-11-16"
[#3271]:https://github.com/puma/puma/pull/3271     "PR by @MSP-Greg, merged 2023-10-30"
[#3266]:https://github.com/puma/puma/issues/3266   "Issue by @Dragonicity, closed 2023-10-30"
[#3270]:https://github.com/puma/puma/pull/3270     "PR by @MSP-Greg, merged 2023-10-30"
[#3265]:https://github.com/puma/puma/pull/3265     "PR by @MSP-Greg, merged 2023-10-25"
[#3264]:https://github.com/puma/puma/issues/3264   "Issue by @dentarg, closed 2023-10-25"
[#3254]:https://github.com/puma/puma/pull/3254     "PR by @casperisfine, merged 2023-10-11"
[#3245]:https://github.com/puma/puma/pull/3245     "PR by @olleolleolle, merged 2023-10-02"
[#3293]:https://github.com/puma/puma/pull/3293     "PR by @MSP-Greg, merged 2023-12-21"
[#3301]:https://github.com/puma/puma/pull/3301     "PR by @benburkert, merged 2023-12-29"
[#3248]:https://github.com/puma/puma/pull/3248     "PR by @dentarg, merged 2023-10-04"
[#3298]:https://github.com/puma/puma/pull/3298     "PR by @til, merged 2023-12-26"
[#2920]:https://github.com/puma/puma/pull/2920     "PR by @biinari, merged 2023-07-11"
[#3195]:https://github.com/puma/puma/pull/3195     "PR by @binarygit, merged 2023-08-15"
[#3209]:https://github.com/puma/puma/pull/3209     "PR by @joshuay03, merged 2023-09-04"
[#2580]:https://github.com/puma/puma/issues/2580   "Issue by @schuetzm, closed 2023-09-04"
[#3204]:https://github.com/puma/puma/pull/3204     "PR by @dhavalsingh, merged 2023-08-25"
[#3191]:https://github.com/puma/puma/pull/3191     "PR by @MSP-Greg, merged 2023-08-31"
[#3165]:https://github.com/puma/puma/pull/3165     "PR by @fallwith, merged 2023-06-06"
[#3174]:https://github.com/puma/puma/pull/3174     "PR by @copiousfreetime, merged 2023-06-11"
[#3181]:https://github.com/puma/puma/pull/3181     "PR by @MSP-Greg, merged 2023-06-23"
[#3187]:https://github.com/puma/puma/pull/3187     "PR by @MSP-Greg, merged 2023-06-30"
[#3094]:https://github.com/puma/puma/pull/3094     "PR by @Vuta, merged 2023-07-23"
[#3106]:https://github.com/puma/puma/pull/3106     "PR by @MSP-Greg, merged 2023-05-29"
[#3014]:https://github.com/puma/puma/issues/3014   "Issue by @kyledrake, closed 2023-05-29"
[#3161]:https://github.com/puma/puma/pull/3161     "PR by @MSP-Greg, merged 2023-05-27"
[#3037]:https://github.com/puma/puma/issues/3037   "Issue by @daisy1754, closed 2023-05-27"
[#3133]:https://github.com/puma/puma/pull/3133     "PR by @stanhu, merged 2023-04-30"
[#3132]:https://github.com/puma/puma/issues/3132   "Issue by @stanhu, closed 2023-04-30"
[#3163]:https://github.com/puma/puma/pull/3163     "PR by @MSP-Greg, merged 2023-05-27"
[#3155]:https://github.com/puma/puma/pull/3155     "PR by @dentarg, merged 2023-05-14"
[#3148]:https://github.com/puma/puma/issues/3148   "Issue by @dentarg, closed 2023-05-14"
[#3129]:https://github.com/puma/puma/pull/3129     "PR by @MSP-Greg, merged 2023-05-02"
[#3137]:https://github.com/puma/puma/pull/3137     "PR by @MSP-Greg, merged 2023-04-30"
[#3156]:https://github.com/puma/puma/pull/3156     "PR by @severin, merged 2023-05-16"
[#3162]:https://github.com/puma/puma/pull/3162     "PR by @MSP-Greg, merged 2023-05-23"
[#3151]:https://github.com/puma/puma/pull/3151     "PR by @nateberkopec, merged 2023-05-12"
[#3118]:https://github.com/puma/puma/pull/3118     "PR by @ninoseki, merged 2023-04-01"
[#3117]:https://github.com/puma/puma/issues/3117   "Issue by @ninoseki, closed 2023-04-01"
[#3109]:https://github.com/puma/puma/pull/3109     "PR by @ahorek, merged 2023-03-31"
[#3108]:https://github.com/puma/puma/issues/3108   "Issue by @treviateo, closed 2023-03-31"
[#3113]:https://github.com/puma/puma/pull/3113     "PR by @collinsauve, merged 2023-03-31"
[#3112]:https://github.com/puma/puma/issues/3112   "Issue by @dmke, closed 2023-03-31"
[#3111]:https://github.com/puma/puma/pull/3111     "PR by @adzap, merged 2023-03-30"
[#2770]:https://github.com/puma/puma/pull/2770     "PR by @vzajkov, merged 2023-03-29"
[#2511]:https://github.com/puma/puma/issues/2511   "Issue by @jchristie55332, closed 2021-12-12"
[#3089]:https://github.com/puma/puma/pull/3089     "PR by @Vuta, merged 2023-03-06"
[#2709]:https://github.com/puma/puma/pull/2709     "PR by @rodzyn, merged 2023-02-20"
[#3091]:https://github.com/puma/puma/pull/3091     "PR by @MSP-Greg, merged 2023-03-28"
[#3074]:https://github.com/puma/puma/pull/3074     "PR by @MSP-Greg, merged 2023-03-14"
[#3072]:https://github.com/puma/puma/pull/3072     "PR by @MSP-Greg, merged 2023-02-17"
[#3079]:https://github.com/puma/puma/pull/3079     "PR by @mohamedhafez, merged 2023-02-24"
[#3080]:https://github.com/puma/puma/pull/3080     "PR by @MSP-Greg, merged 2023-02-16"
[#3058]:https://github.com/puma/puma/pull/3058     "PR by @dentarg, merged 2023-01-29"
[#3007]:https://github.com/puma/puma/issues/3007   "Issue by @MSP-Greg, closed 2023-01-29"
[#3011]:https://github.com/puma/puma/pull/3011     "PR by @joaomarcos96, merged 2023-01-03"
[#3006]:https://github.com/puma/puma/pull/3006     "PR by @QWYNG, merged 2023-02-09"
[#2604]:https://github.com/puma/puma/issues/2604   "Issue by @dgoetz, closed 2023-02-09"
[#3040]:https://github.com/puma/puma/pull/3040     "PR by @shayonj, merged 2023-01-02"
[#3036]:https://github.com/puma/puma/pull/3036     "PR by @MSP-Greg, merged 2023-01-13"
[#3020]:https://github.com/puma/puma/issues/3020   "Issue by @dentarg, closed 2023-01-13"
[#3061]:https://github.com/puma/puma/pull/3061     "PR by @MSP-Greg, merged 2023-02-12"
[#3057]:https://github.com/puma/puma/issues/3057   "Issue by @mmarvb8h, closed 2023-02-12"
[#3065]:https://github.com/puma/puma/pull/3065     "PR by @MSP-Greg, merged 2023-02-11"
[#3062]:https://github.com/puma/puma/pull/3062     "PR by @willkoehler, merged 2023-01-29"
[#3035]:https://github.com/puma/puma/pull/3035     "PR by @MSP-Greg, merged 2022-12-24"
[#3033]:https://github.com/puma/puma/issues/3033   "Issue by @jules-w2, closed 2022-12-24"
[#3016]:https://github.com/puma/puma/pull/3016     "PR by @MSP-Greg, merged 2022-12-24"
[#3005]:https://github.com/puma/puma/pull/3005     "PR by @JuanitoFatas, merged 2022-11-04"
[#3004]:https://github.com/puma/puma/pull/3004     "PR by @MSP-Greg, merged 2022-11-24"
[#3000]:https://github.com/puma/puma/issues/3000   "Issue by @dentarg, closed 2022-11-24"
[#3002]:https://github.com/puma/puma/pull/3002     "PR by @MSP-Greg, merged 2022-11-03"
[#2999]:https://github.com/puma/puma/issues/2999   "Issue by @aymeric-ledorze, closed 2022-11-03"
[#3013]:https://github.com/puma/puma/pull/3013     "PR by @MSP-Greg, merged 2022-11-13"
[#2919]:https://github.com/puma/puma/pull/2919     "PR by @MSP-Greg, merged 2022-08-30"
[#2652]:https://github.com/puma/puma/issues/2652   "Issue by @Roguelazer, closed 2022-09-04"
[#2653]:https://github.com/puma/puma/pull/2653     "PR by @Roguelazer, closed 2022-03-07"
[#2849]:https://github.com/puma/puma/pull/2849     "PR by @kares, merged 2022-04-09"
[#2933]:https://github.com/puma/puma/pull/2933     "PR by @cafedomancer, merged 2022-09-09"
[#2925]:https://github.com/puma/puma/issues/2925   "Issue by @nateberkopec, closed 2022-09-09"
[#2940]:https://github.com/puma/puma/pull/2940     "PR by @cafedomancer, merged 2022-09-10"
[#2924]:https://github.com/puma/puma/pull/2924     "PR by @cafedomancer, merged 2022-09-07"
[#2853]:https://github.com/puma/puma/issues/2853   "Issue by @nateberkopec, closed 2022-09-07"
[#2957]:https://github.com/puma/puma/pull/2957     "PR by @JuanitoFatas, merged 2022-09-16"
[#2958]:https://github.com/puma/puma/pull/2958     "PR by @JuanitoFatas, merged 2022-09-16"
[#2959]:https://github.com/puma/puma/pull/2959     "PR by @JuanitoFatas, merged 2022-09-16"
[#2960]:https://github.com/puma/puma/pull/2960     "PR by @JuanitoFatas, merged 2022-09-16"
[#2988]:https://github.com/puma/puma/pull/2988     "PR by @MSP-Greg, merged 2022-10-12"
[#2928]:https://github.com/puma/puma/pull/2928     "PR by @nateberkopec, merged 2022-09-10"
[#2798]:https://github.com/puma/puma/pull/2798     "PR by @johnnyshields, merged 2022-02-05"
[#2932]:https://github.com/puma/puma/pull/2932     "PR by @mrzasa, merged 2022-09-12"
[#2896]:https://github.com/puma/puma/pull/2896     "PR by @MSP-Greg, merged 2022-09-13"
[#2892]:https://github.com/puma/puma/pull/2892     "PR by @guilleiguaran, closed 2022-09-13"
[#2923]:https://github.com/puma/puma/pull/2923     "PR by @nateberkopec, merged 2022-09-09"
[#2740]:https://github.com/puma/puma/pull/2740     "PR by @ioquatix, merged 2022-01-29"
[#2845]:https://github.com/puma/puma/issues/2845   "Issue by @donv, closed 2022-03-22"
[#2917]:https://github.com/puma/puma/pull/2917     "PR by @MSP-Greg, merged 2022-09-19"
[#2915]:https://github.com/puma/puma/issues/2915   "Issue by @mperham, closed 2022-09-19"
[#2907]:https://github.com/puma/puma/pull/2907     "PR by @casperisfine, merged 2022-09-15"
[#2953]:https://github.com/puma/puma/pull/2953     "PR by @JuanitoFatas, merged 2022-09-14"
[#2936]:https://github.com/puma/puma/pull/2936     "PR by @MSP-Greg, merged 2022-09-09"
[#2931]:https://github.com/puma/puma/issues/2931   "Issue by @dentarg, closed 2022-09-09"
[#2875]:https://github.com/puma/puma/pull/2875     "PR by @ylecuyer, merged 2022-05-19"
[#2840]:https://github.com/puma/puma/pull/2840     "PR by @LukaszMaslej, merged 2022-04-13"
[#2774]:https://github.com/puma/puma/pull/2774     "PR by @ob-stripe, merged 2022-01-31"
[#2891]:https://github.com/puma/puma/pull/2891     "PR by @gingerlime, merged 2022-06-02"
[#2886]:https://github.com/puma/puma/pull/2886     "PR by @kares, merged 2022-05-30"
[#2899]:https://github.com/puma/puma/pull/2899     "PR by @kares, merged 2022-07-04"
[#2904]:https://github.com/puma/puma/pull/2904     "PR by @kares, merged 2022-08-27"
[#2884]:https://github.com/puma/puma/pull/2884     "PR by @kares, merged 2022-05-30"
[#2897]:https://github.com/puma/puma/pull/2897     "PR by @Edouard-chin, merged 2022-08-27"
[#1441]:https://github.com/puma/puma/issues/1441   "Issue by @nirvdrum, closed 2022-09-12"
[#2956]:https://github.com/puma/puma/pull/2956     "PR by @MSP-Greg, merged 2022-09-15"
[#2888]:https://github.com/puma/puma/pull/2888     "PR by @MSP-Greg, merged 2022-06-01"
[#2797]:https://github.com/puma/puma/pull/2797     "PR by @johnnyshields, merged 2022-02-01"
[#2795]:https://github.com/puma/puma/pull/2795     "PR by @johnnyshields, merged 2022-01-31"
[#2903]:https://github.com/puma/puma/pull/2903     "PR by @MSP-Greg, merged 2022-08-27"
[#2942]:https://github.com/puma/puma/pull/2942     "PR by @nateberkopec, merged 2022-09-15"
[#2921]:https://github.com/puma/puma/issues/2921   "Issue by @MSP-Greg, closed 2022-09-15"
[#2922]:https://github.com/puma/puma/issues/2922   "Issue by @MSP-Greg, closed 2022-09-10"
[#2955]:https://github.com/puma/puma/pull/2955     "PR by @cafedomancer, merged 2022-09-15"
[#3166]:https://github.com/puma/puma/pull/3166     "PR by @JoeDupuis, merged 2023-06-08"
[#2868]:https://github.com/puma/puma/pull/2868     "PR by @MSP-Greg, merged 2022-06-02"
[#2866]:https://github.com/puma/puma/issues/2866   "Issue by @slondr, closed 2022-06-02"
[#2883]:https://github.com/puma/puma/pull/2883     "PR by @MSP-Greg, merged 2022-06-02"
[#2890]:https://github.com/puma/puma/pull/2890     "PR by @kares, merged 2022-06-01"
[#2729]:https://github.com/puma/puma/issues/2729   "Issue by @kares, closed 2022-06-01"
[#2885]:https://github.com/puma/puma/pull/2885     "PR by @MSP-Greg, merged 2022-05-30"
[#2839]:https://github.com/puma/puma/issues/2839   "Issue by @wlipa, closed 2022-05-30"
[#2864]:https://github.com/puma/puma/pull/2864     "PR by @MSP-Greg, merged 2022-04-26"
[#2863]:https://github.com/puma/puma/issues/2863   "Issue by @eradman, closed 2022-04-26"
[#2861]:https://github.com/puma/puma/pull/2861     "PR by @BlakeWilliams, merged 2022-04-17"
[#2856]:https://github.com/puma/puma/issues/2856   "Issue by @nateberkopec, closed 2022-04-17"
[#2855]:https://github.com/puma/puma/pull/2855     "PR by @stanhu, merged 2022-04-09"
[#2848]:https://github.com/puma/puma/pull/2848     "PR by @stanhu, merged 2022-04-02"
[#2847]:https://github.com/puma/puma/pull/2847     "PR by @stanhu, merged 2022-04-02"
[#2838]:https://github.com/puma/puma/pull/2838     "PR by @epsilon-0, merged 2022-03-03"
[#2817]:https://github.com/puma/puma/pull/2817     "PR by @khustochka, merged 2022-02-20"
[#2810]:https://github.com/puma/puma/pull/2810     "PR by @kzkn, merged 2022-01-27"
[#2809]:https://github.com/puma/puma/pull/2809     "PR by @dentarg, merged 2022-01-26"
[#2764]:https://github.com/puma/puma/pull/2764     "PR by @dentarg, merged 2022-01-18"
[#2708]:https://github.com/puma/puma/issues/2708   "Issue by @erikaxel, closed 2022-01-18"
[#2780]:https://github.com/puma/puma/pull/2780     "PR by @dalibor, merged 2022-01-01"
[#2784]:https://github.com/puma/puma/pull/2784     "PR by @MSP-Greg, merged 2022-01-01"
[#2773]:https://github.com/puma/puma/pull/2773     "PR by @ob-stripe, merged 2022-01-01"
[#2794]:https://github.com/puma/puma/pull/2794     "PR by @johnnyshields, merged 2022-01-10"
[#2759]:https://github.com/puma/puma/pull/2759     "PR by @ob-stripe, merged 2021-12-11"
[#2731]:https://github.com/puma/puma/pull/2731     "PR by @baelter, merged 2021-11-02"
[#2341]:https://github.com/puma/puma/issues/2341   "Issue by @cjlarose, closed 2023-07-23"
[#2728]:https://github.com/puma/puma/pull/2728     "PR by @dalibor, merged 2021-10-31"
[#2733]:https://github.com/puma/puma/pull/2733     "PR by @ob-stripe, merged 2021-12-12"
[#2807]:https://github.com/puma/puma/pull/2807     "PR by @MSP-Greg, merged 2022-01-25"
[#2806]:https://github.com/puma/puma/issues/2806   "Issue by @olleolleolle, closed 2022-01-25"
[#2799]:https://github.com/puma/puma/pull/2799     "PR by @ags, merged 2022-01-22"
[#2785]:https://github.com/puma/puma/pull/2785     "PR by @MSP-Greg, merged 2022-01-02"
[#2757]:https://github.com/puma/puma/pull/2757     "PR by @MSP-Greg, merged 2021-11-24"
[#2745]:https://github.com/puma/puma/pull/2745     "PR by @MSP-Greg, merged 2021-11-03"
[#2742]:https://github.com/puma/puma/pull/2742     "PR by @MSP-Greg, merged 2021-12-12"
[#2730]:https://github.com/puma/puma/pull/2730     "PR by @kares, merged 2021-11-01"
[#2702]:https://github.com/puma/puma/pull/2702     "PR by @jacobherrington, merged 2021-09-21"
[#2610]:https://github.com/puma/puma/pull/2610     "PR by @ye-lin-aung, merged 2021-08-18"
[#2257]:https://github.com/puma/puma/issues/2257   "Issue by @nateberkopec, closed 2021-08-18"
[#2654]:https://github.com/puma/puma/pull/2654     "PR by @Roguelazer, merged 2021-09-07"
[#2651]:https://github.com/puma/puma/issues/2651   "Issue by @Roguelazer, closed 2021-09-07"
[#2689]:https://github.com/puma/puma/pull/2689     "PR by @jacobherrington, merged 2021-09-05"
[#2700]:https://github.com/puma/puma/pull/2700     "PR by @ioquatix, merged 2021-09-16"
[#2699]:https://github.com/puma/puma/issues/2699   "Issue by @ioquatix, closed 2021-09-16"
[#2690]:https://github.com/puma/puma/pull/2690     "PR by @doits, merged 2021-09-06"
[#2688]:https://github.com/puma/puma/pull/2688     "PR by @jdelStrother, merged 2021-09-03"
[#2687]:https://github.com/puma/puma/issues/2687   "Issue by @jdelStrother, closed 2021-09-03"
[#2675]:https://github.com/puma/puma/pull/2675     "PR by @devwout, merged 2021-09-08"
[#2657]:https://github.com/puma/puma/pull/2657     "PR by @olivierbellone, merged 2021-07-13"
[#2648]:https://github.com/puma/puma/pull/2648     "PR by @MSP-Greg, merged 2021-06-27"
[#1412]:https://github.com/puma/puma/issues/1412   "Issue by @x-yuri, closed 2021-06-27"
[#2586]:https://github.com/puma/puma/pull/2586     "PR by @MSP-Greg, merged 2021-05-26"
[#2569]:https://github.com/puma/puma/issues/2569   "Issue by @tarragon, closed 2021-05-26"
[#2643]:https://github.com/puma/puma/pull/2643     "PR by @MSP-Greg, merged 2021-06-27"
[#2638]:https://github.com/puma/puma/issues/2638   "Issue by @gingerlime, closed 2021-06-27"
[#2642]:https://github.com/puma/puma/pull/2642     "PR by @MSP-Greg, merged 2021-06-16"
[#2633]:https://github.com/puma/puma/pull/2633     "PR by @onlined, merged 2021-06-04"
[#2656]:https://github.com/puma/puma/pull/2656     "PR by @olivierbellone, merged 2021-07-07"
[#2666]:https://github.com/puma/puma/pull/2666     "PR by @MSP-Greg, merged 2021-07-25"
[#2630]:https://github.com/puma/puma/pull/2630     "PR by @seangoedecke, merged 2021-05-20"
[#2626]:https://github.com/puma/puma/issues/2626   "Issue by @rorymckinley, closed 2021-05-20"
[#2629]:https://github.com/puma/puma/pull/2629     "PR by @ye-lin-aung, merged 2021-05-20"
[#2628]:https://github.com/puma/puma/pull/2628     "PR by @wjordan, merged 2021-05-20"
[#2625]:https://github.com/puma/puma/issues/2625   "Issue by @jarthod, closed 2021-05-11"
[#2564]:https://github.com/puma/puma/pull/2564     "PR by @MSP-Greg, merged 2021-04-24"
[#2526]:https://github.com/puma/puma/issues/2526   "Issue by @nerdrew, closed 2021-04-24"
[#2559]:https://github.com/puma/puma/pull/2559     "PR by @ylecuyer, merged 2021-03-11"
[#2528]:https://github.com/puma/puma/issues/2528   "Issue by @cjlarose, closed 2021-03-11"
[#2565]:https://github.com/puma/puma/pull/2565     "PR by @CGA1123, merged 2021-03-09"
[#2534]:https://github.com/puma/puma/issues/2534   "Issue by @nateberkopec, closed 2021-03-09"
[#2563]:https://github.com/puma/puma/pull/2563     "PR by @MSP-Greg, merged 2021-03-06"
[#2504]:https://github.com/puma/puma/issues/2504   "Issue by @fsateler, closed 2021-03-06"
[#2591]:https://github.com/puma/puma/pull/2591     "PR by @MSP-Greg, merged 2021-05-05"
[#2572]:https://github.com/puma/puma/issues/2572   "Issue by @josef-krabath, closed 2021-05-05"
[#2613]:https://github.com/puma/puma/pull/2613     "PR by @smcgivern, merged 2021-04-27"
[#2605]:https://github.com/puma/puma/pull/2605     "PR by @pascalbetz, merged 2021-04-26"
[#2584]:https://github.com/puma/puma/issues/2584   "Issue by @kaorihinata, closed 2021-04-26"
[#2607]:https://github.com/puma/puma/pull/2607     "PR by @calvinxiao, merged 2021-04-23"
[#2552]:https://github.com/puma/puma/issues/2552   "Issue by @feliperaul, closed 2021-05-24"
[#2606]:https://github.com/puma/puma/pull/2606     "PR by @wjordan, merged 2021-04-20"
[#2574]:https://github.com/puma/puma/issues/2574   "Issue by @darkhelmet, closed 2021-04-20"
[#2567]:https://github.com/puma/puma/pull/2567     "PR by @kddnewton, merged 2021-04-19"
[#2566]:https://github.com/puma/puma/issues/2566   "Issue by @kddnewton, closed 2021-04-19"
[#2596]:https://github.com/puma/puma/pull/2596     "PR by @MSP-Greg, merged 2021-04-18"
[#2588]:https://github.com/puma/puma/pull/2588     "PR by @dentarg, merged 2021-04-02"
[#2556]:https://github.com/puma/puma/issues/2556   "Issue by @gamecreature, closed 2021-04-02"
[#2585]:https://github.com/puma/puma/pull/2585     "PR by @MSP-Greg, merged 2021-03-26"
[#2583]:https://github.com/puma/puma/issues/2583   "Issue by @jboler, closed 2021-03-26"
[#2609]:https://github.com/puma/puma/pull/2609     "PR by @calvinxiao, merged 2021-04-26"
[#2590]:https://github.com/puma/puma/pull/2590     "PR by @calvinxiao, merged 2021-04-05"
[#2600]:https://github.com/puma/puma/pull/2600     "PR by @wjordan, merged 2021-04-30"
[#2579]:https://github.com/puma/puma/pull/2579     "PR by @ghiculescu, merged 2021-03-17"
[#2553]:https://github.com/puma/puma/pull/2553     "PR by @olivierbellone, merged 2021-02-10"
[#2557]:https://github.com/puma/puma/pull/2557     "PR by @cjlarose, merged 2021-02-22"
[#2550]:https://github.com/puma/puma/pull/2550     "PR by @MSP-Greg, merged 2021-02-05"
[#2547]:https://github.com/puma/puma/pull/2547     "PR by @wildmaples, merged 2021-02-03"
[#2543]:https://github.com/puma/puma/pull/2543     "PR by @MSP-Greg, merged 2021-02-01"
[#2549]:https://github.com/puma/puma/pull/2549     "PR by @nmb, merged 2021-02-04"
[#2519]:https://github.com/puma/puma/pull/2519     "PR by @MSP-Greg, merged 2021-01-26"
[#2522]:https://github.com/puma/puma/pull/2522     "PR by @jcmfernandes, merged 2021-01-12"
[#2490]:https://github.com/puma/puma/pull/2490     "PR by @Bonias, merged 2020-12-07"
[#2486]:https://github.com/puma/puma/pull/2486     "PR by @karloscodes, merged 2020-12-02"
[#2535]:https://github.com/puma/puma/pull/2535     "PR by @MSP-Greg, merged 2021-01-27"
[#2529]:https://github.com/puma/puma/pull/2529     "PR by @MSP-Greg, merged 2021-01-24"
[#2533]:https://github.com/puma/puma/pull/2533     "PR by @MSP-Greg, merged 2021-01-24"
[#1953]:https://github.com/puma/puma/issues/1953   "Issue by @nateberkopec, closed 2020-12-01"
[#2516]:https://github.com/puma/puma/pull/2516     "PR by @cjlarose, merged 2020-12-17"
[#2520]:https://github.com/puma/puma/pull/2520     "PR by @dentarg, merged 2021-01-04"
[#2521]:https://github.com/puma/puma/pull/2521     "PR by @ojab, merged 2021-01-04"
[#2531]:https://github.com/puma/puma/pull/2531     "PR by @wjordan, merged 2021-01-19"
[#2510]:https://github.com/puma/puma/pull/2510     "PR by @micke, merged 2020-12-10"
[#2472]:https://github.com/puma/puma/pull/2472     "PR by @karloscodes, merged 2020-11-02"
[#2438]:https://github.com/puma/puma/pull/2438     "PR by @ekohl, merged 2020-10-26"
[#2406]:https://github.com/puma/puma/pull/2406     "PR by @fdel15, merged 2020-10-19"
[#2449]:https://github.com/puma/puma/pull/2449     "PR by @MSP-Greg, merged 2020-10-28"
[#2362]:https://github.com/puma/puma/pull/2362     "PR by @ekohl, merged 2020-11-10"
[#2485]:https://github.com/puma/puma/pull/2485     "PR by @elct9620, merged 2020-11-18"
[#2489]:https://github.com/puma/puma/pull/2489     "PR by @MSP-Greg, merged 2020-11-27"
[#2487]:https://github.com/puma/puma/pull/2487     "PR by @MSP-Greg, merged 2020-11-17"
[#2477]:https://github.com/puma/puma/pull/2477     "PR by @MSP-Greg, merged 2020-11-16"
[#2475]:https://github.com/puma/puma/pull/2475     "PR by @nateberkopec, merged 2020-11-02"
[#2439]:https://github.com/puma/puma/pull/2439     "PR by @kuei0221, merged 2020-10-26"
[#2460]:https://github.com/puma/puma/pull/2460     "PR by @cjlarose, merged 2020-10-27"
[#2473]:https://github.com/puma/puma/pull/2473     "PR by @cjlarose, merged 2020-11-01"
[#2479]:https://github.com/puma/puma/pull/2479     "PR by @cjlarose, merged 2020-11-10"
[#2495]:https://github.com/puma/puma/pull/2495     "PR by @JuanitoFatas, merged 2020-11-27"
[#2461]:https://github.com/puma/puma/pull/2461     "PR by @cjlarose, merged 2020-10-27"
[#2454]:https://github.com/puma/puma/issues/2454   "Issue by @majksner, closed 2020-10-27"
[#2432]:https://github.com/puma/puma/pull/2432     "PR by @MSP-Greg, merged 2020-10-25"
[#2442]:https://github.com/puma/puma/pull/2442     "PR by @wjordan, merged 2020-10-22"
[#2427]:https://github.com/puma/puma/pull/2427     "PR by @cjlarose, merged 2020-10-20"
[#2018]:https://github.com/puma/puma/issues/2018   "Issue by @gingerlime, closed 2020-10-20"
[#2435]:https://github.com/puma/puma/pull/2435     "PR by @wjordan, merged 2020-10-20"
[#2431]:https://github.com/puma/puma/pull/2431     "PR by @wjordan, merged 2020-10-16"
[#2212]:https://github.com/puma/puma/issues/2212   "Issue by @junaruga, closed 2020-10-16"
[#2409]:https://github.com/puma/puma/pull/2409     "PR by @fliiiix, merged 2020-10-03"
[#2448]:https://github.com/puma/puma/pull/2448     "PR by @MSP-Greg, merged 2020-10-25"
[#2450]:https://github.com/puma/puma/pull/2450     "PR by @MSP-Greg, merged 2020-10-25"
[#2419]:https://github.com/puma/puma/pull/2419     "PR by @MSP-Greg, merged 2020-10-09"
[#2279]:https://github.com/puma/puma/pull/2279     "PR by @wjordan, merged 2020-10-06"
[#2412]:https://github.com/puma/puma/pull/2412     "PR by @MSP-Greg, merged 2020-10-06"
[#2405]:https://github.com/puma/puma/pull/2405     "PR by @MSP-Greg, merged 2020-10-05"
[#2408]:https://github.com/puma/puma/pull/2408     "PR by @fliiiix, merged 2020-10-03"
[#2374]:https://github.com/puma/puma/pull/2374     "PR by @cjlarose, merged 2020-09-29"
[#2389]:https://github.com/puma/puma/pull/2389     "PR by @MSP-Greg, merged 2020-09-29"
[#2381]:https://github.com/puma/puma/pull/2381     "PR by @joergschray, merged 2020-09-24"
[#2271]:https://github.com/puma/puma/pull/2271     "PR by @wjordan, merged 2020-09-24"
[#2377]:https://github.com/puma/puma/pull/2377     "PR by @cjlarose, merged 2020-09-23"
[#2376]:https://github.com/puma/puma/pull/2376     "PR by @alexeevit, merged 2020-09-22"
[#2372]:https://github.com/puma/puma/pull/2372     "PR by @ahorek, merged 2020-09-22"
[#2384]:https://github.com/puma/puma/pull/2384     "PR by @schneems, merged 2020-09-27"
[#2375]:https://github.com/puma/puma/pull/2375     "PR by @MSP-Greg, merged 2020-09-23"
[#2373]:https://github.com/puma/puma/pull/2373     "PR by @MSP-Greg, merged 2020-09-23"
[#2305]:https://github.com/puma/puma/pull/2305     "PR by @MSP-Greg, merged 2020-09-14"
[#2099]:https://github.com/puma/puma/pull/2099     "PR by @wjordan, merged 2020-05-11"
[#2079]:https://github.com/puma/puma/pull/2079     "PR by @ayufan, merged 2020-05-11"
[#2093]:https://github.com/puma/puma/pull/2093     "PR by @schneems, merged 2019-12-18"
[#2256]:https://github.com/puma/puma/pull/2256     "PR by @nateberkopec, merged 2020-05-11"
[#2054]:https://github.com/puma/puma/pull/2054     "PR by @composerinteralia, merged 2019-11-11"
[#2106]:https://github.com/puma/puma/pull/2106     "PR by @ylecuyer, merged 2020-02-11"
[#2167]:https://github.com/puma/puma/pull/2167     "PR by @ChrisBr, closed 2020-07-06"
[#2344]:https://github.com/puma/puma/pull/2344     "PR by @dentarg, merged 2020-08-26"
[#2203]:https://github.com/puma/puma/pull/2203     "PR by @zanker-stripe, merged 2020-03-31"
[#2220]:https://github.com/puma/puma/pull/2220     "PR by @wjordan, merged 2020-04-14"
[#2238]:https://github.com/puma/puma/pull/2238     "PR by @sthirugn, merged 2020-05-07"
[#2086]:https://github.com/puma/puma/pull/2086     "PR by @bdewater, merged 2019-12-17"
[#2253]:https://github.com/puma/puma/pull/2253     "PR by @schneems, merged 2020-05-11"
[#2288]:https://github.com/puma/puma/pull/2288     "PR by @FTLam11, merged 2020-06-02"
[#1487]:https://github.com/puma/puma/pull/1487     "PR by @jxa, merged 2018-05-09"
[#2143]:https://github.com/puma/puma/pull/2143     "PR by @jalevin, merged 2020-04-21"
[#2169]:https://github.com/puma/puma/pull/2169     "PR by @nateberkopec, merged 2020-03-10"
[#2170]:https://github.com/puma/puma/pull/2170     "PR by @nateberkopec, merged 2020-03-10"
[#2076]:https://github.com/puma/puma/pull/2076     "PR by @drews256, merged 2020-02-27"
[#2022]:https://github.com/puma/puma/pull/2022     "PR by @olleolleolle, merged 2019-11-11"
[#2300]:https://github.com/puma/puma/pull/2300     "PR by @alexeevit, merged 2020-07-06"
[#2269]:https://github.com/puma/puma/pull/2269     "PR by @MSP-Greg, merged 2020-08-31"
[#2312]:https://github.com/puma/puma/pull/2312     "PR by @MSP-Greg, merged 2020-07-20"
[#2338]:https://github.com/puma/puma/issues/2338   "Issue by @micahhainlinestitchfix, closed 2020-08-18"
[#2116]:https://github.com/puma/puma/pull/2116     "PR by @MSP-Greg, merged 2020-05-15"
[#2074]:https://github.com/puma/puma/issues/2074   "Issue by @jchristie55332, closed 2020-02-19"
[#2211]:https://github.com/puma/puma/pull/2211     "PR by @MSP-Greg, merged 2020-03-30"
[#2069]:https://github.com/puma/puma/pull/2069     "PR by @MSP-Greg, merged 2019-11-09"
[#2112]:https://github.com/puma/puma/pull/2112     "PR by @wjordan, merged 2020-03-03"
[#1893]:https://github.com/puma/puma/pull/1893     "PR by @seven1m, merged 2020-02-18"
[#2119]:https://github.com/puma/puma/pull/2119     "PR by @wjordan, merged 2020-02-20"
[#2121]:https://github.com/puma/puma/pull/2121     "PR by @wjordan, merged 2020-02-21"
[#2154]:https://github.com/puma/puma/pull/2154     "PR by @cjlarose, merged 2020-03-10"
[#1551]:https://github.com/puma/puma/issues/1551   "Issue by @austinthecoder, closed 2020-03-10"
[#2198]:https://github.com/puma/puma/pull/2198     "PR by @eregon, merged 2020-03-24"
[#2216]:https://github.com/puma/puma/pull/2216     "PR by @praboud-stripe, merged 2020-04-06"
[#2122]:https://github.com/puma/puma/pull/2122     "PR by @wjordan, merged 2020-04-10"
[#2177]:https://github.com/puma/puma/issues/2177   "Issue by @GuiTeK, closed 2020-04-08"
[#2221]:https://github.com/puma/puma/pull/2221     "PR by @wjordan, merged 2020-04-17"
[#2233]:https://github.com/puma/puma/pull/2233     "PR by @ayufan, merged 2020-04-25"
[#2234]:https://github.com/puma/puma/pull/2234     "PR by @wjordan, merged 2020-04-30"
[#2225]:https://github.com/puma/puma/issues/2225   "Issue by @nateberkopec, closed 2020-04-27"
[#2267]:https://github.com/puma/puma/pull/2267     "PR by @wjordan, merged 2020-05-20"
[#2287]:https://github.com/puma/puma/pull/2287     "PR by @eugeneius, merged 2020-05-31"
[#2317]:https://github.com/puma/puma/pull/2317     "PR by @MSP-Greg, merged 2020-09-01"
[#2319]:https://github.com/puma/puma/issues/2319   "Issue by @AlexWayfer, closed 2020-09-03"
[#2326]:https://github.com/puma/puma/pull/2326     "PR by @rkistner, closed 2020-09-04"
[#2299]:https://github.com/puma/puma/issues/2299   "Issue by @JohnPhillips31416, closed 2020-09-17"
[#2095]:https://github.com/puma/puma/pull/2095     "PR by @bdewater, merged 2019-12-25"
[#2102]:https://github.com/puma/puma/pull/2102     "PR by @bdewater, merged 2020-02-07"
[#2111]:https://github.com/puma/puma/pull/2111     "PR by @wjordan, merged 2020-02-20"
[#1980]:https://github.com/puma/puma/pull/1980     "PR by @nateberkopec, merged 2020-02-27"
[#2189]:https://github.com/puma/puma/pull/2189     "PR by @jkowens, merged 2020-03-19"
[#2124]:https://github.com/puma/puma/pull/2124     "PR by @wjordan, merged 2020-04-14"
[#2223]:https://github.com/puma/puma/pull/2223     "PR by @wjordan, merged 2020-04-20"
[#2239]:https://github.com/puma/puma/pull/2239     "PR by @wjordan, merged 2020-05-15"
[#2496]:https://github.com/puma/puma/pull/2496     "PR by @TheRusskiy, merged 2020-11-30"
[#2304]:https://github.com/puma/puma/issues/2304   "Issue by @mpeltomaa, closed 2020-09-05"
[#2132]:https://github.com/puma/puma/issues/2132   "Issue by @bmclean, closed 2020-02-28"
[#2010]:https://github.com/puma/puma/pull/2010     "PR by @nateberkopec, merged 2019-10-07"
[#2012]:https://github.com/puma/puma/pull/2012     "PR by @headius, merged 2019-10-07"
[#2046]:https://github.com/puma/puma/pull/2046     "PR by @composerinteralia, merged 2019-10-21"
[#2052]:https://github.com/puma/puma/pull/2052     "PR by @composerinteralia, merged 2019-11-02"
[#1564]:https://github.com/puma/puma/issues/1564   "Issue by @perlun, closed 2019-10-07"
[#2035]:https://github.com/puma/puma/pull/2035     "PR by @AndrewSpeed, merged 2019-10-18"
[#2048]:https://github.com/puma/puma/pull/2048     "PR by @hahmed, merged 2019-10-21"
[#2050]:https://github.com/puma/puma/pull/2050     "PR by @olleolleolle, merged 2019-10-25"
[#1842]:https://github.com/puma/puma/issues/1842   "Issue by @nateberkopec, closed 2019-09-18"
[#1988]:https://github.com/puma/puma/issues/1988   "Issue by @mcg, closed 2019-10-01"
[#1986]:https://github.com/puma/puma/issues/1986   "Issue by @flaminestone, closed 2019-10-01"
[#1994]:https://github.com/puma/puma/issues/1994   "Issue by @LimeBlast, closed 2019-10-01"
[#2006]:https://github.com/puma/puma/pull/2006     "PR by @nateberkopec, merged 2019-10-01"
[#1222]:https://github.com/puma/puma/issues/1222   "Issue by @seanmckinley, closed 2019-10-04"
[#1885]:https://github.com/puma/puma/pull/1885     "PR by @spk, merged 2019-08-10"
[#1934]:https://github.com/puma/puma/pull/1934     "PR by @zarelit, merged 2019-08-28"
[#1105]:https://github.com/puma/puma/pull/1105     "PR by @daveallie, merged 2019-09-02"
[#1786]:https://github.com/puma/puma/pull/1786     "PR by @evanphx, merged 2019-09-11"
[#1320]:https://github.com/puma/puma/pull/1320     "PR by @nateberkopec, merged 2019-09-12"
[#1968]:https://github.com/puma/puma/pull/1968     "PR by @nateberkopec, merged 2019-09-15"
[#1908]:https://github.com/puma/puma/pull/1908     "PR by @MSP-Greg, merged 2019-08-23"
[#1952]:https://github.com/puma/puma/pull/1952     "PR by @MSP-Greg, merged 2019-09-19"
[#1941]:https://github.com/puma/puma/pull/1941     "PR by @MSP-Greg, merged 2019-09-02"
[#1961]:https://github.com/puma/puma/pull/1961     "PR by @nateberkopec, merged 2019-09-11"
[#1970]:https://github.com/puma/puma/pull/1970     "PR by @MSP-Greg, merged 2019-09-18"
[#1946]:https://github.com/puma/puma/pull/1946     "PR by @nateberkopec, merged 2019-09-02"
[#1831]:https://github.com/puma/puma/pull/1831     "PR by @spk, merged 2019-07-27"
[#1816]:https://github.com/puma/puma/pull/1816     "PR by @ylecuyer, merged 2019-08-01"
[#1844]:https://github.com/puma/puma/pull/1844     "PR by @ylecuyer, merged 2019-08-01"
[#1836]:https://github.com/puma/puma/pull/1836     "PR by @MSP-Greg, merged 2019-08-06"
[#1887]:https://github.com/puma/puma/pull/1887     "PR by @MSP-Greg, merged 2019-08-06"
[#1812]:https://github.com/puma/puma/pull/1812     "PR by @kou, merged 2019-08-03"
[#1491]:https://github.com/puma/puma/pull/1491     "PR by @olleolleolle, merged 2019-07-17"
[#1837]:https://github.com/puma/puma/pull/1837     "PR by @montanalow, merged 2019-07-25"
[#1857]:https://github.com/puma/puma/pull/1857     "PR by @Jesus, merged 2019-08-03"
[#1822]:https://github.com/puma/puma/pull/1822     "PR by @Jesus, merged 2019-08-01"
[#1863]:https://github.com/puma/puma/pull/1863     "PR by @dzunk, merged 2019-08-04"
[#1838]:https://github.com/puma/puma/pull/1838     "PR by @bogn83, merged 2019-07-14"
[#1882]:https://github.com/puma/puma/pull/1882     "PR by @okuramasafumi, merged 2019-08-06"
[#1848]:https://github.com/puma/puma/pull/1848     "PR by @nateberkopec, merged 2019-07-16"
[#1847]:https://github.com/puma/puma/pull/1847     "PR by @nateberkopec, merged 2019-07-16"
[#1846]:https://github.com/puma/puma/pull/1846     "PR by @nateberkopec, merged 2019-07-16"
[#1853]:https://github.com/puma/puma/pull/1853     "PR by @Jesus, merged 2019-07-18"
[#1850]:https://github.com/puma/puma/pull/1850     "PR by @nateberkopec, merged 2019-07-27"
[#1866]:https://github.com/puma/puma/pull/1866     "PR by @josacar, merged 2019-07-28"
[#1870]:https://github.com/puma/puma/pull/1870     "PR by @MSP-Greg, merged 2019-07-30"
[#1872]:https://github.com/puma/puma/pull/1872     "PR by @MSP-Greg, merged 2019-07-30"
[#1833]:https://github.com/puma/puma/issues/1833   "Issue by @julik, closed 2019-07-09"
[#1888]:https://github.com/puma/puma/pull/1888     "PR by @ClikeX, merged 2019-08-06"
[#1829]:https://github.com/puma/puma/pull/1829     "PR by @Fudoshiki, merged 2019-07-09"
[#1832]:https://github.com/puma/puma/pull/1832     "PR by @MSP-Greg, merged 2019-07-08"
[#1827]:https://github.com/puma/puma/pull/1827     "PR by @amrrbakry, merged 2019-06-27"
[#1562]:https://github.com/puma/puma/pull/1562     "PR by @skrobul, merged 2019-02-20"
[#1569]:https://github.com/puma/puma/pull/1569     "PR by @rianmcguire, merged 2019-02-20"
[#1648]:https://github.com/puma/puma/pull/1648     "PR by @wjordan, merged 2019-02-20"
[#1691]:https://github.com/puma/puma/pull/1691     "PR by @kares, merged 2019-02-20"
[#1716]:https://github.com/puma/puma/pull/1716     "PR by @mdkent, merged 2019-02-20"
[#1690]:https://github.com/puma/puma/pull/1690     "PR by @mic-kul, merged 2019-03-11"
[#1689]:https://github.com/puma/puma/pull/1689     "PR by @michaelherold, merged 2019-03-11"
[#1728]:https://github.com/puma/puma/pull/1728     "PR by @evanphx, merged 2019-03-20"
[#1824]:https://github.com/puma/puma/pull/1824     "PR by @spk, merged 2019-06-24"
[#1685]:https://github.com/puma/puma/pull/1685     "PR by @mainameiz, merged 2019-02-20"
[#1808]:https://github.com/puma/puma/pull/1808     "PR by @schneems, merged 2019-06-10"
[#1508]:https://github.com/puma/puma/pull/1508     "PR by @florin555, merged 2019-02-20"
[#1650]:https://github.com/puma/puma/pull/1650     "PR by @adam101, merged 2019-02-20"
[#1655]:https://github.com/puma/puma/pull/1655     "PR by @mipearson, merged 2019-02-20"
[#1671]:https://github.com/puma/puma/pull/1671     "PR by @eric-norcross, merged 2019-02-20"
[#1583]:https://github.com/puma/puma/pull/1583     "PR by @chwevans, merged 2019-02-20"
[#1773]:https://github.com/puma/puma/pull/1773     "PR by @enebo, merged 2019-04-14"
[#1731]:https://github.com/puma/puma/issues/1731   "Issue by @Fudoshiki, closed 2019-03-20"
[#1803]:https://github.com/puma/puma/pull/1803     "PR by @Jesus, merged 2019-05-28"
[#1741]:https://github.com/puma/puma/pull/1741     "PR by @MSP-Greg, merged 2019-03-19"
[#1674]:https://github.com/puma/puma/issues/1674   "Issue by @atitan, closed 2019-06-12"
[#1720]:https://github.com/puma/puma/issues/1720   "Issue by @voxik, closed 2019-03-20"
[#1730]:https://github.com/puma/puma/issues/1730   "Issue by @nearapogee, closed 2019-07-16"
[#1755]:https://github.com/puma/puma/issues/1755   "Issue by @vbalazs, closed 2019-07-26"
[#1649]:https://github.com/puma/puma/pull/1649     "PR by @schneems, merged 2018-10-17"
[#1607]:https://github.com/puma/puma/pull/1607     "PR by @harmdewit, merged 2018-08-15"
[#1700]:https://github.com/puma/puma/pull/1700     "PR by @schneems, merged 2019-01-05"
[#1630]:https://github.com/puma/puma/pull/1630     "PR by @eregon, merged 2018-09-11"
[#1478]:https://github.com/puma/puma/pull/1478     "PR by @eallison91, merged 2018-05-09"
[#1604]:https://github.com/puma/puma/pull/1604     "PR by @schneems, merged 2018-07-02"
[#1579]:https://github.com/puma/puma/pull/1579     "PR by @schneems, merged 2018-06-14"
[#1506]:https://github.com/puma/puma/pull/1506     "PR by @dekellum, merged 2018-05-09"
[#1563]:https://github.com/puma/puma/pull/1563     "PR by @dannyfallon, merged 2018-05-01"
[#1557]:https://github.com/puma/puma/pull/1557     "PR by @swrobel, merged 2018-05-09"
[#1529]:https://github.com/puma/puma/pull/1529     "PR by @desnudopenguino, merged 2018-03-20"
[#1532]:https://github.com/puma/puma/pull/1532     "PR by @schneems, merged 2018-03-21"
[#1482]:https://github.com/puma/puma/pull/1482     "PR by @shayonj, merged 2018-03-19"
[#1511]:https://github.com/puma/puma/pull/1511     "PR by @jemiam, merged 2018-03-19"
[#1545]:https://github.com/puma/puma/pull/1545     "PR by @hoshinotsuyoshi, merged 2018-03-28"
[#1550]:https://github.com/puma/puma/pull/1550     "PR by @eileencodes, merged 2018-03-29"
[#1553]:https://github.com/puma/puma/pull/1553     "PR by @eugeneius, merged 2018-04-02"
[#1510]:https://github.com/puma/puma/issues/1510   "Issue by @vincentwoo, closed 2018-03-06"
[#1524]:https://github.com/puma/puma/pull/1524     "PR by @tuwukee, closed 2018-03-06"
[#1507]:https://github.com/puma/puma/issues/1507   "Issue by @vincentwoo, closed 2018-03-19"
[#1483]:https://github.com/puma/puma/issues/1483   "Issue by @igravious, closed 2018-03-06"
[#1502]:https://github.com/puma/puma/issues/1502   "Issue by @vincentwoo, closed 2020-03-09"
[#1403]:https://github.com/puma/puma/pull/1403     "PR by @eileencodes, merged 2017-10-04"
[#1435]:https://github.com/puma/puma/pull/1435     "PR by @juliancheal, merged 2017-10-11"
[#1340]:https://github.com/puma/puma/pull/1340     "PR by @ViliusLuneckas, merged 2017-10-16"
[#1434]:https://github.com/puma/puma/pull/1434     "PR by @jumbosushi, merged 2017-10-10"
[#1436]:https://github.com/puma/puma/pull/1436     "PR by @luislavena, merged 2017-10-11"
[#1418]:https://github.com/puma/puma/pull/1418     "PR by @eileencodes, merged 2017-09-22"
[#1416]:https://github.com/puma/puma/pull/1416     "PR by @hiimtaylorjones, merged 2017-09-22"
[#1409]:https://github.com/puma/puma/pull/1409     "PR by @olleolleolle, merged 2017-09-13"
[#1427]:https://github.com/puma/puma/issues/1427   "Issue by @garybernhardt, closed 2017-10-04"
[#1430]:https://github.com/puma/puma/pull/1430     "PR by @MSP-Greg, merged 2017-10-09"
[#1429]:https://github.com/puma/puma/pull/1429     "PR by @perlun, merged 2017-10-09"
[#1455]:https://github.com/puma/puma/pull/1455     "PR by @perlun, merged 2017-11-16"
[#1425]:https://github.com/puma/puma/pull/1425     "PR by @vizcay, merged 2017-10-01"
[#1452]:https://github.com/puma/puma/pull/1452     "PR by @eprothro, merged 2017-11-16"
[#1439]:https://github.com/puma/puma/pull/1439     "PR by @MSP-Greg, merged 2017-10-16"
[#1442]:https://github.com/puma/puma/pull/1442     "PR by @MSP-Greg, merged 2017-10-19"
[#1464]:https://github.com/puma/puma/pull/1464     "PR by @MSP-Greg, merged 2017-11-20"
[#1384]:https://github.com/puma/puma/pull/1384     "PR by @noahgibbs, merged 2017-08-03"
[#1111]:https://github.com/puma/puma/pull/1111     "PR by @alexlance, merged 2017-06-04"
[#1392]:https://github.com/puma/puma/pull/1392     "PR by @hoffm, merged 2017-08-11"
[#1347]:https://github.com/puma/puma/pull/1347     "PR by @NikolayRys, merged 2017-06-28"
[#1334]:https://github.com/puma/puma/pull/1334     "PR by @respire, merged 2017-06-13"
[#1383]:https://github.com/puma/puma/pull/1383     "PR by @schneems, merged 2017-08-02"
[#1368]:https://github.com/puma/puma/pull/1368     "PR by @bongole, merged 2017-08-03"
[#1318]:https://github.com/puma/puma/pull/1318     "PR by @nateberkopec, merged 2017-08-03"
[#1376]:https://github.com/puma/puma/pull/1376     "PR by @pat, merged 2017-08-03"
[#1388]:https://github.com/puma/puma/pull/1388     "PR by @nateberkopec, merged 2017-08-08"
[#1390]:https://github.com/puma/puma/pull/1390     "PR by @junaruga, merged 2017-08-16"
[#1391]:https://github.com/puma/puma/pull/1391     "PR by @junaruga, merged 2017-08-16"
[#1385]:https://github.com/puma/puma/pull/1385     "PR by @grosser, merged 2017-08-16"
[#1377]:https://github.com/puma/puma/pull/1377     "PR by @shayonj, merged 2017-08-16"
[#1337]:https://github.com/puma/puma/pull/1337     "PR by @shayonj, merged 2017-08-16"
[#1325]:https://github.com/puma/puma/pull/1325     "PR by @palkan, merged 2017-06-04"
[#1395]:https://github.com/puma/puma/pull/1395     "PR by @junaruga, merged 2017-08-16"
[#1367]:https://github.com/puma/puma/issues/1367   "Issue by @dekellum, closed 2017-08-17"
[#1314]:https://github.com/puma/puma/pull/1314     "PR by @grosser, merged 2017-06-02"
[#1311]:https://github.com/puma/puma/pull/1311     "PR by @grosser, merged 2017-06-02"
[#1313]:https://github.com/puma/puma/pull/1313     "PR by @grosser, merged 2017-06-03"
[#1260]:https://github.com/puma/puma/pull/1260     "PR by @grosser, merged 2017-04-11"
[#1278]:https://github.com/puma/puma/pull/1278     "PR by @evanphx, merged 2017-04-28"
[#1306]:https://github.com/puma/puma/pull/1306     "PR by @jules2689, merged 2017-05-31"
[#1274]:https://github.com/puma/puma/pull/1274     "PR by @evanphx, merged 2017-05-01"
[#1261]:https://github.com/puma/puma/pull/1261     "PR by @jacksonrayhamilton, merged 2017-04-07"
[#1259]:https://github.com/puma/puma/pull/1259     "PR by @jacksonrayhamilton, merged 2017-04-07"
[#1248]:https://github.com/puma/puma/pull/1248     "PR by @davidarnold, merged 2017-04-18"
[#1277]:https://github.com/puma/puma/pull/1277     "PR by @schneems, merged 2017-05-01"
[#1290]:https://github.com/puma/puma/pull/1290     "PR by @schneems, merged 2017-05-12"
[#1285]:https://github.com/puma/puma/pull/1285     "PR by @fmauNeko, merged 2017-05-12"
[#1282]:https://github.com/puma/puma/pull/1282     "PR by @grosser, merged 2017-05-09"
[#1294]:https://github.com/puma/puma/pull/1294     "PR by @masry707, merged 2017-05-15"
[#1206]:https://github.com/puma/puma/pull/1206     "PR by @NikolayRys, closed 2017-06-27"
[#1241]:https://github.com/puma/puma/issues/1241   "Issue by @renchap, closed 2017-03-14"
[#1239]:https://github.com/puma/puma/pull/1239     "PR by @schneems, merged 2017-03-10"
[#1234]:https://github.com/puma/puma/pull/1234     "PR by @schneems, merged 2017-03-09"
[#1226]:https://github.com/puma/puma/pull/1226     "PR by @eileencodes, merged 2017-03-09"
[#1227]:https://github.com/puma/puma/pull/1227     "PR by @sirupsen, merged 2017-02-27"
[#1213]:https://github.com/puma/puma/pull/1213     "PR by @junaruga, merged 2017-02-28"
[#1182]:https://github.com/puma/puma/issues/1182   "Issue by @brunowego, closed 2017-02-09"
[#1203]:https://github.com/puma/puma/pull/1203     "PR by @twalpole, merged 2017-02-09"
[#1129]:https://github.com/puma/puma/pull/1129     "PR by @chtitux, merged 2016-12-12"
[#1165]:https://github.com/puma/puma/pull/1165     "PR by @sriedel, merged 2016-12-21"
[#1175]:https://github.com/puma/puma/pull/1175     "PR by @jemiam, merged 2016-12-21"
[#1068]:https://github.com/puma/puma/pull/1068     "PR by @junaruga, merged 2016-09-05"
[#1091]:https://github.com/puma/puma/pull/1091     "PR by @frodsan, merged 2016-09-17"
[#1088]:https://github.com/puma/puma/pull/1088     "PR by @frodsan, merged 2016-11-20"
[#1160]:https://github.com/puma/puma/pull/1160     "PR by @frodsan, merged 2016-11-24"
[#1169]:https://github.com/puma/puma/pull/1169     "PR by @scbrubaker02, merged 2016-12-12"
[#1061]:https://github.com/puma/puma/pull/1061     "PR by @michaelsauter, merged 2016-09-05"
[#1036]:https://github.com/puma/puma/issues/1036   "Issue by @matobinder, closed 2016-08-03"
[#1120]:https://github.com/puma/puma/pull/1120     "PR by @prathamesh-sonpatki, merged 2016-11-21"
[#1178]:https://github.com/puma/puma/pull/1178     "PR by @Koronen, merged 2016-12-21"
[#1002]:https://github.com/puma/puma/issues/1002   "Issue by @mattyb, closed 2016-07-26"
[#1063]:https://github.com/puma/puma/issues/1063   "Issue by @mperham, closed 2016-09-05"
[#1089]:https://github.com/puma/puma/issues/1089   "Issue by @AdamBialas, closed 2016-09-17"
[#1114]:https://github.com/puma/puma/pull/1114     "PR by @sj26, merged 2016-12-13"
[#1110]:https://github.com/puma/puma/pull/1110     "PR by @montdidier, merged 2016-12-12"
[#1135]:https://github.com/puma/puma/pull/1135     "PR by @jkraemer, merged 2016-11-19"
[#1081]:https://github.com/puma/puma/pull/1081     "PR by @frodsan, merged 2016-09-08"
[#1138]:https://github.com/puma/puma/pull/1138     "PR by @skull-squadron, merged 2016-12-13"
[#1118]:https://github.com/puma/puma/pull/1118     "PR by @hiroara, merged 2016-11-20"
[#1075]:https://github.com/puma/puma/issues/1075   "Issue by @pvalena, closed 2016-09-06"
[#932]:https://github.com/puma/puma/issues/932     "Issue by @everplays, closed 2016-07-24"
[#519]:https://github.com/puma/puma/issues/519     "Issue by @tmornini, closed 2016-07-25"
[#828]:https://github.com/puma/puma/issues/828     "Issue by @Zapotek, closed 2016-07-24"
[#984]:https://github.com/puma/puma/issues/984     "Issue by @erichmenge, closed 2016-07-24"
[#1028]:https://github.com/puma/puma/issues/1028   "Issue by @matobinder, closed 2016-07-24"
[#1023]:https://github.com/puma/puma/issues/1023   "Issue by @fera2k, closed 2016-07-24"
[#1027]:https://github.com/puma/puma/issues/1027   "Issue by @rosenfeld, closed 2016-07-24"
[#925]:https://github.com/puma/puma/issues/925     "Issue by @lokenmakwana, closed 2016-07-24"
[#911]:https://github.com/puma/puma/issues/911     "Issue by @veganstraightedge, closed 2016-07-24"
[#620]:https://github.com/puma/puma/issues/620     "Issue by @javanthropus, closed 2016-07-25"
[#778]:https://github.com/puma/puma/issues/778     "Issue by @niedhui, closed 2016-07-24"
[#1021]:https://github.com/puma/puma/pull/1021     "PR by @sarahzrf, merged 2016-07-20"
[#1022]:https://github.com/puma/puma/issues/1022   "Issue by @AKovtunov, closed 2017-08-16"
[#958]:https://github.com/puma/puma/issues/958     "Issue by @lalitlogical, closed 2016-04-23"
[#782]:https://github.com/puma/puma/issues/782     "Issue by @Tonkpils, closed 2016-07-19"
[#1010]:https://github.com/puma/puma/issues/1010   "Issue by @mneumark, closed 2016-07-19"
[#959]:https://github.com/puma/puma/issues/959     "Issue by @mwpastore, closed 2016-04-22"
[#840]:https://github.com/puma/puma/issues/840     "Issue by @maxkwallace, closed 2016-04-07"
[#1007]:https://github.com/puma/puma/pull/1007     "PR by @willnet, merged 2016-06-24"
[#1014]:https://github.com/puma/puma/pull/1014     "PR by @szymon-jez, merged 2016-07-11"
[#1015]:https://github.com/puma/puma/pull/1015     "PR by @bf4, merged 2016-07-19"
[#1017]:https://github.com/puma/puma/pull/1017     "PR by @jorihardman, merged 2016-07-19"
[#954]:https://github.com/puma/puma/pull/954       "PR by @jf, merged 2016-04-12"
[#955]:https://github.com/puma/puma/pull/955       "PR by @jf, merged 2016-04-22"
[#956]:https://github.com/puma/puma/pull/956       "PR by @maxkwallace, merged 2016-04-12"
[#960]:https://github.com/puma/puma/pull/960       "PR by @kmayer, merged 2016-04-15"
[#969]:https://github.com/puma/puma/pull/969       "PR by @frankwong15, merged 2016-05-10"
[#970]:https://github.com/puma/puma/pull/970       "PR by @willnet, merged 2016-04-26"
[#974]:https://github.com/puma/puma/pull/974       "PR by @reidmorrison, merged 2016-05-10"
[#977]:https://github.com/puma/puma/pull/977       "PR by @snow, merged 2016-05-10"
[#981]:https://github.com/puma/puma/pull/981       "PR by @zach-chai, merged 2016-07-19"
[#993]:https://github.com/puma/puma/pull/993       "PR by @scorix, merged 2016-07-19"
[#938]:https://github.com/puma/puma/issues/938     "Issue by @vandrijevik, closed 2016-04-07"
[#529]:https://github.com/puma/puma/issues/529     "Issue by @mperham, closed 2016-04-07"
[#788]:https://github.com/puma/puma/issues/788     "Issue by @herregroen, closed 2016-04-07"
[#894]:https://github.com/puma/puma/issues/894     "Issue by @rafbm, closed 2016-04-07"
[#937]:https://github.com/puma/puma/issues/937     "Issue by @huangxiangdan, closed 2016-04-07"
[#945]:https://github.com/puma/puma/pull/945       "PR by @dekellum, merged 2016-04-07"
[#946]:https://github.com/puma/puma/pull/946       "PR by @vipulnsward, merged 2016-04-07"
[#947]:https://github.com/puma/puma/pull/947       "PR by @vipulnsward, merged 2016-04-07"
[#936]:https://github.com/puma/puma/pull/936       "PR by @prathamesh-sonpatki, merged 2016-04-01"
[#940]:https://github.com/puma/puma/pull/940       "PR by @kyledrake, merged 2016-04-01"
[#942]:https://github.com/puma/puma/pull/942       "PR by @dekellum, merged 2016-04-01"
[#927]:https://github.com/puma/puma/pull/927       "PR by @jlecour, merged 2016-03-18"
[#931]:https://github.com/puma/puma/pull/931       "PR by @runlevel5, merged 2016-03-18"
[#922]:https://github.com/puma/puma/issues/922     "Issue by @LavirtheWhiolet, closed 2016-03-07"
[#923]:https://github.com/puma/puma/issues/923     "Issue by @donv, closed 2016-03-06"
[#912]:https://github.com/puma/puma/pull/912       "PR by @tricknotes, merged 2016-03-06"
[#921]:https://github.com/puma/puma/pull/921       "PR by @swrobel, merged 2016-03-06"
[#924]:https://github.com/puma/puma/pull/924       "PR by @tbrisker, merged 2016-03-07"
[#916]:https://github.com/puma/puma/issues/916     "Issue by @ma11hew28, closed 2016-03-06"
[#913]:https://github.com/puma/puma/issues/913     "Issue by @Casara, closed 2016-03-06"
[#918]:https://github.com/puma/puma/issues/918     "Issue by @rodrigdav, closed 2016-03-06"
[#910]:https://github.com/puma/puma/issues/910     "Issue by @ball-hayden, closed 2016-03-05"
[#914]:https://github.com/puma/puma/issues/914     "Issue by @osheroff, closed 2016-03-06"
[#901]:https://github.com/puma/puma/pull/901       "PR by @mitto, merged 2016-02-26"
[#902]:https://github.com/puma/puma/pull/902       "PR by @corrupt952, merged 2016-02-26"
[#905]:https://github.com/puma/puma/pull/905       "PR by @Eric-Guo, merged 2016-02-26"
[#852]:https://github.com/puma/puma/issues/852     "Issue by @asia653, closed 2016-02-25"
[#854]:https://github.com/puma/puma/issues/854     "Issue by @ollym, closed 2016-02-25"
[#824]:https://github.com/puma/puma/issues/824     "Issue by @MattWalston, closed 2016-02-25"
[#823]:https://github.com/puma/puma/issues/823     "Issue by @pneuman, closed 2016-02-25"
[#815]:https://github.com/puma/puma/issues/815     "Issue by @nate-dipiazza, closed 2016-02-25"
[#835]:https://github.com/puma/puma/issues/835     "Issue by @mwpastore, closed 2016-02-25"
[#798]:https://github.com/puma/puma/issues/798     "Issue by @schneems, closed 2016-02-25"
[#876]:https://github.com/puma/puma/issues/876     "Issue by @osheroff, closed 2016-02-25"
[#849]:https://github.com/puma/puma/issues/849     "Issue by @apotheon, closed 2016-02-25"
[#871]:https://github.com/puma/puma/pull/871       "PR by @deepj, merged 2016-02-25"
[#874]:https://github.com/puma/puma/pull/874       "PR by @wallclockbuilder, merged 2016-02-25"
[#883]:https://github.com/puma/puma/pull/883       "PR by @dadah89, merged 2016-02-25"
[#884]:https://github.com/puma/puma/pull/884       "PR by @furkanmustafa, merged 2016-02-25"
[#888]:https://github.com/puma/puma/pull/888       "PR by @mlarraz, merged 2016-02-25"
[#890]:https://github.com/puma/puma/pull/890       "PR by @todd, merged 2016-02-25"
[#891]:https://github.com/puma/puma/pull/891       "PR by @ctaintor, merged 2016-02-25"
[#893]:https://github.com/puma/puma/pull/893       "PR by @spastorino, merged 2016-02-25"
[#897]:https://github.com/puma/puma/pull/897       "PR by @vanchi-zendesk, merged 2016-02-25"
[#899]:https://github.com/puma/puma/pull/899       "PR by @kch, merged 2016-02-25"
[#859]:https://github.com/puma/puma/issues/859     "Issue by @boxofrad, closed 2016-01-28"
[#822]:https://github.com/puma/puma/pull/822       "PR by @kwugirl, merged 2016-01-28"
[#833]:https://github.com/puma/puma/pull/833       "PR by @joemiller, merged 2016-01-28"
[#837]:https://github.com/puma/puma/pull/837       "PR by @YurySolovyov, merged 2016-01-28"
[#839]:https://github.com/puma/puma/pull/839       "PR by @ka8725, merged 2016-01-15"
[#845]:https://github.com/puma/puma/pull/845       "PR by @deepj, merged 2016-01-28"
[#846]:https://github.com/puma/puma/pull/846       "PR by @sriedel, merged 2016-01-15"
[#850]:https://github.com/puma/puma/pull/850       "PR by @deepj, merged 2016-01-15"
[#853]:https://github.com/puma/puma/pull/853       "PR by @Jeffrey6052, merged 2016-01-28"
[#857]:https://github.com/puma/puma/pull/857       "PR by @osheroff, merged 2016-01-15"
[#858]:https://github.com/puma/puma/pull/858       "PR by @mlarraz, merged 2016-01-28"
[#860]:https://github.com/puma/puma/pull/860       "PR by @osheroff, merged 2016-01-15"
[#861]:https://github.com/puma/puma/pull/861       "PR by @osheroff, merged 2016-01-15"
[#818]:https://github.com/puma/puma/pull/818       "PR by @unleashed, merged 2015-11-06"
[#819]:https://github.com/puma/puma/pull/819       "PR by @VictorLowther, merged 2015-11-06"
[#563]:https://github.com/puma/puma/issues/563     "Issue by @deathbob, closed 2015-11-06"
[#803]:https://github.com/puma/puma/issues/803     "Issue by @burningTyger, closed 2016-04-07"
[#768]:https://github.com/puma/puma/pull/768       "PR by @nathansamson, merged 2015-11-06"
[#773]:https://github.com/puma/puma/pull/773       "PR by @rossta, merged 2015-11-06"
[#774]:https://github.com/puma/puma/pull/774       "PR by @snow, merged 2015-11-06"
[#781]:https://github.com/puma/puma/pull/781       "PR by @sunsations, merged 2015-11-06"
[#791]:https://github.com/puma/puma/pull/791       "PR by @unleashed, merged 2015-10-01"
[#793]:https://github.com/puma/puma/pull/793       "PR by @robdimarco, merged 2015-11-06"
[#794]:https://github.com/puma/puma/pull/794       "PR by @peterkeen, merged 2015-11-06"
[#795]:https://github.com/puma/puma/pull/795       "PR by @unleashed, merged 2015-11-06"
[#796]:https://github.com/puma/puma/pull/796       "PR by @cschneid, merged 2015-10-13"
[#799]:https://github.com/puma/puma/pull/799       "PR by @annawinkler, merged 2015-11-06"
[#800]:https://github.com/puma/puma/pull/800       "PR by @liamseanbrady, merged 2015-11-06"
[#801]:https://github.com/puma/puma/pull/801       "PR by @scottjg, merged 2015-11-06"
[#802]:https://github.com/puma/puma/pull/802       "PR by @scottjg, merged 2015-11-06"
[#804]:https://github.com/puma/puma/pull/804       "PR by @burningTyger, merged 2015-11-06"
[#809]:https://github.com/puma/puma/pull/809       "PR by @unleashed, merged 2015-11-06"
[#810]:https://github.com/puma/puma/pull/810       "PR by @vlmonk, merged 2015-11-06"
[#814]:https://github.com/puma/puma/pull/814       "PR by @schneems, merged 2015-11-04"
[#817]:https://github.com/puma/puma/pull/817       "PR by @unleashed, merged 2015-11-06"
[#735]:https://github.com/puma/puma/issues/735     "Issue by @trekr5, closed 2015-08-04"
[#769]:https://github.com/puma/puma/issues/769     "Issue by @dovestyle, closed 2015-08-16"
[#767]:https://github.com/puma/puma/issues/767     "Issue by @kapso, closed 2015-08-15"
[#765]:https://github.com/puma/puma/issues/765     "Issue by @monfresh, closed 2015-08-15"
[#764]:https://github.com/puma/puma/issues/764     "Issue by @keithpitt, closed 2015-08-15"
[#669]:https://github.com/puma/puma/pull/669       "PR by @chulkilee, closed 2015-08-14"
[#673]:https://github.com/puma/puma/pull/673       "PR by @chulkilee, closed 2015-08-14"
[#668]:https://github.com/puma/puma/pull/668       "PR by @kcollignon, merged 2015-08-14"
[#754]:https://github.com/puma/puma/pull/754       "PR by @nathansamson, merged 2015-08-14"
[#759]:https://github.com/puma/puma/pull/759       "PR by @BenV, merged 2015-08-14"
[#761]:https://github.com/puma/puma/pull/761       "PR by @dmarcotte, merged 2015-08-14"
[#742]:https://github.com/puma/puma/pull/742       "PR by @deivid-rodriguez, merged 2015-07-17"
[#743]:https://github.com/puma/puma/pull/743       "PR by @matthewd, merged 2015-07-18"
[#749]:https://github.com/puma/puma/pull/749       "PR by @huacnlee, merged 2015-08-04"
[#751]:https://github.com/puma/puma/pull/751       "PR by @costi, merged 2015-07-31"
[#741]:https://github.com/puma/puma/issues/741     "Issue by @GUI, closed 2015-07-17"
[#739]:https://github.com/puma/puma/issues/739     "Issue by @hab278, closed 2015-07-17"
[#737]:https://github.com/puma/puma/issues/737     "Issue by @dmill, closed 2015-07-16"
[#733]:https://github.com/puma/puma/issues/733     "Issue by @Eric-Guo, closed 2015-07-15"
[#736]:https://github.com/puma/puma/pull/736       "PR by @paulanunda, merged 2015-07-15"
[#722]:https://github.com/puma/puma/issues/722     "Issue by @mikeki, closed 2015-07-14"
[#694]:https://github.com/puma/puma/issues/694     "Issue by @yld, closed 2015-06-10"
[#705]:https://github.com/puma/puma/issues/705     "Issue by @TheTeaNerd, closed 2015-07-14"
[#686]:https://github.com/puma/puma/pull/686       "PR by @jjb, merged 2015-06-10"
[#693]:https://github.com/puma/puma/pull/693       "PR by @rob-murray, merged 2015-06-10"
[#697]:https://github.com/puma/puma/pull/697       "PR by @spk, merged 2015-06-10"
[#699]:https://github.com/puma/puma/pull/699       "PR by @deees, merged 2015-05-19"
[#701]:https://github.com/puma/puma/pull/701       "PR by @deepj, merged 2015-05-19"
[#702]:https://github.com/puma/puma/pull/702       "PR by @OleMchls, merged 2015-06-10"
[#703]:https://github.com/puma/puma/pull/703       "PR by @deepj, merged 2015-06-10"
[#704]:https://github.com/puma/puma/pull/704       "PR by @grega, merged 2015-06-10"
[#709]:https://github.com/puma/puma/pull/709       "PR by @lian, merged 2015-06-10"
[#711]:https://github.com/puma/puma/pull/711       "PR by @julik, merged 2015-06-10"
[#712]:https://github.com/puma/puma/pull/712       "PR by @chewi, merged 2015-07-14"
[#715]:https://github.com/puma/puma/pull/715       "PR by @raymondmars, merged 2015-07-14"
[#725]:https://github.com/puma/puma/pull/725       "PR by @rwz, merged 2015-07-14"
[#726]:https://github.com/puma/puma/pull/726       "PR by @jshafton, merged 2015-07-14"
[#729]:https://github.com/puma/puma/pull/729       "PR by @allaire, merged 2015-07-14"
[#730]:https://github.com/puma/puma/pull/730       "PR by @iamjarvo, merged 2015-07-14"
[#690]:https://github.com/puma/puma/issues/690     "Issue by @bachue, closed 2015-04-21"
[#684]:https://github.com/puma/puma/issues/684     "Issue by @tomquas, closed 2015-04-13"
[#698]:https://github.com/puma/puma/pull/698       "PR by @dmarcotte, merged 2015-05-04"
[#683]:https://github.com/puma/puma/issues/683     "Issue by @indirect, closed 2015-04-11"
[#657]:https://github.com/puma/puma/pull/657       "PR by @schneems, merged 2015-02-19"
[#658]:https://github.com/puma/puma/pull/658       "PR by @tomohiro, merged 2015-02-23"
[#662]:https://github.com/puma/puma/pull/662       "PR by @iaintshine, merged 2015-03-06"
[#664]:https://github.com/puma/puma/pull/664       "PR by @fxposter, merged 2015-03-09"
[#667]:https://github.com/puma/puma/pull/667       "PR by @JuanitoFatas, merged 2015-03-12"
[#672]:https://github.com/puma/puma/pull/672       "PR by @chulkilee, merged 2015-03-15"
[#653]:https://github.com/puma/puma/issues/653     "Issue by @dvrensk, closed 2015-02-11"
[#644]:https://github.com/puma/puma/pull/644       "PR by @bpaquet, merged 2015-01-29"
[#646]:https://github.com/puma/puma/pull/646       "PR by @mkonecny, merged 2015-02-05"
[#630]:https://github.com/puma/puma/issues/630     "Issue by @jelmd, closed 2015-01-20"
[#622]:https://github.com/puma/puma/issues/622     "Issue by @sabamotto, closed 2015-01-20"
[#583]:https://github.com/puma/puma/issues/583     "Issue by @rwojsznis, closed 2015-01-20"
[#586]:https://github.com/puma/puma/issues/586     "Issue by @ponchik, closed 2015-01-20"
[#359]:https://github.com/puma/puma/issues/359     "Issue by @natew, closed 2014-12-13"
[#633]:https://github.com/puma/puma/issues/633     "Issue by @joevandyk, closed 2015-01-20"
[#478]:https://github.com/puma/puma/pull/478       "PR by @rubencaro, merged 2015-01-20"
[#610]:https://github.com/puma/puma/pull/610       "PR by @kwilczynski, merged 2014-11-27"
[#611]:https://github.com/puma/puma/pull/611       "PR by @jasonl, merged 2015-01-20"
[#616]:https://github.com/puma/puma/pull/616       "PR by @jc00ke, merged 2014-12-10"
[#623]:https://github.com/puma/puma/pull/623       "PR by @raldred, merged 2015-01-20"
[#628]:https://github.com/puma/puma/pull/628       "PR by @rdpoor, merged 2015-01-20"
[#634]:https://github.com/puma/puma/pull/634       "PR by @deepj, merged 2015-01-20"
[#637]:https://github.com/puma/puma/pull/637       "PR by @raskhadafi, merged 2015-01-20"
[#639]:https://github.com/puma/puma/pull/639       "PR by @ebeigarts, merged 2015-01-20"
[#640]:https://github.com/puma/puma/pull/640       "PR by @bailsman, merged 2015-01-20"
[#591]:https://github.com/puma/puma/issues/591     "Issue by @renier, closed 2014-11-24"
[#606]:https://github.com/puma/puma/issues/606     "Issue by @, closed 2014-11-24"
[#560]:https://github.com/puma/puma/pull/560       "PR by @raskhadafi, merged 2014-11-24"
[#566]:https://github.com/puma/puma/pull/566       "PR by @sheltond, merged 2014-11-24"
[#593]:https://github.com/puma/puma/pull/593       "PR by @andruby, merged 2014-10-30"
[#594]:https://github.com/puma/puma/pull/594       "PR by @hassox, merged 2014-10-31"
[#596]:https://github.com/puma/puma/pull/596       "PR by @burningTyger, merged 2014-11-01"
[#601]:https://github.com/puma/puma/pull/601       "PR by @sorentwo, merged 2014-11-24"
[#602]:https://github.com/puma/puma/pull/602       "PR by @1334, merged 2014-11-24"
[#608]:https://github.com/puma/puma/pull/608       "PR by @Gu1, merged 2014-11-24"
[#538]:https://github.com/puma/puma/pull/538       "PR by @memiux, merged 2014-11-24"
[#550]:https://github.com/puma/puma/issues/550     "Issue by @, closed 2014-10-30"
[#549]:https://github.com/puma/puma/pull/549       "PR by @bsnape, merged 2014-10-16"
[#553]:https://github.com/puma/puma/pull/553       "PR by @lowjoel, merged 2014-10-16"
[#568]:https://github.com/puma/puma/pull/568       "PR by @mariuz, merged 2014-10-16"
[#578]:https://github.com/puma/puma/pull/578       "PR by @danielbuechele, merged 2014-10-16"
[#581]:https://github.com/puma/puma/pull/581       "PR by @alexch, merged 2014-10-16"
[#590]:https://github.com/puma/puma/pull/590       "PR by @dmarcotte, merged 2014-10-16"
[#574]:https://github.com/puma/puma/issues/574     "Issue by @minasmart, closed 2014-09-05"
[#561]:https://github.com/puma/puma/pull/561       "PR by @krasnoukhov, merged 2014-08-04"
[#570]:https://github.com/puma/puma/pull/570       "PR by @havenwood, merged 2014-08-20"
[#520]:https://github.com/puma/puma/pull/520       "PR by @misfo, merged 2014-06-16"
[#530]:https://github.com/puma/puma/pull/530       "PR by @dmarcotte, merged 2014-06-16"
[#537]:https://github.com/puma/puma/pull/537       "PR by @vlmonk, merged 2014-06-16"
[#540]:https://github.com/puma/puma/pull/540       "PR by @allaire, merged 2014-05-27"
[#544]:https://github.com/puma/puma/pull/544       "PR by @chulkilee, merged 2014-06-03"
[#551]:https://github.com/puma/puma/pull/551       "PR by @jcxplorer, merged 2014-07-02"
[#487]:https://github.com/puma/puma/pull/487       "PR by @, merged 2014-03-06"
[#492]:https://github.com/puma/puma/pull/492       "PR by @, merged 2014-03-06"
[#493]:https://github.com/puma/puma/pull/493       "PR by @alepore, merged 2014-03-07"
[#503]:https://github.com/puma/puma/pull/503       "PR by @mariuz, merged 2014-04-12"
[#505]:https://github.com/puma/puma/pull/505       "PR by @sammcj, merged 2014-04-12"
[#506]:https://github.com/puma/puma/pull/506       "PR by @dsander, merged 2014-04-12"
[#510]:https://github.com/puma/puma/pull/510       "PR by @momer, merged 2014-04-12"
[#511]:https://github.com/puma/puma/pull/511       "PR by @macool, merged 2014-04-12"
[#514]:https://github.com/puma/puma/pull/514       "PR by @nanaya, merged 2014-04-12"
[#517]:https://github.com/puma/puma/pull/517       "PR by @misfo, merged 2014-04-12"
[#518]:https://github.com/puma/puma/pull/518       "PR by @alxgsv, merged 2014-04-12"
[#471]:https://github.com/puma/puma/pull/471       "PR by @arthurnn, merged 2014-02-28"
[#485]:https://github.com/puma/puma/pull/485       "PR by @runlevel5, merged 2014-03-01"
[#486]:https://github.com/puma/puma/pull/486       "PR by @joshwlewis, merged 2014-03-02"
[#490]:https://github.com/puma/puma/pull/490       "PR by @tobinibot, merged 2014-03-06"
[#491]:https://github.com/puma/puma/pull/491       "PR by @brianknight10, merged 2014-03-06"
[#438]:https://github.com/puma/puma/issues/438     "Issue by @mperham, closed 2014-01-25"
[#333]:https://github.com/puma/puma/issues/333     "Issue by @SamSaffron, closed 2014-01-26"
[#440]:https://github.com/puma/puma/issues/440     "Issue by @sudara, closed 2014-01-25"
[#449]:https://github.com/puma/puma/issues/449     "Issue by @cezarsa, closed 2014-02-04"
[#444]:https://github.com/puma/puma/issues/444     "Issue by @le0pard, closed 2014-01-25"
[#370]:https://github.com/puma/puma/issues/370     "Issue by @pelcasandra, closed 2014-01-26"
[#377]:https://github.com/puma/puma/issues/377     "Issue by @mrbrdo, closed 2014-01-26"
[#406]:https://github.com/puma/puma/issues/406     "Issue by @simonrussell, closed 2014-01-25"
[#425]:https://github.com/puma/puma/issues/425     "Issue by @jhass, closed 2014-01-26"
[#432]:https://github.com/puma/puma/pull/432       "PR by @anatol, closed 2014-01-25"
[#428]:https://github.com/puma/puma/pull/428       "PR by @alexeyfrank, merged 2014-01-25"
[#429]:https://github.com/puma/puma/pull/429       "PR by @namusyaka, merged 2013-12-16"
[#431]:https://github.com/puma/puma/pull/431       "PR by @mrb, merged 2014-01-25"
[#433]:https://github.com/puma/puma/pull/433       "PR by @alepore, merged 2014-02-28"
[#437]:https://github.com/puma/puma/pull/437       "PR by @ibrahima, merged 2014-01-25"
[#446]:https://github.com/puma/puma/pull/446       "PR by @sudara, merged 2014-01-27"
[#451]:https://github.com/puma/puma/pull/451       "PR by @pwiebe, merged 2014-02-04"
[#453]:https://github.com/puma/puma/pull/453       "PR by @joevandyk, merged 2014-02-28"
[#470]:https://github.com/puma/puma/pull/470       "PR by @arthurnn, merged 2014-02-28"
[#472]:https://github.com/puma/puma/pull/472       "PR by @rubencaro, merged 2014-02-21"
[#480]:https://github.com/puma/puma/pull/480       "PR by @jjb, merged 2014-02-26"
[#481]:https://github.com/puma/puma/pull/481       "PR by @schneems, merged 2014-02-25"
[#482]:https://github.com/puma/puma/pull/482       "PR by @prathamesh-sonpatki, merged 2014-02-26"
[#483]:https://github.com/puma/puma/pull/483       "PR by @maxilev, merged 2014-02-26"
[#422]:https://github.com/puma/puma/issues/422     "Issue by @alexandru-calinoiu, closed 2013-12-05"
[#334]:https://github.com/puma/puma/issues/334     "Issue by @srgpqt, closed 2013-07-18"
[#179]:https://github.com/puma/puma/issues/179     "Issue by @betelgeuse, closed 2013-07-18"
[#332]:https://github.com/puma/puma/issues/332     "Issue by @SamSaffron, closed 2013-07-18"
[#317]:https://github.com/puma/puma/issues/317     "Issue by @masterkain, closed 2013-07-11"
[#309]:https://github.com/puma/puma/issues/309     "Issue by @masterkain, closed 2013-07-09"
[#166]:https://github.com/puma/puma/issues/166     "Issue by @emassip, closed 2013-07-06"
[#292]:https://github.com/puma/puma/issues/292     "Issue by @pulse00, closed 2013-07-06"
[#274]:https://github.com/puma/puma/issues/274     "Issue by @mrbrdo, closed 2013-07-06"
[#304]:https://github.com/puma/puma/issues/304     "Issue by @nandosola, closed 2013-07-06"
[#287]:https://github.com/puma/puma/issues/287     "Issue by @runlevel5, closed 2013-07-06"
[#256]:https://github.com/puma/puma/issues/256     "Issue by @rkh, closed 2013-07-01"
[#285]:https://github.com/puma/puma/issues/285     "Issue by @mkwiatkowski, closed 2013-06-20"
[#270]:https://github.com/puma/puma/issues/270     "Issue by @iamroody, closed 2013-06-01"
[#246]:https://github.com/puma/puma/issues/246     "Issue by @amencarini, closed 2013-06-01"
[#278]:https://github.com/puma/puma/issues/278     "Issue by @titanous, closed 2013-06-18"
[#251]:https://github.com/puma/puma/issues/251     "Issue by @cure, closed 2013-06-18"
[#252]:https://github.com/puma/puma/issues/252     "Issue by @vixns, closed 2013-06-01"
[#234]:https://github.com/puma/puma/issues/234     "Issue by @jgarber, closed 2013-04-08"
[#228]:https://github.com/puma/puma/issues/228     "Issue by @joelmats, closed 2013-04-29"
[#192]:https://github.com/puma/puma/issues/192     "Issue by @steverandy, closed 2013-02-09"
[#206]:https://github.com/puma/puma/issues/206     "Issue by @moll, closed 2013-03-19"
[#154]:https://github.com/puma/puma/issues/154     "Issue by @trevor, closed 2013-03-19"
[#208]:https://github.com/puma/puma/issues/208     "Issue by @ochronus, closed 2013-03-18"
[#189]:https://github.com/puma/puma/issues/189     "Issue by @tolot27, closed 2013-02-09"
[#185]:https://github.com/puma/puma/issues/185     "Issue by @nicolai86, closed 2013-02-06"
[#182]:https://github.com/puma/puma/issues/182     "Issue by @sriedel, closed 2013-02-05"
[#183]:https://github.com/puma/puma/issues/183     "Issue by @concept47, closed 2013-02-05"
[#176]:https://github.com/puma/puma/issues/176     "Issue by @cryo28, closed 2013-02-05"
[#180]:https://github.com/puma/puma/issues/180     "Issue by @tscolari, closed 2013-02-05"
[#170]:https://github.com/puma/puma/issues/170     "Issue by @nixme, closed 2012-11-29"
[#148]:https://github.com/puma/puma/issues/148     "Issue by @rafaelss, closed 2012-11-18"
[#128]:https://github.com/puma/puma/issues/128     "Issue by @fbjork, closed 2012-10-20"
[#155]:https://github.com/puma/puma/issues/155     "Issue by @ehlertij, closed 2012-10-13"
[#123]:https://github.com/puma/puma/pull/123       "PR by @jcoene, closed 2012-07-19"
[#111]:https://github.com/puma/puma/pull/111       "PR by @kenkeiter, closed 2012-07-19"
[#98]:https://github.com/puma/puma/pull/98         "PR by @Flink, closed 2012-05-15"
[#94]:https://github.com/puma/puma/issues/94       "Issue by @ender672, closed 2012-05-08"
[#84]:https://github.com/puma/puma/issues/84       "Issue by @sigursoft, closed 2012-04-29"
[#78]:https://github.com/puma/puma/issues/78       "Issue by @dstrelau, closed 2012-04-28"
[#79]:https://github.com/puma/puma/issues/79       "Issue by @jammi, closed 2012-04-28"
[#65]:https://github.com/puma/puma/issues/65       "Issue by @bporterfield, closed 2012-04-11"
[#54]:https://github.com/puma/puma/issues/54       "Issue by @masterkain, closed 2012-04-10"
[#58]:https://github.com/puma/puma/pull/58         "PR by @paneq, closed 2012-04-10"
[#61]:https://github.com/puma/puma/issues/61       "Issue by @dustalov, closed 2012-04-10"
[#63]:https://github.com/puma/puma/issues/63       "Issue by @seamusabshere, closed 2012-04-11"
[#60]:https://github.com/puma/puma/issues/60       "Issue by @paneq, closed 2012-04-11"
[#53]:https://github.com/puma/puma/pull/53         "PR by @sxua, closed 2012-04-11"
