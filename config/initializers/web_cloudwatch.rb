# Publish web tier saturation metrics to CloudWatch, so a scaling policy has something to read.
#
# Two families, because how the web tier is fronted decides which one carries signal:
#   Puma  - thread pool backlog and spare capacity, read straight from the process. Always works.
#   Rack  - request queue time, how long a request waited before Puma picked it up. Needs the
#           reverse proxy to stamp an X-Request-Start (or X-Queue-Start) header, which
#           deployment/nginx_chatwoot.conf does. Behind a load balancer that cannot add the
#           header there is nothing to measure, and this metric simply reports nothing.
#
# Opt-in via ENABLE_WEB_CLOUDWATCH, and skipped in Sidekiq processes, which report their own
# metrics. The reporter itself is started from config/puma.rb, where the master process is.
if !Sidekiq.server? && ActiveModel::Type::Boolean.new.cast(ENV.fetch('ENABLE_WEB_CLOUDWATCH', false))
  require 'speedshop/cloudwatch'
  require 'speedshop/cloudwatch/puma'
  require 'speedshop/cloudwatch/rack'
  require Rails.root.join('lib/cloudwatch_reporter_config')

  reporter_config = CloudwatchReporterConfig.new('WEB_CLOUDWATCH_')
  namespace = ENV.fetch('WEB_CLOUDWATCH_NAMESPACE', 'Chatwoot/Web')

  Speedshop::Cloudwatch.configure do |cw|
    cw.client = reporter_config.client
    cw.interval = reporter_config.interval
    cw.enabled_environments = [cw.environment]

    cw.collectors |= [:puma]
    cw.namespaces[:puma] = namespace
    cw.metrics[:puma] = %i[Workers BootedWorkers OldWorkers Running Backlog PoolCapacity MaxThreads]

    cw.namespaces[:rack] = namespace
    cw.metrics[:rack] = %i[RequestQueueTime]
  end

  # Inserted here rather than through the gem's Railtie, which is not loaded: requiring the gem
  # from an initializer is past the point where a new Railtie's own initializers would be run.
  Rails.application.config.middleware.insert_before 0, Speedshop::Cloudwatch::Rack
end
