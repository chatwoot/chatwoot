if defined?(Sidekiq::CloudWatchMetrics) && ChatwootApp.chatwoot_cloud?
  Sidekiq::CloudWatchMetrics.configure do |config|
    # AWS region for CloudWatch
    config.aws_region = ENV.fetch('AWS_REGION', 'us-east-1')

    # Namespace for metrics in CloudWatch
    config.namespace = ENV.fetch('SIDEKIQ_CLOUDWATCH_NAMESPACE', 'Chatwoot/Sidekiq')

    # Additional dimensions to add to all metrics
    config.additional_dimensions = {
      Environment: Rails.env,
      Application: 'Chatwoot'
    }

    # Enable detailed queue metrics
    config.enable_queue_metrics = true

    # Enable job class metrics
    config.enable_job_class_metrics = true

    # Publishing interval (in seconds)
    config.publish_interval = ENV.fetch('SIDEKIQ_CLOUDWATCH_INTERVAL', '60').to_i

    # Enable/disable specific metric types
    config.enabled_metrics = %w[
      processed
      failed
      busy
      enqueued
      scheduled
      retry_set_size
      dead_set_size
      default_queue_latency
      queues
    ]
  end
end
