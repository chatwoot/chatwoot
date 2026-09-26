# Puma can serve each request in a thread from an internal thread pool.
# The `threads` method setting takes two numbers: a minimum and maximum.
# Any libraries that use thread pools should be configured to match
# the maximum value specified for Puma. Default is set to 5 threads for minimum
# and maximum; this matches the default thread size of Active Record.
#
max_threads_count = ENV.fetch('RAILS_MAX_THREADS', 5)
min_threads_count = ENV.fetch('RAILS_MIN_THREADS') { max_threads_count }
threads min_threads_count, max_threads_count

# Specifies the `port` that Puma will listen on to receive requests; default is 3000.
#
port ENV.fetch('PORT', 3000)

# Specifies the `environment` that Puma will run in.
#
environment ENV.fetch('RAILS_ENV') { 'development' }

# Specifies the `pidfile` that Puma will use.
pidfile ENV.fetch('PIDFILE') { 'tmp/pids/server.pid' }

# Specifies the number of `workers` to boot in clustered mode.
# Workers are forked web server processes. If using threads and workers together
# the concurrency of the application would be max `threads` * `workers`.
# Workers do not work on JRuby or Windows (both of which do not support
# processes).
#
workers ENV.fetch('WEB_CONCURRENCY', 0)

# Use the `preload_app!` method when specifying a `workers` number.
# This directive tells Puma to first boot the application and load code
# before forking the application. This takes advantage of Copy On Write
# process behavior so workers use less memory.
#
preload_app!

# Puma's own stats are only meaningful in the master process, so the CloudWatch reporter has to
# be started here rather than from the initializer. Both hooks are no-ops unless
# config/initializers/web_cloudwatch.rb turned the reporter on, and the app is preloaded above,
# so that initializer has already run by the time the server is booted.
after_booted do
  Speedshop::Cloudwatch.start! if defined?(Speedshop::Cloudwatch)
end

before_worker_boot do
  # A forked worker inherits the collector list, and Puma.stats_hash still answers in a child
  # with the master's stale numbers, so leaving it in place makes every worker republish them.
  Speedshop::Cloudwatch.config.collectors.clear if defined?(Speedshop::Cloudwatch)
end

# Allow puma to be restarted by `rails restart` command.
plugin :tmp_restart
