if ENV['SENTRY_DSN'].present?
  Sentry.init do |config|
    config.dsn = ENV['SENTRY_DSN']
    config.enabled_environments = %w[staging production]

    # To activate performance monitoring, set one of these options.
    # We recommend adjusting the value in production:
    config.traces_sample_rate = 0.1 if ENV['ENABLE_SENTRY_TRANSACTIONS']

    config.excluded_exceptions += ['Rack::Timeout::RequestTimeoutException']

    # to track post data in sentry
    config.send_default_pii = true unless ENV['DISABLE_SENTRY_PII']
  end
end
