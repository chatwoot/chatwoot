[![Gem Version](https://badge.fury.io/rb/newrelic-sidekiq-metrics.svg)](https://rubygems.org/gems/newrelic-sidekiq-metrics)
[![Build Status](https://github.com/RenoFi/newrelic-sidekiq-metrics/actions/workflows/ci.yml/badge.svg)](https://github.com/RenoFi/newrelic-sidekiq-metrics/actions/workflows/ci.yml?query=branch%3Amain)

# newrelic-sidekiq-metrics

Implements recording Sidekiq stats to New Relic metrics by leveraging sidekiq middlewares.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'newrelic-sidekiq-metrics'
```

## Usage

Available metrics you can record are:

```
----------------------------------------------------
| Sidekiq stat name |    NewRelic metric name      |
----------------------------------------------------
| processed         | Custom/Sidekiq/ProcessedSize |
| failed            | Custom/Sidekiq/FailedSize    |
| scheduled_size    | Custom/Sidekiq/ScheduledSize |
| retry_size        | Custom/Sidekiq/RetrySize     |
| dead_size         | Custom/Sidekiq/DeadSize      |
| enqueued          | Custom/Sidekiq/EnqueuedSize  |
| processes_size    | Custom/Sidekiq/ProcessesSize |
| workers_size      | Custom/Sidekiq/WorkersSize   |
----------------------------------------------------
```

By default only `enqueued` and `retry_size` are recorded.

You can enable more with:

```ruby
NewrelicSidekiqMetrics.use(:enqueued, :retry_size, :dead_size)
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/RenoFi/newrelic-sidekiq-metrics. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
