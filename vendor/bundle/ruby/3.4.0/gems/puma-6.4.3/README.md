<p align="center">
  <img src="https://puma.io/images/logos/puma-logo-large.png">
</p>

# Puma: A Ruby Web Server Built For Parallelism

[![Actions](https://github.com/puma/puma/workflows/Tests/badge.svg?branch=master)](https://github.com/puma/puma/actions?query=workflow%3ATests)
[![Code Climate](https://codeclimate.com/github/puma/puma.svg)](https://codeclimate.com/github/puma/puma)
[![StackOverflow](https://img.shields.io/badge/stackoverflow-Puma-blue.svg)]( https://stackoverflow.com/questions/tagged/puma )

Puma is a **simple, fast, multi-threaded, and highly parallel HTTP 1.1 server for Ruby/Rack applications**.

## Built For Speed &amp; Parallelism

Puma is a server for [Rack](https://github.com/rack/rack)-powered HTTP applications written in Ruby.  It is: 
* **Multi-threaded**. Each request is served in a separate thread. This helps you serve more requests per second with less memory use.
* **Multi-process**. "Pre-forks" in cluster mode, using less memory per-process thanks to copy-on-write memory.
* **Standalone**. With SSL support, zero-downtime rolling restarts and a built-in request bufferer, you can deploy Puma without any reverse proxy.
* **Battle-tested**. Our HTTP parser is inherited from Mongrel and has over 15 years of production use. Puma is currently the most popular Ruby webserver, and is the default server for Ruby on Rails.

Originally designed as a server for [Rubinius](https://github.com/rubinius/rubinius), Puma also works well with Ruby (MRI) and JRuby.

On MRI, there is a Global VM Lock (GVL) that ensures only one thread can run Ruby code at a time. But if you're doing a lot of blocking IO (such as HTTP calls to external APIs like Twitter), Puma still improves MRI's throughput by allowing IO waiting to be done in parallel. Truly parallel Ruby implementations (TruffleRuby, JRuby) don't have this limitation.

## Quick Start

```
$ gem install puma
$ puma
```

Without arguments, puma will look for a rackup (.ru) file in
working directory called `config.ru`.

## SSL Connection Support

Puma will install/compile with support for ssl sockets, assuming OpenSSL
development files are installed on the system.

If the system does not have OpenSSL development files installed, Puma will
install/compile, but it will not allow ssl connections.

## Frameworks

### Rails

Puma is the default server for Rails, included in the generated Gemfile.

Start your server with the `rails` command:

```
$ rails server
```

Many configuration options and Puma features are not available when using `rails server`. It is recommended that you use Puma's executable instead:

```
$ bundle exec puma
```

### Sinatra

You can run your Sinatra application with Puma from the command line like this:

```
$ ruby app.rb -s Puma
```

In order to actually configure Puma using a config file, like `puma.rb`, however, you need to use the `puma` executable. To do this, you must add a rackup file to your Sinatra app:

```ruby
# config.ru
require './app'
run Sinatra::Application
```

You can then start your application using:

```
$ bundle exec puma
```

## Configuration

Puma provides numerous options. Consult `puma -h` (or `puma --help`) for a full list of CLI options, or see `Puma::DSL` or [dsl.rb](https://github.com/puma/puma/blob/master/lib/puma/dsl.rb).

You can also find several configuration examples as part of the
[test](https://github.com/puma/puma/tree/master/test/config) suite.

For debugging purposes, you can set the environment variable `PUMA_LOG_CONFIG` with a value
and the loaded configuration will be printed as part of the boot process.

### Thread Pool

Puma uses a thread pool. You can set the minimum and maximum number of threads that are available in the pool with the `-t` (or `--threads`) flag:

```
$ puma -t 8:32
```

Puma will automatically scale the number of threads, from the minimum until it caps out at the maximum, based on how much traffic is present. The current default is `0:16` and on MRI is `0:5`. Feel free to experiment, but be careful not to set the number of maximum threads to a large number, as you may exhaust resources on the system (or cause contention for the Global VM Lock, when using MRI).

Be aware that additionally Puma creates threads on its own for internal purposes (e.g. handling slow clients). So, even if you specify -t 1:1, expect around 7 threads created in your application.

### Clustered mode

Puma also offers "clustered mode". Clustered mode `fork`s workers from a master process. Each child process still has its own thread pool. You can tune the number of workers with the `-w` (or `--workers`) flag:

```
$ puma -t 8:32 -w 3
```

Or with the `WEB_CONCURRENCY` environment variable:

```
$ WEB_CONCURRENCY=3 puma -t 8:32
```

Note that threads are still used in clustered mode, and the `-t` thread flag setting is per worker, so `-w 2 -t 16:16` will spawn 32 threads in total, with 16 in each worker process.

For an in-depth discussion of the tradeoffs of thread and process count settings, [see our docs](https://github.com/puma/puma/blob/9282a8efa5a0c48e39c60d22ca70051a25df9f55/docs/kubernetes.md#workers-per-pod-and-other-config-issues).

In clustered mode, Puma can "preload" your application. This loads all the application code *prior* to forking. Preloading reduces total memory usage of your application via an operating system feature called [copy-on-write](https://en.wikipedia.org/wiki/Copy-on-write).

If the `WEB_CONCURRENCY` environment variable is set to a value > 1 (and `--prune-bundler` has not been specified), preloading will be enabled by default. Otherwise, you can use the `--preload` flag from the command line:

```
$ puma -w 3 --preload
```

Or, if you're using a configuration file, you can use the `preload_app!` method:

```ruby
# config/puma.rb
workers 3
preload_app!
```

Preloading can’t be used with phased restart, since phased restart kills and restarts workers one-by-one, and preloading copies the code of master into the workers.

When using clustered mode, you can specify a block in your configuration file that will be run on boot of each worker:

```ruby
# config/puma.rb
on_worker_boot do
  # configuration here
end
```

This code can be used to setup the process before booting the application, allowing
you to do some Puma-specific things that you don't want to embed in your application.
For instance, you could fire a log notification that a worker booted or send something to statsd. This can be called multiple times.

Constants loaded by your application (such as `Rails`) will not be available in `on_worker_boot`
unless preloading is enabled.

You can also specify a block to be run before workers are forked, using `before_fork`:

```ruby
# config/puma.rb
before_fork do
  # configuration here
end
```

You can also specify a block to be run after puma is booted using `on_booted`:

```ruby
# config/puma.rb
on_booted do
  # configuration here
end
```

### Error handling

If puma encounters an error outside of the context of your application, it will respond with a 500 and a simple
textual error message (see `Puma::Server#lowlevel_error` or [server.rb](https://github.com/puma/puma/blob/master/lib/puma/server.rb)).
You can specify custom behavior for this scenario. For example, you can report the error to your third-party
error-tracking service (in this example, [rollbar](https://rollbar.com)):

```ruby
lowlevel_error_handler do |e|
  Rollbar.critical(e)
  [500, {}, ["An error has occurred, and engineers have been informed. Please reload the page. If you continue to have problems, contact support@example.com\n"]]
end
```

### Binding TCP / Sockets

Bind Puma to a socket with the `-b` (or `--bind`) flag:

```
$ puma -b tcp://127.0.0.1:9292
```

To use a UNIX Socket instead of TCP:

```
$ puma -b unix:///var/run/puma.sock
```

If you need to change the permissions of the UNIX socket, just add a umask parameter:

```
$ puma -b 'unix:///var/run/puma.sock?umask=0111'
```

Need a bit of security? Use SSL sockets:

```
$ puma -b 'ssl://127.0.0.1:9292?key=path_to_key&cert=path_to_cert'
```
#### Self-signed SSL certificates (via the [`localhost`] gem, for development use):

Puma supports the [`localhost`] gem for self-signed certificates. This is particularly useful if you want to use Puma with SSL locally, and self-signed certificates will work for your use-case. Currently, the integration can only be used in MRI.

Puma automatically configures SSL when the [`localhost`] gem is loaded in a `development` environment:

Add the gem to your Gemfile:
```ruby
group(:development) do
  gem 'localhost'
end
```

And require it implicitly using bundler:
```ruby
require "bundler"
Bundler.require(:default, ENV["RACK_ENV"].to_sym)
```

Alternatively, you can require the gem in your configuration file, either `config/puma/development.rb`, `config/puma.rb`, or set via the `-C` cli option:
```ruby
require 'localhost'
# configuration methods (from Puma::DSL) as needed
```

Additionally, Puma must be listening to an SSL socket:

```shell
$ puma -b 'ssl://localhost:9292' -C config/use_local_host.rb

# The following options allow you to reach Puma over HTTP as well:
$ puma -b ssl://localhost:9292 -b tcp://localhost:9393 -C config/use_local_host.rb
```

[`localhost`]: https://github.com/socketry/localhost

#### Controlling SSL Cipher Suites

To use or avoid specific SSL cipher suites, use `ssl_cipher_filter` or `ssl_cipher_list` options.

##### Ruby:

```
$ puma -b 'ssl://127.0.0.1:9292?key=path_to_key&cert=path_to_cert&ssl_cipher_filter=!aNULL:AES+SHA'
```

##### JRuby:

```
$ puma -b 'ssl://127.0.0.1:9292?keystore=path_to_keystore&keystore-pass=keystore_password&ssl_cipher_list=TLS_RSA_WITH_AES_128_CBC_SHA,TLS_RSA_WITH_AES_256_CBC_SHA'
```

See https://www.openssl.org/docs/man1.1.1/man1/ciphers.html for cipher filter format and full list of cipher suites.

Disable TLS v1 with the `no_tlsv1` option:

```
$ puma -b 'ssl://127.0.0.1:9292?key=path_to_key&cert=path_to_cert&no_tlsv1=true'
```

#### Controlling OpenSSL Verification Flags

To enable verification flags offered by OpenSSL, use `verification_flags` (not available for JRuby):

```
$ puma -b 'ssl://127.0.0.1:9292?key=path_to_key&cert=path_to_cert&verification_flags=PARTIAL_CHAIN'
```

You can also set multiple verification flags (by separating them with coma):

```
$ puma -b 'ssl://127.0.0.1:9292?key=path_to_key&cert=path_to_cert&verification_flags=PARTIAL_CHAIN,CRL_CHECK'
```

List of available flags: `USE_CHECK_TIME`, `CRL_CHECK`, `CRL_CHECK_ALL`, `IGNORE_CRITICAL`, `X509_STRICT`, `ALLOW_PROXY_CERTS`, `POLICY_CHECK`, `EXPLICIT_POLICY`, `INHIBIT_ANY`, `INHIBIT_MAP`, `NOTIFY_POLICY`, `EXTENDED_CRL_SUPPORT`, `USE_DELTAS`, `CHECK_SS_SIGNATURE`, `TRUSTED_FIRST`, `SUITEB_128_LOS_ONLY`, `SUITEB_192_LOS`, `SUITEB_128_LOS`, `PARTIAL_CHAIN`, `NO_ALT_CHAINS`, `NO_CHECK_TIME`
(see https://www.openssl.org/docs/manmaster/man3/X509_VERIFY_PARAM_set_hostflags.html#VERIFICATION-FLAGS).

#### Controlling OpenSSL Password Decryption

To enable runtime decryption of an encrypted SSL key (not available for JRuby), use `key_password_command`:

```
$ puma -b 'ssl://127.0.0.1:9292?key=path_to_key&cert=path_to_cert&key_password_command=/path/to/command.sh'
```

`key_password_command` must:

1. Be executable by Puma.
2. Print the decryption password to stdout.

 For example:

```shell
#!/bin/sh

echo "this is my password"
```

`key_password_command` can be used with `key` or `key_pem`. If the key
is not encrypted, the executable will not be called.

### Control/Status Server

Puma has a built-in status and control app that can be used to query and control Puma.

```
$ puma --control-url tcp://127.0.0.1:9293 --control-token foo
```

Puma will start the control server on localhost port 9293. All requests to the control server will need to include control token (in this case, `token=foo`) as a query parameter. This allows for simple authentication. Check out `Puma::App::Status` or [status.rb](https://github.com/puma/puma/blob/master/lib/puma/app/status.rb) to see what the status app has available.

You can also interact with the control server via `pumactl`. This command will restart Puma:

```
$ pumactl --control-url 'tcp://127.0.0.1:9293' --control-token foo restart
```

To see a list of `pumactl` options, use `pumactl --help`.

### Configuration File

You can also provide a configuration file with the `-C` (or `--config`) flag:

```
$ puma -C /path/to/config
```

If no configuration file is specified, Puma will look for a configuration file at `config/puma.rb`. If an environment is specified (via the `--environment` flag or through the `APP_ENV`, `RACK_ENV`, or `RAILS_ENV` environment variables) Puma looks for a configuration file at `config/puma/<environment_name>.rb` and then falls back to `config/puma.rb`.

If you want to prevent Puma from looking for a configuration file in those locations, include the `--no-config` flag:

```
$ puma --no-config

# or

$ puma -C "-"
```

The other side-effects of setting the environment are whether to show stack traces (in `development` or `test`), and setting RACK_ENV may potentially affect middleware looking for this value to change their behavior. The default puma RACK_ENV value is `development`. You can see all config default values in `Puma::Configuration#puma_default_options` or [configuration.rb](https://github.com/puma/puma/blob/61c6213fbab/lib/puma/configuration.rb#L182-L204).

Check out `Puma::DSL` or [dsl.rb](https://github.com/puma/puma/blob/master/lib/puma/dsl.rb) to see all available options.

## Restart

Puma includes the ability to restart itself. When available (MRI, Rubinius, JRuby), Puma performs a "hot restart". This is the same functionality available in *Unicorn* and *NGINX* which keep the server sockets open between restarts. This makes sure that no pending requests are dropped while the restart is taking place.

For more, see the [Restart documentation](docs/restart.md).

## Signals

Puma responds to several signals. A detailed guide to using UNIX signals with Puma can be found in the [Signals documentation](docs/signals.md).

## Platform Constraints

Some platforms do not support all Puma features.

  * **JRuby**, **Windows**: server sockets are not seamless on restart, they must be closed and reopened. These platforms have no way to pass descriptors into a new process that is exposed to Ruby. Also, cluster mode is not supported due to a lack of fork(2).
  * **Windows**: Cluster mode is not supported due to a lack of fork(2).
  * **Kubernetes**: The way Kubernetes handles pod shutdowns interacts poorly with server processes implementing graceful shutdown, like Puma. See the [kubernetes section of the documentation](docs/kubernetes.md) for more details.

## Known Bugs

For MRI versions 2.2.7, 2.2.8, 2.2.9, 2.2.10, 2.3.4 and 2.4.1, you may see ```stream closed in another thread (IOError)```. It may be caused by a [Ruby bug](https://bugs.ruby-lang.org/issues/13632). It can be fixed with the gem https://rubygems.org/gems/stopgap_13632:

```ruby
if %w(2.2.7 2.2.8 2.2.9 2.2.10 2.3.4 2.4.1).include? RUBY_VERSION
  begin
    require 'stopgap_13632'
  rescue LoadError
  end
end
```

## Deployment

 * Puma has support for Capistrano with an [external gem](https://github.com/seuros/capistrano-puma).

 * Additionally, Puma has support for built-in daemonization via the [puma-daemon](https://github.com/kigster/puma-daemon) ruby gem. The gem restores the `daemonize` option that was removed from Puma starting version 5, but only for MRI Ruby.


It is common to use process monitors with Puma. Modern process monitors like systemd or rc.d
provide continuous monitoring and restarts for increased reliability in production environments:

* [rc.d](docs/jungle/rc.d/README.md)
* [systemd](docs/systemd.md)

Community guides:

* [Deploying Puma on OpenBSD using relayd and httpd](https://gist.github.com/anon987654321/4532cf8d6c59c1f43ec8973faa031103)

## Community Extensions

### Plugins

* [puma-metrics](https://github.com/harmjanblok/puma-metrics) — export Puma metrics to Prometheus
* [puma-plugin-statsd](https://github.com/yob/puma-plugin-statsd) — send Puma metrics to statsd
* [puma-plugin-systemd](https://github.com/sj26/puma-plugin-systemd) — deeper integration with systemd for notify, status and watchdog. Puma 5.1.0 integrated notify and watchdog, which probably conflicts with this plugin. Puma 6.1.0 added status support which obsoletes the plugin entirely.
* [puma-plugin-telemetry](https://github.com/babbel/puma-plugin-telemetry) - telemetry plugin for Puma offering various targets to publish
* [puma-acme](https://github.com/anchordotdev/puma-acme) - automatic SSL/HTTPS certificate provisioning and setup

### Monitoring

* [puma-status](https://github.com/ylecuyer/puma-status) — Monitor CPU/Mem/Load of running puma instances from the CLI

## Contributing

Find details for contributing in the [contribution guide](CONTRIBUTING.md).

## License

Puma is copyright Evan Phoenix and contributors, licensed under the BSD 3-Clause license. See the included LICENSE file for details.
