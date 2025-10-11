# Sentry Error Tracking & Logging Configuration
# Only enabled when SENTRY_DSN is set and environment is in enabled_environments

if ENV['SENTRY_DSN'].present?
  begin
    Sentry.init do |config|
      config.dsn = ENV['SENTRY_DSN']
      config.environment = ENV['APP_ENVIRONMENT'] || Rails.env
      config.enabled_environments = %w[devnet prod-india local]

      # To activate performance monitoring, set one of these options.
      # We recommend adjusting the value in production:
      config.traces_sample_rate = 0.1 if ENV['ENABLE_SENTRY_TRANSACTIONS']

      config.excluded_exceptions += ['Rack::Timeout::RequestTimeoutException']

      # to track post data in sentry
      config.send_default_pii = true unless ENV['DISABLE_SENTRY_PII']

      # Enable Sentry Logs feature (requires sentry-ruby >= 5.24.0)
      config.enable_logs = true

      # Graceful timeout handling for development/network issues
      config.transport.timeout = 2
      config.background_worker_threads = 0 if Rails.env.development?
    end
  rescue StandardError => e
    # Gracefully handle Sentry initialization errors
    Rails.logger.warn "Sentry initialization failed: #{e.message}" if defined?(Rails.logger)
  end
end
