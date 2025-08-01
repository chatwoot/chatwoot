if defined?(Sidekiq::CloudWatchMetrics) && defined?(ChatwootApp) && ChatwootApp.chatwoot_cloud? && ENV['ENABLE_SIDEKIQ_CLOUDWATCH'].present?
  require 'sidekiq/cloudwatchmetrics'

  Rails.logger.info '================================================'
  Rails.logger.info 'Sidekiq::CloudWatchMetrics defined'
  Rails.logger.info 'ChatwootApp defined'
  Rails.logger.info "ChatwootApp.chatwoot_cloud? #{ChatwootApp.chatwoot_cloud?}"
  Rails.logger.info "ENV['ENABLE_SIDEKIQ_CLOUDWATCH'] #{ENV.fetch('ENABLE_SIDEKIQ_CLOUDWATCH', nil)}"
  Rails.logger.info "ENV['SIDEKIQ_CLOUDWATCH_NAMESPACE'] #{ENV.fetch('SIDEKIQ_CLOUDWATCH_NAMESPACE', nil)}"
  Rails.logger.info "ENV['SIDEKIQ_CLOUDWATCH_INTERVAL'] #{ENV.fetch('SIDEKIQ_CLOUDWATCH_INTERVAL', nil)}"
  Rails.logger.info '================================================'

  # Use EC2 instance role for AWS credentials (no custom client needed)
  Sidekiq::CloudWatchMetrics.enable!(
    namespace: ENV.fetch('SIDEKIQ_CLOUDWATCH_NAMESPACE', 'Chatwoot/Sidekiq'),
    interval: ENV.fetch('SIDEKIQ_CLOUDWATCH_INTERVAL', '60').to_i
  )
end
