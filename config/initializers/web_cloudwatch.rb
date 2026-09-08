# Publish web request queue time to CloudWatch. Queue time is how long a request waited in the
# reverse proxy backlog before Puma picked it up, which saturates before response time does.
#
# Opt-in via ENABLE_WEB_CLOUDWATCH, and skipped in Sidekiq processes, which report their own
# metrics. Depends on the reverse proxy sending an X-Request-Start (or X-Queue-Start) header;
# without it the middleware measures nothing and no datums are published.
if !Sidekiq.server? && ActiveModel::Type::Boolean.new.cast(ENV.fetch('ENABLE_WEB_CLOUDWATCH', false))
  require 'speedshop/cloudwatch'
  require 'speedshop/cloudwatch/rack'
  require Rails.root.join('lib/cloudwatch_reporter_config')

  reporter_config = CloudwatchReporterConfig.new('WEB_CLOUDWATCH_')

  Speedshop::Cloudwatch.configure do |cw|
    cw.client = reporter_config.client
    cw.namespaces[:rack] = ENV.fetch('WEB_CLOUDWATCH_NAMESPACE', 'Chatwoot/Web')
    cw.interval = reporter_config.interval
    cw.metrics[:rack] = %i[RequestQueueTime]
    cw.enabled_environments = [cw.environment]
  end

  # Inserted here rather than through the gem's Railtie, which is not loaded: requiring the gem
  # from an initializer is past the point where a new Railtie's own initializers would be run.
  Rails.application.config.middleware.insert_before 0, Speedshop::Cloudwatch::Rack
end
