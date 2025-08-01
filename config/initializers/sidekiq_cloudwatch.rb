if defined?(Sidekiq::CloudWatchMetrics) && defined?(ChatwootApp) && ChatwootApp.chatwoot_cloud? && ENV['ENABLE_SIDEKIQ_CLOUDWATCH'].present?
  require 'sidekiq/cloudwatchmetrics'

  # Use EC2 instance role for AWS credentials (no custom client needed)
  Sidekiq::CloudWatchMetrics.enable!(
    namespace: ENV.fetch('SIDEKIQ_CLOUDWATCH_NAMESPACE', 'Chatwoot/Sidekiq'),
    interval: ENV.fetch('SIDEKIQ_CLOUDWATCH_INTERVAL', '60').to_i
  )
end
