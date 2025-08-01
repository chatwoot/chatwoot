if defined?(Sidekiq::CloudWatchMetrics) && defined?(ChatwootApp) && ChatwootApp.chatwoot_cloud? && ENV['ENABLE_SIDEKIQ_CLOUDWATCH'].present?
  require 'sidekiq/cloudwatchmetrics'

  # Configure AWS region if specified
  if ENV['AWS_REGION'].present?
    require 'aws-sdk-cloudwatch'
    client = Aws::CloudWatch::Client.new(region: ENV['AWS_REGION'])
  else
    client = nil # Use default client (EC2 instance role or env credentials)
  end

  Sidekiq::CloudWatchMetrics.enable!(
    client: client,
    namespace: ENV.fetch('SIDEKIQ_CLOUDWATCH_NAMESPACE', 'Chatwoot/Sidekiq'),
    interval: ENV.fetch('SIDEKIQ_CLOUDWATCH_INTERVAL', '60').to_i
  )
end
