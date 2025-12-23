# Deployment engineering for Puma

Puma expects to be run in a deployed environment eventually. You can use it as
your development server, but most people use it in their production deployments.

To that end, this document serves as a foundation of wisdom regarding deploying
Puma to production while increasing happiness and decreasing downtime.

## Specifying Puma

Most people will specify Puma by including `gem "puma"` in a Gemfile, so we'll
assume this is how you're using Puma.

## Single vs. Cluster mode

Initially, Puma was conceived as a thread-only web server, but support for
processes was added in version 2.

To run `puma` in single mode (i.e., as a development environment), set the
number of workers to 0; anything higher will run in cluster mode.

Here are some tips for cluster mode:

### MRI

* Use cluster mode and set the number of workers to 1.5x the number of CPU cores
  in the machine, starting from a minimum of 2.
* Set the number of threads to desired concurrent requests/number of workers.
  Puma defaults to 5, and that's a decent number.

#### Migrating from Unicorn

* If you're migrating from unicorn though, here are some settings to start with:
  * Set workers to half the number of unicorn workers you're using
  * Set threads to 2
  * Enjoy 50% memory savings
* As you grow more confident in the thread-safety of your app, you can tune the
  workers down and the threads up.

#### Ubuntu / Systemd (Systemctl) Installation

See [systemd.md](systemd.md)

#### Worker utilization

**How do you know if you've got enough (or too many workers)?**

A good question. Due to MRI's GIL, only one thread can be executing Ruby code at
a time. But since so many apps are waiting on IO from DBs, etc., they can
utilize threads to use the process more efficiently.

Generally, you never want processes that are pegged all the time. That can mean
there is more work to do than the process can get through. On the other hand, if
you have processes that sit around doing nothing, then they're just eating up
resources.

Watch your CPU utilization over time and aim for about 70% on average. 70%
utilization means you've got capacity still but aren't starving threads.

**Measuring utilization**

Using a timestamp header from an upstream proxy server (e.g., `nginx` or
`haproxy`) makes it possible to indicate how long requests have been waiting for
a Puma thread to become available.

* Have your upstream proxy set a header with the time it received the request:
    * nginx: `proxy_set_header X-Request-Start "${msec}";`
    * haproxy >= 1.9: `http-request set-header X-Request-Start
      t=%[date()]%[date_us()]`
    * haproxy < 1.9: `http-request set-header X-Request-Start t=%[date()]`
* In your Rack middleware, determine the amount of time elapsed since
  `X-Request-Start`.
* To improve accuracy, you will want to subtract time spent waiting for slow
  clients:
    * `env['puma.request_body_wait']` contains the number of milliseconds Puma
      spent waiting for the client to send the request body.
    * haproxy: `%Th` (TLS handshake time) and `%Ti` (idle time before request)
      can can also be added as headers.

## Should I daemonize?

The Puma 5.0 release removed daemonization. For older versions and alternatives,
continue reading.

I prefer not to daemonize my servers and use something like `runit` or `systemd`
to monitor them as child processes. This gives them fast response to crashes and
makes it easy to figure out what is going on. Additionally, unlike `unicorn`,
Puma does not require daemonization to do zero-downtime restarts.

I see people using daemonization because they start puma directly via Capistrano
task and thus want it to live on past the `cap deploy`. To these people, I say:
You need to be using a process monitor. Nothing is making sure Puma stays up in
this scenario! You're just waiting for something weird to happen, Puma to die,
and to get paged at 3 AM. Do yourself a favor, at least the process monitoring
your OS comes with, be it `sysvinit` or `systemd`. Or branch out and use `runit`
or hell, even `monit`.

## Restarting

You probably will want to deploy some new code at some point, and you'd like
Puma to start running that new code. There are a few options for restarting
Puma, described separately in our [restart documentation](restart.md).
