# SidekiqAlive

[![Gem Version](https://badge.fury.io/rb/sidekiq_alive.svg)](https://rubygems.org/gems/sidekiq_alive)
[![Total Downloads](https://img.shields.io/gem/dt/sidekiq_alive?color=blue)](https://rubygems.org/gems/https://rubygems.org/gems/sidekiq_alive)
![Workflow status](https://github.com/allure-framework/allure-ruby/workflows/Test/badge.svg)

---

SidekiqAlive offers a solution to add liveness probe for a Sidekiq instance deployed in Kubernetes.
This library can be used to check sidekiq health outside kubernetes.

**How?**

A http server is started and on each requests validates that a liveness key is stored in Redis. If it is there means is working.

A Sidekiq worker is the responsible to storing this key. If Sidekiq stops processing workers
this key gets expired by Redis an consequently the http server will return a 500 error.

This worker is responsible to requeue itself for the next liveness probe.

Each instance in kubernetes will be checked based on `ENV` variable `HOSTNAME` (kubernetes sets this for each replica/pod).

On initialization SidekiqAlive will asign to Sidekiq::Worker a queue with the current host and add this queue to the current instance queues to process.

example:

```
hostname: foo
  Worker queue: sidekiq_alive-foo
  instance queues:
   - sidekiq_alive-foo
   *- your queues

hostname: bar
  Worker queue: sidekiq_alive-bar
  instance queues:
   - sidekiq_alive-bar
   *- your queues
```

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'sidekiq_alive'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install sidekiq_alive

## Usage

SidekiqAlive will start when running `sidekiq` command.

Run `Sidekiq`

```
bundle exec sidekiq
```

```
curl localhost:7433
#=> Alive!
```

**how to disable?**
You can disabled by setting `ENV` variable `DISABLE_SIDEKIQ_ALIVE`
example:

```
DISABLE_SIDEKIQ_ALIVE=true bundle exec sidekiq
```

### Kubernetes setup

Set `livenessProbe` in your Kubernetes deployment

example with recommended setup:

#### Sidekiq < 6

```yaml
spec:
  containers:
    - name: my_app
      image: my_app:latest
      env:
        - name: RAILS_ENV
          value: production
      command:
        - bundle
        - exec
        - sidekiq
      ports:
        - containerPort: 7433
      livenessProbe:
        httpGet:
          path: /
          port: 7433
        initialDelaySeconds: 80 # app specific. Time your sidekiq takes to start processing.
        timeoutSeconds: 5 # can be much less
      readinessProbe:
        httpGet:
          path: /
          port: 7433
        initialDelaySeconds: 80 # app specific
        timeoutSeconds: 5 # can be much less
      lifecycle:
        preStop:
          exec:
            # SIGTERM triggers a quick exit; gracefully terminate instead
            command: ['bundle', 'exec', 'sidekiqctl', 'quiet']
  terminationGracePeriodSeconds: 60 # put your longest Job time here plus security time.
```

#### Sidekiq >= 6

Create file:

_kube/sidekiq_quiet_

```bash
#!/bin/bash

# Find Pid
SIDEKIQ_PID=$(ps aux | grep sidekiq | grep busy | awk '{ print $2 }')
# Send TSTP signal
kill -SIGTSTP $SIDEKIQ_PID
```

Make it executable:

```
$ chmod +x kube/sidekiq_quiet
```

Execute it in your deployment preStop:

```yaml
spec:
  containers:
    - name: my_app
      image: my_app:latest
      env:
        - name: RAILS_ENV
          value: production
      command:
        - bundle
        - exec
        - sidekiq
      ports:
        - containerPort: 7433
      livenessProbe:
        httpGet:
          path: /
          port: 7433
        initialDelaySeconds: 80 # app specific. Time your sidekiq takes to start processing.
        timeoutSeconds: 5 # can be much less
      readinessProbe:
        httpGet:
          path: /
          port: 7433
        initialDelaySeconds: 80 # app specific
        timeoutSeconds: 5 # can be much less
      lifecycle:
        preStop:
          exec:
            # SIGTERM triggers a quick exit; gracefully terminate instead
            command: ['kube/sidekiq_quiet']
  terminationGracePeriodSeconds: 60 # put your longest Job time here plus security time.
```

### Outside kubernetes

It's just up to you how you want to use it.

An example in local would be:

```
bundle exec sidekiq
# let it initialize ...
```

```
curl localhost:7433
#=> Alive!
```

## Options

```ruby
SidekiqAlive.setup do |config|
  # ==> Server host
  # Host to bind the server.
  # Can also be set with the environment variable SIDEKIQ_ALIVE_HOST.
  # default: 0.0.0.0
  #
  #   config.host = 0.0.0.0

  # ==> Server port
  # Port to bind the server.
  # Can also be set with the environment variable SIDEKIQ_ALIVE_PORT.
  # default: 7433
  #
  #   config.port = 7433

  # ==> Server path
  # HTTP path to respond to.
  # Can also be set with the environment variable SIDEKIQ_ALIVE_PATH.
  # default: '/'
  #
  #   config.path = '/'

  # ==> Custom Liveness Probe
  # Extra check to decide if restart the pod or not for example connection to DB.
  # `false`, `nil` or `raise` will not write the liveness probe
  # default: proc { true }
  #
  #     config.custom_liveness_probe = proc { db_running? }

  # ==> Liveness key
  # Key to be stored in Redis as probe of liveness
  # default: "SIDEKIQ::LIVENESS_PROBE_TIMESTAMP"
  #
  #   config.liveness_key = "SIDEKIQ::LIVENESS_PROBE_TIMESTAMP"

  # ==> Time to live
  # Time for the key to be kept by Redis.
  # Here is where you can set de periodicity that the Sidekiq has to probe it is working
  # Time unit: seconds
  # default: 10 * 60 # 10 minutes
  #
  #   config.time_to_live = 10 * 60

  # ==> Callback
  # After the key is stored in redis you can perform anything.
  # For example a webhook or email to notify the team
  # default: proc {}
  #
  #    require 'net/http'
  #    config.callback = proc { Net::HTTP.get("https://status.com/ping") }

  # ==> Shutdown callback
  # When sidekiq process is shutting down, you can perform some arbitrary action.
  # default: proc {}
  #
  #    config.shutdown_callback = proc { puts "Sidekiq is shutting down" }

  # ==> Queue Prefix
  # SidekiqAlive will run in a independent queue for each instance/replica
  # This queue name will be generated with: "#{queue_prefix}-#{hostname}.
  # You can customize the prefix here.
  # default: :sidekiq-alive
  #
  #    config.queue_prefix = :other

  # ==> Concurrency
  # The maximum number of Redis connections requested for the SidekiqAlive pool.
  # Can also be set with the environment variable SIDEKIQ_ALIVE_CONCURRENCY.
  # NOTE: only effects Sidekiq 7 or greater.
  # default: 2
  #
  #    config.concurrency = 3

  # ==> Rack server
  # Web server used to serve an HTTP response. By default simple GServer based http server is used.
  # To use specific server, rack gem version > 2 is required. For rack version >= 3, rackup gem is required.
  # Can also be set with the environment variable SIDEKIQ_ALIVE_SERVER.
  # default: nil
  #
  #    config.server = 'puma'

  # ==> Quiet mode timeout in seconds
  # When sidekiq is shutting down, the Sidekiq process stops pulling jobs from the queue. This includes alive key update job. In case of
  # long running jobs, alive key can expire before the job is finished. To avoid this, web server is set in to quiet mode
  # and is returning 200 OK for healthcheck requests. To avoid infinite quiet mode in case sidekiq process is stuck in shutdown,
  # timeout can be set. After timeout is reached, web server resumes normal operations and will return unhealthy status in case
  # alive key is expired or purged from redis.
  # default: 180
  #
  #    config.quiet_timeout = 300

end
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`.

Here is an example [rails app](https://github.com/arturictus/sidekiq_alive_example)

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/arturictus/sidekiq_alive. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
