## Accessing stats

Stats can be accessed in two ways:

### control server

`$ pumactl stats` or `GET /stats`

[Read more about `pumactl` and the control server in the README.](https://github.com/puma/puma#controlstatus-server).

### Puma.stats

`Puma.stats` produces a JSON string. `Puma.stats_hash` produces a ruby hash.

#### in single mode

Invoke `Puma.stats` anywhere in runtime, e.g. in a rails initializer:

```ruby
# config/initializers/puma_stats.rb

Thread.new do
  loop do
    sleep 30
    puts Puma.stats
  end
end
```

#### in cluster mode

Invoke `Puma.stats` from the master process

```ruby
# config/puma.rb

before_fork do
  Thread.new do
    loop do
      puts Puma.stats
      sleep 30
    end
  end
end
```


## Explanation of stats

`Puma.stats` returns different information and a different structure depending on if Puma is in single vs. cluster mode. There is one top-level attribute that is common to both modes:

* started_at: when Puma was started

### single mode and individual workers in cluster mode

When Puma runs in single mode, these stats are available at the top level. When Puma runs in cluster mode, these stats are available within the `worker_status` array in a hash labeled `last_status`, in an array of hashes where one hash represents each worker.

* backlog: requests that are waiting for an available thread to be available. if this is above 0, you need more capacity [always true?]
* running: how many threads are running
* pool_capacity: the number of requests that the server is capable of taking right now. For example, if the number is 5, then it means there are 5 threads sitting idle ready to take a request. If one request comes in, then the value would be 4 until it finishes processing. If the minimum threads allowed is zero, this number will still have a maximum value of the maximum threads allowed.
* max_threads: the maximum number of threads Puma is configured to spool per worker
* requests_count: the number of requests this worker has served since starting


### cluster mode

* phase: which phase of restart the process is in, during [phased restart](https://github.com/puma/puma/blob/master/docs/restart.md)
* workers: ??
* booted_workers: how many workers currently running?
* old_workers: ??
* worker_status: array of hashes of info for each worker (see below)

### worker status

* started_at: when the worker started
* pid: the process id of the worker process
* index: each worker gets a number. if Puma is configured to have 3 workers, then this will be 0, 1, or 2
* booted: if it's done booting [?]
* last_checkin: Last time the worker responded to the master process' heartbeat check.
* last_status: a hash of info about the worker's state handling requests. See the explanation for this in "single mode and individual workers in cluster mode" section above.


## Examples

Here are two example stats hashes produced by `Puma.stats`:

### single

```json
{
  "started_at": "2021-01-14T07:12:35Z",
  "backlog": 0,
  "running": 5,
  "pool_capacity": 5,
  "max_threads": 5,
  "requests_count": 3
}
```

### cluster

```json
{
  "started_at": "2021-01-14T07:09:17Z",
  "workers": 2,
  "phase": 0,
  "booted_workers": 2,
  "old_workers": 0,
  "worker_status": [
    {
      "started_at": "2021-01-14T07:09:24Z",
      "pid": 64136,
      "index": 0,
      "phase": 0,
      "booted": true,
      "last_checkin": "2021-01-14T07:11:09Z",
      "last_status": {
        "backlog": 0,
        "running": 5,
        "pool_capacity": 5,
        "max_threads": 5,
        "requests_count": 2
      }
    },
    {
      "started_at": "2021-01-14T07:09:24Z",
      "pid": 64137,
      "index": 1,
      "phase": 0,
      "booted": true,
      "last_checkin": "2021-01-14T07:11:09Z",
      "last_status": {
        "backlog": 0,
        "running": 5,
        "pool_capacity": 5,
        "max_threads": 5,
        "requests_count": 1
      }
    }
  ]
}
```
