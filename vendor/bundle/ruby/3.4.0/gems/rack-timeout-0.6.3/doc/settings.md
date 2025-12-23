# Settings

Rack::Timeout has 4 settings, each of which impacts when Rack::Timeout
will raise an exception, and which type of exception will be raised.

### Service Timeout

`service_timeout` is the most important setting.

*Service time* is the time taken from when a request first enters rack to when its response is sent back. When the application takes longer than `service_timeout` to process a request, the request's status is logged as `timed_out` and `Rack::Timeout::RequestTimeoutException` or `Rack::Timeout::RequestTimeoutError` is raised on the application thread. This may be automatically caught by the framework or plugins, so beware. Also, the exception is not guaranteed to be raised in a timely fashion, see section below about IO blocks.

Service timeout can be disabled entirely by setting the property to `0` or `false`, at which point the request skips Rack::Timeout's machinery (so no logging will be present).

### Wait Timeout

Before a request reaches the rack application, it may have spent some time being received by the web server, or waiting in the application server's queue before being dispatched to rack. The time between when a request is received by the web server and when rack starts handling it is called the *wait time*.

On Heroku, a request will be dropped when the routing layer sees no data being transferred for over 30 seconds. (You can read more about the specifics of Heroku routing's timeout [here][heroku-routing] and [here][heroku-timeout].) In this case, it makes no sense to process a request that reaches the application after having waited more than 30 seconds. That's where the `wait_timeout` setting comes in. When a request has a wait time greater than `wait_timeout`, it'll be dropped without ever being sent down to the application, and a `Rack::Timeout::RequestExpiryError` is raised. Such requests are logged as `expired`.

[heroku-routing]: https://devcenter.heroku.com/articles/http-routing#timeouts
[heroku-timeout]: https://devcenter.heroku.com/articles/request-timeout

`wait_timeout` is set at a default of 30 seconds, matching Heroku's router's timeout.

Wait timeout can be disabled entirely by setting the property to `0` or `false`.

A request's computed wait time may affect the service timeout used for it. Basically, a request's wait time plus service time may not exceed the wait timeout. The reasoning for that is based on Heroku router's behavior, that the request would be dropped anyway after the wait timeout. So, for example, with the default settings of `service_timeout=15`, `wait_timeout=30`, a request that had 20 seconds of wait time will not have a service timeout of 15, but instead of 10, as there are only 10 seconds left before `wait_timeout` is reached. This behavior can be disabled by setting `service_past_wait` to `true`. When set, the `service_timeout` setting will always be honored. Please note that if you're using the `RACK_TIMEOUT_SERVICE_PAST_WAIT` environment variable, any value different than `"false"` will be considered `true`.

The way we're able to infer a request's start time, and from that its wait time, is through the availability of the `X-Request-Start` HTTP header, which is expected to contain the time since epoch in milliseconds. (A concession is made for nginx's sec.msec notation.)

If the `X-Request-Start` header is not present `wait_timeout` handling is skipped entirely.

### Wait Overtime

Relying on `X-Request-Start` is less than ideal, as it computes the time since the request *started* being received by the web server, rather than the time the request *finished* being received by the web server. That poses a problem for lengthy requests.

Lengthy requests are requests with a body, such as POST requests. These take time to complete being received by the application server, especially when the client has a slow upload speed, as is common for example with mobile clients or asymmetric connections.

While we can infer the time since a request started being received, we can't tell when it completed being received, which would be preferable. We're also unable to tell the time since the last byte was sent in the request, which would be relevant in tracking Heroku's router timeout appropriately.

A request that took longer than 30s to be fully received, but that had been uploading data all that while, would be dropped immediately by Rack::Timeout because it'd be considered too old. Heroku's router, however, would not have dropped this request because data was being transmitted all along.

As a concession to these shortcomings, for requests that have a body present, we allow some additional wait time on top of `wait_timeout`. This aims to make up for time lost to long uploads.

This extra time is called *wait overtime* and can be set via `wait_overtime`. It defaults to 60 seconds. This can be disabled as usual by setting the property to `0` or `false`. When disabled, there's no overtime. If you want lengthy requests to never get expired, set `wait_overtime` to a very high number.

Keep in mind that Heroku [recommends][uploads] uploading large files directly to S3, so as to prevent the dyno from being blocked for too long and hence unable to handle further incoming requests.

[uploads]: https://devcenter.heroku.com/articles/s3#file-uploads

### Term on Timeout

If your application timeouts fire frequently then [they can cause your application to enter a corrupt state](https://www.schneems.com/2017/02/21/the-oldest-bug-in-ruby-why-racktimeout-might-hose-your-server/). One option for resetting that bad state is to restart the entire process. If you are running in an environment with multiple processes (such as `puma -w 2`) then when a process is sent a `SIGTERM` it will exit. The webserver then knows how to restart the process. For more information on process restart behavior see:

- [Ruby Application Restart Behavior](https://devcenter.heroku.com/articles/what-happens-to-ruby-apps-when-they-are-restarted)
- [License to SIGKILL](https://www.sitepoint.com/license-to-sigkill/)

**Puma SIGTERM behavior** When a Puma worker receives a `SIGTERM` it will begin to shut down, but not exit right away. It stops accepting new requests and waits for any existing requests to finish before fully shutting down. This means that only the request that experiences a timeout will be interupted, all other in-flight requests will be allowed to run until they return or also are timed out.

After the worker process exists will Puma's parent process know to boot a replacement worker. While one process is restarting, another can still serve requests (if you have more than 1 worker process per server/dyno). Between when a process exits and when a new process boots, there will be a reduction in throughput. If all processes are restarting, then incoming requests will be blocked while new processes boot.

**How to enable** To enable this behavior you can set `term_on_timeout: 1` to an integer value. If you set it to one, then the first time the process encounters a timeout, it will receive a SIGTERM.

To enable on Heroku run:

```
$ heroku config:set RACK_TIMEOUT_TERM_ON_TIMEOUT=1
```

**Caution** If you use this setting inside of a webserver without enabling multi-process mode, then it will exit the entire server when it fires:

- ✅ `puma -w 2 -t 5` This is OKAY
- ❌ `puma -t 5` This is NOT OKAY

If you're using a `config/puma.rb` file then make sure you are calling `workers` configuration DSL. You should see multiple workers when the server boots:

```
[3922] Puma starting in cluster mode...
[3922] * Version 4.3.0 (ruby 2.6.5-p114), codename: Mysterious Traveller
[3922] * Min threads: 0, max threads: 16
[3922] * Environment: development
[3922] * Process workers: 2
[3922] * Phased restart available
[3922] * Listening on tcp://0.0.0.0:9292
[3922] Use Ctrl-C to stop
[3922] - Worker 0 (pid: 3924) booted, phase: 0
[3922] - Worker 1 (pid: 3925) booted, phase: 0
```

> ✅ Notice how it says it is booting in "cluster mode" and how it gives PIDs for two worker processes at the bottom.

**How to decide the term_on_timeout value** If you set to a higher value such as `5` then rack-timeout will wait until the process has experienced five timeouts before restarting the process. Setting this value to a higher number means the application restarts processes less frequently, so throughput will be less impacted. If you set it to too high of a number, then the underlying issue of the application being put into a bad state will not be effectively mitigated.


**How do I know when a process is being restarted by rack-timeout?** This exception error should be visible in the logs:

```
Request ran for longer than 1000ms, sending SIGTERM to process 3925
```

> Note: Since the worker waits for all in-flight requests to finish (with puma) you may see multiple SIGTERMs to the same PID before it exits, this means that multiple requests timed out.
